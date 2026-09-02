module LockFinancialStrategyLibraryPanelV3ProposalPolicyInterface003

using SHA: sha256
using TOML

export lock_proposal_policy_interface_003, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const PREVIOUS_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_INTERFACE_LOCK_002.toml")
const EXPECTED_PREVIOUS_LOCK_SHA256 =
    "8556cfd48e010bcdb746dc2f333448343c546e8bc422a5c6f3f8d658ff44e9c7"
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_INTERFACE_LOCK_003.toml")
const SEALED_PATHS = [
    "julia/scripts/export_financial_strategy_library_panel_v3_proposal_policy.jl",
    "julia/scripts/seal_financial_strategy_library_panel_v3_proposal_policy_result.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_proposal_policy_interface_003.jl",
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
        error("proposal policy interface lock 002 changed")
    previous = TOML.parsefile(PREVIOUS_LOCK_PATH)
    previous["status"] == "LOCKED_PROPOSAL_POLICY_INTERFACE_002" ||
        error("unexpected previous proposal policy interface status")
    previous["historical_evaluation_return_access_permitted"] === false ||
        error("previous proposal policy interface permits evaluation access")
    hashes = Dict(
        relative => _sha256_file(joinpath(REPOSITORY_ROOT, relative)) for
        relative in SEALED_PATHS
    )
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-policy-interface-lock-v3",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PROPOSAL_POLICY_INTERFACE_003",
        "language" => "Julia",
        "previous_proposal_policy_interface_lock_sha256" => _sha256_file(PREVIOUS_LOCK_PATH),
        "change_scope" => "make exporter and seal verifier consume the final interface lock",
        "scientific_design_or_policy_choices_changed" => false,
        "bound_local_artifact_count" => previous["bound_local_artifact_count"],
        "bound_local_artifact_aggregate_sha256" =>
            previous["bound_local_artifact_aggregate_sha256"],
        "public_proposal_stage_manifest_sha256" =>
            previous["public_proposal_stage_manifest_sha256"],
        "local_proposal_stage_manifest_sha256" =>
            previous["local_proposal_stage_manifest_sha256"],
        "public_proposal_computation_manifest_sha256" =>
            previous["public_proposal_computation_manifest_sha256"],
        "local_proposal_computation_manifest_sha256" =>
            previous["local_proposal_computation_manifest_sha256"],
        "sealed_file_count" => length(hashes),
        "sealed_file_sha256" => hashes,
        "proposal_policy_choices_known_before_interface_lock" => true,
        "proposal_values_accessed_before_lock" => true,
        "evaluation_values_accessed_before_lock" => false,
        "historical_evaluation_return_access_permitted" => false,
        "next_required_seal" => "PROPOSAL_POLICY_RESULT_SEAL",
    )
end


function lock_proposal_policy_interface_003(; check = false)
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("proposal policy interface lock 003 is absent")
        read(LOCK_PATH, String) == text || error("proposal policy interface lock 003 changed")
    elseif isfile(LOCK_PATH)
        read(LOCK_PATH, String) == text ||
            error("refusing to replace nonidentical proposal policy interface lock 003")
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PROPOSAL_POLICY_INTERFACE_LOCK_003_PASSED")
    println("change scope: final-lock consumption only")
    println("evaluation access permitted: false")
    return payload
end


function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_proposal_policy_interface_003(; check = "--check" in args)
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3ProposalPolicyInterface003.main()
end
