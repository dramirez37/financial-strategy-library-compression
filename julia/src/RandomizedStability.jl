using Printf: @sprintf

"""
    RandomizedStabilityDiagnostics

Exact cumulative and factor-stratified simulation-precision summaries for a
fixed randomized-library run. Decimal Wilson intervals, Monte Carlo standard
errors, and SVG coordinates are presentation diagnostics only.
"""
struct RandomizedStabilityDiagnostics
    prefixes::Vector{Int}
    cumulative_rows::Vector{NamedTuple}
    factor_rows::Vector{NamedTuple}
    warnings::Vector{String}
end

const RANDOMIZED_STABILITY_ESTIMANDS = (
    :frontier_positive_loss_frequency,
    :mean_positive_frontier_loss,
    :innovation_safe_loss_frequency,
    :silent_generative_asset_frequency,
    :substitution_frequency,
    :complementarity_frequency,
    :frontier_only_mean_compression_ratio,
    :innovation_safe_mean_compression_ratio,
)

const RANDOMIZED_STABILITY_INPUT_FIELDS = (
    :trial_id,
    :frontier_only_signed_total_dynamic_loss,
    :innovation_safe_signed_total_dynamic_loss,
    :silent_generative_asset_count,
    :active_asset_count,
    :frontier_closure_J,
    :frontier_only_compression_ratio,
    :innovation_safe_compression_ratio,
)

_stability_exact(value::Rational) = exact_rational(value)
_stability_exact(value) = throw(
    ArgumentError(
        "randomized stability theorem-facing input must be an exact Rational, got $(typeof(value))",
    ),
)

function _stability_require_fields(rows, factor_levels)
    factors = Tuple(Symbol(name) for name in keys(factor_levels))
    required = (RANDOMIZED_STABILITY_INPUT_FIELDS..., factors...)
    for (index, row) in enumerate(rows)
        for field in required
            hasproperty(row, field) || throw(
                ArgumentError(
                    "randomized stability row $index is missing field $field",
                ),
            )
        end
        Int(getproperty(row, :trial_id)) == index || throw(
            ArgumentError(
                "randomized stability rows must be ordered by consecutive trial_id",
            ),
        )
        frontier_loss = _stability_exact(
            getproperty(row, :frontier_only_signed_total_dynamic_loss),
        )
        safe_loss = _stability_exact(
            getproperty(row, :innovation_safe_signed_total_dynamic_loss),
        )
        interaction =
            _stability_exact(getproperty(row, :frontier_closure_J))
        frontier_ratio = _stability_exact(
            getproperty(row, :frontier_only_compression_ratio),
        )
        safe_ratio = _stability_exact(
            getproperty(row, :innovation_safe_compression_ratio),
        )
        silent = Int(getproperty(row, :silent_generative_asset_count))
        assets = Int(getproperty(row, :active_asset_count))
        0 <= silent <= assets || throw(
            ArgumentError(
                "silent-generative count must lie between zero and the active-asset count",
            ),
        )
        assets >= 1 || throw(
            ArgumentError("every stability row must have an active asset"),
        )
        0 <= frontier_ratio <= 1 || throw(
            ArgumentError("frontier-only compression ratio must lie in [0,1]"),
        )
        0 <= safe_ratio <= 1 || throw(
            ArgumentError("innovation-safe compression ratio must lie in [0,1]"),
        )
        for factor in factors
            registered_levels =
                string.(getproperty(factor_levels, factor))
            string(getproperty(row, factor)) in registered_levels || throw(
                ArgumentError(
                    "randomized stability row $index has an unregistered " *
                    "$factor level",
                ),
            )
        end
        frontier_loss
        safe_loss
        interaction
    end
    return true
end

function _wilson_interval(events::Int, observations::Int, z::Float64)
    observations > 0 || return (nothing, nothing)
    0 <= events <= observations || throw(
        ArgumentError("binomial event count is outside its denominator"),
    )
    probability = events / observations
    denominator = 1 + z^2 / observations
    center =
        (probability + z^2 / (2observations)) / denominator
    radius =
        z / denominator * sqrt(
            probability * (1 - probability) / observations +
            z^2 / (4observations^2),
        )
    return (max(0.0, center - radius), min(1.0, center + radius))
