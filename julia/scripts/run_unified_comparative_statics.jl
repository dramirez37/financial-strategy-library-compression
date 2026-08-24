module UnifiedComparativeStaticsExperiment

using Printf
using StrategyInnovation
using TOML

export main,
    render_exact_fixtures_csv,
    render_interaction_csv,
    render_policy_figure,
    render_response_csv,
    render_sign_checks_csv,
    render_summary_json,
    render_value_figure,
    run_unified_comparative_statics_experiment,
    write_unified_comparative_statics_outputs

const EXPERIMENT_ID = "unified-comparative-statics-v1"
const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "unified_comparative_statics.toml",
)
const SURFACE_PARAMETERS = (
    :frontier_level,
    :frontier_density,
    :closure_richness,
    :module_overlap,
    :research_cost,
    :research_duration,
    :admission_probability,
    :candidate_survival,
    :discount_factor,
    :belief_kernel_persistence,
    :signal_precision_proxy,
    :candidate_profile_quality,
    :generator_frontier_dependence,
)

_number(value::Integer) = string(value)
_number(value::AbstractFloat) = @sprintf("%.12g", value)
_number(value::Rational) = "$(numerator(value))//$(denominator(value))"
_json_bool(value::Bool) = value ? "true" : "false"
_json_escape(value) = replace(
    string(value),
    "\\" => "\\\\",
    "\"" => "\\\"",
    "\n" => "\\n",
)

function _baseline_parameters(config)
    values = config["baseline"]
    return UnifiedComparativeParameters(
        mode = Float64Mode(),
        frontier_level = values["frontier_level"],
        frontier_density = values["frontier_density"],
        closure_richness = values["closure_richness"],
        module_overlap = values["module_overlap"],
        research_cost = values["research_cost"],
        research_duration = values["research_duration"],
        admission_probability = values["admission_probability"],
        candidate_survival = values["candidate_survival"],
        discount_factor = values["discount_factor"],
        belief_kernel_persistence = values["belief_kernel_persistence"],
        signal_precision_proxy = values["signal_precision_proxy"],
        candidate_profile_quality = values["candidate_profile_quality"],
        generator_frontier_dependence = values["generator_frontier_dependence"],
    )
end

function _solver_config(config)
    values = config["float_solver"]
    return ComparativeStaticsConfig(
        mode = Float64Mode(),
        belief_count = values["belief_count"],
        reference_index = values["reference_index"],
        finite_horizon = values["finite_horizon"],
        value_tolerance = values["value_tolerance"],
        residual_gate = values["residual_gate"],
        error_gate = values["error_gate"],
        max_iterations = values["max_iterations"],
        frontier_step = values["frontier_step"],
        closure_step = values["closure_step"],
        parameter_step = values["parameter_step"],
        operates_during_research = values["operates_during_research"],
    )
end

function _true_flags(flags)
    names = Symbol[]
    for name in fieldnames(ComparativeStaticsFlags)
        getfield(flags, name) && push!(names, name)
    end
    return join(string.(names), ";")
end

function _surface_row(parameter, parameter_value, result)
    p = result.parameters
    return (
        parameter,
        parameter_value = Float64(parameter_value),
        frontier_level = p.frontier_level,
        frontier_density = p.frontier_density,
        closure_richness = p.closure_richness,
        module_overlap = p.module_overlap,
        research_cost = p.research_cost,
        research_duration = p.research_duration,
        admission_probability = p.admission_probability,
        candidate_survival = p.candidate_survival,
        discount_factor = p.discount_factor,
        belief_kernel_persistence = p.belief_kernel_persistence,
        signal_precision_proxy = p.signal_precision_proxy,
        candidate_profile_quality = p.candidate_profile_quality,
        generator_frontier_dependence = p.generator_frontier_dependence,
        total_value = result.total_value,
        passive_value = result.passive_value,
        research_option_premium = result.research_option_premium,
        operational_innovation = result.operational_innovation,
        generative_innovation = result.generative_innovation,
        research_frequency = result.research_frequency,
        optimal_action = result.optimal_action,
        research_cutoff = result.research_cutoff,
        cutoff_kind = result.cutoff_kind,
        pruning_loss = result.pruning_loss,
        compression_ratio = Float64(result.compression_ratio),
        descendant_quality = result.descendant_quality,
        frontier_closure_cross_difference =
            result.frontier_closure_cross_difference,
        bellman_residual = result.bellman_residual,
        value_error_bound = result.value_error_bound,
        iterations = result.iterations,
        converged = result.converged,
        gate_passed = result.gate_passed,
        sparse_mode = result.sparse_mode,
        raw_source_of_truth = result.raw_source_of_truth,
        flags = _true_flags(result.flags),
    )
