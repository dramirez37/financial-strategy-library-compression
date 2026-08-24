module PrimitiveSubstitutionSearch

using StrategyInnovation: ExactRational
using TOML

export main,
    relative_saturation_holds,
    render_primitive_substitution_csv,
    render_primitive_substitution_summary,
    run_primitive_substitution_search,
    run_primitive_substitution_search_from_config,
    write_primitive_substitution_outputs

const EXPERIMENT_ID = "primitive-substitution-search-v1"
const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "primitive_substitution_search.toml",
)

_ratio(value::Rational) = "$(numerator(value))//$(denominator(value))"

function _exact_grid(numerators, denominator)
    denominator > 0 || throw(ArgumentError("grid denominator must be positive"))
    return ExactRational[
        ExactRational(numerator, denominator) for numerator in numerators
    ]
end

_action(intercept::T, exposure::T) where {T<:Real} =
    (; intercept, exposure)

_action_value(action, gap) = action.intercept + action.exposure * gap

"""
    relative_saturation_holds(gap0, gap1, rich_actions, poor_actions)

Check the exact all-pairs relative-action-saturation inequality in the
fixed-continuation common-gap class. `gap1 <= gap0` corresponds to the higher
frontier. Each action is represented by a frontier-independent intercept and
its exposure to the common positive-part descendant gap.
"""
function relative_saturation_holds(
    gap0::T,
    gap1::T,
    rich_actions,
    poor_actions,
) where {T<:Real}
    gap1 <= gap0 || throw(ArgumentError("the high-frontier gap must be smaller"))
    isempty(rich_actions) && throw(ArgumentError("rich action menu is empty"))
    isempty(poor_actions) && throw(ArgumentError("poor action menu is empty"))
    return all(
        (_action_value(rich, gap1) - _action_value(poor, gap1)) <=
        (_action_value(rich, gap0) - _action_value(poor, gap0))
        for rich in rich_actions for poor in poor_actions
    )
end

function _find_row(rows; kwargs...)
    index = findfirst(rows) do row
        all(getproperty(row, key) == value for (key, value) in kwargs)
    end
    index === nothing && error("missing primitive-substitution row: $kwargs")
    return rows[index]
end

