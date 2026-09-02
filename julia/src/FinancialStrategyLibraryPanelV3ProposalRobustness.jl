module FinancialStrategyLibraryPanelV3ProposalRobustness

using Random: rand
using StableRNGs: StableRNG
using Statistics: mean, median, std, var

include(joinpath(@__DIR__, "FinancialStrategyLibraryPanelV3.jl"))
using .FinancialStrategyLibraryPanelV3: stable_seed

export RobustnessPath,
       RobustnessChoice,
       RobustnessInference,
       robustness_grid,
       freeze_cost_risk_hurdle_grid,
       primary_cap_choices

const CASH_ID = "mandatory_inactive_cash"
const ANNUALIZATION_SESSIONS = 252
const BOOTSTRAP_REPETITIONS = 5_000
const BLOCK_SESSIONS = 20
const FAMILYWISE_ALPHA = 0.10
const BASE_SEED = 310002

struct RobustnessPath
    strategy_id::String
    gross_returns::Vector{Union{Missing,Float64}}
    turnover::Vector{Float64}
    available::BitVector
end

struct RobustnessChoice
    policy_id::String
    selected_strategy_id::String
    used_cash::Bool
    baseline_strategy_id::String
    selected_point_delta::Float64
    selected_lower_bound::Float64
    eligible_count::Int
    complete_candidate_count::Int
    failure_code::String
end

struct RobustnessInference
    candidate_ids::Vector{String}
    point_deltas::Vector{Float64}
    standard_errors::Vector{Float64}
    lower_bounds::Vector{Float64}
    shrunk_deltas::Vector{Float64}
    shrinkage_center::Float64
    estimated_between_variance::Float64
    critical_value::Float64
    bootstrap_repetitions::Int
    moving_block_sessions::Int
    seed::Int
    simultaneous_family_contrast_count::Int
end

struct SafeJointFamily
    ordered_ids::Vector{String}
    point_ce::Vector{Float64}
    bootstrap_ce::Matrix{Float64}
    safe_ids::Vector{String}
    comparator_ids::Vector{String}
    pair_indices::Vector{Tuple{Int,Int}}
    pair_point::Vector{Float64}
    pair_standard_errors::Vector{Float64}
    critical_value::Float64
    seed::Int
end

function _complete_net(path::RobustnessPath, cost_bps::Real)
    all(path.available) || return nothing
    any(ismissing, path.gross_returns) && return nothing
    length(path.gross_returns) == length(path.turnover) == length(path.available) ||
        throw(DimensionMismatch("robustness path fields differ in length"))
    cost = Float64(cost_bps) / 10_000
    values = Float64[
        Float64(path.gross_returns[index]) - cost * path.turnover[index] for
        index in eachindex(path.gross_returns)
    ]
    all(isfinite, values) || return nothing
    return values
end

function _ce(values, risk_aversion::Real)
    length(values) > 1 || throw(ArgumentError("robustness CE needs at least two sessions"))
    risk = Float64(risk_aversion)
    risk >= 0 || throw(ArgumentError("risk aversion must be nonnegative"))
    return ANNUALIZATION_SESSIONS * mean(values) -
           0.5 * risk * ANNUALIZATION_SESSIONS * var(values; corrected = true)
end

function _ce_from_moments(total, total_squares, sessions, risk_aversion)
    n = Int(sessions)
    average = total / n
    centered = max(0.0, total_squares - total^2 / n)
    sample_variance = centered / (n - 1)
    return ANNUALIZATION_SESSIONS * average -
           0.5 * Float64(risk_aversion) * ANNUALIZATION_SESSIONS * sample_variance
end

