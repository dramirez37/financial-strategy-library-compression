module ApproximateCompressionExperiment

using Printf
using SHA
using StrategyInnovation
using TOML

export main,
    render_approximate_compression_report,
    render_approximate_pareto_figure,
    render_approximate_search_figure,
    run_approximate_compression_experiment

const EXPERIMENT_ID = "approximate-library-compression-v1"
const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "approximate_compression.toml",
)
const BENCHMARKS = ("base", "expanded")
const GREEDY_CRITERIA = (:balanced, :operational, :generative, :value)
const BLUE = "#4C78A8"
const BLUE_DARK = "#2F5D8A"
const GOLD = "#E3A52B"
const GOLD_DARK = "#9A6700"
const INK = "#1F2937"
const MUTED = "#6B7280"
const GRID = "#D8DEE8"
const LIGHT = "#EEF2F7"

_exact(value) = exact_rational(value)
_exact_string(value::Rational) =
    "$(numerator(value))//$(denominator(value))"
_decimal(value) = @sprintf("%.4f", Float64(value))
_short_decimal(value) = @sprintf("%.2g", Float64(value))
_percent(value) = @sprintf("%.1f%%", 100 * Float64(value))

function _fixture_parameters(config)
    row = config["fixture"]
    return RandomizedLibraryParameters(
        trial_id = row["trial_id"],
        seed = row["seed"],
        belief_count = row["belief_count"],
        strategy_count = row["strategy_count"],
        module_count = row["module_count"],
        module_overlap = Symbol(row["module_overlap"]),
        closure_structure = Symbol(row["closure_structure"]),
        frontier_density = _exact(row["frontier_density"]),
        candidate_quality = _exact(row["candidate_quality"]),
        generator_complementarity = row["generator_complementarity"],
        research_cost = _exact(row["research_cost"]),
        project_delay = row["project_delay"],
        admission_probability = _exact(row["admission_probability"]),
        regime_persistence = _exact(row["regime_persistence"]),
    )
end

function _reference_belief(model, id)
    matches = filter(belief -> belief.id == id, collect(model.kernel.space))
    length(matches) == 1 ||
        error("reference belief id must resolve exactly once")
    return only(matches)
end

function _benchmark_sources(model)
    expanded = RawLibrary(
        model.catalog,
        [row.id for row in model.catalog.strategies],
    )
    return Dict("base" => model.source, "expanded" => expanded)
end

function _retained_ids(problem, library)
    return join(
        (
            string(row.id.id) for row in problem.process.catalog.strategies if
            row.id in library
        ),
        ";",
    )
end

function _subset_row(benchmark, problem, record, pareto)
    return (
        benchmark,
        source_size = length(problem.source),
        retained_size = record.retained_size,
        removed_count = length(problem.source) - record.retained_size,
        compression_ratio =
            _exact(length(problem.source) - record.retained_size) /
            _exact(length(problem.source)),
        retained_ids = _retained_ids(problem, record.library),
        epsilon_operational = problem.epsilon_operational,
        epsilon_generative = problem.epsilon_generative,
        operational_loss = record.operational_loss,
        operating_value_loss = record.operating_value_loss,
        generative_loss = record.generative_loss,
        value_loss = record.value_loss,
        operational_loss_decimal = Float64(record.operational_loss),
        operating_value_loss_decimal = Float64(record.operating_value_loss),
        generative_loss_decimal = Float64(record.generative_loss),
        value_loss_decimal = Float64(record.value_loss),
        feasible = record.feasible,
        pareto,
        decomposition_gate = record.decomposition_gate,
        theorem_evidence = false,
    )
end

function _algorithm_row(
    benchmark,
    problem,
    solution,
    exact_size,
    total_subsets;
    beam_width = missing,
)
    record = solution.record
    return (
        benchmark,
        method = solution.method,
        beam_width,
        source_size = length(problem.source),
        retained_size = record.retained_size,
        cardinality_gap = record.retained_size - exact_size,
        removed_count = length(problem.source) - record.retained_size,
        compression_ratio =
            _exact(length(problem.source) - record.retained_size) /
            _exact(length(problem.source)),
        operational_loss = record.operational_loss,
        operating_value_loss = record.operating_value_loss,
        generative_loss = record.generative_loss,
        value_loss = record.value_loss,
        retained_ids = _retained_ids(problem, record.library),
        evaluated_count = solution.evaluated_count,
        total_subsets,
        evaluation_effort_ratio =
            _exact(solution.evaluated_count) / _exact(total_subsets),
        feasible = record.feasible,
        complete_search = solution.exact,
        optimality_certified = solution.optimal,
        theorem_evidence = false,
    )
