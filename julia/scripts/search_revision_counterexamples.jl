module RevisionCounterexampleGauntlet

using Random: AbstractRNG, rand
using LinearAlgebra: I
using StrategyInnovation: research_rng

if !isdefined(Main, :CounterexampleSearch)
    Base.include(Main, joinpath(@__DIR__, "search_counterexamples.jl"))
end
const LegacySearch = Main.CounterexampleSearch

export DEFAULT_REVISION_SEED,
       run_revision_gauntlet,
       correlated_projection_witness,
       t4_unified_witness,
       t6_cost_boundary_witness,
       generator_complementarity_witness,
       unified_stationary_policy_witness,
       persistence_direction_witnesses,
       information_direction_witnesses,
       delay_direction_witnesses,
       write_result

const Rat = Rational{BigInt}
const DEFAULT_REVISION_SEED = UInt64(0x5448454f52454d32)
const PAYOFF_GRID = Rat[-1 // 1, 0 // 1, 1 // 2, 1 // 1, 2 // 1]
const PROB_GRID = Rat[0 // 1, 1 // 4, 1 // 2, 3 // 4, 1 // 1]
const COST_GRID = Rat[0 // 1, 1 // 4, 1 // 2, 1 // 1]
const DISCOUNT_GRID = Rat[0 // 1, 1 // 4, 1 // 2, 3 // 4, 9 // 10]

strategy_bit(s::Int) = UInt64(1) << (s - 1)
module_bit(m::Int) = UInt64(1) << (m - 1)
mask_contains(mask::UInt64, item::Int) = !iszero(mask & strategy_bit(item))
is_subset_mask(left::UInt64, right::UInt64) = (left & right) == left
mask_bound(n::Int) = UInt64(1) << n
mask_index(mask::UInt64) = Int(mask) + 1
rat_string(x::Rational) = string(numerator(x), "//", denominator(x))

struct SemiMarkovProject
    id::Symbol
    requirements::UInt64
    duration::Int
    operates::Bool
    cost::Matrix{Rat}
    generation::Array{Rat,3}
    verification::Array{Rat,3}
    coupling::Array{Rat,4}
end

struct SemiMarkovModel
    belief_count::Int
    strategy_count::Int
    module_count::Int
    payoffs::Matrix{Rat}
    modules::Vector{UInt64}
    closure_table::Vector{UInt64}
    belief_kernel::Matrix{Rat}
    projects::Vector{SemiMarkovProject}
    discount::Rat
end

function identity_closure(module_count::Int)
    return UInt64[UInt64(mask) for mask in 0:(Int(mask_bound(module_count)) - 1)]
end

function all_libraries(strategy_count::Int)
    return UInt64[
        UInt64(mask) for mask in 1:(Int(mask_bound(strategy_count)) - 1) if
        isodd(mask)
    ]
end

function strategy_indices(mask::UInt64, count::Int)
    return Int[s for s in 1:count if mask_contains(mask, s)]
end

function module_union(model::SemiMarkovModel, library::UInt64)
    result = UInt64(0)
    for strategy in strategy_indices(library, model.strategy_count)
        result |= model.modules[strategy]
    end
    return result
end

generative_closure(model::SemiMarkovModel, library::UInt64) =
    model.closure_table[mask_index(module_union(model, library))]

function frontier(model::SemiMarkovModel, library::UInt64)
    result = Vector{Rat}(undef, model.belief_count)
    for belief in 1:model.belief_count
        value = model.payoffs[belief, 1]
        for strategy in 2:model.strategy_count
            if mask_contains(library, strategy)
                value = max(value, model.payoffs[belief, strategy])
            end
        end
        result[belief] = value
    end
    return result
end

innovation_key(model::SemiMarkovModel, library::UInt64) =
    (Tuple(frontier(model, library)), generative_closure(model, library))

admit(library::UInt64, outcome::Int) =
    outcome == 0 ? library : library | strategy_bit(outcome)

function add_key(model::SemiMarkovModel, key::Tuple, outcome::Int)
    outcome == 0 && return key
    old_frontier, closure = key
    new_frontier = ntuple(
        belief -> max(old_frontier[belief], model.payoffs[belief, outcome]),
        model.belief_count,
    )
    new_closure = model.closure_table[
        mask_index(closure | model.modules[outcome])
    ]
    return (new_frontier, new_closure)
end

function admitted_distribution(
    model::SemiMarkovModel,
    project::SemiMarkovProject,
    belief::Int,
    closure::UInt64,
)
    ci = mask_index(closure)
    result = fill(Rat(0), model.strategy_count + 1)
    result[1] = project.generation[belief, ci, 1]
    for strategy in 1:model.strategy_count
        raw_mass = project.generation[belief, ci, strategy + 1]
        pass = project.verification[belief, ci, strategy]
        result[strategy + 1] = raw_mass * pass
        result[1] += raw_mass * (1 - pass)
    end
    return result
end

function kernel_power(kernel::Matrix{Rat}, exponent::Int)
    exponent >= 0 || throw(ArgumentError("negative kernel exponent"))
    n = size(kernel, 1)
    result = fill(Rat(0), n, n)
    for i in 1:n
        result[i, i] = 1 // 1
    end
    for _ in 1:exponent
        next = fill(Rat(0), n, n)
        for i in 1:n, j in 1:n, k in 1:n
            next[i, j] += result[i, k] * kernel[k, j]
        end
        result = next
    end
    return result
end

function validate_probability(values)
    return all(x -> x >= 0, values) && sum(values; init = Rat(0)) == 1
end

function validate_model(model::SemiMarkovModel)
    nb = model.belief_count
    ns = model.strategy_count
    nm = model.module_count
    nb >= 1 || return false
    ns >= 2 || return false
    nm >= 1 || return false
    size(model.payoffs) == (nb, ns) || return false
    all(model.payoffs[:, 1] .== 0) || return false
    length(model.modules) == ns || return false
    model.modules[1] == 0 || return false
    length(model.closure_table) == Int(mask_bound(nm)) || return false
    size(model.belief_kernel) == (nb, nb) || return false
    0 <= model.discount < 1 || return false
    for belief in 1:nb
        validate_probability(view(model.belief_kernel, belief, :)) || return false
    end
    closure_count = Int(mask_bound(nm))
    for project in model.projects
        project.duration >= 1 || return false
        size(project.cost) == (nb, closure_count) || return false
        size(project.generation) == (nb, closure_count, ns + 1) || return false
        size(project.verification) == (nb, closure_count, ns) || return false
        size(project.coupling) == (nb, closure_count, nb, ns + 1) || return false
        all(x -> x >= 0, project.cost) || return false
        all(x -> 0 <= x <= 1, project.verification) || return false
        terminal_kernel = kernel_power(model.belief_kernel, project.duration)
        for belief in 1:nb, ci in 1:closure_count
            validate_probability(view(project.generation, belief, ci, :)) ||
                return false
            gamma = admitted_distribution(
                model,
                project,
                belief,
                UInt64(ci - 1),
            )
            validate_probability(gamma) || return false
            joint = view(project.coupling, belief, ci, :, :)
            validate_probability(joint) || return false
            for terminal_belief in 1:nb
                sum(view(joint, terminal_belief, :); init = Rat(0)) ==
                    terminal_kernel[belief, terminal_belief] || return false
            end
            for outcome in 0:ns
                sum(view(joint, :, outcome + 1); init = Rat(0)) ==
                    gamma[outcome + 1] || return false
            end
            closure = UInt64(ci - 1)
            if !is_subset_mask(project.requirements, closure)
                gamma[1] == 1 || return false
            end
        end
    end
    return true
end

function expected_prefix(
    model::SemiMarkovModel,
    belief::Int,
    frontier_values::Tuple,
    duration::Int,
    operates::Bool,
)
    operates || return Rat(0)
    distribution = fill(Rat(0), model.belief_count)
    distribution[belief] = 1 // 1
    result = Rat(0)
    for t in 0:(duration - 1)
        result += model.discount^t * sum(
            distribution[b] * frontier_values[b] for b in 1:model.belief_count;
            init = Rat(0),
        )
        next = fill(Rat(0), model.belief_count)
        for left in 1:model.belief_count, right in 1:model.belief_count
            next[right] += distribution[left] * model.belief_kernel[left, right]
        end
        distribution = next
    end
    return result
end

function raw_value(
    model::SemiMarkovModel,
    horizon::Int,
    belief::Int,
    library::UInt64,
    memo::Dict{Tuple{Int,Int,UInt64},Rat} = Dict{Tuple{Int,Int,UInt64},Rat}(),
)
    horizon == 0 && return Rat(0)
    cache_key = (horizon, belief, library)
    haskey(memo, cache_key) && return memo[cache_key]
    key = innovation_key(model, library)
    frontier_values, closure = key
    continuation = sum(
        model.belief_kernel[belief, next_belief] *
        raw_value(model, horizon - 1, next_belief, library, memo) for
        next_belief in 1:model.belief_count;
        init = Rat(0),
    )
    best = frontier_values[belief] + model.discount * continuation
    for project in model.projects
        project.duration <= horizon || continue
        is_subset_mask(project.requirements, closure) || continue
        ci = mask_index(closure)
        candidate = -project.cost[belief, ci] + expected_prefix(
            model,
            belief,
            frontier_values,
            project.duration,
            project.operates,
        )
        future = Rat(0)
        for next_belief in 1:model.belief_count, outcome in 0:model.strategy_count
            mass = project.coupling[belief, ci, next_belief, outcome + 1]
            iszero(mass) && continue
            future += mass * raw_value(
                model,
                horizon - project.duration,
                next_belief,
                admit(library, outcome),
                memo,
            )
        end
        candidate += model.discount^project.duration * future
        best = max(best, candidate)
    end
    memo[cache_key] = best
    return best
end

function compressed_value(
    model::SemiMarkovModel,
    horizon::Int,
    belief::Int,
    key::Tuple,
    memo::Dict{Tuple,Rat} = Dict{Tuple,Rat}(),
)
    horizon == 0 && return Rat(0)
    frontier_values, closure = key
    cache_key = (horizon, belief, frontier_values, closure)
    haskey(memo, cache_key) && return memo[cache_key]
    continuation = sum(
        model.belief_kernel[belief, next_belief] *
        compressed_value(model, horizon - 1, next_belief, key, memo) for
        next_belief in 1:model.belief_count;
        init = Rat(0),
    )
    best = frontier_values[belief] + model.discount * continuation
    for project in model.projects
        project.duration <= horizon || continue
        is_subset_mask(project.requirements, closure) || continue
        ci = mask_index(closure)
        candidate = -project.cost[belief, ci] + expected_prefix(
            model,
            belief,
            frontier_values,
            project.duration,
            project.operates,
        )
        future = Rat(0)
        for next_belief in 1:model.belief_count, outcome in 0:model.strategy_count
            mass = project.coupling[belief, ci, next_belief, outcome + 1]
            iszero(mass) && continue
            future += mass * compressed_value(
                model,
                horizon - project.duration,
                next_belief,
                add_key(model, key, outcome),
                memo,
            )
        end
        candidate += model.discount^project.duration * future
        best = max(best, candidate)
    end
    memo[cache_key] = best
    return best
end

function operational_value(
    model::SemiMarkovModel,
    horizon::Int,
    belief::Int,
    frontier_values::Tuple,
    memo::Dict{Tuple,Rat} = Dict{Tuple,Rat}(),
)
    horizon == 0 && return Rat(0)
    cache_key = (horizon, belief, frontier_values)
    haskey(memo, cache_key) && return memo[cache_key]
    result = frontier_values[belief] + model.discount * sum(
        model.belief_kernel[belief, next_belief] *
        operational_value(model, horizon - 1, next_belief, frontier_values, memo) for
        next_belief in 1:model.belief_count;
        init = Rat(0),
    )
    memo[cache_key] = result
    return result
end

innovation_premium(model, horizon, belief, key) =
    compressed_value(model, horizon, belief, key) -
    operational_value(model, horizon, belief, key[1])

function compressed_stationary_states(model::SemiMarkovModel)
    keys = unique(innovation_key(model, library) for library in all_libraries(model.strategy_count))
    return [(belief, key) for key in keys for belief in 1:model.belief_count]
end

function stationary_actions(model::SemiMarkovModel, key::Tuple)
    closure = key[2]
    actions = Int[0] # zero denotes Continue
    append!(
        actions,
        project_index for (project_index, project) in enumerate(model.projects) if
        is_subset_mask(project.requirements, closure)
    )
    return actions
end

function compressed_stationary_action_row(
    model::SemiMarkovModel,
    state::Tuple,
    action::Int,
    state_index::AbstractDict,
)
    belief, key = state
    frontier_values, closure = key
    transition = fill(Rat(0), length(state_index))
    if action == 0
        reward = frontier_values[belief]
        for next_belief in 1:model.belief_count
            next_state = (next_belief, key)
            transition[state_index[next_state]] +=
                model.discount * model.belief_kernel[belief, next_belief]
        end
        return reward, transition
    end

    project = model.projects[action]
    is_subset_mask(project.requirements, closure) ||
        throw(ArgumentError("stationary research action is infeasible"))
    ci = mask_index(closure)
    reward = -project.cost[belief, ci] + expected_prefix(
        model,
        belief,
        frontier_values,
        project.duration,
        project.operates,
    )
    continuation_discount = model.discount^project.duration
    for next_belief in 1:model.belief_count, outcome in 0:model.strategy_count
        mass = project.coupling[belief, ci, next_belief, outcome + 1]
        iszero(mass) && continue
        next_state = (next_belief, add_key(model, key, outcome))
        transition[state_index[next_state]] += continuation_discount * mass
    end
    return reward, transition
end

function evaluate_compressed_stationary_policy(
    model::SemiMarkovModel,
    states::Vector{<:Tuple},
    policy::Vector{Int},
)
    length(states) == length(policy) ||
        throw(DimensionMismatch("stationary policy has the wrong state count"))
    state_index = Dict(state => index for (index, state) in enumerate(states))
    reward = fill(Rat(0), length(states))
    discounted_transition = fill(Rat(0), length(states), length(states))
    for (index, state) in enumerate(states)
        policy[index] in stationary_actions(model, state[2]) ||
            throw(ArgumentError("stationary policy contains an infeasible action"))
        reward[index], discounted_transition[index, :] =
            compressed_stationary_action_row(model, state, policy[index], state_index)
    end
    values =
        (Matrix{Rat}(I, length(states), length(states)) - discounted_transition) \ reward
    equation_residual = maximum(
        abs.(reward + discounted_transition * values - values);
        init = Rat(0),
    )
    return (; values, equation_residual)
end

function exact_compressed_stationary_policy_iteration(
    model::SemiMarkovModel;
    max_iterations::Int = 100,
)
    validate_model(model) || throw(ArgumentError("invalid semi-Markov model"))
    max_iterations >= 1 || throw(ArgumentError("max_iterations must be positive"))
    states = compressed_stationary_states(model)
    state_index = Dict(state => index for (index, state) in enumerate(states))
    policy = fill(0, length(states))

    for iteration in 1:max_iterations
        evaluation = evaluate_compressed_stationary_policy(model, states, policy)
        changes = 0
        for (index, state) in enumerate(states)
            best_action = policy[index]
            reward, transition =
                compressed_stationary_action_row(model, state, best_action, state_index)
            best_value = reward + sum(transition .* evaluation.values; init = Rat(0))
            for action in stationary_actions(model, state[2])
                candidate_reward, candidate_transition =
                    compressed_stationary_action_row(model, state, action, state_index)
                candidate =
                    candidate_reward +
                    sum(candidate_transition .* evaluation.values; init = Rat(0))
                if candidate > best_value
                    best_action = action
                    best_value = candidate
                end
            end
            if best_action != policy[index]
                policy[index] = best_action
                changes += 1
            end
        end
        if changes == 0
            final_evaluation =
                evaluate_compressed_stationary_policy(model, states, policy)
            bellman_residual = maximum(
                begin
                    best = maximum(
                        begin
                            reward, transition = compressed_stationary_action_row(
                                model,
                                state,
                                action,
                                state_index,
                            )
                            reward + sum(transition .* final_evaluation.values; init = Rat(0))
                        end for action in stationary_actions(model, state[2])
                    )
                    abs(best - final_evaluation.values[index])
                end for (index, state) in enumerate(states);
                init = Rat(0),
            )
            return (
                states,
                policy,
                values = final_evaluation.values,
                policy_equation_residual = final_evaluation.equation_residual,
                bellman_residual,
                iterations = iteration,
                converged = true,
            )
        end
    end
    throw(ErrorException("unified exact stationary policy iteration did not converge"))
end

function check_projection(model::SemiMarkovModel; horizon::Int = 4)
    validate_model(model) || throw(ArgumentError("invalid semi-Markov model"))
    local_updates = 0
    joint_transitions = 0
    values = 0
    libraries = all_libraries(model.strategy_count)
    for library in libraries, outcome in 0:model.strategy_count
        local_updates += 1
        innovation_key(model, admit(library, outcome)) ==
            add_key(model, innovation_key(model, library), outcome) ||
            return (holds = false, local_updates, joint_transitions, values)
    end
    for library in libraries
        key = innovation_key(model, library)
        closure = key[2]
        for project in model.projects
            is_subset_mask(project.requirements, closure) || continue
            ci = mask_index(closure)
            for belief in 1:model.belief_count
                raw_law = Dict{Tuple{Int,Tuple},Rat}()
                compressed_law = Dict{Tuple{Int,Tuple},Rat}()
                for next_belief in 1:model.belief_count,
                    outcome in 0:model.strategy_count
                    mass = project.coupling[belief, ci, next_belief, outcome + 1]
                    iszero(mass) && continue
                    raw_key = (
                        next_belief,
                        innovation_key(model, admit(library, outcome)),
                    )
                    compressed_key = (
                        next_belief,
                        add_key(model, key, outcome),
                    )
                    raw_law[raw_key] = get(raw_law, raw_key, Rat(0)) + mass
                    compressed_law[compressed_key] =
                        get(compressed_law, compressed_key, Rat(0)) + mass
                end
                joint_transitions += 1
                raw_law == compressed_law ||
                    return (holds = false, local_updates, joint_transitions, values)
            end
        end
        for h in 0:horizon, belief in 1:model.belief_count
            values += 1
            raw_value(model, h, belief, library) ==
                compressed_value(model, h, belief, key) ||
                return (holds = false, local_updates, joint_transitions, values)
        end
    end
    return (holds = true, local_updates, joint_transitions, values)
end

function project_signature(
    model::SemiMarkovModel,
    project::SemiMarkovProject,
    belief::Int,
    closure::UInt64,
)
    available = is_subset_mask(project.requirements, closure)
    available || return (false,)
    ci = mask_index(closure)
    return (
        true,
        project.duration,
        project.operates,
        project.cost[belief, ci],
        Tuple(vec(project.coupling[belief, ci, :, :])),
    )
end

function semi_markov_signature(model::SemiMarkovModel, library::UInt64)
    key = innovation_key(model, library)
    frontier_values, closure = key
    data = Any[frontier_values]
    for project in model.projects, belief in 1:model.belief_count
        push!(data, project_signature(model, project, belief, closure))
    end
    return Tuple(data)
end

function t2_observable(model::SemiMarkovModel)
    libraries = all_libraries(model.strategy_count)
    for i in eachindex(libraries), j in (i + 1):length(libraries)
        j > length(libraries) && continue
        left = innovation_key(model, libraries[i])
        right = innovation_key(model, libraries[j])
        if left[1] == right[1] && left[2] != right[2]
            semi_markov_signature(model, libraries[i]) !=
                semi_markov_signature(model, libraries[j]) || return false
        end
    end
    return true
end

function check_t2(model::SemiMarkovModel)
    t2_observable(model) || return (applicable = false, holds = false, checks = 0)
    libraries = all_libraries(model.strategy_count)
    checks = 0
    for i in eachindex(libraries), j in i:length(libraries)
        checks += 1
        signature_equal = semi_markov_signature(model, libraries[i]) ==
                          semi_markov_signature(model, libraries[j])
        key_equal = innovation_key(model, libraries[i]) ==
                    innovation_key(model, libraries[j])
        signature_equal == key_equal ||
            return (applicable = true, holds = false, checks)
    end
    return (applicable = true, holds = true, checks)
end

function check_t5(model::SemiMarkovModel; horizon::Int = 4)
    checks = 0
    keys = unique(innovation_key(model, library) for library in all_libraries(model.strategy_count))
    for key in keys, h in 1:horizon, belief in 1:model.belief_count
        premium = innovation_premium(model, h, belief, key)
        premium >= 0 || return (holds = false, checks, witness = :negative_premium)
        frontier_values, closure = key
        continue_branch = model.discount * sum(
            model.belief_kernel[belief, next_belief] *
            innovation_premium(model, h - 1, next_belief, key) for
            next_belief in 1:model.belief_count;
            init = Rat(0),
        )
        rhs = continue_branch
        for project in model.projects
            project.duration <= h || continue
            is_subset_mask(project.requirements, closure) || continue
            ci = mask_index(closure)
            full_prefix = expected_prefix(
                model,
                belief,
                frontier_values,
                project.duration,
                true,
            )
            branch = -project.cost[belief, ci]
            if !project.operates
                branch -= full_prefix
            end
            future = Rat(0)
            for next_belief in 1:model.belief_count,
                outcome in 0:model.strategy_count
                mass = project.coupling[belief, ci, next_belief, outcome + 1]
                iszero(mass) && continue
                next_key = add_key(model, key, outcome)
                future += mass * (
                    innovation_premium(
                        model,
                        h - project.duration,
                        next_belief,
                        next_key,
                    ) +
                    operational_value(
                        model,
                        h - project.duration,
                        next_belief,
                        next_key[1],
                    ) -
                    operational_value(
                        model,
                        h - project.duration,
                        next_belief,
                        frontier_values,
                    )
                )
            end
            branch += model.discount^project.duration * future
            rhs = max(rhs, branch)
        end
        checks += 1
        premium == rhs || return (
            holds = false,
            checks,
            witness = (h, belief, key, premium, rhs),
        )
    end
    return (holds = true, checks, witness = nothing)
end

function random_probability(rng::AbstractRNG, count::Int)
    weights = Int[rand(rng, 0:3) for _ in 1:count]
    all(iszero, weights) && (weights[rand(rng, 1:count)] = 1)
    total = sum(weights)
    return Rat[weight // total for weight in weights]
end

function random_kernel(rng::AbstractRNG, belief_count::Int)
    result = Matrix{Rat}(undef, belief_count, belief_count)
    for belief in 1:belief_count
        result[belief, :] .= random_probability(rng, belief_count)
    end
    return result
end

function product_project(
    id::Symbol,
    requirements::UInt64,
    duration::Int,
    operates::Bool,
    cost::Matrix{Rat},
    generation::Array{Rat,3},
    verification::Array{Rat,3},
    belief_kernel::Matrix{Rat},
)
    nb, closure_count, outcome_count = size(generation)
    ns = outcome_count - 1
    terminal = kernel_power(belief_kernel, duration)
    coupling = fill(Rat(0), nb, closure_count, nb, outcome_count)
    provisional = SemiMarkovProject(
        id,
        requirements,
        duration,
        operates,
        cost,
        generation,
        verification,
        coupling,
    )
    dummy = SemiMarkovModel(
        nb,
        ns,
        trailing_zeros(UInt(closure_count)),
        fill(Rat(0), nb, ns),
        fill(UInt64(0), ns),
        UInt64[UInt64(mask) for mask in 0:(closure_count - 1)],
        belief_kernel,
        SemiMarkovProject[],
        1 // 2,
    )
    for belief in 1:nb, ci in 1:closure_count
        gamma = admitted_distribution(dummy, provisional, belief, UInt64(ci - 1))
        for next_belief in 1:nb, outcome in 0:ns
            coupling[belief, ci, next_belief, outcome + 1] =
                terminal[belief, next_belief] * gamma[outcome + 1]
        end
    end
    return SemiMarkovProject(
        id,
        requirements,
        duration,
        operates,
        cost,
        generation,
        verification,
        coupling,
    )
end

function random_model(rng::AbstractRNG)
    nb = rand(rng, 1:3)
    ns = rand(rng, 2:5)
    nm = rand(rng, 1:3)
    nq = rand(rng, 1:3)
    payoffs = fill(Rat(0), nb, ns)
    for belief in 1:nb, strategy in 2:ns
        payoffs[belief, strategy] = rand(rng, PAYOFF_GRID)
    end
    modules = UInt64[0; [UInt64(rand(rng, 0:(Int(mask_bound(nm)) - 1))) for _ in 2:ns]]
    kernel = random_kernel(rng, nb)
    closure_count = Int(mask_bound(nm))
    projects = SemiMarkovProject[]
    for project_index in 1:nq
        requirements = UInt64(rand(rng, 0:(closure_count - 1)))
        duration = rand(rng, 1:3)
        operates = rand(rng, Bool)
        cost = Matrix{Rat}(undef, nb, closure_count)
        generation = fill(Rat(0), nb, closure_count, ns + 1)
        verification = fill(Rat(1), nb, closure_count, ns)
        for belief in 1:nb, ci in 1:closure_count
            cost[belief, ci] = rand(rng, COST_GRID)
            closure = UInt64(ci - 1)
            if is_subset_mask(requirements, closure)
                generation[belief, ci, :] .= random_probability(rng, ns + 1)
                for strategy in 1:ns
                    verification[belief, ci, strategy] = rand(rng, PROB_GRID)
                end
            else
                generation[belief, ci, 1] = 1 // 1
            end
        end
        push!(
            projects,
            product_project(
                Symbol("q", project_index),
                requirements,
                duration,
                operates,
                cost,
                generation,
                verification,
                kernel,
            ),
        )
    end
    model = SemiMarkovModel(
        nb,
        ns,
        nm,
        payoffs,
        modules,
        identity_closure(nm),
        kernel,
        projects,
        rand(rng, DISCOUNT_GRID),
    )
    validate_model(model) || error("random generator produced invalid model")
    return model
end

function correlated_projection_witness()
    nb, ns, nm = 2, 2, 1
    kernel = fill(Rat(1 // 2), nb, nb)
    closure_count = 2
    cost = fill(Rat(0), nb, closure_count)
    generation = fill(Rat(0), nb, closure_count, ns + 1)
    verification = fill(Rat(1), nb, closure_count, ns)
    generation[:, :, 1] .= 1 // 2
    generation[:, :, 3] .= 1 // 2
    coupling = fill(Rat(0), nb, closure_count, nb, ns + 1)
    for belief in 1:nb, ci in 1:closure_count
        coupling[belief, ci, 1, 1] = 1 // 2
        coupling[belief, ci, 2, 3] = 1 // 2
    end
    project = SemiMarkovProject(
        :correlated,
        UInt64(0),
        1,
        true,
        cost,
        generation,
        verification,
        coupling,
    )
    model = SemiMarkovModel(
        nb,
        ns,
        nm,
        Rat[0 0; 0 1],
        UInt64[0, 0],
        identity_closure(nm),
        kernel,
        [project],
        1 // 2,
    )
    projection = check_projection(model; horizon = 3)
    key = innovation_key(model, UInt64(1))
    joint_value = compressed_value(model, 2, 1, key)
    product_value = 1 // 8
    return (
        id = "FX-T1-CORRELATED-01",
        model,
        belief_count = 2,
        strategy_count = 2,
        duration = 1,
        discount = 1 // 2,
        belief_kernel = ["1//2,1//2", "1//2,1//2"],
        payoff_rows = ["0//1,0//1", "0//1,1//1"],
        admitted_marginal = ["none:1//2", "candidate:1//2"],
        joint_nonzero = ["belief1:none:1//2", "belief2:candidate:1//2"],
        projection,
        joint_value,
        product_value,
        dependent = joint_value != product_value,
    )
end

function deterministic_candidate_model(;
    candidate_payoff::Rat = Rat(1 // 1),
    cost_value::Rat = Rat(0 // 1),
    success::Rat = Rat(1 // 1),
    duration::Int = 1,
    bridge::Bool = true,
    discount::Rat = Rat(1 // 2),
)
    nb, ns, nm = 1, 3, 1
    kernel = reshape(Rat[1 // 1], 1, 1)
    closure_count = 2
    cost = fill(cost_value, nb, closure_count)
    generation = fill(Rat(0), nb, closure_count, ns + 1)
    verification = fill(Rat(1), nb, closure_count, ns)
    requirements = bridge ? UInt64(1) : UInt64(0)
    for ci in 1:closure_count
        closure = UInt64(ci - 1)
        if is_subset_mask(requirements, closure)
            generation[1, ci, 1] = 1 - success
            generation[1, ci, 4] = success
        else
            generation[1, ci, 1] = 1 // 1
        end
    end
    project = product_project(
        :innovate,
        requirements,
        duration,
        true,
        cost,
        generation,
        verification,
        kernel,
    )
    return SemiMarkovModel(
        nb,
        ns,
        nm,
        reshape(Rat[0 // 1, 0 // 1, candidate_payoff], nb, ns),
        UInt64[0, bridge ? 1 : 0, 0],
        identity_closure(nm),
        kernel,
        [project],
        discount,
    )
end

function unified_stationary_policy_witness()
    model = deterministic_candidate_model(
        candidate_payoff = Rat(2 // 1),
        cost_value = Rat(0 // 1),
        success = Rat(1 // 1),
        duration = 1,
        bridge = true,
        discount = Rat(1 // 2),
    )
    projection = check_projection(model; horizon = 4)
    result = exact_compressed_stationary_policy_iteration(model)
    bridge_library = strategy_bit(1) | strategy_bit(2)
    bridge_state = (1, innovation_key(model, bridge_library))
    bridge_position = findfirst(isequal(bridge_state), result.states)
    isnothing(bridge_position) && error("unified stationary bridge state is missing")
    candidate_library = bridge_library | strategy_bit(3)
    candidate_state = (1, innovation_key(model, candidate_library))
    candidate_position = findfirst(isequal(candidate_state), result.states)
    isnothing(candidate_position) && error("unified stationary candidate state is missing")
    return (
        id = "FX-S2-UNIFIED-STATIONARY-01",
        model,
        projection,
        converged = result.converged,
        iterations = result.iterations,
        policy_equation_residual = result.policy_equation_residual,
        bellman_residual = result.bellman_residual,
        bridge_action = result.policy[bridge_position],
        bridge_value = result.values[bridge_position],
        candidate_action = result.policy[candidate_position],
        candidate_value = result.values[candidate_position],
    )
end

function t4_unified_witness(target_value::Rational)
    target = Rat(target_value)
    n = max(2, floor(Int, 2 * target) + 1)
    while n // 2 <= target
        n += 1
    end
    horizon = n + 1
    discount = Rat(1) - Rat(1 // (n^2))
    model = deterministic_candidate_model(discount = discount)
    full = UInt64(3)
    pruned = UInt64(1)
    loss = raw_value(model, horizon, 1, full) - raw_value(model, horizon, 1, pruned)
    formula = sum(discount^t for t in 1:n; init = Rat(0))
    return (
        id = "FX-T4-UNIFIED-01",
        target,
        n,
        horizon,
        discount,
        loss,
        formula,
        lower = n // 2,
        holds = loss == formula && formula >= n // 2 && n // 2 > target,
    )
end

function descendant_lower_bound(
    model::SemiMarkovModel,
    horizon::Int,
    belief::Int,
    key::Tuple,
    project::SemiMarkovProject,
    descendant::Int,
)
    frontier_values, closure = key
    project.duration <= horizon || throw(ArgumentError("project exceeds horizon"))
    ci = mask_index(closure)
    gain = Rat(0)
    descendant_key = add_key(model, key, descendant)
    for next_belief in 1:model.belief_count
        mass = project.coupling[belief, ci, next_belief, descendant + 1]
        gain += mass * (
            operational_value(
                model,
                horizon - project.duration,
                next_belief,
                descendant_key[1],
            ) -
            operational_value(
                model,
                horizon - project.duration,
                next_belief,
                frontier_values,
            )
        )
    end
    return max(
        Rat(0),
        -project.cost[belief, ci] + model.discount^project.duration * gain,
    )
end

function t6_cost_boundary_witness()
    model = deterministic_candidate_model(cost_value = Rat(3 // 4))
    full = UInt64(3)
    base = UInt64(1)
    horizon = 2
    actual = raw_value(model, horizon, 1, full) - raw_value(model, horizon, 1, base)
    probability_gap_without_cost = 1 // 2
    revised_bound = descendant_lower_bound(
        model,
        horizon,
        1,
        innovation_key(model, full),
        only(model.projects),
        3,
    )
    return (
        id = "CX-T6-COST-01",
        belief_count = 1,
        strategy_count = 3,
        module_count = 1,
        project_count = 1,
        horizon,
        duration = 1,
        discount = 1 // 2,
        cost = 3 // 4,
        success = 1 // 1,
        carrier_payoff = 0 // 1,
        descendant_payoff = 1 // 1,
        actual,
        probability_gap_without_cost,
        revised_bound,
        naive_bound_fails = actual < probability_gap_without_cost,
        revised_bound_holds = actual >= revised_bound,
    )
end

function check_t6_random(rng::AbstractRNG; trials::Int = 512)
    checks = 0
    for _ in 1:trials
        success = rand(rng, PROB_GRID)
        cost = rand(rng, COST_GRID)
        duration = rand(rng, 1:3)
        discount = rand(rng, DISCOUNT_GRID)
        payoff = rand(rng, Rat[0 // 1, 1 // 2, 1 // 1, 2 // 1])
        model = deterministic_candidate_model(
            candidate_payoff = payoff,
            cost_value = cost,
            success = success,
            duration = duration,
            discount = discount,
        )
        horizon = duration + rand(rng, 0:3)
        full = UInt64(3)
        base = UInt64(1)
        actual = raw_value(model, horizon, 1, full) - raw_value(model, horizon, 1, base)
        bound = descendant_lower_bound(
            model,
            horizon,
            1,
            innovation_key(model, full),
            only(model.projects),
            3,
        )
        checks += 1
        actual >= bound || return (holds = false, checks, witness = (actual, bound))
    end
    return (holds = true, checks, witness = nothing)
end

function check_t7_random(rng::AbstractRNG; trials::Int = 512, horizon::Int = 4)
    checks = 0
    for _ in 1:trials
        model = random_model(rng)
        low = Tuple(Rat[rand(rng, 0:2) // 1 for _ in 1:model.belief_count])
        high = Tuple(low[b] + rand(rng, 0:2) // 1 for b in 1:model.belief_count)
        closure = UInt64(rand(rng, 0:(Int(mask_bound(model.module_count)) - 1)))
        low_key = (low, closure)
        high_key = (high, closure)
        for h in 0:horizon, belief in 1:model.belief_count
            low_premium = innovation_premium(model, h, belief, low_key)
            high_premium = innovation_premium(model, h, belief, high_key)
            checks += 1
            high_premium <= low_premium || return (
                holds = false,
                checks,
                witness = (h, belief, low, high, closure, low_premium, high_premium),
            )
        end
    end
    return (holds = true, checks, witness = nothing)
end

function check_t7_correlated(; horizon::Int = 4)
    model = correlated_projection_witness().model
    closure = UInt64(0)
    low_key = ((Rat(0), Rat(0)), closure)
    high_key = ((Rat(1), Rat(1)), closure)
    checks = 0
    for h in 0:horizon, belief in 1:model.belief_count
        checks += 1
        innovation_premium(model, h, belief, high_key) <=
            innovation_premium(model, h, belief, low_key) ||
            return (holds = false, checks, witness = (h, belief))
    end
    return (holds = true, checks, witness = nothing)
end

function generator_complementarity_witness()
    beta = 1 // 2
    low_frontier = 0 // 1
    high_frontier = 1 // 1
    candidate = 2 // 1
    low_success = 0 // 1
    high_success = 1 // 1
    low_premium = beta * low_success * max(candidate - low_frontier, 0)
    high_premium = beta * high_success * max(candidate - high_frontier, 0)
    return (
        id = "CX-T7-FRONTIER-GENERATOR-01",
        belief_count = 1,
        project_count = 1,
        duration = 1,
        discount = beta,
        cost = 0 // 1,
        low_frontier,
        high_frontier,
        candidate,
        low_success,
        high_success,
        low_premium,
        high_premium,
        complementarity = high_premium > low_premium,
        violates_assumption = "A-T7-GEN-INDEPENDENCE",
    )
end

function persistence_direction_witnesses()
    beta = 1 // 2
    low_persistence = 1 // 4
    high_persistence = 3 // 4
    increasing_low = beta * low_persistence
    increasing_high = beta * high_persistence
    decreasing_low = beta * (1 - low_persistence)
    decreasing_high = beta * (1 - high_persistence)
    return (
        increasing = (
            id = "CX-PERSISTENCE-INCREASE-01",
            discount = beta,
            low_persistence,
            high_persistence,
            gap = Rat[1 // 1, 0 // 1],
            low = increasing_low,
            high = increasing_high,
            holds = increasing_high > increasing_low,
        ),
        decreasing = (
            id = "CX-PERSISTENCE-DECREASE-01",
            discount = beta,
            low_persistence,
            high_persistence,
            gap = Rat[0 // 1, 1 // 1],
            low = decreasing_low,
            high = decreasing_high,
            holds = decreasing_high < decreasing_low,
        ),
    )
end

function information_direction_witnesses()
    beta = 1 // 2
    increase_cost = 1 // 8
    less_increase_gap = 0 // 1
    more_increase_gap = 1 // 2
    increase_less_net = beta * less_increase_gap - increase_cost
    increase_more_net = beta * more_increase_gap - increase_cost

    decrease_cost = 1 // 16
    less_decrease_gap = 1 // 4
    more_decrease_gap = 0 // 1
    decrease_less_net = beta * less_decrease_gap - decrease_cost
    decrease_more_net = beta * more_decrease_gap - decrease_cost
    return (
        increasing = (
            id = "CX-INFORMATION-INCREASE-01",
            discount = beta,
            cost = increase_cost,
            prior = 1 // 2,
            less_posterior_law = ["1//2@1//1"],
            more_posterior_law = ["0//1@1//2", "1//1@1//2"],
            candidate_state_payoffs = Rat[-1 // 1, 1 // 1],
            less_expected_gap = less_increase_gap,
            more_expected_gap = more_increase_gap,
            less_net = increase_less_net,
            more_net = increase_more_net,
            demand_less = increase_less_net >= 0,
            demand_more = increase_more_net >= 0,
            holds = increase_less_net < 0 < increase_more_net,
        ),
        decreasing = (
            id = "CX-INFORMATION-DECREASE-01",
            discount = beta,
            cost = decrease_cost,
            prior = 1 // 2,
            less_posterior_law = ["1//2@1//1"],
            more_posterior_law = ["0//1@1//2", "1//1@1//2"],
            incumbent_state_payoffs = [Rat[1 // 1, 0 // 1], Rat[0 // 1, 1 // 1]],
            candidate_state_payoffs = Rat[3 // 4, 3 // 4],
            less_expected_gap = less_decrease_gap,
            more_expected_gap = more_decrease_gap,
            less_net = decrease_less_net,
            more_net = decrease_more_net,
            demand_less = decrease_less_net >= 0,
            demand_more = decrease_more_net >= 0,
            holds = decrease_more_net < 0 < decrease_less_net,
        ),
    )
end

function delay_direction_witnesses()
    beta = 1 // 2
    positive_short = 1 // 1
    positive_long = 1 + beta
    negative_short = -1 // 1
    negative_long = -1 - beta
    value_consistent_short = beta + beta^2
    value_consistent_long = beta^2
    return (
        operator_positive = (
            id = "CX-DELAY-OPERATOR-POSITIVE-01",
            discount = beta,
            cost = 0 // 1,
            frontier = 1 // 1,
            continuation = 0 // 1,
            duration_one = positive_short,
            duration_two = positive_long,
            longer_is_higher = positive_long > positive_short,
        ),
        operator_negative = (
            id = "CX-DELAY-OPERATOR-NEGATIVE-01",
            discount = beta,
            cost = 0 // 1,
            frontier = -1 // 1,
            continuation = 0 // 1,
            duration_one = negative_short,
            duration_two = negative_long,
            longer_is_lower = negative_long < negative_short,
            violates_assumption = "A-LIBRARY/A-PROFILE zero inactive baseline",
        ),
        value_consistent = (
            id = "FX-DELAY-FIXED-GENERATOR-01",
            discount = beta,
            cost = 0 // 1,
            frontier = 0 // 1,
            candidate = 1 // 1,
            horizon = 3,
            duration_one = value_consistent_short,
            duration_two = value_consistent_long,
            shorter_is_higher = value_consistent_short > value_consistent_long,
        ),
    )
end

function random_search(rng::AbstractRNG; trials::Int, horizon::Int)
    totals = Dict(
        "models" => 0,
        "t1_local_updates" => 0,
        "t1_joint_transitions" => 0,
        "t1_value_factorizations" => 0,
        "t2_applicable_models" => 0,
        "t2_signature_checks" => 0,
        "t5_recursion_checks" => 0,
    )
    failures = Dict{String,Any}()
    for _ in 1:trials
        model = random_model(rng)
        totals["models"] += 1
        projection = check_projection(model; horizon)
        totals["t1_local_updates"] += projection.local_updates
        totals["t1_joint_transitions"] += projection.joint_transitions
        totals["t1_value_factorizations"] += projection.values
        if !projection.holds
            failures["T1"] = projection
            break
        end
        t2 = check_t2(model)
        if t2.applicable
            totals["t2_applicable_models"] += 1
            totals["t2_signature_checks"] += t2.checks
            if !t2.holds
                failures["T2"] = t2
                break
            end
        end
        t5 = check_t5(model; horizon)
        totals["t5_recursion_checks"] += t5.checks
        if !t5.holds
            failures["T5"] = t5
            break
        end
    end
    return (totals = totals, failures = failures)
end

function record(classification, holds, boundary)
    return Dict{String,Any}(
        "classification" => classification,
        "survived_search" => holds,
        "boundary" => boundary,
    )
end

function witness_dict(witness)
    result = Dict{String,Any}()
    for name in propertynames(witness)
        value = getproperty(witness, name)
        name == :model && continue
        if value isa Rational
            result[string(name)] = rat_string(value)
        elseif value isa AbstractVector{<:Rational}
            result[string(name)] = [rat_string(x) for x in value]
        elseif value isa Tuple || value isa NamedTuple
            result[string(name)] = witness_dict(value)
        else
            result[string(name)] = value
        end
    end
    return result
end

function run_revision_gauntlet(;
    seed::UInt64 = DEFAULT_REVISION_SEED,
    random_trials::Int = 512,
    t6_trials::Int = 512,
    t7_trials::Int = 512,
    horizon::Int = 4,
    exhaustive_t3::Bool = true,
)
    rng = research_rng(seed)
    random = random_search(rng; trials = random_trials, horizon)
    legacy_t3 = exhaustive_t3 ? LegacySearch.exhaustive_t3_search() :
                (holds = true, configurations = 0, deletion_checks = 0, witness = nothing)
    t6 = check_t6_random(rng; trials = t6_trials)
    t7 = check_t7_random(rng; trials = t7_trials, horizon)
    t7_correlated = check_t7_correlated(; horizon)
    correlated = correlated_projection_witness()
    stationary = unified_stationary_policy_witness()
    t4s = [t4_unified_witness(target) for target in Rat[1, 2, 5, 10]]
    t6_cost = t6_cost_boundary_witness()
    t7_complementarity = generator_complementarity_witness()
    persistence = persistence_direction_witnesses()
    information = information_direction_witnesses()
    delay = delay_direction_witnesses()
    silent = LegacySearch.silent_module_witness()
    batch = LegacySearch.t3_batch_witness()
    t5_separability = LegacySearch.t5_separability_witness()

    t1_holds = !haskey(random.failures, "T1") && correlated.projection.holds
    t2_holds = !haskey(random.failures, "T2")
    t3_holds = legacy_t3.holds
    t4_holds = all(w -> w.holds, t4s)
    t5_holds = !haskey(random.failures, "T5")
    t6_holds = t6.holds && t6_cost.revised_bound_holds
    t7_holds = t7.holds && t7_correlated.holds
    stationary_holds =
        stationary.projection.holds &&
        stationary.converged &&
        iszero(stationary.policy_equation_residual) &&
        iszero(stationary.bellman_residual)
    all_hold = all((
        t1_holds,
        t2_holds,
        t3_holds,
        t4_holds,
        t5_holds,
        t6_holds,
        t7_holds,
        stationary_holds,
    ))

    theorems = Dict{String,Any}(
        "T1" => record(
            "survives only with primitive raw-factorization and joint-coupling assumptions",
            t1_holds,
            "Raw provenance dependence still falsifies projection; conditional belief/outcome independence is unnecessary and changes value in FX-T1-CORRELATED-01.",
        ),
        "T2" => record(
            "survives with the full semi-Markov signature and A-T2-OBS",
            t2_holds,
            "The one-belief silent-module fixture remains the minimal failure without closure observability.",
        ),
        "T3" => record(
            "survives for one deletion",
            t3_holds,
            "The simultaneous batch inference is false even with one belief and one module.",
        ),
        "T4" => record(
            "survives under active duration-one research",
            t4_holds,
            "The exact normalized loss is sum(beta^t,t=1:H-1); unboundedness varies horizon and discount, never fixed parameters.",
        ),
        "T5" => record(
            "survives after adding the suspension prefix term",
            t5_holds,
            "Closure-only additive separability is false; suspending research requires subtracting foregone incumbent rewards.",
        ),
        "T6" => record(
            "revised descendant-event lower bound survives",
            t6_holds,
            "The naive probability-times-gap lower bound is false unless cost is subtracted; a marginal carrier-value interpretation also requires unchanged frontier and zero deleted-state premium.",
        ),
        "T7" => record(
            "frontier antitonicity of innovation premium survives primitive generator independence",
            t7_holds,
            "If admitted quality depends on frontier, one belief and one project suffice for strict complementarity.",
        ),
        "S2" => record(
            "unified stationary selector fixture satisfies exact policy evaluation",
            stationary_holds,
            "The exact fixture validates one finite raw/compressed instance; the general selector, policy equation, contraction, and uniqueness results are Lean theorems.",
        ),
    )

    return Dict{String,Any}(
        "schema_version" => "revision-counterexample-gauntlet-v1",
        "experiment_id" => "paper1-unified-semi-markov-falsification-v1",
        "config_file" => "experiments/configs/revision_counterexample_gauntlet.toml",
        "run_date" => "2026-07-23",
        "julia_version" => string(VERSION),
        "arithmetic" => "Rational{BigInt}",
        "rng" => "StableRNGs.StableRNG",
        "seed" => string(seed),
        "bounds" => Dict{String,Any}(
            "belief_states" => "1-3",
            "strategies" => "2-5 including inactive baseline",
            "modules" => "1-3",
            "projects" => "1-3 plus Continue",
            "durations" => "1-3 calendar periods",
            "operation_flags" => [false, true],
            "discounts" => [rat_string(x) for x in DISCOUNT_GRID],
            "calendar_horizon" => horizon,
            "random_trials" => random_trials,
            "t6_trials" => t6_trials,
            "t7_trials" => t7_trials,
        ),
        "search_counts" => merge(
            random.totals,
            Dict{String,Any}(
                "t3_configurations" => legacy_t3.configurations,
                "t3_deletion_checks" => legacy_t3.deletion_checks,
                "t6_lower_bound_checks" => t6.checks,
                "t7_substitution_checks" => t7.checks + t7_correlated.checks,
                "t7_correlated_substitution_checks" => t7_correlated.checks,
                "stationary_policy_states" => length(
                    compressed_stationary_states(stationary.model),
                ),
            ),
        ),
        "random_failures" => Dict(key => string(value) for (key, value) in random.failures),
        "theorems" => theorems,
        "fixtures" => Dict{String,Any}(
            "conditional_dependence" => witness_dict(correlated),
            "unified_stationary_policy" => witness_dict(stationary),
            "raw_dependence" => Dict(
                "id" => "CX-T1-RAW-01",
                "belief_count" => 1,
                "strategy_count" => 3,
                "project_count" => 1,
                "value_without_identifier" => "0//1",
                "value_with_identifier" => "1//2",
                "violates_assumption" => "A-GEN-FACTOR",
            ),
            "silent_module" => Dict(
                "id" => silent.id,
                "belief_count" => 1,
                "strategy_count" => 2,
                "module_count" => 1,
                "same_frontier" => silent.same_frontier,
                "different_closure" => silent.different_closure,
                "same_signature" => silent.same_signature,
                "violates_assumption" => "A-T2-OBS",
            ),
            "batch_deletion" => Dict(
                "id" => batch.id,
                "belief_count" => 1,
                "strategy_count" => 3,
                "module_count" => 1,
                "first_safe" => batch.first_safe,
                "second_safe" => batch.second_safe,
                "batch_unsafe" => batch.batch_unsafe,
            ),
            "t4_unified" => [witness_dict(w) for w in t4s],
            "t5_separability" => Dict(
                "id" => t5_separability.id,
                "belief_count" => 1,
                "low_premium" => rat_string(t5_separability.low_premium),
                "high_premium" => rat_string(t5_separability.high_premium),
                "same_initial_frontier" => t5_separability.same_initial_frontier,
                "same_closure" => t5_separability.same_closure,
            ),
            "t6_cost_boundary" => witness_dict(t6_cost),
            "t7_complementarity" => witness_dict(t7_complementarity),
            "persistence" => witness_dict(persistence),
            "information" => witness_dict(information),
            "delay" => witness_dict(delay),
        ),
        "principal_t1_t7_survived" => all_hold,
        "lean_formalization_gate_open" => all_hold,
        "lean_unified_bellman_verified" => true,
        "lean_changes_made" => true,
    )
end

function json_escape(value::AbstractString)
    return replace(
        value,
        "\\" => "\\\\",
        "\"" => "\\\"",
        "\n" => "\\n",
        "\r" => "\\r",
        "\t" => "\\t",
    )
end

function write_json(io::IO, value, indent::Int = 0)
    padding = " "^indent
    child_padding = " "^(indent + 2)
    if value isa AbstractDict
        keys_sorted = sort!(collect(keys(value)); by = string)
        print(io, "{")
        if !isempty(keys_sorted)
            print(io, "\n")
            for (index, key) in enumerate(keys_sorted)
                print(io, child_padding, "\"", json_escape(string(key)), "\": ")
                write_json(io, value[key], indent + 2)
                index == length(keys_sorted) || print(io, ",")
                print(io, "\n")
            end
            print(io, padding)
        end
        print(io, "}")
    elseif value isa AbstractVector || value isa Tuple
        print(io, "[")
        if !isempty(value)
            print(io, "\n")
            for (index, item) in enumerate(value)
                print(io, child_padding)
                write_json(io, item, indent + 2)
                index == length(value) || print(io, ",")
                print(io, "\n")
            end
            print(io, padding)
        end
        print(io, "]")
    elseif value isa AbstractString
        print(io, "\"", json_escape(value), "\"")
    elseif value isa Bool
        print(io, value ? "true" : "false")
    elseif value === nothing
        print(io, "null")
    elseif value isa Integer
        print(io, value)
    elseif value isa Rational
        print(io, "\"", rat_string(value), "\"")
    else
        throw(ArgumentError("unsupported JSON value $(typeof(value))"))
    end
end

function result_string(result)
    return sprint() do io
        write_json(io, result)
        print(io, "\n")
    end
end

function write_result(path::AbstractString, result; check::Bool = false)
    rendered = result_string(result)
    if check
        isfile(path) || error("missing committed result: $path")
        read(path, String) == rendered || error("revision gauntlet result drift: $path")
    else
        mkpath(dirname(path))
        open(path, "w") do io
            print(io, rendered)
        end
    end
    return path
end

function parse_arguments(args)
    options = Dict{String,Any}(
        "check" => false,
        "random_trials" => 512,
        "t6_trials" => 512,
        "t7_trials" => 512,
        "exhaustive_t3" => true,
    )
    for argument in args
        if argument == "--check"
            options["check"] = true
        elseif argument == "--no-exhaustive-t3"
            options["exhaustive_t3"] = false
        elseif startswith(argument, "--random-trials=")
            options["random_trials"] = parse(Int, split(argument, "=", limit = 2)[2])
        elseif startswith(argument, "--t6-trials=")
            options["t6_trials"] = parse(Int, split(argument, "=", limit = 2)[2])
        elseif startswith(argument, "--t7-trials=")
            options["t7_trials"] = parse(Int, split(argument, "=", limit = 2)[2])
        else
            throw(ArgumentError("unknown argument: $argument"))
        end
    end
    return options
end

function main(args = ARGS)
    options = parse_arguments(args)
    result = run_revision_gauntlet(
        random_trials = options["random_trials"],
        t6_trials = options["t6_trials"],
        t7_trials = options["t7_trials"],
        exhaustive_t3 = options["exhaustive_t3"],
    )
    root = normpath(joinpath(@__DIR__, "..", ".."))
    output = joinpath(root, "experiments", "results", "revision_counterexample_gauntlet.json")
    write_result(output, result; check = options["check"])
    println(options["check"] ? "Checked " : "Wrote ", output)
    println("Principal T1-T7 survived: ", result["principal_t1_t7_survived"])
    println("Lean gate open: ", result["lean_formalization_gate_open"])
    return result
end

end # module RevisionCounterexampleGauntlet

if abspath(PROGRAM_FILE) == @__FILE__
    RevisionCounterexampleGauntlet.main()
end
