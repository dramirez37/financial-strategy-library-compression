using LinearAlgebra: I

"""Failure or one typed catalog strategy, matching Lean `Option StrategyId`."""
struct CandidateOutcome{S}
    strategy::Union{Nothing,StrategyId{S}}
end

CandidateOutcome{S}() where {S} = CandidateOutcome{S}(nothing)
CandidateOutcome(strategy::StrategyId{S}) where {S} = CandidateOutcome{S}(strategy)
Base.:(==)(left::CandidateOutcome, right::CandidateOutcome) =
    left.strategy == right.strategy
Base.hash(outcome::CandidateOutcome, seed::UInt) =
    hash((:CandidateOutcome, outcome.strategy), seed)
is_failure(outcome::CandidateOutcome) = isnothing(outcome.strategy)

"""
Raw-model project row. `duration` is positive elapsed calendar time and
`operates_during_research` controls the incumbent reward stream.
"""
struct UnifiedResearchProject{P,M}
    id::ResearchProjectId{P}
    requirements::ModuleSet{M}
    duration::Int
    operates_during_research::Bool

    function UnifiedResearchProject{P,M}(
        id::ResearchProjectId{P},
        requirements::ModuleSet{M},
        duration::Integer,
        operates::Bool,
    ) where {P,M}
        duration > 0 ||
            throw(ArgumentError("unified project duration must be strictly positive"))
        new{P,M}(id, requirements, Int(duration), operates)
    end
end

UnifiedResearchProject(
    id,
    requirements::ModuleSet{M},
    duration::Integer,
    operates::Bool = true,
) where {M} = UnifiedResearchProject{typeof(id),M}(
    ResearchProjectId(id),
    requirements,
    duration,
    operates,
)

Base.:(==)(left::UnifiedResearchProject, right::UnifiedResearchProject) =
    left.id == right.id &&
    left.requirements == right.requirements &&
    left.duration == right.duration &&
    left.operates_during_research == right.operates_during_research
Base.hash(project::UnifiedResearchProject, seed::UInt) = hash(
    (
        :UnifiedResearchProject,
        project.id,
        project.requirements,
        project.duration,
        project.operates_during_research,
    ),
    seed,
)

"""Full belief path paired with its possibly correlated admitted outcome."""
struct ProjectCompletionOutcome{B,S}
    path::Tuple{Vararg{Belief{B}}}
    admitted::CandidateOutcome{S}
end

ProjectCompletionOutcome(
    path::AbstractVector{Belief{B}},
    admitted::CandidateOutcome{S},
) where {B,S} = ProjectCompletionOutcome{B,S}(Tuple(path), admitted)
Base.:(==)(left::ProjectCompletionOutcome, right::ProjectCompletionOutcome) =
    left.path == right.path && left.admitted == right.admitted
Base.hash(outcome::ProjectCompletionOutcome, seed::UInt) =
    hash((:ProjectCompletionOutcome, outcome.path, outcome.admitted), seed)
terminal_belief(outcome::ProjectCompletionOutcome) = last(outcome.path)

struct RawTerminalState{B,S}
    belief::Belief{B}
    library::RawLibrary{S}
end
Base.:(==)(left::RawTerminalState, right::RawTerminalState) =
    left.belief == right.belief && left.library == right.library
Base.hash(state::RawTerminalState, seed::UInt) =
    hash((:RawTerminalState, state.belief, state.library), seed)

struct CompressedTerminalState{B,M}
    belief::Belief{B}
    state::CompressedLibraryState{B,M,ExactRational}
end
Base.:(==)(left::CompressedTerminalState, right::CompressedTerminalState) =
    left.belief == right.belief && left.state == right.state
Base.hash(state::CompressedTerminalState, seed::UInt) =
    hash((:CompressedTerminalState, state.belief, state.state), seed)

"""Holding time, complete discounted reward block, and next decision state."""
struct UnifiedEmbeddedOutcome{N}
    holding_time::Int
    reward::ExactRational
    next_state::N
end
Base.:(==)(left::UnifiedEmbeddedOutcome, right::UnifiedEmbeddedOutcome) =
    left.holding_time == right.holding_time &&
    left.reward == right.reward &&
    left.next_state == right.next_state
Base.hash(outcome::UnifiedEmbeddedOutcome, seed::UInt) = hash(
    (
        :UnifiedEmbeddedOutcome,
        outcome.holding_time,
        outcome.reward,
        outcome.next_state,
    ),
    seed,
)

