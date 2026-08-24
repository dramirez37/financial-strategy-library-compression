# Resource Model Specification for Paper 1

## Status and scope

This specification adopts the Paper 1 resource layer under D-0111. It is a
conservative outer layer around the existing finite raw innovation process:
resources affect which library is retained and how retained libraries are
ranked, but they do not change operating payoffs, candidate generation,
verification, admission, belief evolution, research timing, or the raw
library update.

The primary resource model is exact, finite, rational, and additive. The
optional nonadditive object below is reserved for discussion and later work.
The additive outer layer is now implemented in Julia with
`Rational{BigInt}` arithmetic and exact finite enumeration. This does not
establish a Lean theorem or a resource experiment.
`OPTIMIZATION_PROBLEM_SPEC.md` controls the exact feasible domains for safe,
capacity-constrained, penalized, and replacement problems.

## 1. Economic interpretation

For every noninactive catalog strategy \(s\ne s_0\), let
\[
  w_s\in\mathbb Q_{>0}
\]
be its resource weight. The weight is a commensurated stock measure of the
burden created by retaining that strategy in the usable library. It may
aggregate:

- storage and indexing;
- validation and revalidation;
- maintenance and dependency repair;
- monitoring and incident response;
- retrieval and routing overhead; and
- documentation, approval, and governance burden.

The six components need not have natural common physical units. A calibration
must first convert them into one declared resource unit. Once that calibration
is fixed, \(w_s\) is treated as primitive data rather than as utility,
productive payoff, project cost, or a probability.

The resource burden is attached to retention, not to whether a strategy is
currently selected for operation. A dominated or rarely used strategy can
therefore have positive resource weight even when it contributes no current
frontier value. This is the channel that makes resource-constrained
compression economically distinct from ordinary operational pruning.

## 2. Exact rational representation

The primary weight table is
\[
  w:S\longrightarrow\mathbb Q_{\ge0},
  \qquad
  w_{s_0}=0,
  \qquad
  s\ne s_0\Longrightarrow w_s>0.
\]
Thus the instruction that strategy weights are strictly positive applies to
every active strategy. The inactive baseline is the explicit exception.

For every admissible finite library \(L\), define
\[
  W(L):=\sum_{s\in L}w_s
       =\sum_{s\in L\setminus\{s_0\}}w_s.
\]
The two sums are equal because \(w_{s_0}=0\). Consequently,
\[
  W(\{s_0\})=0,\qquad W(L)\ge0,
\]
and adding any previously absent active strategy strictly increases \(W\).
The zero-baseline convention avoids a mandatory constant in every objective
and makes every nonnegative capacity budget admit the inactive-only library.
A fixed positive mandatory baseline burden would only translate every budget
and penalized objective by a constant, but Paper 1 does not use that
alternative.

Every weight, resource budget \(B\), and resource price \(\lambda\) in the
primary exact layer is rational, with
\[
  B\in\mathbb Q_{\ge0},
  \qquad
  \lambda\in\mathbb Q_{\ge0}.
\]
Mathematically, a positive weight is an exact rational equivalence class. A
serialized representation uses a normalized integer numerator and positive
integer denominator. The planned Lean layer should use `ℚ`; the Julia layer
uses `Rational{BigInt}` and rejects floating inputs. Floating-point weights may
be used only in separately labeled numerical extensions and are not proof
data.

### Optional nonadditive burden

For future discussion, reserve an exact nonnegative set functional
\[
  M:\mathcal L\longrightarrow\mathbb Q_{\ge0},
  \qquad
  M(\{s_0\})=0,
\]
where \(\mathcal L\) is the finite set of admissible libraries. No additivity
or monotonicity of \(M\) is implicit. It may represent shared validation
infrastructure, pairwise compatibility work, fixed governance overhead, or
other set-level economies or diseconomies.

When both layers are used, the total burden is
\[
  \widetilde W(L):=W(L)+M(L).
\]
Paper 1's primary theorem and implementation targets set \(M\equiv0\) and use
\(W\). Any theorem using \(\widetilde W\) must state the properties of \(M\)
that it needs; additive proofs and weighted 0--1 formulations do not transfer
automatically.

## 3. Catalog status of the weights

The weight table is an immutable catalog primitive indexed by `StrategyId`.
It is fixed at the same logical stage as the payoff and module tables, but it
is not derived from either table. An admitted candidate `some(s)` inherits
the already declared \(w_s\); admission does not estimate or renegotiate its
weight.

