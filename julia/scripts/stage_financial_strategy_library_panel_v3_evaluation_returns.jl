module StageFinancialStrategyLibraryPanelV3EvaluationReturns

using Parquet
using SHA: sha256
using Tables
using TOML

include(joinpath(@__DIR__, "stage_financial_strategy_library_panel_v3_predecision_returns.jl"))
const MaskedReader = StageFinancialStrategyLibraryPanelV3PredecisionReturns

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV3Evaluation.jl"))
using .FinancialStrategyLibraryPanelV3Evaluation: FrozenEvaluationChoice

export EvaluationCell, evaluation_leakage_sentinel, stage_evaluation_returns

const CASH_ID = "mandatory_inactive_cash"
const POLICY_IDS = [
    "frontier_only_robust_policy",
    "innovation_safe_robust_policy",
    "innovation_safe_forced_max",
    "equal_weight_available_policy",
    "source_uncompressed_robust_policy",
]
const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const EXECUTION_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EVALUATION_EXECUTION_LOCK.toml")
const PROPOSAL_RESULT_SEAL_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_RESULT_SEAL.toml")
const PROPOSAL_STAGE_REPLAY_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_STAGE_REPLAY_AMENDMENT_002_LOCK.toml")
const PROPOSAL_ROBUSTNESS_RESULT_SEAL_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_ROBUSTNESS_RESULT_SEAL.toml")
const PROPOSAL_ROBUSTNESS_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "proposal_robustness",
    "PROPOSAL_ROBUSTNESS_MANIFEST.toml",
)
const LOCAL_PROPOSAL_ROBUSTNESS_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal_robustness",
    "PROPOSAL_ROBUSTNESS_LOCAL_MANIFEST.toml",
)
const PROPOSAL_RESULT_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "proposal_policy",
    "PROPOSAL_POLICY_MANIFEST.toml",
)
const LOCAL_PROPOSAL_RESULT_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal_policy",
    "PROPOSAL_POLICY_LOCAL_MANIFEST.toml",
)
const SELECTION_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "universe_census",
    "UNIVERSE_SELECTIONS.toml",
)
const MASTER_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v2",
    "local_data",
    "master_market_panel",
)
const MASTER_MANIFEST_PATH = joinpath(MASTER_ROOT, "MASTER_MANIFEST.toml")
const LOCAL_STAGE_ROOT = joinpath(EXPERIMENT_ROOT, "local_data", "evaluation")
const LOCAL_STAGE_MANIFEST_PATH =
    joinpath(LOCAL_STAGE_ROOT, "EVALUATION_STAGE_LOCAL_MANIFEST.toml")
const PUBLIC_STAGE_ROOT = joinpath(EXPERIMENT_ROOT, "evaluation_stage")
const PUBLIC_STAGE_MANIFEST_PATH =
    joinpath(PUBLIC_STAGE_ROOT, "EVALUATION_STAGE_MANIFEST.toml")

struct EvaluationCell
    cell_index::Int
    origin_id::String
    universe_id::String
    role::String
    universe_status::String
    gate_passed::Bool
    evaluation_year::Int
    selected_permnos::Set{Int}
    cap50_permnos::Set{Int}
    robustness_selected_strategy_count::Int
    choices::Vector{FrozenEvaluationChoice}
    proposal_relative_path::String
    proposal_sha256::String
end

mutable struct SparseEvaluationBuffer
    permno::Vector{Int64}
    date::Vector{String}
    total_return::Vector{Union{Missing,Float64}}
    return_available::Vector{Bool}
    terminal_delisting::Vector{Bool}
    return_flag::Vector{String}
    delisting_flag::Vector{String}
    capacity_permno::Vector{Int64}
    capacity_date::Vector{String}
    close::Vector{Union{Missing,Float64}}
    volume::Vector{Union{Missing,Float64}}
end

SparseEvaluationBuffer() = SparseEvaluationBuffer(
    Int64[], String[], Union{Missing,Float64}[], Bool[], Bool[], String[], String[],
    Int64[], String[], Union{Missing,Float64}[], Union{Missing,Float64}[],
)

struct TargetRow
    row_index::Int
    permno::Int
    date::String
    cell_indices::Vector{Int}
end

struct EvaluationChunk
    buffers::Vector{SparseEvaluationBuffer}
    reference_dates::Dict{Int,Set{String}}
    source_rows::Int
    materialized_rows::Int
    capacity_materialized_rows::Int
    source_sha256::String
end

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

_sha256_text(value) = bytes2hex(sha256(codeunits(String(value))))

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _write_new_or_identical(path, content)
    if isfile(path)
        read(path, String) == content ||
            error("refusing to replace a nonidentical evaluation artifact")
        return path
    end
    mkpath(dirname(path))
    temporary = path * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, content)
    end
    mv(temporary, path)
    return path
end

function _install_parquet(path, table; check)
    mktempdir() do directory
        candidate = joinpath(directory, basename(path))
        Parquet.write_parquet(candidate, table)
        digest = _sha256_file(candidate)
        bytes = filesize(candidate)
        if check
            isfile(path) || error("evaluation-stage parquet is absent")
            _sha256_file(path) == digest || error("evaluation-stage parquet changed")
        elseif isfile(path)
            _sha256_file(path) == digest ||
                error("refusing to replace evaluation-stage parquet")
        else
            mkpath(dirname(path))
            mv(candidate, path)
        end
        return digest, bytes
    end
end