function _map_ratprob(distribution::RatProb, transform)
    mapped_type = typeof(transform(first(distribution.outcomes)))
    outcomes = mapped_type[]
    masses = ExactRational[]
    for (outcome, mass) in zip(distribution.outcomes, distribution.probabilities)
        mapped = transform(outcome)
        position = findfirst(isequal(mapped), outcomes)
        if isnothing(position)
            push!(outcomes, mapped)
            push!(masses, mass)
        else
            masses[position] += mass
        end
    end
    keep = findall(mass -> !iszero(mass), masses)
    return RatProb(outcomes[keep], masses[keep])
end

function _all_raw_libraries(catalog::StrategyCatalog{S}) where {S}
    libraries = RawLibrary{S}[
        RawLibrary(catalog, StrategyId{S}[catalog.inactive_strategy]),
    ]
    for row in catalog.strategies
        row.id == catalog.inactive_strategy && continue
        append!(
            libraries,
            RawLibrary{S}[
                insert_strategy(catalog, library, row.id) for library in copy(libraries)
            ],
        )
    end
    return libraries
end

function _belief_paths(space::FiniteBeliefSpace{B}, initial::Belief{B}, duration) where {B}
    paths = Tuple{Vararg{Belief{B}}}[(initial,)]
    for _ in 1:duration
        paths = Tuple{Vararg{Belief{B}}}[
            (path..., next) for path in paths for next in space
        ]
    end
    return paths
end

function _positive_belief_paths(
    kernel::MarkovKernel{B,ExactRational},
    initial::Belief{B},
    duration,
) where {B}
    paths = Tuple{Vararg{Belief{B}}}[(initial,)]
    for _ in 1:duration
        paths = Tuple{Vararg{Belief{B}}}[
            (path..., next) for path in paths for next in kernel.space if
            !iszero(transition_probability(kernel, last(path), next))
        ]
    end
    return paths
end

function _markov_path_probability(kernel, initial, path)
    first(path) == initial || return exact_rational(0)
    mass = exact_rational(1)
    for index in 1:(length(path) - 1)
        mass *= transition_probability(kernel, path[index], path[index + 1])
    end
    return mass
end

"""
    RawInnovationProcess(catalog, closure, belief_kernel, projects,
                         generation, verification, cost, completion, discount;
                         availability=nothing)

Exact raw source of truth for candidate generation, verification/admission,
raw updates, unified timing, and Bellman computation. Call signatures:

* `generation(project, belief, closure) -> RatProb{CandidateOutcome}`;
* `verification(project, belief, closure, strategy_id) -> Rational`;
* `cost(belief, compressed_state, project) -> Rational`;
* `completion(project, belief, compressed_state) ->
  RatProb{ProjectCompletionOutcome}`.

The completion law may correlate its belief path and admitted outcome. The
constructor separately validates its exact Markov-path and admitted-law
marginals on every realizable compressed state.
"""
struct RawInnovationProcess{S,B,M,P,G,V,C,J,A}
    catalog::StrategyCatalog{S,B,M,ExactRational}
    closure::GenerativeClosure{M}
    belief_kernel::MarkovKernel{B,ExactRational}
    projects::Tuple{Vararg{UnifiedResearchProject{P,M}}}
    generation::G
    verification::V
    cost::C
    completion::J
    availability::A
    discount::ExactRational
    raw_libraries::Tuple{Vararg{RawLibrary{S}}}
    compressed_states::Tuple{Vararg{CompressedLibraryState{B,M,ExactRational}}}
end

function RawInnovationProcess(
    catalog::StrategyCatalog{S,B,M,ExactRational},
    closure::GenerativeClosure{M},
    kernel::MarkovKernel{B,ExactRational},
    projects::AbstractVector{UnifiedResearchProject{P,M}},
    generation::G,
    verification::V,
    cost::C,
    completion::J,
    discount;
    availability = nothing,
) where {S,B,M,P,G,V,C,J}
    kernel.space == catalog.beliefs ||
        throw(ArgumentError("raw process and catalog must share a belief space"))
    isempty(projects) && throw(ArgumentError("a raw process needs a project"))
    _require_unique([project.id for project in projects], "unified project IDs")
    for project in projects
        issubset(project.requirements, closure.universe) ||
            throw(ArgumentError("a project has unresolved module requirements"))
    end
    available = isnothing(availability) ?
                ((state, project) -> issubset(project.requirements, state.closure)) :
                availability
    libraries = _all_raw_libraries(catalog)
    states = unique([
        compressed_library_state(catalog, closure, library) for library in libraries
    ])
    process = RawInnovationProcess{
        S,B,M,P,G,V,C,J,typeof(available)
    }(
        catalog,
        closure,
        kernel,
        Tuple(projects),
        generation,
        verification,
        cost,
        completion,
        available,
        discount_factor(discount; mode = ExactMode()),
        Tuple(libraries),
        Tuple(states),
    )
    return _validate_raw_process(process)
