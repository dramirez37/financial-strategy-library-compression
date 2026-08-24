function _all_module_subsets(universe::ModuleSet{M}) where {M}
    subsets = ModuleSet{M}[ModuleSet{M}()]
    for module_id in universe
        singleton = ModuleSet(ModuleId{M}[module_id])
        prior = copy(subsets)
        append!(subsets, ModuleSet{M}[union(subset, singleton) for subset in prior])
    end
    return subsets
end

"""
    GenerativeClosure(modules, close)

Finite module-closure table built from a supplied closure function.  The
constructor evaluates every module subset and checks exact extensivity,
monotonicity, idempotence, and reference resolution.  This directly enforces
the fields of Lean `ModuleClosure`.
"""
struct GenerativeClosure{M}
    universe::ModuleSet{M}
    table::Tuple{Vararg{Pair{ModuleSet{M},ModuleSet{M}}}}
end

function GenerativeClosure(
    modules::AbstractVector{GenerativeModule{M}},
    close::F,
) where {M,F}
    isempty(modules) &&
        throw(ArgumentError("a generative closure requires a nonempty module carrier"))
    _require_unique(
        [module_row.id for module_row in modules],
        "module IDs in a closure universe",
    )
    universe = ModuleSet(modules)
    subsets = _all_module_subsets(universe)
    table = Dict{ModuleSet{M},ModuleSet{M}}()

    for subset in subsets
        closed = close(subset)
        closed isa ModuleSet{M} || throw(
            ArgumentError("a closure function must return ModuleSet{$M}"),
        )
        issubset(closed, universe) ||
            throw(ArgumentError("a closure result contains an unresolved module ID"))
        issubset(subset, closed) ||
            throw(ArgumentError("the module closure is not extensive at $subset"))
        table[subset] = closed
    end

    for subset in subsets
        table[table[subset]] == table[subset] ||
            throw(ArgumentError("the module closure is not idempotent at $subset"))
    end
    for left in subsets, right in subsets
        if issubset(left, right) && !issubset(table[left], table[right])
            throw(ArgumentError("the module closure is not monotone"))
        end
    end
    immutable_table = Tuple(subset => table[subset] for subset in subsets)
    return GenerativeClosure{M}(universe, immutable_table)
end

"""Construct the identity closure on a finite module catalog."""
identity_generative_closure(modules::AbstractVector{<:GenerativeModule}) =
    GenerativeClosure(modules, identity)

"""Apply a validated finite generative closure (`ModuleClosure.close` in Lean)."""
function module_closure(closure::GenerativeClosure{M}, modules::ModuleSet{M}) where {M}
    issubset(modules, closure.universe) ||
        throw(ArgumentError("cannot close a set with unresolved module references"))
    index = findfirst(entry -> first(entry) == modules, closure.table)
    isnothing(index) && error("validated closure table is internally incomplete")
    return last(closure.table[index])
end

"""Insert one resolved strategy ID into a raw library (`Library.insert`)."""
function insert_strategy(
    catalog::StrategyCatalog{S},
    library::RawLibrary{S},
    strategy_id::StrategyId{S},
) where {S}
    validate_library(catalog, library)
    strategy(catalog, strategy_id)
    strategy_id in library && return library
    return RawLibrary(catalog, [collect(library.strategies); strategy_id])
end

"""
    delete_strategy(catalog, library, strategy_id)

Delete a resolved noninactive strategy (`Library.erase`).  Deleting an absent
noninactive strategy is a no-op, exactly as for Lean `Finset.erase`; deleting
the inactive strategy is rejected.
"""
function delete_strategy(
    catalog::StrategyCatalog{S},
    library::RawLibrary{S},
    strategy_id::StrategyId{S},
) where {S}
    validate_library(catalog, library)
    strategy(catalog, strategy_id)
    strategy_id == catalog.inactive_strategy &&
        throw(ArgumentError("the inactive strategy cannot be deleted"))
    remaining = StrategyId{S}[
        candidate for candidate in library if candidate != strategy_id
    ]
    return RawLibrary(catalog, remaining)
end

"""
    operational_frontier(catalog, library)

Pointwise attained maximum of the profiles represented in an admissible raw
library.  The inactive member makes the maximum nonempty and nonnegative.
This mirrors Lean `operationalFrontier`.
"""
function operational_frontier(
    catalog::StrategyCatalog{S,B,M,T},
    library::RawLibrary{S},
) where {S,B,M,T<:Real}
    validate_library(catalog, library)
    values = Vector{T}(undef, length(catalog.beliefs))
    for (belief_index_value, belief) in enumerate(catalog.beliefs)
        first_id = first(library.strategies)
        best = operational_profile(catalog, first_id)[belief]
        for strategy_id in Iterators.drop(library.strategies, 1)
            best = max(best, operational_profile(catalog, strategy_id)[belief])
        end
        values[belief_index_value] = best
    end
    return OperationalProfile{B,T}(catalog.beliefs, Tuple(values))
