module RunFinancialStrategyLibraryPanelV1

using Dates
using LinearAlgebra
using SHA: sha256
using StrategyInnovation
using TOML

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV1.jl"))
using .FinancialStrategyLibraryPanelV1

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_021.jl"))
using .LockFinancialStrategyLibraryPanelV1Execution021: verify_execution_lock_021

export main,
       prepare_instances,
       run_post_audit_analysis,
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
const HEAVY_CONCURRENCY = 2
const ALGORITHM_CHECKPOINT_SCHEMA =
    "financial-strategy-library-panel-algorithm-checkpoint-v1"
const LOCK_005_AGGREGATE =
    "74f8e021f47b53ab4b23718224a8d9879bf95fb30b50f3f547b9841b8ce42d83"
const LOCK_010_AGGREGATE =
    "a5a1b53a16f5a238c92b1db04b6d073ee8057f12403c4e5a1b00f19fa59586ae"
const LOCK_011_AGGREGATE =
    "59cb6795ad35986bdc5c102da900147efad952dd557b94eaba107ead85393e9f"
const LOCK_012_AGGREGATE =
    "cf364daa5f00991819c4ac514cfe6b7416690f154ce83bfd7734c01143d8244e"
const LOCK_013_AGGREGATE =
    "a1c6393ea636c87c8f7106b97b2ac37b8670d7d2957bddd1b3ff7bce8ae3fe40"
const LOCK_014_AGGREGATE =
    "993b6af47f6e027a273bb8b3fb5d102b7e9708f696719b6b7a3b575e46edba90"
const LOCK_015_AGGREGATE =
    "49c256ff1e61ef513ab656586c8b4e89c1e891959da21a7407135fe5810690de"
const LOCK_016_AGGREGATE =
    "afe87492ee4fd8b368f9052bddec85c43743a005575f26fb65146fffce33532c"
const LOCK_017_AGGREGATE =
    "9eda494c80aaf31e1fdfc0adaa4bbdb7384e0e96288da224b041175c59fc4401"
const LOCK_018_AGGREGATE =
    "e1489a49bd9b9a9a49c94f5ad145919133b88fe26622a8a293becd0fd2f9820b"
const LOCK_019_AGGREGATE =
    "bd5b20ff313fc2d8ae1b60387c11c1a00fdcdc432d0ea1fd9f9174505c09298e"
const LOCK_020_AGGREGATE =
    "2f1322c99baeca02f78daf56d210efb64110b54ad4f517a40cb2efb5e581f74c"
const LOCK_013_POSTDECISION_AGGREGATE =
    "3214c2ee9fa7bee99089b5017b5ec8d5b1bc26b2b0cee174921ae2fd958ff9a1"
const LOCK_015_POSTDECISION_DIRECTORY_AGGREGATE =
    "f63bb273afc4d6ed69fb12a2f7f35a84f8eb45822f1cce59dd06db90af0fcacc"

_utc_now() = Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")
_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

function _toml_directory_aggregate(directory)
    isdir(directory) || return bytes2hex(sha256(codeunits("")))
    entries = Dict{String,String}()
    for (root, _, files) in walkdir(directory), file in files
        endswith(file, ".toml") || continue
        path = joinpath(root, file)
        entries[relpath(path, directory)] = _sha256_file(path)
    end
    text = join(
        ("$path\0$(entries[path])\n" for path in sort!(collect(keys(entries)))),
    )
    return bytes2hex(sha256(codeunits(text)))
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
        checkpoints = joinpath(local_results, "checkpoints"),
        solver_logs = joinpath(local_results, "solver_logs"),
        postdecision = joinpath(local_results, "postdecision"),
        postdecision_scan_cache = joinpath(local_data, "prepared_return_panels"),
        analysis = joinpath(local_results, "analysis"),
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
        "schema_version" => "financial-strategy-library-panel-environment-v5",
        "recorded_at_utc" => _utc_now(),
        "git_commit" => commit,
        "dirty_worktree" => !isempty(strip(status)),
        "dirty_worktree_status_sha256" => bytes2hex(sha256(codeunits(status))),
        "julia_version" => string(VERSION),
        "julia_threads" => Threads.nthreads(),
        "blas_threads" => LinearAlgebra.BLAS.get_num_threads(),
        "highs_threads_per_model" => 1,
        "threaded_lane_count" => THREAD_COUNT,
        "maximum_simultaneous_heavy_stages" => HEAVY_CONCURRENCY,
        "execution_lock_aggregate_sha256" => execution_lock_aggregate,
        "active_amendment_id" => "AMENDMENT_021",
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


function _progress_job_label(job)
    hasproperty(job, :stem) && return String(job.stem)
    hasproperty(job, :origin_id) && return String(job.origin_id)
    return string(nameof(typeof(job)))
end


function _active_progress_summary(states; maximum_lanes = 4)
    isempty(states) && return ""
    now = time()
    rows = String[]
    for lane in sort!(collect(keys(states)))[1:min(length(states), maximum_lanes)]
        state = states[lane]
        elapsed = max(0, floor(Int, now - state.started_at))
        stage = state.stage
        algorithm = isnothing(state.algorithm_id) ? "" : "/$(state.algorithm_id)"
        push!(rows, "L$lane:$(state.job)/$stage$algorithm $(elapsed)s")
    end
    length(states) > maximum_lanes && push!(rows, "+$(length(states) - maximum_lanes) lanes")
    return isempty(rows) ? "" : "  " * join(rows, " | ")
