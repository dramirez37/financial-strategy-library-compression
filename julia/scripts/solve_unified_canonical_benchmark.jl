module UnifiedCanonicalBenchmarkSolver

using LinearAlgebra: I
using Printf
using StrategyInnovation
using TOML

if !isdefined(Main, :UnifiedBenchmarkSearch)
    Base.include(Main, joinpath(@__DIR__, "search_unified_benchmark.jl"))
end
const BenchmarkSearch = Main.UnifiedBenchmarkSearch

export CompiledUnifiedAction,
       CompiledUnifiedModel,
       evaluate_stationary_policy,
       main,
       run_unified_canonical_benchmark,
       unified_bellman_residual,
       unified_bellman_step,
       unified_value_iteration

const EXPERIMENT_ID = "unified-canonical-benchmark-v1"
const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "unified_canonical_benchmark.toml",
)
const LOW = Belief(:low)
const HIGH = Belief(:high)

struct CompiledUnifiedAction{T<:Real}
    label::String
    holding_time::Int
    reward::T
    discounted_transition::Vector{T}
end

struct CompiledUnifiedModel{T<:Real}
    states::Vector{Tuple}
    actions::Vector{Vector{CompiledUnifiedAction{T}}}
    discount::T
end

struct UnifiedValueIterationRecord
    iteration::Int
    increment::Float64
    bellman_residual::Float64
    apriori_error_bound::Float64
    residual_error_bound::Float64
end

struct UnifiedValueIterationResult
    values::Vector{Float64}
    policy::Vector{String}
    converged::Bool
    iterations::Int
    increment::Float64
    bellman_residual::Float64
    residual_error_bound::Float64
    log::Vector{UnifiedValueIterationRecord}
end

_ratio(value::Rational) = "$(numerator(value))//$(denominator(value))"
_tex_ratio(value::Rational) = denominator(value) == 1 ?
                               string(numerator(value)) :
                               "\\frac{$(numerator(value))}{$(denominator(value))}"
_state_label(state) = BenchmarkSearch._state_label(state)
_state_order(state) = parse(Int, last(_state_label(state)))
_belief_label(belief) = string(belief.id)

function _library_label(process, library)
    ids = String[]
    for row in process.catalog.strategies
        row.id in library && push!(ids, string(row.id.id))
    end
    return join(ids, "|")
end

function _candidate_label(outcome)
    return is_failure(outcome) ? "failure" : string(outcome.strategy.id)
end

function _absolute(path)
    return isabspath(path) ? path : joinpath(REPOSITORY_ROOT, path)
end

function _selected_parameters(config)
    selected_path = _absolute(config["selected_configuration"])
    selected = TOML.parsefile(selected_path)
    selected["candidate_id"] == config["selected_candidate"] ||
        error("selected candidate and canonical configuration disagree")
    selected["experiment_id"] ==
        "unified-positive-duration-benchmark-search-v1" ||
        error("unexpected selected-search experiment")
    parameters = selected["parameters"]
    return BenchmarkSearch.UnifiedBenchmarkParameters(
        parameters["discount"],
        parameters["discover_cost_low"],
        parameters["discover_cost_high"],
        parameters["scale_cost"],
        parameters["scale_duration"],
        parameters["scale_admission"],
        parameters["survival"],
    )
end

function _ordered_states(process)
    return sort(collect(process.compressed_states); by = _state_order)
end

function _state_keys(process)
    return [
        (belief, state) for state in _ordered_states(process) for
        belief in process.belief_kernel.space
    ]
end

function _coerce(::Type{ExactRational}, value)
    return exact_rational(value)
end

function _coerce(::Type{Float64}, value)
    return Float64(value)
end

function _compile_unified_model(process, ::Type{T}) where {T<:Union{ExactRational,Float64}}
    states = _state_keys(process)
    indices = Dict(state => index for (index, state) in enumerate(states))
    action_rows = Vector{CompiledUnifiedAction{T}}[]
    for (belief, state) in states
        rows = CompiledUnifiedAction{T}[]
        for action in unified_available_actions(process, state)
            embedded = compressed_embedded_transition(
                process,
                belief,
                state,
                action,
            )
            reward = expectation(embedded, outcome -> outcome.reward)
            durations = unique(outcome.holding_time for outcome in embedded.outcomes)
            length(durations) == 1 ||
                error("an embedded action has multiple holding times")
            duration = only(durations)
            transition = zeros(T, length(states))
            for (outcome, mass) in
                zip(embedded.outcomes, embedded.probabilities)
                key = (
                    outcome.next_state.belief,
                    outcome.next_state.state,
                )
                transition[indices[key]] += _coerce(
                    T,
                    process.discount^outcome.holding_time * mass,
                )
            end
            push!(
                rows,
                CompiledUnifiedAction{T}(
                    action_label(action),
                    duration,
                    _coerce(T, reward),
                    transition,
                ),
            )
        end
        push!(action_rows, rows)
    end
    discount = _coerce(T, process.discount)
    all(
        sum(action.discounted_transition) <= discount for
        actions in action_rows for action in actions
    ) || error("compiled action exceeds the unified contraction modulus")
    return CompiledUnifiedModel{T}(states, action_rows, discount)
