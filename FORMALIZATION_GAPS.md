# Formalization Gaps

## Current state

The finite model interface and corrected T1--T7 statements are locked, and the
unified exact Julia falsification pass is complete. F0, the R0 raw
admission/local-update foundation, UDI, the supporting families F1--F8, and
S4--S7/C2 are implemented in Lean. T1--T7 are implemented.
“Resolved” below means Lean verified only where the corresponding declaration
and axiom audit are cited.

## Gap registry

### FG-0001 — Core objects lacked exact definitions

- **Affected results:** T1--T7
- **Resolution:** `MODEL_SPEC.md`, `ASSUMPTIONS.md`, and `NOTATION.md` now
  define the finite carriers, belief grid, strategy catalog, baseline-containing
  library, operational profile and frontier, module closure, projects,
  generation, verification, admission, compressed state, and finite-horizon
  value.
- **Residual risk:** planned Lean representations may reveal proof-engineering
  friction, but no semantic choice remains open in the finite core.
- **Status:** partially implemented: T1 supplies the finite
  catalog/library/closure/frontier, exact generation/admission, RC1, declared
  joint completion, timing/cost, and value layers; the hidden-state belief
  interpretation adapter remains open

### FG-0002 — Preservation and minimality were conflated

- **Affected results:** T1, T2
- **Resolution:** T1 proves the structural raw-to-compressed projection. UDI
  defines the final cost-sensitive behavioral relation by five
  availability-tagged observations and proves finite/infinite value
  preservation, finite quotient factorization, and compressed-state
  sufficiency. Generic minimality is rejected; only refinement inside the
  explicitly observation-preserving comparison class is retained. T2
  characterizes final UDI exactly by frontier--closure equality under the
  raw-process A-T2-OBS detectability predicate.
- **Residual risk:** full abstraction or minimality in a broader continuation
  category remains undefined and is not a Paper 1 core claim.
- **Counterexample:** validated CX-T1-RAW-01 and
  CX-T1-MIN-T2-SILENT-01.
- **Status:** core resolved and UDI Lean verified; stronger claims falsified

### FG-0003 — Frontier and closure semantics were undefined

- **Affected results:** T1--T6
- **Resolution:** \(F_L\) is the pointwise rational upper-envelope value;
  \(C_L\) is an extensive, monotone, idempotent closure of the union of
  strategy modules. Candidate generation, verification, and cost factor through
  \(b,C_L\).
- **Residual risk:** closure-signature injectivity is an explicit T2
  assumption, not a consequence of the closure axioms.
- **Counterexample:** validated CX-T1-MIN-T2-SILENT-01.
- **Status:** resolved at specification and Lean levels for T1--T6

### FG-0004 — “Arbitrarily large loss” lacked quantifier order

- **Affected results:** T4
- **Resolution:** payoffs are normalized to \([0,1]\); additive loss is
  unbounded across finite instances with varying rational \(\beta\) and finite
  horizon \(H\). Fixed-\((\beta,H)\) unboundedness is explicitly rejected.
- **Residual risk:** exact dynamic programming and a separate finite-sum
  calculation agree for four targets, but the adopted choice
  \(H=n+1,\ \beta=1-1/n^2,\ n>2R\) still needs a Lean proof of the finite
  Bernoulli/geometric lower bound.
- **Counterexample:** validated positive family CX-T4-BRIDGE-01 and
  fixed-parameter guard CX-T4-FIXED-01.
- **Status:** semantic gap resolved; proof obligation open

### FG-0005 — Value decomposition risked tautology or double counting

- **Affected results:** T5
- **Resolution:** `Value/UnifiedDecomposition.lean` defines the operational
  component from the frozen raw-library, never-research baseline; full value
  is T1 `rawValue`; and the premium is their difference. The insertion
  identity is proved by exact cancellation. Frontier silence, two-component
  silence through T1, fixed-candidate operational antitonicity, an exact raw
  bridge witness, and premium monotonicity under explicit unified
  project-action dominance supply the non-definitional consequences.
- **Residual risk:** the decomposition itself is an accounting identity.
  Closure inclusion without A-T5-PROJECT-DOMINANCE gives no comparative
  static, and no universal sign is claimed for generative insertion value.
- **Counterexample:** validated CX-T5-SEPARABILITY-01 rejects a closure-only
  premium.
- **Status:** resolved at the exact finite Lean level; stronger closure-only
  extension remains falsified

### FG-0006 — Legacy single-gap geometry was undefined

- **Affected results:** legacy T6, S4--S5, C1
- **Resolution:** the version-1 feasibility package defined a two-period
  forced-project comparison on finite \(B\). Publication-facing T6 is now the
  separate retained-carrier lower bound; the one-gap identity remains a
  supporting legacy fixture.
- **Residual risk:** continuous geometry, repeated attempts, and multiple gaps
  are excluded.
- **Counterexamples:** validated CX-T6-DISCONNECTED-01 rejects unconditional
  connected or threshold geometry; Lean-checked CX-SG-KERNEL-01 strengthens
  the boundary to a single-peaked nonnegative gap under an arbitrary kernel;
  CX-MULTIGAP-ADDITIVITY-01 rejects an additive component bound.
- **Status:** finite legacy identity computationally validated; supporting
  monotone S5 Lean verified; named stronger extensions falsified

### FG-0007 — Lean/Julia semantic correspondence is unspecified

- **Affected results:** all results with computational counterparts
- **Problem:** the original audit had a deterministic rational JSON result and
  a generated Lean data fixture, but the fixture's expected facts were strings
  rather than propositions in the future formal model.
- **Partial resolution:** the reusable Julia core now has canonical typed
  encodings for belief, strategy, module, and project identifiers; exact
  `RatProb`; exact belief kernels; inactive-containing libraries; validated
  finite closure tables; operational profiles; frontier--closure states; raw
  generation and verification laws; the derived admitted law; raw and
  compressed updates; a validated joint completion coupling; unified timing;
  and raw/compressed finite and stationary Bellman solvers. Exact rationals
  and matrices have a deterministic lossless text round trip. The reusable
  raw API is tested directly against R0, T1, UDI, and S2 fixture identities;
  the older F1/F5/F8 primitive APIs are deprecated compatibility layers.
- **Residual risk:** the broader Phase 2 raw-library oracle still uses local
  bitmask structures and string-valued expected facts. No complete serialized
  typed round-trip schema yet connects Julia callbacks for generation, cost,
  availability, and the joint completion coupling to Lean declarations.
- **Status:** reusable raw-model computation resolved; a general serialized
  Lean/Julia raw-model round trip remains open.

### FG-0008 — Toolchain and stable Julia runtime location

- **Affected results:** future computational validation
- **Resolution:** Lean/mathlib, Julia package manifests, LaTeX, and CI are
  pinned. The official Julia 1.12.6 Apple Silicon archive was checksum-verified
  and unpacked under the stable ignored repository path
  `.local_runtime/julia-1.12.6`; no project command was executed from a
  temporary directory.
