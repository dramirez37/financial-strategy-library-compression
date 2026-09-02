using SHA: sha256
using Test
using TOML

include(joinpath(
    @__DIR__,
    "..",
    "scripts",
    "run_financial_strategy_library_panel_v3_evaluation.jl",
))
using .RunFinancialStrategyLibraryPanelV3Evaluation

const Runner = RunFinancialStrategyLibraryPanelV3Evaluation
const EvalCore = Runner.Core

@testset "v3 evaluation runner preserves security-contiguous history" begin
    panel = table_to_security_panel((;
        permno = Int64[10, 10, 10, 20, 20, 20],
        date = [
            "2000-01-03", "2000-01-04", "2001-01-03",
            "2000-01-03", "2000-01-04", "2001-01-03",
        ],
        total_return = Union{Missing,Float64}[0.01, -1.0, missing, 0.02, 0.03, 0.04],
        return_available = Bool[true, true, false, true, true, true],
        terminal_delisting = Bool[false, true, false, false, false, false],
        close = Union{Missing,Float64}[missing, 10.0, 9.0, missing, 20.0, 21.0],
        volume = Union{Missing,Float64}[missing, 100.0, 110.0, missing, 200.0, 210.0],
    ))
    @test panel.security_ids == [10, 20]
    @test panel.dates == ["2000-01-03", "2000-01-04", "2001-01-03"]
    @test size(panel.security_returns) == (3, 2)
    @test panel.security_returns[2, 1] == -1.0
    @test panel.terminal_delisting[2, 1]
    @test !panel.return_available[3, 1]
    @test panel.close[3, 2] == 21.0
    @test panel.volume[2, 1] == 100.0

    @test_throws ErrorException table_to_security_panel((;
        permno = Int64[10, 20, 10, 20],
        date = ["2000-01-03", "2000-01-03", "2000-01-04", "2000-01-04"],
        total_return = [0.01, 0.02, 0.03, 0.04],
        return_available = trues(4),
        terminal_delisting = falses(4),
        close = fill(10.0, 4),
        volume = fill(100.0, 4),
    ))
end

function _synthetic_policy_outcome(policy_id; identity = "frozen-identity", value = 0.01)
    return EvalCore.PolicyEvaluationOutcome(
        "O001",
        "liquid_common_equity",
        String(policy_id),
        [String(identity)],
        true,
        20,
        Float64(value),
        Float64(value) + 0.001,
        0.0005,
        0.0005,
        "",
    )
end

@testset "v3 runner retains all five sealed primary policy rows" begin
    policies = collect(Runner.Stage.POLICY_IDS)
    unavailable = "innovation_safe_forced_max"
    proposal = Dict{String,Any}(
        "primary_choices" => [Dict{String,Any}(
            "policy_id" => policy_id,
            "available" => policy_id != unavailable,
            "choice_sha256" => "sealed-$policy_id",
            "failure_code" => policy_id == unavailable ?
                "NO_COMPLETE_ACTIVE_PROPOSAL_PATH" : "",
        ) for policy_id in policies],
    )
    outcomes = [
        _synthetic_policy_outcome(policy_id) for policy_id in policies if
        policy_id != unavailable
    ]
    records = Runner._public_policy_outcomes(proposal, outcomes)
    @test length(records) == 5
    @test getindex.(records, "policy_id") == policies
    @test all(record -> record["choice_sha256"] ==
        "sealed-$(record["policy_id"])", records)
    forced = only(filter(record -> record["policy_id"] == unavailable, records))
    @test forced["available"] === false
    @test forced["failure_code"] == "NO_COMPLETE_ACTIVE_PROPOSAL_PATH"
    @test sum(length(Runner._public_policy_outcomes(proposal, outcomes)) for _ in 1:38) == 190

    failed = Dict{String,Any}(
        "primary_choices" => [Dict{String,Any}(
            "policy_id" => policy_id,
            "available" => false,
            "choice_sha256" => "failed-$policy_id",
            "failure_code" => "UNIVERSE_GATE_FAILED",
        ) for policy_id in policies],
    )
    failed_records = Runner._public_policy_outcomes(failed, EvalCore.PolicyEvaluationOutcome[])
    @test length(failed_records) == 5
    @test all(record -> record["available"] === false, failed_records)
    @test all(record -> record["failure_code"] == "UNIVERSE_GATE_FAILED", failed_records)
    contrast = EvalCore.OriginEvaluationContrast(
        "O001", "liquid_common_equity", true, "raw-safe", "raw-comparator",
        0.001, 0.002, 0.0004, 0.0006, false, "",
    )
    public_contrast = Runner._public_contrast(
        contrast;
        safe_choice_sha256 = "sealed-primary-safe",
        comparator_choice_sha256 = "sealed-primary-comparator",
    )
    @test public_contrast["safe_choice_sha256"] == "sealed-primary-safe"
    @test public_contrast["comparator_choice_sha256"] ==
        "sealed-primary-comparator"
