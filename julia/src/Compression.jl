"""
    CompressionVerification

Audit record returned by [`verify_compressed_equivalence`](@ref).  The
`compression_ratio` is the exact fraction of source strategies removed,
`(source_size - compressed_size) / source_size`.  Dynamic fields are `missing`
unless the corresponding exact semantics or value oracle is supplied.
"""
struct CompressionVerification
    source_size::Int
    compressed_size::Int
    compression_ratio::ExactRational
    sublibrary::Bool
    frontier_preserved::Bool
    generative_closure_preserved::Bool
    compressed_state_preserved::Bool
    dynamic_innovation_preserved::Union{Missing,Bool}
    dynamic_value_preserved::Union{Missing,Bool}
    value_comparisons::Int
end

function _compression_ratio(source::RawLibrary, compressed::RawLibrary)
    return exact_rational(length(source) - length(compressed)) /
           exact_rational(length(source))
end

function _validate_compression_closure(
    catalog::StrategyCatalog,
    closure::GenerativeClosure,
)
    catalog_modules = ModuleSet(collect(catalog.modules))
    closure.universe == catalog_modules || throw(
        ArgumentError("the generative closure and strategy catalog must share a module universe"),
    )
    return closure
end

function _ordered_deletion_ids(
    catalog::StrategyCatalog{S},
    library::RawLibrary{S},
    deletion_order,
) where {S}
    validate_library(catalog, library)
    ids = if isnothing(deletion_order)
        StrategyId{S}[
            row.id for row in catalog.strategies if
            row.id in library && row.id != catalog.inactive_strategy
        ]
    else
        try
            StrategyId{S}[strategy_id for strategy_id in deletion_order]
        catch error
            throw(ArgumentError("deletion_order must contain typed StrategyId values: $error"))
        end
    end
    _require_unique(ids, "strategy IDs in the deletion order")
    for strategy_id in ids
        strategy(catalog, strategy_id)
        strategy_id == catalog.inactive_strategy &&
            throw(ArgumentError("the deletion order cannot contain the inactive strategy"))
        strategy_id in library || throw(
            ArgumentError("the deletion order contains a strategy absent from the source library"),
        )
    end
    return ids
end

"""
    frontier_only_prune(catalog, library; deletion_order=nothing)

Repeatedly delete strategies whose deletion preserves the current operational
frontier, using catalog order unless a deterministic `deletion_order` is
provided.  Every deletion is checked against the intermediate library.

This is the reusable Julia counterpart of Lean F4
`FrontierPruningLoss.frontierOnlyPrune`.  It deliberately ignores generative
closure and therefore is not innovation-safe in general.
"""
function frontier_only_prune(
    catalog::StrategyCatalog{S},
    library::RawLibrary{S};
    deletion_order = nothing,
) where {S}
    ordered_ids = _ordered_deletion_ids(catalog, library, deletion_order)
    current = library
    changed = true
    while changed
        changed = false
        for strategy_id in ordered_ids
            strategy_id in current || continue
            if operationally_redundant(catalog, current, strategy_id)
                current = delete_strategy(catalog, current, strategy_id)
                changed = true
            end
        end
    end
    return current
end

"""
    innovation_safe_delete(catalog, closure, library, strategy_id)

Delete one present noninactive strategy only if its removal preserves both the
operational frontier and the generative closure.  An unsafe request throws an
`ArgumentError` and leaves the input immutable.

The guard mirrors Lean F3 `operationallyRedundant` and
`generativelyRedundant`; the returned state is the executable counterpart of
`redundantDeletion_iff_compressedStatePreservingDeletion`.
"""
function innovation_safe_delete(
    catalog::StrategyCatalog{S},
    closure::GenerativeClosure,
    library::RawLibrary{S},
    strategy_id::StrategyId{S},
) where {S}
    validate_library(catalog, library)
    _validate_compression_closure(catalog, closure)
    strategy(catalog, strategy_id)
    strategy_id == catalog.inactive_strategy &&
        throw(ArgumentError("the inactive strategy cannot be deleted"))
    strategy_id in library ||
        throw(ArgumentError("innovation-safe deletion requires a strategy present in the library"))

    operational = operationally_redundant(catalog, library, strategy_id)
    generative = generatively_redundant(catalog, closure, library, strategy_id)
    operational && generative || throw(
        ArgumentError(
            "unsafe deletion of $strategy_id: " *
            "operationally_redundant=$operational, " *
            "generatively_redundant=$generative",
        ),
    )
    return delete_strategy(catalog, library, strategy_id)
