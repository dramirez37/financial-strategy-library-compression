module RandomizedLibraryStressV2

using Printf: @sprintf
using SHA: sha256
using TOML
using StrategyInnovation

include("randomized_library_v2_core.jl")
using .RandomizedLibraryV2Core

include("lock_randomized_library_design_v2.jl")
using .LockRandomizedLibraryDesignV2

include("lock_randomized_library_stability_amendment.jl")
using .LockRandomizedLibraryStabilityAmendment

include("lock_randomized_library_execution_amendment.jl")
using .LockRandomizedLibraryExecutionAmendment

export main, run_registered_experiment_v2

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "randomized_library_stress_v2.toml",
)
const STABILITY_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "randomized_library_stability_amendment_1.toml",
)
const IMPLEMENTATION_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "randomized_library_execution_amendment_2.toml",
)

_absolute(path::AbstractString) =
    isabspath(path) ? normpath(path) :
    normpath(joinpath(REPOSITORY_ROOT, path))

_ratio_string(value::Rational) =
    "$(numerator(value))//$(denominator(value))"
_csv_value(::Nothing) = ""
_csv_value(value::Rational) = _ratio_string(value)
_csv_value(value::Bool) = lowercase(string(value))
_csv_value(value::Symbol) = String(value)
_csv_value(value) = string(value)

function _csv_escape(value)
    text = _csv_value(value)
    occursin(r"[\",\n]", text) || return text
    return "\"" * replace(text, "\"" => "\"\"") * "\""
end

function _render_csv(rows::AbstractVector)
    isempty(rows) && error("cannot render an empty registered table")
    fields = propertynames(first(rows))
    all(propertynames(row) == fields for row in rows) ||
        error("registered output table has inconsistent row fields")
    io = IOBuffer()
    println(io, join(string.(fields), ","))
    for row in rows
        println(
            io,
            join(
                (
                    _csv_escape(getproperty(row, field)) for
                    field in fields
                ),
                ",",
            ),
        )
    end
    return String(take!(io))
end

_mean(values) = begin
    collected = collect(values)
    isempty(collected) && return nothing
    sum(collected; init = exact_rational(0)) /
    exact_rational(length(collected))
end

_frequency(count, denominator) =
    denominator == 0 ? nothing :
    exact_rational(count) / exact_rational(denominator)

function _method_summary(pruning_rows)
    rows = NamedTuple[]
    for method in (
        "frontier_only",
        "innovation_safe",
        "approx_operational",
        "approx_generative",
    )
        selected = filter(row -> row.method == method, pruning_rows)
        positive = filter(
            row -> row.signed_total_dynamic_loss > 0,
            selected,
        )
        push!(
            rows,
            (
                method,
                trial_count = length(selected),
                positive_loss_count = length(positive),
                positive_loss_frequency =
                    _frequency(length(positive), length(selected)),
                mean_positive_loss = _mean(
                    row.signed_total_dynamic_loss for row in positive
                ),
                mean_signed_operational_loss = _mean(
                    row.signed_operational_loss for row in selected
                ),
                mean_signed_generative_loss = _mean(
                    row.signed_generative_loss for row in selected
                ),
                mean_signed_total_dynamic_loss = _mean(
                    row.signed_total_dynamic_loss for row in selected
                ),
                maximum_signed_total_dynamic_loss = maximum(
                    row.signed_total_dynamic_loss for row in selected
                ),
                mean_retention_ratio = _mean(
                    row.retention_ratio for row in selected
                ),
                mean_compression_ratio = _mean(
                    row.compression_ratio for row in selected
                ),
                exact_decomposition_count =
                    count(row -> row.decomposition_gate, selected),
            ),
        )
    end
    return rows
end

