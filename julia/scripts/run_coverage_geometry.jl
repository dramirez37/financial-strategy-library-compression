module CoverageGeometryExperiments

using StrategyInnovation

export bernstein_coverage_fixture,
    delayed_coverage_fixture,
    destructive_single_gap_fixture,
    main,
    run_coverage_geometry,
    write_coverage_outputs

const EXPERIMENT_ID = "coverage-potential-geometry-v1"
const BLUE = "#2563A6"
const ORANGE = "#D97706"
const GREEN = "#3A7D5D"
const CHARCOAL = "#25313C"
const MUTED = "#6B7785"
const GRID = "#DDE3E8"
const BACKGROUND = "#FBFCFD"

function delayed_coverage_fixture()
    space = FiniteBeliefSpace([:initial, :future])
    kernel = MarkovKernel(space, [0 1; 0 1])
    gap = ExactRational[0, 2]
    occupation = finite_discounted_occupation(kernel, 1 // 2, 2)
    potential = finite_coverage_potential(kernel, gap, 1 // 2, 2)
    return (
        id = "LEAN-S4-DELAYED-COVERAGE",
        space = space,
        kernel = kernel,
        gap = gap,
        occupation = occupation,
        potential = potential,
        independent_check = occupation == ExactRational[1 1 // 2; 0 3 // 2] &&
                            potential == ExactRational[1, 3],
    )
end

function destructive_single_gap_fixture()
    space = FiniteBeliefSpace([:left, :middle, :right])
    kernel = MarkovKernel(space, [0 1 0; 1 0 0; 0 1 0])
    gap = ExactRational[0, 1, 0]
    potential = gross_coverage_value(kernel, gap, 1)
    region = research_region(potential, 1 // 2)
    return (
        id = "LEAN-S5-DESTRUCTIVE-KERNEL",
        space = space,
        kernel = kernel,
        gap = gap,
        potential = potential,
        region = region,
        independent_check = potential == ExactRational[1, 0, 1] &&
                            region == Bool[true, false, true] &&
                            !is_stochastically_monotone(kernel),
    )
end

function bernstein_coverage_fixture()
    space = FiniteBeliefSpace(collect(0:4))
    kernel = MarkovKernel(
        space,
        [
            1 0 0 0 0
            81 // 256 108 // 256 54 // 256 12 // 256 1 // 256
            1 // 16 4 // 16 6 // 16 4 // 16 1 // 16
            1 // 256 12 // 256 54 // 256 108 // 256 81 // 256
            0 0 0 0 1
        ],
    )
    left_gap = ExactRational[4, 0, 0, 0, 0]
    right_gap = ExactRational[0, 0, 0, 0, 4]
    gap = left_gap + right_gap
    potential = gross_coverage_value(kernel, gap, 1)
    region = research_region(potential, 1; strict = true)
    return (
        id = "LEAN-C2-MULTIGAP",
        space = space,
        kernel = kernel,
        left_gap = left_gap,
        right_gap = right_gap,
        gap = gap,
        potential = potential,
        cost = one(ExactRational),
        region = region,
        components = component_count(region),
        independent_check = potential == ExactRational[4, 41 // 32, 1 // 2, 41 // 32, 4] &&
                            region == Bool[true, true, false, true, true],
    )
end

function _gaussian_kernel(space, coordinates; precision::Float64, persistence::Float64)
    precision > 0 || throw(ArgumentError("signal scale must be positive"))
    0 <= persistence <= 1 || throw(ArgumentError("persistence must lie in [0, 1]"))
    count = length(space)
    transition = Matrix{Float64}(undef, count, count)
    for row in 1:count
        center = persistence * coordinates[row] + (1 - persistence) * 0.5
        weights = [exp(-0.5 * ((coordinate - center) / precision)^2) for coordinate in coordinates]
        transition[row, :] .= weights ./ sum(weights)
    end
    return MarkovKernel(space, transition; mode = Float64Mode(), atol = 5e-14)
end

function _smooth_geometry(; grid_size::Int = 121)
    grid_size >= 5 || throw(ArgumentError("coverage geometry requires at least five grid points"))
    coordinates = collect(range(0.0, 1.0; length = grid_size))
    space = FiniteBeliefSpace(collect(1:grid_size))
    grid = OrderedBeliefGrid(space, coordinates)
    kernel = _gaussian_kernel(space, coordinates; precision = 0.075, persistence = 0.88)
    frontier_values = @. 0.18 + 0.54 * coordinates + 0.06 * sinpi(coordinates)
    raw_advantage = @. 0.82 * exp(-0.5 * ((coordinates - 0.68) / 0.17)^2) - 0.10
    candidate_values = frontier_values + raw_advantage
    frontier_profile = OperationalProfile(space, frontier_values; mode = Float64Mode())
    candidate_profile = OperationalProfile(space, candidate_values; mode = Float64Mode())
    gap_profile = candidate_gap(candidate_profile, frontier_profile)
    gap = collect(gap_profile.values)
    discount = 0.86
    survival = 0.90
    delay = 0
    occupation = discounted_occupation_matrix(kernel, discount; survival)
    potential = delayed_lifetime_coverage_potential(
        kernel,
        gap,
        discount;
        survival,
        delay,
    )
    cost = 0.72
    region = research_region(potential, cost)
    diagnostics = boundary_transversality(grid, potential, cost; slope_tolerance = 1e-6)
    initial_index = argmin(abs.(coordinates .- 0.25))
    occupation_weights = occupation[initial_index, :]
    occupation_share = occupation_weights ./ sum(occupation_weights)
    return (
        grid = grid,
        coordinates = coordinates,
        space = space,
        kernel = kernel,
        frontier = frontier_values,
        candidate = candidate_values,
        gap = gap,
        discount = discount,
        survival = survival,
        delay = delay,
        occupation = occupation,
        potential = potential,
        cost = cost,
        region = region,
        components = connected_components(region),
        threshold = extract_threshold(grid, region),
        diagnostics = diagnostics,
        initial_index = initial_index,
        occupation_weights = occupation_weights,
        occupation_share = occupation_share,
    )
end

function _sensitivity_rows(model)
    coarse_kernel = _gaussian_kernel(
        model.space,
        model.coordinates;
        precision = 0.13,
        persistence = 0.88,
    )
    precise_kernel = _gaussian_kernel(
        model.space,
        model.coordinates;
        precision = 0.045,
        persistence = 0.88,
    )
    return coverage_sensitivity(
        model.grid,
        model.kernel,
        model.gap,
        model.cost;
        discount = model.discount,
        survival = model.survival,
        delay = model.delay,
        costs = (0.55, 0.72, 0.90),
        discounts = (0.72, 0.86, 0.94),
        persistences = (0.0, 0.5, 0.9),
        delays = (0, 1, 3),
        survivals = (0.65, 0.80, 0.95),
        signal_kernels = (
            "coarse" => coarse_kernel,
            "baseline" => model.kernel,
            "precise" => precise_kernel,
        ),
    )
end

function run_coverage_geometry(; grid_size::Int = 121)
    delayed = delayed_coverage_fixture()
    destructive = destructive_single_gap_fixture()
    disconnected = bernstein_coverage_fixture()
    model = _smooth_geometry(; grid_size)
    sensitivity = _sensitivity_rows(model)
    return (
        experiment_id = EXPERIMENT_ID,
        arithmetic = (
            theorem_fixtures = "Rational{BigInt}",
            geometry = "Float64",
        ),
        randomness = "none",
        delayed = delayed,
        destructive = destructive,
        disconnected = disconnected,
        model = model,
        sensitivity = sensitivity,
        checks = (
            exact_fixtures = delayed.independent_check &&
                             destructive.independent_check &&
                             disconnected.independent_check,
            baseline_component_count = component_count(model.region),
            baseline_boundary_count = length(model.diagnostics),
            baseline_transverse = all(diagnostic -> diagnostic.transverse, model.diagnostics),
            disconnected_component_count = disconnected.components,
        ),
    )
end

_csv(value::Bool) = value ? "true" : "false"
_csv(value::Rational) = "$(numerator(value))//$(denominator(value))"
_csv(value::Nothing) = ""
_csv(value) = string(value)

function _write_csv(path, header, rows)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, join(header, ","))
        for row in rows
            println(io, join((_csv(value) for value in row), ","))
        end
    end
    return path
end

function _json_escape(value::AbstractString)
    return replace(value, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n")
end

function _write_json(io::IO, value, indent::Int = 0)
    padding = " "^indent
    child_padding = " "^(indent + 2)
    if value isa NamedTuple
        _write_json(io, Dict(string(key) => getproperty(value, key) for key in keys(value)), indent)
    elseif value isa AbstractDict
        keys_sorted = sort!(collect(keys(value)); by = string)
        print(io, "{")
        isempty(keys_sorted) || print(io, "\n")
        for (index, key) in enumerate(keys_sorted)
            print(io, child_padding, "\"", _json_escape(string(key)), "\": ")
            _write_json(io, value[key], indent + 2)
            index == length(keys_sorted) || print(io, ",")
            print(io, "\n")
        end
        isempty(keys_sorted) || print(io, padding)
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
    elseif value isa Rational
        print(io, "\"", _csv(value), "\"")
    elseif value isa AbstractString || value isa Symbol
        print(io, "\"", _json_escape(string(value)), "\"")
    elseif value isa Bool
        print(io, value ? "true" : "false")
    elseif value isa Nothing
        print(io, "null")
    elseif value isa Real
        isfinite(value) || throw(ArgumentError("JSON output cannot encode nonfinite values"))
        print(io, value)
    else
        throw(ArgumentError("unsupported JSON output type $(typeof(value))"))
    end
end

function _xml_escape(value)
    return replace(
        string(value),
        "&" => "&amp;",
        "<" => "&lt;",
        ">" => "&gt;",
        "\"" => "&quot;",
    )
end

function _polyline_path(x, y, map_x, map_y)
    isempty(x) && return ""
    return join(
        (
            (index == firstindex(x) ? "M" : "L") *
            string(round(map_x(x[index]); digits = 3)) * " " *
            string(round(map_y(y[index]); digits = 3)) for index in eachindex(x)
        ),
        " ",
    )
end

function _area_path(x, upper, lower, map_x, map_y)
    forward = [
        string(round(map_x(x[index]); digits = 3), ",", round(map_y(upper[index]); digits = 3))
        for index in eachindex(x)
    ]
    reverse_lower = [
        string(round(map_x(x[index]); digits = 3), ",", round(map_y(lower[index]); digits = 3))
        for index in reverse(eachindex(x))
    ]
    return join(vcat(forward, reverse_lower), " ")
end

function _line_figure(
    path;
    title,
    subtitle,
    x,
    series,
    x_label = "Belief coordinate",
    y_label = "Value",
    bands = (),
    region = nothing,
    zero_line = false,
    description = "",
)
    width, height = 960, 600
    left, right, top, bottom = 92.0, 34.0, 96.0, 74.0
    plot_width = width - left - right
    plot_height = height - top - bottom
    all_y = Float64[]
    for item in series
        append!(all_y, Float64.(item.values))
    end
    for band in bands
        append!(all_y, Float64.(band.upper))
        append!(all_y, Float64.(band.lower))
    end
    zero_line && push!(all_y, 0.0)
    y_min, y_max = extrema(all_y)
    padding = iszero(y_max - y_min) ? 1.0 : 0.08 * (y_max - y_min)
    y_min -= padding
    y_max += padding
    x_min, x_max = extrema(x)
    map_x(value) = left + (Float64(value) - x_min) / (x_max - x_min) * plot_width
    map_y(value) = top + (y_max - Float64(value)) / (y_max - y_min) * plot_height
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\" viewBox=\"0 0 $width $height\" role=\"img\">")
        println(io, "<title>$(_xml_escape(title))</title>")
        println(io, "<desc>$(_xml_escape(description))</desc>")
        println(io, "<rect width=\"$width\" height=\"$height\" fill=\"$BACKGROUND\"/>")
        println(io, "<text x=\"$left\" y=\"35\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"24\" font-weight=\"600\">$(_xml_escape(title))</text>")
        println(io, "<text x=\"$left\" y=\"61\" fill=\"$MUTED\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"14\">$(_xml_escape(subtitle))</text>")
        if region !== nothing
            for component in connected_components(region)
                first_x = component.start == firstindex(x) ? x_min : (x[component.start - 1] + x[component.start]) / 2
                last_x = component.stop == lastindex(x) ? x_max : (x[component.stop] + x[component.stop + 1]) / 2
                rx = map_x(first_x)
                rw = map_x(last_x) - rx
                println(io, "<rect x=\"$rx\" y=\"$top\" width=\"$rw\" height=\"$plot_height\" fill=\"$BLUE\" opacity=\"0.07\"/>")
            end
        end
        for tick in 0:5
            fraction = tick / 5
            y_position = top + fraction * plot_height
            value = y_max - fraction * (y_max - y_min)
            println(io, "<line x1=\"$left\" y1=\"$y_position\" x2=\"$(left + plot_width)\" y2=\"$y_position\" stroke=\"$GRID\" stroke-width=\"1\"/>")
            println(io, "<text x=\"$(left - 12)\" y=\"$(y_position + 5)\" text-anchor=\"end\" fill=\"$MUTED\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\">$(round(value; digits = 2))</text>")
        end
        for tick in 0:5
            fraction = tick / 5
            x_position = left + fraction * plot_width
            value = x_min + fraction * (x_max - x_min)
            println(io, "<line x1=\"$x_position\" y1=\"$top\" x2=\"$x_position\" y2=\"$(top + plot_height)\" stroke=\"$GRID\" stroke-width=\"1\"/>")
            println(io, "<text x=\"$x_position\" y=\"$(top + plot_height + 25)\" text-anchor=\"middle\" fill=\"$MUTED\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"12\">$(round(value; digits = 2))</text>")
        end
        for band in bands
            points = _area_path(x, band.upper, band.lower, map_x, map_y)
            println(io, "<polygon points=\"$points\" fill=\"$(band.color)\" opacity=\"$(band.opacity)\"/>")
        end
        if zero_line && y_min <= 0 <= y_max
            zero_y = map_y(0)
            println(io, "<line x1=\"$left\" y1=\"$zero_y\" x2=\"$(left + plot_width)\" y2=\"$zero_y\" stroke=\"$CHARCOAL\" stroke-width=\"1.2\" stroke-dasharray=\"5 5\"/>")
        end
        for item in series
            path_data = _polyline_path(x, item.values, map_x, map_y)
            dash = hasproperty(item, :dash) ? " stroke-dasharray=\"$(item.dash)\"" : ""
            println(io, "<path d=\"$path_data\" fill=\"none\" stroke=\"$(item.color)\" stroke-width=\"$(get(item, :width, 2.6))\"$dash stroke-linecap=\"round\" stroke-linejoin=\"round\"/>")
        end
        legend_x = left + 18
        for (index, item) in enumerate(series)
            legend_y = top + 22 + 24 * (index - 1)
            dash = hasproperty(item, :dash) ? " stroke-dasharray=\"$(item.dash)\"" : ""
            println(io, "<line x1=\"$legend_x\" y1=\"$legend_y\" x2=\"$(legend_x + 30)\" y2=\"$legend_y\" stroke=\"$(item.color)\" stroke-width=\"3\"$dash/>")
            println(io, "<text x=\"$(legend_x + 39)\" y=\"$(legend_y + 5)\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"13\">$(_xml_escape(item.label))</text>")
        end
        println(io, "<text x=\"$(left + plot_width / 2)\" y=\"$(height - 20)\" text-anchor=\"middle\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"14\">$(_xml_escape(x_label))</text>")
        println(io, "<text x=\"22\" y=\"$(top + plot_height / 2)\" text-anchor=\"middle\" transform=\"rotate(-90 22 $(top + plot_height / 2))\" fill=\"$CHARCOAL\" font-family=\"Helvetica,Arial,sans-serif\" font-size=\"14\">$(_xml_escape(y_label))</text>")
        println(io, "</svg>")
    end
    return path
end

function _write_data_tables(result, output_dir)
    model = result.model
    paths = Dict{String,String}()
    paths["frontier_gap"] = _write_csv(
        joinpath(output_dir, "coverage_frontier_gap.csv"),
        ("belief_index", "coordinate", "frontier", "candidate", "certified_gap"),
        ((index, model.coordinates[index], model.frontier[index], model.candidate[index], model.gap[index]) for index in eachindex(model.coordinates)),
    )
    paths["occupation"] = _write_csv(
        joinpath(output_dir, "coverage_occupation_distribution.csv"),
        ("initial_index", "initial_coordinate", "future_index", "future_coordinate", "discounted_weight", "normalized_share"),
        ((model.initial_index, model.coordinates[model.initial_index], index, model.coordinates[index], model.occupation_weights[index], model.occupation_share[index]) for index in eachindex(model.coordinates)),
    )
    paths["potential"] = _write_csv(
        joinpath(output_dir, "coverage_potential.csv"),
        ("belief_index", "coordinate", "gap", "potential", "cost", "net_value", "research_region", "component"),
        ((index, model.coordinates[index], model.gap[index], model.potential[index], model.cost, model.potential[index] - model.cost, model.region[index], something(findfirst(component -> index in component, model.components), 0)) for index in eachindex(model.coordinates)),
    )
    boundary_locations = [diagnostic.location for diagnostic in model.diagnostics]
    mesh = length(model.coordinates) > 1 ? model.coordinates[2] - model.coordinates[1] : 0.0
    paths["boundaries"] = _write_csv(
        joinpath(output_dir, "coverage_research_boundaries.csv"),
        ("belief_index", "coordinate", "potential", "cost", "net_value", "research_region", "near_boundary"),
        ((index, model.coordinates[index], model.potential[index], model.cost, model.potential[index] - model.cost, model.region[index], any(abs(model.coordinates[index] - location) <= mesh for location in boundary_locations)) for index in eachindex(model.coordinates)),
    )
    disconnected = result.disconnected
    connected_net_scale = maximum(abs, model.potential .- model.cost)
    disconnected_net = Float64.(disconnected.potential .- disconnected.cost)
    disconnected_net_scale = maximum(abs, disconnected_net)
    paths["topology"] = _write_csv(
        joinpath(output_dir, "coverage_connected_disconnected.csv"),
        ("scenario", "belief_index", "coordinate", "normalized_net_value", "research_region", "component_count"),
        Iterators.flatten((
            (("connected", index, model.coordinates[index], (model.potential[index] - model.cost) / connected_net_scale, model.region[index], component_count(model.region)) for index in eachindex(model.coordinates)),
            (("disconnected_lean_c2", index, (index - 1) / 4, disconnected_net[index] / disconnected_net_scale, disconnected.region[index], disconnected.components) for index in eachindex(disconnected.region)),
        )),
    )
    paths["sensitivity"] = _write_csv(
        joinpath(output_dir, "coverage_sensitivity.csv"),
        ("parameter", "label", "parameter_value", "belief_index", "coordinate", "potential", "research_region", "component_count", "threshold_kind", "cutoff_coordinate"),
        ((row.parameter, row.label, row.parameter_value, index, model.coordinates[index], row.potential[index], row.region[index], row.component_count, row.threshold_kind, row.cutoff_coordinate) for row in result.sensitivity for index in eachindex(model.coordinates)),
    )
    return paths
end

function _write_figures(result, figure_dir)
    model = result.model
    mkpath(figure_dir)
    figures = Dict{String,String}()
    figures["frontier_gap"] = _line_figure(
        joinpath(figure_dir, "coverage_frontier_candidate_gap.svg");
        title = "Current frontier and candidate advantage",
        subtitle = "The certified gap retains only positive candidate improvements",
        x = model.coordinates,
        series = (
            (label = "Current frontier", values = model.frontier, color = BLUE, width = 2.8),
            (label = "Candidate profile", values = model.candidate, color = ORANGE, width = 2.8),
        ),
        bands = ((upper = max.(model.candidate, model.frontier), lower = model.frontier, color = ORANGE, opacity = 0.14),),
        y_label = "Operational payoff",
        description = "Current frontier, candidate profile, and shaded certified positive gap. Data: coverage_frontier_gap.csv.",
    )
    figures["occupation"] = _line_figure(
        joinpath(figure_dir, "coverage_discounted_occupation.svg");
        title = "Discounted occupation distribution",
        subtitle = "Normalized row of Uβs from initial belief coordinate $(round(model.coordinates[model.initial_index]; digits = 2))",
        x = model.coordinates,
        series = ((label = "Occupation share", values = model.occupation_share, color = BLUE, width = 2.8),),
        bands = ((upper = model.occupation_share, lower = zeros(length(model.occupation_share)), color = BLUE, opacity = 0.12),),
        y_label = "Normalized discounted share",
        description = "Discounted future-belief occupation distribution. Data: coverage_occupation_distribution.csv.",
    )
    figures["potential"] = _line_figure(
        joinpath(figure_dir, "coverage_potential.svg");
        title = "Coverage potential and research cost",
        subtitle = "Discounted, survival-adjusted value after the completion lag",
        x = model.coordinates,
        series = (
            (label = "Coverage potential", values = model.potential, color = BLUE, width = 2.8),
            (label = "Research cost", values = fill(model.cost, length(model.coordinates)), color = ORANGE, width = 2.2, dash = "7 5"),
        ),
        region = model.region,
        y_label = "Present value",
        description = "Coverage potential, cost, and shaded research region. Data: coverage_potential.csv.",
    )
    net = model.potential .- model.cost
    figures["boundaries"] = _line_figure(
        joinpath(figure_dir, "coverage_research_region_boundaries.svg");
        title = "Research-region boundary diagnostics",
        subtitle = "A nonzero local slope identifies a transverse boundary",
        x = model.coordinates,
        series = ((label = "Potential minus cost", values = net, color = BLUE, width = 2.8),),
        region = model.region,
        zero_line = true,
        y_label = "Net research value",
        description = "Potential-cost crossings and research-region shading. Data: coverage_research_boundaries.csv.",
    )
    disconnected = result.disconnected
    connected_net = net ./ maximum(abs, net)
    disconnected_net = Float64.(disconnected.potential .- disconnected.cost)
    disconnected_net ./= maximum(abs, disconnected_net)
    interpolated_disconnected = [
        begin
            position = coordinate * 4 + 1
            left = clamp(floor(Int, position), 1, 5)
            right = clamp(ceil(Int, position), 1, 5)
            left == right ? disconnected_net[left] :
            disconnected_net[left] + (position - left) * (disconnected_net[right] - disconnected_net[left])
        end for coordinate in model.coordinates
    ]
    figures["topology"] = _line_figure(
        joinpath(figure_dir, "coverage_connected_disconnected.svg");
        title = "Connected and disconnected research geometry",
        subtitle = "The Lean C2 multi-gap fixture has two strict positive components",
        x = model.coordinates,
        series = (
            (label = "Connected smooth case", values = connected_net, color = BLUE, width = 2.8),
            (label = "Disconnected Lean C2 case", values = interpolated_disconnected, color = ORANGE, width = 2.8, dash = "8 5"),
        ),
        zero_line = true,
        y_label = "Normalized potential minus cost",
        description = "Connected smooth research region compared with the exact disconnected C2 fixture. Data: coverage_connected_disconnected.csv.",
    )
    return figures
end

function write_coverage_outputs(
    result;
    output_dir,
    figure_dir,
)
    data_paths = _write_data_tables(result, output_dir)
    figure_paths = _write_figures(result, figure_dir)
    model = result.model
    diagnostics = [
        Dict(
            "kind" => diagnostic.kind,
            "left_index" => diagnostic.left_index,
            "right_index" => diagnostic.right_index,
            "location" => diagnostic.location,
            "slope" => diagnostic.slope,
            "transverse" => diagnostic.transverse,
        ) for diagnostic in model.diagnostics
    ]
    summary = Dict(
        "schema_version" => EXPERIMENT_ID,
        "experiment_id" => EXPERIMENT_ID,
        "julia_version" => string(VERSION),
        "randomness" => result.randomness,
        "arithmetic" => result.arithmetic,
        "parameters" => Dict(
            "grid_size" => length(model.grid),
            "discount" => model.discount,
            "candidate_survival" => model.survival,
            "research_delay" => model.delay,
            "cost" => model.cost,
        ),
        "baseline" => Dict(
            "component_count" => component_count(model.region),
            "threshold_kind" => model.threshold.kind,
            "cutoff_coordinate" => model.threshold.cutoff_coordinate,
            "boundary_diagnostics" => diagnostics,
        ),
        "exact_fixtures" => Dict(
            "delayed_coverage" => Dict(
                "potential" => result.delayed.potential,
                "passed" => result.delayed.independent_check,
            ),
            "destructive_single_gap" => Dict(
                "potential" => result.destructive.potential,
                "region" => result.destructive.region,
                "passed" => result.destructive.independent_check,
            ),
            "disconnected_multi_gap" => Dict(
                "potential" => result.disconnected.potential,
                "region" => result.disconnected.region,
                "components" => result.disconnected.components,
                "passed" => result.disconnected.independent_check,
            ),
        ),
        "sensitivity_scenarios" => length(result.sensitivity),
        "checks" => result.checks,
        "data_files" => Dict(key => basename(value) for (key, value) in data_paths),
        "figure_files" => Dict(key => basename(value) for (key, value) in figure_paths),
    )
    summary_path = joinpath(output_dir, "coverage_geometry_summary.json")
    open(summary_path, "w") do io
        _write_json(io, summary)
        println(io)
    end
    return (
        summary = summary_path,
        data = data_paths,
        figures = figure_paths,
    )
end

function main()
    repository_root = normpath(joinpath(@__DIR__, "..", ".."))
    result = run_coverage_geometry()
    outputs = write_coverage_outputs(
        result;
        output_dir = joinpath(repository_root, "experiments", "results", "summaries"),
        figure_dir = joinpath(repository_root, "manuscript", "figures"),
    )
    println("experiment=$(result.experiment_id)")
    println("exact_fixtures=$(result.checks.exact_fixtures)")
    println("baseline_components=$(result.checks.baseline_component_count)")
    println("disconnected_components=$(result.checks.disconnected_component_count)")
    println("summary=$(outputs.summary)")
    return outputs
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
