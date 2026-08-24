function _validate_value_library(
    process::DiscountedResearchProcess,
    catalog::StrategyCatalog,
    belief::Belief,
    library::RawLibrary,
)
    process.beliefs == catalog.beliefs || throw(
        ArgumentError("the process and catalog must use the same belief space"),
    )
    validate_library(catalog, library)
    belief_index(process.beliefs, belief)
    frontier_type = eltype(operational_frontier(catalog, library).values)
    process_type = eltype(process.continue_rewards)
    frontier_type === process_type || throw(
        ArgumentError("the process and catalog must use the same arithmetic mode"),
    )
    return nothing
end

function _discounted_profile_values(
    process::DiscountedResearchProcess{B,P,M,T},
    profile::OperationalProfile{B,T},
    horizon::Integer,
) where {B,P,M,T}
    horizon >= 0 || throw(ArgumentError("horizon must be nonnegative"))
    profile.space == process.beliefs || throw(
        ArgumentError("the payoff profile and process must use the same belief space"),
    )
    belief_count = length(process.beliefs)
    values = zeros(T, belief_count)
    next_values = similar(values)
    for _ in 1:horizon
        for current in 1:belief_count
            continuation = sum(
                process.continue_transition[current, next] * values[next]
                for next in 1:belief_count;
                init = zero(T),
            )
            next_values[current] = profile.values[current] + process.discount * continuation
        end
        values, next_values = next_values, values
    end
    return values
end

"""
    passive_value(process, catalog, horizon, belief, library)

Exact frozen-library value `P_n(b,L)`.  The recursion earns the current
operational frontier and then follows the process belief kernel, while the
raw library is held fixed.  This is the Julia counterpart of Lean
`ValueDecomposition.passiveValue`.
"""
function passive_value(
    process::DiscountedResearchProcess,
    catalog::StrategyCatalog,
    horizon::Integer,
    belief::Belief,
    library::RawLibrary,
)
    _validate_value_library(process, catalog, belief, library)
    values = _discounted_profile_values(
        process,
        operational_frontier(catalog, library),
        horizon,
    )
    return values[belief_index(process.beliefs, belief)]
end

"""
    full_value(process, catalog, closure, horizon, belief, library)

Optimized finite-horizon value `U_n(b,L)` at the library's compressed state.
The compressed state must be represented in `process.compressed_states`.
This instantiates Lean `ValueDecomposition.fullValue` with the package's
frontier--closure compression map.
"""
function full_value(
    process::DiscountedResearchProcess,
    catalog::StrategyCatalog,
    closure::GenerativeClosure,
    horizon::Integer,
    belief::Belief,
    library::RawLibrary,
)
    _validate_value_library(process, catalog, belief, library)
    state = compressed_state(catalog, closure, library)
    state_position = findfirst(isequal(state), process.compressed_states)
    isnothing(state_position) && throw(
        ArgumentError("the compressed library state is absent from the process"),
    )
    values = finite_horizon_value(process, horizon)
    return values[belief_index(process.beliefs, belief), state_position]
end

"""Return the finite-horizon research-option premium `Ω_n = U_n - P_n`."""
function research_option_premium(
    process::DiscountedResearchProcess,
    catalog::StrategyCatalog,
    closure::GenerativeClosure,
    horizon::Integer,
    belief::Belief,
    library::RawLibrary,
)
    return full_value(process, catalog, closure, horizon, belief, library) -
           passive_value(process, catalog, horizon, belief, library)
end

"""Return total insertion value `I_n(s|b,L)`."""
function total_innovation(
    process::DiscountedResearchProcess,
    catalog::StrategyCatalog,
    closure::GenerativeClosure,
    horizon::Integer,
    belief::Belief,
    library::RawLibrary,
    strategy_id::StrategyId,
)
    inserted = insert_strategy(catalog, library, strategy_id)
    return full_value(process, catalog, closure, horizon, belief, inserted) -
           full_value(process, catalog, closure, horizon, belief, library)
end

