# Discrete Capacity and Resource-Demand Elasticity

## Status and purpose

This specification records proposed supporting result CPEL. It extends the
finite capacity theorem CAP and the penalized affine-envelope theorem PEN with
normalized finite-change measures. It does not replace either parent result.

The deterministic retention problem is discrete. Its capacity value is a
right-continuous step function, and its optimal resource demand in price is a
set-valued step correspondence at switching thresholds. Ordinary derivative
elasticity is therefore generally the wrong object. The primary reports here
are exact forward, base-normalized arc elasticities on a declared increment.

The word **arc** below follows the requested base-value convention. It is not
the symmetric midpoint arc elasticity in the internal archived
switching-elasticity note, which is omitted from the public release export.

## 1. Fixed finite resource problems

Fix a nonempty finite capacity-independent and price-independent library
family \(\mathcal F\). For every \(L\in\mathcal F\), let
\[
  v_L:=V_\theta(b,L)\in\mathbb Q,
  \qquad
  w_L:=W(L)\in\mathbb Q_{\ge0}.
\]
For the capacity problem, assume that \(\mathcal F\) contains a zero-burden
library so that every \(B\ge0\) is feasible.

Define
\[
\begin{aligned}
  V^\star(B)
  &:={\max}_{L\in\mathcal F:\,w_L\le B}v_L,\\
  J^\star(\lambda)
  &:={\max}_{L\in\mathcal F}\{v_L-\lambda w_L\},\\
  \operatorname{Opt}_\lambda
  &:={\arg\max}_{L\in\mathcal F}\{v_L-\lambda w_L\}.
\end{aligned}
\]
CAP proves at the human level that \(V^\star\) is a nondecreasing
right-continuous finite step function. PEN proves at the human level that the
penalized envelope is continuous, convex, and piecewise affine and that
optimal burden is weakly nonincreasing in \(\lambda\).

All finite-difference claims below are exact over rational inputs. Real
arguments are used only for the canonical step and affine extensions already
declared in CAP and PEN.

## 2. Capacity shadow values and capacity elasticity

Fix a declared increment \(\delta>0\). The **capacity shadow value** is the
exact level gain
\[
  \boxed{
  \Delta_B^\delta V^\star
  :=
  V^\star(B+\delta)-V^\star(B).}
\]
Its per-unit form is
\[
  s_B^\delta
  :=
  \frac{\Delta_B^\delta V^\star}{\delta}.
\]
Feasible-set nesting gives
\[
  \Delta_B^\delta V^\star\ge0,
  \qquad
  s_B^\delta\ge0.
\]
Neither object is a derivative or automatically a Lagrange multiplier. A
large \(\delta\) can aggregate several distinct capacity jumps.

When
\[
  B>0,
  \qquad
  V^\star(B)>0,
\]
define the **forward capacity arc elasticity**
\[
  \boxed{
  \varepsilon_{B,\delta}^{V^\star}
  :=
  \frac{V^\star(B+\delta)-V^\star(B)}{V^\star(B)}
  \frac{B}{\delta}
  =
  \frac{B}{V^\star(B)}s_B^\delta.}
  \tag{CE}
\]
When \(\delta\) has been fixed by the declared grid or experiment, abbreviate
this as the requested \(\varepsilon_B^{V^\star}\). The explicit subscript is
retained in proofs because different increments generally give different
elasticities.

It is the percentage value gain relative to the base value divided by the
percentage capacity increase relative to the base capacity. Consequently,
\[
  \varepsilon_{B,\delta}^{V^\star}\ge0.
\]

Although formula (CE) algebraically returns zero at \(B=0\), an ordinary
percentage increase from zero capacity is not defined. At \(B=0\), report
\(\Delta_0^\delta V^\star\) or \(s_0^\delta\), not an elasticity. Likewise,
if \(V^\star(B)\le0\), use the exact level shadow rather than an ordinary
percentage elasticity.

## 3. Breakpoint representation and zero regions

Let \(\mathcal B_C\) be CAP's strict capacity-value breakpoint set and define
the jump at \(\omega\in\mathcal B_C\) by
\[
  d(\omega)
  :=
  V^\star(\omega)-V^\star(\omega^-)>0.
\]
The finite step representation gives
\[
  \boxed{
  \Delta_B^\delta V^\star
  =
  \sum_{\omega\in\mathcal B_C\cap(B,B+\delta]}d(\omega).}
  \tag{J}
\]
Therefore, whenever the elasticity denominator is admissible,
\[
  \boxed{
  \varepsilon_{B,\delta}^{V^\star}
  =
  \frac{B}{\delta V^\star(B)}
  \sum_{\omega\in\mathcal B_C\cap(B,B+\delta]}d(\omega).}
  \tag{JE}
\]

