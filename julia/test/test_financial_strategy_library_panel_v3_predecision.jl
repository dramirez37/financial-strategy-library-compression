using Statistics: var
using Test

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV3Predecision.jl"))
using .FinancialStrategyLibraryPanelV3Predecision

@testset "v3 predecision grammar and capabilities" begin
    catalog = portfolio_catalog()
    @test length(catalog) == 96
    @test length(unique(specification_id.(catalog))) == 96
    for universe in ("liquid_common_equity", "liquid_plain_etf")
        requirements = capability_ids.(catalog, Ref(universe))
        @test all(row -> length(row) == 13, requirements)
        @test length(union(Set.(requirements)...)) == 31
    end
    equity = Set(capability_ids(first(catalog), "liquid_common_equity"))
    etf = Set(capability_ids(first(catalog), "liquid_plain_etf"))
    @test "platform::point_in_time_common_equity_data::v3" in equity
    @test !("platform::point_in_time_plain_etf_data::v3" in equity)
    @test "platform::point_in_time_plain_etf_data::v3" in etf
end

@testset "v3 predecision burden schedule" begin
    baseline = PortfolioSpecification(
        "momentum_20",
        "always",
        5,
        "equal_weight",
        0.5,
        "horizon",
    )
    @test strategy_burden(baseline) == 181
    complex = PortfolioSpecification(
        "momentum_60",
        "trend_100",
        20,
        "inverse_volatility",
        1.0,
        "signal_flip",
    )
    @test strategy_burden(complex) == 550
end

@testset "v3 predecision portfolio timing and cash residual" begin
    specification = PortfolioSpecification(
        "momentum_20",
        "always",
        20,
        "equal_weight",
        1.0,
        "horizon",
    )
    returns = fill(0.001, 130, 25)
    result = backtest_portfolio_specification(
        specification,
        returns;
        security_weight_cap = 0.05,
        decision_to_first_return_lag_sessions = 2,
        one_way_cost_bps = 0,
    )
    intended_gross = vec(sum(result.intended_weights; dims = 2))
    effective_gross = vec(sum(result.effective_weights; dims = 2))
    @test findfirst(>(0), intended_gross) == 21
    @test findfirst(>(0), effective_gross) == 23
    @test maximum(result.intended_weights) <= 0.05 + 1e-12
    @test maximum(intended_gross) <= 1.0 + 1e-12

    sparse = backtest_portfolio_specification(
        specification,
        fill(0.001, 130, 5);
        security_weight_cap = 0.05,
        decision_to_first_return_lag_sessions = 2,
        one_way_cost_bps = 0,
    )
    sparse_gross = vec(sum(sparse.intended_weights; dims = 2))
    @test maximum(sparse_gross) ≈ 0.25
end

@testset "v3 registered portfolio volatility target" begin
    specification = PortfolioSpecification(
        "momentum_20",
        "always",
        20,
        "equal_weight",
        1.0,
        "horizon",
    )
    returns = [isodd(session) ? 0.04 : -0.03 for session in 1:130, _ in 1:25]
    result = backtest_portfolio_specification(
        specification,
        returns;
        security_weight_cap = 0.05,
        decision_to_first_return_lag_sessions = 2,
        one_way_cost_bps = 0,
        portfolio_volatility_target = 0.10,
    )
    intended_gross = vec(sum(result.intended_weights; dims = 2))
    @test maximum(intended_gross) < 0.30
    @test maximum(intended_gross) > 0.10
    for session in findall(>(0), intended_gross)
        session >= 20 || continue
        weights = @view result.intended_weights[session, :]
        projected = [
            sum(weights .* @view returns[history_session, :])
            for history_session in (session - 19):session
        ]
        @test sqrt(252 * var(projected)) <= 0.10 + 1e-12
    end
end

@testset "v3 terminal and unresolved-return semantics" begin
    specification = PortfolioSpecification(
        "momentum_20",
        "always",
        20,
        "equal_weight",
        1.0,
        "horizon",
    )
    terminal_returns = fill(0.001, 130, 25)
    terminal_returns[50, 1] = -1.0
    terminal = falses(size(terminal_returns))
    terminal[50, 1] = true
    return_available = trues(size(terminal_returns))
    return_available[51:end, 1] .= false
    terminal_result = backtest_portfolio_specification(
        specification,
        terminal_returns;
        security_weight_cap = 0.05,
        one_way_cost_bps = 0,
        terminal_delisting = terminal,
        return_available,
    )
    @test terminal_result.available[50]
    @test !ismissing(terminal_result.gross_returns[50])
    @test terminal_result.gross_returns[50] < 0
    @test terminal_result.intended_weights[50, 1] == 0
    @test all(iszero, @view terminal_result.effective_weights[51:end, 1])

    unresolved_returns = Matrix{Union{Missing,Float64}}(fill(0.001, 130, 25))
    unresolved_returns[50, 1] = missing
    unresolved_result = backtest_portfolio_specification(
        specification,
        unresolved_returns;
        security_weight_cap = 0.05,
        one_way_cost_bps = 0,
    )
    @test !unresolved_result.available[50]
    @test ismissing(unresolved_result.gross_returns[50])
    @test ismissing(unresolved_result.net_returns[50])
end

@testset "v3 predecision input rejection" begin
    specification = first(portfolio_catalog())
    @test_throws ArgumentError backtest_portfolio_specification(
        specification,
        [0.0 NaN];
        security_weight_cap = 0.05,
    )
    @test_throws ArgumentError backtest_portfolio_specification(
        specification,
        [0.0 -1.01];
        security_weight_cap = 0.05,
    )
    @test_throws ArgumentError PortfolioSpecification(
        "future_signal",
        "always",
        5,
        "equal_weight",
        0.5,
        "horizon",
    )
end
