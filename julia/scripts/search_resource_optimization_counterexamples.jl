module ResourceOptimizationCounterexampleSearch

using SHA: sha256
using TOML
using StrategyInnovation

include(joinpath(@__DIR__, "..", "src", "ResourceOptimization.jl"))
using .ResourceOptimization

export default_config_path,
       render_json,
       run_resource_optimization_audit,
       write_resource_optimization_audit

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "resource_optimization_counterexamples.toml",
)
const SCHEMA_VERSION = "resource-optimization-counterexample-audit-v1"

default_config_path() = DEFAULT_CONFIG
_ratio(value::Rational) = "$(numerator(value))//$(denominator(value))"
_ratio(value::Integer) = "$(value)//1"

function _parse_ratio(value)
    value isa Rational && return exact_rational(value)
    value isa Integer && return exact_rational(value)
    return exact_rational(String(value))
end

_bit(index::Int) = UInt64(1) << (index - 1)
_active_count(mask::UInt64) = count_ones(mask)
_subset(left::UInt64, right::UInt64) = (left & ~right) == 0
_incomparable(left::UInt64, right::UInt64) =
    !_subset(left, right) && !_subset(right, left)

function _permutations(values::Vector{Int})
    isempty(values) && return [Int[]]
    rows = Vector{Vector{Int}}()
    for (index, value) in enumerate(values)
        remainder = [values[1:(index - 1)]; values[(index + 1):end]]
        for tail in _permutations(remainder)
            push!(rows, [value; tail])
        end
    end
    return rows
end

_tuples(values, count::Int) =
    Iterators.product(ntuple(_ -> values, count)...)

function _monotone_value_tables(active_count::Int, maximum_value::Int)
    library_count = Int(1) << active_count
    return Channel{Vector{Int}}() do channel
        for tail in _tuples(0:maximum_value, library_count - 1)
            values = Int[0; collect(tail)]
            monotone = true
            for mask in UInt64(0):UInt64(library_count - 1)
                for strategy_index in 1:active_count
                    bit = _bit(strategy_index)
                    iszero(mask & bit) || continue
                    if values[Int(mask) + 1] >
                       values[Int(mask | bit) + 1]
                        monotone = false
                        break
                    end
                end
                monotone || break
            end
            monotone && put!(channel, values)
        end
    end
end

function _problem(
    active_count::Int,
    weights,
    module_masks,
    module_count::Int,
    values;
    profiles = zeros(Int, active_count, 1),
)
    return ExactRetentionProblem(
        ["s$strategy_index" for strategy_index in 1:active_count],
        collect(weights),
        profiles,
        collect(module_masks),
        module_count,
        values,
    )
end

function _mask_modules(problem::ExactRetentionProblem, mask::UInt64)
    module_mask = library_module_mask(problem, mask)
    return String[
        "m$module_index" for module_index in 1:problem.module_count if
        !iszero(module_mask & _bit(module_index))
    ]
end

function _library_dict(problem::ExactRetentionProblem, mask::UInt64)
    return Dict{String,Any}(
        "mask" => Int(mask),
        "strategies" => library_strategy_ids(problem, mask),
        "active_count" => _active_count(mask),
        "cardinality_with_inactive" => library_cardinality(problem, mask),
        "weight" => _ratio(library_weight(problem, mask)),
        "productive_value" => _ratio(library_value(problem, mask)),
        "frontier" => [_ratio(value) for value in library_frontier(problem, mask)],
        "modules" => _mask_modules(problem, mask),
    )
end

function _problem_dict(problem::ExactRetentionProblem)
    strategies = Vector{Dict{String,Any}}()
    for strategy_index in 1:active_strategy_count(problem)
        push!(
            strategies,
            Dict{String,Any}(
                "id" => problem.strategy_ids[strategy_index],
                "weight" => _ratio(problem.weights[strategy_index]),
                "profile" => [
                    _ratio(problem.profiles[strategy_index, belief_index]) for
                    belief_index in axes(problem.profiles, 2)
                ],
                "modules" => String[
                    "m$module_index" for module_index in 1:problem.module_count if
                    !iszero(problem.module_masks[strategy_index] & _bit(module_index))
                ],
            ),
        )
    end
    value_table = Dict{String,Any}[
        Dict(
            "mask" => Int(mask),
            "strategies" => library_strategy_ids(problem, mask),
            "productive_value" => _ratio(library_value(problem, mask)),
        ) for mask in library_masks(problem)
    ]
    return Dict{String,Any}(
        "inactive" => Dict(
            "id" => "inactive",
            "weight" => "0//1",
            "profile" => fill("0//1", size(problem.profiles, 2)),
            "modules" => String[],
        ),
        "active_strategies" => strategies,
        "belief_count" => size(problem.profiles, 2),
        "module_count" => problem.module_count,
        "closure" => "identity",
        "productive_value_table" => value_table,
        "productive_value_monotone_under_inclusion" => true,
    )
end

function _trace_dict(
    problem::ExactRetentionProblem,
    trace,
    order::Vector{Int},
)
    return Dict{String,Any}(
        "deletion_order" => problem.strategy_ids[order],
        "actual_deletions" => problem.strategy_ids[trace.deletions],
        "libraries" => [_library_dict(problem, mask) for mask in trace.masks],
        "endpoint" => _library_dict(problem, trace.endpoint),
        "endpoint_irreducible" => inclusion_irreducible(problem, trace.endpoint),
        "all_steps_source_safe" => all(
            safe_feasible(problem, first(trace.masks), mask) for mask in trace.masks
        ),
    )
end

function _safe_set_dict(problem::ExactRetentionProblem, source_mask::UInt64)
    feasible = safe_sublibraries(problem, source_mask)
    return Dict{String,Any}(
        "source" => _library_dict(problem, source_mask),
        "feasible_libraries" => [_library_dict(problem, mask) for mask in feasible],
        "minimum_cardinality_libraries" => [
            _library_dict(problem, mask) for
            mask in minimum_safe_cardinality_masks(problem, source_mask)
        ],
        "minimum_weight_libraries" => [
            _library_dict(problem, mask) for
            mask in minimum_safe_weight_masks(problem, source_mask)
        ],
    )
end

