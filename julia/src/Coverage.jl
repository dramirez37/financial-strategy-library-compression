using LinearAlgebra: I

"""
    OrderedBeliefGrid(beliefs, coordinates)

Finite belief space with a strictly increasing real coordinate for each state.
The tuple order is the order used by connected-component, threshold, and
boundary calculations.  This is the executable counterpart of Lean
`Coverage.FiniteOrderedBeliefGrid`.
"""
struct OrderedBeliefGrid{B,X<:Real}
    beliefs::FiniteBeliefSpace{B}
    coordinates::Tuple{Vararg{X}}

    function OrderedBeliefGrid{B,X}(
        beliefs::FiniteBeliefSpace{B},
        coordinates::Tuple{Vararg{X}},
    ) where {B,X<:Real}
        length(coordinates) == length(beliefs) || throw(
            DimensionMismatch("an ordered grid needs one coordinate per belief"),
        )
        all(isfinite, coordinates) ||
            throw(ArgumentError("belief-grid coordinates must be finite"))
        if length(coordinates) > 1
            all(
                coordinates[index] < coordinates[index + 1] for
                index in 1:(length(coordinates) - 1)
            ) || throw(
                ArgumentError("belief-grid coordinates must be strictly increasing"),
            )
        end
        return new{B,X}(beliefs, coordinates)
    end
end

function OrderedBeliefGrid(
    beliefs::FiniteBeliefSpace{B},
    coordinates::AbstractVector{X},
) where {B,X<:Real}
    return OrderedBeliefGrid{B,X}(beliefs, Tuple(coordinates))
end

Base.length(grid::OrderedBeliefGrid) = length(grid.beliefs)
Base.getindex(grid::OrderedBeliefGrid, index::Integer) =
    (belief = grid.beliefs.states[index], coordinate = grid.coordinates[index])

_coverage_mode(::Type{ExactRational}) = ExactMode()
_coverage_mode(::Type{Float64}) = Float64Mode()

function _coverage_scalar(::Type{T}, value) where {T<:Union{ExactRational,Float64}}
    converted = _coerce_scalar(_coverage_mode(T), value)
    isfinite(converted) || throw(ArgumentError("coverage inputs must be finite"))
    return converted
end

function _unit_interval(
    ::Type{T},
    value,
    label::AbstractString,
) where {T<:Union{ExactRational,Float64}}
    converted = _coverage_scalar(T, value)
    0 <= converted <= 1 ||
        throw(ArgumentError("$label must lie in [0, 1]"))
    return converted
end

function _kernel_matrix(kernel::MarkovKernel{B,T}) where {B,T}
    count = length(kernel.space)
    result = Matrix{T}(undef, count, count)
    for row in 1:count, column in 1:count
        result[row, column] = kernel.rows[row][column]
    end
    return result
end

function _coverage_vector(
    ::Type{T},
    values::AbstractVector,
    count::Integer,
    label::AbstractString,
) where {T<:Union{ExactRational,Float64}}
    length(values) == count ||
        throw(DimensionMismatch("$label must have length $count"))
    return T[_coverage_scalar(T, value) for value in values]
end

"""
    finite_discounted_occupation(kernel, discount, horizon; survival=1)

Compute the exact finite sum
`I + qP + ⋯ + q^(horizon-1)P^(horizon-1)`, where
`q = discount * survival`.  This matches Lean
`Coverage.discountedOccupationWeight` when occupation at date `t` is `P^t`.
Both factors may equal one because the horizon is finite.
"""
function finite_discounted_occupation(
    kernel::MarkovKernel{B,T},
    discount,
    horizon::Integer;
    survival = 1,
) where {B,T<:Union{ExactRational,Float64}}
    horizon >= 0 || throw(ArgumentError("horizon must be nonnegative"))
    beta = _unit_interval(T, discount, "discount")
    survival_probability = _unit_interval(T, survival, "candidate survival")
    effective_discount = beta * survival_probability
    transition = _kernel_matrix(kernel)
    count = length(kernel.space)
    total = zeros(T, count, count)
    term = Matrix{T}(I, count, count)
    for _ in 1:horizon
        total .+= term
        term = effective_discount .* (term * transition)
    end
    return total
