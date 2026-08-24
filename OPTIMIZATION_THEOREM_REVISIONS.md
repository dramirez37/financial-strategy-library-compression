# Optimization Theorem Revisions Before Lean

## Status

This file is the pre-formalization theorem gate for the scarce-resource
revision. It incorporates the exact `Rational{BigInt}` search in
`experiments/results/resource_optimization_claim_audit.json`. This file does
not itself confer Lean status. Subsequent OPT-FND and OPT-T2T4 ledger entries
record the exact resource foundations and requested T2--T4 clauses that now
have compiled declarations and axiom audits. Other rows remain at the status
stated in their controlling specifications; the labels below are the
publication-facing manuscript labels.

The audit found 13 counterexamples among 14 proposed optimization shortcuts.
The only surviving searched target is the antitonicity of resource burden
across penalized-optimal libraries as the price rises. The exact witnesses
revise the target statements as follows.

`PENALIZED_ENVELOPE_SPEC.md` now supplies the complete human statement and
proof for revised T6. It defines the canonical real-price extension of the
exact rational problem, distinguishes pairwise candidate prices from active
envelope breakpoints, and proves the exact one-sided slope formulas. The
requested finite-envelope core now has matching Lean declarations and axiom
output; the stronger active-face one-sided formulas, global partition, and raw
boundary retain their separate proposed/human/Julia status.

`CAPACITY_VALUE_SPEC.md` now supplies the complete human statement and proof
for revised T7. It identifies the attainable-burden representation, proves
the finite right-continuous step structure and breakpoint containment, and
separates ordinary real concavity from discrete diminishing returns. It also
records that additive value needs equal resource units, and that monotone
submodularity alone is insufficient. T7 remains proposed until a matching
Lean declaration and axiom audit exist.

`REPLACEMENT_OPTIMIZATION_SPEC.md` records REP as a supporting proposition,
not an additional T1--T9 contribution. It proves the capacity-deficit and
opportunity-cost identities and corrects the false inference from “no
pre-admission safe deletion” to positive replacement loss. The exact
trade-off condition uses absence of every capacity-feasible zero-loss
deletion.

BRIDGE_ELASTICITY_SPEC.md records BEM as a supporting canonical calculation,
not the complete planned T8. It derives the five point elasticities of the T4
bridge margin on a named real-coordinate path, defines
\(\mathcal F_{\mathrm{br}}=A_{\mathrm{br}}/M_{\mathrm{br}}\), and corrects
zero-margin divergence to the scale-free condition
\(M_{\mathrm{br}}/A_{\mathrm{br}}\downarrow0\).

CHANNEL_ELASTICITY_SPEC.md supplies proposed CED, the human-level algebraic
core of planned T8. It differentiates the existing T5 accounting identity
along one named scalar path, defines channel contributions that remain valid
at zero or negative component levels, and restricts convex weighted-average
language to strictly positive total, operational, and generative values.

INNOVATION_DURATION_SPEC.md replaces the underspecified combined T9 with
IDCV, a fixed-exposure effective-discount theorem. It defines duration as the
normalized contribution-weighted mean date and convexity as its timing
variance, while preserving every existing project-delay counterexample.

Under D-0139, a general set-valued switching theory is excluded from this
revision gate and left for future work.  Completed PEN envelope results and
exact finite switching diagnostics retain their independent statuses.

CAPACITY_ELASTICITY_SPEC.md supplies proposed supporting CPEL for planned
T6--T7. It normalizes CAP's exact capacity shadows and PEN's optimal-burden
changes as guarded forward arcs, proves capacity-breakpoint spike formulas and
nonpositive price-demand arcs, and retains the set-valued-demand boundary at
unequal-burden ties.

## Revised target table