end

function _action_value(action::CompiledUnifiedAction, values)
    return action.reward + sum(
        action.discounted_transition .* values;
        init = zero(eltype(values)),
    )
end

function unified_bellman_step(model::CompiledUnifiedModel{T}, values) where {T}
    length(values) == length(model.states) ||
        throw(DimensionMismatch("unified value vector has the wrong length"))
    result = zeros(T, length(model.states))
    for index in eachindex(model.states)
        result[index] = maximum(
            _action_value(action, values) for action in model.actions[index]
        )
    end
    return result
end

function _greedy_policy(model::CompiledUnifiedModel, values)
    policy = String[]
    for index in eachindex(model.states)
        actions = model.actions[index]
        best = first(actions)
        best_value = _action_value(best, values)
        for action in Iterators.drop(actions, 1)
            candidate = _action_value(action, values)
            if candidate > best_value
                best = action
                best_value = candidate
            end
        end
        push!(policy, best.label)
    end
    return policy
end

function unified_bellman_residual(model::CompiledUnifiedModel, values)
    return maximum(
        abs.(unified_bellman_step(model, values) .- values);
        init = zero(eltype(values)),
    )
end

function unified_value_iteration(
    model::CompiledUnifiedModel{Float64};
    tolerance::Real = 1.0e-12,
    max_iterations::Integer = 10_000,
)
    tolerance > 0 || throw(ArgumentError("value-iteration tolerance must be positive"))
    max_iterations >= 1 ||
        throw(ArgumentError("value-iteration limit must be positive"))
    values = zeros(Float64, length(model.states))
    initial_increment = maximum(
        abs,
        unified_bellman_step(model, values) .- values;
        init = 0.0,
    )
    log = UnifiedValueIterationRecord[]
    for iteration in 1:max_iterations
        next_values = unified_bellman_step(model, values)
        increment = maximum(abs, next_values .- values; init = 0.0)
        residual = unified_bellman_residual(model, next_values)
        apriori = model.discount^iteration /
                   (1 - model.discount) * initial_increment
        posterior = residual / (1 - model.discount)
        push!(
            log,
            UnifiedValueIterationRecord(
                iteration,
                increment,
                residual,
                apriori,
                posterior,
            ),
        )
        values = next_values
        if increment <= tolerance
            return UnifiedValueIterationResult(
                values,
                _greedy_policy(model, values),
                true,
                iteration,
                increment,
                residual,
                posterior,
                log,
            )
        end
    end
    residual = unified_bellman_residual(model, values)
    return UnifiedValueIterationResult(
        values,
        _greedy_policy(model, values),
        false,
        Int(max_iterations),
        last(log).increment,
        residual,
        residual / (1 - model.discount),
        log,
    )
end

function evaluate_stationary_policy(
    model::CompiledUnifiedModel{T},
    policy::AbstractVector{<:AbstractString},
) where {T}
    length(policy) == length(model.states) ||
        throw(DimensionMismatch("stationary policy has the wrong length"))
    rewards = zeros(T, length(model.states))
    transitions = zeros(T, length(model.states), length(model.states))
    for index in eachindex(model.states)
        position = findfirst(
            action -> action.label == policy[index],
            model.actions[index],
        )
        isnothing(position) &&
            throw(ArgumentError("stationary policy selects an unavailable action"))
        action = model.actions[index][position]
        rewards[index] = action.reward
        transitions[index, :] = action.discounted_transition
    end
    values = (
        Matrix{T}(I, length(model.states), length(model.states)) -
        transitions
    ) \ rewards
    policy_residual = maximum(
        abs.(rewards + transitions * values - values);
        init = zero(T),
    )
    return (
        values,
        policy_residual,
        bellman_residual = unified_bellman_residual(model, values),
    )
end

function _exact_policy_vector(process, result, compiled)
    return [
        action_label(policy_action(result, belief, state)) for
        (belief, state) in compiled.states
    ]
end