end

"""
    discounted_occupation_matrix(kernel, discount; survival=1)

Compute the infinite discounted occupation matrix
`U = I + qP + q²P² + ⋯ = (I-qP)⁻¹`, with
`q = discount * survival < 1`.  Rational kernels use an exact
`Rational{BigInt}` linear solve; Float64 kernels use numerical linear algebra.
This infinite extension is computational and sits beyond Lean S4's finite sum.
"""
function discounted_occupation_matrix(
    kernel::MarkovKernel{B,T},
    discount;
    survival = 1,
) where {B,T<:Union{ExactRational,Float64}}
    beta = _unit_interval(T, discount, "discount")
    survival_probability = _unit_interval(T, survival, "candidate survival")
    effective_discount = beta * survival_probability
    effective_discount < one(T) || throw(
        ArgumentError("discount times survival must be strictly below one"),
    )
    transition = _kernel_matrix(kernel)
    count = length(kernel.space)
    identity_matrix = Matrix{T}(I, count, count)
    return (identity_matrix - effective_discount .* transition) \ identity_matrix
end

"""
    discounted_gap_solve(kernel, gap, discount; survival=1)

Solve `(I-qP) \\ gap` directly without forming the full occupation matrix.
For exact kernels this is an exact rational solve.  It is algebraically equal
to `discounted_occupation_matrix(kernel, discount) * gap`.
"""
function discounted_gap_solve(
    kernel::MarkovKernel{B,T},
    gap::AbstractVector,
    discount;
    survival = 1,
) where {B,T<:Union{ExactRational,Float64}}
    beta = _unit_interval(T, discount, "discount")
    survival_probability = _unit_interval(T, survival, "candidate survival")
    effective_discount = beta * survival_probability
    effective_discount < one(T) || throw(
        ArgumentError("discount times survival must be strictly below one"),
    )
    values = _coverage_vector(T, gap, length(kernel.space), "gap")
    transition = _kernel_matrix(kernel)
    count = length(kernel.space)
    return (Matrix{T}(I, count, count) - effective_discount .* transition) \ values
end

"""
    candidate_gap(candidate, frontier)

Compute the certified pointwise gap `max(candidate-frontier, 0)`, mirroring
Lean `Coverage.certifiedGap` and `InnovationEquation.frontierGap`.
"""
function candidate_gap(
    candidate::OperationalProfile{B,T},
    current_frontier::OperationalProfile{B,T},
) where {B,T<:Real}
    candidate.space == current_frontier.space ||
        throw(ArgumentError("candidate and frontier must use the same belief space"))
    values = T[
        max(candidate.values[index] - current_frontier.values[index], zero(T)) for
        index in eachindex(candidate.values)
    ]
    return OperationalProfile{B,T}(candidate.space, Tuple(values))
end

"""
    project_gap(candidates, frontier)

Sum the certified gaps of a nonempty finite candidate collection.  This is the
Julia counterpart of the aggregate `projectGap` used by Lean C2.
"""
function project_gap(
    candidates::AbstractVector{OperationalProfile{B,T}},
    current_frontier::OperationalProfile{B,T},
) where {B,T<:Real}
    isempty(candidates) &&
        throw(ArgumentError("a project gap requires at least one candidate"))
    values = zeros(T, length(current_frontier))
    for candidate in candidates
        certified = candidate_gap(candidate, current_frontier)
        values .+= collect(certified.values)
    end
    return OperationalProfile{B,T}(current_frontier.space, Tuple(values))
end

"""
    coverage_potential(occupation, gap)

Multiply discounted occupation weights by a future-belief gap vector.  This
is Lean `Coverage.coveragePotential` specialized to Markov occupation rows.
"""
function coverage_potential(
    occupation::AbstractMatrix{T},
    gap::AbstractVector,
) where {T<:Union{ExactRational,Float64}}
    size(occupation, 1) == size(occupation, 2) ||
        throw(DimensionMismatch("occupation matrix must be square"))
    values = _coverage_vector(T, gap, size(occupation, 2), "gap")
    return occupation * values
