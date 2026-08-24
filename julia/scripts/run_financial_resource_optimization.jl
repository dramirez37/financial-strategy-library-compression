module FinancialResourceOptimization

using SHA: sha256
using Serialization
using StrategyInnovation
using TOML
import HiGHS
import JuMP

if !isdefined(Main, :FinancialTerminalAudit)
    Base.include(Main, joinpath(@__DIR__, "run_financial_terminal_audit.jl"))
end
if !isdefined(Main, :FinancialAnnualWalkforwardAudit)
    Base.include(Main, joinpath(@__DIR__, "run_financial_annual_walkforward_audit.jl"))
end
if !isdefined(Main, :LockFinancialResourceOptimization)
    Base.include(Main, joinpath(@__DIR__, "lock_financial_resource_optimization.jl"))
end

const TerminalAudit = Main.FinancialTerminalAudit
const AnnualAudit = Main.FinancialAnnualWalkforwardAudit
const DesignLock = Main.LockFinancialResourceOptimization
const ER = Rational{BigInt}
const INACTIVE_ID = "__resource_inactive__"
const RESOURCE_GC_PREVIOUS = Ref{Union{Nothing,Bool}}(nothing)
const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_resource_optimization.toml",
)

export build_exact_resource_model,
       main,
       registered_strategy_weights,
       run_extension

_require(condition::Bool, message::AbstractString) =
    condition ? true : error(message)
_repo_path(path::AbstractString) =
    isabspath(path) ? normpath(path) :
    normpath(joinpath(REPOSITORY_ROOT, path))
_exact(value::AbstractFloat) = ER(value)
_exact(value::Integer) = ER(value, 1)
_rat(value::Rational) = "$(numerator(value))//$(denominator(value))"
_rat(value::Integer) = "$(value)//1"
_bool(value::Bool) = value ? "true" : "false"

function _sha256_file(path::AbstractString)
    return open(path, "r") do io
        bytes2hex(sha256(io))
    end
end

function _csv_field(value)
    token = if value === missing || value === nothing
        ""
    elseif value isa Rational
        _rat(value)
    elseif value isa Bool
        _bool(value)
    elseif value isa AbstractFloat
        isfinite(value) ? repr(value) : string(value)
    else
        string(value)
    end
    return occursin(r"[,\"\n\r]", token) ?
           "\"$(replace(token, "\"" => "\"\""))\"" : token
end

function _csv_text(rows::AbstractVector{<:NamedTuple})
    isempty(rows) && error("cannot render an empty registered table")
    columns = propertynames(first(rows))
    all(propertynames(row) == columns for row in rows) ||
        error("CSV rows have inconsistent schemas")
    io = IOBuffer()
    println(io, join(string.(columns), ","))
    for row in rows
        println(io, join((_csv_field(getproperty(row, column)) for column in columns), ","))
    end
    return String(take!(io))
end

_json_escape(value::AbstractString) = replace(
    value,
    "\\" => "\\\\",
    "\"" => "\\\"",
    "\n" => "\\n",
    "\r" => "\\r",
    "\t" => "\\t",
)

function _json(value)
    value === nothing && return "null"
    value === missing && return "null"
    value isa Bool && return value ? "true" : "false"
    value isa Integer && return string(value)
    value isa Rational && return _json(_rat(value))
    value isa AbstractFloat && return isfinite(value) ? repr(value) : "null"
    value isa AbstractString && return "\"$(_json_escape(value))\""
    value isa AbstractVector && return "[" * join((_json(item) for item in value), ",") * "]"
    value isa Tuple && return _json(collect(value))
    value isa NamedTuple && return _json(Dict(string(key) => getproperty(value, key) for key in keys(value)))
    value isa AbstractDict && return "{" * join((
        "$(_json(string(key))):$(_json(value[key]))" for key in sort!(collect(keys(value)); by = string)
    ), ",") * "}"
    return _json(string(value))
end

function _write_text(path::AbstractString, text::AbstractString)
    mkpath(dirname(path))
    open(path, "w") do io
        write(io, text)
    end
    return path
end

function _status_expected_hash(status_text::String, path::String)
    marker = "\"$path\":\""
    location = findfirst(marker, status_text)
    isnothing(location) && error("locked status omits generated artifact hash: $path")
    start = last(location) + 1
    stop = start + 63
    stop <= lastindex(status_text) || error("truncated artifact hash for $path")
    digest = status_text[start:stop]
    occursin(r"^[0-9a-f]{64}$", digest) || error("invalid artifact hash for $path")
    return digest
end

function _verify_parent_artifacts(audit)
    status_path = String(audit["status"])
    status_text = read(_repo_path(status_path), String)
    parent = TOML.parsefile(_repo_path(audit["config"]))
    hashes = Dict(status_path => _sha256_file(_repo_path(status_path)))
    for path in String.(collect(values(parent["outputs"])))
        path == status_path && continue
        expected = _status_expected_hash(status_text, path)
        actual = _sha256_file(_repo_path(path))
        actual == expected || error("locked parent artifact changed: $path")
        hashes[path] = actual
    end
    return hashes
end

function _strategy_lookup(catalog)
    return Dict(strategy.id => strategy for strategy in catalog)
end

function _source_profiles_terminal(result, config)
    panel = TerminalAudit.load_market_panel(
        _repo_path(config["data"]["path"]),
        config,
    )
    beliefs = TerminalAudit._belief_states(panel, config)
    validation_indices = TerminalAudit._period_indices(
        panel,
        config["periods"]["validation_start"],
        config["periods"]["validation_end"],
    )
    base_cost = Float64(config["backtest"]["one_way_transaction_cost_bps"])
    lookup = _strategy_lookup(result.catalog)
    profiles = Dict{String,Vector{Float64}}()
    for id in result.initial_library
        strategy = lookup[id]
        backtest = TerminalAudit._backtest_strategy(strategy, panel, config; cost_bps = base_cost)
        profiles[id] = TerminalAudit._state_profile(backtest.net, beliefs.states, validation_indices, config)
    end
    return profiles
end

