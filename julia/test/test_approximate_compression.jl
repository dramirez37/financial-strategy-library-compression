function _approximate_compression_fixture()
    parameters = RandomizedLibraryParameters(
        trial_id = 15,
        seed = 731700466,
        belief_count = 4,
        strategy_count = 6,
        module_count = 3,
        module_overlap = :low,
        closure_structure = :identity,
        frontier_density = 1 // 2,
        candidate_quality = 5 // 4,
        generator_complementarity = 2,
        research_cost = 0,
        project_delay = 2,
        admission_probability = 1 // 4,
        regime_persistence = 1 // 4,
    )
    model = build_randomized_library_model(parameters)
    problem = ApproximateCompressionProblem(
        model.process,
        model.source;
        horizon = 4,
        reference_belief = first(model.kernel.space),
        epsilon_operational = 1,
        epsilon_generative = 1 // 4,
    )
    return (; parameters, model, problem)
end

@testset "approximate compression loss definitions" begin
    fixture = _approximate_compression_fixture()
    problem = fixture.problem
    source = approximate_compression_losses(problem, fixture.model.source)
    @test source.operational_loss == 0
    @test source.operating_value_loss == 0
    @test source.generative_loss == 0
    @test source.value_loss == 0
    @test source.feasible
    @test source.decomposition_gate

    inactive = RawLibrary(
        fixture.model.catalog,
        [fixture.model.catalog.inactive_strategy],
    )
    deleted = approximate_compression_losses(problem, inactive)
    @test deleted.operational_loss == 4
    @test deleted.operating_value_loss == 175 // 16
    @test deleted.generative_loss == 10071 // 32768
    @test deleted.value_loss == 368471 // 32768
    @test deleted.value_loss ==
          deleted.operating_value_loss + deleted.generative_loss
    @test !deleted.feasible
    @test raw_passive_finite_horizon_value(
        fixture.model.process,
        0,
        first(fixture.model.kernel.space),
        fixture.model.source,
    ) == 0
    @test raw_passive_finite_horizon_value(
        fixture.model.process,
        4,
        first(fixture.model.kernel.space),
        fixture.model.source,
    ) == 175 // 16

    @test_throws ArgumentError ApproximateCompressionProblem(
        fixture.model.process,
        fixture.model.source;
        horizon = 0,
    )
    @test_throws ArgumentError ApproximateCompressionProblem(
        fixture.model.process,
        fixture.model.source;
        horizon = 4,
        epsilon_operational = -1,
    )
    outside = insert_strategy(
        fixture.model.catalog,
        fixture.model.source,
        first(fixture.model.candidate_ids),
    )
    @test_throws ArgumentError approximate_compression_losses(problem, outside)
end

@testset "exact subset optimizer and Pareto frontier" begin
    fixture = _approximate_compression_fixture()
    result = enumerate_approximate_compressions(fixture.problem)
    solution = result.solution
    @test length(result.records) == 32
    @test length(result.pareto_records) == 5
    @test solution.method == :exact_enumeration
    @test solution.exact
    @test solution.optimal
    @test solution.evaluated_count == 32
    @test solution.record.retained_size == 3
    @test solution.record.operational_loss == 0
    @test solution.record.generative_loss == 0
    @test solution.record.value_loss == 0
    @test all(record.decomposition_gate for record in result.records)
    @test all(
        !record.feasible || (
            record.operational_loss <= fixture.problem.epsilon_operational &&
            record.generative_loss <= fixture.problem.epsilon_generative
        ) for record in result.records
    )
    @test !any(
        record.feasible && record.retained_size < solution.record.retained_size
        for record in result.records
    )
    @test all(
        !any(
            other.retained_size <= record.retained_size &&
            other.operational_loss <= record.operational_loss &&
            other.generative_loss <= record.generative_loss &&
            (
                other.retained_size < record.retained_size ||
                other.operational_loss < record.operational_loss ||
                other.generative_loss < record.generative_loss
            ) for other in result.records
        ) for record in result.pareto_records
    )
    @test_throws ArgumentError enumerate_approximate_compressions(
        fixture.problem;
        max_optional = 4,
    )
end

@testset "deterministic greedy and Pareto-beam heuristics" begin
    fixture = _approximate_compression_fixture()
    exact = enumerate_approximate_compressions(fixture.problem)
    greedy_rows = [
        greedy_approximate_compression(fixture.problem; criterion) for
        criterion in (:balanced, :operational, :generative, :value)
    ]
    @test all(solution.record.feasible for solution in greedy_rows)
    @test all(solution.record.retained_size == 3 for solution in greedy_rows)
    @test all(!solution.exact && !solution.optimal for solution in greedy_rows)
    @test all(solution.evaluated_count == 15 for solution in greedy_rows)
    generative = only(
        solution for solution in greedy_rows if
        solution.method == :greedy_generative
    )
    @test generative.record.operational_loss == 1
    @test generative.record.generative_loss == -549 // 4096
    @test generative.record.value_loss == 6511 // 4096

    multistart = multistart_greedy_approximate_compression(fixture.problem)
    @test length(multistart.starts) == 4
    @test multistart.solution.record.retained_size ==
          exact.solution.record.retained_size
    @test multistart.solution.evaluated_count == 60

    narrow = pareto_beam_compression(fixture.problem; beam_width = 2)
    complete = pareto_beam_compression(fixture.problem; beam_width = 8)
    @test !narrow.complete
    @test narrow.solution.record.retained_size == 3
    @test narrow.solution.record.feasible
    @test complete.complete
    @test complete.solution.exact
    @test complete.solution.optimal
    @test complete.solution.evaluated_count == 32
    @test complete.solution.record.library == exact.solution.record.library
    @test length(complete.pareto_records) == length(exact.pareto_records)
    @test_throws ArgumentError pareto_beam_compression(
        fixture.problem;
        beam_width = 0,
    )
    @test_throws ArgumentError greedy_approximate_compression(
        fixture.problem;
        criterion = :unsupported,
    )
