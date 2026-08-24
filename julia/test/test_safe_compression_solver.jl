function _solver_library(catalog, ids::Symbol...)
    return RawLibrary(
        catalog,
        StrategyId{Symbol}[StrategyId(id) for id in ids],
    )
end

function _solver_burden(library, weights)
    return sum(
        (weights[strategy_id] for strategy_id in library);
        init = zero(ExactRational),
    )
end

function _enumerated_weight_optima(catalog, closure, source, weights)
    optional = StrategyId{Symbol}[
        row.id for row in catalog.strategies if
        row.id in source && row.id != catalog.inactive_strategy
    ]
    target = compressed_state(catalog, closure, source)
    best::Union{Nothing,ExactRational} = nothing
    optima = RawLibrary{Symbol}[]
    for mask in UInt64(0):((UInt64(1) << length(optional)) - UInt64(1))
        ids = StrategyId{Symbol}[catalog.inactive_strategy]
        for (index, strategy_id) in enumerate(optional)
            iszero(mask & (UInt64(1) << (index - 1))) ||
                push!(ids, strategy_id)
        end
        candidate = RawLibrary(catalog, ids)
        compressed_state(catalog, closure, candidate) == target || continue
        value = _solver_burden(candidate, weights)
        if isnothing(best) || value < best
            best = value
            empty!(optima)
            push!(optima, candidate)
        elseif value == best
            push!(optima, candidate)
        end
    end
    return (; objective = best, libraries = optima)
end

function _weighted_cardinality_fixture()
    beliefs = FiniteBeliefSpace([:low, :high])
    modules = [GenerativeModule(:left_module), GenerativeModule(:right_module)]
    empty_modules = ModuleSet{Symbol}()
    left_module = ModuleSet([ModuleId(:left_module)])
    right_module = ModuleSet([ModuleId(:right_module)])
    both_modules = union(left_module, right_module)
    strategies = [
        Strategy(:inactive, OperationalProfile(beliefs, [0, 0]), empty_modules),
        Strategy(:left, OperationalProfile(beliefs, [2, 0]), left_module),
        Strategy(:right, OperationalProfile(beliefs, [0, 2]), right_module),
        Strategy(:bundle, OperationalProfile(beliefs, [2, 2]), both_modules),
    ]
    catalog = StrategyCatalog(
        beliefs,
        modules,
        strategies,
        StrategyId(:inactive),
    )
    closure = identity_generative_closure(modules)
    source = RawLibrary(catalog, [row.id for row in strategies])
    weights = Dict(
        StrategyId(:inactive) => 0 // 1,
        StrategyId(:left) => 1 // 1,
        StrategyId(:right) => 1 // 1,
        StrategyId(:bundle) => 3 // 1,
    )
    return (; catalog, closure, source, weights)
end

function _multiple_optimum_fixture()
    beliefs = FiniteBeliefSpace([:only])
    modules = [GenerativeModule(:key)]
    empty_modules = ModuleSet{Symbol}()
    key = ModuleSet([ModuleId(:key)])
    strategies = [
        Strategy(:inactive, OperationalProfile(beliefs, [0]), empty_modules),
        Strategy(:first, OperationalProfile(beliefs, [1]), key),
        Strategy(:second, OperationalProfile(beliefs, [1]), key),
    ]
    catalog = StrategyCatalog(
        beliefs,
        modules,
        strategies,
        StrategyId(:inactive),
    )
    closure = identity_generative_closure(modules)
    source = RawLibrary(catalog, [row.id for row in strategies])
    weights = Dict(
        StrategyId(:inactive) => 0 // 1,
        StrategyId(:first) => 1 // 1,
        StrategyId(:second) => 1 // 1,
    )
    return (; catalog, closure, source, weights)
end