end


function _emit_progress(message::AbstractString)
    println(stderr, "[", _utc_now(), "] ", message)
    flush(stderr)
    return nothing
end


function _draw_progress(label, completed, total, states)
    _emit_progress(
        _progress_line(label, completed, total) * _active_progress_summary(states),
    )
    return nothing
end


function _scan_progress_reporter(label::AbstractString)
    started_at = time()
    return function(update)
        completed = update.state == "file-completed" ? update.file_index : update.file_index - 1
        elapsed = round(Int, max(0, time() - started_at))
        _emit_progress(
            _progress_line(label, completed, update.file_count) *
            "  stage=$(update.stage) state=$(update.state) " *
            "file=$(update.file_index)/$(update.file_count) " *
            "rows=$(update.source_rows_scanned) elapsed=$(elapsed)s",
        )
        return nothing
    end
end


function _parallel_scan_progress_reporter(label::AbstractString, file_count::Integer)
    started_at = time()
    progress_lock = ReentrantLock()
    completed_files = Set{Int}()
    return function(update)
        lock(progress_lock) do
            update.state in ("file-completed", "file-reused") &&
                push!(completed_files, update.file_index)
            elapsed = round(Int, max(0, time() - started_at))
            _emit_progress(
                _progress_line(label, length(completed_files), file_count) *
                "  state=$(update.state) file=$(update.file_index)/$(update.file_count) " *
                "file_rows=$(update.source_rows_scanned) elapsed=$(elapsed)s",
            )
        end
        return nothing
    end
end

function _run_threaded_lanes!(
    jobs,
    label,
    run_one;
    lanes = THREAD_COUNT,
    allow_failures = false,
    heartbeat_seconds::Real = 30,
)
    lanes <= Threads.nthreads() || error(
        "$label requires at least $lanes Julia threads; found $(Threads.nthreads())",
    )
    isfinite(heartbeat_seconds) && heartbeat_seconds > 0 || error(
        "$label heartbeat_seconds must be finite and positive",
    )
    assignments = [Any[] for _ in 1:lanes]
    for (index, job) in enumerate(jobs)
        push!(assignments[mod1(index, lanes)], job)
    end
    events = Channel{NamedTuple}(max(32 * length(jobs), 64))
    tasks = Task[]
    for lane in 1:lanes
        push!(tasks, Threads.@spawn begin
            for job in assignments[lane]
                report = function(update)
                    put!(events, (
                        kind = :progress,
                        lane,
                        job,
                        update,
                    ))
                    return nothing
                end
                try
                    if applicable(run_one, job, lane, report)
                        run_one(job, lane, report)
                    else
                        run_one(job, lane)
                    end
                    put!(events, (
                        kind = :terminal,
                        passed = true,
                        lane,
                        job,
                        exception = nothing,
                    ))
                catch exception
                    put!(events, (
                        kind = :terminal,
                        passed = false,
                        lane,
                        job,
                        exception,
                    ))
                end
            end
        end)
    end
    stop_heartbeat = Threads.Atomic{Bool}(false)
    heartbeat = @async begin
        while !stop_heartbeat[]
            sleep(heartbeat_seconds)
            stop_heartbeat[] || put!(events, (kind = :heartbeat,))
        end
    end
    completed = 0
    failures = NamedTuple[]
    states = Dict{Int,NamedTuple}()
    _draw_progress(label, completed, length(jobs), states)
    while completed < length(jobs)
        event = take!(events)
        if event.kind == :heartbeat
            _draw_progress(label, completed, length(jobs), states)
            continue
        elseif event.kind == :progress
            update = event.update
            if update.state in ("completed", "resumed") && update.stage == "algorithm"
                states[event.lane] = (
                    job = _progress_job_label(event.job),
                    stage = update.state,
                    algorithm_id = update.algorithm_id,
                    started_at = time(),
                )
            else
                states[event.lane] = (
                    job = _progress_job_label(event.job),
                    stage = update.stage,
                    algorithm_id = update.algorithm_id,
                    started_at = time(),
                )
            end
            _draw_progress(label, completed, length(jobs), states)
            continue
        end
        event.passed || push!(failures, event)
        completed += 1
        delete!(states, event.lane)
        _draw_progress(label, completed, length(jobs), states)
    end
    stop_heartbeat[] = true
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


function _algorithm_checkpoint_path(output, stem, algorithm_id)
    return joinpath(output.checkpoints, stem, "$(algorithm_id).toml")
end


function _checkpoint_selection(instance, record)
    record["candidate_returned"] === true || return nothing
    selection = record["selection"]
    indices = Int.(selection["selected_strategy_indices"])
    length(indices) == length(unique(indices)) || error(
        "checkpoint selection repeats a strategy index",
    )
    all(index -> index in eachindex(instance.strategy_ids), indices) || error(
        "checkpoint selection contains an out-of-range strategy index",
    )
    selected = falses(length(instance.strategy_ids))
    selected[indices] .= true
    check = check_journal_compression_solution(instance, selected)
    check.exact_feasible === true || error("checkpoint selection is not exactly feasible")
    string(numerator(check.exact_burden), "//", denominator(check.exact_burden)) ==
    selection["exact_burden"] || error("checkpoint exact burden differs")
    return selected
end


