module FinancialStrategyLibraryPanelV3Predecision

include(joinpath(@__DIR__, "FinancialStrategyLibraryPanelV3.jl"))
using .FinancialStrategyLibraryPanelV3: normalize_long_weights

export PortfolioSpecification,
       backtest_portfolio_specification,
       capability_ids,
       portfolio_catalog,
       specification_id,
       strategy_burden

struct PortfolioSpecification
    directional_signal::String
    entry_filter::String
    holding_horizon::Int
    allocation_rule::String
    gross_target::Float64
    exit_rule::String

    function PortfolioSpecification(signal, filter, horizon, allocation, gross, exit_rule)
        signal_text = String(signal)
        filter_text = String(filter)
        horizon_value = Int(horizon)
        allocation_text = String(allocation)
        gross_value = Float64(gross)
        exit_text = String(exit_rule)
        signal_text in ("momentum_20", "momentum_60", "mean_reversion_5") ||
            throw(ArgumentError("unsupported directional signal"))
        filter_text in ("always", "trend_100") ||
            throw(ArgumentError("unsupported entry filter"))
        horizon_value in (5, 20) || throw(ArgumentError("unsupported holding horizon"))
        allocation_text in ("equal_weight", "inverse_volatility") ||
            throw(ArgumentError("unsupported allocation rule"))
        gross_value in (0.5, 1.0) || throw(ArgumentError("unsupported gross target"))
        exit_text in ("horizon", "signal_flip") ||
            throw(ArgumentError("unsupported exit rule"))
        return new(
            signal_text,
            filter_text,
            horizon_value,
            allocation_text,
            gross_value,
            exit_text,
        )
    end
end

function portfolio_catalog()
    result = PortfolioSpecification[]
    for signal in ("momentum_20", "momentum_60", "mean_reversion_5"),
        filter in ("always", "trend_100"),
        horizon in (5, 20),
        allocation in ("equal_weight", "inverse_volatility"),
        gross in (0.5, 1.0),
        exit_rule in ("horizon", "signal_flip")
        push!(result, PortfolioSpecification(
            signal,
            filter,
            horizon,
            allocation,
            gross,
            exit_rule,
        ))
    end
    sort!(result; by = specification_id)
    length(result) == 96 || error("v3 portfolio grammar does not contain 96 specifications")
    return result
end

function specification_id(specification::PortfolioSpecification)
    gross = specification.gross_target == 0.5 ? "0_5" : "1_0"
    return join((
        specification.directional_signal,
        specification.entry_filter,
        specification.holding_horizon,
        specification.allocation_rule,
        gross,
        specification.exit_rule,
    ), '|')
end

function capability_ids(specification::PortfolioSpecification, universe_id)
    universe = String(universe_id)
    data_capability = universe == "liquid_common_equity" ?
        "platform::point_in_time_common_equity_data::v3" :
        universe == "liquid_plain_etf" ?
            "platform::point_in_time_plain_etf_data::v3" :
            throw(ArgumentError("unsupported v3 universe"))
    gross_id = specification.gross_target == 0.5 ? "0_5" : "1_0"
    gross_value = specification.gross_target == 0.5 ? "0.5" : "1.0"
    return sort!([
        "atomic::signal::$(specification.directional_signal)::v3",
        "atomic::filter::$(specification.entry_filter)::v3",
        "atomic::horizon::$(specification.holding_horizon)::v3",
        "atomic::allocation::$(specification.allocation_rule)::v3",
        "atomic::gross::$gross_id::v3",
        "atomic::exit::$(specification.exit_rule)::v3",
        "interface::signal_filter::$(specification.directional_signal)+$(specification.entry_filter)::v3",
        "interface::horizon_exit::$(specification.holding_horizon)+$(specification.exit_rule)::v3",
        "interface::allocation_gross::$(specification.allocation_rule)+$gross_value::v3",
        data_capability,
        "platform::corporate_action_and_delisting::v3",
        "platform::portfolio_aggregation::v3",
        "platform::cost_and_capacity_model::v3",
    ])
end

function strategy_burden(specification::PortfolioSpecification)
    signal = Dict("momentum_20" => 20, "momentum_60" => 60, "mean_reversion_5" => 5)
    filter = Dict("always" => 0, "trend_100" => 100)
    horizon = Dict(5 => 51, 20 => 13)
    allocation = Dict("equal_weight" => 5, "inverse_volatility" => 25)
    exit = Dict("horizon" => 5, "signal_flip" => 252)
    return 100 + signal[specification.directional_signal] +
           filter[specification.entry_filter] + horizon[specification.holding_horizon] +
           allocation[specification.allocation_rule] + exit[specification.exit_rule]
