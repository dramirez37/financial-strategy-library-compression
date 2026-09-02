module LockFinancialStrategyLibraryPanelV3EvaluationExecution

using SHA: sha256
using TOML

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EVALUATION_EXECUTION_LOCK.toml")
const PROPOSAL_RESULT_SEAL_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_RESULT_SEAL.toml")
const PROPOSAL_STAGE_REPLAY_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_STAGE_REPLAY_AMENDMENT_002_LOCK.toml")
const PREDECISION_BINDING_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PREDECISION_BINDING_AMENDMENT_003_LOCK.toml")
const PROPOSAL_ROBUSTNESS_RESULT_SEAL_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_ROBUSTNESS_RESULT_SEAL.toml")
const PROPOSAL_ROBUSTNESS_PUBLIC_PATH = joinpath(
    EXPERIMENT_ROOT, "proposal_robustness", "PROPOSAL_ROBUSTNESS_MANIFEST.toml",
)
const PROPOSAL_ROBUSTNESS_LOCAL_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal_robustness",
    "PROPOSAL_ROBUSTNESS_LOCAL_MANIFEST.toml",
)
const PROPOSAL_PUBLIC_PATH = joinpath(
    EXPERIMENT_ROOT,
    "proposal_policy",
    "PROPOSAL_POLICY_MANIFEST.toml",
)
const PROPOSAL_LOCAL_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal_policy",
    "PROPOSAL_POLICY_LOCAL_MANIFEST.toml",
)
const MASTER_MANIFEST_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v2",
    "local_data",
    "master_market_panel",
    "MASTER_MANIFEST.toml",
)
const SELECTION_PATH = joinpath(
    EXPERIMENT_ROOT, "local_data", "universe_census", "UNIVERSE_SELECTIONS.toml",
)

