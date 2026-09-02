using SHA: sha256
using Statistics: mean
using Test

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV3Evaluation.jl"))
using .FinancialStrategyLibraryPanelV3Evaluation

const TEST_ORIGIN = "TEST-O2000"
const TEST_UNIVERSE = "liquid_common_equity"
const ACTIVE_ID = join((
    TEST_ORIGIN,
    TEST_UNIVERSE,
    "momentum_20",
    "always",
    "20",
    "equal_weight",
    "0_5",
    "horizon",
), '|')
const ACTIVE_ID_2 = join((
    TEST_ORIGIN,
    TEST_UNIVERSE,
    "momentum_20",
    "always",
    "20",
    "equal_weight",
    "1_0",
    "horizon",
), '|')

function _choices(; safe = ACTIVE_ID, comparator = "mandatory_inactive_cash")
    return [
        FrozenEvaluationChoice(
            TEST_ORIGIN,
            TEST_UNIVERSE,
            "innovation_safe_robust_policy",
            safe,
        ),
        FrozenEvaluationChoice(
            TEST_ORIGIN,
            TEST_UNIVERSE,
            "frontier_only_robust_policy",
            comparator,
        ),
        FrozenEvaluationChoice(
            TEST_ORIGIN,
            TEST_UNIVERSE,
            "innovation_safe_forced_max",
            ACTIVE_ID,
        ),
        FrozenEvaluationChoice(
            TEST_ORIGIN,
            TEST_UNIVERSE,
            "equal_weight_available_policy",
            [ACTIVE_ID, ACTIVE_ID_2],
        ),
        FrozenEvaluationChoice(
            TEST_ORIGIN,
            TEST_UNIVERSE,
            "source_uncompressed_robust_policy",
            "mandatory_inactive_cash",
        ),
    ]
end

function _cash_choices()
    return [
        FrozenEvaluationChoice(TEST_ORIGIN, TEST_UNIVERSE, policy_id, "mandatory_inactive_cash")
        for policy_id in (
            "frontier_only_robust_policy",
            "innovation_safe_robust_policy",
            "innovation_safe_forced_max",
            "equal_weight_available_policy",
            "source_uncompressed_robust_policy",
        )
    ]
end

function _history(; evaluation_sessions = 20)
    pre_sessions = 140
    dates = [
        ["2000-$(lpad(div(index - 1, 28) + 1, 2, '0'))-$(lpad(mod(index - 1, 28) + 1, 2, '0'))" for index in 1:pre_sessions];
        ["2001-01-$(lpad(index, 2, '0'))" for index in 1:evaluation_sessions]
    ]
    returns = fill(0.001, length(dates), 1)
    return (; dates, returns, available = trues(size(returns)), terminal = falses(size(returns)))
end

@testset "v3 evaluation scores only frozen paths with carried state" begin
    history = _history()
    result = evaluate_frozen_choices(
        TEST_ORIGIN,
        TEST_UNIVERSE,
        history.returns,
        history.available,
        history.terminal,
        history.dates,
        2001,
        _choices();
        security_weight_cap = 0.10,
    )
    @test length(result.outcomes) == 6
    lookup = Dict(outcome.policy_id => outcome for outcome in result.outcomes)
    @test lookup["innovation_safe_robust_policy"].complete
    @test lookup["innovation_safe_robust_policy"].observation_count == 20
    @test lookup["innovation_safe_robust_policy"].annual_mean_component > 0
    @test lookup["frontier_only_robust_policy"].certainty_equivalent == 0
    @test length(result.policy_outcomes) == 5
    @test length(result.outcomes) == 6
    equal_weight = only(filter(
        outcome -> outcome.policy_id == "equal_weight_available_policy",
        result.policy_outcomes,
    ))
    @test equal_weight.complete
    @test length(equal_weight.choice_ids) == 2
    contrast = origin_evaluation_contrast(result.policy_outcomes)
    @test contrast.complete
    @test contrast.certainty_equivalent_difference > 0
    @test contrast.certainty_equivalent_difference ≈
        contrast.mean_component_difference - contrast.variance_penalty_difference -
        contrast.turnover_cost_difference

    isolated = _history(evaluation_sessions = 20)
    isolated_result = evaluate_frozen_choices(
        TEST_ORIGIN,
        TEST_UNIVERSE,
        isolated.returns[(end - 19):end, :],
        isolated.available[(end - 19):end, :],
        isolated.terminal[(end - 19):end, :],
        isolated.dates[(end - 19):end],
        2001,
        _choices();
        security_weight_cap = 0.10,
    )
    isolated_lookup = Dict(outcome.policy_id => outcome for outcome in isolated_result.outcomes)
    @test isolated_lookup["innovation_safe_robust_policy"].annual_mean_component == 0

    same = evaluate_frozen_choices(
        TEST_ORIGIN,
        TEST_UNIVERSE,
        history.returns,
        history.available,
        history.terminal,
        history.dates,
        2001,
        _choices(comparator = ACTIVE_ID);
        security_weight_cap = 0.10,
    )
    same_contrast = origin_evaluation_contrast(same.policy_outcomes)
    @test same_contrast.same_choice
    @test same_contrast.certainty_equivalent_difference === 0.0
