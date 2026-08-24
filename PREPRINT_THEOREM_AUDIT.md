# Preprint Theorem Audit

Audit date: 2026-08-19

Audited branch: `codex/optimization-revision`

Audited manuscript: `manuscript/main.tex` and every included section and appendix

Scope: every labeled Definition, Lemma, Proposition, Theorem, Corollary,
Example, and Counterexample in the current preprint

## Verdict

The preprint contains 55 labeled mathematical results: 9 definitions, 1
lemma, 12 propositions, 15 theorems, 6 corollaries, 6 examples, and 6 formal
counterexamples.  The audit classifies 48 as **PASS**, 6 as **WORDING PATCH**,
1 as **FORMALIZATION PATCH**, and none as **PROOF PATCH** or **REMOVE FROM
CLAIM PACKAGE**.

The mathematical core survives.  The required patches are correspondence and
self-contained-statement repairs; no theorem should be broadened.

| Classification | Count | Meaning in this audit |
|---|---:|---|
| PASS | 48 | Statement, proof, timing, dependencies, and claimed evidence agree at the stated scope. |
| WORDING PATCH | 6 | The proof is adequate, but notation, a hypothesis, or the stated boundary needs a local manuscript repair. |
| PROOF PATCH | 0 | No labeled result requires a new mathematical argument at its current scope. |
| FORMALIZATION PATCH | 1 | The human result is valid, but the manuscript's Lean-facing status exceeds the exact named declaration. |
| REMOVE FROM CLAIM PACKAGE | 0 | No labeled result must be removed. |

This count does not include the unnumbered claims audited separately below.
Among them, the innovation-duration display needs a formalization-facing
patch, and the canonical duration rows should be relabeled as exact
fixed-policy diagnostics.

## Audit conventions

- “Lean” lists the principal exact declaration or declaration family when the
  manuscript claims formal support.  All listed manuscript-facing
  declarations occur in the focused audit files and the comprehensive axiom
  gate.  Their recorded axiom footprint is no more than
  `[propext, Classical.choice, Quot.sound]`; no project axiom, `sorry`, or
  `admit` is being treated as proof.
- “Julia” is validation or a finite fixture, never proof.  “None used” means
  the result is not relying on a Julia calculation.
- Definitions have no proof obligation beyond well-definedness.  Examples and
  counterexamples are checked as exact finite constructions.
- Proof locations refer to the manuscript labels and appendix subsections,
  not merely to the external theorem ledger.
- The audit distinguishes the raw library $L$, the compressed productive
  state $K_L=(F_L,C_L)$, and the outer retention burden $W(L)$ throughout.

## Required patches and high-risk findings

### 1. Rechecked pruning: the two irreducibility notions coincide here

The paragraph following Corollary 4.6 says inclusion-wise irreducibility is a
stronger audit object than one-deletion irreducibility.  That is not correct
inside the exact safe fiber.  If $D\subsetneq E$ and
$K_D=K_E=K_L$, choose $s\in E\setminus D$.  Monotonicity gives

\[
 F_D\le F_{E\setminus\{s\}}\le F_E,
 \qquad
 C_D\subseteq C_{E\setminus\{s\}}\subseteq C_E.
\]

The endpoint equalities force
$K_{E\setminus\{s\}}=K_E$.  Thus a proper safe sublibrary exists iff a
safe one-element deletion exists.  This does **not** make the endpoint a
global minimum-weight library: Theorem 4.9 and Example 4.10 still correctly
separate inclusion minimality from global resource optimality.  Patch only
the “stronger audit object” discussion and the claim that separate sublibrary
enumeration is needed for this distinction.

### 2. Theorem 4.11 needs its canonical loss object and comparison class in the statement

The proof establishes the exact canonical one-project bridge envelope.  The
symbol `Loss_d` is not defined before the theorem, and the displayed equality
would be too strong in a broader model with additional differential projects,
post-admission continuation gains beyond the capped object, or unequal
operating blocks.  Define the loss as the retained canonical bridge value
minus its frontier-only comparator, and state that $C$ caps the complete
distinguished terminal continuation gain in that comparison.  Retain the
existing common-operating-block cancellation and positive-duration timing.
No proof change is needed.

### 3. Theorem 4.13 has an exact Lean-correspondence gap

The human implication from the capacity profile $(0,0,1)$ to failure of
ordinary real concavity is valid.  The named Lean witness proves the three
capacity values and failure of diminishing unit increments; it does not state
`ConcaveOn` failure for the real-capacity step function.  Either add the exact
analytic declaration or, without expanding scope, change the Lean-facing
wording to “unit capacity increments need not diminish.”  Until one of those
repairs is made, the result is **FORMALIZATION PATCH**.

### 4. Proposition 5.7 omits a proof-critical path identity

The proof and Lean theorem require $I(x)=O(x)+G(x)$ on a neighborhood of
$x_0$, with all three derivatives taken along the same named path.  The
surrounding prose states this, but the proposition itself assumes only
differentiability.  Put the neighborhood accounting identity in the
proposition.

### 5. Proposition 5.9 uses undefined auxiliary notation

The manuscript introduces
$\Delta_n^{\mathrm{op},\mathrm{aux}}$ only in the proposition's conclusion.
Define it explicitly as the passive-value difference in the supporting
frozen-library process, or use the already defined passive difference after
stating the adapter.  The existing Lean result is the supporting F7 process;
it is not silently a theorem identifying every legacy process binder with the
unified T5 raw process.

### 6. Definition 6.1 must handle an empty project menu

The formula

\[
 \max\{\mathsf CV,\max_{q\in A(K)}\mathsf R_qV\}
\]

has an undefined inner maximum when $A(K)=\varnothing$, a case the paper
uses in Counterexample A.9.  Define the Bellman maximum over the nonempty
finite action set consisting of Continue plus all available projects, or say
that the inner term is omitted when the menu is empty.  The Lean operator
already uses the nonempty Continue-augmented action carrier, so Proposition
6.2 needs no proof patch.

## Result-by-result audit

### Section 3 — Dynamic library model and sufficient state

