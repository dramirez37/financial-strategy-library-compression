module FinalizeAlgorithmicCompressionPilotV1

using Printf
using Statistics
using StrategyInnovation
using TOML

include(joinpath(@__DIR__, "run_algorithmic_compression_pilot_v1.jl"))
using .AlgorithmicCompressionPilotV1: check_pilot_outputs

export check_postpilot_documents, main, render_amendment, render_pilot_report

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const STUDY_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "algorithmic_compression_v1",
)
const PILOT_ROOT = joinpath(STUDY_ROOT, "pilot")
const REPORT_PATH = joinpath(STUDY_ROOT, "PILOT_REPORT.md")
const AMENDMENT_PATH = joinpath(STUDY_ROOT, "amendments", "AMENDMENT_001.md")
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "algorithmic_compression_v1.toml",
)
const ALGORITHM_ORDER = (
    "complete_enumeration",
    "requirement_mask_dp",
    "jump_highs_tagged_cover",
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
)


_require(condition::Bool, message::AbstractString) =
    condition ? true : error(message)


function _records()
    root = joinpath(PILOT_ROOT, "records")
    paths = sort!(String[
        joinpath(directory, name) for (directory, _, names) in walkdir(root) for
        name in names if endswith(name, ".toml")
    ])
    return [TOML.parsefile(path) for path in paths]
end


function _status_counts(records)
    counts = Dict{String,Int}()
    for record in records
        status = String(record["status"])
        counts[status] = get(counts, status, 0) + 1
    end
    return counts
end


function _algorithm_rows(records)
    return [
        let
            applicable = filter(
                record -> record["algorithm_id"] == algorithm &&
                          record["applicable"],
                records,
            )
            times = sort!(Float64[
                Int(record["wall_clock_ns"]) / 1.0e9 for record in applicable
            ])
            (
                algorithm,
                attempted = length(applicable),
                solved = count(record -> record["solved"], applicable),
                minimum = minimum(times),
                median = Statistics.median(times),
                maximum = maximum(times),
            )
        end for algorithm in ALGORITHM_ORDER
    ]
end


function _exact_agreement(records)
    exact_ids = Set((
        "complete_enumeration",
        "requirement_mask_dp",
        "jump_highs_tagged_cover",
    ))
    instance_ids = sort!(unique(String(record["instance_id"]) for record in records))
    rows = NamedTuple[]
    for instance_id in instance_ids
        exact = filter(
            record -> record["instance_id"] == instance_id &&
                      record["algorithm_id"] in exact_ids &&
                      record["applicable"],
            records,
        )
        burdens = unique(String(record["exact_burden"]) for record in exact)
        push!(
            rows,
            (
                instance_id,
                applicable_methods = length(exact),
                exact_burden = only(burdens),
                agree = length(burdens) == 1,
            ),
        )
    end
    return rows
end


function _seed_counts()
    registries = load_algorithmic_benchmark_registries()
    pilot_values = Set{Int}()
    final_values = Set{Int}()
    for (spec, seed) in zip(registries.instances, registries.seeds)
        target = spec.phase == :pilot ? pilot_values :
                 spec.phase == :final ? final_values : nothing
        isnothing(target) && continue
        union!(
            target,
            (
                seed.execution_order_key,
                seed.generator_seed,
                seed.random_order_seed,
                seed.multistart_seed,
                seed.mip_seed,
            ),
        )
    end
    _require(isempty(intersect(pilot_values, final_values)), "pilot/final seed overlap")
    return (pilot = length(pilot_values), final = length(final_values))
end


function _join_code(values)
    return join(("`$(value)`" for value in values), ", ")
end


function _format_seconds(value)
    return @sprintf("%.6f", value)
end


