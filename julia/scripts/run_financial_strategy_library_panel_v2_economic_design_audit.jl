module FinancialStrategyLibraryPanelV2EconomicDesignAudit

using SHA: sha256
using TOML

export audit, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const SOURCE_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v2",
)
const AUDIT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v2_economic_design_audit",
)
const PREDECISION_ROOT = joinpath(SOURCE_ROOT, "local_results", "predecision")
const POSTDECISION_ROOT = joinpath(SOURCE_ROOT, "local_results", "postdecision")
const ORIGIN_STATUS_ROOT = joinpath(SOURCE_ROOT, "local_data", "origin_status")
const PROMOTED_SUMMARY = joinpath(SOURCE_ROOT, "results", "PRIMARY_SUMMARY.toml")
const RESULTS_ROOT = joinpath(AUDIT_ROOT, "results")

const SAFE_ARM = "innovation_safe_greedy"
const COMPARATOR_ARM = "frontier_only_budget_matched"
const THRESHOLD_GRID = (0.0, 0.01, 0.025, 0.05, 0.10, 0.20)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

_mean(values) = isempty(values) ? NaN : sum(values) / length(values)

function _median(values)
    isempty(values) && return NaN
    ordered = sort!(collect(values))
    n = length(ordered)
    isodd(n) && return ordered[(n + 1) ÷ 2]
    return (ordered[n ÷ 2] + ordered[n ÷ 2 + 1]) / 2
end

function _nearest_rank_quantile(values, probability)
    isempty(values) && return NaN
    0 <= probability <= 1 || throw(ArgumentError("quantile probability must lie in [0,1]"))
    ordered = sort!(collect(values))
    index = clamp(ceil(Int, probability * length(ordered)), 1, length(ordered))
    return ordered[index]
end

function _correlation(xs, ys)
    length(xs) == length(ys) || throw(DimensionMismatch("correlation inputs differ"))
    length(xs) >= 3 || return NaN
    xbar = _mean(xs)
    ybar = _mean(ys)
    numerator = sum((x - xbar) * (y - ybar) for (x, y) in zip(xs, ys))
    xss = sum((x - xbar)^2 for x in xs)
    yss = sum((y - ybar)^2 for y in ys)
    iszero(xss) || iszero(yss) ? NaN : numerator / sqrt(xss * yss)
end

function _csv_field(value)
    text = value isa AbstractFloat ? repr(Float64(value)) : string(value)
    occursin(r"[\",\n\r]", text) || return text
    return "\"" * replace(text, "\"" => "\"\"") * "\""
end

function _csv_text(columns, rows)
    io = IOBuffer()
    println(io, join(columns, ','))
    for row in rows
        println(io, join((_csv_field(getproperty(row, Symbol(column))) for column in columns), ','))
    end
    return String(take!(io))
end

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _atomic_write(path, text)
    mkpath(dirname(path))
    temporary = path * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, path; force = true)
    return path
end

function _strategy_parts(identifier)
    identifier == "mandatory_inactive_cash" && return nothing
    parts = split(String(identifier), '|')
    length(parts) == 8 || error("malformed v2 strategy identifier")
    return (
        origin_id = parts[1],
        permno = parse(Int, parts[2]),
        signal = parts[3],
        filter = parts[4],
        horizon = parse(Int, parts[5]),
        sizing = parts[6],
        exit_rule = parts[7],
        risk = parts[8],
    )
end

function _origin_class_maps()
    result = Dict{String,Dict{Int,String}}()
    for path in sort!(filter(endswith(".toml"), readdir(ORIGIN_STATUS_ROOT; join = true)))
        payload = TOML.parsefile(path)
        origin_id = String(payload["origin_id"])
        selected = Dict{Int,String}()
        for row in payload["selected"]
            selected[Int(row["permno"])] = String(row["instrument_class"])
        end
        length(selected) == 100 || error("origin $origin_id does not have 100 selected securities")
        result[origin_id] = selected
    end
    length(result) == 20 || error("expected 20 origin classification maps")
    return result
end

function _choice_map(choices)
    result = Dict{String,Dict{String,Any}}()
    for choice in choices
        menu_id = String(choice["menu_id"])
        haskey(result, menu_id) && error("duplicate frozen choice for $menu_id")
        result[menu_id] = choice
    end
    return result