function _projected_raw_embedded(process, belief, library, action)
    result = Dict{Tuple,ExactRational}()
    law = raw_embedded_transition(process, belief, library, action)
    for (outcome, mass) in zip(law.outcomes, law.probabilities)
        next_state = compressed_library_state(
            process.catalog,
            process.closure,
            outcome.next_state.library,
        )
        key = (
            outcome.holding_time,
            outcome.reward,
            outcome.next_state.belief,
            next_state,
        )
        result[key] = get(result, key, exact_rational(0)) + mass
    end
    return result
end

function _compressed_embedded(process, belief, state, action)
    result = Dict{Tuple,ExactRational}()
    law = compressed_embedded_transition(process, belief, state, action)
    for (outcome, mass) in zip(law.outcomes, law.probabilities)
        key = (
            outcome.holding_time,
            outcome.reward,
            outcome.next_state.belief,
            outcome.next_state.state,
        )
        result[key] = get(result, key, exact_rational(0)) + mass
    end
    return result
end

function _raw_compressed_audit(
    process,
    raw_stationary,
    compressed_stationary,
    horizon,
)
    transition_checks = 0
    finite_value_checks = 0
    finite_policy_checks = 0
    stationary_value_checks = 0
    policy_lift_checks = 0
    for library in process.raw_libraries, belief in process.belief_kernel.space
        state = compressed_library_state(
            process.catalog,
            process.closure,
            library,
        )
        for action in unified_available_actions(process, state)
            _projected_raw_embedded(process, belief, library, action) ==
                _compressed_embedded(process, belief, state, action) ||
                error("raw/compressed embedded transition mismatch")
            transition_checks += 1
        end
        for current_horizon in 0:horizon
            raw_finite_horizon_value(
                process,
                current_horizon,
                belief,
                library,
            ) == compressed_finite_horizon_value(
                process,
                current_horizon,
                belief,
                state,
            ) || error("raw/compressed finite-horizon value mismatch")
            finite_value_checks += 1
            if current_horizon > 0
                raw_finite_horizon_policy(
                    process,
                    current_horizon,
                    belief,
                    library,
                ) == compressed_finite_horizon_policy(
                    process,
                    current_horizon,
                    belief,
                    state,
                ) || error("raw/compressed finite-horizon policy mismatch")
                finite_policy_checks += 1
            end
        end
        state_value(raw_stationary, belief, library) ==
            state_value(compressed_stationary, belief, state) ||
            error("raw/compressed stationary value mismatch")
        stationary_value_checks += 1
        policy_action(raw_stationary, belief, library) ==
            policy_action(compressed_stationary, belief, state) ||
            error("stationary policy lift mismatch")
        policy_lift_checks += 1
    end
    return (;
        transition_checks,
        finite_value_checks,
        finite_policy_checks,
        stationary_value_checks,
        policy_lift_checks,
    )
end

function _value_rows(process, horizon, compressed, exact_evaluation, float, float_evaluation)
    rows = NamedTuple[]
    for current_horizon in 0:horizon,
        state in _ordered_states(process),
        belief in process.belief_kernel.space
        push!(
            rows,
            (
                solution = "finite_horizon_exact",
                horizon = string(current_horizon),
                arithmetic = "Rational{BigInt}",
                compressed_state = _state_label(state),
                belief = _belief_label(belief),
                value = _ratio(
                    compressed_finite_horizon_value(
                        process,
                        current_horizon,
                        belief,
                        state,
                    ),
                ),
            ),
        )
    end
    compiled = _compile_unified_model(process, ExactRational)
    for (index, (belief, state)) in enumerate(compiled.states)
        exact_value = state_value(compressed, belief, state)
        append!(
            rows,
            [
                (
                    solution = "stationary_exact_policy_iteration",
                    horizon = "",
                    arithmetic = "Rational{BigInt}",
                    compressed_state = _state_label(state),
                    belief = _belief_label(belief),
                    value = _ratio(exact_value),
                ),
                (
                    solution = "stationary_exact_policy_evaluation",
                    horizon = "",
                    arithmetic = "Rational{BigInt}",
                    compressed_state = _state_label(state),
                    belief = _belief_label(belief),
                    value = _ratio(exact_evaluation.values[index]),
                ),
                (
                    solution = "stationary_float64_value_iteration",
                    horizon = "",
                    arithmetic = "Float64",
                    compressed_state = _state_label(state),
                    belief = _belief_label(belief),
                    value = @sprintf("%.17g", float.values[index]),
                ),
                (
                    solution = "stationary_float64_policy_evaluation",
                    horizon = "",
                    arithmetic = "Float64",
                    compressed_state = _state_label(state),
                    belief = _belief_label(belief),
                    value = @sprintf(
                        "%.17g",
                        float_evaluation.values[index],
                    ),
                ),
            ],
        )
    end
    return rows
