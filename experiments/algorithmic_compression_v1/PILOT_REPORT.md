# Registered Algorithmic Compression Benchmark v1 — Pilot Report

> **IMPLEMENTATION PILOT — EXCLUDED FROM FINAL ANALYSIS.** This report is an
> operational readiness audit. Its timing, solver, preprocessing, and burden
> observations are not final computational evidence and must never enter a
> final-study denominator, figure, table, model, or manuscript result.

Pilot completed on 2026-08-27. The runner emitted all 143 prospectively
required status records for 11 registered pilot instances. All
141 applicable runs returned independently rechecked,
exactly feasible libraries; two enumeration cells were prospectively marked
`NOT_APPLICABLE`. No final seed was used, and the 55
pilot seed values (including the 11 execution-order keys) are disjoint from the
865 final seed values.

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
| Machine token | `ac84fa6899d5165f` |
| CPU | Apple M1 Pro; 10 physical / 10 logical cores |
| Installed memory | 17179869184 bytes |
| OS / kernel / architecture | macOS 26.6.2; `25.6.0`; `arm64` |
| Julia | `1.12.6`; 1 thread; BLAS 1 thread |
| HiGHS solver / wrapper | `v1.15.1` / `1.24.1` |
| JuMP / StableRNGs | `1.31.1` / `1.0.4` |
| Recorded source commit | `3227ba203fba123ac021682352137181966d38c0` |
| Project / manifest SHA-256 | `595faaffbf7a74ab56c6e3fcef6f1f10185469117d3c92bad823a504cf154fab` / `4f75e819e1e3fa28cc39e0600937d0d28345e74ee3e0f9a092aa71dfd1a6f666` |
| Pilot UTC interval | `2026-08-27T06:24:56.189Z` to `2026-08-27T06:25:31.317Z` |

The worktree was recorded dirty and included the then-uncommitted pilot runner;
the runner itself is identified by SHA-256 `69bacb3f81f841ac288d56c434612c6975724d2a768c105221559aff18f028c5`. The
post-pilot lock verifies that this hash still matches the committed runner and
that the tracked algorithm source matches the recorded commit before freezing
the final execution code.

## Completion and exactness checks

| Status | Records |
|---|---:|
| `SOLVED` | 135 |
| `SOLVED_BY_EXACT_PREPROCESSING` | 6 |
| `NOT_APPLICABLE` | 2 |

All 141/141 applicable status records
were solved without an implementation, generation, certificate, solver,
timeout, or recorded memory-failure status. Exact burden agreement held on all
11 pilot instances: exact finite enumeration and DP matched the exactly
rechecked MIP candidate burden on the nine cells where all three applied; exact
finite DP and the rechecked MIP candidate matched on the remaining two. This
burden agreement does not turn MIP solver evidence into exhaustive or formal
proof.

| Instance | Applicable comparison methods | Agreed exact burden | Burdens agree? |
|---|---:|---:|---|
| `P-A-001` | 3 | `6//1` | yes |
| `P-A-002` | 3 | `4//1` | yes |
| `P-B-001` | 2 | `4//1` | yes |
| `P-B-002` | 2 | `3//1` | yes |
| `P-C-001` | 3 | `3//2` | yes |
| `P-C-002` | 3 | `1//1` | yes |
| `P-C-003` | 3 | `1//1` | yes |
| `P-C-004` | 3 | `2//1` | yes |
| `P-C-005` | 3 | `3//1` | yes |
| `P-C-006` | 3 | `2//1` | yes |
| `P-C-007` | 3 | `15//4` | yes |

These burden values are implementation checks only. They are not final evidence
and are not pooled with the registered final study.

## Operational timing diagnostics

The following values are raw pilot runner durations in seconds, shown only to
audit applicability, instrumentation, and gross runtime risk. They are not
algorithm rankings and must not be cited as comparative scientific findings.

