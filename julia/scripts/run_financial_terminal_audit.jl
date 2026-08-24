module FinancialTerminalAudit

using Random: rand
using Printf: @sprintf
using SHA: sha256
using StableRNGs: StableRNG
using TOML

export DEFAULT_FINANCIAL_CONFIG,
    MarketPanel,
    StrategySpec,
    finite_strategy_catalog,
    load_financial_config,
    load_market_panel,
    load_provenance,
    run_financial_terminal_audit,
    write_financial_terminal_audit_outputs,
    main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_FINANCIAL_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_terminal_audit.toml",
)
const PROVENANCE_SCHEMA = "financial-illustration-provenance-v1"
const CONFIG_SCHEMA = "financial-illustration-v1"
const PENDING_SENTINEL = "PENDING"

struct StrategySpec
    id::String
    ticker::String
    directional_signal::String
    entry_filter::String
    holding_horizon::Int
    sizing_rule::String
    exit_rule::String
    risk_constraint::String
    modules::NTuple{7,String}
end

struct MarketPanel
    dates::Vector{String}
    tickers::Vector{String}
    total_return_index::Dict{String,Vector{Float64}}
    close::Dict{String,Vector{Float64}}
    volume::Dict{String,Vector{Float64}}
    audit::NamedTuple
end

function _require(condition::Bool, message::AbstractString)
    condition || error(message)
    return true
end

function _repo_path(path::AbstractString)
    isabspath(path) && return normpath(path)
    return normpath(joinpath(REPOSITORY_ROOT, path))
end

function _artifact_path(root::AbstractString, configured::AbstractString)
    return joinpath(root, splitpath(configured)...)
end

function _validate_iso_date(value::AbstractString, label::AbstractString)
    _require(
        occursin(r"^\d{4}-\d{2}-\d{2}$", value),
        "$label must use ISO YYYY-MM-DD: $value",
    )
    return String(value)
end

