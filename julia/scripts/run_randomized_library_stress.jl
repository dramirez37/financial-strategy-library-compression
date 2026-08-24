module RandomizedLibraryStressExperiment

using Printf
using SHA
using StrategyInnovation
using TOML

export main,
    render_factor_figure,
    render_method_figure,
    render_prevalence_figure,
    render_randomized_library_report,
    run_randomized_library_stress_experiment

const EXPERIMENT_ID = "randomized-finite-library-stress-v1"
const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "randomized_library_stress.toml",
)
const METHODS = (
    :frontier_only,
    :innovation_safe,
    :approx_operational,
    :approx_generative,
)
const METHOD_LABELS = Dict(
    :frontier_only => "Frontier only",
    :innovation_safe => "Innovation safe",
    :approx_operational => "Operational budget",
    :approx_generative => "Generative budget",
)
const METHOD_COLORS = Dict(
    :frontier_only => "#C44E52",
    :innovation_safe => "#4C78A8",
    :approx_operational => "#59A14F",
    :approx_generative => "#F28E2B",
)
const FACTORS = (
    :belief_count,
    :strategy_count,
    :module_count,
    :module_overlap,
    :closure_structure,
    :frontier_density,
    :candidate_quality,
    :generator_complementarity,
    :research_cost,
    :project_delay,
    :admission_probability,
    :regime_persistence,
)
const FACTOR_LABELS = Dict(
    :belief_count => "Beliefs",
    :strategy_count => "Strategies",
    :module_count => "Modules",
    :module_overlap => "Module overlap",
    :closure_structure => "Closure structure",
    :frontier_density => "Frontier density",
    :candidate_quality => "Candidate quality",
    :generator_complementarity => "Generator complementarity",
    :research_cost => "Research cost",
    :project_delay => "Project delay",
    :admission_probability => "Admission probability",
    :regime_persistence => "Regime persistence",
)

_exact(value) = exact_rational(value)
_mean(values) =
    sum(values; init = exact_rational(0)) / exact_rational(length(values))
_fraction(numerator_value, denominator_value) =
    iszero(denominator_value) ? exact_rational(0) :
    exact_rational(numerator_value) / exact_rational(denominator_value)
_percent(value) = @sprintf("%.1f%%", 100 * Float64(value))
_decimal(value) = @sprintf("%.4f", Float64(value))
_exact_string(value::Rational) =
    "$(numerator(value))//$(denominator(value))"

function _level_values(config, name)
    values = config["levels"][string(name)]
    name in (
        :frontier_density,
        :candidate_quality,
        :research_cost,
        :admission_probability,
        :regime_persistence,
    ) && return [_exact(value) for value in values]
    name in (:module_overlap, :closure_structure) &&
        return Symbol.(values)
    return values
end

function _design(config)
    return randomized_library_factor_design(
        config["trial_count"],
        config["master_seed"];
        belief_count = _level_values(config, :belief_count),
        strategy_count = _level_values(config, :strategy_count),
        module_count = _level_values(config, :module_count),
        module_overlap = _level_values(config, :module_overlap),
        closure_structure = _level_values(config, :closure_structure),
        frontier_density = _level_values(config, :frontier_density),
        candidate_quality = _level_values(config, :candidate_quality),
        generator_complementarity =
            _level_values(config, :generator_complementarity),
        research_cost = _level_values(config, :research_cost),
        project_delay = _level_values(config, :project_delay),
        admission_probability =
            _level_values(config, :admission_probability),
        regime_persistence = _level_values(config, :regime_persistence),
    )
end

function _method_summary(result)
    rows = NamedTuple[]
    for method in METHODS
        selected = filter(row -> row.method == method, result.pruning_rows)
        push!(
            rows,
            (
                method,
                trials = length(selected),
                future_value_loss_count =
                    count(row -> row.future_value_loss, selected),
                future_value_loss_frequency = _fraction(
                    count(row -> row.future_value_loss, selected),
                    length(selected),
                ),
                mean_library_reduction =
                    _mean(row.library_reduction for row in selected),
                mean_operational_loss =
                    _mean(row.operational_loss for row in selected),
                mean_generative_loss =
                    _mean(row.generative_loss for row in selected),
                mean_total_dynamic_loss =
                    _mean(row.total_dynamic_loss for row in selected),
                conditional_mean_total_dynamic_loss = begin
                    positive = filter(
                        row -> row.future_value_loss,
                        selected,
                    )
                    isempty(positive) ? exact_rational(0) :
                    _mean(row.total_dynamic_loss for row in positive)
                end,
                maximum_total_dynamic_loss = maximum(
                    row.total_dynamic_loss for row in selected;
                    init = exact_rational(0),
                ),
                decomposition_gates =
                    all(row.decomposition_gate for row in selected),
            ),
        )
    end
    return rows
