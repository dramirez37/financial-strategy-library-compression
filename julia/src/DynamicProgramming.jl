using LinearAlgebra: I, dot
using SparseArrays: SparseMatrixCSC, sparse, spzeros

"""
    FloatProb(outcomes, probabilities; atol=1e-12)

Validated finitely supported `Float64` probability distribution for larger
simulations.  Exact theorem fixtures must use [`RatProb`](@ref).  The
constructor rejects duplicate outcomes, nonfinite or negative masses, and
rows that do not sum to one within `atol`.
"""
struct FloatProb{O}
    outcomes::Tuple{Vararg{O}}
    probabilities::Tuple{Vararg{Float64}}

    function FloatProb{O}(
        outcomes::Tuple{Vararg{O}},
        probabilities::Tuple{Vararg{Float64}};
        atol::Real = 1e-12,
    ) where {O}
        length(outcomes) == length(probabilities) || throw(
            DimensionMismatch("outcomes and probabilities must have equal length"),
        )
        _require_unique(outcomes, "outcomes in a floating distribution")
        atol >= 0 || throw(ArgumentError("atol must be nonnegative"))
        all(isfinite, probabilities) ||
            throw(ArgumentError("floating probabilities must be finite"))
        all(mass -> mass >= 0, probabilities) ||
            throw(ArgumentError("floating probabilities must be nonnegative"))
        isapprox(sum(probabilities; init = 0.0), 1.0; atol, rtol = 0) ||
            throw(ArgumentError("floating probabilities must sum to one"))
        return new{O}(outcomes, probabilities)
    end
end

function FloatProb(
    outcomes::AbstractVector{O},
    probabilities::AbstractVector;
    atol::Real = 1e-12,
) where {O}
    return FloatProb{O}(Tuple(outcomes), Tuple(Float64.(probabilities)); atol)
end

"""Return the `Float64` mass assigned to `outcome` by a `FloatProb`."""
function probability(distribution::FloatProb, outcome)
    index = findfirst(isequal(outcome), distribution.outcomes)
    return isnothing(index) ? 0.0 : distribution.probabilities[index]
end

"""Evaluate a real-valued function under a finite `FloatProb`."""
function expectation(distribution::FloatProb, value::F) where {F}
    result = 0.0
    for (outcome, mass) in zip(distribution.outcomes, distribution.probabilities)
        result += mass * Float64(value(outcome))
    end
    return result
end

"""Abstract action carrier corresponding to Lean `Option ResearchProject`."""
abstract type StrategyResearchAction{P} end

"""The passive/continue action (`none` in Lean `FiniteHorizon.Action`)."""
struct ContinueAction{P} <: StrategyResearchAction{P} end

"""A project-selection action (`some project` in Lean `FiniteHorizon.Action`)."""
struct ResearchAction{P} <: StrategyResearchAction{P}
    project::ResearchProjectId{P}
end

Base.:(==)(::ContinueAction{P}, ::ContinueAction{P}) where {P} = true
Base.:(==)(left::ResearchAction{P}, right::ResearchAction{P}) where {P} =
    left.project == right.project
Base.hash(::ContinueAction{P}, seed::UInt) where {P} =
    hash((:ContinueAction, P), seed)
Base.hash(action::ResearchAction, seed::UInt) =
    hash((:ResearchAction, action.project), seed)

"""Return the stable machine-readable label of a dynamic-program action."""
action_label(::ContinueAction) = "continue"
action_label(action::ResearchAction) = "research:" * string(action.project.id)

