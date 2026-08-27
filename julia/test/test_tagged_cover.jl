function tagged_test_library(catalog, strategy_ids::Symbol...)
    return RawLibrary(catalog, StrategyId.(collect(strategy_ids)))
end

function tagged_module_set(module_ids::Symbol...)
    return ModuleSet(ModuleId{Symbol}[ModuleId(module_id) for module_id in module_ids])
end

@testset "identity-closure tagged-cover representation" begin
    beliefs = FiniteBeliefSpace([:shared, :zero])
    modules = [GenerativeModule(:shared), GenerativeModule(:other)]
    strategies = [
        Strategy(
            :inactive,
            OperationalProfile(beliefs, [0, 0]),
            tagged_module_set(),
        ),
        Strategy(
            :alpha,
            OperationalProfile(beliefs, [2, 0]),
            tagged_module_set(:shared),
        ),
        Strategy(
            :beta,
            OperationalProfile(beliefs, [2, -1]),
            tagged_module_set(:shared, :other),
        ),
        Strategy(
            :gamma,
            OperationalProfile(beliefs, [1, 0]),
            tagged_module_set(:other),
        ),
    ]
    catalog = StrategyCatalog(
        beliefs,
        modules,
        strategies,
        StrategyId(:inactive),
    )
    closure = identity_generative_closure(modules)
    source = tagged_test_library(catalog, :inactive, :alpha, :beta, :gamma)
    weights = Dict(
        StrategyId(:inactive) => 0,
        StrategyId(:alpha) => 3 // 2,
        StrategyId(:beta) => 7 // 3,
        StrategyId(:gamma) => 5 // 4,
    )
    representation = tagged_cover_representation(
        catalog,
        closure,
        source;
        strategy_weights = weights,
    )

    @test representation.strategy_ids == Tuple(
        StrategyId.(collect((:inactive, :alpha, :beta, :gamma))),
    )
    @test representation.requirements == (
        FrontierRequirement(Belief(:shared)),
        FrontierRequirement(Belief(:zero)),
        ModuleRequirement(ModuleId(:shared)),
        ModuleRequirement(ModuleId(:other)),
    )
    @test FrontierRequirement(Belief(:shared)) !=
          ModuleRequirement(ModuleId(:shared))
    @test representation.coverage == Bool[
        0 1 1 0
        1 1 0 1
        0 1 1 0
        0 0 1 1
    ]

    # Alpha and beta tie at :shared; either attainer can cover that row.
    @test FrontierRequirement(Belief(:shared)) in
          strategy_tagged_coverage(representation, StrategyId(:alpha))
    @test FrontierRequirement(Belief(:shared)) in
          strategy_tagged_coverage(representation, StrategyId(:beta))

    # The zero-frontier row is retained and automatically covered by inactive.
    @test FrontierRequirement(Belief(:zero)) in
          strategy_tagged_coverage(representation, StrategyId(:inactive))

    # Both source modules have multiple raw carriers.
    @test ModuleRequirement(ModuleId(:shared)) in
          strategy_tagged_coverage(representation, StrategyId(:alpha))
    @test ModuleRequirement(ModuleId(:shared)) in
          strategy_tagged_coverage(representation, StrategyId(:beta))
    @test ModuleRequirement(ModuleId(:other)) in
          strategy_tagged_coverage(representation, StrategyId(:beta))
    @test ModuleRequirement(ModuleId(:other)) in
          strategy_tagged_coverage(representation, StrategyId(:gamma))

    candidate = tagged_test_library(catalog, :inactive, :alpha, :gamma)
    selected = Bool[true, true, false, true]
    @test tagged_cover_feasible(representation, candidate)
    @test tagged_cover_feasible(representation, selected)
    @test tagged_cover_burden(representation, candidate) == 11 // 4
    @test tagged_cover_burden(representation, selected) == 11 // 4
    @test tagged_cover_certificate(representation, candidate) == (
        sublibrary = true,
        inactive_retained = true,
        frontier_preserved = true,
        closure_preserved = true,
        exact_safe_feasible = true,
        tagged_cover_feasible = true,
        equivalence_holds = true,
        exact_burden = 11 // 4,
    )

    formulation = tagged_binary_cover_formulation(representation)
    @test formulation.inactive_index == 1
    @test formulation.inactive_fixed_value
    @test formulation.row_lower_bounds == (1, 1, 1, 1)
    @test formulation.weights == (0 // 1, 3 // 2, 7 // 3, 5 // 4)
    @test formulation.incidence == representation.coverage

    @test !tagged_cover_feasible(
        representation,
        Bool[false, true, true, true],
    )
end

@testset "exhaustive exact small-library equivalence" begin
    beliefs = FiniteBeliefSpace([:b1, :b2])
    modules = [GenerativeModule(:m1), GenerativeModule(:m2)]
    closure = identity_generative_closure(modules)
    profile_options = collect(Iterators.product((-1, 0, 1), (-1, 0, 1)))
    module_masks = 0:3
    catalogs_checked = 0
    sublibraries_checked = 0

    for first_profile in profile_options,
        second_profile in profile_options,
        first_mask in module_masks,
        second_mask in module_masks
        first_modules = tagged_module_set(
            (module_id for (index, module_id) in enumerate((:m1, :m2)) if
             !iszero(first_mask & (1 << (index - 1))))...,
        )
        second_modules = tagged_module_set(
            (module_id for (index, module_id) in enumerate((:m1, :m2)) if
             !iszero(second_mask & (1 << (index - 1))))...,
        )
        strategies = [
            Strategy(
                :inactive,
                OperationalProfile(beliefs, [0, 0]),
                tagged_module_set(),
            ),
            Strategy(
                :s1,
                OperationalProfile(beliefs, collect(first_profile)),
                first_modules,
            ),
            Strategy(
                :s2,
                OperationalProfile(beliefs, collect(second_profile)),
                second_modules,
            ),
        ]
        catalog = StrategyCatalog(
            beliefs,
            modules,
            strategies,
            StrategyId(:inactive),
        )
        source = tagged_test_library(catalog, :inactive, :s1, :s2)
        representation = tagged_cover_representation(catalog, closure, source)

        for mask in 0:3
            selected_active = Symbol[
                strategy_id for (index, strategy_id) in enumerate((:s1, :s2)) if
                !iszero(mask & (1 << (index - 1)))
            ]
            candidate = tagged_test_library(
                catalog,
                :inactive,
                selected_active...,
            )
            exact_feasible =
                compressed_state(catalog, closure, candidate) ==
                compressed_state(catalog, closure, source)
            cover_feasible = tagged_cover_feasible(representation, candidate)
            @test exact_feasible == cover_feasible
            @test tagged_cover_certificate(representation, candidate).equivalence_holds
            sublibraries_checked += 1
        end
        catalogs_checked += 1
    end

    @test catalogs_checked == 1_296
    @test sublibraries_checked == 5_184
end

@testset "exact boundary counterexamples" begin
    one_belief = FiniteBeliefSpace([:only])
    one_module = [GenerativeModule(:m)]
    identity_closure = identity_generative_closure(one_module)

    # Frontier rows alone accept the inactive-only candidate but it loses m.
    frontier_only_catalog = StrategyCatalog(
        one_belief,
        one_module,
        [
            Strategy(
                :inactive,
                OperationalProfile(one_belief, [0]),
                tagged_module_set(),
            ),
            Strategy(
                :carrier,
                OperationalProfile(one_belief, [0]),
                tagged_module_set(:m),
            ),
        ],
        StrategyId(:inactive),
    )
    frontier_only_source =
        tagged_test_library(frontier_only_catalog, :inactive, :carrier)
    inactive_only = tagged_test_library(frontier_only_catalog, :inactive)
    @test frontier(frontier_only_catalog, inactive_only) ==
          frontier(frontier_only_catalog, frontier_only_source)
    @test generative_closure(
        frontier_only_catalog,
        identity_closure,
        inactive_only,
    ) != generative_closure(
        frontier_only_catalog,
        identity_closure,
        frontier_only_source,
    )
    @test !tagged_cover_feasible(
        tagged_cover_representation(
            frontier_only_catalog,
            identity_closure,
            frontier_only_source,
        ),
        inactive_only,
    )

    # Module rows alone are vacuous but the inactive-only candidate loses profit.
    module_only_catalog = StrategyCatalog(
        one_belief,
        one_module,
        [
            Strategy(
                :inactive,
                OperationalProfile(one_belief, [0]),
                tagged_module_set(),
            ),
            Strategy(
                :leader,
                OperationalProfile(one_belief, [1]),
                tagged_module_set(),
            ),
        ],
        StrategyId(:inactive),
    )
    module_only_source =
        tagged_test_library(module_only_catalog, :inactive, :leader)
    inactive_only = tagged_test_library(module_only_catalog, :inactive)
    @test generative_closure(
        module_only_catalog,
        identity_closure,
        inactive_only,
    ) == generative_closure(
        module_only_catalog,
        identity_closure,
        module_only_source,
    )
    @test frontier(module_only_catalog, inactive_only) !=
          frontier(module_only_catalog, module_only_source)
    @test !tagged_cover_feasible(
        tagged_cover_representation(
            module_only_catalog,
            identity_closure,
            module_only_source,
        ),
        inactive_only,
    )

    # Under complementary closure, raw-carrier rows for every closed module
    # reject even the source: c is generated by retaining both a and b.
    complement_modules = GenerativeModule.(collect((:a, :b, :c)))
    universe = ModuleSet(complement_modules)
    complement_closure = GenerativeClosure(
        complement_modules,
        raw_modules -> begin
            has_pair =
                ModuleId(:a) in raw_modules && ModuleId(:b) in raw_modules
            return has_pair ? universe : raw_modules
        end,
    )
    complement_catalog = StrategyCatalog(
        one_belief,
        complement_modules,
        [
            Strategy(
                :inactive,
                OperationalProfile(one_belief, [0]),
                tagged_module_set(),
            ),
            Strategy(
                :a_carrier,
                OperationalProfile(one_belief, [0]),
                tagged_module_set(:a),
            ),
            Strategy(
                :b_carrier,
                OperationalProfile(one_belief, [0]),
                tagged_module_set(:b),
            ),
            Strategy(
                :c_carrier,
                OperationalProfile(one_belief, [0]),
                tagged_module_set(:c),
            ),
        ],
        StrategyId(:inactive),
    )
    complement_source = tagged_test_library(
        complement_catalog,
        :inactive,
        :a_carrier,
        :b_carrier,
    )
    source_closure = generative_closure(
        complement_catalog,
        complement_closure,
        complement_source,
    )
    @test source_closure == universe
    @test compressed_state(
        complement_catalog,
        complement_closure,
        complement_source,
    ) == compressed_state(
        complement_catalog,
        complement_closure,
        complement_source,
    )
    @test !any(
        ModuleId(:c) in strategy_modules(complement_catalog, strategy_id) for
        strategy_id in complement_source
    )
    @test_throws ArgumentError tagged_cover_representation(
        complement_catalog,
        complement_closure,
        complement_source,
    )
end

@testset "machine-readable tagged-cover theorem fixture" begin
    fixture = build_tagged_cover_theorem_fixture()
    @test fixture["schema_version"] == "tagged-cover-equivalence-v1"
    @test fixture["arithmetic"] == "Rational{BigInt}"
    @test fixture["evidence_class"] ==
          "exact finite computation; not a universal mathematical proof or solver certificate"
    @test fixture["exhaustive_small_library_audit"]["catalogs_checked"] == 1_296
    @test fixture["exhaustive_small_library_audit"]["sublibraries_checked"] ==
          5_184
    @test fixture["exhaustive_small_library_audit"]["mismatch_count"] == 0
    @test fixture["gates"]["all_gates_pass"]
    @test write_tagged_cover_theorem_fixture(; check = true).fixture == fixture
end
