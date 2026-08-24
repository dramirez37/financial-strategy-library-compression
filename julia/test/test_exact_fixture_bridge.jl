@testset "Lean–Julia exact fixture bridge" begin
    fixtures = build_exact_fixtures()
    fixture_ids = [fixture.fixture_id for fixture in fixtures]
    @test fixture_ids == sort(fixture_ids)
    @test fixture_ids == [
        "current_zero_future_positive",
        "discount_survival_complementarity",
        "frontier_closure_complementarity",
        "frontier_closure_substitution",
        "frontier_pruning_loss",
        "generative_lower_bound",
        "monotone_gap_threshold",
        "multi_gap_disconnected_region",
        "multi_gap_disconnection",
        "normalized_pruning_loss",
        "operational_generative_decomposition",
        "persistence_decreases_coverage",
        "persistence_increases_coverage",
        "raw_compressed_transition_identity",
        "raw_compressed_value_equality",
        "safe_deletion",
        "single_gap_research_region",
        "strategy_innovation_equation",
    ]
    @test all(fixture -> fixture.schema_version == BRIDGE_SCHEMA_VERSION, fixtures)
    @test all(fixture -> eltype(fixture.transition_rows) == ExactRational, fixtures)
    @test all(fixture -> validate_fixture(fixture) === fixture, fixtures)

    rendered_once = render_generated_lean(fixtures)
    rendered_twice = render_generated_lean(reverse(fixtures))
    @test rendered_once == rendered_twice
    @test occursin("examples below are kernel-checked fixture calculations", rendered_once)
    @test !occursin("native_decide", rendered_once)
    @test !occursin("sorry", rendered_once)

    repository_root = normpath(joinpath(@__DIR__, "..", ".."))
    generated_lean = joinpath(
        repository_root,
        "formal",
        "StrategyInnovation",
        "Fixtures",
        "Generated.lean",
    )
    @test read(generated_lean, String) == rendered_once
    for fixture in fixtures
        rendered_json = render_fixture_json(fixture)
        json_path = joinpath(
            repository_root,
            "shared",
            "exact_fixtures",
            fixture.fixture_id * ".json",
        )
        @test read(json_path, String) == rendered_json
        @test occursin("\"schema_version\": \"lean-julia-exact-fixture-v2\"", rendered_json)
        @test occursin(r"\"-?[0-9]+//[1-9][0-9]*\"", rendered_json)
    end
    @test isempty(write_exact_fixtures(; repository_root, check = true).changed)

    by_id = Dict(fixture.fixture_id => fixture for fixture in fixtures)
    transition = by_id["raw_compressed_transition_identity"].expected
    @test Dict(transition.boolean_scalars)["transition_law_equal"]
    @test Dict(transition.rational_vectors)["raw_projected_probabilities"] ==
          Dict(transition.rational_vectors)["compressed_probabilities"]
    @test Dict(transition.rational_vectors)["raw_projected_terminal_frontiers"] ==
          Dict(transition.rational_vectors)["compressed_terminal_frontiers"]

    values = by_id["raw_compressed_value_equality"].expected
    @test Dict(values.boolean_scalars)["finite_values_equal"]
    @test Dict(values.boolean_scalars)["infinite_values_equal"]
    @test Dict(values.boolean_scalars)["stationary_actions_equal"]
    @test Dict(values.rational_scalars)["raw_infinite_value"] == 4 // 3
    @test Dict(values.rational_scalars)["raw_bellman_residual"] == 0
    @test Dict(values.rational_vectors)["raw_finite_values_horizon_zero_to_five"] ==
          Dict(values.rational_vectors)["compressed_finite_values_horizon_zero_to_five"]

    deletion = by_id["safe_deletion"].expected
    @test Dict(deletion.boolean_scalars)["compressed_state_equal"]
    @test Dict(deletion.boolean_scalars)["operationally_redundant"]
    @test Dict(deletion.boolean_scalars)["generatively_redundant"]

    pruning = by_id["normalized_pruning_loss"].expected
    @test Dict(pruning.rational_scalars)["value_loss"] == 1
    @test Dict(pruning.rational_scalars)["normalized_pruning_loss"] == 1
    @test Dict(pruning.boolean_scalars)["frontier_preserved"]

    decomposition = by_id["operational_generative_decomposition"].expected
    @test Dict(decomposition.rational_scalars)["total_increment"] ==
          Dict(decomposition.rational_scalars)["operational_component"] +
          Dict(decomposition.rational_scalars)["generative_component"]

    lower_bound = by_id["generative_lower_bound"].expected
    @test Dict(lower_bound.rational_scalars)["lower_bound"] == 1
    @test Dict(lower_bound.boolean_scalars)["lower_bound_positive"]

    interaction = by_id["discount_survival_complementarity"].expected
    @test Dict(interaction.rational_vectors)["cross_difference"] ==
          ExactRational[43771 // 55296, 24869 // 27648]
    @test Dict(interaction.boolean_scalars)["factorization_holds"]
    @test Dict(interaction.boolean_scalars)["cross_difference_nonnegative"]

    persistence_up = by_id["persistence_increases_coverage"].expected
    @test Dict(persistence_up.rational_scalars)["coverage_low_persistence"] == 9 // 8
    @test Dict(persistence_up.rational_scalars)["coverage_high_persistence"] == 11 // 8
    @test Dict(persistence_up.boolean_scalars)["coverage_increases"]
    persistence_down = by_id["persistence_decreases_coverage"].expected
    @test Dict(persistence_down.rational_scalars)["coverage_low_persistence"] == 3 // 8
    @test Dict(persistence_down.rational_scalars)["coverage_high_persistence"] == 1 // 8
    @test Dict(persistence_down.boolean_scalars)["coverage_decreases"]

    substitution = by_id["frontier_closure_substitution"].expected
    @test Dict(substitution.rational_scalars)["cross_difference"] == -1
    @test Dict(substitution.boolean_scalars)["is_substitution"]
    complementarity = by_id["frontier_closure_complementarity"].expected
    @test Dict(complementarity.rational_scalars)["cross_difference"] == 1 // 2
    @test Dict(complementarity.boolean_scalars)["is_complementarity"]

    threshold = by_id["monotone_gap_threshold"].expected
    @test Dict(threshold.boolean_vectors)["research_region"] ==
          [false, false, true, true]
    @test Dict(threshold.boolean_scalars)["upper_threshold"]
    @test Dict(threshold.rational_scalars)["threshold_cutoff_index"] == 3
    multi_gap = by_id["multi_gap_disconnection"].expected
    @test Dict(multi_gap.boolean_vectors)["research_region"] ==
          [true, true, false, true, true]

    legacy_pruning = by_id["frontier_pruning_loss"].expected
    @test Dict(legacy_pruning.rational_scalars)["research_value_loss"] == 5
    legacy_equation = by_id["strategy_innovation_equation"].expected
    @test Dict(legacy_equation.rational_vectors)["discounted_gap_sum_horizon_three"] ==
          ExactRational[5 // 2, 7 // 2]
    legacy_delayed = by_id["current_zero_future_positive"].expected
    @test Dict(legacy_delayed.rational_scalars)["initial_innovation_value"] == 1
    legacy_single = by_id["single_gap_research_region"].expected
    @test Dict(legacy_single.boolean_vectors)["research_region"] ==
          [true, false, true]
    legacy_multi = by_id["multi_gap_disconnected_region"].expected
    @test Dict(legacy_multi.boolean_vectors)["research_region"] ==
          Dict(multi_gap.boolean_vectors)["research_region"]

    valid = by_id["safe_deletion"]
    invalid_kernel = copy(valid.transition_rows)
    invalid_kernel[1, 1] = -1 // 1
    invalid_kernel[1, 2] = 2 // 1
    bad_kernel = ExactBridgeFixture(
        valid.schema_version,
        valid.fixture_id,
        valid.theorem_family,
        valid.beliefs,
        invalid_kernel,
        valid.discount,
        valid.modules,
        valid.strategies,
        valid.libraries,
        valid.projects,
        valid.expected,
    )
    @test_throws ArgumentError validate_fixture(bad_kernel)

    duplicate_strategies = ExactBridgeFixture(
        valid.schema_version,
        valid.fixture_id,
        valid.theorem_family,
        valid.beliefs,
        valid.transition_rows,
        valid.discount,
        valid.modules,
        [valid.strategies; valid.strategies[end]],
        valid.libraries,
        valid.projects,
        valid.expected,
    )
    @test_throws ArgumentError validate_fixture(duplicate_strategies)

    bad_discount = ExactBridgeFixture(
        valid.schema_version,
        valid.fixture_id,
        valid.theorem_family,
        valid.beliefs,
        valid.transition_rows,
        exact_rational(2),
        valid.modules,
        valid.strategies,
        valid.libraries,
        valid.projects,
        valid.expected,
    )
    @test_throws ArgumentError validate_fixture(bad_discount)

    project = only(valid.projects)
    zero_duration = ExactFixtureExporter.FixtureProject(
        project.id,
        project.cost,
        0,
        project.survival,
        project.strict_cost,
        project.required_modules,
        project.candidate_strategies,
    )
    bad_duration = ExactBridgeFixture(
        valid.schema_version,
        valid.fixture_id,
        valid.theorem_family,
        valid.beliefs,
        valid.transition_rows,
        valid.discount,
        valid.modules,
        valid.strategies,
        valid.libraries,
        [zero_duration],
        valid.expected,
    )
    @test_throws ArgumentError validate_fixture(bad_duration)

    unresolved_strategy = ExactFixtureExporter.FixtureStrategy(
        "unresolved",
        ExactRational[0, 0],
        ["missing_module"],
    )
    bad_reference = ExactBridgeFixture(
        valid.schema_version,
        valid.fixture_id,
        valid.theorem_family,
        valid.beliefs,
        valid.transition_rows,
        valid.discount,
        valid.modules,
        [valid.strategies; unresolved_strategy],
        valid.libraries,
        valid.projects,
        valid.expected,
    )
    @test_throws ArgumentError validate_fixture(bad_reference)
end
