module TheoremMechanismExperiments

using LinearAlgebra: I
using Random: rand
using SHA: sha256
using StrategyInnovation
using TOML

export DEFAULT_MECHANISM_CONFIG,
       load_mechanism_config,
       main,
       run_coverage_family,
       run_decomposition_family,
       run_dynamic_policy_family,
       run_dynamic_quotient_family,
       run_frontier_closure_family,
       run_frontier_pruning_family,
       run_safe_deletion_family,
       run_theorem_mechanism_experiments,
       write_theorem_mechanism_outputs

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_MECHANISM_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "theorem_mechanisms.toml",
)
const SCHEMA_VERSION = "theorem-mechanism-experiments-v2"
const EXPERIMENT_ID = "theorem-mechanism-controlled-suite-v2"
const BLUE = "#2563A6"
const ORANGE = "#D97706"
const GREEN = "#3A7D5D"
const PURPLE = "#7656A5"
const RED = "#B64A4A"
const CHARCOAL = "#25313C"
const MUTED = "#6B7785"
const GRID = "#DDE3E8"
const BACKGROUND = "#FBFCFD"

function _require_pattern(condition::Bool, identifier::AbstractString, detail::AbstractString)
    condition || error("expected theorem pattern $identifier failed: $detail")
    return true
end

_rational_string(value::Rational) =
    string(numerator(value), "//", denominator(value))

function _display_value(value)
    value isa Rational && return _rational_string(value)
    value isa Missing && return ""
    value isa AbstractFloat && return string(round(value; sigdigits = 12))
    value isa AbstractVector && return join((_display_value(item) for item in value), ";")
    return string(value)
end

function _observation(
    family,
    case_id,
    observation_id,
    metric;
    belief_index = missing,
    coordinate = missing,
    parameter = "",
    parameter_value = "",
    exact_value = "",
    float_value = missing,
    action = "",
    expected = "",
    passed = true,
    notes = "",
)
    return (;
        family = string(family),
        case_id = string(case_id),
        observation_id = string(observation_id),
        belief_index,
        coordinate,
        parameter = string(parameter),
        parameter_value = string(parameter_value),
        metric = string(metric),
        exact_value = exact_value isa Rational ? _rational_string(exact_value) : string(exact_value),
        float_value,
        action = string(action),
        expected = string(expected),
        passed,
        notes = string(notes),
    )
end

function _summary(
    family,
    title,
    arithmetic,
    cases,
    expected_pattern,
    observed_pattern,
    validations,
    formal_scope,
)
    return (;
        family = string(family),
        title = string(title),
        arithmetic = string(arithmetic),
        cases,
        expected_pattern = string(expected_pattern),
        observed_pattern = string(observed_pattern),
        validations,
        passed = true,
        formal_scope = string(formal_scope),
    )
end

"""Load and validate the single preregistered controlled-experiment catalog."""
function load_mechanism_config(path::AbstractString = DEFAULT_MECHANISM_CONFIG)
    isfile(path) || throw(ArgumentError("experiment configuration not found: $path"))
    config = TOML.parsefile(path)
    get(config, "schema_version", "") == SCHEMA_VERSION || throw(
        ArgumentError("unsupported theorem-mechanism configuration schema"),
    )
    get(config, "experiment_id", "") == EXPERIMENT_ID || throw(
        ArgumentError("unexpected theorem-mechanism experiment ID"),
    )
    string(VERSION) == config["julia_version"] || throw(
        ArgumentError(
            "configuration requires Julia $(config["julia_version"]); found $(VERSION)",
        ),
    )
    config["seed"] isa Integer || throw(ArgumentError("the experiment seed must be an integer"))
    return config
end

function _library_evaluation(process, horizon::Integer, state)
    values = finite_horizon_value(process, horizon)
    policy = finite_horizon_policy(process, horizon)
    state_index = findfirst(isequal(state), process.compressed_states)
    isnothing(state_index) && error("compressed state is absent from the process")
    return (
        values = collect(values[:, state_index]),
        policy = [action_label(policy[row, state_index]) for row in axes(policy, 1)],
    )
end

function _passive_value(process, horizon::Integer)
    horizon >= 0 || throw(ArgumentError("passive horizon must be nonnegative"))
    values = zeros(eltype(process.continue_rewards), length(process.beliefs), length(process.compressed_states))
    for _ in 1:horizon
        next_values = similar(values)
        for (state_index, state) in enumerate(process.compressed_states)
            for (belief_index_value, belief) in enumerate(process.beliefs)
                next_values[belief_index_value, state_index] =
                    continue_value(process, values, belief, state)
            end
        end
        values = next_values
    end
    return values
end

function _alias_fixture(profile_values, supplied_modules; horizon::Integer)
    beliefs = FiniteBeliefSpace([Symbol("b$index") for index in eachindex(profile_values)])
    modules = [GenerativeModule(:key), GenerativeModule(:aux)]
    empty_modules = ModuleSet{Symbol}()
    module_set = ModuleSet(ModuleId{Symbol}[ModuleId(module_id) for module_id in supplied_modules])
    profile = OperationalProfile(beliefs, profile_values)
    future_profile = OperationalProfile(beliefs, ExactRational[value + 6 for value in profile.values])
    strategies = [
        Strategy(:inactive, OperationalProfile(beliefs, zeros(Int, length(beliefs))), empty_modules),
        Strategy(:code_alpha, profile, module_set),
        Strategy(:code_beta, profile, module_set),
        Strategy(:future, future_profile, module_set),
    ]
    catalog = StrategyCatalog(beliefs, modules, strategies, StrategyId(:inactive))
    closure = identity_generative_closure(modules)
    left = RawLibrary(catalog, [StrategyId(:inactive), StrategyId(:code_alpha)])
    right = RawLibrary(catalog, [StrategyId(:inactive), StrategyId(:code_beta)])
    future = RawLibrary(catalog, [StrategyId(:inactive), StrategyId(:future)])
    left_state = compressed_state(catalog, closure, left)
    right_state = compressed_state(catalog, closure, right)
    future_state = compressed_state(catalog, closure, future)
    project = ResearchProject(:innovate, empty_modules)
    transition = (belief, state, selected) -> dirac(future_state)
    process = DiscountedResearchProcess(
        [left_state, future_state],
        [project],
        MarkovKernel(beliefs, Matrix{Int}(I, length(beliefs), length(beliefs))),
        transition,
        (belief, state, selected) -> 0,
        selected -> 0,
        1 // 2,
    )
    return (;
        beliefs,
        catalog,
        closure,
        left,
        right,
        left_state,
        right_state,
        future_state,
        process,
        horizon,
    )
end

"""Family A: raw code aliases collapse to the same exact dynamic quotient state."""
function run_dynamic_quotient_family(config, rng)
    settings = config["dynamic_quotient"]
    horizon = Int(settings["horizon"])
    trials = Int(settings["stress_trials"])
    belief_count = Int(settings["belief_count"])
    raw = NamedTuple[]
    passed_pairs = 0

    core = _alias_fixture(ExactRational[1, 2, 3], [:key]; horizon)
    _require_pattern(core.left != core.right, "A-RAW-IDENTITY", "raw libraries must differ")
    _require_pattern(
        core.left_state == core.right_state,
        "A-FRONTIER-CLOSURE",
        "code aliases must have equal compressed states",
    )
    core_left = _library_evaluation(core.process, horizon, core.left_state)
    core_right = _library_evaluation(core.process, horizon, core.right_state)
    _require_pattern(core_left.values == core_right.values, "A-VALUE", "alias values differ")
    _require_pattern(core_left.policy == core_right.policy, "A-POLICY", "alias policies differ")
    passed_pairs += 1
    for index in eachindex(core_left.values)
        push!(raw, _observation(
            "A", "alias-core", "belief-$index", "dynamic-value-and-policy";
            belief_index = index,
            exact_value = core_left.values[index],
            action = core_left.policy[index],
            expected = "left equals right",
            notes = "distinct strategy identifiers; equal frontier and closure",
        ))
    end

    module_ids = (:key, :aux)
    for trial in 1:trials
        profile = ExactRational[rand(rng, 0:8) for _ in 1:belief_count]
        supplied = Symbol[module_id for module_id in module_ids if rand(rng, Bool)]
        fixture = _alias_fixture(profile, supplied; horizon)
        left = _library_evaluation(fixture.process, horizon, fixture.left_state)
        right = _library_evaluation(fixture.process, horizon, fixture.right_state)
        pair_passed = fixture.left != fixture.right &&
                      fixture.left_state == fixture.right_state &&
                      left.values == right.values &&
                      left.policy == right.policy
        _require_pattern(pair_passed, "A-STRESS-$trial", "seeded alias pair failed")
        passed_pairs += 1
        push!(raw, _observation(
            "A", "alias-stress", "trial-$trial", "quotient-invariance";
            exact_value = join((_rational_string(value) for value in left.values), ";"),
            action = join(left.policy, ";"),
            expected = "equal values and policies",
            notes = "profile=$(join(_rational_string.(profile), ";")); modules=$(join(supplied, ";"))",
        ))
    end
    total_pairs = trials + 1
    return (
        summary = _summary(
            "A",
            "Dynamic quotient",
            settings["arithmetic"],
            total_pairs,
            settings["expected"],
            "$passed_pairs/$total_pairs distinct raw-library pairs had equal K, values, and policies",
            total_pairs * 4,
            "Computational counterpart of supporting F1/F2; not the unproved raw T1 bridge.",
        ),
        raw,
        core,
    )
end

function _decomposition_fixture(horizon::Integer)
    beliefs = FiniteBeliefSpace([:only])
    modules = [GenerativeModule(:key)]
    empty_modules = ModuleSet{Symbol}()
    key = ModuleSet([ModuleId(:key)])
    strategies = [
        Strategy(:inactive, OperationalProfile(beliefs, [0]), empty_modules),
        Strategy(:operational, OperationalProfile(beliefs, [2]), empty_modules),
        Strategy(:generative, OperationalProfile(beliefs, [0]), key),
        Strategy(:both, OperationalProfile(beliefs, [2]), key),
        Strategy(:future, OperationalProfile(beliefs, [8]), key),
    ]
    catalog = StrategyCatalog(beliefs, modules, strategies, StrategyId(:inactive))
    closure = identity_generative_closure(modules)
    libraries = (
        base = RawLibrary(catalog, [StrategyId(:inactive)]),
        operational = RawLibrary(catalog, [StrategyId(:inactive), StrategyId(:operational)]),
        generative = RawLibrary(catalog, [StrategyId(:inactive), StrategyId(:generative)]),
        both = RawLibrary(catalog, [StrategyId(:inactive), StrategyId(:both)]),
        future = RawLibrary(catalog, [StrategyId(:inactive), StrategyId(:future)]),
    )
    states = map(library -> compressed_state(catalog, closure, library), libraries)
    process = DiscountedResearchProcess(
        collect(states),
        [ResearchProject(:innovate, key)],
        MarkovKernel(beliefs, reshape([1], 1, 1)),
        (belief, state, project) ->
            dirac(ModuleId(:key) in state.closure ? states.future : state),
        (belief, state, project) -> 0,
        project -> 0,
        1 // 2,
    )
    full = finite_horizon_value(process, horizon)
    passive = _passive_value(process, horizon)
    function value_for(table, state)
        position = findfirst(isequal(state), process.compressed_states)
        return table[1, position]
    end
    values = map(state -> (
        full = value_for(full, state),
        passive = value_for(passive, state),
        premium = value_for(full, state) - value_for(passive, state),
    ), states)
    return (; beliefs, catalog, closure, libraries, states, process, values, horizon)
