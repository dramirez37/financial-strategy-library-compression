module RunFinancialStrategyLibraryPanelV3Proposal

using Parquet
using SHA: sha256
using Tables
using TOML

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV3Proposal.jl"))
using .FinancialStrategyLibraryPanelV3Proposal
const Proposal = FinancialStrategyLibraryPanelV3Proposal

export audit_proposal_computation, run_proposal_computation, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const EXECUTION_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PROPOSAL_EXECUTION_LOCK.toml")
const COMPUTATION_AMENDMENT_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_COMPUTATION_AMENDMENT_001_LOCK_003.toml")
const PREDECISION_RESULT_SEAL_PATH =
    joinpath(EXPERIMENT_ROOT, "PREDECISION_COMPUTATION_RESULT_SEAL.toml")
const PUBLIC_STAGE_MANIFEST_PATH =
    joinpath(EXPERIMENT_ROOT, "proposal_stage", "PROPOSAL_STAGE_MANIFEST.toml")
const LOCAL_STAGE_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal",
    "PROPOSAL_STAGE_LOCAL_MANIFEST.toml",
)
const LOCAL_PREDECISION_RESULT_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "predecision_computation",
    "PREDECISION_COMPUTATION_LOCAL_MANIFEST.toml",
)
const LOCAL_RESULT_ROOT = joinpath(EXPERIMENT_ROOT, "local_data", "proposal_computation")
const LOCAL_RESULT_MANIFEST_PATH =
    joinpath(LOCAL_RESULT_ROOT, "PROPOSAL_COMPUTATION_LOCAL_MANIFEST.toml")
const PUBLIC_RESULT_ROOT = joinpath(EXPERIMENT_ROOT, "proposal_computation")
const PUBLIC_RESULT_MANIFEST_PATH =
    joinpath(PUBLIC_RESULT_ROOT, "PROPOSAL_COMPUTATION_MANIFEST.toml")
const CASH_ID = "mandatory_inactive_cash"
const BASE_SEED = 310002
const HURDLE = 0.0025
const LEDGER_FIELDS = (
    "trial_id",
    "origin_id",
    "universe_id",
    "strategy_id",
    "compression_arm_id",
    "policy_id",
    "requirements_hash",
    "generatable",
    "failure_code",
    "proposal_observation_count",
    "proposal_ce",
    "proposal_incremental_lower_bound",
    "policy_eligible",
    "policy_selected",
    "evaluation_observation_count",
    "evaluation_ce",
    "evaluation_mean_component",
    "evaluation_variance_penalty",
    "evaluation_turnover_cost",
    "record_hash",
)

struct CombinedPanel
    dates::Vector{String}
    permnos::Vector{Int64}
    returns::Matrix{Union{Missing,Float64}}
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

function _aggregate(hashes)
    canonical = join(
        ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
    )
    return _sha256_text(canonical)
end

function _write_new_or_identical(path, content)
    if isfile(path)
        read(path, String) == content ||
            error("refusing to replace a nonidentical proposal computation artifact")
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
            _sha256_file(path) == digest ||
                error("refusing to replace a nonidentical proposal path artifact")
        else
            mkpath(dirname(path))
            mv(candidate, path)
        end
        return digest, bytes
    end
end

function _csv_rows(path)
    lines = readlines(path)
    header = split(first(lines), ','; keepempty = true)
    header == collect(LEDGER_FIELDS) || error("trial-ledger schema changed")
    rows = Dict{String,Any}[]
    for line in Iterators.drop(lines, 1)
        isempty(line) && continue
        values = split(line, ','; keepempty = true)
        length(values) == length(header) || error("unexpected quoted field in trial ledger")
        push!(rows, Dict{String,Any}(String(key) => String(value) for (key, value) in zip(header, values)))
    end
    return rows
end

