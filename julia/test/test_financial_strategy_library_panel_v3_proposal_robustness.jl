using Test

include(joinpath(
    @__DIR__,
    "..",
    "src",
    "FinancialStrategyLibraryPanelV3ProposalRobustness.jl",
))
using .FinancialStrategyLibraryPanelV3ProposalRobustness
const Robustness = FinancialStrategyLibraryPanelV3ProposalRobustness

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV3Proposal.jl"))
using .FinancialStrategyLibraryPanelV3Proposal
const PrimaryProposal = FinancialStrategyLibraryPanelV3Proposal

function synthetic_robustness_path(id, values; turnover = 0.02, complete = true)
    gross = Union{Missing,Float64}[Float64.(values)...]
    available = trues(length(gross))
    if !complete
        gross[end] = missing
        available[end] = false
    end
    return RobustnessPath(
        String(id),
        gross,
        fill(Float64(turnover), length(gross)),
        available,
    )
end

@testset "v3 proposal robustness full registered grid and stable seeds" begin
    sessions = 252
    comparator = [
        synthetic_robustness_path("c1", fill(0.00012, sessions); turnover = 0.01),
        synthetic_robustness_path("c2", fill(-0.00005, sessions); turnover = 0.01),
    ]
    safe = [
        comparator...,
        synthetic_robustness_path("s1", fill(0.00018, sessions); turnover = 0.01),
        synthetic_robustness_path("s_incomplete", fill(0.01, sessions); complete = false),
    ]
    grid = freeze_cost_risk_hurdle_grid(safe, comparator, "origin", "universe")
    @test length(grid) == 24
    @test sort(unique(row.cost_bps for row in grid)) == [0.0, 5.0, 15.0, 30.0]
    @test sort(unique(row.risk_aversion for row in grid)) == [1.0, 3.0]
    @test sort(unique(row.hurdle for row in grid)) == [0.0, 0.0025, 0.005]
    @test all(row.comparator_inference.bootstrap_repetitions == 5_000 for row in grid)
    @test all(row.safe_inference.moving_block_sessions == 20 for row in grid)
    @test all(row.comparator.selected_strategy_id in
              [Robustness.CASH_ID; row.comparator_inference.candidate_ids] for row in grid)
    @test all(row.safe.selected_strategy_id == row.comparator.selected_strategy_id ||
              row.safe.selected_strategy_id in row.safe_inference.candidate_ids for row in grid)
    @test all(!("s_incomplete" in row.safe_inference.candidate_ids) for row in grid)
    @test all(row.safe_inference.simultaneous_family_contrast_count == 7 for row in grid)
    repeated = freeze_cost_risk_hurdle_grid(
        safe,
        comparator,
        "origin",
        "universe";
        costs = (5.0,),
        risk_aversions = (3.0,),
        hurdles = (0.0025,),
    )
    primary = only(filter(
        row -> row.cost_bps == 5 && row.risk_aversion == 3 && row.hurdle == 0.0025,
        grid,
    ))
    @test only(repeated).comparator == primary.comparator
    @test only(repeated).safe == primary.safe
end

@testset "v3 robustness primary specification reproduces primary policy engine" begin
    sessions = 252
    gross = Dict(
        "c1" => [0.00015 + 0.00005 * sin(index / 11) for index in 1:sessions],
        "c2" => [-0.00002 + 0.00003 * cos(index / 7) for index in 1:sessions],
        "s1" => [0.00020 + 0.00005 * sin(index / 13) for index in 1:sessions],
    )
    robust_paths = Dict(
        id => synthetic_robustness_path(id, values; turnover = 0.012) for
        (id, values) in gross
    )
    comparator = [robust_paths["c1"], robust_paths["c2"]]
    safe = [comparator...; robust_paths["s1"]]
    frozen = primary_cap_choices(safe, comparator, "origin", "universe")

    candidate(id) = PrimaryProposal.ProposalCandidatePath(
        id,
        Union{Missing,Float64}[
            gross[id][index] - 0.0005 * 0.012 for index in 1:sessions
        ],
        trues(sessions),
    )
    primary_comparator_paths = [candidate("c1"), candidate("c2")]
    primary_safe_paths = [primary_comparator_paths...; candidate("s1")]
    comparator_choice, _ = PrimaryProposal.robust_cash_choice(
        "frontier_only_robust_policy",
        primary_comparator_paths;
        base_seed = 310002,
        scope_values = ("origin", "universe"),
    )
    safe_choice, _ = PrimaryProposal.robust_safe_choice(
        primary_safe_paths,
        comparator_choice;
        comparator_candidates = primary_comparator_paths,
        base_seed = 310002,
        scope_values = ("origin", "universe"),
    )
    @test frozen.comparator.selected_strategy_id == only(comparator_choice.selected_strategy_ids)
    @test frozen.safe.selected_strategy_id == only(safe_choice.selected_strategy_ids)
    @test frozen.comparator.selected_lower_bound ≈ comparator_choice.selected_lower_bound atol = 1e-14
    @test frozen.safe.selected_lower_bound ≈ safe_choice.selected_lower_bound atol = 1e-14
    @test frozen.safe_inference.simultaneous_family_contrast_count == 7
end
