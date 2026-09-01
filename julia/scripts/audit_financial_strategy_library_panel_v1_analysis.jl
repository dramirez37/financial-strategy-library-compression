module AuditFinancialStrategyLibraryPanelV1Analysis

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV1.jl"))
using .FinancialStrategyLibraryPanelV1
using .FinancialStrategyLibraryPanelV1.FinancialPanelParquet

export audit_analysis, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const ANALYSIS_THREAD_COUNT = 8
const ALGORITHM_IDS = collect(FinancialStrategyLibraryPanelV1.ALGORITHM_IDS)
const PROHIBITED_COLUMN_PATTERNS = (
    "permno",
    "ticker",
    "security_name",
    "daily_return",
    "dlyret",
    "dlyclose",
    "dlyprc",
    "dlyvol",
)

_utc_now() = Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")
_sha256_text(value) = bytes2hex(sha256(codeunits(value)))

function _paths(config)
    local_results = joinpath(REPOSITORY_ROOT, String(config["paths"]["local_results_root"]))
    analysis = joinpath(local_results, "analysis")
    return (
        local_results,
        result_audit = joinpath(local_results, "RESULT_AUDIT.toml"),
        analysis,
        manifest = joinpath(analysis, "ANALYSIS_MANIFEST.toml"),
        audit = joinpath(analysis, "ANALYSIS_AUDIT.toml"),
        algorithm_rows = joinpath(analysis, "algorithm_rows.parquet"),
        instance_rows = joinpath(analysis, "instance_rows.parquet"),
        summary = joinpath(analysis, "structural_summary.parquet"),
        overlap = joinpath(analysis, "identity_overlap.parquet"),
        exact_agreement = joinpath(analysis, "exact_method_agreement.parquet"),
        carrier_multiplicity = joinpath(analysis, "carrier_multiplicity.parquet"),
        catalog = joinpath(analysis, "ANALYSIS_CATALOG.toml"),
        figures = joinpath(analysis, "figures"),
    )
end


function _audit_catalog(paths, manifest, errors)
    isfile(paths.catalog) || begin
        push!(errors, "analysis catalog is absent")
        return (0, 0)
    end
    catalog = TOML.parsefile(paths.catalog)
    catalog["schema_version"] == "financial-panel-analysis-catalog-v1" ||
        push!(errors, "unexpected analysis catalog schema")
    tables = get(catalog, "tables", Any[])
    figures = get(catalog, "figures", Any[])
    length(tables) == 7 || push!(errors, "analysis catalog does not map seven tables")
    length(figures) == 5 || push!(errors, "analysis catalog does not map five figures")
    for row in figures
        figure = joinpath(paths.analysis, String(row["file"]))
        isfile(figure) || begin
            push!(errors, "registered analysis figure is absent: $(row["file"])")
            continue
        end
        text = read(figure, String)
        occursin("<title", text) && occursin("<desc", text) ||
            push!(errors, "analysis figure lacks accessible title/description: $(row["file"])")
    end
    Int(manifest["registered_table_count"]) == length(tables) ||
        push!(errors, "registered table count differs from the manifest")
    Int(manifest["registered_figure_count"]) == length(figures) ||
        push!(errors, "registered figure count differs from the manifest")
    return length(tables), length(figures)
end

function _atomic_toml(path, payload)
    temporary = path * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, toml_text(payload))
    end
    try
        mv(temporary, path; force = true)
    finally
        isfile(temporary) && rm(temporary; force = true)
    end
    return path
end

function _audit_progress(io, completed, total)
    width = 36
    filled = total == 0 ? width : fld(completed * width, total)
    bar = repeat("█", filled) * repeat("░", width - filled)
    println(io, "[$(_utc_now())] analysis-audit [$bar] $completed/$total")
    flush(io)
end

function _parallel_hashes(paths; progress_io = stderr)
    hashes = Vector{String}(undef, length(paths))
    completed = Threads.Atomic{Int}(0)
    progress_lock = ReentrantLock()
    worker_ids = Vector{Int}(undef, length(paths))
    _audit_progress(progress_io, 0, length(paths))
    Threads.@threads :static for index in eachindex(paths)
        hashes[index] = sha256_file(paths[index])
        worker_ids[index] = Threads.threadid()
        lock(progress_lock) do
            count = Threads.atomic_add!(completed, 1) + 1
            _audit_progress(progress_io, count, length(paths))
        end
    end
    return hashes, worker_ids
end

function _algorithm_key(columns, index)
    return (
        String(columns.origin_id[index]),
        String(columns.library_id[index]),
        String(columns.schedule_id[index]),
        String(columns.algorithm_id[index]),
    )
end