end

function coverage_potential(
    occupation::AbstractMatrix{T},
    gap::OperationalProfile{B,T},
) where {B,T<:Union{ExactRational,Float64}}
    values = coverage_potential(occupation, collect(gap.values))
    size(occupation, 1) == length(gap.space) ||
        throw(DimensionMismatch("occupation rows must match the gap belief space"))
    return OperationalProfile{B,T}(gap.space, Tuple(values))
end

"""
    finite_coverage_potential(kernel, gap, discount, horizon; survival=1)

Compute Lean S4's finite discounted, survival-adjusted coverage potential with
Markov occupation `P^t` and dates `t=0,…,horizon-1`.
"""
function finite_coverage_potential(
    kernel::MarkovKernel,
    gap,
    discount,
    horizon::Integer;
    survival = 1,
)
    occupation = finite_discounted_occupation(
        kernel,
        discount,
        horizon;
        survival,
    )
    return coverage_potential(occupation, gap)
end

"""
    finite_discount_survival_interaction(
        kernel, gap, beta0, beta1, survival0, survival1, horizon,
    )

Validate with exact finite algebra that patience and candidate survival are
complements. The returned cross-difference is computed both from the four
finite potentials and from the factorization

`sum((beta1^t-beta0^t)*(survival1^t-survival0^t)*P^t*g, t=0:horizon-1)`.

For an exact kernel, every reported quantity uses `Rational{BigInt}`. The
routine is a validation companion to Lean's finite theorem; it does not use
real differentiation or an infinite-series approximation.
"""
function finite_discount_survival_interaction(
    kernel::MarkovKernel{B,T},
    gap::AbstractVector,
    beta0,
    beta1,
    survival0,
    survival1,
    horizon::Integer,
) where {B,T<:Union{ExactRational,Float64}}
    horizon >= 0 || throw(ArgumentError("horizon must be nonnegative"))
    lower_beta = _unit_interval(T, beta0, "lower discount")
    upper_beta = _unit_interval(T, beta1, "upper discount")
    lower_survival = _unit_interval(T, survival0, "lower candidate survival")
    upper_survival = _unit_interval(T, survival1, "upper candidate survival")
    lower_beta <= upper_beta ||
        throw(ArgumentError("lower discount must not exceed upper discount"))
    lower_survival <= upper_survival || throw(
        ArgumentError("lower candidate survival must not exceed upper candidate survival"),
    )

    values = _coverage_vector(T, gap, length(kernel.space), "gap")
    all(>=(zero(T)), values) ||
        throw(ArgumentError("gap must be pointwise nonnegative"))
    transition = _kernel_matrix(kernel)
    count = length(kernel.space)

    potential00 =
        finite_coverage_potential(kernel, values, lower_beta, horizon;
            survival = lower_survival)
    potential10 =
        finite_coverage_potential(kernel, values, upper_beta, horizon;
            survival = lower_survival)
    potential01 =
        finite_coverage_potential(kernel, values, lower_beta, horizon;
            survival = upper_survival)
    potential11 =
        finite_coverage_potential(kernel, values, upper_beta, horizon;
            survival = upper_survival)

    direct = Dict{Tuple{T,T},Vector{T}}()
    for beta in (lower_beta, upper_beta), survival in
        (lower_survival, upper_survival)
        total = zeros(T, count)
        transition_power = Matrix{T}(I, count, count)
        for time in 0:(horizon - 1)
            total .+= (beta * survival)^time .* (transition_power * values)
            transition_power *= transition
        end
        direct[(beta, survival)] = total
    end

    cross_difference =
        potential11 .+ potential00 .- potential10 .- potential01
    factorized_cross_difference = zeros(T, count)
    transition_power = Matrix{T}(I, count, count)
    for time in 0:(horizon - 1)
        coefficient =
            (upper_beta^time - lower_beta^time) *
            (upper_survival^time - lower_survival^time)
        factorized_cross_difference .+=
            coefficient .* (transition_power * values)
        transition_power *= transition
    end

    finite_sum_identity_holds =
        potential00 == direct[(lower_beta, lower_survival)] &&
        potential10 == direct[(upper_beta, lower_survival)] &&
        potential01 == direct[(lower_beta, upper_survival)] &&
        potential11 == direct[(upper_beta, upper_survival)]
    factorization_holds = cross_difference == factorized_cross_difference
    interaction_holds =
        all(potential00 .<= potential10) &&
        all(potential00 .<= potential01) &&
        all((potential11 .- potential01) .>=
            (potential10 .- potential00)) &&
        all(cross_difference .>= zero(T))

    return (
        potential00,
        potential10,
        potential01,
        potential11,
        beta_effect_low_survival = potential10 .- potential00,
        beta_effect_high_survival = potential11 .- potential01,
        cross_difference,
        factorized_cross_difference,
        finite_sum_identity_holds,
        factorization_holds,
        interaction_holds,
    )
