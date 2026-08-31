module AuditFinancialStrategyLibraryPanelV1

using Dates
using SHA: sha256
using StrategyInnovation
using TOML

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV1.jl"))
using .FinancialStrategyLibraryPanelV1

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_010.jl"))
using .LockFinancialStrategyLibraryPanelV1Execution010: verify_execution_lock_010

export audit_all_results, audit_structural_results, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const ALGORITHM_IDS = (
    "jump_highs_tagged_cover",
    "requirement_mask_dp",
    "complete_enumeration",
    "weighted_greedy_reverse_delete",
    "heaviest_safe_first",
    "declared_source_order",
    "multistart_random_rechecked_deletion_32",
)
const AUDIT_THREAD_COUNT = 8

_utc_now() = Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")
_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(value) = bytes2hex(sha256(codeunits(value)))

function _audit_progress(
    io::IO,
    label::AbstractString,
    completed::Integer,
    total::Integer,
)
    width = 36
    filled = total == 0 ? width : fld(Int(completed) * width, Int(total))
    bar = repeat("█", filled) * repeat("░", width - filled)
    println(io, "[$(_utc_now())] $label [$bar] $completed/$total")
    flush(io)
    return nothing
end

function _parallel_indexed_audits(
    worker,
    items;
    progress_io::IO = stderr,
    progress_label::AbstractString = "structural-audit",
)
    results = Vector{Any}(undef, length(items))
    worker_thread_ids = Vector{Int}(undef, length(items))
    completed = Threads.Atomic{Int}(0)
    progress_lock = ReentrantLock()
    _audit_progress(progress_io, progress_label, 0, length(items))
    Threads.@threads :static for index in eachindex(items)
        results[index] = worker(items[index])
        worker_thread_ids[index] = Threads.threadid()
        lock(progress_lock) do
            completed_count = Threads.atomic_add!(completed, 1) + 1
            _audit_progress(progress_io, progress_label, completed_count, length(items))
        end
    end
    return results, worker_thread_ids
end

function _paths(config)
    root = joinpath(REPOSITORY_ROOT, String(config["paths"]["local_results_root"]))
    local_data = joinpath(REPOSITORY_ROOT, String(config["paths"]["local_data_root"]))
    return (
        root,
        instances = joinpath(root, "instances"),
        preparation_failures = joinpath(root, "preparation_failures"),
        origin_failures = joinpath(local_data, "origin_failures"),
        preparation = joinpath(root, "PREPARATION_MANIFEST.toml"),
        structural = joinpath(root, "structural"),
        solver_logs = joinpath(root, "solver_logs"),
        postdecision = joinpath(root, "postdecision"),
        structural_audit = joinpath(root, "STRUCTURAL_AUDIT.toml"),
        result_audit = joinpath(root, "RESULT_AUDIT.toml"),
    )
end

function _atomic_toml(path, payload)
    mkpath(dirname(path))
    temporary = path * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, toml_text(payload))
    end
    mv(temporary, path; force = true)
    return path
end

_stem(origin_id, library_id, schedule_id) = "$(origin_id)__$(library_id)__$(schedule_id)"

function _expected_stems()
    return sort!(vec(String[
        _stem(origin_id, library_id, schedule_id) for
        (origin_id, library_id, schedule_id) in registered_job_keys()
    ]))
end

function _toml_stems(directory)
    isdir(directory) || return String[]
    return sort!(String[
        first(splitext(name)) for name in readdir(directory) if endswith(name, ".toml")
    ])
end

function _aggregate_hash(entries)
    return _sha256_text(join(
        ("$path\0$(entries[path])\n" for path in sort!(collect(keys(entries)))),
    ))
end

function _read_instance(path)
    return open(path, "r") do io
        read_journal_compression_instance(io)
    end
end

