function _deletion_provenance(instance_id; kind = :synthetic)
    return JournalCompressionProvenance(
        kind,
        String(instance_id),
        "exact in-repository certified deletion fixture";
        generator = "test_certified_deletion_journal_compression",
        attributes = ["evidence_class" => "exact finite computation"],
    )
end


function _deletion_fixture(
    instance_id,
    ids,
    mandatory,
    weights,
    modules;
    profiles = zeros(Int, length(ids), 1),
    kind = :synthetic,
)
    return journal_compression_instance_from_components(
        ids,
        mandatory,
        weights,
        [:zero],
        profiles,
        modules;
        provenance = _deletion_provenance(instance_id; kind),
    )
end


function _deletion_gap_fixture(k, epsilon)
    singleton_ids = Symbol[Symbol("s_", index) for index in 1:k]
    ids = Symbol[:inactive; singleton_ids; :s_bundle]
    weights = Any[0; fill(1, k); 1 + epsilon]
    modules = Any[Symbol[]]
    append!(modules, Any[[Symbol("m_", index)] for index in 1:k])
    push!(modules, Symbol[Symbol("m_", index) for index in 1:k])
    return _deletion_fixture(
        "safe-deletion-gap-k$(k)-epsilon-$(numerator(epsilon))-$(denominator(epsilon))",
        ids,
        Bool[true; falses(k + 1)],
        weights,
        modules;
        kind = :adversarial,
    )
end


function _deletion_index(instance, id)
    index = findfirst(strategy_id -> strategy_id.id == id, instance.strategy_ids)
    isnothing(index) && error("missing strategy identifier in deletion fixture")
    return index
end


_deletion_selected_ids(result) = Set(
    strategy_id.id for strategy_id in result.selected_strategy_ids
)


function _test_certified_deletion_result(instance, result, optimum_burden)
    @test result.status == :certified_irreducible_heuristic
    @test journal_compression_feasible(instance, result.selected)
    @test journal_compression_burden(instance, result.selected) ==
          result.exact_burden
    @test result.exact_burden >= optimum_burden
    @test result.counters.frontier_checks == result.counters.closure_checks
    @test result.counters.complete_scans >= 1
    @test result.runtime.total_ns >= result.runtime.algorithm_ns
    @test result.runtime.total_ns >= result.runtime.final_certification_ns
    @test result.final_feasibility_certificate.frontier_preserved
    @test result.final_feasibility_certificate.closure_preserved
    @test result.final_feasibility_certificate.tagged_coverage
    @test !result.final_feasibility_certificate.solver_status_used
    @test !result.final_feasibility_certificate.search_complete
    @test !result.final_feasibility_certificate.lean_kernel_verified
    @test result.irreducibility_certificate.complete
    @test result.irreducibility_certificate.no_safe_nonmandatory_deletion
    for check in result.irreducibility_certificate.checks
        @test !check.deletion_safe
    end
    for step in result.deletion_trace
        @test step.mandatory_retained
        @test step.tagged_coverage_preserved
        @test step.frontier_preserved
        @test step.closure_preserved
        @test step.exact_burden_release == instance.weights[step.strategy_index]
        @test setdiff(step.selected_before_indices, step.selected_after_indices) ==
              [step.strategy_index]
        @test step.exact_burden_after == sum(
            (
                instance.weights[index] for index in step.selected_after_indices
            );
            init = zero(ExactRational),
        )
    end
end


@testset "certified deletion common API and deterministic rules" begin
    instance = _deletion_fixture(
        "common-api",
        [:inactive, :a, :b, :c],
        Bool[true, false, false, false],
        [0, 1, 2, 3],
        [Symbol[], [:m1], [:m1], [:m2]],
    )
    optimum = solve_journal_compression_enumeration(
        instance;
        retain_all_ties = false,
    )
    heaviest = solve_journal_compression_deletion(
        instance;
        algorithm = :heaviest_safe_first,
    )
    lightest = solve_journal_compression_lightest_safe_first(instance)
    release = solve_journal_compression_maximum_immediate_burden_release(
        instance,
    )
    exposure = solve_journal_compression_minimum_unique_carrier_exposure(
        instance,
    )
    declared = solve_journal_compression_declared_order(instance)

    for result in (heaviest, lightest, release, exposure, declared)
        _test_certified_deletion_result(instance, result, optimum.exact_burden)
        @test isnothing(result.random_seed)
        @test isempty(result.start_summaries)
    end
    @test heaviest.selected ==
          solve_journal_compression_heaviest_safe_first(instance).selected
    @test heaviest.selected == release.selected
    @test [step.strategy_index for step in heaviest.deletion_trace] ==
          [step.strategy_index for step in release.deletion_trace]
    @test occursin("equivalent", release.tie_declaration)
    @test first(heaviest.deletion_trace).strategy_id.id == :b
    @test first(lightest.deletion_trace).strategy_id.id == :a
    @test first(declared.deletion_trace).strategy_id.id == :a
    @test haskey(first(exposure.deletion_trace).selection_score,
        :remaining_unique_carrier_exposure)
    @test heaviest.counters.complete_scans ==
          length(heaviest.deletion_trace) + 1
    @test heaviest.counters.frontier_checks == 6
    @test length(heaviest.irreducibility_certificate.checks) == 2

    optional = Int[
        index for index in eachindex(instance.strategy_ids) if
        !instance.mandatory[index]
    ]
    reversed = solve_journal_compression_declared_order(
        instance;
        declared_source_order = reverse(optional),
    )
    @test first(reversed.deletion_trace).strategy_id.id == :b
    @test reversed.order_indices == reverse(optional)
    @test_throws ArgumentError solve_journal_compression_declared_order(
        instance;
        declared_source_order = optional[1:2],
    )
