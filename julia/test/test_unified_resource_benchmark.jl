const SELECTED_UNIFIED_RESOURCE_EXPERIMENT =
    run_unified_resource_benchmark()

@testset "unified resource benchmark preregistration and exact channels" begin
    experiment = SELECTED_UNIFIED_RESOURCE_EXPERIMENT
    @test experiment.experiment_id == "unified-canonical-resources-v1"
    @test [schedule.id for schedule in experiment.schedules] == [
        "equal_active",
        "carrier_heavy",
        "descendant_heavy",
    ]
    @test [schedule.inactive for schedule in experiment.schedules] ==
          ExactRational[1, 1, 1]
    @test [schedule.weights for schedule in experiment.schedules] == [
        ExactRational[1, 1, 1],
        ExactRational[2, 2, 1],
        ExactRational[1, 1, 2],
    ]
    @test length(experiment.channel_rows) == 16
    @test all(
        row.operational_value + row.generative_value == row.productive_value for
        row in experiment.channel_rows
    )
    @test all(
        row.operational_contribution + row.generative_contribution ==
        row.innovation_duration for row in experiment.channel_rows
    )
    @test all(
        row.operational_elasticity === nothing for
        row in experiment.channel_rows if row.operational_value == 0
    )
    @test all(
        row.generative_elasticity === nothing for
        row in experiment.channel_rows if row.generative_value == 0
    )
    inactive_low = only(
        row for row in experiment.channel_rows if row.mask == 0 && row.belief == "low"
    )
    carrier_low = only(
        row for row in experiment.channel_rows if row.mask == 1 && row.belief == "low"
    )
    descendant_high = only(
        row for row in experiment.channel_rows if row.mask == 4 && row.belief == "high"
    )
    @test inactive_low.productive_value == 115 // 288
    @test inactive_low.innovation_duration == 10777 // 2070
    @test carrier_low.productive_value == 1
    @test carrier_low.innovation_duration == 56 // 15
    @test descendant_high.operational_value == 22 // 3
    @test descendant_high.generative_value == 0
    @test descendant_high.innovation_duration == 29 // 33
    @test descendant_high.action_tie_distance_linf == 3 // 32
end

@testset "unified resource exact safe compression exhausts every raw library" begin
    experiment = SELECTED_UNIFIED_RESOURCE_EXPERIMENT
    @test length(experiment.safe_rows) == 3 * 8
    for schedule in experiment.schedules
        low = experiment.problems[(schedule.id, "low")]
        high = experiment.problems[(schedule.id, "high")]
        for source in UInt64.(0:7)
            result = Main.ResourceOptimization.minimum_weight_safe_compression(low, source)
            optima = UInt64[library.mask for library in result.optimal_libraries]
            manual_feasible = UInt64[
                mask for mask in UInt64.(0:7) if
                (mask & ~source) == 0 &&
                Main.ResourceOptimization.library_frontier(low, mask) ==
                Main.ResourceOptimization.library_frontier(low, source) &&
                Main.ResourceOptimization.library_closure(low, mask) ==
                Main.ResourceOptimization.library_closure(low, source)
            ]
            manual_best = minimum(
                Main.ResourceOptimization.library_weight(low, mask) for
                mask in manual_feasible
            )
            manual_optima = UInt64[
                mask for mask in manual_feasible if
                Main.ResourceOptimization.library_weight(low, mask) == manual_best
            ]
            @test optima == manual_optima
            @test result.certificate.ties_complete
            @test all(
                Main.ResourceOptimization.exact_safe_feasible(low, mask, source) for
                mask in optima
            )
            @test all(
                Main.ResourceOptimization.library_total_value(low, mask) ==
                Main.ResourceOptimization.library_total_value(low, source) &&
                Main.ResourceOptimization.library_total_value(high, mask) ==
                Main.ResourceOptimization.library_total_value(high, source) for
                mask in manual_feasible
            )
            for mask in manual_feasible
                mask == source && continue
                @test Main.ResourceOptimization.library_weight(low, mask) <
                      Main.ResourceOptimization.library_weight(low, source)
            end
        end
    end