function _source_profiles_annual(result, config)
    panel = AnnualAudit.TerminalAudit.load_market_panel(
        _repo_path(config["data"]["path"]),
        config,
    )
    beliefs = AnnualAudit._belief_states(panel, config)
    validation_indices = AnnualAudit._period_indices(
        panel,
        config["periods"]["validation_start"],
        config["periods"]["validation_end"],
    )
    base_cost = Float64(config["backtest"]["one_way_transaction_cost_bps"])
    lookup = _strategy_lookup(result.catalog)
    profiles = Dict{String,Vector{Float64}}()
    for id in result.initial_library
        strategy = lookup[id]
        backtest = AnnualAudit.TerminalAudit._backtest_strategy(strategy, panel, config; cost_bps = base_cost)
        state_stats = AnnualAudit._state_stats(
            backtest.gross,
            backtest.turnover,
            beliefs.states,
            validation_indices,
            beliefs.state_count,
        )
        profiles[id] = AnnualAudit._profile(state_stats, base_cost, config)
    end
    return profiles
end

function _resource_mean_target(
    candidate_ids,
    initial_library,
    evaluations,
    panel,
    beliefs,
    evaluated,
    config,
    design_hash,
)
    base_cost = Float64(config["backtest"]["one_way_transaction_cost_bps"])
    years = Int.(config["periods"]["walk_forward_years"])
    lookback = Int(config["periods"]["trailing_estimation_years"])
    top_k = Int(config["ranking"]["top_k"])
    q = Float64(config["ranking"]["daily_discount"] * config["ranking"]["candidate_survival"])
    pseudocount = Float64(config["ranking"]["transition_pseudocount"])
    horizon = Int(config["ranking"]["occupation_horizon_sessions"])
    state_count = beliefs.state_count
    novelty = Dict(id => AnnualAudit._hamming_novelty(evaluations[id].strategy, initial_library, evaluations) for id in candidate_ids)
    target_sums = Dict(id => 0.0 for id in candidate_ids)
    decision_hashes = Dict{Int,String}()

    for year in years
        training_years = collect((year - lookback):(year - 1))
        training_indices = reduce(vcat, evaluated.year_indices[training_year] for training_year in training_years)
        prior_indices = findall(date -> date < string(year, "-01-01"), panel.dates)
        current_state = beliefs.states[last(prior_indices)]
        current_state in 1:state_count || error("walk-forward origin has undefined belief state")
        transition = AnnualAudit._transition_matrix(beliefs.states, training_indices, state_count, pseudocount)
        predicted_weights = AnnualAudit._predicted_occupation(transition, current_state, horizon, q)
        trailing_profiles = Dict{String,Vector{Float64}}()
        trailing_utilities = Dict{String,Float64}()
        for id in vcat(initial_library, candidate_ids)
            state_stats = AnnualAudit._combine_state_stats(evaluations[id].year_state_full, training_years, state_count)
            trailing_profiles[id] = AnnualAudit._profile(state_stats, base_cost, config)
            trailing_all = reduce(+, (evaluations[id].year_all_full[training_year] for training_year in training_years); init = AnnualAudit.TradeStats())
            trailing_utilities[id] = AnnualAudit._utility(trailing_all, base_cost, config)
        end
        trailing_frontier = AnnualAudit._frontier(initial_library, trailing_profiles, state_count)
        score_gaps = Dict(id => max.(trailing_profiles[id] .- trailing_frontier, 0.0) for id in candidate_ids)
        coverage_scores = Dict(id => sum(predicted_weights .* score_gaps[id]) for id in candidate_ids)
        current_scores = Dict(id => score_gaps[id][current_state] for id in candidate_ids)
        average_scores = Dict(id => trailing_utilities[id] for id in candidate_ids)
        score_maps = Dict(
            "coverage_marginal" => coverage_scores,
            "current_belief_improvement" => current_scores,
            "average_trailing_score" => average_scores,
            "raw_parameter_novelty" => novelty,
        )
        coverage_selection = AnnualAudit.greedy_marginal_selection(candidate_ids, score_gaps, predicted_weights, top_k)
        selected_by_method = Dict(
            "coverage_marginal" => coverage_selection.selected,
            "current_belief_improvement" => AnnualAudit._top_selection(current_scores, top_k),
            "average_trailing_score" => AnnualAudit._top_selection(average_scores, top_k),
            "raw_parameter_novelty" => AnnualAudit._top_selection(novelty, top_k),
        )
        decision_hash = AnnualAudit._decision_hash(year, design_hash, score_maps, selected_by_method)
        length(decision_hash) == 64 || error("walk-forward decision hash failed")
        decision_hashes[year] = decision_hash

        # The target year remains inaccessible until the identical registered
        # score, selection, and decision-hash computation above is complete.
        target_indices = evaluated.target_indices[year]
        actual_weights = AnnualAudit._realized_occupation(beliefs.states, target_indices, q, state_count)
        target_minimum = Int(config["backtest"]["minimum_target_profile_observations"])
        target_counts = evaluations[first(initial_library)].year_state_target[year]
        all(state -> target_counts[state].count > 0 || actual_weights[state] == 0.0, 1:state_count) ||
            error("an unvisited target state has positive realized occupation")
        target_profiles = Dict(
            id => AnnualAudit._profile(
                evaluations[id].year_state_target[year],
                base_cost,
                config;
                minimum_observations = target_minimum,
                allow_empty = true,
            ) for id in vcat(initial_library, candidate_ids)
        )
        target_frontier = AnnualAudit._frontier(initial_library, target_profiles, state_count)
        for id in candidate_ids
            gap = max.(target_profiles[id] .- target_frontier, 0.0)
            target_sums[id] += sum(actual_weights .* gap)
        end
        if year == last(years)
            isnothing(RESOURCE_GC_PREVIOUS[]) || error("resource GC guard is already active")
            RESOURCE_GC_PREVIOUS[] = GC.enable(false)
        end
        println("resource walk-forward episode=$year; decision_hash=$decision_hash")
        empty!(trailing_profiles)
        empty!(trailing_utilities)
        empty!(score_gaps)
        empty!(coverage_scores)
        empty!(current_scores)
        empty!(average_scores)
        empty!(target_profiles)
    end
    episode_count = length(years)
    mean_target = Dict(id => target_sums[id] / episode_count for id in candidate_ids)
    return (; mean_target, decision_hashes)
