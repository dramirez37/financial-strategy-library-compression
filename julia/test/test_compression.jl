function compression_property_fixture(seed::UInt64)
    rng = research_rng(seed)
    belief_count = rand(rng, 1:3)
    module_count = rand(rng, 1:3)
    optional_count = rand(rng, 2:6)
    beliefs = FiniteBeliefSpace([Symbol("b$index") for index in 1:belief_count])
    modules = [GenerativeModule(Symbol("m$index")) for index in 1:module_count]
    empty_modules = ModuleSet{Symbol}()
    strategies = Strategy[
        Strategy(:inactive, OperationalProfile(beliefs, zeros(Int, belief_count)), empty_modules),
    ]
    for strategy_index in 1:optional_count
        profile = [rand(rng, -2:3) // 1 for _ in 1:belief_count]
        supplied = ModuleId{Symbol}[
            module_row.id for module_row in modules if rand(rng, Bool)
        ]
        push!(
            strategies,
            Strategy(
                Symbol("s$strategy_index"),
                OperationalProfile(beliefs, profile),
                ModuleSet(supplied),
            ),
        )
    end
    typed_strategies = typeof(first(strategies))[strategy_row for strategy_row in strategies]
    catalog = StrategyCatalog(
        beliefs,
        modules,
        typed_strategies,
        StrategyId(:inactive),
    )
    closure = identity_generative_closure(modules)
    source = RawLibrary(catalog, [row.id for row in typed_strategies])
    project = ResearchProject(:self_loop, empty_modules)
    identity_kernel = [
        row == column ? 1 : 0 for row in 1:belief_count, column in 1:belief_count
    ]
    semantics = FiniteResearchSemantics(
        catalog,
        MarkovKernel(beliefs, identity_kernel),
        [project],
        (belief, state, current_project) -> dirac(state),
        1 // 2,
    )
    value_oracle = CompressionExperiments.exact_finite_horizon_value_oracle(
        semantics,
        catalog,
        closure,
    )
    return (; beliefs, catalog, closure, source, semantics, value_oracle)
end

@testset "innovation-safe single and fixed-point deletion" begin
    full = core_library(:inactive, :leader, :duplicate, :bridge)
    before = compressed_state(CORE_CATALOG, CORE_CLOSURE, full)
    after = innovation_safe_delete(
        CORE_CATALOG,
        CORE_CLOSURE,
        full,
        StrategyId(:duplicate),
    )

    # Lean F3: redundantDeletion_iff_compressedStatePreservingDeletion.
    @test after == core_library(:inactive, :leader, :bridge)
    @test compressed_state(CORE_CATALOG, CORE_CLOSURE, after) == before
    @test frontier(CORE_CATALOG, after) == frontier(CORE_CATALOG, full)
    @test generative_closure(CORE_CATALOG, CORE_CLOSURE, after) ==
          generative_closure(CORE_CATALOG, CORE_CLOSURE, full)

    @test_throws ArgumentError innovation_safe_delete(
        CORE_CATALOG,
        CORE_CLOSURE,
        full,
        StrategyId(:bridge),
    )
    @test_throws ArgumentError innovation_safe_delete(
        CORE_CATALOG,
        CORE_CLOSURE,
        full,
        StrategyId(:inactive),
    )
    @test_throws ArgumentError innovation_safe_delete(
        CORE_CATALOG,
        CORE_CLOSURE,
        core_library(:inactive),
        StrategyId(:duplicate),
    )

    fixed_point = innovation_safe_prune_fixed_point(
        CORE_CATALOG,
        CORE_CLOSURE,
        full,
    )
    @test fixed_point == core_library(:inactive, :leader, :bridge)
    @test compressed_state(CORE_CATALOG, CORE_CLOSURE, fixed_point) == before
    @test all(
        strategy_id == CORE_CATALOG.inactive_strategy ||
        !(operationally_redundant(CORE_CATALOG, fixed_point, strategy_id) &&
          generatively_redundant(
              CORE_CATALOG,
              CORE_CLOSURE,
              fixed_point,
              strategy_id,
          )) for strategy_id in fixed_point
    )

    @test_throws ArgumentError innovation_safe_prune_fixed_point(
        CORE_CATALOG,
        CORE_CLOSURE,
        full;
        deletion_order = [StrategyId(:missing)],
    )
    @test_throws ArgumentError frontier_only_prune(
        CORE_CATALOG,
        full;
        deletion_order = [StrategyId(:bridge), StrategyId(:bridge)],
    )
    mismatched_closure = identity_generative_closure([GenerativeModule(:other)])
    @test_throws ArgumentError innovation_safe_prune_fixed_point(
        CORE_CATALOG,
        mismatched_closure,
        full,
    )
end

@testset "stepwise deletion rejects the batch inference" begin
    beliefs = FiniteBeliefSpace([:only])
    modules = [GenerativeModule(:key)]
    empty_modules = ModuleSet{Symbol}()
    key = ModuleSet([ModuleId(:key)])
    strategies = [
        Strategy(:inactive, OperationalProfile(beliefs, [0]), empty_modules),
        Strategy(:first, OperationalProfile(beliefs, [-1]), key),
        Strategy(:second, OperationalProfile(beliefs, [-1]), key),
    ]
    catalog = StrategyCatalog(beliefs, modules, strategies, StrategyId(:inactive))
    closure = identity_generative_closure(modules)
    source = RawLibrary(catalog, [row.id for row in strategies])

    @test operationally_redundant(catalog, source, StrategyId(:first))
    @test generatively_redundant(catalog, closure, source, StrategyId(:first))
    @test operationally_redundant(catalog, source, StrategyId(:second))
    @test generatively_redundant(catalog, closure, source, StrategyId(:second))

    result = innovation_safe_prune_fixed_point(catalog, closure, source)
    @test length(result) == 2
    @test compressed_state(catalog, closure, result) ==
          compressed_state(catalog, closure, source)
    @test_throws ArgumentError innovation_safe_delete(
        catalog,
        closure,
        result,
        only(strategy_id for strategy_id in result if strategy_id != catalog.inactive_strategy),
    )
end

@testset "frontier-only pruning reproduces Lean F4 exact loss" begin
    for target in (0, 1, 5, 13)
        fixture = CompressionExperiments.exact_frontier_loss_fixture(target)
        pruned = frontier_only_prune(fixture.catalog, fixture.unpruned)
        only_belief = only(fixture.beliefs.states)

        # Lean F4: frontierOnlyPrune_eq_pruned and current_frontiers_equal.
        @test pruned == fixture.pruned
        @test frontier(fixture.catalog, fixture.unpruned) ==
              frontier(fixture.catalog, pruned)
        @test generative_closure(fixture.catalog, fixture.closure, fixture.unpruned) ==
              ModuleSet([ModuleId(:key)])
        @test isempty(generative_closure(fixture.catalog, fixture.closure, pruned))
        @test !generatively_redundant(
            fixture.catalog,
            fixture.closure,
            fixture.unpruned,
            StrategyId(:dominated),
        )

        # Lean F4: pruned_value_two_eq_zero,
        # unpruned_value_two_eq_half_reward, and
        # frontierPruningLoss_scaledTarget_exact.
        @test fixture.value_oracle(2, only_belief, pruned) == 0
        @test fixture.value_oracle(2, only_belief, fixture.unpruned) ==
              fixture.reward / 2
        @test fixture.value_oracle(2, only_belief, fixture.unpruned) -
              fixture.value_oracle(2, only_belief, pruned) == fixture.target

        report = verify_compressed_equivalence(
            fixture.catalog,
            fixture.closure,
            fixture.unpruned,
            pruned;
            semantics = fixture.semantics,
            value_oracle = fixture.value_oracle,
            horizons = 0:2,
        )
        @test report.sublibrary
        @test report.frontier_preserved
        @test !report.generative_closure_preserved
        @test !report.compressed_state_preserved
        @test report.dynamic_innovation_preserved == iszero(target)
        @test report.dynamic_value_preserved == iszero(target)
        @test report.value_comparisons == 3
        @test report.compression_ratio == 1 // 2

        safely_pruned = innovation_safe_prune_fixed_point(
            fixture.catalog,
            fixture.closure,
            fixture.unpruned,
        )
        @test safely_pruned == fixture.unpruned
    end
end

@testset "minimum compression, safe greedy, and exact 0-1 formulation" begin
    source = core_library(:inactive, :leader, :duplicate, :bridge)
    exact_minimum = minimum_safe_compression(CORE_CATALOG, CORE_CLOSURE, source)
    greedy = innovation_safe_prune_fixed_point(CORE_CATALOG, CORE_CLOSURE, source)
    @test length(exact_minimum) == 3
    @test length(greedy) == length(exact_minimum)
    @test compressed_state(CORE_CATALOG, CORE_CLOSURE, exact_minimum) ==
          compressed_state(CORE_CATALOG, CORE_CLOSURE, source)

    formulation = minimum_safe_compression_ip_formulation(
        CORE_CATALOG,
        CORE_CLOSURE,
        source,
    )
    @test formulation.objective == (1, 1, 1, 1)
    @test formulation.strategy_ids[formulation.inactive_index] == StrategyId(:inactive)
    @test size(formulation.frontier_cover) == (2, 4)
    @test size(formulation.module_supply) == (2, 4)
    @test_throws DimensionMismatch satisfies_compression_formulation(
        formulation,
        Bool[true],
    )

    for mask in 0:15
        isodd(mask) || continue
        selected = [!iszero(mask & (1 << (index - 1))) for index in 1:4]
        ids = StrategyId{Symbol}[
            formulation.strategy_ids[index] for index in 1:4 if selected[index]
        ]
        candidate = RawLibrary(CORE_CATALOG, ids)
        expected = compressed_state(CORE_CATALOG, CORE_CLOSURE, candidate) ==
                   compressed_state(CORE_CATALOG, CORE_CLOSURE, source)
        @test satisfies_compression_formulation(formulation, selected) == expected
    end

    derived_closure = GenerativeClosure(
        CORE_MODULES,
        module_set -> ModuleId(:signal) in module_set ?
                      union(module_set, RECIPE_MODULE) : module_set,
    )
    derived_source = core_library(:inactive, :leader)
    derived_formulation = minimum_safe_compression_ip_formulation(
        CORE_CATALOG,
        derived_closure,
        derived_source,
    )
    @test derived_formulation.closure_generators == (SIGNAL_MODULE,)
    @test satisfies_compression_formulation(derived_formulation, [true, true])
    @test !satisfies_compression_formulation(derived_formulation, [true, false])

    @test_throws ArgumentError minimum_safe_compression(
        CORE_CATALOG,
        CORE_CLOSURE,
        source;
        max_optional = 2,
    )
    @test_throws ArgumentError minimum_safe_compression(
        CORE_CATALOG,
        CORE_CLOSURE,
        source;
        max_optional = -1,
    )
end

@testset "deterministic random small-library properties" begin
    for trial in 1:40
        fixture = compression_property_fixture(UInt64(0x5000 + trial))
        safe = innovation_safe_prune_fixed_point(
            fixture.catalog,
            fixture.closure,
            fixture.source,
        )
        minimum = minimum_safe_compression(
            fixture.catalog,
            fixture.closure,
            fixture.source,
        )
        frontier_pruned = frontier_only_prune(fixture.catalog, fixture.source)

        safe_report = verify_compressed_equivalence(
            fixture.catalog,
            fixture.closure,
            fixture.source,
            safe;
            semantics = fixture.semantics,
            value_oracle = fixture.value_oracle,
            horizons = 0:3,
        )
        @test safe_report.sublibrary
        @test safe_report.frontier_preserved
        @test safe_report.generative_closure_preserved
        @test safe_report.compressed_state_preserved
        @test safe_report.dynamic_innovation_preserved
        @test safe_report.dynamic_value_preserved
        @test safe_report.compression_ratio >= 0
        @test length(minimum) <= length(safe)
        @test compressed_state(fixture.catalog, fixture.closure, minimum) ==
              compressed_state(fixture.catalog, fixture.closure, fixture.source)
        @test frontier(fixture.catalog, frontier_pruned) ==
              frontier(fixture.catalog, fixture.source)

        formulation = minimum_safe_compression_ip_formulation(
            fixture.catalog,
            fixture.closure,
            fixture.source,
        )
        column_count = length(formulation.strategy_ids)
        for mask in UInt64(0):((UInt64(1) << column_count) - UInt64(1))
            selected = [
                !iszero(mask & (UInt64(1) << (index - 1))) for
                index in 1:column_count
            ]
            selected[formulation.inactive_index] || continue
            ids = StrategyId{Symbol}[
                formulation.strategy_ids[index] for index in 1:column_count if
                selected[index]
            ]
            candidate = RawLibrary(fixture.catalog, ids)
            expected =
                compressed_state(fixture.catalog, fixture.closure, candidate) ==
                compressed_state(fixture.catalog, fixture.closure, fixture.source)
            @test satisfies_compression_formulation(formulation, selected) == expected
        end
    end
end

@testset "compression experiment outputs" begin
    rows = CompressionExperiments.run_compression_experiments(
        scaling_sizes = (8,),
    )
    @test length(rows) == 5
    f4_row = only(
        row for row in rows if
        row.experiment_id == "lean-f4-scaled-loss" &&
        row.algorithm == "frontier_only_prune"
    )
    @test f4_row.frontier_preserved
    @test !f4_row.generative_closure_preserved
    @test !f4_row.dynamic_value_preserved
    @test f4_row.dynamic_value_loss == 5
    @test f4_row.frontier_only_failure

    mktempdir() do directory
        json_path = joinpath(directory, "compression.json")
        csv_path = joinpath(directory, "compression.csv")
        CompressionExperiments.write_compression_json(json_path, rows)
        CompressionExperiments.write_compression_csv(csv_path, rows)
        json_text = read(json_path, String)
        csv_text = read(csv_path, String)
        @test occursin("innovation-safe-compression-v1", json_text)
        @test occursin("lean-f4-scaled-loss", json_text)
        @test startswith(csv_text, "experiment_id,arithmetic,algorithm,")
        @test length(readlines(csv_path)) == length(rows) + 1
    end
end

include(joinpath(@__DIR__, "..", "scripts", "run_safe_compression_scaling.jl"))
using .SafeCompressionScaling
include("test_safe_compression_solver.jl")