function _audit_preparation(paths, errors)
    isfile(paths.preparation) || begin
        push!(errors, "preparation manifest is absent")
        return Dict{String,String}()
    end
    manifest = TOML.parsefile(paths.preparation)
    get(manifest, "registered_slot_count", 0) == 180 ||
        push!(errors, "preparation manifest does not contain 180 registered slots")
    get(manifest, "serialized_instance_count", 0) == 108 ||
        push!(errors, "preparation manifest does not contain 108 source instances")
    get(manifest, "preparation_failure_slot_count", 0) == 72 ||
        push!(errors, "preparation manifest does not contain 72 failure slots")
    get(manifest, "successful_origin_count", 0) == 12 ||
        push!(errors, "preparation manifest does not contain 12 successful origins")
    get(manifest, "failed_origin_count", 0) == 8 ||
        push!(errors, "preparation manifest does not contain 8 failed origins")
    get(manifest, "return_values_used_for_universe_selection", true) === false ||
        push!(errors, "universe selection return firewall is false")
    get(manifest, "structural_return_maps_origin_scoped", false) === true ||
        push!(errors, "structural return maps are not declared origin scoped")
    get(manifest, "shared_cross_origin_return_map_created", true) === false ||
        push!(errors, "a shared cross-origin return map was declared")
    get(manifest, "new_security_initialization_rows_excluded", -1) == 340 ||
        push!(errors, "structural CRSP NS initialization count differs from Amendment 002")
    get(manifest, "interior_missing_return_rows", -1) == 0 ||
        push!(errors, "structural extraction has an interior missing return")
    get(manifest, "unexpected_return_flag_rows", -1) == 0 ||
        push!(errors, "structural extraction has an unexpected return flag")
    get(manifest, "postdecision_returns_opened", true) === false ||
        push!(errors, "preparation manifest says postdecision returns were opened")
    get(manifest, "licensed_rows_included", true) === false ||
        push!(errors, "preparation manifest contains licensed rows")
    entries = Dict{String,String}()
    for (relative, expected) in get(manifest, "files", Dict{String,Any}())
        path = normpath(joinpath(paths.root, String(relative)))
        isfile(path) || begin
            push!(errors, "prepared file is missing: $relative")
            continue
        end
        actual = _sha256_file(path)
        actual == expected || push!(errors, "prepared file hash differs: $relative")
        entries[String(relative)] = actual
    end
    return entries
end

function _audit_preparation_failure_payload(payload, preparation_failure, errors, stem)
    get(payload, "terminal", false) === true || push!(errors, "$stem failure is nonterminal")
    get(payload, "source_instance_available", true) === false ||
        push!(errors, "$stem preparation failure claims a source instance")
    get(payload, "source_instance_fabricated", true) === false ||
        push!(errors, "$stem preparation failure fabricated a source instance")
    get(payload, "algorithm_terminal_row_count", 0) == 7 ||
        push!(errors, "$stem preparation failure does not preserve seven terminal rows")
    String.(get(payload, "registered_algorithm_ids", String[])) == collect(ALGORITHM_IDS) ||
        push!(errors, "$stem preparation failure algorithm registry differs")
    get(payload, "preparation_failure_sha256", "") == preparation_failure["record_sha256"] ||
        push!(errors, "$stem preparation failure link hash differs")
    get(payload, "postdecision_opened", true) === false ||
        push!(errors, "$stem preparation failure says postdecision was opened")
    get(payload, "licensed_rows_included", true) === false ||
        push!(errors, "$stem preparation failure contains licensed rows")
    return nothing
end

function _audit_preparation_failure_record(payload, paths, errors, stem)
    get(payload, "schema_version", "") ==
    "financial-strategy-library-panel-preparation-failure-v1" ||
        push!(errors, "$stem has an unrecognized preparation-failure schema")
    get(payload, "terminal", false) === true ||
        push!(errors, "$stem preparation-failure record is nonterminal")
    get(payload, "source_instance_available", true) === false ||
        push!(errors, "$stem preparation-failure record claims an instance")
    get(payload, "source_instance_fabricated", true) === false ||
        push!(errors, "$stem preparation-failure record fabricated an instance")
    get(payload, "algorithm_terminal_row_count", 0) == 7 ||
        push!(errors, "$stem preparation-failure record does not preserve seven rows")
    String.(get(payload, "registered_algorithm_ids", String[])) == collect(ALGORITHM_IDS) ||
        push!(errors, "$stem preparation-failure record algorithm registry differs")
    origin_relative = String(get(payload, "origin_failure_path", ""))
    origin_path = normpath(joinpath(paths.root, origin_relative))
    if !isfile(origin_path)
        push!(errors, "$stem linked origin-failure record is absent")
    elseif _sha256_file(origin_path) != get(payload, "origin_failure_sha256", "")
        push!(errors, "$stem linked origin-failure hash differs")
    else
        origin_payload = TOML.parsefile(origin_path)
        get(origin_payload, "schema_version", "") ==
        "financial-strategy-library-panel-origin-construction-failure-v1" ||
            push!(errors, "$stem linked origin-failure schema differs")
        get(origin_payload, "terminal", false) === true ||
            push!(errors, "$stem linked origin failure is nonterminal")
        get(origin_payload, "source_instance_fabricated", true) === false ||
            push!(errors, "$stem linked origin failure fabricated an instance")
        get(origin_payload, "profile_imputed", true) === false ||
            push!(errors, "$stem linked origin failure imputed a profile")
        get(origin_payload, "licensed_rows_included", true) === false ||
            push!(errors, "$stem linked origin failure contains licensed rows")
    end
    return nothing
