module RunFinancialStrategyLibraryPanelV3PredecisionComputation

using Parquet
using SHA: sha256
using StrategyInnovation: check_journal_compression_solution,
                          encode_exact_rational,
                          journal_compression_instance_sha256,
                          serialize_journal_mip_solution
using Tables
using TOML

include(joinpath(
    @__DIR__,
    "..",
    "src",
    "FinancialStrategyLibraryPanelV3PredecisionComputation.jl",
))
using .FinancialStrategyLibraryPanelV3PredecisionComputation

export audit_predecision_computation, main, run_predecision_computation

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_strategy_library_panel_v3.toml",
)
const COMPUTATION_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_COMPUTATION_LOCK_002.toml")
const BASE_COMPUTATION_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_COMPUTATION_LOCK.toml")
const PUBLIC_STAGE_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "predecision_stage",
    "PREDECISION_STAGE_MANIFEST.toml",
)
const LOCAL_STAGE_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "predecision",
    "PREDECISION_STAGE_LOCAL_MANIFEST.toml",
)
const LOCAL_RESULT_ROOT = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "predecision_computation",
)
const LOCAL_RESULT_MANIFEST_PATH = joinpath(
    LOCAL_RESULT_ROOT,
    "PREDECISION_COMPUTATION_LOCAL_MANIFEST.toml",
)
const PUBLIC_RESULT_ROOT = joinpath(EXPERIMENT_ROOT, "predecision_computation")
const PUBLIC_RESULT_MANIFEST_PATH = joinpath(
    PUBLIC_RESULT_ROOT,
    "PREDECISION_COMPUTATION_MANIFEST.toml",
)

struct CellPanel
    dates::Vector{String}
    permnos::Vector{Int64}
    returns::Matrix{Float64}
    available::BitMatrix
    terminal_delisting::BitMatrix
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

function _directory_aggregate(hashes)
    canonical = join(
        ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
    )
    return _sha256_text(canonical)
end

function _write_new_or_identical(path, content)
    if isfile(path)
        read(path, String) == content || error(
            "refusing to replace a nonidentical v3 computation artifact: " *
            relpath(path, REPOSITORY_ROOT),
        )
        return path
    end
    mkpath(dirname(path))
    temporary = path * ".tmp.$(getpid()).$(Threads.threadid())"
    open(temporary, "w") do io
        write(io, content)
    end
    mv(temporary, path)
    return path
end

function _install_parquet(path, table)
    mktempdir() do directory
        candidate = joinpath(directory, basename(path))
        Parquet.write_parquet(candidate, table)
        digest = _sha256_file(candidate)
        bytes = filesize(candidate)
        if isfile(path)
            _sha256_file(path) == digest || error(
                "refusing to replace nonidentical v3 computation parquet: " *
                relpath(path, REPOSITORY_ROOT),
            )
        else
            mkpath(dirname(path))
            mv(candidate, path)
        end
        return digest, bytes
    end
end

function _verify_sealed_lock(path)
    isfile(path) || error("required v3 lock is absent: $(relpath(path, REPOSITORY_ROOT))")
    lock = TOML.parsefile(path)
    hashes = Dict{String,String}(lock["sealed_file_sha256"])
    for relative in sort!(collect(keys(hashes)))
        source = joinpath(REPOSITORY_ROOT, relative)
        isfile(source) || error("sealed prerequisite is absent: $relative")
        _sha256_file(source) == hashes[relative] || error("sealed prerequisite changed: $relative")
    end
    return lock
end