end

"""
    infinite_coverage_potential(kernel, gap, discount; survival=1)

Compute the infinite Markov coverage potential, either by direct gap solve
for vectors or by exact profile reconstruction for an `OperationalProfile`.
"""
function infinite_coverage_potential(
    kernel::MarkovKernel,
    gap::AbstractVector,
    discount;
    survival = 1,
)
    return discounted_gap_solve(kernel, gap, discount; survival)
end

function infinite_coverage_potential(
    kernel::MarkovKernel{B,T},
    gap::OperationalProfile{B,T},
    discount;
    survival = 1,
) where {B,T<:Union{ExactRational,Float64}}
    kernel.space == gap.space ||
        throw(ArgumentError("kernel and gap must use the same belief space"))
    values = discounted_gap_solve(kernel, collect(gap.values), discount; survival)
    return OperationalProfile{B,T}(gap.space, Tuple(values))
end

function _survival_vector(
    ::Type{T},
    survival,
    count::Integer,
) where {T<:Union{ExactRational,Float64}}
    if survival isa Real
        value = _unit_interval(T, survival, "candidate survival")
        return fill(value, count)
    end
    values = _coverage_vector(T, survival, count, "candidate survival")
    all(value -> 0 <= value <= 1, values) ||
        throw(ArgumentError("candidate survival must lie in [0, 1]"))
    return values
end

"""
    gross_coverage_value(kernel, gap, discount; survival=1)

Compute the one-step value `discount * survival .* (P*gap)`, exactly mirroring
Lean `Coverage.grossCoverageValue` and its S5/C2 fixtures.  `survival` may be a
scalar or one value per initial belief; `discount=1` is valid for this finite
one-step calculation.
"""
function gross_coverage_value(
    kernel::MarkovKernel{B,T},
    gap::AbstractVector,
    discount;
    survival = 1,
) where {B,T<:Union{ExactRational,Float64}}
    beta = _unit_interval(T, discount, "discount")
    values = _coverage_vector(T, gap, length(kernel.space), "gap")
    survival_values = _survival_vector(T, survival, length(kernel.space))
    return beta .* survival_values .* (_kernel_matrix(kernel) * values)
end

