module LockFinancialStrategyLibraryPanelV3ProposalStageReplayAmendment002

using SHA: sha256
using TOML

export lock_proposal_stage_replay_amendment_002, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const ORIGINAL_EXECUTION_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PROPOSAL_EXECUTION_LOCK.toml")
const ORIGINAL_EXECUTION_LOCK_SHA256 =
    "86092535a1f8084ecea0b82b8fc41e59ff703536f7ba29fb649c67ac25683fd3"
const FINAL_COMPUTATION_AMENDMENT_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_COMPUTATION_AMENDMENT_001_LOCK_003.toml")
const FINAL_COMPUTATION_AMENDMENT_SHA256 =
    "3e5723a6e64275b3c812cd40d7e4f4ed8a73c4420b54eb3e5dc6a1928e3c11ee"
const PUBLIC_STAGE_PATH =
    joinpath(EXPERIMENT_ROOT, "proposal_stage", "PROPOSAL_STAGE_MANIFEST.toml")
const LOCAL_STAGE_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal",
    "PROPOSAL_STAGE_LOCAL_MANIFEST.toml",
)
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PROPOSAL_STAGE_REPLAY_AMENDMENT_002_LOCK.toml")
const SEALED_PATHS = [
    "experiments/financial_strategy_library_panel_v3/amendments/PROPOSAL_STAGE_REPLAY_AMENDMENT_002.md",
    "julia/scripts/stage_financial_strategy_library_panel_v3_proposal_returns.jl",
    "julia/scripts/run_financial_strategy_library_panel_v3_proposal.jl",
    "julia/scripts/check_financial_strategy_library_panel_v3_proposal_stage_replay.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_proposal_stage_replay_amendment_002.jl",
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
    canonical = join(("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))))
    return _sha256_text(canonical)
end

function _payload()
    _sha256_file(ORIGINAL_EXECUTION_LOCK_PATH) == ORIGINAL_EXECUTION_LOCK_SHA256 ||
        error("original proposal execution lock changed")
    _sha256_file(FINAL_COMPUTATION_AMENDMENT_PATH) == FINAL_COMPUTATION_AMENDMENT_SHA256 ||
        error("final proposal computation amendment changed")
    original = TOML.parsefile(ORIGINAL_EXECUTION_LOCK_PATH)
    final = TOML.parsefile(FINAL_COMPUTATION_AMENDMENT_PATH)
    original["status"] == "LOCKED_PROPOSAL_EXECUTION" ||
        error("unexpected original proposal execution status")
    final["status"] == "LOCKED_PROPOSAL_COMPUTATION_AMENDMENT_001_003" ||
        error("unexpected final proposal computation amendment status")
    final["historical_evaluation_return_access_permitted"] === false ||
        error("final proposal computation amendment permits evaluation access")
    local_stage = TOML.parsefile(LOCAL_STAGE_PATH)
    artifact_hashes = Dict{String,String}(local_stage["local_artifact_sha256"])
    length(artifact_hashes) == 37 || error("proposal stage artifact count changed")
    for (relative, digest) in artifact_hashes
        _sha256_file(joinpath(EXPERIMENT_ROOT, relative)) == digest ||
            error("proposal stage artifact changed: $relative")
    end
    hashes = Dict(
        relative => _sha256_file(joinpath(REPOSITORY_ROOT, relative)) for
        relative in SEALED_PATHS
    )
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-stage-replay-amendment-lock-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PROPOSAL_STAGE_REPLAY_AMENDMENT_002",
        "language" => "Julia",
        "original_proposal_execution_lock_sha256" =>
            _sha256_file(ORIGINAL_EXECUTION_LOCK_PATH),
        "final_proposal_computation_amendment_lock_sha256" =>
            _sha256_file(FINAL_COMPUTATION_AMENDMENT_PATH),
        "public_proposal_stage_manifest_sha256" => _sha256_file(PUBLIC_STAGE_PATH),
        "local_proposal_stage_manifest_sha256" => _sha256_file(LOCAL_STAGE_PATH),
        "proposal_stage_artifact_count" => length(artifact_hashes),
        "proposal_stage_artifact_aggregate_sha256" => _aggregate(artifact_hashes),
        "sealed_file_count" => length(hashes),
        "sealed_file_sha256" => hashes,
        "change_scope" => "amendment-aware stage replay only",
        "scientific_design_paths_choices_or_results_changed" => false,
        "proposal_values_accessed_before_amendment" => true,
        "evaluation_values_accessed_before_amendment" => false,
        "failed_universe_cell_proposal_access_permitted" => false,
        "historical_proposal_return_access_permitted" => true,
        "historical_evaluation_return_access_permitted" => false,
    )
end


function lock_proposal_stage_replay_amendment_002(; check = false)
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("proposal stage replay amendment lock is absent")
        read(LOCK_PATH, String) == text || error("proposal stage replay amendment lock changed")
    elseif isfile(LOCK_PATH)
        read(LOCK_PATH, String) == text ||
            error("refusing to replace nonidentical proposal stage replay amendment lock")
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PROPOSAL_STAGE_REPLAY_AMENDMENT_002_PASSED")
    println("proposal stage artifacts bound: 37")
    println("evaluation access permitted: false")
    return payload
end


function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_proposal_stage_replay_amendment_002(; check = "--check" in args)
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3ProposalStageReplayAmendment002.main()
end
