# Financial algorithm comparison protocol

Status: locked implementation protocol for a retrospective extension; no new
financial comparison result is reported here.

Protocol date: 2026-08-27.

## Scope and immutable parents

The extension consumes the already declared source libraries from the locked
terminal audit, annual walk-forward audit, and cross-audit financial-resource
workflow. The parent runners, configurations, design locks, decision hashes,
pruning definitions, and committed outputs remain unchanged. After amendment
002, frozen source membership and the historical stepwise comparator are read
from the committed cross-audit membership certificates; source validation
profiles are recomputed from the SHA-256-matching licensed panel and must
exactly reproduce the committed source frontier and module union. The new layer is
implemented in `julia/src/FinancialAlgorithmComparison.jl` and
`julia/scripts/run_financial_algorithm_comparison_v1.jl`; it calls the public
aggregate extraction functions in `run_financial_resource_optimization.jl`.

The exact comparison input consists only of source strategy identifiers,
losslessly rationalized validation-profile coordinates, source frontier,
module strings, identity closure, and preregistered resource weights. It does
not accept dates, prices, returns, holdings, or raw market rows. Local
serialized instances and solver logs are ignored by Git. No raw CRSP/WRDS row
or row-level derivative is a permitted output.

The current annual parent `--check` is known to fail because its decision hash
now embeds the later taxonomy-lock identity rather than the registered
analytical-lock identity used by the committed decision certificates.
Amendment 002 records the exact diagnosis. The extension neither rewrites the
parent nor waives the mismatch: it imports only the already committed source
object and validates that object independently before algorithm dispatch.

This is a retrospective financial resource audit, not a trading-performance
study. It makes no causal, forecasting, alpha, or deployable-performance claim.

## Fixed source instances and weights

Two source instances are evaluated separately:

1. `locked_terminal_v1`, whose held-out diagnostic unit is the locked
   2020–2024 enabled-descendant net-utility opportunity quantity; and
2. `annual_walk_forward_v2`, whose unit is the mean next-year
   enabled-descendant opportunity quantity across its five hashed annual
   episodes.

The terminal and annual units are never pooled. For each source, the four
existing resource schedules are used without modification:

- uniform cardinality;
- source-local nonshared modules;
- documented validation computation; and
- documented model complexity.

These weights depend only on the frozen strategy grammar and source-local
module incidence. Held-out quantities cannot define or alter a weight.

## Algorithms and fixed controls

Every audit/schedule pair includes the locked current stepwise safe-deletion
endpoint, heaviest-safe-first certified deletion, exact-score weighted greedy,
weighted greedy followed by reverse deletion, 32-start stable random deletion,
preprocessed JuMP/HiGHS MIP, and exact requirement-mask DP when the
mandatory-preprocessed requirement count is at most 22. The multi-start seed is
`20260827`. HiGHS uses seed zero, one solver thread, parallel mode off, no warm
start, a 300-second limit, and zero requested absolute and relative MIP gaps.

No supported second open-source solver is present in the pinned environment.
The schema therefore records an explicit `UNAVAILABLE` row; it neither adds a
package nor fabricates a cross-check. Exact DP and the existing small-instance
triangulation remain the independent exact checks where applicable.

All deterministic tie rules and applicability limits are frozen in
`experiments/configs/financial_algorithm_comparison_v1.toml`. The design lock
hashes that config, this protocol, the comparison code, the algorithm
implementations, the pinned Julia environment, the parent configs and locks,
and the data-access policy. It acknowledges that legacy parent financial
outcomes preexist, while recording that no output from this new algorithm
comparison existed at lock time.

## Required structure fields

Each audit/schedule/algorithm row records:

- active strategy count (excluding the mandatory inactive entry);
- frontier and module tagged-row counts;
- exact active incidence density;
- duplicate active coverage columns beyond the first representative;
- variables removed specifically by exact coverage dominance;
- tagged rows with one source carrier;
- nonmandatory strategies selected by unique-carrier propagation;
- variables before and after full exact preprocessing;
- constraints before preprocessing (tagged rows plus mandatory equalities) and
  after preprocessing (residual tagged rows);