function _greedy_gap_fixture()
    beliefs = FiniteBeliefSpace([:only])
    modules = [GenerativeModule(:left_module), GenerativeModule(:right_module)]
    empty_modules = ModuleSet{Symbol}()
    left_module = ModuleSet([ModuleId(:left_module)])
    right_module = ModuleSet([ModuleId(:right_module)])
    both_modules = union(left_module, right_module)
    strategies = [
        Strategy(:inactive, OperationalProfile(beliefs, [0]), empty_modules),
        Strategy(:left, OperationalProfile(beliefs, [0]), left_module),
        Strategy(:right, OperationalProfile(beliefs, [0]), right_module),
        Strategy(:bundle, OperationalProfile(beliefs, [0]), both_modules),
    ]
    catalog = StrategyCatalog(
        beliefs,
        modules,
        strategies,
        StrategyId(:inactive),
    )
    closure = identity_generative_closure(modules)
    source = RawLibrary(catalog, [row.id for row in strategies])
    weights = Dict(
        StrategyId(:inactive) => 0 // 1,
        StrategyId(:left) => 2 // 1,
        StrategyId(:right) => 2 // 1,
        StrategyId(:bundle) => 3 // 1,
    )
    return (; catalog, closure, source, weights)
end

@testset "JuMP/HiGHS exact safe-compression boundary" begin
    fixture = _weighted_cardinality_fixture()
    model = build_safe_compression_milp(
        fixture.catalog,
        fixture.closure,
        fixture.source;
        strategy_weights = fixture.weights,
        objective = :weight,
    )
    @test model.closure_kind == :identity
    @test model.frontier_constraint_count == 2
    @test model.closure_constraint_count == 2
    @test model.generator_count == 1
    @test model.generator_variable_count == 0
    @test model.generator_selection_constraint_count == 0
    @test model.objective_scale == 1
    @test model.scaled_objective == Int64[0, 1, 1, 3]

    weighted = solve_safe_compression_milp(
        fixture.catalog,
        fixture.closure,
        fixture.source;
        strategy_weights = fixture.weights,
        objective = :weight,
        enumerate_all_optima = true,
    )
    cardinality = solve_safe_compression_milp(
        fixture.catalog,
        fixture.closure,
        fixture.source;
        strategy_weights = fixture.weights,
        objective = :cardinality,
        enumerate_all_optima = true,
    )
    @test weighted.optimal_objective == 2 // 1
    @test only(weighted.optimal_libraries) ==
          _solver_library(fixture.catalog, :inactive, :left, :right)
    @test only(weighted.active_cardinalities) == 2
    @test only(weighted.burdens) == 2 // 1
    @test cardinality.optimal_objective == 1 // 1
    @test only(cardinality.optimal_libraries) ==
          _solver_library(fixture.catalog, :inactive, :bundle)
    @test only(cardinality.active_cardinalities) == 1
    @test only(cardinality.burdens) == 3 // 1
    @test weighted.exact_certificate.exact_optimality_verified
    @test cardinality.exact_certificate.exact_optimality_verified
    @test !weighted.exact_certificate.solver_tolerances_used_as_proof
    @test weighted.exact_certificate.every_selected_library_exactly_verified
    @test !weighted.exact_certificate.deletion_traces_included
    @test all(isnothing, weighted.deletion_traces)
    @test all(
        certificate.exact_certificate.frontier_preserved &&
        certificate.exact_certificate.closure_preserved for
        certificate in weighted.selected_library_certificates
    )

    tie_fixture = _multiple_optimum_fixture()
    ties = solve_safe_compression_milp(
        tie_fixture.catalog,
        tie_fixture.closure,
        tie_fixture.source;
        strategy_weights = tie_fixture.weights,
        objective = :weight,
        enumerate_all_optima = true,
    )
    expected_ties = Set([
        _solver_library(tie_fixture.catalog, :inactive, :first),
        _solver_library(tie_fixture.catalog, :inactive, :second),
    ])
    @test ties.optimal_objective == 1 // 1
    @test Set(ties.optimal_libraries) == expected_ties
    @test ties.solver_certificate.solver_exhausted_optimal_face
    @test ties.exact_certificate.complete_tie_set_exactly_verified
    @test ties.exact_certificate.exact_optimum_count == 2
end