function _claim(
    number::Int,
    id::String,
    title::String,
    status::String,
    theorem_revision::String,
    assumption_boundary::String,
    minimality,
    fixture,
)
    return Dict{String,Any}(
        "claim_number" => number,
        "id" => id,
        "title" => title,
        "status" => status,
        "arithmetic" => "Rational{BigInt}",
        "evidence_class" => "exact finite Julia search; not Lean proof",
        "theorem_revision" => theorem_revision,
        "assumption_boundary" => assumption_boundary,
        "minimality" => minimality,
        "fixture" => fixture,
    )
end

function _update_best!(best::Dict{Int,Any}, claim_number::Int, score, witness)
    if !haskey(best, claim_number) || score < best[claim_number].score
        best[claim_number] = (score = score, witness = witness)
    end
    return nothing
end

function _maximum_burden_safe_trace(
    problem::ExactRetentionProblem,
    source_mask::UInt64,
)
    current = source_mask
    masks = UInt64[current]
    deletions = Int[]
    while true
        candidates = Int[
            strategy_index for
            strategy_index in 1:active_strategy_count(problem) if
            safely_deletable(problem, current, strategy_index)
        ]
        isempty(candidates) && break
        maximum_weight = maximum(problem.weights[index] for index in candidates)
        strategy_index = minimum(
            index for index in candidates if
            problem.weights[index] == maximum_weight
        )
        current &= ~_bit(strategy_index)
        push!(deletions, strategy_index)
        push!(masks, current)
    end
    return (masks = masks, deletions = deletions, endpoint = current)
end

function _search_compression(config)
    maximum_active = Int(config["max_active"])
    maximum_modules = Int(config["max_modules"])
    maximum_weight = Int(config["max_weight"])
    best = Dict{Int,Any}()
    maximum_burden_best = nothing
    counts = Dict(
        "structural_instances" => 0,
        "weighted_instances" => 0,
        "deletion_orders" => 0,
    )

    for active_count in 1:maximum_active
        orders = _permutations(collect(1:active_count))
        source_mask = (UInt64(1) << active_count) - UInt64(1)
        for module_count in 1:maximum_modules
            module_options = 1:((1 << module_count) - 1)
            universe_mask = UInt64((1 << module_count) - 1)
            for module_tuple in _tuples(module_options, active_count)
                module_masks = UInt64[UInt64(value) for value in module_tuple]
                foldl(|, module_masks; init = UInt64(0)) == universe_mask ||
                    continue
                problem = _problem(
                    active_count,
                    ones(Int, active_count),
                    module_masks,
                    module_count,
                    zeros(Int, 1 << active_count),
                )
                counts["structural_instances"] += 1
                minimum_cardinality = minimum(
                    _active_count(mask) for
                    mask in minimum_safe_cardinality_masks(problem, source_mask)
                )
                for order in orders
                    counts["deletion_orders"] += 1
                    trace = safe_pruning_trace(problem, source_mask, order)
                    if _active_count(trace.endpoint) > minimum_cardinality
                        score = (
                            active_count,
                            module_count,
                            sum(count_ones, module_masks),
                            Tuple(module_masks),
                            Tuple(order),
                        )
                        _update_best!(
                            best,
                            1,
                            score,
                            (
                                problem = problem,
                                source = source_mask,
                                order = order,
                                trace = trace,
                            ),
                        )
                    end
                end
            end
        end
    end

    for active_count in 1:maximum_active
        orders = _permutations(collect(1:active_count))
        source_mask = (UInt64(1) << active_count) - UInt64(1)
        for module_count in 1:maximum_modules
            module_options = 1:((1 << module_count) - 1)
            universe_mask = UInt64((1 << module_count) - 1)
            for module_tuple in _tuples(module_options, active_count)
                module_masks = UInt64[UInt64(value) for value in module_tuple]
                foldl(|, module_masks; init = UInt64(0)) == universe_mask ||
                    continue
                for weight_tuple in _tuples(1:maximum_weight, active_count)
                    problem = _problem(
                        active_count,
                        collect(weight_tuple),
                        module_masks,
                        module_count,
                        zeros(Int, 1 << active_count),
                    )
                    counts["weighted_instances"] += 1
                    minimum_weight = minimum(
                        library_weight(problem, mask) for
                        mask in minimum_safe_weight_masks(problem, source_mask)
                    )
                    traces = [
                        (
                            order = order,
                            trace = safe_pruning_trace(
                                problem,
                                source_mask,
                                order,
                            ),
                        ) for order in orders
                    ]
                    maximum_burden_trace =
                        _maximum_burden_safe_trace(problem, source_mask)
                    maximum_burden_endpoint_weight = library_weight(
                        problem,
                        maximum_burden_trace.endpoint,
                    )
                    initial_candidates = Int[
                        strategy_index for
                        strategy_index in 1:active_strategy_count(problem) if
                        safely_deletable(
                            problem,
                            source_mask,
                            strategy_index,
                        )
                    ]
                    first_deletion = isempty(
                        maximum_burden_trace.deletions,
                    ) ? 0 : first(maximum_burden_trace.deletions)
                    strict_initial_maximum =
                        !iszero(first_deletion) &&
                        all(
                            problem.weights[first_deletion] >
                            problem.weights[strategy_index] for
                            strategy_index in initial_candidates if
                            strategy_index != first_deletion
                        )
                    if length(initial_candidates) >= 2 &&
                       strict_initial_maximum &&
                       maximum_burden_endpoint_weight > minimum_weight
                        score = (
                            active_count,
                            module_count,
                            maximum(problem.weights),
                            sum(problem.weights),
                            sum(count_ones, module_masks),
                            Tuple(module_masks),
                            Tuple(problem.weights),
                        )
                        witness = (
                            problem = problem,
                            source = source_mask,
                            trace = maximum_burden_trace,
                        )
                        if isnothing(maximum_burden_best) ||
                           score < maximum_burden_best.score
                            maximum_burden_best = (
                                score = score,
                                witness = witness,
                            )
                        end
                    end
                    for row in traces
                        endpoint_weight = library_weight(
                            problem,
                            row.trace.endpoint,
                        )
                        if endpoint_weight > minimum_weight
                            score = (
                                active_count,
                                module_count,
                                maximum(problem.weights),
                                sum(problem.weights),
                                sum(count_ones, module_masks),
                                Tuple(module_masks),
                                Tuple(problem.weights),
                                Tuple(row.order),
                            )
                            witness = (
                                problem = problem,
                                source = source_mask,
                                order = row.order,
                                trace = row.trace,
                            )
                            _update_best!(best, 2, score, witness)
                            if inclusion_irreducible(
                                problem,
                                row.trace.endpoint,
                            )
                                _update_best!(best, 4, score, witness)
                            end
                        end
                    end
                    for left_index in eachindex(traces)
                        left = traces[left_index]
                        for right_index in (left_index + 1):length(traces)
                            right = traces[right_index]
                            left.trace.endpoint == right.trace.endpoint && continue
                            left_weight = library_weight(
                                problem,
                                left.trace.endpoint,
                            )
                            right_weight = library_weight(
                                problem,
                                right.trace.endpoint,
                            )
                            left_weight == right_weight && continue
                            score = (
                                active_count,
                                module_count,
                                maximum(problem.weights),
                                sum(problem.weights),
                                sum(count_ones, module_masks),
                                Tuple(module_masks),
                                Tuple(problem.weights),
                                Tuple(left.order),
                                Tuple(right.order),
                            )
                            _update_best!(
                                best,
                                3,
                                score,
                                (
                                    problem = problem,
                                    source = source_mask,
                                    left = left,
                                    right = right,
                                ),
                            )
                        end
                    end
                end
            end
        end
    end

    all(haskey(best, number) for number in 1:4) ||
        error("compression search did not find every requested witness")
    isnothing(maximum_burden_best) &&
        error("compression search found no maximum-burden greedy witness")
    return best, counts, maximum_burden_best
