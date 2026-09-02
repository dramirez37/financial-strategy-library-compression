module LockFinancialStrategyLibraryPanelV3ProposalPostcompletionBindingAmendment003002

using SHA: sha256
using TOML

export lock_proposal_postcompletion_binding_amendment_003_002, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT, "experiments", "financial_strategy_library_panel_v3",
)
const PREVIOUS_LOCK_PATH = joinpath(
    EXPERIMENT_ROOT, "PROPOSAL_POSTCOMPLETION_BINDING_AMENDMENT_003_LOCK.toml",
)
const EXPECTED_PREVIOUS_LOCK_SHA256 =
    "0d6941cf5448ce3d30e527cc8316b8b8eb0e890e64e9b413c828393cbfdee34c"
const COMPUTATION_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_COMPUTATION_AMENDMENT_001_LOCK_003.toml")
const INTERFACE_LOCK_PATHS = [
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_INTERFACE_LOCK.toml"),
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_INTERFACE_LOCK_002.toml"),
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_INTERFACE_LOCK_003.toml"),
]
const RESULT_SEAL_PATH = joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_RESULT_SEAL.toml")
const LOCK_PATH = joinpath(
    EXPERIMENT_ROOT, "PROPOSAL_POSTCOMPLETION_BINDING_AMENDMENT_003_LOCK_002.toml",
)
const EXPECTED_CHAIN_SHA256 = [
    "3e5723a6e64275b3c812cd40d7e4f4ed8a73c4420b54eb3e5dc6a1928e3c11ee",
    "736089a603b74b8d4dd91040b922319b2bcb58a922eb416448f5b0ca11c717ff",
    "8556cfd48e010bcdb746dc2f333448343c546e8bc422a5c6f3f8d658ff44e9c7",
    "c5c651ecb531d9f93d358bbb5ce8028478001bda78ac26259fd3b33b7c949156",
    "35ac8541432dfd102944024fde36b82324ea3bc943bc6556aef11ca1b2a251b4",
]
const SEALED_PATHS = [
    "experiments/financial_strategy_library_panel_v3/amendments/PROPOSAL_POSTCOMPLETION_BINDING_AMENDMENT_003_002.md",
    "julia/scripts/lock_financial_strategy_library_panel_v3_proposal_postcompletion_binding_amendment_003_002.jl",
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
        error("postcompletion binding lock 001 changed")
    previous = TOML.parsefile(PREVIOUS_LOCK_PATH)
    previous["status"] == "LOCKED_PROPOSAL_POSTCOMPLETION_BINDING_AMENDMENT_003" ||
        error("unexpected postcompletion binding lock 001 status")
    chain_paths = [COMPUTATION_LOCK_PATH; INTERFACE_LOCK_PATHS; RESULT_SEAL_PATH]
    actual_chain = _sha256_file.(chain_paths)
    actual_chain == EXPECTED_CHAIN_SHA256 || error("proposal result chain changed")
    locks = TOML.parsefile.(chain_paths[1:4])
    latest_hashes = Dict{String,String}()
    for lock in locks
        for (relative, digest) in Dict{String,String}(lock["sealed_file_sha256"])
            latest_hashes[relative] = digest
        end
    end
    verified_paths = Set{String}()
    for lock in locks
        for (relative, original_digest) in Dict{String,String}(lock["sealed_file_sha256"])
            actual = _sha256_file(joinpath(REPOSITORY_ROOT, relative))
            actual == original_digest || actual == latest_hashes[relative] ||
                error("proposal chain source changed without a later sealed digest: $relative")
            push!(verified_paths, relative)
        end
    end
    result = TOML.parsefile(RESULT_SEAL_PATH)
    result["proposal_policy_interface_lock_sha256"] == actual_chain[4] ||
        error("proposal result does not bind final interface lock")
    result["bound_local_artifact_count"] == previous["final_local_artifact_count"] ||
        error("proposal final artifact denominator differs across binding locks")
    result["bound_local_artifact_aggregate_sha256"] ==
        previous["final_local_artifact_aggregate_sha256"] ||
        error("proposal final artifact aggregate differs across binding locks")
    result["historical_evaluation_return_access_permitted"] === false ||
        error("proposal result seal permits evaluation access")
    sealed = Dict(
        relative => _sha256_file(joinpath(REPOSITORY_ROOT, relative)) for
        relative in SEALED_PATHS
    )
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-postcompletion-binding-amendment-lock-v2",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PROPOSAL_POSTCOMPLETION_BINDING_AMENDMENT_003_002",
        "language" => "Julia",
        "previous_postcompletion_binding_lock_sha256" => _sha256_file(PREVIOUS_LOCK_PATH),
        "proposal_computation_amendment_lock_003_sha256" => actual_chain[1],
        "proposal_policy_interface_lock_001_sha256" => actual_chain[2],
        "proposal_policy_interface_lock_002_sha256" => actual_chain[3],
        "proposal_policy_interface_lock_003_sha256" => actual_chain[4],
        "proposal_policy_result_seal_sha256" => actual_chain[5],
        "embedded_sealed_source_path_count" => length(verified_paths),
        "embedded_sealed_source_bindings_verified" => true,
        "historical_partial_path_artifact_count" =>
            previous["historical_partial_path_artifact_count"],
        "final_local_artifact_count" => previous["final_local_artifact_count"],
        "final_local_artifact_aggregate_sha256" =>
            previous["final_local_artifact_aggregate_sha256"],
        "proposal_choices_and_returns_known_before_amendment" => true,
        "evaluation_values_inspected_before_amendment" => 0,
        "evaluation_values_materialized_before_amendment" => 0,
        "evaluation_values_used_before_amendment" => 0,
        "historical_evaluation_return_access_permitted" => false,
        "scientific_design_paths_choices_ledgers_or_results_changed" => false,
        "sealed_file_count" => length(sealed),
        "sealed_file_sha256" => sealed,
        "next_required_stage" => "proposal-known robustness freeze before evaluation access",
    )
end

function lock_proposal_postcompletion_binding_amendment_003_002(; check = false)
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("postcompletion binding lock 002 is absent")
        read(LOCK_PATH, String) == text || error("postcompletion binding lock 002 changed")
    elseif isfile(LOCK_PATH)
        read(LOCK_PATH, String) == text ||
            error("refusing to replace nonidentical postcompletion binding lock 002")
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PROPOSAL_POSTCOMPLETION_BINDING_AMENDMENT_003_002_PASSED")
    source_count = payload["embedded_sealed_source_path_count"]
    println("embedded sealed source paths verified: $source_count")
    println("historical checkpoints: 8; final artifacts: 150; evaluation access: 0")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_proposal_postcompletion_binding_amendment_003_002(; check = "--check" in args)
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3ProposalPostcompletionBindingAmendment003002.main()
end
