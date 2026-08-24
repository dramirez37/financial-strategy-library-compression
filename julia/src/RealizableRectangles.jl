"""
    RealizableRectangle

Four raw libraries from one catalog and module-closure system. The type stores
only raw libraries; [`rectangle_states`](@ref) always recomputes their
frontier--closure images from the raw primitives.

Use [`construct_realizable_rectangle`](@ref) instead of constructing
compressed corner states directly.
"""
struct RealizableRectangle{S,B,M,T<:Real}
    catalog::StrategyCatalog{S,B,M,T}
    closure::GenerativeClosure{M}
    L00::RawLibrary{S}
    L01::RawLibrary{S}
    L10::RawLibrary{S}
    L11::RawLibrary{S}
    frontier_strategies::Tuple{Vararg{StrategyId{S}}}
    closure_strategies::Tuple{Vararg{StrategyId{S}}}

    function RealizableRectangle(
        catalog::StrategyCatalog{S,B,M,T},
        closure::GenerativeClosure{M},
        base::RawLibrary{S},
        frontier_strategies::AbstractVector{StrategyId{S}},
        closure_strategies::AbstractVector{StrategyId{S}},
    ) where {S,B,M,T<:Real}
        validate_library(catalog, base)
        closure.universe == ModuleSet(collect(catalog.modules)) || throw(
            ArgumentError(
                "the rectangle catalog and generative closure must share a module universe",
            ),
        )
        isempty(frontier_strategies) && throw(
            ArgumentError("the frontier addition set must be nonempty"),
        )
        isempty(closure_strategies) && throw(
            ArgumentError("the closure addition set must be nonempty"),
        )
        _require_unique(frontier_strategies, "frontier additions")
        _require_unique(closure_strategies, "closure additions")
        any(strategy_id -> strategy_id in closure_strategies, frontier_strategies) &&
            throw(
                ArgumentError(
                    "frontier and closure addition sets must be disjoint",
                ),
            )
        any(strategy_id -> strategy_id in base, frontier_strategies) && throw(
            ArgumentError("every frontier addition must be absent from the base library"),
        )
        any(strategy_id -> strategy_id in base, closure_strategies) && throw(
            ArgumentError("every closure addition must be absent from the base library"),
        )

        foreach(strategy_id -> strategy(catalog, strategy_id), frontier_strategies)
        foreach(strategy_id -> strategy(catalog, strategy_id), closure_strategies)
        L00 = base
        L01 = _insert_strategies(catalog, L00, closure_strategies)
        L10 = _insert_strategies(catalog, L00, frontier_strategies)
        L11 = _insert_strategies(catalog, L01, frontier_strategies)
        alternative_L11 = _insert_strategies(
            catalog,
            L10,
            closure_strategies,
        )
        L11 == alternative_L11 ||
            error("raw-library insertions failed to commute")

        state00 = compressed_library_state(catalog, closure, L00)
        state01 = compressed_library_state(catalog, closure, L01)
        state10 = compressed_library_state(catalog, closure, L10)
        state11 = compressed_library_state(catalog, closure, L11)

        state00.frontier == state01.frontier || throw(
            ArgumentError(
                "the closure carrier is not frontier-silent at the low-frontier edge",
            ),
        )
        state10.frontier == state11.frontier || throw(
            ArgumentError(
                "the closure carrier is not frontier-silent at the high-frontier edge",
            ),
        )
        state00.closure == state10.closure || throw(
            ArgumentError(
                "the frontier strategy changes the low-closure edge",
            ),
        )
        state01.closure == state11.closure || throw(
            ArgumentError(
                "the frontier strategy changes the high-closure edge",
            ),
        )
        all(
            belief -> state00.frontier[belief] <= state10.frontier[belief],
            catalog.beliefs,
        ) || throw(ArgumentError("the constructed frontiers do not satisfy F0 <= F1"))
        issubset(state00.closure, state01.closure) || throw(
            ArgumentError("the constructed closures do not satisfy C0 subseteq C1"),
        )

        return new{S,B,M,T}(
            catalog,
            closure,
            L00,
            L01,
            L10,
            L11,
            Tuple(frontier_strategies),
            Tuple(closure_strategies),
        )
    end
end

function _insert_strategies(catalog, library, strategy_ids)
    return foldl(
        (current, strategy_id) ->
            insert_strategy(catalog, current, strategy_id),
        strategy_ids;
        init = library,
    )
