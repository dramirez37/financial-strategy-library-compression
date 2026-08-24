module ResourceOptimization

using StrategyInnovation: ExactRational, exact_rational

export ExactRetentionProblem,
       active_strategy_count,
       capacity_optimal_library,
       capacity_optimal_masks,
       capacity_value,
       discrete_capacity_profile,
       enumerate_sublibraries,
       exact_safe_feasible,
       inclusion_irreducible,
       library_cardinality,
       library_closure,
       library_frontier,
       library_generative_value,
       library_masks,
       library_module_mask,
       library_operational_value,
       library_strategy_ids,
       library_total_value,
       library_value,
       library_weight,
       minimum_cardinality_safe_compression,
       minimum_safe_cardinality_masks,
       minimum_safe_weight_masks,
       minimum_weight_safe_compression,
       optimal_admission_deletion_set,
       optimizer_breakpoints,
       penalty_breakpoints,
       penalty_probe_prices,
       penalized_optimal_library,
       penalized_optimal_masks,
       penalized_value,
       safe_feasible,
       safe_pruning_trace,
       safe_sublibraries,
       safely_deletable,
       supporting_price_interval

function _require_unique(values, label::AbstractString)
    length(Set(values)) == length(values) ||
        throw(ArgumentError("$label must be unique"))
    return nothing
end

"""
    ExactRetentionProblem

Finite exact-rational outer-library optimization problem. The inactive
strategy is implicit, has zero burden, zero operational profile, and no
modules. Active libraries are represented by bit masks over `strategy_ids`.

`values[mask + 1]` is productive value before resource penalty. The
constructor requires this table to be monotone under raw inclusion, matching
the conservative Paper 1 search domain. The compression search uses identity
module closure; a selected mask is safe relative to a source mask when both
its operational frontier and raw module union equal the source values.

Optional `operational_values` and `generative_values` keyword tables provide
an exact channel decomposition and must sum to `values`. If neither is given,
the total table is treated as operational and the generative table is zero.
"""
struct ExactRetentionProblem
    strategy_ids::Vector{String}
    weights::Vector{ExactRational}
    profiles::Matrix{ExactRational}
    module_masks::Vector{UInt64}
    module_count::Int
    operational_values::Vector{ExactRational}
    generative_values::Vector{ExactRational}
    values::Vector{ExactRational}
end

