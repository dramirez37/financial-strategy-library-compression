using Test

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV4.jl"))
using .FinancialStrategyLibraryPanelV4

function small_design()
    return MechanismDesign(
        calibration_world_count = 256,
        evaluation_world_count_per_regime = 256,
        proposal_sessions = 100,
        annualization_sessions = 252,
        proposal_burnin_sessions = 20,
        discount_factor = 0.99,
        survival_probability = 0.98,
        admission_probability = 0.90,
        delay_periods = 1,
        economic_hurdle = 0.0025,
        null_quantile = 0.95,
        null_seed = 440001,
        proposal_seed = 440002,
        evaluation_seed = 440003,
        safe_retention_burden = 3,
        frontier_retention_burden = 3,
        safe_operating_frontier = 1,
        frontier_operating_frontier = 1,
    )
end

@testset "v4 structural first stage" begin
    design = small_design()
    structure = structural_first_stage(design)
    @test structure.valid
    @test structure.equal_burden
    @test structure.equal_frontier
    @test structure.safe_bridge_capability
    @test !structure.frontier_bridge_capability
    @test structure.cash_feasible
end

@testset "v4 exact bridge-margin construction" begin
    design = small_design()
    cost = 0.04
    for margin in (-0.02, 0.0, 0.0025, 0.08)
        gain = bridge_descendant_gain(design, cost, margin)
        recovered = design.discount_factor^design.delay_periods *
            design.survival_probability^design.delay_periods *
            design.admission_probability * gain - cost
        @test recovered ≈ margin atol = 1e-14
        @test gain >= 0
    end
    @test_throws ArgumentError bridge_descendant_gain(design, 0.01, -0.02)
end

@testset "v4 null threshold and stable simulation" begin
    design = small_design()
    calibration = NoiseCalibration(0.003, 0.10, 7)
    first_result = calibrate_adoption_threshold(design, calibration)
    second_result = calibrate_adoption_threshold(design, calibration)
    @test first_result.threshold == second_result.threshold
    @test first_result.estimates == second_result.estimates
    @test first_result.threshold >= design.economic_hurdle
    @test stable_seed(440001, "null", 1) == stable_seed(440001, "null", 1)
    @test stable_seed(440001, "null", 1) != stable_seed(440001, "null", 2)
end

@testset "v4 complete paired experiment" begin
    design = small_design()
    calibration = NoiseCalibration(0.002, 0.05, 8)
    experiment = run_experiment(design, calibration)
    @test length(experiment.regimes) == 4
    @test length(experiment.results) == 4 * design.evaluation_world_count_per_regime
    @test all(result -> result.structural_valid, experiment.results)
    @test all(result -> record_hash(result) == result.record_hash, experiment.results)

    for world_id in 1:design.evaluation_world_count_per_regime
        rows = sort!(
            filter(result -> result.world_id == world_id, experiment.results);
            by = result -> result.true_margin,
        )
        @test length(unique(getfield.(rows, :proposal_noise))) == 1
        @test issorted(getfield.(rows, :proposal_margin_estimate))
        @test issorted(Int.(getfield.(rows, :learned_adopt)))
        @test length(unique(getfield.(rows, :project_success))) == 1
    end

    summaries = Dict(summary.regime_id => summary for summary in experiment.summaries)
    @test summaries["null_margin"].theoretical_oracle_value == 0.0
    @test summaries["adversarial_margin"].theoretical_oracle_value == 0.0
    @test summaries["powered_positive"].theoretical_oracle_value > 0
    @test summaries["powered_positive"].adoption_rate >
          summaries["low_dose_positive"].adoption_rate
end

@testset "v4 intervals" begin
    interval = mean_ci([1.0, 2.0, 3.0])
    @test interval.mean == 2.0
    @test interval.lower < interval.mean < interval.upper
    wilson = wilson_interval(5, 100)
    @test 0 <= wilson.lower <= 0.05 <= wilson.upper <= 1
    @test nearest_rank_quantile(1:100, 0.95) == 95.0
end