end

function _factor_summary(result, config)
    method_index = Dict(
        (row.trial_id, row.method) => row for row in result.pruning_rows
    )
    rows = NamedTuple[]
    for factor in FACTORS
        levels = _level_values(config, factor)
        for level in levels
            selected = filter(
                row -> getproperty(row, factor) == level,
                result.trial_rows,
            )
            loss_count = count(
                row -> row.frontier_only_future_value_loss,
                selected,
            )
            carrier_count = sum(
                row.active_carrier_count for row in selected;
                init = 0,
            )
            carrier_events = sum(
                row.dominated_generatively_valuable_count for
                row in selected;
                init = 0,
            )
            contrast = filter(
                row -> row.genuine_closure_contrast,
                selected,
            )
            push!(
                rows,
                (
                    factor,
                    level = string(level),
                    trials = length(selected),
                    frontier_only_loss_count = loss_count,
                    frontier_only_loss_frequency =
                        _fraction(loss_count, length(selected)),
                    mean_frontier_only_total_loss = _mean(
                        row.frontier_only_total_dynamic_loss for
                        row in selected
                    ),
                    dominated_generatively_valuable_count =
                        carrier_events,
                    active_carrier_count = carrier_count,
                    dominated_generatively_valuable_fraction =
                        _fraction(carrier_events, carrier_count),
                    genuine_closure_contrasts = length(contrast),
                    substitution_count = count(
                        row -> row.interaction_classification ==
                               :substitution,
                        contrast,
                    ),
                    complementarity_count = count(
                        row -> row.interaction_classification ==
                               :complementarity,
                        contrast,
                    ),
                    substitution_frequency = _fraction(
                        count(
                            row -> row.interaction_classification ==
                                   :substitution,
                            contrast,
                        ),
                        length(contrast),
                    ),
                    complementarity_frequency = _fraction(
                        count(
                            row -> row.interaction_classification ==
                                   :complementarity,
                            contrast,
                        ),
                        length(contrast),
                    ),
                    mean_frontier_reduction = _mean(
                        method_index[(row.trial_id, :frontier_only)].library_reduction
                        for row in selected
                    ),
                    mean_safe_reduction = _mean(
                        method_index[(row.trial_id, :innovation_safe)].library_reduction
                        for row in selected
                    ),
                    mean_approx_operational_reduction = _mean(
                        method_index[
                            (row.trial_id, :approx_operational)
                        ].library_reduction for row in selected
                    ),
                    mean_approx_generative_reduction = _mean(
                        method_index[
                            (row.trial_id, :approx_generative)
                        ].library_reduction for row in selected
                    ),
                ),
            )
        end
    end
    return rows
end

function _prevalence(result)
    trial_count = length(result.trial_rows)
    frontier_loss_count = count(
        row -> row.frontier_only_future_value_loss,
        result.trial_rows,
    )
    carrier_count = length(result.carrier_rows)
    dominated_count = count(
        row -> row.operationally_redundant,
        result.carrier_rows,
    )
    carrier_events = count(
        row -> row.dominated_and_generatively_valuable,
        result.carrier_rows,
    )
    contrast = filter(
        row -> row.genuine_closure_contrast,
        result.trial_rows,
    )
    substitution_count = count(
        row -> row.interaction_classification == :substitution,
        contrast,
    )
    complementarity_count = count(
        row -> row.interaction_classification == :complementarity,
        contrast,
    )
    return (
        frontier_loss = (
            count = frontier_loss_count,
            denominator = trial_count,
            frequency = _fraction(frontier_loss_count, trial_count),
        ),
        carrier = (
            count = carrier_events,
            denominator = carrier_count,
            frequency = _fraction(carrier_events, carrier_count),
        ),
        conditional_carrier = (
            count = carrier_events,
            denominator = dominated_count,
            frequency = _fraction(carrier_events, dominated_count),
        ),
        closure_contrast = (
            count = length(contrast),
            denominator = trial_count,
            frequency = _fraction(length(contrast), trial_count),
        ),
        substitution = (
            count = substitution_count,
            denominator = length(contrast),
            frequency = _fraction(substitution_count, length(contrast)),
        ),
        complementarity = (
            count = complementarity_count,
            denominator = length(contrast),
            frequency = _fraction(complementarity_count, length(contrast)),
        ),
    )