end

"""
    construct_realizable_rectangle(
        catalog,
        closure,
        base,
        frontier_strategies,
        closure_strategies,
    )

Build

* `L00 = base`;
* `L01 = base ∪ closure_strategies`;
* `L10 = base ∪ frontier_strategies`; and
* `L11 = base ∪ closure_strategies ∪ frontier_strategies`.

Every compressed corner is subsequently derived with
`compressed_library_state`. Construction fails unless the frontier addition
leaves both closures fixed and the closure addition leaves both frontiers
fixed.
"""
construct_realizable_rectangle(
    catalog::StrategyCatalog,
    closure::GenerativeClosure,
    base::RawLibrary,
    frontier_strategies::AbstractVector{<:StrategyId},
    closure_strategies::AbstractVector{<:StrategyId},
) = RealizableRectangle(
    catalog,
    closure,
    base,
    frontier_strategies,
    closure_strategies,
)

function construct_realizable_rectangle(
    catalog::StrategyCatalog{S},
    closure::GenerativeClosure,
    base::RawLibrary{S},
    frontier_strategy::StrategyId{S},
    closure_strategy::StrategyId{S},
) where {S}
    return construct_realizable_rectangle(
        catalog,
        closure,
        base,
        StrategyId{S}[frontier_strategy],
        StrategyId{S}[closure_strategy],
    )
end

"""Return the four actual raw libraries in canonical corner order."""
rectangle_libraries(rectangle::RealizableRectangle) = (
    L00 = rectangle.L00,
    L01 = rectangle.L01,
    L10 = rectangle.L10,
    L11 = rectangle.L11,
)

"""Recompute all four compressed images from the stored raw libraries."""
function rectangle_states(rectangle::RealizableRectangle)
    libraries = rectangle_libraries(rectangle)
    compress = library -> compressed_library_state(
        rectangle.catalog,
        rectangle.closure,
        library,
    )
    return (
        L00 = compress(libraries.L00),
        L01 = compress(libraries.L01),
        L10 = compress(libraries.L10),
        L11 = compress(libraries.L11),
    )
end

function _require_rectangle_process(
    rectangle::RealizableRectangle,
    process::RawInnovationProcess,
)
    process.catalog === rectangle.catalog || throw(
        ArgumentError("the rectangle and raw process must use the same catalog object"),
    )
    process.closure === rectangle.closure || throw(
        ArgumentError(
            "the rectangle and raw process must use the same closure-system object",
        ),
    )
    all(library -> library in process.raw_libraries, values(rectangle_libraries(rectangle))) ||
        throw(ArgumentError("a rectangle corner is absent from the raw process"))
    return process
end

"""
    rectangle_action_menus(rectangle, process; horizon=nothing)

Derive each corner's action menu from its actual compressed image and the raw
process's project requirements. No menu is accepted as input.
"""
function rectangle_action_menus(
    rectangle::RealizableRectangle,
    process::RawInnovationProcess;
    horizon::Union{Nothing,Integer} = nothing,
)
    _require_rectangle_process(rectangle, process)
    states = rectangle_states(rectangle)
    menu = state -> unified_available_actions(process, state; horizon)
    return (
        L00 = menu(states.L00),
        L01 = menu(states.L01),
        L10 = menu(states.L10),
        L11 = menu(states.L11),
    )
end

"""
    rectangle_raw_transitions(rectangle, process; horizon=nothing)

Return every raw embedded transition law at every belief and feasible derived
action. Each row records its corner, belief, action, source library, derived
compressed source state, and exact `RatProb` law.
"""
function rectangle_raw_transitions(
    rectangle::RealizableRectangle,
    process::RawInnovationProcess;
    horizon::Union{Nothing,Integer} = nothing,
)
    _require_rectangle_process(rectangle, process)
    libraries = rectangle_libraries(rectangle)
    states = rectangle_states(rectangle)
    menus = rectangle_action_menus(rectangle, process; horizon)
    rows = NamedTuple[]
    for corner in keys(libraries)
        library = getproperty(libraries, corner)
        state = getproperty(states, corner)
        for belief in process.belief_kernel.space
            for action in getproperty(menus, corner)
                push!(
                    rows,
                    (
                        corner = corner,
                        belief = belief,
                        action = action,
                        library = library,
                        state = state,
                        law = raw_embedded_transition(
                            process,
                            belief,
                            library,
                            action,
                        ),
                    ),
                )
            end
        end
    end
    return rows
