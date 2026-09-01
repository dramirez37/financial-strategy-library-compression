using Test

include(joinpath(
    @__DIR__,
    "..",
    "scripts",
    "analyze_financial_strategy_library_panel_v1_corrected.jl",
))
const CorrectedPanelAnalysis = AnalyzeFinancialStrategyLibraryPanelV1Corrected

@testset "financial panel runtime summary correction" begin
    summary = (
        library_id = ["library"],
        schedule_id = ["schedule"],
        algorithm_id = ["enumeration"],
        registered_instance_count = Int64[2],
        runtime_count = Int64[2],
        runtime_mean_seconds = [5.0005],
        runtime_median_seconds = [5.0005],
        runtime_q25_seconds = [0.001],
        runtime_q75_seconds = [10.0],
        runtime_p90_seconds = [10.0],
        runtime_max_seconds = [10.0],
    )
    algorithms = (
        origin_id = ["origin-1", "origin-2"],
        library_id = ["library", "library"],
        schedule_id = ["schedule", "schedule"],
        algorithm_id = ["enumeration", "enumeration"],
        applicable = [true, false],
        wall_clock_seconds = [10.0, 0.001],
    )
    corrected = CorrectedPanelAnalysis.correct_runtime_summary(summary, algorithms)
    @test corrected.runtime_count == [1]
    @test corrected.runtime_mean_seconds == [10.0]
    @test corrected.runtime_median_seconds == [10.0]
    @test corrected.runtime_q25_seconds == [10.0]
    @test corrected.runtime_q75_seconds == [10.0]
    @test corrected.runtime_p90_seconds == [10.0]
    @test corrected.runtime_max_seconds == [10.0]
end

@testset "financial panel public projection boundary" begin
    names = Set(CorrectedPanelAnalysis.PUBLIC_ALGORITHM_COLUMNS)
    @test :selected_active_ids ∉ names
    @test :belief_losses_exact ∉ names
    @test :selected_identity_sha256 in names
    @test :exact_frontier_preservation in names
    @test :exact_closure_preservation in names
    @test :postdecision_available in names
    @test isempty(intersect(names, CorrectedPanelAnalysis.PROHIBITED_PUBLIC_COLUMNS))
end