end

function _run_annual_resource_inputs(config, status_path::AbstractString)
    design_hash = AnnualAudit.DesignLock.verify_design_lock(config)
    data_path = _repo_path(config["data"]["path"])
    provenance = AnnualAudit._load_provenance(config, data_path)
    panel = AnnualAudit.TerminalAudit.load_market_panel(data_path, config)
    catalog = AnnualAudit.finite_strategy_catalog_annual(config)
    beliefs = AnnualAudit._belief_states(panel, config)
    evaluated = AnnualAudit._evaluate_catalog(catalog, panel, beliefs, config)
    evaluations = evaluated.evaluations
    initial_library = AnnualAudit._initial_library(catalog, evaluations, config)
    safe = AnnualAudit._prune_library(initial_library, evaluations, beliefs.state_count, config; safe = true)
    frontier_only = AnnualAudit._prune_library(initial_library, evaluations, beliefs.state_count, config; safe = false)
    profiles = Dict(id => copy(evaluations[id].validation_profile) for id in initial_library)
    tolerance = Float64(config["backtest"]["frontier_tolerance"])
    initial_frontier = AnnualAudit._frontier(initial_library, profiles, beliefs.state_count)
    AnnualAudit._profiles_equal(initial_frontier, AnnualAudit._frontier(safe.library, profiles, beliefs.state_count), tolerance) ||
        error("safe compression changed the annual-audit validation frontier")
    AnnualAudit._closure(initial_library, evaluations) == AnnualAudit._closure(safe.library, evaluations) ||
        error("safe compression changed the annual-audit module closure")
    AnnualAudit._profiles_equal(initial_frontier, AnnualAudit._frontier(frontier_only.library, profiles, beliefs.state_count), tolerance) ||
        error("frontier-only pruning changed the annual-audit validation frontier")

    initial_closure = AnnualAudit._closure(initial_library, evaluations)
    safe_closure = AnnualAudit._closure(safe.library, evaluations)
    frontier_closure = AnnualAudit._closure(frontier_only.library, evaluations)
    candidate_ids = [strategy.id for strategy in catalog if !(strategy.id in initial_library) && AnnualAudit._enabled(strategy, initial_closure)]
    ranked = _resource_mean_target(
        candidate_ids,
        initial_library,
        evaluations,
        panel,
        beliefs,
        evaluated,
        config,
        design_hash,
    )
    status_text = read(_repo_path(status_path), String)
    for (year, decision_hash) in ranked.decision_hashes
        occursin("\"$year\":\"$decision_hash\"", status_text) ||
            error("resource extraction changed the locked annual walk-forward decision hash for $year")
    end
    mean_target = ranked.mean_target
    candidate_quality(closure) = maximum(
        (mean_target[id] for id in candidate_ids if AnnualAudit._enabled(evaluations[id].strategy, closure));
        init = 0.0,
    )
    initial_candidate_quality = candidate_quality(initial_closure)
    safe_candidate_quality = candidate_quality(safe_closure)
    frontier_candidate_quality = candidate_quality(frontier_closure)
    isapprox(initial_candidate_quality, safe_candidate_quality; atol = tolerance, rtol = 0) ||
        error("safe compression changed annual walk-forward future candidate quality")
    result = (;
        status = "empirical_complete_aggregate_publishable",
        catalog,
        initial_library,
        safe_library = safe.library,
        frontier_only_library = frontier_only.library,
        initial_candidate_quality,
        safe_candidate_quality,
        frontier_candidate_quality,
        annual_decision_hashes = ranked.decision_hashes,
        design_hash,
        provenance,
    )
    return (; result, profiles)
end

function _write_annual_worker_payload(config_path::AbstractString, status_path::AbstractString)
    payload = redirect_stdout(stderr) do
        config = AnnualAudit.load_financial_annual_config(config_path)
        _run_annual_resource_inputs(config, status_path)
    end
    serialize(stdout, payload)
    flush(stdout)
    return nothing
end

function _run_annual_resource_inputs_isolated(config_path::AbstractString, status_path::AbstractString)
    project = joinpath(REPOSITORY_ROOT, "julia")
    command = `$(Base.julia_cmd()) --project=$project $(@__FILE__) --extract-annual-worker $config_path $status_path`
    bytes = read(command)
    return deserialize(IOBuffer(bytes))
end

function _run_locked_parent(audit)
    audit_id = String(audit["audit_id"])
    if audit_id == "locked_terminal_v1"
        parent_config = TerminalAudit.load_financial_config(_repo_path(audit["config"]))
        result = TerminalAudit.run_financial_terminal_audit(parent_config)
        _require(result.status == "empirical_complete_aggregate_publishable", "terminal parent audit is not complete")
        profiles = _source_profiles_terminal(result, parent_config)
    elseif audit_id == "annual_walk_forward_v2"
        parent_config = AnnualAudit.load_financial_annual_config(_repo_path(audit["config"]))
        extracted = _run_annual_resource_inputs_isolated(
            _repo_path(audit["config"]),
            _repo_path(audit["status"]),
        )
        result = extracted.result
        _require(result.status == "empirical_complete_aggregate_publishable", "annual walk-forward parent audit is not complete")
        profiles = extracted.profiles
    else
        error("unsupported registered financial audit: $audit_id")
    end
    lookup = _strategy_lookup(result.catalog)
    source_specs = [lookup[id] for id in result.initial_library]
    return (;
        audit_id,
        label = String(audit["reader_label"]),
        quality_timing = String(audit["quality_timing"]),
        parent_config,
        result,
        source_specs,
        profiles,
        tolerance = Float64(parent_config["backtest"]["frontier_tolerance"]),
    )
end