"""Return passive operational insertion value `Δ^op_n(s|b,L)`."""
function operational_innovation(
    process::DiscountedResearchProcess,
    catalog::StrategyCatalog,
    horizon::Integer,
    belief::Belief,
    library::RawLibrary,
    strategy_id::StrategyId,
)
    inserted = insert_strategy(catalog, library, strategy_id)
    return passive_value(process, catalog, horizon, belief, inserted) -
           passive_value(process, catalog, horizon, belief, library)
end

"""Return generative insertion value `Δ^gen_n(s|b,L)`."""
function generative_innovation(
    process::DiscountedResearchProcess,
    catalog::StrategyCatalog,
    closure::GenerativeClosure,
    horizon::Integer,
    belief::Belief,
    library::RawLibrary,
    strategy_id::StrategyId,
)
    inserted = insert_strategy(catalog, library, strategy_id)
    return research_option_premium(
        process,
        catalog,
        closure,
        horizon,
        belief,
        inserted,
    ) - research_option_premium(
        process,
        catalog,
        closure,
        horizon,
        belief,
        library,
    )
end

"""
    generative_strategy_lower_bound(
        discount,
        duration,
        research_cost,
        admission_probability,
        survival_factor,
        expected_completion_gain;
        operating_adjustment = zero(discount),
    )

Evaluate the exact T6 scalar guarantee

`max(-κ + Aop + β^d * π * ρ^d * E[G(B_d)], 0)`.

`operating_adjustment` is the unified-timing difference between incumbent
rewards plus frozen passive continuation during research and the passive value
of not starting the project.  It is zero only when those baselines match.
"""
function generative_strategy_lower_bound(
    discount::T,
    duration::Integer,
    research_cost::T,
    admission_probability::T,
    survival_factor::T,
    expected_completion_gain::T;
    operating_adjustment::T = zero(T),
) where {T<:Real}
    duration > 0 || throw(ArgumentError("duration must be positive"))
    zero(T) <= discount <= one(T) ||
        throw(ArgumentError("discount must lie in [0, 1]"))
    research_cost >= zero(T) ||
        throw(ArgumentError("research cost must be nonnegative"))
    zero(T) <= admission_probability <= one(T) ||
        throw(ArgumentError("admission probability must lie in [0, 1]"))
    zero(T) <= survival_factor <= one(T) ||
        throw(ArgumentError("survival factor must lie in [0, 1]"))
    expected_completion_gain >= zero(T) ||
        throw(ArgumentError("expected completion gain must be nonnegative"))
    net_gain =
        -research_cost + operating_adjustment +
        discount^duration * admission_probability * survival_factor^duration *
        expected_completion_gain
    return max(net_gain, zero(T))
end

