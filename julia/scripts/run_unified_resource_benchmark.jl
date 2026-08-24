module UnifiedResourceBenchmark

using LinearAlgebra: I
using Printf
using StrategyInnovation
using TOML

if !isdefined(Main, :UnifiedCanonicalBenchmarkSolver)
    Base.include(Main, joinpath(@__DIR__, "solve_unified_canonical_benchmark.jl"))
end
if !isdefined(Main, :ResourceOptimization)
    Base.include(Main, joinpath(@__DIR__, "..", "src", "ResourceOptimization.jl"))
end

const Canonical = Main.UnifiedCanonicalBenchmarkSolver
const Resource = Main.ResourceOptimization

export main, run_unified_resource_benchmark

const EXPERIMENT_ID = "unified-canonical-resources-v1"
const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "unified_canonical_resources.toml",
)
const SCHEDULE_ORDER = ["equal_active", "carrier_heavy", "descendant_heavy"]
const ACTIVE_SYMBOLS = [:carrier_a, :carrier_b, :descendant]
const ACTIVE_IDS = StrategyId.(ACTIVE_SYMBOLS)
const MASKS = UInt64.(0:7)
const BLUE = "#2f5d8a"
const GOLD = "#d39b2a"
const ORANGE = "#c65d32"
const NAVY = "#172a3a"
const GRAY = "#66717e"
const LIGHT = "#e7edf2"
const PALETTE = Dict(
    "equal_active" => BLUE,
    "carrier_heavy" => GOLD,
    "descendant_heavy" => ORANGE,
)
const DASH = Dict(
    "equal_active" => "",
    "carrier_heavy" => "9 5",
    "descendant_heavy" => "2 4",
)

_ratio(value::Rational) = "$(numerator(value))//$(denominator(value))"
_maybe_ratio(value) = isnothing(value) ? "" : _ratio(value)
_belief_label(belief) = string(belief.id)
_absolute(path) = isabspath(path) ? path : joinpath(REPOSITORY_ROOT, path)

function _mask_ids(mask::UInt64)
    ids = String["inactive"]
    for (index, symbol) in enumerate(ACTIVE_SYMBOLS)
        iszero(mask & (UInt64(1) << (index - 1))) || push!(ids, string(symbol))
    end
    return ids
end

function _mask_label(mask::UInt64)
    labels = String["I"]
    for (index, label) in enumerate(("A", "B", "D"))
        iszero(mask & (UInt64(1) << (index - 1))) || push!(labels, label)
    end
    return join(labels, "+")
end

_mask_list(masks) = join((string(Int(mask)) for mask in masks), ";")
_label_list(masks) = join((_mask_label(mask) for mask in masks), ";")
_value_list(values) = join((_ratio(value) for value in values), ";")

function _raw_library(process, mask::UInt64)
    ids = typeof(process.catalog.inactive_strategy)[process.catalog.inactive_strategy]
    for (index, strategy_id) in enumerate(ACTIVE_IDS)
        iszero(mask & (UInt64(1) << (index - 1))) || push!(ids, strategy_id)
    end
    return RawLibrary(process.catalog, ids)
end

function _state_index(experiment, belief, state)
    index = findfirst(isequal((belief, state)), experiment.exact_model.states)
    isnothing(index) && error("unified state is absent from the compiled model")
    return index
end

function _schedule_rows(config)
    configured = config["weight_schedules"]
    Set(keys(configured)) == Set(SCHEDULE_ORDER) ||
        error("the preregistered resource schedules changed")
    rows = NamedTuple[]
    for id in SCHEDULE_ORDER
        schedule = configured[id]
        inactive = exact_rational(schedule["inactive"])
        weights = ExactRational[
            exact_rational(schedule["carrier_a"]),
            exact_rational(schedule["carrier_b"]),
            exact_rational(schedule["descendant"]),
        ]
        inactive > 0 && all(>(zero(ExactRational)), weights) ||
            error("every registered resource weight must be positive")
        weights[1] == weights[2] ||
            error("the exchangeable capability carriers must remain symmetric")
        push!(rows, (; id, label = schedule["label"], inactive, weights))
    end
    return rows
end

_total_burden(problem, inactive_weight, mask) =
    inactive_weight + Resource.library_weight(problem, mask)

function _reward_derivative(process, belief, state, action)
    action isa ContinueAction && return zero(ExactRational)
    project = only(row for row in process.projects if row.id == action.project)
    project.operates_during_research || return zero(ExactRational)
    law = process.completion(project, belief, state)
    discount = process.discount
    derivative = zero(ExactRational)
    for (outcome, mass) in zip(law.outcomes, law.probabilities)
        path_derivative = sum(
            exact_rational(time) * discount^(time - 1) *
            state.frontier[outcome.path[time + 1]] for
            time in 1:(project.duration - 1);
            init = zero(ExactRational),
        )
        derivative += mass * path_derivative
    end
    return derivative
end

"""Exact fixed-policy derivative with respect to the benchmark discount."""
function _productive_discount_derivative(experiment)
    process = experiment.fixture.process
    model = experiment.exact_model
    state_indices = Dict(state => index for (index, state) in enumerate(model.states))
    n = length(model.states)
    rewards = zeros(ExactRational, n)
    reward_derivatives = zeros(ExactRational, n)
    transitions = zeros(ExactRational, n, n)
    transition_derivatives = zeros(ExactRational, n, n)
    for index in eachindex(model.states)
        belief, state = model.states[index]
        label = experiment.exact_policy[index]
        action = only(
            action for action in unified_available_actions(process, state) if
            action_label(action) == label
        )
        embedded = compressed_embedded_transition(process, belief, state, action)
        rewards[index] = expectation(embedded, outcome -> outcome.reward)
        reward_derivatives[index] = _reward_derivative(process, belief, state, action)
        for (outcome, mass) in zip(embedded.outcomes, embedded.probabilities)
            next_key = (outcome.next_state.belief, outcome.next_state.state)
            next_index = state_indices[next_key]
            duration = outcome.holding_time
            transitions[index, next_index] +=
                process.discount^duration * mass
            transition_derivatives[index, next_index] +=
                exact_rational(duration) *
                process.discount^(duration - 1) * mass
        end
    end
    values = (Matrix{ExactRational}(I, n, n) - transitions) \ rewards
    values == experiment.exact_values ||
        error("fixed-policy value reconstruction changed the exact benchmark")
    derivatives = (Matrix{ExactRational}(I, n, n) - transitions) \
                  (reward_derivatives + transition_derivatives * values)
    return (; values, derivatives, rewards, reward_derivatives, transitions,
            transition_derivatives)