function _secondary_by_id(config, schedule_id::String)
    return only(row for row in config["secondary_resources"] if row["schedule_id"] == schedule_id)
end

"""Return all preregistered positive integer active-strategy weights."""
function registered_strategy_weights(source_specs, config)
    module_counts = Dict{String,Int}()
    for strategy in source_specs, module_id in strategy.modules
        module_counts[module_id] = get(module_counts, module_id, 0) + 1
    end
    validation = _secondary_by_id(config, "validation_computation")
    lookbacks = Dict(String(key) => Int(value) for (key, value) in validation["directional_lookbacks"])
    baseline = _secondary_by_id(config, "documented_complexity")["baseline"]
    schedules = Dict(
        "uniform_cardinality" => Dict{String,ER}(),
        "nonshared_modules" => Dict{String,ER}(),
        "validation_computation" => Dict{String,ER}(),
        "documented_complexity" => Dict{String,ER}(),
    )
    nonshared_counts = Dict{String,Int}()
    for strategy in source_specs
        id = strategy.id
        nonshared = count(module_id -> module_counts[module_id] == 1, strategy.modules)
        validation_units = 1 + div(lookbacks[strategy.directional_signal], 5) +
                           (strategy.entry_filter == "trend_100" ? Int(validation["trend_lookback_units"]) : 0) +
                           (strategy.risk_constraint == "vol_target_10" ? Int(validation["volatility_lookback_units"]) : 0) +
                           (strategy.exit_rule == "signal_flip" ? Int(validation["signal_flip_units"]) : 0)
        complexity_units = 1 +
                           (strategy.directional_signal != baseline["directional_signal"]) +
                           (strategy.entry_filter != baseline["entry_filter"]) +
                           (strategy.holding_horizon != Int(baseline["holding_horizon"])) +
                           (strategy.sizing_rule != baseline["sizing_rule"]) +
                           (strategy.exit_rule != baseline["exit_rule"]) +
                           (strategy.risk_constraint != baseline["risk_constraint"])
        schedules["uniform_cardinality"][id] = ER(1, 1)
        schedules["nonshared_modules"][id] = ER(1 + nonshared, 1)
        schedules["validation_computation"][id] = ER(validation_units, 1)
        schedules["documented_complexity"][id] = ER(complexity_units, 1)
        nonshared_counts[id] = nonshared
    end
    all(weight > 0 for weights in values(schedules) for weight in values(weights)) ||
        error("a registered active-strategy weight is not positive")
    return (; schedules, nonshared_counts, module_counts)
end

function _module_union(ids, lookup)
    modules = Set{String}()
    for id in ids
        union!(modules, lookup[id].modules)
    end
    return modules
end

function _rational_profiles(profiles)
    return Dict(id => ER[_exact(value) for value in values] for (id, values) in profiles)
end

function _frontier(ids, profiles)
    isempty(ids) && error("financial library cannot be empty")
    state_count = length(profiles[first(ids)])
    return ER[maximum(profiles[id][state] for id in ids) for state in 1:state_count]
end

function _float_frontier(ids, profiles)
    isempty(ids) && error("financial library cannot be empty")
    state_count = length(profiles[first(ids)])
    return Float64[maximum(profiles[id][state] for id in ids) for state in 1:state_count]
end

"""
Build the exact sparse incidence data used by the financial identity-closure
MILP. This deliberately does not materialize the power set of the module
universe. Exact post-solve verification checks the original rational profiles
and original module strings, so the incidence reduction cannot mask a change.
"""
function build_exact_resource_model(source_specs, float_profiles)
    lookup = _strategy_lookup(source_specs)
    source_ids = sort!(collect(keys(lookup)))
    rational_profiles = _rational_profiles(float_profiles)
    source_frontier = _frontier(source_ids, rational_profiles)
    state_count = length(source_frontier)
    module_ids = sort!(collect(_module_union(source_ids, lookup)))
    frontier_attainers = [
        [id for id in source_ids if rational_profiles[id][state] == source_frontier[state]]
        for state in 1:state_count
    ]
    all(!isempty, frontier_attainers) || error("an exact frontier row has no source attainer")
    module_carriers = Dict(
        module_id => [id for id in source_ids if module_id in lookup[id].modules]
        for module_id in module_ids
    )
    all(!isempty, values(module_carriers)) || error("an identity-closure module has no source carrier")
    return (;
        source_ids,
        source_frontier,
        rational_profiles,
        source_modules = Set(module_ids),
        frontier_attainers,
        module_carriers,
        lookup,
    )
end

function _scaled_objective_weights(source_ids, weights)
    all(haskey(weights, id) && weights[id] > 0 for id in source_ids) ||
        error("every active strategy requires a positive exact objective weight")
    scale = foldl(lcm, (BigInt(denominator(weights[id])) for id in source_ids); init = BigInt(1))
    big_coefficients = Dict(
        id => numerator(weights[id]) * div(scale, denominator(weights[id]))
        for id in source_ids
    )
    sum(values(big_coefficients); init = BigInt(0)) <= (BigInt(1) << 53) ||
        error("scaled MILP objective exceeds exact Float64 integer representation")
    coefficients = Dict(id => Int64(big_coefficients[id]) for id in source_ids)
    all(BigInt(coefficients[id]) == big_coefficients[id] for id in source_ids) ||
        error("scaled MILP objective conversion lost an integer coefficient")
    return (; scale, coefficients)
end

