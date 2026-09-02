module LockFinancialStrategyLibraryPanelV3PredecisionComputation

using SHA: sha256
using TOML

export lock_predecision_computation, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const DESIGN_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK.toml")
const AMENDMENT_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_AMENDMENT_001_LOCK.toml")
const EXTRACTOR_LOCK_001_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_EXTRACTOR_LOCK.toml")
const EXTRACTOR_LOCK_002_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_EXTRACTOR_LOCK_002.toml")
const EXPECTED_EXTRACTOR_LOCK_002_SHA256 =
    "fce4f369e5c7ab7069090ea63aaa52ae0e54e5ead9ee625f5e7771acf7ccb427"
const ACCESS_AMENDMENT_002_LOCK_PATH = joinpath(
    EXPERIMENT_ROOT,
    "PREDECISION_ACCESS_AMENDMENT_002_LOCK.toml",
)
const EXPECTED_ACCESS_AMENDMENT_002_LOCK_SHA256 =
    "560aa75d86e016a838d5b6da3544326fdd606ade33b1934190d9ed7d6d9d6e49"
const EXTRACTOR_LOCK_003_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_EXTRACTOR_LOCK_003.toml")
const EXPECTED_EXTRACTOR_LOCK_003_SHA256 =
    "599eeb90d707a8255e641c9990406962dd4c93cb08b8abcca87b39e94d42fdc9"
const PUBLIC_STAGE_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "predecision_stage",
    "PREDECISION_STAGE_MANIFEST.toml",
)
const LOCAL_STAGE_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "predecision",
    "PREDECISION_STAGE_LOCAL_MANIFEST.toml",
)
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_COMPUTATION_LOCK.toml")
const LOCAL_RESULT_ROOT = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "predecision_computation",
)
const PUBLIC_RESULT_ROOT = joinpath(EXPERIMENT_ROOT, "predecision_computation")
const SEALED_PATHS = [
    "experiments/financial_strategy_library_panel_v3/PREDECISION_COMPUTATION_SPEC.md",
    "julia/src/FinancialStrategyLibraryPanelV3PredecisionComputation.jl",
    "julia/scripts/run_financial_strategy_library_panel_v3_predecision_computation.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_predecision_computation.jl",
    "julia/test/test_financial_strategy_library_panel_v3_predecision_computation.jl",
    "julia/test/run_financial_strategy_library_panel_v3_predecision_computation_tests.jl",
    "julia/Project.toml",
    "julia/Manifest.toml",
]

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

_sha256_text(value) = bytes2hex(sha256(codeunits(String(value))))

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _aggregate(hashes)
    canonical = join(
        ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
    )
    return _sha256_text(canonical)
end

function _verify_lock(path, expected_status)
    isfile(path) || error("required prerequisite lock is absent: $(relpath(path, REPOSITORY_ROOT))")
    lock = TOML.parsefile(path)
    lock["status"] == expected_status || error("unexpected prerequisite lock status")
    hashes = Dict{String,String}(lock["sealed_file_sha256"])
    for relative in sort!(collect(keys(hashes)))
        source = joinpath(REPOSITORY_ROOT, relative)
        isfile(source) || error("sealed prerequisite is absent: $relative")
        _sha256_file(source) == hashes[relative] || error("sealed prerequisite changed: $relative")
    end
    for aggregate_key in (
        "design_aggregate_sha256",
        "amendment_aggregate_sha256",
        "access_amendment_aggregate_sha256",
        "extractor_aggregate_sha256",
    )
        haskey(lock, aggregate_key) || continue
        _aggregate(hashes) == String(lock[aggregate_key]) ||
            error("sealed prerequisite aggregate changed: $aggregate_key")
    end
    return lock
end