function _factor_summary(trial_rows, pruning_rows, asset_rows)
    frontier_by_trial = Dict(
        row.trial_id => row for row in pruning_rows if
        row.method == "frontier_only"
    )
    safe_by_trial = Dict(
        row.trial_id => row for row in pruning_rows if
        row.method == "innovation_safe"
    )
    assets_by_trial = Dict(
        trial_id => filter(row -> row.trial_id == trial_id, asset_rows) for
        trial_id in getproperty.(trial_rows, :trial_id)
    )
    factors = (
        frontier_density = ("sparse", "dense"),
        module_overlap = ("low", "high"),
        module_complementarity = ("weak", "strong"),
        project_cost = ("low", "high"),
        duration = ("short", "long"),
        admission = ("low", "high"),
        persistence = ("low", "high"),
    )
    rows = NamedTuple[]
    for factor in keys(factors), level in getproperty(factors, factor)
        selected = filter(
            row -> string(getproperty(row, factor)) == level,
            trial_rows,
        )
        frontier = [
            frontier_by_trial[row.trial_id] for row in selected
        ]
        safe = [safe_by_trial[row.trial_id] for row in selected]
        assets = reduce(
            vcat,
            (
                assets_by_trial[row.trial_id] for row in selected
            );
            init = NamedTuple[],
        )
        positive = count(
            row -> row.signed_total_dynamic_loss > 0,
            frontier,
        )
        safe_positive = count(
            row -> row.signed_total_dynamic_loss > 0,
            safe,
        )
        silent = count(
            row -> row.operationally_silent_generative,
            assets,
        )
        substitution =
            count(row -> row.frontier_closure_J < 0, selected)
        complementarity =
            count(row -> row.frontier_closure_J > 0, selected)
        zero = count(
            row -> iszero(row.frontier_closure_J),
            selected,
        )
        push!(
            rows,
            (
                factor = String(factor),
                level,
                trial_count = length(selected),
                frontier_positive_loss_count = positive,
                frontier_positive_loss_frequency =
                    _frequency(positive, length(selected)),
                mean_frontier_signed_loss = _mean(
                    row.signed_total_dynamic_loss for row in frontier
                ),
                mean_frontier_compression_ratio = _mean(
                    row.compression_ratio for row in frontier
                ),
                innovation_safe_positive_loss_count =
                    safe_positive,
                innovation_safe_positive_loss_frequency =
                    _frequency(safe_positive, length(selected)),
                mean_innovation_safe_compression_ratio = _mean(
                    row.compression_ratio for row in safe
                ),
                silent_generative_asset_count = silent,
                active_asset_count = length(assets),
                silent_generative_asset_frequency =
                    _frequency(silent, length(assets)),
                substitution_count = substitution,
                complementarity_count = complementarity,
                zero_interaction_count = zero,
                substitution_frequency =
                    _frequency(substitution, length(selected)),
                complementarity_frequency =
                    _frequency(complementarity, length(selected)),
                zero_interaction_frequency =
                    _frequency(zero, length(selected)),
                primitive_predicate_count = count(
                    row -> row.computed_primitive_predicate,
                    selected,
                ),
            ),
        )
    end
    return rows
end

function _interaction_rows(trial_rows)
    rows = NamedTuple[]
    function add_scope(scope, factor, level, selected)
        denominator = length(selected)
        for (sign, predicate) in (
            ("substitution", row -> row.frontier_closure_J < 0),
            ("complementarity", row -> row.frontier_closure_J > 0),
            ("zero", row -> iszero(row.frontier_closure_J)),
        )
            count_value = count(predicate, selected)
            push!(
                rows,
                (
                    scope,
                    factor,
                    level,
                    interaction_sign = sign,
                    count = count_value,
                    denominator,
                    exact_frequency =
                        _frequency(count_value, denominator),
                    simulation_only = true,
                ),
            )
        end
    end
    add_scope("overall", "", "", trial_rows)
    for value in (false, true)
        selected = filter(
            row -> row.computed_primitive_predicate == value,
            trial_rows,
        )
        add_scope(
            "primitive_predicate",
            "computed_primitive_predicate",
            string(value),
            selected,
        )
    end
    factors = (
        :frontier_density,
        :module_overlap,
        :module_complementarity,
        :project_cost,
        :duration,
        :admission,
        :persistence,
    )
    for factor in factors
        for level in sort(
            unique(string(getproperty(row, factor)) for row in trial_rows),
        )
            selected = filter(
                row -> string(getproperty(row, factor)) == level,
                trial_rows,
            )
            add_scope("factor", String(factor), level, selected)
        end
    end
    return rows
end

function _ols_slope(xs, ys)
    x = exact_rational.(collect(xs))
    y = exact_rational.(collect(ys))
    length(x) == length(y) ||
        error("OLS inputs have inconsistent lengths")
    length(x) >= 2 || return nothing
    xbar = _mean(x)
    ybar = _mean(y)
    denominator = sum(
        (value - xbar)^2 for value in x;
        init = exact_rational(0),
    )
    iszero(denominator) && return nothing
    numerator = sum(
        (x[index] - xbar) * (y[index] - ybar) for
        index in eachindex(x);
        init = exact_rational(0),
    )
    return numerator / denominator
end

function _selected_action_map(action_rows)
    return Dict(
        (
            row.trial_id,
            row.carrier,
            row.remaining_horizon,
            row.belief,
        ) => row.action for row in action_rows if row.selected
    )
end

