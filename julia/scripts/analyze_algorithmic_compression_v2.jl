#!/usr/bin/env julia

"""
Generate the registered analysis of the locked and independently audited
Registered Algorithmic Compression Benchmark v2.

The script reads committed final artifacts only. It does not invoke any
benchmark algorithm or solver. All generated table rows retain raw-record
paths and hashes through `analysis_row_trace.csv` and the figure-data tables.
"""
module AlgorithmicCompressionAnalysisV2

using LinearAlgebra
using Printf
using SHA
using TOML

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const STUDY_ROOT = joinpath(REPOSITORY_ROOT, "experiments", "algorithmic_compression_v2")
const RESULTS_ROOT = joinpath(STUDY_ROOT, "results")
const TABLE_ROOT = joinpath(REPOSITORY_ROOT, "journal", "aor", "tables")
const FIGURE_ROOT = joinpath(REPOSITORY_ROOT, "journal", "aor", "figures")
const REPORT_PATH = joinpath(REPOSITORY_ROOT, "journal", "aor", "reports", "ALGORITHMIC_RESULTS.md")

const SOLVED_STATUSES = Set(["SOLVED", "SOLVED_BY_EXACT_PREPROCESSING"])
const EXACT_ALGORITHMS = ["complete_enumeration", "requirement_mask_dp"]
const MIP_ALGORITHM = "jump_highs_tagged_cover"
const HEURISTIC_ALGORITHMS = [
    "weighted_greedy",
    "cardinality_greedy",
    "weighted_greedy_reverse_delete",
    "heaviest_safe_first",
    "lightest_safe_first",
    "maximum_immediate_burden_release",
    "minimum_unique_carrier_exposure",
    "declared_source_order",
    "random_order_rechecked_deletion",
    "multistart_random_rechecked_deletion_32",
]
const DELETION_ALGORITHMS = [
    "heaviest_safe_first",
    "lightest_safe_first",
    "maximum_immediate_burden_release",
    "minimum_unique_carrier_exposure",
    "declared_source_order",
    "random_order_rechecked_deletion",
    "multistart_random_rechecked_deletion_32",
]
const ALGORITHM_ORDER = vcat(EXACT_ALGORITHMS, [MIP_ALGORITHM], HEURISTIC_ALGORITHMS)
const PRIMARY_VARIANT = Dict(
    "complete_enumeration" => "mandatory_only",
    "requirement_mask_dp" => "mandatory_only",
    "jump_highs_tagged_cover" => "full_fixed_point",
    (algorithm => "mandatory_only" for algorithm in HEURISTIC_ALGORITHMS)...,
)

const ALGORITHM_LABEL = Dict(
    "complete_enumeration" => "Enumeration",
    "requirement_mask_dp" => "Mask DP",
    "jump_highs_tagged_cover" => "HiGHS MIP",
    "weighted_greedy" => "Weighted greedy",
    "cardinality_greedy" => "Cardinality greedy",
    "weighted_greedy_reverse_delete" => "Weighted greedy + reverse deletion",
    "heaviest_safe_first" => "Heaviest safe first",
    "lightest_safe_first" => "Lightest safe first",
    "maximum_immediate_burden_release" => "Maximum immediate release",
    "minimum_unique_carrier_exposure" => "Minimum unique-carrier exposure",
    "declared_source_order" => "Declared source order",
    "random_order_rechecked_deletion" => "Random-order deletion",
    "multistart_random_rechecked_deletion_32" => "32-start random deletion",
)

const PALETTE = ["#3B6FB6", "#C69214", "#D36B2C", "#7A8B32", "#B65C7A"]
const INK = "#24313D"
const MID = "#66727E"
const GRID = "#D9DEE3"
const LIGHT = "#F4F6F8"
const DASHES = ["", "8 4", "2 3", "10 3 2 3", "5 3 1 3"]

_string(value) = value === missing ? "" : string(value)

function parse_exact(value)
    value === missing && return missing
    text = String(value)
    isempty(text) && return missing
    text == "UNAVAILABLE" && return missing
    parts = split(text, "//")
    length(parts) == 2 || error("invalid exact rational: $text")
    return parse(BigInt, parts[1]) // parse(BigInt, parts[2])
end

encode_exact(value) = value === missing ? "UNAVAILABLE" : "$(numerator(value))//$(denominator(value))"

function nested_get(data, keys...; default = missing)
    current = data
    for key in keys
        current isa AbstractDict || return default
        haskey(current, key) || return default
        current = current[key]
    end
    return current
end

function parse_float(value)
    value === missing && return missing
    if value isa AbstractDict
        get(value, "available", false) === true || return missing
        return parse_float(get(value, "value", missing))
    end
    value isa Number && return Float64(value)
    isempty(String(value)) && return missing
    return parse(Float64, String(value))
end

function parse_integer(value)
    value === missing && return missing
    if value isa AbstractDict
        get(value, "available", false) === true || return missing
        return parse_integer(get(value, "value", missing))
    end
    value isa Integer && return Int(value)
    isempty(String(value)) && return missing
    return parse(Int, String(value))
end

function csv_fields(line)
    fields = String[]
    buffer = IOBuffer()
    quoted = false
    index = firstindex(line)
    while index <= lastindex(line)
        char = line[index]
        if quoted
            if char == '"'
                nextindex_value = nextind(line, index)
                if nextindex_value <= lastindex(line) && line[nextindex_value] == '"'
                    write(buffer, '"')
                    index = nextindex_value
                else
                    quoted = false
                end
            else
                write(buffer, char)
            end
        elseif char == '"'
            quoted = true
        elseif char == ','
            push!(fields, String(take!(buffer)))
        else
            write(buffer, char)
        end
        index = nextind(line, index)
    end
    push!(fields, String(take!(buffer)))
    quoted && error("unterminated quoted CSV field")
    return fields
end

function read_csv(path)
    lines = readlines(path)
    isempty(lines) && return Dict{String,String}[]
    header = csv_fields(lines[1])
    rows = Dict{String,String}[]
    for line in lines[2:end]
        isempty(line) && continue
        values = csv_fields(line)
        length(values) == length(header) || error("CSV width mismatch in $path")
        push!(rows, Dict(header[i] => values[i] for i in eachindex(header)))
    end
    return rows
end

function csv_escape(value)
    text = _string(value)
    if occursin(',', text) || occursin('"', text) || occursin('\n', text)
        return "\"" * replace(text, "\"" => "\"\"") * "\""
    end
    return text
end

function write_csv(path, columns, rows)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, join(columns, ','))
        for row in rows
            println(io, join((csv_escape(get(row, column, "")) for column in columns), ','))
        end
    end
    return path
end

function latex_escape(value)
    text = _string(value)
    escaped = IOBuffer()
    replacements = Dict(
        '\\' => "\\textbackslash{}",
        '&' => "\\&",
        '%' => "\\%",
        '$' => "\\\$",
        '#' => "\\#",
        '_' => "\\_",
        '{' => "\\{",
        '}' => "\\}",
        '~' => "\\textasciitilde{}",
        '^' => "\\textasciicircum{}",
    )
    for character in text
        write(escaped, get(replacements, character, string(character)))
    end
    return String(take!(escaped))
end

function latex_display(value)
    text = _string(value)
    return get(Dict(
        "UNAVAILABLE" => "--",
        "EXACT_FINITE" => "exact finite",
        "MIP_OPTIMAL_EXACTLY_RECHECKED" => "MIP-optimal, exactly rechecked",
        "SOLVED_BY_EXACT_PREPROCESSING" => "exact preprocessing",
    ), text, text)
end

function write_tex(path, columns, rows; caption, label, longtable = true, alignment = nothing)
    mkpath(dirname(path))
    environment = longtable ? "longtable" : "tabular"
    alignment_spec = alignment === nothing ? "l" * repeat("r", max(length(columns) - 1, 0)) : alignment
    headers = latex_escape.(replace.(columns, "_" => " "))
    open(path, "w") do io
        println(io, "% Generated by julia/scripts/analyze_algorithmic_compression_v2.jl")
        println(io, "{\\footnotesize")
        longtable && println(io, "\\begin{longtable}{$alignment_spec}")
        !longtable && println(io, "\\begin{tabular}{$alignment_spec}")
        println(io, "\\caption{", latex_escape(caption), "}\\label{", label, "}\\\\")
        println(io, "\\toprule")
        println(io, join(headers, " & "), " \\\\")
        println(io, "\\midrule")
        longtable && println(io, "\\endfirsthead\n\\toprule\n", join(headers, " & "), " \\\\\n\\midrule\n\\endhead")
        for row in rows
            println(io, join((latex_escape(latex_display(get(row, column, ""))) for column in columns), " & "), " \\\\")
        end
        println(io, "\\bottomrule")
        println(io, "\\end{$environment}")
        println(io, "}")
    end
    return path
end

function sha256_file(path)
    return bytes2hex(open(SHA.sha256, path))
end

function empirical_quantile(values, probability)
    isempty(values) && return missing
    sorted = sort(collect(values))
    length(sorted) == 1 && return sorted[1]
    # Deterministic Hyndman--Fan type 7 interpolation. The registered levels
    # were fixed, but the plan did not name an interpolation convention.
    h = (length(sorted) - 1) * probability + 1
    lower = floor(Int, h)
    upper = ceil(Int, h)
    lower == upper && return sorted[lower]
    fraction = h - lower
    return sorted[lower] + fraction * (sorted[upper] - sorted[lower])
end

mean_value(values) = isempty(values) ? missing : sum(values) / length(values)

function summarize(values)
    clean = [value for value in values if value !== missing]
    isempty(clean) && return Dict{String,Any}(
        "n" => 0, "mean" => missing, "q10" => missing, "q25" => missing,
        "median" => missing, "q75" => missing, "q90" => missing,
        "iqr" => missing, "minimum" => missing, "maximum" => missing,
    )
    q25 = empirical_quantile(clean, 0.25)
    q75 = empirical_quantile(clean, 0.75)
    return Dict{String,Any}(
        "n" => length(clean),
        "mean" => mean_value(clean),
        "q10" => empirical_quantile(clean, 0.10),
        "q25" => q25,
        "median" => empirical_quantile(clean, 0.50),
        "q75" => q75,
        "q90" => empirical_quantile(clean, 0.90),
        "iqr" => q75 - q25,
        "minimum" => minimum(clean),
        "maximum" => maximum(clean),
    )
end

format_float(value; digits = 3) = value === missing ? "UNAVAILABLE" : @sprintf("%.*f", digits, Float64(value))
format_percent(numerator, denominator) = denominator == 0 ? "UNAVAILABLE" : @sprintf("%.1f%%", 100 * numerator / denominator)

function format_summary_value(value; exact = false, digits = 4)
    value === missing && return "UNAVAILABLE"
    exact && value isa Rational && return encode_exact(value)
    return @sprintf("%.*g", digits, Float64(value))
end

function effect_level(value, low, high)
    value == low && return -1.0
    value == high && return 1.0
    error("unexpected registered factor level $value (expected $low or $high)")
end

function structure_covariates(spec)
    strategy_count = parse(Int, spec["strategy_count"])
    requirement_count = parse(Int, spec["tagged_requirement_count"])
    frontier_count = parse(Int, spec["frontier_row_count"])
    return Dict(
        "log2_strategy_count" => log2(strategy_count),
        "log2_requirement_count" => log2(requirement_count),
        "frontier_row_share" => frontier_count / requirement_count,
        "coverage_density" => effect_level(spec["coverage_density_level"], "one_eighth", "three_eighths"),
        "module_overlap" => effect_level(spec["module_overlap_level"], "low_clustered", "high_clustered"),
        "bundle_prevalence" => effect_level(spec["bundle_prevalence_level"], "zero", "one_eighth"),
        "unique_carrier_frequency" => effect_level(spec["unique_carrier_frequency_level"], "zero", "one_eighth"),
        "weight_dispersion" => effect_level(spec["weight_dispersion_level"], "low_1_to_3", "high_powers_of_two"),
        "frontier_module_correlation" => effect_level(spec["frontier_module_correlation_level"], "independent", "positive_aligned"),
        "replicate_2" => parse(Int, spec["replicate_id"]) == 2 ? 1.0 : 0.0,
    )
end

function primary_run(run)
    return get(PRIMARY_VARIANT, run["algorithm_id"], "") == run["preprocessing_variant"]
end

function size_label(spec)
    if spec["family"] == "adversarial"
        identifier = spec["instance_id"]
        endswith(identifier, "S01") && return "small"
        endswith(identifier, "S02") && return "medium"
        return "large"
    end
    return "N$(spec["strategy_count"])-R$(spec["tagged_requirement_count"])"
end

function compact_preprocessing(record, method)
    audit = missing
    preprocessing = nested_get(method, "preprocessing"; default = missing)
    if preprocessing isa AbstractDict && haskey(preprocessing, "audit")
        audit = preprocessing["audit"]
    else
        sensitivity = nested_get(record, "worker", "full_preprocessing_sensitivity"; default = missing)
        if sensitivity isa AbstractDict && get(sensitivity, "available", false) && haskey(sensitivity, "audit")
            audit = sensitivity["audit"]
        end
    end
    audit === missing && return Dict{String,Any}(
        "available" => false,
        "original_variables" => missing,
        "reduced_variables" => missing,
        "variables_removed" => missing,
        "original_requirements" => missing,
        "reduced_requirements" => missing,
        "requirements_removed" => missing,
        "forced_selections" => missing,
        "fixed_point_iterations" => missing,
        "rule_counts" => Dict{String,Any}(),
    )
    original_variables = parse_integer(get(audit, "original_variable_count", missing))
    reduced_variables = parse_integer(get(audit, "reduced_variable_count", missing))
    original_requirements = parse_integer(get(audit, "original_requirement_count", missing))
    reduced_requirements = parse_integer(get(audit, "reduced_requirement_count", missing))
    return Dict{String,Any}(
        "available" => true,
        "original_variables" => original_variables,
        "reduced_variables" => reduced_variables,
        "variables_removed" => original_variables - reduced_variables,
        "original_requirements" => original_requirements,
        "reduced_requirements" => reduced_requirements,
        "requirements_removed" => original_requirements - reduced_requirements,
        "forced_selections" => length(get(audit, "forced_strategy_indices", Any[])),
        "fixed_point_iterations" => parse_integer(get(audit, "fixed_point_iterations", missing)),
        "rule_counts" => get(audit, "rule_counts", Dict{String,Any}()),
    )
end