end

function _policy_rows(process, horizon, compressed, float_policy)
    rows = NamedTuple[]
    for current_horizon in 1:horizon,
        state in _ordered_states(process),
        belief in process.belief_kernel.space
        push!(
            rows,
            (
                solution = "finite_horizon_exact",
                horizon = string(current_horizon),
                compressed_state = _state_label(state),
                belief = _belief_label(belief),
                action = action_label(
                    compressed_finite_horizon_policy(
                        process,
                        current_horizon,
                        belief,
                        state,
                    ),
                ),
            ),
        )
    end
    compiled = _compile_unified_model(process, ExactRational)
    exact_policy = _exact_policy_vector(process, compressed, compiled)
    for (index, (belief, state)) in enumerate(compiled.states)
        push!(
            rows,
            (
                solution = "stationary_exact_policy_iteration",
                horizon = "",
                compressed_state = _state_label(state),
                belief = _belief_label(belief),
                action = exact_policy[index],
            ),
        )
        push!(
            rows,
            (
                solution = "stationary_float64_value_iteration",
                horizon = "",
                compressed_state = _state_label(state),
                belief = _belief_label(belief),
                action = float_policy[index],
            ),
        )
    end
    return rows
end

function _transition_rows(process)
    rows = NamedTuple[]
    for state in _ordered_states(process)
        push!(
            rows,
            (
                from_state = _state_label(state),
                to_state = _state_label(state),
                action = "continue",
                duration = 1,
                probability = exact_rational(1),
            ),
        )
        for project in process.projects
            project_available(process, state, project) || continue
            law = induced_compressed_transition(process, LOW, state, project)
            for (next_state, mass) in
                zip(law.outcomes, law.probabilities)
                iszero(mass) && continue
                push!(
                    rows,
                    (
                        from_state = _state_label(state),
                        to_state = _state_label(next_state),
                        action = string(project.id.id),
                        duration = project.duration,
                        probability = mass,
                    ),
                )
            end
        end
    end
    sort!(
        rows;
        by = row -> (
            parse(Int, last(row.from_state)),
            row.action,
            parse(Int, last(row.to_state)),
        ),
    )
    return rows
end

function _duration_path_rows(process)
    rows = NamedTuple[]
    for state in _ordered_states(process),
        belief in process.belief_kernel.space,
        project in process.projects
        project_available(process, state, project) || continue
        law = process.completion(project, belief, state)
        for (outcome, mass) in zip(law.outcomes, law.probabilities)
            path_mass = BenchmarkSearch._path_probability(
                process.belief_kernel,
                outcome.path,
            )
            push!(
                rows,
                (
                    project = string(project.id.id),
                    start_state = _state_label(state),
                    start_belief = _belief_label(belief),
                    duration = project.duration,
                    path = join(_belief_label.(outcome.path), ">"),
                    terminal_belief = _belief_label(terminal_belief(outcome)),
                    admitted = _candidate_label(outcome.admitted),
                    joint_mass = mass,
                    path_mass,
                    conditional_admission_mass = mass / path_mass,
                ),
            )
        end
    end
    return rows
end

function _operating_reward_rows(process)
    rows = NamedTuple[]
    for state in _ordered_states(process), belief in process.belief_kernel.space
        push!(
            rows,
            (
                compressed_state = _state_label(state),
                belief = _belief_label(belief),
                action = "continue",
                duration = 1,
                operates_during_research = false,
                initiation_cost = exact_rational(0),
                expected_incumbent_reward = state.frontier[belief],
                expected_net_reward_block = state.frontier[belief],
            ),
        )
        for project in process.projects
            project_available(process, state, project) || continue
            law = process.completion(project, belief, state)
            operating = expectation(
                law,
                outcome -> incumbent_reward(
                    process,
                    state,
                    project,
                    outcome.path,
                ),
            )
            cost = unified_research_cost(process, belief, state, project)
            push!(
                rows,
                (
                    compressed_state = _state_label(state),
                    belief = _belief_label(belief),
                    action = string(project.id.id),
                    duration = project.duration,
                    operates_during_research =
                        project.operates_during_research,
                    initiation_cost = cost,
                    expected_incumbent_reward = operating,
                    expected_net_reward_block = operating - cost,
                ),
            )
        end
    end
    return rows
end

