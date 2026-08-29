module RunFinancialStrategyLibraryPanelV1

using Dates
using LinearAlgebra
using SHA: sha256
using StrategyInnovation
using TOML

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV1.jl"))
using .FinancialStrategyLibraryPanelV1

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_003.jl"))
using .LockFinancialStrategyLibraryPanelV1Execution003: verify_execution_lock_003

export main,
       prepare_instances,
       run_postdecision_phase,
       run_smoke,
       run_structural_phase,
       validate_readiness

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_strategy_library_panel_v1.toml",
)
const THREAD_COUNT = 8

_utc_now() = Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")
_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

function _atomic_write(path, text; replace = false)
    mkpath(dirname(path))
    temporary = path * ".tmp.$(getpid()).$(Threads.threadid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, path; force = replace)
    return path
end

_atomic_toml(path, payload; replace = false) =
    _atomic_write(path, toml_text(payload); replace)

function _paths(config)
    paths = config["paths"]
    local_data = joinpath(REPOSITORY_ROOT, String(paths["local_data_root"]))
    local_results = joinpath(REPOSITORY_ROOT, String(paths["local_results_root"]))
    return (
        local_data,
        local_results,
        instances = joinpath(local_results, "instances"),
        origin_metadata = joinpath(local_data, "origin_builds"),
        origin_failures = joinpath(local_data, "origin_failures"),
        preparation_failures = joinpath(local_results, "preparation_failures"),
        preparation_manifest = joinpath(local_results, "PREPARATION_MANIFEST.toml"),
        structural = joinpath(local_results, "structural"),
        solver_logs = joinpath(local_results, "solver_logs"),
        postdecision = joinpath(local_results, "postdecision"),
        environment = joinpath(local_results, "ENVIRONMENT.toml"),
    )
end

function _source_root(config)
    if haskey(ENV, "ALGOLIB_CRSP_ROOT") && !isempty(strip(ENV["ALGOLIB_CRSP_ROOT"]))
        root = ENV["ALGOLIB_CRSP_ROOT"]
        return isabspath(root) ? normpath(root) : normpath(joinpath(REPOSITORY_ROOT, root))
    end
    configured = String(config["source"]["repository_root_default"])
    return normpath(joinpath(REPOSITORY_ROOT, configured))
end

function _environment(
    execution_lock_aggregate;
    replaced_predecessor_environment = false,
    predecessor_instance_count = 0,
    predecessor_origin_metadata_count = 0,
)
    LinearAlgebra.BLAS.set_num_threads(1)
    commit = try
        strip(read(`git -C $REPOSITORY_ROOT rev-parse HEAD`, String))
    catch
        "UNAVAILABLE"
    end
    status = try
        read(`git -C $REPOSITORY_ROOT status --porcelain=v1 --untracked-files=all`, String)
    catch
        "UNAVAILABLE"
    end
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-environment-v3",
        "recorded_at_utc" => _utc_now(),
        "git_commit" => commit,
        "dirty_worktree" => !isempty(strip(status)),
        "dirty_worktree_status_sha256" => bytes2hex(sha256(codeunits(status))),
        "julia_version" => string(VERSION),
        "julia_threads" => Threads.nthreads(),
        "blas_threads" => LinearAlgebra.BLAS.get_num_threads(),
        "highs_threads_per_model" => 1,
        "threaded_lane_count" => THREAD_COUNT,
        "execution_lock_aggregate_sha256" => execution_lock_aggregate,
        "active_amendment_id" => "AMENDMENT_003",
        "replaced_predecessor_environment" => replaced_predecessor_environment,
        "predecessor_instance_count" => predecessor_instance_count,
        "predecessor_origin_metadata_count" => predecessor_origin_metadata_count,
        "dependency_manifest_sha256" =>
            _sha256_file(joinpath(REPOSITORY_ROOT, "julia", "Manifest.toml")),
        "operating_system" => string(Sys.KERNEL),
        "architecture" => string(Sys.ARCH),
        "logical_threads_visible" => Sys.CPU_THREADS,
        "licensed_rows_included" => false,
    )
