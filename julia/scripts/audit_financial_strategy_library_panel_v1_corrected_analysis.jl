module AuditFinancialStrategyLibraryPanelV1CorrectedAnalysis

using SHA: sha256
using TOML

include(joinpath(@__DIR__, "analyze_financial_strategy_library_panel_v1_corrected.jl"))
using .AnalyzeFinancialStrategyLibraryPanelV1Corrected
using .AnalyzeFinancialStrategyLibraryPanelV1Corrected.FinancialPanelParquet

export audit_public_results, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v1",
)
const RESULTS_ROOT = joinpath(EXPERIMENT_ROOT, "results")
const JOURNAL_REPORT = joinpath(
    REPOSITORY_ROOT,
    "journal",
    "aor",
    "reports",
    "FINANCIAL_PANEL_RESULTS.md",
)
const PROHIBITED_PATTERNS = (
    "permno",
    "ticker",
    "security_name",
    "daily_return",
    "dlyret",
    "dlyclose",
    "dlyprc",
    "dlyvol",
    "selected_active_ids",
    "belief_losses_exact",
)

_sha256_text(value) = bytes2hex(sha256(codeunits(value)))

function _atomic_toml(path, payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    temporary = path * ".tmp.$(getpid())"
    open(temporary, "w") do output
        write(output, String(take!(io)))
    end
    mv(temporary, path; force = true)
    return path
end

function _median(values)
    isempty(values) && return missing
    ordered = sort!(Float64.(values))
    n = length(ordered)
    return isodd(n) ? ordered[(n + 1) ÷ 2] :
           (ordered[n ÷ 2] + ordered[n ÷ 2 + 1]) / 2
end

function _nearest_quantile(values, probability)
    isempty(values) && return missing
    ordered = sort!(Float64.(values))
    return ordered[clamp(ceil(Int, probability * length(ordered)), 1, length(ordered))]
end

_mean(values) = isempty(values) ? missing : sum(values) / length(values)
_maximum(values) = isempty(values) ? missing : maximum(values)

function _same_number(actual, expected)
    ismissing(actual) || ismissing(expected) || return isapprox(
        Float64(actual),
        Float64(expected);
        rtol = 1e-12,
        atol = 1e-12,
    )
    return ismissing(actual) && ismissing(expected)
end

function _audit_no_prohibited_columns(columns, label, errors)
    names = lowercase.(String.(propertynames(columns)))
    for pattern in PROHIBITED_PATTERNS
        any(name -> occursin(pattern, name), names) && push!(
            errors,
            "$label contains prohibited public field pattern: $pattern",
        )
    end
end

function _audit_corrected_runtime(summary, algorithms, errors)
    for index in eachindex(summary.library_id)
        group = [row for row in eachindex(algorithms.origin_id) if
                 algorithms.library_id[row] == summary.library_id[index] &&
                 algorithms.schedule_id[row] == summary.schedule_id[index] &&
                 algorithms.algorithm_id[row] == summary.algorithm_id[index]]
        length(group) == summary.registered_instance_count[index] || push!(
            errors,
            "runtime summary group does not retain its registered denominator at row $index",
        )
        runtime = Float64[
            algorithms.wall_clock_seconds[row] for row in group if
            algorithms.applicable[row] && !ismissing(algorithms.wall_clock_seconds[row])
        ]
        expected = (
            count = length(runtime),
            mean = isempty(runtime) ? missing : sum(runtime) / length(runtime),
            median = _median(runtime),
            q25 = _nearest_quantile(runtime, 0.25),
            q75 = _nearest_quantile(runtime, 0.75),
            p90 = _nearest_quantile(runtime, 0.90),
            maximum = _maximum(runtime),
        )
        summary.runtime_count[index] == expected.count || push!(
            errors,
            "runtime count includes an inapplicable row at summary row $index",
        )
        for (name, actual, target) in (
            ("mean", summary.runtime_mean_seconds[index], expected.mean),
            ("median", summary.runtime_median_seconds[index], expected.median),
            ("q25", summary.runtime_q25_seconds[index], expected.q25),
            ("q75", summary.runtime_q75_seconds[index], expected.q75),
            ("p90", summary.runtime_p90_seconds[index], expected.p90),
            ("maximum", summary.runtime_max_seconds[index], expected.maximum),
        )
            _same_number(actual, target) || push!(
                errors,
                "runtime $name differs from applicable executions at summary row $index",
            )
        end
    end
end

function _progress(completed, total)
    width = 32
    filled = total == 0 ? width : fld(completed * width, total)
    println(stderr, "public-results-audit [", repeat("█", filled),
            repeat("░", width - filled), "] $completed/$total")
    flush(stderr)
end

function audit_public_results(; write_report = true)
    manifest_path = joinpath(RESULTS_ROOT, "PUBLIC_RESULTS_MANIFEST.toml")
    isfile(manifest_path) || error("public-results manifest is absent")
    manifest = TOML.parsefile(manifest_path)
    errors = String[]
    manifest["schema_version"] == "financial-strategy-library-panel-public-results-v1" ||
        push!(errors, "unexpected public-results schema")
    manifest["analysis_correction_id"] == "ANALYSIS_CORRECTION_001" ||
        push!(errors, "unexpected analysis correction")
    manifest["source_execution_lock_aggregate_sha256"] ==
    AnalyzeFinancialStrategyLibraryPanelV1Corrected.EXECUTION_LOCK_AGGREGATE ||
        push!(errors, "public results use a different execution lock")
    manifest["runtime_summary_excludes_inapplicable_rows"] === true ||
        push!(errors, "runtime correction is not declared")
    manifest["unsuccessful_rows_retained_in_denominators"] === true ||
        push!(errors, "unsuccessful denominators are not declared")
    manifest["raw_licensed_rows_included"] === false || push!(errors, "raw rows are declared")
    manifest["selected_strategy_identifiers_included"] === false ||
        push!(errors, "selected strategy identifiers are declared")

    files = Dict(String(path) => String(hash) for (path, hash) in manifest["files"])
    relatives = sort!(collect(keys(files)))
    _progress(0, length(relatives))
    hashes = Vector{String}(undef, length(relatives))
    completed = Threads.Atomic{Int}(0)
    progress_lock = ReentrantLock()
    Threads.@threads :static for index in eachindex(relatives)
        path = joinpath(RESULTS_ROOT, relatives[index])
        hashes[index] = isfile(path) ? sha256_file(path) : "MISSING"
        lock(progress_lock) do
            count = Threads.atomic_add!(completed, 1) + 1
            _progress(count, length(relatives))
        end
    end
    for (index, relative) in enumerate(relatives)
        hashes[index] == files[relative] || push!(errors, "public artifact differs: $relative")
    end
    aggregate = _sha256_text(join(
        ("$path\0$(files[path])\n" for path in relatives)
    ))
    aggregate == manifest["artifact_aggregate_sha256"] ||
        push!(errors, "public artifact aggregate differs")

    algorithms = parquet_columns(joinpath(RESULTS_ROOT, "algorithm_rows_public.parquet"))
    instances = parquet_columns(joinpath(RESULTS_ROOT, "instance_rows.parquet"))
    summary = parquet_columns(joinpath(RESULTS_ROOT, "structural_summary.parquet"))
    agreement = parquet_columns(joinpath(RESULTS_ROOT, "exact_method_agreement.parquet"))
    overlaps = parquet_columns(joinpath(RESULTS_ROOT, "identity_overlap.parquet"))
    carriers = parquet_columns(joinpath(RESULTS_ROOT, "carrier_multiplicity.parquet"))
    propertynames(algorithms) == AnalyzeFinancialStrategyLibraryPanelV1Corrected.PUBLIC_ALGORITHM_COLUMNS ||
        push!(errors, "public algorithm schema differs from its exact whitelist")
    for (label, columns) in (
        ("algorithm", algorithms),
        ("instance", instances),
        ("summary", summary),
        ("agreement", agreement),
        ("overlap", overlaps),
        ("carrier", carriers),
    )
        _audit_no_prohibited_columns(columns, label, errors)
    end
    parquet_row_count(algorithms) == 1260 || push!(errors, "algorithm row count differs")
    parquet_row_count(instances) == 180 || push!(errors, "instance row count differs")
    parquet_row_count(summary) == 63 || push!(errors, "summary row count differs")
    parquet_row_count(agreement) == 180 || push!(errors, "agreement row count differs")
    parquet_row_count(overlaps) == 5040 || push!(errors, "overlap row count differs")
    parquet_row_count(carriers) == 3456 || push!(errors, "carrier row count differs")
    all(==(20), summary.registered_instance_count) ||
        push!(errors, "a summary denominator drops a registered origin")
    all(index -> !algorithms.candidate_returned[index] ||
                 algorithms.exact_feasible[index] === true,
        eachindex(algorithms.origin_id)) ||
        push!(errors, "a public candidate lacks an exact feasibility certificate")
    all(!, agreement.mip_solver_status_used_as_exact_proof) ||
        push!(errors, "a solver status is represented as exact proof")
    any(value -> value === false, agreement.dp_enumeration_objective_agreement) &&
        push!(errors, "DP and enumeration disagree")
    _audit_corrected_runtime(summary, algorithms, errors)
    all(>(0), carriers.carrier_count) || push!(errors, "carrierless requirement found")
    all(index -> overlaps.available[index] ?
                 0.0 <= overlaps.jaccard[index] <= 1.0 :
                 ismissing(overlaps.jaccard[index]),
        eachindex(overlaps.origin_id)) || push!(errors, "invalid overlap value")

    report_path = joinpath(RESULTS_ROOT, "RESULTS_REPORT.md")
    isfile(JOURNAL_REPORT) || push!(errors, "journal results report is absent")
    isfile(JOURNAL_REPORT) && sha256_file(JOURNAL_REPORT) != sha256_file(report_path) &&
        push!(errors, "journal and experiment result reports differ")
    for name in (
        "origin_compression.svg",
        "completion_cactus.svg",
        "carrier_multiplicity_compression.svg",
        "schedule_identity_overlap.svg",
        "postdecision_diagnostics.svg",
    )
        text = read(joinpath(RESULTS_ROOT, "figures", name), String)
        occursin("<title", text) && occursin("<desc", text) ||
            push!(errors, "figure lacks accessible title/description: $name")
    end

    report = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-public-results-audit-v1",
        "experiment_id" => "financial-strategy-library-panel-v1",
        "analysis_correction_id" => "ANALYSIS_CORRECTION_001",
        "passed" => isempty(errors),
        "integrity_errors" => errors,
        "source_execution_lock_aggregate_sha256" =>
            manifest["source_execution_lock_aggregate_sha256"],
        "source_result_audit_sha256" => manifest["source_result_audit_sha256"],
        "source_analysis_manifest_sha256" => manifest["source_analysis_manifest_sha256"],
        "public_results_manifest_sha256" => sha256_file(manifest_path),
        "public_artifact_aggregate_sha256" => aggregate,
        "registered_algorithm_row_count" => parquet_row_count(algorithms),
        "registered_instance_row_count" => parquet_row_count(instances),
        "runtime_summary_excludes_inapplicable_rows" => true,
        "unsuccessful_rows_retained_in_denominators" => true,
        "raw_licensed_rows_included" => false,
        "selected_strategy_identifiers_included" => false,
    )
    write_report && _atomic_toml(joinpath(RESULTS_ROOT, "PUBLIC_RESULTS_AUDIT.toml"), report)
    isempty(errors) || error("public-results audit failed: $(join(errors, "; "))")
    return report
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: audit_financial_strategy_library_panel_v1_corrected_analysis.jl --check",
    )
    only(args) == "--check" || error("unknown mode: $(only(args))")
    result = audit_public_results()
    println("corrected financial panel public-results audit passed: ",
            result["public_artifact_aggregate_sha256"])
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    AuditFinancialStrategyLibraryPanelV1CorrectedAnalysis.main()
end
