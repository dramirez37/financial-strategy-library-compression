const CORE_BELIEFS = FiniteBeliefSpace([:low, :high])
const CORE_MODULES = [GenerativeModule(:signal), GenerativeModule(:recipe)]
const EMPTY_MODULES = ModuleSet{Symbol}()
const SIGNAL_MODULE = ModuleSet([ModuleId(:signal)])
const RECIPE_MODULE = ModuleSet([ModuleId(:recipe)])

function core_strategy(id, values, modules = EMPTY_MODULES; mode = ExactMode())
    return Strategy(id, OperationalProfile(CORE_BELIEFS, values; mode), modules)
end

const CORE_STRATEGIES = [
    core_strategy(:inactive, [0, 0]),
    core_strategy(:leader, [2, 1], SIGNAL_MODULE),
    core_strategy(:duplicate, [1, 1], SIGNAL_MODULE),
    core_strategy(:bridge, [0, 0], RECIPE_MODULE),
]
const CORE_CATALOG = StrategyCatalog(
    CORE_BELIEFS,
    CORE_MODULES,
    CORE_STRATEGIES,
    StrategyId(:inactive),
)
const CORE_CLOSURE = identity_generative_closure(CORE_MODULES)

core_library(ids::Symbol...) =
    RawLibrary(CORE_CATALOG, StrategyId{Symbol}[StrategyId(id) for id in ids])

function all_core_libraries()
    optional = [:leader, :duplicate, :bridge]
    libraries = RawLibrary{Symbol}[]
    for mask in 0:(2^length(optional) - 1)
        ids = Symbol[:inactive]
        for (index, id) in enumerate(optional)
            iszero(mask & (1 << (index - 1))) || push!(ids, id)
        end
        push!(libraries, core_library(ids...))
    end
    return libraries
end