end

"""
    rectangle_raw_values(rectangle, process, horizon)

Compute exact finite-horizon values and maximizing actions directly on all four
raw libraries. No compressed value table or hand-assigned action value enters
the calculation.
"""
function rectangle_raw_values(
    rectangle::RealizableRectangle,
    process::RawInnovationProcess,
    horizon::Integer,
)
    horizon >= 1 || throw(ArgumentError("rectangle value horizon must be positive"))
    _require_rectangle_process(rectangle, process)
    rows = NamedTuple[]
    for (corner, library) in pairs(rectangle_libraries(rectangle))
        for belief in process.belief_kernel.space
            push!(
                rows,
                (
                    corner = corner,
                    belief = belief,
                    horizon = Int(horizon),
                    value = raw_finite_horizon_value(
                        process,
                        horizon,
                        belief,
                        library,
                    ),
                    action = raw_finite_horizon_policy(
                        process,
                        horizon,
                        belief,
                        library,
                    ),
                ),
            )
        end
    end
    return rows
end

function _rectangle_structure_checks(rectangle::RealizableRectangle)
    libraries = rectangle_libraries(rectangle)
    states = rectangle_states(rectangle)
    library_valid = NamedTuple{keys(libraries)}(
        Tuple(
            try
                validate_library(rectangle.catalog, library)
                true
            catch
                false
            end for library in values(libraries)
        ),
    )
    raw_insertions = (
        L01 = _insert_strategies(
            rectangle.catalog,
            libraries.L00,
            rectangle.closure_strategies,
        ) == libraries.L01,
        L10 = _insert_strategies(
            rectangle.catalog,
            libraries.L00,
            rectangle.frontier_strategies,
        ) == libraries.L10,
        L11_from_L01 = _insert_strategies(
            rectangle.catalog,
            libraries.L01,
            rectangle.frontier_strategies,
        ) == libraries.L11,
        L11_from_L10 = _insert_strategies(
            rectangle.catalog,
            libraries.L10,
            rectangle.closure_strategies,
        ) == libraries.L11,
    )
    frontier_edges = (
        low = states.L00.frontier == states.L01.frontier,
        high = states.L10.frontier == states.L11.frontier,
        ordered = all(
            belief -> states.L00.frontier[belief] <= states.L10.frontier[belief],
            rectangle.catalog.beliefs,
        ),
    )
    closure_edges = (
        low = states.L00.closure == states.L10.closure,
        high = states.L01.closure == states.L11.closure,
        ordered = issubset(states.L00.closure, states.L01.closure),
    )
    all_pass = all(values(library_valid)) &&
               all(values(raw_insertions)) &&
               all(values(frontier_edges)) &&
               all(values(closure_edges))
    return (;
        shared_catalog = true,
        library_valid,
        raw_insertions,
        frontier_edges,
        closure_edges,
        all_pass,
    )
end

function _project_laws_follow_corner_closure(
    rectangle,
    process::RawInnovationProcess{S},
) where {S}
    states = rectangle_states(rectangle)
    candidate_outcomes = CandidateOutcome{S}[CandidateOutcome{S}()]
    append!(
        candidate_outcomes,
        [CandidateOutcome(row.id) for row in process.catalog.strategies],
    )
    for state in values(states)
        for belief in process.belief_kernel.space
            for project in process.projects
                project_available(process, state, project) ==
                    issubset(project.requirements, state.closure) ||
                    return false
                candidate_generation_distribution(
                    process,
                    project,
                    belief,
                    state,
                ) == candidate_generation_distribution(
                    process,
                    project,
                    belief,
                    state.closure,
                ) || return false
                admitted = admitted_candidate_distribution(
                    process,
                    project,
                    belief,
                    state,
                )
                admitted == admitted_candidate_distribution(
                    process,
                    project,
                    belief,
                    state.closure,
                ) || return false
                for row in process.catalog.strategies
                    admission_probability(
                        process,
                        project,
                        belief,
                        state,
                        row.id,
                    ) == admission_probability(
                        process,
                        project,
                        belief,
                        state.closure,
                        row.id,
                    ) || return false
                end
                unified_research_cost(process, belief, state, project)
                completion = _completion_distribution(
                    process,
                    project,
                    belief,
                    state,
                )
                for outcome in candidate_outcomes
                    completion_mass = sum(
                        mass for
                        (atom, mass) in
                        zip(completion.outcomes, completion.probabilities) if
                        atom.admitted == outcome;
                        init = exact_rational(0),
                    )
                    completion_mass == probability(admitted, outcome) ||
                        return false
                end
            end
        end
    end
    return true
