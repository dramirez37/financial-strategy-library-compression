module MainTextTables

using Printf

include(joinpath(@__DIR__, "search_resource_optimization_counterexamples.jl"))
using .ResourceOptimizationCounterexampleSearch

export check_main_text_tables, generate_main_text_tables, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const SUMMARY_ROOT = joinpath(REPOSITORY_ROOT, "experiments", "results", "summaries")
const TABLE_ROOT = joinpath(REPOSITORY_ROOT, "manuscript", "tables")
const ExactRational = Rational{BigInt}

const OUTPUTS = Dict(
    "greedy_global" => joinpath(TABLE_ROOT, "main_greedy_global_comparison.tex"),
    "canonical_solution" => joinpath(TABLE_ROOT, "main_canonical_stationary_solution.tex"),
    "randomized_summary" => joinpath(TABLE_ROOT, "main_randomized_optimization_summary.tex"),
    "price_elasticities" => joinpath(TABLE_ROOT, "main_randomized_price_elasticities.tex"),
    "financial_resources" => joinpath(TABLE_ROOT, "main_financial_resource_compression.tex"),
    "canonical_safe_appendix" => joinpath(TABLE_ROOT, "appendix_canonical_safe_compression.tex"),
    "canonical_resource_appendix" => joinpath(TABLE_ROOT, "appendix_canonical_resource_summary.tex"),
)

function _split_csv_line(line::AbstractString)
    fields = String[]
    field = IOBuffer()
    quoted = false
    index = firstindex(line)
    while index <= lastindex(line)
        character = line[index]
        if character == '"'
            next_index = nextind(line, index)
            if quoted && next_index <= lastindex(line) && line[next_index] == '"'
                print(field, '"')
                index = next_index
            else
                quoted = !quoted
            end
        elseif character == ',' && !quoted
            push!(fields, String(take!(field)))
        else
            print(field, character)
        end
        index = nextind(line, index)
    end
    quoted && error("unterminated quoted CSV field")
    push!(fields, String(take!(field)))
    return fields
end

function _parse_csv(path::AbstractString)
    lines = readlines(path)
    isempty(lines) && error("empty CSV: $path")
    header = _split_csv_line(first(lines))
    length(unique(header)) == length(header) || error("duplicate CSV header: $path")
    rows = Dict{String,String}[]
    for line in Iterators.drop(lines, 1)
        isempty(strip(line)) && continue
        fields = _split_csv_line(line)
        length(fields) == length(header) || error("malformed CSV row in $path")
        push!(rows, Dict(header .=> fields))
    end
    return rows
end

_csv(name::AbstractString) = _parse_csv(joinpath(SUMMARY_ROOT, name))

function _exact(value::AbstractString)
    isempty(value) && error("empty exact rational")
    parts = split(value, "//")
    length(parts) == 1 && return parse(BigInt, only(parts)) // BigInt(1)
    length(parts) == 2 || error("invalid exact rational: $value")
    return parse(BigInt, parts[1]) // parse(BigInt, parts[2])
end

function _tex_exact(value)
    rational = value isa AbstractString ? _exact(value) : ExactRational(value)
    denominator(rational) == 1 && return string(numerator(rational))
    return "\\frac{$(numerator(rational))}{$(denominator(rational))}"
end

_decimal(value; digits::Integer = 5) = @sprintf("%.*f", digits, Float64(value))

function _only_row(rows; filters...)
    selected = filter(rows) do row
        all(row[string(key)] == string(value) for (key, value) in filters)
    end
    length(selected) == 1 || error("expected one row for filters $(filters)")
    return only(selected)
end