function _comparative_parameters(parameters, config)
    table = config["comparative_statics"]
    replace(; kwargs...) = BenchmarkSearch._replace(parameters; kwargs...)
    return (
        cost_low = replace(scale_cost = exact_rational(table["cost_low"])),
        cost_high = replace(scale_cost = exact_rational(table["cost_high"])),
        duration_low = replace(scale_duration = table["duration_low"]),
        duration_high = replace(scale_duration = table["duration_high"]),
        discount_low = replace(discount = exact_rational(table["discount_low"])),
        discount_high = replace(discount = exact_rational(table["discount_high"])),
        admission_low =
            replace(scale_admission = exact_rational(table["admission_low"])),
        admission_high =
            replace(scale_admission = exact_rational(table["admission_high"])),
        survival_low = replace(survival = exact_rational(table["survival_low"])),
        survival_high = replace(survival = exact_rational(table["survival_high"])),
    )
end

function _comparative_rows(parameters, config, policy_iteration_limit)
    rows = NamedTuple[]
    for (scenario, scenario_parameters) in
        pairs(_comparative_parameters(parameters, config))
        fixture = BenchmarkSearch.build_unified_benchmark(
            scenario_parameters,
        )
        process = fixture.process
        result = compressed_infinite_horizon_policy_iteration(
            process;
            max_iterations = policy_iteration_limit,
        )
        result.converged && result.bellman_residual == 0 ||
            error("comparative-static policy iteration failed")
        axis, level = split(string(scenario), "_")
        parameter_value = if axis == "cost"
            scenario_parameters.scale_cost
        elseif axis == "duration"
            exact_rational(scenario_parameters.scale_duration)
        elseif axis == "discount"
            scenario_parameters.discount
        elseif axis == "admission"
            scenario_parameters.scale_admission
        else
            scenario_parameters.survival
        end
        k1 = only(
            state for state in process.compressed_states if
            _state_label(state) == "K1"
        )
        push!(
            rows,
            (
                axis,
                level,
                parameter_value,
                k1_low_value = state_value(result, LOW, k1),
                k1_high_value = state_value(result, HIGH, k1),
                k1_low_action = action_label(policy_action(result, LOW, k1)),
                k1_high_action = action_label(policy_action(result, HIGH, k1)),
            ),
        )
    end
    by_axis = Dict(
        axis => sort(
            [row for row in rows if row.axis == axis];
            by = row -> row.parameter_value,
        ) for axis in ("cost", "duration", "discount", "admission", "survival")
    )
    first(by_axis["cost"]).k1_low_value >
        last(by_axis["cost"]).k1_low_value ||
        error("cost comparative static is not visible")
    first(by_axis["duration"]).k1_low_value >
        last(by_axis["duration"]).k1_low_value ||
        error("duration comparative static is not visible")
    for axis in ("discount", "admission", "survival")
        first(by_axis[axis]).k1_low_value <
            last(by_axis[axis]).k1_low_value ||
            error("$axis comparative static is not visible")
    end
    return rows
end

