module LockFinancialStrategyLibraryPanelV3ProposalRobustnessComputationAmendment005

using SHA: sha256
using TOML

export lock_proposal_robustness_computation_amendment_005, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT, "experiments", "financial_strategy_library_panel_v3",
)
const PREVIOUS_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_ROBUSTNESS_FREEZE_AMENDMENT_004_LOCK.toml")
const EXPECTED_PREVIOUS_LOCK_SHA256 =
    "08fde971f32180578a29d6f934e19aa415a743a34fa944d1394b6ea367ce383d"
const LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_ROBUSTNESS_COMPUTATION_AMENDMENT_005_LOCK.toml")
const PARTIAL_PATHS = [
    "local_data/proposal_robustness/cell-006.toml",
    "local_data/proposal_robustness/cell-016.toml",
    "local_data/proposal_robustness/cell-026.toml",
]
const SEALED_PATHS = [
    "experiments/financial_strategy_library_panel_v3/amendments/PROPOSAL_ROBUSTNESS_COMPUTATION_AMENDMENT_005.md",
    "julia/scripts/run_financial_strategy_library_panel_v3_proposal_robustness.jl",
    "julia/scripts/seal_financial_strategy_library_panel_v3_proposal_robustness_result.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_proposal_robustness_computation_amendment_005.jl",
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

function _payload()
    _sha256_file(PREVIOUS_LOCK_PATH) == EXPECTED_PREVIOUS_LOCK_SHA256 ||
        error("proposal robustness freeze lock changed")
    previous = TOML.parsefile(PREVIOUS_LOCK_PATH)
    previous["status"] == "LOCKED_PROPOSAL_ROBUSTNESS_FREEZE_AMENDMENT_004" ||
        error("unexpected proposal robustness freeze status")
    previous["historical_evaluation_return_access_permitted"] === false ||
        error("proposal robustness freeze lock permits evaluation")
    partial = Dict(
        relative => _sha256_file(joinpath(EXPERIMENT_ROOT, relative)) for
        relative in PARTIAL_PATHS
    )
    length(partial) == 3 || error("partial robustness artifact count changed")
    sealed = Dict(
        relative => _sha256_file(joinpath(REPOSITORY_ROOT, relative)) for
        relative in SEALED_PATHS
    )
    original_hashes = Dict{String,String}(previous["sealed_file_sha256"])
    amended = Set([
        "julia/scripts/run_financial_strategy_library_panel_v3_proposal_robustness.jl",
        "julia/scripts/seal_financial_strategy_library_panel_v3_proposal_robustness_result.jl",
    ])
    for (relative, digest) in original_hashes
        relative in amended && continue
        _sha256_file(joinpath(REPOSITORY_ROOT, relative)) == digest ||
            error("unamended robustness source changed: $relative")
    end
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-robustness-computation-amendment-lock-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PROPOSAL_ROBUSTNESS_COMPUTATION_AMENDMENT_005",
        "language" => "Julia",
        "previous_proposal_robustness_freeze_lock_sha256" =>
            _sha256_file(PREVIOUS_LOCK_PATH),
        "change_scope" => "cap-disposition initializer control flow only",
        "partial_artifact_count" => length(partial),
        "partial_artifact_aggregate_sha256" => _aggregate(partial),
        "partial_artifact_sha256" => partial,
        "public_result_manifests_before_amendment" => 0,
        "local_result_manifests_before_amendment" => 0,
        "result_seals_before_amendment" => 0,
        "proposal_values_accessed_before_amendment" => true,
        "evaluation_values_inspected_before_amendment" => 0,
        "evaluation_values_materialized_before_amendment" => 0,
        "evaluation_values_used_before_amendment" => 0,
        "historical_proposal_return_reuse_permitted" => true,
        "historical_evaluation_return_access_permitted" => false,
        "scientific_grid_policies_choices_or_dispositions_changed" => false,
        "sealed_file_count" => length(sealed),
        "sealed_file_sha256" => sealed,
        "next_required_seal" => "PROPOSAL_ROBUSTNESS_RESULT_SEAL",
    )
end

function lock_proposal_robustness_computation_amendment_005(; check = false)
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("robustness computation amendment is absent")
        read(LOCK_PATH, String) == text || error("robustness computation amendment changed")
    elseif isfile(LOCK_PATH)
        read(LOCK_PATH, String) == text ||
            error("refusing to replace nonidentical robustness computation amendment")
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PROPOSAL_ROBUSTNESS_COMPUTATION_AMENDMENT_005_PASSED")
    println("partial ETF artifacts bound: 3; scientific design changed: false")
    println("evaluation values inspected/materialized/used: 0")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_proposal_robustness_computation_amendment_005(; check = "--check" in args)
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3ProposalRobustnessComputationAmendment005.main()
end
