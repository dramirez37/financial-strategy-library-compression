module RandomizedLibraryV2Core

using StrategyInnovation
using StableRNGs: StableRNG
using Random: rand, randperm

import StrategyInnovation:
    admitted_candidate_distribution,
    candidate_generation_distribution,
    rectangle_consistency

export RegisteredTrialV2,
    V2StateGeneration,
    V2TrialResult,
    build_registered_v2_model,
    read_registered_v2_trials,
    run_registered_v2_trial

const SI = StrategyInnovation
const ER = ExactRational

struct RegisteredTrialV2
    trial_id::Int
    batch_id::Int
    within_batch_order::Int
    principal_cell_id::String
    canonical_index::Int
    replicate_id::Int
    theorem_regime::Symbol
    boundary_mechanism::Symbol
    frontier_density::Symbol
    module_overlap::Symbol
    module_complementarity::Symbol
    project_cost::Symbol
    duration::Symbol
    admission::Symbol
    persistence::Symbol
    schedule_key::UInt64
    trial_seed::Int
    catalog_seed::Int
    project_seed::Int
    deletion_seed::Int
end

struct V2StateGeneration{S,B,M}
    project_candidates::Dict{
        ResearchProjectId{S},
        Tuple{StrategyId{S},StrategyId{S}},
    }
    frontier_sensitive::Bool
    frontier_cutoff::ER
end

function (generation::V2StateGeneration)(
    project,
    _,
    ::ModuleSet,
)
    candidate = first(generation.project_candidates[project.id])
    return dirac(CandidateOutcome(candidate))
end

function (generation::V2StateGeneration)(
    project,
    _,
    state::CompressedLibraryState,
)
    low_candidate, high_candidate =
        generation.project_candidates[project.id]
    frontier_sum = sum(
        state.frontier.values;
        init = exact_rational(0),
    )
    candidate =
        generation.frontier_sensitive &&
        frontier_sum > generation.frontier_cutoff ?
        high_candidate : low_candidate
    return dirac(CandidateOutcome(candidate))
end

function candidate_generation_distribution(
    process::RawInnovationProcess{S,B,M,P,G},
    project,
    belief::Belief{B},
    state::CompressedLibraryState{B,M,ER},
) where {S,B,M,P,G<:V2StateGeneration}
    belief in process.belief_kernel.space ||
        throw(ArgumentError("unresolved belief"))
    row = SI._resolve_project(process, project)
    law = process.generation(row, belief, state)
    law isa RatProb ||
        throw(ArgumentError("state-dependent generation must return RatProb"))
    foreach(
        outcome -> SI._validate_candidate_outcome(process, outcome),
        law.outcomes,
    )
    return law
end

function admitted_candidate_distribution(
    process::RawInnovationProcess{S,B,M,P,G},
    project,
    belief::Belief{B},
    state::CompressedLibraryState{B,M,ER},
) where {S,B,M,P,G<:V2StateGeneration}
    row = SI._resolve_project(process, project)
    raw = candidate_generation_distribution(
        process,
        row,
        belief,
        state,
    )
    failure = CandidateOutcome{S}()
    outcomes = CandidateOutcome{S}[failure]
    append!(
        outcomes,
        [CandidateOutcome(strategy_row.id) for
         strategy_row in process.catalog.strategies],
    )
    masses = zeros(ER, length(outcomes))
    masses[1] = probability(raw, failure)
    for (index, strategy_row) in enumerate(process.catalog.strategies)
        generated = probability(
            raw,
            CandidateOutcome(strategy_row.id),
        )
        pass = admission_probability(
            process,
            row,
            belief,
            state,
            strategy_row.id,
        )
        masses[index + 1] = generated * pass
        masses[1] += generated * (1 - pass)
    end
    return RatProb(outcomes, masses)
end

function rectangle_consistency(
    rectangle::RealizableRectangle,
    process::RawInnovationProcess{S,B,M,P,G};
    horizon::Integer = 2,
) where {S,B,M,P,G<:V2StateGeneration}
    horizon >= 1 ||
        throw(ArgumentError("consistency horizon must be positive"))
    structure = SI.rectangle_consistency(rectangle)
    same_process_primitives =
        process.catalog === rectangle.catalog &&
        process.closure === rectangle.closure
    corners_in_process =
        same_process_primitives &&
        all(
            library -> library in process.raw_libraries,
            values(rectangle_libraries(rectangle)),
        )
    project_laws_follow_corner_state =
        corners_in_process &&
        all(values(rectangle_states(rectangle))) do state
            all(
                project_available(process, state, project) ==
                issubset(project.requirements, state.closure) for
                project in process.projects
            )
        end
    transition_pushforwards_agree =
        corners_in_process &&
        SI._transition_pushforwards_agree(rectangle, process)
    finite_values_agree =
        corners_in_process &&
        SI._finite_values_agree(rectangle, process, horizon)
    all_pass =
        structure.all_pass &&
        same_process_primitives &&
        corners_in_process &&
        project_laws_follow_corner_state &&
        transition_pushforwards_agree &&
        finite_values_agree
    return (;
        structure...,
        same_process_primitives,
        corners_in_process,
        project_laws_follow_corner_closure =
            project_laws_follow_corner_state,
        project_laws_follow_corner_state,
        transition_pushforwards_agree,
        finite_values_agree,
        all_pass,
    )
end

struct V2TrialResult
    trial_row::NamedTuple
    corner_rows::Vector{NamedTuple}
    transition_rows::Vector{NamedTuple}
    pruning_rows::Vector{NamedTuple}
    asset_rows::Vector{NamedTuple}
    action_rows::Vector{NamedTuple}
    profile_rows::Vector{NamedTuple}
    module_rows::Vector{NamedTuple}
    closure_rows::Vector{NamedTuple}
    kernel_rows::Vector{NamedTuple}
    project_rows::Vector{NamedTuple}
    witness_rows::Vector{NamedTuple}