end

@testset "v3 evaluation preserves observed delisting then cash" begin
    history = _history()
    terminal_row = length(history.dates) - 10
    history.returns[terminal_row, 1] = -1.0
    history.terminal[terminal_row, 1] = true
    history.available[(terminal_row + 1):end, 1] .= false
    result = evaluate_frozen_choices(
        TEST_ORIGIN,
        TEST_UNIVERSE,
        history.returns,
        history.available,
        history.terminal,
        history.dates,
        2001,
        _choices();
        security_weight_cap = 0.10,
    )
    safe = only(filter(outcome -> outcome.policy_id == "innovation_safe_robust_policy", result.outcomes))
    @test safe.complete
    @test safe.observation_count == 20
    @test safe.annual_mean_component < 0

    unresolved = _history()
    unresolved_row = length(unresolved.dates) - 10
    unresolved.available[unresolved_row, 1] = false
    unresolved.terminal[unresolved_row, 1] = true
    result = evaluate_frozen_choices(
        TEST_ORIGIN,
        TEST_UNIVERSE,
        unresolved.returns,
        unresolved.available,
        unresolved.terminal,
        unresolved.dates,
        2001,
        _choices();
        security_weight_cap = 0.10,
    )
    safe = only(filter(outcome -> outcome.policy_id == "innovation_safe_robust_policy", result.outcomes))
    @test !safe.complete
    @test safe.failure_code == "INCOMPLETE_EVALUATION_PATH"
    @test ismissing(safe.certainty_equivalent)
end

@testset "v3 full engine scores all 96 candidates without policy feedback" begin
    history = _history(evaluation_sessions = 20)
    function run_full_search()
        return evaluate_frozen_choices(
            TEST_ORIGIN,
            TEST_UNIVERSE,
            history.returns,
            history.available,
            history.terminal,
            history.dates,
            2001,
            _cash_choices();
            security_weight_cap = 0.10,
            compute_full_search = true,
            full_search_bootstrap_repetitions = 100,
            full_search_moving_block_sessions = 5,
            full_search_cscv_blocks = 8,
        )
    end
    first_result = run_full_search()
    second_result = run_full_search()
    first_diagnostic = first_result.full_search_diagnostics
    second_diagnostic = second_result.full_search_diagnostics
    @test length(first_diagnostic.candidate_ids) == 96
    @test length(unique(first_diagnostic.candidate_ids)) == 96
    @test length(first_diagnostic.candidate_outcomes) == 96
    @test all(outcome -> outcome.certainty_equivalent == 0.0, first_result.policy_outcomes)
    @test getfield.(first_result.policy_outcomes, :choice_ids) ==
        getfield.(second_result.policy_outcomes, :choice_ids)
    @test first_diagnostic.white_reality_check_p_value ==
        second_diagnostic.white_reality_check_p_value
    @test first_diagnostic.hansen_spa_p_value == second_diagnostic.hansen_spa_p_value
    @test first_diagnostic.pbo_cscv == second_diagnostic.pbo_cscv
    @test isequal(
        first_diagnostic.deflated_sharpe_probability,
        second_diagnostic.deflated_sharpe_probability,
    )
end