end

"""Short canonical alias for `operational_frontier`."""
frontier(catalog::StrategyCatalog, library::RawLibrary) =
    operational_frontier(catalog, library)

"""
    raw_module_union(catalog, library)

Finite union of all module sets supplied by strategies in a raw library.  This
is Lean `rawModuleUnion`.
"""
function raw_module_union(
    catalog::StrategyCatalog{S,B,M},
    library::RawLibrary{S},
) where {S,B,M}
    validate_library(catalog, library)
    result = ModuleSet{M}()
    for strategy_id in library
        result = union(result, strategy_modules(catalog, strategy_id))
    end
    return result
end

"""Short canonical alias for `raw_module_union`."""
module_union(catalog::StrategyCatalog, library::RawLibrary) =
    raw_module_union(catalog, library)

"""
    generative_closure(catalog, closure, library)

Apply a validated `GenerativeClosure` to a library's raw module union.  This is
Lean `generativeClosure`.
"""
function generative_closure(
    catalog::StrategyCatalog,
    closure::GenerativeClosure,
    library::RawLibrary,
)
    raw_modules = raw_module_union(catalog, library)
    return module_closure(closure, raw_modules)
end

"""
    CompressedLibraryState(frontier, closure)

Strongly typed operational-frontier/generative-closure pair.  This mirrors
Lean `InnovationState` and intentionally stores frontier values rather than
maximizing strategy IDs.
"""
struct CompressedLibraryState{B,M,T<:Real}
    frontier::OperationalProfile{B,T}
    closure::ModuleSet{M}
end

Base.:(==)(left::CompressedLibraryState, right::CompressedLibraryState) =
    left.frontier == right.frontier && left.closure == right.closure
Base.hash(state::CompressedLibraryState, seed::UInt) =
    hash((:CompressedLibraryState, state.frontier, state.closure), seed)

"""Alias matching the frozen Lean name `InnovationState`."""
const InnovationState = CompressedLibraryState

"""
    compressed_library_state(catalog, closure, library)

Compress a raw library to its exact frontier--closure state.  This is Lean
`compressedLibraryState`.
"""
function compressed_library_state(
    catalog::StrategyCatalog,
    closure::GenerativeClosure,
    library::RawLibrary,
)
    return CompressedLibraryState(
        operational_frontier(catalog, library),
        generative_closure(catalog, closure, library),
    )
end

"""Short canonical alias for `compressed_library_state`."""
compressed_state(
    catalog::StrategyCatalog,
    closure::GenerativeClosure,
    library::RawLibrary,
) = compressed_library_state(catalog, closure, library)

"""
    operationally_dominated(catalog, library, strategy_id)

Check the insertion-side F0 predicate `OperationallyRedundant`: the existing
frontier dominates the candidate profile at every belief.
"""
function operationally_dominated(
    catalog::StrategyCatalog,
    library::RawLibrary,
    strategy_id::StrategyId,
)
    candidate = operational_profile(catalog, strategy_id)
    current_frontier = operational_frontier(catalog, library)
    return all(belief -> candidate[belief] <= current_frontier[belief], catalog.beliefs)
end

"""
    operationally_redundant(catalog, library, strategy_id)

Deletion-side F3 predicate: deleting a resolved noninactive strategy leaves
the complete operational frontier unchanged.  This mirrors Lean
`operationallyRedundant` in `Compression/SafeDeletion.lean`.
"""
function operationally_redundant(
    catalog::StrategyCatalog,
    library::RawLibrary,
    strategy_id::StrategyId,
)
    erased = delete_strategy(catalog, library, strategy_id)
    return operational_frontier(catalog, erased) ==
           operational_frontier(catalog, library)
end

"""
    generatively_redundant(catalog, closure, library, strategy_id)

Deletion-side F3 predicate: deleting a resolved noninactive strategy leaves
the complete generative closure unchanged.  This mirrors Lean
`generativelyRedundant` in `Compression/SafeDeletion.lean`.
"""
function generatively_redundant(
    catalog::StrategyCatalog,
    closure::GenerativeClosure,
    library::RawLibrary,
    strategy_id::StrategyId,
)
    erased = delete_strategy(catalog, library, strategy_id)
    return generative_closure(catalog, closure, erased) ==
           generative_closure(catalog, closure, library)
