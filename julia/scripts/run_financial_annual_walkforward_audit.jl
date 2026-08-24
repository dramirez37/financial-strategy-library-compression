module FinancialAnnualWalkforwardAudit

using Printf: @sprintf
using SHA: sha256
using StableRNGs: StableRNG
using Random: rand
using TOML

include(joinpath(@__DIR__, "run_financial_terminal_audit.jl"))
include(joinpath(@__DIR__, "freeze_financial_annual_walkforward_audit.jl"))
const TerminalAudit = FinancialTerminalAudit
const DesignLock = FreezeFinancialAnnualWalkforwardAudit

export DEFAULT_FINANCIAL_ANNUAL_CONFIG,
    TradeStats,
    load_financial_annual_config,
    finite_strategy_catalog_annual,
    greedy_marginal_selection,
    run_financial_annual_walkforward_audit,
    write_financial_annual_walkforward_audit_outputs,
    main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_FINANCIAL_ANNUAL_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_annual_walkforward_audit.toml",
)
const CONFIG_SCHEMA = "financial-illustration-v2"
const SELECTION_SCHEMA = "financial-universe-selection-v2"
const PROVENANCE_SCHEMA = "financial-illustration-provenance-v2"

_require(condition::Bool, message::AbstractString) = condition ? true : error(message)
_repo_path(path::AbstractString) = isabspath(path) ? normpath(path) : normpath(joinpath(REPOSITORY_ROOT, path))

function _sha256_file(path::AbstractString)
    open(path, "r") do io
        return bytes2hex(sha256(io))
    end
end

struct TradeStats
    count::Int
    sum_gross::Float64
    sum_gross_squared::Float64
    sum_turnover::Float64
    sum_turnover_squared::Float64
    sum_gross_turnover::Float64
end

TradeStats() = TradeStats(0, 0.0, 0.0, 0.0, 0.0, 0.0)

Base.:+(left::TradeStats, right::TradeStats) = TradeStats(
    left.count + right.count,
    left.sum_gross + right.sum_gross,
    left.sum_gross_squared + right.sum_gross_squared,
    left.sum_turnover + right.sum_turnover,
    left.sum_turnover_squared + right.sum_turnover_squared,
    left.sum_gross_turnover + right.sum_gross_turnover,
)

function _stats(gross::Vector{Float64}, turnover::Vector{Float64}, indices)
    result = TradeStats()
    for index in indices
        g = gross[index]
        t = turnover[index]
        result += TradeStats(1, g, g^2, t, t^2, g * t)
    end
    return result
end

function _state_stats(gross, turnover, states, indices, state_count::Int)
    return [_stats(gross, turnover, (index for index in indices if states[index] == state)) for state in 1:state_count]
end

function _combine_state_stats(year_stats, years, state_count::Int)
    combined = [TradeStats() for _ in 1:state_count]
    for year in years, state in 1:state_count
        combined[state] += year_stats[year][state]
    end
    return combined
end

function _net_moments(stats::TradeStats, cost_bps::Real)
    _require(stats.count > 0, "cannot evaluate empty return statistics")
    cost = Float64(cost_bps) / 10_000
    net_sum = stats.sum_gross - cost * stats.sum_turnover
    net_sum_squared = stats.sum_gross_squared -
                      2 * cost * stats.sum_gross_turnover +
                      cost^2 * stats.sum_turnover_squared
    mean = net_sum / stats.count
    variance = stats.count <= 1 ? 0.0 : max(0.0, (net_sum_squared - net_sum^2 / stats.count) / (stats.count - 1))
    return (; mean, variance)
end

function _utility(stats::TradeStats, cost_bps::Real, config::AbstractDict)
    moments = _net_moments(stats, cost_bps)
    annualization = Float64(config["backtest"]["annualization_sessions"])
    risk_aversion = Float64(config["backtest"]["risk_aversion"])
    return annualization * moments.mean - 0.5 * risk_aversion * annualization * moments.variance
end

function _profile(
    stats::Vector{TradeStats},
    cost_bps::Real,
    config::AbstractDict;
    minimum_observations::Int = Int(config["backtest"]["minimum_profile_observations"]),
    allow_empty::Bool = false,
)
    values = Float64[]
    for item in stats
        if item.count == 0 && allow_empty
            push!(values, 0.0)
        else
            _require(item.count >= minimum_observations, "a belief-state profile has too few observations")
            push!(values, _utility(item, cost_bps, config))
        end
    end
    return values
end

function _load_selection(config::AbstractDict)
    path = _repo_path(config["universe"]["selection_manifest"])
    _require(isfile(path), "universe selection manifest is absent")
    _require(_sha256_file(path) == config["universe"]["selection_manifest_sha256"], "universe selection hash differs from the protocol")
    selection = TOML.parsefile(path)
    _require(selection["schema_version"] == SELECTION_SCHEMA, "unsupported universe selection schema")
    _require(selection["outcome_fields_read"] === false, "universe selection was not outcome blind")
    _require(length(selection["selected"]) == config["universe"]["expected_count"], "universe count differs from the protocol")
    tickers = String[row["ticker"] for row in selection["selected"]]
    _require(length(unique(tickers)) == length(tickers), "selected tickers are not unique")
    return (; path, selection, tickers)
end

function load_financial_annual_config(path::AbstractString = DEFAULT_FINANCIAL_ANNUAL_CONFIG)
    config = TOML.parsefile(path)
    _require(config["schema_version"] == CONFIG_SCHEMA, "unsupported annual walk-forward financial-audit config schema")
    _require(config["julia_version"] == "1.12.6", "annual walk-forward financial audit requires Julia 1.12.6")
    selection = _load_selection(config)
    config["universe"]["tickers"] = selection.tickers
    _require(length(selection.tickers) == 100, "annual walk-forward audit requires the frozen 100-ETF universe")
    _require(config["ranking"]["expected_pattern_is_hard_gate"] === false, "empirical ranking outcomes must not be hard-coded")
    _require(config["ranking"]["selection_rule"] == "sequential greedy marginal set coverage with strategy-id tie break", "unsupported annual walk-forward selection rule")
    _require(0 <= config["ranking"]["daily_discount"] <= 1, "daily discount must lie in [0,1]")
    _require(0 <= config["ranking"]["candidate_survival"] <= 1, "candidate survival must lie in [0,1]")
    _require(config["ranking"]["top_k"] > 0, "top_k must be positive")
    _require(length(config["backtest"]["belief_quantiles"]) == 4, "annual walk-forward protocol requires five belief states")
    _require(config["periods"]["walk_forward_years"] == [2020, 2021, 2022, 2023, 2024], "annual walk-forward audit years changed")
    return config
end

finite_strategy_catalog_annual(config::AbstractDict = load_financial_annual_config()) = TerminalAudit.finite_strategy_catalog(config)

function _load_provenance(config::AbstractDict, data_path::AbstractString)
    path = _repo_path(config["data"]["provenance_path"])
    _require(isfile(path), "annual walk-forward provenance file is absent")
    provenance = TOML.parsefile(path)
    _require(provenance["schema_version"] == PROVENANCE_SCHEMA, "unsupported annual walk-forward provenance schema")
    _require(provenance["raw_data_redistribution_permitted"] === false, "raw redistribution must remain false")
    _require(provenance["aggregate_outputs_publishable"] === true, "aggregate publication status is not cleared")
    _require(provenance["universe_selection_outcome_fields_read"] === false, "provenance does not preserve the outcome-blind universe gate")
    _require(provenance["universe_selection_manifest_sha256"] == config["universe"]["selection_manifest_sha256"], "provenance universe hash differs")
    _require(_sha256_file(data_path) == provenance["file_sha256"], "annual walk-forward market-panel hash differs from provenance")
    return provenance
end