function _load_contract()
    for path in (
        EXECUTION_LOCK_PATH,
        PREDECISION_RESULT_SEAL_PATH,
        PUBLIC_STAGE_MANIFEST_PATH,
        LOCAL_STAGE_MANIFEST_PATH,
        LOCAL_PREDECISION_RESULT_MANIFEST_PATH,
    )
        isfile(path) || error("proposal computation input is absent: $(relpath(path, REPOSITORY_ROOT))")
    end
    lock = TOML.parsefile(EXECUTION_LOCK_PATH)
    lock["status"] == "LOCKED_PROPOSAL_EXECUTION" || error("proposal execution is not locked")
    lock["historical_proposal_return_access_permitted"] === true ||
        error("proposal computation is not permitted")
    lock["historical_evaluation_return_access_permitted"] === false ||
        error("proposal execution lock permits evaluation access")
    lock["failed_universe_cell_proposal_access_permitted"] === false ||
        error("proposal execution lock permits failed-cell access")
    lock["predecision_computation_result_seal_sha256"] ==
        _sha256_file(PREDECISION_RESULT_SEAL_PATH) ||
        error("proposal execution is not bound to the predecision result seal")
    isfile(COMPUTATION_AMENDMENT_PATH) || error("proposal computation amendment 001 is absent")
    amendment = TOML.parsefile(COMPUTATION_AMENDMENT_PATH)
    amendment["status"] == "LOCKED_PROPOSAL_COMPUTATION_AMENDMENT_001_003" ||
        error("unexpected proposal computation amendment status")
    amendment["previous_proposal_execution_lock_sha256"] == _sha256_file(EXECUTION_LOCK_PATH) ||
        error("proposal computation amendment is not bound to the execution lock")
    amendment["historical_evaluation_return_access_permitted"] === false ||
        error("proposal computation amendment permits evaluation access")
    amended_hashes = Dict{String,String}(amendment["sealed_file_sha256"])
    runner_relative = "julia/scripts/run_financial_strategy_library_panel_v3_proposal.jl"
    amended_hashes[runner_relative] == _sha256_file(joinpath(REPOSITORY_ROOT, runner_relative)) ||
        error("amended proposal runner changed")
    for (relative, digest) in amended_hashes
        _sha256_file(joinpath(REPOSITORY_ROOT, relative)) == digest ||
            error("proposal computation amendment input changed: $relative")
    end
    for (relative, digest) in Dict{String,String}(lock["sealed_file_sha256"])
        actual = _sha256_file(joinpath(REPOSITORY_ROOT, relative))
        actual == digest && continue
        get(amended_hashes, relative, "") == actual ||
            error("proposal-execution sealed file changed without amendment: $relative")
    end
    public_stage = TOML.parsefile(PUBLIC_STAGE_MANIFEST_PATH)
    local_stage = TOML.parsefile(LOCAL_STAGE_MANIFEST_PATH)
    for manifest in (public_stage, local_stage)
        manifest["status"] == "PROPOSAL_RETURNS_STAGED" ||
            error("unexpected proposal-stage status")
        manifest["cell_count"] == 38 || error("proposal-stage cell denominator changed")
        manifest["accessed_cell_count"] == 37 || error("proposal-stage access count changed")
        manifest["failed_universe_cells_retained_without_access"] == 1 ||
            error("proposal stage omitted the failed universe cell")
        manifest["evaluation_values_inspected"] == 0 || error("evaluation values were inspected")
        manifest["evaluation_values_materialized"] == 0 || error("evaluation values were materialized")
        manifest["evaluation_values_used"] == 0 || error("evaluation values were used")
    end
    local_stage["public_manifest_sha256"] == _sha256_file(PUBLIC_STAGE_MANIFEST_PATH) ||
        error("proposal-stage manifests are not bound")
    return (; lock, public_stage, local_stage,
        predecision = TOML.parsefile(LOCAL_PREDECISION_RESULT_MANIFEST_PATH))
end

_cell_map(manifest) = Dict(Int(cell["cell_index"]) => cell for cell in manifest["cells"])