function _pilot_facts()
    check_pilot_outputs()
    records = _records()
    _require(length(records) == 143, "unexpected pilot record count")
    environment = TOML.parsefile(joinpath(PILOT_ROOT, "environment.toml"))
    config = TOML.parsefile(CONFIG_PATH)
    statuses = _status_counts(records)
    applicable = filter(record -> record["applicable"], records)
    mips = filter(
        record -> record["algorithm_id"] == "jump_highs_tagged_cover",
        records,
    )
    preprocessing_only = sort!(String[
        record["instance_id"] for record in mips if
        !record["method_result"]["solver_diagnostics"]["solver_invoked"]
    ])
    solver_invoked = length(mips) - length(preprocessing_only)
    exact_agreement = _exact_agreement(records)
    all(row -> row.agree, exact_agreement) || error("exact burden disagreement")
    peak_unavailable = count(
        record -> record["applicable"] &&
                  record["peak_memory_bytes"] == "UNAVAILABLE",
        records,
    )
    nonmip_time_unenforced = count(
        record -> record["applicable"] && !record["time_limit_enforced"],
        records,
    )
    memory_unenforced = count(
        record -> record["applicable"] && !record["memory_limit_enforced"],
        records,
    )
    logs = filter(
        name -> endswith(name, ".log"),
        readdir(joinpath(PILOT_ROOT, "solver_logs")),
    )
    return (
        records,
        environment,
        config,
        statuses,
        applicable_count = length(applicable),
        solved_count = count(record -> record["solved"], applicable),
        preprocessing_only,
        solver_invoked,
        exact_agreement,
        algorithm_rows = _algorithm_rows(records),
        peak_unavailable,
        nonmip_time_unenforced,
        memory_unenforced,
        solver_log_count = length(logs),
        seed_counts = _seed_counts(),
    )
end