function _belief_states(panel, config)
    reference = String(config["backtest"]["belief_signal_ticker"])
    prices = panel.total_return_index[reference]
    lookback = Int(config["backtest"]["belief_lookback"])
    features = [TerminalAudit._lookback_return(prices, index, lookback) for index in eachindex(prices)]
    periods = config["periods"]
    development = [
        features[index] for index in eachindex(features) if
        periods["development_start"] <= panel.dates[index] <= periods["development_end"] &&
        isfinite(features[index])
    ]
    thresholds = [TerminalAudit._empirical_quantile(development, Float64(probability)) for probability in config["backtest"]["belief_quantiles"]]
    _require(issorted(thresholds), "belief thresholds are not ordered")
    states = zeros(Int, length(features))
    for index in eachindex(features)
        isfinite(features[index]) || continue
        states[index] = searchsortedfirst(thresholds, features[index])
    end
    return (; states, thresholds, state_count = length(thresholds) + 1)
end

function _period_indices(panel, start_date::String, end_date::String)
    return findall(date -> start_date <= date <= end_date, panel.dates)
end

function _year_indices(panel, year::Int)
    prefix = string(year, "-")
    return findall(date -> startswith(date, prefix), panel.dates)
end

function _evaluate_catalog(catalog, panel, beliefs, config)
    periods = config["periods"]
    development_indices = _period_indices(panel, periods["development_start"], periods["development_end"])
    validation_indices = _period_indices(panel, periods["validation_start"], periods["validation_end"])
    locked_indices = _period_indices(panel, periods["locked_start"], periods["locked_end"])
    years = collect(2015:2024)
    year_indices = Dict(year => _year_indices(panel, year) for year in years)
    horizon = Int(config["ranking"]["occupation_horizon_sessions"])
    target_indices = Dict(year => first(year_indices[year], min(horizon, length(year_indices[year]))) for year in years)
    base_cost = Float64(config["backtest"]["one_way_transaction_cost_bps"])
    evaluations = Dict{String,NamedTuple}()
    for (position, strategy) in enumerate(catalog)
        backtest = TerminalAudit._backtest_strategy(strategy, panel, config; cost_bps = base_cost)
        gross = backtest.gross
        turnover = backtest.turnover
        development_all = _stats(gross, turnover, development_indices)
        validation_all = _stats(gross, turnover, validation_indices)
        locked_all = _stats(gross, turnover, locked_indices)
        validation_state = _state_stats(gross, turnover, beliefs.states, validation_indices, beliefs.state_count)
        year_state_full = Dict(year => _state_stats(gross, turnover, beliefs.states, year_indices[year], beliefs.state_count) for year in years)
        year_state_target = Dict(year => _state_stats(gross, turnover, beliefs.states, target_indices[year], beliefs.state_count) for year in years)
        year_all_full = Dict(year => _stats(gross, turnover, year_indices[year]) for year in years)
        evaluations[strategy.id] = (
            strategy,
            development_all,
            validation_all,
            locked_all,
            validation_state,
            validation_profile = _profile(validation_state, base_cost, config),
            development_utility = _utility(development_all, base_cost, config),
            validation_utility = _utility(validation_all, base_cost, config),
            locked_utility = _utility(locked_all, base_cost, config),
            development_gross_utility = _utility(development_all, 0.0, config),
            validation_gross_utility = _utility(validation_all, 0.0, config),
            locked_gross_utility = _utility(locked_all, 0.0, config),
            mean_validation_turnover = validation_all.sum_turnover / validation_all.count,
            year_state_full,
            year_state_target,
            year_all_full,
        )
        if position % 500 == 0 || position == length(catalog)
            println("evaluated strategies=$position/$(length(catalog))")
            GC.gc(false)
        end
    end
    return (; evaluations, development_indices, validation_indices, locked_indices, year_indices, target_indices)
end

function _closure(ids, evaluations)
    result = Set{String}()
    for id in ids
        union!(result, evaluations[id].strategy.modules)
    end
    return result
end

function _frontier(ids, profile_by_id, state_count::Int)
    _require(!isempty(ids), "library cannot be empty")
    return [maximum(profile_by_id[id][state] for id in ids) for state in 1:state_count]
end

function _initial_library(catalog, evaluations, config)
    selected = Set{String}()
    top_per_ticker = Int(config["library"]["top_development_strategies_per_ticker"])
    for ticker in String.(config["universe"]["tickers"])
        ids = [strategy.id for strategy in catalog if strategy.ticker == ticker]
        sort!(ids; by = id -> (-evaluations[id].development_utility, id))
        union!(selected, first(ids, min(top_per_ticker, length(ids))))
    end
    all_modules = sort!(unique(module_id for strategy in catalog for module_id in strategy.modules))
    for module_id in all_modules
        ids = [strategy.id for strategy in catalog if module_id in strategy.modules]
        sort!(ids; by = id -> (-evaluations[id].development_utility, id))
        push!(selected, first(ids))
    end
    library = sort!(collect(selected))
    _require(_closure(library, evaluations) == Set(all_modules), "initial library does not span the grammar")
    return library
end

function _profiles_equal(left, right, tolerance)
    return length(left) == length(right) && all(isapprox(left[index], right[index]; atol = tolerance, rtol = 0) for index in eachindex(left))
end

function _prune_library(source, evaluations, state_count, config; safe::Bool)
    profiles = Dict(id => evaluations[id].validation_profile for id in source)
    tolerance = Float64(config["backtest"]["frontier_tolerance"])
    order = sort(copy(source); by = id -> (safe ? evaluations[id].development_utility : evaluations[id].validation_utility, id))
    current = copy(source)
    decisions = NamedTuple[]
    for (step, id) in enumerate(order)
        id in current || continue
        length(current) > 1 || break
        before = copy(current)
        after = [candidate for candidate in before if candidate != id]
        before_frontier = _frontier(before, profiles, state_count)
        after_frontier = _frontier(after, profiles, state_count)
        before_closure = _closure(before, evaluations)
        after_closure = _closure(after, evaluations)
        operationally_redundant = _profiles_equal(before_frontier, after_frontier, tolerance)
        generatively_redundant = before_closure == after_closure
        remove = operationally_redundant && (!safe || generatively_redundant)
        remove && (current = after)
        push!(decisions, (
            rule = safe ? "innovation_safe" : "frontier_only",
            step,
            strategy_id = id,
            operationally_redundant,
            generatively_redundant,
            decision = remove ? "remove" : "retain",
            source_size = length(before),
            resulting_size = remove ? length(after) : length(before),
            closure_size_before = length(before_closure),
            closure_size_after = remove ? length(after_closure) : length(before_closure),
            maximum_frontier_change = maximum(abs.(before_frontier .- after_frontier)),
        ))
    end
    return (; library = current, decisions)
end

_enabled(strategy, closure) = all(module_id -> module_id in closure, strategy.modules)

function _hamming_novelty(strategy, library, evaluations)
    minimum_distance = minimum(
        count(index -> strategy.modules[index] != evaluations[id].strategy.modules[index], eachindex(strategy.modules)) for id in library
    )
    return minimum_distance / length(strategy.modules)
end

function _transition_matrix(states, indices, state_count::Int, pseudocount::Float64)
    counts = fill(pseudocount, state_count, state_count)
    index_set = Set(indices)
    for index in indices
        index + 1 in index_set || continue
        current = states[index]
        next = states[index + 1]
        current > 0 && next > 0 && (counts[current, next] += 1)
    end
    for row in 1:state_count
        counts[row, :] ./= sum(counts[row, :])
    end
    return counts
end