function _load_contract()
    for path in (
        EXECUTION_LOCK_PATH,
        PROPOSAL_RESULT_SEAL_PATH,
        PROPOSAL_STAGE_REPLAY_LOCK_PATH,
        PROPOSAL_ROBUSTNESS_RESULT_SEAL_PATH,
        PROPOSAL_ROBUSTNESS_MANIFEST_PATH,
        LOCAL_PROPOSAL_ROBUSTNESS_MANIFEST_PATH,
        PROPOSAL_RESULT_MANIFEST_PATH,
        LOCAL_PROPOSAL_RESULT_MANIFEST_PATH,
        SELECTION_PATH,
        MASTER_MANIFEST_PATH,
    )
        isfile(path) || error(
            "required evaluation-stage input is absent: $(relpath(path, REPOSITORY_ROOT))",
        )
    end
    lock = TOML.parsefile(EXECUTION_LOCK_PATH)
    lock["status"] == "LOCKED_EVALUATION_EXECUTION" ||
        error("evaluation execution is not locked")
    lock["historical_evaluation_return_access_permitted"] === true ||
        error("evaluation return access is not permitted")
    lock["evaluation_scope"] == "all five frozen registered policies; primary headline fixed" ||
        error("evaluation scope is not the frozen registered policy family")
    lock["failed_universe_cell_evaluation_access_permitted"] === false ||
        error("evaluation lock permits failed-universe access")
    lock["frozen_candidate_diagnostic_evaluation_access_permitted"] === true ||
        error("evaluation lock omits registered search-wide diagnostics")
    lock["frozen_candidate_count_per_gate_passed_cell"] == 96 ||
        error("evaluation lock candidate denominator changed")
    lock["policy_reselection_or_repair_permitted"] === false ||
        error("evaluation lock permits ex-post selection")
    lock["capacity_source_fields"] == ["close", "volume"] ||
        error("evaluation lock capacity source fields changed")
    lock["capacity_choice_rule"] == "SCORE_FROZEN_CHOICES_ONLY_NO_RESELECTION" ||
        error("evaluation lock capacity choice rule changed")
    lock["reality_check_seed_base"] == 310003 &&
        lock["hansen_spa_seed_base"] == 310004 &&
        lock["pbo_cscv_seed_base"] == 310005 &&
        lock["permuted_closure_sham_seed_base_reserved_not_used"] == 310006 &&
        lock["capacity_seed_base"] == 310007 ||
        error("evaluation lock seed namespaces changed")
    lock["reality_check_seed_scope"] == "origin_id|universe_id" &&
        lock["hansen_spa_seed_scope"] == "origin_id|universe_id" &&
        lock["pbo_cscv_seed_scope"] == "origin_id|universe_id" &&
        lock["capacity_seed_scope"] == "origin_id|universe_id|aum_id" ||
        error("evaluation lock seed scopes changed")
    lock["robustness_grid_cell_spec_denominator"] == 912 &&
        lock["robustness_grid_policy_choice_denominator"] == 1824 &&
        lock["robustness_grid_available_cell_spec_count"] == 888 &&
        lock["robustness_grid_available_policy_choice_count"] == 1776 ||
        error("evaluation lock robustness denominators changed")
    lock["registered_primary_policy_row_denominator"] == 190 ||
        error("evaluation lock primary policy denominator changed")
    lock["leave_one_origin_out_omission_count"] == 19 &&
        lock["leave_one_origin_out_rule"] == "AGGREGATION_ONLY_NO_RESELECTION" ||
        error("evaluation lock leave-one-origin-out rule changed")
    lock["master_market_panel_manifest_sha256"] == _sha256_file(MASTER_MANIFEST_PATH) ||
        error("evaluation lock is not bound to the master manifest")
    seal_digest = _sha256_file(PROPOSAL_RESULT_SEAL_PATH)
    lock["proposal_policy_result_seal_sha256"] == seal_digest ||
        error("evaluation lock is not bound to the proposal-policy result seal")
    lock["proposal_stage_replay_amendment_lock_sha256"] ==
        _sha256_file(PROPOSAL_STAGE_REPLAY_LOCK_PATH) ||
        error("evaluation lock is not bound to the proposal-stage replay amendment")
    lock["proposal_robustness_result_seal_sha256"] ==
        _sha256_file(PROPOSAL_ROBUSTNESS_RESULT_SEAL_PATH) ||
        error("evaluation lock is not bound to the proposal robustness result")
    lock["proposal_robustness_manifest_sha256"] ==
        _sha256_file(PROPOSAL_ROBUSTNESS_MANIFEST_PATH) ||
        error("evaluation lock is not bound to the public robustness manifest")
    lock["proposal_robustness_local_manifest_sha256"] ==
        _sha256_file(LOCAL_PROPOSAL_ROBUSTNESS_MANIFEST_PATH) ||
        error("evaluation lock is not bound to the local robustness manifest")
    seal = TOML.parsefile(PROPOSAL_RESULT_SEAL_PATH)
    seal["status"] == "SEALED_PROPOSAL_POLICY_RESULT" ||
        error("proposal policy result is not sealed")
    seal["historical_evaluation_return_access_permitted"] === false ||
        error("proposal result seal crossed the evaluation boundary")
    seal["evaluation_values_inspected_before_seal"] == 0 ||
        error("proposal result seal reports prior evaluation inspection")
    seal["evaluation_values_materialized_before_seal"] == 0 ||
        error("proposal result seal reports prior evaluation materialization")
    seal["evaluation_values_used_before_seal"] == 0 ||
        error("proposal result seal reports prior evaluation use")
    seal["proposal_policy_manifest_sha256"] == _sha256_file(PROPOSAL_RESULT_MANIFEST_PATH) ||
        error("proposal result seal is not bound to its public manifest")
    seal["proposal_policy_local_manifest_sha256"] ==
        _sha256_file(LOCAL_PROPOSAL_RESULT_MANIFEST_PATH) ||
        error("proposal result seal is not bound to its local manifest")
    robustness = TOML.parsefile(PROPOSAL_ROBUSTNESS_RESULT_SEAL_PATH)
    robustness["status"] == "SEALED_PROPOSAL_ROBUSTNESS_RESULT" ||
        error("proposal robustness result is not sealed")
    robustness["historical_evaluation_return_access_permitted"] === false ||
        error("proposal robustness result crossed the evaluation boundary")
    robustness["evaluation_values_inspected_before_seal"] == 0 ||
        error("proposal robustness reports prior evaluation inspection")
    robustness["evaluation_values_materialized_before_seal"] == 0 ||
        error("proposal robustness reports prior evaluation materialization")
    robustness["evaluation_values_used_before_seal"] == 0 ||
        error("proposal robustness reports prior evaluation use")
    robustness["public_proposal_robustness_manifest_sha256"] ==
        _sha256_file(PROPOSAL_ROBUSTNESS_MANIFEST_PATH) ||
        error("proposal robustness seal/public manifest binding changed")
    robustness["local_proposal_robustness_manifest_sha256"] ==
        _sha256_file(LOCAL_PROPOSAL_ROBUSTNESS_MANIFEST_PATH) ||
        error("proposal robustness seal/local manifest binding changed")
    for (relative, digest) in Dict{String,String}(lock["sealed_file_sha256"])
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("evaluation sealed file is absent: $relative")
        _sha256_file(path) == digest || error("evaluation sealed file changed: $relative")
    end
    proposal = TOML.parsefile(PROPOSAL_RESULT_MANIFEST_PATH)
    local_proposal = TOML.parsefile(LOCAL_PROPOSAL_RESULT_MANIFEST_PATH)
    proposal["status"] == "PROPOSAL_POLICY_INTERFACE_FROZEN" ||
        error("proposal policy choices are not frozen")
    local_proposal["status"] == "PROPOSAL_POLICY_INTERFACE_FROZEN" ||
        error("local proposal policy choices are not frozen")
    proposal["evaluation_values_inspected"] == 0 ||
        error("proposal computation inspected evaluation returns")
    proposal["evaluation_values_materialized"] == 0 ||
        error("proposal computation materialized evaluation returns")
    proposal["evaluation_values_used"] == 0 ||
        error("proposal computation used evaluation returns")
    local_proposal["public_manifest_sha256"] ==
        _sha256_file(PROPOSAL_RESULT_MANIFEST_PATH) ||
        error("proposal public/local manifests are not bound")
    proposal_robustness = TOML.parsefile(PROPOSAL_ROBUSTNESS_MANIFEST_PATH)
    local_proposal_robustness = TOML.parsefile(LOCAL_PROPOSAL_ROBUSTNESS_MANIFEST_PATH)
    for manifest in (proposal_robustness, local_proposal_robustness)
        manifest["status"] == "PROPOSAL_ROBUSTNESS_CHOICES_FROZEN" ||
            error("proposal robustness choices are not frozen")
        manifest["grid_cell_spec_denominator"] == 912 ||
            error("proposal robustness grid denominator changed")
        manifest["grid_policy_choice_denominator"] == 1824 ||
            error("proposal robustness choice denominator changed")
        manifest["evaluation_values_inspected"] == 0 ||
            error("proposal robustness inspected evaluation values")
        manifest["evaluation_values_materialized"] == 0 ||
            error("proposal robustness materialized evaluation values")
        manifest["evaluation_values_used"] == 0 ||
            error("proposal robustness used evaluation values")
    end
    local_proposal_robustness["public_manifest_sha256"] ==
        _sha256_file(PROPOSAL_ROBUSTNESS_MANIFEST_PATH) ||
        error("proposal robustness public/local manifests are not bound")
    robustness_artifact_hashes = Dict{String,String}(
        local_proposal_robustness["local_artifact_sha256"],
    )
    length(robustness_artifact_hashes) == 38 ||
        error("proposal robustness local artifact denominator changed")
    for (relative, digest) in robustness_artifact_hashes
        path = joinpath(EXPERIMENT_ROOT, relative)
        isfile(path) || error("proposal robustness artifact is absent: $relative")
        _sha256_file(path) == digest ||
            error("proposal robustness artifact changed: $relative")
    end
    return (;
        lock,
        seal,
        robustness,
        proposal,
        local_proposal,
        proposal_robustness,
        local_proposal_robustness,
        selections = TOML.parsefile(SELECTION_PATH),
        master = TOML.parsefile(MASTER_MANIFEST_PATH),
    )