@testset "general closure and fail-closed certification" begin
    derived_closure = GenerativeClosure(
        CORE_MODULES,
        module_set -> ModuleId(:signal) in module_set ?
                      union(module_set, RECIPE_MODULE) : module_set,
    )
    source = core_library(:inactive, :leader)
    weights = Dict(
        StrategyId(:inactive) => 0 // 1,
        StrategyId(:leader) => 3 // 2,
    )
    result = solve_safe_compression_milp(
        CORE_CATALOG,
        derived_closure,
        source;
        strategy_weights = weights,
        objective = :weight,
        enumerate_all_optima = true,
    )
    @test result.formulation.closure_kind == :general
    @test result.formulation.generator_count == 1
    @test result.formulation.closure_constraint_count == 1
    @test result.optimal_objective == 3 // 2
    @test only(result.closures) == union(SIGNAL_MODULE, RECIPE_MODULE)
    @test only(result.optimal_libraries) == source

    interchangeable_beliefs = FiniteBeliefSpace([:only])
    interchangeable_modules = [GenerativeModule(:a), GenerativeModule(:b)]
    interchangeable_universe = ModuleSet(interchangeable_modules)
    empty_modules = ModuleSet{Symbol}()
    module_a = ModuleSet([ModuleId(:a)])
    module_b = ModuleSet([ModuleId(:b)])
    interchangeable_strategies = [
        Strategy(
            :inactive,
            OperationalProfile(interchangeable_beliefs, [0]),
            empty_modules,
        ),
        Strategy(
            :carrier_a,
            OperationalProfile(interchangeable_beliefs, [0]),
            module_a,
        ),
        Strategy(
            :carrier_b,
            OperationalProfile(interchangeable_beliefs, [0]),
            module_b,
        ),
    ]
    interchangeable_catalog = StrategyCatalog(
        interchangeable_beliefs,
        interchangeable_modules,
        interchangeable_strategies,
        StrategyId(:inactive),
    )
    interchangeable_closure = GenerativeClosure(
        interchangeable_modules,
        module_set -> isempty(module_set) ? module_set : interchangeable_universe,
    )
    interchangeable_source = RawLibrary(
        interchangeable_catalog,
        [row.id for row in interchangeable_strategies],
    )
    interchangeable = solve_safe_compression_milp(
        interchangeable_catalog,
        interchangeable_closure,
        interchangeable_source;
        objective = :cardinality,
        enumerate_all_optima = true,
    )
    @test interchangeable.formulation.closure_kind == :general
    @test interchangeable.formulation.generator_count == 2
    @test interchangeable.formulation.generator_variable_count == 2
    @test interchangeable.formulation.generator_selection_constraint_count == 1
    @test interchangeable.formulation.closure_constraint_count == 2
    @test Set(interchangeable.optimal_libraries) == Set([
        _solver_library(interchangeable_catalog, :inactive, :carrier_a),
        _solver_library(interchangeable_catalog, :inactive, :carrier_b),
    ])
    @test interchangeable.exact_certificate.complete_tie_set_exactly_verified

    unsafe = core_library(:inactive)
    @test_throws ErrorException certify_safe_compression(
        CORE_CATALOG,
        derived_closure,
        source,
        unsafe;
        strategy_weights = weights,
        objective = :weight,
    )
    @test_throws ArgumentError build_safe_compression_milp(
        CORE_CATALOG,
        derived_closure,
        source;
        strategy_weights = Dict(
            StrategyId(:inactive) => 0.0,
            StrategyId(:leader) => 1.0,
        ),
        objective = :weight,
    )

    full = core_library(:inactive, :leader, :duplicate, :bridge)
    tiny = BigInt(1) // (BigInt(1) << 54)
    huge_scale_weights = Dict(
        StrategyId(:inactive) => 0 // 1,
        StrategyId(:leader) => 1 // 1,
        StrategyId(:duplicate) => tiny,
        StrategyId(:bridge) => 1 // 1,
    )
    @test_throws ArgumentError build_safe_compression_milp(
        CORE_CATALOG,
        CORE_CLOSURE,
        full;
        strategy_weights = huge_scale_weights,
        objective = :weight,
    )
end

