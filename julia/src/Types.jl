"""
    ExactRational

Arbitrary-precision rational scalar used by every theorem fixture.  This is
the Julia counterpart of Lean's `ℚ` in `Basic/Probability.lean`.
"""
const ExactRational = Rational{BigInt}

"""Abstract marker for an explicitly selected arithmetic mode."""
abstract type ArithmeticMode end

"""Exact arbitrary-precision rational arithmetic for theorem fixtures."""
struct ExactMode <: ArithmeticMode end

"""IEEE `Float64` arithmetic, reserved for larger numerical simulations."""
struct Float64Mode <: ArithmeticMode end

"""
    exact_rational(value)

Convert an integer, rational, or canonical `"numerator//denominator"` string
to `ExactRational`.  Floating-point inputs are rejected so theorem fixtures
cannot silently inherit an approximation.
"""
exact_rational(value::Integer) = BigInt(value) // BigInt(1)
exact_rational(value::Rational) =
    BigInt(numerator(value)) // BigInt(denominator(value))

function exact_rational(value::AbstractString)
    token = strip(value)
    isempty(token) && throw(ArgumentError("an exact rational token cannot be empty"))
    pieces = split(token, "//"; keepempty = true)
    if length(pieces) == 1
        return parse(BigInt, strip(only(pieces))) // BigInt(1)
    elseif length(pieces) == 2
        numerator_value = parse(BigInt, strip(pieces[1]))
        denominator_value = parse(BigInt, strip(pieces[2]))
        iszero(denominator_value) &&
            throw(ArgumentError("an exact rational denominator cannot be zero"))
        return numerator_value // denominator_value
    end
    throw(ArgumentError("invalid exact rational token: $(repr(value))"))
end

exact_rational(value::AbstractFloat) = throw(
    ArgumentError(
        "floating-point values cannot be promoted to theorem-fixture rationals; " *
        "provide an integer, rational, or exact string",
    ),
)

_coerce_scalar(::ExactMode, value) = exact_rational(value)
_coerce_scalar(::Float64Mode, value::Real) = Float64(value)
_coefficient_type(::ExactMode) = ExactRational
_coefficient_type(::Float64Mode) = Float64

function _require_unique(values, label::AbstractString)
    length(Set(values)) == length(values) ||
        throw(ArgumentError("$label must be unique"))
    return nothing
end

"""Typed label for one finite belief-grid state (`FiniteModel.Belief`)."""
struct Belief{I}
    id::I
end

"""Typed finite strategy identifier (`FiniteModel.StrategyId`)."""
struct StrategyId{I}
    id::I
end

"""Typed finite module identifier (`FiniteModel.ModuleId`)."""
struct ModuleId{I}
    id::I
end

"""Typed finite research-project identifier (`FiniteModel.ResearchProject`)."""
struct ResearchProjectId{I}
    id::I
end

for Identifier in (Belief, StrategyId, ModuleId, ResearchProjectId)
    @eval begin
        Base.:(==)(left::$Identifier{I}, right::$Identifier{I}) where {I} =
            left.id == right.id
        Base.hash(value::$Identifier, seed::UInt) =
            hash(($(QuoteNode(Identifier)), value.id), seed)
    end
end

Base.show(io::IO, value::Belief) = print(io, "Belief(", repr(value.id), ")")
Base.show(io::IO, value::StrategyId) = print(io, "StrategyId(", repr(value.id), ")")
Base.show(io::IO, value::ModuleId) = print(io, "ModuleId(", repr(value.id), ")")
Base.show(io::IO, value::ResearchProjectId) =
    print(io, "ResearchProjectId(", repr(value.id), ")")

"""
    GenerativeModule(id)

Immutable catalog row for a finite generative capability.  Lean treats
modules as identifiers; the wrapper prevents cross-domain identifier mixups.
"""
struct GenerativeModule{I}
    id::ModuleId{I}
end

