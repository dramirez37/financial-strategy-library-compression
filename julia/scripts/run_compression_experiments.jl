module CompressionExperiments

using Random: rand
using StrategyInnovation

export DEFAULT_COMPRESSION_SEED,
       exact_frontier_loss_fixture,
       exact_finite_horizon_value_oracle,
       main,
       run_compression_experiments,
       write_compression_csv,
       write_compression_json

const DEFAULT_COMPRESSION_SEED = UInt64(0x434f4d5052455353)

"""Return a script-local exact evaluator matching Lean F1 `dynamicLibraryValue`."""
function exact_finite_horizon_value_oracle(
    semantics::FiniteResearchSemantics,
    catalog::StrategyCatalog,
    closure::GenerativeClosure,
)
    function state_value(horizon::Integer, belief::Belief, state::CompressedLibraryState)
        horizon >= 0 || throw(ArgumentError("the horizon must be nonnegative"))
        iszero(horizon) && return exact_rational(0)

        idle_continuation = expectation(
            transition_distribution(semantics.belief_kernel, belief),
            next_belief -> state_value(horizon - 1, next_belief, state),
        )
        project_continuations = ExactRational[]
        for project in semantics.projects
            continuation = expectation(
                transition_distribution(semantics.belief_kernel, belief),
                next_belief -> expectation(
                    research_distribution(semantics, belief, state, project),
                    next_state -> state_value(horizon - 1, next_belief, next_state),
                ),
            )
            push!(project_continuations, continuation)
        end
        project_continuation = maximum(project_continuations)
        return state.frontier[belief] +
               semantics.discount * max(idle_continuation, project_continuation)
    end

    return (horizon, belief, library) -> state_value(
        horizon,
        belief,
        compressed_state(catalog, closure, library),
    )
end

"""
    exact_frontier_loss_fixture(target=5)

Construct the exact Lean F4 scaled-loss fixture.  The future reward is
`2 * target`, discount is `1//2`, the current bridge is operationally
redundant, and deleting it loses exactly `target` at horizon two.
"""
function exact_frontier_loss_fixture(target::Integer = 5)
    target >= 0 || throw(ArgumentError("the F4 loss target must be nonnegative"))
    reward = exact_rational(2 * target)
    beliefs = FiniteBeliefSpace([:only])
    modules = [GenerativeModule(:key)]
    empty_modules = ModuleSet{Symbol}()
    key_module = ModuleSet([ModuleId(:key)])
    strategies = [
        Strategy(
            :inactive,
            OperationalProfile(beliefs, [0]),
            empty_modules,
        ),
        Strategy(
            :dominated,
            OperationalProfile(beliefs, [0]),
            key_module,
        ),
        Strategy(
            :future,
            OperationalProfile(beliefs, [reward]),
            empty_modules,
        ),
    ]
    catalog = StrategyCatalog(
        beliefs,
        modules,
        strategies,
        StrategyId(:inactive),
    )
    closure = identity_generative_closure(modules)
    pruned = RawLibrary(catalog, [StrategyId(:inactive)])
    unpruned = RawLibrary(
        catalog,
        [StrategyId(:inactive), StrategyId(:dominated)],
    )
    future = RawLibrary(
        catalog,
        [StrategyId(:inactive), StrategyId(:future)],
    )
    project = ResearchProject(:innovate, key_module)
    pruned_state = compressed_state(catalog, closure, pruned)
    future_state = compressed_state(catalog, closure, future)
    semantics = FiniteResearchSemantics(
        catalog,
        MarkovKernel(beliefs, reshape([1], 1, 1)),
        [project],
        (belief, state, current_project) ->
            dirac(ModuleId(:key) in state.closure ? future_state : pruned_state),
        1 // 2,
    )
    value_oracle = exact_finite_horizon_value_oracle(semantics, catalog, closure)
    return (
        target = exact_rational(target),
        reward,
        beliefs,
        catalog,
        closure,
        pruned,
        unpruned,
        future,
        project,
        semantics,
        value_oracle,
    )
end

