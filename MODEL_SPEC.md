# Finite Model Specification for Paper 1

## Revision authority notice

Decisions D-0046 and D-0047 supersede this file's within-period timing,
candidate-update notation, product-kernel restriction, horizon clock, and
raw/compressed T1--T2 transition targets. The binding replacement definitions
are in `UNIFIED_TIMING_SPEC.md` and `RAW_TO_COMPRESSED_SPEC.md`. The older
blocks below are retained as a pre-migration record because the current Lean,
Julia, manuscript, and experiment artifacts still encode them. They must not
be used as the target semantics for new implementation or theorem claims.

Decision D-0111 and `RESOURCE_MODEL_SPEC.md` add the binding retention-resource
layer. That layer is external to the productive raw transition and value
recursion. If this file conflicts with `RESOURCE_MODEL_SPEC.md` on resource
weights, capacity, penalties, or the inactive-strategy convention, the
resource specification controls.

## Decision and scope

**Recommendation: model accepted.**

The accepted theorem core uses **Path A: a finite belief grid**. It is the
smallest model found that simultaneously supports exact partial information,
reusable strategies, genuinely compositional generation, verified admission,
library compression, finite-horizon dynamic value, pruning loss, value
decomposition, and belief-grid coverage.

Acceptance is limited to the finite theorem forms stated below. It does not
revive generic quotient-minimality novelty, an unbounded-loss claim at fixed
discount and horizon, an interaction-free value split, or a continuous-belief
coverage theorem. No implementation or proof is part of this specification.

## Why Path A is locked

Let \(X=\operatorname{Fin}(m)\) be the hidden market state and let \(B\) be a
nonempty finite type of belief-grid points. Each \(b\in B\) has an exact
rational interpretation
\[
  \mu_b\in\Delta_{\mathbb Q}(X),
\]
and the already-filtered information state follows an exact rational Markov
kernel
\[
  P_B:B\longrightarrow\Delta_{\mathbb Q}(B).
\]

This choice keeps every expectation, maximum, transition, and finite-horizon
Bellman recursion finite and rational. Lean need not formalize Bayes
normalization, support side conditions, or equality of arbitrary probability
vectors in the theorem-critical path. The hidden state remains substantive
because strategy payoffs are defined on \(X\) and averaged using \(\mu_b\).

An exact-probability-vector or continuous-simplex model is an extension only.
It may later be used in Julia or in separately labeled manuscript results, but
it is not part of the fully verified core.

## Finite exact primitives

For a finite type \(A\), write
\[
  \Delta_{\mathbb Q}(A)
  =
  \left\{p:A\to\mathbb Q:
    (\forall a,\ 0\le p(a))\ \land\ \sum_{a\in A}p(a)=1
  \right\}.
\]

The model has the following nonempty finite types:

- hidden market states \(X=\operatorname{Fin}(m)\);
- belief-grid points \(B\);
- strategy identifiers \(S\), called `StrategyId`;
- module identifiers \(M\), called `ModuleId`; and
- research projects \(Q\).

There is a distinguished inactive baseline strategy \(s_0\in S\), with
\(u_{s_0}(x)=0\) for every hidden state and
\(\operatorname{mods}(s_0)=\varnothing\). A raw library is a finite set
\(L\subseteq S\) with \(s_0\in L\). The baseline condition makes the
operational maximum total, gives it a zero lower bound, and keeps admissible
libraries closed under candidate admission and deletion of any nonbaseline
strategy.

## Strategy catalog

A `Strategy` is the immutable catalog row indexed by \(s\in S\):
\[
  \sigma_s=(s,u_s,\operatorname{mods}(s)),
\]
where
\[
  u_s:X\to\mathbb Q,
  \qquad
  \operatorname{mods}(s)\subseteq M.
\]

The operational profile of \(s\) at belief \(b\) is
\[
  j_s(b)
  :=
  \sum_{x\in X}\mu_b(x)u_s(x).
\]

Consequently, \(j_{s_0}(b)=0\) at every belief. The inactive row is an actual
catalog strategy in every admissible library, not a default value used only to
totalize an empty maximum.

Strategy identifiers, payoffs, and module sets are immutable. Libraries are
sets: multiplicity, age, provenance, and the order of admission have no
semantic effect in the theorem core.

## Retention resource layer

The resource extension adds an immutable catalog-indexed table
\[
  w:S\to\mathbb Q_{\ge0},
  \qquad
  w_{s_0}=0,
  \qquad
  s\ne s_0\Longrightarrow w_s>0.
\]
For an admissible library,
\[
  W(L)=\sum_{s\in L}w_s.
\]
The inactive strategy therefore contributes no resource burden. This zero
convention is an explicit exception to active-strategy strict positivity and
avoids adding the same mandatory constant to every library.