function load_instance_metadata(specs)
    metadata = Dict{String,Dict{String,Any}}()
    for spec in values(specs)
        id = spec["instance_id"]
        generation_path = joinpath(RESULTS_ROOT, "generation", "$id.toml")
        generation = isfile(generation_path) ? TOML.parsefile(generation_path) : Dict{String,Any}()
        instance_path = joinpath(RESULTS_ROOT, "instances", "$id.toml")
        source_burden = missing
        if isfile(instance_path)
            instance = TOML.parsefile(instance_path)
            weights = [parse_exact(strategy["weight"]) for strategy in get(instance, "strategies", Any[])]
            source_burden = sum(weights; init = BigInt(0) // BigInt(1))
        end
        realized = get(generation, "realized", Dict{String,Any}())
        metadata[id] = Dict{String,Any}(
            "generation_status" => String(get(generation, "status", "MISSING")),
            "generation_path" => isfile(generation_path) ? relpath(generation_path, REPOSITORY_ROOT) : "",
            "instance_path" => isfile(instance_path) ? relpath(instance_path, REPOSITORY_ROOT) : "",
            "instance_sha256" => isfile(instance_path) ? sha256_file(instance_path) : "",
            "source_burden" => source_burden,
            "realized_active_coverage_density" => get(realized, "active_coverage_density", "UNAVAILABLE"),
            "realized_module_overlap" => get(realized, "mean_pairwise_module_jaccard", "UNAVAILABLE"),
            "realized_bundle_prevalence" => get(realized, "bundle_prevalence", "UNAVAILABLE"),
            "realized_unique_carrier_frequency" => get(realized, "unique_carrier_frequency", "UNAVAILABLE"),
            "realized_frontier_module_association" => get(realized, "frontier_module_rank_association", "UNAVAILABLE"),
        )
    end
    return metadata
end

function load_run(row, spec)
    record_path = joinpath(REPOSITORY_ROOT, row["record_path"])
    record = TOML.parsefile(record_path)
    worker = get(record, "worker", Dict{String,Any}())
    method = get(worker, "method_result", Dict{String,Any}())
    exact_burden = parse_exact(row["exact_burden"])
    accepted = row["candidate_accepted"] == "true"
    exact_feasible = row["exact_feasible"] == "true"
    solved = row["status"] in SOLVED_STATUSES && accepted && exact_feasible
    wall_ns = isempty(row["wall_clock_ns"]) ? missing : parse(BigInt, row["wall_clock_ns"])
    wall_seconds = wall_ns === missing ? missing : Float64(wall_ns) / 1.0e9
    time_limit = parse(Float64, row["time_limit_seconds"])
    par2 = solved && wall_seconds !== missing ? wall_seconds : 2.0 * time_limit
    mip = get(method, "solver_diagnostics", Dict{String,Any}())
    counters = get(method, "counters", Dict{String,Any}())
    starts = get(method, "start_summaries", Any[])
    first_start_burden = isempty(starts) ? missing : parse_exact(starts[1]["exact_burden"])
    start_burdens = isempty(starts) ? Rational{BigInt}[] : [parse_exact(start["exact_burden"]) for start in starts]
    best_start_burden = isempty(start_burdens) ? missing : minimum(start_burdens)
    preprocessing = compact_preprocessing(record, method)
    selected_indices = get(worker, "selected_original_strategy_indices", Int[])
    result = Dict{String,Any}(
        "instance_id" => row["instance_id"],
        "family" => row["family"],
        "mechanism" => row["mechanism"],
        "algorithm_id" => row["algorithm_id"],
        "preprocessing_variant" => row["preprocessing_variant"],
        "status" => row["status"],
        "failure_code" => row["failure_code"],
        "candidate_accepted" => accepted,
        "exact_feasible" => exact_feasible,
        "solved" => solved,
        "exact_burden" => exact_burden,
        "wall_clock_seconds" => wall_seconds,
        "par2_seconds" => par2,
        "peak_memory_bytes" => isempty(row["peak_memory_bytes"]) ? missing : parse(BigInt, row["peak_memory_bytes"]),
        "time_limit_seconds" => time_limit,
        "record_path" => row["record_path"],
        "record_sha256" => row["record_sha256"],
        "worker_lane" => parse(Int, row["worker_lane"]),
        "launch_wave" => parse(Int, row["launch_wave"]),
        "global_schedule_position" => parse(Int, row["global_schedule_position"]),
        "evidence_class" => String(get(worker, "evidence_class", get(method, "evidence_class", "UNAVAILABLE"))),
        "selected_indices" => selected_indices,
        "selected_cardinality" => accepted ? length(selected_indices) : missing,
        "search_complete" => get(method, "search_complete", missing),
        "solver_claimed_optimal" => get(method, "solver_claimed_optimal", false),
        "solver_invoked" => get(mip, "solver_invoked", false),
        "termination_status" => String(get(mip, "termination_status", "UNAVAILABLE")),
        "mip_node_count" => parse_integer(get(mip, "node_count", missing)),
        "mip_best_bound" => parse_float(get(mip, "best_bound", missing)),
        "mip_objective_value" => parse_float(get(mip, "objective_value", missing)),
        "mip_reported_gap" => parse_float(get(mip, "reported_relative_gap", missing)),
        "mip_presolve_variables_removed" => parse_integer(get(mip, "presolve_variables_removed", missing)),
        "mip_presolve_rows_removed" => parse_integer(get(mip, "presolve_rows_removed", missing)),
        "dp_state_layer_pairs" => parse_integer(get(counters, "state_layer_pairs_visited", missing)),
        "dp_transitions" => parse_integer(get(counters, "transitions_evaluated", missing)),
        "dp_final_states" => parse_integer(get(counters, "final_reachable_states", missing)),
        "frontier_checks" => parse_integer(get(counters, "frontier_checks", missing)),
        "closure_checks" => parse_integer(get(counters, "closure_checks", missing)),
        "complete_scans" => parse_integer(get(counters, "complete_scans", missing)),
        "irreducible" => nested_get(method, "irreducibility_certificate", "no_safe_nonmandatory_deletion"; default = missing),
        "deletion_steps" => haskey(method, "deletion_trace") ? length(method["deletion_trace"]) : missing,
        "greedy_steps" => haskey(method, "step_trace") ? length(method["step_trace"]) : missing,
        "first_start_burden" => first_start_burden,
        "best_start_burden" => best_start_burden,
        "start_burdens" => start_burdens,
        "preprocessing" => preprocessing,
        "strategy_count" => parse(Int, spec["strategy_count"]),
        "requirement_count" => parse(Int, spec["tagged_requirement_count"]),
        "frontier_row_count" => parse(Int, spec["frontier_row_count"]),
        "replicate_id" => parse(Int, spec["replicate_id"]),
        "size_label" => size_label(spec),
    )
    return result
end

function load_analysis_data()
    audit = TOML.parsefile(joinpath(RESULTS_ROOT, "audit", "audit_summary.toml"))
    get(audit, "passed", false) === true || error("audited final results do not pass")
    parse(Int, string(audit["terminal_run_count"])) == 3907 || error("unexpected terminal-run count")
    registry_rows = read_csv(joinpath(STUDY_ROOT, "registry", "INSTANCE_REGISTRY.csv"))
    final_specs = Dict(row["instance_id"] => row for row in registry_rows if row["analysis_included"] == "true")
    length(final_specs) == 173 || error("unexpected final-instance count")
    metadata = load_instance_metadata(final_specs)
    run_rows = read_csv(joinpath(RESULTS_ROOT, "final_algorithm_runs.csv"))
    length(run_rows) == 3907 || error("unexpected final run matrix size")
    runs = Dict{String,Any}[]
    for row in run_rows
        haskey(final_specs, row["instance_id"]) || error("run outside final registry: $(row["instance_id"])")
        push!(runs, load_run(row, final_specs[row["instance_id"]]))
    end
    index = Dict((run["instance_id"], run["algorithm_id"], run["preprocessing_variant"]) => run for run in runs)
    return (; audit, final_specs, metadata, runs, index)
end

function mip_conclusive(run)
    run === nothing && return false
    run["solved"] || return false
    return run["solver_claimed_optimal"] === true || run["status"] == "SOLVED_BY_EXACT_PREPROCESSING"
end

function establish_references(data)
    references = Dict{String,Dict{String,Any}}()
    exact_rows = Dict{String,Any}[]
    for id in sort!(collect(keys(data.final_specs)))
        spec = data.final_specs[id]
        enum_required = spec["exact_enumeration_required"] == "true"
        dp_required = spec["exact_dp_required"] == "true"
        enum = get(data.index, (id, "complete_enumeration", "mandatory_only"), nothing)
        dp = get(data.index, (id, "requirement_mask_dp", "mandatory_only"), nothing)
        dp_full = get(data.index, (id, "requirement_mask_dp", "full_fixed_point"), nothing)
        mip_full = get(data.index, (id, MIP_ALGORITHM, "full_fixed_point"), nothing)
        mip_mandatory = get(data.index, (id, MIP_ALGORITHM, "mandatory_only"), nothing)

        exact_available = enum_required && dp_required && enum !== nothing && dp !== nothing &&
            enum["solved"] && dp["solved"] && enum["exact_burden"] == dp["exact_burden"]
        if exact_available && spec["family"] == "small_exact"
            exact_available &= dp_full !== nothing && dp_full["solved"] &&
                dp_full["exact_burden"] == enum["exact_burden"] && mip_conclusive(mip_full) &&
                mip_full["exact_burden"] == enum["exact_burden"]
        end
        exact_burden = exact_available ? enum["exact_burden"] : missing

        mip_reference_available = mip_conclusive(mip_mandatory) &&
            mip_mandatory["solver_claimed_optimal"] === true
        mip_burden = mip_reference_available ? mip_mandatory["exact_burden"] : missing
        if exact_available
            references[id] = Dict("class" => "EXACT_FINITE", "burden" => exact_burden, "available" => true)
        elseif spec["family"] in ("structured", "adversarial") && mip_reference_available
            references[id] = Dict("class" => "MIP_OPTIMAL_EXACTLY_RECHECKED", "burden" => mip_burden, "available" => true)
        else
            references[id] = Dict("class" => "UNAVAILABLE", "burden" => missing, "available" => false)
        end

        if enum_required && dp_required
            conclusive_runs = [run for run in (enum, dp, dp_full, mip_full, mip_mandatory) if run !== nothing &&
                ((run["algorithm_id"] == MIP_ALGORITHM && mip_conclusive(run)) ||
                 (run["algorithm_id"] != MIP_ALGORITHM && run["solved"]))]
            burdens = [run["exact_burden"] for run in conclusive_runs]
            agreement = exact_available && !isempty(burdens) && all(value == first(burdens) for value in burdens)
            selections = [Tuple(run["selected_indices"]) for run in conclusive_runs]
            identity_difference = agreement && length(unique(selections)) > 1
            push!(exact_rows, Dict{String,Any}(
                "instance_id" => id,
                "family" => spec["family"],
                "size" => size_label(spec),
                "enumeration_status" => enum === nothing ? "NOT_REGISTERED" : enum["status"],
                "enumeration_burden" => enum === nothing ? "UNAVAILABLE" : encode_exact(enum["exact_burden"]),
                "dp_mandatory_status" => dp === nothing ? "NOT_REGISTERED" : dp["status"],
                "dp_mandatory_burden" => dp === nothing ? "UNAVAILABLE" : encode_exact(dp["exact_burden"]),
                "dp_full_status" => dp_full === nothing ? "NOT_REGISTERED" : dp_full["status"],
                "dp_full_burden" => dp_full === nothing ? "UNAVAILABLE" : encode_exact(dp_full["exact_burden"]),
                "mip_full_status" => mip_full === nothing ? "NOT_REGISTERED" : mip_full["status"],
                "mip_full_burden" => mip_full === nothing ? "UNAVAILABLE" : encode_exact(mip_full["exact_burden"]),
                "mip_mandatory_status" => mip_mandatory === nothing ? "NOT_REGISTERED" : mip_mandatory["status"],
                "mip_mandatory_burden" => mip_mandatory === nothing ? "UNAVAILABLE" : encode_exact(mip_mandatory["exact_burden"]),
                "exact_agreement" => agreement,
                "optimizer_identity_difference" => identity_difference,
                "reference_class" => references[id]["class"],
            ))
        end
    end
    return references, exact_rows
end

normal_cdf(value) = 0.5 * ccall((:erfc, Base.Math.libm), Cdouble, (Cdouble,), -value / sqrt(2.0))

function categorical_columns(values, prefix; baseline = nothing)
    levels = sort!(unique(String.(values)))
    isempty(levels) && return zeros(length(values), 0), String[], String[]
    baseline_value = baseline === nothing ? levels[1] : String(baseline)
    baseline_value in levels || error("missing categorical baseline $baseline_value")
    retained = [level for level in levels if level != baseline_value]
    matrix = zeros(Float64, length(values), length(retained))
    for (column, level) in enumerate(retained), row in eachindex(values)
        matrix[row, column] = String(values[row]) == level ? 1.0 : 0.0
    end
    return matrix, ["$(prefix)[$level]" for level in retained], levels
end

function hc3_fit(model_id, model_family, evidence_label, y, X, names; population_n, exclusions)
    n, p = size(X)
    rows = Dict{String,Any}[]
    diagnostic = Dict{String,Any}(
        "model_id" => model_id,
        "model_family" => model_family,
        "evidence_label" => evidence_label,
        "status" => "NOT_FIT",
        "population_n" => population_n,
        "fitted_n" => n,
        "unavailable_n" => exclusions,
        "parameter_count" => p,
        "rank" => rank(X),
        "r_squared" => missing,
    )
    if n <= p || rank(X) < p
        diagnostic["status"] = "RANK_DEFICIENT"
        return rows, diagnostic
    end
    beta = X \ y
    residuals = y - X * beta
    xtx_inverse = inv(X' * X)
    leverage = vec(sum((X * xtx_inverse) .* X; dims = 2))
    any(value >= 1 - 1e-10 for value in leverage) && begin
        diagnostic["status"] = "HC3_LEVERAGE_FAILURE"
        return rows, diagnostic
    end
    meat = zeros(Float64, p, p)
    for index in 1:n
        adjusted = residuals[index] / (1 - leverage[index])
        vector = @view X[index, :]
        meat .+= (adjusted^2) .* (vector * vector')
    end
    covariance = xtx_inverse * meat * xtx_inverse
    standard_errors = sqrt.(max.(diag(covariance), 0.0))
    total = sum((y .- sum(y) / n) .^ 2)
    r_squared = total == 0 ? missing : 1 - sum(residuals .^ 2) / total
    diagnostic["status"] = "FIT"
    diagnostic["r_squared"] = r_squared
    raw_p = Float64[]
    for index in eachindex(beta)
        z = standard_errors[index] == 0 ? (beta[index] == 0 ? 0.0 : sign(beta[index]) * Inf) : beta[index] / standard_errors[index]
        pvalue = min(1.0, 2 * (1 - normal_cdf(abs(z))))
        push!(raw_p, pvalue)
        push!(rows, Dict{String,Any}(
            "model_id" => model_id,
            "model_family" => model_family,
            "evidence_label" => evidence_label,
            "term" => names[index],
            "estimate" => beta[index],
            "standard_error" => standard_errors[index],
            "ci_lower_95" => beta[index] - 1.959963984540054 * standard_errors[index],
            "ci_upper_95" => beta[index] + 1.959963984540054 * standard_errors[index],
            "p_value" => pvalue,
            "holm_p_value" => missing,
            "population_n" => population_n,
            "fitted_n" => n,
        ))
    end
    test_indices = [index for index in eachindex(rows) if rows[index]["term"] != "intercept"]
    order = sort(test_indices; by = index -> raw_p[index])
    running = 0.0
    m = length(order)
    for (position, index) in enumerate(order)
        adjusted = min(1.0, (m - position + 1) * raw_p[index])
        running = max(running, adjusted)
        rows[index]["holm_p_value"] = running
    end
    return rows, diagnostic
end

function logistic_fit(model_id, model_family, evidence_label, y, X, names; population_n, exclusions)
    n, p = size(X)
    rows = Dict{String,Any}[]
    diagnostic = Dict{String,Any}(
        "model_id" => model_id,
        "model_family" => model_family,
        "evidence_label" => evidence_label,
        "status" => "NOT_FIT",
        "population_n" => population_n,
        "fitted_n" => n,
        "unavailable_n" => exclusions,
        "parameter_count" => p,
        "rank" => rank(X),
        "iterations" => 0,
    )
    if n <= p || rank(X) < p || length(unique(y)) < 2
        diagnostic["status"] = length(unique(y)) < 2 ? "NO_OUTCOME_VARIATION" : "RANK_DEFICIENT"
        return rows, diagnostic
    end
    beta = zeros(Float64, p)
    converged = false
    separated = false
    information = zeros(Float64, p, p)
    for iteration in 1:100
        eta = X * beta
        probabilities = 1.0 ./ (1.0 .+ exp.(-clamp.(eta, -35.0, 35.0)))
        weights = clamp.(probabilities .* (1 .- probabilities), 1e-10, Inf)
        information = X' * (weights .* X)
        if rank(information) < p
            diagnostic["status"] = "RANK_DEFICIENT_IRLS"
            return rows, diagnostic
        end
        score = X' * (y - probabilities)
        candidate = beta + information \ score
        diagnostic["iterations"] = iteration
        if maximum(abs.(candidate - beta)) < 1e-9
            beta = candidate
            converged = true
            break
        end
        beta = candidate
        if maximum(abs.(beta)) > 30
            separated = true
            break
        end
    end
    if separated
        diagnostic["status"] = "SEPARATION_DETECTED"
        return rows, diagnostic
    elseif !converged
        diagnostic["status"] = "IRLS_DID_NOT_CONVERGE"
        return rows, diagnostic
    end
    covariance = inv(information)
    standard_errors = sqrt.(max.(diag(covariance), 0.0))
    diagnostic["status"] = "FIT"
    raw_p = Float64[]
    for index in eachindex(beta)
        z = standard_errors[index] == 0 ? (beta[index] == 0 ? 0.0 : sign(beta[index]) * Inf) : beta[index] / standard_errors[index]
        pvalue = min(1.0, 2 * (1 - normal_cdf(abs(z))))
        push!(raw_p, pvalue)
        push!(rows, Dict{String,Any}(
            "model_id" => model_id,
            "model_family" => model_family,
            "evidence_label" => evidence_label,
            "term" => names[index],
            "estimate" => beta[index],
            "standard_error" => standard_errors[index],
            "ci_lower_95" => beta[index] - 1.959963984540054 * standard_errors[index],
            "ci_upper_95" => beta[index] + 1.959963984540054 * standard_errors[index],
            "p_value" => pvalue,
            "holm_p_value" => missing,
            "population_n" => population_n,
            "fitted_n" => n,
        ))
    end
    test_indices = [index for index in eachindex(rows) if rows[index]["term"] != "intercept"]
    order = sort(test_indices; by = index -> raw_p[index])
    running = 0.0
    m = length(order)
    for (position, index) in enumerate(order)
        adjusted = min(1.0, (m - position + 1) * raw_p[index])
        running = max(running, adjusted)
        rows[index]["holm_p_value"] = running
    end
    return rows, diagnostic
end

function base_runtime_design(rows)
    n = length(rows)
    present_algorithms = unique([row["algorithm_id"] for row in rows])
    baseline_algorithm = first(algorithm for algorithm in ALGORITHM_ORDER if algorithm in present_algorithms)
    algorithm_matrix, algorithm_names, _ = categorical_columns([row["algorithm_id"] for row in rows], "algorithm"; baseline = baseline_algorithm)
    preprocessing = [row["preprocessing_variant"] == "mandatory_only" ? "mandatory" : "full" for row in rows]
    preprocessing_matrix, preprocessing_names, _ = categorical_columns(preprocessing, "preprocessing"; baseline = "mandatory")
    lane_matrix, lane_names, _ = categorical_columns([string(row["worker_lane"]) for row in rows], "lane"; baseline = "1")
    numeric = hcat([log2(row["strategy_count"]) for row in rows], [log2(row["requirement_count"]) for row in rows])
    X = hcat(ones(n), algorithm_matrix, numeric, preprocessing_matrix, lane_matrix)
    names = vcat(["intercept"], algorithm_names, ["log2_strategy_count", "log2_requirement_count"], preprocessing_names, lane_names)
    return X, names
end

function family_b_structural_design(rows; include_algorithm = false, include_lane = true)
    n = length(rows)
    covariate_names = [
        "log2_strategy_count", "log2_requirement_count", "frontier_row_share",
        "coverage_density", "module_overlap", "bundle_prevalence",
        "unique_carrier_frequency", "weight_dispersion", "frontier_module_correlation",
        "replicate_2",
    ]
    structural = zeros(Float64, n, length(covariate_names))
    for (row_index, row) in enumerate(rows)
        values = row["structural_covariates"]
        for (column, name) in enumerate(covariate_names)
            structural[row_index, column] = values[name]
        end
    end
    X = hcat(ones(n), structural)
    names = vcat(["intercept"], covariate_names)
    if include_algorithm
        algorithms = [row["algorithm_id"] for row in rows]
        algorithm_matrix, algorithm_names, levels = categorical_columns(algorithms, "algorithm"; baseline = HEURISTIC_ALGORITHMS[1])
        X = hcat(X, algorithm_matrix)
        append!(names, algorithm_names)
        for level in levels
            level == HEURISTIC_ALGORITHMS[1] && continue
            indicator = Float64.(algorithms .== level)
            X = hcat(X, indicator .* structural[:, 1], indicator .* structural[:, 2])
            push!(names, "algorithm[$level]:log2_strategy_count")
            push!(names, "algorithm[$level]:log2_requirement_count")
        end
    end
    if include_lane
        lane_matrix, lane_names, _ = categorical_columns([string(row["worker_lane"]) for row in rows], "lane"; baseline = "1")
        X = hcat(X, lane_matrix)
        append!(names, lane_names)
    end
    return X, names
end

function enrich_runs!(data, references)
    for run in data.runs
        reference = references[run["instance_id"]]
        run["reference_class"] = reference["class"]
        run["reference_burden"] = reference["burden"]
        if reference["available"] && run["exact_feasible"] && run["exact_burden"] !== missing
            absolute_gap = run["exact_burden"] - reference["burden"]
            reference["burden"] > 0 || error("nonpositive reference burden on $(run["instance_id"])")
            absolute_gap >= 0 || error("negative gap against registered reference on $(run["instance_id"])/$(run["algorithm_id"])")
            run["absolute_gap"] = absolute_gap
            run["relative_gap"] = absolute_gap / reference["burden"]
            run["reference_attained"] = absolute_gap == 0
        else
            run["absolute_gap"] = missing
            run["relative_gap"] = missing
            run["reference_attained"] = false
        end
        spec = data.final_specs[run["instance_id"]]
        run["structural_covariates"] = spec["family"] == "structured" ? structure_covariates(spec) : Dict{String,Float64}()
        run["source_burden"] = data.metadata[run["instance_id"]]["source_burden"]
        run["source_normalized_burden"] = run["exact_burden"] === missing || run["source_burden"] === missing || run["source_burden"] == 0 ? missing : run["exact_burden"] / run["source_burden"]
    end
    return data
end

function algorithm_guarantee_rows()
    source_ledger = "THEOREM_LEDGER.md"
    literature = "journal/aor/reports/OR_LITERATURE_AUDIT.md"
    rows = Dict{String,Any}[]
    function add(algorithm, guarantee, evidence, scope, source)
        push!(rows, Dict{String,Any}(
            "algorithm" => ALGORITHM_LABEL[algorithm],
            "algorithm_id" => algorithm,
            "guarantee" => guarantee,
            "evidence_class" => evidence,
            "scope_and_limit" => scope,
            "source" => source,
        ))
    end
    add("complete_enumeration", "Exact optimum after complete finite search", "Human proof + exact finite computation", "Small finite identity-closure instances; exponential in optional strategies", source_ledger)
    add("requirement_mask_dp", "Exact optimum; O(n 2^r) recurrence operations", "Human proof + exact finite computation", "FPT in residual requirements r, not polynomial in full input size", source_ledger)
    add("jump_highs_tagged_cover", "Exactly rechecked feasible incumbent; solver-optimal status reported separately", "Mixed-integer solver evidence + exact finite post-check", "OPTIMAL is neither formal proof nor exhaustive enumeration", "journal/aor/reports/MIP_SPECIFICATION.md")
    add("weighted_greedy", "H(d) <= H(r) weighted-cover approximation", "Transferred primary-source theorem", "Positive active weights and identity-closure tagged-cover equivalence only", literature)
    add("weighted_greedy_reverse_delete", "H(d) guarantee inherited; deletion cannot increase burden", "Transferred theorem + exact deletion check", "Same identity-closure scope; reverse deletion adds no general-closure guarantee", source_ledger)
    add("cardinality_greedy", "No burden approximation guarantee for heterogeneous weights", "Algorithmic limitation", "Unweighted score is reported as a comparator", source_ledger)
    for algorithm in DELETION_ALGORITHMS
        algorithm == "multistart_random_rechecked_deletion_32" && continue
        limitation = algorithm == "heaviest_safe_first" ? "Exact feasibility and irreducibility only; registered family proves an unbounded burden ratio" : "Exact feasibility and endpoint irreducibility only; no global burden factor"
        add(algorithm, limitation, "Exact finite certification + human-proof boundary", "Identity closure for tagged checks; every accepted deletion independently rechecked", source_ledger)
    end
    add("multistart_random_rechecked_deletion_32", "Best of 32 certified irreducible endpoints; no approximation factor", "Synthetic algorithmic evidence + exact finite certification", "Registered seeds and fixed 32 starts; not adaptive", source_ledger)
    return rows
end

function trace_rows(data)
    rows = Dict{String,Any}[]
    for run in sort(data.runs; by = run -> (run["instance_id"], run["algorithm_id"], run["preprocessing_variant"]))
        push!(rows, Dict{String,Any}(
            "instance_id" => run["instance_id"],
            "family" => run["family"],
            "size" => run["size_label"],
            "algorithm_id" => run["algorithm_id"],
            "preprocessing_variant" => run["preprocessing_variant"],
            "primary_variant" => primary_run(run),
            "status" => run["status"],
            "candidate_accepted" => run["candidate_accepted"],
            "exact_feasible" => run["exact_feasible"],
            "exact_burden" => encode_exact(run["exact_burden"]),
            "reference_class" => run["reference_class"],
            "reference_burden" => encode_exact(run["reference_burden"]),
            "absolute_gap" => encode_exact(run["absolute_gap"]),
            "relative_gap" => encode_exact(run["relative_gap"]),
            "wall_clock_seconds" => run["wall_clock_seconds"],
            "par2_seconds" => run["par2_seconds"],
            "time_limit_seconds" => run["time_limit_seconds"],
            "worker_lane" => run["worker_lane"],
            "launch_wave" => run["launch_wave"],
            "record_path" => run["record_path"],
            "record_sha256" => run["record_sha256"],
        ))
    end
    return rows
end

function heuristic_quality_rows(data)
    rows = Dict{String,Any}[]
    primary = [run for run in data.runs if run["algorithm_id"] in HEURISTIC_ALGORITHMS && primary_run(run)]
    keys = sort!(unique((run["family"], run["reference_class"], run["algorithm_id"]) for run in primary))
    for (family, reference_class, algorithm) in keys
        group = [run for run in primary if run["family"] == family && run["reference_class"] == reference_class && run["algorithm_id"] == algorithm]
        reference_eligible = [run for run in group if run["reference_burden"] !== missing]
        gap_eligible = [run for run in reference_eligible if run["relative_gap"] !== missing]
        relative = summarize([run["relative_gap"] for run in gap_eligible])
        absolute = summarize([run["absolute_gap"] for run in gap_eligible])
        attained = count(run -> run["reference_attained"], reference_eligible)
        solved = count(run -> run["solved"], group)
        push!(rows, Dict{String,Any}(
            "family" => family,
            "reference_class" => reference_class,
            "algorithm" => ALGORITHM_LABEL[algorithm],
            "algorithm_id" => algorithm,
            "registered_n" => length(group),
            "solved_n" => solved,
            "solved_fraction" => length(group) == 0 ? missing : solved / length(group),
            "reference_available_n" => length(reference_eligible),
            "reference_unavailable_n" => length(group) - length(reference_eligible),
            "attained_n" => attained,
            "attainment_denominator" => length(reference_eligible),
            "attainment_fraction" => isempty(reference_eligible) ? missing : attained / length(reference_eligible),
            "gap_available_n" => relative["n"],
            "gap_unavailable_n" => length(reference_eligible) - relative["n"],
            "relative_gap_mean" => format_summary_value(relative["mean"]),
            "relative_gap_median" => format_summary_value(relative["median"]),
            "relative_gap_q10" => format_summary_value(relative["q10"]),
            "relative_gap_q25" => format_summary_value(relative["q25"]),
            "relative_gap_q75" => format_summary_value(relative["q75"]),
            "relative_gap_q90" => format_summary_value(relative["q90"]),
            "relative_gap_minimum" => format_summary_value(relative["minimum"]),
            "relative_gap_worst" => format_summary_value(relative["maximum"]),
            "absolute_gap_mean" => format_summary_value(absolute["mean"]; exact = true),
            "absolute_gap_median" => format_summary_value(absolute["median"]; exact = true),
            "absolute_gap_q10" => format_summary_value(absolute["q10"]; exact = true),
            "absolute_gap_q25" => format_summary_value(absolute["q25"]; exact = true),
            "absolute_gap_q75" => format_summary_value(absolute["q75"]; exact = true),
            "absolute_gap_q90" => format_summary_value(absolute["q90"]; exact = true),
            "absolute_gap_minimum" => format_summary_value(absolute["minimum"]; exact = true),
            "absolute_gap_worst" => format_summary_value(absolute["maximum"]; exact = true),
        ))
    end
    return rows
end

function computational_scaling_rows(data)
    rows = Dict{String,Any}[]
    primary = [run for run in data.runs if primary_run(run)]
    keys = sort!(unique((run["family"], run["size_label"], run["algorithm_id"], run["preprocessing_variant"]) for run in primary))
    for (family, size, algorithm, variant) in keys
        group = [run for run in primary if run["family"] == family && run["size_label"] == size && run["algorithm_id"] == algorithm && run["preprocessing_variant"] == variant]
        solved_wall = summarize([run["wall_clock_seconds"] for run in group if run["solved"]])
        par2 = summarize([run["par2_seconds"] for run in group])
        memory = summarize([run["peak_memory_bytes"] === missing ? missing : Float64(run["peak_memory_bytes"]) for run in group])
        nodes = summarize([run["mip_node_count"] for run in group])
        states = summarize([run["dp_state_layer_pairs"] for run in group])
        transitions = summarize([run["dp_transitions"] for run in group])
        frontier = summarize([run["frontier_checks"] for run in group])
        closure = summarize([run["closure_checks"] for run in group])
        solved_count = count(run -> run["solved"], group)
        push!(rows, Dict{String,Any}(
            "family" => family,
            "size" => size,
            "algorithm" => ALGORITHM_LABEL[algorithm],
            "algorithm_id" => algorithm,
            "preprocessing_variant" => variant,
            "registered_n" => length(group),
            "solved_n" => solved_count,
            "solved_fraction" => solved_count / length(group),
            "time_limit_seconds" => join(sort!(unique(run["time_limit_seconds"] for run in group)), ";"),
            "wall_solved_n" => solved_wall["n"],
            "wall_seconds_mean_solved" => format_summary_value(solved_wall["mean"]),
            "wall_seconds_median_solved" => format_summary_value(solved_wall["median"]),
            "wall_seconds_q90_solved" => format_summary_value(solved_wall["q90"]),
            "wall_seconds_worst_solved" => format_summary_value(solved_wall["maximum"]),
            "par2_mean_seconds" => format_summary_value(par2["mean"]),
            "par2_median_seconds" => format_summary_value(par2["median"]),
            "par2_q25_seconds" => format_summary_value(par2["q25"]),
            "par2_q75_seconds" => format_summary_value(par2["q75"]),
            "par2_q90_seconds" => format_summary_value(par2["q90"]),
            "par2_worst_seconds" => format_summary_value(par2["maximum"]),
            "peak_memory_available_n" => memory["n"],
            "peak_memory_mean_mib" => memory["mean"] === missing ? "UNAVAILABLE" : format_summary_value(memory["mean"] / 2.0^20),
            "peak_memory_median_mib" => memory["median"] === missing ? "UNAVAILABLE" : format_summary_value(memory["median"] / 2.0^20),
            "peak_memory_q90_mib" => memory["q90"] === missing ? "UNAVAILABLE" : format_summary_value(memory["q90"] / 2.0^20),
            "peak_memory_worst_mib" => memory["maximum"] === missing ? "UNAVAILABLE" : format_summary_value(memory["maximum"] / 2.0^20),
            "mip_nodes_available_n" => nodes["n"],
            "mip_nodes_mean" => format_summary_value(nodes["mean"]),
            "mip_nodes_median" => format_summary_value(nodes["median"]),
            "mip_nodes_q10" => format_summary_value(nodes["q10"]),
            "mip_nodes_q25" => format_summary_value(nodes["q25"]),
            "mip_nodes_q75" => format_summary_value(nodes["q75"]),
            "mip_nodes_q90" => format_summary_value(nodes["q90"]),
            "mip_nodes_minimum" => format_summary_value(nodes["minimum"]),
            "mip_nodes_worst" => format_summary_value(nodes["maximum"]),
            "dp_states_available_n" => states["n"],
            "dp_states_mean" => format_summary_value(states["mean"]),
            "dp_states_median" => format_summary_value(states["median"]),
            "dp_states_q10" => format_summary_value(states["q10"]),
            "dp_states_q25" => format_summary_value(states["q25"]),
            "dp_states_q75" => format_summary_value(states["q75"]),
            "dp_states_q90" => format_summary_value(states["q90"]),
            "dp_states_minimum" => format_summary_value(states["minimum"]),
            "dp_states_worst" => format_summary_value(states["maximum"]),
            "dp_transitions_available_n" => transitions["n"],
            "dp_transitions_mean" => format_summary_value(transitions["mean"]),
            "dp_transitions_median" => format_summary_value(transitions["median"]),
            "dp_transitions_q90" => format_summary_value(transitions["q90"]),
            "dp_transitions_worst" => format_summary_value(transitions["maximum"]),
            "frontier_checks_available_n" => frontier["n"],
            "frontier_checks_mean" => format_summary_value(frontier["mean"]),
            "frontier_checks_median" => format_summary_value(frontier["median"]),
            "frontier_checks_q10" => format_summary_value(frontier["q10"]),
            "frontier_checks_q25" => format_summary_value(frontier["q25"]),
            "frontier_checks_q75" => format_summary_value(frontier["q75"]),
            "frontier_checks_q90" => format_summary_value(frontier["q90"]),
            "frontier_checks_minimum" => format_summary_value(frontier["minimum"]),
            "frontier_checks_worst" => format_summary_value(frontier["maximum"]),
            "closure_checks_available_n" => closure["n"],
            "closure_checks_mean" => format_summary_value(closure["mean"]),
            "closure_checks_median" => format_summary_value(closure["median"]),
            "closure_checks_q10" => format_summary_value(closure["q10"]),
            "closure_checks_q25" => format_summary_value(closure["q25"]),
            "closure_checks_q75" => format_summary_value(closure["q75"]),
            "closure_checks_q90" => format_summary_value(closure["q90"]),
            "closure_checks_minimum" => format_summary_value(closure["minimum"]),
            "closure_checks_worst" => format_summary_value(closure["maximum"]),
        ))
    end
    return rows
end

function preprocessing_rows(data)
    detailed = Dict{String,Any}[]
    rule_rows = Dict{String,Any}[]
    for id in sort!(collect(keys(data.final_specs)))
        spec = data.final_specs[id]
        full = get(data.index, (id, MIP_ALGORITHM, "full_fixed_point"), nothing)
        mandatory = get(data.index, (id, MIP_ALGORITHM, "mandatory_only"), nothing)
        full === nothing && continue
        pre = full["preprocessing"]
        variable_fraction = pre["available"] && pre["original_variables"] > 0 ? pre["variables_removed"] / pre["original_variables"] : missing
        requirement_fraction = pre["available"] && pre["original_requirements"] > 0 ? pre["requirements_removed"] / pre["original_requirements"] : missing
        node_difference = full["mip_node_count"] === missing || mandatory === nothing || mandatory["mip_node_count"] === missing ? missing : full["mip_node_count"] - mandatory["mip_node_count"]
        node_log_difference = full["mip_node_count"] === missing || mandatory === nothing || mandatory["mip_node_count"] === missing ? missing : log1p(full["mip_node_count"]) - log1p(mandatory["mip_node_count"])
        par2_log_difference = mandatory === nothing ? missing : log(full["par2_seconds"]) - log(mandatory["par2_seconds"])
        push!(detailed, Dict{String,Any}(
            "instance_id" => id,
            "family" => spec["family"],
            "size" => size_label(spec),
            "full_status" => full["status"],
            "mandatory_status" => mandatory === nothing ? "NOT_REGISTERED" : mandatory["status"],
            "original_variables" => pre["original_variables"],
            "reduced_variables" => pre["reduced_variables"],
            "variables_removed" => pre["variables_removed"],
            "variable_reduction_fraction" => variable_fraction,
            "original_requirements" => pre["original_requirements"],
            "reduced_requirements" => pre["reduced_requirements"],
            "requirements_removed" => pre["requirements_removed"],
            "requirement_reduction_fraction" => requirement_fraction,
            "forced_selections" => pre["forced_selections"],
            "fixed_point_iterations" => pre["fixed_point_iterations"],
            "full_par2_seconds" => full["par2_seconds"],
            "mandatory_par2_seconds" => mandatory === nothing ? missing : mandatory["par2_seconds"],
            "log_par2_difference_full_minus_mandatory" => par2_log_difference,
            "full_node_count" => full["mip_node_count"],
            "mandatory_node_count" => mandatory === nothing ? missing : mandatory["mip_node_count"],
            "node_difference_full_minus_mandatory" => node_difference,
            "log1p_node_difference_full_minus_mandatory" => node_log_difference,
            "full_record_path" => full["record_path"],
            "full_record_sha256" => full["record_sha256"],
            "mandatory_record_path" => mandatory === nothing ? "" : mandatory["record_path"],
            "mandatory_record_sha256" => mandatory === nothing ? "" : mandatory["record_sha256"],
        ))
        for (rule, counts) in pre["rule_counts"]
            push!(rule_rows, Dict{String,Any}(
                "instance_id" => id,
                "family" => spec["family"],
                "size" => size_label(spec),
                "rule" => rule,
                "applications" => get(counts, "applications", 0),
                "variables_removed" => get(counts, "variables_removed", 0),
                "requirements_removed" => get(counts, "requirements_removed", 0),
                "record_path" => full["record_path"],
                "record_sha256" => full["record_sha256"],
            ))
        end
    end
    summary = Dict{String,Any}[]
    summary_keys = sort!(unique((row["family"], row["size"]) for row in detailed))
    for (family, size) in summary_keys
        group = [row for row in detailed if row["family"] == family && row["size"] == size]
        variables = summarize([row["variable_reduction_fraction"] for row in group])
        requirements = summarize([row["requirement_reduction_fraction"] for row in group])
        par2 = summarize([row["log_par2_difference_full_minus_mandatory"] for row in group])
        nodes = summarize([row["log1p_node_difference_full_minus_mandatory"] for row in group])
        push!(summary, Dict{String,Any}(
            "family" => family,
            "size" => size,
            "registered_n" => length(group),
            "preprocessing_available_n" => variables["n"],
            "variable_reduction_mean" => format_summary_value(variables["mean"]),
            "variable_reduction_median" => format_summary_value(variables["median"]),
            "variable_reduction_q10" => format_summary_value(variables["q10"]),
            "variable_reduction_q25" => format_summary_value(variables["q25"]),
            "variable_reduction_q75" => format_summary_value(variables["q75"]),
            "variable_reduction_q90" => format_summary_value(variables["q90"]),
            "variable_reduction_minimum" => format_summary_value(variables["minimum"]),
            "variable_reduction_worst" => format_summary_value(variables["maximum"]),
            "requirement_reduction_mean" => format_summary_value(requirements["mean"]),
            "requirement_reduction_median" => format_summary_value(requirements["median"]),
            "requirement_reduction_q10" => format_summary_value(requirements["q10"]),
            "requirement_reduction_q25" => format_summary_value(requirements["q25"]),
            "requirement_reduction_q75" => format_summary_value(requirements["q75"]),
            "requirement_reduction_q90" => format_summary_value(requirements["q90"]),
            "requirement_reduction_minimum" => format_summary_value(requirements["minimum"]),
            "requirement_reduction_worst" => format_summary_value(requirements["maximum"]),
            "paired_par2_available_n" => par2["n"],
            "mean_log_par2_difference" => format_summary_value(par2["mean"]),
            "median_log_par2_difference" => format_summary_value(par2["median"]),
            "q90_log_par2_difference" => format_summary_value(par2["q90"]),
            "worst_log_par2_difference" => format_summary_value(par2["maximum"]),
            "paired_nodes_available_n" => nodes["n"],
            "mean_log1p_node_difference" => format_summary_value(nodes["mean"]),
            "median_log1p_node_difference" => format_summary_value(nodes["median"]),
            "q90_log1p_node_difference" => format_summary_value(nodes["q90"]),
            "worst_log1p_node_difference" => format_summary_value(nodes["maximum"]),
        ))
    end
    return detailed, summary, rule_rows
end

function multistart_rows(data)
    detailed = Dict{String,Any}[]
    start_rows = Dict{String,Any}[]
    for run in data.runs
        run["algorithm_id"] == "multistart_random_rechecked_deletion_32" || continue
        primary_run(run) || continue
        absolute = run["first_start_burden"] === missing || run["best_start_burden"] === missing ? missing : run["first_start_burden"] - run["best_start_burden"]
        relative = absolute === missing || run["first_start_burden"] == 0 ? missing : absolute / run["first_start_burden"]
        push!(detailed, Dict{String,Any}(
            "instance_id" => run["instance_id"],
            "family" => run["family"],
            "size" => run["size_label"],
            "status" => run["status"],
            "first_start_burden" => encode_exact(run["first_start_burden"]),
            "selected_best_burden" => encode_exact(run["best_start_burden"]),
            "absolute_improvement" => encode_exact(absolute),
            "relative_improvement" => encode_exact(relative),
            "start_count_available" => length(run["start_burdens"]),
            "record_path" => run["record_path"],
            "record_sha256" => run["record_sha256"],
        ))
        for (index, burden) in enumerate(run["start_burdens"])
            push!(start_rows, Dict{String,Any}(
                "instance_id" => run["instance_id"],
                "family" => run["family"],
                "size" => run["size_label"],
                "start_index" => index,
                "exact_burden" => encode_exact(burden),
                "relative_to_first" => run["first_start_burden"] == 0 ? "UNAVAILABLE" : encode_exact(burden / run["first_start_burden"]),
                "selected_best" => burden == run["best_start_burden"],
                "record_path" => run["record_path"],
                "record_sha256" => run["record_sha256"],
            ))
        end
    end
    summary = Dict{String,Any}[]
    for key in sort!(unique((row["family"], row["size"]) for row in detailed))
        family, size = key
        group = [row for row in detailed if row["family"] == family && row["size"] == size]
        relative_values = [parse_exact(row["relative_improvement"]) for row in group]
        stats = summarize(relative_values)
        improved = count(value -> value !== missing && value > 0, relative_values)
        push!(summary, Dict{String,Any}(
            "family" => family,
            "size" => size,
            "registered_n" => length(group),
            "complete_32_start_n" => count(row -> row["start_count_available"] == 32, group),
            "unavailable_n" => count(row -> row["start_count_available"] == 0, group),
            "improved_n" => improved,
            "improvement_denominator" => stats["n"],
            "relative_improvement_mean" => format_summary_value(stats["mean"]),
            "relative_improvement_median" => format_summary_value(stats["median"]),
            "relative_improvement_q10" => format_summary_value(stats["q10"]),
            "relative_improvement_q25" => format_summary_value(stats["q25"]),
            "relative_improvement_q75" => format_summary_value(stats["q75"]),
            "relative_improvement_q90" => format_summary_value(stats["q90"]),
            "relative_improvement_minimum" => format_summary_value(stats["minimum"]),
            "relative_improvement_worst" => format_summary_value(stats["maximum"]),
        ))
    end
    return detailed, summary, start_rows
end

function timeout_rows(data)
    rows = Dict{String,Any}[]
    for run in data.runs
        run["status"] == "TIME_LIMIT" || continue
        candidate = run["exact_burden"]
        bound = run["mip_best_bound"]
        bound_relative = candidate === missing || bound === missing || bound <= 0 ? missing : (Float64(candidate) - bound) / bound
        push!(rows, Dict{String,Any}(
            "instance_id" => run["instance_id"],
            "family" => run["family"],
            "size" => run["size_label"],
            "algorithm_id" => run["algorithm_id"],
            "preprocessing_variant" => run["preprocessing_variant"],
            "exact_incumbent_burden" => encode_exact(candidate),
            "best_bound" => bound,
            "bound_relative_gap" => bound_relative,
            "solver_reported_gap" => run["mip_reported_gap"],
            "record_path" => run["record_path"],
            "record_sha256" => run["record_sha256"],
        ))
    end
    return rows
end

function failure_rows(data)
    rows = Dict{String,Any}[]
    keys = sort!(unique((run["family"], run["algorithm_id"], run["preprocessing_variant"], run["status"]) for run in data.runs))
    for (family, algorithm, variant, status) in keys
        group = [run for run in data.runs if run["family"] == family && run["algorithm_id"] == algorithm && run["preprocessing_variant"] == variant && run["status"] == status]
        push!(rows, Dict{String,Any}(
            "family" => family,
            "algorithm" => ALGORITHM_LABEL[algorithm],
            "algorithm_id" => algorithm,
            "preprocessing_variant" => variant,
            "status" => status,
            "count" => length(group),
            "successful_status" => status in SOLVED_STATUSES,
            "example_record_path" => first(group)["record_path"],
            "example_record_sha256" => first(group)["record_sha256"],
        ))
    end
    return rows
end

function adversarial_rows(data)
    rows = Dict{String,Any}[]
    for id in sort!(collect(keys(data.final_specs)))
        spec = data.final_specs[id]
        spec["family"] == "adversarial" || continue
        reference = first(run for run in data.runs if run["instance_id"] == id)["reference_burden"]
        reference_class = first(run for run in data.runs if run["instance_id"] == id)["reference_class"]
        for algorithm in ALGORITHM_ORDER
            run = get(data.index, (id, algorithm, get(PRIMARY_VARIANT, algorithm, "")), nothing)
            run === nothing && continue
            theoretical = "NOT_APPLICABLE"
            if spec["mechanism"] == "unbounded_heaviest_safe_first_gap" && algorithm == "heaviest_safe_first"
                parameter_match = match(r"k=([0-9]+);epsilon=1//2", spec["mechanism_parameter"])
                theoretical = parameter_match === nothing ? "UNAVAILABLE" : "$(2 * parse(Int, parameter_match.captures[1]))//3"
            end
            observed_ratio = reference === missing || run["exact_burden"] === missing ? missing : run["exact_burden"] / reference
            push!(rows, Dict{String,Any}(
                "instance_id" => id,
                "mechanism" => spec["mechanism"],
                "scale" => size_label(spec),
                "mechanism_parameter" => spec["mechanism_parameter"],
                "algorithm" => ALGORITHM_LABEL[algorithm],
                "algorithm_id" => algorithm,
                "status" => run["status"],
                "reference_class" => reference_class,
                "reference_burden" => encode_exact(reference),
                "observed_burden" => encode_exact(run["exact_burden"]),
                "observed_burden_ratio" => encode_exact(observed_ratio),
                "theoretical_ratio_if_applicable" => theoretical,
                "evidence_class" => theoretical == "NOT_APPLICABLE" ? "synthetic exact-feasibility computation" : "human proof ratio and synthetic exact-feasibility computation",
                "record_path" => run["record_path"],
                "record_sha256" => run["record_sha256"],
            ))
        end
    end
    return rows
end

function run_registered_models(data, preprocessing_detailed)
    coefficient_rows = Dict{String,Any}[]
    diagnostics = Dict{String,Any}[]

    # Registered Family B heuristic-gap models: primary algorithm variants and
    # exactly rechecked HiGHS-optimal mandatory-only references.
    b_gap_rows = [run for run in data.runs if run["family"] == "structured" &&
        run["algorithm_id"] in HEURISTIC_ALGORITHMS && primary_run(run) &&
        run["reference_class"] == "MIP_OPTIMAL_EXACTLY_RECHECKED" && run["relative_gap"] !== missing]
    for algorithm in HEURISTIC_ALGORITHMS
        rows = [run for run in b_gap_rows if run["algorithm_id"] == algorithm]
        isempty(rows) && continue
        X, names = family_b_structural_design(rows; include_algorithm = false, include_lane = true)
        y = log1p.(Float64.([run["relative_gap"] for run in rows]))
        population = count(run -> run["family"] == "structured" && run["algorithm_id"] == algorithm && primary_run(run), data.runs)
        coefficients, diagnostic = hc3_fit(
            "family_b_gap_$(algorithm)", "family_b_gap", "REGISTERED",
            y, X, names; population_n = population, exclusions = population - length(rows),
        )
        append!(coefficient_rows, coefficients)
        push!(diagnostics, diagnostic)
    end
    if !isempty(b_gap_rows)
        X, names = family_b_structural_design(b_gap_rows; include_algorithm = true, include_lane = true)
        y = log1p.(Float64.([run["relative_gap"] for run in b_gap_rows]))
        population = count(run -> run["family"] == "structured" && run["algorithm_id"] in HEURISTIC_ALGORITHMS && primary_run(run), data.runs)
        coefficients, diagnostic = hc3_fit(
            "family_b_gap_joint", "family_b_gap", "REGISTERED",
            y, X, names; population_n = population, exclusions = population - length(b_gap_rows),
        )
        append!(coefficient_rows, coefficients)
        push!(diagnostics, diagnostic)
    end

    # Registered Family A secondary exact-gap OLS.
    a_gap_rows = [run for run in data.runs if run["family"] == "small_exact" &&
        run["algorithm_id"] in HEURISTIC_ALGORITHMS && primary_run(run) &&
        run["reference_class"] == "EXACT_FINITE" && run["relative_gap"] !== missing]
    if !isempty(a_gap_rows)
        algorithm_matrix, algorithm_names, _ = categorical_columns(
            [run["algorithm_id"] for run in a_gap_rows], "algorithm"; baseline = HEURISTIC_ALGORITHMS[1],
        )
        lane_matrix, lane_names, _ = categorical_columns([string(run["worker_lane"]) for run in a_gap_rows], "lane"; baseline = "1")
        X = hcat(
            ones(length(a_gap_rows)),
            [log2(run["strategy_count"]) for run in a_gap_rows],
            [log2(run["requirement_count"]) for run in a_gap_rows],
            algorithm_matrix,
            lane_matrix,
        )
        names = vcat(["intercept", "log2_strategy_count", "log2_requirement_count"], algorithm_names, lane_names)
        y = log1p.(Float64.([run["relative_gap"] for run in a_gap_rows]))
        population = count(run -> run["family"] == "small_exact" && run["algorithm_id"] in HEURISTIC_ALGORITHMS && primary_run(run), data.runs)
        coefficients, diagnostic = hc3_fit(
            "family_a_exact_gap_secondary", "family_a_gap", "REGISTERED_SECONDARY",
            y, X, names; population_n = population, exclusions = population - length(a_gap_rows),
        )
        append!(coefficient_rows, coefficients)
        push!(diagnostics, diagnostic)
    end

    # Registered solved-fraction and penalized-runtime models, fitted by family.
    for family in ("small_exact", "structured", "adversarial")
        rows = [run for run in data.runs if run["family"] == family]
        X, names = base_runtime_design(rows)
        solved_y = Float64.([run["solved"] for run in rows])
        coefficients, diagnostic = logistic_fit(
            "$(family)_solved_fraction", "solved_fraction", "REGISTERED",
            solved_y, X, names; population_n = length(rows), exclusions = 0,
        )
        append!(coefficient_rows, coefficients)
        push!(diagnostics, diagnostic)
        runtime_y = log.([run["par2_seconds"] for run in rows])
        coefficients, diagnostic = hc3_fit(
            "$(family)_log_par2", "penalized_runtime", "REGISTERED",
            runtime_y, X, names; population_n = length(rows), exclusions = 0,
        )
        append!(coefficient_rows, coefficients)
        push!(diagnostics, diagnostic)

        # Registered descriptive launch-wave sensitivity. This augments rather
        # than replaces the locked primary runtime specification.
        wave = Float64.([run["launch_wave"] for run in rows])
        X_wave = hcat(X, (wave .- mean_value(wave)) ./ max(1.0, sqrt(mean_value((wave .- mean_value(wave)) .^ 2))))
        coefficients, diagnostic = hc3_fit(
            "$(family)_log_par2_launch_wave_sensitivity", "launch_wave_sensitivity", "REGISTERED_DESCRIPTIVE_SENSITIVITY",
            runtime_y, X_wave, vcat(names, ["standardized_launch_wave"]); population_n = length(rows), exclusions = 0,
        )
        append!(coefficient_rows, coefficients)
        push!(diagnostics, diagnostic)
    end

    # Registered paired preprocessing models for Family B MIP runs.
    paired = [row for row in preprocessing_detailed if row["family"] == "structured"]
    function preprocessing_design(rows)
        covariate_names = [
            "frontier_row_share", "coverage_density", "module_overlap", "bundle_prevalence",
            "unique_carrier_frequency", "weight_dispersion", "frontier_module_correlation",
            "log2_strategy_count", "log2_requirement_count",
        ]
        matrix = zeros(Float64, length(rows), length(covariate_names))
        for (row_index, row) in enumerate(rows)
            spec = data.final_specs[row["instance_id"]]
            covariates = structure_covariates(spec)
            for (column, name) in enumerate(covariate_names)
                matrix[row_index, column] = covariates[name]
            end
        end
        full_lanes = [string(data.index[(row["instance_id"], MIP_ALGORITHM, "full_fixed_point")]["worker_lane"]) for row in rows]
        mandatory_lanes = [string(data.index[(row["instance_id"], MIP_ALGORITHM, "mandatory_only")]["worker_lane"]) for row in rows]
        full_matrix, full_names, _ = categorical_columns(full_lanes, "full_lane"; baseline = "1")
        mandatory_matrix, mandatory_names, _ = categorical_columns(mandatory_lanes, "mandatory_lane"; baseline = "1")
        return hcat(ones(length(rows)), matrix, full_matrix, mandatory_matrix), vcat(["intercept"], covariate_names, full_names, mandatory_names)
    end
    if !isempty(paired)
        X, names = preprocessing_design(paired)
        y = Float64.([row["log_par2_difference_full_minus_mandatory"] for row in paired])
        coefficients, diagnostic = hc3_fit(
            "family_b_preprocessing_log_par2_difference", "preprocessing", "REGISTERED",
            y, X, names; population_n = length(paired), exclusions = 0,
        )
        append!(coefficient_rows, coefficients)
        push!(diagnostics, diagnostic)
        node_rows = [row for row in paired if row["log1p_node_difference_full_minus_mandatory"] !== missing]
        if !isempty(node_rows)
            X_nodes, names_nodes = preprocessing_design(node_rows)
            y_nodes = Float64.([row["log1p_node_difference_full_minus_mandatory"] for row in node_rows])
            coefficients, diagnostic = hc3_fit(
                "family_b_preprocessing_log1p_node_difference", "preprocessing", "REGISTERED",
                y_nodes, X_nodes, names_nodes; population_n = length(paired), exclusions = length(paired) - length(node_rows),
            )
            append!(coefficient_rows, coefficients)
            push!(diagnostics, diagnostic)
        end
    end

    # EXPLORATORY: the locked plan has no optimum-attainment logistic model.
    # This separate model responds to the requested diagnostic without
    # relabeling it as prespecified.
    for family in ("small_exact", "structured")
        reference_class = family == "small_exact" ? "EXACT_FINITE" : "MIP_OPTIMAL_EXACTLY_RECHECKED"
        rows = [run for run in data.runs if run["family"] == family &&
            run["algorithm_id"] in HEURISTIC_ALGORITHMS && primary_run(run) &&
            run["reference_class"] == reference_class]
        isempty(rows) && continue
        if family == "structured"
            X, names = family_b_structural_design(rows; include_algorithm = true, include_lane = true)
        else
            algorithm_matrix, algorithm_names, _ = categorical_columns([run["algorithm_id"] for run in rows], "algorithm"; baseline = HEURISTIC_ALGORITHMS[1])
            lane_matrix, lane_names, _ = categorical_columns([string(run["worker_lane"]) for run in rows], "lane"; baseline = "1")
            X = hcat(ones(length(rows)), [log2(run["strategy_count"]) for run in rows], [log2(run["requirement_count"]) for run in rows], algorithm_matrix, lane_matrix)
            names = vcat(["intercept", "log2_strategy_count", "log2_requirement_count"], algorithm_names, lane_names)
        end
        y = Float64.([run["reference_attained"] for run in rows])
        coefficients, diagnostic = logistic_fit(
            "$(family)_reference_attainment_exploratory", "reference_attainment", "EXPLORATORY_NOT_PRESPECIFIED",
            y, X, names; population_n = length(rows), exclusions = 0,
        )
        append!(coefficient_rows, coefficients)
        push!(diagnostics, diagnostic)
    end
    return coefficient_rows, diagnostics
end

function sign_test_pvalue(wins, losses)
    n = wins + losses
    n == 0 && return 1.0
    tail = min(wins, losses)
    numerator = sum(binomial(BigInt(n), k) for k in 0:tail)
    return min(1.0, 2.0 * Float64(numerator // (BigInt(2)^n)))
end

function sign_interval(differences; alpha = 0.05)
    isempty(differences) && return missing, missing
    sorted = sort(collect(differences))
    n = length(sorted)
    cumulative = BigInt(0)
    denominator = BigInt(2)^n
    k = 0
    for candidate in 0:fld(n, 2)
        cumulative += binomial(BigInt(n), candidate)
        if Float64(cumulative // denominator) <= alpha / 2
            k = candidate + 1
        else
            break
        end
    end
    lower_index = max(1, k)
    upper_index = min(n, n - k + 1)
    return sorted[lower_index], sorted[upper_index]
end

function paired_comparison_rows(data)
    rows = Dict{String,Any}[]
    primary = [run for run in data.runs if primary_run(run)]
    for family in ("small_exact", "structured", "adversarial")
        algorithms = [algorithm for algorithm in ALGORITHM_ORDER if any(run -> run["family"] == family && run["algorithm_id"] == algorithm, primary)]
        for left_index in 1:length(algorithms)-1, right_index in left_index+1:length(algorithms)
            left_algorithm = algorithms[left_index]
            right_algorithm = algorithms[right_index]
            ids = intersect(
                Set(run["instance_id"] for run in primary if run["family"] == family && run["algorithm_id"] == left_algorithm),
                Set(run["instance_id"] for run in primary if run["family"] == family && run["algorithm_id"] == right_algorithm),
            )
            differences = Float64[]
            for id in ids
                left = data.index[(id, left_algorithm, PRIMARY_VARIANT[left_algorithm])]
                right = data.index[(id, right_algorithm, PRIMARY_VARIANT[right_algorithm])]
                push!(differences, left["par2_seconds"] - right["par2_seconds"])
            end
            wins = count(value -> value < 0, differences)
            losses = count(value -> value > 0, differences)
            ties = count(==(0), differences)
            lower, upper = sign_interval(differences)
            push!(rows, Dict{String,Any}(
                "comparison_class" => "primary_algorithm_PAR2",
                "family" => family,
                "left" => left_algorithm,
                "right" => right_algorithm,
                "paired_n" => length(differences),
                "left_wins" => wins,
                "ties" => ties,
                "left_losses" => losses,
                "median_left_minus_right" => empirical_quantile(differences, 0.5),
                "sign_interval_lower_95" => lower,
                "sign_interval_upper_95" => upper,
                "two_sided_sign_test_p" => sign_test_pvalue(wins, losses),
            ))
        end
    end
    # Declared paired preprocessing sensitivities.
    for algorithm in vcat(["requirement_mask_dp", MIP_ALGORITHM], HEURISTIC_ALGORITHMS)
        variants = algorithm == MIP_ALGORITHM || algorithm == "requirement_mask_dp" ? ("full_fixed_point", "mandatory_only") : ("full_fixed_point_then_reconstruct", "mandatory_only")
        for family in ("small_exact", "structured", "adversarial")
            ids = [id for id in keys(data.final_specs) if haskey(data.index, (id, algorithm, variants[1])) && haskey(data.index, (id, algorithm, variants[2])) && data.final_specs[id]["family"] == family]
            isempty(ids) && continue
            differences = [data.index[(id, algorithm, variants[1])]["par2_seconds"] - data.index[(id, algorithm, variants[2])]["par2_seconds"] for id in ids]
            wins = count(value -> value < 0, differences)
            losses = count(value -> value > 0, differences)
            ties = count(==(0), differences)
            lower, upper = sign_interval(differences)
            push!(rows, Dict{String,Any}(
                "comparison_class" => "preprocessing_PAR2",
                "family" => family,
                "left" => "$(algorithm):$(variants[1])",
                "right" => "$(algorithm):$(variants[2])",
                "paired_n" => length(differences),
                "left_wins" => wins,
                "ties" => ties,
                "left_losses" => losses,
                "median_left_minus_right" => empirical_quantile(differences, 0.5),
                "sign_interval_lower_95" => lower,
                "sign_interval_upper_95" => upper,
                "two_sided_sign_test_p" => sign_test_pvalue(wins, losses),
            ))
        end
    end
    return rows
end

svg_escape(value) = replace(replace(replace(replace(_string(value), "&" => "&amp;"), "<" => "&lt;"), ">" => "&gt;"), "\"" => "&quot;")

function svg_text(io, x, y, text_value; size = 12, anchor = "start", weight = "400", fill = INK, family = "Arial, Helvetica, sans-serif", rotate = nothing)
    transform = rotate === nothing ? "" : " transform=\"rotate($rotate $x $y)\""
    println(io, "<text x=\"$x\" y=\"$y\" text-anchor=\"$anchor\" font-family=\"$family\" font-size=\"$size\" font-weight=\"$weight\" fill=\"$fill\"$transform>$(svg_escape(text_value))</text>")
end

function svg_line(io, x1, y1, x2, y2; stroke = INK, width = 1.5, dash = "", opacity = 1.0)
    dash_attr = isempty(dash) ? "" : " stroke-dasharray=\"$dash\""
    println(io, "<line x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\" stroke=\"$stroke\" stroke-width=\"$width\" opacity=\"$opacity\"$dash_attr />")
end

function svg_rect(io, x, y, width, height; fill = "none", stroke = "none", stroke_width = 1.0, opacity = 1.0)
    println(io, "<rect x=\"$x\" y=\"$y\" width=\"$width\" height=\"$height\" fill=\"$fill\" stroke=\"$stroke\" stroke-width=\"$stroke_width\" opacity=\"$opacity\" />")
end

function svg_circle(io, x, y; radius = 4.0, fill = "white", stroke = INK, stroke_width = 1.5, opacity = 1.0)
    println(io, "<circle cx=\"$x\" cy=\"$y\" r=\"$radius\" fill=\"$fill\" stroke=\"$stroke\" stroke-width=\"$stroke_width\" opacity=\"$opacity\" />")
end

function svg_marker(io, x, y, index; color, filled = true, radius = 4.0)
    shape = mod(index - 1, 4) + 1
    fill = filled ? color : "white"
    if shape == 1
        svg_circle(io, x, y; radius, fill, stroke = color)
    elseif shape == 2
        svg_rect(io, x - radius, y - radius, 2radius, 2radius; fill, stroke = color, stroke_width = 1.5)
    elseif shape == 3
        points = "$(x),$(y-radius-1) $(x-radius-1),$(y+radius) $(x+radius+1),$(y+radius)"
        println(io, "<polygon points=\"$points\" fill=\"$fill\" stroke=\"$color\" stroke-width=\"1.5\" />")
    else
        svg_line(io, x - radius, y - radius, x + radius, y + radius; stroke = color, width = 1.5)
        svg_line(io, x - radius, y + radius, x + radius, y - radius; stroke = color, width = 1.5)
    end
end

function write_svg(path, width, height, title, subtitle, draw_function)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\" viewBox=\"0 0 $width $height\" role=\"img\" aria-labelledby=\"title desc\">")
        println(io, "<title id=\"title\">$(svg_escape(title))</title>")
        println(io, "<desc id=\"desc\">$(svg_escape(subtitle))</desc>")
        svg_rect(io, 0, 0, width, height; fill = "#FFFFFF")
        svg_text(io, 36, 36, title; size = 20, weight = "700")
        svg_text(io, 36, 58, subtitle; size = 11, fill = MID)
        draw_function(io)
        println(io, "</svg>")
    end
    return path
end

write_svg(draw_function::Function, path, width, height, title, subtitle) =
    write_svg(path, width, height, title, subtitle, draw_function)

function plot_performance_profile(data)
    primary = [run for run in data.runs if primary_run(run)]
    profile_rows = Dict{String,Any}[]
    facets = sort!(unique((run["family"], run["size_label"]) for run in primary))
    maximum_ratio = 1.0
    for (family, size) in facets
        facet_runs = [run for run in primary if run["family"] == family && run["size_label"] == size]
        for id in unique(run["instance_id"] for run in facet_runs)
            instance_runs = [run for run in facet_runs if run["instance_id"] == id]
            solved_times = [run["wall_clock_seconds"] for run in instance_runs if run["solved"] && run["wall_clock_seconds"] !== missing]
            best = isempty(solved_times) ? missing : minimum(solved_times)
            for run in instance_runs
                ratio = best !== missing && run["solved"] && run["wall_clock_seconds"] !== missing ? run["wall_clock_seconds"] / best : missing
                ratio !== missing && (maximum_ratio = max(maximum_ratio, ratio))
                push!(profile_rows, Dict{String,Any}(
                    "family" => family, "size" => size, "instance_id" => id,
                    "algorithm_id" => run["algorithm_id"], "algorithm" => ALGORITHM_LABEL[run["algorithm_id"]],
                    "performance_ratio" => ratio, "solved" => run["solved"],
                    "any_method_solved_instance" => best !== missing,
                    "record_path" => run["record_path"], "record_sha256" => run["record_sha256"],
                ))
            end
        end
    end
    tau_max = max(1.05, maximum_ratio)
    width, panel_width, panel_height = 1500, 690, 250
    columns = 2
    rows_count = ceil(Int, length(facets) / columns)
    height = 115 + rows_count * panel_height + 180
    path = joinpath(FIGURE_ROOT, "performance_profile.svg")
    write_svg(path, width, height, "Empirical performance profiles", "PAR-2/runtime evidence in the fixed eight-worker v2 environment; unsolved runs remain below a final profile value of one.") do io
        left0, top0 = 70, 86
        for (facet_index, (family, size)) in enumerate(facets)
            column = mod(facet_index - 1, columns)
            row_index = fld(facet_index - 1, columns)
            left = left0 + column * 730
            top = top0 + row_index * panel_height
            plot_left, plot_top, plot_width, plot_height = left + 50, top + 34, 600, 160
            svg_text(io, left, top + 10, "$(family) · $(size)"; size = 13, weight = "700")
            for tick in 0:4
                y = plot_top + plot_height - tick * plot_height / 4
                svg_line(io, plot_left, y, plot_left + plot_width, y; stroke = GRID, width = 0.8)
                svg_text(io, plot_left - 8, y + 4, @sprintf("%.2f", tick / 4); size = 9, anchor = "end", fill = MID)
            end
            svg_line(io, plot_left, plot_top, plot_left, plot_top + plot_height; width = 1.0)
            svg_line(io, plot_left, plot_top + plot_height, plot_left + plot_width, plot_top + plot_height; width = 1.0)
            for tick in range(0.0, log10(tau_max); length = 5)
                x = plot_left + plot_width * tick / max(log10(tau_max), 1e-9)
                svg_line(io, x, plot_top + plot_height, x, plot_top + plot_height + 5; width = 1.0)
                svg_text(io, x, plot_top + plot_height + 18, @sprintf("%.2g", 10.0^tick); size = 9, anchor = "middle", fill = MID)
            end
            facet_data = [row for row in profile_rows if row["family"] == family && row["size"] == size]
            algorithms = [algorithm for algorithm in ALGORITHM_ORDER if any(row -> row["algorithm_id"] == algorithm, facet_data)]
            taus = 10.0 .^ collect(range(0.0, log10(tau_max); length = 80))
            for (algorithm_index, algorithm) in enumerate(algorithms)
                algorithm_rows = [row for row in facet_data if row["algorithm_id"] == algorithm]
                isempty(algorithm_rows) && continue
                points = Tuple{Float64,Float64}[]
                for tau in taus
                    solved_at_tau = count(row -> row["performance_ratio"] !== missing && row["performance_ratio"] <= tau + 1e-12, algorithm_rows)
                    push!(points, (plot_left + plot_width * log10(tau) / max(log10(tau_max), 1e-9), plot_top + plot_height * (1 - solved_at_tau / length(algorithm_rows))))
                end
                color = PALETTE[mod(algorithm_index - 1, length(PALETTE)) + 1]
                dash = DASHES[mod(fld(algorithm_index - 1, length(PALETTE)), length(DASHES)) + 1]
                for index in 2:length(points)
                    svg_line(io, points[index-1][1], points[index-1][2], points[index][1], points[index][2]; stroke = color, width = 1.4, dash)
                end
            end
            svg_text(io, plot_left + plot_width / 2, plot_top + plot_height + 34, "performance ratio τ"; size = 9, anchor = "middle", fill = MID)
        end
        legend_top = height - 145
        svg_text(io, 70, legend_top - 12, "Algorithms (color and dash jointly encode series)"; size = 11, weight = "700")
        for (index, algorithm) in enumerate(ALGORITHM_ORDER)
            column = mod(index - 1, 3)
            row_index = fld(index - 1, 3)
            x = 80 + column * 475
            y = legend_top + row_index * 23
            color = PALETTE[mod(index - 1, length(PALETTE)) + 1]
            dash = DASHES[mod(fld(index - 1, length(PALETTE)), length(DASHES)) + 1]
            svg_line(io, x, y, x + 32, y; stroke = color, width = 2, dash)
            svg_marker(io, x + 16, y, index; color, radius = 3)
            svg_text(io, x + 42, y + 4, ALGORITHM_LABEL[algorithm]; size = 9)
        end
    end
    return profile_rows, path
end

function plot_runtime_vs_size(data)
    primary = [run for run in data.runs if primary_run(run) && run["family"] in ("small_exact", "structured")]
    figure_rows = Dict{String,Any}[]
    for key in sort!(unique((run["family"], run["requirement_count"], run["strategy_count"], run["algorithm_id"]) for run in primary))
        family, requirements, strategies, algorithm = key
        group = [run for run in primary if run["family"] == family && run["requirement_count"] == requirements && run["strategy_count"] == strategies && run["algorithm_id"] == algorithm]
        stats = summarize([run["par2_seconds"] for run in group])
        push!(figure_rows, Dict{String,Any}(
            "family" => family, "requirement_count" => requirements, "strategy_count" => strategies,
            "algorithm_id" => algorithm, "algorithm" => ALGORITHM_LABEL[algorithm],
            "registered_n" => length(group), "median_par2_seconds" => stats["median"],
            "q25_par2_seconds" => stats["q25"], "q75_par2_seconds" => stats["q75"],
            "trace_join_key" => "$family|N$strategies-R$requirements|$algorithm|primary",
        ))
    end
    values = Float64.([row["median_par2_seconds"] for row in figure_rows])
    ymin, ymax = minimum(values), maximum(values)
    log_min = floor(log10(max(ymin, 1e-6)))
    log_max = ceil(log10(max(ymax, 1e-6)))
    facets = sort!(unique((row["family"], row["requirement_count"]) for row in figure_rows))
    width, height = 1480, 890
    path = joinpath(FIGURE_ROOT, "runtime_vs_size.svg")
    write_svg(path, width, height, "Runtime versus registered strategy count", "Median PAR-2 seconds; all unsuccessful runs receive twice their registered limit and remain in the summaries.") do io
        for (facet_index, (family, requirements)) in enumerate(facets)
            column = mod(facet_index - 1, 2)
            row_index = fld(facet_index - 1, 2)
            left, top = 85 + column * 720, 90 + row_index * 350
            plot_width, plot_height = 610, 245
            svg_text(io, left, top - 8, "$(family) · r=$(requirements)"; size = 13, weight = "700")
            for tick in log_min:log_max
                y = top + plot_height * (1 - (tick - log_min) / max(log_max - log_min, 1))
                svg_line(io, left, y, left + plot_width, y; stroke = GRID, width = 0.8)
                svg_text(io, left - 10, y + 4, "10^$tick"; size = 9, anchor = "end", fill = MID)
            end
            facet_rows = [row for row in figure_rows if row["family"] == family && row["requirement_count"] == requirements]
            strategies = sort!(unique(row["strategy_count"] for row in facet_rows))
            xmap(value) = left + (length(strategies) == 1 ? plot_width / 2 : plot_width * (findfirst(==(value), strategies) - 1) / (length(strategies) - 1))
            ymap(value) = top + plot_height * (1 - (log10(max(Float64(value), 1e-6)) - log_min) / max(log_max - log_min, 1))
            svg_line(io, left, top, left, top + plot_height; width = 1.0)
            svg_line(io, left, top + plot_height, left + plot_width, top + plot_height; width = 1.0)
            for strategy in strategies
                x = xmap(strategy)
                svg_text(io, x, top + plot_height + 20, strategy; size = 9, anchor = "middle", fill = MID)
            end
            algorithms = [algorithm for algorithm in ALGORITHM_ORDER if any(row -> row["algorithm_id"] == algorithm, facet_rows)]
            for (algorithm_index, algorithm) in enumerate(algorithms)
                algorithm_rows = sort([row for row in facet_rows if row["algorithm_id"] == algorithm]; by = row -> row["strategy_count"])
                color = PALETTE[mod(algorithm_index - 1, length(PALETTE)) + 1]
                dash = DASHES[mod(fld(algorithm_index - 1, length(PALETTE)), length(DASHES)) + 1]
                for index in 2:length(algorithm_rows)
                    svg_line(io, xmap(algorithm_rows[index-1]["strategy_count"]), ymap(algorithm_rows[index-1]["median_par2_seconds"]), xmap(algorithm_rows[index]["strategy_count"]), ymap(algorithm_rows[index]["median_par2_seconds"]); stroke = color, width = 1.5, dash)
                end
                for row in algorithm_rows
                    svg_marker(io, xmap(row["strategy_count"]), ymap(row["median_par2_seconds"]), algorithm_index; color, radius = 3.5)
                end
            end
            svg_text(io, left + plot_width / 2, top + plot_height + 38, "strategies n"; size = 10, anchor = "middle")
        end
        legend_top = 790
        for (index, algorithm) in enumerate(ALGORITHM_ORDER)
            column = mod(index - 1, 4)
            row_index = fld(index - 1, 4)
            x = 70 + column * 355
            y = legend_top + row_index * 19
            color = PALETTE[mod(index - 1, length(PALETTE)) + 1]
            dash = DASHES[mod(fld(index - 1, length(PALETTE)), length(DASHES)) + 1]
            svg_line(io, x, y, x + 25, y; stroke = color, width = 1.8, dash)
            svg_marker(io, x + 12, y, index; color, radius = 2.8)
            svg_text(io, x + 33, y + 3, ALGORITHM_LABEL[algorithm]; size = 8)
        end
    end
    return figure_rows, path
end

function heat_color(value, maximum_value)
    value === missing && return "#E8EBEE"
    maximum_value <= 0 && return "#EAF0F7"
    fraction = clamp(log1p(Float64(value)) / log1p(maximum_value), 0.0, 1.0)
    start = (234, 240, 247)
    finish = (59, 111, 182)
    rgb = ntuple(index -> round(Int, start[index] + fraction * (finish[index] - start[index])), 3)
    return @sprintf("#%02X%02X%02X", rgb...)
end

function plot_gap_heatmap(data)
    primary = [run for run in data.runs if primary_run(run) && run["algorithm_id"] in HEURISTIC_ALGORITHMS &&
        run["family"] in ("small_exact", "structured")]
    cells = Dict{String,Any}[]
    cell_keys = sort!(unique((run["family"], run["size_label"]) for run in primary))
    for (family, size) in cell_keys, algorithm in HEURISTIC_ALGORITHMS
        group = [run for run in primary if run["family"] == family && run["size_label"] == size && run["algorithm_id"] == algorithm]
        stats = summarize([run["relative_gap"] for run in group])
        push!(cells, Dict{String,Any}(
            "family" => family, "size" => size, "algorithm_id" => algorithm,
            "algorithm" => ALGORITHM_LABEL[algorithm], "registered_n" => length(group),
            "gap_available_n" => stats["n"], "median_relative_gap" => stats["median"],
            "worst_relative_gap" => stats["maximum"],
            "trace_join_key" => "$family|$size|$algorithm|primary",
        ))
    end
    maximum_gap = maximum(Float64(row["median_relative_gap"]) for row in cells if row["median_relative_gap"] !== missing)
    width = 1680
    left = 315
    cell_width = 125
    cell_height = 44
    height = 150 + length(HEURISTIC_ALGORITHMS) * cell_height
    path = joinpath(FIGURE_ROOT, "heuristic_gap_heatmap.svg")
    write_svg(path, width, height, "Median heuristic burden gaps", "Family A cells use exact finite optima; Family B cells use exactly rechecked HiGHS-optimal references. Evidence classes are not pooled.") do io
        for (column, (family, size)) in enumerate(cell_keys)
            x = left + (column - 1) * cell_width
            svg_text(io, x + cell_width / 2, 90, replace(size, "-" => "\n"); size = 9, anchor = "middle", weight = "700")
            svg_text(io, x + cell_width / 2, 106, family == "small_exact" ? "EXACT" : "MIP REF"; size = 8, anchor = "middle", fill = MID)
        end
        for (row_index, algorithm) in enumerate(HEURISTIC_ALGORITHMS)
            y = 120 + (row_index - 1) * cell_height
            svg_text(io, left - 12, y + 27, ALGORITHM_LABEL[algorithm]; size = 10, anchor = "end")
            for (column, key) in enumerate(cell_keys)
                family, size = key
                cell = only(row for row in cells if row["family"] == family && row["size"] == size && row["algorithm_id"] == algorithm)
                x = left + (column - 1) * cell_width
                fill = heat_color(cell["median_relative_gap"], maximum_gap)
                svg_rect(io, x, y, cell_width - 3, cell_height - 3; fill, stroke = "white", stroke_width = 1)
                label = cell["median_relative_gap"] === missing ? "NA" : @sprintf("%.3g", Float64(cell["median_relative_gap"]))
                text_color = cell["median_relative_gap"] !== missing && maximum_gap > 0 && log1p(Float64(cell["median_relative_gap"])) / log1p(maximum_gap) > 0.55 ? "white" : INK
                svg_text(io, x + (cell_width - 3) / 2, y + 27, label; size = 10, anchor = "middle", weight = "700", fill = text_color, family = "Menlo, monospace")
            end
        end
        svg_text(io, left, height - 18, "Color spans the full observed median-gap range 0 to $(format_summary_value(maximum_gap)). NA is unavailable, never zero."; size = 10, fill = MID)
    end
    return cells, path
end

function plot_preprocessing(preprocessing_detailed)
    rows = [row for row in preprocessing_detailed if row["family"] == "structured" && row["variable_reduction_fraction"] !== missing]
    width, height = 1510, 545
    path = joinpath(FIGURE_ROOT, "preprocessing_reduction.svg")
    y_par2 = [row["log_par2_difference_full_minus_mandatory"] for row in rows if row["log_par2_difference_full_minus_mandatory"] !== missing]
    y_nodes = [row["log1p_node_difference_full_minus_mandatory"] for row in rows if row["log1p_node_difference_full_minus_mandatory"] !== missing]
    y_req = [row["requirement_reduction_fraction"] for row in rows if row["requirement_reduction_fraction"] !== missing]
    panels = [
        ("log(PAR-2 full / mandatory)", y_par2, "log_par2_difference_full_minus_mandatory"),
        ("log((1+nodes full)/(1+nodes mandatory))", y_nodes, "log1p_node_difference_full_minus_mandatory"),
        ("requirement reduction fraction", y_req, "requirement_reduction_fraction"),
    ]
    write_svg(path, width, height, "Exact preprocessing reductions and paired computational changes", "Family B MIP pairs only. Every generated point is shown; unavailable node diagnostics and generation failures are counted in the linked table.") do io
        for (panel_index, (label, values, field)) in enumerate(panels)
            left = 75 + (panel_index - 1) * 490
            top, plot_width, plot_height = 115, 415, 315
            svg_text(io, left, top - 18, label; size = 12, weight = "700")
            isempty(values) && begin
                svg_text(io, left + plot_width / 2, top + plot_height / 2, "UNAVAILABLE"; anchor = "middle", fill = MID)
                continue
            end
            ymin, ymax = minimum(values), maximum(values)
            ymin == ymax && (ymin -= 0.5; ymax += 0.5)
            padding = 0.08 * (ymax - ymin)
            ymin -= padding
            ymax += padding
            xmap(value) = left + plot_width * Float64(value)
            ymap(value) = top + plot_height * (1 - (Float64(value) - ymin) / (ymax - ymin))
            for tick in 0:4
                x = left + tick * plot_width / 4
                svg_line(io, x, top, x, top + plot_height; stroke = GRID, width = 0.8)
                svg_text(io, x, top + plot_height + 18, @sprintf("%.2f", tick / 4); size = 9, anchor = "middle", fill = MID)
                y = top + plot_height * (1 - tick / 4)
                svg_line(io, left, y, left + plot_width, y; stroke = GRID, width = 0.6)
                svg_text(io, left - 7, y + 3, @sprintf("%.2g", ymin + (ymax - ymin) * tick / 4); size = 8, anchor = "end", fill = MID)
            end
            if ymin <= 0 <= ymax
                svg_line(io, left, ymap(0), left + plot_width, ymap(0); stroke = MID, width = 1.2, dash = "4 3")
            end
            svg_line(io, left, top, left, top + plot_height; width = 1.0)
            svg_line(io, left, top + plot_height, left + plot_width, top + plot_height; width = 1.0)
            for row in rows
                value = row[field]
                value === missing && continue
                size_index = occursin("N192", row["size"]) ? 2 : 1
                color = size_index == 1 ? PALETTE[1] : PALETTE[3]
                filled = row["full_status"] in SOLVED_STATUSES && row["mandatory_status"] in SOLVED_STATUSES
                svg_marker(io, xmap(row["variable_reduction_fraction"]), ymap(value), size_index; color, filled, radius = 3.5)
            end
            svg_text(io, left + plot_width / 2, top + plot_height + 38, "variable reduction fraction"; size = 10, anchor = "middle")
            svg_text(io, left, top + plot_height + 58, "● N64   ▲ N192; open marks indicate an unsuccessful pair member"; size = 9, fill = MID)
        end
    end
    return rows, path
end

function plot_multistart(multistart_detailed)
    values = Dict{String,Any}[]
    for row in multistart_detailed
        relative = parse_exact(row["relative_improvement"])
        relative === missing && continue
        push!(values, merge(copy(row), Dict("relative_improvement_numeric" => Float64(relative))))
    end
    groups = sort!(unique((row["family"], row["size"]) for row in multistart_detailed))
    maximum_value = isempty(values) ? 1.0 : maximum(row["relative_improvement_numeric"] for row in values)
    width, height = 1540, 650
    left, top, plot_width, plot_height = 95, 105, 1380, 420
    path = joinpath(FIGURE_ROOT, "multistart_improvement.svg")
    write_svg(path, width, height, "Improvement from the first random deletion start", "Primary mandatory-only 32-start method; exact burden improvement relative to start one. Missing runs remain counted below the plot.") do io
        ymax = max(maximum_value, 0.01)
        for tick in 0:5
            y = top + plot_height * (1 - tick / 5)
            svg_line(io, left, y, left + plot_width, y; stroke = GRID, width = 0.8)
            svg_text(io, left - 10, y + 4, @sprintf("%.3f", ymax * tick / 5); size = 9, anchor = "end", fill = MID)
        end
        svg_line(io, left, top, left, top + plot_height; width = 1)
        svg_line(io, left, top + plot_height, left + plot_width, top + plot_height; width = 1)
        for (group_index, (family, size)) in enumerate(groups)
            x_center = left + plot_width * (group_index - 0.5) / length(groups)
            group_rows = [row for row in values if row["family"] == family && row["size"] == size]
            for row in group_rows
                digest = SHA.sha256(row["instance_id"])
                jitter = (Int(digest[1]) / 255 - 0.5) * 48
                y = top + plot_height * (1 - row["relative_improvement_numeric"] / ymax)
                color = PALETTE[mod(group_index - 1, length(PALETTE)) + 1]
                svg_marker(io, x_center + jitter, y, group_index; color, filled = false, radius = 3.2)
            end
            if !isempty(group_rows)
                median_value = empirical_quantile([row["relative_improvement_numeric"] for row in group_rows], 0.5)
                y = top + plot_height * (1 - median_value / ymax)
                svg_line(io, x_center - 32, y, x_center + 32, y; stroke = INK, width = 3)
            end
            svg_text(io, x_center, top + plot_height + 20, size; size = 8, anchor = "middle", rotate = -30)
            svg_text(io, x_center, top + plot_height + 57, family; size = 8, anchor = "middle", fill = MID, rotate = -30)
        end
        unavailable = count(row -> row["start_count_available"] == 0, multistart_detailed)
        svg_text(io, left, height - 24, "All $(length(multistart_detailed)) registered primary rows remain in the denominator; $unavailable have no 32-start endpoint and are not plotted as zero."; size = 10, fill = MID)
    end
    return values, path
end

function plot_family_a_gap_distributions(data)
    rows = [run for run in data.runs if run["family"] == "small_exact" &&
        run["algorithm_id"] in HEURISTIC_ALGORITHMS && primary_run(run) &&
        run["reference_class"] == "EXACT_FINITE" && run["relative_gap"] !== missing]
    maximum_gap = isempty(rows) ? 1.0 : maximum(Float64(run["relative_gap"]) for run in rows)
    width, height = 1460, 690
    left, top, plot_width, plot_height = 350, 100, 1020, 500
    path = joinpath(FIGURE_ROOT, "family_a_exact_gap_distributions.svg")
    write_svg(path, width, height, "Family A exact heuristic-gap distributions", "Exact finite optima require completed enumeration and matching requirement-mask DP; every available point is shown.") do io
        xmax = max(maximum_gap, 0.01)
        for tick in 0:5
            x = left + plot_width * tick / 5
            svg_line(io, x, top, x, top + plot_height; stroke = GRID, width = 0.8)
            svg_text(io, x, top + plot_height + 20, @sprintf("%.3g", xmax * tick / 5); size = 9, anchor = "middle", fill = MID)
        end
        for (index, algorithm) in enumerate(HEURISTIC_ALGORITHMS)
            y = top + (index - 0.5) * plot_height / length(HEURISTIC_ALGORITHMS)
            algorithm_rows = [run for run in rows if run["algorithm_id"] == algorithm]
            svg_text(io, left - 12, y + 4, ALGORITHM_LABEL[algorithm]; size = 10, anchor = "end")
            for run in algorithm_rows
                x = left + plot_width * Float64(run["relative_gap"]) / xmax
                digest = SHA.sha256(run["instance_id"])
                jitter = (Int(digest[2]) / 255 - 0.5) * 18
                color = PALETTE[mod(index - 1, length(PALETTE)) + 1]
                svg_marker(io, x, y + jitter, index; color, filled = false, radius = 3)
            end
            if !isempty(algorithm_rows)
                values = Float64.([run["relative_gap"] for run in algorithm_rows])
                q25, median_value, q75 = empirical_quantile(values, 0.25), empirical_quantile(values, 0.5), empirical_quantile(values, 0.75)
                svg_line(io, left + plot_width * q25 / xmax, y, left + plot_width * q75 / xmax, y; width = 5, stroke = INK)
                svg_line(io, left + plot_width * median_value / xmax, y - 8, left + plot_width * median_value / xmax, y + 8; width = 2, stroke = INK)
            end
        end
        svg_text(io, left + plot_width / 2, top + plot_height + 48, "exact relative burden gap"; size = 11, anchor = "middle")
        unavailable = count(run -> run["family"] == "small_exact" && run["algorithm_id"] in HEURISTIC_ALGORITHMS && primary_run(run) && run["relative_gap"] === missing, data.runs)
        svg_text(io, left, height - 18, "$unavailable registered Family A heuristic rows have no exact reference/gap and are not plotted as zero."; size = 10, fill = MID)
    end
    return rows, path
end

function plot_burden_runtime_frontier(data)
    rows = [run for run in data.runs if run["family"] == "structured" &&
        run["algorithm_id"] in HEURISTIC_ALGORITHMS && primary_run(run) &&
        run["reference_class"] == "MIP_OPTIMAL_EXACTLY_RECHECKED" && run["relative_gap"] !== missing]
    width, height = 1420, 720
    left, top, plot_width, plot_height = 105, 105, 1010, 520
    xmax = isempty(rows) ? 1.0 : maximum(Float64(run["relative_gap"]) for run in rows)
    par2_values = isempty(rows) ? [1.0] : [run["par2_seconds"] for run in rows]
    ymin, ymax = floor(log10(minimum(par2_values))), ceil(log10(maximum(par2_values)))
    path = joinpath(FIGURE_ROOT, "family_b_burden_runtime_frontier.svg")
    write_svg(path, width, height, "Family B burden gap versus penalized runtime", "MIP-reference relative gap and PAR-2 seconds. The fixed eight-worker environment is part of the runtime estimand.") do io
        xscale = max(xmax, 0.01)
        for tick in 0:5
            x = left + plot_width * tick / 5
            svg_line(io, x, top, x, top + plot_height; stroke = GRID, width = 0.8)
            svg_text(io, x, top + plot_height + 20, @sprintf("%.3g", xscale * tick / 5); size = 9, anchor = "middle", fill = MID)
        end
        for tick in ymin:ymax
            y = top + plot_height * (1 - (tick - ymin) / max(ymax - ymin, 1))
            svg_line(io, left, y, left + plot_width, y; stroke = GRID, width = 0.8)
            svg_text(io, left - 10, y + 4, "10^$tick"; size = 9, anchor = "end", fill = MID)
        end
        for run in rows
            index = findfirst(==(run["algorithm_id"]), HEURISTIC_ALGORITHMS)
            color = PALETTE[mod(index - 1, length(PALETTE)) + 1]
            x = left + plot_width * Float64(run["relative_gap"]) / xscale
            y = top + plot_height * (1 - (log10(run["par2_seconds"]) - ymin) / max(ymax - ymin, 1))
            svg_marker(io, x, y, index; color, filled = run["solved"], radius = 3.3)
        end
        svg_text(io, left + plot_width / 2, top + plot_height + 48, "MIP-reference relative burden gap"; size = 11, anchor = "middle")
        svg_text(io, 25, top + plot_height / 2, "PAR-2 seconds"; size = 11, anchor = "middle", rotate = -90)
        unavailable = count(run -> run["family"] == "structured" && run["algorithm_id"] in HEURISTIC_ALGORITHMS && primary_run(run) && run["relative_gap"] === missing, data.runs)
        svg_text(io, 1140, 118, "Gap-unavailable rows: $unavailable"; size = 10, weight = "700")
        for (index, algorithm) in enumerate(HEURISTIC_ALGORITHMS)
            y = 150 + (index - 1) * 34
            color = PALETTE[mod(index - 1, length(PALETTE)) + 1]
            svg_marker(io, 1152, y, index; color, radius = 3.5)
            svg_text(io, 1168, y + 4, ALGORITHM_LABEL[algorithm]; size = 9)
        end
    end
    return rows, path
end

function plot_solved_fraction_grid(data)
    primary = [run for run in data.runs if primary_run(run)]
    facets = sort!(unique((run["family"], run["size_label"]) for run in primary))
    cells = Dict{String,Any}[]
    for (family, size) in facets, algorithm in ALGORITHM_ORDER
        group = [run for run in primary if run["family"] == family && run["size_label"] == size && run["algorithm_id"] == algorithm]
        isempty(group) && continue
        solved = count(run -> run["solved"], group)
        push!(cells, Dict{String,Any}(
            "family" => family, "size" => size, "algorithm_id" => algorithm,
            "algorithm" => ALGORITHM_LABEL[algorithm], "solved_n" => solved,
            "registered_n" => length(group), "solved_fraction" => solved / length(group),
            "trace_join_key" => "$family|$size|$algorithm|primary",
        ))
    end
    left, cell_width, cell_height = 325, 140, 41
    # Keep every registered family/size facet inside the SVG view box.  The
    # final registry has thirteen facets, so a fixed 1840-pixel canvas clipped
    # the last columns even though their machine-readable rows were complete.
    width = left + length(facets) * cell_width + 45
    height = 150 + length(ALGORITHM_ORDER) * cell_height
    path = joinpath(FIGURE_ROOT, "solved_fraction_grid.svg")
    write_svg(path, width, height, "Solved fraction by registered size cell", "Exactly feasible candidates within registered limits; failed generation, interruption, memory failure, and rejected candidates remain in denominators.") do io
        for (column, (family, size)) in enumerate(facets)
            x = left + (column - 1) * cell_width
            svg_text(io, x + cell_width / 2, 88, size; size = 8, anchor = "middle", weight = "700", rotate = -20)
            svg_text(io, x + cell_width / 2, 111, family; size = 8, anchor = "middle", fill = MID)
        end
        for (row_index, algorithm) in enumerate(ALGORITHM_ORDER)
            y = 125 + (row_index - 1) * cell_height
            svg_text(io, left - 12, y + 25, ALGORITHM_LABEL[algorithm]; size = 10, anchor = "end")
            for (column, (family, size)) in enumerate(facets)
                matching = [cell for cell in cells if cell["family"] == family && cell["size"] == size && cell["algorithm_id"] == algorithm]
                x = left + (column - 1) * cell_width
                if isempty(matching)
                    svg_rect(io, x, y, cell_width - 3, cell_height - 3; fill = "#E8EBEE", stroke = "white")
                    svg_text(io, x + (cell_width - 3)/2, y + 25, "NA"; size = 9, anchor = "middle", fill = MID)
                else
                    cell = only(matching)
                    fill = heat_color(1 - cell["solved_fraction"], 1.0)
                    svg_rect(io, x, y, cell_width - 3, cell_height - 3; fill, stroke = "white")
                    color = cell["solved_fraction"] < 0.45 ? "white" : INK
                    svg_text(io, x + (cell_width - 3)/2, y + 25, "$(cell["solved_n"])/$(cell["registered_n"])"; size = 9, anchor = "middle", weight = "700", fill = color, family = "Menlo, monospace")
                end
            end
        end
    end
    return cells, path
end

function plot_semantic_evaluations(data)
    rows = [run for run in data.runs if run["algorithm_id"] in DELETION_ALGORITHMS && primary_run(run) && run["frontier_checks"] !== missing && run["closure_checks"] !== missing]
    summary_rows = Dict{String,Any}[]
    for (family, algorithm) in sort!(unique((run["family"], run["algorithm_id"]) for run in rows))
        group = [run for run in rows if run["family"] == family && run["algorithm_id"] == algorithm]
        totals = [run["frontier_checks"] + run["closure_checks"] for run in group]
        stats = summarize(totals)
        push!(summary_rows, Dict{String,Any}(
            "family" => family, "algorithm_id" => algorithm, "algorithm" => ALGORITHM_LABEL[algorithm],
            "available_n" => stats["n"], "median_total_checks" => stats["median"],
            "q25_total_checks" => stats["q25"], "q75_total_checks" => stats["q75"],
            "trace_join_key" => "$family|$algorithm|primary",
        ))
    end
    width, height = 1480, 680
    left, top, plot_width, plot_height = 350, 100, 1020, 490
    maximum_value = isempty(summary_rows) ? 1.0 : maximum(Float64(row["q75_total_checks"]) for row in summary_rows)
    path = joinpath(FIGURE_ROOT, "semantic_evaluation_counts.svg")
    write_svg(path, width, height, "Exact frontier and closure evaluations", "Primary certified-deletion variants; medians and interquartile ranges are finite-design summaries, not proof or runtime guarantees.") do io
        families = ["small_exact", "structured", "adversarial"]
        for (index, algorithm) in enumerate(DELETION_ALGORITHMS)
            y = top + (index - 0.5) * plot_height / length(DELETION_ALGORITHMS)
            svg_text(io, left - 12, y + 4, ALGORITHM_LABEL[algorithm]; size = 10, anchor = "end")
            for (family_index, family) in enumerate(families)
                matching = [row for row in summary_rows if row["family"] == family && row["algorithm_id"] == algorithm]
                isempty(matching) && continue
                row = only(matching)
                offset = (family_index - 2) * 13
                x25 = left + plot_width * Float64(row["q25_total_checks"]) / max(maximum_value, 1)
                x50 = left + plot_width * Float64(row["median_total_checks"]) / max(maximum_value, 1)
                x75 = left + plot_width * Float64(row["q75_total_checks"]) / max(maximum_value, 1)
                color = PALETTE[family_index]
                svg_line(io, x25, y + offset, x75, y + offset; stroke = color, width = 3)
                svg_marker(io, x50, y + offset, family_index; color, radius = 3.5)
            end
        end
        for tick in 0:5
            x = left + plot_width * tick / 5
            svg_line(io, x, top, x, top + plot_height; stroke = GRID, width = 0.6)
            svg_text(io, x, top + plot_height + 20, @sprintf("%.0f", maximum_value * tick / 5); size = 9, anchor = "middle", fill = MID)
        end
        svg_text(io, left, top + plot_height + 52, "● small exact   ■ structured   ▲ adversarial"; size = 10, fill = MID)
        unavailable = count(run -> run["algorithm_id"] in DELETION_ALGORITHMS && primary_run(run) && (run["frontier_checks"] === missing || run["closure_checks"] === missing), data.runs)
        svg_text(io, left + 520, top + plot_height + 52, "Unavailable registered rows: $unavailable (not encoded as zero)."; size = 10, fill = MID)
    end
    return summary_rows, path
end

function plot_adversarial(adversarial)
    rows = [row for row in adversarial if row["observed_burden_ratio"] != "UNAVAILABLE" && row["algorithm_id"] in HEURISTIC_ALGORITHMS]
    mechanisms = sort!(unique(row["mechanism"] for row in adversarial))
    maximum_ratio = maximum(Float64(parse_exact(row["observed_burden_ratio"])) for row in rows)
    width, height = 1540, 1210
    path = joinpath(FIGURE_ROOT, "adversarial_mechanisms.svg")
    write_svg(path, width, height, "Adversarial mechanism outcomes", "Observed exact-feasible burden ratios by registered scale; analytic ratios are limited to the proved heaviest-safe-first rows in the linked table.") do io
        for (mechanism_index, mechanism) in enumerate(mechanisms)
            column = mod(mechanism_index - 1, 2)
            row_index = fld(mechanism_index - 1, 2)
            left, top = 85 + column * 745, 95 + row_index * 235
            plot_width, plot_height = 640, 155
            svg_text(io, left, top - 10, replace(mechanism, "_" => " "); size = 11, weight = "700")
            for tick in 0:4
                y = top + plot_height * (1 - tick / 4)
                svg_line(io, left, y, left + plot_width, y; stroke = GRID, width = 0.7)
                ratio_tick = exp(log(maximum_ratio) * tick / 4)
                svg_text(io, left - 8, y + 3, @sprintf("%.2g", ratio_tick); size = 8, anchor = "end", fill = MID)
            end
            scales = ["small", "medium", "large"]
            for (scale_index, scale) in enumerate(scales)
                x = left + plot_width * (scale_index - 0.5) / 3
                svg_text(io, x, top + plot_height + 18, scale; size = 9, anchor = "middle", fill = MID)
            end
            mechanism_rows = [row for row in rows if row["mechanism"] == mechanism]
            for (algorithm_index, algorithm) in enumerate(HEURISTIC_ALGORITHMS)
                algorithm_rows = sort([row for row in mechanism_rows if row["algorithm_id"] == algorithm]; by = row -> findfirst(==(row["scale"]), scales))
                color = PALETTE[mod(algorithm_index - 1, length(PALETTE)) + 1]
                dash = DASHES[mod(fld(algorithm_index - 1, length(PALETTE)), length(DASHES)) + 1]
                points = Tuple{Float64,Float64}[]
                for row in algorithm_rows
                    scale_index = findfirst(==(row["scale"]), scales)
                    ratio = Float64(parse_exact(row["observed_burden_ratio"]))
                    push!(points, (left + plot_width * (scale_index - 0.5) / 3, top + plot_height * (1 - log(ratio) / log(maximum_ratio))))
                end
                for index in 2:length(points)
                    svg_line(io, points[index-1][1], points[index-1][2], points[index][1], points[index][2]; stroke = color, width = 1.3, dash)
                end
                for point in points
                    svg_marker(io, point[1], point[2], algorithm_index; color, radius = 3)
                end
            end
        end
        svg_text(io, 85, 1075, "Logarithmic burden-ratio axis spans the complete observed range 1 to $(format_summary_value(maximum_ratio)); no point is clipped."; size = 10, fill = MID)
        for (index, algorithm) in enumerate(HEURISTIC_ALGORITHMS)
            column = mod(index - 1, 3)
            row_index = fld(index - 1, 3)
            x = 85 + column * 470
            y = 1110 + row_index * 20
            color = PALETTE[mod(index - 1, length(PALETTE)) + 1]
            dash = DASHES[mod(fld(index - 1, length(PALETTE)), length(DASHES)) + 1]
            svg_line(io, x, y, x + 28, y; stroke = color, width = 1.7, dash)
            svg_marker(io, x + 14, y, index; color, radius = 2.8)
            svg_text(io, x + 36, y + 3, ALGORITHM_LABEL[algorithm]; size = 8)
        end
    end
    return rows, path
end

function structural_diagnostic_rows(data)
    rows = Dict{String,Any}[]
    for id in sort!(collect(keys(data.final_specs)))
        spec = data.final_specs[id]
        meta = data.metadata[id]
        push!(rows, Dict{String,Any}(
            "instance_id" => id,
            "family" => spec["family"],
            "size" => size_label(spec),
            "replicate_id" => spec["replicate_id"],
            "generation_status" => meta["generation_status"],
            "strategy_count_requested" => spec["strategy_count"],
            "requirement_count_requested" => spec["tagged_requirement_count"],
            "frontier_rows_requested" => spec["frontier_row_count"],
            "module_rows_requested" => spec["module_row_count"],
            "coverage_density_level" => spec["coverage_density_level"],
            "coverage_density_realized" => meta["realized_active_coverage_density"],
            "module_overlap_level" => spec["module_overlap_level"],
            "module_overlap_realized" => meta["realized_module_overlap"],
            "bundle_prevalence_level" => spec["bundle_prevalence_level"],
            "bundle_prevalence_realized" => meta["realized_bundle_prevalence"],
            "unique_carrier_frequency_level" => spec["unique_carrier_frequency_level"],
            "unique_carrier_frequency_realized" => meta["realized_unique_carrier_frequency"],
            "weight_dispersion_level" => spec["weight_dispersion_level"],
            "frontier_module_correlation_level" => spec["frontier_module_correlation_level"],
            "frontier_module_association_realized" => meta["realized_frontier_module_association"],
            "mechanism" => spec["mechanism"],
            "mechanism_parameter" => spec["mechanism_parameter"],
            "generation_path" => meta["generation_path"],
            "instance_path" => meta["instance_path"],
            "instance_sha256" => meta["instance_sha256"],
        ))
    end
    return rows
end

function deletion_summary_rows(data)
    rows = Dict{String,Any}[]
    primary = [run for run in data.runs if run["algorithm_id"] in DELETION_ALGORITHMS && primary_run(run)]
    for key in sort!(unique((run["family"], run["size_label"], run["algorithm_id"]) for run in primary))
        family, size, algorithm = key
        group = [run for run in primary if run["family"] == family && run["size_label"] == size && run["algorithm_id"] == algorithm]
        frontier = summarize([run["frontier_checks"] for run in group])
        closure = summarize([run["closure_checks"] for run in group])
        scans = summarize([run["complete_scans"] for run in group])
        gap = summarize([run["relative_gap"] for run in group])
        push!(rows, Dict{String,Any}(
            "family" => family,
            "size" => size,
            "algorithm" => ALGORITHM_LABEL[algorithm],
            "algorithm_id" => algorithm,
            "registered_n" => length(group),
            "solved_n" => count(run -> run["solved"], group),
            "irreducible_certified_n" => count(run -> run["irreducible"] === true, group),
            "frontier_checks_available_n" => frontier["n"],
            "frontier_checks_median" => format_summary_value(frontier["median"]),
            "closure_checks_available_n" => closure["n"],
            "closure_checks_median" => format_summary_value(closure["median"]),
            "complete_scans_median" => format_summary_value(scans["median"]),
            "relative_gap_available_n" => gap["n"],
            "relative_gap_median" => format_summary_value(gap["median"]),
            "relative_gap_worst" => format_summary_value(gap["maximum"]),
        ))
    end
    return rows
end

function environment_rows()
    path = joinpath(RESULTS_ROOT, "environment_amendment_002.toml")
    environment = TOML.parsefile(path)
    rows = Dict{String,Any}[]
    for key in sort!(collect(keys(environment)))
        value = environment[key]
        value isa AbstractDict && continue
        value isa AbstractVector && continue
        push!(rows, Dict{String,Any}(
            "field" => key,
            "value" => value,
            "source_path" => relpath(path, REPOSITORY_ROOT),
            "source_sha256" => sha256_file(path),
        ))
    end
    return rows
end

function write_table_pair(stem, columns, rows; caption, label, tex_columns = columns, tex_rows = rows, tex_alignment = nothing)
    csv_path = write_csv(joinpath(TABLE_ROOT, "$stem.csv"), columns, rows)
    tex_path = write_tex(joinpath(TABLE_ROOT, "$stem.tex"), tex_columns, tex_rows; caption, label, alignment = tex_alignment)
    return csv_path, tex_path
end

function markdown_link(path)
    return relpath(path, dirname(REPORT_PATH))
end

function write_figure_includes(figure_paths)
    path = joinpath(FIGURE_ROOT, "figure_includes.tex")
    captions = Dict(
        "performance_profile.svg" => "Synthetic performance profiles under the fixed eight-worker v2 environment. Unsuccessful runs remain in method denominators; the figure is computational evidence, not an algorithmic guarantee.",
        "runtime_vs_size.svg" => "Median PAR-2 runtime across registered size cells. Values are synthetic experimental measurements conditional on the declared hardware and concurrency.",
        "heuristic_gap_heatmap.svg" => "Median heuristic burden gaps. Family A uses exact finite optima; Family B uses exactly rechecked HiGHS-optimal references, which are solver evidence rather than formal proof.",
        "preprocessing_reduction.svg" => "Exact preprocessing reductions and paired computational changes. Reconstruction and feasibility are exact finite checks; runtime and node changes are synthetic experimental evidence.",
        "multistart_improvement.svg" => "Exact burden improvement of registered 32-start deletion over start one. The endpoints are exactly feasible finite computations; their distribution is synthetic evidence.",
        "family_a_exact_gap_distributions.svg" => "Family A heuristic gaps relative to optima established by agreeing complete finite methods. This is exact finite computation, not Lean verification.",
        "family_b_burden_runtime_frontier.svg" => "Family B burden quality against PAR-2. Burden references are exactly rechecked HiGHS-optimal incumbents; runtime is eight-worker synthetic evidence.",
        "solved_fraction_grid.svg" => "Solved fractions with all registered failures retained. This is synthetic experimental evidence under registered limits.",
        "semantic_evaluation_counts.svg" => "Exact frontier and closure evaluation counts for certified deletion. Counts are computational measurements and do not prove an approximation factor.",
        "adversarial_mechanisms.svg" => "Adversarial synthetic burden ratios. Only the registered heaviest-safe-first family has a separate human proof for its analytic ratio; other curves are finite computation.",
    )
    open(path, "w") do io
        println(io, "% Generated by julia/scripts/analyze_algorithmic_compression_v2.jl")
        for (index, figure) in enumerate(figure_paths)
            index > 1 && println(io)
            stem = splitext(basename(figure))[1]
            println(io, "\\begin{figure}[tbp]")
            println(io, "  \\centering")
            println(io, "  \\includegraphics[width=\\linewidth]{journal/aor/figures/$(basename(figure))}")
            println(io, "  \\caption{", latex_escape(captions[basename(figure)]), "}")
            println(io, "  \\label{fig:aor-$(replace(stem, "_" => "-"))}")
            println(io, "\\end{figure}")
        end
    end
    return path
end

function write_manifest(paths)
    manifest_path = joinpath(TABLE_ROOT, "ANALYSIS_ARTIFACT_MANIFEST.csv")
    manifest_rows = Dict{String,Any}[]
    for path in sort!(unique(paths))
        isfile(path) || continue
        push!(manifest_rows, Dict{String,Any}(
            "path" => relpath(path, REPOSITORY_ROOT),
            "sha256" => sha256_file(path),
            "bytes" => filesize(path),
        ))
    end
    write_csv(manifest_path, ["path", "sha256", "bytes"], manifest_rows)
    return manifest_path
end

function write_report(data, exact_rows, heuristic_quality, scaling, preprocessing_summary,
    multistart_summary, timeout_records, model_diagnostics, exploratory_diagnostics,
    figure_paths, artifact_paths)
    exact_agreements = count(row -> row["exact_agreement"] === true, exact_rows)
    exact_unavailable = length(exact_rows) - exact_agreements
    identity_differences = count(row -> row["optimizer_identity_difference"] === true, exact_rows)
    status_counts = data.audit["status_counts"]
    structured_generated = count(id -> data.final_specs[id]["family"] == "structured" && data.metadata[id]["generation_status"] == "GENERATED", keys(data.final_specs))
    structured_total = count(id -> data.final_specs[id]["family"] == "structured", keys(data.final_specs))
    family_b_refs = count(id -> data.final_specs[id]["family"] == "structured" &&
        first(run for run in data.runs if run["instance_id"] == id)["reference_class"] == "MIP_OPTIMAL_EXACTLY_RECHECKED", keys(data.final_specs))
    multistart_complete = sum(parse(Int, string(row["complete_32_start_n"])) for row in multistart_summary)
    multistart_improved = sum(parse(Int, string(row["improved_n"])) for row in multistart_summary)
    registered_fit = count(row -> row["status"] == "FIT", model_diagnostics)
    registered_failed = length(model_diagnostics) - registered_fit
    report = IOBuffer()
    println(report, "# Audited algorithmic results: Registered Algorithmic Compression Benchmark v2\n")
    println(report, "## Technical summary\n")
    println(report, "This report analyzes only the committed, locked, independently audited v2 final records. The audit gate is **PASS**: all $(data.audit["terminal_run_count"]) registered run units are terminal, all $(data.audit["accepted_solution_count"]) accepted libraries passed independent exact frontier, identity-closure, mandatory-retention, tagged-coverage, and burden rechecks, and the artifact audit recorded zero errors. Runtime evidence is conditional on the registered eight-worker environment; it is not pooled with v1.\n")
    println(report, "Among $(length(exact_rows)) exact-capable instances, $exact_agreements had complete cross-method burden agreement, $exact_unavailable were unavailable after recorded failures, and $identity_differences agreed in burden while at least one returned optimizer identity differed. This is exact finite computation, not Lean verification. For Family B, $family_b_refs/$structured_total registered instances have an exactly feasible HiGHS-`OPTIMAL` reference; $structured_generated/$structured_total instances generated successfully.\n")
    println(report, "There were no `TIME_LIMIT` records, so timeout best-bound gaps are not numerically estimable; the empty machine table preserves that result. Multi-start completed all 32 registered starts on $multistart_complete rows and improved on start one on $multistart_improved of those rows.\n")

    println(report, "## Key findings with visual evidence\n")
    println(report, "- Exact methods agreed whenever the registered exact comparison was available; disagreement was never resolved by majority vote. Different optimizer identities at equal burden are retained as ties, not errors. See [exact-method agreement](../tables/exact_method_agreement.csv).\n")
    println(report, "- Failed generation is the dominant unsuccessful category: $(status_counts["GENERATION_FAILED"]) run units, arising from $(structured_total - structured_generated) structured registry instances. These rows remain in solved fractions, PAR-2, model populations, and failure tables.\n")
    println(report, "- The 14 memory-limit records all belong to the primary mandatory-only 32-start deletion workflow; they are not silently replaced by the successful full-preprocessing sensitivity. See [complete statuses](../tables/failure_statuses.csv) and [multi-start improvements](../tables/multistart_improvement.csv).\n")
    println(report, "- The performance, size-scaling, gap, preprocessing, and multi-start figures use the complete plotted populations and link back to [analysis_row_trace.csv](../tables/analysis_row_trace.csv). Aggregated figure rows include stable join keys; raw-point figure tables carry record paths and SHA-256 hashes.\n")

    println(report, "## Primary heuristic-quality summaries\n")
    println(report, "The following tables show every registered heuristic, not a selected subset. Attainment uses the full reference-available denominator; unsuccessful returned runs therefore count as nonattainment. Gap moments use exactly feasible returned solutions and state that smaller denominator explicitly.\n")
    for (family, reference_class, heading) in [
        ("small_exact", "EXACT_FINITE", "Family A: exact finite reference"),
        ("structured", "MIP_OPTIMAL_EXACTLY_RECHECKED", "Family B: HiGHS-optimal, exactly rechecked reference"),
    ]
        println(report, "### $heading\n")
        println(report, "| Algorithm | Attained/reference | Gap n | Mean relative gap | Median | q90 | Worst |")
        println(report, "|---|---:|---:|---:|---:|---:|---:|")
        for algorithm in HEURISTIC_ALGORITHMS
            matching = [row for row in heuristic_quality if row["family"] == family && row["reference_class"] == reference_class && row["algorithm_id"] == algorithm]
            isempty(matching) && continue
            row = only(matching)
            attainment_percent = 100 * Float64(row["attainment_fraction"])
            attainment = "$(row["attained_n"])/$(row["attainment_denominator"]) ($(format_summary_value(attainment_percent))%)"
            println(report, "| $(row["algorithm"]) | $attainment | $(row["gap_available_n"]) | $(row["relative_gap_mean"]) | $(row["relative_gap_median"]) | $(row["relative_gap_q90"]) | $(row["relative_gap_worst"]) |")
        end
        println(report)
    end
    println(report, "Absolute-gap means, medians, upper quantiles, and maxima are retained alongside these relative summaries in [heuristic_quality.csv](../tables/heuristic_quality.csv). The adversarial mechanisms are reported separately in [adversarial_family.csv](../tables/adversarial_family.csv), because pooling them with the random finite designs would obscure the registered constructions and evidence classes.\n")

    println(report, "## Runtime and resource summaries\n")
    println(report, "The complete per-family, per-size, per-algorithm [computational scaling table](../tables/computational_scaling.csv) reports solved fraction, solved-run wall-clock mean/median/q90/worst, PAR-2 mean/median/interquartile range/q90/worst, MIP nodes, DP states and transitions, and frontier/closure evaluation counts. The [certified deletion table](../tables/certified_deletion.csv) isolates exact semantic-check counts and final irreducibility certificates. [Preprocessing summaries](../tables/preprocessing_summary.csv) report variable and requirement reductions plus paired PAR-2 and node changes, while [multi-start summaries](../tables/multistart_summary.csv) report all registered improvement quantiles. [Timeout best-bound gaps](../tables/timeout_best_bound_gaps.csv) is deliberately header-only because no registered run ended at `TIME_LIMIT`.\n")

    println(report, "## Scope, data, and metric definitions\n")
    println(report, "The analysis population is the 173 `analysis_included=true` final registry instances and their 3,907 registered run units. Dry-run, pilot, v1, and untracked v1 output directories are excluded. Families are reported separately: 24 small exact, 128 structured finite-design, and 21 adversarial mechanism instances. Neither structured nor adversarial instances are a probability sample of real financial libraries.\n")
    println(report, "For a returned exact burden `W` and a registered reference `W*`, absolute gap is `W-W*` and relative gap is `(W-W*)/W*`. Family A uses enumeration/DP exact finite agreement (plus the registered conclusive MIP gate); Family B uses an exactly rechecked, HiGHS-`OPTIMAL` mandatory-only reference. These evidence classes are never pooled in one claimed exact distribution. Optimum/reference-attainment denominators include every registered algorithm row for which the reference exists; an unsuccessful algorithm run does not attain it. Gap distributions require an exactly feasible returned burden and print their unavailable counts.\n")
    println(report, "A run is solved only if it returned an exactly feasible candidate within both registered limits; exact methods additionally require complete search. PAR-2 equals observed supervisor wall time for solved rows and twice the registered limit otherwise. Unavailable nodes, states, frontier checks, and closure checks remain unavailable rather than zero. Quantile levels 0.10, 0.25, 0.50, 0.75, and 0.90 are registered. Because the plan did not name an interpolation convention, the generator uses deterministic Hyndman--Fan type 7 interpolation and records that completion explicitly.\n")

    println(report, "## Methodology\n")
    println(report, "The Julia 1.12.6 generator reads `results/final_algorithm_runs.csv`, the referenced raw TOML records, registry rows, generated instances, exactness certificates, and `audit_summary.toml`. It does not run a solver or algorithm. All burden arithmetic and gap construction originate in exact rational fields; floating point is used only for runtime, solver diagnostics, model fitting, and SVG coordinates.\n")
    println(report, "Primary finite-design summaries report row counts, eligible denominators, unavailable counts, means, medians, interquartile ranges, registered quantiles, minima, and maxima. Runtime comparisons use solved fraction, empirical performance profiles, PAR-2, and paired PAR-2 differences. The registered Family B relative-gap models use `log(1+gap)`, the nine declared structural main effects, replicate block, fixed lane, and only the declared algorithm-by-size interactions. Registered penalized-runtime models use `log(PAR-2)`; logistic models target solved/not solved. HC3 standard errors and Holm adjustment are implemented directly with `LinearAlgebra`.\n")
    println(report, "The registered model suite produced $registered_fit fits and $registered_failed declared failures or nonestimable specifications. A failed IRLS, separation, rank deficiency, or unavailable diagnostic is reported without changing links, penalties, or covariates. See [registered model diagnostics](../tables/registered_model_diagnostics.csv) and [coefficients](../tables/registered_model_coefficients.csv).\n")

    println(report, "## Requested publication artifacts\n")
    println(report, "Tables distinguish theorem/proof claims from exact computation and synthetic evidence:\n")
    println(report, "1. [Algorithm guarantees](../tables/algorithm_guarantees.tex) — human proofs or transferred approximation theorem; no benchmark result establishes a guarantee.")
    println(report, "2. [Exact-method agreement](../tables/exact_method_agreement.tex) — exact finite computation plus exact semantic audit; not Lean verification.")
    println(report, "3. [Computational scaling](../tables/computational_scaling.tex) — synthetic runtime/resource evidence under eight-worker contention.")
    println(report, "4. [Heuristic quality](../tables/heuristic_quality.tex) — exact or MIP-reference burden evidence, labeled per row.")
    println(report, "5. [Adversarial family](../tables/adversarial_family.tex) — synthetic exact-feasibility computation; analytic ratios appear only for the proved heaviest-safe-first family.\n")
    println(report, "Figures are publication SVGs with machine-readable sources: [performance profile](../figures/performance_profile.svg), [runtime versus size](../figures/runtime_vs_size.svg), [heuristic-gap heat map](../figures/heuristic_gap_heatmap.svg), [preprocessing reductions](../figures/preprocessing_reduction.svg), and [multi-start improvement](../figures/multistart_improvement.svg). Registered supplementary figures are [Family A gap distributions](../figures/family_a_exact_gap_distributions.svg), [Family B burden/runtime frontier](../figures/family_b_burden_runtime_frontier.svg), [solved-fraction grid](../figures/solved_fraction_grid.svg), [semantic evaluation counts](../figures/semantic_evaluation_counts.svg), and [adversarial mechanisms](../figures/adversarial_mechanisms.svg).\n")

    println(report, "## EXPLORATORY — reference-attainment regression\n")
    println(report, "The locked analysis plan does **not** prespecify a logistic regression for probability of exact optimum. It prespecifies an exact/reference-attainment frequency and a separate solved/not-solved logistic model. To avoid rewriting the registration after outcomes, the requested attainment regression is isolated here as `EXPLORATORY_NOT_PRESPECIFIED`; Family A targets exact finite attainment and Family B targets MIP-reference attainment. It must not be described as confirmatory. See [exploratory diagnostics](../tables/exploratory_reference_attainment_diagnostics.csv) and [coefficients](../tables/exploratory_reference_attainment_coefficients.csv).\n")

    println(report, "## Limitations, uncertainty, and robustness\n")
    println(report, "- Eight concurrent one-thread subprocesses define the runtime estimand. CPU, cache, and memory-bandwidth contention are part of v2; v1 timing is not pooled or compared numerically.")
    println(report, "- Six adversarial enumeration runs ended in implementation error, seven run units were process-interrupted, fourteen primary multi-start rows hit the memory limit, and two MIP candidates were unavailable/rejected under exact binary-value handling. All remain visible.")
    println(report, "- The $exact_unavailable exact-capable instances without complete agreement have no inferred exact optimum in exact-gap summaries.")
    println(report, "- HiGHS `OPTIMAL` plus an exact post-check is mixed-integer solver evidence, not a formal or exhaustive proof. No second solver was pinned.")
    println(report, "- No timeout occurred, so the registered timeout-bound analysis is an explicit zero-row result rather than evidence about bound quality under time limits.")
    println(report, "- Statistical intervals summarize the registered finite design. They do not license population, causal, forecasting, alpha, or deployable-performance claims.")
    println(report, "- The benchmark is identity-closure only and supplies no algorithmic guarantee for arbitrary nonidentity closure.\n")

    println(report, "## Validation report\n")
    println(report, "**Overall assessment: Ready to share with stated caveats.** The source audit passes, exact-agreement counts reconcile to the committed audit, every generated result is traceable, failed-run denominators are retained, and no negative reference gap was observed. Remaining caveats are the registered unsuccessful rows, eight-worker conditionality, absent second solver, and the explicitly exploratory attainment regression.\n")
    println(report, "Calculation spot-checks performed by the generator:\n")
    println(report, "- terminal matrix: $(length(data.runs)) = $(data.audit["terminal_run_count"]);")
    println(report, "- exact agreements: $exact_agreements = $(data.audit["exact_agreement_count"]);")
    println(report, "- exact unavailable: $exact_unavailable = $(data.audit["exact_agreement_unavailable_count"]);")
    println(report, "- optimizer-identity differences: $identity_differences = $(data.audit["optimizer_identity_difference_count"]);")
    println(report, "- time-limit rows: $(length(timeout_records));")
    println(report, "- generated artifacts listed in [ANALYSIS_ARTIFACT_MANIFEST.csv](../tables/ANALYSIS_ARTIFACT_MANIFEST.csv).\n")

    println(report, "## Recommended next step\n")
    println(report, "Integrate only the audited table/figure inputs selected by the locked manuscript architecture into Section 7, preserving the evidence-class captions and the failed-run caveats. Do not rerun or retune the benchmark.\n")
    println(report, "## Further questions\n")
    println(report, "The manuscript revision should decide which registered supplementary figures stay in the main article versus the online resource, without changing their data, denominators, axes, or evidence labels.")
    mkpath(dirname(REPORT_PATH))
    write(REPORT_PATH, String(take!(report)))
    return REPORT_PATH
end

function generate()
    mkpath(TABLE_ROOT)
    mkpath(FIGURE_ROOT)
    data = load_analysis_data()
    references, exact_rows = establish_references(data)
    enrich_runs!(data, references)
    count(row -> row["exact_agreement"] === true, exact_rows) == data.audit["exact_agreement_count"] || error("exact-agreement count does not reconcile to audit")
    count(row -> row["optimizer_identity_difference"] === true, exact_rows) == data.audit["optimizer_identity_difference_count"] || error("optimizer-identity count does not reconcile to audit")
    length(exact_rows) - count(row -> row["exact_agreement"] === true, exact_rows) == data.audit["exact_agreement_unavailable_count"] || error("exact-unavailable count does not reconcile to audit")

    guarantees = algorithm_guarantee_rows()
    trace = trace_rows(data)
    heuristic_quality = heuristic_quality_rows(data)
    scaling = computational_scaling_rows(data)
    preprocessing_detailed, preprocessing_summary, preprocessing_rules = preprocessing_rows(data)
    multistart_detailed, multistart_summary, multistart_starts = multistart_rows(data)
    timeouts = timeout_rows(data)
    failures = failure_rows(data)
    adversarial = adversarial_rows(data)
    structural = structural_diagnostic_rows(data)
    deletion = deletion_summary_rows(data)
    environment = environment_rows()
    model_coefficients, model_diagnostics = run_registered_models(data, preprocessing_detailed)
    registered_coefficients = [row for row in model_coefficients if !startswith(row["evidence_label"], "EXPLORATORY")]
    exploratory_coefficients = [row for row in model_coefficients if startswith(row["evidence_label"], "EXPLORATORY")]
    registered_diagnostics = [row for row in model_diagnostics if !startswith(row["evidence_label"], "EXPLORATORY")]
    exploratory_diagnostics = [row for row in model_diagnostics if startswith(row["evidence_label"], "EXPLORATORY")]
    paired = paired_comparison_rows(data)

    artifact_paths = String[]
    function table(stem, columns, rows; caption, label, tex_columns = columns, tex_rows = rows, tex_alignment = nothing)
        paths = write_table_pair(stem, columns, rows; caption, label, tex_columns, tex_rows, tex_alignment)
        append!(artifact_paths, paths)
    end

    table("algorithm_guarantees", ["algorithm", "algorithm_id", "guarantee", "evidence_class", "scope_and_limit", "source"], guarantees;
        caption = "Algorithm guarantees and claim boundaries. Guarantees originate in human proofs or transferred classical theorems, not benchmark timings.", label = "tab:aor-algorithm-guarantees",
        tex_columns = ["algorithm", "guarantee", "evidence_class", "scope_and_limit"],
        tex_alignment = raw"p{0.12\linewidth}p{0.22\linewidth}p{0.16\linewidth}p{0.22\linewidth}")
    table("exact_method_agreement", ["instance_id", "family", "size", "enumeration_status", "enumeration_burden", "dp_mandatory_status", "dp_mandatory_burden", "dp_full_status", "dp_full_burden", "mip_full_status", "mip_full_burden", "mip_mandatory_status", "mip_mandatory_burden", "exact_agreement", "optimizer_identity_difference", "reference_class"], exact_rows;
        caption = "Exact-method agreement on registered exact-capable instances. Agreement is exact finite computation and semantic audit, not Lean verification.", label = "tab:aor-exact-method-agreement",
        tex_columns = ["instance_id", "family", "size", "enumeration_burden", "dp_mandatory_burden", "mip_full_burden", "exact_agreement", "optimizer_identity_difference"],
        tex_alignment = raw"p{0.15\linewidth}p{0.09\linewidth}p{0.07\linewidth}p{0.10\linewidth}p{0.10\linewidth}p{0.10\linewidth}p{0.08\linewidth}p{0.08\linewidth}")
    scaling_columns = ["family", "size", "algorithm", "algorithm_id", "preprocessing_variant", "registered_n", "solved_n", "solved_fraction", "time_limit_seconds", "wall_solved_n", "wall_seconds_mean_solved", "wall_seconds_median_solved", "wall_seconds_q90_solved", "wall_seconds_worst_solved", "par2_mean_seconds", "par2_median_seconds", "par2_q25_seconds", "par2_q75_seconds", "par2_q90_seconds", "par2_worst_seconds", "peak_memory_available_n", "peak_memory_mean_mib", "peak_memory_median_mib", "peak_memory_q90_mib", "peak_memory_worst_mib", "mip_nodes_available_n", "mip_nodes_mean", "mip_nodes_median", "mip_nodes_q10", "mip_nodes_q25", "mip_nodes_q75", "mip_nodes_q90", "mip_nodes_minimum", "mip_nodes_worst", "dp_states_available_n", "dp_states_mean", "dp_states_median", "dp_states_q10", "dp_states_q25", "dp_states_q75", "dp_states_q90", "dp_states_minimum", "dp_states_worst", "dp_transitions_available_n", "dp_transitions_mean", "dp_transitions_median", "dp_transitions_q90", "dp_transitions_worst", "frontier_checks_available_n", "frontier_checks_mean", "frontier_checks_median", "frontier_checks_q10", "frontier_checks_q25", "frontier_checks_q75", "frontier_checks_q90", "frontier_checks_minimum", "frontier_checks_worst", "closure_checks_available_n", "closure_checks_mean", "closure_checks_median", "closure_checks_q10", "closure_checks_q25", "closure_checks_q75", "closure_checks_q90", "closure_checks_minimum", "closure_checks_worst"]
    table("computational_scaling", scaling_columns, scaling;
        caption = "Computational scaling under the fixed eight-worker v2 environment. PAR-2 retains every unsuccessful run; unavailable diagnostics are not zero.", label = "tab:aor-computational-scaling",
        tex_columns = ["family", "size", "algorithm", "registered_n", "solved_n", "par2_median_seconds", "par2_q90_seconds", "mip_nodes_median", "dp_states_median", "frontier_checks_median"],
        tex_alignment = raw"p{0.07\linewidth}p{0.06\linewidth}p{0.13\linewidth}p{0.055\linewidth}p{0.055\linewidth}p{0.075\linewidth}p{0.075\linewidth}p{0.085\linewidth}p{0.085\linewidth}p{0.085\linewidth}")
    quality_columns = ["family", "reference_class", "algorithm", "algorithm_id", "registered_n", "solved_n", "solved_fraction", "reference_available_n", "reference_unavailable_n", "attained_n", "attainment_denominator", "attainment_fraction", "gap_available_n", "gap_unavailable_n", "relative_gap_mean", "relative_gap_median", "relative_gap_q10", "relative_gap_q25", "relative_gap_q75", "relative_gap_q90", "relative_gap_minimum", "relative_gap_worst", "absolute_gap_mean", "absolute_gap_median", "absolute_gap_q10", "absolute_gap_q25", "absolute_gap_q75", "absolute_gap_q90", "absolute_gap_minimum", "absolute_gap_worst"]
    table("heuristic_quality", quality_columns, heuristic_quality;
        caption = "Heuristic burden quality. Exact and MIP-reference evidence classes are printed separately and are not pooled.", label = "tab:aor-heuristic-quality",
        tex_columns = ["family", "reference_class", "algorithm", "registered_n", "attained_n", "attainment_denominator", "relative_gap_median", "relative_gap_q90", "relative_gap_worst"],
        tex_alignment = raw"p{0.075\linewidth}p{0.13\linewidth}p{0.14\linewidth}p{0.055\linewidth}p{0.055\linewidth}p{0.065\linewidth}p{0.075\linewidth}p{0.075\linewidth}p{0.075\linewidth}")
    preprocessing_columns = ["instance_id", "family", "size", "full_status", "mandatory_status", "original_variables", "reduced_variables", "variables_removed", "variable_reduction_fraction", "original_requirements", "reduced_requirements", "requirements_removed", "requirement_reduction_fraction", "forced_selections", "fixed_point_iterations", "full_par2_seconds", "mandatory_par2_seconds", "log_par2_difference_full_minus_mandatory", "full_node_count", "mandatory_node_count", "node_difference_full_minus_mandatory", "log1p_node_difference_full_minus_mandatory", "full_record_path", "full_record_sha256", "mandatory_record_path", "mandatory_record_sha256"]
    table("preprocessing_reductions", preprocessing_columns, preprocessing_detailed;
        caption = "Paired exact-preprocessing diagnostics and MIP changes. Reduced solutions are reconstructed and exactly audited in original coordinates.", label = "tab:aor-preprocessing-reductions",
        tex_columns = ["instance_id", "family", "size", "variables_removed", "requirements_removed", "forced_selections", "log_par2_difference_full_minus_mandatory", "node_difference_full_minus_mandatory"])
    preprocessing_summary_columns = ["family", "size", "registered_n", "preprocessing_available_n", "variable_reduction_mean", "variable_reduction_median", "variable_reduction_q10", "variable_reduction_q25", "variable_reduction_q75", "variable_reduction_q90", "variable_reduction_minimum", "variable_reduction_worst", "requirement_reduction_mean", "requirement_reduction_median", "requirement_reduction_q10", "requirement_reduction_q25", "requirement_reduction_q75", "requirement_reduction_q90", "requirement_reduction_minimum", "requirement_reduction_worst", "paired_par2_available_n", "mean_log_par2_difference", "median_log_par2_difference", "q90_log_par2_difference", "worst_log_par2_difference", "paired_nodes_available_n", "mean_log1p_node_difference", "median_log1p_node_difference", "q90_log1p_node_difference", "worst_log1p_node_difference"]
    table("preprocessing_summary", preprocessing_summary_columns, preprocessing_summary;
        caption = "Finite-design preprocessing summaries; unavailable node counts remain unavailable.", label = "tab:aor-preprocessing-summary")
    table("preprocessing_rule_counts", ["instance_id", "family", "size", "rule", "applications", "variables_removed", "requirements_removed", "record_path", "record_sha256"], preprocessing_rules;
        caption = "Per-rule preprocessing audit counts from exact fixed-point records.", label = "tab:aor-preprocessing-rules",
        tex_columns = ["family", "size", "rule", "applications", "variables_removed", "requirements_removed"])
    deletion_columns = ["family", "size", "algorithm", "algorithm_id", "registered_n", "solved_n", "irreducible_certified_n", "frontier_checks_available_n", "frontier_checks_median", "closure_checks_available_n", "closure_checks_median", "complete_scans_median", "relative_gap_available_n", "relative_gap_median", "relative_gap_worst"]
    table("certified_deletion", deletion_columns, deletion;
        caption = "Certified deletion outcomes. Feasibility and irreducibility are exact finite certificates; burden quality remains experimental.", label = "tab:aor-certified-deletion")
    table("multistart_improvement", ["instance_id", "family", "size", "status", "first_start_burden", "selected_best_burden", "absolute_improvement", "relative_improvement", "start_count_available", "record_path", "record_sha256"], multistart_detailed;
        caption = "Registered 32-start deletion improvement relative to start one; unavailable endpoints are not set to zero.", label = "tab:aor-multistart-improvement",
        tex_columns = ["instance_id", "family", "size", "status", "first_start_burden", "selected_best_burden", "relative_improvement"])
    multistart_summary_columns = ["family", "size", "registered_n", "complete_32_start_n", "unavailable_n", "improved_n", "improvement_denominator", "relative_improvement_mean", "relative_improvement_median", "relative_improvement_q10", "relative_improvement_q25", "relative_improvement_q75", "relative_improvement_q90", "relative_improvement_minimum", "relative_improvement_worst"]
    table("multistart_summary", multistart_summary_columns, multistart_summary;
        caption = "Multi-start improvement summaries by registered family and size.", label = "tab:aor-multistart-summary")
    table("multistart_start_endpoints", ["instance_id", "family", "size", "start_index", "exact_burden", "relative_to_first", "selected_best", "record_path", "record_sha256"], multistart_starts;
        caption = "All registered random-deletion start endpoints retained in the saved trace.", label = "tab:aor-multistart-starts",
        tex_columns = ["instance_id", "start_index", "exact_burden", "relative_to_first", "selected_best"])
    table("timeout_best_bound_gaps", ["instance_id", "family", "size", "algorithm_id", "preprocessing_variant", "exact_incumbent_burden", "best_bound", "bound_relative_gap", "solver_reported_gap", "record_path", "record_sha256"], timeouts;
        caption = "Timeout best-bound diagnostics. The v2 final matrix contains no TIME LIMIT record, so this table has zero data rows.", label = "tab:aor-timeout-bounds")
    table("failure_statuses", ["family", "algorithm", "algorithm_id", "preprocessing_variant", "status", "count", "successful_status", "example_record_path", "example_record_sha256"], failures;
        caption = "Complete terminal status counts; no failed or unsuccessful run is dropped.", label = "tab:aor-failure-statuses",
        tex_columns = ["family", "algorithm", "preprocessing_variant", "status", "count"])
    adversarial_columns = ["instance_id", "mechanism", "scale", "mechanism_parameter", "algorithm", "algorithm_id", "status", "reference_class", "reference_burden", "observed_burden", "observed_burden_ratio", "theoretical_ratio_if_applicable", "evidence_class", "record_path", "record_sha256"]
    table("adversarial_family", adversarial_columns, adversarial;
        caption = "Adversarial-family outcomes. The theoretical ratio is printed only for the proved heaviest-safe-first family; other ratios are synthetic computation.", label = "tab:aor-adversarial-family",
        tex_columns = ["mechanism", "scale", "algorithm", "reference_class", "observed_burden_ratio", "theoretical_ratio_if_applicable"],
        tex_alignment = raw"p{0.18\linewidth}p{0.07\linewidth}p{0.17\linewidth}p{0.16\linewidth}p{0.10\linewidth}p{0.12\linewidth}")
    structural_columns = ["instance_id", "family", "size", "replicate_id", "generation_status", "strategy_count_requested", "requirement_count_requested", "frontier_rows_requested", "module_rows_requested", "coverage_density_level", "coverage_density_realized", "module_overlap_level", "module_overlap_realized", "bundle_prevalence_level", "bundle_prevalence_realized", "unique_carrier_frequency_level", "unique_carrier_frequency_realized", "weight_dispersion_level", "frontier_module_correlation_level", "frontier_module_association_realized", "mechanism", "mechanism_parameter", "generation_path", "instance_path", "instance_sha256"]
    table("registered_design_realized", structural_columns, structural;
        caption = "Registered design and realized structural diagnostics. Generation failures retain requested fields and unavailable realized fields.", label = "tab:aor-design-realized",
        tex_columns = ["instance_id", "family", "size", "generation_status", "coverage_density_level", "coverage_density_realized", "module_overlap_level", "bundle_prevalence_level", "unique_carrier_frequency_level"])
    table("environment", ["field", "value", "source_path", "source_sha256"], environment;
        caption = "Registered v2 execution environment and provenance.", label = "tab:aor-environment",
        tex_columns = ["field", "value"])
    table("analysis_row_trace", ["instance_id", "family", "size", "algorithm_id", "preprocessing_variant", "primary_variant", "status", "candidate_accepted", "exact_feasible", "exact_burden", "reference_class", "reference_burden", "absolute_gap", "relative_gap", "wall_clock_seconds", "par2_seconds", "time_limit_seconds", "worker_lane", "launch_wave", "record_path", "record_sha256"], trace;
        caption = "Complete analysis row trace to committed raw records.", label = "tab:aor-analysis-trace",
        tex_columns = ["instance_id", "algorithm_id", "preprocessing_variant", "status", "exact_burden", "reference_class", "record_sha256"])
    model_columns = ["model_id", "model_family", "evidence_label", "term", "estimate", "standard_error", "ci_lower_95", "ci_upper_95", "p_value", "holm_p_value", "population_n", "fitted_n"]
    diagnostic_columns = ["model_id", "model_family", "evidence_label", "status", "population_n", "fitted_n", "unavailable_n", "parameter_count", "rank", "r_squared", "iterations"]
    table("registered_model_coefficients", model_columns, registered_coefficients;
        caption = "Registered finite-design model coefficients with declared HC3 or logistic uncertainty and Holm adjustment.", label = "tab:aor-registered-model-coefficients",
        tex_columns = ["model_id", "term", "estimate", "standard_error", "ci_lower_95", "ci_upper_95", "holm_p_value"])
    table("registered_model_diagnostics", diagnostic_columns, registered_diagnostics;
        caption = "Registered model fit diagnostics. Failed specifications are reported without post hoc replacement.", label = "tab:aor-registered-model-diagnostics",
        tex_columns = ["model_id", "status", "population_n", "fitted_n", "unavailable_n", "parameter_count", "rank"])
    table("exploratory_reference_attainment_coefficients", model_columns, exploratory_coefficients;
        caption = "EXPLORATORY reference-attainment logistic coefficients; this regression was not prespecified.", label = "tab:aor-exploratory-attainment-coefficients",
        tex_columns = ["model_id", "term", "estimate", "standard_error", "ci_lower_95", "ci_upper_95", "holm_p_value"])
    table("exploratory_reference_attainment_diagnostics", diagnostic_columns, exploratory_diagnostics;
        caption = "EXPLORATORY reference-attainment model diagnostics; not confirmatory.", label = "tab:aor-exploratory-attainment-diagnostics",
        tex_columns = ["model_id", "status", "population_n", "fitted_n", "parameter_count", "rank"])
    paired_columns = ["comparison_class", "family", "left", "right", "paired_n", "left_wins", "ties", "left_losses", "median_left_minus_right", "sign_interval_lower_95", "sign_interval_upper_95", "two_sided_sign_test_p"]
    table("paired_comparisons", paired_columns, paired;
        caption = "Registered paired PAR-2 comparisons with exact two-sided sign-test diagnostics.", label = "tab:aor-paired-comparisons")

    profile_data, profile_path = plot_performance_profile(data)
    runtime_data, runtime_path = plot_runtime_vs_size(data)
    heatmap_data, heatmap_path = plot_gap_heatmap(data)
    preprocessing_plot_data, preprocessing_path = plot_preprocessing(preprocessing_detailed)
    multistart_plot_data, multistart_path = plot_multistart(multistart_detailed)
    family_a_plot_data, family_a_path = plot_family_a_gap_distributions(data)
    burden_runtime_data, burden_runtime_path = plot_burden_runtime_frontier(data)
    solved_data, solved_path = plot_solved_fraction_grid(data)
    semantic_data, semantic_path = plot_semantic_evaluations(data)
    adversarial_plot_data, adversarial_path = plot_adversarial(adversarial)
    figure_paths = [profile_path, runtime_path, heatmap_path, preprocessing_path, multistart_path, family_a_path, burden_runtime_path, solved_path, semantic_path, adversarial_path]
    append!(artifact_paths, figure_paths)

    figure_tables = [
        ("figure_performance_profile_data", ["family", "size", "instance_id", "algorithm_id", "algorithm", "performance_ratio", "solved", "any_method_solved_instance", "record_path", "record_sha256"], profile_data),
        ("figure_runtime_vs_size_data", ["family", "requirement_count", "strategy_count", "algorithm_id", "algorithm", "registered_n", "median_par2_seconds", "q25_par2_seconds", "q75_par2_seconds", "trace_join_key"], runtime_data),
        ("figure_heuristic_gap_heatmap_data", ["family", "size", "algorithm_id", "algorithm", "registered_n", "gap_available_n", "median_relative_gap", "worst_relative_gap", "trace_join_key"], heatmap_data),
        ("figure_preprocessing_reduction_data", ["instance_id", "family", "size", "full_status", "mandatory_status", "variable_reduction_fraction", "requirement_reduction_fraction", "log_par2_difference_full_minus_mandatory", "log1p_node_difference_full_minus_mandatory", "full_record_path", "full_record_sha256", "mandatory_record_path", "mandatory_record_sha256"], preprocessing_plot_data),
        ("figure_multistart_improvement_data", ["instance_id", "family", "size", "status", "relative_improvement_numeric", "record_path", "record_sha256"], multistart_plot_data),
        ("figure_family_a_gap_data", ["instance_id", "algorithm_id", "relative_gap", "record_path", "record_sha256"], family_a_plot_data),
        ("figure_family_b_burden_runtime_data", ["instance_id", "algorithm_id", "relative_gap", "par2_seconds", "solved", "record_path", "record_sha256"], burden_runtime_data),
        ("figure_solved_fraction_data", ["family", "size", "algorithm_id", "algorithm", "solved_n", "registered_n", "solved_fraction", "trace_join_key"], solved_data),
        ("figure_semantic_evaluation_data", ["family", "algorithm_id", "algorithm", "available_n", "median_total_checks", "q25_total_checks", "q75_total_checks", "trace_join_key"], semantic_data),
        ("figure_adversarial_mechanism_data", adversarial_columns, adversarial_plot_data),
    ]
    for (stem, columns, rows) in figure_tables
        path = write_csv(joinpath(TABLE_ROOT, "$stem.csv"), columns, rows)
        push!(artifact_paths, path)
    end
    chart_map = [
        Dict("figure" => basename(profile_path), "question" => "How robustly do methods solve registered instances relative to the best observed solved time?", "family" => "performance profile", "data" => "journal/aor/tables/figure_performance_profile_data.csv", "palette_policy" => "five approved roots plus dash/marker cycles", "qa_surface" => "SVG and rendered PNG"),
        Dict("figure" => basename(runtime_path), "question" => "How does median PAR-2 change across registered strategy counts?", "family" => "faceted line-dot", "data" => "journal/aor/tables/figure_runtime_vs_size_data.csv", "palette_policy" => "five approved roots plus dash/marker cycles", "qa_surface" => "SVG and rendered PNG"),
        Dict("figure" => basename(heatmap_path), "question" => "Where do heuristic burden gaps concentrate by algorithm and size?", "family" => "heatmap with direct values", "data" => "journal/aor/tables/figure_heuristic_gap_heatmap_data.csv", "palette_policy" => "single blue root", "qa_surface" => "SVG and rendered PNG"),
        Dict("figure" => basename(preprocessing_path), "question" => "How do exact reductions relate to paired PAR-2 and node changes?", "family" => "three-panel scatter", "data" => "journal/aor/tables/figure_preprocessing_reduction_data.csv", "palette_policy" => "blue/orange plus shapes", "qa_surface" => "SVG and rendered PNG"),
        Dict("figure" => basename(multistart_path), "question" => "How often and how much does 32-start deletion improve over start one?", "family" => "strip plot with medians", "data" => "journal/aor/tables/figure_multistart_improvement_data.csv", "palette_policy" => "approved roots plus open markers", "qa_surface" => "SVG and rendered PNG"),
        Dict("figure" => basename(family_a_path), "question" => "What is the full Family A exact-gap distribution by heuristic?", "family" => "strip and interval", "data" => "journal/aor/tables/figure_family_a_gap_data.csv", "palette_policy" => "approved roots plus open markers", "qa_surface" => "SVG and rendered PNG"),
        Dict("figure" => basename(burden_runtime_path), "question" => "How do Family B MIP-reference gaps relate to PAR-2?", "family" => "scatter", "data" => "journal/aor/tables/figure_family_b_burden_runtime_data.csv", "palette_policy" => "approved roots plus marker shapes", "qa_surface" => "SVG and rendered PNG"),
        Dict("figure" => basename(solved_path), "question" => "Which registered method-size cells return exactly feasible candidates?", "family" => "heatmap with direct fractions", "data" => "journal/aor/tables/figure_solved_fraction_data.csv", "palette_policy" => "single blue root", "qa_surface" => "SVG and rendered PNG"),
        Dict("figure" => basename(semantic_path), "question" => "How many exact semantic checks do certified deletion variants use?", "family" => "dot and interval", "data" => "journal/aor/tables/figure_semantic_evaluation_data.csv", "palette_policy" => "three approved roots plus shapes", "qa_surface" => "SVG and rendered PNG"),
        Dict("figure" => basename(adversarial_path), "question" => "How do registered adversarial mechanisms separate heuristic burden ratios?", "family" => "faceted line-dot", "data" => "journal/aor/tables/figure_adversarial_mechanism_data.csv", "palette_policy" => "approved roots plus dash/marker cycles", "qa_surface" => "SVG and rendered PNG"),
    ]
    chart_map_path = write_csv(joinpath(FIGURE_ROOT, "CHART_MAP.csv"), ["figure", "question", "family", "data", "palette_policy", "qa_surface"], chart_map)
    push!(artifact_paths, chart_map_path)
    figure_include_path = write_figure_includes(figure_paths)
    push!(artifact_paths, figure_include_path)

    report_path = write_report(data, exact_rows, heuristic_quality, scaling, preprocessing_summary,
        multistart_summary, timeouts, registered_diagnostics, exploratory_diagnostics,
        figure_paths, artifact_paths)
    push!(artifact_paths, report_path)
    manifest_path = write_manifest(artifact_paths)
    push!(artifact_paths, manifest_path)

    println("Generated $(length(artifact_paths)) audited analysis artifacts")
    println("Report: $(relpath(report_path, REPOSITORY_ROOT))")
    println("Exact agreements: $(data.audit["exact_agreement_count"])/$(data.audit["exact_instance_count"])")
    println("Timeout records: $(length(timeouts))")
    return (; data, exact_rows, guarantees, trace, heuristic_quality, scaling,
        preprocessing_detailed, preprocessing_summary, multistart_detailed,
        multistart_summary, timeouts, model_coefficients, model_diagnostics,
        paired, adversarial, artifact_paths)
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    using .AlgorithmicCompressionAnalysisV2
    AlgorithmicCompressionAnalysisV2.generate()
end
