module LockFinancialStrategyLibraryPanelV3ProposalComputationAmendment001003

using SHA: sha256
using TOML

export lock_proposal_computation_amendment_001_003, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const PREVIOUS_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_COMPUTATION_AMENDMENT_001_LOCK_002.toml")
const LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_COMPUTATION_AMENDMENT_001_LOCK_003.toml")
const PARTIAL_ROOT = joinpath(EXPERIMENT_ROOT, "local_data", "proposal_computation")
const SEALED_PATHS = [
    "julia/scripts/run_financial_strategy_library_panel_v3_proposal.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_proposal_computation_amendment_001_003.jl",
    "julia/test/test_financial_strategy_library_panel_v3_proposal.jl",
]

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _partial_hashes()
    paths = sort!(filter(
        path -> endswith(path, "-paths.parquet"),
        readdir(PARTIAL_ROOT; join = true),
    ))
    length(paths) == 8 || error("second interrupted attempt partial artifact count changed")
    return Dict(relpath(path, EXPERIMENT_ROOT) => _sha256_file(path) for path in paths)
end

function _payload()
    isfile(PREVIOUS_LOCK_PATH) || error("proposal computation amendment lock 002 is absent")
    previous = TOML.parsefile(PREVIOUS_LOCK_PATH)
    previous["status"] == "LOCKED_PROPOSAL_COMPUTATION_AMENDMENT_001_002" ||
        error("unexpected previous proposal computation amendment status")
    previous["historical_evaluation_return_access_permitted"] === false ||
        error("previous proposal computation amendment permits evaluation access")
    previous_hashes = Dict{String,String}(previous["sealed_file_sha256"])
    for (relative, digest) in previous_hashes
        relative in SEALED_PATHS && continue
        _sha256_file(joinpath(REPOSITORY_ROOT, relative)) == digest ||
            error("unchanged proposal computation input changed: $relative")
    end
    partial = _partial_hashes()
    hashes = Dict(
        relative => _sha256_file(joinpath(REPOSITORY_ROOT, relative)) for
        relative in SEALED_PATHS
    )
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-computation-amendment-lock-v3",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PROPOSAL_COMPUTATION_AMENDMENT_001_003",
        "language" => "Julia",
        "previous_proposal_execution_lock_sha256" =>
            previous["previous_proposal_execution_lock_sha256"],
        "previous_proposal_computation_amendment_lock_sha256" =>
            _sha256_file(PREVIOUS_LOCK_PATH),
        "change_scope" => "Julia module qualification compatibility only",
        "scientific_design_changed" => false,
        "policy_rules_changed" => false,
        "proposal_values_accessed_before_amendment" => true,
        "proposal_path_availability_known_before_amendment" => true,
        "evaluation_values_accessed_before_amendment" => false,
        "partial_path_artifact_count" => length(partial),
        "partial_path_artifact_sha256" => partial,
        "completed_choice_artifacts_before_amendment" => 0,
        "completed_ledger_artifacts_before_amendment" => 0,
        "result_manifests_before_amendment" => 0,
        "sealed_file_count" => length(hashes),
        "sealed_file_sha256" => hashes,
        "historical_proposal_return_computation_permitted" => true,
        "historical_evaluation_return_access_permitted" => false,
        "next_required_seal" => "frozen proposal choices and complete proposal trial ledger",
    )
end


function lock_proposal_computation_amendment_001_003(; check = false)
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("proposal computation amendment lock 003 is absent")
        read(LOCK_PATH, String) == text || error("proposal computation amendment lock 003 changed")
    elseif isfile(LOCK_PATH)
        read(LOCK_PATH, String) == text ||
            error("refusing to replace nonidentical proposal computation amendment lock 003")
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PROPOSAL_COMPUTATION_AMENDMENT_001_003_PASSED")
    println("change scope: Julia module qualification compatibility only")
    println("scientific design/policy rules changed: false")
    println("evaluation values accessed: false")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_proposal_computation_amendment_001_003(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3ProposalComputationAmendment001003.main()
end