end

function _projected_embedded_law(process, raw_law)
    return _map_ratprob(
        raw_law,
        outcome -> UnifiedEmbeddedOutcome(
            outcome.holding_time,
            outcome.reward,
            CompressedTerminalState(
                outcome.next_state.belief,
                compressed_library_state(
                    process.catalog,
                    process.closure,
                    outcome.next_state.library,
                ),
            ),
        ),
    )
end

function _transition_pushforwards_agree(rectangle, process)
    return all(rectangle_raw_transitions(rectangle, process)) do row
        projected = _projected_embedded_law(process, row.law)
        projected == compressed_embedded_transition(
            process,
            row.belief,
            row.state,
            row.action,
        )
    end
end

function _finite_values_agree(rectangle, process, horizon)
    states = rectangle_states(rectangle)
    return all(
        raw_finite_horizon_value(process, horizon, belief, library) ==
        compressed_finite_horizon_value(
            process,
            horizon,
            belief,
            getproperty(states, corner),
        ) &&
        raw_finite_horizon_policy(process, horizon, belief, library) ==
        compressed_finite_horizon_policy(
            process,
            horizon,
            belief,
            getproperty(states, corner),
        ) for
        (corner, library) in pairs(rectangle_libraries(rectangle)) for
        belief in process.belief_kernel.space
    )
end

"""
    rectangle_consistency(rectangle[, process]; horizon=2)

Audit raw-library validity, commuting additions, frontier/closure edge
identities, process membership, requirement-derived menus, transition
pushforwards, and raw/compressed finite-horizon value agreement.
"""
rectangle_consistency(rectangle::RealizableRectangle) =
    _rectangle_structure_checks(rectangle)

function rectangle_consistency(
    rectangle::RealizableRectangle,
    process::RawInnovationProcess;
    horizon::Integer = 2,
)
    horizon >= 1 || throw(ArgumentError("consistency horizon must be positive"))
    structure = _rectangle_structure_checks(rectangle)
    same_process_primitives =
        process.catalog === rectangle.catalog &&
        process.closure === rectangle.closure
    if !same_process_primitives
        return (;
            structure...,
            same_process_primitives,
            corners_in_process = false,
            project_laws_follow_corner_closure = false,
            transition_pushforwards_agree = false,
            finite_values_agree = false,
            all_pass = false,
        )
    end
    corners_in_process = all(
        library -> library in process.raw_libraries,
        values(rectangle_libraries(rectangle)),
    )
    project_laws_follow_corner_closure =
        corners_in_process &&
        _project_laws_follow_corner_closure(rectangle, process)
    transition_pushforwards_agree =
        corners_in_process &&
        _transition_pushforwards_agree(rectangle, process)
    finite_values_agree =
        corners_in_process &&
        _finite_values_agree(rectangle, process, horizon)
    all_pass = structure.all_pass &&
               same_process_primitives &&
               corners_in_process &&
               project_laws_follow_corner_closure &&
               transition_pushforwards_agree &&
               finite_values_agree
    return (;
        structure...,
        same_process_primitives,
        corners_in_process,
        project_laws_follow_corner_closure,
        transition_pushforwards_agree,
        finite_values_agree,
        all_pass,
    )
end