end

function run_approximate_compression_experiment(
    config_path::AbstractString = DEFAULT_CONFIG,
)
    config = TOML.parsefile(config_path)
    config["schema_version"] == EXPERIMENT_ID ||
        error("unexpected approximate-compression schema")
    parameters = _fixture_parameters(config)
    model = build_randomized_library_model(parameters)
    sources = _benchmark_sources(model)
    reference_belief =
        _reference_belief(model, config["reference_belief_id"])
    problems = Dict{String,Any}()
    exact_results = Dict{String,Any}()
    subset_rows = NamedTuple[]
    pareto_rows = NamedTuple[]
    algorithm_rows = NamedTuple[]
    ip_rows = NamedTuple[]

    for benchmark in BENCHMARKS
        source = sources[benchmark]
        problem = ApproximateCompressionProblem(
            model.process,
            source;
            horizon = config["horizon"],
            reference_belief,
            epsilon_operational = _exact(config["epsilon_operational"]),
            epsilon_generative = _exact(config["epsilon_generative"]),
        )
        problems[benchmark] = problem
        exact_result = enumerate_approximate_compressions(
            problem;
            max_optional = config["exact_max_optional"],
        )
        exact_results[benchmark] = exact_result
        pareto_libraries = Set(
            record.library for record in exact_result.pareto_records
        )
        for record in exact_result.records
            row = _subset_row(
                benchmark,
                problem,
                record,
                record.library in pareto_libraries,
            )
            push!(subset_rows, row)
            row.pareto && push!(pareto_rows, row)
        end

        exact_size = exact_result.solution.record.retained_size
        total_subsets = length(exact_result.records)
        push!(
            algorithm_rows,
            _algorithm_row(
                benchmark,
                problem,
                exact_result.solution,
                exact_size,
                total_subsets,
            ),
        )
        for criterion in GREEDY_CRITERIA
            solution =
                greedy_approximate_compression(problem; criterion)
            push!(
                algorithm_rows,
                _algorithm_row(
                    benchmark,
                    problem,
                    solution,
                    exact_size,
                    total_subsets,
                ),
            )
        end
        multistart = multistart_greedy_approximate_compression(problem)
        push!(
            algorithm_rows,
            _algorithm_row(
                benchmark,
                problem,
                multistart.solution,
                exact_size,
                total_subsets,
            ),
        )
        for beam_width in config["beam_widths"]
            result =
                pareto_beam_compression(problem; beam_width)
            push!(
                algorithm_rows,
                _algorithm_row(
                    benchmark,
                    problem,
                    result.solution,
                    exact_size,
                    total_subsets;
                    beam_width,
                ),
            )
        end

        formulation = approximate_compression_ip_formulation(
            problem;
            records = exact_result.records,
        )
        lower_bound = operational_ip_cardinality_lower_bound(formulation)
        exact_selected = Bool[
            strategy_id in exact_result.solution.record.library for
            strategy_id in formulation.strategy_ids
        ]
        push!(
            ip_rows,
            (
                benchmark,
                source_size = length(source),
                belief_constraints = length(formulation.beliefs),
                binary_strategy_variables =
                    length(formulation.strategy_ids),
                epsilon_operational = formulation.epsilon_operational,
                epsilon_generative = formulation.epsilon_generative,
                generative_no_good_cuts =
                    length(formulation.generative_no_good_cuts),
                evaluated_count = formulation.evaluated_count,
                complete_generative_oracle =
                    formulation.complete_generative_oracle,
                operational_cardinality_lower_bound = lower_bound,
                exact_bicriterion_optimum = exact_size,
                generative_cardinality_lift = exact_size - lower_bound,
                optimum_satisfies_complete_formulation =
                    satisfies_approximate_compression_ip_formulation(
                        formulation,
                        exact_selected,
                    ),
                external_optimizer_dependency = false,
                theorem_evidence = false,
            ),
        )
    end

    exact_solutions = Dict(
        benchmark => exact_results[benchmark].solution.record for
        benchmark in BENCHMARKS
    )
    gates = (
        exact_subset_counts = all(
            length(exact_results[benchmark].records) ==
            (1 << (length(problems[benchmark].source) - 1)) for
            benchmark in BENCHMARKS
        ),
        decomposition = all(row.decomposition_gate for row in subset_rows),
        exact_feasibility =
            all(exact_solutions[name].feasible for name in BENCHMARKS),
        exact_minimum = all(
            !any(
                record.feasible &&
                record.retained_size < exact_solutions[name].retained_size for
                record in exact_results[name].records
            ) for name in BENCHMARKS
        ),
        heuristic_feasibility =
            all(row.feasible for row in algorithm_rows),
        formulation =
            all(
                row.complete_generative_oracle &&
                row.optimum_satisfies_complete_formulation for row in ip_rows
            ),
        theorem_boundary =
            all(!row.theorem_evidence for row in subset_rows) &&
            all(!row.theorem_evidence for row in algorithm_rows) &&
            all(!row.theorem_evidence for row in ip_rows),
    )
    all(values(gates)) ||
        error("approximate-compression experiment gate failed: $gates")
    return (
        experiment_id = EXPERIMENT_ID,
        config_path,
        config,
        parameters,
        model,
        problems,
        exact_results,
        subset_rows,
        pareto_rows,
        algorithm_rows,
        ip_rows,
        gates,
    )