end


@testset "exact deletion ties and mandatory-only endpoint" begin
    tie_instance = _deletion_fixture(
        "exact-ties",
        [:inactive, :a, :b, :c],
        Bool[true, false, false, false],
        [0, 1, 1, 1],
        [Symbol[], [:m1], [:m1], [:m2]],
    )
    tie_optimum = solve_journal_compression_enumeration(
        tie_instance;
        retain_all_ties = true,
    )
    lowest_safe_index = _deletion_index(tie_instance, :a)
    deterministic = (
        solve_journal_compression_heaviest_safe_first(tie_instance),
        solve_journal_compression_lightest_safe_first(tie_instance),
        solve_journal_compression_maximum_immediate_burden_release(
            tie_instance,
        ),
        solve_journal_compression_minimum_unique_carrier_exposure(
            tie_instance,
        ),
        solve_journal_compression_declared_order(tie_instance),
    )
    for result in deterministic
        _test_certified_deletion_result(
            tie_instance,
            result,
            tie_optimum.exact_burden,
        )
        @test first(result.deletion_trace).strategy_index == lowest_safe_index
    end

    mandatory_instance = _deletion_fixture(
        "mandatory-only-endpoint",
        [:inactive, :core],
        Bool[true, true],
        [0, 5],
        [Symbol[], [:m]],
    )
    mandatory_optimum = solve_journal_compression_enumeration(
        mandatory_instance;
        retain_all_ties = false,
    )
    algorithms = (
        :heaviest_safe_first,
        :lightest_safe_first,
        :maximum_immediate_burden_release,
        :minimum_remaining_unique_carrier_exposure,
        :declared_source_order,
        :random_order_rechecked_deletion,
        :multistart_random_deletion,
    )
    endpoints = JournalDeletionSolutionResult[
        solve_journal_compression_deletion(
            mandatory_instance;
            algorithm,
            seed = UInt64(0x5511),
            starts = 3,
        ) for algorithm in algorithms
    ]
    for result in endpoints
        _test_certified_deletion_result(
            mandatory_instance,
            result,
            mandatory_optimum.exact_burden,
        )
        @test isempty(result.deletion_trace)
        @test isempty(result.irreducibility_certificate.checks)
    end
    @test all(isempty(result.order_indices) for result in endpoints)
    @test endpoints[end].counters.complete_scans == 3
    @test endpoints[end].counters.frontier_checks == 3
    @test length(endpoints[end].start_summaries) == 3
end


@testset "unbounded-gap family regression across deletion rules" begin
    for k in 2:7
        epsilon = BigInt(1) // BigInt(2)
        instance = _deletion_gap_fixture(k, epsilon)
        bundle_index = _deletion_index(instance, :s_bundle)
        singleton_indices = Int[
            _deletion_index(instance, Symbol("s_", index)) for index in 1:k
        ]
        optimum = solve_journal_compression_enumeration(
            instance;
            retain_all_ties = false,
            maximum_optional_strategies = 8,
        )
        heaviest = solve_journal_compression_heaviest_safe_first(instance)
        release = solve_journal_compression_maximum_immediate_burden_release(
            instance,
        )
        lightest = solve_journal_compression_lightest_safe_first(instance)
        exposure = solve_journal_compression_minimum_unique_carrier_exposure(
            instance,
        )
        bundle_first = solve_journal_compression_declared_order(
            instance;
            declared_source_order = [bundle_index; singleton_indices],
        )
        singleton_first = solve_journal_compression_declared_order(
            instance;
            declared_source_order = [singleton_indices; bundle_index],
        )

        @test optimum.exact_burden == 1 + epsilon
        @test heaviest.exact_burden == k
        @test release.exact_burden == k
        @test bundle_first.exact_burden == k
        @test first(heaviest.deletion_trace).strategy_index == bundle_index
        @test heaviest.exact_burden / optimum.exact_burden ==
              exact_rational(k) / (1 + epsilon)
        @test lightest.exact_burden == optimum.exact_burden
        @test exposure.exact_burden == optimum.exact_burden
        @test singleton_first.exact_burden == optimum.exact_burden
        @test _deletion_selected_ids(exposure) == Set([:inactive, :s_bundle])
        @test first(exposure.deletion_trace).selection_score.remaining_unique_carrier_exposure ==
              1
        for result in (
            heaviest,
            release,
            lightest,
            exposure,
            bundle_first,
            singleton_first,
        )
            _test_certified_deletion_result(
                instance,
                result,
                optimum.exact_burden,
            )
        end
    end