- **Residual risk:** the local runtime is intentionally untracked and must be
  reinstalled from the recorded official archive on a fresh workstation.
- **Status:** resolved for this workstation; portable bootstrap remains
  documented rather than vendored

### FG-0009 — A-T2-OBS is an explicit identification condition

- **Affected results:** T2
- **Resolution:** T2 now states `RawClosureDetectable` explicitly on the
  realizable compressed carrier. A distinct closure must change a tagged
  project cost, duration, or projected joint terminal law. Candidate or
  primitive-admission changes count only when they survive admission and raw
  update into that projected observation. The proof does not use the old
  abstract transition table.
- **Counterexamples:** the exact Lean silent-process construction establishes
  necessity; the raw-identifier construction establishes the forward input
  restriction. A small economically motivated family of probe projects would
  strengthen interpretation but is not needed for validity of the conditional
  theorem.
- **Status:** resolved and Lean verified; economic calibration of detectability
  remains an interpretation limitation, not a formalization gap

### FG-0010 — Belief-grid calibration is taken as primitive

- **Affected results:** empirical relevance of all belief results
- **Problem:** the exact core assumes the filtered kernel \(P_B\) and belief
  interpretations \(\mu_b\); it does not derive them from hidden-state and
  observation kernels.
- **Required resolution:** a Julia specialization must document grid
  construction and approximation error. A Lean Bayes derivation is optional
  extension E-BAYES, not a prerequisite for T1--T7.
- **Status:** open for calibration and empirical interpretation; finite theorem
  core accepted

### FG-0011 — Optional multi-gap additive bound is false

- **Affected results:** optional multi-gap component bound; C1
- **Problem:** module complementarity lets a zero-payoff bridge project unlock a
  valuable later project, so isolated component values do not upper-bound joint
  innovation value.
- **Counterexample:** CX-MULTIGAP-ADDITIVITY-01 has joint value \(1/4\) and two
  isolated values equal to \(0\).
- **Resolution:** remove the optional bound from the theorem package. Any
  replacement must state substitutes-only, no-unlocking, or quantified
  complementarity assumptions before proof work starts.
- **Status:** counterexample found; stronger claim removed

### FG-0012 — The locked baseline did not guarantee an inactive zero option

- **Affected results:** foundational frontier lemmas and the model interface
  used by T1--T7
- **Problem:** the initial specification guaranteed a baseline member but did
  not say that its profile was zero or that it supplied no modules, while the
  foundational Lean prompt requires an inactive zero strategy in every finite
  maximum.
- **Resolution:** D-0021 refines \(s_0\) to an immutable zero-profile,
  empty-module strategy present in every admissible library. The Lean
  `StrategyCatalog` records both equalities, and `Library` records membership.
- **Counterexample:** none required; this is a transparent strengthening of
  the model class rather than a failed claimed implication. The prior exact
  search covered the larger unrestricted-baseline class.
- **Status:** resolved at specification and foundational Lean levels

### FG-0013 — Abstract DI value preservation is not structural T1

- **Affected results:** F1 and T1
- **Problem:** F1 takes the compressed research kernel as primitive and defines
  raw-library value by first applying `compressedLibraryState`. Its recursion
  omits project cost. It therefore proves behavioral invariance for the
  abstract semantics, not that the accepted raw generation/verification model
  factors through \(K_L\).
- **Resolution:** D-0022 records F1 as a supporting theorem only. D-0050 and
  Projection/RawToCompressed.lean supply the independent T1 bridge from R0,
  including the realizable-state pushforward, displayed cost,
  availability/timing, joint coupling, embedded law, and strong
  calendar-horizon induction.
- **Minimality boundary:** the implemented theorem is coarseness only among
  representations whose equal fibers are assumed to preserve current rewards
  and every primitive research transition. A generic categorical,
  continuation-context, or MDP-minimality theorem remains outside the result.
- **Status:** F1 and the separate T1 bridge are Lean verified

### FG-0014 — Raw T2 must not reuse the abstract frontier--closure table

- **Affected results:** F2 and T2
- **Problem:** F2 identifies closure through a primitive modular next-state
  kernel \(g(b,F,C,q)\). The accepted T2 signature instead contains raw-model
  project costs and admitted-candidate kernels
  \((\kappa(q,b,C),\Gamma(q,b,C))\).
- **Resolution:** D-0023 registers F2 separately under A-FC-FACTOR and
  A-FC-IDENT. The new raw T2 module instead exposes raw candidate and admission
  factorization, invokes the T1 pushforward, and uses `RawClosureDetectable`.
  The manuscript retains F2 only as a deprecated primitive supporting result.
- **Counterexamples:** the Lean theorems
  `frontier_converse_fails_without_currentReward` and
  `closure_converse_fails_without_identifiability` respectively show that
  transition observations alone need not detect frontier differences and that
  DI equivalence need not detect a closure ignored by all projects.
- **Implemented T2 bridge:** `Quotient/RawFrontierClosure.lean` formalizes the
  raw laws, their closure-factorization consequences, the T1-projected law,
  observable closure witnesses, both iff criteria, and both exact boundary
  counterexamples.
- **Status:** F2 and the separate raw T2 are Lean verified

### FG-0015 — Value equality does not identify safe deletion

- **Affected results:** F3 and any value-only strengthening of T3
- **Problem:** the requested converse from equality of every finite-horizon
  value to preservation of frontier and generative closure is false in the
  abstract semantics. With discount zero, all positive-horizon values equal
  the current frontier; future project transitions can identify a closure
  difference without affecting any value.
- **Lean counterexample:** a one-belief, one-project, one-module model has a
  zero-payoff bridge whose deletion leaves the frontier unchanged and removes
  the only module. The modular generator returns a Dirac mass at its supplied
  frontier--closure pair, so it satisfies both A-FC-FACTOR and the strongest
  closure-identifiability condition. Nevertheless deletion preserves value at
  every finite horizon. This is theorem
  `finiteHorizonValuePreservation_does_not_imply_generativeRedundancy`.
- **Resolution:** the F3 converse uses A-SD-OBS: equality of current rewards
  and every allowed project-transition distribution. This premise is exactly
  deletion-level DI equivalence and, under A-FC-IDENT, recovers frontier and
  closure. Value preservation remains a one-way corollary only.
- **T3 boundary and resolution:** Unified T3 defines innovation safety using
  the complete UDI process observations plus all finite-horizon values. Its
  converse uses `RawClosureDetectable`, never value equality alone. The
  compressed-state and value implications are Lean verified through T1.
- **Status:** stronger value-only converse counterexample retained;
  observation-level F3 and unified T3 converses Lean verified

### FG-0016 — Reward scaling is secondary to normalized T4

- **Affected results:** F4 and T4
- **Problem:** at fixed parameters, arbitrary pruning loss cannot coexist with
  a fixed reward cap. The earlier manuscript result made reward scaling
  primary and did not expose delay, survival, admission, or research cost.