const IMPLEMENTATION_PATHS = [
    "experiments/configs/financial_strategy_library_panel_v3.toml",
    "experiments/financial_strategy_library_panel_v3/ANALYSIS_PLAN.md",
    "experiments/financial_strategy_library_panel_v3/DATA_CONTRACT.md",
    "experiments/financial_strategy_library_panel_v3/EVALUATION_IMPLEMENTATION_SPEC.md",
    "experiments/financial_strategy_library_panel_v3/registry/ORIGIN_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v3/registry/SEED_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v3/registry/TRIAL_LEDGER_SCHEMA.csv",
    "julia/Project.toml",
    "julia/Manifest.toml",
    "julia/src/FinancialStrategyLibraryPanelV3.jl",
    "julia/src/FinancialStrategyLibraryPanelV3Predecision.jl",
    "julia/src/FinancialStrategyLibraryPanelV3PredecisionComputation.jl",
    "julia/src/FinancialStrategyLibraryPanelV3Evaluation.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_evaluation_execution.jl",
    "julia/scripts/stage_financial_strategy_library_panel_v3_predecision_returns.jl",
    "julia/scripts/stage_financial_strategy_library_panel_v3_evaluation_returns.jl",
    "julia/scripts/run_financial_strategy_library_panel_v3_evaluation.jl",
    "julia/scripts/seal_financial_strategy_library_panel_v3_evaluation_result.jl",
    "julia/test/test_financial_strategy_library_panel_v3_evaluation.jl",
    "julia/test/test_financial_strategy_library_panel_v3_evaluation_staging.jl",
    "julia/test/test_financial_strategy_library_panel_v3_evaluation_runner.jl",
    "julia/test/run_financial_strategy_library_panel_v3_evaluation_tests.jl",
    "julia/test/run_financial_strategy_library_panel_v3_evaluation_staging_tests.jl",
    "julia/test/run_financial_strategy_library_panel_v3_evaluation_runner_tests.jl",
]

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _proposal_seal_contract()
    for path in (
        PROPOSAL_RESULT_SEAL_PATH,
        PROPOSAL_STAGE_REPLAY_LOCK_PATH,
        PREDECISION_BINDING_LOCK_PATH,
        PROPOSAL_ROBUSTNESS_RESULT_SEAL_PATH,
        PROPOSAL_ROBUSTNESS_PUBLIC_PATH,
        PROPOSAL_ROBUSTNESS_LOCAL_PATH,
        PROPOSAL_PUBLIC_PATH,
        PROPOSAL_LOCAL_PATH,
        MASTER_MANIFEST_PATH,
        SELECTION_PATH,
    )
        isfile(path) || error(
            "proposal-policy result is not yet seal-complete; evaluation remains locked: " *
            relpath(path, REPOSITORY_ROOT),
        )
    end
    seal = TOML.parsefile(PROPOSAL_RESULT_SEAL_PATH)
    seal["status"] == "SEALED_PROPOSAL_POLICY_RESULT" ||
        error("proposal-policy result seal has an unexpected status")
    seal["historical_evaluation_return_access_permitted"] === false ||
        error("proposal-policy result seal crossed the evaluation boundary")
    seal["evaluation_values_inspected_before_seal"] == 0 ||
        error("proposal-policy result reports prior evaluation inspection")
    seal["evaluation_values_materialized_before_seal"] == 0 ||
        error("proposal-policy result reports prior evaluation materialization")
    seal["evaluation_values_used_before_seal"] == 0 ||
        error("proposal-policy result reports prior evaluation use")
    seal["proposal_policy_manifest_sha256"] == _sha256_file(PROPOSAL_PUBLIC_PATH) ||
        error("proposal-policy result seal/public manifest binding changed")
    seal["proposal_policy_local_manifest_sha256"] == _sha256_file(PROPOSAL_LOCAL_PATH) ||
        error("proposal-policy result seal/local manifest binding changed")
    replay = TOML.parsefile(PROPOSAL_STAGE_REPLAY_LOCK_PATH)
    replay["status"] == "LOCKED_PROPOSAL_STAGE_REPLAY_AMENDMENT_002" ||
        error("proposal-stage replay amendment is not locked")
    replay["historical_evaluation_return_access_permitted"] === false ||
        error("proposal-stage replay amendment crossed the evaluation boundary")
    replay["evaluation_values_accessed_before_amendment"] === false ||
        error("proposal-stage replay amendment reports prior evaluation access")
    replay["scientific_design_paths_choices_or_results_changed"] === false ||
        error("proposal-stage replay amendment changed the scientific result")
    for (relative, digest) in Dict{String,String}(replay["sealed_file_sha256"])
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("proposal-stage replay sealed file is absent: $relative")
        _sha256_file(path) == digest ||
            error("proposal-stage replay sealed file changed: $relative")
    end
    binding = TOML.parsefile(PREDECISION_BINDING_LOCK_PATH)
    binding["status"] == "LOCKED_PREDECISION_BINDING_AMENDMENT_003" ||
        error("predecision runtime-source binding amendment is not locked")
    binding["historical_proposal_or_evaluation_return_access_permitted"] === false ||
        error("predecision runtime-source binding crossed the evaluation boundary")
    binding["evaluation_return_values_accessed_before_lock"] === false ||
        error("predecision runtime-source binding reports prior evaluation access")
    binding["sealed_file_count"] == 42 ||
        error("predecision runtime-source closure denominator changed")
    binding["strategy_innovation_include_count"] == 29 ||
        error("StrategyInnovation runtime include denominator changed")
    binding_hashes = Dict{String,String}(binding["sealed_file_sha256"])
    length(binding_hashes) == binding["sealed_file_count"] ||
        error("predecision runtime-source closure is incomplete")
    get(binding_hashes, "julia/src/StrategyInnovation.jl", "") != "" ||
        error("predecision runtime-source closure omits StrategyInnovation.jl")
    for (relative, digest) in binding_hashes
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("predecision runtime-source file is absent: $relative")
        _sha256_file(path) == digest ||
            error("predecision runtime-source file changed: $relative")
    end
    robustness = TOML.parsefile(PROPOSAL_ROBUSTNESS_RESULT_SEAL_PATH)
    robustness["status"] == "SEALED_PROPOSAL_ROBUSTNESS_RESULT" ||
        error("proposal robustness result is not sealed")
    robustness["proposal_policy_result_seal_sha256"] ==
        _sha256_file(PROPOSAL_RESULT_SEAL_PATH) ||
        error("proposal robustness result does not bind the primary result")
    robustness["historical_evaluation_return_access_permitted"] === false ||
        error("proposal robustness result crossed the evaluation boundary")
    robustness["evaluation_values_inspected_before_seal"] == 0 ||
        error("proposal robustness reports prior evaluation inspection")
    robustness["evaluation_values_materialized_before_seal"] == 0 ||
        error("proposal robustness reports prior evaluation materialization")
    robustness["evaluation_values_used_before_seal"] == 0 ||
        error("proposal robustness reports prior evaluation use")
    robustness["capacity_status"] ==
        "DEFERRED_PRE_EVALUATION_FORMULA_GRID_LOCK_REQUIRED" ||
        error("proposal robustness capacity handoff changed")
    robustness["capacity_choice_rule"] ==
        "SCORE_FROZEN_CHOICES_ONLY_NO_RESELECTION" ||
        error("proposal robustness capacity choice rule changed")
    robustness["public_proposal_robustness_manifest_sha256"] ==
        _sha256_file(PROPOSAL_ROBUSTNESS_PUBLIC_PATH) ||
        error("proposal robustness public manifest binding changed")
    robustness["local_proposal_robustness_manifest_sha256"] ==
        _sha256_file(PROPOSAL_ROBUSTNESS_LOCAL_PATH) ||
        error("proposal robustness local manifest binding changed")
    local_robustness = TOML.parsefile(PROPOSAL_ROBUSTNESS_LOCAL_PATH)
    local_robustness["public_manifest_sha256"] ==
        _sha256_file(PROPOSAL_ROBUSTNESS_PUBLIC_PATH) ||
        error("proposal robustness public/local manifests are not bound")
    robustness["bound_local_artifact_count"] == 38 &&
        robustness["all_bound_local_artifact_hashes_verified"] === true ||
        error("proposal robustness result does not certify all local artifacts")
    robustness["bound_local_artifact_aggregate_sha256"] ==
        String(local_robustness["local_artifact_aggregate_sha256"]) ||
        error("proposal robustness artifact aggregate binding changed")
    robustness_artifacts = Dict{String,String}(local_robustness["local_artifact_sha256"])
    length(robustness_artifacts) == 38 ||
        error("proposal robustness artifact denominator changed")
    for (relative, digest) in robustness_artifacts
        path = joinpath(EXPERIMENT_ROOT, relative)
        isfile(path) || error("proposal robustness artifact is absent: $relative")
        _sha256_file(path) == digest || error("proposal robustness artifact changed: $relative")
    end
    return (; seal, replay, binding, binding_hashes, robustness, robustness_artifacts)