end

function _mean_precision(values)
    count_values = length(values)
    count_values >= 2 || return (nothing, nothing)
    exact_values = _stability_exact.(values)
    mean_value =
        sum(exact_values; init = exact_rational(0)) /
        exact_rational(count_values)
    sample_variance =
        sum(
            (value - mean_value)^2 for value in exact_values;
            init = exact_rational(0),
        ) / exact_rational(count_values - 1)
    mcse = sqrt(Float64(sample_variance) / count_values)
    return (sample_variance, mcse)
end

function _warning_codes(
    event_count::Int,
    observation_count::Int;
    sparse_event_threshold::Int,
)
    observation_count == 0 && return ["empty_denominator"]
    codes = String[]
    event_count < sparse_event_threshold && push!(codes, "sparse_events")
    observation_count - event_count < sparse_event_threshold &&
        push!(codes, "sparse_nonevents")
    return codes
end

function _frequency_row(
    prefix_n,
    scope,
    factor,
    level,
    estimand,
    event_count,
    observation_count;
    sparse_event_threshold,
    confidence_z,
)
    warning_codes = _warning_codes(
        event_count,
        observation_count;
        sparse_event_threshold,
    )
    estimate =
        observation_count == 0 ? nothing :
        exact_rational(event_count) / exact_rational(observation_count)
    interval_low, interval_high =
        _wilson_interval(event_count, observation_count, confidence_z)
    return (
        prefix_n = Int(prefix_n),
        scope = String(scope),
        factor = String(factor),
        level = String(level),
        estimand = String(estimand),
        statistic_kind = "frequency",
        event_count = Int(event_count),
        non_event_count = Int(observation_count - event_count),
        observation_count = Int(observation_count),
        exact_sum = exact_rational(event_count),
        estimate,
        exact_sample_variance = nothing,
        interval_kind = "Wilson descriptive simulation interval",
        interval_low,
        interval_high,
        mcse = nothing,
        warning_code = join(warning_codes, ";"),
        warning = isempty(warning_codes) ? "" :
                  "event or nonevent support is below the registered sparse-count threshold",
        simulation_precision_only = true,
    )
end

function _mean_row(
    prefix_n,
    scope,
    factor,
    level,
    estimand,
    values;
    event_count,
    total_trial_count,
    minimum_count,
)
    exact_values = _stability_exact.(values)
    exact_sum =
        sum(exact_values; init = exact_rational(0))
    observation_count = length(exact_values)
    estimate =
        observation_count == 0 ? nothing :
        exact_sum / exact_rational(observation_count)
    exact_sample_variance, mcse = _mean_precision(exact_values)
    warning_codes = String[]
    observation_count == 0 &&
        push!(warning_codes, "undefined_empty_mean")
    observation_count < minimum_count &&
        push!(warning_codes, "sparse_mean_support")
    return (
        prefix_n = Int(prefix_n),
        scope = String(scope),
        factor = String(factor),
        level = String(level),
        estimand = String(estimand),
        statistic_kind = "mean",
        event_count = Int(event_count),
        non_event_count = Int(total_trial_count - event_count),
        observation_count = Int(observation_count),
        exact_sum,
        estimate,
        exact_sample_variance,
        interval_kind = "",
        interval_low = nothing,
        interval_high = nothing,
        mcse,
        warning_code = join(warning_codes, ";"),
        warning = isempty(warning_codes) ? "" :
                  "mean support is below the registered Monte Carlo precision threshold",
        simulation_precision_only = true,
    )
end