function _load_contract()
    isfile(COMPUTATION_LOCK_PATH) || error("v3 predecision computation is not locked")
    lock = TOML.parsefile(COMPUTATION_LOCK_PATH)
    lock["status"] == "LOCKED_PREDECISION_COMPUTATION_002" ||
        error("unexpected v3 predecision computation-lock status")
    lock["historical_predecision_return_computation_permitted"] === true ||
        error("predecision computation is not permitted")
    lock["historical_proposal_or_evaluation_return_access_permitted"] === false ||
        error("predecision computation lock permits forbidden postdecision access")
    lock["previous_computation_lock_sha256"] == _sha256_file(BASE_COMPUTATION_LOCK_PATH) ||
        error("computation lock 002 is not bound to the initial computation lock")
    sealed = Dict{String,String}(lock["sealed_file_sha256"])
    for relative in sort!(collect(keys(sealed)))
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("computation-sealed file is absent: $relative")
        _sha256_file(path) == sealed[relative] || error("computation-sealed file changed: $relative")
    end
    _directory_aggregate(sealed) == String(lock["computation_code_aggregate_sha256"]) ||
        error("computation code aggregate changed")
    _sha256_file(PUBLIC_STAGE_MANIFEST_PATH) == lock["public_stage_manifest_sha256"] ||
        error("public predecision stage manifest changed")
    _sha256_file(LOCAL_STAGE_MANIFEST_PATH) == lock["local_stage_manifest_sha256"] ||
        error("local predecision stage manifest changed")
    public_stage = TOML.parsefile(PUBLIC_STAGE_MANIFEST_PATH)
    local_stage = TOML.parsefile(LOCAL_STAGE_MANIFEST_PATH)
    for field in (
        "proposal_or_evaluation_values_inspected",
        "proposal_or_evaluation_values_materialized",
        "proposal_or_evaluation_values_used",
    )
        public_stage[field] == 0 || error("predecision stage crossed postdecision boundary")
        local_stage[field] == 0 || error("local predecision stage crossed postdecision boundary")
    end
    public_stage["return_values_included"] === false ||
        error("public stage manifest contains returns")
    local_stage["return_values_included"] === true ||
        error("local stage manifest does not bind staged returns")
    local_stage["public_manifest_sha256"] == _sha256_text(read(PUBLIC_STAGE_MANIFEST_PATH, String)) ||
        error("local and public stage manifests are not bound")
    config = TOML.parsefile(CONFIG_PATH)
    config["language"] == "Julia" || error("v3 main language is not Julia")
    config["v3_outcomes_opened"] === false || error("v3 postdecision outcomes were opened")
    return (; lock, public_stage, local_stage, config)
end

function _cell_by_index(manifest)
    return Dict(Int(cell["cell_index"]) => cell for cell in manifest["cells"])
end

function _parquet_columns(path)
    return Tables.columntable(Parquet.Table(path; use_threads = false))
end

function _load_cell_panel(cell)
    relative = String(cell["local_artifact_relative_path"])
    path = joinpath(EXPERIMENT_ROOT, relative)
    isfile(path) || error("staged cell parquet is absent: $relative")
    _sha256_file(path) == String(cell["local_artifact_sha256"]) ||
        error("staged cell parquet changed: $relative")
    columns = _parquet_columns(path)
    count = length(columns.permno)
    count == Int(cell["staged_row_count"]) || error("staged cell row count changed")
    permnos = sort!(unique(Int64.(columns.permno)))
    length(permnos) == Int(cell["selected_security_count"]) ||
        error("staged cell security count changed")
    sessions = Int(cell["expected_sessions_per_security"])
    count == length(permnos) * sessions || error("staged cell is not rectangular")
    dates = String.(columns.date[1:sessions])
    issorted(dates) && allunique(dates) || error("staged cell calendar is not canonical")
    returns = Matrix{Float64}(undef, sessions, length(permnos))
    available = falses(sessions, length(permnos))
    terminal = falses(sessions, length(permnos))
    for (security, permno) in enumerate(permnos)
        first_row = (security - 1) * sessions + 1
        last_row = security * sessions
        all(==(permno), @view columns.permno[first_row:last_row]) ||
            error("staged cell security rows are not contiguous")
        String.(columns.date[first_row:last_row]) == dates ||
            error("staged cell security calendars differ")
        returns[:, security] .= Float64.(columns.total_return[first_row:last_row])
        available[:, security] .= Bool.(columns.return_available[first_row:last_row])
        terminal[:, security] .= Bool.(columns.terminal_delisting[first_row:last_row])
    end
    all(available) || error("complete-universe predecision stage contains unavailable returns")
    maximum(dates) <= String(cell["decision_date"]) ||
        error("staged cell crosses its compression decision")
    return CellPanel(dates, permnos, returns, available, terminal)
end

