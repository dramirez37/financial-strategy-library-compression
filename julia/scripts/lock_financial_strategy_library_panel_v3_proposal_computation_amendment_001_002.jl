module LockFinancialStrategyLibraryPanelV3ProposalComputationAmendment001002

using SHA: sha256
using TOML

export lock_proposal_computation_amendment_001_002, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const PREVIOUS_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_COMPUTATION_AMENDMENT_001_LOCK.toml")
const EXPECTED_PREVIOUS_LOCK_SHA256 =
    "a6a144dffad2e3c8c1548fefb6ced988d687ec5ebd4df4b6af29c782e0b5cb2d"
const LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_COMPUTATION_AMENDMENT_001_LOCK_002.toml")
const SEALED_PATHS = [
    "julia/scripts/run_financial_strategy_library_panel_v3_proposal.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_proposal_computation_amendment_001_002.jl",
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

function _payload()
    _sha256_file(PREVIOUS_LOCK_PATH) == EXPECTED_PREVIOUS_LOCK_SHA256 ||
        error("proposal computation amendment lock 001 changed")
    previous = TOML.parsefile(PREVIOUS_LOCK_PATH)
    previous["status"] == "LOCKED_PROPOSAL_COMPUTATION_AMENDMENT_001" ||
        error("unexpected prior proposal computation amendment status")
    for (relative, digest) in Dict{String,String}(previous["sealed_file_sha256"])
        relative in SEALED_PATHS && continue
        _sha256_file(joinpath(REPOSITORY_ROOT, relative)) == digest ||
            error("unchanged proposal amendment input changed: $relative")
    end
    partial = Dict{String,String}(previous["partial_path_artifact_sha256"])
    for (relative, digest) in partial
        _sha256_file(joinpath(EXPERIMENT_ROOT, relative)) == digest ||
            error("partial proposal path artifact changed: $relative")
    end
    hashes = Dict(
        relative => _sha256_file(joinpath(REPOSITORY_ROOT, relative)) for
        relative in SEALED_PATHS
    )
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-computation-amendment-lock-v2",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PROPOSAL_COMPUTATION_AMENDMENT_001_002",
        "language" => "Julia",
        "previous_proposal_execution_lock_sha256" =>
            previous["previous_proposal_execution_lock_sha256"],
        "previous_proposal_computation_amendment_lock_sha256" =>
            _sha256_file(PREVIOUS_LOCK_PATH),
        "change_scope" => "amendment-aware sealed-source verification only",
        "scientific_design_changed" => false,
        "policy_rules_changed" => false,
        "proposal_values_accessed_before_amendment" => true,
        "proposal_path_availability_known_before_amendment" => true,
        "evaluation_values_accessed_before_amendment" => false,
        "partial_path_artifact_count" => length(partial),
        "partial_path_artifact_sha256" => partial,
        "sealed_file_count" => length(hashes),
        "sealed_file_sha256" => hashes,
        "historical_proposal_return_computation_permitted" => true,
        "historical_evaluation_return_access_permitted" => false,
        "next_required_seal" => "frozen proposal choices and complete proposal trial ledger",
    )
end

function lock_proposal_computation_amendment_001_002(; check = false)
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("proposal computation amendment lock 002 is absent")
        read(LOCK_PATH, String) == text || error("proposal computation amendment lock 002 changed")
    elseif isfile(LOCK_PATH)
        read(LOCK_PATH, String) == text ||
            error("refusing to replace nonidentical proposal computation amendment lock 002")
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PROPOSAL_COMPUTATION_AMENDMENT_001_002_PASSED")
    println("change scope: amendment-aware sealed-source verification only")
    println("scientific design/policy rules changed: false")
    println("evaluation values accessed: false")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_proposal_computation_amendment_001_002(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3ProposalComputationAmendment001002.main()
end