@testset "v3 capacity grid is lagged, frozen, and hard-capped" begin
    pre_sessions = 30
    evaluation_sessions = 20
    dates = [
        ["2000-01-$(lpad(index, 2, '0'))" for index in 1:pre_sessions];
        ["2001-01-$(lpad(index, 2, '0'))" for index in 1:evaluation_sessions]
    ]
    security_returns = reshape([
        isodd(index) ? 0.001 : -0.001 for index in eachindex(dates)
    ], :, 1)
    return_available = trues(size(security_returns))
    close = fill(100.0, size(security_returns))
    volume = fill(10_000_000.0, size(security_returns))
    active_weights = zeros(Float64, size(security_returns))
    active_weights[(pre_sessions + 1):end, 1] .= 0.01
    cash_weights = zeros(Float64, size(security_returns))
    weights = Dict(
        "innovation_safe_robust_policy" => active_weights,
        "frontier_only_robust_policy" => cash_weights,
    )
    capacity = capacity_policy_grid(
        TEST_ORIGIN,
        TEST_UNIVERSE,
        weights,
        security_returns,
        return_available,
        close,
        volume,
        dates,
        2001,
    )
    @test length(capacity) == 2 * 4 * 3 * 2
    @test all(outcome -> outcome.complete, capacity)
    @test all(outcome -> outcome.observation_count == evaluation_sessions, capacity)
    @test all(outcome -> outcome.maximum_adv_fraction == 0.0,
        filter(outcome -> outcome.policy_id == "frontier_only_robust_policy", capacity))
    example = only(filter(outcome ->
        outcome.policy_id == "innovation_safe_robust_policy" &&
        outcome.aum == 1_000_000.0 && outcome.half_spread_bps == 2.5 &&
        outcome.impact_coefficient == 0.5,
        capacity,
    ))
    @test example.certainty_equivalent ≈
        example.annual_mean_component - example.annual_execution_cost -
        example.annual_variance_penalty

    low_volume = fill(100_000.0, size(security_returns))
    constrained = capacity_policy_grid(
        TEST_ORIGIN,
        TEST_UNIVERSE,
        weights,
        security_returns,
        return_available,
        close,
        low_volume,
        dates,
        2001;
        aum_levels = (1_000_000.0, 1_000_000_000.0),
        half_spread_bps_levels = (2.5,),
        impact_coefficients = (0.5,),
    )
    safe_small = only(filter(outcome ->
        outcome.policy_id == "innovation_safe_robust_policy" &&
        outcome.aum == 1_000_000.0,
        constrained,
    ))
    safe_large = only(filter(outcome ->
        outcome.policy_id == "innovation_safe_robust_policy" &&
        outcome.aum == 1_000_000_000.0,
        constrained,
    ))
    @test safe_small.complete
    @test !safe_large.complete
    @test safe_large.failure_code == "CAPACITY_ADV_CAP_BREACH"
    @test all(outcome -> outcome.complete,
        filter(outcome -> outcome.policy_id == "frontier_only_robust_policy", constrained))

    missing_close = Matrix{Union{Missing,Float64}}(close)
    missing_close[20, 1] = missing
    unavailable = capacity_policy_grid(
        TEST_ORIGIN,
        TEST_UNIVERSE,
        weights,
        security_returns,
        return_available,
        missing_close,
        volume,
        dates,
        2001;
        aum_levels = (1_000_000.0,),
        half_spread_bps_levels = (2.5,),
        impact_coefficients = (0.5,),
    )
    active_unavailable = only(filter(outcome ->
        outcome.policy_id == "innovation_safe_robust_policy",
        unavailable,
    ))
    @test !active_unavailable.complete
    @test active_unavailable.failure_code == "CAPACITY_SOURCE_FIELDS_UNAVAILABLE"
    @test only(filter(outcome ->
        outcome.policy_id == "frontier_only_robust_policy",
        unavailable,
    )).complete
    capacity_summary = summarize_capacity_outcomes(
        capacity;
        universe_id = TEST_UNIVERSE,
        policy_id = "innovation_safe_robust_policy",
        aum = 1_000_000.0,
        half_spread_bps = 2.5,
        impact_coefficient = 0.5,
    )
    @test capacity_summary["available_origin_count"] == 1
    @test capacity_summary["complete_origin_count"] == 1
    @test capacity_summary["arithmetic_mean_ce"] == example.certainty_equivalent
    seed_by_aum = Dict(
        aum => only(unique(outcome.seed for outcome in capacity if outcome.aum == aum))
        for aum in (1_000_000.0, 10_000_000.0, 100_000_000.0, 1_000_000_000.0)
    )
    @test length(unique(values(seed_by_aum))) == 4
    expected_capacity_seed = parse(Int, first(bytes2hex(sha256(codeunits(join(
        (310007, TEST_ORIGIN, TEST_UNIVERSE, "aum_1000000"), '\0',
    )))), 15); base = 16)
    @test seed_by_aum[1_000_000.0] == expected_capacity_seed