function _exact_comparison_fixture()
    beliefs = FiniteBeliefSpace([:low, :high])
    modules = [GenerativeModule(:signal), GenerativeModule(:recipe)]
    empty_modules = ModuleSet{Symbol}()
    signal = ModuleSet([ModuleId(:signal)])
    recipe = ModuleSet([ModuleId(:recipe)])
    strategies = [
        Strategy(:inactive, OperationalProfile(beliefs, [0, 0]), empty_modules),
        Strategy(:leader, OperationalProfile(beliefs, [2, 1]), signal),
        Strategy(:duplicate, OperationalProfile(beliefs, [1, 1]), signal),
        Strategy(:bridge, OperationalProfile(beliefs, [0, 0]), recipe),
    ]
    catalog = StrategyCatalog(
        beliefs,
        modules,
        strategies,
        StrategyId(:inactive),
    )
    closure = identity_generative_closure(modules)
    source = RawLibrary(catalog, [row.id for row in strategies])
    projects = [ResearchProject(:wait, empty_modules)]
    semantics = FiniteResearchSemantics(
        catalog,
        MarkovKernel(beliefs, [1 0; 0 1]),
        projects,
        (belief, state, project) -> dirac(state),
        1 // 2,
    )
    value_oracle = exact_finite_horizon_value_oracle(semantics, catalog, closure)
    return (; beliefs, catalog, closure, source, semantics, value_oracle)
end

function _float_scaling_fixture(strategy_count::Int, seed::UInt64)
    strategy_count >= 2 || throw(ArgumentError("scaling requires at least two strategies"))
    rng = research_rng(seed)
    belief_count = 8
    module_count = 6
    prototype_count = min(12, strategy_count - 1)
    beliefs = FiniteBeliefSpace([Symbol("b$index") for index in 1:belief_count])
    modules = [GenerativeModule(Symbol("m$index")) for index in 1:module_count]
    empty_modules = ModuleSet{Symbol}()

    prototype_profiles = [
        [rand(rng, 0:20) / 10.0 for _ in 1:belief_count] for
        _ in 1:prototype_count
    ]
    prototype_modules = ModuleSet{Symbol}[]
    for _ in 1:prototype_count
        supplied = ModuleId{Symbol}[
            module_row.id for module_row in modules if rand(rng, Bool)
        ]
        push!(prototype_modules, ModuleSet(supplied))
    end

    strategies = Strategy[
        Strategy(
            :inactive,
            OperationalProfile(beliefs, zeros(belief_count); mode = Float64Mode()),
            empty_modules,
        ),
    ]
    for index in 1:(strategy_count - 1)
        prototype = mod1(index, prototype_count)
        push!(
            strategies,
            Strategy(
                Symbol("s$index"),
                OperationalProfile(
                    beliefs,
                    prototype_profiles[prototype];
                    mode = Float64Mode(),
                ),
                prototype_modules[prototype],
            ),
        )
    end
    typed_strategies = typeof(first(strategies))[strategy for strategy in strategies]
    catalog = StrategyCatalog(
        beliefs,
        modules,
        typed_strategies,
        StrategyId(:inactive),
    )
    closure = identity_generative_closure(modules)
    source = RawLibrary(catalog, [row.id for row in typed_strategies])
    value_oracle = (horizon, belief, library) ->
        Float64(horizon) * frontier(catalog, library)[belief]
    return (; beliefs, catalog, closure, source, value_oracle)
end

function _result_row(
    experiment_id,
    arithmetic,
    algorithm,
    catalog,
    source,
    compressed,
    verification,
    runtime_ns;
    minimum_size = missing,
    optimality_gap = missing,
    frontier_only_failure = false,
    dynamic_value_loss = missing,
)
    return (
        experiment_id = string(experiment_id),
        arithmetic = string(arithmetic),
        algorithm = string(algorithm),
        belief_count = length(catalog.beliefs),
        strategy_count = length(catalog.strategies),
        source_size = length(source),
        compressed_size = length(compressed),
        compression_ratio = verification.compression_ratio,
        frontier_preserved = verification.frontier_preserved,
        generative_closure_preserved = verification.generative_closure_preserved,
        compressed_state_preserved = verification.compressed_state_preserved,
        dynamic_innovation_preserved = verification.dynamic_innovation_preserved,
        dynamic_value_preserved = verification.dynamic_value_preserved,
        dynamic_value_loss,
        minimum_size,
        optimality_gap,
        frontier_only_failure,
        runtime_ns,
    )
end

function _timed_after_warmup(operation)
    operation()
    start_time = time_ns()
    result = operation()
    return result, time_ns() - start_time
end

