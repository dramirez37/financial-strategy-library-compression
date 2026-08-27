# Auditable MIP specification for journal compression

Status: implemented and targeted-test verified

Evidence class: mixed-integer solver evidence followed by independent exact
finite reconstruction and feasibility checks. A HiGHS termination status is
not a human proof, Lean kernel verification, or exhaustive finite proof.

## Scope

`solve_journal_compression_mip(instance; ...)` accepts a validated
`journal-compression-instance-v1` identity-closure instance. It solves one
weighted tagged-cover problem and returns
`journal-compression-mip-solution-v1`. The workflow does not apply its tagged
rows to arbitrary nonidentity closure.

The original formulation has one binary variable $x_s$ per strategy:

\[
 \min \sum_s w_s x_s,
 \qquad
 x_s=1\quad(s\text{ mandatory}),
 \qquad
 \sum_{s:u\in R_s}x_s\geq 1\quad(u\in U_L).
\]

Under the proved tagged-cover equivalence, complete tagged coverage and
mandatory inactive-strategy retention are equivalent to exact source-frontier
and source identity-closure preservation. The implementation nevertheless
recomputes both semantic objects after solving rather than trusting the MIP
rows alone.

## Exact preprocessing and reconstruction

The workflow reruns `preprocess_tagged_cover` from the original instance on
every invocation, even when the input schema carries an earlier preprocessing
map. This makes the applied rules and fixed-point trace auditable for the
specific MIP run. The pipeline uses exact `Rational{BigInt}` weights and the
registered stable rule order:

1. mandatory selection and requirement propagation;
2. duplicate requirement removal;
3. unique-carrier forcing and propagation;
4. empty-contribution removal;
5. duplicate-coverage reduction with equal-weight reconstruction maps; and
6. exact coverage dominance.

Forced variables are substituted at one, their exact weights become the
objective offset, and their satisfied rows are removed. The residual JuMP
model therefore contains only remaining binary variables and remaining cover
rows. The result preserves the full preprocessing audit, including events,
per-rule removals, forced and remaining original indices, exact offset,
fixed-point iterations, and the optimizer-identity preservation flag.

A residual solver vector is lifted using the preprocessing reconstruction
map. Equal-weight duplicate substitutions are not enumerated: this workflow
returns one incumbent and rejects an input that declares complete tie
handling. The selected identifiers are always returned in canonical original
strategy order.

If exact preprocessing removes every residual variable and requirement,
HiGHS is not invoked. The result says
`NOT_CALLED_PREPROCESSING_SOLVED`, records `solver_invoked=false`, reconstructs
the forced solution, and still performs the exact semantic checks and any
applicable independent oracle comparison. It does not fabricate an `OPTIMAL`
solver status for a solve that did not occur.

## Exact objective encoding

HiGHS receives integer objective coefficients. The implementation computes a
common denominator for all original exact weights, converts every coefficient
and the forced offset to integers, and verifies the conversion exactly. It
rejects an instance if the complete scaled objective range exceeds exact
integer representation in the solver's `Float64` interface.

Solver objective values and bounds are reported in the original burden unit
after numerical rescaling. The accepted candidate's authoritative burden is
recomputed independently as `Rational{BigInt}` and serialized as
`numerator//denominator`.

## Deterministic solver controls

The workflow records every control in the result:

| Control | Default | Meaning |
|---|---:|---|
| solver | HiGHS | JuMP backend fixed by this workflow |
| threads | 1 | single-threaded solve |
| parallel | `off` | parallel search disabled |
| random seed | 0 | explicit HiGHS seed; caller may supply another nonnegative seed |
| presolve | `on` | HiGHS presolve enabled |
| time limit | unset | caller may set any finite nonnegative number of seconds, including zero |
| relative MIP gap | 0 | no positive relative-gap stopping allowance |
| absolute MIP gap | 0 | no positive absolute-gap stopping allowance |
| console log | off | solver output is captured rather than discarded |

The current pinned environment reports HiGHS.jl 1.24.1, HiGHS solver 1.15.1,
and JuMP 1.31.1. Versions are queried at runtime and stored; they are not
hard-coded into result validation.

The optional warm start is either absent, the complete source library
projected through preprocessing, or a caller-provided original-coordinate
binary selection with a nonempty source label. A supplied warm start must be
exactly safe before projection and exactly cover the residual model after
projection. No financial outcome, dynamic value, held-out quality, or
licensed row enters warm-start construction.

## Diagnostics and log preservation

Every result records:

