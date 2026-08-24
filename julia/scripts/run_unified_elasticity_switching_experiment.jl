module UnifiedElasticitySwitchingExperiment

using LinearAlgebra: I
using Printf
using SHA: sha256
using StrategyInnovation
using TOML

if !isdefined(Main, :UnifiedResourceBenchmark)
    Base.include(Main, joinpath(@__DIR__, "run_unified_resource_benchmark.jl"))
end

const ResourceBenchmark = Main.UnifiedResourceBenchmark
const Resource = Main.ResourceOptimization
const Canonical = ResourceBenchmark.Canonical

export main, run_unified_elasticity_switching_experiment

const EXPERIMENT_ID = "unified-elasticity-switching-v1"
const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "unified_elasticity_switching_v1.toml",
)
const SCHEDULE_ORDER = ["equal_active", "carrier_heavy", "descendant_heavy"]
const BELIEF_ORDER = ["low", "high"]
const BLUE = "#2f5d8a"
const GOLD = "#d39b2a"
const ORANGE = "#c65d32"
const OLIVE = "#6f7f3f"
const ROSE = "#ad5573"
const NAVY = "#172a3a"
const GRAY = "#66717e"
const LIGHT = "#e7edf2"
const SCHEDULE_COLOR = Dict(
    "equal_active" => BLUE,
    "carrier_heavy" => GOLD,
    "descendant_heavy" => ORANGE,
)
const SCHEDULE_DASH = Dict(
    "equal_active" => "",
    "carrier_heavy" => "9 5",
    "descendant_heavy" => "2 4",
)
const LOCKED_HASHES = Dict(
    "experiments/configs/unified_elasticity_switching_v1.toml" =>
        "1a6d6f1a41def79773751216101f17169f58bc928e2191ba8362715edcd9c3db",
    "experiments/configs/unified_canonical_resources.toml" =>
        "9a3899ae1baeecb023f4689b47db84a853e3c9ccc6f5fc7f281b1672162c17a1",
    "experiments/configs/unified_canonical_benchmark.toml" =>
        "8674f9136ce0b7a245de6665e46a8c9b3bc13e3472d2080af5089108a6d2e1c8",
    "experiments/configs/unified_comparative_statics.toml" =>
        "f1f1c9fe77e96ad0be5d16de9c2f79c9c2bbb99df27464cb97d4955a53033633",
    "BRIDGE_ELASTICITY_SPEC.md" =>
        "5253b0313c0e07f395291f46bf0443a234717a5483d5663139a20f3a11bda7ad",
    "julia/scripts/run_unified_resource_benchmark.jl" =>
        "6a03eb7690dd5f5366808564585568d6d5660b2214ee35bdecd847b35a20606b",
    "julia/src/ComparativeStatics.jl" =>
        "7790337981c1d80a021c433b67a90e4dcf8c73dbd928b5fa2c3effe4f47473dd",
)

_absolute(path) = isabspath(path) ? normpath(path) : normpath(joinpath(REPOSITORY_ROOT, path))
_ratio(value::Rational) = "$(numerator(value))//$(denominator(value))"
_optional_ratio(value) = isnothing(value) ? "" : _ratio(value)
_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

function _verify_design_lock(config)
    config["schema_version"] == EXPERIMENT_ID || error("unexpected elasticity experiment schema")
    config["registration_status"] == "locked_before_extension_outcomes" ||
        error("elasticity experiment is not preregistered")
    config["arithmetic_exact"] == "Rational{BigInt}" ||
        error("exact arithmetic registration changed")
    config["randomness"] == "none" || error("experiment must remain deterministic")
    all(values(config["gates"])) || error("every registered hard gate must remain enabled")
    lock_path = _absolute(config["design_lock"]["path"])
    isfile(lock_path) || error("elasticity experiment design lock is absent")
    lock_text = read(lock_path, String)
    for fragment in (
        "\"extension_outcomes_read_before_lock\": false",
        "\"outputs_absent_at_freeze\": true",
        "\"design_sha256\": \"$(LOCKED_HASHES["experiments/configs/unified_elasticity_switching_v1.toml"])\"",
    )
        occursin(fragment, lock_text) || error("design lock is missing: $fragment")
    end
    for (relative, expected) in LOCKED_HASHES
        observed = _sha256_file(_absolute(relative))
        observed == expected || error("registered input drifted: $relative")
        occursin("\"$relative\": \"$expected\"", lock_text) ||
            error("design lock has no current hash for $relative")
    end
    return true
end

function _baseline_parameters(config)
    values = config["dynamic"]["baseline"]
    return UnifiedComparativeParameters(
        mode = ExactMode(),
        frontier_level = values["frontier_level"],
        frontier_density = values["frontier_density"],
        closure_richness = values["closure_richness"],
        module_overlap = values["module_overlap"],
        research_cost = values["research_cost"],
        research_duration = Int(values["research_duration"]),
        admission_probability = values["admission_probability"],
        candidate_survival = values["candidate_survival"],
        discount_factor = values["discount_factor"],
        belief_kernel_persistence = values["belief_kernel_persistence"],
        signal_precision_proxy = values["signal_precision_proxy"],
        candidate_profile_quality = values["candidate_profile_quality"],
        generator_frontier_dependence = values["generator_frontier_dependence"],
    )
end

function _dynamic_config(config)
    values = config["dynamic"]
    count = Int(values["belief_count"])
    return ComparativeStaticsConfig(
        mode = ExactMode(),
        belief_count = count,
        reference_index = 1,
        finite_horizon = Int(values["finite_horizon"]),
        value_tolerance = 0,
        residual_gate = 0,
        error_gate = 0,
        max_iterations = Int(values["max_iterations"]),
        frontier_step = 1 // 4,
        closure_step = 1 // 4,
        parameter_step = 1 // 10,
        operates_during_research = Bool(values["operates_during_research"]),
    )
end

