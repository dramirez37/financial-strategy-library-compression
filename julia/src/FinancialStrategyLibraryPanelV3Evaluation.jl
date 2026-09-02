module FinancialStrategyLibraryPanelV3Evaluation

using SHA: sha256
using Random: rand
using StableRNGs: StableRNG
using Statistics: cor, mean, var

include(joinpath(@__DIR__, "FinancialStrategyLibraryPanelV3Predecision.jl"))
using .FinancialStrategyLibraryPanelV3Predecision: backtest_portfolio_specification,
                                                   portfolio_catalog,
                                                   specification_id

include(joinpath(@__DIR__, "FinancialStrategyLibraryPanelV3PredecisionComputation.jl"))
using .FinancialStrategyLibraryPanelV3PredecisionComputation: TRIAL_LEDGER_FIELDS

export FrozenEvaluationChoice,
       FrozenRobustnessSpec,
       CapacityOutcome,
       EvaluationOutcome,
       FullSearchDiagnostics,
       OriginEvaluationContrast,
       PolicyEvaluationOutcome,
       RobustnessEvaluationOutcome,
       cash_only_evaluation_outcomes,
       capacity_policy_grid,
       evaluate_frozen_choices,
       evaluate_frozen_robustness_specs,
       full_search_diagnostics,
       origin_evaluation_contrast,
       proposal_evaluation_calibration,
       summarize_capacity_outcomes,
       summarize_origin_contrasts,
       summarize_policy_outcomes,
       summarize_robustness_outcomes,
       leave_one_origin_out_summary,
       update_trial_ledger

const CASH_ID = "mandatory_inactive_cash"
const SAFE_POLICY = "innovation_safe_robust_policy"
const COMPARATOR_POLICY = "frontier_only_robust_policy"
const PRIMARY_POLICIES = Set((SAFE_POLICY, COMPARATOR_POLICY))
const REGISTERED_POLICY_IDS = [
    COMPARATOR_POLICY,
    SAFE_POLICY,
    "innovation_safe_forced_max",
    "equal_weight_available_policy",
    "source_uncompressed_robust_policy",
]
const REGISTERED_POLICIES = Set(REGISTERED_POLICY_IDS)
const PRIMARY_COST_BPS = 5.0
const PRIMARY_RISK_AVERSION = 3.0
const ANNUALIZATION_SESSIONS = 252
const REALITY_CHECK_BASE_SEED = 310003
const HANSEN_SPA_BASE_SEED = 310004
const PBO_CSCV_BASE_SEED = 310005
const FULL_SEARCH_BOOTSTRAP_REPETITIONS = 5_000
const FULL_SEARCH_BLOCK_SESSIONS = 20
const FULL_SEARCH_CSCV_BLOCKS = 8
const CAPACITY_AUM_LEVELS = (1_000_000.0, 10_000_000.0, 100_000_000.0, 1_000_000_000.0)
const CAPACITY_HALF_SPREAD_BPS = (2.5, 7.5, 15.0)
const CAPACITY_IMPACT_COEFFICIENTS = (0.5, 1.0)
const CAPACITY_ADV_FRACTION_CAP = 0.10
const CAPACITY_LAG_SESSIONS = 20
const CAPACITY_BASE_SEED = 310007

struct FrozenEvaluationChoice
    origin_id::String
    universe_id::String
    policy_id::String
    strategy_ids::Vector{String}
    strategy_id::String

    function FrozenEvaluationChoice(origin_id, universe_id, policy_id, strategy_ids)
        policy = String(policy_id)
        policy in REGISTERED_POLICIES ||
            throw(ArgumentError("evaluation choice is not a registered policy"))
        strategies = strategy_ids isa AbstractString ? [String(strategy_ids)] :
            String.(collect(strategy_ids))
        isempty(strategies) && throw(ArgumentError("available evaluation choice is empty"))
        length(unique(strategies)) == length(strategies) ||
            throw(ArgumentError("evaluation choice repeats a strategy identity"))
        scalar = length(strategies) == 1 ? only(strategies) : ""
        return new(String(origin_id), String(universe_id), policy, strategies, scalar)
    end
end

struct FrozenRobustnessSpec
    context_id::String
    variant_kind::String
    liquidity_cap::Int
    cost_bps::Float64
    risk_aversion::Float64
    adoption_hurdle::Float64
    comparator_choice::FrozenEvaluationChoice
    safe_choice::FrozenEvaluationChoice

    function FrozenRobustnessSpec(
        context_id,
        variant_kind,
        liquidity_cap,
        cost_bps,
        risk_aversion,
        adoption_hurdle,
        comparator_choice,
        safe_choice,
    )
        kind = String(variant_kind)
        kind in ("cost_risk_hurdle_grid", "common_equity_liquidity_cap") ||
            throw(ArgumentError("unknown frozen robustness variant"))
        comparator_choice.policy_id == COMPARATOR_POLICY ||
            throw(ArgumentError("robustness comparator policy changed"))
        safe_choice.policy_id == SAFE_POLICY ||
            throw(ArgumentError("robustness safe policy changed"))
        comparator_choice.origin_id == safe_choice.origin_id &&
            comparator_choice.universe_id == safe_choice.universe_id ||
            throw(ArgumentError("robustness choices cross cells"))
        return new(
            String(context_id),
            kind,
            Int(liquidity_cap),
            Float64(cost_bps),
            Float64(risk_aversion),
            Float64(adoption_hurdle),
            comparator_choice,
            safe_choice,
        )
    end
end

struct EvaluationOutcome
    origin_id::String
    universe_id::String
    policy_id::String
    strategy_id::String
    complete::Bool
    observation_count::Int
    certainty_equivalent::Union{Missing,Float64}
    annual_mean_component::Union{Missing,Float64}
    annual_variance_penalty::Union{Missing,Float64}
    annual_turnover_cost::Union{Missing,Float64}
    failure_code::String
end

struct PolicyEvaluationOutcome
    origin_id::String
    universe_id::String
    policy_id::String
    choice_ids::Vector{String}
    complete::Bool
    observation_count::Int
    certainty_equivalent::Union{Missing,Float64}
    annual_mean_component::Union{Missing,Float64}
    annual_variance_penalty::Union{Missing,Float64}
    annual_turnover_cost::Union{Missing,Float64}
    failure_code::String
end

struct CapacityOutcome
    origin_id::String
    universe_id::String
    policy_id::String
    aum::Float64
    half_spread_bps::Float64
    impact_coefficient::Float64
    adv_fraction_cap::Float64
    seed::Int
    complete::Bool
    observation_count::Int
    certainty_equivalent::Union{Missing,Float64}
    annual_mean_component::Union{Missing,Float64}
    annual_variance_penalty::Union{Missing,Float64}
    annual_execution_cost::Union{Missing,Float64}
    maximum_adv_fraction::Union{Missing,Float64}
    failure_code::String
end

struct FullSearchDiagnostics
    candidate_ids::Vector{String}
    candidate_outcomes::Vector{EvaluationOutcome}
    complete_candidate_ids::Vector{String}
    white_reality_check_p_value::Union{Missing,Float64}
    hansen_spa_p_value::Union{Missing,Float64}
    pbo_cscv::Union{Missing,Float64}
    cscv_split_count::Int
    deflated_sharpe_probability::Union{Missing,Float64}
    deflated_sharpe_expected_maximum::Union{Missing,Float64}
    deflated_sharpe_best_candidate_id::String
    best_candidate_id::String
    best_candidate_ce::Union{Missing,Float64}
    bootstrap_repetitions::Int
    moving_block_sessions::Int
    reality_check_seed::Int
    hansen_spa_seed::Int
    pbo_cscv_seed::Int
end

struct OriginEvaluationContrast
    origin_id::String
    universe_id::String
    complete::Bool
    safe_strategy_id::String
    comparator_strategy_id::String
    certainty_equivalent_difference::Union{Missing,Float64}
    mean_component_difference::Union{Missing,Float64}
    variance_penalty_difference::Union{Missing,Float64}
    turnover_cost_difference::Union{Missing,Float64}
    same_choice::Bool
    failure_code::String