function _relationship_summary(
    trial_rows,
    pruning_rows,
    asset_rows,
    action_rows,
)
    frontier_by_trial = Dict(
        row.trial_id => row for row in pruning_rows if
        row.method == "frontier_only"
    )
    signed_losses = [
        frontier_by_trial[row.trial_id].signed_total_dynamic_loss for
        row in trial_rows
    ]
    positive_losses = max.(exact_rational(0), signed_losses)
    density = getproperty.(
        trial_rows,
        :realized_frontier_supplier_fraction,
    )
    uniqueness = exact_rational.(
        getproperty.(asset_rows, :unique_closure_count),
    )
    generative = getproperty.(
        asset_rows,
        :signed_generative_loss,
    )
    richness = exact_rational.(
        getproperty.(trial_rows, :source_closure_size),
    )
    quality = getproperty.(trial_rows, :descendant_quality)
    selected = _selected_action_map(action_rows)
    switch_rows = NamedTuple[]
    edge_pairs = (
        ("closure_low", "L00", "L01"),
        ("closure_high", "L10", "L11"),
        ("frontier_poor", "L00", "L10"),
        ("frontier_rich", "L01", "L11"),
        ("prune_frontier", "L11", "frontier_only"),
        ("prune_safe", "L11", "innovation_safe"),
    )
    for (edge, left, right) in edge_pairs
        keys_left = filter(
            key -> key[2] == left,
            collect(keys(selected)),
        )
        comparisons = length(keys_left)
        switches = count(keys_left) do key
            right_key = (key[1], right, key[3], key[4])
            selected[key] != selected[right_key]
        end
        push!(
            switch_rows,
            (
                relationship = "action_switching",
                group = edge,
                observation_count = comparisons,
                exact_mean_or_frequency =
                    _frequency(switches, comparisons),
                exact_slope = nothing,
                exact_difference = nothing,
                numerator_count = switches,
                denominator_count = comparisons,
            ),
        )
    end
    dense_trials =
        filter(row -> row.frontier_density == "dense", trial_rows)
    sparse_trials =
        filter(row -> row.frontier_density == "sparse", trial_rows)
    dense_signed = _mean(
        frontier_by_trial[row.trial_id].signed_total_dynamic_loss for
        row in dense_trials
    )
    sparse_signed = _mean(
        frontier_by_trial[row.trial_id].signed_total_dynamic_loss for
        row in sparse_trials
    )
    dense_positive = _mean(
        max(
            exact_rational(0),
            frontier_by_trial[row.trial_id].signed_total_dynamic_loss,
        ) for row in dense_trials
    )
    sparse_positive = _mean(
        max(
            exact_rational(0),
            frontier_by_trial[row.trial_id].signed_total_dynamic_loss,
        ) for row in sparse_trials
    )
    uniqueness_zero =
        filter(row -> iszero(row.unique_closure_count), asset_rows)
    uniqueness_positive =
        filter(row -> row.unique_closure_count > 0, asset_rows)
    weak = filter(
        row -> row.module_complementarity == "weak",
        trial_rows,
    )
    strong = filter(
        row -> row.module_complementarity == "strong",
        trial_rows,
    )
    append!(
        switch_rows,
        NamedTuple[
            (
                relationship = "frontier_density_signed_loss",
                group = "dense_minus_sparse",
                observation_count = length(trial_rows),
                exact_mean_or_frequency = _mean(signed_losses),
                exact_slope = _ols_slope(density, signed_losses),
                exact_difference = dense_signed - sparse_signed,
                numerator_count = 0,
                denominator_count = length(trial_rows),
            ),
            (
                relationship = "frontier_density_positive_loss",
                group = "dense_minus_sparse",
                observation_count = length(trial_rows),
                exact_mean_or_frequency = _mean(positive_losses),
                exact_slope = _ols_slope(density, positive_losses),
                exact_difference = dense_positive - sparse_positive,
                numerator_count = 0,
                denominator_count = length(trial_rows),
            ),
            (
                relationship =
                    "module_uniqueness_generative_value",
                group = "positive_minus_zero_uniqueness",
                observation_count = length(asset_rows),
                exact_mean_or_frequency = _mean(generative),
                exact_slope = _ols_slope(uniqueness, generative),
                exact_difference =
                    _mean(
                        row.signed_generative_loss for
                        row in uniqueness_positive
                    ) -
                    _mean(
                        row.signed_generative_loss for
                        row in uniqueness_zero
                    ),
                numerator_count = length(uniqueness_positive),
                denominator_count = length(asset_rows),
            ),
            (
                relationship =
                    "closure_richness_descendant_quality",
                group = "strong_minus_weak_complementarity",
                observation_count = length(trial_rows),
                exact_mean_or_frequency = _mean(quality),
                exact_slope = _ols_slope(richness, quality),
                exact_difference =
                    _mean(row.descendant_quality for row in strong) -
                    _mean(row.descendant_quality for row in weak),
                numerator_count = length(strong),
                denominator_count = length(trial_rows),
            ),
        ],
    )
    return switch_rows
end

