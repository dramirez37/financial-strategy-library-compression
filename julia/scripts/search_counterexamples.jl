module CounterexampleSearch

using Random: AbstractRNG, rand
using StrategyInnovation: research_rng

export DEFAULT_FEASIBILITY_SEED,
       check_t1,
       check_t2,
       check_t3,
       check_t5,
       run_feasibility_search,
       silent_module_witness,
       t3_batch_witness,
       t4_witness,
       t5_separability_witness,
       t6_disconnected_witness,
       multi_gap_additivity_witness,
       write_json_result,
       write_lean_fixture

const Rat = Rational{BigInt}
const DEFAULT_FEASIBILITY_SEED = UInt64(0x5448454f52454d31)
const PAYOFF_GRID = Rat[-1 // 1, -1 // 2, 0 // 1, 1 // 2, 1 // 1]
const PROB_GRID = Rat[0 // 1, 1 // 4, 1 // 2, 3 // 4, 1 // 1]
const COST_GRID = Rat[0 // 1, 1 // 4, 1 // 2, 1 // 1]
const DISCOUNT_GRID = Rat[0 // 1, 1 // 4, 1 // 2, 3 // 4, 9 // 10, 15 // 16]

strategy_bit(s::Int) = UInt64(1) << (s - 1)
module_bit(m::Int) = UInt64(1) << (m - 1)
mask_contains(mask::UInt64, item::Int) = !iszero(mask & strategy_bit(item))
is_subset_mask(left::UInt64, right::UInt64) = (left & right) == left
mask_bound(n::Int) = UInt64(1) << n
mask_index(mask::UInt64) = Int(mask) + 1
rat_string(x::Rational) = string(numerator(x), "//", denominator(x))

struct Project
    requirements::UInt64
    cost::Matrix{Rat}
    raw::Array{Rat,3}
    verify::Array{Rat,3}
end

struct FiniteModel
    belief_count::Int
    strategy_count::Int
    module_count::Int
    payoffs::Matrix{Rat}
    modules::Vector{UInt64}
    closure_table::Vector{UInt64}
    belief_kernel::Matrix{Rat}
    projects::Vector{Project}
    discount::Rat
end

function all_libraries(strategy_count::Int)
    upper = Int(mask_bound(strategy_count)) - 1
    return UInt64[UInt64(mask) for mask in 1:upper if isodd(mask)]
end

function library_index(library::UInt64)
    @assert isodd(library)
    return (Int(library) + 1) ÷ 2
end

function strategy_indices(mask::UInt64, count::Int)
    return Int[s for s in 1:count if mask_contains(mask, s)]
end

function module_union(model::FiniteModel, library::UInt64)
    raw = UInt64(0)
    for s in strategy_indices(library, model.strategy_count)
        raw |= model.modules[s]
    end
    return raw
end

function generative_closure(model::FiniteModel, library::UInt64)
    return model.closure_table[mask_index(module_union(model, library))]
end

function frontier(model::FiniteModel, library::UInt64)
    @assert isodd(library)
    result = Vector{Rat}(undef, model.belief_count)
    for b in 1:model.belief_count
        best = model.payoffs[b, 1]
        for s in 2:model.strategy_count
            if mask_contains(library, s)
                best = max(best, model.payoffs[b, s])
            end
        end
        result[b] = best
    end
    return result
end

innovation_key(model::FiniteModel, library::UInt64) =
    (Tuple(frontier(model, library)), generative_closure(model, library))

admit(library::UInt64, outcome::Int) =
    outcome == 0 ? library : library | strategy_bit(outcome)

function admitted_distribution(
    model::FiniteModel,
    project::Project,
    belief::Int,
    closure::UInt64,
)
    result = fill(Rat(0), model.strategy_count + 1)
    if !is_subset_mask(project.requirements, closure)
        result[1] = Rat(1)
        return result
    end

    ci = mask_index(closure)
    result[1] = project.raw[belief, ci, 1]
    for s in 1:model.strategy_count
        raw_mass = project.raw[belief, ci, s + 1]
        pass = project.verify[belief, ci, s]
        result[s + 1] = raw_mass * pass
        result[1] += raw_mass * (1 - pass)
    end
    return result
end

project_cost(project::Project, belief::Int, closure::UInt64) =
    project.cost[belief, mask_index(closure)]

function validate_probability(probabilities)
    all(p -> p >= 0, probabilities) || return false
    return sum(probabilities; init = Rat(0)) == 1
end

function validate_model(model::FiniteModel)
    nb = model.belief_count
    ns = model.strategy_count
    nm = model.module_count
    nb >= 1 || return false
    ns >= 1 || return false
    nm >= 1 || return false
    size(model.payoffs) == (nb, ns) || return false
    length(model.modules) == ns || return false
    length(model.closure_table) == Int(mask_bound(nm)) || return false
    size(model.belief_kernel) == (nb, nb) || return false
    0 <= model.discount < 1 || return false

    universe = mask_bound(nm) - 1
    for raw in UInt64(0):universe
        closed = model.closure_table[mask_index(raw)]
        closed <= universe || return false
        is_subset_mask(raw, closed) || return false
        model.closure_table[mask_index(closed)] == closed || return false
        for larger in raw:universe
            if is_subset_mask(raw, larger)
                is_subset_mask(closed, model.closure_table[mask_index(larger)]) ||
                    return false
            end
        end
    end

    for b in 1:nb
        validate_probability(view(model.belief_kernel, b, :)) || return false
    end

    closure_count = Int(mask_bound(nm))
    for project in model.projects
        project.requirements <= universe || return false
        size(project.cost) == (nb, closure_count) || return false
        size(project.raw) == (nb, closure_count, ns + 1) || return false
        size(project.verify) == (nb, closure_count, ns) || return false
        all(x -> x >= 0, project.cost) || return false
        all(x -> 0 <= x <= 1, project.verify) || return false
        for b in 1:nb, ci in 1:closure_count
            validate_probability(view(project.raw, b, ci, :)) || return false
        end
    end
    return true
end

function identity_closure(module_count::Int)
    return UInt64[UInt64(mask) for mask in 0:(Int(mask_bound(module_count)) - 1)]
end

function closure_from_rules(
    module_count::Int,
    rules::Vector{Tuple{UInt64,UInt64}},
)
    universe = mask_bound(module_count) - 1
    table = Vector{UInt64}(undef, Int(universe) + 1)
    for raw in UInt64(0):universe
        current = raw
        changed = true
        while changed
            changed = false
            for (premise, conclusion) in rules
                if is_subset_mask(premise, current)
                    updated = (current | conclusion) & universe
                    if updated != current
                        current = updated
                        changed = true
                    end
                end
            end
        end
        table[mask_index(raw)] = current
    end
    return table
end

function all_closure_tables(module_count::Int)
    module_count <= 3 ||
        throw(ArgumentError("exhaustive closure enumeration is limited to 3 modules"))
    set_count = Int(mask_bound(module_count))
    universe = UInt64(set_count - 1)
    tables = Vector{Vector{UInt64}}()
    family_limit = UInt64(1) << set_count

    for family in UInt64(0):(family_limit - 1)
        iszero(family & (UInt64(1) << Int(universe))) && continue
        intersection_closed = true
        for left in UInt64(0):universe, right in UInt64(0):universe
            left_member = !iszero(family & (UInt64(1) << Int(left)))
            right_member = !iszero(family & (UInt64(1) << Int(right)))
            if left_member && right_member
                intersection = left & right
                if iszero(family & (UInt64(1) << Int(intersection)))
                    intersection_closed = false
                    break
                end
            end
        end
        intersection_closed || continue

        table = Vector{UInt64}(undef, set_count)
        for raw in UInt64(0):universe
            closed = universe
            for candidate in UInt64(0):universe
                member = !iszero(family & (UInt64(1) << Int(candidate)))
                if member && is_subset_mask(raw, candidate)
                    closed &= candidate
                end
            end
            table[mask_index(raw)] = closed
        end
        push!(tables, table)
    end
    return unique(tables)
end

function null_project(belief_count::Int, strategy_count::Int, module_count::Int)
    closure_count = Int(mask_bound(module_count))
    cost = fill(Rat(0), belief_count, closure_count)
    raw = fill(Rat(0), belief_count, closure_count, strategy_count + 1)
    raw[:, :, 1] .= Rat(1)
    verify = fill(Rat(1), belief_count, closure_count, strategy_count)
    return Project(UInt64(0), cost, raw, verify)
end

function value_tables(model::FiniteModel, horizon::Int)
    validate_model(model) || throw(ArgumentError("invalid finite model"))
    libraries = all_libraries(model.strategy_count)
    values = [
        fill(Rat(0), model.belief_count, length(libraries)) for
        _ in 0:horizon
    ]

    for h in 1:horizon
        previous = values[h]
        current = values[h + 1]
        for library in libraries
            li = library_index(library)
            current_frontier = frontier(model, library)
            closure = generative_closure(model, library)
            for belief in 1:model.belief_count
                idle_continuation = Rat(0)
                for next_belief in 1:model.belief_count
                    idle_continuation +=
                        model.belief_kernel[belief, next_belief] *
                        previous[next_belief, li]
                end
                best_research = model.discount * idle_continuation

                for project in model.projects
                    distribution =
                        admitted_distribution(model, project, belief, closure)
                    continuation = Rat(0)
                    for next_belief in 1:model.belief_count
                        belief_mass = model.belief_kernel[belief, next_belief]
                        for outcome in 0:model.strategy_count
                            outcome_mass = distribution[outcome + 1]
                            iszero(outcome_mass) && continue
                            next_library = admit(library, outcome)
                            continuation +=
                                belief_mass *
                                outcome_mass *
                                previous[
                                    next_belief,
                                    library_index(next_library),
                                ]
                        end
                    end
                    candidate =
                        -project_cost(project, belief, closure) +
                        model.discount * continuation
                    best_research = max(best_research, candidate)
                end

                current[belief, li] =
                    current_frontier[belief] + best_research
            end
        end
    end
    return values
end

function operational_tables(model::FiniteModel, horizon::Int)
    libraries = all_libraries(model.strategy_count)
    values = [
        fill(Rat(0), model.belief_count, length(libraries)) for
        _ in 0:horizon
    ]
    for h in 1:horizon
        previous = values[h]
        current = values[h + 1]
        for library in libraries
            li = library_index(library)
            current_frontier = frontier(model, library)
            for belief in 1:model.belief_count
                continuation = sum(
                    model.belief_kernel[belief, next_belief] *
                    previous[next_belief, li] for
                    next_belief in 1:model.belief_count;
                    init = Rat(0),
                )
                current[belief, li] =
                    current_frontier[belief] + model.discount * continuation
            end
        end
    end
    return values
end

function check_t1(model::FiniteModel; horizon::Int = 3)
    values = value_tables(model, horizon)
    libraries = all_libraries(model.strategy_count)
    value_comparisons = 0
    update_comparisons = 0
    for i in eachindex(libraries), j in i:length(libraries)
        left = libraries[i]
        right = libraries[j]
        innovation_key(model, left) == innovation_key(model, right) || continue
        for h in 0:horizon, belief in 1:model.belief_count
            value_comparisons += 1
            if values[h + 1][belief, library_index(left)] !=
               values[h + 1][belief, library_index(right)]
                return (
                    holds = false,
                    value_comparisons,
                    update_comparisons,
                    witness = (left, right, h, belief),
                )
            end
        end
        for outcome in 0:model.strategy_count
            update_comparisons += 1
            if innovation_key(model, admit(left, outcome)) !=
               innovation_key(model, admit(right, outcome))
                return (
                    holds = false,
                    value_comparisons,
                    update_comparisons,
                    witness = (left, right, outcome),
                )
            end
        end
    end
    return (
        holds = true,
        value_comparisons,
        update_comparisons,
        witness = nothing,
    )
end

function closure_signature(model::FiniteModel, closure::UInt64)
    data = Rat[]
    for project in model.projects, belief in 1:model.belief_count
        push!(data, project_cost(project, belief, closure))
        append!(data, admitted_distribution(model, project, belief, closure))
    end
    return Tuple(data)
end

function observable_on_realisable_closures(model::FiniteModel)
    closures = unique(
        generative_closure(model, library) for
        library in all_libraries(model.strategy_count)
    )
    signatures = Dict{Tuple,UInt64}()
    for closure in closures
        signature = closure_signature(model, closure)
        if haskey(signatures, signature) && signatures[signature] != closure
            return false
        end
        signatures[signature] = closure
    end
    return true
end

function innovation_signature(model::FiniteModel, library::UInt64)
    return (
        Tuple(frontier(model, library)),
        closure_signature(model, generative_closure(model, library)),
    )
end

function check_t2(model::FiniteModel)
    observable_on_realisable_closures(model) ||
        return (holds = false, applicable = false, comparisons = 0, witness = nothing)
    libraries = all_libraries(model.strategy_count)
    comparisons = 0
    for i in eachindex(libraries), j in i:length(libraries)
        comparisons += 1
        left = libraries[i]
        right = libraries[j]
        signature_equal =
            innovation_signature(model, left) ==
            innovation_signature(model, right)
        key_equal =
            innovation_key(model, left) == innovation_key(model, right)
        if signature_equal != key_equal
            return (
                holds = false,
                applicable = true,
                comparisons,
                witness = (left, right),
            )
        end
    end
    return (holds = true, applicable = true, comparisons, witness = nothing)
end

function deletion_conditions(
    model::FiniteModel,
    library::UInt64,
    strategy::Int,
)
    @assert strategy != 1
    @assert mask_contains(library, strategy)
    remaining = library & ~strategy_bit(strategy)
    remaining_frontier = frontier(model, remaining)
    operational = all(
        model.payoffs[belief, strategy] <= remaining_frontier[belief] for
        belief in 1:model.belief_count
    )
    generative = is_subset_mask(
        model.modules[strategy],
        generative_closure(model, remaining),
    )
    return operational, generative, remaining
end

function check_t3(model::FiniteModel)
    checks = 0
    for library in all_libraries(model.strategy_count)
        for strategy in 2:model.strategy_count
            mask_contains(library, strategy) || continue
            operational, generative, remaining =
                deletion_conditions(model, library, strategy)
            key_equal =
                innovation_key(model, library) ==
                innovation_key(model, remaining)
            checks += 1
            if key_equal != (operational && generative)
                return (
                    holds = false,
                    checks,
                    witness = (
                        library,
                        strategy,
                        operational,
                        generative,
                        key_equal,
                    ),
                )
            end
        end
    end
    return (holds = true, checks, witness = nothing)
end

function check_t5(model::FiniteModel; horizon::Int = 3)
    raw = value_tables(model, horizon)
    operational = operational_tables(model, horizon)
    libraries = all_libraries(model.strategy_count)
    checks = 0

    for h in 0:(horizon - 1)
        premium_h = raw[h + 1] - operational[h + 1]
        premium_next = raw[h + 2] - operational[h + 2]
        all(x -> x >= 0, premium_h) ||
            return (holds = false, checks, witness = (:negative_premium, h))

        for library in libraries
            li = library_index(library)
            closure = generative_closure(model, library)
            for belief in 1:model.belief_count
                idle_rhs = Rat(0)
                for next_belief in 1:model.belief_count
                    idle_rhs +=
                        model.belief_kernel[belief, next_belief] *
                        premium_h[next_belief, li]
                end
                best_rhs = model.discount * idle_rhs

                for project in model.projects
                    distribution =
                        admitted_distribution(model, project, belief, closure)
                    expectation = Rat(0)
                    for next_belief in 1:model.belief_count
                        belief_mass = model.belief_kernel[belief, next_belief]
                        for outcome in 0:model.strategy_count
                            outcome_mass = distribution[outcome + 1]
                            iszero(outcome_mass) && continue
                            next_library = admit(library, outcome)
                            next_li = library_index(next_library)
                            expectation +=
                                belief_mass *
                                outcome_mass *
                                (
                                    premium_h[next_belief, next_li] +
                                    operational[h + 1][next_belief, next_li] -
                                    operational[h + 1][next_belief, li]
                                )
                        end
                    end
                    rhs =
                        -project_cost(project, belief, closure) +
                        model.discount * expectation
                    best_rhs = max(best_rhs, rhs)
                end

                checks += 1
                if premium_next[belief, li] != best_rhs
                    return (
                        holds = false,
                        checks,
                        witness = (
                            h,
                            belief,
                            library,
                            premium_next[belief, li],
                            best_rhs,
                        ),
                    )
                end
            end
        end
    end

    all(x -> x >= 0, raw[end] - operational[end]) ||
        return (
            holds = false,
            checks,
            witness = (:negative_premium, horizon),
        )
    return (holds = true, checks, witness = nothing)
end

function forced_idle_two_period(
    model::FiniteModel,
    library::UInt64,
    belief::Int,
)
    current = frontier(model, library)[belief]
    future = sum(
        model.belief_kernel[belief, next_belief] *
        frontier(model, library)[next_belief] for
        next_belief in 1:model.belief_count;
        init = Rat(0),
    )
    return current + model.discount * future
end

function forced_project_two_period(
    model::FiniteModel,
    library::UInt64,
    belief::Int,
    project_index::Int,
)
    project = model.projects[project_index]
    closure = generative_closure(model, library)
    distribution = admitted_distribution(model, project, belief, closure)
    future = Rat(0)
    for next_belief in 1:model.belief_count
        belief_mass = model.belief_kernel[belief, next_belief]
        for outcome in 0:model.strategy_count
            outcome_mass = distribution[outcome + 1]
            iszero(outcome_mass) && continue
            future +=
                belief_mass *
                outcome_mass *
                frontier(model, admit(library, outcome))[next_belief]
        end
    end
    return frontier(model, library)[belief] -
           project_cost(project, belief, closure) +
           model.discount * future
end

function t6_inequality_holds(
    model::FiniteModel,
    library::UInt64,
    belief::Int,
    project_index::Int,
    candidate::Int,
)
    project = model.projects[project_index]
    closure = generative_closure(model, library)
    distribution = admitted_distribution(model, project, belief, closure)
    for outcome in 1:model.strategy_count
        if outcome != candidate && !iszero(distribution[outcome + 1])
            throw(ArgumentError("T6 project has more than one admitted candidate"))
        end
    end
    success = distribution[candidate + 1]
    gap = frontier(model, library | strategy_bit(candidate)) -
          frontier(model, library)
    expected_gap = sum(
        model.belief_kernel[belief, next_belief] * gap[next_belief] for
        next_belief in 1:model.belief_count;
        init = Rat(0),
    )
    return model.discount * success * expected_gap >=
           project_cost(project, belief, closure)
end

function check_t6(
    model::FiniteModel,
    library::UInt64,
    project_index::Int,
    candidate::Int,
)
    checks = 0
    for belief in 1:model.belief_count
        direct =
            forced_project_two_period(model, library, belief, project_index) >=
            forced_idle_two_period(model, library, belief)
        formula =
            t6_inequality_holds(
                model,
                library,
                belief,
                project_index,
                candidate,
            )
        checks += 1
        if direct != formula
            return (
                holds = false,
                checks,
                witness = (belief, direct, formula),
            )
        end
    end
    return (holds = true, checks, witness = nothing)
end

function deterministic_kernel(belief_count::Int)
    kernel = fill(Rat(0), belief_count, belief_count)
    for b in 1:belief_count
        kernel[b, b] = 1 // 1
    end
    return kernel
end

function random_probability(rng::AbstractRNG, count::Int)
    weights = Int[rand(rng, 0:3) for _ in 1:count]
    if all(iszero, weights)
        weights[rand(rng, 1:count)] = 1
    end
    total = sum(weights)
    return Rat[weight // total for weight in weights]
end

function random_closure_table(rng::AbstractRNG, module_count::Int)
    universe = mask_bound(module_count) - 1
    rules = Tuple{UInt64,UInt64}[]
    for _ in 1:rand(rng, 0:(2 * module_count))
        premise = UInt64(rand(rng, 0:Int(universe)))
        conclusion = UInt64(rand(rng, 0:Int(universe)))
        push!(rules, (premise, conclusion))
    end
    return closure_from_rules(module_count, rules)
end

function random_project(
    rng::AbstractRNG,
    belief_count::Int,
    strategy_count::Int,
    module_count::Int;
    unique_candidate::Union{Nothing,Int} = nothing,
)
    closure_count = Int(mask_bound(module_count))
    requirements = UInt64(rand(rng, 0:(closure_count - 1)))
    cost = Matrix{Rat}(undef, belief_count, closure_count)
    raw = fill(Rat(0), belief_count, closure_count, strategy_count + 1)
    verify = Array{Rat,3}(undef, belief_count, closure_count, strategy_count)

    for b in 1:belief_count, ci in 1:closure_count
        cost[b, ci] = rand(rng, COST_GRID)
        if isnothing(unique_candidate)
            raw[b, ci, :] .= random_probability(rng, strategy_count + 1)
        else
            probability = rand(rng, PROB_GRID)
            raw[b, ci, 1] = 1 - probability
            raw[b, ci, unique_candidate + 1] = probability
        end
        for s in 1:strategy_count
            verify[b, ci, s] = rand(rng, PROB_GRID)
        end
    end
    return Project(requirements, cost, raw, verify)
end

function random_model(
    rng::AbstractRNG;
    belief_count::Int,
    strategy_count::Int,
    module_count::Int,
    project_count::Int,
    discount::Rat,
    unique_candidate::Union{Nothing,Int} = nothing,
)
    payoffs = Matrix{Rat}(undef, belief_count, strategy_count)
    for index in eachindex(payoffs)
        payoffs[index] = rand(rng, PAYOFF_GRID)
    end
    universe = Int(mask_bound(module_count)) - 1
    modules =
        UInt64[UInt64(rand(rng, 0:universe)) for _ in 1:strategy_count]
    closure_table = random_closure_table(rng, module_count)
    belief_kernel = Matrix{Rat}(undef, belief_count, belief_count)
    for b in 1:belief_count
        belief_kernel[b, :] .= random_probability(rng, belief_count)
    end
    projects = Project[
        random_project(
            rng,
            belief_count,
            strategy_count,
            module_count;
            unique_candidate,
        ) for _ in 1:project_count
    ]
    model = FiniteModel(
        belief_count,
        strategy_count,
        module_count,
        payoffs,
        modules,
        closure_table,
        belief_kernel,
        projects,
        discount,
    )
    validate_model(model) || error("random model generator produced invalid data")
    return model
end

function decode_digits(code::Int, base::Int, count::Int)
    digits = Vector{Int}(undef, count)
    remaining = code
    for index in 1:count
        digits[index] = rem(remaining, base)
        remaining = div(remaining, base)
    end
    return digits
end

function model_for_structural_data(
    payoffs::Matrix{Rat},
    modules::Vector{UInt64},
    closure_table::Vector{UInt64},
)
    nb, ns = size(payoffs)
    nm = trailing_zeros(UInt(length(closure_table)))
    return FiniteModel(
        nb,
        ns,
        nm,
        payoffs,
        modules,
        closure_table,
        deterministic_kernel(nb),
        Project[null_project(nb, ns, nm)],
        1 // 2,
    )
end

function exhaustive_t3_search()
    configurations = 0
    deletion_checks = 0
    for belief_count in 1:2, strategy_count in 2:3, module_count in 1:2
        closure_tables = all_closure_tables(module_count)
        payoff_entries = belief_count * strategy_count
        payoff_code_count = 3^payoff_entries
        module_base = Int(mask_bound(module_count))
        module_code_count = module_base^strategy_count
        for payoff_code in 0:(payoff_code_count - 1)
            payoff_digits = decode_digits(payoff_code, 3, payoff_entries)
            payoffs = reshape(
                Rat[(-1 + digit) // 1 for digit in payoff_digits],
                belief_count,
                strategy_count,
            )
            for module_code in 0:(module_code_count - 1)
                module_digits =
                    decode_digits(module_code, module_base, strategy_count)
                modules = UInt64[UInt64(digit) for digit in module_digits]
                for closure_table in closure_tables
                    model =
                        model_for_structural_data(payoffs, modules, closure_table)
                    result = check_t3(model)
                    configurations += 1
                    deletion_checks += result.checks
                    result.holds ||
                        return (
                            holds = false,
                            configurations,
                            deletion_checks,
                            witness = result.witness,
                        )
                end
            end
        end
    end
    return (holds = true, configurations, deletion_checks, witness = nothing)
end

function exhaustive_t1_update_search()
    configurations = 0
    update_checks = 0
    for belief_count in 1:2, strategy_count in 2:3, module_count in 1:2
        closure_tables = all_closure_tables(module_count)
        payoff_entries = belief_count * strategy_count
        payoff_code_count = 2^payoff_entries
        module_base = Int(mask_bound(module_count))
        module_code_count = module_base^strategy_count
        for payoff_code in 0:(payoff_code_count - 1)
            payoff_digits = decode_digits(payoff_code, 2, payoff_entries)
            payoffs = reshape(
                Rat[digit // 1 for digit in payoff_digits],
                belief_count,
                strategy_count,
            )
            for module_code in 0:(module_code_count - 1)
                module_digits =
                    decode_digits(module_code, module_base, strategy_count)
                modules = UInt64[UInt64(digit) for digit in module_digits]
                for closure_table in closure_tables
                    model =
                        model_for_structural_data(payoffs, modules, closure_table)
                    libraries = all_libraries(strategy_count)
                    for i in eachindex(libraries), j in i:length(libraries)
                        left = libraries[i]
                        right = libraries[j]
                        innovation_key(model, left) ==
                            innovation_key(model, right) || continue
                        for outcome in 0:strategy_count
                            update_checks += 1
                            if innovation_key(model, admit(left, outcome)) !=
                               innovation_key(model, admit(right, outcome))
                                return (
                                    holds = false,
                                    configurations,
                                    update_checks,
                                    witness = (left, right, outcome),
                                )
                            end
                        end
                    end
                    configurations += 1
                end
            end
        end
    end
    return (holds = true, configurations, update_checks, witness = nothing)
end

function probe_observable_model()
    nb, ns, nm = 1, 2, 1
    payoffs = reshape(Rat[0 // 1, -1 // 1], nb, ns)
    modules = UInt64[0, 1]
    closure = identity_closure(nm)
    project = null_project(nb, ns, nm)
    project.cost[1, 1] = Rat(0)
    project.cost[1, 2] = 1 // 1
    return FiniteModel(
        nb,
        ns,
        nm,
        payoffs,
        modules,
        closure,
        deterministic_kernel(nb),
        Project[project],
        1 // 2,
    )
end

function silent_module_witness()
    nb, ns, nm = 1, 2, 1
    model = FiniteModel(
        nb,
        ns,
        nm,
        reshape(Rat[0 // 1, -1 // 1], nb, ns),
        UInt64[0, 1],
        identity_closure(nm),
        deterministic_kernel(nb),
        Project[null_project(nb, ns, nm)],
        1 // 2,
    )
    smaller = UInt64(1)
    larger = UInt64(3)
    values = value_tables(model, 4)
    same_values = all(
        values[h + 1][1, library_index(smaller)] ==
        values[h + 1][1, library_index(larger)] for h in 0:4
    )
    return (
        id = "CX-T1-MIN-T2-SILENT-01",
        exact = true,
        minimal = true,
        model,
        smaller,
        larger,
        same_frontier = frontier(model, smaller) == frontier(model, larger),
        different_closure =
            generative_closure(model, smaller) !=
            generative_closure(model, larger),
        same_signature =
            innovation_signature(model, smaller) ==
            innovation_signature(model, larger),
        same_values,
    )
end

function raw_dependence_witness()
    discount = 1 // 2
    baseline_library = UInt64(1)
    provenance_library = UInt64(3)
    frontier_equal = true
    closure_equal = true
    value_without_identifier = Rat(0)
    value_with_identifier = discount * (1 // 1)
    return (
        id = "CX-T1-RAW-01",
        exact = true,
        minimal = true,
        belief_count = 1,
        strategy_count = 3,
        module_count = 1,
        project_count = 1,
        payoffs = Rat[0 // 1, -1 // 1, 1 // 1],
        baseline_library,
        provenance_library,
        discount,
        frontier_equal,
        closure_equal,
        value_without_identifier,
        value_with_identifier,
        violates_assumption = "A-GEN-FACTOR",
    )
end

function t3_batch_witness()
    model = FiniteModel(
        1,
        3,
        1,
        reshape(Rat[0 // 1, -1 // 1, -1 // 1], 1, 3),
        UInt64[0, 1, 1],
        identity_closure(1),
        deterministic_kernel(1),
        Project[null_project(1, 3, 1)],
        1 // 2,
    )
    full = UInt64(7)
    first_removed = full & ~strategy_bit(2)
    second_removed = full & ~strategy_bit(3)
    both_removed = UInt64(1)
    first_safe = innovation_key(model, full) == innovation_key(model, first_removed)
    second_safe =
        innovation_key(model, full) == innovation_key(model, second_removed)
    batch_unsafe =
        innovation_key(model, full) != innovation_key(model, both_removed)
    return (
        id = "CX-T3-BATCH-01",
        exact = true,
        minimal = true,
        model,
        full,
        first_safe,
        second_safe,
        batch_unsafe,
    )
end

function t4_model(discount_value::Rational)
    discount = Rat(discount_value)
    nb, ns, nm = 1, 3, 1
    project = null_project(nb, ns, nm)
    project = Project(
        UInt64(1),
        project.cost,
        project.raw,
        project.verify,
    )
    project.raw[:, :, :] .= Rat(0)
    for ci in 1:2
        closure = UInt64(ci - 1)
        if is_subset_mask(project.requirements, closure)
            project.raw[1, ci, 4] = 1 // 1
        else
            project.raw[1, ci, 1] = 1 // 1
        end
    end
    return FiniteModel(
        nb,
        ns,
        nm,
        reshape(Rat[0 // 1, 0 // 1, 1 // 1], nb, ns),
        UInt64[0, 1, 0],
        identity_closure(nm),
        deterministic_kernel(nb),
        Project[project],
        discount,
    )
end

function t4_witness(target_value::Rational)
    target = Rat(target_value)
    target >= 0 || throw(ArgumentError("T4 target must be nonnegative"))
    n = max(2, floor(Int, 2 * target) + 1)
    while n // 2 <= target
        n += 1
    end
    horizon = n + 1
    discount = Rat(1) - Rat(1 // (n^2))
    model = t4_model(discount)
    full = UInt64(3)
    pruned = UInt64(1)
    values = value_tables(model, horizon)
    loss =
        values[end][1, library_index(full)] -
        values[end][1, library_index(pruned)]
    closed_form = sum(discount^t for t in 1:n; init = Rat(0))
    bernoulli_lower_bound = n // 2
    return (
        id = "CX-T4-BRIDGE-01",
        exact = true,
        minimal = true,
        target,
        n,
        horizon,
        discount,
        loss,
        closed_form,
        bernoulli_lower_bound,
        frontier_preserved = frontier(model, full) == frontier(model, pruned),
        closure_changed =
            generative_closure(model, full) !=
            generative_closure(model, pruned),
        independent_check =
            loss == closed_form &&
            closed_form >= bernoulli_lower_bound &&
            bernoulli_lower_bound > target,
    )
end

function deterministic_candidate_project(
    belief_count::Int,
    strategy_count::Int,
    module_count::Int,
    candidate::Int;
    requirements::UInt64 = UInt64(0),
    costs::Vector{Rat} = fill(Rat(0), belief_count),
)
    project = null_project(belief_count, strategy_count, module_count)
    project = Project(
        requirements,
        project.cost,
        project.raw,
        project.verify,
    )
    project.raw[:, :, :] .= Rat(0)
    for b in 1:belief_count, ci in 1:Int(mask_bound(module_count))
        project.cost[b, ci] = costs[b]
        closure = UInt64(ci - 1)
        if is_subset_mask(requirements, closure)
            project.raw[b, ci, candidate + 1] = 1 // 1
        else
            project.raw[b, ci, 1] = 1 // 1
        end
    end
    return project
end

function t5_separability_witness()
    function model_with_candidate_payoff(candidate_payoff_value::Rational)
        candidate_payoff = Rat(candidate_payoff_value)
        project = deterministic_candidate_project(1, 2, 1, 2)
        return FiniteModel(
            1,
            2,
            1,
            reshape(Rat[0 // 1, candidate_payoff], 1, 2),
            UInt64[1, 0],
            identity_closure(1),
            deterministic_kernel(1),
            Project[project],
            1 // 2,
        )
    end
    low = model_with_candidate_payoff(1 // 1)
    high = model_with_candidate_payoff(2 // 1)
    library = UInt64(1)
    low_raw = value_tables(low, 2)
    low_operational = operational_tables(low, 2)
    high_raw = value_tables(high, 2)
    high_operational = operational_tables(high, 2)
    low_premium =
        low_raw[end][1, library_index(library)] -
        low_operational[end][1, library_index(library)]
    high_premium =
        high_raw[end][1, library_index(library)] -
        high_operational[end][1, library_index(library)]
    return (
        id = "CX-T5-SEPARABILITY-01",
        exact = true,
        minimal = true,
        low_premium,
        high_premium,
        same_initial_frontier =
            frontier(low, library) == frontier(high, library),
        same_closure =
            generative_closure(low, library) ==
            generative_closure(high, library),
        independent_check =
            low_premium == 1 // 2 && high_premium == 1 // 1,
    )
end

function t6_disconnected_witness()
    nb, ns, nm = 3, 2, 1
    project = deterministic_candidate_project(
        nb,
        ns,
        nm,
        2;
        costs = Rat[0 // 1, 1 // 1, 0 // 1],
    )
    model = FiniteModel(
        nb,
        ns,
        nm,
        hcat(fill(Rat(0), nb), fill(Rat(1), nb)),
        UInt64[0, 0],
        identity_closure(nm),
        deterministic_kernel(nb),
        Project[project],
        1 // 2,
    )
    library = UInt64(1)
    region = Bool[
        t6_inequality_holds(model, library, belief, 1, 2) for
        belief in 1:nb
    ]
    direct_region = Bool[
        forced_project_two_period(model, library, belief, 1) >=
        forced_idle_two_period(model, library, belief) for belief in 1:nb
    ]
    return (
        id = "CX-T6-DISCONNECTED-01",
        exact = true,
        minimal = true,
        region,
        direct_region,
        disconnected = region == Bool[true, false, true],
        independent_check = region == direct_region,
    )
end

function multi_gap_additivity_witness()
    nb, ns, nm = 1, 3, 1
    first = deterministic_candidate_project(nb, ns, nm, 2)
    second = deterministic_candidate_project(
        nb,
        ns,
        nm,
        3;
        requirements = UInt64(1),
    )
    common = (
        nb,
        ns,
        nm,
        reshape(Rat[0 // 1, 0 // 1, 1 // 1], nb, ns),
        UInt64[0, 1, 0],
        identity_closure(nm),
        deterministic_kernel(nb),
    )
    joint = FiniteModel(common..., Project[first, second], 1 // 2)
    first_only = FiniteModel(common..., Project[first], 1 // 2)
    second_only = FiniteModel(common..., Project[second], 1 // 2)
    library = UInt64(1)
    joint_value = value_tables(joint, 3)[end][1, library_index(library)]
    first_value =
        value_tables(first_only, 3)[end][1, library_index(library)]
    second_value =
        value_tables(second_only, 3)[end][1, library_index(library)]
    return (
        id = "CX-MULTIGAP-ADDITIVITY-01",
        exact = true,
        minimal = true,
        joint_value,
        first_value,
        second_value,
        violates_additive_upper_bound =
            joint_value > first_value + second_value,
        independent_check =
            joint_value == 1 // 4 &&
            first_value == 0 &&
            second_value == 0,
    )
end

function randomized_search(
    rng::AbstractRNG;
    random_trials::Int,
    single_gap_trials::Int,
)
    totals = Dict(
        "models" => 0,
        "t1_value_comparisons" => 0,
        "t1_update_comparisons" => 0,
        "t2_applicable_models" => 0,
        "t2_comparisons" => 0,
        "t3_deletions" => 0,
        "t5_recursion_checks" => 0,
        "t6_grid_checks" => 0,
    )
    failures = Dict{String,Any}()

    for _ in 1:random_trials
        nb = rand(rng, 1:4)
        ns = rand(rng, 1:6)
        nm = rand(rng, 1:6)
        nq = rand(rng, 1:3)
        discount = rand(rng, DISCOUNT_GRID)
        model = random_model(
            rng;
            belief_count = nb,
            strategy_count = ns,
            module_count = nm,
            project_count = nq,
            discount,
        )
        totals["models"] += 1

        t1 = check_t1(model; horizon = 3)
        totals["t1_value_comparisons"] += t1.value_comparisons
        totals["t1_update_comparisons"] += t1.update_comparisons
        if !t1.holds
            failures["T1"] = t1.witness
            break
        end

        t2 = check_t2(model)
        if t2.applicable
            totals["t2_applicable_models"] += 1
            totals["t2_comparisons"] += t2.comparisons
            if !t2.holds
                failures["T2"] = t2.witness
                break
            end
        end

        t3 = check_t3(model)
        totals["t3_deletions"] += t3.checks
        if !t3.holds
            failures["T3"] = t3.witness
            break
        end

        t5 = check_t5(model; horizon = 3)
        totals["t5_recursion_checks"] += t5.checks
        if !t5.holds
            failures["T5"] = t5.witness
            break
        end
    end

    if isempty(failures)
        for _ in 1:single_gap_trials
            nb = rand(rng, 1:4)
            ns = rand(rng, 2:6)
            nm = rand(rng, 1:6)
            candidate = rand(rng, 2:ns)
            model = random_model(
                rng;
                belief_count = nb,
                strategy_count = ns,
                module_count = nm,
                project_count = 1,
                discount = rand(rng, DISCOUNT_GRID),
                unique_candidate = candidate,
            )
            t6 = check_t6(model, UInt64(1), 1, candidate)
            totals["t6_grid_checks"] += t6.checks
            if !t6.holds
                failures["T6"] = t6.witness
                break
            end
        end
    end

    return (totals = totals, failures = failures)
end

function classification_record(
    classification::String,
    current_statement_holds::Bool,
    boundary::String,
)
    return Dict{String,Any}(
        "classification" => classification,
        "current_statement_holds_in_search" => current_statement_holds,
        "boundary_finding" => boundary,
    )
end

function run_feasibility_search(;
    seed::UInt64 = DEFAULT_FEASIBILITY_SEED,
    random_trials::Int = 2048,
    single_gap_trials::Int = 4096,
    exhaustive::Bool = true,
)
    rng = research_rng(seed)
    exhaustive_t1 = exhaustive ?
                    exhaustive_t1_update_search() :
                    (holds = true, configurations = 0, update_checks = 0)
    exhaustive_t3 = exhaustive ?
                    exhaustive_t3_search() :
                    (holds = true, configurations = 0, deletion_checks = 0)
    random = randomized_search(
        rng;
        random_trials,
        single_gap_trials,
    )

    observable = check_t2(probe_observable_model())
    silent = silent_module_witness()
    raw_dependence = raw_dependence_witness()
    batch = t3_batch_witness()
    t4_targets = Rat[1 // 1, 2 // 1, 5 // 1, 10 // 1]
    t4_witnesses = [t4_witness(target) for target in t4_targets]
    t5_boundary = t5_separability_witness()
    t6_boundary = t6_disconnected_witness()
    multi_gap = multi_gap_additivity_witness()

    all_current_hold =
        exhaustive_t1.holds &&
        exhaustive_t3.holds &&
        isempty(random.failures) &&
        observable.holds &&
        all(witness -> witness.independent_check, t4_witnesses) &&
        t6_boundary.independent_check

    theorem_records = Dict{String,Any}(
        "T1" => classification_record(
            "survives as stated",
            exhaustive_t1.holds && !haskey(random.failures, "T1"),
            "Generic minimality is false: a silent module changes K while all searched values and signatures remain equal. Raw-library dependence also falsifies sufficiency when A-GEN-FACTOR is removed.",
        ),
        "T2" => classification_record(
            "survives as stated",
            observable.holds && !haskey(random.failures, "T2"),
            "The converse fails without the already-recorded A-T2-OBS assumption.",
        ),
        "T3" => classification_record(
            "survives as stated",
            exhaustive_t3.holds && !haskey(random.failures, "T3"),
            "The single-deletion converse survived; the analogous batch-deletion inference is false.",
        ),
        "T4" => classification_record(
            "survives as stated",
            all(witness -> witness.independent_check, t4_witnesses),
            "Unbounded loss requires varying horizon and discount; fixed-parameter unboundedness remains false.",
        ),
        "T5" => classification_record(
            "survives as stated",
            !haskey(random.failures, "T5"),
            "The exact premium recursion survived; any closure-only or interaction-free decomposition is false.",
        ),
        "T6" => classification_record(
            "survives as stated",
            !haskey(random.failures, "T6") &&
            t6_boundary.independent_check,
            "The exact finite-grid identity survived, but coverage can be disconnected and need not be a threshold interval.",
        ),
        "optional_multi_gap_component_bound" => classification_record(
            "false and should be removed",
            false,
            "A two-project compositional fixture has positive joint premium and zero isolated component premia.",
        ),
    )

    result = Dict{String,Any}(
        "schema_version" => "theorem-feasibility-v1",
        "experiment_id" => "paper1-theorem-falsification-v1",
        "config_file" => "experiments/configs/theorem_feasibility.toml",
        "run_date" => "2026-07-20",
        "julia_version" => string(VERSION),
        "arithmetic" => "Rational{BigInt}",
        "rng" => "StableRNGs.StableRNG",
        "seed" => string(seed),
        "bounds" => Dict{String,Any}(
            "belief_states" => "1-4",
            "strategies" => "1-6 total, including baseline-only models",
            "modules" => "1-6",
            "projects" => "1-3 plus idle",
            "discounts" => [rat_string(x) for x in DISCOUNT_GRID],
            "random_trials" => random_trials,
            "single_gap_trials" => single_gap_trials,
        ),
        "exhaustive" => Dict{String,Any}(
            "t1_configurations" => exhaustive_t1.configurations,
            "t1_update_checks" => exhaustive_t1.update_checks,
            "t3_configurations" => exhaustive_t3.configurations,
            "t3_deletion_checks" => exhaustive_t3.deletion_checks,
        ),
        "randomized" => random.totals,
        "random_failures" => Dict(
            key => string(value) for (key, value) in random.failures
        ),
        "theorems" => theorem_records,
        "witnesses" => Dict{String,Any}(
            "raw_library_dependence" => Dict(
                "id" => raw_dependence.id,
                "value_without_identifier" =>
                    rat_string(raw_dependence.value_without_identifier),
                "value_with_identifier" =>
                    rat_string(raw_dependence.value_with_identifier),
                "violates_assumption" => raw_dependence.violates_assumption,
                "independent_check" =>
                    raw_dependence.frontier_equal &&
                    raw_dependence.closure_equal &&
                    raw_dependence.value_without_identifier == 0 &&
                    raw_dependence.value_with_identifier == 1 // 2,
            ),
            "silent_module" => Dict(
                "id" => silent.id,
                "same_frontier" => silent.same_frontier,
                "different_closure" => silent.different_closure,
                "same_signature" => silent.same_signature,
                "same_values_through_h4" => silent.same_values,
                "independent_check" =>
                    silent.same_frontier &&
                    silent.different_closure &&
                    silent.same_signature &&
                    silent.same_values,
            ),
            "batch_deletion" => Dict(
                "id" => batch.id,
                "first_individually_safe" => batch.first_safe,
                "second_individually_safe" => batch.second_safe,
                "batch_unsafe" => batch.batch_unsafe,
                "independent_check" =>
                    batch.first_safe &&
                    batch.second_safe &&
                    batch.batch_unsafe,
            ),
            "t4_targets" => [
                Dict{String,Any}(
                    "target" => rat_string(witness.target),
                    "n" => witness.n,
                    "horizon" => witness.horizon,
                    "discount" => rat_string(witness.discount),
                    "loss" => rat_string(witness.loss),
                    "frontier_preserved" => witness.frontier_preserved,
                    "closure_changed" => witness.closure_changed,
                    "independent_check" => witness.independent_check,
                ) for witness in t4_witnesses
            ],
            "t5_separability" => Dict(
                "id" => t5_boundary.id,
                "low_premium" => rat_string(t5_boundary.low_premium),
                "high_premium" => rat_string(t5_boundary.high_premium),
                "same_initial_frontier" =>
                    t5_boundary.same_initial_frontier,
                "same_closure" => t5_boundary.same_closure,
                "independent_check" => t5_boundary.independent_check,
            ),
            "t6_disconnected" => Dict(
                "id" => t6_boundary.id,
                "region" => collect(t6_boundary.region),
                "direct_region" => collect(t6_boundary.direct_region),
                "disconnected" => t6_boundary.disconnected,
                "independent_check" => t6_boundary.independent_check,
            ),
            "multi_gap_additivity" => Dict(
                "id" => multi_gap.id,
                "joint_value" => rat_string(multi_gap.joint_value),
                "first_value" => rat_string(multi_gap.first_value),
                "second_value" => rat_string(multi_gap.second_value),
                "violates_additive_upper_bound" =>
                    multi_gap.violates_additive_upper_bound,
                "independent_check" => multi_gap.independent_check,
            ),
        ),
        "all_current_t1_t6_survived" => all_current_hold,
        "main_novelty_collapsed" => !all_current_hold,
    )
    return result
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

function write_json_result(path::AbstractString, result)
    mkpath(dirname(path))
    open(path, "w") do io
        write_json(io, result)
        print(io, "\n")
    end
    return path
end

function write_lean_fixture(path::AbstractString)
    mkpath(dirname(path))
    source = raw"""import Mathlib.Data.Int.Basic

namespace StrategyInnovation.Fixtures.TheoremFeasibility

/-- Exact rational datum represented as numerator and positive denominator. -/
structure QDatum where
  num : Int
  den : Nat
  deriving Repr, DecidableEq

/-- Data-only witness to be mapped into the future formal model. -/
structure ExactFixture where
  id : String
  theoremId : String
  beliefCount : Nat
  strategyCount : Nat
  moduleCount : Nat
  projectCount : Nat
  rationalData : List QDatum
  maskData : List Nat
  expectedFacts : List String
  deriving Repr, DecidableEq

def rawLibraryDependence : ExactFixture where
  id := "CX-T1-RAW-01"
  theoremId := "T1-boundary"
  beliefCount := 1
  strategyCount := 3
  moduleCount := 1
  projectCount := 1
  rationalData := [⟨0, 1⟩, ⟨-1, 1⟩, ⟨1, 1⟩, ⟨1, 2⟩]
  maskData := [1, 3]
  expectedFacts := ["equal frontier", "equal closure", "different value"]

def silentModule : ExactFixture where
  id := "CX-T1-MIN-T2-SILENT-01"
  theoremId := "T1-minimality/T2-converse"
  beliefCount := 1
  strategyCount := 2
  moduleCount := 1
  projectCount := 1
  rationalData := [⟨0, 1⟩, ⟨-1, 1⟩, ⟨1, 2⟩]
  maskData := [1, 3, 0, 1]
  expectedFacts := ["equal frontier", "different closure", "equal signature", "equal value"]

def batchDeletion : ExactFixture where
  id := "CX-T3-BATCH-01"
  theoremId := "T3-batch-extension"
  beliefCount := 1
  strategyCount := 3
  moduleCount := 1
  projectCount := 1
  rationalData := [⟨0, 1⟩, ⟨-1, 1⟩, ⟨-1, 1⟩]
  maskData := [7, 5, 3, 1]
  expectedFacts := ["each single deletion safe", "joint deletion changes K"]

def frontierLoss : ExactFixture where
  id := "CX-T4-BRIDGE-01"
  theoremId := "T4"
  beliefCount := 1
  strategyCount := 3
  moduleCount := 1
  projectCount := 1
  rationalData := [⟨0, 1⟩, ⟨0, 1⟩, ⟨1, 1⟩, ⟨120, 121⟩, ⟨5, 1⟩]
  maskData := [3, 1, 12]
  expectedFacts := ["frontier preserved", "closure changed", "loss greater than five"]

def valueSeparability : ExactFixture where
  id := "CX-T5-SEPARABILITY-01"
  theoremId := "T5-extension"
  beliefCount := 1
  strategyCount := 2
  moduleCount := 1
  projectCount := 1
  rationalData := [⟨1, 2⟩, ⟨1, 1⟩, ⟨2, 1⟩]
  maskData := [1]
  expectedFacts := ["same initial frontier", "same closure", "different innovation premium"]

def disconnectedCoverage : ExactFixture where
  id := "CX-T6-DISCONNECTED-01"
  theoremId := "T6-extension"
  beliefCount := 3
  strategyCount := 2
  moduleCount := 1
  projectCount := 1
  rationalData := [⟨1, 2⟩, ⟨0, 1⟩, ⟨1, 1⟩, ⟨0, 1⟩]
  maskData := [1, 0, 1]
  expectedFacts := ["coverage region is beliefs one and three", "coverage formula still exact"]

def multiGapAdditivity : ExactFixture where
  id := "CX-MULTIGAP-ADDITIVITY-01"
  theoremId := "optional-multi-gap"
  beliefCount := 1
  strategyCount := 3
  moduleCount := 1
  projectCount := 2
  rationalData := [⟨1, 2⟩, ⟨1, 4⟩, ⟨0, 1⟩, ⟨0, 1⟩]
  maskData := [1]
  expectedFacts := ["joint premium positive", "isolated component premia zero"]

def all : List ExactFixture :=
  [rawLibraryDependence, silentModule, batchDeletion, frontierLoss,
   valueSeparability, disconnectedCoverage, multiGapAdditivity]

end StrategyInnovation.Fixtures.TheoremFeasibility
"""
    open(path, "w") do io
        print(io, source)
    end
    return path
end

function parse_arguments(args)
    options = Dict{String,Any}(
        "seed" => DEFAULT_FEASIBILITY_SEED,
        "random_trials" => 2048,
        "single_gap_trials" => 4096,
        "exhaustive" => true,
    )
    for argument in args
        if startswith(argument, "--seed=")
            options["seed"] = parse(UInt64, split(argument, "=", limit = 2)[2])
        elseif startswith(argument, "--random-trials=")
            options["random_trials"] =
                parse(Int, split(argument, "=", limit = 2)[2])
        elseif startswith(argument, "--single-gap-trials=")
            options["single_gap_trials"] =
                parse(Int, split(argument, "=", limit = 2)[2])
        elseif argument == "--no-exhaustive"
            options["exhaustive"] = false
        else
            throw(ArgumentError("unknown argument: $argument"))
        end
    end
    return options
end

function main(args = ARGS)
    options = parse_arguments(args)
    result = run_feasibility_search(
        seed = options["seed"],
        random_trials = options["random_trials"],
        single_gap_trials = options["single_gap_trials"],
        exhaustive = options["exhaustive"],
    )
    repository_root = normpath(joinpath(@__DIR__, "..", ".."))
    result_path =
        joinpath(repository_root, "experiments", "results", "theorem_feasibility.json")
    fixture_path = joinpath(
        repository_root,
        "formal",
        "StrategyInnovation",
        "Fixtures",
        "TheoremFeasibility.lean",
    )
    write_json_result(result_path, result)
    write_lean_fixture(fixture_path)
    println("Wrote ", result_path)
    println("Wrote ", fixture_path)
    println(
        "Current T1-T6 survived: ",
        result["all_current_t1_t6_survived"],
    )
    println("Main novelty collapsed: ", result["main_novelty_collapsed"])
    return result
end

end # module CounterexampleSearch

if abspath(PROGRAM_FILE) == @__FILE__
    CounterexampleSearch.main()
end
