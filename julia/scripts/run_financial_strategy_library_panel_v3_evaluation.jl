module RunFinancialStrategyLibraryPanelV3Evaluation

using Parquet
using SHA: sha256
using Tables
using TOML

include(joinpath(@__DIR__, "stage_financial_strategy_library_panel_v3_evaluation_returns.jl"))
const Stage = StageFinancialStrategyLibraryPanelV3EvaluationReturns
const Core = Stage.FinancialStrategyLibraryPanelV3Evaluation
const LedgerCore = Core.FinancialStrategyLibraryPanelV3PredecisionComputation

export audit_evaluation, run_evaluation, table_to_security_panel

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const EXECUTION_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EVALUATION_EXECUTION_LOCK.toml")
const PROPOSAL_RESULT_SEAL_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_RESULT_SEAL.toml")
const PROPOSAL_ROBUSTNESS_RESULT_SEAL_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_ROBUSTNESS_RESULT_SEAL.toml")
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
const PUBLIC_STAGE_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "evaluation_stage",
    "EVALUATION_STAGE_MANIFEST.toml",
)
const LOCAL_STAGE_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "evaluation",
    "EVALUATION_STAGE_LOCAL_MANIFEST.toml",
)
const PUBLIC_RESULT_ROOT = joinpath(EXPERIMENT_ROOT, "evaluation_results")
const PUBLIC_RESULT_MANIFEST_PATH =
    joinpath(PUBLIC_RESULT_ROOT, "EVALUATION_RESULT_MANIFEST.toml")
const LOCAL_RESULT_ROOT = joinpath(EXPERIMENT_ROOT, "local_data", "evaluation_results")
const LOCAL_RESULT_MANIFEST_PATH =
    joinpath(LOCAL_RESULT_ROOT, "EVALUATION_RESULT_LOCAL_MANIFEST.toml")

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
            error("refusing to replace a nonidentical evaluation result")
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

function _csv_rows(path)
    lines = filter(!isempty, strip.(readlines(path)))
    isempty(lines) && error("trial ledger is empty")
    header = split(first(lines), ',')
    header == collect(LedgerCore.TRIAL_LEDGER_FIELDS) ||
        error("trial ledger schema changed")
    rows = Dict{String,Any}[]
    for line in Iterators.drop(lines, 1)
        fields = split(line, ','; keepempty = true)
        length(fields) == length(header) ||
            error("trial ledger row width changed")
        row = Dict{String,Any}(String(key) => String(value) for (key, value) in zip(header, fields))
        for field in ("proposal_observation_count", "evaluation_observation_count")
            row[field] = parse(Int, row[field])
        end
        for field in ("generatable", "policy_eligible", "policy_selected")
            lowercase(row[field]) in ("true", "false") ||
                error("trial ledger Boolean changed")
            row[field] = lowercase(row[field]) == "true"
        end
        push!(rows, row)
    end
    return rows
end

"Convert a security-contiguous combined table into dates-by-securities panels."
function table_to_security_panel(table)
    columns = Tables.columntable(table)
    permno = Int64.(collect(skipmissing(columns.permno)))
    dates = String.(collect(skipmissing(columns.date)))
    returns = Union{Missing,Float64}[columns.total_return...]
    available = Bool.(collect(skipmissing(columns.return_available)))
    terminal = Bool.(collect(skipmissing(columns.terminal_delisting)))
    close = Union{Missing,Float64}[columns.close...]
    volume = Union{Missing,Float64}[columns.volume...]
    length(permno) == length(dates) == length(returns) == length(available) ==
        length(terminal) == length(close) == length(volume) ||
        error("combined evaluation columns do not align")
    identifiers = sort!(unique(permno))
    isempty(identifiers) && error("combined evaluation table has no securities")
    sessions = length(permno) ÷ length(identifiers)
    sessions * length(identifiers) == length(permno) ||
        error("combined evaluation table is not rectangular")
    calendar = String[]
    return_matrix = Matrix{Union{Missing,Float64}}(missing, sessions, length(identifiers))
    available_matrix = falses(sessions, length(identifiers))
    terminal_matrix = falses(sessions, length(identifiers))
    close_matrix = Matrix{Union{Missing,Float64}}(missing, sessions, length(identifiers))
    volume_matrix = Matrix{Union{Missing,Float64}}(missing, sessions, length(identifiers))
    for (security_index, identifier) in enumerate(identifiers)
        rows = ((security_index - 1) * sessions + 1):(security_index * sessions)
        all(==(identifier), @view permno[rows]) ||
            error("combined evaluation security rows are not contiguous")
        security_calendar = dates[rows]
        if security_index == 1
            calendar = copy(security_calendar)
            issorted(calendar) && allunique(calendar) ||
                error("combined evaluation calendar is not canonical")
        else
            security_calendar == calendar ||
                error("combined evaluation security calendars differ")
        end
        return_matrix[:, security_index] .= returns[rows]
        available_matrix[:, security_index] .= available[rows]
        terminal_matrix[:, security_index] .= terminal[rows]
        close_matrix[:, security_index] .= close[rows]
        volume_matrix[:, security_index] .= volume[rows]
    end
    return (;
        security_ids = identifiers,
        dates = calendar,
        security_returns = return_matrix,
        return_available = available_matrix,
        terminal_delisting = terminal_matrix,
        close = close_matrix,
        volume = volume_matrix,
    )
end