function _prevalence(trial_rows, asset_rows)
    frontier = count(
        row -> row.frontier_only_signed_total_dynamic_loss > 0,
        trial_rows,
    )
    safe = count(
        row -> row.innovation_safe_signed_total_dynamic_loss > 0,
        trial_rows,
    )
    silent = count(
        row -> row.operationally_silent_generative,
        asset_rows,
    )
    silent_library = count(
        trial_id -> any(
            row ->
                row.trial_id == trial_id &&
                row.operationally_silent_generative,
            asset_rows,
        ),
        getproperty.(trial_rows, :trial_id),
    )
    substitution =
        count(row -> row.frontier_closure_J < 0, trial_rows)
    complementarity =
        count(row -> row.frontier_closure_J > 0, trial_rows)
    zero =
        count(row -> iszero(row.frontier_closure_J), trial_rows)
    positive_losses = filter(
        row -> row.frontier_only_signed_total_dynamic_loss > 0,
        trial_rows,
    )
    maximum_normalized = maximum(
        max(
            exact_rational(0),
            row.frontier_only_signed_total_dynamic_loss,
        ) / row.source_total_value for row in trial_rows
    )
    return (
        trial_count = length(trial_rows),
        frontier_positive_count = frontier,
        frontier_positive_frequency =
            _frequency(frontier, length(trial_rows)),
        conditional_mean_positive_loss = _mean(
            row.frontier_only_signed_total_dynamic_loss for
            row in positive_losses
        ),
        maximum_normalized_loss = maximum_normalized,
        innovation_safe_positive_count = safe,
        innovation_safe_positive_frequency =
            _frequency(safe, length(trial_rows)),
        silent_asset_count = silent,
        active_asset_count = length(asset_rows),
        silent_asset_frequency =
            _frequency(silent, length(asset_rows)),
        silent_library_count = silent_library,
        silent_library_frequency =
            _frequency(silent_library, length(trial_rows)),
        substitution_count = substitution,
        substitution_frequency =
            _frequency(substitution, length(trial_rows)),
        complementarity_count = complementarity,
        complementarity_frequency =
            _frequency(complementarity, length(trial_rows)),
        zero_count = zero,
        zero_frequency = _frequency(zero, length(trial_rows)),
    )
end

function _svg_escape(value)
    return replace(
        string(value),
        "&" => "&amp;",
        "<" => "&lt;",
        ">" => "&gt;",
        "\"" => "&quot;",
    )
end

function _svg_header(title, subtitle; height = 720)
    return """<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="$height" viewBox="0 0 1200 $height" role="img">
<rect width="1200" height="$height" fill="#FFFFFF"/>
<text x="64" y="52" font-family="Helvetica,Arial,sans-serif" font-size="28" font-weight="700" fill="#101828">$(_svg_escape(title))</text>
<text x="64" y="80" font-family="Helvetica,Arial,sans-serif" font-size="14" fill="#475467">$(_svg_escape(subtitle))</text>
"""
end

function _bar_figure(title, subtitle, labels, values, colors)
    io = IOBuffer()
    print(io, _svg_header(title, subtitle))
    maximum_value = max(maximum(values; init = 0.0), 1e-12)
    chart_x = 260
    chart_y = 120
    chart_width = 820
    row_height = 82
    for (index, (label, value, color)) in
        enumerate(zip(labels, values, colors))
        y = chart_y + (index - 1) * row_height
        width = chart_width * value / maximum_value
        println(
            io,
            """<text x="64" y="$(y + 28)" font-family="Helvetica,Arial,sans-serif" font-size="16" fill="#344054">$(_svg_escape(label))</text>""",
        )
        println(
            io,
            """<rect x="$chart_x" y="$(y + 5)" width="$chart_width" height="30" rx="5" fill="#F2F4F7"/>""",
        )
        println(
            io,
            """<rect x="$chart_x" y="$(y + 5)" width="$width" height="30" rx="5" fill="$color"/>""",
        )
        println(
            io,
            """<text x="$(chart_x + width + 10)" y="$(y + 27)" font-family="Helvetica,Arial,sans-serif" font-size="14" fill="#344054">$(@sprintf("%.3f", value))</text>""",
        )
    end
    println(
        io,
        """<text x="64" y="690" font-family="Helvetica,Arial,sans-serif" font-size="12" fill="#667085">Exact rational estimates; decimal rendering is presentation only. Registered finite-generator simulation, not population inference.</text>""",
    )
    println(io, "</svg>")
    return String(take!(io))
end

function _method_figure(method_rows)
    rows = filter(
        row -> row.method in ("frontier_only", "innovation_safe"),
        method_rows,
    )
    labels = String[]
    values = Float64[]
    colors = String[]
    for row in rows
        push!(labels, "$(row.method): compression")
        push!(values, Float64(row.mean_compression_ratio))
        push!(colors, row.method == "frontier_only" ? "#F79009" : "#1570EF")
        push!(labels, "$(row.method): positive loss")
        push!(values, Float64(row.positive_loss_frequency))
        push!(colors, row.method == "frontier_only" ? "#D92D20" : "#039855")
    end
    return _bar_figure(
        "Randomized-library v2 compression and loss",
        "Fixed N=1,024; every source and compressed state has a raw witness",
        labels,
        values,
        colors,
    )
end