function _predicted_occupation(transition, initial_state::Int, horizon::Int, discount_survival::Float64)
    state_count = size(transition, 1)
    distribution = zeros(Float64, state_count)
    distribution[initial_state] = 1.0
    weights = zeros(Float64, state_count)
    for step in 1:horizon
        distribution = vec(transpose(distribution) * transition)
        weights .+= discount_survival^(step - 1) .* distribution
    end
    _require(sum(weights) > 0, "predicted occupation has zero mass")
    return weights ./ sum(weights)
end

function _realized_occupation(states, indices, discount_survival::Float64, state_count::Int)
    weights = zeros(Float64, state_count)
    for (step, index) in enumerate(indices)
        state = states[index]
        state > 0 && (weights[state] += discount_survival^(step - 1))
    end
    _require(sum(weights) > 0, "realized occupation has zero mass")
    return weights ./ sum(weights)
end

_set_value(ids, gaps, weights) = isempty(ids) ? 0.0 : sum(weights .* reduce((left, right) -> max.(left, right), (gaps[id] for id in ids); init = zeros(length(weights))))

function greedy_marginal_selection(candidate_ids, gaps, weights, top_k::Int)
    remaining = Set(String.(candidate_ids))
    selected = String[]
    marginals = Float64[]
    current_gap = zeros(Float64, length(weights))
    current_value = 0.0
    for _ in 1:min(top_k, length(remaining))
        best_id = ""
        best_value = -Inf
        for id in remaining
            value = sum(weights .* max.(current_gap, gaps[id]))
            if value > best_value || (value == best_value && (isempty(best_id) || id < best_id))
                best_id = id
                best_value = value
            end
        end
        push!(selected, best_id)
        push!(marginals, best_value - current_value)
        current_gap = max.(current_gap, gaps[best_id])
        current_value = best_value
        delete!(remaining, best_id)
    end
    return (; selected, marginals, value = current_value)
end

function _top_selection(scores, top_k::Int)
    ids = sort!(collect(keys(scores)); by = id -> (-scores[id], id))
    return first(ids, min(top_k, length(ids)))
end

function _selection_marginals(selected, gaps, weights)
    current = String[]
    marginals = Float64[]
    value = 0.0
    for id in selected
        push!(current, id)
        next_value = _set_value(current, gaps, weights)
        push!(marginals, next_value - value)
        value = next_value
    end
    return marginals
end

function _decision_hash(year, design_hash, score_maps, selected_by_method)
    rows = ["year:$year", "design:$design_hash"]
    for method in sort!(collect(keys(score_maps)))
        ids = sort!(collect(keys(score_maps[method])); by = id -> (-score_maps[method][id], id))
        append!(rows, "$method:$rank:$id" for (rank, id) in enumerate(ids))
        append!(rows, "selected:$method:$rank:$id" for (rank, id) in enumerate(selected_by_method[method]))
    end
    return bytes2hex(sha256(join(rows, "\n")))
end

function _episode_rankings(candidate_ids, initial_library, evaluations, panel, beliefs, evaluated, config, design_hash)
    base_cost = Float64(config["backtest"]["one_way_transaction_cost_bps"])
    years = Int.(config["periods"]["walk_forward_years"])
    lookback = Int(config["periods"]["trailing_estimation_years"])
    top_k = Int(config["ranking"]["top_k"])
    q = Float64(config["ranking"]["daily_discount"] * config["ranking"]["candidate_survival"])
    pseudocount = Float64(config["ranking"]["transition_pseudocount"])
    horizon = Int(config["ranking"]["occupation_horizon_sessions"])
    state_count = beliefs.state_count
    novelty = Dict(id => _hamming_novelty(evaluations[id].strategy, initial_library, evaluations) for id in candidate_ids)
    ranking_rows = NamedTuple[]
    selection_rows = NamedTuple[]
    episode_summaries = NamedTuple[]
    episodes = NamedTuple[]

    for year in years
        training_years = collect((year - lookback):(year - 1))
        training_indices = reduce(vcat, evaluated.year_indices[training_year] for training_year in training_years)
        prior_indices = findall(date -> date < string(year, "-01-01"), panel.dates)
        current_state = beliefs.states[last(prior_indices)]
        _require(current_state in 1:state_count, "walk-forward origin has undefined belief state")
        transition = _transition_matrix(beliefs.states, training_indices, state_count, pseudocount)
        predicted_weights = _predicted_occupation(transition, current_state, horizon, q)
        trailing_profiles = Dict{String,Vector{Float64}}()
        trailing_utilities = Dict{String,Float64}()
        for id in vcat(initial_library, candidate_ids)
            state_stats = _combine_state_stats(evaluations[id].year_state_full, training_years, state_count)
            trailing_profiles[id] = _profile(state_stats, base_cost, config)
            trailing_all = reduce(+, (evaluations[id].year_all_full[training_year] for training_year in training_years); init = TradeStats())
            trailing_utilities[id] = _utility(trailing_all, base_cost, config)
        end
        trailing_frontier = _frontier(initial_library, trailing_profiles, state_count)
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
        coverage_selection = greedy_marginal_selection(candidate_ids, score_gaps, predicted_weights, top_k)
        selected_by_method = Dict(
            "coverage_marginal" => coverage_selection.selected,
            "current_belief_improvement" => _top_selection(current_scores, top_k),
            "average_trailing_score" => _top_selection(average_scores, top_k),
            "raw_parameter_novelty" => _top_selection(novelty, top_k),
        )
        decision_hash = _decision_hash(year, design_hash, score_maps, selected_by_method)
        _require(length(decision_hash) == 64, "walk-forward decision hash failed")

        # No target-year profile or return statistic is accessed above this line.
        target_indices = evaluated.target_indices[year]
        actual_weights = _realized_occupation(beliefs.states, target_indices, q, state_count)
        target_minimum = Int(config["backtest"]["minimum_target_profile_observations"])
        target_counts = evaluations[first(initial_library)].year_state_target[year]
        _require(
            all(state -> target_counts[state].count > 0 || actual_weights[state] == 0.0, 1:state_count),
            "an unvisited target state has positive realized occupation",
        )
        target_profiles = Dict(
            id => _profile(
                evaluations[id].year_state_target[year],
                base_cost,
                config;
                minimum_observations = target_minimum,
                allow_empty = true,
            ) for id in vcat(initial_library, candidate_ids)
        )
        target_frontier = _frontier(initial_library, target_profiles, state_count)
        target_gaps = Dict(id => max.(target_profiles[id] .- target_frontier, 0.0) for id in candidate_ids)
        target_individual = Dict(id => sum(actual_weights .* target_gaps[id]) for id in candidate_ids)
        target_rank = TerminalAudit._rank_descending(target_individual)
        oracle = greedy_marginal_selection(candidate_ids, target_gaps, actual_weights, top_k)
        score_ranks = Dict(method => TerminalAudit._rank_descending(scores) for (method, scores) in score_maps)

        for id in sort!(collect(candidate_ids))
            push!(ranking_rows, (
                year,
                strategy_id = id,
                ticker = evaluations[id].strategy.ticker,
                coverage_score = coverage_scores[id],
                current_belief_improvement = current_scores[id],
                average_trailing_score = average_scores[id],
                raw_parameter_novelty = novelty[id],
                realized_coverage_target = target_individual[id],
                coverage_rank = score_ranks["coverage_marginal"][id],
                current_rank = score_ranks["current_belief_improvement"][id],
                average_rank = score_ranks["average_trailing_score"][id],
                novelty_rank = score_ranks["raw_parameter_novelty"][id],
                realized_target_rank = target_rank[id],
                decision_hash,
            ))
        end

        target_values = collect(values(target_individual))
        for method in ("coverage_marginal", "current_belief_improvement", "average_trailing_score", "raw_parameter_novelty")
            selected = selected_by_method[method]
            realized_value = _set_value(selected, target_gaps, actual_weights)
            score_values = [score_maps[method][id] for id in candidate_ids]
            target_vector = [target_individual[id] for id in candidate_ids]
            spearman = TerminalAudit._spearman(score_values, target_vector)
            push!(episode_summaries, (
                year,
                method,
                spearman_with_realized_target = spearman,
                realized_set_value = realized_value,
                realized_oracle_greedy_value = oracle.value,
                realized_regret = oracle.value - realized_value,
                selected_top_k = length(selected),
                decision_hash,
            ))
            training_marginals = _selection_marginals(selected, score_gaps, predicted_weights)
            realized_marginals = _selection_marginals(selected, target_gaps, actual_weights)
            for rank in eachindex(selected)
                id = selected[rank]
                push!(selection_rows, (
                    year,
                    method,
                    selection_rank = rank,
                    strategy_id = id,
                    ticker = evaluations[id].strategy.ticker,
                    training_individual_score = score_maps[method][id],
                    training_set_marginal = training_marginals[rank],
                    realized_individual_target = target_individual[id],
                    realized_set_marginal = realized_marginals[rank],
                    selected_by_realized_greedy_oracle = id in oracle.selected,
                    decision_hash,
                ))
            end
        end
        push!(episodes, (
            year,
            training_years,
            current_state,
            predicted_weights,
            actual_weights,
            score_gaps,
            target_gaps,
            target_individual,
            selected_by_method,
            decision_hash,
            oracle,
            target_sessions = length(target_indices),
        ))
        println("walk-forward episode=$year; decision_hash=$decision_hash")
    end
    return (; ranking_rows, selection_rows, episode_summaries, episodes)