end

@testset "operational-cover IP and generative lazy cuts" begin
    fixture = _approximate_compression_fixture()
    exact = enumerate_approximate_compressions(fixture.problem)
    formulation = approximate_compression_ip_formulation(
        fixture.problem;
        records = exact.records,
    )
    @test formulation.complete_generative_oracle
    @test formulation.evaluated_count == 32
    @test length(formulation.generative_no_good_cuts) == 11
    @test operational_ip_cardinality_lower_bound(formulation) == 2
    selected = Bool[
        strategy_id in exact.solution.record.library for
        strategy_id in formulation.strategy_ids
    ]
    @test satisfies_approximate_compression_ip_formulation(
        formulation,
        selected,
    )
    violating = first(
        filter(
            record ->
                record.operational_loss <= fixture.problem.epsilon_operational &&
                record.generative_loss > fixture.problem.epsilon_generative &&
                record.retained_size == 2,
            exact.records,
        ),
    )
    violating_selected = Bool[
        strategy_id in violating.library for
        strategy_id in formulation.strategy_ids
    ]
    @test !satisfies_approximate_compression_ip_formulation(
        formulation,
        violating_selected,
    )
    outer = approximate_compression_ip_formulation(fixture.problem)
    @test !outer.complete_generative_oracle
    @test isempty(outer.generative_no_good_cuts)
    source_selected = Bool[
        strategy_id in fixture.model.source for
        strategy_id in outer.strategy_ids
    ]
    @test satisfies_approximate_compression_ip_formulation(
        outer,
        source_selected,
    )
    @test_throws DimensionMismatch satisfies_approximate_compression_ip_formulation(
        formulation,
        [true],
    )
end

@testset "expanded benchmark exact-versus-heuristic regression" begin
    fixture = _approximate_compression_fixture()
    expanded = RawLibrary(
        fixture.model.catalog,
        [row.id for row in fixture.model.catalog.strategies],
    )
    problem = ApproximateCompressionProblem(
        fixture.model.process,
        expanded;
        horizon = 4,
        reference_belief = first(fixture.model.kernel.space),
        epsilon_operational = 1,
        epsilon_generative = 1 // 4,
    )
    exact = enumerate_approximate_compressions(problem)
    @test length(exact.records) == 128
    @test length(exact.pareto_records) == 11
    @test exact.solution.record.retained_size == 2
    @test exact.solution.record.operational_loss == 1 // 2
    @test exact.solution.record.generative_loss == 0
    @test exact.solution.record.value_loss == 2025 // 8192

    for criterion in (:balanced, :operational, :generative, :value)
        greedy = greedy_approximate_compression(problem; criterion)
        @test greedy.record.retained_size == 2
        @test greedy.record.feasible
    end
    beam = pareto_beam_compression(problem; beam_width = 16)
    @test !beam.complete
    @test beam.solution.record.retained_size == 2
    @test beam.solution.record.feasible
    @test beam.solution.evaluated_count == 121

    formulation = approximate_compression_ip_formulation(
        problem;
        records = exact.records,
    )
    @test formulation.complete_generative_oracle
    @test isempty(formulation.generative_no_good_cuts)
    @test operational_ip_cardinality_lower_bound(formulation) == 2
end

@testset "approximate-compression committed artifacts" begin
    experiment = run_approximate_compression_experiment()
    @test experiment.experiment_id == "approximate-library-compression-v1"
    @test length(experiment.subset_rows) == 160
    @test length(experiment.pareto_rows) == 16
    @test length(experiment.algorithm_rows) == 20
    @test length(experiment.ip_rows) == 2
    @test all(values(experiment.gates))
    @test all(row.decomposition_gate for row in experiment.subset_rows)
    @test all(!row.theorem_evidence for row in experiment.subset_rows)

    base = only(
        row for row in experiment.algorithm_rows if
        row.benchmark == "base" && row.method == :exact_enumeration
    )
    expanded = only(
        row for row in experiment.algorithm_rows if
        row.benchmark == "expanded" && row.method == :exact_enumeration
    )
    @test base.retained_size == 3
    @test base.value_loss == 0
    @test expanded.retained_size == 2
    @test expanded.operational_loss == 1 // 2
    @test expanded.generative_loss == 0
    @test expanded.value_loss == 2025 // 8192

    report = render_approximate_compression_report(experiment)
    pareto_figure = render_approximate_pareto_figure(experiment)
    search_figure = render_approximate_search_figure(experiment)
    @test occursin("numerical extension only", report)
    @test occursin("160 subset rows", report)
    @test occursin("Approximate compression loss surface", pareto_figure)
    @test occursin("Exact and heuristic compression solutions", search_figure)

    artifacts = ApproximateCompressionExperiment._artifact_contents(experiment)
    @test length(artifacts) == 8
    for (relative_path, content) in artifacts
        path = joinpath(
            ApproximateCompressionExperiment.REPOSITORY_ROOT,
            relative_path,
        )
        @test isfile(path)
        @test read(path, String) == content
    end
end