"""
    generative_lower_bound_fixture()

Small exact-rational T6 carrier fixture.  A one-period bridge has zero current
frontier, zero cost, unit admission and survival, and completion gain two under
discount one half.  Its occupation-weighted gain is two and its lower bound is
exactly one.
"""
function generative_lower_bound_fixture()
    discount = ExactRational(1 // 2)
    duration = 1
    research_cost = zero(ExactRational)
    admission_probability = one(ExactRational)
    survival_factor = one(ExactRational)
    occupation_weights = ExactRational[1]
    completion_gains = ExactRational[2]
    expected_completion_gain = sum(
        occupation_weights .* completion_gains;
        init = zero(ExactRational),
    )
    operating_adjustment = zero(ExactRational)
    lower_bound = generative_strategy_lower_bound(
        discount,
        duration,
        research_cost,
        admission_probability,
        survival_factor,
        expected_completion_gain;
        operating_adjustment,
    )
    return (;
        discount,
        duration,
        research_cost,
        admission_probability,
        survival_factor,
        occupation_weights,
        completion_gains,
        expected_completion_gain,
        operating_adjustment,
        lower_bound,
    )
end

"""
    closure_increment(value, frontier, closure1, closure0)

Return `value(frontier, closure1) - value(frontier, closure0)`. This is the
executable counterpart of Lean T7 `closureIncrement`.
"""
closure_increment(value, frontier, closure1, closure0) =
    value(frontier, closure1) - value(frontier, closure0)

"""
    interaction_cross_difference(value, frontier1, frontier0, closure1, closure0)

Return the frontier--closure cross difference

`[V(frontier1,closure1)-V(frontier1,closure0)] -
 [V(frontier0,closure1)-V(frontier0,closure0)]`.

Negative values indicate substitution, positive values complementarity, and
zero values separability on the displayed rectangle.
"""
interaction_cross_difference(value, frontier1, frontier0, closure1, closure0) =
    closure_increment(value, frontier1, closure1, closure0) -
    closure_increment(value, frontier0, closure1, closure0)

function _one_project_premium(
    discount::T,
    frontier::T,
    success::T,
    cost::T,
    candidate::T,
) where {T<:Real}
    return max(
        zero(T),
        discount * success * max(candidate - frontier, zero(T)) - cost,
    )
end

"""
    frontier_closure_interaction_surface(
        frontiers,
        candidate_values,
        old_successes,
        added_successes,
        old_costs,
        added_costs;
        discount,
        include_equal_frontiers=false,
    )

Map the exact one-period T7 interaction over a finite parameter grid. The
closure-poor menu contains an old project; closure enrichment adds a second
project. Both projects have fixed candidate quality, success, and cost across
the two frontiers:

`premium(F; π,κ,y) = max(0, β*π*max(y-F,0)-κ)`.

The optimized full value is the frozen frontier plus the best available
premium. Returned rows report both closure increments, their cross difference,
and the sign classification. Positive rows are the project-switching boundary
showing why primitive frontier independence alone does not prove T7.
"""
function frontier_closure_interaction_surface(
    frontiers::AbstractVector{T},
    candidate_values::AbstractVector{T},
    old_successes::AbstractVector{T},
    added_successes::AbstractVector{T},
    old_costs::AbstractVector{T},
    added_costs::AbstractVector{T};
    discount::T,
    include_equal_frontiers::Bool = false,
) where {T<:Real}
    zero(T) <= discount <= one(T) ||
        throw(ArgumentError("discount must lie in [0, 1]"))
    isempty(frontiers) && throw(ArgumentError("frontier grid must be nonempty"))
    isempty(candidate_values) &&
        throw(ArgumentError("candidate grid must be nonempty"))
    all(>=(zero(T)), frontiers) ||
        throw(ArgumentError("frontiers must be nonnegative"))
    all(>=(zero(T)), candidate_values) ||
        throw(ArgumentError("candidate values must be nonnegative"))
    all(probability -> zero(T) <= probability <= one(T), old_successes) ||
        throw(ArgumentError("old success probabilities must lie in [0, 1]"))
    all(probability -> zero(T) <= probability <= one(T), added_successes) ||
        throw(ArgumentError("added success probabilities must lie in [0, 1]"))
    all(>=(zero(T)), old_costs) ||
        throw(ArgumentError("old costs must be nonnegative"))
    all(>=(zero(T)), added_costs) ||
        throw(ArgumentError("added costs must be nonnegative"))

    rows = NamedTuple[]
    for frontier0 in frontiers, frontier1 in frontiers
        frontier0 <= frontier1 || continue
        !include_equal_frontiers && frontier0 == frontier1 && continue
        for candidate in candidate_values,
            old_success in old_successes,
            added_success in added_successes,
            old_cost in old_costs,
            added_cost in added_costs

            old0 = _one_project_premium(
                discount,
                frontier0,
                old_success,
                old_cost,
                candidate,
            )
            old1 = _one_project_premium(
                discount,
                frontier1,
                old_success,
                old_cost,
                candidate,
            )
            added0 = _one_project_premium(
                discount,
                frontier0,
                added_success,
                added_cost,
                candidate,
            )
            added1 = _one_project_premium(
                discount,
                frontier1,
                added_success,
                added_cost,
                candidate,
            )
            increment0 = max(old0, added0) - old0
            increment1 = max(old1, added1) - old1
            interaction = increment1 - increment0
            classification = interaction < zero(T) ? :substitutes :
                             interaction > zero(T) ? :complements : :separable
            push!(
                rows,
                (;
                    discount,
                    frontier0,
                    frontier1,
                    candidate,
                    old_success,
                    added_success,
                    old_cost,
                    added_cost,
                    old_premium0 = old0,
                    old_premium1 = old1,
                    added_premium0 = added0,
                    added_premium1 = added1,
                    closure_increment0 = increment0,
                    closure_increment1 = increment1,
                    interaction,
                    classification,
                ),
            )
        end
    end
    return rows
end

"""
    frontier_gap(catalog, library, strategy_id[, belief])

The candidate's positive pointwise gap `max(j_s-F_L,0)`, either as a complete
profile or at one belief.  This mirrors Lean `InnovationEquation.frontierGap`.
"""
function frontier_gap(
    catalog::StrategyCatalog{S,B,M,T},
    library::RawLibrary{S},
    strategy_id::StrategyId{S},
) where {S,B,M,T}
    validate_library(catalog, library)
    candidate = operational_profile(catalog, strategy_id)
    current = operational_frontier(catalog, library)
    values = T[
        max(candidate.values[index] - current.values[index], zero(T))
        for index in eachindex(candidate.values)
    ]
    return OperationalProfile{B,T}(catalog.beliefs, Tuple(values))
end

frontier_gap(
    catalog::StrategyCatalog,
    library::RawLibrary,
    strategy_id::StrategyId,
    belief::Belief,
) = frontier_gap(catalog, library, strategy_id)[belief]

"""
    discounted_gap_sum(process, catalog, horizon, belief, library, strategy_id)

Exact finite recursion `G_n(b;L,s)` for discounted positive frontier gaps.
This is the Julia counterpart of Lean `InnovationEquation.discountedGapSum`.
"""
function discounted_gap_sum(
    process::DiscountedResearchProcess,
    catalog::StrategyCatalog,
    horizon::Integer,
    belief::Belief,
    library::RawLibrary,
    strategy_id::StrategyId,
)
    _validate_value_library(process, catalog, belief, library)
    values = _discounted_profile_values(
        process,
        frontier_gap(catalog, library, strategy_id),
        horizon,
    )
    return values[belief_index(process.beliefs, belief)]
end

"""Alias matching Lean `passiveOperationalInnovation`."""
passive_operational_innovation(
    process::DiscountedResearchProcess,
    catalog::StrategyCatalog,
    horizon::Integer,
    belief::Belief,
    library::RawLibrary,
    strategy_id::StrategyId,
) = operational_innovation(process, catalog, horizon, belief, library, strategy_id)

"""
    discounted_belief_occupancy(process, horizon, belief)

Return the exact finite weights `sum_{t<n} β^t Pr_b(B_t=b')` in process belief
order.  This expands, but does not alter, the finite `discountedGapSum`
recursion and is used for figure diagnostics.
"""
function discounted_belief_occupancy(
    process::DiscountedResearchProcess{B,P,M,T},
    horizon::Integer,
    belief::Belief,
) where {B,P,M,T}
    horizon >= 0 || throw(ArgumentError("horizon must be nonnegative"))
    belief_count = length(process.beliefs)
    initial = belief_index(process.beliefs, belief)
    distribution = zeros(T, belief_count)
    distribution[initial] = one(T)
    next_distribution = similar(distribution)
    occupancy = zeros(T, belief_count)
    discount_power = one(T)
    for _ in 1:horizon
        occupancy .+= discount_power .* distribution
        for next in 1:belief_count
            next_distribution[next] = sum(
                distribution[current] * process.continue_transition[current, next]
                for current in 1:belief_count;
                init = zero(T),
            )
        end
        distribution, next_distribution = next_distribution, distribution
        discount_power *= process.discount
    end
    return occupancy
end
