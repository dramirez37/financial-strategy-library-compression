# Assumption Registry

## Authority and status

This file is the sole registry for mathematical assumptions. The definitions
and assumptions below are **adopted for the proposed finite theorem package**.
Adoption locks the model interface; it does not establish any theorem or
confer Lean-verification status.

Status vocabulary:

- **adopted:** exact wording fixed for the cited proposed results;
- **extension-only:** excluded from the finite Lean core;
- **rejected:** known to be unnecessary, false, or outside Paper 1;
- **revised:** retained only in Git history after replacement.

## Methodological commitments

These are governance rules rather than mathematical hypotheses:

- **M-01:** Julia is the primary computational language.
- **M-02:** Lean 4 verifies only exact encoded statements.
- **M-03:** the theorem core is finite and exact.
- **M-04:** proof-level probabilities, rewards, costs, and discounting use
  rational arithmetic.
- **M-05:** floating-point calculations cannot serve as proofs.
- **M-06:** informal validity, Lean verification, Julia validation, and
  empirical relevance are reported separately.

## Adopted core assumptions

### A-FIN — Finite nonempty carriers

- **Exact wording:** \(X=\operatorname{Fin}(m)\) with \(2\le m\).
  `Belief`, `StrategyId`, `ModuleId`, and `ResearchProject` are nonempty finite
  types with decidable equality.
- **Purpose:** makes all model carriers enumerable and preserves a genuinely
  hidden market state.
- **Status:** adopted
- **Used by:** T1--T7

### A-RATPROB — Exact finite rational distributions

- **Exact wording:** for every finite carrier \(A\), a probability
  distribution is a function \(p:A\to\mathbb Q\) with pointwise
  nonnegativity and finite sum one. Every kernel used in the theorem core has
  this form.
- **Purpose:** makes sums and equality exact in Lean.
- **Status:** adopted
- **Used by:** T1, T2, T4--T7

### A-BELIEF-GRID — Finite filtered information state

- **Exact wording:** `Belief` is a finite grid \(B\). There is an injective map
  \(\mu:B\to\Delta_{\mathbb Q}(X)\), at least one \(\mu_b\) is non-Dirac, and
  the already-filtered information state evolves according to
  \(P_B:B\to\Delta_{\mathbb Q}(B)\).
- **Purpose:** supplies exact partial information without formalizing Bayes
  normalization in the primary theorem path.
- **Status:** adopted
- **Used by:** T1, T4--T7

### A-STRATEGY — Immutable finite strategy catalog

- **Exact wording:** each \(s:\texttt{StrategyId}\) indexes one immutable
  strategy row with hidden-state payoff \(u_s:X\to\mathbb Q\) and finite
  module set \(\operatorname{mods}(s)\). Neither table depends on a library,
  admission history, or time. The distinguished inactive row \(s_0\) has
  \(u_{s_0}(x)=0\) for every \(x\) and
  \(\operatorname{mods}(s_0)=\varnothing\).
- **Purpose:** allows operational and generative information to be updated
  from a candidate identifier alone.
- **Status:** adopted
- **Used by:** T1--T7

### A-PROFILE — Belief-conditional operational payoff

- **Exact wording:**
  \(j_s(b)=\sum_x\mu_b(x)u_s(x)\). Current operation selects a strategy with
  maximum \(j_s(b)\) in the current library; operational choice has no direct
  effect on \(P_B\), generation, or verification. In particular,
  \(j_{s_0}(b)=0\) at every belief.
- **Purpose:** makes the operational library relevant only through its upper
  envelope.
- **Status:** adopted
- **Used by:** T1--T7

### A-LIBRARY — Set-valued verified library

- **Exact wording:** there is a distinguished inactive baseline strategy
  \(s_0\), whose profile is identically zero and whose module set is empty.
  An admissible library is a finite set \(L\) of strategy identifiers with
  \(s_0\in L\). Multiplicity, age, provenance, order, and rejected raw
  candidates are not state variables. Only a verified candidate is admitted,
  by set union.
- **Purpose:** ensures nonempty operational maxima, a zero operational lower
  bound, and a finite library state.
- **Status:** adopted
- **Used by:** T1--T7

### A-RESOURCE-WEIGHT — Fixed additive catalog burden

- **Exact wording:** there is an immutable catalog-indexed table
  \(w:S\to\mathbb Q_{\ge0}\) with
  \(w_{s_0}=0\) and \(w_s>0\) for every \(s\ne s_0\). For every admissible
  library,
  \[
    W(L)=\sum_{s\in L}w_s
        =\sum_{s\in L\setminus\{s_0\}}w_s.
  \]
  The weight depends only on the strategy identifier. It does not depend on
  belief, library composition, age, usage, time, admission history, or
  validation outcomes.
- **Inactive convention:** the mandatory inactive strategy has zero burden.
  This is the sole exception to strict positivity and gives
  \(W(\{s_0\})=0\). Paper 1 does not use the equivalent alternative of a
  fixed positive mandatory burden.
- **Purpose:** represents exact storage, validation, maintenance, monitoring,
  retrieval, and governance burden while preserving a linear finite
  retention objective.
- **Status:** adopted; implemented in the exact Julia outer optimizer and in
  Lean by `StrategyResourceWeights`, `resourceBurden`, and `libraryBurden`,
  with the foundational order lemmas axiom-audited under OPT-FND
- **Used by:** future exact safe-compression, capacity, and penalized-retention
  results; not used by existing T1--T7

### A-RESOURCE-OUTER — One-time ex ante retention layer