function _bridge_rows(config)
    bridge = config["bridge"]
    gross = exact_rational(bridge["gross_descendant_value"])
    margins = exact_rational.(String.(bridge["normalized_margins"]))
    durations = Int.(bridge["durations"])
    gross > 0 || error("bridge gross value must be positive")
    all(0 .< margins .<= 1) || error("registered bridge margins left (0,1]")
    rows = NamedTuple[]
    for duration in durations, normalized_margin in margins
        net_margin = gross * normalized_margin
        research_cost = gross - net_margin
        fragility = gross / net_margin
        discount_elasticity = exact_rational(duration) * fragility
        survival_elasticity = discount_elasticity
        admission_elasticity = fragility
        payoff_elasticity = fragility
        cost_elasticity = -research_cost / net_margin
        push!(
            rows,
            (;
                duration,
                gross_descendant_value = gross,
                normalized_margin,
                net_innovation_margin = net_margin,
                research_cost,
                margin_fragility = fragility,
                discount_elasticity,
                survival_elasticity,
                admission_elasticity,
                descendant_payoff_elasticity = payoff_elasticity,
                research_cost_elasticity = cost_elasticity,
                absolute_research_cost_elasticity = abs(cost_elasticity),
                discount_identity = discount_elasticity == duration / normalized_margin,
                survival_identity = survival_elasticity == duration / normalized_margin,
                admission_identity = admission_elasticity == 1 / normalized_margin,
                payoff_identity = payoff_elasticity == 1 / normalized_margin,
                cost_identity = cost_elasticity == -(1 - normalized_margin) / normalized_margin,
            ),
        )
    end
    return rows
end

function _reward_discount_derivative(process, belief, state, action)
    action isa ContinueAction && return zero(ExactRational)
    project = only(row for row in process.projects if row.id == action.project)
    project.operates_during_research || return zero(ExactRational)
    law = process.completion(project, belief, state)
    beta = process.discount
    derivative = zero(ExactRational)
    for (outcome, mass) in zip(law.outcomes, law.probabilities)
        path_derivative = sum(
            exact_rational(time) * beta^(time - 1) *
            state.frontier[outcome.path[time + 1]] for
            time in 1:(project.duration - 1);
            init = zero(ExactRational),
        )
        derivative += mass * path_derivative
    end
    return derivative
end

function _fixed_policy_discount_system(process, result)
    states = result.states
    indices = Dict(state => index for (index, state) in enumerate(states))
    count = length(states)
    rewards = zeros(ExactRational, count)
    reward_derivatives = zeros(ExactRational, count)
    transitions = zeros(ExactRational, count, count)
    transition_derivatives = zeros(ExactRational, count, count)
    for index in eachindex(states)
        belief, state = states[index]
        action = result.policy[index]
        embedded = compressed_embedded_transition(process, belief, state, action)
        rewards[index] = expectation(embedded, outcome -> outcome.reward)
        reward_derivatives[index] =
            _reward_discount_derivative(process, belief, state, action)
        for (outcome, mass) in zip(embedded.outcomes, embedded.probabilities)
            next_index = indices[(outcome.next_state.belief, outcome.next_state.state)]
            duration = outcome.holding_time
            transitions[index, next_index] += process.discount^duration * mass
            transition_derivatives[index, next_index] +=
                exact_rational(duration) * process.discount^(duration - 1) * mass
        end
    end
    system = Matrix{ExactRational}(I, count, count) - transitions
    reconstructed = system \ rewards
    reconstructed == result.values ||
        error("fixed-policy exact value reconstruction failed")
    derivatives = system \ (reward_derivatives + transition_derivatives * result.values)
    derivative_residual = maximum(
        abs.(system * derivatives -
             (reward_derivatives + transition_derivatives * result.values));
        init = zero(ExactRational),
    )
    derivative_residual == 0 || error("fixed-policy derivative system has nonzero residual")
    return (; derivatives, derivative_residual, reconstructed)
end

function _passive_values_and_derivatives(process, state)
    beliefs = collect(process.belief_kernel.space)
    count = length(beliefs)
    transition = ExactRational[
        transition_probability(process.belief_kernel, belief, next) for
        belief in beliefs, next in beliefs
    ]
    reward = ExactRational[state.frontier[belief] for belief in beliefs]
    system = Matrix{ExactRational}(I, count, count) - process.discount * transition
    values = system \ reward
    derivatives = system \ (transition * values)
    residual = maximum(abs.(system * derivatives - transition * values); init = zero(ExactRational))
    residual == 0 || error("passive derivative system has nonzero residual")
    return (; beliefs, values, derivatives, residual)
end

function _embedded_q(process, result, indices, belief, state, action)
    embedded = compressed_embedded_transition(process, belief, state, action)
    reward = expectation(embedded, outcome -> outcome.reward)
    continuation = sum(
        mass * process.discount^outcome.holding_time *
        result.values[indices[(outcome.next_state.belief, outcome.next_state.state)]] for
        (outcome, mass) in zip(embedded.outcomes, embedded.probabilities);
        init = zero(ExactRational),
    )
    return reward + continuation
end

function _action_details(process, result, belief, state)
    indices = Dict(row => index for (index, row) in enumerate(result.states))
    state_index = indices[(belief, state)]
    selected = result.policy[state_index]
    actions = collect(unified_available_actions(process, state))
    values = [(action = action, value = _embedded_q(
        process, result, indices, belief, state, action,
    )) for action in actions]
    selected_value = only(row.value for row in values if row.action == selected)
    best_value = maximum(row.value for row in values)
    selected_value == best_value || error("policy action is not Bellman optimal")
    alternatives = [row for row in values if row.action != selected]
    if isempty(alternatives)
        return (
            action = action_label(selected),
            alternate_action = nothing,
            winning_q = selected_value,
            alternate_q = nothing,
            action_margin = nothing,
            action_tie_distance_linf = nothing,
        )
    end
    alternate = first(sort(alternatives; by = row -> (-row.value, action_label(row.action))))
    margin = selected_value - alternate.value
    margin >= 0 || error("negative Bellman action margin")
    return (
        action = action_label(selected),
        alternate_action = action_label(alternate.action),
        winning_q = selected_value,
        alternate_q = alternate.value,
        action_margin = margin,
        action_tie_distance_linf = margin / 2,
    )
end

