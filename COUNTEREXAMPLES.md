# Counterexample Registry

## Current state

The exact finite gauntlet is complete for the locked publication-facing
T1--T7 statements under the unified semi-Markov convention. No in-assumption
counterexample was found. T6 was honestly narrowed before the final run: the
cost-free probability-times-gap conjecture is false, while the cost-adjusted
descendant-event bound survives under explicit operational-redundancy and
deleted-comparator assumptions. The requested T7 cross-difference theorem is
false under primitive frontier independence alone: optimized project switching
produces complementarity even when every fixed opportunity saturates.
Corrected T7 adds relative Bellman-action saturation. Frontier-dependent
generator quality supplies a separate complementarity mechanism. The
primitive common-gap corollary is narrower still: an added-project exposure
order does not imply all-pairs relative saturation when the poor menu already
contains a positive-exposure project, because rich-menu Continue supplies the
opposite pair.

This is computational and hand-checkable evidence for the full search record,
not Lean verification of every searched instance. T2 now additionally has
kernel-checked reduced boundary models for raw-identifier dependence and
behaviorally invisible closure. The exact search models and all displayed values are committed in
`experiments/results/revision_counterexample_gauntlet.json` and checked by the
Julia regression suite.

## Unified semi-Markov search record

- **Experiment:** `paper1-unified-semi-markov-falsification-v1`
- **Arithmetic:** `Rational{BigInt}` throughout; no floating-point comparison
- **Seed:** `6073180304494120242` (`StableRNGs.StableRNG`)
- **Random semi-Markov search:** 512 models with 1--3 beliefs, 2--5 strategies,
  1--3 modules, 1--3 projects, durations 1--3, both operation flags, and five
  exact discounts
- **T1:** 20,462 local updates, 10,869 joint raw/compressed transitions, and
  39,060 calendar-horizon value factorizations
- **T2:** 473 observable models and 21,848 full semi-Markov signature checks
- **T3:** the preserved exhaustive search reran 361,584 configurations and
  1,413,936 deletion checks
- **T5:** 19,468 exact premium-recursion identities
- **T6:** 512 descendant-event lower-bound comparisons
- **T7:** 5,230 frontier-order premium comparisons, including 10 checks on the
  explicit non-product completion fixture
- **Configuration:** `experiments/configs/revision_counterexample_gauntlet.toml`
- **Result:** `experiments/results/revision_counterexample_gauntlet.json`

Search survival is evidence within these finite bounds, not a proof. Each
boundary fixture also has a direct exact calculation independent of the
random property that it limits.

## Theorem disposition

| Claim | Classification | Required boundary or failed assumption |
|---|---|---|
| T1 raw-to-compressed projection | survives unified search | A-GEN-FACTOR and compressed-input coupling are essential; independence is not |
| T2 frontier--closure characterization | survives on observable models | A-T2-OBS is essential |
| T3 single-deletion iff | survives exhaustive search | batch deletion is a different and false inference |
| T4 normalized pruning-loss formula | Lean verified | exact \(\beta^d\rho^d\pi C-\kappa\); fixed cap is sharp and arbitrary loss requires scaling \(C\) |
| T5 operational--generative decomposition | Lean verified on the unified raw process | identity and silence results are exact; closure-only separability is false and premium monotonicity requires explicit project-action dominance |
| T6 generative-option lower bound | revised bound survives | naive bound failed by omitting cost; marginal carrier wording requires unchanged frontier and zero deleted-state premium |
| T7 frontier--closure substitutability | corrected theorem survives under relative action saturation | primitive independence alone permits project switching; frontier-dependent generator quality is a second complementarity channel |
| T7 primitive common-gap corollary | survives with zero poor-menu exposure and nonnegative rich exposure | added-project exposure order alone fails against rich Continue |
| Persistence comparative static | no universal direction | sign depends on where the candidate gap lies relative to the persistent state |
| Information and research demand | no universal direction | the candidate gap is neither generally convex nor concave in posterior belief |
| Delay operator with operation continuing | no universal raw-operator direction | sign depends on frontier rewards versus continuation; value monotonicity needs a fixed generator/coupling and value-consistent comparator |
| Negative-frontier delay claim | outside the adopted core | the inactive zero strategy makes every admissible frontier nonnegative |

Failed statements retain their exact witnesses. The cost-free T6 and the
frontier-independence-only T7 cross-difference form were rejected; their
revised assumptions and conclusions are registered in `ASSUMPTIONS.md`,
`FORMALIZATION_GAPS.md`, and `MODEL_SPEC.md`.

## Legacy feasibility record

The earlier `paper1-theorem-falsification-v1` remains valid for its pre-unified
oracle and old single-gap T6. It used seed `6073180304494120241`, 2,048 random
models, 4,096 single-gap models, 35,808 exhaustive T1 configurations, and the
same exhaustive T3 search. Its result is
`experiments/results/theorem_feasibility.json`; its data-only Lean fixture does
not prove a publication theorem.

## Exact reduced witnesses

### CX-T1-RAW-01 — Raw-library dependence beyond closure

- **Target:** T1 with A-GEN-FACTOR removed
- **Data:** one belief; strategies \(s_0,s_1,s_2\) with payoffs \(0,-1,1\);
  one unused module; identity belief transition; horizon two;
  \(\beta=1/2\); zero cost; perfect verification.