"""
    delayed_lifetime_coverage_potential(kernel, gap, discount;
                                        survival=1, delay=0)

Compute lifetime coverage when a candidate becomes available after the F5
completion lag `delay+1`.  With `q=discount*survival`, the value is
`q^(delay+1) P^(delay+1) (I-qP)⁻¹ gap`.  This convention makes research delay
and survival sensitivity explicit while preserving S4's date-zero occupation
inside the post-completion lifetime.
"""
function delayed_lifetime_coverage_potential(
    kernel::MarkovKernel{B,T},
    gap::AbstractVector,
    discount;
    survival = 1,
    delay::Integer = 0,
) where {B,T<:Union{ExactRational,Float64}}
    delay >= 0 || throw(ArgumentError("research delay must be nonnegative"))
    beta = _unit_interval(T, discount, "discount")
    survival_probability = _unit_interval(T, survival, "candidate survival")
    effective_discount = beta * survival_probability
    effective_discount < one(T) || throw(
        ArgumentError("discount times survival must be strictly below one"),
    )
    continuation = discounted_gap_solve(
        kernel,
        gap,
        beta;
        survival = survival_probability,
    )
    lag = delay + 1
    return effective_discount^lag .* (_kernel_matrix(kernel)^lag * continuation)
end

"""
    cost_covering_set(potential, cost; strict=false)

Return the ordered-grid membership vector.  Weak comparison `cost ≤ potential`
matches Lean S5; `strict=true` uses `cost < potential`, matching Lean C2.
This is a one-shot gross-value diagnostic, not an optimal Bellman research
region.
"""
function cost_covering_set(
    potential::AbstractVector{T},
    cost;
    strict::Bool = false,
) where {T<:Union{ExactRational,Float64}}
    count = length(potential)
    potential_values = _coverage_vector(T, potential, count, "potential")
    cost_values = cost isa Real ?
                  fill(_coverage_scalar(T, cost), count) :
                  _coverage_vector(T, cost, count, "cost")
    all(value -> value >= 0, cost_values) ||
        throw(ArgumentError("research costs must be nonnegative"))
    return BitVector(
        strict ? cost_values[index] < potential_values[index] :
        cost_values[index] <= potential_values[index] for index in 1:count
    )
end

function cost_covering_set(
    potential::OperationalProfile{B,T},
    cost;
    strict::Bool = false,
) where {B,T<:Union{ExactRational,Float64}}
    cost_values = cost isa OperationalProfile ? begin
        cost.space == potential.space ||
            throw(ArgumentError("cost and potential must use the same belief space"))
        collect(cost.values)
    end : cost
    return cost_covering_set(collect(potential.values), cost_values; strict)
end

"""
    research_region(potential, cost; strict=false)

Compatibility alias for [`cost_covering_set`](@ref).  The legacy name is
retained for artifact migration only and does not identify the returned set
with an optimal dynamic research region.
"""
research_region(potential, cost; strict::Bool = false) =
    cost_covering_set(potential, cost; strict)

"""
    connected_components(region)

Return maximal contiguous `UnitRange`s of `true` entries on an ordered finite
belief grid.  This is the executable finite-grid analogue of Lean
`Set.OrdConnected` diagnostics.
"""
function connected_components(region::AbstractVector{Bool})
    components = UnitRange{Int}[]
    start = nothing
    for index in eachindex(region)
        if region[index] && isnothing(start)
            start = index
        elseif !region[index] && !isnothing(start)
            push!(components, start:(index - 1))
            start = nothing
        end
    end
    isnothing(start) || push!(components, start:lastindex(region))
    return components
end

"""Return the number of connected components in an ordered Boolean region."""
component_count(region::AbstractVector{Bool}) = length(connected_components(region))

"""Result of checking whether a finite research region is an upper/lower threshold."""
struct ResearchThreshold{B,X<:Real}
    direction::Symbol
    kind::Symbol
    cutoff_index::Union{Nothing,Int}
    cutoff_belief::Union{Nothing,Belief{B}}
    cutoff_coordinate::Union{Nothing,X}
end