- runtime, DP state count, deletion frontier/closure evaluation counts and
  complete scans where those diagnostics exist (the evaluation totals include
  the comparison layer's final independent recheck); and
- multi-start count and seed where applicable.

Missing does not mean zero. Historical stepwise runtime is unavailable because
the frozen parent did not record a comparable timer. MIP node count can be
missing when HiGHS does not expose it or preprocessing solves the instance.
Algorithm-inapplicable fields remain explicitly missing. The selected active
count excludes the mandatory inactive entry; the companion total selected
count includes it so the binary-vector dimension remains auditable.

## Solver and exact-certificate fields

The MIP row preserves termination status, numerical primal objective, best
bound, solver-reported relative gap, solve time, node count when available,
and the complete local solver log. The returned original strategy identifiers
are reconstructed through preprocessing before certification. No fractional
binary vector is rounded.

Every returned endpoint is independently recomputed against the unpreprocessed
source for:

1. mandatory inactive-strategy retention;
2. complete tagged coverage;
3. exact operating-frontier equality;
4. exact identity-closure equality; and
5. exact rational burden.

Solver-reported `OPTIMAL` is recorded separately and is never marked as exact,
formal, exhaustive, or Lean proof. If DP applies, its exact finite optimum is
the benchmark. Otherwise, an exactly feasible HiGHS candidate with reported
`OPTIMAL` is the benchmark with that evidence class stated verbatim. If neither
is available, the benchmark is merely the lowest-burden exactly feasible
returned endpoint, with no optimality claim. Absolute and relative heuristic
gaps are computed only for exactly feasible endpoints.

## Held-out information firewall

The algorithm function accepts an exact compression instance and fixed
controls; it has no held-out argument in any solver call. Only after all
algorithms have terminated and benchmark burdens and gaps are frozen does it
invoke a two-argument ex-post evaluator on a copy of each exactly feasible
selection and a frozen copy of all pre-diagnostic rows. Thus held-out quality
cannot enter weights, preprocessing, applicability, algorithm choice, warm
start, deletion order, objective, or benchmark assignment.

Because exact closure preservation leaves the enabled descendant set
unchanged, the existing audit-specific opportunity sufficient statistic is
reported as a diagnostic after the certificate passes. Its empirical meaning
and timing remain those of the parent audit. It is not an optimization target.

## Failure and audit rules

- An over-limit DP produces a visible `NOT_APPLICABLE_REQUIREMENT_LIMIT` row.
- An unavailable second solver produces a visible `UNAVAILABLE` row.
- A timeout or nonoptimal MIP status is retained with its incumbent and bound;
  a candidate is accepted only after the exact recheck.
- A solver with no incumbent produces no invented selection or burden.
- A locked historical stepwise endpoint that fails lossless-rational exact
  equality remains visible as historical evidence but is excluded from the
  certified benchmark.
- Any saved selection, burden, hash, frontier, closure, or mandatory-retention
  disagreement fails the nonmutating audit.
- Unsuccessful rows remain in the denominator of any later comparison.

The local audit reopens each serialized exact aggregate instance, recomputes
every saved selection certificate without rerunning a solver, checks artifact
hashes, and writes a local audit status. Only after it passes may a later task
consider public aggregate promotion. The explicit promotion command validates
the complete two-audit, four-schedule, eight-row algorithm grid; rejects any
unknown column or missing exact certificate; copies only the aggregate summary;
and generates a public status plus results report from those committed rows.

## Publication boundary

`experiments/financial_algorithm_comparison_v1/local_results/` is ignored and
contains the only outputs of the licensed command. Public promotion is manual,
must be invoked only after the audit passes, must exclude raw and row-level
data, and must preserve failures. The permitted public outputs are the fixed
aggregate CSV, its audit/provenance status TOML, and the report generated from
that CSV. They must be committed separately from this code and protocol commit.