end

function _audit_failure_payload(payload, instance, errors, stem)
    get(payload, "terminal", false) === true || push!(errors, "$stem failure is nonterminal")
    get(payload, "algorithm_terminal_row_count", 0) == 7 ||
        push!(errors, "$stem failure does not preserve seven terminal rows")
    String.(get(payload, "registered_algorithm_ids", String[])) == collect(ALGORITHM_IDS) ||
        push!(errors, "$stem failure algorithm registry differs")
    get(payload, "instance_sha256", "") == journal_compression_instance_sha256(instance) ||
        push!(errors, "$stem failure instance hash differs")
    get(payload, "postdecision_opened", true) === false ||
        push!(errors, "$stem failure says postdecision was opened")
    get(payload, "licensed_rows_included", true) === false ||
        push!(errors, "$stem failure contains licensed rows")
    return nothing
end

function _stem_audit_record(
    errors;
    result_relative = nothing,
    result_sha256 = nothing,
    success_count = 0,
    preparation_failure_count = 0,
    execution_failure_count = 0,
    algorithm_error_count = 0,
    inapplicable_count = 0,
    candidate_count = 0,
    exact_reference_count = 0,
    missing_solver_log_count = 0,
    checked_algorithm_rows = 0,
)
    return (;
        errors,
        result_relative,
        result_sha256,
        success_count,
        preparation_failure_count,
        execution_failure_count,
        algorithm_error_count,
        inapplicable_count,
        candidate_count,
        exact_reference_count,
        missing_solver_log_count,
        checked_algorithm_rows,
    )
end

function _audit_structural_stem(stem, paths)
    errors = String[]
    instance_path = joinpath(paths.instances, stem * ".toml")
    preparation_failure_path = joinpath(paths.preparation_failures, stem * ".toml")
    result_path = joinpath(paths.structural, stem * ".toml")
    isfile(result_path) || return _stem_audit_record(errors)
    if isfile(preparation_failure_path)
        isfile(instance_path) && begin
            push!(errors, "$stem has both an instance and a preparation failure")
            return _stem_audit_record(errors)
        end
        preparation_failure = try
            TOML.parsefile(preparation_failure_path)
        catch exception
            push!(errors, "$stem preparation failure cannot be parsed: $(sprint(showerror, exception))")
            return _stem_audit_record(errors)
        end
        preparation_failure["record_sha256"] = _sha256_file(preparation_failure_path)
        _audit_preparation_failure_record(preparation_failure, paths, errors, stem)
        payload = try
            TOML.parsefile(result_path)
        catch exception
            push!(errors, "$stem result cannot be parsed: $(sprint(showerror, exception))")
            return _stem_audit_record(errors)
        end
        payload["schema_version"] ==
        "financial-strategy-library-panel-preparation-failure-result-v1" ||
            push!(errors, "$stem preparation failure has an unrecognized structural schema")
        _audit_preparation_failure_payload(payload, preparation_failure, errors, stem)
        return _stem_audit_record(
            errors;
            result_relative = relpath(result_path, paths.root),
            result_sha256 = _sha256_file(result_path),
            preparation_failure_count = 1,
            checked_algorithm_rows = 7,
        )
    end
    isfile(instance_path) || return _stem_audit_record(errors)
    instance_file_sha256 = _sha256_file(instance_path)
    instance = try
        _read_instance(instance_path)
    catch exception
        push!(errors, "$stem instance cannot be deserialized: $(sprint(showerror, exception))")
        return _stem_audit_record(errors)
    end
    payload = try
        TOML.parsefile(result_path)
    catch exception
        push!(errors, "$stem result cannot be parsed: $(sprint(showerror, exception))")
        return _stem_audit_record(errors)
    end
    result_relative = relpath(result_path, paths.root)
    result_sha256 = _sha256_file(result_path)
    schema = get(payload, "schema_version", "")
    if schema == "financial-strategy-library-panel-instance-failure-v1"
        _audit_failure_payload(payload, instance, errors, stem)
        return _stem_audit_record(
            errors;
            result_relative,
            result_sha256,
            execution_failure_count = 1,
            checked_algorithm_rows = 7,
        )
    end
    if schema != "financial-strategy-library-panel-instance-result-v1"
        push!(errors, "$stem has an unrecognized terminal schema")
        return _stem_audit_record(errors; result_relative, result_sha256)
    end
    audit = audit_instance_result(
        instance,
        payload;
        precomputed_instance_sha256 = instance_file_sha256,
    )
    if audit["passed"] !== true
        append!(errors, ("$stem: $message" for message in audit["errors"]))
    end
    get(payload, "postdecision_opened", true) === false ||
        push!(errors, "$stem structural result says postdecision was opened")
    get(payload, "licensed_rows_included", true) === false ||
        push!(errors, "$stem structural result contains licensed rows")
    algorithms = payload["algorithms"]
    log_relative = get(payload, "solver_log_path", nothing)
    missing_solver_log_count = 0
    if isnothing(log_relative)
        missing_solver_log_count = 1
    else
        log_path = normpath(joinpath(paths.root, String(log_relative)))
        if !isfile(log_path)
            push!(errors, "$stem solver log is absent")
        elseif _sha256_file(log_path) != get(payload, "solver_log_sha256", "")
            push!(errors, "$stem solver log hash differs")
        end
    end
    return _stem_audit_record(
        errors;
        result_relative,
        result_sha256,
        success_count = 1,
        algorithm_error_count = count(row -> row["status"] == "ERROR", algorithms),
        inapplicable_count = count(row -> row["applicable"] === false, algorithms),
        candidate_count = count(row -> row["candidate_returned"] === true, algorithms),
        exact_reference_count = get(payload, "global_optimum_exactly_verified", false) === true,
        missing_solver_log_count,
        checked_algorithm_rows = length(algorithms),
    )