end

function _wilson(count, denominator; z = 1.959963984540054)
    iszero(denominator) && return (0.0, 0.0)
    n = Float64(denominator)
    p = Float64(count) / n
    center = (p + z^2 / (2n)) / (1 + z^2 / n)
    radius =
        z * sqrt(p * (1 - p) / n + z^2 / (4n^2)) /
        (1 + z^2 / n)
    return (max(0.0, center - radius), min(1.0, center + radius))
end

function run_randomized_library_stress_experiment(
    config_path::AbstractString = DEFAULT_CONFIG,
)
    config = TOML.parsefile(config_path)
    config["schema_version"] == EXPERIMENT_ID ||
        error("unexpected randomized-library schema")
    design = _design(config)
    result = run_randomized_library_stress(
        design;
        horizon = config["horizon"],
        operational_budget_fraction =
            _exact(config["operational_budget_fraction"]),
        generative_budget_fraction =
            _exact(config["generative_budget_fraction"]),
    )
    method_summary = _method_summary(result)
    factor_summary = _factor_summary(result, config)
    prevalence = _prevalence(result)
    gates = (
        trial_count =
            length(result.trial_rows) == config["trial_count"],
        pruning_row_count =
            length(result.pruning_rows) == 4 * config["trial_count"],
        balanced_factors = all(
            length(unique(count(
                row -> getproperty(row, factor) == level,
                result.trial_rows,
            ) for level in unique(
                getproperty(row, factor) for row in result.trial_rows
            ))) == 1 for factor in FACTORS
        ),
        exact_decomposition =
            all(row.decomposition_gate for row in result.pruning_rows) &&
            all(row.decomposition_gate for row in result.carrier_rows),
        frontier_passive =
            all(row.frontier_passive_gate for row in result.trial_rows),
        innovation_safe_value =
            all(row.safe_value_gate for row in result.trial_rows),
        operational_budgets =
            all(row.operational_budget_gate for row in result.trial_rows),
        generative_budgets =
            all(row.generative_budget_gate for row in result.trial_rows),
        theorem_boundary =
            all(!row.theorem_evidence for row in result.trial_rows),
    )
    all(values(gates)) ||
        error("randomized-library experiment gate failed: $gates")
    return (
        experiment_id = EXPERIMENT_ID,
        config_path,
        config,
        config_sha256 = bytes2hex(sha256(read(config_path))),
        design,
        result,
        method_summary,
        factor_summary,
        prevalence,
        gates,
    )
end

function _csv_escape(value)
    token = if value isa Rational
        _exact_string(value)
    elseif value isa AbstractFloat
        @sprintf("%.12g", value)
    elseif value isa Bool
        lowercase(string(value))
    elseif value isa Symbol
        string(value)
    else
        string(value)
    end
    occursin(r"[\",\n\r]", token) || return token
    return "\"" * replace(token, "\"" => "\"\"") * "\""
end

function _render_csv(rows)
    isempty(rows) && return ""
    columns = propertynames(first(rows))
    io = IOBuffer()
    println(io, join(string.(columns), ","))
    for row in rows
        println(
            io,
            join(
                (_csv_escape(getproperty(row, column)) for column in columns),
                ",",
            ),
        )
    end
    return String(take!(io))
end

_json_escape(value) = replace(
    string(value),
    "\\" => "\\\\",
    "\"" => "\\\"",
    "\n" => "\\n",
    "\r" => "\\r",
)
_json(value::Nothing) = "null"
_json(value::Missing) = "null"
_json(value::Bool) = lowercase(string(value))
_json(value::Integer) = string(value)
_json(value::AbstractFloat) = @sprintf("%.12g", value)
_json(value::Rational) = "\"$(_exact_string(value))\""
_json(value::Symbol) = "\"$(_json_escape(value))\""
_json(value::AbstractString) = "\"$(_json_escape(value))\""
_json(value::NamedTuple) = "{" * join(
    (
        "\"$(_json_escape(name))\":" * _json(getproperty(value, name)) for
        name in propertynames(value)
    ),
    ",",
) * "}"
_json(value::AbstractVector) =
    "[" * join((_json(item) for item in value), ",") * "]"
_json(value::Tuple) =
    "[" * join((_json(item) for item in value), ",") * "]"
_json(value::AbstractDict) = "{" * join(
    (
        "\"$(_json_escape(key))\":" * _json(item) for
        (key, item) in sort(collect(value); by = pair -> string(first(pair)))
    ),
    ",",
) * "}"

