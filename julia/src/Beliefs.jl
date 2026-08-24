"""
    FiniteBeliefSpace(states)

Nonempty finite collection of unique typed belief-grid labels.  A `Belief`
is a grid label, not a floating posterior vector, matching Lean
`FiniteModel.Belief` and the frozen model specification.
"""
struct FiniteBeliefSpace{B}
    states::Tuple{Vararg{Belief{B}}}

    function FiniteBeliefSpace{B}(states::Tuple{Vararg{Belief{B}}}) where {B}
        isempty(states) && throw(ArgumentError("a finite belief space must be nonempty"))
        _require_unique(states, "belief-state IDs")
        return new{B}(states)
    end
end

FiniteBeliefSpace(states::AbstractVector{Belief{B}}) where {B} =
    FiniteBeliefSpace{B}(Tuple(states))
FiniteBeliefSpace(ids::AbstractVector{B}) where {B} =
    FiniteBeliefSpace(Belief{B}[Belief(id) for id in ids])

Base.length(space::FiniteBeliefSpace) = length(space.states)
Base.iterate(space::FiniteBeliefSpace, state...) = iterate(space.states, state...)
Base.eltype(::Type{FiniteBeliefSpace{B}}) where {B} = Belief{B}
Base.in(belief::Belief, space::FiniteBeliefSpace) = belief in space.states
Base.:(==)(left::FiniteBeliefSpace{B}, right::FiniteBeliefSpace{B}) where {B} =
    left.states == right.states
Base.hash(space::FiniteBeliefSpace, seed::UInt) = hash((:FiniteBeliefSpace, space.states), seed)

"""Return the one-based position of a belief, rejecting unresolved labels."""
function belief_index(space::FiniteBeliefSpace, belief::Belief)
    index = findfirst(isequal(belief), space.states)
    isnothing(index) && throw(ArgumentError("unresolved belief reference: $belief"))
    return index
end

"""
    discount_factor(value; mode=ExactMode())

Validate and return a discount factor satisfying `0 ≤ β < 1`.  Exact mode is
the default and rejects floating-point inputs; `Float64Mode()` must be selected
explicitly for simulation data.
"""
function discount_factor(value; mode::ArithmeticMode = ExactMode())
    discount = _coerce_scalar(mode, value)
    isfinite(discount) || throw(ArgumentError("the discount factor must be finite"))
    0 <= discount < 1 ||
        throw(ArgumentError("the discount factor must satisfy 0 ≤ discount < 1"))
    return discount
end

"""
    MarkovKernel(space, probabilities; mode=ExactMode(), atol=1e-12)

Finite row-stochastic Markov kernel on a `FiniteBeliefSpace`.  Exact mode
stores `Rational{BigInt}` entries and requires every row to sum exactly to one.
Float mode is explicit and uses `atol` only for row-normalization validation;
it never serves as theorem evidence.  This mirrors Lean
`FiniteResearchSemantics.beliefKernel`.
"""
struct MarkovKernel{B,T<:Real}
    space::FiniteBeliefSpace{B}
    rows::Tuple{Vararg{Tuple{Vararg{T}}}}
end

function MarkovKernel(
    space::FiniteBeliefSpace{B},
    probabilities::AbstractMatrix;
    mode::ArithmeticMode = ExactMode(),
    atol::Real = 1e-12,
) where {B}
    state_count = length(space)
    size(probabilities) == (state_count, state_count) || throw(
        DimensionMismatch(
            "a Markov kernel on $state_count beliefs must be a " *
            "$state_count×$state_count matrix",
        ),
    )
    atol >= 0 || throw(ArgumentError("the floating validation tolerance must be nonnegative"))

    coefficient_type = _coefficient_type(mode)
    rows = Vector{Tuple{Vararg{coefficient_type}}}(undef, state_count)
    for row_index in 1:state_count
        row = coefficient_type[
            _coerce_scalar(mode, probabilities[row_index, column_index])
            for column_index in 1:state_count
        ]
        all(isfinite, row) ||
            throw(ArgumentError("transition probabilities must be finite"))
        all(probability -> probability >= 0, row) ||
            throw(ArgumentError("transition probabilities must be nonnegative"))
        row_sum = sum(row; init = zero(coefficient_type))
        normalized = mode isa ExactMode ? row_sum == one(coefficient_type) :
                     isapprox(row_sum, one(coefficient_type); atol = atol, rtol = 0)
        normalized || throw(
            ArgumentError("transition row $row_index must sum to one (found $row_sum)"),
        )
        rows[row_index] = Tuple(row)
    end
    return MarkovKernel{B,coefficient_type}(space, Tuple(rows))
end

"""Return one validated Markov transition probability."""
function transition_probability(
    kernel::MarkovKernel,
    current::Belief,
    next::Belief,
)
    return kernel.rows[belief_index(kernel.space, current)][belief_index(kernel.space, next)]
end

"""Return a copy of one complete transition row in belief-space order."""
function transition_row(kernel::MarkovKernel, current::Belief)
    return collect(kernel.rows[belief_index(kernel.space, current)])
end

"""
    transition_distribution(kernel, current)

Return the exact `RatProb` represented by a rational Markov row.  No method is
provided for `Float64` kernels because approximate rows are simulation data,
not exact theorem fixtures.
"""
function transition_distribution(
    kernel::MarkovKernel{B,ExactRational},
    current::Belief{B},
) where {B}
    return RatProb(collect(kernel.space.states), transition_row(kernel, current))
end