end

function audit_structural_results(; write_report::Bool = true)
    Threads.nthreads() == AUDIT_THREAD_COUNT || error(
        "financial panel structural audit requires --threads=$AUDIT_THREAD_COUNT; " *
        "found $(Threads.nthreads())",
    )
    execution_lock = verify_execution_lock_010()
    config, _ = load_panel_config()
    paths = _paths(config)
    errors = String[]
    prepared_hashes = _audit_preparation(paths, errors)
    expected = _expected_stems()
    instance_stems = _toml_stems(paths.instances)
    preparation_failure_stems = _toml_stems(paths.preparation_failures)
    isempty(intersect(instance_stems, preparation_failure_stems)) ||
        push!(errors, "a registered key has both an instance and a preparation failure")
    sort!(union(instance_stems, preparation_failure_stems)) == expected ||
        push!(errors, "instances and preparation failures do not cover the 180 registered keys")
    length(instance_stems) == 108 || push!(errors, "serialized instance set does not contain 108 keys")
    length(preparation_failure_stems) == 72 ||
        push!(errors, "preparation failure set does not contain 72 keys")
    failed_origins = sort!(unique([first(split(stem, "__")) for stem in preparation_failure_stems]))
    _toml_stems(paths.origin_failures) == failed_origins ||
        push!(errors, "origin-failure records do not match failed preparation origins")
    _toml_stems(paths.structural) == expected ||
        push!(errors, "structural result set differs from the 180 registered keys")

    audits, worker_thread_ids = _parallel_indexed_audits(expected) do stem
        return try
            _audit_structural_stem(stem, paths)
        catch exception
            _stem_audit_record([
                "$stem audit raised an exception: $(sprint(showerror, exception))",
            ])
        end
    end

    result_hashes = Dict{String,String}()
    success_count = 0
    preparation_failure_count = 0
    execution_failure_count = 0
    algorithm_error_count = 0
    inapplicable_count = 0
    candidate_count = 0
    exact_reference_count = 0
    missing_solver_log_count = 0
    checked_algorithm_rows = 0
    for audit in audits
        append!(errors, audit.errors)
        if !isnothing(audit.result_relative)
            result_hashes[audit.result_relative] = audit.result_sha256
        end
        success_count += audit.success_count
        preparation_failure_count += audit.preparation_failure_count
        execution_failure_count += audit.execution_failure_count
        algorithm_error_count += audit.algorithm_error_count
        inapplicable_count += audit.inapplicable_count
        candidate_count += audit.candidate_count
        exact_reference_count += audit.exact_reference_count
        missing_solver_log_count += audit.missing_solver_log_count
        checked_algorithm_rows += audit.checked_algorithm_rows
    end
    checked_algorithm_rows == 1260 ||
        push!(errors, "audit saw $checked_algorithm_rows algorithm terminal rows instead of 1260")
    report = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-structural-audit-v1",
        "experiment_id" => "financial-strategy-library-panel-v1",
        "audited_at_utc" => _utc_now(),
        "passed" => isempty(errors),
        "integrity_errors" => errors,
        "execution_lock_aggregate_sha256" => execution_lock,
        "registered_instance_count" => 180,
        "registered_algorithm_terminal_rows" => 1260,
        "successful_instance_count" => success_count,
        "preparation_failure_instance_count" => preparation_failure_count,
        "execution_failure_instance_count" => execution_failure_count,
        "algorithm_error_count" => algorithm_error_count,
        "inapplicable_algorithm_row_count" => inapplicable_count,
        "candidate_returned_row_count" => candidate_count,
        "exact_reference_instance_count" => exact_reference_count,
        "missing_solver_log_count" => missing_solver_log_count,
        "unsuccessful_rows_retained_in_denominators" => true,
        "solver_status_used_as_formal_or_exhaustive_proof" => false,
        "postdecision_opened_during_structural_audit" => false,
        "licensed_rows_included" => false,
        "audit_thread_count" => Threads.nthreads(),
        "audit_worker_thread_ids" => sort!(unique(worker_thread_ids)),
        "audit_aggregation_order" => "lexicographic registered-key order",
        "preparation_file_count" => length(prepared_hashes),
        "structural_result_sha256" => result_hashes,
        "structural_result_aggregate_sha256" => _aggregate_hash(result_hashes),
    )
    write_report && _atomic_toml(paths.structural_audit, report)
    if report["passed"] !== true
        message = join(errors, "; ")
        error("financial panel structural audit failed: $message")
    end
    return report