end

function _resolve_project(process::RawInnovationProcess, id::ResearchProjectId)
    position = findfirst(project -> project.id == id, process.projects)
    isnothing(position) && throw(ArgumentError("unresolved unified project: $id"))
    return process.projects[position]
end
_resolve_project(process::RawInnovationProcess, project::UnifiedResearchProject) =
    _resolve_project(process, project.id)

function _validate_candidate_outcome(process::RawInnovationProcess{S}, outcome) where {S}
    outcome isa CandidateOutcome{S} ||
        throw(ArgumentError("candidate laws must return CandidateOutcome{$S}"))
    isnothing(outcome.strategy) || strategy(process.catalog, outcome.strategy)
    return outcome
end

function candidate_generation_distribution(
    process::RawInnovationProcess{S,B,M},
    project,
    belief::Belief{B},
    available::ModuleSet{M},
) where {S,B,M}
    belief in process.belief_kernel.space ||
        throw(ArgumentError("unresolved belief"))
    issubset(available, process.closure.universe) ||
        throw(ArgumentError("unresolved module in generation input"))
    law = process.generation(_resolve_project(process, project), belief, available)
    law isa RatProb || throw(ArgumentError("generation must return RatProb"))
    foreach(outcome -> _validate_candidate_outcome(process, outcome), law.outcomes)
    return law
end
candidate_generation_distribution(process, project, belief, state::CompressedLibraryState) =
    candidate_generation_distribution(process, project, belief, state.closure)

function admission_probability(
    process::RawInnovationProcess{S,B,M},
    project,
    belief::Belief{B},
    available::ModuleSet{M},
    strategy_id::StrategyId{S},
) where {S,B,M}
    strategy(process.catalog, strategy_id)
    value = exact_rational(
        process.verification(
            _resolve_project(process, project),
            belief,
            available,
            strategy_id,
        ),
    )
    0 <= value <= 1 || throw(ArgumentError("admission probability must be in [0,1]"))
    return value
end
admission_probability(process, project, belief, state::CompressedLibraryState, strategy_id) =
    admission_probability(process, project, belief, state.closure, strategy_id)

"""Derived admitted law: rejected candidates contribute to failure mass."""
function admitted_candidate_distribution(
    process::RawInnovationProcess{S,B,M},
    project,
    belief::Belief{B},
    available::ModuleSet{M},
) where {S,B,M}
    project_row = _resolve_project(process, project)
    raw = candidate_generation_distribution(process, project_row, belief, available)
    failure = CandidateOutcome{S}()
    outcomes = CandidateOutcome{S}[failure]
    append!(outcomes, [CandidateOutcome(row.id) for row in process.catalog.strategies])
    masses = zeros(ExactRational, length(outcomes))
    masses[1] = probability(raw, failure)
    for (index, row) in enumerate(process.catalog.strategies)
        generated = probability(raw, CandidateOutcome(row.id))
        pass = admission_probability(
            process,
            project_row,
            belief,
            available,
            row.id,
        )
        masses[index + 1] = generated * pass
        masses[1] += generated * (1 - pass)
    end
    return RatProb(outcomes, masses)
end
admitted_candidate_distribution(process, project, belief, state::CompressedLibraryState) =
    admitted_candidate_distribution(process, project, belief, state.closure)

function raw_library_update(
    catalog::StrategyCatalog{S},
    library::RawLibrary{S},
    outcome::CandidateOutcome{S},
) where {S}
    validate_library(catalog, library)
    return is_failure(outcome) ? library :
           insert_strategy(catalog, library, outcome.strategy)
end
raw_library_update(process::RawInnovationProcess, library, outcome) =
    raw_library_update(process.catalog, library, outcome)