function _stability_metric_rows(
    rows,
    prefix_n,
    scope,
    factor,
    level;
    sparse_event_threshold,
    conditional_mean_minimum,
    confidence_z,
)
    trial_count = length(rows)
    frontier_losses = _stability_exact.(
        getproperty.(rows, :frontier_only_signed_total_dynamic_loss),
    )
    safe_losses = _stability_exact.(
        getproperty.(rows, :innovation_safe_signed_total_dynamic_loss),
    )
    interactions =
        _stability_exact.(getproperty.(rows, :frontier_closure_J))
    frontier_ratios = _stability_exact.(
        getproperty.(rows, :frontier_only_compression_ratio),
    )
    safe_ratios = _stability_exact.(
        getproperty.(rows, :innovation_safe_compression_ratio),
    )
    positive_losses = filter(>(0), frontier_losses)
    frontier_event_count = length(positive_losses)
    safe_event_count = count(>(0), safe_losses)
    silent_event_count = sum(
        Int(getproperty(row, :silent_generative_asset_count)) for row in rows;
        init = 0,
    )
    active_asset_count = sum(
        Int(getproperty(row, :active_asset_count)) for row in rows;
        init = 0,
    )
    substitution_count = count(<(0), interactions)
    complementarity_count = count(>(0), interactions)

    return NamedTuple[
        _frequency_row(
            prefix_n,
            scope,
            factor,
            level,
            :frontier_positive_loss_frequency,
            frontier_event_count,
            trial_count;
            sparse_event_threshold,
            confidence_z,
        ),
        _mean_row(
            prefix_n,
            scope,
            factor,
            level,
            :mean_positive_frontier_loss,
            positive_losses;
            event_count = frontier_event_count,
            total_trial_count = trial_count,
            minimum_count = conditional_mean_minimum,
        ),
        _frequency_row(
            prefix_n,
            scope,
            factor,
            level,
            :innovation_safe_loss_frequency,
            safe_event_count,
            trial_count;
            sparse_event_threshold,
            confidence_z,
        ),
        _frequency_row(
            prefix_n,
            scope,
            factor,
            level,
            :silent_generative_asset_frequency,
            silent_event_count,
            active_asset_count;
            sparse_event_threshold,
            confidence_z,
        ),
        _frequency_row(
            prefix_n,
            scope,
            factor,
            level,
            :substitution_frequency,
            substitution_count,
            trial_count;
            sparse_event_threshold,
            confidence_z,
        ),
        _frequency_row(
            prefix_n,
            scope,
            factor,
            level,
            :complementarity_frequency,
            complementarity_count,
            trial_count;
            sparse_event_threshold,
            confidence_z,
        ),
        _mean_row(
            prefix_n,
            scope,
            factor,
            level,
            :frontier_only_mean_compression_ratio,
            frontier_ratios;
            event_count = trial_count,
            total_trial_count = trial_count,
            minimum_count = 2,
        ),
        _mean_row(
            prefix_n,
            scope,
            factor,
            level,
            :innovation_safe_mean_compression_ratio,
            safe_ratios;
            event_count = trial_count,
            total_trial_count = trial_count,
            minimum_count = 2,
        ),
    ]
end