function _load_contract()
    # The stage verifier performs the proposal-seal, access-lock, and transitive
    # sealed-file checks before this runner can read any staged outcome.
    stage_contract = Stage._load_contract()
    for path in (PUBLIC_STAGE_MANIFEST_PATH, LOCAL_STAGE_MANIFEST_PATH)
        isfile(path) || error("evaluation stage manifest is absent")
    end
    public_stage = TOML.parsefile(PUBLIC_STAGE_MANIFEST_PATH)
    local_stage = TOML.parsefile(LOCAL_STAGE_MANIFEST_PATH)
    public_stage["status"] == "EVALUATION_RETURNS_STAGED_FOR_FROZEN_CHOICES" ||
        error("evaluation returns are not staged")
    public_stage["evaluation_scope"] == "all five frozen registered policies; primary headline fixed" ||
        error("evaluation stage scope changed")
    public_stage["return_values_included"] === false ||
        error("public evaluation-stage manifest contains returns")
    local_stage["public_manifest_sha256"] == _sha256_file(PUBLIC_STAGE_MANIFEST_PATH) ||
        error("evaluation stage public/local manifests are not bound")
    local_stage["evaluation_execution_lock_sha256"] == _sha256_file(EXECUTION_LOCK_PATH) ||
        error("evaluation stage is not bound to its execution lock")
    local_stage["proposal_policy_result_seal_sha256"] ==
        _sha256_file(PROPOSAL_RESULT_SEAL_PATH) ||
        error("evaluation stage is not bound to the proposal result seal")
    local_stage["proposal_robustness_result_seal_sha256"] ==
        _sha256_file(PROPOSAL_ROBUSTNESS_RESULT_SEAL_PATH) ||
        error("evaluation stage is not bound to the proposal robustness result seal")
    for (relative, digest) in Dict{String,String}(local_stage["local_artifact_sha256"])
        path = joinpath(EXPERIMENT_ROOT, relative)
        isfile(path) || error("evaluation stage artifact is absent: $relative")
        _sha256_file(path) == digest || error("evaluation stage artifact changed: $relative")
    end
    return (;
        stage_contract,
        public_stage,
        local_stage,
        proposal = TOML.parsefile(PROPOSAL_RESULT_MANIFEST_PATH),
        local_proposal = TOML.parsefile(LOCAL_PROPOSAL_RESULT_MANIFEST_PATH),
        proposal_robustness = stage_contract.proposal_robustness,
        local_proposal_robustness = stage_contract.local_proposal_robustness,
        selections = stage_contract.selections,
    )
end

function _cell_maps(contract)
    proposal = Dict(Int(cell["cell_index"]) => cell for cell in contract.proposal["cells"])
    local_proposal = Dict(Int(cell["cell_index"]) => cell for cell in contract.local_proposal["cells"])
    stage = Dict(Int(cell["cell_index"]) => cell for cell in contract.local_stage["cells"])
    proposal_robustness = Dict(
        Int(cell["cell_index"]) => cell for cell in contract.proposal_robustness["cells"]
    )
    local_proposal_robustness = Dict(
        Int(cell["cell_index"]) => cell for cell in contract.local_proposal_robustness["cells"]
    )
    selections = Dict(
        (String(cell["origin_id"]), String(cell["universe_id"])) => cell for
        cell in contract.selections["cells"]
    )
    sort!(collect(keys(proposal))) == collect(1:38) ||
        error("proposal result cell denominator changed")
    sort!(collect(keys(local_proposal))) == collect(1:38) ||
        error("local proposal result cell denominator changed")
    sort!(collect(keys(stage))) == collect(1:38) ||
        error("evaluation stage cell denominator changed")
    sort!(collect(keys(proposal_robustness))) == collect(1:38) ||
        error("proposal robustness cell denominator changed")
    sort!(collect(keys(local_proposal_robustness))) == collect(1:38) ||
        error("local proposal robustness cell denominator changed")
    return (;
        proposal,
        local_proposal,
        stage,
        proposal_robustness,
        local_proposal_robustness,
        selections,
    )
end

function _choices(cell)
    return Stage._registered_choices(cell)
end

function _robustness_choice(origin_id, universe_id, record)
    return Core.FrozenEvaluationChoice(
        origin_id,
        universe_id,
        record["policy_id"],
        String.(collect(record["strategy_ids"])),
    )
end

function _robustness_specs(local_manifest_cell)
    relative = String(local_manifest_cell["local_artifact_relative_path"])
    path = joinpath(EXPERIMENT_ROOT, relative)
    _sha256_file(path) == String(local_manifest_cell["local_artifact_sha256"]) ||
        error("proposal robustness artifact changed")
    artifact = TOML.parsefile(path)
    origin_id = String(artifact["origin_id"])
    universe_id = String(artifact["universe_id"])
    grid = Core.FrozenRobustnessSpec[]
    for record in artifact["grid_records"]
        haskey(record, "failure_code") &&
            String(record["failure_code"]) == "UNIVERSE_GATE_FAILED" && continue
        push!(grid, Core.FrozenRobustnessSpec(
            record["spec_id"],
            "cost_risk_hurdle_grid",
            0,
            record["cost_bps"],
            record["risk_aversion"],
            record["adoption_hurdle"],
            _robustness_choice(origin_id, universe_id, record["comparator_choice"]),
            _robustness_choice(origin_id, universe_id, record["safe_choice"]),
        ))
    end
    caps = Dict{Int,Core.FrozenRobustnessSpec}()
    for record in artifact["common_equity_cap_records"]
        Bool(record["available"]) || continue
        cap = Int(record["liquidity_cap"])
        caps[cap] = Core.FrozenRobustnessSpec(
            "common_equity_cap$(cap)",
            "common_equity_liquidity_cap",
            cap,
            record["cost_bps"],
            record["risk_aversion"],
            record["adoption_hurdle"],
            _robustness_choice(origin_id, universe_id, record["comparator_choice"]),
            _robustness_choice(origin_id, universe_id, record["safe_choice"]),
        )
    end
    return (; grid, caps)