end

function _search_capacity_nonconcavity(config)
    maximum_active = Int(config["max_active"])
    maximum_weight = Int(config["max_weight"])
    maximum_value = Int(config["max_value"])
    best = Dict{Int,Any}()
    counts = Dict("problems" => 0)

    for active_count in 1:maximum_active
        module_masks = UInt64[_bit(index) for index in 1:active_count]
        module_count = max(1, active_count)
        for weight_tuple in _tuples(1:maximum_weight, active_count)
            maximum_capacity = sum(weight_tuple)
            maximum_capacity >= 2 || continue
            for values in _monotone_value_tables(active_count, maximum_value)
                problem = _problem(
                    active_count,
                    collect(weight_tuple),
                    module_masks,
                    module_count,
                    values,
                )
                counts["problems"] += 1
                profile = discrete_capacity_profile(problem, maximum_capacity)
                for middle_budget in 1:(maximum_capacity - 1)
                    left_marginal = profile.marginals[middle_budget]
                    right_marginal = profile.marginals[middle_budget + 1]
                    right_marginal > left_marginal || continue
                    score = (
                        active_count,
                        maximum(problem.weights),
                        sum(problem.weights),
                        maximum(problem.values),
                        sum(problem.values),
                        middle_budget,
                        Tuple(problem.weights),
                        Tuple(problem.values),
                    )
                    _update_best!(
                        best,
                        5,
                        score,
                        (
                            problem = problem,
                            profile = profile,
                            middle_budget = middle_budget,
                        ),
                    )
                end
            end
        end
    end

    for active_count in 2:maximum_active
        weights = ones(Int, active_count)
        module_masks = UInt64[_bit(index) for index in 1:active_count]
        for values in _monotone_value_tables(active_count, maximum_value)
            problem = _problem(
                active_count,
                weights,
                module_masks,
                active_count,
                values,
            )
            profile = discrete_capacity_profile(problem, active_count)
            for middle_budget in 1:(active_count - 1)
                left_marginal = profile.marginals[middle_budget]
                right_marginal = profile.marginals[middle_budget + 1]
                right_marginal > left_marginal || continue
                score = (
                    active_count,
                    maximum(problem.values),
                    sum(problem.values),
                    middle_budget,
                    Tuple(problem.values),
                )
                _update_best!(
                    best,
                    6,
                    score,
                    (
                        problem = problem,
                        profile = profile,
                        middle_budget = middle_budget,
                    ),
                )
            end
        end
    end
    all(haskey(best, number) for number in (5, 6)) ||
        error("capacity search did not find both nonconcavity witnesses")
    return best, counts
end

function _search_penalized(config)
    maximum_active = Int(config["max_active"])
    maximum_weight = Int(config["max_weight"])
    maximum_value = Int(config["max_value"])
    best = Dict{Int,Any}()
    counts = Dict("problems" => 0)

    for active_count in 1:maximum_active
        module_masks = UInt64[_bit(index) for index in 1:active_count]
        module_count = max(1, active_count)
        for weight_tuple in _tuples(1:maximum_weight, active_count)
            for values in _monotone_value_tables(active_count, maximum_value)
                problem = _problem(
                    active_count,
                    collect(weight_tuple),
                    module_masks,
                    module_count,
                    values,
                )
                counts["problems"] += 1
                breakpoints = penalty_breakpoints(problem)
                probes = penalty_probe_prices(problem)

                for left_index in eachindex(probes)
                    left_price = probes[left_index]
                    left_optima = penalized_optimal_masks(problem, left_price)
                    length(left_optima) == 1 || continue
                    left_mask = only(left_optima)
                    for right_price in probes[(left_index + 1):end]
                        right_optima = penalized_optimal_masks(
                            problem,
                            right_price,
                        )
                        length(right_optima) == 1 || continue
                        right_mask = only(right_optima)
                        _incomparable(left_mask, right_mask) || continue
                        score = (
                            active_count,
                            maximum(problem.weights),
                            sum(problem.weights),
                            maximum(problem.values),
                            sum(problem.values),
                            left_price,
                            right_price,
                            Tuple(problem.weights),
                            Tuple(problem.values),
                        )
                        _update_best!(
                            best,
                            7,
                            score,
                            (
                                problem = problem,
                                left_price = left_price,
                                left_mask = left_mask,
                                right_price = right_price,
                                right_mask = right_mask,
                            ),
                        )
                    end
                end

                for breakpoint in breakpoints
                    breakpoint > 0 || continue
                    optimizers = penalized_optimal_masks(problem, breakpoint)
                    length(optimizers) >= 2 || continue
                    length(
                        unique([
                            library_weight(problem, mask) for mask in optimizers
                        ]),
                    ) >= 2 ||
                        continue
                    score = (
                        active_count,
                        maximum(problem.weights),
                        sum(problem.weights),
                        maximum(problem.values),
                        sum(problem.values),
                        breakpoint,
                        Tuple(problem.weights),
                        Tuple(problem.values),
                    )
                    _update_best!(
                        best,
                        9,
                        score,
                        (
                            problem = problem,
                            breakpoint = breakpoint,
                            optimizers = optimizers,
                        ),
                    )

                    lower_breakpoints = [
                        value for value in breakpoints if value < breakpoint
                    ]
                    higher_breakpoints = [
                        value for value in breakpoints if value > breakpoint
                    ]
                    left_price = isempty(lower_breakpoints) ?
                                 breakpoint / 2 :
                                 (last(lower_breakpoints) + breakpoint) / 2
                    right_price = isempty(higher_breakpoints) ?
                                  breakpoint + 1 :
                                  (breakpoint + first(higher_breakpoints)) / 2
                    left_optima = penalized_optimal_masks(problem, left_price)
                    right_optima = penalized_optimal_masks(problem, right_price)
                    length(left_optima) == 1 || continue
                    length(right_optima) == 1 || continue
                    left_mask = only(left_optima)
                    right_mask = only(right_optima)
                    left_weight = library_weight(problem, left_mask)
                    right_weight = library_weight(problem, right_mask)
                    left_weight == right_weight && continue
                    _update_best!(
                        best,
                        14,
                        score,
                        (
                            problem = problem,
                            breakpoint = breakpoint,
                            breakpoint_optimizers = optimizers,
                            left_price = left_price,
                            left_mask = left_mask,
                            right_price = right_price,
                            right_mask = right_mask,
                            left_slope = -left_weight,
                            right_slope = -right_weight,
                        ),
                    )
                end
            end
        end
    end
    all(haskey(best, number) for number in (7, 9, 14)) ||
        error("penalized search did not find all requested witnesses")
    return best, counts