function _mean_exact(values)
    isempty(values) && error("cannot average an empty exact collection")
    return sum(values; init = BigInt(0) // BigInt(1)) / length(values)
end

function _median_exact(values)
    isempty(values) && error("cannot take the median of an empty exact collection")
    ordered = sort(collect(values))
    midpoint = length(ordered) ÷ 2
    isodd(length(ordered)) && return ordered[midpoint + 1]
    return (ordered[midpoint] + ordered[midpoint + 1]) / 2
end

function _tex_library(value::AbstractString)
    replacements = Dict("I" => "I", "A" => "A", "B" => "B", "D" => "D")
    return join((replacements[part] for part in split(value, '+')), "{+}")
end

function _greedy_global_source()
    audit = ResourceOptimizationCounterexampleSearch.write_resource_optimization_audit(; check = true)
    witness = audit["claims"]["02"]["fixture"]["maximum_burden_greedy_counterexample"]
    witness["related_id"] == "CX-OPT-GREEDY-WEIGHT-01" || error("wrong greedy witness")
    source = witness["safe_set"]["source"]
    greedy = witness["trace"]["endpoint"]
    optima = witness["safe_set"]["minimum_weight_libraries"]
    length(optima) == 1 || error("greedy witness must have one minimum-weight library")
    optimum = only(optima)
    source["weight"] == "7//1" || error("unexpected greedy source burden")
    greedy["weight"] == "4//1" || error("unexpected greedy endpoint burden")
    optimum["weight"] == "3//1" || error("unexpected global minimum burden")
    witness["trace"]["endpoint_irreducible"] || error("greedy endpoint is not irreducible")
    witness["trace"]["all_steps_source_safe"] || error("greedy trace is not source-safe")

    strategy_label(id) = id == "s3" ? "s_{12}" : replace(id, r"^s(\d+)$" => s"s_{\1}")
    module_label(id) = replace(id, r"^m(\d+)$" => s"m_{\1}")
    function active_strategies(row)
        active = filter(!=("inactive"), row["strategies"])
        return join(strategy_label.(active), ",")
    end
    closure(row) = "\\{" * join(module_label.(row["modules"]), ",") * "\\}"
    frontier(row) = all(value == "0//1" for value in row["frontier"]) ? "F\\equiv0" : error("unexpected frontier")

    rows = (
        ("Current library", source),
        ("Heaviest-safe-first endpoint", greedy),
        ("Minimum-weight safe library", optimum),
    )
    io = IOBuffer()
    println(io, "% Generated by julia/scripts/generate_main_text_tables.jl.")
    println(io, "% Exact source: experiments/results/resource_optimization_fixtures/02_cx_opt_prune_weight_01.json.")
    println(io, "\\begin{tabular}{@{}lcccc@{}}")
    println(io, "\\toprule")
    println(io, "Representation & Active strategies & Burden (units) & Frontier (payoff units) & Closure \\\\")
    println(io, "\\midrule")
    for (label, row) in rows
        println(io, "$label & \\($(active_strategies(row))\\) & \\($(_tex_exact(row["weight"]))\\) & \\($(frontier(row))\\) & \\($(closure(row))\\) \\\\")
    end
    println(io, "\\bottomrule")
    println(io, "\\end{tabular}")
    return String(take!(io))
end

function _canonical_solution_source()
    rows = _csv("unified_canonical_resource_channel_elasticities.csv")
    length(rows) == 16 || error("canonical channel source must contain 16 rows")
    representatives = Dict("K0" => "0", "K1" => "1", "K2" => "4")
    action_label = Dict(
        "research:discover" => "Discover",
        "research:scale" => "Scale",
        "continue" => "Continue",
    )
    io = IOBuffer()
    println(io, "% Generated by julia/scripts/generate_main_text_tables.jl.")
    println(io, "% Exact source: experiments/results/summaries/unified_canonical_resource_channel_elasticities.csv.")
    println(io, "\\begin{tabular}{@{}llrll@{}}")
    println(io, "\\toprule")
    println(io, "State & Belief & \\(V^\\star\\) (payoff units) & \\(\\pi^\\star\\) & Winning margin (payoff units) \\\\")
    println(io, "\\midrule")
    for state in ("K0", "K1", "K2"), belief in ("low", "high")
        row = _only_row(rows; mask = representatives[state], belief)
        row["compressed_state"] == state || error("canonical state/mask mismatch")
        state_rows = filter(
            candidate -> candidate["compressed_state"] == state && candidate["belief"] == belief,
            rows,
        )
        for field in ("productive_value", "action", "action_margin")
            all(candidate[field] == row[field] for candidate in state_rows) ||
                error("canonical compressed-state invariance failed for $state/$belief/$field")
        end
        belief_tex = belief == "low" ? "\\ell" : "h"
        state_tex = replace(state, r"^K(\d+)$" => s"K_{\1}")
        println(io, "\\($state_tex\\)&\\($belief_tex\\)&\\($(_tex_exact(row["productive_value"]))\\)&$(action_label[row["action"]])&\\($(_tex_exact(row["action_margin"]))\\)\\\\")
    end
    println(io, "\\bottomrule")
    println(io, "\\end{tabular}")
    return String(take!(io))
end

function _randomized_summary_source()
    trials = _csv("randomized_library_v2_optimization_v1_trials.csv")
    length(trials) == 1024 || error("randomized optimization source must contain 1024 trials")
    all(row["arithmetic"] == "Rational{BigInt}" for row in trials) || error("randomized arithmetic drift")
    all(row["global_enumeration_gate"] == "true" for row in trials) || error("randomized enumeration gate failed")

    safe_weight = _mean_exact(_exact(row["safe_weight_compression_ratio"]) for row in trials)
    safe_cardinality = _mean_exact(_exact(row["safe_cardinality_compression_ratio"]) for row in trials)
    greedy_gaps = [_exact(row["greedy_optimality_gap"]) for row in trials]
    positive_losses = count(row["frontier_only_any_positive_value_loss"] == "true" for row in trials)
    normalized_losses = [_exact(row["frontier_only_normalized_value_loss"]) for row in trials]
    positive_normalized = filter(>(0), normalized_losses)
    registered_nonconcavity = count(row["registered_capacity_nonconcavity"] == "true" for row in trials)
    attainable_nonconcavity = count(row["attainable_capacity_nonconcavity"] == "true" for row in trials)
    breakpoint_counts = [_exact(row["lambda_breakpoint_count"]) for row in trials]
    positive_breakpoint_counts = [_exact(row["positive_lambda_breakpoint_count"]) for row in trials]

    safe_weight == 31 // 160 || error("safe-weight mean drift")
    safe_cardinality == 1 // 8 || error("safe-cardinality mean drift")
    maximum(greedy_gaps) == 0 && count(>(0), greedy_gaps) == 0 || error("greedy gap drift")
    positive_losses == 398 || error("frontier-only positive-loss count drift")
    registered_nonconcavity == 97 || error("registered nonconcavity count drift")
    attainable_nonconcavity == 921 || error("attainable nonconcavity count drift")
    mean_loss = _mean_exact(normalized_losses)
    conditional_loss = _mean_exact(positive_normalized)
    median_loss = _median_exact(normalized_losses)
    maximum_loss = maximum(normalized_losses)
    maximum_loss == 84963 // 222163 || error("maximum normalized loss drift")
    median_loss == 0 || error("normalized-loss median drift")
    mean_breakpoints = _mean_exact(breakpoint_counts)
    mean_positive_breakpoints = _mean_exact(positive_breakpoint_counts)
    mean_breakpoints == 1043 // 256 || error("breakpoint-count mean drift")
    mean_positive_breakpoints == 787 // 256 || error("positive-breakpoint mean drift")

    capacity = _csv("randomized_library_v2_optimization_v1_capacity.csv")
    b75 = filter(row -> row["grid"] == "registered" && row["point_id"] == "B75", capacity)
    length(b75) == 1024 || error("registered B75 source must contain 1024 rows")
    mean_b75 = _mean_exact(_exact(row["normalized_total_value"]) for row in b75)

    io = IOBuffer()
    println(io, "% Generated by julia/scripts/generate_main_text_tables.jl.")
    println(io, "% Exact sources: randomized_library_v2_optimization_v1_{trials,capacity}.csv.")
    println(io, "\\begin{tabular}{@{}>{\\raggedright\\arraybackslash}p{0.38\\linewidth}>{\\raggedright\\arraybackslash}p{0.53\\linewidth}@{}}")
    println(io, "\\toprule")
    println(io, "Registered estimand (unit) & Exact result or explicitly rendered mean \\\\")
    println(io, "\\midrule")
    println(io, "Safe resources retained (share of source) & Mean burden \\($(_tex_exact(safe_weight))\\); mean cardinality \\($(_tex_exact(safe_cardinality))\\) \\\\")
    println(io, "Registered deletion-order gap (burden units) & Mean and maximum \\(0\\); positive in \\(0/1024\\) trials \\\\")
    println(io, "Frontier-only loss (normalized value units) & Positive in \\($positive_losses/1024\\); mean \\(\\approx$(_decimal(mean_loss))\\), conditional-positive mean \\(\\approx$(_decimal(conditional_loss))\\), median \\(0\\), maximum \\($(_tex_exact(maximum_loss))\\) \\\\")
    println(io, "Capacity value at 75\\% source burden (normalized value units) & Across-trial mean \\(\\approx$(_decimal(mean_b75; digits = 4))\\) \\\\")
    println(io, "Capacity nonconcavity (trial count) & \\($registered_nonconcavity/1024\\) on the registered grid; \\($attainable_nonconcavity/1024\\) over all attainable burdens \\\\")
    println(io, "Resource-price breakpoints (count per trial) & Mean total \\($(_tex_exact(mean_breakpoints))\\) \\(\\approx$(_decimal(mean_breakpoints; digits = 3))\\); mean strictly positive \\($(_tex_exact(mean_positive_breakpoints))\\) \\(\\approx$(_decimal(mean_positive_breakpoints; digits = 3))\\) \\\\")
    println(io, "\\bottomrule")
    println(io, "\\end{tabular}")
    return String(take!(io))
end

function _price_elasticity_source()
    rows = _csv("randomized_library_v2_optimization_v1_elasticities.csv")
    length(rows) == 4096 || error("price elasticity source must contain 4096 rows")
    interval_order = ("E025_050", "E050_100", "E100_200", "E200_400")
    interval_label = Dict(
        "E025_050" => "\\frac14\\to\\frac12",
        "E050_100" => "\\frac12\\to1",
        "E100_200" => "1\\to2",
        "E200_400" => "2\\to4",
    )
    io = IOBuffer()
    println(io, "% Generated by julia/scripts/generate_main_text_tables.jl.")
    println(io, "% Exact source: experiments/results/summaries/randomized_library_v2_optimization_v1_elasticities.csv.")
    println(io, "\\begin{tabular}{@{}ccccc@{}}")
    println(io, "\\toprule")
    println(io, "Price arc & Demand elasticity & Productive-value elasticity & Operational contribution & Generative contribution \\\\")
    println(io, "\\midrule")
    for interval in interval_order
        selected = filter(row -> row["interval_id"] == interval, rows)
        length(selected) == 1024 || error("price interval $interval is incomplete")
        all(row["demand_defined"] == "true" for row in selected) || error("undefined demand elasticity in $interval")
        all(row["channel_defined"] == "true" for row in selected) || error("undefined channel elasticity in $interval")
        metrics = (
            "resource_demand_elasticity",
            "productive_value_elasticity",
            "operational_contribution",
            "generative_contribution",
        )
        means = [_mean_exact(_exact(row[metric]) for row in selected) for metric in metrics]
        means[3] + means[4] == means[2] || error("channel decomposition mean failed for $interval")
        cells = join(("\\(\\approx" * _decimal(value) * "\\)" for value in means), " & ")
        println(io, "\\($(interval_label[interval])\\) & $cells \\\\")
    end
    println(io, "\\bottomrule")
    println(io, "\\end{tabular}")
    return String(take!(io))
end

function _financial_resource_source()
    rows = _csv("financial_resource_optimization_solutions.csv")
    length(rows) == 24 || error("financial resource solution source must contain 24 rows")
    audits = (
        ("locked_terminal_v1", "Terminal"),
        ("annual_walk_forward_v2", "Annual"),
    )
    io = IOBuffer()
    println(io, "% Generated by julia/scripts/generate_main_text_tables.jl.")
    println(io, "% Exact source: experiments/results/summaries/financial_resource_optimization_solutions.csv.")
    println(io, "\\begin{tabular}{@{}lccccc@{}}")
    println(io, "\\toprule")
    println(io, "Audit & Source & Stepwise safe & HiGHS min-card. & HiGHS min-\\(W_v\\) & Frontier-only \\\\")
    println(io, " & \\((|L|,W_v)\\) & \\((|L|,W_v)\\) & \\(|L|\\) & \\((|L|,W_v)\\) & \\((|L|,W_v)\\) \\\\")
    println(io, "\\midrule")
    for (audit_id, label) in audits
        stepwise = _only_row(rows; audit_id, schedule_id = "validation_computation", method = "stepwise_safe")
        weighted = _only_row(rows; audit_id, schedule_id = "validation_computation", method = "global_safe")
        cardinality = _only_row(rows; audit_id, schedule_id = "uniform_cardinality", method = "global_safe")
        frontier = _only_row(rows; audit_id, schedule_id = "validation_computation", method = "frontier_only")
        weighted["solver_claimed_optimal"] == "true" && weighted["solver_termination_status"] == "OPTIMAL" || error("weighted solver status failed")
        cardinality["solver_claimed_optimal"] == "true" && cardinality["solver_termination_status"] == "OPTIMAL" || error("cardinality solver status failed")
        all(row["exact_postsolve_selected_library_verified"] == "true" for row in (stepwise, weighted, cardinality)) || error("financial exact recheck failed")
        all(row["exact_global_optimality_by_enumeration"] == "false" for row in (weighted, cardinality)) || error("financial optimum unexpectedly enumerated")
        all(row["solver_tolerances_used_as_proof"] == "false" for row in (weighted, cardinality)) || error("solver tolerance misuse")
        source_pair = "($(stepwise["source_size"]),$(_tex_exact(stepwise["source_burden"])))"
        stepwise_pair = "($(stepwise["selected_size"]),$(_tex_exact(stepwise["selected_burden"])))"
        weighted_pair = "($(weighted["selected_size"]),$(_tex_exact(weighted["selected_burden"])))"
        frontier_pair = "($(frontier["selected_size"]),$(_tex_exact(frontier["selected_burden"])))"
        println(io, "$label & \\($source_pair\\) & \\($stepwise_pair\\) & \\($(cardinality["selected_size"])\\) & \\($weighted_pair\\) & \\($frontier_pair\\) \\\\")
    end
    println(io, "\\bottomrule")
    println(io, "\\end{tabular}")
    return String(take!(io))
end

function _canonical_safe_appendix_source()
    rows = _csv("unified_canonical_resource_safe_compression.csv")
    length(rows) == 24 || error("canonical safe-compression source must contain 24 rows")
    schedules = ("equal_active", "carrier_heavy", "descendant_heavy")
    groups = (
        (("I", "I+A", "I+B", "I+D"), "source itself"),
        (("I+A+B",), "I+A or I+B"),
        (("I+A+D", "I+B+D"), "I+D"),
        (("I+A+B+D",), "I+D"),
    )
    io = IOBuffer()
    println(io, "% Generated by julia/scripts/generate_main_text_tables.jl.")
    println(io, "% Exact source: experiments/results/summaries/unified_canonical_resource_safe_compression.csv.")
    println(io, "\\begin{tabular}{@{}>{\\raggedright\\arraybackslash}p{0.27\\linewidth}>{\\raggedright\\arraybackslash}p{0.30\\linewidth}>{\\raggedright\\arraybackslash}p{0.33\\linewidth}@{}}")
    println(io, "\\toprule")
    println(io, "Raw source & Minimum-resource safe library or libraries & Burden reduction by schedule (equal, carrier-heavy, descendant-heavy) \\\\")
    println(io, "\\midrule")
    for (sources, expected_optimum) in groups
        source_rows = [_only_row(rows; schedule = first(schedules), source_library = source) for source in sources]
        reductions = String[]
        for schedule in schedules
            schedule_rows = [_only_row(rows; schedule, source_library = source) for source in sources]
            unique_reductions = unique(row["burden_reduction"] for row in schedule_rows)
            length(unique_reductions) == 1 || error("grouped safe-compression reduction mismatch")
            push!(reductions, _tex_exact(only(unique_reductions)))
        end
        optimum = first(source_rows)["optimal_libraries"]
        if expected_optimum != "source itself"
            expected_csv = replace(expected_optimum, " or " => ";")
            optimum == expected_csv || error("canonical safe optimum drift for $(first(sources))")
        end
        source_tex = join(("\\(" * _tex_library(source) * "\\)" for source in sources), ", ")
        if expected_optimum == "source itself"
            rendered_optimum = "source itself"
        else
            rendered_optimum = join(("\\(" * _tex_library(item) * "\\)" for item in split(expected_optimum, " or ")), " or ")
        end
        println(io, "$source_tex & $rendered_optimum & \\(($(join(reductions, ",")))\\) \\\\")
    end
    println(io, "\\bottomrule")
    println(io, "\\end{tabular}")
    return String(take!(io))
end

function _canonical_resource_appendix_source()
    capacity = _csv("unified_canonical_resource_capacity.csv")
    switching = _csv("unified_canonical_resource_switching_prices.csv")
    all(row["all_optima_feasible"] == "true" && row["ties_complete"] == "true" for row in capacity) || error("canonical capacity gate failed")
    schedules = (
        ("equal_active", "Equal active"),
        ("carrier_heavy", "Carrier heavy"),
        ("descendant_heavy", "Descendant heavy"),
    )
    io = IOBuffer()
    println(io, "% Generated by julia/scripts/generate_main_text_tables.jl.")
    println(io, "% Exact sources: unified_canonical_resource_{capacity,switching_prices}.csv.")
    println(io, "\\begin{tabular}{@{}p{0.19\\linewidth}p{0.43\\linewidth}p{0.28\\linewidth}@{}}")
    println(io, "\\toprule")
    println(io, "Weight schedule & Low-belief capacity path & Positive globally active switch prices \\((\\ell,h)\\) \\\\")
    println(io, "\\midrule")
    for (schedule, label) in schedules
        selected = filter(row -> row["schedule"] == schedule && row["belief"] == "low", capacity)
        sort!(selected; by = row -> _exact(row["capacity"]))
        path = if schedule == "descendant_heavy"
            "\\(B=1:I;\\ B=2:I{+}A\\text{ or }I{+}B;\\ B\\ge3:I{+}D\\)"
        else
            "\\(B=1:I;\\ B\\ge2:I{+}D\\)"
        end
        for row in selected
            expected = if _exact(row["capacity"]) == 1
                "I"
            elseif schedule == "descendant_heavy" && _exact(row["capacity"]) == 2
                "I+A;I+B"
            else
                occursin("I+D", row["optimal_libraries"]) ? row["optimal_libraries"] : error("capacity path drift")
            end
            occursin(expected, row["optimal_libraries"]) || error("capacity path mismatch")
        end
        prices = String[]
        for belief in ("low", "high")
            active = filter(row -> row["schedule"] == schedule && row["belief"] == belief && row["globally_active"] == "true" && !isempty(row["switching_price"]) && _exact(row["switching_price"]) > 0, switching)
            unique_prices = unique(row["switching_price"] for row in active)
            length(unique_prices) == 1 || error("expected one positive active switch price")
            push!(prices, _tex_exact(only(unique_prices)))
        end
        println(io, "$label & $path & \\($(join(prices, ",\\ "))\\) \\\\")
    end
    println(io, "\\bottomrule")
    println(io, "\\end{tabular}")
    return String(take!(io))
end

function _payloads()
    return Dict(
        OUTPUTS["greedy_global"] => _greedy_global_source(),
        OUTPUTS["canonical_solution"] => _canonical_solution_source(),
        OUTPUTS["randomized_summary"] => _randomized_summary_source(),
        OUTPUTS["price_elasticities"] => _price_elasticity_source(),
        OUTPUTS["financial_resources"] => _financial_resource_source(),
        OUTPUTS["canonical_safe_appendix"] => _canonical_safe_appendix_source(),
        OUTPUTS["canonical_resource_appendix"] => _canonical_resource_appendix_source(),
    )
end

function generate_main_text_tables(; check::Bool = false)
    for (path, source) in _payloads()
        if check
            isfile(path) || error("missing generated table: $path")
            read(path, String) == source || error("generated table drift: $path")
        else
            mkpath(dirname(path))
            open(path, "w") do io
                print(io, source)
            end
        end
    end
    return OUTPUTS
end

check_main_text_tables() = generate_main_text_tables(; check = true)

function main(args = ARGS)
    check = args == ["--check"]
    isempty(args) || check || error("usage: generate_main_text_tables.jl [--check]")
    generate_main_text_tables(; check)
    println(check ? "main-text tables match exact sources" : "generated main-text tables")
    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