end

function _progress_line(label, completed, total; width = 36)
    ratio = iszero(total) ? 1.0 : completed / total
    filled = clamp(floor(Int, ratio * width), 0, width)
    bar = repeat("█", filled) * repeat("░", width - filled)
    return "$(rpad(label, 14)) [$bar] $(lpad(completed, ndigits(total)))/$total"
end

function _run_threaded_lanes!(
    jobs,
    label,
    run_one;
    lanes = THREAD_COUNT,
    allow_failures = false,
)
    lanes <= Threads.nthreads() || error(
        "$label requires at least $lanes Julia threads; found $(Threads.nthreads())",
    )
    assignments = [Any[] for _ in 1:lanes]
    for (index, job) in enumerate(jobs)
        push!(assignments[mod1(index, lanes)], job)
    end
    events = Channel{NamedTuple}(max(length(jobs), 1))
    tasks = Task[]
    for lane in 1:lanes
        push!(tasks, Threads.@spawn begin
            for job in assignments[lane]
                try
                    run_one(job, lane)
                    put!(events, (passed = true, lane = lane, job = job, exception = nothing))
                catch exception
                    put!(events, (passed = false, lane = lane, job = job, exception = exception))
                end
            end
        end)
    end
    completed = 0
    failures = NamedTuple[]
    print(stderr, '\r', _progress_line(label, completed, length(jobs)))
    while completed < length(jobs)
        event = take!(events)
        event.passed || push!(failures, event)
        completed += 1
        print(stderr, '\r', _progress_line(label, completed, length(jobs)))
    end
    println(stderr)
    foreach(fetch, tasks)
    (allow_failures || isempty(failures)) || error(
        "$label failed in $(length(failures)) job(s); first lane=$(first(failures).lane): " *
        sprint(showerror, first(failures).exception),
    )
    return (completed = completed, failures = failures)
end

function _instance_stem(origin_id, library_id, schedule_id)
    return "$(origin_id)__$(library_id)__$(schedule_id)"
end

function _read_instance(path)
    return open(path, "r") do io
        read_journal_compression_instance(io)
    end
end

function _registry_seed(origin_id, library_id)
    row = only(filter(
        item -> item.origin_id == origin_id && item.library_id == library_id,
        FinancialStrategyLibraryPanelV1.FinancialStrategyLibraryPanelV1Registries.seed_rows(),
    ))
    return string(row.multistart_seed)
end

function validate_readiness(; require_sources::Bool = true)
    verify_execution_lock_003()
    VERSION == v"1.12.6" || error("financial panel v1 requires Julia 1.12.6")
    Threads.nthreads() == THREAD_COUNT || error(
        "financial panel v1 requires --threads=$THREAD_COUNT; found $(Threads.nthreads())",
    )
    LinearAlgebra.BLAS.set_num_threads(1)
    LinearAlgebra.BLAS.get_num_threads() == 1 || error("BLAS must use one thread")
    config, amendment = load_panel_config()
    amendment["threading"]["julia_threads"] == THREAD_COUNT ||
        error("execution amendment thread count changed")
    if require_sources
        paths = source_paths(config, _source_root(config))
        missing = filter(!isfile, [paths.security_history; paths.daily_files])
        isempty(missing) || error(
            "licensed source files are missing. Set ALGOLIB_CRSP_ROOT to the licensed CRSP root.",
        )
    end
    return config, amendment
end

