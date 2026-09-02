module LockFinancialStrategyLibraryPanelV3PredecisionBindingAmendment003

using SHA: sha256
using TOML

export lock_binding_amendment_003, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_BINDING_AMENDMENT_003_LOCK.toml")
const COMPUTATION_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_COMPUTATION_LOCK_002.toml")
const EXPECTED_COMPUTATION_LOCK_SHA256 =
    "e7e8595d7660f7ba1e0f8158bdcd3df3a5dc3632313624b657f5becd55a117ad"
const PUBLIC_RESULT_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "predecision_computation",
    "PREDECISION_COMPUTATION_MANIFEST.toml",
)
const LOCAL_RESULT_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "predecision_computation",
    "PREDECISION_COMPUTATION_LOCAL_MANIFEST.toml",
)
const STRATEGY_INNOVATION_MAIN = "julia/src/StrategyInnovation.jl"
const FIXED_PATHS = [
    "experiments/financial_strategy_library_panel_v3/amendments/PREDECISION_BINDING_AMENDMENT_003.md",
    "experiments/financial_strategy_library_panel_v3/amendments/PREDECISION_BINDING_AMENDMENT_003.toml",
    "experiments/financial_strategy_library_panel_v3/PREDECISION_COMPUTATION_SPEC.md",
    "experiments/financial_strategy_library_panel_v3/PREDECISION_COMPUTATION_LOCK.toml",
    "experiments/financial_strategy_library_panel_v3/PREDECISION_COMPUTATION_LOCK_002.toml",
    "julia/Project.toml",
    "julia/Manifest.toml",
    "julia/src/FinancialStrategyLibraryPanelV3.jl",
    "julia/src/FinancialStrategyLibraryPanelV3Predecision.jl",
    "julia/src/FinancialStrategyLibraryPanelV3PredecisionComputation.jl",
    "julia/scripts/run_financial_strategy_library_panel_v3_predecision_computation.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_predecision_binding_amendment_003.jl",
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

function _strategy_innovation_closure()
    relative_paths = String[]
    active = Set{String}()
    loaded = Set{String}()
    function visit(relative)
        relative = normpath(relative)
        (relative == "julia/src" || startswith(relative, "julia/src/")) ||
            error("StrategyInnovation include escapes julia/src: $relative")
        relative in active && error("StrategyInnovation include cycle at $relative")
        relative in loaded && error("StrategyInnovation includes a source more than once: $relative")
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("StrategyInnovation source is absent: $relative")
        push!(active, relative)
        push!(loaded, relative)
        push!(relative_paths, relative)
        for line in eachline(path)
            matched = match(r"^include\(\"([^\"]+)\"\)$", strip(line))
            isnothing(matched) && continue
            visit(normpath(joinpath(dirname(relative), String(matched.captures[1]))))
        end
        delete!(active, relative)
        return nothing
    end
    visit(STRATEGY_INNOVATION_MAIN)
    length(relative_paths) > 1 || error("StrategyInnovation include closure is empty")
    return relative_paths
end

function _validate_existing_results()
    for path in (PUBLIC_RESULT_MANIFEST_PATH, LOCAL_RESULT_MANIFEST_PATH)
        isfile(path) || error("predecision result manifest is absent")
    end
    public = TOML.parsefile(PUBLIC_RESULT_MANIFEST_PATH)
    local_manifest = TOML.parsefile(LOCAL_RESULT_MANIFEST_PATH)
    for manifest in (public, local_manifest)
        manifest["status"] == "PREPROPOSAL_STRUCTURAL_STATE_FROZEN" ||
            error("unexpected predecision result status")
        manifest["cell_count"] == 38 || error("predecision cell denominator changed")
        manifest["preproposal_trial_ledger_rows"] == 18_430 ||
            error("preproposal ledger denominator changed")
        manifest["proposal_return_values_accessed"] === false ||
            error("proposal returns were accessed before binding amendment 003")
        manifest["evaluation_return_values_accessed"] === false ||
            error("evaluation returns were accessed before binding amendment 003")
    end
    local_manifest["public_manifest_sha256"] == _sha256_file(PUBLIC_RESULT_MANIFEST_PATH) ||
        error("public/local predecision result manifests are not bound")
    return public, local_manifest
end

function _payload()
    _sha256_file(COMPUTATION_LOCK_PATH) == EXPECTED_COMPUTATION_LOCK_SHA256 ||
        error("predecision computation lock 002 changed")
    computation_lock = TOML.parsefile(COMPUTATION_LOCK_PATH)
    computation_lock["status"] == "LOCKED_PREDECISION_COMPUTATION_002" ||
        error("unexpected computation-lock status")
    public, local_manifest = _validate_existing_results()

    closure = _strategy_innovation_closure()
    hashes = Dict{String,String}()
    for relative in vcat(FIXED_PATHS, closure)
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("binding-amendment input is absent: $relative")
        hashes[relative] = _sha256_file(path)
    end
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-predecision-binding-amendment-lock-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PREDECISION_BINDING_AMENDMENT_003",
        "language" => "Julia",
        "amendment_type" => "post-result provenance binding only",
        "scientific_design_changed" => false,
        "predecision_results_known_before_amendment" => true,
        "predecision_computation_lock_002_sha256" => _sha256_file(COMPUTATION_LOCK_PATH),
        "public_result_manifest_sha256_at_amendment" => _sha256_file(PUBLIC_RESULT_MANIFEST_PATH),
        "local_result_manifest_sha256_at_amendment" => _sha256_file(LOCAL_RESULT_MANIFEST_PATH),
        "result_cell_count_at_amendment" => public["cell_count"],
        "result_trial_rows_at_amendment" => local_manifest["preproposal_trial_ledger_rows"],
        "strategy_innovation_include_count" => length(closure) - 1,
        "strategy_innovation_load_order" => closure,
        "loaded_source_aggregate_sha256" => _aggregate(Dict(path => hashes[path] for path in closure)),
        "sealed_file_count" => length(hashes),
        "sealed_file_sha256" => hashes,
        "required_replay_cell_count" => 38,
        "required_replay_mode" => "byte-identical full computation replay",
        "proposal_return_values_accessed_before_lock" => false,
        "evaluation_return_values_accessed_before_lock" => false,
        "historical_proposal_or_evaluation_return_access_permitted" => false,
        "next_required_seal" => "PREDECISION_COMPUTATION_RESULT_SEAL",
    )
end

function lock_binding_amendment_003(; check = false)
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("predecision binding amendment 003 lock is absent")
        read(LOCK_PATH, String) == text || error("predecision binding amendment 003 lock changed")
    elseif isfile(LOCK_PATH)
        read(LOCK_PATH, String) == text ||
            error("refusing to replace nonidentical binding amendment 003 lock")
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PREDECISION_BINDING_AMENDMENT_003_PASSED")
    include_count = payload["strategy_innovation_include_count"]
    println("StrategyInnovation included sources frozen: $include_count")
    println("scientific design changed: false")
    println("proposal/evaluation returns accessed: false")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_binding_amendment_003(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3PredecisionBindingAmendment003.main()
end