"""
    run_primitive_substitution_search(; ...)

Search the exact one-belief, fixed-continuation, single-descendant subclass.
The poor menu contains Continue and one incumbent project; the rich menu adds
one project without changing the retained actions. The broad candidate
requires only that the added project's gap exposure weakly exceed the
incumbent project's. The surviving primitive class additionally requires the
poor project to have zero gap exposure. Continue has zero intercept and zero
exposure in both menus.
"""
function run_primitive_substitution_search(;
    frontiers = ExactRational[0, 2, 4, 6, 8, 10],
    candidates = ExactRational[4, 10],
    successes = ExactRational[0, 1 // 2, 1],
    costs = ExactRational[0, 1, 2],
    discount::ExactRational = 1 // 2,
)
    zero(discount) <= discount <= one(discount) ||
        throw(ArgumentError("discount must lie in [0, 1]"))
    isempty(frontiers) && throw(ArgumentError("frontier grid must be nonempty"))
    isempty(candidates) && throw(ArgumentError("candidate grid must be nonempty"))
    all(>=(zero(ExactRational)), frontiers) ||
        throw(ArgumentError("frontiers must be nonnegative"))
    all(>=(zero(ExactRational)), candidates) ||
        throw(ArgumentError("candidate values must be nonnegative"))
    all(probability -> 0 <= probability <= 1, successes) ||
        throw(ArgumentError("success probabilities must lie in [0, 1]"))
    all(>=(zero(ExactRational)), costs) ||
        throw(ArgumentError("costs must be nonnegative"))

    rows = NamedTuple[]
    continue_action = _action(zero(discount), zero(discount))
    for frontier0 in frontiers, frontier1 in frontiers
        frontier0 < frontier1 || continue
        for candidate in candidates,
            old_success in successes,
            added_success in successes,
            old_cost in costs,
            added_cost in costs

            gap0 = max(candidate - frontier0, zero(discount))
            gap1 = max(candidate - frontier1, zero(discount))
            old_action = _action(-old_cost, discount * old_success)
            added_action = _action(-added_cost, discount * added_success)
            poor_actions = (continue_action, old_action)
            rich_actions = (continue_action, old_action, added_action)

            relative_saturation =
                relative_saturation_holds(gap0, gap1, rich_actions, poor_actions)
            added_exposure_order =
                added_action.exposure >= old_action.exposure
            poor_zero_exposure = iszero(old_action.exposure)
            rich_nonnegative_exposure =
                all(action -> action.exposure >= 0, rich_actions)

            poor0 = maximum(_action_value(action, gap0) for action in poor_actions)
            poor1 = maximum(_action_value(action, gap1) for action in poor_actions)
            rich0 = maximum(_action_value(action, gap0) for action in rich_actions)
            rich1 = maximum(_action_value(action, gap1) for action in rich_actions)
            increment0 = rich0 - poor0
            increment1 = rich1 - poor1
            interaction = increment1 - increment0
            classification = interaction < 0 ? :substitutes :
                             interaction > 0 ? :complements : :separable

            push!(
                rows,
                (;
                    discount,
                    frontier0,
                    frontier1,
                    candidate,
                    gap0,
                    gap1,
                    old_success,
                    added_success,
                    old_cost,
                    added_cost,
                    old_exposure = old_action.exposure,
                    added_exposure = added_action.exposure,
                    added_exposure_order,
                    poor_zero_exposure,
                    rich_nonnegative_exposure,
                    relative_saturation,
                    closure_increment0 = increment0,
                    closure_increment1 = increment1,
                    interaction,
                    classification,
                ),
            )
        end
    end
    isempty(rows) && error("the primitive-substitution search produced no rows")

    broad_rows = filter(row -> row.added_exposure_order, rows)
    broad_failures = filter(row -> !row.relative_saturation, broad_rows)
    primitive_rows = filter(
        row -> row.poor_zero_exposure && row.rich_nonnegative_exposure,
        rows,
    )
    primitive_failures = filter(row -> !row.relative_saturation, primitive_rows)

    strict_substitution = _find_row(
        rows;
        frontier0 = ExactRational(0),
        frontier1 = ExactRational(2),
        candidate = ExactRational(4),
        old_success = ExactRational(0),
        added_success = ExactRational(1),
        old_cost = ExactRational(0),
        added_cost = ExactRational(0),
    )
    broad_counterexample = _find_row(
        rows;
        frontier0 = ExactRational(0),
        frontier1 = ExactRational(8),
        candidate = ExactRational(10),
        old_success = ExactRational(1),
        added_success = ExactRational(1),
        old_cost = ExactRational(0),
        added_cost = ExactRational(0),
    )
    optimizer_switch = _find_row(
        rows;
        frontier0 = ExactRational(0),
        frontier1 = ExactRational(8),
        candidate = ExactRational(10),
        old_success = ExactRational(1),
        added_success = ExactRational(1 // 2),
        old_cost = ExactRational(2),
        added_cost = ExactRational(0),
    )

    counts = (
        all_rows = length(rows),
        relative_saturation_rows =
            count(row -> row.relative_saturation, rows),
        broad_rows = length(broad_rows),
        broad_failures = length(broad_failures),
        primitive_rows = length(primitive_rows),
        primitive_failures = length(primitive_failures),
        substitutes = count(row -> row.classification == :substitutes, rows),
        complements = count(row -> row.classification == :complements, rows),
        separable = count(row -> row.classification == :separable, rows),
    )
    checks = (
        row_count = counts.all_rows == 2430,
        all_exact = all(
            row ->
                row.interaction isa ExactRational &&
                row.old_exposure isa ExactRational &&
                row.added_exposure isa ExactRational,
            rows,
        ),
        broad_candidate_falsified = counts.broad_failures > 0,
        primitive_class_survives = counts.primitive_failures == 0,
        strict_substitution_matches_lean =
            strict_substitution.relative_saturation &&
            strict_substitution.interaction == -1,
        broad_counterexample_is_separable =
            broad_counterexample.added_exposure_order &&
            !broad_counterexample.relative_saturation &&
            broad_counterexample.interaction == 0,
        optimizer_switch_preserved =
            !optimizer_switch.relative_saturation &&
            optimizer_switch.interaction == 1 // 2 &&
            optimizer_switch.classification == :complements,
    )
    all(values(checks)) || error("primitive-substitution search checks failed")

    return (;
        experiment_id = EXPERIMENT_ID,
        arithmetic = "Rational{BigInt}",
        randomness = "none",
        model = "fixed-continuation common-gap menu expansion",
        rows,
        counts,
        witnesses = (; strict_substitution, broad_counterexample, optimizer_switch),
        checks,
    )
end

function run_primitive_substitution_search_from_config(
    path::AbstractString = DEFAULT_CONFIG,
)
    config = TOML.parsefile(path)
    grid = config["grid"]
    model = config["model"]
    return run_primitive_substitution_search(
        frontiers = _exact_grid(
            grid["frontier_numerators"],
            grid["frontier_denominator"],
        ),
        candidates = _exact_grid(
            grid["candidate_numerators"],
            grid["candidate_denominator"],
        ),
        successes = _exact_grid(
            grid["success_numerators"],
            grid["success_denominator"],
        ),
        costs = _exact_grid(
            grid["cost_numerators"],
            grid["cost_denominator"],
        ),
        discount = ExactRational(
            model["discount_numerator"],
            model["discount_denominator"],
        ),
    )
end

function render_primitive_substitution_csv(result)
    io = IOBuffer()
    println(
        io,
        "discount,frontier0,frontier1,candidate,gap0,gap1,old_success," *
        "added_success,old_cost,added_cost,old_exposure,added_exposure," *
        "added_exposure_order,poor_zero_exposure,rich_nonnegative_exposure," *
        "relative_saturation,closure_increment0,closure_increment1," *
        "interaction,classification",
    )
    for row in result.rows
        println(
            io,
            join(
                (
                    _ratio(row.discount),
                    _ratio(row.frontier0),
                    _ratio(row.frontier1),
                    _ratio(row.candidate),
                    _ratio(row.gap0),
                    _ratio(row.gap1),
                    _ratio(row.old_success),
                    _ratio(row.added_success),
                    _ratio(row.old_cost),
                    _ratio(row.added_cost),
                    _ratio(row.old_exposure),
                    _ratio(row.added_exposure),
                    row.added_exposure_order,
                    row.poor_zero_exposure,
                    row.rich_nonnegative_exposure,
                    row.relative_saturation,
                    _ratio(row.closure_increment0),
                    _ratio(row.closure_increment1),
                    _ratio(row.interaction),
                    row.classification,
                ),
                ",",
            ),
        )
    end
    return String(take!(io))
end

function render_primitive_substitution_summary(result)
    io = IOBuffer()
    println(io, "{")
    println(io, "  \"arithmetic\": \"$(result.arithmetic)\",")
    println(io, "  \"checks\": {")
    check_keys = collect(keys(result.checks))
    for (index, key) in enumerate(check_keys)
        comma = index == length(check_keys) ? "" : ","
        println(io, "    \"$key\": $(getproperty(result.checks, key))$comma")
    end
    println(io, "  },")
    println(io, "  \"counts\": {")
    count_keys = collect(keys(result.counts))
    for (index, key) in enumerate(count_keys)
        comma = index == length(count_keys) ? "" : ","
        println(io, "    \"$key\": $(getproperty(result.counts, key))$comma")
    end
    println(io, "  },")
    println(io, "  \"experiment_id\": \"$(result.experiment_id)\",")
    println(io, "  \"model\": \"$(result.model)\",")
    println(io, "  \"randomness\": \"$(result.randomness)\",")
    println(io, "  \"witnesses\": {")
    println(
        io,
        "    \"broad_counterexample_interaction\": " *
        "\"$(_ratio(result.witnesses.broad_counterexample.interaction))\",",
    )
    println(
        io,
        "    \"optimizer_switch_interaction\": " *
        "\"$(_ratio(result.witnesses.optimizer_switch.interaction))\",",
    )
    println(
        io,
        "    \"strict_substitution_interaction\": " *
        "\"$(_ratio(result.witnesses.strict_substitution.interaction))\"",
    )
    println(io, "  }")
    println(io, "}")
    return String(take!(io))
end

function write_primitive_substitution_outputs(
    result;
    output_dir = joinpath(REPOSITORY_ROOT, "experiments", "results", "summaries"),
)
    mkpath(output_dir)
    csv = joinpath(output_dir, "primitive_substitution_search.csv")
    summary = joinpath(output_dir, "primitive_substitution_summary.json")
    write(csv, render_primitive_substitution_csv(result))
    write(summary, render_primitive_substitution_summary(result))
    return (; csv, summary)
end

function _configured_output_paths(config_path)
    config = TOML.parsefile(config_path)
    outputs = config["outputs"]
    return (
        csv = joinpath(REPOSITORY_ROOT, outputs["search_rows"]),
        summary = joinpath(REPOSITORY_ROOT, outputs["summary"]),
    )
end

function main(args = ARGS)
    all(argument -> argument == "--check", args) ||
        throw(ArgumentError("usage: search_primitive_substitution.jl [--check]"))
    check_only = "--check" in args
    result = run_primitive_substitution_search_from_config()
    paths = _configured_output_paths(DEFAULT_CONFIG)
    rendered = (
        csv = render_primitive_substitution_csv(result),
        summary = render_primitive_substitution_summary(result),
    )
    if check_only
        for key in keys(paths)
            path = getproperty(paths, key)
            isfile(path) || error("missing registered output: $path")
            read(path, String) == getproperty(rendered, key) ||
                error("registered output drift: $path")
        end
        println("Primitive-substitution outputs are current.")
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