### Proposition 1 — Zero capacity elasticity on a stable step

If the entire interval \([B,B+\delta]\) remains in one capacity-value step,
then
\[
  \Delta_B^\delta V^\star=0,
  \qquad
  \varepsilon_{B,\delta}^{V^\star}=0
\]
whenever the latter is defined.

In particular, an unchanged optimal library is sufficient for zero capacity
elasticity because productive values do not depend on capacity in the fixed
problem. The converse need not hold: the optimizer correspondence may gain or
switch among tied libraries without a strict value gain. Such an optimizer-
only threshold is not a member of \(\mathcal B_C\) and creates no capacity-
value elasticity spike.

#### Proof

No strict value breakpoint in \((B,B+\delta]\) makes the sum in (J) empty.
Equivalently, the same step value occurs at both endpoints. Substitution in
(CE) gives zero. \(\square\)

## 4. Elasticity spikes at capacity breakpoints

### Proposition 2 — Exact spike formula

Let \(\omega>0\) be a strict capacity-value breakpoint with
\[
  v_-:=V^\star(\omega^-)>0,
  \qquad
  d:=d(\omega)>0.
\]
Choose \(\eta>0\) small enough that there is no other value breakpoint in
\((\omega-\eta,\omega)\), and put
\[
  B=\omega-\eta,
  \qquad
  \delta=\eta.
\]
Then the forward arc lands exactly on the breakpoint and
\[
  \boxed{
  \varepsilon_{\omega-\eta,\eta}^{V^\star}
  =
  \frac{d}{v_-}\frac{\omega-\eta}{\eta}.}
  \tag{spike}
\]
Consequently,
\[
  \varepsilon_{\omega-\eta,\eta}^{V^\star}
  \longrightarrow +\infty
  \qquad
  \text{as }\eta\downarrow0.
\]

#### Proof

Right-continuity and isolation of the finite breakpoint set give
\[
  V^\star(\omega-\eta)=v_-,
  \qquad
  V^\star(\omega)=v_-+d.
\]
Substituting these two exact levels into (CE) proves (spike). Because
\(d/v_->0\), \(\omega>0\), and \((\omega-\eta)/\eta\to+\infty\), the limit
follows. \(\square\)

This divergence is a shrinking-arc consequence of a level jump, not an
ordinary derivative elasticity. On a fixed discrete grid the spike is finite
and occurs at the grid point immediately before a breakpoint that the next
increment reaches. Evaluating a forward arc from \(B=\omega\) may instead
give zero, because the jump at \(\omega\) is already included in the base
value. For fixed \(\delta\), the forward statistic as a function of its base
can change when a breakpoint enters the window at \(B=\omega-\delta\) and
when it leaves at \(B=\omega\).

Thus the exact reporting unit is the ordered pair \((B,\delta)\), not the
breakpoint alone.

## 5. Increasing marginal capacity value under module complementarity

Capacity monotonicity does not imply diminishing discrete shadows. Consider
two unit-burden carriers \(s_1,s_2\) of distinct modules \(m_1,m_2\). A
productive opportunity requires both modules jointly. Add a positive
capacity-independent baseline value one so that ordinary elasticity is
defined before the opportunity becomes feasible:
\[
\begin{array}{c|c|c}
  \text{active carriers}&W&V\\
  \hline
  \varnothing&0&1\\
  \{s_1\}&1&1\\
  \{s_2\}&1&1\\
  \{s_1,s_2\}&2&2
\end{array}
\]
Then
\[
  V^\star(B)
  =
  \begin{cases}
    1,&0\le B<2,\\
    2,&B\ge2.
  \end{cases}
\]
For the unit grid,
\[
  \Delta_0^1V^\star=0,
  \qquad
  \Delta_1^1V^\star=1,
\]
so the second capacity unit is strictly more valuable than the first. At the
positive base \(B=1\),
\[
  \boxed{
  \varepsilon_{1,1}^{V^\star}
  =
  \frac{2-1}{1}\frac11
  =1.}
\]
Inside either flat region, an increment that does not cross two has zero
elasticity. For example,
\[
  \varepsilon_{1/2,1/4}^{V^\star}=0.
\]
A narrower arc that lands on the breakpoint produces the predicted larger
spike:
\[
  \varepsilon_{3/2,1/2}^{V^\star}
  =
  \frac{2-1}{1}\frac{3/2}{1/2}
  =3.
\]

This is the positive-baseline companion to registered fixture
CX-OPT-CAPACITY-INCREASING-RETURNS-01. The registered fixture has profile
\((0,0,1)\) and validates the same complementarity mechanism, but its zero
pre-breakpoint value correctly prevents ordinary percentage elasticity.

## 6. Optimal resource demand under a price