function _path_table(paths, dates)
    row_count = length(paths) * length(dates)
    strategy_ids = Vector{String}(undef, row_count)
    output_dates = Vector{String}(undef, row_count)
    gross_returns = Vector{Union{Missing,Float64}}(undef, row_count)
    turnover = Vector{Float64}(undef, row_count)
    available = Vector{Bool}(undef, row_count)
    cursor = 1
    for path in paths, session in eachindex(dates)
        strategy_ids[cursor] = path.strategy_id
        output_dates[cursor] = dates[session]
        gross_returns[cursor] = path.gross_returns[session]
        turnover[cursor] = path.turnover[session]
        available[cursor] = path.available[session]
        cursor += 1
    end
    return (;
        strategy_id = strategy_ids,
        date = output_dates,
        gross_return = gross_returns,
        turnover,
        available,
    )
end

function _profile_table(paths, formation, compression)
    row_count = length(paths) * (length(formation.profile_ids) + length(compression.profile_ids))
    strategy_ids = Vector{String}(undef, row_count)
    windows = Vector{String}(undef, row_count)
    profile_ids = Vector{String}(undef, row_count)
    ce = Vector{Float64}(undef, row_count)
    exact_ce = Vector{String}(undef, row_count)
    cursor = 1
    for (window, bundle) in (("formation", formation), ("compression", compression))
        for (row, path) in enumerate(paths), column in eachindex(bundle.profile_ids)
            strategy_ids[cursor] = path.strategy_id
            windows[cursor] = window
            profile_ids[cursor] = bundle.profile_ids[column]
            ce[cursor] = bundle.floating_values[row, column]
            exact_ce[cursor] = encode_exact_rational(bundle.exact_values[row, column])
            cursor += 1
        end
    end
    return (;
        strategy_id = strategy_ids,
        window = windows,
        profile_id = profile_ids,
        certainty_equivalent = ce,
        exact_certainty_equivalent = exact_ce,
    )
end

_selected_ids(instance, selected) = sort!(String[
    String(instance.strategy_ids[index].id) for index in findall(selected)
])