| Target | Revised statement before formalization | Rejected strengthening | Exact evidence |
|---|---|---|---|
| T1 | Preserve the current productive raw-to-compressed projection unchanged. Resource is an outer layer and is not an input to the raw transition. | Equal productive state implies equal burden or equal net value. | CX-RESOURCE-K-NET-01; targets 2--4 |
| T2 | On the finite source-relative safe domain, a minimum-weight optimizer exists. Every safe-feasible library has the same productive value as the source under the existing T1 sufficiency assumptions. Under detectability, DI and frontier--closure feasibility coincide. | Productive equivalence alone identifies burden; detectability is unnecessary for the DI-to-frontier--closure converse. | Lean: `exists_minimumWeightSafeCompression`, `safeCompressionFeasible_iff_dynamicEquivalentFeasible`, and feasible value/action preservation; no adverse search result |
| T3 | Every current-library-certified deletion remains source-safe, lowers burden by exactly \(w_s>0\), and preserves productive value. Every rechecked trace endpoint is source-safe; endpoint completeness is a separate local condition. | A complete trace is minimum-cardinality or minimum-weight; arbitrary batch deletion is safe. | Lean: `recheckedSafeDeletionEndpoint_feasible`; CX-OPT-PRUNE-CARDINALITY-01 has an exact Lean counterpart; CX-OPT-PRUNE-WEIGHT-01 remains Julia evidence |
| T4 | Every global minimum-weight safe library is one-deletion irreducible. The converse fails, and even unique-heaviest-safe-first deletion can be globally suboptimal. The stronger generic inclusion-wise bridge is separate. | Local irreducibility, fixed-order pruning, or heaviest-safe-first pruning implies global optimality. | Lean: `MinimumWeightSafeCompression.oneDeletionIrreducible`, unit endpoint counterexample, and exact `(2,2,3)` CX-OPT-GREEDY-WEIGHT-01 counterpart; other order fixtures remain Julia evidence |
| T5 | Preserve the current sharp productive loss from dropping closure. Interpret it as a feasibility/value warning, not as a resource optimizer result. | The current T5/T4 productive construction solves a weighted retention problem. | Existing Lean theorem unchanged |
| T6 | **Lean-verified form:** for a fixed nonempty finite family, the canonical real-price extension \(J^\star(\lambda)=\max_L\{V(L)-\lambda W(L)\}\) is attained, continuous, convex, and nonincreasing. Unequal-burden pairwise switching prices form a finite candidate set; outside it an optimal affine branch agrees locally with the envelope and supplies slope \(-W(L)\). Strict dominance on an open region gives the same branch and slope. If \(\lambda_1<\lambda_2\), every \(L_1\in\operatorname{Opt}_{\lambda_1}\) and \(L_2\in\operatorname{Opt}_{\lambda_2}\) satisfy \(W(L_2)\le W(L_1)\), and a weakly antitone optimizer-burden selection exists. | Every pairwise intersection is an active breakpoint; the full global cell partition or active-face one-sided slope/subdifferential formulas are already Lean verified; optimizers are unique; raw libraries are inclusion-nested; or an unequal-burden tied face defines one scalar demand without selection. | Lean: `Optimization/PenalizedEnvelope.lean` and focused axiom audit. Human/Julia-only extensions: `PENALIZED_ENVELOPE_SPEC.md`, `CAPACITY_ELASTICITY_SPEC.md`, FX-OPT-PENALIZED-BURDEN-MONOTONE-01, CX-OPT-PENALIZED-INCLUSION-SWITCH-01, CX-OPT-PENALIZED-BREAKPOINT-TIE-01, CX-OPT-VALUE-KINK-01 |
| T7 | \(V^\star(B)\) is attained, nondecreasing, and a right-continuous finite step function whose value breakpoints are attainable burdens. Discrete shadow value is the exact finite difference on a declared grid. For positive base capacity and value, supporting CPEL normalizes it as a forward capacity arc; the arc is zero on a stable step and can spike when its window reaches a strict breakpoint. Capacity optimizers can jump, and unit-capacity marginal values can increase under module complementarity. Equal-unit additive value is sufficient for discrete diminishing returns; arbitrary-weight additivity and unit-weight submodularity are not. A penalized optimum is capacity-optimal at its own burden, but the converse can fail. | Ordinary concavity or derivative elasticity of the deterministic step function, unconditional discrete diminishing returns, every optimizer-only threshold causing a value spike, submodularity of the general model, sufficiency of submodularity alone, zero duality gap, or recovery of every capacity optimum by a price. | `CAPACITY_VALUE_SPEC.md`; `CAPACITY_ELASTICITY_SPEC.md`; CX-OPT-CAPACITY-NONCONCAVE-01; CX-OPT-CAPACITY-INCREASING-RETURNS-01; CX-OPT-SUBMODULAR-CAPACITY-01; CX-OPT-LAGRANGE-UNSUPPORTED-01 |
| T8 | Along one named positive differentiable parameter path, differentiate the T5 identity to obtain \(x\partial_xI=x\partial_x\Delta^{\mathrm{op}}+x\partial_x\Delta^{\mathrm{gen}}\). For \(I>0\), define \(C_x^{\mathrm{op}}=(x/I)\partial_x\Delta^{\mathrm{op}}\) and \(C_x^{\mathrm{gen}}=(x/I)\partial_x\Delta^{\mathrm{gen}}\), so \(\varepsilon_x^I=C_x^{\mathrm{op}}+C_x^{\mathrm{gen}}\). Only when both channel levels are positive is this the convex weighted average \((\Delta^{\mathrm{op}}/I)\varepsilon_x^{\mathrm{op}}+(\Delta^{\mathrm{gen}}/I)\varepsilon_x^{\mathrm{gen}}\). Supporting BEM gives the canonical positive bridge-margin specialization. Use the scaled level identity, exact finite changes, or action-region analysis at kinks and nonpositive total value. | Component elasticity is defined at a zero or negative channel level; a zero share times an undefined elasticity is valid; different perturbation paths may be mixed; channel shares are automatically positive; closure cardinality is a sufficient scalar state; vanishing net margin alone forces divergence. | CHANNEL_ELASTICITY_SPEC.md; BRIDGE_ELASTICITY_SPEC.md; three direct exact channel examples; CX-OPT-CLOSURE-CARDINALITY-ELASTICITY-01; CX-OPT-ELASTICITY-ZERO-MARGIN-01; CX-BEM-VANISHING-GROSS-SCALE-01 |
| T9 | For fixed \(H\ge1\), \(\alpha=\beta\rho>0\), and a fixed nonnegative nonzero scalar exposure sequence \(z\), define \(\omega_t^\Psi=\alpha^tz_t/\Psi_H\), \(D_\Psi=\sum_tt\omega_t^\Psi\), and \(C_\Psi=\sum_t\omega_t^\Psi(t-D_\Psi)^2\). Then \(\partial\log\Psi_H/\partial\log\alpha=\varepsilon_\beta^\Psi=\varepsilon_\rho^\Psi=D_\Psi\), \(\partial D_\Psi/\partial\log\alpha=C_\Psi\ge0\), and \(0\le D_\Psi\le H-1\), with equality exactly at the stated singleton-support cases. | Innovation duration is primitive project delay, admission time, or policy duration; the formulas survive when \(z\) changes with the differentiated primitive; convexity is an unconditional Bellman-value shape claim; log elasticity is defined at \(\alpha=0\). | INNOVATION_DURATION_SPEC.md; existing Lean-verified S6 finite-sum base; direct exact duration/convexity examples |