function _write_environment(paths)
    execution_lock_aggregate = verify_execution_lock_003()
    if isfile(paths.environment)
        environment = TOML.parsefile(paths.environment)
        if get(environment, "execution_lock_aggregate_sha256", "") == execution_lock_aggregate
            environment["julia_version"] == string(VERSION) || error("saved environment Julia version differs")
            environment["julia_threads"] == THREAD_COUNT || error("saved environment thread count differs")
            return environment
        end
        instance_count = isdir(paths.instances) ?
                         count(name -> endswith(name, ".toml"), readdir(paths.instances)) : 0
        origin_metadata_count = isdir(paths.origin_metadata) ?
                                count(name -> endswith(name, ".toml"), readdir(paths.origin_metadata)) : 0
        successor_recovery = !isfile(paths.preparation_manifest) &&
                             instance_count == 108 &&
                             origin_metadata_count == 12 &&
                             all(
            directory -> !isdir(directory) || isempty(readdir(directory)),
            (paths.structural, paths.postdecision, paths.preparation_failures, paths.origin_failures),
        )
        successor_recovery || error(
            "saved environment belongs to an earlier execution lock outside Amendment 003 recovery",
        )
        environment = _environment(
            execution_lock_aggregate;
            replaced_predecessor_environment = true,
            predecessor_instance_count = instance_count,
            predecessor_origin_metadata_count = origin_metadata_count,
        )
        _atomic_toml(paths.environment, environment; replace = true)
        return environment
    end
    environment = _environment(execution_lock_aggregate)
    _atomic_toml(paths.environment, environment)
    return environment
end

function _write_once_or_match(path, text, drift_message)
    if isfile(path)
        read(path, String) == text || error(drift_message)
    else
        _atomic_write(path, text)
    end
    return _sha256_file(path)
end

function _sanitized_origin_failure(exception)
    message = sprint(showerror, exception)
    if occursin("a registered belief profile has too few observations", message)
        return "registered belief profile has too few observations"
    end
    return "origin construction failed without a distributable row-level diagnostic"
end

_is_registered_origin_rejection(exception) =
    sprint(showerror, exception) == "a registered belief profile has too few observations"

function _preparation_failure_payload(job, origin_failure_relative, origin_failure_sha256, exception)
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-preparation-failure-v1",
        "experiment_id" => "financial-strategy-library-panel-v1",
        "origin_id" => job.origin_id,
        "library_id" => job.library_id,
        "schedule_id" => job.schedule_id,
        "terminal" => true,
        "source_instance_available" => false,
        "source_instance_fabricated" => false,
        "algorithm_terminal_row_count" => 7,
        "registered_algorithm_ids" => collect(FinancialStrategyLibraryPanelV1.ALGORITHM_IDS),
        "failure_type" => string(typeof(exception)),
        "failure_message" => _sanitized_origin_failure(exception),
        "origin_failure_path" => origin_failure_relative,
        "origin_failure_sha256" => origin_failure_sha256,
        "postdecision_opened" => false,
        "licensed_rows_included" => false,
    )
end

function _origin_payload(origin)
    return Dict{String,Any}(
        "origin_id" => origin.origin_id,
        "decision_year" => origin.decision_year,
        "decision_date" => origin.decision_date,
        "construction_start" => origin.construction_start,
        "construction_end" => origin.construction_end,
        "compression_start" => origin.compression_start,
        "compression_end" => origin.compression_end,
        "postdecision_start" => origin.postdecision_start,
        "postdecision_end" => origin.postdecision_end,
        "candidate_count" => origin.candidate_count,
        "eligible_count" => origin.eligible_count,
        "selected_count" => length(origin.selected),
        "reference_permno" => origin.reference_permno,
        "selected" => [Dict(
            "permno" => row.permno,
            "ticker" => row.ticker,
            "security_name_sha256" => row.security_name_sha256,
            "median_close" => row.median_close,
            "median_dollar_volume" => row.median_dollar_volume,
            "preorigin_daily_rows" => row.preorigin_daily_rows,
            "compression_liquidity_rows" => row.compression_liquidity_rows,
            "invalid_liquidity_rows" => row.invalid_liquidity_rows,
        ) for row in origin.selected],
        "licensed_rows_included" => false,
    )
end