"""
    extract_threshold(grid, region; direction=:upper)

Classify `region` as empty, full, a genuine upper/lower threshold, or not a
threshold.  For the S5 theorem use `direction=:upper`.
"""
function extract_threshold(
    grid::OrderedBeliefGrid{B,X},
    region::AbstractVector{Bool};
    direction::Symbol = :upper,
) where {B,X}
    length(region) == length(grid) ||
        throw(DimensionMismatch("region must match the ordered belief grid"))
    direction in (:upper, :lower) ||
        throw(ArgumentError("threshold direction must be :upper or :lower"))
    if !any(region)
        return ResearchThreshold{B,X}(direction, :empty, nothing, nothing, nothing)
    end
    if all(region)
        cutoff = direction == :upper ? firstindex(region) : lastindex(region)
        return ResearchThreshold{B,X}(
            direction,
            :full,
            cutoff,
            grid.beliefs.states[cutoff],
            grid.coordinates[cutoff],
        )
    end
    cutoff = direction == :upper ? findfirst(identity, region) : findlast(identity, region)
    expected = direction == :upper ?
               [index >= cutoff for index in eachindex(region)] :
               [index <= cutoff for index in eachindex(region)]
    kind = collect(region) == expected ? direction : :not_threshold
    if kind == :not_threshold
        return ResearchThreshold{B,X}(direction, kind, nothing, nothing, nothing)
    end
    return ResearchThreshold{B,X}(
        direction,
        kind,
        cutoff,
        grid.beliefs.states[cutoff],
        grid.coordinates[cutoff],
    )
end

"""Check weak monotonicity of a finite ordered numeric sequence."""
is_monotone_sequence(values::AbstractVector) = length(values) <= 1 ||
    all(values[index] <= values[index + 1] for index in 1:(length(values) - 1))

"""Check weak antitonicity of a finite ordered numeric sequence."""
is_antitone_sequence(values::AbstractVector) = length(values) <= 1 ||
    all(values[index] >= values[index + 1] for index in 1:(length(values) - 1))

"""Check Lean `Coverage.IsSinglePeaked` on a finite ordered sequence."""
function is_single_peaked(values::AbstractVector)
    isempty(values) && throw(ArgumentError("a single-peaked sequence must be nonempty"))
    return any(
        is_monotone_sequence(values[1:peak]) &&
        is_antitone_sequence(values[peak:end]) for peak in eachindex(values)
    )
end

"""Check Lean `Coverage.IsQuasiConcaveSequence` on a finite ordered sequence."""
function is_quasiconcave_sequence(values::AbstractVector)
    for left in eachindex(values), middle in left:lastindex(values), right in middle:lastindex(values)
        min(values[left], values[right]) <= values[middle] || return false
    end
    return true
end

"""
    is_stochastically_monotone(kernel)

Check first-order stochastic monotonicity on the declared ordered state order
using all upper-tail probabilities.  This finite characterization is the
executable assumption behind Lean `Coverage.IsStochasticallyMonotone`.
"""
function is_stochastically_monotone(kernel::MarkovKernel)
    transition = _kernel_matrix(kernel)
    count = size(transition, 1)
    for left in 1:count, right in left:count, cutoff in 1:count
        sum(transition[left, cutoff:end]) <= sum(transition[right, cutoff:end]) ||
            return false
    end
    return true
end

"""One zero/crossing diagnostic for a finite-grid research boundary."""
struct BoundaryDiagnostic{T<:Real}
    kind::Symbol
    left_index::Int
    right_index::Int
    location::T
    slope::T
    left_net_value::T
    right_net_value::T
    transverse::Bool
end