end

@testset "v3 frozen robustness grid scores variants without reselection" begin
    history = _history(evaluation_sessions = 20)
    specs = FrozenRobustnessSpec[]
    for cost in (0.0, 5.0, 15.0, 30.0), risk in (1.0, 3.0),
        (hurdle_id, hurdle) in (("00", 0.0), ("25", 0.0025), ("50", 0.005))
        context = "cost$(lpad(round(Int, cost), 2, '0'))_risk$(round(Int, risk))_hurdle$(hurdle_id)bp"
        same_choice = cost == 30.0 && risk == 3.0 && hurdle == 0.005
        comparator = FrozenEvaluationChoice(
            TEST_ORIGIN,
            TEST_UNIVERSE,
            "frontier_only_robust_policy",
            same_choice ? ACTIVE_ID : "mandatory_inactive_cash",
        )
        safe = FrozenEvaluationChoice(
            TEST_ORIGIN,
            TEST_UNIVERSE,
            "innovation_safe_robust_policy",
            ACTIVE_ID,
        )
        push!(specs, FrozenRobustnessSpec(
            context,
            "cost_risk_hurdle_grid",
            0,
            cost,
            risk,
            hurdle,
            comparator,
            safe,
        ))
    end
    result = evaluate_frozen_robustness_specs(
        TEST_ORIGIN,
        TEST_UNIVERSE,
        history.returns,
        history.available,
        history.terminal,
        history.dates,
        2001,
        specs;
        security_weight_cap = 0.10,
    )
    @test length(result.outcomes) == 24
    @test length(unique(outcome.context_id for outcome in result.outcomes)) == 24
    lookup = Dict(outcome.context_id => outcome for outcome in result.outcomes)
    cost0 = lookup["cost00_risk3_hurdle00bp"]
    cost30 = lookup["cost30_risk3_hurdle00bp"]
    @test cost0.safe.annual_mean_component == cost30.safe.annual_mean_component
    @test cost30.safe.annual_turnover_cost > cost0.safe.annual_turnover_cost
    risk1 = lookup["cost05_risk1_hurdle00bp"]
    risk3 = lookup["cost05_risk3_hurdle00bp"]
    @test risk3.safe.annual_variance_penalty ≈ 3 * risk1.safe.annual_variance_penalty
    @test lookup["cost05_risk3_hurdle00bp"].safe.certainty_equivalent ==
        lookup["cost05_risk3_hurdle25bp"].safe.certainty_equivalent
    @test all(outcome -> outcome.safe.choice_ids == [ACTIVE_ID], result.outcomes)
    same = lookup["cost30_risk3_hurdle50bp"].contrast
    @test same.same_choice
    @test same.certainty_equivalent_difference === 0.0
end

