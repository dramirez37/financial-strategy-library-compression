module SafeCompressionComplexity

using StrategyInnovation: ExactRational, exact_rational

export IdentitySafeCover,
       SafeCompressionDecisionInstance,
       WeightedSetCoverInstance,
       active_strategy_count,
       combined_safe_compression_reduction,
       closure_only_safe_compression_reduction,
       covers_identity_obligations,
       frontier_only_safe_compression_reduction,
       identity_safe_cover,
       library_frontier,
       library_module_mask,
       library_weight,
       minimum_safe_weight_masks,
       reduction_correspondence,
       safe_feasible,
       set_cover_feasible,
       set_cover_optimal_masks,
       set_cover_source_mask,
       set_cover_weight

function _require_unique(values, label::AbstractString)
    length(Set(values)) == length(values) ||
        throw(ArgumentError("$label must be unique"))
    return nothing
end

function _full_mask(count::Integer)
    0 <= count <= 62 ||
        throw(ArgumentError("bit-mask fixtures support between 0 and 62 entries"))
    return iszero(count) ? UInt64(0) :
           (UInt64(1) << Int(count)) - UInt64(1)
end

"""
    WeightedSetCoverInstance

Finite exact weighted-set-cover input used to construct safe-compression
instances. `set_masks[i]` records the elements covered by selectable set `i`.
The constructor requires the complete family to cover the universe, matching
the standard restricted NP-complete input class used by the reductions.

The bit-mask bounds are implementation limits of the executable fixture, not
assumptions of the mathematical reduction.
"""
struct WeightedSetCoverInstance
    element_ids::Vector{String}
    set_ids::Vector{String}
    weights::Vector{ExactRational}
    set_masks::Vector{UInt64}
end

function WeightedSetCoverInstance(
    element_ids::AbstractVector,
    set_ids::AbstractVector,
    weights::AbstractVector,
    set_masks::AbstractVector{<:Integer},
)
    elements = String[string(value) for value in element_ids]
    sets = String[string(value) for value in set_ids]
    isempty(elements) &&
        throw(ArgumentError("a set-cover reduction needs a nonempty universe"))
    isempty(sets) &&
        throw(ArgumentError("a set-cover reduction needs at least one selectable set"))
    length(elements) <= 62 ||
        throw(ArgumentError("bit-mask fixtures support at most 62 elements"))
    length(sets) <= 62 ||
        throw(ArgumentError("bit-mask fixtures support at most 62 selectable sets"))
    _require_unique(elements, "set-cover element identifiers")
    _require_unique(sets, "set-cover set identifiers")
    length(weights) == length(sets) ||
        throw(DimensionMismatch("one exact weight is required per selectable set"))
    length(set_masks) == length(sets) ||
        throw(DimensionMismatch("one incidence mask is required per selectable set"))

    exact_weights = ExactRational[exact_rational(weight) for weight in weights]
    all(>(zero(ExactRational)), exact_weights) ||
        throw(ArgumentError("every selectable set must have positive exact weight"))

    universe_mask = _full_mask(length(elements))
    incidence = UInt64[UInt64(mask) for mask in set_masks]
    all(mask -> (mask & ~universe_mask) == 0, incidence) ||
        throw(ArgumentError("a set contains an element outside the universe"))
    reduce(|, incidence; init = UInt64(0)) == universe_mask ||
        throw(ArgumentError("the complete set family must cover the universe"))

    return WeightedSetCoverInstance(elements, sets, exact_weights, incidence)
end

set_cover_source_mask(instance::WeightedSetCoverInstance) =
    _full_mask(length(instance.set_ids))

function _validate_selection(
    instance::WeightedSetCoverInstance,
    selected_mask::UInt64,
)
    (selected_mask & ~set_cover_source_mask(instance)) == 0 ||
        throw(ArgumentError("a selected-set mask exceeds the set carrier"))
    return selected_mask
end

function set_cover_feasible(
    instance::WeightedSetCoverInstance,
    selected_mask::UInt64,
)
    _validate_selection(instance, selected_mask)
    covered = UInt64(0)
    for set_index in eachindex(instance.set_ids)
        bit = UInt64(1) << (set_index - 1)
        iszero(selected_mask & bit) && continue
        covered |= instance.set_masks[set_index]
    end
    return covered == _full_mask(length(instance.element_ids))
end