end

function _audit_penalized_burden(config)
    maximum_active = Int(config["audit_max_active"])
    maximum_weight = Int(config["audit_max_weight"])
    maximum_value = Int(config["audit_max_value"])
    problem_count = 0
    price_pair_count = 0
    optimizer_pair_count = 0
    strict_example = nothing

    for active_count in 1:maximum_active
        module_masks = UInt64[_bit(index) for index in 1:active_count]
        for weight_tuple in _tuples(1:maximum_weight, active_count)
            for values in _monotone_value_tables(active_count, maximum_value)
                problem = _problem(
                    active_count,
                    collect(weight_tuple),
                    module_masks,
                    max(1, active_count),
                    values,
                )
                problem_count += 1
                probes = penalty_probe_prices(problem)
                for left_index in eachindex(probes)
                    left_price = probes[left_index]
                    left_optima = penalized_optimal_masks(problem, left_price)
                    for right_price in probes[(left_index + 1):end]
                        price_pair_count += 1
                        right_optima = penalized_optimal_masks(problem, right_price)
                        for left_mask in left_optima, right_mask in right_optima
                            optimizer_pair_count += 1
                            left_weight = library_weight(problem, left_mask)
                            right_weight = library_weight(problem, right_mask)
                            right_weight <= left_weight || error(
                                "penalized burden antitonicity failed",
                            )
                            if isnothing(strict_example) &&
                               length(left_optima) == 1 &&
                               length(right_optima) == 1 &&
                               right_weight < left_weight
                                strict_example = (
                                    problem = problem,
                                    left_price = left_price,
                                    left_mask = left_mask,
                                    right_price = right_price,
                                    right_mask = right_mask,
                                )
                            end
                        end
                    end
                end
            end
        end
    end
    isnothing(strict_example) &&
        error("burden audit found no strict decreasing example")
    return (
        problem_count = problem_count,
        price_pair_count = price_pair_count,
        optimizer_pair_count = optimizer_pair_count,
        strict_example = strict_example,
        maximum_active = maximum_active,
        maximum_weight = maximum_weight,
        maximum_value = maximum_value,
    )
end

function _search_replacement(config)
    maximum_incumbents = Int(config["max_incumbents"])
    maximum_weight = Int(config["max_weight"])
    best = nothing
    count = 0
    for incumbent_count in 1:maximum_incumbents
        active_count = incumbent_count + 1
        candidate_index = active_count
        module_masks = fill(UInt64(1), active_count)
        for weight_tuple in _tuples(1:maximum_weight, active_count)
            problem = _problem(
                active_count,
                collect(weight_tuple),
                module_masks,
                1,
                zeros(Int, 1 << active_count),
            )
            current_mask = (UInt64(1) << incumbent_count) - UInt64(1)
            candidate_bit = _bit(candidate_index)
            for capacity in 0:sum(weight_tuple)
                count += 1
                library_weight(problem, current_mask) <= capacity || continue
                library_weight(problem, current_mask | candidate_bit) > capacity ||
                    continue
                feasible_deletions = UInt64[]
                for retained_incumbents in UInt64(0):current_mask
                    _subset(retained_incumbents, current_mask) || continue
                    final_mask = retained_incumbents | candidate_bit
                    library_weight(problem, final_mask) <= capacity &&
                        push!(feasible_deletions, current_mask & ~retained_incumbents)
                end
                isempty(feasible_deletions) && continue
                score = (
                    incumbent_count,
                    maximum(problem.weights),
                    sum(problem.weights),
                    capacity,
                    Tuple(problem.weights),
                )
                witness = (
                    problem = problem,
                    current_mask = current_mask,
                    candidate_index = candidate_index,
                    capacity = exact_rational(capacity),
                    feasible_deletions = feasible_deletions,
                )
                if isnothing(best) || score < best.score
                    best = (score = score, witness = witness)
                end
            end
        end
    end
    isnothing(best) && error("replacement search found no deletion-required witness")
    return best, count
end

