module FinancialStrategyLibraryPanelV3Proposal

using Random: rand
using SHA: sha256
using StableRNGs: StableRNG
using Statistics: mean, median, std, var

include(joinpath(@__DIR__, "FinancialStrategyLibraryPanelV3.jl"))
using .FinancialStrategyLibraryPanelV3: stable_seed

include(joinpath(@__DIR__, "FinancialStrategyLibraryPanelV3PredecisionComputation.jl"))
using .FinancialStrategyLibraryPanelV3PredecisionComputation: StrategyPath,
                                                               build_strategy_paths,
                                                               certainty_equivalent

export ProposalCandidatePath,
       ProposalPolicyChoice,
       SimultaneousInference,
       action_candidate_paths,
       cash_candidate_path,
       equal_weight_positive_choice,
       forced_max_choice,
       robust_cash_choice,
       robust_safe_choice,
       simultaneous_moving_block_max_t

const ANNUALIZATION_SESSIONS = 252
const PRIMARY_RISK_AVERSION = 3.0
const PRIMARY_COST_BPS = 5.0
const PRIMARY_HURDLE = 0.0025
const PRIMARY_BOOTSTRAP_REPETITIONS = 5_000
const PRIMARY_BLOCK_SESSIONS = 20
const PRIMARY_FAMILYWISE_ALPHA = 0.10

struct ProposalCandidatePath
    strategy_id::String
    net_returns::Vector{Union{Missing,Float64}}
    available::BitVector
end

struct SimultaneousInference
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
end

struct ProposalPolicyChoice
    policy_id::String
    selected_strategy_ids::Vector{String}
    used_cash::Bool
    baseline_strategy_id::String
    selected_point_delta::Float64
    selected_lower_bound::Float64
    eligible_count::Int
    complete_candidate_count::Int
    failure_code::String
end

_sha256_text(value) = bytes2hex(sha256(codeunits(String(value))))

function cash_candidate_path(session_count::Integer)
    n = Int(session_count)
    n > 1 || throw(ArgumentError("proposal cash path needs at least two sessions"))
    return ProposalCandidatePath(
        "mandatory_inactive_cash",
        Union{Missing,Float64}[zeros(n)...],
        trues(n),
    )
end

function _proposal_path(path::StrategyPath, proposal_indices; cost_bps = PRIMARY_COST_BPS)
    indices = Int.(collect(proposal_indices))
    cost = Float64(cost_bps) / 10_000
    values = Vector{Union{Missing,Float64}}(undef, length(indices))
    available = BitVector(undef, length(indices))
    for (position, index) in enumerate(indices)
        available[position] = path.available[index]
        if path.available[index]
            ismissing(path.gross_returns[index]) &&
                error("an available proposal gross return is missing")
            values[position] = Float64(path.gross_returns[index]) -
                               cost * path.turnover[index]
        else
            values[position] = missing
        end
    end
    return ProposalCandidatePath(path.strategy_id, values, available)
end

function action_candidate_paths(
    origin_id,
    universe_id,
    security_returns,
    return_available,
    terminal_delisting,
    dates,
    proposal_year::Integer,
    action_strategy_ids;
    security_weight_cap::Real,
)
    all_paths = build_strategy_paths(
        origin_id,
        universe_id,
        security_returns,
        return_available,
        terminal_delisting;
        security_weight_cap,
    )
    requested = Set(String.(collect(action_strategy_ids)))
    lookup = Dict(path.strategy_id => path for path in all_paths)
    issubset(requested, Set(keys(lookup))) ||
        error("a frozen proposal action is outside the 96-strategy grammar")
    proposal_indices = findall(date -> startswith(String(date), "$(Int(proposal_year))-") , dates)
    length(proposal_indices) > 1 || error("proposal reference calendar is incomplete")
    result = ProposalCandidatePath[
        _proposal_path(lookup[strategy_id], proposal_indices) for
        strategy_id in sort!(collect(requested))
    ]
    return (; paths = result, proposal_indices)
end

function _complete_values(path::ProposalCandidatePath)
    all(path.available) || return nothing
    any(ismissing, path.net_returns) && return nothing
    values = Float64.(path.net_returns)
    all(isfinite, values) || return nothing
    return values
end