end

"""Family B: isolate frontier and closure changes and their value channels."""
function run_frontier_closure_family(config)
    settings = config["frontier_closure"]
    fixture = _decomposition_fixture(Int(settings["horizon"]))
    base = fixture.values.base
    frontier_change = fixture.values.operational
    closure_change = fixture.values.generative

    _require_pattern(
        fixture.states.base.closure == fixture.states.operational.closure,
        "B-HOLD-CLOSURE",
        "frontier comparison changed closure",
    )
    _require_pattern(
        fixture.states.base.frontier != fixture.states.operational.frontier,
        "B-CHANGE-FRONTIER",
        "frontier comparison did not change frontier",
    )
    _require_pattern(
        frontier_change.passive - base.passive == 3 &&
        frontier_change.premium == base.premium,
        "B-FRONTIER-CHANNEL",
        "frontier change did not isolate passive value",
    )
    _require_pattern(
        fixture.states.base.frontier == fixture.states.generative.frontier,
        "B-HOLD-FRONTIER",
        "closure comparison changed frontier",
    )
    _require_pattern(
        fixture.states.base.closure != fixture.states.generative.closure,
        "B-CHANGE-CLOSURE",
        "closure comparison did not change closure",
    )
    _require_pattern(
        closure_change.passive == base.passive &&
        closure_change.premium - base.premium == 4,
        "B-CLOSURE-CHANNEL",
        "closure change did not isolate the research premium",
    )

    raw = NamedTuple[]
    for (case_id, before, after, note) in (
        ("frontier-only", base, frontier_change, "closure fixed"),
        ("closure-only", base, closure_change, "frontier fixed"),
    )
        for metric in (:full, :passive, :premium)
            difference = getproperty(after, metric) - getproperty(before, metric)
            push!(raw, _observation(
                "B", case_id, string(metric), "value-change";
                exact_value = difference,
                expected = case_id == "frontier-only" ?
                           "passive changes; premium fixed" :
                           "passive fixed; premium changes",
                notes = note,
            ))
        end
    end
    return (
        summary = _summary(
            "B",
            "Frontier–closure sufficiency",
            settings["arithmetic"],
            2,
            settings["expected"],
            "frontier-only: Δpassive=3//1, Δpremium=0//1; closure-only: Δpassive=0//1, Δpremium=4//1",
            6,
            "Exact F5/F6 mechanism fixture; it does not establish raw-model T2.",
        ),
        raw,
        fixture,
    )
end

"""Family C: delete two strategies only after checking both redundancy predicates."""
function run_safe_deletion_family(config)
    settings = config["safe_deletion"]
    horizon = Int(settings["horizon"])
    beliefs = FiniteBeliefSpace([:only])
    modules = [GenerativeModule(:key)]
    empty_modules = ModuleSet{Symbol}()
    key = ModuleSet([ModuleId(:key)])
    strategies = [
        Strategy(:inactive, OperationalProfile(beliefs, [0]), empty_modules),
        Strategy(:leader, OperationalProfile(beliefs, [2]), key),
        Strategy(:operational_duplicate, OperationalProfile(beliefs, [1]), empty_modules),
        Strategy(:generative_duplicate, OperationalProfile(beliefs, [0]), key),
    ]
    catalog = StrategyCatalog(beliefs, modules, strategies, StrategyId(:inactive))
    closure = identity_generative_closure(modules)
    source = RawLibrary(catalog, [row.id for row in strategies])
    deletion_ids = (StrategyId(:operational_duplicate), StrategyId(:generative_duplicate))
    current = source
    raw = NamedTuple[]
    for (step, strategy_id) in enumerate(deletion_ids)
        operational = operationally_redundant(catalog, current, strategy_id)
        generative = generatively_redundant(catalog, closure, current, strategy_id)
        _require_pattern(
            operational && generative,
            "C-REDUNDANCY-$step",
            "deletion did not preserve both components",
        )
        push!(raw, _observation(
            "C", "stepwise-safe-deletion", "step-$step", "redundancy-predicates";
            exact_value = "operational=$operational;generative=$generative",
            expected = "both true",
            notes = "delete=$(strategy_id.id)",
        ))
        current = innovation_safe_delete(catalog, closure, current, strategy_id)
    end
    final = current
    source_state = compressed_state(catalog, closure, source)
    final_state = compressed_state(catalog, closure, final)
    _require_pattern(source_state == final_state, "C-COMPRESSED-STATE", "safe deletion changed K")

    future_state = CompressedLibraryState(OperationalProfile(beliefs, [8]), key)
    process = DiscountedResearchProcess(
        [source_state, future_state],
        [ResearchProject(:innovate, key)],
        MarkovKernel(beliefs, reshape([1], 1, 1)),
        (belief, state, project) -> dirac(future_state),
        (belief, state, project) -> 0,
        project -> 0,
        1 // 2,
    )
    before = _library_evaluation(process, horizon, source_state)
    after = _library_evaluation(process, horizon, final_state)
    _require_pattern(before.values == after.values, "C-VALUE", "safe deletion changed value")
    _require_pattern(before.policy == after.policy, "C-POLICY", "safe deletion changed policy")
    push!(raw, _observation(
        "C", "stepwise-safe-deletion", "endpoint", "dynamic-invariance";
        exact_value = only(before.values),
        action = only(before.policy),
        expected = "source equals compressed endpoint",
        notes = "source_size=$(length(source)); final_size=$(length(final))",
    ))
    return (
        summary = _summary(
            "C",
            "Safe deletion",
            settings["arithmetic"],
            2,
            settings["expected"],
            "two stepwise deletions reduced 4 strategies to 2 with identical K, horizon-$horizon value, and policy",
            7,
            "Computational F3 counterpart; deletion is rechecked at every intermediate library.",
        ),
        raw,
        source,
        final,
        source_state,
        final_state,
        before,
        after,
    )
end

function _frontier_pruning_case(reward::Integer)
    reward >= 0 || throw(ArgumentError("future reward must be nonnegative"))
    beliefs = FiniteBeliefSpace([:only])
    modules = [GenerativeModule(:key)]
    empty_modules = ModuleSet{Symbol}()
    key = ModuleSet([ModuleId(:key)])
    strategies = [
        Strategy(:inactive, OperationalProfile(beliefs, [0]), empty_modules),
        Strategy(:bridge, OperationalProfile(beliefs, [0]), key),
        Strategy(:future, OperationalProfile(beliefs, [reward]), empty_modules),
    ]
    catalog = StrategyCatalog(beliefs, modules, strategies, StrategyId(:inactive))
    closure = identity_generative_closure(modules)
    unpruned = RawLibrary(catalog, [StrategyId(:inactive), StrategyId(:bridge)])
    pruned = frontier_only_prune(catalog, unpruned)
    unpruned_state = compressed_state(catalog, closure, unpruned)
    pruned_state = compressed_state(catalog, closure, pruned)
    future_library = RawLibrary(catalog, [StrategyId(:inactive), StrategyId(:future)])
    future_state = compressed_state(catalog, closure, future_library)
    states = unpruned_state == future_state ? [pruned_state, unpruned_state] :
             pruned_state == future_state ? [pruned_state, unpruned_state] :
             [pruned_state, unpruned_state, future_state]
    process = DiscountedResearchProcess(
        states,
        [ResearchProject(:innovate, key)],
        MarkovKernel(beliefs, reshape([1], 1, 1)),
        (belief, state, project) ->
            dirac(ModuleId(:key) in state.closure ? future_state : pruned_state),
        (belief, state, project) -> 0,
        project -> 0,
        1 // 2,
    )
    values = finite_horizon_value(process, 2)
    value(state) = values[1, findfirst(isequal(state), process.compressed_states)]
    loss = value(unpruned_state) - value(pruned_state)
    return (;
        reward = exact_rational(reward),
        loss,
        catalog,
        closure,
        unpruned,
        pruned,
        unpruned_state,
        pruned_state,
        process,
    )
end

"""Family D: scale the enabled future payoff in the exact F4 construction."""
function run_frontier_pruning_family(config)
    settings = config["frontier_pruning"]
    rewards = Int.(settings["future_rewards"])
    cases = NamedTuple[]
    raw = NamedTuple[]
    for reward in rewards
        case = _frontier_pruning_case(reward)
        _require_pattern(
            frontier(case.catalog, case.unpruned) == frontier(case.catalog, case.pruned),
            "D-FRONTIER-$reward",
            "frontier-only rule changed the current frontier",
        )
        _require_pattern(
            generative_closure(case.catalog, case.closure, case.unpruned) !=
            generative_closure(case.catalog, case.closure, case.pruned),
            "D-CLOSURE-$reward",
            "frontier-only rule did not remove the key closure",
        )
        _require_pattern(
            case.loss == case.reward / 2,
            "D-LOSS-$reward",
            "loss was $(case.loss), expected $(case.reward / 2)",
        )
        push!(cases, case)
        push!(raw, _observation(
            "D", "scaled-frontier-pruning", "reward-$reward", "pruning-loss";
            parameter = "future_reward",
            parameter_value = _rational_string(case.reward),
            exact_value = case.loss,
            expected = "future_reward/2",
            notes = "frontier preserved; closure changed",
        ))
    end
    positive_cases = filter(case -> case.reward > 0, cases)
    _require_pattern(
        all(index -> positive_cases[index].loss > positive_cases[index - 1].loss,
            2:length(positive_cases)),
        "D-MONOTONE-SCALING",
        "loss did not strictly grow with positive future rewards",
    )
    return (
        summary = _summary(
            "D",
            "Frontier-only pruning failure",
            settings["arithmetic"],
            length(cases),
            settings["expected"],
            "all $(length(cases)) cases satisfy loss=future_reward/2; maximum loss=$(_rational_string(last(cases).loss))",
            3 * length(cases) + 1,
            "Exact supporting F4 construction; arbitrary loss comes from reward scaling, not normalized T4.",
        ),
        raw,
        cases,
    )
end