@testset "exact finite probability and belief core" begin
    @test exact_rational(3 // 4) isa ExactRational
    @test exact_rational("-6//8") == -3 // 4
    @test_throws ArgumentError exact_rational(0.5)
    @test_throws ArgumentError exact_rational("1//0")

    distribution = RatProb([:left, :right], [1 // 4, 3 // 4])
    reordered = RatProb([:right, :left, :zero], [3 // 4, 1 // 4, 0])
    @test distribution == reordered
    @test hash(distribution) == hash(reordered)
    @test probability(distribution, :missing) == 0
    @test expectation(distribution, outcome -> outcome == :left ? 2 : 4) == 7 // 2
    @test expectation(distribution, _ -> 3) ==
          expectation(distribution, outcome -> outcome == :left ? 3 : 3)
    @test expectation(dirac(:left), outcome -> outcome == :left ? 5 : 0) == 5
    @test_throws ArgumentError RatProb([:left, :right], [1 // 2, -1 // 2])
    @test_throws ArgumentError RatProb([:left, :right], [1 // 3, 1 // 3])
    @test_throws ArgumentError RatProb([:left, :left], [1 // 2, 1 // 2])

    exact_kernel = MarkovKernel(
        CORE_BELIEFS,
        [1//2 1//2; 1//4 3//4],
    )
    @test transition_probability(
        exact_kernel,
        Belief(:low),
        Belief(:high),
    ) == 1 // 2
    @test eltype(transition_row(exact_kernel, Belief(:low))) == ExactRational
    @test transition_distribution(exact_kernel, Belief(:high)) ==
          RatProb(collect(CORE_BELIEFS.states), [1 // 4, 3 // 4])

    float_kernel = MarkovKernel(
        CORE_BELIEFS,
        [0.5 0.5; 0.25 0.75];
        mode = Float64Mode(),
    )
    @test eltype(transition_row(float_kernel, Belief(:low))) == Float64
    @test_throws MethodError transition_distribution(float_kernel, Belief(:low))
    @test_throws ArgumentError MarkovKernel(CORE_BELIEFS, [0.5 0.5; 0.5 0.5])
    @test_throws ArgumentError MarkovKernel(CORE_BELIEFS, [1 0; -1 2])
    @test_throws ArgumentError MarkovKernel(CORE_BELIEFS, [1 1; 0 1])
    @test_throws ArgumentError discount_factor(-1 // 4)
    @test_throws ArgumentError discount_factor(1)
    @test discount_factor(3 // 4) == exact_rational(3 // 4)
    @test discount_factor(0.9; mode = Float64Mode()) === 0.9
    @test_throws ArgumentError FiniteBeliefSpace(Symbol[])
    @test_throws ArgumentError FiniteBeliefSpace([:low, :low])
end

@testset "catalog and reference validation" begin
    string_id_left = StrategyId(join(["strategy", "-id"]))
    string_id_right = StrategyId(String(copy(codeunits("strategy-id"))))
    @test string_id_left == string_id_right
    @test hash(string_id_left) == hash(string_id_right)
    @test_throws ArgumentError FiniteBeliefSpace([
        join(["belief", "-id"]),
        String(copy(codeunits("belief-id"))),
    ])

    @test operational_profile(CORE_CATALOG, StrategyId(:leader))[Belief(:low)] == 2
    @test strategy_modules(CORE_CATALOG, StrategyId(:leader)) == SIGNAL_MODULE
    @test_throws ArgumentError strategy(CORE_CATALOG, StrategyId(:missing))
    @test_throws ArgumentError core_library(:inactive, :missing)
    @test_throws ArgumentError RawLibrary(
        [StrategyId(:inactive), StrategyId(:inactive)],
        StrategyId(:inactive),
    )

    bad_module_strategy = core_strategy(
        :ghost_user,
        [0, 0],
        ModuleSet([ModuleId(:ghost)]),
    )
    @test_throws ArgumentError StrategyCatalog(
        CORE_BELIEFS,
        CORE_MODULES,
        [CORE_STRATEGIES; bad_module_strategy],
        StrategyId(:inactive),
    )
    @test_throws ArgumentError StrategyCatalog(
        CORE_BELIEFS,
        [GenerativeModule(:signal), GenerativeModule(:signal)],
        CORE_STRATEGIES,
        StrategyId(:inactive),
    )
    @test_throws ArgumentError StrategyCatalog(
        CORE_BELIEFS,
        CORE_MODULES,
        [CORE_STRATEGIES; CORE_STRATEGIES[2]],
        StrategyId(:inactive),
    )
    bad_inactive = [
        core_strategy(:inactive, [1, 0]),
        CORE_STRATEGIES[2:end]...,
    ]
    @test_throws ArgumentError StrategyCatalog(
        CORE_BELIEFS,
        CORE_MODULES,
        bad_inactive,
        StrategyId(:inactive),
    )

    projects = [ResearchProject(:probe, SIGNAL_MODULE)]
    @test validate_projects(CORE_CATALOG, projects) === projects
    @test_throws ArgumentError validate_projects(CORE_CATALOG, ResearchProject[])
    @test_throws ArgumentError validate_projects(
        CORE_CATALOG,
        [projects[1], projects[1]],
    )
    @test_throws ArgumentError validate_projects(
        CORE_CATALOG,
        [ResearchProject(:ghost, ModuleSet([ModuleId(:missing)]))],
    )
end

@testset "frontier and closure foundational properties" begin
    libraries = all_core_libraries()
    strategy_ids = [strategy_row.id for strategy_row in CORE_CATALOG.strategies]
    module_ids = [module_row.id for module_row in CORE_CATALOG.modules]

    # Lean: Library.ext (set equality, independent of enumeration order).
    reordered = core_library(:bridge, :inactive, :leader)
    canonical = core_library(:inactive, :leader, :bridge)
    @test reordered == canonical
    @test hash(reordered) == hash(canonical)

    for library in libraries
        current_frontier = frontier(CORE_CATALOG, library)
        raw_modules = module_union(CORE_CATALOG, library)
        closed_modules = generative_closure(CORE_CATALOG, CORE_CLOSURE, library)

        # Lean: operationalProfile_le_frontier, zero_le_operationalFrontier,
        # exists_profile_eq_operationalFrontier.
        for belief in CORE_BELIEFS
            @test current_frontier[belief] >= 0
            @test any(
                strategy_id ->
                    operational_profile(CORE_CATALOG, strategy_id)[belief] ==
                    current_frontier[belief],
                library,
            )
            for strategy_id in library
                @test operational_profile(CORE_CATALOG, strategy_id)[belief] <=
                      current_frontier[belief]
            end
        end

        # Lean: rawModuleUnion_subset_generativeClosure.
        @test issubset(raw_modules, closed_modules)

        # Lean: mem_rawModuleUnion.
        for module_id in module_ids
            @test (module_id in raw_modules) == any(
                strategy_id -> module_id in strategy_modules(CORE_CATALOG, strategy_id),
                library,
            )
        end

        # Lean: operationalFrontier_le_iff.
        for belief in CORE_BELIEFS, bound in ExactRational[-1, 0, 1, 3]
            @test (current_frontier[belief] <= bound) == all(
                strategy_id ->
                    operational_profile(CORE_CATALOG, strategy_id)[belief] <= bound,
                library,
            )
        end

        for strategy_id in strategy_ids
            inserted = insert_strategy(CORE_CATALOG, library, strategy_id)
            if operationally_dominated(CORE_CATALOG, library, strategy_id)
                # Lean: operationalFrontier_insert_of_operationallyRedundant.
                @test frontier(CORE_CATALOG, inserted) == current_frontier
            end
            if strategy_id != CORE_CATALOG.inactive_strategy
                erased = delete_strategy(CORE_CATALOG, library, strategy_id)
                if issubset(
                    strategy_modules(CORE_CATALOG, strategy_id),
                    generative_closure(CORE_CATALOG, CORE_CLOSURE, erased),
                )
                    # Lean: generativeClosure_erase_of_generativelyRedundant.
                    @test generative_closure(CORE_CATALOG, CORE_CLOSURE, erased) ==
                          closed_modules
                end

                # Lean: redundantDeletion_iff_compressedStatePreservingDeletion.
                state_preserved = compressed_state(
                    CORE_CATALOG,
                    CORE_CLOSURE,
                    erased,
                ) == compressed_state(CORE_CATALOG, CORE_CLOSURE, library)
                @test state_preserved == (
                    operationally_redundant(CORE_CATALOG, library, strategy_id) &&
                    generatively_redundant(
                        CORE_CATALOG,
                        CORE_CLOSURE,
                        library,
                        strategy_id,
                    )
                )
            end
        end
    end

    # Lean: operationalFrontier_mono, rawModuleUnion_mono,
    # generativeClosure_mono.
    for left in libraries, right in libraries
        if issubset(left, right)
            @test all(
                belief ->
                    frontier(CORE_CATALOG, left)[belief] <=
                    frontier(CORE_CATALOG, right)[belief],
                CORE_BELIEFS,
            )
            @test issubset(
                module_union(CORE_CATALOG, left),
                module_union(CORE_CATALOG, right),
            )
            @test issubset(
                generative_closure(CORE_CATALOG, CORE_CLOSURE, left),
                generative_closure(CORE_CATALOG, CORE_CLOSURE, right),
            )
        end
    end

    full = core_library(:inactive, :leader, :duplicate, :bridge)
    @test operationally_redundant(CORE_CATALOG, full, StrategyId(:duplicate))
    @test generatively_redundant(
        CORE_CATALOG,
        CORE_CLOSURE,
        full,
        StrategyId(:duplicate),
    )
    @test operationally_redundant(CORE_CATALOG, full, StrategyId(:bridge))
    @test !generatively_redundant(
        CORE_CATALOG,
        CORE_CLOSURE,
        full,
        StrategyId(:bridge),
    )
    @test !operationally_redundant(CORE_CATALOG, full, StrategyId(:leader))
    @test generatively_redundant(
        CORE_CATALOG,
        CORE_CLOSURE,
        full,
        StrategyId(:leader),
    )
    @test_throws ArgumentError delete_strategy(
        CORE_CATALOG,
        full,
        StrategyId(:inactive),
    )

    # Lean: compressed-state equality projects to frontier and closure.
    leader_only = core_library(:inactive, :leader)
    with_duplicate = core_library(:inactive, :leader, :duplicate)
    leader_state = compressed_state(CORE_CATALOG, CORE_CLOSURE, leader_only)
    duplicate_state = compressed_state(CORE_CATALOG, CORE_CLOSURE, with_duplicate)
    @test leader_state == duplicate_state
    @test leader_state.frontier == duplicate_state.frontier
    @test leader_state.closure == duplicate_state.closure

    @test_throws ArgumentError GenerativeClosure(CORE_MODULES, _ -> EMPTY_MODULES)
    nonidempotent = modules -> begin
        if isempty(modules)
            return SIGNAL_MODULE
        elseif modules == SIGNAL_MODULE
            return union(SIGNAL_MODULE, RECIPE_MODULE)
        end
        return modules
    end
    @test_throws ArgumentError GenerativeClosure(CORE_MODULES, nonidempotent)

    three_modules = [
        GenerativeModule(:a),
        GenerativeModule(:b),
        GenerativeModule(:c),
    ]
    only_a = ModuleSet([ModuleId(:a)])
    a_and_c = ModuleSet([ModuleId(:a), ModuleId(:c)])
    nonmonotone = modules -> modules == only_a ? a_and_c : modules
    @test_throws ArgumentError GenerativeClosure(three_modules, nonmonotone)
end

@testset "exact dynamic innovation equivalence" begin
    belief_kernel = MarkovKernel(CORE_BELIEFS, [1 0; 0 1])
    projects = [ResearchProject(:probe, EMPTY_MODULES)]
    revealing = FiniteResearchSemantics(
        CORE_CATALOG,
        belief_kernel,
        projects,
        (belief, state, project) -> dirac(state),
        1 // 2,
    )
    inactive = core_library(:inactive)
    bridge = core_library(:inactive, :bridge)
    leader = core_library(:inactive, :leader)
    duplicate = core_library(:inactive, :leader, :duplicate)

    @test dynamic_innovation_equivalent(
        revealing,
        CORE_CATALOG,
        CORE_CLOSURE,
        leader,
        duplicate,
    )
    @test !dynamic_innovation_equivalent(
        revealing,
        CORE_CATALOG,
        CORE_CLOSURE,
        inactive,
        bridge,
    )

    fixed_state = compressed_state(CORE_CATALOG, CORE_CLOSURE, inactive)
    silent = FiniteResearchSemantics(
        CORE_CATALOG,
        belief_kernel,
        projects,
        (belief, state, project) -> dirac(fixed_state),
        0,
    )
    @test dynamic_innovation_equivalent(
        silent,
        CORE_CATALOG,
        CORE_CLOSURE,
        inactive,
        bridge,
    )

    # Lean: DI reflexivity, symmetry, and transitivity.
    libraries = all_core_libraries()
    relation(left, right) = dynamic_innovation_equivalent(
        revealing,
        CORE_CATALOG,
        CORE_CLOSURE,
        left,
        right,
    )
    @test all(library -> relation(library, library), libraries)
    @test all(
        relation(left, right) == relation(right, left)
        for left in libraries for right in libraries
    )
    @test all(
        !(relation(first_library, second_library) &&
          relation(second_library, third_library)) ||
        relation(first_library, third_library)
        for first_library in libraries for second_library in libraries for
        third_library in libraries
    )

    unresolved_project = ResearchProject(:missing, EMPTY_MODULES)
    state = compressed_state(CORE_CATALOG, CORE_CLOSURE, inactive)
    @test research_distribution(
        revealing,
        Belief(:low),
        state,
        ResearchProject(:probe, EMPTY_MODULES),
    ) == dirac(state)
    @test_throws ArgumentError research_distribution(
        revealing,
        Belief(:low),
        state,
        unresolved_project,
    )
    @test_throws ArgumentError FiniteResearchSemantics(
        CORE_CATALOG,
        belief_kernel,
        [projects[1], projects[1]],
        (belief, state, project) -> dirac(state),
        1 // 2,
    )
end

@testset "exact fixture IO" begin
    matrix = ExactRational[1//2 1//3; -5//7 9//1]
    buffer = IOBuffer()
    write_exact_matrix(buffer, matrix)
    seekstart(buffer)
    @test read_exact_matrix(buffer) == matrix
    @test encode_exact_rational(-6 // 8) == "-3//4"
    @test_throws ArgumentError read_exact_matrix(IOBuffer(""))
    @test_throws DimensionMismatch read_exact_matrix(IOBuffer("1//1\n1//2\t1//2\n"))
end

@testset "Float64 simulation mode is explicit" begin
    float_profiles = [
        core_strategy(:inactive, [0.0, 0.0], EMPTY_MODULES; mode = Float64Mode()),
        core_strategy(:leader, [2.0, 1.0], SIGNAL_MODULE; mode = Float64Mode()),
    ]
    float_catalog = StrategyCatalog(
        CORE_BELIEFS,
        CORE_MODULES,
        float_profiles,
        StrategyId(:inactive),
    )
    float_library = RawLibrary(
        float_catalog,
        [StrategyId(:inactive), StrategyId(:leader)],
    )
    @test frontier(float_catalog, float_library).values isa Tuple{Vararg{Float64}}
    @test_throws MethodError FiniteResearchSemantics(
        float_catalog,
        MarkovKernel(CORE_BELIEFS, [0.5 0.5; 0.0 1.0]; mode = Float64Mode()),
        [ResearchProject(:probe, EMPTY_MODULES)],
        (belief, state, project) -> dirac(state),
        0.5,
    )
end