function _solve_dynamic(parameters, solver)
    bundle = build_exact_comparative_process(parameters, solver)
    process = bundle.process
    result = compressed_infinite_horizon_policy_iteration(
        process;
        max_iterations = solver.max_iterations,
    )
    result.converged || error("exact compressed policy iteration did not converge")
    result.policy_equation_residual == 0 || error("policy equation residual is nonzero")
    result.bellman_residual == 0 || error("Bellman residual is nonzero")
    derivative = _fixed_policy_discount_system(process, result)
    base_state = compressed_library_state(process.catalog, process.closure, bundle.base)
    passive = _passive_values_and_derivatives(process, base_state)
    coordinates = ExactRational[
        solver.belief_count == 1 ? zero(ExactRational) :
        exact_rational(index - 1) / exact_rational(solver.belief_count - 1) for
        index in 1:solver.belief_count
    ]
    rows = NamedTuple[]
    for (belief_index, belief) in enumerate(process.belief_kernel.space)
        state_index = findfirst(isequal((belief, base_state)), result.states)
        isnothing(state_index) && error("base compressed state is absent")
        total_value = result.values[state_index]
        total_derivative = derivative.derivatives[state_index]
        operational_value = passive.values[belief_index]
        operational_derivative = passive.derivatives[belief_index]
        generative_value = total_value - operational_value
        generative_derivative = total_derivative - operational_derivative
        beta = process.discount
        total_scaled = beta * total_derivative
        operational_scaled = beta * operational_derivative
        generative_scaled = beta * generative_derivative
        total_value > 0 || error("innovation duration requires a positive total value")
        action = _action_details(process, result, belief, base_state)
        push!(
            rows,
            (;
                belief_index,
                belief_coordinate = coordinates[belief_index],
                total_value,
                operational_value,
                generative_value,
                total_discount_derivative = total_derivative,
                operational_discount_derivative = operational_derivative,
                generative_discount_derivative = generative_derivative,
                total_scaled_sensitivity = total_scaled,
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
                policy_iterations = result.iterations,
                policy_equation_residual = result.policy_equation_residual,
                bellman_residual = result.bellman_residual,
                derivative_residual = derivative.derivative_residual,
                value_reconstruction_exact = derivative.reconstructed == result.values,
                channel_identity_exact = operational_value + generative_value == total_value,
                sensitivity_identity_exact =
                    operational_scaled + generative_scaled == total_scaled,
            ),
        )
    end
    return rows
end

function _duration_rows(config, baseline, solver)
    rows = NamedTuple[]
    for duration in Int.(config["duration"]["grid"])
        parameters = with_comparative_parameter(baseline, :research_duration, duration)
        append!(rows, [merge(row, (; research_duration = duration)) for row in _solve_dynamic(parameters, solver)])
    end
    step = exact_rational(1) / exact_rational(solver.belief_count - 1)
    enriched = NamedTuple[]
    for row in rows
        group = sort(
            [candidate for candidate in rows if candidate.research_duration == row.research_duration];
            by = candidate -> candidate.belief_index,
        )
        if row.belief_index in (1, solver.belief_count)
            second_difference = nothing
            scaled_curvature = nothing
            convexity = "boundary"
        else
            left = group[row.belief_index - 1].innovation_duration
            center = group[row.belief_index].innovation_duration
            right = group[row.belief_index + 1].innovation_duration
            second_difference = right - 2 * center + left
            scaled_curvature = second_difference / step^2
            convexity = second_difference > 0 ? "convex" :
                        second_difference < 0 ? "concave" : "locally_linear"
        end
        push!(enriched, merge(row, (; belief_second_difference = second_difference,
                                      scaled_belief_curvature = scaled_curvature,
                                      local_convexity = convexity)))
    end
    return enriched
end

function _robustness_parameters(config, baseline, parameter::String, registered_value)
    value = exact_rational(registered_value)
    if parameter == "descendant_payoff_scale"
        varied = with_comparative_parameter(
            baseline,
            :candidate_profile_quality,
            baseline.candidate_profile_quality * value,
        )
        return varied, varied.candidate_profile_quality
    end
    symbol = Symbol(parameter)
    varied = with_comparative_parameter(baseline, symbol, value)
    return varied, getfield(varied, symbol)
end

function _robustness_rows(config, baseline, solver)
    registration = config["robustness"]
    rows = NamedTuple[]
    for parameter in String.(registration["parameters"])
        for registered_value in String.(registration[parameter])
            varied, actual = _robustness_parameters(config, baseline, parameter, registered_value)
            solved = _solve_dynamic(varied, solver)
            append!(
                rows,
                [merge(
                    row,
                    (;
                        parameter,
                        registered_value = exact_rational(registered_value),
                        actual_parameter_value = actual,
                    ),
                ) for row in solved],
            )
        end
    end
    return rows
end

function _resource_penalized_rows(resource)
    rows = NamedTuple[]
    for row in resource.penalized_rows
        channel = only(
            candidate for candidate in resource.channel_rows if
            candidate.belief == row.belief && candidate.mask == row.selected_mask
        )
        push!(
            rows,
            merge(
                row,
                (;
                    selected_action = channel.action,
                    selected_alternate_action = channel.second_action,
                    selected_action_margin = channel.action_margin,
                    selected_action_tie_distance_linf = channel.action_tie_distance_linf,
                ),
            ),
        )
    end
    return rows
end

function _bellman_rows(duration_rows, robustness_rows, resource)
    rows = NamedTuple[]
    empty_row = (
        source = "",
        row_kind = "",
        parameter = "",
        schedule = "",
        belief = "",
        belief_coordinate = nothing,
        library_mask = nothing,
        library = "",
        registered_value = nothing,
        actual_parameter_value = nothing,
        lower_value = nothing,
        upper_value = nothing,
        action = "",
        alternate_action = "",
        upper_endpoint_action = "",
        winning_q = nothing,
        alternate_q = nothing,
        action_margin = nothing,
        action_tie_distance_linf = nothing,
        exact_coordinate = true,
        bellman_residual = nothing,
    )
    for row in duration_rows
        push!(rows, merge(empty_row, (;
            source = "duration_surface",
            row_kind = "q_gap",
            parameter = "research_duration",
            belief = string(row.belief_index),
            belief_coordinate = row.belief_coordinate,
            registered_value = exact_rational(row.research_duration),
            actual_parameter_value = exact_rational(row.research_duration),
            action = row.action,
            alternate_action = isnothing(row.alternate_action) ? "" : row.alternate_action,
            winning_q = row.winning_q,
            alternate_q = row.alternate_q,
            action_margin = row.action_margin,
            action_tie_distance_linf = row.action_tie_distance_linf,
            bellman_residual = row.bellman_residual,
        )))
    end
    for row in robustness_rows
        push!(rows, merge(empty_row, (;
            source = "robustness_surface",
            row_kind = "q_gap",
            parameter = row.parameter,
            belief = string(row.belief_index),
            belief_coordinate = row.belief_coordinate,
            registered_value = row.registered_value,
            actual_parameter_value = row.actual_parameter_value,
            action = row.action,
            alternate_action = isnothing(row.alternate_action) ? "" : row.alternate_action,
            winning_q = row.winning_q,
            alternate_q = row.alternate_q,
            action_margin = row.action_margin,
            action_tie_distance_linf = row.action_tie_distance_linf,
            bellman_residual = row.bellman_residual,
        )))
    end
    for row in resource.channel_rows
        push!(rows, merge(empty_row, (;
            source = "resource_library",
            row_kind = "q_gap",
            parameter = "library",
            belief = row.belief,
            library_mask = Int(row.mask),
            library = row.library,
            registered_value = exact_rational(Int(row.mask)),
            actual_parameter_value = exact_rational(Int(row.mask)),
            action = row.action,
            alternate_action = row.second_action,
            action_margin = row.action_margin,
            action_tie_distance_linf = row.action_tie_distance_linf,
            bellman_residual = zero(ExactRational),
        )))
    end

    function add_brackets!(source_rows, parameter_names)
        for parameter in parameter_names
            parameter_rows = [row for row in source_rows if
                              (hasproperty(row, :parameter) ? row.parameter : "research_duration") == parameter]
            for belief_index in sort(unique(row.belief_index for row in parameter_rows))
                group = sort(
                    [row for row in parameter_rows if row.belief_index == belief_index];
                    by = row -> hasproperty(row, :registered_value) ?
                        row.registered_value : exact_rational(row.research_duration),
                )
                for index in 1:(length(group) - 1)
                    left, right = group[index], group[index + 1]
                    left.action == right.action && continue
                    lower = hasproperty(left, :registered_value) ?
                            left.registered_value : exact_rational(left.research_duration)
                    upper = hasproperty(right, :registered_value) ?
                            right.registered_value : exact_rational(right.research_duration)
                    push!(rows, merge(empty_row, (;
                        source = "registered_parameter_grid",
                        row_kind = "registered_parameter_bracket",
                        parameter,
                        belief = string(belief_index),
                        belief_coordinate = left.belief_coordinate,
                        lower_value = lower,
                        upper_value = upper,
                        action = left.action,
                        upper_endpoint_action = right.action,
                        exact_coordinate = false,
                    )))
                end
            end
        end
    end
    add_brackets!(duration_rows, ["research_duration"])
    add_brackets!(robustness_rows, sort(unique(row.parameter for row in robustness_rows)))
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