function _ce(values)
    return certainty_equivalent(
        Union{Missing,Float64}[values...],
        zeros(length(values)),
        trues(length(values));
        cost_bps = 0,
        risk_aversion = PRIMARY_RISK_AVERSION,
        annualization_sessions = ANNUALIZATION_SESSIONS,
    )
end

function _moving_block_indices(rng, sessions, block_sessions)
    indices = Vector{Int}(undef, sessions)
    cursor = 1
    while cursor <= sessions
        start = rand(rng, 1:sessions)
        for offset in 0:(block_sessions - 1)
            cursor > sessions && break
            indices[cursor] = mod1(start + offset, sessions)
            cursor += 1
        end
    end
    return indices
end

function _ce_from_moments(total, total_squares, sessions)
    n = Int(sessions)
    n > 1 || throw(ArgumentError("proposal CE moments need at least two sessions"))
    average = total / n
    centered_sum_squares = max(0.0, total_squares - total^2 / n)
    variance = centered_sum_squares / (n - 1)
    return ANNUALIZATION_SESSIONS * average -
           0.5 * PRIMARY_RISK_AVERSION * ANNUALIZATION_SESSIONS * variance
end

function _circular_block_moments(series, block_sessions)
    sessions, columns = size(series)
    block = Int(block_sessions)
    remainder = rem(sessions, block)
    lengths = remainder == 0 ? (block,) : (block, remainder)
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

function _family_shrink(point, standard_errors)
    isempty(point) && return (Float64[], 0.0, 0.0)
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

function simultaneous_moving_block_max_t(
    candidates,
    baseline::ProposalCandidatePath;
    base_seed::Integer,
    purpose_id,
    scope_values = (),
    bootstrap_repetitions::Integer = PRIMARY_BOOTSTRAP_REPETITIONS,
    moving_block_sessions::Integer = PRIMARY_BLOCK_SESSIONS,
    familywise_alpha::Real = PRIMARY_FAMILYWISE_ALPHA,
)
    baseline_values = _complete_values(baseline)
    isnothing(baseline_values) && throw(ArgumentError("proposal baseline path is incomplete"))
    complete = ProposalCandidatePath[]
    candidate_values = Vector{Vector{Float64}}()
    for candidate in sort!(ProposalCandidatePath[collect(candidates)...]; by = path -> path.strategy_id)
        values = _complete_values(candidate)
        isnothing(values) && continue
        length(values) == length(baseline_values) ||
            throw(DimensionMismatch("proposal candidate calendar differs from baseline"))
        push!(complete, candidate)
        push!(candidate_values, values)
    end
    isempty(complete) && return SimultaneousInference(
        String[], Float64[], Float64[], Float64[], Float64[], 0.0, 0.0, 0.0,
        Int(bootstrap_repetitions), Int(moving_block_sessions),
        stable_seed(base_seed, purpose_id, scope_values...),
    )
    repetitions = Int(bootstrap_repetitions)
    repetitions >= 100 || throw(ArgumentError("max-t bootstrap needs at least 100 repetitions"))
    block = Int(moving_block_sessions)
    block >= 1 || throw(ArgumentError("moving-block length must be positive"))
    alpha = Float64(familywise_alpha)
    0 < alpha < 1 || throw(ArgumentError("familywise alpha must lie in (0,1)"))
    sessions = length(baseline_values)
    point = Float64[_ce(values) - _ce(baseline_values) for values in candidate_values]
    bootstrap = Matrix{Float64}(undef, repetitions, length(complete))
    seed = stable_seed(base_seed, purpose_id, scope_values...)
    rng = StableRNG(seed)
    series = hcat(baseline_values, candidate_values...)
    moments = _circular_block_moments(series, block)
    column_count = size(series, 2)
    block_count = cld(sessions, block)
    final_block_sessions = rem(sessions, block)
    final_block_sessions == 0 && (final_block_sessions = block)
    for repetition in 1:repetitions
        totals = zeros(Float64, column_count)
        total_squares = zeros(Float64, column_count)
        for block_index in 1:block_count
            start = rand(rng, 1:sessions)
            length_value = block_index == block_count ? final_block_sessions : block
            totals .+= @view moments.sums[length_value][start, :]
            total_squares .+= @view moments.squares[length_value][start, :]
        end
        baseline_ce = _ce_from_moments(totals[1], total_squares[1], sessions)
        for candidate in eachindex(complete)
            candidate_column = candidate + 1
            bootstrap[repetition, candidate] = _ce_from_moments(
                totals[candidate_column],
                total_squares[candidate_column],
                sessions,
            ) - baseline_ce
        end
    end
    standard_errors = Float64[
        std(@view bootstrap[:, candidate]; corrected = true) for
        candidate in eachindex(complete)
    ]
    max_t = Vector{Float64}(undef, repetitions)
    for repetition in 1:repetitions
        maximum_value = -Inf
        for candidate in eachindex(complete)
            scale = standard_errors[candidate]
            studentized = scale > eps(Float64) ?
                (point[candidate] - bootstrap[repetition, candidate]) / scale : 0.0
            maximum_value = max(maximum_value, studentized)
        end
        max_t[repetition] = maximum_value
    end
    sort!(max_t)
    critical_index = clamp(ceil(Int, (1 - alpha) * repetitions), 1, repetitions)
    critical = max_t[critical_index]
    lower = point .- critical .* standard_errors
    shrunk, center, latent = _family_shrink(point, standard_errors)
    return SimultaneousInference(
        getfield.(complete, :strategy_id),
        point,
        standard_errors,
        lower,
        shrunk,
        center,
        latent,
        critical,
        repetitions,
        block,
        seed,
    )
