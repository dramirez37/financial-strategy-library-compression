# Theorem Ledger

## Claim policy

This ledger is the authoritative bridge between the manuscript and Lean. A
result may be called **Lean verified** only after its exact declaration builds
without `sorry`, `admit`, user-declared axioms, or hidden placeholders and its
`#print axioms` output is recorded here.

Every record separately reports:

- informal mathematical validity;
- Lean kernel verification;
- Julia implementation validation; and
- empirical relevance.

The publication-facing status matrix and declaration-free correspondence
summary are in Appendix F.  The complete theorem-to-declaration table,
assumption reconciliation, executable axiom audit, and implementation map are
online-supplement artifacts; internal ledger identifiers do not appear in the
main-text prose.

T1--T7 have exact finite target statements, adopted assumption IDs, and a
completed exact-arithmetic falsification pass under the unified semi-Markov
timing. All seven locked statements survived the recorded finite searches.
This is computational validation within
the searched bounds, not proof. No target is established until it passes the
full claim gate below.

## Controlled overall statuses

`proposed` · `counterexample found` · `revised` · `Lean verified` ·
`numerically validated` · `empirically illustrated`

Multiple statuses may eventually apply, but no status implies another.

## Resource-layer claim boundary

The resource layer adopts fixed additive rational retention burden as a
conservative outer layer. Every active strategy has
$w_s>0$, the inactive strategy has $w_{s_0}=0$, and
$W(L)=\sum_{s\in L}w_s$. Productive dynamic value $V$ and every raw
transition remain unchanged; the new net objective is
$J_\lambda=V-\lambda W$.

The canonical resource artifacts use a separate reporting translation
$\widetilde W(L)=1+W(L)$. Their configuration field named `inactive` is the
common display addend; it is not a positive formal weight for $s_0$. Thus
$\widetilde V^\star(b;\widetilde B)=V^\star(b;\widetilde B-1)$ for
$\widetilde B\ge1$ and
$\widetilde J^\star(b;\lambda)=J^\star(b;\lambda)-\lambda$. Optimizers,
switching prices, breakpoint order, and absolute burden reductions are
unchanged. Every Lean resource statement and every claim-status entry below
continues to use $W$ and the zero-burden inactive-only library.

The additive burden, exact safe-feasibility, minimum-attainment, productive
value-preservation wrapper, and rational capacity predicates now have a
building, axiom-audited Lean foundation under OPT-FND below. The exact finite
Julia outer optimizer, breakpoint/support calculations, and counterexample
audit remain implementation validation rather than proof or empirical
support. The composite SC, PEN, and CAP records retain the exact verified/open
boundaries stated in their entries below.

All existing theorem records retain their statements and statuses. In
particular, the current frontier--closure equivalence and value-factorization
results concern productive dynamics. They do not imply equality of
$W(L)$ or $J_\lambda$ for two libraries with the same
$K_L=(F_L,C_L)$, and the current rechecked-pruning theorem does not imply a
global minimum-resource endpoint.

The manuscript and Lean definitions fix four optimization problems without
changing that status boundary:

- source-relative exact safe compression minimizes $W$ under frontier and
  general-closure equality;
- its DI form has the same feasible set only under the current T1/UDI
  sufficiency restrictions plus A-T2-OBS/`RawClosureDetectable` for the
  converse;
- capacity and penalty optimization range over all admissible sublibraries of
  the outer-certified retention-eligible catalog; and
- conditional replacement ranges over active deletions after a candidate is
  outer-certified, outside the raw admission transition.

Minimum attainment for the exact source-safe family is now Lean verified.
Generic fixed-finite-family penalty and capacity optimizers are also Lean
verified, while their typed outer-certified eligible-catalog adapters and the
replacement argmax remain open. CX-OPT-LAGRANGE-UNSUPPORTED-01 is a
realized two-active-strategy exact fixture: budget one selects the middle
point, no nonnegative price supports it, and the Lagrangian gap is $1/2$.
No strong constrained--penalized equivalence may be attributed to the current
theorem package.

The local-versus-global result fixes the interpretation of innovation-safe
deletion without changing T3. A current-library deletion
certificate preserves feasibility, and positive active weight makes the
deletion a strict resource reduction. A rechecked trace remains feasible, but
only an explicitly complete trace can support endpoint irreducibility.
Irreducibility is one-way necessary for global minimum weight, not sufficient.

The existing Lean duplicate-encoding example still establishes only
raw-distinct equal-compressed-state representatives. The exact Julia
resource audit adds:

- CX-OPT-PRUNE-CARDINALITY-01 and CX-OPT-PRUNE-WEIGHT-01 against global
  optimality of complete rechecked traces;
- CX-OPT-GREEDY-WEIGHT-01,
  CX-OPT-DELETION-ORDER-WEIGHT-01, and CX-OPT-LOCAL-NONGLOBAL-01 against
  greedy/order/local-to-global strengthenings;
- CX-OPT-CAPACITY-NONCONCAVE-01 and
  CX-OPT-CAPACITY-INCREASING-RETURNS-01 against capacity shape shortcuts;
- CX-OPT-PENALIZED-INCLUSION-SWITCH-01,
  CX-OPT-PENALIZED-BREAKPOINT-TIE-01, and CX-OPT-VALUE-KINK-01 against raw
  nesting, uniqueness, and differentiability;
- CX-OPT-ADMISSION-REQUIRES-DELETION-01 for capacity-releasing replacement;
  and
- CX-OPT-CLOSURE-CARDINALITY-ELASTICITY-01 and
  CX-OPT-ELASTICITY-ZERO-MARGIN-01 against naive elasticity statements.

FX-OPT-PENALIZED-BURDEN-MONOTONE-01 survived the bounded search and remains
the exact Julia fixture for the boundary. The general all-optimizer-pairs
burden order is now Lean verified as
`FinitePenalizedProblem.optimalBurden_antitone`; the selected-burden corollary
is `selectedBurden_antitone`. Rejected stronger claims are recorded with their
counterexamples later in this ledger.

### OPT-FND — Resource and exact-safe-compression foundations

- **Theorem ID:** OPT-FND
- **Informal statement:** Fixed rational strategy weights with a zero-weight
  inactive strategy and positive active strategies induce a nonnegative
  additive burden `W`. Burden is monotone under library inclusion, and
  deleting a represented active strategy strictly lowers it. Exact safe
  feasibility is source-relative sublibrary inclusion plus equality of the
  operational-frontier/general-closure compressed state. Its family is finite
  and nonempty and therefore attains a minimum burden. A current safe deletion
  preserves frontier and closure and maps a source-feasible library to a
  strictly lower-weight source-feasible sublibrary. Equal compressed states,
  and hence every exact-safe feasible pair, have equal unified finite-horizon
  productive value. A nonnegative rational budget admits the inactive-only
  library; capacity feasibility is monotone in budgets and inherited by
  sublibraries.
- **Exact assumptions:**
  1. the existing finite model carriers and inactive-containing raw-library
     type;
  2. exact rational weights, pointwise nonnegativity, zero inactive weight,
     and strict positivity away from the inactive identifier;
  3. the existing extensive, monotone, idempotent general module closure;
  4. exact compressed-state equality for safe feasibility and deletion;
  5. current-library membership for strict deletion; and
  6. the existing unified raw process only for the productive-value clauses.
- **Assumption reconciliation:** The empty-set convention is proved for the
  underlying finite sum, while admissible libraries use the inactive-only
  zero-burden convention. Monotonicity uses nonnegative weights; strict
  deletion uses both membership and positive active weight. Minimum
  attainment uses only finite-library enumeration and source reflexivity, not
  active-weight positivity or optimizer uniqueness. Productive value equality
  uses the existing compressed-state-to-DI and DI-to-value theorems; it does
  not assert equal burden or equal penalized value. Capacity is an outer
  initial-retention predicate and does not alter raw admission.
- **Lean declarations:**
  `StrategyInnovation.Optimization.resourceBurden_empty`;
  `libraryBurden_inactiveOnly`; `libraryBurden_nonnegative`;
  `libraryBurden_mono`; `libraryBurden_erase_lt`;
  `exactSafeCompressionFeasible_source`; `sublibrarySet_finite`;
  `exactSafeCompressionFeasibleSet_finite`;
  `exactSafeDeletion_preserves_frontier_and_closure`;
  `exactSafeDeletion_produces_feasible_lowerWeight`;
  `exists_minimumWeight_exactSafeCompression`;
  `equalCompressedStates_preserve_dynamicValue`;
  `ExactSafeCompressionFeasible.preserves_dynamicValue`;
  `inactiveOnly_capacityFeasible`; `CapacityFeasible.mono_budget`; and
  `CapacityFeasible.of_sublibrary`.
- **Lean files:**
  `formal/StrategyInnovation/Optimization/{ResourceBurden,SafeCompression,Capacity}.lean`.
- **`#print axioms` result:** Every listed theorem reports exactly
  `[propext, Classical.choice, Quot.sound]`; no user-declared axiom or hidden
  placeholder occurs. The focused audit is
  `formal/StrategyInnovation/Audit/OptimizationFoundations.lean`, and the
  declarations are also registered in the complete `AxiomAudit.lean` gate.
- **Status:** Lean verified for the exact encoded foundational statements
- **Informal mathematical validity:** Direct finite-sum order algebra,
  compressed-state projection, and minimum selection over a nonempty finite
  family.
- **Lean kernel verification:** Passed under Lean 4.32.0 and pinned mathlib
  commit `81a5d257c8e410db227a6665ed08f64fea08e997`.
- **Julia implementation validation:** The existing exact
  `Rational{BigInt}` resource optimizer independently implements burden,
  safe-family enumeration, and capacity predicates. This record adds no new
  Julia fixture or run.
- **Empirical relevance:** Not applicable.

### OPT-T2T4 — Exact safe optimization and local/global boundary

- **Theorem ID:** OPT-T2T4
- **Informal statement:** Exact frontier--closure safe feasibility is a
  source-relative sublibrary condition and is distinct from both local
  one-deletion irreducibility and global minimum burden. A minimum-weight safe
  sublibrary exists. Under `RawClosureDetectable`, frontier--closure and
  unified dynamic-equivalence feasibility coincide. Every frontier--closure
  feasible library preserves all unified finite-horizon values and, under the
  existing contraction model, stationary value and the complete set of
  optimal stationary actions. Every global minimum is one-deletion
  irreducible. Every rechecked safe-deletion trace ends at a source-feasible
  library, but a feasible one-deletion-irreducible endpoint need not be a
  global minimum. Moreover, the registered `(2,2,3)` instance shows that the
  unique-heaviest-safe-first rule can be globally suboptimal.
- **Exact assumptions:**
  1. the existing finite carriers, raw-library type, catalog, and extensive,
     monotone, idempotent general closure;
  2. exact rational catalog weights with zero inactive weight and strictly
     positive active weights;
  3. source inclusion and exact equality of the existing compressed
     frontier--closure state for `SafeCompressionFeasible`;
  4. `RawClosureDetectable` only for the dynamic-equivalence-to-compressed-
     state direction of the feasibility biconditional;
  5. the existing unified raw process for finite-horizon preservation;
  6. the existing `DiscountedContractionModel` only for stationary value and
     optimal-action preservation; and
  7. at every trace step, current membership and both redundancy certificates
     required by `RedundantDeletionSequence`.
- **Assumption reconciliation:** `OneDeletionIrreducible` is a local predicate
  on the current library and does not quantify over all safe sublibraries.
  `MinimumWeightSafeCompression` includes feasibility and compares against
  every source-feasible candidate, retaining ties. Detectability is absent
  from the forward feasible-to-dynamic/value/action results. The action result
  preserves the complete set-valued correspondence, not a selected action.
  The generic optimum theorem proves one-deletion irreducibility, not the
  stronger inclusion-wise statement. Trace rechecking proves feasibility,
  not optimality. The strict-heaviest theorem is an exact counterexample, not
  an approximation result.
- **Lean declarations:**
  `StrategyInnovation.Optimization.SafeCompressionFeasible`;
  `DynamicEquivalentSafeCompressionFeasible`; `OneDeletionIrreducible`;
  `MinimumWeightSafeCompression`; `exists_minimumWeightSafeCompression`;
  `safeCompressionFeasible_iff_dynamicEquivalentFeasible`;
  `SafeCompressionFeasible.dynamicInnovationEquivalent`;
  `SafeCompressionFeasible.preserves_finiteHorizonValue`;
  `SafeCompressionFeasible.preserves_infiniteHorizonValue`;
  `optimalFixedPointActions`;
  `isOptimalFixedPointAction_iff_of_compressedState_eq`;
  `SafeCompressionFeasible.preserves_optimalActions`;
  `MinimumWeightSafeCompression.oneDeletionIrreducible`;
  `recheckedSafeDeletionEndpoint_feasible`;
  `SafeCompressionCounterexample.recheckedEndpoint_need_not_be_globallyMinimum`;
  and
  `SafeCompressionCounterexample.strictHeaviestFirst_greedy_not_globallyOptimal`.
- **Lean files:**
  `formal/StrategyInnovation/Optimization/{SafeCompression,SafeCompressionCounterexample}.lean`.
- **`#print axioms` result:** Every listed definition and theorem reports
  exactly `[propext, Classical.choice, Quot.sound]`. The focused executable
  gate is `formal/StrategyInnovation/Audit/SafeCompressionOptimization.lean`;
  all manuscript-facing declarations are also in `AxiomAudit.lean`.
- **Status:** Lean verified for the exact encoded T2--T4 clauses and both
  local/global counterexamples
- **Informal mathematical validity:** Minimum existence is finite selection;
  equivalence and preservation reuse the audited projection interfaces;
  positive deletion weight contradicts global minimality; trace feasibility
  composes exact compressed-state equalities; and both counterexamples are
  exhaustive finite constructions.
- **Lean kernel verification:** Passed under Lean 4.32.0 and pinned mathlib
  commit `81a5d257c8e410db227a6665ed08f64fea08e997`.
- **Julia implementation validation:** The exact gauntlet command
  `search_resource_optimization_counterexamples.jl --check` passes with
  `claims=14`, `counterexamples=13`, `survivors=1`, and
  `arithmetic=Rational{BigInt}`. The Lean unit and `(2,2,3)` constructions
  match CX-OPT-PRUNE-CARDINALITY-01 and CX-OPT-GREEDY-WEIGHT-01.
- **Empirical relevance:** Not applicable.

### SC — Exact safe-compression theorem

- **Theorem ID:** SC
- **Human proof and assumption boundary:** manuscript Appendix B
- **Informal statement:** For an admissible finite source library, the exact
  frontier--closure safe family is nonempty and attains minimum additive
  rational burden. Under the current raw factorization and closure
  detectability, safe feasibility is equivalent to unified dynamic innovation
  equivalence. Every feasible library preserves all unified finite-horizon
  values and, under the existing contraction certificates, stationary value,
  every stationary action comparison, and the complete optimal stationary
  action set. A minimum-weight solution has no safely deletable
  positive-weight strategy. A complete irreducible pruning endpoint need not
  be globally minimum weight. With a common positive active weight,
  minimum-weight and minimum-cardinality optimizer correspondences coincide.
- **Exact assumptions:**
  1. finite nonempty belief, strategy, module, and project carriers;
  2. an admissible finite source library containing the inactive strategy;
  3. exact rational profiles and an extensive, monotone, idempotent finite
     module closure;
  4. $w_{s_0}=0$, strictly positive rational active weights, and additive
     $W$;
  5. the current T1/UDI raw factorization restrictions for all productive
     preservation conclusions;
  6. A-T2-OBS/`RawClosureDetectable` only for the DI-to-frontier--closure
     converse; and
  7. the current `DiscountedContractionModel` only for stationary value and
     action conclusions.
- **Assumption reconciliation:** Feasibility and finite attainment use only
  the finite source-relative domain. The forward
  frontier--closure-to-UDI/value direction does not use detectability.
  Strict deletion improvement uses only additivity and $w_s>0$. The
  equal-weight corollary means equal active weights; the mandatory inactive
  strategy remains the zero-weight exception. No exchange, matroid, greedy,
  uniqueness, or tie-breaking hypothesis is present.
- **Existing Lean dependencies:**
  `StrategyInnovation.Projection.Model.dynamicInnovationEquivalent_iff_frontierClosure_eq`;
  `StrategyInnovation.Projection.Model.rawValue_eq_of_dynamicInnovationEquivalent`;
  `StrategyInnovation.Projection.Model.DiscountedContractionModel.rawFixedPoint_eq_of_dynamicInnovationEquivalent`;
  `StrategyInnovation.Projection.Model.stationaryActionAvailable_iff_of_compressedState_eq`;
  and
  `StrategyInnovation.Projection.Model.DiscountedContractionModel.fixedPointActionValue_eq_of_compressedState_eq`.
- **Composite Lean declaration:** none. OPT-FND and OPT-T2T4 now verify parts
  1--6 through separate axiom-audited declarations, including the
  detectability biconditional, stationary value/action preservation, the
  minimum-to-one-deletion implication, rechecked endpoint feasibility, and
  exact nonglobal endpoint and strict-heaviest boundaries. Part 7's
  equal-active-weight optimizer/cardinality correspondence and a separate
  named Lean bridge to inclusion-wise irreducibility remain open.
- **Julia counterpart:** `julia/src/ResourceOptimization.jl` implements exact
  safe feasibility and complete optimizer enumeration. The unit-weight
  bundle-versus-singletons witness is
  CX-OPT-PRUNE-CARDINALITY-01 in
  `experiments/results/resource_optimization_fixtures/01_cx_opt_prune_cardinality_01.json`.
- **Status:** parts 1--6 Lean verified through OPT-FND/OPT-T2T4; part 7 and a
  single composite declaration remain proposed
- **Informal mathematical validity:** The proof is finite. Reflexivity gives
  feasibility; a nonempty finite domain gives attainment; existing T2/UDI
  gives the productive consequences; positive additive weight rules out a
  safe deletion at an optimum; the registered three-active-strategy carrier
  refutes global pruning optimality; and common active weight makes burden a
  positive scalar multiple of active cardinality.
- **Lean kernel verification:** Established for the exact separate
  declarations covering parts 1--6, but not for part 7 or one monolithic SC
  declaration.
- **Julia implementation validation:** Exact safe-domain enumeration and the
  registered pruning counterexample are validated with
  `Rational{BigInt}`. This is not proof of the universal clauses.
- **Empirical relevance:** Not assessed.

### SC-COMP — Complexity of exact safe compression

- **Theorem ID:** SC-COMP
- **Evidence status:** exact Julia reduction fixtures; no manuscript theorem or
  Lean verification claim
- **Informal statement:** Under an explicit finite binary encoding, the
  identity-closure safe-compression decision problem is NP-complete and its
  minimum-weight optimization problem is NP-hard. Frontier preservation alone
  is NP-complete. Closure preservation alone is exactly weighted set cover
  and is NP-complete. Under identity closure, the combined problem is exactly
  weighted hitting set on positive-frontier attainer obligations and
  source-module carrier obligations. The lower bounds persist under unit
  weights. A general-closure class containing identity closure is NP-hard and
  is NP-complete when its closure equality is polynomial-time verifiable.
- **Exact assumptions:**
  1. A-FIN, A-LIBRARY, A-PROFILE, A-FRONTIER, A-CLOSURE, and
     A-RESOURCE-WEIGHT for the finite exact source problem;
  2. A-SAFE-COMPLEXITY-ENCODING for explicit binary input size and the
     certificate model;
  3. identity closure for the primary equivalence and reductions; and
  4. a polynomial closure-equality evaluator only for the general-closure
     NP-membership conclusion.
- **Assumption reconciliation:** The reductions use no dynamic process,
  Bellman value, UDI, detectability, randomization, approximation oracle, or
  floating arithmetic. The closure-only reduction has one belief and zero
  profiles. The frontier-only reduction has binary profiles and inert
  modules. General closure inherits only the lower bound without an
  evaluation assumption.
- **Lean declaration:** none. A finite complexity encoding, polynomial-time
  reduction formalism, and NP-completeness library bridge remain absent.
- **Julia counterpart:** `julia/src/SafeCompressionComplexity.jl`,
  `julia/scripts/verify_safe_compression_complexity_reductions.jl`, and
  `julia/test/test_safe_compression_complexity.jl`.
- **Registered fixture:**
  `experiments/results/safe_compression_complexity_reduction_fixture.json`.
- **Status:** proposed; complete human polynomial proof and exact Julia
  reduction validation; Lean proof open
- **Informal mathematical validity:** The identity problem is in NP by direct
  exact verification. Three weight-preserving polynomial constructors map
  weighted set cover to closure-only, frontier-only, and combined safe
  compression with identical feasible masks. Unit weights transfer ordinary
  set-cover hardness. The exact combined hitting-set characterization follows
  by listing all positive-frontier attainer sets and source-module carrier
  sets.
- **Lean kernel verification:** Not established. No active manuscript result
  may call SC-COMP Lean verified.
- **Julia implementation validation:** All masks in the registered fixture
  agree across source set cover and all three safe-compression constructors.
  The focused suite also exhausts all 265 covering three-set/three-element
  incidence systems, totaling 6,360 reduction/mask correspondences. This is
  implementation validation, not universal proof.
- **Empirical relevance:** Not applicable.

### PEN — Exact penalized affine-envelope theorem

- **Theorem ID:** PEN
- **Manuscript label:** `thm:penalized-envelope`
- **Specification and human proof:** manuscript Theorem
  `thm:penalized-envelope` and Appendix B
- **Informal statement:** For a fixed nonempty finite feasible library family,
  finite productive values, and nonnegative burdens, the real-price extension
  $$
    J^\star(\lambda)
      =\max_L\{V_\theta(b,L)-\lambda W(L)\}
  $$
  is finite, continuous, nonincreasing, convex, and piecewise affine on
  $\lambda\ge0$, with finitely many breakpoints. At a unique optimizer its
  derivative is minus that library's burden. At an interior tied price, the
  left slope is minus the maximum optimal burden and the right slope is minus
  the minimum optimal burden. For any
  $\lambda_1<\lambda_2$, every higher-price optimizer has weakly lower
  burden than every lower-price optimizer. Raw optimizer libraries need not
  be inclusion-nested.
- **Exact assumptions:**
  1. A-FIN, A-RESOURCE-WEIGHT, A-RESOURCE-OUTER, and
     A-OPTIMIZATION-DOMAIN;
  2. A-PENALIZED-ENVELOPE, including a fixed price-independent feasible
     family, finite rational values, nonnegative rational burdens, and the
     canonical real-price extension;
  3. no sign restriction on productive value; and
  4. no optimizer uniqueness except where the derivative clause explicitly
     assumes it.
- **Assumption reconciliation:** The primary domain is the full
  outer-certified eligible family and contains the inactive library. The
  analytic claims concern the real extension of exact rational affine
  branches; rational prices retain the original exact objective. Convexity is
  convexity in price of a maximum of affine branches, not concavity of the
  hard-capacity value. Pairwise intersections are only candidate prices;
  actual breakpoints require globally optimal unequal-burden branches.
  Productive-value monotonicity, raw inclusion, frontier/closure order, and
  differentiability at ties are not assumed.
- **Verified finite-envelope form:** Lean works over an arbitrary library
  identifier type and an explicit nonempty `Finset`, with real productive
  values and burdens nonnegative on that family. It proves the attained
  maximum, nonempty optimizer set, antitonicity, convexity, continuity,
  finite unequal-burden switching candidates, local affine equality and slope
  under strict dominance, the all-optimizer-pairs burden order, and an
  antitone selected burden. Outside the finite candidate set, some optimal
  branch agrees with the envelope on a neighborhood and supplies its
  derivative. This is the strongest fully verified manuscript form.
- **Lean declarations:**
  `StrategyInnovation.Optimization.FinitePenalizedProblem`;
  `ofRational`; `ofRational_branch`; `branch`; `envelope`; `IsOptimizer`;
  `optimizerSet`;
  `envelope_is_finite_maximum`; `optimizerSet_nonempty`;
  `envelope_antitone`; `envelope_convex`; `continuous_envelope`;
  `switchingPrice`; `pairwiseSwitchingPrices`;
  `pairwiseSwitchingPriceSet_finite`; `branch_eq_at_switchingPrice`;
  `optimizer_tie_eq_switchingPrice`;
  `optimizer_tie_mem_pairwiseSwitchingPrices`;
  `optimizer_burdens_eq_of_not_mem_pairwiseSwitchingPrices`;
  `exists_eventuallyEq_branch_of_not_mem_pairwiseSwitchingPrices`;
  `IsLocallyAffineAt`; `breakpointSet`;
  `isLocallyAffineAt_of_not_mem_pairwiseSwitchingPrices`;
  `breakpointSet_subset_pairwiseSwitchingPrices`; `breakpointSet_finite`;
  `exists_hasDerivAt_envelope_of_not_mem_breakpointSet`;
  `exists_hasDerivAt_envelope_of_not_mem_pairwiseSwitchingPrices`;
  `StrictlyDominatesOn`;
  `envelope_eq_branch_of_strictlyDominatesOn`;
  `hasDerivAt_envelope_of_strictlyDominatesOn`;
  `optimalBurden_antitone`; `selectedOptimizer`;
  `selectedOptimizer_isOptimizer`; and `selectedBurden_antitone`.
- **Lean file:**
  `formal/StrategyInnovation/Optimization/PenalizedEnvelope.lean`.
- **`#print axioms` result:** Every listed declaration reports exactly
  `[propext, Classical.choice, Quot.sound]`. The focused executable gate is
  `formal/StrategyInnovation/Audit/PenalizedEnvelope.lean`; all declarations
  are also registered in `AxiomAudit.lean`.
- **Remaining PEN clauses:** The global ordered partition into affine cells,
  exact active-breakpoint classification and cardinality bound, active-face
  one-sided derivatives/subdifferential, and the raw nonnesting counterexample
  are not formalized in this slice. No verified statement calls every
  pairwise intersection an active kink.
- **Julia counterpart:** `julia/src/ResourceOptimization.jl` implements exact
  penalized values, optimizer correspondences, supporting intervals, and the
  finite candidate switching-price set.
- **Exact fixtures:**
  FX-OPT-PENALIZED-BURDEN-MONOTONE-01,
  CX-OPT-PENALIZED-INCLUSION-SWITCH-01,
  CX-OPT-PENALIZED-BREAKPOINT-TIE-01, and CX-OPT-VALUE-KINK-01 under
  `experiments/results/resource_optimization_fixtures/`.
- **Status:** Lean verified for the finite-envelope form requested here;
  complete human PEN additionally contains open active-face/topology and raw
  boundary clauses
- **Informal mathematical validity:** Finiteness and continuity follow from a
  finite maximum. Nonincrease uses nonnegative slopes; convexity uses the
  maximum-of-affine inequality. Pairwise intersections partition the price
  axis into finitely many affine cells. Directional derivatives select the
  extreme burdens of the active face. Adding the two cross-price optimality
  inequalities proves the all-optimizer-pairs burden order. The registered
  two-strategy instance proves that this scalar order does not imply raw
  inclusion.
- **Lean kernel verification:** Established for the listed finite-envelope
  declarations under Lean 4.32.0 and pinned mathlib commit
  `81a5d257c8e410db227a6665ed08f64fea08e997`; not established for the
  remaining PEN clauses.
- **Julia implementation validation:** Exact rational enumeration reproduces
  ties, switching prices, supporting intervals, the kink slopes, strict
  burden reduction across one switch, and the nonnested unique-optimizer
  counterexample. The current `penalty_breakpoints` routine enumerates the
  finite pairwise candidate superset; it does not certify that every returned
  intersection is an active envelope kink.
- **Empirical relevance:** Not assessed.

### CAP — Exact capacity-constrained value theorem

- **Theorem ID:** CAP
- **Manuscript label:** `thm:capacity-value`
- **Specification and human proof:** manuscript Theorem `thm:capacity-value`
  and Appendix B
- **Informal statement:** For the fixed finite outer-certified library family
  with a zero-burden inactive library, the capacity-constrained productive
  value
  $$
    V^\star(B)
    =
    \max\{V_\theta(b,L):W(L)\le B\}
  $$
  is finite and attained for every $B\ge0$, nondecreasing, and a
  right-continuous finite step function. Every strict value breakpoint is an
  attainable library burden. Discrete shadow value is the nonnegative exact
  finite difference $V^\star(B+\delta)-V^\star(B)$. Optimal libraries can
  switch discontinuously, and capacity marginals need not diminish.
- **Exact assumptions:**
  1. A-FIN, A-RESOURCE-WEIGHT, A-RESOURCE-OUTER, and
     A-OPTIMIZATION-DOMAIN;
  2. A-CAPACITY-VALUE, including a fixed capacity-independent finite family,
     finite rational values and burdens, a zero-burden library, and the
     canonical real-capacity extension;
  3. $B\in\mathbb R_{\ge0}$ for the analytic step statement, with the
     original exact problem recovered at rational $B$; and
  4. no sign, additivity, submodularity, or optimizer-uniqueness assumption on
     productive values.
- **Assumption reconciliation:** The primary family is
  $\mathfrak L(S_\theta^{\mathrm{elig}})$, not a safe-compression family.
  The inactive-only library guarantees feasibility at every nonnegative
  capacity. Breakpoints mean strict jumps in value, not every threshold where
  a tied optimizer joins. Ordinary real-variable concavity is separated from
  lattice diminishing returns and from randomized or fractional
  convexification.
- **Lean declarations:** `FiniteCapacityProblem`,
  `FiniteCapacityProblem.capacityValue`,
  `FiniteCapacityProblem.IsCapacityOptimizer`,
  `FiniteCapacityProblem.exists_capacityOptimizer_of_inactive_feasible`,
  `FiniteCapacityProblem.capacityValue_is_finite_maximum`,
  `FiniteCapacityProblem.capacityOptimizerSet_nonempty`,
  `FiniteCapacityProblem.capacityValue_mono`,
  `FiniteCapacityProblem.attainableBurdens`,
  `FiniteCapacityProblem.capacityValue_constant_between_attainableBurdens`,
  `FiniteCapacityProblem.capacityBreakpointSet_subset_attainableBurdens`,
  `FiniteCapacityProblem.capacityBreakpointSet_finite`,
  `FiniteCapacityProblem.discreteShadowValue`, and
  `FiniteCapacityProblem.discreteShadowValue_nonnegative` in
  `Optimization/CapacityValue.lean`.
- **Exact failure declaration:**
  `CapacityComplementarityCounterexample.productiveValue_eq_jointRequirement`
  identifies the value table with a jointly required two-capability
  opportunity; `capacityValue_zero`, `capacityValue_one`, and
  `capacityValue_two` prove the exact profile `(0,0,1)`; and
  `increasing_marginal_capacity_value` plus
  `diminishing_capacity_returns_fail` prove the strict failure of general
  discrete diminishing returns.
- **Separate sufficient-condition declarations:**
  `AdditiveUnitCapacityProfile.gridShadow_eq_nextIncrement`,
  `gridShadow_antitone`, and `gridShadow_succ_le` prove weakly decreasing
  grid shadows for the sorted-prefix formula induced by additive independent
  nonnegative values and equal positive units. These declarations do not
  assert ordinary real-variable concavity or a property of arbitrary
  `FiniteCapacityProblem`s.
- **Julia counterpart:** `julia/src/ResourceOptimization.jl` implements exact
  rational capacity values, complete optimizer correspondences, and discrete
  capacity profiles.
- **Exact fixtures:**
  CX-OPT-CAPACITY-NONCONCAVE-01 and
  CX-OPT-CAPACITY-INCREASING-RETURNS-01 under
  `experiments/results/resource_optimization_fixtures/`.
  CX-OPT-SUBMODULAR-CAPACITY-01 is a direct exact four-policy coverage
  calculation in the specification and counterexample registry.
- **Status:** requested finite CAP core, exact complementarity boundary, and
  sorted additive-unit grid sufficient condition Lean verified; the stronger
  globally sorted right-continuous partition packaging, optimizer-switch
  selection theorem, submodular coverage counterexample, jump-sum identity,
  and typed eligible-catalog adapter remain human/Julia-only
- **Informal mathematical validity:** The zero-burden inactive library makes
  every capacity-feasible family nonempty, and finiteness gives attainment.
  Feasible-set nesting gives monotonicity. Sorting the finite attainable
  burdens shows that the feasible family, and hence the optimum, is constant
  on the half-closed intervals between them. The lumpy-weight and jointly
  required-module examples give exact increasing marginal values. Additive
  equal-unit value sorts independent gains downward, while the coverage
  example proves that monotone submodularity alone does not.
- **Lean kernel verification:** Established for the declarations listed
  above. `Audit/CapacityValue.lean` prints axioms for every manuscript-facing
  declaration and is linter-clean; every report is exactly
  `[propext, Classical.choice, Quot.sound]`. The direct verified breakpoint
  form defines positive value breakpoints as failures of local constancy,
  proves local constancy away from attainable burdens, and therefore proves
  containment in the finite attainable-burden set.
- **Julia implementation validation:** Exact rational enumeration reproduces
  the one-strategy optimizer jump and the two-unit complementarity profile
  $(0,0,1)$. The general step and breakpoint statements are human proofs;
  no Julia actual-capacity-breakpoint classifier is registered.
- **Empirical relevance:** Not assessed.

### REP — Supporting capacity-constrained replacement proposition