const DYNAMIC_COLUMNS = (
    :belief_index, :belief_coordinate, :total_value, :operational_value,
    :generative_value, :total_discount_derivative, :operational_discount_derivative,
    :generative_discount_derivative, :total_scaled_sensitivity,
    :operational_scaled_sensitivity, :generative_scaled_sensitivity,
    :innovation_duration, :operational_elasticity, :generative_elasticity,
    :operational_contribution, :generative_contribution, :action,
    :alternate_action, :winning_q, :alternate_q, :action_margin,
    :action_tie_distance_linf, :policy_iterations, :policy_equation_residual,
    :bellman_residual, :derivative_residual, :value_reconstruction_exact,
    :channel_identity_exact, :sensitivity_identity_exact,
)

function _render_bridge(rows)
    return _csv(rows, (
        :duration, :gross_descendant_value, :normalized_margin,
        :net_innovation_margin, :research_cost, :margin_fragility,
        :discount_elasticity, :survival_elasticity, :admission_elasticity,
        :descendant_payoff_elasticity, :research_cost_elasticity,
        :absolute_research_cost_elasticity, :discount_identity,
        :survival_identity, :admission_identity, :payoff_identity, :cost_identity,
    ))
end

function _render_duration(rows)
    return _csv(rows, (
        :research_duration, DYNAMIC_COLUMNS...,
        :belief_second_difference, :scaled_belief_curvature, :local_convexity,
    ))
end

function _render_robustness(rows)
    return _csv(rows, (
        :parameter, :registered_value, :actual_parameter_value, DYNAMIC_COLUMNS...,
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
        :action_tie_distance_linf, :selected_action, :selected_alternate_action,
        :selected_action_margin, :selected_action_tie_distance_linf,
        :enumerated_count, :ties_complete,
    ))
end

function _render_bellman(rows)
    return _csv(rows, propertynames(first(rows)))
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

function _svg_header(io, width, height, title, description, sources)
    println(io, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\" viewBox=\"0 0 $width $height\" role=\"img\" aria-labelledby=\"title desc\">")
    println(io, "<title id=\"title\">$(_xml(title))</title>")
    println(io, "<desc id=\"desc\">$(_xml(description))</desc>")
    println(io, "<metadata data-experiment=\"$EXPERIMENT_ID\" data-sources=\"$(_xml(join(sources, ";")))\">Exact Rational{BigInt} source rows; Float64 coordinates are secondary.</metadata>")
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

function _draw_axes(io, x, y, width, height, x_min, x_max, y_min, y_max, title)
    println(io, "<text x=\"$x\" y=\"$(y - 10)\" class=\"label\" font-weight=\"600\">$(_xml(title))</text>")
    println(io, "<line x1=\"$x\" y1=\"$(y + height)\" x2=\"$(x + width)\" y2=\"$(y + height)\" stroke=\"$GRAY\"/>")
    println(io, "<line x1=\"$x\" y1=\"$y\" x2=\"$x\" y2=\"$(y + height)\" stroke=\"$GRAY\"/>")
    for index in 0:4
        fraction = index / 4
        xx = x + width * fraction
        yy = y + height * fraction
        xv = Float64(x_min) + fraction * (Float64(x_max) - Float64(x_min))
        yv = Float64(y_max) - fraction * (Float64(y_max) - Float64(y_min))
        println(io, "<line x1=\"$xx\" y1=\"$y\" x2=\"$xx\" y2=\"$(y + height)\" stroke=\"$LIGHT\"/>")
        println(io, "<line x1=\"$x\" y1=\"$yy\" x2=\"$(x + width)\" y2=\"$yy\" stroke=\"$LIGHT\"/>")
        println(io, "<text x=\"$xx\" y=\"$(y + height + 16)\" text-anchor=\"middle\" class=\"axis\">$(@sprintf("%.2g", xv))</text>")
        println(io, "<text x=\"$(x - 7)\" y=\"$(yy + 4)\" text-anchor=\"end\" class=\"axis\">$(@sprintf("%.2g", yv))</text>")
    end
end