function prepare_instances()
    config, amendment = validate_readiness()
    output = _paths(config)
    _write_environment(output)
    raw_paths = source_paths(config, _source_root(config))
    universes = construct_origin_universes(config, raw_paths)
    return_quality = Dict{String,Any}()
    series_by_origin = extract_origin_series(
        config,
        raw_paths.daily_files,
        universes;
        phase = :structural,
        diagnostics = return_quality,
    )
    entries_lock = ReentrantLock()
    entries = Dict{String,String}()
    run_one = function(origin, lane)
        instances, metadata = build_origin_instances(
            origin,
            series_by_origin[origin.origin_id],
            config,
            amendment,
        )
        metadata["thread_lane"] = lane
        metadata["origin_universe"] = _origin_payload(origin)
        metadata["return_quality"] = return_quality[origin.origin_id]
        metadata_path = joinpath(output.origin_metadata, "$(origin.origin_id).toml")
        metadata_text = toml_text(metadata)
        metadata_hash = _write_once_or_match(
            metadata_path,
            metadata_text,
            "origin metadata drift on resume",
        )
        local_entries = Dict{String,String}(relpath(metadata_path, output.local_results) => metadata_hash)
        for ((library_id, schedule_id), instance) in instances
            stem = _instance_stem(origin.origin_id, library_id, schedule_id)
            path = joinpath(output.instances, stem * ".toml")
            text = serialize_journal_compression_instance(instance)
            local_entries[relpath(path, output.local_results)] = _write_once_or_match(
                path,
                text,
                "instance drift on resume: $stem",
            )
        end
        lock(entries_lock) do
            merge!(entries, local_entries)
        end
        return nothing
    end
    threaded = _run_threaded_lanes!(
        universes,
        "prepare",
        run_one;
        allow_failures = true,
    )
    for failure in threaded.failures
        origin = failure.job
        _is_registered_origin_rejection(failure.exception) || error(
            "prepare encountered an unregistered origin-construction exception of type " *
            string(typeof(failure.exception)),
        )
        origin_instance_paths = filter(
            name -> startswith(name, origin.origin_id * "__") && endswith(name, ".toml"),
            isdir(output.instances) ? readdir(output.instances) : String[],
        )
        isempty(origin_instance_paths) || error(
            "failed origin has serialized source instances: $(origin.origin_id)",
        )
        origin_failure = Dict{String,Any}(
            "schema_version" => "financial-strategy-library-panel-origin-construction-failure-v1",
            "experiment_id" => "financial-strategy-library-panel-v1",
            "origin_id" => origin.origin_id,
            "terminal" => true,
            "phase" => "structural source-instance construction",
            "failure_type" => string(typeof(failure.exception)),
            "failure_message" => _sanitized_origin_failure(failure.exception),
            "registered_instance_failure_slots" => 9,
            "registered_algorithm_terminal_rows" => 63,
            "source_instance_fabricated" => false,
            "profile_imputed" => false,
            "origin_universe" => _origin_payload(origin),
            "return_quality" => return_quality[origin.origin_id],
            "postdecision_opened" => false,
            "licensed_rows_included" => false,
        )
        origin_failure_path = joinpath(output.origin_failures, "$(origin.origin_id).toml")
        origin_failure_hash = _write_once_or_match(
            origin_failure_path,
            toml_text(origin_failure),
            "origin failure drift on resume: $(origin.origin_id)",
        )
        origin_failure_relative = relpath(origin_failure_path, output.local_results)
        entries[origin_failure_relative] = origin_failure_hash
        origin_jobs = [(
            origin_id,
            library_id,
            schedule_id,
            stem = _instance_stem(origin_id, library_id, schedule_id),
        ) for (origin_id, library_id, schedule_id) in registered_job_keys() if
             origin_id == origin.origin_id]
        length(origin_jobs) == 9 || error("registered origin does not map to nine instance slots")
        for job in origin_jobs
            path = joinpath(output.preparation_failures, job.stem * ".toml")
            payload = _preparation_failure_payload(
                job,
                origin_failure_relative,
                origin_failure_hash,
                failure.exception,
            )
            entries[relpath(path, output.local_results)] = _write_once_or_match(
                path,
                toml_text(payload),
                "preparation failure drift on resume: $(job.stem)",
            )
        end
    end
    instance_count = count(name -> endswith(name, ".toml"), readdir(output.instances))
    failure_slot_count = count(
        name -> endswith(name, ".toml"),
        readdir(output.preparation_failures),
    )
    successful_origin_count = count(name -> endswith(name, ".toml"), readdir(output.origin_metadata))
    failed_origin_count = count(name -> endswith(name, ".toml"), readdir(output.origin_failures))
    instance_count == 108 || error("preparation produced $instance_count instances instead of 108")
    failure_slot_count == 72 || error("preparation produced $failure_slot_count failure slots instead of 72")
    successful_origin_count == 12 || error("preparation retained $successful_origin_count successful origins instead of 12")
    failed_origin_count == 8 || error("preparation retained $failed_origin_count failed origins instead of 8")
    instance_count + failure_slot_count == 180 || error("preparation does not account for 180 slots")
    manifest = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-preparation-manifest-v1",
        "created_at_utc" => _utc_now(),
        "origin_count" => length(universes),
        "registered_slot_count" => 180,
        "serialized_instance_count" => instance_count,
        "preparation_failure_slot_count" => failure_slot_count,
        "successful_origin_count" => successful_origin_count,
        "failed_origin_count" => failed_origin_count,
        "registered_algorithm_terminal_rows" => 1260,
        "source_root_recorded" => false,
        "return_values_used_for_universe_selection" => false,
        "structural_return_maps_origin_scoped" => true,
        "shared_cross_origin_return_map_created" => false,
        "missing_return_rule" =>
            "exclude first scoped CRSP NS initialization row without imputation; otherwise fail",
        "new_security_initialization_rows_excluded" => sum(
            quality_row["new_security_initialization_rows_excluded"] for
            quality_row in values(return_quality)
        ),
        "interior_missing_return_rows" => sum(
            quality_row["interior_missing_return_rows"] for
            quality_row in values(return_quality)
        ),
        "unexpected_return_flag_rows" => sum(
            quality_row["unexpected_return_flag_rows"] for
            quality_row in values(return_quality)
        ),
        "postdecision_returns_opened" => false,
        "licensed_rows_included" => false,
        "files" => entries,
    )
    _atomic_toml(output.preparation_manifest, manifest; replace = isfile(output.preparation_manifest))
    return output.preparation_manifest