function _prevalence_figure(prevalence)
    labels = [
        "Frontier-only positive loss",
        "Innovation-safe positive loss",
        "Silent generative asset",
        "Substitution",
        "Complementarity",
        "Zero interaction",
    ]
    values = Float64[
        prevalence.frontier_positive_frequency,
        prevalence.innovation_safe_positive_frequency,
        prevalence.silent_asset_frequency,
        prevalence.substitution_frequency,
        prevalence.complementarity_frequency,
        prevalence.zero_frequency,
    ]
    return _bar_figure(
        "Randomized-library v2 registered frequencies",
        "Exact counts under the locked raw-realizable generator",
        labels,
        values,
        [
            "#D92D20",
            "#039855",
            "#7A5AF8",
            "#1570EF",
            "#F79009",
            "#667085",
        ],
    )
end

function _factor_figure(factor_rows)
    io = IOBuffer()
    print(
        io,
        _svg_header(
            "Frontier-only loss across registered factor levels",
            "Exact factor-stratified frequencies; descriptive design contrasts only";
            height = 820,
        ),
    )
    factors = unique(row.factor for row in factor_rows)
    for (factor_index, factor) in enumerate(factors)
        selected = filter(row -> row.factor == factor, factor_rows)
        y = 125 + (factor_index - 1) * 92
        println(
            io,
            """<text x="64" y="$(y + 22)" font-family="Helvetica,Arial,sans-serif" font-size="15" font-weight="700" fill="#344054">$(_svg_escape(factor))</text>""",
        )
        for (level_index, row) in enumerate(selected)
            x = 330 + (level_index - 1) * 400
            value = Float64(row.frontier_positive_loss_frequency)
            width = 300 * value
            println(
                io,
                """<text x="$x" y="$(y + 20)" font-family="Helvetica,Arial,sans-serif" font-size="13" fill="#475467">$(_svg_escape(row.level))</text>""",
            )
            println(
                io,
                """<rect x="$(x + 70)" y="$y" width="300" height="25" rx="4" fill="#F2F4F7"/>""",
            )
            println(
                io,
                """<rect x="$(x + 70)" y="$y" width="$width" height="25" rx="4" fill="$(level_index == 1 ? "#4C78A8" : "#E45756")"/>""",
            )
            println(
                io,
                """<text x="$(x + 78 + width)" y="$(y + 18)" font-family="Helvetica,Arial,sans-serif" font-size="12" fill="#344054">$(_svg_escape(row.frontier_positive_loss_count))/$(row.trial_count)</text>""",
            )
        end
    end
    println(
        io,
        """<text x="64" y="795" font-family="Helvetica,Arial,sans-serif" font-size="12" fill="#667085">Simulation precision only; no causal or real-population interpretation.</text>""",
    )
    println(io, "</svg>")
    return String(take!(io))
end

function _json_escape(value)
    return replace(
        string(value),
        "\\" => "\\\\",
        "\"" => "\\\"",
        "\n" => "\\n",
    )
end

function _json_value(value)
    value isa Bool && return lowercase(string(value))
    value isa Integer && return string(value)
    value isa Rational &&
        return "\"$(_ratio_string(value))\""
    isnothing(value) && return "null"
    return "\"$(_json_escape(value))\""
end

function _summary_json(experiment)
    p = experiment.prevalence
    gates = experiment.gates
    io = IOBuffer()
    println(io, "{")
    println(io, "  \"schema_version\": \"randomized-library-v2-results-v1\",")
    println(io, "  \"experiment_id\": \"randomized-finite-library-stress-v2\",")
    println(io, "  \"trial_count\": $(length(experiment.trial_rows)),")
    println(io, "  \"arithmetic\": \"Rational{BigInt}\",")
    println(io, "  \"theorem_evidence\": false,")
    println(io, "  \"parent_design_sha256\": \"$(experiment.parent_hash)\",")
    println(io, "  \"stability_amendment_sha256\": \"$(experiment.stability_hash)\",")
    println(io, "  \"execution_amendment_sha256\": \"$(experiment.execution_hash)\",")
    println(io, "  \"row_counts\": {")
    names = (
        :trials,
        :corners,
        :transitions,
        :pruning,
        :assets,
        :actions,
        :profiles,
        :modules,
        :closures,
        :kernels,
        :projects,
        :witnesses,
    )
    counts = (
        length(experiment.trial_rows),
        length(experiment.corner_rows),
        length(experiment.transition_rows),
        length(experiment.pruning_rows),
        length(experiment.asset_rows),
        length(experiment.action_rows),
        length(experiment.profile_rows),
        length(experiment.module_rows),
        length(experiment.closure_rows),
        length(experiment.kernel_rows),
        length(experiment.project_rows),
        length(experiment.witness_rows),
    )
    for (index, (name, count_value)) in enumerate(zip(names, counts))
        comma = index == length(names) ? "" : ","
        println(io, "    \"$name\": $count_value$comma")
    end
    println(io, "  },")
    println(io, "  \"primary\": {")
    primary_fields = propertynames(p)
    for (index, field) in enumerate(primary_fields)
        comma = index == length(primary_fields) ? "" : ","
        println(
            io,
            "    \"$field\": $(_json_value(getproperty(p, field)))$comma",
        )
    end
    println(io, "  },")
    println(io, "  \"hard_gates\": {")
    gate_fields = propertynames(gates)
    for (index, field) in enumerate(gate_fields)
        comma = index == length(gate_fields) ? "" : ","
        println(
            io,
            "    \"$field\": $(_json_value(getproperty(gates, field)))$comma",
        )
    end
    println(io, "  }")
    println(io, "}")
    return String(take!(io))
