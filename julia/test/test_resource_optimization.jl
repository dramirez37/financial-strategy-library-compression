using .ResourceOptimizationCounterexampleSearch.ResourceOptimization
using Random: MersenneTwister, rand

function _rich_optimizer_problem()
    operational_values = [0, 2, 2, 4, 4, 4, 4, 4]
    generative_values = [0, 1, 1, 2, 2, 2, 2, 2]
    return ExactRetentionProblem(
        ["left", "right", "bundle"],
        [1, 1, 3],
        [2 0; 0 2; 2 2],
        UInt64[1, 2, 3],
        2,
        operational_values + generative_values;
        operational_values = operational_values,
        generative_values = generative_values,
    )
end

function _generated_exact_optimizer_problem(rng::MersenneTwister)
    active_count = 4
    belief_count = 2
    weights = rand(rng, 1:4, active_count)
    profiles = rand(rng, 0:3, active_count, belief_count)
    module_masks = UInt64.(rand(rng, 0:3, active_count))
    library_count = 1 << active_count
    operational_values = zeros(Int, library_count)
    generative_values = zeros(Int, library_count)
    for mask in UInt64(0):UInt64(library_count - 1)
        frontier = zeros(Int, belief_count)
        closure_mask = UInt64(0)
        for strategy_index in 1:active_count
            bit = UInt64(1) << (strategy_index - 1)
            iszero(mask & bit) && continue
            for belief_index in 1:belief_count
                frontier[belief_index] = max(
                    frontier[belief_index],
                    profiles[strategy_index, belief_index],
                )
            end
            closure_mask |= module_masks[strategy_index]
        end
        operational_values[Int(mask) + 1] = sum(frontier)
        generative_values[Int(mask) + 1] = count_ones(closure_mask)
    end
    return ExactRetentionProblem(
        ["s$index" for index in 1:active_count],
        weights,
        profiles,
        module_masks,
        2,
        operational_values + generative_values;
        operational_values = operational_values,
        generative_values = generative_values,
    )
end

@testset "exact resource optimization primitives" begin
    problem = ExactRetentionProblem(
        ["light", "heavy"],
        [1, 2],
        zeros(Int, 2, 1),
        UInt64[1, 1],
        1,
        [0, 0, 0, 0],
    )
    source = UInt64(3)

    @test eltype(problem.weights) == ExactRational
    @test library_strategy_ids(problem, UInt64(1)) == ["inactive", "light"]
    @test library_cardinality(problem, UInt64(1)) == 2
    @test library_weight(problem, UInt64(1)) == 1 // 1
    @test safe_sublibraries(problem, source) == UInt64[1, 2, 3]
    @test minimum_safe_cardinality_masks(problem, source) == UInt64[1, 2]
    @test minimum_safe_weight_masks(problem, source) == UInt64[1]

    trace = safe_pruning_trace(problem, source, [1, 2])
    @test trace.endpoint == UInt64(2)
    @test trace.deletions == [1]
    @test inclusion_irreducible(problem, trace.endpoint)
    @test safe_feasible(problem, source, trace.endpoint)

    @test_throws ArgumentError ExactRetentionProblem(
        ["bad"],
        [0],
        zeros(Int, 1, 1),
        UInt64[1],
        1,
        [0, 0],
    )
    @test_throws ArgumentError ExactRetentionProblem(
        ["float"],
        [1.0],
        zeros(Int, 1, 1),
        UInt64[1],
        1,
        [0, 0],
    )
    @test_throws ArgumentError ExactRetentionProblem(
        ["bad decomposition"],
        [1],
        zeros(Int, 1, 1),
        UInt64[1],
        1,
        [0, 1];
        operational_values = [0, 1],
        generative_values = [0, 1],
    )

    unsupported = ExactRetentionProblem(
        ["first", "second"],
        [1, 1],
        zeros(Int, 2, 1),
        UInt64[1, 2],
        2,
        [0, 0, 1, 3],
    )
    @test capacity_optimal_masks(unsupported, 1) == UInt64[2]
    @test supporting_price_interval(unsupported, UInt64(2)) === nothing

    breakpoint = ExactRetentionProblem(
        ["active"],
        [1],
        zeros(Int, 1, 1),
        UInt64[1],
        1,
        [0, 1],
    )
    @test penalty_breakpoints(breakpoint) == ExactRational[0, 1]
    @test penalized_optimal_masks(breakpoint, 1) == UInt64[0, 1]
    @test penalized_value(breakpoint, 1) == 0 // 1