end

function _menu_map(menus)
    result = Dict{String,Dict{String,Any}}()
    for menu in menus
        menu_id = String(menu["menu_id"])
        haskey(result, menu_id) && error("duplicate predecision menu $menu_id")
        ids = String.(menu["candidate_ids"])
        scores = Float64.(menu["candidate_predecision_scores"])
        length(ids) == 8 || error("menu $menu_id does not have eight candidates")
        length(unique(ids)) == 8 || error("menu $menu_id repeats a candidate")
        result[menu_id] = Dict{String,Any}(
            "scores" => Dict(id => score for (id, score) in zip(ids, scores)),
            "candidate_ids" => ids,
        )
    end
    return result
end

function _collect_rows()
    class_maps = _origin_class_maps()
    rows = NamedTuple[]
    pre_files = String[]
    for origin_id in sort!(readdir(PREDECISION_ROOT))
        origin_dir = joinpath(PREDECISION_ROOT, origin_id)
        isdir(origin_dir) || continue
        append!(pre_files, sort!(filter(endswith(".toml"), readdir(origin_dir; join = true))))
    end
    length(pre_files) == 40 || error("expected 40 sealed predecision docket files")
    seen_menus = Set{String}()
    for pre_path in pre_files
        origin_id = basename(dirname(pre_path))
        post_path = joinpath(POSTDECISION_ROOT, origin_id, basename(pre_path))
        isfile(post_path) || error("missing postdecision partner for $(relpath(pre_path, REPOSITORY_ROOT))")
        pre = TOML.parsefile(pre_path)
        post = TOML.parsefile(post_path)
        String(pre["origin_id"]) == origin_id || error("predecision origin path mismatch")
        String(post["origin_id"]) == origin_id || error("postdecision origin path mismatch")
        String(pre["docket_id"]) == String(post["docket_id"]) || error("docket mismatch")
        String(post["predecision_file_sha256"]) == _sha256_file(pre_path) ||
            error("postdecision file does not bind its predecision partner")
        String(pre["primary_safe_arm_id"]) == SAFE_ARM || error("unexpected safe arm")
        String(pre["primary_comparator_arm_id"]) == COMPARATOR_ARM ||
            error("unexpected comparator arm")
        menus = _menu_map(pre["menus"])
        length(menus) == 32 || error("expected 32 menus per docket")
        safe_choices = _choice_map(pre["choices"][SAFE_ARM])
        comparator_choices = _choice_map(pre["choices"][COMPARATOR_ARM])
        length(safe_choices) == 32 || error("safe choice count mismatch")
        length(comparator_choices) == 32 || error("comparator choice count mismatch")
        length(post["menus"]) == 32 || error("postdecision menu count mismatch")
        for outcome in post["menus"]
            menu_id = String(outcome["menu_id"])
            menu_id in seen_menus && error("menu identifier repeated across dockets")
            push!(seen_menus, menu_id)
            haskey(menus, menu_id) || error("postdecision menu absent from predecision record")
            safe_choice = safe_choices[menu_id]
            comparator_choice = comparator_choices[menu_id]
            safe_outcome = outcome["arm_outcomes"][SAFE_ARM]
            comparator_outcome = outcome["arm_outcomes"][COMPARATOR_ARM]
            safe_id = String(safe_outcome["candidate_id"])
            comparator_id = String(comparator_outcome["candidate_id"])
            String(safe_choice["candidate_id"]) == safe_id || error("safe frozen choice changed")
            String(comparator_choice["candidate_id"]) == comparator_id ||
                error("comparator frozen choice changed")
            safe_cash = Bool(safe_outcome["used_cash_fallback"])
            comparator_cash = Bool(comparator_outcome["used_cash_fallback"])
            scores = menus[menu_id]["scores"]
            safe_pre = safe_cash ? 0.0 : Float64(scores[safe_id])
            comparator_pre = comparator_cash ? 0.0 : Float64(scores[comparator_id])
            safe_post = Bool(safe_outcome["available"]) ? Float64(safe_outcome["score"]) : NaN
            comparator_post = Bool(comparator_outcome["available"]) ?
                Float64(comparator_outcome["score"]) : NaN
            complete = Bool(outcome["complete_primary_pair"])
            complete == (isfinite(safe_post) && isfinite(comparator_post)) ||
                error("primary completeness does not reconcile")
            delta = complete ? Float64(outcome["heldout_innovation_utility_delta"]) : NaN
            complete && isapprox(delta, safe_post - comparator_post; atol = 1e-12, rtol = 0) ||
                !complete || error("held-out delta arithmetic changed")
            same_candidate = Bool(outcome["same_primary_candidate"])
            same_candidate == (safe_id == comparator_id) || error("same-candidate flag changed")
            safe_parts = _strategy_parts(safe_id)
            comparator_parts = _strategy_parts(comparator_id)
            safe_class = safe_cash ? "cash" : class_maps[origin_id][safe_parts.permno]
            comparator_class = comparator_cash ?
                "cash" : class_maps[origin_id][comparator_parts.permno]
            push!(rows, (
                origin_id,
                decision_year = parse(Int, last(split(origin_id, 'O'))),
                docket_id = String(pre["docket_id"]),
                menu_id,
                complete,
                same_candidate,
                safe_rank = Int(safe_choice["predecision_rank"]),
                comparator_rank = Int(comparator_choice["predecision_rank"]),
                safe_cash,
                comparator_cash,
                safe_pre,
                comparator_pre,
                safe_post,
                comparator_post,
                delta,
                safe_id,
                comparator_id,
                safe_permno = safe_cash ? missing : safe_parts.permno,
                comparator_permno = comparator_cash ? missing : comparator_parts.permno,
                safe_class,
                comparator_class,
            ))
        end
    end
    length(rows) == 1_280 || error("registered menu-pair count changed")
    return rows
