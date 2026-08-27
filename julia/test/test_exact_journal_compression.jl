import TOML


function _exact_solver_provenance(instance_id)
    return JournalCompressionProvenance(
        :synthetic,
        String(instance_id),
        "exact in-repository journal solver fixture";
        generator = "test_exact_journal_compression",
        attributes = ["evidence_class" => "exact finite computation"],
    )
end


function _exact_solver_fixture(
    instance_id,
    ids,
    mandatory,
    weights,
    modules;
    profiles = zeros(Int, length(ids), 1),
    tie_handling = default_journal_tie_handling(),
)
    return journal_compression_instance_from_components(
        ids,
        mandatory,
        weights,
        [:zero],
        profiles,
        modules;
        tie_handling,
        provenance = _exact_solver_provenance(instance_id),
    )
end


function _exact_solver_with_preprocessing(instance, result)
    preprocessing = JournalPreprocessingMap(
        true,
        sort(result.remaining_requirement_indices),
        sort(result.remaining_strategy_indices),
        sort(result.forced_strategy_indices),
        result.objective_offset,
        result.equal_coverage_choices;
        all_optimizer_identities_reconstructable =
            result.all_optimizer_identities_reconstructable,
    )
    return JournalCompressionInstance(
        instance.schema_version,
        instance.strategy_ids,
        instance.mandatory,
        instance.weights,
        instance.requirements,
        instance.coverage,
        instance.operating_profiles,
        instance.strategy_modules,
        instance.source_frontier,
        instance.source_closure,
        instance.identity_closure,
        preprocessing,
        instance.tie_handling,
        instance.provenance,
    )
end


_exact_selection_keys(result) =
    Set(Tuple(findall(selection)) for selection in result.optimal_selections)

_exact_selected_ids(result) = Set(
    result.strategy_ids[index].id for index in findall(result.selected)
)


function _cross_check_exact_solvers(instance; retain_all_ties = true)
    enumeration = solve_journal_compression_enumeration(
        instance;
        retain_all_ties,
        maximum_optional_strategies = 12,
        maximum_ties = 1_000,
    )
    dynamic_program = solve_journal_compression_dp(
        instance;
        retain_all_ties,
        maximum_ties = 1_000,
    )
    @test enumeration.exact_burden == dynamic_program.exact_burden
    @test _exact_selection_keys(enumeration) ==
          _exact_selection_keys(dynamic_program)
    @test all(
        journal_compression_burden(instance, selection) ==
        enumeration.exact_burden for selection in enumeration.optimal_selections
    )
    @test all(
        check_journal_compression_solution(
            instance,
            selection;
            expected_burden = enumeration.exact_burden,
        ).exact_feasible for selection in enumeration.optimal_selections
    )
    @test all(certificate.burden_reconciled for certificate in enumeration.certificates)
    @test all(certificate.burden_reconciled for certificate in dynamic_program.certificates)
    return enumeration, dynamic_program
end