end

function _total_return_index(returns, available, terminal_delisting)
    sessions, securities = size(returns)
    result = fill(NaN, sessions, securities)
    for security in 1:securities
        value = 1.0
        valid_history = true
        alive = true
        for session in 1:sessions
            if alive && valid_history && available[session, security]
                value *= 1 + returns[session, security]
                result[session, security] = value
            else
                valid_history = false
            end
            terminal_delisting[session, security] && (alive = false)
        end
    end
    return result
end

function _lookback_return(index, session, security, lookback)
    session > lookback || return NaN
    base = index[session - lookback, security]
    isfinite(base) && base > 0 || return NaN
    return index[session, security] / base - 1
end

function _rolling_mean(index, session, security, lookback)
    session >= lookback || return NaN
    return sum(@view index[(session - lookback + 1):session, security]) / lookback
end

function _rolling_volatility(returns, available, session, security; lookback = 20)
    session >= lookback || return NaN
    all(@view available[(session - lookback + 1):session, security]) || return NaN
    values = @view returns[(session - lookback + 1):session, security]
    average = sum(values) / lookback
    variance = sum((value - average)^2 for value in values) / (lookback - 1)
    return sqrt(252 * variance)
end

function _volatility_scaled_weights(
    weights,
    returns,
    available,
    session;
    target,
    lookback = 20,
)
    sum(weights) > 0 || return zeros(Float64, length(weights))
    session >= lookback || return zeros(Float64, length(weights))
    positive = findall(>(0), weights)
    first_session = session - lookback + 1
    all(
        available[history_session, security]
        for history_session in first_session:session for security in positive
    ) || return zeros(Float64, length(weights))
    portfolio_returns = [
        sum(weights[security] * returns[history_session, security] for security in positive)
        for history_session in first_session:session
    ]
    average = sum(portfolio_returns) / lookback
    variance = sum((value - average)^2 for value in portfolio_returns) / (lookback - 1)
    annualized_volatility = sqrt(252 * variance)
    isfinite(annualized_volatility) || return zeros(Float64, length(weights))
    iszero(annualized_volatility) && return Float64.(weights)
    scale = min(1.0, Float64(target) / annualized_volatility)
    return scale .* weights
end

function _signal(specification, index, session, security)
    if specification.directional_signal == "momentum_20"
        value = _lookback_return(index, session, security, 20)
        return isfinite(value) && value > 0
    elseif specification.directional_signal == "momentum_60"
        value = _lookback_return(index, session, security, 60)
        return isfinite(value) && value > 0
    end
    value = _lookback_return(index, session, security, 5)
    return isfinite(value) && value < 0
end

function _filter(specification, index, session, security)
    specification.entry_filter == "always" && return true
    average = _rolling_mean(index, session, security, 100)
    return isfinite(average) && index[session, security] > average
end