function _known_mip_projection_failure(record)
    return get(record, "algorithm_id", "") == "jump_highs_tagged_cover" &&
           get(record, "status", "") == "ERROR" &&
           get(record, "candidate_returned", true) === false &&
           get(record, "failure_type", "") == "ArgumentError" &&
           get(record, "failure_message", "") ==
           "ArgumentError: the supplied warm start is not feasible after exact preprocessing projection"
end


function _known_lock019_checkpoint_namespace_failure(payload)
    return get(payload, "schema_version", "") ==
           "financial-strategy-library-panel-instance-failure-v1" &&
           get(payload, "failure_type", "") == "ErrorException" &&
           startswith(
               get(payload, "failure_message", ""),
               "corrective checkpoint is not bound to Lock 018:",
           )
end


function _corrective_resume_algorithms(
    instance,
    saved;
    precomputed_instance_sha256 = nothing,
)
    algorithms = Dict{String,Any}(
        String(record["algorithm_id"]) => record for record in saved["algorithms"]
    )
    mip = get(algorithms, "jump_highs_tagged_cover", nothing)
    isnothing(mip) && return nothing
    _known_mip_projection_failure(mip) || return nothing
    audit_instance_result(
        instance,
        saved;
        precomputed_instance_sha256,
    )["passed"] === true || error(
        "predecessor result fails the exact resume audit",
    )
    resumed = Dict{String,Any}()
    for algorithm_id in FinancialStrategyLibraryPanelV1.ALGORITHM_IDS
        algorithm_id == "jump_highs_tagged_cover" && continue
        record = algorithms[algorithm_id]
        resumed[algorithm_id] = (
            record = record,
            selection = _checkpoint_selection(instance, record),
        )
    end
    length(resumed) == 6 || error("corrective MIP resume did not preserve six algorithms")
    return resumed
end


function _corrective_resume_algorithms_from_checkpoints(
    output,
    stem,
    instance;
    precomputed_instance_sha256 = nothing,
)
    instance_sha256 = isnothing(precomputed_instance_sha256) ?
                      journal_compression_instance_sha256(instance) :
                      String(precomputed_instance_sha256)
    saved = Dict{String,Any}()
    mip_requires_rerun = false
    for algorithm_id in FinancialStrategyLibraryPanelV1.ALGORITHM_IDS
        path = _algorithm_checkpoint_path(output, stem, algorithm_id)
        isfile(path) || error("corrective checkpoint is absent: $path")
        payload = TOML.parsefile(path)
        payload["schema_version"] == ALGORITHM_CHECKPOINT_SCHEMA || error(
            "corrective checkpoint has an unrecognized schema: $path",
        )
        payload["instance_sha256"] == instance_sha256 ||
            error("corrective checkpoint instance hash differs: $path")
        payload["algorithm_id"] == algorithm_id ||
            error("corrective checkpoint algorithm differs: $path")
        payload["terminal"] === true || error("corrective checkpoint is nonterminal: $path")
        record = payload["record"]
        record["algorithm_id"] == algorithm_id ||
            error("corrective checkpoint record algorithm differs: $path")
        record["terminal"] === true || error("corrective checkpoint record is nonterminal: $path")
        for log_entry in get(payload, "solver_logs", Any[])
            log_path = joinpath(output.local_results, String(log_entry["path"]))
            isfile(log_path) || error("corrective checkpoint solver log is absent: $log_path")
            _sha256_file(log_path) == log_entry["sha256"] ||
                error("corrective checkpoint solver log hash differs: $log_path")
        end
        if algorithm_id == "jump_highs_tagged_cover"
            checkpoint_lock = String(payload["execution_lock_aggregate_sha256"])
            if checkpoint_lock == LOCK_005_AGGREGATE
                _known_mip_projection_failure(record) || error(
                    "Lock 005 corrective checkpoint lacks the registered MIP failure",
                )
                mip_requires_rerun = true
                continue
            end
            checkpoint_lock == LOCK_020_AGGREGATE || error(
                "corrected MIP checkpoint belongs to an undeclared execution lock: $path",
            )
            get(payload, "corrective_execution_amendment_id", "") == "AMENDMENT_020" ||
                error("Lock 020 corrected MIP checkpoint lacks amendment provenance")
            get(record, "candidate_returned", false) === true ||
                error("Lock 020 corrected MIP checkpoint lacks a candidate")
        else
            payload["execution_lock_aggregate_sha256"] == LOCK_005_AGGREGATE || error(
                "unaffected corrective checkpoint is not bound to Lock 005: $path",
            )
        end
        saved[algorithm_id] = (
            record = record,
            selection = _checkpoint_selection(instance, record),
        )
    end
    expected_saved = mip_requires_rerun ? 6 : 7
    length(saved) == expected_saved || error(
        mip_requires_rerun ?
        "corrective checkpoint preflight did not preserve the six unaffected algorithms" :
        "corrective checkpoint preflight did not recover all seven algorithms",
    )
    return saved
end