function ExactRetentionProblem(
    strategy_ids::AbstractVector,
    weights::AbstractVector,
    profiles::AbstractMatrix,
    module_masks::AbstractVector{<:Integer},
    module_count::Integer,
    values::AbstractVector,
    ;
    operational_values = nothing,
    generative_values = nothing,
)
    ids = String[string(id) for id in strategy_ids]
    _require_unique(ids, "active strategy IDs in an exact retention problem")
    active_count = length(ids)
    active_count <= 62 ||
        throw(ArgumentError("bit-mask enumeration supports at most 62 active strategies"))
    length(weights) == active_count ||
        throw(DimensionMismatch("one resource weight is required per active strategy"))
    size(profiles, 1) == active_count ||
        throw(
            DimensionMismatch(
                "one operational-profile row is required per active strategy",
            ),
        )
    size(profiles, 2) >= 1 ||
        throw(DimensionMismatch("an exact retention problem needs at least one belief"))
    length(module_masks) == active_count ||
        throw(DimensionMismatch("one module mask is required per active strategy"))
    module_count >= 1 ||
        throw(ArgumentError("an exact retention problem needs at least one module"))
    module_count <= 62 ||
        throw(ArgumentError("bit-mask module encoding supports at most 62 modules"))

    exact_weights = ExactRational[exact_rational(weight) for weight in weights]
    all(>(zero(ExactRational)), exact_weights) ||
        throw(ArgumentError("every active resource weight must be strictly positive"))
    exact_profiles = ExactRational[
        exact_rational(profiles[row, column]) for
        row in axes(profiles, 1), column in axes(profiles, 2)
    ]
    exact_module_masks = UInt64[UInt64(mask) for mask in module_masks]
    universe_mask = (UInt64(1) << Int(module_count)) - UInt64(1)
    all(mask -> (mask & ~universe_mask) == 0, exact_module_masks) ||
        throw(ArgumentError("a strategy module mask exceeds the declared universe"))

    library_count = Int(1) << active_count
    length(values) == library_count ||
        throw(
            DimensionMismatch(
                "the productive-value table needs $library_count entries",
            ),
        )
    exact_values = ExactRational[exact_rational(value) for value in values]
    if isnothing(operational_values) && isnothing(generative_values)
        exact_operational_values = copy(exact_values)
        exact_generative_values = zeros(ExactRational, library_count)
    elseif isnothing(operational_values)
        length(generative_values) == library_count ||
            throw(
                DimensionMismatch(
                    "the generative-value table needs $library_count entries",
                ),
            )
        exact_generative_values = ExactRational[
            exact_rational(value) for value in generative_values
        ]
        exact_operational_values = exact_values - exact_generative_values
    elseif isnothing(generative_values)
        length(operational_values) == library_count ||
            throw(
                DimensionMismatch(
                    "the operational-value table needs $library_count entries",
                ),
            )
        exact_operational_values = ExactRational[
            exact_rational(value) for value in operational_values
        ]
        exact_generative_values = exact_values - exact_operational_values
    else
        length(operational_values) == library_count ||
            throw(
                DimensionMismatch(
                    "the operational-value table needs $library_count entries",
                ),
            )
        length(generative_values) == library_count ||
            throw(
                DimensionMismatch(
                    "the generative-value table needs $library_count entries",
                ),
            )
        exact_operational_values = ExactRational[
            exact_rational(value) for value in operational_values
        ]
        exact_generative_values = ExactRational[
            exact_rational(value) for value in generative_values
        ]
        exact_operational_values + exact_generative_values == exact_values ||
            throw(
                ArgumentError(
                    "operational plus generative value must equal total value " *
                    "at every library",
                ),
            )
    end
    for mask in UInt64(0):UInt64(library_count - 1)
        for strategy_index in 1:active_count
            bit = UInt64(1) << (strategy_index - 1)
            iszero(mask & bit) || continue
            expanded = mask | bit
            exact_values[Int(mask) + 1] <= exact_values[Int(expanded) + 1] ||
                throw(
                    ArgumentError(
                        "productive value must be monotone under raw inclusion",
                    ),
                )
        end
    end

    return ExactRetentionProblem(
        ids,
        exact_weights,
        exact_profiles,
        exact_module_masks,
        Int(module_count),
        exact_operational_values,
        exact_generative_values,
        exact_values,
    )
end

active_strategy_count(problem::ExactRetentionProblem) =
    length(problem.strategy_ids)

function _validate_library_mask(problem::ExactRetentionProblem, mask::UInt64)
    maximum_mask = (UInt64(1) << active_strategy_count(problem)) - UInt64(1)
    (mask & ~maximum_mask) == 0 ||
        throw(ArgumentError("library mask exceeds the active strategy carrier"))
    return mask
end

library_masks(problem::ExactRetentionProblem) =
    UInt64(0):((UInt64(1) << active_strategy_count(problem)) - UInt64(1))

library_cardinality(::ExactRetentionProblem, mask::UInt64) =
    count_ones(mask) + 1

function library_strategy_ids(problem::ExactRetentionProblem, mask::UInt64)
    _validate_library_mask(problem, mask)
    ids = String["inactive"]
    for strategy_index in 1:active_strategy_count(problem)
        bit = UInt64(1) << (strategy_index - 1)
        iszero(mask & bit) || push!(ids, problem.strategy_ids[strategy_index])
    end
    return ids
end

function library_weight(problem::ExactRetentionProblem, mask::UInt64)
    _validate_library_mask(problem, mask)
    return sum(
        (
            problem.weights[strategy_index] for
            strategy_index in 1:active_strategy_count(problem) if
            !iszero(mask & (UInt64(1) << (strategy_index - 1)))
        );
        init = zero(ExactRational),
    )
end

function library_value(problem::ExactRetentionProblem, mask::UInt64)
    _validate_library_mask(problem, mask)
    return problem.values[Int(mask) + 1]
end

function library_operational_value(
    problem::ExactRetentionProblem,
    mask::UInt64,
)
    _validate_library_mask(problem, mask)
    return problem.operational_values[Int(mask) + 1]
end

function library_generative_value(
    problem::ExactRetentionProblem,
    mask::UInt64,
)
    _validate_library_mask(problem, mask)
    return problem.generative_values[Int(mask) + 1]
end

library_total_value(problem::ExactRetentionProblem, mask::UInt64) =
    library_value(problem, mask)