end

function _percent(value)
    isnothing(value) && return "undefined"
    return @sprintf("%.2f%%", 100Float64(value))
end

function _report(experiment)
    p = experiment.prevalence
    frontier = only(
        row for row in experiment.method_summary if
        row.method == "frontier_only"
    )
    safe = only(
        row for row in experiment.method_summary if
        row.method == "innovation_safe"
    )
    io = IOBuffer()
    println(io, "# Randomized Library Report V2")
    println(io)
    println(io, "## Registered result")
    println(io)
    println(
        io,
        "The fixed registered run completed all **$(p.trial_count)** exact trials. " *
        "Every compressed state had an enumerated raw-library witness, every " *
        "interaction observation had four raw corners, and every hard gate passed.",
    )
    println(io)
    println(
        io,
        "Frontier-only pruning produced positive dynamic loss in " *
        "**$(p.frontier_positive_count)/$(p.trial_count)** trials " *
        "($(_percent(p.frontier_positive_frequency))). Its conditional mean " *
        "positive loss was **$(_csv_value(p.conditional_mean_positive_loss))** " *
        "and its maximum normalized loss was " *
        "**$(_csv_value(p.maximum_normalized_loss))**.",
    )
    println(
        io,
        "Innovation-safe pruning produced positive loss in " *
        "**$(p.innovation_safe_positive_count)/$(p.trial_count)** trials and " *
        "passed exact zero frontier, closure, operational, generative, and total " *
        "loss gates in every trial.",
    )
    println(io)
    println(
        io,
        "The mean compression ratios were " *
        "**$(_csv_value(frontier.mean_compression_ratio))** for frontier-only " *
        "pruning and **$(_csv_value(safe.mean_compression_ratio))** for " *
        "innovation-safe pruning.",
    )
    println(
        io,
        "Operationally silent generative assets occurred in " *
        "**$(p.silent_asset_count)/$(p.active_asset_count)** source-asset " *
        "observations ($(_percent(p.silent_asset_frequency))) and in " *
        "**$(p.silent_library_count)/$(p.trial_count)** libraries.",
    )
    println(io)
    println(
        io,
        "The raw-realizable interaction signs were **$(p.substitution_count)** " *
        "substitution, **$(p.complementarity_count)** complementarity, and " *
        "**$(p.zero_count)** zero cases. Predicate-true rows obeyed the locked " *
        "nonpositive-interaction gate.",
    )
    println(io)
    println(io, "## Design and exactness")
    println(io)
    println(
        io,
        "The run used the complete locked 2^7 factorial registry, master seed " *
        "`6075990691714899803`, all recorded derived seeds, horizon four, and " *
        "exact `Rational{BigInt}` model arithmetic. The final estimate uses " *
        "N=1,024 regardless of every earlier sequential sign.",
    )
    println(io)
    println(
        io,
        "The four libraries in each interaction rectangle were constructed from " *
        "one catalog by commuting frontier and closure additions. Menus, " *
        "candidate laws, completion paths, transitions, policies, and values " *
        "were evaluated from those raw primitives. No compressed state, action " *
        "menu, transition, or value was inserted directly.",
    )
    println(io)
    println(io, "## Hard gates")
    println(io)
    for field in propertynames(experiment.gates)
        println(io, "- `$field`: `$(getproperty(experiment.gates, field))`")
    end
    println(io)
    println(io, "## Precision diagnostics")
    println(io)
    println(
        io,
        "Cumulative diagnostics are reported at N = 50, 100, 200, 300, 500, " *
        "750, 1,000, and 1,024. Tables retain exact counts and rational point " *
        "estimates. Wilson intervals and MCSE square roots are descriptive " *
        "presentation diagnostics only. Sparse-support warnings remain visible " *
        "and never change the fixed maximum.",
    )
    println(io)
    println(io, "## Evidence boundary")
    println(io)
    println(
        io,
        "These are finite-generator simulation results, not statistical claims " *
        "about a real population and not Lean theorem evidence. The mechanically " *
        "evaluated primitive-condition flags describe only the generated rows. " *
        "The frozen N=90 pilot was not pooled and none of its files was overwritten.",
    )
    println(io)
    println(io, "## Artifact index")
    println(io)
    for (name, path) in pairs(experiment.output_paths)
        println(io, "- `$name`: `$path`")
    end
    return String(take!(io))
end

function _collect_results(results)
    field_names = (
        :corner_rows,
        :transition_rows,
        :pruning_rows,
        :asset_rows,
        :action_rows,
        :profile_rows,
        :module_rows,
        :closure_rows,
        :kernel_rows,
        :project_rows,
        :witness_rows,
    )
    collections = Dict{Symbol,Vector{NamedTuple}}(
        field => NamedTuple[] for field in field_names
    )
    for result in results, field in field_names
        append!(collections[field], getproperty(result, field))
    end
    return collections