end

function _robust_choice(policy_id, inference, baseline; hurdle = PRIMARY_HURDLE)
    eligible = findall(>(Float64(hurdle)), inference.lower_bounds)
    if isempty(eligible)
        return ProposalPolicyChoice(
            String(policy_id),
            [baseline.strategy_id],
            baseline.strategy_id == "mandatory_inactive_cash",
            baseline.strategy_id,
            0.0,
            0.0,
            0,
            length(inference.candidate_ids),
            "",
        )
    end
    selected = sort(
        eligible;
        by = index -> (-inference.shrunk_deltas[index], inference.candidate_ids[index]),
    )[1]
    return ProposalPolicyChoice(
        String(policy_id),
        [inference.candidate_ids[selected]],
        false,
        baseline.strategy_id,
        inference.point_deltas[selected],
        inference.lower_bounds[selected],
        length(eligible),
        length(inference.candidate_ids),
        "",
    )
end

function robust_cash_choice(
    policy_id,
    candidates;
    base_seed::Integer,
    scope_values = (),
    kwargs...,
)
    collected = ProposalCandidatePath[collect(candidates)...]
    isempty(collected) && return ProposalPolicyChoice(
        String(policy_id), ["mandatory_inactive_cash"], true, "mandatory_inactive_cash",
        0.0, 0.0, 0, 0, "NO_COMPLETE_ACTIVE_PROPOSAL_PATH",
    ), simultaneous_moving_block_max_t(
        ProposalCandidatePath[], cash_candidate_path(2);
        base_seed, purpose_id = policy_id, scope_values, kwargs...,
    )
    sessions = length(first(collected).net_returns)
    cash = cash_candidate_path(sessions)
    inference = simultaneous_moving_block_max_t(
        collected,
        cash;
        base_seed,
        purpose_id = policy_id,
        scope_values,
        kwargs...,
    )
    return _robust_choice(policy_id, inference, cash), inference
end

function robust_safe_choice(
    candidates,
    comparator_choice::ProposalPolicyChoice;
    comparator_candidates = nothing,
    base_seed::Integer,
    scope_values = (),
    kwargs...,
)
    collected = ProposalCandidatePath[collect(candidates)...]
    isempty(comparator_choice.selected_strategy_ids) &&
        throw(ArgumentError("safe policy has no comparator default"))
    baseline_id = only(comparator_choice.selected_strategy_ids)
    sessions = isempty(collected) ? 2 : length(first(collected).net_returns)
    baseline = if baseline_id == "mandatory_inactive_cash"
        cash_candidate_path(sessions)
    else
        index = findfirst(path -> path.strategy_id == baseline_id, collected)
        isnothing(index) && error("safe action paths omit the exact comparator choice")
        collected[index]
    end
    comparator_family = isnothing(comparator_candidates) ? collected :
        ProposalCandidatePath[collect(comparator_candidates)...]
    inference = _selection_aware_safe_max_t(
        collected,
        comparator_family,
        baseline;
        base_seed,
        purpose_id = "innovation_safe_robust_policy",
        scope_values,
        kwargs...,
    )
    return _robust_choice("innovation_safe_robust_policy", inference, baseline), inference