- **Theorem ID:** REP
- **Manuscript role:** supporting result only; no main contribution label
- **Specification and human proof:** online supplement S3
- **Informal statement:** For an outer-certified candidate $c\notin L$,
  additive burden turns replacement feasibility into the exact release
  requirement
  $$
    W(D)\ge[W(L)+w_c-B]_+.
  $$
  Conditional replacement minimizes candidate-relative displacement loss
  among deletion sets meeting this requirement, and net admission value
  decomposes as
  $$
    A_c(b,L,B)
    =
    G_c(b,L)-\ell_c^\star(b,L,B).
  $$
  A capacity-sufficient safe deletion attains the unconstrained augmented
  value. Admission is strictly preferred to retaining a feasible $L$
  exactly when incremental candidate value exceeds least required
  displacement loss.
- **Exact assumptions:**
  1. A-FIN, A-RESOURCE-WEIGHT, A-RESOURCE-OUTER, and
     A-OPTIMIZATION-DOMAIN;
  2. A-REPLACEMENT-OPTIMIZATION, including outer eligibility, unrestricted
     active-incumbent deletion, inclusion-monotone productive value, and
     $w_c\le B$;
  3. frontier--closure factorization for the implication from structural
     candidate-relative safety to zero loss; and
  4. $W(L)\le B$ plus “retain $L$” as the outside option only for the
     accept/reject criterion.
- **Assumption reconciliation:** Pre-admission safety
  $K_{L\setminus D}=K_L$, candidate-relative safety
  $K_{(L\setminus D)\cup\{c\}}=K_{L\cup\{c\}}$, and equality of the single
  fixed value objective are distinct. Pre-admission safety implies
  candidate-relative safety, which implies zero loss. The converses and
  strict loss from structural inequality are not assumed.
- **Lean declaration:** none. The resource carrier, deletion-set domain,
  burden identity, safe-insertion congruence, loss decomposition, and
  accept/reject comparison have not been formalized or axiom-audited.
- **Julia counterpart:** the exact resource audit enumerates the registered
  capacity-releasing replacement instance. `optimal_admission_deletion_set`
  in `julia/src/ResourceOptimization.jl` now exhausts every incumbent
  deletion set, retains all capacity-feasible value-maximizing ties, and
  reports the exact release, channel-value, opportunity-cost, and enumeration
  certificates.
- **Exact fixtures and examples:**
  CX-OPT-ADMISSION-REQUIRES-DELETION-01 and
  CX-OPT-NO-PRESAFE-STILL-ZERO-LOSS-01 use
  `10_cx_opt_admission_requires_deletion_01.json`.
  The operational-versus-generative loss table and
  CX-OPT-POSITIVE-CANDIDATE-REJECT-01 are direct exact calculations in the
  specification.
- **Status:** proposed supporting proposition; complete human proof with
  exact finite boundary evidence; Lean proof open
- **Informal mathematical validity:** Additive burden proves the release
  identity. Inclusion monotonicity makes every displacement loss
  nonnegative. Adding and subtracting the unconstrained augmented value gives
  the opportunity-cost decomposition. Common insertion preserves a
  pre-admission frontier--closure equality, so sufficient safe release is
  optimal. Finite minimization gives strict positive loss exactly when no
  feasible zero-loss deletion exists.
- **Lean kernel verification:** Not established for REP.
- **Julia implementation validation:** The registered exact fixture confirms
  that insertion without deletion violates capacity and that deleting the
  incumbent restores feasibility. Its duplicate module also validates the
  pre-safe versus candidate-safe distinction. A pinned one-off exact Julia
  check reproduces the two additional value tables, but they are not
  registered generated fixtures or reusable implementation tests.
- **Empirical relevance:** Not assessed.

### BEM — Supporting canonical bridge-margin elasticity proposition

- **Theorem ID:** BEM
- **Manuscript role:** Appendix C unnumbered bridge result at
  `eq:bridge-elasticities`, summarized only as bridge-margin sensitivity in
  Section 5; not a complete operational--generative elasticity theorem
- **Specification and human proof:** BRIDGE_ELASTICITY_SPEC.md
- **Informal statement:** For fixed $d\ge1$, let
  $A_{\mathrm{br}}=\beta^d\rho^d\pi C$ and
  $M_{\mathrm{br}}=A_{\mathrm{br}}-\kappa>0$. Named-coordinate
  differentiation gives
  $$
    \varepsilon_\beta^M=\varepsilon_\rho^M
      =\frac{dA_{\mathrm{br}}}{M_{\mathrm{br}}},
    \qquad
    \varepsilon_\pi^M=\varepsilon_C^M
      =\frac{A_{\mathrm{br}}}{M_{\mathrm{br}}},
    \qquad
    \varepsilon_\kappa^M
      =-\frac{\kappa}{M_{\mathrm{br}}}.
  $$
  With $m_{\mathrm{br}}=M_{\mathrm{br}}/A_{\mathrm{br}}$, the
  dimensionless amplification factor is
  $\mathcal F_{\mathrm{br}}=1/m_{\mathrm{br}}$. Elasticity magnitudes
  diverge as $m_{\mathrm{br}}\downarrow0$; $M_{\mathrm{br}}\downarrow0$
  alone is insufficient without a positive gross-scale floor.
- **Exact assumptions:** A-T4-FIXTURE, A-T4-CANONICAL, and
  A-BRIDGE-MARGIN-ELASTICITY. The elasticity domain strengthens the T4 weak
  inequalities to positive gross coordinates and a strictly positive net
  margin.
- **Assumption reconciliation:** The existing T4 declaration proves the exact
  rational scalar pruning-loss identity on its worthwhile-action domain. BEM
  separately embeds that scalar identity in a real-coordinate extension,
  fixes duration during differentiation, and holds every unnamed primitive
  constant. Realized loss is $[M_{\mathrm{br}}]_+$, so the signed margin
  equals pruning loss only on $M_{\mathrm{br}}>0$.
- **Lean declarations:**
  `StrategyInnovation.Compression.grossBridge`; `bridgeMargin`; `bridgeLoss`;
  `hasDerivAt_max_zero_of_pos`; the five
  `hasDerivAt_bridgeMargin_*` declarations; the five
  `hasDerivAt_bridgeLoss_*` declarations; `normalizedBridgeMargin`;
  `bridgeFragility`; the five `bridgeLoss_*_elasticity` declarations;
  `bridgeFragility_eq_inv_normalizedMargin`;
  `normalizedMargin_fragility_tendsto_atTop`;
  `positiveMargin_thresholdElasticity_tendsto_atBot`;
  `fixedGross_fragility_tendsto_atTop`;
  `costless_vanishingGross_fragility_eq_one`; and the exact declarations in
  `Compression.BridgeExample`.
- **Lean file:**
  `formal/StrategyInnovation/Compression/BridgeMarginElasticity.lean`.
- **`#print axioms` result:** Every listed declaration reports exactly
  `[propext, Classical.choice, Quot.sound]` in
  `formal/StrategyInnovation/Audit/Elasticity.lean`; the principal BEM
  declarations are additionally registered in the complete
  `AxiomAudit.lean` gate.
- **Julia counterpart:** none. The specification records exact rational
  coordinatewise finite-change formulas but introduces no reusable routine or
  generated fixture.
- **Status:** Lean verified for the named real-coordinate derivative,
  elasticity, normalized-margin blow-up, boundary, and exact-example form;
  Julia implementation open
- **Informal mathematical validity:** Power- and product-rule differentiation of the
  monomial gives gross elasticities $(d,d,1,1)$. Subtracting fixed cost
  leaves the level derivatives unchanged and divides percentage effects by
  $m_{\mathrm{br}}$. The cost elasticity is
  $-(1-m_{\mathrm{br}})/m_{\mathrm{br}}$. Direct limits prove divergence
  exactly when the normalized positive margin tends to zero. The costless
  path $A_{\mathrm{br}}=M_{\mathrm{br}}\downarrow0$ supplies the
  counterexample to unqualified level-margin divergence.
- **Exact boundary record:** CX-BEM-VANISHING-GROSS-SCALE-01 is the direct
  rational costless family; CX-OPT-ELASTICITY-ZERO-MARGIN-01 is the
  complementary divergent positive-gross-scale family.
- **Lean kernel verification:** Established for the listed BEM declarations
  under Lean 4.32.0 and pinned mathlib commit
  `81a5d257c8e410db227a6665ed08f64fea08e997`. The application to realized
  positive-part loss explicitly assumes a strictly positive margin.
- **Julia implementation validation:** Not established for BEM.
- **Empirical relevance:** Not assessed.

### CED — Operational--generative channel-elasticity decomposition

- **Theorem ID:** CED
- **Manuscript location:** Appendix C at `prop:channel-elasticity`
- **Specification and human proof:** manuscript Appendix C,
  `prop:channel-elasticity`
- **Informal statement:** Along one named positive scalar path on which the
  T5 channel values are differentiable,
  $$
    xI'(x)
    =
    x(\Delta^{\mathrm{op}})'(x)
    +
    x(\Delta^{\mathrm{gen}})'(x).
  $$
  If $I>0$, define
  $$
    C_x^{\mathrm{op}}
      =\frac{x}{I}(\Delta^{\mathrm{op}})',
    \qquad
    C_x^{\mathrm{gen}}
      =\frac{x}{I}(\Delta^{\mathrm{gen}})'.
  $$
  Then
  $$
    \varepsilon_x^I
    =
    C_x^{\mathrm{op}}+C_x^{\mathrm{gen}}.
  $$
  If both channel levels are positive, this is the convex weighted average
  $$
    \varepsilon_x^I
    =
    \frac{\Delta^{\mathrm{op}}}{I}
      \varepsilon_x^{\mathrm{op}}
    +
    \frac{\Delta^{\mathrm{gen}}}{I}
      \varepsilon_x^{\mathrm{gen}}.
  $$
- **Exact assumptions:** A-CHANNEL-ELASTICITY and the existing T5
  operational--generative accounting definitions. BEM and IDCV are separate
  specializations with their own additional assumptions.
- **Assumption reconciliation:** The T5 level identity must hold along the
  complete neighborhood path, and every derivative uses the same perturbation
  and held-fixed convention. Total positivity is enough for contribution
  normalization. Strict channel positivity is additionally required for
  ordinary component log elasticities and convex weighted-average language.
  Optimizer kinks use one-sided identities or exact finite changes.
- **Parameter interpretations:** discount can load both channels;
  innovation-only survival, admission, and project-cost coordinates leave the
  passive operational channel fixed; a common operating-profile scale gives
  unit operational elasticity when that level is positive; and a named
  differentiable belief-kernel family allocates persistence effects without
  imposing a universal sign.
- **Lean declarations:**
  `StrategyInnovation.Value.ChannelAccountingAt`;
  `operational_generative_derivative_decomposition`;
  `channel_level_decomposition`;
  `operational_generative_scaledDerivative_decomposition`;
  `operational_generative_contribution_decomposition`;
  `positive_channel_shares`;
  `operational_generative_weightedAverage_elasticity`;
  `operational_generative_contribution_decomposition_of_hasDerivAt`; and the
  derivative/value/contribution declarations in
  `Value.ChannelElasticityExamples`.
- **Lean file:** `formal/StrategyInnovation/Value/ChannelElasticity.lean`.
- **Verified interpretation boundary:** The derivative theorem assumes the
  accounting identity as an eventual equality on a real neighborhood and
  verified derivatives on that same path. Signed scaled and total-normalized
  contribution identities use no positivity. Ordinary total percentage
  interpretation requires nonzero total level, and the share-weighted formula
  is proved only for positive operational and generative levels. No theorem
  silently identifies an arbitrary path with the rational T5 model.
- **`#print axioms` result:** Every listed declaration reports exactly
  `[propext, Classical.choice, Quot.sound]` in the focused elasticity audit;
  the principal CED declarations are additionally registered in the complete
  axiom gate.
- **Julia counterpart:** none. The specification contains direct exact
  rational examples but no reusable routine or generated fixture.
- **Exact examples:** At $x=1$, the paths
  $(O,G)=(100+x,1+10x)$ give operational level dominance and generative
  sensitivity dominance; $(O,G)=(10+4x,10-3x)$ give contributions
  $4/21$ and $-3/21$, hence total elasticity $1/21$; and
  $(O,G)=(0,x)$ give zero operational level with unit generative
  contribution.
- **Status:** Lean verified for the real-path derivative, signed contribution,
  positive weighted-average, and three exact-example form; model-specific
  path adapters and Julia implementation open
- **Informal mathematical validity:** Differentiate the pointwise T5
  accounting identity and multiply by the common positive parameter. Division
  by positive total value gives the contribution identity. Multiplication and
  division by each positive component gives the share-weighted formula, whose
  shares are positive and sum to one.
- **Lean kernel verification:** Established for the listed CED declarations
  under Lean 4.32.0 and pinned mathlib commit
  `81a5d257c8e410db227a6665ed08f64fea08e997`.
- **Julia implementation validation:** Not established for CED.
- **Empirical relevance:** Not assessed.

### IDCV — Innovation duration and log-effective-discount convexity

- **Theorem ID:** IDCV
- **Manuscript location:** Appendix C, unnumbered result at
  `eq:innovation-duration`
- **Specification and human proof:** manuscript Appendix C,
  `eq:innovation-duration`
- **Informal statement:** For $H\ge1$, $\alpha>0$, and a fixed
  nonnegative nonzero exposure sequence, define
  $$
    \Psi_H(\alpha;z)=\sum_{t<H}\alpha^tz_t,
    \qquad
    \omega_t^\Psi=\frac{\alpha^tz_t}{\Psi_H},
    \qquad
    D_\Psi=\sum_tt\omega_t^\Psi.
  $$
  Then
  $$
    \frac{\partial\log\Psi_H}{\partial\log\alpha}
    =
    \varepsilon_\beta^\Psi
    =
    \varepsilon_\rho^\Psi
    =
    D_\Psi
  $$
  for $\alpha=\beta\rho$ with the other primitive fixed. Defining
  $$
    C_\Psi=\sum_t\omega_t^\Psi(t-D_\Psi)^2
  $$
  gives
  $$
    \frac{\partial D_\Psi}{\partial\log\alpha}
    =
    \frac{\partial^2\log\Psi_H}{\partial(\log\alpha)^2}
    =
    C_\Psi\ge0,
    \qquad
    0\le D_\Psi\le H-1.
  $$
- **Exact assumptions:** A-INNOVATION-DURATION. The componentwise S6
  specialization additionally uses A-S6-DISCOUNT-SURVIVAL to derive
  $z_t=(P^tg)(b)\ge0$.
- **Assumption reconciliation:** The sequence $z$ is fixed under every
  derivative. Strict positivity of $\alpha,\beta,\rho,\Psi_H$ makes each
  logarithm and normalization defined. The theorem concerns a scalar
  component or abstract scalar exposure polynomial. It does not differentiate
  the S6 vector in Lean and does not identify $D_\Psi$ with project or
  policy duration.
- **Equality cases:** $D_\Psi=0$ exactly for positive support at date zero;
  $D_\Psi=H-1$ exactly for positive support at date $H-1$; and
  $C_\Psi=0$ exactly for singleton positive support. With at least two
  distinct positive-support dates, $C_\Psi>0$ and $D_\Psi$ is strictly
  increasing in $\log\alpha$.
- **Lean declarations:** `StrategyInnovation.Coverage.innovationPotential`;
  `innovationFirstMoment`; `innovationSecondMoment`;
  `innovationPotentialDerivative`; `innovationFirstMomentDerivative`;
  `innovationDuration`; `innovationWeight`; `innovationConvexity`;
  `innovationTimingVariance`; `hasDerivAt_innovationPotential`;
  `hasDerivAt_innovationFirstMoment`;
  `scaled_potentialDerivative_eq_firstMoment`;
  `scaled_firstMomentDerivative_eq_secondMoment`;
  `innovationDuration_identity`; `sum_innovationWeight_eq_one`;
  `sum_time_mul_innovationWeight_eq_duration`;
  `finite_weighted_variance_identity`;
  `sum_time_sq_mul_innovationWeight`;
  `innovationConvexity_eq_timingVariance`;
  `hasDerivAt_innovationDuration`;
  `scaled_durationDerivative_eq_timingVariance`;
  `innovationWeight_nonnegative`; `innovationConvexity_nonnegative`; and the
  early, middle, late, and spread declarations in
  `Coverage.InnovationDurationExamples`.
- **Lean file:** `formal/StrategyInnovation/Coverage/InnovationDuration.lean`.
- **Verified interpretation boundary:** Lean verifies the polynomial and
  quotient derivatives and the scaled identities
  `α Ψ' = N₁`, `α N₁' = N₂`, and `α D' = C`. Thus the usual
  log-parameter reading is available as a carefully stated chain-rule
  corollary, but no separate derivative of `log Ψ (exp θ)` is declared. The
  broader duration bounds, support equality cases, and strictness clauses are
  not part of the verified slice.
- **`#print axioms` result:** Every listed declaration reports exactly
  `[propext, Classical.choice, Quot.sound]` in the focused elasticity audit;
  the principal IDCV declarations are additionally registered in the
  complete axiom gate.
- **Julia counterpart:** none. The specification gives exact rational
  evaluation formulas and direct finite examples, but no reusable routine or
  generated fixture.
- **Exact examples:** At $H=3$, $\alpha=1/2$, exposure sequences
  $(2,0,0)$ and $(0,0,8)$ both have potential level two and durations
  zero and two. Sequences $(0,4,0)$ and $(1,0,4)$ both have potential
  level two and duration one, but convexities zero and one.
- **Status:** Lean verified for the finite derivative, duration, weighted-
  variance, nonnegativity, and four exact-example core; broader support
  equality cases/bounds and Julia implementation open
- **Informal mathematical validity:** Differentiating the finite exponential
  sum in $\theta=\log\alpha$ makes its first log derivative the weighted
  mean date. Differentiating normalized weights gives
  $\partial\omega_t/\partial\theta=(t-D_\Psi)\omega_t$, so the derivative
  of the mean is the variance. Convex-combination bounds and the exact
  pairwise variance identity give the equality cases.
- **Lean kernel verification:** Established for the listed IDCV declarations
  under Lean 4.32.0 and pinned mathlib commit
  `81a5d257c8e410db227a6665ed08f64fea08e997`; not established for the explicitly
  excluded bounds, equality cases, or separate log-composition calculus.
- **Julia implementation validation:** Not established for IDCV.
- **Empirical relevance:** Not assessed.

**Public-preprint switching scope.** A general set-valued switching theory is
beyond the current result package and is left for future work.  It is not a
theorem-ledger entry or a release formalization target.  The preprint retains
only PEN's verified finite envelope and pairwise candidate-price results,
globally active exact benchmark breakpoints, optimizer margins, Bellman
action-gap diagnostics, and one-sided or finite-change interpretations at
actual switches.

### CPEL — Discrete capacity and resource-demand elasticity

- **Theorem ID:** CPEL
- **Manuscript role:** supporting finite-change result for optimization
  T6--T7
- **Specification and human proof:** manuscript Appendix C and this ledger
- **Informal statement:** For a declared positive increment, positive base
  capacity, and positive capacity value, the forward capacity arc elasticity
  is
  $$
    \varepsilon_{B,\delta}^{V^\star}
    =
    \frac{V^\star(B+\delta)-V^\star(B)}{V^\star(B)}
    \frac B\delta.
  $$
  It is nonnegative, equals zero on a window contained in one value step, and
  is the base-normalized sum of strict capacity jumps crossed by the window.
  A shrinking arc landing on an interior jump with positive left value has an
  unbounded spike. For positive price and base demand and singleton endpoint
  optimal-burden sets,
  $$
    \varepsilon_{\lambda,\delta}^{W^\star}
    =
    \frac{W^\star(\lambda+\delta)-W^\star(\lambda)}
         {W^\star(\lambda)}
    \frac\lambda\delta
    \le0.
  $$
  At an unequal-burden price tie, scalar optimal demand and its elasticity are
  undefined without a selection rule.
- **Exact assumptions:** A-CAPACITY-VALUE, A-PENALIZED-ENVELOPE, and
  A-DISCRETE-RESOURCE-ELASTICITY. The feasible library family, productive
  values, and burdens are fixed. All arcs use a declared positive increment;
  percentage reports require positive bases, and price-demand arcs require
  singleton endpoint burden correspondences.
- **Assumption reconciliation:** The requested arc convention is forward and
  base-normalized rather than a derivative through a switching point.
  Capacity breakpoints mean strict right-continuous value jumps. Price
  breakpoints require globally active unequal-burden branches. Optimizer-only
  capacity thresholds and equal-burden price ties need not move either
  elasticity.
- **Shadow and spike identity:** CAP's jump decomposition gives
  $$
    \varepsilon_{B,\delta}^{V^\star}
    =
    \frac{B}{\delta V^\star(B)}
    \sum_{\omega\in\mathcal B_C\cap(B,B+\delta]}d(\omega).
  $$
  If $B=\omega-\delta$ and the interval reaches one isolated breakpoint,
  the elasticity is
  $[d(\omega)/V^\star(\omega^-)][(\omega-\delta)/\delta]$.
- **Tie boundary:** Define
  $\mathcal W^\star(\lambda)=\{W(L):L\in\operatorname{Opt}_\lambda\}$.
  A raw optimizer tie does not prevent scalar demand if this image is a
  singleton. An unequal-burden tie makes it non-singleton; report the maximum
  and minimum active burdens or a unique-endpoint cross-breakpoint arc.
- **Lean declaration:** none. No exact finite-arc normalization, guarded
  division, jump-sum elasticity, optimal-burden image, or tie-aware demand
  elasticity has been formalized or axiom-audited.
- **Julia counterpart:** none. CAP and PEN have existing exact Julia routines
  and fixtures, but no reusable CPEL reporting API is implemented.
- **Exact examples:** The positive-baseline two-module profile
  $V^\star=(1,1,2)$ on unit capacities has shadows zero then one,
  $\varepsilon_{1,1}^{V^\star}=1$, and
  $\varepsilon_{3/2,1/2}^{V^\star}=3$. The registered penalized-switch
  branches with burden change two to one give zero elasticity inside the
  low-price cell, cross-breakpoint elasticity $-3/4$, and incompatible
  selected values $-1$ and zero at the tied base, proving the scalar point
  statistic undefined there.
- **Status:** proposed supporting result; complete human deduction with direct
  exact rational examples and reused registered boundary evidence; Lean proof
  and reusable Julia implementation open
- **Informal mathematical validity:** The CAP jump-sum identity immediately
  yields nonnegativity, zero regions, and the spike formula. PEN orders every
  higher-price optimal burden below every lower-price optimal burden, yielding
  nonpositive demand arcs whenever endpoint images are singletons. A
  non-singleton burden image makes the scalar denominator selection-dependent.
- **Lean kernel verification:** Not established for CPEL. The requested finite
  CAP and PEN cores are separately Lean verified, but CPEL additionally uses
  the unformalized CAP jump-sum identity, guarded normalizations, and
  tie-aware demand correspondence.
- **Julia implementation validation:** A dependency-free exact rational spot
  check reproduces the capacity and price-demand calculations. No reusable
  implementation or generated fixture is claimed.
- **Empirical relevance:** Not assessed.

## Updated complete formal audit

The current claim-gate audit is executed by
`formal/StrategyInnovation/Audit/AxiomAudit.lean`. It elaborates and
executes 752 distinct `#print axioms` commands covering every one of the 276
distinct Lean declarations or definitions in the active manuscript
correspondence, the principal theorem dependencies, and the retained audited
compatibility surface, including the twelve publication-facing certificates
for the unified canonical benchmark. Non-publication declarations remain
implementation-only. The
2026-07-22 T1 extension derives its transition and value projection from the
raw generation, admission, and update layer; T2 derives its frontier--closure
criterion from that projection and explicit raw detectability; T3 derives
deletion safety from T1 and its observable converse from T2; T4 derives its
survival/admission mass from the raw probability layer; T5 defines full value
through T1 and derives its bridge law from raw generation and admission; T6
derives its retained-carrier event directly from the unified joint completion
law, keeps the operating adjustment, and uses conditional independence only
for the product specialization. None
changes an old primitive abstract-transition theorem.
CS1 proves the finite sign-definite comparative statics under explicit
primitive orders and records the exact continued-operation delay boundary.
S6 proves exact finite discount--survival complementarity through a
factorized rational matrix-power cross difference and attributes no derivative
claim to Lean. S7 proves that scalar persistence has no universal sign and
derives the valid direction from discounted occupation aligned with the
positive-gap region. T7 proves the frontier--closure cross-difference sign on
the T1 compressed Bellman process under relative action saturation. Its
common-gap primitive corollary derives that condition from zero poor exposure,
nonnegative rich exposure, and an antitone fixed-descendant gap. The canonical
specialization derives that gap order by finite-horizon induction under the
process's common belief kernel, nonnegative discount, and pointwise ordered
current and terminal gaps. Its exact
menu-switching and Continue-pair counterexamples establish that primitive
frontier independence and a broader added-exposure order are insufficient. S5
now names its actual one-shot object:
`oneShotCostCoveringSet`. The
monotone-gap upper-threshold theorem and its cost, survival, admission, and
frontier cutoff comparisons make no Bellman-optimal research-region claim.
S2 derives the unified raw and compressed Bellman contractions from T1,
proves unique fixed points and geometric iteration, and formalizes stationary
selector existence and policy evaluation.
The exact raw-derived canonical fixture separately checks normalized raw and
compressed laws, update compression, positive duration, $P^d$ path
marginals, operating blocks, raw/compressed finite values, the six-state
stationary fixed point, selector attainment, lifted raw policy evaluation,
zero exact residual, and unique displayed actions.
No `sorry`, `admit`, user `axiom`, `unsafe`, placeholder, disabled declaration,
commented-out theorem, or active correspondence collision was found. The
manuscript reconciliation now makes UDI the unqualified relation and gives the
retained F1--F4 relation the explicit `prim` qualifier. The clean Lean build
completed successfully, including unified S2 and the root library. The focused
unified Bellman audit prints all 34 principal declarations, the release linter
and 36-command canonical-fixture audit pass, and the comprehensive audit
executes all 570 `#print axioms` commands.
The audit downgraded F7's manuscript presentation to a supporting
primitive-adapter proposition because no named Lean theorem bridges its
passive recursion to unified T5; FG-0028 records that optional bridge. No main
claim depends on it.

## Adversarial feasibility verdict

| Claim | Classification after exact search | Boundary that must remain explicit |
|---|---|---|
| F2 | Lean verified with typed counterexamples | factorization for forward; closure identifiability for converse |
| F3 | Lean verified with typed counterexample | value preservation is a consequence, not an identifiable converse |
| F4 | Lean verified scaled-loss construction | unboundedness scales reward; capped loss is exactly bounded |
| F5 | Lean verified finite-state value calculus | primitive compressed kernel and action-specific timing; not T1 |
| F6 | Lean verified insertion-value decomposition | positivity only under explicit stochastic monotonicity; not T5 |
| F7 | Lean verified supporting primitive-adapter passive gap-sum identity | no named bridge to unified T5; not T5 or T6 |
| F8 | Lean verified primitive finite-state Bellman contraction | compatibility result over F5 timing; unified S2 is publication-facing |
| S2 | Lean verified unified Bellman contraction and stationary selector | finite exact raw model, positive duration, $0\le\beta<1$; finite-horizon feasibility remains distinct from stationary iteration |
| S4 | Lean verified finite coverage-potential representation | gross fixed-candidate occupation value only; not T6 |
| S6 | Lean-verified finite patience--survival complementarity | exact truncated matrix powers; no infinite resolvent derivative |
| S7 | Lean-verified finite belief-kernel comparative static | scalar persistence has no universal sign; direction requires gap-aligned discounted occupation |
| T1 | Lean-verified raw-to-compressed controlled semi-Markov projection | no generic minimality; A-GEN-FACTOR restricts raw inputs and A-TIMING declares the joint coupling |
| UDI | Lean-verified unified cost-sensitive dynamic innovation equivalence | five availability-tagged observations; refinement only in the explicitly preserving comparison class |
| T2 | Lean-verified raw UDI frontier--closure characterization with exact counterexamples | typed raw factorization for forward; A-T2-OBS for converse |
| T3 | Lean-verified unified deletion theorem with exact examples | A-T2-OBS only for the process-observation converse; recheck redundancy after every deletion |
| T4 | Lean-verified sharp normalized bridge loss | exact $\beta^d\rho^d\pi C-\kappa$; arbitrary loss is scaling only |
| T5 | Lean-verified unified raw insertion-value decomposition | no unconditional generative sign or closure-only split; premium monotonicity uses explicit project-action dominance |
| T6 | Lean-verified joint descendant-event generative-option lower bound | subtract cost; expose the exact operating and continuation blocks; require a zero-premium deleted comparator and use independence only for the product corollary |
| CS1 | Lean-verified finite sign-definite comparative statics | all directions are one-way and primitive-conditional; continued-operation delay needs no-waiting-gain |
| T7 | Lean-verified frontier--closure substitution under relative action saturation | primitive independence alone permits project-switching complementarity; frontier-dependent success supplies the economic complementarity witness |
| optional multi-gap additive bound | false and should be removed | complementarity requires new assumptions |

The current full record is
`experiments/results/revision_counterexample_gauntlet.json`; the legacy record
is `experiments/results/theorem_feasibility.json`. Boundary witnesses and their
exact reductions are recorded in those artifacts and the Lean counterexample
modules. No assumption was silently added during adjudication.

## Lean-verified foundational lemma family

### F0 — Finite-library frontier and closure calculus

- **Theorem ID:** F0
- **Manuscript label:** Foundational library lemmas; not a primary manuscript
  theorem.
- **Informal statement:** For a nonempty finite library containing an inactive
  zero strategy, the exact rational frontier is attained, bounds every member,
  and is monotone under inclusion. Raw module union and an
  extensive/monotone/idempotent generative closure are monotone. A dominated
  insertion preserves the frontier, a generatively redundant single deletion
  preserves closure, and equality of the compressed pair projects to equality
  of each component.
- **Exact Lean assumptions:**
  1. `FiniteModel` supplies nonempty finite types with decidable equality for
     beliefs, strategy identifiers, module identifiers, and research projects.
  2. `StrategyCatalog` supplies an arbitrary exact table
     `StrategyId → Belief → ℚ`, a finite module row for every identifier, an
     inactive identifier, proof that its profile is zero at every belief, and
     proof that its module set is empty.
  3. `Library` supplies a finite strategy set and proof that the inactive
     identifier belongs to it.
  4. Closure results additionally assume a `ModuleClosure` with exactly
     extensivity, monotonicity, and idempotence.
  5. Deletion additionally assumes the deleted identifier is not inactive and
     that its modules are contained in the closure of the remaining library.
- **Assumption reconciliation:** Items 1--4 are the implemented abstract
  interfaces for A-FIN, A-STRATEGY, A-LIBRARY, A-CLOSURE, and A-FRONTIER after
  D-0021. The current exact profile table is weaker and more abstract than the
  full A-BELIEF-GRID/A-PROFILE construction: no hidden-state carrier,
  `RatProb`, belief interpretation, or expectation identity is encoded yet.
  Therefore F0 may be used as a later dependency, but it does not establish
  that any T1--T7 model satisfies all adopted assumptions.
- **Lean files:** `formal/StrategyInnovation/Basic/Model.lean` and
  `formal/StrategyInnovation/Library/{Strategy,Library,Frontier,Closure,InnovationState}.lean`.
- **Proof audit file:** `formal/StrategyInnovation/Audit/Foundations.lean`.

| Lean declaration | Exact role | `#print axioms` result |
|---|---|---|
| `StrategyInnovation.Library.ext` | library extensionality | `[propext, Quot.sound]` |
| `StrategyInnovation.operationalProfile_le_frontier` | represented profile is frontier-bounded | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.zero_le_operationalFrontier` | inactive zero lower bound | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.exists_profile_eq_operationalFrontier` | finite maximum is attained | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.operationalFrontier_le_iff` | frontier boundedness characterization | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.operationalFrontier_mono` | frontier monotonicity | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.operationalFrontier_insert_of_operationallyRedundant` | dominated insertion preserves frontier | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.mem_rawModuleUnion` | module-union membership witness | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.rawModuleUnion_mono` | module-union monotonicity | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.rawModuleUnion_subset_generativeClosure` | closure extensivity at a library | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.generativeClosure_mono` | closure monotonicity | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.generativeClosure_erase_of_generativelyRedundant` | redundant deletion preserves closure | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.operationalFrontier_eq_of_compressedLibraryState_eq` | compressed equality gives frontier equality | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.generativeClosure_eq_of_compressedLibraryState_eq` | compressed equality gives closure equality | `[propext, Classical.choice, Quot.sound]` |

- **Proof dependencies:** Lean finite sets, rational linear order, genuine
  nonempty `Finset.max'`, function extensionality, and the stated closure
  fields. No Bellman, generation, verification, or primary research theorem is
  used.
- **Julia test or experiment counterpart:** `julia/test/core.jl` implements
  the reusable exact finite objects and exhaustively checks the F0
  membership-bound, zero-bound, attainment, upper-bound characterization,
  inclusion monotonicity, dominated-insertion, module-union membership,
  closure extensivity/monotonicity, redundant-deletion, and compressed-state
  projection properties on all eight admissible fixture libraries.