function _render_margin_elasticity_figure(rows, config)
    duration = Int(config["bridge"]["figure_reference_duration"])
    selected = sort([row for row in rows if row.duration == duration]; by = row -> row.net_innovation_margin)
    curves = [
        (field = :discount_elasticity, label = "discount / survival", color = BLUE, dash = ""),
        (field = :admission_elasticity, label = "admission / payoff", color = GOLD, dash = "9 5"),
        (field = :absolute_research_cost_elasticity, label = "|research-cost elasticity|", color = ORANGE, dash = "2 4"),
    ]
    x_min = minimum(row.net_innovation_margin for row in selected)
    x_max = maximum(row.net_innovation_margin for row in selected)
    y_max = maximum(getproperty(row, curve.field) for row in selected for curve in curves)
    io = IOBuffer()
    _svg_header(io, 860, 500, "Net innovation margin and bridge elasticity",
        "Exact canonical bridge elasticities at registered duration three and gross descendant value one.",
        [config["outputs"]["bridge"]])
    println(io, "<text x=\"60\" y=\"38\" class=\"title\">Net innovation margin versus elasticity</text>")
    println(io, "<text x=\"60\" y=\"59\" class=\"subtitle\">A=1 and d=$duration; normalized margin m=M/A is the boundary coordinate.</text>")
    x, y, width, height = 80, 100, 650, 320
    _draw_axes(io, x, y, width, height, x_min, x_max, 0, y_max, "Exact bridge-margin elasticities")
    for curve in curves
        points = join((
            "$(_sx(row.net_innovation_margin, x_min, x_max, x, width)),$(_sy(getproperty(row, curve.field), 0, y_max, y, height))" for row in selected
        ), " ")
        println(io, "<polyline points=\"$points\" fill=\"none\" stroke=\"$(curve.color)\" stroke-width=\"2.8\" stroke-dasharray=\"$(curve.dash)\"/>")
        for row in selected
            xx = _sx(row.net_innovation_margin, x_min, x_max, x, width)
            value = getproperty(row, curve.field)
            yy = _sy(value, 0, y_max, y, height)
            println(io, "<circle cx=\"$xx\" cy=\"$yy\" r=\"3\" fill=\"$(curve.color)\"><title>$(_xml("$(curve.label): M=$(_ratio(row.net_innovation_margin)), elasticity=$(_ratio(value))"))</title></circle>")
        end
    end
    for (index, curve) in enumerate(curves)
        legend_x = 385 + (index - 1) * 155
        println(io, "<line x1=\"$legend_x\" y1=\"87\" x2=\"$(legend_x + 24)\" y2=\"87\" stroke=\"$(curve.color)\" stroke-width=\"2.8\" stroke-dasharray=\"$(curve.dash)\"/>")
        println(io, "<text x=\"$(legend_x + 29)\" y=\"91\" font-size=\"10\" fill=\"$(curve.color)\">$(_xml(curve.label))</text>")
    end
    println(io, "<text x=\"405\" y=\"474\" text-anchor=\"middle\" class=\"axis\">Positive net innovation margin M (gross value fixed at 1)</text>")
    println(io, "<text x=\"20\" y=\"260\" text-anchor=\"middle\" class=\"axis\" transform=\"rotate(-90 20 260)\">Absolute point elasticity</text>")
    return _svg_footer(io)
end

function _render_capacity_figure(rows, config)
    source = ResourceBenchmark._render_value_capacity_figure(rows)
    marker = "<metadata data-experiment=\"$EXPERIMENT_ID\" data-sources=\"$(_xml(config["outputs"]["capacity"]))\">Exact Rational{BigInt} source rows; Float64 coordinates are secondary.</metadata>"
    source = replace(source, "<title id=\"title\">" => marker * "<title id=\"title\">"; count = 1)
    return replace(source, "</svg>" => "<text x=\"18\" y=\"240\" text-anchor=\"middle\" class=\"axis\" transform=\"rotate(-90 18 240)\">Optimal productive value V*(B)</text>\n</svg>"; count = 1)
end

function _price_xmax(rows)
    prices = ExactRational[row.probe_price for row in rows if row.cell_kind == "breakpoint"]
    maximum_price = isempty(prices) ? one(ExactRational) : maximum(prices)
    return maximum_price * 5 // 4 + 1 // 4
end

function _render_penalized_envelope_figure(rows, config)
    x_max = _price_xmax(rows)
    segments = [row for row in rows if row.cell_kind != "breakpoint"]
    endpoint_values = ExactRational[]
    for row in segments
        right = isnothing(row.upper_price) ? x_max : min(row.upper_price, x_max)
        left = min(row.lower_price, x_max)
        push!(endpoint_values, row.productive_value - left * row.selected_burden)
        push!(endpoint_values, row.productive_value - right * row.selected_burden)
    end
    y_min, y_max = minimum(endpoint_values), maximum(endpoint_values)
    y_min == y_max && (y_max += 1)
    io = IOBuffer()
    _svg_header(io, 980, 470, "Penalized exact library envelope",
        "Exact active affine branches of max_L V(L)-lambda W(L), shown in two belief panels.",
        [config["outputs"]["penalized_path"]])
    println(io, "<text x=\"55\" y=\"35\" class=\"title\">Penalized piecewise-linear envelope</text>")
    println(io, "<text x=\"55\" y=\"55\" class=\"subtitle\">Exact branch intercepts and burdens; Float64 positions only.</text>")
    for (panel, belief) in enumerate(BELIEF_ORDER)
        x, y, width, height = 65 + (panel - 1) * 465, 100, 400, 285
        _draw_axes(io, x, y, width, height, 0, x_max, y_min, y_max, "Initial belief: $belief")
        for schedule in SCHEDULE_ORDER
            selected = sort([row for row in segments if row.schedule == schedule && row.belief == belief]; by = row -> row.lower_price)
            for row in selected
                left = row.lower_price
                left > x_max && continue
                right = isnothing(row.upper_price) ? x_max : min(row.upper_price, x_max)
                left_value = row.productive_value - left * row.selected_burden
                right_value = row.productive_value - right * row.selected_burden
                println(io, "<line x1=\"$(_sx(left, 0, x_max, x, width))\" y1=\"$(_sy(left_value, y_min, y_max, y, height))\" x2=\"$(_sx(right, 0, x_max, x, width))\" y2=\"$(_sy(right_value, y_min, y_max, y, height))\" stroke=\"$(SCHEDULE_COLOR[schedule])\" stroke-width=\"2.5\" stroke-dasharray=\"$(SCHEDULE_DASH[schedule])\"><title>$(_xml("$(schedule), $(belief), $(row.selected_library): V=$(_ratio(row.productive_value)), W=$(_ratio(row.selected_burden))"))</title></line>")
            end
        end
    end
    println(io, "<text x=\"490\" y=\"442\" text-anchor=\"middle\" class=\"axis\">Resource price lambda</text>")
    println(io, "<text x=\"18\" y=\"245\" text-anchor=\"middle\" class=\"axis\" transform=\"rotate(-90 18 245)\">Penalized value J(lambda)</text>")
    for (index, schedule) in enumerate(SCHEDULE_ORDER)
        x = 545 + (index - 1) * 138
        println(io, "<line x1=\"$x\" y1=\"55\" x2=\"$(x + 23)\" y2=\"55\" stroke=\"$(SCHEDULE_COLOR[schedule])\" stroke-width=\"3\" stroke-dasharray=\"$(SCHEDULE_DASH[schedule])\"/>")
        println(io, "<text x=\"$(x + 28)\" y=\"59\" class=\"small\">$(_xml(replace(schedule, "_" => " ")))</text>")
    end
    return _svg_footer(io)
