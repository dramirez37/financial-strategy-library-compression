# Analysis Plan

## Analysis populations

The `final` rows in `INSTANCE_REGISTRY.csv` are the sole final analysis set.
Dry-run and pilot rows are excluded. All 173 final rows remain in reporting
denominators even if generation, execution, timeout, memory, or certification
fails.

Analyses are reported separately for Family A (24 small exact), Family B (128
structured), and Family C (21 adversarial). Families are not pooled into a
single “average benchmark” ranking. Family B summaries describe its registered
finite design. Family C summaries describe mechanisms. Neither is a probability
sample from real financial libraries.

The run unit is `(instance_id, algorithm_id, preprocessing_variant)`. The
instance is the pairing/blocking unit for algorithm comparisons. Replicate is a
registered independently seeded realization of the same design cell, not an
independent draw from a financial population.

## Outcome definitions

Let `W_a(i)` be the exact rechecked burden returned by algorithm `a` on instance
`i`, when an exactly feasible library is available. Let `W_exact*(i)` denote an
optimum established by complete enumeration and independently matched by DP.
Let `W_MIP(i)` denote an exactly feasible incumbent for which HiGHS reports
`OPTIMAL`. `W_MIP` is a mixed-integer reference, not an exhaustive finite or
formal proof. It never overrides a contradictory exact oracle.

### Primary outcomes

1. **Relative burden gap.** `(W_a(i)-W_exact*(i))/W_exact*(i)` for exact-reference
   rows. Family A gaps are exact. Family B separately reports
   `(W_a(i)-W_MIP(i))/W_MIP(i)` as an **MIP-reference relative gap** when the
   reference is available. A time-limited MIP yields a bound-relative interval,
   not an exact or MIP-optimality gap. Registered final instances must have
   positive reference burden whenever a ratio is reported.
2. **Optimum-attainment frequency.** Exact optimum-attainment is the fraction of
   exact-reference rows on which an exactly feasible algorithm result equals
   `W_exact*`. Family B reports MIP-reference attainment separately. Every table
   prints its evidence class, denominator, and unavailable-reference count.
3. **Solved fraction.** Fraction of registered method runs returning an exactly
   feasible candidate within both limits. For exact methods, `solved` also
   requires complete search. For MIP, solver optimality and incumbent feasibility
   are separate fields.
4. **Wall-clock time.** Monotonic elapsed seconds for the registered run scope.
   Timeouts retain the limit and status. Solved-only times are never the sole
   runtime summary.
5. **Node count.** HiGHS node count when available; unavailable is not encoded as
   zero.
6. **DP state count.** State-layer pairs visited, transitions evaluated, and
   final reachable masks for registered DP runs.
7. **Preprocessing reduction.** Separate variable and requirement reductions,
   both as counts and fractions of original dimensions, plus forced selections
   and fixed-point iteration count.
8. **Semantic evaluation count.** Frontier checks and closure checks for each
   certified deletion method, reported separately and jointly.

### Secondary outcomes

- exact absolute burden gap;
- source-normalized retained and removed burden;
- exact selected cardinality;
- optimizer-identity disagreement at equal objective;
- endpoint one-deletion irreducibility;
- greedy and deletion step count;
- multistart improvement over its first random start;
- complete-tie count when exact enumeration is registered;
- peak resident memory;
- solver incumbent, best bound, and reported gap at timeout;
- preprocessing wall time and share of total runtime;
- requirement and strategy counts after each named preprocessing rule; and
- minimized failure-fixture dimensions.

## Exact-reference rules

Family A requires enumeration and DP burden equality, feasibility of both
representatives, and a conclusive MIP pipeline. A disagreement is labeled
`EXACT_METHOD_DISAGREEMENT`, causes the exactness CI gate to fail, and triggers a
minimized failing fixture. It is never resolved by majority vote.

For Family B and non-exact Family C rows, an exact optimum is available only
when HiGHS reports optimality and the incumbent passes exact reconstruction and
semantic checks. Time-limited best bounds are mixed-integer diagnostics. If a
future second solver is registered by amendment, disagreement remains visible;
one solver is not selected post hoc as authoritative.

## Descriptive summaries

For every primary outcome, report the raw row count, eligible denominator,
missing/unavailable count, median, interquartile range, mean where meaningful,
minimum, maximum, and registered quantiles 0.10, 0.25, 0.50, 0.75, and 0.90.
Exact rational aggregates remain exact in tables whenever practical. Decimal
renderings are derived fields.

Paired algorithm differences are computed only within the same instance and
declared preprocessing comparison. Report wins, ties, losses, median paired
difference, and exact two-sided sign-test interval/p-value as a descriptive
finite-design diagnostic. No pair is dropped merely because one method timed
out; solved-fraction and penalized-runtime analyses retain it.

## Runtime and timeout analysis

Runtime reporting has three complementary views:

1. solved fraction by registered time threshold;
2. empirical performance profiles using the best observed solved time per
   instance as denominator, with unsolved methods beyond the plotted maximum;
3. PAR-2 time, equal to observed time if solved and twice the registered limit
   otherwise.

The primary runtime comparison uses median PAR-2 and paired PAR-2 differences.
Solved-only log runtime is explicitly secondary. No timeout is imputed as a fast
failure or discarded.

## Registered statistical models

Models summarize the finite design and do not support population inference.
They are fitted separately by family unless stated otherwise.

### Family B burden-gap model

For each heuristic with an available registered reference, fit ordinary least
squares to `log(1 + reference_relative_gap)` using nine registered instance-level main effects: log2
strategy count, log2 requirement count, frontier-row share, coverage density,
module overlap, bundle prevalence, unique-carrier frequency, weight dispersion,
and frontier-module correlation. The joint model adds the registered algorithm
indicator. Include algorithm-by-log2-strategy-count and
algorithm-by-log2-requirement-count interactions only. Replicate is a fixed
block. Use HC3 standard errors implemented from `LinearAlgebra`. Higher-order
structural interactions are not estimated.

