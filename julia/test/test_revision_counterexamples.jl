@testset "unified semi-Markov counterexample fixtures" begin
    correlated = correlated_projection_witness()
    @test correlated.projection.holds
    @test correlated.dependent
    @test correlated.joint_value == 1 // 4
    @test correlated.product_value == 1 // 8

    stationary = unified_stationary_policy_witness()
    @test stationary.projection.holds
    @test stationary.converged
    @test stationary.policy_equation_residual == 0
    @test stationary.bellman_residual == 0
    @test stationary.bridge_action == 1
    @test stationary.bridge_value == 2
    @test stationary.candidate_action == 0
    @test stationary.candidate_value == 4

    normalized = t4_unified_witness(5 // 1)
    @test normalized.holds
    @test normalized.loss == normalized.formula
    @test normalized.loss > normalized.target

    cost_boundary = t6_cost_boundary_witness()
    @test cost_boundary.actual == 0
    @test cost_boundary.probability_gap_without_cost == 1 // 2
    @test cost_boundary.naive_bound_fails
    @test cost_boundary.revised_bound_holds

    complementarity = generator_complementarity_witness()
    @test complementarity.low_premium == 0
    @test complementarity.high_premium == 1 // 2
    @test complementarity.complementarity

    persistence = persistence_direction_witnesses()
    @test persistence.increasing.holds
    @test persistence.decreasing.holds
    @test persistence.increasing.high > persistence.increasing.low
    @test persistence.decreasing.high < persistence.decreasing.low

    information = information_direction_witnesses()
    @test information.increasing.holds
    @test !information.increasing.demand_less
    @test information.increasing.demand_more
    @test information.decreasing.holds
    @test information.decreasing.demand_less
    @test !information.decreasing.demand_more

    delay = delay_direction_witnesses()
    @test delay.operator_positive.longer_is_higher
    @test delay.operator_negative.longer_is_lower
    @test delay.value_consistent.shorter_is_higher
end

@testset "deterministic unified semi-Markov gauntlet smoke search" begin
    result = run_revision_gauntlet(
        random_trials = 4,
        t6_trials = 8,
        t7_trials = 8,
        exhaustive_t3 = false,
    )
    @test result["principal_t1_t7_survived"]
    @test result["lean_formalization_gate_open"]
    @test result["lean_unified_bellman_verified"]
    @test isempty(result["random_failures"])
    @test result["search_counts"]["models"] == 4
    @test result["search_counts"]["t6_lower_bound_checks"] == 8
    @test result["search_counts"]["t7_substitution_checks"] > 0
    @test all(
        theorem["survived_search"] for theorem in values(result["theorems"])
    )
end
