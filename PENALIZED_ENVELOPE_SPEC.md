# Exact Penalized-Optimization Envelope Specification

## Verdict and status

The ten requested conclusions are valid for a fixed nonempty finite feasible
family, finite productive values, and nonnegative resource burdens. The
strongest monotonicity statement is set-valued: if
\(\lambda_1<\lambda_2\), every optimizer at \(\lambda_2\) has weakly lower
burden than every optimizer at \(\lambda_1\). Raw library inclusion does not
obey the corresponding order.

This document gives the complete human proof of theorem PEN, the planned
optimization T6. The updated PEN ledger entry now records a building,
axiom-audited Lean core: finite maximum and optimizer existence, continuity,
convexity, nonincrease, finite pairwise switching candidates, local affine
slopes under strict dominance and outside the candidate set, all-optimizer
burden order, and an antitone selected burden. The global affine-cell
partition, exact active-kink classification/count, active-face one-sided
slopes/subdifferential, and raw nonnesting counterexample remain human/Julia
claims rather than Lean-verified clauses.

## 1. Exact finite setting

Fix a belief \(b\), productive parameter bundle \(\theta\), and a nonempty
finite feasible family
\[
  \mathcal F\subseteq
  \mathfrak L(S_\theta^{\mathrm{elig}}).
\]
For the primary penalized-retention problem,
\[
  \mathcal F=\mathfrak L(S_\theta^{\mathrm{elig}}).
\]
The theorem also applies to a separately named restricted or hybrid problem
provided that \(\mathcal F\) is fixed independently of \(\lambda\).

For each \(L\in\mathcal F\), write
\[
  v_L:=V_\theta(b,L)\in\mathbb Q,
  \qquad
  w_L:=W(L)\in\mathbb Q_{\ge0}.
\]
The primary exact optimization problem evaluates rational prices. To state
continuity and derivatives without ambiguity, embed \(v_L,w_L\) in
\(\mathbb R\) and define the canonical real-price extension
\[
  J_L(\lambda):=v_L-\lambda w_L,
  \qquad \lambda\in\mathbb R_{\ge0}.
\]
At every rational price this agrees exactly with the rational problem.
Because the inputs are rational, every finite pairwise switching price and
every envelope slope is rational even though the argument \(\lambda\) is
allowed to be real.

Define
\[
  J^\star(\lambda)
  :=
  \max_{L\in\mathcal F}J_L(\lambda)
\]
and the nonempty optimizer correspondence
\[
  \operatorname{Opt}_\lambda
  :=
  \{L\in\mathcal F:J_L(\lambda)=J^\star(\lambda)\}.
\]
No tie breaker or uniqueness assumption is part of the definition.

The proof uses no sign restriction on \(v_L\), no monotonicity of productive
value under raw inclusion, no frontier or closure order, and no additivity of
productive value. Nonnegativity of \(w_L\) is required only for the
nonincrease conclusion. The current additive positive-strategy resource model
implies \(w_L\ge0\).

## 2. Switching prices and breakpoint definitions

For two libraries \(L_1,L_2\), put
\[
  \Delta v_{12}:=v_{L_1}-v_{L_2},
  \qquad
  \Delta w_{12}:=w_{L_1}-w_{L_2}.
\]
Their branch difference is
\[
  J_{L_1}(\lambda)-J_{L_2}(\lambda)
  =
  \Delta v_{12}-\lambda\Delta w_{12}.
\]
When \(\Delta w_{12}\ne0\), define the pairwise switching price
\[
  \boxed{
  \lambda_{12}
  =
  \frac{v_{L_1}-v_{L_2}}
       {w_{L_1}-w_{L_2}}.}
\]
This is a candidate switching price. It is an economically admissible
candidate only when \(\lambda_{12}\ge0\), and it is an actual envelope
breakpoint only when both branches are globally optimal there and their
burdens differ.