end

function _validate_preparation(output)
    isfile(output.preparation_manifest) || error("preparation manifest is absent")
    manifest = TOML.parsefile(output.preparation_manifest)
    manifest["registered_slot_count"] == 180 || error("prepared slot count changed")
    manifest["serialized_instance_count"] == 108 || error("prepared instance count changed")
    manifest["preparation_failure_slot_count"] == 72 || error("preparation failure count changed")
    manifest["successful_origin_count"] == 12 || error("successful origin count changed")
    manifest["failed_origin_count"] == 8 || error("failed origin count changed")
    manifest["postdecision_returns_opened"] === false || error("preparation opened postdecision returns")
    manifest["new_security_initialization_rows_excluded"] == 340 ||
        error("registered structural CRSP NS initialization count changed")
    manifest["interior_missing_return_rows"] == 0 ||
        error("structural extraction contains an interior missing return")
    manifest["unexpected_return_flag_rows"] == 0 ||
        error("structural extraction contains an unexpected return flag")
    for (relative, expected) in manifest["files"]
        path = joinpath(output.local_results, relative)
        isfile(path) || error("prepared artifact is missing: $relative")
        _sha256_file(path) == expected || error("prepared artifact hash mismatch: $relative")
    end
    return manifest
end

function _failure_payload(job, instance, exception)
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-instance-failure-v1",
        "experiment_id" => "financial-strategy-library-panel-v1",
        "origin_id" => job.origin_id,
        "library_id" => job.library_id,
        "schedule_id" => job.schedule_id,
        "instance_sha256" => journal_compression_instance_sha256(instance),
        "terminal" => true,
        "algorithm_terminal_row_count" => 7,
        "registered_algorithm_ids" => collect(FinancialStrategyLibraryPanelV1.ALGORITHM_IDS),
        "failure_type" => string(typeof(exception)),
        "failure_message" => sprint(showerror, exception),
        "postdecision_opened" => false,
        "licensed_rows_included" => false,
    )