"""Family E: operational-only, generative-only, and mixed insertions."""
function run_decomposition_family(config)
    settings = config["value_decomposition"]
    fixture = _decomposition_fixture(Int(settings["horizon"]))
    base = fixture.values.base
    cases = NamedTuple[]
    raw = NamedTuple[]
    for (case_id, values) in (
        ("operational-only", fixture.values.operational),
        ("generative-only", fixture.values.generative),
        ("both-components", fixture.values.both),
    )
        total = values.full - base.full
        operational = values.passive - base.passive
        generative = values.premium - base.premium
        _require_pattern(
            total == operational + generative,
            "E-DECOMPOSITION-$case_id",
            "total innovation did not decompose exactly",
        )
        push!(cases, (; case_id, total, operational, generative))
        for (metric, value) in (
            ("total_innovation", total),
            ("operational_innovation", operational),
            ("generative_innovation", generative),
        )
            push!(raw, _observation(
                "E", case_id, metric, "innovation-component";
                exact_value = value,
                expected = "total=operational+generative",
            ))
        end
    end
    _require_pattern(
        cases[1].operational > 0 && cases[1].generative == 0,
        "E-OPERATIONAL-ONLY",
        "operational-only case did not isolate the operational channel",
    )
    _require_pattern(
        cases[2].operational == 0 && cases[2].generative > 0,
        "E-GENERATIVE-ONLY",
        "generative-only case did not isolate the generative channel",
    )
    _require_pattern(
        cases[3].operational > 0 && cases[3].generative > 0,
        "E-BOTH",
        "mixed case did not have both components",
    )
    return (
        summary = _summary(
            "E",
            "Value decomposition",
            settings["arithmetic"],
            3,
            settings["expected"],
            "operational-only=(3,0), generative-only=(0,4), both=(3,1) for (operational,generative)",
            6,
            "Exact F6 accounting mechanism; no unconditional general sign claim is inferred.",
        ),
        raw,
        cases,
        fixture,
    )
end

function _identity_matrix(::Type{T}, count::Int) where {T}
    return T[row == column ? 1 : 0 for row in 1:count, column in 1:count]
end

function _exact_matrix(rows)
    row_count = length(rows)
    row_count > 0 || throw(ArgumentError("an exact matrix requires at least one row"))
    column_count = length(first(rows))
    all(length(row) == column_count for row in rows) ||
        throw(DimensionMismatch("all exact-matrix rows must have equal length"))
    return ExactRational[
        exact_rational(rows[row][column]) for row in 1:row_count, column in 1:column_count
    ]
end

function _date_first_coverage_value(
    transition::AbstractMatrix{ExactRational},
    gap::AbstractVector{ExactRational},
    initial_belief::Integer,
    discount::ExactRational,
    survival::ExactRational,
    horizon::Integer,
)
    count = length(gap)
    size(transition) == (count, count) ||
        throw(DimensionMismatch("transition and gap dimensions must agree"))
    initial_belief in 1:count || throw(BoundsError(gap, initial_belief))
    horizon >= 0 || throw(ArgumentError("coverage horizon must be nonnegative"))
    distribution = zeros(ExactRational, count)
    distribution[initial_belief] = exact_rational(1)
    effective_discount = discount * survival
    value = exact_rational(0)
    for date_index in 1:horizon
        value += effective_discount^(date_index - 1) * sum(distribution .* gap)
        distribution = ExactRational[
            sum(distribution[row] * transition[row, column] for row in 1:count)
            for column in 1:count
        ]
    end
    return value
end

function _unique_descending_ranks(scores)
    length(unique(scores)) == length(scores) ||
        throw(ArgumentError("ranking scores must be unique in the exact fixture"))
    order = sortperm(scores; rev = true)
    ranks = zeros(Int, length(scores))
    for (rank, index) in enumerate(order)
        ranks[index] = rank
    end
    return ranks, order
end

function _exact_spearman(left_ranks, right_ranks)
    length(left_ranks) == length(right_ranks) ||
        throw(DimensionMismatch("rank vectors must have equal length"))
    count = length(left_ranks)
    count >= 2 || throw(ArgumentError("Spearman correlation requires two candidates"))
    squared_distance = sum((left_ranks[index] - right_ranks[index])^2 for index in 1:count)
    return exact_rational(1) -
           exact_rational(6 * squared_distance) /
           exact_rational(count * (count^2 - 1))
end

function _coverage_ranking_fixture(settings)
    transition = _exact_matrix(settings["transition"])
    count = size(transition, 1)
    size(transition, 2) == count ||
        throw(DimensionMismatch("coverage-ranking transition must be square"))
    space = FiniteBeliefSpace(collect(1:count))
    kernel = MarkovKernel(space, transition)
    initial_belief = Int(settings["initial_belief"])
    horizon = Int(settings["horizon"])
    discount = exact_rational(settings["discount"])
    survival = exact_rational(settings["survival"])
    expected = settings["expected"]

    candidates = [
        (;
            candidate_id = candidate["candidate_id"],
            gap = ExactRational[exact_rational(value) for value in candidate["gap"]],
            novelty = exact_rational(candidate["raw_parameter_novelty"]),
            stable_error = exact_rational(candidate["stable_score_error"]),
            stress_error = exact_rational(candidate["stress_score_error"]),
        )
        for candidate in settings["candidates"]
    ]
    all(length(candidate.gap) == count for candidate in candidates) ||
        throw(DimensionMismatch("every candidate gap must match the belief grid"))
    all(all(value >= 0 for value in candidate.gap) for candidate in candidates) ||
        throw(ArgumentError("every certified candidate gap must be nonnegative"))

    candidate_rows = NamedTuple[]
    coverage_scores = ExactRational[]
    target_values = ExactRational[]
    current_scores = ExactRational[]
    average_scores = ExactRational[]
    novelty_scores = ExactRational[]
    for candidate in candidates
        potential = finite_coverage_potential(
            kernel,
            candidate.gap,
            discount,
            horizon;
            survival,
        )[initial_belief]
        target = _date_first_coverage_value(
            transition,
            candidate.gap,
            initial_belief,
            discount,
            survival,
            horizon,
        )
        _require_pattern(
            potential == target,
            "F-RANKING-IDENTITY-$(candidate.candidate_id)",
            "occupation-first coverage potential did not equal date-first gross value",
        )
        push!(coverage_scores, potential)
        push!(target_values, target)
        push!(current_scores, candidate.gap[initial_belief])
        push!(average_scores, sum(candidate.gap) / exact_rational(count))
        push!(novelty_scores, candidate.novelty)
    end

    target_ranks, target_order = _unique_descending_ranks(target_values)
    score_vectors = (
        coverage_potential = coverage_scores,
        current_belief_improvement = current_scores,
        average_gap = average_scores,
        raw_parameter_novelty = novelty_scores,
    )
    rank_vectors = Dict{Symbol,Vector{Int}}()
    orders = Dict{Symbol,Vector{Int}}()
    ranking_summary = NamedTuple[]
    best_target = maximum(target_values)
    for (method, scores) in pairs(score_vectors)
        ranks, order = _unique_descending_ranks(scores)
        rank_vectors[method] = ranks
        orders[method] = order
        selected = first(order)
        push!(ranking_summary, (;
            method = string(method),
            spearman_rank_correlation = _exact_spearman(ranks, target_ranks),
            top_candidate = candidates[selected].candidate_id,
            top_candidate_value = target_values[selected],
            top_one_regret = best_target - target_values[selected],
        ))
    end
    summary_by_method = Dict(Symbol(row.method) => row for row in ranking_summary)
    configured_order = String.(expected["coverage_order"])
    observed_order = [candidates[index].candidate_id for index in target_order]
    _require_pattern(
        observed_order == configured_order,
        "F-RANKING-ORDER",
        "coverage order $(observed_order) differs from the preregistered order $(configured_order)",
    )
    _require_pattern(
        summary_by_method[:coverage_potential].spearman_rank_correlation == exact_rational(1),
        "F-RANKING-SPEARMAN",
        "coverage potential did not recover the exact target ranking",
    )
    for method in (:current_belief_improvement, :average_gap, :raw_parameter_novelty)
        _require_pattern(
            summary_by_method[:coverage_potential].spearman_rank_correlation >
            summary_by_method[method].spearman_rank_correlation,
            "F-RANKING-DOMINATES-$(uppercase(string(method)))",
            "coverage did not rank the exact target more accurately than $method",
        )
        _require_pattern(
            summary_by_method[method].top_one_regret > 0,
            "F-RANKING-REGRET-$(uppercase(string(method)))",
            "$method unexpectedly had zero top-one regret",
        )
    end
    _require_pattern(
        summary_by_method[:coverage_potential].top_one_regret == 0,
        "F-RANKING-ZERO-REGRET",
        "coverage potential did not select the target-maximizing candidate",
    )
    _require_pattern(
        summary_by_method[:current_belief_improvement].top_candidate == expected["current_belief_top"] &&
        summary_by_method[:average_gap].top_candidate == expected["average_gap_top"] &&
        summary_by_method[:raw_parameter_novelty].top_candidate == expected["raw_parameter_novelty_top"],
        "F-RANKING-COMPARATOR-TOPS",
        "one or more preregistered comparator top candidates changed",
    )

    top_margin = target_values[target_order[1]] - target_values[target_order[2]]
    _require_pattern(
        top_margin == exact_rational(expected["top_margin"]),
        "F-RANKING-TOP-MARGIN",
        "top-two target separation changed",
    )
    stable_bound = exact_rational(expected["stable_error_bound"])
    stress_bound = exact_rational(expected["stress_error_bound"])
    stable_scores = ExactRational[
        coverage_scores[index] + candidates[index].stable_error for index in eachindex(candidates)
    ]
    stress_scores = ExactRational[
        coverage_scores[index] + candidates[index].stress_error for index in eachindex(candidates)
    ]
    stable_ranks, stable_order = _unique_descending_ranks(stable_scores)
    stress_ranks, stress_order = _unique_descending_ranks(stress_scores)
    _require_pattern(
        all(abs(candidate.stable_error) <= stable_bound for candidate in candidates),
        "F-RANKING-STABLE-ERROR-BOUND",
        "stable score perturbation exceeded its preregistered bound",
    )
    _require_pattern(
        top_margin > 2 * stable_bound,
        "F-RANKING-STABLE-MARGIN",
        "top-two separation is insufficient for the bounded-error guarantee",
    )
    _require_pattern(
        candidates[first(stable_order)].candidate_id == expected["stable_top"],
        "F-RANKING-STABLE-TOP",
        "bounded exact perturbation changed the separated top candidate",
    )
    _require_pattern(
        all(abs(candidate.stress_error) <= stress_bound for candidate in candidates),
        "F-RANKING-STRESS-ERROR-BOUND",
        "stress score perturbation exceeded its preregistered bound",
    )
    _require_pattern(
        top_margin <= 2 * stress_bound,
        "F-RANKING-STRESS-MARGIN",
        "stress perturbation did not cross the separation boundary",
    )
    _require_pattern(
        candidates[first(stress_order)].candidate_id == expected["stress_top"],
        "F-RANKING-STRESS-TOP",
        "stress perturbation did not produce the preregistered top candidate",
    )

    for index in eachindex(candidates)
        push!(candidate_rows, (;
            candidate_id = candidates[index].candidate_id,
            gap = join(_rational_string.(candidates[index].gap), ";"),
            coverage_potential = coverage_scores[index],
            date_first_target = target_values[index],
            current_belief_improvement = current_scores[index],
            average_gap = average_scores[index],
            raw_parameter_novelty = novelty_scores[index],
            true_rank = target_ranks[index],
            coverage_rank = rank_vectors[:coverage_potential][index],
            current_belief_rank = rank_vectors[:current_belief_improvement][index],
            average_gap_rank = rank_vectors[:average_gap][index],
            novelty_rank = rank_vectors[:raw_parameter_novelty][index],
            stable_score_error = candidates[index].stable_error,
            stable_estimated_score = stable_scores[index],
            stable_rank = stable_ranks[index],
            stress_score_error = candidates[index].stress_error,
            stress_estimated_score = stress_scores[index],
            stress_rank = stress_ranks[index],
        ))
    end

    value_of_gap = gap -> _date_first_coverage_value(
        transition,
        gap,
        initial_belief,
        discount,
        survival,
        horizon,
    )
    selection_count = Int(settings["selection_count"])
    selection_count in 1:length(candidates) ||
        throw(ArgumentError("coverage selection count must index the candidate set"))
    individual_order = orders[:coverage_potential][1:selection_count]
    individual_rows = NamedTuple[]
    union_gap = zeros(ExactRational, count)
    prior_value = exact_rational(0)
    for (step, index) in enumerate(individual_order)
        union_gap = max.(union_gap, candidates[index].gap)
        cumulative_value = value_of_gap(union_gap)
        push!(individual_rows, (;
            method = "individual-coverage-top-k",
            step,
            selected_candidate = candidates[index].candidate_id,
            marginal_value = cumulative_value - prior_value,
            cumulative_set_value = cumulative_value,
        ))
        prior_value = cumulative_value
    end

    marginal_rows = NamedTuple[]
    remaining = collect(eachindex(candidates))
    union_gap = zeros(ExactRational, count)
    prior_value = exact_rational(0)
    for step in 1:selection_count
        marginal_values = ExactRational[
            value_of_gap(max.(union_gap, candidates[index].gap)) - prior_value
            for index in remaining
        ]
        best_remaining = argmax(marginal_values)
        selected_index = remaining[best_remaining]
        union_gap = max.(union_gap, candidates[selected_index].gap)
        cumulative_value = value_of_gap(union_gap)
        push!(marginal_rows, (;
            method = "sequential-marginal-coverage",
            step,
            selected_candidate = candidates[selected_index].candidate_id,
            marginal_value = cumulative_value - prior_value,
            cumulative_set_value = cumulative_value,
        ))
        prior_value = cumulative_value
        deleteat!(remaining, best_remaining)
    end
    individual_ids = getfield.(individual_rows, :selected_candidate)
    marginal_ids = getfield.(marginal_rows, :selected_candidate)
    _require_pattern(
        individual_ids == String.(expected["individual_selection"]),
        "F-RANKING-INDIVIDUAL-SELECTION",
        "individual-score selection differed from its preregistered order",
    )
    _require_pattern(
        marginal_ids == String.(expected["marginal_selection"]),
        "F-RANKING-MARGINAL-SELECTION",
        "marginal-coverage selection differed from its preregistered order",
    )
    _require_pattern(
        last(individual_rows).cumulative_set_value == exact_rational(expected["individual_set_value"]),
        "F-RANKING-INDIVIDUAL-VALUE",
        "individual-score set value changed",
    )
    _require_pattern(
        last(marginal_rows).cumulative_set_value == exact_rational(expected["marginal_set_value"]),
        "F-RANKING-MARGINAL-VALUE",
        "marginal-coverage set value changed",
    )
    _require_pattern(
        last(marginal_rows).cumulative_set_value > last(individual_rows).cumulative_set_value,
        "F-RANKING-REDUNDANCY",
        "marginal selection did not improve on redundant individual top-k selection",
    )

    return (;
        transition,
        kernel,
        initial_belief,
        horizon,
        discount,
        survival,
        candidates,
        candidate_rows,
        ranking_summary,
        individual_selection = individual_rows,
        marginal_selection = marginal_rows,
        occupation = finite_discounted_occupation(kernel, discount, horizon; survival),
        top_margin,
        stable_bound,
        stress_bound,
    )