end

function _selection_aware_safe_max_t(
    safe_candidates,
    comparator_candidates,
    selected_baseline::ProposalCandidatePath;
    base_seed::Integer,
    purpose_id,
    scope_values = (),
    bootstrap_repetitions::Integer = PRIMARY_BOOTSTRAP_REPETITIONS,
    moving_block_sessions::Integer = PRIMARY_BLOCK_SESSIONS,
    familywise_alpha::Real = PRIMARY_FAMILYWISE_ALPHA,
)
    baseline_values = _complete_values(selected_baseline)
    isnothing(baseline_values) && throw(ArgumentError("selected comparator path is incomplete"))
    sessions = length(baseline_values)
    safe_complete = ProposalCandidatePath[]
    for candidate in sort!(ProposalCandidatePath[collect(safe_candidates)...]; by = p -> p.strategy_id)
        values = _complete_values(candidate)
        isnothing(values) && continue
        length(values) == sessions || throw(DimensionMismatch("safe proposal calendars differ"))
        push!(safe_complete, candidate)
    end
    comparator_complete = ProposalCandidatePath[cash_candidate_path(sessions)]
    for candidate in sort!(ProposalCandidatePath[collect(comparator_candidates)...]; by = p -> p.strategy_id)
        values = _complete_values(candidate)
        isnothing(values) && continue
        length(values) == sessions || throw(DimensionMismatch("comparator proposal calendars differ"))
        push!(comparator_complete, candidate)
    end

    path_lookup = Dict{String,ProposalCandidatePath}()
    for path in ProposalCandidatePath[safe_complete...; comparator_complete...; selected_baseline]
        if haskey(path_lookup, path.strategy_id)
            existing = path_lookup[path.strategy_id]
            existing.net_returns == path.net_returns && existing.available == path.available ||
                error("a proposal strategy identifier maps to unequal paths")
        else
            path_lookup[path.strategy_id] = path
        end
    end
    ordered_ids = sort!(collect(keys(path_lookup)))
    id_index = Dict(id => index for (index, id) in enumerate(ordered_ids))
    values = Vector{Vector{Float64}}(undef, length(ordered_ids))
    for (index, id) in enumerate(ordered_ids)
        complete_values = _complete_values(path_lookup[id])
        isnothing(complete_values) && error("selection-aware max-t retained an incomplete path")
        values[index] = complete_values
    end
    point_ce = _ce.(values)

    repetitions = Int(bootstrap_repetitions)
    repetitions >= 100 || throw(ArgumentError("max-t bootstrap needs at least 100 repetitions"))
    block = Int(moving_block_sessions)
    block >= 1 || throw(ArgumentError("moving-block length must be positive"))
    alpha = Float64(familywise_alpha)
    0 < alpha < 1 || throw(ArgumentError("familywise alpha must lie in (0,1)"))
    seed = stable_seed(base_seed, purpose_id, scope_values...)
    rng = StableRNG(seed)
    series = hcat(values...)
    moments = _circular_block_moments(series, block)
    bootstrap_ce = Matrix{Float64}(undef, repetitions, length(ordered_ids))
    block_count = cld(sessions, block)
    final_block_sessions = rem(sessions, block)
    final_block_sessions == 0 && (final_block_sessions = block)
    for repetition in 1:repetitions
        totals = zeros(Float64, length(ordered_ids))
        total_squares = zeros(Float64, length(ordered_ids))
        for block_index in 1:block_count
            start = rand(rng, 1:sessions)
            length_value = block_index == block_count ? final_block_sessions : block
            totals .+= @view moments.sums[length_value][start, :]
            total_squares .+= @view moments.squares[length_value][start, :]
        end
        for column in eachindex(ordered_ids)
            bootstrap_ce[repetition, column] = _ce_from_moments(
                totals[column],
                total_squares[column],
                sessions,
            )
        end
    end

    pair_indices = Tuple{Int,Int}[]
    for candidate in safe_complete, comparator in comparator_complete
        candidate.strategy_id == comparator.strategy_id && continue
        pair = (id_index[candidate.strategy_id], id_index[comparator.strategy_id])
        pair in pair_indices || push!(pair_indices, pair)
    end
    sort!(pair_indices)
    pair_point = Float64[point_ce[candidate] - point_ce[baseline] for (candidate, baseline) in pair_indices]
    pair_se = Vector{Float64}(undef, length(pair_indices))
    for (pair_index, (candidate, baseline)) in enumerate(pair_indices)
        average = 0.0
        for repetition in 1:repetitions
            average += bootstrap_ce[repetition, candidate] - bootstrap_ce[repetition, baseline]
        end
        average /= repetitions
        sum_squares = 0.0
        for repetition in 1:repetitions
            difference = bootstrap_ce[repetition, candidate] -
                         bootstrap_ce[repetition, baseline] - average
            sum_squares += difference^2
        end
        pair_se[pair_index] = sqrt(sum_squares / (repetitions - 1))
    end
    max_t = zeros(Float64, repetitions)
    if !isempty(pair_indices)
        for repetition in 1:repetitions
            maximum_value = -Inf
            for (pair_index, (candidate, baseline)) in enumerate(pair_indices)
                bootstrap_delta = bootstrap_ce[repetition, candidate] -
                                  bootstrap_ce[repetition, baseline]
                scale = pair_se[pair_index]
                studentized = scale > eps(Float64) ?
                    (pair_point[pair_index] - bootstrap_delta) / scale : 0.0
                maximum_value = max(maximum_value, studentized)
            end
            max_t[repetition] = maximum_value
        end
    end
    sort!(max_t)
    critical_index = clamp(ceil(Int, (1 - alpha) * repetitions), 1, repetitions)
    critical = max_t[critical_index]

    alternatives = filter(path -> path.strategy_id != selected_baseline.strategy_id, safe_complete)
    candidate_ids = getfield.(alternatives, :strategy_id)
    selected_baseline_index = id_index[selected_baseline.strategy_id]
    selected_point = Float64[]
    selected_se = Float64[]
    for candidate in alternatives
        candidate_index = id_index[candidate.strategy_id]
        pair_index = findfirst(==((candidate_index, selected_baseline_index)), pair_indices)
        isnothing(pair_index) && error("selected safe contrast is outside simultaneous pair family")
        push!(selected_point, pair_point[pair_index])
        push!(selected_se, pair_se[pair_index])
    end
    lower = selected_point .- critical .* selected_se
    shrunk, center, latent = _family_shrink(selected_point, selected_se)
    return SimultaneousInference(
        candidate_ids,
        selected_point,
        selected_se,
        lower,
        shrunk,
        center,
        latent,
        critical,
        repetitions,
        block,
        seed,
    )