function _render_summary_json(experiment)
    p = experiment.prevalence
    payload = (
        schema_version = EXPERIMENT_ID,
        experiment_id = EXPERIMENT_ID,
        config_sha256 = experiment.config_sha256,
        julia_version = string(VERSION),
        arithmetic = experiment.config["arithmetic"],
        master_seed = experiment.config["master_seed"],
        trial_count = length(experiment.result.trial_rows),
        horizon = experiment.config["horizon"],
        evidence_class = experiment.config["evidence_class"],
        theorem_evidence = false,
        row_counts = (
            trials = length(experiment.result.trial_rows),
            pruning = length(experiment.result.pruning_rows),
            carriers = length(experiment.result.carrier_rows),
            profiles = length(experiment.result.profile_rows),
            modules = length(experiment.result.module_rows),
            closures = length(experiment.result.closure_rows),
            kernels = length(experiment.result.kernel_rows),
            projects = length(experiment.result.project_rows),
            method_summary = length(experiment.method_summary),
            factor_summary = length(experiment.factor_summary),
        ),
        prevalence = p,
        method_summary = experiment.method_summary,
        gates = experiment.gates,
        source_data = [
            experiment.config["outputs"][name] for name in (
                "trials",
                "pruning",
                "carriers",
                "profiles",
                "modules",
                "closures",
                "kernels",
                "projects",
                "method_summary",
                "factor_summary",
            )
        ],
    )
    return _json(payload) * "\n"
end

_svg_escape(value) = replace(
    string(value),
    "&" => "&amp;",
    "<" => "&lt;",
    ">" => "&gt;",
    "\"" => "&quot;",
)

function _svg_header(width, height, title, subtitle)
    return """
<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height" role="img" aria-labelledby="title desc">
<title id="title">$(_svg_escape(title))</title>
<desc id="desc">$(_svg_escape(subtitle))</desc>
<rect width="$width" height="$height" fill="#FFFFFF"/>
<text x="60" y="54" font-family="Helvetica,Arial,sans-serif" font-size="28" font-weight="700" fill="#1F2937">$(_svg_escape(title))</text>
<text x="60" y="82" font-family="Helvetica,Arial,sans-serif" font-size="15" fill="#4B5563">$(_svg_escape(subtitle))</text>
"""
end

function render_method_figure(experiment)
    metrics = (
        (
            "Mean library reduction",
            row -> Float64(row.mean_library_reduction),
            value -> @sprintf("%.1f%%", 100value),
        ),
        (
            "Mean operational loss",
            row -> Float64(row.mean_operational_loss),
            value -> @sprintf("%.3f", value),
        ),
        (
            "Mean generative loss",
            row -> Float64(row.mean_generative_loss),
            value -> @sprintf("%.3f", value),
        ),
        (
            "Mean total dynamic loss",
            row -> Float64(row.mean_total_dynamic_loss),
            value -> @sprintf("%.3f", value),
        ),
    )
    io = IOBuffer()
    print(
        io,
        _svg_header(
            1200,
            780,
            "Pruning trade-offs across randomized finite libraries",
            "Exact finite-horizon means; each panel has its own scale. Values are descriptive, not theorem evidence.",
        ),
    )
    for (panel_index, (label, accessor, formatter)) in enumerate(metrics)
        column = mod(panel_index - 1, 2)
        row_index = div(panel_index - 1, 2)
        x0 = 60 + 620column
        y0 = 120 + 320row_index
        values = [accessor(row) for row in experiment.method_summary]
        maximum_value = maximum(values; init = 0.0)
        scale = iszero(maximum_value) ? 1.0 : maximum_value
        println(
            io,
            """<text x="$(x0)" y="$(y0)" font-family="Helvetica,Arial,sans-serif" font-size="18" font-weight="700" fill="#1F2937">$(_svg_escape(label))</text>""",
        )
        for (index, method) in enumerate(METHODS)
            value = values[index]
            y = y0 + 38 + 54(index - 1)
            width = 310 * value / scale
            println(
                io,
                """<text x="$(x0)" y="$(y + 17)" font-family="Helvetica,Arial,sans-serif" font-size="14" fill="#374151">$(_svg_escape(METHOD_LABELS[method]))</text>""",
            )
            println(
                io,
                """<rect x="$(x0 + 160)" y="$(y)" width="310" height="24" rx="3" fill="#EEF2F7"/>""",
            )
            println(
                io,
                """<rect x="$(x0 + 160)" y="$(y)" width="$(width)" height="24" rx="3" fill="$(METHOD_COLORS[method])"/>""",
            )
            println(
                io,
                """<text x="$(x0 + 480)" y="$(y + 17)" font-family="Helvetica,Arial,sans-serif" font-size="14" font-weight="700" fill="#111827">$(_svg_escape(formatter(value)))</text>""",
            )
        end
    end
    println(
        io,
        """<text x="60" y="752" font-family="Helvetica,Arial,sans-serif" font-size="13" fill="#6B7280">Operational = passive-value loss; generative = research-option-premium loss; exact signed decomposition is gate-checked.</text>""",
    )
    println(io, "</svg>")
    return String(take!(io))