function library_frontier(problem::ExactRetentionProblem, mask::UInt64)
    _validate_library_mask(problem, mask)
    frontier_values = zeros(ExactRational, size(problem.profiles, 2))
    for strategy_index in 1:active_strategy_count(problem)
        bit = UInt64(1) << (strategy_index - 1)
        iszero(mask & bit) && continue
        for belief_index in axes(problem.profiles, 2)
            frontier_values[belief_index] = max(
                frontier_values[belief_index],
                problem.profiles[strategy_index, belief_index],
            )
        end
    end
    return frontier_values
end

function library_module_mask(problem::ExactRetentionProblem, mask::UInt64)
    _validate_library_mask(problem, mask)
    result = UInt64(0)
    for strategy_index in 1:active_strategy_count(problem)
        bit = UInt64(1) << (strategy_index - 1)
        iszero(mask & bit) && continue
        result |= problem.module_masks[strategy_index]
    end
    return result
end

function library_closure(problem::ExactRetentionProblem, mask::UInt64)
    module_mask = library_module_mask(problem, mask)
    return Int[
        module_index for module_index in 1:problem.module_count if
        !iszero(module_mask & (UInt64(1) << (module_index - 1)))
    ]
end

function _library_report(problem::ExactRetentionProblem, mask::UInt64)
    return (
        mask = mask,
        strategy_ids = library_strategy_ids(problem, mask),
        burden = library_weight(problem, mask),
        frontier = library_frontier(problem, mask),
        closure = library_closure(problem, mask),
        closure_mask = library_module_mask(problem, mask),
        operational_value = library_operational_value(problem, mask),
        generative_value = library_generative_value(problem, mask),
        total_value = library_total_value(problem, mask),
    )
end

function _sublibrary_masks(
    problem::ExactRetentionProblem,
    source_mask::UInt64,
)
    _validate_library_mask(problem, source_mask)
    masks = UInt64[]
    candidate = source_mask
    while true
        push!(masks, candidate)
        iszero(candidate) && break
        candidate = (candidate - UInt64(1)) & source_mask
    end
    sort!(masks)
    return masks
end

"""
    enumerate_sublibraries(problem, source_mask)

Enumerate every inactive-containing sublibrary of `source_mask`. The inactive
strategy is implicit, so mask zero is the inactive-only library.
"""
function enumerate_sublibraries(
    problem::ExactRetentionProblem,
    source_mask::UInt64 = last(library_masks(problem)),
)
    masks = _sublibrary_masks(problem, source_mask)
    libraries = [_library_report(problem, mask) for mask in masks]
    return (
        source = _library_report(problem, source_mask),
        libraries = libraries,
        burdens = [library.burden for library in libraries],
        frontiers = [library.frontier for library in libraries],
        closures = [library.closure for library in libraries],
        operational_values = [library.operational_value for library in libraries],
        generative_values = [library.generative_value for library in libraries],
        total_values = [library.total_value for library in libraries],
        certificate = (
            algorithm = :complete_submask_enumeration,
            arithmetic = ExactRational,
            source_mask = source_mask,
            enumerated_count = length(masks),
            expected_count = Int(1) << count_ones(source_mask),
            complete = length(masks) == (Int(1) << count_ones(source_mask)),
        ),
    )
end

function safe_feasible(
    problem::ExactRetentionProblem,
    source_mask::UInt64,
    candidate_mask::UInt64,
)
    _validate_library_mask(problem, source_mask)
    _validate_library_mask(problem, candidate_mask)
    (candidate_mask & ~source_mask) == 0 || return false
    return library_frontier(problem, candidate_mask) ==
           library_frontier(problem, source_mask) &&
           library_module_mask(problem, candidate_mask) ==
           library_module_mask(problem, source_mask)
end

"""
    exact_safe_feasible(problem, candidate_mask, source_mask)

Test source-relative exact frontier--closure feasibility. Argument order
matches the mathematical predicate `exact_safe_feasible(L', L)`.
"""
exact_safe_feasible(
    problem::ExactRetentionProblem,
    candidate_mask::UInt64,
    source_mask::UInt64,
) = safe_feasible(problem, source_mask, candidate_mask)

function safe_sublibraries(
    problem::ExactRetentionProblem,
    source_mask::UInt64,
)
    _validate_library_mask(problem, source_mask)
    return UInt64[
        candidate_mask for candidate_mask in library_masks(problem) if
        safe_feasible(problem, source_mask, candidate_mask)
    ]
end

