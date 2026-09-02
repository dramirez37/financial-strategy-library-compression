# Financial Innovation-Challenge Panel v2 — execution protocol 001

This protocol is frozen by `EXECUTION_LOCK.json` before any v2 licensed row is
parsed. It implements the already locked design without changing an estimand,
threshold, origin, docket, burden schedule, scenario, arm, menu count, or seed.

## Runtime and source boundary

- Julia 1.12.6 runs with one BLAS thread and one HiGHS thread per model.
- The execution lock binds the design lock, execution source, audit source,
  tests, dependency manifest, and the byte-size and modification-time metadata
  of the four registered CRSP files. Phase-one source audit records their full
  SHA-256 digests and required schemas inside the ignored local result root.
- Raw values, PERMNOs, licensed-derived menus, strategy scores, solver inputs,
  and return paths remain below the ignored v2 `local_data/` or
  `local_results/` roots.

## Eligibility implementation

The runner first applies the registered point-in-time security-history,
activity, security-type, name, pre-origin history, liquidity, price, and volume
rules. It then estimates the four SPY cutpoints from the construction window.
For each provisional security it counts valid-return observations in all five
SPY states separately in the construction and compression windows. Securities
with any count below 25 are removed before liquidity ranking; the first 100
remaining securities in descending median compression-window dollar volume,
then ascending PERMNO, form the origin universe. SPY must be retained and at
least 20 securities must remain. Every origin receives a terminal status.

## Dockets and scenario profiles

Each supported security receives the complete registered 96-strategy grammar.
Construction rank is pooled mean-variance utility at 5 bps and risk aversion 3.
The compression profile contains the Cartesian 30 rows in the registered
scenario order: five construction-estimated SPY states, costs 0/5/15 bps, and
risk aversion 1/3. Floating computations are losslessly frozen to exact
rationals when a compression instance is constructed.

For each docket the source is the union of: the registered depth within each
security by construction score; the registered depth within each of the 30
compression scenarios; and the registered depth within each capability by
construction score. Every exact Float64 cutoff tie is retained. Canonical
strategy identity breaks output-order ties only.

## Masked menus

The non-source grammar pool is partitioned into the 12 registered combined
strata `(directional signal, signal-filter interface, risk constraint)`. A
StableRNG seeded by the registered menu seed shuffles the stratum order and the
members of every stratum. Each of 32 menus takes eight successive distinct
strata from a rotating stratum order and the next cyclic unused member within
each selected stratum. A menu therefore has eight distinct candidates and
balances all three registered stratification dimensions. Candidate reuse
across different menus is permitted. Menus are serialized and hashed before
arm solving.

## Arms and certificates

For every origin, docket, and burden schedule, the source, innovation-safe
weighted greedy, and innovation-safe 64-start deletion endpoints are computed.
HiGHS solves the innovation-safe and frontier-only tagged-cover models with one
thread, seed zero, a 900-second limit, and zero registered relative and
absolute gaps. Returned binary candidates are accepted only after exact
`Rational{BigInt}` burden, mandatory, frontier, and closure checks. `OPTIMAL`
is retained as solver evidence and is never described as a formal proof. The
57-row registered models disable the small-instance exhaustive cross-check;
their global-minimum language is therefore qualified by the solver-evidence
boundary required in the locked reporting rules.

The budget-matched comparator starts from the accepted frontier-only endpoint
and scans every remaining strategy by descending frozen pooled compression
score, then canonical identity, adding each whole strategy that fits within
the accepted safe-arm burden. The runner records cap, realized burden, slack,
additions, closure recovery, and exact feasibility.

## Information firewall and held-out evaluation

All dockets, menus, arm selections, certificates, and frozen menu choices are
serialized below `local_results/predecision/`. A canonical directory aggregate
is written to `PREDECISION_SEAL.toml`, read back, and independently recomputed.
No postdecision extraction function is called until this verification passes.

The postdecision evaluator reads only the prior-year warm-up and registered
next calendar year for structurally evaluable origins. The SPY sessions in the
postdecision year define the expected calendar. A finite observed delisting
return is included and later sessions are cash. Missing dates without that
transition, unobserved terminal delisting returns, invalid return rows, or fewer
than 200 calendar sessions make the already frozen candidate unavailable;
another menu candidate is never substituted.

## Terminal rows, analysis, and promotion

Every origin, docket, schedule, arm, and menu receives a terminal row or a
reason-coded inherited structural-unavailable row. The primary analysis uses
only the validation-work-units schedule. An origin-docket estimate requires 24
complete pairs; an origin passes the registered menu gate only when both
dockets do. The cross-docket origin value averages its two available docket
estimates. The headline gate requires at least 15 structurally evaluable
origins and at least 75% of them passing. Whole-origin percentile bootstrap
resampling uses 10,000 StableRNG repetitions with a seed derived from the
literal `financial-strategy-library-panel-v2|primary-bootstrap`.

Public promotion is a separate fail-closed action. It requires every audit
certificate to pass and whitelists only origin IDs, docket/arm/schedule IDs,
statuses, reason codes, aggregate counts, exact burdens, hashes, solver
diagnostics, and origin-level contrasts. It rejects PERMNOs, non-SPY tickers,
security-linked dates, row-level returns, paths outside the repository, and
licensed-derived menu or strategy scores.

## Amendment 004: liquid equity-and-ETF master panel

`DESIGN_AMENDMENT_001` supersedes the original ETF-only state-support rule
before any v2 score or outcome was observed. The runner stages a nonduplicated
2000--2025 panel of eligible common equities and plain ETFs, then derives each
point-in-time origin universe from its decision-date classification and
predecision rows. Instruments compete in one descending median-dollar-volume
ranking. Each retained security must have complete usable data on the SPY
reference calendar from the fixed warm-up start through the decision date and
must satisfy the still-registered state-cell minima. Known CRSP missing-return
reasons remain missing; unknown or contradictory flags fail closed.

The three registered source files are staged concurrently with bounded
file-local buffers and terminal Parquet chunks. The master manifest freezes
registered file and chunk order. SPY states, completeness, structural
backtests, dockets, and scores all read origin-scoped predecision views from
that one dataset. The postdecision view is inaccessible to scientific code
until the predecision seal has been verified. See `EXECUTION_AMENDMENT_004`
for the failed-attempt boundary and concurrency disclosure.