- **Lean examples:** `formal/StrategyInnovation/Library/Examples.lean`
  compiles concrete examples for the zero bound, dominated insertion, closure
  extensivity, redundant deletion, and compressed-state projection.
- **Manuscript location:** Section 3, label
  `lem:frontier-closure-calculus`, with the hidden-state expectation adapter
  explicitly excluded from the Lean claim.
- **Status:** Lean verified
- **Informal mathematical validity:** Elementary finite-order and closure
  arguments; the deletion proof explicitly uses only extensivity,
  monotonicity, and idempotence.
- **Lean kernel verification:** Passed under Lean 4.32.0 and mathlib commit
  `81a5d257c8e410db227a6665ed08f64fea08e997`. The reported dependencies are
  Lean/mathlib foundational principles; none is a user-declared axiom.
- **Julia implementation validation:** Reusable exact interface implemented and
  property tested with `Rational{BigInt}`. This is computational validation of
  the mapped Julia definitions, not a cross-language proof or generated Lean
  round trip.
- **Empirical relevance:** Not assessed.

### R0 — Raw generation, admission, and local compressed update

- **Theorem ID:** R0
- **Manuscript label:** Raw-model foundation; not a manuscript theorem and not
  Candidate Theorem T1.
- **Informal statement:** A raw project generates an optional catalog
  candidate according to an exact rational law. Exact verification
  probabilities lie in the closed unit interval. Composing generation and
  verification produces a nonnegative normalized admitted-candidate law:
  verified candidates retain their identifiers, while failed generation and
  failed verification contribute to `none`. Failure leaves a raw library
  unchanged and success inserts the candidate. Candidate insertion updates
  the raw module union by union, the closure by closing the old closure with
  the candidate modules, and the operational frontier by pointwise maximum.
  Therefore compression commutes with the raw update:
  `compressedLibraryState (rawLibraryUpdate L o) =
  addCompressedState (compressedLibraryState L) o`.
- **Exact Lean assumptions:**
  1. `FiniteModel` supplies finite nonempty belief, strategy, module, and
     project carriers with decidable equality.
  2. The existing exact `StrategyCatalog` supplies immutable rational profiles,
     immutable finite module rows, and the inactive zero/empty row.
  3. The existing `Library` is a finite set of strategy identifiers containing
     the inactive identifier; insertion has set semantics.
  4. `ModuleClosure` is exactly extensive, monotone, and idempotent.
  5. `CandidateGenerationDistributions.distribution q b C` is a normalized,
     pointwise-nonnegative `RatProb (Option StrategyId)` and has no raw-library
     argument beyond the displayed closure `C`.
  6. `AdmissionProbabilities.probability q b C s` is rational with explicit
     bounds `0 ≤ ν ≤ 1` and has no raw-library argument beyond the
     displayed closure `C`.
  7. `admittedCandidateMass` is definitionally the RC-Gamma formula: the
     `some s` mass is `G (some s) * ν s`, and the `none` mass is the raw
     `none` mass plus the finite sum of rejected-candidate masses.
- **Assumption reconciliation:** Items 1--4 reuse the verified A-FIN,
  A-STRATEGY, A-PROFILE, A-LIBRARY, A-CLOSURE, and A-FRONTIER interfaces.
  Items 5--7 are the finite exact portion of A-GEN-FACTOR and A-VERIFY. Project
  prerequisites are not yet encoded as a certificate that an unavailable
  project generates `none`; costs, durations, belief paths, joint completion
  coupling, availability, and Bellman values are not present.
- **Lean files:** `formal/StrategyInnovation/Raw/{StrategyCatalog,Library,
  ModuleSet,Closure,CandidateGeneration,Admission,AdmittedCandidate,
  LibraryUpdate,CompressedUpdate}.lean`, aggregated by
  `formal/StrategyInnovation/Raw.lean`.
- **Proof audit file:** `formal/StrategyInnovation/Audit/RawModel.lean`.

| Lean declaration | Exact role | `#print axioms` result |
|---|---|---|
| `StrategyInnovation.Raw.admittedCandidateDistribution_nonnegative` | derived admitted law is pointwise nonnegative | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Raw.admittedCandidateDistribution_totalMass` | derived admitted law has total mass one | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Raw.rawLibraryUpdate_none` | failed outcome is the raw-library identity | `[propext, Quot.sound]` |
| `StrategyInnovation.Raw.rawLibraryUpdate_some` | successful outcome inserts its candidate | `[propext, Quot.sound]` |
| `StrategyInnovation.Raw.closure_absorption` | closing an already closed base before adjoining modules is redundant | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Raw.rawModuleUnion_insert` | raw module union updates by finite union | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Raw.generativeClosure_insert` | generative closure updates locally | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Raw.operationalFrontier_insert` | frontier updates by pointwise maximum | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Raw.compressedLibraryState_rawLibraryUpdate` | compressed raw-update identity RC1 | `[propext, Classical.choice, Quot.sound]` |

- **Proof dependencies:** exact rational order and ring normalization; finite
  sums over `Option StrategyId`; `RatProb` normalization; set-valued library
  insertion; attained finite frontiers; and closure extensivity, monotonicity,
  and idempotence. No primitive research transition, Bellman recursion, or
  value theorem is used.
- **Difference from T1:** R0 alone proves the normalization prerequisite and
  RC1 only. T1 is now completed in
  `StrategyInnovation/Projection/RawToCompressed.lean`, which supplies the
  realizable carrier, declared joint completion coupling, transition
  pushforwards, embedded law, and raw/compressed value recursions.
- **Status:** Lean verified
- **Informal mathematical validity:** The admission proof partitions each
  generated candidate's mass into pass and fail components. The local update
  proof is finite maximum/union algebra plus closure absorption.
- **Lean kernel verification:** The focused audit passes under Lean 4.32.0 and
  pinned mathlib. Only the standard dependencies listed in the table occur;
  no user-declared axiom or placeholder is present.
- **Julia implementation validation:** `julia/src/RawDynamicProgramming.jl`
  now implements catalog-validated candidate outcomes, exact generation and
  verification, the derived admitted law, raw insertion, local compressed
  update, and the induced compressed pushforward. Exhaustive fixture tests
  compare every raw-library/outcome update and explicitly check partial
  verification's rejected mass.
- **Empirical relevance:** Not assessed.

### UDI — Unified cost-sensitive dynamic innovation equivalence

- **Theorem ID:** UDI
- **Manuscript labels:** `def:dynamic-innovation-equivalence`,
  `prop:di-equivalence-relation`, `thm:di-quotient-sufficiency`, and
  `prop:di-refinement-minimality`.
- **Informal statement:** Two raw libraries are dynamically innovation
  equivalent when they have identical current frontiers and identical
  availability-tagged project costs, durations, joint terminal
  belief/compressed-state laws, and expected discounted incumbent-reward
  blocks. This is an equivalence relation. It preserves every zero-terminal
  unified calendar-horizon raw value and, under T1's explicit contraction
  certificates, the raw stationary fixed-point value. Its raw-library
  quotient is finite, finite-horizon value factors through the quotient, and
  equality of actual compressed states is sufficient for equivalence.
- **Exact Lean assumptions:** T1's `Projection.Model`: finite nonempty belief,
  strategy, module, and project types; exact rational generation/admission and
  completion laws; positive project-specific duration; state-indexed
  availability and nonnegative cost; operation flag; exact rational discount
  in `[0,1)`; and the raw/compressed update identity inherited from R0. The
  infinite theorem additionally takes the explicit raw and compressed
  `ContractingWith` certificates already displayed by
  `DiscountedContractionModel`.
- **Signature reconciliation:** `availableProjectData` returns `none` for an
  unavailable project and `some data` otherwise. Thus equality of each
  project observation includes equality of its domain and derives identical
  feasible menus without a hidden sixth conjunct. `projectNextStateLaw` is
  the exact pushforward of the declared completion coupling to terminal belief
  and next realizable compressed state. `expectedOperatingReward` is the exact
  expected discounted incumbent-reward block; additivity makes this marginal
  sufficient alongside the complete terminal joint law. In the present Lean
  model duration is project-specific, so its tagged equality is nontrivial
  through project availability.
- **Lean declarations:**
  `StrategyInnovation.Projection.Model.dynamicInnovationEquivalent_refl`;
  `StrategyInnovation.Projection.Model.dynamicInnovationEquivalent_symm`;
  `StrategyInnovation.Projection.Model.dynamicInnovationEquivalent_trans`;
  `StrategyInnovation.Projection.Model.dynamicInnovationQuotientFinite`;
  `StrategyInnovation.Projection.Model.compressedState_eq_implies_dynamicInnovationEquivalent`;
  `StrategyInnovation.Projection.Model.rawValue_eq_of_dynamicInnovationEquivalent`;
  `StrategyInnovation.Projection.Model.finiteHorizonValue_depends_only_on_dynamicInnovationClass`;
  `StrategyInnovation.Projection.Model.DiscountedContractionModel.compressedFixedPoint_eq_of_equivalent`;
  `StrategyInnovation.Projection.Model.DiscountedContractionModel.rawFixedPoint_eq_of_dynamicInnovationEquivalent`;
  `StrategyInnovation.Projection.Model.representation_refines_dynamicInnovationEquivalent`.
- **Lean file:**
  `formal/StrategyInnovation/Quotient/UnifiedDynamicInnovation.lean`.
- **Proof dependencies:** exact deterministic pushforward expectation;
  decomposition of each project action into cost, expected operating reward,
  and discounted expectation under the joint terminal law; equality of tagged
  durations to recover the feasible menu; strong calendar-horizon induction;
  preservation of class-constant real tables by the stationary Bellman
  operator; convergence of contraction iteration from zero; finite quotient
  inference; and T1 raw/compressed value intertwining.
- **Restricted refinement boundary:**
  `PreservesDynamicInnovationObservations` requires equal representation
  fibers to preserve all five displayed observations. The refinement theorem
  merely packages those equalities into UDI. It does not assert generic
  minimality, full abstraction, or a canonical map from every representation
  quotient.
- **Legacy migration:** The top-level
  `StrategyInnovation.DynamicInnovationEquivalent` and related F1 theorem
  names remain compiled only for the cost-free primitive supporting layer.
  They are superseded, not aliases. The exact name table is
  `formal/StrategyInnovation/Quotient/MIGRATION.md`. The separate F5/F8
  cost-sensitive primitive-timing relations are also supporting results, not
  aliases for UDI.
- **`#print axioms` result:** Every principal UDI declaration reports exactly
  `[propext, Classical.choice, Quot.sound]`; no user-declared axiom occurs.
- **Julia test or experiment counterpart:** The exact unified falsification
  oracle compares the full semi-Markov signature and value tables. This Lean
  change adds no new Julia implementation and does not promote finite search
  to proof.
- **Manuscript location:** Section 4 states the five observations, exact
  availability tagging, and their finite/infinite value-preservation
  consequence. Appendix A, `app:di-quotient`, contains the equivalence-relation
  proof, finite quotient, value factorization, compressed-state sufficiency,
  and restricted representation-refinement boundary.
- **Status:** Lean verified
- **Informal mathematical validity:** Equality algebra gives the equivalence
  laws. Exact action decomposition and strong induction give finite value
  preservation. Bellman iteration from zero stays class-constant and converges
  to the unique contraction fixed point. Quotient finiteness follows from the
  finite raw-library carrier.
- **Lean kernel verification:** The focused UDI audit and comprehensive axiom
  audit pass with only the standard foundations listed above.
- **Julia implementation validation:** Existing exact finite signature/value
  comparisons are consistent with the encoded result; no Julia source changed.
- **Empirical relevance:** Not assessed.

### F1 — Deprecated abstract dynamic innovation quotient and value preservation

- **Theorem ID:** F1
- **Manuscript label:** Deprecated abstract finite research semantics and the
  primitive F2--F4 supporting layer.
- **Informal statement:** On admissible finite libraries, equality of current
  frontiers and all primitive compressed-state research transition laws is an
  equivalence relation. The abstract cost-free finite-horizon value is
  invariant under that relation and therefore factors through its finite
  quotient. Any representation whose equal fibers preserve those rewards and
  transitions refines the dynamic innovation quotient.
- **Exact Lean assumptions:**
  1. `FiniteModel` supplies nonempty finite types with decidable equality for
     beliefs, strategy identifiers, module identifiers, and projects.
  2. `StrategyCatalog`, `Library`, and `ModuleClosure` supply the exact
     frontier/closure compression from F0. Admissible libraries have an
     explicit finite enumeration.
  3. `RatProb α` is a finitely supported rational mass function with
     pointwise nonnegativity and total mass one. Its carrier `α` need not be
     finite; in particular it may be the ambient `InnovationState`.
  4. `FiniteResearchSemantics` supplies a common exact belief kernel, a
     primitive research kernel indexed by current belief, compressed state,
     and project, plus rational `discount` with `0 ≤ discount < 1`.
  5. The recursion receives current frontier reward, then maximizes between an
     idle continuation that retains the compressed state and one project from
     the nonempty finite project type. Belief and research outcomes use nested
     expectations, encoding their conditional product. There is no current
     project-cost term.
  6. Dynamic innovation equivalence assumes equality of all current frontier
     values and equality of the entire next-state `RatProb` for every current
     belief and project.
  7. The minimality theorem quantifies over an arbitrary representation and
     assumes, rather than derives, that equality of representation values
     preserves item 6's current rewards and transitions.
- **Assumption reconciliation:** Items 1--6 implement A-FIN, the F0 interfaces,
  the exact finite-support part of A-RATPROB, A-DISCOUNT, and the separate
  supporting assumption A-DI-ABSTRACT. The `Finsupp` representation is a
  conservative generalization of A-RATPROB from finite carriers to
  finite-support mass on the ambient state. Item 7 is the explicit comparison
  class for minimality. A-BELIEF-GRID's hidden-state interpretation,
  A-GEN-FACTOR, A-VERIFY, A-COST, raw admission, and the local-update part of
  A-TIMING are not encoded.
- **Lean files:**
  `formal/StrategyInnovation/Basic/Probability.lean` and
  `formal/StrategyInnovation/Quotient/DynamicInnovation.lean`.
- **Proof audit file:**
  `formal/StrategyInnovation/Audit/DynamicInnovation.lean`.

| Lean declaration | Exact role | `#print axioms` result |
|---|---|---|
| `StrategyInnovation.RatProb.ext` | exact finite-support probability extensionality | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.dynamicInnovationEquivalent_refl` | DI reflexivity | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.dynamicInnovationEquivalent_symm` | DI symmetry | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.dynamicInnovationEquivalent_trans` | DI transitivity | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.compressedFiniteHorizonValue_eq_of_frontier_and_transition_eq` | compressed-state value congruence | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.finiteHorizonValue_eq_of_dynamicInnovationEquivalent` | library value preservation | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.quotientFiniteHorizonValue_mk` | quotient evaluation | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.finiteHorizonValue_depends_only_on_dynamicInnovationClass` | abstract Markov sufficiency | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.representation_refines_dynamicInnovationEquivalent` | explicit minimality/refinement | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.representationQuotientToDynamicInnovationQuotient_mk` | canonical refinement-map evaluation | `[propext, Classical.choice, Quot.sound]` |

- **Quotient declarations:** `StrategyInnovation.dynamicInnovationSetoid`,
  `StrategyInnovation.DynamicInnovationQuotient`,
  `StrategyInnovation.dynamicInnovationClass`, and the finite instance
  `StrategyInnovation.dynamicInnovationQuotientFinite`.
- **Proof dependencies:** exact `Finsupp` expectation; finite nonempty project
  maximum; horizon induction; equality substitution for transition laws;
  `Quotient.lift`; and the F0 frontier projection of compressed states.
- **Deprecation boundary:** `dynamicLibraryValue` is defined by
  compressing the raw library before recursion. The kernel on compressed
  states is primitive, project costs are absent, and no raw candidate,
  verification, admission, or local state-update semantics appears. Thus F1
  is not the final-model equivalence or value theorem. Its top-level names are
  superseded by the namespaced UDI declarations; they remain compiled because
  F2--F4 depend on this primitive supporting calculus.
- **Stronger formulation not claimed:** no generic categorical minimality,
  coarsest bisimulation under arbitrary continuation contexts, or relationship
  between DI classes and equality of the frontier/closure pair is proved. The
  canonical quotient map exists only under the two explicit preservation
  predicates.
- **Julia test or experiment counterpart:** `julia/test/core.jl` implements the
  exact primitive `FiniteResearchSemantics` relation and exhaustively checks DI
  reflexivity, symmetry, and transitivity on the finite fixture libraries. It
  also checks transition-sensitive and behaviorally silent closure examples.
  No Julia quotient or abstract finite-horizon value recursion is implemented.
- **Manuscript location:** Section 4's deprecated primitive supporting
  subsection states the abstract recursion. The F2 characterization there is
  explicitly written for `~_DI^prim`, not the unified relation.
- **Status:** Lean verified; deprecated as a publication-facing interface
- **Informal mathematical validity:** The equivalence laws are equality
  algebra; value preservation is finite-horizon induction; explicit minimality
  follows directly from the stated preservation predicates.
- **Lean kernel verification:** Passed under Lean 4.32.0 and mathlib commit
  `81a5d257c8e410db227a6665ed08f64fea08e997`. All registered declarations
  report only the listed Lean/mathlib foundational principles.
- **Julia implementation validation:** The exact DI relation and `RatProb`
  extensional equality are implemented and property tested. F1's quotient,
  value preservation, and refinement-map results remain Lean-only. Controlled
  family A additionally maps 65 pairs of distinct raw code identities with
  equal frontier and closure into the same exact finite process state and
  confirms identical horizon-three values and policies. That mapping is a
  mechanism fixture, not a Julia construction of the F1 quotient or raw T1.
- **Empirical relevance:** Not assessed.

### F2 — Abstract frontier--closure characterization

- **Theorem ID:** F2
- **Manuscript label:** Abstract frontier--closure characterization; deprecated
  supporting theorem, not raw T2.
- **Informal statement:** If the primitive compressed transition factors
  through a declared modular generator $g(b,F,C,q)$, equality of frontier and
  closure implies DI equivalence and hence equality of every abstract
  finite-horizon value. Conversely, if every distinct pair of realizable
  closures at a common frontier is separated by some belief--project transition
  law, DI equivalence implies equality of frontier and closure.
- **Exact Lean assumptions:**
  1. F0 supplies finite admissible libraries, exact frontiers, generative
     closures, and `compressedLibraryState`.
  2. F1 supplies `FiniteResearchSemantics`, exact finite-support next-state
     distributions, `DynamicInnovationEquivalent`, and its value-preservation
     theorem.
  3. `ModularGenerator.candidateTransition` has type
     `Belief → (Belief → ℚ) → Finset ModuleId → ResearchProject →
     RatProb InnovationState`.
  4. `GeneratorFactorsThroughFrontierClosure` requires, for every belief,
     ambient `InnovationState`, and project, equality between the semantics'
     research transition and the modular generator evaluated at that state's
     frontier and closure.
  5. `ClosureIdentifiable` requires, for every frontier and every unequal pair
     of finite module sets separately realized with that same frontier,
     witnesses `belief` and `project` whose modular next-state distributions
     are unequal.
  6. No frontier-identifiability binder is assumed. Operational equivalence
     supplies pointwise frontier equality, and
     `currentReward_detects_frontier` proves function equality by
     extensionality.
- **Assumption reconciliation:** Items 1--4 implement A-FIN, the F0/F1
  interfaces, A-DI-ABSTRACT, and A-FC-FACTOR. Item 5 is exactly A-FC-IDENT.
  The forward and value-sufficiency theorems use A-FC-FACTOR but not
  A-FC-IDENT. The converse and iff use both. A-GEN-FACTOR, A-VERIFY, A-COST,
  raw admission, and A-T2-OBS's cost/admitted-kernel signature are not
  encoded.
- **Lean file:**
  `formal/StrategyInnovation/Quotient/FrontierClosure.lean`.
- **Proof audit file:**
  `formal/StrategyInnovation/Audit/FrontierClosure.lean`.

| Lean declaration | Exact role | `#print axioms` result |
|---|---|---|
| `StrategyInnovation.currentReward_detects_frontier` | pointwise reward detects frontier | `[propext, Quot.sound]` |
| `StrategyInnovation.frontier_eq_of_operationallyEquivalent` | operational equivalence detects library frontier | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.researchTransition_eq_modularGenerator_on_library` | raw-library factorization equation | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.frontierClosure_eq_implies_dynamicInnovationEquivalent` | forward/sufficiency direction | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.dynamicInnovationEquivalent_implies_frontierClosure_eq` | identifiable converse | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.dynamicInnovationEquivalent_iff_frontierClosure_eq` | exact componentwise iff | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.dynamicInnovationEquivalent_iff_compressedLibraryState_eq` | compressed-state iff | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.frontierClosure_eq_preserves_finiteHorizonValue` | finite-horizon value sufficiency | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierClosureCounterexamples.constantSemantics_factors` | factorized counterexample generator | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierClosureCounterexamples.frontier_converse_fails_without_currentReward` | missing-frontier-observation witness | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierClosureCounterexamples.closure_converse_fails_without_identifiability` | missing-closure-identification witness | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierClosureCounterexamples.constantGenerator_not_closureIdentifiable` | failed identifiability certificate | `[propext, Classical.choice, Quot.sound]` |

- **Proof dependencies:** function extensionality for frontier recovery;
  rewriting by the factorization equation; the witnessed contrapositive of
  closure identifiability; equality of structure fields; and F1's
  finite-horizon value preservation.
- **Counterexamples:** CX-F2-FRONTIER-OBS-01 has equal constant transition
  signatures but unequal frontiers when current rewards are omitted.
  CX-F2-CLOSURE-ID-01 has equal current frontiers and transitions but unequal
  closures under a constant generator. Both are typed finite Lean models.
- **Difference from raw T2:** F2 observes a primitive next-compressed-state
  distribution and contains no project cost, raw candidate kernel,
  verification, admitted-candidate kernel, or local admission update. Raw T2
  separately derives the factorization consequences and projected transition
  from those primitives in `Projection.Model`.
- **Manuscript location:** Section 4, labels
  `thm:frontier-closure-sufficiency` and
  `thm:frontier-closure-characterization`, with factorization separated from
  converse-only closure detectability and with the distinction from T2 stated
  explicitly.
- **Status:** Lean verified
- **Informal mathematical validity:** The forward implication is direct
  substitution. The converse first recovers the frontier from current rewards,
  then contradicts a closure-separating project witness.
- **Lean kernel verification:** Passed under Lean 4.32.0 and mathlib commit
  `81a5d257c8e410db227a6665ed08f64fea08e997`. No user-declared axiom or
  placeholder appears.
- **Julia implementation validation:** Controlled family A checks the forward
  frontier--closure mechanism on 65 exact alias pairs. Family B holds closure
  fixed while changing frontier, then holds frontier fixed while changing
  closure, and observes exact passive/premium changes `(3,0)` and `(0,4)`.
  This does not test F2's identifiable converse; raw T2 has its own exact
  projection proof and boundary counterexamples.
- **Empirical relevance:** Not assessed.

### F3 — Abstract innovation-safe deletion

- **Theorem ID:** F3
- **Manuscript label:** Abstract innovation-safe deletion; supporting theorem,
  not the unified raw-model T3.
- **Informal statement:** If deleting a noninactive strategy preserves both
  the operational frontier and the generative closure, then it preserves the
  compressed state, gives dynamic innovation equivalence under modular
  generator factorization, and preserves every abstract finite-horizon value.
  Under factorization and closure identifiability, preservation of all current
  rewards and every allowed project-transition distribution conversely
  recovers frontier and closure preservation. A proof-relevant sequence of
  stepwise value-safe deletions preserves all finite-horizon values and ends in
  an innovation-safe sublibrary.
- **Exact Lean assumptions:**
  1. F0 supplies finite admissible libraries, noninactive single deletion,
     operational frontiers, generative closures, and frontier--closure
     compressed states.
  2. `operationallyRedundant` and `generativelyRedundant` are defined by exact
     equality after deletion, oriented as
     $F_{L^{-s}}=F_L$ and $C_{L^{-s}}=C_L$. They do not assume that the
     deleted identifier is present; deletion of an absent noninactive
     identifier is a no-op.
  3. `compressedStatePreservingDeletion` is exact compressed-state equality.
     It is not definitionally identified with DI equivalence or value
     preservation.
  4. F1 supplies the primitive cost-free compressed transition semantics,
     dynamic innovation equivalence, and its finite-horizon value theorem.
     `safelyDeletable` means exact value equality for every natural-number
     horizon and every belief.
  5. The sufficient DI and value theorems assume A-FC-FACTOR through
     `GeneratorFactorsThroughFrontierClosure`.
  6. The converse assumes A-FC-IDENT and A-SD-OBS: equality of current frontier
     rewards and equality of the complete exact transition distribution for
     every belief and project. It does not infer transition equality from
     optimized value equality.
  7. `SafeDeletionSequence` checks noninactive status and `safelyDeletable` at
     each intermediate library. `InnovationSafeCompression` additionally
     records that the endpoint is a sublibrary.
- **Assumption reconciliation:** Items 1--5 are exactly the F0/F1 interfaces,
  A-DI-ABSTRACT, and A-FC-FACTOR. Item 6 is A-FC-IDENT plus A-SD-OBS. Item 7
  is an inductive sequence of A-T3-DELETE-shaped single deletions, but its
  safety premise is the abstract value predicate. Raw generation,
  verification, costs, admission, local updates, the raw Bellman recursion,
  and unified T3's process observations and action values are absent.
- **Lean file:**
  `formal/StrategyInnovation/Compression/SafeDeletion.lean`.
- **Proof audit file:**
  `formal/StrategyInnovation/Audit/SafeDeletion.lean`.
- **Definitions:** `StrategyInnovation.operationallyRedundant`,
  `StrategyInnovation.generativelyRedundant`,
  `StrategyInnovation.compressedStatePreservingDeletion`,
  `StrategyInnovation.safelyDeletable`,
  `StrategyInnovation.deletionPreservesCurrentRewardAndProjects`,
  `StrategyInnovation.SafeDeletionSequence`, and
  `StrategyInnovation.InnovationSafeCompression`.

| Lean declaration | Exact role | `#print axioms` result |
|---|---|---|
| `StrategyInnovation.redundantDeletion_iff_compressedStatePreservingDeletion` | component equality iff compressed-state equality | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.redundantDeletion_dynamicInnovationEquivalent` | frontier/closure sufficient condition for deletion DI | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.redundantDeletion_safelyDeletable` | redundant deletion preserves every finite-horizon value | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.deletionPreservesCurrentRewardAndProjects_iff_dynamicInnovationEquivalent` | observation predicate is deletion DI | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.deletionObservations_imply_operationallyAndGenerativelyRedundant` | identifiable observation-level converse | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.deletionPreservesCurrentRewardAndProjects_iff_redundant` | exact deletion-observation iff | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.safeDeletionSequence_sublibrary` | repeated deletion endpoint is included in source | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.safeDeletionSequence_preserves_finiteHorizonValue` | repeated safe deletion preserves value | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.safeDeletionSequence_innovationSafeCompression` | repeated deletion produces safe compression | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.SafeDeletionCounterexamples.ratProb_dirac_injective` | exact point masses identify outcomes | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.SafeDeletionCounterexamples.revealingSemantics_factors` | counterexample satisfies factorization | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.SafeDeletionCounterexamples.revealingGenerator_closureIdentifiable` | counterexample satisfies closure identifiability | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.SafeDeletionCounterexamples.bridgeLibrary_erase_eq_inactiveLibrary` | concrete deletion computation | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.SafeDeletionCounterexamples.finiteHorizonValuePreservation_does_not_imply_generativeRedundancy` | value-only converse counterexample | `[propext, Classical.choice, Quot.sound]` |

- **Proof dependencies:** structure extensionality for compressed states;
  F2's factorization and identifiable converse; F1's value preservation;
  transitivity of rational equality along an inductive deletion sequence; and
  library inclusion under `Finset.erase`.
- **Exact examples:** three anonymous `example` declarations check,
  respectively, a zero-profile duplicate that is operationally and
  generatively redundant, a zero-profile bridge that is operationally
  redundant but generatively essential, and a positive leader that is
  operationally essential but generatively redundant.
- **Counterexample:** CX-F3-VALUE-ID-01 uses one belief, one project, one
  module, a revealing Dirac generator, and discount zero. Factorization and
  closure identifiability both hold, but deletion values do not detect the
  closure difference.
- **Revised requested converse:** no theorem states that `safelyDeletable`
  implies frontier or closure preservation. The strongest verified converse
  is
  `deletionObservations_imply_operationallyAndGenerativelyRedundant`, whose
  premise explicitly preserves current rewards and all project-transition
  laws. This revision is visible in A-SD-OBS, FG-0015, and manuscript
  Theorem 2.
- **Difference from unified T3:** F3 uses a primitive cost-free transition
  kernel and omits raw generation, admission, duration, initiation cost,
  operating reward, joint terminal law, and fixed-point action comparisons.
  It remains a supporting predecessor; the separate
  `Projection.Model` T3 declarations establish the final raw-model theorem.
- **Manuscript location:** Theorem 2 in `manuscript/main.tex`, explicitly
  labeled as abstract supporting result F3.
- **Status:** Lean verified
- **Informal mathematical validity:** The sufficient condition is component
  substitution followed by F2 and F1. Repeated deletion is equality
  transitivity. The observation-level converse is F2's identifiable converse.
  The rejected value-only converse has a kernel-checked finite counterexample.
- **Lean kernel verification:** Passed under Lean 4.32.0 and mathlib commit
  `81a5d257c8e410db227a6665ed08f64fea08e997`. Every registered declaration
  reports only `[propext, Classical.choice, Quot.sound]`; no user-declared
  axiom or placeholder appears.
- **Julia implementation validation:** The deletion-side operational and
  generative predicates guard `innovation_safe_delete`; deterministic
  fixed-point pruning rechecks both predicates at every intermediate library.
  The exact batch counterexample confirms why simultaneous inference is
  invalid. Exhaustive small-instance minimization and a solver-neutral 0--1
  frontier/closure formulation are cross-checked against exact compressed
  states, including a nonidentity closure. Forty seeded small-library property
  fixtures validate compressed-state, primitive F1 DI, and script-local F1
  value preservation. This is computational validation; the reusable package
  still does not implement Lean's value recursion or the observation-level
  converse. Controlled family C also deletes two both-redundant strategies
  stepwise and confirms exact endpoint state, horizon-three value, and policy
  equality.
- **Empirical relevance:** Not assessed.

### F4 — Sharp scaled frontier-only pruning loss

- **Theorem ID:** F4
- **Manuscript label:** Arbitrary loss only by reward scaling; supporting
  specialization and regression corollary after T4.
- **Informal statement:** In an explicit finite model, a zero-payoff strategy
  is operationally redundant but uniquely carries the module required to
  generate a future strategy. Frontier-only pruning deletes it while preserving
  the current frontier. With horizon two and discount $1/2$, pruning loss is
  exactly half the future reward. Hence reward $2M$ realizes every natural
  target loss $M$. Under reward cap $C$, the sharp maximum in this
  construction is $C/2$.
- **Exact Lean construction and assumptions:**
  1. `FrontierPruningLoss.model` has singleton belief, module, and project
     types and exactly three strategy identifiers: inactive, dominated, and
     future.
  2. `profile reward` assigns zero to inactive and dominated and exact rational
     `reward` to future. `modules` assigns the singleton key module only to
     dominated.
  3. The current unpruned library is `{inactive, dominated}`, its frontier-only
     deletion is `{inactive}`, and the successful future library is
     `{inactive, future}`. Identity module closure is used.
  4. `generator reward` returns a Dirac mass at the future-library compressed
     state iff the key belongs to the supplied closure, and otherwise a Dirac
     mass at the pruned-library state.
  5. `semantics reward` has deterministic constant belief, the generator's
     primitive compressed transition, no project-cost term, and exact discount
     $1/2$. Values are compared at horizon two.
  6. The exact-loss theorem assumes `0 ≤ reward`. The arbitrary-loss theorem
     quantifies over `target : ℕ` and chooses rational reward `2 * target`.
  7. `RewardsBoundedBy reward cap` requires every profile at every belief to
     lie in $[0,C]$. The sharp theorem assumes `0 ≤ cap`.
- **Assumption reconciliation:** Items 1--7 are exactly A-F4-SCALED on the
  F0/F1/F3 interfaces. They do not encode raw candidate generation,
  verification, admission, costs, or local raw-library updates. Arbitrary loss
  comes from scaling the future reward and does not use A-T4-SCALE.
- **Lean file:**
  `formal/StrategyInnovation/Counterexamples/FrontierPruningLoss.lean`.
- **Proof audit file:**
  `formal/StrategyInnovation/Audit/FrontierPruningLoss.lean`.
- **Definitions:** `StrategyInnovation.FrontierPruningLoss.profile`,
  `modules`, `catalog`, `prunedLibrary`, `unprunedLibrary`, `futureLibrary`,
  `frontierOnlyPrune`, `generator`, `semantics`,
  `FrontierPruningWitness`, and `RewardsBoundedBy`.

| Lean declaration | Exact role | `#print axioms` result |
|---|---|---|
| `StrategyInnovation.FrontierPruningLoss.keyModule_unique_to_dominated` | only the bridge carries the key module | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierPruningLoss.pruned_frontier_eq_zero` | pruned current frontier is exactly zero | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierPruningLoss.unpruned_frontier_eq_zero` | unpruned current frontier is exactly zero | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierPruningLoss.dominated_operationallyRedundant` | bridge deletion preserves current frontier | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierPruningLoss.dominated_not_generativelyRedundant` | bridge deletion changes closure | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierPruningLoss.frontierOnlyPrune_eq_pruned` | explicit frontier-only rule deletes bridge | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierPruningLoss.current_frontiers_equal` | pruned and unpruned current frontiers agree | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierPruningLoss.semantics_factors` | transition factors through declared generator | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierPruningLoss.researchTransition_unpruned` | retained module reaches future state | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierPruningLoss.researchTransition_pruned` | absent module remains pruned | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierPruningLoss.pruned_value_two_eq_zero` | exact pruned horizon-two value | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierPruningLoss.unpruned_value_two_eq_half_reward` | exact unpruned horizon-two value | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierPruningLoss.frontierPruningLoss_exact` | exact pruning loss `reward / 2` | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierPruningLoss.frontierPruningLoss_scaledTarget_exact` | reward `2 * target` gives loss exactly `target` | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierPruningLoss.frontierPruningLoss_arbitrarilyLarge` | every natural target has a scaled exact witness | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FrontierPruningLoss.boundedReward_frontierPruningLoss_sharp` | capped loss is at most and attains `cap / 2` | `[propext, Classical.choice, Quot.sound]` |

- **Proof dependencies:** finite frontier boundedness; exact computation of
  singleton module unions; `RatProb.dirac` expectations; the singleton finite
  project maximum; exact rational normalization; and the horizon-two abstract
  recursion.
- **Relationship to T4:** F4 is now the primitive-transition specialization
  $d=1,\beta=1/2,\rho=\pi=1,\kappa=0$ of the normalized raw-law formula.
  It remains compiled as supporting regression evidence. Its arbitrary-loss
  result is secondary and uses explicit reward scaling.
- **Manuscript location:** Corollary
  `thm:scaled-frontier-pruning-loss`, after the primary normalized T4 theorem.
- **Status:** Lean verified
- **Informal mathematical validity:** Both current frontiers are zero. The
  retained key makes research reach reward `R`, giving discounted value
  `R/2`; pruning removes the key and leaves value zero.
- **Lean kernel verification:** Passed under Lean 4.32.0 and mathlib commit
  `81a5d257c8e410db227a6665ed08f64fea08e997`. Every registered declaration
  reports only `[propext, Classical.choice, Quot.sound]`; no user-declared
  axiom or placeholder appears.
- **Julia implementation validation:** The exact `Rational{BigInt}` Julia
  fixture mirrors the singleton belief, three strategies, key module, identity
  closure, revealing Dirac generator, discount `1//2`, and horizon-two F1
  recursion. Targets 0, 1, 5, and 13 reproduce pruning to the inactive library,
  current-frontier equality, generative-closure loss, pruned value zero, and
  exact loss `reward / 2 = target`. The target-zero edge case correctly has
  equal primitive transition outcomes despite unequal closure. This is
  now the deterministic specialization of the normalized raw T4 formula.
  Controlled family D extends this regression to future rewards
  `0,2,4,10,20,40`, checks closure loss with current-frontier preservation,
  and obtains the exact loss sequence `0,1,2,5,10,20`.