function safely_deletable(
    problem::ExactRetentionProblem,
    mask::UInt64,
    strategy_index::Integer,
)
    _validate_library_mask(problem, mask)
    1 <= strategy_index <= active_strategy_count(problem) ||
        throw(BoundsError(problem.strategy_ids, strategy_index))
    bit = UInt64(1) << (Int(strategy_index) - 1)
    iszero(mask & bit) && return false
    return safe_feasible(problem, mask, mask & ~bit)
end

function safe_pruning_trace(
    problem::ExactRetentionProblem,
    source_mask::UInt64,
    deletion_order::AbstractVector{<:Integer},
)
    _validate_library_mask(problem, source_mask)
    order = Int[Int(index) for index in deletion_order]
    _require_unique(order, "strategy indices in a deletion order")
    all(index -> 1 <= index <= active_strategy_count(problem), order) ||
        throw(ArgumentError("a deletion order contains an invalid strategy index"))

    current = source_mask
    masks = UInt64[current]
    deletions = Int[]
    changed = true
    while changed
        changed = false
        for strategy_index in order
            bit = UInt64(1) << (strategy_index - 1)
            iszero(current & bit) && continue
            safely_deletable(problem, current, strategy_index) || continue
            current &= ~bit
            push!(deletions, strategy_index)
            push!(masks, current)
            changed = true
        end
    end
    return (masks = masks, deletions = deletions, endpoint = current)
end

function inclusion_irreducible(
    problem::ExactRetentionProblem,
    mask::UInt64,
)
    _validate_library_mask(problem, mask)
    return all(
        !safely_deletable(problem, mask, strategy_index) for
        strategy_index in 1:active_strategy_count(problem)
    )
end

function minimum_safe_cardinality_masks(
    problem::ExactRetentionProblem,
    source_mask::UInt64,
)
    feasible = safe_sublibraries(problem, source_mask)
    minimum_cardinality = minimum(
        library_cardinality(problem, mask) for mask in feasible
    )
    return UInt64[
        mask for mask in feasible if
        library_cardinality(problem, mask) == minimum_cardinality
    ]
end

function minimum_safe_weight_masks(
    problem::ExactRetentionProblem,
    source_mask::UInt64,
)
    feasible = safe_sublibraries(problem, source_mask)
    minimum_weight = minimum(library_weight(problem, mask) for mask in feasible)
    return UInt64[
        mask for mask in feasible if
        library_weight(problem, mask) == minimum_weight
    ]
end

function _optimization_result(
    problem::ExactRetentionProblem,
    optimal_objective,
    optimal_masks::Vector{UInt64},
    certificate,
)
    libraries = [_library_report(problem, mask) for mask in optimal_masks]
    return (
        optimal_objective = optimal_objective,
        optimal_libraries = libraries,
        burdens = [library.burden for library in libraries],
        frontiers = [library.frontier for library in libraries],
        closures = [library.closure for library in libraries],
        operational_values = [library.operational_value for library in libraries],
        generative_values = [library.generative_value for library in libraries],
        total_values = [library.total_value for library in libraries],
        certificate = certificate,
    )
end

function _require_safe_productive_value_preservation(
    problem::ExactRetentionProblem,
    source_mask::UInt64,
    feasible_masks::Vector{UInt64},
)
    source_value = library_total_value(problem, source_mask)
    all(
        library_total_value(problem, mask) == source_value for
        mask in feasible_masks
    ) ||
        throw(
            ArgumentError(
                "the productive-value table does not factor through exact " *
                "frontier--closure safety for this source library",
            ),
        )
    return source_value
end

function _safe_compression_result(
    problem::ExactRetentionProblem,
    source_mask::UInt64,
    objective::Function,
    objective_name::Symbol,
)
    submasks = _sublibrary_masks(problem, source_mask)
    feasible_masks = UInt64[
        mask for mask in submasks if
        exact_safe_feasible(problem, mask, source_mask)
    ]
    source_value = _require_safe_productive_value_preservation(
        problem,
        source_mask,
        feasible_masks,
    )
    best = minimum(objective(mask) for mask in feasible_masks)
    optimal_masks = UInt64[
        mask for mask in feasible_masks if objective(mask) == best
    ]
    objective_table = [
        (
            mask = mask,
            feasible = mask in feasible_masks,
            objective = mask in feasible_masks ? objective(mask) : nothing,
        ) for mask in submasks
    ]
    certificate = (
        algorithm = :exhaustive_enumeration,
        arithmetic = ExactRational,
        problem = objective_name,
        source_mask = source_mask,
        enumerated_masks = submasks,
        feasible_masks = feasible_masks,
        optimal_masks = optimal_masks,
        objective_table = objective_table,
        source_is_feasible = source_mask in feasible_masks,
        all_optima_feasible = all(mask -> mask in feasible_masks, optimal_masks),
        objective_attained = !isempty(optimal_masks),
        ties_complete = all(
            (mask in optimal_masks) ==
            (mask in feasible_masks && objective(mask) == best) for
            mask in submasks
        ),
        productive_value_preserved = all(
            library_total_value(problem, mask) == source_value for
            mask in feasible_masks
        ),
    )
    return _optimization_result(problem, best, optimal_masks, certificate)