function compressed_state_update(
    catalog::StrategyCatalog{S,B,M,ExactRational},
    closure::GenerativeClosure{M},
    state::CompressedLibraryState{B,M,ExactRational},
    outcome::CandidateOutcome{S},
) where {S,B,M}
    is_failure(outcome) && return state
    id = outcome.strategy
    candidate = operational_profile(catalog, id)
    next_frontier = OperationalProfile(
        catalog.beliefs,
        [max(state.frontier[belief], candidate[belief]) for belief in catalog.beliefs],
    )
    next_closure = module_closure(
        closure,
        union(state.closure, strategy_modules(catalog, id)),
    )
    return CompressedLibraryState(next_frontier, next_closure)
end
compressed_state_update(process::RawInnovationProcess, state, outcome) =
    compressed_state_update(process.catalog, process.closure, state, outcome)

function induced_compressed_transition(process, belief, state, project)
    return _map_ratprob(
        admitted_candidate_distribution(process, project, belief, state),
        outcome -> compressed_state_update(process, state, outcome),
    )
end

function _completion_distribution(process::RawInnovationProcess{S,B}, project, belief, state) where {S,B}
    row = _resolve_project(process, project)
    law = process.completion(row, belief, state)
    law isa RatProb || throw(ArgumentError("completion must return RatProb"))
    for outcome in law.outcomes
        outcome isa ProjectCompletionOutcome{B,S} ||
            throw(ArgumentError("completion outcome has the wrong type"))
        length(outcome.path) == row.duration + 1 ||
            throw(ArgumentError("completion path must have duration + 1 beliefs"))
        first(outcome.path) == belief ||
            throw(ArgumentError("completion path must start at current belief"))
        all(path_belief -> path_belief in process.belief_kernel.space, outcome.path) ||
            throw(ArgumentError("completion path has an unresolved belief"))
        _validate_candidate_outcome(process, outcome.admitted)
    end
    return law
end

function incumbent_reward(process, state, project, path::Tuple)
    row = _resolve_project(process, project)
    row.operates_during_research || return exact_rational(0)
    length(path) == row.duration + 1 ||
        throw(DimensionMismatch("operating path has the wrong length"))
    return sum(
        process.discount^time * state.frontier[path[time + 1]] for
        time in 0:(row.duration - 1);
        init = exact_rational(0),
    )
end

function raw_project_transition(process, belief, library, project)
    state = compressed_library_state(process.catalog, process.closure, library)
    return _map_ratprob(
        _completion_distribution(process, project, belief, state),
        outcome -> RawTerminalState(
            terminal_belief(outcome),
            raw_library_update(process, library, outcome.admitted),
        ),
    )
end

function compressed_project_transition(process, belief, state, project)
    return _map_ratprob(
        _completion_distribution(process, project, belief, state),
        outcome -> CompressedTerminalState(
            terminal_belief(outcome),
            compressed_state_update(process, state, outcome.admitted),
        ),
    )
end

function projected_raw_project_transition(process, belief, library, project)
    return _map_ratprob(
        raw_project_transition(process, belief, library, project),
        outcome -> CompressedTerminalState(
            outcome.belief,
            compressed_library_state(
                process.catalog,
                process.closure,
                outcome.library,
            ),
        ),
    )
end

function project_available(process, state, project)
    result = process.availability(state, _resolve_project(process, project))
    result isa Bool || throw(ArgumentError("availability must return Bool"))
    return result
end

function unified_research_cost(process, belief, state, project)
    value = exact_rational(
        process.cost(belief, state, _resolve_project(process, project)),
    )
    value >= 0 || throw(ArgumentError("research cost must be nonnegative"))
    return value
end

function unified_available_actions(
    process::RawInnovationProcess{S,B,M,P},
    state;
    horizon::Union{Nothing,Integer} = nothing,
) where {S,B,M,P}
    actions = StrategyResearchAction{P}[ContinueAction{P}()]
    for project in process.projects
        project_available(process, state, project) || continue
        !isnothing(horizon) && project.duration > horizon && continue
        push!(actions, ResearchAction{P}(project.id))
    end
    return actions
end