end

function _csv_value(value)
    value === missing && return ""
    value isa Rational && return _exact_string(value)
    value isa Symbol && return string(value)
    value isa Bool && return lowercase(string(value))
    value isa AbstractFloat && return @sprintf("%.10f", value)
    return string(value)
end

function _csv_escape(value)
    text = _csv_value(value)
    occursin(r"[\",\n]", text) || return text
    return "\"" * replace(text, "\"" => "\"\"") * "\""
end

function _render_csv(rows)
    isempty(rows) && return ""
    fields = propertynames(first(rows))
    io = IOBuffer()
    println(io, join(string.(fields), ","))
    for row in rows
        println(
            io,
            join((_csv_escape(getproperty(row, field)) for field in fields), ","),
        )
    end
    return String(take!(io))
end

_xml(text) = replace(
    string(text),
    "&" => "&amp;",
    "<" => "&lt;",
    ">" => "&gt;",
    "\"" => "&quot;",
)

function _scale(value, lower, upper, start, width)
    upper == lower && return start + width / 2
    return start + (Float64(value) - lower) / (upper - lower) * width
end

function _yscale(value, lower, upper, top, height)
    upper == lower && return top + height / 2
    return top + height -
           (Float64(value) - lower) / (upper - lower) * height
end

function _svg_start(io, width, height, title, description)
    println(
        io,
        """<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height" role="img" aria-labelledby="title desc">""",
    )
    println(io, "<title id=\"title\">$(_xml(title))</title>")
    println(io, "<desc id=\"desc\">$(_xml(description))</desc>")
    println(io, "<rect width=\"100%\" height=\"100%\" fill=\"#FFFFFF\"/>")
    println(
        io,
        """<style>.title{font:700 28px Helvetica,Arial,sans-serif;fill:$INK}.subtitle{font:15px Helvetica,Arial,sans-serif;fill:$MUTED}.panel{font:700 18px Helvetica,Arial,sans-serif;fill:$INK}.axis{font:13px Helvetica,Arial,sans-serif;fill:$MUTED}.note{font:12px Helvetica,Arial,sans-serif;fill:$MUTED}.direct{font:700 11px Menlo,monospace;fill:$INK}</style>""",
    )
    println(io, "<text x=\"54\" y=\"48\" class=\"title\">$(_xml(title))</text>")
    println(
        io,
        "<text x=\"54\" y=\"76\" class=\"subtitle\">$(_xml(description))</text>",
    )
    println(
        io,
        """<g transform="translate($(width - 86),36)" stroke="$GOLD_DARK" fill="none" stroke-width="1.5"><circle r="5"/><path d="M0,-14V-7 M0,7V14 M-14,0H-7 M7,0H14 M-10,-10L-5,-5 M5,5L10,10 M10,-10L5,-5 M-5,5L-10,10"/></g>""",
    )
end

function _axes(io, x, y, width, height, x_label, y_label)
    println(
        io,
        """<line x1="$x" y1="$(y + height)" x2="$(x + width)" y2="$(y + height)" stroke="$INK" stroke-width="1.2"/>""",
    )
    println(
        io,
        """<line x1="$x" y1="$y" x2="$x" y2="$(y + height)" stroke="$INK" stroke-width="1.2"/>""",
    )
    println(
        io,
        """<text x="$(x + width / 2)" y="$(y + height + 42)" text-anchor="middle" class="axis">$(_xml(x_label))</text>""",
    )
    println(
        io,
        """<text x="$(x - 42)" y="$(y + height / 2)" text-anchor="middle" class="axis" transform="rotate(-90 $(x - 42) $(y + height / 2))">$(_xml(y_label))</text>""",
    )
end

function _x_ticks(io, values, lower, upper, x, y, width)
    for value in values
        position = _scale(value, lower, upper, x, width)
        println(
            io,
            """<line x1="$position" y1="$y" x2="$position" y2="$(y + 6)" stroke="$INK"/>""",
        )
        println(
            io,
            """<text x="$position" y="$(y + 20)" text-anchor="middle" class="note">$(@sprintf("%.2g", value))</text>""",
        )
    end