end

function _passive_values_and_derivatives(process, state)
    beliefs = collect(process.belief_kernel.space)
    n = length(beliefs)
    transition = ExactRational[
        transition_probability(process.belief_kernel, belief, next) for
        belief in beliefs, next in beliefs
    ]
    reward = ExactRational[state.frontier[belief] for belief in beliefs]
    resolvent = Matrix{ExactRational}(I, n, n) - process.discount * transition
    values = resolvent \ reward
    derivatives = resolvent \ (transition * values)
    return (; beliefs, values, derivatives)
end

function _action_details(experiment, belief, state)
    index = _state_index(experiment, belief, state)
    values = [
        (
            label = action.label,
            value = Canonical._action_value(action, experiment.exact_values),
        ) for action in experiment.exact_model.actions[index]
    ]
    sort!(values; by = row -> row.value, rev = true)
    best, second = values[1], values[2]
    best.label == experiment.exact_policy[index] ||
        error("action certificate and exact policy disagree")
    margin = best.value - second.value
    margin > 0 || error("resource extension encountered an action tie")
    return (
        action = best.label,
        second_action = second.label,
        action_margin = margin,
        action_tie_distance_linf = margin / 2,
    )
end

function _channel_rows(experiment)
    process = experiment.fixture.process
    productive = _productive_discount_derivative(experiment)
    passive_by_state = Dict(
        state => _passive_values_and_derivatives(process, state) for
        state in process.compressed_states
    )
    rows = NamedTuple[]
    for mask in MASKS
        library = _raw_library(process, mask)
        state = compressed_library_state(process.catalog, process.closure, library)
        passive = passive_by_state[state]
        for (belief_index, belief) in enumerate(process.belief_kernel.space)
            state_index = _state_index(experiment, belief, state)
            total_value = productive.values[state_index]
            total_derivative = productive.derivatives[state_index]
            operational_value = passive.values[belief_index]
            operational_derivative = passive.derivatives[belief_index]
            generative_value = total_value - operational_value
            generative_derivative = total_derivative - operational_derivative
            beta = process.discount
            total_scaled = beta * total_derivative
            operational_scaled = beta * operational_derivative
            generative_scaled = beta * generative_derivative
            total_value > 0 || error("productive benchmark value must be positive")
            action = _action_details(experiment, belief, state)
            push!(
                rows,
                (;
                    mask,
                    library = _mask_label(mask),
                    strategies = join(_mask_ids(mask), "|"),
                    compressed_state = Canonical._state_label(state),
                    belief = _belief_label(belief),
                    productive_value = total_value,
                    operational_value,
                    generative_value,
                    productive_discount_derivative = total_derivative,
                    operational_discount_derivative = operational_derivative,
                    generative_discount_derivative = generative_derivative,
                    productive_scaled_sensitivity = total_scaled,
                    operational_scaled_sensitivity = operational_scaled,
                    generative_scaled_sensitivity = generative_scaled,
                    innovation_duration = total_scaled / total_value,
                    operational_elasticity = operational_value > 0 ?
                                             operational_scaled / operational_value : nothing,
                    generative_elasticity = generative_value > 0 ?
                                            generative_scaled / generative_value : nothing,
                    operational_contribution = operational_scaled / total_value,
                    generative_contribution = generative_scaled / total_value,
                    action...,
                ),
            )
        end
    end
    return rows
end

function _channel_lookup(rows, belief, mask)
    return only(row for row in rows if row.belief == belief && row.mask == mask)
end

function _retention_problem(channel_rows, schedule, belief)
    values = ExactRational[]
    operational = ExactRational[]
    generative = ExactRational[]
    for mask in MASKS
        row = _channel_lookup(channel_rows, belief, mask)
        push!(values, row.productive_value)
        push!(operational, row.operational_value)
        push!(generative, row.generative_value)
    end
    profiles = ExactRational[0 0; 0 0; 2 4]
    return Resource.ExactRetentionProblem(
        string.(ACTIVE_SYMBOLS),
        schedule.weights,
        profiles,
        UInt64[1, 1, 1],
        1,
        values;
        operational_values = operational,
        generative_values = generative,
    )
end

function _safe_compression_rows(problems, schedules)
    rows = NamedTuple[]
    for schedule in schedules
        low_problem = problems[(schedule.id, "low")]
        high_problem = problems[(schedule.id, "high")]
        for source_mask in MASKS
            result = Resource.minimum_weight_safe_compression(low_problem, source_mask)
            optimal_masks = UInt64[library.mask for library in result.optimal_libraries]
            feasible = Resource.safe_sublibraries(low_problem, source_mask)
            all(Resource.exact_safe_feasible(low_problem, mask, source_mask) for mask in optimal_masks) ||
                error("safe-compression optimum is not exactly feasible")
            all(
                Resource.library_total_value(low_problem, mask) ==
                Resource.library_total_value(low_problem, source_mask) &&
                Resource.library_total_value(high_problem, mask) ==
                Resource.library_total_value(high_problem, source_mask) for
                mask in feasible
            ) || error("productive value was not preserved in the exact safe set")
            source_burden = _total_burden(low_problem, schedule.inactive, source_mask)
            optimal_total = schedule.inactive + result.optimal_objective
            all(
                _total_burden(low_problem, schedule.inactive, mask) == optimal_total for
                mask in optimal_masks
            ) || error("safe-compression burden certificate failed")
            optimal_total <= source_burden || error("safe compression raised burden")
            push!(
                rows,
                (
                    schedule = schedule.id,
                    source_mask,
                    source_library = _mask_label(source_mask),
                    source_burden,
                    feasible_masks = _mask_list(feasible),
                    optimal_objective = optimal_total,
                    optimal_masks = _mask_list(optimal_masks),
                    optimal_libraries = _label_list(optimal_masks),
                    burden_reduction = source_burden - optimal_total,
                    frontier = _value_list(Resource.library_frontier(low_problem, source_mask)),
                    closure = join(Resource.library_closure(low_problem, source_mask), ";"),
                    productive_low = Resource.library_total_value(low_problem, source_mask),
                    productive_high = Resource.library_total_value(high_problem, source_mask),
                    enumerated_count = length(result.certificate.enumerated_masks),
                    feasible_count = length(feasible),
                    all_optima_feasible = result.certificate.all_optima_feasible,
                    productive_value_preserved = result.certificate.productive_value_preserved,
                    ties_complete = result.certificate.ties_complete,
                ),
            )
        end
    end
    return rows