function _load_algorithm_checkpoints(
    output,
    stem,
    instance,
    execution_lock_aggregate,
    ; precomputed_instance_sha256 = nothing,
)
    instance_sha256 = isnothing(precomputed_instance_sha256) ?
                      journal_compression_instance_sha256(instance) :
                      String(precomputed_instance_sha256)
    saved = Dict{String,Any}()
    for algorithm_id in FinancialStrategyLibraryPanelV1.ALGORITHM_IDS
        path = _algorithm_checkpoint_path(output, stem, algorithm_id)
        isfile(path) || continue
        payload = TOML.parsefile(path)
        payload["schema_version"] == ALGORITHM_CHECKPOINT_SCHEMA || error(
            "unrecognized algorithm checkpoint schema: $path",
        )
        payload["execution_lock_aggregate_sha256"] == execution_lock_aggregate || error(
            "algorithm checkpoint belongs to another execution lock: $path",
        )
        payload["instance_sha256"] == instance_sha256 || error(
            "algorithm checkpoint instance hash differs: $path",
        )
        payload["algorithm_id"] == algorithm_id || error(
            "algorithm checkpoint identifier differs: $path",
        )
        payload["terminal"] === true || error("nonterminal algorithm checkpoint: $path")
        record = payload["record"]
        record["algorithm_id"] == algorithm_id || error(
            "checkpoint record algorithm differs: $path",
        )
        record["terminal"] === true || error("checkpoint record is nonterminal: $path")
        for log_entry in get(payload, "solver_logs", Any[])
            log_path = joinpath(output.local_results, String(log_entry["path"]))
            isfile(log_path) || error("checkpoint solver log is absent: $log_path")
            _sha256_file(log_path) == log_entry["sha256"] || error(
                "checkpoint solver log hash differs: $log_path",
            )
        end
        saved[algorithm_id] = (
            record = record,
            selection = _checkpoint_selection(instance, record),
        )
    end
    return saved
end


function _write_algorithm_checkpoint(
    output,
    stem,
    instance,
    execution_lock_aggregate,
    algorithm_id,
    record,
    selection,
    logs,
    ; replace_known_mip_projection_failure::Bool = false,
    precomputed_instance_sha256 = nothing,
)
    isnothing(selection) || _checkpoint_selection(instance, record) == selection || error(
        "algorithm checkpoint callback selection differs from its record",
    )
    path = _algorithm_checkpoint_path(output, stem, algorithm_id)
    instance_sha256 = isnothing(precomputed_instance_sha256) ?
                      journal_compression_instance_sha256(instance) :
                      String(precomputed_instance_sha256)
    replace = false
    if isfile(path)
        replace_known_mip_projection_failure || error(
            "refusing to overwrite terminal algorithm checkpoint: $path",
        )
        predecessor = TOML.parsefile(path)
        predecessor["schema_version"] == ALGORITHM_CHECKPOINT_SCHEMA || error(
            "corrective checkpoint has an unrecognized predecessor schema: $path",
        )
        predecessor["execution_lock_aggregate_sha256"] == LOCK_005_AGGREGATE || error(
            "corrective checkpoint is not bound to the declared Lock 005 namespace: $path",
        )
        predecessor["instance_sha256"] == instance_sha256 ||
            error("corrective checkpoint instance hash differs: $path")
        _known_mip_projection_failure(predecessor["record"]) || error(
            "corrective checkpoint does not contain the registered MIP projection failure",
        )
        algorithm_id == "jump_highs_tagged_cover" || error(
            "corrective checkpoint replacement is restricted to HiGHS",
        )
        replace = true
    end
    log_rows = Dict{String,Any}[]
    for (log_id, log) in sort!(collect(logs); by = first)
        log_path = joinpath(output.solver_logs, stem * "__$(log_id).log")
        _atomic_write(log_path, log; replace = isfile(log_path))
        push!(log_rows, Dict(
            "algorithm_id" => log_id,
            "path" => relpath(log_path, output.local_results),
            "sha256" => _sha256_file(log_path),
        ))
    end
    payload = Dict{String,Any}(
        "schema_version" => ALGORITHM_CHECKPOINT_SCHEMA,
        "experiment_id" => "financial-strategy-library-panel-v1",
        "execution_lock_aggregate_sha256" => execution_lock_aggregate,
        "instance_sha256" => instance_sha256,
        "algorithm_id" => algorithm_id,
        "terminal" => true,
        "created_at_utc" => _utc_now(),
        "record" => record,
        "solver_logs" => log_rows,
        "licensed_rows_included" => false,
    )
    if replace
        payload["corrected_predecessor_execution_lock_aggregate_sha256"] =
            LOCK_005_AGGREGATE
        payload["corrective_execution_amendment_id"] = "AMENDMENT_021"
    end
    _atomic_toml(path, payload; replace)
    return path
end

function _registry_seed(origin_id, library_id)
    row = only(filter(
        item -> item.origin_id == origin_id && item.library_id == library_id,
        FinancialStrategyLibraryPanelV1.FinancialStrategyLibraryPanelV1Registries.seed_rows(),
    ))
    return string(row.multistart_seed)
end