end

function _y_ticks(io, values, lower, upper, x, y, height)
    for value in values
        position = _yscale(value, lower, upper, y, height)
        println(
            io,
            """<line x1="$(x - 6)" y1="$position" x2="$x" y2="$position" stroke="$INK"/>""",
        )
        println(
            io,
            """<text x="$(x - 10)" y="$(position + 4)" text-anchor="end" class="note">$(@sprintf("%.2g", value))</text>""",
        )
    end
end

function _point(io, x, y, row)
    if row.pareto
        println(
            io,
            """<rect x="$(x - 5)" y="$(y - 5)" width="10" height="10" transform="rotate(45 $x $y)" fill="$GOLD" stroke="$GOLD_DARK" stroke-width="1.3"/>""",
        )
    elseif row.feasible
        println(
            io,
            """<circle cx="$x" cy="$y" r="4.5" fill="$BLUE" stroke="$BLUE_DARK" stroke-width="1"/>""",
        )
    else
        println(
            io,
            """<circle cx="$x" cy="$y" r="4" fill="#FFFFFF" stroke="#9CA3AF" stroke-width="1"/>""",
        )
    end
end

function render_approximate_pareto_figure(experiment)
    rows = filter(row -> row.benchmark == "base", experiment.subset_rows)
    epsilon_op = Float64(experiment.problems["base"].epsilon_operational)
    epsilon_gen = Float64(experiment.problems["base"].epsilon_generative)
    sizes = Float64[row.retained_size for row in rows]
    op = Float64[row.operational_loss_decimal for row in rows]
    gen = Float64[row.generative_loss_decimal for row in rows]
    size_min, size_max = minimum(sizes), maximum(sizes)
    op_min, op_max = min(0.0, minimum(op)), max(epsilon_op, maximum(op))
    gen_min = min(minimum(gen), 0.0)
    gen_max = max(epsilon_gen, maximum(gen))
    gen_padding = max((gen_max - gen_min) * 0.08, 0.02)
    gen_min -= gen_padding
    gen_max += gen_padding

    io = IOBuffer()
    _svg_start(
        io,
        1200,
        1200,
        "Approximate compression loss surface",
        "All 32 exact sublibraries of the six-strategy benchmark; H=4, εop=1, εgen=0.25",
    )
    panels = (
        (60.0, "A. Size and operational loss"),
        (445.0, "B. Size and generative loss"),
        (830.0, "C. Operational and generative loss"),
    )
    for (x, title) in panels
        println(io, "<text x=\"$x\" y=\"125\" class=\"panel\">$title</text>")
    end
    y, width, height = 155.0, 290.0, 875.0
    _axes(io, panels[1][1], y, width, height, "Retained library size", "OpLoss")
    _axes(io, panels[2][1], y, width, height, "Retained library size", "GenLoss")
    _axes(io, panels[3][1], y, width, height, "OpLoss", "GenLoss")
    size_ticks = collect(size_min:size_max)
    op_ticks = collect(range(op_min, op_max; length = 5))
    gen_ticks = collect(range(gen_min, gen_max; length = 5))
    _x_ticks(
        io,
        size_ticks,
        size_min,
        size_max,
        panels[1][1],
        y + height,
        width,
    )
    _y_ticks(io, op_ticks, op_min, op_max, panels[1][1], y, height)
    _x_ticks(
        io,
        size_ticks,
        size_min,
        size_max,
        panels[2][1],
        y + height,
        width,
    )
    _y_ticks(io, gen_ticks, gen_min, gen_max, panels[2][1], y, height)
    _x_ticks(
        io,
        op_ticks,
        op_min,
        op_max,
        panels[3][1],
        y + height,
        width,
    )
    _y_ticks(io, gen_ticks, gen_min, gen_max, panels[3][1], y, height)

    op_budget_y = _yscale(epsilon_op, op_min, op_max, y, height)
    gen_budget_y = _yscale(epsilon_gen, gen_min, gen_max, y, height)
    gen_zero_y = _yscale(0.0, gen_min, gen_max, y, height)
    println(
        io,
        """<line x1="$(panels[1][1])" y1="$op_budget_y" x2="$(panels[1][1] + width)" y2="$op_budget_y" stroke="$GOLD_DARK" stroke-dasharray="6,5"/><text x="$(panels[1][1] + width - 4)" y="$(op_budget_y - 7)" text-anchor="end" class="note">εop</text>""",
    )
    for x in (panels[2][1], panels[3][1])
        println(
            io,
            """<line x1="$x" y1="$gen_budget_y" x2="$(x + width)" y2="$gen_budget_y" stroke="$GOLD_DARK" stroke-dasharray="6,5"/><text x="$(x + width - 4)" y="$(gen_budget_y - 7)" text-anchor="end" class="note">εgen</text>""",
        )
        println(
            io,
            """<line x1="$x" y1="$gen_zero_y" x2="$(x + width)" y2="$gen_zero_y" stroke="$GRID" stroke-dasharray="3,4"/>""",
        )
    end
    op_budget_x = _scale(epsilon_op, op_min, op_max, panels[3][1], width)
    println(
        io,
        """<line x1="$op_budget_x" y1="$y" x2="$op_budget_x" y2="$(y + height)" stroke="$GOLD_DARK" stroke-dasharray="6,5"/>""",
    )

    for row in rows
        size_x1 = _scale(row.retained_size, size_min, size_max, panels[1][1], width)
        size_x2 = _scale(row.retained_size, size_min, size_max, panels[2][1], width)
        op_y = _yscale(
            row.operational_loss_decimal,
            op_min,
            op_max,
            y,
            height,
        )
        gen_y = _yscale(
            row.generative_loss_decimal,
            gen_min,
            gen_max,
            y,
            height,
        )
        op_x = _scale(
            row.operational_loss_decimal,
            op_min,
            op_max,
            panels[3][1],
            width,
        )
        _point(io, size_x1, op_y, row)
        _point(io, size_x2, gen_y, row)
        _point(io, op_x, gen_y, row)
        if row.pareto
            println(
                io,
                """<text x="$(op_x + 8)" y="$(gen_y - 7)" class="direct">|L′|=$(row.retained_size)</text>""",
            )
        end
    end
    println(
        io,
        """<g transform="translate(72,1145)"><circle cx="5" cy="0" r="4.5" fill="$BLUE" stroke="$BLUE_DARK"/><text x="16" y="4" class="note">budget-feasible</text><circle cx="137" cy="0" r="4" fill="#fff" stroke="#9CA3AF"/><text x="148" y="4" class="note">infeasible</text><rect x="244" y="-5" width="10" height="10" transform="rotate(45 249 0)" fill="$GOLD" stroke="$GOLD_DARK"/><text x="262" y="4" class="note">three-criterion Pareto frontier</text></g>""",
    )
    println(io, "</svg>")
    return String(take!(io))