end

"""
    minimum_weight_safe_compression(problem, source_mask)

Return the exact minimum burden and every globally minimum exact-safe
sublibrary, together with complete enumeration and value-preservation
certificates.
"""
minimum_weight_safe_compression(
    problem::ExactRetentionProblem,
    source_mask::UInt64 = last(library_masks(problem)),
) = _safe_compression_result(
    problem,
    source_mask,
    mask -> library_weight(problem, mask),
    :minimum_weight_safe_compression,
)

"""
    minimum_cardinality_safe_compression(problem, source_mask)

Return every exact-safe sublibrary with minimum library cardinality.
The reported objective includes the mandatory implicit inactive strategy,
matching `library_cardinality` and the mathematical admissible-library size.
"""
minimum_cardinality_safe_compression(
    problem::ExactRetentionProblem,
    source_mask::UInt64 = last(library_masks(problem)),
) = _safe_compression_result(
    problem,
    source_mask,
    mask -> library_cardinality(problem, mask),
    :minimum_cardinality_safe_compression,
)

function capacity_optimal_masks(
    problem::ExactRetentionProblem,
    capacity,
)
    exact_capacity = exact_rational(capacity)
    exact_capacity >= 0 ||
        throw(ArgumentError("resource capacity must be nonnegative"))
    feasible = UInt64[
        mask for mask in library_masks(problem) if
        library_weight(problem, mask) <= exact_capacity
    ]
    best = maximum(library_value(problem, mask) for mask in feasible)
    return UInt64[
        mask for mask in feasible if library_value(problem, mask) == best
    ]
end

capacity_value(problem::ExactRetentionProblem, capacity) =
    library_value(problem, first(capacity_optimal_masks(problem, capacity)))

"""
    capacity_optimal_library(problem, capacity, belief=nothing, parameters=nothing)

Exhaust the eligible finite catalog and return the capacity value and the
complete optimizer correspondence. `belief` and `parameters` are recorded as
context; the supplied problem already contains the corresponding exact value
tables.
"""
function capacity_optimal_library(
    problem::ExactRetentionProblem,
    capacity,
    belief = nothing,
    parameters = nothing,
)
    exact_capacity = exact_rational(capacity)
    exact_capacity >= 0 ||
        throw(ArgumentError("resource capacity must be nonnegative"))
    masks = collect(library_masks(problem))
    feasible_masks = UInt64[
        mask for mask in masks if
        library_weight(problem, mask) <= exact_capacity
    ]
    best = maximum(library_total_value(problem, mask) for mask in feasible_masks)
    optimal_masks = UInt64[
        mask for mask in feasible_masks if
        library_total_value(problem, mask) == best
    ]
    objective_table = [
        (
            mask = mask,
            burden = library_weight(problem, mask),
            feasible = mask in feasible_masks,
            total_value = library_total_value(problem, mask),
        ) for mask in masks
    ]
    certificate = (
        algorithm = :exhaustive_enumeration,
        arithmetic = ExactRational,
        problem = :capacity_optimal_library,
        capacity = exact_capacity,
        belief = belief,
        parameters = parameters,
        enumerated_masks = masks,
        feasible_masks = feasible_masks,
        optimal_masks = optimal_masks,
        objective_table = objective_table,
        inactive_library_feasible = UInt64(0) in feasible_masks,
        all_optima_feasible = all(mask -> mask in feasible_masks, optimal_masks),
        objective_attained = !isempty(optimal_masks),
        ties_complete = all(
            (mask in optimal_masks) ==
            (mask in feasible_masks && library_total_value(problem, mask) == best) for
            mask in masks
        ),
    )
    return _optimization_result(problem, best, optimal_masks, certificate)
end

function penalized_optimal_masks(
    problem::ExactRetentionProblem,
    resource_price,
)
    price = exact_rational(resource_price)
    price >= 0 ||
        throw(ArgumentError("resource price must be nonnegative"))
    objectives = ExactRational[
        library_value(problem, mask) - price * library_weight(problem, mask) for
        mask in library_masks(problem)
    ]
    best = maximum(objectives)
    return UInt64[
        mask for mask in library_masks(problem) if
        objectives[Int(mask) + 1] == best
    ]