For conservative implementation, the first Lean and Julia resource layers
may store \(w\) in a separate catalog-indexed structure instead of modifying
the existing proof-critical `StrategyCatalog`. That representation choice
does not change the semantics: two occurrences of the same strategy
identifier have the same resource weight, and set-valued libraries never
count multiplicity.

Experimental calibrations may select different prospective weight tables, but
each table is a different model parameterization. It must be versioned and
locked before resource-sensitive outcomes are inspected.

## 4. Dependence on belief, age, or usage

In Paper 1,
\[
  w_s=w(s)
\]
depends only on the catalog strategy identifier. It does not depend on:

- current belief \(b\);
- library composition;
- strategy age or admission date;
- realized or expected usage;
- retrieval frequency;
- time;
- maintenance history; or
- past validation outcomes.

Belief-, age-, usage-, or time-dependent weights would turn resource burden
into a dynamic state variable or flow. They would require an enlarged state,
a new transition convention, and possibly repeated retention decisions.
Those variants are extension-only. Uncertainty about how a fixed weight was
measured may be studied statistically without making the weight
belief-dependent inside the mathematical model.

## 5. Why Paper 1 uses fixed additive weights

Fixed additive rational weights give the smallest resource layer that
supports the paper's optimization question without changing the productive
innovation process. They provide:

- exact comparison, summation, budgets, and prices;
- a transparent contribution from each retained strategy;
- monotonicity under active-strategy insertion;
- direct weighted enumeration and solver-neutral 0--1 objectives;
- a finite Lean representation with elementary algebra; and
- clean separation between resource scarcity and productive dynamics.

This restriction is a tractability and identification choice, not a claim
that real validation or governance systems are physically additive. The
optional \(M(L)\) records the omitted set-level channel explicitly. Paper 1
does not mix that channel into additive results unless an equally exact and
tractable theorem is stated separately.

## 6. Resource burden, recurring maintenance cost, and hard capacity

These are different economic objects.

| Object | Primary notation | Role in Paper 1 |
|---|---|---|
| Resource burden | \(W(L)\) | Stock measure used to rank or constrain retained libraries |
| Resource price | \(\lambda\) | Converts one resource unit into productive-value units in a penalized outer objective |
| Recurring maintenance cost | not in the primary model | A per-calendar-period flow that would have to enter operating or research reward explicitly |
| Hard capacity | \(B\) | Feasibility bound \(W(L)\le B\) at the one-time retention decision |
| Research initiation cost | \(\kappa_q(b,K)\) | Existing one-time cost of starting project \(q\); distinct from retaining strategies |

The term \(\lambda W(L)\) is a retention penalty or shadow-price valuation.
It is not automatically a recurring maintenance flow. If an application
interprets \(\lambda W\) as the present value of recurring maintenance, the
conversion and horizon must be stated outside the primary model. If recurring
maintenance is instead deducted every calendar period, it changes operating
rewards and the Bellman value and therefore requires a new dynamic theorem
layer.

A hard capacity is a constraint, not a cost. Because retained libraries form
a finite discrete set, the capacity-constrained and price-penalized problems
need not select the same library at every \(B\) and \(\lambda\). No
zero-duality-gap or complete Lagrangian-equivalence claim is implicit.

## 7. Effect on reward, feasibility, and optimization

### Operating reward and productive value

The raw Continue reward remains \(F_L(b)\). Research still pays
\(\kappa_q(b,K_L)\), uses the existing incumbent-operation convention, and
continues through the existing joint completion law. The resource table does
not enter \(F_L\), \(C_L\), \(G\), \(\nu\), \(\Gamma\), \(\Lambda_q\), the raw
update, or any compressed pushforward.

Write \(V_\theta(b,L)\) for the applicable existing productive value, where
\(\theta\) records the finite-horizon or stationary specification and other
held-fixed process primitives. The symbol \(V\) always means productive value
before a retention-resource penalty.

### Admission and retention feasibility