Let
\[
  \mathcal S
  :=
  \left\{
    \lambda_{12}\ge0:
    L_1,L_2\in\mathcal F,
    w_{L_1}\ne w_{L_2}
  \right\}
\]
be the finite candidate-price set. Define the set of interior envelope
breakpoints by
\[
  \mathcal B
  :=
  \left\{
    \lambda_0\in(0,\infty):
    J^\star\text{ is not affine on any open neighborhood of }\lambda_0
  \right\}.
\]
Equivalently,
\[
  \lambda_0\in\mathcal B
  \iff
  \exists L_1,L_2\in\operatorname{Opt}_{\lambda_0}
  \text{ with }w_{L_1}\ne w_{L_2}.
\]
Thus \(\mathcal B\subseteq\mathcal S\). A tie at \(\lambda=0\) is a boundary
switch of the optimizer correspondence, not automatically an interior
breakpoint of the value function.

## 3. The penalized-envelope theorem

### Theorem PEN — Finite penalized affine envelope

Under the setting above, for every \(\lambda\ge0\):

1. **Finite value.**
   \[
     J^\star(\lambda)\in\mathbb R.
   \]

2. **Continuity.** \(J^\star\) is continuous on
   \(\mathbb R_{\ge0}\).

3. **Monotonicity.** \(J^\star\) is nonincreasing:
   \[
     0\le\lambda_1\le\lambda_2
     \Longrightarrow
     J^\star(\lambda_2)\le J^\star(\lambda_1).
   \]

4. **Convexity.** For \(\lambda_1,\lambda_2\ge0\) and
   \(t\in[0,1]\),
   \[
     J^\star(t\lambda_1+(1-t)\lambda_2)
     \le
     tJ^\star(\lambda_1)+(1-t)J^\star(\lambda_2).
   \]

5. **Piecewise affinity.** The nonnegative price axis has a finite partition
   into points, bounded open intervals, and one final open ray on each of
   which \(J^\star\) agrees with one affine branch
   \(v_L-\lambda w_L\).

6. **Finitely many breakpoints.**
   \[
     \mathcal B\subseteq\mathcal S,
     \qquad
     |\mathcal B|<\infty.
   \]
   If \(r\) is the number of distinct pairs \((w_L,v_L)\), then
   \[
     |\mathcal B|\le {r\choose2}.
   \]

7. **Derivative under a unique optimizer.** If the optimizer is unique at
   an interior price \(\lambda\), it remains the unique optimizer on some
   neighborhood of \(\lambda\), and
   \[
     \boxed{
     \frac{dJ^\star(\lambda)}{d\lambda}
     =
     -W(L^\star(\lambda)).}
   \]
   In particular, if a fixed \(L^\star\) is the unique optimizer throughout
   an open interval \(I\subset(0,\infty)\), then
   \[
     J^\star(\lambda)=v_{L^\star}-\lambda w_{L^\star},
     \qquad
     (J^\star)'(\lambda)=-w_{L^\star}
     \quad(\lambda\in I).
   \]