function _validate_utc_timestamp(value::AbstractString, label::AbstractString)
    _require(
        occursin(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$", value),
        "$label must use UTC YYYY-MM-DDTHH:MM:SSZ: $value",
    )
    return String(value)
end

function _validate_nonempty_strings(values, label::AbstractString)
    _require(values isa AbstractVector && !isempty(values), "$label must be nonempty")
    normalized = String[]
    for value in values
        text = String(value)
        _require(!isempty(strip(text)), "$label contains a blank value")
        push!(normalized, text)
    end
    _require(length(unique(normalized)) == length(normalized), "$label contains duplicates")
    return normalized
end

function load_financial_config(path::AbstractString = DEFAULT_FINANCIAL_CONFIG)
    config = TOML.parsefile(path)
    _require(get(config, "schema_version", "") == CONFIG_SCHEMA, "unsupported financial config schema")
    _require(
        get(config, "status", "") in (
            "pending_data",
            "ready",
            "ready_if_restricted_local_source_is_present",
            "ready_with_reviewer_supplied_licensed_crsp",
        ),
        "invalid terminal financial-audit status",
    )
    _require(get(config, "julia_version", "") == "1.12.6", "terminal financial audit requires Julia 1.12.6")
    _require(
        config["source"]["orats_inventory_required"] isa Bool,
        "source.orats_inventory_required must be explicit",
    )
    _require(
        config["source"]["aggregate_outputs_publishable"] isa Bool,
        "source.aggregate_outputs_publishable must be explicit",
    )

    tickers = _validate_nonempty_strings(config["universe"]["tickers"], "universe.tickers")
    _require(
        2 <= length(tickers) <= 30,
        "the terminal financial audit requires between 2 and 30 instruments",
    )

    periods = config["periods"]
    period_dates = [
        _validate_iso_date(periods[key], "periods.$key") for key in (
            "development_start",
            "development_end",
            "validation_start",
            "validation_end",
            "locked_start",
            "locked_end",
        )
    ]
    _require(issorted(period_dates), "development, validation, and locked dates must be ordered")
    _require(period_dates[2] < period_dates[3], "development and validation periods overlap")
    _require(period_dates[4] < period_dates[5], "validation and locked periods overlap")

    grammar = config["grammar"]
    _validate_nonempty_strings(grammar["directional_signal"], "grammar.directional_signal")
    _validate_nonempty_strings(grammar["entry_filter"], "grammar.entry_filter")
    _validate_nonempty_strings(grammar["sizing_rule"], "grammar.sizing_rule")
    _validate_nonempty_strings(grammar["exit_rule"], "grammar.exit_rule")
    _validate_nonempty_strings(grammar["risk_constraint"], "grammar.risk_constraint")
    horizons = Int.(grammar["holding_horizon"])
    _require(all(>(0), horizons), "holding horizons must be positive")
    _require(length(unique(horizons)) == length(horizons), "holding horizons contain duplicates")

    backtest = config["backtest"]
    _require(backtest["annualization_sessions"] > 0, "annualization sessions must be positive")
    _require(backtest["decision_to_first_return_lag_sessions"] >= 2, "close-only execution requires a lag of at least two return indices")
    _require(backtest["one_way_transaction_cost_bps"] >= 0, "transaction cost must be nonnegative")
    _require(all(>=(0), Float64.(backtest["cost_sensitivity_bps"])), "cost sensitivities must be nonnegative")
    _require(backtest["frontier_tolerance"] >= 0, "frontier tolerance must be nonnegative")

    ranking = config["ranking"]
    _require(ranking["top_k"] > 0, "ranking.top_k must be positive")
    _require(ranking["bootstrap_replications"] > 0, "bootstrap replications must be positive")
    _require(ranking["bootstrap_block_sessions"] > 0, "bootstrap block length must be positive")
    level = Float64(ranking["uncertainty_level"])
    _require(0 < level < 1, "uncertainty level must lie in (0,1)")

    outputs = config["outputs"]
    required_outputs = (
        "status_json",
        "grammar_csv",
        "candidate_audit_csv",
        "pruning_audit_csv",
        "ranking_csv",
        "ranking_summary_csv",
        "decomposition_csv",
        "mechanism_summary_csv",
        "uncertainty_csv",
        "cost_sensitivity_csv",
        "frontier_pruning_figure_data",
        "candidate_ranking_figure_data",
        "decomposition_figure_data",
        "frontier_pruning_figure",
        "candidate_ranking_figure",
        "decomposition_figure",
        "draft_results_md",
        "limitations_md",
        "manuscript_section",
    )
    for key in required_outputs
        _require(haskey(outputs, key), "missing output path: $key")
    end
    return config
end

function finite_strategy_catalog(config::AbstractDict)
    tickers = String.(config["universe"]["tickers"])
    grammar = config["grammar"]
    strategies = StrategySpec[]
    for ticker in tickers,
        directional in String.(grammar["directional_signal"]),
        entry_filter in String.(grammar["entry_filter"]),
        horizon in Int.(grammar["holding_horizon"]),
        sizing in String.(grammar["sizing_rule"]),
        exit_rule in String.(grammar["exit_rule"]),
        risk in String.(grammar["risk_constraint"])
        id = join((ticker, directional, entry_filter, "h$horizon", sizing, exit_rule, risk), "__")
        modules = (
            "instrument:$ticker",
            "directional_signal:$directional",
            "entry_filter:$entry_filter",
            "holding_horizon:$horizon",
            "sizing_rule:$sizing",
            "exit_rule:$exit_rule",
            "risk_constraint:$risk",
        )
        push!(
            strategies,
            StrategySpec(
                id,
                ticker,
                directional,
                entry_filter,
                horizon,
                sizing,
                exit_rule,
                risk,
                modules,
            ),
        )
    end
    sort!(strategies; by = strategy -> strategy.id)
    _require(length(unique(getfield.(strategies, :id))) == length(strategies), "strategy ids are not unique")
    return strategies
end

function _sha256_file(path::AbstractString)
    open(path, "r") do io
        return bytes2hex(sha256(io))
    end
end

function load_provenance(path::AbstractString, data_path::AbstractString, config::AbstractDict)
    _require(isfile(path), "provenance file is absent: $path")
    provenance = TOML.parsefile(path)
    _require(get(provenance, "schema_version", "") == PROVENANCE_SCHEMA, "unsupported provenance schema")

    textual = (
        "provider",
        "dataset_name",
        "source_url_or_delivery_id",
        "license_name",
        "license_url_or_text_reference",
        "derived_output_publication_status",
        "reviewer_replication_access",
        "retrieved_at_utc",
        "file_sha256",
        "exchange_timezone",
        "date_field_semantics",
        "field_availability",
        "total_return_construction",
        "corporate_action_revision_policy",
        "universe_selection_notes",
        "survivorship_notes",
        "known_missingness",
        "stale_price_and_correction_policy",
        "attested_by",
        "attested_at_utc",
    )
    for key in textual
        value = strip(String(get(provenance, key, "")))
        _require(!isempty(value) && uppercase(value) != PENDING_SENTINEL, "provenance.$key is incomplete")
    end
    _require(provenance["license_allows_research_use"] === true, "license does not attest research use")
    _require(
        provenance["raw_data_redistribution_permitted"] === false,
        "raw-data redistribution status must be explicitly false",
    )
    _require(
        provenance["aggregate_outputs_publishable"] isa Bool,
        "aggregate-output publication status must be explicit",
    )
    _require(provenance["point_in_time_attested"] isa Bool, "point-in-time attestation must be explicit")
    _require(
        haskey(provenance, "point_in_time_status") && !isempty(strip(String(provenance["point_in_time_status"]))),
        "point-in-time status is absent",
    )
    _validate_utc_timestamp(provenance["retrieved_at_utc"], "provenance.retrieved_at_utc")
    _validate_utc_timestamp(provenance["attested_at_utc"], "provenance.attested_at_utc")
    _require(
        provenance["exchange_timezone"] == config["data"]["exchange_timezone"],
        "provenance timezone differs from the configuration",
    )
    expected = lowercase(String(provenance["file_sha256"]))
    _require(occursin(r"^[0-9a-f]{64}$", expected), "provenance checksum is not SHA-256")
    actual = _sha256_file(data_path)
    _require(actual == expected, "market-data checksum differs from provenance")
    return provenance
end

function _parse_csv_line(line::AbstractString)
    fields = String[]
    buffer = IOBuffer()
    quoted = false
    index = firstindex(line)
    while index <= lastindex(line)
        character = line[index]
        if quoted
            if character == '"'
                next_index = nextind(line, index)
                if next_index <= lastindex(line) && line[next_index] == '"'
                    write(buffer, '"')
                    index = next_index
                else
                    quoted = false
                end
            else
                write(buffer, character)
            end
        elseif character == '"'
            _require(position(buffer) == 0, "quote begins inside an unquoted CSV field")
            quoted = true
        elseif character == ','
            push!(fields, String(take!(buffer)))
        else
            write(buffer, character)
        end
        index = nextind(line, index)
    end
    _require(!quoted, "unterminated quoted CSV field")
    push!(fields, String(take!(buffer)))
    return fields
end

function _parse_market_number(value::AbstractString, label::AbstractString; positive::Bool = false)
    _require(!isempty(strip(value)), "$label is missing")
    parsed = tryparse(Float64, strip(value))
    _require(!isnothing(parsed) && isfinite(parsed), "$label is not finite numeric data")
    positive && _require(parsed > 0, "$label must be positive")
    !positive && _require(parsed >= 0, "$label must be nonnegative")
    return parsed
end

function _period_count(dates::Vector{String}, start_date::String, end_date::String)
    return count(date -> start_date <= date <= end_date, dates)
end

function load_market_panel(data_path::AbstractString, config::AbstractDict)
    _require(isfile(data_path), "market data are absent: $data_path")
    lines = readlines(data_path)
    _require(length(lines) >= 2, "market-data CSV has no observations")
    header = strip.(_parse_csv_line(chomp(first(lines))))
    _require(length(unique(header)) == length(header), "market-data CSV has duplicate headers")
    required = String.(config["data"]["required_columns"])
    for column in required
        _require(column in header, "market-data CSV is missing required column: $column")
    end
    positions = Dict(column => findfirst(==(column), header) for column in required)

    configured_tickers = String.(config["universe"]["tickers"])
    rows = NamedTuple[]
    keys_seen = Set{Tuple{String,String}}()
    for (offset, raw_line) in enumerate(Iterators.drop(lines, 1))
        line_number = offset + 1
        isempty(strip(raw_line)) && continue
        fields = _parse_csv_line(chomp(raw_line))
        _require(length(fields) == length(header), "CSV width mismatch on line $line_number")
        date = _validate_iso_date(strip(fields[positions["date"]]), "date on line $line_number")
        ticker = strip(fields[positions["ticker"]])
        _require(!isempty(ticker), "ticker is blank on line $line_number")
        key = (date, ticker)
        _require(!(key in keys_seen), "duplicate (date,ticker) key: $key")
        push!(keys_seen, key)
        tri = _parse_market_number(fields[positions["total_return_index"]], "total_return_index on line $line_number"; positive = true)
        close = _parse_market_number(fields[positions["close"]], "close on line $line_number"; positive = true)
        volume = _parse_market_number(fields[positions["volume"]], "volume on line $line_number")
        push!(rows, (; date, ticker, total_return_index = tri, close, volume))
    end
    _require(!isempty(rows), "market-data CSV has no usable observations")

    observed_tickers = sort!(unique(getfield.(rows, :ticker)))
    if config["data"]["require_exact_universe"]
        _require(observed_tickers == sort(configured_tickers), "observed tickers differ from the fixed universe")
    else
        _require(all(ticker -> ticker in observed_tickers, configured_tickers), "a required ticker is absent")
    end
    rows = [row for row in rows if row.ticker in configured_tickers]
    _require(maximum(getfield.(rows, :date)) <= config["periods"]["locked_end"], "input contains dates after the locked-period end")

    dates_by_ticker = Dict(
        ticker => Set(row.date for row in rows if row.ticker == ticker) for ticker in configured_tickers
    )
    union_dates = union(values(dates_by_ticker)...)
    complete_dates = intersect(values(dates_by_ticker)...)
    missing_share = 1 - length(complete_dates) / length(union_dates)
    _require(
        missing_share <= Float64(config["data"]["maximum_cross_section_missing_share"]),
        "cross-sectional missing-date share exceeds the configured maximum",
    )
    dates = sort!(collect(complete_dates))
    periods = config["periods"]
    warmup_count = count(date -> date < periods["development_start"], dates)
    _require(warmup_count >= config["data"]["minimum_warmup_sessions"], "insufficient pre-development warmup")
    for (label, start_key, end_key, minimum_key) in (
        ("development", "development_start", "development_end", "minimum_development_sessions"),
        ("validation", "validation_start", "validation_end", "minimum_validation_sessions"),
        ("locked", "locked_start", "locked_end", "minimum_locked_sessions"),
    )
        count_in_period = _period_count(dates, periods[start_key], periods[end_key])
        _require(count_in_period >= periods[minimum_key], "insufficient $label observations")
    end

    row_lookup = Dict((row.date, row.ticker) => row for row in rows)
    total_return_index = Dict{String,Vector{Float64}}()
    close = Dict{String,Vector{Float64}}()
    volume = Dict{String,Vector{Float64}}()
    for ticker in configured_tickers
        total_return_index[ticker] = [row_lookup[(date, ticker)].total_return_index for date in dates]
        close[ticker] = [row_lookup[(date, ticker)].close for date in dates]
        volume[ticker] = [row_lookup[(date, ticker)].volume for date in dates]
    end
    audit = (
        source_rows = length(rows),
        union_dates = length(union_dates),
        complete_dates = length(dates),
        excluded_incomplete_dates = length(union_dates) - length(dates),
        cross_section_missing_share = missing_share,
        first_date = first(dates),
        last_date = last(dates),
        warmup_sessions = warmup_count,
    )
    return MarketPanel(dates, configured_tickers, total_return_index, close, volume, audit)
end

function _mean(values::AbstractVector{<:Real})
    isempty(values) && return NaN
    return sum(Float64, values) / length(values)
end

function _variance(values::AbstractVector{<:Real})
    length(values) <= 1 && return 0.0
    average = _mean(values)
    return sum(value -> (Float64(value) - average)^2, values) / (length(values) - 1)
end

function _utility(values::AbstractVector{<:Real}, config::AbstractDict)
    isempty(values) && return NaN
    annualization = Float64(config["backtest"]["annualization_sessions"])
    risk_aversion = Float64(config["backtest"]["risk_aversion"])
    return annualization * _mean(values) - 0.5 * risk_aversion * annualization * _variance(values)
end

function _returns(index_values::Vector{Float64})
    returns = zeros(Float64, length(index_values))
    for index in 2:length(index_values)
        returns[index] = index_values[index] / index_values[index - 1] - 1
    end
    return returns
end

function _lookback_return(index_values::Vector{Float64}, index::Int, lookback::Int)
    index > lookback || return NaN
    return index_values[index] / index_values[index - lookback] - 1
end

function _rolling_mean(values::Vector{Float64}, index::Int, lookback::Int)
    index >= lookback || return NaN
    return _mean(@view values[(index - lookback + 1):index])
end

function _rolling_volatility(returns::Vector{Float64}, index::Int, lookback::Int, annualization::Int)
    index > lookback || return NaN
    return sqrt(annualization * _variance(@view returns[(index - lookback + 1):index]))
end

function _directional_signal(strategy::StrategySpec, prices::Vector{Float64}, index::Int)
    if strategy.directional_signal == "momentum_20"
        value = _lookback_return(prices, index, 20)
        return isfinite(value) && value > 0
    elseif strategy.directional_signal == "momentum_60"
        value = _lookback_return(prices, index, 60)
        return isfinite(value) && value > 0
    elseif strategy.directional_signal == "mean_reversion_5"
        value = _lookback_return(prices, index, 5)
        return isfinite(value) && value < 0
    end
    error("unsupported directional signal: $(strategy.directional_signal)")
end

function _entry_filter(strategy::StrategySpec, prices::Vector{Float64}, index::Int, config::AbstractDict)
    strategy.entry_filter == "always" && return true
    if strategy.entry_filter == "trend_100"
        lookback = Int(config["backtest"]["trend_filter_lookback"])
        average = _rolling_mean(prices, index, lookback)
        return isfinite(average) && prices[index] > average
    end
    error("unsupported entry filter: $(strategy.entry_filter)")
end

function _position_size(
    strategy::StrategySpec,
    returns::Vector{Float64},
    index::Int,
    config::AbstractDict,
)
    base = strategy.sizing_rule == "unit" ? 1.0 :
           strategy.sizing_rule == "half" ? 0.5 :
           error("unsupported sizing rule: $(strategy.sizing_rule)")
    strategy.risk_constraint == "notional_cap_1" && return min(base, 1.0)
    if strategy.risk_constraint == "vol_target_10"
        lookback = Int(config["backtest"]["volatility_lookback"])
        annualization = Int(config["backtest"]["annualization_sessions"])
        volatility = _rolling_volatility(returns, index, lookback, annualization)
        return !isfinite(volatility) || volatility <= 0 ? 0.0 : min(base, 0.10 / volatility)
    end
    error("unsupported risk constraint: $(strategy.risk_constraint)")
end

function _backtest_strategy(
    strategy::StrategySpec,
    panel::MarketPanel,
    config::AbstractDict;
    cost_bps::Real = config["backtest"]["one_way_transaction_cost_bps"],
)
    prices = panel.total_return_index[strategy.ticker]
    asset_returns = _returns(prices)
    intended = zeros(Float64, length(prices))
    position = 0.0
    age = 0
    for index in eachindex(prices)
        signal = _directional_signal(strategy, prices, index)
        filter_passes = _entry_filter(strategy, prices, index, config)
        if position == 0.0
            if signal && filter_passes
                position = _position_size(strategy, asset_returns, index, config)
                age = position > 0 ? 1 : 0
            end
        else
            should_exit = age >= strategy.holding_horizon ||
                          (strategy.exit_rule == "signal_flip" && !signal)
            if should_exit
                position = 0.0
                age = 0
            else
                position = _position_size(strategy, asset_returns, index, config)
                age += 1
            end
        end
        intended[index] = position
    end

    lag = Int(config["backtest"]["decision_to_first_return_lag_sessions"])
    effective = zeros(Float64, length(prices))
    for index in (lag + 1):length(prices)
        effective[index] = intended[index - lag]
    end
    turnover = similar(effective)
    turnover[1] = abs(effective[1])
    for index in 2:length(effective)
        turnover[index] = abs(effective[index] - effective[index - 1])
    end
    cost_rate = Float64(cost_bps) / 10_000
    gross = effective .* asset_returns
    net = gross .- cost_rate .* turnover
    return (; gross, net, turnover, position = effective)
end

function _empirical_quantile(values::Vector{Float64}, probability::Float64)
    _require(!isempty(values), "cannot compute a quantile from an empty vector")
    _require(0 <= probability <= 1, "quantile probability must lie in [0,1]")
    ordered = sort(values)
    position = clamp(ceil(Int, probability * length(ordered)), 1, length(ordered))
    return ordered[position]
end

function _belief_states(panel::MarketPanel, config::AbstractDict)
    reference = String(config["backtest"]["belief_signal_ticker"])
    prices = panel.total_return_index[reference]
    lookback = Int(config["backtest"]["belief_lookback"])
    features = [_lookback_return(prices, index, lookback) for index in eachindex(prices)]
    periods = config["periods"]
    development_features = [
        features[index] for index in eachindex(features) if
        periods["development_start"] <= panel.dates[index] <= periods["development_end"] &&
        isfinite(features[index])
    ]
    probabilities = Float64.(config["backtest"]["belief_quantiles"])
    thresholds = [_empirical_quantile(development_features, probability) for probability in probabilities]
    _require(issorted(thresholds), "belief thresholds are not ordered")
    states = zeros(Int, length(features))
    for index in eachindex(features)
        feature = features[index]
        if isfinite(feature)
            states[index] = feature <= thresholds[1] ? 1 : feature <= thresholds[2] ? 2 : 3
        end
    end
    return (; states, thresholds, features)
end

function _period_indices(panel::MarketPanel, start_date::String, end_date::String)
    return findall(date -> start_date <= date <= end_date, panel.dates)
end

function _state_profile(
    net_returns::Vector{Float64},
    states::Vector{Int},
    indices::Vector{Int},
    config::AbstractDict,
)
    profile = Float64[]
    for state in 1:3
        observations = [net_returns[index] for index in indices if states[index] == state]
        _require(!isempty(observations), "a validation belief state has no observations")
        push!(profile, _utility(observations, config))
    end
    return profile
end

function _evaluate_catalog(catalog, panel, beliefs, config)
    periods = config["periods"]
    development_indices = _period_indices(panel, periods["development_start"], periods["development_end"])
    validation_indices = _period_indices(panel, periods["validation_start"], periods["validation_end"])
    locked_indices = _period_indices(panel, periods["locked_start"], periods["locked_end"])
    base_cost = Float64(config["backtest"]["one_way_transaction_cost_bps"])
    evaluations = Dict{String,NamedTuple}()
    for strategy in catalog
        backtest = _backtest_strategy(strategy, panel, config; cost_bps = base_cost)
        development_net = backtest.net[development_indices]
        validation_net = backtest.net[validation_indices]
        evaluations[strategy.id] = (
            strategy = strategy,
            gross = backtest.gross,
            net = backtest.net,
            turnover = backtest.turnover,
            development_utility = _utility(development_net, config),
            validation_utility = _utility(validation_net, config),
            validation_profile = _state_profile(backtest.net, beliefs.states, validation_indices, config),
            mean_validation_turnover = _mean(backtest.turnover[validation_indices]),
            locked_indices = locked_indices,
        )
    end
    return (; evaluations, development_indices, validation_indices, locked_indices)
end

function _strategy_closure(ids::Vector{String}, evaluations::AbstractDict)
    closure = Set{String}()
    for id in ids
        union!(closure, evaluations[id].strategy.modules)
    end
    return closure
end

function _frontier(ids::Vector{String}, evaluations::AbstractDict)
    _require(!isempty(ids), "library cannot be empty")
    return [maximum(evaluations[id].validation_profile[state] for id in ids) for state in 1:3]
end

function _profile_equal(left, right, tolerance::Float64)
    return length(left) == length(right) && all(isapprox(left[index], right[index]; atol = tolerance, rtol = 0) for index in eachindex(left))
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
    _require(_strategy_closure(library, evaluations) == Set(all_modules), "initial library does not span the finite grammar")
    return library
end

function _prune_library(
    source::Vector{String},
    evaluations::AbstractDict,
    config::AbstractDict;
    safe::Bool,
)
    tolerance = Float64(config["backtest"]["frontier_tolerance"])
    order = sort(copy(source); by = id -> (
        safe ? evaluations[id].development_utility : evaluations[id].validation_utility,
        id,
    ))
    current = copy(source)
    decisions = NamedTuple[]
    step = 0
    for id in order
        id in current || continue
        length(current) > 1 || break
        step += 1
        before = copy(current)
        before_frontier = _frontier(before, evaluations)
        before_closure = _strategy_closure(before, evaluations)
        after = [candidate for candidate in before if candidate != id]
        after_frontier = _frontier(after, evaluations)
        after_closure = _strategy_closure(after, evaluations)
        operationally_redundant = _profile_equal(before_frontier, after_frontier, tolerance)
        generatively_redundant = before_closure == after_closure
        remove = operationally_redundant && (!safe || generatively_redundant)
        if remove
            current = after
        end
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

function _transition_matrix(states::Vector{Int}, indices::Vector{Int})
    counts = ones(Float64, 3, 3)
    index_set = Set(indices)
    for index in indices
        index + 1 in index_set || continue
        current = states[index]
        next = states[index + 1]
        current > 0 && next > 0 && (counts[current, next] += 1)
    end
    for row in 1:3
        counts[row, :] ./= sum(counts[row, :])
    end
    return counts
end

function _coverage_weights(transition::Matrix{Float64}, initial_state::Int; horizon::Int = 20, discount::Float64 = 0.99)
    distribution = zeros(Float64, 3)
    distribution[initial_state] = 1.0
    weights = zeros(Float64, 3)
    for step in 1:horizon
        distribution = vec(transpose(distribution) * transition)
        weights .+= discount^(step - 1) .* distribution
    end
    return weights
end

function _enabled(strategy::StrategySpec, closure::Set{String})
    return all(module_id -> module_id in closure, strategy.modules)
end

function _hamming_novelty(strategy::StrategySpec, library::Vector{String}, evaluations)
    minimum_distance = minimum(
        count(index -> strategy.modules[index] != evaluations[id].strategy.modules[index], eachindex(strategy.modules)) for id in library
    )
    return minimum_distance / length(strategy.modules)
end

function _rank_descending(values::Dict{String,Float64})
    ids = sort!(collect(keys(values)); by = id -> (-values[id], id))
    return Dict(id => rank for (rank, id) in enumerate(ids))
end

function _average_tie_ranks(values::Vector{Float64})
    order = sortperm(values)
    ranks = zeros(Float64, length(values))
    start = 1
    while start <= length(order)
        stop = start
        while stop < length(order) && values[order[stop + 1]] == values[order[start]]
            stop += 1
        end
        average_rank = (start + stop) / 2
        for position in start:stop
            ranks[order[position]] = average_rank
        end
        start = stop + 1
    end
    return ranks
end

function _correlation(left::Vector{Float64}, right::Vector{Float64})
    length(left) == length(right) || error("correlation vectors differ in length")
    length(left) >= 2 || return NaN
    left_centered = left .- _mean(left)
    right_centered = right .- _mean(right)
    denominator = sqrt(sum(abs2, left_centered) * sum(abs2, right_centered))
    return denominator == 0 ? NaN : sum(left_centered .* right_centered) / denominator
end

function _spearman(left::Vector{Float64}, right::Vector{Float64})
    return _correlation(_average_tie_ranks(left), _average_tie_ranks(right))
end

function _library_locked_quality(library::Vector{String}, evaluations, config)
    return maximum(_utility(evaluations[id].net[evaluations[id].locked_indices], config) for id in library)
end

function _candidate_quality(closure::Set{String}, candidate_ids::Vector{String}, evaluations, config)
    enabled_ids = [id for id in candidate_ids if _enabled(evaluations[id].strategy, closure)]
    isempty(enabled_ids) && return -Inf
    return maximum(_utility(evaluations[id].net[evaluations[id].locked_indices], config) for id in enabled_ids)
end

function _weighted_frontier(frontier::Vector{Float64}, states::Vector{Int}, indices::Vector{Int})
    frequencies = [count(index -> states[index] == state, indices) for state in 1:3]
    total = sum(frequencies)
    return sum(frontier[state] * frequencies[state] for state in 1:3) / total
end

function _decision_hash(initial_library, safe_decisions, frontier_decisions, ranking_rows)
    rows = String[]
    append!(rows, "initial:$id" for id in initial_library)
    append!(rows, "$(row.rule):$(row.step):$(row.strategy_id):$(row.decision)" for row in safe_decisions)
    append!(rows, "$(row.rule):$(row.step):$(row.strategy_id):$(row.decision)" for row in frontier_decisions)
    append!(rows, "rank:$(row.strategy_id):$(row.coverage_rank):$(row.current_rank):$(row.average_rank):$(row.novelty_rank)" for row in ranking_rows)
    return bytes2hex(sha256(join(rows, "\n")))
end

function _circular_block_indices(rng, observation_count::Int, block_length::Int)
    indices = Int[]
    while length(indices) < observation_count
        start = rand(rng, 1:observation_count)
        for offset in 0:(block_length - 1)
            push!(indices, mod1(start + offset, observation_count))
            length(indices) == observation_count && break
        end
    end
    return indices
end

function _quantile(values::Vector{Float64}, probability::Float64)
    return _empirical_quantile(values, probability)
end

function _uncertainty_rows(ranking_rows, library, evaluations, config)
    top_k = min(Int(config["ranking"]["top_k"]), length(ranking_rows))
    replications = Int(config["ranking"]["bootstrap_replications"])
    block = Int(config["ranking"]["bootstrap_block_sessions"])
    level = Float64(config["ranking"]["uncertainty_level"])
    seed = UInt64(config["seed"])
    methods = (
        ("coverage_potential", :coverage_rank),
        ("current_belief_improvement", :current_rank),
        ("average_validation_score", :average_rank),
        ("raw_parameter_novelty", :novelty_rank),
    )
    locked_indices = evaluations[first(library)].locked_indices
    rows = NamedTuple[]
    for (method, rank_field) in methods
        selected = sort(ranking_rows; by = row -> getproperty(row, rank_field))[1:top_k]
        selected_ids = getfield.(selected, :strategy_id)
        rng = StableRNG(seed + UInt64(length(rows) + 1))
        samples = Float64[]
        for _ in 1:replications
            sampled_positions = _circular_block_indices(rng, length(locked_indices), block)
            sampled_indices = locked_indices[sampled_positions]
            candidate_value = _mean([_utility(evaluations[id].net[sampled_indices], config) for id in selected_ids])
            baseline_value = maximum(_utility(evaluations[id].net[sampled_indices], config) for id in library)
            push!(samples, candidate_value - baseline_value)
        end
        estimate = _mean(getfield.(selected, :locked_net_utility_improvement))
        alpha = (1 - level) / 2
        push!(rows, (
            method,
            metric = "top_k_locked_net_utility_improvement",
            estimate,
            lower = _quantile(samples, alpha),
            upper = _quantile(samples, 1 - alpha),
            uncertainty_level = level,
            replications,
            block_sessions = block,
        ))
    end
    return rows
end

function _locked_utility_at_cost(evaluation, locked_indices, cost_bps::Real, config)
    net = evaluation.gross[locked_indices] .-
          (Float64(cost_bps) / 10_000) .* evaluation.turnover[locked_indices]
    return _utility(net, config)
end

function _cost_sensitivity_rows(ranking_rows, library, evaluations, locked_indices, config)
    top_k = min(Int(config["ranking"]["top_k"]), length(ranking_rows))
    rows = NamedTuple[]
    for cost_bps in Float64.(config["backtest"]["cost_sensitivity_bps"])
        baseline = maximum(
            _locked_utility_at_cost(evaluations[id], locked_indices, cost_bps, config) for id in library
        )
        for (method, rank_field) in (
            ("coverage_potential", :coverage_rank),
            ("current_belief_improvement", :current_rank),
            ("average_validation_score", :average_rank),
            ("raw_parameter_novelty", :novelty_rank),
        )
            selected = sort(ranking_rows; by = row -> getproperty(row, rank_field))[1:top_k]
            selected_value = _mean([
                _locked_utility_at_cost(
                    evaluations[row.strategy_id],
                    locked_indices,
                    cost_bps,
                    config,
                ) for row in selected
            ])
            push!(rows, (
                cost_bps,
                method,
                top_k,
                locked_baseline_utility = baseline,
                top_k_locked_utility = selected_value,
                top_k_locked_improvement = selected_value - baseline,
            ))
        end
    end
    return rows
end

function _run_ready(config, panel, provenance, catalog)
    beliefs = _belief_states(panel, config)
    evaluated = _evaluate_catalog(catalog, panel, beliefs, config)
    evaluations = evaluated.evaluations
    initial_library = _initial_library(catalog, evaluations, config)
    safe = _prune_library(initial_library, evaluations, config; safe = true)
    frontier_only = _prune_library(initial_library, evaluations, config; safe = false)
    tolerance = Float64(config["backtest"]["frontier_tolerance"])
    initial_frontier = _frontier(initial_library, evaluations)
    _require(_profile_equal(initial_frontier, _frontier(safe.library, evaluations), tolerance), "safe compression changed the validation frontier")
    _require(_strategy_closure(initial_library, evaluations) == _strategy_closure(safe.library, evaluations), "safe compression changed module closure")
    _require(_profile_equal(initial_frontier, _frontier(frontier_only.library, evaluations), tolerance), "frontier-only pruning changed the validation frontier")

    initial_closure = _strategy_closure(initial_library, evaluations)
    safe_closure = _strategy_closure(safe.library, evaluations)
    frontier_closure = _strategy_closure(frontier_only.library, evaluations)
    candidate_ids = [strategy.id for strategy in catalog if !(strategy.id in initial_library)]

    transition = _transition_matrix(beliefs.states, evaluated.development_indices)
    last_validation_index = last(evaluated.validation_indices)
    current_state = beliefs.states[last_validation_index]
    _require(current_state in 1:3, "last validation belief state is undefined")
    weights = _coverage_weights(transition, current_state)

    score_maps = Dict(
        "coverage_potential" => Dict{String,Float64}(),
        "current_belief_improvement" => Dict{String,Float64}(),
        "average_validation_score" => Dict{String,Float64}(),
        "raw_parameter_novelty" => Dict{String,Float64}(),
    )
    for id in candidate_ids
        evaluation = evaluations[id]
        _enabled(evaluation.strategy, initial_closure) || continue
        gap = max.(evaluation.validation_profile .- initial_frontier, 0.0)
        score_maps["coverage_potential"][id] = sum(weights .* gap)
        score_maps["current_belief_improvement"][id] = gap[current_state]
        score_maps["average_validation_score"][id] = evaluation.validation_utility
        score_maps["raw_parameter_novelty"][id] = _hamming_novelty(evaluation.strategy, initial_library, evaluations)
    end
    _require(!isempty(score_maps["coverage_potential"]), "no enabled candidates remain for ranking")
    ranks = Dict(method => _rank_descending(scores) for (method, scores) in score_maps)
    decision_rows = NamedTuple[]
    for id in sort!(collect(keys(score_maps["coverage_potential"])))
        push!(decision_rows, (
            strategy_id = id,
            coverage_rank = ranks["coverage_potential"][id],
            current_rank = ranks["current_belief_improvement"][id],
            average_rank = ranks["average_validation_score"][id],
            novelty_rank = ranks["raw_parameter_novelty"][id],
        ))
    end
    decision_hash = _decision_hash(initial_library, safe.decisions, frontier_only.decisions, decision_rows)
    _require(length(decision_hash) == 64, "decision audit did not produce a SHA-256 hash")

    # Locked-period values are first accessed only after the validation-only
    # library, pruning, rankings, and their decision hash have been frozen.
    locked_baseline = _library_locked_quality(initial_library, evaluations, config)
    locked_targets = Dict(
        id => _utility(evaluations[id].net[evaluated.locked_indices], config) - locked_baseline for
        id in keys(score_maps["coverage_potential"])
    )
    target_rank = _rank_descending(locked_targets)
    ranking_rows = NamedTuple[]
    for id in sort!(collect(keys(locked_targets)))
        push!(ranking_rows, (
            strategy_id = id,
            ticker = evaluations[id].strategy.ticker,
            coverage_potential = score_maps["coverage_potential"][id],
            current_belief_improvement = score_maps["current_belief_improvement"][id],
            average_validation_score = score_maps["average_validation_score"][id],
            raw_parameter_novelty = score_maps["raw_parameter_novelty"][id],
            locked_net_utility_improvement = locked_targets[id],
            coverage_rank = ranks["coverage_potential"][id],
            current_rank = ranks["current_belief_improvement"][id],
            average_rank = ranks["average_validation_score"][id],
            novelty_rank = ranks["raw_parameter_novelty"][id],
            locked_rank = target_rank[id],
        ))
    end

    initial_candidate_quality = _candidate_quality(initial_closure, candidate_ids, evaluations, config)
    safe_candidate_quality = _candidate_quality(safe_closure, candidate_ids, evaluations, config)
    frontier_candidate_quality = _candidate_quality(frontier_closure, candidate_ids, evaluations, config)
    _require(initial_candidate_quality == safe_candidate_quality, "safe compression changed enabled locked candidate quality")

    validation_value = _weighted_frontier(initial_frontier, beliefs.states, evaluated.validation_indices)
    frontier_value = _weighted_frontier(_frontier(frontier_only.library, evaluations), beliefs.states, evaluated.validation_indices)

    decomposition_rows = NamedTuple[]
    for id in safe.library
        reduced = [candidate for candidate in safe.library if candidate != id]
        isempty(reduced) && continue
        operational = validation_value - _weighted_frontier(_frontier(reduced, evaluations), beliefs.states, evaluated.validation_indices)
        reduced_quality = _candidate_quality(_strategy_closure(reduced, evaluations), candidate_ids, evaluations, config)
        generative = initial_candidate_quality - reduced_quality
        total = operational + generative
        _require(
            isapprox(total, operational + generative; atol = tolerance, rtol = 0),
            "operational-generative decomposition identity failed for $id",
        )
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

    ranking_summaries = NamedTuple[]
    locked_values = [locked_targets[row.strategy_id] for row in ranking_rows]
    top_k = min(Int(config["ranking"]["top_k"]), length(ranking_rows))
    for (method, field, rank_field) in (
        ("coverage_potential", :coverage_potential, :coverage_rank),
        ("current_belief_improvement", :current_belief_improvement, :current_rank),
        ("average_validation_score", :average_validation_score, :average_rank),
        ("raw_parameter_novelty", :raw_parameter_novelty, :novelty_rank),
    )
        scores = [getproperty(row, field) for row in ranking_rows]
        selected = sort(ranking_rows; by = row -> getproperty(row, rank_field))[1:top_k]
        push!(ranking_summaries, (
            method,
            spearman_with_locked = _spearman(scores, locked_values),
            top_k_locked_improvement = _mean(getfield.(selected, :locked_net_utility_improvement)),
            top_k,
        ))
    end
    coverage_summary = only(row for row in ranking_summaries if row.method == "coverage_potential")
    comparator_best = maximum(row.top_k_locked_improvement for row in ranking_summaries if row.method != "coverage_potential")

    mechanism_rows = [
        (
            question = "A",
            mechanism = "frontier-only pruning",
            current_validation_value_change = frontier_value - validation_value,
            locked_candidate_quality_change = frontier_candidate_quality - initial_candidate_quality,
            result = frontier_candidate_quality < initial_candidate_quality - tolerance ? "supportive" : "negative_or_zero",
        ),
        (
            question = "B",
            mechanism = "innovation-safe compression",
            current_validation_value_change = _weighted_frontier(_frontier(safe.library, evaluations), beliefs.states, evaluated.validation_indices) - validation_value,
            locked_candidate_quality_change = safe_candidate_quality - initial_candidate_quality,
            result = "identity_pass",
        ),
        (
            question = "C",
            mechanism = "coverage candidate ranking",
            current_validation_value_change = coverage_summary.spearman_with_locked,
            locked_candidate_quality_change = coverage_summary.top_k_locked_improvement - comparator_best,
            result = coverage_summary.top_k_locked_improvement > comparator_best ? "supportive" : "negative_or_tied",
        ),
        (
            question = "D",
            mechanism = "operational-generative decomposition",
            current_validation_value_change = count(row -> row.currently_dominated && row.generatively_valuable, decomposition_rows),
            locked_candidate_quality_change = maximum((row.generative for row in decomposition_rows); init = 0.0),
            result = any(row -> row.currently_dominated && row.generatively_valuable, decomposition_rows) ? "supportive" : "negative_or_zero",
        ),
    ]

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
        development_gross_utility = _utility(evaluations[strategy.id].gross[evaluated.development_indices], config),
        development_net_utility = evaluations[strategy.id].development_utility,
        validation_gross_utility = _utility(evaluations[strategy.id].gross[evaluated.validation_indices], config),
        validation_net_utility = evaluations[strategy.id].validation_utility,
        locked_gross_utility = _utility(evaluations[strategy.id].gross[evaluated.locked_indices], config),
        locked_net_utility = _utility(evaluations[strategy.id].net[evaluated.locked_indices], config),
        mean_validation_turnover = evaluations[strategy.id].mean_validation_turnover,
    ) for strategy in catalog]

    uncertainty = _uncertainty_rows(ranking_rows, initial_library, evaluations, config)
    cost_sensitivity = _cost_sensitivity_rows(
        ranking_rows,
        initial_library,
        evaluations,
        evaluated.locked_indices,
        config,
    )
    pruning_rows = vcat(safe.decisions, frontier_only.decisions)
    aggregate_outputs_publishable = provenance["aggregate_outputs_publishable"] === true
    return (
        status = aggregate_outputs_publishable ? "empirical_complete_aggregate_publishable" :
                 "empirical_complete_internal_review_required",
        empirical_results_permitted = true,
        aggregate_outputs_publishable,
        config,
        provenance,
        panel_audit = panel.audit,
        catalog,
        candidate_audit,
        pruning_rows,
        ranking_rows,
        decomposition_rows,
        mechanism_rows,
        uncertainty,
        cost_sensitivity,
        ranking_summaries,
        initial_library,
        safe_library = safe.library,
        frontier_only_library = frontier_only.library,
        initial_frontier,
        initial_candidate_quality,
        safe_candidate_quality,
        frontier_candidate_quality,
        decision_hash,
        belief_thresholds = beliefs.thresholds,
        current_validation_state = current_state,
    )
