@testset "terminal financial audit" begin
    config = load_financial_config()
    catalog = finite_strategy_catalog(config)
    @test length(catalog) == 25 * 96
    @test length(unique(strategy.id for strategy in catalog)) == 25 * 96
    @test all(length(strategy.modules) == 7 for strategy in catalog)
    @test Set(strategy.ticker for strategy in catalog) == Set(String.(config["universe"]["tickers"]))

    result = run_financial_terminal_audit(config)
    if result.status == "pending_data"
        @test !result.empirical_results_permitted
        @test !result.aggregate_outputs_publishable
        @test isempty(result.candidate_audit)
    else
        @test result.status == "empirical_complete_aggregate_publishable"
        @test result.empirical_results_permitted
        @test result.aggregate_outputs_publishable
        @test !result.provenance["raw_data_redistribution_permitted"]
        @test result.provenance["aggregate_outputs_publishable"]
        @test length(result.candidate_audit) == 25 * 96
        @test length(result.decision_hash) == 64
        @test length(result.initial_library) >= 25
        @test length(result.safe_library) <= length(result.initial_library)
        @test length(result.frontier_only_library) <= length(result.initial_library)
        safe_row = only(row for row in result.mechanism_rows if row.question == "B")
        @test safe_row.current_validation_value_change == 0.0
        @test safe_row.locked_candidate_quality_change == 0.0
        @test safe_row.result == "identity_pass"
        @test all(
            isapprox(row.total, row.operational + row.generative; atol = 1.0e-12, rtol = 0) for
            row in result.decomposition_rows
        )
        @test length(result.ranking_summaries) == 4
        @test length(result.uncertainty) == 4
        @test length(result.cost_sensitivity) == 12
    end
end