"""
    DiscountedResearchProcess(states, projects, belief_kernel,
                              research_transition, research_cost,
                              research_delay, discount; atol=1e-12)

Deprecated compatibility process for the primitive F5/F8 API. New models
must use [`RawInnovationProcess`](@ref), whose candidate-generation,
admission, raw-update, completion, and timing laws induce the compressed
transition.

This legacy type is a validated finite discounted process on
`belief × compressed-library-state`.  `research_transition(b, s, p)` returns
a `RatProb` in exact mode or a `FloatProb` in floating mode;
`research_cost(b, s, p)` is a nonnegative immediate cost; and
`research_delay(p)` is a nonnegative integer.  The compiled exact process
uses dense rational matrices, while the `Float64` process uses sparse
transition matrices.

The timing mirrors Lean `FiniteHorizon.continueValue` and
`FiniteHorizon.researchValue`:
continue earns the current frontier and discounts one transition; research
pays cost now and discounts its candidate continuation by `β^(delay+1)`.
That convention is intentionally retained only for backward compatibility.
"""
struct DiscountedResearchProcess{
    B,
    P,
    M,
    T<:Real,
    K<:CompressedLibraryState{B,M,T},
    MT<:AbstractMatrix{T},
}
    beliefs::FiniteBeliefSpace{B}
    compressed_states::Tuple{Vararg{K}}
    projects::Tuple{Vararg{ResearchProject{P,M}}}
    discount::T
    delays::Tuple{Vararg{Int}}
    continue_rewards::Vector{T}
    research_costs::Matrix{T}
    continue_transition::MT
    candidate_transitions::Tuple{Vararg{MT}}
    research_transitions::Tuple{Vararg{MT}}
end

_distribution_type(::Type{ExactRational}) = RatProb
_distribution_type(::Type{Float64}) = FloatProb

function _validated_distribution(
    ::Type{T},
    transition,
    belief,
    state,
    project,
    declared_states,
) where {T<:Real}
    distribution = transition(belief, state, project)
    expected = _distribution_type(T)
    distribution isa expected || throw(
        ArgumentError("research transitions in $T mode must return $expected"),
    )
    for outcome in distribution.outcomes
        outcome in declared_states || throw(
            ArgumentError("a research transition returned an unresolved compressed state"),
        )
    end
    return distribution
end

function _compiled_matrix(::Type{ExactRational}, dense::Matrix{ExactRational})
    return dense
end

function _compiled_matrix(::Type{Float64}, dense::Matrix{Float64})
    return sparse(dense)
end

function _compiled_matrix(::Type{Float64}, matrix::SparseMatrixCSC{Float64,Int})
    return matrix
end

_transition_work_matrix(::Type{ExactRational}, rows::Int, columns::Int) =
    zeros(ExactRational, rows, columns)

_transition_work_matrix(::Type{Float64}, rows::Int, columns::Int) =
    spzeros(Float64, rows, columns)

