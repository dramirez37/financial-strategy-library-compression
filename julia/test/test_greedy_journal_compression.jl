function _greedy_provenance(instance_id)
    return JournalCompressionProvenance(
        :synthetic,
        String(instance_id),
        "exact in-repository journal greedy fixture";
        generator = "test_greedy_journal_compression",
        attributes = ["evidence_class" => "exact finite computation"],
    )
end


function _greedy_fixture(
    instance_id,
    ids,
    mandatory,
    weights,
    modules;
    profiles = zeros(Int, length(ids), 1),
)
    return journal_compression_instance_from_components(
        ids,
        mandatory,
        weights,
        [:zero],
        profiles,
        modules;
        provenance = _greedy_provenance(instance_id),
    )
end


function _greedy_selected_ids(result)
    return [strategy_id.id for strategy_id in result.selected_strategy_ids]
end


@testset "journal weighted and cardinality greedy traces" begin
    instance = _greedy_fixture(
        "weighted-versus-cardinality",
        [:inactive, :bundle, :left, :right],
        Bool[true, false, false, false],
        [0, 10, 1, 1],
        [Symbol[], [:m1, :m2], [:m1], [:m2]],
    )
    weighted = solve_journal_compression_weighted_greedy(instance)
    cardinality = solve_journal_compression_cardinality_greedy(instance)

    @test weighted.status == :feasible_heuristic
    @test _greedy_selected_ids(weighted) == [:inactive, :left, :right]
    @test weighted.exact_burden == 2
    @test weighted.uncovered_counts == [2, 1, 0]
    @test [step.exact_score for step in weighted.step_trace] == [1, 1]
    @test [step.newly_covered_requirement_indices for step in weighted.step_trace] ==
          [[2], [3]]
    @test weighted.guarantee.applies_to_exact_burden
    @test weighted.guarantee.maximum_residual_set_cardinality == 2
    @test weighted.guarantee.exact_harmonic_factor == 3 // 2
    @test weighted.final_certificate.evidence_class ==
          "exact finite heuristic computation"
    @test !weighted.final_certificate.solver_status_used
    @test !weighted.final_certificate.search_complete
    @test !weighted.final_certificate.lean_kernel_verified

    @test _greedy_selected_ids(cardinality) == [:bundle, :inactive]
    @test cardinality.exact_burden == 10
    @test only(cardinality.step_trace).exact_score == 1 // 2
    @test !cardinality.guarantee.applies_to_exact_burden
    @test occursin("no approximation guarantee", cardinality.guarantee.declaration)

    tied = _greedy_fixture(
        "deterministic-exact-tie",
        [:inactive, :a, :b],
        Bool[true, false, false],
        [0, 1, 1],
        [Symbol[], [:m1], [:m1]],
    )
    tied_result = solve_journal_compression_weighted_greedy(tied)
    tied_cardinality = solve_journal_compression_cardinality_greedy(tied)
    @test _greedy_selected_ids(tied_result) == [:a, :inactive]
    @test only(tied_result.step_trace).exact_score == 1
    @test occursin("lowest original strategy index", tied_result.tie_declaration)
    @test tied_cardinality.guarantee.applies_to_exact_burden

    huge = big(10)^100
    exact_score = _greedy_fixture(
        "large-exact-score",
        [:inactive, :all, :left],
        Bool[true, false, false],
        [0, 2 * huge + 1, huge],
        [Symbol[], [:m1, :m2], [:m1]],
    )
    exact_result = solve_journal_compression_weighted_greedy(exact_score)
    @test first(exact_result.step_trace).exact_score == huge
    @test first(exact_result.step_trace).strategy_id.id == :left
    @test all(step -> step.exact_score isa Rational{BigInt}, exact_result.step_trace)
end