function raw_embedded_transition(
    process::RawInnovationProcess{S,B,M,P},
    belief::Belief{B},
    library::RawLibrary{S},
    action::StrategyResearchAction{P},
) where {S,B,M,P}
    state = compressed_library_state(process.catalog, process.closure, library)
    if action isa ContinueAction
        return _map_ratprob(
            transition_distribution(process.belief_kernel, belief),
            next -> UnifiedEmbeddedOutcome(
                1,
                state.frontier[belief],
                RawTerminalState(next, library),
            ),
        )
    end
    project = _resolve_project(process, (action::ResearchAction).project)
    project_available(process, state, project) ||
        throw(ArgumentError("infeasible raw research action"))
    cost = unified_research_cost(process, belief, state, project)
    return _map_ratprob(
        _completion_distribution(process, project, belief, state),
        outcome -> UnifiedEmbeddedOutcome(
            project.duration,
            -cost + incumbent_reward(process, state, project, outcome.path),
            RawTerminalState(
                terminal_belief(outcome),
                raw_library_update(process, library, outcome.admitted),
            ),
        ),
    )
end

function compressed_embedded_transition(
    process::RawInnovationProcess{S,B,M,P},
    belief::Belief{B},
    state::CompressedLibraryState{B,M,ExactRational},
    action::StrategyResearchAction{P},
) where {S,B,M,P}
    if action isa ContinueAction
        return _map_ratprob(
            transition_distribution(process.belief_kernel, belief),
            next -> UnifiedEmbeddedOutcome(
                1,
                state.frontier[belief],
                CompressedTerminalState(next, state),
            ),
        )
    end
    project = _resolve_project(process, (action::ResearchAction).project)
    project_available(process, state, project) ||
        throw(ArgumentError("infeasible compressed research action"))
    cost = unified_research_cost(process, belief, state, project)
    return _map_ratprob(
        _completion_distribution(process, project, belief, state),
        outcome -> UnifiedEmbeddedOutcome(
            project.duration,
            -cost + incumbent_reward(process, state, project, outcome.path),
            CompressedTerminalState(
                terminal_belief(outcome),
                compressed_state_update(process, state, outcome.admitted),
            ),
        ),
    )
end

function _validate_raw_process(process::RawInnovationProcess{S}) where {S}
    all_outcomes = CandidateOutcome{S}[CandidateOutcome{S}()]
    append!(all_outcomes, [CandidateOutcome(row.id) for row in process.catalog.strategies])
    for state in process.compressed_states,
        belief in process.belief_kernel.space,
        project in process.projects
        project_available(process, state, project)
        unified_research_cost(process, belief, state, project)
        admitted = admitted_candidate_distribution(process, project, belief, state)
        completion = _completion_distribution(process, project, belief, state)
        paths = _positive_belief_paths(
            process.belief_kernel,
            belief,
            project.duration,
        )
        for path in paths
            marginal = sum(
                probability(
                    completion,
                    ProjectCompletionOutcome(collect(path), outcome),
                ) for outcome in all_outcomes;
                init = exact_rational(0),
            )
            marginal == _markov_path_probability(process.belief_kernel, belief, path) ||
                throw(ArgumentError("completion has the wrong belief-path marginal"))
        end
        for outcome in all_outcomes
            marginal = sum(
                probability(
                    completion,
                    ProjectCompletionOutcome(collect(path), outcome),
                ) for path in paths;
                init = exact_rational(0),
            )
            marginal == probability(admitted, outcome) ||
                throw(ArgumentError("completion has the wrong admitted marginal"))
        end
    end
    return process
end

_unified_lookup(value::Function, belief, state) = value(belief, state)
_unified_lookup(value::AbstractDict, belief, state) = value[(belief, state)]

function raw_continue_value(process, value, belief, library)
    state = compressed_library_state(process.catalog, process.closure, library)
    return state.frontier[belief] + process.discount * expectation(
        transition_distribution(process.belief_kernel, belief),
        next -> _unified_lookup(value, next, library),
    )
end

function compressed_continue_value(process, value, belief, state)
    return state.frontier[belief] + process.discount * expectation(
        transition_distribution(process.belief_kernel, belief),
        next -> _unified_lookup(value, next, state),
    )
end

function raw_research_value(process, value, belief, library, project)
    state = compressed_library_state(process.catalog, process.closure, library)
    row = _resolve_project(process, project)
    project_available(process, state, row) ||
        throw(ArgumentError("infeasible raw research action"))
    return -unified_research_cost(process, belief, state, row) + expectation(
        _completion_distribution(process, row, belief, state),
        outcome ->
            incumbent_reward(process, state, row, outcome.path) +
            process.discount^row.duration * _unified_lookup(
                value,
                terminal_belief(outcome),
                raw_library_update(process, library, outcome.admitted),
            ),
    )
end