function DiscountedResearchProcess(
    compressed_states::AbstractVector{K},
    projects::AbstractVector{ResearchProject{P,M}},
    belief_kernel::MarkovKernel{B,T},
    research_transition::F,
    research_cost::C,
    research_delay::D,
    discount;
    atol::Real = 1e-12,
) where {B,P,M,T<:Union{ExactRational,Float64},K<:CompressedLibraryState{B,M,T},F,C,D}
    Base.depwarn(
        "DiscountedResearchProcess uses the obsolete primitive transition and " *
        "β^(delay+1) decision-epoch timing. Use RawInnovationProcess for new work.",
        :DiscountedResearchProcess,
    )
    isempty(compressed_states) &&
        throw(ArgumentError("at least one compressed library state is required"))
    isempty(projects) &&
        throw(ArgumentError("at least one research project is required"))
    _require_unique(compressed_states, "compressed library states")
    _require_unique([project.id for project in projects], "research-project IDs")
    atol >= 0 || throw(ArgumentError("atol must be nonnegative"))

    mode = T === ExactRational ? ExactMode() : Float64Mode()
    beta = discount_factor(discount; mode)
    states = Tuple(compressed_states)
    project_rows = Tuple(projects)
    declared_modules = ModuleSet{M}()
    for state in states
        state.frontier.space == belief_kernel.space || throw(
            ArgumentError("every compressed state must use the process belief space"),
        )
        declared_modules = union(declared_modules, state.closure)
    end
    for project in project_rows
        issubset(project.requirements, declared_modules) || throw(
            ArgumentError(
                "project $(project.id) has a module reference absent from every declared state",
            ),
        )
    end

    delays = Int[]
    for project in project_rows
        delay = research_delay(project)
        delay isa Integer ||
            throw(ArgumentError("research delays must be integers"))
        delay >= 0 || throw(ArgumentError("research delays must be nonnegative"))
        push!(delays, Int(delay))
    end

    nb = length(belief_kernel.space)
    nk = length(states)
    np = length(project_rows)
    joint_count = nb * nk
    continue_rewards = Vector{T}(undef, joint_count)
    costs = Matrix{T}(undef, joint_count, np)
    continue_dense = _transition_work_matrix(T, joint_count, joint_count)
    candidate_dense = [
        _transition_work_matrix(T, joint_count, nk) for _ in 1:np
    ]
    research_dense = [
        _transition_work_matrix(T, joint_count, joint_count) for _ in 1:np
    ]

    for (state_position, state) in enumerate(states)
        for (belief_position, belief) in enumerate(belief_kernel.space)
            row = belief_position + (state_position - 1) * nb
            continue_rewards[row] = state.frontier[belief]
            for next_belief_position in 1:nb
                column = next_belief_position + (state_position - 1) * nb
                continue_dense[row, column] =
                    belief_kernel.rows[belief_position][next_belief_position]
            end

            for (project_position, project) in enumerate(project_rows)
                raw_cost = research_cost(belief, state, project)
                cost = _coerce_scalar(mode, raw_cost)
                isfinite(cost) || throw(ArgumentError("research costs must be finite"))
                cost >= 0 || throw(ArgumentError("research costs must be nonnegative"))
                costs[row, project_position] = cost

                distribution = _validated_distribution(
                    T,
                    research_transition,
                    belief,
                    state,
                    project,
                    states,
                )
                for next_state_position in 1:nk
                    candidate_mass = probability(distribution, states[next_state_position])
                    candidate_dense[project_position][row, next_state_position] =
                        candidate_mass
                    for next_belief_position in 1:nb
                        column = next_belief_position + (next_state_position - 1) * nb
                        research_dense[project_position][row, column] =
                            belief_kernel.rows[belief_position][next_belief_position] *
                            candidate_mass
                    end
                end
            end
        end
    end

    for row in 1:joint_count
        normalized = T === ExactRational ?
                     sum(continue_dense[row, :]) == one(T) :
                     isapprox(sum(continue_dense[row, :]), 1.0; atol, rtol = 0)
        normalized || error("internal continue-transition row is not stochastic")
        for project_position in 1:np
            candidate_sum = sum(candidate_dense[project_position][row, :])
            research_sum = sum(research_dense[project_position][row, :])
            candidate_ok = T === ExactRational ? candidate_sum == one(T) :
                           isapprox(candidate_sum, 1.0; atol, rtol = 0)
            research_ok = T === ExactRational ? research_sum == one(T) :
                          isapprox(research_sum, 1.0; atol, rtol = 0)
            candidate_ok || error("internal candidate-transition row is not stochastic")
            research_ok || error("internal research-transition row is not stochastic")
        end
    end

    continue_matrix = _compiled_matrix(T, continue_dense)
    candidate_matrices = Tuple(_compiled_matrix(T, matrix) for matrix in candidate_dense)
    research_matrices = Tuple(_compiled_matrix(T, matrix) for matrix in research_dense)
    matrix_type = typeof(continue_matrix)
    return DiscountedResearchProcess{B,P,M,T,K,matrix_type}(
        belief_kernel.space,
        states,
        project_rows,
        beta,
        Tuple(delays),
        continue_rewards,
        costs,
        continue_matrix,
        candidate_matrices,
        research_matrices,
    )
end

"""Return the canonical one-based index of `(belief, compressed_state)`."""
function joint_state_index(
    process::DiscountedResearchProcess,
    belief::Belief,
    state::CompressedLibraryState,
)
    belief_position = belief_index(process.beliefs, belief)
    state_position = findfirst(isequal(state), process.compressed_states)
    isnothing(state_position) &&
        throw(ArgumentError("unresolved compressed-state reference"))
    return belief_position + (state_position - 1) * length(process.beliefs)
end

"""Return `continue` followed by the validated project actions."""
function available_actions(process::DiscountedResearchProcess{B,P}) where {B,P}
    return (
        ContinueAction{P}(),
        (ResearchAction{P}(project.id) for project in process.projects)...,
    )
