module AlgorithmicCompressionPilotV1

using Dates
using LinearAlgebra
using SHA: sha256
using StrategyInnovation
using TOML

include(joinpath(@__DIR__, "lock_algorithmic_compression_design_v1.jl"))
using .LockAlgorithmicCompressionDesignV1: verify_design_lock

export check_pilot_outputs, main, run_pilot

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "algorithmic_compression_v1.toml",
)
const PILOT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "algorithmic_compression_v1",
    "pilot",
)
const RUNS_PATH = joinpath(PILOT_ROOT, "pilot_runs.csv")
const FAILURES_PATH = joinpath(PILOT_ROOT, "pilot_failures.csv")
const ENVIRONMENT_PATH = joinpath(PILOT_ROOT, "environment.toml")
const MANIFEST_PATH = joinpath(PILOT_ROOT, "PILOT_MANIFEST.toml")
const INITIAL_LOCK_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "algorithmic_compression_v1",
    "DESIGN_LOCK.json",
)
const PILOT_SCHEMA_VERSION = "algorithmic-compression-pilot-run-v1"
const PILOT_MANIFEST_SCHEMA_VERSION = "algorithmic-compression-pilot-manifest-v1"
const ALGORITHM_IDS = (
    :complete_enumeration,
    :requirement_mask_dp,
    :jump_highs_tagged_cover,
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
    :phase,
    :family,
    :mechanism,
    :strategy_count,
    :tagged_requirement_count,
    :algorithm_id,
    :registry_position,
    :instance_execution_position,
    :algorithm_execution_position,
    :applicable,
    :status,
    :solved,
    :evidence_class,
    :exact_burden,
    :wall_clock_ns,
    :julia_allocated_bytes,
    :gc_time_seconds,
    :compile_time_seconds,
    :time_limit_seconds,
    :time_limit_enforced,
    :memory_limit_bytes,
    :memory_limit_enforced,
    :peak_memory_bytes,
    :peak_memory_status,
    :mip_node_count,
    :mip_best_bound,
    :mip_reported_gap,
    :dp_state_count,
    :dp_transition_count,
    :frontier_check_count,
    :closure_check_count,
    :preprocessing_variables_removed,
    :preprocessing_requirements_removed,
    :record_path,
    :record_sha256,
    :log_path,
    :log_sha256,
    :failure_code,
)
const FAILURE_COLUMNS = (
    :instance_id,
    :algorithm_id,
    :failure_code,
    :exception_type,
    :message,
    :record_path,
    :record_sha256,
)


_require(condition::Bool, message::AbstractString) =
    condition ? true : error(message)

_relative(path::AbstractString) = relpath(path, REPOSITORY_ROOT)

_sha256_text(text::AbstractString) = bytes2hex(sha256(codeunits(text)))

_sha256_file(path::AbstractString) = open(path, "r") do io
    bytes2hex(sha256(io))
end

_utc_now() = Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")


function _command_output(command::Cmd; unavailable = "UNAVAILABLE")
    try
        return strip(read(command, String))
    catch
        return unavailable
    end
end


function _package_version(name::AbstractString)
    manifest = TOML.parsefile(joinpath(REPOSITORY_ROOT, "julia", "Manifest.toml"))
    dependencies = get(manifest, "deps", Dict{String,Any}())
    entries = get(dependencies, String(name), Any[])
    entries isa AbstractVector || (entries = Any[entries])
    length(entries) == 1 || return "UNAVAILABLE"
    return string(get(only(entries), "version", "UNAVAILABLE"))
end


function _parse_int_or_unavailable(value::AbstractString)
    value == "UNAVAILABLE" && return value
    return parse(Int, value)
end


function _hardware_environment(started_at::String)
    cpu_model = _command_output(`sysctl -n machdep.cpu.brand_string`)
    physical = _command_output(`sysctl -n hw.physicalcpu`)
    logical = _command_output(`sysctl -n hw.logicalcpu`)
    memory = _command_output(`sysctl -n hw.memsize`)
    kernel = _command_output(`uname -r`)
    architecture = _command_output(`uname -m`)
    os_version = _command_output(`sw_vers -productVersion`)
    host_token = _command_output(`hostname`)
    machine_id = _sha256_text(host_token)[1:16]
    project_path = joinpath(REPOSITORY_ROOT, "julia", "Project.toml")
    manifest_path = joinpath(REPOSITORY_ROOT, "julia", "Manifest.toml")
    return Dict{String,Any}(
        "schema_version" => "algorithmic-compression-environment-v1",
        "machine_id" => machine_id,
        "cpu_model" => cpu_model,
        "physical_core_count" => _parse_int_or_unavailable(physical),
        "logical_core_count" => _parse_int_or_unavailable(logical),
        "julia_visible_cpu_threads" => Sys.CPU_THREADS,
        "installed_memory_bytes" => _parse_int_or_unavailable(memory),
        "operating_system" => "macOS $os_version",
        "kernel_version" => kernel,
        "architecture" => architecture,
        "julia_version" => string(VERSION),
        "git_commit" => _command_output(`git -C $REPOSITORY_ROOT rev-parse HEAD`),
        "git_worktree_dirty_at_pilot" => !isempty(
            _command_output(`git -C $REPOSITORY_ROOT status --short`; unavailable = ""),
        ),
        "project_toml_sha256" => _sha256_file(project_path),
        "manifest_toml_sha256" => _sha256_file(manifest_path),
        "highs_solver_version" => "PENDING_FIRST_MIP_RECORD",
        "highs_julia_version" => _package_version("HiGHS"),
        "jump_version" => _package_version("JuMP"),
        "stable_rngs_version" => _package_version("StableRNGs"),
        "julia_threads" => Threads.nthreads(),
        "blas_threads" => LinearAlgebra.BLAS.get_num_threads(),
        "started_at_utc" => started_at,
        "runtime_clock" => "Base.time_ns monotonic wall clock",
        "peak_memory_measure" => "UNAVAILABLE per algorithm in this in-process pilot; Sys.maxrss is recorded only as a cumulative process diagnostic",
    )