@testset "exact journal enumeration and requirement-mask DP edge cases" begin
    zero_remaining = _exact_solver_fixture(
        "zero-remaining-requirements",
        [:inactive, :unused],
        Bool[true, false],
        [0, 7],
        [Symbol[], Symbol[]],
    )
    zero_enum, zero_dp = _cross_check_exact_solvers(zero_remaining)
    @test zero_enum.exact_burden == 0
    @test findall(zero_enum.selected) == [1]
    @test zero_dp.preprocessing.reduced_requirement_count == 0
    @test zero_dp.counters.final_reachable_states == 1

    all_mandatory = _exact_solver_fixture(
        "all-mandatory",
        [:inactive, :required],
        Bool[true, true],
        [0, 3],
        [Symbol[], [:m1]],
    )
    mandatory_enum, mandatory_dp = _cross_check_exact_solvers(all_mandatory)
    @test mandatory_enum.exact_burden == 3
    @test findall(mandatory_dp.selected) == [1, 2]
    @test mandatory_dp.preprocessing.reduced_strategy_count == 0

    tied = _exact_solver_fixture(
        "tied-optima",
        [:inactive, :left, :right, :bundle],
        Bool[true, false, false, false],
        [0, 1, 1, 2],
        [Symbol[], [:m1], [:m2], [:m1, :m2]],
    )
    tied_enum, tied_dp = _cross_check_exact_solvers(tied)
    @test tied_enum.ties_complete
    @test tied_dp.ties_complete
    @test length(tied_enum.optimal_selections) == 2
    @test tied_enum.exact_burden == 2
    representative_enum = solve_journal_compression_enumeration(
        tied;
        retain_all_ties = false,
    )
    representative_dp = solve_journal_compression_dp(
        tied;
        retain_all_ties = false,
    )
    @test representative_enum.exact_burden == representative_dp.exact_burden
    @test representative_dp.selected == solve_journal_compression_dp(
        tied;
        retain_all_ties = false,
    ).selected
    @test !representative_dp.ties_complete
    @test_throws ArgumentError solve_journal_compression_enumeration(
        tied;
        retain_all_ties = true,
        maximum_ties = 1,
    )
    @test_throws ArgumentError solve_journal_compression_dp(
        tied;
        retain_all_ties = true,
        maximum_ties = 1,
    )

    dominated = _exact_solver_fixture(
        "dominated-strategy",
        [:inactive, :costly_left, :cover],
        Bool[true, false, false],
        [0, 9, 2],
        [Symbol[], [:m1], [:m1, :m2]],
    )
    dominated_enum, dominated_dp = _cross_check_exact_solvers(dominated)
    @test dominated_enum.exact_burden == 2
    @test _exact_selected_ids(dominated_dp) == Set([:inactive, :cover])

    duplicates = _exact_solver_fixture(
        "duplicate-masks",
        [:inactive, :copy_a, :copy_b],
        Bool[true, false, false],
        [0, 1, 1],
        [Symbol[], [:m1], [:m1]],
    )
    duplicate_enum, duplicate_dp = _cross_check_exact_solvers(duplicates)
    @test duplicate_enum.exact_burden == 1
    @test length(duplicate_dp.optimal_selections) == 2

    duplicate_preprocessing = preprocess_tagged_cover(
        exact_tagged_cover_model(duplicates),
    )
    preprocessed_duplicates = _exact_solver_with_preprocessing(
        duplicates,
        duplicate_preprocessing,
    )
    preprocessed_enum, preprocessed_dp = _cross_check_exact_solvers(
        preprocessed_duplicates,
    )
    @test preprocessed_enum.preprocessing.input_preprocessing_reused
    @test length(preprocessed_dp.optimal_selections) == 2

    lossy = _exact_solver_fixture(
        "lossy-equal-dominance",
        [:inactive, :left, :right, :bundle],
        Bool[true, false, false, false],
        [0, 1, 1, 1],
        [Symbol[], [:m1], [:m2], [:m1, :m2]],
    )
    lossy_preprocessing = preprocess_tagged_cover(exact_tagged_cover_model(lossy))
    @test !lossy_preprocessing.all_optimizer_identities_reconstructable
    lossy_instance = _exact_solver_with_preprocessing(lossy, lossy_preprocessing)
    @test_throws ArgumentError solve_journal_compression_enumeration(
        lossy_instance;
        retain_all_ties = true,
    )
    @test_throws ArgumentError solve_journal_compression_dp(
        lossy_instance;
        retain_all_ties = true,
    )
    @test solve_journal_compression_dp(lossy_instance).exact_burden == 1

    huge = big(10)^80
    large_weights = _exact_solver_fixture(
        "large-exact-weights",
        [:inactive, :left, :right, :bundle],
        Bool[true, false, false, false],
        [0, huge, huge + 1, 2 * huge + 2],
        [Symbol[], [:m1], [:m2], [:m1, :m2]],
    )
    large_enum, large_dp = _cross_check_exact_solvers(large_weights)
    @test large_enum.exact_burden == 2 * huge + 1
    @test large_dp.exact_burden isa Rational{BigInt}

    malformed = _exact_solver_fixture(
        "malformed-infeasible",
        [:inactive, :carrier],
        Bool[true, false],
        [0, 1],
        [Symbol[], [:m1]],
    )
    module_row = findfirst(
        requirement -> requirement isa ModuleRequirement,
        malformed.requirements,
    )
    malformed.coverage[module_row, :] .= false
    @test_throws ArgumentError solve_journal_compression_enumeration(malformed)
    @test_throws ArgumentError solve_journal_compression_dp(malformed)