end

function read_registered_v2_trials(path::AbstractString)
    lines = readlines(path)
    isempty(lines) && error("registered v2 trial registry is empty")
    expected_header = [
        "trial_id",
        "batch_id",
        "within_batch_order",
        "principal_cell_id",
        "canonical_index",
        "replicate_id",
        "theorem_regime",
        "boundary_mechanism",
        "frontier_density",
        "module_overlap",
        "module_complementarity",
        "project_cost",
        "duration",
        "admission",
        "persistence",
        "schedule_key",
        "trial_seed",
        "catalog_seed",
        "project_seed",
        "deletion_seed",
    ]
    split(first(lines), ",") == expected_header ||
        error("registered v2 trial registry header changed")
    rows = RegisteredTrialV2[]
    for line in Iterators.drop(lines, 1)
        fields = split(line, ",")
        length(fields) == length(expected_header) ||
            error("malformed v2 registry row")
        push!(
            rows,
            RegisteredTrialV2(
                parse(Int, fields[1]),
                parse(Int, fields[2]),
                parse(Int, fields[3]),
                fields[4],
                parse(Int, fields[5]),
                parse(Int, fields[6]),
                Symbol(fields[7]),
                Symbol(fields[8]),
                Symbol(fields[9]),
                Symbol(fields[10]),
                Symbol(fields[11]),
                Symbol(fields[12]),
                Symbol(fields[13]),
                Symbol(fields[14]),
                Symbol(fields[15]),
                parse(UInt64, fields[16]),
                parse(Int, fields[17]),
                parse(Int, fields[18]),
                parse(Int, fields[19]),
                parse(Int, fields[20]),
            ),
        )
    end
    all(row.trial_id == index for (index, row) in enumerate(rows)) ||
        error("registered v2 rows are not in consecutive trial order")
    return rows
end

_module_id(name) = ModuleId(Symbol(name))
_strategy_id(name) = StrategyId(Symbol(name))
_project_id(name) = ResearchProjectId(Symbol(name))

function _factor_primitives(row::RegisteredTrialV2)
    cost = row.project_cost == :low ? 1 // 2 : 2 // 1
    duration = row.duration == :short ? 1 : 3
    admission = row.admission == :low ? 1 // 4 : 3 // 4
    persistence =
        row.persistence == :low ? 1 // 4 : 3 // 4
    return (
        cost = exact_rational(cost),
        duration,
        admission = exact_rational(admission),
        persistence = exact_rational(persistence),
    )
end