end

function run_unified_comparative_statics_experiment(
    config_path::AbstractString = DEFAULT_CONFIG,
)
    config = TOML.parsefile(config_path)
    config["schema_version"] == EXPERIMENT_ID ||
        error("unexpected comparative-statics schema")
    parameters = _baseline_parameters(config)
    solver = _solver_config(config)
    exact_fixtures = exact_comparative_statics_fixtures()
    baseline = run_unified_comparative_statics(parameters, solver)
    repeated = run_unified_comparative_statics(parameters, solver)

    response_rows = NamedTuple[]
    surface = config["surface"]
    for parameter in SURFACE_PARAMETERS
        values = surface[string(parameter)]
        for value in values
            varied = with_comparative_parameter(parameters, parameter, value)
            result = run_unified_comparative_statics(varied, solver)
            push!(response_rows, _surface_row(parameter, value, result))
        end
    end

    interaction_rows = NamedTuple[]
    interaction = config["interaction_surface"]
    for closure in interaction["closure_richness"]
        for frontier in interaction["frontier_level"]
            varied = with_comparative_parameter(
                with_comparative_parameter(
                    parameters,
                    :frontier_level,
                    frontier,
                ),
                :closure_richness,
                closure,
            )
            result = run_unified_comparative_statics(varied, solver)
            push!(
                interaction_rows,
                (
                    frontier_level = Float64(frontier),
                    closure_richness = Float64(closure),
                    total_value = result.total_value,
                    research_option_premium = result.research_option_premium,
                    research_frequency = result.research_frequency,
                    interaction = result.frontier_closure_cross_difference,
                    gate_passed = result.gate_passed,
                ),
            )
        end
    end

    sign_checks = run_comparative_static_sign_checks(parameters, solver)
    deterministic =
        baseline.total_value == repeated.total_value &&
        baseline.passive_value == repeated.passive_value &&
        baseline.frontier_closure_cross_difference ==
        repeated.frontier_closure_cross_difference &&
        baseline.policy == repeated.policy &&
        baseline.bellman_residual == repeated.bellman_residual
    applicable_checks = filter(check -> check.applicable, sign_checks)
    checks = (
        exact_fixtures = exact_fixtures.all_passed,
        sparse_float64 = baseline.sparse_mode,
        raw_source_of_truth = baseline.raw_source_of_truth,
        baseline_gate = baseline.gate_passed,
        response_gates = all(row.gate_passed for row in response_rows),
        interaction_gates = all(row.gate_passed for row in interaction_rows),
        applicable_signs = all(check.passed for check in applicable_checks),
        boundary_flags =
            baseline.flags.persistence_has_no_universal_sign &&
            baseline.flags.bellman_cutoff_is_numerical_only &&
            any(
                occursin("frontier_dependent_generator", row.flags) for
                row in response_rows
            ),
        deterministic,
    )
    all(values(checks)) ||
        error("unified comparative-statics experiment gate failed: $checks")

    return (
        experiment_id = EXPERIMENT_ID,
        arithmetic = (
            exact = "Rational{BigInt}",
            response_surface = "sparse Float64",
        ),
        randomness = "none",
        model = config["model"],
        parameters,
        solver,
        baseline,
        exact_fixtures,
        response_rows,
        interaction_rows,
        sign_checks,
        checks,
    )