end

function _postdecision_audit_record(
    errors;
    result_relative = nothing,
    result_sha256 = nothing,
    available_count = 0,
    structural_failure_count = 0,
    checked_rows = 0,
)
    return (;
        errors,
        result_relative,
        result_sha256,
        available_count,
        structural_failure_count,
        checked_rows,
    )
end

function _audit_postdecision_stem(stem, paths)
    errors = String[]
    structural_path = joinpath(paths.structural, stem * ".toml")
    post_path = joinpath(paths.postdecision, stem * ".toml")
    isfile(structural_path) && isfile(post_path) || return _postdecision_audit_record(errors)
    source = try
        TOML.parsefile(structural_path)
    catch exception
        push!(errors, "$stem structural record cannot be parsed: $(sprint(showerror, exception))")
        return _postdecision_audit_record(errors)
    end
    payload = try
        TOML.parsefile(post_path)
    catch exception
        push!(errors, "$stem postdecision record cannot be parsed: $(sprint(showerror, exception))")
        return _postdecision_audit_record(errors)
    end
    result_relative = relpath(post_path, paths.root)
    result_sha256 = _sha256_file(post_path)
    get(payload, "licensed_rows_included", true) === false ||
        push!(errors, "$stem postdecision record contains licensed rows")
    get(payload, "structural_result_terminal_and_audited_before_open", false) === true ||
        push!(errors, "$stem postdecision record lacks the structural firewall certificate")
    if source["schema_version"] in (
        "financial-strategy-library-panel-instance-failure-v1",
        "financial-strategy-library-panel-preparation-failure-result-v1",
    )
        payload["schema_version"] == "financial-strategy-library-panel-postdecision-failure-v1" ||
            push!(errors, "$stem should have a postdecision failure record")
        get(payload, "postdecision_opened", true) === false ||
            push!(errors, "$stem failed slot says postdecision was opened")
        return _postdecision_audit_record(
            errors;
            result_relative,
            result_sha256,
            structural_failure_count = 1,
        )
    end
    quality = get(payload, "return_quality", Dict{String,Any}())
    get(quality, "interior_missing_return_rows", -1) == 0 ||
        push!(errors, "$stem postdecision extraction has an interior missing return")
    get(quality, "unexpected_return_flag_rows", -1) == 0 ||
        push!(errors, "$stem postdecision extraction has an unexpected return flag")
    payload["schema_version"] == "financial-strategy-library-panel-postdecision-v1" || begin
        push!(errors, "$stem has an unrecognized postdecision schema")
        return _postdecision_audit_record(errors; result_relative, result_sha256)
    end
    get(payload, "structural_instance_sha256", "") == source["instance_sha256"] ||
        push!(errors, "$stem postdecision link hash differs")
    length(get(payload, "source_frontier", Any[])) == 5 ||
        push!(errors, "$stem postdecision source frontier does not have five beliefs")
    algorithms = payload["algorithms"]
    String[row["algorithm_id"] for row in algorithms] == collect(ALGORITHM_IDS) ||
        push!(errors, "$stem postdecision algorithms differ from the registry")
    available_count = 0
    for row in algorithms
        get(row, "available", false) === true || continue
        available_count += 1
        losses = exact_rational.(String.(row["belief_losses"]))
        length(losses) == 5 || push!(errors, "$stem postdecision loss vector length differs")
        all(value -> value >= 0, losses) ||
            push!(errors, "$stem contains a negative source-minus-retained loss")
    end
    return _postdecision_audit_record(
        errors;
        result_relative,
        result_sha256,
        available_count,
        checked_rows = length(algorithms),
    )