end

"""
    innovation_safe_prune_fixed_point(catalog, closure, library;
                                      deletion_order=nothing)

Apply [`innovation_safe_delete`](@ref) at each intermediate library until no
ordered candidate is removable.  The result is deletion-irreducible for this
deterministic order, but is not claimed to be a minimum-cardinality
compression.

The stepwise check mirrors the intermediate-library discipline of Lean F3
`SafeDeletionSequence`.  Lean proves safety of such a sequence under the F1/F3
factorization assumptions; it does not prove a greedy approximation ratio.
"""
function innovation_safe_prune_fixed_point(
    catalog::StrategyCatalog{S},
    closure::GenerativeClosure,
    library::RawLibrary{S};
    deletion_order = nothing,
) where {S}
    ordered_ids = _ordered_deletion_ids(catalog, library, deletion_order)
    _validate_compression_closure(catalog, closure)
    current = library
    changed = true
    while changed
        changed = false
        for strategy_id in ordered_ids
            strategy_id in current || continue
            if operationally_redundant(catalog, current, strategy_id) &&
               generatively_redundant(catalog, closure, current, strategy_id)
                current = innovation_safe_delete(
                    catalog,
                    closure,
                    current,
                    strategy_id,
                )
                changed = true
            end
        end
    end
    return current
end

function _value_equal(left, right, atol)
    isnothing(atol) && return left == right
    return isapprox(left, right; atol, rtol = 0)
end

"""
    verify_compressed_equivalence(catalog, closure, source, compressed;
                                  semantics=nothing, value_oracle=nothing,
                                  horizons=0:0, beliefs=catalog.beliefs,
                                  value_atol=nothing)

Return a [`CompressionVerification`](@ref) separating current-frontier,
generative-closure, compressed-state, primitive dynamic-innovation, and
dynamic-value checks.

Supplying exact F1 `semantics` evaluates Lean
`DynamicInnovationEquivalent`.  A `value_oracle(horizon, belief, library)` may
be supplied to audit a model-specific finite-horizon recursion; `value_atol`
must remain `nothing` for theorem fixtures and may be nonnegative only for
Float64 simulations.  Compressed-state equality mirrors Lean F3
`redundantDeletion_iff_compressedStatePreservingDeletion`; value preservation
is reported independently and is not inferred as a converse.
"""
function verify_compressed_equivalence(
    catalog::StrategyCatalog,
    closure::GenerativeClosure,
    source::RawLibrary,
    compressed::RawLibrary;
    semantics = nothing,
    value_oracle = nothing,
    horizons = 0:0,
    beliefs = catalog.beliefs,
    value_atol = nothing,
)
    validate_library(catalog, source)
    validate_library(catalog, compressed)
    _validate_compression_closure(catalog, closure)
    if !isnothing(value_atol)
        value_atol isa Real ||
            throw(ArgumentError("value_atol must be a nonnegative real or nothing"))
        value_atol >= 0 || throw(ArgumentError("value_atol must be nonnegative"))
    end

    frontier_preserved = frontier(catalog, source) == frontier(catalog, compressed)
    closure_preserved =
        generative_closure(catalog, closure, source) ==
        generative_closure(catalog, closure, compressed)
    state_preserved =
        compressed_state(catalog, closure, source) ==
        compressed_state(catalog, closure, compressed)

    dynamic_innovation = if isnothing(semantics)
        missing
    else
        dynamic_innovation_equivalent(
            semantics,
            catalog,
            closure,
            source,
            compressed,
        )
    end

    value_preserved::Union{Missing,Bool} = missing
    comparisons = 0
    if !isnothing(value_oracle)
        checked_horizons = collect(horizons)
        all(horizon -> horizon isa Integer && horizon >= 0, checked_horizons) ||
            throw(ArgumentError("value horizons must be nonnegative integers"))
        checked_beliefs = collect(beliefs)
        for belief in checked_beliefs
            belief in catalog.beliefs ||
                throw(ArgumentError("the value audit contains an unresolved belief"))
        end
        value_preserved = true
        for horizon in checked_horizons, belief in checked_beliefs
            comparisons += 1
            source_value = value_oracle(horizon, belief, source)
            compressed_value = value_oracle(horizon, belief, compressed)
            if !_value_equal(source_value, compressed_value, value_atol)
                value_preserved = false
            end
        end
    end

    return CompressionVerification(
        length(source),
        length(compressed),
        _compression_ratio(source, compressed),
        issubset(compressed, source),
        frontier_preserved,
        closure_preserved,
        state_preserved,
        dynamic_innovation,
        value_preserved,
        comparisons,
    )