function _solve_identity_resource_milp(model, active_weights; objective::Symbol)
    objective in (:cardinality, :weight) || error("unsupported financial resource objective")
    objective_weights = objective == :cardinality ?
                        Dict(id => ER(1, 1) for id in model.source_ids) : active_weights
    scaled = _scaled_objective_weights(model.source_ids, objective_weights)
    optimization = JuMP.Model(HiGHS.Optimizer)
    JuMP.set_silent(optimization)
    JuMP.set_attribute(optimization, "threads", 1)
    JuMP.set_attribute(optimization, "random_seed", 0)
    JuMP.set_attribute(optimization, "mip_abs_gap", 0.0)
    JuMP.set_attribute(optimization, "mip_rel_gap", 0.0)
    JuMP.@variable(optimization, inactive_selected, Bin)
    JuMP.@constraint(optimization, inactive_selected == 1)
    JuMP.@variable(optimization, selected[model.source_ids], Bin)
    for attainers in model.frontier_attainers
        JuMP.@constraint(optimization, sum(selected[id] for id in attainers) >= 1)
    end
    for module_id in sort!(collect(model.source_modules))
        JuMP.@constraint(
            optimization,
            sum(selected[id] for id in model.module_carriers[module_id]) >= 1,
        )
    end
    JuMP.@objective(
        optimization,
        Min,
        sum(scaled.coefficients[id] * selected[id] for id in model.source_ids),
    )
    JuMP.optimize!(optimization)
    termination = JuMP.termination_status(optimization)
    primal = JuMP.primal_status(optimization)
    termination == JuMP.MOI.OPTIMAL || error("HiGHS did not claim a global optimum: $termination")
    primal == JuMP.MOI.FEASIBLE_POINT || error("HiGHS did not return a feasible binary vector: $primal")
    raw_values = Dict(id => Float64(JuMP.value(selected[id])) for id in model.source_ids)
    inactive_value = Float64(JuMP.value(inactive_selected))
    all(isfinite, values(raw_values)) && isfinite(inactive_value) ||
        error("HiGHS returned a nonfinite binary-variable value")
    integrality_residual = maximum(
        [abs(value - round(value)) for value in [inactive_value; collect(values(raw_values))]];
        init = 0.0,
    )
    ids = sort!([id for id in model.source_ids if raw_values[id] >= 0.5])
    round(Int, inactive_value) == 1 || error("mandatory inactive policy was not selected")
    exact_certificate = _certify_original(model, ids)
    all(any(id in ids for id in attainers) for attainers in model.frontier_attainers) ||
        error("exact frontier-cover incidence verification failed")
    all(any(id in ids for id in carriers) for carriers in values(model.module_carriers)) ||
        error("exact identity-closure carrier verification failed")
    exact_objective = _burden(ids, objective_weights)
    scaled_selected = sum((scaled.coefficients[id] for id in ids); init = Int64(0))
    ER(BigInt(scaled_selected), scaled.scale) == exact_objective ||
        error("exact objective does not reconcile with the scaled integer MILP")
    return (;
        selected_ids = ids,
        optimal_objective = exact_objective,
        exact_certificate = (;
            every_returned_library_exactly_safe = true,
            exact_optimality_verified = false,
            frontier_preserved = exact_certificate.frontier_preserved,
            closure_preserved = exact_certificate.closure_preserved,
            scaled_objective_reconciled = true,
            inactive_policy_selected = true,
        ),
        solver_certificate = (;
            solver_claimed_optimal = true,
            runs = [(
                termination_status = termination,
                primal_status = primal,
                raw_status = JuMP.raw_status(optimization),
                solve_time_seconds = JuMP.solve_time(optimization),
                node_count = try
                    Int(JuMP.node_count(optimization))
                catch
                    missing
                end,
                maximum_integrality_residual = integrality_residual,
            )],
        ),
    )
end

function _certify_original(model, selected_ids)
    selected_set = Set(selected_ids)
    issubset(selected_set, Set(model.source_ids)) || error("selected library is not a source sublibrary")
    selected_frontier = _frontier(selected_ids, model.rational_profiles)
    selected_modules = _module_union(selected_ids, model.lookup)
    selected_frontier == model.source_frontier || error("returned library does not exactly preserve the original rational frontier")
    selected_modules == model.source_modules || error("returned library does not exactly preserve identity closure")
    return (;
        selected_frontier,
        selected_modules,
        frontier_preserved = true,
        closure_preserved = true,
    )
end

function _endpoint_certificate(model, ids, tolerance::Float64)
    rational_frontier = _frontier(ids, model.rational_profiles)
    float_source = _float_frontier(model.source_ids, Dict(id => Float64.(model.rational_profiles[id]) for id in model.source_ids))
    float_selected = _float_frontier(ids, Dict(id => Float64.(model.rational_profiles[id]) for id in model.source_ids))
    modules = _module_union(ids, model.lookup)
    return (;
        selected_frontier = rational_frontier,
        selected_modules = modules,
        exact_frontier_preserved = rational_frontier == model.source_frontier,
        locked_tolerance_frontier_preserved = all(isapprox(float_source[state], float_selected[state]; atol = tolerance, rtol = 0) for state in eachindex(float_source)),
        closure_preserved = modules == model.source_modules,
    )
end

function _burden(ids, weights)
    return sum((weights[id] for id in ids); init = ER(0, 1))
end

function _certificate_hash(audit_id, schedule_id, method, ids, frontier, modules, burden)
    payload = join((
        audit_id,
        schedule_id,
        method,
        join(sort(ids), ";"),
        join((_rat(value) for value in frontier), ";"),
        join(sort(collect(modules)), ";"),
        _rat(burden),
    ), "\n")
    return bytes2hex(sha256(payload))
end

function _quality_values(parent)
    result = parent.result
    return (
        source = _exact(Float64(result.initial_candidate_quality)),
        stepwise = _exact(Float64(result.safe_candidate_quality)),
        frontier_only = _exact(Float64(result.frontier_candidate_quality)),
    )
end

