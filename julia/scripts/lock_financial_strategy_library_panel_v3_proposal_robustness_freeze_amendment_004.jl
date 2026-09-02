module LockFinancialStrategyLibraryPanelV3ProposalRobustnessFreezeAmendment004

using SHA: sha256
using TOML

export lock_proposal_robustness_freeze_amendment_004, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT, "experiments", "financial_strategy_library_panel_v3",
)
const CHAIN_LOCK_PATH = joinpath(
    EXPERIMENT_ROOT, "PROPOSAL_POSTCOMPLETION_BINDING_AMENDMENT_003_LOCK_002.toml",
)
const EXPECTED_CHAIN_LOCK_SHA256 =
    "27453e2ecb68c165d52301c386d3c95f5cf8cee5d73f9d55d010ece91e91ed98"
const PROPOSAL_RESULT_SEAL_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_RESULT_SEAL.toml")
const EXPECTED_PROPOSAL_RESULT_SEAL_SHA256 =
    "35ac8541432dfd102944024fde36b82324ea3bc943bc6556aef11ca1b2a251b4"
const PREDECISION_BINDING_PATH =
    joinpath(EXPERIMENT_ROOT, "PREDECISION_BINDING_AMENDMENT_003_LOCK.toml")
const EXPECTED_PREDECISION_BINDING_SHA256 =
    "16cbf54b20e0bb475665acdfd54c539d820f02f6015dc5e610d1b791424bc8e7"