end

@testset "unified resource capacity and penalized optima match enumeration" begin
    experiment = SELECTED_UNIFIED_RESOURCE_EXPERIMENT
    @test length(experiment.capacity_rows) == 30
    @test length(experiment.penalized_rows) == 24
    for schedule in experiment.schedules, belief in ("low", "high")
        problem = experiment.problems[(schedule.id, belief)]
        capacity_rows = [
            row for row in experiment.capacity_rows if
            row.schedule == schedule.id && row.belief == belief
        ]
        sort!(capacity_rows; by = row -> row.capacity)
        @test issorted([row.optimal_objective for row in capacity_rows])
        for row in capacity_rows
            feasible = UInt64[
                mask for mask in UInt64.(0:7) if
                schedule.inactive +
                Main.ResourceOptimization.library_weight(problem, mask) <= row.capacity
            ]
            best = maximum(
                Main.ResourceOptimization.library_total_value(problem, mask) for
                mask in feasible
            )
            optima = UInt64[
                mask for mask in feasible if
                Main.ResourceOptimization.library_total_value(problem, mask) == best
            ]
            @test row.optimal_objective == best
            @test row.optimal_masks == join(string.(Int.(optima)), ";")
            @test row.all_optima_feasible
            @test row.ties_complete
        end

        price_rows = [
            row for row in experiment.penalized_rows if
            row.schedule == schedule.id && row.belief == belief
        ]
        sort!(price_rows; by = row -> (row.probe_price, row.cell_kind))
        burdens = ExactRational[]
        for row in price_rows
            objectives = ExactRational[
                Main.ResourceOptimization.library_total_value(problem, mask) -
                row.probe_price * (
                    schedule.inactive +
                    Main.ResourceOptimization.library_weight(problem, mask)
                ) for mask in UInt64.(0:7)
            ]
            best = maximum(objectives)
            optima = UInt64[
                mask for mask in UInt64.(0:7) if objectives[Int(mask) + 1] == best
            ]
            @test row.net_value == best
            @test row.optimal_masks == join(string.(Int.(optima)), ";")
            @test row.ties_complete
            push!(burdens, row.selected_burden)
        end
        @test all(burdens[index] >= burdens[index + 1] for index in 1:(length(burdens) - 1))
    end
end

@testset "unified resource exact switching prices and artifacts" begin
    experiment = SELECTED_UNIFIED_RESOURCE_EXPERIMENT
    expected = Dict(
        ("equal_active", "low") => ExactRational[0, 1229 // 288],
        ("equal_active", "high") => ExactRational[0, 2089 // 288],
        ("carrier_heavy", "low") => ExactRational[0, 1229 // 288],
        ("carrier_heavy", "high") => ExactRational[0, 2089 // 288],
        ("descendant_heavy", "low") => ExactRational[0, 1229 // 576],
        ("descendant_heavy", "high") => ExactRational[0, 2089 // 576],
    )
    for schedule in experiment.schedules, belief in ("low", "high")
        problem = experiment.problems[(schedule.id, belief)]
        breakpoints = Main.ResourceOptimization.optimizer_breakpoints(problem)
        @test breakpoints.prices == expected[(schedule.id, belief)]
    end
    @test length(experiment.switching_rows) == 3 * 2 * 28
    @test all(
        !row.globally_active ||
        (row.nonnegative_candidate && row.relationship == "intersection") for
        row in experiment.switching_rows
    )
    for (relative_path, content) in
        Main.UnifiedResourceBenchmark._artifact_contents(experiment)
        path = joinpath(Main.UnifiedResourceBenchmark.REPOSITORY_ROOT, relative_path)
        @test isfile(path)
        @test read(path, String) == content
        if endswith(path, ".svg")
            @test startswith(content, "<svg")
            @test occursin("<title", content)
            @test !occursin("NaN", content)
        end
    end
end