function validate_readiness(; require_sources::Bool = true)
    verify_execution_lock_021()
    VERSION == v"1.12.6" || error("financial panel v1 requires Julia 1.12.6")
    Threads.nthreads() == THREAD_COUNT || error(
        "financial panel v1 requires --threads=$THREAD_COUNT; found $(Threads.nthreads())",
    )
    LinearAlgebra.BLAS.set_num_threads(1)
    LinearAlgebra.BLAS.get_num_threads() == 1 || error("BLAS must use one thread")
    config, amendment = load_panel_config()
    amendment["threading"]["julia_threads"] == THREAD_COUNT ||
        error("execution amendment thread count changed")
    amendment["threading"]["maximum_simultaneous_heavy_stages"] == HEAVY_CONCURRENCY ||
        error("execution amendment heavy-stage concurrency changed")
    amendment["amendment_id"] == "AMENDMENT_021" ||
        error("active execution amendment changed")
    amendment["audit_key_shape"]["expected_key_count"] == 180 ||
        error("audit key count changed")
    amendment["audit_parallelism"]["worker_count"] == THREAD_COUNT ||
        error("audit worker count changed")
    amendment["progress"]["output_records"] ==
    "durable newline-delimited stderr records" ||
        error("progress output contract changed")
    amendment["parquet"]["compression"] == "SNAPPY" ||
        error("Parquet compression contract changed")
    amendment["analysis_materialization"]["worker_count"] == THREAD_COUNT ||
        error("analysis worker count changed")
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
    execution_lock_aggregate = verify_execution_lock_021()
    if isfile(paths.environment)
        environment = TOML.parsefile(paths.environment)
        if get(environment, "execution_lock_aggregate_sha256", "") == execution_lock_aggregate
            environment["julia_version"] == string(VERSION) || error("saved environment Julia version differs")
            environment["julia_threads"] == THREAD_COUNT || error("saved environment thread count differs")
            return environment
        end
        predecessor_lock_matches = get(
            environment,
            "execution_lock_aggregate_sha256",
            "",
        ) in (
            LOCK_010_AGGREGATE,
            LOCK_011_AGGREGATE,
            LOCK_012_AGGREGATE,
            LOCK_013_AGGREGATE,
            LOCK_014_AGGREGATE,
            LOCK_015_AGGREGATE,
            LOCK_016_AGGREGATE,
            LOCK_017_AGGREGATE,
            LOCK_018_AGGREGATE,
            LOCK_019_AGGREGATE,
            LOCK_020_AGGREGATE,
        )
        instance_count = isdir(paths.instances) ?
                         count(name -> endswith(name, ".toml"), readdir(paths.instances)) : 0
        origin_metadata_count = isdir(paths.origin_metadata) ?
                                count(name -> endswith(name, ".toml"), readdir(paths.origin_metadata)) : 0
        structural_files = isdir(paths.structural) ?
                           filter(name -> endswith(name, ".toml"), readdir(paths.structural)) : String[]
        checkpoint_count = isdir(paths.checkpoints) ? sum(
            count(name -> endswith(name, ".toml"), files) for
            (_, _, files) in walkdir(paths.checkpoints)
        ) : 0
        solver_log_count = isdir(paths.solver_logs) ? sum(
            length(files) for (_, _, files) in walkdir(paths.solver_logs)
        ) : 0
        postdecision_files = isdir(paths.postdecision) ?
                             filter(name -> endswith(name, ".toml"), readdir(paths.postdecision)) :
                             String[]
        postdecision_aggregate = _toml_directory_aggregate(paths.postdecision)
        postdecision_recoverable = isempty(postdecision_files) ||
                                   (
            length(postdecision_files) == 108 &&
            postdecision_aggregate == LOCK_013_POSTDECISION_AGGREGATE
        ) ||
                                   (
            length(postdecision_files) == 180 &&
            postdecision_aggregate == LOCK_015_POSTDECISION_DIRECTORY_AGGREGATE
        )
        successor_recovery = predecessor_lock_matches &&
                             isfile(paths.preparation_manifest) &&
                             instance_count == 108 &&
                             origin_metadata_count == 12 &&
                             length(structural_files) == 180 &&
                             all(
            name -> get(
                TOML.parsefile(joinpath(paths.structural, name)),
                "terminal",
                false,
            ) === true,
            structural_files,
        ) &&
                             postdecision_recoverable &&
                             checkpoint_count == 756 &&
                             solver_log_count == 14
        successor_recovery || error(
            "saved environment belongs to an execution lock outside the declared successor recovery",
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
    _emit_progress("prepare: constructing point-in-time universes")
    scan_progress = _scan_progress_reporter("prepare-scan")
    universes = construct_origin_universes(
        config,
        raw_paths;
        progress_callback = scan_progress,
    )
    _emit_progress("prepare: extracting origin-scoped structural return series")
    return_quality = Dict{String,Any}()
    series_by_origin = extract_origin_series(
        config,
        raw_paths.daily_files,
        universes;
        phase = :structural,
        diagnostics = return_quality,
        progress_callback = scan_progress,
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


function _ensure_preparation_for_run(
    output;
    prepare_callback = prepare_instances,
    validate_callback = _validate_preparation,
)
    if isfile(output.preparation_manifest)
        _emit_progress("prepare: validating and reusing completed preparation manifest")
        validate_callback(output)
        _emit_progress("prepare: manifest and all registered artifact hashes valid; reconstruction skipped")
        return :reused
    end
    _emit_progress("prepare: no manifest found; running registered preparation")
    prepare_callback()
    validate_callback(output)
    return :created
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
    environment = _write_environment(output)
    execution_lock_aggregate = String(environment["execution_lock_aggregate_sha256"])
    heavy_gate = Base.Semaphore(HEAVY_CONCURRENCY)
    heavy_executor = function(task)
        Base.acquire(heavy_gate)
        try
            return task()
        finally
            Base.release(heavy_gate)
        end
    end
    jobs = [(
        origin_id,
        library_id,
        schedule_id,
        stem = _instance_stem(origin_id, library_id, schedule_id),
    ) for (origin_id, library_id, schedule_id) in registered_job_keys()]
    run_one = function(job, lane, report)
        instance_path = joinpath(output.instances, job.stem * ".toml")
        preparation_failure_path = joinpath(output.preparation_failures, job.stem * ".toml")
        result_path = joinpath(output.structural, job.stem * ".toml")
        corrective_resume = nothing
        instance_file_sha256 = nothing
        if isfile(result_path)
            saved = TOML.parsefile(result_path)
            saved["terminal"] === true || error("nonterminal saved result: $(job.stem)")
            if saved["schema_version"] == "financial-strategy-library-panel-instance-result-v1"
                instance = _read_instance(instance_path)
                instance_file_sha256 = _sha256_file(instance_path)
                audit_instance_result(
                    instance,
                    saved;
                    precomputed_instance_sha256 = instance_file_sha256,
                )["passed"] === true ||
                    error("saved result fails resume audit: $(job.stem)")
                corrective_resume = _corrective_resume_algorithms(
                    instance,
                    saved;
                    precomputed_instance_sha256 = instance_file_sha256,
                )
                if !isnothing(corrective_resume)
                    corrective_resume = _corrective_resume_algorithms_from_checkpoints(
                        output,
                        job.stem,
                        instance;
                        precomputed_instance_sha256 = instance_file_sha256,
                    )
                end
            elseif _known_lock019_checkpoint_namespace_failure(saved)
                instance = _read_instance(instance_path)
                instance_file_sha256 = _sha256_file(instance_path)
                corrective_resume = _corrective_resume_algorithms_from_checkpoints(
                    output,
                    job.stem,
                    instance;
                    precomputed_instance_sha256 = instance_file_sha256,
                )
            elseif saved["schema_version"] !=
                   "financial-strategy-library-panel-preparation-failure-result-v1"
                error("unrecognized saved result schema: $(job.stem)")
            end
            isnothing(corrective_resume) || report((
                state = "running",
                stage = "corrective-mip-resume",
                algorithm_id = "jump_highs_tagged_cover",
            ))
            isnothing(corrective_resume) && return nothing
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
        isnothing(instance_file_sha256) &&
            (instance_file_sha256 = _sha256_file(instance_path))
        resume_algorithms = isnothing(corrective_resume) ?
            _load_algorithm_checkpoints(
                output,
                job.stem,
                instance,
                execution_lock_aggregate,
            ) : corrective_resume
        checkpoint_callback = function(
            algorithm_id,
            record,
            selection,
            algorithm_logs,
        )
            _write_algorithm_checkpoint(
                output,
                job.stem,
                instance,
                execution_lock_aggregate,
                algorithm_id,
                record,
                selection,
                algorithm_logs,
                ; replace_known_mip_projection_failure = !isnothing(corrective_resume),
                precomputed_instance_sha256 = instance_file_sha256,
            )
            return nothing
        end
        payload = nothing
        logs = Dict{String,String}()
        try
            payload, logs = run_algorithm_suite(
                instance;
                origin_id = job.origin_id,
                library_id = job.library_id,
                schedule_id = job.schedule_id,
                config,
                progress_callback = report,
                checkpoint_callback,
                resume_algorithms,
                heavy_executor,
                precomputed_instance_sha256 = instance_file_sha256,
            )
            payload["thread_lane"] = lane
            payload["multistart_seed"] = _registry_seed(job.origin_id, job.library_id)
            if !isnothing(corrective_resume)
                payload["corrective_execution_amendment_id"] = "AMENDMENT_021"
                payload["corrected_algorithm_ids"] = ["jump_highs_tagged_cover"]
                payload["preserved_algorithm_ids"] = [
                    algorithm_id for algorithm_id in
                    FinancialStrategyLibraryPanelV1.ALGORITHM_IDS if
                    algorithm_id != "jump_highs_tagged_cover"
                ]
            end
        catch exception
            payload = _failure_payload(job, instance, exception)
            payload["thread_lane"] = lane
        end
        for (algorithm_id, log) in logs
            log_path = joinpath(output.solver_logs, job.stem * "__$(algorithm_id).log")
            isfile(log_path) || _atomic_write(log_path, log)
            payload["solver_log_sha256"] = _sha256_file(log_path)
            payload["solver_log_path"] = relpath(log_path, output.local_results)
        end
        for algorithm_id in FinancialStrategyLibraryPanelV1.ALGORITHM_IDS
            log_path = joinpath(output.solver_logs, job.stem * "__$(algorithm_id).log")
            isfile(log_path) || continue
            payload["solver_log_sha256"] = _sha256_file(log_path)
            payload["solver_log_path"] = relpath(log_path, output.local_results)
        end
        _atomic_toml(result_path, payload; replace = !isnothing(corrective_resume))
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
    execution_lock_aggregate = verify_execution_lock_021()
    _write_environment(output)
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
    jobs = [(
        origin_id,
        library_id,
        schedule_id,
        stem = _instance_stem(origin_id, library_id, schedule_id),
    ) for (origin_id, library_id, schedule_id) in registered_job_keys()]
    postdecision_current = function(path)
        isfile(path) || return false
        payload = TOML.parsefile(path)
        return get(payload, "corrective_execution_amendment_id", "") == "AMENDMENT_021"
    end
    pending_jobs = [
        job for job in jobs if !postdecision_current(
            joinpath(output.postdecision, job.stem * ".toml"),
        )
    ]
    if isempty(pending_jobs)
        _emit_progress("postdecision: all 180 terminal records validated for resume; scan skipped")
        return output.postdecision
    end
    raw_paths = source_paths(config, _source_root(config))
    postdecision_return_quality = Dict{String,Any}()
    _emit_progress(
        "postdecision: extracting origin-scoped series to three resumable Snappy Parquet partitions",
    )
    series_by_origin = extract_origin_series_parquet(
        config,
        raw_paths.daily_files,
        [origins[origin_id] for origin_id in sort!(collect(keys(thresholds)))];
        phase = :postdecision,
        cache_root = output.postdecision_scan_cache,
        execution_lock_aggregate,
        compatible_execution_lock_aggregates =
            (
                LOCK_011_AGGREGATE,
                LOCK_012_AGGREGATE,
                LOCK_013_AGGREGATE,
                LOCK_014_AGGREGATE,
                LOCK_015_AGGREGATE,
                LOCK_016_AGGREGATE,
                LOCK_017_AGGREGATE,
                LOCK_018_AGGREGATE,
                execution_lock_aggregate,
            ),
        diagnostics = postdecision_return_quality,
        progress_callback = _parallel_scan_progress_reporter(
            "post-scan",
            length(raw_paths.daily_files),
        ),
    )
    unavailable_postdecision_origins =
        validate_postdecision_return_quality(postdecision_return_quality, config)
    _emit_progress(
        "postdecision: return-quality merge complete; " *
        "$(length(unavailable_postdecision_origins)) origin retained as unavailable",
    )
    pending_success_origins = sort!(unique(String[
        job.origin_id for job in pending_jobs if
        haskey(thresholds, job.origin_id) &&
        !(job.origin_id in unavailable_postdecision_origins)
    ]))
    profile_status = Dict{String,Any}()
    profile_status_lock = ReentrantLock()
    profile_jobs = [(origin_id, stem = origin_id) for origin_id in pending_success_origins]
    profile_check = function(profile_job, _lane, report)
        origin_id = profile_job.origin_id
        instances = Any[]
        seen_libraries = Set{String}()
        for job in jobs
            job.origin_id == origin_id || continue
            job.library_id in seen_libraries && continue
            instance_path = joinpath(output.instances, job.stem * ".toml")
            isfile(instance_path) || continue
            push!(seen_libraries, job.library_id)
            push!(instances, _read_instance(instance_path))
        end
        report((
            state = "running",
            stage = "profile-adequacy",
            algorithm_id = nothing,
        ))
        status = postdecision_profile_adequacy(
            instances,
            origins[origin_id],
            series_by_origin[origin_id],
            thresholds[origin_id],
            config,
            amendment,
        )
        lock(profile_status_lock) do
            profile_status[origin_id] = status
        end
        return nothing
    end
    _run_threaded_lanes!(profile_jobs, "profile-check", profile_check)
    profile_unavailable_origins = Set(String[
        origin_id for origin_id in pending_success_origins if
        profile_status[origin_id].available === false
    ])
    profile_policy = amendment["postdecision_profile_failure_policy"]
    length(profile_unavailable_origins) == Int(profile_policy["affected_origin_count"]) ||
        error("Amendment 014 postdecision-profile affected-origin count differs")
    profile_origin_hash = bytes2hex(sha256(codeunits(join(
        sort!(collect(profile_unavailable_origins)),
        '\n',
    ))))
    profile_origin_hash == String(profile_policy["affected_origin_id_set_sha256"]) ||
        error("Amendment 014 postdecision-profile affected-origin set differs")
    _emit_progress(
        "postdecision: profile-adequacy check complete; " *
        "$(length(profile_unavailable_origins)) origins retained as unavailable",
    )
    run_one = function(job, lane)
        destination = joinpath(output.postdecision, job.stem * ".toml")
        result_payload = TOML.parsefile(joinpath(output.structural, job.stem * ".toml"))
        payload = if job.origin_id in unavailable_postdecision_origins
            result_payload["schema_version"] ==
            "financial-strategy-library-panel-instance-result-v1" || error(
                "Amendment 013 affected origin lacks a successful structural result",
            )
            Dict{String,Any}(
                "schema_version" =>
                    "financial-strategy-library-panel-postdecision-data-unavailable-v1",
                "origin_id" => job.origin_id,
                "library_id" => job.library_id,
                "schedule_id" => job.schedule_id,
                "structural_instance_sha256" => result_payload["instance_sha256"],
                "structural_result_terminal_and_audited_before_open" => true,
                "available" => false,
                "reason" => "terminal CRSP DP row leaves the origin postdecision return incomplete",
                "postdecision_opened" => true,
                "origin_wide_unavailability" => true,
                "return_imputed" => false,
                "zero_return_substituted" => false,
                "unavailable_algorithm_row_count" => length(FinancialStrategyLibraryPanelV1.ALGORITHM_IDS),
                "licensed_rows_included" => false,
            )
        elseif job.origin_id in profile_unavailable_origins
            result_payload["schema_version"] ==
            "financial-strategy-library-panel-instance-result-v1" || error(
                "Amendment 014 affected origin lacks a successful structural result",
            )
            status = profile_status[job.origin_id]
            Dict{String,Any}(
                "schema_version" =>
                    "financial-strategy-library-panel-postdecision-profile-unavailable-v1",
                "origin_id" => job.origin_id,
                "library_id" => job.library_id,
                "schedule_id" => job.schedule_id,
                "structural_instance_sha256" => result_payload["instance_sha256"],
                "structural_result_terminal_and_audited_before_open" => true,
                "available" => false,
                "reason" => status.reason,
                "postdecision_opened" => true,
                "origin_wide_unavailability" => true,
                "minimum_observations_per_belief" => status.minimum_observations_per_belief,
                "checked_distinct_security_count" => status.checked_security_count,
                "profile_imputed" => false,
                "belief_states_pooled" => false,
                "minimum_relaxed" => false,
                "postdecision_score_fabricated" => false,
                "unavailable_algorithm_row_count" => length(FinancialStrategyLibraryPanelV1.ALGORITHM_IDS),
                "licensed_rows_included" => false,
            )
        elseif result_payload["schema_version"] ==
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
        payload["corrective_execution_amendment_id"] = "AMENDMENT_021"
        if haskey(postdecision_return_quality, job.origin_id)
            payload["return_quality"] = postdecision_return_quality[job.origin_id]
        end
        _atomic_toml(destination, payload; replace = isfile(destination))
        return nothing
    end
    _run_threaded_lanes!(pending_jobs, "postdecision", run_one)
    return output.postdecision
end

function run_smoke()
    config, _ = validate_readiness(; require_sources = false)
    execution_lock_aggregate = verify_execution_lock_021()
    jobs = build_synthetic_smoke_instances(THREAD_COUNT)
    mktempdir() do root
        output = (
            local_results = root,
            checkpoints = joinpath(root, "checkpoints"),
            solver_logs = joinpath(root, "solver_logs"),
        )
        heavy_gate = Base.Semaphore(HEAVY_CONCURRENCY)
        heavy_executor = function(task)
            Base.acquire(heavy_gate)
            try
                return task()
            finally
                Base.release(heavy_gate)
            end
        end
        run_one = function(job, lane, report)
            checkpoint_callback = function(
                algorithm_id,
                record,
                selection,
                algorithm_logs,
            )
                _write_algorithm_checkpoint(
                    output,
                    job.origin_id,
                    job.instance,
                    execution_lock_aggregate,
                    algorithm_id,
                    record,
                    selection,
                    algorithm_logs,
                )
            end
            payload, logs = run_algorithm_suite(
                job.instance;
                origin_id = job.origin_id,
                library_id = job.library_id,
                schedule_id = job.schedule_id,
                config,
                progress_callback = report,
                checkpoint_callback,
                heavy_executor,
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
        checkpoint_count = sum(
            count(name -> endswith(name, ".toml"), files) for
            (_, _, files) in walkdir(output.checkpoints)
        )
        checkpoint_count == THREAD_COUNT * length(FinancialStrategyLibraryPanelV1.ALGORITHM_IDS) ||
            error("threaded smoke did not persist every algorithm checkpoint")
    end
    println(
        "financial panel v1 threaded smoke passed: lanes=8, heavy_concurrency=2, " *
        "algorithms_per_lane=7",
    )
    return true
end


function _load_script_module(name::Symbol, filename::AbstractString)
    if !Base.invokelatest(isdefined, Main, name)
        Base.include(Main, joinpath(@__DIR__, filename))
    end
    module_ = Base.invokelatest(getfield, Main, name)
    module_ isa Module || error("financial panel script binding is not a module: $name")
    return module_
end


_load_audit_module() = _load_script_module(
    :AuditFinancialStrategyLibraryPanelV1,
    "audit_financial_strategy_library_panel_v1.jl",
)


function _invoke_latest_binding(module_::Module, name::Symbol, args...; kwargs...)
    Base.invokelatest(isdefined, module_, name) || error("audit module does not define $name")
    callable = Base.invokelatest(getfield, module_, name)
    return Base.invokelatest(callable, args...; kwargs...)
end


_invoke_audit(name::Symbol; kwargs...) =
    _invoke_latest_binding(_load_audit_module(), name; kwargs...)

function run_post_audit_analysis()
    analysis_module = _load_script_module(
        :AnalyzeFinancialStrategyLibraryPanelV1,
        "analyze_financial_strategy_library_panel_v1.jl",
    )
    manifest = _invoke_latest_binding(analysis_module, :run_analysis)
    audit_module = _load_script_module(
        :AuditFinancialStrategyLibraryPanelV1Analysis,
        "audit_financial_strategy_library_panel_v1_analysis.jl",
    )
    audit = _invoke_latest_binding(audit_module, :audit_analysis)
    return (manifest, audit)
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: run_financial_strategy_library_panel_v1.jl --check|--smoke|--prepare-only|--solve-only|--postdecision-only|--analysis-only|--continue-after-structural-audit|--run",
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
    if mode == "--analysis-only"
        _invoke_audit(:audit_all_results)
        return run_post_audit_analysis()
    end
    if mode == "--continue-after-structural-audit"
        _invoke_audit(:audit_structural_results)
        run_postdecision_phase()
        _invoke_audit(:audit_all_results)
        return run_post_audit_analysis()
    end
    if mode == "--run"
        config, _ = validate_readiness()
        _ensure_preparation_for_run(_paths(config))
        run_structural_phase()
        _invoke_audit(:audit_structural_results)
        run_postdecision_phase()
        _invoke_audit(:audit_all_results)
        return run_post_audit_analysis()
    end
    error("unknown mode: $mode")
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    RunFinancialStrategyLibraryPanelV1.main()
end