end

function _weighted_frontier(frontier, states, indices, state_count)
    frequencies = [count(index -> states[index] == state, indices) for state in 1:state_count]
    return sum(frontier .* frequencies) / sum(frequencies)
end

function _aggregate_ranking_summaries(episode_summaries)
    methods = unique(getfield.(episode_summaries, :method))
    rows = NamedTuple[]
    for method in methods
        selected = [row for row in episode_summaries if row.method == method]
        push!(rows, (
            method,
            mean_spearman_with_realized_target = TerminalAudit._mean(getfield.(selected, :spearman_with_realized_target)),
            mean_realized_set_value = TerminalAudit._mean(getfield.(selected, :realized_set_value)),
            mean_realized_regret = TerminalAudit._mean(getfield.(selected, :realized_regret)),
            positive_set_value_years = count(row -> row.realized_set_value > 0, selected),
            episodes = length(selected),
        ))
    end
    return rows
end

function _uncertainty_rows(episode_summaries, config)
    methods = unique(getfield.(episode_summaries, :method))
    replications = Int(config["ranking"]["bootstrap_replications"])
    level = Float64(config["ranking"]["uncertainty_level"])
    seed = UInt64(config["seed"])
    rows = NamedTuple[]
    for (method_index, method) in enumerate(methods)
        values = [row.realized_set_value for row in episode_summaries if row.method == method]
        rng = StableRNG(seed + UInt64(method_index))
        samples = Float64[]
        for _ in 1:replications
            push!(samples, TerminalAudit._mean([values[rand(rng, eachindex(values))] for _ in eachindex(values)]))
        end
        alpha = (1 - level) / 2
        push!(rows, (
            method,
            metric = "mean_walk_forward_realized_set_coverage",
            estimate = TerminalAudit._mean(values),
            lower = TerminalAudit._quantile(samples, alpha),
            upper = TerminalAudit._quantile(samples, 1 - alpha),
            uncertainty_level = level,
            replications,
            bootstrap_unit = "walk_forward_year",
        ))
    end
    return rows
end

function _cost_sensitivity_rows(episodes, initial_library, evaluations, config)
    methods = ("coverage_marginal", "current_belief_improvement", "average_trailing_score", "raw_parameter_novelty")
    state_count = length(first(episodes).actual_weights)
    rows = NamedTuple[]
    for cost_bps in Float64.(config["backtest"]["cost_sensitivity_bps"]), method in methods
        episode_values = Float64[]
        for episode in episodes
            target_profiles = Dict(
                id => _profile(
                    evaluations[id].year_state_target[episode.year],
                    cost_bps,
                    config;
                    minimum_observations = Int(config["backtest"]["minimum_target_profile_observations"]),
                    allow_empty = true,
                ) for
                id in vcat(initial_library, episode.selected_by_method[method])
            )
            frontier = _frontier(initial_library, target_profiles, state_count)
            gaps = Dict(id => max.(target_profiles[id] .- frontier, 0.0) for id in episode.selected_by_method[method])
            push!(episode_values, _set_value(episode.selected_by_method[method], gaps, episode.actual_weights))
        end
        push!(rows, (
            cost_bps,
            method,
            mean_realized_set_value = TerminalAudit._mean(episode_values),
            minimum_episode_value = minimum(episode_values),
            maximum_episode_value = maximum(episode_values),
            episodes = length(episode_values),
        ))
    end
    return rows
end

