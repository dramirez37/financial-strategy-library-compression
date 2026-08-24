@testset "unified canonical benchmark frozen-reference fixture" begin
    parameters = UnifiedBenchmarkParameters(
        1 // 2,
        1 // 16,
        1 // 1,
        1 // 8,
        2,
        3 // 4,
        1 // 1,
    )
    evaluated = evaluate_unified_candidate(parameters)
    @test evaluated.policy_signature ==
          "research:discover|continue|research:scale|research:scale|continue|continue"
    @test evaluated.minimum_margin == 1 // 8
    @test getproperty.(evaluated.rows, :value) == ExactRational[
        113 // 288,
        113 // 1440,
        16 // 15,
        37 // 30,
        14 // 3,
        22 // 3,
    ]
    @test evaluated.result.converged
    @test evaluated.result.iterations == 3
    @test evaluated.result.policy_equation_residual == 0
    @test evaluated.result.bellman_residual == 0
end

@testset "selected unified benchmark exact policy and raw lift" begin
    parameters = UnifiedBenchmarkParameters(
        1 // 2,
        1 // 32,
        1 // 1,
        3 // 16,
        2,
        3 // 4,
        1 // 1,
    )
    evaluated = evaluate_unified_candidate(parameters)
    process = evaluated.fixture.process
    @test length(process.catalog.strategies) == 4
    @test length(process.raw_libraries) == 8
    @test length(process.compressed_states) == 3
    @test sort(
        [
            count(
                library ->
                    compressed_library_state(
                        process.catalog,
                        process.closure,
                        library,
                    ) == state,
                process.raw_libraries,
            ) for state in process.compressed_states
        ],
    ) == [1, 3, 4]
    @test all(project.duration > 0 for project in process.projects)
    @test all(project.operates_during_research for project in process.projects)

    @test evaluated.policy_signature ==
          "research:discover|continue|research:scale|research:scale|continue|continue"
    @test evaluated.minimum_margin == 3 // 16
    @test getproperty.(evaluated.rows, :value) == ExactRational[
        115 // 288,
        23 // 288,
        1 // 1,
        7 // 6,
        14 // 3,
        22 // 3,
    ]
    @test getproperty.(evaluated.rows, :margin) == ExactRational[
        23 // 96,
        245 // 384,
        23 // 48,
        29 // 48,
        3 // 16,
        3 // 16,
    ]
    @test evaluated.has_continue
    @test evaluated.has_discover
    @test evaluated.has_scale
    @test evaluated.no_ties
    @test evaluated.result.policy_equation_residual == 0
    @test evaluated.result.bellman_residual == 0

    scale = only(
        project for project in process.projects if
        project.id == ResearchProjectId(:scale)
    )
    k1 = only(
        state for state in process.compressed_states if
        ModuleId(:scale_capability) in state.closure &&
        all(iszero(state.frontier[belief]) for belief in process.belief_kernel.space)
    )
    generated = candidate_generation_distribution(
        process,
        scale,
        Belief(:low),
        k1,
    )
    admitted = admitted_candidate_distribution(
        process,
        scale,
        Belief(:low),
        k1,
    )
    @test probability(
        generated,
        CandidateOutcome(StrategyId(:descendant)),
    ) == 1
    @test probability(
        admitted,
        CandidateOutcome(StrategyId(:descendant)),
    ) == 3 // 4
    completion = process.completion(scale, Belief(:low), k1)
    @test all(
        length(outcome.path) == scale.duration + 1 for
        outcome in completion.outcomes
    )
    @test sum(
        mass for (outcome, mass) in
        zip(completion.outcomes, completion.probabilities) if
        terminal_belief(outcome) == Belief(:high);
        init = exact_rational(0),
    ) == 3 // 8

    raw = raw_infinite_horizon_policy_iteration(process)
    @test raw.converged
    @test raw.policy_equation_residual == 0
    @test raw.bellman_residual == 0
    for library in process.raw_libraries, belief in process.belief_kernel.space
        state = compressed_library_state(
            process.catalog,
            process.closure,
            library,
        )
        @test state_value(raw, belief, library) ==
              state_value(evaluated.result, belief, state)
        @test policy_action(raw, belief, library) ==
              policy_action(evaluated.result, belief, state)
    end
end

@testset "selected unified benchmark perturbation and comparative-static gates" begin
    parameters = UnifiedBenchmarkParameters(
        1 // 2,
        1 // 32,
        1 // 1,
        3 // 16,
        2,
        3 // 4,
        1 // 1,
    )
    evaluated = evaluate_unified_candidate(parameters)
    config = UnifiedBenchmarkSearch.TOML.parsefile(
        UnifiedBenchmarkSearch.DEFAULT_CONFIG,
    )
    stability = UnifiedBenchmarkSearch._stability_audit(
        evaluated,
        config,
        config["gates"]["policy_iteration_limit"],
    )
    @test stability.all_stable
    @test stability.minimum_margin == 11 // 64
    @test length(stability.rows) == 11

    comparatives = UnifiedBenchmarkSearch._comparative_static_audit(
        parameters,
        config,
        config["gates"]["policy_iteration_limit"],
    )
    @test comparatives.all_visible
    @test all(values(comparatives.checks))
    @test length(comparatives.rows) == 10

    deep = UnifiedBenchmarkSearch._deep_audit(evaluated, config)
    @test all(values(deep.checks))
    @test deep.value_iteration.residual <=
          exact_rational(config["gates"]["value_iteration_residual_tolerance"])
end