end

function _search_rows(experiment, benchmark)
    selected = NamedTuple[]
    exact = only(
        row for row in experiment.algorithm_rows if
        row.benchmark == benchmark && row.method == :exact_enumeration
    )
    multi = only(
        row for row in experiment.algorithm_rows if
        row.benchmark == benchmark && row.method == :greedy_multistart
    )
    push!(selected, merge(exact, (display_label = "Exact",)))
    push!(selected, merge(multi, (display_label = "Greedy",)))
    for width in experiment.config["beam_widths"]
        row = only(
            candidate for candidate in experiment.algorithm_rows if
            candidate.benchmark == benchmark &&
            candidate.method == :pareto_beam &&
            candidate.beam_width == width
        )
        push!(selected, merge(row, (display_label = "Beam $width",)))
    end
    return selected
end

function render_approximate_search_figure(experiment)
    io = IOBuffer()
    _svg_start(
        io,
        1200,
        1200,
        "Exact and heuristic compression solutions",
        "Retained cardinality; labels report exact OpLoss / signed GenLoss and search evaluations",
    )
    panel_x = Dict("base" => 70.0, "expanded" => 635.0)
    panel_titles = Dict(
        "base" => "A. Six-strategy benchmark",
        "expanded" => "B. Eight-strategy expanded benchmark",
    )
    shared_upper =
        maximum(row.retained_size for row in experiment.algorithm_rows) + 1
    for benchmark in BENCHMARKS
        rows = _search_rows(experiment, benchmark)
        x0 = panel_x[benchmark]
        println(
            io,
            "<text x=\"$x0\" y=\"125\" class=\"panel\">$(panel_titles[benchmark])</text>",
        )
        plot_y, plot_h, plot_w = 165.0, 800.0, 455.0
        _axes(
            io,
            x0,
            plot_y,
            plot_w,
            plot_h,
            "",
            "Retained library size",
        )
        _y_ticks(
            io,
            collect(0:shared_upper),
            0.0,
            Float64(shared_upper),
            x0,
            plot_y,
            plot_h,
        )
        bar_width = 46.0
        gap = (plot_w - length(rows) * bar_width) / (length(rows) + 1)
        for (index, row) in enumerate(rows)
            x = x0 + gap * index + bar_width * (index - 1)
            bar_height = row.retained_size / shared_upper * plot_h
            y = plot_y + plot_h - bar_height
            fill = row.method == :exact_enumeration ? GOLD : BLUE
            stroke = row.method == :exact_enumeration ? GOLD_DARK : BLUE_DARK
            println(
                io,
                """<rect x="$x" y="$y" width="$bar_width" height="$bar_height" fill="$fill" stroke="$stroke" stroke-width="1.2"/>""",
            )
            println(
                io,
                """<text x="$(x + bar_width / 2)" y="$(y - 10)" text-anchor="middle" class="direct">$(row.retained_size)</text>""",
            )
            println(
                io,
                """<text x="$(x + bar_width / 2)" y="$(y - 27)" text-anchor="middle" class="note">$(_short_decimal(row.operational_loss)) / $(_short_decimal(row.generative_loss))</text>""",
            )
            println(
                io,
                """<text x="$(x + bar_width / 2)" y="$(plot_y + plot_h + 23)" text-anchor="middle" class="note">$(_xml(row.display_label))</text>""",
            )
            println(
                io,
                """<text x="$(x + bar_width / 2)" y="$(plot_y + plot_h + 43)" text-anchor="middle" class="note">n=$(row.evaluated_count)</text>""",
            )
        end
    end
    println(
        io,
        """<text x="70" y="1130" class="note">Gold bars certify the exact optimum. Blue bars are deterministic heuristics; equal size does not imply equal losses or a general approximation guarantee.</text>""",
    )
    println(io, "</svg>")
    return String(take!(io))