@testset "v3 cap50 uses rank-subset weights and an isolated cache namespace" begin
    history = _history(evaluation_sessions = 20)
    full_returns = hcat(
        repeat(history.returns, 1, 50),
        repeat(3 .* history.returns, 1, 50),
    )
    full_available = trues(size(full_returns))
    full_terminal = falses(size(full_returns))
    comparator = FrozenEvaluationChoice(
        TEST_ORIGIN, TEST_UNIVERSE, "frontier_only_robust_policy",
        "mandatory_inactive_cash",
    )
    safe = FrozenEvaluationChoice(
        TEST_ORIGIN, TEST_UNIVERSE, "innovation_safe_robust_policy", ACTIVE_ID,
    )
    cap50_spec = FrozenRobustnessSpec(
        "common_equity_cap50", "common_equity_liquidity_cap", 50,
        5.0, 3.0, 0.0025, comparator, safe,
    )
    cap100_spec = FrozenRobustnessSpec(
        "common_equity_cap100", "common_equity_liquidity_cap", 100,
        5.0, 3.0, 0.0025, comparator, safe,
    )
    shared_cache = Dict{String,Any}()
    cap100 = evaluate_frozen_robustness_specs(
        TEST_ORIGIN, TEST_UNIVERSE, full_returns, full_available, full_terminal,
        history.dates, 2001, [cap100_spec];
        security_weight_cap = 0.10,
        strategy_path_cache = shared_cache,
        evaluated_liquidity_cap = 100,
    )
    cap50 = evaluate_frozen_robustness_specs(
        TEST_ORIGIN, TEST_UNIVERSE, full_returns[:, 1:50], full_available[:, 1:50],
        full_terminal[:, 1:50], history.dates, 2001, [cap50_spec];
        security_weight_cap = 0.10,
        strategy_path_cache = shared_cache,
        evaluated_liquidity_cap = 50,
    )
    @test only(cap100.outcomes).safe.annual_mean_component !=
        only(cap50.outcomes).safe.annual_mean_component
    @test only(cap100.outcomes).safe.choice_ids == only(cap50.outcomes).safe.choice_ids ==
        [ACTIVE_ID]
    @test length(shared_cache) == 2
    @test any(startswith(key, "full_selected_universe\0") for key in keys(shared_cache))
    @test any(startswith(key, "common_equity_liquidity_cap50\0") for key in keys(shared_cache))
    @test_throws ArgumentError evaluate_frozen_robustness_specs(
        TEST_ORIGIN, TEST_UNIVERSE, full_returns, full_available, full_terminal,
        history.dates, 2001, [cap50_spec];
        security_weight_cap = 0.10,
        evaluated_liquidity_cap = 50,
    )
    @test_throws ArgumentError evaluate_frozen_robustness_specs(
        TEST_ORIGIN, TEST_UNIVERSE, full_returns[:, 1:50], full_available[:, 1:50],
        full_terminal[:, 1:50], history.dates, 2001, [cap100_spec];
        security_weight_cap = 0.10,
        evaluated_liquidity_cap = 100,
    )
end

function _ledger_row(trial_id, policy_id, strategy_id; selected = false)
    values = Dict{String,Any}(
        "trial_id" => trial_id,
        "origin_id" => TEST_ORIGIN,
        "universe_id" => TEST_UNIVERSE,
        "strategy_id" => strategy_id,
        "compression_arm_id" => policy_id == "frontier_only_robust_policy" ?
            "frontier_only_exact_budget_matched" : "innovation_safe_exact",
        "policy_id" => policy_id,
        "requirements_hash" => "requirements",
        "generatable" => true,
        "failure_code" => "",
        "proposal_observation_count" => 20,
        "proposal_ce" => 0.01,
        "proposal_incremental_lower_bound" => 0.005,
        "policy_eligible" => selected,
        "policy_selected" => selected,
        "evaluation_observation_count" => 0,
        "evaluation_ce" => "",
        "evaluation_mean_component" => "",
        "evaluation_variance_penalty" => "",
        "evaluation_turnover_cost" => "",
        "record_hash" => "proposal-record-hash",
    )
    return values
end

@testset "v3 evaluation updates the complete ledger without trial drift" begin
    history = _history()
    evaluation = evaluate_frozen_choices(
        TEST_ORIGIN,
        TEST_UNIVERSE,
        history.returns,
        history.available,
        history.terminal,
        history.dates,
        2001,
        _choices();
        security_weight_cap = 0.10,
    )
    rows = [
        _ledger_row("safe-selected", "innovation_safe_robust_policy", ACTIVE_ID; selected = true),
        _ledger_row("safe-other", "innovation_safe_robust_policy", "other"),
        _ledger_row("comparator-selected", "frontier_only_robust_policy", "mandatory_inactive_cash"; selected = true),
        _ledger_row("forced-selected", "innovation_safe_forced_max", ACTIVE_ID; selected = true),
        _ledger_row("equal-selected-a", "equal_weight_available_policy", ACTIVE_ID; selected = true),
        _ledger_row("equal-selected-b", "equal_weight_available_policy", ACTIVE_ID_2; selected = true),
        _ledger_row("source-selected", "source_uncompressed_robust_policy", "mandatory_inactive_cash"; selected = true),
    ]
    candidate_outcome = EvaluationOutcome(
        TEST_ORIGIN,
        TEST_UNIVERSE,
        "full_search_candidate",
        "other",
        true,
        20,
        0.02,
        0.03,
        0.005,
        0.005,
        "",
    )
    updated = update_trial_ledger(
        rows,
        evaluation.outcomes;
        full_search_candidate_outcomes = [candidate_outcome],
    )
    @test getindex.(updated, "trial_id") == getindex.(rows, "trial_id")
    @test updated[1]["evaluation_observation_count"] == 20
    @test updated[3]["evaluation_ce"] == 0.0
    @test updated[2]["evaluation_observation_count"] == 20
    @test all(row -> row["evaluation_observation_count"] == 20, updated[[1, 3, 4, 5, 6, 7]])
    @test updated[2]["evaluation_ce"] == 0.02
    @test all(row -> row["record_hash"] != "proposal-record-hash", updated)