Because the penalized optimizer may be tied, define the **optimal burden
correspondence**
\[
  \boxed{
  \mathcal W^\star(\lambda)
  :=
  \{W(L):L\in\operatorname{Opt}_\lambda\}.}
\]
When this set is a singleton, write its unique element as
\(W^\star(\lambda)\). Raw-library uniqueness is sufficient but not necessary:
several optimal libraries can share one burden and therefore induce a
single-valued resource demand.

For
\[
  \lambda>0,
  \qquad
  \delta>0,
  \qquad
  W^\star(\lambda)>0,
\]
and singleton burden correspondences at both endpoints, define the **forward
resource-demand arc elasticity**
\[
  \boxed{
  \varepsilon_{\lambda,\delta}^{W^\star}
  :=
  \frac{W^\star(\lambda+\delta)-W^\star(\lambda)}
       {W^\star(\lambda)}
  \frac{\lambda}{\delta}.}
  \tag{RE}
\]
When the price increment is fixed, abbreviate this as the requested
\(\varepsilon_\lambda^{W^\star}\).

PEN's all-optimizer-pairs burden order implies
\[
  W^\star(\lambda+\delta)
  \le
  W^\star(\lambda),
\]
so every defined forward resource-demand elasticity satisfies
\[
  \boxed{
  \varepsilon_{\lambda,\delta}^{W^\star}\le0.}
\]
It is strictly negative exactly when the two endpoint demands differ.

At \(\lambda=0\), an ordinary percentage price change is not defined. If
\(W^\star(\lambda)=0\), the demand denominator vanishes. In either case,
report the exact burden change rather than an elasticity.

### Proposition 3 — Zero price elasticity on a stable optimizer cell

If the same library is optimal at both endpoints and throughout
\([\lambda,\lambda+\delta]\), its burden is fixed, so
\[
  \varepsilon_{\lambda,\delta}^{W^\star}=0
\]
whenever the denominator conditions hold. More generally, the result remains
zero if optimal raw-library identity changes but the unique optimal burden
does not.

This is a finite-arc statement. The pointwise demand schedule is constant on
open affine cells of \(J^\star\), so its ordinary derivative is zero there,
while the schedule can jump at a price breakpoint.

## 7. Price breakpoints, one-sided demand, and ties

At an interior PEN breakpoint \(\lambda_0>0\), define
\[
\begin{aligned}
  W^-(\lambda_0)
  &:={\max}\,\mathcal W^\star(\lambda_0),\\
  W^+(\lambda_0)
  &:={\min}\,\mathcal W^\star(\lambda_0).
\end{aligned}
\]
These are the burdens on the adjacent left and right optimal faces. PEN gives
\[
  W^+(\lambda_0)\le W^-(\lambda_0)
\]
and relates them to the one-sided envelope slopes:
\[
  (J^\star)'_-(\lambda_0)=-W^-(\lambda_0),
  \qquad
  (J^\star)'_+(\lambda_0)=-W^+(\lambda_0).
\]
Thus the resource-demand drop is the slope kink of the penalized value
envelope.

If
\[
  W^-(\lambda_0)>W^+(\lambda_0),
\]
then \(\mathcal W^\star(\lambda_0)\) is not a singleton. The point statistic
in (RE) is therefore undefined at the threshold unless a tie-breaking rule
is added. A cross-breakpoint arc with unique endpoint demands is well defined.
If \(\lambda_-<\lambda_0<\lambda_+\), no other demand switch lies between the
endpoints, the left/base demand is positive, and both endpoint demands are
unique, then
\[
  \boxed{
  \varepsilon_{[\lambda_-,\lambda_+]}^{W^\star,\mathrm{fwd}}
  =
  \frac{W^+(\lambda_0)-W^-(\lambda_0)}{W^-(\lambda_0)}
  \frac{\lambda_-}{\lambda_+-\lambda_-}
  <0.}
\]

As an interval slides across a switching threshold, the forward demand
elasticity changes from zero, to a negative cross-switch value, and back to
zero. At the exact unequal-burden tie it is set-valued or undefined. This is
the relevant discontinuity; no ordinary smooth elasticity exists there.

An equal-burden raw-library tie is different. Then
\(\mathcal W^\star(\lambda_0)\) can remain a singleton, the penalized envelope
has no burden-induced kink, and resource-demand elasticity need not be
undefined.

## 8. Exact resource-price examples

Use the burden-value pairs
\[
\begin{array}{c|cc}
  &v_L&w_L\\
  \hline
  L_H&3&2\\
  L_L&2&1\\
  L_0&0&0
\end{array}
\]
with branches
\[
  J_H(\lambda)=3-2\lambda,
  \qquad
  J_L(\lambda)=2-\lambda,
  \qquad
  J_0(\lambda)=0.
\]
The optimal demand is
\[
  \mathcal W^\star(\lambda)
  =
  \begin{cases}
    \{2\},&0<\lambda<1,\\
    \{1,2\},&\lambda=1,\\
    \{1\},&1<\lambda<2,\\
    \{0,1\},&\lambda=2,\\
    \{0\},&\lambda>2.
  \end{cases}
\]