end

function _registered_choices(cell)
    records = collect(cell["primary_choices"])
    Set(String(choice["policy_id"]) for choice in records) == Set(POLICY_IDS) ||
        error("proposal manifest omitted a registered policy")
    result = FrozenEvaluationChoice[]
    for choice in records
        Bool(choice["available"]) || continue
        identifiers = _choice_strategy_ids(choice)
        isempty(identifiers) &&
            error("an available registered policy has no frozen identity")
        push!(result, FrozenEvaluationChoice(
            cell["origin_id"],
            cell["universe_id"],
            choice["policy_id"],
            identifiers,
        ))
    end
    return result
end

function _choice_strategy_ids(choice)
    if haskey(choice, "strategy_ids")
        return String.(collect(choice["strategy_ids"]))
    elseif haskey(choice, "strategy_id") && !isempty(String(choice["strategy_id"]))
        return [String(choice["strategy_id"])]
    end
    return String[]
end

function _validate_choice_binding(public, local_cell)
    public_lookup = Dict(String(choice["policy_id"]) => choice for choice in public["primary_choices"])
    local_lookup = Dict(String(choice["policy_id"]) => choice for choice in local_cell["primary_choices"])
    Set(keys(public_lookup)) == Set(POLICY_IDS) ||
        error("public proposal choice policy set changed")
    Set(keys(local_lookup)) == Set(POLICY_IDS) ||
        error("local proposal choice policy set changed")
    hashes = String[]
    for policy_id in POLICY_IDS
        public_choice = public_lookup[policy_id]
        local_choice = local_lookup[policy_id]
        Bool(public_choice["available"]) == Bool(local_choice["available"]) ||
            error("public/local proposal choice availability changed")
        strategy_ids = _choice_strategy_ids(local_choice)
        expected = if !Bool(local_choice["available"]) &&
                      String(local_choice["failure_code"]) == "UNIVERSE_GATE_FAILED"
            _sha256_text(policy_id * '\0' * "UNAVAILABLE_UNIVERSE_GATE_FAILED")
        else
            _sha256_text(join([policy_id; strategy_ids], '\0'))
        end
        expected == String(public_choice["choice_sha256"]) ||
            error("public/local proposal choice identity binding changed")
        push!(hashes, expected)
    end
    aggregate = _sha256_text(join(hashes, '\n'))
    aggregate == String(public["choice_aggregate_sha256"]) ||
        error("public proposal choice aggregate changed")
    aggregate == String(local_cell["choice_aggregate_sha256"]) ||
        error("local proposal choice aggregate changed")
    return aggregate
end

function _robustness_choice_hash(context_id, choice)
    strategy_ids = _choice_strategy_ids(choice)
    identity = isempty(strategy_ids) ? String(choice["failure_code"]) :
        join(strategy_ids, '\0')
    return _sha256_text(join((
        String(context_id),
        String(choice["policy_id"]),
        identity,
    ), '\0'))
end