"""
    run_compression_experiments(; seed=DEFAULT_COMPRESSION_SEED,
                                scaling_sizes=(16, 32, 64, 128))

Run exact F4 and minimum-compression audits plus deterministic Float64 scaling
experiments.  The returned named tuples contain compression, frontier,
closure, primitive dynamic-equivalence, value, runtime, and failure fields.
"""
function run_compression_experiments(;
    seed::UInt64 = DEFAULT_COMPRESSION_SEED,
    scaling_sizes = (16, 32, 64, 128),
)
    rows = NamedTuple[]

    loss_fixture = exact_frontier_loss_fixture(5)
    frontier_pruned, elapsed = _timed_after_warmup(
        () -> frontier_only_prune(
            loss_fixture.catalog,
            loss_fixture.unpruned,
        ),
    )
    frontier_report = verify_compressed_equivalence(
        loss_fixture.catalog,
        loss_fixture.closure,
        loss_fixture.unpruned,
        frontier_pruned;
        semantics = loss_fixture.semantics,
        value_oracle = loss_fixture.value_oracle,
        horizons = 0:2,
    )
    belief = only(loss_fixture.beliefs.states)
    frontier_loss =
        loss_fixture.value_oracle(2, belief, loss_fixture.unpruned) -
        loss_fixture.value_oracle(2, belief, frontier_pruned)
    push!(
        rows,
        _result_row(
            "lean-f4-scaled-loss",
            "Rational{BigInt}",
            "frontier_only_prune",
            loss_fixture.catalog,
            loss_fixture.unpruned,
            frontier_pruned,
            frontier_report,
            elapsed;
            frontier_only_failure = !frontier_report.generative_closure_preserved,
            dynamic_value_loss = frontier_loss,
        ),
    )

    safely_pruned, elapsed = _timed_after_warmup(
        () -> innovation_safe_prune_fixed_point(
            loss_fixture.catalog,
            loss_fixture.closure,
            loss_fixture.unpruned,
        ),
    )
    safe_report = verify_compressed_equivalence(
        loss_fixture.catalog,
        loss_fixture.closure,
        loss_fixture.unpruned,
        safely_pruned;
        semantics = loss_fixture.semantics,
        value_oracle = loss_fixture.value_oracle,
        horizons = 0:2,
    )
    push!(
        rows,
        _result_row(
            "lean-f4-scaled-loss",
            "Rational{BigInt}",
            "innovation_safe_prune_fixed_point",
            loss_fixture.catalog,
            loss_fixture.unpruned,
            safely_pruned,
            safe_report,
            elapsed;
            dynamic_value_loss = exact_rational(0),
        ),
    )

    comparison = _exact_comparison_fixture()
    exact_minimum, minimum_elapsed = _timed_after_warmup(
        () -> minimum_safe_compression(
            comparison.catalog,
            comparison.closure,
            comparison.source,
        ),
    )
    minimum_report = verify_compressed_equivalence(
        comparison.catalog,
        comparison.closure,
        comparison.source,
        exact_minimum;
        semantics = comparison.semantics,
        value_oracle = comparison.value_oracle,
        horizons = 0:3,
    )
    push!(
        rows,
        _result_row(
            "small-exact-minimum",
            "Rational{BigInt}",
            "minimum_safe_compression",
            comparison.catalog,
            comparison.source,
            exact_minimum,
            minimum_report,
            minimum_elapsed;
            minimum_size = length(exact_minimum),
            optimality_gap = 0,
            dynamic_value_loss = exact_rational(0),
        ),
    )

    greedy, greedy_elapsed = _timed_after_warmup(
        () -> innovation_safe_prune_fixed_point(
            comparison.catalog,
            comparison.closure,
            comparison.source,
        ),
    )
    greedy_report = verify_compressed_equivalence(
        comparison.catalog,
        comparison.closure,
        comparison.source,
        greedy;
        semantics = comparison.semantics,
        value_oracle = comparison.value_oracle,
        horizons = 0:3,
    )
    push!(
        rows,
        _result_row(
            "small-exact-minimum",
            "Rational{BigInt}",
            "safe_greedy_fixed_point",
            comparison.catalog,
            comparison.source,
            greedy,
            greedy_report,
            greedy_elapsed;
            minimum_size = length(exact_minimum),
            optimality_gap = length(greedy) - length(exact_minimum),
            dynamic_value_loss = exact_rational(0),
        ),
    )

    for (scaling_index, strategy_count) in enumerate(scaling_sizes)
        fixture = _float_scaling_fixture(
            strategy_count,
            seed + UInt64(scaling_index),
        )
        compressed, elapsed = _timed_after_warmup(
            () -> innovation_safe_prune_fixed_point(
                fixture.catalog,
                fixture.closure,
                fixture.source,
            ),
        )
        report = verify_compressed_equivalence(
            fixture.catalog,
            fixture.closure,
            fixture.source,
            compressed;
            value_oracle = fixture.value_oracle,
            horizons = 0:3,
            value_atol = 1e-12,
        )
        push!(
            rows,
            _result_row(
                "float64-scaling-$strategy_count",
                "Float64",
                "innovation_safe_prune_fixed_point",
                fixture.catalog,
                fixture.source,
                compressed,
                report,
                elapsed;
                dynamic_value_loss = 0.0,
            ),
        )
    end
    return rows
