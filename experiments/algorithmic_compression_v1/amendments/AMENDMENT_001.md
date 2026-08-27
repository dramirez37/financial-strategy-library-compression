# Amendment 001 — Post-pilot final freeze and execution-readiness gates

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
143 status records from 11 pilot instances: 141 applicable
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

1. **Grid:** 24 Family A instances at `n ∈ {7, 11, 15}` and `r ∈ {6, 10}`; 128 Family B instances at `n ∈ {64, 192}` and `r ∈ {32, 64}` across the registered 16-cell structural array; and 21 Family C instances covering seven mechanisms at three scales.
2. **Algorithms:** all 13 identifiers in the initial config; none is added, removed, or redefined.
3. **Preprocessing:** primary and paired variants remain exactly registered. Missing implementation blocks final execution; it does not authorize dropping a variant.
4. **Limits:** all small, medium, large, and adversarial exact time limits and the 16 GiB per-process memory cap remain unchanged.
5. **Rows and seeds:** all 173 final registry rows and 865 final seed values remain unchanged and disjoint from pilot values.
6. **Primary outcomes:** `relative_burden_gap`, `optimum_attainment_frequency`, `solved_fraction`, `wall_clock_time`, `mip_node_count`, `dp_state_count`, `preprocessing_reduction`, `frontier_closure_evaluation_count`.
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