end

function audit_all_results(; write_report::Bool = true)
    structural = audit_structural_results(; write_report)
    config, _ = load_panel_config()
    paths = _paths(config)
    expected = _expected_stems()
    errors = String[]
    _toml_stems(paths.postdecision) == expected ||
        push!(errors, "postdecision result set differs from the 180 registered keys")
    audits, worker_thread_ids = _parallel_indexed_audits(
        expected;
        progress_label = "postdecision-audit",
    ) do stem
        return try
            _audit_postdecision_stem(stem, paths)
        catch exception
            _postdecision_audit_record([
                "$stem postdecision audit raised an exception: $(sprint(showerror, exception))",
            ])
        end
    end
    hashes = Dict{String,String}()
    available_count = 0
    structural_failure_count = 0
    checked_rows = 0
    for audit in audits
        append!(errors, audit.errors)
        if !isnothing(audit.result_relative)
            hashes[audit.result_relative] = audit.result_sha256
        end
        available_count += audit.available_count
        structural_failure_count += audit.structural_failure_count
        checked_rows += audit.checked_rows
    end
    checked_rows + 7 * structural_failure_count == 1260 ||
        push!(errors, "postdecision audit does not account for all 1260 algorithm rows")
    report = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-result-audit-v1",
        "experiment_id" => "financial-strategy-library-panel-v1",
        "audited_at_utc" => _utc_now(),
        "passed" => isempty(errors),
        "integrity_errors" => errors,
        "structural_audit_aggregate_sha256" =>
            structural["structural_result_aggregate_sha256"],
        "registered_instance_count" => 180,
        "registered_algorithm_terminal_rows" => 1260,
        "postdecision_available_algorithm_rows" => available_count,
        "structural_failure_instance_count" => structural_failure_count,
        "unsuccessful_rows_retained_in_denominators" => true,
        "postdecision_cannot_change_structural_results" => true,
        "licensed_rows_included" => false,
        "audit_thread_count" => Threads.nthreads(),
        "audit_worker_thread_ids" => sort!(unique(worker_thread_ids)),
        "audit_aggregation_order" => "lexicographic registered-key order",
        "postdecision_result_sha256" => hashes,
        "postdecision_result_aggregate_sha256" => _aggregate_hash(hashes),
    )
    write_report && _atomic_toml(paths.result_audit, report)
    if report["passed"] !== true
        message = join(errors, "; ")
        error("financial panel result audit failed: $message")
    end
    return report
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: audit_financial_strategy_library_panel_v1.jl --structural|--all",
    )
    mode = only(args)
    mode == "--structural" && return println(
        "financial panel structural audit passed: " *
        string(audit_structural_results()["structural_result_aggregate_sha256"]),
    )
    mode == "--all" && return println(
        "financial panel full audit passed: " *
        string(audit_all_results()["postdecision_result_aggregate_sha256"]),
    )
    error("unknown audit mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    AuditFinancialStrategyLibraryPanelV1.main()
end