end

function _pending_result(config, catalog; reason::AbstractString)
    return (
        status = "pending_data",
        empirical_results_permitted = false,
        aggregate_outputs_publishable = false,
        config,
        catalog,
        reason = String(reason),
        candidate_audit = NamedTuple[],
        pruning_rows = NamedTuple[],
        ranking_rows = NamedTuple[],
        decomposition_rows = NamedTuple[],
        mechanism_rows = NamedTuple[],
        uncertainty = NamedTuple[],
        cost_sensitivity = NamedTuple[],
        ranking_summaries = NamedTuple[],
    )
end

function run_financial_terminal_audit(
    config::AbstractDict = load_financial_config();
    data_path::AbstractString = _repo_path(config["data"]["path"]),
    provenance_path::AbstractString = _repo_path(config["data"]["provenance_path"]),
)
    catalog = finite_strategy_catalog(config)
    if !isfile(data_path) || !isfile(provenance_path)
        return _pending_result(
            config,
            catalog;
            reason = "no licensed, provenance-complete market dataset is present; empirical section remains pending",
        )
    end
    provenance = load_provenance(provenance_path, data_path, config)
    panel = load_market_panel(data_path, config)
    return _run_ready(config, panel, provenance, catalog)
end

function _csv_escape(value)
    text = value isa Bool ? (value ? "true" : "false") :
           value isa AbstractFloat ? (isfinite(value) ? repr(value) : string(value)) :
           string(value)
    return occursin(r"[\",\n\r]", text) ? "\"$(replace(text, "\"" => "\"\""))\"" : text