const UNIVERSE_SELECTION_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "universe_census",
    "UNIVERSE_SELECTIONS.toml",
)
const LOCAL_PROPOSAL_POLICY_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal_policy",
    "PROPOSAL_POLICY_LOCAL_MANIFEST.toml",
)
const LOCAL_PROPOSAL_STAGE_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal",
    "PROPOSAL_STAGE_LOCAL_MANIFEST.toml",
)
const LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_ROBUSTNESS_FREEZE_AMENDMENT_004_LOCK.toml")
const SEALED_PATHS = [
    "experiments/financial_strategy_library_panel_v3/ANALYSIS_PLAN.md",
    "experiments/financial_strategy_library_panel_v3/CLAIM_BOUNDARY.md",
    "experiments/financial_strategy_library_panel_v3/registry/ARM_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v3/registry/SEED_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v3/amendments/PROPOSAL_ROBUSTNESS_FREEZE_AMENDMENT_004.md",
    "julia/src/FinancialStrategyLibraryPanelV3Proposal.jl",
    "julia/src/FinancialStrategyLibraryPanelV3ProposalRobustness.jl",
    "julia/scripts/run_financial_strategy_library_panel_v3_proposal.jl",
    "julia/scripts/run_financial_strategy_library_panel_v3_proposal_robustness.jl",
    "julia/scripts/seal_financial_strategy_library_panel_v3_proposal_robustness_result.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_proposal_robustness_freeze_amendment_004.jl",
    "julia/test/test_financial_strategy_library_panel_v3_proposal_robustness.jl",
    "julia/test/run_financial_strategy_library_panel_v3_proposal_robustness_tests.jl",
    "julia/test/test_financial_strategy_library_panel_v3_proposal_robustness_runner.jl",
    "julia/test/run_financial_strategy_library_panel_v3_proposal_robustness_runner_tests.jl",
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
    _sha256_file(CHAIN_LOCK_PATH) == EXPECTED_CHAIN_LOCK_SHA256 ||
        error("proposal postcompletion binding changed")
    chain = TOML.parsefile(CHAIN_LOCK_PATH)
    chain["status"] == "LOCKED_PROPOSAL_POSTCOMPLETION_BINDING_AMENDMENT_003_002" ||
        error("unexpected proposal postcompletion binding status")
    chain["historical_evaluation_return_access_permitted"] === false ||
        error("proposal postcompletion chain permits evaluation")
    _sha256_file(PROPOSAL_RESULT_SEAL_PATH) == EXPECTED_PROPOSAL_RESULT_SEAL_SHA256 ||
        error("proposal policy result seal changed")
    proposal_seal = TOML.parsefile(PROPOSAL_RESULT_SEAL_PATH)
    proposal_seal["status"] == "SEALED_PROPOSAL_POLICY_RESULT" ||
        error("primary proposal result is not sealed")
    proposal_seal["historical_evaluation_return_access_permitted"] === false ||
        error("primary proposal result permits evaluation")
    _sha256_file(PREDECISION_BINDING_PATH) == EXPECTED_PREDECISION_BINDING_SHA256 ||
        error("predecision loaded-source binding changed")
    predecision_binding = TOML.parsefile(PREDECISION_BINDING_PATH)
    predecision_binding["status"] == "LOCKED_PREDECISION_BINDING_AMENDMENT_003" ||
        error("predecision source closure is not locked")
    for (relative, digest) in Dict{String,String}(predecision_binding["sealed_file_sha256"])
        _sha256_file(joinpath(REPOSITORY_ROOT, relative)) == digest ||
            error("predecision loaded-source closure changed: $relative")
    end
    local_policy = TOML.parsefile(LOCAL_PROPOSAL_POLICY_PATH)
    local_stage = TOML.parsefile(LOCAL_PROPOSAL_STAGE_PATH)
    local_policy["status"] == "PROPOSAL_POLICY_INTERFACE_FROZEN" ||
        error("proposal policy interface is not frozen")
    local_stage["status"] == "PROPOSAL_RETURNS_STAGED" ||
        error("proposal returns are not staged")
    for manifest in (local_policy, local_stage)
        manifest["evaluation_values_inspected"] == 0 || error("evaluation was inspected")
        manifest["evaluation_values_materialized"] == 0 ||
            error("evaluation was materialized")
        manifest["evaluation_values_used"] == 0 || error("evaluation was used")
    end
    hashes = Dict(
        relative => _sha256_file(joinpath(REPOSITORY_ROOT, relative)) for
        relative in SEALED_PATHS
    )
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-robustness-freeze-amendment-lock-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PROPOSAL_ROBUSTNESS_FREEZE_AMENDMENT_004",
        "language" => "Julia",
        "proposal_postcompletion_binding_amendment_003_sha256" =>
            _sha256_file(CHAIN_LOCK_PATH),
        "proposal_policy_result_seal_sha256" => _sha256_file(PROPOSAL_RESULT_SEAL_PATH),
        "predecision_loaded_source_binding_sha256" => _sha256_file(PREDECISION_BINDING_PATH),
        "universe_selection_sha256" => _sha256_file(UNIVERSE_SELECTION_PATH),
        "local_proposal_policy_manifest_sha256" => _sha256_file(LOCAL_PROPOSAL_POLICY_PATH),
        "local_proposal_stage_manifest_sha256" => _sha256_file(LOCAL_PROPOSAL_STAGE_PATH),
        "costs_bps" => [0, 5, 15, 30],
        "risk_aversions" => [1, 3],
        "adoption_hurdles" => [0.0, 0.0025, 0.005],
        "grid_spec_count" => 24,
        "grid_policy_ids" => [
            "frontier_only_robust_policy", "innovation_safe_robust_policy",
        ],
        "bootstrap_repetitions" => 5_000,
        "moving_block_sessions" => 20,
        "familywise_alpha" => 0.10,
        "stable_seed_base" => 310002,
        "comparator_cash_max_t_required" => true,
        "safe_joint_all_comparator_max_t_required" => true,
        "primary_specification_must_reproduce_sealed_choices" => true,
        "common_equity_cap50_disposition" => "RECONSTRUCT_FROM_PREPROPOSAL_RANKS",
        "common_equity_cap100_disposition" => "PRIMARY_FROZEN_MEMBERSHIP",
        "common_equity_cap200_disposition" => "DESIGN_NOT_FROZEN_BEFORE_PROPOSAL",
        "permuted_closure_sham_disposition" => "DESIGN_NOT_FROZEN_BEFORE_PROPOSAL",
        "leave_one_origin_out_rule" => "AGGREGATION_ONLY_NO_RESELECTION",
        "capacity_status" => "DEFERRED_PRE_EVALUATION_FORMULA_GRID_LOCK_REQUIRED",
        "capacity_choice_rule" => "SCORE_FROZEN_CHOICES_ONLY_NO_RESELECTION",
        "proposal_choices_and_returns_known_before_lock" => true,
        "historical_proposal_return_reuse_permitted" => true,
        "evaluation_values_inspected_before_lock" => 0,
        "evaluation_values_materialized_before_lock" => 0,
        "evaluation_values_used_before_lock" => 0,
        "historical_evaluation_return_access_permitted" => false,
        "primary_policy_choices_changed" => false,
        "sealed_file_count" => length(hashes),
        "sealed_file_aggregate_sha256" => _aggregate(hashes),
        "sealed_file_sha256" => hashes,
        "next_required_seal" => "PROPOSAL_ROBUSTNESS_RESULT_SEAL",
    )
end

function lock_proposal_robustness_freeze_amendment_004(; check = false)
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("proposal robustness freeze lock is absent")
        read(LOCK_PATH, String) == text || error("proposal robustness freeze lock changed")
    elseif isfile(LOCK_PATH)
        read(LOCK_PATH, String) == text ||
            error("refusing to replace nonidentical proposal robustness freeze lock")
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PROPOSAL_ROBUSTNESS_FREEZE_AMENDMENT_004_PASSED")
    println("registered grid specs: 24; primary policies: 2")
    println("proposal known: true; evaluation access permitted: false")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_proposal_robustness_freeze_amendment_004(; check = "--check" in args)
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3ProposalRobustnessFreezeAmendment004.main()
end