end

function _cell_outcomes(proposal, local_proposal, local_robustness, selection, stage)
    choices = _choices(local_proposal)
    gate = Bool(proposal["universe_gate_passed"])
    gate || return (
        Core.EvaluationOutcome[],
        Core.PolicyEvaluationOutcome[],
        nothing,
        Core.CapacityOutcome[],
        Core.RobustnessEvaluationOutcome[],
        Core.OriginEvaluationContrast(
            String(proposal["origin_id"]),
            String(proposal["universe_id"]),
            false,
            "",
            "",
            missing,
            missing,
            missing,
            missing,
            false,
            "UNIVERSE_GATE_FAILED",
        ),
    )
    relative = String(stage["local_artifact_relative_path"])
    path = joinpath(EXPERIMENT_ROOT, relative)
    _sha256_file(path) == String(stage["local_artifact_sha256"]) ||
        error("combined evaluation artifact changed")
    panel = table_to_security_panel(Parquet.Table(path; use_threads = false))
    result = Core.evaluate_frozen_choices(
        proposal["origin_id"],
        proposal["universe_id"],
        panel.security_returns,
        panel.return_available,
        panel.terminal_delisting,
        panel.dates,
        Int(proposal["evaluation_year"]),
        choices;
        security_weight_cap = Float64(proposal["security_weight_cap"]),
        portfolio_volatility_target = 0.10,
        decision_to_first_return_lag_sessions = 2,
        cost_bps = 5.0,
        risk_aversion = 3.0,
        compute_full_search = true,
    )
    frozen_robustness = _robustness_specs(local_robustness)
    length(frozen_robustness.grid) == 24 ||
        error("gate-passed robustness cell does not have 24 specs")
    grid_evaluation = Core.evaluate_frozen_robustness_specs(
        proposal["origin_id"],
        proposal["universe_id"],
        panel.security_returns,
        panel.return_available,
        panel.terminal_delisting,
        panel.dates,
        Int(proposal["evaluation_year"]),
        frozen_robustness.grid;
        security_weight_cap = Float64(proposal["security_weight_cap"]),
        strategy_path_cache = result.strategy_path_cache,
        evaluated_liquidity_cap = 0,
    )
    robustness_outcomes = copy(grid_evaluation.outcomes)
    if haskey(frozen_robustness.caps, 100)
        size(panel.security_returns, 2) == 100 ||
            error("sealed cap100 panel does not contain 100 securities")
        cap100_evaluation = Core.evaluate_frozen_robustness_specs(
            proposal["origin_id"],
            proposal["universe_id"],
            panel.security_returns,
            panel.return_available,
            panel.terminal_delisting,
            panel.dates,
            Int(proposal["evaluation_year"]),
            [frozen_robustness.caps[100]];
            security_weight_cap = Float64(proposal["security_weight_cap"]),
            strategy_path_cache = result.strategy_path_cache,
            evaluated_liquidity_cap = 100,
        )
        append!(robustness_outcomes, cap100_evaluation.outcomes)
    end
    if haskey(frozen_robustness.caps, 50)
        ranked = sort!(collect(selection["selected"]); by = row -> Int(row["rank"]))
        length(ranked) == 100 || error("sealed top100 membership changed")
        panel_lookup = Dict(identifier => index for (index, identifier) in
            enumerate(panel.security_ids))
        cap50_identifiers = Int.(getindex.(ranked[1:50], "permno"))
        all(haskey(panel_lookup, identifier) for identifier in cap50_identifiers) ||
            error("sealed cap50 membership is absent from the combined panel")
        columns = [panel_lookup[identifier] for identifier in cap50_identifiers]
        cap50_evaluation = Core.evaluate_frozen_robustness_specs(
            proposal["origin_id"],
            proposal["universe_id"],
            panel.security_returns[:, columns],
            panel.return_available[:, columns],
            panel.terminal_delisting[:, columns],
            panel.dates,
            Int(proposal["evaluation_year"]),
            [frozen_robustness.caps[50]];
            security_weight_cap = Float64(proposal["security_weight_cap"]),
            strategy_path_cache = Dict{String,Any}(),
            evaluated_liquidity_cap = 50,
        )
        append!(robustness_outcomes, cap50_evaluation.outcomes)
    end
    capacity_outcomes = Core.capacity_policy_grid(
        proposal["origin_id"],
        proposal["universe_id"],
        result.policy_effective_weights,
        panel.security_returns,
        panel.return_available,
        panel.close,
        panel.volume,
        panel.dates,
        Int(proposal["evaluation_year"]),
    )
    return result.outcomes,
           result.policy_outcomes,
           result.full_search_diagnostics,
           capacity_outcomes,
           robustness_outcomes,
           Core.origin_evaluation_contrast(result.policy_outcomes)
end

function _public_outcome(outcome; choice_sha256 = "")
    value(field) = ismissing(getfield(outcome, field)) ? "" : getfield(outcome, field)
    return Dict{String,Any}(
        "policy_id" => outcome.policy_id,
        "available" => true,
        "choice_sha256" => isempty(String(choice_sha256)) ? _sha256_text(
            join([outcome.policy_id; outcome.choice_ids], '\0'),
        ) : String(choice_sha256),
        "selected_strategy_count" => length(outcome.choice_ids),
        "complete" => outcome.complete,
        "evaluation_observation_count" => outcome.observation_count,
        "evaluation_ce" => value(:certainty_equivalent),
        "evaluation_mean_component" => value(:annual_mean_component),
        "evaluation_variance_penalty" => value(:annual_variance_penalty),
        "evaluation_turnover_cost" => value(:annual_turnover_cost),
        "failure_code" => outcome.failure_code,
    )