function set_cover_weight(
    instance::WeightedSetCoverInstance,
    selected_mask::UInt64,
)
    _validate_selection(instance, selected_mask)
    return sum(
        (
            instance.weights[set_index] for
            set_index in eachindex(instance.set_ids) if
            !iszero(selected_mask & (UInt64(1) << (set_index - 1)))
        );
        init = zero(ExactRational),
    )
end

function set_cover_optimal_masks(instance::WeightedSetCoverInstance)
    feasible = UInt64[
        mask for mask in UInt64(0):set_cover_source_mask(instance) if
        set_cover_feasible(instance, mask)
    ]
    minimum_weight = minimum(set_cover_weight(instance, mask) for mask in feasible)
    return UInt64[
        mask for mask in feasible if
        set_cover_weight(instance, mask) == minimum_weight
    ]
end

"""
    SafeCompressionDecisionInstance

Polynomial-size identity-closure decision instance. The inactive policy is
implicit and has zero profile, zero weight, and no modules. Exact exhaustive
optimization is provided only as a fixture validator and is not part of the
reduction constructor.
"""
struct SafeCompressionDecisionInstance
    strategy_ids::Vector{String}
    weights::Vector{ExactRational}
    profiles::Matrix{ExactRational}
    module_masks::Vector{UInt64}
    module_count::Int
end

function SafeCompressionDecisionInstance(
    strategy_ids::AbstractVector,
    weights::AbstractVector,
    profiles::AbstractMatrix,
    module_masks::AbstractVector{<:Integer},
    module_count::Integer,
)
    ids = String[string(id) for id in strategy_ids]
    _require_unique(ids, "active strategy identifiers")
    active_count = length(ids)
    1 <= active_count <= 62 ||
        throw(ArgumentError("bit-mask fixtures support between 1 and 62 active policies"))
    length(weights) == active_count ||
        throw(DimensionMismatch("one exact weight is required per active policy"))
    size(profiles, 1) == active_count ||
        throw(DimensionMismatch("one profile row is required per active policy"))
    size(profiles, 2) >= 1 ||
        throw(DimensionMismatch("at least one belief is required"))
    length(module_masks) == active_count ||
        throw(DimensionMismatch("one module mask is required per active policy"))
    1 <= module_count <= 62 ||
        throw(ArgumentError("bit-mask fixtures support between 1 and 62 modules"))

    exact_weights = ExactRational[exact_rational(weight) for weight in weights]
    all(>(zero(ExactRational)), exact_weights) ||
        throw(ArgumentError("every active policy must have positive exact weight"))
    exact_profiles = ExactRational[
        exact_rational(profiles[row, column]) for
        row in axes(profiles, 1), column in axes(profiles, 2)
    ]
    exact_module_masks = UInt64[UInt64(mask) for mask in module_masks]
    module_universe = _full_mask(module_count)
    all(mask -> iszero(mask & ~module_universe), exact_module_masks) ||
        throw(ArgumentError("a module row exceeds the declared universe"))

    return SafeCompressionDecisionInstance(
        ids,
        exact_weights,
        exact_profiles,
        exact_module_masks,
        Int(module_count),
    )
end

active_strategy_count(problem::SafeCompressionDecisionInstance) =
    length(problem.strategy_ids)

function _validate_policy_mask(
    problem::SafeCompressionDecisionInstance,
    mask::UInt64,
)
    (mask & ~_full_mask(active_strategy_count(problem))) == 0 ||
        throw(ArgumentError("a policy mask exceeds the active carrier"))
    return mask
end

function library_weight(
    problem::SafeCompressionDecisionInstance,
    mask::UInt64,
)
    _validate_policy_mask(problem, mask)
    return sum(
        (
            problem.weights[index] for index in eachindex(problem.strategy_ids) if
            !iszero(mask & (UInt64(1) << (index - 1)))
        );
        init = zero(ExactRational),
    )
end

function library_frontier(
    problem::SafeCompressionDecisionInstance,
    mask::UInt64,
)
    _validate_policy_mask(problem, mask)
    frontier = zeros(ExactRational, size(problem.profiles, 2))
    for strategy_index in eachindex(problem.strategy_ids)
        iszero(mask & (UInt64(1) << (strategy_index - 1))) && continue
        for belief_index in axes(problem.profiles, 2)
            frontier[belief_index] = max(
                frontier[belief_index],
                problem.profiles[strategy_index, belief_index],
            )
        end
    end
    return frontier
