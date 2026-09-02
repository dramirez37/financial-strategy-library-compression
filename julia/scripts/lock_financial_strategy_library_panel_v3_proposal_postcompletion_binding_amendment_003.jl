module LockFinancialStrategyLibraryPanelV3ProposalPostcompletionBindingAmendment003

using SHA: sha256
using TOML

export lock_proposal_postcompletion_binding_amendment_003, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const COMPUTATION_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_COMPUTATION_AMENDMENT_001_LOCK_003.toml")
const INTERFACE_LOCK_PATHS = [
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_INTERFACE_LOCK.toml"),
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_INTERFACE_LOCK_002.toml"),
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_INTERFACE_LOCK_003.toml"),
]
const RESULT_SEAL_PATH = joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_RESULT_SEAL.toml")
const LOCAL_STAGE_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal",
    "PROPOSAL_STAGE_LOCAL_MANIFEST.toml",
)
const LOCAL_COMPUTATION_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal_computation",
    "PROPOSAL_COMPUTATION_LOCAL_MANIFEST.toml",
)
const PUBLIC_POLICY_PATH =
    joinpath(EXPERIMENT_ROOT, "proposal_policy", "PROPOSAL_POLICY_MANIFEST.toml")
const LOCAL_POLICY_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal_policy",
    "PROPOSAL_POLICY_LOCAL_MANIFEST.toml",
)
const LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_POSTCOMPLETION_BINDING_AMENDMENT_003_LOCK.toml")
const EXPECTED_CHAIN_SHA256 = [
    "3e5723a6e64275b3c812cd40d7e4f4ed8a73c4420b54eb3e5dc6a1928e3c11ee",
    "736089a603b74b8d4dd91040b922319b2bcb58a922eb416448f5b0ca11c717ff",
    "8556cfd48e010bcdb746dc2f333448343c546e8bc422a5c6f3f8d658ff44e9c7",
    "c5c651ecb531d9f93d358bbb5ce8028478001bda78ac26259fd3b33b7c949156",
    "35ac8541432dfd102944024fde36b82324ea3bc943bc6556aef11ca1b2a251b4",
]
const SEALED_PATHS = [
    "experiments/financial_strategy_library_panel_v3/amendments/PROPOSAL_POSTCOMPLETION_BINDING_AMENDMENT_003.md",
    "julia/scripts/lock_financial_strategy_library_panel_v3_proposal_postcompletion_binding_amendment_003.jl",
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

function _final_artifact_hashes()
    local_stage = TOML.parsefile(LOCAL_STAGE_PATH)
    local_computation = TOML.parsefile(LOCAL_COMPUTATION_PATH)
    local_stage["status"] == "PROPOSAL_RETURNS_STAGED" ||
        error("unexpected proposal stage status")
    local_computation["status"] == "PROPOSAL_POLICY_CHOICES_FROZEN" ||
        error("unexpected proposal computation status")
    hashes = Dict{String,String}(local_stage["local_artifact_sha256"])
    for cell in local_computation["cells"]
        for (relative, digest) in Dict{String,String}(cell["local_artifact_sha256"])
            haskey(hashes, relative) && error("duplicate final proposal artifact: $relative")
            hashes[relative] = digest
        end
    end
    length(hashes) == 150 || error("final proposal artifact denominator changed")
    for (relative, digest) in hashes
        _sha256_file(joinpath(EXPERIMENT_ROOT, relative)) == digest ||
            error("final proposal artifact changed: $relative")
    end
    return hashes
end

function _payload()
    chain_paths = [COMPUTATION_LOCK_PATH; INTERFACE_LOCK_PATHS; RESULT_SEAL_PATH]
    actual_chain = _sha256_file.(chain_paths)
    actual_chain == EXPECTED_CHAIN_SHA256 || error("proposal postcompletion chain changed")

    computation = TOML.parsefile(COMPUTATION_LOCK_PATH)
    computation["status"] == "LOCKED_PROPOSAL_COMPUTATION_AMENDMENT_001_003" ||
        error("unexpected proposal computation amendment status")
    computation["historical_evaluation_return_access_permitted"] === false ||
        error("proposal computation amendment permits evaluation access")
    partial = Dict{String,String}(computation["partial_path_artifact_sha256"])
    length(partial) == 8 || error("historical partial-path checkpoint count changed")
    for (relative, digest) in partial
        _sha256_file(joinpath(EXPERIMENT_ROOT, relative)) == digest ||
            error("historical proposal checkpoint changed: $relative")
    end

    interface1, interface2, interface3 = TOML.parsefile.(INTERFACE_LOCK_PATHS)
    interface1["status"] == "LOCKED_PROPOSAL_POLICY_INTERFACE" ||
        error("unexpected proposal interface lock 001 status")
    interface1["final_proposal_computation_amendment_lock_sha256"] == actual_chain[1] ||
        error("interface lock 001 does not bind computation lock 003")
    interface2["status"] == "LOCKED_PROPOSAL_POLICY_INTERFACE_002" ||
        error("unexpected proposal interface lock 002 status")
    interface2["previous_proposal_policy_interface_lock_sha256"] == actual_chain[2] ||
        error("interface lock 002 does not bind interface lock 001")
    interface3["status"] == "LOCKED_PROPOSAL_POLICY_INTERFACE_003" ||
        error("unexpected proposal interface lock 003 status")
    interface3["previous_proposal_policy_interface_lock_sha256"] == actual_chain[3] ||
        error("interface lock 003 does not bind interface lock 002")
    for interface in (interface1, interface2, interface3)
        interface["historical_evaluation_return_access_permitted"] === false ||
            error("proposal interface chain permits evaluation access")
    end

    result = TOML.parsefile(RESULT_SEAL_PATH)
    result["status"] == "SEALED_PROPOSAL_POLICY_RESULT" ||
        error("unexpected proposal policy result status")
    result["proposal_policy_interface_lock_sha256"] == actual_chain[4] ||
        error("proposal result seal does not bind interface lock 003")
    result["historical_evaluation_return_access_permitted"] === false ||
        error("proposal result seal permits evaluation access")
    for field in (
        "evaluation_values_inspected_before_seal",
        "evaluation_values_materialized_before_seal",
        "evaluation_values_used_before_seal",
    )
        result[field] == 0 || error("proposal result seal records evaluation access")
    end
    result["proposal_policy_manifest_sha256"] == _sha256_file(PUBLIC_POLICY_PATH) ||
        error("proposal result seal does not bind the public policy manifest")
    result["proposal_policy_local_manifest_sha256"] == _sha256_file(LOCAL_POLICY_PATH) ||
        error("proposal result seal does not bind the local policy manifest")

    final_artifacts = _final_artifact_hashes()
    final_aggregate = _aggregate(final_artifacts)
    result["bound_local_artifact_count"] == length(final_artifacts) ||
        error("proposal result seal final artifact count changed")
    result["bound_local_artifact_aggregate_sha256"] == final_aggregate ||
        error("proposal result seal final artifact aggregate changed")
    for (relative, digest) in partial
        get(final_artifacts, relative, "") == digest ||
            error("historical checkpoint is absent from final denominator: $relative")
    end

    sealed = Dict(
        relative => _sha256_file(joinpath(REPOSITORY_ROOT, relative)) for
        relative in SEALED_PATHS
    )
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-postcompletion-binding-amendment-lock-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PROPOSAL_POSTCOMPLETION_BINDING_AMENDMENT_003",
        "language" => "Julia",
        "proposal_computation_amendment_lock_003_sha256" => actual_chain[1],
        "proposal_policy_interface_lock_001_sha256" => actual_chain[2],
        "proposal_policy_interface_lock_002_sha256" => actual_chain[3],
        "proposal_policy_interface_lock_003_sha256" => actual_chain[4],
        "proposal_policy_result_seal_sha256" => actual_chain[5],
        "historical_partial_path_artifact_count" => length(partial),
        "historical_partial_path_artifact_aggregate_sha256" => _aggregate(partial),
        "historical_partial_path_artifact_sha256" => partial,
        "final_local_artifact_count" => length(final_artifacts),
        "final_local_artifact_aggregate_sha256" => final_aggregate,
        "final_artifact_denominator_separately_bound" => true,
        "partial_checkpoint_interpreted_as_final_denominator" => false,
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

function lock_proposal_postcompletion_binding_amendment_003(; check = false)
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("proposal postcompletion binding amendment is absent")
        read(LOCK_PATH, String) == text ||
            error("proposal postcompletion binding amendment changed")
    elseif isfile(LOCK_PATH)
        read(LOCK_PATH, String) == text ||
            error("refusing to replace nonidentical postcompletion binding amendment")
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PROPOSAL_POSTCOMPLETION_BINDING_AMENDMENT_003_PASSED")
    println("historical checkpoints verified: 8; final artifacts verified: 150")
    println("evaluation values inspected/materialized/used: 0")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_proposal_postcompletion_binding_amendment_003(; check = "--check" in args)
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3ProposalPostcompletionBindingAmendment003.main()
end