function _cell_computation(cell)
    index = Int(cell["cell_index"])
    origin_id = String(cell["origin_id"])
    universe_id = String(cell["universe_id"])
    panel = _load_cell_panel(cell)
    cap = universe_id == "liquid_common_equity" ? 0.05 :
          universe_id == "liquid_plain_etf" ? 0.10 :
          error("unsupported v3 universe")
    paths = build_strategy_paths(
        origin_id,
        universe_id,
        panel.returns,
        panel.available,
        panel.terminal_delisting;
        security_weight_cap = cap,
    )
    formation_start = Int(cell["formation_start_year"])
    decision_year = Int(cell["compression_decision_year"])
    formation = profile_bundle(paths, panel.dates, formation_start:(formation_start + 2))
    docket = freeze_source_docket(paths, formation, universe_id)
    compression = profile_bundle(paths, panel.dates, (decision_year - 2):decision_year)
    arms = compression_arms(origin_id, universe_id, paths, docket, compression)
    ledger = preproposal_trial_rows(
        origin_id,
        universe_id,
        paths,
        docket,
        arms;
        universe_status = String(cell["status"]),
    )

    prefix = "cell-$(lpad(index, 3, '0'))"
    path_relative = joinpath("local_data", "predecision_computation", "$prefix-paths.parquet")
    profile_relative = joinpath("local_data", "predecision_computation", "$prefix-profiles.parquet")
    safe_relative = joinpath("local_data", "predecision_computation", "$prefix-safe-mip.toml")
    frontier_relative = joinpath("local_data", "predecision_computation", "$prefix-frontier-mip.toml")
    arms_relative = joinpath("local_data", "predecision_computation", "$prefix-arms.toml")
    ledger_relative = joinpath("local_data", "predecision_computation", "$prefix-trial-ledger.csv")

    path_hash, path_bytes = _install_parquet(
        joinpath(EXPERIMENT_ROOT, path_relative),
        _path_table(paths, panel.dates),
    )
    profile_hash, profile_bytes = _install_parquet(
        joinpath(EXPERIMENT_ROOT, profile_relative),
        _profile_table(paths, formation, compression),
    )
    safe_text = serialize_journal_mip_solution(arms.safe_result)
    frontier_text = serialize_journal_mip_solution(arms.frontier_result)
    _write_new_or_identical(joinpath(EXPERIMENT_ROOT, safe_relative), safe_text)
    _write_new_or_identical(joinpath(EXPERIMENT_ROOT, frontier_relative), frontier_text)

    safe_selected = BitVector(arms.safe_result.reconstructed_candidate)
    frontier_selected = BitVector(arms.frontier_result.reconstructed_candidate)
    safe_check = check_journal_compression_solution(arms.instance, safe_selected)
    comparator_check = check_journal_compression_solution(
        arms.frontier_instance,
        arms.comparator_selected,
    )
    source_burden = sum(arms.instance.weights; init = zero(eltype(arms.instance.weights)))
    arm_payload = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-predecision-cell-arms-v1",
        "origin_id" => origin_id,
        "universe_id" => universe_id,
        "universe_status" => String(cell["status"]),
        "formation_docket_strategy_ids" => docket.selected_strategy_ids,
        "formation_docket_sha256" => _sha256_text(join(docket.selected_strategy_ids, '\n')),
        "formation_docket_count" => length(docket.selected_strategy_ids),
        "complete_capability_ids" => docket.complete_capability_ids,
        "complete_capability_count" => length(docket.complete_capability_ids),
        "source_instance_sha256" => journal_compression_instance_sha256(arms.instance),
        "source_selected_strategy_ids" => _selected_ids(arms.instance, arms.source_selected),
        "source_exact_burden" => encode_exact_rational(source_burden),
        "safe_selected_strategy_ids" => _selected_ids(arms.instance, safe_selected),
        "safe_exact_burden" => encode_exact_rational(safe_check.exact_burden),
        "safe_solver_claimed_optimal" => arms.safe_result.solver_claimed_optimal,
        "safe_solved_by_exact_preprocessing" => !arms.safe_result.diagnostics.solver_invoked,
        "safe_independent_exact_check" => safe_check.exact_feasible,
        "frontier_selected_strategy_ids" => _selected_ids(
            arms.frontier_instance,
            frontier_selected,
        ),
        "frontier_exact_burden" => encode_exact_rational(arms.frontier_result.exact_burden),
        "frontier_solver_claimed_optimal" => arms.frontier_result.solver_claimed_optimal,
        "frontier_solved_by_exact_preprocessing" => !arms.frontier_result.diagnostics.solver_invoked,
        "comparator_selected_strategy_ids" => _selected_ids(
            arms.frontier_instance,
            arms.comparator_selected,
        ),
        "comparator_exact_burden" => encode_exact_rational(comparator_check.exact_burden),
        "comparator_within_safe_burden" => comparator_check.exact_burden <= safe_check.exact_burden,
        "innovation_strategy_ids" => arms.innovation_strategy_ids,
        "source_action_set_strategy_ids" => arms.source_action_set,
        "safe_action_set_strategy_ids" => arms.safe_action_set,
        "comparator_action_set_strategy_ids" => arms.comparator_action_set,
        "comparator_action_set_subset_safe" =>
            Set(arms.comparator_action_set) ⊆ Set(arms.safe_action_set),
        "safe_action_set_subset_source" =>
            Set(arms.safe_action_set) ⊆ Set(arms.source_action_set),
        "cash_added_by_policy_layer" => true,
        "proposal_return_values_accessed" => false,
        "evaluation_return_values_accessed" => false,
    )
    arms_text = _toml_text(arm_payload)
    ledger_text = render_trial_ledger_csv(ledger)
    _write_new_or_identical(joinpath(EXPERIMENT_ROOT, arms_relative), arms_text)
    _write_new_or_identical(joinpath(EXPERIMENT_ROOT, ledger_relative), ledger_text)

    artifact_hashes = Dict(
        path_relative => path_hash,
        profile_relative => profile_hash,
        safe_relative => _sha256_text(safe_text),
        frontier_relative => _sha256_text(frontier_text),
        arms_relative => _sha256_text(arms_text),
        ledger_relative => _sha256_text(ledger_text),
    )
    safe_burden = encode_exact_rational(safe_check.exact_burden)
    comparator_burden = encode_exact_rational(comparator_check.exact_burden)
    public = Dict{String,Any}(
        "cell_index" => index,
        "origin_id" => origin_id,
        "universe_id" => universe_id,
        "role" => String(cell["role"]),
        "universe_status" => String(cell["status"]),
        "universe_gate_passed" => String(cell["status"]) == "PASSED",
        "strategy_path_count" => length(paths),
        "formation_profile_count" => length(paths) * length(formation.profile_ids),
        "compression_profile_count" => length(paths) * length(compression.profile_ids),
        "source_docket_count" => length(docket.selected_strategy_ids),
        "source_docket_sha256" => arm_payload["formation_docket_sha256"],
        "complete_capability_count" => length(docket.complete_capability_ids),
        "source_exact_burden" => encode_exact_rational(source_burden),
        "safe_exact_burden" => safe_burden,
        "frontier_exact_burden" => encode_exact_rational(arms.frontier_result.exact_burden),
        "comparator_exact_burden" => comparator_burden,
        "comparator_within_safe_burden" => comparator_check.exact_burden <= safe_check.exact_burden,
        "innovation_option_count" => length(arms.innovation_strategy_ids),
        "source_action_count_including_cash" => length(arms.source_action_set) + 1,
        "safe_action_count_including_cash" => length(arms.safe_action_set) + 1,
        "comparator_action_count_including_cash" => length(arms.comparator_action_set) + 1,
        "comparator_action_set_subset_safe" => true,
        "safe_action_set_subset_source" => true,
        "preproposal_trial_ledger_rows" => length(ledger),
        "trial_record_aggregate_sha256" =>
            _sha256_text(join((row["record_hash"] for row in ledger), '\n')),
        "safe_solver_claimed_optimal" => arms.safe_result.solver_claimed_optimal,
        "safe_solved_by_exact_preprocessing" => !arms.safe_result.diagnostics.solver_invoked,
        "frontier_solver_claimed_optimal" => arms.frontier_result.solver_claimed_optimal,
        "frontier_solved_by_exact_preprocessing" => !arms.frontier_result.diagnostics.solver_invoked,
        "independent_exact_checks_passed" => safe_check.exact_feasible &&
            comparator_check.exact_feasible,
        "local_artifact_count" => length(artifact_hashes),
        "local_artifact_aggregate_sha256" => _directory_aggregate(artifact_hashes),
        "return_values_included" => false,
        "licensed_security_identifiers_included" => false,
        "proposal_or_evaluation_values_included" => false,
    )
    local_result = copy(public)
    local_result["local_artifact_sha256"] = artifact_hashes
    local_result["local_path_parquet_bytes"] = path_bytes
    local_result["local_profile_parquet_bytes"] = profile_bytes
    local_result["return_values_included"] = true
    local_result["public_promotion_permitted"] = false
    println(stderr, "v3 predecision computation completed cell $index/38 $origin_id $universe_id")
    return (; public, local_result)