end

function _library_rows(problems, schedules, channel_rows)
    rows = NamedTuple[]
    for schedule in schedules, belief in ("low", "high"), mask in MASKS
        problem = problems[(schedule.id, belief)]
        channel = _channel_lookup(channel_rows, belief, mask)
        burden = _total_burden(problem, schedule.inactive, mask)
        push!(
            rows,
            (
                schedule = schedule.id,
                belief,
                mask,
                library = _mask_label(mask),
                strategies = channel.strategies,
                compressed_state = channel.compressed_state,
                inactive_weight = schedule.inactive,
                carrier_a_weight = schedule.weights[1],
                carrier_b_weight = schedule.weights[2],
                descendant_weight = schedule.weights[3],
                burden,
                productive_value = channel.productive_value,
                operational_value = channel.operational_value,
                generative_value = channel.generative_value,
                total_value = channel.productive_value,
                net_value_at_unit_price = channel.productive_value - burden,
                innovation_duration = channel.innovation_duration,
                action = channel.action,
                second_action = channel.second_action,
                action_margin = channel.action_margin,
                action_tie_distance_linf = channel.action_tie_distance_linf,
                frontier = _value_list(Resource.library_frontier(problem, mask)),
                closure = join(Resource.library_closure(problem, mask), ";"),
            ),
        )
    end
    return rows
end

function _capacity_rows(problems, schedules, channel_rows)
    rows = NamedTuple[]
    for schedule in schedules, belief in ("low", "high")
        problem = problems[(schedule.id, belief)]
        capacities = sort(unique(
            _total_burden(problem, schedule.inactive, mask) for mask in MASKS
        ))
        objectives = ExactRational[]
        results = NamedTuple[]
        for capacity in capacities
            variable_capacity = capacity - schedule.inactive
            result = Resource.capacity_optimal_library(
                problem,
                variable_capacity,
                belief,
                schedule.id,
            )
            masks = UInt64[library.mask for library in result.optimal_libraries]
            all(
                _total_burden(problem, schedule.inactive, mask) <= capacity for
                mask in masks
            ) || error("capacity optimizer returned an infeasible library")
            selected = first(sort(masks; by = mask -> (
                _total_burden(problem, schedule.inactive, mask), mask
            )))
            push!(objectives, result.optimal_objective)
            push!(results, (; capacity, result, masks, selected))
        end
        issorted(objectives) || error("capacity value is not weakly increasing")
        for index in eachindex(results)
            entry = results[index]
            capacity = entry.capacity
            result = entry.result
            masks = entry.masks
            selected = entry.selected
            selected_channel = _channel_lookup(channel_rows, belief, selected)
            if index < length(results)
                next_capacity = results[index + 1].capacity
                next_value = results[index + 1].result.optimal_objective
                increment = next_capacity - capacity
                shadow = (next_value - result.optimal_objective) / increment
                arc = capacity > 0 && result.optimal_objective > 0 ?
                      ((next_value - result.optimal_objective) /
                       result.optimal_objective) * (capacity / increment) : nothing
            else
                next_capacity = nothing
                increment = nothing
                shadow = nothing
                arc = nothing
            end
            push!(
                rows,
                (
                    schedule = schedule.id,
                    belief,
                    capacity,
                    optimal_objective = result.optimal_objective,
                    optimal_masks = _mask_list(masks),
                    optimal_libraries = _label_list(masks),
                    optimal_burdens = _value_list(
                        _total_burden(problem, schedule.inactive, mask) for mask in masks
                    ),
                    selected_mask = selected,
                    selected_library = _mask_label(selected),
                    selected_burden = _total_burden(problem, schedule.inactive, selected),
                    operational_value = selected_channel.operational_value,
                    generative_value = selected_channel.generative_value,
                    total_value = selected_channel.productive_value,
                    next_capacity,
                    capacity_increment = increment,
                    forward_shadow = shadow,
                    forward_capacity_arc_elasticity = arc,
                    feasible_count = length(result.certificate.feasible_masks),
                    enumerated_count = length(result.certificate.enumerated_masks),
                    all_optima_feasible = result.certificate.all_optima_feasible,
                    ties_complete = result.certificate.ties_complete,
                ),
            )
        end
    end
    return rows
end

function _actual_breakpoints(problem, belief, schedule)
    return Resource.optimizer_breakpoints(problem, belief, schedule)
end

function _pairwise_switching_rows(problems, schedules)
    rows = NamedTuple[]
    for schedule in schedules, belief in ("low", "high")
        problem = problems[(schedule.id, belief)]
        actual = _actual_breakpoints(problem, belief, schedule)
        actual_prices = Set(actual.prices)
        for left_index in 1:(length(MASKS) - 1)
            left = MASKS[left_index]
            for right_index in (left_index + 1):length(MASKS)
                right = MASKS[right_index]
                left_burden = _total_burden(problem, schedule.inactive, left)
                right_burden = _total_burden(problem, schedule.inactive, right)
                left_value = Resource.library_total_value(problem, left)
                right_value = Resource.library_total_value(problem, right)
                if left_burden == right_burden
                    price = nothing
                    relationship = left_value == right_value ? "coincident" : "parallel"
                    nonnegative = false
                    globally_active = false
                else
                    price = (left_value - right_value) /
                            (left_burden - right_burden)
                    nonnegative = price >= 0
                    relationship = "intersection"
                    if nonnegative && price in actual_prices
                        optimizers = Set(Resource.penalized_optimal_masks(problem, price))
                        globally_active = left in optimizers && right in optimizers
                    else
                        globally_active = false
                    end
                end
                push!(
                    rows,
                    (
                        schedule = schedule.id,
                        belief,
                        left_mask = left,
                        left_library = _mask_label(left),
                        left_value,
                        left_burden,
                        right_mask = right,
                        right_library = _mask_label(right),
                        right_value,
                        right_burden,
                        relationship,
                        switching_price = price,
                        nonnegative_candidate = nonnegative,
                        globally_active,
                    ),
                )
            end
        end
    end
    return rows
end