end

"""Family F: exact coverage geometry plus a prospective fixed-candidate ranking fixture."""
function run_coverage_family(config)
    settings = config["coverage_geometry"]
    weak_cost = exact_rational(settings["weak_cost"])
    strict_cost = exact_rational(settings["strict_cost"])
    cases = NamedTuple[]
    raw = NamedTuple[]

    monotone_space = FiniteBeliefSpace(collect(0:3))
    monotone_kernel = MarkovKernel(monotone_space, _identity_matrix(Int, 4))
    monotone_gap = ExactRational[0, 1, 2, 3]
    monotone_survival = ExactRational[1 // 4, 1 // 2, 3 // 4, 1]
    monotone_potential = gross_coverage_value(monotone_kernel, monotone_gap, 1; survival = monotone_survival)
    monotone_cost = ExactRational[2, 1, 1 // 2, 0]
    monotone_region = research_region(monotone_potential, monotone_cost)
    _require_pattern(is_stochastically_monotone(monotone_kernel), "F-MONOTONE-KERNEL", "identity kernel rejected")
    _require_pattern(is_monotone_sequence(monotone_potential), "F-MONOTONE-POTENTIAL", "potential is not monotone")
    _require_pattern(monotone_region == Bool[false, false, true, true], "F-MONOTONE-REGION", "threshold region mismatch")
    push!(cases, (;
        case_id = "monotone-gap",
        gap = monotone_gap,
        potential = monotone_potential,
        region = monotone_region,
        kernel_assumption = true,
        components = component_count(monotone_region),
    ))

    peak_space = FiniteBeliefSpace(collect(0:4))
    peak_kernel = MarkovKernel(peak_space, _identity_matrix(Int, 5))
    peak_gap = ExactRational[0, 2, 4, 2, 0]
    peak_potential = gross_coverage_value(peak_kernel, peak_gap, 1)
    peak_region = research_region(peak_potential, weak_cost)
    _require_pattern(is_single_peaked(peak_gap), "F-SINGLE-PEAK", "input gap is not single-peaked")
    _require_pattern(is_single_peaked(peak_potential), "F-PEAK-PRESERVED", "identity kernel did not preserve the peak")
    _require_pattern(component_count(peak_region) == 1, "F-PEAK-CONNECTED", "preserving case disconnected")
    push!(cases, (;
        case_id = "single-peak-preserved",
        gap = peak_gap,
        potential = peak_potential,
        region = peak_region,
        kernel_assumption = true,
        components = component_count(peak_region),
    ))

    destructive_space = FiniteBeliefSpace(collect(0:2))
    destructive_kernel = MarkovKernel(destructive_space, [0 1 0; 1 0 0; 0 1 0])
    destructive_gap = ExactRational[0, 1, 0]
    destructive_potential = gross_coverage_value(destructive_kernel, destructive_gap, 1)
    destructive_region = research_region(destructive_potential, weak_cost)
    _require_pattern(!is_stochastically_monotone(destructive_kernel), "F-FAILED-ASSUMPTION", "destructive kernel unexpectedly satisfies FOSD monotonicity")
    _require_pattern(destructive_potential == ExactRational[1, 0, 1], "F-DESTRUCTIVE-POTENTIAL", "counterexample potential mismatch")
    _require_pattern(component_count(destructive_region) == 2, "F-DESTRUCTIVE-REGION", "counterexample did not disconnect")
    push!(cases, (;
        case_id = "single-peak-destroyed",
        gap = destructive_gap,
        potential = destructive_potential,
        region = destructive_region,
        kernel_assumption = false,
        components = component_count(destructive_region),
    ))

    bernstein_kernel = MarkovKernel(
        peak_space,
        [
            1 0 0 0 0
            81 // 256 108 // 256 54 // 256 12 // 256 1 // 256
            1 // 16 4 // 16 6 // 16 4 // 16 1 // 16
            1 // 256 12 // 256 54 // 256 108 // 256 81 // 256
            0 0 0 0 1
        ],
    )
    two_gap = ExactRational[4, 0, 0, 0, 4]
    two_potential = gross_coverage_value(bernstein_kernel, two_gap, 1)
    two_region = research_region(two_potential, strict_cost; strict = true)
    _require_pattern(
        two_potential == ExactRational[4, 41 // 32, 1 // 2, 41 // 32, 4],
        "F-TWO-GAP-POTENTIAL",
        "C2 potential mismatch",
    )
    _require_pattern(component_count(two_region) == 2, "F-TWO-GAP-REGION", "C2 region did not have two components")
    push!(cases, (;
        case_id = "two-gap-candidate",
        gap = two_gap,
        potential = two_potential,
        region = two_region,
        kernel_assumption = is_stochastically_monotone(bernstein_kernel),
        components = component_count(two_region),
    ))

    for case in cases
        count = length(case.gap)
        for index in 1:count
            push!(raw, _observation(
                "F", case.case_id, "belief-$index", "coverage-geometry";
                belief_index = index,
                coordinate = count == 1 ? 0.0 : (index - 1) / (count - 1),
                exact_value = "gap=$(_rational_string(case.gap[index]));potential=$(_rational_string(case.potential[index]))",
                action = case.region[index] ? "research" : "continue",
                expected = "component_count=$(case.components)",
                notes = "kernel_preservation_assumption=$(case.kernel_assumption)",
            ))
        end
    end
    ranking = _coverage_ranking_fixture(config["coverage_ranking"])
    for row in ranking.candidate_rows
        push!(raw, _observation(
            "F", "prospective-ranking", row.candidate_id, "coverage-ranking";
            exact_value = "coverage=$(_rational_string(row.coverage_potential));target=$(_rational_string(row.date_first_target))",
            action = "coverage_rank=$(row.coverage_rank)",
            expected = "identity and exact rank recovery",
            notes = "current_rank=$(row.current_belief_rank);average_rank=$(row.average_gap_rank);novelty_rank=$(row.novelty_rank);stable_rank=$(row.stable_rank);stress_rank=$(row.stress_rank)",
        ))
    end
    for row in vcat(ranking.individual_selection, ranking.marginal_selection)
        push!(raw, _observation(
            "F", "prospective-set-selection", "$(row.method)-$(row.step)", "coverage-set-selection";
            parameter = "selection_step",
            parameter_value = row.step,
            exact_value = "marginal=$(_rational_string(row.marginal_value));cumulative=$(_rational_string(row.cumulative_set_value))",
            action = row.selected_candidate,
            expected = "preregistered selection order",
            notes = row.method,
        ))
    end
    return (
        summary = _summary(
            "F",
            "Coverage geometry and prospective ranking",
            settings["arithmetic"],
            6,
            settings["expected"],
            "geometry components=(1,1,2,2); exact rank correlation=1; bounded-error top preserved; marginal top-2 value=69//4 versus redundant individual top-2 value=10//1",
            37,
            "Exact S4/S5/C2 mechanism and limitation fixtures; ranking recovery holds only because the prospective target is the same fixed-candidate gross occupation value. Candidate T6 remains unproved.",
        ),
        raw,
        cases,
        ranking,
    )
end

function _gaussian_policy_kernel(space, coordinates; precision::Float64, persistence::Float64)
    precision > 0 || throw(ArgumentError("signal scale must be positive"))
    0 <= persistence <= 1 || throw(ArgumentError("persistence must lie in [0,1]"))
    count = length(coordinates)
    transition = Matrix{Float64}(undef, count, count)
    for row in 1:count
        center = persistence * coordinates[row] + (1 - persistence) * 0.5
        weights = [exp(-0.5 * ((coordinate - center) / precision)^2) for coordinate in coordinates]
        transition[row, :] .= weights ./ sum(weights)
    end
    return MarkovKernel(space, transition; mode = Float64Mode(), atol = 5e-14)
end

function _policy_scenarios(settings)
    baseline = (
        cost = Float64(settings["baseline_cost"]),
        delay = Int(settings["baseline_delay"]),
        persistence = Float64(settings["baseline_persistence"]),
        discount = Float64(settings["baseline_discount"]),
    )
    scenarios = NamedTuple[]
    for (axis, values) in (
        ("cost", settings["costs"]),
        ("delay", settings["delays"]),
        ("persistence", settings["persistences"]),
        ("discount", settings["discounts"]),
    )
        for (level, value) in zip(("low", "baseline", "high"), values)
            push!(scenarios, (;
                scenario_id = "$axis-$level",
                axis,
                level,
                axis_value = Float64(value),
                cost = axis == "cost" ? Float64(value) : baseline.cost,
                delay = axis == "delay" ? Int(value) : baseline.delay,
                persistence = axis == "persistence" ? Float64(value) : baseline.persistence,
                discount = axis == "discount" ? Float64(value) : baseline.discount,
            ))
        end
    end
    return scenarios
end

function _dynamic_policy_case(settings, scenario, coordinates, success_probabilities)
    belief_count = length(coordinates)
    space = FiniteBeliefSpace(collect(1:belief_count))
    kernel = _gaussian_policy_kernel(
        space,
        coordinates;
        precision = Float64(settings["signal_scale"]),
        persistence = scenario.persistence,
    )
    empty_modules = ModuleSet{Symbol}()
    baseline = CompressedLibraryState(
        OperationalProfile(space, @. 0.12 + 0.18 * coordinates; mode = Float64Mode()),
        empty_modules,
    )
    adopted = CompressedLibraryState(
        OperationalProfile(space, @. 0.85 + 1.40 * coordinates; mode = Float64Mode()),
        empty_modules,
    )
    project = ResearchProject(:innovate, empty_modules)
    process = DiscountedResearchProcess(
        [baseline, adopted],
        [project],
        kernel,
        (belief, state, selected) -> begin
            state == adopted && return FloatProb([adopted], [1.0])
            index = belief_index(space, belief)
            probability_success = success_probabilities[index]
            return FloatProb(
                [baseline, adopted],
                [1 - probability_success, probability_success],
            )
        end,
        (belief, state, selected) -> scenario.cost,
        selected -> scenario.delay,
        scenario.discount,
    )
    result = value_iteration(
        process;
        tolerance = Float64(settings["value_tolerance"]),
        max_iterations = Int(settings["maximum_iterations"]),
        throw_on_nonconvergence = true,
    )
    baseline_index = findfirst(isequal(baseline), process.compressed_states)
    policy = result.policy[:, baseline_index]
    region = [action isa ResearchAction for action in policy]
    continue_values = Float64[]
    research_values = Float64[]
    for belief in process.beliefs
        push!(continue_values, continue_value(process, result.values, belief, baseline))
        push!(research_values, research_value(process, result.values, belief, baseline, project.id))
    end
    return (;
        scenario...,
        process,
        baseline,
        adopted,
        result,
        region,
        continue_values,
        research_values,
        advantages = research_values .- continue_values,
        components = component_count(region),
        research_count = count(identity, region),
        cutoff = any(region) ? coordinates[findfirst(identity, region)] : missing,
    )
end

"""Family G: map solved dynamic policies over four one-at-a-time parameters."""
function run_dynamic_policy_family(config, rng; grid_size_override = nothing)
    settings = config["dynamic_policy"]
    grid_size = isnothing(grid_size_override) ?
                Int(settings["belief_grid_size"]) : Int(grid_size_override)
    grid_size >= 11 || throw(ArgumentError("dynamic-policy grid needs at least 11 beliefs"))
    coordinates = collect(range(0.0, 1.0; length = grid_size))
    increments = 0.8 .+ 0.4 .* rand(rng, grid_size)
    cumulative = cumsum(increments)
    cumulative ./= last(cumulative)
    success_probabilities = 0.08 .+ 0.84 .* cumulative
    scenarios = [
        _dynamic_policy_case(settings, scenario, coordinates, success_probabilities)
        for scenario in _policy_scenarios(settings)
    ]
    raw = NamedTuple[]
    policy_summary = NamedTuple[]
    for case in scenarios
        _require_pattern(case.result.converged, "G-CONVERGENCE-$(case.scenario_id)", "value iteration did not converge")
        _require_pattern(case.components <= 1, "G-THRESHOLD-$(case.scenario_id)", "policy region is disconnected")
        for index in eachindex(coordinates)
            push!(raw, _observation(
                "G", case.scenario_id, "belief-$index", "dynamic-policy";
                belief_index = index,
                coordinate = coordinates[index],
                parameter = case.axis,
                parameter_value = case.axis_value,
                float_value = case.result.values[index, 1],
                action = case.region[index] ? "research" : "continue",
                expected = "solved Bellman policy",
                notes = "advantage=$(case.advantages[index]); success=$(success_probabilities[index])",
            ))
        end
        push!(policy_summary, (;
            scenario_id = case.scenario_id,
            axis = case.axis,
            level = case.level,
            axis_value = case.axis_value,
            cost = case.cost,
            delay = case.delay,
            persistence = case.persistence,
            discount = case.discount,
            research_beliefs = case.research_count,
            total_beliefs = grid_size,
            component_count = case.components,
            cutoff_coordinate = case.cutoff,
            iterations = case.result.iterations,
            bellman_residual = case.result.residual,
            posterior_error_bound = case.result.posterior_error_bound,
            converged = case.result.converged,
        ))
    end
    by_axis(axis) = filter(case -> case.axis == axis, scenarios)
    cost_cases = by_axis("cost")
    delay_cases = by_axis("delay")
    discount_cases = by_axis("discount")
    persistence_cases = by_axis("persistence")
    cost_counts = getfield.(cost_cases, :research_count)
    delay_counts = getfield.(delay_cases, :research_count)
    discount_counts = getfield.(discount_cases, :research_count)
    persistence_counts = getfield.(persistence_cases, :research_count)
    _require_pattern(issorted(cost_counts; rev = true), "G-COST", "research region did not shrink with cost")
    _require_pattern(issorted(delay_counts; rev = true), "G-DELAY", "research region did not shrink with delay")
    _require_pattern(issorted(discount_counts), "G-DISCOUNT", "research region did not expand with discount")
    _require_pattern(length(unique(cost_counts)) > 1, "G-COST-RESPONSIVE", "cost variation did not move policy")
    _require_pattern(length(unique(delay_counts)) > 1, "G-DELAY-RESPONSIVE", "delay variation did not move policy")
    _require_pattern(length(unique(discount_counts)) > 1, "G-DISCOUNT-RESPONSIVE", "discount variation did not move policy")
    _require_pattern(length(unique(persistence_counts)) > 1, "G-PERSISTENCE-RESPONSIVE", "persistence variation did not move policy")
    _require_pattern(
        any(case -> any(case.region), scenarios) && any(case -> any(.!case.region), scenarios),
        "G-NONDEGENERATE",
        "policy map lacks both continue and research actions",
    )
    return (
        summary = _summary(
            "G",
            "Dynamic research policy",
            settings["arithmetic"],
            length(scenarios),
            settings["expected"],
            "research counts cost=$(join(cost_counts, "/")), delay=$(join(delay_counts, "/")), persistence=$(join(persistence_counts, "/")), discount=$(join(discount_counts, "/")) on $grid_size beliefs",
            length(scenarios) * 2 + 8,
            "Seeded Float64 F5/F8 compatibility policy map; no comparative-static theorem.",
        ),
        raw,
        scenarios,
        policy_summary,
        coordinates,
        success_probabilities,
    )
end

"""Run all seven families; any failed expected identity raises before output."""
function run_theorem_mechanism_experiments(
    config = load_mechanism_config();
    policy_grid_size_override = nothing,
)
    seed = UInt64(config["seed"])
    # Family-specific streams keep seeded outputs invariant to execution order.
    dynamic_quotient = run_dynamic_quotient_family(config, research_rng(seed))
    frontier_closure = run_frontier_closure_family(config)
    safe_deletion = run_safe_deletion_family(config)
    frontier_pruning = run_frontier_pruning_family(config)
    decomposition = run_decomposition_family(config)
    coverage = run_coverage_family(config)
    dynamic_policy = run_dynamic_policy_family(
        config,
        research_rng(seed);
        grid_size_override = policy_grid_size_override,
    )
    families = (
        dynamic_quotient,
        frontier_closure,
        safe_deletion,
        frontier_pruning,
        decomposition,
        coverage,
        dynamic_policy,
    )
    summaries = [family.summary for family in families]
    raw = reduce(vcat, (family.raw for family in families); init = NamedTuple[])
    _require_pattern(length(summaries) == 7, "SUITE-FAMILY-COUNT", "all seven families are required")
    _require_pattern(all(summary -> summary.passed, summaries), "SUITE-PASS", "a family summary failed")
    return (;
        schema_version = SCHEMA_VERSION,
        experiment_id = EXPERIMENT_ID,
        seed,
        summaries,
        raw,
        validation_count = sum(summary.validations for summary in summaries),
        all_passed = true,
        dynamic_quotient,
        frontier_closure,
        safe_deletion,
        frontier_pruning,
        decomposition,
        coverage,
        dynamic_policy,
    )
end

function _csv_value(value)
    value isa Missing && return ""
    value isa Rational && return _rational_string(value)
    value isa AbstractFloat && return repr(value)
    return string(value)
end

function _csv_quote(value)
    text = _csv_value(value)
    return occursin(r"[\",\n\r]", text) ? "\"$(replace(text, "\"" => "\"\""))\"" : text
end

function _write_csv(path::AbstractString, rows)
    rows = collect(rows)
    isempty(rows) && throw(ArgumentError("CSV output requires at least one row"))
    columns = collect(keys(first(rows)))
    all(keys(row) == keys(first(rows)) for row in rows) ||
        throw(ArgumentError("all CSV rows must have identical fields"))
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, join(string.(columns), ','))
        for row in rows
            println(io, join((_csv_quote(getproperty(row, column)) for column in columns), ','))
        end
    end
    return path
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
    if value isa NamedTuple
        _write_json(io, Dict(string(key) => getproperty(value, key) for key in keys(value)), indent)
    elseif value isa AbstractDict
        ordered_keys = sort!(collect(keys(value)); by = string)
        print(io, "{")
        isempty(ordered_keys) || print(io, "\n")
        for (index, key) in enumerate(ordered_keys)
            print(io, child_padding, "\"", _json_escape(string(key)), "\": ")
            _write_json(io, value[key], indent + 2)
            index == length(ordered_keys) || print(io, ",")
            print(io, "\n")
        end
        isempty(ordered_keys) || print(io, padding)
        print(io, "}")
    elseif value isa AbstractVector || value isa Tuple
        print(io, "[")
        isempty(value) || print(io, "\n")
        for (index, item) in enumerate(value)
            print(io, child_padding)
            _write_json(io, item, indent + 2)
            index == length(value) || print(io, ",")
            print(io, "\n")
        end
        isempty(value) || print(io, padding)
        print(io, "]")
    elseif value isa Missing || value === nothing
        print(io, "null")
    elseif value isa AbstractString || value isa Symbol
        print(io, "\"", _json_escape(string(value)), "\"")
    elseif value isa Rational
        print(io, "\"", _rational_string(value), "\"")
    elseif value isa Bool
        print(io, value ? "true" : "false")
    elseif value isa Integer
        print(io, value)
    elseif value isa AbstractFloat
        isfinite(value) || throw(ArgumentError("JSON cannot encode nonfinite values"))
        print(io, repr(value))
    else
        throw(ArgumentError("unsupported JSON value $(typeof(value))"))
    end