function run_unified_canonical_benchmark(
    config_path::AbstractString = DEFAULT_CONFIG,
)
    config = TOML.parsefile(config_path)
    config["experiment_id"] == EXPERIMENT_ID ||
        error("unexpected unified canonical experiment ID")
    config["randomness"] == "none" ||
        error("the unified canonical benchmark must be deterministic")
    parameters = _selected_parameters(config)
    fixture = BenchmarkSearch.build_unified_benchmark(parameters)
    process = fixture.process
    solver = config["solver"]
    horizon = solver["finite_horizon"]
    policy_iteration_limit = solver["policy_iteration_limit"]

    raw_stationary = raw_infinite_horizon_policy_iteration(
        process;
        max_iterations = policy_iteration_limit,
    )
    compressed_stationary = compressed_infinite_horizon_policy_iteration(
        process;
        max_iterations = policy_iteration_limit,
    )
    raw_stationary.converged && compressed_stationary.converged ||
        error("exact unified policy iteration did not converge")
    raw_stationary.policy_equation_residual == 0 ||
        error("raw policy-equation residual is nonzero")
    compressed_stationary.policy_equation_residual == 0 ||
        error("compressed policy-equation residual is nonzero")
    raw_stationary.bellman_residual == 0 ||
        error("raw exact Bellman residual is nonzero")
    compressed_stationary.bellman_residual == 0 ||
        error("compressed exact Bellman residual is nonzero")

    exact_model = _compile_unified_model(process, ExactRational)
    exact_policy = _exact_policy_vector(
        process,
        compressed_stationary,
        exact_model,
    )
    exact_evaluation = evaluate_stationary_policy(
        exact_model,
        exact_policy,
    )
    exact_evaluation.policy_residual == 0 ||
        error("exact stationary policy evaluation has nonzero residual")
    exact_evaluation.bellman_residual == 0 ||
        error("exact stationary evaluated policy is not Bellman optimal")
    exact_values = ExactRational[
        state_value(compressed_stationary, belief, state) for
        (belief, state) in exact_model.states
    ]
    exact_evaluation.values == exact_values ||
        error("policy evaluation and policy iteration values disagree")
    exact_action_margins = ExactRational[]
    for index in eachindex(exact_model.states)
        action_values = sort(
            [
                _action_value(action, exact_values) for
                action in exact_model.actions[index]
            ];
            rev = true,
        )
        length(action_values) >= 2 ||
            error("every canonical state must have two available actions")
        push!(exact_action_margins, action_values[1] - action_values[2])
    end
    minimum(exact_action_margins) > 0 ||
        error("the exact canonical fixed point has an action tie")

    float_model = _compile_unified_model(process, Float64)
    float = unified_value_iteration(
        float_model;
        tolerance = solver["value_iteration_tolerance"],
        max_iterations = solver["value_iteration_limit"],
    )
    float.converged || error("Float64 unified value iteration did not converge")
    float.policy == exact_policy ||
        error("exact and Float64 stationary actions disagree")
    float_evaluation = evaluate_stationary_policy(float_model, float.policy)
    float_evaluation.bellman_residual <=
        128 * eps(maximum(abs, float_evaluation.values)) ||
        error("Float64 stationary policy evaluation is not Bellman optimal")
    float_error = maximum(
        abs.(Float64.(exact_values) .- float.values);
        init = 0.0,
    )
    float_values_as_exact = ExactRational[
        Rational{BigInt}(value) for value in float.values
    ]
    exact_float_residual = unified_bellman_residual(
        exact_model,
        float_values_as_exact,
    )
    exact_float_residual_bound =
        exact_float_residual / (1 - exact_model.discount)
    exact_float_error = maximum(
        abs.(exact_values .- float_values_as_exact);
        init = exact_rational(0),
    )
    exact_float_error <= exact_float_residual_bound ||
        error("Float64 values exceed the exactly re-evaluated residual-based certificate")

    correspondence = _raw_compressed_audit(
        process,
        raw_stationary,
        compressed_stationary,
        horizon,
    )
    value_rows = _value_rows(
        process,
        horizon,
        compressed_stationary,
        exact_evaluation,
        float,
        float_evaluation,
    )
    policy_rows = _policy_rows(
        process,
        horizon,
        compressed_stationary,
        float.policy,
    )
    transition_rows = _transition_rows(process)
    duration_path_rows = _duration_path_rows(process)
    operating_reward_rows = _operating_reward_rows(process)
    comparative_rows = _comparative_rows(
        parameters,
        config,
        policy_iteration_limit,
    )
    return (
        experiment_id = EXPERIMENT_ID,
        config_path = abspath(config_path),
        config,
        parameters,
        fixture,
        horizon,
        raw_stationary,
        compressed_stationary,
        exact_model,
        exact_policy,
        exact_values,
        exact_action_margins,
        exact_evaluation,
        float_model,
        float,
        float_evaluation,
        float_error,
        exact_float_residual,
        exact_float_residual_bound,
        exact_float_error,
        correspondence,
        value_rows,
        policy_rows,
        transition_rows,
        duration_path_rows,
        operating_reward_rows,
        comparative_rows,
    )
end

function _csv(rows, columns; encode = string)
    io = IOBuffer()
    println(io, join(string.(columns), ","))
    for row in rows
        values = String[]
        for column in columns
            value = getproperty(row, column)
            encoded = value isa Rational ? _ratio(value) : encode(value)
            occursin(',', encoded) &&
                error("canonical CSV fields may not contain commas")
            push!(values, encoded)
        end
        println(io, join(values, ","))
    end
    return String(take!(io))
end

function _render_values(experiment)
    return _csv(
        experiment.value_rows,
        (
            :solution,
            :horizon,
            :arithmetic,
            :compressed_state,
            :belief,
            :value,
        ),
    )
end

function _render_policies(experiment)
    return _csv(
        experiment.policy_rows,
        (
            :solution,
            :horizon,
            :compressed_state,
            :belief,
            :action,
        ),
    )
end

function _render_transition_edges(experiment)
    return _csv(
        experiment.transition_rows,
        (:from_state, :to_state, :action, :duration, :probability),
    )
end

function _edge_mass(rows, from, to, action)
    return only(
        row.probability for row in rows if
        row.from_state == from &&
        row.to_state == to &&
        row.action == action
    )
end