function _selected_by_minimum_burden(problem, inactive, masks)
    return first(sort(collect(masks); by = mask -> (
        _total_burden(problem, inactive, mask), mask
    )))
end

function _price_cell(
    problem,
    schedule,
    belief,
    channel_rows,
    kind,
    lower,
    upper,
    probe,
    actual_prices,
)
    result = Resource.penalized_optimal_library(problem, probe, belief, schedule.id)
    masks = UInt64[library.mask for library in result.optimal_libraries]
    selected = _selected_by_minimum_burden(problem, schedule.inactive, masks)
    selected_channel = _channel_lookup(channel_rows, belief, selected)
    total_burdens = ExactRational[
        _total_burden(problem, schedule.inactive, mask) for mask in masks
    ]
    net_value = result.optimal_objective - probe * schedule.inactive
    exact_objective = maximum(
        Resource.library_total_value(problem, mask) -
        probe * _total_burden(problem, schedule.inactive, mask) for mask in MASKS
    )
    net_value == exact_objective || error("penalized total-burden objective mismatch")
    if kind == "breakpoint"
        radius = zero(ExactRational)
    else
        distances = ExactRational[abs(probe - price) for price in actual_prices]
        radius = isempty(distances) ? nothing : minimum(distances)
    end
    fragility = !isnothing(radius) && radius > 0 ? probe / radius : nothing
    minimum_action_margin = minimum(
        _channel_lookup(channel_rows, belief, mask).action_margin for mask in masks
    )
    minimum_action_distance = minimum_action_margin / 2
    return (
        schedule = schedule.id,
        belief,
        cell_kind = kind,
        lower_price = lower,
        upper_price = upper,
        lower_inclusive = kind == "breakpoint",
        upper_inclusive = kind == "breakpoint",
        probe_price = probe,
        optimal_objective = net_value,
        optimal_masks = _mask_list(masks),
        optimal_libraries = _label_list(masks),
        optimal_burdens = _value_list(total_burdens),
        selected_mask = selected,
        selected_library = _mask_label(selected),
        selected_burden = _total_burden(problem, schedule.inactive, selected),
        productive_value = selected_channel.productive_value,
        operational_value = selected_channel.operational_value,
        generative_value = selected_channel.generative_value,
        net_value,
        library_breakpoint_distance = radius,
        library_inverse_fragility = fragility,
        minimum_action_margin,
        action_tie_distance_linf = minimum_action_distance,
        enumerated_count = length(result.certificate.enumerated_masks),
        ties_complete = result.certificate.ties_complete,
    )
end

function _penalized_interval_rows(problems, schedules, channel_rows)
    rows = NamedTuple[]
    for schedule in schedules, belief in ("low", "high")
        problem = problems[(schedule.id, belief)]
        actual = _actual_breakpoints(problem, belief, schedule)
        prices = sort(unique(actual.prices))
        for price in prices
            push!(
                rows,
                _price_cell(
                    problem, schedule, belief, channel_rows,
                    "breakpoint", price, price, price, prices,
                ),
            )
        end
        boundaries = sort(unique(vcat(zero(ExactRational), prices)))
        for index in 1:(length(boundaries) - 1)
            lower, upper = boundaries[index], boundaries[index + 1]
            lower == upper && continue
            probe = (lower + upper) / 2
            push!(
                rows,
                _price_cell(
                    problem, schedule, belief, channel_rows,
                    "open_interval", lower, upper, probe, prices,
                ),
            )
        end
        lower = isempty(boundaries) ? zero(ExactRational) : last(boundaries)
        probe = lower + 1
        push!(
            rows,
            _price_cell(
                problem, schedule, belief, channel_rows,
                "terminal_interval", lower, nothing, probe, prices,
            ),
        )
    end
    sort!(rows; by = row -> (
        findfirst(==(row.schedule), SCHEDULE_ORDER),
        row.belief == "low" ? 1 : 2,
        row.probe_price,
        row.cell_kind == "breakpoint" ? 1 : 2,
    ))
    for schedule in schedules, belief in ("low", "high")
        selection = [
            row for row in rows if row.schedule == schedule.id &&
            row.belief == belief
        ]
        sort!(selection; by = row -> row.probe_price)
        burdens = ExactRational[row.selected_burden for row in selection]
        all(burdens[index] >= burdens[index + 1] for index in 1:(length(burdens) - 1)) ||
            error("minimum-burden optimal price selection is not weakly decreasing")
    end
    return rows
end

function _csv_escape(value)
    text = if isnothing(value)
        ""
    elseif value isa Rational
        _ratio(value)
    else
        string(value)
    end
    if occursin(',', text) || occursin('"', text) || occursin('\n', text)
        return "\"" * replace(text, "\"" => "\"\"") * "\""
    end
    return text
end

function _csv(rows, columns)
    io = IOBuffer()
    println(io, join(string.(columns), ","))
    for row in rows
        println(io, join((_csv_escape(getproperty(row, column)) for column in columns), ","))
    end
    return String(take!(io))
end

function _render_libraries(rows)
    return _csv(rows, (
        :schedule, :belief, :mask, :library, :strategies, :compressed_state,
        :inactive_weight, :carrier_a_weight, :carrier_b_weight, :descendant_weight,
        :burden, :productive_value, :operational_value, :generative_value,
        :total_value, :net_value_at_unit_price, :innovation_duration, :action,
        :second_action, :action_margin, :action_tie_distance_linf, :frontier, :closure,
    ))
end

function _render_safe_compression(rows)
    return _csv(rows, (
        :schedule, :source_mask, :source_library, :source_burden,
        :feasible_masks, :optimal_objective, :optimal_masks, :optimal_libraries,
        :burden_reduction, :frontier, :closure, :productive_low, :productive_high,
        :enumerated_count, :feasible_count, :all_optima_feasible,
        :productive_value_preserved, :ties_complete,
    ))
end

function _render_capacity(rows)
    return _csv(rows, (
        :schedule, :belief, :capacity, :optimal_objective, :optimal_masks,
        :optimal_libraries, :optimal_burdens, :selected_mask, :selected_library,
        :selected_burden, :operational_value, :generative_value, :total_value,
        :next_capacity, :capacity_increment, :forward_shadow,
        :forward_capacity_arc_elasticity, :feasible_count, :enumerated_count,
        :all_optima_feasible, :ties_complete,
    ))
end