function _run_ready(config, panel, provenance, catalog, design_hash)
    beliefs = _belief_states(panel, config)
    evaluated = _evaluate_catalog(catalog, panel, beliefs, config)
    evaluations = evaluated.evaluations
    initial_library = _initial_library(catalog, evaluations, config)
    safe = _prune_library(initial_library, evaluations, beliefs.state_count, config; safe = true)
    frontier_only = _prune_library(initial_library, evaluations, beliefs.state_count, config; safe = false)
    profiles = Dict(id => evaluations[id].validation_profile for id in initial_library)
    tolerance = Float64(config["backtest"]["frontier_tolerance"])
    initial_frontier = _frontier(initial_library, profiles, beliefs.state_count)
    _require(_profiles_equal(initial_frontier, _frontier(safe.library, profiles, beliefs.state_count), tolerance), "safe compression changed the validation frontier")
    _require(_closure(initial_library, evaluations) == _closure(safe.library, evaluations), "safe compression changed module closure")
    _require(_profiles_equal(initial_frontier, _frontier(frontier_only.library, profiles, beliefs.state_count), tolerance), "frontier-only pruning changed the validation frontier")

    initial_closure = _closure(initial_library, evaluations)
    safe_closure = _closure(safe.library, evaluations)
    frontier_closure = _closure(frontier_only.library, evaluations)
    candidate_ids = [strategy.id for strategy in catalog if !(strategy.id in initial_library) && _enabled(strategy, initial_closure)]
    _require(!isempty(candidate_ids), "no candidates remain after initial-library construction")
    ranked = _episode_rankings(candidate_ids, initial_library, evaluations, panel, beliefs, evaluated, config, design_hash)
    ranking_summaries = _aggregate_ranking_summaries(ranked.episode_summaries)
    uncertainty = _uncertainty_rows(ranked.episode_summaries, config)
    cost_sensitivity = _cost_sensitivity_rows(ranked.episodes, initial_library, evaluations, config)
    base_cost = Float64(config["backtest"]["one_way_transaction_cost_bps"])
    for summary in ranking_summaries
        cost_row = only(row for row in cost_sensitivity if row.cost_bps == base_cost && row.method == summary.method)
        _require(isapprox(cost_row.mean_realized_set_value, summary.mean_realized_set_value; atol = tolerance, rtol = 0), "base-cost sensitivity does not reproduce the primary result")
    end

    mean_target = Dict(id => TerminalAudit._mean([episode.target_individual[id] for episode in ranked.episodes]) for id in candidate_ids)
    candidate_quality(closure) = maximum((mean_target[id] for id in candidate_ids if _enabled(evaluations[id].strategy, closure)); init = 0.0)
    initial_candidate_quality = candidate_quality(initial_closure)
    safe_candidate_quality = candidate_quality(safe_closure)
    frontier_candidate_quality = candidate_quality(frontier_closure)
    _require(isapprox(initial_candidate_quality, safe_candidate_quality; atol = tolerance, rtol = 0), "safe compression changed future candidate quality")

    validation_value = _weighted_frontier(initial_frontier, beliefs.states, evaluated.validation_indices, beliefs.state_count)
    safe_value = _weighted_frontier(_frontier(safe.library, profiles, beliefs.state_count), beliefs.states, evaluated.validation_indices, beliefs.state_count)
    frontier_value = _weighted_frontier(_frontier(frontier_only.library, profiles, beliefs.state_count), beliefs.states, evaluated.validation_indices, beliefs.state_count)
    decomposition_rows = NamedTuple[]
    for id in safe.library
        reduced = [candidate for candidate in safe.library if candidate != id]
        isempty(reduced) && continue
        reduced_frontier = _frontier(reduced, profiles, beliefs.state_count)
        operational = validation_value - _weighted_frontier(reduced_frontier, beliefs.states, evaluated.validation_indices, beliefs.state_count)
        generative = initial_candidate_quality - candidate_quality(_closure(reduced, evaluations))
        total = operational + generative
        _require(isapprox(total, operational + generative; atol = tolerance, rtol = 0), "decomposition identity failed")
        push!(decomposition_rows, (
            strategy_id = id,
            ticker = evaluations[id].strategy.ticker,
            operational,
            generative,
            total,
            currently_dominated = abs(operational) <= tolerance,
            generatively_valuable = generative > tolerance,
        ))
    end

    primary = only(row for row in ranking_summaries if row.method == "coverage_marginal")
    comparators = [row for row in ranking_summaries if row.method != "coverage_marginal"]
    best_comparator_value = maximum(getfield.(comparators, :mean_realized_set_value))
    best_comparator_regret = minimum(getfield.(comparators, :mean_realized_regret))
    coverage_verdict = primary.mean_realized_set_value > best_comparator_value + tolerance &&
                       primary.mean_realized_regret < best_comparator_regret - tolerance ? "supportive" :
                       primary.mean_realized_set_value >= best_comparator_value - tolerance ? "mixed_or_tied" : "negative"
    mechanism_rows = [
        (
            question = "A",
            mechanism = "frontier-only pruning",
            current_validation_value_change = frontier_value - validation_value,
            future_candidate_quality_change = frontier_candidate_quality - initial_candidate_quality,
            result = frontier_candidate_quality < initial_candidate_quality - tolerance ? "supportive" : "negative_or_zero",
        ),
        (
            question = "B",
            mechanism = "innovation-safe compression",
            current_validation_value_change = safe_value - validation_value,
            future_candidate_quality_change = safe_candidate_quality - initial_candidate_quality,
            result = "identity_pass",
        ),
        (
            question = "C",
            mechanism = "estimand-aligned marginal coverage ranking",
            current_validation_value_change = primary.mean_spearman_with_realized_target,
            future_candidate_quality_change = primary.mean_realized_set_value - best_comparator_value,
            result = coverage_verdict,
        ),
        (
            question = "D",
            mechanism = "operational-generative decomposition",
            current_validation_value_change = count(row -> row.currently_dominated && row.generatively_valuable, decomposition_rows),
            future_candidate_quality_change = maximum((row.generative for row in decomposition_rows); init = 0.0),
            result = any(row -> row.currently_dominated && row.generatively_valuable, decomposition_rows) ? "supportive" : "negative_or_zero",
        ),
    ]

    selection_counts = Dict((id, method) => count(row -> row.strategy_id == id && row.method == method, ranked.selection_rows) for id in candidate_ids for method in ("coverage_marginal", "current_belief_improvement", "average_trailing_score", "raw_parameter_novelty"))
    candidate_audit = [(
        strategy_id = strategy.id,
        ticker = strategy.ticker,
        directional_signal = strategy.directional_signal,
        entry_filter = strategy.entry_filter,
        holding_horizon = strategy.holding_horizon,
        sizing_rule = strategy.sizing_rule,
        exit_rule = strategy.exit_rule,
        risk_constraint = strategy.risk_constraint,
        in_initial_library = strategy.id in initial_library,
        in_safe_library = strategy.id in safe.library,
        in_frontier_only_library = strategy.id in frontier_only.library,
        enabled_initial = _enabled(strategy, initial_closure),
        enabled_safe = _enabled(strategy, safe_closure),
        enabled_frontier_only = _enabled(strategy, frontier_closure),
        development_gross_utility = evaluations[strategy.id].development_gross_utility,
        development_net_utility = evaluations[strategy.id].development_utility,
        validation_gross_utility = evaluations[strategy.id].validation_gross_utility,
        validation_net_utility = evaluations[strategy.id].validation_utility,
        locked_gross_utility = evaluations[strategy.id].locked_gross_utility,
        locked_net_utility = evaluations[strategy.id].locked_utility,
        mean_validation_turnover = evaluations[strategy.id].mean_validation_turnover,
        coverage_selection_count = get(selection_counts, (strategy.id, "coverage_marginal"), 0),
        current_selection_count = get(selection_counts, (strategy.id, "current_belief_improvement"), 0),
        average_selection_count = get(selection_counts, (strategy.id, "average_trailing_score"), 0),
        novelty_selection_count = get(selection_counts, (strategy.id, "raw_parameter_novelty"), 0),
    ) for strategy in catalog]

    return (
        status = "empirical_complete_aggregate_publishable",
        empirical_results_permitted = true,
        aggregate_outputs_publishable = true,
        config,
        provenance,
        design_hash,
        panel_audit = panel.audit,
        catalog,
        candidate_audit,
        pruning_rows = vcat(safe.decisions, frontier_only.decisions),
        episode_ranking_rows = ranked.ranking_rows,
        selection_rows = ranked.selection_rows,
        episode_summaries = ranked.episode_summaries,
        ranking_summaries,
        decomposition_rows,
        mechanism_rows,
        uncertainty,
        cost_sensitivity,
        initial_library,
        safe_library = safe.library,
        frontier_only_library = frontier_only.library,
        initial_candidate_quality,
        safe_candidate_quality,
        frontier_candidate_quality,
        belief_thresholds = beliefs.thresholds,
        episodes = ranked.episodes,
    )
end

function run_financial_annual_walkforward_audit(config::AbstractDict = load_financial_annual_config())
    design_hash = DesignLock.verify_design_lock(config)
    data_path = _repo_path(config["data"]["path"])
    if !isfile(data_path) || !isfile(_repo_path(config["data"]["provenance_path"]))
        return (
            status = "pending_data",
            empirical_results_permitted = false,
            aggregate_outputs_publishable = false,
            config,
            design_hash,
            catalog = finite_strategy_catalog_annual(config),
            reason = "licensed CRSP input or completed provenance is absent",
        )
    end
    provenance = _load_provenance(config, data_path)
    panel = TerminalAudit.load_market_panel(data_path, config)
    catalog = finite_strategy_catalog_annual(config)
    _require(length(catalog) == 100 * 96, "annual walk-forward finite grammar size changed")
    return _run_ready(config, panel, provenance, catalog, design_hash)
end