function backtest_portfolio_specification(
    specification::PortfolioSpecification,
    security_returns::AbstractMatrix;
    security_weight_cap::Real,
    decision_to_first_return_lag_sessions::Integer = 2,
    one_way_cost_bps::Real = 5.0,
    portfolio_volatility_target::Real = 0.10,
    return_available = .!ismissing.(security_returns),
    terminal_delisting = falses(size(security_returns)),
)
    size(return_available) == size(security_returns) ||
        throw(DimensionMismatch("return-availability panel does not align"))
    size(terminal_delisting) == size(security_returns) ||
        throw(DimensionMismatch("terminal-delisting panel does not align"))
    available = Bool.(return_available)
    terminal = Bool.(terminal_delisting)
    returns = zeros(Float64, size(security_returns))
    for index in eachindex(security_returns)
        value = security_returns[index]
        if available[index]
            ismissing(value) &&
                throw(ArgumentError("an available portfolio return cannot be missing"))
            converted = Float64(value)
            isfinite(converted) ||
                throw(ArgumentError("an available portfolio return must be finite"))
            converted >= -1 ||
                throw(ArgumentError("portfolio security return is below total loss"))
            returns[index] = converted
        elseif !ismissing(value)
            converted = Float64(value)
            isfinite(converted) ||
                throw(ArgumentError("an unavailable return sentinel must be finite or missing"))
        end
    end
    sessions, securities = size(returns)
    sessions > 0 && securities > 0 || throw(ArgumentError("portfolio return panel is empty"))
    all(terminal .<= available) ||
        throw(ArgumentError("every terminal delisting requires an observed return"))
    for security in 1:securities
        terminal_sessions = findall(@view terminal[:, security])
        length(terminal_sessions) <= 1 ||
            throw(ArgumentError("a security has multiple terminal delistings"))
        if !isempty(terminal_sessions)
            terminal_session = only(terminal_sessions)
            any(@view available[(terminal_session + 1):end, security]) &&
                throw(ArgumentError("a security has observed returns after terminal delisting"))
        end
    end
    cap = Float64(security_weight_cap)
    isfinite(cap) && cap > 0 || throw(ArgumentError("security weight cap is invalid"))
    volatility_target = Float64(portfolio_volatility_target)
    isfinite(volatility_target) && volatility_target > 0 ||
        throw(ArgumentError("portfolio volatility target is invalid"))
    lag = Int(decision_to_first_return_lag_sessions)
    lag >= 1 || throw(ArgumentError("portfolio implementation lag must be positive"))

    index = _total_return_index(returns, available, terminal)
    active = falses(securities)
    age = zeros(Int, securities)
    intended = zeros(Float64, sessions, securities)
    for session in 1:sessions
        raw = zeros(Float64, securities)
        for security in 1:securities
            if terminal[session, security] || !available[session, security]
                active[security] = false
                age[security] = 0
                continue
            end
            signal = _signal(specification, index, session, security)
            filter_passes = _filter(specification, index, session, security)
            if !active[security]
                if signal && filter_passes
                    active[security] = true
                    age[security] = 1
                end
            else
                should_exit = age[security] >= specification.holding_horizon ||
                    (specification.exit_rule == "signal_flip" && !signal)
                if should_exit
                    active[security] = false
                    age[security] = 0
                else
                    age[security] += 1
                end
            end
            active[security] || continue
            if specification.allocation_rule == "equal_weight"
                raw[security] = 1.0
            else
                volatility = _rolling_volatility(
                    returns,
                    available,
                    session,
                    security,
                )
                isfinite(volatility) && volatility > 0 && (raw[security] = 1 / volatility)
            end
        end
        positive_count = count(>(0), raw)
        realized_gross = min(specification.gross_target, positive_count * cap)
        if realized_gross > 0
            capped_weights = normalize_long_weights(
                raw;
                gross_target = realized_gross,
                security_weight_cap = cap,
            )
            intended[session, :] .= _volatility_scaled_weights(
                capped_weights,
                returns,
                available,
                session;
                target = volatility_target,
            )
        end
    end
    effective = zeros(Float64, sessions, securities)
    if sessions > lag
        effective[(lag + 1):end, :] .= @view intended[1:(end - lag), :]
    end
    for security in 1:securities
        terminal_sessions = findall(@view terminal[:, security])
        isempty(terminal_sessions) && continue
        terminal_session = only(terminal_sessions)
        terminal_session < sessions && (effective[(terminal_session + 1):end, security] .= 0)
    end

    cost = Float64(one_way_cost_bps) / 10_000
    isfinite(cost) && cost >= 0 || throw(ArgumentError("transaction cost is invalid"))
    turnover = zeros(Float64, sessions)
    turnover[1] = sum(abs, @view effective[1, :])
    for session in 2:sessions
        turnover[session] = sum(
            abs(effective[session, security] - effective[session - 1, security])
            for security in 1:securities
        )
    end
    observation_available = [
        all(available[session, security] || iszero(effective[session, security])
            for security in 1:securities)
        for session in 1:sessions
    ]
    gross_returns = Vector{Union{Missing,Float64}}(missing, sessions)
    net_returns = Vector{Union{Missing,Float64}}(missing, sessions)
    cost_returns = Vector{Union{Missing,Float64}}(missing, sessions)
    for session in 1:sessions
        observation_available[session] || continue
        gross = sum(effective[session, :] .* returns[session, :])
        session_cost = cost * turnover[session]
        gross_returns[session] = gross
        cost_returns[session] = session_cost
        net_returns[session] = gross - session_cost
    end
    portfolio = (;
        gross_returns,
        net_returns,
        cost_returns,
        turnover,
        available = observation_available,
    )
    return merge(portfolio, (; intended_weights = intended, effective_weights = effective))
end

end # module