GenerativeModule(id) = GenerativeModule(ModuleId(id))
Base.:(==)(left::GenerativeModule, right::GenerativeModule) = left.id == right.id
Base.hash(module_row::GenerativeModule, seed::UInt) =
    hash((:GenerativeModule, module_row.id), seed)

"""
    ModuleSet{I}

Immutable finite set of typed module identifiers.  Equality and hashing are
set-based, matching Lean `Finset ModuleId` rather than input order.
"""
struct ModuleSet{I}
    members::Tuple{Vararg{ModuleId{I}}}

    function ModuleSet{I}(members::Tuple{Vararg{ModuleId{I}}}) where {I}
        _require_unique(members, "module IDs in a module set")
        return new{I}(members)
    end
end

ModuleSet(values::AbstractVector{ModuleId{I}}) where {I} = ModuleSet{I}(Tuple(values))
ModuleSet(values::AbstractVector{GenerativeModule{I}}) where {I} =
    ModuleSet(ModuleId{I}[value.id for value in values])
ModuleSet{I}() where {I} = ModuleSet{I}(())

Base.length(modules::ModuleSet) = length(modules.members)
Base.isempty(modules::ModuleSet) = isempty(modules.members)
Base.iterate(modules::ModuleSet, state...) = iterate(modules.members, state...)
Base.eltype(::Type{ModuleSet{I}}) where {I} = ModuleId{I}
Base.in(module_id::ModuleId, modules::ModuleSet) = module_id in modules.members
Base.issubset(left::ModuleSet, right::ModuleSet) =
    all(module_id -> module_id in right, left)

function Base.union(left::ModuleSet{I}, right::ModuleSet{I}) where {I}
    members = ModuleId{I}[left.members...]
    for module_id in right
        module_id in left || push!(members, module_id)
    end
    return ModuleSet(members)
end

Base.:(==)(left::ModuleSet{I}, right::ModuleSet{I}) where {I} =
    length(left) == length(right) && issubset(left, right)

function Base.hash(modules::ModuleSet, seed::UInt)
    unordered_hash = foldl(xor, (hash(module_id) for module_id in modules); init = UInt(0))
    return hash((:ModuleSet, length(modules), unordered_hash), seed)
end

"""
    ResearchProject(id, requirements)

Strongly typed finite research project with its frozen finite prerequisite
module set.  Dynamic innovation equivalence uses the identifier as the
project carrier; generation, verification, and costs remain later layers.
"""
struct ResearchProject{P,M}
    id::ResearchProjectId{P}
    requirements::ModuleSet{M}
end

ResearchProject(id, requirements::ModuleSet{M}) where {M} =
    ResearchProject(ResearchProjectId(id), requirements)
Base.:(==)(left::ResearchProject, right::ResearchProject) =
    left.id == right.id && left.requirements == right.requirements
Base.hash(project::ResearchProject, seed::UInt) =
    hash((:ResearchProject, project.id, project.requirements), seed)

"""
    RawLibrary(strategy_ids, inactive_strategy)

Finite set of verified strategy identifiers containing the distinguished
inactive strategy.  This mirrors Lean `Library`; catalog-reference validation
is performed by the catalog-aware constructor in `Profiles.jl`.
"""
struct RawLibrary{S}
    strategies::Tuple{Vararg{StrategyId{S}}}
    inactive_strategy::StrategyId{S}

    function RawLibrary{S}(
        strategies::Tuple{Vararg{StrategyId{S}}},
        inactive_strategy::StrategyId{S},
    ) where {S}
        _require_unique(strategies, "strategy IDs in a raw library")
        inactive_strategy in strategies ||
            throw(ArgumentError("every raw library must contain the inactive strategy"))
        return new{S}(strategies, inactive_strategy)
    end
end

RawLibrary(
    strategies::AbstractVector{StrategyId{S}},
    inactive_strategy::StrategyId{S},
) where {S} = RawLibrary{S}(Tuple(strategies), inactive_strategy)