function _solution_row(
    parent,
    model,
    weights,
    schedule_id,
    method,
    ids,
    endpoint,
    opportunity_quality;
    solver_result = nothing,
)
    source_burden = _burden(model.source_ids, weights)
    selected_burden = _burden(ids, weights)
    saved = source_burden - selected_burden
    certificate_hash = _certificate_hash(
        parent.audit_id,
        schedule_id,
        method,
        ids,
        endpoint.selected_frontier,
        endpoint.selected_modules,
        selected_burden,
    )
    solver_claimed_optimal = !isnothing(solver_result)
    exact_postsolve = isnothing(solver_result) ?
                      endpoint.exact_frontier_preserved && endpoint.closure_preserved :
                      solver_result.exact_certificate.every_returned_library_exactly_safe &&
                      endpoint.exact_frontier_preserved && endpoint.closure_preserved
    solver_status = isnothing(solver_result) ? "not_applicable" :
                    string(first(solver_result.solver_certificate.runs).termination_status)
    integrality_residual = isnothing(solver_result) ? 0.0 :
                           first(solver_result.solver_certificate.runs).maximum_integrality_residual
    return (
        audit_id = parent.audit_id,
        audit_label = parent.label,
        schedule_id,
        method,
        objective = method == "global_safe" ? (schedule_id == "uniform_cardinality" ? "cardinality" : "weight") : "comparator",
        source_size = length(model.source_ids),
        selected_size = length(ids),
        source_burden,
        selected_burden,
        burden_saved = saved,
        burden_saved_share = source_burden == 0 ? ER(0, 1) : saved / source_burden,
        exact_frontier_preserved = endpoint.exact_frontier_preserved,
        locked_tolerance_frontier_preserved = endpoint.locked_tolerance_frontier_preserved,
        exact_closure_preserved = endpoint.closure_preserved,
        modules_retained = length(endpoint.selected_modules),
        target_modules = length(model.source_modules),
        ex_post_enabled_descendant_opportunity_quality = opportunity_quality,
        ex_post_quality_change = opportunity_quality - _quality_values(parent).source,
        quality_timing = parent.quality_timing,
        solver_claimed_optimal,
        solver_termination_status = solver_status,
        exact_postsolve_selected_library_verified = exact_postsolve,
        exact_global_optimality_by_enumeration = isnothing(solver_result) ? false : solver_result.exact_certificate.exact_optimality_verified,
        solver_tolerances_used_as_proof = false,
        maximum_integrality_residual = integrality_residual,
        selected_library_certificate_sha256 = certificate_hash,
        selected_strategy_ids = join(ids, ";"),
        retained_module_ids = join(sort(collect(endpoint.selected_modules)), ";"),
    )
end

function _analyze_audit(parent, config)
    model = build_exact_resource_model(parent.source_specs, parent.profiles)
    weights_data = registered_strategy_weights(parent.source_specs, config)
    quality = _quality_values(parent)
    quality.source == quality.stepwise || error("locked safe opportunity-quality identity does not close exactly")
    source_lookup = model.lookup
    stepwise_ids = sort!(String.(parent.result.safe_library))
    frontier_ids = sort!(String.(parent.result.frontier_only_library))
    stepwise_endpoint = _endpoint_certificate(model, stepwise_ids, parent.tolerance)
    frontier_endpoint = _endpoint_certificate(model, frontier_ids, parent.tolerance)
    stepwise_endpoint.locked_tolerance_frontier_preserved || error("locked stepwise endpoint no longer passes its frozen tolerance")
    stepwise_endpoint.closure_preserved || error("locked stepwise endpoint no longer preserves closure")
    frontier_endpoint.locked_tolerance_frontier_preserved || error("locked frontier-only endpoint no longer passes its frozen tolerance")

    schedule_ids = [
        "uniform_cardinality",
        "nonshared_modules",
        "validation_computation",
        "documented_complexity",
    ]
    solver_results = Dict{String,Any}()
    global_ids = Dict{String,Vector{String}}()
    for schedule_id in schedule_ids
        objective = schedule_id == "uniform_cardinality" ? :cardinality : :weight
        println("solving audit=$(parent.audit_id) schedule=$schedule_id objective=$objective")
        solver_result = _solve_identity_resource_milp(
            model,
            weights_data.schedules[schedule_id];
            objective,
        )
        solver_result.solver_certificate.solver_claimed_optimal || error("HiGHS did not claim a global optimum")
        solver_result.exact_certificate.every_returned_library_exactly_safe || error("exact solver certificate failed")
        ids = solver_result.selected_ids
        _certify_original(model, ids)
        solver_results[schedule_id] = solver_result
        global_ids[schedule_id] = ids
    end

    solution_rows = NamedTuple[]
    library_rows = NamedTuple[]
    frontier_rows = NamedTuple[]
    for schedule_id in schedule_ids
        weights = weights_data.schedules[schedule_id]
        global_endpoint_raw = _certify_original(model, global_ids[schedule_id])
        global_endpoint = (;
            selected_frontier = global_endpoint_raw.selected_frontier,
            selected_modules = global_endpoint_raw.selected_modules,
            exact_frontier_preserved = true,
            locked_tolerance_frontier_preserved = true,
            closure_preserved = true,
        )
        method_data = [
            ("global_safe", global_ids[schedule_id], global_endpoint, quality.source, solver_results[schedule_id]),
            ("stepwise_safe", stepwise_ids, stepwise_endpoint, quality.stepwise, nothing),
            ("frontier_only", frontier_ids, frontier_endpoint, quality.frontier_only, nothing),
        ]
        for (method, ids, endpoint, opportunity_quality, solver_result) in method_data
            push!(solution_rows, _solution_row(
                parent,
                model,
                weights,
                schedule_id,
                method,
                ids,
                endpoint,
                opportunity_quality;
                solver_result,
            ))
            selected = Set(ids)
            certificate_hash = last(solution_rows).selected_library_certificate_sha256
            for id in model.source_ids
                push!(library_rows, (
                    audit_id = parent.audit_id,
                    schedule_id,
                    method,
                    strategy_id = id,
                    selected = id in selected,
                    resource_weight = weights[id],
                    certificate_sha256 = certificate_hash,
                ))
            end
            for state in eachindex(model.source_frontier)
                push!(frontier_rows, (
                    audit_id = parent.audit_id,
                    schedule_id,
                    method,
                    belief_state = state,
                    source_frontier = model.source_frontier[state],
                    selected_frontier = endpoint.selected_frontier[state],
                    exact_equal = model.source_frontier[state] == endpoint.selected_frontier[state],
                    locked_tolerance_preserved = endpoint.locked_tolerance_frontier_preserved,
                ))
            end
        end
    end

    weight_rows = NamedTuple[]
    for strategy in sort(parent.source_specs; by = row -> row.id)
        id = strategy.id
        push!(weight_rows, (
            audit_id = parent.audit_id,
            strategy_id = id,
            module_count = length(strategy.modules),
            source_local_nonshared_module_count = weights_data.nonshared_counts[id],
            uniform_cardinality_weight = weights_data.schedules["uniform_cardinality"][id],
            nonshared_modules_weight = weights_data.schedules["nonshared_modules"][id],
            validation_computation_weight = weights_data.schedules["validation_computation"][id],
            documented_complexity_weight = weights_data.schedules["documented_complexity"][id],
        ))
    end

    primary_global = only(row for row in solution_rows if row.schedule_id == "uniform_cardinality" && row.method == "global_safe")
    primary_stepwise = only(row for row in solution_rows if row.schedule_id == "uniform_cardinality" && row.method == "stepwise_safe")
    primary_frontier = only(row for row in solution_rows if row.schedule_id == "uniform_cardinality" && row.method == "frontier_only")
    summary_row = (
        audit_id = parent.audit_id,
        audit_label = parent.label,
        source_size = length(model.source_ids),
        stepwise_safe_size = length(stepwise_ids),
        globally_optimal_safe_size = primary_global.selected_size,
        stepwise_cardinality_optimality_gap = length(stepwise_ids) - primary_global.selected_size,
        frontier_only_size = length(frontier_ids),
        source_module_count = length(model.source_modules),
        global_modules_retained = primary_global.modules_retained,
        stepwise_modules_retained = primary_stepwise.modules_retained,
        frontier_only_modules_retained = primary_frontier.modules_retained,
        global_exact_frontier_preserved = primary_global.exact_frontier_preserved,
        global_exact_closure_preserved = primary_global.exact_closure_preserved,
        stepwise_exact_frontier_preserved = primary_stepwise.exact_frontier_preserved,
        stepwise_locked_tolerance_frontier_preserved = primary_stepwise.locked_tolerance_frontier_preserved,
        stepwise_exact_closure_preserved = primary_stepwise.exact_closure_preserved,
        frontier_only_exact_frontier_preserved = primary_frontier.exact_frontier_preserved,
        frontier_only_locked_tolerance_frontier_preserved = primary_frontier.locked_tolerance_frontier_preserved,
        frontier_only_exact_closure_preserved = primary_frontier.exact_closure_preserved,
        source_ex_post_opportunity_quality = quality.source,
        global_ex_post_opportunity_quality = primary_global.ex_post_enabled_descendant_opportunity_quality,
        stepwise_ex_post_opportunity_quality = quality.stepwise,
        frontier_only_ex_post_opportunity_quality = quality.frontier_only,
        frontier_only_ex_post_opportunity_quality_loss = quality.source - quality.frontier_only,
        global_uniform_maintenance_burden_saved = primary_global.burden_saved,
        stepwise_uniform_maintenance_burden_saved = primary_stepwise.burden_saved,
        global_selected_library_certificate_sha256 = primary_global.selected_library_certificate_sha256,
        parent_pruning_rules_redefined = false,
        held_out_quality_used_to_define_weights = false,
    )
    return (; weight_rows, solution_rows, library_rows, frontier_rows, summary_row)