function _render_penalized(rows)
    return _csv(rows, (
        :schedule, :belief, :cell_kind, :lower_price, :upper_price,
        :lower_inclusive, :upper_inclusive, :probe_price, :optimal_objective,
        :optimal_masks, :optimal_libraries, :optimal_burdens, :selected_mask,
        :selected_library, :selected_burden, :productive_value, :operational_value,
        :generative_value, :net_value, :library_breakpoint_distance,
        :library_inverse_fragility, :minimum_action_margin,
        :action_tie_distance_linf, :enumerated_count, :ties_complete,
    ))
end

function _render_switching_prices(rows)
    return _csv(rows, (
        :schedule, :belief, :left_mask, :left_library, :left_value,
        :left_burden, :right_mask, :right_library, :right_value, :right_burden,
        :relationship, :switching_price, :nonnegative_candidate, :globally_active,
    ))
end

function _render_channel_elasticities(rows)
    return _csv(rows, (
        :mask, :library, :strategies, :compressed_state, :belief,
        :productive_value, :operational_value, :generative_value,
        :productive_discount_derivative, :operational_discount_derivative,
        :generative_discount_derivative, :productive_scaled_sensitivity,
        :operational_scaled_sensitivity, :generative_scaled_sensitivity,
        :innovation_duration, :operational_elasticity, :generative_elasticity,
        :operational_contribution, :generative_contribution, :action,
        :second_action, :action_margin, :action_tie_distance_linf,
    ))
end

function _tex_fraction(value::Rational)
    denominator(value) == 1 && return string(numerator(value))
    return "\\frac{$(numerator(value))}{$(denominator(value))}"
end

_tex_optional(value) = isnothing(value) ? "--" : _tex_fraction(value)

function _render_channel_table(rows)
    representatives = [
        row for row in rows if row.mask in UInt64[0, 1, 4]
    ]
    sort!(representatives; by = row -> (
        row.belief == "low" ? 1 : 2,
        findfirst(==(row.mask), UInt64[0, 1, 4]),
    ))
    io = IOBuffer()
    println(io, "% Generated by julia/scripts/run_unified_resource_benchmark.jl")
    println(io, "\\begin{tabular}{llrrrrrr}")
    println(io, "\\toprule")
    println(io, "Belief & Library & \$V\$ & \$V^{\\mathrm{op}}\$ & \$V^{\\mathrm{gen}}\$ & \$D_\\beta\$ & \$E^{\\mathrm{op}}_\\beta\$ & \$E^{\\mathrm{gen}}_\\beta\$ \\\\")
    println(io, "\\midrule")
    for row in representatives
        println(
            io,
            row.belief,
            " & ",
            row.library,
            " & \$",
            _tex_fraction(row.productive_value),
            "\$ & \$",
            _tex_fraction(row.operational_value),
            "\$ & \$",
            _tex_fraction(row.generative_value),
            "\$ & \$",
            _tex_fraction(row.innovation_duration),
            "\$ & \$",
            _tex_optional(row.operational_elasticity),
            "\$ & \$",
            _tex_optional(row.generative_elasticity),
            "\$ \\\\",
        )
    end
    println(io, "\\bottomrule")
    println(io, "\\end{tabular}")
    return String(take!(io))
end

function _xml(value)
    return replace(
        string(value),
        "&" => "&amp;",
        "<" => "&lt;",
        ">" => "&gt;",
        "\"" => "&quot;",
    )
end

function _svg_header(io, width, height, title, description)
    println(io, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\" viewBox=\"0 0 $width $height\" role=\"img\" aria-labelledby=\"title desc\">")
    println(io, "<title id=\"title\">$(_xml(title))</title>")
    println(io, "<desc id=\"desc\">$(_xml(description))</desc>")
    println(io, "<rect width=\"100%\" height=\"100%\" fill=\"#ffffff\"/>")
    println(io, "<style>text{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;fill:$NAVY}.title{font-size:20px;font-weight:650}.subtitle{font-size:12px;fill:$GRAY}.axis{font-size:11px;fill:$GRAY}.label{font-size:12px}.small{font-size:10px;fill:$GRAY}</style>")
end

function _svg_footer(io)
    println(io, "</svg>")
    return String(take!(io))
end

_sx(value, minimum_value, maximum_value, x, width) =
    x + width * (Float64(value) - Float64(minimum_value)) /
        (Float64(maximum_value) - Float64(minimum_value))
_sy(value, minimum_value, maximum_value, y, height) =
    y + height * (1 - (Float64(value) - Float64(minimum_value)) /
        (Float64(maximum_value) - Float64(minimum_value)))

function _draw_panel_axes(io, x, y, width, height, x_min, x_max, y_min, y_max, panel_title)
    println(io, "<text x=\"$x\" y=\"$(y - 10)\" class=\"label\" font-weight=\"600\">$(_xml(panel_title))</text>")
    println(io, "<line x1=\"$x\" y1=\"$(y + height)\" x2=\"$(x + width)\" y2=\"$(y + height)\" stroke=\"$GRAY\"/>")
    println(io, "<line x1=\"$x\" y1=\"$y\" x2=\"$x\" y2=\"$(y + height)\" stroke=\"$GRAY\"/>")
    for fraction in 0:4
        xx = x + width * fraction / 4
        yy = y + height * fraction / 4
        x_value = Float64(x_min) + (Float64(x_max) - Float64(x_min)) * fraction / 4
        y_value = Float64(y_max) - (Float64(y_max) - Float64(y_min)) * fraction / 4
        println(io, "<line x1=\"$xx\" y1=\"$y\" x2=\"$xx\" y2=\"$(y + height)\" stroke=\"$LIGHT\"/>")
        println(io, "<line x1=\"$x\" y1=\"$yy\" x2=\"$(x + width)\" y2=\"$yy\" stroke=\"$LIGHT\"/>")
        println(io, "<text x=\"$xx\" y=\"$(y + height + 16)\" text-anchor=\"middle\" class=\"axis\">$(@sprintf("%.2g", x_value))</text>")
        println(io, "<text x=\"$(x - 7)\" y=\"$(yy + 4)\" text-anchor=\"end\" class=\"axis\">$(@sprintf("%.2g", y_value))</text>")
    end
end

