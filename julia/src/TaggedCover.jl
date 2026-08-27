"""Supertype for disjoint source-relative tagged-cover requirements."""
abstract type TaggedRequirement end

"""Requirement that the source frontier be attained at one declared belief."""
struct FrontierRequirement{B} <: TaggedRequirement
    belief::Belief{B}
end

"""Requirement that one source-closure module have a retained raw carrier."""
struct ModuleRequirement{M} <: TaggedRequirement
    module_id::ModuleId{M}
end

Base.:(==)(left::FrontierRequirement, right::FrontierRequirement) =
    left.belief == right.belief
Base.:(==)(left::ModuleRequirement, right::ModuleRequirement) =
    left.module_id == right.module_id
Base.hash(requirement::FrontierRequirement, seed::UInt) =
    hash((:frontier_requirement, requirement.belief), seed)
Base.hash(requirement::ModuleRequirement, seed::UInt) =
    hash((:module_requirement, requirement.module_id), seed)

Base.show(io::IO, requirement::FrontierRequirement) =
    print(io, "FrontierRequirement(", repr(requirement.belief.id), ")")
Base.show(io::IO, requirement::ModuleRequirement) =
    print(io, "ModuleRequirement(", repr(requirement.module_id.id), ")")

"""
    TaggedCoverRepresentation

Exact source-relative weighted covering representation for identity closure.
Rows are a stable disjoint sequence of all belief-frontier requirements
followed by all modules in the source closure. Columns are source strategies
in catalog order, including the mandatory inactive strategy. `coverage[row,
column]` is true exactly when that strategy covers that tagged requirement.
"""
struct TaggedCoverRepresentation{S,B,M,T<:Real}
    catalog::StrategyCatalog{S,B,M,T}
    closure::GenerativeClosure{M}
    source::RawLibrary{S}
    strategy_ids::Tuple{Vararg{StrategyId{S}}}
    requirements::Tuple{Vararg{TaggedRequirement}}
    coverage::BitMatrix
    inactive_index::Int
    weights::Tuple{Vararg{ExactRational}}
end

function _require_identity_generative_closure(
    catalog::StrategyCatalog,
    closure::GenerativeClosure,
)
    _validate_compression_closure(catalog, closure)
    all(first(entry) == last(entry) for entry in closure.table) || throw(
        ArgumentError(
            "the tagged per-module representation is valid only for identity closure",
        ),
    )
    return closure
end

function _tagged_cover_weights(strategy_ids, inactive_index, strategy_weights)
    count = length(strategy_ids)
    weights = if isnothing(strategy_weights)
        ExactRational[
            index == inactive_index ? 0 // 1 : 1 // 1 for index in 1:count
        ]
    elseif strategy_weights isa AbstractVector
        length(strategy_weights) == count || throw(
            DimensionMismatch(
                "strategy_weights must align with source strategies in catalog order",
            ),
        )
        ExactRational[exact_rational(weight) for weight in strategy_weights]
    elseif strategy_weights isa AbstractDict
        missing_ids = [
            strategy_id for strategy_id in strategy_ids if
            !haskey(strategy_weights, strategy_id)
        ]
        isempty(missing_ids) || throw(
            ArgumentError("strategy_weights are missing source IDs: $missing_ids"),
        )
        ExactRational[
            exact_rational(strategy_weights[strategy_id]) for
            strategy_id in strategy_ids
        ]
    else
        throw(
            ArgumentError(
                "strategy_weights must be nothing, an aligned vector, or a dictionary",
            ),
        )
    end
    iszero(weights[inactive_index]) || throw(
        ArgumentError("the mandatory inactive strategy must have zero weight"),
    )
    for index in eachindex(weights)
        index == inactive_index && continue
        weights[index] > 0 || throw(
            ArgumentError("every active strategy must have positive exact weight"),
        )
    end
    return Tuple(weights)
end

"""
    tagged_requirement_universe(catalog, closure, source)

Return `U_L`: all belief-frontier tags followed by all source-closure module
tags in catalog order. Frontier and module tags remain type-disjoint even when
their underlying labels compare equal as raw values.
"""
function tagged_requirement_universe(
    catalog::StrategyCatalog{S,B,M},
    closure::GenerativeClosure{M},
    source::RawLibrary{S},
) where {S,B,M}
    validate_library(catalog, source)
    _require_identity_generative_closure(catalog, closure)
    source_closure = generative_closure(catalog, closure, source)
    requirements = TaggedRequirement[
        FrontierRequirement(belief) for belief in catalog.beliefs
    ]
    append!(
        requirements,
        TaggedRequirement[
            ModuleRequirement(module_row.id) for module_row in catalog.modules if
            module_row.id in source_closure
        ],
    )
    return Tuple(requirements)
end