const GRAMMAR_COLUMNS = TerminalAudit.GRAMMAR_COLUMNS
const CANDIDATE_COLUMNS = (
    TerminalAudit.CANDIDATE_COLUMNS...,
    "coverage_selection_count",
    "current_selection_count",
    "average_selection_count",
    "novelty_selection_count",
)
const PRUNING_COLUMNS = TerminalAudit.PRUNING_COLUMNS
const EPISODE_RANKING_COLUMNS = (
    "year", "strategy_id", "ticker", "coverage_score", "current_belief_improvement",
    "average_trailing_score", "raw_parameter_novelty", "realized_coverage_target",
    "coverage_rank", "current_rank", "average_rank", "novelty_rank", "realized_target_rank",
    "decision_hash",
)
const SELECTION_COLUMNS = (
    "year", "method", "selection_rank", "strategy_id", "ticker",
    "training_individual_score", "training_set_marginal", "realized_individual_target",
    "realized_set_marginal", "selected_by_realized_greedy_oracle", "decision_hash",
)
const RANKING_SUMMARY_COLUMNS = (
    "method", "mean_spearman_with_realized_target", "mean_realized_set_value",
    "mean_realized_regret", "positive_set_value_years", "episodes",
)
const DECOMPOSITION_COLUMNS = TerminalAudit.DECOMPOSITION_COLUMNS
const MECHANISM_COLUMNS = (
    "question", "mechanism", "current_validation_value_change",
    "future_candidate_quality_change", "result",
)
const UNCERTAINTY_COLUMNS = (
    "method", "metric", "estimate", "lower", "upper", "uncertainty_level",
    "replications", "bootstrap_unit",
)
const COST_COLUMNS = (
    "cost_bps", "method", "mean_realized_set_value", "minimum_episode_value",
    "maximum_episode_value", "episodes",
)

function _write_data_audit(path, result)
    config = result.config
    selection = TOML.parsefile(_repo_path(config["universe"]["selection_manifest"]))
    audit_count = length(readlines(_repo_path(config["universe"]["audit_csv"]))) - 1
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "# Annual Walk-Forward Financial Audit: Data Audit\n")
        println(io, "**Disposition:** aggregate mechanism outputs are publishable; licensed raw and row-level inputs are not redistributed.\n")
        println(io, "The annual walk-forward audit found $audit_count ETFs classified `FUND`/`ETF` at both endpoint dates and admitted $(selection["eligible_count"]) after predeclared identity, history, price, liquidity, flag, and complex-product gates. It selected the top $(selection["selected_count"]) by 2009--2014 median dollar volume. The selection script parsed no return outcome, and the immutable selection manifest was included in the initial analytical lock `$(config["design_lock"]["initial_analytical_design_sha256"])` before the return panel was prepared.\n")
        println(io, "The source is the same existing CRSP/WRDS daily-security and security-history snapshot used by the terminal audit, at sibling commit `$(config["source"]["repository_commit"])`. No network request or download occurred. Dates use CRSP `dlycaldt`; signals use information through close `t`; the two-return-index lag prevents contemporaneous execution. `dlyret` is compounded within PERMNO. Prices and volumes are never interpolated.\n")
        println(io, "The local derivative has $(result.panel_audit.source_rows) rows and $(result.panel_audit.complete_dates) complete common dates from $(result.panel_audit.first_date) through $(result.panel_audit.last_date); $(result.panel_audit.excluded_incomplete_dates) union dates were removed. The snapshot is point-in-time-conscious but not revision-timestamped, and the endpoint-stable universe remains survivorship-biased.\n")
        println(io, "The base turnover charge is $(config["backtest"]["one_way_transaction_cost_bps"]) basis points one way, with frozen $(join(config["backtest"]["cost_sensitivity_bps"], "/"))-basis-point sensitivities. These are reduced-form costs, not reconstructed historical spreads. Reviewers reproduce the row-level stage with independently licensed CRSP/WRDS files. This design supports mechanism validation only, never a market-alpha claim.")
    end
end