end

function _public_policy_outcomes(proposal_cell, outcomes)
    lookup = Dict(outcome.policy_id => outcome for outcome in outcomes)
    records = Dict{String,Any}[]
    proposal_lookup = Dict(
        String(choice["policy_id"]) => choice for choice in proposal_cell["primary_choices"]
    )
    Set(keys(proposal_lookup)) == Set(Stage.POLICY_IDS) ||
        error("proposal cell omitted a registered policy")
    for policy_id in Stage.POLICY_IDS
        sealed = proposal_lookup[policy_id]
        if Bool(sealed["available"])
            haskey(lookup, policy_id) || error("available registered policy was not evaluated")
            push!(records, _public_outcome(
                lookup[policy_id]; choice_sha256 = sealed["choice_sha256"],
            ))
        else
            push!(records, Dict{String,Any}(
                "policy_id" => policy_id,
                "available" => false,
                "choice_sha256" => String(sealed["choice_sha256"]),
                "selected_strategy_count" => 0,
                "complete" => false,
                "evaluation_observation_count" => 0,
                "evaluation_ce" => "",
                "evaluation_mean_component" => "",
                "evaluation_variance_penalty" => "",
                "evaluation_turnover_cost" => "",
                "failure_code" => String(sealed["failure_code"]),
                "realized_regret_upper_bound" => "",
            ))
        end
    end
    return records
end

function _public_full_search(diagnostic)
    value(item) = ismissing(item) ? "" : item
    return Dict{String,Any}(
        "candidate_count" => length(diagnostic.candidate_ids),
        "complete_candidate_count" => length(diagnostic.complete_candidate_ids),
        "incomplete_candidate_count" => length(diagnostic.candidate_ids) -
            length(diagnostic.complete_candidate_ids),
        "white_reality_check_p_value" => value(diagnostic.white_reality_check_p_value),
        "hansen_spa_p_value" => value(diagnostic.hansen_spa_p_value),
        "pbo_cscv" => value(diagnostic.pbo_cscv),
        "cscv_split_count" => diagnostic.cscv_split_count,
        "deflated_sharpe_probability" => value(diagnostic.deflated_sharpe_probability),
        "deflated_sharpe_expected_maximum" =>
            value(diagnostic.deflated_sharpe_expected_maximum),
        "deflated_sharpe_best_candidate_sha256" =>
            isempty(diagnostic.deflated_sharpe_best_candidate_id) ? "" :
            _sha256_text(diagnostic.deflated_sharpe_best_candidate_id),
        "best_candidate_sha256" => isempty(diagnostic.best_candidate_id) ? "" :
            _sha256_text(diagnostic.best_candidate_id),
        "best_candidate_ce" => value(diagnostic.best_candidate_ce),
        "bootstrap_repetitions" => diagnostic.bootstrap_repetitions,
        "moving_block_sessions" => diagnostic.moving_block_sessions,
        "reality_check_seed" => diagnostic.reality_check_seed,
        "hansen_spa_seed" => diagnostic.hansen_spa_seed,
        "pbo_cscv_seed" => diagnostic.pbo_cscv_seed,
    )
end

function _public_capacity(outcome)
    value(field) = ismissing(getfield(outcome, field)) ? "" : getfield(outcome, field)
    return Dict{String,Any}(
        "policy_id" => outcome.policy_id,
        "aum" => outcome.aum,
        "half_spread_bps" => outcome.half_spread_bps,
        "impact_coefficient" => outcome.impact_coefficient,
        "adv_fraction_cap" => outcome.adv_fraction_cap,
        "seed" => outcome.seed,
        "complete" => outcome.complete,
        "evaluation_observation_count" => outcome.observation_count,
        "capacity_ce" => value(:certainty_equivalent),
        "capacity_mean_component" => value(:annual_mean_component),
        "capacity_variance_penalty" => value(:annual_variance_penalty),
        "capacity_execution_cost" => value(:annual_execution_cost),
        "maximum_adv_fraction" => value(:maximum_adv_fraction),
        "failure_code" => outcome.failure_code,
    )
end

function _public_robustness_policy(outcome, choice_sha256)
    value(field) = ismissing(getfield(outcome, field)) ? "" : getfield(outcome, field)
    return Dict{String,Any}(
        "policy_id" => outcome.policy_id,
        "choice_sha256" => String(choice_sha256),
        "complete" => outcome.complete,
        "evaluation_observation_count" => outcome.observation_count,
        "evaluation_ce" => value(:certainty_equivalent),
        "evaluation_mean_component" => value(:annual_mean_component),
        "evaluation_variance_penalty" => value(:annual_variance_penalty),
        "evaluation_turnover_cost" => value(:annual_turnover_cost),
        "failure_code" => outcome.failure_code,
    )
end

function _public_robustness_contrast(contrast, comparator_hash, safe_hash)
    value(field) = ismissing(getfield(contrast, field)) ? "" : getfield(contrast, field)
    return Dict{String,Any}(
        "origin_id" => contrast.origin_id,
        "universe_id" => contrast.universe_id,
        "complete" => contrast.complete,
        "comparator_choice_sha256" => String(comparator_hash),
        "safe_choice_sha256" => String(safe_hash),
        "certainty_equivalent_difference" => value(:certainty_equivalent_difference),
        "mean_component_difference" => value(:mean_component_difference),
        "variance_penalty_difference" => value(:variance_penalty_difference),
        "turnover_cost_difference" => value(:turnover_cost_difference),
        "same_choice" => contrast.same_choice,
        "failure_code" => contrast.failure_code,
    )