## Statements safe to formalize next

After the compiled OPT-FND and OPT-T2T4 slices, the remaining resource-layer
Lean work may target only the following dependency order:

1. the generic complete-trace/inclusion-wise irreducibility bridge and the
   equal-active-weight cardinality corollary;
2. any additional exact finite counterexample records needed by manuscript
   wording;
3. penalized-envelope algebra, including set-valued burden antitonicity;
4. capacity monotonicity and the unsupported-point boundary; and
5. the supporting replacement burden identity, common-insertion safety
   congruence, and opportunity-cost decomposition; and
6. only then any named elasticity statement with its perturbation domain.

The following must not enter Lean under the current assumptions:

- minimum-cardinality or minimum-weight optimality of rechecked pruning;
- any greedy approximation claim;
- raw-inclusion nesting of penalized optimizers;
- uniqueness at resource-price breakpoints;
- concavity or diminishing returns of capacity value;
- positive replacement loss inferred only from failure of pre-admission
  structural safety;
- strong constrained--penalized equivalence;
- closure-cardinality elasticity; or
- a uniform level-elasticity bound without a positive margin floor.

## Exact-search scope and proof boundary

The exhaustive bounds are versioned in
`experiments/configs/resource_optimization_counterexamples.toml`. Carrier
minimality is established either by exhaustive smaller-carrier search or by
the elementary necessity recorded in each fixture. Lexicographic minimization
within the declared finite grids chooses canonical integer-weight and
integer-value representatives.

The surviving burden-order result also has a general two-inequality proof:
for \(\lambda_1<\lambda_2\), optimality of \(L_1\) and \(L_2\) gives
\[
\begin{aligned}
V(L_1)-\lambda_1W(L_1)
  &\ge V(L_2)-\lambda_1W(L_2),\\
V(L_2)-\lambda_2W(L_2)
  &\ge V(L_1)-\lambda_2W(L_1).
\end{aligned}
\]
Adding yields
\[
(\lambda_2-\lambda_1)(W(L_1)-W(L_2))\ge0.
\]
This argument covers every optimizer pair and does not require uniqueness,
raw nesting, concavity, or differentiability. It remains informally valid and
Julia validated until an exact Lean declaration and axiom audit are added.
