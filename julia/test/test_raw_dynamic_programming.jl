const RAW_BELIEFS = FiniteBeliefSpace([:only])
const RAW_MODULES = [GenerativeModule(:bridge_key)]
const RAW_EMPTY_MODULES = ModuleSet{Symbol}()
const RAW_BRIDGE_MODULES = ModuleSet([ModuleId(:bridge_key)])
const RAW_STRATEGIES = [
    Strategy(
        :inactive,
        OperationalProfile(RAW_BELIEFS, [0]),
        RAW_EMPTY_MODULES,
    ),
    Strategy(
        :bridge_a,
        OperationalProfile(RAW_BELIEFS, [0]),
        RAW_BRIDGE_MODULES,
    ),
    Strategy(
        :bridge_b,
        OperationalProfile(RAW_BELIEFS, [0]),
        RAW_BRIDGE_MODULES,
    ),
    Strategy(
        :candidate,
        OperationalProfile(RAW_BELIEFS, [2]),
        RAW_EMPTY_MODULES,
    ),
]
const RAW_CATALOG = StrategyCatalog(
    RAW_BELIEFS,
    RAW_MODULES,
    RAW_STRATEGIES,
    StrategyId(:inactive),
)
const RAW_CLOSURE = identity_generative_closure(RAW_MODULES)
const RAW_KERNEL = MarkovKernel(RAW_BELIEFS, reshape([1 // 1], 1, 1))
const RAW_PROJECT = UnifiedResearchProject(
    :innovate,
    RAW_BRIDGE_MODULES,
    1,
    true,
)
const RAW_FAILURE = CandidateOutcome{Symbol}()
const RAW_CANDIDATE = CandidateOutcome(StrategyId(:candidate))

function raw_generation(project, belief, closure)
    project.id == ResearchProjectId(:innovate) || error("unexpected project")
    belief == Belief(:only) || error("unexpected belief")
    return ModuleId(:bridge_key) in closure ? dirac(RAW_CANDIDATE) :
           dirac(RAW_FAILURE)
end

raw_verification(project, belief, closure, strategy_id) = 1 // 1
raw_cost(belief, state, project) = 0 // 1

function raw_completion(project, belief, state)
    admitted = ModuleId(:bridge_key) in state.closure ? RAW_CANDIDATE : RAW_FAILURE
    return dirac(ProjectCompletionOutcome([belief, belief], admitted))
end

const RAW_PROCESS = RawInnovationProcess(
    RAW_CATALOG,
    RAW_CLOSURE,
    RAW_KERNEL,
    [RAW_PROJECT],
    raw_generation,
    raw_verification,
    raw_cost,
    raw_completion,
    1 // 2,
)

raw_half_verification(project, belief, closure, strategy_id) = 1 // 2

function raw_half_completion(project, belief, state)
    if ModuleId(:bridge_key) in state.closure
        return RatProb(
            [
                ProjectCompletionOutcome([belief, belief], RAW_FAILURE),
                ProjectCompletionOutcome([belief, belief], RAW_CANDIDATE),
            ],
            [1 // 2, 1 // 2],
        )
    end
    return dirac(ProjectCompletionOutcome([belief, belief], RAW_FAILURE))
end

const RAW_HALF_PROCESS = RawInnovationProcess(
    RAW_CATALOG,
    RAW_CLOSURE,
    RAW_KERNEL,
    [RAW_PROJECT],
    raw_generation,
    raw_half_verification,
    raw_cost,
    raw_half_completion,
    1 // 2,
)

raw_library(ids::Symbol...) =
    RawLibrary(RAW_CATALOG, StrategyId{Symbol}[StrategyId(id) for id in ids])

@testset "raw generation, admission, and local update" begin
    inactive = raw_library(:inactive)
    bridge = raw_library(:inactive, :bridge_a)
    bridge_state = compressed_library_state(RAW_CATALOG, RAW_CLOSURE, bridge)

    @test is_failure(RAW_FAILURE)
    @test !is_failure(RAW_CANDIDATE)
    @test candidate_generation_distribution(
        RAW_PROCESS,
        RAW_PROJECT,
        Belief(:only),
        bridge_state,
    ) == dirac(RAW_CANDIDATE)
    @test candidate_generation_distribution(
        RAW_PROCESS,
        RAW_PROJECT,
        Belief(:only),
        compressed_library_state(
            RAW_CATALOG,
            RAW_CLOSURE,
            inactive,
        ),
    ) == dirac(RAW_FAILURE)
    @test admission_probability(
        RAW_PROCESS,
        RAW_PROJECT,
        Belief(:only),
        bridge_state,
        StrategyId(:candidate),
    ) == 1
    @test admitted_candidate_distribution(
        RAW_PROCESS,
        RAW_PROJECT,
        Belief(:only),
        bridge_state,
    ) == dirac(RAW_CANDIDATE)
    @test admission_probability(
        RAW_HALF_PROCESS,
        RAW_PROJECT,
        Belief(:only),
        bridge_state,
        StrategyId(:candidate),
    ) == 1 // 2
    @test admitted_candidate_distribution(
        RAW_HALF_PROCESS,
        RAW_PROJECT,
        Belief(:only),
        bridge_state,
    ) == RatProb([RAW_FAILURE, RAW_CANDIDATE], [1 // 2, 1 // 2])

    for library in RAW_PROCESS.raw_libraries
        state = compressed_library_state(RAW_CATALOG, RAW_CLOSURE, library)
        for outcome in (RAW_FAILURE, RAW_CANDIDATE)
            updated_library = raw_library_update(RAW_PROCESS, library, outcome)
            updated_state = compressed_state_update(RAW_PROCESS, state, outcome)
            @test compressed_library_state(
                RAW_CATALOG,
                RAW_CLOSURE,
                updated_library,
            ) == updated_state
        end
    end

    @test raw_library_update(RAW_PROCESS, inactive, RAW_FAILURE) == inactive
    @test induced_compressed_transition(
        RAW_PROCESS,
        Belief(:only),
        bridge_state,
        RAW_PROJECT,
    ) == dirac(compressed_state_update(RAW_PROCESS, bridge_state, RAW_CANDIDATE))
end

@testset "unified positive duration and operating timing" begin
    @test_throws ArgumentError UnifiedResearchProject(
        :invalid,
        RAW_EMPTY_MODULES,
        0,
        true,
    )

    active = UnifiedResearchProject(:long, RAW_EMPTY_MODULES, 2, true)
    suspended = UnifiedResearchProject(:long, RAW_EMPTY_MODULES, 2, false)
    generation(project, belief, closure) = dirac(RAW_FAILURE)
    verification(project, belief, closure, strategy_id) = 0 // 1
    cost(belief, state, project) = 1 // 1
    completion(project, belief, state) =
        dirac(ProjectCompletionOutcome([belief, belief, belief], RAW_FAILURE))
    active_process = RawInnovationProcess(
        RAW_CATALOG,
        RAW_CLOSURE,
        RAW_KERNEL,
        [active],
        generation,
        verification,
        cost,
        completion,
        1 // 2,
    )
    suspended_process = RawInnovationProcess(
        RAW_CATALOG,
        RAW_CLOSURE,
        RAW_KERNEL,
        [suspended],
        generation,
        verification,
        cost,
        completion,
        1 // 2,
    )
    incumbent = raw_library(:inactive, :candidate)
    incumbent_state =
        compressed_library_state(RAW_CATALOG, RAW_CLOSURE, incumbent)
    path = (Belief(:only), Belief(:only), Belief(:only))

    @test incumbent_reward(active_process, incumbent_state, active, path) == 3
    @test incumbent_reward(suspended_process, incumbent_state, suspended, path) == 0
    active_law = raw_embedded_transition(
        active_process,
        Belief(:only),
        incumbent,
        ResearchAction{Symbol}(ResearchProjectId(:long)),
    )
    suspended_law = raw_embedded_transition(
        suspended_process,
        Belief(:only),
        incumbent,
        ResearchAction{Symbol}(ResearchProjectId(:long)),
    )
    @test only(active_law.outcomes).holding_time == 2
    @test only(active_law.outcomes).reward == 2
    @test only(suspended_law.outcomes).reward == -1
    zero_value(belief, library) = 0 // 1
    @test raw_research_value(
        active_process,
        zero_value,
        Belief(:only),
        incumbent,
        active,
    ) == 2
end

@testset "raw and compressed transition laws agree" begin
    for library in RAW_PROCESS.raw_libraries
        state = compressed_library_state(RAW_CATALOG, RAW_CLOSURE, library)
        for belief in RAW_BELIEFS, project in RAW_PROCESS.projects
            @test projected_raw_project_transition(
                RAW_PROCESS,
                belief,
                library,
                project,
            ) == compressed_project_transition(
                RAW_PROCESS,
                belief,
                state,
                project,
            )
        end
        for belief in RAW_BELIEFS,
            action in unified_available_actions(RAW_PROCESS, state)
            raw_law =
                raw_embedded_transition(RAW_PROCESS, belief, library, action)
            projected = RatProb(
                [
                    UnifiedEmbeddedOutcome(
                        outcome.holding_time,
                        outcome.reward,
                        CompressedTerminalState(
                            outcome.next_state.belief,
                            compressed_library_state(
                                RAW_CATALOG,
                                RAW_CLOSURE,
                                outcome.next_state.library,
                            ),
                        ),
                    ) for outcome in raw_law.outcomes
                ],
                collect(raw_law.probabilities),
            )
            @test projected ==
                  compressed_embedded_transition(
                RAW_PROCESS,
                belief,
                state,
                action,
            )
        end
    end

    bridge = raw_library(:inactive, :bridge_a)
    state = compressed_library_state(RAW_CATALOG, RAW_CLOSURE, bridge)
    raw_law = raw_embedded_transition(
        RAW_PROCESS,
        Belief(:only),
        bridge,
        ResearchAction{Symbol}(ResearchProjectId(:innovate)),
    )
    compressed_law = compressed_embedded_transition(
        RAW_PROCESS,
        Belief(:only),
        state,
        ResearchAction{Symbol}(ResearchProjectId(:innovate)),
    )
    @test only(raw_law.outcomes).holding_time == 1
    @test only(compressed_law.outcomes).holding_time == 1
    @test only(raw_law.outcomes).reward == 0
    @test only(compressed_law.outcomes).reward == 0
end

@testset "raw and compressed finite-horizon values and policies agree" begin
    for horizon in 0:6, library in RAW_PROCESS.raw_libraries, belief in RAW_BELIEFS
        state = compressed_library_state(RAW_CATALOG, RAW_CLOSURE, library)
        @test raw_finite_horizon_value(
            RAW_PROCESS,
            horizon,
            belief,
            library,
        ) == compressed_finite_horizon_value(
            RAW_PROCESS,
            horizon,
            belief,
            state,
        )
        if horizon > 0
            @test raw_finite_horizon_policy(
                RAW_PROCESS,
                horizon,
                belief,
                library,
            ) == compressed_finite_horizon_policy(
                RAW_PROCESS,
                horizon,
                belief,
                state,
            )
        end
    end
end

@testset "raw and compressed stationary values, policies, and Lean fixture" begin
    raw_zero = Dict(
        (belief, library) => exact_rational(0) for
        library in RAW_PROCESS.raw_libraries for belief in RAW_BELIEFS
    )
    compressed_zero = Dict(
        (belief, state) => exact_rational(0) for
        state in RAW_PROCESS.compressed_states for belief in RAW_BELIEFS
    )
    raw_step = raw_bellman_operator(RAW_PROCESS, raw_zero)
    compressed_step = compressed_bellman_operator(RAW_PROCESS, compressed_zero)
    for library in RAW_PROCESS.raw_libraries, belief in RAW_BELIEFS
        state = compressed_library_state(RAW_CATALOG, RAW_CLOSURE, library)
        @test raw_step[(belief, library)] == compressed_step[(belief, state)]
    end

    raw_result = raw_infinite_horizon_policy_iteration(RAW_PROCESS)
    compressed_result = compressed_infinite_horizon_policy_iteration(RAW_PROCESS)
    @test raw_result.converged
    @test compressed_result.converged
    @test raw_result.policy_equation_residual == 0
    @test compressed_result.policy_equation_residual == 0
    @test raw_result.bellman_residual == 0
    @test compressed_result.bellman_residual == 0

    for library in RAW_PROCESS.raw_libraries, belief in RAW_BELIEFS
        state = compressed_library_state(RAW_CATALOG, RAW_CLOSURE, library)
        @test state_value(raw_result, belief, library) ==
              state_value(compressed_result, belief, state)
        @test policy_action(raw_result, belief, library) ==
              policy_action(compressed_result, belief, state)
    end

    bridge_a = raw_library(:inactive, :bridge_a)
    bridge_b = raw_library(:inactive, :bridge_b)
    descendant = raw_library(:inactive, :bridge_a, :candidate)
    @test dynamic_innovation_equivalent(RAW_PROCESS, bridge_a, bridge_b)
    @test state_value(raw_result, Belief(:only), bridge_a) == 2
    @test state_value(raw_result, Belief(:only), descendant) == 4
    @test action_label(policy_action(raw_result, Belief(:only), bridge_a)) ==
          "research:innovate"
    @test action_label(policy_action(raw_result, Belief(:only), descendant)) ==
          "continue"
    @test state_value(raw_result, Belief(:only), bridge_a) ==
          state_value(raw_result, Belief(:only), bridge_b)
    @test policy_action(raw_result, Belief(:only), bridge_a) ==
          policy_action(raw_result, Belief(:only), bridge_b)
    for horizon in 1:6
        @test raw_finite_horizon_value(
            RAW_PROCESS,
            horizon,
            Belief(:only),
            bridge_a,
        ) == raw_finite_horizon_value(
            RAW_PROCESS,
            horizon,
            Belief(:only),
            bridge_b,
        )
        @test raw_finite_horizon_policy(
            RAW_PROCESS,
            horizon,
            Belief(:only),
            bridge_a,
        ) == raw_finite_horizon_policy(
            RAW_PROCESS,
            horizon,
            Belief(:only),
            bridge_b,
        )
    end
end

@testset "correlated completion coupling remains raw/compressed consistent" begin
    beliefs = FiniteBeliefSpace([:low, :high])
    modules = [GenerativeModule(:dummy)]
    empty_modules = ModuleSet{Symbol}()
    strategies = [
        Strategy(:inactive, OperationalProfile(beliefs, [0, 0]), empty_modules),
        Strategy(:candidate, OperationalProfile(beliefs, [0, 1]), empty_modules),
    ]
    catalog = StrategyCatalog(
        beliefs,
        modules,
        strategies,
        StrategyId(:inactive),
    )
    closure = identity_generative_closure(modules)
    kernel = MarkovKernel(beliefs, [1//2 1//2; 1//2 1//2])
    project = UnifiedResearchProject(:correlated, empty_modules, 1, true)
    failure = CandidateOutcome{Symbol}()
    candidate = CandidateOutcome(StrategyId(:candidate))
    generation(project, belief, closure) =
        RatProb([failure, candidate], [1 // 2, 1 // 2])
    verification(project, belief, closure, strategy_id) = 1 // 1
    cost(belief, state, project) = 0 // 1
    completion(project, belief, state) = RatProb(
        [
            ProjectCompletionOutcome([belief, Belief(:low)], failure),
            ProjectCompletionOutcome([belief, Belief(:high)], candidate),
        ],
        [1 // 2, 1 // 2],
    )
    process = RawInnovationProcess(
        catalog,
        closure,
        kernel,
        [project],
        generation,
        verification,
        cost,
        completion,
        1 // 2,
    )
    library = RawLibrary(catalog, [StrategyId(:inactive)])
    state = compressed_library_state(catalog, closure, library)
    @test projected_raw_project_transition(
        process,
        Belief(:low),
        library,
        project,
    ) == compressed_project_transition(
        process,
        Belief(:low),
        state,
        project,
    )
    @test raw_finite_horizon_value(process, 2, Belief(:low), library) == 1 // 4
    @test compressed_finite_horizon_value(
        process,
        2,
        Belief(:low),
        state,
    ) == 1 // 4
end
