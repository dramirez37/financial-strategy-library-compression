_is_sparse_matrix(matrix) = nameof(typeof(matrix)) == :SparseMatrixCSC

function _single_state_process(;
    reward = 2,
    discount = 1//2,
    cost = 10,
    delay = 0,
)
    beliefs = FiniteBeliefSpace([:only])
    state = CompressedLibraryState(
        OperationalProfile(beliefs, [reward]),
        ModuleSet{Symbol}(),
    )
    project = ResearchProject(:research, ModuleSet{Symbol}())
    process = DiscountedResearchProcess(
        [state],
        [project],
        MarkovKernel(beliefs, reshape([1], 1, 1)),
        (belief, current, selected) -> dirac(current),
        (belief, current, selected) -> cost,
        selected -> delay,
        discount,
    )
    return (; process, belief = Belief(:only), state, project)
end

function _single_state_float_process(;
    reward = 2.0,
    discount = 0.9,
    cost = 10.0,
    delay = 0,
)
    beliefs = FiniteBeliefSpace([:only])
    state = CompressedLibraryState(
        OperationalProfile(beliefs, [reward]; mode = Float64Mode()),
        ModuleSet{Symbol}(),
    )
    project = ResearchProject(:research, ModuleSet{Symbol}())
    process = DiscountedResearchProcess(
        [state],
        [project],
        MarkovKernel(
            beliefs,
            reshape([1.0], 1, 1);
            mode = Float64Mode(),
        ),
        (belief, current, selected) -> FloatProb([current], [1.0]),
        (belief, current, selected) -> cost,
        selected -> delay,
        discount,
    )
    return (; process, belief = Belief(:only), state, project)
end

@testset "dynamic-program input validation and typed actions" begin
    fixture = _single_state_process()
    process = fixture.process
    @test available_actions(process) ==
          (ContinueAction{Symbol}(), ResearchAction(ResearchProjectId(:research)))
    @test action_label(first(available_actions(process))) == "continue"
    @test action_label(last(available_actions(process))) == "research:research"
    @test joint_state_index(process, fixture.belief, fixture.state) == 1
    @test_throws ArgumentError joint_state_index(
        process,
        fixture.belief,
        CompressedLibraryState(
            OperationalProfile(process.beliefs, [3]),
            ModuleSet{Symbol}(),
        ),
    )
    @test_throws DimensionMismatch bellman_step(process, zeros(ExactRational, 2, 1))
    @test_throws ArgumentError finite_horizon_value(process, -1)
    @test_throws ArgumentError finite_horizon_policy(process, 0)
    @test_throws ArgumentError finite_horizon_value(
        process,
        0;
        terminal_value = reshape([0.0], 1, 1),
    )
    @test_throws ArgumentError continue_value(
        process,
        reshape([0.0], 1, 1),
        fixture.belief,
        fixture.state,
    )
    @test_throws ArgumentError contraction_error_bound(process, 1.0, 1)

    @test probability(FloatProb([:a, :b], [0.25, 0.75]), :b) == 0.75
    @test expectation(FloatProb([:a, :b], [0.25, 0.75]), x -> x == :a ? 4 : 0) == 1.0
    @test_throws DimensionMismatch FloatProb([:a], [0.5, 0.5])
    @test_throws ArgumentError FloatProb([:a, :a], [0.5, 0.5])
    @test_throws ArgumentError FloatProb([:a, :b], [-0.1, 1.1])
    @test_throws ArgumentError FloatProb([:a, :b], [0.4, 0.5])
    @test_throws ArgumentError FloatProb([:a], [NaN])

    beliefs = process.beliefs
    state = fixture.state
    project = fixture.project
    kernel = MarkovKernel(beliefs, reshape([1], 1, 1))
    other_state = CompressedLibraryState(
        OperationalProfile(beliefs, [7]),
        ModuleSet{Symbol}(),
    )
    constructor(;
        states = [state],
        projects = [project],
        transition = (belief, current, selected) -> dirac(current),
        cost = (belief, current, selected) -> 0,
        delay = selected -> 0,
        beta = 1//2,
    ) = DiscountedResearchProcess(
        states,
        projects,
        kernel,
        transition,
        cost,
        delay,
        beta,
    )
    @test_throws ArgumentError constructor(states = [state, state])
    @test_throws ArgumentError constructor(projects = [project, project])
    @test_throws ArgumentError constructor(
        projects = [ResearchProject(:bad, ModuleSet([ModuleId(:unknown)]))],
    )
    @test_throws ArgumentError constructor(transition = (b, s, p) -> dirac(other_state))
    @test_throws ArgumentError constructor(cost = (b, s, p) -> -1)
    @test_throws ArgumentError constructor(delay = p -> -1)
    @test_throws ArgumentError constructor(delay = p -> 0.5)
    @test_throws ArgumentError constructor(beta = 1)
    @test_throws ArgumentError constructor(states = typeof(state)[])
    @test_throws ArgumentError constructor(projects = typeof(project)[])

    different_beliefs = FiniteBeliefSpace([:different])
    mismatched_state = CompressedLibraryState(
        OperationalProfile(different_beliefs, [0]),
        ModuleSet{Symbol}(),
    )
    @test_throws ArgumentError constructor(states = [mismatched_state])