end

function _project_index(process::DiscountedResearchProcess, project_id::ResearchProjectId)
    index = findfirst(project -> project.id == project_id, process.projects)
    isnothing(index) &&
        throw(ArgumentError("unresolved research-project reference: $project_id"))
    return index
end

function _validate_value_table(process::DiscountedResearchProcess, values::AbstractMatrix)
    expected = (length(process.beliefs), length(process.compressed_states))
    size(values) == expected ||
        throw(DimensionMismatch("value table must have dimensions $expected"))
    return nothing
end

_process_mode(::DiscountedResearchProcess{B,P,M,ExactRational}) where {B,P,M} =
    ExactMode()

_process_mode(::DiscountedResearchProcess{B,P,M,Float64}) where {B,P,M} =
    Float64Mode()

function _coerce_value_table(
    process::DiscountedResearchProcess{B,P,M,T},
    values::AbstractMatrix,
) where {B,P,M,T}
    _validate_value_table(process, values)
    converted = T[_coerce_scalar(_process_mode(process), value) for value in values]
    return reshape(converted, size(values))
end

"""
    continue_value(process, continuation, belief, state)

Evaluate Lean `FiniteHorizon.continueValue`: current frontier reward plus one-step
discounted belief continuation while retaining the compressed state.
"""
function continue_value(
    process::DiscountedResearchProcess{B,P,M,T},
    continuation::AbstractMatrix,
    belief::Belief,
    state::CompressedLibraryState,
) where {B,P,M,T}
    row = joint_state_index(process, belief, state)
    values = vec(_coerce_value_table(process, continuation))
    return process.continue_rewards[row] +
           process.discount * dot(process.continue_transition[row, :], values)
end

"""
    research_value(process, continuation, belief, state, project)

Evaluate Lean `FiniteHorizon.researchValue`: immediate negative cost plus the
candidate continuation discounted by `β^(delay(project)+1)`.
"""
function research_value(
    process::DiscountedResearchProcess{B,P,M,T},
    continuation::AbstractMatrix,
    belief::Belief,
    state::CompressedLibraryState,
    project::ResearchProjectId{P},
) where {B,P,M,T}
    row = joint_state_index(process, belief, state)
    project_position = _project_index(process, project)
    values = vec(_coerce_value_table(process, continuation))
    discount = process.discount^(process.delays[project_position] + 1)
    return -process.research_costs[row, project_position] +
           discount * dot(process.research_transitions[project_position][row, :], values)
end

"""Evaluate either Lean `none`/continue or `some project` action value."""
action_value(process, continuation, belief, state, ::ContinueAction) =
    continue_value(process, continuation, belief, state)

action_value(process, continuation, belief, state, action::ResearchAction) =
    research_value(process, continuation, belief, state, action.project)

function _zero_values(process::DiscountedResearchProcess{B,P,M,T}) where {B,P,M,T}
    return zeros(T, length(process.beliefs), length(process.compressed_states))
end

"""
    bellman_step(process, continuation)

Apply the finite Bellman maximization `FiniteHorizon.bellmanStep` once.  Exact
processes return exact rationals; floating processes use sparse matrix-vector
products.  Ties are resolved deterministically in favor of continue, then
project declaration order.
"""
function bellman_step(
    process::DiscountedResearchProcess{B,P,M,T},
    continuation::AbstractMatrix,
) where {B,P,M,T}
    old = vec(_coerce_value_table(process, continuation))
    joint_count = length(old)
    result = Vector{T}(undef, joint_count)
    continue_candidates = process.continue_rewards .+
                          process.discount .* (process.continue_transition * old)
    research_candidates = Vector{Vector{T}}(undef, length(process.projects))
    for project_position in eachindex(process.projects)
        discount = process.discount^(process.delays[project_position] + 1)
        research_candidates[project_position] =
            -process.research_costs[:, project_position] .+
            discount .* (process.research_transitions[project_position] * old)
    end
    for row in 1:joint_count
        best = continue_candidates[row]
        for candidates in research_candidates
            candidates[row] > best && (best = candidates[row])
        end
        result[row] = best
    end
    return reshape(result, length(process.beliefs), length(process.compressed_states))