end

"""
    minimum_safe_compression(catalog, closure, source; max_optional=20)

Find a minimum-cardinality sublibrary with exactly the same frontier--closure
compressed state by exhaustive cardinality-ordered search.  Ties are broken
deterministically by catalog order.  The search is limited to `max_optional`
noninactive source strategies and is intended only for small finite fixtures.

This optimizer targets the endpoint predicate characterized by Lean F3
`redundantDeletion_iff_compressedStatePreservingDeletion`.  Lean contains no
minimum-cardinality or approximation theorem for this search.
"""
function minimum_safe_compression(
    catalog::StrategyCatalog{S},
    closure::GenerativeClosure,
    source::RawLibrary{S};
    max_optional::Integer = 20,
) where {S}
    validate_library(catalog, source)
    _validate_compression_closure(catalog, closure)
    max_optional >= 0 || throw(ArgumentError("max_optional must be nonnegative"))
    optional = StrategyId{S}[
        row.id for row in catalog.strategies if
        row.id in source && row.id != catalog.inactive_strategy
    ]
    optional_count = length(optional)
    optional_count <= max_optional || throw(
        ArgumentError(
            "exhaustive compression has $optional_count optional strategies, " *
            "exceeding max_optional=$max_optional",
        ),
    )
    optional_count <= 62 ||
        throw(ArgumentError("the exhaustive bit-mask implementation supports at most 62 strategies"))

    target_state = compressed_state(catalog, closure, source)
    upper = UInt64(1) << optional_count
    for retained_count in 0:optional_count
        for mask in UInt64(0):(upper - UInt64(1))
            count_ones(mask) == retained_count || continue
            retained = StrategyId{S}[catalog.inactive_strategy]
            for (index, strategy_id) in enumerate(optional)
                iszero(mask & (UInt64(1) << (index - 1))) ||
                    push!(retained, strategy_id)
            end
            candidate = RawLibrary(catalog, retained)
            compressed_state(catalog, closure, candidate) == target_state &&
                return candidate
        end
    end
    error("the source library itself should always be a feasible compression")
end

"""
    BinaryCompressionFormulation

Solver-independent exact 0--1 formulation data for minimum safe compression.
Columns correspond to `strategy_ids`; rows of `frontier_cover` identify
strategies attaining each target frontier value, and rows of `module_supply`
identify suppliers of each module.  `closure_generators` are the
inclusion-minimal module sets whose validated closure equals the target.

With binary strategy variables `x` and generator-choice variables `y`, the
MILP is: minimize `sum(x)`; fix the inactive column to one; cover every
frontier row; require `sum(y) >= 1`; and for every generator `g` and module in
`g`, require the corresponding supplier sum to be at least `y[g]`.  This is a
formulation of F3 compressed-state equality, not a Lean-verified optimization
or approximation theorem.
"""
struct BinaryCompressionFormulation{S,B,M}
    strategy_ids::Tuple{Vararg{StrategyId{S}}}
    beliefs::Tuple{Vararg{Belief{B}}}
    modules::Tuple{Vararg{ModuleId{M}}}
    frontier_cover::BitMatrix
    module_supply::BitMatrix
    closure_generators::Tuple{Vararg{ModuleSet{M}}}
    inactive_index::Int
    objective::Tuple{Vararg{Int}}