function _load_combined_panel(cell)
    relative = String(cell["local_artifact_relative_path"])
    isempty(relative) && error("gate-passed proposal cell has no staged artifact")
    path = joinpath(EXPERIMENT_ROOT, relative)
    _sha256_file(path) == String(cell["local_artifact_sha256"]) ||
        error("staged proposal cell changed: $relative")
    columns = Tables.columntable(Parquet.Table(path; use_threads = false))
    count = length(columns.permno)
    count == Int(cell["combined_row_count"]) || error("combined proposal row count changed")
    permnos = sort!(unique(Int64.(columns.permno)))
    isempty(permnos) && error("combined proposal panel has no securities")
    sessions = count ÷ length(permnos)
    sessions * length(permnos) == count || error("combined proposal panel is not rectangular")
    dates = String.(columns.date[1:sessions])
    issorted(dates) && allunique(dates) || error("combined proposal calendar is not canonical")
    returns = Matrix{Union{Missing,Float64}}(undef, sessions, length(permnos))
    available = falses(sessions, length(permnos))
    terminal = falses(sessions, length(permnos))
    for (security, permno) in enumerate(permnos)
        first_row = (security - 1) * sessions + 1
        rows = first_row:(first_row + sessions - 1)
        all(==(permno), @view columns.permno[rows]) ||
            error("combined proposal security rows are not contiguous")
        String.(columns.date[rows]) == dates ||
            error("combined proposal security calendars differ")
        returns[:, security] .= columns.total_return[rows]
        available[:, security] .= Bool.(columns.return_available[rows])
        terminal[:, security] .= Bool.(columns.terminal_delisting[rows])
    end
    return CombinedPanel(dates, permnos, returns, available, terminal)
end

function _arm_payload(index, predecision_manifest, result_seal)
    prefix = "cell-$(lpad(index, 3, '0'))"
    relative = joinpath("local_data", "predecision_computation", "$prefix-arms.toml")
    hashes = Dict{String,String}(predecision_manifest["local_artifact_sha256"])
    digest = String(hashes[relative])
    seal_hashes = Dict{String,String}(result_seal["local_artifact_sha256"])
    seal_hashes[relative] == digest || error("result seal does not bind cell arms")
    path = joinpath(EXPERIMENT_ROOT, relative)
    _sha256_file(path) == digest || error("predecision cell arms changed")
    return TOML.parsefile(path)
end

function _path_lookup(paths)
    return Dict(path.strategy_id => path for path in paths)
end

function _raw_path_stats(paths)
    result = Dict{String,NamedTuple}()
    for path in paths
        observations = count(identity, path.available)
        values = Proposal._complete_values(path)
        result[path.strategy_id] = (;
            observations,
            complete = !isnothing(values),
            raw_ce = isnothing(values) ? nothing : Proposal._ce(values),
        )
    end
    return result
end

function _inference_lookup(inference)
    return Dict(
        inference.candidate_ids[index] => (;
            point = inference.point_deltas[index],
            standard_error = inference.standard_errors[index],
            lower_bound = inference.lower_bounds[index],
            shrunk_delta = inference.shrunk_deltas[index],
        ) for index in eachindex(inference.candidate_ids)
    )
end

_finite_or_blank(value) = value isa Real && isfinite(value) ? Float64(value) : ""

function _choice_payload(choice)
    return Dict{String,Any}(
        "policy_id" => choice.policy_id,
        "selected_strategy_ids" => choice.selected_strategy_ids,
        "used_cash" => choice.used_cash,
        "baseline_strategy_id" => choice.baseline_strategy_id,
        "selected_point_delta" => _finite_or_blank(choice.selected_point_delta),
        "selected_lower_bound" => _finite_or_blank(choice.selected_lower_bound),
        "eligible_count" => choice.eligible_count,
        "complete_candidate_count" => choice.complete_candidate_count,
        "failure_code" => choice.failure_code,
    )
end

function _inference_payload(policy_id, inference)
    candidates = Dict{String,Any}[]
    for index in eachindex(inference.candidate_ids)
        push!(candidates, Dict{String,Any}(
            "strategy_id" => inference.candidate_ids[index],
            "point_delta" => inference.point_deltas[index],
            "standard_error" => inference.standard_errors[index],
            "simultaneous_lower_bound" => inference.lower_bounds[index],
            "shrunk_delta" => inference.shrunk_deltas[index],
        ))
    end
    return Dict{String,Any}(
        "policy_id" => String(policy_id),
        "bootstrap_repetitions" => inference.bootstrap_repetitions,
        "moving_block_sessions" => inference.moving_block_sessions,
        "seed" => inference.seed,
        "familywise_alpha" => 0.10,
        "critical_value" => inference.critical_value,
        "shrinkage_center" => inference.shrinkage_center,
        "estimated_between_variance" => inference.estimated_between_variance,
        "candidate_count" => length(candidates),
        "candidates" => candidates,
    )