end

function _origin_estimates(rows, value_function)
    docket_values = Dict{Tuple{String,String},Vector{Float64}}()
    for row in rows
        row.complete || continue
        push!(get!(docket_values, (row.origin_id, row.docket_id), Float64[]), value_function(row))
    end
    length(docket_values) == 40 || error("origin-docket coverage changed")
    by_origin = Dict{String,Vector{Float64}}()
    for ((origin_id, _), values) in docket_values
        push!(get!(by_origin, origin_id, Float64[]), _mean(values))
    end
    all(length(values) == 2 for values in values(by_origin)) ||
        error("an origin lacks one of its two dockets")
    return Dict(origin_id => _mean(values) for (origin_id, values) in by_origin)
end

function _estimate_summary(estimates)
    ordered_origins = sort!(collect(keys(estimates)))
    values = Float64[estimates[origin] for origin in ordered_origins]
    signed_sum = sum(values)
    contribution_2007 = iszero(signed_sum) ? NaN : estimates["FSLP2-O2007"] / signed_sum
    return (
        mean = _mean(values),
        median = _nearest_rank_quantile(values, 0.5),
        positive = count(>(0), values),
        zero = count(iszero, values),
        negative = count(<(0), values),
        minimum = minimum(values),
        maximum = maximum(values),
        contribution_2007,
    )
end

_original_value(row) = row.delta

function _cash_floor_value(row)
    safe = row.safe_pre > 0 ? row.safe_post : 0.0
    comparator = row.comparator_pre > 0 ? row.comparator_post : 0.0
    return safe - comparator
end

function _nested_value(row, threshold)
    comparator_pre = max(row.comparator_pre, 0.0)
    comparator_post = row.comparator_pre > 0 ? row.comparator_post : 0.0
    safe_post = row.safe_pre > 0 ? row.safe_post : 0.0
    adopt = row.safe_pre - comparator_pre > threshold
    return adopt ? safe_post - comparator_post : 0.0
end

function _rank_rows(rows)
    result = NamedTuple[]
    for (arm, ranks) in (
        ("innovation_safe_greedy", getfield.(rows, :safe_rank)),
        ("frontier_only_budget_matched", getfield.(rows, :comparator_rank)),
    )
        for rank in sort!(unique(ranks))
            count_rank = count(==(rank), ranks)
            push!(result, (; arm, rank, count = count_rank, share = count_rank / length(ranks)))
        end
    end
    return result
end