Base.length(library::RawLibrary) = length(library.strategies)
Base.iterate(library::RawLibrary, state...) = iterate(library.strategies, state...)
Base.eltype(::Type{RawLibrary{S}}) where {S} = StrategyId{S}
Base.in(strategy_id::StrategyId, library::RawLibrary) =
    strategy_id in library.strategies
Base.issubset(left::RawLibrary, right::RawLibrary) =
    all(strategy_id -> strategy_id in right, left)
Base.:(==)(left::RawLibrary{S}, right::RawLibrary{S}) where {S} =
    left.inactive_strategy == right.inactive_strategy &&
    length(left) == length(right) && issubset(left, right)

function Base.hash(library::RawLibrary, seed::UInt)
    unordered_hash =
        foldl(xor, (hash(strategy_id) for strategy_id in library); init = UInt(0))
    return hash(
        (:RawLibrary, library.inactive_strategy, length(library), unordered_hash),
        seed,
    )
end

"""Alias matching the frozen Lean and notation-registry name `Library`."""
const Library = RawLibrary

"""
    RatProb(outcomes, probabilities)

Exact finitely supported rational probability distribution.  Probabilities
are converted to `ExactRational`, checked for nonnegativity, and required to
sum exactly to one.  Equality is extensional in outcome mass, as for Lean
`RatProb.mass`; zero-mass and input-order differences are ignored.
"""
struct RatProb{O}
    outcomes::Tuple{Vararg{O}}
    probabilities::Tuple{Vararg{ExactRational}}

    function RatProb{O}(
        outcomes::Tuple{Vararg{O}},
        probabilities::Tuple{Vararg{ExactRational}},
    ) where {O}
        length(outcomes) == length(probabilities) ||
            throw(DimensionMismatch("outcomes and probabilities must have equal length"))
        _require_unique(outcomes, "outcomes in an exact distribution")
        all(probability -> probability >= 0, probabilities) ||
            throw(ArgumentError("exact probabilities must be nonnegative"))
        sum(probabilities; init = exact_rational(0)) == exact_rational(1) ||
            throw(ArgumentError("exact probabilities must sum exactly to one"))
        return new{O}(outcomes, probabilities)
    end
end

function RatProb(outcomes::AbstractVector{O}, probabilities::AbstractVector) where {O}
    exact_probabilities = ExactRational[exact_rational(value) for value in probabilities]
    return RatProb{O}(Tuple(outcomes), Tuple(exact_probabilities))
end

"""Return the exact probability assigned by a `RatProb` to one outcome."""
function probability(distribution::RatProb, outcome)
    index = findfirst(isequal(outcome), distribution.outcomes)
    return isnothing(index) ? exact_rational(0) : distribution.probabilities[index]
end

"""Evaluate an exact rational-valued function under a finite `RatProb`."""
function expectation(distribution::RatProb, value::F) where {F}
    result = exact_rational(0)
    for (outcome, mass) in zip(distribution.outcomes, distribution.probabilities)
        result += mass * exact_rational(value(outcome))
    end
    return result
end

"""Construct the exact point mass at one outcome (`RatProb.dirac` in Lean)."""
dirac(outcome) = RatProb([outcome], [exact_rational(1)])

function Base.:(==)(left::RatProb{O}, right::RatProb{O}) where {O}
    outcomes = collect(left.outcomes)
    for outcome in right.outcomes
        outcome in outcomes || push!(outcomes, outcome)
    end
    return all(outcome -> probability(left, outcome) == probability(right, outcome), outcomes)
end

function Base.hash(distribution::RatProb, seed::UInt)
    nonzero_mass = Dict(
        outcome => probability
        for (outcome, probability) in
            zip(distribution.outcomes, distribution.probabilities) if !iszero(probability)
    )
    return hash((:RatProb, nonzero_mass), seed)
end
