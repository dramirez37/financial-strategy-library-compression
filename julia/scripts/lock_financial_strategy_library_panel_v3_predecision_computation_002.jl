module LockFinancialStrategyLibraryPanelV3PredecisionComputation002

using Parquet
using SHA: sha256
using TOML

include(joinpath(
    @__DIR__,
    "run_financial_strategy_library_panel_v3_predecision_computation.jl",
))

export lock_predecision_computation_002, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const PREVIOUS_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_COMPUTATION_LOCK.toml")
const EXPECTED_PREVIOUS_LOCK_SHA256 =
    "db4c9cc5aa6427ad8e08d516c2bb43e82e5b9e552619584f68c0b1e908556c20"
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_COMPUTATION_LOCK_002.toml")
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
const LOCAL_RESULT_ROOT = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "predecision_computation",
)
const PUBLIC_RESULT_ROOT = joinpath(EXPERIMENT_ROOT, "predecision_computation")
const SEALED_PATHS = [
    "julia/scripts/run_financial_strategy_library_panel_v3_predecision_computation.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_predecision_computation_002.jl",
    "julia/test/test_financial_strategy_library_panel_v3_predecision_computation_io.jl",
    "julia/test/run_financial_strategy_library_panel_v3_predecision_computation_io_tests.jl",
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

function _synthetic_io_sentinel()
    return mktempdir() do directory
        path = joinpath(directory, "synthetic-stage.parquet")
        Parquet.write_parquet(path, (;
            permno = Int64[10, 10, 20, 20],
            date = ["2000-01-03", "2000-01-04", "2000-01-03", "2000-01-04"],
            total_return = [0.01, -1.0, 0.02, 0.03],
            return_available = trues(4),
            terminal_delisting = Bool[false, true, false, false],
            return_flag = fill("NA", 4),
            delisting_flag = ["N", "D", "N", "N"],
        ))
        columns = RunFinancialStrategyLibraryPanelV3PredecisionComputation._parquet_columns(path)
        values = collect(skipmissing(columns.total_return))
        values == [0.01, -1.0, 0.02, 0.03] || error("synthetic Parquet.Table sentinel changed")
        return Dict{String,Any}(
            "status" => "SYNTHETIC_PARQUET_TABLE_COMPATIBILITY_PASSED",
            "row_count" => length(values),
            "exact_negative_one_preserved" => minimum(values) == -1.0,
            "historical_return_values_accessed" => false,
        )
    end
end

function _payload()
    isfile(PREVIOUS_LOCK_PATH) || error("initial predecision computation lock is absent")
    _sha256_file(PREVIOUS_LOCK_PATH) == EXPECTED_PREVIOUS_LOCK_SHA256 ||
        error("initial predecision computation lock changed")
    previous = TOML.parsefile(PREVIOUS_LOCK_PATH)
    previous["status"] == "LOCKED_PREDECISION_COMPUTATION" ||
        error("unexpected initial computation-lock status")
    previous["proposal_return_values_accessed_before_lock"] === false ||
        error("initial computation lock records proposal access")
    previous["evaluation_return_values_accessed_before_lock"] === false ||
        error("initial computation lock records evaluation access")
    _sha256_file(PUBLIC_STAGE_MANIFEST_PATH) == previous["public_stage_manifest_sha256"] ||
        error("public stage manifest changed after initial computation lock")
    _sha256_file(LOCAL_STAGE_MANIFEST_PATH) == previous["local_stage_manifest_sha256"] ||
        error("local stage manifest changed after initial computation lock")

    for (relative, digest) in previous["sealed_file_sha256"]
        relative in (
            "julia/scripts/run_financial_strategy_library_panel_v3_predecision_computation.jl",
            "julia/scripts/lock_financial_strategy_library_panel_v3_predecision_computation.jl",
        ) && continue
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("unchanged initial computation input is absent: $relative")
        _sha256_file(path) == digest || error("unamended computation input changed: $relative")
    end
    public_stage = TOML.parsefile(PUBLIC_STAGE_MANIFEST_PATH)
    local_stage = TOML.parsefile(LOCAL_STAGE_MANIFEST_PATH)
    for field in (
        "proposal_or_evaluation_values_inspected",
        "proposal_or_evaluation_values_materialized",
        "proposal_or_evaluation_values_used",
    )
        public_stage[field] == 0 || error("public stage crossed postdecision boundary")
        local_stage[field] == 0 || error("local stage crossed postdecision boundary")
    end
    local_stage["public_manifest_sha256"] ==
        _sha256_text(read(PUBLIC_STAGE_MANIFEST_PATH, String)) ||
        error("stage manifests are not bound")
    cells = Dict(Int(cell["cell_index"]) => cell for cell in local_stage["cells"])
    length(cells) == 38 || error("staged-cell denominator changed")
    parquet_hashes = Dict{String,String}()
    for index in 1:38
        cell = cells[index]
        relative = String(cell["local_artifact_relative_path"])
        digest = String(cell["local_artifact_sha256"])
        path = joinpath(EXPERIMENT_ROOT, relative)
        isfile(path) || error("staged cell parquet is absent: $relative")
        _sha256_file(path) == digest || error("staged cell parquet changed: $relative")
        parquet_hashes[relative] = digest
    end
    _aggregate(parquet_hashes) == previous["staged_parquet_aggregate_sha256"] ||
        error("staged parquet aggregate changed after initial computation lock")

    hashes = Dict{String,String}()
    for relative in SEALED_PATHS
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("computation lock 002 input is absent: $relative")
        hashes[relative] = _sha256_file(path)
    end
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-predecision-computation-lock-v2",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PREDECISION_COMPUTATION_002",
        "language" => "Julia",
        "previous_computation_lock_sha256" => _sha256_file(PREVIOUS_LOCK_PATH),
        "public_stage_manifest_sha256" => _sha256_file(PUBLIC_STAGE_MANIFEST_PATH),
        "local_stage_manifest_sha256" => _sha256_file(LOCAL_STAGE_MANIFEST_PATH),
        "staged_parquet_count" => length(parquet_hashes),
        "staged_parquet_aggregate_sha256" => _aggregate(parquet_hashes),
        "computation_code_aggregate_sha256" => _aggregate(hashes),
        "sealed_file_count" => length(hashes),
        "sealed_file_sha256" => hashes,
        "change_scope" => "Parquet.jl Tables API compatibility only",
        "scientific_design_changed" => false,
        "initial_attempt_opened_parquet_metadata" => true,
        "initial_attempt_return_values_inspected_or_materialized" => false,
        "initial_attempt_local_result_artifacts_written" => false,
        "synthetic_io_sentinel" => _synthetic_io_sentinel(),
        "historical_predecision_return_computation_permitted" => true,
        "historical_proposal_or_evaluation_return_access_permitted" => false,
        "proposal_return_values_accessed_before_lock_002" => false,
        "evaluation_return_values_accessed_before_lock_002" => false,
        "v3_outcomes_opened" => false,
        "next_required_seal" =>
            "frozen predecision dockets exact arms nested action sets and complete trial ledger",
    )
end

function lock_predecision_computation_002(; check = false)
    if !check
        (ispath(LOCAL_RESULT_ROOT) || ispath(PUBLIC_RESULT_ROOT)) && error(
            "predecision computation result artifacts exist before lock 002",
        )
    end
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("v3 predecision computation lock 002 is absent")
        read(LOCK_PATH, String) == text || error("v3 predecision computation lock 002 changed")
    elseif isfile(LOCK_PATH)
        read(LOCK_PATH, String) == text ||
            error("refusing to replace a nonidentical computation lock 002")
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PREDECISION_COMPUTATION_LOCK_002_PASSED")
    println("synthetic Parquet.Table compatibility sentinel: passed")
    println("historical proposal/evaluation return access permitted: false")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_predecision_computation_002(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3PredecisionComputation002.main()
end
