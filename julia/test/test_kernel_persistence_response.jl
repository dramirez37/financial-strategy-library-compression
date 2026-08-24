@testset "exact kernel-persistence response surfaces" begin
    result = run_kernel_persistence_response_from_config()
    @test result.experiment_id == "kernel-persistence-response-surface-v1"
    @test result.arithmetic == "Rational{BigInt}"
    @test result.randomness == "none"
    @test length(result.rows) == 135
    @test all(values(result.checks))

    witness = result.witness
    @test witness.current_low == 9 // 8
    @test witness.current_high == 11 // 8
    @test witness.current_low < witness.current_high
    @test witness.other_low == 3 // 8
    @test witness.other_high == 1 // 8
    @test witness.other_high < witness.other_low
    @test witness.constant_low == witness.constant_high == 3 // 2

    for alpha in result.effective_discounts
        current = [
            row.coverage for row in result.rows if
            row.scenario == :current_advantage &&
            row.effective_discount == alpha
        ]
        other = [
            row.coverage for row in result.rows if
            row.scenario == :other_advantage &&
            row.effective_discount == alpha
        ]
        constant = [
            row.coverage for row in result.rows if
            row.scenario == :constant_advantage &&
            row.effective_discount == alpha
        ]
        @test issorted(current)
        @test issorted(other; rev = true)
        @test all(==(first(constant)), constant)
    end

    space = FiniteBeliefSpace([:current, :other])
    switch_kernel = MarkovKernel(space, [0 1; 1 0])
    @test_throws BoundsError persistence_coverage_response_surface(
        switch_kernel,
        ExactRational[1, 0],
        ExactRational[1 // 2],
        ExactRational[1 // 2],
        2;
        initial_index = 3,
    )
    @test_throws ArgumentError persistence_coverage_response_surface(
        switch_kernel,
        ExactRational[1, -1],
        ExactRational[1 // 2],
        ExactRational[1 // 2],
        2,
    )

    mktempdir() do directory
        outputs = write_kernel_persistence_outputs(result; output_dir = directory)
        @test isfile(outputs.csv)
        @test isfile(outputs.summary)
        @test read(outputs.csv, String) ==
              render_kernel_persistence_csv(result)
        @test read(outputs.summary, String) ==
              render_kernel_persistence_summary(result)
        @test countlines(outputs.csv) == 136
        @test occursin("\"row_count\": 135", read(outputs.summary, String))
    end
end
