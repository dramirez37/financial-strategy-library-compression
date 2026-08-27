using .SafeCompressionComplexityReductionFixture.SafeCompressionComplexity

@testset "budgeted full-union set-cover reduction" begin
    instance = WeightedSetCoverInstance(
        ["m1", "m2", "m3"],
        ["s1", "s2", "s3"],
        [2, 1, 2],
        UInt64[0x03, 0x06, 0x05],
        3,
    )

    @test instance.weights == BigInt[2, 1, 2]
    @test instance.budget == BigInt(3)
    @test set_cover_source_mask(instance) == UInt64(7)
    @test set_cover_weight(instance, UInt64(6)) == BigInt(3)
    @test set_cover_within_budget(instance, UInt64(6))
    @test !set_cover_within_budget(instance, UInt64(5))
    @test set_cover_optimal_masks(instance) == UInt64[3, 6]

    reduction = reduction_correspondence(instance, :closure_only)
    problem = reduction.problem

    @test problem.inactive_strategy_id == "inactive"
    @test problem.budget == instance.budget
    @test size(problem.profiles) == (3, 1)
    @test all(==(0 // 1), problem.profiles)
    @test library_frontier(problem, reduction.source_mask) ==
          Rational{BigInt}[0 // 1]
    @test library_module_mask(problem, reduction.source_mask) == UInt64(7)
    @test length(reduction.identity_cover.obligation_labels) == 3
    @test all(
        startswith(label, "module:") for
        label in reduction.identity_cover.obligation_labels
    )
    @test reduction.correspondence
    @test reduction.weight_preservation
    @test reduction.threshold_preservation
    @test reduction.decision_correspondence
    @test reduction.optimizer_correspondence
    @test reduction.set_cover_yes
    @test reduction.safe_compression_yes

    @test safe_feasible(problem, reduction.source_mask, UInt64(6))
    @test safe_compression_within_budget(
        problem,
        reduction.source_mask,
        UInt64(6),
    )
    @test safe_feasible(problem, reduction.source_mask, UInt64(5))
    @test !safe_compression_within_budget(
        problem,
        reduction.source_mask,
        UInt64(5),
    )

    @test_throws ArgumentError WeightedSetCoverInstance(
        ["m1"], ["s1"], [1 // 2], UInt64[0x01], 1
    )
    @test_throws ArgumentError WeightedSetCoverInstance(
        ["m1"], ["s1"], [0], UInt64[0x01], 1
    )
    @test_throws ArgumentError WeightedSetCoverInstance(
        ["m1"], ["s1"], [1], UInt64[0x01], -1
    )
    @test_throws ArgumentError WeightedSetCoverInstance(
        ["m1", "m2"], ["s1"], [1], UInt64[0x01], 1
    )
end

@testset "exhaustive budgeted reduction correspondence" begin
    incidence_systems = 0
    decision_instances = 0
    candidate_masks_checked = 0
    mismatches = String[]
    weight_patterns = ([1, 1, 1], [1, 2, 3], [3, 1, 2])

    for a in UInt64(1):UInt64(7),
        b in UInt64(1):UInt64(7),
        c in UInt64(1):UInt64(7)
        (a | b | c) == UInt64(7) || continue
        incidence_systems += 1

        for weights in weight_patterns, budget in 0:6
            decision_instances += 1
            instance = WeightedSetCoverInstance(
                ["m1", "m2", "m3"],
                ["s1", "s2", "s3"],
                collect(weights),
                UInt64[a, b, c],
                budget,
            )
            reduction = reduction_correspondence(instance, :closure_only)
            problem = reduction.problem

            valid = reduction.correspondence &&
                    reduction.weight_preservation &&
                    reduction.threshold_preservation &&
                    reduction.decision_correspondence &&
                    reduction.optimizer_correspondence &&
                    all(==(0 // 1), problem.profiles) &&
                    library_frontier(problem, reduction.source_mask) ==
                    Rational{BigInt}[0 // 1] &&
                    library_module_mask(problem, reduction.source_mask) == UInt64(7) &&
                    length(reduction.identity_cover.obligation_labels) == 3 &&
                    all(
                        startswith(label, "module:") for
                        label in reduction.identity_cover.obligation_labels
                    )
            valid || push!(
                mismatches,
                "instance $(decision_instances) failed global correspondence",
            )

            for selected_mask in UInt64(0):UInt64(7)
                candidate_masks_checked += 1
                cover_feasible = set_cover_feasible(instance, selected_mask)
                safe = safe_feasible(problem, reduction.source_mask, selected_mask)
                cover_within_budget = set_cover_within_budget(instance, selected_mask)
                safe_within_budget = safe_compression_within_budget(
                    problem,
                    reduction.source_mask,
                    selected_mask,
                )
                if cover_feasible != safe ||
                   cover_within_budget != safe_within_budget ||
                   set_cover_weight(instance, selected_mask) !=
                   library_weight(problem, selected_mask)
                    push!(mismatches, "instance $(decision_instances), mask $(selected_mask)")
                end
            end
        end
    end

    @test incidence_systems == 265
    @test decision_instances == 5_565
    @test candidate_masks_checked == 44_520
    @test isempty(mismatches)
end

@testset "committed complexity reduction fixture" begin
    root = normpath(joinpath(@__DIR__, "..", ".."))
    artifact_path = joinpath(
        root,
        "experiments",
        "results",
        "safe_compression_complexity_reduction_fixture.json",
    )

    expected = build_complexity_reduction_fixture()
    committed = read(artifact_path, String)

    @test expected["schema_version"] ==
          "safe-compression-complexity-reduction-v2"
    @test expected["source_problem"]["problem"] ==
          "full-union weighted set cover decision"
    @test length(expected["instances"]) == 5
    @test expected["gates"]["all_gates_pass"]
    @test [row["set_cover_decision_answer"] for row in expected["instances"]] ==
          [true, false, true, false, true]
    @test all(
        row["decision_correspondence_for_every_mask"] for
        row in expected["instances"]
    )
    @test all(
        row["inactive_retained"] &&
        row["set_cover_cost"] == row["safe_compression_burden"] &&
        row["safe_compression_feasible"] ==
        (row["frontier_equal"] && row["closure_equal"]) for
        instance in expected["instances"] for row in instance["candidate_rows"]
    )
    @test committed == render_json(expected)
end
