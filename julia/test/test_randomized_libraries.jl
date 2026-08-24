@testset "randomized finite-library design contract" begin
    first_design = randomized_library_factor_design(9, 41)
    second_design = randomized_library_factor_design(9, 41)
    @test first_design == second_design
    @test length(first_design) == 9
    for field in (
        :belief_count,
        :strategy_count,
        :module_count,
        :module_overlap,
        :closure_structure,
        :frontier_density,
        :candidate_quality,
        :generator_complementarity,
        :research_cost,
        :project_delay,
        :admission_probability,
        :regime_persistence,
    )
        counts = [
            count(
                parameters -> getfield(parameters, field) == level,
                first_design,
            ) for level in unique(
                getfield(parameters, field) for parameters in first_design
            )
        ]
        @test length(counts) == 3
        @test all(==(3), counts)
    end
    @test_throws ArgumentError randomized_library_factor_design(10, 41)
    @test_throws ArgumentError RandomizedLibraryParameters(
        trial_id = 1,
        seed = 1,
        belief_count = 1,
        strategy_count = 4,
        module_count = 3,
        module_overlap = :low,
        closure_structure = :identity,
        frontier_density = 1 // 2,
        candidate_quality = 1,
        generator_complementarity = 1,
        research_cost = 0,
        project_delay = 1,
        admission_probability = 1 // 2,
        regime_persistence = 1 // 2,
    )
end

@testset "randomized raw-library exact loss fixture" begin
    parameters = RandomizedLibraryParameters(
        trial_id = 5,
        seed = 3964027497,
        belief_count = 2,
        strategy_count = 5,
        module_count = 4,
        module_overlap = :low,
        closure_structure = :hierarchy,
        frontier_density = 1 // 4,
        candidate_quality = 1,
        generator_complementarity = 2,
        research_cost = 0,
        project_delay = 3,
        admission_probability = 1 // 2,
        regime_persistence = 1 // 4,
    )
    result = run_randomized_library_trial(
        parameters;
        horizon = 4,
        operational_budget_fraction = 1 // 10,
        generative_budget_fraction = 1 // 20,
    )
    frontier = only(
        row for row in result.pruning_rows if row.method == :frontier_only
    )
    safe = only(
        row for row in result.pruning_rows if row.method == :innovation_safe
    )
    @test frontier.signed_operational_loss == 0
    @test frontier.signed_generative_loss == 27 // 256
    @test frontier.signed_total_dynamic_loss == 27 // 256
    @test safe.signed_total_dynamic_loss == 0
    @test result.trial_row.frontier_closure_J == -189 // 512
    @test result.trial_row.interaction_classification == :substitution
    @test result.trial_row.genuine_closure_contrast
    @test !result.trial_row.theorem_evidence
    @test result.trial_row.all_decomposition_gates
    @test result.trial_row.frontier_passive_gate
    @test result.trial_row.safe_value_gate
    @test result.trial_row.operational_budget_gate
    @test result.trial_row.generative_budget_gate
end

@testset "randomized stress source rows and deterministic gates" begin
    design = randomized_library_factor_design(3, 73)
    first_result = run_randomized_library_stress(design)
    second_result = run_randomized_library_stress(design)
    @test first_result.trial_rows == second_result.trial_rows
    @test first_result.pruning_rows == second_result.pruning_rows
    @test first_result.carrier_rows == second_result.carrier_rows
    @test first_result.profile_rows == second_result.profile_rows
    @test first_result.module_rows == second_result.module_rows
    @test first_result.closure_rows == second_result.closure_rows
    @test first_result.kernel_rows == second_result.kernel_rows
    @test first_result.project_rows == second_result.project_rows
    @test length(first_result.trial_rows) == 3
    @test length(first_result.pruning_rows) == 12
    @test length(first_result.project_rows) == 6
    @test all(row.decomposition_gate for row in first_result.pruning_rows)
    @test all(row.decomposition_gate for row in first_result.carrier_rows)
    @test all(row.safe_value_gate for row in first_result.trial_rows)
    @test all(!row.theorem_evidence for row in first_result.trial_rows)
end

@testset "randomized-library committed artifacts" begin
    experiment = run_randomized_library_stress_experiment()
    @test experiment.experiment_id == "randomized-finite-library-stress-v1"
    @test length(experiment.result.trial_rows) == 90
    @test length(experiment.result.pruning_rows) == 360
    @test length(experiment.method_summary) == 4
    @test length(experiment.factor_summary) == 36
    @test all(values(experiment.gates))
    @test experiment.prevalence.frontier_loss.count == 8
    @test experiment.prevalence.frontier_loss.frequency == 4 // 45
    @test experiment.prevalence.carrier.count == 3
    @test experiment.prevalence.substitution.count == 13
    @test experiment.prevalence.complementarity.count == 0

    report = render_randomized_library_report(experiment)
    method_figure = render_method_figure(experiment)
    prevalence_figure = render_prevalence_figure(experiment)
    factor_figure = render_factor_figure(experiment)
    @test occursin("Random search is not used as proof", report)
    @test occursin("8/90 cases (8.9%)", report)
    @test occursin("Pruning trade-offs", method_figure)
    @test occursin("Observed mechanism prevalence", prevalence_figure)
    @test occursin("Frontier-only loss frequency", factor_figure)

    artifacts =
        RandomizedLibraryStressExperiment._artifact_contents(experiment)
    for (relative_path, content) in artifacts
        path = joinpath(
            RandomizedLibraryStressExperiment.REPOSITORY_ROOT,
            relative_path,
        )
        @test isfile(path)
        @test read(path, String) == content
    end
end