end

function penalized_value(
    problem::ExactRetentionProblem,
    resource_price,
)
    price = exact_rational(resource_price)
    optimizer = first(penalized_optimal_masks(problem, price))
    return library_value(problem, optimizer) -
           price * library_weight(problem, optimizer)
end

"""
    penalized_optimal_library(problem, resource_price, belief=nothing, parameters=nothing)

Return the exact penalized envelope value and every optimal library at a
nonnegative rational resource price.
"""
function penalized_optimal_library(
    problem::ExactRetentionProblem,
    resource_price,
    belief = nothing,
    parameters = nothing,
)
    price = exact_rational(resource_price)
    price >= 0 ||
        throw(ArgumentError("resource price must be nonnegative"))
    masks = collect(library_masks(problem))
    objective(mask) =
        library_total_value(problem, mask) -
        price * library_weight(problem, mask)
    best = maximum(objective(mask) for mask in masks)
    optimal_masks = UInt64[
        mask for mask in masks if objective(mask) == best
    ]
    objective_table = [
        (
            mask = mask,
            burden = library_weight(problem, mask),
            total_value = library_total_value(problem, mask),
            penalized_value = objective(mask),
        ) for mask in masks
    ]
    certificate = (
        algorithm = :exhaustive_enumeration,
        arithmetic = ExactRational,
        problem = :penalized_optimal_library,
        resource_price = price,
        belief = belief,
        parameters = parameters,
        enumerated_masks = masks,
        feasible_masks = masks,
        optimal_masks = optimal_masks,
        objective_table = objective_table,
        all_optima_feasible = true,
        objective_attained = !isempty(optimal_masks),
        ties_complete = all(
            (mask in optimal_masks) == (objective(mask) == best) for mask in masks
        ),
    )
    return _optimization_result(problem, best, optimal_masks, certificate)
end

"""
    supporting_price_interval(problem, mask)

Return the closed interval of nonnegative prices for which `mask` is
penalized-optimal. The upper endpoint is `nothing` for an unbounded interval;
`nothing` for the entire return value means that no supporting price exists.
"""
function supporting_price_interval(
    problem::ExactRetentionProblem,
    mask::UInt64,
)
    _validate_library_mask(problem, mask)
    lower = zero(ExactRational)
    upper::Union{Nothing,ExactRational} = nothing
    own_weight = library_weight(problem, mask)
    own_value = library_value(problem, mask)

    for comparison in library_masks(problem)
        comparison == mask && continue
        weight_difference =
            library_weight(problem, comparison) - own_weight
        value_difference =
            library_value(problem, comparison) - own_value
        if iszero(weight_difference)
            value_difference <= 0 || return nothing
        elseif weight_difference > 0
            lower = max(lower, value_difference / weight_difference)
        else
            candidate_upper = value_difference / weight_difference
            upper = isnothing(upper) ? candidate_upper :
                    min(upper, candidate_upper)
        end
    end

    lower = max(lower, zero(ExactRational))
    if !isnothing(upper) && upper < lower
        return nothing
    end
    if !isnothing(upper) && upper < 0
        return nothing
    end
    return (lower = lower, upper = upper)
end

function penalty_breakpoints(problem::ExactRetentionProblem)
    breakpoints = ExactRational[zero(ExactRational)]
    masks = collect(library_masks(problem))
    for left_index in eachindex(masks)
        left = masks[left_index]
        for right_index in (left_index + 1):length(masks)
            right = masks[right_index]
            left_weight = library_weight(problem, left)
            right_weight = library_weight(problem, right)
            left_weight == right_weight && continue
            price =
                (library_value(problem, left) - library_value(problem, right)) /
                (left_weight - right_weight)
            price >= 0 && push!(breakpoints, price)
        end
    end
    sort!(unique!(breakpoints))
    return breakpoints
end

function penalty_probe_prices(problem::ExactRetentionProblem)
    breakpoints = penalty_breakpoints(problem)
    probes = copy(breakpoints)
    for index in 1:(length(breakpoints) - 1)
        push!(probes, (breakpoints[index] + breakpoints[index + 1]) / 2)
    end
    push!(probes, last(breakpoints) + 1)
    sort!(unique!(probes))
    return probes
end