end

"""
    minimum_safe_compression_ip_formulation(catalog, closure, source)

Build the exact solver-independent [`BinaryCompressionFormulation`](@ref) for
the source library.  No optimizer dependency is required; downstream code may
translate the matrices and generator disjunction to its preferred MILP
package.  The formulation is derived from the finite closure table and is
valid for non-identity closures as well as identity closure.
"""
function minimum_safe_compression_ip_formulation(
    catalog::StrategyCatalog{S,B,M},
    closure::GenerativeClosure{M},
    source::RawLibrary{S},
) where {S,B,M}
    validate_library(catalog, source)
    _validate_compression_closure(catalog, closure)
    strategy_ids = Tuple(
        row.id for row in catalog.strategies if row.id in source
    )
    beliefs = Tuple(catalog.beliefs.states)
    modules = Tuple(module_row.id for module_row in catalog.modules)
    target_frontier = frontier(catalog, source)
    target_closure = generative_closure(catalog, closure, source)
    source_modules = module_union(catalog, source)

    frontier_cover = falses(length(beliefs), length(strategy_ids))
    for (belief_index_value, belief) in enumerate(beliefs)
        for (strategy_index, strategy_id) in enumerate(strategy_ids)
            frontier_cover[belief_index_value, strategy_index] =
                operational_profile(catalog, strategy_id)[belief] ==
                target_frontier[belief]
        end
    end

    module_supply = falses(length(modules), length(strategy_ids))
    for (module_index, module_id) in enumerate(modules)
        for (strategy_index, strategy_id) in enumerate(strategy_ids)
            module_supply[module_index, strategy_index] =
                module_id in strategy_modules(catalog, strategy_id)
        end
    end

    generators = ModuleSet{M}[]
    for entry in closure.table
        raw_modules = first(entry)
        closed_modules = last(entry)
        closed_modules == target_closure || continue
        issubset(raw_modules, source_modules) || continue
        push!(generators, raw_modules)
    end
    minimal_generators = ModuleSet{M}[
        candidate for candidate in generators if !any(
            other -> other != candidate && issubset(other, candidate),
            generators,
        )
    ]
    isempty(minimal_generators) &&
        error("the source raw module union must generate its own target closure")

    inactive_index = findfirst(==(catalog.inactive_strategy), strategy_ids)
    isnothing(inactive_index) && error("validated source library lost its inactive strategy")
    return BinaryCompressionFormulation{S,B,M}(
        strategy_ids,
        beliefs,
        modules,
        frontier_cover,
        module_supply,
        Tuple(minimal_generators),
        inactive_index,
        Tuple(ones(Int, length(strategy_ids))),
    )
end

"""
    satisfies_compression_formulation(formulation, selected)

Evaluate the 0--1 constraints represented by a
[`BinaryCompressionFormulation`](@ref).  `selected` is a Boolean vector in
`formulation.strategy_ids` order.  This utility validates translations to an
external optimizer; it does not solve the MILP.
"""
function satisfies_compression_formulation(
    formulation::BinaryCompressionFormulation,
    selected::AbstractVector{Bool},
)
    length(selected) == length(formulation.strategy_ids) ||
        throw(DimensionMismatch("the binary selection has the wrong number of columns"))
    selected[formulation.inactive_index] || return false

    for belief_row in axes(formulation.frontier_cover, 1)
        any(
            selected[column] && formulation.frontier_cover[belief_row, column]
            for column in axes(formulation.frontier_cover, 2)
        ) || return false
    end

    for generator in formulation.closure_generators
        generator_covered = true
        for module_id in generator
            module_row = findfirst(==(module_id), formulation.modules)
            isnothing(module_row) && error("formulation generator contains an unknown module")
            covered = any(
                selected[column] && formulation.module_supply[module_row, column]
                for column in axes(formulation.module_supply, 2)
            )
            if !covered
                generator_covered = false
                break
            end
        end
        generator_covered && return true
    end
    return false
end

include("SafeCompressionSolver.jl")