function _render_transition_diagram(experiment)
    rows = experiment.transition_rows
    discover_fail = _tex_ratio(_edge_mass(rows, "K0", "K0", "discover"))
    discover_success = _tex_ratio(_edge_mass(rows, "K0", "K1", "discover"))
    scale_fail = _tex_ratio(_edge_mass(rows, "K1", "K1", "scale"))
    scale_success = _tex_ratio(_edge_mass(rows, "K1", "K2", "scale"))
    return """% Generated by julia/scripts/solve_unified_canonical_benchmark.jl.
% Source: experiments/results/summaries/unified_canonical_transition_edges.csv.
\\begin{tikzpicture}[>=stealth,font=\\small]
  \\node[draw,rounded corners,align=center,minimum width=2.3cm] (k0) at (0,0)
    {\\(K_0\\)\\\\weak frontier\\\\capability missing};
  \\node[draw,rounded corners,align=center,minimum width=2.3cm] (k1) at (4,0)
    {\\(K_1\\)\\\\same frontier\\\\capability present};
  \\node[draw,rounded corners,align=center,minimum width=2.3cm] (k2) at (8,0)
    {\\(K_2\\)\\\\improved frontier\\\\capability retained};
  \\draw[->,blue!72!black,line width=1.0pt]
    (k0) to[bend left=12] node[above] {Discover \\($discover_success\\)} (k1);
  \\draw[->,orange!85!black,dashed,line width=1.0pt]
    (k1) to[bend left=12] node[above] {Scale \\($scale_success\\), \\(d=2\\)} (k2);
  \\draw[->,blue!72!black]
    (k0) edge[loop below] node {failure \\($discover_fail\\); Continue} (k0);
  \\draw[->,orange!85!black,dashed]
    (k1) edge[loop below] node {failure \\($scale_fail\\); Continue} (k1);
  \\draw[->,black!70]
    (k2) edge[loop below] node {Continue; repeat Scale} (k2);
\\end{tikzpicture}
"""
end

function _render_duration_paths(experiment)
    return _csv(
        experiment.duration_path_rows,
        (
            :project,
            :start_state,
            :start_belief,
            :duration,
            :path,
            :terminal_belief,
            :admitted,
            :joint_mass,
            :path_mass,
            :conditional_admission_mass,
        ),
    )
end

function _render_operating_rewards(experiment)
    return _csv(
        experiment.operating_reward_rows,
        (
            :compressed_state,
            :belief,
            :action,
            :duration,
            :operates_during_research,
            :initiation_cost,
            :expected_incumbent_reward,
            :expected_net_reward_block,
        ),
    )
end

function _render_convergence(experiment)
    rows = [
        (
            iteration = row.iteration,
            float64_iteration_increment = @sprintf("%.17g", row.increment),
            float64_bellman_residual = @sprintf("%.17g", row.bellman_residual),
            float64_apriori_contraction_bound =
                @sprintf("%.17g", row.apriori_error_bound),
            float64_aposteriori_contraction_bound =
                @sprintf("%.17g", row.residual_error_bound),
        ) for row in experiment.float.log
    ]
    return _csv(
        rows,
        (
            :iteration,
            :float64_iteration_increment,
            :float64_bellman_residual,
            :float64_apriori_contraction_bound,
            :float64_aposteriori_contraction_bound,
        ),
    )
end

function _render_comparatives(experiment)
    return _csv(
        experiment.comparative_rows,
        (
            :axis,
            :level,
            :parameter_value,
            :k1_low_value,
            :k1_high_value,
            :k1_low_action,
            :k1_high_action,
        ),
    )
end

function _json_escape(value)
    return replace(
        string(value),
        "\\" => "\\\\",
        "\"" => "\\\"",
        "\n" => "\\n",
    )
end

function _write_json(io, value, indent = 0)
    padding = " "^indent
    child = " "^(indent + 2)
    if value isa NamedTuple
        _write_json(
            io,
            Dict(string(key) => getproperty(value, key) for key in keys(value)),
            indent,
        )
    elseif value isa AbstractDict
        ordered = sort(collect(keys(value)); by = string)
        println(io, "{")
        for (index, key) in enumerate(ordered)
            print(io, child, "\"", _json_escape(key), "\": ")
            _write_json(io, value[key], indent + 2)
            index == length(ordered) || print(io, ",")
            println(io)
        end
        print(io, padding, "}")
    elseif value isa AbstractVector || value isa Tuple
        print(io, "[")
        for (index, item) in enumerate(value)
            index == 1 || print(io, ", ")
            _write_json(io, item, indent)
        end
        print(io, "]")
    elseif value isa Rational
        print(io, "\"", _ratio(value), "\"")
    elseif value isa AbstractString || value isa Symbol
        print(io, "\"", _json_escape(value), "\"")
    elseif value isa Bool
        print(io, value ? "true" : "false")
    elseif value isa Real
        print(io, repr(value))
    else
        error("unsupported canonical JSON value $(typeof(value))")
    end
