module CheckFinancialStrategyLibraryPanelV3PredecisionBindingReplay

using Parquet
using StrategyInnovation: check_journal_compression_solution,
                          encode_exact_rational,
                          journal_compression_instance_sha256,
                          journal_mip_solution_certificate
using Tables
using TOML

include(joinpath(@__DIR__, "run_financial_strategy_library_panel_v3_predecision_computation.jl"))
const Runner = RunFinancialStrategyLibraryPanelV3PredecisionComputation

export check_binding_replay, main

const EXPERIMENT_ROOT = Runner.EXPERIMENT_ROOT
const PUBLIC_RESULT_MANIFEST_PATH = Runner.PUBLIC_RESULT_MANIFEST_PATH
const LOCAL_RESULT_MANIFEST_PATH = Runner.LOCAL_RESULT_MANIFEST_PATH
const FINAL_BINDING_LOCK_PATH = joinpath(
    EXPERIMENT_ROOT,
    "PREDECISION_AUDIT_AMENDMENT_004_LOCK.toml",
)

function _require_final_binding_lock()
    isfile(FINAL_BINDING_LOCK_PATH) || error("predecision audit amendment 004 lock is absent")
    lock = TOML.parsefile(FINAL_BINDING_LOCK_PATH)
    lock["status"] == "LOCKED_PREDECISION_AUDIT_AMENDMENT_004" ||
        error("unexpected predecision audit-amendment status")
    lock["historical_proposal_or_evaluation_return_access_permitted"] === false ||
        error("binding lock permits forbidden postdecision access")
    hashes = Dict{String,String}(lock["sealed_file_sha256"])
    for (relative, digest) in hashes
        Runner._sha256_file(joinpath(Runner.REPOSITORY_ROOT, relative)) == digest ||
            error("binding-lock input changed: $relative")
    end
    return lock
end

function _columns_equal(left, right)
    names = propertynames(right)
    propertynames(left) == names || return false
    for name in names
        a = collect(getproperty(left, name))
        b = collect(getproperty(right, name))
        length(a) == length(b) || return false
        all(isequal.(a, b)) || return false
    end
    return true
end

function _stable_mip_certificate(payload)
    result = deepcopy(payload)
    delete!(result, "runtime_ns")
    diagnostics = result["solver_diagnostics"]
    delete!(diagnostics, "solve_time_seconds")
    delete!(diagnostics, "complete_solver_log")
    return result
end

function _selected_ids(instance, selected)
    return sort!(String[
        String(instance.strategy_ids[index].id) for index in findall(selected)
    ])
end

function _check_arm_manifest(existing, cell, paths, docket, arms)
    safe_selected = BitVector(arms.safe_result.reconstructed_candidate)
    frontier_selected = BitVector(arms.frontier_result.reconstructed_candidate)
    safe_check = check_journal_compression_solution(arms.instance, safe_selected)
    comparator_check = check_journal_compression_solution(
        arms.frontier_instance,
        arms.comparator_selected,
    )
    source_burden = sum(arms.instance.weights; init = zero(eltype(arms.instance.weights)))
    expected = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-predecision-cell-arms-v1",
        "origin_id" => String(cell["origin_id"]),
        "universe_id" => String(cell["universe_id"]),
        "universe_status" => String(cell["status"]),
        "formation_docket_strategy_ids" => docket.selected_strategy_ids,
        "formation_docket_sha256" => Runner._sha256_text(join(docket.selected_strategy_ids, '\n')),
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
        "frontier_selected_strategy_ids" =>
            _selected_ids(arms.frontier_instance, frontier_selected),
        "frontier_exact_burden" => encode_exact_rational(arms.frontier_result.exact_burden),
        "frontier_solver_claimed_optimal" => arms.frontier_result.solver_claimed_optimal,
        "frontier_solved_by_exact_preprocessing" =>
            !arms.frontier_result.diagnostics.solver_invoked,
        "comparator_selected_strategy_ids" =>
            _selected_ids(arms.frontier_instance, arms.comparator_selected),
        "comparator_exact_burden" => encode_exact_rational(comparator_check.exact_burden),
        "comparator_within_safe_burden" =>
            comparator_check.exact_burden <= safe_check.exact_burden,
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
    existing == expected || error("cell arm manifest changed")
    return nothing
end