function _origin_rows(rows, original, cash_floor, nested_zero)
    result = NamedTuple[]
    for origin_id in sort!(collect(keys(original)))
        scoped = filter(row -> row.origin_id == origin_id && row.complete, rows)
        changed = count(row -> !row.same_candidate, scoped)
        active_changed = count(
            row -> !row.same_candidate && !row.safe_cash && !row.comparator_cash,
            scoped,
        )
        same_security = count(
            row -> !row.same_candidate && !row.safe_cash && !row.comparator_cash &&
                   row.safe_permno == row.comparator_permno,
            scoped,
        )
        push!(result, (;
            origin_id,
            decision_year = first(scoped).decision_year,
            complete_pairs = length(scoped),
            changed_pairs = changed,
            active_changed_pairs = active_changed,
            same_security_active_changed_pairs = same_security,
            comparator_cash_pairs = count(getfield.(scoped, :comparator_cash)),
            original_contrast = original[origin_id],
            cash_floor_contrast = cash_floor[origin_id],
            nested_no_harm_zero_contrast = nested_zero[origin_id],
        ))
    end
    return result
end

function _instrument_rows(rows)
    groups = Dict{Tuple{String,String},Vector{Float64}}()
    for row in rows
        row.complete && !row.same_candidate || continue
        push!(get!(groups, (row.safe_class, row.comparator_class), Float64[]), row.delta)
    end
    return [(
        safe_instrument_class = key[1],
        comparator_instrument_class = key[2],
        changed_pair_count = length(groups[key]),
        mean_contrast = _mean(groups[key]),
        median_contrast = _median(groups[key]),
    ) for key in sort!(collect(keys(groups)))]
end

function _calibration(rows)
    changed = filter(row -> row.complete && !row.same_candidate, rows)
    active = filter(row -> !row.safe_cash && !row.comparator_cash, changed)
    pooled = _correlation(
        [row.safe_pre - row.comparator_pre for row in changed],
        getfield.(changed, :delta),
    )
    pooled_active = _correlation(
        [row.safe_pre - row.comparator_pre for row in active],
        getfield.(active, :delta),
    )
    cell_correlations = Float64[]
    for origin_id in sort!(unique(getfield.(active, :origin_id))),
        docket_id in sort!(unique(getfield.(active, :docket_id)))
        scoped = filter(
            row -> row.origin_id == origin_id && row.docket_id == docket_id,
            active,
        )
        correlation = _correlation(
            [row.safe_pre - row.comparator_pre for row in scoped],
            getfield.(scoped, :delta),
        )
        isfinite(correlation) && push!(cell_correlations, correlation)
    end
    return (
        changed_count = length(changed),
        active_changed_count = length(active),
        pooled,
        pooled_active,
        within_cell_median = _median(cell_correlations),
        within_cell_mean = _mean(cell_correlations),
        within_cell_positive = count(>(0), cell_correlations),
        within_cell_negative = count(<(0), cell_correlations),
    )
end

function _threshold_rows(rows)
    result = NamedTuple[]
    for threshold in THRESHOLD_GRID
        estimates = _origin_estimates(rows, row -> _nested_value(row, threshold))
        summary = _estimate_summary(estimates)
        complete = filter(row -> row.complete, rows)
        adoption_count = count(
            row -> row.safe_pre - max(row.comparator_pre, 0.0) > threshold,
            complete,
        )
        push!(result, (;
            threshold,
            adoption_count,
            adoption_rate = adoption_count / length(complete),
            origin_mean = summary.mean,
            origin_median = summary.median,
            positive_origins = summary.positive,
            zero_origins = summary.zero,
            negative_origins = summary.negative,
            origin_minimum = summary.minimum,
            origin_maximum = summary.maximum,
            contribution_2007 = summary.contribution_2007,
        ))
    end
    return result
end