end

function _preparation_failure_result(job, preparation_failure, lane)
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-preparation-failure-result-v1",
        "experiment_id" => "financial-strategy-library-panel-v1",
        "origin_id" => job.origin_id,
        "library_id" => job.library_id,
        "schedule_id" => job.schedule_id,
        "terminal" => true,
        "source_instance_available" => false,
        "source_instance_fabricated" => false,
        "algorithm_terminal_row_count" => 7,
        "registered_algorithm_ids" => collect(FinancialStrategyLibraryPanelV1.ALGORITHM_IDS),
        "failure_type" => preparation_failure["failure_type"],
        "failure_message" => preparation_failure["failure_message"],
        "preparation_failure_sha256" => preparation_failure["record_sha256"],
        "thread_lane" => lane,
        "postdecision_opened" => false,
        "licensed_rows_included" => false,
    )
end

function run_structural_phase()
    config, _ = validate_readiness(; require_sources = false)
    output = _paths(config)
    _validate_preparation(output)
    _write_environment(output)
    jobs = [(
        origin_id,
        library_id,
        schedule_id,
        stem = _instance_stem(origin_id, library_id, schedule_id),
    ) for (origin_id, library_id, schedule_id) in registered_job_keys()]
    run_one = function(job, lane)
        instance_path = joinpath(output.instances, job.stem * ".toml")
        preparation_failure_path = joinpath(output.preparation_failures, job.stem * ".toml")
        result_path = joinpath(output.structural, job.stem * ".toml")
        if isfile(result_path)
            saved = TOML.parsefile(result_path)
            saved["terminal"] === true || error("nonterminal saved result: $(job.stem)")
            if saved["schema_version"] == "financial-strategy-library-panel-instance-result-v1"
                instance = _read_instance(instance_path)
                audit_instance_result(instance, saved)["passed"] === true ||
                    error("saved result fails resume audit: $(job.stem)")
            elseif saved["schema_version"] !=
                   "financial-strategy-library-panel-preparation-failure-result-v1"
                error("unrecognized saved result schema: $(job.stem)")
            end
            return nothing
        end
        if isfile(preparation_failure_path)
            isfile(instance_path) && error("failed preparation slot also has a source instance")
            preparation_failure = TOML.parsefile(preparation_failure_path)
            preparation_failure["record_sha256"] = _sha256_file(preparation_failure_path)
            payload = _preparation_failure_result(job, preparation_failure, lane)
            _atomic_toml(result_path, payload)
            return nothing
        end
        isfile(instance_path) || error("registered slot has neither an instance nor a failure record")
        instance = _read_instance(instance_path)
        payload = nothing
        logs = Dict{String,String}()
        try
            payload, logs = run_algorithm_suite(
                instance;
                origin_id = job.origin_id,
                library_id = job.library_id,
                schedule_id = job.schedule_id,
                config,
            )
            payload["thread_lane"] = lane
            payload["multistart_seed"] = _registry_seed(job.origin_id, job.library_id)
        catch exception
            payload = _failure_payload(job, instance, exception)
            payload["thread_lane"] = lane
        end
        for (algorithm_id, log) in logs
            log_path = joinpath(output.solver_logs, job.stem * "__$(algorithm_id).log")
            _atomic_write(log_path, log)
            payload["solver_log_sha256"] = _sha256_file(log_path)
            payload["solver_log_path"] = relpath(log_path, output.local_results)
        end
        _atomic_toml(result_path, payload)
        return nothing
    end
    _run_threaded_lanes!(jobs, "structural", run_one)
    return output.structural