function _audit_no_raw_columns(columns, label, errors)
    names = String.(propertynames(columns))
    for pattern in PROHIBITED_COLUMN_PATTERNS
        any(name -> occursin(pattern, lowercase(name)), names) &&
            push!(errors, "$label schema contains prohibited raw-row field: $pattern")
    end
end

function _audit_algorithm_rows(path, errors)
    columns = parquet_columns(path)
    parquet_row_count(columns) == 1260 ||
        push!(errors, "analysis algorithm table does not contain 1260 rows")
    _audit_no_raw_columns(columns, "analysis algorithm", errors)
    expected = Set(
        (origin_id, library_id, schedule_id, algorithm_id) for
        (origin_id, library_id, schedule_id) in registered_job_keys() for
        algorithm_id in ALGORITHM_IDS
    )
    actual = Set(_algorithm_key(columns, index) for index in eachindex(columns.origin_id))
    actual == expected || push!(errors, "analysis algorithm keys differ from the registry")
    length(actual) == 1260 || push!(errors, "analysis algorithm keys are duplicated")
    for index in eachindex(columns.origin_id)
        getproperty(columns, :selected_identity_sha256)[index] ==
        _sha256_text(String(getproperty(columns, :selected_active_ids)[index])) ||
            push!(errors, "selected-identity hash differs at algorithm row $index")
        candidate = Bool(getproperty(columns, :candidate_returned)[index])
        feasible = getproperty(columns, :exact_feasible)[index]
        candidate && feasible !== true &&
            push!(errors, "returned candidate lacks an exact feasibility certificate")
    end
    return parquet_row_count(columns)
end


function _audit_instance_rows(path, errors)
    columns = parquet_columns(path)
    parquet_row_count(columns) == 180 ||
        push!(errors, "instance analysis table does not contain 180 rows")
    _audit_no_raw_columns(columns, "instance analysis", errors)
    expected = Set(registered_job_keys())
    actual = Set(
        (
            String(columns.origin_id[index]),
            String(columns.library_id[index]),
            String(columns.schedule_id[index]),
        ) for index in eachindex(columns.origin_id)
    )
    actual == expected || push!(errors, "instance analysis keys differ from the registry")
    length(actual) == 180 || push!(errors, "instance analysis keys are duplicated")
    return parquet_row_count(columns)
end

function _audit_summary(path, errors)
    columns = parquet_columns(path)
    parquet_row_count(columns) == 63 ||
        push!(errors, "analysis summary does not contain 63 registered groups")
    all(==(20), columns.registered_instance_count) ||
        push!(errors, "analysis summary drops an origin from a denominator")
    return parquet_row_count(columns)
end

function _audit_overlap(path, errors)
    columns = parquet_columns(path)
    parquet_row_count(columns) == 5040 ||
        push!(errors, "analysis identity-overlap table does not contain 5040 comparisons")
    for value in columns.jaccard
        ismissing(value) || 0.0 <= value <= 1.0 ||
            push!(errors, "identity-overlap Jaccard value is outside [0,1]")
    end
    return parquet_row_count(columns)
end


function _audit_exact_agreement(path, errors)
    columns = parquet_columns(path)
    parquet_row_count(columns) == 180 ||
        push!(errors, "exact-method agreement table does not contain 180 rows")
    _audit_no_raw_columns(columns, "exact-method agreement", errors)
    all(!, columns.mip_solver_status_used_as_exact_proof) || push!(
        errors,
        "a MIP solver status was represented as exact proof",
    )
    any(value -> value === false, columns.dp_enumeration_objective_agreement) &&
        push!(errors, "DP and complete enumeration disagree on an exact objective")
    for index in eachindex(columns.origin_id)
        columns.mip_solver_claimed_optimal[index] || continue
        columns.mip_exact_objective_agreement[index] === false && push!(
            errors,
            "solver-claimed-optimal MIP and an independent exact method disagree at row $index",
        )
    end
    return parquet_row_count(columns)
end


function _audit_carriers(path, manifest, errors)
    columns = parquet_columns(path)
    count = parquet_row_count(columns)
    count == Int(manifest["carrier_multiplicity_row_count"]) ||
        push!(errors, "carrier-multiplicity row count differs from the manifest")
    _audit_no_raw_columns(columns, "carrier multiplicity", errors)
    all(>(0), columns.carrier_count) ||
        push!(errors, "carrier-multiplicity table contains a carrierless requirement")
    all(index -> Bool(columns.unique_carrier[index]) == (columns.carrier_count[index] == 1),
        eachindex(columns.carrier_count)) ||
        push!(errors, "carrier-multiplicity unique-carrier flag is inconsistent")
    return count
end

