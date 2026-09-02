using Test
using TOML

include(joinpath(
    @__DIR__,
    "..",
    "scripts",
    "stage_financial_strategy_library_panel_v3_evaluation_returns.jl",
))
using .StageFinancialStrategyLibraryPanelV3EvaluationReturns

@testset "v3 evaluation masked-column access sentinel" begin
    report = evaluation_leakage_sentinel()
    @test report["status"] == "SYNTHETIC_EVALUATION_MASK_PASSED"
    @test report["active_evaluation_rows_materialized"] == 1
    @test report["cash_only_full_search_rows_materialized"] == 1
    @test report["failed_cell_rows_materialized"] == 0
    @test report["preevaluation_and_postevaluation_rows_inspected_materialized_or_used"] == 0
    @test report["masked_outputs_identical_across_unmasked_variants"] === true
    @test report["observed_delisting_preserved"] === true
    @test report["capacity_rows_materialized"] == 4
    @test report["lagged_capacity_fields_present"] === true
    @test report["historical_values_accessed"] === false
end

@testset "v3 robustness staging binds all frozen identities and cap50 ranks" begin
    stage = StageFinancialStrategyLibraryPanelV3EvaluationReturns
    mktempdir() do directory
        origin_id = "O001"
        universe_id = "liquid_common_equity"
        local_grid = Dict{String,Any}[]
        public_grid = Dict{String,Any}[]
        choice_hashes = String[]
        index = 0
        for cost in (0.0, 5.0, 15.0, 30.0), risk in (1.0, 3.0),
            hurdle in (0.0, 0.0025, 0.005)
            index += 1
            spec_id = "grid-$(lpad(index, 2, '0'))"
            comparator = Dict{String,Any}(
                "policy_id" => "frontier_only_robust_policy",
                "strategy_ids" => ["comparator-$index"],
                "failure_code" => "",
            )
            safe = Dict{String,Any}(
                "policy_id" => "innovation_safe_robust_policy",
                "strategy_ids" => index == 1 ? ["comparator-1"] : ["safe-$index"],
                "failure_code" => "",
            )
            comparator_hash = stage._robustness_choice_hash(spec_id, comparator)
            safe_hash = stage._robustness_choice_hash(spec_id, safe)
            append!(choice_hashes, (comparator_hash, safe_hash))
            push!(local_grid, Dict{String,Any}(
                "spec_id" => spec_id,
                "cost_bps" => cost,
                "risk_aversion" => risk,
                "adoption_hurdle" => hurdle,
                "comparator_choice" => comparator,
                "safe_choice" => safe,
                "comparator_choice_sha256" => comparator_hash,
                "safe_choice_sha256" => safe_hash,
            ))
            push!(public_grid, Dict{String,Any}(
                "spec_id" => spec_id,
                "cost_bps" => cost,
                "risk_aversion" => risk,
                "adoption_hurdle" => hurdle,
                "same_choice" => index == 1,
                "comparator_choice_sha256" => comparator_hash,
                "safe_choice_sha256" => safe_hash,
            ))
        end
        aggregate = stage._sha256_text(join(choice_hashes, '\n'))
        local_caps = Dict{String,Any}[]
        public_caps = Dict{String,Any}[]
        for cap in (50, 100)
            context = "common_equity_cap$cap"
            comparator = Dict{String,Any}(
                "policy_id" => "frontier_only_robust_policy",
                "strategy_ids" => ["cap$cap-comparator"],
                "failure_code" => "",
            )
            safe = Dict{String,Any}(
                "policy_id" => "innovation_safe_robust_policy",
                "strategy_ids" => ["cap$cap-safe"],
                "failure_code" => "",
            )
            comparator_hash = stage._robustness_choice_hash(context, comparator)
            safe_hash = stage._robustness_choice_hash(context, safe)
            push!(local_caps, Dict{String,Any}(
                "liquidity_cap" => cap,
                "available" => true,
                "comparator_choice" => comparator,
                "safe_choice" => safe,
                "comparator_choice_sha256" => comparator_hash,
                "safe_choice_sha256" => safe_hash,
            ))
            push!(public_caps, Dict{String,Any}(
                "liquidity_cap" => cap,
                "available" => true,
                "same_choice" => false,
                "comparator_choice_sha256" => comparator_hash,
                "safe_choice_sha256" => safe_hash,
            ))
        end
        push!(local_caps, Dict{String,Any}(
            "liquidity_cap" => 200,
            "available" => false,
        ))
        push!(public_caps, Dict{String,Any}(
            "liquidity_cap" => 200,
            "available" => false,
        ))
        artifact = Dict{String,Any}(
            "cell_index" => 1,
            "origin_id" => origin_id,
            "universe_id" => universe_id,
            "universe_gate_passed" => true,
            "grid_records" => local_grid,
            "grid_choice_aggregate_sha256" => aggregate,
            "common_equity_cap_records" => local_caps,
        )
        artifact_path = joinpath(directory, "synthetic-robustness.toml")
        open(artifact_path, "w") do io
            TOML.print(io, artifact; sorted = true)
        end
        local_manifest_cell = Dict{String,Any}(
            "local_artifact_relative_path" =>
                relpath(artifact_path, stage.EXPERIMENT_ROOT),
            "local_artifact_sha256" => stage._sha256_file(artifact_path),
            "grid_choice_aggregate_sha256" => aggregate,
        )
        public = Dict{String,Any}(
            "cell_index" => 1,
            "origin_id" => origin_id,
            "universe_id" => universe_id,
            "universe_gate_passed" => true,
            "grid_records" => public_grid,
            "grid_choice_aggregate_sha256" => aggregate,
            "common_equity_cap_records" => public_caps,
        )
        selection = Dict{String,Any}(
            "universe_id" => universe_id,
            "selected" => [Dict{String,Any}(
                "rank" => rank,
                "permno" => 10_000 + rank,
            ) for rank in reverse(1:100)],
        )
        binding = stage._validate_robustness_binding(
            public, local_manifest_cell, selection,
        )
        @test length(binding.selected_strategy_ids) == 51
        @test "comparator-1" in binding.selected_strategy_ids
        @test "cap50-safe" in binding.selected_strategy_ids
        @test length(binding.cap50_permnos) == 50
        @test binding.cap50_permnos == Set(10_001:10_050)
        @test !((10_051) in binding.cap50_permnos)
        public["grid_records"][1]["safe_choice_sha256"] = repeat("0", 64)
        @test_throws ErrorException stage._validate_robustness_binding(
            public, local_manifest_cell, selection,
        )
    end