| Result and classification | Assumptions and conclusion | Dependencies and manuscript proof | Lean declaration if claimed | Julia fixture if used | Audit finding |
|---|---|---|---|---|---|
| **Definition 3.1, Compressed frontier–closure state — PASS** | Finite raw library (L), pointwise frontier (F_L), extensive/monotone/idempotent closure (C_L). Defines (K_L=(F_L,C_L)) and the finite realizable image. | Depends on the Section 3 catalog, inactive strategy, and closure definitions. Well-definedness and finiteness are immediate; local-update algebra is in Appendix A, `app:proofs-quotient`. | `StrategyInnovation.compressedLibraryState`; raw counterpart `Raw.compressedLibraryState`; update theorem `Raw.compressedLibraryState_rawLibraryUpdate`. | `RawDynamicProgramming.jl`; exact raw-update tests. | Productive compression intentionally excludes (W(L)); the text correctly warns that equal (K) may have unequal burdens. |
| **Theorem 3.2, Raw-to-compressed controlled Markov projection — PASS** | Finite exact raw model; derived admission; completion coupling with the stated path and outcome marginals; primitives factor through (K); (d_q\ge1); (0\le\beta<1). Concludes normalized realizable pushforwards, representative invariance, embedded semi-Markov projection, finite-horizon value equality, stationary fixed-point equality, and selector lift. | R0 local update, exact pushforward, strong induction on calendar horizon, then the unified contraction. Proof: Appendix A, `app:proofs-quotient`; stationary portion: Appendix D, `app:dynamic-solution-proof`. | `Projection.Model.inducedCompressedTransition_wellDefined`, `same_compressedState_same_next_probability`, `projectedProcess_controlledMarkov`, `rawValue_eq_compressedValue`, `rawInfiniteHorizonValue_eq_compressed`, and `liftedRawStationarySelector_policyEvaluationEquation`. | `search_revision_counterexamples.jl`; FX-T1-CORRELATED-01; unified canonical raw/compressed fixtures. | No independence is used. Markovity is correctly limited to embedded decision epochs; the text explicitly requires project/remaining-duration state between epochs. Raw and compressed timing match. |

### Section 4 — Optimal innovation-safe compression