end

struct RobustnessEvaluationOutcome
    context_id::String
    variant_kind::String
    liquidity_cap::Int
    cost_bps::Float64
    risk_aversion::Float64
    adoption_hurdle::Float64
    comparator::PolicyEvaluationOutcome
    safe::PolicyEvaluationOutcome
    contrast::OriginEvaluationContrast
end

_sha256_text(value) = bytes2hex(sha256(codeunits(String(value))))

function _bool(value)
    value isa Bool && return value
    lowercase(String(value)) == "true" && return true
    lowercase(String(value)) == "false" && return false
    throw(ArgumentError("ledger Boolean has an invalid representation"))
end

function _strategy_lookup(origin_id, universe_id)
    prefix = "$(String(origin_id))|$(String(universe_id))|"
    return Dict(
        prefix * specification_id(specification) => specification for
        specification in portfolio_catalog()
    )
end

function _validate_choices(origin_id, universe_id, choices)
    result = FrozenEvaluationChoice[collect(choices)...]
    length(result) >= 2 ||
        throw(ArgumentError("evaluation requires the frozen primary choices"))
    policy_ids = getfield.(result, :policy_id)
    length(unique(policy_ids)) == length(policy_ids) ||
        throw(ArgumentError("evaluation repeats a registered policy"))
    Set(policy_ids) ⊆ REGISTERED_POLICIES ||
        throw(ArgumentError("evaluation includes an unregistered policy"))
    PRIMARY_POLICIES ⊆ Set(policy_ids) ||
        throw(ArgumentError("evaluation choices omit a primary registered policy"))
    all(choice -> choice.origin_id == String(origin_id), result) ||
        throw(ArgumentError("evaluation choices cross origins"))
    all(choice -> choice.universe_id == String(universe_id), result) ||
        throw(ArgumentError("evaluation choices cross universes"))
    return sort!(result; by = choice -> choice.policy_id)
end

function _metric_values(gross, turnover; cost_bps, risk_aversion)
    gross_values = Float64.(collect(gross))
    turnover_values = Float64.(collect(turnover))
    length(gross_values) == length(turnover_values) ||
        throw(DimensionMismatch("evaluation return and turnover paths differ"))
    length(gross_values) > 1 || throw(ArgumentError("evaluation path is too short"))
    all(isfinite, gross_values) && all(isfinite, turnover_values) ||
        error("a complete evaluation path contains a nonfinite value")
    cost_rate = Float64(cost_bps) / 10_000
    risk = Float64(risk_aversion)
    net = gross_values .- cost_rate .* turnover_values
    annual_mean = ANNUALIZATION_SESSIONS * mean(gross_values)
    annual_cost = ANNUALIZATION_SESSIONS * cost_rate * mean(turnover_values)
    variance_penalty =
        0.5 * risk * ANNUALIZATION_SESSIONS * var(net; corrected = true)
    certainty_equivalent = annual_mean - annual_cost - variance_penalty
    return (; certainty_equivalent, annual_mean, variance_penalty, annual_cost)
end

function _cash_outcome(choice::FrozenEvaluationChoice, strategy_id, observation_count::Integer)
    count = Int(observation_count)
    count > 1 || throw(ArgumentError("evaluation cash path needs at least two sessions"))
    return EvaluationOutcome(
        choice.origin_id,
        choice.universe_id,
        choice.policy_id,
        String(strategy_id),
        true,
        count,
        0.0,
        0.0,
        0.0,
        0.0,
        "",
    )
end

function cash_only_evaluation_outcomes(choices, observation_count::Integer)
    values = _validate_choices(first(choices).origin_id, first(choices).universe_id, choices)
    all(choice -> choice.strategy_ids == [CASH_ID], values) ||
        throw(ArgumentError("cash-only evaluation received an active strategy"))
    outcomes = EvaluationOutcome[
        _cash_outcome(choice, CASH_ID, observation_count) for choice in values
    ]
    policy_outcomes = PolicyEvaluationOutcome[
        PolicyEvaluationOutcome(
            choice.origin_id,
            choice.universe_id,
            choice.policy_id,
            copy(choice.strategy_ids),
            true,
            Int(observation_count),
            0.0,
            0.0,
            0.0,
            0.0,
            "",
        ) for choice in values
    ]
    return (; outcomes, policy_outcomes)
end

function _path_components(
    choice,
    strategy_id,
    result,
    evaluation_indices;
    cost_bps,
    risk_aversion,
)
    indices = Int.(collect(evaluation_indices))
    available = Bool.(result.available[indices])
    gross = result.gross_returns[indices]
    turnover = Float64.(result.turnover[indices])
    observation_count = count(identity, available)
    if !all(available)
        outcome = EvaluationOutcome(
            choice.origin_id,
            choice.universe_id,
            choice.policy_id,
            String(strategy_id),
            false,
            observation_count,
            missing,
            missing,
            missing,
            missing,
            "INCOMPLETE_EVALUATION_PATH",
        )
        return (; outcome, gross, turnover, available)
    end
    metrics = _metric_values(Float64.(gross), turnover; cost_bps, risk_aversion)
    outcome = EvaluationOutcome(
        choice.origin_id,
        choice.universe_id,
        choice.policy_id,
        String(strategy_id),
        true,
        observation_count,
        metrics.certainty_equivalent,
        metrics.annual_mean,
        metrics.variance_penalty,
        metrics.annual_cost,
        "",
    )
    return (; outcome, gross, turnover, available)
end

function _aggregate_effective_weights(series)
    isempty(series) && error("available frozen policy has no strategy series")
    result = zeros(Float64, size(first(series).effective))
    for path in series
        size(path.effective) == size(result) ||
            error("frozen policy strategy weight panels differ")
        result .+= path.effective ./ length(series)
    end
    return result
end

function _policy_outcome(choice, series, evaluation_indices; cost_bps, risk_aversion)
    isempty(series) && error("available frozen policy has no strategy series")
    sessions = length(first(series).available)
    all(path -> length(path.available) == sessions, series) ||
        error("frozen policy strategy calendars differ")
    available = BitVector([
        all(path.available[session] for path in series) for session in 1:sessions
    ])
    observation_count = count(identity, available)
    if !all(available)
        return PolicyEvaluationOutcome(
            choice.origin_id,
            choice.universe_id,
            choice.policy_id,
            copy(choice.strategy_ids),
            false,
            observation_count,
            missing,
            missing,
            missing,
            missing,
            "INCOMPLETE_EVALUATION_POLICY_PATH",
        )
    end
    sleeve_count = length(series)
    gross = Float64[
        sum(Float64(path.gross[session]) for path in series) / sleeve_count
        for session in 1:sessions
    ]
    effective = _aggregate_effective_weights(series)
    turnover_full = zeros(Float64, size(effective, 1))
    turnover_full[1] = sum(abs, @view effective[1, :])
    for session in 2:size(effective, 1)
        turnover_full[session] = sum(abs,
            view(effective, session, :) .- view(effective, session - 1, :))
    end
    turnover = turnover_full[Int.(collect(evaluation_indices))]
    metrics = _metric_values(gross, turnover; cost_bps, risk_aversion)
    return PolicyEvaluationOutcome(
        choice.origin_id,
        choice.universe_id,
        choice.policy_id,
        copy(choice.strategy_ids),
        true,
        observation_count,
        metrics.certainty_equivalent,
        metrics.annual_mean,
        metrics.variance_penalty,
        metrics.annual_cost,
        "",
    )
end

function _registered_seed(base_seed::Integer, scope_values)
    digest = _sha256_text(join((Int(base_seed), scope_values...), '\0'))
    return parse(Int, first(digest, 15); base = 16)
end

