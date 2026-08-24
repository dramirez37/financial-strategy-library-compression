"""
    RandomizedLibraryParameters

One exact, deterministic finite-library stress-test design point. Randomness
selects a finite model; every probability, payoff, Bellman value, and loss
inside that model is then evaluated with `Rational{BigInt}`. The randomized
suite is an economic-relevance diagnostic and is never theorem evidence.
"""
struct RandomizedLibraryParameters
    trial_id::Int
    seed::Int
    belief_count::Int
    strategy_count::Int
    module_count::Int
    module_overlap::Symbol
    closure_structure::Symbol
    frontier_density::ExactRational
    candidate_quality::ExactRational
    generator_complementarity::Int
    research_cost::ExactRational
    project_delay::Int
    admission_probability::ExactRational
    regime_persistence::ExactRational
end

Base.:(==)(
    left::RandomizedLibraryParameters,
    right::RandomizedLibraryParameters,
) = all(
    getfield(left, field) == getfield(right, field) for
    field in fieldnames(RandomizedLibraryParameters)
)

function RandomizedLibraryParameters(;
    trial_id::Integer,
    seed::Integer,
    belief_count::Integer,
    strategy_count::Integer,
    module_count::Integer,
    module_overlap,
    closure_structure,
    frontier_density,
    candidate_quality,
    generator_complementarity::Integer,
    research_cost,
    project_delay::Integer,
    admission_probability,
    regime_persistence,
)
    parameters = RandomizedLibraryParameters(
        Int(trial_id),
        Int(seed),
        Int(belief_count),
        Int(strategy_count),
        Int(module_count),
        Symbol(module_overlap),
        Symbol(closure_structure),
        exact_rational(frontier_density),
        exact_rational(candidate_quality),
        Int(generator_complementarity),
        exact_rational(research_cost),
        Int(project_delay),
        exact_rational(admission_probability),
        exact_rational(regime_persistence),
    )
    parameters.trial_id >= 1 ||
        throw(ArgumentError("trial_id must be positive"))
    parameters.seed >= 0 || throw(ArgumentError("trial seed must be nonnegative"))
    parameters.belief_count >= 2 ||
        throw(ArgumentError("randomized stress tests require at least two beliefs"))
    parameters.strategy_count >= 3 || throw(
        ArgumentError("strategy_count includes inactive and must be at least three"),
    )
    parameters.module_count >= 2 ||
        throw(ArgumentError("randomized stress tests require at least two modules"))
    parameters.module_overlap in (:low, :medium, :high) ||
        throw(ArgumentError("module_overlap must be low, medium, or high"))
    parameters.closure_structure in (:identity, :blocks, :hierarchy) ||
        throw(ArgumentError("closure_structure must be identity, blocks, or hierarchy"))
    0 <= parameters.frontier_density <= 1 ||
        throw(ArgumentError("frontier_density must lie in [0,1]"))
    parameters.candidate_quality >= 0 ||
        throw(ArgumentError("candidate_quality must be nonnegative"))
    1 <= parameters.generator_complementarity <= parameters.module_count ||
        throw(ArgumentError("generator complementarity exceeds the module carrier"))
    parameters.research_cost >= 0 ||
        throw(ArgumentError("research_cost must be nonnegative"))
    parameters.project_delay >= 1 ||
        throw(ArgumentError("project_delay must be positive"))
    0 <= parameters.admission_probability <= 1 ||
        throw(ArgumentError("admission_probability must lie in [0,1]"))
    0 <= parameters.regime_persistence <= 1 ||
        throw(ArgumentError("regime_persistence must lie in [0,1]"))
    return parameters
end

"""
Complete machine-readable rows returned by a randomized stress run.
"""
struct RandomizedLibraryStressResult
    trial_rows::Vector{NamedTuple}
    pruning_rows::Vector{NamedTuple}
    carrier_rows::Vector{NamedTuple}
    profile_rows::Vector{NamedTuple}
    module_rows::Vector{NamedTuple}
    closure_rows::Vector{NamedTuple}
    kernel_rows::Vector{NamedTuple}
    project_rows::Vector{NamedTuple}
end