function _render_value_capacity_figure(capacity_rows)
    io = IOBuffer()
    width, height = 980, 450
    _svg_header(io, width, height, "Productive value by exact capacity", "Two belief panels show the exact right-continuous capacity-value step function for each preregistered weight schedule.")
    println(io, "<text x=\"55\" y=\"35\" class=\"title\">Value–capacity curve</text>")
    println(io, "<text x=\"55\" y=\"55\" class=\"subtitle\">Exact right-continuous steps; markers identify attainable Rational{BigInt} capacities.</text>")
    y_max = maximum(row.optimal_objective for row in capacity_rows)
    x_max = maximum(row.capacity for row in capacity_rows)
    for (panel, belief) in enumerate(("low", "high"))
        x, y, panel_width, panel_height = 65 + (panel - 1) * 465, 100, 400, 280
        _draw_panel_axes(io, x, y, panel_width, panel_height, 1, x_max, 0, y_max, "Initial belief: $belief")
        for schedule in SCHEDULE_ORDER
            rows = [row for row in capacity_rows if row.schedule == schedule && row.belief == belief]
            sort!(rows; by = row -> row.capacity)
            step_points = Tuple{ExactRational,ExactRational}[
                (first(rows).capacity, first(rows).optimal_objective)
            ]
            for index in 2:length(rows)
                push!(step_points, (rows[index].capacity, rows[index - 1].optimal_objective))
                push!(step_points, (rows[index].capacity, rows[index].optimal_objective))
            end
            points = join((
                "$(_sx(capacity, 1, x_max, x, panel_width)),$(_sy(value, 0, y_max, y, panel_height))" for
                (capacity, value) in step_points
            ), " ")
            println(io, "<polyline points=\"$points\" fill=\"none\" stroke=\"$(PALETTE[schedule])\" stroke-width=\"2.4\" stroke-dasharray=\"$(DASH[schedule])\"/>")
            for row in rows
                xx = _sx(row.capacity, 1, x_max, x, panel_width)
                yy = _sy(row.optimal_objective, 0, y_max, y, panel_height)
                println(io, "<circle cx=\"$xx\" cy=\"$yy\" r=\"3.2\" fill=\"$(PALETTE[schedule])\"><title>$(_xml("$(schedule), B=$(_ratio(row.capacity)), V=$(_ratio(row.optimal_objective)), opt=$(row.optimal_libraries)"))</title></circle>")
            end
        end
    end
    println(io, "<text x=\"490\" y=\"425\" text-anchor=\"middle\" class=\"axis\">Total resource capacity B (including inactive policy)</text>")
    for (index, schedule) in enumerate(SCHEDULE_ORDER)
        x = 550 + (index - 1) * 135
        println(io, "<line x1=\"$x\" y1=\"55\" x2=\"$(x + 22)\" y2=\"55\" stroke=\"$(PALETTE[schedule])\" stroke-width=\"3\" stroke-dasharray=\"$(DASH[schedule])\"/>")
        println(io, "<text x=\"$(x + 27)\" y=\"59\" class=\"small\">$(_xml(replace(schedule, "_" => " ")))</text>")
    end
    return _svg_footer(io)
end

function _render_value_price_figure(problems, schedules, switching_rows)
    active_prices = ExactRational[
        row.switching_price for row in switching_rows if row.globally_active
    ]
    x_max = isempty(active_prices) ? one(ExactRational) : maximum(active_prices) * 5 // 4 + 1 // 4
    sample_prices = range(0.0, Float64(x_max); length = 181)
    envelope_value(problem, schedule, price) = maximum(
        Float64(Resource.library_total_value(problem, mask)) -
        price * Float64(_total_burden(problem, schedule.inactive, mask)) for mask in MASKS
    )
    all_values = Float64[]
    for schedule in schedules, belief in ("low", "high"), price in sample_prices
        push!(all_values, envelope_value(problems[(schedule.id, belief)], schedule, price))
    end
    y_min, y_max = minimum(all_values), maximum(all_values)
    y_min == y_max && (y_max += 1)
    io = IOBuffer()
    width, height = 980, 450
    _svg_header(io, width, height, "Net value envelope by resource price", "Float64 paths are sampled only for display from exact productive values and exact burdens; exact switching prices are tabulated separately.")
    println(io, "<text x=\"55\" y=\"35\" class=\"title\">Value–resource-price envelope</text>")
    println(io, "<text x=\"55\" y=\"55\" class=\"subtitle\">J(λ)=maxₗ[V(L)−λW(L)]; exact affine branches, Float64 rendering.</text>")
    for (panel, belief) in enumerate(("low", "high"))
        x, y, panel_width, panel_height = 65 + (panel - 1) * 465, 100, 400, 280
        _draw_panel_axes(io, x, y, panel_width, panel_height, 0, x_max, y_min, y_max, "Initial belief: $belief")
        for schedule in schedules
            problem = problems[(schedule.id, belief)]
            points = join((
                "$(_sx(price, 0, x_max, x, panel_width)),$(_sy(envelope_value(problem, schedule, price), y_min, y_max, y, panel_height))" for price in sample_prices
            ), " ")
            println(io, "<polyline points=\"$points\" fill=\"none\" stroke=\"$(PALETTE[schedule.id])\" stroke-width=\"2.4\" stroke-dasharray=\"$(DASH[schedule.id])\"/>")
        end
    end
    println(io, "<text x=\"490\" y=\"425\" text-anchor=\"middle\" class=\"axis\">Resource price λ</text>")
    for (index, schedule) in enumerate(SCHEDULE_ORDER)
        x = 550 + (index - 1) * 135
        println(io, "<line x1=\"$x\" y1=\"55\" x2=\"$(x + 22)\" y2=\"55\" stroke=\"$(PALETTE[schedule])\" stroke-width=\"3\" stroke-dasharray=\"$(DASH[schedule])\"/>")
        println(io, "<text x=\"$(x + 27)\" y=\"59\" class=\"small\">$(_xml(replace(schedule, "_" => " ")))</text>")
    end
    return _svg_footer(io)
end

function _library_color(mask::UInt64)
    mask == 0 && return "#c8d0d8"
    mask == 4 && return ORANGE
    return BLUE
end

