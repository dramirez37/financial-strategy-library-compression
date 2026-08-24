@testset "larger-universe financial mechanism protocol" begin
    config = load_financial_annual_config()
    @test length(config["universe"]["tickers"]) == 100
    @test config["ranking"]["expected_pattern_is_hard_gate"] === false
    catalog = finite_strategy_catalog_annual(config)
    @test length(catalog) == 100 * 96
    @test length(unique(strategy.id for strategy in catalog)) == 100 * 96
    @test all(length(strategy.modules) == 7 for strategy in catalog)

    gross = [0.01, -0.005, 0.02]
    turnover = [1.0, 0.5, 0.25]
    stats = FinancialAnnualWalkforwardAudit._stats(gross, turnover, eachindex(gross))
    cost_bps = 5.0
    explicit_net = gross .- (cost_bps / 10_000) .* turnover
    @test isapprox(
        FinancialAnnualWalkforwardAudit._utility(stats, cost_bps, config),
        FinancialAnnualWalkforwardAudit.TerminalAudit._utility(explicit_net, config);
        atol = 1.0e-14,
        rtol = 0,
    )

    gaps = Dict(
        "a" => [3.0, 0.0],
        "b" => [2.5, 0.0],
        "c" => [0.0, 2.0],
    )
    selected = greedy_marginal_selection(["a", "b", "c"], gaps, [0.5, 0.5], 2)
    @test selected.selected == ["a", "c"]
    @test selected.marginals == [1.5, 1.0]
    @test selected.value == 2.5

    transition = [0.8 0.2; 0.3 0.7]
    predicted = FinancialAnnualWalkforwardAudit._predicted_occupation(transition, 1, 20, 0.99)
    @test isapprox(sum(predicted), 1.0; atol = 1.0e-14, rtol = 0)
    realized = FinancialAnnualWalkforwardAudit._realized_occupation([1, 2, 1, 2], 1:4, 0.99, 2)
    @test isapprox(sum(realized), 1.0; atol = 1.0e-14, rtol = 0)
end