end

function _write_json_file(path, value)
    mkpath(dirname(path))
    open(path, "w") do io
        _write_json(io, value)
        println(io)
    end
    return path
end

_xml_escape(value) = replace(
    string(value),
    "&" => "&amp;",
    "<" => "&lt;",
    ">" => "&gt;",
    "\"" => "&quot;",
)

function _svg_header(io, title, description; width = 960, height = 600)
    println(io, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\" viewBox=\"0 0 $width $height\" role=\"img\">")
    println(io, "<title>$(_xml_escape(title))</title>")
    println(io, "<desc>$(_xml_escape(description))</desc>")
    println(io, "<rect width=\"$width\" height=\"$height\" fill=\"$BACKGROUND\"/>")
    println(io, "<text x=\"80\" y=\"42\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"24\" font-weight=\"600\">$(_xml_escape(title))</text>")
end

function _write_pruning_figure(path, cases)
    width, height = 960, 600
    left, right, top, bottom = 90.0, 38.0, 90.0, 75.0
    plot_width = width - left - right
    plot_height = height - top - bottom
    rewards = Float64[case.reward for case in cases]
    losses = Float64[case.loss for case in cases]
    x_max = maximum(rewards)
    y_max = maximum(losses)
    map_x(x) = left + x / x_max * plot_width
    map_y(y) = top + (y_max - y) / y_max * plot_height
    mkpath(dirname(path))
    open(path, "w") do io
        _svg_header(io, "Frontier-only pruning loss", "Exact F4 mechanism: loss grows one-for-two with enabled future reward. Data: theorem_mechanism_pruning_loss.csv."; width, height)
        println(io, "<text x=\"80\" y=\"68\" fill=\"$MUTED\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"14\">Exact Rational arithmetic; horizon 2 and discount 1/2</text>")
        for tick in 0:5
            fraction = tick / 5
            x = left + fraction * plot_width
            y = top + (1 - fraction) * plot_height
            println(io, "<line x1=\"$left\" y1=\"$y\" x2=\"$(left + plot_width)\" y2=\"$y\" stroke=\"$GRID\"/>")
            println(io, "<text x=\"$x\" y=\"$(top + plot_height + 25)\" text-anchor=\"middle\" fill=\"$MUTED\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\">$(round(x_max * fraction; digits=0))</text>")
            println(io, "<text x=\"$(left - 12)\" y=\"$(y + 4)\" text-anchor=\"end\" fill=\"$MUTED\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\">$(round(y_max * fraction; digits=0))</text>")
        end
        path_data = join(((index == 1 ? "M" : "L") * "$(map_x(rewards[index])) $(map_y(losses[index]))" for index in eachindex(rewards)), " ")
        println(io, "<path d=\"$path_data\" fill=\"none\" stroke=\"$BLUE\" stroke-width=\"3\"/>")
        for index in eachindex(rewards)
            println(io, "<circle cx=\"$(map_x(rewards[index]))\" cy=\"$(map_y(losses[index]))\" r=\"5\" fill=\"$ORANGE\" stroke=\"white\" stroke-width=\"1.5\"/>")
        end
        println(io, "<text x=\"$(left + plot_width / 2)\" y=\"$(height - 18)\" text-anchor=\"middle\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"14\">Enabled future policy value</text>")
        println(io, "<text x=\"22\" y=\"$(top + plot_height / 2)\" transform=\"rotate(-90 22 $(top + plot_height / 2))\" text-anchor=\"middle\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"14\">Value lost after pruning</text>")
        println(io, "</svg>")
    end
    return path
