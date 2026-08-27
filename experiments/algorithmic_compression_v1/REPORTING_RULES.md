# Reporting Rules

## Mandatory reporting principles

1. Report all 173 final registry rows, including failures and exclusions.
2. Keep Family A, B, and C conclusions separate.
3. Label complete enumeration and DP as exact finite computation.
4. Label HiGHS results as mixed-integer solver evidence plus exact post-check.
5. Never describe solver `OPTIMAL` as formal proof or exhaustive enumeration.
6. Report exact rational burdens and gaps whenever defined; decimal values are
   derived presentation fields.
7. Distinguish exact feasibility, solver feasibility, structural generator
   validity, and endpoint irreducibility.
8. Never report a financial-population interpretation. The benchmark contains
   no real financial library sample.
9. Make no causal, forecasting, alpha, or deployable-performance claim.
10. Derive every manuscript number from a committed machine-readable artifact.

## Required run record

Every attempted `(instance, algorithm, preprocessing)` run must contain:

- schema and experiment versions;
- instance, seed, phase, family, mechanism, and replicate identifiers;
- instance SHA-256 and input artifact path;
- algorithm and preprocessing identifiers;
- deterministic tie rule;
- generator, random-order, multistart, and MIP seeds as applicable;
- registered time and memory limits;
- start/end timestamps and monotonic wall-clock duration;
- peak resident memory or explicit `UNAVAILABLE`;
- selected original strategy identifiers and exact burden when available;
- exact frontier, closure, tagged coverage, mandatory, and burden checks;
- feasibility and irreducibility certificates as applicable;
- method counters and complete trace paths;
- solver controls, status, incumbent, bound, gap, nodes, versions, and log path
  for MIP runs;
- outcome status and failure/deviation code; and
- certificate and log SHA-256 values.

No unavailable field may be encoded as zero. No fractional MIP vector may be
rounded into a candidate.

## Denominators

Every frequency prints `numerator/denominator`, with the denominator defined in
the table note. The full registry denominator is retained for solved fraction,
generation failure, timeout, memory failure, solver error, exact recheck failure,
and disagreement. Optimum-attainment and exact-gap tables additionally print the
number for which an optimum is known.

Pilot and dry-run rows never enter final denominators. Rows are not excluded for
slow runtime, large gaps, unfavorable rankings, or disagreement.

## Gap language

- `exact relative burden gap` is used only when `W_exact*` is established by the
  complete exact methods under the analysis plan.
- `MIP-reference relative burden gap` is used when an exactly feasible incumbent
  has HiGHS-reported `OPTIMAL` status; it remains mixed-integer solver evidence.
- `bound-relative gap` is used for an exactly feasible candidate compared with
  a valid MIP lower bound when optimality is unresolved.
- `solver-reported gap` is reproduced only as a solver diagnostic.
- Undefined ratios are reported `UNDEFINED` with their reason; they are not set
  to zero.

Different selected identities at the same exact objective are reported as tied
optimizer disagreement, not algorithm error. Complete optimizer identity is
claimed only when the exact method's complete-tie search finished within its
registered bound.

## Timeouts, memory limits, and crashes

Timeouts appear in solved-fraction tables, performance profiles, PAR-2
summaries, and the failure appendix. The registered time limit is used for the
timeout runtime field; any separately measured termination overhead is reported
in a diagnostic column.

Memory-limit and process failures retain partial logs and counters. A crash does
not authorize a higher-limit rerun. Machine interruption or infrastructure
failure is documented as a deviation with the affected rows and whether any
outcome was visible before a prospective restart decision.

## Disagreements

Never discard an exact-method, solver, certificate, or hash disagreement. Stop
the affected final batch, preserve raw method certificates, run the registered
minimizer, and commit or otherwise archive the minimized failing fixture before
continuing. The narrative states which methods disagreed, whether burdens or
identities differed, and whether the issue was resolved. A corrected rerun
requires an amendment or declared implementation-correction protocol; the
original record remains.

## Preprocessing reporting

Report mandatory selections, forced selections, dominance removals, duplicate
columns, empty columns, merged requirement rows, remaining dimensions, and
fixed-point iterations separately. For each result, state whether the applied
map preserves feasibility, optimum value, at least one optimum, or every
optimizer identity. Reconstructed original-coordinate solutions receive the
same exact checks as unpreprocessed solutions.

## Pilot reporting

Pilot outputs are stored only at registered pilot paths and labeled
`IMPLEMENTATION PILOT — EXCLUDED FROM FINAL ANALYSIS`. A pilot report lists code
or schema defects found and any amendments proposed. It must not present pilot
rankings as study results or combine pilot and final estimates.

## Figures and tables

All planned figures and tables in `ANALYSIS_PLAN.md` are produced even when the
result is null, flat, timed out, or contrary to expectations. Omitting a planned
display requires an amendment or an explicit empty-panel explanation.

Figures must:

- include direct labels or non-color encodings;
- visibly distinguish timeout and unavailable observations;
- state whether vertical values are exact, solver, or runtime evidence;
- use consistent algorithm names and ordering; and
- link to the machine-readable source artifact and generation command.

Tables must include counts, denominators, exact/decimal status, timeout policy,
and applicable evidence class. Runtime tables identify the machine and software
record. Adversarial tables distinguish analytically known ratios from observed
computational quantities.

## Statistical reporting

Report every registered model, including nonconvergence or separation. Do not
replace a failed registered model with an unregistered specification. Coefficient
tables include the exact model formula, row count, missingness, HC3 convention,
and Holm family. P-values do not determine which effects are discussed. Raw
finite-design summaries remain primary.

## Claims permitted

Subject to results, the paper may state finite-design facts such as:

- exact methods agreed on all or a stated fraction of registered small rows;
- one algorithm attained the known optimum on a stated registry fraction;
- preprocessing removed a stated fraction of variables or requirements;
- a method timed out on a stated set of registered rows; and
- the proved adversarial family exhibited its registered exact ratio.

It may not infer prevalence in real strategy libraries, claim universal solver
superiority from this finite benchmark, or convert a synthetic association into
an economic or causal effect.

## Amendment and deviation disclosure

Every amendment is numbered, prospective, separately hashed, and linked to the
prior lock. It lists:

- the reason;
- exact changed files and fields;
- pilot or final outcomes already seen;
- affected hypotheses, estimands, rows, algorithms, and limits; and
- whether old and new results can be compared or pooled.

Minor execution deviations that do not change the design are still recorded in
the final failure/deviation table. Silent corrections, overwritten locks, and
retroactive seed changes are prohibited.

## Release gate

Before manuscript numbers are generated, require:

1. current design-lock verification;
2. exact registry equality and seed uniqueness;
3. complete hardware and environment record;
4. one run-status row for every registered attempt;
5. successful exactness-directory audit for all small bundles;
6. exact feasibility rechecks for every returned library;
7. hashes for certificates and logs;
8. generated tables/figures agreeing with result schemas; and
9. explicit confirmation that no raw licensed financial data entered the study.