end

const RESPONSE_COLUMNS = (
    :parameter,
    :parameter_value,
    :frontier_level,
    :frontier_density,
    :closure_richness,
    :module_overlap,
    :research_cost,
    :research_duration,
    :admission_probability,
    :candidate_survival,
    :discount_factor,
    :belief_kernel_persistence,
    :signal_precision_proxy,
    :candidate_profile_quality,
    :generator_frontier_dependence,
    :total_value,
    :passive_value,
    :research_option_premium,
    :operational_innovation,
    :generative_innovation,
    :research_frequency,
    :optimal_action,
    :research_cutoff,
    :cutoff_kind,
    :pruning_loss,
    :compression_ratio,
    :descendant_quality,
    :frontier_closure_cross_difference,
    :bellman_residual,
    :value_error_bound,
    :iterations,
    :converged,
    :gate_passed,
    :sparse_mode,
    :raw_source_of_truth,
    :flags,
)

function _csv_value(value)
    isnothing(value) && return ""
    value isa Bool && return lowercase(string(value))
    value isa Real && return _number(value)
    return string(value)
end

function render_response_csv(result)
    io = IOBuffer()
    println(io, join(string.(RESPONSE_COLUMNS), ","))
    for row in result.response_rows
        println(io, join((_csv_value(getproperty(row, name)) for name in RESPONSE_COLUMNS), ","))
    end
    return String(take!(io))
end

function render_interaction_csv(result)
    io = IOBuffer()
    columns = (
        :frontier_level,
        :closure_richness,
        :total_value,
        :research_option_premium,
        :research_frequency,
        :interaction,
        :gate_passed,
    )
    println(io, join(string.(columns), ","))
    for row in result.interaction_rows
        println(io, join((_csv_value(getproperty(row, name)) for name in columns), ","))
    end
    return String(take!(io))
end

function render_sign_checks_csv(result)
    io = IOBuffer()
    println(
        io,
        "check_id,theorem_id,expected_direction,observed_difference,applicable,passed,boundary_flag,detail",
    )
    for check in result.sign_checks
        detail = replace(check.detail, "," => ";")
        println(
            io,
            join(
                (
                    check.check_id,
                    check.theorem_id,
                    check.expected_direction,
                    _number(check.observed_difference),
                    lowercase(string(check.applicable)),
                    lowercase(string(check.passed)),
                    check.boundary_flag,
                    detail,
                ),
                ",",
            ),
        )
    end
    return String(take!(io))
end

function render_exact_fixtures_csv(result)
    io = IOBuffer()
    println(io, "fixture_id,theorem_id,observed,expected,passed,detail")
    for row in result.exact_fixtures.rows
        println(
            io,
            join(
                (
                    row.fixture_id,
                    row.theorem_id,
                    row.observed,
                    row.expected,
                    lowercase(string(row.passed)),
                    replace(row.detail, "," => ";"),
                ),
                ",",
            ),
        )
    end
    return String(take!(io))
end

