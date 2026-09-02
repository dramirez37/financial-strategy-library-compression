module SealFinancialStrategyLibraryPanelV3ProposalPolicyResult

using SHA: sha256
using TOML

export seal_proposal_policy_result, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const INTERFACE_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_INTERFACE_LOCK_003.toml")
const PUBLIC_POLICY_PATH = joinpath(
    EXPERIMENT_ROOT,
    "proposal_policy",
    "PROPOSAL_POLICY_MANIFEST.toml",
)
const LOCAL_POLICY_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal_policy",
    "PROPOSAL_POLICY_LOCAL_MANIFEST.toml",
)
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
const SEAL_PATH = joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_RESULT_SEAL.toml")

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

function _bound_artifacts(local_stage, local_computation)
    hashes = Dict{String,String}(local_stage["local_artifact_sha256"])
    for cell in local_computation["cells"]
        for (relative, digest) in Dict{String,String}(cell["local_artifact_sha256"])
            haskey(hashes, relative) && error("duplicate proposal result artifact")
            hashes[relative] = digest
        end
    end
    length(hashes) == 150 || error("proposal result artifact denominator changed")
    for (relative, digest) in hashes
        path = joinpath(EXPERIMENT_ROOT, relative)
        isfile(path) || error("proposal result artifact is absent: $relative")
        _sha256_file(path) == digest || error("proposal result artifact changed: $relative")
    end
    return hashes
end

function _payload()
    lock = TOML.parsefile(INTERFACE_LOCK_PATH)
    lock["status"] == "LOCKED_PROPOSAL_POLICY_INTERFACE_003" ||
        error("proposal policy interface is not locked")
    lock["historical_evaluation_return_access_permitted"] === false ||
        error("proposal policy interface permits evaluation access")
    for (relative, digest) in Dict{String,String}(lock["sealed_file_sha256"])
        _sha256_file(joinpath(REPOSITORY_ROOT, relative)) == digest ||
            error("proposal policy interface input changed: $relative")
    end
    public = TOML.parsefile(PUBLIC_POLICY_PATH)
    local_policy = TOML.parsefile(LOCAL_POLICY_PATH)
    for manifest in (public, local_policy)
        manifest["status"] == "PROPOSAL_POLICY_INTERFACE_FROZEN" ||
            error("unexpected proposal policy manifest status")
        manifest["cell_count"] == 38 || error("proposal policy cell denominator changed")
        manifest["proposal_trial_ledger_rows"] == 18_430 ||
            error("proposal policy ledger denominator changed")
        manifest["evaluation_values_inspected"] == 0 || error("evaluation values were inspected")
        manifest["evaluation_values_materialized"] == 0 ||
            error("evaluation values were materialized")
        manifest["evaluation_values_used"] == 0 || error("evaluation values were used")
    end
    public["selected_strategy_identities_included"] === false ||
        error("public proposal policy manifest contains selected identities")
    local_policy["public_manifest_sha256"] == _sha256_file(PUBLIC_POLICY_PATH) ||
        error("public/local proposal policy manifests are not bound")
    local_stage = TOML.parsefile(LOCAL_STAGE_PATH)
    local_computation = TOML.parsefile(LOCAL_COMPUTATION_PATH)
    artifacts = _bound_artifacts(local_stage, local_computation)
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-policy-result-seal-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "SEALED_PROPOSAL_POLICY_RESULT",
        "language" => "Julia",
        "proposal_policy_interface_lock_sha256" => _sha256_file(INTERFACE_LOCK_PATH),
        "public_proposal_policy_manifest_sha256" => _sha256_file(PUBLIC_POLICY_PATH),
        "local_proposal_policy_manifest_sha256" => _sha256_file(LOCAL_POLICY_PATH),
        "proposal_policy_manifest_sha256" => _sha256_file(PUBLIC_POLICY_PATH),
        "proposal_policy_local_manifest_sha256" => _sha256_file(LOCAL_POLICY_PATH),
        "local_proposal_stage_manifest_sha256" => _sha256_file(LOCAL_STAGE_PATH),
        "local_proposal_computation_manifest_sha256" =>
            _sha256_file(LOCAL_COMPUTATION_PATH),
        "bound_local_artifact_count" => length(artifacts),
        "bound_local_artifact_aggregate_sha256" => _aggregate(artifacts),
        "all_bound_local_artifact_hashes_verified" => true,
        "cell_count" => 38,
        "available_cell_count" => 37,
        "failed_universe_cells_retained" => 1,
        "registered_policy_count" => 5,
        "proposal_trial_ledger_rows" => 18_430,
        "proposal_policy_choices_known_before_result_seal" => true,
        "public_selected_strategy_identities_included" => false,
        "local_selected_strategy_identities_sealed" => true,
        "evaluation_values_inspected_before_seal" => 0,
        "evaluation_values_materialized_before_seal" => 0,
        "evaluation_values_used_before_seal" => 0,
        "historical_evaluation_return_access_permitted" => false,
        "next_permitted_stage" => "separately sealed evaluation-year extraction",
    )
end

function seal_proposal_policy_result(; check = false)
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(SEAL_PATH) || error("proposal policy result seal is absent")
        read(SEAL_PATH, String) == text || error("proposal policy result seal changed")
    elseif isfile(SEAL_PATH)
        read(SEAL_PATH, String) == text || error("refusing to replace nonidentical policy seal")
    else
        open(SEAL_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PROPOSAL_POLICY_RESULT_SEAL_PASSED")
    println("cells sealed: 38; locally available: 37")
    println("proposal trial-ledger rows sealed: 18430")
    println("evaluation values inspected/materialized/used: 0")
    return payload
end


function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    seal_proposal_policy_result(; check = "--check" in args)
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    SealFinancialStrategyLibraryPanelV3ProposalPolicyResult.main()
end