"""
    randomized_stability_diagnostics(rows; prefixes, factor_levels, ...)

Compute exact cumulative estimates and exact factor-stratified estimates at
fixed prefixes. The maximum prefix is the fixed final sample; no result can
alter the prefix schedule or stop the run.
"""
function randomized_stability_diagnostics(
    rows::AbstractVector;
    prefixes = (50, 100, 200, 300, 500, 750, 1000, 1024),
    factor_levels = (
        frontier_density = ("sparse", "dense"),
        module_overlap = ("low", "high"),
        module_complementarity = ("weak", "strong"),
        project_cost = ("low", "high"),
        duration = ("short", "long"),
        admission = ("low", "high"),
        persistence = ("low", "high"),
    ),
    sparse_event_threshold::Integer = 20,
    conditional_mean_minimum::Integer = 40,
    confidence_z::Real = 1.959963984540054,
)
    prefix_values = Int.(collect(prefixes))
    isempty(prefix_values) &&
        throw(ArgumentError("at least one stability prefix is required"))
    issorted(prefix_values) ||
        throw(ArgumentError("stability prefixes must be sorted"))
    length(unique(prefix_values)) == length(prefix_values) ||
        throw(ArgumentError("stability prefixes must be unique"))
    first(prefix_values) >= 1 ||
        throw(ArgumentError("stability prefixes must be positive"))
    last(prefix_values) == length(rows) || throw(
        ArgumentError(
            "the final stability prefix must equal the fixed registered sample size",
        ),
    )
    sparse_event_threshold >= 1 || throw(
        ArgumentError("sparse-event threshold must be positive"),
    )
    conditional_mean_minimum >= 2 || throw(
        ArgumentError("conditional-mean threshold must be at least two"),
    )
    factor_names = Tuple(Symbol(name) for name in keys(factor_levels))
    _stability_require_fields(rows, factor_levels)

    cumulative_rows = NamedTuple[]
    factor_rows = NamedTuple[]
    for prefix_n in prefix_values
        prefix_rows = rows[1:prefix_n]
        append!(
            cumulative_rows,
            _stability_metric_rows(
                prefix_rows,
                prefix_n,
                "cumulative",
                "",
                "";
                sparse_event_threshold = Int(sparse_event_threshold),
                conditional_mean_minimum =
                    Int(conditional_mean_minimum),
                confidence_z = Float64(confidence_z),
            ),
        )
        for factor in factor_names
            levels = getproperty(factor_levels, factor)
            length(levels) == 2 || throw(
                ArgumentError(
                    "factor $factor must have exactly two registered levels",
                ),
            )
            for level in levels
                selected = filter(
                    row -> string(getproperty(row, factor)) == string(level),
                    prefix_rows,
                )
                append!(
                    factor_rows,
                    _stability_metric_rows(
                        selected,
                        prefix_n,
                        "factor",
                        factor,
                        level;
                        sparse_event_threshold =
                            Int(sparse_event_threshold),
                        conditional_mean_minimum =
                            Int(conditional_mean_minimum),
                        confidence_z = Float64(confidence_z),
                    ),
                )
            end
        end
    end
    warnings = sort(
        unique(
            "$(row.scope):N=$(row.prefix_n):$(row.factor):$(row.level):$(row.estimand):$(row.warning_code)" for
            row in (cumulative_rows..., factor_rows...) if
            !isempty(row.warning_code)
        ),
    )
    return RandomizedStabilityDiagnostics(
        prefix_values,
        cumulative_rows,
        factor_rows,
        warnings,
    )
end

_stability_ratio_string(value::Rational) =
    "$(numerator(value))//$(denominator(value))"
_stability_csv_value(::Nothing) = ""
_stability_csv_value(value::Rational) = _stability_ratio_string(value)
_stability_csv_value(value::Float64) = @sprintf("%.12g", value)
_stability_csv_value(value::Bool) = string(value)
_stability_csv_value(value) = string(value)

function _stability_csv_escape(value)
    text = _stability_csv_value(value)
    occursin(r"[\",\n]", text) || return text
    return "\"" * replace(text, "\"" => "\"\"") * "\""
end

function render_randomized_stability_csv(rows::AbstractVector)
    fields = (
        :prefix_n,
        :scope,
        :factor,
        :level,
        :estimand,
        :statistic_kind,
        :event_count,
        :non_event_count,
        :observation_count,
        :exact_sum,
        :estimate,
        :exact_sample_variance,
        :interval_kind,
        :interval_low,
        :interval_high,
        :mcse,
        :warning_code,
        :warning,
        :simulation_precision_only,
    )
    io = IOBuffer()
    println(io, join(string.(fields), ","))
    for row in rows
        println(
            io,
            join(
                (
                    _stability_csv_escape(getproperty(row, field)) for
                    field in fields
                ),
                ",",
            ),
        )
    end
    return String(take!(io))
end

render_randomized_stability_csv(
    diagnostics::RandomizedStabilityDiagnostics,
) = render_randomized_stability_csv(diagnostics.cumulative_rows)

render_randomized_factor_stability_csv(
    diagnostics::RandomizedStabilityDiagnostics,
) = render_randomized_stability_csv(diagnostics.factor_rows)

_stability_svg_escape(text) = replace(
    string(text),
    "&" => "&amp;",
    "<" => "&lt;",
    ">" => "&gt;",
    "\"" => "&quot;",
)

