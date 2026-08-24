const FLOAT64_ARTIFACT_ATOL = 2e-12
const FLOAT64_ARTIFACT_RTOL = 2e-12
const FLOAT64_ARTIFACT_NUMBER = r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?"

function _csv_rows(text)
    return [split(line, ','; keepempty = true) for line in split(chomp(text), '\n')]
end

"""Compare a rendered Float64 CSV while retaining exact nonnumeric fields."""
function _float64_csv_equivalent(
    committed,
    generated,
    approximate_columns;
    atol = FLOAT64_ARTIFACT_ATOL,
    rtol = FLOAT64_ARTIFACT_RTOL,
)
    committed_rows = _csv_rows(committed)
    generated_rows = _csv_rows(generated)
    length(committed_rows) == length(generated_rows) || return false
    isempty(committed_rows) && return true
    committed_rows[1] == generated_rows[1] || return false

    header = committed_rows[1]
    approximate_names = Set(string.(approximate_columns))
    all(name -> name in header, approximate_names) || return false
    approximate_indices = Set(findall(name -> name in approximate_names, header))

    for (committed_row, generated_row) in
        zip(committed_rows[2:end], generated_rows[2:end])
        length(committed_row) == length(header) || return false
        length(generated_row) == length(header) || return false
        for column_index in eachindex(header)
            committed_cell = committed_row[column_index]
            generated_cell = generated_row[column_index]
            committed_cell == generated_cell && continue
            column_index in approximate_indices || return false
            committed_value = tryparse(Float64, committed_cell)
            generated_value = tryparse(Float64, generated_cell)
            isnothing(committed_value) && return false
            isnothing(generated_value) && return false
            isapprox(
                committed_value,
                generated_value;
                atol,
                rtol,
                nans = false,
            ) || return false
        end
    end
    return true
end

"""Compare SVG structure exactly and platform-sensitive numeric tokens closely."""
function _float64_svg_equivalent(
    committed,
    generated;
    atol = FLOAT64_ARTIFACT_ATOL,
    rtol = FLOAT64_ARTIFACT_RTOL,
)
    replace(committed, FLOAT64_ARTIFACT_NUMBER => "#") ==
        replace(generated, FLOAT64_ARTIFACT_NUMBER => "#") || return false
    committed_numbers = [
        parse(Float64, match.match) for
        match in eachmatch(FLOAT64_ARTIFACT_NUMBER, committed)
    ]
    generated_numbers = [
        parse(Float64, match.match) for
        match in eachmatch(FLOAT64_ARTIFACT_NUMBER, generated)
    ]
    length(committed_numbers) == length(generated_numbers) || return false
    return all(
        isapprox(
            committed_number,
            generated_number;
            atol,
            rtol,
            nans = false,
        ) for (committed_number, generated_number) in
            zip(committed_numbers, generated_numbers)
    )
end