end

function render_prevalence_figure(experiment)
    p = experiment.prevalence
    entries = (
        (
            "Frontier-only future-value loss",
            p.frontier_loss,
            "trials",
        ),
        (
            "Dominated + generatively valuable",
            p.carrier,
            "source carriers",
        ),
        (
            "Substitution (closure contrasts)",
            p.substitution,
            "contrast trials",
        ),
        (
            "Complementarity (closure contrasts)",
            p.complementarity,
            "contrast trials",
        ),
    )
    io = IOBuffer()
    print(
        io,
        _svg_header(
            1100,
            560,
            "Observed mechanism prevalence",
            "Points are design frequencies; lines are descriptive Wilson 95% intervals with denominators shown.",
        ),
    )
    x0 = 430
    width = 570
    for tick in 0:5
        x = x0 + width * tick / 5
        println(
            io,
            """<line x1="$x" y1="120" x2="$x" y2="475" stroke="#E5E7EB" stroke-width="1"/>""",
        )
        println(
            io,
            """<text x="$x" y="505" text-anchor="middle" font-family="Helvetica,Arial,sans-serif" font-size="13" fill="#6B7280">$(20tick)%</text>""",
        )
    end
    for (index, (label, entry, denominator_label)) in enumerate(entries)
        y = 155 + 82(index - 1)
        low, high = _wilson(entry.count, entry.denominator)
        point = Float64(entry.frequency)
        println(
            io,
            """<text x="60" y="$(y - 4)" font-family="Helvetica,Arial,sans-serif" font-size="16" font-weight="700" fill="#1F2937">$(_svg_escape(label))</text>""",
        )
        println(
            io,
            """<text x="60" y="$(y + 18)" font-family="Helvetica,Arial,sans-serif" font-size="13" fill="#6B7280">$(entry.count)/$(entry.denominator) $(_svg_escape(denominator_label))</text>""",
        )
        println(
            io,
            """<line x1="$(x0 + width * low)" y1="$y" x2="$(x0 + width * high)" y2="$y" stroke="#374151" stroke-width="5" stroke-linecap="round"/>""",
        )
        println(
            io,
            """<circle cx="$(x0 + width * point)" cy="$y" r="10" fill="#4C78A8" stroke="#FFFFFF" stroke-width="3"/>""",
        )
        println(
            io,
            """<text x="$(min(1040, x0 + width * point + 18))" y="$(y - 12)" font-family="Helvetica,Arial,sans-serif" font-size="14" font-weight="700" fill="#111827">$(_percent(entry.frequency))</text>""",
        )
    end
    println(io, "</svg>")
    return String(take!(io))
end

function render_factor_figure(experiment)
    io = IOBuffer()
    print(
        io,
        _svg_header(
            1260,
            1130,
            "Frontier-only loss frequency across randomized factors",
            "Each level contains 30 trials by construction. Percent labels make the encoding independent of color.",
        ),
    )
    x0 = 400
    width = 700
    colors = ("#4C78A8", "#F28E2B", "#59A14F")
    for tick in 0:5
        x = x0 + width * tick / 5
        println(
            io,
            """<line x1="$x" y1="115" x2="$x" y2="1050" stroke="#E5E7EB" stroke-width="1"/>""",
        )
        println(
            io,
            """<text x="$x" y="1080" text-anchor="middle" font-family="Helvetica,Arial,sans-serif" font-size="13" fill="#6B7280">$(20tick)%</text>""",
        )
    end
    for (factor_index, factor) in enumerate(FACTORS)
        y = 145 + 78(factor_index - 1)
        rows = filter(row -> row.factor == factor, experiment.factor_summary)
        level_order = string.(_level_values(experiment.config, factor))
        sort!(
            rows;
            by = row -> findfirst(==(row.level), level_order),
        )
        println(
            io,
            """<text x="60" y="$(y + 5)" font-family="Helvetica,Arial,sans-serif" font-size="15" font-weight="700" fill="#1F2937">$(_svg_escape(FACTOR_LABELS[factor]))</text>""",
        )
        for (level_index, row) in enumerate(rows)
            offset = 20 * (level_index - 2)
            point = Float64(row.frontier_only_loss_frequency)
            x = x0 + width * point
            println(
                io,
                """<line x1="$x0" y1="$(y + offset)" x2="$x" y2="$(y + offset)" stroke="$(colors[level_index])" stroke-width="3"/>""",
            )
            println(
                io,
                """<circle cx="$x" cy="$(y + offset)" r="7" fill="$(colors[level_index])"/>""",
            )
            println(
                io,
                """<text x="$(x + 12)" y="$(y + offset + 4)" font-family="Helvetica,Arial,sans-serif" font-size="12" fill="#111827">$(_svg_escape(row.level)): $(_percent(row.frontier_only_loss_frequency))</text>""",
            )
        end
    end
    println(
        io,
        """<text x="60" y="1110" font-family="Helvetica,Arial,sans-serif" font-size="13" fill="#6B7280">Marginal contrasts are descriptive and confounded by the finite randomized design; no causal or theorem claim is attached.</text>""",
    )
    println(io, "</svg>")
    return String(take!(io))
