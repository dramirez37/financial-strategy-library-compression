module UnifiedBenchmarkSearch

using StrategyInnovation
using TOML

export UnifiedBenchmarkParameters,
       build_unified_benchmark,
       evaluate_unified_candidate,
       main,
       run_unified_benchmark_search

const EXPERIMENT_ID = "unified-positive-duration-benchmark-search-v1"
const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "unified_benchmark_search.toml",
)

const LOW = Belief(:low)
const HIGH = Belief(:high)
const CAPABILITY = ModuleId(:scale_capability)
const FAILURE = CandidateOutcome{Symbol}()
const CARRIER_A = CandidateOutcome(StrategyId(:carrier_a))
const CARRIER_B = CandidateOutcome(StrategyId(:carrier_b))
const DESCENDANT = CandidateOutcome(StrategyId(:descendant))

struct UnifiedBenchmarkParameters
    discount::ExactRational
    discover_cost_low::ExactRational
    discover_cost_high::ExactRational
    scale_cost::ExactRational
    scale_duration::Int
    scale_admission::ExactRational
    survival::ExactRational

    function UnifiedBenchmarkParameters(
        discount,
        discover_cost_low,
        discover_cost_high,
        scale_cost,
        scale_duration::Integer,
        scale_admission,
        survival,
    )
        beta = exact_rational(discount)
        cost_low = exact_rational(discover_cost_low)
        cost_high = exact_rational(discover_cost_high)
        descendant_cost = exact_rational(scale_cost)
        admission = exact_rational(scale_admission)
        survival_probability = exact_rational(survival)
        0 < beta < 1 || throw(ArgumentError("discount must lie strictly between zero and one"))
        all(x -> x >= 0, (cost_low, cost_high, descendant_cost)) ||
            throw(ArgumentError("all initiation costs must be nonnegative"))
        scale_duration >= 1 ||
            throw(ArgumentError("scale duration must be strictly positive"))
        0 <= admission <= 1 ||
            throw(ArgumentError("scale admission must be a probability"))
        0 <= survival_probability <= 1 ||
            throw(ArgumentError("survival must be a probability"))
        return new(
            beta,
            cost_low,
            cost_high,
            descendant_cost,
            Int(scale_duration),
            admission,
            survival_probability,
        )
    end
end

_ratio(value::Rational) = "$(numerator(value))//$(denominator(value))"
_bool(value::Bool) = value ? "true" : "false"

function _replace(
    parameters::UnifiedBenchmarkParameters;
    discount = parameters.discount,
    discover_cost_low = parameters.discover_cost_low,
    discover_cost_high = parameters.discover_cost_high,
    scale_cost = parameters.scale_cost,
    scale_duration = parameters.scale_duration,
    scale_admission = parameters.scale_admission,
    survival = parameters.survival,
)
    return UnifiedBenchmarkParameters(
        discount,
        discover_cost_low,
        discover_cost_high,
        scale_cost,
        scale_duration,
        scale_admission,
        survival,
    )
end

function _kernel_power(kernel::MarkovKernel, duration::Integer)
    duration >= 0 || throw(ArgumentError("kernel exponent must be nonnegative"))
    beliefs = collect(kernel.space)
    n = length(beliefs)
    result = zeros(ExactRational, n, n)
    for index in 1:n
        result[index, index] = 1
    end
    step = ExactRational[
        transition_probability(kernel, left, right) for left in beliefs, right in beliefs
    ]
    for _ in 1:duration
        result = result * step
    end
    return result
end

function _belief_paths(kernel::MarkovKernel, initial, duration::Integer)
    paths = Tuple[(initial,)]
    for _ in 1:duration
        paths = Tuple[
            (path..., next) for path in paths for next in kernel.space if
            !iszero(transition_probability(kernel, last(path), next))
        ]
    end
    return paths
end

function _path_probability(kernel::MarkovKernel, path)
    mass = exact_rational(1)
    for time in 1:(length(path) - 1)
        mass *= transition_probability(kernel, path[time], path[time + 1])
    end
    return mass
end

function _scale_success(parameters::UnifiedBenchmarkParameters)
    return parameters.survival^parameters.scale_duration *
           parameters.scale_admission
end

function _tilted_success_probabilities(high_mass, success_mass)
    high = exact_rational(high_mass)
    success = exact_rational(success_mass)
    low = 1 - high
    if iszero(success)
        return (low = exact_rational(0), high = exact_rational(0))
    elseif success == 1
        return (low = exact_rational(1), high = exact_rational(1))
    elseif high >= success
        return (low = exact_rational(0), high = success / high)
    end
    return (low = (success - high) / low, high = exact_rational(1))
end

function _product_completion(kernel, project, belief, admitted::RatProb)
    outcomes = ProjectCompletionOutcome{Symbol,Symbol}[]
    masses = ExactRational[]
    for path in _belief_paths(kernel, belief, project.duration)
        path_mass = _path_probability(kernel, path)
        for (outcome, outcome_mass) in
            zip(admitted.outcomes, admitted.probabilities)
            mass = path_mass * outcome_mass
            iszero(mass) && continue
            push!(outcomes, ProjectCompletionOutcome(collect(path), outcome))
            push!(masses, mass)
        end
    end
    return RatProb(outcomes, masses)
end