end


@testset "exhaustive generated exact-solver cross-check" begin
    generated_instances = 0
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
                carriers = digits[module_index]
                for active_index in 1:active_count
                    iszero(carriers & (1 << (active_index - 1))) && continue
                    push!(modules[active_index + 1], module_id)
                end
            end
            weights = Any[0]
            for active_index in 1:active_count
                push!(
                    weights,
                    BigInt(1 + mod(active_index + encoded_system, 3)) //
                    BigInt(1 + mod(active_index, 2)),
                )
            end
            instance = _exact_solver_fixture(
                "generated-a$(active_count)-m$(module_count)-$(encoded_system)",
                ids,
                Bool[true; falses(active_count)],
                weights,
                modules,
            )
            _cross_check_exact_solvers(instance)
            generated_instances += 1
        end
    end
    @test generated_instances == 441
end


@testset "exact result counters, certificate, and CLI" begin
    fixture = _exact_solver_fixture(
        "certificate-fixture",
        [:inactive, :left, :right, :bundle],
        Bool[true, false, false, false],
        [0, 1, 1, 3],
        [Symbol[], [:m1], [:m2], [:m1, :m2]],
    )
    enumeration = solve_journal_compression_enumeration(fixture)
    dynamic_program = solve_journal_compression_dp(fixture)
    @test enumeration.counters.candidate_selections_evaluated == 8
    @test enumeration.counters.transitions_evaluated == 0
    @test dynamic_program.counters.state_layer_pairs_visited > 0
    @test dynamic_program.counters.transitions_evaluated ==
          2 * dynamic_program.counters.state_layer_pairs_visited
    @test dynamic_program.runtime.total_ns >= dynamic_program.runtime.search_ns

    certificate_text = serialize_journal_exact_solution(dynamic_program)
    certificate = TOML.parse(certificate_text)
    @test certificate["schema_version"] ==
          JOURNAL_EXACT_SOLUTION_SCHEMA_VERSION
    @test certificate["algorithm"] == "requirement_mask_dp"
    @test certificate["evidence_class"] == "exact finite computation"
    @test certificate["solver_status_used"] == false
    @test certificate["exact_burden"] == "2//1"
    @test certificate["optimal_selections"][1]["frontier_preserved"]
    @test certificate["optimal_selections"][1]["closure_preserved"]

    mktempdir() do directory
        input_path = joinpath(directory, "instance.toml")
        open(input_path, "w") do io
            write_journal_compression_instance(io, fixture)
        end
        output = IOBuffer()
        cli_result = JournalCompressionExactCLI.main(
            [input_path, "--algorithm", "dp"];
            output,
        )
        cli_payload = TOML.parse(String(take!(output)))
        @test cli_result.exact_burden == 2
        @test cli_payload["instance_sha256"] ==
              journal_compression_instance_sha256(fixture)
        @test cli_payload["search_complete"]
    end

    @test_throws ArgumentError solve_journal_compression_enumeration(
        fixture;
        maximum_optional_strategies = 2,
    )
    @test_throws ArgumentError solve_journal_compression_dp(
        fixture;
        maximum_ties = 0,
    )
end