"""
    optimizer_breakpoints(problem, belief=nothing, parameters=nothing)

Filter the pairwise switching-price candidates to the actual nonnegative
penalized-envelope breakpoints at which globally optimal libraries have
unequal burdens. Every breakpoint entry retains the full optimizer
correspondence and its exhaustive certificate.
"""
function optimizer_breakpoints(
    problem::ExactRetentionProblem,
    belief = nothing,
    parameters = nothing,
)
    candidates = penalty_breakpoints(problem)
    breakpoint_results = NamedTuple[]
    for price in candidates
        result = penalized_optimal_library(
            problem,
            price,
            belief,
            parameters,
        )
        length(unique(result.burdens)) >= 2 || continue
        push!(breakpoint_results, (; resource_price = price, result...))
    end
    prices = ExactRational[
        result.resource_price for result in breakpoint_results
    ]
    return (
        prices = prices,
        breakpoints = breakpoint_results,
        burdens = [result.burdens for result in breakpoint_results],
        frontiers = [result.frontiers for result in breakpoint_results],
        closures = [result.closures for result in breakpoint_results],
        operational_values = [
            result.operational_values for result in breakpoint_results
        ],
        generative_values = [
            result.generative_values for result in breakpoint_results
        ],
        total_values = [result.total_values for result in breakpoint_results],
        certificate = (
            algorithm = :pairwise_candidates_then_global_envelope_filter,
            arithmetic = ExactRational,
            belief = belief,
            parameters = parameters,
            candidate_prices = candidates,
            actual_prices = prices,
            all_prices_nonnegative = all(>=(zero(ExactRational)), prices),
            every_breakpoint_has_unequal_optimal_burdens = all(
                length(unique(result.burdens)) >= 2 for
                result in breakpoint_results
            ),
            every_report_is_globally_certified = all(
                result.certificate.ties_complete for result in breakpoint_results
            ),
        ),
    )
end

function _candidate_index(
    problem::ExactRetentionProblem,
    candidate::Integer,
)
    index = Int(candidate)
    1 <= index <= active_strategy_count(problem) ||
        throw(BoundsError(problem.strategy_ids, index))
    return index
end

function _candidate_index(
    problem::ExactRetentionProblem,
    candidate::AbstractString,
)
    index = findfirst(==(String(candidate)), problem.strategy_ids)
    isnothing(index) &&
        throw(ArgumentError("unknown candidate strategy ID: $(repr(candidate))"))
    return index
end

function _deleted_strategy_ids(
    problem::ExactRetentionProblem,
    deletion_mask::UInt64,
)
    return String[
        problem.strategy_ids[index] for
        index in 1:active_strategy_count(problem) if
        !iszero(deletion_mask & (UInt64(1) << (index - 1)))
    ]
end

