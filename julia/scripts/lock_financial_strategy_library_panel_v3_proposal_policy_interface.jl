module LockFinancialStrategyLibraryPanelV3ProposalPolicyInterface

using SHA: sha256
using TOML

export lock_proposal_policy_interface, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const AMENDMENT_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_COMPUTATION_AMENDMENT_001_LOCK_003.toml")
const EXPECTED_AMENDMENT_LOCK_SHA256 =
    "3e5723a6e64275b3c812cd40d7e4f4ed8a73c4420b54eb3e5dc6a1928e3c11ee"
const PUBLIC_STAGE_PATH =
    joinpath(EXPERIMENT_ROOT, "proposal_stage", "PROPOSAL_STAGE_MANIFEST.toml")
const LOCAL_STAGE_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal",
    "PROPOSAL_STAGE_LOCAL_MANIFEST.toml",
)
const PUBLIC_COMPUTATION_PATH = joinpath(
    EXPERIMENT_ROOT,
    "proposal_computation",
    "PROPOSAL_COMPUTATION_MANIFEST.toml",
)
const LOCAL_COMPUTATION_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal_computation",
    "PROPOSAL_COMPUTATION_LOCAL_MANIFEST.toml",
)
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_INTERFACE_LOCK.toml")
const OUTPUT_PATHS = [
    joinpath(EXPERIMENT_ROOT, "proposal_policy"),
    joinpath(EXPERIMENT_ROOT, "local_data", "proposal_policy"),
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_RESULT_SEAL.toml"),
]
const SEALED_PATHS = [
    "experiments/financial_strategy_library_panel_v3/PROPOSAL_POLICY_INTERFACE.md",
    "julia/scripts/export_financial_strategy_library_panel_v3_proposal_policy.jl",
    "julia/scripts/seal_financial_strategy_library_panel_v3_proposal_policy_result.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_proposal_policy_interface.jl",
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

function _local_artifacts(local_stage, local_computation)
    hashes = Dict{String,String}(local_stage["local_artifact_sha256"])
    for cell in local_computation["cells"]
        for (relative, digest) in Dict{String,String}(cell["local_artifact_sha256"])
            haskey(hashes, relative) && error("duplicate proposal artifact")
            hashes[relative] = digest
        end
    end
    length(hashes) == 150 || error("proposal artifact denominator changed")
    for (relative, digest) in hashes
        _sha256_file(joinpath(EXPERIMENT_ROOT, relative)) == digest ||
            error("proposal artifact changed before policy-interface lock: $relative")
    end
    return hashes
end

function _payload()
    _sha256_file(AMENDMENT_LOCK_PATH) == EXPECTED_AMENDMENT_LOCK_SHA256 ||
        error("final proposal computation amendment lock changed")
    amendment = TOML.parsefile(AMENDMENT_LOCK_PATH)
    amendment["status"] == "LOCKED_PROPOSAL_COMPUTATION_AMENDMENT_001_003" ||
        error("unexpected final proposal computation amendment status")
    amendment["historical_evaluation_return_access_permitted"] === false ||
        error("proposal computation amendment permits evaluation access")
    for path in (PUBLIC_STAGE_PATH, LOCAL_STAGE_PATH, PUBLIC_COMPUTATION_PATH, LOCAL_COMPUTATION_PATH)
        isfile(path) || error("proposal result manifest is absent before interface lock")
    end
    public_computation = TOML.parsefile(PUBLIC_COMPUTATION_PATH)
    local_computation = TOML.parsefile(LOCAL_COMPUTATION_PATH)
    public_computation["status"] == "PROPOSAL_POLICY_CHOICES_FROZEN" ||
        error("proposal computation choices are not frozen")
    public_computation["proposal_trial_ledger_rows"] == 18_430 ||
        error("proposal trial-ledger denominator changed")
    public_computation["evaluation_values_inspected"] == 0 ||
        error("evaluation values were inspected")
    public_computation["evaluation_values_materialized"] == 0 ||
        error("evaluation values were materialized")
    public_computation["evaluation_values_used"] == 0 || error("evaluation values were used")
    local_stage = TOML.parsefile(LOCAL_STAGE_PATH)
    artifacts = _local_artifacts(local_stage, local_computation)
    hashes = Dict(
        relative => _sha256_file(joinpath(REPOSITORY_ROOT, relative)) for
        relative in SEALED_PATHS
    )
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-policy-interface-lock-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PROPOSAL_POLICY_INTERFACE",
        "language" => "Julia",
        "final_proposal_computation_amendment_lock_sha256" =>
            _sha256_file(AMENDMENT_LOCK_PATH),
        "public_proposal_stage_manifest_sha256" => _sha256_file(PUBLIC_STAGE_PATH),
        "local_proposal_stage_manifest_sha256" => _sha256_file(LOCAL_STAGE_PATH),
        "public_proposal_computation_manifest_sha256" =>
            _sha256_file(PUBLIC_COMPUTATION_PATH),
        "local_proposal_computation_manifest_sha256" =>
            _sha256_file(LOCAL_COMPUTATION_PATH),
        "bound_local_artifact_count" => length(artifacts),
        "bound_local_artifact_aggregate_sha256" => _aggregate(artifacts),
        "sealed_file_count" => length(hashes),
        "sealed_file_sha256" => hashes,
        "sealed_file_aggregate_sha256" => _aggregate(hashes),
        "proposal_policy_choices_known_before_interface_lock" => true,
        "scientific_design_or_policy_choices_changed" => false,
        "public_selected_strategy_identities_permitted" => false,
        "local_selected_strategy_identities_required" => true,
        "proposal_values_accessed_before_lock" => true,
        "evaluation_values_accessed_before_lock" => false,
        "historical_evaluation_return_access_permitted" => false,
        "next_required_seal" => "PROPOSAL_POLICY_RESULT_SEAL",
    )
end

function lock_proposal_policy_interface(; check = false)
    if !check
        for path in OUTPUT_PATHS
            ispath(path) && error("proposal policy interface output exists before lock")
        end
    end
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("proposal policy interface lock is absent")
        read(LOCK_PATH, String) == text || error("proposal policy interface lock changed")
    elseif isfile(LOCK_PATH)
        read(LOCK_PATH, String) == text || error("refusing to replace nonidentical interface lock")
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PROPOSAL_POLICY_INTERFACE_LOCK_PASSED")
    println("bound proposal artifacts: 150")
    println("public selected strategy identities permitted: false")
    println("evaluation access permitted: false")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_proposal_policy_interface(; check = "--check" in args)
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3ProposalPolicyInterface.main()
end