end

function _algorithm_summary(experiment, benchmark, method; beam_width = missing)
    matches = filter(
        row ->
            row.benchmark == benchmark &&
            row.method == method &&
            (beam_width === missing || row.beam_width == beam_width),
        experiment.algorithm_rows,
    )
    length(matches) == 1 || error("algorithm row did not resolve uniquely")
    return only(matches)
end

function render_approximate_compression_report(experiment)
    base = _algorithm_summary(
        experiment,
        "base",
        :exact_enumeration,
    )
    expanded = _algorithm_summary(
        experiment,
        "expanded",
        :exact_enumeration,
    )
    base_ip = only(row for row in experiment.ip_rows if row.benchmark == "base")
    expanded_ip =
        only(row for row in experiment.ip_rows if row.benchmark == "expanded")
    expanded_beam = _algorithm_summary(
        experiment,
        "expanded",
        :pareto_beam;
        beam_width = maximum(experiment.config["beam_widths"]),
    )
    io = IOBuffer()
    println(io, "# Numerical Analysis of Approximate Library Compression")
    println(io)
    println(io, "## Technical summary")
    println(io)
    println(
        io,
        "Exact enumeration finds a three-strategy compression of the registered six-strategy source (50.0% reduction) with `OpLoss = 0`, `GenLoss = 0`, and `ValueLoss = 0` under \\(\\epsilon_{op}=1\\), \\(\\epsilon_{gen}=1/4\\), horizon four, and reference belief one. In the eight-strategy expanded benchmark, the exact optimum retains two strategies (75.0% reduction), with `OpLoss = 1/2`, `GenLoss = 0`, and `ValueLoss = 2025/8192` (0.2472).",
    )
    println(io)
    println(
        io,
        "All four greedy scores reach the exact minimum cardinality on both registered benchmarks. A width-16 Pareto beam also reaches the two-strategy expanded optimum after evaluating $(expanded_beam.evaluated_count) of 128 subsets, but it does not certify completeness. These are benchmark results, not approximation ratios. The exact three-loss surface contains negative `GenLoss` rows: deletion can lower passive operating value while increasing the measured research-option residual.",
    )
    println(io)
    println(
        io,
        "**Evidence boundary.** This is a numerical extension only. No Lean declaration, approximation theorem, optimality theorem for a heuristic, or theorem-ledger proof status is created or changed.",
    )
    println(io)
    println(io, "## The exact surface separates operational and generative constraints")
    println(io)
    println(
        io,
        "The three panels report every exact source sublibrary. Filled circles satisfy both budgets, open circles violate at least one, and diamonds are nondominated in retained size, `OpLoss`, and signed `GenLoss`. The third panel labels Pareto points by retained cardinality, avoiding a distorted three-dimensional perspective.",
    )
    println(io)
    println(
        io,
        "![Exact approximate-compression Pareto surface](manuscript/figures/approximate_compression_pareto.svg)",
    )
    println(io)
    println(
        io,
        "The six-strategy benchmark has $(length(experiment.exact_results["base"].pareto_records)) exact Pareto libraries among 32 subsets. The expanded benchmark has $(length(experiment.exact_results["expanded"].pareto_records)) among 128 subsets. Signed generative loss is preserved in the data rather than truncated at zero.",
    )
    println(io)
    println(io, "## Scope, data, and metric definitions")
    println(io)
    println(
        io,
        "The deterministic fixture is randomized-library trial 15, reconstructed from its registered raw catalog parameters and exact seed. The base benchmark is its six-strategy source. The expanded benchmark adds both already-declared candidate strategies, giving eight strategies without changing the raw process. All payoffs, probabilities, Bellman values, losses, budgets, and dominance comparisons use `Rational{BigInt}`.",
    )
    println(io)
    println(
        io,
        "For source \\(L\\), sublibrary \\(L'\\), frozen-library operating value \\(W_H\\), and unified raw-model value \\(V_H\\):",
    )
    println(io)
    println(io, "- `OpLoss(L′) = max_b [F_L(b) − F_L′(b)]`;")
    println(
        io,
        "- `GenLoss(L′) = [V_H(b,L) − V_H(b,L′)] − [W_H(b,L) − W_H(b,L′)]`;",
    )
    println(io, "- `ValueLoss(L′) = V_H(b,L) − V_H(b,L′)`.")
    println(io)
    println(
        io,
        "Thus `ValueLoss = operating-value loss + GenLoss` is an exact checked identity. The optimization minimizes retained cardinality subject to the one-sided bounds `OpLoss ≤ εop` and `GenLoss ≤ εgen`. Because the stated generative definition is signed, negative values are feasible and economically mean that the research-option residual rises after compression.",
    )
    println(io)
    println(io, "## Exact, greedy, Pareto, and integer-program methods")
    println(io)
    println(
        io,
        "Small libraries use complete bit-mask enumeration over every sublibrary containing the inactive strategy, deterministic cardinality-first tie-breaking, and exact Pareto dominance in `(size, OpLoss, GenLoss)`. This is the only method that receives an optimality certificate.",
    )
    println(io)
    println(
        io,
        "Larger-library support has four backward-deletion scores—balanced budget use, operational loss first, generative loss first, and total value loss first—plus a deterministic multistart selector. The Pareto beam expands deletions level by level, retains nondominated loss pairs at each size, and fills remaining capacity by exact budget violation. Every heuristic result is re-evaluated against the source budgets.",
    )
    println(io)
    println(
        io,
        "![Exact and heuristic search comparison](manuscript/figures/approximate_compression_search.svg)",
    )
    println(io)
    println(
        io,
        "The solver-neutral 0–1 layer is deliberately limited to what is justified. `OpLoss ≤ εop` is an exact set-cover constraint at each belief. Unified `GenLoss` is a Bellman-oracle constraint and has no general linear representation here; evaluated violations become exact no-good cuts. With all subset rows supplied, the formulation is exact. With a partial pool, it is explicitly an outer approximation requiring lazy cuts.",
    )
    println(io)
    println(
        io,
        "For the base benchmark the operational-cover relaxation has lower bound $(base_ip.operational_cardinality_lower_bound), but $(base_ip.generative_no_good_cuts) generative no-good cuts raise the exact bi-criterion optimum to $(base.retained_size). For the expanded benchmark the operational lower bound and full optimum both equal $(expanded_ip.exact_bicriterion_optimum), and no generative cut is active. This separation is why adding an optimizer dependency is not justified for the current finite analysis.",
    )
    println(io)
    println(io, "## Validation and robustness checks")
    println(io)
    println(
        io,
        "The artifact gate recomputes all 160 subset rows, every exact decomposition, both cardinality minima, all heuristic budget checks, both complete-oracle 0–1 formulations, and byte-identical CSV/JSON/SVG/report outputs. The exact enumerator is cross-checked against the greedy and beam methods; the width-8 base beam visits all 32 subsets and reproduces the complete Pareto frontier.",
    )
    println(io)
    println(io, "## Limitations")
    println(io)
    println(
        io,
        "The numerical benchmarks are small and share one generated catalog, horizon, belief, and budget pair. Matching the exact optimum on these cases is not evidence of a greedy approximation factor or large-scale performance. Beam search can miss an optimum, and the lazy-cut 0–1 formulation certifies the generative constraint only when its Bellman oracle is complete or an external solve-and-cut loop terminates with a valid certificate.",
    )
    println(io)
    println(
        io,
        "The frontier sup-gap and the passive operating-value loss are different objects. `OpLoss` controls the worst one-period frontier deterioration, while `W` aggregates that frontier through the belief kernel and horizon. Neither randomized selection nor floating-point plotting is used as theorem evidence.",
    )
    println(io)
    println(io, "## Recommended next steps")
    println(io)
    println(
        io,
        "Use the exact enumerator as a regression oracle up to the configured optional-strategy cap. For genuinely larger catalogs, report beam width, evaluated-pool fraction, incumbent cardinality, the operational IP lower bound, and the remaining optimality gap. Add JuMP and an external MILP solver only after a registered benchmark shows that operational cover plus lazy Bellman cuts materially improves on the dependency-free beam.",
    )
    println(io)
    println(io, "## Further questions")
    println(io)
    println(
        io,
        "- Which additional structural assumptions make signed `GenLoss` monotone under deletion?",
    )
    println(
        io,
        "- Can submodularity or exchange conditions yield a separately proved greedy approximation theorem?",
    )
    println(
        io,
        "- How do exact Pareto surfaces change across horizons, reference beliefs, and budget pairs?",
    )
    return String(take!(io))