- **Empirical relevance:** Not assessed.

### F5 — Exact finite-state Bellman calculus

- **Theorem ID:** F5
- **Manuscript label:** Supporting exact finite-horizon value calculus; not
  Candidate Theorem T1.
- **Informal statement:** On finite belief, compressed-state, project, and
  action spaces, exact expectation and the finite-action Bellman operator are
  monotone. The horizon recursion is uniformly bounded on the finite state
  space, preserves cost-sensitive dynamic innovation equivalence, factors
  through any declared raw-to-compressed map, and has a maximizing action at
  every finite horizon.
- **Exact Lean assumptions:**
  1. `FiniteModel` supplies nonempty finite belief and research-project types
     with decidable equality. Its strategy and module carriers are present but
     unused by this generic value layer.
  2. `FiniteHorizon.Process` supplies a nonempty finite compressed-state type
     with decidable equality, an exact rational frontier table, a common exact
     belief kernel, and an exact compressed-state research kernel.
  3. Every kernel is a normalized, pointwise-nonnegative `RatProb`; its
     expectation is the finite `Finsupp` sum.
  4. Research cost is an exact rational table with a pointwise nonnegativity
     certificate. The certificate is a model-validity condition; the
     monotonicity and equivalence proofs need equality of costs, not their
     sign.
  5. The rational discount satisfies $0\le\beta<1$. Nonnegativity is used
     by Bellman monotonicity; the strict upper bound is recorded for the model
     but is unnecessary for a finite-horizon recursion.
  6. Each project has `researchDelay : ResearchProject → Nat`. A delay `d`
     multiplies completion continuation by $\beta^{d+1}$; the recursion
     horizon counts decision epochs.
  7. `none` continues, earns the current frontier, retains compressed state,
     and advances belief. `some q` researches, pays negative current cost, and
     advances belief and compressed state through nested exact expectations.
  8. `FiniteHorizon.DynamicInnovationEquivalent` requires equality of current
     frontier values, every current research cost, and every exact
     next-compressed-state distribution.
- **Assumption reconciliation:** Items 1--8 are exactly A-FH-VALUE together
  with the finite-support component of A-RATPROB, A-DISCOUNT, and A-HORIZON.
  Cost equality is an explicit addition to F1's DI signature and is necessary
  because action-specific research costs affect horizon-one value. The common
  belief kernel and nested expectations encode a conditional product law.
- **Lean file:**
  `formal/StrategyInnovation/Value/FiniteHorizon.lean`.
- **Proof audit file:**
  `formal/StrategyInnovation/Audit/FiniteHorizon.lean`.
- **Definitions:** `StrategyInnovation.FiniteHorizon.Process`,
  `expectedValue`, `ValueFunction`, `ValueFunctionLE`, `continueValue`,
  `researchValue`, `Action`, `actionValue`, `bellmanStep`,
  `finiteHorizonValue`, `DynamicInnovationEquivalent`,
  `finiteHorizonValueBound`, and `rawFiniteHorizonValue`.

| Lean declaration | Exact role | `#print axioms` result |
|---|---|---|
| `StrategyInnovation.FiniteHorizon.expectedValue_extensionality` | expectation extensionality | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FiniteHorizon.expectedValue_mono` | expectation monotonicity | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FiniteHorizon.bellmanStep_mono` | Bellman monotonicity | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FiniteHorizon.bellmanStep_respectsDynamicInnovation` | one-step DI preservation | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FiniteHorizon.finiteHorizonValue_eq_of_dynamicInnovationEquivalent` | all-horizon DI value preservation | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FiniteHorizon.abs_finiteHorizonValue_le_bound` | explicit absolute-value bound | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FiniteHorizon.finiteHorizonValue_bounded` | existential nonnegative uniform bound | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FiniteHorizon.rawFiniteHorizonValue_eq_of_compressedState_eq` | equality on compression fibers | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FiniteHorizon.finiteHorizonValue_factors_through_compressedState` | explicit compressed-state factorization | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.FiniteHorizon.finiteHorizon_optimalAction_exists` | finite-horizon maximizing action | `[propext, Classical.choice, Quot.sound]` |

- **Proof dependencies:** order preservation of finite rational sums with
  nonnegative probability masses; nonnegative multiplication and powers;
  finite `Finset.sup'` monotonicity and attainment; induction on the natural
  horizon; equality substitution for costs and kernels; and the finite maximum
  of absolute values on belief--state pairs.
- **Difference from intended T1:** F5 has no raw-library recursion and does
  not derive its compressed transition from generation, verification,
  admission, or local frontier--closure updates. Its requested action timing
  gives the frontier reward only to Continue and uses delay only in
  $\beta^{d+1}$, whereas unified A-TIMING evolves belief and incumbent
  rewards through the full duration and uses a declared joint completion law.
  Its raw factorization theorem evaluates a raw input by applying the supplied
  compression map by definition; it is not the raw-to-compressed simulation
  required by T1. FG-0017 records this boundary.
- **Infinite-horizon boundary:** F5 itself defines no infinite series,
  contraction, stationary policy, or limit theorem. Supporting F8 later proves
  the primitive-state contraction and value limit, but not a stationary policy
  or raw-model bridge.
- **Julia test or experiment counterpart:**
  `julia/src/DynamicProgramming.jl` implements the same finite
  belief--compressed-state carrier, continue/research actions, costs, delays,
  nested product transition, exact Bellman step, finite-horizon recursion,
  policy extraction, and exact cost-sensitive DI decision procedure.
  `julia/test/test_dynamic_programming.jl` matches hand calculations and the
  exact F4/arbitrary-loss family, and tests Bellman monotonicity on 32 explicitly
  seeded small processes.
- **Manuscript location:** The primitive F5 timing remains compatibility
  infrastructure rather than the publication operator. Section 6 uses the
  unified T1/S2 operators and raw-derived six-state benchmark; Appendix D's
  “Legacy regression fixture” alone retains the six-state compatibility
  process and states its timing boundary.
- **Status:** Lean verified
- **Informal mathematical validity:** Finite sums and finite maxima make the
  monotonicity, boundedness, and optimizer arguments elementary; DI value
  preservation is induction on the finite horizon.
- **Lean kernel verification:** Passed under Lean 4.32.0 and mathlib commit
  `81a5d257c8e410db227a6665ed08f64fea08e997`. Every principal theorem reports
  only `[propext, Classical.choice, Quot.sound]`; no user-declared axiom or
  placeholder appears.
- **Julia implementation validation:** `Rational{BigInt}` is used throughout
  theorem fixtures. Exact finite-horizon values reproduce the Lean timing,
  delay exponent, dynamic-equivalence value equality, and arbitrary scaled
  horizon-two loss. This is computational correspondence, not a Lean proof or
  the missing raw T1 bridge.
- **Empirical relevance:** Not assessed.

### F6 — Total strategy-innovation value decomposition

- **Theorem ID:** F6
- **Manuscript label:** Supporting primitive-adapter insertion decomposition;
  superseded for final-model use by T5.
- **Informal statement:** The value created by inserting a strategy is exactly
  its frozen-library passive operational contribution plus its change in the
  option value of research. Frontier-preserving insertion has zero operational
  contribution. Under frontier--closure factorization, insertion preserving
  both components has zero total value. Under exact stochastic monotonicity of
  candidate transitions, antitone research costs, and unchanged frontier,
  insertion cannot reduce the research-option premium. An exact finite bridge
  example has operational innovation zero and generative innovation one.
- **Exact Lean assumptions:**
  1. F0 supplies finite admissible libraries, exact operational frontiers,
     insertion, generative closure, and closure monotonicity.
  2. F5 supplies the exact finite-state process, continue/research actions,
     finite-horizon full value, exact expectation, and cost-sensitive DI value
     preservation.
  3. `LibraryDynamics` maps every raw library to the finite process state and
     requires the process frontier at that image to equal the raw operational
     frontier.
  4. `passiveValue` freezes the raw library and recursively takes continue;
     `fullValue` evaluates F5 at the image. `researchOptionPremium` is their
     difference.
  5. `totalInnovation`, `operationalInnovation`, and
     `generativeInnovation` are the exact before/after-insertion differences
     specified in A-F6-DECOMP.
  6. The algebraic decomposition and frontier-preserving operational-zero
     theorem use no transition factorization or monotonicity assumption.
  7. `FactorsThroughFrontierClosure` requires equality of every project cost
     and transition distribution whenever raw frontier and closure agree. It
     is used for full-value sufficiency and zero total innovation.
  8. `CandidateGenerationMonotone` supplies a relation on finite process
     states. Raw-library inclusion maps into it; process frontiers are
     pointwise monotone; research costs are antitone; and each research kernel
     has weakly larger expectation for every rational continuation monotone in
     the relation.
  9. Premium monotonicity additionally assumes the inserted strategy leaves
     the operational frontier unchanged. Library insertion itself supplies
     weakly larger generative closure by F0.
  10. The exact example reuses the F4 singleton belief/project/module and
      three-strategy catalog with future reward `2`. Its new F5 process has
      zero cost, zero delay, discount `1/2`, and deterministic research that
      reaches the future library iff the bridge module is present.
- **Assumption reconciliation:** Items 1--10 are exactly A-F6-DECOMP on the
  F0 and F5 interfaces. Factorization is isolated to the D-style sufficiency
  theorem. Stochastic monotonicity is isolated to the E-style premium theorem.
  No declaration assumes or proves unconditional positivity of generative
  innovation.
- **Lean file:**
  `formal/StrategyInnovation/Value/Decomposition.lean`.
- **Proof audit file:**
  `formal/StrategyInnovation/Audit/Decomposition.lean`.
- **Definitions:** `StrategyInnovation.ValueDecomposition.LibraryDynamics`,
  `passiveValue`, `fullValue`, `researchOptionPremium`, `totalInnovation`,
  `operationalInnovation`, `generativeInnovation`,
  `FactorsThroughFrontierClosure`, `CandidateGenerationMonotone`, and
  `StateMonotone`.

| Lean declaration | Exact role | `#print axioms` result |
|---|---|---|
| `StrategyInnovation.ValueDecomposition.totalInnovation_eq_operational_add_generative` | exact accounting decomposition | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.ValueDecomposition.passiveValue_eq_of_frontier_eq` | passive value depends only on frozen frontier | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.ValueDecomposition.operationalInnovation_eq_zero_of_frontier_eq` | unchanged frontier gives zero operational innovation | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.ValueDecomposition.dynamicInnovationEquivalent_of_frontier_closure_eq` | factorized frontier/closure equality gives cost-sensitive DI | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.ValueDecomposition.fullValue_eq_of_frontier_closure_eq` | factorized frontier/closure equality preserves full value | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.ValueDecomposition.totalInnovation_eq_zero_of_frontier_closure_eq` | unchanged frontier and closure give zero total innovation | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.ValueDecomposition.finiteHorizonValue_state_mono` | optimized value is monotone under one-step assumptions | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.ValueDecomposition.fullValue_mono_of_library_inclusion` | library inclusion weakly raises full value | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.ValueDecomposition.researchOptionPremium_mono_of_candidateGenerationMonotone` | frontier-fixed insertion weakly raises research premium | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.ValueDecomposition.moduleInsertion_does_not_reduce_researchOptionPremium` | closure expansion and premium monotonicity pair | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.ValueDecomposition.ExactExample.operationalInnovation_zero_generativeInnovation_positive` | exact zero-operational/positive-generative bridge | `[propext, Classical.choice, Quot.sound]` |

- **Proof dependencies:** rational ring normalization for the unconditional
  identity; induction on passive horizon; F5 DI preservation; F0 closure
  monotonicity; exact expectation monotonicity; nonnegative discount powers;
  finite-action maximum monotonicity; and horizon induction under the declared
  state relation.
- **Exact example:** the inserted bridge preserves the zero frontier, changes
  closure from empty to the singleton key, and makes deterministic research
  reach a horizon-one frontier reward of two. Discount one half gives full
  value one, while both passive values are zero.
- **Difference from T5:** F6 uses the primitive F5 adapter and does not
  instantiate raw generation, admission, update, completion coupling, or
  A-TIMING. FG-0018 records this boundary. T5 separately proves the
  corresponding insertion results on the accepted raw process.
- **Sign boundary:** the exact example proves existence of positive
  generative innovation. The only general nondecrease theorem assumes the
  full one-step stochastic monotonicity and frontier condition above.
- **Julia test or experiment counterpart:** `julia/src/InnovationValue.jl`
  implements the exact passive/full/premium and three insertion-difference
  APIs over the compiled F5 process. Dedicated tests reproduce the Lean
  bridge value `(operational,generative)=(0,1)` and exact decomposition.
  Controlled family E separately checks operational-only, generative-only,
  and mixed pairs `(3,0)`, `(0,4)`, and `(3,1)`.
- **Manuscript location:** Mentioned only as supporting legacy accounting in
  Appendix C's formal boundary. The displayed T5 environments in Section 5
  map to `UnifiedDecomposition`, not this family.
- **Status:** Lean verified
- **Informal mathematical validity:** The main identity is exact algebra. The
  zero results follow from passive frontier invariance or cost-sensitive DI.
  Premium monotonicity is Bellman induction under explicit one-step order
  preservation.
- **Lean kernel verification:** Passed under Lean 4.32.0 and mathlib commit
  `81a5d257c8e410db227a6665ed08f64fea08e997`. Every principal theorem reports
  only `[propext, Classical.choice, Quot.sound]`; no user-declared assumption
  constant or placeholder appears.
- **Julia implementation validation:** The reusable exact API and the three
  controlled insertion cases reproduce the F6 accounting mechanism and
  channel isolation. They do not test the full stochastic-monotonicity theorem
  or prove unified T5.
- **Empirical relevance:** Not assessed.

### F7 — Supporting finite-horizon passive gap-sum identity

- **Theorem ID:** F7
- **Manuscript label:** Supporting primitive-adapter passive operational
  insertion equation; not unified T5 or T6.
- **Informal statement:** For a fixed candidate, its passive operational
  insertion value over (n) periods equals the exact discounted expected sum
  of its positive frontier gap along the finite belief Markov chain. The value
  is zero when every positive-probability belief reachable before the horizon
  has zero gap, and it weakly decreases as the comparison library expands. A
  two-belief example has zero gap now but strictly positive passive value from
  a future reachable gap.