function render_pilot_report()
    facts = _pilot_facts()
    env = facts.environment
    config = facts.config
    status_rows = join(
        (
            "| `$(status)` | $(get(facts.statuses, status, 0)) |" for status in
            ("SOLVED", "SOLVED_BY_EXACT_PREPROCESSING", "NOT_APPLICABLE")
        ),
        '\n',
    )
    runtime_rows = join(
        (
            "| `$(row.algorithm)` | $(row.attempted) | $(row.solved) | " *
            "$(_format_seconds(row.minimum)) | $(_format_seconds(row.median)) | " *
            "$(_format_seconds(row.maximum)) |" for row in facts.algorithm_rows
        ),
        '\n',
    )
    exact_rows = join(
        (
            "| `$(row.instance_id)` | $(row.applicable_methods) | " *
            "`$(row.exact_burden)` | yes |" for row in facts.exact_agreement
        ),
        '\n',
    )
    outcomes = config["analysis"]["primary_estimands"]
    algorithms = collect(ALGORITHM_ORDER)
    report_date = first(String(env["finished_at_utc"]), 10)
    return """# Registered Algorithmic Compression Benchmark v1 — Pilot Report

> **IMPLEMENTATION PILOT — EXCLUDED FROM FINAL ANALYSIS.** This report is an
> operational readiness audit. Its timing, solver, preprocessing, and burden
> observations are not final computational evidence and must never enter a
> final-study denominator, figure, table, model, or manuscript result.

Pilot completed on $report_date. The runner emitted all 143 prospectively
required status records for 11 registered pilot instances. All
$(facts.applicable_count) applicable runs returned independently rechecked,
exactly feasible libraries; two enumeration cells were prospectively marked
`NOT_APPLICABLE`. No final seed was used, and the $(facts.seed_counts.pilot)
pilot seed values (including the 11 execution-order keys) are disjoint from the
$(facts.seed_counts.final) final seed values.

The pilot supports freezing the already registered scientific design without
changing the final size grid, algorithms, time limits, memory limit, seeds,
primary outcomes, or analysis rules. It does **not** establish that the final
grid is computationally feasible: the largest pilot structured cell is
`n=32, r=16`, whereas the frozen final grid reaches `n=192, r=64`. Final
execution remains blocked until the registered paired preprocessing variants,
per-process timeout and memory enforcement, and required diagnostic schema pass
the prospective readiness gates in Amendment 001.

## Scope and method

Only registry rows with `phase=pilot` and `analysis_included=false` were
generated. Instances ran in ascending registered execution-order key. The 13
registered algorithms used deterministic Latin rotation, one Julia thread, one
BLAS thread, one HiGHS thread, full garbage collection before each timing scope,
and exact common-instance rechecks after every returned solution. MIP used its
registered limit and exact post-check; non-MIP methods were measured in process
but, as documented below, did not yet have an external limit supervisor.

Evidence labels remain distinct: enumeration and requirement-mask DP are exact
finite computations; HiGHS is mixed-integer solver evidence plus exact
post-check when invoked; fixed-point preprocessing is exact finite computation;
greedy and deletion endpoints are exactly feasible heuristic evidence. No
solver `OPTIMAL` status is treated as formal proof or exhaustive search.

## Hardware and software environment

| Field | Recorded value |
|---|---|
| Machine token | `$(env["machine_id"])` |
| CPU | $(env["cpu_model"]); $(env["physical_core_count"]) physical / $(env["logical_core_count"]) logical cores |
| Installed memory | $(env["installed_memory_bytes"]) bytes |
| OS / kernel / architecture | $(env["operating_system"]); `$(env["kernel_version"])`; `$(env["architecture"])` |
| Julia | `$(env["julia_version"])`; $(env["julia_threads"]) thread; BLAS $(env["blas_threads"]) thread |
| HiGHS solver / wrapper | `$(env["highs_solver_version"])` / `$(env["highs_julia_version"])` |
| JuMP / StableRNGs | `$(env["jump_version"])` / `$(env["stable_rngs_version"])` |
| Recorded source commit | `$(env["git_commit"])` |
| Project / manifest SHA-256 | `$(env["project_toml_sha256"])` / `$(env["manifest_toml_sha256"])` |
| Pilot UTC interval | `$(env["started_at_utc"])` to `$(env["finished_at_utc"])` |

The worktree was recorded dirty and included the then-uncommitted pilot runner;
the runner itself is identified by SHA-256 `$(env["runner_sha256"])`. The
post-pilot lock verifies that this hash still matches the committed runner and
that the tracked algorithm source matches the recorded commit before freezing
the final execution code.

## Completion and exactness checks

| Status | Records |
|---|---:|
$status_rows

All $(facts.solved_count)/$(facts.applicable_count) applicable status records
were solved without an implementation, generation, certificate, solver,
timeout, or recorded memory-failure status. Exact burden agreement held on all
11 pilot instances: exact finite enumeration and DP matched the exactly
rechecked MIP candidate burden on the nine cells where all three applied; exact
finite DP and the rechecked MIP candidate matched on the remaining two. This
burden agreement does not turn MIP solver evidence into exhaustive or formal
proof.

| Instance | Applicable comparison methods | Agreed exact burden | Burdens agree? |
|---|---:|---:|---|
$exact_rows

These burden values are implementation checks only. They are not final evidence
and are not pooled with the registered final study.

## Operational timing diagnostics

The following values are raw pilot runner durations in seconds, shown only to
audit applicability, instrumentation, and gross runtime risk. They are not
algorithm rankings and must not be cited as comparative scientific findings.

| Algorithm | Applicable | Completed | Minimum | Median | Maximum |
|---|---:|---:|---:|---:|---:|
$runtime_rows

Enumeration was prospectively applicable on 9/11 cells; DP and MIP were
applicable on 11/11; every registered greedy and deletion method was applicable
on 11/11. Six MIP cells were solved entirely by exact preprocessing, without
invoking HiGHS: $(_join_code(facts.preprocessing_only)). HiGHS was invoked on
$(facts.solver_invoked)/11 MIP cells, and all invoked cells recorded solver logs.

## Required pilot classifications

| Classification | Finding | Consequence |
|---|---|---|
| Trivial cells | $(_join_code(facts.preprocessing_only)) had empty residual MIP models after exact fixed-point preprocessing. | These cells validate reconstruction but do not test branch-and-bound scaling. |
| Universally timed-out cells | None observed among 11 pilot instances. | No size level is removed; the pilot is too small to justify tighter limits. |
| Memory-failure cells | None recorded. Memory caps were not enforced and peak RSS was unavailable. | Absence of a recorded memory failure is not evidence that the final grid fits memory. |
| Redundant size levels | None can be identified defensibly. Family A and structured pilot rows each use only one numerical size. | Preserve the registered final grid unchanged. |
| Missing diagnostics | Peak RSS unavailable on $(facts.peak_unavailable)/$(facts.applicable_count) applicable runs; memory limit unenforced on $(facts.memory_unenforced)/$(facts.applicable_count); non-MIP time limit unenforced on $(facts.nonmip_time_unenforced)/$(facts.applicable_count). The environment used `highs_solver_version` rather than the registered `highs_version` key. | Correct the final runner schema and add external per-process supervision before final execution. |
| Implementation bottlenecks | Registered mandatory-only MIP, full-preprocessing DP sensitivity, and full-preprocessing heuristic sensitivity are not callable through this pilot runner. In-process execution cannot enforce non-MIP timeouts or the 16 GiB process cap. | Final execution remains blocked; registered variants are not dropped. |

The output audit found 143 hashed per-run records, $(facts.solver_log_count)
solver logs, one environment record, one run-status CSV, one empty failure CSV,
and a pilot manifest. Every returned library passed exact mandatory-retention,
tagged-coverage, source-frontier, source-closure, and burden reconciliation
checks. Per-algorithm peak resident memory is explicitly `UNAVAILABLE`, never
encoded as zero.

## Frozen final specification

Amendment 001 freezes, without scientific alteration:

- Family A: strategy counts `$(join(config["family_a"]["strategy_counts_including_inactive"], ", "))`, requirement counts `$(join(config["family_a"]["tagged_requirement_counts"], ", "))`, four replicates per size cell, 24 final instances;
- Family B: strategy counts `$(join(config["family_b"]["strategy_counts_including_inactive"], ", "))`, requirement counts `$(join(config["family_b"]["tagged_requirement_counts"], ", "))`, 16 structural cells with two replicates, 128 final instances;
- Family C: seven registered mechanisms at small, medium, and large scales, 21 final instances;
- all 13 algorithms: $(_join_code(algorithms));
- the registered 300/60/120-second small, 900/300/600-second medium, and 1800/600/900-second large exact-or-MIP/deterministic/randomized limits, plus the registered 300-second adversarial enumeration and DP limits;
- a 16 GiB per-process memory cap;
- all 173 final rows and all $(facts.seed_counts.final) final seed values;
- primary estimands $(_join_code(outcomes)); and
- all registered exclusion, failure, timeout, multiple-testing, no-peeking, and no-population-inference rules.

No generator parameter, incidence rule, weight rule, tie rule, algorithm, seed,
row, estimand, or analysis rule was tuned after observing the pilot. Pilot and
final results may not be pooled.

## Limitations and final-execution gate

This pilot does not validate scaling at any final Family B size, enforce or
measure per-process memory, exercise every registered preprocessing variant, or
establish a useful final runtime distribution. The small number and deliberate
implementation purpose preclude scientific algorithm comparison. It contains
no financial library and supports no population, causal, forecasting, alpha,
or deployable-performance claim.

Before any final seed is used, implement and test a process-isolated final
runner that emits one record for every registered `(instance, algorithm,
preprocessing)` attempt, enforces registered time and memory limits, records
peak RSS or a standards-compliant explicit unavailable status, implements all
paired preprocessing variants with reconstruction, uses the exact hardware key
schema, and passes the current initial and Amendment 001 lock checks. Do not
rerun the pilot or substitute pilot seeds.
"""
end


