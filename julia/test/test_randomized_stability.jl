function _synthetic_stability_rows(trial_count = 1024)
    rows = NamedTuple[]
    for trial_id in 1:trial_count
        cell_code = mod(trial_id - 1, 128)
        level(bit, low, high) =
            iszero(cell_code & (1 << bit)) ? low : high
        push!(
            rows,
            (
                trial_id,
                frontier_only_signed_total_dynamic_loss =
                    iszero(trial_id % 5) ?
                    exact_rational(1 // 5) : exact_rational(0),
                innovation_safe_signed_total_dynamic_loss =
                    exact_rational(0),
                silent_generative_asset_count =
                    iszero(trial_id % 7) ? 1 : 0,
                active_asset_count = 5,
                frontier_closure_J =
                    iszero(trial_id % 4) ? exact_rational(-1) :
                    trial_id % 4 == 1 ? exact_rational(1) :
                    exact_rational(0),
                frontier_only_compression_ratio =
                    iseven(trial_id) ?
                    exact_rational(1 // 2) : exact_rational(2 // 3),
                innovation_safe_compression_ratio =
                    trial_id % 3 == 0 ?
                    exact_rational(2 // 3) : exact_rational(5 // 6),
                frontier_density = level(0, "sparse", "dense"),
                module_overlap = level(1, "low", "high"),
                module_complementarity = level(2, "weak", "strong"),
                project_cost = level(3, "low", "high"),
                duration = level(4, "short", "long"),
                admission = level(5, "low", "high"),
                persistence = level(6, "low", "high"),
            ),
        )
    end
    return rows
end

@testset "randomized-library sequential stability diagnostics" begin
    rows = _synthetic_stability_rows()
    diagnostics = randomized_stability_diagnostics(rows)

    @test diagnostics.prefixes ==
          [50, 100, 200, 300, 500, 750, 1000, 1024]
    @test length(diagnostics.cumulative_rows) == 8 * 8
    @test length(diagnostics.factor_rows) == 8 * 7 * 2 * 8
    @test !isempty(diagnostics.warnings)
    @test all(
        row.simulation_precision_only for
        row in diagnostics.cumulative_rows
    )

    row_at(prefix, estimand) = only(
        row for row in diagnostics.cumulative_rows if
        row.prefix_n == prefix && row.estimand == string(estimand)
    )
    frontier_50 = row_at(50, :frontier_positive_loss_frequency)
    @test frontier_50.event_count == 10
    @test frontier_50.non_event_count == 40
    @test frontier_50.observation_count == 50
    @test frontier_50.estimate == 1 // 5
    @test frontier_50.exact_sum == 10
    @test !isnothing(frontier_50.interval_low)
    @test isnothing(frontier_50.mcse)
    @test occursin("sparse_events", frontier_50.warning_code)

    mean_50 = row_at(50, :mean_positive_frontier_loss)
    @test mean_50.event_count == 10
    @test mean_50.observation_count == 10
    @test mean_50.exact_sum == 2
    @test mean_50.estimate == 1 // 5
    @test mean_50.exact_sample_variance == 0
    @test mean_50.mcse == 0.0
    @test isnothing(mean_50.interval_low)
    @test occursin("sparse_mean_support", mean_50.warning_code)

    safe_final = row_at(1024, :innovation_safe_loss_frequency)
    @test safe_final.event_count == 0
    @test safe_final.observation_count == 1024
    @test safe_final.estimate == 0
    @test occursin("sparse_events", safe_final.warning_code)

    silent_100 = row_at(100, :silent_generative_asset_frequency)
    @test silent_100.event_count == 14
    @test silent_100.observation_count == 500
    @test silent_100.estimate == 7 // 250

    frontier_compression =
        row_at(50, :frontier_only_mean_compression_ratio)
    @test frontier_compression.observation_count == 50
    @test frontier_compression.estimate == 7 // 12
    @test !isnothing(frontier_compression.exact_sample_variance)
    @test !isnothing(frontier_compression.mcse)

    dense_50 = only(
        row for row in diagnostics.factor_rows if
        row.prefix_n == 50 &&
        row.factor == "frontier_density" &&
        row.level == "dense" &&
        row.estimand == "frontier_positive_loss_frequency"
    )
    @test dense_50.observation_count == 25
    @test dense_50.event_count + dense_50.non_event_count ==
          dense_50.observation_count

    cumulative_csv = render_randomized_stability_csv(diagnostics)
    factor_csv = render_randomized_factor_stability_csv(diagnostics)
    @test length(split(chomp(cumulative_csv), '\n')) == 1 + 8 * 8
    @test length(split(chomp(factor_csv), '\n')) ==
          1 + 8 * 7 * 2 * 8
    @test occursin("Wilson descriptive simulation interval", cumulative_csv)
    @test occursin("simulation_precision_only", cumulative_csv)

    svg = render_randomized_stability_svg(diagnostics)
    @test startswith(svg, "<svg")
    @test occursin("Sequential stability at fixed registered prefixes", svg)
    @test occursin("Dynamic-loss frequencies", svg)
    @test occursin("Conditional mean positive loss", svg)
    @test occursin("Generative and interaction frequencies", svg)
    @test occursin("Mean compression ratios", svg)
    @test occursin("not inference about a real population", svg)

    @test_throws ArgumentError randomized_stability_diagnostics(
        rows;
        prefixes = (50, 1000),
    )
    invalid = copy(rows)
    invalid[1] = merge(
        invalid[1],
        (frontier_only_signed_total_dynamic_loss = 0.0,),
    )
    @test_throws ArgumentError randomized_stability_diagnostics(invalid)
    invalid_factor = copy(rows)
    invalid_factor[1] =
        merge(invalid_factor[1], (frontier_density = "medium",))
    @test_throws ArgumentError randomized_stability_diagnostics(
        invalid_factor,
    )
end