end

"""
    extract_policy(process, continuation)

Extract the maximizing decision rule associated with one Bellman step.
Deterministic tie-breaking matches [`bellman_step`](@ref).
"""
function extract_policy(
    process::DiscountedResearchProcess{B,P},
    continuation::AbstractMatrix,
) where {B,P}
    _validate_value_table(process, continuation)
    policy = Matrix{StrategyResearchAction{P}}(
        undef,
        length(process.beliefs),
        length(process.compressed_states),
    )
    for (state_position, state) in enumerate(process.compressed_states)
        for (belief_position, belief) in enumerate(process.beliefs)
            best_action = ContinueAction{P}()
            best_value = continue_value(process, continuation, belief, state)
            for project in process.projects
                candidate = research_value(process, continuation, belief, state, project.id)
                if candidate > best_value
                    best_value = candidate
                    best_action = ResearchAction{P}(project.id)
                end
            end
            policy[belief_position, state_position] = best_action
        end
    end
    return policy
end

"""
    finite_horizon_value(process, horizon; terminal_value=zeros(...))

Compute the exact finite-horizon recursion `FiniteHorizon.finiteHorizonValue` by
iterating the Bellman operator from the supplied terminal value.  `horizon`
counts decision epochs; research delay changes discounting, not the recursion
index, exactly as in Lean.
"""
function finite_horizon_value(
    process::DiscountedResearchProcess,
    horizon::Integer;
    terminal_value = _zero_values(process),
)
    horizon >= 0 || throw(ArgumentError("horizon must be nonnegative"))
    values = _coerce_value_table(process, terminal_value)
    for _ in 1:horizon
        values = bellman_step(process, values)
    end
    return values
end

"""
    finite_horizon_policy(process, horizon; terminal_value=zeros(...))

Return the first-decision policy for a positive finite horizon.  This is the
argmax of the Lean finite-horizon recursion with `horizon-1` epochs remaining.
"""
function finite_horizon_policy(
    process::DiscountedResearchProcess,
    horizon::Integer;
    terminal_value = _zero_values(process),
)
    horizon >= 1 || throw(ArgumentError("policy extraction requires a positive horizon"))
    continuation = finite_horizon_value(process, horizon - 1; terminal_value)
    return extract_policy(process, continuation)
end

"""
    dynamic_innovation_equivalent(process, left_state, right_state)

Decide the exact F5 `DynamicInnovationEquivalent` relation inside a compiled
finite process: equal frontier, equal project costs, and equal primitive
candidate-state laws at every belief and project.  No `Float64` overload is
provided, preventing tolerance-based equality from being used as theorem
evidence.
"""
function dynamic_innovation_equivalent(
    process::DiscountedResearchProcess{B,P,M,ExactRational},
    left_state::CompressedLibraryState{B,M,ExactRational},
    right_state::CompressedLibraryState{B,M,ExactRational},
) where {B,P,M}
    left_state.frontier == right_state.frontier || return false
    left_position = findfirst(isequal(left_state), process.compressed_states)
    right_position = findfirst(isequal(right_state), process.compressed_states)
    (isnothing(left_position) || isnothing(right_position)) &&
        throw(ArgumentError("both compressed states must belong to the process"))
    nb = length(process.beliefs)
    for belief_position in 1:nb, project_position in eachindex(process.projects)
        left_row = belief_position + (left_position - 1) * nb
        right_row = belief_position + (right_position - 1) * nb
        process.research_costs[left_row, project_position] ==
            process.research_costs[right_row, project_position] || return false
        process.candidate_transitions[project_position][left_row, :] ==
            process.candidate_transitions[project_position][right_row, :] || return false
    end
    return true
end

function _sup_norm(values::AbstractArray)
    isempty(values) && return zero(eltype(values))
    return maximum(abs, values)
end

"""Return `‖T(V)-V‖∞`, the Bellman residual used in Lean F8."""
function bellman_residual(process::DiscountedResearchProcess, values::AbstractMatrix)
    current = _coerce_value_table(process, values)
    return _sup_norm(bellman_step(process, current) .- current)