function _balanced_random_column(rng, levels, trial_count)
    isempty(levels) && throw(ArgumentError("factor levels cannot be empty"))
    trial_count % length(levels) == 0 || throw(
        ArgumentError("trial_count must be divisible by every factor-level count"),
    )
    values = [levels[mod1(index, length(levels))] for index in 1:trial_count]
    shuffle!(rng, values)
    return values
end

"""
    randomized_library_factor_design(trial_count, master_seed; levels...)

Build a deterministic marginally balanced randomized design. Each factor
column is independently shuffled with `StableRNG`; no trial is sampled or
solved with floating-point arithmetic.
"""
function randomized_library_factor_design(
    trial_count::Integer,
    master_seed::Integer;
    belief_count = (2, 3, 4),
    strategy_count = (4, 5, 6),
    module_count = (3, 4, 5),
    module_overlap = (:low, :medium, :high),
    closure_structure = (:identity, :blocks, :hierarchy),
    frontier_density = (1 // 4, 1 // 2, 3 // 4),
    candidate_quality = (3 // 4, 1 // 1, 5 // 4),
    generator_complementarity = (1, 2, 3),
    research_cost = (0 // 1, 2 // 1, 4 // 1),
    project_delay = (1, 2, 3),
    admission_probability = (1 // 4, 1 // 2, 3 // 4),
    regime_persistence = (1 // 4, 1 // 2, 3 // 4),
)
    trial_count >= 1 || throw(ArgumentError("trial_count must be positive"))
    master_seed >= 0 || throw(ArgumentError("master_seed must be nonnegative"))
    rng = StableRNG(Int(master_seed))
    factors = (
        belief_count = _balanced_random_column(rng, collect(belief_count), trial_count),
        strategy_count = _balanced_random_column(rng, collect(strategy_count), trial_count),
        module_count = _balanced_random_column(rng, collect(module_count), trial_count),
        module_overlap = _balanced_random_column(rng, collect(module_overlap), trial_count),
        closure_structure =
            _balanced_random_column(rng, collect(closure_structure), trial_count),
        frontier_density =
            _balanced_random_column(rng, collect(frontier_density), trial_count),
        candidate_quality =
            _balanced_random_column(rng, collect(candidate_quality), trial_count),
        generator_complementarity = _balanced_random_column(
            rng,
            collect(generator_complementarity),
            trial_count,
        ),
        research_cost =
            _balanced_random_column(rng, collect(research_cost), trial_count),
        project_delay =
            _balanced_random_column(rng, collect(project_delay), trial_count),
        admission_probability = _balanced_random_column(
            rng,
            collect(admission_probability),
            trial_count,
        ),
        regime_persistence = _balanced_random_column(
            rng,
            collect(regime_persistence),
            trial_count,
        ),
    )
    trial_seeds = Int[rand(rng, UInt32) for _ in 1:trial_count]
    return RandomizedLibraryParameters[
        RandomizedLibraryParameters(
            trial_id = trial_id,
            seed = trial_seeds[trial_id],
            belief_count = factors.belief_count[trial_id],
            strategy_count = factors.strategy_count[trial_id],
            module_count = factors.module_count[trial_id],
            module_overlap = factors.module_overlap[trial_id],
            closure_structure = factors.closure_structure[trial_id],
            frontier_density = factors.frontier_density[trial_id],
            candidate_quality = factors.candidate_quality[trial_id],
            generator_complementarity =
                factors.generator_complementarity[trial_id],
            research_cost = factors.research_cost[trial_id],
            project_delay = factors.project_delay[trial_id],
            admission_probability = factors.admission_probability[trial_id],
            regime_persistence = factors.regime_persistence[trial_id],
        ) for trial_id in 1:trial_count
    ]
end

_strategy_symbol(index) = Symbol("strategy_", index)
_module_symbol(index) = Symbol("module_", index)
_project_symbol(index) = Symbol("project_", index)
_candidate_symbol(index) = Symbol("candidate_", index)

function _exact_bernoulli(rng, probability::ExactRational)
    probability == 0 && return false
    probability == 1 && return true
    return rand(rng, 1:Int(denominator(probability))) <=
           Int(numerator(probability))
end

function _random_module_assignments(rng, active_count, module_count, overlap)
    assignments = [Int[] for _ in 1:active_count]
    for module_index in 1:module_count
        push!(assignments[mod1(module_index, active_count)], module_index)
    end
    target = if overlap == :low
        maximum(length, assignments)
    elseif overlap == :medium
        cld(module_count, 2)
    else
        max(module_count - 1, 1)
    end
    for strategy_index in 1:active_count
        target_count = max(target, length(assignments[strategy_index]))
        for module_index in randperm(rng, module_count)
            length(assignments[strategy_index]) >= target_count && break
            module_index in assignments[strategy_index] ||
                push!(assignments[strategy_index], module_index)
        end
        sort!(assignments[strategy_index])
    end
    return assignments
end

function _closure_from_structure(modules, structure)
    structure == :identity && return identity_generative_closure(modules)
    ids = [module_row.id for module_row in modules]
    if structure == :blocks
        close_blocks = function (supplied)
            result = supplied
            for first_index in 1:2:length(ids)
                block = ids[first_index:min(first_index + 1, length(ids))]
                any(module_id -> module_id in supplied, block) || continue
                result = union(result, ModuleSet(collect(block)))
            end
            return result
        end
        return GenerativeClosure(modules, close_blocks)
    end
    close_hierarchy = function (supplied)
        isempty(supplied) && return supplied
        highest = maximum(
            findfirst(==(module_id), ids) for module_id in supplied
        )
        return ModuleSet(ids[1:highest])
    end
    return GenerativeClosure(modules, close_hierarchy)
end

function _cyclic_kernel(space, persistence)
    count = length(space)
    matrix = zeros(ExactRational, count, count)
    for index in 1:count
        matrix[index, index] += persistence
        matrix[index, mod1(index + 1, count)] += 1 - persistence
    end
    return MarkovKernel(space, matrix)
end

function _module_overlap_score(catalog, source)
    ids = [
        strategy_id for strategy_id in source if
        strategy_id != catalog.inactive_strategy
    ]
    pairs = 0
    score = exact_rational(0)
    for left_index in 1:length(ids), right_index in (left_index + 1):length(ids)
        left = strategy_modules(catalog, ids[left_index])
        right = strategy_modules(catalog, ids[right_index])
        intersection = count(module_id -> module_id in right, left)
        union_count = length(union(left, right))
        score += exact_rational(intersection) / exact_rational(union_count)
        pairs += 1
    end
    return iszero(pairs) ? exact_rational(0) :
           score / exact_rational(pairs)
end

function _frontier_density_score(catalog, source)
    source_frontier = frontier(catalog, source)
    active = [
        strategy_id for strategy_id in source if
        strategy_id != catalog.inactive_strategy
    ]
    hits = sum(
        operational_profile(catalog, strategy_id)[belief] ==
        source_frontier[belief] for strategy_id in active for
        belief in catalog.beliefs;
        init = 0,
    )
    return exact_rational(hits) /
           exact_rational(length(active) * length(catalog.beliefs))
end

function _candidate_quality_score(catalog, source, candidate_ids)
    source_frontier = frontier(catalog, source)
    ratios = ExactRational[]
    for candidate_id in candidate_ids, belief in catalog.beliefs
        base = source_frontier[belief]
        iszero(base) && continue
        push!(
            ratios,
            operational_profile(catalog, candidate_id)[belief] / base,
        )
    end
    return sum(ratios; init = exact_rational(0)) /
           exact_rational(length(ratios))
end

function _build_randomized_library_model(parameters::RandomizedLibraryParameters)
    rng = StableRNG(parameters.seed)
    beliefs = FiniteBeliefSpace(collect(1:parameters.belief_count))
    modules = [
        GenerativeModule(_module_symbol(index)) for
        index in 1:parameters.module_count
    ]
    module_ids = [module_row.id for module_row in modules]
    inactive = Strategy(
        :inactive,
        OperationalProfile(beliefs, zeros(Int, parameters.belief_count)),
        ModuleSet{Symbol}(),
    )
    active_count = parameters.strategy_count - 1
    assignments = _random_module_assignments(
        rng,
        active_count,
        parameters.module_count,
        parameters.module_overlap,
    )
    active_rows = Strategy{Symbol,Int,Symbol,ExactRational}[]
    for index in 1:active_count
        values = ExactRational[
            _exact_bernoulli(rng, parameters.frontier_density) ?
            exact_rational(4) : exact_rational(rand(rng, 1:3)) for
            _ in 1:parameters.belief_count
        ]
        push!(
            active_rows,
            Strategy(
                _strategy_symbol(index),
                OperationalProfile(beliefs, values),
                ModuleSet(module_ids[assignments[index]]),
            ),
        )
    end
    provisional = StrategyCatalog(
        beliefs,
        modules,
        [inactive; active_rows],
        StrategyId(:inactive),
    )
    source_ids = [row.id for row in provisional.strategies]
    provisional_source = RawLibrary(provisional, source_ids)
    source_frontier = frontier(provisional, provisional_source)
    candidate_rows = Strategy{Symbol,Int,Symbol,ExactRational}[]
    for candidate_index in 1:2
        values = ExactRational[
            max(
                exact_rational(0),
                parameters.candidate_quality * source_frontier[belief] +
                exact_rational(rand(rng, -1:1)) / 2,
            ) for belief in beliefs
        ]
        module_count = parameters.module_overlap == :low ? 1 :
                       parameters.module_overlap == :medium ?
                       cld(parameters.module_count, 2) :
                       max(parameters.module_count - 1, 1)
        selected = sort(randperm(rng, parameters.module_count)[1:module_count])
        push!(
            candidate_rows,
            Strategy(
                _candidate_symbol(candidate_index),
                OperationalProfile(beliefs, values),
                ModuleSet(module_ids[selected]),
            ),
        )
    end
    catalog = StrategyCatalog(
        beliefs,
        modules,
        [inactive; active_rows; candidate_rows],
        StrategyId(:inactive),
    )
    source = RawLibrary(catalog, source_ids)
    closure = _closure_from_structure(modules, parameters.closure_structure)
    kernel = _cyclic_kernel(beliefs, parameters.regime_persistence)
    candidate_ids = [row.id for row in candidate_rows]
    projects = UnifiedResearchProject{Symbol,Symbol}[]
    requirements = Dict{ResearchProjectId{Symbol},ModuleSet{Symbol}}()
    candidates = Dict{ResearchProjectId{Symbol},StrategyId{Symbol}}()
    for project_index in 1:2
        selected = sort(
            randperm(rng, parameters.module_count)[
                1:parameters.generator_complementarity
            ],
        )
        project = UnifiedResearchProject(
            _project_symbol(project_index),
            ModuleSet(module_ids[selected]),
            parameters.project_delay,
            true,
        )
        push!(projects, project)
        requirements[project.id] = project.requirements
        candidates[project.id] = candidate_ids[project_index]
    end
    failure = CandidateOutcome{Symbol}()
    generation = function (project, _, available)
        issubset(requirements[project.id], available) ||
            return dirac(failure)
        return dirac(CandidateOutcome(candidates[project.id]))
    end
    verification = function (project, _, _, strategy_id)
        return strategy_id == candidates[project.id] ?
               parameters.admission_probability : exact_rational(0)
    end
    cost = (_, _, _) -> parameters.research_cost
    completion = function (project, belief, state)
        available = issubset(requirements[project.id], state.closure)
        admitted = available ? parameters.admission_probability :
                   exact_rational(0)
        success = CandidateOutcome(candidates[project.id])
        outcomes = ProjectCompletionOutcome{Int,Symbol}[]
        masses = ExactRational[]
        for path in _positive_belief_paths(
            kernel,
            belief,
            project.duration,
        )
            path_mass = _markov_path_probability(kernel, belief, path)
            push!(
                outcomes,
                ProjectCompletionOutcome(collect(path), failure),
            )
            push!(masses, path_mass * (1 - admitted))
            push!(
                outcomes,
                ProjectCompletionOutcome(collect(path), success),
            )
            push!(masses, path_mass * admitted)
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
        3 // 4,
    )
    active_ids = [
        strategy_id for strategy_id in source if
        strategy_id != catalog.inactive_strategy
    ]
    deletion_order = active_ids[randperm(rng, length(active_ids))]
    return (;
        catalog,
        closure,
        kernel,
        process,
        source,
        projects,
        candidate_ids,
        deletion_order,
    )
end

"""
    build_randomized_library_model(parameters)

Construct the deterministic exact raw catalog, closure, belief kernel,
candidate projects, admission/completion laws, source library, and deletion
order for one registered randomized-library design point. This public wrapper
supports numerical extensions that reuse the same raw-model source of truth.
Randomized construction remains numerical evidence, never theorem evidence.
"""
build_randomized_library_model(parameters::RandomizedLibraryParameters) =
    _build_randomized_library_model(parameters)

function _passive_average(process, horizon, library)
    state = compressed_library_state(
        process.catalog,
        process.closure,
        library,
    )
    values = zeros(ExactRational, length(process.belief_kernel.space))
    for _ in 1:horizon
        prior = values
        values = ExactRational[
            state.frontier[belief] + process.discount * sum(
                transition_probability(process.belief_kernel, belief, next) *
                prior[belief_index(process.belief_kernel.space, next)] for
                next in process.belief_kernel.space;
                init = exact_rational(0),
            ) for belief in process.belief_kernel.space
        ]
    end
    return sum(values; init = exact_rational(0)) /
           exact_rational(length(values))
end

function _library_evaluator(process, horizon)
    raw_memo = Dict{Tuple,ExactRational}()
    cache = Dict{RawLibrary{Symbol},NamedTuple}()
    return function (library)
        haskey(cache, library) && return cache[library]
        passive = _passive_average(process, horizon, library)
        full = sum(
            _raw_finite_value(
                process,
                horizon,
                belief,
                library,
                raw_memo,
            ) for belief in process.belief_kernel.space;
            init = exact_rational(0),
        ) / exact_rational(length(process.belief_kernel.space))
        result = (
            passive = passive,
            full = full,
            premium = full - passive,
        )
        cache[library] = result
        return result
    end
end

function _budget_prune(
    catalog,
    source,
    deletion_order,
    metric,
    budget,
)
    current = source
    changed = true
    while changed
        changed = false
        for strategy_id in deletion_order
            strategy_id in current || continue
            candidate = delete_strategy(catalog, current, strategy_id)
            max(exact_rational(0), metric(source) - metric(candidate)) <=
                budget || continue
            current = candidate
            changed = true
        end
    end
    return current
end

function _scaled_frontier(profile, scale)
    return OperationalProfile(
        profile.space,
        [scale * value for value in profile.values],
    )
end

function _compressed_average(process, horizon, state, memo)
    return sum(
        _compressed_finite_value(
            process,
            horizon,
            belief,
            state,
            memo,
        ) for belief in process.belief_kernel.space;
        init = exact_rational(0),
    ) / exact_rational(length(process.belief_kernel.space))
end

function _frontier_closure_cross_difference(
    process,
    horizon,
    source,
    frontier_pruned,
)
    rich = compressed_library_state(
        process.catalog,
        process.closure,
        source,
    )
    poor = compressed_library_state(
        process.catalog,
        process.closure,
        frontier_pruned,
    )
    low_frontier = _scaled_frontier(rich.frontier, 1 // 2)
    high_rich = rich
    high_poor = CompressedLibraryState(rich.frontier, poor.closure)
    low_rich = CompressedLibraryState(low_frontier, rich.closure)
    low_poor = CompressedLibraryState(low_frontier, poor.closure)
    memo = Dict{Tuple,ExactRational}()
    values = (
        high_rich = _compressed_average(process, horizon, high_rich, memo),
        high_poor = _compressed_average(process, horizon, high_poor, memo),
        low_rich = _compressed_average(process, horizon, low_rich, memo),
        low_poor = _compressed_average(process, horizon, low_poor, memo),
    )
    interaction =
        (values.high_rich - values.high_poor) -
        (values.low_rich - values.low_poor)
    classification = interaction < 0 ? :substitution :
                     interaction > 0 ? :complementarity : :separable
    return (
        values...,
        interaction,
        classification,
        closure_contrast = rich.closure != poor.closure,
    )
end

function _method_row(
    parameters,
    method,
    source,
    pruned,
    source_values,
    evaluator,
    budget_kind,
    budget_fraction,
    budget_amount,
)
    values = evaluator(pruned)
    signed_operational = source_values.passive - values.passive
    signed_generative = source_values.premium - values.premium
    signed_total = source_values.full - values.full
    decomposition_gate =
        signed_total == signed_operational + signed_generative
    return (
        trial_id = parameters.trial_id,
        method = method,
        source_size = length(source),
        retained_size = length(pruned),
        removed_count = length(source) - length(pruned),
        library_reduction = exact_rational(length(source) - length(pruned)) /
                            exact_rational(length(source)),
        budget_kind = budget_kind,
        budget_fraction = budget_fraction,
        budget_amount = budget_amount,
        passive_value = values.passive,
        research_option_premium = values.premium,
        total_value = values.full,
        signed_operational_loss = signed_operational,
        signed_generative_loss = signed_generative,
        signed_total_dynamic_loss = signed_total,
        operational_loss = max(exact_rational(0), signed_operational),
        generative_loss = max(exact_rational(0), signed_generative),
        total_dynamic_loss = max(exact_rational(0), signed_total),
        future_value_loss = signed_total > 0,
        retained_ids = join(
            (string(strategy_id.id) for strategy_id in pruned),
            ";",
        ),
        decomposition_gate,
    )
end

"""
    run_randomized_library_trial(parameters; horizon=4, ...)

Generate and exactly solve one randomized raw-library model, compare all four
pruning rules, and return complete source and diagnostic rows.
"""
function run_randomized_library_trial(
    parameters::RandomizedLibraryParameters;
    horizon::Integer = 4,
    operational_budget_fraction = 1 // 20,
    generative_budget_fraction = 1 // 20,
)
    horizon >= 1 || throw(ArgumentError("horizon must be positive"))
    operational_fraction = exact_rational(operational_budget_fraction)
    generative_fraction = exact_rational(generative_budget_fraction)
    0 <= operational_fraction <= 1 ||
        throw(ArgumentError("operational budget fraction must lie in [0,1]"))
    0 <= generative_fraction <= 1 ||
        throw(ArgumentError("generative budget fraction must lie in [0,1]"))
    model = _build_randomized_library_model(parameters)
    evaluator = _library_evaluator(model.process, Int(horizon))
    source_values = evaluator(model.source)
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
        operational_fraction * source_values.passive
    generative_budget =
        generative_fraction * source_values.premium
    operational_pruned = _budget_prune(
        model.catalog,
        model.source,
        model.deletion_order,
        library -> evaluator(library).passive,
        operational_budget,
    )
    generative_pruned = _budget_prune(
        model.catalog,
        model.source,
        model.deletion_order,
        library -> evaluator(library).premium,
        generative_budget,
    )
    pruning_rows = NamedTuple[
        _method_row(
            parameters,
            :frontier_only,
            model.source,
            frontier_pruned,
            source_values,
            evaluator,
            :none,
            exact_rational(0),
            exact_rational(0),
        ),
        _method_row(
            parameters,
            :innovation_safe,
            model.source,
            safe_pruned,
            source_values,
            evaluator,
            :none,
            exact_rational(0),
            exact_rational(0),
        ),
        _method_row(
            parameters,
            :approx_operational,
            model.source,
            operational_pruned,
            source_values,
            evaluator,
            :passive_value,
            operational_fraction,
            operational_budget,
        ),
        _method_row(
            parameters,
            :approx_generative,
            model.source,
            generative_pruned,
            source_values,
            evaluator,
            :research_option_premium,
            generative_fraction,
            generative_budget,
        ),
    ]
    interaction = _frontier_closure_cross_difference(
        model.process,
        Int(horizon),
        model.source,
        frontier_pruned,
    )
    carrier_rows = NamedTuple[]
    for strategy_id in model.source
        strategy_id == model.catalog.inactive_strategy && continue
        deleted = delete_strategy(model.catalog, model.source, strategy_id)
        deleted_values = evaluator(deleted)
        signed_operational =
            source_values.passive - deleted_values.passive
        signed_generative =
            source_values.premium - deleted_values.premium
        signed_total = source_values.full - deleted_values.full
        operationally_redundant_flag = operationally_redundant(
            model.catalog,
            model.source,
            strategy_id,
        )
        push!(
            carrier_rows,
            (
                trial_id = parameters.trial_id,
                strategy_id = strategy_id.id,
                operationally_redundant = operationally_redundant_flag,
                closure_changes = !generatively_redundant(
                    model.catalog,
                    model.closure,
                    model.source,
                    strategy_id,
                ),
                generatively_valuable = signed_generative > 0,
                future_value_valuable = signed_total > 0,
                dominated_and_generatively_valuable =
                    operationally_redundant_flag && signed_generative > 0,
                signed_operational_loss = signed_operational,
                signed_generative_loss = signed_generative,
                signed_total_dynamic_loss = signed_total,
                decomposition_gate =
                    signed_total ==
                    signed_operational + signed_generative,
            ),
        )
    end
    profile_rows = NamedTuple[]
    for row in model.catalog.strategies, belief in model.catalog.beliefs
        push!(
            profile_rows,
            (
                trial_id = parameters.trial_id,
                strategy_id = row.id.id,
                belief_id = belief.id,
                profile_value = row.operational_profile[belief],
                in_source = row.id in model.source,
                is_candidate = row.id in model.candidate_ids,
                is_inactive = row.id == model.catalog.inactive_strategy,
            ),
        )
    end
    module_rows = NamedTuple[]
    for row in model.catalog.strategies, module_row in model.catalog.modules
        push!(
            module_rows,
            (
                trial_id = parameters.trial_id,
                strategy_id = row.id.id,
                module_id = module_row.id.id,
                supplied = module_row.id in row.modules,
                in_source = row.id in model.source,
                is_candidate = row.id in model.candidate_ids,
            ),
        )
    end
    closure_rows = NamedTuple[
        (
            trial_id = parameters.trial_id,
            input_modules = join(
                sort([string(module_id.id) for module_id in first(entry)]),
                ";",
            ),
            closed_modules = join(
                sort([string(module_id.id) for module_id in last(entry)]),
                ";",
            ),
        ) for entry in model.closure.table
    ]
    kernel_rows = NamedTuple[
        (
            trial_id = parameters.trial_id,
            current_belief = current.id,
            next_belief = next.id,
            probability = transition_probability(model.kernel, current, next),
        ) for current in model.kernel.space for next in model.kernel.space
    ]
    project_rows = NamedTuple[
        (
            trial_id = parameters.trial_id,
            project_id = project.id.id,
            candidate_id = model.candidate_ids[index].id,
            requirements = join(
                sort([
                    string(module_id.id) for
                    module_id in project.requirements
                ]),
                ";",
            ),
            requirement_count = length(project.requirements),
            duration = project.duration,
            operates_during_research = project.operates_during_research,
            admission_probability = parameters.admission_probability,
            research_cost = parameters.research_cost,
        ) for (index, project) in enumerate(model.projects)
    ]
    frontier_row = only(
        row for row in pruning_rows if row.method == :frontier_only
    )
    dominated_count =
        count(row -> row.operationally_redundant, carrier_rows)
    dominated_generative_count = count(
        row -> row.dominated_and_generatively_valuable,
        carrier_rows,
    )
    trial_row = (
        trial_id = parameters.trial_id,
        seed = parameters.seed,
        belief_count = parameters.belief_count,
        strategy_count = parameters.strategy_count,
        module_count = parameters.module_count,
        module_overlap = parameters.module_overlap,
        actual_module_overlap = _module_overlap_score(
            model.catalog,
            model.source,
        ),
        closure_structure = parameters.closure_structure,
        source_closure_size = length(
            generative_closure(
                model.catalog,
                model.closure,
                model.source,
            ),
        ),
        frontier_density = parameters.frontier_density,
        actual_frontier_density = _frontier_density_score(
            model.catalog,
            model.source,
        ),
        candidate_quality = parameters.candidate_quality,
        actual_candidate_quality = _candidate_quality_score(
            model.catalog,
            model.source,
            model.candidate_ids,
        ),
        generator_complementarity =
            parameters.generator_complementarity,
        research_cost = parameters.research_cost,
        project_delay = parameters.project_delay,
        admission_probability = parameters.admission_probability,
        regime_persistence = parameters.regime_persistence,
        discount_factor = model.process.discount,
        horizon = Int(horizon),
        deletion_order = join(
            (
                string(strategy_id.id) for
                strategy_id in model.deletion_order
            ),
            ";",
        ),
        source_passive_value = source_values.passive,
        source_research_option_premium = source_values.premium,
        source_total_value = source_values.full,
        frontier_only_future_value_loss =
            frontier_row.future_value_loss,
        frontier_only_total_dynamic_loss =
            frontier_row.total_dynamic_loss,
        active_carrier_count = length(carrier_rows),
        operationally_redundant_carrier_count = dominated_count,
        dominated_generatively_valuable_count =
            dominated_generative_count,
        dominated_generatively_valuable_fraction =
            exact_rational(dominated_generative_count) /
            exact_rational(length(carrier_rows)),
        dominated_generatively_valuable_conditional_fraction =
            iszero(dominated_count) ? exact_rational(0) :
            exact_rational(dominated_generative_count) /
            exact_rational(dominated_count),
        frontier_closure_J = interaction.interaction,
        interaction_classification = interaction.classification,
        genuine_closure_contrast = interaction.closure_contrast,
        high_rich_value = interaction.high_rich,
        high_poor_value = interaction.high_poor,
        low_rich_value = interaction.low_rich,
        low_poor_value = interaction.low_poor,
        all_decomposition_gates =
            all(row.decomposition_gate for row in pruning_rows) &&
            all(row.decomposition_gate for row in carrier_rows),
        frontier_passive_gate =
            frontier_row.signed_operational_loss == 0,
        safe_value_gate = only(
            row for row in pruning_rows if
            row.method == :innovation_safe
        ).signed_total_dynamic_loss == 0,
        operational_budget_gate = only(
            row for row in pruning_rows if
            row.method == :approx_operational
        ).operational_loss <= operational_budget,
        generative_budget_gate = only(
            row for row in pruning_rows if
            row.method == :approx_generative
        ).generative_loss <= generative_budget,
        theorem_evidence = false,
        evidence_class =
            "randomized finite-model robustness diagnostic; not theorem evidence",
    )
    all(
        (
            trial_row.all_decomposition_gates,
            trial_row.frontier_passive_gate,
            trial_row.safe_value_gate,
            trial_row.operational_budget_gate,
            trial_row.generative_budget_gate,
        ),
    ) || error("randomized-library exact gate failed in trial $(parameters.trial_id)")
    return (;
        trial_row,
        pruning_rows,
        carrier_rows,
        profile_rows,
        module_rows,
        closure_rows,
        kernel_rows,
        project_rows,
    )
end

"""
    run_randomized_library_stress(design; ...)

Run a vector of deterministic exact trial specifications and concatenate all
machine-readable source and diagnostic rows.
"""
function run_randomized_library_stress(
    design::AbstractVector{RandomizedLibraryParameters};
    horizon::Integer = 4,
    operational_budget_fraction = 1 // 20,
    generative_budget_fraction = 1 // 20,
)
    trial_rows = NamedTuple[]
    pruning_rows = NamedTuple[]
    carrier_rows = NamedTuple[]
    profile_rows = NamedTuple[]
    module_rows = NamedTuple[]
    closure_rows = NamedTuple[]
    kernel_rows = NamedTuple[]
    project_rows = NamedTuple[]
    for parameters in design
        result = run_randomized_library_trial(
            parameters;
            horizon,
            operational_budget_fraction,
            generative_budget_fraction,
        )
        push!(trial_rows, result.trial_row)
        append!(pruning_rows, result.pruning_rows)
        append!(carrier_rows, result.carrier_rows)
        append!(profile_rows, result.profile_rows)
        append!(module_rows, result.module_rows)
        append!(closure_rows, result.closure_rows)
        append!(kernel_rows, result.kernel_rows)
        append!(project_rows, result.project_rows)
    end
    return RandomizedLibraryStressResult(
        trial_rows,
        pruning_rows,
        carrier_rows,
        profile_rows,
        module_rows,
        closure_rows,
        kernel_rows,
        project_rows,
    )
end