end

function library_module_mask(
    problem::SafeCompressionDecisionInstance,
    mask::UInt64,
)
    _validate_policy_mask(problem, mask)
    result = UInt64(0)
    for strategy_index in eachindex(problem.strategy_ids)
        iszero(mask & (UInt64(1) << (strategy_index - 1))) && continue
        result |= problem.module_masks[strategy_index]
    end
    return result
end

function safe_feasible(
    problem::SafeCompressionDecisionInstance,
    source_mask::UInt64,
    candidate_mask::UInt64,
)
    _validate_policy_mask(problem, source_mask)
    _validate_policy_mask(problem, candidate_mask)
    iszero(candidate_mask & ~source_mask) || return false
    return library_frontier(problem, candidate_mask) ==
           library_frontier(problem, source_mask) &&
           library_module_mask(problem, candidate_mask) ==
           library_module_mask(problem, source_mask)
end

function minimum_safe_weight_masks(
    problem::SafeCompressionDecisionInstance,
    source_mask::UInt64,
)
    _validate_policy_mask(problem, source_mask)
    feasible = UInt64[
        mask for mask in UInt64(0):source_mask if
        safe_feasible(problem, source_mask, mask)
    ]
    minimum_weight = minimum(library_weight(problem, mask) for mask in feasible)
    return UInt64[
        mask for mask in feasible if library_weight(problem, mask) == minimum_weight
    ]
end

function _incidence_profiles(instance::WeightedSetCoverInstance)
    profiles = zeros(
        ExactRational,
        length(instance.set_ids),
        length(instance.element_ids),
    )
    for set_index in eachindex(instance.set_ids)
        for element_index in eachindex(instance.element_ids)
            element_bit = UInt64(1) << (element_index - 1)
            iszero(instance.set_masks[set_index] & element_bit) ||
                (profiles[set_index, element_index] = one(ExactRational))
        end
    end
    return profiles
end

"""
    closure_only_safe_compression_reduction(instance)

Polynomial construction for the closure-only hardness reduction. It creates
one belief, zero active profiles, identity closure, and one module per
set-cover element. The mandatory inactive policy preserves the frontier, so a
sublibrary is safe exactly when its active policies form a set cover.
"""
function closure_only_safe_compression_reduction(
    instance::WeightedSetCoverInstance,
)
    active_count = length(instance.set_ids)
    return SafeCompressionDecisionInstance(
        instance.set_ids,
        instance.weights,
        zeros(ExactRational, active_count, 1),
        instance.set_masks,
        length(instance.element_ids),
    )
end

"""
    frontier_only_safe_compression_reduction(instance)

Polynomial construction for the frontier-only hardness reduction. It creates
one belief per set-cover element, uses binary profiles equal to the incidence
matrix, and gives every active policy an empty module row. Because the source
sets cover the universe, its frontier is one at every belief. Frontier
preservation is therefore exactly set-cover feasibility.
"""
function frontier_only_safe_compression_reduction(
    instance::WeightedSetCoverInstance,
)
    active_count = length(instance.set_ids)
    return SafeCompressionDecisionInstance(
        instance.set_ids,
        instance.weights,
        _incidence_profiles(instance),
        zeros(UInt64, active_count),
        1,
    )
end

"""
    combined_safe_compression_reduction(instance)

Exact combined-obligation fixture. Each set-cover element appears both as a
belief-frontier obligation and as an identity-closure module obligation.
The duplicate obligation types leave the feasible selected-set family
unchanged.
"""
function combined_safe_compression_reduction(
    instance::WeightedSetCoverInstance,
)
    return SafeCompressionDecisionInstance(
        instance.set_ids,
        instance.weights,
        _incidence_profiles(instance),
        instance.set_masks,
        length(instance.element_ids),
    )
end

"""
    IdentitySafeCover

Weighted-cover representation of an identity-closure safe-compression
instance. `policy_obligation_masks[i]` contains all nonautomatic belief and
module obligations covered by active policy `i`. Frontier-zero beliefs are
omitted because the mandatory inactive policy already attains them.
"""
struct IdentitySafeCover
    obligation_labels::Vector{String}
    policy_obligation_masks::Vector{UInt64}
    full_obligation_mask::UInt64
    source_mask::UInt64
end

