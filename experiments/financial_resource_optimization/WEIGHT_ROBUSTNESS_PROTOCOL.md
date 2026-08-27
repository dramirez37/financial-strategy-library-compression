# Financial retention-weight robustness protocol

Status: prospective analysis lock for a limited robustness replay of already
observed retrospective financial audits.

Protocol date: 2026-08-27.

## Prior-outcome disclosure

This is not a first-look or outcome-blind experiment. The equal,
validation-computation, and documented-complexity schedules were all specified
and evaluated in earlier committed financial-resource work, and equal,
validation-computation, and documented-complexity algorithm comparisons were
reported before this protocol. Those facts make a claim that the present
schedule set was chosen without any knowledge of outcomes false.

The defensible prospective element is narrower: before producing the dedicated
robustness outputs, this protocol fixes the three-schedule subset, schedule
interpretations, complete algorithm grid, identity-overlap statistic, burden
and compression formulas, tied-rank rule, unique-carrier check, exclusions,
and public schema. No new schedule is searched for or tuned. The governance
schedule is the already prespecified `documented_complexity` schedule, reused
unchanged because it is objective and avoids post-outcome weight construction.

## Fixed schedules

### Equal active-strategy burden

- Economic interpretation: every retained active strategy consumes one common
  maintenance slot.
- Formula: $w_s=1$ for each active strategy; the mandatory inactive strategy
  has zero burden.
- Units: active-strategy maintenance slots.
- Permitted inputs: active versus mandatory-inactive status only.
- Prohibited inputs: validation or held-out returns, opportunity quality,
  rankings, selected identities, solver outcomes, and algorithm performance.
- Tie handling: exact equal weights; algorithms use their predeclared stable
  identifier tie rules and optimization ties are not claimed complete.
- Expected range: exactly 1 for active strategies.
- Missing data: not applicable; an absent active/mandatory flag is a schema
  error and the instance is rejected.

### Validation-computation burden

- Economic interpretation: documented rolling computation and validation work
  in five-session units.
- Formula: $w_s=1+L_s/5+20I_s^{trend}+4I_s^{vol}+I_s^{flip}$, where $L_s$ is
  the declared directional-signal lookback in sessions.
- Units: five-session rolling-computation equivalents, with one fixed unit.
- Permitted inputs: the locked grammar fields `directional_signal`,
  `entry_filter`, `risk_constraint`, and `exit_rule`, and the prespecified
  lookback dictionary in the parent resource configuration.
- Prohibited inputs: all realized validation and held-out quantities, returns,
  opportunity quality, selection outcomes, solver results, and runtimes.
- Tie handling: exact positive integer weights followed by each algorithm's
  locked deterministic tie rule.
- Expected range: 2 through 38 units under the locked grammar.
- Missing data: unknown signals or missing grammar fields cause a hard failure;
  no imputation or fallback weight is permitted.

### Governance-complexity burden

- Economic interpretation: one fixed governance-review unit plus one unit for
  each documented departure from the baseline policy template. It is a proxy
  for model documentation, approval, and ongoing review scope—not an observed
  dollar cost.
- Formula: $w_s=1+I(signal\ne momentum\_20)+I(filter\ne always)+
  I(horizon\ne5)+I(sizing\ne unit)+I(exit\ne horizon)+
  I(risk\ne notional\_cap\_1)$.
- Units: documented governance-review units.
- Permitted inputs: the six locked grammar fields and the baseline values
  specified before the original resource optimization.
- Prohibited inputs: financial outcomes, held-out quality, strategy rankings,
  selected libraries, solver results, runtimes, or savings under any schedule.
- Tie handling: exact positive integer weights followed by the locked stable
  algorithm tie rules.
- Expected range: 1 through 7 units.
- Missing data: any absent or unrecognized grammar field rejects the instance;
  no default is silently inserted.

## Algorithms and exact checks

Each audit and schedule runs the locked historical stepwise endpoint,
heaviest-safe-first, weighted greedy, weighted greedy plus reverse deletion,
32-start seeded random deletion, preprocessed HiGHS MIP, requirement-mask DP
when its locked residual-row limit permits, and the explicitly unavailable
second-solver row. Algorithms, seeds, limits, HiGHS controls, tie rules, and the
held-out firewall are inherited unchanged from the locked financial algorithm
comparison configuration.

Every returned identity set is independently rechecked in original coordinates
for the mandatory inactive strategy, complete tagged coverage, exact frontier
equality, exact identity closure, and exact rational burden. A solver status is
not formal or exhaustive proof.

When exact fixed-point preprocessing is feasible and leaves no residual
strategy and no residual requirement, the lifted forced selection and objective
offset form an exact finite preprocessing certificate of the global cover
optimum under the human-proved preprocessing propositions. This is human-proof
plus exact-computation evidence; it is not Lean verification or a solver claim.
Otherwise the report uses the comparison's explicitly qualified best returned
benchmark and does not manufacture global optimality.

For every audit/schedule instance, the machine-readable certificate records
the instance hash, preprocessing feasibility, residual dimensions, forced and
selected counts, exact optimum burden, every original-instance semantic check,
the theorem basis, and explicit false flags for Lean verification and solver
invocation. The certificate is produced inside the locked robustness run; it
does not require a separate experiment.

## Locked robustness summaries

Within each audit, never across audits, the study reports:

1. source and selected active counts, exact burdens, compression ratios, burden
   saved, and burden-savings ratios;
2. selected active strategy identifiers and exact certificate fields;
3. pairwise schedule identity overlap for each feasible algorithm as
   intersection, union, symmetric difference, and Jaccard similarity;
4. competition ranks by exact burden within each schedule, with exact ties
   sharing a rank, plus each algorithm's best-rank frequency and rank range;
5. the exact global-preprocessing-versus-historical-stepwise burden gap when an
   empty-residual optimum certificate exists;
6. the distinct source strategies that uniquely carry at least one tagged
   requirement and their retention by every feasible endpoint; and
7. held-out opportunity diagnostics only after all choices, burdens, ranks,
   overlaps, and certificates are fixed.

Unsuccessful, unavailable, and inapplicable algorithm rows remain visible.
Terminal and annual held-out quantities retain their different units and are
never pooled. The analysis makes no causal, forecasting, alpha, or deployable-
performance claim.

## Publication boundary

Licensed panels may be read locally to reconstruct the locked source profiles.
Raw rows, row-level derivatives, local exact instances, solver logs, and
completed licensed provenance remain ignored. Existing policy permits public
aggregate strategy identifiers, exact burdens and certificates, structural
counts, overlap statistics, and postdecision diagnostics. Promotion requires
the independent local audit and writes only the locked aggregate files.