end


function _write_toml(path::AbstractString, payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    text = String(take!(io))
    mkpath(dirname(path))
    open(path, "w") do output
        write(output, text)
    end
    return text
end


function _serializable(value)
    value isa Rational && return encode_exact_rational(value)
    value isa BigInt && return string(value)
    value isa Unsigned && return string(value)
    value isa Symbol && return string(value)
    value isa StrategyId && return string(value.id)
    value isa Missing && return Dict{String,Any}("available" => false)
    value === nothing && return Dict{String,Any}("available" => false)
    value isa NamedTuple && return Dict{String,Any}(
        string(key) => _serializable(getproperty(value, key)) for key in keys(value)
    )
    value isa AbstractDict && return Dict{String,Any}(
        string(key) => _serializable(entry) for (key, entry) in value
    )
    value isa AbstractArray && return [_serializable(entry) for entry in value]
    value isa Tuple && return [_serializable(entry) for entry in value]
    if isstructtype(typeof(value)) && parentmodule(typeof(value)) === StrategyInnovation
        return Dict{String,Any}(
            string(name) => _serializable(getfield(value, name)) for
            name in fieldnames(typeof(value))
        )
    end
    return value
end


function _csv_cell(value)
    text = value === nothing || ismissing(value) ? "" : string(value)
    if occursin(',', text) || occursin('"', text) || occursin('\n', text) || occursin('\r', text)
        return "\"" * replace(text, "\"" => "\"\"") * "\""
    end
    return text
end


function _render_csv(rows, columns)
    io = IOBuffer()
    println(io, join(string.(columns), ','))
    for row in rows
        println(
            io,
            join((_csv_cell(getproperty(row, column)) for column in columns), ','),
        )
    end
    return String(take!(io))
end


function _write_csv(path, rows, columns)
    text = _render_csv(rows, columns)
    mkpath(dirname(path))
    open(path, "w") do io
        write(io, text)
    end
    return text
end


function _algorithm_applicable(spec, algorithm::Symbol)
    algorithm == :complete_enumeration && return spec.exact_enumeration_required
    algorithm == :requirement_mask_dp && return spec.exact_dp_required
    algorithm == :jump_highs_tagged_cover && return spec.mip_required
    return true
end


function _size_class(spec)
    spec.family in (:small_exact, :adversarial) && return :small
    spec.family == :structured && return (
        spec.strategy_count >= 192 || spec.tagged_requirement_count >= 64 ?
        :large : :medium
    )
    error("unsupported pilot family $(spec.family)")
end


function _algorithm_limit(config, spec, algorithm)
    size_class = _size_class(spec)
    limits = config["limits"][string(size_class)]
    if algorithm == :complete_enumeration
        return Float64(config["limits"]["adversarial_exact"]["enumeration_seconds"])
    elseif algorithm == :requirement_mask_dp
        return Float64(config["limits"]["adversarial_exact"]["dp_seconds"])
    elseif algorithm == :jump_highs_tagged_cover
        return Float64(limits["mip_seconds"])
    elseif algorithm in (
        :random_order_rechecked_deletion,
        :multistart_random_rechecked_deletion_32,
    )
        return Float64(limits["randomized_heuristic_seconds"])
    end
    return Float64(limits["deterministic_heuristic_seconds"])
end


function _memory_limit_bytes(config, spec)
    size_class = _size_class(spec)
    gib = Int(config["limits"][string(size_class)]["memory_gib_per_process"])
    return gib * 1024^3
end


function _execute_algorithm(instance, spec, seed, algorithm, time_limit, config)
    if algorithm == :complete_enumeration
        return solve_journal_compression_enumeration(
            instance;
            retain_all_ties = true,
            maximum_optional_strategies = 24,
            maximum_ties = Int(config["limits"]["adversarial_exact"]["maximum_ties"]),
        )
    elseif algorithm == :requirement_mask_dp
        return solve_journal_compression_dp(
            instance;
            retain_all_ties = true,
            maximum_ties = Int(config["limits"]["adversarial_exact"]["maximum_ties"]),
        )
    elseif algorithm == :jump_highs_tagged_cover
        return solve_journal_compression_mip(
            instance;
            random_seed = seed.mip_seed,
            time_limit,
            relative_mip_gap_tolerance = 0.0,
            absolute_mip_gap_tolerance = 0.0,
            exact_crosscheck = :auto,
            enumeration_crosscheck_limit = 20,
            dp_crosscheck_requirement_limit = 18,
        )
    elseif algorithm == :weighted_greedy
        return solve_journal_compression_weighted_greedy(instance)
    elseif algorithm == :cardinality_greedy
        return solve_journal_compression_cardinality_greedy(instance)
    elseif algorithm == :weighted_greedy_reverse_delete
        return solve_journal_compression_weighted_greedy_reverse_delete(instance)
    elseif algorithm == :heaviest_safe_first
        return solve_journal_compression_heaviest_safe_first(instance)
    elseif algorithm == :lightest_safe_first
        return solve_journal_compression_lightest_safe_first(instance)
    elseif algorithm == :maximum_immediate_burden_release
        return solve_journal_compression_maximum_immediate_burden_release(instance)
    elseif algorithm == :minimum_unique_carrier_exposure
        return solve_journal_compression_minimum_unique_carrier_exposure(instance)
    elseif algorithm == :declared_source_order
        return solve_journal_compression_declared_order(instance)
    elseif algorithm == :random_order_rechecked_deletion
        return solve_journal_compression_random_order(
            instance;
            seed = seed.random_order_seed,
        )
    elseif algorithm == :multistart_random_rechecked_deletion_32
        return solve_journal_compression_multistart_random(
            instance;
            seed = seed.multistart_seed,
            starts = Int(config["seeds"]["random_multistart_count"]),
        )
    end
    error("unsupported registered algorithm: $algorithm")
end


function _greedy_payload(result::JournalGreedySolutionResult)
    return Dict{String,Any}(
        "schema_version" => result.schema_version,
        "algorithm" => string(result.algorithm),
        "status" => string(result.status),
        "instance_sha256" => result.instance_sha256,
        "exact_burden" => encode_exact_rational(result.exact_burden),
        "greedy_burden_before_reverse_deletion" =>
            encode_exact_rational(result.greedy_burden_before_reverse_deletion),
        "selected_strategy_ids" =>
            collect(string.(getfield.(result.selected_strategy_ids, :id))),
        "tie_declaration" => result.tie_declaration,
        "uncovered_counts" => result.uncovered_counts,
        "guarantee" => _serializable(result.guarantee),
        "final_certificate" => _serializable(result.final_certificate),
        "step_trace" => [_serializable(step) for step in result.step_trace],
        "reverse_deletion_trace" =>
            [_serializable(step) for step in result.reverse_deletion_trace],
    )
end


function _deletion_payload(result::JournalDeletionSolutionResult)
    return Dict{String,Any}(
        "schema_version" => result.schema_version,
        "algorithm" => string(result.algorithm),
        "status" => string(result.status),
        "instance_sha256" => result.instance_sha256,
        "exact_burden" => encode_exact_rational(result.exact_burden),
        "selected_strategy_ids" =>
            collect(string.(getfield.(result.selected_strategy_ids, :id))),
        "random_seed" => isnothing(result.random_seed) ? "NOT_APPLICABLE" : string(result.random_seed),
        "order_indices" => result.order_indices,
        "tie_declaration" => result.tie_declaration,
        "counters" => _serializable(result.counters),
        "runtime" => _serializable(result.runtime),
        "final_feasibility_certificate" =>
            _serializable(result.final_feasibility_certificate),
        "irreducibility_certificate" =>
            _serializable(result.irreducibility_certificate),
        "deletion_trace" => [_serializable(step) for step in result.deletion_trace],
        "start_summaries" => [_serializable(row) for row in result.start_summaries],
    )
end


function _result_payload(result)
    result isa JournalExactSolutionResult && return journal_exact_solution_certificate(result)
    result isa JournalMIPSolutionResult && return journal_mip_solution_certificate(result)
    result isa JournalGreedySolutionResult && return _greedy_payload(result)
    result isa JournalDeletionSolutionResult && return _deletion_payload(result)
    error("unsupported pilot result type $(typeof(result))")
end


function _result_summary(result, external_wall_ns)
    if result isa JournalExactSolutionResult
        selected = result.selected
        check = result.certificates[1]
        return (
            status = "SOLVED",
            solved = true,
            evidence_class = "exact finite computation",
            exact_burden = encode_exact_rational(result.exact_burden),
            selected,
            mandatory_retained = check.mandatory_retained,
            tagged_coverage = check.tagged_coverage,
            frontier_preserved = check.frontier_preserved,
            closure_preserved = check.closure_preserved,
            burden_reconciled = check.burden_reconciled,
            mip_node_count = nothing,
            mip_best_bound = nothing,
            mip_reported_gap = nothing,
            dp_state_count = result.algorithm == :requirement_mask_dp ?
                string(result.counters.state_layer_pairs_visited) : nothing,
            dp_transition_count = result.algorithm == :requirement_mask_dp ?
                string(result.counters.transitions_evaluated) : nothing,
            frontier_check_count = nothing,
            closure_check_count = nothing,
            preprocessing_variables_removed =
                result.preprocessing.original_strategy_count -
                result.preprocessing.reduced_strategy_count,
            preprocessing_requirements_removed =
                result.preprocessing.original_requirement_count -
                result.preprocessing.reduced_requirement_count,
        )
    elseif result isa JournalMIPSolutionResult
        certificate = result.exact_feasibility_certificate
        feasible = result.candidate_accepted && !isnothing(certificate) &&
                   certificate.exact_feasible
        preprocessing_solved = feasible && !result.diagnostics.solver_invoked
        solved = preprocessing_solved || (feasible && result.solver_claimed_optimal)
        status = preprocessing_solved ? "SOLVED_BY_EXACT_PREPROCESSING" :
                 solved ? "SOLVED" :
                 feasible ? "FEASIBLE_INCUMBENT" : uppercase(string(result.status))
        return (
            status,
            solved,
            evidence_class = preprocessing_solved ?
                "exact finite preprocessing computation" :
                "mixed-integer solver evidence plus exact post-check",
            exact_burden = ismissing(result.exact_burden) ? nothing :
                encode_exact_rational(result.exact_burden),
            selected = isnothing(result.reconstructed_candidate) ?
                falses(length(result.strategy_ids)) : result.reconstructed_candidate,
            mandatory_retained = feasible ? certificate.mandatory_retained : false,
            tagged_coverage = feasible ? certificate.tagged_coverage : false,
            frontier_preserved = feasible ? certificate.frontier_preserved : false,
            closure_preserved = feasible ? certificate.closure_preserved : false,
            burden_reconciled = feasible ? certificate.burden_reconciled : false,
            mip_node_count = ismissing(result.diagnostics.node_count) ? nothing :
                result.diagnostics.node_count,
            mip_best_bound = ismissing(result.diagnostics.best_bound) ? nothing :
                result.diagnostics.best_bound,
            mip_reported_gap = ismissing(result.diagnostics.reported_relative_gap) ? nothing :
                result.diagnostics.reported_relative_gap,
            dp_state_count = nothing,
            dp_transition_count = nothing,
            frontier_check_count = nothing,
            closure_check_count = nothing,
            preprocessing_variables_removed = result.preprocessing.variables_removed,
            preprocessing_requirements_removed = result.preprocessing.requirements_removed,
        )
    elseif result isa JournalGreedySolutionResult
        check = result.final_certificate
        return (
            status = "SOLVED",
            solved = true,
            evidence_class = "exact finite greedy heuristic computation",
            exact_burden = encode_exact_rational(result.exact_burden),
            selected = result.selected,
            mandatory_retained = check.mandatory_retained,
            tagged_coverage = check.tagged_coverage,
            frontier_preserved = check.frontier_preserved,
            closure_preserved = check.closure_preserved,
            burden_reconciled = check.burden_reconciled,
            mip_node_count = nothing,
            mip_best_bound = nothing,
            mip_reported_gap = nothing,
            dp_state_count = nothing,
            dp_transition_count = nothing,
            frontier_check_count = nothing,
            closure_check_count = nothing,
            preprocessing_variables_removed = nothing,
            preprocessing_requirements_removed = nothing,
        )
    elseif result isa JournalDeletionSolutionResult
        check = result.final_feasibility_certificate
        return (
            status = "SOLVED",
            solved = true,
            evidence_class = "exact finite rechecked-deletion heuristic computation",
            exact_burden = encode_exact_rational(result.exact_burden),
            selected = result.selected,
            mandatory_retained = check.mandatory_retained,
            tagged_coverage = check.tagged_coverage,
            frontier_preserved = check.frontier_preserved,
            closure_preserved = check.closure_preserved,
            burden_reconciled = check.burden_reconciled,
            mip_node_count = nothing,
            mip_best_bound = nothing,
            mip_reported_gap = nothing,
            dp_state_count = nothing,
            dp_transition_count = nothing,
            frontier_check_count = string(result.counters.frontier_checks),
            closure_check_count = string(result.counters.closure_checks),
            preprocessing_variables_removed = nothing,
            preprocessing_requirements_removed = nothing,
        )
    end
    error("unsupported pilot result type")
end


function _timing_fields(timed, wall_ns)
    names = propertynames(timed)
    compile_time = :compile_time in names ? getproperty(timed, :compile_time) : nothing
    return (
        wall_clock_ns = wall_ns,
        julia_allocated_bytes = timed.bytes,
        gc_time_seconds = timed.gctime,
        compile_time_seconds = compile_time,
        cumulative_process_maxrss_after = isdefined(Sys, :maxrss) ? Sys.maxrss() : nothing,
    )
end


function _base_record(spec, seed, instance, algorithm, positions, limits, started_at, finished_at)
    return Dict{String,Any}(
        "schema_version" => PILOT_SCHEMA_VERSION,
        "experiment_id" => "registered-algorithmic-compression-benchmark-v1",
        "pilot_label" => "IMPLEMENTATION PILOT — EXCLUDED FROM FINAL ANALYSIS",
        "instance_id" => spec.instance_id,
        "phase" => string(spec.phase),
        "analysis_included" => spec.analysis_included,
        "family" => string(spec.family),
        "mechanism" => string(spec.mechanism),
        "replicate_id" => spec.replicate_id,
        "seed_id" => seed.seed_id,
        "generator_seed" => string(seed.generator_seed),
        "random_order_seed" => string(seed.random_order_seed),
        "multistart_seed" => string(seed.multistart_seed),
        "mip_seed" => string(seed.mip_seed),
        "instance_sha256" => journal_compression_instance_sha256(instance),
        "input_artifact_path" => _relative(joinpath(PILOT_ROOT, "instances", "$(spec.instance_id).toml")),
        "algorithm_id" => string(algorithm),
        "preprocessing_variant" => algorithm == :jump_highs_tagged_cover ?
            "full_fixed_point" : "mandatory_only",
        "registry_position" => positions.registry_position,
        "instance_execution_position" => positions.instance_execution_position,
        "algorithm_execution_position" => positions.algorithm_execution_position,
        "tie_rule" => instance.tie_handling.declaration,
        "registered_time_limit_seconds" => limits.time,
        "time_limit_enforced" => algorithm == :jump_highs_tagged_cover,
        "registered_memory_limit_bytes" => limits.memory,
        "memory_limit_enforced" => false,
        "peak_memory_bytes" => "UNAVAILABLE",
        "started_at_utc" => started_at,
        "finished_at_utc" => finished_at,
    )
end


function _write_not_applicable_record(spec, seed, instance, algorithm, positions, limits)
    started_at = _utc_now()
    record = _base_record(
        spec,
        seed,
        instance,
        algorithm,
        positions,
        limits,
        started_at,
        started_at,
    )
    record["applicable"] = false
    record["status"] = "NOT_APPLICABLE"
    record["reason"] = algorithm == :complete_enumeration ?
        "registry marks exact_enumeration_required=false for this pilot row" :
        "registry marks this method inapplicable"
    path = joinpath(PILOT_ROOT, "records", spec.instance_id, "$(algorithm).toml")
    text = _write_toml(path, record)
    return (
        instance_id = spec.instance_id,
        phase = string(spec.phase),
        family = string(spec.family),
        mechanism = string(spec.mechanism),
        strategy_count = spec.strategy_count,
        tagged_requirement_count = spec.tagged_requirement_count,
        algorithm_id = string(algorithm),
        registry_position = positions.registry_position,
        instance_execution_position = positions.instance_execution_position,
        algorithm_execution_position = positions.algorithm_execution_position,
        applicable = false,
        status = "NOT_APPLICABLE",
        solved = false,
        evidence_class = "not applicable by prospective registry",
        exact_burden = nothing,
        wall_clock_ns = nothing,
        julia_allocated_bytes = nothing,
        gc_time_seconds = nothing,
        compile_time_seconds = nothing,
        time_limit_seconds = limits.time,
        time_limit_enforced = false,
        memory_limit_bytes = limits.memory,
        memory_limit_enforced = false,
        peak_memory_bytes = nothing,
        peak_memory_status = "UNAVAILABLE",
        mip_node_count = nothing,
        mip_best_bound = nothing,
        mip_reported_gap = nothing,
        dp_state_count = nothing,
        dp_transition_count = nothing,
        frontier_check_count = nothing,
        closure_check_count = nothing,
        preprocessing_variables_removed = nothing,
        preprocessing_requirements_removed = nothing,
        record_path = _relative(path),
        record_sha256 = _sha256_text(text),
        log_path = nothing,
        log_sha256 = nothing,
        failure_code = nothing,
    )
end


function _run_one(spec, seed, instance, algorithm, positions, limits, config)
    GC.gc()
    started_at = _utc_now()
    started_ns = time_ns()
    try
        timed = @timed _execute_algorithm(
            instance,
            spec,
            seed,
            algorithm,
            limits.time,
            config,
        )
        wall_ns = time_ns() - started_ns
        finished_at = _utc_now()
        result = timed.value
        summary = _result_summary(result, wall_ns)
        exact_check = check_journal_compression_solution(instance, summary.selected)
        all((
            exact_check.exact_feasible,
            summary.mandatory_retained,
            summary.tagged_coverage,
            summary.frontier_preserved,
            summary.closure_preserved,
            summary.burden_reconciled,
        )) || error("pilot result failed independent exact common-instance recheck")
        timing = _timing_fields(timed, wall_ns)
        record = _base_record(
            spec,
            seed,
            instance,
            algorithm,
            positions,
            limits,
            started_at,
            finished_at,
        )
        record["applicable"] = true
        record["status"] = summary.status
        record["solved"] = summary.solved
        record["evidence_class"] = summary.evidence_class
        record["exact_burden"] = summary.exact_burden
        record["wall_clock_ns"] = Int(timing.wall_clock_ns)
        record["julia_allocated_bytes"] = timing.julia_allocated_bytes
        record["gc_time_seconds"] = timing.gc_time_seconds
        record["compile_time_seconds"] = isnothing(timing.compile_time_seconds) ?
            "UNAVAILABLE" : timing.compile_time_seconds
        record["cumulative_process_maxrss_after"] = isnothing(
            timing.cumulative_process_maxrss_after,
        ) ? "UNAVAILABLE" : timing.cumulative_process_maxrss_after
        record["exact_recheck"] = _serializable(exact_check)
        record["method_result"] = _result_payload(result)
        log_path = nothing
        log_sha = nothing
        if result isa JournalMIPSolutionResult
            log_path = joinpath(PILOT_ROOT, "solver_logs", "$(spec.instance_id).log")
            mkpath(dirname(log_path))
            open(log_path, "w") do io
                write(io, result.diagnostics.complete_solver_log)
            end
            log_sha = _sha256_file(log_path)
            record["complete_solver_log_path"] = _relative(log_path)
            record["complete_solver_log_sha256"] = log_sha
        end
        path = joinpath(PILOT_ROOT, "records", spec.instance_id, "$(algorithm).toml")
        text = _write_toml(path, record)
        return (
            run = (
                instance_id = spec.instance_id,
                phase = string(spec.phase),
                family = string(spec.family),
                mechanism = string(spec.mechanism),
                strategy_count = spec.strategy_count,
                tagged_requirement_count = spec.tagged_requirement_count,
                algorithm_id = string(algorithm),
                registry_position = positions.registry_position,
                instance_execution_position = positions.instance_execution_position,
                algorithm_execution_position = positions.algorithm_execution_position,
                applicable = true,
                status = summary.status,
                solved = summary.solved,
                evidence_class = summary.evidence_class,
                exact_burden = summary.exact_burden,
                wall_clock_ns = timing.wall_clock_ns,
                julia_allocated_bytes = timing.julia_allocated_bytes,
                gc_time_seconds = timing.gc_time_seconds,
                compile_time_seconds = timing.compile_time_seconds,
                time_limit_seconds = limits.time,
                time_limit_enforced = algorithm == :jump_highs_tagged_cover,
                memory_limit_bytes = limits.memory,
                memory_limit_enforced = false,
                peak_memory_bytes = nothing,
                peak_memory_status = "UNAVAILABLE",
                mip_node_count = summary.mip_node_count,
                mip_best_bound = summary.mip_best_bound,
                mip_reported_gap = summary.mip_reported_gap,
                dp_state_count = summary.dp_state_count,
                dp_transition_count = summary.dp_transition_count,
                frontier_check_count = summary.frontier_check_count,
                closure_check_count = summary.closure_check_count,
                preprocessing_variables_removed = summary.preprocessing_variables_removed,
                preprocessing_requirements_removed = summary.preprocessing_requirements_removed,
                record_path = _relative(path),
                record_sha256 = _sha256_text(text),
                log_path = isnothing(log_path) ? nothing : _relative(log_path),
                log_sha256 = log_sha,
                failure_code = summary.solved ? nothing : summary.status,
            ),
            failure = nothing,
        )
    catch error
        finished_at = _utc_now()
        wall_ns = time_ns() - started_ns
        record = _base_record(
            spec,
            seed,
            instance,
            algorithm,
            positions,
            limits,
            started_at,
            finished_at,
        )
        record["applicable"] = true
        record["status"] = "IMPLEMENTATION_ERROR"
        record["solved"] = false
        record["failure_code"] = "IMPLEMENTATION_ERROR"
        record["exception_type"] = string(typeof(error))
        record["message"] = sprint(showerror, error)
        record["wall_clock_ns"] = Int(wall_ns)
        path = joinpath(PILOT_ROOT, "records", spec.instance_id, "$(algorithm).toml")
        text = _write_toml(path, record)
        run = (
            instance_id = spec.instance_id,
            phase = string(spec.phase),
            family = string(spec.family),
            mechanism = string(spec.mechanism),
            strategy_count = spec.strategy_count,
            tagged_requirement_count = spec.tagged_requirement_count,
            algorithm_id = string(algorithm),
            registry_position = positions.registry_position,
            instance_execution_position = positions.instance_execution_position,
            algorithm_execution_position = positions.algorithm_execution_position,
            applicable = true,
            status = "IMPLEMENTATION_ERROR",
            solved = false,
            evidence_class = "pilot implementation failure",
            exact_burden = nothing,
            wall_clock_ns = wall_ns,
            julia_allocated_bytes = nothing,
            gc_time_seconds = nothing,
            compile_time_seconds = nothing,
            time_limit_seconds = limits.time,
            time_limit_enforced = algorithm == :jump_highs_tagged_cover,
            memory_limit_bytes = limits.memory,
            memory_limit_enforced = false,
            peak_memory_bytes = nothing,
            peak_memory_status = "UNAVAILABLE",
            mip_node_count = nothing,
            mip_best_bound = nothing,
            mip_reported_gap = nothing,
            dp_state_count = nothing,
            dp_transition_count = nothing,
            frontier_check_count = nothing,
            closure_check_count = nothing,
            preprocessing_variables_removed = nothing,
            preprocessing_requirements_removed = nothing,
            record_path = _relative(path),
            record_sha256 = _sha256_text(text),
            log_path = nothing,
            log_sha256 = nothing,
            failure_code = "IMPLEMENTATION_ERROR",
        )
        failure = (
            instance_id = spec.instance_id,
            algorithm_id = string(algorithm),
            failure_code = "IMPLEMENTATION_ERROR",
            exception_type = string(typeof(error)),
            message = sprint(showerror, error),
            record_path = _relative(path),
            record_sha256 = _sha256_text(text),
        )
        return (; run, failure)
    end
end


function _pilot_manifest_payload(started_at, finished_at)
    files = sort!(String[
        path for (root, _, names) in walkdir(PILOT_ROOT) for name in names for
        path in [joinpath(root, name)] if path != MANIFEST_PATH
    ])
    return Dict{String,Any}(
        "schema_version" => PILOT_MANIFEST_SCHEMA_VERSION,
        "pilot_label" => "IMPLEMENTATION PILOT — EXCLUDED FROM FINAL ANALYSIS",
        "started_at_utc" => started_at,
        "finished_at_utc" => finished_at,
        "pilot_seed_scope_only" => true,
        "final_seed_used" => false,
        "file_count" => length(files),
        "files" => [
            Dict{String,Any}(
                "path" => _relative(path),
                "sha256" => _sha256_file(path),
                "bytes" => filesize(path),
            ) for path in files
        ],
    )
end


"""Run each registered algorithm once on the 11 registered pilot rows only."""
function run_pilot()
    ispath(PILOT_ROOT) && error(
        "pilot output directory already exists; registered pilot runs are never overwritten",
    )
    isfile(INITIAL_LOCK_PATH) || error("initial design lock is absent")
    verify_design_lock(CONFIG_PATH)
    config = TOML.parsefile(CONFIG_PATH)
    string(VERSION) == String(config["julia_version"]) || error(
        "pilot requires Julia $(config["julia_version"]), observed $(VERSION)",
    )
    Threads.nthreads() == Int(config["execution"]["julia_threads"]) || error(
        "pilot Julia thread count differs from registration",
    )
    LinearAlgebra.BLAS.set_num_threads(Int(config["execution"]["blas_threads"]))
    registries = load_algorithmic_benchmark_registries()
    pilot_indices = findall(spec -> spec.phase == :pilot, registries.instances)
    length(pilot_indices) == Int(config["counts"]["pilot_instances"]) || error(
        "pilot registry row count changed",
    )
    pilot_pairs = [
        (
            registry_position = position,
            spec = registries.instances[position],
            seed = registries.seeds[position],
        ) for position in pilot_indices
    ]
    sort!(pilot_pairs; by = row -> row.seed.execution_order_key)
    all(row -> row.spec.phase == :pilot && !row.spec.analysis_included, pilot_pairs) ||
        error("nonpilot or analysis-included row entered pilot")
    pilot_seed_values = Set(
        value for row in pilot_pairs for value in (
            row.seed.generator_seed,
            row.seed.random_order_seed,
            row.seed.multistart_seed,
            row.seed.mip_seed,
        )
    )
    final_seed_values = Set(
        value for (spec, seed) in zip(registries.instances, registries.seeds) if
        spec.phase == :final for value in (
            seed.generator_seed,
            seed.random_order_seed,
            seed.multistart_seed,
            seed.mip_seed,
        )
    )
    isempty(intersect(pilot_seed_values, final_seed_values)) || error(
        "pilot/final seed overlap detected",
    )

    started_at = _utc_now()
    mkpath(PILOT_ROOT)
    environment = _hardware_environment(started_at)
    environment["pilot_instance_count"] = length(pilot_pairs)
    environment["registered_algorithm_count"] = length(ALGORITHM_IDS)
    environment["pilot_seed_value_count_used"] = length(pilot_seed_values)
    environment["final_seed_used"] = false
    environment["runner_sha256"] = _sha256_file(@__FILE__)
    _write_toml(ENVIRONMENT_PATH, environment)

    run_rows = NamedTuple[]
    failure_rows = NamedTuple[]
    for (execution_position, row) in enumerate(pilot_pairs)
        generated = generate_algorithmic_benchmark_instance(row.spec, row.seed)
        generated isa AlgorithmicGeneratedInstance || error(
            "registered pilot generation failed for $(row.spec.instance_id)",
        )
        instance = generated.instance
        instance_path = joinpath(PILOT_ROOT, "instances", "$(row.spec.instance_id).toml")
        generation_path = joinpath(PILOT_ROOT, "generation", "$(row.spec.instance_id).toml")
        _write_toml(instance_path, TOML.parse(serialize_journal_compression_instance(instance)))
        _write_toml(generation_path, TOML.parse(serialize_algorithmic_generation_record(generated)))
        rotation = mod(row.registry_position - first(pilot_indices), length(ALGORITHM_IDS))
        order = circshift(collect(ALGORITHM_IDS), -rotation)
        for (algorithm_position, algorithm) in enumerate(order)
            positions = (
                registry_position = row.registry_position,
                instance_execution_position = execution_position,
                algorithm_execution_position = algorithm_position,
            )
            limits = (
                time = _algorithm_limit(config, row.spec, algorithm),
                memory = _memory_limit_bytes(config, row.spec),
            )
            if !_algorithm_applicable(row.spec, algorithm)
                push!(
                    run_rows,
                    _write_not_applicable_record(
                        row.spec,
                        row.seed,
                        instance,
                        algorithm,
                        positions,
                        limits,
                    ),
                )
                continue
            end
            outcome = _run_one(
                row.spec,
                row.seed,
                instance,
                algorithm,
                positions,
                limits,
                config,
            )
            push!(run_rows, outcome.run)
            !isnothing(outcome.failure) && push!(failure_rows, outcome.failure)
        end
    end
    length(run_rows) == length(pilot_pairs) * length(ALGORITHM_IDS) || error(
        "pilot did not emit one status row per instance-algorithm pair",
    )
    sort!(
        run_rows;
        by = row -> (
            row.instance_execution_position,
            row.algorithm_execution_position,
        ),
    )
    _write_csv(RUNS_PATH, run_rows, RUN_COLUMNS)
    _write_csv(FAILURES_PATH, failure_rows, FAILURE_COLUMNS)
    finished_at = _utc_now()
    first_mip_row = first(
        row for row in run_rows if
        row.algorithm_id == string(:jump_highs_tagged_cover) && row.applicable
    )
    first_mip_record = TOML.parsefile(joinpath(REPOSITORY_ROOT, first_mip_row.record_path))
    environment["highs_solver_version"] = first_mip_record["method_result"]["solver_diagnostics"]["solver_version"]
    environment["finished_at_utc"] = finished_at
    _write_toml(ENVIRONMENT_PATH, environment)
    _write_toml(MANIFEST_PATH, _pilot_manifest_payload(started_at, finished_at))
    println(
        "pilot complete: instances=$(length(pilot_pairs)), " *
        "status_rows=$(length(run_rows)), failures=$(length(failure_rows)); " *
        "final seeds used=false",
    )
    return (; run_rows, failure_rows)
end


function _parse_csv(path, columns)
    lines = readlines(path)
    isempty(lines) && error("empty CSV: $path")
    Tuple(Symbol.(split(first(lines), ','))) == columns || error(
        "CSV header changed: $path",
    )
    # Generated values containing commas are quoted; validation of row counts
    # uses the record files and manifest rather than reparsing quoted CSV here.
    return length(lines) - 1
end


"""Nonmutating validation of pilot scope, hashes, records, and seed separation."""
function check_pilot_outputs()
    for path in (RUNS_PATH, FAILURES_PATH, ENVIRONMENT_PATH, MANIFEST_PATH)
        isfile(path) || error("missing pilot artifact: $(_relative(path))")
    end
    _parse_csv(RUNS_PATH, RUN_COLUMNS) == 143 || error(
        "pilot run status CSV must contain 143 rows",
    )
    manifest = TOML.parsefile(MANIFEST_PATH)
    manifest["schema_version"] == PILOT_MANIFEST_SCHEMA_VERSION || error(
        "unsupported pilot manifest schema",
    )
    manifest["pilot_seed_scope_only"] === true || error("pilot seed scope changed")
    manifest["final_seed_used"] === false || error("final seed entered pilot")
    for row in manifest["files"]
        path = joinpath(REPOSITORY_ROOT, String(row["path"]))
        isfile(path) || error("manifested pilot file is missing: $(row["path"])")
        _sha256_file(path) == row["sha256"] || error(
            "pilot artifact hash mismatch: $(row["path"])",
        )
        filesize(path) == Int(row["bytes"]) || error(
            "pilot artifact size mismatch: $(row["path"])",
        )
    end
    record_paths = String[
        path for (root, _, names) in walkdir(joinpath(PILOT_ROOT, "records")) for
        name in names for path in [joinpath(root, name)] if endswith(name, ".toml")
    ]
    length(record_paths) == 143 || error("pilot must contain 143 run records")
    for path in record_paths
        record = TOML.parsefile(path)
        record["schema_version"] == PILOT_SCHEMA_VERSION || error(
            "pilot run schema mismatch: $(_relative(path))",
        )
        record["phase"] == "pilot" || error("nonpilot run record detected")
        record["analysis_included"] === false || error(
            "pilot record entered analysis population",
        )
    end
    registries = load_algorithmic_benchmark_registries()
    pilot = Set(
        value for (spec, seed) in zip(registries.instances, registries.seeds) if
        spec.phase == :pilot for value in (
            seed.generator_seed,
            seed.random_order_seed,
            seed.multistart_seed,
            seed.mip_seed,
        )
    )
    final = Set(
        value for (spec, seed) in zip(registries.instances, registries.seeds) if
        spec.phase == :final for value in (
            seed.generator_seed,
            seed.random_order_seed,
            seed.multistart_seed,
            seed.mip_seed,
        )
    )
    isempty(intersect(pilot, final)) || error("pilot and final seed domains overlap")
    println("pilot artifacts verified: 11 instances, 143 status records, final seeds used=false")
    return true
end


function main(args = ARGS)
    mode = isempty(args) ? "--check" : only(args)
    mode == "--run" && return run_pilot()
    mode == "--check" && return check_pilot_outputs()
    error("usage: run_algorithmic_compression_pilot_v1.jl [--run|--check]")
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    AlgorithmicCompressionPilotV1.main()
end