end

function _write_decomposition_figure(path, cases)
    width, height = 960, 600
    left, top = 250.0, 120.0
    bar_width, bar_height, gap = 590.0, 70.0, 60.0
    maximum_total = maximum(Float64(case.total) for case in cases)
    scale(value) = Float64(value) / maximum_total * bar_width
    mkpath(dirname(path))
    open(path, "w") do io
        _svg_header(io, "Exact strategy-value decomposition", "Operational and generative components stack exactly to total innovation. Data: theorem_mechanism_decomposition_figure.csv."; width, height)
        println(io, "<text x=\"80\" y=\"68\" fill=\"$MUTED\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"14\">Total innovation = operational innovation + generative innovation</text>")
        for (index, case) in enumerate(cases)
            y = top + (index - 1) * (bar_height + gap)
            op_width = scale(case.operational)
            gen_width = scale(case.generative)
            println(io, "<text x=\"$(left - 18)\" y=\"$(y + bar_height / 2 + 5)\" text-anchor=\"end\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"15\">$(_xml_escape(case.case_id))</text>")
            println(io, "<rect x=\"$left\" y=\"$y\" width=\"$op_width\" height=\"$bar_height\" fill=\"$BLUE\"/>")
            println(io, "<rect x=\"$(left + op_width)\" y=\"$y\" width=\"$gen_width\" height=\"$bar_height\" fill=\"$ORANGE\"/>")
            println(io, "<text x=\"$(left + op_width + gen_width + 10)\" y=\"$(y + bar_height / 2 + 5)\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"14\">total $(_display_value(case.total))</text>")
        end
        println(io, "<rect x=\"300\" y=\"525\" width=\"18\" height=\"18\" fill=\"$BLUE\"/><text x=\"327\" y=\"539\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"14\">Operational</text>")
        println(io, "<rect x=\"475\" y=\"525\" width=\"18\" height=\"18\" fill=\"$ORANGE\"/><text x=\"502\" y=\"539\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"14\">Generative</text>")
        println(io, "</svg>")
    end
    return path
end

function _write_coverage_figure(path, cases)
    width, height = 1040, 690
    panel_width, panel_height = 430.0, 230.0
    origins = ((80.0, 105.0), (570.0, 105.0), (80.0, 395.0), (570.0, 395.0))
    mkpath(dirname(path))
    open(path, "w") do io
        _svg_header(io, "Coverage preservation and failure modes", "Four exact geometries separate preserved thresholds from assumption violations and multi-gap disconnection. Data: theorem_mechanism_coverage_geometry.csv."; width, height)
        for (case, (origin_x, origin_y)) in zip(cases, origins)
            values = Float64.(case.potential)
            gaps = Float64.(case.gap)
            ymax = max(maximum(values), maximum(gaps), 1.0)
            count = length(values)
            map_x(index) = origin_x + (index - 1) / (count - 1) * panel_width
            map_y(value) = origin_y + panel_height - value / ymax * panel_height
            println(io, "<rect x=\"$origin_x\" y=\"$origin_y\" width=\"$panel_width\" height=\"$panel_height\" fill=\"white\" stroke=\"$GRID\"/>")
            for component in connected_components(case.region)
                x0 = component.start == 1 ? origin_x : (map_x(component.start - 1) + map_x(component.start)) / 2
                x1 = component.stop == count ? origin_x + panel_width : (map_x(component.stop) + map_x(component.stop + 1)) / 2
                println(io, "<rect x=\"$x0\" y=\"$origin_y\" width=\"$(x1 - x0)\" height=\"$panel_height\" fill=\"$BLUE\" opacity=\"0.07\"/>")
            end
            gap_path = join(((index == 1 ? "M" : "L") * "$(map_x(index)) $(map_y(gaps[index]))" for index in eachindex(gaps)), " ")
            potential_path = join(((index == 1 ? "M" : "L") * "$(map_x(index)) $(map_y(values[index]))" for index in eachindex(values)), " ")
            println(io, "<path d=\"$gap_path\" fill=\"none\" stroke=\"$ORANGE\" stroke-width=\"2.5\" stroke-dasharray=\"7 4\"/>")
            println(io, "<path d=\"$potential_path\" fill=\"none\" stroke=\"$BLUE\" stroke-width=\"3\"/>")
            println(io, "<text x=\"$origin_x\" y=\"$(origin_y - 13)\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"16\" font-weight=\"600\">$(_xml_escape(case.case_id))</text>")
            println(io, "<text x=\"$(origin_x + panel_width)\" y=\"$(origin_y - 13)\" text-anchor=\"end\" fill=\"$MUTED\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\">$(case.components) component(s)</text>")
        end
        println(io, "<line x1=\"360\" y1=\"660\" x2=\"395\" y2=\"660\" stroke=\"$BLUE\" stroke-width=\"3\"/><text x=\"405\" y=\"665\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"13\">Potential</text>")
        println(io, "<line x1=\"520\" y1=\"660\" x2=\"555\" y2=\"660\" stroke=\"$ORANGE\" stroke-width=\"2.5\" stroke-dasharray=\"7 4\"/><text x=\"565\" y=\"665\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"13\">Gap</text>")
        println(io, "</svg>")
    end
    return path
end

