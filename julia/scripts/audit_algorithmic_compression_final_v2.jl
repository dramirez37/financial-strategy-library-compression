module AuditAlgorithmicCompressionFinalV2

using SHA: sha256
using StrategyInnovation
using TOML

include(joinpath(@__DIR__, "run_algorithmic_compression_final_v2.jl"))
using .AlgorithmicCompressionFinalV2

export audit_final_benchmark, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const STUDY_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "algorithmic_compression_v2",
)
const RESULTS_ROOT = joinpath(STUDY_ROOT, "results")
const AUDIT_ROOT = joinpath(RESULTS_ROOT, "audit")
const EXECUTION_RECORD_PATH = joinpath(STUDY_ROOT, "EXECUTION_RECORD.md")
const RESULT_AUDIT_PATH = joinpath(STUDY_ROOT, "RESULT_AUDIT.md")
const FAILURE_LOG_PATH = joinpath(STUDY_ROOT, "FAILURE_LOG.md")
const AUDIT_SCHEMA_VERSION = "algorithmic-compression-final-audit-v2"


_relative(path) = relpath(path, REPOSITORY_ROOT)


function _sha256_file(path::AbstractString)
    return open(path, "r") do io
        bytes2hex(sha256(io))
    end
end


function _write_replace(path::AbstractString, text::AbstractString)
    mkpath(dirname(path))
    temporary = path * ".replace.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, path; force = true)
    return text
end


