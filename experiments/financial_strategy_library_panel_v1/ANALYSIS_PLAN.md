# Financial Strategy-Library Panel v1 — analysis plan

## Evidence sequence

Analysis begins only after the committed design lock verifies, every registered
origin has a terminal universe record, every registered run unit is terminal,
and the independent result audit passes. No interim burden, identity, solver,
runtime, or postdecision summary can change the design.

## Primary estimands

For every origin, library construction, and burden schedule, report:

1. source and selected active-strategy counts;
2. exact source and selected burdens, absolute burden reduction, and burden
   reduction fraction;
3. frontier rows, capability rows, incidence density, duplicate columns,
   dominance removals, unique carriers, forced selections, and variables and
   rows before and after preprocessing;
4. exact-reference availability and evidence class;
5. algorithm optimum-attainment indicator when an exact finite reference is
   available;
6. absolute and relative burden gap to the strongest certified reference;
7. exact frontier, closure, mandatory-retention, and burden certificates;
8. selected-identity overlap across algorithms and burden schedules; and
9. registered failures and inapplicability without denominator deletion.

The primary comparison is within the same origin--library--schedule instance.
Library constructions and burden schedules are not pooled into one scale.
Complete finite-panel summaries report median, mean, interquartile range, 90th
percentile, worst observed value, and the full denominator.

## Secondary computational estimands

Report preprocessing iterations and reductions, MIP solve time, best bound,
reported gap, node count when available, DP state count, frontier/closure
evaluation counts, complete deletion scans, and multi-start improvement over its
first start. Runtime is conditional on the registered eight-worker environment.
No runtime profile mixes feasible construction with completed proof of
optimality; feasibility, quality-qualified attainment, and exact completion use
separate targets.

## Secondary postdecision financial diagnostics

Only after selection and certification, calculate separately for each origin
and library construction:

- next-calendar-year change in the audit-specific best operating score between
  the source and retained library, by registered belief and in aggregate;
- the share of beliefs with no postdecision loss;
- identity persistence into the next origin's independently reconstructed
  source; and
- the realized count of source securities that delist or cease classification
  after the decision.

These are registered postdecision mechanism diagnostics. They do not enter the
optimization, are not corrected into an alpha estimate, and do not support a
forecasting or deployable-performance claim. The maximum over a large fixed
catalog is identified as such. Terminal levels from different origins or
library constructions are not treated as commensurate portfolio returns.

## Dependence and uncertainty

The finite registered panel is reported as a census. No primary null-hypothesis
test or population p-value is used. For paired algorithm differences, an
optional uncertainty summary resamples whole decision origins with replacement
using the registered bootstrap seed and reports percentile intervals. It never
resamples algorithm rows independently. With only 20 origins, intervals are
descriptive sensitivity summaries and not asymptotic validation.

No unregistered regression specification may replace a failed or nonestimable
model. If later regression is desired, it is exploratory unless separately
registered before results are accessed.

## Failure and exclusion rules

- Fewer than 20 origin-eligible ETFs, missing SPY, a missing required source
  field, or an unresolved capability owner produces a visible origin failure.
- An invalid strategy score, incomplete operating profile, or nonpositive
  active weight rejects that source instance; no imputation is permitted.
- Under Amendment 014, an insufficient postdecision belief profile makes all
  nine secondary records for that origin unavailable without changing its
  structural records; all 63 corresponding algorithm rows remain in the
  denominator.
- Exact cutoff ties are retained. No random tie breaking is allowed.
- Solver timeouts, missing incumbents, certificate failures, memory limits,
  method inapplicability, and infrastructure interruptions retain distinct
  statuses.
- A rerun may resume terminal records but may not replace a valid unsuccessful
  record without a prospective amendment.
- No origin, library, schedule, or algorithm is dropped because its result is
  unfavorable, trivial, or difficult.

## Prespecified tables and figures

1. origin-eligible universe and source-library structure table;
2. capability ownership and carrier-multiplicity table;
3. burden calibration and source-burden table;
4. exact-method agreement and solver-evidence table;
5. algorithm burden-gap table;
6. preprocessing reduction table;
7. failure and applicability census;
8. origin-by-origin compression plot with all failures shown;
9. separate feasibility, quality, and exact-completion cactus plots;
10. capability-carrier multiplicity versus compression plot;
11. schedule identity-overlap plot; and
12. postdecision diagnostic plot, visually and textually separated from the
    optimization evidence.

Every displayed number must be generated from audited rows. Axis ranges include
all finite observations or state an explicit, non-cherry-picked transformation.
