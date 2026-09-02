using Test

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV3.jl"))
using .FinancialStrategyLibraryPanelV3

@testset "v3 always-feasible outside option" begin
    negative = PortfolioAlternative("negative", -0.01, -0.02, -0.03)
    @test frontier_policy_choice([negative]).candidate_id == "mandatory_inactive_cash"

    zero = PortfolioAlternative("zero", 0.0, 0.0, 0.0)
    @test frontier_policy_choice([zero]).candidate_id == "mandatory_inactive_cash"

    uncertified = PortfolioAlternative("uncertified", 0.01, -0.01, 0.02)
    @test frontier_policy_choice([uncertified]).candidate_id == "mandatory_inactive_cash"

    positive = PortfolioAlternative("positive", 0.01, 0.0026, 0.02)
    choice = frontier_policy_choice([positive]; hurdle = 0.0025)
    @test choice.candidate_id == "positive"
    @test choice.reason == "certified_active_candidate_above_cash"
end

@testset "v3 nested no-harm adoption" begin
    comparator_alt = PortfolioAlternative("comparator", 0.01, 0.0026, 0.015)
    comparator = frontier_policy_choice([comparator_alt])
    weak = PortfolioAlternative("weak-safe", 0.03, 0.0025, -0.01)
    @test innovation_safe_policy_choice(
        comparator,
        [weak];
        hurdle = 0.0025,
    ).candidate_id == "comparator"

    strong = PortfolioAlternative("strong-safe", 0.02, 0.0026, 0.025)
    safe = innovation_safe_policy_choice(comparator, [weak, strong]; hurdle = 0.0025)
    @test safe.candidate_id == "strong-safe"
    @test safe.reason == "closure_enabled_candidate_clears_simultaneous_hurdle"

    contrast = policy_contrast(safe, comparator)
    @test contrast.available
    @test contrast.value ≈ 0.01
    @test !contrast.same_choice
end

@testset "v3 action-set nesting" begin
    comparator = ["mandatory_inactive_cash", "a"]
    safe = ["mandatory_inactive_cash", "a", "b"]
    @test validate_nested_action_sets(comparator, safe)
    @test_throws ArgumentError validate_nested_action_sets(comparator, ["mandatory_inactive_cash", "b"])
    @test_throws ArgumentError validate_nested_action_sets(["a"], safe)
end

@testset "v3 certainty equivalent and shrinkage" begin
    result = annualized_certainty_equivalent([0.01, -0.01]; annualization_sessions = 2, risk_aversion = 3)
    @test result.daily_mean == 0.0
    @test result.daily_variance ≈ 0.0002
    @test result.certainty_equivalent ≈ -0.0006
    @test family_shrunk_score(0.02, 0.0, 252; prior_strength_sessions = 252) ≈ 0.01
    @test stable_seed(310002, "proposal_max_t", "origin_2005", "liquid_common_equity") ==
          stable_seed(310002, "proposal_max_t", "origin_2005", "liquid_common_equity")
    @test stable_seed(310002, "proposal_max_t", "origin_2005", "liquid_common_equity") !=
          stable_seed(310002, "proposal_max_t", "origin_2006", "liquid_common_equity")
end

@testset "v3 diversified portfolio construction" begin
    weights = normalize_long_weights([3.0, 1.0, 0.0]; gross_target = 0.5, security_weight_cap = 0.3)
    @test sum(weights) ≈ 0.5
    @test maximum(weights) <= 0.3 + 1e-12
    @test weights[1] ≈ 0.3
    @test weights[2] ≈ 0.2
    @test normalize_long_weights(
        [0.0, 0.0];
        gross_target = 0.0,
        security_weight_cap = 0.3,
    ) == [0.0, 0.0]
    @test_throws ArgumentError normalize_long_weights(
        [0.0, 0.0];
        gross_target = 0.5,
        security_weight_cap = 0.3,
    )

    returns = [0.01 0.02; -0.01 0.00]
    effective = [0.5 0.5; 0.5 0.5]
    portfolio = aggregate_portfolio_returns(returns, effective; one_way_cost_bps = 0)
    @test portfolio.gross_returns ≈ [0.015, -0.005]
    @test portfolio.turnover ≈ [1.0, 0.0]
    @test portfolio.net_returns == portfolio.gross_returns

    volume = fill(1000.0, 2, 2)
    volatility = fill(0.02, 2, 2)
    capacity = capacity_adjusted_portfolio_returns(
        returns,
        effective,
        volume,
        volatility;
        aum_usd = 100.0,
        half_spread_bps = 10.0,
        square_root_impact_coefficient = 0.0,
        maximum_daily_adv_participation = 0.10,
    )
    @test all(capacity.available)
    @test capacity.cost_returns == Union{Missing,Float64}[0.001, 0.0]
    @test capacity.net_returns ≈ Union{Missing,Float64}[0.014, -0.005]

    unavailable = capacity_adjusted_portfolio_returns(
        returns,
        effective,
        volume,
        volatility;
        aum_usd = 100.0,
        half_spread_bps = 10.0,
        square_root_impact_coefficient = 0.0,
        maximum_daily_adv_participation = 0.01,
    )
    @test !unavailable.available[1]
    @test ismissing(unavailable.net_returns[1])
end