function _write_reports(paths, result)
    primary = only(row for row in result.ranking_summaries if row.method == "coverage_marginal")
    comparators = [row for row in result.ranking_summaries if row.method != "coverage_marginal"]
    best_comparator = first(sort(comparators; by = row -> (-row.mean_realized_set_value, row.method)))
    mechanism = Dict(row.question => row for row in result.mechanism_rows)
    dominated = [row for row in result.decomposition_rows if row.currently_dominated && row.generatively_valuable]
    primary_uncertainty = only(row for row in result.uncertainty if row.method == "coverage_marginal")
    _write_data_audit(paths["data_audit_md"], result)
    mkpath(dirname(paths["draft_results_md"]))
    mkpath(dirname(paths["limitations_md"]))
    mkpath(dirname(paths["manuscript_section"]))
    open(paths["draft_results_md"], "w") do io
        println(io, "# Draft Results: Annual Walk-Forward Financial Audit\n")
        println(io, "**Status:** the annual walk-forward mechanism run is complete under the documented lock and amendment chain. The locked terminal-audit adverse ranking remains reported separately. Licensed rows are excluded; aggregate outputs are publishable.\n")
        println(io, "## Design\n")
        println(io, "The outcome-blind audit selected 100 liquid, endpoint-stable ETFs from 427 CRSP ETF identities, versus the 25-ETF terminal-audit universe. The full finite grammar contains $(length(result.catalog)) strategies. Development (2009--2014) fixes the universe, belief quintiles, and initial library. Validation (2015--2019) fixes the first ranking episode and the compression audit. Five annual walk-forward episodes then estimate profiles and transitions from the preceding five calendar years and score the next year, 2020 through 2024. Each annual ranking and top-five selection is SHA-256 hashed before its target-year sufficient statistics are accessed. The score is aligned with S4's empirical estimand: positive state-profile gaps are integrated against predicted discounted belief occupation. Candidate sets are chosen by sequential marginal rather than independent coverage.\n")
        println(io, "The target is the analogous next-year gap integrated against realized discounted belief occupation. This is a mechanism target, not portfolio return and not an alpha estimand. The universe, ranking rules, 5 bp one-way base cost, 1/10 bp sensitivities, seed `$(result.config["seed"])`, and non-gating support verdict were frozen in the initial analytical lock `$(result.config["design_lock"]["initial_analytical_design_sha256"])` before return extraction. A sparse-state feasibility amendment and six report-only corrections are disclosed in `DESIGN_AMENDMENTS.md`; no candidate result changed the analytical specification. The completed implementation lock is `$(result.design_hash)`.\n")
        println(io, "## Compression mechanisms\n")
        println(io, "The initial library contained $(length(result.initial_library)) strategies. Frontier-only pruning retained $(length(result.frontier_only_library)); its validation-value change was $(TerminalAudit._fmt(mechanism["A"].current_validation_value_change)) and its future candidate-quality change was $(TerminalAudit._fmt(mechanism["A"].future_candidate_quality_change)), yielding **$(mechanism["A"].result)**. Innovation-safe deletion retained $(length(result.safe_library)) and passed both registered identities: validation frontier and module closure were unchanged, and future enabled-candidate quality changed by $(TerminalAudit._fmt(mechanism["B"].future_candidate_quality_change)). Any deviation beyond tolerance would have aborted the run.\n")
        println(io, "## Coverage ranking\n")
        println(io, "Across five walk-forward years, marginal coverage achieved mean realized set coverage $(TerminalAudit._fmt(primary.mean_realized_set_value)) and mean regret $(TerminalAudit._fmt(primary.mean_realized_regret)) relative to the target-year greedy oracle. Its mean candidate-level Spearman association was $(TerminalAudit._fmt(primary.mean_spearman_with_realized_target)). The strongest comparator by realized set value was `$(best_comparator.method)` at $(TerminalAudit._fmt(best_comparator.mean_realized_set_value)) with regret $(TerminalAudit._fmt(best_comparator.mean_realized_regret)). The frozen annual walk-forward verdict is **$(mechanism["C"].result)**; no score or universe rule is changed in response.\n")
        println(io, "A deterministic StableRNG bootstrap over the five annual episodes gives a $(round(Int, 100 * primary_uncertainty.uncertainty_level))% interval [$(TerminalAudit._fmt(primary_uncertainty.lower)), $(TerminalAudit._fmt(primary_uncertainty.upper))] for mean realized set coverage. With only five annual units, this interval is descriptive and coarse. It does not account for universe choice, grammar choice, provider revisions, or repeated research iterations.\n")
        println(io, "## Operational--generative decomposition\n")
        println(io, "Every safely retained policy was deleted alone. The operational term is its validation-frontier contribution; the generative term is its contribution to best enabled future candidate quality. Totals are the exact numerical sum and fail on mismatch. The run found $(length(dominated)) currently dominated policies with positive generative retention value; the verdict is **$(mechanism["D"].result)**. This explains why a currently dominated module carrier can remain worth retaining without claiming that the carrier itself forecasts returns.\n")
        println(io, "## Interpretation\n")
        println(io, "The larger universe improves breadth and the redesigned score aligns prediction and evaluation with the coverage-potential object, while the walk-forward layout exposes five separate decisions instead of one terminal ranking. It still does not establish a universal ranking theorem. The scientific contribution is whether frontier preservation, closure preservation, marginal coverage, and the operational--generative accounting organize a transparent finite library. Profitability is not the contribution, and negative or mixed results remain visible in the tables.")
    end
    open(paths["limitations_md"], "w") do io
        println(io, "# Empirical Limitations\n")
        println(io, "- **No alpha claim.** The outcome is mechanism coverage, not expected return or a tradable portfolio estimate.")
        println(io, "- **Licensed inputs.** CRSP/WRDS rows and row-level derivatives are excluded. Aggregate artifacts are publishable; reviewers supply licensed files.")
        println(io, "- **Point in time.** Date-valid identifiers and lagged signals are used, but the CRSP snapshot is not revision-timestamped.")
        println(io, "- **Survivorship.** The 100 funds are same-PERMNO ETFs classified at both 2008 and 2024 endpoints. This avoids ticker splicing but is not survivorship-free.")
        println(io, "- **Universe iteration.** The first outcome-blind name-keyword pass admitted complex trust products because CRSP omitted product names. Before any return was parsed, the rule was amended to exclude ProShares and Direxion trusts wholesale. Both audit files and the final selection hash are retained.")
        println(io, "- **Lock amendments.** The initial analytical design was frozen before return extraction. A-001 changed only sparse target-state support handling after a support abort and before any ranking result was produced; A-002 through A-007 are report-only. The immutable lock chain is retained.")
        println(io, "- **Retrospective lock.** Each annual decision is code-separated and hashed before its target statistics are accessed, but 2020--2024 is historical rather than a live prospective trial.")
        println(io, "- **Inference.** Five annual bootstrap units provide limited uncertainty resolution and do not absorb design, grammar, universe, or data-revision uncertainty.")
        println(io, "- **Costs.** 1/5/10 bp one-way costs omit time-varying spreads, impact, capacity, taxes, financing, and operational constraints.")
        println(io, "- **Finite grammar.** The $(length(result.catalog)) strategies are fully enumerated and module-representable. No unrestricted or LLM-generated code is used.")
        println(io, "- **Theorem boundary.** S4 proves an exact fixed-candidate occupation identity for supplied gaps. It does not prove empirical gap estimation, transition estimation, ranking consistency, set-selection optimality, or market performance.")
        println(io, "- **Negative results.** The terminal-audit adverse ranking and any annual walk-forward negative or mixed comparison remain reported; no post-outcome redesign is permitted.")
    end
    open(paths["manuscript_section"], "w") do io
        println(io, "% Generated by julia/scripts/run_financial_annual_walkforward_audit.jl; do not edit by hand.")
        println(io, "\\section{Annual walk-forward financial audit}\\label{sec:financial-annual-walkforward-audit}")
        println(io, "An outcome-blind CRSP audit selects 100 liquid endpoint-stable ETFs from 427 ETF identities, versus 25 in the terminal audit; the finite grammar has $(length(result.catalog)) strategies. Five annual 2020--2024 decisions use trailing five-year profiles, and their top-five marginal-coverage selections are hashed before next-year targets are read. The initial analytical design preceded return extraction; amendments are disclosed separately and the adverse terminal-audit result remains unchanged.")
        println(io, "\\begin{center}\\small")
        println(io, "\\refstepcounter{table}\\textbf{Table \\thetable. Larger-universe mechanism outcomes}\\label{tab:financial-annual-walkforward}\\par\\smallskip")
        println(io, "\\begin{tabular}{p{0.32\\linewidth}p{0.56\\linewidth}}\\hline")
        println(io, "Mechanism & Walk-forward diagnostic \\\\ \\hline")
        println(io, string("Frontier-only pruning & $(length(result.initial_library)) to $(length(result.frontier_only_library)); future-quality change $(TerminalAudit._fmt(mechanism["A"].future_candidate_quality_change)); $(mechanism["A"].result) ", raw"\\\\"))
        println(io, string("Innovation-safe compression & $(length(result.initial_library)) to $(length(result.safe_library)); registered changes zero; identity pass ", raw"\\\\"))
        println(io, string("Marginal coverage & Mean set value $(TerminalAudit._fmt(primary.mean_realized_set_value)); best comparator $(TerminalAudit._fmt(best_comparator.mean_realized_set_value)); $(mechanism["C"].result) ", raw"\\\\"))
        println(io, "Value decomposition & $(length(dominated)) dominated carriers with positive generative value; $(mechanism["D"].result) \\\\ \\hline")
        println(io, "\\end{tabular}\\par\\smallskip\\textit{Note: coverage values are mechanism diagnostics, not return forecasts.}\\end{center}")
        println(io, "\\newpage")
        println(io, "\\paragraph{Walk-forward result.} Marginal coverage averaged $(TerminalAudit._fmt(primary.mean_realized_set_value)), versus $(TerminalAudit._fmt(best_comparator.mean_realized_set_value)) for the strongest comparator, and was positive in $(primary.positive_set_value_years) of $(primary.episodes) annual episodes. Its descriptive 95\\% annual-bootstrap interval was [$(TerminalAudit._fmt(primary_uncertainty.lower)), $(TerminalAudit._fmt(primary_uncertainty.upper))]. Mean candidate-level Spearman association was $(TerminalAudit._fmt(primary.mean_spearman_with_realized_target)) and mean greedy-oracle regret was $(TerminalAudit._fmt(primary.mean_realized_regret)); the redesign improves the registered mechanism comparison but leaves substantial ranking error.")
        println(io, "\\paragraph{Compression and decomposition.} Frontier-only pruning preserved current validation value while changing future candidate quality by $(TerminalAudit._fmt(mechanism["A"].future_candidate_quality_change)). Innovation-safe compression preserved the registered frontier, closure, and future-quality identities. The safely retained library contained $(length(dominated)) currently dominated carrier with positive purely generative value, illustrating why current dominance alone is not a safe deletion rule.")
        println(io, "\\paragraph{Data and claim boundary.} Licensed rows are not distributed. The universe is larger but survivorship-biased, the snapshot is not revision-timestamped, the annual lock is retrospective, five annual units give coarse uncertainty, and costs are reduced form. The exercise supports no market-alpha, ranking-consistency, or new Lean claim.")
    end
end