function _exact_rectangle_fixture(fixture_id::Symbol; generated_closure::Bool)
    beliefs = FiniteBeliefSpace([:low, :high])
    modules = generated_closure ?
              [
        GenerativeModule(:core),
        GenerativeModule(:trigger),
        GenerativeModule(:bridge),
    ] :
              [GenerativeModule(:core), GenerativeModule(:expansion)]
    empty_modules = ModuleSet{Symbol}()
    core_modules = ModuleSet([ModuleId(:core)])
    carrier_modules = generated_closure ?
                      ModuleSet([ModuleId(:trigger)]) :
                      ModuleSet([ModuleId(:expansion)])
    rich_requirement = generated_closure ?
                       ModuleSet([ModuleId(:bridge)]) :
                       ModuleSet([ModuleId(:expansion)])
    carrier_profile = generated_closure ? [1, 2] : [0, 0]
    strategies = [
        Strategy(:inactive, OperationalProfile(beliefs, [0, 0]), empty_modules),
        Strategy(:base, OperationalProfile(beliefs, [2, 3]), core_modules),
        Strategy(
            :frontier_only,
            OperationalProfile(beliefs, [4, 5]),
            empty_modules,
        ),
        Strategy(
            :closure_carrier,
            OperationalProfile(beliefs, carrier_profile),
            carrier_modules,
        ),
        Strategy(
            :core_descendant,
            OperationalProfile(beliefs, [8, 10]),
            empty_modules,
        ),
        Strategy(
            :expanded_descendant,
            OperationalProfile(beliefs, [14, 16]),
            empty_modules,
        ),
    ]
    catalog = StrategyCatalog(
        beliefs,
        modules,
        strategies,
        StrategyId(:inactive),
    )
    closure = if generated_closure
        bridge = ModuleId(:bridge)
        trigger = ModuleId(:trigger)
        GenerativeClosure(modules, function (available)
            trigger in available ?
            union(available, ModuleSet([bridge])) :
            available
        end)
    else
        identity_generative_closure(modules)
    end
    base = RawLibrary(
        catalog,
        [StrategyId(:inactive), StrategyId(:base)],
    )
    rectangle = construct_realizable_rectangle(
        catalog,
        closure,
        base,
        StrategyId(:frontier_only),
        StrategyId(:closure_carrier),
    )

    kernel = MarkovKernel(
        beliefs,
        ExactRational[1 0; 0 1],
    )
    projects = [
        UnifiedResearchProject(:core_project, core_modules, 1, false),
        UnifiedResearchProject(:expanded_project, rich_requirement, 1, false),
    ]
    failure = CandidateOutcome{Symbol}()
    candidates = Dict(
        ResearchProjectId(:core_project) => StrategyId(:core_descendant),
        ResearchProjectId(:expanded_project) => StrategyId(:expanded_descendant),
    )
    function generation(project, belief, available)
        issubset(project.requirements, available) ||
            return dirac(failure)
        return dirac(CandidateOutcome(candidates[project.id]))
    end
    function verification(project, belief, available, strategy_id)
        return issubset(project.requirements, available) &&
               strategy_id == candidates[project.id] ? 1 // 1 : 0 // 1
    end
    function cost(belief, state, project)
        issubset(project.requirements, state.closure) ||
            return 0 // 1
        return project.id == ResearchProjectId(:core_project) ? 1 // 1 : 0 // 1
    end
    function completion(project, belief, state)
        admitted = issubset(project.requirements, state.closure) ?
                   CandidateOutcome(candidates[project.id]) :
                   failure
        return dirac(ProjectCompletionOutcome([belief, belief], admitted))
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
        1 // 2,
    )
    menus = rectangle_action_menus(rectangle, process; horizon = 2)
    transitions = rectangle_raw_transitions(rectangle, process; horizon = 2)
    values = rectangle_raw_values(rectangle, process, 2)
    consistency = rectangle_consistency(rectangle, process; horizon = 2)
    consistency.all_pass ||
        error("internal exact realizable-rectangle fixture is inconsistent")
    return (;
        fixture_id,
        arithmetic = "Rational{BigInt}",
        rectangle,
        process,
        menus,
        transitions,
        values,
        consistency,
    )
end

"""
    exact_identity_rectangle_fixture()

Exact two-belief fixture using identity module closure and a zero-profile
module-only carrier for the closure edge.
"""
exact_identity_rectangle_fixture() = _exact_rectangle_fixture(
    :identity_module_only_rectangle;
    generated_closure = false,
)

"""
    exact_generated_closure_rectangle_fixture()

Exact two-belief fixture whose nonzero but frontier-silent carrier supplies a
trigger; the module closure derives an additional bridge module that enables
the rich project.
"""
exact_generated_closure_rectangle_fixture() = _exact_rectangle_fixture(
    :generated_closure_frontier_silent_rectangle;
    generated_closure = true,
)

"""Return both deterministic exact raw-first rectangle fixtures."""
exact_realizable_rectangle_fixtures() = (
    exact_identity_rectangle_fixture(),
    exact_generated_closure_rectangle_fixture(),
)
