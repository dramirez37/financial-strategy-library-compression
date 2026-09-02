using Test
using StrategyInnovation

function _financial_v2_fixture()
    provenance = JournalCompressionProvenance(
        :financial,
        "financial-v2-fixture",
        "public synthetic v2 challenge fixture";
        generator = "test_financial_strategy_library_panel_v2",
        redistributable = true,
    )
    return journal_compression_instance_from_components(
        ["inactive", "s1", "s2", "s3"],
        Bool[true, false, false, false],
        [0, 4, 5, 6],
        ["belief_1", "belief_2"],
        [
            0 0
            10 0
            0 10
            10 10
        ],
        [String[], ["m1"], ["m2"], ["m1"]];
        provenance,
    )
end

function _selection(instance, ids)
    wanted = Set(String.(ids))
    return BitVector(string(strategy_id.id) in wanted for strategy_id in instance.strategy_ids)
end

@testset "financial innovation-challenge v2 mechanics" begin
    state_by_date = Dict(
        "2020-01-02" => 1,
        "2020-01-03" => 1,
        "2020-01-06" => 2,
        "2020-01-07" => 2,
        "2021-01-04" => 1,
        "2021-01-05" => 1,
        "2021-01-06" => 2,
        "2021-01-07" => 2,
    )
    dates = sort!(collect(keys(state_by_date)))
    supported = financial_profile_support(
        dates,
        state_by_date;
        construction_start = "2020-01-01",
        construction_end = "2020-12-31",
        compression_start = "2021-01-01",
        compression_end = "2021-12-31",
        state_count = 2,
        minimum_per_state = 2,
    )
    @test supported.supported
    @test supported.construction_counts == [2, 2]
    @test supported.compression_counts == [2, 2]

    sparse = financial_profile_support(
        filter(!=("2021-01-07"), dates),
        state_by_date;
        construction_start = "2020-01-01",
        construction_end = "2020-12-31",
        compression_start = "2021-01-01",
        compression_end = "2021-12-31",
        state_count = 2,
        minimum_per_state = 2,
    )
    @test !sparse.supported
    @test sparse.construction_supported
    @test !sparse.compression_supported

    instance = _financial_v2_fixture()
    safe = _selection(instance, ["inactive", "s1", "s2"])
    @test check_journal_compression_solution(instance, safe).exact_feasible
    frontier = frontier_only_journal_instance(instance)
    @test isempty(frontier.source_closure)
    frontier_exact = _selection(frontier, ["inactive", "s3"])
    @test check_journal_compression_solution(frontier, frontier_exact).exact_feasible
    @test !check_journal_compression_solution(instance, frontier_exact).closure_preserved

    scores = [0, 9, 8, 10]
    matched = frontier_only_budget_matched_selection(
        instance,
        frontier_exact,
        safe,
        scores,
    )
    @test matched.exact_burden == 6
    @test matched.exact_burden_cap == 9
    @test isempty(matched.additions)
    @test !matched.closure_recovered

    menu = FinancialInnovationMenu(
        "menu-001",
        [
            FinancialInnovationCandidate("candidate-safe", ["m1", "m2"], 10, 2),
            FinancialInnovationCandidate("candidate-frontier", ["m1"], 9, 5),
        ],
    )
    safe_choice = select_financial_innovation_candidate(
        menu,
        retained_capability_ids(instance, safe),
    )
    comparator_choice = select_financial_innovation_candidate(
        menu,
        retained_capability_ids(instance, matched.selected),
    )
    @test safe_choice.candidate_id == "candidate-safe"
    @test comparator_choice.candidate_id == "candidate-frontier"
    contrast = paired_financial_innovation_contrast(safe_choice, comparator_choice)
    @test contrast.available
    @test contrast.heldout_innovation_utility_delta == -3
    @test !contrast.same_candidate

    missing_menu = FinancialInnovationMenu(
        "menu-002",
        [
            FinancialInnovationCandidate("missing-top", ["m1"], 10, missing),
            FinancialInnovationCandidate("observed-second", ["m1"], 9, 7),
        ],
    )
    missing_choice = select_financial_innovation_candidate(missing_menu, Set(["m1"]))
    @test missing_choice.candidate_id == "missing-top"
    @test !missing_choice.postdecision_available
    @test ismissing(missing_choice.postdecision_score)

    cash_choice = select_financial_innovation_candidate(menu, Set{String}())
    @test cash_choice.used_cash_fallback
    @test cash_choice.postdecision_score == 0

    full = full_calendar_postdecision_utility(
        ["2025-01-02", "2025-01-03", "2025-01-06"],
        ["2025-01-02", "2025-01-03"],
        [0.01, -0.01];
        explicit_delisting_date = "2025-01-03",
        annualization_sessions = 3,
        risk_aversion = 3,
        minimum_sessions = 3,
    )
    @test full.available
    @test full.cash_sessions == 1
    @test full.observed_sessions == 2

    @test_throws ArgumentError full_calendar_postdecision_utility(
        ["2025-01-02", "2025-01-03", "2025-01-06"],
        ["2025-01-02"],
        [0.01];
        explicit_delisting_date = "2025-01-03",
        annualization_sessions = 3,
        risk_aversion = 3,
        minimum_sessions = 3,
    )
    @test_throws ArgumentError full_calendar_postdecision_utility(
        ["2025-01-02", "2025-01-03", "2025-01-06"],
        ["2025-01-02", "2025-01-03", "2025-01-07"],
        [0.01, -0.01, 0.02];
        annualization_sessions = 3,
        risk_aversion = 3,
        minimum_sessions = 3,
    )
    @test_throws ArgumentError full_calendar_postdecision_utility(
        ["2025-01-02", "2025-01-03", "2025-01-06"],
        ["2025-01-02", "2025-01-03", "2025-01-06"],
        [0.01, -0.01, 0.02];
        explicit_delisting_date = "2025-01-03",
        annualization_sessions = 3,
        risk_aversion = 3,
        minimum_sessions = 3,
    )

    unresolved = full_calendar_postdecision_utility(
        ["2025-01-02", "2025-01-03", "2025-01-06"],
        ["2025-01-02", "2025-01-03"],
        [0.01, -0.01];
        annualization_sessions = 3,
        risk_aversion = 3,
        minimum_sessions = 3,
    )
    @test !unresolved.available
    @test unresolved.reason == "calendar_return_unavailable_without_cash_transition"
end