end

function run_predecision_computation()
    contract = _load_contract()
    public_cells = _cell_by_index(contract.public_stage)
    local_cells = _cell_by_index(contract.local_stage)
    sort!(collect(keys(public_cells))) == collect(1:38) ||
        error("public predecision stage does not contain 38 canonical cells")
    sort!(collect(keys(local_cells))) == collect(1:38) ||
        error("local predecision stage does not contain 38 canonical cells")
    for index in 1:38
        public = public_cells[index]
        local_cell = local_cells[index]
        for field in (
            "origin_id",
            "universe_id",
            "status",
            "decision_date",
            "local_artifact_relative_path",
            "local_artifact_sha256",
        )
            public[field] == local_cell[field] || error("stage manifests disagree for cell $index")
        end
    end

    results = Vector{Any}(undef, 38)
    Threads.@threads :static for index in 1:38
        results[index] = _cell_computation(local_cells[index])
    end
    public_result_cells = [results[index].public for index in 1:38]
    local_result_cells = [results[index].local_result for index in 1:38]
    total_rows = sum(Int(cell["preproposal_trial_ledger_rows"]) for cell in public_result_cells)
    total_rows == 38 * 485 || error("complete v3 preproposal ledger row count changed")
    common = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-predecision-computation-manifest-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "PREPROPOSAL_STRUCTURAL_STATE_FROZEN",
        "language" => "Julia",
        "cell_count" => 38,
        "primary_common_equity_cells" => 19,
        "registered_etf_cells" => 19,
        "failed_universe_cells_retained" => count(
            cell -> !cell["universe_gate_passed"],
            public_result_cells,
        ),
        "strategy_paths_per_cell" => 96,
        "formation_profiles_per_cell" => 1_152,
        "compression_profiles_per_cell" => 1_152,
        "registered_policies" => 5,
        "preproposal_trial_ledger_rows" => total_rows,
        "all_comparator_action_sets_nested" => all(
            cell -> cell["comparator_action_set_subset_safe"],
            public_result_cells,
        ),
        "all_safe_action_sets_nested" => all(
            cell -> cell["safe_action_set_subset_source"],
            public_result_cells,
        ),
        "all_exact_postchecks_passed" => all(
            cell -> cell["independent_exact_checks_passed"],
            public_result_cells,
        ),
        "predecision_computation_lock_sha256" => _sha256_file(COMPUTATION_LOCK_PATH),
        "public_stage_manifest_sha256" => _sha256_file(PUBLIC_STAGE_MANIFEST_PATH),
        "local_stage_manifest_sha256" => _sha256_file(LOCAL_STAGE_MANIFEST_PATH),
        "historical_predecision_return_computation_permitted" => true,
        "historical_proposal_or_evaluation_return_access_permitted" => false,
        "proposal_return_values_accessed" => false,
        "evaluation_return_values_accessed" => false,
        "v3_outcomes_opened" => false,
    )
    public_payload = copy(common)
    public_payload["return_values_included"] = false
    public_payload["licensed_security_identifiers_included"] = false
    public_payload["public_promotion_permitted"] = true
    public_payload["cells"] = public_result_cells
    public_text = _toml_text(public_payload)
    _write_new_or_identical(PUBLIC_RESULT_MANIFEST_PATH, public_text)

    local_payload = copy(common)
    local_payload["return_values_included"] = true
    local_payload["licensed_security_identifiers_included"] = false
    local_payload["public_promotion_permitted"] = false
    local_payload["public_manifest_sha256"] = _sha256_text(public_text)
    local_payload["cells"] = local_result_cells
    local_text = _toml_text(local_payload)
    _write_new_or_identical(LOCAL_RESULT_MANIFEST_PATH, local_text)
    println("V3_PREDECISION_COMPUTATION_PASSED")
    println("cells frozen: 38")
    println("preproposal trial-ledger rows: $total_rows")
    println("proposal/evaluation return values accessed: false")
    return public_payload