### Solved-fraction model

Fit a prespecified binomial logistic model to solved/not solved with algorithm,
log2 strategy count, log2 requirement count, and preprocessing variant. If IRLS
does not converge or separation is detected, report that failure and use exact
stratum counts only; do not change links or add penalties post hoc.

### Penalized-runtime model

Fit OLS to `log(PAR2)` with the same covariates as the solved-fraction model and
HC3 standard errors. This model is secondary to performance profiles and paired
finite-design summaries.

### Preprocessing model

For paired mandatory-only versus full MIP runs, model the within-instance
difference in `log(PAR2)` and node count using the seven registered structural
factors and size main effects. Node-count models use `log(1+nodes)` and only rows
where the solver supplies a node count; availability counts are mandatory.

### Family A exact gaps

No asymptotic model is primary. Report exact gap distributions and paired exact
comparisons. A secondary OLS on `log(1+gap)` may use strategy count, requirement
count, and algorithm only, with HC3 standard errors.

### Family C mechanisms

No cross-mechanism regression is fitted. Report each mechanism by parameter,
including the analytically proved `2k/3` heaviest-safe-first ratio only for its
registered theorem family. Other observed trends are computational evidence.

Holm adjustment is applied within each family of secondary coefficient tests.
Primary finite-design summaries and registered failure counts are shown
regardless of significance.

## Preprocessing analysis

For each rule, separately report removed variables, removed requirements,
forced selections, duplicate groups, dominance removals, empty columns, and
fixed-point iterations. Verify reconstructed burden and feasibility on the
original instance. Report whether the map preserves all optimizer identities or
only at least one optimum.

The primary MIP comparison is paired full preprocessing versus mandatory-only.
If the mandatory-only workflow is not implemented before final execution, the
benchmark is blocked; it is not dropped from the plan. The same rule applies to
the registered full-preprocessing DP sensitivity in Family A.

## Randomized deletion analysis

Random-order deletion uses the registered `random_order_seed`. Multi-start uses
32 domain-separated starts from `multistart_seed`; all endpoints remain in the
trace, while the returned endpoint is the minimum exact burden with stable
selected-index tie breaking. Report the distribution across starts and the
improvement from start one to the selected endpoint. No adaptive increase in
start count is permitted.

## Exclusions and missingness

Permitted pre-outcome exclusions are limited to failure to generate within 128
structural attempts, schema invalidity detected before algorithms run, and an
incomplete hardware record before timing. The registry row remains in tables and
denominators with its failure code.

Runtime, timeout, large gap, unfavorable ranking, node count, solver
disagreement, or certificate failure is never an exclusion reason. `missing`,
`unavailable`, `not applicable`, `timeout`, and numeric zero are distinct in the
machine schema.

## Failure handling

- `GENERATION_FAILED`: retain all attempt diagnostics; no replacement.
- `TIME_LIMIT`: retain incumbent, bound, gap, log, and registered capped time.
- `MEMORY_LIMIT`: retain partial diagnostics and measured peak memory.
- `SOLVER_ERROR`: retain status, log, and environment record.
- `EXACT_RECHECK_FAILED`: reject the candidate and preserve its raw output.
- `EXACT_METHOD_DISAGREEMENT`: fail the gate and create a minimized fixture.

No failed final run is rerun. A machine interruption unrelated to the algorithm
is a protocol deviation: retain the interrupted record, document the cause, and
restart only under the reporting rule or amendment determined before seeing the
affected algorithm's outcome.

## Figures

1. Dolan–Moré-style performance profiles for PAR-2/runtime, faceted by family
   and size.
2. Exact relative burden-gap distributions for heuristics in Family A.
3. Family B paired burden-versus-runtime frontier with timeout markings.
4. Preprocessing reductions versus node-count and PAR-2 changes.
5. Solved fraction by strategy and requirement size cell.
6. Frontier/closure evaluation counts for certified deletion variants.
7. Adversarial mechanism panels with registered parameter on the horizontal
   axis and exact/observed burden ratio on the vertical axis.

All figures use shape, line style, or direct labels in addition to color.
Timeouts and unavailable values are visible, not removed from plotting data.

## Tables

1. Registered design and realized structural diagnostics.
2. Small exact cross-method agreement and exact heuristic gaps.
3. Solved fraction, PAR-2, memory, states, and nodes by algorithm and size.
4. Paired preprocessing effects and per-rule removals.
5. Certified-deletion burden, irreducibility, and semantic-check counts.
6. Adversarial mechanism results and theorem-versus-computational evidence
   labels.
7. Complete failures, timeouts, disagreements, exclusions, and deviations.
8. Hardware, software, hashes, solver controls, and seed registry summary.

## No-result-peeking rule

Final outputs may be read only after the design lock verifies, pilot activity is
closed, the final runner passes trivial and pilot gates, and the execution start
is recorded. There is no interim final analysis, outcome-dependent stopping,
row replacement, or factor-level adjustment. Pilot outcomes may repair code but
cannot change primary estimands, final rows, final seeds, limits, or algorithms
without a prospective amendment that discloses what was seen.

## Reproducibility checks

Every run references committed instance and seed rows, records stable ordering,
serializes exact selections and burdens, and emits a hashed certificate. Small
exact result directories pass the nonmutating independent exactness auditor.
Medium and large outputs pass exact feasibility rechecks and preserve MIP bound
diagnostics. Summary numbers are generated from committed run artifacts rather
than manual transcription.