function compressed_research_value(process, value, belief, state, project)
    row = _resolve_project(process, project)
    project_available(process, state, row) ||
        throw(ArgumentError("infeasible compressed research action"))
    return -unified_research_cost(process, belief, state, row) + expectation(
        _completion_distribution(process, row, belief, state),
        outcome ->
            incumbent_reward(process, state, row, outcome.path) +
            process.discount^row.duration * _unified_lookup(
                value,
                terminal_belief(outcome),
                compressed_state_update(process, state, outcome.admitted),
            ),
    )
end

function _raw_action_value(process, value, belief, library, action)
    action isa ContinueAction &&
        return raw_continue_value(process, value, belief, library)
    return raw_research_value(process, value, belief, library, action.project)
end
function _compressed_action_value(process, value, belief, state, action)
    action isa ContinueAction &&
        return compressed_continue_value(process, value, belief, state)
    return compressed_research_value(process, value, belief, state, action.project)
end

function raw_bellman_operator(process, value)
    result = Dict{Tuple,ExactRational}()
    for library in process.raw_libraries, belief in process.belief_kernel.space
        state = compressed_library_state(process.catalog, process.closure, library)
        result[(belief, library)] = maximum(
            _raw_action_value(process, value, belief, library, action) for
            action in unified_available_actions(process, state)
        )
    end
    return result
end

function compressed_bellman_operator(process, value)
    result = Dict{Tuple,ExactRational}()
    for state in process.compressed_states, belief in process.belief_kernel.space
        result[(belief, state)] = maximum(
            _compressed_action_value(process, value, belief, state, action) for
            action in unified_available_actions(process, state)
        )
    end
    return result
end

function _raw_finite_value(process, horizon, belief, library, memo)
    horizon == 0 && return exact_rational(0)
    key = (horizon, belief, library)
    haskey(memo, key) && return memo[key]
    state = compressed_library_state(process.catalog, process.closure, library)
    best = state.frontier[belief] + process.discount * expectation(
        transition_distribution(process.belief_kernel, belief),
        next -> _raw_finite_value(process, horizon - 1, next, library, memo),
    )
    for project in process.projects
        project.duration <= horizon || continue
        project_available(process, state, project) || continue
        candidate = -unified_research_cost(process, belief, state, project) +
                    expectation(
            _completion_distribution(process, project, belief, state),
            outcome ->
                incumbent_reward(process, state, project, outcome.path) +
                process.discount^project.duration * _raw_finite_value(
                    process,
                    horizon - project.duration,
                    terminal_belief(outcome),
                    raw_library_update(process, library, outcome.admitted),
                    memo,
                ),
        )
        candidate > best && (best = candidate)
    end
    memo[key] = best
    return best
end

function _compressed_finite_value(process, horizon, belief, state, memo)
    horizon == 0 && return exact_rational(0)
    key = (horizon, belief, state)
    haskey(memo, key) && return memo[key]
    best = state.frontier[belief] + process.discount * expectation(
        transition_distribution(process.belief_kernel, belief),
        next -> _compressed_finite_value(process, horizon - 1, next, state, memo),
    )
    for project in process.projects
        project.duration <= horizon || continue
        project_available(process, state, project) || continue
        candidate = -unified_research_cost(process, belief, state, project) +
                    expectation(
            _completion_distribution(process, project, belief, state),
            outcome ->
                incumbent_reward(process, state, project, outcome.path) +
                process.discount^project.duration * _compressed_finite_value(
                    process,
                    horizon - project.duration,
                    terminal_belief(outcome),
                    compressed_state_update(process, state, outcome.admitted),
                    memo,
                ),
        )
        candidate > best && (best = candidate)
    end
    memo[key] = best
    return best
end

function raw_finite_horizon_value(process, horizon::Integer, belief, library)
    horizon >= 0 || throw(ArgumentError("horizon must be nonnegative"))
    library in process.raw_libraries || throw(ArgumentError("unresolved raw library"))
    return _raw_finite_value(
        process,
        Int(horizon),
        belief,
        library,
        Dict{Tuple,ExactRational}(),
    )
end

function compressed_finite_horizon_value(process, horizon::Integer, belief, state)
    horizon >= 0 || throw(ArgumentError("horizon must be nonnegative"))
    state in process.compressed_states ||
        throw(ArgumentError("compressed state is not realizable"))
    return _compressed_finite_value(
        process,
        Int(horizon),
        belief,
        state,
        Dict{Tuple,ExactRational}(),
    )