end

function audit_predecision_computation()
    _load_contract()
    for path in (PUBLIC_RESULT_MANIFEST_PATH, LOCAL_RESULT_MANIFEST_PATH)
        isfile(path) || error("v3 predecision computation result manifest is absent")
    end
    public = TOML.parsefile(PUBLIC_RESULT_MANIFEST_PATH)
    local_manifest = TOML.parsefile(LOCAL_RESULT_MANIFEST_PATH)
    public["status"] == "PREPROPOSAL_STRUCTURAL_STATE_FROZEN" ||
        error("unexpected public v3 preproposal status")
    public["return_values_included"] === false ||
        error("public preproposal manifest contains returns")
    public["licensed_security_identifiers_included"] === false ||
        error("public preproposal manifest contains licensed identifiers")
    public["proposal_return_values_accessed"] === false ||
        error("proposal returns were accessed before preproposal seal")
    public["evaluation_return_values_accessed"] === false ||
        error("evaluation returns were accessed before preproposal seal")
    public["preproposal_trial_ledger_rows"] == 38 * 485 ||
        error("preproposal ledger denominator changed")
    local_manifest["public_manifest_sha256"] == _sha256_text(read(PUBLIC_RESULT_MANIFEST_PATH, String)) ||
        error("local/public computation manifests are not bound")
    local_cells = _cell_by_index(local_manifest)
    length(local_cells) == 38 || error("local computation manifest omitted a cell")
    for index in 1:38
        hashes = Dict{String,String}(local_cells[index]["local_artifact_sha256"])
        _directory_aggregate(hashes) == local_cells[index]["local_artifact_aggregate_sha256"] ||
            error("cell $index computation artifact aggregate changed")
        for (relative, digest) in hashes
            path = joinpath(EXPERIMENT_ROOT, relative)
            isfile(path) || error("cell $index computation artifact is absent: $relative")
            _sha256_file(path) == digest || error("cell $index computation artifact changed: $relative")
        end
    end
    println("V3_PREDECISION_COMPUTATION_AUDIT_PASSED")
    println("public manifest contains return values: false")
    println("proposal/evaluation return values accessed: false")
    return public
end

function main(args = ARGS)
    length(args) == 1 || error("use exactly one of --run or --audit-only")
    args[1] == "--run" && return run_predecision_computation()
    args[1] == "--audit-only" && return audit_predecision_computation()
    error("unknown argument: $(args[1])")
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    RunFinancialStrategyLibraryPanelV3PredecisionComputation.main()
end