end


@testset "reproducible random-order and multi-start deletion" begin
    instance = _deletion_gap_fixture(6, 1 // 2)
    optimum = solve_journal_compression_enumeration(
        instance;
        retain_all_ties = false,
        maximum_optional_strategies = 8,
    )
    seed = UInt64(0x5eed_2026)
    first_run = solve_journal_compression_random_order(instance; seed)
    repeated = solve_journal_compression_random_order(instance; seed)
    @test first_run.random_seed == seed
    @test first_run.order_indices == repeated.order_indices
    @test first_run.selected == repeated.selected
    @test [step.strategy_index for step in first_run.deletion_trace] ==
          [step.strategy_index for step in repeated.deletion_trace]
    @test [step.selection_score for step in first_run.deletion_trace] ==
          [step.selection_score for step in repeated.deletion_trace]
    _test_certified_deletion_result(
        instance,
        first_run,
        optimum.exact_burden,
    )

    multi = solve_journal_compression_multistart_random(
        instance;
        seed,
        starts = 24,
    )
    multi_repeated = solve_journal_compression_multistart_random(
        instance;
        seed,
        starts = 24,
    )
    @test multi.random_seed == seed
    @test length(multi.start_summaries) == 24
    @test [row.random_seed for row in multi.start_summaries] ==
          [row.random_seed for row in multi_repeated.start_summaries]
    @test [row.random_order_indices for row in multi.start_summaries] ==
          [row.random_order_indices for row in multi_repeated.start_summaries]
    @test multi.selected == multi_repeated.selected
    @test multi.exact_burden == minimum(
        row.exact_burden for row in multi.start_summaries
    )
    @test multi.exact_burden == optimum.exact_burden
    @test all(row.exact_feasible for row in multi.start_summaries)
    @test all(row.irreducible for row in multi.start_summaries)
    @test multi.counters.frontier_checks == sum(
        (row.counters.frontier_checks for row in multi.start_summaries);
        init = BigInt(0),
    )
    _test_certified_deletion_result(instance, multi, optimum.exact_burden)

    @test_throws ArgumentError solve_journal_compression_multistart_random(
        instance;
        seed,
        starts = 0,
    )
    @test_throws ArgumentError solve_journal_compression_random_order(
        instance;
        seed = -1,
    )
end


@testset "exhaustive small deletion-suite cross-check against exact optimum" begin
    checked_instances = 0
    algorithms = (
        :heaviest_safe_first,
        :lightest_safe_first,
        :maximum_immediate_burden_release,
        :minimum_remaining_unique_carrier_exposure,
        :declared_source_order,
        :random_order_rechecked_deletion,
        :multistart_random_deletion,
    )
    for active_count in 1:3, module_count in 1:3
        carrier_pattern_count = (1 << active_count) - 1
        system_count = carrier_pattern_count^module_count
        for encoded_system in 0:(system_count - 1)
            digits = Int[]
            remainder = encoded_system
            for _ in 1:module_count
                push!(digits, (remainder % carrier_pattern_count) + 1)
                remainder = div(remainder, carrier_pattern_count)
            end
            ids = Symbol[:inactive; [Symbol("s$index") for index in 1:active_count]]
            modules = [Symbol[] for _ in eachindex(ids)]
            for module_index in 1:module_count
                module_id = Symbol("m$module_index")
                for active_index in 1:active_count
                    iszero(digits[module_index] & (1 << (active_index - 1))) && continue
                    push!(modules[active_index + 1], module_id)
                end
            end
            weights = Any[0]
            for active_index in 1:active_count
                push!(
                    weights,
                    BigInt(1 + mod(active_index + encoded_system, 5)) //
                    BigInt(1 + mod(active_index, 2)),
                )
            end
            instance = _deletion_fixture(
                "deletion-a$(active_count)-m$(module_count)-$(encoded_system)",
                ids,
                Bool[true; falses(active_count)],
                weights,
                modules,
            )
            optimum = solve_journal_compression_enumeration(
                instance;
                retain_all_ties = false,
                maximum_optional_strategies = 3,
            )
            results = JournalDeletionSolutionResult[
                solve_journal_compression_deletion(
                    instance;
                    algorithm,
                    seed = UInt64(0xabc0 + encoded_system),
                    starts = 4,
                ) for algorithm in algorithms
            ]
            for result in results
                @test journal_compression_feasible(instance, result.selected)
                @test result.exact_burden >= optimum.exact_burden
                @test result.irreducibility_certificate.no_safe_nonmandatory_deletion
                @test result.counters.frontier_checks ==
                      result.counters.closure_checks
            end
            @test results[1].selected == results[3].selected
            @test results[7].exact_burden <= maximum(
                row.exact_burden for row in results[7].start_summaries
            )
            checked_instances += 1
        end
    end
    @test checked_instances == 441
end