function _write_coverage_ranking_figure(path, ranking)
    width, height = 1120, 620
    left_x, left_y, panel_width, panel_height = 80.0, 120.0, 540.0, 390.0
    right_x, right_y, right_width, right_height = 760.0, 120.0, 280.0, 390.0
    correlations = Float64[row.spearman_rank_correlation for row in ranking.ranking_summary]
    labels = ["Coverage", "Current", "Average", "Novelty"]
    colors = [BLUE, MUTED, MUTED, MUTED]
    map_rank_y(value) = left_y + (1 - (value + 1) / 2) * panel_height
    individual_value = Float64(last(ranking.individual_selection).cumulative_set_value)
    marginal_value = Float64(last(ranking.marginal_selection).cumulative_set_value)
    maximum_set_value = max(individual_value, marginal_value)
    map_set_y(value) = right_y + (maximum_set_value - value) / maximum_set_value * right_height
    mkpath(dirname(path))
    open(path, "w") do io
        _svg_header(
            io,
            "Prospective coverage-ranking mechanism",
            "Exact rank recovery for the theorem-aligned target and redundancy-aware set selection. Data: theorem_mechanism_coverage_ranking_summary.csv and theorem_mechanism_coverage_selection.csv.";
            width,
            height,
        )
        println(io, "<text x=\"80\" y=\"70\" fill=\"$MUTED\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"14\">Fixed before execution; Rational{BigInt}; six candidates; no market returns</text>")
        println(io, "<text x=\"$left_x\" y=\"98\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"16\" font-weight=\"600\">A. Rank correlation with exact gross value</text>")
        println(io, "<rect x=\"$left_x\" y=\"$left_y\" width=\"$panel_width\" height=\"$panel_height\" fill=\"white\" stroke=\"$GRID\"/>")
        for tick in -1:1
            y = map_rank_y(tick)
            println(io, "<line x1=\"$left_x\" y1=\"$y\" x2=\"$(left_x + panel_width)\" y2=\"$y\" stroke=\"$GRID\"/>")
            println(io, "<text x=\"$(left_x - 10)\" y=\"$(y + 4)\" text-anchor=\"end\" fill=\"$MUTED\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\">$tick</text>")
        end
        bar_width = 82.0
        bar_gap = (panel_width - length(correlations) * bar_width) / (length(correlations) + 1)
        zero_y = map_rank_y(0)
        for index in eachindex(correlations)
            x = left_x + bar_gap * index + bar_width * (index - 1)
            value_y = map_rank_y(correlations[index])
            y = min(value_y, zero_y)
            bar_height = abs(zero_y - value_y)
            println(io, "<rect x=\"$x\" y=\"$y\" width=\"$bar_width\" height=\"$bar_height\" fill=\"$(colors[index])\" stroke=\"$CHARCOAL\" stroke-width=\"0.8\"/>")
            println(io, "<text x=\"$(x + bar_width / 2)\" y=\"$(height - 75)\" text-anchor=\"middle\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\">$(labels[index])</text>")
            println(io, "<text x=\"$(x + bar_width / 2)\" y=\"$(value_y - 8)\" text-anchor=\"middle\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\">$(round(correlations[index]; digits=2))</text>")
        end

        println(io, "<text x=\"$right_x\" y=\"98\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"16\" font-weight=\"600\">B. Exact top-2 set value</text>")
        println(io, "<rect x=\"$right_x\" y=\"$right_y\" width=\"$right_width\" height=\"$right_height\" fill=\"white\" stroke=\"$GRID\"/>")
        set_values = [individual_value, marginal_value]
        set_labels = ["Individual", "Marginal"]
        set_colors = [MUTED, BLUE]
        set_bar_width = 80.0
        set_gap = (right_width - 2 * set_bar_width) / 3
        for index in eachindex(set_values)
            x = right_x + set_gap * index + set_bar_width * (index - 1)
            y = map_set_y(set_values[index])
            println(io, "<rect x=\"$x\" y=\"$y\" width=\"$set_bar_width\" height=\"$(right_y + right_height - y)\" fill=\"$(set_colors[index])\" stroke=\"$CHARCOAL\" stroke-width=\"0.8\"/>")
            println(io, "<text x=\"$(x + set_bar_width / 2)\" y=\"$(y - 9)\" text-anchor=\"middle\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\">$(round(set_values[index]; digits=2))</text>")
            println(io, "<text x=\"$(x + set_bar_width / 2)\" y=\"$(height - 75)\" text-anchor=\"middle\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\">$(set_labels[index])</text>")
        end
        println(io, "<text x=\"560\" y=\"585\" text-anchor=\"middle\" fill=\"$MUTED\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"13\">The construction validates the fixed-candidate S4 mechanism; it is not a universal ranking theorem.</text>")
        println(io, "</svg>")
    end
    return path
end

function _write_policy_figure(path, policy_result)
    width, height = 1120, 720
    left, right, top, bottom = 230.0, 50.0, 105.0, 70.0
    scenarios = policy_result.scenarios
    coordinates = policy_result.coordinates
    cell_width = (width - left - right) / length(coordinates)
    cell_height = (height - top - bottom) / length(scenarios)
    mkpath(dirname(path))
    open(path, "w") do io
        _svg_header(io, "Dynamic continue/research policy map", "Seeded Float64 Bellman policies under cost, delay, persistence, and discount variations. Blue cells select research. Data: theorem_mechanism_policy_map.csv."; width, height)
        println(io, "<text x=\"80\" y=\"68\" fill=\"$MUTED\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"14\">One-at-a-time parameter changes; $(length(coordinates))-point belief grid</text>")
        for (row, case) in enumerate(scenarios)
            y = top + (row - 1) * cell_height
            println(io, "<text x=\"$(left - 12)\" y=\"$(y + cell_height * 0.68)\" text-anchor=\"end\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\">$(_xml_escape(case.scenario_id))</text>")
            for column in eachindex(coordinates)
                color = case.region[column] ? BLUE : "#E9EDF1"
                println(io, "<rect x=\"$(left + (column - 1) * cell_width)\" y=\"$y\" width=\"$(cell_width + 0.25)\" height=\"$(cell_height + 0.25)\" fill=\"$color\"/>")
            end
        end
        for tick in 0:5
            x = left + tick / 5 * (width - left - right)
            println(io, "<text x=\"$x\" y=\"$(height - 35)\" text-anchor=\"middle\" fill=\"$MUTED\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\">$(round(tick / 5; digits=1))</text>")
        end
        println(io, "<text x=\"$(left + (width - left - right) / 2)\" y=\"$(height - 12)\" text-anchor=\"middle\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"14\">Belief coordinate</text>")
        println(io, "<rect x=\"830\" y=\"50\" width=\"16\" height=\"16\" fill=\"$BLUE\"/><text x=\"854\" y=\"63\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"13\">Research</text>")
        println(io, "<rect x=\"930\" y=\"50\" width=\"16\" height=\"16\" fill=\"#E9EDF1\"/><text x=\"954\" y=\"63\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"13\">Continue</text>")
        println(io, "</svg>")
    end
    return path
end

function _sha256_file(path)
    return bytes2hex(sha256(read(path)))
end

function _configured_path(config, key, artifact_root)
    return joinpath(artifact_root, splitpath(config["outputs"][key])...)
end

const FLOAT64_ARTIFACT_ATOL = 2e-12
const FLOAT64_ARTIFACT_RTOL = 2e-12
const FLOAT64_ARTIFACT_NUMBER = r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?"
const PLATFORM_FLOAT64_OUTPUT_KEYS =
    ("raw", "summary_json", "policy_summary_csv", "policy_figure_data")

function _csv_rows(text)
    return [split(line, ','; keepempty = true) for line in split(chomp(text), '\n')]
end

function _float64_csv_equivalent(
    committed,
    generated,
    approximate_columns;
    atol = FLOAT64_ARTIFACT_ATOL,
    rtol = FLOAT64_ARTIFACT_RTOL,
)
    committed_rows = _csv_rows(committed)
    generated_rows = _csv_rows(generated)
    length(committed_rows) == length(generated_rows) || return false
    isempty(committed_rows) && return true
    committed_rows[1] == generated_rows[1] || return false

    header = committed_rows[1]
    approximate_names = Set(string.(approximate_columns))
    all(name -> name in header, approximate_names) || return false
    approximate_indices = Set(findall(name -> name in approximate_names, header))
    for (committed_row, generated_row) in
        zip(committed_rows[2:end], generated_rows[2:end])
        length(committed_row) == length(header) || return false
        length(generated_row) == length(header) || return false
        for column_index in eachindex(header)
            committed_cell = committed_row[column_index]
            generated_cell = generated_row[column_index]
            committed_cell == generated_cell && continue
            column_index in approximate_indices || return false
            committed_value = tryparse(Float64, committed_cell)
            generated_value = tryparse(Float64, generated_cell)
            isnothing(committed_value) && return false
            isnothing(generated_value) && return false
            isapprox(
                committed_value,
                generated_value;
                atol,
                rtol,
                nans = false,
            ) || return false
        end
    end
    return true
end

function _float64_numeric_text_equivalent(
    committed,
    generated;
    atol = FLOAT64_ARTIFACT_ATOL,
    rtol = FLOAT64_ARTIFACT_RTOL,
)
    replace(committed, FLOAT64_ARTIFACT_NUMBER => "#") ==
        replace(generated, FLOAT64_ARTIFACT_NUMBER => "#") || return false
    committed_numbers = [
        parse(Float64, match.match) for
        match in eachmatch(FLOAT64_ARTIFACT_NUMBER, committed)
    ]
    generated_numbers = [
        parse(Float64, match.match) for
        match in eachmatch(FLOAT64_ARTIFACT_NUMBER, generated)
    ]
    length(committed_numbers) == length(generated_numbers) || return false
    return all(
        isapprox(
            committed_number,
            generated_number;
            atol,
            rtol,
            nans = false,
        ) for (committed_number, generated_number) in
            zip(committed_numbers, generated_numbers)
    )
end

function _metadata_platform_signature(text, config)
    platform_paths = Set(config["outputs"][key] for key in PLATFORM_FLOAT64_OUTPUT_KEYS)
    lines = split(text, '\n'; keepempty = true)
    for index in eachindex(lines)
        stripped = lstrip(lines[index])
        if any(path -> startswith(stripped, "\"$path\":"), platform_paths)
            lines[index] = replace(
                lines[index],
                r"\"[0-9a-f]{64}\"" => "\"<platform-dependent-float64>\"",
            )
        end
    end
    return join(lines, '\n')
end

function _artifact_equivalent(key, committed_path, generated_path, config)
    committed = read(committed_path, String)
    generated = read(generated_path, String)
    committed == generated && return true
    if key == "summary_json"
        return _float64_numeric_text_equivalent(committed, generated)
    elseif key == "policy_summary_csv"
        return _float64_csv_equivalent(
            committed,
            generated,
            (
                :axis_value,
                :cost,
                :persistence,
                :discount,
                :cutoff_coordinate,
                :bellman_residual,
                :posterior_error_bound,
            ),
        )
    elseif key == "policy_figure_data"
        return _float64_csv_equivalent(
            committed,
            generated,
            (
                :axis_value,
                :coordinate,
                :success_probability,
                :continue_value,
                :research_value,
                :research_advantage,
            ),
        )
    elseif key == "metadata"
        return _metadata_platform_signature(committed, config) ==
               _metadata_platform_signature(generated, config)
    end
    return false