end

function _origin_from_saved(payload)
    selected = NamedTuple[
        (
            permno = Int(row["permno"]),
            ticker = String(row["ticker"]),
            security_name_sha256 = String(row["security_name_sha256"]),
            median_close = Float64(row["median_close"]),
            median_dollar_volume = Float64(row["median_dollar_volume"]),
            preorigin_daily_rows = Int(row["preorigin_daily_rows"]),
            compression_liquidity_rows = Int(row["compression_liquidity_rows"]),
            invalid_liquidity_rows = Int(row["invalid_liquidity_rows"]),
        ) for row in payload["selected"]
    ]
    return OriginUniverse(
        String(payload["origin_id"]),
        Int(payload["decision_year"]),
        String(payload["decision_date"]),
        String(payload["construction_start"]),
        String(payload["construction_end"]),
        String(payload["compression_start"]),
        String(payload["compression_end"]),
        String(payload["postdecision_start"]),
        String(payload["postdecision_end"]),
        selected,
        Int(payload["candidate_count"]),
        Int(payload["eligible_count"]),
        Int(payload["reference_permno"]),
    )
end

function _source_identity_tokens(instance)
    return Set(
        join(split(string(instance.strategy_ids[index].id), '|')[3:end], '|') for
        index in eachindex(instance.strategy_ids) if !instance.mandatory[index]
    )
end

function run_postdecision_phase()
    config, amendment = validate_readiness()
    output = _paths(config)
    structural_audit_path = joinpath(output.local_results, "STRUCTURAL_AUDIT.toml")
    isfile(structural_audit_path) || error("structural audit is absent; run the audit before postdecision")
    structural_audit = TOML.parsefile(structural_audit_path)
    structural_audit["passed"] === true || error("structural audit did not pass")
    origins = Dict{String,OriginUniverse}()
    thresholds = Dict{String,Vector{Float64}}()
    for origin_row in FinancialStrategyLibraryPanelV1.FinancialStrategyLibraryPanelV1Registries.origin_rows()
        path = joinpath(output.origin_metadata, "$(origin_row.origin_id).toml")
        failure_path = joinpath(output.origin_failures, "$(origin_row.origin_id).toml")
        isfile(path) == isfile(failure_path) && error(
            "origin must have exactly one success or construction-failure record",
        )
        payload = TOML.parsefile(isfile(path) ? path : failure_path)
        origin_payload = payload["origin_universe"]
        origins[origin_row.origin_id] = _origin_from_saved(origin_payload)
        isfile(path) && (thresholds[origin_row.origin_id] = Float64.(payload["belief_thresholds"]))
    end
    raw_paths = source_paths(config, _source_root(config))
    postdecision_return_quality = Dict{String,Any}()
    series_by_origin = extract_origin_series(
        config,
        raw_paths.daily_files,
        [origins[origin_id] for origin_id in sort!(collect(keys(thresholds)))];
        phase = :postdecision,
        diagnostics = postdecision_return_quality,
    )
    jobs = [(
        origin_id,
        library_id,
        schedule_id,
        stem = _instance_stem(origin_id, library_id, schedule_id),
    ) for (origin_id, library_id, schedule_id) in registered_job_keys()]
    run_one = function(job, lane)
        destination = joinpath(output.postdecision, job.stem * ".toml")
        isfile(destination) && return nothing
        result_payload = TOML.parsefile(joinpath(output.structural, job.stem * ".toml"))
        payload = if result_payload["schema_version"] ==
                     "financial-strategy-library-panel-instance-result-v1"
            instance = _read_instance(joinpath(output.instances, job.stem * ".toml"))
            next_year = origins[job.origin_id].decision_year + 1
            next_origin_id = next_year <= 2024 ? "FSLP1-O$next_year" : nothing
            next_instance_path = isnothing(next_origin_id) ? nothing : joinpath(
                output.instances,
                _instance_stem(next_origin_id, job.library_id, job.schedule_id) * ".toml",
            )
            next_identities = if isnothing(next_instance_path) || !isfile(next_instance_path)
                nothing
            else
                _source_identity_tokens(_read_instance(next_instance_path))
            end
            evaluate_postdecision(
                instance,
                result_payload,
                origins[job.origin_id],
                series_by_origin[job.origin_id],
                thresholds[job.origin_id],
                config,
                amendment;
                next_origin_source_identities = next_identities,
            )
        else
            Dict{String,Any}(
                "schema_version" => "financial-strategy-library-panel-postdecision-failure-v1",
                "origin_id" => job.origin_id,
                "library_id" => job.library_id,
                "schedule_id" => job.schedule_id,
                "available" => false,
                "reason" => result_payload["schema_version"] ==
                            "financial-strategy-library-panel-preparation-failure-result-v1" ?
                            "registered source-instance construction failure" :
                            "structural algorithm-suite failure",
                "structural_result_terminal_and_audited_before_open" => true,
                "postdecision_opened" => false,
                "licensed_rows_included" => false,
            )
        end
        payload["thread_lane"] = lane
        if haskey(postdecision_return_quality, job.origin_id)
            payload["return_quality"] = postdecision_return_quality[job.origin_id]
        end
        _atomic_toml(destination, payload)
        return nothing
    end
    _run_threaded_lanes!(jobs, "postdecision", run_one)
    return output.postdecision