end

function _path_table(paths, dates)
    rows = length(paths) * length(dates)
    strategy_id = Vector{String}(undef, rows)
    output_date = Vector{String}(undef, rows)
    net_return = Vector{Union{Missing,Float64}}(undef, rows)
    available = Vector{Bool}(undef, rows)
    cursor = 1
    for path in sort!(collect(paths); by = item -> item.strategy_id), session in eachindex(dates)
        strategy_id[cursor] = path.strategy_id
        output_date[cursor] = dates[session]
        net_return[cursor] = path.net_returns[session]
        available[cursor] = path.available[session]
        cursor += 1
    end
    return (; strategy_id, date = output_date, net_return, available)
end

function _record_hash!(row)
    row["record_hash"] = _sha256_text(join((string(row[field]) for field in LEDGER_FIELDS[1:end-1]), '\0'))
    return row
end

function _fill_trial_ledger(
    rows,
    sessions,
    path_stats,
    choices,
    inferences,
)
    inference_lookup = Dict(policy => _inference_lookup(value) for (policy, value) in inferences)
    selected = Dict(policy => Set(choice.selected_strategy_ids) for (policy, choice) in choices)
    safe_baseline = choices["innovation_safe_robust_policy"].baseline_strategy_id
    baseline_ce = safe_baseline == CASH_ID ? 0.0 : path_stats[safe_baseline].raw_ce
    isnothing(baseline_ce) && error("safe comparator baseline is incomplete")
    for row in rows
        policy = String(row["policy_id"])
        strategy = String(row["strategy_id"])
        generatable = row["generatable"] == "true" || row["generatable"] === true
        row["generatable"] = generatable
        row["evaluation_observation_count"] = 0
        for field in (
            "evaluation_ce",
            "evaluation_mean_component",
            "evaluation_variance_penalty",
            "evaluation_turnover_cost",
        )
            row[field] = ""
        end
        row["proposal_observation_count"] = 0
        row["proposal_ce"] = ""
        row["proposal_incremental_lower_bound"] = ""
        row["policy_eligible"] = false
        row["policy_selected"] = false
        if !generatable
            _record_hash!(row)
            continue
        end
        row["failure_code"] = ""
        row["policy_selected"] = strategy in selected[policy]
        if strategy == CASH_ID
            row["proposal_observation_count"] = sessions
            row["proposal_ce"] = 0.0
            if policy in ("frontier_only_robust_policy", "source_uncompressed_robust_policy")
                row["proposal_incremental_lower_bound"] = 0.0
                row["policy_eligible"] = true
            elseif policy == "innovation_safe_robust_policy"
                if safe_baseline == CASH_ID
                    row["proposal_incremental_lower_bound"] = 0.0
                    row["policy_eligible"] = true
                end
            elseif policy == "equal_weight_available_policy"
                row["policy_eligible"] = row["policy_selected"]
            end
            _record_hash!(row)
            continue
        end
        haskey(path_stats, strategy) || error("proposal trial is outside frozen action paths")
        stats = path_stats[strategy]
        row["proposal_observation_count"] = stats.observations
        if !stats.complete
            row["failure_code"] = "INCOMPLETE_PROPOSAL_PATH"
            _record_hash!(row)
            continue
        end
        if policy in ("frontier_only_robust_policy", "source_uncompressed_robust_policy")
            info = inference_lookup[policy][strategy]
            row["proposal_ce"] = info.shrunk_delta
            row["proposal_incremental_lower_bound"] = info.lower_bound
            row["policy_eligible"] = info.lower_bound > HURDLE
        elseif policy == "innovation_safe_robust_policy"
            if strategy == safe_baseline
                row["proposal_ce"] = Float64(baseline_ce)
                row["proposal_incremental_lower_bound"] = 0.0
                row["policy_eligible"] = true
            else
                info = inference_lookup[policy][strategy]
                row["proposal_ce"] = Float64(baseline_ce) + info.shrunk_delta
                row["proposal_incremental_lower_bound"] = info.lower_bound
                row["policy_eligible"] = info.lower_bound > HURDLE
            end
        elseif policy == "innovation_safe_forced_max"
            row["proposal_ce"] = stats.raw_ce
            row["policy_eligible"] = true
        elseif policy == "equal_weight_available_policy"
            row["proposal_ce"] = stats.raw_ce
            row["policy_eligible"] = stats.raw_ce > 0
        else
            error("unregistered proposal policy: $policy")
        end
        _record_hash!(row)
    end
    length(rows) == 485 || error("proposal trial ledger cell denominator changed")
    selected_policy_count = length(unique(
        String(row["policy_id"]) for row in rows if Bool(row["policy_selected"])
    ))
    selected_policy_count >= 4 ||
        error("a cash-capable registered policy has no frozen choice")
    if selected_policy_count == 4
        forced = choices["innovation_safe_forced_max"]
        isempty(forced.selected_strategy_ids) &&
            forced.failure_code == "NO_COMPLETE_ACTIVE_PROPOSAL_PATH" ||
            error("only the cash-omitted forced control may freeze without a selected path")
    end
    return rows
