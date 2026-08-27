module AlgorithmicCompressionFinalV2

using Dates
using HiGHS
using JuMP
using LinearAlgebra
using SHA: sha256
using StrategyInnovation
using TOML

include(joinpath(@__DIR__, "lock_algorithmic_compression_design_v2.jl"))
using .LockAlgorithmicCompressionDesignV2: verify_design_lock_v2

export main, run_final_benchmark, validate_final_runner_readiness

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "algorithmic_compression_v2.toml",
)
const STUDY_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "algorithmic_compression_v2",
)
const INSTANCE_REGISTRY_PATH = joinpath(STUDY_ROOT, "registry", "INSTANCE_REGISTRY.csv")
const SEED_REGISTRY_PATH = joinpath(STUDY_ROOT, "registry", "SEED_REGISTRY.csv")
const RESULTS_ROOT = joinpath(STUDY_ROOT, "results")
const ENVIRONMENT_PATH = joinpath(RESULTS_ROOT, "environment.toml")
const EXECUTION_LOCK_PATH = joinpath(RESULTS_ROOT, "EXECUTION_START_LOCK.json")
const EXECUTION_START_FAILURE_PATH = joinpath(
    RESULTS_ROOT,
    "EXECUTION_START_FAILURE_001.toml",
)
const RUN_STATUS_PATH = joinpath(RESULTS_ROOT, "final_algorithm_runs.csv")
const WORKER_PATH = joinpath(
    REPOSITORY_ROOT,
    "julia",
    "scripts",
    "run_algorithmic_compression_final_worker_v1.jl",
)
const RUNNER_PATH = @__FILE__
const FINAL_RUN_SCHEMA_VERSION = "algorithmic-compression-final-run-v2"
const FINAL_JOB_SCHEMA_VERSION = "algorithmic-compression-final-job-v1"
const WORKER_COUNT = 8
const MEMORY_LIMIT_BYTES = 1536 * 1024^2
const HEURISTICS = (
    :weighted_greedy,
    :cardinality_greedy,
    :weighted_greedy_reverse_delete,
    :heaviest_safe_first,
    :lightest_safe_first,
    :maximum_immediate_burden_release,
    :minimum_unique_carrier_exposure,
    :declared_source_order,
    :random_order_rechecked_deletion,
    :multistart_random_rechecked_deletion_32,
)
const RUN_COLUMNS = (
    :instance_id,
    :family,
    :mechanism,
    :algorithm_id,
    :preprocessing_variant,
    :applicable,
    :status,
    :candidate_accepted,
    :exact_feasible,
    :exact_burden,
    :wall_clock_ns,
    :peak_memory_bytes,
    :time_limit_seconds,
    :record_path,
    :record_sha256,
    :failure_code,
    :worker_lane,
    :lane_position,
    :global_schedule_position,
    :launch_wave,
)


_require(condition::Bool, message::AbstractString) =
    condition ? true : error(message)

_relative(path::AbstractString) = relpath(path, REPOSITORY_ROOT)

_utc_now() = Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")


function _sha256_file(path::AbstractString)
    return open(path, "r") do io
        bytes2hex(sha256(io))
    end
end


_sha256_text(text::AbstractString) = bytes2hex(sha256(codeunits(text)))


function _write_atomic(path::AbstractString, text::AbstractString)
    mkpath(dirname(path))
    temporary = path * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, path; force = false)
    return text
end


function _replace_atomic(path::AbstractString, text::AbstractString)
    mkpath(dirname(path))
    temporary = path * ".replace.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, path; force = true)
    return text
end


function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end


_write_atomic_toml(path, payload) = _write_atomic(path, _toml_text(payload))