- **Exact wording:** one admissible retained library is chosen at an outer
  review. Exact safe compression chooses from
  \(\mathcal R(L)=\{L'\subseteq L:s_0\in L'\}\) for a fixed current library
  \(L\). Capacity-constrained and penalized retention choose from all
  admissible sublibraries of the outer-certified retention-eligible catalog
  \(S_\theta^{\mathrm{elig}}\). Resource burden may enter the objective or the
  rational feasibility constraint \(W(L')\le B\), with
  \(B\in\mathbb Q_{\ge0}\). It does not enter operating reward, project
  initiation cost, generation, verification, admission, belief evolution,
  research timing, the raw library update, or any compressed pushforward.
  After the outer choice, the existing raw process starts from \(L'\) without
  statewise capacity enforcement.
- **Value convention:** \(V_\theta(b,L')\) is the existing productive value
  before resource penalty. For
  \(\lambda\in\mathbb Q_{\ge0}\),
  \[
    J_{\theta,\lambda}(b,L')
      =V_\theta(b,L')-\lambda W(L').
  \]
  The abbreviated notation is \(J_\lambda=V-\lambda W\) when the initial
  state and parameter bundle are fixed.
- **Purpose:** separates a one-time retention decision from the productive
  Bellman process and prevents a hard capacity from silently changing raw
  candidate admission.
- **Status:** adopted for the Paper 1 resource-optimization layer. OPT-FND
  verifies the source-relative safe and capacity-feasibility foundations;
  full eligible-catalog optimization, penalty, and replacement remain open
- **Used by:** exact safe-compression, capacity, penalized-envelope, and
  replacement results; not used by existing productive T1--T7

### A-OPTIMIZATION-DOMAIN — Outer-certified finite selection domain

- **Exact wording:** \(S_\theta^{\mathrm{elig}}\subseteq S\) is the finite set
  of strategies independently catalog-certified and eligible for retention at
  the outer decision, and \(s_0\in S_\theta^{\mathrm{elig}}\). This outer
  certification is distinct from stochastic raw verification under
  A-VERIFY. For every finite
  \(A\subseteq S\) with \(s_0\in A\), admissible selectable libraries are
  \[
    \mathfrak L(A)=\{L'\subseteq A:s_0\in L'\}.
  \]
  The notation \(L'\subseteq S\) in full-catalog optimization is shorthand
  for \(L'\in\mathfrak L(S_\theta^{\mathrm{elig}})\). Mere raw generation
  does not confer outer eligibility; the primary specification defines no
  conversion from a generated-but-unadmitted raw candidate to the eligible
  set.
- **Value scope:** the primary exact problems use rational finite-calendar-
  horizon productive value \(V_\theta(b,L')\). \(B\) and \(\lambda\) are
  nonnegative rationals outside the productive value. A stationary-value
  problem is a separately labeled variant.
- **Replacement scope:** a candidate \(c\) in the replacement problem is a
  newly outer-certified active member of
  \(S_\theta^{\mathrm{elig}}\setminus L\). Deletions satisfy
  \(D\subseteq L\setminus\{s_0\}\). The problem is a static outer review
  conditional on retaining \(c\), not a modification of the raw admission
  transition.
- **Closure:** all four problems use the adopted extensive, monotone,
  idempotent closure operator. Identity closure is a specialization only.
- **Purpose:** fixes the domain differences among source-relative
  compression, full-catalog selection, and conditional replacement before
  implementation or proof work.
- **Status:** adopted and definition-frozen; the eligible carrier is implicit
  in the exact Julia outer problem. Lean now represents source-relative exact
  safety with the general closure and proves finite minimum attainment; typed
  outer eligibility and the full-catalog optimizer carriers remain open
- **Used by:** future exact safe-compression, capacity, penalized-retention,
  and replacement results; not used by existing T1--T7

### A-LOCAL-GLOBAL-COMPRESSION — Rechecked local reduction versus global search

- **Exact wording:** for an active \(s\in K\setminus\{s_0\}\), a safe
  deletion certificate at the current library \(K\) consists of
  \(F_{K\setminus\{s\}}=F_K\) and
  \(C_{K\setminus\{s\}}=C_K\). If \(K\) is safe-feasible relative to source
  \(L\), the deletion remains feasible for \(P_{\mathrm{safe}}(L)\) and
  lowers burden by exactly \(w_s>0\). A stepwise trace must recheck both
  equalities after every deletion. An endpoint is called irreducible only
  when no active current-library deletion is certified. Global minimum weight
  always compares every member of
  \(\mathfrak F_{\mathrm{safe}}(L)\), not only one trace.
- **Monotonicity bridge:** under A-FRONTIER and A-CLOSURE, absence of a
  certified one-strategy deletion is equivalent to absence of any strict
  safe-feasible sublibrary of the endpoint.
- **Greedy boundary:** a deletion heuristic must declare its priority and tie
  breaker. Safety of its rechecked steps supplies no approximation ratio or
  global-optimality claim.
- **Witness boundary:** the unit-weight bundle-versus-singletons endpoint and
  the `(2,2,3)` unique-heaviest-safe-first failure now have compiled exact Lean
  counterparts. Other minimized catalogs remain Julia evidence unless a
  corresponding declaration is separately audited.
- **Status:** conceptual definitions frozen; exact Julia resource wrapper,
  enumeration, and weighted witnesses implemented. Lean verifies the
  current-membership safe-deletion certificate, component preservation,
  source-feasible strict reduction, minimum attainment, global-minimum-to-
  one-deletion irreducibility, rechecked endpoint feasibility, and the two
  stated local/global boundary witnesses. Generic complete-trace-to-
  inclusion-wise irreducibility remains pending
- **Used by:** planned local-versus-global compression results; the productive
  portion reuses T3, but this assumption does not alter existing T1--T7

### A-SAFE-COMPLEXITY-ENCODING — Explicit finite input and closure-evaluation boundary

- **Exact wording:** complexity statements use explicitly listed finite
  beliefs, policies, module incidences, and binary-encoded exact rational
  profiles, weights, and budget. The primary SC-COMP theorem specializes to
  identity closure. A selected-policy incidence vector is the certificate.
  General-closure NP membership is asserted only for a named representation
  in which closure evaluation and equality are polynomial in the encoded
  input size.
- **Identity specialization:** identity closure is an extensive, monotone,
  idempotent member of the general closure class. It therefore transfers all
  identity-closure lower bounds to any general-closure representation class
  that can encode it.
- **Excluded shortcut:** no arbitrary closure oracle is presumed
  polynomial-time, and general closure is not reduced to independent
  per-module cover obligations when derivation has complementarities.
- **Purpose:** makes NP membership, polynomial reduction size, and the
  identity/general-closure distinction representation-explicit.
- **Status:** adopted for proposed SC-COMP; complete human reduction and exact
  Julia fixture, Lean complexity formalization pending
- **Used by:** SC-COMP only; not used by the productive T1--T7 or SC

### A-RESOURCE-OPTIMIZATION-BOUNDARY — Discrete shape and elasticity limits

- **Exact wording:** optimizer correspondences are set-valued. For
  \(\lambda_1<\lambda_2\), every low-price penalized optimizer has burden
  weakly at least that of every high-price optimizer. No raw-inclusion nesting
  is assumed. Capacity value is finite and nondecreasing, but no concavity or
  diminishing-marginal-return property is assumed. No capacity optimizer is
  presumed price-supported. Any elasticity must name a scalar perturbation
  and held-fixed primitives; a level elasticity is stated only on a domain
  where its denominator is bounded away from zero.
- **Rejected shortcuts:** unconditional pruning optimality, breakpoint
  uniqueness, global differentiability, capacity concavity, strong
  constrained--penalized equivalence, closure-cardinality elasticity, and a
  uniform elasticity bound at zero innovation margin.
- **Exact boundary records:** CX-OPT-PRUNE-CARDINALITY-01 through
  CX-OPT-VALUE-KINK-01 and the survivor
  FX-OPT-PENALIZED-BURDEN-MONOTONE-01 in
  `experiments/results/resource_optimization_fixtures/`.
- **Status:** adopted from exact Julia counterexample search and general
  algebra; the resource/capacity foundation is Lean verified, while the PEN,
  CAP step, and elasticity shape theorems remain open
- **Used by:** revised target T2 and T4--T9 in
  `OPTIMIZATION_THEOREM_REVISIONS.md`

### A-BRIDGE-MARGIN-ELASTICITY — Named real-coordinate extension of T4

- **Exact wording:** fix \(d\in\mathbb N_{\ge1}\) and extend the scalar T4
  expression to real coordinates
  \(0<\beta<1\), \(0<\rho,\pi\le1\), \(C>0\), and \(\kappa\ge0\).
  Set \(A_{\mathrm{br}}=\beta^d\rho^d\pi C\) and
  \(M_{\mathrm{br}}=A_{\mathrm{br}}-\kappa\). A partial derivative varies
  exactly one named continuous coordinate while holding \(d\) and every
  other primitive fixed. Ordinary margin elasticity and
  \(\mathcal F_{\mathrm{br}}=A_{\mathrm{br}}/M_{\mathrm{br}}\) are stated
  only on \(M_{\mathrm{br}}>0\).
- **Boundary wording:** zero-margin divergence means
  \(M_{\mathrm{br}}/A_{\mathrm{br}}\downarrow0\). The weaker condition
  \(M_{\mathrm{br}}\downarrow0\) is sufficient only with a positive gross-
  scale floor and is false as a universal divergence condition. At
  \(M_{\mathrm{br}}\le0\), report the signed level margin, the action region,
  the threshold ratio \(\kappa/A_{\mathrm{br}}\), or exact finite changes.
- **Exact-rational boundary:** derivatives belong to the declared real
  extension. Coordinatewise finite-change identities remain the primary
  exact-rational report when an endpoint has nonpositive margin or a
  perturbation crosses the action boundary.
- **Status:** adopted for supporting BEM; complete human algebra, Lean
  formalization and reusable Julia implementation absent
- **Used by:** BEM and the canonical bridge component of planned optimization
  T8 only

### A-CHANNEL-ELASTICITY — Common differentiable path for T5 channels

- **Exact wording:** fix the T5 horizon, belief, base library, inserted
  strategy, and every primitive not named by a positive scalar
  \(x\in U\subset\mathbb R_{>0}\). Along one common real path, define total,
  operational, and generative insertion values \(I(x)\),
  \(\Delta^{\mathrm{op}}(x)\), and \(\Delta^{\mathrm{gen}}(x)\). Require the
  T5 identity to hold pointwise on a neighborhood of the evaluation point and
  require all three functions to be differentiable there.
- **Normalization boundary:** total elasticity and the direct channel
  contributions require \(I>0\). Calling their decomposition a convex
  weighted average additionally requires
  \(\Delta^{\mathrm{op}}>0\) and \(\Delta^{\mathrm{gen}}>0\). A zero or
  negative component uses its total-normalized derivative contribution and
  is not assigned an ordinary real log elasticity.
- **Path boundary:** every channel uses the same perturbation and held-fixed
  convention. Probability endpoints use one-sided derivatives or a separately
  declared open real extension. At an optimizer switch, apply the identity to
  each existing one-sided derivative or use finite/arc changes.
- **Status:** adopted for proposed CED / planned optimization T8; complete
  human proof and direct exact rational examples, Lean formalization and
  reusable Julia implementation absent
- **Used by:** CED only; T5 remains independently Lean verified

### A-INNOVATION-DURATION — Fixed nonnegative exposure and log-parameter domain

- **Exact wording:** fix \(H\in\mathbb N_{\ge1}\), a positive real effective
  discount \(\alpha\), and a finite sequence
  \(z_0,\ldots,z_{H-1}\in\mathbb R_{\ge0}\) with nonempty positive support.
  The complete sequence \(z\) is independent of \(\alpha\). Define
  \(\Psi_H(\alpha;z)=\sum_{t<H}\alpha^tz_t>0\), normalized timing weights
  \(\omega_t^\Psi=\alpha^tz_t/\Psi_H\), innovation duration
  \(D_\Psi=\sum_tt\omega_t^\Psi\), and innovation convexity
  \(C_\Psi=\sum_t\omega_t^\Psi(t-D_\Psi)^2\).
- **Primitive decomposition:** for \(\alpha=\beta\rho\), both
  \(\beta\) and \(\rho\) are strictly positive. A primitive elasticity holds
  the other primitive and the complete sequence \(z\) fixed. Probability
  applications may impose the stronger bounds \(0<\beta<1\) and
  \(0<\rho\le1\).
- **S6 specialization:** after fixing an initial belief \(b\), the existing
  S6 potential supplies \(z_t=(P^tg)(b)\). Row stochasticity and
  nonnegative \(g\) establish \(z_t\ge0\). IDCV adds a separate
  real-coordinate derivative layer; no derivative is attributed to the
  existing rational S6 declaration.
- **Interpretation boundary:** \(D_\Psi\) is the timing centroid of fixed
  uncovered-value contributions, not primitive project duration, time to
  admission, a stopping time, or policy-induced duration. \(C_\Psi\) is
  curvature of \(\log\Psi_H\) in \(\log\alpha\), not convexity of general
  Bellman value in delay, capacity, or a changing kernel.
- **Status:** adopted for proposed IDCV / planned optimization T9; complete
  human derivation and direct exact rational examples, Lean formalization and
  reusable Julia implementation absent
- **Used by:** IDCV only; S6 remains independently Lean verified

### A-SWITCHING-ELASTICITY — Archived future-work assumptions

- **Exact wording:** fix a positive scalar parameter
  \(x\in U\subset\mathbb R_{>0}\). For the library envelope, fix belief,
  resource price, burden, and a nonempty finite feasible library family
  independently of \(x\). For the Bellman envelope, fix a nonempty finite
  action menu locally in \(x\). Require every named branch to be continuous;
  require differentiability only for derivative and one-sided-slope claims.
- **Margin and stability boundary:** the library margin and action margin are
  the largest branch value minus the second-largest value, counting one value
  per raw library or action. A strictly positive margin gives a unique
  maximizer and local stability by finiteness and continuity. Zero margin is
  necessary but not sufficient for an actual switching boundary.
- **Elasticity boundary:** within-branch, left, and right ordinary
  elasticities require positive optimized value. A midpoint arc elasticity
  requires positive endpoint values. At a zero or negative value, use scaled
  level derivatives and exact finite changes.
- **Breakpoint boundary:** actual breakpoints require globally active branches
  and a locally changing optimizer correspondence. Pairwise intersections are
  candidates only. Positive current action margin does not remove a kink
  inherited from a downstream continuation envelope.
- **Status:** archived outside the public-preprint claim architecture; no
  Lean or reusable Julia completion is required for the current paper
- **Used by:** an internal archived switching-elasticity research note omitted
  from the public release export; PEN and the existing Bellman results retain
  their independent evidence statuses

### A-PENALIZED-ENVELOPE — Fixed finite family and real-price extension

- **Exact wording:** fix \(b,\theta\) and a nonempty finite feasible family
  \(\mathcal F\) that does not depend on the resource price. Each
  \(L\in\mathcal F\) has finite productive value
  \(v_L=V_\theta(b,L)\in\mathbb Q\) and nonnegative burden
  \(w_L=W(L)\in\mathbb Q_{\ge0}\). The exact rational inputs define the
  canonical real-price extension
  \(J_L(\lambda)=v_L-\lambda w_L\) for
  \(\lambda\in\mathbb R_{\ge0}\). At rational prices this is the original
  exact problem.
- **Primary domain:** for penalized retention,
  \(\mathcal F=\mathfrak L(S_\theta^{\mathrm{elig}})\). A restricted family
  is allowed only when separately named and fixed independently of
  \(\lambda\).
- **Value-sign boundary:** productive values may be positive, zero, or
  negative. Nonincrease in price uses only \(w_L\ge0\); the other envelope
  conclusions use finiteness.
- **Tie boundary:** the optimizer is the full argmax correspondence. Raw-
  distinct libraries with the same \((w_L,v_L)\) define the same affine
  branch and may remain tied on an interval.
- **Switching boundary:** pairwise switching prices are candidate
  intersections. An actual envelope breakpoint additionally requires global
  optimality of unequal-burden branches at that price.
- **Lean representation:** `Optimization.FinitePenalizedProblem` stores an
  arbitrary explicit nonempty finite family with real values and burdens
  nonnegative on that family. This directly represents the canonical real
  extension through the compiled `ofRational` adapter; the typed
  outer-certified catalog adapter remains separate.
- **Status:** adopted for PEN. The requested finite maximum,
  continuity/convexity/nonincrease, switching-candidate, local affine slope,
  and optimal-burden-order clauses are Lean verified. Active-face one-sided
  slopes, the global partition, and raw nonnesting remain human/Julia-only
- **Used by:** PEN / planned optimization T6 only

### A-CAPACITY-VALUE — Fixed finite family and real-capacity extension

- **Exact wording:** fix \(b,\theta\) and a nonempty finite feasible family
  \(\mathcal F\) that does not depend on capacity. Each \(L\in\mathcal F\)
  has finite productive value \(v_L=V_\theta(b,L)\in\mathbb Q\) and
  nonnegative burden \(w_L=W(L)\in\mathbb Q_{\ge0}\). The family contains a
  zero-burden library. The exact rational problem is
  \[
    V^\star(B)=\max\{v_L:L\in\mathcal F,\ w_L\le B\},
    \qquad B\in\mathbb Q_{\ge0}.
  \]
  Its canonical real-capacity extension uses the identical finite rational
  pairs and the identical feasibility inequality for
  \(B\in\mathbb R_{\ge0}\).
- **Primary domain:** for capacity-constrained retention,
  \(\mathcal F=\mathfrak L(S_\theta^{\mathrm{elig}})\). The mandatory
  inactive-only library supplies the zero-burden feasible point. A restricted
  family is allowed only when separately named, fixed independently of
  \(B\), and known to contain a zero-burden member.
- **Breakpoint boundary:** a capacity-value breakpoint is a positive point
  where the right-continuous value step strictly exceeds its left limit. A
  newly feasible tied optimizer may change the optimizer correspondence
  without creating a value breakpoint.
- **Shape boundary:** ordinary concavity of a nonconstant deterministic step
  function on the real capacity axis is not asserted. Discrete diminishing
  returns must name a budget grid. Monotone submodularity alone is
  insufficient; convexified fractional or randomized retention is an
  extension model.
- **Status:** adopted for proposed CAP; complete human proof and exact finite
  counterexamples, Lean formalization pending
- **Used by:** CAP / planned optimization T7 only

### A-DISCRETE-RESOURCE-ELASTICITY — Positive bases and singleton demands

- **Exact wording:** retain the fixed finite exact library family, productive
  values, nonnegative burdens, capacity step function, and penalized affine
  envelope of A-CAPACITY-VALUE and A-PENALIZED-ENVELOPE. Declare a positive
  rational finite increment \(\delta\). Capacity elasticity additionally
  requires \(B>0\) and \(V^\star(B)>0\). Resource-demand elasticity
  additionally requires \(\lambda>0\), a positive unique optimal burden at
  the base, and singleton optimal-burden correspondences at both endpoints.
- **Arc convention:** use the requested forward base normalization,
  \([\Delta V/V(B)][B/\delta]\) or
  \([\Delta W/W(\lambda)][\lambda/\delta]\). This is distinct from the
  a symmetric midpoint normalization.
- **Breakpoint boundary:** a capacity arc is positive only when its window
  crosses at least one strict capacity-value breakpoint. An optimizer-only
  capacity tie creates no value elasticity spike. At an unequal-burden price
  tie, optimal demand is a correspondence and the scalar point elasticity is
  undefined without a tie rule; use one-sided burdens or a cross-breakpoint
  arc with unique endpoints.
- **Status:** adopted for proposed supporting CPEL; complete human deduction
  and direct exact rational examples, Lean formalization and reusable Julia
  implementation absent
- **Used by:** CPEL only; CAP and PEN retain their independent evidence
  statuses

### A-REPLACEMENT-OPTIMIZATION — Conditional outer replacement and loss accounting

- **Exact wording:** fix a current finite library
  \(L\in\mathfrak L(S_\theta^{\mathrm{elig}})\), a newly outer-certified
  active candidate \(c\in S_\theta^{\mathrm{elig}}\setminus L\), and
  \(B\in\mathbb Q_{\ge0}\). Conditional replacement chooses
  \(D\subseteq L\setminus\{s_0\}\) and retains
  \(L^{c,D}=(L\setminus D)\cup\{c\}\). Productive value is weakly monotone
  under library inclusion on this finite family. The conditional problem is
  feasible exactly when \(w_c\le B\); the accept/reject comparison with
  \(V_\theta(b,L)\) additionally assumes \(W(L)\le B\) and that rejection
  means retaining \(L\).
- **Capacity accounting:** additive burden gives
  \[
    W(L^{c,D})=W(L)+w_c-W(D).
  \]
  Thus a feasible deletion must release at least
  \([W(L)+w_c-B]_+\). Resource burden enters this hard-capacity problem
  through feasibility, not as a silent subtraction from productive value.
- **Safety boundary:** pre-admission safety
  \(K_{L\setminus D}=K_L\), candidate-relative safety
  \(K_{L^{c,D}}=K_{L\cup\{c\}}\), and zero displacement loss at the fixed
  objective are distinct. Pre-admission safety implies candidate-relative
  safety, which implies zero loss under frontier--closure factorization.
  Neither converse is assumed.
- **Strict-loss boundary:** absence of a pre-admission or
  candidate-relative structural certificate does not by itself imply strict
  productive loss. A true-trade-off conclusion uses absence of every
  capacity-feasible zero-loss deletion or an explicit objective-level
  strict-loss hypothesis.
- **Status:** adopted for supporting REP; complete human proof and exact
  finite examples, Lean formalization pending
- **Used by:** REP only; not used by the primary optimization T1--T9

### A-CLOSURE — Finite module closure operator

- **Exact wording:**
  \(\operatorname{cl}:\mathcal P_{\mathrm{fin}}(M)\to
  \mathcal P_{\mathrm{fin}}(M)\) is extensive, monotone, and idempotent.
  With \(U_L=\bigcup_{s\in L}\operatorname{mods}(s)\), define
  \(C_L=\operatorname{cl}(U_L)\).
- **Purpose:** permits cross-strategy module composition and the local closure
  update used by T1 and T3.
- **Status:** adopted
- **Used by:** T1--T7

### A-FRONTIER — Value-envelope frontier

- **Exact wording:** for each admissible \(L\),
  \(F_L(b)=\max_{s\in L}j_s(b)\). The frontier stores the rational upper
  envelope \(B\to\mathbb Q\), not maximizing identifiers. Ties use equality of
  values; any maximizer may later be selected.
- **Purpose:** avoids over-distinguishing payoff-identical strategies.
- **Status:** adopted
- **Used by:** T1--T7

### A-GEN-FACTOR — Raw generation from declared closure inputs

- **Exact wording:** every project has prerequisites
  \(\operatorname{req}(q)\subseteq M\) and a raw kernel
  \(G(q,b,C)\in\Delta_{\mathbb Q}(\operatorname{Option}(S))\). If
  \(\operatorname{req}(q)\nsubseteq C\), then \(G(q,b,C)\) is the point mass
  at `none`. Apart from \(q,b,C\), the primitive raw generator cannot inspect
  library identities, provenance, multiplicity, age, or admission order.
- **Purpose:** states the observable inputs of the raw generator from which
  the compressed transition is derived. The historical ID is retained for
  ledger continuity; this assumption does not assert transition or value
  factorization.
- **Lean implementation:** R0 encodes the closure-indexed exact distribution.
  The prerequisite-to-Dirac-`none` certificate remains open.
- **Status:** adopted
- **Used by:** T1--T7

### A-VERIFY — Raw verification and derived admission

- **Exact wording:** a raw candidate \(s\) passes verification with rational
  probability \(\nu(q,b,C,s)\in[0,1]\), and this primitive rule cannot inspect
  raw-library information beyond \(q,b,C,s\). The admitted law is derived by
  \[
  \begin{aligned}
    \Gamma(q,b,C)(\operatorname{some}(s))
      &=G(q,b,C)(\operatorname{some}(s))\nu(q,b,C,s),\\
    \Gamma(q,b,C)(\operatorname{none})
      &=G(q,b,C)(\operatorname{none})
        +\sum_sG(q,b,C)(\operatorname{some}(s))(1-\nu(q,b,C,s)).
  \end{aligned}
  \]
  Failed generation and failed verification both produce `none`; only an
  admitted `some(s)` updates the library by set union.
- **Purpose:** distinguishes candidate generation from verified admission
  without adding an intermediate state.
- **Lean implementation:** R0 encodes the unit-interval probability bounds,
  derives the displayed law, and proves its nonnegativity and normalization.
- **Status:** adopted
- **Used by:** T1, T2, T4--T7

### A-COST — Nonnegative compressed-state project cost

- **Exact wording:** the total initiation cost is
  \(\kappa_q(b,K)\in\mathbb Q_{\ge0}\). It is paid once when project \(q\) is
  initiated and cannot inspect raw-library features not present in
  \(K=(F,C)\). Continue has no project cost.
- **Purpose:** aligns cost with the unified semi-Markov action signature while
  permitting economically relevant dependence on either frontier or closure.
- **Status:** adopted
- **Used by:** T1, T2, T4--T7

### A-COMPOSITION — Generative nondegeneracy

- **Exact wording:** the admitted theorem class contains realizable libraries
  \(L,L'\), \(b\), and \(q\) with \(F_L=F_{L'}\), \(C_L\ne C_{L'}\), and
  \(\Gamma(q,b,C_L)\ne\Gamma(q,b,C_{L'})\).
- **Purpose:** rules out a generator that is only nominally module-dependent.
- **Status:** adopted
- **Used by:** interpretation of all novelty results; witnessed constructively
  by T4

### A-TIMING — Unified semi-Markov raw completion law

- **Exact wording:** at a decision epoch the controller chooses Continue or
  one \(q\in Q(K_L)\). Continue earns \(F_L(b)\), advances belief once through
  \(P_B\), and leaves \(L\) fixed. Research pays \(\kappa_q(b,K_L)\) at
  initiation, has full calendar duration \(d_q\in\mathbb N_0\), leaves \(L\)
  fixed before completion, and earns
  \(o_qF_L(B_t)\) at dates \(t=0,\ldots,d_q-1\), where \(o_q=1\) unless the
  project is explicitly suspending. No new control is chosen before
  completion. A normalized joint coupling
  \(\Lambda_q(\mathbf b,o\mid b,K_L)\) has the Markov belief-path marginal
  induced by \(P_B\) and admitted-outcome marginal
  \(\Gamma(q,b,C_L)\); it cannot inspect raw-library information outside
  \(K_L\). At
  date \(d_q\), outcome \(o\) updates the library to \(L\oplus o\), and
  continuation begins from \((B_{d_q},L\oplus o)\). No product coupling is
  assumed. The primary recursion requires \(d_q\ge1\); a duration-zero action
  requires a separately declared well-founded rank that strictly decreases
  before another instantaneous choice.
- **Purpose:** fixes the complete reward clock, belief path, admission
  coupling, raw update, and continuation state without assuming conditional
  independence.
- **Status:** adopted
- **Used by:** T1, T4--T7

### A-DISCOUNT — Rational discount

- **Exact wording:** \(\beta\in\mathbb Q\) and \(0\le\beta<1\).
- **Purpose:** matches the finite theorem core to a later contraction
  extension.
- **Status:** adopted
- **Used by:** T1, T4--T7

### A-HORIZON — Finite-horizon objective first

- **Exact wording:** the primary value \(V_h\) is indexed by the number
  \(h\in\mathbb N\) of remaining calendar reward dates. The terminal payoff is
  zero, or more generally has the declared form
  \(g^{\mathrm{raw}}(b,L)=\bar g(b,K_L)\). Continue indexes \(V_{h-1}\);
  feasible positive-duration project \(q\) satisfies \(d_q\le h\) and indexes
  \(V_{h-d_q}\), with its full untruncated incumbent reward stream. Every
  action set, sum, and maximum is finite. The exact target recursions are those
  in `UNIFIED_TIMING_SPEC.md` and `RAW_TO_COMPRESSED_SPEC.md`.
- **Purpose:** keeps the first formal value theory elementary and exact.
- **Status:** adopted
- **Used by:** T1, T3--T7

## Theorem-specific assumptions

### A-DI-ABSTRACT — Primitive compressed transition semantics

- **Exact wording:** for the supporting abstract dynamic-innovation result,
  there is a primitive exact kernel
  \[
    T:B\times\mathcal I\times Q\to\Delta_{\mathbb Q}(\mathcal I),
  \]
  where \(\mathcal I=(B\to\mathbb Q)\times\mathcal P_{\mathrm{fin}}(M)\)
  is the ambient compressed-state type. Every distribution has finite support.
  At each positive horizon the current reward is the state's frontier value,
  the planner chooses idle or one project, idle retains the compressed state,
  and a project uses \(T\). The next belief independently follows a primitive
  exact kernel \(P_B\), and continuation is discounted by rational
  \(0\le\beta<1\). This abstract recursion has no current project-cost term.
- **Purpose:** isolates the exact behavioral equivalence and quotient argument
  before deriving compressed transitions from raw generation, verification,
  cost, admission, and local state updates.
- **Status:** adopted for supporting result F1 only
- **Used by:** F1; not a substitute for any T1 assumption

### A-UDI — Unified cost-sensitive dynamic innovation observations

- **Exact wording:** on the T1 raw model, two libraries are dynamically
  innovation equivalent when they have identical current frontiers and, for
  every belief and project, identical availability-tagged initiation costs,
  durations, joint terminal belief/next-realizable-compressed-state laws, and
  exact expected discounted incumbent-reward blocks. The tag is `none` when a
  project is unavailable and `some data` when it is available, so equality of
  project observations includes equality of the feasible menu.
- **Timing and dependence:** the terminal law is the pushforward of T1's full
  completion coupling and need not be a product. The operating reward is an
  exact expectation under the path marginal; additivity of the unified action
  value makes that marginal sufficient next to the complete terminal law. In
  the current Lean model duration and operation flags are project-specific.
- **Infinite boundary:** infinite-horizon preservation uses T1's explicit raw
  and compressed contraction certificates; A-UDI does not derive them.
- **Minimality boundary:** a representation-refinement proposition is allowed
  only when equal representation fibers preserve every displayed observation.
  Generic minimality and full abstraction remain excluded.
- **Status:** adopted and Lean verified
- **Used by:** UDI; supplies the final-model equivalence, while the
  A-DI-ABSTRACT and A-FH-VALUE relations remain supporting layers

### A-FH-VALUE — Exact finite-state action-value semantics

- **Exact wording:** supporting result F5 has nonempty finite belief,
  compressed-state, and research-project carriers. Exact rational kernels
  \(P_B(b)\) and \(T(b,K,q)\) govern the next belief and compressed state.
  The action set is `Option ResearchProject`: `none` continues, collects
  \(F_K(b)\), keeps \(K\), and advances the belief; `some q` researches, pays
  a nonnegative exact cost \(\kappa(b,K,q)\), and advances belief and
  compressed state. Conditional belief and state draws use nested
  expectations, hence their exact product law.
- **Discount and delay:** \(\beta\in\mathbb Q\) satisfies
  \(0\le\beta<1\). Each project has a delay \(d(q)\in\mathbb N\); its
  completion continuation is multiplied by \(\beta^{d(q)+1}\). The finite
  horizon counts decision epochs, so delay does not introduce a second
  calendar-time recursion index.
- **Equivalence signature:** cost-sensitive dynamic innovation equivalence
  compares the current frontier, every project cost, and every exact
  next-compressed-state distribution. Cost equality is required because
  research has an action-specific current payoff.
- **Boundary:** unlike A-TIMING, the F5 research action does not also collect
  the current frontier. The compressed-state kernel is primitive, not derived
  from generation, verification, admission, or a raw-library update.
- **Status:** adopted for supporting result F5 only
- **Used by:** F5; not a substitute for the accepted raw/compressed Bellman
  model or T1

### A-F6-DECOMP — Library adapter and monotone research opportunities

- **Base adapter:** supporting result F6 supplies a map from every admissible
  raw library into the finite compressed-state carrier of an A-FH-VALUE
  process. The process frontier at that image equals the library's exact
  operational frontier. Passive value freezes the raw library and repeatedly
  takes the continue action; full value is the F5 optimized finite-horizon
  value at the image.
- **Factorization used by zero total innovation:** if two raw libraries have
  equal operational frontiers and equal generative closures, then every
  project cost and exact next-state distribution at their images is equal.
  This hypothesis is used only for the frontier--closure sufficiency results.
- **Monotonicity used by premium comparison:** there is a relation on finite
  compressed states such that raw-library inclusion maps to that relation,
  frontiers are pointwise monotone, research costs are antitone, and each
  research transition has weakly larger expectation for every rational
  continuation monotone in the relation. The premium theorem additionally
  assumes that the inserted strategy leaves the operational frontier
  unchanged.
- **Sign boundary:** the exact total/operational/generative accounting identity
  is unconditional. No theorem assigns a sign to generative innovation
  without the preceding monotonicity assumptions. In particular, F6 does not
  assume the desired premium inequality as a premise.
- **Exact example:** the F4 singleton bridge carriers are reused with a new
  F5 process, future reward (2), zero project cost, delay zero, and discount
  (1/2). Inserting the zero-frontier bridge has operational innovation zero
  and generative innovation exactly one at horizon two.
- **Status:** adopted for supporting result F6 only
- **Used by:** F6; not a substitute for T5's unified raw insertion values

### A-F7-INNOVATION-EQUATION — Passive finite belief dynamics

- **Base process:** supporting result F7 reuses the F6 `LibraryDynamics`
  adapter. Passive value holds the raw library fixed, receives its current
  operational frontier, and evolves beliefs through the process's common exact
  rational kernel with rational discount (0\le\beta<1).
- **Gap sum:** the finite discounted gap functional is defined recursively by

  \[
    G_0(b)=0,\qquad
    G_{n+1}(b)=\Delta_{s,L}(b)
      +\beta\sum_{b'}P_B(b)(b')G_n(b'),
  \]
  where
  \(\Delta_{s,L}(b)=\max\{j_s(b)-F_L(b),0\}\).
- **Reachability:** an exact belief is reachable in (t) steps when there is a
  length-(t) chain whose every transition has nonzero rational mass. The zero
  criterion requires the gap to vanish at every such state for every
  (t<n).
- **Diminishing marginal value:** library inclusion is compared under the same
  belief kernel and discount. Nonnegative discount and frontier monotonicity
  suffice; no research-transition or closure assumption is used.
- **Exact example:** a two-belief deterministic kernel moves from a current
  belief, where the candidate ties the zero frontier, to a future belief where
  its exact gap is two. At horizon two and discount (1/2), passive operational
  innovation is strictly positive (in fact one).
- **Boundary:** F7 is the exact passive insertion equation on the F5/F6
  adapter. It is not T5's unified raw-process theorem and does not establish
  T6's retained-carrier descendant bound.
- **Status:** adopted for supporting result F7 only
- **Used by:** F7

### A-F8-CONTRACTION — Discounted primitive finite-state extension

- **Base process:** supporting result F8 reuses exactly the finite carriers,
  rational reward/cost tables, rational kernels, delay convention, finite
  actions, and cost-sensitive dynamic innovation signature of A-FH-VALUE.
- **Scalar and norm:** finite-horizon inputs remain exact rationals. For the
  infinite-horizon theorem they are cast to real numbers, and value functions
  are all maps from the finite product
  `Belief × CompressedState` to the reals. The function space carries
  mathlib's finite-product sup norm and is complete; boundedness is automatic.
- **Bellman operator:** continue has continuation coefficient \(\beta\).
  Research project \(q\) has coefficient \(\beta^{d(q)+1}\); because
  \(0\le\beta<1\), this is at most \(\beta\). The Bellman operator takes the genuine
  maximum over `Option ResearchProject`.
- **Fixed point and limits:** mathlib's Banach contraction theorem defines a
  unique real-valued fixed point. Value iteration converges uniformly from
  every real initial table with the standard a priori geometric error bound.
  The existing exact rational finite-horizon recursion, cast pointwise to
  reals, is proved equal to iteration from zero and therefore converges
  uniformly and pointwise to that fixed point.
- **Equivalence:** F8 reuses F5's cost-sensitive dynamic innovation
  equivalence: equal frontier, every project cost, and every research
  transition law. Equivalent compressed states have equal fixed-point value
  at every belief.
- **Boundary:** the research kernel remains primitive and action timing remains
  A-FH-VALUE rather than A-TIMING. No raw-library simulation, derived
  frontier--closure transition, infinite series identity, or stationary policy
  object is proved.
- **Status:** adopted for supporting result F8 only
- **Used by:** F8; not a substitute for T1 or the full Candidate S2 policy
  theorem

### A-S4-COVERAGE-POTENTIAL — Finite one-shot occupation representation

- **Belief grid:** the supporting S4 model uses a nonempty finite linearly
  ordered belief type. The order is used only to define exact finite regional
  minima and global maxima; no interval, connectedness, or threshold geometry
  is assumed.
- **Gap:** a fixed candidate value table and an existing-frontier table define
  the certified gap
  \(\Delta(q,K,b)=\max\{j_q(b)-F_K(b),0\}\). It is exact rational and
  pointwise nonnegative. Candidate value is fixed when frontier states are
  compared.
- **Occupation:** `weight t b b'` is an exact nonnegative rational
  date-\(t\) occupation weight of future belief \(b'\) from initial belief
  \(b\). Reusable monotonicity permits unnormalized subprobability or exposure
  weights. The declared one-shot probability model separately requires each
  date-specific belief row to sum to one.
- **Discount and survival:** the declared model has a finite horizon,
  \(0\le\beta\le1\), and project-specific candidate survival
  \(0\le\rho_q\le1\). Date \(t\) is weighted by
  \(\beta^t\rho_q^t\). The reusable finite-sum monotonicity lemmas require
  only the stated nonnegativity and pointwise order conditions.
- **Gross-value boundary:** coverage potential is gross operational value.
  It includes neither project cost nor raw generation, verification,
  admission/success probability, optimization, or a forced-action comparison.
  It therefore does not establish the separately verified T6.
- **Status:** adopted for supporting result S4 only
- **Used by:** S4

### A-S5-MONOTONE-COVERAGE — Finite monotone-gap one-shot cost covering

- **Belief grid:** a nonempty finite linearly ordered belief type.
- **Transition:** an exact rational row-stochastic kernel \(P\). First-order
  stochastic monotonicity is stated by its finite expectation
  characterization: for every increasing \(f:B\to\mathbb Q\), the map
  \(b\mapsto\sum_{b'}P(b,b')f(b')\) is increasing.
- **Gap:** the single supplied gap \(\Delta:B\to\mathbb Q\) is pointwise
  nonnegative and increasing. This is a directional restriction, stronger than
  unrestricted single-peakedness.
- **Discount and survival:** \(\beta\ge0\), and the belief-dependent survival or
  success factor \(p:B\to\mathbb Q\) is pointwise nonnegative and increasing.
  Probability applications may additionally impose upper bounds of one; those
  bounds are not needed for the finite order theorem.
- **Cost:** \(\kappa:B\to\mathbb Q\) is antitone. The one-shot cost-covering
  set is exactly

  \[
    \{b:\kappa(b)\le
      \beta p(b)\sum_{b'}P(b,b')\Delta(b')\}.
  \]
- **Boundary:** single-peakedness alone is insufficient under an arbitrary
  row-stochastic kernel, and increasing gross potential alone is insufficient
  under arbitrary costs. No continuous-belief, log-concavity, TP2, or general
  unimodality-preservation claim is assumed. The set is not the optimal
  Bellman research region: no continuation-value or competing-action
  monotonicity is assumed.
- **Comparative-static scope:** pointwise higher cost shrinks the set;
  pointwise higher nonnegative survival or admission probability expands it;
  and a pointwise higher existing frontier shrinks a fixed candidate's
  positive-part gap and covering set. Cutoff directions are asserted when both
  compared nonempty sets are represented as upper thresholds.
- **Status:** adopted for supporting result S5 only
- **Used by:** S5; not a substitute for current T6's retained-carrier bound

### A-S6-DISCOUNT-SURVIVAL — Finite patience--survival interaction

- **State space and transition:** a finite type with decidable equality and an
  exact rational matrix \(P\) in mathlib's row-stochastic submonoid. Thus all
  entries are nonnegative and every row sums exactly to one. Closure of the
  submonoid under powers derives nonnegativity of every \(P^t\).
- **Gap:** \(g:B\to\mathbb Q\) is pointwise nonnegative. This is
  proof-critical: a one-state exact negative-gap example reverses the cross
  difference.
- **Finite horizon:** for \(H\in\mathbb N\),
  \[
    U_{\alpha,H}=\sum_{t<H}\alpha^tP^t,\qquad
    \Psi_H(\beta,\rho)=U_{\beta\rho,H}g.
  \]
  No inverse, infinite series, limit, or differentiability assumption is used.
- **Parameter order:** monotonicity uses a nonnegative lower parameter and
  pointwise scalar order. Complementarity uses
  \(0\le\beta_0\le\beta_1\) and
  \(0\le\rho_0\le\rho_1\). Probability applications may additionally bound
  the parameters by one, but those upper bounds are unnecessary for the
  finite theorem.
- **Analytical boundary:** \(U_\alpha=(I-\alpha P)^{-1}\) for
  \(\alpha<1\) remains a Julia-validated exact finite-dimensional
  interpretation. No infinite-resolvent identity or resolvent derivative is
  attributed to Lean S6.
- **Status:** adopted and Lean verified
- **Used by:** S6 finite patience--survival complementarity

### A-S7-KERNEL-ALIGNMENT — Finite gap-aligned kernel comparison

- **State space and transition:** a finite type with decidable equality and
  exact rational transition matrices. In the probabilistic interpretation,
  the matrices are row stochastic. The exact persistence counterexamples use
  `Fin 2` and
  \[
    P(\theta)=
    \begin{pmatrix}\theta&1-\theta\\1-\theta&\theta\end{pmatrix},
    \qquad 0\le\theta\le1.
  \]
- **Coverage:** for finite horizon \(H\), effective discount
  \(\alpha\in\mathbb Q\), and pointwise nonnegative gap
  \(g:B\to\mathbb Q_{\ge0}\),
  \[
    \Psi^P_{H,\alpha}(b)
      =\sum_{t=0}^{H-1}\alpha^t(P^tg)(b).
  \]
  The exact sign witnesses use \(H=2\), \(\alpha=1/2\), and compare
  \(\theta_0=1/4\) with \(\theta_1=3/4\).
- **Alignment:** \(P_1\) occupation-dominates \(P_0\) on the advantage region
  when, for every initial state and every state with \(g>0\), its discounted
  finite occupation is weakly larger. This condition and \(g\ge0\) imply
  pointwise coverage dominance. Stochasticity and \(0\le\alpha\le1\) give the
  intended Markov interpretation but are not proof-critical once the
  occupation inequalities themselves are assumed.
- **Gap-tailored order:** \(P_1\succeq_gP_0\) is defined exactly by pointwise
  comparison of the displayed finite coverage potentials. It is a
  gap-relative order, not a scalar persistence order.
- **Boundary:** no universal increasing or decreasing sign is asserted for a
  larger persistence parameter. The sign depends on whether the induced
  discounted occupation moves toward or away from positive-gap beliefs.
- **Status:** adopted and Lean verified
- **Used by:** S7 belief-kernel comparative statics

### A-C2-MULTIGAP-WITNESS — Exact five-belief limitation construction

- **Belief grid:** `Fin 5` with its standard finite linear order.
- **Project and gaps:** one project supplies exactly two candidate outcomes.
  Relative to the zero existing frontier, their certified rational gaps are
  `(4,0,0,0,0)` and `(0,0,0,0,4)`. Aggregate project gap is their exact sum.
- **Transition:** the degree-four Bernstein/binomial kernel: at state `i`, the
  future state is the success count in four Bernoulli trials with success
  probability `i/4`. Lean proves every rational entry nonnegative and every
  finite row normalized.
- **Value and cost:** discount and candidate survival are one. Gross one-shot
  coverage value is the exact expectation of aggregate gap. Research cost is
  constant one, and the cost-covering set uses strict inequality.
- **Boundary:** this is one exact counterexample, not a parametric multi-gap
  theorem and not current T6's retained-carrier comparison. Costs are
  unrestricted only in the separate topology-bound counterexample.
- **Status:** adopted for supporting limitation result C2 only
- **Used by:** C2

### A-FC-FACTOR — Modular frontier--closure generator

- **Exact wording:** for supporting result F2, there is a modular generator
  \[
    g:B\times(B\to\mathbb Q)\times
      \mathcal P_{\mathrm{fin}}(M)\times Q
      \to\Delta_{\mathbb Q}(\mathcal I)
  \]
  such that, for every belief \(b\), ambient compressed state \(K=(F,C)\),
  and project \(q\),
  \[
    T(b,K,q)=g(b,F,C,q).
  \]
  Consequently the transition induced at a raw library \(L\) is exactly
  \(g(b,F_L,C_L,q)\).
- **Purpose:** makes dependence on a raw library through its operational
  frontier and generative closure explicit rather than implicit in a
  compressed-state argument.
- **Status:** adopted for supporting results F2--F3 only
- **Used by:** both directions of F2, its value-sufficiency corollary, and the
  F3 deletion sufficient condition and converse

### A-FC-IDENT — Closure detectability at a fixed frontier

- **Exact wording:** for every frontier \(F:B\to\mathbb Q\) and distinct
  finite module sets \(C\ne C'\) for which there are admissible libraries
  \(L,L'\) satisfying
  \((F_L,C_L)=(F,C)\) and \((F_{L'},C_{L'})=(F,C')\), there exist \(b\in B\)
  and \(q\in Q\) such that
  \[
    g(b,F,C,q)\ne g(b,F,C',q).
  \]
- **Purpose:** makes every realizable closure difference at a common frontier
  observable through a concrete belief--project transition experiment, without
  imposing restrictions on unreachable frontier--closure pairs. Frontier
  detectability is not an additional assumption because F2's current reward
  observation is exactly \(F(b)\) at every belief.
- **Status:** adopted for the converse and iff of supporting results F2--F3
- **Used by:** converse and iff directions of F2 and F3

### A-SD-OBS — Deletion observation preservation

- **Exact wording:** the identifiable converse in supporting result F3 assumes
  that deleting a noninactive strategy preserves (i) the current frontier
  reward at every belief and (ii) the complete exact next-compressed-state
  distribution for every belief and every allowed research project.
- **Purpose:** states the observations that define dynamic innovation
  equivalence. It does not replace them by equality of the optimized
  finite-horizon value function.
- **Boundary:** finite-horizon value equality alone need not recover the
  closure, even under A-FC-FACTOR and A-FC-IDENT. The Lean counterexample uses
  an allowed discount of zero, so future research transitions are
  value-irrelevant although their laws identify the closure.
- **Status:** adopted for the converse of supporting result F3 only
- **Used by:** F3 observation-level converse; not a substitute for the
  raw-model T3 hypotheses

### A-T2-OBS — Observable closure signature

- **Exact wording:** let \(K=(F,C)\) and \(K'=(F,C')\) be realizable
  compressed states with \(C\ne C'\). There is a project experiment that
  changes at least one availability-tagged unified observation: initiation
  cost, duration, or the joint terminal-belief/next-compressed-state law.
  A witnessed inequality of \(G(q,b,C)\) and \(G(q,b,C')\), or of primitive
  admission probabilities \(\nu(q,b,C,s)\) and \(\nu(q,b,C',s)\), counts as
  detection only when it also induces an inequality of the tagged joint
  projected law after derived admission and raw update.
- **Raw factorization used by the forward direction:** Projection.Model
  enforces at the type level that generation and primitive admission take
  only \(q,b,C\) (and \(s\) for admission); feasibility, cost, and completion
  coupling inspect only realizable \(K=(F,C)\); and research-period operating
  rewards inspect \(F\). No raw identifier, multiplicity, lineage, or
  admission history is available after \(F,C\) are fixed.
- **Latent-law boundary:** candidate or admission laws can differ while
  deriving the same admitted/update pushforward. Such a latent difference
  alone cannot contradict UDI, whose observation is the projected joint law.
- **Purpose:** makes the converse direction of the frontier--closure
  characterization true for the final cost-sensitive UDI relation under the
  unified timing convention, without the old abstract \(T\) table.
- **Lean implementation:** RawClosureDetectionWitness and
  RawClosureDetectable in
  StrategyInnovation/Quotient/RawFrontierClosure.lean.
- **Status:** adopted and Lean verified for T2 and the observable converse of T3
- **Used by:** T2 and T3's process-observation converse; not used by abstract
  supporting results F2/F3 or by T3's forward/state/value implications

### A-T3-DELETE — Admissible single deletion

- **Exact wording:** T3 considers \(s\in L\setminus\{s_0\}\) and
  \(L^{-s}=L\setminus\{s\}\). No other strategy is deleted simultaneously.
- **Purpose:** keeps the baseline and avoids unsafe inference from individual
  to batch redundancy. A stepwise pruning trace may contain multiple
  deletions only when both redundancy equalities are rechecked at the current
  intermediate library before each erasure.
- **Status:** adopted and Lean verified
- **Used by:** T3

### A-F4-SCALED — Fixed two-period scaled pruning construction

- **Exact wording:** supporting result F4 uses one belief, one project, one
  module, and three strategies. The inactive strategy and the dominated bridge
  have zero operational profile; only the bridge carries the module. A future
  strategy has exact rational reward \(R\ge0\). Research deterministically
  reaches the future-strategy compressed state iff the module remains in the
  current closure. Belief is constant, project cost is absent, the horizon is
  two, and the rational discount is \(1/2\).
- **Unbounded quantifier:** for target \(M\in\mathbb N\), F4 sets \(R=2M\).
  Thus its unboundedness is reward-scaled, not normalized.
- **Bounded variant:** if every catalog profile is in \([0,C]\) for rational
  \(C\ge0\), then the exact maximum pruning loss within this construction is
  \(C/2\).
- **Status:** adopted for supporting result F4 only
- **Used by:** F4; not a substitute for A-T4-SCALE

### A-T4-SCALE — Normalized across-instance loss

- **Exact wording:** T4 quantifies over a family of finite models with
  \(0\le j_s(b)\le1\), zero project cost, variable finite horizon \(H\), and
  variable rational \(0\le\beta<1\). “Arbitrarily large” means: for every
  rational \(R\ge0\), some family member has additive value loss greater than
  \(R\).
- **Purpose:** prevents arbitrary payoff rescaling while respecting the finite
  fixed-\((\beta,H)\) upper bound.
- **Status:** superseded by A-T4-CANONICAL
- **Used by:** historical pre-formalization target only

### A-T4-FIXTURE — Bridge-module construction

- **Exact wording:** T4 uses singleton belief, module, and project types and
  three strategy identifiers \(s_0,s_{\mathrm{bridge}},s_\star\).
  Both \(s_0\) and \(s_{\mathrm{bridge}}\) pay zero,
  \(s_{\mathrm{bridge}}\) uniquely supplies \(m_\star\), \(s_\star\) pays the
  exact cap \(C\), and closure is identity. The raw generator assigns
  descendant mass \(\rho^d\) exactly when \(m_\star\) is available, and the
  primitive admission row accepts it with probability \(\pi\).
- **Purpose:** provides a smallest hand-checkable T4 family template.
- **Status:** adopted
- **Used by:** T4

### A-T4-CANONICAL — Sharp normalized delayed-descendant loss

- **Exact wording:** The T4 parameters are exact rationals with
  \(d\in\mathbb N_{>0}\), \(0\le\beta<1\), \(0\le\rho\le1\),
  \(0\le\pi\le1\), \(C\ge0\), and initiation-cost difference
  \(\kappa\ge0\). The cap instance additionally assumes
  \(\kappa\le\beta^d\rho^d\pi C\), so the one-project research action weakly
  dominates zero-valued Continue. The raw survival gate and admission law are
  independent stages in the admitted-candidate calculation, giving mass
  \(\rho^d\pi\).
- **Cost timing:** \(\kappa\) is paid at project initiation. The pruned
  comparator pays no research cost because its descendant opportunity is
  absent; hence the declared cost difference is \(\kappa-0\).
- **Operating timing:** The base theorem suspends zero-valued incumbent
  operation. If operation continues, add the difference of the two exact
  discounted incumbent-reward blocks. Operational redundancy and a common
  belief-path law make this difference zero.
- **Normalization boundary:** For \(R\in[0,C]\), loss is capped sharply by the
  cap-\(C\) formula. If \(C\le1\), loss is at most one. Arbitrarily large
  additive loss is asserted only after scaling \(C\).
- **Status:** adopted and Lean verified
- **Used by:** T4

### A-T5-BASELINE — Frozen-library operational counterfactual

- **Exact wording:** on the T1 raw process, \(P_h(b,L)\) freezes the verified
  raw library and takes Continue at every remaining calendar date. Full value
  is \(U_h(b,L)=\texttt{rawValue}(h,b,L)\), and the research-option premium is
  \(\Omega_h(b,L)=U_h(b,L)-P_h(b,L)\). For an insertion,
  \[
    \mathcal I_h=U_h(L\cup\{s\})-U_h(L),\quad
    \Delta_h^{\mathrm{op}}=P_h(L\cup\{s\})-P_h(L),\quad
    \Delta_h^{\mathrm{gen}}=\Omega_h(L\cup\{s\})-\Omega_h(L).
  \]
  T1 identifies both raw full values with their values at the realizable
  compressed states. Research retains T1's positive calendar duration,
  initiation cost, correlated completion law, and exact incumbent operating
  block.
- **Purpose:** fixes a non-double-counted operational counterfactual and makes
  the T5 insertion components statements about the accepted raw process.
- **Status:** adopted and Lean verified
- **Used by:** T5--T7

### A-T5-PROJECT-DOMINANCE — Closure-enrichment comparison

- **Exact wording:** a comparison from \(L^-\) to \(L^+\) certifies equal
  operational frontiers, \(C_{L^-}\subseteq C_{L^+}\), inclusion of the old
  feasible project menu in the new menu, and, for every old feasible project,
  belief, and remaining finite horizon, weak increase of its exact T1
  compressed project-action value. That action value includes initiation
  cost, positive duration, the full correlated completion law, operation
  during research, and compressed continuation value.
- **Purpose:** states the substantive behavioral premise under which closure
  enrichment cannot lower the research-option premium; closure inclusion
  alone is deliberately insufficient.
- **Status:** adopted and Lean verified
- **Used by:** T5

### A-T6-CARRIER-BOUND — Retained-carrier descendant bound

- **Exact wording:** T6 compares \(L\) with
  \(L^+=L\cup\{s\}\). The insertion is frontier-silent,
  \(F_{L^+}=F_L\), the positive-duration project \(q\) fits the finite
  calendar horizon, is feasible at \(K_{L^+}\), and is infeasible at \(K_L\).
  The deleted comparator has zero research-option premium at the displayed
  horizon and belief. The retained-state T1 joint completion law directly
  defines
  \[
    \eta_{q,g}(b'\mid b,K_{L^+})
    =\Pr(B_{d_q}=b',O=\operatorname{some}(g)\mid b,K_{L^+},q).
  \]
  No independence is assumed in the primary theorem. The successful
  completion-date full-value improvement over the frozen retained library is
  at least \(G(B_{d_q})\ge0\) on every length-\(d_q\) path ending in `some g`;
  thus terminal \(G\) is a supportwise floor on the complete continuation,
  including any future-menu changes. For every other outcome, nonnegativity
  is derived from insertion-only raw update, passive-value monotonicity, and
  full value dominating passive value; it is not an extra certificate
  assumption. Models allowing harmful omitted outcomes require their explicit
  joint-law correction. The exact initiation cost is \(\kappa\). Unified research timing
  contributes the separately displayed operating/passive-baseline adjustment
  \[
    A^{\mathrm{op}}
    =\mathbb E[G^{\mathrm{op}}+\beta^{d_q}P_{h-d_q}(B_{d_q},L^+)]
      -P_h(b,L^+).
  \]
  The simpler target formula additionally assumes \(A^{\mathrm{op}}=0\).
  Suspended operation is not silently treated as baseline matched. The old
  \(\pi\rho^{d_q}\mu_{q,d_q}\) formula is a corollary when the distinguished
  joint event factors; process-wide `ConditionalIndependence`, generation mass
  \(\rho^{d_q}\), and admission probability \(\pi\) are sufficient for that
  specialization only.
- **Purpose:** turns one retained module carrier and one admitted descendant
  event into a valid lower bound on the carrier's marginal value without
  assuming the desired inequality.
- **Status:** adopted and Lean verified
- **Used by:** T6

### A-CS-SIGN — Sign-definite finite comparative statics

- **Dynamic state order:** `GenerativeDominanceOrder` is a declared relation
  on realizable compressed states. Related states have pointwise ordered
  frontiers, nested feasible menus, antitone research costs, and ordered exact
  completion expectations for every continuation monotone in the relation.
  The completion comparison includes the full incumbent operating-reward
  block, positive project duration, terminal belief, admitted outcome, local
  compressed update, and discounted continuation.
- **Fixed-closure frontier specialization:** two states have the same closure
  and pointwise ordered frontiers. Availability, cost, and the complete joint
  completion law are equal for every such pair. The common candidate catalog
  and `addK` operation then preserve the order after every admitted outcome.
- **Cost comparison:** a `ResearchCostSchedule` is pointwise nonnegative.
  Lower and higher schedules are compared pointwise while availability,
  duration, belief dynamics, operation, completion coupling, discount, and
  every continuation primitive remain fixed.
- **Binary candidate comparison:** project duration is positive,
  \(0\le\pi,\rho\le1\), and the otherwise common success continuation weakly
  dominates the common failure continuation. Admission changes only \(\pi\);
  survival changes only \(\rho\).
- **Elapsed-time delay comparison:** \(0<d_0\le d_1\),
  \(0\le\beta\le1\), operating rewards on the additional dates are
  nonnegative, and terminal descendant continuation \(W\) is nonnegative.
  Continued operation also requires the no-waiting-gain inequality
  \(F_t\le(1-\beta)W\) for every added elapsed date. Suspended operation
  satisfies this inequality automatically. Nonnegativity alone is
  insufficient.
- **Closure comparison:** the supporting closure theorem reuses T5's
  `ClosureEnrichmentProjectDominance`; closure inclusion without behavioral
  project dominance receives no value sign.
- **Finite action regions:** Continue value and every primitive other than the
  displayed cost or survival schedule are fixed. Research belongs to the
  exact weak-action region precisely when its rational return weakly exceeds
  Continue.
- **Status:** adopted and Lean verified
- **Used by:** supporting comparative-statics family CS1; not a proof of T7

### A-T7-GEN-INDEPENDENCE — Primitive frontier-independent research

- **Exact wording:** for every project, belief, closure, and ambient frontier,
  project availability, initiation cost, duration, operation flag, and the
  terminal joint belief/admission law \(\Xi_q\) depend on \((q,b,C)\) but not
  on \(F\). The common Markov belief-path marginal, strategy catalog, and
  `addK` update remain fixed and
  extension-only. This restriction holds at every descendant closure reached
  in the finite induction, not merely at the initial state.
- **Purpose:** is a primitive, noncircular independence condition from which
  fixed-action frontier saturation can be derived. It is necessary context
  for T7 but does not by itself order the optimized closure cross difference
  because the maximizing project may switch.
- **Status:** adopted
- **Used by:** T7

### A-T7-RELATIVE-SATURATION — Bellman-action single crossing

- **Exact wording:** for every finite remaining horizon, belief, and
  frontier--closure rectangle
  \((F_0,C_0),(F_0,C_1),(F_1,C_0),(F_1,C_1)\), every action \(a_1\) feasible
  in the closure-rich high-frontier state and every action \(a_0\) feasible
  in the closure-poor low-frontier state satisfy
  \[
    Q_h(F_1,C_1,a_1)-Q_h(F_1,C_0,a_0)
      \le
    Q_h(F_0,C_1,a_1)-Q_h(F_0,C_0,a_0).
  \]
  Frontier independence transports the two actions to the opposite-frontier
  states. Each \(Q_h\) is the exact unified Bellman action value, including
  cost, duration, operation during research, the joint completion law,
  `addK`, and the already-defined lower-horizon optimized continuation.
- **Purpose:** rules out relative project switching of
  CX-T7-INDEPENDENT-MENU-SWITCH-02. It is an action-level single-crossing
  condition, not the desired cross difference of optimized values.
- **Boundary:** pointwise antitonicity of every individual candidate premium
  is insufficient. With fixed candidate payoff ten, discount one half,
  frontiers zero and eight, an old success-one/cost-two project and an added
  success-one-half/zero-cost project both saturate, yet \(J=1/2\).
- **Status:** adopted for corrected T7
- **Used by:** T7

### A-T7-COMMON-GAP — Primitive fixed-continuation saturation subclass

- **Exact wording:** at every finite Bellman node and belief, the rich- and
  poor-closure action values have the common-gap form
  \[
    Q_h(F_i,C_j,a)
      =B_{h,i}+\eta^j_{h,a}+\lambda^j_{h,a}g_{h,i}.
  \]
  The frontier-specific base is common across closures; action intercepts and
  exposures are unchanged across the two frontiers; the common gap satisfies
  \(g_{h,1}\le g_{h,0}\); every rich-menu exposure is nonnegative; and every
  feasible poor-menu action has zero exposure. The four states retain
  A-T7-GEN-INDEPENDENCE and poor-to-rich menu inclusion.
- **Primitive interpretation:** one fixed descendant profile supplies the
  positive-part gap. Frontier-independent cost, duration, operation,
  generation/admission, and fixed-continuation terms enter the intercept and
  exposure. A Continue-only poor menu is the leading special case. At longer
  horizons the shared form is an explicit fixed-continuation preservation
  restriction, not a conclusion for arbitrary optimized successor closures.
- **Transition-level sufficient condition:** in the canonical recursive
  specialization, both frontier gaps use the process's same belief kernel and
  nonnegative discount. Pointwise ordered current gap flows and terminal gaps
  generate the finite-horizon gaps. Positivity of rational expectation
  preserves their order by induction. This derives the required
  \(g_{h,1}\le g_{h,0}\) at every horizon instead of assuming that part of the
  certificate node by node.
- **Purpose:** derives A-T7-RELATIVE-SATURATION from primitive exposure and gap
  orders, so the general T7 theorem yields substitution without assuming the
  action-level sign directly.
- **Sharp boundary:** merely ordering the added project's exposure above an
  incumbent project's is insufficient. Rich-menu Continue has zero exposure
  and gains relative to any positive-exposure poor action as the common gap
  shrinks. CX-T7-RS-CONTINUE-03 and 648 exact search rows record this failure.
- **Status:** adopted and Lean verified as a sufficient-condition subclass
- **Used by:** T7 primitive common-gap corollary and its recursion-stable
  canonical specialization

### A-T6-SINGLE — Legacy one-gap feasibility comparator

- **Exact wording:** the version-1 feasibility experiment compared one forced
  current project with forced Continue, supported admission on `none` and one
  candidate, and prohibited later research.
- **Purpose:** preserves the meaning of the old single-gap result and its
  fixtures after publication-facing T6 was reassigned to the generative-option
  lower bound.
- **Status:** revised; supporting legacy only
- **Used by:** legacy `paper1-theorem-falsification-v1`, not current T6

## Exact theorem-to-assumption map

The raw-to-compressed preparation results are finer-grained than T1 and use
only the assumptions needed for each step:

| Prepared result | Required assumptions |
|---|---|
| RC1 raw update identity | A-STRATEGY, A-PROFILE, A-LIBRARY, A-CLOSURE, A-FRONTIER |
| RC2 marginal compressed transition | RC1 plus A-FIN, A-RATPROB, A-GEN-FACTOR, A-VERIFY |
| RC2 joint compressed transition | RC2 marginal plus the coupling and raw-input restrictions in A-TIMING |
| RC3 embedded controlled Markov projection | RC2 joint plus A-BELIEF-GRID, A-COST, and the availability/duration/operation/no-intermediate-control clauses of A-TIMING |
| RC4 finite calendar-horizon value factorization | RC1--RC3 plus A-DISCOUNT and A-HORIZON; positive durations for ordinary strong induction |
| RC4 infinite-horizon value corollary | RC4 structural inputs plus bounded finite data, \(0\le\beta<1\), and positive recurrent research durations |
| additive resource burden | A-FIN, A-LIBRARY, A-RESOURCE-WEIGHT |
| exact safe-compression problem | additive resource burden plus A-RESOURCE-OUTER, A-OPTIMIZATION-DOMAIN, A-FRONTIER, and A-CLOSURE |
| identity-closure safe-compression complexity | exact safe-compression inputs plus A-SAFE-COMPLEXITY-ENCODING and identity closure |
| general-closure safe-compression NP membership | exact safe-compression inputs plus A-SAFE-COMPLEXITY-ENCODING and a polynomial-time closure-equality evaluator |
| dynamic-equivalence safe-compression form | exact safe-compression domain plus T1/UDI sufficiency; A-T2-OBS for equality with the frontier--closure feasible set |
| safe deletion as a feasible resource reduction | exact safe-compression inputs plus A-T3-DELETE and A-LOCAL-GLOBAL-COMPRESSION |
| complete-trace irreducibility | stepwise safe deletion plus endpoint completeness and frontier/closure monotonicity |
| global minimum implies irreducibility | exact safe-compression inputs plus strict positivity of every active resource weight |
| capacity or penalized retention problem | additive resource burden plus A-RESOURCE-OUTER, A-OPTIMIZATION-DOMAIN, and the declared productive finite-horizon value assumptions |
| finite capacity-value step theorem | capacity inputs plus A-CAPACITY-VALUE; one-sided breakpoint language concerns the canonical real extension of the exact rational burden--value pairs |
| penalized finite affine envelope | capacity/penalty inputs plus A-PENALIZED-ENVELOPE; real-price continuity and derivatives concern the canonical extension of the exact rational branches |
| discrete capacity and resource-demand elasticity | CAP and PEN inputs plus A-DISCRETE-RESOURCE-ELASTICITY; every elasticity is an exact finite arc on a declared increment, not a derivative theorem |
| conditional replacement opportunity-cost identity | capacity problem inputs plus the candidate/deletion restrictions in A-OPTIMIZATION-DOMAIN and A-REPLACEMENT-OPTIMIZATION |
| canonical bridge-margin elasticity | exact T4 scalar identity plus A-BRIDGE-MARGIN-ELASTICITY; derivative and limit language concerns the named real-coordinate extension |
| operational--generative channel elasticity | exact T5 level identity plus A-CHANNEL-ELASTICITY; total-normalized contributions require positive total value and the convex weighted average additionally requires positive component levels |
| innovation duration and log-effective-discount convexity | scalar S6 finite-sum identity plus A-INNOVATION-DURATION; derivative language concerns the fixed-exposure real extension |

None of RC1--RC4 uses belief/outcome independence, closure identifiability, or
a generic quotient-minimality assumption. A-RESOURCE-WEIGHT and
A-RESOURCE-OUTER are conservative outer assumptions and are not dependencies
of RC1--RC4 or any existing T1--T7 declaration.

| Result | Required assumptions |
|---|---|
| F1 abstract DI quotient | A-FIN, F0 interfaces, A-RATPROB's finite-support component, A-DI-ABSTRACT |
| UDI unified cost-sensitive DI quotient | T1 structural assumptions plus A-UDI; explicit contraction certificates for infinite value preservation |
| F2 abstract frontier--closure characterization | F1 interfaces plus A-FC-FACTOR; A-FC-IDENT for the converse and iff |
| F3 abstract safe deletion | F0/F1 interfaces plus A-FC-FACTOR for sufficiency; A-FC-IDENT and A-SD-OBS for the converse |
| F4 sharp scaled frontier-pruning loss | F0/F1/F3 interfaces plus the explicit finite construction A-F4-SCALED |
| F5 exact finite-state Bellman calculus | A-FIN, A-RATPROB's finite-support component, A-DISCOUNT, A-HORIZON, A-FH-VALUE |
| F6 total strategy-innovation decomposition | F0 and F5 interfaces plus A-F6-DECOMP; factorization only for zero-total sufficiency; stochastic monotonicity only for premium monotonicity |
| F7 finite-horizon Strategy Innovation Equation | F0, F5, and F6 interfaces plus A-F7-INNOVATION-EQUATION |
| F8 discounted finite-state Bellman contraction | F5 interfaces plus A-F8-CONTRACTION |
| S4 coverage-potential representation | A-S4-COVERAGE-POTENTIAL |
| S5 monotone-gap one-shot upper threshold | A-S5-MONOTONE-COVERAGE |
| S6 finite patience--survival complementarity | A-S6-DISCOUNT-SURVIVAL |
| S7 finite gap-aligned kernel comparison | A-S7-KERNEL-ALIGNMENT |
| C2 one-project multi-gap disconnected cost-covering set | A-C2-MULTIGAP-WITNESS |
| T1 quotient sufficiency | A-FIN, A-RATPROB, A-BELIEF-GRID, A-STRATEGY, A-PROFILE, A-LIBRARY, A-CLOSURE, A-FRONTIER, A-GEN-FACTOR, A-VERIFY, A-COST, A-TIMING, A-DISCOUNT, A-HORIZON |
| T2 raw UDI frontier--closure characterization | T1/UDI structural assumptions plus A-T2-OBS; no old abstract T factorization |
| T3 deletion criterion | A-STRATEGY, A-PROFILE, A-LIBRARY, A-CLOSURE, A-FRONTIER, A-T3-DELETE; T1 assumptions for process/value/action preservation; A-T2-OBS only for the converse |
| T4 sharp normalized bridge loss | Raw generation/admission and unified timing conventions from T1 plus A-T4-FIXTURE and A-T4-CANONICAL |
| T5 value decomposition | T1 assumptions plus A-T5-BASELINE; A-T5-PROJECT-DOMINANCE only for premium monotonicity |
| T6 generative-option lower bound | T1 assumptions plus A-T5-BASELINE and A-T6-CARRIER-BOUND |
| CS1 sign-definite finite comparative statics | T1/T5 finite unified timing plus A-CS-SIGN |
| T7 frontier--closure substitutability | T1 assumptions plus A-T7-GEN-INDEPENDENCE and A-T7-RELATIVE-SATURATION; A-T7-COMMON-GAP is an optional primitive sufficient condition that implies the latter |

## Extension-only assumptions

| ID | Extension | Status |
|---|---|---|
| E-BELIEF-SIMPLEX | Beliefs range over all exact or real probability vectors on \(X\) | extension-only |
| E-BAYES | \(P_B\) is derived from hidden transition and observation kernels by Bayes' rule | extension-only |
| E-INFINITE | Infinite-horizon discounted value and stationary optimal policies | primitive F8 value part verified; raw bridge and policy remain extension-only |
| E-JOINT-INDEPENDENCE | Conditional terminal product law \(\Xi_q(b',o\mid b,K)=P_B^{d_q}(b,b')\Gamma(q,b,C)(o)\) for \(K=(F,C)\); full path/outcome product coupling is a stronger specialization | extension-only specialization; not required by RC1--RC4 or T1 |
| E-CONT-COVER | Piecewise-polyhedral continuous-belief coverage under affine data | extension-only |
| E-BATCH-DELETE | Simultaneous deletion of multiple strategies | extension-only |
| E-PROVENANCE | Generation may depend on strategy age, lineage, multiplicity, or admission order | rejected for Paper 1 core because it invalidates \(K=(F,C)\) |
| E-NONADDITIVE-RESOURCE | An exact set-level burden \(M(L)\) and total \(\widetilde W(L)=W(L)+M(L)\), with every required monotonicity or interaction property stated explicitly | extension-only; Paper 1 primary results set \(M\equiv0\) |
| E-DYNAMIC-RESOURCE | Resource weights depend on belief, age, usage, or time, or a hard capacity is enforced after every candidate admission | extension-only; requires an enlarged state and a new raw transition/control model |
| E-RANDOMIZED-RETENTION | The optimizer chooses a probability distribution over libraries to convexify the attainable resource--value set | extension-only; not used to infer strong Lagrangian equivalence in the discrete primary model |

## Explicitly rejected assumptions or shortcuts

1. The operational frontier stores maximizing strategy identifiers.
2. Generation may inspect the raw library after \(C_L\) is fixed.
3. Distinct closures are automatically behaviorally distinguishable without
   A-T2-OBS.
4. “Arbitrary loss” may be obtained solely by rescaling payoffs.
5. T5's generative component depends only on closure and not on candidate
   operational profiles.
6. T6 may omit initiation cost or interpret a state-level forced-project bound
   as marginal carrier value without frontier and comparator restrictions.
7. T7 may infer substitution from frontier independence or individual
   candidate saturation alone, or allow generator quality, cost,
   availability, or the completion coupling to depend on the frontier.
8. The admitted-outcome marginal \(\Gamma\) and terminal-belief marginal
   \(P_B^{d_q}\) imply conditional independence or determine their joint law.
9. The retention penalty \(\lambda W(L)\) is automatically a recurring
   maintenance flow inside the Bellman reward.
10. A hard ex ante capacity \(W(L')\le B\) automatically blocks or evicts a
    candidate admitted later by the raw process.
11. Equality of \(K_L=(F_L,C_L)\) implies equality of \(W(L)\) or of
    resource-penalized net value.
12. Mere raw generation, without separate outer certification, makes a
    strategy selectable by a full-catalog retention problem.
13. Every hard-capacity optimum is selected by some nonnegative resource
    price, or the discrete capacity problem has zero Lagrangian duality gap.
14. The conditional replacement problem silently includes rejection of the
    candidate as an outside option.
15. Any finite rechecked trace is irreducible without an endpoint-completeness
    condition.
16. Inclusion-wise irreducibility, or safety of a deterministic greedy trace,
    implies global minimum resource or an approximation ratio.
17. Exact Julia resource counterexamples are automatically Lean-verified
    theorems.
18. Finiteness or monotone submodularity alone implies capacity concavity or
    diminishing returns; or finiteness implies raw-inclusion nesting,
    breakpoint uniqueness, differentiability, or bounded zero-margin level
    elasticity.
19. Failure of pre-admission structural safety implies that every
    capacity-feasible replacement has positive productive loss; the candidate
    may replace the deleted incumbent's frontier or modules.
20. A zero or negative T5 component has an ordinary real log elasticity, or a
    zero channel share can be multiplied by an undefined component elasticity
    to recover its derivative contribution.
21. A unique optimizer at one parameter point remains stable without
    continuity and finiteness; every branch crossing is globally active; or
    positive current action margin removes a kink inherited from optimized
    continuation value.
22. A deterministic capacity step has an ordinary derivative elasticity at
    a jump; every optimizer-only threshold creates a capacity-value spike; or
    an unequal-burden price tie defines a unique scalar resource demand
    without an explicit selection rule.

## Future Lean reconciliation template

For each theorem declaration, the ledger must eventually add:

| Manuscript assumption | Assumption ID | Lean binder/typeclass | Match | Resolution |
|---|---|---|---|---|
| Exact manuscript text | A-… | Exact Lean object | exact / stronger / weaker / mismatch | Action and commit |

No theorem can become Lean verified while a row is stronger, weaker, or
mismatched without an explicit manuscript revision.