function identity_safe_cover(
    problem::SafeCompressionDecisionInstance,
    source_mask::UInt64,
)
    source_frontier = library_frontier(problem, source_mask)
    source_modules = library_module_mask(problem, source_mask)
    obligation_labels = String[]
    policy_masks = zeros(UInt64, active_strategy_count(problem))

    function add_obligation!(label::String, carriers::Vector{Int})
        length(obligation_labels) < 62 ||
            throw(ArgumentError("bit-mask fixtures support at most 62 obligations"))
        push!(obligation_labels, label)
        obligation_bit = UInt64(1) << (length(obligation_labels) - 1)
        for strategy_index in carriers
            policy_masks[strategy_index] |= obligation_bit
        end
        return nothing
    end

    for belief_index in eachindex(source_frontier)
        frontier_value = source_frontier[belief_index]
        iszero(frontier_value) && continue
        carriers = Int[
            strategy_index for
            strategy_index in 1:active_strategy_count(problem) if
            !iszero(source_mask & (UInt64(1) << (strategy_index - 1))) &&
            problem.profiles[strategy_index, belief_index] == frontier_value
        ]
        isempty(carriers) &&
            error("a positive finite source frontier must have an active maximizer")
        add_obligation!("belief:$belief_index", carriers)
    end

    for module_index in 1:problem.module_count
        module_bit = UInt64(1) << (module_index - 1)
        iszero(source_modules & module_bit) && continue
        carriers = Int[
            strategy_index for
            strategy_index in 1:active_strategy_count(problem) if
            !iszero(source_mask & (UInt64(1) << (strategy_index - 1))) &&
            !iszero(problem.module_masks[strategy_index] & module_bit)
        ]
        isempty(carriers) &&
            error("every source module must have an active carrier")
        add_obligation!("module:$module_index", carriers)
    end

    return IdentitySafeCover(
        obligation_labels,
        policy_masks,
        _full_mask(length(obligation_labels)),
        source_mask,
    )
end

function covers_identity_obligations(
    cover::IdentitySafeCover,
    selected_mask::UInt64,
)
    maximum_mask = _full_mask(length(cover.policy_obligation_masks))
    (selected_mask & ~maximum_mask) == 0 ||
        throw(ArgumentError("a selected-policy mask exceeds the policy carrier"))
    iszero(selected_mask & ~cover.source_mask) || return false
    covered = UInt64(0)
    for strategy_index in eachindex(cover.policy_obligation_masks)
        strategy_bit = UInt64(1) << (strategy_index - 1)
        iszero(selected_mask & strategy_bit) && continue
        covered |= cover.policy_obligation_masks[strategy_index]
    end
    return covered == cover.full_obligation_mask
end

"""
    reduction_correspondence(instance, mode)

Enumerate the executable fixture and verify that every selected-set mask is a
set cover iff it is a safe sublibrary in the requested reduction mode.
Supported modes are `:closure_only`, `:frontier_only`, and `:combined`.
"""
function reduction_correspondence(
    instance::WeightedSetCoverInstance,
    mode::Symbol,
)
    problem =
        mode === :closure_only ?
        closure_only_safe_compression_reduction(instance) :
        mode === :frontier_only ?
        frontier_only_safe_compression_reduction(instance) :
        mode === :combined ?
        combined_safe_compression_reduction(instance) :
        throw(ArgumentError("unsupported safe-compression reduction mode: $mode"))
    source_mask = set_cover_source_mask(instance)
    identity_cover = identity_safe_cover(problem, source_mask)
    masks = collect(UInt64(0):source_mask)
    correspondence = all(
        set_cover_feasible(instance, mask) ==
        safe_feasible(problem, source_mask, mask) ==
        covers_identity_obligations(identity_cover, mask) for mask in masks
    )
    weight_preservation = all(
        set_cover_weight(instance, mask) == library_weight(problem, mask) for
        mask in masks
    )
    safe_optima = minimum_safe_weight_masks(problem, source_mask)
    cover_optima = set_cover_optimal_masks(instance)
    return (
        mode = mode,
        problem = problem,
        source_mask = source_mask,
        identity_cover = identity_cover,
        correspondence = correspondence,
        weight_preservation = weight_preservation,
        safe_optima = safe_optima,
        cover_optima = cover_optima,
        optimizer_correspondence = safe_optima == cover_optima,
    )
end

end