end

function _validate_registry(config, registry)
    length(registry) == Int(config["trial_count"]) ||
        error("registered trial count changed")
    all(row.trial_id == index for (index, row) in enumerate(registry)) ||
        error("registered trial execution order changed")
    length(unique(row.principal_cell_id for row in registry)) == 128 ||
        error("principal-cell registry changed")
    length(unique(
        seed for row in registry for seed in (
            row.trial_seed,
            row.catalog_seed,
            row.project_seed,
            row.deletion_seed,
        )
    )) == 4096 || error("registered component seeds are not unique")
    return true
end

function _validate_final_gates(
    trial_rows,
    pruning_rows,
    witness_rows,
)
    safe = filter(
        row -> row.method == "innovation_safe",
        pruning_rows,
    )
    gates = (
        all_trials_completed = length(trial_rows) == 1024,
        all_trial_hard_gates =
            all(row -> row.all_hard_gates_pass, trial_rows),
        every_compressed_state_has_raw_witness =
            all(row -> row.witness_valid, witness_rows),
        every_rectangle_has_four_raw_witnesses =
            all(row -> row.four_raw_witnesses, trial_rows),
        raw_compressed_values_agree =
            all(row -> row.raw_compressed_values_agree, trial_rows),
        innovation_safe_frontier_loss_zero =
            all(row -> iszero(row.frontier_loss), safe),
        innovation_safe_closure_loss_zero =
            all(row -> iszero(row.closure_loss_count), safe),
        innovation_safe_operational_loss_zero =
            all(row -> iszero(row.signed_operational_loss), safe),
        innovation_safe_generative_loss_zero =
            all(row -> iszero(row.signed_generative_loss), safe),
        innovation_safe_total_loss_zero =
            all(row -> iszero(row.signed_total_dynamic_loss), safe),
        all_signed_decompositions_exact =
            all(row -> row.all_decompositions_exact, trial_rows),
        theorem_flags_mechanically_evaluated = all(
            row ->
                row.theorem_regime == "primitive_eligible" ?
                row.computed_primitive_predicate :
                !row.computed_primitive_predicate,
            trial_rows,
        ),
        all_theorem_facing_outputs_exact =
            all(row -> row.all_exact_outputs_rational, trial_rows),
        predicate_true_interactions_nonpositive = all(
            row ->
                !row.computed_primitive_predicate ||
                row.frontier_closure_J <= 0,
            trial_rows,
        ),
        theorem_evidence_false =
            all(row -> !row.theorem_evidence, trial_rows),
    )
    all(values(gates)) ||
        error("registered v2 aggregate hard gate failed: $gates")
    return gates
end

function _output_paths(base_config, implementation_config)
    base = Dict(
        Symbol(name) => String(path) for
        (name, path) in base_config["outputs"]
    )
    base[:factor_stability] =
        "experiments/results/summaries/randomized_library_v2_stability_factor_summary.csv"
    base[:interaction_signs] = String(
        implementation_config["outputs"]["interaction_signs"],
    )
    base[:witness_manifest] = String(
        implementation_config["outputs"]["witness_manifest"],
    )
    return (; (name => base[name] for name in sort(collect(keys(base))))...)
end

function run_registered_experiment_v2(;
    config_path::AbstractString = DEFAULT_CONFIG,
    progress::Bool = true,
)
    parent_hash = LockRandomizedLibraryDesignV2.verify_design_lock(
        config_path,
    )
    stability_hash =
        LockRandomizedLibraryStabilityAmendment.verify_amendment_lock(
            STABILITY_CONFIG,
        )
    isfile(IMPLEMENTATION_CONFIG) ||
        error("registered execution amendment config is absent")
    implementation_config = TOML.parsefile(IMPLEMENTATION_CONFIG)
    implementation_config["registration_status"] ==
        "pre-outcome_execution_implementation_locked" ||
        error("execution amendment is not locked")
    execution_hash =
        LockRandomizedLibraryExecutionAmendment.verify_execution_lock(
            IMPLEMENTATION_CONFIG,
        )
    config = TOML.parsefile(config_path)
    registry = read_registered_v2_trials(
        _absolute(config["registry"]["path"]),
    )
    _validate_registry(config, registry)
    results = V2TrialResult[]
    for row in registry
        push!(
            results,
            run_registered_v2_trial(
                row;
                horizon = Int(config["horizon"]),
                operational_budget_fraction =
                    _parse_exact(config["operational_budget_fraction"]),
                generative_budget_fraction =
                    _parse_exact(config["generative_budget_fraction"]),
            ),
        )
        progress && row.trial_id % 32 == 0 &&
            println(
                "registered v2 progress: $(row.trial_id)/$(length(registry))",
            )
    end
    trial_rows = [result.trial_row for result in results]
    collections = _collect_results(results)
    gates = _validate_final_gates(
        trial_rows,
        collections[:pruning_rows],
        collections[:witness_rows],
    )
    method_summary = _method_summary(collections[:pruning_rows])
    factor_summary = _factor_summary(
        trial_rows,
        collections[:pruning_rows],
        collections[:asset_rows],
    )
    interaction_rows = _interaction_rows(trial_rows)
    relationship_summary = _relationship_summary(
        trial_rows,
        collections[:pruning_rows],
        collections[:asset_rows],
        collections[:action_rows],
    )
    diagnostics = randomized_stability_diagnostics(trial_rows)
    prevalence = _prevalence(trial_rows, collections[:asset_rows])
    output_paths = _output_paths(config, implementation_config)
    experiment = (;
        config,
        parent_hash,
        stability_hash,
        execution_hash,
        output_paths,
        trial_rows,
        corner_rows = collections[:corner_rows],
        transition_rows = collections[:transition_rows],
        pruning_rows = collections[:pruning_rows],
        asset_rows = collections[:asset_rows],
        action_rows = collections[:action_rows],
        profile_rows = collections[:profile_rows],
        module_rows = collections[:module_rows],
        closure_rows = collections[:closure_rows],
        kernel_rows = collections[:kernel_rows],
        project_rows = collections[:project_rows],
        witness_rows = collections[:witness_rows],
        method_summary,
        factor_summary,
        interaction_rows,
        relationship_summary,
        diagnostics,
        prevalence,
        gates,
    )
    return experiment