function _validate_robustness_binding(public, local_manifest_cell, selection)
    relative = String(local_manifest_cell["local_artifact_relative_path"])
    path = joinpath(EXPERIMENT_ROOT, relative)
    _sha256_file(path) == String(local_manifest_cell["local_artifact_sha256"]) ||
        error("proposal robustness cell artifact changed")
    artifact = TOML.parsefile(path)
    for field in ("cell_index", "origin_id", "universe_id", "universe_gate_passed")
        artifact[field] == public[field] ||
            error("proposal robustness cell identity changed: $field")
    end
    public_grid = Dict(String(row["spec_id"]) => row for row in public["grid_records"])
    local_grid = collect(artifact["grid_records"])
    length(public_grid) == length(local_grid) == 24 ||
        error("proposal robustness cell does not have 24 grid specs")
    choice_hashes = String[]
    selected_strategy_ids = Set{String}()
    for local_record in local_grid
        spec_id = String(local_record["spec_id"])
        haskey(public_grid, spec_id) || error("public robustness grid omitted $spec_id")
        public_record = public_grid[spec_id]
        for field in ("cost_bps", "risk_aversion", "adoption_hurdle")
            Float64(local_record[field]) == Float64(public_record[field]) ||
                error("robustness grid metadata changed: $spec_id/$field")
        end
        comparator = local_record["comparator_choice"]
        safe = local_record["safe_choice"]
        String(comparator["policy_id"]) == "frontier_only_robust_policy" ||
            error("robustness comparator policy changed")
        String(safe["policy_id"]) == "innovation_safe_robust_policy" ||
            error("robustness safe policy changed")
        comparator_hash = _robustness_choice_hash(spec_id, comparator)
        safe_hash = _robustness_choice_hash(spec_id, safe)
        comparator_hash == String(local_record["comparator_choice_sha256"]) ==
            String(public_record["comparator_choice_sha256"]) ||
            error("robustness comparator identity binding changed: $spec_id")
        safe_hash == String(local_record["safe_choice_sha256"]) ==
            String(public_record["safe_choice_sha256"]) ||
            error("robustness safe identity binding changed: $spec_id")
        local_same = _choice_strategy_ids(comparator) == _choice_strategy_ids(safe)
        Bool(public_record["same_choice"]) == local_same ||
            error("robustness same-choice flag changed: $spec_id")
        append!(choice_hashes, (comparator_hash, safe_hash))
        for choice in (comparator, safe), strategy_id in _choice_strategy_ids(choice)
            strategy_id == CASH_ID || push!(selected_strategy_ids, strategy_id)
        end
    end
    aggregate = _sha256_text(join(choice_hashes, '\n'))
    aggregate == String(public["grid_choice_aggregate_sha256"]) ==
        String(local_manifest_cell["grid_choice_aggregate_sha256"]) ==
        String(artifact["grid_choice_aggregate_sha256"]) ||
        error("proposal robustness grid aggregate changed")

    public_caps = Dict(Int(row["liquidity_cap"]) => row for row in public["common_equity_cap_records"])
    local_caps = Dict(Int(row["liquidity_cap"]) => row for row in artifact["common_equity_cap_records"])
    Set(keys(public_caps)) == Set((50, 100, 200)) == Set(keys(local_caps)) ||
        error("proposal robustness cap dispositions changed")
    for cap in (50, 100, 200)
        public_record = public_caps[cap]
        local_record = local_caps[cap]
        Bool(public_record["available"]) == Bool(local_record["available"]) ||
            error("proposal robustness cap availability changed")
        Bool(local_record["available"]) || continue
        context = "common_equity_cap$(cap)"
        comparator = local_record["comparator_choice"]
        safe = local_record["safe_choice"]
        comparator_hash = _robustness_choice_hash(context, comparator)
        safe_hash = _robustness_choice_hash(context, safe)
        comparator_hash == String(public_record["comparator_choice_sha256"]) ==
            String(local_record["comparator_choice_sha256"]) ||
            error("robustness cap comparator binding changed")
        safe_hash == String(public_record["safe_choice_sha256"]) ==
            String(local_record["safe_choice_sha256"]) ||
            error("robustness cap safe binding changed")
        Bool(public_record["same_choice"]) ==
            (_choice_strategy_ids(comparator) == _choice_strategy_ids(safe)) ||
            error("robustness cap same-choice flag changed")
        for choice in (comparator, safe), strategy_id in _choice_strategy_ids(choice)
            strategy_id == CASH_ID || push!(selected_strategy_ids, strategy_id)
        end
    end
    ranked = sort!(collect(selection["selected"]); by = row -> Int(row["rank"]))
    cap50_permnos = if String(selection["universe_id"]) == "liquid_common_equity"
        length(ranked) == 100 || error("common-equity top100 membership changed")
        Set(Int(row["permno"]) for row in ranked[1:50])
    else
        Set{Int}()
    end
    return (; selected_strategy_ids, cap50_permnos)
end

function _load_cells(contract)
    public_cells = Dict(Int(cell["cell_index"]) => cell for cell in contract.proposal["cells"])
    local_cells = Dict(Int(cell["cell_index"]) => cell for cell in contract.local_proposal["cells"])
    robustness_cells = Dict(
        Int(cell["cell_index"]) => cell for cell in contract.proposal_robustness["cells"]
    )
    local_robustness_cells = Dict(
        Int(cell["cell_index"]) => cell for
        cell in contract.local_proposal_robustness["cells"]
    )
    selections = collect(contract.selections["cells"])
    sort!(selections; by = row -> (String(row["origin_id"]), String(row["universe_id"])))
    length(selections) == 38 || error("evaluation cell denominator changed")
    result = EvaluationCell[]
    for (index, selection) in enumerate(selections)
        haskey(public_cells, index) && haskey(local_cells, index) &&
            haskey(robustness_cells, index) && haskey(local_robustness_cells, index) ||
            error("proposal interface omitted cell $index")
        public = public_cells[index]
        local_cell = local_cells[index]
        robustness_cell = robustness_cells[index]
        local_robustness_cell = local_robustness_cells[index]
        public["origin_id"] == selection["origin_id"] || error("evaluation origin changed")
        public["universe_id"] == selection["universe_id"] || error("evaluation universe changed")
        local_cell["origin_id"] == public["origin_id"] ||
            error("public/local proposal origin changed")
        local_cell["universe_id"] == public["universe_id"] ||
            error("public/local proposal universe changed")
        _validate_choice_binding(public, local_cell)
        robustness_binding = _validate_robustness_binding(
            robustness_cell,
            local_robustness_cell,
            selection,
        )
        robustness_cell["origin_id"] == public["origin_id"] ||
            error("proposal robustness origin changed")
        robustness_cell["universe_id"] == public["universe_id"] ||
            error("proposal robustness universe changed")
        choices = _registered_choices(local_cell)
        gate = Bool(public["universe_gate_passed"])
        choice_policies = Set(getfield.(choices, :policy_id))
        if gate && !issubset(
            Set(("innovation_safe_robust_policy", "frontier_only_robust_policy")),
            choice_policies,
        )
            error("gate-passed proposal cell did not freeze both primary choices")
        end
        !gate && !isempty(choices) &&
            error("failed-universe proposal cell exposes an available primary choice")
        permnos = Set(Int(row["permno"]) for row in selection["selected"])
        access_ids = gate ? permnos : Set{Int}()
        !gate && !isempty(access_ids) && error("failed universe has evaluation access")
        relative = gate ?
            String(local_cell["proposal_combined_relative_path"]) : ""
        digest = gate ?
            String(local_cell["proposal_combined_sha256"]) : ""
        push!(result, EvaluationCell(
            index,
            String(public["origin_id"]),
            String(public["universe_id"]),
            String(public["role"]),
            String(public["universe_status"]),
            gate,
            Int(public["evaluation_year"]),
            Set(access_ids),
            robustness_binding.cap50_permnos,
            length(robustness_binding.selected_strategy_ids),
            choices,
            relative,
            digest,
        ))
    end
    count(cell -> !cell.gate_passed, result) == 1 ||
        error("evaluation failed-universe denominator changed")
    return result