end

function _report_method_table(experiment)
    io = IOBuffer()
    println(
        io,
        "| Pruning rule | Mean reduction | Loss frequency | Mean operational loss | Mean generative loss | Mean total loss | Max total loss |",
    )
    println(io, "|---|---:|---:|---:|---:|---:|---:|")
    for row in experiment.method_summary
        println(
            io,
            "| $(METHOD_LABELS[row.method]) | $(_percent(row.mean_library_reduction)) | " *
            "$(row.future_value_loss_count)/$(row.trials) ($(_percent(row.future_value_loss_frequency))) | " *
            "$(_decimal(row.mean_operational_loss)) | $(_decimal(row.mean_generative_loss)) | " *
            "$(_decimal(row.mean_total_dynamic_loss)) | $(_decimal(row.maximum_total_dynamic_loss)) |",
        )
    end
    return String(take!(io))
end

function render_randomized_library_report(experiment)
    p = experiment.prevalence
    frontier_summary = only(
        row for row in experiment.method_summary if
        row.method == :frontier_only
    )
    ranked = sort(
        experiment.factor_summary;
        by = row -> (
            -Float64(row.frontier_only_loss_frequency),
            string(row.factor),
            row.level,
        ),
    )
    leading = first(ranked, min(5, length(ranked)))
    source_paths = [
        experiment.config["outputs"][name] for name in (
            "trials",
            "pruning",
            "carriers",
            "profiles",
            "modules",
            "closures",
            "kernels",
            "projects",
            "method_summary",
            "factor_summary",
            "summary",
        )
    ]
    io = IOBuffer()
    println(io, "# Randomized finite-library stress test")
    println(io)
    println(io, "## Technical summary")
    println(io)
    println(
        io,
        "Across $(length(experiment.result.trial_rows)) exact finite-library trials, frontier-only pruning caused positive future-value loss in " *
        "$(p.frontier_loss.count)/$(p.frontier_loss.denominator) cases ($(_percent(p.frontier_loss.frequency))). " *
        "Its mean total loss was $(_decimal(frontier_summary.mean_total_dynamic_loss)); conditional on a loss, the mean was " *
        "$(_decimal(frontier_summary.conditional_mean_total_dynamic_loss)). The observed mechanism is therefore " *
        (iszero(p.frontier_loss.count) ?
         "not detected in this randomized design." :
         "not merely a hand-built possibility in this design, but its frequency remains design-dependent.") ,
    )
    println(io)
    println(
        io,
        "Operationally redundant yet generatively valuable carriers appeared in $(p.carrier.count)/$(p.carrier.denominator) source-carrier observations " *
        "($(_percent(p.carrier.frequency)); $(_percent(p.conditional_carrier.frequency)) conditional on operational redundancy). " *
        "Among $(p.closure_contrast.count) trials with a genuine frontier-only closure contrast, the synthetic frontier–closure rectangle produced " *
        "$(p.substitution.count) substitution and $(p.complementarity.count) complementarity cases. These are numerical classifications of `J`, not applications of a Lean sign theorem.",
    )
    println(io)
    println(
        io,
        "> Evidence boundary: every randomized result in this report is an economic-relevance and robustness diagnostic. Random search is not used as proof, theorem validation, or evidence for a universal comparative-static sign.",
    )
    println(io)
    println(io, "## Findings with visual evidence")
    println(io)
    println(io, "![Pruning trade-offs](manuscript/figures/randomized_library_method_comparison.svg)")
    println(io)
    print(io, _report_method_table(experiment))
    println(io)
    println(
        io,
        "Innovation-safe pruning is the zero-loss reference because every deletion is rechecked for exact frontier and closure preservation. " *
        "The operational-budget rule controls passive loss only; the generative-budget rule controls research-option-premium loss only. " *
        "Their unconstrained component can therefore generate a larger total dynamic loss even when the declared budget is met.",
    )
    println(io)
    println(io, "![Observed prevalence](manuscript/figures/randomized_library_prevalence.svg)")
    println(io)
    println(
        io,
        "The displayed Wilson intervals summarize finite-design sampling variation only. They do not turn the generator into a population model.",
    )
    println(io)
    println(io, "![Factor contrasts](manuscript/figures/randomized_library_factor_contrasts.svg)")
    println(io)
    println(io, "The five highest marginal loss-frequency cells were:")
    println(io)
    for row in leading
        println(
            io,
            "- $(FACTOR_LABELS[row.factor]) = `$(row.level)`: " *
            "$(row.frontier_only_loss_count)/$(row.trials) ($(_percent(row.frontier_only_loss_frequency))).",
        )
    end
    println(io)
    println(
        io,
        "These one-factor summaries are descriptive slices of a jointly randomized finite design. They are useful for locating regimes for follow-up analysis, not for causal attribution.",
    )
    println(io)
    println(io, "## Scope, data, and definitions")
    println(io)
    println(
        io,
        "The design independently shuffles balanced three-level columns for belief count, source-library size (including the inactive strategy), module count, module overlap, closure structure, frontier density, candidate quality, generator complementarity, research cost, project delay, admission probability, and regime persistence. " *
        "Each trial contains two candidate projects. `generator_complementarity = k` means a project requires the joint presence of `k` modules. The raw catalog and raw library remain the source of truth.",
    )
    println(io)
    println(
        io,
        "Values average uniformly over initial beliefs at horizon $(experiment.config["horizon"]) with discount factor $(experiment.config["discount_factor"]). Passive value freezes the library and always continues. Research-option premium is total value minus passive value. For a pruned library:",
    )
    println(io)
    println(io, "- operational loss = source passive value − pruned passive value;")
    println(io, "- generative loss = source option premium − pruned option premium;")
    println(io, "- total dynamic loss = source total value − pruned total value.")
    println(io)
    println(
        io,
        "The signed identity `total loss = operational loss + generative loss` is checked exactly on every method and one-carrier deletion. Reported loss magnitudes use the positive part; signed fields remain in the source tables.",
    )
    println(io)
    println(io, "The four pruning rules are:")
    println(io)
    println(
        io,
        "1. **Frontier only:** repeatedly deletes current-frontier-redundant strategies and ignores closure.",
    )
    println(
        io,
        "2. **Innovation safe:** repeatedly deletes only when both the current frontier and closure are preserved.",
    )
    println(
        io,
        "3. **Approximate operational:** greedily deletes while cumulative passive-value loss relative to the source stays within $(experiment.config["operational_budget_fraction"]) of source passive value.",
    )
    println(
        io,
        "4. **Approximate generative:** greedily deletes while cumulative option-premium loss relative to the source stays within $(experiment.config["generative_budget_fraction"]) of source option premium.",
    )
    println(io)
    println(io, "## Methodology and experimental design")
    println(io)
    println(
        io,
        "The master seed is `$(experiment.config["master_seed"])`; each trial has its own recorded seed and deletion order. Factor columns are exactly marginally balanced. Profiles, module incidence, closure tables, Markov kernels, project requirements, admitted-candidate laws, raw updates, and Bellman recursions are finite. All within-trial arithmetic uses `Rational{BigInt}`; there are no solver tolerances or floating-point Bellman comparisons.",
    )
    println(io)
    println(
        io,
        "The frontier–closure statistic uses a synthetic compressed-state rectangle: the observed source frontier versus one-half of that frontier, crossed with source closure versus frontier-pruned closure. `J < 0` is labeled substitution, `J > 0` complementarity, and `J = 0` separability. Frequencies are conditioned on a genuine closure contrast. Because the low-frontier states need not be raw-library realizations, this statistic is explicitly a numerical interaction diagnostic.",
    )
    println(io)
    println(io, "Exact gates require:")
    println(io)
    println(io, "- all loss decompositions to hold as rational equalities;")
    println(io, "- frontier-only pruning to preserve passive value;")
    println(io, "- innovation-safe pruning to preserve total value;")
    println(io, "- each approximate method to satisfy its declared cumulative budget;")
    println(io, "- every row to carry `theorem_evidence = false`.")
    println(io)
    println(io, "All gates passed in the committed run.")
    println(io)
    println(io, "## Source data and reproducibility")
    println(io)
    println(
        io,
        "Run `julia --project=julia julia/scripts/run_randomized_library_stress.jl` to regenerate, or add `--check` for a nonmutating byte comparison. The configuration SHA-256 is `$(experiment.config_sha256)`.",
    )
    println(io)
    for path in source_paths
        println(io, "- [`$path`]($path)")
    end
    println(io)
    println(
        io,
        "The trial, profile, module-incidence, closure-table, kernel, and project files are the complete generated source data. The carrier and pruning files contain exact estimands; method and factor summaries plus JSON are derived outputs.",
    )
    println(io)
    println(io, "## Limitations and robustness boundaries")
    println(io)
    println(
        io,
        "- The generator is deliberately broad but not a probability model of real firms, technologies, or research organizations.",
    )
    println(
        io,
        "- Results cover small libraries, two projects, three-level factor grids, a four-period horizon, and the registered payoff/profile generator.",
    )
    println(
        io,
        "- Marginal factor cells are balanced but other factors vary jointly; cell differences are not causal effects.",
    )
    println(
        io,
        "- Wilson intervals quantify design-sampling uncertainty only. They omit model-generator uncertainty and do not support population prevalence claims.",
    )
    println(
        io,
        "- Exact arithmetic removes numerical error; it does not remove specification error or make randomized evidence deductive.",
    )
    println(io)
    println(io, "## Next steps")
    println(io)
    println(
        io,
        "Use the highest-loss factor cells as preregistered targets for larger-library sparse simulations, then repeat with alternative profile and project generators. Any proposed universal claim must still be formulated and proved independently in Lean; these trials can only motivate or challenge it.",
    )
    println(io)
    println(io, "## Further questions")
    println(io)
    println(
        io,
        "- Does frontier-only loss persist as the candidate count and horizon increase?",
    )
    println(
        io,
        "- Which closure generators produce complementarity once candidate menus and frontier dependence are expanded?",
    )
    println(
        io,
        "- Can operational and generative loss budgets be combined into a useful certified bi-criterion pruning rule?",
    )
    return String(take!(io))