end

function _robustness_outcome(spec_id, cost_bps, risk_aversion, hurdle; same = false)
    comparator = _synthetic_policy_outcome(
        "frontier_only_robust_policy";
        identity = same ? "shared" : "comparator-$spec_id",
        value = 0.01,
    )
    safe = _synthetic_policy_outcome(
        "innovation_safe_robust_policy";
        identity = same ? "shared" : "safe-$spec_id",
        value = same ? 0.01 : 0.011,
    )
    contrast = EvalCore.OriginEvaluationContrast(
        "O001",
        "liquid_common_equity",
        true,
        only(safe.choice_ids),
        only(comparator.choice_ids),
        same ? 0.0 : 0.001,
        same ? 0.0 : 0.001,
        0.0,
        0.0,
        same,
        "",
    )
    return EvalCore.RobustnessEvaluationOutcome(
        String(spec_id),
        "cost_risk_hurdle_grid",
        0,
        Float64(cost_bps),
        Float64(risk_aversion),
        Float64(hurdle),
        comparator,
        safe,
        contrast,
    )
end

@testset "v3 runner preserves 912 specs and 1824 sealed robustness choices" begin
    grid = Dict{String,Any}[]
    outcomes = EvalCore.RobustnessEvaluationOutcome[]
    index = 0
    for cost in (0.0, 5.0, 15.0, 30.0), risk in (1.0, 3.0),
        hurdle in (0.0, 0.0025, 0.005)
        index += 1
        spec_id = "grid-$(lpad(index, 2, '0'))"
        same = index == 1
        push!(grid, Dict{String,Any}(
            "spec_id" => spec_id,
            "cost_bps" => cost,
            "risk_aversion" => risk,
            "adoption_hurdle" => hurdle,
            "available" => true,
            "same_choice" => same,
            "comparator_choice_sha256" => "sealed-comparator-$spec_id",
            "safe_choice_sha256" => "sealed-safe-$spec_id",
        ))
        push!(outcomes, _robustness_outcome(spec_id, cost, risk, hurdle; same))
    end
    available_cell = Dict{String,Any}(
        "grid_records" => grid,
        "permuted_closure_sham_available" => false,
        "permuted_closure_sham_failure_code" =>
            "DESIGN_NOT_FROZEN_BEFORE_PROPOSAL",
        "common_equity_cap_records" => [Dict{String,Any}(
            "liquidity_cap" => cap,
            "available" => false,
            "failure_code" => cap == 200 ?
                "DESIGN_NOT_FROZEN_BEFORE_PROPOSAL" : "NOT_APPLICABLE_TO_ETF",
        ) for cap in (50, 100, 200)],
    )
    published = Runner._public_robustness(available_cell, outcomes)
    @test published["grid_spec_count"] == 24
    @test published["grid_policy_choice_count"] == 48
    @test length(published["common_equity_cap_records"]) == 3
    @test published["grid_records"][1]["contrast"]["same_choice"] === true
    @test published["grid_records"][1]["contrast"]["certainty_equivalent_difference"] == 0.0
    @test published["grid_records"][2]["safe_choice_sha256"] == "sealed-safe-grid-02"
    @test !any(haskey(record, "strategy_ids") for record in published["grid_records"])

    failed_cell = Dict{String,Any}(
        "permuted_closure_sham_available" => false,
        "permuted_closure_sham_failure_code" =>
            "DESIGN_NOT_FROZEN_BEFORE_PROPOSAL",
        "grid_records" => [Dict{String,Any}(
            "spec_id" => record["spec_id"],
            "cost_bps" => record["cost_bps"],
            "risk_aversion" => record["risk_aversion"],
            "adoption_hurdle" => record["adoption_hurdle"],
            "available" => false,
            "same_choice" => false,
            "comparator_choice_sha256" => "failed-comparator-$(record["spec_id"])",
            "safe_choice_sha256" => "failed-safe-$(record["spec_id"])",
            "failure_code" => "UNIVERSE_GATE_FAILED",
        ) for record in grid],
        "common_equity_cap_records" => [Dict{String,Any}(
            "liquidity_cap" => cap,
            "available" => false,
            "failure_code" => "UNIVERSE_GATE_FAILED",
        ) for cap in (50, 100, 200)],
    )
    failed = Runner._public_robustness(
        failed_cell, EvalCore.RobustnessEvaluationOutcome[],
    )
    cells = [published for _ in 1:37]
    push!(cells, failed)
    @test sum(Int(cell["grid_spec_count"]) for cell in cells) == 912
    @test sum(Int(cell["grid_policy_choice_count"]) for cell in cells) == 1824
    @test sum(count(record -> haskey(record, "contrast"), cell["grid_records"])
        for cell in cells) == 888
    @test all(record -> record["failure_code"] == "UNIVERSE_GATE_FAILED",
        failed["grid_records"])