| Algorithm | Applicable | Completed | Minimum | Median | Maximum |
|---|---:|---:|---:|---:|---:|
| `complete_enumeration` | 9 | 9 | 0.000584 | 0.001085 | 0.114978 |
| `requirement_mask_dp` | 11 | 11 | 0.000517 | 0.000688 | 0.667286 |
| `jump_highs_tagged_cover` | 11 | 11 | 0.016728 | 0.025384 | 0.939175 |
| `weighted_greedy` | 11 | 11 | 0.000493 | 0.000636 | 0.039820 |
| `cardinality_greedy` | 11 | 11 | 0.000534 | 0.000643 | 0.001881 |
| `weighted_greedy_reverse_delete` | 11 | 11 | 0.000522 | 0.000639 | 0.015301 |
| `heaviest_safe_first` | 11 | 11 | 0.000485 | 0.000676 | 0.014793 |
| `lightest_safe_first` | 11 | 11 | 0.000502 | 0.000572 | 0.013716 |
| `maximum_immediate_burden_release` | 11 | 11 | 0.000448 | 0.000564 | 0.008096 |
| `minimum_unique_carrier_exposure` | 11 | 11 | 0.000456 | 0.000558 | 0.056831 |
| `declared_source_order` | 11 | 11 | 0.000440 | 0.000587 | 0.007960 |
| `random_order_rechecked_deletion` | 11 | 11 | 0.000471 | 0.000696 | 0.013862 |
| `multistart_random_rechecked_deletion_32` | 11 | 11 | 0.009786 | 0.016316 | 0.271618 |

Enumeration was prospectively applicable on 9/11 cells; DP and MIP were
applicable on 11/11; every registered greedy and deletion method was applicable
on 11/11. Six MIP cells were solved entirely by exact preprocessing, without
invoking HiGHS: `P-A-001`, `P-A-002`, `P-B-001`, `P-B-002`, `P-C-002`, `P-C-003`. HiGHS was invoked on
5/11 MIP cells, and all invoked cells recorded solver logs.

## Required pilot classifications

| Classification | Finding | Consequence |
|---|---|---|
| Trivial cells | `P-A-001`, `P-A-002`, `P-B-001`, `P-B-002`, `P-C-002`, `P-C-003` had empty residual MIP models after exact fixed-point preprocessing. | These cells validate reconstruction but do not test branch-and-bound scaling. |
| Universally timed-out cells | None observed among 11 pilot instances. | No size level is removed; the pilot is too small to justify tighter limits. |
| Memory-failure cells | None recorded. Memory caps were not enforced and peak RSS was unavailable. | Absence of a recorded memory failure is not evidence that the final grid fits memory. |
| Redundant size levels | None can be identified defensibly. Family A and structured pilot rows each use only one numerical size. | Preserve the registered final grid unchanged. |
| Missing diagnostics | Peak RSS unavailable on 141/141 applicable runs; memory limit unenforced on 141/141; non-MIP time limit unenforced on 130/141. The environment used `highs_solver_version` rather than the registered `highs_version` key. | Correct the final runner schema and add external per-process supervision before final execution. |
| Implementation bottlenecks | Registered mandatory-only MIP, full-preprocessing DP sensitivity, and full-preprocessing heuristic sensitivity are not callable through this pilot runner. In-process execution cannot enforce non-MIP timeouts or the 16 GiB process cap. | Final execution remains blocked; registered variants are not dropped. |

The output audit found 143 hashed per-run records, 11
solver logs, one environment record, one run-status CSV, one empty failure CSV,
and a pilot manifest. Every returned library passed exact mandatory-retention,
tagged-coverage, source-frontier, source-closure, and burden reconciliation
checks. Per-algorithm peak resident memory is explicitly `UNAVAILABLE`, never
encoded as zero.

## Frozen final specification

Amendment 001 freezes, without scientific alteration:

- Family A: strategy counts `7, 11, 15`, requirement counts `6, 10`, four replicates per size cell, 24 final instances;
- Family B: strategy counts `64, 192`, requirement counts `32, 64`, 16 structural cells with two replicates, 128 final instances;
- Family C: seven registered mechanisms at small, medium, and large scales, 21 final instances;
- all 13 algorithms: `complete_enumeration`, `requirement_mask_dp`, `jump_highs_tagged_cover`, `weighted_greedy`, `cardinality_greedy`, `weighted_greedy_reverse_delete`, `heaviest_safe_first`, `lightest_safe_first`, `maximum_immediate_burden_release`, `minimum_unique_carrier_exposure`, `declared_source_order`, `random_order_rechecked_deletion`, `multistart_random_rechecked_deletion_32`;
- the registered 300/60/120-second small, 900/300/600-second medium, and 1800/600/900-second large exact-or-MIP/deterministic/randomized limits, plus the registered 300-second adversarial enumeration and DP limits;
- a 16 GiB per-process memory cap;
- all 173 final rows and all 865 final seed values;
- primary estimands `relative_burden_gap`, `optimum_attainment_frequency`, `solved_fraction`, `wall_clock_time`, `mip_node_count`, `dp_state_count`, `preprocessing_reduction`, `frontier_closure_evaluation_count`; and
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