- **Resolution:** T4 now derives the raw admitted-descendant mass
  \(\rho^d\pi\) and proves the exact unified-timing loss
  \(\beta^d\rho^d\pi C-\kappa\). The cap-\(C\) bound is sharp, the positive
  opportunity-loss ratio is one, and \(C\le1\) implies loss at most one.
  Arbitrary loss is retained only as the specialization
  \(d=1,\beta=1/2,\rho=\pi=1,\kappa=0,C=2M\).
- **Operation boundary:** continued operation adds the difference of exact
  incumbent-reward blocks; frontier equality and the common belief-path law
  make it zero in the canonical construction.
- **Julia boundary:** existing exact fixtures validate the deterministic
  specialization only. No new Julia claim is inferred from the Lean proof.
- **Status:** resolved; T4 and supporting F4 are Lean verified

### FG-0017 — Generic finite-state value is not the raw Bellman bridge

- **Affected results:** F5 and T1
- **Problem:** F5 supplies a genuine finite compressed-state carrier, exact
  costs, finite action maximization, and delay, but its compressed transition
  is primitive. It has no raw library, candidate generation, verification,
  admission, or local frontier--closure update. Its action timing follows the
  value-model prompt: continue earns the current frontier, while research pays
  cost without incumbent rewards and uses delay only in the continuation
  exponent. Unified A-TIMING instead evolves beliefs and incumbent rewards
  through full calendar duration, then applies a jointly declared completion
  law.
- **Resolution:** D-0026 registers F5 as reusable supporting infrastructure
  under A-FH-VALUE. Cost-sensitive DI includes equality of project costs,
  which is logically necessary for value preservation. Delay is encoded by
  \(\beta^{d+1}\) and the horizon counts decision epochs. D-0046 and D-0047
  fix the replacement timing and raw projection without altering F5's verified
  legacy meaning.
- **T1 resolution:** Projection/RawToCompressed.lean instantiates the finite
  realizable image, declared non-product joint coupling, transition
  pushforwards, embedded projection, and unified raw/compressed calendar
  recursions. F5 remains a separate legacy supporting calculus.
- **Status:** F5 and T1 Lean verified under their distinct encoded semantics

### FG-0018 — Insertion decomposition is not the T5 premium recursion

- **Affected results:** F6 and T5
- **Problem:** F6 defines passive and full values through an explicit
  raw-library adapter to the primitive F5 process, so its algebraic insertion
  theorem did not establish the requested result on T1's accepted raw model.
- **Resolution:** D-0027 continues to register F6 separately.
  D-0055 adds `Value/UnifiedDecomposition.lean`: full value is T1 `rawValue`,
  frontier--closure silence uses T1 compressed projection, and premium
  monotonicity compares exact T1 project-action values under
  A-T5-PROJECT-DOMINANCE.
- **Sign boundary:** an exact bridge example proves positive generative
  insertion value is possible, not universal. No declaration states
  unconditional nonnegativity of generative insertion value.
- **Status:** resolved: F6 remains supporting and T5 is separately Lean
  verified on the unified raw process

### FG-0019 — Passive gap equation does not supply project-value recursion

- **Affected results:** F7, T5, and T6
- **Problem:** F7 exactly values a fixed candidate's passive operational
  insertion along the primitive F5 belief kernel. It therefore could not by
  itself establish T5 on the unified raw research process. T6 additionally
  compares forced research with forced idle using an admitted-candidate
  probability.
- **Resolution:** D-0028 registers F7 separately. Its finite recursive gap sum
  is the exact path expectation needed for passive insertion, but no theorem
  identifies it with a project payoff or the full innovation premium. The
  infinite-horizon geometric extension remains separate. T6 instead derives
  its committed-project identity and terminal path occupation directly from
  the T1 raw completion law in `Value/GenerativeLowerBound.lean`.
- **Status:** F7 remains supporting; T5's raw operational antitonicity is Lean
  verified independently; T6 is separately Lean verified

### FG-0020 — Primitive-state contraction is not the raw infinite-horizon theorem

- **Affected results:** F8, T1, and S2
- **Problem:** F8 proves a sup-norm contraction for the primitive finite
  compressed-state process of F5. That process does not derive its transition
  from raw candidate generation, verification, admission, or local
  frontier--closure updates, and its research action timing differs from
  accepted A-TIMING. Candidate S2 also asks for an optimal stationary policy,
  while F8 constructs only the unique value fixed point.
- **Resolution:** D-0029 retains the primitive Banach result as supporting F8.
  D-0062 and `Bellman/Unified.lean` now discharge the stronger bridge: the
  realizable compressed state and joint completion law come from T1; positive
  duration gives \(\beta^{d(q)}\le\beta\); raw and compressed contractions are
  derived; fixed points intertwine; and a finite maximizing stationary
  selector satisfies a separately contracting policy-evaluation equation.
- **Status:** resolved; F8 remains compatibility-only and unified S2 is Lean
  verified

### FG-0021 — Gross coverage potential is not the T6 carrier bound

- **Affected results:** S4 and T6
- **Problem:** S4 represents the gross operational contribution of one fixed
  candidate against primitive future-belief occupation weights. Current T6
  instead bounds the marginal value of retaining an operationally redundant
  module carrier, subtracts project cost, uses the joint terminal
  belief/admission mass, and requires a zero-premium deleted comparator.
- **Resolution:** D-0030 registers the finite-horizon survival-adjusted
  occupation representation under A-S4-COVERAGE-POTENTIAL. Its gap is a
  certified positive part over the existing frontier, and its exact
  finite-sum identity, monotonicities, no-value condition, bounds, delayed
  example, and frontier comparison are independently kernel checked.
- **T6 resolution:** `Value/GenerativeLowerBound.lean` derives the
  survival--admission event from the raw generator under explicit conditional
  independence, subtracts exact project cost, exposes the unified operating
  adjustment, and uses the zero-premium deleted comparator. Its occupation
  weights are derived from T1's full belief paths; S4 is not used as the proof.
- **Status:** S4 and T6 are separately Lean verified

### FG-0022 — Single-peaked gaps do not imply connected supporting coverage

- **Affected result:** desired single-gap supporting coverage-region extension
- **Mismatch:** A single-peaked or quasi-concave nonnegative gap can be mapped
  by a valid row-stochastic finite kernel to a non-quasi-concave potential.
  Moreover, monotone potential does not give a connected cost-covering region
  when costs are unrestricted.
- **Counterexamples:** CX-SG-KERNEL-01 uses gap \((0,1,0)\), deterministic
  destinations \((2,1,2)\), and potential \((1,0,1)\). CX-SG-COST-01 uses
  potential \((1,2,3)\) and cost \((0,3,0)\). Both yield decision vector
  \((\mathsf{true},\mathsf{false},\mathsf{true})\) at the displayed level or
  cost and are exact Lean propositions.
- **Resolution:** D-0031 replaces the failed desired statement by S5 under
  A-S5-MONOTONE-COVERAGE. `SingleGap.lean` proves only a finite upper-threshold
  theorem from increasing gap, first-order stochastic monotonicity, increasing
  nonnegative survival, nonnegative discount, and antitone cost.