end

function _payload()
    proposal_contract = _proposal_seal_contract()
    sealed = Dict{String,String}()
    for relative in IMPLEMENTATION_PATHS
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("evaluation implementation input is absent: $relative")
        sealed[relative] = _sha256_file(path)
    end
    for path in (
        PROPOSAL_RESULT_SEAL_PATH,
        PROPOSAL_STAGE_REPLAY_LOCK_PATH,
        PREDECISION_BINDING_LOCK_PATH,
        PROPOSAL_ROBUSTNESS_RESULT_SEAL_PATH,
        PROPOSAL_ROBUSTNESS_PUBLIC_PATH,
        PROPOSAL_ROBUSTNESS_LOCAL_PATH,
        PROPOSAL_PUBLIC_PATH,
        PROPOSAL_LOCAL_PATH,
        MASTER_MANIFEST_PATH,
        SELECTION_PATH,
    )
        relative = relpath(path, REPOSITORY_ROOT)
        sealed[relative] = _sha256_file(path)
    end
    for (relative, digest) in proposal_contract.robustness_artifacts
        sealed[joinpath("experiments", "financial_strategy_library_panel_v3", relative)] = digest
    end
    for (relative, digest) in Dict{String,String}(
        proposal_contract.replay["sealed_file_sha256"],
    )
        haskey(sealed, relative) && sealed[relative] != digest &&
            error("proposal replay/runtime implementation hash conflict: $relative")
        sealed[relative] = digest
    end
    for (relative, digest) in proposal_contract.binding_hashes
        haskey(sealed, relative) && sealed[relative] != digest &&
            error("predecision runtime/evaluation implementation hash conflict: $relative")
        sealed[relative] = digest
    end
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-evaluation-execution-lock-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_EVALUATION_EXECUTION",
        "language" => "Julia",
        "julia_version" => "1.12.6",
        "evaluation_scope" => "all five frozen registered policies; primary headline fixed",
        "primary_cost_bps" => 5,
        "primary_risk_aversion" => 3,
        "portfolio_state_start" => "full predecision plus proposal history",
        "historical_evaluation_return_access_permitted" => true,
        "failed_universe_cell_evaluation_access_permitted" => false,
        "cash_only_gate_passed_cell_security_return_access_permitted" => true,
        "cash_only_access_purpose" => "registered all-96 search-wide diagnostics only",
        "frozen_candidate_diagnostic_evaluation_access_permitted" => true,
        "frozen_candidate_count_per_gate_passed_cell" => 96,
        "candidate_diagnostic_access_purpose" =>
            "White Reality Check, Hansen SPA, PBO/CSCV, Deflated Sharpe, and ex-post regret only",
        "policy_reselection_or_repair_permitted" => false,
        "full_search_bootstrap_repetitions" => 5000,
        "full_search_moving_block_sessions" => 20,
        "full_search_cscv_blocks" => 8,
        "full_search_cscv_split_count" => 70,
        "reality_check_seed_base" => 310003,
        "reality_check_seed_scope" => "origin_id|universe_id",
        "hansen_spa_seed_base" => 310004,
        "hansen_spa_seed_scope" => "origin_id|universe_id",
        "pbo_cscv_seed_base" => 310005,
        "pbo_cscv_seed_scope" => "origin_id|universe_id",
        "permuted_closure_sham_seed_base_reserved_not_used" => 310006,
        "capacity_seed_base" => 310007,
        "capacity_seed_scope" => "origin_id|universe_id|aum_id",
        "hansen_spa_long_run_variance" => "Bartlett-Newey-West bandwidth 19",
        "hansen_spa_recenter_threshold" =>
            "sqrt(n)*mean/omega < -sqrt(2*log(log(n)))",
        "hansen_spa_zero_benchmark_included" => true,
        "deflated_sharpe_secondary_diagnostic" => true,
        "capacity_choice_rule" => "SCORE_FROZEN_CHOICES_ONLY_NO_RESELECTION",
        "capacity_source_fields" => ["close", "volume"],
        "capacity_source_window" => "proposal plus evaluation years; 20 sessions strictly lagged",
        "capacity_aum" => [1_000_000, 10_000_000, 100_000_000, 1_000_000_000],
        "capacity_half_spread_bps" => [2.5, 7.5, 15.0],
        "capacity_impact_coefficients" => [0.5, 1.0],
        "capacity_impact_model" =>
            "coefficient * lagged_daily_volatility * sqrt(order_dollars / lagged_ADV)",
        "capacity_adv_fraction_cap" => 0.10,
        "capacity_adv_cap_behavior" => "UNAVAILABLE_NO_TRUNCATION",
        "capacity_source_limitation_behavior" =>
            "CAPACITY_SOURCE_FIELDS_UNAVAILABLE_NO_OMISSION",
        "evaluation_values_accessed_before_lock" => false,
        "proposal_policy_result_seal_sha256" => _sha256_file(PROPOSAL_RESULT_SEAL_PATH),
        "proposal_stage_replay_amendment_lock_sha256" =>
            _sha256_file(PROPOSAL_STAGE_REPLAY_LOCK_PATH),
        "predecision_binding_amendment_003_lock_sha256" =>
            _sha256_file(PREDECISION_BINDING_LOCK_PATH),
        "predecision_runtime_source_closure_file_count" => 42,
        "strategy_innovation_runtime_include_count" => 29,
        "proposal_robustness_result_seal_sha256" =>
            _sha256_file(PROPOSAL_ROBUSTNESS_RESULT_SEAL_PATH),
        "proposal_robustness_manifest_sha256" =>
            _sha256_file(PROPOSAL_ROBUSTNESS_PUBLIC_PATH),
        "proposal_robustness_local_manifest_sha256" =>
            _sha256_file(PROPOSAL_ROBUSTNESS_LOCAL_PATH),
        "proposal_policy_manifest_sha256" => _sha256_file(PROPOSAL_PUBLIC_PATH),
        "proposal_policy_local_manifest_sha256" => _sha256_file(PROPOSAL_LOCAL_PATH),
        "master_market_panel_manifest_sha256" => _sha256_file(MASTER_MANIFEST_PATH),
        "universe_selections_sha256" => _sha256_file(SELECTION_PATH),
        "seed_registry_sha256" => _sha256_file(joinpath(
            EXPERIMENT_ROOT, "registry", "SEED_REGISTRY.csv",
        )),
        "robustness_grid_cell_spec_denominator" => 912,
        "robustness_grid_policy_choice_denominator" => 1824,
        "robustness_grid_available_cell_spec_count" => 888,
        "robustness_grid_available_policy_choice_count" => 1776,
        "registered_primary_policy_row_denominator" => 190,
        "leave_one_origin_out_omission_count" => 19,
        "leave_one_origin_out_rule" => "AGGREGATION_ONLY_NO_RESELECTION",
        "robustness_common_equity_cap50_membership_source" => "PREPROPOSAL_RANKED_TOP50",
        "sealed_file_sha256" => sealed,
    )
end

function main(args = ARGS)
    length(args) <= 1 || error("use no argument to lock or --check to verify")
    check = "--check" in args
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("evaluation execution lock is absent")
        read(LOCK_PATH, String) == text || error("evaluation execution lock changed")
        println("V3_EVALUATION_EXECUTION_LOCK_CHECK_PASSED")
    else
        isfile(LOCK_PATH) && read(LOCK_PATH, String) != text &&
            error("refusing to replace a nonidentical evaluation execution lock")
        if !isfile(LOCK_PATH)
            open(LOCK_PATH, "w") do io
                write(io, text)
            end
        end
        println("V3_EVALUATION_EXECUTION_LOCKED")
    end
    println("proposal-policy result seal: $(_sha256_file(PROPOSAL_RESULT_SEAL_PATH))")
    println("historical evaluation return access permitted: true")
    return payload
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3EvaluationExecution.main()
end