end

@testset "v3 execution authority pins its full Julia runtime closure" begin
    lock_script = joinpath(
        @__DIR__, "..", "scripts",
        "lock_financial_strategy_library_panel_v3_evaluation_execution.jl",
    )
    include(lock_script)
    lock_module = LockFinancialStrategyLibraryPanelV3EvaluationExecution
    @test "julia/scripts/lock_financial_strategy_library_panel_v3_evaluation_execution.jl" in
        lock_module.IMPLEMENTATION_PATHS
    contract = lock_module._proposal_seal_contract()
    @test contract.binding["status"] == "LOCKED_PREDECISION_BINDING_AMENDMENT_003"
    @test length(contract.binding_hashes) == 42
    @test contract.binding["strategy_innovation_include_count"] == 29
    @test haskey(contract.binding_hashes, "julia/src/StrategyInnovation.jl")
    @test all(((relative, digest),) -> begin
        path = joinpath(lock_module.REPOSITORY_ROOT, relative)
        isfile(path) && open(path, "r") do io
            bytes2hex(sha256(io)) == digest
        end
    end, collect(contract.binding_hashes))
    payload = lock_module._payload()
    @test payload["reality_check_seed_base"] == 310003 &&
        payload["hansen_spa_seed_base"] == 310004 &&
        payload["pbo_cscv_seed_base"] == 310005
    @test payload["robustness_grid_cell_spec_denominator"] == 912
    @test payload["robustness_grid_policy_choice_denominator"] == 1824
    @test haskey(
        payload["sealed_file_sha256"],
        "julia/scripts/lock_financial_strategy_library_panel_v3_evaluation_execution.jl",
    )
    @test haskey(
        payload["sealed_file_sha256"],
        "experiments/financial_strategy_library_panel_v3/registry/SEED_REGISTRY.csv",
    )
end