- solver name, solver version, HiGHS.jl version, and JuMP version;
- whether the solver was invoked;
- termination, primal, dual, and raw statuses;
- numerical objective value, best bound, and reported relative gap when
  available;
- solver-reported solve time and branch-and-bound node count when available;
- HiGHS presolve variables and rows removed when the complete log exposes the
  standard `Presolve reductions` line;
- the exact preprocessing removals separately from HiGHS presolve;
- all effective solver controls and warm-start source;
- the raw residual variable values; and
- the complete captured HiGHS log.

Unavailable diagnostics use an explicit `{available=false}` entry in the TOML
payload. Infinite bounds and gaps from an immediate time limit are preserved
as TOML infinities rather than replaced or hidden. Presolve removal counts are
marked unavailable if the installed solver does not emit the parseable line.

`journal_mip_solution_certificate`, `serialize_journal_mip_solution`, and
`write_journal_mip_solution_certificate` expose the complete result as sorted
machine-readable TOML. The serialized log is the exact string captured during
that invocation.

## Incumbent acceptance and exact post-check

The workflow never thresholds or rounds a solver value. A residual candidate
is reconstructed only if every returned value equals floating-point `0.0` or
`1.0` exactly; signed zero is accepted as zero. Any other finite value is
reported as a fractional candidate and rejected. Nonfinite values are also
rejected.

For an exactly binary vector, the workflow then:

1. lifts the residual selection through exact preprocessing;
2. recomputes mandatory retention;
3. recomputes complete tagged coverage;
4. recomputes the operating frontier from original exact profiles;
5. recomputes the identity closure from original module memberships; and
6. recomputes and reconciles exact burden.

Only a candidate passing every check receives
`status=exactly_rechecked_solver_candidate`, selected strategy identifiers,
and an authoritative exact burden. A failing candidate retains its solver
diagnostics and reconstructed candidate for audit but does not expose it as a
certified selected library.

## Time limits and exact-oracle comparison

`TIME_LIMIT` and every other nonoptimal termination status are returned
unchanged. If such a run has an exactly binary, exactly feasible incumbent,
the incumbent may be certified as safe without being described as optimal.
If it has no incumbent, the result has `status=no_primal_candidate`. Best
bound and reported gap remain in the solver diagnostics when HiGHS provides
them.

The default `exact_crosscheck=:auto` applies an independent exact oracle under
declared size limits:

- complete enumeration when mandatory preprocessing leaves at most 20
  optional strategies;
- otherwise requirement-mask dynamic programming when mandatory
  preprocessing leaves at most 18 tagged requirements; and
- otherwise no exact comparison, with the inapplicability reason recorded.

The caller may select `:enumeration`, `:dp`, or `:none` and may change the
limits. An explicit oracle request that exceeds its declared limit is rejected
rather than silently skipped. `exact_global_optimum_verified=true` requires an
independent exact-oracle burden equal to the exactly rechecked MIP incumbent.
HiGHS `OPTIMAL` alone never sets that field.

If HiGHS reports `OPTIMAL` but an applicable exact oracle finds a lower
burden, the candidate remains separately identified as safe only and the
workflow returns `solver_optimality_contradicted_by_exact_oracle`. It does not
silently prefer the solver claim.

## Targeted validation

`julia/test/test_journal_compression_mip.jl` covers:

- an exactly known triangle-cover optimum and deterministic replay;
- exact rational scaling and an independent DP comparison;
- full preprocessing and reconstruction before any solver call;
- a zero-second time limit with preserved bound, gap, statuses, and log;
- rejection of a deliberately fractional binary-value fixture;
- complete TOML serialization, including the solver log;
- warm-start validation and provenance; and
- invalid controls and unsupported complete-tie claims.

The targeted file passes 568 assertions, including an exhaustive comparison
with exact enumeration across 70 small nonempty carrier systems with up to
three active strategies and two module requirements.

These tests are exact finite validation of fixtures and control flow. They are
not runtime-scaling evidence, formal verification of JuMP or HiGHS, or a proof
that a solver-reported optimum is globally correct on an unchecked instance.

## Remaining boundaries

- The workflow returns one incumbent and does not enumerate every optimizer.
- Arbitrary nonidentity closure requires the older general-closure formulation
  and does not inherit this tagged-cover workflow automatically.
- Solver presolve counts depend on log availability and format; the complete
  log remains authoritative if parsed counts are unavailable.
- Runtime fields are instrumentation for the future registered algorithmic
  study, not manuscript findings.
- No frozen experiment, financial outcome, licensed row, or held-out
  information is read by this workflow.