Weights are fixed catalog primitives. They do not depend on belief, age,
usage, time, library composition, or admission history. They do not enter the
frontier, closure, raw generation, verification, admission, belief path,
research reward, or library update. The existing dynamic value \(V\) remains
productive value before resource penalty, and the outer penalized objective
is
\[
  J_\lambda=V-\lambda W
\]
for rational \(\lambda\ge0\). A rational hard capacity restricts the one-time
retention choice by \(W(L')\le B\); it does not constrain later raw candidate
admission.

The optional nonadditive burden \(M(L)\in\mathbb Q_{\ge0}\) is reserved for
set-level validation, maintenance, retrieval, or governance interactions,
with total burden \(\widetilde W(L)=W(L)+M(L)\). The primary Paper 1 layer sets
\(M\equiv0\). Complete definitions, optimization domains, and the boundary
between resource burden, recurring maintenance cost, and hard capacity are in
`RESOURCE_MODEL_SPEC.md`. Source-relative safe compression, full-catalog
capacity and penalty selection, outer-candidate eligibility, conditional
replacement, optimizer existence, and the constrained--penalized boundary are
fixed in `OPTIMIZATION_PROBLEM_SPEC.md`. Outer eligibility is distinct from
stochastic raw verification.

## Operational frontier

For an admissible library \(L\), define the pointwise upper envelope
\[
  F_L:B\to\mathbb Q,
  \qquad
  F_L(b):=\max_{s\in L}j_s(b).
\]

Thus \(F_L(b)\) is a value, not a set of maximizing identifiers. A maximizing
strategy exists because \(L\) is finite and contains \(s_0\), and
\(F_L(b)\ge0\) because \(j_{s_0}(b)=0\). Ties are therefore immaterial to the
compressed state; a later policy-extraction lemma may select any maximizer
using finite decidability.

This value-frontier choice is essential. Retaining maximizing identifiers
would distinguish behaviorally identical strategies and would make the
compression needlessly fine.

## Modules and generative closure

Let
\[
  \operatorname{cl}:\mathcal P_{\mathrm{fin}}(M)
  \longrightarrow \mathcal P_{\mathrm{fin}}(M)
\]
be an extensive, monotone, idempotent closure operator. Define
\[
  U_L:=\bigcup_{s\in L}\operatorname{mods}(s),
  \qquad
  C_L:=\operatorname{cl}(U_L).
\]

The operator may encode finite recipes, compatibility rules, or module
derivations without introducing a separate recursively generated strategy
language. Composition is genuine because modules from different retained
strategies may jointly satisfy a project prerequisite, and candidate
generation is required to depend on \(C_L\), not on \(F_L\) alone.

## Compressed innovation state

The compressed state is
\[
  K_L:=(F_L,C_L).
\]

Although the ambient type
\((B\to\mathbb Q)\times\mathcal P_{\mathrm{fin}}(M)\) is not finite because of
\(\mathbb Q\), the realizable image
\[
  \mathcal K:=\{K_L:L\text{ is an admissible library}\}
\]
is finite because \(S\) is finite. This image subtype is the intended finite
Lean state space.

The raw controlled state is
\[
  \Omega=B\times\{\text{admissible libraries}\},
\]
and the compressed controlled state is
\[
  \bar\Omega=B\times\mathcal K.
\]
The hidden \(x\) is not observed or included in the planner's state; its
payoff effect is integrated through \(\mu_b\).

For a candidate \(c\in S\), define the local update
\[
  \operatorname{addK}((F,C),c)
  :=
  \left(
    b\mapsto\max\{F(b),j_c(b)\},
    \operatorname{cl}(C\cup\operatorname{mods}(c))
  \right).
\]
The closure axioms imply
\[
  K_{L\cup\{c\}}=\operatorname{addK}(K_L,c).
\]
Extend the update to optional admitted outcomes by
\[
  \operatorname{addK?}(K,\operatorname{none})=K,
  \qquad
  \operatorname{addK?}(K,\operatorname{some}(c))
  =\operatorname{addK}(K,c).
\]

### Deprecated abstract quotient layer

Before the raw generation and admission mechanism is encoded, a supporting
formal layer may take an exact finite-support transition
\[
  T(b,K,q)\in\Delta_{\mathbb Q}(\mathcal I)
\]
on the ambient compressed-state type \(\mathcal I\) as primitive. In that
layer, primitive dynamic innovation equivalence
\(\sim_{\mathrm{DI}}^{\mathrm{prim}}\) means equality of current frontiers and
of \(T(b,K_L,q)\) for every \(b,q\). A cost-free finite-horizon recursion under
this primitive kernel factors through the resulting quotient. This relation is
superseded as the final-model interface and retained only for F1--F4.

This supporting abstraction is not T1. T1 must construct \(T\) from the raw
generation, verification, cost, admission, and local update below, and must
prove equality with the raw-library Bellman recursion.

For the abstract frontier--closure characterization, declare a modular
generator
\[
  g(b,F,C,q)\in\Delta_{\mathbb Q}(\mathcal I)
\]
and assume exact factorization
\[
  T(b,(F,C),q)=g(b,F,C,q).
\]
Current reward observes \(F(b)\), so equality of current rewards at every
belief detects equality of \(F\). The converse for closure uses the explicit
probe condition
\[
  C\ne C'
  \Longrightarrow
  \exists b,q,\quad g(b,F,C,q)\ne g(b,F,C',q)
\]
whenever both \((F,C)\) and \((F,C')\) are realized by admissible libraries.
Under these assumptions,
\[
  L\sim_{\mathrm{DI}}L'
  \quad\Longleftrightarrow\quad
  F_L=F_{L'}\ \land\ C_L=C_{L'}
  \quad\Longleftrightarrow\quad
  K_L=K_{L'}.
\]
This is supporting result F2. It is not the raw one-step signature theorem T2,
which additionally includes project costs and admitted-candidate kernels.

## Research, generation, and verification

### Candidate-generation transition

Each project \(q\in Q\) has a finite prerequisite set
\(\operatorname{req}(q)\subseteq M\).

The raw candidate kernel is
\[
  G(q,b,C)\in\Delta_{\mathbb Q}(\operatorname{Option}(S)).
\]
`none` denotes generation failure. If
\(\operatorname{req}(q)\nsubseteq C\), the kernel is the point mass at
`none`.

For a raw candidate \(s\), the rational verification-pass probability is
\[
  \nu(q,b,C,s)\in[0,1]\cap\mathbb Q.
\]
The admitted-candidate kernel
\(\Gamma(q,b,C)\in\Delta_{\mathbb Q}(\operatorname{Option}(S))\) is
\[
\begin{aligned}
  \Gamma(q,b,C)(\operatorname{some}(s))
    &=G(q,b,C)(\operatorname{some}(s))\,\nu(q,b,C,s),\\
  \Gamma(q,b,C)(\operatorname{none})
    &=G(q,b,C)(\operatorname{none})
      +\sum_{s\in S}G(q,b,C)(\operatorname{some}(s))
       (1-\nu(q,b,C,s)).
\end{aligned}
\]

Only an admitted candidate enters the library:
\[
  L\oplus\operatorname{none}=L,
  \qquad
  L\oplus\operatorname{some}(s)=L\cup\{s\}.
\]

The total project and verification cost is
\[
  \kappa(q,b,C)\in\mathbb Q_{\ge0}.
\]
The core keeps a single total cost because splitting generation and
verification costs adds no theorem-relevant state. Raw generation and
verification remain separate so that “verified candidate” is not merely a
name for a generated object.

An idle action \(\bot\) is adjoined with zero cost and point-mass
`none` outcome.

### Genuine-composition requirement

The model class must contain realizable \(L,L'\), a belief \(b\), and a project
\(q\) such that
\[
  F_L=F_{L'},\quad C_L\ne C_{L'},\quad
  \Gamma(q,b,C_L)\ne\Gamma(q,b,C_{L'}).
\]
The smallest counterexample family in T4 supplies such a witness. This
nondegeneracy condition prevents the generator from being a disguised
function of the operational frontier.

## Within-period timing

At state \((b,L)\) with positive remaining horizon:

1. the planner observes \(b\) and \(L\), but not \(x\);
2. the best available operational profile pays \(F_L(b)\);
3. the planner chooses idle or one \(q\in Q\);
4. project cost \(\kappa(q,b,C_L)\) is paid;
5. raw generation and verification produce
   \(z\sim\Gamma(q,b,C_L)\);
6. the next library is \(L\oplus z\);
7. independently conditional on the current state and action,
   \(b'\sim P_B(b)\); and
8. continuation value is discounted by \(\beta\).

Generation before the next belief draw is what yields the product kernel used
below. Other timings are extensions and require new theorem statements.

## Discount and finite-horizon value

The discount factor satisfies
\[
  \beta\in\mathbb Q,\qquad 0\le\beta<1.
\]
The strict bound is not needed for existence of finite-horizon values, but it
aligns the core with the later infinite-horizon extension.

Define \(V_0(b,L)=0\). For \(h\in\mathbb N\),
\[
\begin{aligned}
V_{h+1}(b,L)
={}&F_L(b)+
\max_{a\in\{\bot\}\sqcup Q}
\Bigg[
  -\kappa(a,b,C_L)\\
&\quad+\beta
\sum_{b'\in B}P_B(b)(b')
\sum_{z\in\operatorname{Option}(S)}
\Gamma(a,b,C_L)(z)V_h(b',L\oplus z)
\Bigg].
\end{aligned}
\]
For idle, use \(\kappa=0\) and \(\Gamma=\delta_{\operatorname{none}}\).
Every term is rational and every sum and maximum is finite.

### Supporting primitive infinite-horizon extension (F8)

F8 applies to the separate A-FH-VALUE process, not directly to the accepted
raw recursion above. Its finite state is \(X=B\times\mathcal K_{\mathrm{prim}}\),
where \(\mathcal K_{\mathrm{prim}}\) is an arbitrary nonempty finite
compressed-state carrier with a primitive exact research kernel. Rational
model data are cast to reals and the Bellman operator acts on
\(X\to\mathbb R\) with the finite-product sup norm. Continue has coefficient
\(\beta\); research project \(q\) has coefficient
\(\beta^{d(q)+1}\le\beta\); and the operator takes the genuine finite maximum
over continue and every project.

The verified statement is exactly: the Bellman operator is a contraction with
modulus \(\beta<1\); it has a unique fixed point; iteration from any real
initial table converges uniformly with the Banach a priori error bound; the
exact rational A-FH-VALUE finite-horizon recursion, cast to reals, is iteration
from zero and converges uniformly and pointwise; and F5 cost-sensitive dynamic
innovation equivalence preserves fixed-point value. No stationary policy,
raw/compressed simulation, or series representation is included.

## Preservation target

The accepted preservation statement is model-specific:

- current operational reward is recovered from \(F\);
- project costs and admitted-candidate kernels are recovered from \(C\);
- every admitted-candidate update is computed by `addK`; and
- finite-horizon value factors through \((b,K_L)\).

No claim is made that \(K\) is the generic minimal bisimulation quotient of an
arbitrary augmented MDP.

The final-model dynamic innovation relation is cost-sensitive. It compares
the current frontier and, with unavailable projects tagged by `none`, every
project's initiation cost, full duration, joint terminal
belief/next-compressed-state law, and exact expected incumbent-reward block.
These five observations define UDI. UDI preserves finite calendar-horizon
values, preserves contraction fixed-point values, has a finite raw-library
quotient, and is implied by equality of \(K_L\). Representation refinement is
asserted only when equal representation fibers preserve all five observations.

## Theorem package

T1--T7 and UDI are Lean verified. “Lean-verifiable form”
identifies the exact finite statement required by the claim gate.

### T1 — Structural quotient sufficiency

**Strongest desired form.** For every horizon, optimal value and an optimal
research action depend on the raw library only through \(K_L\), and the
compressed recursion is a homomorphic image of the raw recursion.

**Finite Lean-verifiable form.** Define \(\bar V_h:B\times\mathcal K\to\mathbb
Q\) by the same calendar-horizon recursion using `addK`. Under the T1
assumptions,
\[
  V_h(b,L)=\bar V_h(b,K_L)
\]
for every \(h,b,L\). Also prove the candidate-update identity
\(K_{L\oplus o}=\operatorname{addK}(K_L,o)\), normalization of the derived
admission law, equality of the raw and compressed joint completion
pushforwards, and the controlled Markov projection at embedded decision
epochs. Conditional terminal-belief/outcome independence is not assumed.

**Stronger manuscript extension.** Infinite-horizon discounted value and a
stationary optimal project policy factor through \(K\), after a separately
proved contraction theorem.

**Risk of falsehood.** Low for the finite form; high if generation,
verification, cost, belief transitions, or payoffs depend on raw provenance,
multiplicity, or deleted identifiers.

**Counterexample strategy.** Give two libraries with equal \(F\) and \(C\) but
different provenance-dependent generation kernels. Their one-step values
separate, showing why A-GEN-FACTOR is necessary.

### T2 — Frontier–closure characterization

In the accepted raw model, generation and primitive admission are indexed only
by project, belief, and closure; feasibility, cost, and the completion
coupling are indexed only by the realizable compressed state; operating
rewards use the frontier. Under A-T2-OBS, every distinct pair of realizable
closures at a common frontier changes a tagged cost, tagged duration, or
projected joint terminal-belief/next-compressed-state law. Raw
candidate/admission differences count only when they survive into that
projected observation.

**Finite Lean-verified form.**
\[
  L\sim_{\mathrm{DI}}L'
  \quad\Longleftrightarrow\quad
  F_L=F_{L'}\ \land\ C_L=C_{L'}
  \quad\Longleftrightarrow\quad
  K_L=K_{L'}.
\]
The forward proof first derives equality of raw candidate laws, primitive
admission probabilities, admitted laws, and T1-projected raw transitions. The
converse uses only the raw-process detectability witness, never the deprecated
abstract \(T\) table.

**Stronger manuscript extension.** Full abstraction under all finite
continuation rewards, with a precisely delimited comparison class.

**Risk of falsehood.** Medium. Without closure observability, distinct
behaviorally silent module closures have identical signatures and \(K\) is
over-refined. Generic minimality is already excluded by the novelty audit.

**Counterexample strategy.** Add a module that is never required by any
project. It changes \(C\) but neither costs nor candidate kernels, refuting the
converse without A-T2-OBS. Separately, allow generation to inspect a hidden raw
identifier to refute forward sufficiency outside the typed raw factorization.

**Lean implementation.**
StrategyInnovation/Quotient/RawFrontierClosure.lean, audited by
StrategyInnovation/Audit/RawFrontierClosure.lean.

### T3 — Exact innovation-safe deletion criterion

For \(s\in L\setminus\{s_0\}\), write \(L^{-s}=L\setminus\{s\}\).

**Verified unified form.** Define operational redundancy by
\(F_{L^{-s}}=F_L\), generative redundancy by \(C_{L^{-s}}=C_L\), and unified
innovation safety by equality of all five UDI observations plus raw value
equality for every finite horizon and belief. Then
\[
  [F_{L^{-s}}=F_L\ \land\ C_{L^{-s}}=C_L]
  \iff K_{L^{-s}}=K_L.
\]
This equality implies innovation safety through T1. Under a declared
contraction model it preserves fixed-point values, every pairwise stationary
action-value comparison, and optimal actions. Under A-T2-OBS, preservation of
the unified process observations and the full innovation-safety certificate
are each equivalent to the two redundancy equalities.

**Verified stepwise extension.** A proof-relevant deletion trace rechecks both
equalities at every intermediate library. Its endpoint is a sublibrary with
the same compressed state, UDI class, all finite-horizon values, and
contraction value. `PruningAlgorithmSpec` requires every pruning output to
carry such a trace, so every performed deletion receives an
`InnovationSafeDeletion` certificate.

**Optimization interpretation.** Under the fixed additive resource layer, a
certified deletion of active \(s\) makes the current library a strictly
dominated feasible point of the source problem
\(P_{\mathrm{safe}}(L)\), because burden falls by \(w_s>0\). A complete
rechecked trace ends only when no current one-strategy safe deletion remains;
that terminality condition, not trace safety alone, supplies
inclusion-wise irreducibility. Neither property supplies a global
minimum-weight claim. Exact definitions and the minimized Julia witnesses are
in `LOCAL_VS_GLOBAL_COMPRESSION_SPEC.md`; revised theorem statements are in
`OPTIMIZATION_THEOREM_REVISIONS.md`.

**Boundary.** Original-library redundancy certificates do not compose:
duplicate encodings can each be redundant initially, while the survivor is
essential after the first deletion. Rechecked orders can retain different raw
identifiers, but those endpoints have equal compressed states.

**Lean implementation.**
`StrategyInnovation/Compression/UnifiedSafeDeletion.lean`, exact examples in
`StrategyInnovation/Compression/UnifiedSafeDeletionExamples.lean`, and
focused audit in `StrategyInnovation/Audit/UnifiedSafeDeletion.lean`.

### T4 — Sharp normalized frontier-only pruning loss

**Canonical raw construction.** A zero-payoff bridge is operationally
dominated but uniquely carries the module required for one descendant. The
project has positive delay \(d\), exact discount \(0\le\beta<1\), raw
survival-gate mass \(\rho^d\), primitive admission probability \(\pi\), reward
cap \(C\), and initiation cost difference \(\kappa-0\), with
\[
  0\le\rho,\pi\le1,\qquad C,\kappa\ge0.
\]
The raw generator produces the descendant with mass \(\rho^d\) only when the
bridge module is present. The derived admitted-candidate mass is therefore
\(\rho^d\pi\) before pruning and zero afterward.

**Exact theorem.** The one-project Bellman envelope compares zero-valued
Continue with expected discounted descendant reward less initiation cost.
When
\[
  \kappa\le\beta^d\rho^d\pi C,
\]
frontier-only pruning has exact loss
\[
  \operatorname{Loss}
  =\beta^d\rho^d\pi C-\kappa.
\]
For fixed \((\beta,\rho,\pi,d,\kappa)\), every reward \(R\in[0,C]\) has loss
at most this quantity, and \(R=C\) attains the bound. If the net quantity is
positive, pruning destroys all attainable net descendant value, so the loss
ratio is one.

**Normalization and scaling boundary.** If \(C\le1\), exact loss is at most
one. The theorem therefore does not use unbounded rewards. Arbitrary additive
loss is only the corollary obtained by scaling the cap; for example
\(d=1,\beta=1/2,\rho=\pi=1,\kappa=0,C=2M\) gives loss \(M\).

**Operation during research.** Continued operation adds
\[
  G_L^{\rm op}-G_{L^{-s}}^{\rm op}
\]
to the base formula. Operational redundancy and the common belief-path law
make these exact incumbent-reward blocks equal in the canonical construction,
so the adjustment vanishes.

**Lean implementation.**
`StrategyInnovation/Compression/NormalizedPruningLoss.lean`, with focused
audit in `StrategyInnovation/Audit/NormalizedPruningLoss.lean`.

### T5 — Unified operational--generative decomposition

On the T1 raw process, define the frozen-library passive value
\[
  P_0(b,L)=0,\qquad
  P_{h+1}(b,L)=F_L(b)+\beta
    \sum_{b'}P_B(b)(b')P_h(b',L).
\]
This counterfactual freezes the raw verified library and excludes every
research action. Full value is the unified finite-calendar raw Bellman value
\(U_h(b,L)\) from T1, including positive project duration, exact initiation
cost, the declared possibly correlated completion coupling, and the incumbent
operating-reward block. T1 gives
\[
  U_h(b,L)=\bar U_h(b,K_L).
\]
Define
\[
  \Omega_h(b,L)=U_h(b,L)-P_h(b,L)
\]
and, for insertion of \(s\),
\[
  \mathcal I_h=U_h(b,L\cup\{s\})-U_h(b,L),\qquad
  \Delta_h^{\mathrm{op}}=P_h(b,L\cup\{s\})-P_h(b,L),
\]
and
\[
  \Delta_h^{\mathrm{gen}}
    =\Omega_h(b,L\cup\{s\})-\Omega_h(b,L).
\]
Then the exact T5 identity is
\[
  \mathcal I_h
    =\Delta_h^{\mathrm{op}}+\Delta_h^{\mathrm{gen}}.
\]
It is algebraic, but all three components are now defined on the accepted raw
process rather than the primitive F5 adapter.

Equal insertion frontiers imply \(\Delta_h^{\mathrm{op}}=0\). Equal insertion
frontiers and closures imply \(\mathcal I_h=0\) through equality of \(K_L\)
and T1, without an old primitive-transition factorization assumption.
Library inclusion weakly lowers a fixed candidate's operational insertion
value at every belief and finite horizon.

For premium monotonicity, T5 uses A-T5-PROJECT-DOMINANCE: the enriched library
has the same frontier, a larger closure and feasible menu, and weakly larger
exact unified project-action value for every old project, belief, and remaining
horizon. The project comparison includes cost, duration, the correlated
terminal law, operation during research, and continuation. Under this explicit
certificate, full value and hence the research-option premium cannot fall.
Closure inclusion alone is not enough.

The exact bridge witness has one belief, duration one, discount \(1/2\), zero
cost, suspended operation, a raw generator keyed by the bridge module, and
unit admission. Inserting the zero-frontier bridge changes passive value by
zero and research-option premium by exactly one at horizon two.

Supporting F6 remains the older primitive-F5 insertion accounting theorem, and
F7 remains its passive gap-sum companion. Neither proves T5 and neither changes
the unified timing.

### S4 — Finite one-shot coverage-potential representation

Supporting result S4 uses a separate finite ordered-belief occupation model.
Let \(B\) be a nonempty finite linearly ordered grid, let
\(\omega_t(b,b')\ge0\) be the exact date-\(t\) occupation weight of future
belief \(b'\) from initial belief \(b\), and let \(H<\infty\). For a fixed
candidate produced by project \(q\), define its certified gap over existing
frontier state \(K\) by
\[
  \Delta(q,K,b')=\max\{j_q(b')-F_K(b'),0\}.
\]
With exact discount \(\beta\) and candidate survival probability \(\rho_q\),
define
\[
  W_H^{\beta,\rho_q}(b,b')
  =\sum_{t=0}^{H-1}\beta^t\rho_q^t\omega_t(b,b'),
  \qquad
  \Psi_H(q,K,b)
  =\sum_{b'\in B}W_H^{\beta,\rho_q}(b,b')\Delta(q,K,b').
\]
Finite-sum rearrangement gives the exact one-shot gross operational value
\[
  \Psi_H(q,K,b)
  =\sum_{t=0}^{H-1}\sum_{b'\in B}
    \beta^t\rho_q^t\omega_t(b,b')\Delta(q,K,b').
\]
The declared probability model assumes every date-specific occupation row
sums to one and \(0\le\beta,\rho_q\le1\). The reusable finite-sum results also
cover unnormalized nonnegative subprobability or exposure weights. They prove
monotonicity in the pointwise gap, discount, survival, and occupation; zero
value when the gap vanishes on every occupation-reachable belief; a regional
minimum-gap lower bound; global and support-restricted maximum-gap upper
bounds; strict positive future coverage despite zero current gap; and
antitonicity under pointwise improvement of the existing frontier.

S4 is gross fixed-candidate operational value. It contains no project cost,
generation, verification, success/admission probability, or carrier
comparator, so it is contextual support rather than a proof of T6.

### S6 — Finite patience--survival complementarity

Specialize S4's occupation weights to powers of an exact finite
row-stochastic matrix \(P\), and write the nonnegative gap as the vector
\(g\). For \(\alpha=\beta\rho\), define
\[
 U_{\alpha,H}:=\sum_{t=0}^{H-1}\alpha^tP^t,\qquad
 \Psi_H(\beta,\rho):=U_{\beta\rho,H}g.
\]
Lean proves the exact finite identity
\[
 \Psi_H(\beta,\rho)=\sum_{t=0}^{H-1}(\beta\rho)^tP^tg,
\]
and pointwise monotonicity in either nonnegative scalar. If
\(0\le\beta_0\le\beta_1\) and \(0\le\rho_0\le\rho_1\), then
\[
\begin{split}
 &[\Psi_H(\beta_1,\rho_1)-\Psi_H(\beta_0,\rho_1)]
 -[\Psi_H(\beta_1,\rho_0)-\Psi_H(\beta_0,\rho_0)]\\
 &\quad=\sum_{t=0}^{H-1}
  (\beta_1^t-\beta_0^t)(\rho_1^t-\rho_0^t)P^tg\ge0.
\end{split}
\]
This is equivalent to the four-corner cross-difference inequality. Matrix
row stochasticity derives \(P^tg\ge0\); no real differentiation is used. The
infinite inverse \(U_\alpha=(I-\alpha P)^{-1}\) remains interpretation and an
exact Julia check, not a Lean S6 conclusion.

### S7 — Belief-kernel alignment, not persistence alone

For a finite belief type, exact rational kernel \(P\), nonnegative gap
\(g\), finite horizon \(H\), and effective discount \(\alpha\), define
\[
  \Psi^P_{H,\alpha}(b)
    :=\sum_{t=0}^{H-1}\alpha^t(P^tg)(b)
    =\sum_{b'\in B}W^P_{H,\alpha}(b,b')g(b'),
\qquad
  W^P_{H,\alpha}(b,b')
    :=\sum_{t=0}^{H-1}\alpha^t(P^t)(b,b').
\]
The gap-tailored order is
\[
  P_1\succeq_gP_0
  \quad\Longleftrightarrow\quad
  \Psi^{P_1}_{H,\alpha}(b)\ge
  \Psi^{P_0}_{H,\alpha}(b)
  \quad\text{for every }b.
\]
A primitive sufficient condition is advantage-region occupation alignment:
for every initial \(b\) and every \(b'\) with \(g(b')>0\),
\[
  W^{P_1}_{H,\alpha}(b,b')
    \ge W^{P_0}_{H,\alpha}(b,b').
\]
Because \(g\ge0\), finite-sum multiplication and addition prove
\(P_1\succeq_gP_0\).

There is no scalar persistence sign. On `Fin 2`, use the exact stochastic
family
\[
  P(\theta)=
  \begin{pmatrix}\theta&1-\theta\\1-\theta&\theta\end{pmatrix}.
\]
At initial state zero, with \(H=2\), \(\alpha=1/2\), and
\(\theta:1/4\to3/4\), coverage rises \(9/8\to11/8\) for
\(g=(1,0)\), falls \(3/8\to1/8\) for \(g=(0,1)\), and remains \(3/2\)
for \(g=(1,1)\). Thus persistence matters through alignment with uncovered
beliefs, not through persistence alone.

### T6 — Joint descendant-event generative-option lower bound

Let \(L^+=L\cup\{s\}\), where \(s\) is frontier-silent, and suppose project
\(q\) is feasible at \(K_{L^+}\), infeasible at \(K_L\), has duration
\(d_q\le h\), and the deleted comparator has zero research-option premium.
For a nonnegative terminal gain \(G:B\to\mathbb Q_+\), define
\[
 \eta_{q,g}(b'\mid b,K_{L^+})
 :=
 \Pr(B_{d_q}=b',O=\operatorname{some}(g)\mid b,K_{L^+},q).
\]
This terminal pushforward of the T1 joint completion law need not factor. On
each terminal belief, \(0\le\eta_{q,g}(b')\le1\), and the total
distinguished-descendant event mass satisfies
\(\sum_{b'}\eta_{q,g}(b')\le1\). On
every length-\(d_q\) path ending in `some g`, the complete continuation
improvement over the frozen retained-library passive continuation is at least
\(G(B_{d_q})\). The floor includes future project-menu changes. Failure is an
identity update and every other admission is insertion-only, so omitted
outcomes are nonnegative by passive inclusion monotonicity and
full-over-passive dominance.

The exact unified-timing adjustment is
\[
 A^{\mathrm{op}}_{q,h}(b,L^+)
 :=
 \mathbb E[
   G^{\mathrm{op}}+\beta^{d_q}P_{h-d_q}(B_{d_q},L^+)]
 -P_h(b,L^+).
\]
Equivalently, the exact project commitment separates initiation cost, the
operating block, frozen passive continuation, the joint descendant gain, and
a remaining-continuation term. Under the stated insertion-only and
supportwise-floor assumptions, that remaining term is nonnegative; this is
the precise condition allowing failure and other admitted outcomes to be
omitted from the lower bound.

**Lean-verified finite form.**
\[
 \Delta_h^{\mathrm{gen}}(s\mid b,L)
 \ge
 \max\left\{
   -\kappa+A^{\mathrm{op}}_{q,h}(b,L^+)
   +\beta^{d_q}\sum_{b'}\eta_{q,g}(b'\mid b,K_{L^+})G(b'),0
 \right\}.
\]
If the research block exactly reproduces the retained passive baseline, then
\(A^{\mathrm{op}}=0\), giving the simpler formula. No independence is assumed.
If
\(\eta_{q,g}(b')=\pi\rho^{d_q}\mu_{q,d_q}(b,b')\), the theorem recovers the
earlier product expression
\(\beta^{d_q}\pi\rho^{d_q}\mathbb E_b[G(B_{d_q})]\).
The guarantee is monotone in pointwise \(\eta\), pointwise \(G\), and
\(A^{\mathrm{op}}\), and antitone in \(\kappa\).

**Risk of falsehood.** High if cost is omitted, if the carrier changes the
frontier, if the deleted state retains other innovation premium, or if
admission can destroy existing strategies without a harm correction. A
terminal gain that is not a supportwise complete-continuation floor, a project
whose duration exceeds the horizon, or a product-of-marginals shortcut under
correlation also invalidates the claim. Conditional independence is not a
consequence of T1's two marginal laws. Duration has no unconditional sign
when it changes the joint law, occupation, continuation gain, horizon
feasibility, or operating adjustment. CX-T6-COST-01 and the
`CX-T6-JOINT-*` fixtures preserve the minimal failures.

### CS1 — Supporting sign-definite finite comparative statics

The finite unified process admits the following one-way order results under
A-CS-SIGN:

1. a primitive one-step generative-dominance order raises full compressed and
   raw value at every finite calendar horizon;
2. if availability, costs, and the complete joint completion law are
   frontier-independent at a fixed closure, then
   \(F_0\le F_1\) implies \(V_h(F_0,C)\le V_h(F_1,C)\);
3. pointwise frontier improvement weakly lowers a fixed candidate's passive
   operational insertion value;
4. pointwise lower nonnegative research-cost schedules weakly raise optimized
   value when every other primitive is fixed;
5. in an otherwise fixed binary candidate law, admission and per-period
   survival raise project return when success weakly dominates failure;
6. T5's declared closure-enrichment/project-dominance order raises full raw
   value; and
7. lower cost or higher survival expands the exact finite weak-research
   action region when every other primitive is fixed.

For elapsed project duration, define
\[
 R_d=-\kappa+\sum_{t<d}\beta^tF_t+\beta^dW.
\]
The exact increment is
\[
 R_{d+1}-R_d=\beta^d\{F_d-(1-\beta)W\}.
\]
Thus nonnegative operation and continuation alone are insufficient for delay
antitonicity. The Lean-verified theorem additionally requires
\(F_t\le(1-\beta)W\) on every added elapsed date. Suspended operation is the
special case \(F_t=0\). Exact Lean counterexamples cover frontier-dependent
opportunities, harmful success, the nonnegative delay reversal, negative
continuation, closure inclusion without dominance, and a cost change
accompanied by deteriorating returns.

CS1 is a supporting family. It does not establish T7's antitonicity of the
optimized innovation premium in the frontier.

### T7 — Frontier--closure system interaction

For \(F_0\le F_1\) and \(C_0\subseteq C_1\), define
\[
  \Delta_CV(F;C_1,C_0)=V(F,C_1)-V(F,C_0)
\]
and
\[
  J=\Delta_CV(F_1;C_1,C_0)-\Delta_CV(F_0;C_1,C_0).
\]
The channels are substitutes on the displayed rectangle when \(J\le0\) and
complements when \(J\ge0\).

Primitive-frontier-independent research means that, at every closure, project
availability, cost, duration, operation flag, and the terminal joint
belief/admission law \(\Xi_q\) are functions of \((q,b,C)\) and not of the
frontier. The common Markov path marginal, catalog profiles, and extension-only
`addK` update remain fixed.

**Insufficient requested form.** Primitive independence, fixed candidate
profiles, unchanged project rows, closure-only menu expansion, and
\(F_0\le F_1\) do not imply \(J\le0\). In
CX-T7-INDEPENDENT-MENU-SWITCH-02, both old and added project premia fall with
the frontier, but their different fixed success/cost rows make the optimizer
switch projects, giving \(J=1/2\).

**Correct finite Lean form.** Add relative action saturation. At every finite
Bellman node, every closure-rich feasible action \(a_1\) and closure-poor
feasible action \(a_0\) obey
\[
 Q_h(F_1,C_1,a_1)-Q_h(F_1,C_0,a_0)
 \le
 Q_h(F_0,C_1,a_1)-Q_h(F_0,C_0,a_0).
\]
Here \(Q_h\) is the exact unified action value, including initiation cost,
positive duration, operation during research, the complete joint completion
law, `addK`, and lower-horizon optimized continuation. Selecting the exact
maximizers at \((F_1,C_1)\) and \((F_0,C_0)\) then proves \(J\le0\). The
condition is action-level single crossing, not the conclusion restated.

Strict substitution is attained by a single fixed opportunity whose
frontier gap saturates. Strict complementarity remains possible when generator
success rises with the frontier, as in CX-T7-FRONTIER-GENERATOR-01, and a
separable value surface has \(J=0\).

## Rejected stronger claims

The following statements are not part of the accepted model:

1. \(K\) is the generic minimal quotient of every augmented innovation MDP.
2. Equality of finite-horizon value for one calibration implies equality of
   \(F\) and \(C\).
3. Normalized frontier-only pruning loss is unbounded for fixed
   \((\beta,H)\).
4. \(V\) splits into an operational term depending only on \(F\) and a
   generative term depending only on \(C\).
5. A cost-free probability-times-gap quantity lower-bounds generative option
   value without comparator assumptions.
6. Frontier--closure substitutability holds when generator quality or the
   completion coupling depends on the frontier.
7. Persistence, information, or the raw research operator has a universal
   one-direction comparative static without gap-shape, coupling, or
   continuation-value assumptions.

## Minimality of the specification

Removing any of the following destroys a required primary result:

| Component | Result lost if removed |
|---|---|
| finite \(B\) and rational \(P_B\) | exact belief-grid value and T6--T7 |
| state payoffs \(u_s\) and \(\mu_b\) | substantive hidden-state interpretation |
| pointwise frontier \(F_L\) | operational compression and deletion half of T3 |
| modules and closure \(C_L\) | compositional generation and generative deletion half |
| raw generation plus verification | verified admission distinction |
| candidate-dependent library update | dynamic innovation and T4 |
| finite horizon | exact first Bellman theorem and value decomposition |
| idle action | total decision problem and nonnegative innovation premium |

Conversely, observations, continuous beliefs, strategy multiplicities,
provenance, multiple simultaneous projects, separate generation/verification
cost accounts, and infinite-horizon fixed points are not needed for T1--T7's
finite core.

## Final recommendation

**Model and finite T1--T7 statements accepted for proof preparation.** The
exact counterexample gauntlet in
`experiments/results/revision_counterexample_gauntlet.json` found no
in-assumption failure within its declared finite bounds. This is not proof.
No Lean formalization may claim a result until its exact statement and every
assumption above are encoded and reconciled through the theorem ledger.