| Result and classification | Assumptions and conclusion | Dependencies and manuscript proof | Lean declaration if claimed | Julia fixture if used | Audit finding |
|---|---|---|---|---|---|
| **Theorem 4.1, Minimum-resource innovation-safe representation — PASS** | Finite source-relative safe fiber; additive burden; stationary claims additionally use the unified contraction. Concludes nonempty finite feasible set, attained minimum burden, equal finite-horizon productive values, and equal stationary value and complete optimal-action correspondence within the fiber. | The source is feasible; finite powerset gives attainment; Theorem 3.2 and Proposition 6.2 give productive consequences. Proof: Appendix B, `app:safe-optimization-proof`. | `Optimization.exactSafeCompressionFeasible_source`, `exists_minimumWeight_exactSafeCompression`, `exists_minimumWeightSafeCompression`, `SafeCompressionFeasible.preserves_finiteHorizonValue`, `preserves_infiniteHorizonValue`, and `preserves_optimalActions`. | `ResourceOptimization.jl`; complete exact safe-sublibrary enumeration. | No uniqueness, greedy, exchange, or detectability assumption is used for forward preservation or existence. |
| **Definition 4.2, Deletion redundancy — PASS** | Active (s\ne s_0). Defines operational redundancy by full belief-indexed frontier equality and generative redundancy by closed-capability equality after deletion. | Depends only on (F_L,C_L) and erasure. No proof. | `Projection.Model.operationallyRedundant`, `generativelyRedundant`, and `RedundantDeletion`. | Exact deletion tests in `Compression.jl` and `test_compression.jl`. | Correctly compares all beliefs and closed capabilities, not current payoff or duplicated raw module rows. |
| **Definition 4.3, Dynamic innovation equivalence — PASS** | Unified raw process with availability tags. Defines equality of frontier, tagged cost, tagged duration, projected joint terminal law, and expected incumbent operating block for every belief/project. | Depends on Theorem 3.2's projected process. No proof; equivalence laws are Proposition A.3. | `Projection.Model.DynamicInnovationEquivalent`. | Full-signature comparisons in `search_revision_counterexamples.jl`. | Availability is encoded by `Option` tags. The joint law is retained; conditional independence is neither assumed nor inferred. |
| **Theorem 4.5, Frontier–closure characterization and safe deletion — PASS** | Raw primitives factor through (K); converse alone assumes `RawClosureDetectable`; stationary clauses assume contraction. Concludes (K)-equality implies DI, detectability gives the iff, deletion safety is frontier plus closure equality, and values/actions are preserved. | Theorem 3.2, UDI observation equality, and closure detectability. Proof: Appendix A, `app:proofs-quotient`. | `frontierClosure_eq_implies_dynamicInnovationEquivalent`, `dynamicInnovationEquivalent_iff_frontierClosure_eq`, `redundantDeletion_iff_compressedLibraryState_eq`, `deletionProcessObservations_iff_redundant`, and stationary preservation declarations. | T2/T3 exact gauntlets; silent-closure boundary fixture. | Factorization, closure detectability, and value preservation are not conflated. Detectability is used only for necessity. |
| **Corollary 4.6, Rechecked pruning certificate — WORDING PATCH** | Each accepted erasure is re-evaluated on the current library and preserves both (F) and (C). Concludes endpoint (K)-equality, DI, safe feasibility, value preservation, and one-deletion irreducibility after a complete final scan. | Composition of Theorem 4.5 at every trace step. Proof: Appendix A, `app:proofs-quotient`, and Appendix B, `app:safe-optimization-proof`. | `RedundantDeletionSequence.compressedLibraryState_final_eq_initial`, `.dynamicInnovationEquivalent`, `.preserves_finiteHorizonValue`, and `recheckedSafeDeletionEndpoint_feasible`. | Rechecked traces in `ResourceOptimization.jl` and compression tests. | The corollary is true. Patch the following prose: in this monotone safe fiber, one-deletion and inclusion-wise irreducibility are equivalent, not distinct strengths. Neither implies global minimum weight. |
| **Proposition 4.7, Certified pruning specification — PASS** | A pruning output is accompanied by a current-state-rechecked deletion trace. Concludes per-step safety and endpoint productive-value preservation. | Theorem 4.5 and Corollary 4.6. Proof: Appendix A, `app:proofs-quotient`. | `Projection.Model.PruningAlgorithmSpec`, `.everyDeletion_safe`, `.output_dynamicInnovationEquivalent`, and `.output_preserves_finiteHorizonValue`. | Trace certificates from exact Julia pruning routines. | It makes no optimality claim and correctly treats the trace as the certificate. |
| **Example 4.8, Why deletion certificates must be rechecked — PASS** | Two strategies are the only carriers of one module. Each is initially redundant, but after one deletion the survivor is essential. | Direct finite closure calculation at the statement; boundary discussion in Appendix A. | `UnifiedSafeDeletionExamples.stale_doubleDeletion_changes_compressedState` and `staleOriginalRedundancyChecks_doNotCompose`. | Batch-deletion regression in `search_counterexamples.jl`. | Correctly refutes stale simultaneous reuse, not single-deletion safety. |
| **Theorem 4.9, Local/global boundary — PASS** | Strictly positive active weights; exact safe fiber. Concludes every global minimum is one-deletion irreducible, rechecked traces are safe, irreducibility need not imply global optimality, and unique-heaviest-safe-first can be suboptimal. | Strict burden reduction under a safe deletion; exact finite counterexamples. Proof: Appendix B, `app:safe-optimization-proof`. | `MinimumWeightSafeCompression.oneDeletionIrreducible`, `SafeCompressionCounterexample.recheckedEndpoint_need_not_be_globallyMinimum`, and `strictHeaviestFirst_greedy_not_globallyOptimal`. | `search_resource_optimization_counterexamples.jl`; CX-OPT-PRUNE-CARDINALITY-01 and CX-OPT-GREEDY-WEIGHT-01. | Global language is correct: the positive theorem is one-way, and both converse failures are exact exhaustive constructions. |
| **Example 4.10, Safe greedy versus the global optimum — PASS** | Identity closure; zero profiles; weights (2,2,3); source contains two singleton carriers and their bundle. Concludes greedy endpoint burden (4) versus unique global safe burden (3). | Direct enumeration of the five safe active sets; Appendix B, `app:safe-optimization-proof`. | Exact instance behind `SafeCompressionCounterexample.strictHeaviestFirst_greedy_not_globallyOptimal`. | `02_cx_opt_greedy_weight_01.json` / registered ((2,2,3)) resource fixture. | Arithmetic, safe sets, order dependence, and uniqueness of the minimum are correct. Productive values agree because both endpoints have the same (K). |
| **Theorem 4.11, Sharp normalized frontier-only relaxation loss — WORDING PATCH** | Intended canonical one-project bridge: (d\ge1), (0\le\beta<1), (0\le\rho,\pi\le1), (C,\kappa\ge0), worthwhile margin, unique carrier, zero descendant mass after deletion, and common operating comparison. Concludes exact net loss, cap sharpness, normalized loss one, and unit-cap bound. | Canonical raw bridge law and unified (beta^d) timing. Proof: Appendix B, `app:bridge-catalog`. | `NormalizedPruningLoss.canonicalPruningLoss_exact`, `rewardCap_sharp`, `destroys_all_attainable_descendant_value`, `unitRewardCap_loss_le_one`, and the continued-operation cancellation declarations. | Exact F4/FX-T4-UNIFIED-01 specialization. | Define `Loss_d` and explicitly restrict the equality to the canonical comparison whose complete distinguished terminal gain is capped by (C). Otherwise extra differential continuation opportunities could make the equality false. The proof itself is sound at the canonical scope. |
| **Corollary 4.12, Arbitrary additive loss only by scaling — WORDING PATCH** | Parent canonical bridge with ((d,\beta,\rho,\pi,\kappa,C)=(1,1/2,1,1,0,2M)). Concludes loss (M). | Substitution into Theorem 4.11; Appendix B, `app:bridge-catalog`. | `NormalizedPruningLoss.arbitraryLoss_by_rewardScaling`. | Deterministic bridge fixture. | Exact algebra. It inherits only the parent result's missing definition/scope wording; it does not claim unbounded normalized loss. |
| **Theorem 4.13, Finite capacity-constrained retention — FORMALIZATION PATCH** | Fixed nonempty finite eligible family with a zero-burden inactive library; capacity does not alter productive dynamics. Concludes attainment, monotonicity, constancy between attainable burdens, finite nonnegative forward shadows, and a two-module increasing-increment/nonconcavity boundary. | Finite feasible-set nesting and the ((0,0,1)) complementarity witness. Proof: Appendix B, `app:capacity-proof`. | `FiniteCapacityProblem.exists_capacityOptimizer_of_inactive_feasible`, `capacityValue_mono`, `capacityValue_constant_between_attainableBurdens`, breakpoint/shadow declarations; witness `CapacityComplementarityCounterexample.capacityValue_zero/one/two`, `increasing_marginal_capacity_value`, and `diminishing_capacity_returns_fail`. | `ResourceOptimization.jl`; CX-OPT-CAPACITY-NONCONCAVE-01 and CX-OPT-CAPACITY-INCREASING-RETURNS-01. | Human theorem is valid. Named Lean evidence proves failure of diminishing unit increments, not an explicit ordinary `ConcaveOn` failure. Patch the formal correspondence or narrow the Lean-facing wording. No nestedness or uniqueness is asserted. |
| **Theorem 4.14, Finite penalized value envelope — PASS** | Fixed nonempty finite price-independent family; finite values; nonnegative burdens; real (lambda\ge0). Concludes attainment, continuity, nonincrease, convex finite piecewise-affine structure, finite candidate crossings, all-optimizer-pairs burden order, and slope on a strictly dominant branch. | Finite maximum of affine branches and two optimality inequalities. Proof: Appendix B, `app:penalized-proof`. | `FinitePenalizedProblem.envelope_is_finite_maximum`, `envelope_antitone`, `envelope_convex`, `continuous_envelope`, switching-price/breakpoint declarations, `optimalBurden_antitone`, and `hasDerivAt_envelope_of_strictlyDominatesOn`. | `ResourceOptimization.jl`; registered PEN burden, tie, kink, and nonnested-switch fixtures. | Candidate intersections are correctly distinguished from active breakpoints. Ties are retained; no uniqueness, raw nesting, or differentiability at a tie is claimed. |

### Section 5 — Value, comparative statics, and elasticity