function _full_search_seeds(scope_values)
    values = collect(scope_values)
    length(values) == 2 || throw(ArgumentError(
        "full-search seed scope must be exactly origin_id|universe_id",
    ))
    return (;
        reality_check = _registered_seed(REALITY_CHECK_BASE_SEED, values),
        hansen_spa = _registered_seed(HANSEN_SPA_BASE_SEED, values),
        pbo_cscv = _registered_seed(PBO_CSCV_BASE_SEED, values),
    )
end

_capacity_seed(origin_id, universe_id, aum) = _registered_seed(
    CAPACITY_BASE_SEED,
    (String(origin_id), String(universe_id), "aum_$(round(Int, Float64(aum)))"),
)

function _moving_block_indices(rng, sessions, block_sessions)
    result = Vector{Int}(undef, sessions)
    cursor = 1
    while cursor <= sessions
        first_index = rand(rng, 1:sessions)
        for offset in 0:(block_sessions - 1)
            cursor > sessions && break
            result[cursor] = mod1(first_index + offset, sessions)
            cursor += 1
        end
    end
    return result
end

function _net_ce(values; risk_aversion = PRIMARY_RISK_AVERSION)
    collected = Float64.(collect(values))
    length(collected) > 1 || throw(ArgumentError("diagnostic path is too short"))
    return ANNUALIZATION_SESSIONS * mean(collected) -
           0.5 * Float64(risk_aversion) * ANNUALIZATION_SESSIONS *
           var(collected; corrected = true)
end

function _contiguous_blocks(sessions, block_count)
    count = min(Int(block_count), sessions)
    count >= 2 || throw(ArgumentError("CSCV needs at least two blocks"))
    boundaries = round.(Int, range(0, sessions; length = count + 1))
    return [
        (boundaries[index] + 1):boundaries[index + 1] for index in 1:count
        if boundaries[index] < boundaries[index + 1]
    ]
end

function _combinations(values, choose)
    result = Vector{Vector{Int}}()
    current = Int[]
    function visit(start)
        if length(current) == choose
            push!(result, copy(current))
            return
        end
        remaining = choose - length(current)
        for index in start:(length(values) - remaining + 1)
            push!(current, values[index])
            visit(index + 1)
            pop!(current)
        end
    end
    visit(1)
    return result
end

function _long_run_variance(values, maximum_lag)
    collected = Float64.(collect(values))
    sessions = length(collected)
    sessions > 1 || throw(ArgumentError("long-run variance path is too short"))
    centered = collected .- mean(collected)
    lag_count = min(Int(maximum_lag), sessions - 1)
    variance = sum(abs2, centered) / sessions
    for lag in 1:lag_count
        covariance = sum(
            centered[index] * centered[index - lag] for index in (lag + 1):sessions
        ) / sessions
        variance += 2 * (1 - lag / (lag_count + 1)) * covariance
    end
    return max(0.0, variance)
end

function _normal_cdf(value)
    x = Float64(value)
    x == Inf && return 1.0
    x == -Inf && return 0.0
    magnitude = abs(x)
    t = 1 / (1 + 0.2316419 * magnitude)
    polynomial = t * (0.319381530 + t * (-0.356563782 + t *
        (1.781477937 + t * (-1.821255978 + t * 1.330274429))))
    upper = exp(-0.5 * magnitude^2) / sqrt(2 * pi) * polynomial
    return x >= 0 ? 1 - upper : upper
end