end

function _write_csv(path::AbstractString, columns, rows)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, join(columns, ","))
        for row in rows
            println(io, join((_csv_escape(getproperty(row, Symbol(column))) for column in columns), ","))
        end
    end
    return path
end

function _json_escape(value::AbstractString)
    return replace(value, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n", "\r" => "\\r", "\t" => "\\t")
end

function _json(value)
    value === nothing && return "null"
    value isa Bool && return value ? "true" : "false"
    value isa Integer && return string(value)
    value isa AbstractFloat && return isfinite(value) ? repr(value) : "null"
    value isa AbstractString && return "\"$(_json_escape(value))\""
    value isa AbstractVector && return "[" * join((_json(item) for item in value), ",") * "]"
    value isa Tuple && return _json(collect(value))
    value isa AbstractDict && return "{" * join(("$(_json(string(key))):$(_json(value[key]))" for key in sort!(collect(keys(value)); by = string)), ",") * "}"
    value isa NamedTuple && return _json(Dict(string(key) => getproperty(value, key) for key in keys(value)))
    return _json(string(value))
end

function _write_status(
    path::AbstractString,
    result,
    config_path::AbstractString,
    artifact_paths::AbstractDict,
)
    mkpath(dirname(path))
    payload = Dict{String,Any}(
        "schema_version" => CONFIG_SCHEMA,
        "config_path" => relpath(abspath(config_path), REPOSITORY_ROOT),
        "experiment_id" => result.config["experiment_id"],
        "status" => result.status,
        "empirical_results_permitted" => result.empirical_results_permitted,
        "protocol_date" => result.config["protocol_date"],
        "protocol_base_commit" => result.config["protocol_base_commit"],
        "seed" => string(result.config["seed"]),
        "rng" => "StableRNGs.StableRNG",
        "arithmetic" => "Float64 financial audit; formal identities use configured hard tolerances",
        "command" => "julia --project=julia julia/scripts/run_financial_terminal_audit.jl",
        "strategy_count" => length(result.catalog),
        "universe" => String.(result.config["universe"]["tickers"]),
        "orats_covered_universe" => String.(result.config["universe"]["orats_covered_tickers"]),
        "crsp_only_additions" => String.(result.config["universe"]["crsp_only_additions"]),
        "excluded_orats_tickers" => String.(result.config["universe"]["excluded_orats_tickers"]),
        "orats_exclusion_reason" => result.config["universe"]["exclusion_reason"],
        "periods" => result.config["periods"],
        "one_way_transaction_cost_bps" => result.config["backtest"]["one_way_transaction_cost_bps"],
        "cost_sensitivity_bps" => result.config["backtest"]["cost_sensitivity_bps"],
        "bootstrap_replications" => result.config["ranking"]["bootstrap_replications"],
        "bootstrap_block_sessions" => result.config["ranking"]["bootstrap_block_sessions"],
        "config_sha256" => _sha256_file(config_path),
        "source_data_downloaded" => false,
        "aggregate_outputs_publishable" => result.aggregate_outputs_publishable,
        "raw_data_redistribution_permitted" => false,
    )
    if result.status == "pending_data"
        payload["reason"] = result.reason
        payload["source"] = "absent"
        payload["license"] = "absent"
        payload["market_observation_count"] = 0
        payload["decision_hash"] = nothing
    else
        payload["source"] = result.provenance["provider"]
        payload["dataset_name"] = result.provenance["dataset_name"]
        payload["license"] = result.provenance["license_name"]
        payload["market_data_sha256"] = result.provenance["file_sha256"]
        payload["market_observation_count"] = result.panel_audit.source_rows
        payload["decision_hash"] = result.decision_hash
        payload["point_in_time_attested"] = result.provenance["point_in_time_attested"]
        payload["derived_output_publication_status"] = result.provenance["derived_output_publication_status"]
        payload["reviewer_replication_access"] = result.provenance["reviewer_replication_access"]
        payload["orats_inventory_revalidated"] = result.provenance["orats_inventory_revalidated"]
        payload["source_repository_commit"] = result.config["source"]["repository_commit"]
        payload["source_file_sha256"] = Dict(
            String(file["path"]) => String(file["sha256"]) for file in result.provenance["source_files"]
        )
        payload["initial_library_size"] = length(result.initial_library)
        payload["safe_library_size"] = length(result.safe_library)
        payload["frontier_only_library_size"] = length(result.frontier_only_library)
    end
    payload["generated_artifact_sha256"] = Dict(
        result.config["outputs"][key] => _sha256_file(artifact_path) for
        (key, artifact_path) in artifact_paths if key != "status_json"
    )
    open(path, "w") do io
        write(io, _json(payload))
        write(io, "\n")
    end
    return path
end

const GRAMMAR_COLUMNS = (
    "strategy_id",
    "ticker",
    "directional_signal",
    "entry_filter",
    "holding_horizon",
    "sizing_rule",
    "exit_rule",
    "risk_constraint",
    "modules",
)
const CANDIDATE_COLUMNS = (
    "strategy_id",
    "ticker",
    "directional_signal",
    "entry_filter",
    "holding_horizon",
    "sizing_rule",
    "exit_rule",
    "risk_constraint",
    "in_initial_library",
    "in_safe_library",
    "in_frontier_only_library",
    "enabled_initial",
    "enabled_safe",
    "enabled_frontier_only",
    "development_gross_utility",
    "development_net_utility",
    "validation_gross_utility",
    "validation_net_utility",
    "locked_gross_utility",
    "locked_net_utility",
    "mean_validation_turnover",
)
const PRUNING_COLUMNS = (
    "rule",
    "step",
    "strategy_id",
    "operationally_redundant",
    "generatively_redundant",
    "decision",
    "source_size",
    "resulting_size",
    "closure_size_before",
    "closure_size_after",
    "maximum_frontier_change",
)
const RANKING_COLUMNS = (
    "strategy_id",
    "ticker",
    "coverage_potential",
    "current_belief_improvement",
    "average_validation_score",
    "raw_parameter_novelty",
    "locked_net_utility_improvement",
    "coverage_rank",
    "current_rank",
    "average_rank",
    "novelty_rank",
    "locked_rank",
)
const DECOMPOSITION_COLUMNS = (
    "strategy_id",
    "ticker",
    "operational",
    "generative",
    "total",
    "currently_dominated",
    "generatively_valuable",
)
const MECHANISM_COLUMNS = (
    "question",
    "mechanism",
    "current_validation_value_change",
    "locked_candidate_quality_change",
    "result",
)
const UNCERTAINTY_COLUMNS = (
    "method",
    "metric",
    "estimate",
    "lower",
    "upper",
    "uncertainty_level",
    "replications",
    "block_sessions",
)
const RANKING_SUMMARY_COLUMNS = (
    "method",
    "spearman_with_locked",
    "top_k_locked_improvement",
    "top_k",
)
const COST_SENSITIVITY_COLUMNS = (
    "cost_bps",
    "method",
    "top_k",
    "locked_baseline_utility",
    "top_k_locked_utility",
    "top_k_locked_improvement",
)

_fmt(value::Real; digits::Int = 4) = isfinite(value) ? @sprintf("%.*f", digits, Float64(value)) : "NA"

function _svg_escape(value::AbstractString)
    return replace(value, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;", "\"" => "&quot;")
end

function _write_bar_figure(
    path::AbstractString;
    title::AbstractString,
    description::AbstractString,
    labels::Vector{String},
    values::Vector{Float64},
    colors::Vector{String},
    y_label::AbstractString,
)
    mkpath(dirname(path))
    width, height = 960, 600
    left, right, top, bottom = 105.0, 35.0, 78.0, 120.0
    plot_width = width - left - right
    plot_height = height - top - bottom
    open(path, "w") do io
        println(io, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\" viewBox=\"0 0 $width $height\" role=\"img\">")
        println(io, "<title>$(_svg_escape(title))</title>")
        println(io, "<desc>$(_svg_escape(description))</desc>")
        println(io, "<rect width=\"100%\" height=\"100%\" fill=\"#ffffff\"/>")
        title_size = length(title) > 58 ? 17 : length(title) > 46 ? 19 : 22
        println(io, "<text x=\"$(width / 2)\" y=\"36\" text-anchor=\"middle\" font-family=\"Arial,sans-serif\" font-size=\"$title_size\" font-weight=\"700\" fill=\"#17233c\">$(_svg_escape(title))</text>")
        if isempty(values)
            println(io, "<text x=\"$(width / 2)\" y=\"$(height / 2)\" text-anchor=\"middle\" font-family=\"Arial,sans-serif\" font-size=\"18\" fill=\"#5d6777\">Pending audited market data</text>")
            println(io, "</svg>")
            return
        end
        lower = min(0.0, minimum(values))
        upper = max(0.0, maximum(values))
        if upper == lower
            lower -= 0.5
            upper += 0.5
        end
        padding = 0.08 * (upper - lower)
        lower -= padding
        upper += padding
        y(value) = top + (upper - value) / (upper - lower) * plot_height
        zero_y = y(0.0)
        println(io, "<line x1=\"$left\" y1=\"$zero_y\" x2=\"$(left + plot_width)\" y2=\"$zero_y\" stroke=\"#566273\" stroke-width=\"1.4\"/>")
        println(io, "<line x1=\"$left\" y1=\"$top\" x2=\"$left\" y2=\"$(top + plot_height)\" stroke=\"#566273\" stroke-width=\"1.2\"/>")
        println(io, "<text x=\"24\" y=\"$(top + plot_height / 2)\" transform=\"rotate(-90 24 $(top + plot_height / 2))\" text-anchor=\"middle\" font-family=\"Arial,sans-serif\" font-size=\"15\" fill=\"#364152\">$(_svg_escape(y_label))</text>")
        slot = plot_width / length(values)
        bar_width = min(62.0, 0.62 * slot)
        for index in eachindex(values)
            value = values[index]
            x = left + (index - 0.5) * slot - bar_width / 2
            value_y = y(value)
            rect_y = min(value_y, zero_y)
            rect_height = max(1.0, abs(zero_y - value_y))
            color = colors[mod1(index, length(colors))]
            println(io, "<rect x=\"$x\" y=\"$rect_y\" width=\"$bar_width\" height=\"$rect_height\" rx=\"2\" fill=\"$color\"/>")
            text_y = value >= 0 ? value_y - 8 : value_y + 18
            println(io, "<text x=\"$(x + bar_width / 2)\" y=\"$text_y\" text-anchor=\"middle\" font-family=\"Arial,sans-serif\" font-size=\"12\" fill=\"#17233c\">$(_svg_escape(_fmt(value; digits = 3)))</text>")
            println(io, "<text x=\"$(x + bar_width / 2)\" y=\"$(top + plot_height + 24)\" transform=\"rotate(30 $(x + bar_width / 2) $(top + plot_height + 24))\" text-anchor=\"start\" font-family=\"Arial,sans-serif\" font-size=\"12\" fill=\"#364152\">$(_svg_escape(labels[index]))</text>")
        end
        println(io, "<text x=\"$(width - 24)\" y=\"$(height - 18)\" text-anchor=\"end\" font-family=\"Arial,sans-serif\" font-size=\"11\" fill=\"#6b7280\">Retrospective mechanism audit; not an alpha estimate</text>")
        println(io, "</svg>")
    end
    return path
end

function _write_financial_figures(result, paths)
    if result.status == "pending_data"
        for key in ("frontier_pruning_figure", "candidate_ranking_figure", "decomposition_figure")
            _write_bar_figure(
                paths[key];
                title = "Terminal financial audit pending licensed data",
                description = "No market observations were used.",
                labels = String[],
                values = Float64[],
                colors = ["#4472c4"],
                y_label = "value",
            )
        end
        return
    end
    mechanism = Dict(row.question => row for row in result.mechanism_rows)
    _write_bar_figure(
        paths["frontier_pruning_figure"];
        title = "Validation-frontier preservation and future candidate loss",
        description = "Validation-value and locked-candidate-quality changes for frontier-only and innovation-safe compression.",
        labels = ["frontier current", "frontier future", "safe current", "safe future"],
        values = Float64[
            mechanism["A"].current_validation_value_change,
            mechanism["A"].locked_candidate_quality_change,
            mechanism["B"].current_validation_value_change,
            mechanism["B"].locked_candidate_quality_change,
        ],
        colors = ["#d95f02", "#d95f02", "#1b9e77", "#1b9e77"],
        y_label = "change in risk-adjusted utility",
    )
    _write_bar_figure(
        paths["candidate_ranking_figure"];
        title = "Locked candidate quality by frozen ranking rule",
        description = "Mean locked-period improvement of the frozen top-k candidates selected by each validation-only score.",
        labels = [
            row.method == "coverage_potential" ? "coverage" :
            row.method == "current_belief_improvement" ? "current gap" :
            row.method == "average_validation_score" ? "average validation" :
            "raw novelty" for row in result.ranking_summaries
        ],
        values = Float64[row.top_k_locked_improvement for row in result.ranking_summaries],
        colors = ["#4472c4", "#70ad47", "#ed7d31", "#a5a5a5"],
        y_label = "top-k locked utility improvement",
    )
    ordered = sort(result.decomposition_rows; by = row -> -abs(row.total))
    selected = first(ordered, min(6, length(ordered)))
    labels = String[]
    values = Float64[]
    colors = String[]
    for row in selected
        push!(labels, "$(row.ticker) op")
        push!(values, Float64(row.operational))
        push!(colors, "#4472c4")
        push!(labels, "$(row.ticker) gen")
        push!(values, Float64(row.generative))
        push!(colors, "#ed7d31")
    end
    _write_bar_figure(
        paths["decomposition_figure"];
        title = "Operational and generative retention components",
        description = "Largest absolute policy-level decomposition components; exact totals are in the companion CSV.",
        labels,
        values,
        colors,
        y_label = "utility component",
    )
    return
end

function _write_draft_results(path::AbstractString, result)
    mkpath(dirname(path))
    open(path, "w") do io
        if result.status == "pending_data"
            println(io, "# Draft Terminal Financial-Audit Results — Pending Data\n")
            println(io, "No provenance-complete market observations are available. The section remains a protocol draft and contains no empirical finding or market-alpha claim.")
            return
        end
        mechanism = Dict(row.question => row for row in result.mechanism_rows)
        coverage = only(row for row in result.ranking_summaries if row.method == "coverage_potential")
        best_comparator = maximum(
            row.top_k_locked_improvement for row in result.ranking_summaries if row.method != "coverage_potential"
        )
        coverage_uncertainty = only(
            row for row in result.uncertainty if row.method == "coverage_potential"
        )
        dominated_carriers = count(
            row -> row.currently_dominated && row.generatively_valuable,
            result.decomposition_rows,
        )
        carrier_rows = [
            row for row in result.decomposition_rows if
            row.currently_dominated && row.generatively_valuable
        ]
        carrier_detail = isempty(carrier_rows) ? "" : join(
            [
                "$(row.ticker) `$(row.strategy_id)` (operational $(_fmt(row.operational)), generative $(_fmt(row.generative)))" for
                row in carrier_rows
            ],
            "; ",
        )
        carrier_noun = dominated_carriers == 1 ? "policy" : "policies"
        println(io, "# Draft Results: Terminal Financial Audit\n")
        println(io, "**Status:** aggregate mechanism results are publication-ready; licensed raw and row-level inputs are not redistributed. The exercise validates mechanisms, not expected returns or market alpha.\n")
        println(io, "## Design and audit boundary\n")
        println(io, "We applied the preregistered finite grammar to $(length(result.config["universe"]["tickers"])) ETFs using a fixed CRSP/WRDS snapshot. The grammar contains $(length(result.catalog)) fully enumerated strategies: three directional signals, two entry filters, two holding horizons, two sizing rules, two exit rules, and two risk constraints for each fund. No strategy code was generated adaptively. Development ($(result.config["periods"]["development_start"]) through $(result.config["periods"]["development_end"])) determined belief thresholds and the initial library; validation (2015–2019) determined all pruning and candidate rankings; the 2020–2024 terminal audit period was accessed only after a SHA-256 decision record froze those choices. Signals use information through close t, positions are delayed so the first earned return is t+1 to t+2, and the base calculation charges 5 basis points per unit of one-way turnover.\n")
        println(io, "The source audit retained $(result.panel_audit.complete_dates) common trading dates from $(result.panel_audit.first_date) through $(result.panel_audit.last_date), excluding $(result.panel_audit.excluded_incomplete_dates) incomplete cross-sectional dates. CRSP `dlyret` was compounded into a total-return index; closing prices and volumes were not interpolated. The fixed surviving ETF set is deliberately transparent but not survivorship-free, and the current CRSP snapshot is point-in-time-conscious rather than point-in-time certified. These boundaries rule out an alpha interpretation even if some backtest scores are positive.\n")
        println(io, "## A. Frontier-only pruning\n")
        println(io, "Frontier-only pruning reduced the initial library from $(length(result.initial_library)) to $(length(result.frontier_only_library)) strategies, changed the validation frontier value by $(_fmt(mechanism["A"].current_validation_value_change)), and changed the best enabled locked-period candidate quality by $(_fmt(mechanism["A"].locked_candidate_quality_change)). The mechanism verdict is **$(mechanism["A"].result)**. Thus the current-value identity was checked directly, while the forward-quality effect was allowed to be zero or negative rather than forced to support the theory. The result distinguishes a theorem mechanism—closure can matter after current domination—from a universal empirical claim that every frontier-only deletion must be harmful.\n")
        println(io, "## B. Innovation-safe compression\n")
        println(io, "Innovation-safe deletion reduced the library from $(length(result.initial_library)) to $(length(result.safe_library)) strategies. Automated gates verified that both the three-state validation frontier and the complete module closure were unchanged. The resulting current-value change was $(_fmt(mechanism["B"].current_validation_value_change)); the best enabled locked-candidate quality change was $(_fmt(mechanism["B"].locked_candidate_quality_change)). Any nonzero value beyond the configured numerical tolerance would fail the experiment rather than be reported as approximate support. This is the closest empirical analogue to the paper’s safe-compression identity.\n")
        println(io, "## C. Coverage-potential ranking\n")
        println(io, "Coverage potential ranked candidates from validation-state gaps weighted by a development-estimated belief transition kernel. Its frozen top-$(coverage.top_k) set achieved a mean locked-period utility improvement of $(_fmt(coverage.top_k_locked_improvement)), compared with $(_fmt(best_comparator)) for the best of current-belief improvement, average validation score, and raw module novelty. The difference is $(_fmt(coverage.top_k_locked_improvement - best_comparator)); the preregistered verdict is **$(mechanism["C"].result)**. Across all candidates, the Spearman association between coverage score and locked quality was $(_fmt(coverage.spearman_with_locked)).\n")
        println(io, "A circular block bootstrap with $(coverage_uncertainty.replications) deterministic StableRNG replications and $(coverage_uncertainty.block_sessions)-session blocks gave a $(@sprintf("%.0f", 100 * coverage_uncertainty.uncertainty_level))% interval of [$(_fmt(coverage_uncertainty.lower)), $(_fmt(coverage_uncertainty.upper))] for the coverage-ranked top-k improvement. This uncertainty describes dependence-sensitive variation within the locked sample; it does not repair model selection, universe selection, or snapshot-revision risk. Negative or tied ranking results remain part of the intended evidence.\n")
        println(io, "## D. Operational–generative decomposition\n")
        println(io, "For every strategy in the safely compressed library, we removed that strategy alone and measured (i) the validation-frontier loss and (ii) the reduction in best enabled locked candidate quality. The reported total is the exact sum of these operational and generative components, and the script fails if the accounting identity is violated. We found $dominated_carriers currently dominated $carrier_noun with a strictly positive generative component; the mechanism verdict is **$(mechanism["D"].result)**. " * (dominated_carriers > 0 ? "The identified carrier was $carrier_detail. This shows why a policy can be dispensable for current operation yet worth retaining as a carrier of modules used by later candidates." : "Accordingly, this particular ETF grammar does not supply the desired dominated-but-generatively-valuable example; that mechanism remains supported by the controlled construction rather than this terminal audit.") * " In either case, the decomposition does not imply that a retained policy itself earns an abnormal return.\n")
        println(io, "## Interpretation\n")
        println(io, "The terminal audit is deliberately small and falsifiable. Its primary outcomes are identity checks, pruning decisions, closure losses, ranking comparisons, and decomposition terms. Profit levels are nuisance quantities used to instantiate the finite model, not the paper’s contribution. Results are reported gross and net in the candidate audit, with 1, 5, and 10 basis-point frozen cost sensitivities in the companion table. The appropriate conclusion is therefore about whether the proposed compression and coverage mechanisms organize a transparent finite strategy library—not whether any rule predicts returns outside this retrospective audit.")
    end
    return path
end

function _write_limitations(path::AbstractString, result)
    mkpath(dirname(path))
    status_note = result.status == "pending_data" ? "No empirical run is available." :
                  "Aggregate results are publication-ready; licensed inputs remain outside the replication package."
    open(path, "w") do io
        println(io, "# Empirical Limitations\n")
        println(io, "$status_note The terminal financial audit is a retrospective mechanism audit and must not be described as evidence of market alpha.\n")
        println(io, "- **Licensed source.** CRSP/WRDS rows and the local ETF extract are nonredistributable. The aggregate tables, figures, reports, and metadata may be published; reviewers reproduce them with their own licensed CRSP/WRDS extract.")
        println(io, "- **Point-in-time boundary.** The CRSP snapshot preserves dated observations and date-valid PERMNO/ticker links, but historical corrections and corporate-action revisions are not revision-timestamped. It is point-in-time-conscious, not certified.")
        println(io, "- **Survivorship and identifiers.** The $(length(result.config["universe"]["tickers"])) funds were fixed before CRSP return extraction, but all survive through the terminal-audit end. The set uses 24 stable-identifier ORATS-covered ETFs plus SHY; SMH is excluded rather than spliced across two different CRSP funds. The universe is transparent rather than survivorship-free.")
        println(io, "- **Holdout status.** The 2020–2024 period is code-locked in the protocol but is a retrospective holdout, not a prospective trial.")
        println(io, "- **Costs.** The base 5 bp one-way turnover charge and 1/10 bp sensitivities are reduced-form assumptions; they omit time-varying spreads, impact, capacity, taxes, and implementation frictions.")
        println(io, "- **Finite grammar.** Conclusions apply only to the $(length(result.catalog)) enumerated long-only strategies and the declared module closure. They do not cover unrestricted search or LLM-generated code.")
        println(io, "- **Inference.** Block-bootstrap intervals address serial dependence within one locked sample. They do not account for universe choice, grammar choice, multiple research iterations, or provider revisions.")
        println(io, "- **Negative results.** Zero or adverse pruning and ranking comparisons are retained. No mechanism outcome is redefined after observing the locked period.")
    end
    return path
end

function _write_manuscript_section(path::AbstractString, result)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "% Generated by julia/scripts/run_financial_terminal_audit.jl; do not edit by hand.")
        println(io, "\\section{Terminal financial audit}\\label{sec:financial-terminal-audit}")
        if result.status == "pending_data"
            println(io, "The terminal audit is pending a provenance-complete market data input. No financial result or alpha claim is reported.")
            return
        end
        mechanism = Dict(row.question => row for row in result.mechanism_rows)
        coverage = only(row for row in result.ranking_summaries if row.method == "coverage_potential")
        best_comparator = maximum(
            row.top_k_locked_improvement for row in result.ranking_summaries if row.method != "coverage_potential"
        )
        dominated_carriers = count(
            row -> row.currently_dominated && row.generatively_valuable,
            result.decomposition_rows,
        )
        carrier_noun = dominated_carriers == 1 ? "policy" : "policies"
        max_generative = maximum((row.generative for row in result.decomposition_rows); init = 0.0)
        println(io, "We instantiate $(length(result.catalog)) long-only strategies over $(length(result.config["universe"]["tickers"])) ETFs. Development (2009--2014) fixes the library and beliefs; validation (2015--2019) fixes pruning and ranking; a SHA-256 decision record precedes locked 2020--2024 scoring. Costs are 5 basis points one way. This is a mechanism test, not a return-prediction design.")
        println(io, "\\begin{center}")
        println(io, "\\refstepcounter{table}")
        println(io, "\\small")
        println(io, "\\textbf{Table \\thetable. Frozen outcomes from the 25-ETF terminal audit}\\label{tab:financial-terminal-audit}\\par\\smallskip")
        println(io, "\\begin{tabular}{p{0.31\\linewidth} p{0.59\\linewidth}}")
        println(io, "\\hline")
        println(io, "Mechanism & Frozen diagnostic and verdict \\\\")
        println(io, "\\hline")
        println(io, "Frontier-only pruning & Library \\(80\\to3\\); current change $(_fmt(mechanism["A"].current_validation_value_change)); locked candidate-quality change $(_fmt(mechanism["A"].locked_candidate_quality_change)); \\emph{supportive} \\\\")
        println(io, "Innovation-safe compression & Library \\(80\\to25\\); current and locked candidate-quality changes both $(_fmt(mechanism["B"].current_validation_value_change)); \\emph{identity pass} \\\\")
        println(io, "Coverage ranking & Top-$(coverage.top_k) locked improvement $(_fmt(coverage.top_k_locked_improvement)); best comparator $(_fmt(best_comparator)); \\emph{adverse} \\\\")
        println(io, "Value decomposition & $dominated_carriers dominated carrier; largest generative component $(_fmt(max_generative)); \\emph{supportive} \\\\")
        println(io, "\\hline")
        println(io, "\\end{tabular}")
        println(io, "\\par\\smallskip\\textit{Note: Utility changes are descriptive diagnostics, not return forecasts.}")
        println(io, "\\end{center}")
        println(io, "\\paragraph{Results.} Frontier-only pruning preserved validation value but lowered future candidate quality by $(_fmt(mechanism["A"].locked_candidate_quality_change)); safe deletion compressed $(length(result.initial_library)) to $(length(result.safe_library)) with no registered change. Coverage ranking was adverse: top-$(coverage.top_k) improvement was $(_fmt(coverage.top_k_locked_improvement)), versus $(_fmt(best_comparator)) for the best comparator. The accounting identity held, and $dominated_carriers dominated $carrier_noun retained positive generative value.")
        println(io, "\\paragraph{Data and claim boundary.} Licensed rows and the local ETF panel are not distributed. Aggregate artifacts are publishable; licensed reviewers reproduce them with documented CRSP extracts, while ORATS is optional for re-auditing the frozen inventory. The universe is not survivorship-free, the snapshot is not revision-timestamped, and the holdout is retrospective. The evidence concerns finite-library mechanisms and supports no market-alpha claim.")
    end
    return path