"""
    boundary_transversality(grid, potential, cost; slope_tolerance=0)

Locate exact grid zeros and between-grid sign changes of `potential-cost`.
Report the local/interpolated slope and whether its magnitude exceeds the
declared tolerance.  A zero slope flags a tangency/unstable boundary rather
than a transverse crossing.
"""
function boundary_transversality(
    grid::OrderedBeliefGrid,
    potential::AbstractVector,
    cost;
    slope_tolerance = 0,
)
    count = length(grid)
    length(potential) == count ||
        throw(DimensionMismatch("potential must match the ordered grid"))
    cost_values = cost isa Real ? fill(cost, count) : collect(cost)
    length(cost_values) == count ||
        throw(DimensionMismatch("cost must match the ordered grid"))
    R = promote_type(eltype(grid.coordinates), eltype(potential), eltype(cost_values))
    coordinates = R.(collect(grid.coordinates))
    net = R.(potential) .- R.(cost_values)
    tolerance = R(slope_tolerance)
    tolerance >= 0 || throw(ArgumentError("slope tolerance must be nonnegative"))
    diagnostics = BoundaryDiagnostic{R}[]

    for index in eachindex(net)
        iszero(net[index]) || continue
        left = index == firstindex(net) ? index : index - 1
        right = index == lastindex(net) ? index : index + 1
        slope = left == right ? zero(R) :
                (net[right] - net[left]) / (coordinates[right] - coordinates[left])
        push!(
            diagnostics,
            BoundaryDiagnostic{R}(
                :grid_zero,
                left,
                right,
                coordinates[index],
                slope,
                net[left],
                net[right],
                abs(slope) > tolerance,
            ),
        )
    end
    if length(net) > 1
        for left in firstindex(net):(lastindex(net) - 1)
            right = left + 1
            net[left] * net[right] < 0 || continue
            slope = (net[right] - net[left]) / (coordinates[right] - coordinates[left])
            location = coordinates[left] - net[left] / slope
            push!(
                diagnostics,
                BoundaryDiagnostic{R}(
                    :crossing,
                    left,
                    right,
                    location,
                    slope,
                    net[left],
                    net[right],
                    abs(slope) > tolerance,
                ),
            )
        end
    end
    sort!(diagnostics; by = diagnostic -> diagnostic.location)
    return diagnostics
end

"""
    persistence_adjusted_kernel(kernel, persistence)

Return `persistence*I + (1-persistence)*P` with the kernel's exact/Float64
arithmetic.  This provides a controlled regime-persistence sensitivity while
retaining row stochasticity.
"""
function persistence_adjusted_kernel(
    kernel::MarkovKernel{B,T},
    persistence,
) where {B,T<:Union{ExactRational,Float64}}
    rho = _unit_interval(T, persistence, "regime persistence")
    transition = _kernel_matrix(kernel)
    count = length(kernel.space)
    adjusted = rho .* Matrix{T}(I, count, count) .+
               (one(T) - rho) .* transition
    return MarkovKernel(
        kernel.space,
        adjusted;
        mode = _coverage_mode(T),
    )
end

"""
    persistence_coverage_response_surface(
        base_kernel, gap, persistences, effective_discounts, horizon;
        initial_index=1,
    )

Evaluate finite coverage over the Cartesian grid of regime-persistence and
effective-discount values. Each kernel is
`theta*I + (1-theta)*base_kernel`. Returned rows contain discounted
occupation of the positive-gap region and the resulting coverage at the
selected initial state.

With an exact kernel, all values are `Rational{BigInt}`. The routine imposes
no sign prediction for persistence: the response is determined by alignment
between the changed occupation weights and the supplied gap.
"""
function persistence_coverage_response_surface(
    base_kernel::MarkovKernel{B,T},
    gap::AbstractVector,
    persistences,
    effective_discounts,
    horizon::Integer;
    initial_index::Integer = 1,
) where {B,T<:Union{ExactRational,Float64}}
    horizon >= 0 || throw(ArgumentError("horizon must be nonnegative"))
    count = length(base_kernel.space)
    1 <= initial_index <= count ||
        throw(BoundsError(base_kernel.space.states, initial_index))
    values = _coverage_vector(T, gap, count, "gap")
    all(>=(zero(T)), values) ||
        throw(ArgumentError("gap must be pointwise nonnegative"))
    advantage = findall(>(zero(T)), values)
    rows = NamedTuple[]
    for effective_discount in effective_discounts
        alpha = _unit_interval(T, effective_discount, "effective discount")
        for persistence in persistences
            theta = _unit_interval(T, persistence, "regime persistence")
            kernel = persistence_adjusted_kernel(base_kernel, theta)
            occupation =
                finite_discounted_occupation(kernel, alpha, horizon)
            potential = coverage_potential(occupation, values)
            push!(
                rows,
                (
                    effective_discount = alpha,
                    persistence = theta,
                    horizon = Int(horizon),
                    initial_index = Int(initial_index),
                    advantage_occupation =
                        sum(
                            (occupation[initial_index, index] for index in advantage);
                            init = zero(T),
                        ),
                    coverage = potential[initial_index],
                ),
            )
        end
    end
    return rows