- **Status:** failed stronger statement rejected; revised S5 Lean verified

### FG-0023 — A kernel-only topology bound does not control net research regions

- **Affected result:** optional finite variation-diminishing/component theorem
- **Problem:** Exact tests strongly support variation diminution for the
  selected degree-four Bernstein matrix, and every one of its 251 square
  minors is nonnegative. Pinned mathlib nevertheless supplies no directly
  reusable total-nonnegative-matrix or variation-diminishing theorem, so a
  universal Lean proof would require a new sign-variation theory. More
  importantly, even such a kernel theorem would not bound connected components
  of `{b | cost b < potential b}` when cost is unrestricted.
- **Counterexample:** CX-TOPOLOGY-COST-01 uses the selected kernel, constant
  gap and potential `(2,2,2,2,2)`, and cost `(0,3,0,3,0)`. The gap has one
  positive component while the strict research region is `{0,2,4}`, with
  three components. The reduction is an exact Lean proposition.
- **Resolution:** D-0032 retains C2, the exact multi-gap disconnected-region
  counterexample, but declines `Coverage/TopologyBound.lean`. The exhaustive
  finite Julia results remain validation evidence only. A future potential-
  topology theorem would need an explicit finite variation-diminishing
  definition and proof; a research-region theorem additionally needs shape
  restrictions on cost.
- **Status:** general research-region component claim false; narrower
  Bernstein potential theorem numerically supported but not manuscript-ready

### FG-0024 — Unified gauntlet survival is not T1--T7 formalization

- **Affected results:** T1--T7
- **Problem:** the exact revision oracle implements the unified positive-
  duration calendar recursion and found no in-assumption counterexample, but
  finite search cannot prove a universally quantified theorem. T6 and T7 were
  not present in the formal dependency graph before this run.
- **Boundary counterexamples:** CX-T6-COST-01 rejects the cost-free lower bound;
  CX-T7-FRONTIER-GENERATOR-01 rejects substitutability without primitive
  generator independence; the paired persistence, information, and delay
  fixtures reject unconditional comparative statics.
- **T6 resolution:** the carrier comparator, exact cost and operating
  adjustment, raw survival/admission product, occupation-weighted form, and
  comparative statics are implemented and axiom audited in
  `Value/GenerativeLowerBound.lean`.
- **T7 resolution:** the T1 compressed Bellman process, realizable
  frontier--closure rectangles, action-menu transport, and exact finite maxima
  are combined in `Value/SystemInteraction.lean`. The stronger requested
  primitive-only theorem is separately rejected by FG-0026.
- **Status:** finite exact gauntlet passed and corrected T1--T7 are Lean
  verified

### FG-0025 — Nonnegative operation does not imply delay antitonicity

- **Affected result:** supporting finite comparative statics, delay branch
- **Problem:** the requested assumptions named a nonnegative operating
  frontier, nonnegative descendant continuation, and unified elapsed timing.
  Those signs alone do not make project value antitone in duration. Under the
  exact unified payoff
  \[
    R_d=-\kappa+\sum_{t<d}\beta^tF_t+\beta^dW,
  \]
  the one-period increment is
  \[
    R_{d+1}-R_d=\beta^d\{F_d-(1-\beta)W\}.
  \]
- **Exact counterexample:** at
  \(\beta=1/2,\kappa=0,F_t=1,W=1\), both sign assumptions hold but
  \(R_1=3/2<R_2=7/4\). With suspended operation and \(W=-1\), longer delay
  also raises value from \(-1/2\) to \(-1/4\), showing why nonnegative
  continuation matters in the zero-operation corollary.
- **Resolution:** D-0057 and `Value/ComparativeStatics.lean` add the exact
  no-waiting-gain condition \(F_t\le(1-\beta)W\) on every added date. The
  module proves delay antitonicity under that condition and proves suspended
  operation as a corollary. Both failures are kernel-checked propositions.
- **Status:** stronger requested sign claim rejected; corrected one-way
  theorem Lean verified

### FG-0026 — Frontier-independent opportunities do not imply closure submodularity

- **Affected result:** requested T7 cross-difference theorem
  \[
    [V(F_1,C_1)-V(F_1,C_0)]
      -[V(F_0,C_1)-V(F_0,C_0)]\le0.
  \]
- **Problem:** frontier independence makes every fixed candidate opportunity
  saturate as the frontier rises, but it does not prevent the optimizer from
  switching between projects with different fixed costs and admission
  probabilities. Menu expansion can therefore be more valuable at the higher
  frontier even though no primitive reads the frontier.
- **Exact counterexample:** take one belief, \(\beta=1/2\), fixed descendant
  payoff \(10\), \(F_0=0\), and \(F_1=8\). Closure \(C_0\) offers an old
  project with fixed \((\pi,\kappa)=(1,2)\); \(C_1\) adds a project with fixed
  \((\pi,\kappa)=(1/2,0)\). The old and added net premia are respectively
  \((3,0)\) and \((5/2,1/2)\) at \((F_0,F_1)\). Hence the optimized closure
  increments are \(0\) and \(1/2\), so \(J=1/2>0\). Candidate quality, costs,
  durations, admission laws, and updates are all frontier independent, and
  closure expansion only adds the second opportunity.
- **Resolution:** retain primitive frontier independence as necessary context
  but add a relative action-saturation condition: at every Bellman node, the
  payoff advantage of every closure-rich feasible action over every
  closure-poor feasible action must be weakly smaller at \(F_1\) than at
  \(F_0\). This condition rules out the project-switching channel and implies
  the desired optimized cross-difference by a finite maximum argument. Record
  the five originally requested conditions as insufficient rather than
  silently treating relative saturation as one of them.
- **Status:** stronger requested theorem rejected; corrected theorem and Lean
  counterexample verified in T7

### FG-0027 — One-shot cost covering is not a Bellman research region