end

function _render_selected_burden_figure(rows, config)
    x_max = _price_xmax(rows)
    segments = [row for row in rows if row.cell_kind != "breakpoint"]
    y_min = minimum(row.selected_burden for row in segments)
    y_max = maximum(row.selected_burden for row in segments)
    y_min == y_max && (y_max += 1)
    io = IOBuffer()
    _svg_header(io, 980, 470, "Selected burden along the exact penalty path",
        "Right-continuous minimum-burden selections from exact penalized optimizer correspondences.",
        [config["outputs"]["penalized_path"]])
    println(io, "<text x=\"55\" y=\"35\" class=\"title\">Selected burden versus resource price</text>")
    println(io, "<text x=\"55\" y=\"55\" class=\"subtitle\">Every path is weakly decreasing; breakpoint ties remain in the source table.</text>")
    for (panel, belief) in enumerate(BELIEF_ORDER)
        x, y, width, height = 65 + (panel - 1) * 465, 100, 400, 285
        _draw_axes(io, x, y, width, height, 0, x_max, y_min, y_max, "Initial belief: $belief")
        for schedule in SCHEDULE_ORDER
            selected = sort([row for row in segments if row.schedule == schedule && row.belief == belief]; by = row -> row.lower_price)
            for row in selected
                left = row.lower_price
                left > x_max && continue
                right = isnothing(row.upper_price) ? x_max : min(row.upper_price, x_max)
                yy = _sy(row.selected_burden, y_min, y_max, y, height)
                println(io, "<line x1=\"$(_sx(left, 0, x_max, x, width))\" y1=\"$yy\" x2=\"$(_sx(right, 0, x_max, x, width))\" y2=\"$yy\" stroke=\"$(SCHEDULE_COLOR[schedule])\" stroke-width=\"3\" stroke-dasharray=\"$(SCHEDULE_DASH[schedule])\"><title>$(_xml("$(schedule), $(belief): W=$(_ratio(row.selected_burden)), $(row.selected_library)"))</title></line>")
            end
        end
    end
    println(io, "<text x=\"490\" y=\"442\" text-anchor=\"middle\" class=\"axis\">Resource price lambda</text>")
    println(io, "<text x=\"18\" y=\"245\" text-anchor=\"middle\" class=\"axis\" transform=\"rotate(-90 18 245)\">Selected total burden W</text>")
    for (index, schedule) in enumerate(SCHEDULE_ORDER)
        legend_x = 550 + (index - 1) * 135
        println(io, "<line x1=\"$legend_x\" y1=\"55\" x2=\"$(legend_x + 22)\" y2=\"55\" stroke=\"$(SCHEDULE_COLOR[schedule])\" stroke-width=\"3\" stroke-dasharray=\"$(SCHEDULE_DASH[schedule])\"/>")
        println(io, "<text x=\"$(legend_x + 27)\" y=\"59\" class=\"small\">$(_xml(replace(schedule, "_" => " ")))</text>")
    end
    return _svg_footer(io)
end

function _duration_color(value, minimum_value, maximum_value)
    palette = ["#eef4f8", "#cedeea", "#9dbbd0", "#668eae", BLUE]
    minimum_value == maximum_value && return palette[3]
    fraction = clamp((Float64(value) - Float64(minimum_value)) /
                     (Float64(maximum_value) - Float64(minimum_value)), 0, 1)
    return palette[clamp(floor(Int, fraction * length(palette)) + 1, 1, length(palette))]
end

function _render_duration_heatmap(rows, config)
    values = ExactRational[row.innovation_duration for row in rows]
    minimum_value, maximum_value = minimum(values), maximum(values)
    io = IOBuffer()
    _svg_header(io, 900, 560, "Innovation duration across beliefs",
        "Exact fixed-policy discount elasticities for five beliefs and five registered research durations; symbols show local belief convexity.",
        [config["outputs"]["duration_convexity"]])
    println(io, "<text x=\"55\" y=\"38\" class=\"title\">Innovation duration and convexity across beliefs</text>")
    println(io, "<text x=\"55\" y=\"59\" class=\"subtitle\">Cell text is D_beta; convex (∪), concave (∩), and linear (=) symbols use exact second differences.</text>")
    plot_x, plot_y, cell_width, cell_height = 190, 105, 120, 72
    for belief_index in 1:5
        row = only(candidate for candidate in rows if candidate.research_duration == 1 && candidate.belief_index == belief_index)
        println(io, "<text x=\"$(plot_x + (belief_index - 0.5) * cell_width)\" y=\"92\" text-anchor=\"middle\" class=\"label\">b=$(_ratio(row.belief_coordinate))</text>")
    end
    for duration in 1:5
        println(io, "<text x=\"170\" y=\"$(plot_y + (duration - 0.5) * cell_height + 5)\" text-anchor=\"end\" class=\"label\">d=$duration</text>")
        for belief_index in 1:5
            row = only(candidate for candidate in rows if candidate.research_duration == duration && candidate.belief_index == belief_index)
            x = plot_x + (belief_index - 1) * cell_width
            y = plot_y + (duration - 1) * cell_height
            color = _duration_color(row.innovation_duration, minimum_value, maximum_value)
            symbol = row.local_convexity == "convex" ? "∪" :
                     row.local_convexity == "concave" ? "∩" :
                     row.local_convexity == "locally_linear" ? "=" : ""
            text_color = color == BLUE ? "#ffffff" : NAVY
            println(io, "<rect x=\"$x\" y=\"$y\" width=\"$cell_width\" height=\"$cell_height\" fill=\"$color\" stroke=\"#ffffff\"><title>$(_xml("d=$duration, b=$(_ratio(row.belief_coordinate)), D=$(_ratio(row.innovation_duration)), curvature=$(_optional_ratio(row.scaled_belief_curvature)), $(row.local_convexity)"))</title></rect>")
            println(io, "<text x=\"$(x + cell_width / 2)\" y=\"$(y + 33)\" text-anchor=\"middle\" font-size=\"13\" fill=\"$text_color\">$(@sprintf("%.3f", Float64(row.innovation_duration)))</text>")
            isempty(symbol) || println(io, "<text x=\"$(x + cell_width / 2)\" y=\"$(y + 53)\" text-anchor=\"middle\" font-size=\"10\" fill=\"$text_color\">$symbol</text>")
        end
    end
    println(io, "<text x=\"490\" y=\"505\" text-anchor=\"middle\" class=\"axis\">Belief coordinate</text>")
    println(io, "<text x=\"75\" y=\"285\" text-anchor=\"middle\" class=\"axis\" transform=\"rotate(-90 75 285)\">Research duration</text>")
    println(io, "<text x=\"190\" y=\"535\" class=\"small\">Exact rationals are in the CSV and every cell tooltip.</text>")
    return _svg_footer(io)