end

function _policy_computation(origin_id, universe_id, panel, proposal_year, arms)
    source_ids = String.(arms["source_action_set_strategy_ids"])
    safe_ids = String.(arms["safe_action_set_strategy_ids"])
    comparator_ids = String.(arms["comparator_action_set_strategy_ids"])
    Set(comparator_ids) ⊆ Set(safe_ids) ⊆ Set(source_ids) ||
        error("frozen proposal action sets are not nested")
    cap = universe_id == "liquid_common_equity" ? 0.05 : 0.10
    built = action_candidate_paths(
        origin_id,
        universe_id,
        panel.returns,
        panel.available,
        panel.terminal_delisting,
        panel.dates,
        proposal_year,
        source_ids;
        security_weight_cap = cap,
    )
    source_paths = built.paths
    lookup = _path_lookup(source_paths)
    safe_paths = ProposalCandidatePath[lookup[id] for id in safe_ids]
    comparator_paths = ProposalCandidatePath[lookup[id] for id in comparator_ids]
    scope = (origin_id, universe_id)
    comparator_choice, comparator_inference = robust_cash_choice(
        "frontier_only_robust_policy",
        comparator_paths;
        base_seed = BASE_SEED,
        scope_values = scope,
    )
    safe_choice, safe_inference = robust_safe_choice(
        safe_paths,
        comparator_choice;
        comparator_candidates = comparator_paths,
        base_seed = BASE_SEED,
        scope_values = scope,
    )
    source_choice, source_inference = robust_cash_choice(
        "source_uncompressed_robust_policy",
        source_paths;
        base_seed = BASE_SEED,
        scope_values = scope,
    )
    forced_choice = forced_max_choice(safe_paths)
    equal_choice = equal_weight_positive_choice(safe_paths)
    choices = Dict(
        "frontier_only_robust_policy" => comparator_choice,
        "innovation_safe_robust_policy" => safe_choice,
        "innovation_safe_forced_max" => forced_choice,
        "equal_weight_available_policy" => equal_choice,
        "source_uncompressed_robust_policy" => source_choice,
    )
    inferences = Dict(
        "frontier_only_robust_policy" => comparator_inference,
        "innovation_safe_robust_policy" => safe_inference,
        "source_uncompressed_robust_policy" => source_inference,
    )
    proposal_dates = panel.dates[built.proposal_indices]
    cash = cash_candidate_path(length(proposal_dates))
    all_paths = ProposalCandidatePath[source_paths...; cash]
    return (; choices, inferences, all_paths, source_paths, proposal_dates)
end