- **Affected result:** S5 finite monotone-gap coverage theorem
- **Problem:** the inequality
  \[
    \kappa(b)\le \beta p(b)\sum_{b'}P(b,b')\Delta(b')
  \]
  contains a one-shot gross candidate payoff and cost, but no Bellman
  continuation difference, competing project, or optimized action value.
  Monotonicity of its two sides therefore cannot establish monotonicity of the
  optimal dynamic research-action region.
- **Resolution:** D-0061 renames the set
  `oneShotCostCoveringSet` and the main declaration
  `monotoneGap_upperThreshold`, preserving the former names only as
  compatibility wrappers. Exact cutoff comparative statics are stated only
  for this one-shot set. The manuscript explicitly withholds any Bellman
  analogue.
- **Status:** terminology and theorem scope corrected; one-shot theorem and
  boundary counterexamples Lean verified

### FG-0028 — The passive gap-sum theorem lacks a unified-process bridge

- **Affected result:** the manuscript's combined finite-horizon Strategy
  Innovation Equation.
- **Problem:** T5 proves the exact decomposition
  `totalInsertionValue = operationalInsertionValue +
  generativeInsertionValue` for the unified T1 raw process. F7 separately
  proves that `passiveOperationalInnovation` is a discounted frontier-gap sum,
  but its binder is `ValueDecomposition.LibraryDynamics`, the older primitive
  F5 adapter. No named Lean theorem identifies that adapter's passive value
  with `Projection.Model.UnifiedDecomposition.passiveValue`.
- **Audit result:** the two source statements are individually kernel checked,
  but composing them as one final-model Lean theorem would be stronger than
  the current formal interface. This is an interface gap, not a discovered
  numerical counterexample; the recursions have the same displayed algebra
  once an explicit adapter equality is supplied.
- **Resolution:** downgrade the combined gap-sum display to a conditional
  economic interpretation. Keep T5's unified accounting identity as the exact
  main result, label F7 as a supporting primitive-adapter proposition, and
  state explicitly that no T1--T7 claim depends on the missing bridge.
- **Status:** manuscript claim downgraded; optional direct unified gap-sum
  bridge remains open

### FG-0029 — Added-project exposure order does not imply all-pairs saturation

- **Affected result:** primitive sufficient conditions for T7 relative action
  saturation
- **Problem:** in a common-gap model, ordering the added project's exposure
  above the incumbent project's controls added-versus-incumbent switching but
  not every rich/poor action pair. Continue belongs to the rich menu and has
  zero descendant-gap exposure. Its advantage over a positive-exposure poor
  project rises when the common gap shrinks.
- **Exact counterexample:** let
  \(\beta=1/2\), \((F_0,F_1)=(0,8)\), and fixed descendant payoff \(10\).
  Give both the old and added projects success one and cost zero, so their
  exposures are equal. Rich Continue minus the poor old-project return is
  \(-5\) at \(F_0\) and \(-1\) at \(F_1\); relative saturation would require
  \(-1\le-5\). The optimized interaction happens to be zero, so this is a
  failure of the all-pairs premise rather than of substitution.
- **Search:** `primitive-substitution-search-v1` checks 2,430 exact rational
  rows. Among 1,620 rows satisfying the broader added-exposure order, 648 fail
  all-pairs relative saturation. All 810 rows with zero poor exposure and
  nonnegative rich exposure pass. The existing 12 complement rows and
  CX-T7-INDEPENDENT-MENU-SWITCH-02 remain unchanged.
- **Resolution:** adopt the fixed-continuation common-gap subclass
  A-T7-COMMON-GAP. It requires zero exposure for every feasible poor action,
  nonnegative rich exposures, and an antitone common gap. Lean proves that
  these primitive restrictions imply relative action saturation and then
  invokes unchanged T7. D-0089 additionally derives the antitone gap at every
  finite horizon from pointwise ordered current/terminal gaps, the process's
  common belief kernel, and nonnegative discounting. This closes the
  preservation step for the stated fixed-kernel subclass, but not for
  arbitrary action-dependent optimized successor closures.
- **Status:** broader primitive proposal rejected; narrow common-gap
  sufficient condition Lean verified

### FG-0030 — Joint descendant bounds require complete supportwise gains

- **Affected result:** proposed joint-law generalization of T6
- **Problem:** replacing the product event probability by a joint
  terminal-belief/descendant mass removes independence, but it does not by
  itself control harmful omitted outcomes, pre-existing comparator option
  value, infeasible long projects, or a declared gain that ignores
  path-dependent continuation and future-menu displacement.
- **Exact counterexamples:** `joint-descendant-bound-gauntlet-v1` preserves
  eight reduced fixtures. Harmful non-\(g\) continuation makes the
  uncorrected bound \(1/2\) while actual value is zero; omitting a negative
  operating adjustment does the same. A project already valuable on both
  sides and a distinct positive-premium comparator each make an uncorrected
  unit bound exceed zero insertion value. Two success paths with the same
  terminal belief but gains zero and two reject use of the larger path as a
  terminal floor. A direct gain two combined with loss of a future option
  worth four rejects any floor that omits menu changes. A duration-two
  project at horizon one rejects the bound without \(d\le h\). Perfect
  correlation placing success only at the zero-gain belief makes the product
  shortcut \(1/4\) while the correct joint term is zero.
- **Search:** 2,204,496 exact primary checks, 419,904 correlated-law checks,
  734,832 negative-adjustment checks, and 2,204,496 multi-descendant checks
  have zero failures. The harmful-outcome correction has zero failures across
  171,072 checks while the uncorrected omission fails 20,736 times. The
  positive-comparator correction has zero failures across nine checks while
  the uncorrected bound fails four times.
- **Resolution:** retain the exact operating adjustment, duration fit,
  post-insertion-only project enablement, and zero-premium comparator. Define
  \(G\) as a supportwise floor on the complete continuation difference,
  including menu changes. Derive omitted-outcome nonnegativity from the
  insertion-only raw update or subtract its explicit expected harm. Use the
  joint event mass directly; recover the product formula only under
  event-specific independence. A path-level formula is the extension when
  continuation retains path memory, and distinct nonnegative descendant
  events may be summed.
- **Status:** resolved for the current insertion-only finite model. The exact
  gauntlet passed; the joint-law theorem, terminal pushforward identity,
  product corollary, comparative statics, focused axiom audit, and exact joint
  carrier example are Lean verified. Harmful-update and path-memory extensions
  remain explicitly corrected specification variants, not claims of the
  current raw model.

### FG-0031 — Productive compression omits retention burden

- **Affected result:** future minimum-resource, capacity-constrained, and
  penalized-retention theorems
- **Problem:** the existing compressed state \(K_L=(F_L,C_L)\) is sufficient
  for the productive raw transition and value, but it does not identify the
  new additive burden \(W(L)\). Two raw libraries may have the same frontier
  and closure while retaining different-weight representatives. Therefore
  existing UDI/value factorization cannot be reused as a net-value
  factorization for \(J_\lambda=V-\lambda W\).
- **Exact counterexample:** CX-RESOURCE-K-NET-01 uses two strategies with
  identical profiles and modules but weights one and two. Their singleton-
  active libraries have the same \(K\) and productive value but different net
  values at every \(\lambda>0\).
- **Resolution:** D-0111 keeps resource outside the raw transition and
  reserves \(K_L^W=(F_L,C_L,W(L))\) only for the outer optimizer. A future
  resource-aware equivalence theorem must assume both productive UDI and
  equal burden. It must not modify or strengthen the existing UDI theorem.
- **Status:** model convention resolved; exact Julia outer structure and
  duplicate-weight fixtures implemented; additive Lean weight/burden structure
  and productive equal-compressed-state value wrapper verified. The distinct
  equal-burden net-objective equivalence theorem remains open.

### FG-0032 — Discrete capacity optima need not have supporting prices

- **Affected result:** future capacity, penalized-envelope, resource-price,
  and constrained--penalized comparison results
- **Problem:** a finite library domain does not make its attainable
  resource--value frontier concave. Maximizing \(V-\lambda W\) exposes only
  supported points, whereas a hard capacity can select an unsupported
  attainable point. Treating the two problems as strongly equivalent would
  add an unproved convexity or integrality hypothesis.
- **Exact counterexample:** CX-OPT-LAGRANGE-UNSUPPORTED-01 uses attainable
  pairs \((0,0),(1,1),(2,3)\). Budget one selects \((1,1)\), but penalty
  support would require both \(\lambda\le1\) and \(\lambda\ge2\). The
  Lagrangian dual value is \(3/2\) against primal value one.
- **Resolution:** D-0112 and `OPTIMIZATION_PROBLEM_SPEC.md` define capacity
  and penalty optimization separately, keep their optimizer correspondences
  set-valued, and assume no zero duality gap or recovery of every capacity
  optimum by a price. Randomized/convexified retention is extension-only.
- **Status:** definition boundary resolved; exact two-active-strategy Julia
  realization and unsupported-point certificate implemented; Lean
  declarations and any positive equivalence theorem remain open

### FG-0033 — Weighted local-versus-global separation

- **Affected result:** planned local irreducibility versus global
  minimum-resource compression theorem
- **Problem:** the current T3 trace proves compressed-state and productive
  value preservation, and the Julia fixed-point routine checks absence of a
  remaining safe single deletion. Neither layer has resource weights or
  compares the endpoint with every member of
  \(\mathfrak F_{\mathrm{safe}}(L)\). The existing Lean duplicate-encoding
  example proves only that equal compressed states can have different raw
  representatives.
- **Exact resolution:** CX-OPT-PRUNE-WEIGHT-01 and
  CX-OPT-LOCAL-NONGLOBAL-01 give the carrier-minimal two-active duplicate
  witness. CX-OPT-GREEDY-WEIGHT-01 gives the size-minimal strict-heaviest-
  first failure with two singleton carriers of weights \(2,2\) and a bundle
  carrier of weight \(3\). Exact enumeration verifies the complete feasible
  sets, traces, irreducibility, and global optimizer sets.
- **Human-proof resolution:** `SAFE_COMPRESSION_THEOREM_SPEC.md` and
  `SAFE_COMPRESSION_PROOF_OUTLINE.md` now state and derive the one-way
  minimum-to-irreducible result, give the unit-weight complete-trace
  counterexample, and derive the equal-active-weight cardinality corollary.
- **Status:** the core gap is resolved for one-deletion irreducibility. Lean
  now distinguishes exact feasibility, local one-deletion irreducibility, and
  global minimum burden; proves minimum-to-one-deletion irreducibility and
  rechecked endpoint feasibility; and formalizes both the unit-weight
  nonglobal endpoint and `(2,2,3)` unique-heaviest-safe-first failure. The
  equal-active-weight cardinality corollary, the generic monotonicity bridge
  to inclusion-wise irreducibility, and the other minimized unequal-weight
  fixture remain open.

### FG-0034 — Discrete optimization shape shortcuts are false

- **Affected results:** proposed penalized envelope, capacity comparative
  statics and elasticity statements
- **Problem:** finiteness alone does not imply capacity concavity, diminishing
  returns, raw-inclusion nesting, optimizer uniqueness, differentiability, or
  closure-cardinality sufficiency. A level elasticity is unbounded as its
  innovation-margin denominator approaches zero.
- **Exact counterexamples:** CX-OPT-CAPACITY-NONCONCAVE-01,
  CX-OPT-CAPACITY-INCREASING-RETURNS-01,
  CX-OPT-PENALIZED-INCLUSION-SWITCH-01,
  CX-OPT-PENALIZED-BREAKPOINT-TIE-01,
  CX-OPT-CLOSURE-CARDINALITY-ELASTICITY-01,
  CX-OPT-ELASTICITY-ZERO-MARGIN-01, and CX-OPT-VALUE-KINK-01.
- **Surviving replacement:** FX-OPT-PENALIZED-BURDEN-MONOTONE-01 supports the
  general algebraic statement that every high-price optimizer has weakly
  lower burden than every low-price optimizer.
- **Resolution:** `OPTIMIZATION_THEOREM_REVISIONS.md` replaced every affected
  target before Lean work. The revised finite PEN burden order, the CAP
  monotonicity/breakpoint core, the exact increasing-return CAP boundary, and
  the normalized bridge-margin boundary now have focused axiom-audited Lean
  declarations. No false strengthening is formalized.
- **Status:** false shortcuts remain refuted; the revised PEN/CAP/BEM cores are
  Lean verified, while their separately listed topology and adapter
  extensions remain open

### FG-0035 — Complexity proof lacks a formal complexity layer

- **Affected result:** proposed SC-COMP complexity theorem
- **Problem:** the repository has exact finite library and closure structures
  but no Lean encoding of binary finite inputs, polynomial-time reductions,
  weighted set cover, NP membership, or NP-hardness. Therefore the clean
  paper-level reductions cannot yet pass the manuscript claim gate as a
  Lean-verified theorem.
- **Human resolution:** `COMPLEXITY_AUDIT.md` and
  `SAFE_COMPRESSION_COMPLEXITY_APPENDIX_PROOF.md` give explicit
  weight-preserving polynomial reductions from weighted set cover to the
  closure-only, frontier-only, and combined identity-closure problems. They
  also isolate the conditional closure-evaluation requirement for
  general-closure NP membership.
- **Executable validation:**
  `julia/src/SafeCompressionComplexity.jl` and the registered exact fixture
  verify every candidate mask in the constructed example and all 265
  covering three-set/three-element incidence systems.
- **Resolution boundary:** register SC-COMP as proposed and appendix-ready,
  but leave the active manuscript unchanged until a matching Lean declaration
  builds without prohibited placeholders and receives an axiom audit.
- **Status:** informal complexity proof and exact Julia construction
  complete; Lean complexity formalization open

### FG-0036 — Penalized active-face topology is only partially formalized

- **Affected result:** proposed PEN / optimization T6
- **Problem:** the exact outer optimizer evaluates rational prices, while the
  analytic envelope uses an explicit real-price extension. Lean now verifies
  the generic finite real envelope, but the proposed active-face one-sided
  slopes, subdifferential, global affine-cell partition, and raw nonnesting
  boundary are not yet encoded. The Julia function `penalty_breakpoints`
  returns zero plus all nonnegative pairwise intersections, including
  inactive intersections; it is a candidate superset rather than an actual-
  kink classifier.
- **Human resolution:** `PENALIZED_ENVELOPE_SPEC.md` defines the canonical real
  extension, distinguishes candidate switching prices from globally active
  breakpoints, proves all ten envelope conclusions, and gives the exact
  extreme-burden formulas for left and right slopes.
- **Boundary evidence:** the existing exact resource fixtures validate
  burden antitonicity, a multiple-optimizer breakpoint, a kink with slopes
  \(-1\) and \(0\), and a nonnested unique-optimizer switch.
- **Lean resolution:** `Optimization/PenalizedEnvelope.lean` proves the
  attained finite maximum, optimizer existence, nonincrease, convexity,
  continuity, finite switching candidates, strict-dominance affine slope,
  all-optimizer burden order, antitone selected burden, and local affine
  agreement outside the finite candidate set. Every unequal-burden optimizer
  tie is a candidate; no converse is asserted.
- **Additional local-slope resolution:** Actual breakpoints are defined as
  failure of local affine representation. Lean now proves directly that every
  price outside this actual set has an optimal locally representing branch
  and envelope derivative equal to minus that branch's burden.
- **Resolution boundary:** manuscript wording may use exactly the verified
  finite-envelope form. The stronger active-face/topology clauses remain
  proposed until matching declarations build. Any Julia actual-breakpoint
  classifier must still filter candidate intersections by global optimality.
- **Status:** requested finite-envelope core Lean verified; complete human PEN
  and exact instance validation retained; active-face one-sided formulas,
  global partition, raw nonnesting Lean witness, and actual-breakpoint
  implementation filter open

### FG-0037 — Capacity step core is formalized; stronger packaging remains open

- **Affected result:** proposed CAP / optimization T7
- **Problem:** exact Julia enumeration evaluates rational capacities, while the
  manuscript also uses a canonical real-capacity extension. The verified core
  must keep the fixed finite family, zero-burden inactive library, nonnegative
  capacity domain, strict value-breakpoint convention, and discrete shadow
  separate from stronger globally sorted, concavity, or jump-sum claims.
- **Human resolution:** `CAPACITY_VALUE_SPEC.md` proves feasibility and
  attainment from the zero-burden inactive library, monotonicity from nested
  feasible sets, and the right-continuous finite step representation from the
  sorted attainable burdens. It defines strict value breakpoints separately
  from tied optimizer-change thresholds and proves breakpoint containment.
- **Boundary evidence:** CX-OPT-CAPACITY-NONCONCAVE-01 gives a lumpy additive
  item and an exact optimizer jump. CX-OPT-CAPACITY-INCREASING-RETURNS-01 gives
  two unit-cost carriers of jointly required modules. The new direct exact
  coverage record CX-OPT-SUBMODULAR-CAPACITY-01 shows that even monotone
  submodular value under unit weights can have capacity marginals
  \((3,1,2,0)\).
- **Sufficient-condition boundary:** equal-unit additive value gives sorted
  nonincreasing lattice marginals. Submodularity becomes sufficient only with
  additional structure such as a greedy chain that is exact at every
  cardinality. Ordinary concavity on the real axis requires a convexified
  fractional or randomized extension and is not a property of the
  deterministic step function.
- **Lean resolution:** `Optimization/CapacityValue.lean` proves finite
  optimizer attainment, monotonicity, half-open constancy between consecutive
  attainable burdens, finite breakpoint containment, and nonnegative exact
  shadows. `CapacityCounterexample.lean` proves the joint-capability profile
  `(0,0,1)` and increasing unit marginal. The separate
  `CapacityDiminishingReturns.lean` proves antitone grid shadows only for the
  sorted additive equal-unit profile. All are focused and comprehensively
  axiom-audited.
- **Resolution boundary:** the globally sorted/right-continuous partition
  packaging, jump-sum identity, optimizer-switch selection theorem, typed
  eligible-catalog adapter, lumpy-item Lean witness, and submodular-coverage
  witness remain human/Julia-only. No general-model submodularity or concavity
  claim may be introduced.
- **Status:** requested finite CAP core, complementarity counterexample, and
  additive equal-unit grid sufficient condition Lean verified; listed
  strengthenings remain open

### FG-0038 — Replacement safety must be candidate-relative

- **Affected result:** supporting REP / capacity-constrained replacement
- **Problem:** the proposed statement “if no safe deletion creates enough
  capacity, admission requires a true value trade-off” is false when “safe”
  means safe relative only to the current library \(L\). The candidate can
  replace the deleted incumbent's frontier or modules. Even failure of
  candidate-relative structural equality need not imply strict loss at one
  fixed belief and horizon without an objective-level strictness condition.
- **Exact counterexample:** CX-OPT-NO-PRESAFE-STILL-ZERO-LOSS-01 reuses the
  registered exact capacity-release fixture. The incumbent and candidate
  carry the same sole module. Deleting the incumbent is unsafe before
  insertion but safe after insertion and has zero displacement loss.
- **Human resolution:** `REPLACEMENT_OPTIMIZATION_SPEC.md` separates
  pre-admission structural safety, candidate-relative structural safety, and
  zero displacement loss. It proves
  \[
    A_c=G_c-\ell_c^\star
  \]
  and states the exact true-trade-off criterion as absence of a
  capacity-feasible zero-loss deletion. A structural version additionally
  requires that every relevant summary change strictly lowers the stated
  objective.
- **Additional boundary:** CX-OPT-POSITIVE-CANDIDATE-REJECT-01 gives a direct
  exact monotone value table in which both standalone and unconstrained
  incremental candidate value are positive, but required displacement loss
  is larger and acceptance is strictly suboptimal.
- **Resolution boundary:** retain REP as a supporting proposition only. Do
  not place the rejected pre-safe-loss implication or a general strict
  frontier/closure detectability claim in the active manuscript or Lean.
- **Status:** corrected human statement and exact finite counterexamples
  complete; Lean formalization and dedicated generated fixtures open

### FG-0039 — Bridge-margin elasticity boundary is formally resolved

- **Affected result:** supporting BEM and the canonical bridge component of
  planned optimization T8
- **Problem:** T4 kernel-checks the exact rational identity
  \(\beta^d\rho^d\pi C-\kappa\), but it does not define a real-coordinate
  extension, point elasticities, normalized margin, fragility, or the
  zero-margin limit. The broader wording “diverges as \(M\downarrow0\)” is
  false when gross opportunity also vanishes; \(\kappa=0\) and
  \(C\downarrow0\) leaves the elasticities at \((d,d,1,1)\).
- **Exact counterexample:** CX-BEM-VANISHING-GROSS-SCALE-01 records the
  rational family \(C_n=1/n\), \(\kappa=0\), for which \(A_n=M_n\downarrow0\)
  but \(m_n=1\) and no elasticity magnitude diverges.
- **Human resolution:** BRIDGE_ELASTICITY_SPEC.md fixes \(d\), names every
  held-fixed primitive, restricts ordinary elasticity to \(M>0\), and proves
  the exact formulas in the canonical real extension. It states divergence
  under \(m=M/A\downarrow0\), or under \(M\downarrow0\) with a positive
  gross-scale floor, and supplies signed-margin, threshold-ratio, action-
  region, and exact finite-change reporting at or below zero.
- **Lean resolution:** `Compression/BridgeMarginElasticity.lean` defines the
  real extension, proves all five margin and positive-loss derivatives,
  verifies the elasticity and normalized-fragility rewrites, formalizes the
  corrected right-limit blow-up with a fixed positive gross scale, and checks
  the costless vanishing-gross boundary and exact finite example.
- **Remaining work:** a reusable Julia routine and any concrete adapter from
  the exact T4 fixture remain separate validation tasks.
- **Status:** BEM real-calculus and boundary core Lean verified and
  axiom-audited; Julia/model-adapter work open

### FG-0040 — Innovation duration finite derivative core is resolved

- **Affected result:** proposed IDCV / planned optimization T9
- **Problem:** S6 kernel-checks a vector-valued exact rational finite sum,
  monotonicity, and discount--survival cross differences, but deliberately
  introduces no real derivative. The former T9 title also left “duration” and
  “convexity” ambiguous among project delay, admission time, policy duration,
  and several possible curvature variables.
- **Human resolution:** INNOVATION_DURATION_SPEC.md fixes a scalar
  nonnegative exposure sequence independent of
  \(\alpha=\beta\rho>0\). It defines normalized contribution weights,
  innovation duration as their mean date, and innovation convexity as their
  timing variance. Finite differentiation proves that duration is the log
  elasticity of potential and that its log-\(\alpha\) derivative is
  nonnegative convexity. The specification gives sharp duration bounds,
  complete equality cases, an exact pairwise variance certificate, and two
  direct rational example pairs.
- **Boundary:** IDCV is not a sign theorem for changing primitive project
  duration. FG-0025 and the existing opposite-direction delay examples remain
  binding. If exposure \(z_t\) changes with \(\alpha,\beta,\rho\), additional
  derivative terms are required.
- **Lean resolution:** `Coverage/InnovationDuration.lean` defines the finite
  scalar real potential, normalized weights, duration, and convexity. It
  verifies the polynomial and quotient derivatives, the scaled moment and
  duration identities, the weighted-variance formula, nonnegativity, and four
  exact examples.
- **Remaining work:** support equality cases, duration endpoint bounds, a
  named S6 rational-to-real component adapter, separate log-composition
  derivative declarations, and reusable Julia evaluation remain open. The
  manuscript uses the verified scaled-derivative form rather than claiming
  those extensions Lean verified.
- **Status:** IDCV finite derivative/variance core Lean verified and
  axiom-audited; listed extensions and Julia counterpart open

### FG-0041 — T5 channel elasticity algebra is formalized conditionally on a path

- **Affected result:** proposed CED / planned optimization T8
- **Problem:** T5 kernel-checks the exact rational identity
  \(I=\Delta^{\mathrm{op}}+\Delta^{\mathrm{gen}}\) at fixed model
  parameters, but it does not define a real parameter path or derivatives.
  The share-weighted elasticity expression is also invalid as an ordinary
  convex average when either component is zero or negative, and optimized
  values may be nondifferentiable at action switches.
- **Human resolution:** CHANNEL_ELASTICITY_SPEC.md requires one common named
  positive differentiable path. Differentiation gives the scaled level
  identity. With positive total value, direct operational and generative
  contributions sum to total elasticity without dividing by component
  levels. Only strictly positive component levels authorize the convex
  weighted-average rewrite.
- **Interpretation boundary:** discount, innovation survival, admission,
  project cost, frontier scale, and belief-kernel persistence must each state
  the affected primitives. Innovation-only survival, admission, and cost
  paths leave passive operational value fixed; shared paths need not.
  Persistence has no universal sign, and optimizer switches use one-sided or
  finite changes.
- **Lean resolution:** `Value/ChannelElasticity.lean` takes a neighborhood
  accounting identity and verified derivatives on one real path. It proves
  derivative additivity, the sign-free scaled and total-normalized
  contribution decompositions, the positive-channel weighted-average
  corollary, positive-share properties, and all three exact path examples.
- **Remaining work:** a concrete adapter from a named T5 primitive path and a
  reusable Julia evaluator remain separate tasks. Optimizer-kink interpretation
  is limited to PEN's verified finite envelope and exact one-sided or
  finite-change diagnostics; it is not a CED theorem.
- **Status:** CED conditional real-path core Lean verified and axiom-audited;
  T5 path adapter and Julia counterpart open

### FG-0042 — Closed by public-preprint scope reduction

- **Former target:** a general set-valued library/action switching theory.
- **Resolution:** the target has been removed from the current theorem
  architecture, formalization roadmap, validation table, and manuscript claim
  package.  No Lean or Julia completion is required for this preprint.
- **Retained results:** PEN's Lean-verified finite envelope and finite pairwise
  candidate prices; globally active exact breakpoints in the canonical
  benchmark; exact optimizer margins; Bellman action-gap diagnostics; and
  one-sided or finite-change interpretation at actual switches.
- **Boundary:** pairwise intersections become breakpoints only after global
  envelope filtering, primitive-coordinate grid changes are brackets rather
  than exact roots, and no general productive-parameter switching theorem is
  claimed.
- **Status:** closed by scope; any general set-valued switching theory is
  future work outside the present preprint

### FG-0043 — Discrete resource elasticities lack correspondence-aware adapters

- **Affected result:** proposed supporting CPEL extending optimization T6--T7
- **Problem:** CAP defines exact capacity shadows and PEN proves burden
  antitonicity and breakpoint slopes, but no declaration normalizes finite
  changes by positive bases. The existing Julia routines also do not expose a
  correspondence-aware scalar demand rule at unequal-burden price ties.
- **Human resolution:** `CAPACITY_ELASTICITY_SPEC.md` expresses capacity
  elasticity as base capacity divided by base value times the per-unit shadow,
  and expresses the shadow as the exact sum of crossed strict value jumps. It
  defines price-demand elasticity only at singleton positive endpoint burden
  sets and proves nonpositivity from PEN's all-optimizer-pairs burden order.
- **Boundary:** the capacity statistic is a forward arc, not a derivative;
  its breakpoint spike is attached to the interval that reaches the jump.
  Optimizer-only capacity changes need not move value. Unequal-burden price
  ties make scalar demand elasticity undefined without selection, while
  equal-burden raw-library ties can retain a unique demand.
- **Exact evidence:** a positive-baseline module-complementarity table gives
  increasing capacity shadows and exact elasticity spikes. The registered
  nonnested penalized-switch branches give zero and \(-3/4\) demand arcs and
  an exact selection-dependence witness at the tied price.
- **Needed formal work:** define exact finite arcs with denominator guards,
  connect capacity arcs to the strict jump sum, define the image of finite
  optimizer correspondences under burden, prove price-demand antitonicity in
  that representation, and add focused axiom output. A reusable Julia report
  routine remains separate.
- **Status:** complete human deduction and direct exact rational examples;
  Lean and reusable Julia counterparts open

## Gap-response protocol

When a proof attempt exposes a new mismatch:

1. stop work on the affected theorem;
2. preserve the failed statement and exact diagnostic;
3. add a gap entry before revising the theorem;
4. seek the smallest exact counterexample;
5. record it in `COUNTEREXAMPLES.md`;
6. revise the manuscript statement explicitly;
7. update assumptions, notation, formalization map, and theorem ledger; and
8. resume only after the dependency chain compiles.