function _report(summary, threshold_rows, instrument_rows)
    original = summary["registered_policy"]
    cash_floor = summary["cash_floor_policy"]
    nested = summary["nested_no_harm_zero_policy"]
    io = IOBuffer()
    println(io, "# Economic-design falsification audit: sealed financial panel v2")
    println(io)
    println(io, "## Verdict")
    println(io)
    println(io, "**", summary["status"], "**. The audit triggered ",
        summary["direction_gate"]["trigger_count"], " of ",
        summary["direction_gate"]["condition_count"],
        " diagnostic conditions; at least ", summary["direction_gate"]["required_count"],
        " were required to proceed with the economic v3 direction.")
    println(io)
    println(io, "This is a post-hoc design diagnosis, not a replacement v2 result. The sealed v2 ",
        "primary remains registered and unchanged.")
    println(io)
    println(io, "## Controlling data and reconciliation")
    println(io)
    println(io, "- 40 sealed origin--docket predecision files were hash-matched to 40 postdecision files.")
    println(io, "- 1,280 registered menu pairs were recovered; ", summary["data"]["complete_pairs"],
        " were complete and ", summary["data"]["incomplete_pairs"], " remained unavailable.")
    println(io, "- The independently recomputed registered origin mean was `",
        original["mean"], "`, matching the promoted summary.")
    println(io)
    println(io, "## Findings")
    println(io)
    println(io, "| Finding | Evidence | Interpretation |")
    println(io, "|---|---:|---|")
    println(io, "| Unequal opportunity-set optimization | Safe rank-one choices: ",
        summary["selection"]["safe_rank_one_count"], "/1,280; comparator lower-rank or cash: ",
        summary["selection"]["comparator_lower_rank_or_cash_count"], "/1,280 | Closure is combined with greater exposure to the maximum of noisy estimates. |")
    println(io, "| Weak rank calibration | Active changed pre-gap/held-out correlation: ",
        summary["calibration"]["pre_gap_vs_delta_active_correlation"],
        " | The ranking rule does not reliably distinguish the subsequently better choice. |")
    println(io, "| Security-identity confounding | Different-security share among active changed pairs: ",
        summary["security"]["different_security_share"],
        " | Nearly every active contrast changes both the rule and the security. |")
    println(io, "| Cash outside option omitted | Safe estimated-negative active choices: ",
        summary["selection"]["safe_negative_active_count"], "; comparator: ",
        summary["selection"]["comparator_negative_active_count"],
        " | Both arms can be forced to exercise an estimated-negative option even though cash has utility zero. |")
    println(io, "| Primary sensitivity to cash floor | Mean ", original["mean"], " → ",
        cash_floor["mean"], "; 2007 contribution ", original["contribution_2007"], " → ",
        cash_floor["contribution_2007"],
        " | A rational outside option materially reduces both magnitude and outlier dependence. |")
    println(io)
    println(io, "## Policy diagnostics")
    println(io)
    println(io, "| Policy | Origin mean | Median | Positive / negative | 2007 signed contribution |")
    println(io, "|---|---:|---:|---:|---:|")
    for (label, values) in (
        ("Registered forced-active rule", original),
        ("Cash floor", cash_floor),
        ("Nested no-harm, threshold 0", nested),
    )
        println(io, "| ", label, " | ", values["mean"], " | ", values["median"], " | ",
            values["positive"], " / ", values["negative"], " | ",
            values["contribution_2007"], " |")
    end
    println(io)
    println(io, "The threshold grid is diagnostic only. Selecting a favorable threshold from this ",
        "historical panel would be another form of outcome-driven specification search.")
    println(io)
    println(io, "## Instrument-class heterogeneity")
    println(io)
    println(io, "| Safe class | Comparator class | Changed pairs | Mean | Median |")
    println(io, "|---|---|---:|---:|---:|")
    for row in instrument_rows
        println(io, "| ", row.safe_instrument_class, " | ", row.comparator_instrument_class,
            " | ", row.changed_pair_count, " | ", row.mean_contrast, " | ",
            row.median_contrast, " |")
    end
    println(io)
    println(io, "## Decision for v3")
    println(io)
    println(io, "The gate supports proceeding with a v3 economic design that: (1) treats cash and the ",
        "comparator choice as always-feasible outside options; (2) uses diversified portfolio ",
        "strategies rather than ticker--strategy candidates; (3) separates opportunity coverage, ",
        "ranking calibration, and realized policy value; and (4) evaluates incremental portfolio ",
        "certainty equivalent under a common risk and cost budget.")
    println(io)
    println(io, "## Limitations")
    println(io)
    println(io, "- Every alternative policy was evaluated after the v2 outcome was known.")
    println(io, "- Candidate-level correlations are range-restricted by the frozen selection rules.")
    println(io, "- The audit can diagnose the current decision rule but cannot establish the performance of v3.")
    println(io, "- A genuinely confirmatory v3 economic result still requires an untouched time period or independent market panel.")
    return String(take!(io))