@testset "mandatory initialization and reverse deletion" begin
    zero_remaining = _greedy_fixture(
        "zero-residual",
        [:inactive, :unused],
        Bool[true, false],
        [0, 3],
        [Symbol[], Symbol[]],
    )
    zero_result = solve_journal_compression_weighted_greedy_reverse_delete(
        zero_remaining,
    )
    @test _greedy_selected_ids(zero_result) == [:inactive]
    @test isempty(zero_result.step_trace)
    @test zero_result.uncovered_counts == [0]
    @test zero_result.guarantee.exact_harmonic_factor == 1
    @test zero_result.guarantee.maximum_residual_set_cardinality == 0

    all_mandatory = _greedy_fixture(
        "all-mandatory",
        [:inactive, :required],
        Bool[true, true],
        [0, 5],
        [Symbol[], [:m1]],
    )
    mandatory_result = solve_journal_compression_weighted_greedy(all_mandatory)
    @test _greedy_selected_ids(mandatory_result) == [:inactive, :required]
    @test mandatory_result.exact_burden == 5
    @test isempty(mandatory_result.step_trace)

    reverse_fixture = _greedy_fixture(
        "reverse-delete",
        [:inactive, :a_early, :b_late, :c_last],
        Bool[true, false, false, false],
        [0, 1, 1, 1],
        [Symbol[], [:m1, :m2], [:m1, :m3], [:m2, :m4]],
    )
    forward = solve_journal_compression_weighted_greedy(reverse_fixture)
    reverse = solve_journal_compression_weighted_greedy_reverse_delete(
        reverse_fixture,
    )
    @test _greedy_selected_ids(forward) ==
          [:a_early, :b_late, :c_last, :inactive]
    @test _greedy_selected_ids(reverse) == [:b_late, :c_last, :inactive]
    @test forward.exact_burden == 3
    @test reverse.greedy_burden_before_reverse_deletion == 3
    @test reverse.exact_burden == 2
    @test [step.strategy_id.id for step in reverse.reverse_deletion_trace] ==
          [:c_last, :b_late, :a_early]
    @test [step.removed for step in reverse.reverse_deletion_trace] ==
          [false, false, true]
    @test all(
        step -> step.exact_burden_after <= step.exact_burden_before,
        reverse.reverse_deletion_trace,
    )
    for index in findall(reverse.selected)
        reverse_fixture.mandatory[index] && continue
        trial = copy(reverse.selected)
        trial[index] = false
        @test !journal_compression_feasible(reverse_fixture, trial)
    end
end


@testset "Chvatal exact near-tight family" begin
    epsilon = BigInt(1) // BigInt(10_000)
    for m in 2:7
        instance = chvatal_weighted_greedy_tightness_instance(m; epsilon)
        greedy = solve_journal_compression_weighted_greedy(instance)
        reverse_result =
            solve_journal_compression_weighted_greedy_reverse_delete(instance)
        optimum = solve_journal_compression_enumeration(
            instance;
            retain_all_ties = false,
            maximum_optional_strategies = 10,
        )
        harmonic = sum(
            (BigInt(1) // BigInt(index) for index in 1:m);
            init = BigInt(0) // BigInt(1),
        )
        @test greedy.exact_burden == harmonic
        @test optimum.exact_burden == 1 + epsilon
        @test greedy.exact_burden / optimum.exact_burden < harmonic
        @test greedy.guarantee.maximum_residual_set_cardinality == m
        @test greedy.guarantee.exact_harmonic_factor == harmonic
        @test [step.strategy_id.id for step in greedy.step_trace] ==
              reverse([Symbol("singleton_", index) for index in 1:m])
        @test [step.exact_score for step in greedy.step_trace] ==
              [BigInt(1) // BigInt(index) for index in m:-1:1]
        @test reverse_result.exact_burden == harmonic
        @test all(!step.removed for step in reverse_result.reverse_deletion_trace)
    end
    @test_throws ArgumentError chvatal_weighted_greedy_tightness_instance(1)
    @test_throws ArgumentError chvatal_weighted_greedy_tightness_instance(
        2;
        epsilon = 1 // 2,
    )
end


@testset "exhaustive small exact greedy audit" begin
    checked = 0
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
            instance = _greedy_fixture(
                "greedy-a$(active_count)-m$(module_count)-$(encoded_system)",
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
            weighted = solve_journal_compression_weighted_greedy(instance)
            cardinality = solve_journal_compression_cardinality_greedy(instance)
            reverse_result =
                solve_journal_compression_weighted_greedy_reverse_delete(instance)

            @test journal_compression_feasible(instance, weighted.selected)
            @test journal_compression_feasible(instance, cardinality.selected)
            @test journal_compression_feasible(instance, reverse_result.selected)
            @test weighted.exact_burden <=
                  weighted.guarantee.exact_harmonic_factor * optimum.exact_burden
            @test reverse_result.exact_burden <= weighted.exact_burden
            @test reverse_result.exact_burden <=
                  reverse_result.guarantee.exact_harmonic_factor *
                  optimum.exact_burden
            repeated = solve_journal_compression_weighted_greedy(instance)
            @test weighted.selected == repeated.selected
            @test [step.strategy_index for step in weighted.step_trace] ==
                  [step.strategy_index for step in repeated.step_trace]
            @test [step.exact_score for step in weighted.step_trace] ==
                  [step.exact_score for step in repeated.step_trace]
            checked += 1
        end
    end
    @test checked == 441
end