end

function run_smoke()
    config, _ = validate_readiness(; require_sources = false)
    jobs = build_synthetic_smoke_instances(THREAD_COUNT)
    mktempdir() do root
        run_one = function(job, lane)
            payload, logs = run_algorithm_suite(
                job.instance;
                origin_id = job.origin_id,
                library_id = job.library_id,
                schedule_id = job.schedule_id,
                config,
            )
            audit = audit_instance_result(job.instance, payload)
            audit["passed"] === true || error("synthetic smoke exact audit failed")
            payload["thread_lane"] = lane
            path = joinpath(root, "$(job.origin_id).toml")
            _atomic_toml(path, payload)
            TOML.parsefile(path)["algorithm_terminal_row_count"] == 7 ||
                error("synthetic smoke serialization failed")
            haskey(logs, "jump_highs_tagged_cover") || error("synthetic smoke lost HiGHS log")
        end
        _run_threaded_lanes!(jobs, "smoke", run_one)
        count(name -> endswith(name, ".toml"), readdir(root)) == THREAD_COUNT ||
            error("threaded smoke did not produce one record per lane")
    end
    println("financial panel v1 threaded smoke passed: lanes=8, algorithms_per_lane=7")
    return true
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: run_financial_strategy_library_panel_v1.jl --check|--smoke|--prepare-only|--solve-only|--postdecision-only|--run",
    )
    mode = only(args)
    if mode == "--check"
        config, amendment = validate_readiness()
        experiment_id = config["experiment_id"]
        amendment_id = amendment["amendment_id"]
        println(
            "financial panel v1 runner ready: experiment=$experiment_id, " *
            "amendment=$amendment_id, threads=$(Threads.nthreads())",
        )
        return true
    end
    mode == "--smoke" && return run_smoke()
    mode == "--prepare-only" && return prepare_instances()
    mode == "--solve-only" && return run_structural_phase()
    mode == "--postdecision-only" && return run_postdecision_phase()
    if mode == "--run"
        prepare_instances()
        run_structural_phase()
        Base.include(Main, joinpath(@__DIR__, "audit_financial_strategy_library_panel_v1.jl"))
        Main.AuditFinancialStrategyLibraryPanelV1.audit_structural_results()
        run_postdecision_phase()
        return Main.AuditFinancialStrategyLibraryPanelV1.audit_all_results()
    end
    error("unknown mode: $mode")
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    RunFinancialStrategyLibraryPanelV1.main()
end