function _circular_block_moments(series, block_sessions)
    sessions, columns = size(series)
    remainder = rem(sessions, block_sessions)
    lengths = remainder == 0 ? (block_sessions,) : (block_sessions, remainder)
    sums = Dict{Int,Matrix{Float64}}()
    squares = Dict{Int,Matrix{Float64}}()
    for length_value in lengths
        block_sums = Matrix{Float64}(undef, sessions, columns)
        block_squares = Matrix{Float64}(undef, sessions, columns)
        for start in 1:sessions, column in 1:columns
            total = 0.0
            total_squares = 0.0
            for offset in 0:(length_value - 1)
                value = series[mod1(start + offset, sessions), column]
                total += value
                total_squares += value^2
            end
            block_sums[start, column] = total
            block_squares[start, column] = total_squares
        end
        sums[length_value] = block_sums
        squares[length_value] = block_squares
    end
    return (; sums, squares)
end

function _bootstrap_ce(series, risk_aversion, seed;
    repetitions = BOOTSTRAP_REPETITIONS,
    block_sessions = BLOCK_SESSIONS,
)
    sessions, columns = size(series)
    sessions > 1 || throw(ArgumentError("robustness bootstrap needs at least two sessions"))
    repetitions >= 100 || throw(ArgumentError("robustness bootstrap needs 100 repetitions"))
    block_sessions >= 1 || throw(ArgumentError("moving block must be positive"))
    moments = _circular_block_moments(series, block_sessions)
    result = Matrix{Float64}(undef, repetitions, columns)
    rng = StableRNG(seed)
    block_count = cld(sessions, block_sessions)
    final_length = rem(sessions, block_sessions)
    final_length == 0 && (final_length = block_sessions)
    totals = zeros(Float64, columns)
    squares = zeros(Float64, columns)
    for repetition in 1:repetitions
        fill!(totals, 0.0)
        fill!(squares, 0.0)
        for block_index in 1:block_count
            start = rand(rng, 1:sessions)
            length_value = block_index == block_count ? final_length : block_sessions
            totals .+= @view moments.sums[length_value][start, :]
            squares .+= @view moments.squares[length_value][start, :]
        end
        for column in 1:columns
            result[repetition, column] = _ce_from_moments(
                totals[column], squares[column], sessions, risk_aversion,
            )
        end
    end
    return result
end

function _family_shrink(point, standard_errors)
    isempty(point) && return Float64[], 0.0, 0.0
    center = mean(point)
    between = length(point) > 1 ? var(point; corrected = true) : 0.0
    noise = median(standard_errors .^ 2)
    latent = max(0.0, between - noise)
    shrunk = Float64[
        center + (latent / (latent + standard_errors[index]^2 + eps(Float64))) *
                 (point[index] - center) for index in eachindex(point)
    ]
    return shrunk, center, latent
end

function _critical_lower(point, bootstrap; alpha = FAMILYWISE_ALPHA)
    repetitions, candidates = size(bootstrap)
    candidates == length(point) || throw(DimensionMismatch("bootstrap family changed"))
    candidates == 0 && return Float64[], Float64[], 0.0
    standard_errors = Float64[
        std(@view bootstrap[:, candidate]; corrected = true) for candidate in 1:candidates
    ]
    max_t = Vector{Float64}(undef, repetitions)
    for repetition in 1:repetitions
        maximum_value = -Inf
        for candidate in 1:candidates
            scale = standard_errors[candidate]
            statistic = scale > eps(Float64) ?
                (point[candidate] - bootstrap[repetition, candidate]) / scale : 0.0
            maximum_value = max(maximum_value, statistic)
        end
        max_t[repetition] = maximum_value
    end
    sort!(max_t)
    critical = max_t[clamp(ceil(Int, (1 - alpha) * repetitions), 1, repetitions)]
    return standard_errors, point .- critical .* standard_errors, critical
end

function _empty_inference(seed; family_count = 0)
    return RobustnessInference(
        String[], Float64[], Float64[], Float64[], Float64[], 0.0, 0.0, 0.0,
        BOOTSTRAP_REPETITIONS, BLOCK_SESSIONS, seed, family_count,
    )
end