end

"""
    contraction_error_bound(process, initial_increment, iteration)

Return the F8 a-priori contraction bound
`β^iteration * ‖T(V₀)-V₀‖∞ / (1-β)` for `V_iteration`.
"""
function contraction_error_bound(
    process::DiscountedResearchProcess{B,P,M,T},
    initial_increment::Real,
    iteration::Integer,
) where {B,P,M,T}
    increment = _coerce_scalar(_process_mode(process), initial_increment)
    increment >= 0 || throw(ArgumentError("increment must be nonnegative"))
    iteration >= 0 || throw(ArgumentError("iteration must be nonnegative"))
    return process.discount^iteration * increment / (1 - process.discount)
end

"""
    residual_error_bound(process, residual)

Return the standard contraction a-posteriori bound
`‖T(V)-V‖∞/(1-β)`.
"""
function residual_error_bound(
    process::DiscountedResearchProcess,
    residual::Real,
)
    converted = _coerce_scalar(_process_mode(process), residual)
    converted >= 0 || throw(ArgumentError("residual must be nonnegative"))
    return converted / (1 - process.discount)
end

"""One deterministic diagnostic row emitted by [`value_iteration`](@ref)."""
struct ConvergenceRecord{T<:Real}
    iteration::Int
    increment::T
    residual::T
    apriori_error_bound::T
    posterior_error_bound::T
end

"""Complete output of discounted infinite-horizon value iteration."""
struct ValueIterationResult{T<:Real,P}
    values::Matrix{T}
    policy::Matrix{StrategyResearchAction{P}}
    converged::Bool
    iterations::Int
    increment::T
    residual::T
    apriori_error_bound::T
    posterior_error_bound::T
    log::Vector{ConvergenceRecord{T}}
end

function _default_tolerance(::Type{ExactRational})
    return BigInt(1) // BigInt(10)^12
end


_default_tolerance(::Type{Float64}) = 1e-10

"""
    value_iteration(process; tolerance, max_iterations=10_000,
                    initial_value=zeros(...), throw_on_nonconvergence=false)

Solve the infinite-horizon discounted Bellman fixed point with a sup-norm
successive-iterate test.  The result includes the policy, Bellman residual,
F8 a-priori contraction bound, residual-based a-posteriori bound, and a full
deterministic convergence log.  `max_iterations` is always enforced.
"""
function value_iteration(
    process::DiscountedResearchProcess{B,P,M,T};
    tolerance = _default_tolerance(T),
    max_iterations::Integer = 10_000,
    initial_value = _zero_values(process),
    throw_on_nonconvergence::Bool = false,
) where {B,P,M,T}
    tol = _coerce_scalar(T === ExactRational ? ExactMode() : Float64Mode(), tolerance)
    tol >= 0 || throw(ArgumentError("tolerance must be nonnegative"))
    max_iterations >= 1 || throw(ArgumentError("max_iterations must be positive"))
    values = _coerce_value_table(process, initial_value)
    log = ConvergenceRecord{T}[]
    first_increment = zero(T)
    increment = zero(T)
    residual = bellman_residual(process, values)
    apriori = residual_error_bound(process, residual)
    posterior = apriori
    converged = false

    for iteration in 1:max_iterations
        updated = bellman_step(process, values)
        increment = _sup_norm(updated .- values)
        iteration == 1 && (first_increment = increment)
        residual = bellman_residual(process, updated)
        apriori = contraction_error_bound(process, first_increment, iteration)
        posterior = residual_error_bound(process, residual)
        push!(
            log,
            ConvergenceRecord{T}(iteration, increment, residual, apriori, posterior),
        )
        values = updated
        if increment <= tol
            converged = true
            break
        end
    end

    if !converged && throw_on_nonconvergence
        throw(ErrorException("value iteration did not converge within $max_iterations iterations"))
    end
    policy = extract_policy(process, values)
    return ValueIterationResult{T,P}(
        values,
        policy,
        converged,
        length(log),
        increment,
        residual,
        apriori,
        posterior,
        log,
    )