"Acklam's deterministic approximation to the standard-normal quantile."
function _normal_quantile(probability)
    p = Float64(probability)
    0 < p < 1 || throw(ArgumentError("normal quantile probability is outside (0,1)"))
    a = (-39.69683028665376, 220.9460984245205, -275.9285104469687,
        138.3577518672690, -30.66479806614716, 2.506628277459239)
    b = (-54.47609879822406, 161.5858368580409, -155.6989798598866,
        66.80131188771972, -13.28068155288572)
    c = (-0.007784894002430293, -0.3223964580411365, -2.400758277161838,
        -2.549732539343734, 4.374664141464968, 2.938163982698783)
    d = (0.007784695709041462, 0.3224671290700398, 2.445134137142996,
        3.754408661907416)
    lower = 0.02425
    upper = 1 - lower
    if p < lower
        q = sqrt(-2 * log(p))
        return (((((c[1] * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) * q + c[6]) /
               ((((d[1] * q + d[2]) * q + d[3]) * q + d[4]) * q + 1)
    elseif p <= upper
        q = p - 0.5
        r = q^2
        return (((((a[1] * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5]) * r + a[6]) * q /
               (((((b[1] * r + b[2]) * r + b[3]) * r + b[4]) * r + b[5]) * r + 1)
    else
        q = sqrt(-2 * log(1 - p))
        return -(((((c[1] * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) * q + c[6]) /
               ((((d[1] * q + d[2]) * q + d[3]) * q + d[4]) * q + 1)
    end
end

function _deflated_sharpe(values, candidate_ids)
    sessions, candidates = size(values)
    sharpe_indices = Int[]
    sharpes = Float64[]
    for candidate in 1:candidates
        standard_deviation = sqrt(var(view(values, :, candidate); corrected = true))
        standard_deviation > eps(Float64) || continue
        push!(sharpe_indices, candidate)
        push!(sharpes, mean(view(values, :, candidate)) / standard_deviation)
    end
    length(sharpes) >= 2 || return (;
        probability = missing,
        expected_maximum = missing,
        best_candidate_id = "",
    )
    best_position = sortperm(eachindex(sharpes); by = index ->
        (-sharpes[index], String(candidate_ids[sharpe_indices[index]])))[1]
    best_candidate = sharpe_indices[best_position]
    observed = sharpes[best_position]
    cross_strategy_variance = var(sharpes; corrected = true)
    euler_gamma = 0.5772156649015329
    trial_count = length(sharpes)
    expected_maximum = sqrt(max(0.0, cross_strategy_variance)) * (
        (1 - euler_gamma) * _normal_quantile(1 - 1 / trial_count) +
        euler_gamma * _normal_quantile(1 - 1 / (trial_count * exp(1)))
    )
    path = Float64.(view(values, :, best_candidate))
    centered = path .- mean(path)
    second_moment = mean(centered .^ 2)
    if second_moment <= eps(Float64)
        return (;
            probability = missing,
            expected_maximum,
            best_candidate_id = String(candidate_ids[best_candidate]),
        )
    end
    skewness = mean(centered .^ 3) / second_moment^(3 / 2)
    kurtosis = mean(centered .^ 4) / second_moment^2
    denominator = sqrt(max(
        eps(Float64),
        1 - skewness * observed + ((kurtosis - 1) / 4) * observed^2,
    ))
    statistic = (observed - expected_maximum) * sqrt(sessions - 1) / denominator
    return (;
        probability = _normal_cdf(statistic),
        expected_maximum,
        best_candidate_id = String(candidate_ids[best_candidate]),
    )
end

function full_search_diagnostics(
    candidate_ids,
    candidate_outcomes,
    net_returns::AbstractMatrix,
    available::AbstractMatrix{Bool};
    scope_values = (),
    bootstrap_repetitions::Integer = FULL_SEARCH_BOOTSTRAP_REPETITIONS,
    moving_block_sessions::Integer = FULL_SEARCH_BLOCK_SESSIONS,
    cscv_blocks::Integer = FULL_SEARCH_CSCV_BLOCKS,
)
    ids = String.(collect(candidate_ids))
    outcomes = EvaluationOutcome[collect(candidate_outcomes)...]
    size(net_returns) == size(available) ||
        throw(DimensionMismatch("full-search return and availability panels differ"))
    size(net_returns, 2) == length(ids) == length(outcomes) ||
        throw(DimensionMismatch("full-search candidates do not align"))
    complete_indices = findall(index -> all(@view available[:, index]), eachindex(ids))
    complete_ids = ids[complete_indices]
    seeds = _full_search_seeds(scope_values)
    repetitions = Int(bootstrap_repetitions)
    repetitions >= 100 || throw(ArgumentError("full-search bootstrap needs at least 100 repetitions"))
    block = Int(moving_block_sessions)
    block >= 1 || throw(ArgumentError("full-search moving block must be positive"))
    if isempty(complete_indices)
        return FullSearchDiagnostics(
            ids,
            outcomes,
            String[],
            missing,
            missing,
            missing,
            0,
            missing,
            missing,
            "",
            "",
            missing,
            repetitions,
            block,
            seeds.reality_check,
            seeds.hansen_spa,
            seeds.pbo_cscv,
        )
    end
    values = Float64.(net_returns[:, complete_indices])
    sessions, candidates = size(values)
    sessions > 2 || throw(ArgumentError("full-search calendar is too short"))
    means = vec(mean(values; dims = 1))
    long_run_variances = Float64[
        _long_run_variance(view(values, :, index), block - 1) for index in 1:candidates
    ]
    long_run_scales = sqrt.(long_run_variances)
    observed_white = sqrt(sessions) * maximum(means)
    observed_spa = max(0.0, maximum([
        long_run_scales[index] > eps(Float64) ?
            sqrt(sessions) * means[index] / long_run_scales[index] :
        (means[index] > 0 ? Inf : 0.0) for index in 1:candidates
    ]))
    spa_exclusion_threshold = sqrt(2 * log(log(sessions)))
    spa_recenter = Float64[
        if long_run_scales[index] <= eps(Float64)
            means[index] < 0 ? means[index] : 0.0
        elseif sqrt(sessions) * means[index] / long_run_scales[index] <
               -spa_exclusion_threshold
            means[index]
        else
            0.0
        end for index in 1:candidates
    ]
    centered = values .- reshape(means, 1, :)
    white_rng = StableRNG(seeds.reality_check)
    spa_rng = StableRNG(seeds.hansen_spa)
    white_exceed = 0
    spa_exceed = 0
    for _ in 1:repetitions
        white_indices = _moving_block_indices(white_rng, sessions, block)
        white_means = vec(mean(view(centered, white_indices, :); dims = 1))
        boot_white = sqrt(sessions) * maximum(white_means)
        spa_indices = _moving_block_indices(spa_rng, sessions, block)
        spa_means = vec(mean(view(centered, spa_indices, :); dims = 1)) .+ spa_recenter
        boot_spa = max(0.0, maximum([
            long_run_scales[index] > eps(Float64) ?
                sqrt(sessions) * spa_means[index] / long_run_scales[index] :
                (spa_means[index] > 0 ? Inf : 0.0)
            for index in 1:candidates
        ]))
        boot_white >= observed_white && (white_exceed += 1)
        boot_spa >= observed_spa && (spa_exceed += 1)
    end
    white_p = (white_exceed + 1) / (repetitions + 1)
    spa_p = (spa_exceed + 1) / (repetitions + 1)

    blocks = _contiguous_blocks(sessions, cscv_blocks)
    block_ids = collect(eachindex(blocks))
    half = length(blocks) ÷ 2
    splits = iseven(length(blocks)) ? _combinations(block_ids, half) : Vector{Vector{Int}}()
    overfit = 0
    valid_splits = 0
    for train_blocks in splits
        train_set = Set(train_blocks)
        train_indices = reduce(vcat, (collect(blocks[index]) for index in train_blocks))
        test_indices = reduce(vcat, (
            collect(blocks[index]) for index in block_ids if !(index in train_set)
        ))
        length(train_indices) > 1 && length(test_indices) > 1 || continue
        train_scores = [_net_ce(@view values[train_indices, index]) for index in 1:candidates]
        selected = sortperm(eachindex(train_scores); by = index -> (-train_scores[index], ids[complete_indices[index]]))[1]
        test_scores = [_net_ce(@view values[test_indices, index]) for index in 1:candidates]
        ordered = sortperm(eachindex(test_scores); by = index -> (test_scores[index], ids[complete_indices[index]]))
        rank = only(findall(==(selected), ordered))
        relative_rank = rank / (candidates + 1)
        relative_rank <= 0.5 && (overfit += 1)
        valid_splits += 1
    end
    pbo = valid_splits > 0 ? overfit / valid_splits : missing
    deflated_sharpe = _deflated_sharpe(values, complete_ids)
    candidate_ces = [_net_ce(@view values[:, index]) for index in 1:candidates]
    best = sortperm(eachindex(candidate_ces); by = index -> (-candidate_ces[index], complete_ids[index]))[1]
    return FullSearchDiagnostics(
        ids,
        outcomes,
        complete_ids,
        white_p,
        spa_p,
        pbo,
        valid_splits,
        deflated_sharpe.probability,
        deflated_sharpe.expected_maximum,
        deflated_sharpe.best_candidate_id,
        complete_ids[best],
        candidate_ces[best],
        repetitions,
        block,
        seeds.reality_check,
        seeds.hansen_spa,
        seeds.pbo_cscv,
    )
end

"""
Score only identities already frozen by the five registered policies, but
construct each distinct selected path over the complete supplied history so
signal, holding-age, volatility, terminal, and implementation-lag state carry
into the evaluation year. A multi-identity policy is an equal-weight collection
of its frozen strategy sleeves.
"""
function evaluate_frozen_choices(
    origin_id,
    universe_id,
    security_returns::AbstractMatrix,
    return_available::AbstractMatrix{Bool},
    terminal_delisting::AbstractMatrix{Bool},
    dates,
    evaluation_year::Integer,
    choices;
    security_weight_cap::Real,
    portfolio_volatility_target::Real = 0.10,
    decision_to_first_return_lag_sessions::Integer = 2,
    cost_bps::Real = PRIMARY_COST_BPS,
    risk_aversion::Real = PRIMARY_RISK_AVERSION,
    compute_full_search::Bool = false,
    full_search_bootstrap_repetitions::Integer = FULL_SEARCH_BOOTSTRAP_REPETITIONS,
    full_search_moving_block_sessions::Integer = FULL_SEARCH_BLOCK_SESSIONS,
    full_search_cscv_blocks::Integer = FULL_SEARCH_CSCV_BLOCKS,
    strategy_path_cache::AbstractDict{String} = Dict{String,Any}(),
    strategy_path_cache_namespace::AbstractString = "full_selected_universe",
)
    size(security_returns) == size(return_available) == size(terminal_delisting) ||
        throw(DimensionMismatch("evaluation security panels do not align"))
    size(security_returns, 1) == length(dates) ||
        throw(DimensionMismatch("evaluation dates do not align with security panels"))
    issorted(String.(dates)) || throw(ArgumentError("evaluation history is not chronological"))
    choice_values = _validate_choices(origin_id, universe_id, choices)
    indices = findall(date -> startswith(String(date), "$(Int(evaluation_year))-"), dates)
    length(indices) > 1 || throw(ArgumentError("evaluation reference calendar is incomplete"))
    lookup = _strategy_lookup(origin_id, universe_id)
    # A source terminal flag without an observed total return is an unresolved
    # terminal event, not an observed delisting. Preserve its unavailable row
    # for the effective-exposure gate, but never pass it as an earned terminal
    # observation to the portfolio engine.
    observed_terminal = Bool.(terminal_delisting .& return_available)
    path_cache = strategy_path_cache
    cache_key(strategy_id) = String(strategy_path_cache_namespace) * '\0' * String(strategy_id)
    outcomes = EvaluationOutcome[]
    policy_outcomes = PolicyEvaluationOutcome[]
    policy_effective_weights = Dict{String,Matrix{Float64}}()
    for choice in choice_values
        series = Any[]
        for strategy_id in choice.strategy_ids
            if strategy_id == CASH_ID
                push!(outcomes, _cash_outcome(choice, strategy_id, length(indices)))
                push!(series, (;
                    gross = Union{Missing,Float64}[zeros(length(indices))...],
                    turnover = zeros(length(indices)),
                    available = trues(length(indices)),
                    effective = zeros(Float64, size(security_returns)),
                ))
                continue
            end
            haskey(lookup, strategy_id) || throw(ArgumentError(
                "a frozen evaluation choice is outside the 96-strategy grammar",
            ))
            result = get!(path_cache, cache_key(strategy_id)) do
                backtest_portfolio_specification(
                    lookup[strategy_id],
                    security_returns;
                    security_weight_cap,
                    portfolio_volatility_target,
                    decision_to_first_return_lag_sessions,
                    one_way_cost_bps = 0.0,
                    return_available,
                    terminal_delisting = observed_terminal,
                )
            end
            components = _path_components(
                choice,
                strategy_id,
                result,
                indices;
                cost_bps,
                risk_aversion,
            )
            push!(outcomes, components.outcome)
            push!(series, (;
                gross = components.gross,
                turnover = components.turnover,
                available = components.available,
                effective = result.effective_weights,
            ))
        end
        push!(policy_outcomes, _policy_outcome(
            choice,
            series,
            indices;
            cost_bps,
            risk_aversion,
        ))
        policy_effective_weights[choice.policy_id] = _aggregate_effective_weights(series)
    end
    Set(getfield.(policy_outcomes, :policy_id)) ⊇ PRIMARY_POLICIES ||
        error("evaluation did not score both primary policies")
    diagnostic = if compute_full_search
        candidate_ids = sort!(collect(keys(lookup)))
        candidate_outcomes = EvaluationOutcome[]
        candidate_net_returns = Matrix{Union{Missing,Float64}}(
            missing,
            length(indices),
            length(candidate_ids),
        )
        candidate_available = falses(length(indices), length(candidate_ids))
        cost_rate = Float64(cost_bps) / 10_000
        for (column, strategy_id) in enumerate(candidate_ids)
            result = get!(path_cache, cache_key(strategy_id)) do
                backtest_portfolio_specification(
                    lookup[strategy_id],
                    security_returns;
                    security_weight_cap,
                    portfolio_volatility_target,
                    decision_to_first_return_lag_sessions,
                    one_way_cost_bps = 0.0,
                    return_available,
                    terminal_delisting = observed_terminal,
                )
            end
            diagnostic_choice = FrozenEvaluationChoice(
                origin_id,
                universe_id,
                COMPARATOR_POLICY,
                strategy_id,
            )
            components = _path_components(
                diagnostic_choice,
                strategy_id,
                result,
                indices;
                cost_bps,
                risk_aversion,
            )
            source = components.outcome
            push!(candidate_outcomes, EvaluationOutcome(
                source.origin_id,
                source.universe_id,
                "full_search_candidate",
                source.strategy_id,
                source.complete,
                source.observation_count,
                source.certainty_equivalent,
                source.annual_mean_component,
                source.annual_variance_penalty,
                source.annual_turnover_cost,
                source.failure_code,
            ))
            candidate_available[:, column] .= components.available
            for row in eachindex(indices)
                components.available[row] || continue
                candidate_net_returns[row, column] =
                    Float64(components.gross[row]) - cost_rate * components.turnover[row]
            end
        end
        full_search_diagnostics(
            candidate_ids,
            candidate_outcomes,
            candidate_net_returns,
            candidate_available;
            scope_values = (String(origin_id), String(universe_id)),
            bootstrap_repetitions = full_search_bootstrap_repetitions,
            moving_block_sessions = full_search_moving_block_sessions,
            cscv_blocks = full_search_cscv_blocks,
        )
    else
        nothing
    end
    return (;
        outcomes,
        policy_outcomes,
        policy_effective_weights,
        full_search_diagnostics = diagnostic,
        evaluation_indices = indices,
        strategy_path_cache = path_cache,
    )
end

"Score sealed robustness pairs without allowing any evaluation-time reselection."
function evaluate_frozen_robustness_specs(
    origin_id,
    universe_id,
    security_returns::AbstractMatrix,
    return_available::AbstractMatrix{Bool},
    terminal_delisting::AbstractMatrix{Bool},
    dates,
    evaluation_year::Integer,
    specs;
    security_weight_cap::Real,
    portfolio_volatility_target::Real = 0.10,
    decision_to_first_return_lag_sessions::Integer = 2,
    strategy_path_cache::AbstractDict{String} = Dict{String,Any}(),
    evaluated_liquidity_cap::Integer = 0,
)
    spec_values = FrozenRobustnessSpec[collect(specs)...]
    length(unique(getfield.(spec_values, :context_id))) == length(spec_values) ||
        throw(ArgumentError("frozen robustness context is repeated"))
    outcomes = RobustnessEvaluationOutcome[]
    for spec in spec_values
        if spec.variant_kind == "cost_risk_hurdle_grid"
            Int(evaluated_liquidity_cap) == 0 ||
                throw(ArgumentError("full robustness grid received a cap-specific panel"))
        else
            Int(evaluated_liquidity_cap) == spec.liquidity_cap ||
                throw(ArgumentError("liquidity-cap robustness panel does not match its seal"))
            size(security_returns, 2) == spec.liquidity_cap ||
                throw(ArgumentError("liquidity-cap robustness membership width changed"))
        end
        for choice in (spec.comparator_choice, spec.safe_choice)
            choice.origin_id == String(origin_id) &&
                choice.universe_id == String(universe_id) ||
                throw(ArgumentError("frozen robustness spec crosses cells"))
        end
        evaluation = evaluate_frozen_choices(
            origin_id,
            universe_id,
            security_returns,
            return_available,
            terminal_delisting,
            dates,
            evaluation_year,
            [spec.comparator_choice, spec.safe_choice];
            security_weight_cap,
            portfolio_volatility_target,
            decision_to_first_return_lag_sessions,
            cost_bps = spec.cost_bps,
            risk_aversion = spec.risk_aversion,
            compute_full_search = false,
            strategy_path_cache,
            strategy_path_cache_namespace = Int(evaluated_liquidity_cap) == 50 ?
                "common_equity_liquidity_cap50" : "full_selected_universe",
        )
        lookup = Dict(outcome.policy_id => outcome for outcome in evaluation.policy_outcomes)
        comparator = lookup[COMPARATOR_POLICY]
        safe = lookup[SAFE_POLICY]
        contrast = origin_evaluation_contrast(evaluation.policy_outcomes)
        push!(outcomes, RobustnessEvaluationOutcome(
            spec.context_id,
            spec.variant_kind,
            spec.liquidity_cap,
            spec.cost_bps,
            spec.risk_aversion,
            spec.adoption_hurdle,
            comparator,
            safe,
            contrast,
        ))
    end
    return (; outcomes, strategy_path_cache)
end

function _capacity_failure(
    origin_id,
    universe_id,
    policy_id,
    aum,
    half_spread_bps,
    impact_coefficient,
    adv_fraction_cap,
    observation_count,
    maximum_adv_fraction,
    failure_code,
)
    return CapacityOutcome(
        String(origin_id),
        String(universe_id),
        String(policy_id),
        Float64(aum),
        Float64(half_spread_bps),
        Float64(impact_coefficient),
        Float64(adv_fraction_cap),
        _capacity_seed(origin_id, universe_id, aum),
        false,
        Int(observation_count),
        missing,
        missing,
        missing,
        missing,
        maximum_adv_fraction,
        String(failure_code),
    )
end

"""
Score the already-frozen policy weight paths on the registered capacity grid.
Execution inputs are strictly point-in-time: a trade on session `t` uses the
arithmetic mean dollar volume and daily return volatility from the preceding
20 sessions. Orders above 10% of lagged ADV are unavailable, never truncated.
The square-root impact rate is `coefficient * daily_volatility * sqrt(order/ADV)`.
"""
function capacity_policy_grid(
    origin_id,
    universe_id,
    policy_effective_weights::AbstractDict,
    security_returns::AbstractMatrix,
    return_available::AbstractMatrix{Bool},
    close::AbstractMatrix,
    volume::AbstractMatrix,
    dates,
    evaluation_year::Integer;
    aum_levels = CAPACITY_AUM_LEVELS,
    half_spread_bps_levels = CAPACITY_HALF_SPREAD_BPS,
    impact_coefficients = CAPACITY_IMPACT_COEFFICIENTS,
    adv_fraction_cap::Real = CAPACITY_ADV_FRACTION_CAP,
    lag_sessions::Integer = CAPACITY_LAG_SESSIONS,
    risk_aversion::Real = PRIMARY_RISK_AVERSION,
)
    size(security_returns) == size(return_available) == size(close) == size(volume) ||
        throw(DimensionMismatch("capacity source panels do not align"))
    size(security_returns, 1) == length(dates) ||
        throw(DimensionMismatch("capacity calendar does not align"))
    issorted(String.(dates)) || throw(ArgumentError("capacity history is not chronological"))
    indices = findall(date -> startswith(String(date), "$(Int(evaluation_year))-"), dates)
    length(indices) > 1 || throw(ArgumentError("capacity evaluation calendar is incomplete"))
    lag = Int(lag_sessions)
    lag >= 2 || throw(ArgumentError("capacity lag window is too short"))
    cap = Float64(adv_fraction_cap)
    0 < cap <= 1 || throw(ArgumentError("capacity ADV fraction cap is invalid"))
    aums = Float64.(collect(aum_levels))
    spreads = Float64.(collect(half_spread_bps_levels))
    impacts = Float64.(collect(impact_coefficients))
    all(>(0), aums) || throw(ArgumentError("capacity AUM must be positive"))
    all(>=(0), spreads) || throw(ArgumentError("capacity half-spreads must be nonnegative"))
    all(>=(0), impacts) || throw(ArgumentError("capacity impact coefficients must be nonnegative"))

    result = CapacityOutcome[]
    for policy_id in sort!(String.(collect(keys(policy_effective_weights))))
        weights = Matrix{Float64}(policy_effective_weights[policy_id])
        size(weights) == size(security_returns) ||
            throw(DimensionMismatch("capacity policy weights do not align"))
        all(isfinite, weights) || error("capacity policy weights contain a nonfinite value")
        gross = zeros(Float64, length(indices))
        gross_available = trues(length(indices))
        for (row, session) in enumerate(indices), security in axes(weights, 2)
            abs(weights[session, security]) <= eps(Float64) && continue
            if !return_available[session, security] ||
               ismissing(security_returns[session, security]) ||
               !isfinite(Float64(security_returns[session, security]))
                gross_available[row] = false
                continue
            end
            gross[row] += weights[session, security] *
                Float64(security_returns[session, security])
        end
        gross_observations = count(identity, gross_available)
        for aum in aums, spread in spreads, impact in impacts
            if !all(gross_available)
                push!(result, _capacity_failure(
                    origin_id, universe_id, policy_id, aum, spread, impact, cap,
                    gross_observations, missing, "INCOMPLETE_CAPACITY_RETURN_PATH",
                ))
                continue
            end
            cost_fraction = zeros(Float64, length(indices))
            maximum_participation = 0.0
            failure_code = ""
            for (row, session) in enumerate(indices)
                previous_session = session - 1
                for security in axes(weights, 2)
                    previous_weight = previous_session >= 1 ?
                        weights[previous_session, security] : 0.0
                    order_dollars = aum * abs(weights[session, security] - previous_weight)
                    order_dollars <= eps(Float64) && continue
                    first_lag = session - lag
                    if first_lag < 1
                        failure_code = "CAPACITY_SOURCE_FIELDS_UNAVAILABLE"
                        break
                    end
                    lag_range = first_lag:(session - 1)
                    valid_market = all(index ->
                        !ismissing(close[index, security]) &&
                        !ismissing(volume[index, security]) &&
                        isfinite(Float64(close[index, security])) &&
                        isfinite(Float64(volume[index, security])) &&
                        Float64(close[index, security]) > 0 &&
                        Float64(volume[index, security]) >= 0,
                        lag_range,
                    )
                    valid_returns = all(index ->
                        return_available[index, security] &&
                        !ismissing(security_returns[index, security]) &&
                        isfinite(Float64(security_returns[index, security])),
                        lag_range,
                    )
                    if !(valid_market && valid_returns)
                        failure_code = "CAPACITY_SOURCE_FIELDS_UNAVAILABLE"
                        break
                    end
                    adv = mean(
                        Float64(close[index, security]) * Float64(volume[index, security])
                        for index in lag_range
                    )
                    if !(isfinite(adv) && adv > 0)
                        failure_code = "CAPACITY_SOURCE_FIELDS_UNAVAILABLE"
                        break
                    end
                    participation = order_dollars / adv
                    maximum_participation = max(maximum_participation, participation)
                    if participation > cap
                        failure_code = "CAPACITY_ADV_CAP_BREACH"
                        break
                    end
                    daily_volatility = sqrt(var(
                        Float64(security_returns[index, security]) for index in lag_range;
                        corrected = true,
                    ))
                    spread_cost = order_dollars * spread / 10_000
                    impact_cost = order_dollars * impact * daily_volatility * sqrt(participation)
                    cost_fraction[row] += (spread_cost + impact_cost) / aum
                end
                isempty(failure_code) || break
            end
            if !isempty(failure_code)
                push!(result, _capacity_failure(
                    origin_id, universe_id, policy_id, aum, spread, impact, cap,
                    length(indices), maximum_participation, failure_code,
                ))
                continue
            end
            net = gross .- cost_fraction
            annual_mean = ANNUALIZATION_SESSIONS * mean(gross)
            annual_cost = ANNUALIZATION_SESSIONS * mean(cost_fraction)
            variance_penalty = 0.5 * Float64(risk_aversion) * ANNUALIZATION_SESSIONS *
                var(net; corrected = true)
            push!(result, CapacityOutcome(
                String(origin_id),
                String(universe_id),
                policy_id,
                aum,
                spread,
                impact,
                cap,
                _capacity_seed(origin_id, universe_id, aum),
                true,
                length(indices),
                annual_mean - annual_cost - variance_penalty,
                annual_mean,
                variance_penalty,
                annual_cost,
                maximum_participation,
                "",
            ))
        end
    end
    return result
end

function origin_evaluation_contrast(outcomes)
    values = PolicyEvaluationOutcome[collect(outcomes)...]
    lookup = Dict(outcome.policy_id => outcome for outcome in values)
    PRIMARY_POLICIES ⊆ Set(keys(lookup)) ||
        throw(ArgumentError("origin contrast does not contain both primary policies"))
    safe = lookup[SAFE_POLICY]
    comparator = lookup[COMPARATOR_POLICY]
    safe_choice = join(safe.choice_ids, '\0')
    comparator_choice = join(comparator.choice_ids, '\0')
    safe.origin_id == comparator.origin_id && safe.universe_id == comparator.universe_id ||
        throw(ArgumentError("origin contrast crosses cells"))
    if !(safe.complete && comparator.complete)
        return OriginEvaluationContrast(
            safe.origin_id,
            safe.universe_id,
            false,
            safe_choice,
            comparator_choice,
            missing,
            missing,
            missing,
            missing,
            safe.choice_ids == comparator.choice_ids,
            "INCOMPLETE_PRIMARY_CHOICE_PAIR",
        )
    end
    difference(field) = Float64(getfield(safe, field)) - Float64(getfield(comparator, field))
    return OriginEvaluationContrast(
        safe.origin_id,
        safe.universe_id,
        true,
        safe_choice,
        comparator_choice,
        difference(:certainty_equivalent),
        difference(:annual_mean_component),
        difference(:annual_variance_penalty),
        difference(:annual_turnover_cost),
        safe.choice_ids == comparator.choice_ids,
        "",
    )
end

function summarize_policy_outcomes(outcomes; universe_id, policy_id)
    selected = filter(
        outcome -> outcome.universe_id == String(universe_id) &&
                   outcome.policy_id == String(policy_id),
        PolicyEvaluationOutcome[collect(outcomes)...],
    )
    complete = filter(outcome -> outcome.complete, selected)
    values = Float64[outcome.certainty_equivalent for outcome in complete]
    result = Dict{String,Any}(
        "universe_id" => String(universe_id),
        "policy_id" => String(policy_id),
        "registered_origin_count" => 19,
        "available_origin_count" => length(selected),
        "unavailable_origin_count" => 19 - length(selected),
        "complete_origin_count" => length(complete),
        "incomplete_origin_count" => length(selected) - length(complete),
        "positive_ce_count" => count(>(0), values),
        "zero_ce_count" => count(iszero, values),
        "negative_ce_count" => count(<(0), values),
    )
    if isempty(values)
        result["arithmetic_mean_ce"] = ""
        result["nearest_rank_median_ce"] = ""
        result["huber_m_estimate_ce"] = ""
        result["minimum_ce"] = ""
        result["maximum_ce"] = ""
    else
        result["arithmetic_mean_ce"] = mean(values)
        result["nearest_rank_median_ce"] = _nearest_rank(values, 0.5)
        result["huber_m_estimate_ce"] = _huber_location(values)
        result["minimum_ce"] = Base.minimum(values)
        result["maximum_ce"] = Base.maximum(values)
    end
    return result
end

function summarize_capacity_outcomes(
    outcomes;
    universe_id,
    policy_id,
    aum,
    half_spread_bps,
    impact_coefficient,
)
    selected = filter(outcome ->
        outcome.universe_id == String(universe_id) &&
        outcome.policy_id == String(policy_id) &&
        outcome.aum == Float64(aum) &&
        outcome.half_spread_bps == Float64(half_spread_bps) &&
        outcome.impact_coefficient == Float64(impact_coefficient),
        CapacityOutcome[collect(outcomes)...],
    )
    complete = filter(outcome -> outcome.complete, selected)
    values = Float64[outcome.certainty_equivalent for outcome in complete]
    failures = Dict{String,Int}()
    for outcome in selected
        isempty(outcome.failure_code) && continue
        failures[outcome.failure_code] = get(failures, outcome.failure_code, 0) + 1
    end
    result = Dict{String,Any}(
        "universe_id" => String(universe_id),
        "policy_id" => String(policy_id),
        "aum" => Float64(aum),
        "half_spread_bps" => Float64(half_spread_bps),
        "impact_coefficient" => Float64(impact_coefficient),
        "registered_origin_count" => 19,
        "available_origin_count" => length(selected),
        "unavailable_origin_count" => 19 - length(selected),
        "complete_origin_count" => length(complete),
        "incomplete_origin_count" => length(selected) - length(complete),
        "failure_counts" => failures,
    )
    if isempty(values)
        result["arithmetic_mean_ce"] = ""
        result["nearest_rank_median_ce"] = ""
        result["minimum_ce"] = ""
        result["maximum_ce"] = ""
    else
        result["arithmetic_mean_ce"] = mean(values)
        result["nearest_rank_median_ce"] = _nearest_rank(values, 0.5)
        result["minimum_ce"] = minimum(values)
        result["maximum_ce"] = maximum(values)
    end
    return result
end

function summarize_robustness_outcomes(outcomes; universe_id, context_id)
    selected = filter(outcome ->
        outcome.contrast.universe_id == String(universe_id) &&
        outcome.context_id == String(context_id),
        RobustnessEvaluationOutcome[collect(outcomes)...],
    )
    complete = filter(outcome -> outcome.contrast.complete, selected)
    values = Float64[
        outcome.contrast.certainty_equivalent_difference for outcome in complete
    ]
    result = Dict{String,Any}(
        "universe_id" => String(universe_id),
        "context_id" => String(context_id),
        "registered_origin_count" => 19,
        "available_origin_count" => length(selected),
        "unavailable_origin_count" => 19 - length(selected),
        "complete_origin_count" => length(complete),
        "incomplete_origin_count" => length(selected) - length(complete),
        "same_choice_count" => count(outcome -> outcome.contrast.same_choice, selected),
        "positive_count" => count(>(0), values),
        "zero_count" => count(iszero, values),
        "negative_count" => count(<(0), values),
    )
    if isempty(values)
        result["arithmetic_mean_ce_difference"] = ""
        result["nearest_rank_median_ce_difference"] = ""
        result["huber_m_estimate_ce_difference"] = ""
        result["minimum_ce_difference"] = ""
        result["maximum_ce_difference"] = ""
    else
        result["arithmetic_mean_ce_difference"] = mean(values)
        result["nearest_rank_median_ce_difference"] = _nearest_rank(values, 0.5)
        result["huber_m_estimate_ce_difference"] = _huber_location(values)
        result["minimum_ce_difference"] = minimum(values)
        result["maximum_ce_difference"] = maximum(values)
    end
    return result
end

function leave_one_origin_out_summary(contrasts; universe_id)
    selected = sort!(filter(
        contrast -> contrast.universe_id == String(universe_id),
        OriginEvaluationContrast[collect(contrasts)...],
    ); by = contrast -> contrast.origin_id)
    length(selected) == 19 ||
        throw(ArgumentError("leave-one-origin-out requires all 19 registered origins"))
    rows = Dict{String,Any}[]
    for omitted in selected
        retained = filter(contrast -> contrast.origin_id != omitted.origin_id, selected)
        values = Float64[
            contrast.certainty_equivalent_difference for contrast in retained if contrast.complete
        ]
        row = Dict{String,Any}(
            "omitted_origin_id" => omitted.origin_id,
            "omitted_origin_complete" => omitted.complete,
            "registered_retained_origin_count" => 18,
            "complete_retained_origin_count" => length(values),
            "incomplete_retained_origin_count" => 18 - length(values),
        )
        if isempty(values)
            row["arithmetic_mean_ce_difference"] = ""
            row["nearest_rank_median_ce_difference"] = ""
            row["huber_m_estimate_ce_difference"] = ""
        else
            row["arithmetic_mean_ce_difference"] = mean(values)
            row["nearest_rank_median_ce_difference"] = _nearest_rank(values, 0.5)
            row["huber_m_estimate_ce_difference"] = _huber_location(values)
        end
        push!(rows, row)
    end
    return Dict{String,Any}(
        "rule" => "AGGREGATION_ONLY_NO_RESELECTION",
        "universe_id" => String(universe_id),
        "omission_count" => 19,
        "rows" => rows,
    )
end

function _nearest_rank(values, probability)
    ordered = sort(Float64.(collect(values)))
    isempty(ordered) && throw(ArgumentError("nearest-rank statistic has no values"))
    return ordered[clamp(ceil(Int, probability * length(ordered)), 1, length(ordered))]
end

function _huber_location(values; tuning = 1.345, tolerance = 1e-12, max_iterations = 200)
    collected = Float64.(collect(values))
    location = _nearest_rank(collected, 0.5)
    deviations = abs.(collected .- location)
    scale = 1.4826 * _nearest_rank(deviations, 0.5)
    scale <= eps(Float64) && return location
    for _ in 1:max_iterations
        residual = (collected .- location) ./ scale
        weights = [iszero(value) ? 1.0 : min(1.0, tuning / abs(value)) for value in residual]
        updated = sum(weights .* collected) / sum(weights)
        abs(updated - location) <= tolerance * max(1.0, abs(location)) && return updated
        location = updated
    end
    return location
end

function summarize_origin_contrasts(
    contrasts;
    universe_id,
    minimum_complete_origins::Integer = 1,
    sealed_choice_hashes = Dict{Tuple{String,String},NamedTuple}(),
)
    selected = filter(
        contrast -> contrast.universe_id == String(universe_id),
        OriginEvaluationContrast[collect(contrasts)...],
    )
    complete = filter(contrast -> contrast.complete, selected)
    values = Float64[contrast.certainty_equivalent_difference for contrast in complete]
    minimum = Int(minimum_complete_origins)
    passed = length(values) >= minimum
    common = Dict{String,Any}(
        "universe_id" => String(universe_id),
        "registered_origin_count" => length(selected),
        "complete_origin_count" => length(values),
        "failed_origin_count" => length(selected) - length(values),
        "minimum_complete_origins" => minimum,
        "availability_gate_passed" => passed,
        "positive_count" => count(>(0), values),
        "zero_count" => count(iszero, values),
        "negative_count" => count(<(0), values),
        "same_choice_count" => count(contrast -> contrast.same_choice, selected),
        "origin_values" => [
            let hashes = get(
                sealed_choice_hashes,
                (contrast.origin_id, contrast.universe_id),
                (safe = "", comparator = ""),
            )
            Dict(
                "origin_id" => contrast.origin_id,
                "complete" => contrast.complete,
                "safe_choice_sha256" => String(hashes.safe),
                "comparator_choice_sha256" => String(hashes.comparator),
                "same_choice" => contrast.same_choice,
                "certainty_equivalent_difference" => ismissing(contrast.certainty_equivalent_difference) ?
                    "" : contrast.certainty_equivalent_difference,
                "failure_code" => contrast.failure_code,
            ) end for contrast in selected
        ],
    )
    if isempty(values)
        for field in ("arithmetic_mean", "nearest_rank_median", "huber_m_estimate", "iqr", "minimum", "maximum")
            common[field] = ""
        end
        common["conclusion"] = "INCONCLUSIVE_AVAILABILITY_GATE"
        return common
    end
    common["arithmetic_mean"] = mean(values)
    common["nearest_rank_median"] = _nearest_rank(values, 0.5)
    common["huber_m_estimate"] = _huber_location(values)
    common["iqr"] = _nearest_rank(values, 0.75) - _nearest_rank(values, 0.25)
    common["minimum"] = Base.minimum(values)
    common["maximum"] = Base.maximum(values)
    common["conclusion"] = passed ? "DESCRIPTIVE_HISTORICAL_RESULT" :
        "INCONCLUSIVE_AVAILABILITY_GATE"
    return common
end

function _average_ranks(values)
    collected = Float64.(collect(values))
    order = sortperm(eachindex(collected); by = index -> (collected[index], index))
    ranks = zeros(Float64, length(collected))
    position = 1
    while position <= length(order)
        last_position = position
        while last_position < length(order) &&
              collected[order[last_position + 1]] == collected[order[position]]
            last_position += 1
        end
        rank = (position + last_position) / 2
        for ordered_position in position:last_position
            ranks[order[ordered_position]] = rank
        end
        position = last_position + 1
    end
    return ranks
end

function proposal_evaluation_calibration(proposal_differences, evaluation_differences)
    proposal = Float64.(collect(proposal_differences))
    evaluation = Float64.(collect(evaluation_differences))
    length(proposal) == length(evaluation) ||
        throw(DimensionMismatch("proposal/evaluation calibration vectors differ"))
    length(proposal) >= 3 || return Dict{String,Any}(
        "complete_pair_count" => length(proposal),
        "pearson_correlation" => "",
        "spearman_rank_correlation" => "",
        "status" => "INSUFFICIENT_PAIRS",
    )
    if iszero(var(proposal)) || iszero(var(evaluation))
        return Dict{String,Any}(
            "complete_pair_count" => length(proposal),
            "pearson_correlation" => "",
            "spearman_rank_correlation" => "",
            "status" => "UNDEFINED_ZERO_VARIANCE",
        )
    end
    pearson = cor(proposal, evaluation)
    proposal_rank = _average_ranks(proposal)
    evaluation_rank = _average_ranks(evaluation)
    spearman = iszero(var(proposal_rank)) || iszero(var(evaluation_rank)) ?
        "" : cor(proposal_rank, evaluation_rank)
    return Dict{String,Any}(
        "complete_pair_count" => length(proposal),
        "pearson_correlation" => pearson,
        "spearman_rank_correlation" => spearman,
        "status" => "DESCRIPTIVE_ONLY",
    )
end

function _ledger_record_hash(row)
    return _sha256_text(join((string(row[field]) for field in TRIAL_LEDGER_FIELDS[1:(end - 1)]), '\0'))
end

"""
Fill evaluation fields only for identities already selected by the five frozen
registered policies. Every registered row is retained in its original order
and receives a recomputed canonical record hash; no trial can be added,
removed, or relabeled.
"""
function update_trial_ledger(rows, outcomes; full_search_candidate_outcomes = EvaluationOutcome[])
    input = [Dict{String,Any}(String(key) => value for (key, value) in row) for row in rows]
    trial_ids = String.(getindex.(input, "trial_id"))
    length(unique(trial_ids)) == length(trial_ids) || error("trial ledger identifiers are not unique")
    outcome_values = EvaluationOutcome[collect(outcomes)...]
    outcome_lookup = Dict(
        (outcome.origin_id, outcome.universe_id, outcome.policy_id, outcome.strategy_id) => outcome
        for outcome in outcome_values
    )
    length(outcome_lookup) == length(outcome_values) ||
        error("duplicate evaluation outcome key")
    candidate_values = EvaluationOutcome[collect(full_search_candidate_outcomes)...]
    candidate_lookup = Dict(
        (outcome.origin_id, outcome.universe_id, outcome.strategy_id) => outcome
        for outcome in candidate_values
    )
    length(candidate_lookup) == length(candidate_values) ||
        error("duplicate full-search candidate outcome key")
    consumed = Set{Tuple{String,String,String,String}}()
    output = Dict{String,Any}[]
    for original in input
        row = copy(original)
        for field in TRIAL_LEDGER_FIELDS
            haskey(row, field) || error("trial ledger field is absent: $field")
        end
        policy = String(row["policy_id"])
        selected = _bool(row["policy_selected"])
        candidate_key = (
            String(row["origin_id"]),
            String(row["universe_id"]),
            String(row["strategy_id"]),
        )
        diagnostic_applicable = _bool(row["generatable"]) && haskey(candidate_lookup, candidate_key)
        if diagnostic_applicable || (selected && policy in REGISTERED_POLICIES)
            key = (
                String(row["origin_id"]),
                String(row["universe_id"]),
                policy,
                String(row["strategy_id"]),
            )
            outcome = if haskey(outcome_lookup, key)
                push!(consumed, key)
                outcome_lookup[key]
            elseif diagnostic_applicable
                candidate_lookup[candidate_key]
            else
                error("selected registered trial has no frozen evaluation outcome")
            end
            row["evaluation_observation_count"] = outcome.observation_count
            row["evaluation_ce"] = ismissing(outcome.certainty_equivalent) ? "" :
                outcome.certainty_equivalent
            row["evaluation_mean_component"] = ismissing(outcome.annual_mean_component) ? "" :
                outcome.annual_mean_component
            row["evaluation_variance_penalty"] = ismissing(outcome.annual_variance_penalty) ? "" :
                outcome.annual_variance_penalty
            row["evaluation_turnover_cost"] = ismissing(outcome.annual_turnover_cost) ? "" :
                outcome.annual_turnover_cost
            if !outcome.complete && isempty(String(row["failure_code"]))
                row["failure_code"] = outcome.failure_code
            end
        else
            Int(row["evaluation_observation_count"]) == 0 ||
                error("an unscored trial already contains evaluation observations")
            all(isempty(String(row[field])) for field in (
                "evaluation_ce",
                "evaluation_mean_component",
                "evaluation_variance_penalty",
                "evaluation_turnover_cost",
            )) || error("an unscored trial already contains evaluation values")
        end
        row["record_hash"] = _ledger_record_hash(row)
        push!(output, row)
    end
    consumed == Set(keys(outcome_lookup)) ||
        error("an evaluation outcome is not bound to a selected registered trial")
    String.(getindex.(output, "trial_id")) == trial_ids ||
        error("evaluation ledger update changed the registered trial set or order")
    return output
end

end # module
