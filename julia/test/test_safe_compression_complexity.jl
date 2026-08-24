using .SafeCompressionComplexityReductionFixture.SafeCompressionComplexity

@testset "safe-compression set-cover reductions" begin
    instance = WeightedSetCoverInstance(
        ["e1", "e2", "e3"],
        ["A", "B", "C", "D"],
        [3, 2, 1, 4],
        UInt64[0x03, 0x06, 0x01, 0x04],
    )
    @test set_cover_source_mask(instance) == UInt64(15)
    @test set_cover_optimal_masks(instance) == UInt64[6]
    @test set_cover_weight(instance, UInt64(6)) == 3 // 1

    for mode in (:closure_only, :frontier_only, :combined)
        reduction = reduction_correspondence(instance, mode)
        @test reduction.correspondence
        @test reduction.weight_preservation
        @test reduction.optimizer_correspondence
        @test reduction.safe_optima == UInt64[6]
        @test all(
            set_cover_feasible(instance, mask) ==
            safe_feasible(reduction.problem, reduction.source_mask, mask) for
            mask in UInt64(0):reduction.source_mask
        )
    end

    closure_reduction = reduction_correspondence(instance, :closure_only)
    @test size(closure_reduction.problem.profiles, 2) == 1
    @test all(iszero, closure_reduction.problem.profiles)
    @test closure_reduction.identity_cover.obligation_labels ==
          ["module:1", "module:2", "module:3"]

    frontier_reduction = reduction_correspondence(instance, :frontier_only)
    @test all(
        ==(1 // 1),
        library_frontier(
            frontier_reduction.problem,
            frontier_reduction.source_mask,
        ),
    )
    @test iszero(
        library_module_mask(
            frontier_reduction.problem,
            frontier_reduction.source_mask,
        ),
    )
    @test frontier_reduction.identity_cover.obligation_labels ==
          ["belief:1", "belief:2", "belief:3"]

    combined_reduction = reduction_correspondence(instance, :combined)
    @test combined_reduction.identity_cover.obligation_labels == [
        "belief:1",
        "belief:2",
        "belief:3",
        "module:1",
        "module:2",
        "module:3",
    ]
end

@testset "exhaustive small reduction correspondence" begin
    checked_instances = 0
    checked_masks = 0
    element_ids = ["e1", "e2", "e3"]
    set_ids = ["s1", "s2", "s3"]
    weights = [1, 2, 3]
    for first_mask in UInt64(1):UInt64(7)
        for second_mask in UInt64(1):UInt64(7)
            for third_mask in UInt64(1):UInt64(7)
                set_masks = UInt64[first_mask, second_mask, third_mask]
                reduce(|, set_masks) == UInt64(7) || continue
                instance = WeightedSetCoverInstance(
                    element_ids,
                    set_ids,
                    weights,
                    set_masks,
                )
                for mode in (:closure_only, :frontier_only, :combined)
                    reduction = reduction_correspondence(instance, mode)
                    @test reduction.correspondence
                    @test reduction.weight_preservation
                    @test reduction.optimizer_correspondence
                    checked_masks += 8
                end
                checked_instances += 1
            end
        end
    end
    @test checked_instances == 265
    @test checked_masks == 6_360
end

@testset "safe-compression complexity artifact" begin
    fixture = build_complexity_reduction_fixture()
    @test fixture["schema_version"] ==
          "safe-compression-complexity-reduction-v1"
    @test fixture["arithmetic"] == "Rational{BigInt}"
    @test fixture["gates"]["all_gates_pass"]
    @test all(
        row["correspondence_for_every_mask"] for row in fixture["reductions"]
    )
    @test write_complexity_reduction_fixture(; check = true).fixture == fixture
end