function _stability_estimate(row)
    isnothing(row.estimate) ? nothing : Float64(row.estimate)
end

function _stability_panel!(
    io,
    rows,
    panel_index,
    title,
    estimands,
    labels,
    colors;
    unit_interval,
)
    column = mod(panel_index - 1, 2)
    panel_row = div(panel_index - 1, 2)
    x0 = 78 + 620column
    y0 = 118 + 360panel_row
    plot_x = x0 + 58
    plot_y = y0 + 44
    plot_width = 500
    plot_height = 235
    selected = filter(row -> row.estimand in string.(estimands), rows)
    values = Float64[]
    for row in selected
        estimate = _stability_estimate(row)
        isnothing(estimate) && continue
        push!(values, estimate)
        row.statistic_kind == "mean" && !isnothing(row.mcse) &&
            push!(values, estimate + row.mcse)
    end
    maximum_value =
        unit_interval ? 1.0 : max(maximum(values; init = 0.0), 1e-12)
    minimum_prefix = minimum(row.prefix_n for row in rows)
    maximum_prefix = maximum(row.prefix_n for row in rows)
    x_coordinate(prefix) =
        plot_x +
        plot_width * (prefix - minimum_prefix) /
        max(maximum_prefix - minimum_prefix, 1)
    y_coordinate(value) =
        plot_y + plot_height * (1 - value / maximum_value)

    println(
        io,
        """<text x="$x0" y="$y0" font-family="Helvetica,Arial,sans-serif" font-size="18" font-weight="700" fill="#172033">$(_stability_svg_escape(title))</text>""",
    )
    for tick in 0:4
        value = maximum_value * tick / 4
        y = y_coordinate(value)
        println(
            io,
            """<line x1="$plot_x" y1="$y" x2="$(plot_x + plot_width)" y2="$y" stroke="#E5E7EB" stroke-width="1"/>""",
        )
        println(
            io,
            """<text x="$(plot_x - 10)" y="$(y + 4)" text-anchor="end" font-family="Helvetica,Arial,sans-serif" font-size="11" fill="#667085">$(@sprintf("%.2f", value))</text>""",
        )
    end
    prefixes = sort(unique(row.prefix_n for row in rows))
    for prefix in prefixes
        x = x_coordinate(prefix)
        println(
            io,
            """<line x1="$x" y1="$plot_y" x2="$x" y2="$(plot_y + plot_height)" stroke="#F0F2F5" stroke-width="1"/>""",
        )
        println(
            io,
            """<text x="$x" y="$(plot_y + plot_height + 19)" text-anchor="middle" font-family="Helvetica,Arial,sans-serif" font-size="10" fill="#667085">$prefix</text>""",
        )
    end
    for (series_index, estimand) in enumerate(estimands)
        series = sort(
            filter(row -> row.estimand == string(estimand), rows);
            by = row -> row.prefix_n,
        )
        points = [
            (
                row,
                x_coordinate(row.prefix_n),
                y_coordinate(_stability_estimate(row)),
            ) for row in series if
            !isnothing(_stability_estimate(row))
        ]
        if length(points) >= 2
            println(
                io,
                """<polyline points="$(join(("$(point[2]),$(point[3])" for point in points), " "))" fill="none" stroke="$(colors[series_index])" stroke-width="3"/>""",
            )
        end
        for (row, x, y) in points
            if row.statistic_kind == "frequency" &&
               !isnothing(row.interval_low)
                low_y = y_coordinate(row.interval_low)
                high_y = y_coordinate(row.interval_high)
                println(
                    io,
                    """<line x1="$x" y1="$low_y" x2="$x" y2="$high_y" stroke="$(colors[series_index])" stroke-opacity="0.35" stroke-width="2"/>""",
                )
            elseif row.statistic_kind == "mean" && !isnothing(row.mcse)
                low_y = y_coordinate(
                    max(0.0, _stability_estimate(row) - row.mcse),
                )
                high_y = y_coordinate(
                    min(
                        maximum_value,
                        _stability_estimate(row) + row.mcse,
                    ),
                )
                println(
                    io,
                    """<line x1="$x" y1="$low_y" x2="$x" y2="$high_y" stroke="$(colors[series_index])" stroke-opacity="0.35" stroke-width="2"/>""",
                )
            end
            println(
                io,
                """<circle cx="$x" cy="$y" r="4" fill="$(colors[series_index])" stroke="#FFFFFF" stroke-width="1.5"/>""",
            )
        end
        legend_x = plot_x + 8 + 170mod(series_index - 1, 3)
        legend_y =
            plot_y + plot_height + 45 + 18div(series_index - 1, 3)
        println(
            io,
            """<line x1="$legend_x" y1="$legend_y" x2="$(legend_x + 18)" y2="$legend_y" stroke="$(colors[series_index])" stroke-width="3"/>""",
        )
        println(
            io,
            """<text x="$(legend_x + 24)" y="$(legend_y + 4)" font-family="Helvetica,Arial,sans-serif" font-size="11" fill="#344054">$(_stability_svg_escape(labels[series_index]))</text>""",
        )
    end
    return nothing