end

"""Check equality of all current frontier rewards (`OperationallyEquivalent`)."""
operationally_equivalent(
    catalog::StrategyCatalog,
    left::RawLibrary,
    right::RawLibrary,
) = operational_frontier(catalog, left) == operational_frontier(catalog, right)

"""
    FiniteResearchSemantics(catalog, belief_kernel, projects,
                            research_transition, discount)

Deprecated exact primitive F1 research semantics. The transition callable receives
`(belief, compressed_state, project)` and must return an exact `RatProb` on
ambient compressed states. This compatibility adapter deliberately retains
the primitive, cost-free Lean `FiniteResearchSemantics`; new models must use
[`RawInnovationProcess`](@ref).
"""
struct FiniteResearchSemantics{B,P,M,F}
    belief_kernel::MarkovKernel{B,ExactRational}
    projects::Tuple{Vararg{ResearchProject{P,M}}}
    research_transition::F
    discount::ExactRational
    module_universe::ModuleSet{M}
end

function FiniteResearchSemantics(
    catalog::StrategyCatalog{S,B,M,ExactRational},
    belief_kernel::MarkovKernel{B,ExactRational},
    projects::AbstractVector{ResearchProject{P,M}},
    research_transition::F,
    discount,
) where {S,B,M,P,F}
    Base.depwarn(
        "FiniteResearchSemantics is the deprecated cost-free primitive-transition " *
        "adapter. Use RawInnovationProcess for raw-model generation and transitions.",
        :FiniteResearchSemantics,
    )
    belief_kernel.space == catalog.beliefs ||
        throw(ArgumentError("the belief kernel and strategy catalog must share a belief space"))
    validate_projects(catalog, projects)
    validated_discount = discount_factor(discount; mode = ExactMode())
    return FiniteResearchSemantics{B,P,M,F}(
        belief_kernel,
        Tuple(projects),
        research_transition,
        validated_discount,
        ModuleSet(collect(catalog.modules)),
    )
end

function _validate_innovation_state(
    semantics::FiniteResearchSemantics{B,P,M},
    state::CompressedLibraryState{B,M,ExactRational},
) where {B,P,M}
    state.frontier.space == semantics.belief_kernel.space ||
        throw(ArgumentError("a compressed state uses an unresolved belief space"))
    issubset(state.closure, semantics.module_universe) ||
        throw(ArgumentError("a compressed state contains an unresolved module reference"))
    return state
end

"""Evaluate and validate one primitive exact research-transition law."""
function research_distribution(
    semantics::FiniteResearchSemantics{B,P,M},
    belief::Belief{B},
    state::CompressedLibraryState{B,M,ExactRational},
    project::ResearchProject{P,M},
) where {B,P,M}
    belief in semantics.belief_kernel.space ||
        throw(ArgumentError("unresolved belief reference: $belief"))
    project in semantics.projects ||
        throw(ArgumentError("unresolved research-project reference: $(project.id)"))
    _validate_innovation_state(semantics, state)
    distribution = semantics.research_transition(belief, state, project)
    distribution isa RatProb ||
        throw(ArgumentError("an exact research transition must return RatProb"))
    for next_state in distribution.outcomes
        next_state isa CompressedLibraryState{B,M,ExactRational} || throw(
            ArgumentError("a research transition returned an ill-typed compressed state"),
        )
        _validate_innovation_state(semantics, next_state)
    end
    return distribution
end

"""
    dynamic_innovation_equivalent(semantics, catalog, closure, left, right)

Exact finite-model decision procedure for Lean `DynamicInnovationEquivalent`:
the two libraries have equal current frontiers and equal primitive research
transition distributions at every belief and project.  No Float64 overload is
provided, so approximate simulation equality cannot be mistaken for the
theorem relation.
"""
function dynamic_innovation_equivalent(
    semantics::FiniteResearchSemantics{B,P,M},
    catalog::StrategyCatalog{S,B,M,ExactRational},
    closure::GenerativeClosure{M},
    left::RawLibrary{S},
    right::RawLibrary{S},
) where {S,B,M,P}
    operationally_equivalent(catalog, left, right) || return false
    left_state = compressed_library_state(catalog, closure, left)
    right_state = compressed_library_state(catalog, closure, right)
    for belief in catalog.beliefs, project in semantics.projects
        research_distribution(semantics, belief, left_state, project) ==
        research_distribution(semantics, belief, right_state, project) || return false
    end
    return true
end