function _write_replace_toml(path, payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return _write_replace(path, String(take!(io)))
end


function _exact_rational(text::AbstractString)
    pieces = split(text, "//")
    length(pieces) == 2 || error("noncanonical exact rational: $text")
    denominator_value = parse(BigInt, pieces[2])
    denominator_value > 0 || error("nonpositive exact denominator: $text")
    return parse(BigInt, pieces[1]) // denominator_value
end


function _execution_lock_payload(path)
    text = read(path, String)
    aggregate_match = match(r"\"aggregate_sha256\"\s*:\s*\"([0-9a-f]{64})\"", text)
    isnothing(aggregate_match) && error("execution lock has no aggregate SHA-256")
    occursin("\"runner_gate_status\": \"READY\"", text) || error(
        "execution lock runner gate is not READY",
    )
    return Dict{String,Any}("aggregate_sha256" => aggregate_match.captures[1])
end


function _require_file(path, errors)
    if !isfile(path)
        push!(errors, "missing required artifact: $(_relative(path))")
        return false
    end
    return true
end


function _record_solution_audit(instance, record, errors, label)
    accepted = get(record, "candidate_accepted", false)
    accepted || return (
        accepted = false,
        exact_feasible = missing,
        exact_burden = missing,
        selected_indices = Int[],
    )
    worker = get(record, "worker", nothing)
    if isnothing(worker)
        push!(errors, "$label accepts a candidate but has no worker certificate")
        return (
            accepted = true,
            exact_feasible = false,
            exact_burden = missing,
            selected_indices = Int[],
        )
    end
    selected_indices = Int.(get(worker, "selected_original_strategy_indices", Int[]))
    if isempty(selected_indices)
        push!(errors, "$label accepts a candidate but returns no selected indices")
        return (
            accepted = true,
            exact_feasible = false,
            exact_burden = missing,
            selected_indices,
        )
    end
    if length(unique(selected_indices)) != length(selected_indices) ||
       any(index -> !(index in eachindex(instance.strategy_ids)), selected_indices)
        push!(errors, "$label has invalid selected indices")
        return (
            accepted = true,
            exact_feasible = false,
            exact_burden = missing,
            selected_indices,
        )
    end
    selected = falses(length(instance.strategy_ids))
    selected[selected_indices] .= true
    burden_payload = get(worker, "exact_burden", Dict{String,Any}())
    if get(burden_payload, "available", false) !== true
        push!(errors, "$label accepts a candidate without exact burden")
        expected_burden = nothing
    else
        expected_burden = _exact_rational(String(burden_payload["value"]))
    end
    check = isnothing(expected_burden) ?
        check_journal_compression_solution(instance, selected) :
        check_journal_compression_solution(
            instance,
            selected;
            expected_burden,
        )
    if !check.exact_feasible
        push!(errors, "$label fails independent exact feasibility")
    end
    if !isnothing(expected_burden) && check.exact_burden != expected_burden
        push!(errors, "$label exact burden does not reconcile")
    end
    saved = get(worker, "exact_feasibility_recheck", Dict{String,Any}())
    for field in (
        "mandatory_retained",
        "tagged_coverage",
        "frontier_preserved",
        "closure_preserved",
        "burden_reconciled",
        "exact_feasible",
    )
        get(saved, field, false) === true || push!(
            errors,
            "$label saved exact certificate field $field is not true",
        )
    end
    return (
        accepted = true,
        exact_feasible = check.exact_feasible,
        exact_burden = check.exact_burden,
        selected_indices,
    )
end


function _mip_is_conclusive(record)
    get(record, "candidate_accepted", false) || return false
    worker = get(record, "worker", Dict{String,Any}())
    method = get(worker, "method_result", Dict{String,Any}())
    return get(method, "solver_claimed_optimal", false) === true ||
           get(worker, "status", "") == "SOLVED_BY_EXACT_PREPROCESSING"
end


function _registered_expected(readiness)
    rows = [(;
        item.spec,
        item.unit,
        item.worker_lane,
        item.lane_position,
        item.global_schedule_position,
        item.launch_wave,
    ) for item in readiness.schedule]
    sort!(rows; by = row -> (
        row.spec.instance_id,
        string(row.unit.algorithm),
        string(row.unit.variant),
    ))
    return rows
end


function _raw_manifest_paths()
    roots = String[
        joinpath(RESULTS_ROOT, "EXECUTION_START_LOCK.json"),
        joinpath(RESULTS_ROOT, "environment.toml"),
        joinpath(RESULTS_ROOT, "execution_state.toml"),
        joinpath(RESULTS_ROOT, "final_algorithm_runs.csv"),
    ]
    for optional in (
        AlgorithmicCompressionFinalV2.EXECUTION_LOCK_AMENDMENT_PATH,
        AlgorithmicCompressionFinalV2.ENVIRONMENT_AMENDMENT_PATH,
    )
        isfile(optional) && push!(roots, optional)
    end
    for directory in ("instances", "generation", "raw_runs", "solver_logs", "control")
        root = joinpath(RESULTS_ROOT, directory)
        isdir(root) || continue
        for (walk_root, _, files) in walkdir(root)
            for file in files
                push!(roots, joinpath(walk_root, file))
            end
        end
    end
    sort!(unique!(roots))
    return roots
end


function _manifest_csv(paths)
    io = IOBuffer()
    println(io, "relative_path,bytes,sha256")
    for path in paths
        relative = _relative(path)
        println(io, relative, ',', filesize(path), ',', _sha256_file(path))
    end
    return String(take!(io))
end


function _status_table(status_counts)
    io = IOBuffer()
    println(io, "| Terminal status | Count |")
    println(io, "|---|---:|")
    for status in sort!(collect(keys(status_counts)))
        println(io, "| `", status, "` | ", status_counts[status], " |")
    end
    return String(take!(io))
end


function _execution_record(environment, execution_lock, total, accepted, unsuccessful, status_counts)
    dirty = environment["dirty_worktree"] ? "yes" : "no"
    return """# Registered Algorithmic Compression Benchmark v2 — execution record

## Outcome

The registered final runner produced $total terminal run records. Exactly
$accepted records contain returned libraries that were independently rechecked;
$unsuccessful records contain no accepted library. These counts are execution
facts, not interpretive performance claims.

## Reproducibility envelope

| Field | Recorded value |
|---|---|
| Design lock | `$(execution_lock["aggregate_sha256"])` |
| Git commit at execution start | `$(environment["git_commit"])` |
| Dirty worktree at execution start | $dirty |
| Dirty-status hash | `$(environment["dirty_worktree_status_sha256"])` |
| Julia | `$(environment["julia_version"])` |
| Manifest SHA-256 | `$(environment["dependency_manifest_sha256"])` |
| Operating system | $(environment["operating_system"]) |
| Kernel / architecture | `$(environment["kernel_version"])` / `$(environment["architecture"])` |
| CPU | $(environment["cpu"]) |
| RAM (bytes) | `$(environment["ram_bytes"])` |
| HiGHS / HiGHS.jl / JuMP | `$(environment["highs_version"])` / `$(environment["highs_julia_version"])` / `$(environment["jump_version"])` |
| Julia / BLAS / HiGHS threads | $(environment["julia_threads"]) / $(environment["blas_threads"]) / $(environment["highs_threads"]) |
| Process concurrency | $(environment["process_concurrency"]) |
| UTC start | `$(environment["start_time_utc"])` |
| UTC end | `$(environment["end_time_utc"])` |

The machine identifier is stored only as `$(environment["machine_id"])`.
The raw dirty-worktree paths are retained in `results/environment.toml`.

## Registered execution controls

The runner used final registry rows only, deterministic registry schedule-key
order, the registered Latin rotation, one process at a time, exact registered
seeds, registered size-class time limits, and a 16 GiB process cap. It requested
a full garbage collection before each timing handshake. All HiGHS runs used one
thread, parallel mode off, presolve on, zero relative and absolute MIP gap
tolerances, and their registered MIP seed. The mandatory-only MIP formulation is
implemented in the locked external runner because the committed package MIP API
exposes the registered full fixed-point formulation; both variants reconstruct
in original coordinates and undergo the same exact post-check.

## Terminal-record census

$(_status_table(status_counts))

The raw matrix is `results/final_algorithm_runs.csv`. Per-run TOML records,
worker handshakes, stdout/stderr, solver logs, generated instances, generation
records, and hashes are retained below `results/`.

## Commands

```text
make aor-benchmark
make aor-benchmark-audit
```
"""
end


function _result_audit_report(summary, status_counts, manifest_hash)
    pass_text = summary["passed"] ? "PASS" : "FAIL"
    return """# Registered Algorithmic Compression Benchmark v2 — result audit

## Audit verdict

**$pass_text.** The independent artifact audit read saved instances and raw run
records; it did not rerun a solver or heuristic. It reconstructed every returned
selection in original strategy coordinates and recomputed mandatory retention,
tagged coverage, source-frontier equality, identity-closure equality, and exact
burden using repository exact arithmetic.

| Audit quantity | Count |
|---|---:|
| Expected terminal run units | $(summary["expected_run_count"]) |
| Raw terminal records found | $(summary["terminal_run_count"]) |
| Accepted solutions exactly rechecked | $(summary["accepted_solution_count"]) |
| Exact-capable instances checked | $(summary["exact_instance_count"]) |
| Exact objective agreements | $(summary["exact_agreement_count"]) |
| Exact comparisons unavailable after recorded failure | $(summary["exact_agreement_unavailable_count"]) |
| Equal-objective optimizer-identity differences | $(summary["optimizer_identity_difference_count"]) |
| MIP records | $(summary["mip_record_count"]) |
| MIP solver logs retained | $(summary["mip_solver_log_count"]) |
| Audit errors | $(summary["error_count"]) |

## Terminal outcomes retained in denominators

$(_status_table(status_counts))

An unsuccessful terminal record is not treated as a missing row. Solver
`OPTIMAL` remains mixed-integer solver evidence; this audit does not relabel it
as exhaustive search or formal proof. Exact comparison certificates are stored
under `results/audit/certificates/`. The SHA-256 manifest is
`results/ARTIFACT_MANIFEST.csv` (manifest file hash `$manifest_hash`).

## Limits

No second open-source MIP solver is pinned in the registered environment. Medium
and large instances therefore receive exact feasibility and burden rechecks plus
saved HiGHS bounds/status/log diagnostics, not a second-solver optimality claim.
Where an exact method or MIP run ended unsuccessfully, agreement is explicitly
unavailable rather than inferred.
"""
end


function _failure_report(failures, errors)
    io = IOBuffer()
    println(io, "# Registered Algorithmic Compression Benchmark v2 — failure log")
    println(io)
    println(io, "This log lists every terminal run without an accepted library and every audit error. Rows remain in all registered denominators.")
    println(io)
    println(io, "## Unsuccessful terminal runs")
    println(io)
    if isempty(failures)
        println(io, "None.")
    else
        println(io, "| Instance | Algorithm | Preprocessing | Status | Failure code | Raw record |")
        println(io, "|---|---|---|---|---|---|")
        for row in failures
            println(
                io,
                "| `$(row.instance_id)` | `$(row.algorithm)` | `$(row.variant)` | `$(row.status)` | `$(row.failure_code)` | `$(row.path)` |",
            )
        end
    end
    println(io)
    println(io, "## Audit errors")
    println(io)
    if isempty(errors)
        println(io, "None.")
    else
        for error in errors
            println(io, "- ", error)
        end
    end
    return String(take!(io))
end


function audit_final_benchmark()
    readiness = validate_final_runner_readiness()
    errors = String[]
    active_execution_lock = isfile(
        AlgorithmicCompressionFinalV2.EXECUTION_LOCK_AMENDMENT_PATH,
    ) ? AlgorithmicCompressionFinalV2.EXECUTION_LOCK_AMENDMENT_PATH :
        AlgorithmicCompressionFinalV2.EXECUTION_LOCK_PATH
    active_environment = AlgorithmicCompressionFinalV2._active_environment_path()
    for path in (
        active_execution_lock,
        active_environment,
        AlgorithmicCompressionFinalV2.RUN_STATUS_PATH,
        joinpath(RESULTS_ROOT, "execution_state.toml"),
    )
        _require_file(path, errors)
    end
    isempty(errors) || error(join(errors, '\n'))
    execution_lock = _execution_lock_payload(
        active_execution_lock,
    )
    environment = TOML.parsefile(active_environment)
    environment["end_time_utc"] != "PENDING" || push!(errors, "execution end time is pending")
    get(environment, "process_concurrency", 0) == 8 || push!(
        errors,
        "recorded process concurrency is not eight",
    )
    get(environment, "worker_julia_threads", 0) == 1 || push!(
        errors,
        "recorded worker Julia thread count is not one",
    )
    expected = _registered_expected(readiness)
    length(expected) == readiness.total_units || push!(errors, "expected matrix size changed")

    instances = Dict{String,JournalCompressionInstance}()
    audited = Dict{Tuple{String,Symbol,Symbol},NamedTuple}()
    status_counts = Dict{String,Int}()
    failures = NamedTuple[]
    accepted_count = 0
    mip_count = 0
    mip_log_count = 0
    certificates = Dict{String,Vector{Dict{String,Any}}}()

    for row in expected
        spec = row.spec
        unit = row.unit
        path = AlgorithmicCompressionFinalV2._record_path(
            spec.instance_id,
            unit.algorithm,
            unit.variant,
        )
        label = "$(spec.instance_id)/$(unit.algorithm)/$(unit.variant)"
        if !_require_file(path, errors)
            continue
        end
        record = try
            TOML.parsefile(path)
        catch error
            push!(errors, "$label raw record parse failure: $(sprint(showerror, error))")
            continue
        end
        get(record, "terminal", false) === true || push!(errors, "$label is nonterminal")
        get(record, "analysis_included", false) === true || push!(errors, "$label is excluded")
        get(record, "instance_id", "") == spec.instance_id || push!(errors, "$label instance mismatch")
        get(record, "algorithm_id", "") == string(unit.algorithm) || push!(errors, "$label algorithm mismatch")
        get(record, "preprocessing_variant", "") == string(unit.variant) || push!(errors, "$label preprocessing mismatch")
        get(record, "worker_lane", 0) == row.worker_lane || push!(errors, "$label lane mismatch")
        get(record, "lane_position", 0) == row.lane_position || push!(errors, "$label lane-position mismatch")
        get(record, "global_schedule_position", 0) == row.global_schedule_position || push!(errors, "$label global schedule mismatch")
        get(record, "launch_wave", 0) == row.launch_wave || push!(errors, "$label launch-wave mismatch")
        status = String(get(record, "status", "MISSING_STATUS"))
        status_counts[status] = get(status_counts, status, 0) + 1

        instance_path = joinpath(RESULTS_ROOT, "instances", "$(spec.instance_id).toml")
        solution = (
            accepted = false,
            exact_feasible = missing,
            exact_burden = missing,
            selected_indices = Int[],
        )
        if get(record, "candidate_accepted", false)
            if _require_file(instance_path, errors)
                instance = get!(instances, spec.instance_id) do
                    open(read_journal_compression_instance, instance_path)
                end
                expected_hash = get(record, "instance_sha256", "")
                journal_compression_instance_sha256(instance) == expected_hash || push!(
                    errors,
                    "$label instance hash mismatch",
                )
                solution = _record_solution_audit(instance, record, errors, label)
                solution.exact_feasible === true && (accepted_count += 1)
            end
        else
            push!(failures, (
                instance_id = spec.instance_id,
                algorithm = string(unit.algorithm),
                variant = string(unit.variant),
                status,
                failure_code = String(get(record, "failure_code", "")),
                path = _relative(path),
            ))
        end
        audited[(spec.instance_id, unit.algorithm, unit.variant)] = solution

        if unit.algorithm == :jump_highs_tagged_cover
            mip_count += 1
            if haskey(record, "solver_log_path")
                log_path = joinpath(REPOSITORY_ROOT, record["solver_log_path"])
                if _require_file(log_path, errors)
                    _sha256_file(log_path) == record["solver_log_sha256"] || push!(
                        errors,
                        "$label solver log hash mismatch",
                    )
                    mip_log_count += 1
                end
            elseif get(record, "candidate_accepted", false)
                push!(errors, "$label accepted MIP candidate has no solver log")
            end
        end
        push!(get!(certificates, spec.instance_id, Dict{String,Any}[]), Dict{String,Any}(
            "algorithm_id" => string(unit.algorithm),
            "preprocessing_variant" => string(unit.variant),
            "raw_record_path" => _relative(path),
            "raw_record_sha256" => _sha256_file(path),
            "status" => status,
            "candidate_accepted" => solution.accepted,
            "independent_exact_feasible" => solution.exact_feasible === true,
            "independent_exact_burden" => ismissing(solution.exact_burden) ?
                "UNAVAILABLE" : encode_exact_rational(solution.exact_burden),
            "selected_strategy_indices" => solution.selected_indices,
        ))
    end

    exact_instances = 0
    exact_agreements = 0
    exact_unavailable = 0
    optimizer_differences = 0
    for spec in readiness.registries.instances
        spec.phase == :final || continue
        if spec.exact_enumeration_required && spec.exact_dp_required
            exact_instances += 1
            keys = [
                (spec.instance_id, :complete_enumeration, :mandatory_only),
                (spec.instance_id, :requirement_mask_dp, :mandatory_only),
            ]
            spec.family == :small_exact && push!(
                keys,
                (spec.instance_id, :requirement_mask_dp, :full_fixed_point),
            )
            for variant in (:full_fixed_point, :mandatory_only)
                record_path = AlgorithmicCompressionFinalV2._record_path(
                    spec.instance_id,
                    :jump_highs_tagged_cover,
                    variant,
                )
                isfile(record_path) && _mip_is_conclusive(TOML.parsefile(record_path)) && push!(
                    keys,
                    (spec.instance_id, :jump_highs_tagged_cover, variant),
                )
            end
            outcomes = [get(audited, key, nothing) for key in keys]
            if any(isnothing, outcomes) || any(outcome -> !outcome.accepted, outcomes)
                exact_unavailable += 1
                continue
            end
            burdens = [outcome.exact_burden for outcome in outcomes]
            if !all(burden == first(burdens) for burden in burdens)
                push!(errors, "$(spec.instance_id) exact methods disagree on burden")
                continue
            end
            exact_agreements += 1
            selections = [Tuple(outcome.selected_indices) for outcome in outcomes]
            length(unique(selections)) > 1 && (optimizer_differences += 1)
        end
    end

    for (instance_id, rows) in certificates
        sort!(rows; by = row -> (row["algorithm_id"], row["preprocessing_variant"]))
        instance_path = joinpath(RESULTS_ROOT, "instances", "$instance_id.toml")
        payload = Dict{String,Any}(
            "schema_version" => "algorithmic-compression-final-instance-audit-v2",
            "instance_id" => instance_id,
            "instance_available" => isfile(instance_path),
            "instance_sha256" => isfile(instance_path) ? _sha256_file(instance_path) : "UNAVAILABLE",
            "run_certificates" => rows,
        )
        _write_replace_toml(joinpath(AUDIT_ROOT, "certificates", "$instance_id.toml"), payload)
    end

    expected_count = length(expected)
    found_count = length(audited)
    found_count == expected_count || push!(errors, "terminal raw record count is $found_count, expected $expected_count")
    status_total = sum(values(status_counts); init = 0)
    status_total == expected_count || push!(errors, "status denominator is $status_total, expected $expected_count")
    summary = Dict{String,Any}(
        "schema_version" => AUDIT_SCHEMA_VERSION,
        "passed" => isempty(errors),
        "expected_run_count" => expected_count,
        "terminal_run_count" => found_count,
        "accepted_solution_count" => accepted_count,
        "unsuccessful_run_count" => length(failures),
        "exact_instance_count" => exact_instances,
        "exact_agreement_count" => exact_agreements,
        "exact_agreement_unavailable_count" => exact_unavailable,
        "optimizer_identity_difference_count" => optimizer_differences,
        "mip_record_count" => mip_count,
        "mip_solver_log_count" => mip_log_count,
        "status_counts" => status_counts,
        "error_count" => length(errors),
        "errors" => errors,
        "solver_optimal_status_is_formal_proof" => false,
        "second_solver_status" => "NOT_PINNED",
    )
    _write_replace_toml(joinpath(AUDIT_ROOT, "audit_summary.toml"), summary)

    manifest_paths = _raw_manifest_paths()
    manifest_path = joinpath(RESULTS_ROOT, "ARTIFACT_MANIFEST.csv")
    _write_replace(manifest_path, _manifest_csv(manifest_paths))
    manifest_hash = _sha256_file(manifest_path)
    _write_replace(
        EXECUTION_RECORD_PATH,
        _execution_record(
            environment,
            execution_lock,
            expected_count,
            accepted_count,
            length(failures),
            status_counts,
        ),
    )
    _write_replace(
        RESULT_AUDIT_PATH,
        _result_audit_report(summary, status_counts, manifest_hash),
    )
    _write_replace(FAILURE_LOG_PATH, _failure_report(failures, errors))

    isempty(errors) || error(
        "final benchmark audit failed with $(length(errors)) errors; see $(_relative(FAILURE_LOG_PATH))",
    )
    println(
        "final benchmark audit PASS: terminal=$found_count, accepted=$accepted_count, " *
        "exact_agreements=$exact_agreements, unsuccessful=$(length(failures))",
    )
    return summary
end


function main(args = ARGS)
    isempty(args) || error("usage: audit_algorithmic_compression_final_v2.jl")
    return audit_final_benchmark()
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    AuditAlgorithmicCompressionFinalV2.main()
end
