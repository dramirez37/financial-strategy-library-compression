module FinancialStrategyLibraryPanelV3

using SHA: sha256

export PortfolioAlternative,
       PolicyChoice,
       aggregate_portfolio_returns,
       annualized_certainty_equivalent,
       capacity_adjusted_portfolio_returns,
       family_shrunk_score,
       frontier_policy_choice,
       innovation_safe_policy_choice,
       normalize_long_weights,
       policy_contrast,
       stable_seed,
       validate_nested_action_sets

"""One proposal-year portfolio alternative and its frozen uncertainty certificate."""
struct PortfolioAlternative
    candidate_id::String
    estimated_certainty_equivalent::Float64
    simultaneous_lower_bound_advantage::Float64
    realized_certainty_equivalent::Union{Missing,Float64}

    function PortfolioAlternative(
        candidate_id,
        estimated_certainty_equivalent,
        simultaneous_lower_bound_advantage,
        realized_certainty_equivalent = missing,
    )
        id = String(candidate_id)
        isempty(id) && throw(ArgumentError("portfolio candidate identifier cannot be empty"))
        estimate = Float64(estimated_certainty_equivalent)
        lower = Float64(simultaneous_lower_bound_advantage)
        isfinite(estimate) || throw(ArgumentError("estimated certainty equivalent must be finite"))
        isfinite(lower) || throw(ArgumentError("simultaneous lower bound must be finite"))
        realized = ismissing(realized_certainty_equivalent) ? missing :
            Float64(realized_certainty_equivalent)
        !ismissing(realized) && !isfinite(realized) &&
            throw(ArgumentError("realized certainty equivalent must be finite or missing"))
        return new(id, estimate, lower, realized)
    end
end

"""A frozen policy choice, including its always-feasible outside-option reason."""
struct PolicyChoice
    candidate_id::String
    estimated_certainty_equivalent::Float64
    realized_certainty_equivalent::Union{Missing,Float64}
    reason::String
end

function _ordered_best(alternatives)
    isempty(alternatives) && return nothing
    ordered = sort!(collect(alternatives); by = alternative -> (
        -alternative.estimated_certainty_equivalent,
        alternative.candidate_id,
    ))
    return first(ordered)
end

"""
    frontier_policy_choice(alternatives; cash_certainty_equivalent=0, hurdle=0.0025)

Choose the highest estimated active alternative among candidates whose
simultaneous lower confidence bound over cash clears the registered economic
hurdle. Exact ties and candidates without a certified advantage default to
cash.
"""
function frontier_policy_choice(
    alternatives;
    cash_certainty_equivalent::Real = 0.0,
    hurdle::Real = 0.0025,
)
    cash = Float64(cash_certainty_equivalent)
    isfinite(cash) || throw(ArgumentError("cash certainty equivalent must be finite"))
    threshold = Float64(hurdle)
    isfinite(threshold) && threshold >= 0 ||
        throw(ArgumentError("the adoption hurdle must be finite and nonnegative"))
    eligible = filter(
        alternative -> alternative.simultaneous_lower_bound_advantage > threshold,
        collect(alternatives),
    )
    best = _ordered_best(eligible)
    if isnothing(best)
        return PolicyChoice("mandatory_inactive_cash", cash, cash, "cash_outside_option")
    end
    return PolicyChoice(
        best.candidate_id,
        best.estimated_certainty_equivalent,
        best.realized_certainty_equivalent,
        "certified_active_candidate_above_cash",
    )
end

"""
    innovation_safe_policy_choice(comparator_choice, safe_only_alternatives; hurdle)

Default to the exact comparator choice. Adopt a safe-only alternative only when
its simultaneous lower confidence bound for incremental certainty equivalent
strictly exceeds the registered economic hurdle.
"""
function innovation_safe_policy_choice(
    comparator_choice::PolicyChoice,
    safe_only_alternatives;
    hurdle::Real = 0.0025,
)
    threshold = Float64(hurdle)
    isfinite(threshold) && threshold >= 0 ||
        throw(ArgumentError("the adoption hurdle must be finite and nonnegative"))
    eligible = filter(
        alternative -> alternative.simultaneous_lower_bound_advantage > threshold,
        collect(safe_only_alternatives),
    )
    best = _ordered_best(eligible)
    isnothing(best) && return PolicyChoice(
        comparator_choice.candidate_id,
        comparator_choice.estimated_certainty_equivalent,
        comparator_choice.realized_certainty_equivalent,
        "default_to_exact_comparator_choice",
    )
    return PolicyChoice(
        best.candidate_id,
        best.estimated_certainty_equivalent,
        best.realized_certainty_equivalent,
        "closure_enabled_candidate_clears_simultaneous_hurdle",
    )
end