end

function _finite_policy(process, horizon, belief, carrier, raw)
    horizon >= 1 || throw(ArgumentError("policy horizon must be positive"))
    state = raw ?
            compressed_library_state(process.catalog, process.closure, carrier) :
            carrier
    actions = unified_available_actions(process, state; horizon)
    values = Pair{StrategyResearchAction,ExactRational}[]
    memo = Dict{Tuple,ExactRational}()
    for action in actions
        value = if action isa ContinueAction
            raw ?
            state.frontier[belief] + process.discount * expectation(
                transition_distribution(process.belief_kernel, belief),
                next -> _raw_finite_value(
                    process,
                    horizon - 1,
                    next,
                    carrier,
                    memo,
                ),
            ) :
            state.frontier[belief] + process.discount * expectation(
                transition_distribution(process.belief_kernel, belief),
                next -> _compressed_finite_value(
                    process,
                    horizon - 1,
                    next,
                    state,
                    memo,
                ),
            )
        else
            project = _resolve_project(process, action.project)
            -unified_research_cost(process, belief, state, project) + expectation(
                _completion_distribution(process, project, belief, state),
                outcome ->
                    incumbent_reward(process, state, project, outcome.path) +
                    process.discount^project.duration * (
                        raw ?
                        _raw_finite_value(
                            process,
                            horizon - project.duration,
                            terminal_belief(outcome),
                            raw_library_update(process, carrier, outcome.admitted),
                            memo,
                        ) :
                        _compressed_finite_value(
                            process,
                            horizon - project.duration,
                            terminal_belief(outcome),
                            compressed_state_update(process, state, outcome.admitted),
                            memo,
                        )
                    ),
            )
        end
        push!(values, action => value)
    end
    best = first(values)
    for candidate in Iterators.drop(values, 1)
        last(candidate) > last(best) && (best = candidate)
    end
    return first(best)
end

raw_finite_horizon_policy(process, horizon, belief, library) =
    _finite_policy(process, Int(horizon), belief, library, true)
compressed_finite_horizon_policy(process, horizon, belief, state) =
    _finite_policy(process, Int(horizon), belief, state, false)

"""
Unified cost-sensitive dynamic equivalence: equal frontier and equal
availability-tagged costs, terminal compressed laws, and expected operating
reward for every belief and project.
"""
function dynamic_innovation_equivalent(process::RawInnovationProcess, left, right)
    left_state = compressed_library_state(process.catalog, process.closure, left)
    right_state = compressed_library_state(process.catalog, process.closure, right)
    left_state.frontier == right_state.frontier || return false
    for belief in process.belief_kernel.space, project in process.projects
        left_available = project_available(process, left_state, project)
        right_available = project_available(process, right_state, project)
        left_available == right_available || return false
        left_available || continue
        unified_research_cost(process, belief, left_state, project) ==
            unified_research_cost(process, belief, right_state, project) ||
            return false
        compressed_project_transition(process, belief, left_state, project) ==
            compressed_project_transition(process, belief, right_state, project) ||
            return false
        expectation(
            _completion_distribution(process, project, belief, left_state),
            outcome -> incumbent_reward(
                process,
                left_state,
                project,
                outcome.path,
            ),
        ) == expectation(
            _completion_distribution(process, project, belief, right_state),
            outcome -> incumbent_reward(
                process,
                right_state,
                project,
                outcome.path,
            ),
        ) || return false
    end
    return true
end

struct UnifiedPolicyIterationResult{P,X}
    states::Vector{X}
    values::Vector{ExactRational}
    policy::Vector{StrategyResearchAction{P}}
    converged::Bool
    iterations::Int
    policy_equation_residual::ExactRational
    bellman_residual::ExactRational
end

function _stationary_states(process, raw)
    carrier = raw ? process.raw_libraries : process.compressed_states
    return [(belief, state) for state in carrier for belief in process.belief_kernel.space]
end