function _cash_inference(candidates, cost_bps, risk_aversion, origin_id, universe_id)
    complete_ids = String[]
    complete_values = Vector{Vector{Float64}}()
    for path in sort!(RobustnessPath[collect(candidates)...]; by = p -> p.strategy_id)
        values = _complete_net(path, cost_bps)
        isnothing(values) && continue
        push!(complete_ids, path.strategy_id)
        push!(complete_values, values)
    end
    seed = stable_seed(
        BASE_SEED,
        "frontier_only_robust_policy",
        origin_id,
        universe_id,
    )
    isempty(complete_values) && return _empty_inference(seed)
    sessions = length(first(complete_values))
    all(values -> length(values) == sessions, complete_values) ||
        throw(DimensionMismatch("comparator candidate calendars differ"))
    series = hcat(zeros(sessions), complete_values...)
    bootstrap_ce = _bootstrap_ce(series, risk_aversion, seed)
    point = Float64[_ce(values, risk_aversion) for values in complete_values]
    bootstrap_delta = bootstrap_ce[:, 2:end] .- bootstrap_ce[:, 1]
    standard_errors, lower, critical = _critical_lower(point, bootstrap_delta)
    shrunk, center, latent = _family_shrink(point, standard_errors)
    return RobustnessInference(
        complete_ids, point, standard_errors, lower, shrunk, center, latent, critical,
        BOOTSTRAP_REPETITIONS, BLOCK_SESSIONS, seed, length(complete_ids),
    )
end

function _choice_from_inference(policy_id, inference, baseline_id, hurdle)
    eligible = findall(>(Float64(hurdle)), inference.lower_bounds)
    if isempty(eligible)
        return RobustnessChoice(
            String(policy_id), String(baseline_id), baseline_id == CASH_ID,
            String(baseline_id), 0.0, 0.0, 0, length(inference.candidate_ids), "",
        )
    end
    selected = sort(
        eligible;
        by = index -> (-inference.shrunk_deltas[index], inference.candidate_ids[index]),
    )[1]
    return RobustnessChoice(
        String(policy_id), inference.candidate_ids[selected], false, String(baseline_id),
        inference.point_deltas[selected], inference.lower_bounds[selected],
        length(eligible), length(inference.candidate_ids), "",
    )
end

function _safe_joint_family(
    safe_candidates,
    comparator_candidates,
    cost_bps,
    risk_aversion,
    origin_id,
    universe_id,
)
    safe_values = Dict{String,Vector{Float64}}()
    comparator_values = Dict{String,Vector{Float64}}(CASH_ID => Float64[])
    sessions = 0
    for (destination, paths) in (
        (safe_values, safe_candidates),
        (comparator_values, comparator_candidates),
    )
        for path in sort!(RobustnessPath[collect(paths)...]; by = p -> p.strategy_id)
            values = _complete_net(path, cost_bps)
            isnothing(values) && continue
            sessions == 0 && (sessions = length(values))
            length(values) == sessions || throw(DimensionMismatch("safe family calendars differ"))
            destination[path.strategy_id] = values
        end
    end
    sessions > 1 || (sessions = 2)
    comparator_values[CASH_ID] = zeros(sessions)
    for (id, values) in safe_values
        if haskey(comparator_values, id)
            comparator_values[id] == values || error("nested strategy maps to unequal paths")
        end
    end
    all_values = merge(copy(comparator_values), safe_values)
    ordered_ids = sort!(collect(keys(all_values)))
    id_index = Dict(id => index for (index, id) in enumerate(ordered_ids))
    series = hcat((all_values[id] for id in ordered_ids)...)
    point_ce = Float64[_ce(all_values[id], risk_aversion) for id in ordered_ids]
    seed = stable_seed(
        BASE_SEED,
        "innovation_safe_robust_policy",
        origin_id,
        universe_id,
    )
    bootstrap_ce = _bootstrap_ce(series, risk_aversion, seed)
    safe_ids = sort!(collect(keys(safe_values)))
    comparator_ids = sort!(collect(keys(comparator_values)))
    pair_indices = Tuple{Int,Int}[]
    for safe_id in safe_ids, comparator_id in comparator_ids
        safe_id == comparator_id && continue
        push!(pair_indices, (id_index[safe_id], id_index[comparator_id]))
    end
    sort!(unique!(pair_indices))
    pair_point = Float64[
        point_ce[safe_index] - point_ce[comparator_index] for
        (safe_index, comparator_index) in pair_indices
    ]
    pair_bootstrap = Matrix{Float64}(undef, BOOTSTRAP_REPETITIONS, length(pair_indices))
    for (pair, (safe_index, comparator_index)) in enumerate(pair_indices)
        pair_bootstrap[:, pair] .=
            @view(bootstrap_ce[:, safe_index]) .- @view(bootstrap_ce[:, comparator_index])
    end
    pair_standard_errors, _, critical = _critical_lower(pair_point, pair_bootstrap)
    return SafeJointFamily(
        ordered_ids,
        point_ce,
        bootstrap_ce,
        safe_ids,
        comparator_ids,
        pair_indices,
        pair_point,
        pair_standard_errors,
        critical,
        seed,
    )