### 8.1 Zero elasticity

Take \(\lambda=1/4\) and \(\delta=1/2\). Both endpoints lie in the
high-burden cell, so
\[
  \boxed{
  \varepsilon_{1/4,1/2}^{W^\star}
  =
  \frac{2-2}{2}\frac{1/4}{1/2}
  =0.}
\]

### 8.2 Negative cross-breakpoint elasticity

Take \(\lambda=3/4\) and \(\delta=1/2\). The arc straddles the breakpoint at
one, and both endpoints have unique positive demand:
\[
  \boxed{
  \varepsilon_{3/4,1/2}^{W^\star}
  =
  \frac{1-2}{2}\frac{3/4}{1/2}
  =-\frac34.}
\]
This is the precise finite-difference meaning of negative resource-price
elasticity “at” a switching breakpoint.

### 8.3 Undefined elasticity at the tie

At \(\lambda_0=1\), both \(L_H\) and \(L_L\) are optimal and
\[
  \mathcal W^\star(1)=\{1,2\}.
\]
There is no single \(W^\star(1)\). With \(\delta=1/2\), selecting burden two
at the tied base would produce
\[
  \frac{1-2}{2}\frac{1}{1/2}=-1,
\]
while selecting burden one would produce zero. Because the answer depends on
an unstated tie breaker, the resource-demand elasticity at the threshold is
undefined. The correct reports are the correspondence \(\{1,2\}\), the
one-sided burdens \((W^-,W^+)=(2,1)\), and a cross-breakpoint arc such as the
one in Section 8.2.

These rational branches are the active portion of registered fixture
CX-OPT-PENALIZED-INCLUSION-SWITCH-01. The example therefore reuses existing
exact price-switch evidence and adds only the normalized finite-change
calculation.

## 9. Exact fixture reporting protocol

For a capacity-elasticity fixture:

1. declare rational \(B>0\) and \(\delta>0\);
2. enumerate the complete feasible and optimal library sets at both
   endpoints;
3. record \(V^\star(B)\), \(V^\star(B+\delta)\), and
   \(\Delta_B^\delta V^\star\);
4. identify every strict value breakpoint in \((B,B+\delta]\);
5. verify the jump-sum identity (J); and
6. report elasticity only when \(V^\star(B)>0\).

For a price-demand fixture:

1. declare rational \(\lambda>0\) and \(\delta>0\);
2. enumerate complete optimizer sets and burden correspondences at the two
   endpoints and every crossed candidate threshold;
3. verify global activity rather than relying on a pairwise crossing alone;
4. report zero elasticity when endpoint demand is unchanged;
5. report a nonpositive exact arc when both endpoint burdens are unique and
   the base burden is positive; and
6. report the burden correspondence and one-sided burdens, not a scalar
   elasticity, at an unequal-burden tie.

All divisions should remain exact rational operations. Floating-point output
is validation convenience, not proof.

## 10. Assumption and claim boundaries

The results require:

1. the fixed finite library family and exact values and burdens of CAP and
   PEN;
2. nonnegative burdens and a zero-burden feasible library for the capacity
   problem;
3. a declared positive finite increment;
4. positive base capacity and base value for capacity elasticity;
5. positive base price, positive base demand, and singleton endpoint burden
   correspondences for resource-demand elasticity; and
6. actual globally active breakpoints rather than unfiltered pairwise
   intersections.

The results do not imply:

- differentiability of the capacity step function;
- an ordinary point elasticity at a capacity-value jump;
- that every optimizer-only capacity threshold creates a value spike;
- diminishing marginal capacity value;
- that a capacity shadow is a continuous Lagrange multiplier;
- a scalar resource demand at an unequal-burden price tie;
- a defined demand elasticity when optimal burden is zero;
- raw-library inclusion nesting as price rises; or
- equivalence of hard-capacity and penalized optimizers.

## 11. Proof and evidence boundary

The formulas and propositions above are complete human deductions from the
finite CAP and PEN statements under their declared assumptions. The capacity
example is a direct exact rational positive-baseline companion to the
registered module-complementarity fixture. The price examples reuse the
active branches of a registered exact penalized-switch fixture.

CPEL has no matching Lean declaration or axiom audit. CAP and PEN remain
human-proved proposed results, and their existing Julia fixtures remain
implementation validation only. No reusable Julia capacity-elasticity API,
new generated fixture, empirical claim, or active-manuscript insertion is
added.
