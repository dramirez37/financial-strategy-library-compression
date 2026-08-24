@testset "controlled theorem-mechanism experiment families" begin
    config = load_mechanism_config()
    result = run_theorem_mechanism_experiments(
        config;
        policy_grid_size_override = 21,
    )

    @test result.all_passed
    @test result.validation_count == 367
    @test getfield.(result.summaries, :family) == string.(collect('A':'G'))

    quotient = result.dynamic_quotient
    @test quotient.core.left != quotient.core.right
    @test quotient.core.left_state == quotient.core.right_state

    frontier_closure = result.frontier_closure.fixture.values
    @test frontier_closure.operational.passive - frontier_closure.base.passive == 3
    @test frontier_closure.operational.premium == frontier_closure.base.premium
    @test frontier_closure.generative.passive == frontier_closure.base.passive
    @test frontier_closure.generative.premium - frontier_closure.base.premium == 4

    deletion = result.safe_deletion
    @test length(deletion.source) == 4
    @test length(deletion.final) == 2
    @test deletion.source_state == deletion.final_state
    @test deletion.before == deletion.after

    for case in result.frontier_pruning.cases
        @test case.loss == case.reward / 2
        @test case.unpruned_state.frontier == case.pruned_state.frontier
        @test case.unpruned_state.closure != case.pruned_state.closure
    end

    decomposition = result.decomposition.cases
    @test [(case.operational, case.generative) for case in decomposition] ==
          [(3 // 1, 0 // 1), (0 // 1, 4 // 1), (3 // 1, 1 // 1)]
    @test all(case.total == case.operational + case.generative for case in decomposition)

    coverage = result.coverage.cases
    @test getfield.(coverage, :components) == [1, 1, 2, 2]
    @test coverage[1].kernel_assumption
    @test coverage[2].kernel_assumption
    @test !coverage[3].kernel_assumption
    @test coverage[4].potential == ExactRational[4, 41 // 32, 1 // 2, 41 // 32, 4]
    ranking = result.coverage.ranking
    @test all(row.coverage_potential == row.date_first_target for row in ranking.candidate_rows)
    @test getfield.(ranking.candidate_rows, :candidate_id)[
        sortperm(getfield.(ranking.candidate_rows, :coverage_potential); rev = true)
    ] == [
        "future-common",
        "future-common-clone",
        "current-specialist",
        "balanced",
        "rare-state-specialist",
        "rare-state-clone",
    ]
    ranking_by_method = Dict(Symbol(row.method) => row for row in ranking.ranking_summary)
    @test ranking_by_method[:coverage_potential].spearman_rank_correlation == 1
    @test ranking_by_method[:coverage_potential].top_one_regret == 0
    @test all(
        ranking_by_method[method].top_one_regret > 0 for method in
        (:current_belief_improvement, :average_gap, :raw_parameter_novelty)
    )
    @test getfield.(ranking.individual_selection, :selected_candidate) ==
          ["future-common", "future-common-clone"]
    @test getfield.(ranking.marginal_selection, :selected_candidate) ==
          ["future-common", "current-specialist"]
    @test last(ranking.individual_selection).cumulative_set_value == 10
    @test last(ranking.marginal_selection).cumulative_set_value == 69 // 4

    policy = result.dynamic_policy
    counts(axis) = [
        case.research_count for case in policy.scenarios if case.axis == axis
    ]
    @test issorted(counts("cost"); rev = true)
    @test issorted(counts("delay"); rev = true)
    @test issorted(counts("discount"))
    @test all(case.components <= 1 for case in policy.scenarios)
    @test all(row.converged for row in policy.policy_summary)

    repeat_policy = run_dynamic_policy_family(
        config,
        research_rng(UInt64(config["seed"]));
        grid_size_override = 21,
    )
    @test repeat_policy.success_probabilities == policy.success_probabilities
    @test repeat_policy.policy_summary == policy.policy_summary

    @test_throws ErrorException TheoremMechanismExperiments._require_pattern(
        false,
        "TEST-GATE",
        "intentional identity failure",
    )
end

@testset "controlled theorem-mechanism artifact generation" begin
    config = load_mechanism_config()
    result = run_theorem_mechanism_experiments(
        config;
        policy_grid_size_override = 21,
    )
    mktempdir() do artifact_root
        paths = write_theorem_mechanism_outputs(
            result,
            config,
            DEFAULT_MECHANISM_CONFIG;
            artifact_root,
        )
        @test Set(keys(paths)) == Set((
            "raw",
            "summary_csv",
            "policy_summary_csv",
            "decomposition_csv",
            "pruning_figure_data",
            "decomposition_figure_data",
            "coverage_figure_data",
            "coverage_ranking_csv",
            "coverage_ranking_summary_csv",
            "coverage_selection_csv",
            "policy_figure_data",
            "pruning_figure",
            "decomposition_figure",
            "coverage_figure",
            "coverage_ranking_figure",
            "policy_figure",
            "summary_json",
            "report",
            "metadata",
        ))
        @test all(isfile, values(paths))
        @test countlines(paths["raw"]) == length(result.raw) + 1
        @test occursin("All seven controlled experiment families passed", read(paths["report"], String))
        @test occursin("<svg", read(paths["policy_figure"], String))
        @test occursin("artifact_sha256", read(paths["metadata"], String))
    end
end