end

@testset "v3 proposal public/local choice identity binding" begin
    policy_ids = StageFinancialStrategyLibraryPanelV3EvaluationReturns.POLICY_IDS
    local_choices = [
        Dict{String,Any}(
            "policy_id" => policy_id,
            "available" => true,
            "strategy_ids" => policy_id == "equal_weight_available_policy" ?
                ["strategy-a", "strategy-b"] : ["strategy-a"],
            "strategy_id" => policy_id == "equal_weight_available_policy" ? "" : "strategy-a",
            "failure_code" => "",
        ) for policy_id in policy_ids
    ]
    choice_hashes = [
        StageFinancialStrategyLibraryPanelV3EvaluationReturns._sha256_text(
            join([choice["policy_id"]; choice["strategy_ids"]], '\0'),
        ) for choice in local_choices
    ]
    aggregate = StageFinancialStrategyLibraryPanelV3EvaluationReturns._sha256_text(
        join(choice_hashes, '\n'),
    )
    public = Dict{String,Any}(
        "choice_aggregate_sha256" => aggregate,
        "primary_choices" => [
            Dict{String,Any}(
                "policy_id" => policy_id,
                "available" => true,
                "choice_sha256" => digest,
            ) for (policy_id, digest) in zip(policy_ids, choice_hashes)
        ],
    )
    local_cell = Dict{String,Any}(
        "choice_aggregate_sha256" => aggregate,
        "primary_choices" => local_choices,
    )
    @test StageFinancialStrategyLibraryPanelV3EvaluationReturns._validate_choice_binding(
        public,
        local_cell,
    ) == aggregate
    public["primary_choices"][1]["choice_sha256"] = repeat("0", 64)
    @test_throws ErrorException StageFinancialStrategyLibraryPanelV3EvaluationReturns._validate_choice_binding(
        public,
        local_cell,
    )
end