function render_summary_json(result)
    baseline = result.baseline
    io = IOBuffer()
    println(io, "{")
    println(io, "  \"arithmetic\": {")
    println(io, "    \"exact\": \"$(result.arithmetic.exact)\",")
    println(
        io,
        "    \"response_surface\": \"$(result.arithmetic.response_surface)\"",
    )
    println(io, "  },")
    println(io, "  \"baseline\": {")
    for (index, name) in enumerate((
        :total_value,
        :passive_value,
        :research_option_premium,
        :operational_innovation,
        :generative_innovation,
        :research_frequency,
        :pruning_loss,
        :descendant_quality,
        :frontier_closure_cross_difference,
        :bellman_residual,
        :value_error_bound,
    ))
        comma = index == 11 ? "" : ","
        println(
            io,
            "    \"$name\": $(_number(getproperty(baseline, name)))$comma",
        )
    end
    println(io, "  },")
    println(io, "  \"baseline_flags\": {")
    flag_names = fieldnames(ComparativeStaticsFlags)
    for (index, name) in enumerate(flag_names)
        comma = index == length(flag_names) ? "" : ","
        println(
            io,
            "    \"$name\": $(_json_bool(getfield(baseline.flags, name)))$comma",
        )
    end
    println(io, "  },")
    println(io, "  \"checks\": {")
    check_names = collect(keys(result.checks))
    for (index, name) in enumerate(check_names)
        comma = index == length(check_names) ? "" : ","
        println(
            io,
            "    \"$name\": $(_json_bool(getproperty(result.checks, name)))$comma",
        )
    end
    println(io, "  },")
    println(io, "  \"exact_fixture_count\": $(length(result.exact_fixtures.rows)),")
    println(io, "  \"experiment_id\": \"$(result.experiment_id)\",")
    println(io, "  \"interaction_row_count\": $(length(result.interaction_rows)),")
    println(io, "  \"model\": \"$(_json_escape(result.model))\",")
    println(io, "  \"randomness\": \"$(result.randomness)\",")
    println(io, "  \"response_row_count\": $(length(result.response_rows)),")
    println(io, "  \"sign_check_count\": $(length(result.sign_checks))")
    println(io, "}")
    return String(take!(io))
end

_svg_escape(value) = replace(
    string(value),
    "&" => "&amp;",
    "<" => "&lt;",
    ">" => "&gt;",
)

function _line_path(points)
    isempty(points) && return ""
    return join(
        (
            (index == 1 ? "M" : "L") *
            @sprintf("%.2f %.2f", point[1], point[2]) for
            (index, point) in enumerate(points)
        ),
        " ",
    )
end

function _panel_lines!(
    io,
    rows,
    parameter,
    x0,
    y0,
    width,
    height,
    title,
)
    selected = sort(
        filter(row -> row.parameter == parameter, rows);
        by = row -> row.parameter_value,
    )
    xvalues = getfield.(selected, :parameter_value)
    series = (
        (:total_value, "#0072B2", "", "Total"),
        (:passive_value, "#6B7280", "8 5", "Passive"),
        (:research_option_premium, "#D55E00", "3 3", "Option premium"),
    )
    yvalues = reduce(vcat, [Float64[getfield(row, name) for row in selected] for (name, _, _, _) in series])
    xmin, xmax = extrema(xvalues)
    ymin = min(0.0, minimum(yvalues))
    ymax = maximum(yvalues)
    ymax == ymin && (ymax = ymin + 1)
    sx(value) = x0 + 46 + (value - xmin) / max(xmax - xmin, eps()) * (width - 64)
    sy(value) = y0 + height - 36 - (value - ymin) / (ymax - ymin) * (height - 66)
    println(io, "<text x=\"$(x0 + 8)\" y=\"$(y0 + 18)\" class=\"panel-title\">$(_svg_escape(title))</text>")
    println(io, "<line x1=\"$(x0 + 46)\" y1=\"$(y0 + 28)\" x2=\"$(x0 + 46)\" y2=\"$(y0 + height - 36)\" class=\"axis\"/>")
    println(io, "<line x1=\"$(x0 + 46)\" y1=\"$(y0 + height - 36)\" x2=\"$(x0 + width - 18)\" y2=\"$(y0 + height - 36)\" class=\"axis\"/>")
    for fraction in (0.0, 0.5, 1.0)
        value = ymin + fraction * (ymax - ymin)
        y = sy(value)
        println(io, "<line x1=\"$(x0 + 46)\" y1=\"$y\" x2=\"$(x0 + width - 18)\" y2=\"$y\" class=\"grid\"/>")
        println(io, "<text x=\"$(x0 + 40)\" y=\"$(y + 4)\" text-anchor=\"end\" class=\"tick\">$(@sprintf("%.2f", value))</text>")
    end
    for (name, color, dash, _) in series
        points = [(sx(row.parameter_value), sy(getfield(row, name))) for row in selected]
        dash_attribute = isempty(dash) ? "" : " stroke-dasharray=\"$dash\""
        println(io, "<path d=\"$(_line_path(points))\" fill=\"none\" stroke=\"$color\" stroke-width=\"2.3\"$dash_attribute/>")
        for point in points
            println(io, "<circle cx=\"$(point[1])\" cy=\"$(point[2])\" r=\"2.3\" fill=\"$color\"/>")
        end
    end
    println(io, "<text x=\"$(x0 + 46)\" y=\"$(y0 + height - 20)\" text-anchor=\"middle\" class=\"tick\">$(@sprintf("%.2g", xmin))</text>")
    println(io, "<text x=\"$(x0 + width - 18)\" y=\"$(y0 + height - 20)\" text-anchor=\"middle\" class=\"tick\">$(@sprintf("%.2g", xmax))</text>")