"""
    tagged_cover_representation(catalog, closure, source; strategy_weights=nothing)

Construct the exact tagged incidence representation for an identity-closure
source library. Unit active weights and zero inactive weight are used when
`strategy_weights` is omitted; supplied weights must be exact-convertible,
strictly positive for active entries, and zero for the inactive entry.
"""
function tagged_cover_representation(
    catalog::StrategyCatalog{S,B,M,T},
    closure::GenerativeClosure{M},
    source::RawLibrary{S};
    strategy_weights = nothing,
) where {S,B,M,T<:Real}
    validate_library(catalog, source)
    _require_identity_generative_closure(catalog, closure)
    strategy_ids = Tuple(
        row.id for row in catalog.strategies if row.id in source
    )
    requirements = tagged_requirement_universe(catalog, closure, source)
    inactive_index = findfirst(==(catalog.inactive_strategy), strategy_ids)
    isnothing(inactive_index) &&
        error("validated source library lost its mandatory inactive strategy")
    source_frontier = frontier(catalog, source)
    coverage = falses(length(requirements), length(strategy_ids))
    for (row_index, requirement) in enumerate(requirements)
        for (column_index, strategy_id) in enumerate(strategy_ids)
            coverage[row_index, column_index] = if requirement isa FrontierRequirement
                operational_profile(catalog, strategy_id)[requirement.belief] ==
                source_frontier[requirement.belief]
            elseif requirement isa ModuleRequirement
                requirement.module_id in strategy_modules(catalog, strategy_id)
            else
                error("unknown tagged requirement subtype")
            end
        end
    end
    weights = _tagged_cover_weights(
        strategy_ids,
        inactive_index,
        strategy_weights,
    )
    return TaggedCoverRepresentation{S,B,M,T}(
        catalog,
        closure,
        source,
        strategy_ids,
        requirements,
        coverage,
        inactive_index,
        weights,
    )
end

"""Return the stable tag set `R_s` covered by one source strategy."""
function strategy_tagged_coverage(
    representation::TaggedCoverRepresentation,
    strategy_id::StrategyId,
)
    column = findfirst(==(strategy_id), representation.strategy_ids)
    isnothing(column) && throw(
        ArgumentError("the strategy is not a column of the source representation"),
    )
    return Tuple(
        representation.requirements[row] for row in axes(representation.coverage, 1) if
        representation.coverage[row, column]
    )
end

function _validate_tagged_selection(
    representation::TaggedCoverRepresentation,
    selected::AbstractVector{Bool},
)
    length(selected) == length(representation.strategy_ids) || throw(
        DimensionMismatch("the binary selection has the wrong number of columns"),
    )
    return selected
end

"""Test all tagged rows and mandatory inactive retention for a binary selection."""
function tagged_cover_feasible(
    representation::TaggedCoverRepresentation,
    selected::AbstractVector{Bool},
)
    _validate_tagged_selection(representation, selected)
    selected[representation.inactive_index] || return false
    return all(
        any(
            selected[column] && representation.coverage[row, column] for
            column in axes(representation.coverage, 2)
        ) for row in axes(representation.coverage, 1)
    )
end

"""Test tagged-cover feasibility of an admissible proposed source sublibrary."""
function tagged_cover_feasible(
    representation::TaggedCoverRepresentation{S},
    candidate::RawLibrary{S},
) where {S}
    validate_library(representation.catalog, candidate)
    issubset(candidate, representation.source) || return false
    selected = Bool[
        strategy_id in candidate for strategy_id in representation.strategy_ids
    ]
    return tagged_cover_feasible(representation, selected)
end

"""Compute the exact weighted binary-cover objective for one selection."""
function tagged_cover_burden(
    representation::TaggedCoverRepresentation,
    selected::AbstractVector{Bool},
)
    _validate_tagged_selection(representation, selected)
    return sum(
        (
            representation.weights[index] for index in eachindex(selected) if
            selected[index]
        );
        init = zero(ExactRational),
    )
end

function tagged_cover_burden(
    representation::TaggedCoverRepresentation{S},
    candidate::RawLibrary{S},
) where {S}
    validate_library(representation.catalog, candidate)
    issubset(candidate, representation.source) || throw(
        ArgumentError("burden is requested for a library outside the source"),
    )
    return tagged_cover_burden(
        representation,
        Bool[strategy_id in candidate for strategy_id in representation.strategy_ids],
    )
end

"""Return solver-neutral data for the weighted binary covering formulation."""
tagged_binary_cover_formulation(representation::TaggedCoverRepresentation) = (
    requirements = representation.requirements,
    strategy_ids = representation.strategy_ids,
    incidence = copy(representation.coverage),
    weights = representation.weights,
    inactive_index = representation.inactive_index,
    inactive_fixed_value = true,
    row_lower_bounds = Tuple(ones(Int, length(representation.requirements))),
)

"""
    tagged_cover_certificate(representation, candidate)

Independently compare tagged-cover feasibility with exact source-relative
frontier and closure equality, and report exact burden and inactive retention.
This is an exact finite certificate for one returned library, not a proof of
global optimality.
"""
function tagged_cover_certificate(
    representation::TaggedCoverRepresentation{S},
    candidate::RawLibrary{S},
) where {S}
    validate_library(representation.catalog, candidate)
    sublibrary = issubset(candidate, representation.source)
    inactive_retained =
        representation.catalog.inactive_strategy in candidate
    frontier_preserved = sublibrary &&
        frontier(representation.catalog, candidate) ==
        frontier(representation.catalog, representation.source)
    closure_preserved = sublibrary &&
        generative_closure(
            representation.catalog,
            representation.closure,
            candidate,
        ) == generative_closure(
            representation.catalog,
            representation.closure,
            representation.source,
        )
    exact_safe_feasible =
        sublibrary && inactive_retained && frontier_preserved && closure_preserved
    cover_feasible = sublibrary && tagged_cover_feasible(representation, candidate)
    return (
        sublibrary = sublibrary,
        inactive_retained = inactive_retained,
        frontier_preserved = frontier_preserved,
        closure_preserved = closure_preserved,
        exact_safe_feasible = exact_safe_feasible,
        tagged_cover_feasible = cover_feasible,
        equivalence_holds = exact_safe_feasible == cover_feasible,
        exact_burden = sublibrary ?
            tagged_cover_burden(representation, candidate) : missing,
    )
end