8. **Breakpoint slopes and adjacent optimal faces.** At an interior price
   \(\lambda_0>0\), define
   \[
   \begin{aligned}
     w^-(\lambda_0)
       &:=\max\{w_L:L\in\operatorname{Opt}_{\lambda_0}\},\\
     w^+(\lambda_0)
       &:=\min\{w_L:L\in\operatorname{Opt}_{\lambda_0}\}.
   \end{aligned}
   \]
   Then the one-sided derivatives exist and satisfy
   \[
     \boxed{
     (J^\star)'_-(\lambda_0)=-w^-(\lambda_0),
     \qquad
     (J^\star)'_+(\lambda_0)=-w^+(\lambda_0).}
   \]
   The adjacent left and right optimal faces are
   \[
   \begin{aligned}
     \mathcal F^-(\lambda_0)
       &:=
       \{L\in\operatorname{Opt}_{\lambda_0}:w_L=w^-(\lambda_0)\},\\
     \mathcal F^+(\lambda_0)
       &:=
       \{L\in\operatorname{Opt}_{\lambda_0}:w_L=w^+(\lambda_0)\}.
   \end{aligned}
   \]
   For a sufficiently small \(\varepsilon>0\), these are exactly the
   optimizer faces immediately to the left and right of \(\lambda_0\).
   Moreover,
   \[
     \partial J^\star(\lambda_0)
     =
     [-w^-(\lambda_0),-w^+(\lambda_0)]
     =
     \operatorname{conv}
     \{-w_L:L\in\operatorname{Opt}_{\lambda_0}\}.
   \]
   A genuine kink occurs exactly when
   \(w^-(\lambda_0)>w^+(\lambda_0)\).

   At the boundary \(\lambda_0=0\), only the within-domain right derivative
   is asserted:
   \[
     (J^\star)'_+(0)
     =
     -\min\{w_L:L\in\operatorname{Opt}_0\}.
   \]

9. **Antitone optimal burden.** For
   \(0\le\lambda_1<\lambda_2\), every pair
   \[
     L_1\in\operatorname{Opt}_{\lambda_1},
     \qquad
     L_2\in\operatorname{Opt}_{\lambda_2}
   \]
   satisfies
   \[
     \boxed{W(L_2)\le W(L_1).}
   \]
   Hence a selection of optimal libraries with weakly nonincreasing burden
   exists. In fact, every selection from the optimizer correspondence has
   weakly nonincreasing burden.

10. **No raw-inclusion order.** There need not exist a selection satisfying
    either
    \[
      L^\star(\lambda_2)\subseteq L^\star(\lambda_1)
      \quad\text{or}\quad
      L^\star(\lambda_1)\subseteq L^\star(\lambda_2)
    \]
    whenever \(\lambda_1<\lambda_2\). Only the scalar burden order in part 9
    is unconditional.

## 4. Proof

### Parts 1 and optimizer existence

The feasible family is nonempty and finite. Each \(J_L(\lambda)\) is a finite
real number. A finite nonempty set of finite real numbers has a finite
maximum, which is attained. Therefore \(J^\star(\lambda)\) is finite and
\(\operatorname{Opt}_\lambda\ne\varnothing\).

### Part 2

Every branch \(J_L(\lambda)=v_L-\lambda w_L\) is continuous. The pointwise
maximum of finitely many continuous functions is continuous. Hence
\(J^\star\) is continuous, including right-continuity at zero.

### Part 3

For \(\lambda_1\le\lambda_2\) and every \(L\),
\[
  J_L(\lambda_2)
  =
  v_L-\lambda_2w_L
  \le
  v_L-\lambda_1w_L
  =
  J_L(\lambda_1),
\]
because \(w_L\ge0\). Maximizing the left and right sides over the same fixed
family gives
\[
  J^\star(\lambda_2)\le J^\star(\lambda_1).
\]

### Part 4

Let \(\lambda_t=t\lambda_1+(1-t)\lambda_2\). Affinity of every branch gives
\[
\begin{aligned}
  J^\star(\lambda_t)
  &=
  \max_L
  \{tJ_L(\lambda_1)+(1-t)J_L(\lambda_2)\}\\
  &\le
  t\max_LJ_L(\lambda_1)
  +(1-t)\max_LJ_L(\lambda_2)\\
  &=
  tJ^\star(\lambda_1)+(1-t)J^\star(\lambda_2).
\end{aligned}
\]
Thus the upper envelope is convex.

### Parts 5 and 6

First consolidate libraries with the same pair \((w_L,v_L)\): they define
one affine branch but retain all raw-library identities in the optimizer
correspondence. Two distinct consolidated branches with unequal slopes
intersect at most once, at their pairwise switching price. Distinct branches
with equal slopes never intersect.

Remove the finite candidate set \(\mathcal S\) from
\(\mathbb R_{\ge0}\). On each remaining connected interval, no pairwise
ordering can change. The same consolidated branch therefore attains the
upper envelope throughout that interval, so \(J^\star\) is affine there.
Continuity supplies the values at the endpoints, and there is one final
affine ray after the largest candidate price. This proves piecewise affinity.

Any interior failure of local affinity must occur where two globally active
branches with distinct slopes intersect. Therefore
\(\mathcal B\subseteq\mathcal S\). There are at most
\({r\choose2}\) pairwise intersections among \(r\) consolidated branches, so
the breakpoint set is finite.

### Part 7

At a price with a unique optimizer, every competing library has a strictly
lower objective. Because there are finitely many competitors and every
objective difference is continuous, the minimum strict gap remains positive
on some neighborhood. The same library is uniquely optimal throughout that
neighborhood. There,
\[
  J^\star(\lambda)=v_{L^\star}-\lambda w_{L^\star},
\]
and differentiation gives
\[
  (J^\star)'(\lambda)=-w_{L^\star}.
\]

### Part 8

Fix an interior price \(\lambda_0\) and let
\(\mathcal A=\operatorname{Opt}_{\lambda_0}\). A nonactive branch has a
strictly negative gap at \(\lambda_0\). Finiteness and continuity give a
neighborhood in which no nonactive branch reaches the envelope. Thus the
local envelope is the maximum of the branches in \(\mathcal A\).

For \(h>0\), every active branch changes from its common value at
\(\lambda_0\) by \(-hw_L\). Immediately to the right, the largest change is
generated by the least burden:
\[
  (J^\star)'_+(\lambda_0)
  =
  \max_{L\in\mathcal A}(-w_L)
  =
  -\min_{L\in\mathcal A}w_L.
\]
Immediately to the left, the largest gain is generated by the greatest
burden:
\[
  (J^\star)'_-(\lambda_0)
  =
  \min_{L\in\mathcal A}(-w_L)
  =
  -\max_{L\in\mathcal A}w_L.
\]
Libraries attaining the two burden extremes form the adjacent faces. All
members of one such face have the same burden and, because they tie at
\(\lambda_0\), the same value; their affine branches coincide. The
subdifferential formula follows from the standard one-dimensional convex
identity
\[
  \partial J^\star(\lambda_0)
  =
  [(J^\star)'_-(\lambda_0),(J^\star)'_+(\lambda_0)].
\]
The same right-direction argument at zero gives the boundary formula.

### Part 9

Let \(\lambda_1<\lambda_2\), and choose arbitrary
\(L_i\in\operatorname{Opt}_{\lambda_i}\). Optimality at the two prices gives
\[
\begin{aligned}
  v_{L_1}-\lambda_1w_{L_1}
    &\ge v_{L_2}-\lambda_1w_{L_2},\\
  v_{L_2}-\lambda_2w_{L_2}
    &\ge v_{L_1}-\lambda_2w_{L_1}.
\end{aligned}
\]
Adding and rearranging yields
\[
  (\lambda_2-\lambda_1)(w_{L_1}-w_{L_2})\ge0.
\]
Since \(\lambda_2-\lambda_1>0\),
\[
  w_{L_2}\le w_{L_1}.
\]
The libraries were arbitrary optimizers, so the order holds for every
optimizer pair. Fixing any total order on the finite family and selecting its
least optimizer at each price gives a selection; the pairwise result makes
its burden weakly nonincreasing. The same reasoning shows that any other
selection has the same burden monotonicity.

### Part 10

Use the registered exact instance
CX-OPT-PENALIZED-INCLUSION-SWITCH-01. It has active strategies
\(s_1,s_2\), weights
\[
  w_{s_1}=1,\qquad w_{s_2}=2,
\]
and productive values by active mask
\[
  V(\varnothing)=0,\quad
  V(\{s_1\})=2,\quad
  V(\{s_2\})=3,\quad
  V(\{s_1,s_2\})=3.
\]
At \(\lambda=1/4\), the unique optimizer is \(\{s_2\}\), with burden two.
At \(\lambda=5/4\), the unique optimizer is \(\{s_1\}\), with burden one.
The higher-price burden is lower, as part 9 requires, but the two raw
libraries are incomparable under inclusion. No choice of tie breaker repairs
the failure because both optimizers are unique. This proves part 10.

## 5. Complete switching-price case analysis

### Unequal burdens

If \(\Delta w_{12}>0\), then
\[
  J_{L_1}(\lambda)-J_{L_2}(\lambda)
  =
  \Delta w_{12}(\lambda_{12}-\lambda).
\]
Thus \(L_1\) beats \(L_2\) below \(\lambda_{12}\), they tie at it, and
\(L_2\) beats \(L_1\) above it. If \(\Delta w_{12}<0\), the inequalities
reverse. A negative \(\lambda_{12}\) lies outside the resource-price domain,
so the pairwise order cannot switch for \(\lambda\ge0\).

### Equal burdens

If \(w_{L_1}=w_{L_2}\), no switching-price quotient is defined. The branches
are parallel:

- if \(v_{L_1}>v_{L_2}\), \(L_1\) strictly dominates \(L_2\) at every price;
- if \(v_{L_1}<v_{L_2}\), \(L_2\) strictly dominates \(L_1\); and
- if \(v_{L_1}=v_{L_2}\), the branches coincide at every price.

In the last case, raw-distinct libraries remain tied at every price for which
their common branch lies on the envelope. Such a persistent tie is not a
breakpoint.

### Equal productive values

If \(v_{L_1}=v_{L_2}\) but \(w_{L_1}\ne w_{L_2}\), then
\[
  \lambda_{12}=0.
\]
They tie pairwise at the boundary. At every positive price, the lower-burden
library strictly beats the higher-burden library. They are both global
optimizers at zero only if their common productive value is maximal over the
entire feasible family.

### More than two tied libraries

Any number of libraries may satisfy
\[
  v_L-\lambda_0w_L=J^\star(\lambda_0)
\]
at the same price. The optimizer is then the complete exposed face
\(\operatorname{Opt}_{\lambda_0}\), not a selected pair. Libraries with
intermediate burdens may be optimal only at the breakpoint. The maximum-
burden optimal face determines the left slope; the minimum-burden optimal
face determines the right slope. All intermediate optimal slopes lie in the
subdifferential interval.

### Candidate intersections versus actual breakpoints

A pairwise switching price need not affect \(J^\star\): a third library may
lie strictly above both intersecting branches. Hence an implementation may
enumerate all \(\lambda_{12}\) as a finite candidate set, but it must test
global optimality to report actual envelope breakpoints. The current Julia
function `penalty_breakpoints` returns zero together with this candidate
superset; it must not be cited as proving that every returned price is an
envelope kink.

## 6. Zero and negative productive values

All ten conclusions are sign-free in productive value.

- If \(v_L=0\), its branch is \(-\lambda w_L\).
- If \(v_L<0\), the branch remains finite and affine.
- At \(\lambda=0\), only productive values determine optimality:
  \[
    J^\star(0)=\max_{L\in\mathcal F}v_L.
  \]
- If the inactive-only library has \(v=0,w=0\), then
  \(J^\star(\lambda)\ge0\) for every \(\lambda\ge0\). A library with negative
  productive value and nonnegative burden cannot be optimal against that
  baseline.
- If a different convention permits every feasible value to be negative, the
  maximum is still finite and attained; continuity, convexity, piecewise
  affinity, switching-price algebra, and burden antitonicity are unchanged.

The only sign used for monotonicity in price is \(w_L\ge0\). Allowing negative
resource burdens would invalidate the unconditional guarantee in part 3 and
is outside the resource model.

## 7. Exact examples and evidence boundary

The existing exact resource audit supplies:

- CX-OPT-PENALIZED-BREAKPOINT-TIE-01:
  \(J^\star(\lambda)=\max\{0,1-\lambda\}\) has two optimizers at
  \(\lambda=1\);
- CX-OPT-VALUE-KINK-01: the same instance has left slope \(-1\) and right
  slope \(0\);
- FX-OPT-PENALIZED-BURDEN-MONOTONE-01: exact exhaustive validation of the
  all-optimizer-pairs burden order on the registered bounded domain; and
- CX-OPT-PENALIZED-INCLUSION-SWITCH-01: unique optimal libraries switch
  nonnestedly while burden falls.

These fixtures validate the implementation and the sharpness of the theorem.
They do not transfer Lean status beyond the declarations listed in the PEN
ledger entry.

## 8. Verified form and remaining manuscript gate

`formal/StrategyInnovation/Optimization/PenalizedEnvelope.lean` implements the
fixed nonempty finite family, real affine branches, attained argmax,
continuity, convexity, nonincrease, switching candidate set, local affine
derivatives, and optimal-burden order. Its direct finite-breakpoint theorem
states that outside the finite candidate set the envelope agrees with an
optimal affine branch on a neighborhood. The module now also defines the
actual breakpoint set as failure of local affine representation and proves
directly that every price outside that actual set has a locally optimal branch
whose envelope derivative is exactly minus its burden.

The manuscript may state exactly that verified form. It must not yet call the
global partition, active-breakpoint equivalence/count, active-face one-sided
derivatives/subdifferential, or raw nonnesting counterexample Lean verified.
Those remaining clauses require separate declarations and axiom output.
