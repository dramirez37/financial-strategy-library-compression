const SELECTED_UNIFIED_CANONICAL_EXPERIMENT =
    run_unified_canonical_benchmark()

@testset "unified canonical benchmark raw-derived solvers" begin
    experiment = SELECTED_UNIFIED_CANONICAL_EXPERIMENT
    process = experiment.fixture.process
    @test process isa RawInnovationProcess
    @test length(process.catalog.strategies) == 4
    @test length(process.raw_libraries) == 8
    @test length(process.compressed_states) == 3
    @test all(project.duration > 0 for project in process.projects)
    @test all(project.operates_during_research for project in process.projects)
    @test !occursin(
        "DiscountedResearchProcess",
        read(
            joinpath(
                @__DIR__,
                "..",
                "scripts",
                "solve_unified_canonical_benchmark.jl",
            ),
            String,
        ),
    )

    @test experiment.raw_stationary.converged
    @test experiment.compressed_stationary.converged
    @test experiment.raw_stationary.iterations == 3
    @test experiment.compressed_stationary.iterations == 3
    @test experiment.raw_stationary.policy_equation_residual == 0
    @test experiment.compressed_stationary.policy_equation_residual == 0
    @test experiment.raw_stationary.bellman_residual == 0
    @test experiment.compressed_stationary.bellman_residual == 0
    @test experiment.exact_evaluation.policy_residual == 0
    @test experiment.exact_evaluation.bellman_residual == 0
    @test experiment.exact_evaluation.values == experiment.exact_values
    @test experiment.exact_values == ExactRational[
        115 // 288,
        23 // 288,
        1 // 1,
        7 // 6,
        14 // 3,
        22 // 3,
    ]
    @test experiment.exact_policy == [
        "research:discover",
        "continue",
        "research:scale",
        "research:scale",
        "continue",
        "continue",
    ]
    @test minimum(experiment.exact_action_margins) == 3 // 16

    correspondence = experiment.correspondence
    @test correspondence.transition_checks == 32
    @test correspondence.finite_value_checks == 144
    @test correspondence.finite_policy_checks == 128
    @test correspondence.stationary_value_checks == 16
    @test correspondence.policy_lift_checks == 16

    @test experiment.float.converged
    @test experiment.float.iterations == 42
    @test experiment.float.policy == experiment.exact_policy
    @test experiment.exact_float_error <=
          experiment.exact_float_residual_bound
    @test experiment.float.bellman_residual > 0
    @test experiment.float.bellman_residual <
          experiment.float.increment <= 1.0e-12
    @test experiment.float_evaluation.bellman_residual <=
          128 * eps(maximum(abs, experiment.float_evaluation.values))

    @test length(experiment.value_rows) == 78
    @test length(experiment.policy_rows) == 60
    @test length(experiment.transition_rows) == 8
    @test length(experiment.duration_path_rows) == 36
    @test length(experiment.operating_reward_rows) == 12
    @test length(experiment.comparative_rows) == 10
end

@testset "unified canonical duration paths and reward blocks" begin
    experiment = SELECTED_UNIFIED_CANONICAL_EXPERIMENT
    for row in experiment.duration_path_rows
        @test length(split(row.path, ">")) == row.duration + 1
        @test row.joint_mass > 0
        @test row.path_mass > 0
        @test 0 < row.conditional_admission_mass <= 1
    end
    keys = unique(
        (
            row.project,
            row.start_state,
            row.start_belief,
        ) for row in experiment.duration_path_rows
    )
    @test length(keys) == 6
    for key in keys
        @test sum(
            row.joint_mass for row in experiment.duration_path_rows if
            (row.project, row.start_state, row.start_belief) == key;
            init = exact_rational(0),
        ) == 1
    end

    k2_low_scale = only(
        row for row in experiment.operating_reward_rows if
        row.compressed_state == "K2" &&
        row.belief == "low" &&
        row.action == "scale"
    )
    k2_high_scale = only(
        row for row in experiment.operating_reward_rows if
        row.compressed_state == "K2" &&
        row.belief == "high" &&
        row.action == "scale"
    )
    @test k2_low_scale.expected_incumbent_reward == 13 // 4
    @test k2_low_scale.expected_net_reward_block == 49 // 16
    @test k2_high_scale.expected_incumbent_reward == 23 // 4
    @test k2_high_scale.expected_net_reward_block == 89 // 16

    transitions = experiment.transition_rows
    @test only(
        row.probability for row in transitions if
        row.from_state == "K0" &&
        row.to_state == "K1" &&
        row.action == "discover"
    ) == 3 // 4
    @test only(
        row.probability for row in transitions if
        row.from_state == "K1" &&
        row.to_state == "K2" &&
        row.action == "scale"
    ) == 3 // 4
end

@testset "unified canonical compiled-solver validation" begin
    experiment = SELECTED_UNIFIED_CANONICAL_EXPERIMENT
    @test_throws DimensionMismatch unified_bellman_step(
        experiment.float_model,
        zeros(2),
    )
    @test_throws ArgumentError unified_value_iteration(
        experiment.float_model;
        tolerance = 0,
    )
    @test_throws ArgumentError unified_value_iteration(
        experiment.float_model;
        max_iterations = 0,
    )
    @test_throws DimensionMismatch evaluate_stationary_policy(
        experiment.exact_model,
        ["continue"],
    )
    bad_policy = copy(experiment.exact_policy)
    bad_policy[1] = "research:scale"
    @test_throws ArgumentError evaluate_stationary_policy(
        experiment.exact_model,
        bad_policy,
    )
end

include(joinpath(@__DIR__, "..", "scripts", "run_unified_resource_benchmark.jl"))
using .UnifiedResourceBenchmark
include("test_unified_resource_benchmark.jl")

include(joinpath(@__DIR__, "..", "scripts", "run_unified_elasticity_switching_experiment.jl"))
using .UnifiedElasticitySwitchingExperiment
include("test_unified_elasticity_switching_experiment.jl")