"""Verify the registered nesting condition before any proposal score is used."""
function validate_nested_action_sets(comparator_candidate_ids, safe_candidate_ids)
    comparator = Set(String.(collect(comparator_candidate_ids)))
    safe = Set(String.(collect(safe_candidate_ids)))
    "mandatory_inactive_cash" in comparator ||
        throw(ArgumentError("comparator action set omits mandatory cash"))
    "mandatory_inactive_cash" in safe ||
        throw(ArgumentError("safe action set omits mandatory cash"))
    issubset(comparator, safe) ||
        throw(ArgumentError("safe action set does not contain the comparator action set"))
    return true
end

"""Return the realized safe-minus-comparator contrast without imputing outcomes."""
function policy_contrast(safe::PolicyChoice, comparator::PolicyChoice)
    available = !ismissing(safe.realized_certainty_equivalent) &&
                !ismissing(comparator.realized_certainty_equivalent)
    return (
        available,
        value = available ? safe.realized_certainty_equivalent -
                            comparator.realized_certainty_equivalent : missing,
        same_choice = safe.candidate_id == comparator.candidate_id,
    )
end

"""Annualized arithmetic certainty equivalent using the sample variance."""
function annualized_certainty_equivalent(
    returns;
    annualization_sessions::Integer = 252,
    risk_aversion::Real = 3.0,
)
    values = Float64.(collect(returns))
    isempty(values) && throw(ArgumentError("certainty equivalent needs return observations"))
    all(isfinite, values) || throw(ArgumentError("returns must be finite"))
    annualization_sessions > 0 || throw(ArgumentError("annualization must be positive"))
    risk = Float64(risk_aversion)
    isfinite(risk) && risk >= 0 ||
        throw(ArgumentError("risk aversion must be finite and nonnegative"))
    average = sum(values) / length(values)
    variance = length(values) == 1 ? 0.0 :
        sum((value - average)^2 for value in values) / (length(values) - 1)
    mean_component = annualization_sessions * average
    variance_penalty = 0.5 * risk * annualization_sessions * variance
    return (
        certainty_equivalent = mean_component - variance_penalty,
        mean_component,
        variance_penalty,
        daily_mean = average,
        daily_variance = variance,
        observation_count = length(values),
    )
end

"""Locked linear shrinkage of a proposal score toward its strategy-family prior."""
function family_shrunk_score(
    proposal_score::Real,
    family_prior_score::Real,
    proposal_sessions::Integer;
    prior_strength_sessions::Real = 252,
)
    proposal_sessions >= 0 || throw(ArgumentError("proposal sessions cannot be negative"))
    prior = Float64(prior_strength_sessions)
    isfinite(prior) && prior >= 0 ||
        throw(ArgumentError("prior strength must be finite and nonnegative"))
    denominator = proposal_sessions + prior
    iszero(denominator) && return Float64(family_prior_score)
    weight = proposal_sessions / denominator
    return weight * Float64(proposal_score) + (1 - weight) * Float64(family_prior_score)
end

"""Derive a platform-stable nonnegative 31-bit seed from a registered scope."""
function stable_seed(base_seed::Integer, purpose_id, scope_values...)
    fields = string.((base_seed, purpose_id, scope_values...))
    digest = sha256(join(fields, '|'))
    value = foldl(
        (accumulator, byte) -> (accumulator << 8) | UInt64(byte),
        @view(digest[1:8]);
        init = UInt64(0),
    )
    return Int(mod(value, UInt64(2_147_483_647)))
end

"""
    normalize_long_weights(raw_weights; gross_target, security_weight_cap)

Normalize nonnegative scores to the requested gross target while enforcing a
per-security cap through deterministic water filling.
"""
function normalize_long_weights(
    raw_weights;
    gross_target::Real,
    security_weight_cap::Real,
)
    raw = Float64.(collect(raw_weights))
    all(value -> isfinite(value) && value >= 0, raw) ||
        throw(ArgumentError("raw long weights must be finite and nonnegative"))
    gross = Float64(gross_target)
    cap = Float64(security_weight_cap)
    isfinite(gross) && gross >= 0 || throw(ArgumentError("gross target is invalid"))
    isfinite(cap) && cap > 0 || throw(ArgumentError("security weight cap is invalid"))
    gross <= length(raw) * cap + 1e-12 ||
        throw(ArgumentError("gross target is infeasible under the security cap"))
    weights = zeros(Float64, length(raw))
    iszero(gross) && return weights
    iszero(sum(raw)) &&
        throw(ArgumentError("a positive gross target requires positive raw support"))
    active = Set(findall(>(0), raw))
    remaining = gross
    while !isempty(active) && remaining > 1e-14
        active_total = sum(raw[index] for index in active)
        iszero(active_total) && break
        capped = Int[]
        for index in active
            proposed = remaining * raw[index] / active_total
            if proposed >= cap - 1e-14
                weights[index] = cap
                push!(capped, index)
            end
        end
        if isempty(capped)
            for index in active
                weights[index] = remaining * raw[index] / active_total
            end
            remaining = 0.0
        else
            for index in capped
                delete!(active, index)
            end
            remaining = gross - sum(weights)
        end
    end
    abs(sum(weights) - gross) <= 1e-10 ||
        throw(ArgumentError("positive raw support cannot satisfy the requested gross target"))
    maximum(weights; init = 0.0) <= cap + 1e-12 || error("weight cap failed")
    return weights
