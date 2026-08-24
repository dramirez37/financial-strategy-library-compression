const SELECTED_ELASTICITY_SWITCHING_EXPERIMENT =
    run_unified_elasticity_switching_experiment()

@testset "elasticity and switching preregistration" begin
    experiment = SELECTED_ELASTICITY_SWITCHING_EXPERIMENT
    @test experiment.experiment_id == "unified-elasticity-switching-v1"
    @test experiment.config["registration_status"] == "locked_before_extension_outcomes"
    @test experiment.config["arithmetic_exact"] == "Rational{BigInt}"
    @test experiment.config["randomness"] == "none"
    @test all(values(experiment.gates))
    @test length(experiment.bridge_rows) == 45
    @test length(experiment.duration_rows) == 25
    @test length(experiment.robustness_rows) == 75
    @test length(experiment.resource.capacity_rows) == 30
    @test length(experiment.penalized_rows) == 24
end

@testset "exact bridge margin elasticities" begin
    rows = SELECTED_ELASTICITY_SWITCHING_EXPERIMENT.bridge_rows
    @test all(
        row.discount_identity && row.survival_identity && row.admission_identity &&
        row.payoff_identity && row.cost_identity for row in rows
    )
    @test all(
        field isa ExactRational for row in rows for field in (
            row.gross_descendant_value,
            row.normalized_margin,
            row.net_innovation_margin,
            row.margin_fragility,
            row.discount_elasticity,
            row.research_cost_elasticity,
        )
    )
    boundary = only(row for row in rows if row.duration == 3 && row.normalized_margin == 1 // 16)
    @test boundary.net_innovation_margin == 1 // 16
    @test boundary.margin_fragility == 16
    @test boundary.discount_elasticity == 48
    @test boundary.admission_elasticity == 16
    @test boundary.research_cost_elasticity == -15
end

@testset "innovation duration and channel identities" begin
    experiment = SELECTED_ELASTICITY_SWITCHING_EXPERIMENT
    for rows in (experiment.duration_rows, experiment.robustness_rows)
        @test all(row.total_value isa ExactRational for row in rows)
        @test all(row.innovation_duration isa ExactRational for row in rows)
        @test all(row.value_reconstruction_exact for row in rows)
        @test all(row.policy_equation_residual == 0 for row in rows)
        @test all(row.bellman_residual == 0 for row in rows)
        @test all(row.derivative_residual == 0 for row in rows)
        @test all(row.operational_value + row.generative_value == row.total_value for row in rows)
        @test all(
            row.operational_scaled_sensitivity + row.generative_scaled_sensitivity ==
            row.total_scaled_sensitivity for row in rows
        )
        @test all(
            row.operational_contribution + row.generative_contribution ==
            row.innovation_duration for row in rows
        )
    end
    @test all(
        row.local_convexity == "boundary" for row in experiment.duration_rows if
        row.belief_index in (1, 5)
    )
    @test all(
        row.local_convexity == "convex" for row in experiment.duration_rows if
        row.belief_index in (2, 3, 4)
    )
end

@testset "capacity, penalty, and switching paths" begin
    experiment = SELECTED_ELASTICITY_SWITCHING_EXPERIMENT
    for schedule in experiment.resource.schedules, belief in ("low", "high")
        capacity = sort(
            [row for row in experiment.resource.capacity_rows if
             row.schedule == schedule.id && row.belief == belief];
            by = row -> row.capacity,
        )
        @test issorted([row.optimal_objective for row in capacity])
        @test all(row.all_optima_feasible && row.ties_complete for row in capacity)
        @test all(row.enumerated_count == 8 for row in capacity)
        penalty = sort(
            [row for row in experiment.penalized_rows if
             row.schedule == schedule.id && row.belief == belief];
            by = row -> (row.probe_price, row.cell_kind == "breakpoint" ? 1 : 2),
        )
        burdens = [row.selected_burden for row in penalty]
        @test all(burdens[index] >= burdens[index + 1] for index in 1:(length(burdens) - 1))
        @test all(row.enumerated_count == 8 && row.ties_complete for row in penalty)
    end
    active = [row for row in experiment.resource.switching_rows if row.globally_active]
    @test length(active) == 36
    @test all(row.nonnegative_candidate && row.relationship == "intersection" for row in active)
end

@testset "Bellman exact distances and registered brackets" begin
    rows = SELECTED_ELASTICITY_SWITCHING_EXPERIMENT.bellman_rows
    dynamic = [row for row in rows if row.row_kind == "q_gap" &&
               row.source in ("duration_surface", "robustness_surface")]
    @test all(row.winning_q - row.alternate_q == row.action_margin for row in dynamic)
    @test all(row.action_tie_distance_linf == row.action_margin / 2 for row in dynamic)
    @test all(row.bellman_residual == 0 for row in dynamic)
    brackets = [row for row in rows if row.row_kind == "registered_parameter_bracket"]
    @test length(brackets) == 2
    @test all(row.parameter == "descendant_payoff_scale" for row in brackets)
    @test Set(row.belief_coordinate for row in brackets) == Set(ExactRational[3 // 4, 1])
    @test all(row.lower_value == 1 // 2 && row.upper_value == 1 for row in brackets)
    @test all(!row.exact_coordinate for row in brackets)
end

@testset "machine-readable figure sources and artifact drift" begin
    experiment = SELECTED_ELASTICITY_SWITCHING_EXPERIMENT
    artifacts = UnifiedElasticitySwitchingExperiment._artifact_contents(experiment)
    outputs = experiment.config["outputs"]
    table_keys = [
        "bridge", "duration_convexity", "channel_contributions", "capacity",
        "penalized_path", "library_breakpoints", "bellman_breakpoints", "robustness",
    ]
    for key in table_keys
        path = joinpath(UnifiedElasticitySwitchingExperiment.REPOSITORY_ROOT, outputs[key])
        @test isfile(path)
        @test read(path, String) == artifacts[outputs[key]]
        @test occursin(',', first(split(read(path, String), '\n')))
    end
    figure_keys = [
        "margin_elasticity_figure", "value_capacity_figure",
        "penalized_envelope_figure", "selected_burden_figure",
        "innovation_duration_figure", "switching_map_figure",
    ]
    for key in figure_keys
        path = joinpath(UnifiedElasticitySwitchingExperiment.REPOSITORY_ROOT, outputs[key])
        content = read(path, String)
        @test content == artifacts[outputs[key]]
        @test startswith(content, "<svg")
        @test occursin("data-experiment=\"unified-elasticity-switching-v1\"", content)
        @test occursin("data-sources=", content)
        @test occursin("Rational{BigInt}", content)
        @test !occursin("NaN", content)
        @test !occursin("Inf", content)
    end
end