function _cell_computation(index, stage_cell, predecision_cell, result_seal)
    origin_id = String(stage_cell["origin_id"])
    universe_id = String(stage_cell["universe_id"])
    prefix = "cell-$(lpad(index, 3, '0'))"
    preledger_relative = joinpath(
        "local_data",
        "predecision_computation",
        "$prefix-trial-ledger.csv",
    )
    preledger_hashes = Dict{String,String}(predecision_cell["local_artifact_sha256"])
    preledger_path = joinpath(EXPERIMENT_ROOT, preledger_relative)
    _sha256_file(preledger_path) == preledger_hashes[preledger_relative] ||
        error("preproposal trial ledger changed")
    rows = _csv_rows(preledger_path)
    artifact_hashes = Dict{String,String}()
    local_summary = Dict{String,Any}()
    if !Bool(stage_cell["universe_gate_passed"])
        String(stage_cell["failure_code"]) == "UNIVERSE_GATE_FAILED" ||
            error("failed proposal cell has unexpected reason")
        all(row -> row["failure_code"] == "UNIVERSE_GATE_FAILED", rows) ||
            error("failed-cell ledger reason changed")
        ledger_relative = joinpath("local_data", "proposal_computation", "$prefix-trial-ledger.csv")
        ledger_text = Proposal.FinancialStrategyLibraryPanelV3PredecisionComputation.render_trial_ledger_csv(rows)
        _write_new_or_identical(joinpath(EXPERIMENT_ROOT, ledger_relative), ledger_text)
        artifact_hashes[ledger_relative] = _sha256_text(ledger_text)
        choice_relative = joinpath("local_data", "proposal_computation", "$prefix-choices.toml")
        choice_text = _toml_text(Dict{String,Any}(
            "schema_version" => "financial-strategy-library-panel-v3-proposal-cell-choices-v1",
            "cell_index" => index,
            "origin_id" => origin_id,
            "universe_id" => universe_id,
            "status" => "UNAVAILABLE_UNIVERSE_GATE_FAILED",
            "proposal_values_accessed" => false,
            "evaluation_values_accessed" => false,
            "registered_policy_count" => 5,
            "choices_frozen" => false,
        ))
        _write_new_or_identical(joinpath(EXPERIMENT_ROOT, choice_relative), choice_text)
        artifact_hashes[choice_relative] = _sha256_text(choice_text)
        local_summary["selected_choices"] = Dict{String,Any}[]
        status = "UNAVAILABLE_UNIVERSE_GATE_FAILED"
        forced_max_available = false
    else
        panel = _load_combined_panel(stage_cell)
        proposal_year = Int(stage_cell["proposal_year"])
        arms = _arm_payload(index, predecision_cell, result_seal)
        computed = _policy_computation(origin_id, universe_id, panel, proposal_year, arms)
        path_stats = _raw_path_stats(computed.source_paths)
        rows = _fill_trial_ledger(
            rows,
            length(computed.proposal_dates),
            path_stats,
            computed.choices,
            computed.inferences,
        )
        path_relative = joinpath("local_data", "proposal_computation", "$prefix-paths.parquet")
        path_hash, path_bytes = _install_parquet(
            joinpath(EXPERIMENT_ROOT, path_relative),
            _path_table(computed.all_paths, computed.proposal_dates),
        )
        artifact_hashes[path_relative] = path_hash
        ledger_relative = joinpath("local_data", "proposal_computation", "$prefix-trial-ledger.csv")
        ledger_text = Proposal.FinancialStrategyLibraryPanelV3PredecisionComputation.render_trial_ledger_csv(rows)
        _write_new_or_identical(joinpath(EXPERIMENT_ROOT, ledger_relative), ledger_text)
        artifact_hashes[ledger_relative] = _sha256_text(ledger_text)
        choice_relative = joinpath("local_data", "proposal_computation", "$prefix-choices.toml")
        choice_payload = Dict{String,Any}(
            "schema_version" => "financial-strategy-library-panel-v3-proposal-cell-choices-v1",
            "cell_index" => index,
            "origin_id" => origin_id,
            "universe_id" => universe_id,
            "status" => "PROPOSAL_CHOICES_FROZEN",
            "proposal_year" => proposal_year,
            "proposal_session_count" => length(computed.proposal_dates),
            "proposal_reference_calendar_sha256" =>
                _sha256_text(join(computed.proposal_dates, '\n')),
            "primary_cost_bps" => 5,
            "primary_risk_aversion" => 3,
            "adoption_hurdle" => HURDLE,
            "bootstrap_repetitions" => 5_000,
            "moving_block_sessions" => 20,
            "familywise_alpha" => 0.10,
            "choices" => [
                _choice_payload(computed.choices[policy]) for policy in (
                    "frontier_only_robust_policy",
                    "innovation_safe_robust_policy",
                    "innovation_safe_forced_max",
                    "equal_weight_available_policy",
                    "source_uncompressed_robust_policy",
                )
            ],
            "inferences" => [
                _inference_payload(policy, computed.inferences[policy]) for policy in (
                    "frontier_only_robust_policy",
                    "innovation_safe_robust_policy",
                    "source_uncompressed_robust_policy",
                )
            ],
            "proposal_return_values_included" => true,
            "evaluation_values_inspected_materialized_or_used" => 0,
        )
        choice_text = _toml_text(choice_payload)
        _write_new_or_identical(joinpath(EXPERIMENT_ROOT, choice_relative), choice_text)
        artifact_hashes[choice_relative] = _sha256_text(choice_text)
        local_summary["selected_choices"] = choice_payload["choices"]
        local_summary["proposal_path_parquet_bytes"] = path_bytes
        local_summary["complete_source_candidate_count"] =
            count(value -> value.complete, values(path_stats))
        forced_max_available = !isempty(
            computed.choices["innovation_safe_forced_max"].selected_strategy_ids,
        )
        status = "PROPOSAL_CHOICES_FROZEN"
    end
    public = Dict{String,Any}(
        "cell_index" => index,
        "origin_id" => origin_id,
        "universe_id" => universe_id,
        "role" => String(stage_cell["role"]),
        "universe_gate_passed" => Bool(stage_cell["universe_gate_passed"]),
        "status" => status,
        "registered_policy_count" => 5,
        "proposal_trial_ledger_rows" => length(rows),
        "choices_frozen" => status == "PROPOSAL_CHOICES_FROZEN",
        "forced_max_available" => forced_max_available,
        "local_artifact_count" => length(artifact_hashes),
        "local_artifact_aggregate_sha256" => _aggregate(artifact_hashes),
        "return_values_included" => false,
        "selected_strategy_identities_included" => false,
        "evaluation_values_inspected_materialized_or_used" => 0,
    )
    local_result = copy(public)
    local_result["local_artifact_sha256"] = artifact_hashes
    local_result["return_values_included"] = Bool(stage_cell["universe_gate_passed"])
    local_result["selected_strategy_identities_included"] = Bool(stage_cell["universe_gate_passed"])
    merge!(local_result, local_summary)
    println(stderr, "v3 proposal computation completed cell $index/38 $origin_id $universe_id")
    return (; public, local_result)