@testset "order-dependent greedy weighted gap" begin
    fixture = _greedy_gap_fixture()
    optimum = solve_safe_compression_milp(
        fixture.catalog,
        fixture.closure,
        fixture.source;
        strategy_weights = fixture.weights,
        objective = :weight,
        enumerate_all_optima = true,
    )
    expensive_order = innovation_safe_prune_fixed_point(
        fixture.catalog,
        fixture.closure,
        fixture.source;
        deletion_order = StrategyId.([:bundle, :left, :right]),
    )
    optimal_order = innovation_safe_prune_fixed_point(
        fixture.catalog,
        fixture.closure,
        fixture.source;
        deletion_order = StrategyId.([:left, :right, :bundle]),
    )
    @test optimum.optimal_objective == 3 // 1
    @test only(optimum.optimal_libraries) ==
          _solver_library(fixture.catalog, :inactive, :bundle)
    @test _solver_burden(expensive_order, fixture.weights) == 4 // 1
    @test _solver_burden(optimal_order, fixture.weights) == 3 // 1
    @test compressed_state(fixture.catalog, fixture.closure, expensive_order) ==
          compressed_state(fixture.catalog, fixture.closure, fixture.source)
    @test compressed_state(fixture.catalog, fixture.closure, optimal_order) ==
          compressed_state(fixture.catalog, fixture.closure, fixture.source)
end

@testset "MILP agrees with independent exhaustive enumeration" begin
    for trial in 1:12
        fixture = compression_property_fixture(UInt64(40_000 + trial))
        weights = Dict(
            row.id => (index == 1 ? 0 // 1 : ((3 * index + trial) % 7 + 1) // 3)
            for (index, row) in enumerate(fixture.catalog.strategies)
        )
        expected = _enumerated_weight_optima(
            fixture.catalog,
            fixture.closure,
            fixture.source,
            weights,
        )
        result = solve_safe_compression_milp(
            fixture.catalog,
            fixture.closure,
            fixture.source;
            strategy_weights = weights,
            objective = :weight,
            enumerate_all_optima = true,
            include_deletion_trace = true,
        )
        formulation = minimum_safe_compression_ip_formulation(
            fixture.catalog,
            fixture.closure,
            fixture.source,
        )

        @test result.optimal_objective == expected.objective
        @test Set(result.optimal_libraries) == Set(expected.libraries)
        @test result.exact_certificate.complete_tie_set_exactly_verified
        @test all(
            satisfies_compression_formulation(
                formulation,
                Bool[strategy_id in library for strategy_id in formulation.strategy_ids],
            ) for library in result.optimal_libraries
        )
        @test all(
            compressed_state(fixture.catalog, fixture.closure, library) ==
            compressed_state(fixture.catalog, fixture.closure, fixture.source) for
            library in result.optimal_libraries
        )

        for trace in result.deletion_traces
            @test trace.all_steps_exact_safe
            trace_burdens = [
                _solver_burden(library, weights) for library in trace.libraries
            ]
            @test all(<(0), diff(trace_burdens))
        end

        cardinality = solve_safe_compression_milp(
            fixture.catalog,
            fixture.closure,
            fixture.source;
            objective = :cardinality,
        )
        enumerated_cardinality = minimum_safe_compression(
            fixture.catalog,
            fixture.closure,
            fixture.source,
        )
        @test cardinality.optimal_objective == length(enumerated_cardinality) - 1
        @test compressed_state(
            fixture.catalog,
            fixture.closure,
            only(cardinality.optimal_libraries),
        ) == compressed_state(
            fixture.catalog,
            fixture.closure,
            fixture.source,
        )
    end
end

@testset "deterministic solver-scaling probe" begin
    rows = run_safe_compression_scaling(
        sizes = ((12, 6), (24, 12));
        warmup = false,
        print_table = false,
    )
    @test [row.active_strategies for row in rows] == [12, 24]
    @test [row.beliefs for row in rows] == [6, 12]
    @test all(row.exact_safety_verified for row in rows)
    @test all(row.solver_claimed_optimal for row in rows)
    @test all(!row.exact_global_optimality_by_enumeration for row in rows)
    @test rows[1].binary_variables < rows[2].binary_variables
    @test rows[1].linear_constraints < rows[2].linear_constraints
end
