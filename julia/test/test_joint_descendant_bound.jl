using TOML

@testset "joint descendant-event exact gauntlet" begin
    result = run_joint_descendant_gauntlet_from_config()
    @test result.experiment_id == "joint-descendant-bound-gauntlet-v1"
    @test result.arithmetic == "Rational{BigInt}"
    @test result.randomness == "none"
    @test result.counts.joint_laws == 21
    @test result.counts.correlated_joint_laws > 0
    @test result.counts.single_checks > 0
    @test result.counts.single_failures == 0
    @test result.counts.correlated_checks > 0
    @test result.counts.correlated_failures == 0
    @test result.counts.negative_adjustment_checks > 0
    @test result.counts.negative_adjustment_failures == 0
    @test result.counts.multiple_checks > 0
    @test result.counts.multiple_failures == 0
    @test result.counts.harmful_naive_failures > 0
    @test result.counts.harmful_corrected_failures == 0
    @test result.counts.comparator_naive_failures > 0
    @test result.counts.comparator_corrected_failures == 0
    @test result.counts.enabled_both_zero_comparator_failures == 0
    @test result.counts.counterexample_fixtures == 8
    @test result.counts.survivor_fixtures == 4
    @test result.lean_gate_open
    @test all(values(result.checks))

    fixtures = Dict(fixture.id => fixture for fixture in result.fixtures)
    @test fixtures["CX-T6-JOINT-HARMFUL-NONG-01"].attacked_bound >
          fixtures["CX-T6-JOINT-HARMFUL-NONG-01"].actual
    @test fixtures["CX-T6-JOINT-HARMFUL-NONG-01"].revised_bound <=
          fixtures["CX-T6-JOINT-HARMFUL-NONG-01"].actual
    @test fixtures["CX-T6-JOINT-OPERATING-ADJUSTMENT-01"].attacked_bound >
          fixtures["CX-T6-JOINT-OPERATING-ADJUSTMENT-01"].actual
    @test fixtures["CX-T6-JOINT-POSITIVE-COMPARATOR-01"].attacked_bound >
          fixtures["CX-T6-JOINT-POSITIVE-COMPARATOR-01"].actual
    @test fixtures["CX-T6-JOINT-PATH-FLOOR-01"].revised_bound ==
          fixtures["CX-T6-JOINT-PATH-FLOOR-01"].actual
    @test fixtures["CX-T6-JOINT-PRODUCT-SHORTCUT-01"].revised_bound ==
          fixtures["CX-T6-JOINT-PRODUCT-SHORTCUT-01"].actual
    @test fixtures["FX-T6-JOINT-MULTIPLE-DESCENDANTS-01"].revised_bound ==
          fixtures["FX-T6-JOINT-MULTIPLE-DESCENDANTS-01"].actual
    @test fixtures["FX-T6-JOINT-CORRELATED-01"].attacked_bound ==
          fixtures["FX-T6-JOINT-CORRELATED-01"].actual

    half = ExactRational(1 // 2)
    joint = ExactRational[0 1 // 2 1 // 2]
    @test joint_bound(half, 1, ExactRational(0), ExactRational(0), joint, 2, ExactRational[2]) ==
          half
    harm = ExactRational[0 0 2]
    @test joint_bound_with_harm(
        half,
        1,
        ExactRational(0),
        ExactRational(0),
        joint,
        2,
        ExactRational[2],
        harm,
    ) == 0

    mktempdir() do directory
        config = TOML.parsefile(DEFAULT_CONFIG)
        config["outputs"]["counterexamples"] =
            joinpath(directory, "counterexamples.csv")
        config["outputs"]["summary"] = joinpath(directory, "summary.json")
        config_path = joinpath(directory, "config.toml")
        open(config_path, "w") do io
            TOML.print(io, config)
        end
        paths = write_outputs(result; config_path)
        @test isfile(paths.counterexamples)
        @test isfile(paths.summary)
        @test read(paths.counterexamples, String) == render_counterexamples(result)
        @test read(paths.summary, String) == render_summary(result)
        @test countlines(paths.counterexamples) == 13
    end
end