function _check_cell(cell, public_cell, local_cell)
    index = Int(cell["cell_index"])
    origin_id = String(cell["origin_id"])
    universe_id = String(cell["universe_id"])
    panel = Runner._load_cell_panel(cell)
    cap = universe_id == "liquid_common_equity" ? 0.05 : 0.10
    paths = Runner.build_strategy_paths(
        origin_id,
        universe_id,
        panel.returns,
        panel.available,
        panel.terminal_delisting;
        security_weight_cap = cap,
    )
    formation_start = Int(cell["formation_start_year"])
    decision_year = Int(cell["compression_decision_year"])
    formation = Runner.profile_bundle(paths, panel.dates, formation_start:(formation_start + 2))
    docket = Runner.freeze_source_docket(paths, formation, universe_id)
    compression = Runner.profile_bundle(paths, panel.dates, (decision_year - 2):decision_year)
    arms = Runner.compression_arms(origin_id, universe_id, paths, docket, compression)
    ledger = Runner.preproposal_trial_rows(
        origin_id,
        universe_id,
        paths,
        docket,
        arms;
        universe_status = String(cell["status"]),
    )

    prefix = "cell-$(lpad(index, 3, '0'))"
    local_root = joinpath(EXPERIMENT_ROOT, "local_data", "predecision_computation")
    existing_paths = Tables.columntable(Parquet.Table(
        joinpath(local_root, "$prefix-paths.parquet"); use_threads = false,
    ))
    _columns_equal(existing_paths, Runner._path_table(paths, panel.dates)) ||
        error("cell $index path artifact failed deterministic replay")
    existing_profiles = Tables.columntable(Parquet.Table(
        joinpath(local_root, "$prefix-profiles.parquet"); use_threads = false,
    ))
    _columns_equal(existing_profiles, Runner._profile_table(paths, formation, compression)) ||
        error("cell $index profile artifact failed deterministic replay")

    for (label, result) in (
        ("safe", arms.safe_result),
        ("frontier", arms.frontier_result),
    )
        existing = TOML.parsefile(joinpath(local_root, "$prefix-$label-mip.toml"))
        current = journal_mip_solution_certificate(result)
        _stable_mip_certificate(existing) == _stable_mip_certificate(current) ||
            error("cell $index $label MIP scientific certificate changed")
    end
    _check_arm_manifest(
        TOML.parsefile(joinpath(local_root, "$prefix-arms.toml")),
        cell,
        paths,
        docket,
        arms,
    )
    ledger_text = Runner.render_trial_ledger_csv(ledger)
    read(joinpath(local_root, "$prefix-trial-ledger.csv"), String) == ledger_text ||
        error("cell $index trial ledger changed")

    safe_check = check_journal_compression_solution(
        arms.instance,
        BitVector(arms.safe_result.reconstructed_candidate),
    )
    comparator_check = check_journal_compression_solution(
        arms.frontier_instance,
        arms.comparator_selected,
    )
    public_cell["source_docket_sha256"] ==
        Runner._sha256_text(join(docket.selected_strategy_ids, '\n')) ||
        error("cell $index public docket digest changed")
    public_cell["safe_exact_burden"] == encode_exact_rational(safe_check.exact_burden) ||
        error("cell $index public safe burden changed")
    public_cell["frontier_exact_burden"] ==
        encode_exact_rational(arms.frontier_result.exact_burden) ||
        error("cell $index public frontier burden changed")
    public_cell["comparator_exact_burden"] ==
        encode_exact_rational(comparator_check.exact_burden) ||
        error("cell $index public comparator burden changed")
    public_cell["trial_record_aggregate_sha256"] ==
        Runner._sha256_text(join((row["record_hash"] for row in ledger), '\n')) ||
        error("cell $index public trial-record aggregate changed")
    Dict{String,String}(local_cell["local_artifact_sha256"]) == Dict(
        relative => Runner._sha256_file(joinpath(EXPERIMENT_ROOT, relative)) for
        relative in keys(local_cell["local_artifact_sha256"])
    ) || error("cell $index local artifact hash binding changed")
    println(stderr, "v3 binding replay checked cell $index/38 $origin_id $universe_id")
    return true
end

function check_binding_replay()
    _require_final_binding_lock()
    contract = Runner._load_contract()
    isfile(PUBLIC_RESULT_MANIFEST_PATH) || error("public result manifest is absent")
    isfile(LOCAL_RESULT_MANIFEST_PATH) || error("local result manifest is absent")
    public = TOML.parsefile(PUBLIC_RESULT_MANIFEST_PATH)
    local_manifest = TOML.parsefile(LOCAL_RESULT_MANIFEST_PATH)
    public_cells = Runner._cell_by_index(public)
    local_cells = Runner._cell_by_index(local_manifest)
    stage_cells = Runner._cell_by_index(contract.local_stage)
    sort!(collect(keys(stage_cells))) == collect(1:38) || error("stage denominator changed")
    checked = falses(38)
    Threads.@threads :static for index in 1:38
        checked[index] = _check_cell(
            stage_cells[index],
            public_cells[index],
            local_cells[index],
        )
    end
    all(checked) || error("full binding replay is incomplete")
    println("V3_PREDECISION_BINDING_FULL_REPLAY_PASSED")
    println("cells scientifically replayed: 38")
    println("proposal/evaluation returns accessed: false")
    return true
end

main(args = ARGS) = isempty(args) ? check_binding_replay() : error("this checker takes no arguments")

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    CheckFinancialStrategyLibraryPanelV3PredecisionBindingReplay.main()
end