end

function _public_robustness(public_cell, outcomes)
    lookup = Dict(outcome.context_id => outcome for outcome in outcomes)
    grid_records = Dict{String,Any}[]
    for sealed in public_cell["grid_records"]
        spec_id = String(sealed["spec_id"])
        record = Dict{String,Any}(
            "spec_id" => spec_id,
            "cost_bps" => Float64(sealed["cost_bps"]),
            "risk_aversion" => Float64(sealed["risk_aversion"]),
            "adoption_hurdle" => Float64(sealed["adoption_hurdle"]),
            "available" => Bool(sealed["available"]),
            "same_choice" => Bool(sealed["same_choice"]),
            "comparator_choice_sha256" => String(sealed["comparator_choice_sha256"]),
            "safe_choice_sha256" => String(sealed["safe_choice_sha256"]),
        )
        if Bool(sealed["available"])
            haskey(lookup, spec_id) || error("frozen robustness spec was not evaluated")
            outcome = lookup[spec_id]
            record["comparator"] = _public_robustness_policy(
                outcome.comparator, sealed["comparator_choice_sha256"],
            )
            record["safe"] = _public_robustness_policy(
                outcome.safe, sealed["safe_choice_sha256"],
            )
            record["contrast"] = _public_robustness_contrast(
                outcome.contrast,
                sealed["comparator_choice_sha256"],
                sealed["safe_choice_sha256"],
            )
        else
            record["failure_code"] = String(sealed["failure_code"])
        end
        push!(grid_records, record)
    end
    cap_records = Dict{String,Any}[]
    for sealed in public_cell["common_equity_cap_records"]
        cap = Int(sealed["liquidity_cap"])
        context = "common_equity_cap$(cap)"
        record = Dict{String,Any}(
            "liquidity_cap" => cap,
            "available" => Bool(sealed["available"]),
        )
        if Bool(sealed["available"])
            haskey(lookup, context) || error("frozen liquidity-cap spec was not evaluated")
            outcome = lookup[context]
            record["membership_source"] = String(sealed["membership_source"])
            record["same_choice"] = Bool(sealed["same_choice"])
            record["comparator_choice_sha256"] =
                String(sealed["comparator_choice_sha256"])
            record["safe_choice_sha256"] = String(sealed["safe_choice_sha256"])
            record["comparator"] = _public_robustness_policy(
                outcome.comparator, sealed["comparator_choice_sha256"],
            )
            record["safe"] = _public_robustness_policy(
                outcome.safe, sealed["safe_choice_sha256"],
            )
            record["contrast"] = _public_robustness_contrast(
                outcome.contrast,
                sealed["comparator_choice_sha256"],
                sealed["safe_choice_sha256"],
            )
        else
            record["failure_code"] = String(sealed["failure_code"])
        end
        push!(cap_records, record)
    end
    return Dict{String,Any}(
        "grid_spec_count" => length(grid_records),
        "grid_policy_choice_count" => 2 * length(grid_records),
        "grid_records" => grid_records,
        "common_equity_cap_records" => cap_records,
        "permuted_closure_sham" => Dict{String,Any}(
            "available" => Bool(public_cell["permuted_closure_sham_available"]),
            "failure_code" =>
                String(public_cell["permuted_closure_sham_failure_code"]),
        ),
    )
end

function _public_contrast(contrast; safe_choice_sha256 = "", comparator_choice_sha256 = "")
    value(field) = ismissing(getfield(contrast, field)) ? "" : getfield(contrast, field)
    return Dict{String,Any}(
        "origin_id" => contrast.origin_id,
        "universe_id" => contrast.universe_id,
        "complete" => contrast.complete,
        "safe_choice_sha256" => String(safe_choice_sha256),
        "comparator_choice_sha256" => String(comparator_choice_sha256),
        "certainty_equivalent_difference" => value(:certainty_equivalent_difference),
        "mean_component_difference" => value(:mean_component_difference),
        "variance_penalty_difference" => value(:variance_penalty_difference),
        "turnover_cost_difference" => value(:turnover_cost_difference),
        "same_choice" => contrast.same_choice,
        "failure_code" => contrast.failure_code,
    )
end

function _primary_choice_hashes(proposal_cell)
    lookup = Dict(
        String(choice["policy_id"]) => choice for choice in proposal_cell["primary_choices"]
    )
    return (;
        safe = String(lookup["innovation_safe_robust_policy"]["choice_sha256"]),
        comparator = String(lookup["frontier_only_robust_policy"]["choice_sha256"]),
    )
end