end

"""One policy-improvement diagnostic row from exact policy iteration."""
struct PolicyIterationRecord
    iteration::Int
    policy_changes::Int
    bellman_residual::ExactRational
end

"""Result of exact finite-state policy iteration."""
struct PolicyIterationResult{P}
    values::Matrix{ExactRational}
    policy::Matrix{StrategyResearchAction{P}}
    converged::Bool
    iterations::Int
    residual::ExactRational
    log::Vector{PolicyIterationRecord}
end

function _policy_row(
    process::DiscountedResearchProcess{B,P,M,ExactRational},
    action::StrategyResearchAction{P},
    row::Int,
) where {B,P,M}
    if action isa ContinueAction{P}
        reward = process.continue_rewards[row]
        transition = process.discount .* collect(process.continue_transition[row, :])
        return reward, transition
    end
    project_position = _project_index(process, (action::ResearchAction{P}).project)
    reward = -process.research_costs[row, project_position]
    discount = process.discount^(process.delays[project_position] + 1)
    transition = discount .* collect(process.research_transitions[project_position][row, :])
    return reward, transition
end

function _evaluate_policy(
    process::DiscountedResearchProcess{B,P,M,ExactRational},
    policy::Matrix{StrategyResearchAction{P}},
) where {B,P,M}
    _validate_value_table(process, policy)
    joint_count = length(process.beliefs) * length(process.compressed_states)
    reward = zeros(ExactRational, joint_count)
    discounted_transition = zeros(ExactRational, joint_count, joint_count)
    flat_policy = vec(policy)
    for row in 1:joint_count
        reward[row], discounted_transition[row, :] =
            _policy_row(process, flat_policy[row], row)
    end
    system = Matrix{ExactRational}(I, joint_count, joint_count) - discounted_transition
    values = system \ reward
    return reshape(values, length(process.beliefs), length(process.compressed_states))
end

"""
    exact_policy_iteration(process; max_iterations=10_000, initial_policy=nothing)

Solve a small exact rational process by stationary policy evaluation and
strict policy improvement.  This solver implements the legacy primitive
compatibility process.  The unified positive-duration raw model now has a
separate Lean stationary-selector and policy-evaluation theorem; output from
this routine remains instance-level validation rather than a proof.
"""
function exact_policy_iteration(
    process::DiscountedResearchProcess{B,P,M,ExactRational};
    max_iterations::Integer = 10_000,
    initial_policy = nothing,
) where {B,P,M}
    max_iterations >= 1 || throw(ArgumentError("max_iterations must be positive"))
    policy = if isnothing(initial_policy)
        default_policy = Matrix{StrategyResearchAction{P}}(
            undef,
            length(process.beliefs),
            length(process.compressed_states),
        )
        fill!(default_policy, ContinueAction{P}())
        default_policy
    else
        _validate_value_table(process, initial_policy)
        Matrix{StrategyResearchAction{P}}(initial_policy)
    end
    log = PolicyIterationRecord[]
    values = _zero_values(process)

    for iteration in 1:max_iterations
        values = _evaluate_policy(process, policy)
        changes = 0
        for (state_position, state) in enumerate(process.compressed_states)
            for (belief_position, belief) in enumerate(process.beliefs)
                current = policy[belief_position, state_position]
                best = current
                best_value = action_value(process, values, belief, state, current)
                for action in available_actions(process)
                    candidate = action_value(process, values, belief, state, action)
                    if candidate > best_value
                        best_value = candidate
                        best = action
                    end
                end
                if best != current
                    policy[belief_position, state_position] = best
                    changes += 1
                end
            end
        end
        residual = bellman_residual(process, values)
        push!(log, PolicyIterationRecord(iteration, changes, residual))
        if changes == 0
            return PolicyIterationResult{P}(
                values,
                policy,
                true,
                iteration,
                residual,
                log,
            )
        end
    end
    values = _evaluate_policy(process, policy)
    residual = bellman_residual(process, values)
    return PolicyIterationResult{P}(
        values,
        policy,
        false,
        max_iterations,
        residual,
        log,
    )
end