end

function _artifact_contents(experiment)
    outputs = experiment.config["outputs"]
    return Dict(
        outputs["trials"] => _render_csv(experiment.result.trial_rows),
        outputs["pruning"] => _render_csv(experiment.result.pruning_rows),
        outputs["carriers"] => _render_csv(experiment.result.carrier_rows),
        outputs["profiles"] => _render_csv(experiment.result.profile_rows),
        outputs["modules"] => _render_csv(experiment.result.module_rows),
        outputs["closures"] => _render_csv(experiment.result.closure_rows),
        outputs["kernels"] => _render_csv(experiment.result.kernel_rows),
        outputs["projects"] => _render_csv(experiment.result.project_rows),
        outputs["method_summary"] => _render_csv(experiment.method_summary),
        outputs["factor_summary"] => _render_csv(experiment.factor_summary),
        outputs["summary"] => _render_summary_json(experiment),
        outputs["report"] => render_randomized_library_report(experiment),
        outputs["method_figure"] => render_method_figure(experiment),
        outputs["prevalence_figure"] => render_prevalence_figure(experiment),
        outputs["factor_figure"] => render_factor_figure(experiment),
    )
end

function _absolute(path)
    return isabspath(path) ? path : joinpath(REPOSITORY_ROOT, path)
end

function _write_or_check(artifacts, check)
    for (relative_path, content) in sort(
        collect(artifacts);
        by = first,
    )
        path = _absolute(relative_path)
        if check
            isfile(path) || error("missing randomized-library artifact: $path")
            read(path, String) == content ||
                error("stale randomized-library artifact: $path")
        else
            mkpath(dirname(path))
            open(path, "w") do io
                write(io, content)
            end
        end
    end
    return nothing
end

function main(args = ARGS)
    check = "--check" in args
    paths = filter(argument -> argument != "--check", args)
    length(paths) <= 1 ||
        error("usage: run_randomized_library_stress.jl [config] [--check]")
    config_path = isempty(paths) ? DEFAULT_CONFIG : only(paths)
    experiment = run_randomized_library_stress_experiment(config_path)
    _write_or_check(_artifact_contents(experiment), check)
    println(
        check ? "randomized-library artifacts are current" :
        "wrote randomized-library artifacts",
    )
    return experiment
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