function _stationary_row(process, raw, state, action, indices)
    belief, carrier = state
    compressed = raw ?
                 compressed_library_state(process.catalog, process.closure, carrier) :
                 carrier
    transition = zeros(ExactRational, length(indices))
    if action isa ContinueAction
        for next in process.belief_kernel.space
            transition[indices[(next, carrier)]] += process.discount *
                                                    transition_probability(
                process.belief_kernel,
                belief,
                next,
            )
        end
        return compressed.frontier[belief], transition
    end
    project = _resolve_project(process, action.project)
    project_available(process, compressed, project) ||
        throw(ArgumentError("stationary policy has an infeasible action"))
    reward = -unified_research_cost(process, belief, compressed, project)
    completion = _completion_distribution(process, project, belief, compressed)
    for (outcome, mass) in zip(completion.outcomes, completion.probabilities)
        reward += mass * incumbent_reward(process, compressed, project, outcome.path)
        next_carrier = raw ?
                       raw_library_update(process, carrier, outcome.admitted) :
                       compressed_state_update(process, carrier, outcome.admitted)
        transition[indices[(terminal_belief(outcome), next_carrier)]] +=
            process.discount^project.duration * mass
    end
    return reward, transition
end

function _evaluate_unified_policy(process, raw, states, policy)
    indices = Dict(state => index for (index, state) in enumerate(states))
    rewards = zeros(ExactRational, length(states))
    transitions = zeros(ExactRational, length(states), length(states))
    for index in eachindex(states)
        rewards[index], transitions[index, :] =
            _stationary_row(process, raw, states[index], policy[index], indices)
    end
    values =
        (Matrix{ExactRational}(I, length(states), length(states)) - transitions) \ rewards
    residual = maximum(
        abs.(rewards + transitions * values - values);
        init = exact_rational(0),
    )
    return values, residual
end

function _unified_policy_iteration(
    process::RawInnovationProcess{S,B,M,P},
    raw;
    max_iterations::Integer = 10_000,
) where {S,B,M,P}
    max_iterations >= 1 || throw(ArgumentError("max_iterations must be positive"))
    states = _stationary_states(process, raw)
    policy = StrategyResearchAction{P}[ContinueAction{P}() for _ in states]
    indices = Dict(state => index for (index, state) in enumerate(states))
    for iteration in 1:max_iterations
        values, equation_residual =
            _evaluate_unified_policy(process, raw, states, policy)
        changes = 0
        for index in eachindex(states)
            _, carrier = states[index]
            compressed = raw ?
                         compressed_library_state(
                process.catalog,
                process.closure,
                carrier,
            ) :
                         carrier
            best_action = policy[index]
            reward, transition =
                _stationary_row(process, raw, states[index], best_action, indices)
            best_value = reward + sum(transition .* values; init = exact_rational(0))
            for action in unified_available_actions(process, compressed)
                reward, transition =
                    _stationary_row(process, raw, states[index], action, indices)
                candidate = reward + sum(transition .* values; init = exact_rational(0))
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
            values, equation_residual =
                _evaluate_unified_policy(process, raw, states, policy)
            bellman_residual = exact_rational(0)
            for index in eachindex(states)
                _, carrier = states[index]
                compressed = raw ?
                             compressed_library_state(
                    process.catalog,
                    process.closure,
                    carrier,
                ) :
                             carrier
                best = maximum(
                    begin
                        reward, transition =
                            _stationary_row(process, raw, states[index], action, indices)
                        reward + sum(transition .* values; init = exact_rational(0))
                    end for action in unified_available_actions(process, compressed)
                )
                bellman_residual =
                    max(bellman_residual, abs(best - values[index]))
            end
            return UnifiedPolicyIterationResult{P,eltype(states)}(
                states,
                values,
                policy,
                true,
                iteration,
                equation_residual,
                bellman_residual,
            )
        end
    end
    values, equation_residual =
        _evaluate_unified_policy(process, raw, states, policy)
    return UnifiedPolicyIterationResult{P,eltype(states)}(
        states,
        values,
        policy,
        false,
        Int(max_iterations),
        equation_residual,
        exact_rational(-1),
    )
end

raw_infinite_horizon_policy_iteration(process; kwargs...) =
    _unified_policy_iteration(process, true; kwargs...)
compressed_infinite_horizon_policy_iteration(process; kwargs...) =
    _unified_policy_iteration(process, false; kwargs...)

function state_value(result::UnifiedPolicyIterationResult, belief, state)
    index = findfirst(isequal((belief, state)), result.states)
    isnothing(index) && throw(ArgumentError("state is absent from the result"))
    return result.values[index]
end

function policy_action(result::UnifiedPolicyIterationResult, belief, state)
    index = findfirst(isequal((belief, state)), result.states)
    isnothing(index) && throw(ArgumentError("state is absent from the result"))
    return result.policy[index]
end