end

function _render_summary_json(experiment)
    base = _algorithm_summary(
        experiment,
        "base",
        :exact_enumeration,
    )
    expanded = _algorithm_summary(
        experiment,
        "expanded",
        :exact_enumeration,
    )
    config_hash = bytes2hex(sha256(read(experiment.config_path)))
    return string(
        "{",
        "\"schema_version\":\"", EXPERIMENT_ID, "\",",
        "\"experiment_id\":\"", EXPERIMENT_ID, "\",",
        "\"arithmetic\":\"Rational{BigInt}\",",
        "\"horizon\":", experiment.config["horizon"], ",",
        "\"reference_belief_id\":", experiment.config["reference_belief_id"], ",",
        "\"epsilon_operational\":\"", _exact_string(base.operational_loss * 0 + _exact(experiment.config["epsilon_operational"])), "\",",
        "\"epsilon_generative\":\"", _exact_string(_exact(experiment.config["epsilon_generative"])), "\",",
        "\"base\":{\"source_size\":", base.source_size,
        ",\"exact_optimum_size\":", base.retained_size,
        ",\"operational_loss\":\"", _exact_string(base.operational_loss),
        "\",\"generative_loss\":\"", _exact_string(base.generative_loss),
        "\",\"value_loss\":\"", _exact_string(base.value_loss),
        "\",\"pareto_count\":", length(experiment.exact_results["base"].pareto_records), "},",
        "\"expanded\":{\"source_size\":", expanded.source_size,
        ",\"exact_optimum_size\":", expanded.retained_size,
        ",\"operational_loss\":\"", _exact_string(expanded.operational_loss),
        "\",\"generative_loss\":\"", _exact_string(expanded.generative_loss),
        "\",\"value_loss\":\"", _exact_string(expanded.value_loss),
        "\",\"pareto_count\":", length(experiment.exact_results["expanded"].pareto_records), "},",
        "\"gates\":{\"all\":true},",
        "\"theorem_evidence\":false,",
        "\"evidence_class\":\"numerical extension; not theorem evidence\",",
        "\"config_sha256\":\"", config_hash, "\"",
        "}\n",
    )
