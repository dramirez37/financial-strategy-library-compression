using Test

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV3Proposal.jl"))
using .FinancialStrategyLibraryPanelV3Proposal

function _proposal_candidate(id, values)
    return ProposalCandidatePath(
        id,
        Union{Missing,Float64}[Float64.(values)...],
        trues(length(values)),
    )
end

@testset "v3 proposal moving-block max-t is stable and simultaneous" begin
    sessions = 120
    good = _proposal_candidate("good", fill(0.001, sessions))
    noisy = _proposal_candidate(
        "noisy",
        [0.0002 + 0.001 * sin(0.21 * index) for index in 1:sessions],
    )
    bad = _proposal_candidate("bad", fill(-0.001, sessions))
    cash = cash_candidate_path(sessions)
    first_result = simultaneous_moving_block_max_t(
        [good, noisy, bad],
        cash;
        base_seed = 310002,
        purpose_id = "test",
        scope_values = ("origin", "universe"),
        bootstrap_repetitions = 200,
        moving_block_sessions = 5,
    )
    second_result = simultaneous_moving_block_max_t(
        [good, noisy, bad],
        cash;
        base_seed = 310002,
        purpose_id = "test",
        scope_values = ("origin", "universe"),
        bootstrap_repetitions = 200,
        moving_block_sessions = 5,
    )
    @test first_result.candidate_ids == ["bad", "good", "noisy"]
    @test first_result.lower_bounds == second_result.lower_bounds
    @test first_result.seed == second_result.seed
    @test first_result.lower_bounds[2] > 0.0025
    @test first_result.lower_bounds[1] < 0
end

@testset "v3 proposal nested no-harm choices" begin
    sessions = 120
    good = _proposal_candidate("good", fill(0.001, sessions))
    better = _proposal_candidate("better", fill(0.002, sessions))
    bad = _proposal_candidate("bad", fill(-0.001, sessions))
    comparator, comparator_inference = robust_cash_choice(
        "frontier_only_robust_policy",
        [good, bad];
        base_seed = 310002,
        scope_values = ("origin", "universe", "frontier_only_robust_policy"),
        bootstrap_repetitions = 200,
        moving_block_sessions = 5,
    )
    @test comparator.selected_strategy_ids == ["good"]
    @test !comparator.used_cash
    @test comparator_inference.bootstrap_repetitions == 200

    safe, safe_inference = robust_safe_choice(
        [good, better, bad],
        comparator;
        comparator_candidates = [good, bad],
        base_seed = 310002,
        scope_values = ("origin", "universe", "innovation_safe_robust_policy"),
        bootstrap_repetitions = 200,
        moving_block_sessions = 5,
    )
    @test safe.baseline_strategy_id == "good"
    @test safe.selected_strategy_ids == ["better"]
    @test safe.selected_lower_bound > 0.0025
    @test safe_inference.candidate_ids == ["bad", "better"]
    @test safe_inference.critical_value >= comparator_inference.critical_value

    forced = forced_max_choice([good, better, bad])
    @test forced.selected_strategy_ids == ["better"]
    equal = equal_weight_positive_choice([good, better, bad])
    @test equal.selected_strategy_ids == ["better", "good"]
end

@testset "v3 proposal incomplete candidates stay visible but ineligible" begin
    incomplete = ProposalCandidatePath(
        "incomplete",
        Union{Missing,Float64}[0.01, missing, 0.02],
        BitVector([true, false, true]),
    )
    choice, inference = robust_cash_choice(
        "frontier_only_robust_policy",
        [incomplete];
        base_seed = 310002,
        scope_values = ("origin", "universe"),
        bootstrap_repetitions = 100,
        moving_block_sessions = 2,
    )
    @test choice.used_cash
    @test isempty(inference.candidate_ids)
    @test choice.complete_candidate_count == 0
    forced = forced_max_choice([incomplete])
    @test isempty(forced.selected_strategy_ids)
    @test forced.failure_code == "NO_COMPLETE_ACTIVE_PROPOSAL_PATH"
end
