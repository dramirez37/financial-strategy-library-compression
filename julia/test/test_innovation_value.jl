function _value_decomposition_fixture()
    beliefs = FiniteBeliefSpace([:only])
    modules = [GenerativeModule(:key)]
    empty_modules = ModuleSet{Symbol}()
    key = ModuleSet([ModuleId(:key)])
    strategies = [
        Strategy(:inactive, OperationalProfile(beliefs, [0]), empty_modules),
        Strategy(:bridge, OperationalProfile(beliefs, [0]), key),
        Strategy(:future, OperationalProfile(beliefs, [2]), empty_modules),
    ]
    catalog = StrategyCatalog(beliefs, modules, strategies, StrategyId(:inactive))
    closure = identity_generative_closure(modules)
    base = RawLibrary(catalog, [StrategyId(:inactive)])
    bridge = insert_strategy(catalog, base, StrategyId(:bridge))
    future = RawLibrary(catalog, [StrategyId(:inactive), StrategyId(:future)])
    states = [
        compressed_state(catalog, closure, base),
        compressed_state(catalog, closure, bridge),
        compressed_state(catalog, closure, future),
    ]
    process = DiscountedResearchProcess(
        states,
        [ResearchProject(:innovate, key)],
        MarkovKernel(beliefs, reshape([1], 1, 1)),
        (belief, state, project) ->
            dirac(ModuleId(:key) in state.closure ? states[3] : states[1]),
        (belief, state, project) -> 0,
        project -> 0,
        1 // 2,
    )
    return (; process, catalog, closure, base, bridge, future, belief = Belief(:only))
end

function _delayed_gap_fixture()
    beliefs = FiniteBeliefSpace([:current, :future])
    modules = [GenerativeModule(:token)]
    empty_modules = ModuleSet{Symbol}()
    strategies = [
        Strategy(:inactive, OperationalProfile(beliefs, [0, 0]), empty_modules),
        Strategy(:candidate, OperationalProfile(beliefs, [0, 2]), empty_modules),
    ]
    catalog = StrategyCatalog(beliefs, modules, strategies, StrategyId(:inactive))
    closure = identity_generative_closure(modules)
    base = RawLibrary(catalog, [StrategyId(:inactive)])
    inserted = insert_strategy(catalog, base, StrategyId(:candidate))
    states = [
        compressed_state(catalog, closure, base),
        compressed_state(catalog, closure, inserted),
    ]
    kernel = MarkovKernel(beliefs, [0 1; 0 1])
    process = DiscountedResearchProcess(
        states,
        [ResearchProject(:dummy, empty_modules)],
        kernel,
        (belief, state, project) -> dirac(state),
        (belief, state, project) -> 10,
        project -> 0,
        1 // 2,
    )
    return (;
        process,
        catalog,
        closure,
        base,
        inserted,
        current = Belief(:current),
        future = Belief(:future),
        candidate = StrategyId(:candidate),
    )
end

@testset "F6 operational--generative decomposition" begin
    fixture = _value_decomposition_fixture()
    process = fixture.process
    catalog = fixture.catalog
    closure = fixture.closure
    belief = fixture.belief
    base = fixture.base
    bridge = StrategyId(:bridge)

    @test passive_value(process, catalog, 2, belief, base) == 0
    @test full_value(process, catalog, closure, 2, belief, base) == 0
    @test research_option_premium(process, catalog, closure, 2, belief, base) == 0
    @test operational_innovation(process, catalog, 2, belief, base, bridge) == 0
    @test generative_innovation(process, catalog, closure, 2, belief, base, bridge) == 1
    @test total_innovation(process, catalog, closure, 2, belief, base, bridge) == 1
    @test total_innovation(process, catalog, closure, 2, belief, base, bridge) ==
          operational_innovation(process, catalog, 2, belief, base, bridge) +
          generative_innovation(process, catalog, closure, 2, belief, base, bridge)
end

@testset "F7 finite Strategy Innovation Equation" begin
    fixture = _delayed_gap_fixture()
    process = fixture.process
    catalog = fixture.catalog
    base = fixture.base
    candidate = fixture.candidate

    @test frontier_gap(catalog, base, candidate).values == (0 // 1, 2 // 1)
    @test frontier_gap(catalog, base, candidate, fixture.current) == 0
    @test frontier_gap(catalog, base, candidate, fixture.future) == 2
    @test discounted_belief_occupancy(process, 2, fixture.current) ==
          ExactRational[1, 1 // 2]
    @test discounted_gap_sum(process, catalog, 2, fixture.current, base, candidate) == 1
    @test passive_operational_innovation(
        process,
        catalog,
        2,
        fixture.current,
        base,
        candidate,
    ) == 1
    @test passive_operational_innovation(
        process,
        catalog,
        2,
        fixture.current,
        base,
        candidate,
    ) == discounted_gap_sum(
        process,
        catalog,
        2,
        fixture.current,
        base,
        candidate,
    )

    larger = fixture.inserted
    @test issubset(base, larger)
    @test passive_operational_innovation(
        process,
        catalog,
        2,
        fixture.current,
        larger,
        candidate,
    ) <= passive_operational_innovation(
        process,
        catalog,
        2,
        fixture.current,
        base,
        candidate,
    )
end

@testset "T6 exact generative carrier lower-bound fixture" begin
    fixture = generative_lower_bound_fixture()
    @test fixture.discount == 1 // 2
    @test fixture.duration == 1
    @test fixture.expected_completion_gain == 2
    @test fixture.operating_adjustment == 0
    @test fixture.lower_bound == 1
    @test fixture.lower_bound == generative_strategy_lower_bound(
        fixture.discount,
        fixture.duration,
        fixture.research_cost,
        fixture.admission_probability,
        fixture.survival_factor,
        fixture.expected_completion_gain;
        operating_adjustment = fixture.operating_adjustment,
    )

    baseline = fixture.lower_bound
    @test generative_strategy_lower_bound(1 // 2, 1, 0 // 1, 1 // 2, 1 // 1, 2 // 1) <= baseline
    @test generative_strategy_lower_bound(1 // 2, 1, 0 // 1, 1 // 1, 1 // 2, 2 // 1) <= baseline
    @test generative_strategy_lower_bound(1 // 2, 1, 0 // 1, 1 // 1, 1 // 1, 1 // 1) <= baseline
    @test generative_strategy_lower_bound(1 // 2, 1, 1 // 2, 1 // 1, 1 // 1, 2 // 1) <= baseline
    @test generative_strategy_lower_bound(1 // 2, 2, 0 // 1, 1 // 1, 1 // 1, 2 // 1) <= baseline
    @test generative_strategy_lower_bound(
        1 // 2,
        1,
        0 // 1,
        1 // 1,
        1 // 1,
        2 // 1;
        operating_adjustment = -1 // 2,
    ) == 1 // 2

    @test_throws ArgumentError generative_strategy_lower_bound(
        1 // 2,
        0,
        0 // 1,
        1 // 1,
        1 // 1,
        2 // 1,
    )
end

@testset "strategy-value figure data" begin
    config = load_strategy_value_figure_config()
    fixture = strategy_value_figure_fixture(config)
    @test fixture.current_gap == 0
    @test fixture.operational_value > 0
    @test fixture.operational_value == fixture.discounted_gap_value
    @test fixture.operational_value ==
          sum(fixture.occupancy .* collect(fixture.gap.values))
    @test any(fixture.gap.values .> 0)
    @test any(fixture.occupancy[index] > 0 && fixture.gap.values[index] > 0
              for index in eachindex(fixture.occupancy))
end