end

function run_proposal_computation()
    contract = _load_contract()
    public_stage = _cell_map(contract.public_stage)
    local_stage = _cell_map(contract.local_stage)
    predecision = _cell_map(contract.predecision)
    result_seal = TOML.parsefile(PREDECISION_RESULT_SEAL_PATH)
    for cells in (public_stage, local_stage, predecision)
        sort!(collect(keys(cells))) == collect(1:38) || error("proposal denominator changed")
    end
    results = Vector{Any}(undef, 38)
    Threads.@threads :static for index in 1:38
        public_stage[index]["origin_id"] == local_stage[index]["origin_id"] ||
            error("proposal-stage manifests disagree")
        results[index] = _cell_computation(
            index,
            local_stage[index],
            predecision[index],
            result_seal,
        )
    end
    public_cells = [results[index].public for index in 1:38]
    local_cells = [results[index].local_result for index in 1:38]
    total_rows = sum(Int(cell["proposal_trial_ledger_rows"]) for cell in public_cells)
    total_rows == 18_430 || error("complete proposal trial-ledger denominator changed")
    common = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-computation-manifest-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "PROPOSAL_POLICY_CHOICES_FROZEN",
        "language" => "Julia",
        "cell_count" => 38,
        "choice_frozen_cell_count" => 37,
        "failed_universe_cells_retained" => 1,
        "forced_max_unavailable_gate_passed_cells" =>
            count(cell -> cell["universe_gate_passed"] && !cell["forced_max_available"], public_cells),
        "registered_policy_count" => 5,
        "proposal_trial_ledger_rows" => total_rows,
        "bootstrap_repetitions" => 5_000,
        "moving_block_sessions" => 20,
        "familywise_alpha" => 0.10,
        "family_shrinkage_applied" => true,
        "comparator_cash_gate_applied" => true,
        "safe_no_harm_gate_applied" => true,
        "proposal_execution_lock_sha256" => _sha256_file(EXECUTION_LOCK_PATH),
        "predecision_computation_result_seal_sha256" =>
            _sha256_file(PREDECISION_RESULT_SEAL_PATH),
        "public_proposal_stage_manifest_sha256" => _sha256_file(PUBLIC_STAGE_MANIFEST_PATH),
        "local_proposal_stage_manifest_sha256" => _sha256_file(LOCAL_STAGE_MANIFEST_PATH),
        "evaluation_values_inspected" => 0,
        "evaluation_values_materialized" => 0,
        "evaluation_values_used" => 0,
    )
    public_payload = copy(common)
    public_payload["return_values_included"] = false
    public_payload["selected_strategy_identities_included"] = false
    public_payload["public_promotion_permitted"] = true
    public_payload["cells"] = public_cells
    public_text = _toml_text(public_payload)
    _write_new_or_identical(PUBLIC_RESULT_MANIFEST_PATH, public_text)
    local_payload = copy(common)
    local_payload["return_values_included"] = true
    local_payload["selected_strategy_identities_included"] = true
    local_payload["public_promotion_permitted"] = false
    local_payload["public_manifest_sha256"] = _sha256_text(public_text)
    local_payload["cells"] = local_cells
    local_text = _toml_text(local_payload)
    _write_new_or_identical(LOCAL_RESULT_MANIFEST_PATH, local_text)
    println("V3_PROPOSAL_COMPUTATION_PASSED")
    println("proposal choices frozen: 37/38 cells x 5 policies")
    println("complete proposal trial-ledger rows: $total_rows")
    println("evaluation values inspected/materialized/used: 0")
    return public_payload