end

"""
    render_randomized_stability_svg(diagnostics)

Render four dependency-free stabilization panels. Frequency bars are
descriptive Wilson intervals; mean bars are plus/minus one Monte Carlo
standard error.
"""
function render_randomized_stability_svg(
    diagnostics::RandomizedStabilityDiagnostics,
)
    rows = diagnostics.cumulative_rows
    io = IOBuffer()
    println(
        io,
        """<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="900" viewBox="0 0 1280 900" role="img" aria-labelledby="title desc">""",
    )
    println(
        io,
        """<title id="title">Randomized-library sequential stability diagnostics</title>""",
    )
    println(
        io,
        """<desc id="desc">Cumulative exact estimates at fixed sample sizes through the registered maximum N. Intervals and Monte Carlo standard errors are simulation precision diagnostics only.</desc>""",
    )
    println(io, """<rect width="1280" height="900" fill="#FFFFFF"/>""")
    println(
        io,
        """<text x="64" y="42" font-family="Helvetica,Arial,sans-serif" font-size="27" font-weight="700" fill="#101828">Sequential stability at fixed registered prefixes</text>""",
    )
    println(
        io,
        """<text x="64" y="70" font-family="Helvetica,Arial,sans-serif" font-size="14" fill="#475467">Final N is fixed in advance; diagnostics do not stop or select the run. Bars show Wilson intervals for frequencies and ±1 MCSE for means.</text>""",
    )
    _stability_panel!(
        io,
        rows,
        1,
        "Dynamic-loss frequencies",
        (
            :frontier_positive_loss_frequency,
            :innovation_safe_loss_frequency,
        ),
        ("Frontier only", "Innovation safe"),
        ("#C44E52", "#4C78A8");
        unit_interval = true,
    )
    _stability_panel!(
        io,
        rows,
        2,
        "Conditional mean positive loss",
        (:mean_positive_frontier_loss,),
        ("Mean positive loss",),
        ("#B54708",);
        unit_interval = false,
    )
    _stability_panel!(
        io,
        rows,
        3,
        "Generative and interaction frequencies",
        (
            :silent_generative_asset_frequency,
            :substitution_frequency,
            :complementarity_frequency,
        ),
        ("Silent asset", "Substitution", "Complementarity"),
        ("#7A5AF8", "#039855", "#D92D20");
        unit_interval = true,
    )
    _stability_panel!(
        io,
        rows,
        4,
        "Mean compression ratios",
        (
            :frontier_only_mean_compression_ratio,
            :innovation_safe_mean_compression_ratio,
        ),
        ("Frontier only", "Innovation safe"),
        ("#F79009", "#1570EF");
        unit_interval = true,
    )
    println(
        io,
        """<text x="64" y="875" font-family="Helvetica,Arial,sans-serif" font-size="12" fill="#667085">Randomized finite-model simulation precision only; not inference about a real population.</text>""",
    )
    println(io, "</svg>")
    return String(take!(io))
end