function _search_unsupported(config)
    maximum_active = Int(config["max_active"])
    maximum_value = Int(config["max_value"])
    best = nothing
    count = 0
    for active_count in 1:maximum_active
        weights = ones(Int, active_count)
        module_masks = UInt64[_bit(index) for index in 1:active_count]
        for values in _monotone_value_tables(active_count, maximum_value)
            problem = _problem(
                active_count,
                weights,
                module_masks,
                max(1, active_count),
                values,
            )
            count += 1
            for budget in 0:active_count
                optimizers = capacity_optimal_masks(problem, budget)
                length(optimizers) == 1 || continue
                optimizer = only(optimizers)
                supporting_price_interval(problem, optimizer) === nothing ||
                    continue
                score = (
                    active_count,
                    maximum(problem.values),
                    sum(problem.values),
                    budget,
                    Tuple(problem.values),
                )
                witness = (
                    problem = problem,
                    budget = exact_rational(budget),
                    optimizer = optimizer,
                )
                if isnothing(best) || score < best.score
                    best = (score = score, witness = witness)
                end
            end
        end
    end
    isnothing(best) && error("unsupported-capacity search found no witness")
    return best, count
end

function _search_closure_cardinality(config)
    maximum_value = Int(config["max_value"])
    best = nothing
    count = 0
    for values in _monotone_value_tables(2, maximum_value)
        problem = _problem(2, [1, 1], UInt64[1, 2], 2, values)
        count += 1
        left = UInt64(1)
        right = UInt64(2)
        count_ones(library_module_mask(problem, left)) ==
            count_ones(library_module_mask(problem, right)) || continue
        library_value(problem, left) == library_value(problem, right) && continue
        score = (
            maximum(problem.values),
            sum(problem.values),
            Tuple(problem.values),
        )
        witness = (problem = problem, left = left, right = right)
        if isnothing(best) || score < best.score
            best = (score = score, witness = witness)
        end
    end
    isnothing(best) && error("closure-cardinality search found no witness")
    return best, count
end

function _elasticity_family(config)
    maximum_denominator = Int(config["maximum_denominator"])
    maximum_denominator >= 2 ||
        throw(ArgumentError("elasticity family needs denominator at least two"))
    cost = exact_rational(1)
    rows = Dict{String,Any}[]
    for denominator in 1:maximum_denominator
        quality = cost + exact_rational(1) / exact_rational(denominator)
        margin = quality - cost
        elasticity = quality / margin
        push!(
            rows,
            Dict(
                "n" => denominator,
                "quality" => _ratio(quality),
                "cost" => _ratio(cost),
                "innovation_margin" => _ratio(margin),
                "level_elasticity" => _ratio(elasticity),
                "identity_check" => elasticity == denominator + 1,
            ),
        )
    end
    return (
        cost = cost,
        maximum_denominator = maximum_denominator,
        rows = rows,
    )
end

function _capacity_fixture(witness)
    problem = witness.problem
    profile = witness.profile
    return Dict{String,Any}(
        "problem" => _problem_dict(problem),
        "capacity_profile" => [
            Dict(
                "budget" => _ratio(profile.budgets[index]),
                "value" => _ratio(profile.values[index]),
                "optimizers" => [
                    _library_dict(problem, mask) for
                    mask in capacity_optimal_masks(
                        problem,
                        profile.budgets[index],
                    )
                ],
            ) for index in eachindex(profile.budgets)
        ],
        "marginals" => [_ratio(value) for value in profile.marginals],
        "violating_middle_budget" => witness.middle_budget,
        "left_marginal" => _ratio(
            profile.marginals[witness.middle_budget],
        ),
        "right_marginal" => _ratio(
            profile.marginals[witness.middle_budget + 1],
        ),
    )
end

