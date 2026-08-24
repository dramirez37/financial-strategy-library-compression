module KernelPersistenceResponseExperiment

using StrategyInnovation
using TOML

export main,
    render_kernel_persistence_csv,
    render_kernel_persistence_summary,
    run_kernel_persistence_response,
    run_kernel_persistence_response_from_config,
    write_kernel_persistence_outputs

const EXPERIMENT_ID = "kernel-persistence-response-surface-v1"
const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG =
    joinpath(REPOSITORY_ROOT, "experiments", "configs", "kernel_persistence_response.toml")

_ratio(value::Rational) = "$(numerator(value))//$(denominator(value))"

function _exact_grid(numerators, denominator)
    denominator > 0 || throw(ArgumentError("grid denominator must be positive"))
    return ExactRational[ExactRational(numerator, denominator) for numerator in numerators]
end

function _scenario_surface(
    base_kernel,
    scenario,
    gap,
    persistences,
    effective_discounts,
    horizon,
    initial_index,
)
    surface = persistence_coverage_response_surface(
        base_kernel,
        gap,
        persistences,
        effective_discounts,
        horizon;
        initial_index,
    )
    return [
        (
            scenario,
            effective_discount = row.effective_discount,
            persistence = row.persistence,
            horizon = row.horizon,
            initial_index = row.initial_index,
            advantage_occupation = row.advantage_occupation,
            coverage = row.coverage,
        ) for row in surface
    ]
end

function _lookup(rows, scenario, effective_discount, persistence)
    index = findfirst(
        row ->
            row.scenario == scenario &&
                row.effective_discount == effective_discount &&
                row.persistence == persistence,
        rows,
    )
    index === nothing &&
        error("response surface is missing $scenario at ($effective_discount, $persistence)")
    return rows[index]
end

"""
    run_kernel_persistence_response(; ...)

Build exact response surfaces for a two-state switching base kernel and three
gap alignments. The persistence family is `theta*I + (1-theta)*P_switch`.
"""
function run_kernel_persistence_response(;
    persistences = ExactRational.(0:8) .// 8,
    effective_discounts = ExactRational.(0:4) .// 4,
    horizon::Integer = 2,
    initial_index::Integer = 1,
    witness_low::ExactRational = 1 // 4,
    witness_high::ExactRational = 3 // 4,
    witness_alpha::ExactRational = 1 // 2,
)
    horizon >= 0 || throw(ArgumentError("horizon must be nonnegative"))
    witness_low <= witness_high ||
        throw(ArgumentError("the lower persistence witness must not exceed the higher"))
    space = FiniteBeliefSpace([:current, :other])
    switch_kernel = MarkovKernel(space, [0 1; 1 0])
    scenarios = (
        current_advantage = ExactRational[1, 0],
        other_advantage = ExactRational[0, 1],
        constant_advantage = ExactRational[1, 1],
    )
    rows = NamedTuple[]
    for (scenario, gap) in pairs(scenarios)
        append!(
            rows,
            _scenario_surface(
                switch_kernel,
                scenario,
                gap,
                persistences,
                effective_discounts,
                horizon,
                initial_index,
            ),
        )
    end

    current_low =
        _lookup(rows, :current_advantage, witness_alpha, witness_low)
    current_high =
        _lookup(rows, :current_advantage, witness_alpha, witness_high)
    other_low =
        _lookup(rows, :other_advantage, witness_alpha, witness_low)
    other_high =
        _lookup(rows, :other_advantage, witness_alpha, witness_high)
    constant_low =
        _lookup(rows, :constant_advantage, witness_alpha, witness_low)
    constant_high =
        _lookup(rows, :constant_advantage, witness_alpha, witness_high)

    constant_surface_invariant = all(effective_discounts) do alpha
        values = [
            row.coverage for row in rows if
            row.scenario == :constant_advantage &&
            row.effective_discount == alpha
        ]
        all(==(first(values)), values)
    end
    checks = (
        current_advantage_raises =
            current_low.coverage < current_high.coverage,
        other_advantage_lowers =
            other_high.coverage < other_low.coverage,
        constant_advantage_no_effect =
            constant_low.coverage == constant_high.coverage,
        constant_surface_invariant,
        current_alignment_raises_occupation =
            current_low.advantage_occupation <
            current_high.advantage_occupation,
        other_alignment_lowers_occupation =
            other_high.advantage_occupation <
            other_low.advantage_occupation,
        all_exact = all(
            row ->
                row.coverage isa ExactRational &&
                row.advantage_occupation isa ExactRational,
            rows,
        ),
    )
    all(values(checks)) || error("kernel-persistence response checks failed")

    return (
        experiment_id = EXPERIMENT_ID,
        arithmetic = "Rational{BigInt}",
        randomness = "none",
        kernel_family = "theta*I + (1-theta)*P_switch",
        persistences = collect(persistences),
        effective_discounts = collect(effective_discounts),
        horizon = Int(horizon),
        initial_index = Int(initial_index),
        witness = (
            low_persistence = witness_low,
            high_persistence = witness_high,
            effective_discount = witness_alpha,
            current_low = current_low.coverage,
            current_high = current_high.coverage,
            other_low = other_low.coverage,
            other_high = other_high.coverage,
            constant_low = constant_low.coverage,
            constant_high = constant_high.coverage,
        ),
        rows,
        checks,
    )
