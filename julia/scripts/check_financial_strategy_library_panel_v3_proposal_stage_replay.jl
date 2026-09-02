module CheckFinancialStrategyLibraryPanelV3ProposalStageReplay

using TOML

include(joinpath(@__DIR__, "stage_financial_strategy_library_panel_v3_proposal_returns.jl"))
const Stage = StageFinancialStrategyLibraryPanelV3ProposalReturns

export check_proposal_stage_replay, main

const AMENDMENT_LOCK_PATH =
    joinpath(Stage.EXPERIMENT_ROOT, "PROPOSAL_STAGE_REPLAY_AMENDMENT_002_LOCK.toml")
const ORIGINAL_EXECUTION_LOCK_SHA256 =
    "86092535a1f8084ecea0b82b8fc41e59ff703536f7ba29fb649c67ac25683fd3"
const FINAL_COMPUTATION_AMENDMENT_SHA256 =
    "3e5723a6e64275b3c812cd40d7e4f4ed8a73c4420b54eb3e5dc6a1928e3c11ee"

function _effective_contract()
    amendment = TOML.parsefile(AMENDMENT_LOCK_PATH)
    amendment["status"] == "LOCKED_PROPOSAL_STAGE_REPLAY_AMENDMENT_002" ||
        error("proposal stage replay amendment is not locked")
    amendment["historical_evaluation_return_access_permitted"] === false ||
        error("proposal stage replay amendment permits evaluation access")
    for (relative, digest) in Dict{String,String}(amendment["sealed_file_sha256"])
        Stage._sha256_file(joinpath(Stage.REPOSITORY_ROOT, relative)) == digest ||
            error("proposal stage replay input changed: $relative")
    end
    Stage._sha256_file(Stage.EXECUTION_LOCK_PATH) == ORIGINAL_EXECUTION_LOCK_SHA256 ||
        error("original proposal execution lock changed")
    execution = TOML.parsefile(Stage.EXECUTION_LOCK_PATH)
    execution["status"] == "LOCKED_PROPOSAL_EXECUTION" ||
        error("unexpected original proposal execution status")
    execution["historical_proposal_return_access_permitted"] === true ||
        error("original proposal execution lock does not permit proposal access")
    execution["historical_evaluation_return_access_permitted"] === false ||
        error("original proposal execution lock permits evaluation access")
    execution["failed_universe_cell_proposal_access_permitted"] === false ||
        error("original proposal execution lock permits failed-cell access")
    final_computation_lock_path = joinpath(
        Stage.EXPERIMENT_ROOT,
        "PROPOSAL_COMPUTATION_AMENDMENT_001_LOCK_003.toml",
    )
    Stage._sha256_file(final_computation_lock_path) ==
        FINAL_COMPUTATION_AMENDMENT_SHA256 ||
        error("final proposal computation amendment changed")
    final_computation = TOML.parsefile(final_computation_lock_path)
    final_computation["status"] == "LOCKED_PROPOSAL_COMPUTATION_AMENDMENT_001_003" ||
        error("unexpected final proposal computation amendment status")
    final_hashes = Dict{String,String}(final_computation["sealed_file_sha256"])
    for (relative, expected) in Dict{String,String}(execution["sealed_file_sha256"])
        actual = Stage._sha256_file(joinpath(Stage.REPOSITORY_ROOT, relative))
        actual == expected && continue
        get(final_hashes, relative, "") == actual ||
            error("original proposal input changed without a sealed amendment: $relative")
    end
    for (relative, digest) in final_hashes
        Stage._sha256_file(joinpath(Stage.REPOSITORY_ROOT, relative)) == digest ||
            error("final proposal computation input changed: $relative")
    end
    return (;
        lock = execution,
        result = TOML.parsefile(Stage.PREDECISION_RESULT_MANIFEST_PATH),
        pre_stage = TOML.parsefile(Stage.PREDECISION_STAGE_MANIFEST_PATH),
        local_pre_stage = TOML.parsefile(Stage.LOCAL_PREDECISION_STAGE_MANIFEST_PATH),
        selections = TOML.parsefile(Stage.SELECTION_PATH),
        origins = Stage._csv_rows(Stage.ORIGIN_PATH),
        master = TOML.parsefile(Stage.MASTER_MANIFEST_PATH),
    )
end