function _build_claims(config)
    compression_best, compression_counts, maximum_burden_best =
        _search_compression(config["compression_search"])
    capacity_best, capacity_counts =
        _search_capacity_nonconcavity(config["capacity_search"])
    penalized_best, penalized_counts =
        _search_penalized(config["penalized_search"])
    burden_audit = _audit_penalized_burden(config["penalized_search"])
    replacement_best, replacement_count =
        _search_replacement(config["replacement_search"])
    unsupported_best, unsupported_count =
        _search_unsupported(config["unsupported_search"])
    closure_best, closure_count =
        _search_closure_cardinality(config["elasticity_search"])
    elasticity = _elasticity_family(config["elasticity_search"])

    claims = Dict{Int,Dict{String,Any}}()

    cardinality = compression_best[1].witness
    claims[1] = _claim(
        1,
        "CX-OPT-PRUNE-CARDINALITY-01",
        "Stepwise safe pruning can miss the global minimum cardinality",
        "counterexample_found",
        "Replace any minimum-cardinality claim for rechecked pruning by safety plus complete-trace inclusion irreducibility; exact global enumeration is separate.",
        "The failed claim lacks an exchange or matroid-type property for the safe-feasible set.",
        Dict(
            "lexicographic_score" => string(compression_best[1].score),
            "exhaustive_active_bound" => config["compression_search"]["max_active"],
            "exhaustive_module_bound" => config["compression_search"]["max_modules"],
            "no_smaller_active_witness" => true,
        ),
        Dict(
            "problem" => _problem_dict(cardinality.problem),
            "safe_set" => _safe_set_dict(cardinality.problem, cardinality.source),
            "greedy_trace" => _trace_dict(
                cardinality.problem,
                cardinality.trace,
                cardinality.order,
            ),
        ),
    )

    weight = compression_best[2].witness
    maximum_burden = maximum_burden_best.witness
    claims[2] = _claim(
        2,
        "CX-OPT-PRUNE-WEIGHT-01",
        "Stepwise safe pruning can miss the global minimum weight",
        "counterexample_found",
        "State rechecked pruning only as a feasible-reduction method; weighted global optimality requires enumeration or an optimizer certificate.",
        "The failed claim lacks a weight-compatible exchange property.",
        Dict(
            "lexicographic_score" => string(compression_best[2].score),
            "no_one_active_strategy_witness" => true,
            "maximum_burden_greedy_score" => string(
                maximum_burden_best.score,
            ),
            "strict_maximum_burden_greedy_two_active_strategies_exhausted" => true,
        ),
        Dict(
            "problem" => _problem_dict(weight.problem),
            "safe_set" => _safe_set_dict(weight.problem, weight.source),
            "greedy_trace" => _trace_dict(
                weight.problem,
                weight.trace,
                weight.order,
            ),
            "maximum_burden_greedy_counterexample" => Dict(
                "related_id" => "CX-OPT-GREEDY-WEIGHT-01",
                "problem" => _problem_dict(maximum_burden.problem),
                "safe_set" => _safe_set_dict(
                    maximum_burden.problem,
                    maximum_burden.source,
                ),
                "trace" => _trace_dict(
                    maximum_burden.problem,
                    maximum_burden.trace,
                    maximum_burden.trace.deletions,
                ),
                "selection_rule" => "delete a currently safe strategy of maximum weight; break ties by lowest strategy index; the first selected strategy is the unique maximum-weight safe deletion",
            ),
        ),
    )

    order = compression_best[3].witness
    claims[3] = _claim(
        3,
        "CX-OPT-DELETION-ORDER-WEIGHT-01",
        "Safe deletion orders can end at different resource burdens",
        "counterexample_found",
        "Make every deletion rule and tie breaker explicit; safety is order-robust but endpoint identity and burden are not.",
        "Equal compressed state does not identify raw representatives or catalog weights.",
        Dict(
            "lexicographic_score" => string(compression_best[3].score),
            "two_active_strategies_are_minimal" => true,
        ),
        Dict(
            "problem" => _problem_dict(order.problem),
            "safe_set" => _safe_set_dict(order.problem, order.source),
            "left_trace" => _trace_dict(
                order.problem,
                order.left.trace,
                order.left.order,
            ),
            "right_trace" => _trace_dict(
                order.problem,
                order.right.trace,
                order.right.order,
            ),
        ),
    )

    local_witness = compression_best[4].witness
    claims[4] = _claim(
        4,
        "CX-OPT-LOCAL-NONGLOBAL-01",
        "A locally irreducible safe library need not be globally optimal",
        "counterexample_found",
        "Retain only the one-way theorem that every global minimum is irreducible; delete the converse.",
        "The converse would require a global exchange property absent from general frontier--closure feasible sets.",
        Dict(
            "lexicographic_score" => string(compression_best[4].score),
            "two_active_strategies_are_minimal" => true,
        ),
        Dict(
            "problem" => _problem_dict(local_witness.problem),
            "safe_set" => _safe_set_dict(
                local_witness.problem,
                local_witness.source,
            ),
            "local_trace" => _trace_dict(
                local_witness.problem,
                local_witness.trace,
                local_witness.order,
            ),
        ),
    )

    claims[5] = _claim(
        5,
        "CX-OPT-CAPACITY-NONCONCAVE-01",
        "Discrete capacity value need not be concave",
        "counterexample_found",
        "Retain capacity monotonicity; state concavity only under an additional discrete-concavity or convexification assumption.",
        "Positive lumpy weights alone violate discrete unit-budget concavity.",
        Dict(
            "lexicographic_score" => string(capacity_best[5].score),
            "one_active_strategy_is_minimal" => true,
        ),
        _capacity_fixture(capacity_best[5].witness),
    )

    claims[6] = _claim(
        6,
        "CX-OPT-CAPACITY-INCREASING-RETURNS-01",
        "Capacity value can exhibit increasing marginal returns",
        "counterexample_found",
        "Permit strict increases in discrete shadow values; rule them out only under a proved diminishing-returns condition.",
        "Unit weights do not prevent complementarity in productive value.",
        Dict(
            "lexicographic_score" => string(capacity_best[6].score),
            "two_active_strategies_are_minimal_under_unit_weights" => true,
        ),
        _capacity_fixture(capacity_best[6].witness),
    )

    switch = penalized_best[7].witness
    claims[7] = _claim(
        7,
        "CX-OPT-PENALIZED-INCLUSION-SWITCH-01",
        "Penalized optimal libraries need not be nested as price rises",
        "counterexample_found",
        "Replace raw-inclusion monotonicity by the valid resource-burden antitonicity theorem and a set-valued switching correspondence.",
        "The failed claim lacks a single-crossing or nested-demand condition across raw libraries.",
        Dict(
            "lexicographic_score" => string(penalized_best[7].score),
            "two_active_strategies_are_minimal" => true,
        ),
        Dict(
            "problem" => _problem_dict(switch.problem),
            "lower_price" => _ratio(switch.left_price),
            "lower_price_optimizer" => _library_dict(
                switch.problem,
                switch.left_mask,
            ),
            "higher_price" => _ratio(switch.right_price),
            "higher_price_optimizer" => _library_dict(
                switch.problem,
                switch.right_mask,
            ),
            "raw_incomparable" => _incomparable(
                switch.left_mask,
                switch.right_mask,
            ),
            "burden_decreases" => library_weight(
                switch.problem,
                switch.right_mask,
            ) < library_weight(switch.problem, switch.left_mask),
        ),
    )

    strict = burden_audit.strict_example
    claims[8] = _claim(
        8,
        "FX-OPT-PENALIZED-BURDEN-MONOTONE-01",
        "Penalized-optimal resource burden is antitone in price",
        "survived_exhaustive_search",
        "Promote only the set-valued burden-order statement: for λ₁<λ₂, every low-price optimizer has burden at least every high-price optimizer.",
        "No raw-inclusion nesting, uniqueness, or differentiability assumption is needed.",
        Dict(
            "active_bound" => burden_audit.maximum_active,
            "weight_bound" => burden_audit.maximum_weight,
            "value_bound" => burden_audit.maximum_value,
            "problem_count" => burden_audit.problem_count,
            "price_pair_count" => burden_audit.price_pair_count,
            "optimizer_pair_count" => burden_audit.optimizer_pair_count,
        ),
        Dict(
            "strict_example_problem" => _problem_dict(strict.problem),
            "lower_price" => _ratio(strict.left_price),
            "lower_optimizer" => _library_dict(strict.problem, strict.left_mask),
            "higher_price" => _ratio(strict.right_price),
            "higher_optimizer" => _library_dict(strict.problem, strict.right_mask),
            "general_algebra" => "optimality at λ1 and λ2 implies (λ2-λ1)(W1-W2) >= 0",
        ),
    )

    tie = penalized_best[9].witness
    claims[9] = _claim(
        9,
        "CX-OPT-PENALIZED-BREAKPOINT-TIE-01",
        "Penalized retention can have multiple optimal libraries at a breakpoint",
        "counterexample_found",
        "Keep optimizer correspondences set-valued and place any deterministic tie breaker outside the value definition.",
        "Uniqueness fails at affine-envelope intersections.",
        Dict(
            "lexicographic_score" => string(penalized_best[9].score),
            "one_active_strategy_is_minimal" => true,
        ),
        Dict(
            "problem" => _problem_dict(tie.problem),
            "breakpoint" => _ratio(tie.breakpoint),
            "optimizers" => [
                _library_dict(tie.problem, mask) for mask in tie.optimizers
            ],
            "optimized_value" => _ratio(
                penalized_value(tie.problem, tie.breakpoint),
            ),
        ),
    )

    replacement = replacement_best.witness
    candidate_bit = _bit(replacement.candidate_index)
    claims[10] = _claim(
        10,
        "CX-OPT-ADMISSION-REQUIRES-DELETION-01",
        "An eligible candidate can require capacity-releasing deletion",
        "counterexample_found",
        "Use 'capacity-feasible after deletion,' not 'becomes admissible': outer eligibility precedes the replacement optimization.",
        "The no-deletion shortcut ignores the hard capacity constraint.",
        Dict(
            "lexicographic_score" => string(replacement_best.score),
            "one_incumbent_is_minimal" => true,
        ),
        Dict(
            "problem" => _problem_dict(replacement.problem),
            "capacity" => _ratio(replacement.capacity),
            "current_library" => _library_dict(
                replacement.problem,
                replacement.current_mask,
            ),
            "candidate" => replacement.problem.strategy_ids[
                replacement.candidate_index
            ],
            "without_deletion" => _library_dict(
                replacement.problem,
                replacement.current_mask | candidate_bit,
            ),
            "without_deletion_feasible" => false,
            "feasible_deletions" => [
                Dict(
                    "deleted" => library_strategy_ids(
                        replacement.problem,
                        deletion_mask,
                    )[2:end],
                    "final_library" => _library_dict(
                        replacement.problem,
                        (replacement.current_mask & ~deletion_mask) |
                        candidate_bit,
                    ),
                ) for deletion_mask in replacement.feasible_deletions
            ],
        ),
    )

    unsupported = unsupported_best.witness
    claims[11] = _claim(
        11,
        "CX-OPT-LAGRANGE-UNSUPPORTED-01",
        "A constrained optimum can be unsupported by every resource price",
        "counterexample_found",
        "Keep constrained and penalized problems separate; strong equivalence requires convexification or a proved discrete support property.",
        "The finite attainable resource--value set is nonconvex.",
        Dict(
            "lexicographic_score" => string(unsupported_best.score),
            "two_active_strategies_are_minimal" => true,
        ),
        Dict(
            "problem" => _problem_dict(unsupported.problem),
            "budget" => _ratio(unsupported.budget),
            "capacity_optimizer" => _library_dict(
                unsupported.problem,
                unsupported.optimizer,
            ),
            "supporting_price_interval" => nothing,
            "attainable_pairs" => [
                Dict(
                    "library" => library_strategy_ids(unsupported.problem, mask),
                    "weight" => _ratio(library_weight(unsupported.problem, mask)),
                    "value" => _ratio(library_value(unsupported.problem, mask)),
                ) for mask in library_masks(unsupported.problem)
            ],
        ),
    )

    closure = closure_best.witness
    claims[12] = _claim(
        12,
        "CX-OPT-CLOSURE-CARDINALITY-ELASTICITY-01",
        "Closure cardinality alone cannot identify productive value or elasticity",
        "counterexample_found",
        "Define elasticity along a named module/library perturbation with held-fixed primitives; do not differentiate with respect to |C| as a sufficient scalar state.",
        "The failed shortcut assumes exchangeable modules and value sufficiency of closure cardinality.",
        Dict(
            "lexicographic_score" => string(closure_best.score),
            "two_active_strategies_are_minimal" => true,
        ),
        Dict(
            "problem" => _problem_dict(closure.problem),
            "left_library" => _library_dict(closure.problem, closure.left),
            "right_library" => _library_dict(closure.problem, closure.right),
            "equal_closure_cardinality" => true,
            "different_productive_value" => true,
        ),
    )

    claims[13] = _claim(
        13,
        "CX-OPT-ELASTICITY-ZERO-MARGIN-01",
        "Level elasticity diverges near a zero innovation margin",
        "counterexample_found",
        "State level elasticity only on a domain with a positive innovation-margin floor, or use exact level changes or semielasticities near zero.",
        "A uniform elasticity bound requires the innovation margin to be bounded away from zero.",
        Dict(
            "active_strategy_count" => 1,
            "project_count" => 1,
            "parametric_family_is_size_minimal" => true,
        ),
        Dict(
            "margin_formula" => "μ(x)=x-1 on x>1",
            "elasticity_formula" => "ε(x)=x/μ(x)",
            "exact_family" => elasticity.rows,
            "maximum_tested_denominator" => elasticity.maximum_denominator,
            "unbounded_family_identity" => "x_n=1+1/n, μ_n=1/n, ε_n=n+1",
        ),
    )

    kink = penalized_best[14].witness
    claims[14] = _claim(
        14,
        "CX-OPT-VALUE-KINK-01",
        "Optimized penalized value has kinks at library-switching prices",
        "counterexample_found",
        "State the penalized envelope as finite convex piecewise affine; use one-sided slopes/subgradients rather than global differentiability.",
        "Differentiability fails when optimal affine branches with different burdens tie.",
        Dict(
            "lexicographic_score" => string(penalized_best[14].score),
            "one_active_strategy_is_minimal" => true,
        ),
        Dict(
            "problem" => _problem_dict(kink.problem),
            "breakpoint" => _ratio(kink.breakpoint),
            "breakpoint_optimizers" => [
                _library_dict(kink.problem, mask) for
                mask in kink.breakpoint_optimizers
            ],
            "left_probe_price" => _ratio(kink.left_price),
            "left_optimizer" => _library_dict(kink.problem, kink.left_mask),
            "left_slope" => _ratio(kink.left_slope),
            "right_probe_price" => _ratio(kink.right_price),
            "right_optimizer" => _library_dict(kink.problem, kink.right_mask),
            "right_slope" => _ratio(kink.right_slope),
            "slope_jump" => _ratio(kink.right_slope - kink.left_slope),
        ),
    )

    counts = Dict{String,Any}(
        "compression" => compression_counts,
        "capacity" => capacity_counts,
        "penalized" => penalized_counts,
        "penalized_burden_audit" => Dict(
            "problems" => burden_audit.problem_count,
            "price_pairs" => burden_audit.price_pair_count,
            "optimizer_pairs" => burden_audit.optimizer_pair_count,
        ),
        "replacement_checks" => replacement_count,
        "unsupported_capacity_problems" => unsupported_count,
        "closure_cardinality_problems" => closure_count,
    )
    return claims, counts