end

@testset "exact finite-horizon recursion and hand calculations" begin
    fixture = _single_state_process()
    process = fixture.process
    zero_values = zeros(ExactRational, 1, 1)
    @test finite_horizon_value(process, 0) == zero_values
    @test finite_horizon_value(process, 1) == reshape(ExactRational[2], 1, 1)
    @test finite_horizon_value(process, 2) == reshape(ExactRational[3], 1, 1)
    @test finite_horizon_value(process, 3) == reshape(ExactRational[7//2], 1, 1)
    @test bellman_step(process, finite_horizon_value(process, 2)) ==
          finite_horizon_value(process, 3)
    @test continue_value(process, zero_values, fixture.belief, fixture.state) == 2
    @test research_value(
        process,
        zero_values,
        fixture.belief,
        fixture.state,
        fixture.project.id,
    ) == -10
    @test finite_horizon_policy(process, 3) == fill(ContinueAction{Symbol}(), 1, 1)

    terminal = reshape(ExactRational[8], 1, 1)
    @test finite_horizon_value(process, 1; terminal_value = terminal)[1] == 6

    policy_result = exact_policy_iteration(process)
    @test policy_result.converged
    @test policy_result.values == reshape(ExactRational[4], 1, 1)
    @test policy_result.residual == 0
    @test policy_result.policy[1] isa ContinueAction
    @test last(policy_result.log).policy_changes == 0

    exact_value_iteration = value_iteration(process; max_iterations = 100)
    @test exact_value_iteration.converged
    @test eltype(exact_value_iteration.values) == ExactRational
    @test abs(exact_value_iteration.values[1] - 4) <=
          exact_value_iteration.apriori_error_bound
end

@testset "Lean exact finite-horizon and arbitrary-loss fixtures" begin
    for target in (0, 1, 5, 13)
        fixture = exact_arbitrary_loss_process(target)
        process = fixture.process
        values_one = finite_horizon_value(process, 1)
        values_two = finite_horizon_value(process, 2)
        belief_position = 1
        pruned_position = findfirst(isequal(fixture.pruned), process.compressed_states)
        unpruned_position = findfirst(isequal(fixture.unpruned), process.compressed_states)
        future_position = findfirst(isequal(fixture.future), process.compressed_states)

        # Lean `ExactExample.future_value_one_eq_two` at target one, and F4 scaling.
        @test values_one[belief_position, future_position] == 2 * target
        # Lean `ExactExample.pruned_value_two_eq_zero`.
        @test values_two[belief_position, pruned_position] == 0
        # Lean `ExactExample.unpruned_value_two_eq_one` and arbitrary scaled loss.
        @test values_two[belief_position, unpruned_position] == target
        @test values_two[belief_position, unpruned_position] -
              values_two[belief_position, pruned_position] == fixture.target
        if target > 0
            @test action_label(finite_horizon_policy(process, 2)[1, unpruned_position]) ==
                  "research:innovate"
        end
    end
end

@testset "research delay, deterministic success, and failed research" begin
    beliefs = FiniteBeliefSpace([:only])
    empty_modules = ModuleSet{Symbol}()
    current = CompressedLibraryState(OperationalProfile(beliefs, [0]), empty_modules)
    future = CompressedLibraryState(OperationalProfile(beliefs, [4]), empty_modules)
    project = ResearchProject(:candidate, empty_modules)
    kernel = MarkovKernel(beliefs, reshape([1], 1, 1))
    transition = (belief, state, selected) -> dirac(state == current ? future : future)
    cost = (belief, state, selected) -> 0

    immediate = DiscountedResearchProcess(
        [current, future], [project], kernel, transition, cost, selected -> 0, 1//2,
    )
    delayed = DiscountedResearchProcess(
        [current, future], [project], kernel, transition, cost, selected -> 1, 1//2,
    )
    current_position = 1
    @test finite_horizon_value(immediate, 2)[1, current_position] == 2
    @test finite_horizon_value(delayed, 2)[1, current_position] == 1

    failed = DiscountedResearchProcess(
        [current, future],
        [project],
        kernel,
        (belief, state, selected) -> dirac(state),
        cost,
        selected -> 0,
        1//2,
    )
    @test finite_horizon_value(failed, 5)[1, current_position] == 0
    @test finite_horizon_policy(failed, 2)[1, current_position] isa ContinueAction

    costly = _single_state_process(cost = 10^6).process
    @test all(action -> action isa ContinueAction, finite_horizon_policy(costly, 8))

    beta_zero = _single_state_process(discount = 0//1, cost = 0).process
    @test finite_horizon_value(beta_zero, 10)[1] == 2
    @test exact_policy_iteration(beta_zero).values[1] == 2
end

@testset "sparse Float64 contraction, convergence guard, and residuals" begin
    fixture = _single_state_float_process()
    process = fixture.process
    @test _is_sparse_matrix(process.continue_transition)
    @test all(_is_sparse_matrix, process.research_transitions)
    @test all(_is_sparse_matrix, process.candidate_transitions)

    left = reshape([0.0], 1, 1)
    right = reshape([7.0], 1, 1)
    contraction = abs(bellman_step(process, right)[1] - bellman_step(process, left)[1])
    @test contraction <= process.discount * maximum(abs, right .- left) + 1e-14
    @test isapprox(contraction, 0.9 * 7; atol = 1e-14)

    result = value_iteration(process; tolerance = 1e-11, max_iterations = 1_000)
    @test result.converged
    @test isapprox(result.values[1], 20.0; atol = result.apriori_error_bound + 1e-12)
    @test result.increment <= 1e-11
    @test result.residual == bellman_residual(process, result.values)
    @test result.posterior_error_bound == residual_error_bound(process, result.residual)
    @test result.apriori_error_bound ==
          contraction_error_bound(process, first(result.log).increment, result.iterations)
    @test all(
        result.log[index + 1].increment <=
        process.discount * result.log[index].increment + 1e-14 for
        index in 1:(length(result.log) - 1)
    )

    guarded = value_iteration(process; tolerance = 0.0, max_iterations = 2)
    @test !guarded.converged
    @test guarded.iterations == 2
    @test_throws ErrorException value_iteration(
        process;
        tolerance = 0.0,
        max_iterations = 2,
        throw_on_nonconvergence = true,
    )
    @test_throws ArgumentError value_iteration(process; max_iterations = 0)
    @test_throws ArgumentError contraction_error_bound(process, -1, 2)
    @test_throws ArgumentError contraction_error_bound(process, 1, -1)
    @test_throws ArgumentError residual_error_bound(process, -1)

    near_one = _single_state_float_process(reward = 1.0, discount = 0.99).process
    near_one_result = value_iteration(
        near_one;
        tolerance = 1e-8,
        max_iterations = 5_000,
    )
    @test near_one_result.converged
    @test isapprox(near_one_result.values[1], 100.0; atol = 2e-6)
end

@testset "frontier monotonicity and exact dynamic equivalence" begin
    low = _single_state_process(reward = 1, cost = 100).process
    high = _single_state_process(reward = 3, cost = 100).process
    for horizon in 0:8
        @test all(finite_horizon_value(low, horizon) .<= finite_horizon_value(high, horizon))
    end
    @test exact_policy_iteration(low).values[1] < exact_policy_iteration(high).values[1]

    beliefs = FiniteBeliefSpace([:only])
    empty_modules = ModuleSet{Symbol}()
    key_modules = ModuleSet([ModuleId(:key)])
    same_frontier = OperationalProfile(beliefs, [1])
    left = CompressedLibraryState(same_frontier, empty_modules)
    right = CompressedLibraryState(same_frontier, key_modules)
    future = CompressedLibraryState(OperationalProfile(beliefs, [4]), key_modules)
    project = ResearchProject(:same_law, empty_modules)
    kernel = MarkovKernel(beliefs, reshape([1], 1, 1))
    equivalent_process = DiscountedResearchProcess(
        [left, right, future],
        [project],
        kernel,
        (belief, state, selected) -> dirac(future),
        (belief, state, selected) -> 1,
        selected -> 0,
        1//2,
    )
    @test dynamic_innovation_equivalent(equivalent_process, left, right)
    for horizon in 0:8
        values = finite_horizon_value(equivalent_process, horizon)
        @test values[1, 1] == values[1, 2]
    end
    infinite = exact_policy_iteration(equivalent_process)
    @test infinite.values[1, 1] == infinite.values[1, 2]

    inequivalent_process = DiscountedResearchProcess(
        [left, right, future],
        [project],
        kernel,
        (belief, state, selected) -> dirac(future),
        (belief, state, selected) -> state == left ? 0 : 1,
        selected -> 0,
        1//2,
    )
    @test !dynamic_innovation_equivalent(inequivalent_process, left, right)
end

@testset "deterministic small-process Bellman properties" begin
    for seed in UInt64(1):UInt64(32)
        rng = research_rng(seed)
        belief_count = rand(rng, 1:3)
        state_count = rand(rng, 1:4)
        project_count = rand(rng, 1:2)
        beliefs = FiniteBeliefSpace([Symbol("b$index") for index in 1:belief_count])
        empty_modules = ModuleSet{Symbol}()
        states = [
            CompressedLibraryState(
                OperationalProfile(
                    beliefs,
                    [rand(rng, 0:4) + 10 * state_index for _ in 1:belief_count],
                ),
                empty_modules,
            ) for state_index in 1:state_count
        ]
        projects = [
            ResearchProject(Symbol("p$index"), empty_modules) for index in 1:project_count
        ]
        identity_kernel = [
            row == column ? 1 : 0 for row in 1:belief_count, column in 1:belief_count
        ]
        destinations = [
            rand(rng, 1:state_count) for
            belief_position in 1:belief_count,
            state_position in 1:state_count,
            project_position in 1:project_count
        ]
        costs = [
            rand(rng, 0:3) for
            belief_position in 1:belief_count,
            state_position in 1:state_count,
            project_position in 1:project_count
        ]
        delays = [rand(rng, 0:2) for _ in 1:project_count]
        beta = (0//1, 1//2, 3//4)[rand(rng, 1:3)]
        transition = function (belief, state, project)
            bi = belief_index(beliefs, belief)
            si = findfirst(isequal(state), states)
            pi = findfirst(isequal(project), projects)
            return dirac(states[destinations[bi, si, pi]])
        end
        cost = function (belief, state, project)
            bi = belief_index(beliefs, belief)
            si = findfirst(isequal(state), states)
            pi = findfirst(isequal(project), projects)
            return costs[bi, si, pi]
        end
        delay(project) = delays[findfirst(isequal(project), projects)]
        process = DiscountedResearchProcess(
            states,
            projects,
            MarkovKernel(beliefs, identity_kernel),
            transition,
            cost,
            delay,
            beta,
        )
        lower = zeros(ExactRational, belief_count, state_count)
        upper = ExactRational[rand(rng, 0:5) for _ in 1:belief_count, _ in 1:state_count]
        lower_step = bellman_step(process, lower)
        upper_step = bellman_step(process, upper)
        @test all(lower_step .<= upper_step)
        @test maximum(abs, upper_step .- lower_step) <=
              beta * maximum(abs, upper .- lower)
        @test finite_horizon_value(process, 3) ==
              bellman_step(process, finite_horizon_value(process, 2))
    end
end

@testset "canonical solver logs and policy tables" begin
    exact_process = canonical_process()
    float_process = canonical_process(mode = Float64Mode())
    @test eltype(exact_process.continue_transition) == ExactRational
    @test _is_sparse_matrix(float_process.continue_transition)
    results = run_canonical_model(exact_horizon = 4, float_tolerance = 1e-9)
    @test results.exact_policy.converged
    @test results.exact_policy.residual == 0
    @test results.float_result.converged
    @test !isempty(results.float_result.log)
    @test maximum(
        abs,
        Float64.(results.exact_policy.values) .- results.float_result.values,
    ) <= results.float_result.posterior_error_bound + 1e-12

    mktempdir() do output_directory
        paths = write_canonical_outputs(output_directory, results)
        @test all(isfile, paths)
        summary = read(paths.summary_path, String)
        convergence = readlines(paths.convergence_path)
        policy = readlines(paths.policy_path)
        @test occursin("\"schema_version\": \"canonical-discounted-dp-v1\"", summary)
        @test occursin("\"exact_bellman_residual\": \"0//1\"", summary)
        @test first(convergence) ==
              "iteration,increment,bellman_residual,apriori_error_bound,posterior_error_bound"
        @test length(convergence) == results.float_result.iterations + 1
        @test first(policy) == "solver,belief,compressed_state,action,value"
        @test length(policy) == 13
        @test any(line -> occursin("research:", line), policy)
    end
end