function render_amendment()
    facts = _pilot_facts()
    config = facts.config
    outcomes = config["analysis"]["primary_estimands"]
    return """# Amendment 001 — Post-pilot final freeze and execution-readiness gates

- Amendment number: 001
- Date: 2026-08-27
- Prior immutable lock: `experiments/algorithmic_compression_v1/DESIGN_LOCK.json`
- Prior aggregate design SHA-256: `c5340efc257be1282aabf54ce971a79dcb66d54fd36e0a0cb2e9bac6e2725166`
- Timing: after pilot outcomes, before any final instance generation or final outcome
- Affects: final execution readiness only
- Does not affect: scientific hypotheses, estimands, generators, registry rows, algorithms, limits, seeds, tie rules, or analysis rules

## Reason

The registered pilot completed the intended schema and implementation audit.
It exposed execution-layer gaps that must be closed before final seeds are used:
the in-process runner does not enforce non-MIP timeouts or the 16 GiB memory
cap, cannot measure per-algorithm peak RSS, uses a nonregistered environment key
for the solver version, and does not expose all registered preprocessing
variants. This amendment does not tune scientific content or respond to a
desired algorithmic conclusion. It adds prospective final-execution gates and
records the unchanged final freeze.

## Pilot outcomes already seen

The full operational pilot report was read before this amendment. It contains
143 status records from 11 pilot instances: $(facts.applicable_count) applicable
runs completed with exact feasibility rechecks, two enumeration rows were
prospectively `NOT_APPLICABLE`, and no final seed was used. Exact finite
enumeration/DP burdens matched the exactly rechecked MIP candidate burden on all
jointly applicable pilot cells. Six primary MIP cells were
solved by exact preprocessing without invoking HiGHS. No timeout or recorded
memory-failure status occurred, but per-algorithm peak RSS and all memory-limit
enforcement were unavailable. These facts are excluded from final analysis.

No final instance, algorithm outcome, summary, table, or figure existed or was
read before this amendment.

## Exact changed files and fields

No initially locked file is edited. This amendment adds:

- `experiments/algorithmic_compression_v1/PILOT_REPORT.md`;
- `experiments/algorithmic_compression_v1/amendments/AMENDMENT_001.md`;
- `experiments/algorithmic_compression_v1/DESIGN_LOCK_AMENDMENT_001.json`;
- the pilot runner, report generator, and post-pilot lock/check scripts; and
- hashed pilot run records, logs, environment metadata, and manifest under the registered pilot path.

The post-pilot lock adds fields for the unchanged final grid, registered
algorithms and preprocessing variants, limits, seed-registry hash, primary
outcomes, analysis-rule hash, pilot manifest hash, final-output absence, and
prospective readiness-gate status.

## Unchanged final freeze

The following are frozen exactly as initially registered:

1. **Grid:** 24 Family A instances at `n ∈ {$(join(config["family_a"]["strategy_counts_including_inactive"], ", "))}` and `r ∈ {$(join(config["family_a"]["tagged_requirement_counts"], ", "))}`; 128 Family B instances at `n ∈ {$(join(config["family_b"]["strategy_counts_including_inactive"], ", "))}` and `r ∈ {$(join(config["family_b"]["tagged_requirement_counts"], ", "))}` across the registered 16-cell structural array; and 21 Family C instances covering seven mechanisms at three scales.
2. **Algorithms:** all 13 identifiers in the initial config; none is added, removed, or redefined.
3. **Preprocessing:** primary and paired variants remain exactly registered. Missing implementation blocks final execution; it does not authorize dropping a variant.
4. **Limits:** all small, medium, large, and adversarial exact time limits and the 16 GiB per-process memory cap remain unchanged.
5. **Rows and seeds:** all 173 final registry rows and $(facts.seed_counts.final) final seed values remain unchanged and disjoint from pilot values.
6. **Primary outcomes:** $(_join_code(outcomes)).
7. **Analysis:** all estimand definitions, reference rules, denominators, exclusions, failure handling, statistical models, multiple-testing rule, no-peeking rule, and nonclaims remain unchanged.

## Prospective final-execution gates

Before any final seed is used, all of the following must pass without reading a
final outcome:

1. a process-isolated supervisor enforces each registered time limit and the 16 GiB memory cap for every algorithm and preprocessing variant;
2. peak resident memory is recorded per process when the OS exposes it, otherwise the field is explicitly `UNAVAILABLE` under the reporting rule;
3. mandatory-only and full-fixed-point MIP, the Family A DP pair, and the full-preprocessing heuristic sensitivity all run through the common API with exact reconstruction and certificates;
4. the environment schema contains every registered key, including `highs_version`, and preserves wrapper and solver versions separately;
5. one run-status record is emitted for every registered `(instance, algorithm, preprocessing)` attempt, including failures and not-applicable cells;
6. the exact small-instance audit, hash audit, and mutation test pass; and
7. both the immutable initial lock and `DESIGN_LOCK_AMENDMENT_001.json` verify.

If a gate fails, final execution does not begin. Repair requires tests and, if
scientific design content changes, a new prospective numbered amendment.

## Effect on claims and pooling

This amendment changes no mathematical or scientific claim. It has no effect
on primary or secondary estimands, rows, algorithms, or limits. Pilot results
remain implementation diagnostics and cannot be pooled with final results.
There are no old final results to compare or pool.
"""
end


function _write(path, text)
    mkpath(dirname(path))
    open(path, "w") do io
        write(io, text)
    end
end


function check_postpilot_documents()
    expected = (
        REPORT_PATH => render_pilot_report(),
        AMENDMENT_PATH => render_amendment(),
    )
    for (path, text) in expected
        isfile(path) || error("missing post-pilot document: $(relpath(path, REPOSITORY_ROOT))")
        read(path, String) == text || error(
            "stale generated post-pilot document: $(relpath(path, REPOSITORY_ROOT))",
        )
    end
    println("post-pilot report and Amendment 001 are current")
    return true
end


function main(args = ARGS)
    mode = isempty(args) ? "--check" : only(args)
    if mode == "--write"
        _write(REPORT_PATH, render_pilot_report())
        _write(AMENDMENT_PATH, render_amendment())
        println("wrote PILOT_REPORT.md and AMENDMENT_001.md from pilot artifacts")
        return true
    elseif mode == "--check"
        return check_postpilot_documents()
    end
    error("usage: finalize_algorithmic_compression_pilot_v1.jl [--write|--check]")
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    FinalizeAlgorithmicCompressionPilotV1.main()
end