end

function _cells_by_permno(cells)
    result = Dict{Int,Vector{Int}}()
    for cell in cells
        cell.gate_passed && !isempty(cell.selected_permnos) || continue
        for permno in cell.selected_permnos
            push!(get!(result, permno, Int[]), cell.cell_index)
        end
    end
    return result
end

function _target_rows_and_calendar(file, cells, cells_by_permno, evaluation_years)
    targeted = TargetRow[]
    capacity_targeted = TargetRow[]
    calendars = Dict(year => Set{String}() for year in evaluation_years)
    permno_cursor = Parquet.ColCursor(file, ["permno"])
    date_cursor = Parquet.ColCursor(file, ["date"])
    row_index = 0
    for (permno_record, date_record) in zip(permno_cursor, date_cursor)
        row_index += 1
        isnothing(date_record.value) && error("source date is missing")
        date = String(date_record.value)
        year = parse(Int, date[1:4])
        year in evaluation_years && push!(calendars[year], date)
        isnothing(permno_record.value) && continue
        permno = Int(permno_record.value)
        memberships = Int[]
        capacity_memberships = Int[]
        for cell_index in get(cells_by_permno, permno, Int[])
            cell = cells[cell_index]
            year == cell.evaluation_year && push!(memberships, cell_index)
            year in ((cell.evaluation_year - 1):cell.evaluation_year) &&
                push!(capacity_memberships, cell_index)
        end
        isempty(memberships) || push!(targeted, TargetRow(row_index, permno, date, memberships))
        isempty(capacity_memberships) || push!(
            capacity_targeted,
            TargetRow(row_index, permno, date, capacity_memberships),
        )
    end
    row_index == Parquet.nrows(file) ||
        error("evaluation identifier/date cursors lost alignment")
    return targeted, capacity_targeted, calendars
end

function _extract_chunk(path, expected_sha, expected_rows, cells, cells_by_permno, years)
    _sha256_file(path) == expected_sha || error("evaluation source chunk hash changed")
    file = Parquet.File(path)
    try
        Parquet.nrows(file) == expected_rows || error("evaluation source chunk rows changed")
        targeted, capacity_targeted, calendars = _target_rows_and_calendar(
            file,
            cells,
            cells_by_permno,
            years,
        )
        target_rows = getfield.(targeted, :row_index)
        values = MaskedReader._materialize_masked_column(file, ["total_return"], target_rows)
        flags = MaskedReader._materialize_masked_column(file, ["return_flag"], target_rows)
        delisting =
            MaskedReader._materialize_masked_column(file, ["delisting_flag"], target_rows)
        capacity_rows = getfield.(capacity_targeted, :row_index)
        closes = MaskedReader._materialize_masked_column(file, ["close"], capacity_rows)
        volumes = MaskedReader._materialize_masked_column(file, ["volume"], capacity_rows)
        buffers = [SparseEvaluationBuffer() for _ in cells]
        for (source, value_record, flag_record, delisting_record) in
            zip(targeted, values, flags, delisting)
            isnothing(flag_record) && error("selected evaluation return flag is missing")
            isnothing(delisting_record) && error("selected evaluation delisting flag is missing")
            flag = String(flag_record)
            delisting_flag = String(delisting_record)
            available = flag == "NA"
            value = if available
                isnothing(value_record) && error("ordinary evaluation return is missing")
                converted = Float64(value_record)
                isfinite(converted) && converted >= -1 ||
                    error("ordinary evaluation return is invalid")
                converted
            else
                missing
            end
            terminal = !(delisting_flag in ("", "N"))
            for cell_index in source.cell_indices
                cell = cells[cell_index]
                cell.gate_passed || error("failed-cell evaluation value was materialized")
                isempty(cell.selected_permnos) &&
                    error("cash-only cell evaluation value was materialized")
                parse(Int, source.date[1:4]) == cell.evaluation_year ||
                    error("nonevaluation value was materialized")
                buffer = buffers[cell_index]
                push!(buffer.permno, source.permno)
                push!(buffer.date, source.date)
                push!(buffer.total_return, value)
                push!(buffer.return_available, available)
                push!(buffer.terminal_delisting, terminal)
                push!(buffer.return_flag, flag)
                push!(buffer.delisting_flag, delisting_flag)
            end
        end
        for (source, close_record, volume_record) in zip(capacity_targeted, closes, volumes)
            close_value = if isnothing(close_record)
                missing
            else
                converted = Float64(close_record)
                isfinite(converted) && converted > 0 ? converted : missing
            end
            volume_value = if isnothing(volume_record)
                missing
            else
                converted = Float64(volume_record)
                isfinite(converted) && converted >= 0 ? converted : missing
            end
            for cell_index in source.cell_indices
                cell = cells[cell_index]
                cell.gate_passed || error("failed-cell capacity value was materialized")
                year = parse(Int, source.date[1:4])
                year in ((cell.evaluation_year - 1):cell.evaluation_year) ||
                    error("out-of-scope capacity value was materialized")
                buffer = buffers[cell_index]
                push!(buffer.capacity_permno, source.permno)
                push!(buffer.capacity_date, source.date)
                push!(buffer.close, close_value)
                push!(buffer.volume, volume_value)
            end
        end
        return EvaluationChunk(
            buffers,
            calendars,
            expected_rows,
            length(targeted),
            length(capacity_targeted),
            expected_sha,
        )
    finally
        close(file)
    end