function _replace_toml(path, payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    text = String(take!(io))
    temporary = path * ".replace.$(getpid())"
    open(temporary, "w") do output
        write(output, text)
    end
    mv(temporary, path; force = true)
    return text
end


function _csv_cell(value)
    text = isnothing(value) || ismissing(value) ? "" : string(value)
    if any(character -> character in text, (',', '"', '\n', '\r'))
        return "\"" * replace(text, "\"" => "\"\"") * "\""
    end
    return text
end


function _render_csv(rows, columns)
    io = IOBuffer()
    println(io, join(string.(columns), ','))
    for row in rows
        println(io, join((_csv_cell(getproperty(row, column)) for column in columns), ','))
    end
    return String(take!(io))
end


function _command_output(command::Cmd; unavailable = "UNAVAILABLE")
    try
        return strip(read(command, String))
    catch
        return unavailable
    end
end


function _registered_run_units(spec)
    units = NamedTuple[]
    spec.exact_enumeration_required && push!(
        units,
        (algorithm = :complete_enumeration, variant = :mandatory_only),
    )
    if spec.exact_dp_required
        push!(units, (algorithm = :requirement_mask_dp, variant = :mandatory_only))
        spec.family == :small_exact && push!(
            units,
            (algorithm = :requirement_mask_dp, variant = :full_fixed_point),
        )
    end
    push!(
        units,
        (algorithm = :jump_highs_tagged_cover, variant = :full_fixed_point),
        (algorithm = :jump_highs_tagged_cover, variant = :mandatory_only),
    )
    for algorithm in HEURISTICS
        push!(units, (algorithm, variant = :mandatory_only))
        push!(units, (algorithm, variant = :full_fixed_point_then_reconstruct))
    end
    return units
end


function _size_class(spec)
    spec.family == :small_exact && return :small
    if spec.family == :structured
        return spec.strategy_count >= 192 || spec.tagged_requirement_count >= 64 ?
               :large : :medium
    end
    spec.family == :adversarial || error("unsupported final family $(spec.family)")
    occursin("-S01", spec.instance_id) && return :small
    occursin("-S02", spec.instance_id) && return :medium
    occursin("-S03", spec.instance_id) && return :large
    error("adversarial scale is not encoded in $(spec.instance_id)")
end


function _time_limit(config, spec, algorithm)
    if spec.family == :adversarial && algorithm == :complete_enumeration
        return Float64(config["limits"]["adversarial_exact"]["enumeration_seconds"])
    elseif spec.family == :adversarial && algorithm == :requirement_mask_dp
        return Float64(config["limits"]["adversarial_exact"]["dp_seconds"])
    end
    limits = config["limits"][string(_size_class(spec))]
    algorithm == :complete_enumeration && return Float64(limits["enumeration_seconds"])
    algorithm == :requirement_mask_dp && return Float64(limits["dp_seconds"])
    algorithm == :jump_highs_tagged_cover && return Float64(limits["mip_seconds"])
    algorithm in (
        :random_order_rechecked_deletion,
        :multistart_random_rechecked_deletion_32,
    ) && return Float64(limits["randomized_heuristic_seconds"])
    return Float64(limits["deterministic_heuristic_seconds"])
end


function _run_key(algorithm, variant)
    return "$(algorithm)__$(variant)"
end


function _record_path(instance_id, algorithm, variant)
    return joinpath(
        RESULTS_ROOT,
        "raw_runs",
        instance_id,
        _run_key(algorithm, variant) * ".toml",
    )
end


function _validate_existing_record(path, instance_id, algorithm, variant)
    record = TOML.parsefile(path)
    record["schema_version"] == FINAL_RUN_SCHEMA_VERSION || error(
        "stale final record schema at $(_relative(path))",
    )
    record["instance_id"] == instance_id || error("final record instance mismatch")
    record["algorithm_id"] == string(algorithm) || error("final record algorithm mismatch")
    record["preprocessing_variant"] == string(variant) || error(
        "final record preprocessing mismatch",
    )
    record["terminal"] === true || error("nonterminal final record cannot be resumed")
    return record
end


function _execution_lock_hashes()
    paths = (
        "experiments/algorithmic_compression_v2/DESIGN_LOCK.json",
        "experiments/algorithmic_compression_v2/DESIGN.md",
        "experiments/algorithmic_compression_v2/ANALYSIS_PLAN.md",
        "experiments/algorithmic_compression_v2/REPORTING_RULES.md",
        "experiments/algorithmic_compression_v2/DESIGN_SUMMARY.md",
        "experiments/algorithmic_compression_v2/registry/INSTANCE_REGISTRY.csv",
        "experiments/algorithmic_compression_v2/registry/SEED_REGISTRY.csv",
        "experiments/configs/algorithmic_compression_v2.toml",
        "julia/Project.toml",
        "julia/Manifest.toml",
        "julia/scripts/create_algorithmic_compression_v2_registries.jl",
        "julia/scripts/audit_algorithmic_compression_final_v2.jl",
        "julia/scripts/lock_algorithmic_compression_design_v2.jl",
        "julia/scripts/run_algorithmic_compression_final_v2.jl",
        "julia/scripts/run_algorithmic_compression_final_worker_v1.jl",
        "julia/test/run_algorithmic_compression_v2_tests.jl",
        "julia/test/test_algorithmic_compression_v2.jl",
        "Makefile",
    )
    return Dict(path => _sha256_file(joinpath(REPOSITORY_ROOT, path)) for path in paths)
end


function _execution_lock_text(
    hashes,
    created_at;
    superseded_aggregate = "",
    failure_record_hash = "",
)
    rows = join(
        (
            "    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))
        ),
        ",\n",
    )
    aggregate = _sha256_text(join(
        ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
    ))
    return """{
  "schema_version": "algorithmic-compression-final-execution-start-lock-v2",
  "experiment_id": "registered-algorithmic-compression-benchmark-v2",
  "created_at_utc": "$created_at",
  "committed_design_lock_verified": true,
  "registered_worker_count": 8,
  "worker_julia_threads": 1,
  "worker_blas_threads": 1,
  "worker_highs_threads": 1,
  "final_outcomes_read_before_lock": false,
  "final_seed_used_before_lock": false,
  "registered_run_unit_count": 3907,
  "runner_gate_status": "READY",
  "pre_final_execution_repair_count": $(isempty(superseded_aggregate) ? 0 : 1),
  "superseded_execution_lock_aggregate_sha256": "$superseded_aggregate",
  "pre_final_failure_record_path": "$(isempty(failure_record_hash) ? "" : _relative(EXECUTION_START_FAILURE_PATH))",
  "pre_final_failure_record_sha256": "$failure_record_hash",
  "aggregate_sha256": "$aggregate",
  "files": {
$rows
  }
}
"""
end


function _verify_or_create_execution_lock()
    hashes = _execution_lock_hashes()
    if isfile(EXECUTION_LOCK_PATH)
        text = read(EXECUTION_LOCK_PATH, String)
        stale = String[]
        for (path, hash) in hashes
            occursin("\"$path\": \"$hash\"", text) || push!(stale, path)
        end
        if !isempty(stale)
            outcome_paths = (
                joinpath(RESULTS_ROOT, "instances"),
                joinpath(RESULTS_ROOT, "generation"),
                joinpath(RESULTS_ROOT, "raw_runs"),
                joinpath(RESULTS_ROOT, "solver_logs"),
                joinpath(RESULTS_ROOT, "control"),
                RUN_STATUS_PATH,
            )
            any(ispath, outcome_paths) && error(
                "execution-start lock is stale after final result creation: $(join(stale, ", "))",
            )
            isfile(EXECUTION_START_FAILURE_PATH) || error(
                "execution-start lock is stale without an auditable pre-final failure record",
            )
            failure = TOML.parsefile(EXECUTION_START_FAILURE_PATH)
            failure["registered_final_seed_consumed"] === false || error(
                "execution-start repair is forbidden after final seed consumption",
            )
            failure["final_outcome_observed"] === false || error(
                "execution-start repair is forbidden after an outcome was observed",
            )
            old_aggregate = match(
                r"\"aggregate_sha256\"\s*:\s*\"([0-9a-f]{64})\"",
                text,
            )
            isnothing(old_aggregate) && error("stale execution lock has no aggregate hash")
            old_aggregate.captures[1] ==
            failure["failed_execution_lock_aggregate_sha256"] || error(
                "pre-final failure record does not identify the stale lock",
            )
            _replace_atomic(
                EXECUTION_LOCK_PATH,
                _execution_lock_text(
                    hashes,
                    _utc_now();
                    superseded_aggregate = old_aggregate.captures[1],
                    failure_record_hash = _sha256_file(EXECUTION_START_FAILURE_PATH),
                ),
            )
            return :repaired_before_final_seed
        end
        occursin("\"runner_gate_status\": \"READY\"", text) || error(
            "execution-start lock is not ready",
        )
        return :verified
    end
    ispath(RESULTS_ROOT) && !isempty(readdir(RESULTS_ROOT)) && error(
        "unlocked final result artifacts already exist",
    )
    mkpath(RESULTS_ROOT)
    _write_atomic(
        EXECUTION_LOCK_PATH,
        _execution_lock_text(hashes, _utc_now()),
    )
    return :created
end


function _hardware_environment()
    LinearAlgebra.BLAS.set_num_threads(1)
    model = JuMP.Model(HiGHS.Optimizer)
    backend = JuMP.backend(model)
    machine_name = _command_output(`hostname`)
    git_status = _command_output(
        `git -C $REPOSITORY_ROOT status --porcelain=v1 --untracked-files=all`;
        unavailable = "",
    )
    return Dict{String,Any}(
        "schema_version" => "algorithmic-compression-final-environment-v2",
        "machine_id" => "sha256:" * _sha256_text(machine_name),
        "git_commit" => _command_output(`git -C $REPOSITORY_ROOT rev-parse HEAD`),
        "dirty_worktree" => !isempty(git_status),
        "dirty_worktree_status_sha256" => _sha256_text(git_status),
        "dirty_worktree_status" => split(git_status, '\n'; keepempty = false),
        "julia_version" => string(VERSION),
        "dependency_manifest_sha256" =>
            _sha256_file(joinpath(REPOSITORY_ROOT, "julia", "Manifest.toml")),
        "project_sha256" =>
            _sha256_file(joinpath(REPOSITORY_ROOT, "julia", "Project.toml")),
        "operating_system" => "macOS " * _command_output(`sw_vers -productVersion`),
        "kernel_version" => _command_output(`uname -r`),
        "architecture" => _command_output(`uname -m`),
        "cpu" => _command_output(`sysctl -n machdep.cpu.brand_string`),
        "physical_core_count" => _command_output(`sysctl -n hw.physicalcpu`),
        "logical_core_count" => _command_output(`sysctl -n hw.logicalcpu`),
        "ram_bytes" => _command_output(`sysctl -n hw.memsize`),
        "highs_version" => String(JuMP.MOI.get(backend, JuMP.MOI.SolverVersion())),
        "highs_julia_version" => string(Base.pkgversion(HiGHS)),
        "jump_version" => string(Base.pkgversion(JuMP)),
        "julia_threads" => Threads.nthreads(),
        "blas_threads" => LinearAlgebra.BLAS.get_num_threads(),
        "highs_threads" => 1,
        "supervisor_julia_threads" => Threads.nthreads(),
        "worker_julia_threads" => 1,
        "process_concurrency" => WORKER_COUNT,
        "start_time_utc" => _utc_now(),
        "end_time_utc" => "PENDING",
        "final_seed_scope_only" => true,
        "pilot_seed_used" => false,
    )
end


function _verify_environment(environment)
    environment["julia_version"] == "1.12.6" || error("final run requires Julia 1.12.6")
    environment["julia_threads"] == WORKER_COUNT || error(
        "final supervisor requires exactly $WORKER_COUNT Julia threads",
    )
    environment["supervisor_julia_threads"] == WORKER_COUNT || error(
        "registered supervisor thread count changed",
    )
    environment["worker_julia_threads"] == 1 || error(
        "registered worker thread count changed",
    )
    environment["process_concurrency"] == WORKER_COUNT || error(
        "registered process concurrency changed",
    )
    environment["blas_threads"] == 1 || error("final run requires one BLAS thread")
    environment["final_seed_scope_only"] === true || error("final seed scope changed")
    return true
end


function _rss_bytes(pid::Integer)
    output = _command_output(`ps -o rss= -p $pid`; unavailable = "")
    isempty(output) && return nothing
    value = tryparse(Int, strip(output))
    return isnothing(value) ? nothing : value * 1024
end


function _terminate_process(process)
    process_running(process) || return
    kill(process, Base.SIGTERM)
    deadline = time() + 5.0
    while process_running(process) && time() < deadline
        sleep(0.05)
    end
    process_running(process) && kill(process, Base.SIGKILL)
end


function _supervise(job, paths, time_limit)
    stdout_io = open(paths.stdout, "w")
    stderr_io = open(paths.stderr, "w")
    command = `$(Base.julia_cmd()) --threads=1 --startup-file=no --project=$(joinpath(REPOSITORY_ROOT, "julia")) $WORKER_PATH $(paths.job)`
    process = run(pipeline(command; stdout = stdout_io, stderr = stderr_io); wait = false)
    close(stdout_io)
    close(stderr_io)
    pid = getpid(process)
    peak_memory = 0
    handshake_deadline = time() + 300.0
    while process_running(process) && !isfile(paths.handshake)
        rss = _rss_bytes(pid)
        !isnothing(rss) && (peak_memory = max(peak_memory, rss))
        rss isa Int && rss > MEMORY_LIMIT_BYTES && begin
            _terminate_process(process)
            wait(process)
            return (status = "MEMORY_LIMIT", peak_memory, elapsed_ns = 0, exit_code = process.exitcode)
        end
        time() > handshake_deadline && begin
            _terminate_process(process)
            wait(process)
            return (status = "WORKER_START_TIMEOUT", peak_memory, elapsed_ns = 0, exit_code = process.exitcode)
        end
        sleep(0.05)
    end
    if !isfile(paths.handshake)
        wait(process)
        return (status = "PROCESS_ERROR", peak_memory, elapsed_ns = 0, exit_code = process.exitcode)
    end
    timing_start = time_ns()
    status = "PROCESS_COMPLETED"
    while process_running(process)
        rss = _rss_bytes(pid)
        !isnothing(rss) && (peak_memory = max(peak_memory, rss))
        if rss isa Int && rss > MEMORY_LIMIT_BYTES
            status = "MEMORY_LIMIT"
            _terminate_process(process)
            break
        elseif (time_ns() - timing_start) / 1.0e9 >= time_limit
            status = "TIME_LIMIT"
            _terminate_process(process)
            break
        end
        sleep(0.05)
    end
    wait(process)
    rss = _rss_bytes(pid)
    !isnothing(rss) && (peak_memory = max(peak_memory, rss))
    return (
        status,
        peak_memory,
        elapsed_ns = time_ns() - timing_start,
        exit_code = process.exitcode,
    )
end


function _job_paths(instance_id, algorithm, variant)
    key = _run_key(algorithm, variant)
    root = joinpath(RESULTS_ROOT, "control", instance_id)
    mkpath(root)
    return (
        job = joinpath(root, "$key.job.toml"),
        handshake = joinpath(root, "$key.handshake.toml"),
        worker = joinpath(root, "$key.worker.toml"),
        stdout = joinpath(root, "$key.stdout.log"),
        stderr = joinpath(root, "$key.stderr.log"),
    )
end

function _control_resume_state(paths)
    isfile(paths.worker) && return :completed_worker
    any(isfile, (paths.job, paths.handshake, paths.stdout, paths.stderr)) &&
        return :interrupted
    return :fresh
end


function _terminal_failure_record(job, supervisor_status, supervision, paths)
    return Dict{String,Any}(
        "schema_version" => FINAL_RUN_SCHEMA_VERSION,
        "experiment_id" => "registered-algorithmic-compression-benchmark-v2",
        "terminal" => true,
        "analysis_included" => true,
        "instance_id" => job["instance_id"],
        "family" => job["family"],
        "mechanism" => job["mechanism"],
        "algorithm_id" => job["algorithm_id"],
        "preprocessing_variant" => job["preprocessing_variant"],
        "worker_lane" => job["worker_lane"],
        "lane_position" => job["lane_position"],
        "global_schedule_position" => job["global_schedule_position"],
        "launch_wave" => job["launch_wave"],
        "status" => supervisor_status,
        "failure_code" => supervisor_status,
        "candidate_accepted" => false,
        "registered_time_limit_seconds" => job["time_limit_seconds"],
        "registered_memory_limit_bytes" => string(MEMORY_LIMIT_BYTES),
        "supervisor" => Dict{String,Any}(
            "time_limit_enforced" => true,
            "memory_limit_enforced" => true,
            "peak_memory_bytes" => supervision.peak_memory,
            "wall_clock_ns" => string(supervision.elapsed_ns),
            "worker_exit_code" => supervision.exit_code,
            "stdout_path" => _relative(paths.stdout),
            "stderr_path" => _relative(paths.stderr),
        ),
        "exact_feasibility_recheck" => Dict{String,Any}("available" => false),
    )
end


function _finalize_worker_record(job, worker, supervision, paths)
    record = Dict{String,Any}(
        "schema_version" => FINAL_RUN_SCHEMA_VERSION,
        "experiment_id" => "registered-algorithmic-compression-benchmark-v2",
        "terminal" => true,
        "analysis_included" => true,
        "instance_id" => job["instance_id"],
        "family" => job["family"],
        "mechanism" => job["mechanism"],
        "replicate_id" => job["replicate_id"],
        "instance_sha256" => job["instance_sha256"],
        "seed_id" => job["seed_id"],
        "generator_seed" => job["generator_seed"],
        "random_order_seed" => job["random_order_seed"],
        "multistart_seed" => job["multistart_seed"],
        "mip_seed" => job["mip_seed"],
        "algorithm_id" => job["algorithm_id"],
        "preprocessing_variant" => job["preprocessing_variant"],
        "algorithm_execution_position" => job["algorithm_execution_position"],
        "worker_lane" => job["worker_lane"],
        "lane_position" => job["lane_position"],
        "global_schedule_position" => job["global_schedule_position"],
        "launch_wave" => job["launch_wave"],
        "status" => worker["status"],
        "failure_code" => worker["worker_status"] == "COMPLETED" ? "" :
            get(worker, "status", "WORKER_ERROR"),
        "candidate_accepted" => worker["candidate_accepted"],
        "registered_time_limit_seconds" => job["time_limit_seconds"],
        "registered_memory_limit_bytes" => string(MEMORY_LIMIT_BYTES),
        "worker" => worker,
        "supervisor" => Dict{String,Any}(
            "status" => supervision.status,
            "time_limit_enforced" => true,
            "memory_limit_enforced" => true,
            "peak_memory_bytes" => supervision.peak_memory,
            "wall_clock_ns" => string(supervision.elapsed_ns),
            "worker_exit_code" => supervision.exit_code,
            "stdout_path" => _relative(paths.stdout),
            "stderr_path" => _relative(paths.stderr),
        ),
    )
    if job["algorithm_id"] == "jump_highs_tagged_cover" &&
       haskey(worker, "method_result")
        log = worker["method_result"]["solver_diagnostics"]["complete_solver_log"]
        log_path = joinpath(
            RESULTS_ROOT,
            "solver_logs",
            job["instance_id"],
            _run_key(Symbol(job["algorithm_id"]), Symbol(job["preprocessing_variant"])) * ".log",
        )
        mkpath(dirname(log_path))
        _write_atomic(log_path, String(log))
        record["solver_log_path"] = _relative(log_path)
        record["solver_log_sha256"] = _sha256_file(log_path)
    end
    return record
end


function _run_one(job)
    algorithm = Symbol(job["algorithm_id"])
    variant = Symbol(job["preprocessing_variant"])
    path = _record_path(job["instance_id"], algorithm, variant)
    isfile(path) && return _validate_existing_record(
        path,
        job["instance_id"],
        algorithm,
        variant,
    )
    paths = _job_paths(job["instance_id"], algorithm, variant)
    resume_state = _control_resume_state(paths)
    if resume_state == :completed_worker
        worker = TOML.parsefile(paths.worker)
        supervision = (
            status = "RECOVERED_COMPLETED_WORKER",
            peak_memory = 0,
            elapsed_ns = parse(
                Int,
                string(get(worker, "algorithm_wall_clock_ns", 0)),
            ),
            exit_code = get(worker, "worker_status", "ERROR") == "COMPLETED" ? 0 : 2,
        )
        record = _finalize_worker_record(job, worker, supervision, paths)
        record["recovered_after_supervisor_interruption"] = true
        _write_atomic_toml(path, record)
        return record
    elseif resume_state == :interrupted
        supervision = (peak_memory = 0, elapsed_ns = 0, exit_code = -1)
        record = _terminal_failure_record(job, "PROCESS_INTERRUPTED", supervision, paths)
        _write_atomic_toml(path, record)
        return record
    end
    for control in (paths.job, paths.handshake, paths.worker, paths.stdout, paths.stderr)
        isfile(control) && error("unexpected preexisting control artifact: $(_relative(control))")
    end
    _write_atomic_toml(paths.job, merge(job, Dict(
        "schema_version" => FINAL_JOB_SCHEMA_VERSION,
        "handshake_path" => paths.handshake,
        "worker_output_path" => paths.worker,
    )))
    supervision = _supervise(job, paths, Float64(job["time_limit_seconds"]))
    record = if supervision.status == "PROCESS_COMPLETED" && isfile(paths.worker)
        worker = TOML.parsefile(paths.worker)
        _finalize_worker_record(job, worker, supervision, paths)
    else
        terminal_status = supervision.status == "PROCESS_COMPLETED" ?
            "PROCESS_ERROR" : supervision.status
        _terminal_failure_record(job, terminal_status, supervision, paths)
    end
    _write_atomic_toml(path, record)
    return record
end


function _generation_failure_record(spec, seed, schedule_item, time_limit, generation_path)
    unit = schedule_item.unit
    return Dict{String,Any}(
        "schema_version" => FINAL_RUN_SCHEMA_VERSION,
        "experiment_id" => "registered-algorithmic-compression-benchmark-v2",
        "terminal" => true,
        "analysis_included" => true,
        "instance_id" => spec.instance_id,
        "family" => string(spec.family),
        "mechanism" => string(spec.mechanism),
        "replicate_id" => spec.replicate_id,
        "seed_id" => seed.seed_id,
        "generator_seed" => string(seed.generator_seed),
        "random_order_seed" => string(seed.random_order_seed),
        "multistart_seed" => string(seed.multistart_seed),
        "mip_seed" => string(seed.mip_seed),
        "algorithm_id" => string(unit.algorithm),
        "preprocessing_variant" => string(unit.variant),
        "algorithm_execution_position" => schedule_item.algorithm_execution_position,
        "worker_lane" => schedule_item.worker_lane,
        "lane_position" => schedule_item.lane_position,
        "global_schedule_position" => schedule_item.global_schedule_position,
        "launch_wave" => schedule_item.launch_wave,
        "status" => "GENERATION_FAILED",
        "failure_code" => "GENERATION_FAILED",
        "candidate_accepted" => false,
        "registered_time_limit_seconds" => time_limit,
        "registered_memory_limit_bytes" => string(MEMORY_LIMIT_BYTES),
        "generation_record_path" => _relative(generation_path),
        "generation_record_sha256" => _sha256_file(generation_path),
        "supervisor" => Dict{String,Any}(
            "status" => "NOT_STARTED_GENERATION_FAILED",
            "time_limit_enforced" => true,
            "memory_limit_enforced" => true,
            "peak_memory_bytes" => 0,
            "wall_clock_ns" => "0",
            "worker_exit_code" => -1,
        ),
        "exact_feasibility_recheck" => Dict{String,Any}("available" => false),
    )
end


function _expand_generation_failure!(spec, seed, schedule_items, config, generation_path)
    for schedule_item in schedule_items
        unit = schedule_item.unit
        path = _record_path(spec.instance_id, unit.algorithm, unit.variant)
        isfile(path) && continue
        record = _generation_failure_record(
            spec,
            seed,
            unit,
            schedule_item,
            _time_limit(config, spec, unit.algorithm),
            generation_path,
        )
        _write_atomic_toml(path, record)
    end
    return nothing
end


function _not_applicable_rows(spec, units)
    return NamedTuple[]
end


function _write_run_status(registries)
    records = NamedTuple[]
    for spec in registries.instances
        spec.phase == :final || continue
        for unit in _registered_run_units(spec)
            path = _record_path(spec.instance_id, unit.algorithm, unit.variant)
            isfile(path) || continue
            record = TOML.parsefile(path)
            recheck = get(record, "worker", Dict{String,Any}())
            recheck = get(recheck, "exact_feasibility_recheck", Dict{String,Any}())
            exact_burden = get(get(record, "worker", Dict{String,Any}()), "exact_burden", Dict{String,Any}())
            push!(records, (
                instance_id = spec.instance_id,
                family = string(spec.family),
                mechanism = string(spec.mechanism),
                algorithm_id = string(unit.algorithm),
                preprocessing_variant = string(unit.variant),
                applicable = true,
                status = String(record["status"]),
                candidate_accepted = Bool(record["candidate_accepted"]),
                exact_feasible = get(recheck, "available", false) ?
                    get(recheck, "exact_feasible", false) : false,
                exact_burden = get(exact_burden, "available", false) ?
                    exact_burden["value"] : nothing,
                wall_clock_ns = get(record["supervisor"], "wall_clock_ns", nothing),
                peak_memory_bytes = get(record["supervisor"], "peak_memory_bytes", nothing),
                time_limit_seconds = record["registered_time_limit_seconds"],
                record_path = _relative(path),
                record_sha256 = _sha256_file(path),
                failure_code = get(record, "failure_code", ""),
                worker_lane = record["worker_lane"],
                lane_position = record["lane_position"],
                global_schedule_position = record["global_schedule_position"],
                launch_wave = record["launch_wave"],
            ))
        end
    end
    sort!(records; by = row -> (row.instance_id, row.algorithm_id, row.preprocessing_variant))
    _replace_toml(
        joinpath(RESULTS_ROOT, "execution_state.toml"),
        Dict{String,Any}(
            "schema_version" => "algorithmic-compression-final-execution-state-v2",
            "terminal_record_count" => length(records),
            "expected_record_count" => 3907,
            "complete" => length(records) == 3907,
            "updated_at_utc" => _utc_now(),
        ),
    )
    text = _render_csv(records, RUN_COLUMNS)
    temporary = RUN_STATUS_PATH * ".replace.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, RUN_STATUS_PATH; force = true)
    return records
end


function _registered_schedule(registries)
    final_pairs = [
        (registry_position = index, spec, seed = registries.seeds[index]) for
        (index, spec) in enumerate(registries.instances) if spec.phase == :final
    ]
    sort!(final_pairs; by = row -> row.seed.execution_order_key)
    unassigned = NamedTuple[]
    for row in final_pairs
        units = _registered_run_units(row.spec)
        rotation = mod(row.registry_position - 1, length(units))
        for (algorithm_execution_position, unit) in enumerate(circshift(units, -rotation))
            push!(unassigned, (;
                row.registry_position,
                row.spec,
                row.seed,
                unit,
                algorithm_execution_position,
            ))
        end
    end
    lane_positions = zeros(Int, WORKER_COUNT)
    return [begin
        lane = mod(global_position - 1, WORKER_COUNT) + 1
        lane_positions[lane] += 1
        (;
            item...,
            worker_lane = lane,
            lane_position = lane_positions[lane],
            global_schedule_position = global_position,
            launch_wave = cld(global_position, WORKER_COUNT),
        )
    end for (global_position, item) in enumerate(unassigned)]
end


function _progress_line(completed::Integer, total::Integer; width::Integer = 40)
    total > 0 || return "[" * repeat("=", width) * "] 0/0 (100.0%)"
    bounded = clamp(completed, 0, total)
    filled = fld(bounded * width, total)
    percent = 100 * bounded / total
    return "[" * repeat("=", filled) * repeat(".", width - filled) *
           "] $bounded/$total ($(round(percent; digits = 1))%)"
end


function _show_progress(completed, total; final = false)
    get(ENV, "AOR_PROGRESS", "1") == "0" && return
    print(stderr, '\r', _progress_line(completed, total))
    final && println(stderr)
    flush(stderr)
end


function _run_lanes!(lanes, total; initially_terminal = 0, run_one = _run_one)
    progress = Channel{NamedTuple}(max(total, 1))
    tasks = Task[]
    for lane in 1:WORKER_COUNT
        push!(tasks, Threads.@spawn begin
            for job in lanes[lane]
                record = run_one(job)
                put!(progress, (
                    worker_lane = lane,
                    global_schedule_position = job["global_schedule_position"],
                    terminal = record["terminal"] === true,
                ))
            end
        end)
    end
    completed = initially_terminal
    _show_progress(completed, total)
    while !all(istaskdone, tasks)
        while isready(progress)
            event = take!(progress)
            event.terminal || error("worker lane returned a nonterminal record")
            completed += 1
            _show_progress(completed, total)
        end
        sleep(0.05)
    end
    while isready(progress)
        event = take!(progress)
        event.terminal || error("worker lane returned a nonterminal record")
        completed += 1
        _show_progress(completed, total)
    end
    foreach(fetch, tasks)
    _show_progress(completed, total; final = true)
    completed == total || error("only $completed of $total scheduled runs became terminal")
    return completed
end


function validate_final_runner_readiness()
    verify_design_lock_v2(CONFIG_PATH)
    string(VERSION) == "1.12.6" || error("final runner requires Julia 1.12.6")
    Threads.nthreads() == WORKER_COUNT || error(
        "final runner requires exactly $WORKER_COUNT supervisor threads",
    )
    isfile(WORKER_PATH) || error("final worker is missing")
    registries = load_algorithmic_benchmark_registries(
        INSTANCE_REGISTRY_PATH,
        SEED_REGISTRY_PATH,
    )
    final_specs = [spec for spec in registries.instances if spec.phase == :final]
    length(final_specs) == 173 || error("final registry count changed")
    total_units = sum(length(_registered_run_units(spec)) for spec in final_specs)
    total_units == 3907 || error("registered final run-unit count changed: $total_units")
    pilot_values = Set{UInt64}()
    final_values = Set{UInt64}()
    for seed in registries.seeds
        values = UInt64[
            seed.execution_order_key,
            seed.generator_seed,
            seed.random_order_seed,
            seed.multistart_seed,
            seed.mip_seed,
        ]
        seed.phase == :pilot && union!(pilot_values, values)
        seed.phase == :final && union!(final_values, values)
    end
    isempty(intersect(pilot_values, final_values)) || error("pilot/final seed overlap")
    v1_root = joinpath(
        REPOSITORY_ROOT,
        "experiments",
        "algorithmic_compression_v1",
        "registry",
    )
    v1 = load_algorithmic_benchmark_registries(
        joinpath(v1_root, "INSTANCE_REGISTRY.csv"),
        joinpath(v1_root, "SEED_REGISTRY.csv"),
    )
    v1_values = Set{UInt64}()
    for seed in v1.seeds
        union!(v1_values, UInt64[
            seed.execution_order_key,
            seed.generator_seed,
            seed.random_order_seed,
            seed.multistart_seed,
            seed.mip_seed,
        ])
    end
    isempty(intersect(v1_values, union(pilot_values, final_values))) || error(
        "v2 registered seeds overlap v1",
    )
    schedule = _registered_schedule(registries)
    length(schedule) == total_units || error("registered schedule is incomplete")
    lane_counts = [count(item -> item.worker_lane == lane, schedule) for lane in 1:WORKER_COUNT]
    maximum(lane_counts) - minimum(lane_counts) <= 1 || error(
        "round-robin lane allocation is imbalanced",
    )
    return (; registries, total_units, schedule, lane_counts)
end


function run_final_benchmark()
    readiness = validate_final_runner_readiness()
    execution_lock_status = _verify_or_create_execution_lock()
    environment = if isfile(ENVIRONMENT_PATH)
        TOML.parsefile(ENVIRONMENT_PATH)
    else
        value = _hardware_environment()
        _verify_environment(value)
        _write_atomic_toml(ENVIRONMENT_PATH, value)
        value
    end
    environment["execution_lock_status_for_run"] = string(execution_lock_status)
    if isfile(EXECUTION_START_FAILURE_PATH)
        environment["pre_final_execution_start_failure_path"] =
            _relative(EXECUTION_START_FAILURE_PATH)
        environment["pre_final_execution_start_failure_sha256"] =
            _sha256_file(EXECUTION_START_FAILURE_PATH)
        _replace_toml(ENVIRONMENT_PATH, environment)
    end
    _verify_environment(environment)
    config = TOML.parsefile(CONFIG_PATH)
    registries = readiness.registries
    schedule_by_instance = Dict{String,Vector{Any}}()
    for item in readiness.schedule
        push!(get!(schedule_by_instance, item.spec.instance_id, Any[]), item)
    end
    lanes = [Dict{String,Any}[] for _ in 1:WORKER_COUNT]
    generation_failure_count = 0
    final_instance_ids = unique(item.spec.instance_id for item in readiness.schedule)
    for instance_id in final_instance_ids
        items = schedule_by_instance[instance_id]
        spec = first(items).spec
        seed = first(items).seed
        seed.phase == :final || error("nonfinal seed entered final runner")
        instance_path = joinpath(RESULTS_ROOT, "instances", "$(spec.instance_id).toml")
        generation_path = joinpath(RESULTS_ROOT, "generation", "$(spec.instance_id).toml")
        if !isfile(instance_path)
            if isfile(generation_path)
                generation = TOML.parsefile(generation_path)
                if generation["status"] == "GENERATED"
                    regenerated = generate_algorithmic_benchmark_instance(
                        spec,
                        seed;
                        allow_final = true,
                    )
                    regenerated isa AlgorithmicGeneratedInstance || error(
                        "deterministic recovery generation failed for $(spec.instance_id)",
                    )
                    regenerated.instance_sha256 == generation["instance_sha256"] || error(
                        "deterministic recovery hash changed for $(spec.instance_id)",
                    )
                    _write_atomic(
                        instance_path,
                        serialize_journal_compression_instance(regenerated.instance),
                    )
                else
                    _expand_generation_failure!(spec, seed, items, config, generation_path)
                    generation_failure_count += length(items)
                    continue
                end
            end
            if !isfile(instance_path)
                generated = generate_algorithmic_benchmark_instance(
                    spec,
                    seed;
                    allow_final = true,
                )
                _write_atomic(generation_path, serialize_algorithmic_generation_record(generated))
                if !(generated isa AlgorithmicGeneratedInstance)
                    _expand_generation_failure!(spec, seed, items, config, generation_path)
                    generation_failure_count += length(items)
                    continue
                end
                _write_atomic(
                    instance_path,
                    serialize_journal_compression_instance(generated.instance),
                )
            end
        end
        instance = open(read_journal_compression_instance, instance_path)
        for item in items
            unit = item.unit
            job = Dict{String,Any}(
                "instance_id" => spec.instance_id,
                "family" => string(spec.family),
                "mechanism" => string(spec.mechanism),
                "replicate_id" => spec.replicate_id,
                "seed_id" => seed.seed_id,
                "generator_seed" => string(seed.generator_seed),
                "random_order_seed" => string(seed.random_order_seed),
                "multistart_seed" => string(seed.multistart_seed),
                "mip_seed" => string(seed.mip_seed),
                "instance_path" => instance_path,
                "instance_sha256" => journal_compression_instance_sha256(instance),
                "strategy_ids" => [string(id.id) for id in instance.strategy_ids],
                "algorithm_id" => string(unit.algorithm),
                "preprocessing_variant" => string(unit.variant),
                "algorithm_execution_position" => item.algorithm_execution_position,
                "worker_lane" => item.worker_lane,
                "lane_position" => item.lane_position,
                "global_schedule_position" => item.global_schedule_position,
                "launch_wave" => item.launch_wave,
                "time_limit_seconds" => _time_limit(config, spec, unit.algorithm),
            )
            push!(lanes[item.worker_lane], job)
        end
    end
    _run_lanes!(
        lanes,
        readiness.total_units;
        initially_terminal = generation_failure_count,
    )
    records = _write_run_status(registries)
    length(records) == readiness.total_units || error("final result matrix is incomplete")
    environment["end_time_utc"] = _utc_now()
    environment["terminal_record_count"] = length(records)
    _replace_toml(ENVIRONMENT_PATH, environment)
    println("final benchmark complete: terminal_records=$(length(records)), final_seeds_only=true")
    return true
end


function main(args = ARGS)
    mode = isempty(args) ? "--run" : only(args)
    mode == "--check" && return validate_final_runner_readiness()
    mode == "--run" && return run_final_benchmark()
    error("usage: run_algorithmic_compression_final_v2.jl [--check|--run]")
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    AlgorithmicCompressionFinalV2.main()
end