end

function _render_report(config, summaries, solutions, design_hash, parent_hashes)
    io = IOBuffer()
    println(io, "# Financial audit resource optimization\n")
    println(io, "This separately registered extension leaves every parent numerical result unchanged. The primary burden is `w_s = 1`; three secondary schedules were frozen before any resource-optimization result was computed. Held-out opportunity quality is reported only after selection and never enters a weight.\n")
    println(io, "Design lock: `$design_hash`. Exact `Rational{BigInt}` values in the CSVs are authoritative.\n")
    println(io, "## Primary minimum-cardinality results\n")
    println(io, "| audit | source | stepwise safe | global safe | gap | frontier only | modules | global maintenance saved |")
    println(io, "|---|---:|---:|---:|---:|---:|---:|---:|")
    for row in summaries
        println(io, "| $(row.audit_label) | $(row.source_size) | $(row.stepwise_safe_size) | $(row.globally_optimal_safe_size) | $(row.stepwise_cardinality_optimality_gap) | $(row.frontier_only_size) | $(row.source_module_count) | $(_rat(row.global_uniform_maintenance_burden_saved)) |")
    end
    println(io, "\nEvery global safe selection exactly reproduces the losslessly rationalized validation frontier and the complete identity closure. Existing stepwise and frontier-only endpoints are reported under both exact equality and their original frozen tolerance; their rules and orders were not changed.\n")
    println(io, "## Registered burden schedules\n")
    println(io, "| audit | schedule | global size | source burden | selected burden | burden saved |")
    println(io, "|---|---|---:|---:|---:|---:|")
    for row in solutions
        row.method == "global_safe" || continue
        println(io, "| $(row.audit_label) | `$(row.schedule_id)` | $(row.selected_size) | $(_rat(row.source_burden)) | $(_rat(row.selected_burden)) | $(_rat(row.burden_saved)) |")
    end
    println(io, "\nThe schedules are fixed maintenance (`uniform_cardinality`), fixed maintenance plus source-local uniquely carried modules, documented rolling validation computation, and documented nonbaseline model complexity.\n")
    println(io, "## Ex post enabled-descendant opportunity quality\n")
    for row in summaries
        println(io, "- **$(row.audit_label):** source/global/stepwise = `$(_rat(row.source_ex_post_opportunity_quality))`; frontier-only = `$(_rat(row.frontier_only_ex_post_opportunity_quality))`; exact loss = `$(_rat(row.frontier_only_ex_post_opportunity_quality_loss))`.")
    end
    println(io, "\nThese quality values retain the parent information timing: the terminal audit uses the locked 2020–2024 period after its validation decision hash; the annual walk-forward audit uses next-year targets after each annual decision hash.\n")
    println(io, "## Certificates and claim boundary\n")
    println(io, "HiGHS reported `OPTIMAL` for every global search. Each binary vector was then reconstructed and checked with exact rational frontier arithmetic, exact module-set closure, exact integer burdens, and a SHA-256 selected-library certificate. Numerical solver tolerances are not treated as a proof of global optimality; the global-search claim and exact post-solve safety certificate are reported separately. Full membership certificates, retained modules, frontier coordinates, and burdens are in the companion CSVs.\n")
    println(io, "Parent artifacts rechecked during the registered solve: $(length(parent_hashes)) files; all hashes were unchanged before and after execution.\n")
    return String(take!(io))