function _verify_stage(extractor_sha)
    for path in (PUBLIC_STAGE_MANIFEST_PATH, LOCAL_STAGE_MANIFEST_PATH)
        isfile(path) || error("bounded predecision stage manifest is absent")
    end
    public = TOML.parsefile(PUBLIC_STAGE_MANIFEST_PATH)
    local_manifest = TOML.parsefile(LOCAL_STAGE_MANIFEST_PATH)
    public["status"] == "PREDECISION_RETURNS_STAGED" ||
        error("unexpected public predecision stage status")
    local_manifest["status"] == "PREDECISION_RETURNS_STAGED" ||
        error("unexpected local predecision stage status")
    public["cell_count"] == 38 || error("predecision stage cell count changed")
    public["return_values_included"] === false ||
        error("public predecision stage contains returns")
    local_manifest["return_values_included"] === true ||
        error("local predecision stage does not bind returns")
    for field in (
        "proposal_or_evaluation_values_inspected",
        "proposal_or_evaluation_values_materialized",
        "proposal_or_evaluation_values_used",
    )
        public[field] == 0 || error("predecision stage crossed postdecision boundary: $field")
        local_manifest[field] == 0 ||
            error("local predecision stage crossed postdecision boundary: $field")
    end
    public["predecision_extractor_lock_sha256"] == extractor_sha ||
        error("public predecision stage is not bound to extractor lock 003")
    local_manifest["predecision_extractor_lock_sha256"] == extractor_sha ||
        error("local predecision stage is not bound to extractor lock 003")
    local_manifest["public_manifest_sha256"] ==
        _sha256_text(read(PUBLIC_STAGE_MANIFEST_PATH, String)) ||
        error("local/public predecision stage manifests are not bound")
    public_cells = Dict(Int(cell["cell_index"]) => cell for cell in public["cells"])
    local_cells = Dict(Int(cell["cell_index"]) => cell for cell in local_manifest["cells"])
    sort!(collect(keys(public_cells))) == collect(1:38) ||
        error("public stage cells are not canonical")
    sort!(collect(keys(local_cells))) == collect(1:38) ||
        error("local stage cells are not canonical")
    parquet_hashes = Dict{String,String}()
    for index in 1:38
        public_cell = public_cells[index]
        local_cell = local_cells[index]
        relative = String(local_cell["local_artifact_relative_path"])
        digest = String(local_cell["local_artifact_sha256"])
        public_cell["local_artifact_relative_path"] == relative ||
            error("stage manifest path mismatch in cell $index")
        public_cell["local_artifact_sha256"] == digest ||
            error("stage manifest hash mismatch in cell $index")
        path = joinpath(EXPERIMENT_ROOT, relative)
        isfile(path) || error("staged predecision parquet is absent: $relative")
        _sha256_file(path) == digest || error("staged predecision parquet changed: $relative")
        parquet_hashes[relative] = digest
    end
    return (; public, local_manifest, parquet_hashes)
end