end

"""One auditable scenario row returned by [`coverage_sensitivity`](@ref)."""
struct CoverageSensitivityRow{T<:Real,X<:Real}
    parameter::Symbol
    label::String
    parameter_value::String
    potential::Vector{T}
    region::BitVector
    component_count::Int
    threshold_kind::Symbol
    cutoff_coordinate::Union{Nothing,X}
end

"""
    coverage_sensitivity(grid, kernel, gap, cost; discount, survival=1,
                         delay=0, costs=(), discounts=(), persistences=(),
                         delays=(), survivals=(), signal_kernels=())

Evaluate the baseline delayed-lifetime coverage model and one-at-a-time
variations in cost, discount, regime persistence, research delay, candidate
survival, and supplied signal-precision kernels.  Each returned row includes
the complete potential and region, component count, and upper-threshold
classification.  `signal_kernels` is an iterable of `label => MarkovKernel`.
"""
function coverage_sensitivity(
    grid::OrderedBeliefGrid{B,X},
    kernel::MarkovKernel{B,T},
    gap::AbstractVector,
    cost;
    discount,
    survival = 1,
    delay::Integer = 0,
    strict::Bool = false,
    costs = (),
    discounts = (),
    persistences = (),
    delays = (),
    survivals = (),
    signal_kernels = (),
) where {B,X,T<:Union{ExactRational,Float64}}
    grid.beliefs == kernel.space ||
        throw(ArgumentError("ordered grid and kernel must share a belief space"))
    gap_values = _coverage_vector(T, gap, length(grid), "gap")
    rows = CoverageSensitivityRow{T,X}[]

    function record!(parameter, label, parameter_value, scenario_kernel,
                     scenario_cost, scenario_discount, scenario_survival,
                     scenario_delay)
        scenario_kernel.space == grid.beliefs ||
            throw(ArgumentError("every sensitivity kernel must use the ordered grid"))
        potential = delayed_lifetime_coverage_potential(
            scenario_kernel,
            gap_values,
            scenario_discount;
            survival = scenario_survival,
            delay = scenario_delay,
        )
        region = research_region(potential, scenario_cost; strict)
        threshold = extract_threshold(grid, region)
        push!(
            rows,
            CoverageSensitivityRow{T,X}(
                parameter,
                label,
                string(parameter_value),
                potential,
                region,
                component_count(region),
                threshold.kind,
                threshold.cutoff_coordinate,
            ),
        )
    end

    record!(:baseline, "baseline", "baseline", kernel, cost, discount, survival, delay)
    for value in costs
        record!(:cost, "cost=$value", value, kernel, value, discount, survival, delay)
    end
    for value in discounts
        record!(:discount, "discount=$value", value, kernel, cost, value, survival, delay)
    end
    for value in persistences
        adjusted = persistence_adjusted_kernel(kernel, value)
        record!(
            :persistence,
            "persistence=$value",
            value,
            adjusted,
            cost,
            discount,
            survival,
            delay,
        )
    end
    for value in delays
        value isa Integer || throw(ArgumentError("research delays must be integers"))
        record!(:delay, "delay=$value", value, kernel, cost, discount, survival, value)
    end
    for value in survivals
        record!(:survival, "survival=$value", value, kernel, cost, discount, value, delay)
    end
    for entry in signal_kernels
        label, signal_kernel = entry
        signal_kernel isa MarkovKernel{B,T} || throw(
            ArgumentError("signal kernels must match the baseline belief/arithmetic types"),
        )
        record!(
            :signal_precision,
            "signal_precision=$label",
            label,
            signal_kernel,
            cost,
            discount,
            survival,
            delay,
        )
    end
    return rows
end