function run_evaluation(; check = false)
    contract = _load_contract()
    maps = _cell_maps(contract)
    results = Vector{Any}(undef, 38)
    for index in 1:38
        proposal = maps.proposal[index]
        local_proposal = maps.local_proposal[index]
        proposal_robustness = maps.proposal_robustness[index]
        local_robustness = maps.local_proposal_robustness[index]
        selection = maps.selections[(
            String(proposal["origin_id"]), String(proposal["universe_id"]),
        )]
        stage = maps.stage[index]
        strategy_outcomes, policy_outcomes, full_search, capacity_outcomes,
            robustness_outcomes, contrast = _cell_outcomes(
                proposal, local_proposal, local_robustness, selection, stage,
            )
        ledger_relative = String(local_proposal["proposal_trial_ledger_relative_path"])
        ledger_path = joinpath(EXPERIMENT_ROOT, ledger_relative)
        _sha256_file(ledger_path) == String(local_proposal["proposal_trial_ledger_sha256"]) ||
            error("proposal trial ledger changed for cell $index")
        ledger = _csv_rows(ledger_path)
        length(ledger) == 485 || error("cell $index trial-ledger denominator changed")
        candidate_outcomes = isnothing(full_search) ? Core.EvaluationOutcome[] :
            full_search.candidate_outcomes
        updated = Core.update_trial_ledger(
            ledger,
            strategy_outcomes;
            full_search_candidate_outcomes = candidate_outcomes,
        )
        ledger_text = LedgerCore.render_trial_ledger_csv(updated)
        output_relative = joinpath(
            "local_data",
            "evaluation_results",
            "cell-$(lpad(index, 3, '0'))-trial-ledger.csv",
        )
        output_path = joinpath(EXPERIMENT_ROOT, output_relative)
        if check
            isfile(output_path) || error("evaluation result ledger is absent for cell $index")
            read(output_path, String) == ledger_text ||
                error("evaluation result ledger changed for cell $index")
        else
            _write_new_or_identical(output_path, ledger_text)
        end
        public_policy_outcomes = _public_policy_outcomes(proposal, policy_outcomes)
        if !isnothing(full_search) && !ismissing(full_search.best_candidate_ce)
            outcome_lookup = Dict(outcome.policy_id => outcome for outcome in policy_outcomes)
            for public_outcome in public_policy_outcomes
                Bool(public_outcome["available"]) || continue
                outcome = outcome_lookup[String(public_outcome["policy_id"])]
                public_outcome["realized_regret_upper_bound"] = outcome.complete ?
                    Float64(full_search.best_candidate_ce) -
                    Float64(outcome.certainty_equivalent) : ""
            end
        else
            for public_outcome in public_policy_outcomes
                public_outcome["realized_regret_upper_bound"] = ""
            end
        end
        results[index] = (;
            public = Dict{String,Any}(
                "cell_index" => index,
                "origin_id" => String(proposal["origin_id"]),
                "universe_id" => String(proposal["universe_id"]),
                "role" => String(proposal["role"]),
                "universe_status" => String(proposal["universe_status"]),
                "evaluation_year" => Int(proposal["evaluation_year"]),
                "available_registered_policy_count" => length(policy_outcomes),
                "registered_policy_row_count" => length(public_policy_outcomes),
                "evaluated_selected_trial_count" => length(strategy_outcomes),
                "policy_outcomes" => public_policy_outcomes,
                "full_search_diagnostics" => isnothing(full_search) ?
                    Dict{String,Any}(
                        "status" => "UNAVAILABLE_UNIVERSE_GATE_FAILED",
                    ) : _public_full_search(full_search),
                "capacity_outcomes" => _public_capacity.(capacity_outcomes),
                "robustness_sensitivities" => _public_robustness(
                    proposal_robustness, robustness_outcomes,
                ),
                "contrast" => let hashes = _primary_choice_hashes(proposal)
                    _public_contrast(
                        contrast;
                        safe_choice_sha256 = hashes.safe,
                        comparator_choice_sha256 = hashes.comparator,
                    )
                end,
                "trial_ledger_rows" => length(updated),
                "trial_id_aggregate_sha256" => _sha256_text(join(getindex.(updated, "trial_id"), '\n')),
                "evaluation_record_aggregate_sha256" => _sha256_text(join(getindex.(updated, "record_hash"), '\n')),
                "local_trial_ledger_relative_path" => output_relative,
                "local_trial_ledger_sha256" => _sha256_text(ledger_text),
                "return_values_included" => false,
                "licensed_identifiers_included" => false,
            ),
            contrast,
            policy_outcomes,
            full_search,
            capacity_outcomes,
            robustness_outcomes,
        )
    end
    contrasts = Core.OriginEvaluationContrast[result.contrast for result in results]
    sealed_primary_choice_hashes = Dict{Tuple{String,String},NamedTuple}()
    for index in 1:38
        proposal = maps.proposal[index]
        sealed_primary_choice_hashes[(
            String(proposal["origin_id"]), String(proposal["universe_id"]),
        )] = _primary_choice_hashes(proposal)
    end
    common_summary = Core.summarize_origin_contrasts(
        contrasts;
        universe_id = "liquid_common_equity",
        minimum_complete_origins = 15,
        sealed_choice_hashes = sealed_primary_choice_hashes,
    )
    etf_summary = Core.summarize_origin_contrasts(
        contrasts;
        universe_id = "liquid_plain_etf",
        minimum_complete_origins = 1,
        sealed_choice_hashes = sealed_primary_choice_hashes,
    )
    all_policy_outcomes = Core.PolicyEvaluationOutcome[
        outcome for result in results for outcome in result.policy_outcomes
    ]
    registered_policy_summaries = Dict{String,Any}()
    for policy_id in Stage.POLICY_IDS
        registered_policy_summaries[policy_id] = Dict(
            "common_equity" => Core.summarize_policy_outcomes(
                all_policy_outcomes;
                universe_id = "liquid_common_equity",
                policy_id,
            ),
            "etf_replication" => Core.summarize_policy_outcomes(
                all_policy_outcomes;
                universe_id = "liquid_plain_etf",
                policy_id,
            ),
        )
    end
    all_capacity_outcomes = Core.CapacityOutcome[
        outcome for result in results for outcome in result.capacity_outcomes
    ]
    capacity_appendix = Dict{String,Any}()
    for policy_id in Stage.POLICY_IDS
        policy_grid = Any[]
        for universe_id in ("liquid_common_equity", "liquid_plain_etf"),
            aum in Core.CAPACITY_AUM_LEVELS,
            spread in Core.CAPACITY_HALF_SPREAD_BPS,
            impact in Core.CAPACITY_IMPACT_COEFFICIENTS
            push!(policy_grid, Core.summarize_capacity_outcomes(
                all_capacity_outcomes;
                universe_id,
                policy_id,
                aum,
                half_spread_bps = spread,
                impact_coefficient = impact,
            ))
        end
        capacity_appendix[policy_id] = policy_grid
    end
    all_robustness_outcomes = Core.RobustnessEvaluationOutcome[
        outcome for result in results for outcome in result.robustness_outcomes
    ]
    robustness_grid_summaries = Dict{String,Any}[]
    registered_grid = maps.proposal_robustness[1]["grid_records"]
    length(registered_grid) == 24 || error("registered robustness grid changed")
    for record in registered_grid
        context_id = String(record["spec_id"])
        push!(robustness_grid_summaries, Dict{String,Any}(
            "spec_id" => context_id,
            "cost_bps" => Float64(record["cost_bps"]),
            "risk_aversion" => Float64(record["risk_aversion"]),
            "adoption_hurdle" => Float64(record["adoption_hurdle"]),
            "common_equity" => Core.summarize_robustness_outcomes(
                all_robustness_outcomes;
                universe_id = "liquid_common_equity",
                context_id,
            ),
            "etf_replication" => Core.summarize_robustness_outcomes(
                all_robustness_outcomes;
                universe_id = "liquid_plain_etf",
                context_id,
            ),
        ))
    end
    robustness_cap_summaries = Dict{String,Any}[]
    for cap in (50, 100)
        context_id = "common_equity_cap$(cap)"
        push!(robustness_cap_summaries, Core.summarize_robustness_outcomes(
            all_robustness_outcomes;
            universe_id = "liquid_common_equity",
            context_id,
        ))
    end
    proposal_differences = Float64[]
    evaluation_differences = Float64[]
    for index in 1:38
        proposal = maps.proposal[index]
        contrast = results[index].contrast
        proposal["universe_id"] == "liquid_common_equity" || continue
        contrast.complete || continue
        push!(proposal_differences, Float64(proposal["proposal_incremental_point_delta"]))
        push!(evaluation_differences, Float64(contrast.certainty_equivalent_difference))
    end
    calibration = Core.proposal_evaluation_calibration(
        proposal_differences,
        evaluation_differences,
    )
    public_payload = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-evaluation-result-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "HISTORICAL_EVALUATION_COMPLETE",
        "language" => "Julia",
        "historical_block_role" => "retrospective_development_facing",
        "cell_count" => 38,
        "trial_ledger_rows" => 38 * 485,
        "registered_policy_row_denominator" => 38 * 5,
        "primary_cost_bps" => 5,
        "primary_risk_aversion" => 3,
        "primary_contrast" => "innovation-safe minus frontier-only comparator",
        "common_equity_summary" => common_summary,
        "etf_replication_summary" => etf_summary,
        "leave_one_origin_out_primary_common_equity" =>
            Core.leave_one_origin_out_summary(
                contrasts; universe_id = "liquid_common_equity",
            ),
        "registered_policy_summaries" => registered_policy_summaries,
        "proposal_robustness_grid_cell_spec_denominator" => 912,
        "proposal_robustness_grid_policy_choice_denominator" => 1824,
        "proposal_robustness_available_grid_cell_specs" => 888,
        "proposal_robustness_available_grid_policy_choices" => 1776,
        "proposal_robustness_grid_summaries" => robustness_grid_summaries,
        "proposal_robustness_common_equity_cap_summaries" =>
            robustness_cap_summaries,
        "proposal_robustness_cap200_disposition" =>
            "DESIGN_NOT_FROZEN_BEFORE_PROPOSAL",
        "proposal_robustness_leave_one_origin_out_rule" =>
            "AGGREGATION_ONLY_NO_RESELECTION",
        "capacity_appendix" => capacity_appendix,
        "capacity_aum_levels" => collect(Core.CAPACITY_AUM_LEVELS),
        "capacity_half_spread_bps" => collect(Core.CAPACITY_HALF_SPREAD_BPS),
        "capacity_impact_coefficients" => collect(Core.CAPACITY_IMPACT_COEFFICIENTS),
        "capacity_adv_fraction_cap" => Core.CAPACITY_ADV_FRACTION_CAP,
        "capacity_lag_sessions" => Core.CAPACITY_LAG_SESSIONS,
        "capacity_impact_model" =>
            "coefficient * lagged_daily_volatility * sqrt(order_dollars / lagged_ADV)",
        "proposal_to_evaluation_calibration" => calibration,
        "full_search_diagnostics_computed_for_gate_passed_cells" => true,
        "full_search_candidate_count_per_gate_passed_cell" => 96,
        "diagnostic_scope" =>
            "scoring only; policy choices remained frozen and immutable",
        "evaluation_execution_lock_sha256" => _sha256_file(EXECUTION_LOCK_PATH),
        "proposal_policy_result_seal_sha256" => _sha256_file(PROPOSAL_RESULT_SEAL_PATH),
        "proposal_robustness_result_seal_sha256" =>
            _sha256_file(PROPOSAL_ROBUSTNESS_RESULT_SEAL_PATH),
        "evaluation_stage_manifest_sha256" => _sha256_file(PUBLIC_STAGE_MANIFEST_PATH),
        "return_values_included" => false,
        "licensed_identifiers_included" => false,
        "public_promotion_permitted" => true,
        "cells" => [result.public for result in results],
    )
    public_text = _toml_text(public_payload)
    local_payload = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-evaluation-result-local-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "HISTORICAL_EVALUATION_COMPLETE_LOCAL",
        "public_manifest_sha256" => _sha256_text(public_text),
        "trial_ledger_rows" => 38 * 485,
        "local_artifact_sha256" => Dict(
            result.public["local_trial_ledger_relative_path"] =>
                result.public["local_trial_ledger_sha256"] for result in results
        ),
        "return_values_included" => false,
        "licensed_identifiers_included" => false,
        "public_promotion_permitted" => false,
    )
    local_text = _toml_text(local_payload)
    if check
        read(PUBLIC_RESULT_MANIFEST_PATH, String) == public_text ||
            error("public evaluation result changed")
        read(LOCAL_RESULT_MANIFEST_PATH, String) == local_text ||
            error("local evaluation result manifest changed")
    else
        _write_new_or_identical(PUBLIC_RESULT_MANIFEST_PATH, public_text)
        _write_new_or_identical(LOCAL_RESULT_MANIFEST_PATH, local_text)
    end
    primary_complete_origins = common_summary["complete_origin_count"]
    println("V3_HISTORICAL_EVALUATION_PASSED")
    println("trial-ledger rows retained: $(38 * 485)")
    println("primary common-equity complete origins: $primary_complete_origins/19")
    return public_payload