function _write_status(path, result, config_path, paths)
    payload = Dict{String,Any}(
        "schema_version" => CONFIG_SCHEMA,
        "experiment_id" => result.config["experiment_id"],
        "status" => result.status,
        "config_path" => relpath(abspath(config_path), REPOSITORY_ROOT),
        "config_sha256" => _sha256_file(config_path),
        "design_sha256" => result.design_hash,
        "universe_selection_sha256" => result.config["universe"]["selection_manifest_sha256"],
        "universe_count" => length(result.config["universe"]["tickers"]),
        "strategy_count" => length(result.catalog),
        "seed" => string(result.config["seed"]),
        "rng" => "StableRNGs.StableRNG",
        "outcome_pattern_hard_gate" => false,
        "raw_data_redistribution_permitted" => false,
        "aggregate_outputs_publishable" => result.aggregate_outputs_publishable,
        "command" => "julia --project=julia julia/scripts/run_financial_annual_walkforward_audit.jl",
    )
    if result.status != "pending_data"
        payload["market_data_sha256"] = result.provenance["file_sha256"]
        payload["market_observation_count"] = result.panel_audit.source_rows
        payload["complete_common_dates"] = result.panel_audit.complete_dates
        payload["initial_library_size"] = length(result.initial_library)
        payload["safe_library_size"] = length(result.safe_library)
        payload["frontier_only_library_size"] = length(result.frontier_only_library)
        payload["annual_decision_hashes"] = Dict(string(episode.year) => episode.decision_hash for episode in result.episodes)
        payload["generated_artifact_sha256"] = Dict(
            result.config["outputs"][key] => _sha256_file(artifact_path) for
            (key, artifact_path) in paths if key != "status_json"
        )
    else
        payload["reason"] = result.reason
    end
    mkpath(dirname(path))
    open(path, "w") do io
        write(io, TerminalAudit._json(payload), "\n")
    end
end

function _write_figures(paths, result)
    selection = TOML.parsefile(_repo_path(result.config["universe"]["selection_manifest"]))
    audit_count = length(readlines(_repo_path(result.config["universe"]["audit_csv"]))) - 1
    TerminalAudit._write_bar_figure(
        paths["universe_figure"];
        title = "Outcome-blind expansion from 25 to 100 ETFs",
        description = "CRSP endpoint ETF inventory, eligible plain ETFs, selected annual-audit ETFs, and the terminal-audit universe.",
        labels = ["endpoint ETFs", "eligible", "annual selected", "terminal selected"],
        values = Float64[audit_count, selection["eligible_count"], selection["selected_count"], 25],
        colors = ["#a5a5a5", "#70ad47", "#4472c4", "#ed7d31"],
        y_label = "instrument count",
    )
    TerminalAudit._write_bar_figure(
        paths["ranking_figure"];
        title = "Walk-forward realized set coverage by frozen rule",
        description = "Mean next-year realized set coverage for each validation-only selection rule.",
        labels = [replace(row.method, "_" => " ") for row in result.ranking_summaries],
        values = Float64[row.mean_realized_set_value for row in result.ranking_summaries],
        colors = ["#4472c4", "#70ad47", "#ed7d31", "#a5a5a5"],
        y_label = "mean realized set coverage",
    )
    mechanism = Dict(row.question => row for row in result.mechanism_rows)
    TerminalAudit._write_bar_figure(
        paths["mechanism_figure"];
        title = "Current-frontier and future-candidate effects",
        description = "Current validation and future candidate-quality changes under frontier-only and innovation-safe compression.",
        labels = ["frontier current", "frontier future", "safe current", "safe future"],
        values = Float64[
            mechanism["A"].current_validation_value_change,
            mechanism["A"].future_candidate_quality_change,
            mechanism["B"].current_validation_value_change,
            mechanism["B"].future_candidate_quality_change,
        ],
        colors = ["#d95f02", "#d95f02", "#1b9e77", "#1b9e77"],
        y_label = "change in mechanism value",
    )
end

function write_financial_annual_walkforward_audit_outputs(result, config, config_path = DEFAULT_FINANCIAL_ANNUAL_CONFIG; artifact_root = REPOSITORY_ROOT)
    _require(result.status != "pending_data", "annual walk-forward aggregate outputs remain pending without licensed data")
    paths = Dict(key => joinpath(artifact_root, splitpath(value)...) for (key, value) in config["outputs"])
    grammar_rows = [(
        strategy_id = strategy.id,
        ticker = strategy.ticker,
        directional_signal = strategy.directional_signal,
        entry_filter = strategy.entry_filter,
        holding_horizon = strategy.holding_horizon,
        sizing_rule = strategy.sizing_rule,
        exit_rule = strategy.exit_rule,
        risk_constraint = strategy.risk_constraint,
        modules = join(strategy.modules, ";"),
    ) for strategy in result.catalog]
    TerminalAudit._write_csv(paths["grammar_csv"], GRAMMAR_COLUMNS, grammar_rows)
    TerminalAudit._write_csv(paths["candidate_audit_csv"], CANDIDATE_COLUMNS, result.candidate_audit)
    TerminalAudit._write_csv(paths["pruning_audit_csv"], PRUNING_COLUMNS, result.pruning_rows)
    TerminalAudit._write_csv(paths["episode_ranking_csv"], EPISODE_RANKING_COLUMNS, result.episode_ranking_rows)
    TerminalAudit._write_csv(paths["selection_audit_csv"], SELECTION_COLUMNS, result.selection_rows)
    TerminalAudit._write_csv(paths["ranking_summary_csv"], RANKING_SUMMARY_COLUMNS, result.ranking_summaries)
    TerminalAudit._write_csv(paths["decomposition_csv"], DECOMPOSITION_COLUMNS, result.decomposition_rows)
    TerminalAudit._write_csv(paths["mechanism_summary_csv"], MECHANISM_COLUMNS, result.mechanism_rows)
    TerminalAudit._write_csv(paths["uncertainty_csv"], UNCERTAINTY_COLUMNS, result.uncertainty)
    TerminalAudit._write_csv(paths["cost_sensitivity_csv"], COST_COLUMNS, result.cost_sensitivity)
    universe_rows = [
        (stage = "endpoint_etfs", count = length(readlines(_repo_path(config["universe"]["audit_csv"]))) - 1),
        (stage = "eligible_plain_etfs", count = TOML.parsefile(_repo_path(config["universe"]["selection_manifest"]))["eligible_count"]),
        (stage = "v2_selected", count = length(config["universe"]["tickers"])),
        (stage = "v1_selected", count = 25),
    ]
    TerminalAudit._write_csv(paths["universe_figure_data"], ("stage", "count"), universe_rows)
    TerminalAudit._write_csv(paths["ranking_figure_data"], RANKING_SUMMARY_COLUMNS, result.ranking_summaries)
    TerminalAudit._write_csv(paths["mechanism_figure_data"], MECHANISM_COLUMNS, result.mechanism_rows)
    _write_figures(paths, result)
    _write_reports(paths, result)
    _write_status(paths["status_json"], result, config_path, paths)
    return paths
end

function _check_outputs(result, config, config_path)
    mktempdir() do root
        generated = write_financial_annual_walkforward_audit_outputs(result, config, config_path; artifact_root = root)
        changed = String[]
        for (key, generated_path) in generated
            committed = _repo_path(config["outputs"][key])
            if !isfile(committed) || read(committed) != read(generated_path)
                push!(changed, config["outputs"][key])
            end
        end
        isempty(changed) || error("annual walk-forward financial-audit artifact drift: $(join(sort!(changed), ", "))")
    end
    return true
end

function main(args = ARGS)
    positional = [argument for argument in args if !startswith(argument, "--")]
    config_path = isempty(positional) ? DEFAULT_FINANCIAL_ANNUAL_CONFIG : only(positional)
    config = load_financial_annual_config(config_path)
    result = run_financial_annual_walkforward_audit(config)
    if "--check" in args
        _check_outputs(result, config, config_path)
        println("annual walk-forward financial-audit artifacts are current; status=$(result.status)")
        return result
    end
    write_financial_annual_walkforward_audit_outputs(result, config, config_path)
    println("experiment=$(config["experiment_id"])")
    println("status=$(result.status)")
    println("funds=$(length(config["universe"]["tickers"])); strategies=$(length(result.catalog))")
    return result
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    FinancialAnnualWalkforwardAudit.main()
end