- **Libraries:** \(L=\{s_0\}\) and \(L'=\{s_0,s_1\}\). They have the same
  zero frontier and the same closure.
- **Nonfactored generator:** it creates \(s_2\) exactly when the dominated
  identifier \(s_1\) is literally present.
- **Check:** the values are \(0\) and \(1/2\), respectively.
- **Reduction:** one belief and one project are minimal; three strategies are
  required for a baseline, a dominated provenance identifier, and a profitable
  descendant.
- **Consequence:** T1 must retain A-GEN-FACTOR. This does not refute current T1.
- **Lean reduction:**
  `RawFrontierClosureCounterexamples.sufficiency_fails_when_generator_uses_raw_identifiers`
  gives equal frontier and closure but unequal exact candidate laws and
  unequal next-compressed-state laws under unit admission for a library-indexed
  generator. `rawIdentifierGenerator_not_factorized` proves that generator
  violates the accepted input restriction. This exact reduction targets
  forward T2 sufficiency as well as T1 factorization.

### FX-T1-CORRELATED-01 — Projection without conditional independence

- **Target:** the claim that T1 needs a product terminal law
- **Data:** two beliefs, a zero baseline, one candidate paying only at the
  second belief, one active duration-one project, \(\beta=1/2\), and belief
  marginal \((1/2,1/2)\). Admission is `none` with probability \(1/2\) and the
  candidate with probability \(1/2\).
- **Joint law:** all `none` mass is coupled to terminal belief one and all
  candidate mass to terminal belief two. Both required marginals are exact,
  but the joint law is not their product.
- **Check:** raw and compressed joint transitions and values agree through
  horizon three. The two-period value is \(1/4\); replacing the joint law by
  the product of the same marginals gives \(1/8\).
- **Reduction:** dependence requires at least two terminal beliefs and two
  outcomes; one project and one nonbaseline candidate suffice.
- **Consequence:** T1 must carry the joint law \(\Xi_q\), but it must not add
  conditional independence.

### CX-T1-MIN-T2-SILENT-01 — Behaviorally silent module

- **Targets:** generic minimality of \(K\); T2 without A-T2-OBS
- **Data:** one belief; \(s_0\) has payoff \(0\) and no module; \(s_1\) has
  payoff \(-1\) and module \(a\); identity closure; \(\beta=1/2\); a null
  project that always returns failure.
- **Libraries:** \(\{s_0\}\) and \(\{s_0,s_1\}\).
- **Check:** frontiers, one-step signatures, and values are equal, while
  closures are \(\varnothing\) and \(\{a\}\). Exact value equality was checked
  through horizon four and follows directly at every horizon because research
  is behaviorally null.
- **Reduction:** one belief, two total strategies, and one module are the
  carrier lower bounds for unequal closures with an unchanged frontier.
- **Consequence:** generic quotient minimality is false; the converse in T2
  requires the already-recorded observability assumption.
- **Lean reduction:**
  `RawFrontierClosureCounterexamples.converse_fails_when_closure_behaviorally_invisible`
  uses an exact raw process with every project unavailable. Its two libraries
  are UDI-equivalent with distinct closures, and
  `silentProcess_not_rawClosureDetectable` proves failure of A-T2-OBS. The
  unavailable-menu construction is the smallest direct witness for the
  availability-tagged final UDI relation.

### CX-T3-BATCH-01 — Individual versus simultaneous deletion

- **Target:** a batch extension of T3
- **Data:** one belief; payoffs \(j_{s_0}=0\) and
  \(j_{s_1}=j_{s_2}=-1\); both \(s_1,s_2\) supply the same single module \(a\);
  identity closure.
- **Check:** from the full library, deleting either \(s_1\) or \(s_2\) alone
  preserves both frontier and closure. Deleting both preserves the frontier
  but changes closure from \(\{a\}\) to \(\varnothing\).
- **Reduction:** two nonbaseline strategies are necessary for individual
  redundancy with joint necessity; one belief and one module suffice.
- **Consequence:** the exact single-deletion equivalence survives, including
  its converse. A batch algorithm must recompute the criterion after each
  deletion or prove a separate joint condition.

### CX-T4-BRIDGE-01 — Historical accumulated bridge-loss family

- **Target:** historical pre-formalization accumulated-loss version of T4
- **Data:** one belief; baseline and bridge payoff \(0\); descendant payoff
  \(1\); only the bridge supplies module \(a\); a zero-cost perfectly verified
  project creates the descendant iff \(a\) is in closure.
- **Parameters:** for rational target \(R\ge0\), choose the least tested
  integer \(n\ge2\) with \(n/2>R\), set \(H=n+1\), and
  \(\beta=1-1/n^2\).
- **Check:** deleting the bridge preserves the frontier and changes closure.
  Exact dynamic programming agrees with
  \[
    \operatorname{loss}=\sum_{t=1}^{n}\beta^t
    \ge n/2>R.
  \]
  Targets \(1,2,5,10\) were checked with
  \((n,H)=(3,4),(5,6),(11,12),(21,22)\).
- **Reduction:** one belief, one module, one project, and three strategies are
  the carrier minima for baseline, redundant bridge, and profitable child.
- **Consequence:** The fixture remains exact numerical evidence but is
  superseded as the theorem target. Current T4 uses the parameterized
  one-descendant formula \(\beta^d\rho^d\pi C-\kappa\).

### CX-T4-FIXED-01 — Fixed-parameter upper-bound guard

- **Target:** any fixed-\((\beta,H)\) unbounded-loss wording
- **Check:** if period payoff lies in \([0,1]\) and cost is nonnegative, the
  maximum difference between two \(H\)-period values is bounded by
  \(\sum_{t=0}^{H-1}\beta^t\).
- **Consequence:** Current T4 makes the fixed-cap sharp bound primary.
  Arbitrary additive loss is stated only after scaling the reward cap.

### CX-T5-SEPARABILITY-01 — Premium is not closure-only

- **Target:** a closure-only or interaction-free extension of T5
- **Data:** one belief, two strategies, one module, one deterministic
  zero-cost project, identity transition, horizon two, and \(\beta=1/2\).
  The two compared models have identical initial frontier, closure, generator,
  verification, and cost. The generated candidate payoff is \(1\) in one model
  and \(2\) in the other.
- **Check:** innovation premia are \(1/2\) and \(1\).
- **Consequence:** T5's insertion identity remains exact, but its premium
  necessarily interacts with descendant operational profiles. Closure
  inclusion alone cannot replace the explicit project-action dominance
  hypothesis used by the verified monotonicity theorem.

### CX-T6-COST-01 — Cost-free generative bound is false

- **Target:** \(V_h(L)-V_h(L^- )\ge \beta p\Delta\) with initiation cost
  omitted
- **Data:** one belief, inactive and zero-payoff module-carrier strategies,
  one payoff-one descendant, one active duration-one project, certain
  admission, horizon two, \(\beta=1/2\), and cost \(3/4\).
- **Check:** Continue is optimal, so the carrier's actual marginal value is
  zero. The naive cost-free right side is \(1/2\), hence \(0<1/2\). The
  revised right side is
  \(\max\{0,-3/4+1/2\}=0\), which is attained.
- **Reduction:** one belief, one project, one module, and the three necessary
  roles—baseline, carrier, descendant—are the carrier minima.
- **Failed assumption:** the conjecture omitted project cost. More generally,
  calling this a marginal carrier bound requires the carrier to leave the
  frontier unchanged and the deleted comparator to have zero innovation
  premium.
- **Revision:** current T6 is the cost-adjusted descendant-event bound under
  A-T6-CARRIER-BOUND.

### CX-T7-FRONTIER-GENERATOR-01 — Frontier-dependent quality creates complementarity

- **Target:** T7 without primitive generator independence
- **Data:** one belief, one active duration-one zero-cost project,
  \(\beta=1/2\), and a payoff-two descendant. Compare frontiers zero and one.
  Admission success is zero at the lower frontier and one at the higher.
- **Check:** innovation premium rises from zero to \(1/2\), even though the
  descendant's operational gap falls from two to one.
- **Reduction:** one belief, one project, one descendant, and two ordered
  frontier values are sufficient; no belief dynamics or module interaction is
  needed.
- **Failed assumption:** admission quality inspected the frontier.
- **Revision:** current T7 requires availability, cost, duration, operation,
  and the complete completion coupling to be frontier-independent primitives
  at every descendant closure.

### CX-CS-FRONTIER-OPPORTUNITY-01 — Frontier order needs fixed opportunities

- **Target:** full-value frontier monotonicity when research primitives may
  change with the frontier
- **Data:** one decision date. At the lower frontier zero, the research return
  is two, so value is two. At the higher frontier one, the research return is
  zero, so value is one.
- **Check:** \(0\le1\) but
  \(\max\{1,0\}=1<2=\max\{0,2\}\).
- **Failed assumption:** the feasible research opportunity changed with the
  frontier.
- **Lean declaration:**
  `ComparativeStatics.Counterexamples.frontier_mono_fails_without_fixed_opportunities`.

### CX-CS-HARMFUL-SUCCESS-01 — Admission and survival can have the wrong sign

- **Target:** unconditional monotonicity in admission or strategy survival
- **Data:** one positive-duration project, unit discount, zero cost and
  operating reward, failure continuation one, and success continuation zero.
- **Check:** raising either admission or survival from zero to one changes the
  exact binary candidate continuation from one to zero.
- **Failed assumption:** successful admission does not weakly dominate
  failure.
- **Lean declarations:**
  `admission_mono_fails_without_successDominance` and
  `survival_mono_fails_without_successDominance`.

### CX-CS-DELAY-NONNEGATIVE-01 — Positive operation can reverse the delay sign

- **Target:** delay antitonicity from nonnegative operation and nonnegative
  continuation alone
- **Data:** unified elapsed timing with
  \(\beta=1/2,\kappa=0,F_t=1,W=1\).
- **Check:** \(R_1=3/2<R_2=7/4\). Both the operating frontier and descendant
  continuation are nonnegative.
- **Failed assumption:** the added incumbent reward exceeds the discount
  opportunity cost: \(1>(1-\beta)W=1/2\).
- **Revision:** the verified theorem requires
  \(F_t\le(1-\beta)W\) on every additional date. A second Lean example with
  suspended operation and \(W=-1\) shows why continuation nonnegativity is
  needed in that corollary.
- **Lean declarations:**
  `delay_antitone_fails_without_noWaitingGain` and
  `delay_antitone_fails_with_negativeContinuation`.

### CX-CS-CLOSURE-ORDER-01 — Closure inclusion has no unconditional value sign

- **Target:** value monotonicity from closure inclusion alone
- **Data:** the exact finite closure-value table assigns value two to the empty
  module set and value one to the singleton module set.
- **Check:** \(\varnothing\subseteq\{\star\}\) but \(1<2\).
- **Failed assumption:** no generative-dominance order constrains how
  feasibility, cost, or completion behavior changes with closure.
- **Lean declaration:**
  `closure_mono_fails_without_generativeDominance`.

### CX-S6-NEGATIVE-GAP-01 — Complementarity needs a nonnegative gap

- **Target:** unconditional discount--survival complementarity for a
  sign-indefinite continuation vector
- **Data:** one state, the unique stochastic matrix \(P=(1)\), horizon two,
  \(\beta_0=\rho_0=0\), \(\beta_1=\rho_1=1\), and gap \(g=-1\).
- **Check:** \(\Psi_2(1,1)=-2\), while each other corner equals \(-1\).
  Hence
  \[
    \Psi_2(1,1)+\Psi_2(0,0)=-3
    <-2=\Psi_2(1,0)+\Psi_2(0,1).
  \]
- **Failed assumption:** \(g\) is not pointwise nonnegative. The transition is
  nevertheless exactly row stochastic and all parameter-order assumptions
  hold.
- **Lean declarations:**
  `DiscountSurvivalInteraction.Counterexamples.oneStateTransition_stochastic`
  and
  `DiscountSurvivalInteraction.Counterexamples.crossDifference_fails_without_nonnegativeGap`.

### CX-PERSISTENCE-INCREASE/DECREASE-01 — Persistence has both signs

- **Target:** either unconditional direction for persistence and innovation
  value
- **Data:** two beliefs and the symmetric kernel
  \(P_\rho=\left(\begin{smallmatrix}\rho&1-\rho\\1-\rho&\rho\end{smallmatrix}\right)\),
  starting at belief one, with \(\rho\) increasing from \(1/4\) to \(3/4\),
  one-period completion, and \(\beta=1/2\).
- **Checks:** for gap \((1,0)\), exact value rises from \(1/8\) to \(3/8\).
  For gap \((0,1)\), it falls from \(3/8\) to \(1/8\).
- **Reduction:** two states are necessary for nontrivial persistence; one
  project and one gap suffice.
- **Failed assumption:** no order was imposed between persistence and the
  location of the profitable gap.
- **Revision:** persistence claims must state an occupation/gap order; no
  unconditional persistence theorem is retained.

### CX-INFORMATION-INCREASE/DECREASE-01 — Information has both demand effects

- **Target:** either unconditional direction for information and research
  demand
- **Information order:** from prior \(1/2\), the less informative experiment
  leaves posterior \(1/2\); the Blackwell-more-informative experiment reveals
  posterior zero or one with probability \(1/2\) each.
- **Increasing fixture:** candidate state payoffs \((-1,1)\), zero incumbent,
  \(\beta=1/2\), and cost \(1/8\). Net research value moves from \(-1/8\) to
  \(1/8\), so demand changes from no to yes.
- **Decreasing fixture:** incumbent specialists have state payoffs \((1,0)\)
  and \((0,1)\), the candidate pays \((3/4,3/4)\), and cost is \(1/16\).
  Net value moves from \(1/16\) to \(-1/16\), so demand changes from yes to no.
- **Reduction:** binary hidden states and the posterior triple
  \(\{0,1/2,1\}\) are the minimum nondegenerate reveal experiment. Two
  incumbent specialists are needed for the decreasing inverted-V gap.
- **Failed assumption:** the candidate gap over the incumbent frontier is not
  generally convex or concave in posterior belief.
- **Revision:** information-demand results require an explicit curvature or
  Blackwell-order condition on the complete net project payoff.

### CX-DELAY-OPERATOR-POSITIVE/NEGATIVE-01 — Raw delay monotonicity is sign-sensitive

- **Target:** a universal delay direction for the research operator merely
  because the incumbent remains operational
- **Data:** one belief, \(\beta=1/2\), zero cost and zero continuation. With
  frontier one, the duration-one and duration-two branches are \(1\) and
  \(3/2\); longer delay raises the branch. With frontier minus one, they are
  \(-1\) and \(-3/2\); longer delay lowers it.
- **Reduction:** one belief and durations one/two suffice.
- **Failed assumption:** operator-level continuation was not tied to the
  value-consistent post-completion problem. The negative fixture additionally
  violates A-LIBRARY/A-PROFILE, because the adopted inactive strategy forces
  every admissible frontier to be nonnegative.
- **Revision:** no raw-operator delay theorem is retained. Under a fixed
  extension-only generator/coupling and a value-consistent three-period
  comparator with frontier zero and payoff-one descendant, duration one gives
  \(3/4\) and duration two gives \(1/4\); this surviving special case is
  fixture FX-DELAY-FIXED-GENERATOR-01.

### CX-T6-DISCONNECTED-01 — Legacy single-gap coverage is disconnected

- **Target:** connected-region or posterior-threshold extensions of T6
- **Data:** three ordered belief states; baseline payoff \(0\); deterministic
  candidate payoff \(1\); identity belief transition; perfect generation and
  verification; \(\beta=1/2\); costs \((0,1,0)\).
- **Check:** both the direct forced-project comparison and the T6 formula give
  coverage vector \((\mathsf{true},\mathsf{false},\mathsf{true})\).
- **Reduction:** three ordered grid points are minimal for a disconnected
  nonempty coverage subset.
- **Consequence:** the old one-gap identity survives within its legacy model;
  no connectedness, convexity, or unique-threshold claim may be inferred. This
  fixture now limits supporting coverage results rather than current T6.

### CX-SG-KERNEL-01 — A nonmonotone kernel defeats the upper threshold

- **Target:** stochastic monotonicity in the one-shot upper-threshold theorem,
  plus single-peaked-gap preservation and connected-potential extensions.
- **Exact data:** on `Fin 3`, increasing gap \((0,1,2)\) and deterministic transition rows
  with zero-based destinations \((1,0,1)\), equivalently

  \[
    P=\begin{pmatrix}0&1&0\\1&0&0\\0&1&0\end{pmatrix}.
  \]
- **Check:** the gap is nonnegative and increasing. The exact expected gap is
  \(P\Delta=(1,0,1)\). With unit survival and antitone constant unit cost, the
  weak cost-covering set is the disconnected pair of endpoints and is not
  upper. The kernel is row-stochastic but not first-order stochastically
  monotone. The retained gap \((0,1,0)\) separately shows that this kernel can
  also destroy single-peakedness.
- **Reduction:** three ordered states are minimal for disconnectedness. The
  Julia search enumerates the complete finite candidate order over gap values
  \(\{0,1,2\}\) and deterministic rows until the first strict-interior-peak
  witness. Lean recomputes the finite sums and proves the failed properties.
- **Consequence:** arbitrary row-stochastic kernels do not preserve finite-grid
  unimodality; S5 must restrict the kernel and the gap direction.

### CX-SG-COST-01 — Non-antitone cost disconnects a monotone covering set

- **Target:** an upper-threshold conclusion from monotone gross potential
  without cost restrictions
- **Exact data:** increasing potential \((1,2,3)\) and cost \((0,3,0)\).
- **Check:** the cost-covering decision vector is
  \((\mathsf{true},\mathsf{false},\mathsf{true})\). The cost is not antitone.
- **Consequence:** S5's antitone-cost hypothesis cannot simply be omitted.
  This exact reduction is generated by Julia and propositionally checked in
  Lean.

### CX-MULTIGAP-ADDITIVITY-01 — Complementary projects

- **Target:** optional additive multi-gap component bound
- **Data:** one belief; baseline payoff \(0\); bridge payoff \(0\) supplying
  module \(a\); final candidate payoff \(1\); two zero-cost deterministic
  projects; the second requires \(a\); horizon three; \(\beta=1/2\).
- **Check:** the joint innovation value is \(1/4\). The bridge-only and
  final-project-only values are both \(0\), so
  \(1/4>0+0\).
- **Reduction:** two projects and three strategies are necessary for this
  two-stage complementarity; one belief and one module suffice.
- **Consequence:** the optional additive component bound is false and removed.
  Any multi-gap bound needs explicit substitutes-only or bounded-complementarity
  assumptions.

### CX-F2-FRONTIER-OBS-01 — Transitions alone miss the frontier

- **Target:** an F2 converse after omitting current reward/frontier
  observations
- **Data:** one belief, one project, one module, and three strategies. The
  productive strategy pays one and supplies the module; the bridge pays zero
  and supplies the same module. The modular generator is constant.
- **Libraries:** inactive plus productive versus inactive plus bridge.
- **Lean check:** their generator transition signatures are equal, while their
  operational frontiers are unequal. This is proved by
  `frontier_converse_fails_without_currentReward`.
- **Consequence:** transition equality cannot replace F2's operational
  equivalence clause. In the actual DI relation, current reward is \(F(b)\), so
  frontier detectability follows by function extensionality rather than an
  added assumption.

### CX-F2-CLOSURE-ID-01 — A silent closure difference

- **Target:** the converse in F2 without A-FC-IDENT
- **Data:** the same one-belief finite model with a constant modular generator.
  The inactive library has empty closure; adding the zero-payoff bridge
  supplies the single module.
- **Lean check:** the two libraries are dynamically innovation equivalent
  because their frontiers and all transition laws agree, but their compressed
  frontier--closure states differ. The declarations
  `closure_converse_fails_without_identifiability` and
  `constantGenerator_not_closureIdentifiable` are kernel checked.
- **Consequence:** closure identifiability is logically necessary for the F2
  converse. Its witness formulation requires a concrete belief and project to
  separate every pair of distinct closures at a fixed frontier.

### CX-F3-VALUE-ID-01 — Values alone miss an identifiable closure

- **Target:** an F3 converse from equality of every finite-horizon value to
  equality of frontier and closure
- **Data:** one belief, one project, one module, an inactive strategy, and a
  zero-payoff bridge supplying the module. The discount is zero. The modular
  generator sends each supplied frontier--closure pair to a Dirac mass at that
  same pair.
- **Lean check:** the generator factors through frontier and closure and is
  closure-identifiable even beyond realizable states. Deleting the bridge
  preserves the frontier and every finite-horizon value, but changes closure
  from the singleton module set to empty. The theorem
  `finiteHorizonValuePreservation_does_not_imply_generativeRedundancy`
  packages all four facts.
- **Consequence:** A-FC-IDENT does not turn optimized value equality into
  transition-law equality. The valid converse must observe current rewards
  and all project-transition distributions explicitly, as A-SD-OBS does.

### CX-F4-FRONTIER-PRUNE-01 — Sharp scaled frontier-pruning loss

- **Target:** frontier-only deletion of an operationally dominated but
  uniquely generative strategy
- **Finite construction:** one belief, one project, one module, and three
  strategies. The inactive strategy and bridge \(d\) pay zero. Only \(d\)
  carries the key module. A future strategy pays exact rational reward
  \(R\ge0\). The current library is \(\{s_0,d\}\); deleting \(d\) leaves
  \(\{s_0\}\). The project deterministically reaches the future-strategy
  library exactly when the key module remains available.
- **Timing:** horizon two, constant belief, no project cost, and rational
  discount \(\beta=1/2\).
- **Lean check:** `dominated_operationallyRedundant` and
  `dominated_not_generativelyRedundant` prove the deletion classification;
  `frontierOnlyPrune_eq_pruned` proves that the explicit frontier-only rule
  deletes \(d\); and `frontierPruningLoss_exact` proves loss \(R/2\).
- **Unbounded parameterization:** for every \(M\in\mathbb N\), choosing
  \(R=2M\) gives loss exactly \(M\). This uses reward scaling explicitly.
- **Bounded-reward sharpness:** under a cap \(C\ge0\), every reward-admissible
  member of this fixed construction has loss at most \(C/2\), and \(R=C\)
  attains the bound.
- **Boundary:** this Lean theorem is supporting family F4. It is the
  deterministic specialization \(d=1,\beta=1/2,\rho=\pi=1,\kappa=0\) of
  normalized T4, and its arbitrary-loss statement uses reward scaling.
- **Julia counterpart:** a matching reusable Julia fixture and dedicated test
  remain scheduled for the later computational implementation pass.

### CX-MULTIGAP-REGION-01 — One project has two separated cost-covering regions

- **Target:** extrapolation of single-gap connectedness to a project filling
  multiple separated strategy-library gaps
- **Finite construction:** beliefs `Fin 5`; one project with two candidate
  outcomes; zero existing frontier; certified candidate gaps
  `(4,0,0,0,0)` and `(0,0,0,0,4)`.
- **Transition:** the exact degree-four Bernstein/binomial row at current
  belief `i` is the distribution of the success count in four Bernoulli trials
  with success probability `i/4`.
- **Check:** the aggregate gap is `(4,0,0,0,4)` and its exact one-shot gross
  potential is `(4,41/32,1/2,41/32,4)`. At constant cost one, the strict
  cost-covering vector is `(true,true,false,true,true)`, hence the set is
  `[0,1] ∪ [3,4]` and is not order-connected.
- **Lean check:** `separatedMultiGap_disconnectedCostCoveringSet` in
  `formal/StrategyInnovation/Counterexamples/MultiGapRegion.lean`.
- **Consequence:** multi-gap coverage can be disconnected even with a smooth,
  row-stochastic, economically interpretable transition kernel and constant
  cost. This is supporting limitation result C2, not T6.

### CX-TOPOLOGY-COST-01 — Variable cost defeats kernel-only component bounds

- **Target:** bounding one-shot cost-covering components by gap or potential
  components using a variation-diminishing kernel alone
- **Data:** the same degree-four Bernstein kernel, constant gap and potential
  `(2,2,2,2,2)`, and belief-dependent cost `(0,3,0,3,0)`.
- **Check:** the positive gap has one component, but the strict cost-covering
  set is `{0,2,4}` and has three components.
- **Lean check:** `unrestrictedCost_defeats_generalComponentBound` in
  `formal/StrategyInnovation/Counterexamples/MultiGapRegion.lean`.
- **Consequence:** even a future variation-diminishing theorem for the kernel
  would not imply a general component bound for the cost-covering set without
  explicit cost-shape assumptions.

### CX-S7-PERSISTENCE-SIGN-01 — Persistence has all three coverage signs

- **Target:** any universal claim that a larger persistence parameter raises,
  lowers, or strictly changes strategy-innovation coverage
- **Exact family:** on `Fin 2`,
  \[
    P(\theta)=
    \begin{pmatrix}\theta&1-\theta\\1-\theta&\theta\end{pmatrix},
  \]
  with initial state zero, horizon two, effective discount \(1/2\), and
  \(\theta\) increasing from \(1/4\) to \(3/4\).
- **Checks:** for gap \(g=(1,0)\), coverage rises from \(9/8\) to \(11/8\).
  For \(g=(0,1)\), coverage falls from \(3/8\) to \(1/8\). For
  \(g=(1,1)\), it remains \(3/2\).
- **Lean checks:** `higherPersistence_raises_coverage`,
  `higherPersistence_lowers_coverage`,
  `higherPersistence_no_effect`,
  `no_universal_persistence_increase`, and
  `no_universal_persistence_decrease` in
  `Coverage/KernelComparativeStatics.lean`.
- **Julia counterpart:** `run_kernel_persistence_response.jl` evaluates the
  complete exact response surface and independently checks the corresponding
  discounted occupation movements.
- **Consequence:** persistence matters through alignment with uncovered
  beliefs. A scalar persistence comparison alone supplies no sign.

### CX-T7-INDEPENDENT-MENU-SWITCH-02 — Project switching defeats substitution

- **Target:** the requested T7 cross-difference sign under frontier-independent
  generation, admission, costs, duration, operation, and candidate profiles
- **Exact construction:** one belief, discount \(1/2\), fixed descendant
  payoff \(10\), frontiers \(F_0=0\le8=F_1\), and two duration-one projects.
  The closure-poor menu contains an old project with success one and cost two.
  Closure enrichment adds a project with success \(1/2\) and zero cost.
- **Check:** relative to the frozen frontier, the old project has net premia
  \(3\) and \(0\), while the added project has premia \(5/2\) and \(1/2\).
  The old project therefore binds at the lower frontier, making closure
  enrichment worth zero, whereas the added project binds at the higher
  frontier, making enrichment worth \(1/2\). Thus \(J=1/2>0\).
- **Failed assumption:** none of the five requested primitive conditions.
  What fails is the stronger pairwise single-crossing property comparing each
  closure-rich action with every closure-poor action.
- **Revision:** corrected T7 adds exact relative action saturation. The
  existing CX-T7-FRONTIER-GENERATOR-01 remains the economically distinct
  complementarity example in which success itself reads the frontier.
- **Lean status:** exact theorem
  `independent_menu_switch_crossDifference_positive` in
  `formal/StrategyInnovation/Value/SystemInteraction.lean`; its individual
  saturation facts are also kernel checked.

### CX-T7-RS-CONTINUE-03 — Continue defeats the broader exposure-order premise

- **Target:** all-pairs relative action saturation inferred from a common
  descendant gap and an added-project exposure weakly above the incumbent
  exposure
- **Exact construction:** one belief, discount \(1/2\), fixed descendant
  payoff \(10\), frontiers \(F_0=0\le8=F_1\), and zero costs. The poor menu
  contains Continue and an old success-one project. The rich menu retains both
  and adds another success-one project, so added and old exposures are equal.
- **Check:** the old project returns \(5\) and \(1\). Rich Continue minus the
  poor old project is therefore \(-5\) and \(-1\). All-pairs relative
  saturation requires the high-frontier difference to be no larger, but
  \(-1\le-5\) is false.
- **Optimized sign:** both menus choose a success-one project at both
  frontiers, so the closure increments and \(J\) are zero. The witness rejects
  the proposed sufficient condition, not the substitution conclusion.
- **Resolution:** in the nonnegative common-gap class, require every feasible
  poor action to have zero gap exposure. Continue-only is the leading case.
- **Lean status:** exact theorem
  `added_exposure_order_insufficient_for_allPairs` in
  `formal/StrategyInnovation/Value/SystemInteraction.lean`.
- **Julia status:** reproduced by
  `primitive-substitution-search-v1`; the broader grid has 648 failures.

### CX-T6-JOINT-HARMFUL-NONG-01 — Harmful omitted outcome

- **Target:** joint descendant bound after dropping every non-\(g\) outcome
- **Minimal data:** one belief, duration one, discount \(1/2\), zero cost and
  operating adjustment, with masses \(1/2\) on \(g\) and \(1/2\) on another
  admitted outcome. Their complete continuation gains are \(2\) and \(-2\).
- **Check:** actual project premium is zero, while the uncorrected single-\(g\)
  bound is \(1/2\). Subtracting the expected harm \(1\) before discounting
  gives the exact corrected bound zero.
- **Missing assumption:** every omitted positive-mass completion gain is
  nonnegative, or its negative floor is charged explicitly.

### CX-T6-JOINT-OPERATING-ADJUSTMENT-01 — Negative adjustment cannot be omitted

- **Target:** the no-adjustment joint formula without a baseline match
- **Minimal data:** one belief, \(g\) certain, \(G=1\), duration one,
  \(\beta=1/2\), zero cost, and \(A^{\mathrm{op}}=-1/2\).
- **Check:** the exact adjusted premium and bound are zero. Silently replacing
  the adjustment by zero gives the false lower bound \(1/2\).
- **Missing assumption:** either retain the exact adjustment or prove
  \(A^{\mathrm{op}}=0\).

### CX-T6-JOINT-ENABLED-BOTH-01 — A pre-existing project is not incremental

- **Target:** interpreting the full value of \(q\) as insertion value when
  \(q\) is feasible in both libraries
- **Minimal data:** one belief and the same unit-premium project on both
  sides. Insertion is frontier silent and changes no project payoff.
- **Check:** generative insertion value is zero while the uncorrected project
  certificate is one.
- **Missing assumption:** post-insertion-only enablement or, algebraically, a
  zero-premium comparator. The companion exact fixture with \(q\) feasible on
  both sides but poor premium zero has no failure, so infeasibility is
  mechanism-facing once the zero-premium comparator is imposed.

### CX-T6-JOINT-POSITIVE-COMPARATOR-01 — Existing option value must be subtracted

- **Target:** the joint project certificate with
  \(\Omega_h(b,L)>0\)
- **Minimal data:** one belief. An old retained project gives the poor library
  premium one. Insertion alone enables \(q\), whose premium is also one.
- **Check:** the rich premium remains one, so insertion value is zero, but the
  uncorrected \(q\)-bound is one. The corrected lower bound is the project
  certificate minus the poor premium, hence zero.
- **Missing assumption:** `deleted_premium_zero`, or the explicit positive-
  comparator correction.

### CX-T6-JOINT-PATH-FLOOR-01 — Terminal averages are not supportwise floors

- **Target:** a terminal-belief gain \(G(b')\) chosen from one success path
  when continuation retains full-path information
- **Minimal data:** two equiprobable \(g\)-success paths end at the same
  terminal belief. Their complete gains are zero and two; duration one and
  \(\beta=1/2\).
- **Check:** using \(G(b')=2\) gives bound one while exact value is \(1/2\).
  The path-weighted floors reproduce \(1/2\); the terminal support minimum
  gives the weaker valid bound zero.
- **Missing assumption:** \(G(b')\) must lower-bound every positive-mass
  success path ending at \(b'\), or the theorem must remain path-level.

### CX-T6-JOINT-MENU-DISPLACEMENT-01 — Direct gain is not complete gain

- **Target:** substituting a descendant's direct payoff gain for its complete
  continuation improvement
- **Minimal data:** one belief and certain admission of \(g\). Its direct
  operating gain is two, but admission removes a future project option worth
  four.
- **Check:** the complete gain is \(-2\), so actual premium is zero at
  \(\beta=1/2\); using the direct \(G=2\) gives the false bound one.
- **Missing assumption:** \(G\) is a floor on the complete full-minus-passive
  continuation value, including every future-menu change. Pure menu expansion
  is harmless and is preserved as `FX-T6-JOINT-MENU-EXPANSION-01`.

### CX-T6-JOINT-HORIZON-01 — Infeasible long project

- **Target:** using the project comparison when \(d>h\)
- **Minimal data:** horizon one, duration two, \(g\) certain, \(G=4\),
  \(\beta=1/2\), and zero cost and adjustment.
- **Check:** the project is absent from the feasible Bellman menu and actual
  insertion value is zero. The formula applied out of scope gives one.
- **Missing assumption:** `duration_fits`, namely \(d\le h\).

### CX-T6-JOINT-PRODUCT-SHORTCUT-01 — Correlation defeats marginal products

- **Target:** replacing \(\eta_{q,g}\) by the product of terminal and
  admitted-event marginals without independence
- **Minimal data:** two terminal beliefs have mass \(1/2\) each, the
  \(g\)-event has mass \(1/2\), and \(G=(0,2)\). Admission of \(g\) occurs
  only at the zero-gain belief.
- **Check:** the exact joint gain is zero. The product-of-marginals gain is
  \(1/2\), hence \(1/4\) after discount \(1/2\).
- **Missing assumption:** event-specific terminal independence. The primary
  theorem uses \(\eta\) directly and survives both positive and negative
  perfect correlation.

### CX-RESOURCE-K-NET-01 — Productive state does not determine net value

- **Target:** extending the existing frontier--closure value-factorization
  theorem from productive value \(V\) to resource-penalized value
  \(J_\lambda=V-\lambda W\) without observing burden
- **Minimal data:** let active strategies \(a\) and \(c\) have identical
  operational profiles and identical module sets but weights \(w_a=1\) and
  \(w_c=2\). Let
  \(L_a=\{s_0,a\}\), \(L_c=\{s_0,c\}\), and take any rational
  \(\lambda>0\).
- **Check:** \(K_{L_a}=K_{L_c}\), so the existing productive process gives
  \(V(b,L_a)=V(b,L_c)\) at every applicable initial state and value horizon.
  But \(W(L_a)=1\) and \(W(L_c)=2\), hence
  \(J_\lambda(b,L_a)-J_\lambda(b,L_c)=\lambda>0\).
- **Missing observation:** resource-aware net equivalence must also compare
  \(W(L)\), or use \(K_L^W=(F_L,C_L,W(L))\). The existing \(K_L\) and UDI
  relation remain correct for productive dynamics.
- **Formal status:** exact mathematical witness specified but not yet encoded
  in Lean or Julia.

## Exact resource-optimization counterexamples

All fixtures in this section were produced by
`julia/scripts/search_resource_optimization_counterexamples.jl` with
`Rational{BigInt}` arithmetic. The complete audit is
`experiments/results/resource_optimization_claim_audit.json`; one
machine-readable file per numbered search target is under
`experiments/results/resource_optimization_fixtures/`. The searches minimize
the active carrier first and then use the lexicographic scores recorded in
the fixtures. These are exact finite Julia results, not Lean proofs.

### CX-OPT-PRUNE-CARDINALITY-01 — Safe pruning misses minimum cardinality

- **Target:** the claim that a complete rechecked safe-deletion trace always
  has globally minimum cardinality.
- **Carrier-minimal data:** one belief, identity closure, two modules, three
  unit-weight active strategies carrying respectively
  \(\{m_1\},\{m_2\},\{m_1,m_2\}\), and zero profiles.
- **Check:** deleting the bundle first leaves the irreducible two-singleton
  endpoint with active cardinality two. The bundle alone is safe-feasible and
  has active cardinality one.
- **Sharpened assumption:** trace safety and completeness imply
  irreducibility, not cardinality optimality. The rejected converse needs an
  exchange or matroid-type property of the safe-feasible family.
- **Fixture:** `01_cx_opt_prune_cardinality_01.json`.

### CX-OPT-PRUNE-WEIGHT-01 — Safe pruning misses minimum weight

- **Target:** the claim that every complete fixed-order safe-pruning trace
  minimizes \(W\).
- **Carrier-minimal data:** two duplicate module carriers with weights
  \(1\) and \(2\). Deleting the weight-one carrier first leaves the
  weight-two singleton.
- **Check:** both singleton endpoints preserve frontier and closure, but the
  returned burden is \(2\) and the global safe minimum is \(1\).
- **Sharpened assumption:** a weight-compatible exchange property or a global
  optimizer certificate is required; positive weights alone provide only
  strict improvement at each accepted deletion.
- **Fixture:** `02_cx_opt_prune_weight_01.json`.

### CX-OPT-GREEDY-WEIGHT-01 — Heaviest-safe-first pruning is suboptimal

- **Target:** the stronger greedy rule that deletes a currently safe strategy
  of maximum weight, with a fixed identifier tie breaker.
- **Size-minimal strict-max data:** singleton module carriers have weights
  \(2,2\); their two-module bundle carrier has weight \(3\). All profiles are
  zero and closure is identity.
- **Check:** the bundle is the unique heaviest initially safe deletion.
  Removing it leaves the irreducible singleton pair of burden \(4\); the
  bundle-only safe library has burden \(3\). Exhaustion through two active
  strategies rules out a smaller strict-maximum example.
- **Sharpened assumption:** even locally maximizing immediate burden release
  does not give global optimality without an exchange property.
- **Fixture:** nested under `maximum_burden_greedy_counterexample` in
  `02_cx_opt_prune_weight_01.json`.

### CX-OPT-DELETION-ORDER-WEIGHT-01 — Safe orders have unequal endpoints

- **Target:** order independence of complete rechecked safe deletion.
- **Carrier-minimal data:** the same two duplicate carriers of weights
  \(1\) and \(2\).
- **Check:** order \((s_1,s_2)\) deletes \(s_1\) and ends at burden \(2\);
  order \((s_2,s_1)\) deletes \(s_2\) and ends at burden \(1\). Both endpoints
  are safe and irreducible.
- **Sharpened assumption:** equal compressed state does not identify the raw
  representative or its resource burden; a deletion rule must declare order
  and tie handling.
- **Fixture:** `03_cx_opt_deletion_order_weight_01.json`.

### CX-OPT-LOCAL-NONGLOBAL-01 — Irreducible does not imply optimal

- **Target:** the converse of “every global minimum-weight safe library is
  inclusion-wise irreducible.”
- **Carrier-minimal data:** the same two unequal-weight duplicate carriers.
- **Check:** the weight-two singleton has no safe active deletion, yet the
  incomparable weight-one singleton is safe-feasible for the source.
- **Sharpened assumption:** local irreducibility excludes only strict feasible
  sublibraries of the endpoint. Global optimality compares all source-safe
  libraries.
- **Fixture:** `04_cx_opt_local_nonglobal_01.json`.

### CX-OPT-CAPACITY-NONCONCAVE-01 — Lumpy capacity value is nonconcave

- **Target:** unconditional concavity of \(B\mapsto V^\star(B)\).
- **Carrier-minimal data:** one active strategy with weight \(2\), value \(1\),
  and inactive-only value \(0\).
- **Check:** at unit budgets \(0,1,2\), capacity values are \(0,0,1\), so
  discrete marginal values are \(0,1\).
- **Sharpened assumption:** monotonicity survives. Concavity needs
  convexification or a separately proved discrete-concavity condition; a
  positive lumpy weight is already enough to defeat it.
- **Fixture:** `05_cx_opt_capacity_nonconcave_01.json`.

### CX-OPT-CAPACITY-INCREASING-RETURNS-01 — Complementarity raises marginal capacity value

- **Target:** unconditional diminishing marginal returns to capacity even
  under unit weights.
- **Carrier-minimal data:** two unit-weight active strategies with values
  \(V(\varnothing)=V(\{s_1\})=V(\{s_2\})=0\) and
  \(V(\{s_1,s_2\})=1\).
- **Check:** \(V^\star(0),V^\star(1),V^\star(2)=(0,0,1)\), hence the second
  unit of capacity is strictly more valuable than the first.
- **Sharpened assumption:** unit weights do not remove productive
  complementarity. Diminishing returns needs structure on the value set
  function.
- **Fixture:** `06_cx_opt_capacity_increasing_returns_01.json`.

### CX-OPT-SUBMODULAR-CAPACITY-01 — Submodularity does not make optimized capacity marginals diminish

- **Target:** discrete diminishing returns from monotone submodularity of
  library value under unit weights.
- **Exact data:** four unit-weight policies cover
  \[
  \{1,4,6\},\quad
  \{3,6\},\quad
  \{1,5\},\quad
  \{2,4\},
  \]
  respectively. Library value is the cardinality of the covered union.
- **Check:** the exact optima under cardinality bounds \(0,1,2,3,4\) are
  \[
    (0,3,4,6,6).
  \]
  The best singleton covers three elements, every pair covers at most four,
  and the last three policies together cover all six. Capacity marginals are
  therefore \((3,1,2,0)\), so the third marginal exceeds the second.
- **Sharpened assumption:** coverage value is normalized, monotone, and
  submodular, but submodularity orders fixed-policy marginal additions along
  nested libraries; capacity optima can switch between nonnested libraries.
  A sufficient positive result needs more structure, such as an exact-optimal
  greedy chain at every cardinality.
- **Evidence boundary:** direct finite exact enumeration recorded in
  `CAPACITY_VALUE_SPEC.md`; no dedicated JSON fixture or Lean declaration.

### CX-OPT-PENALIZED-INCLUSION-SWITCH-01 — Price switches are not inclusion-nested

- **Target:** raw-library inclusion monotonicity of penalized optimizers as
  \(\lambda\) rises.
- **Carrier-minimal data:** weights \((1,2)\) and productive values
  \((0,2,3,3)\) for masks \(\varnothing,\{s_1\},\{s_2\},\{s_1,s_2\}\).
- **Check:** at \(\lambda=1/4\), the unique optimizer is
  \(\{s_2\}\); at \(\lambda=5/4\), it is \(\{s_1\}\). The libraries are raw
  incomparable while burden falls from \(2\) to \(1\).
- **Sharpened assumption:** replace raw nesting by the valid burden-order
  theorem. Raw nesting needs an additional single-crossing or nested-demand
  condition.
- **Fixture:** `07_cx_opt_penalized_inclusion_switch_01.json`.

### CX-OPT-PENALIZED-BREAKPOINT-TIE-01 — Breakpoint optimizers are multiple

- **Target:** uniqueness of the penalized optimizer at every price.
- **Carrier-minimal data:** one active strategy with \(W=1,V=1\), against the
  inactive-only library with \(W=V=0\).
- **Check:** at \(\lambda=1\), both libraries have net value zero and are
  optimal.
- **Sharpened assumption:** the optimizer is a correspondence. A selected
  library requires a declared tie breaker or a strict-gap premise.
- **Fixture:** `09_cx_opt_penalized_breakpoint_tie_01.json`.

### CX-OPT-ADMISSION-REQUIRES-DELETION-01 — Retention may require eviction

- **Target:** the shortcut that an eligible candidate can be added to a full
  library without a capacity-releasing deletion.
- **Size-minimal data:** one weight-one incumbent, one weight-one
  outer-certified candidate, and capacity \(B=1\).
- **Check:** retaining both has burden \(2>B\); deleting the incumbent and
  retaining the candidate has burden \(1\).
- **Sharpened assumption:** deletion makes the already eligible candidate
  capacity-feasible. It does not make a raw generated candidate “admissible”;
  outer eligibility is fixed before optimization.
- **Fixture:** `10_cx_opt_admission_requires_deletion_01.json`.

### CX-OPT-NO-PRESAFE-STILL-ZERO-LOSS-01 — Candidate substitution defeats the pre-safe-loss inference

- **Target:** the claim that failure of a capacity-sufficient deletion safe
  relative to the current library forces positive replacement loss.
- **Exact data:** reuse CX-OPT-ADMISSION-REQUIRES-DELETION-01. The unit-weight
  incumbent \(s_1\) and unit-weight candidate \(c=s_2\) both carry module
  \(m_1\), capacity is one, and all productive values are zero.
- **Check:** deleting \(s_1\) from the current library changes closure from
  \(\{m_1\}\) to \(\varnothing\), so there is no capacity-sufficient
  pre-admission safe deletion. After \(c\) is inserted, deleting \(s_1\)
  preserves the augmented closure because \(c\) carries \(m_1\). The
  replacement is candidate-relative safe and has zero displacement loss.
- **Sharpened assumption:** a true-loss theorem must use absence of every
  capacity-feasible zero-loss deletion, or assume that every relevant
  candidate-relative structural change strictly lowers the fixed value
  objective.
- **Fixture:** `10_cx_opt_admission_requires_deletion_01.json`; the new ID
  records a second logical use of the same exact instance.

### CX-OPT-POSITIVE-CANDIDATE-REJECT-01 — Positive standalone value need not justify displacement

- **Target:** acceptance of every candidate with positive standalone or
  unconstrained incremental productive value.
- **Exact data:** one unit-weight incumbent \(p\), one unit-weight candidate
  \(c\), capacity one, and monotone productive values
  \[
    V(\varnothing)=0,\quad
    V(\{p\})=5,\quad
    V(\{c\})=4,\quad
    V(\{p,c\})=6.
  \]
- **Check:** the candidate's standalone value is four and its unconstrained
  increment at the current library is \(6-5=1\). Capacity forces deletion of
  \(p\), producing value four. Candidate-relative displacement loss is
  \(6-4=2\), so net admission value is \(1-2=-1\).
- **Sharpened assumption:** acceptance compares incremental candidate gain
  with the least loss among capacity-sufficient deletion sets. Standalone
  positivity alone does not perform that comparison.
- **Evidence boundary:** direct exact finite table in
  `REPLACEMENT_OPTIMIZATION_SPEC.md`; no dedicated JSON fixture or Lean
  declaration.

### CX-OPT-LAGRANGE-UNSUPPORTED-01 — A capacity optimum has no supporting price

- **Target:** strong equivalence between hard-capacity and penalized retention
  in the finite discrete library problem.
- **Carrier-minimal realization:** two unit-weight active strategies with
  productive values \((0,0,1,3)\). At budget \(B=1\), the unique capacity
  optimizer is the second singleton with pair \((W,V)=(1,1)\).
- **Penalty check:** comparison with the inactive-only library requires
  \(\lambda\le1\), while comparison with the two-strategy library requires
  \(\lambda\ge2\). No nonnegative price supports the capacity optimizer.
- **Duality-gap check:** the Lagrangian dual value is \(3/2\), versus primal
  value \(1\), for an exact gap of \(1/2\).
- **Sharpened assumption:** strong equivalence needs convexification or a
  proved discrete support property.
- **Fixture:** `11_cx_opt_lagrange_unsupported_01.json`.

### CX-OPT-CLOSURE-CARDINALITY-ELASTICITY-01 — Closure size is not a value state

- **Target:** treating \(|C_L|\) as sufficient for a resource or innovation
  elasticity.
- **Size-minimal data:** two singleton libraries each close one different
  module, with equal burden but productive values \(0\) and \(1\).
- **Check:** equal closure cardinality coexists with unequal productive value.
  A derivative or finite difference indexed only by \(|C|\) therefore does
  not identify a common numerator.
- **Sharpened assumption:** an elasticity must name the module/library
  perturbation and held-fixed primitives; closure size would require
  exchangeable modules plus value sufficiency.
- **Fixture:** `12_cx_opt_closure_cardinality_elasticity_01.json`.

### CX-OPT-ELASTICITY-ZERO-MARGIN-01 — Level elasticity diverges at a zero margin

- **Target:** a uniform level-elasticity bound without a positive innovation
  margin floor.
- **Size-minimal family:** one scalar quality \(x>1\), unit cost, and margin
  \(\mu(x)=x-1\). Along \(x_n=1+1/n\), all inputs are rational.
- **Check:** \(\mu_n=1/n\) and
  \(\varepsilon_n=x_n/\mu_n=n+1\), which is unbounded as the innovation margin
  approaches zero. The fixture records \(n=1,\ldots,16\) and the exact
  parametric identity.
- **Sharpened assumption:** level elasticity requires a positive margin floor;
  otherwise report exact level changes or a semielasticity.
- **Fixture:** `13_cx_opt_elasticity_zero_margin_01.json`.

### CX-BEM-VANISHING-GROSS-SCALE-01 — Vanishing net level need not raise elasticity

- **Target:** the unqualified claim that every path with innovation margin
  \(M\downarrow0\) makes ordinary elasticity magnitudes diverge.
- **Exact rational family:** fix \(d\ge1\) and rational
  \(0<\beta,\rho,\pi<1\), set \(\kappa=0\), and take \(C_n=1/n\) for
  \(n\in\mathbb N_{\ge1}\).
- **Check:** \(A_n=M_n=\beta^d\rho^d\pi/n\downarrow0\), but
  \(m_n=M_n/A_n=1\). The level-form elasticities remain exactly
  \[
    (\varepsilon_\beta^M,\varepsilon_\rho^M,
      \varepsilon_\pi^M,\varepsilon_C^M,\varepsilon_\kappa^M)
    =(d,d,1,1,0).
  \]
- **Sharpened assumption:** divergence requires
  \(m=M/A\downarrow0\). The condition \(M\downarrow0\) suffices when \(A\)
  stays bounded away from zero, but not when gross opportunity vanishes with
  the net margin.
- **Fixture:** direct parametric rational family in
  BRIDGE_ELASTICITY_SPEC.md; no generated JSON or Julia routine.

### CX-OPT-VALUE-KINK-01 — Optimized penalized value is not differentiable

- **Target:** global differentiability of \(J^\star(\lambda)\).
- **Carrier-minimal data:** the one-active-strategy breakpoint fixture with
  \(W=V=1\).
- **Check:** \(J^\star(\lambda)=\max\{0,1-\lambda\}\). At
  \(\lambda=1\), the left slope is \(-1\), the right slope is \(0\), and both
  libraries are optimal.
- **Sharpened assumption:** the correct theorem is a finite convex
  piecewise-affine envelope with one-sided slopes or subgradients.
- **Fixture:** `14_cx_opt_value_kink_01.json`.

### Surviving target — penalized burden is antitone

Target 8 did not yield a counterexample. For
\(\lambda_1<\lambda_2\), take any
\(L_1\in\operatorname{Opt}_{\lambda_1}\) and
\(L_2\in\operatorname{Opt}_{\lambda_2}\). Adding their two optimality
inequalities gives
\[
  (\lambda_2-\lambda_1)\bigl(W(L_1)-W(L_2)\bigr)\ge0,
\]
so \(W(L_2)\le W(L_1)\). The exact bounded audit checked all optimizer pairs
in the declared search domain. This is an informally proved algebraic
survivor with Julia validation, not yet a Lean theorem. Its fixture is
`08_fx_opt_penalized_burden_monotone_01.json`.

## Fixture and claim discipline

The current unified records are generated by
`julia/scripts/search_revision_counterexamples.jl`; the Phase 2 legacy records
remain generated by `julia/scripts/search_counterexamples.jl`.
The two single-gap records are generated by
`julia/scripts/search_single_gap_geometry.jl`. The Julia regression suite
checks each expected fact. The eight joint-bound records and four companion
survivors are generated by
`julia/scripts/search_joint_descendant_bound.jl`. Lean fixtures preserve exact
data for typed proofs.

The resource-optimization records are generated by
`julia/scripts/search_resource_optimization_counterexamples.jl`; `--check`
byte-compares the committed summary and all 14 per-target fixtures.
CX-RESOURCE-K-NET-01 is also realized by the unequal-weight duplicate rows in
targets 2--4. CX-OPT-LAGRANGE-UNSUPPORTED-01 is now a realized two-active-
strategy exact optimization fixture rather than only an abstract attainable
set. None of these resource records has a Lean counterpart, so none carries
Lean-verified status.

The two CX-F2 entries, CX-F3-VALUE-ID-01, CX-F4-FRONTIER-PRUNE-01,
CX-SG-KERNEL-01, CX-SG-COST-01, CX-MULTIGAP-REGION-01, and
CX-TOPOLOGY-COST-01, CX-S7-PERSISTENCE-SIGN-01, and
CX-T7-INDEPENDENT-MENU-SWITCH-02 are typed Lean
propositions with axiom
reports reconciled in `THEOREM_LEDGER.md`. Other generated feasibility records
remain data fixtures: no entry upgrades a manuscript claim to “proved” or
“Lean verified” until it is restated in the formal model and passes the claim
gate.