"""
    optimal_admission_deletion_set(problem, current_mask, candidate, capacity,
                                   belief=nothing, parameters=nothing)

Enumerate every incumbent deletion set that makes an already outer-eligible
candidate capacity-feasible, maximize exact post-replacement productive value,
and return every optimal deletion set. `candidate` may be a one-based active
strategy index or its string ID.
"""
function optimal_admission_deletion_set(
    problem::ExactRetentionProblem,
    current_mask::UInt64,
    candidate,
    capacity,
    belief = nothing,
    parameters = nothing,
)
    _validate_library_mask(problem, current_mask)
    candidate_index = _candidate_index(problem, candidate)
    candidate_bit = UInt64(1) << (candidate_index - 1)
    iszero(current_mask & candidate_bit) ||
        throw(ArgumentError("the admission candidate is already in the library"))
    exact_capacity = exact_rational(capacity)
    exact_capacity >= 0 ||
        throw(ArgumentError("resource capacity must be nonnegative"))

    augmented_mask = current_mask | candidate_bit
    deletion_masks = _sublibrary_masks(problem, current_mask)
    rows = [
        let final_mask = (current_mask & ~deletion_mask) | candidate_bit
            (
                deletion_mask = deletion_mask,
                deleted_strategy_ids =
                    _deleted_strategy_ids(problem, deletion_mask),
                released_burden = library_weight(problem, deletion_mask),
                final_mask = final_mask,
                final_burden = library_weight(problem, final_mask),
                feasible = library_weight(problem, final_mask) <= exact_capacity,
                operational_value =
                    library_operational_value(problem, final_mask),
                generative_value =
                    library_generative_value(problem, final_mask),
                total_value = library_total_value(problem, final_mask),
                operational_displacement_loss =
                    library_operational_value(problem, augmented_mask) -
                    library_operational_value(problem, final_mask),
                generative_displacement_loss =
                    library_generative_value(problem, augmented_mask) -
                    library_generative_value(problem, final_mask),
                total_displacement_loss =
                    library_total_value(problem, augmented_mask) -
                    library_total_value(problem, final_mask),
            )
        end for deletion_mask in deletion_masks
    ]
    feasible_rows = [row for row in rows if row.feasible]
    deficit = max(
        zero(ExactRational),
        library_weight(problem, augmented_mask) - exact_capacity,
    )

    base_certificate = (
        algorithm = :exhaustive_deletion_set_enumeration,
        arithmetic = ExactRational,
        problem = :optimal_admission_deletion_set,
        belief = belief,
        parameters = parameters,
        current_mask = current_mask,
        candidate_index = candidate_index,
        candidate_id = problem.strategy_ids[candidate_index],
        capacity = exact_capacity,
        capacity_deficit = deficit,
        enumerated_deletion_masks = deletion_masks,
        objective_table = rows,
        current_library_feasible =
            library_weight(problem, current_mask) <= exact_capacity,
        feasibility_matches_release_certificate = all(
            row.feasible == (row.released_burden >= deficit) for row in rows
        ),
    )

    if isempty(feasible_rows)
        certificate = (;
            base_certificate...,
            feasible_deletion_masks = UInt64[],
            optimal_deletion_masks = UInt64[],
            all_optima_feasible = true,
            objective_attained = false,
            ties_complete = true,
        )
        return (
            optimal_objective = nothing,
            optimal_libraries = NamedTuple[],
            optimal_deletion_sets = NamedTuple[],
            burdens = ExactRational[],
            frontiers = Vector{ExactRational}[],
            closures = Vector{Int}[],
            operational_values = ExactRational[],
            generative_values = ExactRational[],
            total_values = ExactRational[],
            capacity_deficit = deficit,
            gross_operational_gain =
                library_operational_value(problem, augmented_mask) -
                library_operational_value(problem, current_mask),
            gross_generative_gain =
                library_generative_value(problem, augmented_mask) -
                library_generative_value(problem, current_mask),
            gross_candidate_gain =
                library_total_value(problem, augmented_mask) -
                library_total_value(problem, current_mask),
            minimum_displacement_loss = nothing,
            net_admission_value = nothing,
            certificate = certificate,
        )
    end

    best = maximum(row.total_value for row in feasible_rows)
    optimal_rows = [row for row in feasible_rows if row.total_value == best]
    optimal_masks = UInt64[row.final_mask for row in optimal_rows]
    optimal_deletion_masks = UInt64[
        row.deletion_mask for row in optimal_rows
    ]
    certificate = (;
        base_certificate...,
        feasible_deletion_masks = UInt64[
            row.deletion_mask for row in feasible_rows
        ],
        optimal_deletion_masks = optimal_deletion_masks,
        all_optima_feasible = all(row.feasible for row in optimal_rows),
        objective_attained = true,
        ties_complete = all(
            (row.deletion_mask in optimal_deletion_masks) ==
            (row.feasible && row.total_value == best) for row in rows
        ),
    )
    result = _optimization_result(
        problem,
        best,
        optimal_masks,
        certificate,
    )
    return (;
        result...,
        optimal_deletion_sets = optimal_rows,
        capacity_deficit = deficit,
        gross_operational_gain =
            library_operational_value(problem, augmented_mask) -
            library_operational_value(problem, current_mask),
        gross_generative_gain =
            library_generative_value(problem, augmented_mask) -
            library_generative_value(problem, current_mask),
        gross_candidate_gain =
            library_total_value(problem, augmented_mask) -
            library_total_value(problem, current_mask),
        minimum_displacement_loss =
            library_total_value(problem, augmented_mask) - best,
        net_admission_value = best - library_total_value(problem, current_mask),
    )
end

function discrete_capacity_profile(
    problem::ExactRetentionProblem,
    maximum_capacity::Integer,
)
    maximum_capacity >= 0 ||
        throw(ArgumentError("maximum capacity must be nonnegative"))
    budgets = ExactRational[exact_rational(value) for value in 0:maximum_capacity]
    values = ExactRational[capacity_value(problem, budget) for budget in budgets]
    marginals = ExactRational[
        values[index] - values[index - 1] for index in 2:length(values)
    ]
    return (budgets = budgets, values = values, marginals = marginals)
end

end