@testset "unified comparative-statics parameter contract" begin
    exact = UnifiedComparativeParameters()
    @test exact.frontier_level isa ExactRational
    @test exact.research_duration == 1
    float = UnifiedComparativeParameters(; mode = Float64Mode())
    @test float.frontier_level isa Float64
    @test with_comparative_parameter(float, :research_cost, 2.0).research_cost == 2.0
    @test with_comparative_parameter(float, :research_duration, 3).research_duration == 3
    @test_throws ArgumentError with_comparative_parameter(
        exact,
        :research_cost,
        0.5,
    )
    @test_throws ArgumentError with_comparative_parameter(
        float,
        :unknown_parameter,
        0.5,
    )
    @test_throws ArgumentError UnifiedComparativeParameters(
        admission_probability = 3 // 2,
    )
    @test_throws ArgumentError UnifiedComparativeParameters(
        research_duration = 0,
    )
    @test_throws ArgumentError UnifiedComparativeParameters(
        generator_frontier_dependence = 2,
    )
    @test_throws ArgumentError ComparativeStaticsConfig(belief_count = 0)
    @test_throws ArgumentError ComparativeStaticsConfig(
        mode = Float64Mode(),
        belief_count = 5,
        reference_index = 6,
    )
    @test_throws ArgumentError ComparativeStaticsConfig(value_tolerance = 1 // 100)
end

@testset "exact comparative statics use the raw source of truth" begin
    parameters = UnifiedComparativeParameters(
        frontier_level = 0,
        frontier_density = 1,
        closure_richness = 1,
        module_overlap = 0,
        research_cost = 0,
        research_duration = 1,
        admission_probability = 1,
        candidate_survival = 1,
        discount_factor = 1 // 2,
        belief_kernel_persistence = 1,
        signal_precision_proxy = 0,
        candidate_profile_quality = 2,
    )
    config = ComparativeStaticsConfig(
        belief_count = 1,
        reference_index = 1,
        finite_horizon = 2,
    )
    bundle = build_exact_comparative_process(parameters, config)
    @test bundle.process isa RawInnovationProcess
    @test compressed_library_state(
        bundle.catalog,
        bundle.closure,
        raw_library_update(bundle.process, bundle.base, bundle.success),
    ) == compressed_state_update(
        bundle.process,
        compressed_library_state(bundle.catalog, bundle.closure, bundle.base),
        bundle.success,
    )

    result = run_unified_comparative_statics(parameters, config)
    @test result.raw_source_of_truth
    @test !result.sparse_mode
    @test result.total_value == 2
    @test result.passive_value == 0
    @test result.research_option_premium == 2
    @test result.optimal_action == :research
    @test result.research_frequency == 1
    @test result.pruning_loss == 2
    @test result.compression_ratio == 1 // 4
    @test result.descendant_quality == 2
    @test result.bellman_residual == 0
    @test result.value_error_bound == 0
    @test result.gate_passed
end

@testset "exact comparative-static Lean fixtures" begin
    fixtures = exact_comparative_statics_fixtures()
    @test fixtures.all_passed
    @test length(fixtures.rows) == 8
    @test Set(row.theorem_id for row in fixtures.rows) ==
          Set(("T4", "S2", "T6", "S6", "S7", "T7", "T7 boundary"))
    @test all(row.passed for row in fixtures.rows)
    @test only(
        row for row in fixtures.rows if
        row.fixture_id == "FX-T4-UNIFIED-01"
    ).observed == "1//1"
    @test only(
        row for row in fixtures.rows if
        row.fixture_id == "CX-T7-INDEPENDENT-MENU-SWITCH-02"
    ).observed == "1//2"
end

@testset "sparse Float64 comparative-static solver and gates" begin
    parameters = UnifiedComparativeParameters(
        mode = Float64Mode(),
        research_cost = 2.5,
    )
    config = ComparativeStaticsConfig(
        mode = Float64Mode(),
        belief_count = 41,
        reference_index = 21,
        finite_horizon = 6,
    )
    first_result = run_unified_comparative_statics(parameters, config)
    second_result = run_unified_comparative_statics(parameters, config)
    @test first_result.sparse_mode
    @test first_result.raw_source_of_truth
    @test first_result.converged
    @test first_result.gate_passed
    @test first_result.bellman_residual <= config.residual_gate
    @test first_result.value_error_bound <= config.error_gate
    @test first_result.total_value == second_result.total_value
    @test first_result.policy == second_result.policy
    @test first_result.frontier_closure_cross_difference ==
          second_result.frontier_closure_cross_difference
    @test first_result.total_value ≈
          first_result.passive_value + first_result.research_option_premium
    @test first_result.pruning_loss ≈ first_result.research_option_premium
    @test first_result.flags.persistence_has_no_universal_sign
    @test first_result.flags.bellman_cutoff_is_numerical_only
    @test first_result.cutoff_kind == :lower
    @test !isnothing(first_result.research_cutoff)

    canonical_float = UnifiedComparativeParameters(
        mode = Float64Mode(),
        frontier_level = 0.0,
        frontier_density = 1.0,
        closure_richness = 1.0,
        module_overlap = 0.0,
        research_cost = 0.0,
        research_duration = 1,
        admission_probability = 1.0,
        candidate_survival = 1.0,
        discount_factor = 0.5,
        belief_kernel_persistence = 1.0,
        signal_precision_proxy = 0.0,
        candidate_profile_quality = 2.0,
    )
    canonical_float_config = ComparativeStaticsConfig(
        mode = Float64Mode(),
        belief_count = 1,
        reference_index = 1,
        finite_horizon = 2,
    )
    canonical_float_result = run_unified_comparative_statics(
        canonical_float,
        canonical_float_config,
    )
    @test canonical_float_result.total_value ≈ 2.0 atol = 1e-9
    @test canonical_float_result.optimal_action == :research

    dependent = run_unified_comparative_statics(
        with_comparative_parameter(
            parameters,
            :generator_frontier_dependence,
            0.5,
        ),
        config,
    )
    @test dependent.flags.frontier_dependent_generator

    failed_config = ComparativeStaticsConfig(
        mode = Float64Mode(),
        belief_count = 21,
        reference_index = 11,
        max_iterations = 1,
        value_tolerance = 0.0,
        residual_gate = 0.0,
        error_gate = 0.0,
    )
    failed = run_unified_comparative_statics(parameters, failed_config)
    @test !failed.converged
    @test !failed.gate_passed
    @test failed.flags.bellman_gate_failed
end

@testset "assumption-gated comparative-static signs" begin
    parameters = UnifiedComparativeParameters(
        mode = Float64Mode(),
        research_cost = 2.5,
    )
    config = ComparativeStaticsConfig(
        mode = Float64Mode(),
        belief_count = 21,
        reference_index = 11,
        finite_horizon = 5,
    )
    checks = run_comparative_static_sign_checks(parameters, config)
    @test length(checks) == 11
    @test all(check.passed for check in checks)
    @test all(check.passed for check in checks if check.applicable)
    @test only(
        check for check in checks if check.check_id == :persistence_direction
    ).boundary_flag == :persistence_unaligned
    @test !only(
        check for check in checks if check.check_id == :frontier_closure_J
    ).applicable

    dependent_checks = run_comparative_static_sign_checks(
        with_comparative_parameter(
            parameters,
            :generator_frontier_dependence,
            0.5,
        ),
        config,
    )
    @test !only(
        check for check in dependent_checks if check.check_id == :frontier_value
    ).applicable
end

@testset "unified comparative-statics artifacts" begin
    @test _float64_csv_equivalent(
        "label,value\nrow,1\n",
        "label,value\nrow,1.000000000001\n",
        (:value,),
    )
    @test !_float64_csv_equivalent(
        "label,value\nrow,1\n",
        "changed,value\nrow,1.000000000001\n",
        (:value,),
    )
    @test !_float64_csv_equivalent(
        "label,value\nrow,1\n",
        "label,value\nrow,1.0001\n",
        (:value,),
    )

    result = run_unified_comparative_statics_experiment()
    @test result.experiment_id == "unified-comparative-statics-v1"
    @test length(result.response_rows) == 78
    @test length(result.interaction_rows) == 36
    @test length(result.sign_checks) == 11
    @test all(values(result.checks))

    response = render_response_csv(result)
    interaction = render_interaction_csv(result)
    signs = render_sign_checks_csv(result)
    fixtures = render_exact_fixtures_csv(result)
    summary = render_summary_json(result)
    value_figure = render_value_figure(result)
    policy_figure = render_policy_figure(result)
    @test count(==('\n'), response) == 79
    @test count(==('\n'), interaction) == 37
    @test count(==('\n'), signs) == 12
    @test count(==('\n'), fixtures) == 9
    @test occursin("\"response_row_count\": 78", summary)
    @test occursin("viewBox=\"0 0 1000 650\"", value_figure)
    @test occursin("Policy and frontier", policy_figure)

    root = normpath(joinpath(@__DIR__, "..", ".."))
    committed = (
        response = joinpath(
            root,
            "experiments",
            "results",
            "summaries",
            "unified_comparative_statics_surface.csv",
        ),
        interaction = joinpath(
            root,
            "experiments",
            "results",
            "summaries",
            "unified_comparative_statics_interaction.csv",
        ),
        signs = joinpath(
            root,
            "experiments",
            "results",
            "summaries",
            "unified_comparative_statics_sign_checks.csv",
        ),
        fixtures = joinpath(
            root,
            "experiments",
            "results",
            "summaries",
            "unified_comparative_statics_exact_fixtures.csv",
        ),
        summary = joinpath(
            root,
            "experiments",
            "results",
            "summaries",
            "unified_comparative_statics_summary.json",
        ),
        value_figure = joinpath(
            root,
            "manuscript",
            "figures",
            "unified_comparative_statics_value.svg",
        ),
        policy_figure = joinpath(
            root,
            "manuscript",
            "figures",
            "unified_comparative_statics_policy.svg",
        ),
    )
    @test _float64_csv_equivalent(
        read(committed.response, String),
        response,
        (
            :total_value,
            :passive_value,
            :research_option_premium,
            :operational_innovation,
            :generative_innovation,
            :research_frequency,
            :research_cutoff,
            :pruning_loss,
            :compression_ratio,
            :descendant_quality,
            :frontier_closure_cross_difference,
            :bellman_residual,
            :value_error_bound,
        ),
    )
    @test _float64_csv_equivalent(
        read(committed.interaction, String),
        interaction,
        (
            :total_value,
            :research_option_premium,
            :research_frequency,
            :interaction,
        ),
    )
    @test read(committed.signs, String) == signs
    @test read(committed.fixtures, String) == fixtures
    @test read(committed.summary, String) == summary
    @test _float64_svg_equivalent(
        read(committed.value_figure, String),
        value_figure,
    )
    @test read(committed.policy_figure, String) == policy_figure
end