end

function run_kernel_persistence_response_from_config(path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(path)
    grid = config["grid"]
    witness = config["witness"]
    return run_kernel_persistence_response(
        persistences = _exact_grid(
            grid["persistence_numerators"],
            grid["persistence_denominator"],
        ),
        effective_discounts = _exact_grid(
            grid["effective_discount_numerators"],
            grid["effective_discount_denominator"],
        ),
        horizon = grid["horizon"],
        initial_index = grid["initial_index"],
        witness_low = ExactRational(
            witness["low_persistence_numerator"],
            witness["persistence_denominator"],
        ),
        witness_high = ExactRational(
            witness["high_persistence_numerator"],
            witness["persistence_denominator"],
        ),
        witness_alpha = ExactRational(
            witness["effective_discount_numerator"],
            witness["effective_discount_denominator"],
        ),
    )
end

function render_kernel_persistence_csv(result)
    io = IOBuffer()
    println(
        io,
        "scenario,effective_discount,persistence,horizon,initial_index," *
        "advantage_occupation,coverage",
    )
    for row in result.rows
        println(
            io,
            join(
                (
                    row.scenario,
                    _ratio(row.effective_discount),
                    _ratio(row.persistence),
                    row.horizon,
                    row.initial_index,
                    _ratio(row.advantage_occupation),
                    _ratio(row.coverage),
                ),
                ",",
            ),
        )
    end
    return String(take!(io))
end

function render_kernel_persistence_summary(result)
    witness = result.witness
    checks = result.checks
    io = IOBuffer()
    println(io, "{")
    println(io, "  \"arithmetic\": \"$(result.arithmetic)\",")
    println(io, "  \"checks\": {")
    check_keys = collect(keys(checks))
    for (index, key) in enumerate(check_keys)
        comma = index == length(check_keys) ? "" : ","
        println(io, "    \"$key\": $(getproperty(checks, key))$comma")
    end
    println(io, "  },")
    println(io, "  \"experiment_id\": \"$(result.experiment_id)\",")
    println(io, "  \"horizon\": $(result.horizon),")
    println(io, "  \"kernel_family\": \"$(result.kernel_family)\",")
    println(io, "  \"randomness\": \"$(result.randomness)\",")
    println(io, "  \"row_count\": $(length(result.rows)),")
    println(io, "  \"witness\": {")
    witness_keys = collect(keys(witness))
    for (index, key) in enumerate(witness_keys)
        comma = index == length(witness_keys) ? "" : ","
        println(io, "    \"$key\": \"$(_ratio(getproperty(witness, key)))\"$comma")
    end
    println(io, "  }")
    println(io, "}")
    return String(take!(io))
end

function write_kernel_persistence_outputs(
    result;
    output_dir = joinpath(REPOSITORY_ROOT, "experiments", "results", "summaries"),
)
    mkpath(output_dir)
    csv_path = joinpath(output_dir, "kernel_persistence_response_surface.csv")
    summary_path = joinpath(output_dir, "kernel_persistence_response_summary.json")
    write(csv_path, render_kernel_persistence_csv(result))
    write(summary_path, render_kernel_persistence_summary(result))
    return (csv = csv_path, summary = summary_path)
end

function _configured_output_paths(config_path)
    config = TOML.parsefile(config_path)
    outputs = config["outputs"]
    return (
        csv = joinpath(REPOSITORY_ROOT, outputs["response_surface"]),
        summary = joinpath(REPOSITORY_ROOT, outputs["summary"]),
    )
end

function main(args = ARGS)
    check_only = "--check" in args
    config_path = DEFAULT_CONFIG
    result = run_kernel_persistence_response_from_config(config_path)
    paths = _configured_output_paths(config_path)
    rendered = (
        csv = render_kernel_persistence_csv(result),
        summary = render_kernel_persistence_summary(result),
    )
    if check_only
        for key in keys(paths)
            path = getproperty(paths, key)
            isfile(path) || error("missing registered output: $path")
            read(path, String) == getproperty(rendered, key) ||
                error("registered output drift: $path")
        end
        println("Kernel-persistence response outputs are current.")
    else
        mkpath(dirname(paths.csv))
        write(paths.csv, rendered.csv)
        write(paths.summary, rendered.summary)
        println("Wrote $(paths.csv)")
        println("Wrote $(paths.summary)")
    end
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
