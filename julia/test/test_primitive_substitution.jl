@testset "T7 primitive common-gap substitution search" begin
    result = run_primitive_substitution_search_from_config()
    @test result.experiment_id == "primitive-substitution-search-v1"
    @test result.arithmetic == "Rational{BigInt}"
    @test result.randomness == "none"
    @test result.counts.all_rows == 2430
    @test result.counts.relative_saturation_rows == 1134
    @test result.counts.broad_rows == 1620
    @test result.counts.broad_failures == 648
    @test result.counts.primitive_rows == 810
    @test result.counts.primitive_failures == 0
    @test result.counts.substitutes == 553
    @test result.counts.complements == 12
    @test result.counts.separable == 1865
    @test all(values(result.checks))

    strict = result.witnesses.strict_substitution
    @test strict.poor_zero_exposure
    @test strict.rich_nonnegative_exposure
    @test strict.relative_saturation
    @test strict.closure_increment0 == 2
    @test strict.closure_increment1 == 1
    @test strict.interaction == -1

    broad = result.witnesses.broad_counterexample
    @test broad.added_exposure_order
    @test !broad.poor_zero_exposure
    @test !broad.relative_saturation
    @test broad.interaction == 0

    switching = result.witnesses.optimizer_switch
    @test !switching.added_exposure_order
    @test !switching.relative_saturation
    @test switching.closure_increment0 == 0
    @test switching.closure_increment1 == 1 // 2
    @test switching.interaction == 1 // 2
    @test switching.classification == :complements

    continue_action = (intercept = ExactRational(0), exposure = ExactRational(0))
    project_action = (intercept = ExactRational(0), exposure = ExactRational(1 // 2))
    @test relative_saturation_holds(
        ExactRational(5),
        ExactRational(1),
        (continue_action, project_action),
        (continue_action,),
    )
    @test !relative_saturation_holds(
        ExactRational(5),
        ExactRational(1),
        (continue_action, project_action),
        (continue_action, project_action),
    )
    @test_throws ArgumentError relative_saturation_holds(
        ExactRational(1),
        ExactRational(5),
        (continue_action,),
        (continue_action,),
    )

    mktempdir() do directory
        outputs =
            write_primitive_substitution_outputs(result; output_dir = directory)
        @test isfile(outputs.csv)
        @test isfile(outputs.summary)
        @test read(outputs.csv, String) ==
              render_primitive_substitution_csv(result)
        @test read(outputs.summary, String) ==
              render_primitive_substitution_summary(result)
        @test countlines(outputs.csv) == 2431
        @test occursin(
            "\"primitive_failures\": 0",
            read(outputs.summary, String),
        )
    end
end