function _render_library_path_figure(capacity_rows)
    x_min = minimum(row.capacity for row in capacity_rows)
    x_max = maximum(row.capacity for row in capacity_rows) + 1 // 2
    io = IOBuffer()
    width, height = 980, 430
    _svg_header(io, width, height, "Capacity-optimal selected-library path", "Each row uses the minimum-burden, lowest-mask member of the exact optimizer correspondence; CSV certificates retain every tie.")
    println(io, "<text x=\"55\" y=\"35\" class=\"title\">Optimal library path</text>")
    println(io, "<text x=\"55\" y=\"55\" class=\"subtitle\">Capacity path; ties use the declared minimum-burden then lowest-mask display selection.</text>")
    plot_x, plot_y, plot_width = 250, 85, 680
    row_height = 43
    row_index = 0
    for schedule in SCHEDULE_ORDER, belief in ("low", "high")
        row_index += 1
        y = plot_y + (row_index - 1) * row_height
        rows = [row for row in capacity_rows if row.schedule == schedule && row.belief == belief]
        sort!(rows; by = row -> row.capacity)
        println(io, "<text x=\"235\" y=\"$(y + 18)\" text-anchor=\"end\" class=\"label\">$(_xml(replace(schedule, "_" => " "))) · $belief</text>")
        for index in eachindex(rows)
            left = rows[index].capacity
            right = index < length(rows) ? rows[index + 1].capacity : x_max
            xx = _sx(left, x_min, x_max, plot_x, plot_width)
            width_segment = _sx(right, x_min, x_max, plot_x, plot_width) - xx
            color = _library_color(rows[index].selected_mask)
            println(io, "<rect x=\"$xx\" y=\"$y\" width=\"$width_segment\" height=\"28\" fill=\"$color\" stroke=\"#ffffff\"><title>$(_xml("B∈[$(_ratio(left)),$(_ratio(right))): $(rows[index].optimal_libraries)"))</title></rect>")
            width_segment > 42 && println(io, "<text x=\"$(xx + width_segment / 2)\" y=\"$(y + 19)\" text-anchor=\"middle\" font-size=\"11\" fill=\"#ffffff\">$(_xml(rows[index].selected_library))</text>")
        end
    end
    for capacity in sort(unique(row.capacity for row in capacity_rows))
        xx = _sx(capacity, x_min, x_max, plot_x, plot_width)
        println(io, "<line x1=\"$xx\" y1=\"$(plot_y - 4)\" x2=\"$xx\" y2=\"$(plot_y + 6 * row_height - 14)\" stroke=\"#ffffff\" stroke-opacity=\"0.5\"/>")
        println(io, "<text x=\"$xx\" y=\"$(plot_y + 6 * row_height + 5)\" text-anchor=\"middle\" class=\"axis\">$(_ratio(capacity))</text>")
    end
    println(io, "<text x=\"$(plot_x + plot_width / 2)\" y=\"405\" text-anchor=\"middle\" class=\"axis\">Total capacity B</text>")
    return _svg_footer(io)
end

function _render_switching_figure(penalized_rows)
    finite_upper = ExactRational[
        row.upper_price for row in penalized_rows if !isnothing(row.upper_price)
    ]
    x_max = isempty(finite_upper) ? one(ExactRational) : maximum(finite_upper) * 5 // 4 + 1 // 4
    io = IOBuffer()
    width, height = 980, 450
    _svg_header(io, width, height, "Exact penalized-library switching diagram", "Colored intervals show the right-continuous minimum-burden selection. Dots label globally active exact breakpoints; all candidate intersections are in the switching-price CSV.")
    println(io, "<text x=\"55\" y=\"35\" class=\"title\">Switching diagram</text>")
    println(io, "<text x=\"55\" y=\"55\" class=\"subtitle\">Actual envelope switches only; exact candidate and active prices are reported separately.</text>")
    plot_x, plot_y, plot_width = 250, 85, 680
    row_height = 45
    row_index = 0
    for schedule in SCHEDULE_ORDER, belief in ("low", "high")
        row_index += 1
        y = plot_y + (row_index - 1) * row_height
        rows = [
            row for row in penalized_rows if row.schedule == schedule &&
            row.belief == belief && row.cell_kind != "breakpoint"
        ]
        sort!(rows; by = row -> row.lower_price)
        println(io, "<text x=\"235\" y=\"$(y + 18)\" text-anchor=\"end\" class=\"label\">$(_xml(replace(schedule, "_" => " "))) · $belief</text>")
        for row in rows
            left = row.lower_price
            right = isnothing(row.upper_price) ? x_max : row.upper_price
            right = min(right, x_max)
            left > x_max && continue
            xx = _sx(left, 0, x_max, plot_x, plot_width)
            segment_width = _sx(right, 0, x_max, plot_x, plot_width) - xx
            println(io, "<rect x=\"$xx\" y=\"$y\" width=\"$segment_width\" height=\"28\" fill=\"$(_library_color(row.selected_mask))\" stroke=\"#ffffff\"><title>$(_xml("λ∈($(_ratio(left)),$(isnothing(row.upper_price) ? "∞" : _ratio(row.upper_price))): $(row.optimal_libraries)"))</title></rect>")
            segment_width > 42 && println(io, "<text x=\"$(xx + segment_width / 2)\" y=\"$(y + 19)\" text-anchor=\"middle\" font-size=\"11\" fill=\"#ffffff\">$(_xml(row.selected_library))</text>")
        end
        breakpoints = [
            row for row in penalized_rows if row.schedule == schedule &&
            row.belief == belief && row.cell_kind == "breakpoint"
        ]
        for row in breakpoints
            row.probe_price > x_max && continue
            xx = _sx(row.probe_price, 0, x_max, plot_x, plot_width)
            println(io, "<circle cx=\"$xx\" cy=\"$(y + 14)\" r=\"4\" fill=\"$NAVY\"><title>$(_xml("λ=$(_ratio(row.probe_price)): $(row.optimal_libraries)"))</title></circle>")
        end
    end
    exact_ticks = sort(unique(
        row.probe_price for row in penalized_rows if row.cell_kind == "breakpoint"
    ))
    for price in exact_ticks
        price > x_max && continue
        xx = _sx(price, 0, x_max, plot_x, plot_width)
        tick_y = plot_y + 6 * row_height + 18
        println(io, "<text x=\"$xx\" y=\"$tick_y\" text-anchor=\"end\" class=\"axis\" transform=\"rotate(-32 $xx $tick_y)\">$(_ratio(price))</text>")
    end
    println(io, "<text x=\"$(plot_x + plot_width / 2)\" y=\"425\" text-anchor=\"middle\" class=\"axis\">Resource price λ</text>")
    return _svg_footer(io)