end

function _safe_inference(joint::SafeJointFamily, baseline_id)
    baseline_id in joint.comparator_ids ||
        error("selected comparator baseline is outside the simultaneous family")
    id_index = Dict(id => index for (index, id) in enumerate(joint.ordered_ids))
    baseline_index = id_index[baseline_id]
    alternatives = filter(!=(baseline_id), joint.safe_ids)
    points = Float64[]
    standard_errors = Float64[]
    for candidate_id in alternatives
        pair = (id_index[candidate_id], baseline_index)
        pair_index = findfirst(==(pair), joint.pair_indices)
        isnothing(pair_index) && error("selected safe contrast is outside joint family")
        push!(points, joint.pair_point[pair_index])
        push!(standard_errors, joint.pair_standard_errors[pair_index])
    end
    lower = points .- joint.critical_value .* standard_errors
    shrunk, center, latent = _family_shrink(points, standard_errors)
    return RobustnessInference(
        alternatives,
        points,
        standard_errors,
        lower,
        shrunk,
        center,
        latent,
        joint.critical_value,
        BOOTSTRAP_REPETITIONS,
        BLOCK_SESSIONS,
        joint.seed,
        length(joint.pair_indices),
    )
end

function freeze_cost_risk_hurdle_grid(
    safe_candidates,
    comparator_candidates,
    origin_id,
    universe_id;
    costs = (0.0, 5.0, 15.0, 30.0),
    risk_aversions = (1.0, 3.0),
    hurdles = (0.0, 0.0025, 0.005),
)
    results = NamedTuple[]
    for cost_bps in costs, risk_aversion in risk_aversions
        comparator_inference = _cash_inference(
            comparator_candidates,
            cost_bps,
            risk_aversion,
            origin_id,
            universe_id,
        )
        safe_joint = _safe_joint_family(
            safe_candidates,
            comparator_candidates,
            cost_bps,
            risk_aversion,
            origin_id,
            universe_id,
        )
        for hurdle in hurdles
            comparator = _choice_from_inference(
                "frontier_only_robust_policy",
                comparator_inference,
                CASH_ID,
                hurdle,
            )
            safe_inference = _safe_inference(safe_joint, comparator.selected_strategy_id)
            safe = _choice_from_inference(
                "innovation_safe_robust_policy",
                safe_inference,
                comparator.selected_strategy_id,
                hurdle,
            )
            push!(results, (;
                cost_bps = Float64(cost_bps),
                risk_aversion = Float64(risk_aversion),
                hurdle = Float64(hurdle),
                comparator,
                safe,
                comparator_inference,
                safe_inference,
            ))
        end
    end
    length(results) == length(costs) * length(risk_aversions) * length(hurdles) ||
        error("cost/risk/hurdle grid construction changed")
    return results
end

function primary_cap_choices(safe_candidates, comparator_candidates, origin_id, universe_id)
    grid = freeze_cost_risk_hurdle_grid(
        safe_candidates,
        comparator_candidates,
        origin_id,
        universe_id;
        costs = (5.0,),
        risk_aversions = (3.0,),
        hurdles = (0.0025,),
    )
    return only(grid)
end

robustness_grid(args...; kwargs...) = freeze_cost_risk_hurdle_grid(args...; kwargs...)

end # module