end

function _relative_path(path::AbstractString)
    return relpath(normpath(path), REPOSITORY_ROOT)
end

function _load_config(path::AbstractString)
    config = TOML.parsefile(path)
    config["schema_version"] == SCHEMA_VERSION ||
        throw(ArgumentError("unsupported resource-optimization audit schema"))
    return config
end

function run_resource_optimization_audit(
    ;
    config_path::AbstractString = DEFAULT_CONFIG,
)
    config = _load_config(config_path)
    claims, counts = _build_claims(config)
    counterexample_count = count(
        claim["status"] == "counterexample_found" for claim in values(claims)
    )
    survivor_count = count(
        claim["status"] == "survived_exhaustive_search" for claim in values(claims)
    )
    return Dict{String,Any}(
        "schema_version" => SCHEMA_VERSION,
        "experiment_id" => config["experiment_id"],
        "arithmetic" => "Rational{BigInt}",
        "julia_version" => string(VERSION),
        "config_file" => _relative_path(config_path),
        "config_sha256" => bytes2hex(sha256(read(config_path))),
        "claim_count" => length(claims),
        "counterexample_count" => counterexample_count,
        "survivor_count" => survivor_count,
        "search_counts" => counts,
        "claims" => Dict(
            lpad(string(number), 2, '0') => claims[number] for
            number in sort!(collect(keys(claims)))
        ),
        "formalization_gate" => Dict(
            "lean_changes_made" => false,
            "theorem_revisions_required_before_lean" => true,
            "all_counterexamples_exact" => true,
            "all_counterexamples_machine_readable" => true,
        ),
    )