"""
    build_unified_benchmark(parameters)

Construct the exact two-belief, four-strategy raw benchmark. Survival acts in
the raw Scale generation law: a descendant is generated with probability
`survival^duration`, and a generated descendant is admitted with the separate
verification probability `scale_admission`.
"""
function build_unified_benchmark(parameters::UnifiedBenchmarkParameters)
    beliefs = FiniteBeliefSpace([:low, :high])
    kernel = MarkovKernel(beliefs, [3//4 1//4; 1//4 3//4])
    modules = [GenerativeModule(:scale_capability)]
    empty_modules = ModuleSet{Symbol}()
    capability = ModuleSet([CAPABILITY])
    strategies = [
        Strategy(:inactive, OperationalProfile(beliefs, [0, 0]), empty_modules),
        Strategy(:carrier_a, OperationalProfile(beliefs, [0, 0]), capability),
        Strategy(:carrier_b, OperationalProfile(beliefs, [0, 0]), capability),
        Strategy(:descendant, OperationalProfile(beliefs, [2, 4]), capability),
    ]
    catalog = StrategyCatalog(
        beliefs,
        modules,
        strategies,
        StrategyId(:inactive),
    )
    closure = identity_generative_closure(modules)
    discover = UnifiedResearchProject(:discover, empty_modules, 1, true)
    scale = UnifiedResearchProject(
        :scale,
        capability,
        parameters.scale_duration,
        true,
    )
    projects = [discover, scale]

    generation = function (project, belief, available)
        if project.id == ResearchProjectId(:discover)
            return isempty(available) ?
                   RatProb([CARRIER_A, CARRIER_B], [1//2, 1//2]) :
                   dirac(FAILURE)
        end
        if CAPABILITY in available
            generated = parameters.survival^project.duration
            return RatProb(
                [FAILURE, DESCENDANT],
                [1 - generated, generated],
            )
        end
        return dirac(FAILURE)
    end

    verification = function (project, belief, available, strategy_id)
        strategy_id == StrategyId(:carrier_a) && return 1//1
        strategy_id == StrategyId(:carrier_b) && return 1//2
        strategy_id == StrategyId(:descendant) &&
            return parameters.scale_admission
        return 1//1
    end

    cost = function (belief, state, project)
        if project.id == ResearchProjectId(:discover)
            return belief == LOW ?
                   parameters.discover_cost_low :
                   parameters.discover_cost_high
        end
        return parameters.scale_cost
    end

    availability = function (state, project)
        if project.id == ResearchProjectId(:discover)
            return isempty(state.closure)
        end
        return CAPABILITY in state.closure
    end

    completion = function (project, belief, state)
        if project.id == ResearchProjectId(:discover)
            admitted = isempty(state.closure) ?
                       RatProb(
                [FAILURE, CARRIER_A, CARRIER_B],
                [1//4, 1//2, 1//4],
            ) :
                       dirac(FAILURE)
            return _product_completion(kernel, project, belief, admitted)
        end
        if !(CAPABILITY in state.closure)
            return _product_completion(
                kernel,
                project,
                belief,
                dirac(FAILURE),
            )
        end

        success_mass = _scale_success(parameters)
        terminal = _kernel_power(kernel, project.duration)
        initial_index = belief == LOW ? 1 : 2
        conditional = _tilted_success_probabilities(
            terminal[initial_index, 2],
            success_mass,
        )
        outcomes = ProjectCompletionOutcome{Symbol,Symbol}[]
        masses = ExactRational[]
        for path in _belief_paths(kernel, belief, project.duration)
            path_mass = _path_probability(kernel, path)
            pass = last(path) == HIGH ? conditional.high : conditional.low
            if pass < 1
                push!(
                    outcomes,
                    ProjectCompletionOutcome(collect(path), FAILURE),
                )
                push!(masses, path_mass * (1 - pass))
            end
            if pass > 0
                push!(
                    outcomes,
                    ProjectCompletionOutcome(collect(path), DESCENDANT),
                )
                push!(masses, path_mass * pass)
            end
        end
        return RatProb(outcomes, masses)
    end

    process = RawInnovationProcess(
        catalog,
        closure,
        kernel,
        projects,
        generation,
        verification,
        cost,
        completion,
        parameters.discount;
        availability,
    )
    return (; process, catalog, closure, beliefs, kernel, projects)
end

function _state_label(state)
    isempty(state.closure) && return "K0"
    all(iszero(state.frontier[belief]) for belief in state.frontier.space) &&
        return "K1"
    return "K2"
end

_state_order(state) = parse(Int, last(_state_label(state)))
_belief_label(belief) = string(belief.id)

function _action_values(process, result)
    value = Dict(result.states[index] => result.values[index] for index in eachindex(result.states))
    rows = NamedTuple[]
    ordered_states = sort(collect(process.compressed_states); by = _state_order)
    for state in ordered_states, belief in process.belief_kernel.space
        available = unified_available_actions(process, state)
        values = Pair{String,ExactRational}[]
        for action in available
            candidate = if action isa ContinueAction
                compressed_continue_value(process, value, belief, state)
            else
                compressed_research_value(
                    process,
                    value,
                    belief,
                    state,
                    action.project,
                )
            end
            push!(values, action_label(action) => candidate)
        end
        sort!(values; by = last, rev = true)
        best = first(values)
        second = values[2]
        chosen = action_label(policy_action(result, belief, state))
        chosen == first(best) ||
            error("policy iteration action disagrees with exact Q maximizer")
        research = only(pair for pair in values if first(pair) != "continue")
        project_id = first(research) == "research:discover" ? :discover : :scale
        project = only(row for row in process.projects if row.id == ResearchProjectId(project_id))
        embedded = compressed_embedded_transition(
            process,
            belief,
            state,
            ResearchAction{Symbol}(project.id),
        )
        expected_reward_block = expectation(embedded, outcome -> outcome.reward)
        push!(
            rows,
            (
                state = _state_label(state),
                belief = _belief_label(belief),
                value = state_value(result, belief, state),
                chosen_action = chosen,
                second_action = first(second),
                continue_q = only(last(pair) for pair in values if first(pair) == "continue"),
                research_action = first(research),
                research_q = last(research),
                margin = last(best) - last(second),
                project_duration = project.duration,
                expected_reward_block,
                discounted_continuation = last(research) - expected_reward_block,
            ),
        )
    end
    return rows
end

function _policy_signature(rows)
    ordered = sort(rows; by = row -> (parse(Int, last(row.state)), row.belief == "low" ? 1 : 2))
    return join((row.chosen_action for row in ordered), "|")
end

function _exact_value_iteration(
    process,
    optimal_rows;
    max_iterations::Integer,
    tolerance::ExactRational,
)
    value = Dict(
        (belief, state) => exact_rational(0) for
        state in process.compressed_states for belief in process.belief_kernel.space
    )
    prior_increment = nothing
    contraction_holds = true
    monotone = true
    residual = exact_rational(0)
    iterations = 0
    for iteration in 1:max_iterations
        next_value = compressed_bellman_operator(process, value)
        increment = maximum(
            (abs(next_value[key] - value[key]) for key in keys(value));
            init = exact_rational(0),
        )
        monotone &= all(next_value[key] >= value[key] for key in keys(value))
        if prior_increment !== nothing
            contraction_holds &= increment <= process.discount * prior_increment
        end
        after = compressed_bellman_operator(process, next_value)
        residual = maximum(
            (abs(after[key] - next_value[key]) for key in keys(next_value));
            init = exact_rational(0),
        )
        value = next_value
        prior_increment = increment
        iterations = iteration
        residual <= tolerance && break
    end
    greedy = String[]
    for row in sort(optimal_rows; by = row -> (parse(Int, last(row.state)), row.belief == "low" ? 1 : 2))
        state = only(state for state in process.compressed_states if _state_label(state) == row.state)
        belief = row.belief == "low" ? LOW : HIGH
        values = Pair{String,ExactRational}[]
        for action in unified_available_actions(process, state)
            candidate = action isa ContinueAction ?
                        compressed_continue_value(process, value, belief, state) :
                        compressed_research_value(
                process,
                value,
                belief,
                state,
                action.project,
            )
            push!(values, action_label(action) => candidate)
        end
        best_index = argmax(last.(values))
        push!(greedy, first(values[best_index]))
    end
    return (
        iterations,
        residual,
        converged = residual <= tolerance,
        monotone,
        contraction_holds,
        policy_matches = join(greedy, "|") == _policy_signature(optimal_rows),
    )
end

function evaluate_unified_candidate(
    parameters::UnifiedBenchmarkParameters;
    policy_iteration_limit::Integer = 32,
)
    fixture = build_unified_benchmark(parameters)
    process = fixture.process
    result = compressed_infinite_horizon_policy_iteration(
        process;
        max_iterations = policy_iteration_limit,
    )
    rows = _action_values(process, result)
    actions = Set(row.chosen_action for row in rows)
    minimum_margin = minimum(row.margin for row in rows)
    return (
        parameters,
        fixture,
        result,
        rows,
        policy_signature = _policy_signature(rows),
        minimum_margin,
        has_continue = "continue" in actions,
        has_discover = "research:discover" in actions,
        has_scale = "research:scale" in actions,
        no_ties = all(row.margin > 0 for row in rows),
    )
end

_parse_rat_grid(values) = ExactRational[exact_rational(value) for value in values]

function _validate_fixed_config(config)
    fixed = config["fixed"]
    expected_kernel = [
        exact_rational(fixed["belief_kernel"][row][column]) for
        row in 1:2, column in 1:2
    ]
    expected_kernel == ExactRational[3//4 1//4; 1//4 3//4] ||
        error("the configured belief kernel does not match the versioned builder")
    fixed["discover_duration"] == 1 ||
        error("the configured Discover duration does not match the versioned builder")
    fixed["discover_operates"] === true ||
        error("the configured Discover operating flag must be true")
    fixed["scale_operates"] === true ||
        error("the configured Scale operating flag must be true")
    exact_rational(fixed["discover_carrier_a_generation"]) == 1 // 2 ||
        error("the configured carrier-A generation mass does not match")
    exact_rational(fixed["discover_carrier_b_generation"]) == 1 // 2 ||
        error("the configured carrier-B generation mass does not match")
    exact_rational(fixed["discover_carrier_a_admission"]) == 1 ||
        error("the configured carrier-A admission probability does not match")
    exact_rational(fixed["discover_carrier_b_admission"]) == 1 // 2 ||
        error("the configured carrier-B admission probability does not match")
    fixed["frontier_k0"] == ["0//1", "0//1"] ||
        error("the configured K0 frontier does not match")
    fixed["frontier_k1"] == ["0//1", "0//1"] ||
        error("the configured K1 frontier does not match")
    fixed["frontier_k2"] == ["2//1", "4//1"] ||
        error("the configured K2 frontier does not match")
    return nothing
end

function _parameters_from_config(table)
    return UnifiedBenchmarkParameters(
        table["discount"],
        table["discover_cost_low"],
        table["discover_cost_high"],
        table["scale_cost"],
        table["scale_duration"],
        table["scale_admission"],
        table["survival"],
    )
end

function _parameter_grid(config)
    grid = config["grid"]
    parameters = UnifiedBenchmarkParameters[]
    for discount in _parse_rat_grid(grid["discount"]),
        discover_low in _parse_rat_grid(grid["discover_cost_low"]),
        discover_high in _parse_rat_grid(grid["discover_cost_high"]),
        scale_cost in _parse_rat_grid(grid["scale_cost"]),
        duration in grid["scale_duration"],
        admission in _parse_rat_grid(grid["scale_admission"]),
        survival in _parse_rat_grid(grid["survival"])
        push!(
            parameters,
            UnifiedBenchmarkParameters(
                discount,
                discover_low,
                discover_high,
                scale_cost,
                duration,
                admission,
                survival,
            ),
        )
    end
    return parameters
end

function _continuous_perturbations(parameters, config)
    steps = config["perturbations"]
    specifications = (
        (:discover_cost_low, exact_rational(steps["discover_cost_low"])),
        (:discover_cost_high, exact_rational(steps["discover_cost_high"])),
        (:scale_cost, exact_rational(steps["scale_cost"])),
        (:discount, exact_rational(steps["discount"])),
        (:scale_admission, exact_rational(steps["scale_admission"])),
        (:survival, exact_rational(steps["survival"])),
    )
    rows = NamedTuple[]
    for (field, step) in specifications, direction in (-1, 1)
        old = getfield(parameters, field)
        new = old + direction * step
        if field in (:discount, :scale_admission, :survival)
            0 < new < 1 || continue
        elseif new < 0
            continue
        end
        perturbed = if field == :discover_cost_low
            _replace(parameters; discover_cost_low = new)
        elseif field == :discover_cost_high
            _replace(parameters; discover_cost_high = new)
        elseif field == :scale_cost
            _replace(parameters; scale_cost = new)
        elseif field == :discount
            _replace(parameters; discount = new)
        elseif field == :scale_admission
            _replace(parameters; scale_admission = new)
        else
            _replace(parameters; survival = new)
        end
        push!(
            rows,
            (
                scenario = string(field, direction < 0 ? "_down" : "_up"),
                parameter = string(field),
                direction,
                old,
                new,
                parameters = perturbed,
            ),
        )
    end
    return rows
end

function _stability_audit(baseline, config, policy_iteration_limit)
    rows = NamedTuple[]
    for perturbation in _continuous_perturbations(baseline.parameters, config)
        evaluated = evaluate_unified_candidate(
            perturbation.parameters;
            policy_iteration_limit,
        )
        stable = evaluated.policy_signature == baseline.policy_signature
        push!(
            rows,
            (
                scenario = perturbation.scenario,
                parameter = perturbation.parameter,
                baseline = perturbation.old,
                perturbed = perturbation.new,
                policy_signature = evaluated.policy_signature,
                stable,
                minimum_margin = evaluated.minimum_margin,
            ),
        )
    end
    return (
        rows,
        all_stable = all(row.stable for row in rows),
        minimum_margin = minimum(row.minimum_margin for row in rows),
    )
end

function _comparative_parameters(parameters, config)
    table = config["comparative_statics"]
    return (
        cost_low = _replace(parameters; scale_cost = exact_rational(table["cost_low"])),
        cost_high = _replace(parameters; scale_cost = exact_rational(table["cost_high"])),
        duration_low = _replace(parameters; scale_duration = table["duration_low"]),
        duration_high = _replace(parameters; scale_duration = table["duration_high"]),
        discount_low = _replace(parameters; discount = exact_rational(table["discount_low"])),
        discount_high = _replace(parameters; discount = exact_rational(table["discount_high"])),
        admission_low = _replace(parameters; scale_admission = exact_rational(table["admission_low"])),
        admission_high = _replace(parameters; scale_admission = exact_rational(table["admission_high"])),
        survival_low = _replace(parameters; survival = exact_rational(table["survival_low"])),
        survival_high = _replace(parameters; survival = exact_rational(table["survival_high"])),
    )
end

function _k1_values(evaluated)
    rows = [row for row in evaluated.rows if row.state == "K1"]
    return (
        low = only(row.value for row in rows if row.belief == "low"),
        high = only(row.value for row in rows if row.belief == "high"),
        low_margin = only(row.margin for row in rows if row.belief == "low"),
        high_margin = only(row.margin for row in rows if row.belief == "high"),
    )
end

function _comparative_static_audit(parameters, config, policy_iteration_limit)
    scenario_parameters = _comparative_parameters(parameters, config)
    evaluated = Dict{Symbol,Any}()
    rows = NamedTuple[]
    for (scenario, candidate) in pairs(scenario_parameters)
        result = evaluate_unified_candidate(candidate; policy_iteration_limit)
        evaluated[scenario] = result
        values = _k1_values(result)
        axis, level = split(string(scenario), "_")
        parameter_value = if axis == "cost"
            candidate.scale_cost
        elseif axis == "duration"
            exact_rational(candidate.scale_duration)
        elseif axis == "discount"
            candidate.discount
        elseif axis == "admission"
            candidate.scale_admission
        else
            candidate.survival
        end
        push!(
            rows,
            (
                axis,
                level,
                parameter_value,
                k1_low_value = values.low,
                k1_high_value = values.high,
                k1_low_margin = values.low_margin,
                k1_high_margin = values.high_margin,
                policy_signature = result.policy_signature,
            ),
        )
    end
    checks = (
        cost =
            _k1_values(evaluated[:cost_high]).low <
            _k1_values(evaluated[:cost_low]).low,
        duration =
            _k1_values(evaluated[:duration_high]).low <
            _k1_values(evaluated[:duration_low]).low,
        discount =
            _k1_values(evaluated[:discount_low]).low <
            _k1_values(evaluated[:discount_high]).low,
        admission =
            _k1_values(evaluated[:admission_low]).low <
            _k1_values(evaluated[:admission_high]).low,
        survival =
            _k1_values(evaluated[:survival_low]).low <
            _k1_values(evaluated[:survival_high]).low,
    )
    return (; rows, checks, all_visible = all(values(checks)))
end

function _parameter_distance(left, right)
    return abs(left.discount - right.discount) +
           abs(left.discover_cost_low - right.discover_cost_low) +
           abs(left.discover_cost_high - right.discover_cost_high) +
           abs(left.scale_cost - right.scale_cost) +
           abs(left.scale_duration - right.scale_duration) +
           abs(left.scale_admission - right.scale_admission) +
           abs(left.survival - right.survival)
end

function _denominator_complexity(evaluation)
    parameter_denominators = denominator.(
        (
            evaluation.parameters.discount,
            evaluation.parameters.discover_cost_low,
            evaluation.parameters.discover_cost_high,
            evaluation.parameters.scale_cost,
            evaluation.parameters.scale_admission,
            evaluation.parameters.survival,
        ),
    )
    value_denominators = denominator.(getproperty.(evaluation.rows, :value))
    return maximum(vcat(collect(parameter_denominators), collect(value_denominators)))
end

function _better_candidate(left, right)
    left.minimum_margin != right.minimum_margin &&
        return left.minimum_margin > right.minimum_margin
    left.stability.minimum_margin != right.stability.minimum_margin &&
        return left.stability.minimum_margin > right.stability.minimum_margin
    left.denominator_complexity != right.denominator_complexity &&
        return left.denominator_complexity < right.denominator_complexity
    left.reference_distance != right.reference_distance &&
        return left.reference_distance < right.reference_distance
    return left.candidate_id < right.candidate_id
end

function _deep_audit(evaluation, config)
    process = evaluation.fixture.process
    raw = raw_infinite_horizon_policy_iteration(
        process;
        max_iterations = config["gates"]["policy_iteration_limit"],
    )
    compressed = evaluation.result
    raw_compressed_equal = true
    policy_lift = true
    for library in process.raw_libraries, belief in process.belief_kernel.space
        state = compressed_library_state(
            process.catalog,
            process.closure,
            library,
        )
        raw_compressed_equal &=
            state_value(raw, belief, library) ==
            state_value(compressed, belief, state)
        policy_lift &=
            policy_action(raw, belief, library) ==
            policy_action(compressed, belief, state)
    end

    path_lengths = true
    terminal_kernel = true
    for state in process.compressed_states,
        belief in process.belief_kernel.space,
        project in process.projects
        completion = process.completion(project, belief, state)
        path_lengths &= all(
            length(outcome.path) == project.duration + 1 for
            outcome in completion.outcomes
        )
        power = _kernel_power(process.belief_kernel, project.duration)
        initial_index = belief == LOW ? 1 : 2
        for terminal in process.belief_kernel.space
            terminal_index = terminal == LOW ? 1 : 2
            terminal_mass = sum(
                mass for (outcome, mass) in
                zip(completion.outcomes, completion.probabilities) if
                terminal_belief(outcome) == terminal;
                init = exact_rational(0),
            )
            terminal_kernel &= terminal_mass == power[initial_index, terminal_index]
        end
    end

    representatives = Dict(label => 0 for label in ("K0", "K1", "K2"))
    for library in process.raw_libraries
        state = compressed_library_state(
            process.catalog,
            process.closure,
            library,
        )
        representatives[_state_label(state)] += 1
    end
    value_iteration = _exact_value_iteration(
        process,
        evaluation.rows;
        max_iterations = config["gates"]["value_iteration_limit"],
        tolerance = exact_rational(
            config["gates"]["value_iteration_residual_tolerance"],
        ),
    )
    checks = (
        raw_library_count = length(process.raw_libraries) == 8,
        compressed_state_count = length(process.compressed_states) == 3,
        representative_counts =
            representatives == Dict("K0" => 1, "K1" => 3, "K2" => 4),
        positive_durations = all(project.duration > 0 for project in process.projects),
        full_path_lengths = path_lengths,
        terminal_kernel_power = terminal_kernel,
        unified_operation_flags =
            all(project.operates_during_research for project in process.projects),
        raw_policy_converged = raw.converged,
        compressed_policy_converged = compressed.converged,
        raw_policy_equation_residual = raw.policy_equation_residual == 0,
        compressed_policy_equation_residual =
            compressed.policy_equation_residual == 0,
        raw_bellman_residual = raw.bellman_residual == 0,
        compressed_bellman_residual = compressed.bellman_residual == 0,
        raw_compressed_equal,
        policy_lift,
        value_iteration_converged = value_iteration.converged,
        value_iteration_monotone = value_iteration.monotone,
        value_iteration_contraction = value_iteration.contraction_holds,
        value_iteration_policy_matches = value_iteration.policy_matches,
    )
    all(values(checks)) || error("selected unified benchmark failed its deep audit")
    return (; raw, compressed, representatives, value_iteration, checks)
end

function run_unified_benchmark_search(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    config["experiment_id"] == EXPERIMENT_ID ||
        error("unexpected unified benchmark experiment ID")
    config["arithmetic"] == "Rational{BigInt}" ||
        error("the unified benchmark search requires exact Rational{BigInt} arithmetic")
    config["randomness"] == "none" ||
        error("the unified benchmark search must remain deterministic")
    _validate_fixed_config(config)
    gates = config["gates"]
    minimum_margin_gate = exact_rational(gates["minimum_action_margin"])
    policy_iteration_limit = gates["policy_iteration_limit"]
    reference = _parameters_from_config(config["selection_reference"])
    candidates = NamedTuple[]
    eligible = NamedTuple[]
    parameters_grid = _parameter_grid(config)

    for (index, parameters) in enumerate(parameters_grid)
        candidate_id = "C" * lpad(string(index), 4, '0')
        evaluation = evaluate_unified_candidate(
            parameters;
            policy_iteration_limit,
        )
        reasons = String[]
        evaluation.result.converged ||
            push!(reasons, "policy_iteration_nonconvergence")
        evaluation.result.policy_equation_residual == 0 ||
            push!(reasons, "nonzero_policy_equation_residual")
        evaluation.result.bellman_residual == 0 ||
            push!(reasons, "nonzero_bellman_residual")
        evaluation.has_continue || push!(reasons, "missing_continue")
        evaluation.has_discover || push!(reasons, "missing_discovery")
        evaluation.has_scale || push!(reasons, "missing_descendant")
        evaluation.no_ties || push!(reasons, "action_tie")
        evaluation.minimum_margin >= minimum_margin_gate ||
            push!(reasons, "near_action_tie")

        stability = nothing
        comparatives = nothing
        if isempty(reasons)
            stability = _stability_audit(
                evaluation,
                config,
                policy_iteration_limit,
            )
            stability.all_stable ||
                push!(reasons, "perturbation_instability")
        end
        if isempty(reasons)
            comparatives = _comparative_static_audit(
                parameters,
                config,
                policy_iteration_limit,
            )
            for (axis, passed) in pairs(comparatives.checks)
                passed || push!(reasons, "invisible_$(axis)_comparative_static")
            end
        end

        record = (
            candidate_id,
            parameters,
            evaluation,
            stability,
            comparatives,
            minimum_margin = evaluation.minimum_margin,
            denominator_complexity = _denominator_complexity(evaluation),
            reference_distance = _parameter_distance(parameters, reference),
            reasons,
        )
        push!(candidates, record)
        isempty(reasons) && push!(eligible, record)
    end
    isempty(eligible) && error("the exact unified benchmark search found no eligible candidate")
    selected = first(eligible)
    for candidate in Iterators.drop(eligible, 1)
        _better_candidate(candidate, selected) && (selected = candidate)
    end
    deep = _deep_audit(selected.evaluation, config)
    return (
        experiment_id = EXPERIMENT_ID,
        arithmetic = config["arithmetic"],
        randomness = config["randomness"],
        config_path = abspath(config_path),
        config,
        candidate_count = length(candidates),
        eligible_count = length(eligible),
        candidates,
        selected,
        deep,
    )
end

function _render_search_csv(experiment)
    io = IOBuffer()
    println(
        io,
        "candidate_id,discount,discover_cost_low,discover_cost_high,scale_cost," *
        "scale_duration,scale_admission,survival,scale_success,policy_signature," *
        "minimum_action_margin,stability_minimum_margin,policy_iterations," *
        "policy_equation_residual,bellman_residual,denominator_complexity," *
        "reference_distance,status,rejection_reasons",
    )
    selected_id = experiment.selected.candidate_id
    for candidate in experiment.candidates
        parameters = candidate.parameters
        status = candidate.candidate_id == selected_id ?
                 "selected" :
                 isempty(candidate.reasons) ? "accepted_not_selected" : "rejected"
        reasons = if status == "accepted_not_selected"
            "dominated_by_selection_score"
        else
            join(candidate.reasons, "|")
        end
        stability_margin = isnothing(candidate.stability) ?
                           "" :
                           _ratio(candidate.stability.minimum_margin)
        result = candidate.evaluation.result
        println(
            io,
            join(
                (
                    candidate.candidate_id,
                    _ratio(parameters.discount),
                    _ratio(parameters.discover_cost_low),
                    _ratio(parameters.discover_cost_high),
                    _ratio(parameters.scale_cost),
                    parameters.scale_duration,
                    _ratio(parameters.scale_admission),
                    _ratio(parameters.survival),
                    _ratio(_scale_success(parameters)),
                    candidate.evaluation.policy_signature,
                    _ratio(candidate.minimum_margin),
                    stability_margin,
                    result.iterations,
                    _ratio(result.policy_equation_residual),
                    _ratio(result.bellman_residual),
                    candidate.denominator_complexity,
                    _ratio(candidate.reference_distance),
                    status,
                    reasons,
                ),
                ",",
            ),
        )
    end
    return String(take!(io))
end

function _render_selected_toml(experiment)
    selected = experiment.selected
    parameters = selected.parameters
    io = IOBuffer()
    println(io, "schema_version = \"unified-benchmark-selected-v1\"")
    println(io, "experiment_id = \"$(experiment.experiment_id)\"")
    println(io, "candidate_id = \"$(selected.candidate_id)\"")
    println(io, "arithmetic = \"$(experiment.arithmetic)\"")
    println(io, "randomness = \"$(experiment.randomness)\"")
    println(io, "source_search = \"experiments/configs/unified_benchmark_search.toml\"")
    println(io, "legacy_fixture = \"experiments/configs/canonical_discounted_dp.toml\"")
    println(io)
    println(io, "[parameters]")
    println(io, "discount = \"$(_ratio(parameters.discount))\"")
    println(io, "discover_cost_low = \"$(_ratio(parameters.discover_cost_low))\"")
    println(io, "discover_cost_high = \"$(_ratio(parameters.discover_cost_high))\"")
    println(io, "scale_cost = \"$(_ratio(parameters.scale_cost))\"")
    println(io, "scale_duration = $(parameters.scale_duration)")
    println(io, "scale_admission = \"$(_ratio(parameters.scale_admission))\"")
    println(io, "survival = \"$(_ratio(parameters.survival))\"")
    println(io, "scale_generation = \"$(_ratio(parameters.survival^parameters.scale_duration))\"")
    println(io, "scale_admitted_success = \"$(_ratio(_scale_success(parameters)))\"")
    println(io)
    println(io, "[structure]")
    println(io, "belief_count = 2")
    println(io, "raw_strategy_count = 4")
    println(io, "raw_library_count = 8")
    println(io, "compressed_state_count = 3")
    println(io, "discover_duration = 1")
    println(io, "discover_operates = true")
    println(io, "scale_operates = true")
    println(io, "policy_signature = \"$(selected.evaluation.policy_signature)\"")
    println(io)
    println(io, "[certificates]")
    println(io, "minimum_action_margin = \"$(_ratio(selected.minimum_margin))\"")
    println(io, "stability_minimum_margin = \"$(_ratio(selected.stability.minimum_margin))\"")
    println(io, "policy_iterations = $(selected.evaluation.result.iterations)")
    println(io, "policy_equation_residual = \"$(_ratio(selected.evaluation.result.policy_equation_residual))\"")
    println(io, "bellman_residual = \"$(_ratio(selected.evaluation.result.bellman_residual))\"")
    println(io, "raw_compressed_equal = $(_bool(experiment.deep.checks.raw_compressed_equal))")
    println(io, "policy_lift = $(_bool(experiment.deep.checks.policy_lift))")
    return String(take!(io))
end

function _render_policy_value_csv(experiment)
    io = IOBuffer()
    println(
        io,
        "compressed_state,belief,value,chosen_action,second_action,continue_q," *
        "research_action,research_q,action_margin,project_duration," *
        "expected_project_reward_block,discounted_project_continuation",
    )
    for row in experiment.selected.evaluation.rows
        println(
            io,
            join(
                (
                    row.state,
                    row.belief,
                    _ratio(row.value),
                    row.chosen_action,
                    row.second_action,
                    _ratio(row.continue_q),
                    row.research_action,
                    _ratio(row.research_q),
                    _ratio(row.margin),
                    row.project_duration,
                    _ratio(row.expected_reward_block),
                    _ratio(row.discounted_continuation),
                ),
                ",",
            ),
        )
    end
    return String(take!(io))
end

function _render_stability_csv(experiment)
    io = IOBuffer()
    println(
        io,
        "scenario,parameter,baseline,perturbed,policy_signature,stable,minimum_action_margin",
    )
    for row in experiment.selected.stability.rows
        println(
            io,
            join(
                (
                    row.scenario,
                    row.parameter,
                    _ratio(row.baseline),
                    _ratio(row.perturbed),
                    row.policy_signature,
                    row.stable,
                    _ratio(row.minimum_margin),
                ),
                ",",
            ),
        )
    end
    return String(take!(io))
end

function _render_comparative_csv(experiment)
    io = IOBuffer()
    println(
        io,
        "axis,level,parameter_value,k1_low_value,k1_high_value," *
        "k1_low_action_margin,k1_high_action_margin,policy_signature",
    )
    for row in experiment.selected.comparatives.rows
        println(
            io,
            join(
                (
                    row.axis,
                    row.level,
                    _ratio(row.parameter_value),
                    _ratio(row.k1_low_value),
                    _ratio(row.k1_high_value),
                    _ratio(row.k1_low_margin),
                    _ratio(row.k1_high_margin),
                    row.policy_signature,
                ),
                ",",
            ),
        )
    end
    return String(take!(io))
end

function _rejection_counts(experiment)
    counts = Dict{String,Int}()
    for candidate in experiment.candidates
        reasons = isempty(candidate.reasons) &&
                  candidate.candidate_id != experiment.selected.candidate_id ?
                  ["dominated_by_selection_score"] :
                  candidate.reasons
        for reason in reasons
            counts[reason] = get(counts, reason, 0) + 1
        end
    end
    return counts
end

function _render_rejections_csv(experiment)
    io = IOBuffer()
    println(io, "reason,candidate_count")
    for (reason, count) in sort(collect(_rejection_counts(experiment)); by = first)
        println(io, "$reason,$count")
    end
    return String(take!(io))
end

function _render_action_margin_report(experiment)
    selected = experiment.selected
    parameters = selected.parameters
    deep = experiment.deep
    io = IOBuffer()
    println(io, "# Unified Benchmark Exact Search and Action-Margin Report")
    println(io)
    println(
        io,
        "The exact grid search selected `$(selected.candidate_id)` from " *
        "$(experiment.candidate_count) candidates; $(experiment.eligible_count) " *
        "passed every economic, separation, perturbation, and comparative-static gate.",
    )
    println(io)
    println(io, "This is deterministic Julia `Rational{BigInt}` validation evidence, not a theorem or a Lean proof. The legacy canonical benchmark remains an unchanged appendix compatibility fixture.")
    println(io)
    println(io, "## Selected primitives")
    println(io)
    println(io, "| Primitive | Exact value |")
    println(io, "|---|---:|")
    for (label, value) in (
        ("Discount", parameters.discount),
        ("Discover cost, low belief", parameters.discover_cost_low),
        ("Discover cost, high belief", parameters.discover_cost_high),
        ("Scale cost", parameters.scale_cost),
        ("Scale admission", parameters.scale_admission),
        ("Survival", parameters.survival),
        ("Scale raw generation, survival^duration", parameters.survival^parameters.scale_duration),
        ("Scale admitted success", _scale_success(parameters)),
    )
        println(io, "| $label | `$(_ratio(value))` |")
    end
    println(io, "| Scale duration | `$(parameters.scale_duration)` |")
    println(io)
    println(io, "## Exact policy, values, and action margins")
    println(io)
    println(io, "| State | Belief | Value | Optimal action | Continue Q | Research Q | Margin |")
    println(io, "|---|---|---:|---|---:|---:|---:|")
    for row in selected.evaluation.rows
        println(
            io,
            "| $(row.state) | $(row.belief) | `$(_ratio(row.value))` | " *
            "$(row.chosen_action) | `$(_ratio(row.continue_q))` | " *
            "`$(_ratio(row.research_q))` | `$(_ratio(row.margin))` |",
        )
    end
    println(io)
    println(io, "The worst baseline action margin is `$(_ratio(selected.minimum_margin))`; the worst margin across all accepted local perturbations is `$(_ratio(selected.stability.minimum_margin))`.")
    println(io)
    println(io, "## Structural and solver checks")
    println(io)
    println(io, "| Check | Result |")
    println(io, "|---|---|")
    for (key, passed) in pairs(deep.checks)
        println(io, "| `$(key)` | $(_bool(passed)) |")
    end
    println(io, "| Raw representatives K0/K1/K2 | $(deep.representatives["K0"])/$(deep.representatives["K1"])/$(deep.representatives["K2"]) |")
    println(io, "| Compressed policy iterations | $(selected.evaluation.result.iterations) |")
    println(io, "| Raw policy iterations | $(deep.raw.iterations) |")
    println(io, "| Exact value-iteration iterations | $(deep.value_iteration.iterations) |")
    println(io, "| Exact value-iteration terminal residual | `$(_ratio(deep.value_iteration.residual))` |")
    println(io)
    println(io, "Every project duration is positive. Completion support contains `duration + 1` beliefs, and each terminal marginal equals the corresponding row of `P^duration`. Research reward blocks are generated solely through each project's unified operating flag.")
    println(io)
    println(io, "## Local perturbation stability")
    println(io)
    println(io, "| Scenario | Baseline | Perturbed | Same policy | Minimum margin |")
    println(io, "|---|---:|---:|---|---:|")
    for row in selected.stability.rows
        println(
            io,
            "| $(row.scenario) | `$(_ratio(row.baseline))` | " *
            "`$(_ratio(row.perturbed))` | $(_bool(row.stable)) | " *
            "`$(_ratio(row.minimum_margin))` |",
        )
    end
    println(io)
    println(io, "## Comparative statics")
    println(io)
    println(io, "| Axis | Level | Parameter | K1 low value | K1 high value |")
    println(io, "|---|---|---:|---:|---:|")
    for row in selected.comparatives.rows
        println(
            io,
            "| $(row.axis) | $(row.level) | `$(_ratio(row.parameter_value))` | " *
            "`$(_ratio(row.k1_low_value))` | `$(_ratio(row.k1_high_value))` |",
        )
    end
    println(io)
    println(io, "The exact directional gates require K1 value to fall with cost and duration and to rise with discount, admission, and survival. All five inequalities are strict for the selected candidate.")
    println(io)
    println(io, "## Alternative-candidate rejection accounting")
    println(io)
    println(io, "| Reason | Candidate count |")
    println(io, "|---|---:|")
    for (reason, count) in sort(collect(_rejection_counts(experiment)); by = first)
        println(io, "| `$reason` | $count |")
    end
    println(io)
    println(io, "The complete candidate-level parameters, margins, policy signatures, statuses, and rejection reasons are in `experiments/results/unified_benchmark_search.csv`.")
    return String(take!(io))
end

function _artifact_contents(experiment)
    outputs = experiment.config["outputs"]
    return Dict(
        outputs["search"] => _render_search_csv(experiment),
        outputs["selected"] => _render_selected_toml(experiment),
        outputs["action_margin_report"] => _render_action_margin_report(experiment),
        outputs["policy_value"] => _render_policy_value_csv(experiment),
        outputs["rejections"] => _render_rejections_csv(experiment),
        outputs["perturbation_stability"] => _render_stability_csv(experiment),
        outputs["comparative_statics"] => _render_comparative_csv(experiment),
    )
end

function _absolute(path)
    return isabspath(path) ? path : joinpath(REPOSITORY_ROOT, path)
end

function _write_or_check(artifacts, check)
    for (relative_path, content) in sort(collect(artifacts); by = first)
        path = _absolute(relative_path)
        if check
            isfile(path) || error("missing unified benchmark artifact: $path")
            read(path, String) == content ||
                error("stale unified benchmark artifact: $path")
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
        error("usage: search_unified_benchmark.jl [config] [--check]")
    config_path = isempty(paths) ? DEFAULT_CONFIG : only(paths)
    experiment = run_unified_benchmark_search(config_path)
    _write_or_check(_artifact_contents(experiment), check)
    println(
        check ?
        "unified benchmark search artifacts are current" :
        "wrote unified benchmark search artifacts",
    )
    println(
        "selected $(experiment.selected.candidate_id) with minimum margin " *
        _ratio(experiment.selected.minimum_margin),
    )
    return experiment
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