end

@testset "v3 full-search diagnostics are deterministic and search-wide" begin
    sessions = 120
    candidate_ids = ["candidate-a", "candidate-b", "candidate-c"]
    net = hcat(
        [0.001 + 0.0002 * cos(0.13 * index) for index in 1:sessions],
        [0.0002 + 0.001 * sin(0.2 * index) for index in 1:sessions],
        [-0.001 + 0.0003 * cos(0.17 * index) for index in 1:sessions],
    )
    available = trues(size(net))
    outcomes = [
        EvaluationOutcome(
            TEST_ORIGIN,
            TEST_UNIVERSE,
            "full_search_candidate",
            candidate_ids[index],
            true,
            sessions,
            0.0,
            0.0,
            0.0,
            0.0,
            "",
        ) for index in eachindex(candidate_ids)
    ]
    first_result = full_search_diagnostics(
        candidate_ids,
        outcomes,
        net,
        available;
        scope_values = (TEST_ORIGIN, TEST_UNIVERSE),
        bootstrap_repetitions = 200,
        moving_block_sessions = 5,
        cscv_blocks = 8,
    )
    second_result = full_search_diagnostics(
        candidate_ids,
        outcomes,
        net,
        available;
        scope_values = (TEST_ORIGIN, TEST_UNIVERSE),
        bootstrap_repetitions = 200,
        moving_block_sessions = 5,
        cscv_blocks = 8,
    )
    @test first_result.reality_check_seed == second_result.reality_check_seed
    @test first_result.hansen_spa_seed == second_result.hansen_spa_seed
    @test first_result.pbo_cscv_seed == second_result.pbo_cscv_seed
    @test length(unique((
        first_result.reality_check_seed,
        first_result.hansen_spa_seed,
        first_result.pbo_cscv_seed,
    ))) == 3
    expected_seed(base) = parse(Int, first(bytes2hex(sha256(codeunits(join(
        (base, TEST_ORIGIN, TEST_UNIVERSE), '\0',
    )))), 15); base = 16)
    @test first_result.reality_check_seed == expected_seed(310003)
    @test first_result.hansen_spa_seed == expected_seed(310004)
    @test first_result.pbo_cscv_seed == expected_seed(310005)
    @test first_result.white_reality_check_p_value ==
        second_result.white_reality_check_p_value
    @test first_result.hansen_spa_p_value == second_result.hansen_spa_p_value
    @test 0 <= first_result.white_reality_check_p_value <= 1
    @test 0 <= first_result.hansen_spa_p_value <= 1
    @test 0 <= first_result.pbo_cscv <= 1
    @test 0 <= first_result.deflated_sharpe_probability <= 1
    @test !ismissing(first_result.deflated_sharpe_expected_maximum)
    @test !isempty(first_result.deflated_sharpe_best_candidate_id)
    @test first_result.cscv_split_count == 70
    @test first_result.best_candidate_id == "candidate-a"
    @test length(first_result.complete_candidate_ids) == 3
    @test_throws ArgumentError full_search_diagnostics(
        candidate_ids,
        outcomes,
        net,
        available;
        scope_values = (TEST_ORIGIN, TEST_UNIVERSE, 2001),
        bootstrap_repetitions = 200,
        moving_block_sessions = 5,
        cscv_blocks = 8,
    )
    all_negative = full_search_diagnostics(
        candidate_ids,
        outcomes,
        net .- 0.01,
        available;
        scope_values = (TEST_ORIGIN, TEST_UNIVERSE * "-all-negative"),
        bootstrap_repetitions = 200,
        moving_block_sessions = 5,
        cscv_blocks = 8,
    )
    @test all_negative.hansen_spa_p_value == 1.0