For a source library \(L\), define the one-time retained-library domain
\[
  \mathcal R(L)
  :=
  \{L'\subseteq L:s_0\in L'\}.
\]
This is the source-relative domain for current-library compression. Exact
innovation-safe compression additionally requires
\[
  F_{L'}=F_L,
  \qquad
  C_{L'}=C_L.
\]

Capacity-constrained and penalized retention instead select from the complete
outer-certified retention-eligible catalog
\(S_\theta^{\mathrm{elig}}\subseteq S\). Their admissible domain is
\[
  \mathfrak L(S_\theta^{\mathrm{elig}})
  =
  \{L'\subseteq S_\theta^{\mathrm{elig}}:s_0\in L'\}.
\]
A hard-capacity choice additionally requires \(W(L')\le B\).
Outer certification here is distinct from stochastic verification in the raw
transition. Mere raw generation does not add an identifier to this selection
domain.

This outer retention feasibility must not be confused with raw candidate
admission. In the primary model, generation, verification, and admission
after the initial retention choice are unchanged, and a newly admitted
strategy is not rejected or followed by eviction merely because its weight
would cross \(B\). Enforcing capacity at every future date would alter the raw
transition and make resource management a repeated control problem; that is
an explicit extension, not an implicit consequence of this specification.

### Optimization objectives

The additive layer supports four distinct finite problems.

1. Exact safe compression:
   \[
     \underset{L'\in\mathcal R(L)}{\operatorname{argmin}}\;W(L')
     \quad\text{subject to}\quad
     F_{L'}=F_L,\ C_{L'}=C_L.
   \]

2. Hard-capacity retention:
   \[
     \underset{L'\in\mathfrak L(S_\theta^{\mathrm{elig}})}
       {\operatorname{argmax}}\;
       V_\theta(b,L')
     \quad\text{subject to}\quad
     W(L')\le B.
   \]

3. Penalized retention:
   \[
     J_{\theta,\lambda}(b,L')
       :=V_\theta(b,L')-\lambda W(L'),
     \qquad
     \underset{L'\in\mathfrak L(S_\theta^{\mathrm{elig}})}
       {\operatorname{argmax}}\;
       J_{\theta,\lambda}(b,L').
   \]

4. Conditional replacement after an outer-certified candidate \(c\) is
   presented:
   \[
     \underset{D\subseteq L\setminus\{s_0\}}{\operatorname{argmax}}\;
       V_\theta\bigl(b,(L\setminus D)\cup\{c\}\bigr)
     \quad\text{subject to}\quad
     W\bigl((L\setminus D)\cup\{c\}\bigr)\le B.
   \]
   This is a static outer review conditional on retaining \(c\), not a raw
   transition or an implicit accept/reject problem.

When \(\theta\) and the initial state are fixed, the abbreviated convention is
\[
  J_\lambda=V-\lambda W.
\]
Safe-feasibility constraints may be added to the second or third problem only
when stated explicitly. The default capacity and penalty problems allow the
optimizer to trade productive value against resource use.

The existing compressed state \(K_L=(F_L,C_L)\) remains sufficient for the
productive dynamics. It is not sufficient for the net retention objective:
libraries with the same \(K_L\) may have different \(W(L)\) and therefore
different \(J_\lambda\). The outer optimizer must retain the raw library or
the augmented summary
\[
  K_L^W=(F_L,C_L,W(L)).
\]
This augmentation does not make \(W\) an input to the raw transition.

## 8. Effect on existing theorems

All currently registered Lean-verified statements remain unchanged because
they are statements about the productive raw process and its
frontier--closure projection:

- F0, R0, T1, UDI, and the current T2 retain their frontier, closure,
  admission, transition, equivalence, and value-factorization statements;
- the current T3 deletion and rechecked-trace theorem retains its exact
  productive-safety boundary, while terminal irreducibility additionally
  requires a complete fixed-point procedure;
- the current T4 normalized pruning-loss theorem is unchanged;
- the current T5 decomposition, T6 joint descendant bound, CS1 comparative
  statics, T7 interaction theorem, and unified Bellman results continue to use
  productive value before resource penalty; and
- supporting F1--F8 and S4--S7 remain unchanged within their recorded
  interfaces.

Two qualifications are essential. First, productive dynamic innovation
equivalence does not imply equality of \(J_\lambda\) unless the two libraries
also have equal resource burden. Second, T3 does not become a
minimum-resource theorem: deleting an active strategy strictly lowers \(W\),
but an arbitrary rechecked trace guarantees only safety. A complete
fixed-point trace is locally inclusion-wise irreducible, not globally
minimum-resource. `LOCAL_VS_GLOBAL_COMPRESSION_SPEC.md` fixes this
distinction and leaves its strict weighted witness behind an exact-search
gate.

The resource layer therefore creates new optimizer, capacity, price-envelope,
and switching targets; it does not retroactively strengthen, weaken, or
reinterpret an existing theorem.