end

function audit_proposal_computation()
    _load_contract()
    for path in (PUBLIC_RESULT_MANIFEST_PATH, LOCAL_RESULT_MANIFEST_PATH)
        isfile(path) || error("proposal computation result manifest is absent")
    end
    public = TOML.parsefile(PUBLIC_RESULT_MANIFEST_PATH)
    local_manifest = TOML.parsefile(LOCAL_RESULT_MANIFEST_PATH)
    public["status"] == "PROPOSAL_POLICY_CHOICES_FROZEN" ||
        error("unexpected proposal computation status")
    public["return_values_included"] === false || error("public proposal manifest contains returns")
    public["selected_strategy_identities_included"] === false ||
        error("public proposal manifest contains selected identities")
    public["proposal_trial_ledger_rows"] == 18_430 || error("proposal ledger denominator changed")
    public["evaluation_values_inspected"] == 0 || error("evaluation values were inspected")
    public["evaluation_values_materialized"] == 0 || error("evaluation values were materialized")
    public["evaluation_values_used"] == 0 || error("evaluation values were used")
    local_manifest["public_manifest_sha256"] == _sha256_file(PUBLIC_RESULT_MANIFEST_PATH) ||
        error("proposal result manifests are not bound")
    cells = _cell_map(local_manifest)
    for index in 1:38
        hashes = Dict{String,String}(cells[index]["local_artifact_sha256"])
        _aggregate(hashes) == cells[index]["local_artifact_aggregate_sha256"] ||
            error("proposal cell $index artifact aggregate changed")
        for (relative, digest) in hashes
            _sha256_file(joinpath(EXPERIMENT_ROOT, relative)) == digest ||
                error("proposal computation artifact changed: $relative")
        end
    end
    println("V3_PROPOSAL_COMPUTATION_AUDIT_PASSED")
    println("proposal trial-ledger rows: 18430")
    println("evaluation values inspected/materialized/used: 0")
    return public
end

function main(args = ARGS)
    length(args) == 1 || error("use exactly one of --run or --audit-only")
    args[1] == "--run" && return run_proposal_computation()
    args[1] == "--audit-only" && return audit_proposal_computation()
    error("unknown argument: $(args[1])")
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    RunFinancialStrategyLibraryPanelV3Proposal.main()
end