end

"""Aggregate security returns with time-varying long weights and one-way costs."""
function aggregate_portfolio_returns(
    security_returns::AbstractMatrix,
    effective_weights::AbstractMatrix;
    one_way_cost_bps::Real = 5.0,
)
    size(security_returns) == size(effective_weights) ||
        throw(DimensionMismatch("return and weight panels do not align"))
    sessions, securities = size(security_returns)
    sessions > 0 && securities > 0 || throw(ArgumentError("portfolio panel is empty"))
    returns = Float64.(security_returns)
    weights = Float64.(effective_weights)
    all(isfinite, returns) || throw(ArgumentError("security returns must be finite"))
    all(value -> isfinite(value) && value >= 0, weights) ||
        throw(ArgumentError("effective long weights must be finite and nonnegative"))
    cost = Float64(one_way_cost_bps) / 10_000
    isfinite(cost) && cost >= 0 || throw(ArgumentError("transaction cost is invalid"))
    gross_returns = vec(sum(weights .* returns; dims = 2))
    turnover = zeros(Float64, sessions)
    turnover[1] = sum(abs, @view weights[1, :])
    for session in 2:sessions
        turnover[session] = sum(
            abs(weights[session, security] - weights[session - 1, security])
            for security in axes(weights, 2)
        )
    end
    net_returns = gross_returns .- cost .* turnover
    return (; gross_returns, net_returns, turnover)
end

"""
Apply a registered lagged half-spread plus square-root-impact cost surface.

Any session containing an order above the ADV participation cap is unavailable;
the function never truncates that order or invents an execution price.
"""
function capacity_adjusted_portfolio_returns(
    security_returns::AbstractMatrix,
    effective_weights::AbstractMatrix,
    lagged_dollar_volume::AbstractMatrix,
    lagged_volatility::AbstractMatrix;
    aum_usd::Real,
    half_spread_bps::Real,
    square_root_impact_coefficient::Real,
    maximum_daily_adv_participation::Real = 0.10,
)
    panel_size = size(security_returns)
    panel_size == size(effective_weights) == size(lagged_dollar_volume) ==
        size(lagged_volatility) || throw(DimensionMismatch("capacity panels do not align"))
    sessions, securities = panel_size
    sessions > 0 && securities > 0 || throw(ArgumentError("capacity panel is empty"))

    returns = Float64.(security_returns)
    weights = Float64.(effective_weights)
    dollar_volume = Float64.(lagged_dollar_volume)
    volatility = Float64.(lagged_volatility)
    capital = Float64(aum_usd)
    spread = Float64(half_spread_bps) / 10_000
    impact = Float64(square_root_impact_coefficient)
    participation_cap = Float64(maximum_daily_adv_participation)

    all(isfinite, returns) || throw(ArgumentError("security returns must be finite"))
    all(value -> isfinite(value) && value >= 0, weights) ||
        throw(ArgumentError("effective weights must be finite and nonnegative"))
    all(value -> isfinite(value) && value > 0, dollar_volume) ||
        throw(ArgumentError("lagged dollar volume must be finite and positive"))
    all(value -> isfinite(value) && value >= 0, volatility) ||
        throw(ArgumentError("lagged volatility must be finite and nonnegative"))
    isfinite(capital) && capital > 0 || throw(ArgumentError("AUM must be positive"))
    isfinite(spread) && spread >= 0 || throw(ArgumentError("half spread is invalid"))
    isfinite(impact) && impact >= 0 || throw(ArgumentError("impact coefficient is invalid"))
    isfinite(participation_cap) && 0 < participation_cap <= 1 ||
        throw(ArgumentError("ADV participation cap must lie in (0, 1]"))

    gross_returns = vec(sum(weights .* returns; dims = 2))
    available = trues(sessions)
    cost_returns = Vector{Union{Missing,Float64}}(undef, sessions)
    net_returns = Vector{Union{Missing,Float64}}(undef, sessions)
    previous_weights = zeros(Float64, securities)
    for session in 1:sessions
        session_cost = 0.0
        for security in 1:securities
            trade_dollars = capital * abs(weights[session, security] - previous_weights[security])
            participation = trade_dollars / dollar_volume[session, security]
            if participation > participation_cap + 1e-14
                available[session] = false
                break
            end
            per_dollar_cost = spread + impact * volatility[session, security] * sqrt(participation)
            session_cost += (trade_dollars / capital) * per_dollar_cost
        end
        if available[session]
            cost_returns[session] = session_cost
            net_returns[session] = gross_returns[session] - session_cost
        else
            cost_returns[session] = missing
            net_returns[session] = missing
        end
        previous_weights .= @view weights[session, :]
    end
    return (; gross_returns, net_returns, cost_returns, available)
end

end # module