end

function _append!(target::SparseEvaluationBuffer, source::SparseEvaluationBuffer)
    for field in fieldnames(SparseEvaluationBuffer)
        append!(getfield(target, field), getfield(source, field))
    end
    return target
end

function _extract_all(contract, cells)
    chunks = collect(contract.master["chunks"])
    by_permno = _cells_by_permno(cells)
    years = Set(cell.evaluation_year for cell in cells)
    buffers = [SparseEvaluationBuffer() for _ in cells]
    calendars = Dict(year => Set{String}() for year in years)
    materialized = 0
    capacity_materialized = 0
    source_rows = 0
    worker_count = max(1, Threads.nthreads())
    for first_index in 1:worker_count:length(chunks)
        batch = first_index:min(first_index + worker_count - 1, length(chunks))
        results = Vector{EvaluationChunk}(undef, length(batch))
        Threads.@threads :static for local_index in eachindex(batch)
            chunk = chunks[batch[local_index]]
            results[local_index] = _extract_chunk(
                joinpath(MASTER_ROOT, String(chunk["path"])),
                String(chunk["sha256"]),
                Int(chunk["row_count"]),
                cells,
                by_permno,
                years,
            )
        end
        for extraction in results
            source_rows += extraction.source_rows
            materialized += extraction.materialized_rows
            capacity_materialized += extraction.capacity_materialized_rows
            for index in eachindex(cells)
                _append!(buffers[index], extraction.buffers[index])
            end
            for (year, dates) in extraction.reference_dates
                union!(calendars[year], dates)
            end
        end
        println(stderr, "v3 evaluation extraction completed chunks $(first(batch))-$(last(batch))/$(length(chunks))")
    end
    return (; buffers, calendars, materialized, capacity_materialized, source_rows)
end

function _combined_table(cell, sparse, calendar)
    prior_path = joinpath(EXPERIMENT_ROOT, cell.proposal_relative_path)
    isfile(prior_path) || error("proposal history artifact is absent")
    _sha256_file(prior_path) == cell.proposal_sha256 ||
        error("proposal history artifact changed")
    prior = Tables.columntable(Parquet.Table(prior_path; use_threads = false))
    return _combine_columns(cell, sparse, calendar, prior)
end

function _combine_columns(cell, sparse, calendar, prior)
    prior_permno = Int64.(collect(skipmissing(prior.permno)))
    prior_dates = String.(collect(skipmissing(prior.date)))
    prior_returns = Union{Missing,Float64}[prior.total_return...]
    prior_available = Bool.(collect(skipmissing(prior.return_available)))
    prior_terminal = Bool.(collect(skipmissing(prior.terminal_delisting)))
    prior_flags = String.(collect(skipmissing(prior.return_flag)))
    prior_delisting = String.(collect(skipmissing(prior.delisting_flag)))
    length(prior_permno) == length(prior_dates) == length(prior_returns) ||
        error("proposal history columns do not align")
    evaluation_lookup = Dict{Tuple{Int64,String},Int}()
    for index in eachindex(sparse.permno)
        key = (sparse.permno[index], sparse.date[index])
        haskey(evaluation_lookup, key) && error("duplicate sparse evaluation row")
        evaluation_lookup[key] = index
    end
    capacity_lookup = Dict{Tuple{Int64,String},Int}()
    for index in eachindex(sparse.capacity_permno)
        key = (sparse.capacity_permno[index], sparse.capacity_date[index])
        haskey(capacity_lookup, key) && error("duplicate sparse capacity row")
        capacity_lookup[key] = index
    end
    expected_permnos = sort!(Int64.(collect(cell.selected_permnos)))
    sort!(unique(prior_permno)) == expected_permnos ||
        error("proposal history security identifiers changed")
    prior_sessions = length(prior_permno) ÷ length(expected_permnos)
    prior_sessions * length(expected_permnos) == length(prior_permno) ||
        error("proposal history is not rectangular")
    output_permno = Int64[]
    output_dates = String[]
    output_returns = Union{Missing,Float64}[]
    output_available = Bool[]
    output_terminal = Bool[]
    output_flags = String[]
    output_delisting = String[]
    output_close = Union{Missing,Float64}[]
    output_volume = Union{Missing,Float64}[]
    canonical_prior_calendar = String[]
    for (security_index, permno) in enumerate(expected_permnos)
        rows = ((security_index - 1) * prior_sessions + 1):(security_index * prior_sessions)
        all(==(permno), @view prior_permno[rows]) ||
            error("proposal history security rows are not contiguous")
        security_calendar = prior_dates[rows]
        if security_index == 1
            canonical_prior_calendar = copy(security_calendar)
            issorted(canonical_prior_calendar) && allunique(canonical_prior_calendar) ||
                error("proposal history calendar is not canonical")
            last(canonical_prior_calendar) < first(calendar) ||
                error("evaluation calendar overlaps proposal history")
        else
            security_calendar == canonical_prior_calendar ||
                error("proposal history security calendars differ")
        end
        append!(output_permno, @view prior_permno[rows])
        append!(output_dates, @view prior_dates[rows])
        append!(output_returns, @view prior_returns[rows])
        append!(output_available, @view prior_available[rows])
        append!(output_terminal, @view prior_terminal[rows])
        append!(output_flags, @view prior_flags[rows])
        append!(output_delisting, @view prior_delisting[rows])
        for date in security_calendar
            key = (permno, date)
            if haskey(capacity_lookup, key)
                capacity_index = capacity_lookup[key]
                push!(output_close, sparse.close[capacity_index])
                push!(output_volume, sparse.volume[capacity_index])
            else
                push!(output_close, missing)
                push!(output_volume, missing)
            end
        end
        terminal_seen = any(@view prior_terminal[rows])
        for date in calendar
            key = (permno, date)
            push!(output_permno, permno)
            push!(output_dates, date)
            if haskey(evaluation_lookup, key)
                index = evaluation_lookup[key]
                terminal_seen && error("observed evaluation row follows terminal delisting")
                push!(output_returns, sparse.total_return[index])
                push!(output_available, sparse.return_available[index])
                push!(output_terminal, sparse.terminal_delisting[index])
                push!(output_flags, sparse.return_flag[index])
                push!(output_delisting, sparse.delisting_flag[index])
                sparse.terminal_delisting[index] && (terminal_seen = true)
            else
                push!(output_returns, missing)
                push!(output_available, false)
                push!(output_terminal, false)
                push!(output_flags, terminal_seen ? "POST_TERMINAL_CASH" : "ABSENT")
                push!(output_delisting, "N")
            end
            if haskey(capacity_lookup, key)
                capacity_index = capacity_lookup[key]
                push!(output_close, sparse.close[capacity_index])
                push!(output_volume, sparse.volume[capacity_index])
            else
                push!(output_close, missing)
                push!(output_volume, missing)
            end
        end
    end
    return (;
        permno = output_permno,
        date = output_dates,
        total_return = output_returns,
        return_available = output_available,
        terminal_delisting = output_terminal,
        return_flag = output_flags,
        delisting_flag = output_delisting,
        close = output_close,
        volume = output_volume,
    )