end

_rational_string(value::Rational) =
    string(numerator(value), "//", denominator(value))

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
        _write_json(
            io,
            Dict(string(key) => getproperty(value, key) for key in keys(value)),
            indent,
        )
    elseif value isa AbstractDict
        sorted_keys = sort!(collect(keys(value)); by = string)
        print(io, "{")
        isempty(sorted_keys) || print(io, "\n")
        for (index, key) in enumerate(sorted_keys)
            print(io, child_padding, "\"", _json_escape(string(key)), "\": ")
            _write_json(io, value[key], indent + 2)
            index == length(sorted_keys) || print(io, ",")
            print(io, "\n")
        end
        isempty(sorted_keys) || print(io, padding)
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
        isfinite(value) || throw(ArgumentError("JSON output cannot encode nonfinite values"))
        print(io, repr(value))
    else
        throw(ArgumentError("unsupported JSON value $(typeof(value))"))
    end
end

"""
    write_compression_json(path, rows; seed=DEFAULT_COMPRESSION_SEED)

Write compression experiment data and its explicit RNG seed to deterministic
machine-readable JSON.
"""
function write_compression_json(
    path::AbstractString,
    rows;
    seed::UInt64 = DEFAULT_COMPRESSION_SEED,
)
    result = Dict(
        "schema_version" => "innovation-safe-compression-v1",
        "julia_version" => string(VERSION),
        "seed" => string(seed),
        "rows" => collect(rows),
    )
    mkpath(dirname(path))
    open(path, "w") do io
        _write_json(io, result)
        println(io)
    end
    return path
end

function _csv_value(value)
    value isa Missing && return ""
    value isa Rational && return _rational_string(value)
    return string(value)
end

function _csv_quote(value)
    text = _csv_value(value)
    return occursin(r"[\",\n\r]", text) ? "\"$(replace(text, "\"" => "\"\""))\"" : text
end

"""Write compression experiment rows to deterministic machine-readable CSV."""
function write_compression_csv(path::AbstractString, rows)
    rows = collect(rows)
    isempty(rows) && throw(ArgumentError("CSV output requires at least one row"))
    columns = collect(keys(first(rows)))
    all(keys(row) == keys(first(rows)) for row in rows) ||
        throw(ArgumentError("all CSV result rows must have identical fields"))
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, join(string.(columns), ','))
        for row in rows
            println(
                io,
                join(
                    (_csv_quote(getproperty(row, column)) for column in columns),
                    ',',
                ),
            )
        end
    end
    return path
end

"""Run all compression experiments and write the canonical JSON and CSV summaries."""
function main(args = ARGS)
    length(args) in (0, 2) || throw(
        ArgumentError("usage: run_compression_experiments.jl [JSON_PATH CSV_PATH]"),
    )
    root = normpath(joinpath(@__DIR__, "..", ".."))
    json_path = isempty(args) ? joinpath(
        root,
        "experiments",
        "results",
        "summaries",
        "compression_experiments.json",
    ) : args[1]
    csv_path = isempty(args) ? joinpath(
        root,
        "experiments",
        "results",
        "summaries",
        "compression_experiments.csv",
    ) : args[2]
    rows = run_compression_experiments()
    write_compression_json(json_path, rows)
    write_compression_csv(csv_path, rows)
    println("wrote $(length(rows)) compression rows to $json_path and $csv_path")
    return rows
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