end

function _render_summary(experiment)
    actual_switches = count(row -> row.globally_active, experiment.switching_rows)
    summary = (
        schema_version = EXPERIMENT_ID,
        source_benchmark = experiment.config["source_benchmark"],
        selected_candidate = experiment.canonical.config["selected_candidate"],
        arithmetic_exact = "Rational{BigInt}",
        arithmetic_plotting = "Float64 derived from exact Rational{BigInt} rows",
        randomness = "none",
        weight_choice_timing = "preregistered in D-0131 before resource outputs",
        reference_schedule = experiment.config["reference_schedule"],
        schedules = [
            (
                id = schedule.id,
                label = schedule.label,
                inactive = schedule.inactive,
                carrier_a = schedule.weights[1],
                carrier_b = schedule.weights[2],
                descendant = schedule.weights[3],
            ) for schedule in experiment.schedules
        ],
        raw_library_count = length(MASKS),
        safe_compression_problem_count = length(experiment.safe_rows),
        capacity_problem_count = length(experiment.capacity_rows),
        penalized_cell_count = length(experiment.penalized_rows),
        pairwise_comparison_count = length(experiment.switching_rows),
        globally_active_pair_count = actual_switches,
        channel_row_count = length(experiment.channel_rows),
        exact_safe_all_optima_feasible = all(row.all_optima_feasible for row in experiment.safe_rows),
        exact_safe_productive_value_preserved = all(row.productive_value_preserved for row in experiment.safe_rows),
        exact_safe_never_raises_burden = all(row.burden_reduction >= 0 for row in experiment.safe_rows),
        exact_capacity_all_optima_feasible = all(row.all_optima_feasible for row in experiment.capacity_rows),
        exact_capacity_ties_complete = all(row.ties_complete for row in experiment.capacity_rows),
        exact_penalized_ties_complete = all(row.ties_complete for row in experiment.penalized_rows),
        exact_channel_identity = all(
            row.operational_value + row.generative_value == row.productive_value for
            row in experiment.channel_rows
        ),
        exact_duration_contribution_identity = all(
            row.operational_contribution + row.generative_contribution ==
            row.innovation_duration for row in experiment.channel_rows
        ),
        action_distance_metric = "half exact Q gap in l-infinity action-value space",
        library_distance_metric = "exact distance in lambda to nearest globally active breakpoint",
        plot_status = "secondary presentation only",
    )
    io = IOBuffer()
    Canonical._write_json(io, summary)
    println(io)
    return String(take!(io))
end

function run_unified_resource_benchmark(
    config_path::AbstractString = DEFAULT_CONFIG,
)
    config = TOML.parsefile(config_path)
    config["experiment_id"] == EXPERIMENT_ID ||
        error("unexpected unified resource experiment ID")
    config["randomness"] == "none" ||
        error("the unified resource benchmark must be deterministic")
    config["arithmetic_exact"] == "Rational{BigInt}" ||
        error("the theorem-facing resource arithmetic must remain exact")
    canonical_path = _absolute(config["source_benchmark"])
    canonical = Canonical.run_unified_canonical_benchmark(canonical_path)
    schedules = _schedule_rows(config)
    channel_rows = _channel_rows(canonical)
    problems = Dict{Tuple{String,String},Resource.ExactRetentionProblem}()
    for schedule in schedules, belief in ("low", "high")
        problems[(schedule.id, belief)] =
            _retention_problem(channel_rows, schedule, belief)
    end
    safe_rows = _safe_compression_rows(problems, schedules)
    library_rows = _library_rows(problems, schedules, channel_rows)
    capacity_rows = _capacity_rows(problems, schedules, channel_rows)
    switching_rows = _pairwise_switching_rows(problems, schedules)
    penalized_rows = _penalized_interval_rows(problems, schedules, channel_rows)
    return (;
        experiment_id = EXPERIMENT_ID,
        config_path = abspath(config_path),
        config,
        canonical,
        schedules,
        channel_rows,
        problems,
        safe_rows,
        library_rows,
        capacity_rows,
        switching_rows,
        penalized_rows,
    )
end

function _artifact_contents(experiment)
    outputs = experiment.config["outputs"]
    return Dict(
        outputs["summary"] => _render_summary(experiment),
        outputs["libraries"] => _render_libraries(experiment.library_rows),
        outputs["safe_compression"] => _render_safe_compression(experiment.safe_rows),
        outputs["capacity"] => _render_capacity(experiment.capacity_rows),
        outputs["penalized_intervals"] => _render_penalized(experiment.penalized_rows),
        outputs["switching_prices"] => _render_switching_prices(experiment.switching_rows),
        outputs["channel_elasticities"] => _render_channel_elasticities(experiment.channel_rows),
        outputs["channel_elasticities_tex"] => _render_channel_table(experiment.channel_rows),
        outputs["value_capacity_figure"] => _render_value_capacity_figure(experiment.capacity_rows),
        outputs["value_price_figure"] => _render_value_price_figure(
            experiment.problems,
            experiment.schedules,
            experiment.switching_rows,
        ),
        outputs["library_path_figure"] => _render_library_path_figure(experiment.capacity_rows),
        outputs["switching_figure"] => _render_switching_figure(experiment.penalized_rows),
    )
end

function _write_or_check(artifacts, check)
    for (relative_path, content) in sort(collect(artifacts); by = first)
        path = _absolute(relative_path)
        if check
            isfile(path) || error("missing unified resource artifact: $path")
            read(path, String) == content ||
                error("stale unified resource artifact: $path")
        else
            mkpath(dirname(path))
            write(path, content)
        end
    end
    return nothing
end

function main(args = ARGS)
    check = "--check" in args
    paths = filter(argument -> argument != "--check", args)
    length(paths) <= 1 ||
        error("usage: run_unified_resource_benchmark.jl [config] [--check]")
    config_path = isempty(paths) ? DEFAULT_CONFIG : only(paths)
    experiment = run_unified_resource_benchmark(config_path)
    _write_or_check(_artifact_contents(experiment), check)
    println(check ?
        "unified resource artifacts are current" :
        "wrote unified resource artifacts")
    println(
        "exact schedules ", length(experiment.schedules),
        "; safe problems ", length(experiment.safe_rows),
        "; capacity rows ", length(experiment.capacity_rows),
        "; penalized cells ", length(experiment.penalized_rows),
    )
    return experiment
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