function audit_analysis(; write_report::Bool = true, progress_io = stderr)
    Threads.nthreads() == ANALYSIS_THREAD_COUNT || error(
        "financial panel analysis audit requires --threads=$ANALYSIS_THREAD_COUNT; " *
        "found $(Threads.nthreads())",
    )
    config, amendment = load_panel_config()
    amendment["amendment_id"] == "AMENDMENT_020" || error("active analysis amendment changed")
    paths = _paths(config)
    errors = String[]
    isfile(paths.result_audit) || error("final result audit is absent")
    result_audit = TOML.parsefile(paths.result_audit)
    get(result_audit, "passed", false) === true || error("final result audit did not pass")
    isfile(paths.manifest) || error("analysis manifest is absent")
    manifest = TOML.parsefile(paths.manifest)
    manifest["schema_version"] == "financial-panel-analysis-manifest-v1" ||
        push!(errors, "unexpected analysis manifest schema")
    manifest["result_audit_sha256"] == sha256_file(paths.result_audit) ||
        push!(errors, "analysis manifest result-audit binding differs")
    manifest["result_audit_postdecision_aggregate_sha256"] ==
    result_audit["postdecision_result_aggregate_sha256"] ||
        push!(errors, "analysis manifest postdecision aggregate differs")
    manifest["raw_licensed_rows_included"] === false ||
        push!(errors, "analysis manifest declares licensed rows")
    get(manifest, "resumed_partition_count", -1) == 0 ||
        push!(errors, "Amendment 020 requires all analysis partitions to be rematerialized")
    files = Dict(String(relative) => String(hash) for (relative, hash) in manifest["files"])
    relatives = sort!(collect(keys(files)))
    absolute = [joinpath(paths.analysis, relative) for relative in relatives]
    all(isfile, absolute) || push!(errors, "analysis manifest references a missing artifact")
    if all(isfile, absolute)
        actual_hashes, worker_ids = _parallel_hashes(absolute; progress_io)
        for (index, relative) in enumerate(relatives)
            actual_hashes[index] == files[relative] ||
                push!(errors, "analysis artifact hash differs: $relative")
        end
        aggregate = _sha256_text(join(
            ("$relative\0$(files[relative])\n" for relative in relatives),
        ))
        aggregate == manifest["artifact_aggregate_sha256"] ||
            push!(errors, "analysis artifact aggregate differs")
    else
        worker_ids = Int[]
        aggregate = ""
    end
    algorithm_rows = _audit_algorithm_rows(paths.algorithm_rows, errors)
    instance_rows = _audit_instance_rows(paths.instance_rows, errors)
    summary_rows = _audit_summary(paths.summary, errors)
    overlap_rows = _audit_overlap(paths.overlap, errors)
    exact_agreement_rows = _audit_exact_agreement(paths.exact_agreement, errors)
    carrier_rows = _audit_carriers(paths.carrier_multiplicity, manifest, errors)
    registered_tables, registered_figures = _audit_catalog(paths, manifest, errors)
    report = Dict{String,Any}(
        "schema_version" => "financial-panel-analysis-audit-v1",
        "experiment_id" => "financial-strategy-library-panel-v1",
        "audited_at_utc" => _utc_now(),
        "passed" => isempty(errors),
        "integrity_errors" => errors,
        "execution_lock_aggregate_sha256" =>
            manifest["execution_lock_aggregate_sha256"],
        "result_audit_sha256" => manifest["result_audit_sha256"],
        "analysis_manifest_sha256" => sha256_file(paths.manifest),
        "analysis_artifact_aggregate_sha256" => aggregate,
        "registered_algorithm_row_count" => algorithm_rows,
        "registered_instance_row_count" => instance_rows,
        "summary_row_count" => summary_rows,
        "identity_overlap_row_count" => overlap_rows,
        "exact_method_agreement_row_count" => exact_agreement_rows,
        "carrier_multiplicity_row_count" => carrier_rows,
        "registered_table_count" => registered_tables,
        "registered_figure_count" => registered_figures,
        "analysis_audit_thread_count" => Threads.nthreads(),
        "analysis_audit_worker_thread_ids" => sort!(unique(worker_ids)),
        "unsuccessful_rows_retained_in_denominators" => true,
        "raw_licensed_rows_included" => false,
    )
    write_report && _atomic_toml(paths.audit, report)
    isempty(errors) || error("financial panel analysis audit failed: $(join(errors, "; "))")
    return report
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: audit_financial_strategy_library_panel_v1_analysis.jl --check",
    )
    only(args) == "--check" || error("unknown audit mode: $(only(args))")
    println(
        "financial panel analysis audit passed: ",
        audit_analysis()["analysis_artifact_aggregate_sha256"],
    )
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    AuditFinancialStrategyLibraryPanelV1Analysis.main()
end