end

function _render_outputs(config, analyses, design_hash, parent_hashes)
    weights = vcat((analysis.weight_rows for analysis in analyses)...)
    solutions = vcat((analysis.solution_rows for analysis in analyses)...)
    libraries = vcat((analysis.library_rows for analysis in analyses)...)
    frontiers = vcat((analysis.frontier_rows for analysis in analyses)...)
    summaries = [analysis.summary_row for analysis in analyses]
    texts = Dict{String,String}(
        String(config["outputs"]["weights_csv"]) => _csv_text(weights),
        String(config["outputs"]["solutions_csv"]) => _csv_text(solutions),
        String(config["outputs"]["libraries_csv"]) => _csv_text(libraries),
        String(config["outputs"]["frontier_certificates_csv"]) => _csv_text(frontiers),
        String(config["outputs"]["summary_csv"]) => _csv_text(summaries),
    )
    report_path = String(config["outputs"]["report_md"])
    texts[report_path] = _render_report(config, summaries, solutions, design_hash, parent_hashes)
    hashes = Dict(path => bytes2hex(sha256(text)) for (path, text) in texts)
    all_global = [row for row in solutions if row.method == "global_safe"]
    all_safe_exact = all(row.exact_frontier_preserved && row.exact_closure_preserved && row.exact_postsolve_selected_library_verified for row in all_global)
    status = Dict(
        "schema_version" => config["schema_version"],
        "experiment_id" => config["experiment_id"],
        "design_sha256" => design_hash,
        "arithmetic" => config["arithmetic"],
        "solver" => config["solver"],
        "audit_count" => length(analyses),
        "primary_schedule" => config["primary_resource"]["schedule_id"],
        "secondary_schedules" => String[row["schedule_id"] for row in config["secondary_resources"]],
        "parent_artifact_sha256" => parent_hashes,
        "generated_artifact_sha256" => hashes,
        "gates" => Dict(
            "parent_artifact_hashes_unchanged" => true,
            "all_global_milp_statuses_optimal" => all(row.solver_claimed_optimal && row.solver_termination_status == "OPTIMAL" for row in all_global),
            "all_global_safe_libraries_exactly_verified" => all_safe_exact,
            "all_safe_opportunity_quality_equalities_exact" => all(analysis.summary_row.source_ex_post_opportunity_quality == analysis.summary_row.global_ex_post_opportunity_quality == analysis.summary_row.stepwise_ex_post_opportunity_quality for analysis in analyses),
            "solver_tolerances_used_as_proof" => false,
            "parent_pruning_rules_redefined" => false,
            "held_out_quality_used_to_define_weights" => false,
        ),
    )
    _require(status["gates"]["all_global_milp_statuses_optimal"], "not every MILP reported OPTIMAL")
    _require(status["gates"]["all_global_safe_libraries_exactly_verified"], "an exact safe-library gate failed")
    _require(status["gates"]["all_safe_opportunity_quality_equalities_exact"], "a safe opportunity-quality identity failed")
    status_path = String(config["outputs"]["status_json"])
    texts[status_path] = _json(status) * "\n"
    return (; texts, status, summaries, solutions)
end

function run_extension(config_path::AbstractString = DEFAULT_CONFIG; write_outputs::Bool = true)
    try
        config = TOML.parsefile(config_path)
        design_hash = DesignLock.verify_design_lock(config_path)
        parent_hashes_before = Dict{String,String}()
        for audit in config["audits"]
            merge!(parent_hashes_before, _verify_parent_artifacts(audit))
        end
        parents = [_run_locked_parent(audit) for audit in config["audits"]]
        analyses = [_analyze_audit(parent, config) for parent in parents]
        parent_hashes_after = Dict{String,String}()
        for audit in config["audits"]
            merge!(parent_hashes_after, _verify_parent_artifacts(audit))
        end
        parent_hashes_before == parent_hashes_after || error("a locked parent artifact changed during resource optimization")
        rendered = _render_outputs(config, analyses, design_hash, parent_hashes_after)
        if write_outputs
            for (path, text) in rendered.texts
                _write_text(_repo_path(path), text)
            end
            println("wrote financial resource optimization outputs for $(length(analyses)) locked audits")
        end
        return (; rendered..., analyses, design_hash, parent_hashes = parent_hashes_after)
    finally
        previous = RESOURCE_GC_PREVIOUS[]
        if !isnothing(previous)
            RESOURCE_GC_PREVIOUS[] = nothing
            GC.enable(previous)
        end
    end
end

function _check_outputs(config_path::AbstractString)
    config = TOML.parsefile(config_path)
    result = run_extension(config_path; write_outputs = false)
    for (path, expected) in result.texts
        full_path = _repo_path(path)
        _require(isfile(full_path), "registered financial resource output is absent: $path")
        actual = read(full_path, String)
        actual == expected || error("registered financial resource output drifted: $path")
    end
    println("financial resource optimization outputs current; audits=$(length(result.analyses))")
    return result
end

function main(args = ARGS)
    if "--extract-annual-worker" in args
        length(args) == 3 || error("worker usage: --extract-annual-worker CONFIG STATUS")
        return _write_annual_worker_payload(args[2], args[3])
    end
    positional = [argument for argument in args if !startswith(argument, "--")]
    length(positional) <= 1 || error("usage: run_financial_resource_optimization.jl [config] [--check]")
    config_path = isempty(positional) ? DEFAULT_CONFIG : only(positional)
    return "--check" in args ? _check_outputs(config_path) : run_extension(config_path)
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    FinancialResourceOptimization.main()
end
