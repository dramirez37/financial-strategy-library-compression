@testset "T7 exact frontier--closure interaction surface" begin
    result = run_system_interaction_surface_from_config()
    @test result.experiment_id == "system-interaction-surface-v2"
    @test result.arithmetic == "Rational{BigInt}"
    @test result.randomness == "none"
    @test length(result.rows) == 2430
    @test sum(values(result.counts)) == length(result.rows)
    @test result.counts.substitutes > 0
    @test result.counts.complements > 0
    @test result.counts.separable > 0
    @test all(values(result.checks))

    substitution = result.witnesses.substitution
    @test substitution.closure_increment0 == 2
    @test substitution.closure_increment1 == 1
    @test substitution.interaction == -1
    @test substitution.classification == :substitutes

    independent = result.witnesses.independent_switch
    @test independent.old_premium0 == 3
    @test independent.added_premium0 == 5 // 2
    @test independent.old_premium1 == 0
    @test independent.added_premium1 == 1 // 2
    @test independent.closure_increment0 == 0
    @test independent.closure_increment1 == 1 // 2
    @test independent.interaction == 1 // 2
    @test independent.classification == :complements

    @test result.witnesses.dependent_success_interaction == 1 // 2
    @test result.witnesses.separable_interaction == 0

    fixtures = Dict(row.fixture_id => row for row in result.fixtures)
    @test length(fixtures) == 5
    @test fixtures["primitive_strict_substitution"].interaction == -1
    @test fixtures["saturation_boundary"].interaction == 0
    @test fixtures["optimizer_switching_complementarity"].interaction == 1 // 2
    @test fixtures["frontier_dependent_success_complementarity"].interaction ==
          1 // 2
    @test fixtures["separable_zero_interaction"].interaction == 0
    @test all(row -> row.all_corners_realizable, values(fixtures))
    @test fixtures[
        "primitive_strict_substitution"
    ].primitive_sufficient_conditions_hold
    @test fixtures["saturation_boundary"].primitive_sufficient_conditions_hold
    @test !fixtures[
        "optimizer_switching_complementarity"
    ].primitive_sufficient_conditions_hold
    @test !fixtures[
        "frontier_dependent_success_complementarity"
    ].primitive_sufficient_conditions_hold
    @test fixtures[
        "separable_zero_interaction"
    ].primitive_sufficient_conditions_hold

    switching = fixtures["optimizer_switching_complementarity"]
    @test (
        switching.selected_low_poor,
        switching.selected_low_rich,
        switching.selected_high_poor,
        switching.selected_high_rich,
    ) == ("Old", "Old", "Continue", "Added-1")
    dependent = fixtures["frontier_dependent_success_complementarity"]
    @test (
        dependent.selected_low_poor,
        dependent.selected_low_rich,
        dependent.selected_high_poor,
        dependent.selected_high_rich,
    ) == ("Continue", "Continue", "Continue", "Added-1")

    @test length(result.response_rows) == 3456
    @test result.response_counts.total_rows == 3456
    @test result.response_counts.realizable_rectangles == 576
    @test result.response_counts.excluded_nonrealizable_rectangles == 2880
    @test result.response_counts.eligible_substitutes == 156
    @test result.response_counts.eligible_complements == 183
    @test result.response_counts.eligible_separable == 237
    @test result.response_counts.primitive_rows == 192
    @test result.response_counts.primitive_positive_interactions == 0
    @test all(
        row ->
            row.sign_aggregation_eligible == row.all_corners_realizable,
        result.response_rows,
    )
    @test all(
        row ->
            !row.primitive_sufficient_conditions_hold || row.interaction <= 0,
        result.response_rows,
    )
    @test any(row -> !row.realizable_low_poor, result.response_rows)
    @test any(row -> !row.realizable_high_rich, result.response_rows)
    @test any(
        row ->
            row.selected_low_rich != row.selected_high_rich &&
            row.all_corners_realizable,
        result.response_rows,
    )
    @test result.response_axes.frontiers == ExactRational[0, 2, 4, 8]
    @test result.response_axes.closure_richness == [1, 2]
    @test result.response_axes.project_costs == ExactRational[0, 1]
    @test result.response_axes.admission_probabilities ==
          ExactRational[1 // 2, 1]
    @test result.response_axes.descendant_payoffs == ExactRational[4, 10]
    @test result.response_axes.incumbent_operating_rewards ==
          ExactRational[0, 2, 4, 8]
    @test result.response_axes.durations == [1, 2]
    @test result.response_axes.generator_quality_dependence ==
          ExactRational[0, 1, 2]

    value = (frontier, rich) -> frontier + (rich ? 2 // 1 : 0 // 1)
    @test closure_increment(value, 3 // 1, true, false) == 2
    @test interaction_cross_difference(
        value,
        3 // 1,
        0 // 1,
        true,
        false,
    ) == 0

    @test_throws ArgumentError frontier_closure_interaction_surface(
        ExactRational[0, 1],
        ExactRational[2],
        ExactRational[1],
        ExactRational[1],
        ExactRational[0],
        ExactRational[0];
        discount = ExactRational(3 // 2),
    )
    @test_throws ArgumentError frontier_closure_interaction_surface(
        ExactRational[0, 1],
        ExactRational[2],
        ExactRational[1],
        ExactRational[-1 // 2],
        ExactRational[0],
        ExactRational[0];
        discount = ExactRational(1 // 2),
    )
    @test_throws ArgumentError run_system_interaction_surface(durations = [0])

    mktempdir() do directory
        outputs = write_system_interaction_outputs(result; output_dir = directory)
        @test isfile(outputs.csv)
        @test isfile(outputs.fixtures)
        @test isfile(outputs.response)
        @test isfile(outputs.summary)
        @test read(outputs.csv, String) ==
              render_system_interaction_csv(result)
        @test read(outputs.fixtures, String) ==
              render_system_interaction_fixtures_csv(result)
        @test read(outputs.response, String) ==
              render_system_interaction_response_csv(result)
        @test read(outputs.summary, String) ==
              render_system_interaction_summary(result)
        @test countlines(outputs.csv) == 2431
        @test countlines(outputs.fixtures) == 6
        @test countlines(outputs.response) == 3457
        @test occursin(
            "selected_low_poor,selected_low_rich,selected_high_poor," *
            "selected_high_rich",
            read(outputs.response, String),
        )
        @test occursin(
            "primitive_sufficient_conditions_hold",
            read(outputs.response, String),
        )
        @test occursin("\"row_count\": 2430", read(outputs.summary, String))
        @test occursin(
            "\"excluded_nonrealizable_rectangles\": 2880",
            read(outputs.summary, String),
        )
        @test occursin(
            "\"realizable_rectangles\": 576",
            read(outputs.summary, String),
        )
    end
end