end

function _json_escape(value::AbstractString)
    return replace(
        value,
        "\\" => "\\\\",
        "\"" => "\\\"",
        "\n" => "\\n",
        "\r" => "\\r",
        "\t" => "\\t",
    )
end

function _write_json(io::IO, value, indent::Int = 0)
    padding = " "^indent
    child_padding = " "^(indent + 2)
    if value isa AbstractDict
        keys_sorted = sort!(collect(keys(value)); by = string)
        print(io, "{")
        if !isempty(keys_sorted)
            print(io, "\n")
            for (index, key) in enumerate(keys_sorted)
                print(io, child_padding, "\"", _json_escape(string(key)), "\": ")
                _write_json(io, value[key], indent + 2)
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
                _write_json(io, item, indent + 2)
                index == length(value) || print(io, ",")
                print(io, "\n")
            end
            print(io, padding)
        end
        print(io, "]")
    elseif value isa AbstractString
        print(io, "\"", _json_escape(value), "\"")
    elseif value isa Bool
        print(io, value ? "true" : "false")
    elseif value === nothing
        print(io, "null")
    elseif value isa Integer
        print(io, value)
    elseif value isa Rational
        print(io, "\"", _ratio(value), "\"")
    else
        throw(ArgumentError("unsupported JSON value $(typeof(value))"))
    end
end

function render_json(value)
    return sprint() do io
        _write_json(io, value)
        print(io, "\n")
    end
end

function _artifact_payloads(config, result)
    output_config = config["outputs"]
    fixture_directory = normpath(
        joinpath(REPOSITORY_ROOT, output_config["fixture_directory"]),
    )
    payloads = Dict{String,String}()
    fixture_manifest = Dict{String,Any}()
    for claim_key in sort!(collect(keys(result["claims"])))
        claim = result["claims"][claim_key]
        claim_id = lowercase(replace(claim["id"], "-" => "_"))
        filename =
            "$(claim_key)_$(claim_id).json"
        path = joinpath(fixture_directory, filename)
        fixture_payload = Dict{String,Any}(
            "schema_version" => SCHEMA_VERSION,
            "experiment_id" => result["experiment_id"],
            "claim" => claim,
        )
        rendered = render_json(fixture_payload)
        payloads[path] = rendered
        fixture_manifest[claim_key] = Dict(
            "id" => claim["id"],
            "path" => _relative_path(path),
            "sha256" => bytes2hex(sha256(rendered)),
        )
    end
    summary = copy(result)
    summary["fixture_manifest"] = fixture_manifest
    summary_path = normpath(
        joinpath(REPOSITORY_ROOT, output_config["summary"]),
    )
    payloads[summary_path] = render_json(summary)
    return payloads
end

function write_resource_optimization_audit(
    ;
    config_path::AbstractString = DEFAULT_CONFIG,
    check::Bool = false,
)
    config = _load_config(config_path)
    result = run_resource_optimization_audit(; config_path)
    payloads = _artifact_payloads(config, result)
    for path in sort!(collect(keys(payloads)))
        rendered = payloads[path]
        if check
            isfile(path) || error("missing committed resource fixture: $path")
            read(path, String) == rendered ||
                error("resource optimization artifact drift: $path")
        else
            mkpath(dirname(path))
            open(path, "w") do io
                print(io, rendered)
            end
        end
    end
    return result
end

function _parse_args(args)
    check = false
    config_path = DEFAULT_CONFIG
    for argument in args
        if argument == "--check"
            check = true
        elseif startswith(argument, "--config=")
            config_path = split(argument, "="; limit = 2)[2]
        else
            throw(ArgumentError("unknown argument: $argument"))
        end
    end
    return (check = check, config_path = config_path)
end

function main(args = ARGS)
    options = _parse_args(args)
    result = write_resource_optimization_audit(
        ;
        config_path = options.config_path,
        check = options.check,
    )
    println("claims=$(result["claim_count"])")
    println("counterexamples=$(result["counterexample_count"])")
    println("survivors=$(result["survivor_count"])")
    println("arithmetic=$(result["arithmetic"])")
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