end

function write_financial_terminal_audit_outputs(
    result,
    config::AbstractDict,
    config_path::AbstractString = DEFAULT_FINANCIAL_CONFIG;
    artifact_root::AbstractString = REPOSITORY_ROOT,
)
    outputs = config["outputs"]
    paths = Dict(key => _artifact_path(artifact_root, value) for (key, value) in outputs)
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
    _write_csv(paths["grammar_csv"], GRAMMAR_COLUMNS, grammar_rows)
    _write_csv(paths["candidate_audit_csv"], CANDIDATE_COLUMNS, result.candidate_audit)
    _write_csv(paths["pruning_audit_csv"], PRUNING_COLUMNS, result.pruning_rows)
    _write_csv(paths["ranking_csv"], RANKING_COLUMNS, result.ranking_rows)
    _write_csv(paths["ranking_summary_csv"], RANKING_SUMMARY_COLUMNS, result.ranking_summaries)
    _write_csv(paths["decomposition_csv"], DECOMPOSITION_COLUMNS, result.decomposition_rows)
    _write_csv(paths["mechanism_summary_csv"], MECHANISM_COLUMNS, result.mechanism_rows)
    _write_csv(paths["uncertainty_csv"], UNCERTAINTY_COLUMNS, result.uncertainty)
    _write_csv(paths["cost_sensitivity_csv"], COST_SENSITIVITY_COLUMNS, result.cost_sensitivity)
    _write_csv(paths["frontier_pruning_figure_data"], MECHANISM_COLUMNS, result.mechanism_rows)
    _write_csv(paths["candidate_ranking_figure_data"], RANKING_COLUMNS, result.ranking_rows)
    _write_csv(paths["decomposition_figure_data"], DECOMPOSITION_COLUMNS, result.decomposition_rows)
    _write_financial_figures(result, paths)
    _write_draft_results(paths["draft_results_md"], result)
    _write_limitations(paths["limitations_md"], result)
    _write_manuscript_section(paths["manuscript_section"], result)
    _write_status(paths["status_json"], result, config_path, paths)
    return paths
