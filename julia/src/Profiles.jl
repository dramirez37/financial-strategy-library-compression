"""
    OperationalProfile(space, values; mode=ExactMode())

Pointwise operational payoff table on a finite belief space.  Exact rational
storage is the default.  This is the Julia counterpart of Lean
`OperationalProfile` and `StrategyCatalog.operationalProfile`.
"""
struct OperationalProfile{B,T<:Real}
    space::FiniteBeliefSpace{B}
    values::Tuple{Vararg{T}}
end

function OperationalProfile(
    space::FiniteBeliefSpace{B},
    values::AbstractVector;
    mode::ArithmeticMode = ExactMode(),
) where {B}
    length(values) == length(space) || throw(
        DimensionMismatch(
            "an operational profile needs one value for each of $(length(space)) beliefs",
        ),
    )
    coefficient_type = _coefficient_type(mode)
    converted = coefficient_type[_coerce_scalar(mode, value) for value in values]
    all(isfinite, converted) ||
        throw(ArgumentError("operational profile values must be finite"))
    return OperationalProfile{B,coefficient_type}(space, Tuple(converted))
end

function OperationalProfile(
    value::F,
    space::FiniteBeliefSpace;
    mode::ArithmeticMode = ExactMode(),
) where {F}
    return OperationalProfile(space, [value(belief) for belief in space]; mode)
end

Base.length(profile::OperationalProfile) = length(profile.values)
Base.getindex(profile::OperationalProfile, belief::Belief) =
    profile.values[belief_index(profile.space, belief)]
Base.:(==)(left::OperationalProfile, right::OperationalProfile) =
    left.space == right.space && left.values == right.values
Base.hash(profile::OperationalProfile, seed::UInt) =
    hash((:OperationalProfile, profile.space, profile.values), seed)

"""
    Strategy(id, operational_profile, modules)

Immutable strategy catalog row: a typed identifier, exact or simulation-mode
operational profile, and finite module set.  It mirrors the data fields of
Lean `StrategyCatalog`.
"""
struct Strategy{S,B,M,T<:Real}
    id::StrategyId{S}
    operational_profile::OperationalProfile{B,T}
    modules::ModuleSet{M}
end

Strategy(id, profile::OperationalProfile{B,T}, modules::ModuleSet{M}) where {B,T,M} =
    Strategy(StrategyId(id), profile, modules)
Base.:(==)(left::Strategy, right::Strategy) =
    left.id == right.id &&
    left.operational_profile == right.operational_profile &&
    left.modules == right.modules
Base.hash(strategy_row::Strategy, seed::UInt) = hash(
    (
        :Strategy,
        strategy_row.id,
        strategy_row.operational_profile,
        strategy_row.modules,
    ),
    seed,
)

"""
    StrategyCatalog(beliefs, modules, strategies, inactive_strategy)

Validated finite strategy and module catalog.  Strategy IDs and module IDs
must be unique, every module reference must resolve, every profile must use the
catalog belief space, and the inactive row must have the zero profile and no
modules.  These checks implement Lean `StrategyCatalog.inactiveProfile` and
`inactiveModules` as constructor invariants.
"""
struct StrategyCatalog{S,B,M,T<:Real}
    beliefs::FiniteBeliefSpace{B}
    modules::Tuple{Vararg{GenerativeModule{M}}}
    strategies::Tuple{Vararg{Strategy{S,B,M,T}}}
    inactive_strategy::StrategyId{S}
end

function StrategyCatalog(
    beliefs::FiniteBeliefSpace{B},
    modules::AbstractVector{GenerativeModule{M}},
    strategies::AbstractVector{Strategy{S,B,M,T}},
    inactive_strategy::StrategyId{S},
) where {S,B,M,T<:Real}
    isempty(modules) &&
        throw(ArgumentError("the frozen finite model requires a nonempty module carrier"))
    isempty(strategies) &&
        throw(ArgumentError("the frozen finite model requires a nonempty strategy carrier"))
    _require_unique([module_row.id for module_row in modules], "module IDs in the catalog")
    _require_unique([strategy_row.id for strategy_row in strategies], "strategy IDs in the catalog")

    universe = ModuleSet(modules)
    for strategy_row in strategies
        strategy_row.operational_profile.space == beliefs || throw(
            ArgumentError(
                "strategy $(strategy_row.id) uses a different belief space from its catalog",
            ),
        )
        issubset(strategy_row.modules, universe) || throw(
            ArgumentError("strategy $(strategy_row.id) has an unresolved module reference"),
        )
    end

    inactive_index = findfirst(
        strategy_row -> strategy_row.id == inactive_strategy,
        strategies,
    )
    isnothing(inactive_index) &&
        throw(ArgumentError("the inactive strategy reference must resolve in the catalog"))
    inactive = strategies[inactive_index]
    all(iszero, inactive.operational_profile.values) ||
        throw(ArgumentError("the inactive strategy must have a zero operational profile"))
    isempty(inactive.modules) ||
        throw(ArgumentError("the inactive strategy must supply no modules"))

    return StrategyCatalog{S,B,M,T}(
        beliefs,
        Tuple(modules),
        Tuple(strategies),
        inactive_strategy,
    )
end

"""Resolve and return one immutable strategy row from a catalog."""
function strategy(catalog::StrategyCatalog, strategy_id::StrategyId)
    index = findfirst(row -> row.id == strategy_id, catalog.strategies)
    isnothing(index) &&
        throw(ArgumentError("unresolved strategy reference: $strategy_id"))
    return catalog.strategies[index]
end

"""Return a strategy's pointwise operational profile after ID resolution."""
operational_profile(catalog::StrategyCatalog, strategy_id::StrategyId) =
    strategy(catalog, strategy_id).operational_profile

"""Return a strategy's finite module set after ID resolution."""
strategy_modules(catalog::StrategyCatalog, strategy_id::StrategyId) =
    strategy(catalog, strategy_id).modules

"""
    RawLibrary(catalog, strategy_ids)

Construct an admissible library with all strategy references resolved against
`catalog` and with the catalog's inactive strategy present.
"""
function RawLibrary(
    catalog::StrategyCatalog{S},
    strategy_ids::AbstractVector{StrategyId{S}},
) where {S}
    library = RawLibrary(strategy_ids, catalog.inactive_strategy)
    return validate_library(catalog, library)
end

"""Validate that a raw library belongs to a strategy catalog."""
function validate_library(catalog::StrategyCatalog, library::RawLibrary)
    library.inactive_strategy == catalog.inactive_strategy ||
        throw(ArgumentError("the library and catalog inactive strategies disagree"))
    for strategy_id in library
        strategy(catalog, strategy_id)
    end
    return library
end

"""Validate nonempty, unique, and module-resolved research-project rows."""
function validate_projects(
    catalog::StrategyCatalog,
    projects::AbstractVector{<:ResearchProject},
)
    isempty(projects) &&
        throw(ArgumentError("the frozen finite model requires a nonempty project carrier"))
    throw(ArgumentError("research projects must share the catalog module-ID type"))
end

function validate_projects(
    catalog::StrategyCatalog{S,B,M},
    projects::AbstractVector{ResearchProject{P,M}},
) where {S,B,M,P}
    isempty(projects) &&
        throw(ArgumentError("the frozen finite model requires a nonempty project carrier"))
    _require_unique([project.id for project in projects], "research-project IDs")
    universe = ModuleSet(collect(catalog.modules))
    for project in projects
        issubset(project.requirements, universe) ||
            throw(ArgumentError("project $(project.id) has an unresolved module reference"))
    end
    return projects
end