function _payload()
    design = _verify_lock(DESIGN_LOCK_PATH, "LOCKED_PREDECISION")
    amendment = _verify_lock(AMENDMENT_LOCK_PATH, "LOCKED_PREDECISION_IMPLEMENTATION")
    for path in (EXTRACTOR_LOCK_001_PATH, EXTRACTOR_LOCK_002_PATH)
        isfile(path) || error("immutable extractor-history lock is absent")
    end
    extractor_001 = TOML.parsefile(EXTRACTOR_LOCK_001_PATH)
    extractor_002 = TOML.parsefile(EXTRACTOR_LOCK_002_PATH)
    extractor_001["status"] == "LOCKED_PREDECISION_EXTRACTOR" ||
        error("unexpected extractor lock 001 history status")
    extractor_002["status"] == "LOCKED_PREDECISION_EXTRACTOR_002" ||
        error("unexpected extractor lock 002 history status")
    _sha256_file(EXTRACTOR_LOCK_002_PATH) == EXPECTED_EXTRACTOR_LOCK_002_SHA256 ||
        error("extractor lock 002 changed after its final seal")
    access_amendment = _verify_lock(
        ACCESS_AMENDMENT_002_LOCK_PATH,
        "LOCKED_PREDECISION_ACCESS_AMENDMENT_002",
    )
    _sha256_file(ACCESS_AMENDMENT_002_LOCK_PATH) ==
        EXPECTED_ACCESS_AMENDMENT_002_LOCK_SHA256 ||
        error("predecision access amendment 002 changed after its final seal")
    access_amendment["design_lock_sha256"] == _sha256_file(DESIGN_LOCK_PATH) ||
        error("access amendment 002 is not bound to the current design")
    access_amendment["implementation_amendment_lock_sha256"] ==
        _sha256_file(AMENDMENT_LOCK_PATH) ||
        error("access amendment 002 is not bound to implementation amendment 001")
    access_amendment["extractor_lock_001_sha256"] ==
        _sha256_file(EXTRACTOR_LOCK_001_PATH) ||
        error("access amendment 002 is not bound to extractor lock 001")
    access_amendment["extractor_lock_002_sha256"] ==
        _sha256_file(EXTRACTOR_LOCK_002_PATH) ||
        error("access amendment 002 is not bound to extractor lock 002")
    access_amendment["predecision_values_accessed_before_amendment_002"] === true ||
        error("access amendment 002 omitted prior authorized predecision access")
    access_amendment["proposal_or_evaluation_values_inspected_materialized_or_used"] === false ||
        error("access amendment 002 records postdecision value use")
    extractor = _verify_lock(EXTRACTOR_LOCK_003_PATH, "LOCKED_PREDECISION_EXTRACTOR_003")
    extractor["schema_version"] ==
        "financial-strategy-library-panel-v3-predecision-extractor-lock-v3" ||
        error("downstream computation refuses a non-v3 extractor lock")
    _sha256_file(EXTRACTOR_LOCK_003_PATH) == EXPECTED_EXTRACTOR_LOCK_003_SHA256 ||
        error("extractor lock 003 changed after its final seal")
    extractor["design_lock_sha256"] == _sha256_file(DESIGN_LOCK_PATH) ||
        error("extractor lock 003 is not bound to the current base design")
    extractor["implementation_amendment_lock_sha256"] == _sha256_file(AMENDMENT_LOCK_PATH) ||
        error("extractor lock 003 is not bound to implementation amendment 001")
    extractor["access_amendment_002_lock_sha256"] ==
        _sha256_file(ACCESS_AMENDMENT_002_LOCK_PATH) ||
        error("extractor lock 003 is not bound to access amendment 002")
    extractor["extractor_lock_001_sha256"] == _sha256_file(EXTRACTOR_LOCK_001_PATH) ||
        error("extractor lock 003 is not bound to extractor lock 001")
    extractor["previous_extractor_lock_sha256"] == _sha256_file(EXTRACTOR_LOCK_002_PATH) ||
        error("extractor lock 003 is not bound to extractor lock 002")
    extractor["predecision_values_accessed_before_003"] === true ||
        error("extractor lock 003 omitted prior authorized predecision access")
    extractor["proposal_values_inspected_materialized_or_used_before_003"] === false ||
        error("extractor lock 003 records proposal value use")
    extractor["evaluation_values_inspected_materialized_or_used_before_003"] === false ||
        error("extractor lock 003 records evaluation value use")
    extractor["unmasked_value_inspection_materialization_or_use_permitted"] === false ||
        error("extractor lock 003 permits unmasked value use")
    extractor["historical_predecision_return_access_permitted"] === true ||
        error("extractor lock 003 does not authorize bounded predecision access")
    extractor["historical_proposal_or_evaluation_return_access_permitted"] === false ||
        error("extractor lock 003 permits forbidden postdecision access")
    extractor_sha = _sha256_file(EXTRACTOR_LOCK_003_PATH)
    stage = _verify_stage(extractor_sha)

    hashes = Dict{String,String}()
    for relative in SEALED_PATHS
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("predecision computation-lock input is absent: $relative")
        hashes[relative] = _sha256_file(path)
    end
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-predecision-computation-lock-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PREDECISION_COMPUTATION",
        "language" => "Julia",
        "computation_code_aggregate_sha256" => _aggregate(hashes),
        "sealed_file_count" => length(hashes),
        "sealed_file_sha256" => hashes,
        "design_lock_sha256" => _sha256_file(DESIGN_LOCK_PATH),
        "predecision_amendment_lock_sha256" => _sha256_file(AMENDMENT_LOCK_PATH),
        "predecision_access_amendment_002_lock_sha256" =>
            _sha256_file(ACCESS_AMENDMENT_002_LOCK_PATH),
        "predecision_extractor_lock_001_sha256" => _sha256_file(EXTRACTOR_LOCK_001_PATH),
        "predecision_extractor_lock_002_sha256" => _sha256_file(EXTRACTOR_LOCK_002_PATH),
        "predecision_extractor_lock_003_sha256" => extractor_sha,
        "public_stage_manifest_sha256" => _sha256_file(PUBLIC_STAGE_MANIFEST_PATH),
        "local_stage_manifest_sha256" => _sha256_file(LOCAL_STAGE_MANIFEST_PATH),
        "staged_parquet_count" => length(stage.parquet_hashes),
        "staged_parquet_aggregate_sha256" => _aggregate(stage.parquet_hashes),
        "prior_authorized_predecision_access_recorded_by_access_amendment_002" => true,
        "profile_exact_grid_denominator" => 1_000_000_000_000,
        "portfolio_path_count_per_cell" => 96,
        "formation_profile_count_per_cell" => 1_152,
        "compression_profile_count_per_cell" => 1_152,
        "registered_policy_count" => 5,
        "preproposal_trial_rows_per_cell" => 485,
        "historical_predecision_return_computation_permitted" => true,
        "historical_proposal_or_evaluation_return_access_permitted" => false,
        "proposal_return_values_accessed_before_lock" => false,
        "evaluation_return_values_accessed_before_lock" => false,
        "v3_outcomes_opened" => false,
        "next_required_seal" =>
            "frozen predecision dockets exact arms nested action sets and complete trial ledger",
    )
end

function lock_predecision_computation(; check = false)
    if !check
        (ispath(LOCAL_RESULT_ROOT) || ispath(PUBLIC_RESULT_ROOT)) && error(
            "predecision computation outputs exist before the computation lock",
        )
    end
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("v3 predecision computation lock is absent")
        read(LOCK_PATH, String) == text || error("v3 predecision computation lock changed")
    elseif isfile(LOCK_PATH)
        read(LOCK_PATH, String) == text ||
            error("refusing to replace a nonidentical predecision computation lock")
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PREDECISION_COMPUTATION_LOCK_PASSED")
    println("access amendment 002 and extractor lock 003 required: true")
    println("historical proposal/evaluation return access permitted: false")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_predecision_computation(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3PredecisionComputation.main()
end
