module CanonicalModelSolver

using StrategyInnovation

export canonical_process,
       exact_arbitrary_loss_process,
       main,
       run_canonical_model,
       write_canonical_outputs

function _canonical_fixture(::ExactMode)
    beliefs = FiniteBeliefSpace([:low, :high])
    kernel = MarkovKernel(beliefs, [3//4 1//4; 1//3 2//3])
    empty_modules = ModuleSet{Symbol}()
    key_modules = ModuleSet([ModuleId(:key)])
    baseline = CompressedLibraryState(
        OperationalProfile(beliefs, [1, 2]),
        empty_modules,
    )
    capable = CompressedLibraryState(
        OperationalProfile(beliefs, [1, 2]),
        key_modules,
    )
    frontier = CompressedLibraryState(
        OperationalProfile(beliefs, [3, 5]),
        key_modules,
    )
    states = [baseline, capable, frontier]
    projects = [
        ResearchProject(:discover, empty_modules),
        ResearchProject(:scale, key_modules),
    ]
    transition = function (belief, state, project)
        if project.id == ResearchProjectId(:discover)
            if state == baseline
                return RatProb([baseline, capable], [1//3, 2//3])
            elseif state == capable
                return RatProb([capable, frontier], [1//4, 3//4])
            end
            return dirac(frontier)
        end
        return ModuleId(:key) in state.closure ? dirac(frontier) : dirac(baseline)
    end
    cost = function (belief, state, project)
        project.id == ResearchProjectId(:discover) && return belief == Belief(:low) ? 1//4 : 1//2
        return state == capable ? 1//8 : 2
    end
    delay(project) = project.id == ResearchProjectId(:discover) ? 0 : 2
    process = DiscountedResearchProcess(
        states,
        projects,
        kernel,
        transition,
        cost,
        delay,
        3//4,
    )
    return (; process, state_names = (:baseline, :capable, :frontier))
end

function _canonical_fixture(::Float64Mode)
    beliefs = FiniteBeliefSpace([:low, :high])
    kernel = MarkovKernel(
        beliefs,
        [0.75 0.25; 1/3 2/3];
        mode = Float64Mode(),
    )
    empty_modules = ModuleSet{Symbol}()
    key_modules = ModuleSet([ModuleId(:key)])
    baseline = CompressedLibraryState(
        OperationalProfile(beliefs, [1.0, 2.0]; mode = Float64Mode()),
        empty_modules,
    )
    capable = CompressedLibraryState(
        OperationalProfile(beliefs, [1.0, 2.0]; mode = Float64Mode()),
        key_modules,
    )
    frontier = CompressedLibraryState(
        OperationalProfile(beliefs, [3.0, 5.0]; mode = Float64Mode()),
        key_modules,
    )
    states = [baseline, capable, frontier]
    projects = [
        ResearchProject(:discover, empty_modules),
        ResearchProject(:scale, key_modules),
    ]
    transition = function (belief, state, project)
        if project.id == ResearchProjectId(:discover)
            if state == baseline
                return FloatProb([baseline, capable], [1/3, 2/3])
            elseif state == capable
                return FloatProb([capable, frontier], [0.25, 0.75])
            end
            return FloatProb([frontier], [1.0])
        end
        next_state = ModuleId(:key) in state.closure ? frontier : baseline
        return FloatProb([next_state], [1.0])
    end
    cost = function (belief, state, project)
        project.id == ResearchProjectId(:discover) && return belief == Belief(:low) ? 0.25 : 0.5
        return state == capable ? 0.125 : 2.0
    end
    delay(project) = project.id == ResearchProjectId(:discover) ? 0 : 2
    process = DiscountedResearchProcess(
        states,
        projects,
        kernel,
        transition,
        cost,
        delay,
        0.75,
    )
    return (; process, state_names = (:baseline, :capable, :frontier))
end

"""
    canonical_process(; mode=ExactMode())

Build the deterministic two-belief, three-library canonical research process.
Exact rational mode is the default; `Float64Mode()` compiles sparse matrices
for the scaling solver.
"""
canonical_process(; mode::ArithmeticMode = ExactMode()) =
    _canonical_fixture(mode).process

"""
    exact_arbitrary_loss_process(target=5)

Build the exact Lean F4 arbitrary-loss dynamic-program fixture.  Frontier-only
deletion identifies the zero-frontier unpruned and pruned states operationally,
but the unpruned key module reaches reward `2target` and is worth exactly
`target` more at horizon two.
"""
function exact_arbitrary_loss_process(target::Integer = 5)
    target >= 0 || throw(ArgumentError("target must be nonnegative"))
    beliefs = FiniteBeliefSpace([:only])
    kernel = MarkovKernel(beliefs, reshape([1], 1, 1))
    empty_modules = ModuleSet{Symbol}()
    key_modules = ModuleSet([ModuleId(:key)])
    pruned = CompressedLibraryState(
        OperationalProfile(beliefs, [0]),
        empty_modules,
    )
    unpruned = CompressedLibraryState(
        OperationalProfile(beliefs, [0]),
        key_modules,
    )
    future = CompressedLibraryState(
        OperationalProfile(beliefs, [2 * target]),
        empty_modules,
    )
    project = ResearchProject(:innovate, key_modules)
    states = iszero(target) ? [pruned, unpruned] : [pruned, unpruned, future]
    transition = (belief, state, current_project) ->
        dirac(ModuleId(:key) in state.closure ? future : pruned)
    process = DiscountedResearchProcess(
        states,
        [project],
        kernel,
        transition,
        (belief, state, current_project) -> 0,
        current_project -> 0,
        1//2,
    )
    return (; process, belief = Belief(:only), pruned, unpruned, future, target = exact_rational(target))
end

"""
    run_canonical_model(; exact_horizon=8, float_tolerance=1e-10,
                        max_iterations=10_000)

Solve the canonical model by exact finite-horizon recursion, exact rational
policy iteration, and sparse `Float64` value iteration.  The return value is
fully deterministic apart from separately recorded wall-clock runtime.
"""
function run_canonical_model(;
    exact_horizon::Integer = 8,
    float_tolerance::Real = 1e-10,
    max_iterations::Integer = 10_000,
)
    exact_horizon >= 0 || throw(ArgumentError("exact_horizon must be nonnegative"))
    exact_fixture = _canonical_fixture(ExactMode())
    float_fixture = _canonical_fixture(Float64Mode())

    exact_start = time_ns()
    exact_finite = finite_horizon_value(exact_fixture.process, exact_horizon)
    exact_policy = exact_policy_iteration(
        exact_fixture.process;
        max_iterations,
    )
    exact_runtime_ns = time_ns() - exact_start

    float_start = time_ns()
    float_result = value_iteration(
        float_fixture.process;
        tolerance = float_tolerance,
        max_iterations,
        throw_on_nonconvergence = true,
    )
    float_runtime_ns = time_ns() - float_start

    return (;
        exact_horizon,
        exact_fixture,
        float_fixture,
        exact_finite,
        exact_policy,
        float_result,
        exact_runtime_ns,
        float_runtime_ns,
    )
end

_rational_string(value::Rational) =
    string(numerator(value), "//", denominator(value))

_csv_value(value::Rational) = _rational_string(value)
_csv_value(value) = string(value)

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
        keys_in_order = sort!(collect(keys(value)); by = string)
        print(io, "{")
        isempty(keys_in_order) || print(io, "\n")
        for (position, key) in enumerate(keys_in_order)
            print(io, child_padding, "\"", _json_escape(string(key)), "\": ")
            _write_json(io, value[key], indent + 2)
            position == length(keys_in_order) || print(io, ",")
            print(io, "\n")
        end
        isempty(keys_in_order) || print(io, padding)
        print(io, "}")
    elseif value isa AbstractVector || value isa Tuple
        print(io, "[")
        isempty(value) || print(io, "\n")
        for (position, item) in enumerate(value)
            print(io, child_padding)
            _write_json(io, item, indent + 2)
            position == length(value) || print(io, ",")
            print(io, "\n")
        end
        isempty(value) || print(io, padding)
        print(io, "]")
    elseif value isa AbstractString || value isa Symbol
        print(io, "\"", _json_escape(string(value)), "\"")
    elseif value isa Rational
        print(io, "\"", _rational_string(value), "\"")
    elseif value isa Bool
        print(io, value ? "true" : "false")
    elseif value isa Integer
        print(io, value)
    elseif value isa AbstractFloat
        isfinite(value) || throw(ArgumentError("JSON cannot encode nonfinite numbers"))
        print(io, repr(value))
    else
        throw(ArgumentError("unsupported JSON output value $(typeof(value))"))
    end
end

function _policy_rows(process, state_names, values, policy, solver)
    rows = NamedTuple[]
    for (state_position, state_name) in enumerate(state_names)
        for (belief_position, belief) in enumerate(process.beliefs)
            push!(rows, (;
                solver,
                belief = string(belief.id),
                compressed_state = string(state_name),
                action = action_label(policy[belief_position, state_position]),
                value = values[belief_position, state_position],
            ))
        end
    end
    return rows
end

"""
    write_canonical_outputs(output_directory, results)

Write `canonical_model_summary.json`, `canonical_model_convergence.csv`, and
`canonical_model_policy.csv`.  Rational values use lossless `n//d` strings.
Returns the three output paths.
"""
function write_canonical_outputs(output_directory::AbstractString, results)
    mkpath(output_directory)
    summary_path = joinpath(output_directory, "canonical_model_summary.json")
    convergence_path = joinpath(output_directory, "canonical_model_convergence.csv")
    policy_path = joinpath(output_directory, "canonical_model_policy.csv")

    exact_process = results.exact_fixture.process
    float_process = results.float_fixture.process
    exact_rows = _policy_rows(
        exact_process,
        results.exact_fixture.state_names,
        results.exact_policy.values,
        results.exact_policy.policy,
        "exact_policy_iteration",
    )
    float_rows = _policy_rows(
        float_process,
        results.float_fixture.state_names,
        results.float_result.values,
        results.float_result.policy,
        "float64_value_iteration",
    )
    summary = (;
        schema_version = "canonical-discounted-dp-v1",
        exact_horizon = results.exact_horizon,
        exact_arithmetic = "Rational{BigInt}",
        float_arithmetic = "Float64 sparse",
        state_count = length(exact_process.beliefs) * length(exact_process.compressed_states),
        project_count = length(exact_process.projects),
        exact_policy_converged = results.exact_policy.converged,
        exact_policy_iterations = results.exact_policy.iterations,
        exact_bellman_residual = results.exact_policy.residual,
        float_converged = results.float_result.converged,
        float_iterations = results.float_result.iterations,
        float_increment = results.float_result.increment,
        float_bellman_residual = results.float_result.residual,
        float_apriori_error_bound = results.float_result.apriori_error_bound,
        float_posterior_error_bound = results.float_result.posterior_error_bound,
        exact_runtime_ns = results.exact_runtime_ns,
        float_runtime_ns = results.float_runtime_ns,
        exact_finite_horizon_values = [
            [results.exact_finite[row, column] for column in axes(results.exact_finite, 2)]
            for row in axes(results.exact_finite, 1)
        ],
    )
    open(summary_path, "w") do io
        _write_json(io, summary)
        println(io)
    end

    open(convergence_path, "w") do io
        println(io, "iteration,increment,bellman_residual,apriori_error_bound,posterior_error_bound")
        for record in results.float_result.log
            println(
                io,
                join(
                    (
                        record.iteration,
                        record.increment,
                        record.residual,
                        record.apriori_error_bound,
                        record.posterior_error_bound,
                    ),
                    ',',
                ),
            )
        end
    end
    open(policy_path, "w") do io
        println(io, "solver,belief,compressed_state,action,value")
        for row in (exact_rows..., float_rows...)
            println(
                io,
                join(
                    (
                        row.solver,
                        row.belief,
                        row.compressed_state,
                        row.action,
                        _csv_value(row.value),
                    ),
                    ',',
                ),
            )
        end
    end
    return (; summary_path, convergence_path, policy_path)
end

"""Run the canonical solvers and write committed experiment summaries."""
function main()
    repository_root = normpath(joinpath(@__DIR__, "..", ".."))
    output_directory = joinpath(repository_root, "experiments", "results", "summaries")
    results = run_canonical_model()
    paths = write_canonical_outputs(output_directory, results)
    println("wrote ", paths.summary_path)
    println("wrote ", paths.convergence_path)
    println("wrote ", paths.policy_path)
    return paths
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