end

"Synthetic proof that only active frozen-cell evaluation rows are materialized."
function evaluation_leakage_sentinel()
    return mktempdir() do directory
        path = joinpath(directory, "evaluation-sentinel.parquet")
        table = (;
            permno = Int64[10, 10, 10, 10, 20, 20, 20, 20],
            date = [
                "2000-01-03", "2001-01-03", "2002-01-03", "2003-01-03",
                "2000-01-03", "2001-01-03", "2002-01-03", "2003-01-03",
            ],
            total_return = [NaN, Inf, -1.0, -Inf, NaN, Inf, 999.0, -Inf],
            close = [10.0, 11.0, 12.0, 13.0, 20.0, 21.0, 22.0, 23.0],
            volume = [100.0, 110.0, 120.0, 130.0, 200.0, 210.0, 220.0, 230.0],
            return_flag = ["X", "FORBIDDEN", "NA", "FORBIDDEN", "X", "X", "NA", "X"],
            delisting_flag = ["X", "FORBIDDEN", "D", "FORBIDDEN", "X", "X", "N", "X"],
        )
        Parquet.write_parquet(path, table)
        active_choices = [
            FrozenEvaluationChoice("O", "u", "innovation_safe_robust_policy", "active"),
            FrozenEvaluationChoice("O", "u", "frontier_only_robust_policy", CASH_ID),
        ]
        cash_choices = [
            FrozenEvaluationChoice("O", "cash", "innovation_safe_robust_policy", CASH_ID),
            FrozenEvaluationChoice("O", "cash", "frontier_only_robust_policy", CASH_ID),
        ]
        failed_choices = [
            FrozenEvaluationChoice("O", "failed", "innovation_safe_robust_policy", CASH_ID),
            FrozenEvaluationChoice("O", "failed", "frontier_only_robust_policy", CASH_ID),
        ]
        cells = [
            EvaluationCell(1, "O", "u", "primary", "PASSED", true, 2002,
                Set([10]), Set([10]), 1, active_choices, "", ""),
            EvaluationCell(2, "O", "cash", "replication", "PASSED", true, 2002,
                Set([20]), Set{Int}(), 0, cash_choices, "", ""),
            EvaluationCell(3, "O", "failed", "replication", "FAILED", false, 2002,
                Set([20]), Set{Int}(), 0, failed_choices, "", ""),
        ]
        extraction = _extract_chunk(
            path,
            _sha256_file(path),
            8,
            cells,
            _cells_by_permno(cells),
            Set([2002]),
        )
        only(extraction.buffers[1].total_return) == -1.0 ||
            error("evaluation sentinel selected value changed")
        only(extraction.buffers[1].terminal_delisting) ||
            error("evaluation sentinel delisting was not preserved")
        only(extraction.buffers[2].total_return) == 999.0 ||
            error("cash-only full-search row was not materialized")
        isempty(extraction.buffers[3].total_return) ||
            error("failed-universe cell value was materialized")

        alternate_path = joinpath(directory, "evaluation-sentinel-alternate.parquet")
        Parquet.write_parquet(alternate_path, merge(table, (;
            total_return = [1e90, -1e90, -1.0, NaN, Inf, -Inf, 999.0, NaN],
            close = [-1.0, 11.0, 12.0, NaN, Inf, 21.0, 22.0, -Inf],
            volume = [-1.0, 110.0, 120.0, NaN, Inf, 210.0, 220.0, -Inf],
            return_flag = ["BAD", "BAD", "NA", "BAD", "BAD", "BAD", "NA", "BAD"],
            delisting_flag = ["BAD", "BAD", "D", "BAD", "BAD", "BAD", "N", "BAD"],
        )))
        alternate = _extract_chunk(
            alternate_path,
            _sha256_file(alternate_path),
            8,
            cells,
            _cells_by_permno(cells),
            Set([2002]),
        )
        extraction.buffers[1].total_return == alternate.buffers[1].total_return ||
            error("unmasked source values changed evaluation output")
        extraction.buffers[1].return_flag == alternate.buffers[1].return_flag ||
            error("unmasked source flags changed evaluation output")
        extraction.buffers[2].total_return == alternate.buffers[2].total_return ||
            error("unmasked source values changed cash-cell full-search output")
        extraction.buffers[1].close == alternate.buffers[1].close ||
            error("unmasked source values changed capacity output")
        return Dict{String,Any}(
            "status" => "SYNTHETIC_EVALUATION_MASK_PASSED",
            "active_evaluation_rows_materialized" => 1,
            "cash_only_full_search_rows_materialized" => 1,
            "failed_cell_rows_materialized" => 0,
            "preevaluation_and_postevaluation_rows_inspected_materialized_or_used" => 0,
            "masked_outputs_identical_across_unmasked_variants" => true,
            "observed_delisting_preserved" => true,
            "capacity_rows_materialized" => 4,
            "lagged_capacity_fields_present" => true,
            "historical_values_accessed" => false,
        )
    end
end