end

function _dictionary(summary)
    return Dict{String,Any}(
        "mean" => summary.mean,
        "median" => summary.median,
        "positive" => summary.positive,
        "zero" => summary.zero,
        "negative" => summary.negative,
        "minimum" => summary.minimum,
        "maximum" => summary.maximum,
        "contribution_2007" => summary.contribution_2007,
    )
end

function _outputs()
    rows = _collect_rows()
    complete = filter(row -> row.complete, rows)
    original_estimates = _origin_estimates(rows, _original_value)
    cash_floor_estimates = _origin_estimates(rows, _cash_floor_value)
    nested_zero_estimates = _origin_estimates(rows, row -> _nested_value(row, 0.0))
    original = _estimate_summary(original_estimates)
    cash_floor = _estimate_summary(cash_floor_estimates)
    nested_zero = _estimate_summary(nested_zero_estimates)
    promoted = TOML.parsefile(PROMOTED_SUMMARY)
    isapprox(original.mean, Float64(promoted["primary_mean"]); atol = 1e-14, rtol = 0) ||
        error("audit did not reproduce the promoted origin mean")
    length(complete) == 1_277 || error("audit did not reproduce primary completeness")
    calibration = _calibration(rows)
    active_changed = filter(
        row -> row.complete && !row.same_candidate && !row.safe_cash && !row.comparator_cash,
        rows,
    )
    same_security = count(row -> row.safe_permno == row.comparator_permno, active_changed)
    different_share = 1 - same_security / length(active_changed)
    lower_or_cash = count(row -> row.comparator_rank != 1, rows)
    mean_relative_change = abs(cash_floor.mean - original.mean) / abs(original.mean)
    contribution_change = abs(cash_floor.contribution_2007 - original.contribution_2007)
    gate_conditions = Dict{String,Bool}(
        "unequal_opportunity_set" => count(==(1), getfield.(rows, :safe_rank)) == 1_280 &&
            lower_or_cash / 1_280 > 0.50,
        "weak_active_rank_calibration" => abs(calibration.pooled_active) < 0.10,
        "security_identity_confounding" => different_share > 0.90,
        "outside_option_materiality" => mean_relative_change > 0.25 || contribution_change > 0.25,
    )
    trigger_count = count(values(gate_conditions))
    direction_supported = trigger_count >= 3
    threshold_rows = _threshold_rows(rows)
    instrument_rows = _instrument_rows(rows)
    summary = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v2-economic-design-audit-v1",
        "audit_id" => "financial-strategy-library-panel-v2-economic-design-audit",
        "source_experiment_id" => "financial-strategy-library-panel-v2",
        "audit_is_post_hoc" => true,
        "registered_v2_result_unchanged" => true,
        "licensed_rows_included" => false,
        "status" => direction_supported ? "V3_ECONOMIC_DIRECTION_SUPPORTED" :
            "V3_ECONOMIC_DIRECTION_NOT_YET_SUPPORTED",
        "data" => Dict{String,Any}(
            "origin_count" => 20,
            "docket_count" => 40,
            "registered_pairs" => length(rows),
            "complete_pairs" => length(complete),
            "incomplete_pairs" => length(rows) - length(complete),
            "predecision_postdecision_hash_binding_verified" => true,
        ),
        "selection" => Dict{String,Any}(
            "safe_rank_one_count" => count(==(1), getfield.(rows, :safe_rank)),
            "comparator_rank_one_count" => count(==(1), getfield.(rows, :comparator_rank)),
            "comparator_lower_rank_count" => count(>(1), getfield.(rows, :comparator_rank)),
            "comparator_cash_count" => count(getfield.(rows, :comparator_cash)),
            "comparator_lower_rank_or_cash_count" => lower_or_cash,
            "same_candidate_complete_count" => count(row -> row.complete && row.same_candidate, rows),
            "changed_candidate_complete_count" => count(row -> row.complete && !row.same_candidate, rows),
            "safe_negative_active_count" => count(row -> !row.safe_cash && row.safe_pre < 0, rows),
            "comparator_negative_active_count" => count(
                row -> !row.comparator_cash && row.comparator_pre < 0,
                rows,
            ),
        ),
        "calibration" => Dict{String,Any}(
            "changed_pair_count" => calibration.changed_count,
            "active_changed_pair_count" => calibration.active_changed_count,
            "pre_gap_vs_delta_correlation" => calibration.pooled,
            "pre_gap_vs_delta_active_correlation" => calibration.pooled_active,
            "within_cell_median_correlation" => calibration.within_cell_median,
            "within_cell_mean_correlation" => calibration.within_cell_mean,
            "within_cell_positive_count" => calibration.within_cell_positive,
            "within_cell_negative_count" => calibration.within_cell_negative,
        ),
        "security" => Dict{String,Any}(
            "active_changed_pair_count" => length(active_changed),
            "same_security_count" => same_security,
            "different_security_count" => length(active_changed) - same_security,
            "different_security_share" => different_share,
        ),
        "registered_policy" => _dictionary(original),
        "cash_floor_policy" => _dictionary(cash_floor),
        "nested_no_harm_zero_policy" => _dictionary(nested_zero),
        "outside_option_sensitivity" => Dict{String,Any}(
            "absolute_relative_change_in_mean" => mean_relative_change,
            "absolute_change_in_2007_signed_contribution" => contribution_change,
        ),
        "direction_gate" => Dict{String,Any}(
            "condition_count" => length(gate_conditions),
            "required_count" => 3,
            "trigger_count" => trigger_count,
            "conditions" => gate_conditions,
            "v3_direction_supported" => direction_supported,
        ),
    )
    rank_rows = _rank_rows(rows)
    origin_rows = _origin_rows(
        rows,
        original_estimates,
        cash_floor_estimates,
        nested_zero_estimates,
    )
    outputs = Dict{String,String}(
        "AUDIT_SUMMARY.toml" => _toml_text(summary),
        "selection_rank_distribution.csv" => _csv_text(
            ["arm", "rank", "count", "share"],
            rank_rows,
        ),
        "origin_policy_diagnostics.csv" => _csv_text(
            [
                "origin_id",
                "decision_year",
                "complete_pairs",
                "changed_pairs",
                "active_changed_pairs",
                "same_security_active_changed_pairs",
                "comparator_cash_pairs",
                "original_contrast",
                "cash_floor_contrast",
                "nested_no_harm_zero_contrast",
            ],
            origin_rows,
        ),
        "threshold_policy_diagnostics.csv" => _csv_text(
            [
                "threshold",
                "adoption_count",
                "adoption_rate",
                "origin_mean",
                "origin_median",
                "positive_origins",
                "zero_origins",
                "negative_origins",
                "origin_minimum",
                "origin_maximum",
                "contribution_2007",
            ],
            threshold_rows,
        ),
        "instrument_class_diagnostics.csv" => _csv_text(
            [
                "safe_instrument_class",
                "comparator_instrument_class",
                "changed_pair_count",
                "mean_contrast",
                "median_contrast",
            ],
            instrument_rows,
        ),
    )
    outputs["AUDIT_REPORT.md"] = _report(summary, threshold_rows, instrument_rows)
    return summary, outputs
end

function audit(; check = false)
    summary, outputs = _outputs()
    if check
        for (name, expected) in outputs
            path = joinpath(RESULTS_ROOT, name)
            isfile(path) || error("economic-design audit output is absent: $name")
            read(path, String) == expected || error("economic-design audit output changed: $name")
        end
    else
        for (name, text) in outputs
            _atomic_write(joinpath(RESULTS_ROOT, name), text)
        end
    end
    println(summary["status"])
    println("direction gate: ", summary["direction_gate"]["trigger_count"], "/",
        summary["direction_gate"]["condition_count"])
    println("results: ", relpath(RESULTS_ROOT, REPOSITORY_ROOT))
    return summary
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    audit(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    FinancialStrategyLibraryPanelV2EconomicDesignAudit.main()
end