end

function forced_max_choice(candidates)
    complete = Tuple{ProposalCandidatePath,Float64}[]
    for candidate in candidates
        values = _complete_values(candidate)
        isnothing(values) || push!(complete, (candidate, _ce(values)))
    end
    isempty(complete) && return ProposalPolicyChoice(
        "innovation_safe_forced_max", String[], false, "cash_omitted", NaN, NaN,
        0, 0, "NO_COMPLETE_ACTIVE_PROPOSAL_PATH",
    )
    sort!(complete; by = row -> (-last(row), first(row).strategy_id))
    selected, score = first(complete)
    return ProposalPolicyChoice(
        "innovation_safe_forced_max", [selected.strategy_id], false, "cash_omitted",
        score, NaN, length(complete), length(complete), "",
    )
end

function equal_weight_positive_choice(candidates)
    positive = String[]
    complete_count = 0
    for candidate in sort!(ProposalCandidatePath[collect(candidates)...]; by = p -> p.strategy_id)
        values = _complete_values(candidate)
        isnothing(values) && continue
        complete_count += 1
        _ce(values) > 0 && push!(positive, candidate.strategy_id)
    end
    if isempty(positive)
        return ProposalPolicyChoice(
            "equal_weight_available_policy", ["mandatory_inactive_cash"], true,
            "mandatory_inactive_cash", 0.0, NaN, 0, complete_count, "",
        )
    end
    return ProposalPolicyChoice(
        "equal_weight_available_policy", positive, false, "mandatory_inactive_cash",
        NaN, NaN, length(positive), complete_count, "",
    )
end

end # module