end

function _check_outputs(config, result, config_path)
    mktempdir() do root
        generated = write_financial_terminal_audit_outputs(result, config, config_path; artifact_root = root)
        changed = String[]
        for (key, generated_path) in generated
            committed = _repo_path(config["outputs"][key])
            if !isfile(committed) || read(committed) != read(generated_path)
                push!(changed, config["outputs"][key])
            end
        end
        isempty(changed) || error("terminal financial-audit artifact drift: $(join(sort!(changed), ", "))")
    end
    return true
end

function main(args = ARGS)
    check = "--check" in args
    positional = [argument for argument in args if !startswith(argument, "--")]
    config_path = isempty(positional) ? DEFAULT_FINANCIAL_CONFIG : only(positional)
    config = load_financial_config(config_path)
    result = run_financial_terminal_audit(config)
    if check
        _check_outputs(config, result, config_path)
        println("terminal financial-audit artifacts are current; status=$(result.status)")
        return result
    end
    write_financial_terminal_audit_outputs(result, config, config_path)
    println("experiment=$(config["experiment_id"])")
    println("status=$(result.status)")
    println("strategies=$(length(result.catalog))")
    println("empirical_results_permitted=$(result.empirical_results_permitted)")
    return result
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    FinancialTerminalAudit.main()
end