end

function _parse_exact(value)
    pieces = split(String(value), "//")
    length(pieces) == 2 ||
        error("registered exact rational is malformed: $value")
    return exact_rational(
        parse(BigInt, pieces[1]) // parse(BigInt, pieces[2]),
    )
end

function _artifact_contents(experiment)
    paths = experiment.output_paths
    artifacts = Dict{String,String}(
        paths.trials => _render_csv(experiment.trial_rows),
        paths.rectangle_corners =>
            _render_csv(experiment.corner_rows),
        paths.rectangle_transitions =>
            _render_csv(experiment.transition_rows),
        paths.pruning => _render_csv(experiment.pruning_rows),
        paths.assets => _render_csv(experiment.asset_rows),
        paths.actions => _render_csv(experiment.action_rows),
        paths.profiles => _render_csv(experiment.profile_rows),
        paths.modules => _render_csv(experiment.module_rows),
        paths.closures => _render_csv(experiment.closure_rows),
        paths.kernels => _render_csv(experiment.kernel_rows),
        paths.projects => _render_csv(experiment.project_rows),
        paths.method_summary =>
            _render_csv(experiment.method_summary),
        paths.factor_summary =>
            _render_csv(experiment.factor_summary),
        paths.relationship_summary =>
            _render_csv(experiment.relationship_summary),
        paths.stability_summary =>
            render_randomized_stability_csv(experiment.diagnostics),
        paths.factor_stability =>
            render_randomized_factor_stability_csv(
                experiment.diagnostics,
            ),
        paths.interaction_signs =>
            _render_csv(experiment.interaction_rows),
        paths.witness_manifest =>
            _render_csv(experiment.witness_rows),
        paths.summary => _summary_json(experiment),
        paths.report => _report(experiment),
        paths.method_figure =>
            _method_figure(experiment.method_summary),
        paths.prevalence_figure =>
            _prevalence_figure(experiment.prevalence),
        paths.factor_figure =>
            _factor_figure(experiment.factor_summary),
        paths.stability_figure =>
            render_randomized_stability_svg(experiment.diagnostics),
    )
    return artifacts
end

function _write_or_check(artifacts; check::Bool)
    for path in sort(collect(keys(artifacts)))
        absolute = _absolute(path)
        content = artifacts[path]
        if check
            isfile(absolute) ||
                error("registered v2 artifact is absent: $path")
            read(absolute, String) == content ||
                error("registered v2 artifact drift: $path")
        else
            mkpath(dirname(absolute))
            open(absolute, "w") do io
                write(io, content)
            end
        end
    end
    return true
end

function main(args = ARGS)
    check = "--check" in args
    allowed = Set(["--check"])
    all(argument -> argument in allowed, args) ||
        error("usage: run_randomized_library_stress_v2.jl [--check]")
    experiment = run_registered_experiment_v2()
    artifacts = _artifact_contents(experiment)
    _write_or_check(artifacts; check)
    action = check ? "current" : "written"
    println(
        "randomized-library v2 artifacts $action: " *
        "N=$(length(experiment.trial_rows)), " *
        "frontier_loss=$(experiment.prevalence.frontier_positive_count), " *
        "safe_loss=$(experiment.prevalence.innovation_safe_positive_count), " *
        "interaction=$(experiment.prevalence.substitution_count)/" *
        "$(experiment.prevalence.zero_count)/" *
        "$(experiment.prevalence.complementarity_count)",
    )
    return experiment
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    RandomizedLibraryStressV2.main()
end
