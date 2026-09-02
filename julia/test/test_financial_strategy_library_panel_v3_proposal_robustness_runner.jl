using Test

include(joinpath(
    @__DIR__,
    "..",
    "scripts",
    "run_financial_strategy_library_panel_v3_proposal_robustness.jl",
))
const RobustnessRunner = RunFinancialStrategyLibraryPanelV3ProposalRobustness
const RunnerRobustness = RobustnessRunner.Robustness

@testset "v3 proposal robustness public boundary and dispositions" begin
    failed = RobustnessRunner._failed_grid_payload()
    @test length(failed.public_records) == 24
    @test length(failed.choice_hashes) == 48
    @test all(!haskey(record, "comparator_choice") for record in failed.public_records)
    @test all(record["failure_code"] == "UNIVERSE_GATE_FAILED" for
              record in failed.public_records)

    etf = RobustnessRunner._cap_payload("liquid_plain_etf", NamedTuple[], nothing)
    @test length(etf.public_records) == 3
    @test all(record["failure_code"] == "NOT_APPLICABLE_COMMON_EQUITY_UNIVERSE" for
              record in etf.public_records)

    choice(policy, id, baseline) = RunnerRobustness.RobustnessChoice(
        policy, id, id == RunnerRobustness.CASH_ID, baseline, 0.0, 0.0, 0, 1, "",
    )
    primary = (;
        cost_bps = 5.0,
        risk_aversion = 3.0,
        hurdle = 0.0025,
        comparator = choice(
            "frontier_only_robust_policy",
            RunnerRobustness.CASH_ID,
            RunnerRobustness.CASH_ID,
        ),
        safe = choice(
            "innovation_safe_robust_policy",
            RunnerRobustness.CASH_ID,
            RunnerRobustness.CASH_ID,
        ),
    )
    equity = RobustnessRunner._cap_payload("liquid_common_equity", [primary], primary)
    @test [record["available"] for record in equity.public_records] == [true, true, false]
    @test equity.public_records[3]["failure_code"] ==
          "DESIGN_NOT_FROZEN_BEFORE_PROPOSAL"
end