end

function _report_text(result, config)
    lines = String[
        "# Synthetic Theorem-Mechanism Report",
        "",
        "- Experiment: `$(result.experiment_id)`",
        "- Configuration: `experiments/configs/theorem_mechanisms.toml`",
        "- Run date: `$(config["run_date"])`",
        "- Seed: `$(result.seed)` (`StableRNGs.StableRNG`)",
        "",
        "## Result",
        "",
        "All seven controlled experiment families passed $(result.validation_count) automatic mechanism checks. Exact theorem fixtures used `Rational{BigInt}`; the larger dynamic-policy map used seeded `Float64` value iteration with recorded Bellman diagnostics. Version 2 adds a prospective coverage-ranking fixture fixed before execution and leaves the locked 25-ETF result unchanged.",
        "",
        "| Family | Mechanism | Observed pattern | Status |",
        "|---|---|---|---|",
    ]
    for summary in result.summaries
        push!(lines, "| $(summary.family) | $(summary.title) | $(summary.observed_pattern) | pass |")
    end
    append!(lines, [
        "",
        "## Interpretation",
        "",
        "A isolates representation invariance: changing raw strategy identities while preserving both frontier and closure leaves exact dynamic values and policies unchanged. B then perturbs one component at a time: frontier changes enter the frozen-library operational value, whereas closure changes enter the research-option premium. C confirms that deletion is safe only after both component equalities are rechecked at every intermediate library.",
        "",
        "D validates the formal frontier-pruning construction rather than searching for a profitable rule: the exact loss is `future_reward/2` in every configured case. E checks the accounting identity separately for operational-only, generative-only, and mixed strategies. F places positive and negative coverage geometries side by side, then evaluates a separately configured prospective ranking fixture. In that fixture the evaluation target is exactly S4's date-first gross fixed-candidate value, so coverage potential recovers the ranking by identity. Current-belief improvement, average gap, and raw parameter novelty deliberately target different objects and incur positive top-one regret. A bounded score error smaller than half the top-two margin preserves the winner, while a larger preregistered stress error reverses it. Sequential marginal coverage also avoids a pointwise-redundant second candidate and raises exact top-two set value from `10` to `69/4`. G maps solved continue/research choices over cost, delay, persistence, and discount changes; it is a numerical policy diagnostic, not a theorem.",
        "",
        "## Audit boundary",
        "",
        "These experiments validate encoded mechanisms and regression identities. The ranking fixture does not estimate a relation after observing market outcomes: its target, candidate gaps, transition, perturbations, and expected selections are committed inputs. It establishes no robustness to occupation misspecification, candidate-dependent admission, costs, estimation error beyond the configured margin, or adaptive library generation. It does not upgrade Candidate Theorems T1–T6. Lean verification remains confined to the supporting F1–F8, S4–S5, and C2 declarations recorded in `THEOREM_LEDGER.md`; the Float64 policy maps are numerical evidence only.",
        "",
        "## Artifacts",
        "",
        "- Raw long-form observations: `experiments/results/raw/theorem_mechanism_observations.csv`",
        "- Summary and policy tables: `experiments/results/summaries/theorem_mechanism_*.csv`",
        "- Machine-readable summary and checksummed metadata: `experiments/results/summaries/theorem_mechanism_{summary,metadata}.json`",
        "- Publication figures: `manuscript/figures/theorem_mechanism_*.svg`",
        "",
        "Every figure is generated by `julia/scripts/run_theorem_mechanism_experiments.jl` from a committed CSV source table. A violated exact identity or configured policy comparative static raises an error and fails the experiment command.",
        "",
    ])
    return join(lines, "\n")
end

"""Write raw data, summary tables, metadata, report, and five SVG figures."""
function write_theorem_mechanism_outputs(
    result,
    config,
    config_path::AbstractString = DEFAULT_MECHANISM_CONFIG;
    repository_root::AbstractString = REPOSITORY_ROOT,
    artifact_root::AbstractString = repository_root,
)
    output = key -> _configured_path(config, key, artifact_root)
    paths = Dict{String,String}()
    paths["raw"] = _write_csv(output("raw"), result.raw)
    paths["summary_csv"] = _write_csv(output("summary_csv"), result.summaries)
    paths["policy_summary_csv"] = _write_csv(
        output("policy_summary_csv"),
        result.dynamic_policy.policy_summary,
    )
    paths["decomposition_csv"] = _write_csv(
        output("decomposition_csv"),
        result.decomposition.cases,
    )
    paths["pruning_figure_data"] = _write_csv(
        output("pruning_figure_data"),
        [(; future_reward = case.reward, pruning_loss = case.loss, expected_loss = case.reward / 2) for case in result.frontier_pruning.cases],
    )
    paths["decomposition_figure_data"] = _write_csv(
        output("decomposition_figure_data"),
        result.decomposition.cases,
    )
    coverage_rows = [
        (;
            case_id = case.case_id,
            belief_index = index,
            coordinate = length(case.gap) == 1 ? 0.0 : (index - 1) / (length(case.gap) - 1),
            gap = case.gap[index],
            potential = case.potential[index],
            research = case.region[index],
            component_count = case.components,
            kernel_preservation_assumption = case.kernel_assumption,
        )
        for case in result.coverage.cases for index in eachindex(case.gap)
    ]
    paths["coverage_figure_data"] = _write_csv(output("coverage_figure_data"), coverage_rows)
    paths["coverage_ranking_csv"] = _write_csv(
        output("coverage_ranking_csv"),
        result.coverage.ranking.candidate_rows,
    )
    paths["coverage_ranking_summary_csv"] = _write_csv(
        output("coverage_ranking_summary_csv"),
        result.coverage.ranking.ranking_summary,
    )
    paths["coverage_selection_csv"] = _write_csv(
        output("coverage_selection_csv"),
        vcat(
            result.coverage.ranking.individual_selection,
            result.coverage.ranking.marginal_selection,
        ),
    )
    policy_rows = [
        (;
            scenario_id = case.scenario_id,
            axis = case.axis,
            level = case.level,
            axis_value = case.axis_value,
            belief_index = index,
            coordinate = result.dynamic_policy.coordinates[index],
            success_probability = result.dynamic_policy.success_probabilities[index],
            continue_value = case.continue_values[index],
            research_value = case.research_values[index],
            research_advantage = case.advantages[index],
            action = case.region[index] ? "research" : "continue",
        )
        for case in result.dynamic_policy.scenarios for index in eachindex(result.dynamic_policy.coordinates)
    ]
    paths["policy_figure_data"] = _write_csv(output("policy_figure_data"), policy_rows)
    paths["pruning_figure"] = _write_pruning_figure(output("pruning_figure"), result.frontier_pruning.cases)
    paths["decomposition_figure"] = _write_decomposition_figure(output("decomposition_figure"), result.decomposition.cases)
    paths["coverage_figure"] = _write_coverage_figure(output("coverage_figure"), result.coverage.cases)
    paths["coverage_ranking_figure"] = _write_coverage_ranking_figure(
        output("coverage_ranking_figure"),
        result.coverage.ranking,
    )
    paths["policy_figure"] = _write_policy_figure(output("policy_figure"), result.dynamic_policy)

    summary_json = Dict(
        "schema_version" => result.schema_version,
        "experiment_id" => result.experiment_id,
        "seed" => string(result.seed),
        "all_passed" => result.all_passed,
        "validation_count" => result.validation_count,
        "raw_observation_count" => length(result.raw),
        "families" => result.summaries,
        "coverage_ranking" => result.coverage.ranking.ranking_summary,
        "coverage_selection" => vcat(
            result.coverage.ranking.individual_selection,
            result.coverage.ranking.marginal_selection,
        ),
        "dynamic_policy_scenarios" => result.dynamic_policy.policy_summary,
    )
    paths["summary_json"] = _write_json_file(output("summary_json"), summary_json)
    report_path = output("report")
    mkpath(dirname(report_path))
    open(report_path, "w") do io
        write(io, _report_text(result, config))
    end
    paths["report"] = report_path

    checksum_keys = sort!(collect(keys(paths)))
    checksums = Dict(
        config["outputs"][key] => _sha256_file(paths[key]) for key in checksum_keys
    )
    metadata = Dict(
        "schema_version" => result.schema_version,
        "experiment_id" => result.experiment_id,
        "run_date" => config["run_date"],
        "julia_version" => string(VERSION),
        "seed" => string(result.seed),
        "rng" => "StableRNGs.StableRNG",
        "exact_arithmetic" => "Rational{BigInt}",
        "large_experiment_arithmetic" => "Float64",
        "source_base_commit" => config["source_base_commit"],
        "source_script_sha256" => _sha256_file(joinpath(repository_root, "julia", "scripts", "run_theorem_mechanism_experiments.jl")),
        "config_sha256" => _sha256_file(config_path),
        "manifest_sha256" => _sha256_file(joinpath(repository_root, "julia", "Manifest.toml")),
        "command" => "./.local_runtime/julia-1.12.6/bin/julia --project=julia julia/scripts/run_theorem_mechanism_experiments.jl",
        "raw_observation_count" => length(result.raw),
        "validation_count" => result.validation_count,
        "all_passed" => result.all_passed,
        "artifact_sha256" => checksums,
    )
    paths["metadata"] = _write_json_file(output("metadata"), metadata)
    return paths
end

function _check_outputs(result, config, config_path)
    mktempdir() do temporary_root
        generated = write_theorem_mechanism_outputs(
            result,
            config,
            config_path;
            repository_root = REPOSITORY_ROOT,
            artifact_root = temporary_root,
        )
        tracked_keys = sort!(setdiff(collect(keys(generated)), ["raw"]))
        for key in tracked_keys
            committed = _configured_path(config, key, REPOSITORY_ROOT)
            isfile(committed) || error("committed experiment artifact is missing: $committed")
            _artifact_equivalent(key, committed, generated[key], config) ||
                error("experiment artifact drift detected: $(config["outputs"][key])")
        end
    end
    return true
end

function main(args = ARGS)
    length(args) <= 2 || throw(
        ArgumentError("usage: run_theorem_mechanism_experiments.jl [--check] [CONFIG_PATH]"),
    )
    check_mode = "--check" in args
    positional = filter(argument -> argument != "--check", args)
    config_path = isempty(positional) ? DEFAULT_MECHANISM_CONFIG : only(positional)
    config = load_mechanism_config(config_path)
    result = run_theorem_mechanism_experiments(config)
    if check_mode
        _check_outputs(result, config, config_path)
        println("theorem-mechanism artifacts are current; validations=$(result.validation_count)")
        return result
    end
    paths = write_theorem_mechanism_outputs(result, config, config_path)
    println("experiment=$(result.experiment_id)")
    println("families=$(length(result.summaries))")
    println("validations=$(result.validation_count)")
    println("raw_observations=$(length(result.raw))")
    println("report=$(paths["report"])")
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