end

function _library_color(mask)
    mask == 0 && return "#c8d0d8"
    mask == 4 && return ORANGE
    mask in (1, 2, 3) && return BLUE
    mask in (5, 6) && return OLIVE
    return ROSE
end

function _action_glyph(action)
    startswith(action, "research") && return "R"
    return "C"
end

function _render_switching_map(rows, config)
    x_max = _price_xmax(rows)
    intervals = [row for row in rows if row.cell_kind != "breakpoint"]
    io = IOBuffer()
    _svg_header(io, 1000, 500, "Exact action and library switching map",
        "Library-price cells are exact; R and C report the Bellman action of the displayed selected library, with exact half-Q gaps in tooltips.",
        [config["outputs"]["penalized_path"], config["outputs"]["bellman_breakpoints"], config["outputs"]["library_breakpoints"]])
    println(io, "<text x=\"55\" y=\"35\" class=\"title\">Action and library switching map</text>")
    println(io, "<text x=\"55\" y=\"55\" class=\"subtitle\">R=research, C=continue; dots are globally active exact lambda switches.</text>")
    plot_x, plot_y, plot_width, row_height = 255, 88, 690, 52
    row_index = 0
    for schedule in SCHEDULE_ORDER, belief in BELIEF_ORDER
        row_index += 1
        y = plot_y + (row_index - 1) * row_height
        selected = sort([row for row in intervals if row.schedule == schedule && row.belief == belief]; by = row -> row.lower_price)
        println(io, "<text x=\"240\" y=\"$(y + 22)\" text-anchor=\"end\" class=\"label\">$(_xml(replace(schedule, "_" => " "))) · $belief</text>")
        for row in selected
            left = row.lower_price
            left > x_max && continue
            right = isnothing(row.upper_price) ? x_max : min(row.upper_price, x_max)
            x = _sx(left, 0, x_max, plot_x, plot_width)
            segment_width = _sx(right, 0, x_max, plot_x, plot_width) - x
            color = _library_color(row.selected_mask)
            glyph = _action_glyph(row.selected_action)
            println(io, "<rect x=\"$x\" y=\"$y\" width=\"$segment_width\" height=\"34\" fill=\"$color\" stroke=\"#ffffff\"><title>$(_xml("lambda in ($(_ratio(left)),$(isnothing(row.upper_price) ? "infinity" : _ratio(row.upper_price))): $(row.selected_library), action=$(row.selected_action), half-Q-gap=$(_ratio(row.selected_action_tie_distance_linf))"))</title></rect>")
            if segment_width > 45
                println(io, "<text x=\"$(x + segment_width / 2)\" y=\"$(y + 22)\" text-anchor=\"middle\" font-size=\"11\" fill=\"#ffffff\">$(_xml(row.selected_library)) · $glyph</text>")
            end
        end
        for row in rows
            row.schedule == schedule && row.belief == belief && row.cell_kind == "breakpoint" || continue
            row.probe_price > x_max && continue
            x = _sx(row.probe_price, 0, x_max, plot_x, plot_width)
            println(io, "<circle cx=\"$x\" cy=\"$(y + 17)\" r=\"4\" fill=\"$NAVY\"><title>$(_xml("exact library breakpoint lambda=$(_ratio(row.probe_price)); optimizers=$(row.optimal_libraries)"))</title></circle>")
        end
    end
    prices = sort(unique(row.probe_price for row in rows if row.cell_kind == "breakpoint"))
    for price in prices
        price > x_max && continue
        x = _sx(price, 0, x_max, plot_x, plot_width)
        y = plot_y + 6 * row_height + 12
        println(io, "<text x=\"$x\" y=\"$y\" text-anchor=\"end\" class=\"axis\" transform=\"rotate(-28 $x $y)\">$(_ratio(price))</text>")
    end
    println(io, "<text x=\"$(plot_x + plot_width / 2)\" y=\"475\" text-anchor=\"middle\" class=\"axis\">Resource price lambda</text>")
    return _svg_footer(io)
end

function _render_summary(experiment)
    gates = experiment.gates
    summary = (
        schema_version = EXPERIMENT_ID,
        registration_status = experiment.config["registration_status"],
        design_sha256 = LOCKED_HASHES["experiments/configs/unified_elasticity_switching_v1.toml"],
        arithmetic_exact = "Rational{BigInt}",
        arithmetic_plotting = "Float64 coordinates derived from exact rows",
        randomness = "none",
        theorem_evidence = false,
        bridge_rows = length(experiment.bridge_rows),
        duration_rows = length(experiment.duration_rows),
        channel_rows = length(experiment.resource.channel_rows),
        capacity_rows = length(experiment.resource.capacity_rows),
        penalized_rows = length(experiment.penalized_rows),
        library_breakpoint_rows = length(experiment.resource.switching_rows),
        bellman_rows = length(experiment.bellman_rows),
        robustness_rows = length(experiment.robustness_rows),
        registered_parameter_switch_brackets = count(row -> row.row_kind == "registered_parameter_bracket", experiment.bellman_rows),
        globally_active_library_pairs = count(row -> row.globally_active, experiment.resource.switching_rows),
        gates,
        bridge_boundary = "normalized margin m=M/A",
        innovation_duration = "beta times locally fixed-policy exact derivative divided by total value",
        bellman_breakpoint = "half exact Q gap in l-infinity action-value space",
        primitive_switch_boundary = "registered adjacent-value bracket only",
        plot_status = "secondary presentation from registered exact source tables",
    )
    io = IOBuffer()
    Canonical._write_json(io, summary)
    println(io)
    return String(take!(io))
end

function _resource_experiment(config)
    if isdefined(Main, :SELECTED_UNIFIED_RESOURCE_EXPERIMENT)
        selected = getfield(Main, :SELECTED_UNIFIED_RESOURCE_EXPERIMENT)
        selected.experiment_id == ResourceBenchmark.EXPERIMENT_ID ||
            error("cached resource experiment has the wrong ID")
        return selected
    end
    return ResourceBenchmark.run_unified_resource_benchmark(
        _absolute(config["source_resource_experiment"]),
    )
end