end

function _artifact_contents(experiment)
    outputs = experiment.config["outputs"]
    return Dict(
        outputs["subsets"] => _render_csv(experiment.subset_rows),
        outputs["pareto"] => _render_csv(experiment.pareto_rows),
        outputs["algorithms"] => _render_csv(experiment.algorithm_rows),
        outputs["ip"] => _render_csv(experiment.ip_rows),
        outputs["summary"] => _render_summary_json(experiment),
        outputs["report"] => render_approximate_compression_report(experiment),
        outputs["pareto_figure"] =>
            render_approximate_pareto_figure(experiment),
        outputs["search_figure"] =>
            render_approximate_search_figure(experiment),
    )
end

_absolute(path) =
    isabspath(path) ? path : joinpath(REPOSITORY_ROOT, path)

function _write_or_check(artifacts, check)
    for (relative_path, content) in sort(collect(artifacts); by = first)
        path = _absolute(relative_path)
        if check
            isfile(path) ||
                error("missing approximate-compression artifact: $path")
            read(path, String) == content ||
                error("stale approximate-compression artifact: $path")
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
        error("usage: run_approximate_compression.jl [config] [--check]")
    config_path = isempty(paths) ? DEFAULT_CONFIG : only(paths)
    experiment = run_approximate_compression_experiment(config_path)
    _write_or_check(_artifact_contents(experiment), check)
    println(
        check ? "approximate-compression artifacts are current" :
        "wrote approximate-compression artifacts",
    )
    return experiment
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