end

function _svg_header(io, title, subtitle)
    println(io, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
    println(io, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1000\" height=\"650\" viewBox=\"0 0 1000 650\" role=\"img\" aria-labelledby=\"title desc\">")
    println(io, "<title id=\"title\">$(_svg_escape(title))</title>")
    println(io, "<desc id=\"desc\">$(_svg_escape(subtitle))</desc>")
    println(io, "<rect width=\"1000\" height=\"650\" fill=\"#FFFFFF\"/>")
    println(io, "<style>.title{font:600 20px system-ui,sans-serif;fill:#111827}.subtitle{font:13px system-ui,sans-serif;fill:#4B5563}.panel-title{font:600 14px system-ui,sans-serif;fill:#111827}.tick{font:11px system-ui,sans-serif;fill:#4B5563}.legend{font:12px system-ui,sans-serif;fill:#374151}.axis{stroke:#374151;stroke-width:1}.grid{stroke:#E5E7EB;stroke-width:1}</style>")
    println(io, "<text x=\"44\" y=\"34\" class=\"title\">$(_svg_escape(title))</text>")
    println(io, "<text x=\"44\" y=\"55\" class=\"subtitle\">$(_svg_escape(subtitle))</text>")
end

function render_value_figure(result)
    io = IOBuffer()
    _svg_header(
        io,
        "Unified-model value responses",
        "Sparse Float64 solutions; passive value and research-option premium use the same value units.",
    )
    panels = (
        (:research_cost, "Research cost"),
        (:admission_probability, "Admission probability"),
        (:candidate_survival, "Candidate survival"),
        (:discount_factor, "Discount factor"),
    )
    for (index, (parameter, title)) in enumerate(panels)
        column = (index - 1) % 2
        row = (index - 1) ÷ 2
        _panel_lines!(
            io,
            result.response_rows,
            parameter,
            38 + 482 * column,
            78 + 252 * row,
            450,
            226,
            title,
        )
    end
    legend_y = 626
    for (index, (_, color, dash, label)) in enumerate((
        (:total, "#0072B2", "", "Total value"),
        (:passive, "#6B7280", "8 5", "Passive value"),
        (:premium, "#D55E00", "3 3", "Research-option premium"),
    ))
        x = 250 + 190 * (index - 1)
        dash_attribute = isempty(dash) ? "" : " stroke-dasharray=\"$dash\""
        println(io, "<line x1=\"$x\" y1=\"$legend_y\" x2=\"$(x + 30)\" y2=\"$legend_y\" stroke=\"$color\" stroke-width=\"2.5\"$dash_attribute/>")
        println(io, "<text x=\"$(x + 38)\" y=\"$(legend_y + 4)\" class=\"legend\">$label</text>")
    end
    println(io, "</svg>")
    return String(take!(io))
end

function _rgb_hex(low, high, fraction)
    channels = round.(Int, low .+ clamp(fraction, 0, 1) .* (high .- low))
    return @sprintf("#%02X%02X%02X", channels...)
end

function render_policy_figure(result)
    io = IOBuffer()
    _svg_header(
        io,
        "Policy and frontier–closure surface",
        "Left: base-library research frequency. Right: total value over the configured frontier–closure grid.",
    )
    x0, y0, width, height = 48, 100, 430, 440
    println(io, "<text x=\"$x0\" y=\"$(y0 - 12)\" class=\"panel-title\">Research-frequency responses</text>")
    println(io, "<line x1=\"$(x0 + 44)\" y1=\"$y0\" x2=\"$(x0 + 44)\" y2=\"$(y0 + height)\" class=\"axis\"/>")
    println(io, "<line x1=\"$(x0 + 44)\" y1=\"$(y0 + height)\" x2=\"$(x0 + width)\" y2=\"$(y0 + height)\" class=\"axis\"/>")
    for fraction in (0.0, 0.5, 1.0)
        y = y0 + height * (1 - fraction)
        println(io, "<line x1=\"$(x0 + 44)\" y1=\"$y\" x2=\"$(x0 + width)\" y2=\"$y\" class=\"grid\"/>")
        println(io, "<text x=\"$(x0 + 37)\" y=\"$(y + 4)\" text-anchor=\"end\" class=\"tick\">$(@sprintf("%.1f", fraction))</text>")
    end
    response_series = (
        (:research_cost, "#0072B2", "", "Cost"),
        (:admission_probability, "#D55E00", "7 4", "Admission"),
        (:candidate_survival, "#009E73", "2 3", "Survival"),
    )
    for (series_index, (parameter, color, dash, label)) in enumerate(response_series)
        rows = sort(
            filter(row -> row.parameter == parameter, result.response_rows);
            by = row -> row.parameter_value,
        )
        xmin, xmax = extrema(getfield.(rows, :parameter_value))
        points = [
            (
                x0 + 44 + (row.parameter_value - xmin) / max(xmax - xmin, eps()) * (width - 44),
                y0 + height * (1 - row.research_frequency),
            ) for row in rows
        ]
        dash_attribute = isempty(dash) ? "" : " stroke-dasharray=\"$dash\""
        println(io, "<path d=\"$(_line_path(points))\" fill=\"none\" stroke=\"$color\" stroke-width=\"2.5\"$dash_attribute/>")
        for point in points
            println(io, "<circle cx=\"$(point[1])\" cy=\"$(point[2])\" r=\"3\" fill=\"$color\"/>")
        end
        legend_y = y0 + height + 40
        legend_x = x0 + 40 + 120 * (series_index - 1)
        println(io, "<line x1=\"$legend_x\" y1=\"$legend_y\" x2=\"$(legend_x + 25)\" y2=\"$legend_y\" stroke=\"$color\" stroke-width=\"2.5\"$dash_attribute/>")
        println(io, "<text x=\"$(legend_x + 31)\" y=\"$(legend_y + 4)\" class=\"legend\">$label</text>")
    end
    println(io, "<text x=\"$(x0 + 235)\" y=\"$(y0 + height + 22)\" text-anchor=\"middle\" class=\"tick\">Normalized parameter range (low to high)</text>")

    hx, hy, hw, hh = 540, 100, 400, 440
    frontiers = sort(unique(getfield.(result.interaction_rows, :frontier_level)))
    closures = sort(unique(getfield.(result.interaction_rows, :closure_richness)))
    values = getfield.(result.interaction_rows, :total_value)
    vmin, vmax = extrema(values)
    cell_width = hw / length(frontiers)
    cell_height = hh / length(closures)
    println(io, "<text x=\"$hx\" y=\"$(hy - 12)\" class=\"panel-title\">Total value surface</text>")
    for (closure_index, closure) in enumerate(closures)
        for (frontier_index, frontier) in enumerate(frontiers)
            row = only(
                candidate for candidate in result.interaction_rows if
                candidate.frontier_level == frontier &&
                candidate.closure_richness == closure
            )
            fraction = (row.total_value - vmin) / max(vmax - vmin, eps())
            color = _rgb_hex([229, 245, 249], [0, 114, 178], fraction)
            x = hx + (frontier_index - 1) * cell_width
            y = hy + (length(closures) - closure_index) * cell_height
            println(io, "<rect x=\"$x\" y=\"$y\" width=\"$(cell_width + 0.2)\" height=\"$(cell_height + 0.2)\" fill=\"$color\"/>")
            println(io, "<text x=\"$(x + cell_width / 2)\" y=\"$(y + cell_height / 2 + 4)\" text-anchor=\"middle\" class=\"tick\" style=\"fill:$(fraction > 0.55 ? "#FFFFFF" : "#111827")\">$(@sprintf("%.2f", row.total_value))</text>")
        end
    end
    println(io, "<rect x=\"$hx\" y=\"$hy\" width=\"$hw\" height=\"$hh\" fill=\"none\" stroke=\"#374151\"/>")
    for (index, frontier) in enumerate(frontiers)
        x = hx + (index - 0.5) * cell_width
        println(io, "<text x=\"$x\" y=\"$(hy + hh + 18)\" text-anchor=\"middle\" class=\"tick\">$(@sprintf("%.2g", frontier))</text>")
    end
    for (index, closure) in enumerate(closures)
        y = hy + (length(closures) - index + 0.5) * cell_height
        println(io, "<text x=\"$(hx - 8)\" y=\"$(y + 4)\" text-anchor=\"end\" class=\"tick\">$(@sprintf("%.2g", closure))</text>")
    end
    println(io, "<text x=\"$(hx + hw / 2)\" y=\"$(hy + hh + 38)\" text-anchor=\"middle\" class=\"legend\">Frontier level</text>")
    println(io, "<text x=\"$(hx - 42)\" y=\"$(hy + hh / 2)\" text-anchor=\"middle\" class=\"legend\" transform=\"rotate(-90 $(hx - 42) $(hy + hh / 2))\">Closure richness</text>")
    println(io, "<text x=\"48\" y=\"620\" class=\"subtitle\">Research cutoffs are Bellman diagnostics; persistence and J signs are assumption-gated in the machine-readable output.</text>")
    println(io, "</svg>")
    return String(take!(io))
end

function _output_paths(config_path)
    output = TOML.parsefile(config_path)["outputs"]
    return NamedTuple{
        (
            :response_surface,
            :interaction_surface,
            :sign_checks,
            :exact_fixtures,
            :summary,
            :value_figure,
            :policy_figure,
        )
    }(
        Tuple(
            joinpath(REPOSITORY_ROOT, output[name]) for name in (
                "response_surface",
                "interaction_surface",
                "sign_checks",
                "exact_fixtures",
                "summary",
                "value_figure",
                "policy_figure",
            )
        ),
    )
end

function _rendered_outputs(result)
    return (
        response_surface = render_response_csv(result),
        interaction_surface = render_interaction_csv(result),
        sign_checks = render_sign_checks_csv(result),
        exact_fixtures = render_exact_fixtures_csv(result),
        summary = render_summary_json(result),
        value_figure = render_value_figure(result),
        policy_figure = render_policy_figure(result),
    )
end

function write_unified_comparative_statics_outputs(
    result;
    config_path::AbstractString = DEFAULT_CONFIG,
)
    paths = _output_paths(config_path)
    rendered = _rendered_outputs(result)
    for name in keys(paths)
        path = getproperty(paths, name)
        mkpath(dirname(path))
        write(path, getproperty(rendered, name))
    end
    return paths
end

function main(args = ARGS)
    check_only = "--check" in args
    result = run_unified_comparative_statics_experiment(DEFAULT_CONFIG)
    paths = _output_paths(DEFAULT_CONFIG)
    rendered = _rendered_outputs(result)
    if check_only
        for name in keys(paths)
            path = getproperty(paths, name)
            isfile(path) || error("missing registered comparative-statics output: $path")
            read(path, String) == getproperty(rendered, name) ||
                error("registered comparative-statics output drift: $path")
        end
        println("Unified comparative-statics outputs are current.")
    else
        write_unified_comparative_statics_outputs(result)
        for path in paths
            println("Wrote $path")
        end
    end
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