| Result and classification | Assumptions and conclusion | Dependencies and manuscript proof | Lean declaration if claimed | Julia fixture if used | Audit finding |
|---|---|---|---|---|---|
| **Definition 5.1, Insertion-value channels — PASS** | Unified finite-horizon full value (U_n), passive frozen-library value (P_n), and premium (Omega_n=U_n-P_n). Defines total, operational, and residual generative insertion changes. | Depends on Theorem 3.2's raw process and the passive recursion. No proof. | `UnifiedDecomposition.researchOptionPremium`, `totalInsertionValue`, `operationalInsertionValue`, and `generativeInsertionValue`. | Exact APIs in `InnovationValue.jl`. | Resource burden is correctly excluded from the productive channel accounting. The generative term is a residual and is not assumed nonnegative. |
| **Theorem 5.2, Operational–generative value decomposition — PASS** | Every finite horizon, belief, raw library, and catalog candidate. Concludes total insertion value equals passive operational change plus premium change. | Algebra from Definition 5.1. Proof: Appendix A, `app:proofs-value`. | `UnifiedDecomposition.totalInsertionValue_eq_operational_add_generative`. | Exact decomposition tests; controlled channel fixtures. | Exact accounting identity; no sign, stationarity, or independence claim is smuggled into it. |
| **Corollary 5.3, Frontier-silent insertion — PASS** | Equal frontier; second clause also equal closure. Concludes zero passive operational change, then zero total productive change. | Passive recursion plus Theorem 3.2. Proof: Appendix A, `app:proofs-value`. | `operationalInsertionValue_eq_zero_of_frontier_eq` and `totalInsertionValue_eq_zero_of_frontier_closure_eq`. | Exact bridge/channel tests. | Closure equality is used only for the total-value clause. Correct raw/compressed distinction. |
| **Example 5.4, Operationally silent, generatively valuable bridge — PASS** | One belief; zero-profile unique carrier; duration one; zero cost; suspended operation; (beta=1/2); descendant payoff two. Concludes channel pair ((0,1)) at horizon two. | Direct Bellman calculation at the statement; Appendix A bridge discussion. | `UnifiedDecomposition.BridgeExample.bridge_operational_zero_generative_positive`. | Exact InnovationValue bridge fixture. | Timing is consistent: the payoff two arrives one date later and is discounted once. |
| **Theorem 5.5, Joint descendant-event generative-option lower bound — PASS** | Frontier silence; retained-only feasible project (q); (d\le h); exact cost; deleted comparator premium zero; supportwise complete full-minus-passive gain floor (G\ge0); failure unchanged; other outcomes insertion-only; full continuation contains the passive policy. Concludes the nonnegative part of cost plus operating adjustment plus the discounted joint descendant-event gain. | Theorem 5.2, full value dominates Continue and commitment to (q), insertion monotonicity, and the exact joint completion law. Proof: Appendix A, `app:proofs-value`. | `GenerativeLowerBound.JointGenerativeCarrierCertificate`, `generativeInsertionValue_lowerBound_joint_terminalWeighted`, `generalizedGenerativeOptionLowerBound`, and commitment-accounting declarations. | `search_joint_descendant_bound.jl`; `test_joint_descendant_bound.jl`; exact one- and two-belief survivor fixtures. | Primary theorem keeps the joint law intact and includes the operating-timing adjustment. It does not replace the joint mass by a product, omit harmful outcomes, or assume an unconditional duration sign. |
| **Corollary 5.6, Product specialization and signs — PASS** | Explicit factorization (eta=\pi\rho^d\mu); other terms fixed for comparisons. Concludes the product form and monotonicities in joint mass/gain/adjustment/cost, while total mass alone has no sign if its terminal distribution changes. | Direct substitution in Theorem 5.5. Proof: Appendix A, `app:proofs-value`. | `expectedJointDescendantGain_eq_independentProduct`, `generalizedGenerativeOptionLowerBound_of_independence`, and monotonicity declarations. | Same T6 joint-law gauntlet, including correlated counterexamples. | Conditional independence is a sufficient route to the displayed factorization, not a hidden premise of the primary theorem. The qualification on changing terminal distribution is correct. |
| **Proposition 5.7, Operational–generative elasticity contributions — WORDING PATCH** | Intended: (x_0>0); common differentiable path; neighborhood identity (I=O+G); (I(x_0)>0); component positivity only for share-weighted component elasticities. Concludes signed contributions sum to total elasticity and, on positive channels, the share-weighted formula. | Differentiation of the neighborhood identity. Proof: Appendix C, “Value-channel and bridge-margin calculations.” | `Value.ChannelAccountingAt`, `operational_generative_derivative_decomposition`, `operational_generative_contribution_decomposition`, and `operational_generative_weightedAverage_elasticity`. | Registered exact model instances only; no reusable generic Julia CED routine. | Put the neighborhood identity and common-path condition into the proposition itself. The proof and Lean result already require them. Zero-component and zero-total denominator boundaries are otherwise correct. |
| **Definition 5.8, Positive gap and discounted gap sum — PASS** | Fixed candidate, frozen library, finite horizon, common belief kernel, (0\le\beta<1). Defines positive frontier gap and its finite discounted recursion. | Frontier maximum and passive belief evolution. No proof. | `InnovationEquation.frontierGap` and `discountedGapSum`. | `frontier_gap` and `discounted_gap_sum` in `InnovationValue.jl`. | This is explicitly a supporting passive object, not a research-option or stationary value. |
| **Proposition 5.9, Passive gap-sum identity — WORDING PATCH** | Supporting frozen-library passive process. Concludes passive insertion value equals the recursive gap sum and discounted occupation expansion. | Pointwise max identity and finite-horizon recursion. Proof: Appendix A, `app:proofs-value`. | `InnovationEquation.passiveOperationalInnovation_eq_discountedGapSum`. | Exact F7 adapter test and strategy-value-equation fixture. | Define (Delta_n^{\mathrm{op},\mathrm{aux}}), which otherwise first appears in the conclusion. Keep the supporting-process adapter explicit; do not silently identify legacy and unified binders. |
| **Corollary 5.10, Zero current gap, positive future operating value — PASS** | Deterministic move to a belief with gap two; (n=2); (beta=1/2). Concludes passive operational value one. | Proposition 5.9 by direct substitution. Proof: Appendix A, `app:proofs-value`. | `InnovationEquation.DelayedBenefitExample.zero_currentGap_positive_passiveOperationalInnovation`. | Exact delayed-benefit fixture. | Correctly shows that a zero current gap does not imply zero finite-horizon passive value. |
| **Proposition 5.11, Diminishing marginal operational innovation — PASS** | Same candidate and passive process; (L\subseteq L'). Concludes insertion's passive operational value is weakly smaller against the larger library. | Frontier monotonicity lowers the positive gap; nonnegative discounted expectation preserves order. Proof: Appendix A, `app:proofs-value`. | `UnifiedDecomposition.operationalInsertionValue_antitone_of_library_inclusion` and supporting `InnovationEquation.passiveOperationalInnovation_antitone_of_library_inclusion`. | Exact operational-insertion tests. | Scope is only the operational passive channel. It does not claim submodularity of full productive value or diminishing capacity returns. |

### Section 6 — Dynamic solution

| Result and classification | Assumptions and conclusion | Dependencies and manuscript proof | Lean declaration if claimed | Julia fixture if used | Audit finding |
|---|---|---|---|---|---|
| **Definition 6.1, Unified Continue, research, and Bellman operators — WORDING PATCH** | Finite realizable state; exact joint completion law; positive project duration; (0\le\beta<1). Defines Continue, each research action, and their Bellman maximum. | Section 3 timing and local compressed update. No proof. | `Projection.Model.compressedInfiniteActionValue`, `rawInfiniteActionValue`, `compressedBellmanOperator`, and `rawBellmanOperator`. | `RawDynamicProgramming.jl` and unified solver implementations. | Replace the possibly empty inner project maximum by one maximum over Continue plus available projects, or state the empty-menu convention. This matches Lean and Counterexample A.9. |
| **Proposition 6.2, Finite-state contraction and selectors — PASS** | Finite carriers; exact bounded primitives; (d(q)\ge1); (0\le\beta<1); Continue-augmented finite action set. Concludes finite-horizon attainment, raw/compressed monotone (beta)-contractions, unique fixed points, projection and DI value equality, stationary selector existence/policy evaluation/lift, and the geometric error bound. | Theorem 3.2, nonexpansive exact expectation, (beta^{d(q)}\le\beta), finite maxima, and Banach contraction. Proof: Appendix D, `app:dynamic-solution-proof`. | `finiteHorizonAction_attained`, `compressedBellmanOperator_contracting`, `rawBellmanOperator_contracting`, fixed-point/value-iteration declarations, `exists_stationaryOptimalSelector`, and selector lift/evaluation declarations. | FX-S2-UNIFIED-STATIONARY-01 and unified canonical exact policy iteration. | Finite-horizon and stationary claims are separated correctly. Uniqueness is invoked only for fixed points and policy evaluation; no unique optimizer is assumed. It passes once Definition 6.1's empty-menu notation is repaired. |

### Appendix A — Structural results

| Result and classification | Assumptions and conclusion | Dependencies and manuscript proof | Lean declaration if claimed | Julia fixture if used | Audit finding |
|---|---|---|---|---|---|
| **Lemma A.1, Finite-library frontier and closure calculus — PASS** | Nonempty finite inactive-containing library; inactive profile zero; monotone closure. Concludes frontier bounds/attainment/nonnegativity and frontier/closure monotonicity under inclusion. | Finite maximum and closure monotonicity. Proof is adjacent in Appendix A. | `operationalProfile_le_frontier`, `zero_le_operationalFrontier`, `exists_profile_eq_operationalFrontier`, `operationalFrontier_mono`, and `generativeClosure_mono`. | Exhaustive F0 fixture tests in `julia/test/core.jl`. | Every stated assumption is visible. Hidden-state expectation is not part of this lemma's Lean claim. |
| **Example A.2, A two-module generator — PASS** | Two beliefs, identity closure, two required modules, generation probability (2/3), verification (3/4), and specified payoff row. Concludes admission probability (1/2), module necessity, profiles ((-1/4,5/4)), and a positive-duration instance. | Direct rational multiplication and belief expectation at the statement. | No exact manuscript-example declaration is claimed; foundational catalog/closure examples are compiled separately. | None used for this exact displayed example. | Arithmetic and the distinction between belief-dependent payoff and closure-dependent availability are correct. |
| **Proposition A.3, Dynamic innovation equivalence relation — PASS** | Definition 4.3. Concludes reflexivity, symmetry, and transitivity. | Componentwise equality. Adjacent proof in Appendix A. | `Projection.Model.dynamicInnovationEquivalent_refl`, `_symm`, and `_trans`. | Full-signature comparison tests are ancillary. | Exact equivalence relation; no bisimulation-minimality claim. |
| **Theorem A.4, Dynamic innovation quotient and value sufficiency — PASS** | DI equality; finite raw-library carrier; stationary clause additionally uses contraction. Concludes finite and stationary value equality, finite quotient, value factorization, and (K)-equality sufficiency. | Tagged menu equality, action-value equality, strong horizon induction, then contraction iteration. Adjacent proof in Appendix A. | `rawValue_eq_of_dynamicInnovationEquivalent`, `finiteHorizonValue_depends_only_on_dynamicInnovationClass`, `dynamicInnovationQuotientFinite`, `rawFixedPoint_eq_of_dynamicInnovationEquivalent`, and `compressedState_eq_implies_dynamicInnovationEquivalent`. | Unified signature/value oracle. | Expected operating block plus the full terminal joint law is sufficient by additivity; no path/outcome independence is needed. |
| **Proposition A.5, Restricted representation refinement — PASS** | Arbitrary representation (r) whose equal fibers preserve all five DI observations. Concludes equality of (r) implies DI. | Direct application of the assumed observation preservation. Adjacent proof. | `Projection.Model.representation_refines_dynamicInnovationEquivalent`. | None used. | Correctly restricted; it is not a coarsest quotient, full abstraction, or generic canonical-map theorem. |
| **Proposition A.6, Research-premium monotonicity under project dominance — PASS** | Equal frontier; closure enrichment context; every old project remains feasible; complete action values weakly improve; richer state may add actions. Concludes finite-horizon premium monotonicity and nonnegative generative value for a frontier-silent insertion satisfying the certificate. | Finite-horizon maximization and common passive value. Adjacent proof in Appendix A. | `UnifiedDecomposition.researchOptionPremium_mono_of_closureEnrichmentProjectDominance`. | No dedicated generic Julia fixture. | The explicit action-dominance certificate does the proof-critical work. Closure inclusion is economically contextual once menu inclusion and action dominance are separately assumed; retaining that narrower assumption does not invalidate the result. |
| **Example A.7, Exact one-belief retained carrier — PASS** | (d=1,\beta=1/2,\kappa=0,\pi=\rho=1); zero frontier; descendant gain two; no comparator project. Concludes lower bound one. | Theorem 5.5 specialization. Calculation is adjacent. | `GenerativeLowerBound.OneBeliefExample.exact_lowerBound_one` and carrier-example declarations. | Exact T6 one-belief survivor fixture. | Correct positive-duration discount and zero operating adjustment. |
| **Counterexample A.8, Raw identifiers defeat frontier–closure sufficiency — PASS** | Broader generator is allowed to inspect hidden raw membership. Equal (F,C) libraries then get different candidate and next-compressed-state laws. | Exact finite construction stated in Appendix A. | `RawFrontierClosureCounterexamples.sufficiency_fails_when_generator_uses_raw_identifiers` and `rawIdentifierGenerator_not_factorized`. | Raw-identifier boundary in `search_revision_counterexamples.jl`. | Correctly violates raw factorization; it does not refute Theorem 4.5 under its assumptions. |
| **Counterexample A.9, Behaviorally invisible raw closure — PASS** | Empty project menu at every state; equal frontiers; unequal closures. Concludes identical five DI observations despite closure inequality. | Exact finite construction stated in Appendix A. | `RawFrontierClosureCounterexamples.converse_fails_when_closure_behaviorally_invisible` and `silentProcess_not_rawClosureDetectable`. | Silent-module boundary fixture. | Correctly isolates detectability as necessary only for the converse. It also confirms why Definition 6.1 must handle empty menus. |

### Appendix C — Counterexamples, coverage, and interaction

| Result and classification | Assumptions and conclusion | Dependencies and manuscript proof | Lean declaration if claimed | Julia fixture if used | Audit finding |
|---|---|---|---|---|---|
| **Counterexample C.1, A nonmonotone kernel defeats the upper threshold — PASS** | Three-state deterministic row-stochastic kernel with destinations ((1,0,1)); increasing gap ((0,1,2)); unit scale/cost. Concludes potential ((1,0,1)) and disconnected weak covering set ({0,2}); also maps a single peak to the same disconnected shape. | Direct matrix evaluation in Appendix C. | `SingleGapCounterexamples.destructiveKernel_expectedGap`, `singlePeakedGap_disconnectedPotential`, `destructiveKernel_not_stochasticallyMonotone`, and `nonmonotoneKernel_disconnectedCostCoveringSet`. | Exact single-gap geometry fixture and `test_coverage.jl`. | Correctly violates stochastic monotonicity and no other positive-theorem premise. |
| **Counterexample C.2, Non-antitone cost disconnects a monotone covering set — PASS** | Increasing potential ((1,2,3)); cost ((0,3,0)). Concludes disconnected set ({1,3}). | Direct comparison in Appendix C. | `SingleGapCounterexamples.nonAntitoneCost_disconnectedCostCoveringSet`. | Exact single-gap cost fixture. | Correctly isolates failure of antitone cost. |
| **Counterexample C.3, One-project multi-gap disconnection — PASS** | Five beliefs; two endpoint gaps from one project; Bernstein/binomial kernel; unit strict cost. Concludes potential ((4,41/32,1/2,41/32,4)) and two-component region. | Exact finite matrix multiplication in Appendix C. | `Counterexamples.MultiGapRegion.project_fills_two_separated_strategyLibraryGaps`, `coveragePotential_eq`, `strictCostCoveringSet_eq`, and `separatedMultiGap_disconnectedCostCoveringSet`. | `search_multi_gap_topology.jl`; exact generated Lean/Julia fixture. | Exact and correctly limited to one-shot coverage; no universal topology theorem is inferred. |
| **Counterexample C.4, Arbitrary cost defeats a component bound — PASS** | Same kernel; constant potential two; alternating cost ((0,3,0,3,0)). Concludes strict set ({0,2,4}). | Direct comparison in Appendix C. | `Counterexamples.MultiGapRegion.unrestrictedCost_defeats_generalComponentBound`. | Multi-gap topology fixture. | Correctly shows kernel regularity alone cannot bound net-region components under unrestricted costs. |
| **Definition C.5, Certified gap and coverage potential — PASS** | Fixed supplied candidate; nonnegative occupation weights; finite horizon; discount/survival interpretation. Defines positive gap, discounted occupation, and finite potential. | Frontier and finite sums. No proof. | `Coverage.certifiedGap`, `discountedOccupationWeight`, and `coveragePotential`. | `Coverage.jl` finite-occupation APIs. | Explicitly gross and operational; the weights need not be normalized probabilities. |
| **Theorem C.6, Exact finite coverage representation — PASS** | Definition C.5's finite tables. Concludes belief-first potential equals the date-first double sum. | Finite distributivity and sum commutation. Proof: Appendix C, `app:proofs-coverage`. | `Coverage.coveragePotential_eq_oneShotGrossOperationalResearchValue`. | Exact date-first/occupation-first coverage tests. | Definitional finite rearrangement; no limiting or Bellman-optimality claim. |
| **Corollary C.7, Finite occupation bounds — PASS** | Nonnegative gaps/weights; nonempty comparison region for the lower bound; support restriction for the regional upper bound. Concludes minimum-gap lower and maximum-gap upper bounds. | Termwise finite order. Proof: Appendix C, `app:proofs-coverage`. | `minimumGapOn_mul_regionOccupation_le_coveragePotential`, `coveragePotential_le_maximumGap_mul_totalOccupation`, and regional-bound declarations. | Exact coverage-bound tests. | All sign and support assumptions needed by the inequalities are present. |
| **Example C.8, Delayed coverage — PASS** | Two beliefs; current gap zero; next gap two; (H=2,\beta=1/2,\rho=1). Concludes potential one. | Direct substitution at the statement. | `Coverage.DelayedCoverageExample.zero_currentGap_positive_coveragePotential`. | Exact delayed-coverage fixture. | Correctly distinguishes current screening from finite future occupation. |
| **Definition C.9, One-shot cost-covering region — PASS** | Finite ordered grid, exact kernel, nonnegative scale interpretation, and cost table. Defines gross one-shot value and weak covering set. | Finite expectation. No proof. | `Coverage.oneShotCostCoveringSet` and associated gross-value definitions. | `Coverage.jl` `cost_covering_set`. | Explicitly not an optimized Bellman research region. |
| **Theorem C.10, Monotone-gap upper-threshold theorem — PASS** | Nonempty finite linear order; exact row-stochastic and first-order stochastically monotone kernel; increasing nonnegative gap and scale; (beta\ge0); antitone cost. Concludes increasing gross value and an empty-or-upper-threshold covering set. | Expectation monotonicity, product order under nonnegativity, and finite upper-set geometry. Proof: Appendix C, `app:proofs-coverage`. | `Coverage.grossCoverageValue_monotone`, `oneShotCostCoveringSet_isUpperSet`, and `monotoneGap_upperThreshold`. | Exact positive fixture plus 60,000-configuration boundary audit. | Scope is properly one-shot. It neither asserts preservation of arbitrary single peaks nor characterizes the Bellman policy region. |
| **Proposition C.11, One-shot cutoff comparative statics — PASS** | Pointwise change in one primitive with all other one-shot primitives fixed; threshold comparison requires both sets nonempty. Concludes set and cutoff directions for cost, survival/admission, and fixed-candidate frontier changes. | Monotonicity of the defining inequality and reversal between upper-set inclusion and cutoff order. Proof: Appendix C, `app:proofs-coverage`. | `oneShotCostCoveringSet_antitone_cost`, `_mono_survival`, `_mono_admissionProbability`, `_antitone_frontier`, and cutoff-order declarations. | Reusable exact coverage comparative-static tests. | No full-policy or changing-menu comparison is claimed. “Higher” should continue to be read pointwise, as in the proof and Lean declarations. |
| **Theorem C.12, Finite patience–survival complementarity — PASS** | Finite exact nonnegative transition matrix in the model's row-stochastic class; nonnegative gap; finite horizon; ordered nonnegative discount/survival pairs. Concludes monotonicity and nonnegative cross difference. | Exact factorization into ((\beta_1^t-\beta_0^t)(\rho_1^t-\rho_0^t)P^tg). Proof: Appendix C, `eq:discount-survival-factorization`. | `finiteHorizonPotential_mono_discount`, `_mono_survival`, `finiteHorizonPotential_crossDifference_eq_factorized`, and `_nonnegative`. | `finite_discount_survival_interaction` exact fixture. | Row-stochastic normalization is stronger than the sign algebra needs but is a legitimate model restriction; removing it would broaden scope and is not recommended here. No stationary/resolvent theorem is claimed. |
| **Proposition C.13, Opposite persistence effects — PASS** | Symmetric two-state kernel; (H=2); effective discount (1/2); persistence (1/4\to3/4); three nonnegative gaps. Concludes exact increase, decrease, and no-change cases. | Direct two-state evaluation. Proof: Appendix C, “Belief-kernel alignment and persistence.” | `higherPersistence_raises_coverage`, `higherPersistence_lowers_coverage`, `higherPersistence_no_effect`, and no-universal-sign declarations. | `run_kernel_persistence_response.jl`; 135 exact rows. | Arithmetic is correct and refutes both universal persistence directions. |
| **Theorem C.14, Advantage-region occupation alignment — PASS** | Finite kernels; (g\ge0); discounted occupation under (P_1) dominates (P_0) at every positive-gap state. Concludes componentwise potential dominance. | Finite occupation decomposition and termwise multiplication by nonnegative gaps. Proof: Appendix C, “Belief-kernel alignment and persistence.” | `finiteEffectivePotential_eq_discountedOccupation` and `coverage_mono_of_occupationDominatesOnAdvantage`. | Same kernel-response surface. | The sign-bearing assumption is occupation alignment, not scalar persistence. Kernel stochasticity is contextual, not secretly used to infer the order. |
| **Definition C.15, Closure increment and interaction — PASS** | Four realizable frontier–closure corners. Defines closure increment and cross difference (J_h); signs label substitution/complementarity. | Finite optimized values. No proof. | `SystemInteraction.closureIncrement` and `interactionCrossDifference` / compressed counterparts. | `frontier_closure_interaction_surface`. | Correctly requires realizable corners and keeps the zero case compatible with both weak sign labels. |
| **Theorem C.16, Frontier–closure substitution under relative saturation — PASS** | Realizable rectangle; frontier-independent availability/cost/duration/operation/joint law; rich menu contains poor menu; all rich/poor action pairs satisfy relative saturation at every finite Bellman node. Concludes decreasing closure differences and (J_h\le0). | Transport high-rich and low-poor maximizers, apply the all-pairs inequality, then finite-max bounds. Proof: Appendix C, `app:interaction-proof`. | `SystemInteraction.compressedInteractionCrossDifference_nonpositive` and relative-saturation declarations. | Exact T7 response surface and realizable-rectangle fixtures. | Closure, factorization, and relative action saturation are not conflated. The theorem does not rely on individual project saturation or ignore optimizer switching. |
| **Proposition C.17, Primitive common-gap frontier saturation — PASS** | Theorem C.16's rectangle and frontier independence; common-gap action factorization; (g_1\le g_0); rich exposures nonnegative; all poor exposures zero. Concludes relative saturation and substitution. | Direct cancellation and nonnegative exposure multiplication; recursive gap order uses a common positive kernel. Proof: Appendix C, `app:interaction-proof`. | `relativeActionSaturation_of_commonGap`, `compressedInteractionCrossDifference_nonpositive_of_primitiveSaturation`, and `PrimitiveSubstitution.canonical_frontier_closure_substitutes`. | `search_primitive_substitution.jl`; exact zero-poor-exposure survivor rows. | The narrow zero-poor-exposure boundary is explicit. No arbitrary optimized continuation is claimed to preserve the factorization. |
| **Proposition C.18, Complementarity from project switching — PASS** | Exact one-belief menu; (beta=1/2); descendant payoff ten; frontiers zero/eight; old and added projects with specified probabilities/costs. Concludes individual premia fall but optimized closure increment rises from zero to (1/2). | Direct comparison of two project branches and Continue. Proof: Appendix C, `app:interaction-proof`. | `SystemInteraction.Examples` project-switching strict-complementarity declarations. | Exact T7 menu-switch fixture. | Correctly refutes “frontier independence plus individual saturation implies substitution.” It violates the theorem's relative all-pairs premise, so it is not a counterexample to Theorem C.16. |

## Unnumbered mathematical claims requiring special attention

### Bridge elasticity — PASS

Assumptions are fixed integer duration, strictly positive gross coordinates,
positive bridge margin, one named coordinate varied at a time, and all other
coordinates fixed.  The conclusion in `eq:bridge-elasticities` follows from
the monomial derivative and the positive-margin identity between signed
margin and realized loss.  The proof is in Appendix C, “Value-channel and
bridge-margin calculations.”  Lean declarations are the
`Compression.hasDerivAt_bridgeMargin_*`, `hasDerivAt_bridgeLoss_*`,
`bridgeLoss_*_elasticity`, and normalized-margin fragility families.  The
registered bridge calculation is an exact Julia instance, not the generic
proof.  The zero-margin and costless-vanishing-gross boundaries are stated
correctly.

### Innovation duration display — FORMALIZATION PATCH

The finite fixed-exposure mathematics is correct under
$\alpha>0$ and a nonnegative nonzero fixed exposure sequence.  Appendix C
proves the scaled identities
$\alpha\Psi'=N_1$ and $\alpha D'=C$, with $C$ the timing variance.
Lean proves those polynomial/quotient derivative identities through
`Coverage.scaled_potentialDerivative_eq_firstMoment` and
`scaled_durationDerivative_eq_timingVariance`.  It does not contain the
separate log-composition derivatives displayed in
`eq:innovation-duration`.  State the verified scaled identities in the
display and retain the log equations as chain-rule interpretation, or add the
exact composition declarations.  Do not broaden the claim to optimized
Bellman values or changing exposures.

### Canonical “innovation duration” rows — WORDING PATCH

The ratios $D_\beta=\beta V_\beta/V$ in Section 6 are exact registered
fixed-policy discount elasticities.  No named Lean adapter proves that the
stationary canonical value is the finite nonnegative fixed-exposure
polynomial used by the IDCV theorem; costs and infinite stationary
continuation make that identification nontrivial.  Preserve the numbers but
label them “exact local fixed-policy discount elasticities” unless and until
the adapter and its exposure-sign conditions are formalized.  They must not
inherit the general fixed-exposure duration theorem merely by notation.

### Positive-duration comparative statics — PASS

The manuscript does not claim that longer research is unconditionally worse.
It states the exact increment

\[
 R_{d+1}-R_d=\beta^d[F_d-(1-\beta)W]
\]

and assumes $F_d\le(1-\beta)W$ for an antitone-duration conclusion.  The
counterexample $\beta=1/2,F_d=W=1$ correctly shows why nonnegativity alone
is insufficient.  The descendant-event theorem likewise says duration has no
unconditional sign when the joint law, operating block, gain, or horizon
feasibility changes.

### Switching and resource-price claims — PASS

The current preprint limits the general theory to the finite PEN envelope.
Pairwise crossings are candidates until globally filtered; optimizer ties are
set-valued; optimal burdens are ordered across prices; raw libraries need not
be nested; branch slopes are asserted only under local strict dominance; and
one-sided or finite changes replace derivatives at actual switches.  The
removed general set-valued switching theorem has not re-entered the claim
package.

## Cross-cutting checks requested by the audit

| Check | Result |
|---|---|
| Assumptions used but absent | Patches required for Theorem 4.11's canonical comparison class and Proposition 5.7's neighborhood channel identity. Definition 6.1 also needs an empty-menu convention. |
| Assumptions stated but unnecessary | Proposition A.6's closure inclusion is contextual once complete action dominance/menu inclusion are separately assumed. Theorem C.12's row normalization is stronger than its sign algebra needs. Both narrower statements remain valid; no scope expansion is recommended. |
| Conclusion stronger than proof | No proof patch. Theorem 4.11 reads too generally until its canonical loss object is defined. Theorem 4.13's human conclusion exceeds the named Lean conclusion, not the human proof. |
| Finite-horizon versus stationary | Clean. Every stationary conclusion invokes the discounted contraction; F7/Coverage results remain finite; the canonical duration rows need relabeling rather than promotion to IDCV. |
| Raw versus compressed state | Clean. Productive equivalence uses (K); burden optimization retains (L) or (W(L)); no theorem claims the compressed productive state determines resource burden. |
| Conditional independence | Clean. T1 and T6 primary results retain the joint completion law. Independence appears only as an explicit product specialization. |
| Positive-duration timing | Clean after Theorem 4.11's comparison object is made explicit. Terminal continuation is discounted by (beta^d), operation occupies dates (0,ldots,d-1), and in-progress calendar state is acknowledged. |
| Closure/factorization/detectability | Clean. Factorization gives forward sufficiency; detectability gives only the observable converse; closure equality is not inferred from value equality. |
| Improper iff | No improper theorem-level iff found. The one-deletion/inclusion-wise discussion should be corrected because the two predicates are equivalent in this monotone fiber. |
| Hidden uniqueness | None. Ties are retained in safe, capacity, and penalized correspondences; selector existence does not assert a unique optimizer. |
| Global optimality language | Clean. Rechecked pruning is feasible/local; global claims use complete finite comparison or are explicitly solver-attributed in the financial audit. |

## Release disposition

No labeled mathematical result should be removed or broadened.  Before the
preprint's formal claim package is called fully reconciled:

1. patch the Corollary 4.6 irreducibility discussion;
2. define and canonically scope Theorem 4.11's loss, with Corollary 4.12
   inheriting that definition;
3. reconcile Theorem 4.13 ordinary nonconcavity with its Lean declaration;
4. add the neighborhood accounting hypothesis to Proposition 5.7;
5. define Proposition 5.9's auxiliary passive insertion value;
6. make Definition 6.1 total at empty research menus;
7. reconcile the innovation-duration log display with the scaled Lean
   declarations; and
8. relabel the canonical $\beta V_\beta/V$ rows as fixed-policy discount
   elasticities unless a matching duration adapter is proved.

These repairs preserve the current theorem scope and the valid proof package.