end

@testset "v3 registered origin summary and calibration" begin
    contrasts = OriginEvaluationContrast[]
    for index in 1:5
        push!(contrasts, OriginEvaluationContrast(
            "O$index",
            TEST_UNIVERSE,
            true,
            "safe-$index",
            "comparator-$index",
            0.001 * index,
            0.0015 * index,
            0.0002 * index,
            0.0003 * index,
            false,
            "",
        ))
    end
    summary = summarize_origin_contrasts(
        contrasts;
        universe_id = TEST_UNIVERSE,
        minimum_complete_origins = 5,
    )
    @test summary["availability_gate_passed"] === true
    @test summary["arithmetic_mean"] ≈ 0.003
    @test summary["nearest_rank_median"] ≈ 0.003
    @test length(summary["origin_values"]) == 5

    calibration = proposal_evaluation_calibration(1:5, [2, 1, 3, 5, 4])
    @test calibration["complete_pair_count"] == 5
    @test calibration["status"] == "DESCRIPTIVE_ONLY"
    @test isfinite(calibration["pearson_correlation"])
    @test isfinite(calibration["spearman_rank_correlation"])
    undefined_calibration = proposal_evaluation_calibration(zeros(5), zeros(5))
    @test undefined_calibration["status"] == "UNDEFINED_ZERO_VARIANCE"
    @test undefined_calibration["pearson_correlation"] == ""
end

@testset "v3 leave-one-origin-out is failure-aware aggregation only" begin
    contrasts = OriginEvaluationContrast[]
    hashes = Dict{Tuple{String,String},NamedTuple}()
    for index in 1:19
        origin_id = "O$(lpad(index, 3, '0'))"
        complete = index != 19
        push!(contrasts, OriginEvaluationContrast(
            origin_id,
            TEST_UNIVERSE,
            complete,
            "safe-$index",
            "comparator-$index",
            complete ? 0.001 * index : missing,
            complete ? 0.0015 * index : missing,
            complete ? 0.0002 * index : missing,
            complete ? 0.0003 * index : missing,
            false,
            complete ? "" : "EVALUATION_PATH_UNAVAILABLE",
        ))
        hashes[(origin_id, TEST_UNIVERSE)] = (
            safe = "sealed-safe-$index",
            comparator = "sealed-comparator-$index",
        )
    end
    summary = summarize_origin_contrasts(
        contrasts;
        universe_id = TEST_UNIVERSE,
        minimum_complete_origins = 15,
        sealed_choice_hashes = hashes,
    )
    @test summary["origin_values"][1]["safe_choice_sha256"] == "sealed-safe-1"
    @test summary["origin_values"][1]["comparator_choice_sha256"] ==
        "sealed-comparator-1"
    loo = leave_one_origin_out_summary(contrasts; universe_id = TEST_UNIVERSE)
    @test loo["rule"] == "AGGREGATION_ONLY_NO_RESELECTION"
    @test loo["omission_count"] == 19
    @test length(loo["rows"]) == 19
    @test getindex.(loo["rows"], "omitted_origin_id") ==
        ["O$(lpad(index, 3, '0'))" for index in 1:19]
    omit_incomplete = only(filter(
        row -> row["omitted_origin_id"] == "O019", loo["rows"],
    ))
    @test omit_incomplete["complete_retained_origin_count"] == 18
    @test omit_incomplete["incomplete_retained_origin_count"] == 0
    omit_complete = only(filter(
        row -> row["omitted_origin_id"] == "O001", loo["rows"],
    ))
    @test omit_complete["complete_retained_origin_count"] == 17
    @test omit_complete["incomplete_retained_origin_count"] == 1
    @test omit_complete["arithmetic_mean_ce_difference"] ≈ mean(0.002:0.001:0.018)
    @test_throws ArgumentError leave_one_origin_out_summary(
        contrasts[1:18]; universe_id = TEST_UNIVERSE,
    )
end