- **Exact Lean assumptions:**
  1. F0 supplies the exact rational profile table, inactive-containing finite
     libraries, insertion, attained operational frontier, and frontier
     monotonicity.
  2. F5 supplies exact finite-support rational belief kernels, exact
     expectation, rational discount with $0\le\beta<1$, and expectation
     monotonicity.
  3. F6 supplies `LibraryDynamics` and `passiveValue`; passive evolution holds
     the raw library fixed and uses the process's common belief kernel.
  4. `frontierGap` is exactly
     $\max\{j_s(b)-F_L(b),0\}$.
  5. `discountedGapSum` is the finite recursion
     $G_0=0$ and
     $G_{n+1}(b)=\Delta_{s,L}(b)+\beta E_b[G_n(B')]$.
  6. `BeliefReachableIn` uses a path of exactly the stated length and requires
     nonzero exact rational transition mass at every step.
  7. The zero criterion assumes the gap is zero at every state reachable in
     every exact time (t<n). It makes no converse claim.
  8. Diminishing marginal value compares two libraries under the same
     `LibraryDynamics`; it uses only library inclusion and nonnegative
     discount.
  9. The exact example uses two beliefs, deterministic current-to-future
     transition, a zero inactive frontier, candidate payoffs zero and two,
     discount (1/2), and horizon two.
- **Assumption reconciliation:** Items 1--9 are exactly
  A-F7-INNOVATION-EQUATION on the F0/F5/F6 interfaces. No project-generation,
  verification, admission, cost, module-closure, or research-transition
  assumption enters the equation.
- **Lean file:**
  `formal/StrategyInnovation/Value/InnovationEquation.lean`.
- **Proof audit file:**
  `formal/StrategyInnovation/Audit/InnovationEquation.lean`.
- **Definitions:** `StrategyInnovation.InnovationEquation.frontierGap`,
  `discountedGapSum`, `passiveOperationalInnovation`, and
  `BeliefReachableIn`.

| Lean declaration | Exact role | `#print axioms` result |
|---|---|---|
| `StrategyInnovation.InnovationEquation.operationalFrontier_insert_sub_eq_frontierGap` | one-step frontier identity | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.InnovationEquation.passiveValue_succ` | exact passive-value recursion | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.InnovationEquation.passiveOperationalInnovation_succ` | one-step operational-innovation recursion | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.InnovationEquation.passiveOperationalInnovation_eq_discountedGapSum` | supporting primitive-adapter passive gap-sum identity | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.InnovationEquation.discountedGapSum_eq_zero_of_gap_eq_zero_on_reachable` | generic reachable-support zero lemma | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.InnovationEquation.passiveOperationalInnovation_eq_zero_of_gap_eq_zero_on_reachable` | operational zero-value criterion | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.InnovationEquation.passiveOperationalInnovation_antitone_of_library_inclusion` | diminishing marginal operational innovation | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.InnovationEquation.DelayedBenefitExample.zero_currentGap_positive_passiveOperationalInnovation` | exact zero-now/positive-future example | `[propext, Classical.choice, Quot.sound]` |

- **Proof dependencies:** finite maximum characterization, rational linear
  order, exact expectation linearity and monotonicity, induction on the finite
  horizon, exact-support reachability composition, and nonnegative discount.
- **Exact example:** the candidate ties at the current belief, then a
  deterministic transition reaches a belief with gap two. Thus horizon-two
  value is $0+(1/2)\cdot2=1>0$.
- **Difference from intended T5/T6:** F7 proves the passive operational
  component for one already-specified candidate. It does not optimize over
  research actions, expose project costs, derive admitted-candidate
  probabilities, establish premium nonnegativity, or prove current T6's
  retained-carrier descendant bound. It is also stated on
  `ValueDecomposition.LibraryDynamics`; no named theorem currently identifies
  that passive recursion with unified T5's raw passive value. FG-0019 records
  the scope boundary and FG-0028 records the missing optional bridge.
- **Infinite-horizon boundary:** F7 declares no geometric series, contraction,
  stationary value, or limit theorem. Supporting F8's primitive-state value
  limit is separate, and the verified finite gap equation does not depend on
  it.
- **Julia test or experiment counterpart:** `frontier_gap`,
  `discounted_gap_sum`, `passive_operational_innovation`, and the exact finite
  `discounted_belief_occupancy` expansion are implemented in
  `julia/src/InnovationValue.jl`. Dedicated tests reproduce the two-belief
  zero-current-gap value one and the exact F7 adapter gap-sum identity. The
  deterministic `strategy-value-equation-figure-v1` fixture verifies the same
  identity before generating its data table and manuscript plot.
- **Manuscript location:** Appendix C at `def:frontier-gap-sum`,
  `thm:passive-innovation-equation`,
  `cor:zero-current-gap-positive-future-value`, and
  `prop:diminishing-operational-innovation`; the passive-only boundary is
  explicit.
- **Status:** Lean verified
- **Informal mathematical validity:** The equation is finite telescoping of
  two passive recursions plus the pointwise max identity. Reachable-support
  vanishing and diminishing marginal value follow by finite induction.
- **Lean kernel verification:** Passed under Lean 4.32.0 and mathlib commit
  `81a5d257c8e410db227a6665ed08f64fea08e997`. Every principal theorem reports
  only `[propext, Classical.choice, Quot.sound]`; no user-declared assumption
  constant or placeholder appears.
- **Julia implementation validation:** Not separately assessed.
- **Empirical relevance:** Not assessed.

### F8 — Discounted primitive finite-state Bellman contraction

- **Theorem ID:** F8
- **Manuscript label:** Discounted finite-state Bellman contraction; supporting
  theorem, not Candidate Theorem T1 or the full Candidate S2.
- **Informal statement:** For the primitive finite compressed-state process of
  F5, the real-valued Bellman operator on the finite
  belief--compressed-state product is a sup-norm contraction with modulus
  $\beta$. It has a unique fixed point; value iteration converges uniformly
  from every initial table with a geometric error bound; the exact rational
  finite-horizon values, cast to reals, converge to that fixed point; and
  cost-sensitive dynamically innovation-equivalent compressed states have
  equal fixed-point value.
- **Exact Lean assumptions:**
  1. F5 supplies nonempty finite belief, compressed-state, and project types,
     exact rational frontier/cost tables, normalized rational belief and
     research kernels, finite project delays, and $0\le\beta<1$.
  2. The state is exactly the product of the model's belief type and the
     process's compressed-state type. Every real function on this finite type
     is used as a value table; mathlib supplies its finite-product sup norm and
     complete-space instance.
  3. Exact rational probabilities, rewards, costs, and discount are cast to
     $\mathbb R$ inside the infinite-horizon operators. No floating-point
     value or approximate probability is introduced.
  4. Continue earns the current frontier and has continuation coefficient
     $\beta$. Research pays its current cost and has coefficient
     $\beta^{d(q)+1}$. Belief and compressed-state draws use the same nested
     exact expectations as F5.
  5. The Bellman operator is the genuine finite maximum over continue and
     every research project.
  6. F5 dynamic innovation equivalence requires equality of current
     frontiers, every current project cost, and every exact primitive
     research-transition distribution. The belief kernel and discount are
     common process data.
- **Assumption reconciliation:** Items 1--6 are exactly A-F8-CONTRACTION on
  the A-FH-VALUE/F5 interface. Finite-state boundedness is proved from the sup
  norm, not assumed separately. Strict discount constructs the contraction;
  delay gives a smaller coefficient because
  $\beta^{d+1}\le\beta$. Completeness is the reason the value codomain is
  real even though all process data and finite-horizon values remain rational.
- **Lean file:**
  formal/StrategyInnovation/Bellman/Contraction.lean.
- **Proof audit file:**
  formal/StrategyInnovation/Audit/Contraction.lean.
- **Definitions:** StrategyInnovation.BellmanContraction.State,
  RealValueFunction, realExpectedValue, continueOperator, researchOperator,
  actionOperator, bellmanOperator, infiniteHorizonValue, valueIteration,
  realFiniteHorizonValue, and rationalValueToReal.

| Lean declaration | Exact role | #print axioms result |
|---|---|---|
| StrategyInnovation.BellmanContraction.realValueFunction_bounded | every real table is bounded by its finite-state sup norm | [propext, Classical.choice, Quot.sound] |
| StrategyInnovation.BellmanContraction.actionOperator_lipschitz | every continue/research action is globally $\beta$-Lipschitz | [propext, Classical.choice, Quot.sound] |
| StrategyInnovation.BellmanContraction.bellmanOperator_lipschitz | finite maximum preserves the common sup-norm bound | [propext, Classical.choice, Quot.sound] |
| StrategyInnovation.BellmanContraction.bellmanOperator_contracting | Bellman is a contraction with modulus $\beta<1$ | [propext, Classical.choice, Quot.sound] |
| StrategyInnovation.BellmanContraction.infiniteHorizonValue_isFixedPoint | declared infinite-horizon value satisfies Bellman | [propext, Classical.choice, Quot.sound] |
| StrategyInnovation.BellmanContraction.exists_bellman_fixedPoint | fixed-point existence | [propext, Classical.choice, Quot.sound] |
| StrategyInnovation.BellmanContraction.bellman_fixedPoint_unique | fixed-point uniqueness | [propext, Classical.choice, Quot.sound] |
| StrategyInnovation.BellmanContraction.valueIteration_tendsto_infiniteHorizonValue | uniform convergence from arbitrary real initialization | [propext, Classical.choice, Quot.sound] |
| StrategyInnovation.BellmanContraction.valueIteration_geometric_error_bound | Banach a priori geometric sup-norm estimate | [propext, Classical.choice, Quot.sound] |
| StrategyInnovation.BellmanContraction.realFiniteHorizonValue_eq_valueIteration_zero | real finite-horizon recursion is Bellman iteration from zero | [propext, Classical.choice, Quot.sound] |
| StrategyInnovation.BellmanContraction.realFiniteHorizonValue_eq_ratCast | real recursion equals the cast exact rational recursion | [propext, Classical.choice, Quot.sound] |
| StrategyInnovation.BellmanContraction.rationalFiniteHorizonValue_ratCast_tendsto_infiniteHorizonValue | cast exact horizon tables converge uniformly | [propext, Classical.choice, Quot.sound] |
| StrategyInnovation.BellmanContraction.rationalFiniteHorizonValue_ratCast_geometric_error_bound | geometric bound for cast exact horizon tables | [propext, Classical.choice, Quot.sound] |
| StrategyInnovation.BellmanContraction.finiteHorizonValue_ratCast_tendsto_infiniteHorizonValue | pointwise convergence at each belief and state | [propext, Classical.choice, Quot.sound] |
| StrategyInnovation.BellmanContraction.infiniteHorizonValue_eq_of_dynamicInnovationEquivalent | DI-equivalent states have equal fixed-point value | [propext, Classical.choice, Quot.sound] |

- **Proof dependencies:** finite-support real expectation bounds; evaluation
  bounded by the finite-product sup norm; $\beta^{d+1}\le\beta$; a direct
  two-sided proof that finite maxima preserve a uniform distance bound; and
  mathlib's contraction fixed-point, convergence, uniqueness, and
  geometric-estimate theorems. The rational/real bridge is proved by
  finite-sum casts, finite-max casts, and horizon induction.
- **Difference from intended T1/S2:** F8's compressed-state transition is
  primitive and uses F5's action-specific timing, so it does not prove the
  accepted raw-to-compressed simulation or infinite-horizon T1 factorization.
  The later unified S2 module supplies the raw bridge, derived contractions,
  stationary selector, and policy evaluation. F8 remains a verified
  compatibility theorem rather than the publication-facing Bellman result.
- **Julia test or experiment counterpart:**
  `value_iteration`, `bellman_residual`, `contraction_error_bound`, and
  `residual_error_bound` implement guarded sup-norm iteration and both
  a-priori and residual-based diagnostics. Float64 transition matrices are
  sparse. The deprecated
  `julia/scripts/solve_canonical_model.jl` remains the exact/Float64
  regression counterpart for primitive F5/F8 timing only.
- **Manuscript location:** Section 6 states the unified S2 result. The
  primitive F5/F8 six-state process is no longer a main-text benchmark;
  Appendix D's “Legacy regression fixture” gives its exact values and points
  to the unchanged regression artifacts.
- **Status:** Lean verified
- **Informal mathematical validity:** Standard finite discounted-MDP
  contraction argument, with the research-delay coefficient explicitly
  bounded by the one-period discount.
- **Lean kernel verification:** Passed under Lean 4.32.0 and mathlib commit
  81a5d257c8e410db227a6665ed08f64fea08e997. Every principal theorem reports
  only [propext, Classical.choice, Quot.sound]; no user-declared axiom or
  placeholder appears.
- **Julia implementation validation:** Numerical contraction, decreasing
  increments, Bellman residuals, β close to one, maximum-iteration failure,
  and DI fixed-point equality are tested. Exact policy iteration has zero
  residual on the legacy compatibility instance. The unified publication
  benchmark and selector validation are recorded separately under S2 and N1.
  Float64 output remains numerical evidence only. Controlled family G's
  twelve seeded 61-belief maps are preserved as compatibility regressions.
  The active policy-map diagnostic is confined to Appendix E; it selects cost,
  positive-duration, and discount slices from the raw-derived unified
  comparative-static surface after checking its sparse convergence, residual,
  and posterior-bound gates.
- **Empirical relevance:** Not assessed.

## Primary theorem family

### T1 — Raw-to-compressed controlled Markov projection

- **Theorem ID:** T1
- **Manuscript label:** `thm:raw-to-compressed-projection`
- **Informal statement:** In the unified semi-Markov raw model, admitted
  outcomes update $K_L=(F_L,C_L)$ locally; the induced joint
  terminal-belief/compressed-state law is a controlled Markov projection; and
  every finite calendar-horizon optimal value factors through $(b,K_L)$.
- **Finite target statement:** Use the raw generator $G$, verification rule
  $\nu$, derived admitted law $\Gamma$, and declared joint
  belief-path/outcome coupling $\Lambda_q$. Prove RC1--RC3 and, for every
  calendar horizon,
  belief, and admissible library,
  $$
    V_h^{\mathrm{raw}}(b,L)=\bar V_h(b,K_L),
    \qquad
    K_{L\oplus o}=\operatorname{addK}(K_L,o).
  $$
  The controlled-Markov statement is for embedded decision epochs. A
  calendar-time theorem with multi-period projects must include the
  in-progress project state.
- **Exact assumptions:** A-FIN, A-RATPROB, A-BELIEF-GRID, A-STRATEGY,
  A-PROFILE, A-LIBRARY, A-CLOSURE, A-FRONTIER, A-GEN-FACTOR, A-VERIFY,
  A-COST, A-TIMING, A-DISCOUNT, A-HORIZON.
- **Lean binder reconciliation:** `FiniteModel` supplies the finite nonempty
  belief/strategy/module/project carriers; `Raw.StrategyCatalog`, raw
  libraries, and `Raw.ClosureOperator` encode the immutable profile/module
  rows, inactive-containing sets, and closure laws; `Model.generation` and
  `Model.admission` supply the exact raw inputs; `Model.completion` has
  explicit Markov-path and admitted-law marginals; availability, cost,
  operation, positive duration, and rational discount are displayed fields.
  The finite-horizon declarations use zero terminal payoff. The
  hidden-state-to-profile expectation adapter in the full wording of
  A-BELIEF-GRID/A-PROFILE is not encoded and is not claimed by T1. The
  compatibility API packages raw and compressed `ContractingWith`
  certificates as fields; `Bellman/Unified.lean` now derives the canonical
  certificates directly from these finite T1 data.
- **Excluded stronger claim:** Generic quotient minimality, implicit
  belief/outcome independence, and unaugmented calendar-time Markovity during
  multi-period research are not T1 targets.
- **Lean declarations:**
  `StrategyInnovation.Projection.Model.inducedCompressedTransition_wellDefined`;
  `StrategyInnovation.Projection.Model.same_compressedState_same_next_probability`;
  `StrategyInnovation.Projection.Model.projectedProcess_controlledMarkov`;
  `StrategyInnovation.Projection.Model.rawValue_eq_compressedValue`;
  `StrategyInnovation.Projection.Model.rawInfiniteHorizonValue_eq_compressed`;
  `StrategyInnovation.Projection.Model.liftedRawStationarySelector_policyEvaluationEquation`.
- **Lean file:**
  `formal/StrategyInnovation/Projection/RawToCompressed.lean` and
  `formal/StrategyInnovation/Bellman/Unified.lean`.
- **Proof dependencies:** finite rational kernels; closure absorption;
  frontier and closure outcome-update lemmas; normalization of the derived
  admitted law; joint-coupling pushforward; embedded semi-Markov projection;
  raw and compressed calendar-horizon recursions; strong induction on the
  horizon for positive durations.
- **`#print axioms` result:** Every principal T1 declaration reports exactly
  `[propext, Classical.choice, Quot.sound]`; no user-declared axiom occurs.
- **Julia test or experiment counterpart:**
  `julia/scripts/search_revision_counterexamples.jl`; 512 exact semi-Markov
  models gave 20,462 local-update checks, 10,869 raw/compressed joint-law
  comparisons, and 39,060 raw/compressed calendar-value equalities without
  failure. FX-T1-CORRELATED-01 has dependent terminal belief and admission:
  the joint value is $1/4$, the product-law value would be $1/8$, and the
  raw/compressed projection still agrees.
- **Manuscript location:** Section 3,
  `thm:raw-to-compressed-projection`, with the exact finite calendar timing,
  correlated-coupling boundary, derived contraction, and selector lift.
- **Status:** Lean verified and numerically validated
- **Falsification classification:** the revised finite target is internally
  consistent under the listed raw-input and coupling restrictions. Generic
  minimality is false by CX-T1-MIN-T2-SILENT-01; sufficiency without the raw
  generator restriction is false by CX-T1-RAW-01; a
  provenance-dependent joint coupling is an additional direct failure mode.
- **Informal mathematical validity:** manuscript Section 3 and Appendix A give
  the matching finite update, transition pushforward, embedded
  controlled-Markov, and strong calendar-horizon arguments.
- **Lean kernel verification:** The realizable compressed carrier is finite;
  the induced law is a deterministic pushforward of the R0 admitted law; the
  representative-invariance and embedded controlled semi-Markov theorems
  substitute RC1 pointwise; finite value equality is strong induction on
  positive calendar duration; stationary Bellman intertwining plus the
  derived raw and compressed contractions gives fixed-point equality; and
  finite maximizer attainment plus fixed-policy contraction gives the raw
  policy-evaluation equation. The focused and comprehensive audits name every
  principal declaration.
- **Julia implementation validation:** The reusable
  `RawInnovationProcess` and the independent exact oracle validate derived
  admission, positive durations, active and suspending operation, initiation
  cost, the full belief clock, non-product completion coupling, raw-derived
  compressed transition pushforwards, and raw/compressed finite
  calendar-horizon values and policies. The correlated fixture retains value
  $1/4$, and the complete generated exact-fixture bridge remains byte-stable.
- **Empirical relevance:** Not assessed.

### T2 — Frontier–closure characterization

- **Theorem ID:** T2
- **Manuscript label:** Raw frontier--closure characterization (T2),
  theorem label thm:raw-frontier-closure-characterization.
- **Informal statement:** Under observable raw closure detectability, final
  cost-sensitive dynamic innovation equivalence is exactly equality of the
  operational frontier and generative closure, hence equality of $K$.
- **Finite Lean statement:**
  $$
    L\sim_{\mathrm{DI}}L'
    \iff
    (F_L=F_{L'}\land C_L=C_{L'})
    \iff
    K_L=K_{L'}.
  $$
- **Exact assumptions:** T1/UDI's finite exact raw Projection.Model. Its field
  types force generation and primitive admission to depend only on project,
  belief, and closure; availability, cost, and completion coupling depend only
  on the realizable compressed state; and operating rewards use the frontier.
  The converse assumes A-T2-OBS/RawClosureDetectable. A latent candidate or
  admission inequality is a detection witness only when it also changes the
  availability-tagged projected joint next-belief/next-compressed-state law.
  Conditional independence is not assumed.
- **Excluded stronger claim:** No generic coarsest-bisimulation or minimal
  quotient claim. Full abstraction under all continuation contexts remains an
  extension.
- **Lean declarations:**
  StrategyInnovation.Projection.Model.rawCandidateLaw_eq_of_generativeClosure_eq;
  StrategyInnovation.Projection.Model.rawAdmissionProbability_eq_of_generativeClosure_eq;
  StrategyInnovation.Projection.Model.rawAdmittedLaw_eq_of_generativeClosure_eq;
  StrategyInnovation.Projection.Model.compressedLibraryState_eq_of_frontierClosure_eq;
  StrategyInnovation.Projection.Model.rawNextCompressedTransition_eq_of_frontierClosure_eq;
  StrategyInnovation.Projection.Model.RawClosureDetectionWitness;
  StrategyInnovation.Projection.Model.RawClosureDetectable;
  StrategyInnovation.Projection.Model.frontierClosure_eq_implies_rawLaws_and_dynamicEquivalence;
  StrategyInnovation.Projection.Model.frontierClosure_eq_implies_dynamicInnovationEquivalent;
  StrategyInnovation.Projection.Model.dynamicInnovationEquivalent_implies_frontierClosure_eq;
  StrategyInnovation.Projection.Model.dynamicInnovationEquivalent_iff_frontierClosure_eq;
  StrategyInnovation.Projection.Model.dynamicInnovationEquivalent_iff_compressedLibraryState_eq;
  StrategyInnovation.Projection.Model.RawFrontierClosureCounterexamples.sufficiency_fails_when_generator_uses_raw_identifiers;
  StrategyInnovation.Projection.Model.RawFrontierClosureCounterexamples.rawIdentifierGenerator_not_factorized;
  StrategyInnovation.Projection.Model.RawFrontierClosureCounterexamples.converse_fails_when_closure_behaviorally_invisible;
  StrategyInnovation.Projection.Model.RawFrontierClosureCounterexamples.silentProcess_not_rawClosureDetectable.
- **Lean file:**
  formal/StrategyInnovation/Quotient/RawFrontierClosure.lean.
- **Proof dependencies:** raw generation and primitive-admission input
  restrictions; derived admitted law; RC1; T1 pushforward and
  compression-fiber invariance; availability-tagged UDI observations;
  function/structure extensionality; raw closure detectability.
- **`#print axioms` result:** All 16 principal T2 declarations report exactly
  `[propext, Classical.choice, Quot.sound]`; no user-declared axiom occurs.
- **Julia test or experiment counterpart:**
  `julia/scripts/search_revision_counterexamples.jl`; 473 of 512 randomized
  semi-Markov models satisfied A-T2-OBS and gave 21,848 full signature
  comparisons without failure. The signature includes availability, cost,
  duration, operation flag, and joint completion law. A separate silent-module
  fixture falsifies the converse when A-T2-OBS is removed.
- **Manuscript location:** Section 4,
  thm:raw-frontier-closure-characterization, with both assumption-boundary
  counterexamples in Appendix C. Exact declaration names are confined to the
  online supplement.
- **Status:** Lean verified and numerically validated
- **Falsification classification:** survives within the searched bounds; the
  observability assumption remains essential.
- **Informal mathematical validity:** The forward direction derives equality
  of raw candidate laws, primitive admission probabilities, admitted laws, and
  T1-projected raw transitions from frontier--closure equality. The converse
  eliminates each possible raw detectability witness using the corresponding
  UDI equality.
- **Lean kernel verification:** The focused T2 audit and comprehensive audit
  pass. Both exact counterexamples are kernel checked.
- **Julia implementation validation:** The exact revision oracle represents
  and compares the full joint completion signature; the silent-module fixture
  remains a regression for the excluded converse.
- **Empirical relevance:** Not assessed.

### T3 — Innovation-safe deletion criterion

- **Theorem ID:** T3
- **Manuscript label:** Unified innovation-safe deletion
- **Informal statement:** For one noninactive raw-library deletion,
  operational redundancy $F_{L^{-s}}=F_L$ and generative redundancy
  $C_{L^{-s}}=C_L$ are exactly preservation of the realizable compressed
  state. T1 then preserves unified process observations, every finite-horizon
  raw value, contraction fixed-point value, pairwise stationary action-value
  comparisons, and optimal actions. Under raw closure detectability, unified
  observation preservation (and hence the formal innovation-safety
  certificate) implies both redundancy equalities.
- **Exact formal statement:**
  1. `RedundantDeletion` is the conjunction of the two equality-after-erasure
     predicates.
  2. `RedundantDeletion ... ↔
     compressedLibraryState ... L⁻ = compressedLibraryState ... L`.
  3. The conjunction constructs `InnovationSafeDeletion`, whose fields are
     unified dynamic innovation equivalence of $L^{-s}$ and $L$, and raw
     value equality for every natural horizon and belief.
  4. A `DiscountedContractionModel` gives fixed-point value equality,
     preservation of every pairwise `fixedPointActionValue` comparison, and
     equivalence of `IsOptimalFixedPointAction`.
  5. `RawClosureDetectable process` gives
     `DynamicInnovationEquivalent process L⁻ L ↔ RedundantDeletion ...` and
     `InnovationSafeDeletion process ... ↔ RedundantDeletion ...`.
  6. `RedundantDeletionSequence` rechecks both equalities at every
     intermediate library; its endpoint is a sublibrary with the same
     compressed state, dynamic class, finite values, and contraction value.
  7. `PruningAlgorithmSpec` returns a pruning output and a valid rechecked
     trace; every trace step receives an innovation-safety certificate.
- **Exact assumptions:** A-STRATEGY, A-PROFILE, A-LIBRARY, A-CLOSURE,
  A-FRONTIER, A-T3-DELETE, and the T1 raw projection assumptions. The
  observable converse additionally requires A-T2-OBS. Infinite-horizon and
  stationary action statements additionally require the declared
  `DiscountedContractionModel`.
- **Excluded stronger claims:** Value equality alone does not identify
  generative redundancy. Redundancy certificates checked only in the original
  library cannot be reused as simultaneous or unrechecked batch certificates.
  A valid rechecked trace does not by itself assert that its endpoint is
  terminal or inclusion-wise irreducible, and T3 contains no resource or
  global-optimality conclusion.
- **Lean declaration names:**
  `StrategyInnovation.Projection.Model.redundantDeletion_iff_compressedLibraryState_eq`;
  `StrategyInnovation.Projection.Model.redundantDeletion_innovationSafe`;
  `StrategyInnovation.Projection.Model.DiscountedContractionModel.redundantDeletion_preserves_infiniteHorizonValue`;
  `StrategyInnovation.Projection.Model.DiscountedContractionModel.redundantDeletion_preserves_actionValueComparison`;
  `StrategyInnovation.Projection.Model.DiscountedContractionModel.redundantDeletion_preserves_optimalAction`;
  `StrategyInnovation.Projection.Model.deletionProcessObservations_iff_redundant`;
  `StrategyInnovation.Projection.Model.innovationSafeDeletion_iff_redundant`;
  `StrategyInnovation.Projection.Model.RedundantDeletionSequence.dynamicInnovationEquivalent`;
  `StrategyInnovation.Projection.Model.PruningAlgorithmSpec.everyDeletion_safe`.
- **Lean files:**
  `formal/StrategyInnovation/Compression/UnifiedSafeDeletion.lean`;
  `formal/StrategyInnovation/Compression/UnifiedSafeDeletionExamples.lean`.
- **Proof dependencies:** raw compressed-state structure extensionality; T1
  finite/infinite raw-to-compressed value identities; unified dynamic
  innovation sufficiency; T2 raw closure detectability for the converse.
- **`#print axioms` result:** Every publication-facing declaration is printed
  by `StrategyInnovation/Audit/UnifiedSafeDeletion.lean` and the comprehensive
  audit. The proof footprint is
  `[propext, Classical.choice, Quot.sound]`; no `sorry`, `admit`,
  user-declared axiom, or unsafe proof primitive occurs.
- **Julia test or experiment counterpart:**
  `julia/scripts/search_counterexamples.jl`; 361,584 exhaustive configurations
  gave 1,413,936 successful single-deletion equivalence checks, and the
  randomized run added 43,718 checks.
- **Exact Lean examples:** a universally safely deletable duplicate, an
  operationally redundant/generatively essential carrier, a generatively
  redundant/operationally essential strategy, raw-distinct duplicate
  encodings with equal compressed states, and a stale-certificate double
  deletion that changes the compressed state.
- **Manuscript location:** Theorem
  `thm:unified-safe-deletion`, Corollary
  `cor:stepwise-safe-compression`, Proposition
  `prop:certified-pruning`, Example `ex:t3-deletion-classes`, and the worked
  bridge library and pruning-path diagram in Section 4.
- **Status:** Lean verified and numerically validated
- **Falsification classification:** survives as stated. The detectability
  hypothesis is essential to the observation-level converse, and the
  rechecking requirement is essential to sequential safety.
- **Informal mathematical validity:** The algebraic state identity is
  componentwise. All value and action consequences factor through the T1
  projection. T2 supplies exactly the conditional observable converse.
- **Lean kernel verification:** Focused and comprehensive audits pass.
- **Julia implementation validation:** Exact exhaustive and randomized checks
  passed; batch failure remains a permanent regression fixture. The separate
  fixed-point routine tests that no safe active single deletion remains, but
  it has no resource table or global minimum-weight validation.
- **Empirical relevance:** Not assessed.

### T4 — Sharp normalized frontier-only pruning loss

- **Theorem ID:** T4
- **Manuscript label:** Sharp normalized frontier-only pruning loss
- **Informal statement:** In the canonical finite raw construction, an
  operationally dominated bridge uniquely carries the module required for one
  descendant after delay $d$. The raw generator assigns survival-gated mass
  $\rho^d$, the primitive admission row accepts the descendant with
  probability $\pi$, and pruning makes the descendant mass zero. With
  descendant reward capped at $C$, discount $\beta$, and initiation cost
  difference $\kappa-0$, exact pruning loss is
  $$
    \beta^d\rho^d\pi C-\kappa
  $$
  whenever the net research opportunity is nonnegative.
- **Exact assumptions:** `Parameters` requires $d\ge1$,
  $0\le\beta<1$, $0\le\rho\le1$, $0\le\pi\le1$, $C\ge0$,
  $\kappa\ge0$, and
  $\kappa\le\beta^d\rho^d\pi C$. The exact finite bridge catalog has
  singleton belief/module/project types, zero inactive and bridge profiles,
  one cap-$C$ descendant, identity closure, and the bridge as unique module
  carrier. Candidate generation and admission are explicit raw definitions.
- **Exact value convention:** `canonicalUnprunedValue` is the one-project
  Bellman envelope between zero-valued Continue and initiation cost plus the
  expectation under `Raw.admittedCandidateDistribution`.
  `canonicalPrunedValue` uses the pruned raw law and is zero. The terminal
  descendant payoff is discounted by $\beta^d$, matching T1 timing.
- **Sharpness and normalization:** For fixed
  $(\beta,\rho,\pi,d,\kappa)$, every reward $R\in[0,C]$ has loss bounded
  by the cap formula, and $R=C$ attains it. If the net opportunity is
  positive, loss divided by maximum attainable net descendant value is one.
  If $C\le1$, loss is at most one, so the primary theorem uses no unbounded
  reward.
- **Operation during research:** Continued operation adds the exact difference
  of incumbent operating-reward blocks. Under operational redundancy and a
  common belief-path law that difference is zero, so the formula is unchanged.
- **Scaling boundary:** For target $M\ge0$, the secondary corollary chooses
  $d=1,\beta=1/2,\rho=\pi=1,\kappa=0,C=2M$, giving exact loss $M$.
  Arbitrary additive loss is therefore reward scaling, not a normalized
  conclusion.
- **Lean declarations:**
  `StrategyInnovation.Projection.Model.NormalizedPruningLoss.canonicalConstruction_certificate`;
  `StrategyInnovation.Projection.Model.NormalizedPruningLoss.canonicalPruningLoss_exact`;
  `StrategyInnovation.Projection.Model.NormalizedPruningLoss.rewardCap_sharp`;
  `StrategyInnovation.Projection.Model.NormalizedPruningLoss.destroys_all_attainable_descendant_value`;
  `StrategyInnovation.Projection.Model.NormalizedPruningLoss.unitRewardCap_loss_le_one`;
  `StrategyInnovation.Projection.Model.NormalizedPruningLoss.arbitraryLoss_by_rewardScaling`;
  `StrategyInnovation.Projection.Model.NormalizedPruningLoss.canonicalPruningLossWithOperation_exact`;
  `StrategyInnovation.Projection.Model.NormalizedPruningLoss.continuedOperation_cancels_under_operationalRedundancy`.
- **Lean file:**
  `formal/StrategyInnovation/Compression/NormalizedPruningLoss.lean`.
- **Proof audit file:**
  `formal/StrategyInnovation/Audit/NormalizedPruningLoss.lean`.
- **Proof dependencies:** exact raw generation, primitive admission, derived
  admitted-candidate mass, rational expectation of a point-supported payoff,
  unified $\beta^d$ terminal timing, finite frontier/closure bridge facts,
  and exact ordered-field algebra.
- **`#print axioms` result:** Every publication-facing T4 declaration reports
  exactly `[propext, Classical.choice, Quot.sound]`; no user-declared axiom or
  placeholder occurs.
- **Julia test or experiment counterpart:** Existing exact F4 and
  FX-T4-UNIFIED-01 fixtures cover the deterministic specialization
  $d=1,\rho=\pi=1,\kappa=0$. No Julia source changed in this proof run.
- **Manuscript location:** Theorem
  `thm:normalized-frontier-pruning-loss`; scaling Corollary
  `thm:scaled-frontier-pruning-loss`; the deterministic
  $(d,\beta,\rho,\pi,\kappa,C)=(1,1/2,1,1,0,4)$ specialization is the worked
  bridge library in Section 4.
- **Status:** Lean verified and numerically validated in the deterministic
  specialization
- **Falsification classification:** exact normalized formula and cap bound;
  unrestricted normalized arbitrary loss is superseded.
- **Informal mathematical validity:** Raw descendant mass is
  $\rho^d\pi$. Unified discount and cost accounting give the displayed
  Bellman envelope. Monotonicity in the capped reward gives sharpness.
- **Lean kernel verification:** Focused and comprehensive audits pass with
  only the standard foundations listed above.
- **Julia implementation validation:** Existing exact parameterized
  regressions agree in their deterministic specialization.
- **Empirical relevance:** Not assessed.

### T5 — Unified operational--generative decomposition

- **Theorem ID:** T5
- **Manuscript label:** Unified operational--generative decomposition,
  `thm:value-decomposition`.
- **Informal statement:** Full value uses the accepted T1 raw process with
  research; passive value freezes the raw library and forbids research. The
  total full-value effect of inserting one strategy is exactly its passive
  operational effect plus the insertion-induced change in the research-option
  premium.
- **Finite target statement:** For every exact finite T1 process, horizon
  $h$, belief $b$, raw library $L$, and catalog strategy $s$, define
  $$
    \Omega_h=U_h-P_h,\quad
    \mathcal I_h=U_h(L\cup\{s\})-U_h(L),\quad
    \Delta_h^{\rm op}=P_h(L\cup\{s\})-P_h(L),
  $$
  and
  $\Delta_h^{\rm gen}=\Omega_h(L\cup\{s\})-\Omega_h(L)$.
  Then
  $\mathcal I_h=\Delta_h^{\rm op}+\Delta_h^{\rm gen}$.
  Frontier-silent insertion gives $\Delta_h^{\rm op}=0$;
  frontier-and-closure-silent insertion gives $\mathcal I_h=0$; library
  inclusion weakly lowers a fixed candidate's operational insertion value.
  Under A-T5-PROJECT-DOMINANCE, closure enrichment cannot lower $\Omega_h$.
- **Exact assumptions:** T1 assumptions and A-T5-BASELINE. Premium
  monotonicity additionally assumes A-T5-PROJECT-DOMINANCE. The bridge witness
  specializes to one belief, duration one, $\beta=1/2$, zero cost, suspended
  operation, a closure-indexed raw generator, and unit primitive admission.
- **Excluded stronger claims:** No unconditional sign is assigned to
  generative insertion value. Closure inclusion alone is not claimed to raise
  the premium, and the premium is not claimed to depend only on closure.
- **Lean declarations:**
  `StrategyInnovation.Projection.Model.UnifiedDecomposition.compressedPassiveValue`;
  `passiveValue`; `passiveValue_eq_compressedPassiveValue`; `fullValue`;
  `compressedFullValue`; `fullValue_eq_compressedFullValue`;
  `researchOptionPremium`; `totalInsertionValue`;
  `operationalInsertionValue`; `generativeInsertionValue`;
  `totalInsertionValue_eq_operational_add_generative`;
  `passiveValue_eq_of_frontier_eq`;
  `operationalInsertionValue_eq_zero_of_frontier_eq`;
  `totalInsertionValue_eq_zero_of_frontier_closure_eq`;
  `operationalInsertionValue_antitone_of_library_inclusion`;
  `ClosureEnrichmentProjectDominance`;
  `compressedValue_mono_of_closureEnrichmentProjectDominance`;
  `fullValue_mono_of_closureEnrichmentProjectDominance`;
  `researchOptionPremium_mono_of_closureEnrichmentProjectDominance`; and
  `BridgeExample.bridge_operational_zero_generative_positive`.
- **Lean file:**
  `formal/StrategyInnovation/Value/UnifiedDecomposition.lean`.
- **Migration:** `formal/StrategyInnovation/Value/MIGRATION.md` marks the old
  F6/F7 declarations as supporting and superseded for final-model use. None is
  an alias because the process binders or assumptions differ.
- **Proof dependencies:** T1 raw/compressed value projection; the raw
  frontier/closure compressed-state identity; exact expectation algebra;
  frontier insertion as pointwise maximum; finite action maxima; and the T1
  raw generation, admission, admitted-candidate, update, duration, cost,
  completion-coupling, and incumbent-reward definitions.
- **`#print axioms` result:** Every one of the 20 publication-facing
  declarations above is printed by
  `formal/StrategyInnovation/Audit/UnifiedDecomposition.lean` and the
  comprehensive audit. Each reports only
  `[propext, Classical.choice, Quot.sound]`.
- **Julia test or experiment counterpart:**
  `julia/scripts/search_revision_counterexamples.jl`; 19,468 unified
  premium-recursion checks passed across 512 randomized models with active and
  suspending projects, durations one through three, and exact joint completion
  laws. CX-T5-SEPARABILITY-01 gives premia $1/2$ and $1$ under equal
  initial frontier and closure. These tests target the earlier premium
  recursion and remain ancillary; no new Julia implementation was introduced.
- **Manuscript location:** Section 5 at `def:innovation-components`,
  `thm:value-decomposition`, `cor:frontier-silent-insertion`,
  `ex:operational-zero-generative-positive`, and
  `prop:diminishing-operational-innovation`; Appendix A at
  `prop:premium-monotonicity`.
- **Status:** Lean verified and numerically validated
- **Falsification classification:** exact insertion decomposition survives;
  closure-only or interaction-free premium claims remain false.
- **Informal mathematical validity:** The main equality is exact cancellation
  of passive terms. Frontier silence is induction on the frozen recursion;
  two-component silence invokes T1; operational antitonicity is induction on
  the positive frontier gap; and premium monotonicity follows from the stated
  action-value dominance certificate.
- **Lean kernel verification:** Focused and comprehensive audits pass with
  only the standard foundations listed above.
- **Julia implementation validation:** Existing exact randomized recursion
  checks and the nonseparability regression passed; they do not replace T5's
  raw Lean proof.
- **Empirical relevance:** Not assessed.

### T6 — Joint descendant-event generative-option lower bound

- **Theorem ID:** T6
- **Manuscript label:** Joint descendant-event generative-option lower bound
- **Informal statement:** A frontier-silent retained strategy that makes one
  project feasible has generative insertion value at least the nonnegative
  part of that project's cost-adjusted joint descendant-event gain, including
  the exact unified operating-timing adjustment.
- **Verified finite statement:** Under A-T6-CARRIER-BOUND, write
  $L^+=L\cup\{s\}$. For project $q$, descendant $g$, $d_q\le h$, and
  $G\ge0$,
  $$
    \Delta_h^{\rm gen}(s\mid b,L)
    \ge
    \max\!\left\{
      -\kappa+A^{\rm op}_{q,h}
      +\beta^{d_q}\sum_{b'}
        \eta_{q,g}(b'\mid b,K_{L^+})G(b'),0
    \right\}.
  $$
  Here $\eta_{q,g}$ is the terminal pushforward of the existing joint
  belief-path/admitted-outcome completion law, with
  $0\le\eta_{q,g}(b')\le1$ and
  $\sum_{b'}\eta_{q,g}(b')\le1$. No independence is assumed.
  The committed-project value is also decomposed exactly into initiation
  cost, expected operating reward during research, discounted frozen passive
  continuation, discounted joint descendant gain, and discounted remaining
  continuation. The remaining term includes every other admitted outcome and
  any surplus above the declared floor on `some g`.
  Under the product specialization
  $\eta_{q,g}=\pi\rho^{d_q}\mu_{q,d_q}$, the theorem recovers the earlier
  adjusted formula and, when $A^{\rm op}_{q,h}=0$, the requested
  $\max\{-\kappa+\beta^{d_q}\pi\rho^{d_q}\mathbb E_b[G(B_{d_q})],0\}$ formula.
- **Exact assumptions:** T1 assumptions plus A-T5-BASELINE and
  A-T6-CARRIER-BOUND. In particular, frontiers agree; $q$ is feasible only
  with the carrier and fits the horizon; the deleted comparator premium is
  zero; and the complete successful continuation improvement is at least
  $G(B_{d_q})\ge0$ on every length-$d_q$ path ending in `some g`.
  Insertion-only update, passive inclusion monotonicity, and full-over-passive
  dominance derive nonnegativity of every omitted outcome. Raw generation
  mass $\rho^{d_q}$, primitive admission $\pi$, and process-wide
  `ConditionalIndependence` are assumptions only of the product corollary.
- **Manuscript--Lean assumption reconciliation:**

  | Manuscript condition | Lean object | Match |
  |---|---|---|
  | finite unified process and declared joint law | `Model` and `process.completion` | exact |
  | frontier silence | `JointGenerativeCarrierCertificate.frontier_silent` | exact |
  | $q$ enabled after insertion | `.project_enabled` | exact |
  | $q$ unavailable before insertion | `.project_unavailable_without` | exact |
  | $d_q\le h$ | `.duration_fits` | exact |
  | exact initiation cost $\kappa$ | `.researchCost_eq` | exact |
  | zero-premium deleted comparator | `.deleted_premium_zero` | exact |
  | $G(b')\ge0$ | `.gain_nonnegative` | exact |
  | supportwise complete-continuation floor on `some g` | `.descendant_gain` over every full `BeliefPath` | exact, slightly stronger off support |
  | omitted outcomes nonnegative | `library_le_rawLibraryUpdate`, `passiveValue_mono_of_library_inclusion`, `passiveValue_le_fullValue` | derived exactly for the current insertion-only model |
  | no independence in primary theorem | no independence field in `JointGenerativeCarrierCertificate` | exact |
  | joint event mass $\eta$ | `jointDescendantMass` | exact terminal pushforward |
  | $0\le\eta_{q,g}(b')\le1$ | `jointDescendantMass_nonnegative`, `jointDescendantMass_le_one`, `jointDescendantMass_mem_unitInterval` | derived from completion nonnegativity and unit total mass |
  | $\sum_{b'}\eta_{q,g}(b')\le1$ | `jointDescendantEventMass`, `jointDescendantEventMass_nonnegative`, `jointDescendantEventMass_le_one` | exact distinguished-outcome subprobability bound |
  | exact operating block | `expectedOperatingBlock` and `operatingResearchAdjustment_eq_exactBlocks` | exact |
  | frozen passive continuation | `expectedFrozenPassiveContinuation` | exact |
  | continuation after other outcomes | `remainingContinuationGain`, `expectedRemainingContinuationGain` | exact residual without double counting |
  | exact project commitment accounting | `projectCommitmentValue_eq_cost_operating_joint_remaining` | exact |
  | operating adjustment | `operatingResearchAdjustment` | exact benefit-sign convention |
  | product specialization | `expectedJointDescendantGain_eq_independentProduct` plus `GenerativeCarrierCertificate.toJoint` | exact sufficient corollary |
- **Timing statement:** `operatingResearchAdjustment` is
  $$
    \mathbb E[G^{\rm op}+\beta^{d_q}P_{h-d_q}(B_{d_q},L^+)]
      -P_h(b,L^+).
  $$
  It is never omitted. The simpler formula assumes it is zero. Suspended
  operation can make it negative.
- **Derived consequences:** the joint scalar guarantee is monotone in
  pointwise $\eta$, pointwise $G$, and the benefit-signed operating
  adjustment, and antitone in $\kappa$. The product corollary retains the
  zero/strict-positive conditions and monotonicities in $\pi,\rho,G,\kappa$
  under its fixed-factor assumptions. Zero premia on both libraries imply
  exact zero generative value.
- **Excluded stronger claims:** Cost cannot be omitted. The conclusion can
  fail if insertion changes the frontier or the deleted state has a positive
  innovation premium. A harmful omitted outcome requires an explicit
  correction. Terminal $G$ must be a supportwise floor on complete
  continuation, including future project-menu changes. Conditional
  independence is not inferred from T1's two marginals. Duration has no
  unconditional sign when it changes the joint law, belief occupation,
  continuation gain, horizon feasibility, or operating adjustment.
- **Lean declarations:**
  `StrategyInnovation.Projection.Model.GenerativeLowerBound.jointDescendantMass`;
  `expectedJointDescendantGain`;
  `expectedJointDescendantGain_eq_terminalWeighted`;
  `JointGenerativeCarrierCertificate`;
  `jointGenerativeLowerBound`;
  `jointDescendant_expectedGain_le`;
  `generativeInsertionValue_lowerBound_joint`;
  `generativeInsertionValue_lowerBound_joint_terminalWeighted`;
  `jointDescendantMass_nonnegative`;
  `jointDescendantMass_le_one`;
  `jointDescendantMass_mem_unitInterval`;
  `jointDescendantEventMass`;
  `jointDescendantEventMass_nonnegative`;
  `jointDescendantEventMass_le_one`;
  `expectedOperatingBlock`;
  `expectedFrozenPassiveContinuation`;
  `remainingContinuationGain`;
  `expectedRemainingContinuationGain`;
  `operatingResearchAdjustment_eq_exactBlocks`;
  `completionContinuationGain_eq_joint_add_remaining`;
  `expectedCompletionContinuationGain_eq_joint_add_remaining`;
  `projectCommitmentValue_eq_cost_operating_joint_remaining`;
  `remainingContinuationGain_nonnegative`;
  `expectedRemainingContinuationGain_nonnegative`;
  `generalizedGenerativeOptionLowerBound`;
  `generalizedJointDescendantGain_eq_independentProduct`;
  `generalizedGenerativeOptionLowerBound_of_independence`;
  `generalizedGenerativeOptionLowerBound_mono_jointMass`;
  `generalizedGenerativeOptionLowerBound_mono_gain`;
  `generalizedGenerativeOptionLowerBound_antitone_cost`;
  `no_unconditional_duration_monotonicity`;
  `jointTerminalWeightedGain_mono_mass`;
  `jointTerminalWeightedGain_mono_gain`;
  `expectedJointDescendantGain_nonnegative`;
  `jointGenerativeLowerBound_eq_zero_iff`;
  `jointGenerativeLowerBound_pos_iff`;
  `generativeInsertionValue_pos_joint`;
  `jointGenerativeLowerBound_mono_expectedJointGain`;
  `jointGenerativeLowerBound_antitone_researchCost`;
  `jointGenerativeLowerBound_mono_operatingAdjustment`;
  `jointGenerativeLowerBound_mono_mass`;
  `jointGenerativeLowerBound_mono_gainFunction`;
  `expectedJointDescendantGain_eq_independentProduct`;
  `StrategyInnovation.Projection.Model.GenerativeLowerBound.GenerativeCarrierCertificate`;
  `GenerativeCarrierCertificate.toJoint`;
  `rawProjectActionValue_sub_passive`; `expected_success_gain_eq`;
  `expectedTerminalGain_eq_occupationWeighted`;
  `generativeInsertionValue_lowerBound_with_operatingAdjustment`;
  `generativeInsertionValue_lowerBound`;
  `generativeInsertionValue_lowerBound_occupationWeighted`;
  `generativeLowerBound_eq_zero_iff`;
  `generativeInsertionValue_eq_zero_of_premia_zero`;
  `generativeInsertionValue_pos_with_operatingAdjustment`;
  `generativeInsertionValue_pos`;
  `generativeLowerBound_mono_admission`;
  `generativeLowerBound_mono_survival`;
  `generativeLowerBound_mono_gainFunction`;
  `generativeLowerBound_antitone_researchCost`;
  `generativeLowerBound_antitone_duration`; and
  `CarrierExample.exact_joint_carrier_lowerBound_one`;
  `CarrierExample.exact_carrier_lowerBound_one`;
  `OneBeliefExample.exact_lowerBound_one`;
  `TwoBeliefExample.completionLaw`;
  `TwoBeliefExample.jointMass_exact`;
  `TwoBeliefExample.expectedJointGain_eq_two`; and
  `TwoBeliefExample.exact_lowerBound_one`.
- **Lean files:**
  `formal/StrategyInnovation/Value/GenerativeLowerBound.lean` and
  `formal/StrategyInnovation/Value/JointDescendantLowerBound.lean`.
- **Proof dependencies:** T1 joint completion coupling, calendar-horizon raw
  Bellman recursion, and insertion-only raw update; T5 passive/full values and
  generative insertion definition; exact finite expectation and sum algebra;
  and nonnegative rational powers. Raw generation, admission, and conditional
  independence enter only the product factorization corollary.
- **`#print axioms` result:** The legacy focused T6 audit prints 63
  declarations, and
  `formal/StrategyInnovation/Audit/JointDescendantLowerBound.lean` separately
  prints all 31 declarations in the dedicated joint-law interface, commitment
  accounting, and exact examples. Every declaration reports only
  `[propext, Classical.choice, Quot.sound]`, except
  `library_le_rawLibraryUpdate`, which needs only `[propext, Quot.sound]`.
- **Julia test or experiment counterpart:**
  `generative_strategy_lower_bound` and
  `generative_lower_bound_fixture` in `julia/src/InnovationValue.jl`, with
  exact-rational regression and comparative-static checks in
  `julia/test/test_innovation_value.jl`; and
  `julia/scripts/search_joint_descendant_bound.jl` with focused tests in
  `julia/test/test_joint_descendant_bound.jl`. The joint gauntlet checks
  2,204,496 primary laws, 419,904 correlated cases, 734,832 negative-
  adjustment cases, 2,204,496 two-descendant cases, and 171,072 corrected
  harmful-outcome cases with zero failures. It preserves eight minimized
  assumption-boundary counterexamples and four survivor fixtures. The earlier
  512-instance raw gauntlet and CX-T6-COST-01 remain unchanged.
- **Manuscript location:** Section 5.2 at
  `thm:generative-carrier-lower-bound` and
  `cor:t6-comparative-statics`; Appendix A at `ex:t6-exact-carrier`.
- **Status:** Lean verified and exact Julia fixture validated
- **Falsification classification:** the joint-law theorem survives the exact
  gauntlet. Minimal failures reject uncorrected harmful outcomes, omitted
  negative operating adjustment, a project already valuable on both sides,
  positive comparator premium, non-supportwise terminal gain, direct-only
  gain that omits future-menu displacement, horizon shorter than duration,
  and product-of-marginals substitution under correlation. The cost-free
  probability-times-gap conjecture remains false.
- **Informal mathematical validity:** Full value dominates Continue and the
  forced $q$ action. Subtracting the retained passive value gives the exact
  operating adjustment plus discounted completion gain. All omitted outcomes
  are nonnegative because raw update is insertion-only, passive value is
  inclusion-monotone, and full value dominates passive value. The primary
  proof retains joint path/outcome mass throughout. Conditional independence
  and the derived admitted law factor that term as
  $\rho^{d_q}\pi$ times terminal occupation only in the corollary.
- **Lean kernel verification:** Focused and comprehensive axiom audits pass
  with only the standard foundations listed above. The exact duration
  counterexample proves both longer-higher and longer-lower scalar
  comparisons once the joint term or operating block is allowed to change;
  it is not a monotonicity theorem under fixed inputs.
- **Julia implementation validation:** The exact scalar and joint carrier
  fixtures return gain two and bound one. Exact enumeration confirms the
  corrected primary, harm-corrected, comparator-corrected, correlated, and
  multiple-descendant formulas and preserves every discovered failure. The
  earlier 512 randomized raw instances continue to exceed the product
  specialization.
- **Empirical relevance:** Not assessed.

### CS1 — Sign-definite comparative statics in the finite unified model

- **Theorem ID:** CS1
- **Manuscript label:** Supporting formal comparative-statics family; no
  numbered manuscript theorem.
- **Informal statement:** With all nondisplayed primitives fixed, higher
  frontiers weakly raise full value, a higher incumbent frontier weakly lowers
  a fixed candidate's passive operational insertion value, lower research
  costs weakly raise optimized value, and higher admission or survival weakly
  raises a binary candidate project's return when success dominates failure.
  A declared generative-dominance order raises full value. Lower cost and
  higher survival expand the exact finite weak-research region.
- **Dynamic frontier statement:** `GenerativeDominanceOrder` compares current
  frontiers, feasible menus, costs, and complete unified completion
  expectations for every order-monotone continuation. Strong calendar-horizon
  induction proves compressed and raw value monotonicity. Under
  `FrontierIndependentPrimitives`, same closure and
  $F_0\le F_1$ induce that order, hence
  $$
    V_h(b,F_0,C)\le V_h(b,F_1,C).
  $$
- **Frontier saturation statement:** For any fixed catalog strategy $s$,
  pointwise $F_0\le F_1$ implies
  $$
    \Delta_h^{\mathrm{op}}(s\mid F_1)
      \le \Delta_h^{\mathrm{op}}(s\mid F_0)
  $$
  under the common passive belief recursion.
- **Cost statement:** `compressedValueWithCost` replaces only the unified
  model's nonnegative research-cost table. If
  $\kappa_0\le\kappa_1$ pointwise, then
  $V_h^{\kappa_1}\le V_h^{\kappa_0}$ for every horizon, belief, and
  compressed state.
- **Admission and survival statement:** For positive duration and exact
  $0\le\pi,\rho\le1$, the otherwise fixed binary law has success mass
  $\pi\rho^d$. If its success continuation weakly dominates failure,
  project return is monotone separately in $\pi$ and $\rho$.
- **Delay statement:** Unified elapsed return is
  $$
    R_d=-\kappa+\sum_{t<d}\beta^tF_t+\beta^dW.
  $$
  For $0<d_0\le d_1$, $0\le\beta\le1$, nonnegative $F_t$ and $W$,
  delay is antitone when every additional date satisfies
  $F_t\le(1-\beta)W$. Suspended operation is a corollary. The requested
  nonnegative-only continued-operation statement is false:
  $\beta=1/2,F_t=W=1$ gives $R_1=3/2<R_2=7/4$.
- **Closure statement:** `GenerativelyDominates` is the existing T5
  closure-enrichment/project-dominance order. It implies weakly larger full
  raw value. Mere closure inclusion has no sign.
- **Action-region statement:** The exact finite region is the `Finset` of
  states where a fixed research return weakly exceeds Continue. With all other
  primitives fixed, pointwise lower cost or higher survival weakly expands
  this region.
- **Exact assumptions:** A-CS-SIGN. The dynamic theorems use the final T1
  finite unified elapsed-time model; the binary-law and region theorems use
  exact rational scalars and finite state types. No theorem infers stochastic
  dominance from marginal probability order alone.
- **Excluded stronger claims:** no frontier sign if research opportunities
  change with the frontier; no admission/survival sign if success is worse
  than failure; no continued-operation delay sign from nonnegativity alone;
  no closure sign from set inclusion alone; and no region inclusion when
  nondisplayed primitives change.
- **Lean declarations:** `GenerativeDominanceOrder`;
  `compressedValue_mono_of_generativeDominanceOrder`;
  `rawValue_mono_of_generativeDominanceOrder`;
  `FrontierIndependentPrimitives`;
  `compressedValue_mono_of_frontier_le`;
  `operationalInsertionValue_antitone_of_frontier_le`;
  `ResearchCostSchedule`; `compressedValueWithCost_antitone`;
  `binaryCandidateProjectValue_mono_admission`;
  `binaryCandidateProjectValue_mono_survival`;
  `DelayAntitoneCertificate`;
  `unifiedElapsedProjectValue_antitone_duration`;
  `unifiedElapsedProjectValue_antitone_duration_of_suspendedOperation`;
  `fullValue_mono_of_generativeDominance`;
  `exactFiniteActionRegion_subset_of_lower_cost`; and
  `exactFiniteActionRegion_subset_of_higher_survival`.
- **Counterexample declarations:**
  `Counterexamples.frontier_mono_fails_without_fixed_opportunities`;
  `Counterexamples.admission_mono_fails_without_successDominance`;
  `Counterexamples.survival_mono_fails_without_successDominance`;
  `Counterexamples.delay_antitone_fails_without_noWaitingGain`;
  `Counterexamples.delay_antitone_fails_with_negativeContinuation`;
  `Counterexamples.closure_mono_fails_without_generativeDominance`; and
  `Counterexamples.lower_cost_region_fails_when_returns_change`.
- **Lean file:** `formal/StrategyInnovation/Value/ComparativeStatics.lean`.
- **Proof dependencies:** T1 unified positive-duration calendar recursion and
  completion coupling; T5 passive value, operational insertion recursion, and
  closure project dominance; exact rational finite sums, powers, expectations,
  finite maxima, and strong natural-number induction.
- **`#print axioms` result:** The focused audit prints all 39
  publication-facing definitions, certificates, theorems, and
  counterexamples. `exactFiniteActionRegion` and its membership lemma report
  `[propext, Quot.sound]`; every other declaration reports
  `[propext, Classical.choice, Quot.sound]`.
- **Julia implementation validation:** No Julia implementation changed. The
  existing exact revision gauntlet remains contextual numerical evidence, not
  a proof of CS1.
- **Manuscript location:** Appendix C gives the compact sign and ambiguity
  boundaries, exact delay algebra, action-region directions, and full finite
  differences. The family remains supporting and does not replace T7.
- **Status:** Lean verified
- **Informal mathematical validity:** Each positive result is a one-way order
  argument with all nondisplayed primitives held fixed. The delay increment
  identity exposes the missing condition exactly.
- **Lean kernel verification:** The clean 3,052-job build, focused 39-command
  audit, and comprehensive 346-command audit all passed. Only the standard
  foundations recorded above were reported.
- **Empirical relevance:** Not assessed.

### T7 — Frontier--closure substitutability under relative saturation

- **Theorem ID:** T7
- **Manuscript labels:** `def:frontier-closure-interaction`,
  `thm:frontier-closure-substitution`,
  `prop:primitive-frontier-saturation`, and
  `prop:t7-interaction-examples`.
- **Informal statement:** On a realizable frontier--closure rectangle, the
  optimized value has decreasing differences when closure-rich actions lose
  relative advantage against closure-poor actions as the frontier rises. In
  the fixed-continuation common-gap subclass, this relative order follows from
  an antitone common descendant gap, nonnegative rich-menu exposure, and zero
  exposure for every feasible poor-menu action.
- **Finite target statement:** For
  $$
    (F_0,C_0),\ (F_0,C_1),\ (F_1,C_0),\ (F_1,C_1),
    \qquad F_0\le F_1,\ C_0\subseteq C_1,
  $$
  define
  $$
    \Delta_CV_h(F;C_1,C_0)=V_h(F,C_1)-V_h(F,C_0)
  $$
  and
  $$
    J_h=\Delta_CV_h(F_1;C_1,C_0)
       -\Delta_CV_h(F_0;C_1,C_0).
  $$
  Under A-T7-GEN-INDEPENDENCE and A-T7-RELATIVE-SATURATION,
  $$
    J_h\le0
  $$
  for every finite calendar horizon and belief.
- **Primitive sufficient-condition statement:** Under
  A-T7-COMMON-GAP, each action value has the exact form
  $$
    Q_h(F_i,C_j,a)
      =B_{h,i}+\eta^j_{h,a}+\lambda^j_{h,a}g_{h,i},
  $$
  with $g_{h,1}\le g_{h,0}$, nonnegative rich exposures, and zero feasible
  poor exposures. Therefore every rich/poor relative action difference
  changes by
  $\lambda^1_{h,a_1}(g_{h,1}-g_{h,0})\le0$, which supplies
  A-T7-RELATIVE-SATURATION and invokes unchanged T7.
- **Recursive preservation statement:** In the canonical specialization,
  $$
    g_{0,i}(b)=\bar g_i(b),\qquad
    g_{h+1,i}(b)
      =s_i(b)+\beta E_{P(b,\cdot)}[g_{h,i}],
  $$
  where the process belief kernel $P$ is common to all four corners,
  $\beta\ge0$, $\bar g_1\le\bar g_0$, and $s_1\le s_0$. Positivity of
  rational expectation preserves $g_{h,1}\le g_{h,0}$ by finite-horizon
  induction. The resulting common-gap certificate supplies the primitive
  theorem at every horizon.
- **Exact assumptions:** T1 assumptions plus A-T7-GEN-INDEPENDENCE and
  A-T7-RELATIVE-SATURATION. Duration and operation
  are project-global fields of the unified process; the catalog and `addK`
  are fixed. `FrontierIndependentPrimitives` equates availability, cost, and
  complete joint completion laws across the two frontiers at each closure.
  `opportunities_expand` states menu inclusion across closures.
  A-T7-COMMON-GAP is an optional stronger subclass. Its fixed action
  intercept/exposure representation is stated at every finite node. The
  canonical recursive specialization derives the gap-order component from
  the shared process belief kernel, ordered flows and terminals, and
  nonnegative discounting; it does not infer the full representation for
  arbitrary optimized continuation.
- **Proof-critical correction:** The five initially requested conditions do
  not imply the cross-difference sign. CX-T7-INDEPENDENT-MENU-SWITCH-02 keeps
  both project rows frontier independent and both candidate premia antitone,
  but fixed differences in success and cost make the optimizer switch,
  yielding $J=1/2$. Relative action saturation is therefore additional and
  explicit. The broader primitive exposure-order proposal is also
  insufficient for the all-pairs premise: CX-T7-RS-CONTINUE-03 shows that
  rich Continue gains relative to a positive-exposure poor project. Zero poor
  exposure is the narrow correction within the common-gap class.
- **Lean declarations:**
  `StrategyInnovation.Projection.Model.SystemInteraction.
  compressedInteractionCrossDifference_nonpositive`,
  `relativeActionSaturation_of_commonGap`,
  `relativeActionSaturation_of_primitiveSaturation`, and
  `compressedInteractionCrossDifference_nonpositive_of_primitiveSaturation`;
  `StrategyInnovation.Interaction.PrimitiveSubstitution.
  recursiveGapValue_antitone`,
  `recursive_primitives_imply_relativeActionSaturation`,
  `relative_saturation_implies_crossDifference_nonpositive`, and
  `canonical_frontier_closure_substitutes`.
- **Lean files:**
  `formal/StrategyInnovation/Value/SystemInteraction.lean` and
  `formal/StrategyInnovation/Interaction/PrimitiveSubstitution.lean`.
- **Proof dependencies:** T1 unified compressed recursion; CS1
  `FrontierIndependentPrimitives`; exact finite action attainment; and the
  relative action-saturation inequality for the selected rich/high and
  poor/low actions. The primitive corollary additionally uses exact rational
  multiplication monotonicity on the common-gap exposure factorization and
  then calls the general theorem. Its recursive specialization uses
  expectation monotonicity under the process's fixed rational belief kernel
  and induction on the finite horizon.
- **`#print axioms` result:** The original focused audit prints all 37 T7
  definitions, structures, theorems, and examples; the new primitive audit
  prints all 12 recursion, adapter, substitution, and boundary declarations.
  `Examples.poorClosure` reports
  `[propext, Quot.sound]`; every other declaration reports
  `[propext, Classical.choice, Quot.sound]`.
- **Exact examples:** `strict_substitution_example` has increments $2$ and
  $1$, hence $J=-1$. Frontier-dependent success gives increments $0$
  and $1/2$, hence $J=1/2$. `separable_zero_interaction` has two increments
  $3/2$, hence $J=0$. The independent menu-switch boundary has old/new
  premia $(3,5/2)$ at $F_0$, $(0,1/2)$ at $F_1$, and $J=1/2$.
  `added_exposure_order_insufficient_for_allPairs` has equal old/added
  exposures but rejects $-1\le-5$ for rich Continue versus the poor old
  project. The new namespace theorems re-establish the positive project-switch
  and frontier-dependent-success interactions and the separable zero sign as
  explicit boundaries of the recursive primitive theorem.
- **Julia implementation validation:**
  `frontier_closure_interaction_surface` and
  `run_system_interaction_surface.jl` preserve the registered 2,430 exact
  `Rational{BigInt}` boundary rows. They retain 553 substitute, 1,865
  separable, and 12 complement cases and reproduce every Lean witness exactly.
  Version 2 adds five exact canonical fixtures and a 3,456-row response surface
  over the requested frontier, closure, project, incumbent, duration, and
  generator-quality axes. Every row reports the two closure increments,
  cross-difference, four corner policies, realizability flags, and the
  primitive certificate. Only 576 four-corner-realizable rectangles enter the
  sign summary: 156 substitutes, 183 complements, and 237 separable cases;
  2,880 nonrealizable compressed rectangles are retained as diagnostics but
  excluded from sign aggregation. All 192 primitive-certified rows have
  nonpositive interaction. The prior 5,230 gauntlet checks concerned the
  weaker passive-baseline premium comparison; they are not evidence for the
  stronger closure cross difference.
  `RealizableRectangles.jl` separately provides a raw-first construction
  layer: both exact fixtures form $L_{00},L_{01},L_{10},L_{11}$ by commuting
  insertions in one catalog, recompute every compressed image, and derive
  menus, embedded transitions, finite-horizon values, and policies from
  `RawInnovationProcess`. One fixture uses identity closure and a module-only
  carrier; the other derives a required bridge module from a frontier-silent
  trigger carrier. Sixty-three exact checks audit all four libraries, edge
  identities, closure-derived availability, transition pushforwards, and
  raw/compressed value-policy agreement. These fixtures establish
  realizability of the two constructed instances only; they do not prove the
  T7 sign theorem or alter the registered response-surface counts.
  `search_primitive_substitution.jl` separately evaluates 2,430 exact
  common-gap action tables. It finds 648 failures among 1,620 rows satisfying
  the broader added-exposure order, zero failures among 810 zero-poor-exposure
  rows, and preserves all 12 complement rows including the $J=1/2$
  optimizer switch. This is finite falsification/validation, not proof.
- **Manuscript location:** Appendix C states the compact interaction and
  optimizer-switching boundary and gives the general theorem, primitive
  common-gap corollary, recursive preservation condition, exact sign examples,
  finite-max proof, finite-horizon induction, and exposure-factorization
  argument. Appendix F gives only an
  economic-result-level status summary; exact declaration mapping is confined
  to the online supplement.
- **Status:** Lean verified; exact Julia surface validated
- **Falsification classification:** corrected theorem survives because
  relative saturation rules out the exact independent menu-switch boundary.
  Frontier-dependent success supplies the requested economic complementarity
  mechanism.
- **Informal mathematical validity:** Choose a maximizing action at
  $(F_1,C_1)$ and one at $(F_0,C_0)$. Frontier independence transports
  them to the other two corners. Relative saturation orders their payoff
  difference, and finite maximum inequalities order the optimized values.
- **Lean kernel verification:** The Lean build, focused 37-command general-T7
  audit, focused 12-command primitive-recursion audit, comprehensive
  570-command audit, and proof-source integrity scan all pass. Only the
  standard foundations recorded above are reported.
- **Julia implementation validation:** The full package suite passes, including
  80 dedicated general-T7 experiment checks and 38 exact
  primitive-substitution checks.
- **Empirical relevance:** Not assessed.

## Supporting-result registry

### S1 — Archived early equation label

- **Theorem ID:** S1
- **Manuscript label:** None; this early candidate label is superseded.
- **Disposition:** The unified Bellman recursion is now part of T1/S2, the
  exact unified insertion accounting identity is T5, and F7 is only a
  supporting primitive-adapter passive gap-sum proposition.
- **Lean declaration name:** None, because no active theorem retains the S1
  label.
- **Manuscript location:** None.
- **Status:** superseded; excluded from the active correspondence
- **Claim boundary:** The manuscript does not combine T5 and F7 into an
  unconditional unified gap-sum theorem. FG-0028 records the optional missing
  adapter bridge.

### S2 — Bellman contraction and stationary optimal policy

- **Theorem ID:** S2
- **Manuscript label:** `thm:finite-state-contraction`
- **Informal statement:** For the finite unified raw model and its realizable
  compressed projection, finite-horizon maxima are attained; raw and
  compressed stationary Bellman operators are monotone sup-norm
  contractions; the infinite-horizon value is unique; value iteration
  converges geometrically; raw/compressed and UDI values agree; and a
  stationary optimal selector satisfies its unique policy-evaluation equation
  and lifts to raw libraries.
- **Exact assumptions:** T1 structural assumptions, positive project
  durations, exact rational primitive data, and $0\le\beta<1$. Boundedness
  is automatic because every carrier is finite.
- **Lean declarations:**
  `StrategyInnovation.Projection.Model.finiteHorizonAction_attained`;
  `StrategyInnovation.Projection.Model.rawFiniteHorizonAction_attained`;
  `StrategyInnovation.Projection.Model.compressedBellmanOperator_mono`;
  `StrategyInnovation.Projection.Model.rawBellmanOperator_mono`;
  `StrategyInnovation.Projection.Model.compressedBellmanOperator_contracting`;
  `StrategyInnovation.Projection.Model.rawBellmanOperator_contracting`;
  `StrategyInnovation.Projection.Model.infiniteHorizonValue_isFixedPoint`;
  `StrategyInnovation.Projection.Model.infiniteHorizonValue_unique`;
  `StrategyInnovation.Projection.Model.rawInfiniteHorizonValue_unique`;
  `StrategyInnovation.Projection.Model.valueIteration_tendsto_infiniteHorizonValue`;
  `StrategyInnovation.Projection.Model.valueIteration_geometric_error_bound`;
  `StrategyInnovation.Projection.Model.rawValueIteration_tendsto_rawInfiniteHorizonValue`;
  `StrategyInnovation.Projection.Model.rawValueIteration_geometric_error_bound`;
  `StrategyInnovation.Projection.Model.finiteHorizon_rawValue_eq_compressedValue`;
  `StrategyInnovation.Projection.Model.rawInfiniteHorizonValue_eq_compressed`;
  `StrategyInnovation.Projection.Model.finiteHorizonValue_eq_of_dynamicInnovationEquivalent`;
  `StrategyInnovation.Projection.Model.infiniteHorizonValue_eq_of_dynamicInnovationEquivalent`;
  `StrategyInnovation.Projection.Model.exists_stationaryOptimalSelector`;
  `StrategyInnovation.Projection.Model.stationaryOptimalSelector_attains`;
  `StrategyInnovation.Projection.Model.stationaryOptimalSelector_policyEvaluationEquation`;
  `StrategyInnovation.Projection.Model.stationaryOptimalSelector_value_eq_infiniteHorizonValue`;
  `StrategyInnovation.Projection.Model.liftedRawStationarySelector_attains`;
  `StrategyInnovation.Projection.Model.liftedRawStationarySelector_policyEvaluationEquation`.
  The exact canonical instance is registered through
  `StrategyInnovation.Projection.Model.UnifiedCanonicalFixture.rawProbabilityLaws_normalized`;
  `StrategyInnovation.Projection.Model.UnifiedCanonicalFixture.compressedPushforwardLaws_normalized`;
  `StrategyInnovation.Projection.Model.UnifiedCanonicalFixture.rawUpdates_compress_to_declaredStates`;
  `StrategyInnovation.Projection.Model.UnifiedCanonicalFixture.projectDurations_positive`;
  `StrategyInnovation.Projection.Model.UnifiedCanonicalFixture.beliefPathProbabilities_eq_declaredPowers`;
  `StrategyInnovation.Projection.Model.UnifiedCanonicalFixture.operatingRewardBlocks_eq_declared`;
  `StrategyInnovation.Projection.Model.UnifiedCanonicalFixture.registeredFiniteHorizon_raw_eq_compressed`;
  `StrategyInnovation.Projection.Model.UnifiedCanonicalFixture.stationaryValue_bellmanFixedPoint`;
  `StrategyInnovation.Projection.Model.UnifiedCanonicalFixture.stationarySelector_attains`;
  `StrategyInnovation.Projection.Model.UnifiedCanonicalFixture.liftedRawSelector_policyEvaluationValue`;
  `StrategyInnovation.Projection.Model.UnifiedCanonicalFixture.exactPolicyEvaluationResidual_eq_zero`;
  `StrategyInnovation.Projection.Model.UnifiedCanonicalFixture.optimalActions_unique`.
- **Lean file:** `formal/StrategyInnovation/Bellman/Unified.lean`; exact
  instantiations in `formal/StrategyInnovation/Fixtures/UnifiedBellman.lean`
  and `formal/StrategyInnovation/Fixtures/UnifiedCanonical.lean`.
- **Proof dependencies:** T1's exact completion law, positive duration,
  raw/compressed Bellman intertwining, nonexpansiveness of finite exact
  expectation, $\beta^{d(q)}\le\beta$, preservation of a common bound by a
  finite maximum, mathlib's contraction theorem, and unified UDI value
  preservation. The finite-horizon recursion uses only projects whose
  duration fits the remaining calendar horizon; stationary value iteration
  uses the complete available action menu.
- **`#print axioms` result:** Every registered S2 declaration reports either
  no axioms or only `[propext, Classical.choice, Quot.sound]`; no
  user-declared axiom or placeholder occurs. The dedicated 36-command
  canonical audit and the comprehensive audit record every fixture
  certificate.
- **Julia test or experiment counterpart:**
  `FX-S2-UNIFIED-STATIONARY-01` in
  `julia/scripts/search_revision_counterexamples.jl` uses one belief,
  positive duration one, active incumbent operation, a raw bridge module, and
  deterministic admission. Exact policy iteration selects research at the
  bridge state with value $2$, Continue at the descendant with value $4$,
  and has both policy-evaluation and Bellman residual zero.
  `julia/scripts/solve_unified_canonical_benchmark.jl` supplies the
  publication-facing six-state numerical fixture from four raw strategies,
  eight raw libraries, explicit modules, raw generation and verification,
  full positive-duration belief paths, exact completion couplings, and
  deterministic raw updates. Compressed states and embedded transitions are
  derived from those primitives.
- **Manuscript location:** Section 6,
  `prop:finite-horizon-action-attainment` and
  `thm:finite-state-contraction`; they are combined in one supporting
  proposition and explicitly presented as standard solution theory rather
  than a novelty result. Section 6 states the exact unified fixture, while
  Appendix D gives the full argument, action-value table, zero-residual check,
  and convergence history.
- **Status:** Lean verified and numerically validated
- **Informal mathematical validity:** Standard finite semi-Markov contraction
  and finite-selector argument under the exact unified timing.
- **Lean kernel verification:** The focused
  `Audit/UnifiedBellman.lean`, `Audit/UnifiedCanonical.lean`, and
  comprehensive axiom audit pass. The
  contraction certificates are derived rather than assumed, every fixed
  stationary policy operator is a contraction, and the maximizing selector's
  fixed-point equation identifies its policy value with the optimal value.
  The canonical fixture additionally checks the exact six-state rational
  table and all twelve requested raw-law, timing, correspondence, residual,
  and uniqueness properties by finite kernel reduction.
- **Julia implementation validation:** Reusable exact raw and compressed
  policy iteration agree on every realizable fixture state and return equal
  policies plus zero rational policy-equation and Bellman residuals. The
  unified Lean fixture selects research at value $2$ and Continue at value
  $4$. The selected canonical fixture checks 32 raw/compressed embedded
  transitions, 144 finite-horizon values, 128 finite-horizon actions, 16
  stationary values, and 16 lifted stationary actions. Its exact stationary
  policy is Discover/Continue, Scale/Scale, Continue/Continue across
  $K_0,K_1,K_2$, and exact policy iteration and stationary policy evaluation
  both have residual zero. Dynamically equivalent distinct raw libraries have
  identical finite and stationary values and policies. The legacy exact and
  Float64 solver remains a warning-emitting primitive compatibility model.
- **Empirical relevance:** Not assessed.

### S3 — Diminishing marginal innovation value

- **Theorem ID:** S3
- **Manuscript label:** Candidate supporting result S3
- **Informal statement:** Possible diminishing-returns result for a future
  library-value set function. The accepted model does not imply it.
- **Exact assumptions:** None adopted. Module and candidate complementarities
  make unconditional submodularity likely false.
- **Lean declaration name:** None.
- **Lean file:** None.
- **Proof dependencies:** A separately defined set function and explicit
  restrictions eliminating or controlling complementarities.
- **`#print axioms` result:** Not run; no declaration exists.
- **Julia test or experiment counterpart:** None; exhaustive finite set-function
  tests are planned.
- **Manuscript location:** Planned compression/value section or appendix; no
  result text exists in the buildable manuscript scaffold.
- **Status:** revised, proposed
- **Informal mathematical validity:** High falsehood risk; counterexample
  search must precede any theorem statement.
- **Lean kernel verification:** Not started.
- **Julia implementation validation:** Not started.
- **Empirical relevance:** Not assessed.

### S4 — Coverage-potential representation

- **Theorem ID:** S4
- **Manuscript label:** Supporting finite one-shot coverage-potential
  representation; not T6.
- **Informal statement:** On a finite ordered belief grid, a one-shot
  project's gross operational value for one fixed candidate is exactly the
  candidate's certified nonnegative frontier gap integrated against its
  discounted, survival-adjusted future-belief occupation weights. The
  potential is monotone in the gap, discount, survival, and pointwise
  occupation; zero gap on all occupation-reachable beliefs gives zero value;
  finite regional minima/maxima give exact occupation bounds; and improving
  the existing frontier weakly lowers a fixed candidate's potential.
- **Exact Lean assumptions:**
  1. `FiniteOrderedBeliefGrid` supplies a nonempty finite belief type with a
     linear order. Finiteness supplies exact `Finset` sums; the order is used
     for finite gap minima and maxima only.
  2. `OccupationWeights.weight t b b'` is exact rational and pointwise
     nonnegative. `IsProbabilityOccupation` separately requires every
     date/initial-belief row to sum to one.
  3. The reusable definitions take a finite natural-number horizon, exact
     rational discount, exact rational candidate-survival scalar, a gap table
     `Project → LibraryState → Belief → ℚ`, and one fixed project/state/initial
     belief.
  4. `discountedOccupationWeight` is exactly
     $\sum_{t<H}\beta^t\rho^t\omega_t(b,b')$, and
     `coveragePotential` is exactly
     $\sum_{b'}W_H(b,b')\Delta(q,K,b')$.
  5. `certifiedGap` is
     $\max\{j_q(b)-F_K(b),0\}$, so it is nonnegative. Candidate value does
     not depend on the compared library state.
  6. `OneShotModel` requires $0\le\beta\le1$,
     $0\le\rho_q\le1$, and normalized occupation rows. Its gross value is
     the date-first double sum of the same terms.
  7. Discount and survival monotonicity assume nonnegative smaller values;
     occupation monotonicity is pointwise; all three use a nonnegative gap.
     Gap monotonicity uses nonnegative discount, survival, and occupation.
  8. `Reachable` means that some date before the horizon has nonzero exact
     occupation weight. The zero theorem assumes the gap vanishes on every
     such belief and makes no converse claim.
  9. The lower bound uses a nonempty advantage region's actual finite minimum
     gap and its discounted occupation. The global upper bound uses the actual
     finite maximum gap and total discounted occupation. A regional upper
     bound additionally assumes the gap is zero outside the region.
  10. The exact example uses beliefs `Fin 2`, deterministic occupation of
      belief zero at date zero and belief one afterward, horizon two,
      discount one half, survival one, zero current gap, and future gap two.
- **Assumption reconciliation:** Items 1--10 are exactly
  A-S4-COVERAGE-POTENTIAL. The model is gross and operational. No raw
  generation, verification, admission/success probability, project cost,
  optimization, or forced-research/forced-idle comparison is present.
- **Lean file:**
  `formal/StrategyInnovation/Coverage/Potential.lean`.
- **Proof audit file:**
  `formal/StrategyInnovation/Audit/CoveragePotential.lean`.
- **Definitions:** `StrategyInnovation.Coverage.FiniteOrderedBeliefGrid`,
  `OccupationWeights`, `IsProbabilityOccupation`, `certifiedGap`,
  `discountedOccupationWeight`, `coveragePotential`,
  `oneShotGrossOperationalResearchValue`, `Reachable`,
  `advantageRegion`, `discountedRegionOccupation`,
  `totalDiscountedOccupation`, `minimumGapOn`, `maximumGap`, and
  `OneShotModel`.

| Lean declaration | Exact role | `#print axioms` result |
|---|---|---|
| `StrategyInnovation.Coverage.certifiedGap_nonnegative` | certified positive-part gap | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.coveragePotential_eq_oneShotGrossOperationalResearchValue` | exact finite-sum representation | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.coveragePotential_mono_gap` | pointwise gap monotonicity | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.coveragePotential_mono_discount` | discount monotonicity | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.coveragePotential_mono_survival` | candidate-survival monotonicity | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.coveragePotential_mono_occupation` | pointwise occupation monotonicity | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.coveragePotential_eq_zero_of_gap_eq_zero_on_reachable` | reachable-support no-value condition | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.totalDiscountedOccupation_eq_geometricSum` | probability-occupation interpretation | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.minimumGapOn_mul_regionOccupation_le_coveragePotential` | regional minimum lower bound | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.advantageRegion_minimumGap_mul_occupation_le_coveragePotential` | strict-advantage-region lower bound | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.coveragePotential_le_maximumGap_mul_totalOccupation` | global maximum upper bound | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.coveragePotential_le_maximumGap_mul_advantageRegionOccupation` | advantage-region maximum upper bound | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.coveragePotential_le_maxGap_mul_regionOccupation` | supported-region upper bound | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.OneShotModel.coveragePotential_eq_grossOperationalResearchValue` | declared-model representation | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.OneShotModel.coveragePotential_antitone_of_frontier_improves` | existing-frontier improvement comparison | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.DelayedCoverageExample.zero_currentGap_positive_coveragePotential` | exact zero-now/positive-potential witness | `[propext, Classical.choice, Quot.sound]` |

- **Proof dependencies:** finite-sum rearrangement, rational order and powers,
  nonnegative finite-sum monotonicity, finite `inf'`/`sup'`, exact support
  elimination, and positive-part antitonicity under frontier improvement.
- **Difference from T6:** S4 values a supplied fixed candidate through
  primitive occupation weights and omits project cost and admitted-candidate
  success probability. It proves neither the T6 net expected-gap inequality
  nor equality of that inequality with a forced-action value comparison.
- **Julia test or experiment counterpart:**
  `finite_discounted_occupation`, `finite_coverage_potential`,
  `candidate_gap`, and `coverage_potential` in `julia/src/Coverage.jl` mirror
  the finite Markov-occupation specialization. The exact S4 horizon-two
  fixture lives in `julia/test/test_coverage.jl`. Prospective Family F in
  `theorem-mechanism-controlled-suite-v2` fixes six exact candidates before
  execution and checks that occupation-first coverage scores equal an
  independently evaluated date-first gross value candidate by candidate,
  recover the exact target ranking, obey a top-two separation condition under
  bounded score error, and support redundancy-aware marginal set selection.
  This is an S4 instance, not a general ranking result. The prior
  `t6_inequality_holds` search remains a distinct one-period T6 oracle.
- **Manuscript location:** Appendix C at `def:coverage-potential`,
  `thm:coverage-potential-representation`,
  `cor:coverage-potential-bounds`, and `ex:delayed-coverage`, with the gross
  fixed-candidate and finite-horizon boundaries explicit; the finite-sum
  derivations are in Appendix C.
- **Status:** revised, Lean verified, exact Julia finite-Markov specialization
  validated
- **Informal mathematical validity:** Exact finite distributivity and order
  arguments establish the representation, monotonicities, zero condition, and
  bounds.
- **Lean kernel verification:** Passed under Lean 4.32.0 and mathlib commit
  `81a5d257c8e410db227a6665ed08f64fea08e997`. Every registered declaration
  reports only `[propext, Classical.choice, Quot.sound]`; no user-declared
  axiom or placeholder appears.
- **Julia implementation validation:** The exact Julia occupation sum and
  gap-weighted potential reproduce the delayed S4 value one and agree with the
  exact resolvent/remainder identity on small rational Markov kernels. The
  prospective six-candidate fixture closes all exact coverage/date-first
  identities, returns Spearman rank correlation one and zero top-one regret for
  coverage, preserves the winner when the `3//2` margin exceeds twice the
  `1//2` error bound, reverses it under the configured unit-error stress, and
  raises exact top-two union value from `10//1` to `69//4` by rejecting a
  dominated clone. The locked ETF ranking remains adverse and is not used in
  these gates. The
  reusable API specializes Lean's primitive occupation table to `P^t`; its
  infinite resolvent and delayed-lifetime extension are computational additions,
  not Lean-verified statements.
- **Empirical relevance:** Not assessed.

### S5 — Monotone-gap upper-threshold theorem

- **Theorem ID:** S5
- **Manuscript label:** `thm:finite-monotone-coverage`, titled
  “Monotone-gap upper-threshold theorem”; a supporting one-shot
  cost-covering theorem, not T6, an optimal Bellman research-region theorem,
  or a general unimodality theorem.
- **Desired statement tested:** On a finite ordered belief grid, a nonnegative
  single-peaked or quasi-concave gap remains single-peaked after transition,
  so every potential superlevel set and cost-covering set is an
  interval.
- **Disposition of desired statement:** False without additional assumptions.
  CX-SG-KERNEL-01 maps the single-peaked gap $(0,1,0)$ to potential
  $(1,0,1)$ with a valid deterministic row-stochastic kernel.
  CX-SG-COST-01 disconnects the coverage set of increasing potential
  $(1,2,3)$ using cost $(0,3,0)$.
- **Verified statement:** Let $B$ be a nonempty finite linearly ordered grid,
  $P$ an exact rational row-stochastic kernel, $\Delta:B\to\mathbb Q$ an
  increasing nonnegative gap, $p:B\to\mathbb Q$ an increasing nonnegative
  survival factor, $\beta\ge0$, and $\kappa:B\to\mathbb Q$ antitone. If
  $P$ is first-order stochastically monotone, then

  $$
    G(b)=\beta p(b)\sum_{b'}P(b,b')\Delta(b')
  $$

  is increasing. Consequently

  $$
    \mathcal C=\{b:\kappa(b)\le G(b)\}
  $$

  is an upper set, is order-connected, and is either empty or exactly
  $[b^*,\infty)\cap B$ for some $b^*\in B$.
- **Exact Lean assumptions:**
  1. `FiniteOrderedBeliefGrid` supplies `Fintype`, `LinearOrder`, and
     `Nonempty` instances for the belief carrier.
  2. `FiniteTransitionKernel.weight` is exact rational, pointwise
     nonnegative, and each finite row sums exactly to one.
  3. `IsStochasticallyMonotone kernel` states that for every rational-valued
     monotone function `f`, the exact finite expectation
     `expectedGap kernel f` is monotone.
  4. The gap is pointwise nonnegative and `Monotone`; it is not merely assumed
     `IsSinglePeaked`.
  5. The survival factor is pointwise nonnegative and `Monotone`. No upper
     bound of one is proof-relevant; a probability interpretation may add it.
  6. The rational discount is nonnegative. Because the sum is finite, no
     convergence assumption is needed and no upper bound of one is used.
  7. Research cost is `Antitone`.
  8. `oneShotCostCoveringSet` uses the weak exact inequality
     `cost b ≤ discount * survival b * expectedGap kernel gap b`.
- **Assumption reconciliation:** Items 1--8 are exactly
  A-S5-MONOTONE-COVERAGE. They prove Option 1 from the requested alternatives.
  The semantic first-order stochastic-monotonicity hypothesis is explicit;
  no TP2, total-nonnegativity, log-concavity, or variation-diminishing theorem
  is imported or claimed. The displayed set is one-shot gross cost covering;
  it is not an optimal Bellman action region.
- **Cutoff comparative statics:** Exact set inclusion proves that pointwise
  higher cost shrinks the covering set, higher nonnegative survival or
  admission probability expands it, and a pointwise frontier improvement
  shrinks a fixed candidate's covering set through antitonicity of the
  positive-part gap. If both compared sets are nonempty upper thresholds,
  their cutoff directions are respectively higher, lower, lower, and higher.
- **Finite geometry definitions:** `HasIntervalSupport` is order-connectedness
  of the strict positive support; `IsSinglePeaked` is monotonicity on the lower
  side of some peak and antitonicity on its upper side;
  `IsQuasiConcaveSequence` is the three-point minimum inequality; and
  `HasConnectedUpperLevelSets` requires every weak upper level set to be
  order-connected. Lean proves quasi-concavity iff connected upper levels,
  and single-peakedness implies quasi-concavity and interval support.
- **Mathlib audit:** At pinned mathlib commit
  `81a5d257c8e410db227a6665ed08f64fea08e997`, reusable support exists for
  `Set.OrdConnected`, upper sets, and finite upper-threshold representation.
  `Mathlib.Analysis.Convex.Quasiconvex` concerns convex subsets of modules, not
  arbitrary finite ordered sequences. No dedicated finite-sequence
  unimodality, log-concavity, TP2/total-positivity, or variation-diminishing
  result was found. The order-sequence equivalences are therefore proved from
  first principles.
- **Lean file:** `formal/StrategyInnovation/Coverage/SingleGap.lean`.
- **Proof audit file:** `formal/StrategyInnovation/Audit/SingleGap.lean`.
- **Exact Julia search:**
  `julia/scripts/search_single_gap_geometry.jl`, configured by
  `experiments/configs/single_gap_geometry.toml`, writes
  `experiments/results/single_gap_geometry.json` and exact fixture
  `formal/StrategyInnovation/Fixtures/SingleGapGeometry.lean`.
- **Reusable Julia counterpart:** `gross_coverage_value`,
  `is_stochastically_monotone`, `cost_covering_set`,
  `connected_components`, and `extract_threshold` in
  `julia/src/Coverage.jl`, with exact fixture, comparative-static, and
  assumption-boundary regressions in `julia/test/test_coverage.jl`.
  `research_region` remains a compatibility wrapper only.

| Lean declaration | Exact role | `#print axioms` result |
|---|---|---|
| `StrategyInnovation.Coverage.quasiConcaveSequence_iff_connectedUpperLevelSets` | finite-order quasi-concavity equivalence | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.IsSinglePeaked.quasiConcaveSequence` | single-peaked implies quasi-concave | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.IsSinglePeaked.intervalSupport` | positive support is order-connected | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.expectedGap_nonnegative` | nonnegative exact finite expectation | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.grossCoverageValue_monotone` | monotone gross coverage value | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.oneShotCostCoveringSet` | exact weak gross-value/cost comparison; not a Bellman region | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.oneShotCostCoveringSet_isUpperSet` | upward-closed one-shot cost-covering set | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.monotoneGap_upperThreshold` | main finite empty-or-upper-threshold result | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.expectedGap_mono_gap` | pointwise gap monotonicity | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.oneShotCostCoveringSet_antitone_cost` | higher cost shrinks the set | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.oneShotCostCoveringSet_mono_success` | higher nonnegative success expands the set | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.oneShotCostCoveringSet_mono_survival` | survival specialization | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.oneShotCostCoveringSet_mono_admissionProbability` | admission-probability specialization | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.oneShotCostCoveringSet_antitone_frontier` | fixed-candidate frontier increase shrinks the set | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.cutoff_le_of_Ici_subset` | inclusion orders finite upper cutoffs | `[propext, Quot.sound]` |
| `StrategyInnovation.Coverage.cost_cutoff_mono` | higher-cost cutoff direction | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.survival_cutoff_antitone` | higher-survival cutoff direction | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.admissionProbability_cutoff_antitone` | higher-admission cutoff direction | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.frontier_cutoff_mono` | higher-frontier cutoff direction | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.SingleGapCounterexamples.destructiveKernel_expectedGap` | exact kernel multiplication gives `(1,0,1)` | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.SingleGapCounterexamples.singlePeakedGap_disconnectedPotential` | single-peaked input/disconnected output counterexample | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.SingleGapCounterexamples.destructiveKernel_not_stochasticallyMonotone` | failed theorem assumption is exposed | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.SingleGapCounterexamples.nonmonotoneKernel_disconnectedCostCoveringSet` | increasing-gap witness isolating failure of kernel monotonicity | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Coverage.SingleGapCounterexamples.nonAntitoneCost_disconnectedCostCoveringSet` | non-antitone-cost disconnection counterexample | `[propext, Classical.choice, Quot.sound]` |

- **Proof dependencies:** exact finite sums and rational order; mathlib's
  `Set.OrdConnected` and `IsUpperSet` API; finite well-foundedness to represent
  any upper set as empty or `Ici cutoff`; and elementary product monotonicity
  under nonnegativity.
- **Counterexamples outside assumptions:** CX-SG-KERNEL-01 violates first-order
  stochastic monotonicity. CX-SG-COST-01 violates antitonicity of cost. Both
  use exactly three grid points, the minimum cardinality for a disconnected
  subset with both endpoints present.
- **Difference from T6:** S5 takes a primitive kernel, gap, survival factor,
  discount, and cost inequality. It does not establish current T6's marginal
  retained-carrier bound under raw generation, verification, admission, and
  the deleted-state comparator assumptions. It also does not characterize the
  unified Bellman research region.
- **Headline-worthiness:** No. The positive statement is a clean finite
  supporting comparative static under strong standard monotonicity assumptions.
  The sharper contribution is the formally delimited boundary: general
  single-peaked coverage connectedness is false.
- **Manuscript location:** Appendix C at `def:single-gap-region`,
  `thm:finite-monotone-coverage`, and
  `prop:one-shot-cutoff-comparative-statics`, with exact kernel assumptions
  and the one-shot/Bellman/T6 boundaries explicit; failed stronger cases are
  in Appendix B and the derivations are in Appendix C.
- **Migration:** `singleGapResearchRegion`,
  `singleGapResearchRegion_isUpperSet`,
  `monotone_singleGap_yields_upperThreshold`, and
  `nonAntitoneCost_disconnectedResearchRegion` remain compatibility aliases or
  wrappers. Publication-facing names are recorded in
  `formal/StrategyInnovation/Coverage/MIGRATION.md`.
- **Status:** scope-corrected under D-0061; Lean verified and exact Julia
  counterexamples/comparative statics validated
- **Informal mathematical validity:** The positive result is elementary order
  algebra. The rejected stronger statements have exact minimal three-state
  counterexamples.
- **Lean kernel verification:** Passed under Lean 4.32.0 and pinned mathlib.
  Every registered declaration above reports only
  `[propext, Classical.choice, Quot.sound]`; no user-declared axiom or
  placeholder appears.
- **Julia implementation validation:** Exact `Rational{BigInt}` regressions
  check both witnesses, reproduce the committed Lean fixture, validate the
  positive upper-threshold hypotheses and all four cutoff directions through
  the reusable API, and retain
  the prior 60,000-configuration deterministic-kernel audit. This finite
  computation is validation evidence, not the proof. Controlled family F puts
  the exact monotone threshold, identity-preserved peak, destructive-kernel
  peak, and two-gap cases in one table, with component counts `(1,1,2,2)`.
- **Empirical relevance:** Not assessed; S5 and its counterexamples are finite
  mathematical boundary results.

### S6 — Finite patience--survival complementarity

- **Theorem ID:** S6
- **Manuscript label:** `thm:discount-survival-complementarity`.
- **Informal statement:** For a finite exact row-stochastic matrix $P$,
  nonnegative rational gap vector $g$, and finite horizon $H$, define
  $$
    U_{\alpha,H}=\sum_{t<H}\alpha^tP^t,\qquad
    \Psi_H(\beta,\rho)=U_{\beta\rho,H}g.
  $$
  The potential equals
  $\sum_{t<H}(\beta\rho)^tP^tg$, is monotone in either nonnegative scalar,
  and has increasing differences in discount and survival.
- **Exact interaction:**
  $$
  \begin{split}
   &[\Psi_H(\beta_1,\rho_1)-\Psi_H(\beta_0,\rho_1)]
   -[\Psi_H(\beta_1,\rho_0)-\Psi_H(\beta_0,\rho_0)]\\
   &\quad=\sum_{t<H}
     (\beta_1^t-\beta_0^t)(\rho_1^t-\rho_0^t)P^tg\ge0
  \end{split}
  $$
  whenever $0\le\beta_0\le\beta_1$ and
  $0\le\rho_0\le\rho_1$. This is algebraically equivalent to
  $$
    \Psi_H(\beta_1,\rho_1)+\Psi_H(\beta_0,\rho_0)
    \ge
    \Psi_H(\beta_1,\rho_0)+\Psi_H(\beta_0,\rho_1).
  $$
- **Exact Lean assumptions:** finite state type with decidable equality;
  `transition ∈ Matrix.rowStochastic ℚ State`; pointwise `0 ≤ gap`; a finite
  natural-number horizon; nonnegative lower discount and survival; and ordered
  parameter pairs. Upper bounds of one are not needed for the finite theorem.
- **Assumption reconciliation:** Exactly A-S6-DISCOUNT-SURVIVAL. Row
  stochasticity is stronger than the sign proof needs but matches the model
  and, through submonoid closure under powers, derives
  $P^tg\ge0$. No infinite series, matrix inverse, convergence, or real
  differentiability theorem is used.
- **Lean file:**
  `formal/StrategyInnovation/Coverage/DiscountSurvivalInteraction.lean`.
- **Proof audit file:**
  `formal/StrategyInnovation/Audit/DiscountSurvivalInteraction.lean`.
- **Main declarations:**
  `finiteHorizonPotential_eq_sum`;
  `finiteResolvent_mulVec_eq_finiteEffectivePotential`;
  `matrixPowerGap_nonnegative`;
  `finiteEffectivePotential_mono`;
  `finiteHorizonPotential_mono_discount`;
  `finiteHorizonPotential_mono_survival`;
  `finiteHorizonPotential_crossDifference_eq_factorized`;
  `discountIncrement_difference_eq_factorized`;
  `discountIncrement_mono_survival`;
  `discountIncrement_le_iff_crossDifference`; and
  `finiteHorizonPotential_crossDifference_nonnegative`.
- **Exact boundary:** The one-state stochastic example with horizon two,
  $(\beta_0,\rho_0)=(0,0)$,
  $(\beta_1,\rho_1)=(1,1)$, and $g=-1$ reverses the cross inequality.
  This is
  `Counterexamples.crossDifference_fails_without_nonnegativeGap`.
- **`#print axioms` result:** The focused audit prints all 22 definitions and
  declarations. `Counterexamples.oneStateTransition` reports
  `[propext, Quot.sound]`; every other declaration reports
  `[propext, Classical.choice, Quot.sound]`.
- **Julia implementation validation:**
  `finite_discount_survival_interaction` computes all four finite potentials,
  the two discount increments, their cross difference, and the independently
  factorized sum using `Rational{BigInt}`. On the exact two-state kernel
  $$
    P=\begin{pmatrix}3/4&1/4\\1/2&1/2\end{pmatrix},\quad
    g=(1,3),\quad H=5,
  $$
  with $(\beta_0,\beta_1)=(1/4,3/4)$ and
  $(\rho_0,\rho_1)=(1/3,2/3)$, both cross-difference calculations equal
  $(43771/55296,24869/27648)$.
- **Analytical boundary:** Julia's exact finite-dimensional solve continues to
  validate $U_\alpha=(I-\alpha P)^{-1}$ for $\alpha<1$. The manuscript
  names this only as interpretation. No resolvent derivative is stated as a
  Lean-verified result.
- **Manuscript location:** Appendix C states the finite
  discount--survival complementarity theorem and its full factorization.
- **Status:** Lean verified; exact Julia algebra validated
- **Informal mathematical validity:** Finite distributivity and the identity
  $$
    \beta_1^t\rho_1^t+\beta_0^t\rho_0^t
      -\beta_1^t\rho_0^t-\beta_0^t\rho_1^t
    =(\beta_1^t-\beta_0^t)(\rho_1^t-\rho_0^t)
  $$
  reduce every sign to nonnegative finite factors.
- **Lean kernel verification:** The clean 3,143-job build, focused 22-command
  S6 audit, comprehensive 387-command audit, and proof-source placeholder scan
  all pass. Only `propext`, `Classical.choice`, and `Quot.sound` are reported,
  except that the concrete one-state matrix definition does not report choice.
- **Empirical relevance:** Not assessed.

### S7 — Belief-kernel alignment and persistence counterexamples

- **Theorem ID:** S7
- **Manuscript labels:** `prop:no-universal-persistence-sign` and
  `thm:kernel-occupation-alignment`.
- **Informal statement:** For finite horizon $H$, effective discount
  $\alpha$, rational transition matrix $P$, and nonnegative gap $g$,
  $$
    \Psi^P_{H,\alpha}(b)
      =\sum_{t<H}\alpha^t(P^tg)(b)
      =\sum_{b'}\left[\sum_{t<H}\alpha^t(P^t)(b,b')\right]g(b').
  $$
  If $P_1$ has at least as much discounted occupation as $P_0$ on every
  state with positive gap, from every initial state, then
  $\Psi^{P_1}_{H,\alpha}\ge\Psi^{P_0}_{H,\alpha}$ pointwise. In contrast,
  a scalar increase in persistence can raise, lower, or leave coverage
  unchanged.
- **Gap-tailored order:**
  $P_1\succeq_gP_0$ is defined exactly by the displayed pointwise coverage
  inequality. Advantage-region occupation dominance is a transparent
  sufficient condition for this order.
- **Exact sign family:** on `Fin 2`,
  $$
    P(\theta)=
      \begin{pmatrix}\theta&1-\theta\\1-\theta&\theta\end{pmatrix}.
  $$
  At initial state zero, $H=2$, $\alpha=1/2$, and
  $\theta:1/4\to3/4$, coverage changes as follows:
  $9/8\to11/8$ for $g=(1,0)$;
  $3/8\to1/8$ for $g=(0,1)$; and
  $3/2\to3/2$ for $g=(1,1)$.
- **Exact Lean assumptions:** finite state type with decidable equality,
  rational matrices, finite natural-number horizon, and pointwise
  nonnegative gap. The exact family is proved row stochastic for
  $0\le\theta\le1$. The alignment implication itself needs only the
  displayed occupation inequalities and gap nonnegativity; stochasticity and
  parameter bounds are contextual Markov assumptions rather than hidden proof
  premises.
- **Assumption reconciliation:** Exactly A-S7-KERNEL-ALIGNMENT. The manuscript
  states the stronger probabilistic context while its theorem makes clear
  that the proof-critical hypotheses are nonnegative gap and discounted
  advantage-region occupation dominance.
- **Lean file:**
  `formal/StrategyInnovation/Coverage/KernelComparativeStatics.lean`.
- **Proof audit file:**
  `formal/StrategyInnovation/Audit/KernelComparativeStatics.lean`.
- **Main declarations:**
  `finiteEffectivePotential_eq_discountedOccupation`;
  `coverage_mono_of_occupationDominatesOnAdvantage`;
  `gapOccupationDominates_of_occupationDominatesOnAdvantage`;
  `gapOccupationDominates_iff`;
  `persistenceKernel_stochastic`;
  `higherPersistence_raises_coverage`;
  `higherPersistence_lowers_coverage`;
  `higherPersistence_no_effect`;
  `no_universal_persistence_increase`; and
  `no_universal_persistence_decrease`.
- **`#print axioms` result:** The focused audit prints all 19
  publication-facing definitions and declarations.
  `advantageRegion`, `currentAdvantageGap`, `otherAdvantageGap`, and
  `constantAdvantageGap` report `[propext, Quot.sound]`; every other printed
  object reports `[propext, Classical.choice, Quot.sound]`.
- **Julia implementation validation:**
  `persistence_coverage_response_surface` and
  `run_kernel_persistence_response.jl` evaluate 135 exact
  `Rational{BigInt}` rows: nine persistence values, five effective discounts,
  and three gap locations at horizon two. The registered witness values match
  Lean exactly, and the full surface checks the expected positive, negative,
  and zero directions together with their positive-gap occupation channels.
- **Manuscript location:** Appendix C gives the compact persistence ambiguity,
  states the occupation-alignment theorem and exact opposite effects, and
  supplies the finite-sum expansion and substitutions.
  Numerical response surfaces are kept separate in the experiments.
- **Status:** Lean verified; exact Julia response surface validated
- **Informal mathematical validity:** The positive theorem is finite
  distributivity plus multiplication by nonnegative gaps. The exact two-state
  calculations refute both possible universal monotonicity directions.
- **Lean kernel verification:** The focused 19-command audit and namespace
  linter pass. The comprehensive audit and clean root build are recorded in
  the pre-manuscript audit above.
- **Empirical relevance:** Not assessed; S7 is a finite mathematical
  comparative-static boundary.

### C1 — Complementary-project multi-gap counterexample

- **Theorem ID:** C1
- **Manuscript label:** Candidate counterexample C1
- **Informal statement:** An exact finite two-project construction shows that
  joint innovation value need not be bounded by the sum of isolated project
  values.
- **Exact assumptions:** the legacy A-T6-SINGLE model deliberately relaxed to
  allow two candidates, repeated attempts, or module complementarity; current
  publication-facing T6 is not a dependency.
- **Lean declaration name:** None.
- **Lean file:** None.
- **Proof dependencies:** finite-horizon value definition and
  CX-MULTIGAP-ADDITIVITY-01; it does not require T6's theorem proof.
- **`#print axioms` result:** Not run; no declaration exists.
- **Julia test or experiment counterpart:**
  `multi_gap_additivity_witness()` in
  `julia/scripts/search_counterexamples.jl`: joint value $1/4$, each isolated
  value $0$.
- **Manuscript location:** Planned coverage appendix; no result text exists in
  the buildable manuscript scaffold.
- **Status:** revised, numerically validated
- **Informal mathematical validity:** Exact rational witness found and reduced
  to one belief, three strategies, one module, and two projects.
- **Lean kernel verification:** Not started.
- **Julia implementation validation:** Exact regression passed.
- **Empirical relevance:** Not applicable; this is a formal boundary example.

### C2 — One-project multi-gap disconnected cost-covering set

- **Theorem ID:** C2
- **Manuscript label:** Counterexample `cx:multi-gap-disconnection`
  (supporting limitation result)
- **Desired statement:** A project that fills separated strategy-library gaps
  can have gross coverage value above research cost on separated belief
  regions, so a general connected multi-gap cost-covering theorem is false.
- **Verified statement:** On `Fin 5`, one project has two candidate outcomes
  with certified gaps `(4,0,0,0,0)` and `(0,0,0,0,4)` over the zero frontier.
  Under the degree-four Bernstein/binomial transition kernel, their aggregate
  one-shot gross coverage potential is exactly
  `(4,41/32,1/2,41/32,4)`. Constant cost one gives the strict cost-covering set
  `Icc 0 1 ∪ Icc 3 4`, which is not order-connected.
- **Exact assumptions:**
  1. The belief carrier is `Fin 5` with its finite linear order.
  2. There is one project and two candidate outcomes, both members of the
     project's finite candidate set.
  3. The existing library frontier is zero. Candidate value therefore equals
     certified positive-part gap, and the two exact gap supports are the
     disjoint endpoint intervals `Icc 0 0` and `Icc 4 4`.
  4. Aggregate project gap is the exact sum of the two disjoint candidate
     gaps, `(4,0,0,0,4)`.
  5. `transitionKernel` is the exact rational degree-four Bernstein/binomial
     kernel. Every entry is nonnegative and every finite row sums to one.
  6. Discount and survival are both one, so `coveragePotential` is the exact
     one-shot gross finite expectation of aggregate gap.
  7. Research cost is exactly one at every belief, and coverage uses the
     strict comparison `cost b < coveragePotential b`.
- **Assumption reconciliation:** Items 1--7 are exactly
  A-C2-MULTIGAP-WITNESS and appear definitionally in `MultiGapRegion.lean`.
  No continuous belief interval, raw project
  generation/verification/admission process, net forced-action identity, or
  universal multi-gap topology statement is encoded.
- **Lean declarations:**
  `StrategyInnovation.Counterexamples.MultiGapRegion.project_fills_two_separated_strategyLibraryGaps`,
  `coveragePotential_eq`, `strictCostCoveringSet_eq`, and
  `separatedMultiGap_disconnectedCostCoveringSet`.
- **Lean file:**
  `formal/StrategyInnovation/Counterexamples/MultiGapRegion.lean`.
- **Proof audit file:**
  `formal/StrategyInnovation/Audit/MultiGapRegion.lean`.
- **Exact fixture:**
  `formal/StrategyInnovation/Fixtures/MultiGapRegion.lean`, generated by the
  Julia audit.

| Lean declaration | Exact role | `#print axioms` result |
|---|---|---|
| `StrategyInnovation.Counterexamples.MultiGapRegion.project_fills_two_separated_strategyLibraryGaps` | one project supplies two disjoint certified gaps | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Counterexamples.MultiGapRegion.coveragePotential_eq` | exact matrix--gap product | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Counterexamples.MultiGapRegion.strictCostCoveringSet_eq` | exact two-interval strict one-shot set | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Counterexamples.MultiGapRegion.separatedMultiGap_disconnectedCostCoveringSet` | packaged required limitation | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Counterexamples.MultiGapRegion.constantGapPotential_eq` | constant gap is fixed by the kernel | `[propext, Classical.choice, Quot.sound]` |
| `StrategyInnovation.Counterexamples.MultiGapRegion.unrestrictedCost_defeats_generalComponentBound` | unrestricted-cost topology boundary | `[propext, Classical.choice, Quot.sound]` |

- **Counterexamples outside stronger assumptions:** C2 itself is
  CX-MULTIGAP-REGION-01. CX-TOPOLOGY-COST-01 uses the same kernel with constant
  gap/potential `(2,2,2,2,2)` and cost `(0,3,0,3,0)`; the positive gap has one
  component but the strict cost-covering set `{0,2,4}` has three. Thus kernel
  variation diminution alone cannot bound net-region components under
  unrestricted costs.
- **Optional topology decision:** Exact Julia checks found all 251 square
  minors nonnegative, no sign-variation increase among 3,125 vectors over
  `{-2,-1,0,1,2}`, and no strict-superlevel component increase among 28,125
  enumerated gap--threshold cases. These finite searches do not prove a
  universal theorem. Pinned mathlib has no reusable finite total-nonnegative
  matrix/variation-diminishing development, so criterion 3 (realistic finite
  Lean proof) failed. `Coverage/TopologyBound.lean` was not created, and no
  topology theorem is a manuscript claim.
- **Julia counterpart:** `project_gap`, `gross_coverage_value`,
  `cost_covering_set`, and `connected_components` in
  `julia/src/Coverage.jl` reproduce C2 directly. The legacy
  `research_region` name remains a compatibility wrapper. The earlier
  `julia/scripts/search_multi_gap_topology.jl`, configured by
  `experiments/configs/multi_gap_topology.toml`, retains the minor/sign/
  component audit and writes the exact Lean fixture.
- **Manuscript location:** Appendix C gives the switching and occupancy
  boundary and states the exact five-grid-point
  `cx:multi-gap-disconnection` witness and
  `cx:arbitrary-cost-components`.
- **Headline-worthiness:** No. It is a clean, required limitation result and a
  useful boundary for coverage claims, not a standalone headline theorem.
- **Status:** Lean verified; exact Julia audit passed; optional topology
  theorem rejected
- **Informal mathematical validity:** Exact rational matrix multiplication and
  finite-order separation.
- **Lean kernel verification:** Passed under Lean 4.32.0 and pinned mathlib.
  All registered declarations report only
  `[propext, Classical.choice, Quot.sound]`; no generated native-decision or
  user-declared axiom remains.
- **Julia implementation validation:** Exact `Rational{BigInt}` reusable-API
  witness, stochastic-row, minor, sign-variation, superlevel-component, and
  arbitrary-cost regressions passed. The deterministic geometry run exports
  the exact potential and region beside a Float64 connected comparison.
  Controlled family F independently reuses the exact C2 gap, potential, strict
  region, and two-component count in the unified mechanism suite.
- **Empirical relevance:** Not assessed; C2 is an exact finite mathematical
  boundary example.

### N4 — Unified Julia comparative-statics engine

- **Theorem ID:** N4
- **Manuscript label:** Numerical diagnostic N4, not a theorem.
- **Informal statement:** A deterministic Julia engine evaluates all twelve
  registered unified-model primitive axes and reports value, innovation,
  policy, compression, descendant-quality, interaction, and numerical-error
  diagnostics from one raw-derived parameterization.
- **Exact assumptions:** Exact fixtures use `Rational{BigInt}` and construct
  the public `RawInnovationProcess`, including raw generation, primitive
  verification, the derived admitted law, insertion-only update, validated
  belief-path/outcome completion coupling, positive elapsed duration,
  initiation cost, and active or suspended incumbent operation. Larger
  response surfaces use an explicit sparse Float64 compilation of the same
  catalog and law, with committed tolerances and iteration caps.
- **Lean declaration name:** None. N4 invokes existing exact Julia
  counterparts of T4, S2, T6, S6, S7, and T7 fixtures but adds no theorem and
  cannot alter their proof status.
- **Lean file:** None.
- **Proof dependencies:** None. Sign-check applicability is mapped to CS1,
  T5, S6, S7, and T7 assumptions, but the numerical checks do not prove those
  declarations.
- **`#print axioms` result:** Not applicable.
- **Julia test or experiment counterpart:**
  `julia/src/ComparativeStatics.jl`,
  `julia/scripts/run_unified_comparative_statics.jl`,
  `julia/test/test_comparative_statics.jl`, and
  `experiments/configs/unified_comparative_statics.toml`.
- **Reported outcomes:** total and passive value, research-option premium,
  operational and generative insertion value, base-library research
  frequency, optimal reference action, numerical Bellman cutoff,
  frontier-only pruning loss, exact safe-compression ratio, descendant
  quality, and finite frontier--closure cross-difference $J$.
- **Numerical gates:** Every Float64 solve reports the Bellman residual, the
  residual-based posterior bound using contraction modulus $\beta$,
  iterations, convergence, sparse-storage status, and pass/fail gates.
  Exact policy iteration requires zero rational Bellman and policy-equation
  residuals on the S2 fixture.
- **Sign boundary:** Frontier, cost, admission, survival, closure-dominance,
  and finite patience--survival checks run only under their displayed
  one-at-a-time conditions. Persistence reports S7's no-universal-sign flag.
  Active-operation delay reports a missing no-waiting-gain certificate. The
  Bellman cutoff is not S5's one-shot cutoff. T7's sign is inapplicable
  without relative action saturation even when the generator is
  frontier-independent. Nonzero frontier dependence raises an explicit CS1
  boundary flag.
- **Exact fixtures:** FX-T4-UNIFIED-01 gives pruning loss one;
  FX-S2-UNIFIED-STATIONARY-01 gives base/descendant values two/four with
  Research/Continue and zero residuals; FX-T6-CARRIER-01 gives bound one;
  FX-S6-CROSS-01 reproduces
  $(43771/55296,24869/27648)$; FX-S7-PERSISTENCE-01 reproduces the
  raise/lower/no-effect six-tuple; FX-T7-SUBSTITUTION-01 gives $J=-1$; and
  CX-T7-INDEPENDENT-MENU-SWITCH-02 gives $J=1/2$.
- **Generated artifacts:** 78 one-at-a-time sparse Float64 rows, 36
  frontier--closure cells, 11 sign-check rows, eight exact fixture rows, one
  JSON summary, two data-linked publication SVGs, and the compact policy-map
  diagnostic generated directly from selected surface rows.
- **Manuscript location:** Appendix C summarizes the supporting comparative-
  static boundaries. The policy map and selected one-at-a-time sparse solves
  are in Appendix E; complete response surfaces and the full diagnostic data
  remain in the online supplement and registered experiment artifacts.
- **Status:** exact fixtures and deterministic sparse numerical surfaces
  validated
- **Informal mathematical validity:** N4 is executable finite computation
  with explicit assumptions and hard numerical gates, not a mathematical
  theorem.
- **Lean kernel verification:** Not applicable to N4. The cited theorem
  families retain their separate existing Lean audits.
- **Julia implementation validation:** Exact/raw and Float64/sparse canonical
  values and actions agree on the one-belief fixture. Parameter validation,
  raw-source routing, safe compression, residual/error failure, determinism,
  sign applicability, counterexample flags, serialization, SVG structure,
  and committed artifact drift are tested.
- **Empirical relevance:** Not assessed.

### N5 — Randomized finite-library robustness diagnostic

- **Theorem ID:** N5
- **Manuscript label:** Randomized robustness diagnostic N5, not a theorem.
- **Informal statement:** A registered complete-factorial generator of small
  exact raw libraries measures how often frontier-only pruning destroys
  future value, how innovation-safe and frontier-only compression differ, and
  which interaction signs occur on raw-realizable four-corner rectangles.
- **Exact assumptions:** 1,024 registered trials; complete binary cross of
  frontier density, module overlap, module complementarity, project cost,
  duration, admission, and persistence; eight replicates per principal cell;
  four raw libraries per interaction in one catalog and module system; two
  candidate projects; horizon four; discount $3/4$; StableRNG master seed
  `6075990691714899803`; all recorded component seeds; exact
  `Rational{BigInt}` arithmetic.  The earlier 90-trial, twelve-factor,
  marginally balanced design with master seed `6073180304494120243` is a
  frozen pilot and is not pooled.
- **Registered successor execution:** N5-v2 fixes 1,024 trials as eight
  replicates of the complete binary cross of frontier density, module overlap,
  module complementarity, project cost, duration, admission, and persistence.
  Every interaction observation must use four actual raw libraries built by
  commuting frontier and closure additions in one catalog. Master seed
  `6075990691714899803` and all 4,096 permitted component seeds were recorded
  before outcomes. The initial design lock is
  `0b012dfc14f4ea57b0d34877a68d9a546cd499d2270903e772d78b21425d14db`.
  A pre-outcome sequential-precision amendment fixes cumulative snapshots at
  50/100/200/300/500/750/1000/1024, with the final estimate still required to
  use all 1,024 trials. Its aggregate design lock is
  `d9122d258b8fe62d5872c41b0a418b1351a5798b25ddb99ec73b726e324d244f`.
  A second prospective amendment fixed the executable raw generator, audit
  contract, and two extra source tables under aggregate SHA-256
  `8c278c07d998ba118d98c78cc1373a47ab63127f00d606c0042c006dac11e7be`
  before any registered outcome existed. The complete $N=1024$ run and its
  byte-identical `--check` replay have since passed every hard gate.
- **Lean declaration name:** None. N5 is randomized economic-relevance
  evidence and must not be cited as proof or validation of a Lean theorem.
- **Lean file:** None.
- **Proof dependencies:** None. T3, T4, T5, and T7 motivate the measured
  mechanisms but retain their separate Lean assumptions and audits.
- **`#print axioms` result:** Not applicable.
- **Julia test or experiment counterpart:**
  `julia/src/RandomizedLibraries.jl`,
  `julia/scripts/run_randomized_library_stress.jl`,
  `julia/test/test_randomized_libraries.jl`, and
  `experiments/configs/randomized_library_stress.toml`. The locked v2
  pre-outcome counterparts are `RANDOMIZED_DESIGN_V2.md`,
  `experiments/configs/randomized_library_stress_v2.toml`,
  `experiments/randomized_library_v2/TRIAL_REGISTRY.csv`,
  `experiments/randomized_library_v2/DESIGN_LOCK.json`,
  `julia/scripts/lock_randomized_library_design_v2.jl`, and
  `julia/test/test_randomized_design_v2.jl`. The locked stability counterparts
  are `RANDOMIZED_DESIGN_V2_AMENDMENT_1.md`,
  `experiments/configs/randomized_library_stability_amendment_1.toml`,
  `experiments/randomized_library_v2/DESIGN_LOCK_AMENDMENT_1.json`,
  `julia/src/RandomizedStability.jl`, and
  `julia/test/test_randomized_stability.jl`. The prospective execution and
  completed-run counterparts are `RANDOMIZED_DESIGN_V2_AMENDMENT_2.md`,
  `experiments/configs/randomized_library_execution_amendment_2.toml`,
  `experiments/randomized_library_v2/DESIGN_LOCK_AMENDMENT_2.json`,
  `julia/scripts/randomized_library_v2_core.jl`,
  `julia/scripts/run_randomized_library_stress_v2.jl`,
  `julia/scripts/audit_randomized_library_v2_results.jl`, and
  `julia/test/test_randomized_libraries_v2_execution.jl`.
- **Pruning rules:** deterministic rechecked frontier-only deletion;
  deterministic rechecked frontier-and-closure-safe deletion; cumulative 10%
  source-passive-value loss budget; and cumulative 5%
  source-option-premium loss budget.
- **Reported outcomes:** v1 and v2 separately report frontier-loss frequency
  and magnitude; exact signed
  operational, generative, and total losses; operationally redundant but
  generatively valuable carrier frequency; library reduction; and
  frontier--closure substitution/complementarity frequencies. V1 uses its
  disclosed synthetic rectangle; every v2 interaction uses four realizable
  raw libraries and actual closure-derived project laws.
- **Generated artifacts:** complete trial, pruning, carrier, profile,
  module-incidence, closure-table, kernel, and project CSVs; method and factor
  summaries; JSON metadata; `RANDOMIZED_LIBRARY_REPORT.md`; and three
  publication SVGs. V2 adds complete rectangle corners and transitions,
  raw-witness, action, interaction-sign, relationship, cumulative-stability,
  and factor-stability tables; `RANDOMIZED_LIBRARY_REPORT_V2.md`; and four
  publication SVGs.
- **Manuscript location:** Section 7 reports only the registered optimization
  extension's global compression ratio, greedy gap, frontier-only dynamic and
  normalized loss, capacity pattern, breakpoint counts, and elasticity
  summaries. Appendix E retains the parent study's raw-realizability gate,
  estimands, structural outcomes, sequential diagnostics, and the only v1/v2
  comparison; it omits the pilot's non-raw-witnessed interaction statistic.
  The online supplement indexes the full cumulative, factor-stratified, and
  optimization-extension sources. No theorem statement consumes N5.
- **Status:** v1 frozen pilot validated and unmodified; v2 exact randomized
  robustness diagnostic completed at the registered $N=1024$
- **Informal mathematical validity:** Every within-trial probability, payoff,
  Bellman value, and decomposition is exact. Randomization selects finite
  instances; it supplies no deductive inference.
- **Lean kernel verification:** Not applicable. The experiment does not
  generate Lean source or alter a theorem ledger status.
- **Julia implementation validation:** Frontier-only passive preservation,
  innovation-safe total-value preservation, both approximation budgets, and
  every loss decomposition are exact hard gates. The frozen pilot has 90
  trials and 360 pruning rows; targeted tests pass 102 checks; an independent
  CSV audit reconciles all denominators and complete source-table row counts.
  The v2 lock validator confirms 1,024 preassigned rows, all 128
  principal cells, eight replicates per cell, exact factor/cell/theorem-regime
  balance at prefixes 256/512/768/1024, 4,096 distinct recorded component
  seeds, disjoint v1/v2 output paths, current frozen-pilot hashes, and the
  aggregate lock. The amendment validator additionally fixes eight sequential
  prefixes, eight cumulative estimands, all fourteen registered factor-level
  slices, exact counts/sums/means/sample variances, descriptive Wilson
  intervals, presentation-only mean MCSEs, and deterministic sparse-support
  warnings. The execution freezes all generator and serialization choices
  before outcomes. The completed run contains 1,024 trial rows, 4,096 raw
  corners, 150,882 derived transitions, 4,096 pruning rows, and 47,458 raw
  witness rows. Every compressed state has a raw witness, every rectangle has
  four valid raw corners, raw/compressed values agree, innovation-safe loss is
  exactly zero in all five required components, signed decompositions close,
  displayed theorem flags are mechanical, and all theorem-facing outputs are
  `Rational{BigInt}`. The deterministic replay is byte-identical and a
  separate result-reader audit reconciles all exact counts and frozen-pilot
  hashes.
- **Empirical relevance:** Frontier-only pruning loses future value in 8/90
  trials and operationally redundant/generatively valuable carriers occur in
  3/360 source-carrier observations. These are generator-conditional
  frequencies, not population estimates. Among 45 genuine closure contrasts,
  the synthetic $J$ diagnostic records 13 substitution and zero
  complementarity cases. In the separate v2 run, frontier-only positive loss
  occurs in 398/1024 trials, silent generative assets in 388/5120 asset
  observations, and the realizable rectangles record 256 substitution, 141
  complementarity, and 627 zero interactions. Among the 512 mechanically
  eligible primitive rows, no positive interaction occurs. These are
  generator-conditional simulation diagnostics and do not alter any theorem
  status.

### N6 — Approximate library-compression numerical analysis

- **Theorem ID:** N6
- **Manuscript label:** Numerical extension N6, not a theorem.
- **Informal statement:** For a fixed finite raw model, reference belief, and
  horizon, minimize retained library cardinality subject to bounds on the
  worst operational-frontier loss and signed generative loss, and map the
  exact and heuristic size--loss trade-off.
- **Exact assumptions:** The registered benchmarks use the exact trial-15 raw
  catalog, horizon four, reference belief one,
  $\epsilon_{\mathrm{op}}=1$, and
  $\epsilon_{\mathrm{gen}}=1/4$. The base source has six strategies; the
  expanded source admits both already-declared catalog candidates and has
  eight. All probabilities, payoffs, Bellman values, losses, feasibility
  comparisons, and Pareto comparisons use `Rational{BigInt}`.
- **Definitions:** $\operatorname{OpLoss}(L')$ is the maximum source-minus-
  compressed frontier gap over the finite belief space. $W_H$ is the
  frozen-library passive operating value. `ValueLoss` is the source-minus-
  compressed unified raw Bellman value, and `GenLoss` is `ValueLoss` minus
  the corresponding $W_H$ loss. `GenLoss` is signed and is never clipped.
- **Lean declaration name:** None. N6 is numerical only.
- **Lean file:** None.
- **Proof dependencies:** None. Existing compression and value theorems
  motivate the estimands but do not prove the numerical optimizer or any
  heuristic approximation factor.
- **`#print axioms` result:** Not applicable.
- **Julia test or experiment counterpart:**
  `julia/src/ApproximateCompression.jl`,
  `julia/scripts/run_approximate_compression.jl`,
  `julia/test/test_approximate_compression.jl`, and
  `experiments/configs/approximate_compression.toml`.
- **Methods:** Complete bit-mask enumeration for small libraries; exact
  three-criterion Pareto enumeration; four deterministic backward-deletion
  scores and multistart selection; a width-controlled Pareto beam; and an
  operational set-cover 0--1 formulation with exact Bellman-oracle no-good
  cuts. Only complete enumeration receives an optimality certificate.
- **Generated artifacts:** 160 complete subset rows, 16 exact Pareto rows,
  20 algorithm rows, two 0--1 formulation summaries, one JSON summary,
  `APPROXIMATE_COMPRESSION_REPORT.md`, and two publication SVGs.
- **Numerical result:** The six-strategy source compresses exactly to three
  strategies with zero operational, generative, and total-value loss. The
  expanded eight-strategy source compresses exactly to two strategies with
  operational loss $1/2$, generative loss zero, and total-value loss
  $2025/8192$. The operational-cover lower bound is two in both cases; 11
  generative no-good cuts lift the base optimum from two to three.
- **Manuscript location:** No theorem statement consumes N6. The standalone
  report and figures are publication-supporting numerical artifacts.
- **Status:** exact numerical extension and deterministic heuristics validated
- **Informal mathematical validity:** All displayed finite calculations and
  decompositions are exactly reproducible; no general approximation claim is
  inferred from them.
- **Lean kernel verification:** Not applicable. No Lean file or theorem status
  changes.
- **Julia implementation validation:** The targeted suite checks definitions,
  exact optimality and Pareto dominance, deterministic heuristics, complete
  and partial 0--1 formulations, decomposition and budget gates, expanded
  benchmark results, serialization, figure structure, and artifact drift.
- **Empirical relevance:** Not assessed. The two registered catalogs are
  numerical benchmarks, not a population sample.

### N7 — Exact resource-optimization claim audit

- **Theorem ID:** N7
- **Manuscript label:** Exact optimization counterexample audit, not a
  theorem.
- **Informal statement:** Exhaustive small finite-library search attacks 14
  proposed resource-optimization claims, minimizes exact witnesses, and
  records the theorem revision forced by each result.
- **Exact assumptions:** Implicit zero-burden inactive strategy; one or more
  active strategies with positive `Rational{BigInt}` weights; finite
  bit-mask libraries; identity closure in the minimized witnesses; exact
  operational profiles; and a productive value table monotone under raw
  inclusion. Search bounds and lexicographic objectives are versioned in the
  configuration.
- **Lean declaration name/file:** None.
- **`#print axioms` result:** Not applicable.
- **Julia counterpart:** `julia/src/ResourceOptimization.jl`,
  `julia/scripts/search_resource_optimization_counterexamples.jl`, and
  `julia/test/test_resource_optimization.jl`.
- **Generated artifacts:**
  `experiments/results/resource_optimization_claim_audit.json` and 14
  per-target JSON fixtures in
  `experiments/results/resource_optimization_fixtures/`.
- **Result:** 13 counterexamples and one survivor. The survivor is
  set-valued penalized-burden antitonicity; a separate strict example shows
  that burden can fall. The failed targets cover pruning optimality, greedy
  optimality, order independence, local-to-global inference, capacity
  concavity and diminishing returns, raw-inclusion nesting, breakpoint
  uniqueness, no-deletion replacement, strong Lagrangian equivalence,
  closure-cardinality elasticity, zero-margin elasticity bounds, and global
  differentiability.
- **Status:** exact Julia validated; theorem statements revised; no Lean
  verification and no empirical interpretation.
- **Formalization consequence:** only the surviving statements recorded in
  this ledger may proceed to Lean.

### N1 — Julia value-iteration convergence diagnostics

- **Theorem ID:** N1
- **Manuscript label:** Numerical diagnostic N1, not a theorem
- **Informal statement:** Numerical reporting item for value-iteration
  residuals, iteration counts, contraction bounds, exact small-instance
  agreement, and dynamic research-policy sensitivity.
- **Exact assumptions:** The main six-state diagnostic is derived from the
  unified positive-duration raw law: finite raw catalog and raw-library set,
  explicit capability module, raw generation and verification, exact joint
  belief-path/admission laws, deterministic raw updates, active-operation
  flags, and terminal beliefs generated through $P^{d(q)}$. Exact small
  instances use `Rational{BigInt}`; larger sparse solves use explicit Float64
  tolerances and iteration caps. Primitive F5/F8 timing is retained only in a
  legacy regression fixture.
- **Lean declaration name:** The Float64 convergence diagnostic remains
  numerical. Its exact rational benchmark inputs and outputs are checked by
  the twelve
  `StrategyInnovation.Projection.Model.UnifiedCanonicalFixture.*`
  declarations registered under S2, including
  `stationaryValue_bellmanFixedPoint`,
  `exactPolicyEvaluationResidual_eq_zero`, and `optimalActions_unique`.
- **Lean file:**
  `formal/StrategyInnovation/Fixtures/UnifiedCanonical.lean`.
- **Proof dependencies:** Exact finite enumeration of the two beliefs, eight
  raw libraries, three compressed states, four admitted outcomes, and full
  one- and two-period belief paths; rational arithmetic; deterministic raw
  insertion; and the declared stationary table. The Float64 stopping rule and
  convergence history are not encoded as Lean claims.
- **`#print axioms` result:** The 36-command focused fixture audit reports
  either no axioms or only `[propext, Classical.choice, Quot.sound]`; no
  user-declared axiom or placeholder occurs.
- **Julia test or experiment counterpart:**
  `julia/scripts/solve_unified_canonical_benchmark.jl` provides the main
  raw-derived exact/Float64 canonical solve; the deprecated
  `julia/scripts/solve_canonical_model.jl` preserves the primitive F5/F8
  regression. The active compact policy map is generated from
  `unified_comparative_statics_surface.csv`; its selected 41-belief
  cost/duration/discount rows are raw-derived, strictly positive-duration,
  converged, and within the registered numerical gates. Controlled family G's
  older 61-belief map remains a regression artifact only.
- **Manuscript location:** Section 6 reports the raw-derived six-state
  catalog, libraries, joint path law, transition pushforward, exact stationary
  values/actions/margins, resource weights and optima, and Float64
  residual/error comparison. The unified 41-belief finite-grid policy map
  `fig:dynamic-research-policy-regions` is retained only in Appendix E.
  Appendix D gives the contraction/selector proof, stopping rule and bounds,
  the 42-row unified convergence plot `fig:canonical-convergence`, and the
  full exact action-value table.
- **Status:** numerically validated; exact rational canonical subclaims Lean
  checked
- **Informal mathematical validity:** Not a theorem; the main diagnostics
  implement the unified S2 residual and contraction calculations on a declared
  finite raw-derived process.
- **Lean kernel verification:** The raw probability and pushforward laws,
  duration/path timing, operating blocks, registered finite-horizon
  correspondence, stationary value/action table, lifted raw policy equation,
  zero rational residual, and strict action uniqueness are kernel checked.
  The 42-step Float64 trajectory, its Float64 a-posteriori contraction bound,
  and the exactly re-evaluated residual-based certificate remain Julia
  evidence only.
- **Julia implementation validation:** Unified raw and compressed exact policy
  iteration converge in three iterations, agree on all raw representatives,
  and have exact zero Bellman residual. The selected policy's exact stationary
  evaluation is identical. Float64 value iteration converges in 42 iterations,
  chooses the identical six actions, and its exact rationalization lies within
  the exactly re-evaluated residual-based certificate. All twelve controlled
  policy scenarios also converge; that separate experiment records iteration
  counts, residuals, posterior bounds, regions, and cutoffs. All of these are
  numerical diagnostics rather than proof.
- **Empirical relevance:** Not assessed.

### E1 — Locked terminal financial audit

- **Theorem ID:** E1
- **Former identifier:** N2.
- **Manuscript label:** Locked terminal audit; not a theorem.
- **Informal statement:** A finite 2,400-strategy ETF grammar can be used to
  audit current-frontier preservation, candidate enablement, validation-only
  candidate ranking, and operational--generative accounting without treating
  backtest profitability as the research claim. Its $Q_a$ quantity is ex
  post enabled-descendant opportunity quality computed from held-out audit
  outcomes, not a pruning input or forecast.
- **Exact assumptions:** Fixed 25-ETF universe comprising 24 stable-identifier
  ORATS-covered ETFs plus SHY and committed date-valid PERMNOs; SMH excluded
  rather than spliced across two different CRSP funds; licensed CRSP snapshot;
  development 2009--2014, validation 2015--2019, retrospective locked
  illustration 2020--2024; close-only signals with two-return-index lag;
  long-only finite grammar; 5 bp one-way turnover cost; declared module-union
  closure; deterministic seed `6075990691714899801`.
- **Lean declaration name:** Not applicable. This is an empirical/numerical
  illustration and must not be cited as kernel verification.
- **Lean file:** None.
- **Proof dependencies:** None. The hard identities are runtime checks of the
  selected finite instance, not general proofs.
- **`#print axioms` result:** Not applicable.
- **Julia test or experiment counterpart:**
  `julia/scripts/prepare_financial_terminal_audit_data.jl`,
  `julia/scripts/run_financial_terminal_audit.jl`, and
  `julia/test/test_financial_terminal_audit.jl`. The aggregate-only compression
  presentation is validated by
  `julia/scripts/generate_manuscript_numerical_artifacts.jl` and
  `julia/test/test_financial_compression_focus.jl`.
- **Manuscript location:** The generated source draft
  `manuscript/sections/financial_terminal_audit.tex` is retained as an audit
  artifact. Section 7 presents the locked terminal audit with the annual
  walk-forward audit in `fig:financial-safe-compression`. The locked coverage
  ranking and `fig:supp-financial-coverage-comparison` are online-supplement
  artifacts.
- **Status:** empirically illustrated; aggregate outputs publishable
- **Informal mathematical validity:** Safe deletion is checked by exact
  equality up to the configured Float64 tolerance for both the validation
  frontier and module closure; decomposition totals are checked as accounting
  identities. The innovation-safe deletion acceptance test uses only frontier
  and closure equality, not $Q_a$. These checks instantiate but do not prove
  F3 or F6.
- **Information-set audit:** The validation frontier and structural closure
  are available at pruning time; only the former enters frontier-only
  acceptance and both enter innovation-safe acceptance. The structurally
  enabled candidate set is also derivable then but is not an acceptance test.
  Coverage scores are computed after compression from development/validation
  information and fixed in the terminal decision hash. Compression ratio,
  module uniqueness, and descendant dependence are retrospective structural
  descriptions. Locked net utility, $Q_a$, generative deletion contribution,
  support for the best descendant, and rank diagnostics require held-out
  outcomes. See `EMPIRICAL_INFORMATION_SET_AUDIT.md`.
- **Lean kernel verification:** Not applicable; no Lean claim is added.
- **Julia implementation validation:** The audited run used 106,975 source rows
  and 4,279 complete common dates. Frontier-only pruning preserved current
  validation value and reduced ex post enabled-descendant opportunity quality
  by about 0.00156. Innovation-safe compression reduced 80 strategies to 25
  with zero frontier and ex post opportunity-quality change. The exact
  source/frontier-only/safe closure counts are 38/12/38, and the retained-role
  counts are operational-only 3, generative-only 1, both 0, and neither 21.
  The locked
  outcomes used for $Q_a$ were first accessed after the library, pruning,
  rankings, and decision hash were fixed. Coverage ranking was negative: its
  frozen top-ten candidates underperformed the initial-library locked utility
  by about 0.156, versus about 0.0685 for the best comparator. The safely
  compressed library includes one currently dominated GLD module carrier with
  a positive generative component of about 0.00156 and zero operational
  component. It is the audit's only positive ex post generative carrier; 93 of
  2,320 enabled descendants depend on it, including the best enabled
  descendant. Every retained policy has module-uniqueness share
  $1/7$, so the requested high-versus-low uniqueness comparison is not
  identified. All adverse ranking results are retained. D-0042's prospective
  synthetic S4 construction neither modifies this run nor supplies a post-hoc
  empirical rescue.
- **Empirical relevance:** Mechanism illustration only. Licensed raw and
  row-level inputs are not distributed; project-authored aggregate artifacts
  are publishable and reviewers reproduce them with their own CRSP/WRDS
  access. The snapshot is not point-in-time certified, the universe is not
  survivorship-free, the holdout is retrospective, and no market-alpha claim
  is permitted. $Q_a$ is neither a forecast, policy score, nor deployable
  selection criterion; it is an ex post mechanism diagnostic.

### E2 — Annual walk-forward financial audit

- **Theorem ID:** E2
- **Former identifier:** N3.
- **Manuscript label:** Annual walk-forward audit; not a theorem.
- **Informal statement:** An outcome-blind 100-ETF universe and complete
  9,600-strategy finite grammar can test innovation-safe compression,
  frontier-only pruning loss, estimand-aligned marginal coverage, and
  operational--generative accounting across five historical walk-forward
  decisions without using portfolio return as the research claim. Its
  $Q_a$ quantity is ex post enabled-descendant opportunity quality computed
  from held-out audit outcomes, not a pruning input or forecast.
- **Exact assumptions:** Same-PERMNO ETF classification at 2008 and 2024
  endpoints; pre-return selection by 2009--2014 median dollar volume after
  declared identity/liquidity/complex-product gates; development 2009--2014,
  validation 2015--2019, annual locked illustrations 2020--2024; trailing
  five-year profiles and transitions; five SPY belief states; two-return-index
  execution lag; 5 bp one-way base cost with 1/10 bp sensitivities; sequential
  marginal top-five coverage; seed `6075990691714899802`.
- **Lean declaration name:** Not applicable. This is empirical/numerical
  evidence and must not be cited as kernel verification.
- **Lean file:** None.
- **Proof dependencies:** None. Runtime identities instantiate selected finite
  mechanisms but do not prove F3, F4, F6, or S4.
- **`#print axioms` result:** Not applicable.
- **Julia test or experiment counterpart:**
  `julia/scripts/audit_financial_annual_universe.jl`,
  `julia/scripts/prepare_financial_annual_walkforward_audit_data.jl`,
  `julia/scripts/run_financial_annual_walkforward_audit.jl`, and
  `julia/test/test_financial_annual_walkforward_audit.jl`. The aggregate-only
  compression presentation is validated by
  `julia/scripts/generate_manuscript_numerical_artifacts.jl` and
  `julia/test/test_financial_compression_focus.jl`.
- **Manuscript location:** The generated source draft
  `manuscript/sections/financial_annual_walkforward_audit.tex` is retained as an audit
  artifact. Section 7 presents the annual walk-forward audit with the locked
  terminal audit in `fig:financial-safe-compression`. The annual coverage
  ranking, its five-unit limitation, and
  `fig:supp-financial-coverage-comparison` are in the online supplement;
  descendant-quality levels are not
  compared across the two audits.
- **Status:** empirically illustrated; aggregate outputs publishable
- **Informal mathematical validity:** Innovation-safe deletion is a hard
  runtime identity for the validation frontier and module closure, and every
  deletion decomposition closes at the configured tolerance. The occupation
  target is deliberately aligned with the empirical coverage score, but the
  estimated profiles and transitions remain empirical inputs. The
  innovation-safe deletion acceptance test uses only frontier and closure
  equality, not $Q_a$.
- **Information-set audit:** The validation frontier and structural closure
  have the same pruning-time roles as in E1, while the enabled set is
  structurally available but not tested by either rule. Each coverage score
  uses only trailing information through $y-1$ and is fixed after
  compression in the year-$y$ decision hash. Compression ratio, module
  uniqueness, and descendant dependence are retrospective structural
  descriptions. Realized target-year coverage, $Q_a$, generative deletion
  contribution, support for the best descendant, rank diagnostics, and
  resampling inputs are held out. Greedy-oracle regret is an infeasible
  target-year oracle comparator. See `EMPIRICAL_INFORMATION_SET_AUDIT.md`.
- **Lean kernel verification:** Not applicable; S4 proves only the encoded
  fixed-candidate occupation identity and does not verify this estimator or
  ranking procedure.
- **Julia implementation validation:** The audited 427,900-row panel has 100
  funds and 4,279 complete dates. Frontier-only pruning reduced the initial
  library from 202 policies to 5, preserved current validation value, and
  lowered ex post enabled-descendant opportunity quality by 0.1020.
  Innovation-safe compression retained 100 policies with zero registered
  current and ex post opportunity-quality change. The exact
  source/frontier-only/safe closure counts are 113/14/113, and the retained-role
  counts are operational-only 5, generative-only 1, both 0, and neither 94.
  Each annual decision hash
  was fixed before its target-year outcome was accessed. Marginal
  coverage averaged 0.0704 versus 0.0119 for the best comparator, with three
  positive annual values, mean Spearman association 0.128, mean oracle regret
  0.315, and a five-year bootstrap interval [0.0190, 0.1187]. One dominated
  UNG carrier has operational value zero and generative value 0.0534. It is
  the audit's only positive ex post generative carrier; 94 of 9,398 enabled
  descendants depend on it, including the best enabled descendant. Every
  retained policy has module-uniqueness share $1/7$;
  maximum candidate dependence covers 98 of 100 policies, so neither
  characteristic supports a discriminating comparison.
- **Empirical relevance:** The broadened illustration supports the registered
  mechanisms but not a universal ranking theorem. Licensed rows are excluded;
  the universe remains survivorship-biased, inference uses only five annual
  units, the lock is retrospective, costs are simplified, and no alpha claim
  is permitted. $Q_a$ is neither a forecast, policy score, nor deployable
  selection criterion; it is an ex post mechanism diagnostic. The locked
  terminal audit remains separately adverse.

## Infrastructure-only verification

### I0 — Lean/mathlib smoke theorem

- **Theorem ID:** I0
- **Manuscript label:** Not a manuscript result.
- **Informal statement:** For every natural number `n`, `n + 0 = n`.
- **Exact assumptions:** One arbitrary `n : ℕ`; no hypotheses and no project
  model assumptions.
- **Lean declaration name:** `StrategyInnovation.smokeNatAddZero`
- **Lean file:** `formal/StrategyInnovation/Basic/Smoke.lean`
- **Proof dependencies:** Lean natural-number reduction and the pinned mathlib
  import environment; no research definition or theorem.
- **`#print axioms` result:** `'StrategyInnovation.smokeNatAddZero' does not
  depend on any axioms`
- **Julia test or experiment counterpart:** Not applicable; this checks only
  the Lean toolchain.
- **Manuscript location:** None. This declaration is intentionally excluded
  from the manuscript.
- **Status:** Lean verified
- **Informal mathematical validity:** Checked by definitional reduction.
- **Lean kernel verification:** Passed under Lean 4.32.0 and mathlib commit
  `81a5d257c8e410db227a6665ed08f64fea08e997`; proof is `rfl`.
- **Julia implementation validation:** Not applicable.
- **Empirical relevance:** Not applicable.

### I1 — Exact Lean–Julia fixture consistency bridge

- **Theorem ID:** I1
- **Manuscript label:** Not a manuscript result.
- **Informal statement:** Eighteen selected finite exact models have one
  deterministic Julia representation whose shared JSON expected outputs agree
  with reductions of the paired generated Lean definitions.
- **Exact assumptions:** Schema version `lean-julia-exact-fixture-v2`; exact
  rational transition rows and profiles; strictly positive unified project
  duration; exporter validation of stochasticity, identifiers, dimensions,
  discounts, costs, and references; thirteen claim-boundary records
  for raw/compressed transitions and values, safe deletion, normalized loss,
  decomposition, the generative bound, discount--survival interaction, both
  persistence directions, both frontier--closure signs, the monotone-gap
  threshold, and multi-gap disconnection, plus five migrated compatibility
  records preserving the earlier exact examples.
- **Lean declaration name:** No named theorem. The generated module contains
  anonymous `example` declarations so the infrastructure check cannot be
  mistaken for a reusable general result.
- **Lean file:**
  `formal/StrategyInnovation/Fixtures/Generated.lean`.
- **Proof dependencies:** Transparent finite-list evaluators, exact rational
  reduction, and ordinary `simp`/`norm_num` tactics.
- **`#print axioms` result:** Not applicable to anonymous examples. The module
  builds with no `sorry`, `admit`, user-declared axiom, `native_decide`, or
  hidden placeholder and is imported by the formal root.
- **Julia test or experiment counterpart:**
  `julia/scripts/export_exact_fixtures.jl` and
  `julia/test/test_exact_fixture_bridge.jl`; 110 deterministic checks validate
  rendering, exact outputs, invalid inputs, and committed-file agreement.
- **Manuscript location:** None.
- **Status:** infrastructure verified
- **Informal mathematical validity:** Each fixture identity is independently
  evaluable by finite exact arithmetic. Fixture agreement validates
  implementation correspondence on the selected inputs; it neither replaces
  general proof nor makes a universal claim.
- **Lean kernel verification:** The generated equality and inequality examples
  compile under Lean 4.32.0 and pinned mathlib.
- **Julia implementation validation:** All fixtures use
  `Rational{BigInt}`; byte-identical regeneration and semantic validation pass.
- **Empirical relevance:** Not applicable; no empirical or Float64 input is
  used.

## Record update protocol

Any future change to a statement or assumption must:

1. preserve the prior wording in Git history;
2. add a gap entry when the change was forced by formalization;
3. add or link a counterexample when possible;
4. update manuscript and Lean names together;
5. record exact assumption IDs line by line;
6. rerun Lean, `#print axioms`, Julia counterparts, and placeholder scans as
   applicable.