function _jitter(rng)
    support = ER[-1 // 4, 0 // 1, 1 // 4]
    return rand(rng, support)
end

function _profile_rows(
    row::RegisteredTrialV2,
    beliefs,
    project_rng,
)
    catalog_rng = StableRNG(row.catalog_seed)
    target = rand(catalog_rng, 1:3)
    base_profiles = Vector{Vector{ER}}()
    if row.frontier_density == :sparse
        push!(
            base_profiles,
            ER[4 + _jitter(catalog_rng) for _ in 1:3],
        )
        push!(
            base_profiles,
            ER[2 + _jitter(catalog_rng) for _ in 1:3],
        )
        push!(
            base_profiles,
            ER[1 + _jitter(catalog_rng) for _ in 1:3],
        )
        frontier_profile = ER[
            belief_index == target ?
            5 + _jitter(catalog_rng) :
            3 + _jitter(catalog_rng) for belief_index in 1:3
        ]
    else
        for strategy_index in 1:3
            push!(
                base_profiles,
                ER[
                    belief_index == strategy_index ?
                    6 + _jitter(catalog_rng) :
                    2 + _jitter(catalog_rng) for
                    belief_index in 1:3
                ],
            )
        end
        frontier_profile = ER[
            belief_index == target ?
            8 + _jitter(catalog_rng) :
            1 + _jitter(catalog_rng) for belief_index in 1:3
        ]
    end
    carrier_profile =
        ER[1 + _jitter(catalog_rng) for _ in 1:3]
    low_frontier = ER[
        maximum(profile[belief_index] for profile in base_profiles) for
        belief_index in 1:3
    ]
    high_frontier = ER[
        max(low_frontier[belief_index], frontier_profile[belief_index]) for
        belief_index in 1:3
    ]
    increments_1 = ER[rand(project_rng, 1:3) for _ in 1:3]
    increments_2 = ER[
        increments_1[index] + rand(project_rng, 1:3) for index in 1:3
    ]
    descendant_1 = high_frontier .+ increments_1
    descendant_2 = high_frontier .+ increments_2
    return (;
        target,
        base_profiles,
        frontier_profile,
        carrier_profile,
        low_frontier,
        high_frontier,
        descendant_1,
        descendant_2,
    )
end

function _cyclic_exact_kernel(beliefs, persistence)
    matrix = zeros(ER, 3, 3)
    for index in 1:3
        matrix[index, index] += persistence
        matrix[index, mod1(index + 1, 3)] += 1 - persistence
    end
    return MarkovKernel(beliefs, matrix)
end

function _completion_law(
    generation,
    verification,
    kernel,
    project,
    belief,
    state,
)
    generated = generation(project, belief, state)
    chosen = only(generated.outcomes)
    pass = is_failure(chosen) ?
           exact_rational(0) :
           exact_rational(
        verification(
            project,
            belief,
            state.closure,
            chosen.strategy,
        ),
    )
    failure = CandidateOutcome{Symbol}()
    admitted_outcomes =
        is_failure(chosen) ?
        [failure] : CandidateOutcome{Symbol}[failure, chosen]
    admitted_masses =
        is_failure(chosen) ?
        ER[1] : ER[1 - pass, pass]
    outcomes = ProjectCompletionOutcome{Int,Symbol}[]
    masses = ER[]
    for path in SI._positive_belief_paths(
        kernel,
        belief,
        project.duration,
    )
        path_mass =
            SI._markov_path_probability(kernel, belief, path)
        for (admitted, admitted_mass) in
            zip(admitted_outcomes, admitted_masses)
            iszero(admitted_mass) && continue
            push!(
                outcomes,
                ProjectCompletionOutcome(collect(path), admitted),
            )
            push!(masses, path_mass * admitted_mass)
        end
    end
    return RatProb(outcomes, masses)
end

function build_registered_v2_model(row::RegisteredTrialV2)
    primitives = _factor_primitives(row)
    beliefs = FiniteBeliefSpace(collect(1:3))
    module_names = (
        :core_a,
        :core_b,
        :core_c,
        :expansion,
        :trigger_a,
        :trigger_b,
        :bridge,
    )
    modules = [GenerativeModule(name) for name in module_names]
    module_ids = Dict(
        name => ModuleId(name) for name in module_names
    )
    project_rng = StableRNG(row.project_seed)
    profiles = _profile_rows(row, beliefs, project_rng)
    catalog_rng = StableRNG(row.catalog_seed)
    core_order = randperm(catalog_rng, 3)
    core_ids = [
        module_ids[(:core_a, :core_b, :core_c)[index]] for
        index in core_order
    ]
    base_modules =
        row.module_overlap == :low ?
        [ModuleSet([core_ids[index]]) for index in 1:3] :
        [ModuleSet(core_ids) for _ in 1:3]
    carrier_modules =
        row.module_complementarity == :weak ?
        ModuleSet([module_ids[:expansion]]) :
        ModuleSet([
            module_ids[:trigger_a],
            module_ids[:trigger_b],
        ])
    rich_requirement =
        row.module_complementarity == :weak ?
        ModuleSet([module_ids[:expansion]]) :
        ModuleSet([module_ids[:bridge]])
    empty_modules = ModuleSet{Symbol}()
    strategies = Strategy{Symbol,Int,Symbol,ER}[
        Strategy(
            :inactive,
            OperationalProfile(beliefs, ER[0, 0, 0]),
            empty_modules,
        ),
    ]
    for index in 1:3
        push!(
            strategies,
            Strategy(
                Symbol("base_$index"),
                OperationalProfile(
                    beliefs,
                    profiles.base_profiles[index],
                ),
                base_modules[index],
            ),
        )
    end
    append!(
        strategies,
        Strategy{Symbol,Int,Symbol,ER}[
            Strategy(
                :frontier_addition,
                OperationalProfile(
                    beliefs,
                    profiles.frontier_profile,
                ),
                empty_modules,
            ),
            Strategy(
                :closure_carrier,
                OperationalProfile(
                    beliefs,
                    profiles.carrier_profile,
                ),
                carrier_modules,
            ),
            Strategy(
                :descendant_1,
                OperationalProfile(
                    beliefs,
                    profiles.descendant_1,
                ),
                empty_modules,
            ),
            Strategy(
                :descendant_2,
                OperationalProfile(
                    beliefs,
                    profiles.descendant_2,
                ),
                empty_modules,
            ),
        ],
    )
    catalog = StrategyCatalog(
        beliefs,
        modules,
        strategies,
        _strategy_id(:inactive),
    )
    closure = if row.module_complementarity == :weak
        identity_generative_closure(modules)
    else
        trigger_a = module_ids[:trigger_a]
        trigger_b = module_ids[:trigger_b]
        bridge = module_ids[:bridge]
        GenerativeClosure(modules, function (available)
            trigger_a in available && trigger_b in available ?
            union(available, ModuleSet([bridge])) :
            available
        end)
    end
    base = RawLibrary(
        catalog,
        StrategyId{Symbol}[
            _strategy_id(:inactive),
            _strategy_id(:base_1),
            _strategy_id(:base_2),
            _strategy_id(:base_3),
        ],
    )
    rectangle = construct_realizable_rectangle(
        catalog,
        closure,
        base,
        _strategy_id(:frontier_addition),
        _strategy_id(:closure_carrier),
    )
    states = rectangle_states(rectangle)
    poor_requirement =
        row.boundary_mechanism == :positive_poor_exposure ?
        ModuleSet([first(core_ids)]) : rich_requirement
    projects = UnifiedResearchProject{Symbol,Symbol}[
        UnifiedResearchProject(
            :project_1,
            poor_requirement,
            primitives.duration,
            true,
        ),
        UnifiedResearchProject(
            :project_2,
            rich_requirement,
            primitives.duration,
            true,
        ),
    ]
    frontier_cutoff = (
        sum(states.L00.frontier.values; init = exact_rational(0)) +
        sum(states.L10.frontier.values; init = exact_rational(0))
    ) / 2
    descendant_1 = _strategy_id(:descendant_1)
    descendant_2 = _strategy_id(:descendant_2)
    frontier_sensitive =
        row.boundary_mechanism == :frontier_dependent_generator
    project_candidates = Dict(
        _project_id(:project_1) => (
            descendant_1,
            frontier_sensitive ? descendant_2 : descendant_1,
        ),
        _project_id(:project_2) => (
            descendant_1,
            frontier_sensitive ? descendant_2 : descendant_1,
        ),
    )
    generation = V2StateGeneration{Symbol,Int,Symbol}(
        project_candidates,
        frontier_sensitive,
        frontier_cutoff,
    )
    candidate_set = Set([descendant_1, descendant_2])
    verification = function (_, _, _, strategy_id)
        return strategy_id in candidate_set ?
               primitives.admission : exact_rational(0)
    end
    cost = (_, _, _) -> primitives.cost
    kernel =
        _cyclic_exact_kernel(beliefs, primitives.persistence)
    completion = (
        project,
        belief,
        state,
    ) -> _completion_law(
        generation,
        verification,
        kernel,
        project,
        belief,
        state,
    )
    process = RawInnovationProcess(
        catalog,
        closure,
        kernel,
        projects,
        generation,
        verification,
        cost,
        completion,
        3 // 4,
    )
    source = rectangle.L11
    active_ids = [
        strategy_id for strategy_id in source if
        strategy_id != catalog.inactive_strategy
    ]
    deletion_rng = StableRNG(row.deletion_seed)
    deletion_order =
        active_ids[randperm(deletion_rng, length(active_ids))]
    trial_rng = StableRNG(row.trial_seed)
    trial_draw = rand(trial_rng, UInt64)
    return (;
        row,
        primitives,
        profiles,
        catalog,
        closure,
        rectangle,
        states,
        projects,
        process,
        source,
        deletion_order,
        trial_draw,
        candidate_ids = (descendant_1, descendant_2),
        rich_requirement,
        base_modules,
    )
end

_library_ids(library) = join(
    sort([string(strategy_id.id) for strategy_id in library]),
    ";",
)
_module_ids(modules) =
    join(sort([string(module_id.id) for module_id in modules]), ";")
_frontier_values(profile) =
    join(
        (
            "$(numerator(value))//$(denominator(value))" for
            value in profile.values
        ),
        ";",
    )
_action_name(action) = string(action_label(action))

function _mean_value(process, horizon, library, memo)
    return sum(
        SI._raw_finite_value(
            process,
            horizon,
            belief,
            library,
            memo,
        ) for belief in process.belief_kernel.space;
        init = exact_rational(0),
    ) / exact_rational(length(process.belief_kernel.space))
end

function _passive_mean(process, horizon, library)
    return SI._passive_average(process, horizon, library)
end

function _value_components(process, horizon, library, memo)
    passive = _passive_mean(process, horizon, library)
    full = _mean_value(process, horizon, library, memo)
    return (; passive, premium = full - passive, full)
end

function _action_value(
    process,
    horizon,
    belief,
    library,
    action,
    memo,
)
    state = compressed_library_state(
        process.catalog,
        process.closure,
        library,
    )
    if action isa ContinueAction
        return state.frontier[belief] +
               process.discount * expectation(
            transition_distribution(process.belief_kernel, belief),
            next -> SI._raw_finite_value(
                process,
                horizon - 1,
                next,
                library,
                memo,
            ),
        )
    end
    project = SI._resolve_project(process, action.project)
    return -unified_research_cost(
        process,
        belief,
        state,
        project,
    ) + expectation(
        SI._completion_distribution(
            process,
            project,
            belief,
            state,
        ),
        outcome ->
            incumbent_reward(process, state, project, outcome.path) +
            process.discount^project.duration *
            SI._raw_finite_value(
                process,
                horizon - project.duration,
                terminal_belief(outcome),
                raw_library_update(
                    process,
                    library,
                    outcome.admitted,
                ),
                memo,
            ),
    )
end

function _factor_fields(row::RegisteredTrialV2)
    return (
        frontier_density = String(row.frontier_density),
        module_overlap = String(row.module_overlap),
        module_complementarity =
            String(row.module_complementarity),
        project_cost = String(row.project_cost),
        duration = String(row.duration),
        admission = String(row.admission),
        persistence = String(row.persistence),
    )
end

function _frontier_supplier_fraction(model)
    source_ids = StrategyId{Symbol}[
        _strategy_id(:base_1),
        _strategy_id(:base_2),
        _strategy_id(:base_3),
        _strategy_id(:frontier_addition),
    ]
    source = RawLibrary(model.catalog, [
        model.catalog.inactive_strategy;
        source_ids
    ])
    source_frontier = frontier(model.catalog, source)
    suppliers = count(source_ids) do strategy_id
        profile = operational_profile(model.catalog, strategy_id)
        any(
            profile[belief] == source_frontier[belief] for
            belief in model.catalog.beliefs
        )
    end
    return exact_rational(suppliers) / exact_rational(length(source_ids))
end

function _mean_pairwise_jaccard(model)
    assignments = model.base_modules
    total = exact_rational(0)
    count_pairs = 0
    for left in 1:2, right in (left + 1):3
        union_count = length(union(assignments[left], assignments[right]))
        intersection_count =
            length(intersect(assignments[left], assignments[right]))
        total += exact_rational(intersection_count) /
                 exact_rational(union_count)
        count_pairs += 1
    end
    return total / exact_rational(count_pairs)
end

function _frontier_independence_flags(model)
    process = model.process
    states = model.states
    pairs = ((states.L00, states.L10), (states.L01, states.L11))
    availability = true
    cost = true
    generation = true
    verification = true
    completion = true
    for (low, high) in pairs,
        belief in process.belief_kernel.space,
        project in process.projects
        availability &=
            project_available(process, low, project) ==
            project_available(process, high, project)
        cost &=
            unified_research_cost(process, belief, low, project) ==
            unified_research_cost(process, belief, high, project)
        generation &=
            candidate_generation_distribution(
                process,
                project,
                belief,
                low,
            ) ==
            candidate_generation_distribution(
                process,
                project,
                belief,
                high,
            )
        completion &=
            SI._completion_distribution(
                process,
                project,
                belief,
                low,
            ) ==
            SI._completion_distribution(
                process,
                project,
                belief,
                high,
            )
        for strategy_row in process.catalog.strategies
            verification &=
                admission_probability(
                    process,
                    project,
                    belief,
                    low,
                    strategy_row.id,
                ) ==
                admission_probability(
                    process,
                    project,
                    belief,
                    high,
                    strategy_row.id,
                )
        end
    end
    return (;
        availability,
        cost,
        generation,
        verification,
        completion,
        all =
            availability &&
            cost &&
            generation &&
            verification &&
            completion,
    )
end

function _common_gap_flags(model, horizon, raw_memo)
    process = model.process
    libraries = rectangle_libraries(model.rectangle)
    menus_frontier_independent = true
    menu_inclusion = true
    gap_antitone = true
    rich_exposure_nonnegative = true
    poor_exposure_zero = true
    identities = true
    rich_exposure_min = nothing
    poor_exposure_max = exact_rational(0)
    for remaining in 1:horizon
        menus = rectangle_action_menus(
            model.rectangle,
            process;
            horizon = remaining,
        )
        menus_frontier_independent &=
            menus.L00 == menus.L10 && menus.L01 == menus.L11
        menu_inclusion &=
            all(action -> action in menus.L01, menus.L00) &&
            all(action -> action in menus.L11, menus.L10)
        for belief in process.belief_kernel.space
        gap_low = sum(
            process.discount^time for time in 0:(remaining - 1);
            init = exact_rational(0),
        )
        gap_high = exact_rational(0)
        gap_antitone &= gap_high <= gap_low
        base_low = _action_value(
            process,
            remaining,
            belief,
            libraries.L00,
            first(menus.L00),
            raw_memo,
        )
        base_high = _action_value(
            process,
            remaining,
            belief,
            libraries.L10,
            first(menus.L10),
            raw_memo,
        )
        for (closure_level, low_library, high_library, menu) in (
            (:poor, libraries.L00, libraries.L10, menus.L00),
            (:rich, libraries.L01, libraries.L11, menus.L01),
        )
            for action in menu
                low_value = _action_value(
                    process,
                    remaining,
                    belief,
                    low_library,
                    action,
                    raw_memo,
                )
                high_value = _action_value(
                    process,
                    remaining,
                    belief,
                    high_library,
                    action,
                    raw_memo,
                )
                low_relative = low_value - base_low
                high_relative = high_value - base_high
                exposure =
                    (low_relative - high_relative) /
                    (gap_low - gap_high)
                intercept =
                    high_relative - exposure * gap_high
                identities &=
                    low_value ==
                    base_low + intercept + exposure * gap_low
                identities &=
                    high_value ==
                    base_high + intercept + exposure * gap_high
                if closure_level == :rich
                    rich_exposure_nonnegative &= exposure >= 0
                    rich_exposure_min =
                        isnothing(rich_exposure_min) ?
                        exposure : min(rich_exposure_min, exposure)
                else
                    poor_exposure_zero &= iszero(exposure)
                    poor_exposure_max =
                        max(poor_exposure_max, exposure)
                end
            end
        end
        end
    end
    return (;
        menus_frontier_independent,
        menu_inclusion,
        gap_antitone,
        rich_exposure_nonnegative,
        poor_exposure_zero,
        identities,
        rich_exposure_min =
            isnothing(rich_exposure_min) ?
            exact_rational(0) : rich_exposure_min,
        poor_exposure_max,
    )
end

function _all_values_agree(model, horizon)
    process = model.process
    raw_memo = Dict{Tuple,ER}()
    compressed_memo = Dict{Tuple,ER}()
    comparisons = 0
    for remaining in 0:horizon,
        library in process.raw_libraries,
        belief in process.belief_kernel.space
        state = compressed_library_state(
            process.catalog,
            process.closure,
            library,
        )
        raw_value = SI._raw_finite_value(
            process,
            remaining,
            belief,
            library,
            raw_memo,
        )
        compressed_value = SI._compressed_finite_value(
            process,
            remaining,
            belief,
            state,
            compressed_memo,
        )
        raw_value isa ER && compressed_value isa ER ||
            error("non-Rational{BigInt} value in registered trial")
        raw_value == compressed_value ||
            error("raw/compressed value mismatch")
        comparisons += 1
    end
    return (; raw_memo, compressed_memo, comparisons)
end

function _pruning_row(
    model,
    method,
    pruned,
    source_values,
    pruned_values,
)
    source_state = model.states.L11
    pruned_state = compressed_library_state(
        model.catalog,
        model.closure,
        pruned,
    )
    operational_loss =
        source_values.passive - pruned_values.passive
    generative_loss =
        source_values.premium - pruned_values.premium
    total_loss = source_values.full - pruned_values.full
    frontier_loss = sum(
        source_state.frontier[belief] -
        pruned_state.frontier[belief] for
        belief in model.catalog.beliefs;
        init = exact_rational(0),
    )
    closure_loss_count =
        length(setdiff(source_state.closure, pruned_state.closure))
    return (
        trial_id = model.row.trial_id,
        _factor_fields(model.row)...,
        method = String(method),
        source_size = length(model.source),
        retained_size = length(pruned),
        removed_count = length(model.source) - length(pruned),
        retention_ratio =
            exact_rational(length(pruned)) /
            exact_rational(length(model.source)),
        compression_ratio =
            exact_rational(length(model.source) - length(pruned)) /
            exact_rational(length(model.source)),
        frontier_loss,
        closure_loss_count,
        passive_value = pruned_values.passive,
        research_option_premium = pruned_values.premium,
        total_value = pruned_values.full,
        signed_operational_loss = operational_loss,
        signed_generative_loss = generative_loss,
        signed_total_dynamic_loss = total_loss,
        decomposition_gate =
            total_loss == operational_loss + generative_loss,
        retained_ids = _library_ids(pruned),
    )
end

function _transition_rows(model)
    rows = NamedTuple[]
    for row in rectangle_raw_transitions(
        model.rectangle,
        model.process;
        horizon = 4,
    )
        for (atom_index, (outcome, mass)) in enumerate(
            zip(row.law.outcomes, row.law.probabilities),
        )
            push!(
                rows,
                (
                    trial_id = model.row.trial_id,
                    corner = String(row.corner),
                    belief = row.belief.id,
                    action = _action_name(row.action),
                    atom_index,
                    holding_time = outcome.holding_time,
                    reward = outcome.reward,
                    probability = mass,
                    next_belief = outcome.next_state.belief.id,
                    next_library_ids =
                        _library_ids(outcome.next_state.library),
                    source_library_ids = _library_ids(row.library),
                    source_frontier =
                        _frontier_values(row.state.frontier),
                    source_closure = _module_ids(row.state.closure),
                ),
            )
        end
    end
    return rows
end

function _action_rows(model, libraries, horizon, raw_memo)
    rows = NamedTuple[]
    for (carrier_name, library) in pairs(libraries),
        remaining in 1:horizon,
        belief in model.process.belief_kernel.space
        state = compressed_library_state(
            model.catalog,
            model.closure,
            library,
        )
        actions = unified_available_actions(
            model.process,
            state;
            horizon = remaining,
        )
        values = ER[
            _action_value(
                model.process,
                remaining,
                belief,
                library,
                action,
                raw_memo,
            ) for action in actions
        ]
        best = maximum(values)
        tie_count = count(==(best), values)
        for (action, value) in zip(actions, values)
            push!(
                rows,
                (
                    trial_id = model.row.trial_id,
                    carrier = String(carrier_name),
                    remaining_horizon = remaining,
                    belief = belief.id,
                    action = _action_name(action),
                    action_value = value,
                    selected = value == best &&
                               findfirst(==(best), values) ==
                               findfirst(==(action), actions),
                    maximizing_tie_count = tie_count,
                    menu_size = length(actions),
                    raw_library_ids = _library_ids(library),
                    frontier = _frontier_values(state.frontier),
                    closure = _module_ids(state.closure),
                ),
            )
        end
    end
    return rows
end

function _witness_rows(model)
    rows = NamedTuple[]
    for (state_index, state) in
        enumerate(model.process.compressed_states)
        witness_index = findfirst(
            library -> compressed_library_state(
                model.catalog,
                model.closure,
                library,
            ) == state,
            model.process.raw_libraries,
        )
        isnothing(witness_index) &&
            error("compressed state lacks a raw-library witness")
        witness = model.process.raw_libraries[witness_index]
        push!(
            rows,
            (
                trial_id = model.row.trial_id,
                compressed_state_index = state_index,
                frontier = _frontier_values(state.frontier),
                closure = _module_ids(state.closure),
                witness_library_ids = _library_ids(witness),
                witness_valid = begin
                    validate_library(model.catalog, witness)
                    true
                end,
            ),
        )
    end
    return rows
end

function run_registered_v2_trial(
    row::RegisteredTrialV2;
    horizon::Integer = 4,
    operational_budget_fraction = 1 // 10,
    generative_budget_fraction = 1 // 20,
)
    horizon == 4 ||
        error("registered v2 horizon must remain four")
    model = build_registered_v2_model(row)
    consistency = rectangle_consistency(
        model.rectangle,
        model.process;
        horizon,
    )
    consistency.all_pass ||
        error("trial $(row.trial_id) failed rectangle consistency")
    density = _frontier_supplier_fraction(model)
    overlap = _mean_pairwise_jaccard(model)
    density_gate =
        row.frontier_density == :sparse ?
        density <= 1 // 2 : density >= 3 // 4
    overlap_gate =
        row.module_overlap == :low ?
        overlap <= 1 // 4 : overlap >= 2 // 3
    density_gate ||
        error("trial $(row.trial_id) failed frontier-density gate")
    overlap_gate ||
        error("trial $(row.trial_id) failed module-overlap gate")

    value_audit = _all_values_agree(model, Int(horizon))
    raw_memo = value_audit.raw_memo
    source_values = _value_components(
        model.process,
        Int(horizon),
        model.source,
        raw_memo,
    )
    source_values.full > 0 ||
        error("trial $(row.trial_id) has nonpositive source value")
    frontier_pruned = frontier_only_prune(
        model.catalog,
        model.source;
        deletion_order = model.deletion_order,
    )
    safe_pruned = innovation_safe_prune_fixed_point(
        model.catalog,
        model.closure,
        model.source;
        deletion_order = model.deletion_order,
    )
    operational_budget =
        exact_rational(operational_budget_fraction) *
        source_values.passive
    generative_budget =
        exact_rational(generative_budget_fraction) *
        source_values.premium
    operational_pruned = SI._budget_prune(
        model.catalog,
        model.source,
        model.deletion_order,
        library -> _passive_mean(
            model.process,
            Int(horizon),
            library,
        ),
        operational_budget,
    )
    generative_pruned = SI._budget_prune(
        model.catalog,
        model.source,
        model.deletion_order,
        library -> _value_components(
            model.process,
            Int(horizon),
            library,
            raw_memo,
        ).premium,
        generative_budget,
    )
    pruned_libraries = (
        frontier_only = frontier_pruned,
        innovation_safe = safe_pruned,
        approx_operational = operational_pruned,
        approx_generative = generative_pruned,
    )
    pruning_rows = NamedTuple[]
    for (method, library) in pairs(pruned_libraries)
        values = _value_components(
            model.process,
            Int(horizon),
            library,
            raw_memo,
        )
        push!(
            pruning_rows,
            _pruning_row(
                model,
                method,
                library,
                source_values,
                values,
            ),
        )
    end
    all(row.decomposition_gate for row in pruning_rows) ||
        error("trial $(row.trial_id) failed loss decomposition")
    frontier_row = pruning_rows[1]
    safe_row = pruning_rows[2]
    iszero(frontier_row.signed_operational_loss) ||
        error("trial $(row.trial_id) frontier pruning changed passive value")
    safe_state = compressed_library_state(
        model.catalog,
        model.closure,
        safe_pruned,
    )
    safe_gate =
        iszero(safe_row.frontier_loss) &&
        iszero(safe_row.closure_loss_count) &&
        iszero(safe_row.signed_operational_loss) &&
        iszero(safe_row.signed_generative_loss) &&
        iszero(safe_row.signed_total_dynamic_loss) &&
        safe_state == model.states.L11
    safe_gate ||
        error("trial $(row.trial_id) failed innovation-safe zero-loss gate")

    asset_rows = NamedTuple[]
    for strategy_id in model.source
        strategy_id == model.catalog.inactive_strategy && continue
        deleted = delete_strategy(
            model.catalog,
            model.source,
            strategy_id,
        )
        values = _value_components(
            model.process,
            Int(horizon),
            deleted,
            raw_memo,
        )
        deleted_state = compressed_library_state(
            model.catalog,
            model.closure,
            deleted,
        )
        operational_loss =
            source_values.passive - values.passive
        generative_loss =
            source_values.premium - values.premium
        total_loss = source_values.full - values.full
        frontier_preserved =
            deleted_state.frontier == model.states.L11.frontier
        closure_changes =
            deleted_state.closure != model.states.L11.closure
        unique_closure_count = length(
            setdiff(
                model.states.L11.closure,
                deleted_state.closure,
            ),
        )
        decomposition_gate =
            total_loss == operational_loss + generative_loss
        decomposition_gate ||
            error("trial $(row.trial_id) asset decomposition failed")
        push!(
            asset_rows,
            (
                trial_id = row.trial_id,
                _factor_fields(row)...,
                strategy_id = String(strategy_id.id),
                source_asset = true,
                frontier_preserved,
                closure_changes,
                unique_closure_count,
                operationally_silent_generative =
                    frontier_preserved &&
                    closure_changes &&
                    total_loss > 0,
                signed_operational_loss = operational_loss,
                signed_generative_loss = generative_loss,
                signed_total_dynamic_loss = total_loss,
                decomposition_gate,
                deleted_library_ids = _library_ids(deleted),
            ),
        )
    end

    corner_values = Dict{Symbol,ER}()
    corner_rows = NamedTuple[]
    libraries = rectangle_libraries(model.rectangle)
    for (corner, library) in pairs(libraries)
        state = getproperty(model.states, corner)
        values = _value_components(
            model.process,
            Int(horizon),
            library,
            raw_memo,
        )
        corner_values[corner] = values.full
        push!(
            corner_rows,
            (
                trial_id = row.trial_id,
                corner = String(corner),
                raw_library_ids = _library_ids(library),
                raw_library_valid = begin
                    validate_library(model.catalog, library)
                    true
                end,
                frontier = _frontier_values(state.frontier),
                closure = _module_ids(state.closure),
                passive_value = values.passive,
                research_option_premium = values.premium,
                total_value = values.full,
                shared_catalog = true,
                shared_closure = true,
                raw_compressed_value_gate =
                    consistency.finite_values_agree,
            ),
        )
    end
    interaction = (
        corner_values[:L11] - corner_values[:L10]
    ) - (
        corner_values[:L01] - corner_values[:L00]
    )
    interaction_sign =
        interaction < 0 ? "substitution" :
        interaction > 0 ? "complementarity" : "zero"

    frontier_flags = _frontier_independence_flags(model)
    common_gap = _common_gap_flags(
        model,
        Int(horizon),
        raw_memo,
    )
    primitive_predicate =
        consistency.all_pass &&
        frontier_flags.all &&
        common_gap.menus_frontier_independent &&
        common_gap.menu_inclusion &&
        common_gap.gap_antitone &&
        common_gap.rich_exposure_nonnegative &&
        common_gap.poor_exposure_zero &&
        common_gap.identities
    if row.theorem_regime == :primitive_eligible
        primitive_predicate ||
            error(
                "trial $(row.trial_id) intended eligible predicate failed",
            )
    else
        primitive_predicate &&
            error(
                "trial $(row.trial_id) intended boundary predicate passed",
            )
        if row.boundary_mechanism ==
           :frontier_dependent_generator
            frontier_flags.generation &&
                error(
                    "trial $(row.trial_id) missed frontier-dependent boundary",
                )
        elseif row.boundary_mechanism ==
               :positive_poor_exposure
            common_gap.poor_exposure_zero &&
                error(
                    "trial $(row.trial_id) missed positive-poor-exposure boundary",
                )
        else
            error("unregistered boundary mechanism")
        end
    end
    primitive_predicate && interaction > 0 &&
        error(
            "trial $(row.trial_id) violates primitive interaction sign gate",
        )

    action_libraries = (
        L00 = libraries.L00,
        L01 = libraries.L01,
        L10 = libraries.L10,
        L11 = libraries.L11,
        frontier_only = frontier_pruned,
        innovation_safe = safe_pruned,
    )
    action_rows = _action_rows(
        model,
        action_libraries,
        Int(horizon),
        raw_memo,
    )
    witness_rows = _witness_rows(model)
    all(row.witness_valid for row in witness_rows) ||
        error("trial $(row.trial_id) has an invalid raw witness")

    profile_rows = NamedTuple[]
    for strategy_row in model.catalog.strategies,
        belief in model.catalog.beliefs
        push!(
            profile_rows,
            (
                trial_id = row.trial_id,
                strategy_id = String(strategy_row.id.id),
                belief = belief.id,
                profile_value =
                    strategy_row.operational_profile[belief],
                in_source = strategy_row.id in model.source,
                is_candidate =
                    strategy_row.id in model.candidate_ids,
                is_inactive =
                    strategy_row.id ==
                    model.catalog.inactive_strategy,
            ),
        )
    end
    module_rows = NamedTuple[]
    for strategy_row in model.catalog.strategies,
        module_row in model.catalog.modules
        push!(
            module_rows,
            (
                trial_id = row.trial_id,
                strategy_id = String(strategy_row.id.id),
                module_id = String(module_row.id.id),
                supplied = module_row.id in strategy_row.modules,
                in_source = strategy_row.id in model.source,
                is_candidate =
                    strategy_row.id in model.candidate_ids,
            ),
        )
    end
    closure_entries = sort(
        collect(model.closure.table);
        by = entry -> _module_ids(first(entry)),
    )
    closure_rows = NamedTuple[
        (
            trial_id = row.trial_id,
            input_modules = _module_ids(first(entry)),
            closed_modules = _module_ids(last(entry)),
        ) for entry in closure_entries
    ]
    kernel_rows = NamedTuple[
        (
            trial_id = row.trial_id,
            current_belief = current.id,
            next_belief = next.id,
            probability = transition_probability(
                model.process.belief_kernel,
                current,
                next,
            ),
        ) for current in model.catalog.beliefs for
        next in model.catalog.beliefs
    ]
    project_rows = NamedTuple[]
    for project in model.projects,
        corner in keys(libraries)
        state = getproperty(model.states, corner)
        push!(
            project_rows,
            (
                trial_id = row.trial_id,
                project_id = String(project.id.id),
                corner = String(corner),
                requirements = _module_ids(project.requirements),
                duration = project.duration,
                operates_during_research =
                    project.operates_during_research,
                available =
                    project_available(model.process, state, project),
                cost = unified_research_cost(
                    model.process,
                    first(model.catalog.beliefs),
                    state,
                    project,
                ),
                admission_probability =
                    model.primitives.admission,
                candidate_law = join(
                    (
                        "$(is_failure(outcome) ? "failure" : string(outcome.strategy.id)):" *
                        "$(numerator(mass))//$(denominator(mass))" for
                        (outcome, mass) in zip(
                            candidate_generation_distribution(
                                model.process,
                                project,
                                first(model.catalog.beliefs),
                                state,
                            ).outcomes,
                            candidate_generation_distribution(
                                model.process,
                                project,
                                first(model.catalog.beliefs),
                                state,
                            ).probabilities,
                        )
                    ),
                    ";",
                ),
            ),
        )
    end

    silent_count = count(
        row -> row.operationally_silent_generative,
        asset_rows,
    )
    descendant_quality = maximum(
        sum(
            max(
                exact_rational(0),
                operational_profile(model.catalog, candidate)[belief] -
                model.states.L11.frontier[belief],
            ) for belief in model.catalog.beliefs;
            init = exact_rational(0),
        ) / exact_rational(length(model.catalog.beliefs)) for
        candidate in model.candidate_ids
    )
    trial_row = (
        trial_id = row.trial_id,
        batch_id = row.batch_id,
        within_batch_order = row.within_batch_order,
        principal_cell_id = row.principal_cell_id,
        canonical_index = row.canonical_index,
        replicate_id = row.replicate_id,
        theorem_regime = String(row.theorem_regime),
        boundary_mechanism = String(row.boundary_mechanism),
        _factor_fields(row)...,
        schedule_key = row.schedule_key,
        trial_seed = row.trial_seed,
        catalog_seed = row.catalog_seed,
        project_seed = row.project_seed,
        deletion_seed = row.deletion_seed,
        trial_seed_draw = model.trial_draw,
        arithmetic = "Rational{BigInt}",
        theorem_evidence = false,
        horizon = Int(horizon),
        discount_factor = model.process.discount,
        source_library_ids = _library_ids(model.source),
        source_size = length(model.source),
        source_closure_size = length(model.states.L11.closure),
        source_passive_value = source_values.passive,
        source_research_option_premium = source_values.premium,
        source_total_value = source_values.full,
        realized_frontier_supplier_fraction = density,
        realized_module_overlap = overlap,
        descendant_quality,
        frontier_only_signed_total_dynamic_loss =
            frontier_row.signed_total_dynamic_loss,
        innovation_safe_signed_total_dynamic_loss =
            safe_row.signed_total_dynamic_loss,
        silent_generative_asset_count = silent_count,
        active_asset_count = length(asset_rows),
        frontier_closure_J = interaction,
        interaction_sign,
        frontier_only_compression_ratio =
            frontier_row.compression_ratio,
        innovation_safe_compression_ratio =
            safe_row.compression_ratio,
        four_raw_witnesses = length(corner_rows) == 4,
        all_compressed_states_have_raw_witnesses =
            length(witness_rows) ==
            length(model.process.compressed_states),
        raw_compressed_value_comparisons =
            value_audit.comparisons,
        raw_compressed_values_agree = true,
        rectangle_consistency = consistency.all_pass,
        project_laws_follow_actual_state =
            consistency.project_laws_follow_corner_state,
        frontier_density_gate = density_gate,
        module_overlap_gate = overlap_gate,
        frontier_independent_availability =
            frontier_flags.availability,
        frontier_independent_cost = frontier_flags.cost,
        frontier_independent_generation =
            frontier_flags.generation,
        frontier_independent_verification =
            frontier_flags.verification,
        frontier_independent_completion =
            frontier_flags.completion,
        frontier_independent_primitives =
            frontier_flags.all,
        frontier_independent_menus =
            common_gap.menus_frontier_independent,
        poor_to_rich_menu_inclusion =
            common_gap.menu_inclusion,
        antitone_recursive_descendant_gap =
            common_gap.gap_antitone,
        nonnegative_rich_exposure =
            common_gap.rich_exposure_nonnegative,
        zero_poor_exposure =
            common_gap.poor_exposure_zero,
        common_gap_action_value_identities =
            common_gap.identities,
        minimum_rich_exposure =
            common_gap.rich_exposure_min,
        maximum_poor_exposure =
            common_gap.poor_exposure_max,
        computed_primitive_predicate =
            primitive_predicate,
        primitive_interaction_sign_gate =
            !primitive_predicate || interaction <= 0,
        frontier_only_passive_zero_gate =
            iszero(frontier_row.signed_operational_loss),
        innovation_safe_exact_zero_gate = safe_gate,
        all_decompositions_exact =
            all(row.decomposition_gate for row in pruning_rows) &&
            all(row.decomposition_gate for row in asset_rows),
        all_exact_outputs_rational = true,
        all_hard_gates_pass = true,
    )

    return V2TrialResult(
        trial_row,
        corner_rows,
        _transition_rows(model),
        pruning_rows,
        asset_rows,
        action_rows,
        profile_rows,
        module_rows,
        closure_rows,
        kernel_rows,
        project_rows,
        witness_rows,
    )
end

end
