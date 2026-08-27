using .SafeDeletionGapFamilyFixture.ResourceOptimization

function _gap_permutations(values::Vector{Int})
    isempty(values) && return [Int[]]
    rows = Vector{Vector{Int}}()
    for (index, value) in enumerate(values)
        remainder = [values[1:(index - 1)]; values[(index + 1):end]]
        for tail in _gap_permutations(remainder)
            push!(rows, [value; tail])
        end
    end
    return rows
end

@testset "parameterized exact safe-deletion gap family" begin
    family = safe_deletion_gap_family(61, 1 // 2)
    @test family.k == 61
    @test length(family.strategy_ids) == 62
    @test family.weights[end] == 3 // 2
    @test family.module_masks[end] == family.module_universe_mask

    @test_throws ArgumentError safe_deletion_gap_family(1, 1 // 2)
    @test_throws ArgumentError safe_deletion_gap_family(62, 1 // 2)
    @test_throws ArgumentError safe_deletion_gap_family(2, 0)
    @test_throws ArgumentError safe_deletion_gap_family(2, 1)
    @test_throws ArgumentError safe_deletion_gap_family(2, 0.5)
    @test_throws ArgumentError safe_deletion_gap_problem(19, 1 // 2)
end

@testset "exact family claims over an exhaustive small grid" begin
    epsilon_grid = ExactRational[1 // 5, 1 // 3, 1 // 2, 3 // 4]
    instance_count = 0
    candidate_masks_checked = 0

    for k in 2:7, epsilon in epsilon_grid
        instance_count += 1
        family = safe_deletion_gap_problem(k, epsilon)
        problem = family.problem
        source = family.source_mask
        all_masks = collect(library_masks(problem))
        candidate_masks_checked += length(all_masks)

        @test library_frontier(problem, source) == ExactRational[0]
        @test library_module_mask(problem, source) == family.module_universe_mask
        @test all(
            safely_deletable(problem, source, index) for
            index in 1:active_strategy_count(problem)
        )

        safe_indices = Int[
            index for index in 1:active_strategy_count(problem) if
            safely_deletable(problem, source, index)
        ]
        maximum_safe_weight = maximum(problem.weights[safe_indices])
        @test Int[
            index for index in safe_indices if
            problem.weights[index] == maximum_safe_weight
        ] == [family.bundle_index]

        trace = heaviest_safe_first_trace(problem, source)
        @test trace.selection_rule == :maximum_weight_then_lowest_strategy_index
        @test trace.every_deletion_rechecked
        @test trace.deletions == [family.bundle_index]
        @test trace.endpoint == family.singleton_library_mask
        @test inclusion_irreducible(problem, trace.endpoint)
        @test library_weight(problem, trace.endpoint) == k

        optimum = minimum_weight_safe_compression(problem, source)
        @test optimum.optimal_objective == 1 + epsilon
        @test [library.mask for library in optimum.optimal_libraries] ==
              [family.bundle_mask]
        @test library_weight(problem, trace.endpoint) /
              optimum.optimal_objective == k / (1 + epsilon)

        safe_masks = safe_sublibraries(problem, source)
        @test length(safe_masks) == (1 << k) + 1
        @test all(
            mask ->
                safe_feasible(problem, source, mask) ==
                (
                    library_frontier(problem, mask) ==
                    library_frontier(problem, source) &&
                    library_module_mask(problem, mask) ==
                    library_module_mask(problem, source)
                ),
            all_masks,
        )
        @test all(
            mask ->
                safe_feasible(problem, source, mask) ==
                (
                    !iszero(mask & family.bundle_mask) ||
                    mask == family.singleton_library_mask
                ),
            all_masks,
        )
    end

    @test instance_count == 24
    @test candidate_masks_checked == 2_016
end

@testset "exhaustive deletion-order boundary for small k" begin
    order_count = 0
    for k in 2:5
        family = safe_deletion_gap_problem(k, 1 // 2)
        problem = family.problem
        for order in _gap_permutations(collect(1:active_strategy_count(problem)))
            order_count += 1
            trace = safe_pruning_trace(problem, family.source_mask, order)
            @test inclusion_irreducible(problem, trace.endpoint)
            if first(order) == family.bundle_index
                @test trace.endpoint == family.singleton_library_mask
                @test library_weight(problem, trace.endpoint) == k
            else
                @test trace.endpoint == family.bundle_mask
                @test library_weight(problem, trace.endpoint) == 3 // 2
            end
        end
    end
    @test order_count == 870
end

@testset "committed exact safe-deletion gap fixture" begin
    fixture = build_safe_deletion_gap_fixture()
    committed = read(default_output_path(), String)

    @test fixture["schema_version"] == "safe-deletion-gap-family-v1"
    @test fixture["arithmetic"] == "Rational{BigInt}"
    @test fixture["gates"]["fixture_count"] == 5
    @test fixture["gates"]["all_fixture_gates_pass"]
    @test [row["approximation_ratio"] for row in fixture["fixtures"]] ==
          ["4//3", "2//1", "3//1", "20//7", "5//1"]
    @test all(
        row["gates"]["all_gates_pass"] for row in fixture["fixtures"]
    )
    @test committed == render_json(fixture)
end