end

@testset "rich exact finite-library optimizers" begin
    problem = _rich_optimizer_problem()
    source = UInt64(7)

    enumeration = enumerate_sublibraries(problem, source)
    @test [library.mask for library in enumeration.libraries] ==
          collect(UInt64(0):UInt64(7))
    @test enumeration.certificate.complete
    @test enumeration.operational_values + enumeration.generative_values ==
          enumeration.total_values
    @test exact_safe_feasible(problem, UInt64(3), source)
    @test exact_safe_feasible(problem, UInt64(4), source)
    @test !exact_safe_feasible(problem, UInt64(1), source)

    minimum_weight = minimum_weight_safe_compression(problem, source)
    @test minimum_weight.optimal_objective == 2 // 1
    @test [library.mask for library in minimum_weight.optimal_libraries] ==
          UInt64[3]
    @test minimum_weight.certificate.productive_value_preserved
    @test minimum_weight.certificate.ties_complete
    @test only(minimum_weight.operational_values) == 4 // 1
    @test only(minimum_weight.generative_values) == 2 // 1
    @test only(minimum_weight.total_values) == 6 // 1

    minimum_cardinality = minimum_cardinality_safe_compression(problem, source)
    @test minimum_cardinality.optimal_objective == 2
    @test [library.mask for library in minimum_cardinality.optimal_libraries] ==
          UInt64[4]

    capacity_two = capacity_optimal_library(problem, 2, :belief, :parameters)
    @test capacity_two.optimal_objective == 6 // 1
    @test [library.mask for library in capacity_two.optimal_libraries] ==
          UInt64[3]
    @test capacity_two.certificate.belief == :belief
    @test capacity_two.certificate.parameters == :parameters

    capacity_three = capacity_optimal_library(problem, 3)
    @test [library.mask for library in capacity_three.optimal_libraries] ==
          UInt64[3, 4]
    @test capacity_three.burdens == [2 // 1, 3 // 1]

    penalized = penalized_optimal_library(problem, 3)
    @test penalized.optimal_objective == 0 // 1
    @test [library.mask for library in penalized.optimal_libraries] ==
          UInt64[0, 1, 2, 3]
    @test penalized.certificate.ties_complete

    breakpoints = optimizer_breakpoints(problem)
    @test breakpoints.prices == ExactRational[0, 3]
    price_three = only(
        result for result in breakpoints.breakpoints if
        result.resource_price == 3 // 1
    )
    @test price_three.optimal_objective == 0 // 1
    @test breakpoints.certificate.every_breakpoint_has_unequal_optimal_burdens

    replacement = optimal_admission_deletion_set(
        problem,
        UInt64(3),
        "bundle",
        3,
    )
    @test replacement.optimal_objective == 6 // 1
    @test replacement.certificate.optimal_deletion_masks == UInt64[3]
    @test [library.mask for library in replacement.optimal_libraries] ==
          UInt64[4]
    @test replacement.capacity_deficit == 2 // 1
    @test replacement.gross_candidate_gain == 0 // 1
    @test replacement.minimum_displacement_loss == 0 // 1
    @test replacement.net_admission_value == 0 // 1
    @test replacement.certificate.feasibility_matches_release_certificate

    replacement_ties = optimal_admission_deletion_set(
        problem,
        UInt64(3),
        3,
        4,
    )
    @test replacement_ties.certificate.optimal_deletion_masks == UInt64[1, 2, 3]
    @test replacement_ties.certificate.ties_complete

    infeasible = optimal_admission_deletion_set(
        problem,
        UInt64(3),
        3,
        2,
    )
    @test infeasible.optimal_objective === nothing
    @test isempty(infeasible.optimal_libraries)
    @test !infeasible.certificate.objective_attained

    inconsistent = ExactRetentionProblem(
        ["duplicate"],
        [1],
        zeros(Int, 1, 1),
        UInt64[0],
        1,
        [0, 1],
    )
    @test_throws ArgumentError minimum_weight_safe_compression(
        inconsistent,
        UInt64(1),
    )
end

@testset "exhaustive optimizer reference comparisons" begin
    problem = _rich_optimizer_problem()
    all_masks = collect(library_masks(problem))
    for source in all_masks
        reference_sublibraries = UInt64[
            mask for mask in all_masks if iszero(mask & ~source)
        ]
        @test [
            library.mask for
            library in enumerate_sublibraries(problem, source).libraries
        ] == reference_sublibraries

        reference_safe = UInt64[
            mask for mask in reference_sublibraries if
            safe_feasible(problem, source, mask)
        ]
        best_weight = minimum(
            library_weight(problem, mask) for mask in reference_safe
        )
        reference_weight_optima = UInt64[
            mask for mask in reference_safe if
            library_weight(problem, mask) == best_weight
        ]
        exact_weight = minimum_weight_safe_compression(problem, source)
        @test [library.mask for library in exact_weight.optimal_libraries] ==
              reference_weight_optima

        best_cardinality = minimum(
            library_cardinality(problem, mask) for mask in reference_safe
        )
        reference_cardinality_optima = UInt64[
            mask for mask in reference_safe if
            library_cardinality(problem, mask) == best_cardinality
        ]
        exact_cardinality = minimum_cardinality_safe_compression(problem, source)
        @test [library.mask for library in exact_cardinality.optimal_libraries] ==
              reference_cardinality_optima
    end

    for capacity in 0:5
        feasible = UInt64[
            mask for mask in all_masks if
            library_weight(problem, mask) <= capacity
        ]
        best = maximum(library_total_value(problem, mask) for mask in feasible)
        reference = UInt64[
            mask for mask in feasible if
            library_total_value(problem, mask) == best
        ]
        result = capacity_optimal_library(problem, capacity)
        @test result.optimal_objective == best
        @test [library.mask for library in result.optimal_libraries] == reference
    end

    for price in ExactRational[0, 1, 2, 3, 4]
        objectives = ExactRational[
            library_total_value(problem, mask) -
            price * library_weight(problem, mask) for mask in all_masks
        ]
        best = maximum(objectives)
        reference = UInt64[
            mask for mask in all_masks if
            objectives[Int(mask) + 1] == best
        ]
        result = penalized_optimal_library(problem, price)
        @test result.optimal_objective == best
        @test [library.mask for library in result.optimal_libraries] == reference
    end

    current = UInt64(3)
    candidate_bit = UInt64(4)
    deletion_masks = UInt64[0, 1, 2, 3]
    for capacity in 0:5
        feasible_deletions = UInt64[
            deletion for deletion in deletion_masks if
            library_weight(
                problem,
                (current & ~deletion) | candidate_bit,
            ) <= capacity
        ]
        result = optimal_admission_deletion_set(problem, current, 3, capacity)
        if isempty(feasible_deletions)
            @test result.optimal_objective === nothing
            continue
        end
        values = ExactRational[
            library_total_value(
                problem,
                (current & ~deletion) | candidate_bit,
            ) for deletion in feasible_deletions
        ]
        best = maximum(values)
        reference = UInt64[
            deletion for deletion in feasible_deletions if
            library_total_value(
                problem,
                (current & ~deletion) | candidate_bit,
            ) == best
        ]
        @test result.optimal_objective == best
        @test result.certificate.optimal_deletion_masks == reference
    end
end

@testset "exact optimizer properties" begin
    rng = MersenneTwister(0x5afe_cafe)
    for _ in 1:64
        problem = _generated_exact_optimizer_problem(rng)
        source = last(library_masks(problem))
        safe_result = minimum_weight_safe_compression(problem, source)

        # Every reported optimum satisfies its defining feasibility predicate.
        @test all(
            exact_safe_feasible(problem, library.mask, source) for
            library in safe_result.optimal_libraries
        )
        capacity = exact_rational(rand(rng, 0:sum(problem.weights)))
        capacity_result = capacity_optimal_library(problem, capacity)
        @test all(burden -> burden <= capacity, capacity_result.burdens)
        penalty_result = penalized_optimal_library(problem, rand(rng, 0:5))
        @test all(
            library.mask in library_masks(problem) for
            library in penalty_result.optimal_libraries
        )
        current_mask = UInt64(rand(rng, 0:7))
        replacement = optimal_admission_deletion_set(
            problem,
            current_mask,
            4,
            capacity,
        )
        @test all(burden -> burden <= capacity, replacement.burdens)

        # Every rechecked exact-safe deletion strictly lowers positive burden.
        for mask in library_masks(problem), strategy_index in 1:4
            safely_deletable(problem, mask, strategy_index) || continue
            bit = UInt64(1) << (strategy_index - 1)
            @test library_weight(problem, mask & ~bit) <
                  library_weight(problem, mask)
        end

        # Exact-safe feasibility preserves the productive value in P_safe.
        source_value = library_total_value(problem, source)
        @test all(
            library_total_value(problem, mask) == source_value for
            mask in safe_sublibraries(problem, source)
        )

        # The complete optimal-burden correspondence is antitone in price.
        prices = penalty_probe_prices(problem)
        price_results = [
            penalized_optimal_library(problem, price) for price in prices
        ]
        for left_index in eachindex(prices)
            for right_index in (left_index + 1):length(prices)
                @test maximum(price_results[right_index].burdens) <=
                      minimum(price_results[left_index].burdens)
            end
        end

        # Capacity value is weakly increasing along the exact integer grid.
        capacity_values = ExactRational[
            capacity_optimal_library(problem, budget).optimal_objective for
            budget in 0:sum(problem.weights)
        ]
        @test all(
            capacity_values[index] <= capacity_values[index + 1] for
            index in 1:(length(capacity_values) - 1)
        )
    end
end

@testset "exact resource optimization claim audit" begin
    audit = run_resource_optimization_audit()
    @test audit["arithmetic"] == "Rational{BigInt}"
    @test audit["claim_count"] == 14
    @test audit["counterexample_count"] == 13
    @test audit["survivor_count"] == 1
    @test !audit["formalization_gate"]["lean_changes_made"]

    claims = audit["claims"]
    @test all(
        claims[lpad(string(number), 2, '0')]["status"] ==
        "counterexample_found" for
        number in vcat(collect(1:7), collect(9:14))
    )
    @test claims["08"]["status"] == "survived_exhaustive_search"

    cardinality = claims["01"]["fixture"]
    @test cardinality["greedy_trace"]["endpoint"]["active_count"] == 2
    @test only(
        cardinality["safe_set"]["minimum_cardinality_libraries"],
    )["active_count"] == 1

    weighted = claims["02"]["fixture"]
    @test weighted["greedy_trace"]["endpoint"]["weight"] == "2//1"
    @test only(weighted["safe_set"]["minimum_weight_libraries"])["weight"] ==
          "1//1"
    greedy = weighted["maximum_burden_greedy_counterexample"]
    @test greedy["trace"]["endpoint"]["weight"] == "4//1"
    @test only(greedy["safe_set"]["minimum_weight_libraries"])["weight"] ==
          "3//1"

    order = claims["03"]["fixture"]
    @test order["left_trace"]["endpoint"]["weight"] !=
          order["right_trace"]["endpoint"]["weight"]

    capacity = claims["05"]["fixture"]
    @test capacity["left_marginal"] == "0//1"
    @test capacity["right_marginal"] == "1//1"

    switch = claims["07"]["fixture"]
    @test switch["raw_incomparable"]
    @test switch["burden_decreases"]

    burden = claims["08"]["fixture"]
    @test burden["general_algebra"] ==
          "optimality at λ1 and λ2 implies (λ2-λ1)(W1-W2) >= 0"

    unsupported = claims["11"]["fixture"]
    @test unsupported["supporting_price_interval"] === nothing

    elasticity = claims["13"]["fixture"]["exact_family"]
    @test all(row["identity_check"] for row in elasticity)
    @test last(elasticity)["level_elasticity"] == "17//1"

    @test write_resource_optimization_audit(; check = true) == audit
end
