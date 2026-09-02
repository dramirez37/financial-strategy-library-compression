using Test

include(joinpath(
    @__DIR__,
    "..",
    "scripts",
    "run_financial_strategy_library_panel_v3_evaluation_amendment_001.jl",
))
const AmendmentRunner =
    RunFinancialStrategyLibraryPanelV3EvaluationAmendment001
const AmendmentStage = AmendmentRunner.AmendmentStage

function _choice(policy_id, strategy_ids; failure_code = "")
    return Dict{String,Any}(
        "policy_id" => String(policy_id),
        "strategy_ids" => String.(collect(strategy_ids)),
        "failure_code" => String(failure_code),
    )
end

@testset "staging amendment 001 lock seals original and downstream authority" begin
    include(joinpath(
        @__DIR__, "..", "scripts",
        "lock_financial_strategy_library_panel_v3_evaluation_staging_validator_amendment_001.jl",
    ))
    authority =
        LockFinancialStrategyLibraryPanelV3EvaluationStagingValidatorAmendment001
    payload = authority._payload()
    @test payload["original_evaluation_execution_lock_sha256"] ==
        "3bdab5694d65f2bbf6b8995df0cd4a6939b25eca5b1f8c650f693ad7c9b1a67b"
    @test payload["original_validator_mismatch_count"] == 24
    @test payload["original_validator_mismatch_cell_index"] == 2
    @test payload["available_record_mismatch_count"] == 0
    @test payload["amended_validator_mismatch_count"] == 0
    @test payload["original_sealed_file_count"] == 114
    @test all(haskey(payload["sealed_file_sha256"], path) for path in (
        "julia/scripts/stage_financial_strategy_library_panel_v3_evaluation_returns_amendment_001.jl",
        "julia/scripts/run_financial_strategy_library_panel_v3_evaluation_amendment_001.jl",
        "julia/scripts/seal_financial_strategy_library_panel_v3_evaluation_result_amendment_001.jl",
    ))
    @test payload["final_result_seal_requires_amendment_lock_and_receipt"] === true
end

@testset "staging amendment 001 defines availability-aware same-choice semantics" begin
    available_record = Dict{String,Any}(
        "available" => true,
        "same_choice" => true,
    )
    available_local = Dict{String,Any}()
    comparator = _choice("frontier_only_robust_policy", ["frozen-a"])
    safe = _choice("innovation_safe_robust_policy", ["frozen-a"])
    @test AmendmentStage._validate_grid_same_choice(
        available_record, available_local, comparator, safe,
    ) === true

    available_record["same_choice"] = false
    safe["strategy_ids"] = ["frozen-b"]
    @test AmendmentStage._validate_grid_same_choice(
        available_record, available_local, comparator, safe,
    ) === false

    unavailable_record = Dict{String,Any}(
        "available" => false,
        "same_choice" => false,
        "failure_code" => "UNIVERSE_GATE_FAILED",
    )
    unavailable_local = Dict{String,Any}(
        "failure_code" => "UNIVERSE_GATE_FAILED",
    )
    unavailable_comparator = _choice(
        "frontier_only_robust_policy", String[];
        failure_code = "UNIVERSE_GATE_FAILED",
    )
    unavailable_safe = _choice(
        "innovation_safe_robust_policy", String[];
        failure_code = "UNIVERSE_GATE_FAILED",
    )
    @test unavailable_comparator["strategy_ids"] == unavailable_safe["strategy_ids"]
    @test AmendmentStage._validate_grid_same_choice(
        unavailable_record,
        unavailable_local,
        unavailable_comparator,
        unavailable_safe,
    ) === false
    unavailable_record["same_choice"] = true
    @test_throws ErrorException AmendmentStage._validate_grid_same_choice(
        unavailable_record,
        unavailable_local,
        unavailable_comparator,
        unavailable_safe,
    )
    unavailable_record["same_choice"] = false
    unavailable_safe["failure_code"] = ""
    @test_throws ErrorException AmendmentStage._validate_grid_same_choice(
        unavailable_record,
        unavailable_local,
        unavailable_comparator,
        unavailable_safe,
    )
end

@testset "staging amendment 001 clears only the sealed failed-cell pre-scan blocker" begin
    base = AmendmentStage.BaseStage
    contract = base._load_contract()
    cells = base._load_cells(contract)
    @test length(cells) == 38
    @test count(cell -> cell.gate_passed, cells) == 37
    failed = only(filter(cell -> !cell.gate_passed, cells))
    @test failed.cell_index == 2
    @test isempty(failed.selected_permnos)
    @test isempty(failed.choices)
    @test failed.robustness_selected_strategy_count == 0
    @test all(cell -> cell.cell_index == 2 || cell.gate_passed, cells)

    downstream_stage = AmendmentRunner.BaseRunner.Stage
    downstream_contract = downstream_stage._load_contract()
    downstream_cells = downstream_stage._load_cells(downstream_contract)
    @test length(downstream_cells) == 38
    @test only(filter(cell -> !cell.gate_passed, downstream_cells)).cell_index == 2
end