end

function audit_evaluation()
    contract = _load_contract()
    for path in (PUBLIC_RESULT_MANIFEST_PATH, LOCAL_RESULT_MANIFEST_PATH)
        isfile(path) || error("evaluation result manifest is absent")
    end
    public = TOML.parsefile(PUBLIC_RESULT_MANIFEST_PATH)
    local_manifest = TOML.parsefile(LOCAL_RESULT_MANIFEST_PATH)
    public["status"] == "HISTORICAL_EVALUATION_COMPLETE" ||
        error("unexpected evaluation result status")
    public["return_values_included"] === false ||
        error("public evaluation result contains raw returns")
    public["licensed_identifiers_included"] === false ||
        error("public evaluation result contains licensed identifiers")
    public["trial_ledger_rows"] == 38 * 485 ||
        error("evaluation trial-ledger denominator changed")
    public["registered_policy_row_denominator"] == 38 * 5 ||
        error("registered policy row denominator changed")
    length(public["cells"]) == 38 || error("evaluation result omitted a cell")
    sum(Int(cell["registered_policy_row_count"]) for cell in public["cells"]) == 38 * 5 ||
        error("evaluation result omitted registered policy rows")
    all(length(cell["policy_outcomes"]) == 5 for cell in public["cells"]) ||
        error("evaluation result omitted a registered primary policy disposition")
    public["proposal_robustness_grid_cell_spec_denominator"] == 912 ||
        error("evaluation robustness spec denominator changed")
    public["proposal_robustness_grid_policy_choice_denominator"] == 1824 ||
        error("evaluation robustness choice denominator changed")
    sum(Int(cell["robustness_sensitivities"]["grid_spec_count"])
        for cell in public["cells"]) == 912 ||
        error("evaluation result omitted frozen robustness specs")
    sum(Int(cell["robustness_sensitivities"]["grid_policy_choice_count"])
        for cell in public["cells"]) == 1824 ||
        error("evaluation result omitted frozen robustness choices")
    loo = public["leave_one_origin_out_primary_common_equity"]
    loo["rule"] == "AGGREGATION_ONLY_NO_RESELECTION" &&
        loo["omission_count"] == 19 && length(loo["rows"]) == 19 ||
        error("evaluation result leave-one-origin-out denominator changed")
    local_manifest["public_manifest_sha256"] == _sha256_file(PUBLIC_RESULT_MANIFEST_PATH) ||
        error("evaluation result public/local manifests are not bound")
    hashes = Dict{String,String}(local_manifest["local_artifact_sha256"])
    length(hashes) == 38 || error("evaluation result omitted a trial ledger")
    for (relative, digest) in hashes
        path = joinpath(EXPERIMENT_ROOT, relative)
        isfile(path) || error("evaluation result artifact is absent: $relative")
        _sha256_file(path) == digest || error("evaluation result artifact changed: $relative")
    end
    public["evaluation_execution_lock_sha256"] == _sha256_file(EXECUTION_LOCK_PATH) ||
        error("evaluation result is not bound to its execution lock")
    public["proposal_policy_result_seal_sha256"] == _sha256_file(PROPOSAL_RESULT_SEAL_PATH) ||
        error("evaluation result is not bound to the proposal result seal")
    public["proposal_robustness_result_seal_sha256"] ==
        _sha256_file(PROPOSAL_ROBUSTNESS_RESULT_SEAL_PATH) ||
        error("evaluation result is not bound to the proposal robustness result seal")
    contract.public_stage["evaluation_scope"] ==
        "all five frozen registered policies; primary headline fixed" ||
        error("evaluation audit scope changed")
    println("V3_HISTORICAL_EVALUATION_AUDIT_PASSED")
    println("cells: 38; trial-ledger rows: $(38 * 485)")
    println("raw returns/licensed identifiers in public result: false")
    return public
end

function main(args = ARGS)
    length(args) == 1 || error("use exactly one of --run or --audit-only")
    args[1] == "--run" && return run_evaluation()
    args[1] == "--audit-only" && return audit_evaluation()
    error("unknown argument: $(args[1])")
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    RunFinancialStrategyLibraryPanelV3Evaluation.main()
end