function stage_evaluation_returns(; check = false)
    contract = _load_contract()
    cells = _load_cells(contract)
    extraction = _extract_all(contract, cells)
    extraction.source_rows == Int(contract.master["retained_master_rows"]) ||
        error("evaluation identifier/date scan omitted source rows")
    public_cells = Dict{String,Any}[]
    local_cells = Dict{String,Any}[]
    hashes = Dict{String,String}()
    for cell in cells
        calendar = sort!(collect(extraction.calendars[cell.evaluation_year]))
        isempty(calendar) && error("evaluation reference calendar is empty")
        active = cell.gate_passed
        public = Dict{String,Any}(
            "cell_index" => cell.cell_index,
            "origin_id" => cell.origin_id,
            "universe_id" => cell.universe_id,
            "role" => cell.role,
            "universe_status" => cell.universe_status,
            "universe_gate_passed" => cell.gate_passed,
            "evaluation_year" => cell.evaluation_year,
            "available_registered_policy_count" => length(cell.choices),
            "active_registered_policy_count" => count(
                choice -> any(!=(CASH_ID), choice.strategy_ids),
                cell.choices,
            ),
            "frozen_robustness_grid_spec_count" => 24,
            "frozen_robustness_policy_choice_count" => 48,
            "frozen_robustness_selected_strategy_count" =>
                cell.robustness_selected_strategy_count,
            "frozen_cap50_membership_count" => length(cell.cap50_permnos),
            "reference_calendar_sessions" => length(calendar),
            "reference_calendar_first_date" => first(calendar),
            "reference_calendar_last_date" => last(calendar),
            "reference_calendar_sha256" => _sha256_text(join(calendar, '\n')),
            "evaluation_security_return_access_permitted" => active,
            "evaluation_values_materialized" => active ?
                length(extraction.buffers[cell.cell_index].total_return) : 0,
            "capacity_price_volume_values_materialized" => active ?
                length(extraction.buffers[cell.cell_index].close) : 0,
            "return_values_included" => false,
            "licensed_identifiers_included" => false,
        )
        if active
            table = _combined_table(cell, extraction.buffers[cell.cell_index], calendar)
            relative = joinpath(
                "local_data",
                "evaluation",
                "cell-$(lpad(cell.cell_index, 3, '0')).parquet",
            )
            digest, bytes = _install_parquet(joinpath(EXPERIMENT_ROOT, relative), table; check)
            hashes[relative] = digest
            public["local_artifact_relative_path"] = relative
            public["local_artifact_sha256"] = digest
            public["local_artifact_bytes"] = bytes
            public["combined_row_count"] = length(table.permno)
        else
            public["failure_code"] = "UNIVERSE_GATE_FAILED"
            public["local_artifact_relative_path"] = ""
            public["local_artifact_sha256"] = ""
            public["local_artifact_bytes"] = 0
            public["combined_row_count"] = 0
        end
        local_cell = copy(public)
        local_cell["return_values_included"] = active
        local_cell["licensed_identifiers_included"] = active
        push!(public_cells, public)
        push!(local_cells, local_cell)
    end
    common = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-evaluation-stage-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "EVALUATION_RETURNS_STAGED_FOR_FROZEN_CHOICES",
        "language" => "Julia",
        "cell_count" => length(cells),
        "accessed_cell_count" => count(cell -> cell.gate_passed, cells),
        "failed_universe_cells_retained_without_access" => count(cell -> !cell.gate_passed, cells),
        "frozen_robustness_grid_cell_spec_denominator" => 912,
        "frozen_robustness_grid_policy_choice_denominator" => 1824,
        "common_equity_cap50_membership_validated_cells" =>
            count(cell -> length(cell.cap50_permnos) == 50, cells),
        "cash_only_cells_with_full_search_access" => count(
            cell -> cell.gate_passed &&
                    all(choice -> choice.strategy_ids == [CASH_ID], cell.choices),
            cells,
        ),
        "identifier_date_rows_scanned" => extraction.source_rows,
        "unique_evaluation_source_rows_materialized" => extraction.materialized,
        "unique_proposal_plus_evaluation_capacity_rows_materialized" =>
            extraction.capacity_materialized,
        "identifier_date_mask_frozen_before_return_cursor" => true,
        "masked_column_mechanics" => "Predecision Access Amendment 002",
        "capacity_source_fields" => ["close", "volume"],
        "capacity_source_window" => "proposal year plus evaluation year",
        "evaluation_scope" => "all five frozen registered policies; primary headline fixed",
        "evaluation_execution_lock_sha256" => _sha256_file(EXECUTION_LOCK_PATH),
        "proposal_policy_result_seal_sha256" => _sha256_file(PROPOSAL_RESULT_SEAL_PATH),
        "proposal_robustness_result_seal_sha256" =>
            _sha256_file(PROPOSAL_ROBUSTNESS_RESULT_SEAL_PATH),
        "local_artifact_count" => length(hashes),
    )
    public_payload = copy(common)
    public_payload["return_values_included"] = false
    public_payload["licensed_identifiers_included"] = false
    public_payload["public_promotion_permitted"] = true
    public_payload["cells"] = public_cells
    public_text = _toml_text(public_payload)
    local_payload = copy(common)
    local_payload["return_values_included"] = true
    local_payload["licensed_identifiers_included"] = true
    local_payload["public_promotion_permitted"] = false
    local_payload["public_manifest_sha256"] = _sha256_text(public_text)
    local_payload["local_artifact_sha256"] = hashes
    local_payload["cells"] = local_cells
    local_text = _toml_text(local_payload)
    if check
        read(PUBLIC_STAGE_MANIFEST_PATH, String) == public_text ||
            error("public evaluation stage changed")
        read(LOCAL_STAGE_MANIFEST_PATH, String) == local_text ||
            error("local evaluation stage changed")
    else
        _write_new_or_identical(PUBLIC_STAGE_MANIFEST_PATH, public_text)
        _write_new_or_identical(LOCAL_STAGE_MANIFEST_PATH, local_text)
    end
    accessed_cell_count = common["accessed_cell_count"]
    println("V3_EVALUATION_STAGE_PASSED")
    println("security-return-accessed cells: $accessed_cell_count/$(length(cells))")
    println("scored choice scope: all available frozen registered policies")
    return public_payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    stage_evaluation_returns(; check = "--check" in args)
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    StageFinancialStrategyLibraryPanelV3EvaluationReturns.main()
end