function _check_resource_paths(resource, penalized_rows)
    for schedule in resource.schedules, belief in BELIEF_ORDER
        capacity = sort(
            [row for row in resource.capacity_rows if row.schedule == schedule.id && row.belief == belief];
            by = row -> row.capacity,
        )
        issorted([row.optimal_objective for row in capacity]) ||
            error("capacity value is not weakly increasing")
        all(row.all_optima_feasible && row.ties_complete for row in capacity) ||
            error("capacity enumeration certificate failed")
        penalty = sort(
            [row for row in penalized_rows if row.schedule == schedule.id && row.belief == belief];
            by = row -> (row.probe_price, row.cell_kind == "breakpoint" ? 1 : 2),
        )
        burdens = ExactRational[row.selected_burden for row in penalty]
        all(burdens[index] >= burdens[index + 1] for index in 1:(length(burdens) - 1)) ||
            error("selected burden is not weakly decreasing in lambda")
        all(row.ties_complete && row.enumerated_count == 8 for row in penalty) ||
            error("penalized enumeration certificate failed")
    end
    return true
end

function run_unified_elasticity_switching_experiment(
    config_path::AbstractString = DEFAULT_CONFIG,
)
    config = TOML.parsefile(config_path)
    _verify_design_lock(config)
    baseline = _baseline_parameters(config)
    solver = _dynamic_config(config)
    expected_coordinates = exact_rational.(String.(config["duration"]["belief_coordinates"]))
    expected_coordinates == ExactRational[
        exact_rational(index - 1) / exact_rational(solver.belief_count - 1) for
        index in 1:solver.belief_count
    ] || error("registered belief coordinates and solver grid disagree")
    bridge_rows = _bridge_rows(config)
    duration_rows = _duration_rows(config, baseline, solver)
    robustness_rows = _robustness_rows(config, baseline, solver)
    resource = _resource_experiment(config)
    penalized_rows = _resource_penalized_rows(resource)
    bellman_rows = _bellman_rows(duration_rows, robustness_rows, resource)
    _check_resource_paths(resource, penalized_rows)

    gates = (
        design_lock_current = true,
        bridge_identities = all(
            row.discount_identity && row.survival_identity && row.admission_identity &&
            row.payoff_identity && row.cost_identity for row in bridge_rows
        ),
        duration_exact_systems = all(
            row.value_reconstruction_exact && row.policy_equation_residual == 0 &&
            row.bellman_residual == 0 && row.derivative_residual == 0 for row in duration_rows
        ),
        duration_channel_identities = all(
            row.channel_identity_exact && row.sensitivity_identity_exact &&
            row.operational_contribution + row.generative_contribution == row.innovation_duration for
            row in duration_rows
        ),
        robustness_exact_systems = all(
            row.value_reconstruction_exact && row.policy_equation_residual == 0 &&
            row.bellman_residual == 0 && row.derivative_residual == 0 for row in robustness_rows
        ),
        robustness_channel_identities = all(
            row.channel_identity_exact && row.sensitivity_identity_exact &&
            row.operational_contribution + row.generative_contribution == row.innovation_duration for
            row in robustness_rows
        ),
        resource_channel_identities = all(
            row.operational_value + row.generative_value == row.productive_value &&
            row.operational_contribution + row.generative_contribution == row.innovation_duration for
            row in resource.channel_rows
        ),
        capacity_and_penalty_paths = true,
        capacity_enumeration = all(
            row.all_optima_feasible && row.ties_complete && row.enumerated_count == 8 for
            row in resource.capacity_rows
        ),
        penalized_enumeration = all(
            row.ties_complete && row.enumerated_count == 8 for row in penalized_rows
        ),
        bellman_coordinates_labeled = all(
            row.row_kind != "registered_parameter_bracket" || !row.exact_coordinate for
            row in bellman_rows
        ),
    )
    all(values(gates)) || error("elasticity experiment hard gate failed: $gates")
    return (;
        experiment_id = EXPERIMENT_ID,
        config_path = abspath(config_path),
        config,
        baseline,
        solver,
        bridge_rows,
        duration_rows,
        robustness_rows,
        resource,
        penalized_rows,
        bellman_rows,
        gates,
    )
end

function _artifact_contents(experiment)
    outputs = experiment.config["outputs"]
    return Dict(
        outputs["bridge"] => _render_bridge(experiment.bridge_rows),
        outputs["duration_convexity"] => _render_duration(experiment.duration_rows),
        outputs["channel_contributions"] =>
            ResourceBenchmark._render_channel_elasticities(experiment.resource.channel_rows),
        outputs["capacity"] =>
            ResourceBenchmark._render_capacity(experiment.resource.capacity_rows),
        outputs["penalized_path"] => _render_penalized(experiment.penalized_rows),
        outputs["library_breakpoints"] =>
            ResourceBenchmark._render_switching_prices(experiment.resource.switching_rows),
        outputs["bellman_breakpoints"] => _render_bellman(experiment.bellman_rows),
        outputs["robustness"] => _render_robustness(experiment.robustness_rows),
        outputs["summary"] => _render_summary(experiment),
        outputs["margin_elasticity_figure"] =>
            _render_margin_elasticity_figure(experiment.bridge_rows, experiment.config),
        outputs["value_capacity_figure"] =>
            _render_capacity_figure(experiment.resource.capacity_rows, experiment.config),
        outputs["penalized_envelope_figure"] =>
            _render_penalized_envelope_figure(experiment.penalized_rows, experiment.config),
        outputs["selected_burden_figure"] =>
            _render_selected_burden_figure(experiment.penalized_rows, experiment.config),
        outputs["innovation_duration_figure"] =>
            _render_duration_heatmap(experiment.duration_rows, experiment.config),
        outputs["switching_map_figure"] =>
            _render_switching_map(experiment.penalized_rows, experiment.config),
    )
end

function _write_or_check(artifacts, check)
    for (relative_path, content) in sort(collect(artifacts); by = first)
        path = _absolute(relative_path)
        if check
            isfile(path) || error("missing elasticity experiment artifact: $path")
            read(path, String) == content || error("stale elasticity experiment artifact: $path")
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
        error("usage: run_unified_elasticity_switching_experiment.jl [config] [--check]")
    config_path = isempty(paths) ? DEFAULT_CONFIG : only(paths)
    experiment = run_unified_elasticity_switching_experiment(config_path)
    _write_or_check(_artifact_contents(experiment), check)
    println(check ? "elasticity and switching artifacts are current" :
            "wrote elasticity and switching artifacts")
    println(
        "exact bridge rows ", length(experiment.bridge_rows),
        "; duration rows ", length(experiment.duration_rows),
        "; robustness rows ", length(experiment.robustness_rows),
        "; Bellman rows ", length(experiment.bellman_rows),
    )
    return experiment
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