end

function _render_summary(experiment)
    process = experiment.fixture.process
    parameters = experiment.parameters
    correspondence = experiment.correspondence
    summary = (
        schema_version = EXPERIMENT_ID,
        selected_candidate = experiment.config["selected_candidate"],
        arithmetic_exact = "Rational{BigInt}",
        arithmetic_numerical = "Float64 derived from exact embedded laws",
        randomness = "none",
        raw_strategy_count = length(process.catalog.strategies),
        raw_library_count = length(process.raw_libraries),
        compressed_state_count = length(process.compressed_states),
        joint_state_count =
            length(process.belief_kernel.space) *
            length(process.compressed_states),
        project_durations = [project.duration for project in process.projects],
        discount = parameters.discount,
        finite_horizon = experiment.horizon,
        exact_policy_iterations = experiment.compressed_stationary.iterations,
        exact_policy_equation_residual =
            experiment.compressed_stationary.policy_equation_residual,
        exact_bellman_residual =
            experiment.compressed_stationary.bellman_residual,
        exact_stationary_evaluation_residual =
            experiment.exact_evaluation.policy_residual,
        exact_minimum_action_gap = minimum(experiment.exact_action_margins),
        exact_action_ties = false,
        float64_iterations = experiment.float.iterations,
        float64_final_iteration_increment = experiment.float.increment,
        float64_bellman_residual = experiment.float.bellman_residual,
        float64_aposteriori_contraction_bound =
            experiment.float.residual_error_bound,
        exact_rationalized_float64_residual =
            experiment.exact_float_residual,
        exactly_reevaluated_residual_based_certificate =
            experiment.exact_float_residual_bound,
        float64_maximum_error_against_float64_rounded_exact_values =
            experiment.float_error,
        exact_rationalized_float64_maximum_error =
            experiment.exact_float_error,
        exact_rationalized_float64_error_within_reevaluated_certificate =
            experiment.exact_float_error <=
            experiment.exact_float_residual_bound,
        float64_actions_identical_to_exact =
            experiment.float.policy == experiment.exact_policy,
        raw_compressed_transition_checks =
            correspondence.transition_checks,
        raw_compressed_finite_value_checks =
            correspondence.finite_value_checks,
        raw_compressed_finite_policy_checks =
            correspondence.finite_policy_checks,
        raw_compressed_stationary_value_checks =
            correspondence.stationary_value_checks,
        lifted_stationary_policy_checks =
            correspondence.policy_lift_checks,
        legacy_main_artifact_source = false,
        legacy_regression_fixture =
            experiment.config["legacy_regression_fixture"],
    )
    io = IOBuffer()
    _write_json(io, summary)
    println(io)
    return String(take!(io))
end

function _artifact_contents(experiment)
    outputs = experiment.config["outputs"]
    return Dict(
        outputs["summary"] => _render_summary(experiment),
        outputs["values"] => _render_values(experiment),
        outputs["policies"] => _render_policies(experiment),
        outputs["transition_edges"] => _render_transition_edges(experiment),
        outputs["transition_diagram"] =>
            _render_transition_diagram(experiment),
        outputs["duration_paths"] => _render_duration_paths(experiment),
        outputs["operating_rewards"] =>
            _render_operating_rewards(experiment),
        outputs["convergence"] => _render_convergence(experiment),
        outputs["comparative_statics"] =>
            _render_comparatives(experiment),
    )
end

function _write_or_check(artifacts, check)
    for (relative_path, content) in sort(collect(artifacts); by = first)
        path = _absolute(relative_path)
        if check
            isfile(path) || error("missing unified canonical artifact: $path")
            read(path, String) == content ||
                error("stale unified canonical artifact: $path")
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
        error("usage: solve_unified_canonical_benchmark.jl [config] [--check]")
    config_path = isempty(paths) ? DEFAULT_CONFIG : only(paths)
    experiment = run_unified_canonical_benchmark(config_path)
    _write_or_check(_artifact_contents(experiment), check)
    println(
        check ?
        "unified canonical artifacts are current" :
        "wrote unified canonical artifacts",
    )
    println(
        "exact residual ",
        _ratio(experiment.compressed_stationary.bellman_residual),
        "; Float64 residual ",
        experiment.float.bellman_residual,
        "; exactly re-evaluated residual-based certificate ",
        _ratio(experiment.exact_float_residual_bound),
    )
    return experiment
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