function check_proposal_stage_replay()
    contract = _effective_contract()
    cells = Stage._load_cells(contract)
    extraction = Stage._extract_all(contract, cells)
    extraction.source_rows == Int(contract.master["retained_master_rows"]) ||
        error("proposal replay identifier/date scan omitted source rows")
    public_cells = Dict{String,Any}[]
    local_cells = Dict{String,Any}[]
    hashes = Dict{String,String}()
    for cell in cells
        calendar = sort!(collect(extraction.calendars[cell.proposal_year]))
        isempty(calendar) && error("proposal replay reference calendar is empty")
        public = Dict{String,Any}(
            "cell_index" => cell.cell_index,
            "origin_id" => cell.origin_id,
            "universe_id" => cell.universe_id,
            "role" => cell.role,
            "universe_status" => cell.universe_status,
            "universe_gate_passed" => cell.gate_passed,
            "proposal_year" => cell.proposal_year,
            "evaluation_year" => cell.evaluation_year,
            "reference_calendar_sessions" => length(calendar),
            "reference_calendar_first_date" => first(calendar),
            "reference_calendar_last_date" => last(calendar),
            "reference_calendar_sha256" => Stage._sha256_text(join(calendar, '\n')),
            "proposal_access_permitted" => cell.gate_passed,
            "proposal_values_materialized" => cell.gate_passed ?
                length(extraction.buffers[cell.cell_index].total_return) : 0,
            "evaluation_values_inspected_materialized_or_used" => 0,
            "return_values_included" => false,
            "licensed_identifiers_included" => false,
        )
        local_cell = copy(public)
        if cell.gate_passed
            table = Stage._combined_table(cell, extraction.buffers[cell.cell_index], calendar)
            relative = joinpath(
                "local_data",
                "proposal",
                "cell-$(lpad(cell.cell_index, 3, '0')).parquet",
            )
            digest, bytes = Stage._install_parquet(
                joinpath(Stage.EXPERIMENT_ROOT, relative),
                table;
                check = true,
            )
            hashes[relative] = digest
            public["local_artifact_relative_path"] = relative
            public["local_artifact_sha256"] = digest
            public["local_artifact_bytes"] = bytes
            public["combined_row_count"] = length(table.permno)
            local_cell = copy(public)
            local_cell["return_values_included"] = true
            local_cell["licensed_identifiers_included"] = true
        else
            isempty(extraction.buffers[cell.cell_index].total_return) ||
                error("failed universe cell materialized proposal values")
            public["failure_code"] = "UNIVERSE_GATE_FAILED"
            public["local_artifact_relative_path"] = ""
            public["local_artifact_sha256"] = ""
            public["local_artifact_bytes"] = 0
            public["combined_row_count"] = 0
            local_cell = copy(public)
        end
        push!(public_cells, public)
        push!(local_cells, local_cell)
    end
    common = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-stage-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "PROPOSAL_RETURNS_STAGED",
        "language" => "Julia",
        "cell_count" => 38,
        "accessed_cell_count" => 37,
        "failed_universe_cells_retained_without_access" => 1,
        "identifier_date_rows_scanned" => extraction.source_rows,
        "unique_proposal_source_rows_materialized" => extraction.materialized,
        "identifier_date_mask_frozen_before_return_cursor" => true,
        "masked_column_mechanics" => "Predecision Access Amendment 002",
        "evaluation_values_inspected" => 0,
        "evaluation_values_materialized" => 0,
        "evaluation_values_used" => 0,
        "proposal_execution_lock_sha256" => Stage._sha256_file(Stage.EXECUTION_LOCK_PATH),
        "predecision_computation_result_seal_sha256" =>
            Stage._sha256_file(Stage.PREDECISION_RESULT_SEAL_PATH),
        "predecision_result_manifest_sha256" =>
            Stage._sha256_file(Stage.PREDECISION_RESULT_MANIFEST_PATH),
        "local_artifact_count" => length(hashes),
    )
    public_payload = copy(common)
    public_payload["return_values_included"] = false
    public_payload["licensed_identifiers_included"] = false
    public_payload["public_promotion_permitted"] = true
    public_payload["cells"] = public_cells
    public_text = Stage._toml_text(public_payload)
    local_payload = copy(common)
    local_payload["return_values_included"] = true
    local_payload["licensed_identifiers_included"] = true
    local_payload["public_promotion_permitted"] = false
    local_payload["public_manifest_sha256"] = Stage._sha256_text(public_text)
    local_payload["local_artifact_sha256"] = hashes
    local_payload["cells"] = local_cells
    local_text = Stage._toml_text(local_payload)
    read(Stage.PUBLIC_STAGE_MANIFEST_PATH, String) == public_text ||
        error("public proposal stage manifest failed amendment-aware replay")
    read(Stage.LOCAL_STAGE_MANIFEST_PATH, String) == local_text ||
        error("local proposal stage manifest failed amendment-aware replay")
    println("V3_PROPOSAL_STAGE_AMENDMENT_AWARE_REPLAY_PASSED")
    println("proposal cells replayed: 37/38; failed cell accessed: false")
    println("evaluation values inspected/materialized/used: 0")
    return true
end

main(args = ARGS) = isempty(args) ? check_proposal_stage_replay() :
    error("proposal stage replay checker takes no arguments")

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    CheckFinancialStrategyLibraryPanelV3ProposalStageReplay.main()
end
