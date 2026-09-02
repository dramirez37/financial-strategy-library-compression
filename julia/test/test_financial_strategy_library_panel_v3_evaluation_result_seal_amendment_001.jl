using Test

include(joinpath(
    @__DIR__,
    "..",
    "scripts",
    "seal_financial_strategy_library_panel_v3_evaluation_result_amendment_001.jl",
))
const AmendmentSeal =
    SealFinancialStrategyLibraryPanelV3EvaluationResultAmendment001

@testset "evaluation amendment 001 propagates to runner and final seal" begin
    runner = AmendmentSeal.Runner
    @test runner.AmendmentStage.BaseStage !== runner.BaseRunner.Stage
    @test isdefined(
        runner.BaseRunner.Stage,
        :_amendment_001_robustness_validator_delegate,
    )
    @test basename(runner.AmendmentStage.AMENDMENT_RECEIPT_PATH) ==
        "EVALUATION_STAGING_VALIDATOR_AMENDMENT_001_RECEIPT.toml"
    @test AmendmentSeal.RESULT_SEAL_PATH == joinpath(
        AmendmentSeal.EXPERIMENT_ROOT, "EVALUATION_RESULT_SEAL.toml",
    )
    source = read(joinpath(
        @__DIR__, "..", "scripts",
        "seal_financial_strategy_library_panel_v3_evaluation_result_amendment_001.jl",
    ), String)
    @test occursin(
        "evaluation_staging_validator_amendment_001_lock_sha256", source,
    )
    @test occursin(
        "evaluation_staging_validator_amendment_001_receipt_sha256", source,
    )
end

