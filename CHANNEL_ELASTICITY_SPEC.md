# Channel Elasticities for Operational and Generative Value

## Status and scope

This specification records Lean-verified result CED, the channel-elasticity
decomposition that extends the current T5 operational--generative value
identity. It supplies the real-parameter algebraic core of planned
optimization T8.

The existing Lean theorem proves, for the unified raw process at fixed exact
parameters,
\[
  \mathcal I_h(s\mid b,L)
  =
  \Delta_h^{\mathrm{op}}(s\mid b,L)
  +
  \Delta_h^{\mathrm{gen}}(s\mid b,L).
\]
CED considers a separately declared real scalar path through those exact
objects. It does not attribute derivatives to the existing rational Lean
definitions, and it does not change T5's verified status.

The contribution identity is more general than the familiar weighted-average
formula. A component may be zero or negative even when total insertion value
is positive. In that case the component's ordinary log elasticity is not an
admissible object, but its derivative contribution to total elasticity remains
well defined.

## Named scalar path

Let \(U\subset\mathbb R_{>0}\) be an open interval and let \(x_0\in U\).
Fix the horizon, belief, base library, inserted strategy, and every primitive
not named by \(x\). Along one declared path \(x\mapsto\mathfrak p(x)\), define
the real-valued functions
\[
\begin{aligned}
  I(x)&:=\mathcal I_h(s\mid b,L;\mathfrak p(x)),\\
  O(x)&:=\Delta_h^{\mathrm{op}}(s\mid b,L;\mathfrak p(x)),\\
  G(x)&:=\Delta_h^{\mathrm{gen}}(s\mid b,L;\mathfrak p(x)).
\end{aligned}
\]
Inside this specification, \(O=\Delta^{\mathrm{op}}\) and
\(G=\Delta^{\mathrm{gen}}\). Assume that the T5 accounting identity holds
pointwise on a neighborhood of \(x_0\):
\[
  I(x)=O(x)+G(x).
\]
Assume also that all three functions are differentiable at \(x_0\). Primes
below denote derivatives along this same path, evaluated at \(x_0\).

The path requirement is substantive. A derivative in which \(\beta\) changes
the discount factor in one channel but also changes a belief kernel in the
other channel is not the partial derivative that holds the kernel fixed.
Every elasticity report must state what changes and what is held fixed.

## The channel-elasticity theorem

### Scaled level identity

Differentiating the pointwise T5 identity gives
\[
  I'(x_0)=O'(x_0)+G'(x_0).
\]
Because \(x_0>0\), multiplication by the common parameter level gives
\[
  \boxed{
  x_0 I'(x_0)
  =
  x_0 O'(x_0)
  +
  x_0 G'(x_0).}
\]
This identity requires differentiability but no sign condition on any value.
It is the safest statement when total value is zero.

### Positive-channel weighted average

Suppose
\[
  I(x_0)>0,
  \qquad O(x_0)>0,
  \qquad G(x_0)>0.
\]
Define the ordinary point elasticities
\[
  \varepsilon_x^I
  :=\frac{x_0I'(x_0)}{I(x_0)},
  \qquad
  \varepsilon_x^{\mathrm{op}}
  :=\frac{x_0O'(x_0)}{O(x_0)},
  \qquad
  \varepsilon_x^{\mathrm{gen}}
  :=\frac{x_0G'(x_0)}{G(x_0)}.
\]
Division of the scaled level identity by \(I(x_0)\), followed by multiplication
and division of each term by its own positive channel level, yields
\[
  \boxed{
  \varepsilon_x^I
  =
  \frac{O}{I}\varepsilon_x^{\mathrm{op}}
  +
  \frac{G}{I}\varepsilon_x^{\mathrm{gen}}.}
\]
Here and below undated levels are evaluated at \(x_0\). Since
\[
  \frac OI>0,
  \qquad
  \frac GI>0,
  \qquad
  \frac OI+\frac GI=1,
\]
this is a genuine convex weighted average of the two channel elasticities.

### Contribution form

Suppose only that \(I(x_0)>0\). Define the normalized elasticity
contributions
\[
  \boxed{
  C_x^{\mathrm{op}}
  :=\frac{x_0}{I(x_0)}O'(x_0),
  \qquad
  C_x^{\mathrm{gen}}
  :=\frac{x_0}{I(x_0)}G'(x_0).}
\]
Then
\[
  \boxed{
  \varepsilon_x^I
  =C_x^{\mathrm{op}}+C_x^{\mathrm{gen}}.}
\]
This remains valid when either component level is zero or negative. It divides
only by the positive total value, not by a component.

If a positive component elasticity exists, its contribution has the equivalent
share-times-elasticity form
\[
  C_x^{\mathrm{op}}
  =\frac OI\varepsilon_x^{\mathrm{op}},
  \qquad
  C_x^{\mathrm{gen}}
  =\frac GI\varepsilon_x^{\mathrm{gen}}.
\]
At a zero component level, the corresponding ordinary elasticity is undefined
and the expression \(0\times\text{undefined}\) must not replace the direct
derivative definition. At a negative component level, \(xO'/O\) or \(xG'/G\)
may exist as an algebraic signed ratio, but it is not a real log elasticity and
the associated level shares are not convex weights.

The contributions are channel attributions of total percentage sensitivity.
They are not required to be positive, lie in \([0,1]\), or have the same sign
as the channel levels.

## Parameter-specific interpretations

Every interpretation below uses the same two comparison libraries and the
same named path in all three value functions.

### Discount factor \(\beta\)

Take \(x=\beta\in(0,1)\), holding the belief kernel, generation and admission
laws, project costs and durations, rewards, and libraries fixed.

- \(C_\beta^{\mathrm{op}}\) is the part of total insertion-value sensitivity
  generated by reweighting the frozen-library frontier gains across dates.
- \(C_\beta^{\mathrm{gen}}\) is the part generated by reweighting the
  insertion-induced change in research-option value, including operating
  rewards during research and completion continuation.

In a fixed passive-gap representation
\[
  O(\beta)=\sum_{t=0}^{H-1}\beta^t z_t^{\mathrm{op}},
  \qquad z_t^{\mathrm{op}}\ge0,
\]
the scaled operational sensitivity is
\[
  \beta O'(\beta)
  =\sum_{t=0}^{H-1}t\beta^t z_t^{\mathrm{op}}.
\]
When \(O>0\), its channel elasticity is the timing centroid from IDCV. The
general generative component need not admit a fixed nonnegative exposure
sequence, so no universal duration formula or sign is inferred for it.

### Generation survival \(\rho\)

Take \(x=\rho>0\) along a declared survival family. On the canonical
innovation-only path, \(\rho\) changes only project completion or descendant
mass and does not enter frozen-library passive value. Then
\[
  O'(\rho)=0,
  \qquad
  C_\rho^{\mathrm{op}}=0,
  \qquad
  \varepsilon_\rho^I=C_\rho^{\mathrm{gen}}.
\]
The generative contribution measures how survival changes the value of
descendant access relative to the comparator library. In the one-descendant
product bridge it includes the familiar \(d\)-fold exposure to \(\rho^d\).
In the general T1 joint completion law, omitted outcomes, operating rewards,
and policy switching preclude an unconditional sign unless the required
dominance assumptions are stated.

If the same symbol \(\rho\) also changes the passive belief kernel or operating
survival, the operational derivative is not zero; that is a different path and
must be reported as such.

### Admission probability \(\pi\)

Take \(x=\pi>0\) along an admission-only real extension, holding generation,
rewards, costs, and passive dynamics fixed. Frozen passive value does not use
admission, so
\[
  C_\pi^{\mathrm{op}}=0,
  \qquad
  \varepsilon_\pi^I=C_\pi^{\mathrm{gen}}.
\]
The contribution records the percentage sensitivity of total insertion value
that operates through admitted candidate outcomes. The canonical linear-mass
bridge has unit gross admission exposure, but the optimized general value can
be locally flat when the affected project is not selected and can kink when
the selected action changes. At the probability boundary \(\pi=1\), use a
one-sided derivative or a separately declared open real extension.

### Research cost \(\kappa\)

Take \(x=\kappa>0\) and vary a named initiation-cost coordinate. Because the
frozen passive problem contains no research action,
\[
  C_\kappa^{\mathrm{op}}=0,
  \qquad
  \varepsilon_\kappa^I=C_\kappa^{\mathrm{gen}}.
\]
If \(\kappa\) prices only a project newly available after insertion and leaves
the comparator unchanged, the generative contribution is nonpositive wherever
the optimized value is differentiable: it is negative while the project is
used with positive marginal exposure and zero while the project is locally
irrelevant. If a common cost coordinate changes research menus on both sides
of the insertion comparison, the difference of their responses has no
unconditional sign.

At \(\kappa=0\), a log--cost elasticity is unavailable because the parameter
is not positive. The scaled contribution formula can still be evaluated as a
level-normalized derivative, but its factor \(\kappa\) makes that particular
point contribution zero.

### Frontier scale

Let \(x=f>0\) multiply a named set of operating profiles, with the affected
set stated explicitly. Under the common-scale convention in which every
profile entering the two frozen passive problems is multiplied by \(f\) while
the kernel and discount are fixed, passive homogeneity gives
\[
  O(f)=fO(1).
\]
Thus, when \(O>0\),
\[
  \varepsilon_f^{\mathrm{op}}=1,
  \qquad
  C_f^{\mathrm{op}}=\frac OI.
\]
The generative contribution records the remaining response of the difference
in research premia. It may be positive when research-period operation or
descendant rewards scale with the frontier, or negative when a stronger
incumbent frontier raises the opportunity cost of research. Scaling only the
inserted strategy, only incumbents, or only descendant rewards defines a
different frontier path and need not have the unit operational elasticity.

Frontier scale is a payoff coordinate. Closure cardinality is neither a
continuous sufficient state nor an admissible substitute for this path.

### Belief-kernel persistence

Let \(x=\chi>0\) index a differentiable row-stochastic family \(P_\chi\), with
rewards, libraries, and all other primitives fixed. On a fixed passive-gap
path,
\[
  O(\chi)
  =\sum_{t=0}^{H-1}\beta^t(P_\chi^t g)(b),
\]
so
\[
  O'(\chi)
  =
  \sum_{t=1}^{H-1}\beta^t
  \sum_{k=0}^{t-1}
  \bigl(P_\chi^kP_\chi'P_\chi^{t-1-k}g\bigr)(b).
\]
Consequently \(C_\chi^{\mathrm{op}}\) is the total-value-normalized response
of discounted occupation of operational insertion gaps. The generative
contribution is the corresponding response of relative research-option value,
including persistence effects on research-period occupation and terminal
completion value.

There is no universal persistence sign. Existing S7 results show that a
persistence change can raise, lower, or leave value unchanged depending on
gap alignment. CED allocates a path-specific derivative across channels; it
does not turn persistence into a scalar monotonicity theorem.

## Exact finite examples

The following examples are exact scalar paths. They validate the algebraic
possibilities and do not claim that every path has been instantiated as a
unified T1 process in Lean.

### 1. Operational value dominates levels; generative value dominates sensitivity

For \(x>0\), let
\[
  O(x)=100+x,
  \qquad
  G(x)=1+10x,
  \qquad
  I(x)=101+11x.
\]
At \(x=1\),
\[
  O=101>11=G,
\]
so the operational channel dominates the level. But
\[
  xO'=1<10=xG',
\]
so the generative channel dominates sensitivity. The exact elasticities and
contributions are
\[
\begin{aligned}
  \varepsilon_x^{\mathrm{op}}&=\frac1{101},&
  C_x^{\mathrm{op}}&=\frac1{112},\\
  \varepsilon_x^{\mathrm{gen}}&=\frac{10}{11},&
  C_x^{\mathrm{gen}}&=\frac{10}{112},\\
  \varepsilon_x^I&=\frac{11}{112}
  &=C_x^{\mathrm{op}}+C_x^{\mathrm{gen}}.
\end{aligned}
\]

### 2. Small total elasticity from offsetting channel sensitivities

For \(x\) in a neighborhood of one, let
\[
  O(x)=10+4x,
  \qquad
  G(x)=10-3x,
  \qquad
  I(x)=20+x.
\]
At \(x=1\), the positive levels are \(O=14\), \(G=7\), and \(I=21\), while
\[
  C_x^{\mathrm{op}}=\frac4{21},
  \qquad
  C_x^{\mathrm{gen}}=-\frac3{21},
  \qquad
  \varepsilon_x^I=\frac1{21}.
\]
Equivalently,
\[
  \frac{14}{21}\left(\frac4{14}\right)
  +
  \frac7{21}\left(-\frac3{7}\right)
  =
  \frac1{21}.
\]
The small total elasticity does not mean that either channel is insensitive;
it is the residual of opposing channel responses.

### 3. Zero operational level with positive generative sensitivity

Let
\[
  O(x)=0,
  \qquad
  G(x)=x,
  \qquad
  I(x)=x.
\]
At \(x=1\), operational value is exactly zero and its ordinary elasticity is
undefined. Nevertheless,
\[
  C_x^{\mathrm{op}}=0,
  \qquad
  C_x^{\mathrm{gen}}=1,
  \qquad
  \varepsilon_x^I=1.
\]
This is the differentiable channel pattern represented at the level by T5's
exact operationally silent, generatively valuable carrier witness.

Zero level does not in general imply zero contribution. For example,
\(O(x)=x-1\) has \(O(1)=0\) but \(O'(1)=1\); the direct contribution formula,
not a component elasticity, captures such a crossing.

## Exact validity conditions

The convex weighted-average elasticity formula is valid at \(x_0\) when all
of the following hold:

1. \(x_0>0\).
2. One named scalar path is used for \(I\), \(O\), and \(G\), with the same
   held-fixed primitives.
3. The exhaustive T5 identity \(I(x)=O(x)+G(x)\) holds on a neighborhood of
   \(x_0\), not merely after evaluating unrelated calibrations at one point.
4. All three channel functions are differentiable at \(x_0\).
5. \(I(x_0)>0\), \(O(x_0)>0\), and \(G(x_0)>0\), so all three ordinary log
   elasticities exist and the two level shares are positive and sum to one.

Strict positivity at the point is enough for the local algebra. A positive
denominator floor is additionally required for uniform bounds, stable
comparisons over a region, or limit claims.

If only \(I(x_0)>0\), the contribution identity remains valid under conditions
1--4 even when a component is zero or negative. If \(I(x_0)=0\), total
elasticity and both normalized contributions are undefined; report the scaled
level identity \(x_0I'=x_0O'+x_0G'\), action regions, or exact finite changes.
If \(I(x_0)<0\), \(x_0I'/I\) is an algebraic signed sensitivity rather than the
ordinary log elasticity of positive innovation value.

Optimized Bellman values are maxima of action branches. At a policy switch,
the level identity still holds but a two-sided derivative may fail to exist.
When one-sided derivatives exist, the scaled identity and contribution
decomposition hold separately on each side. Otherwise use exact finite or arc
changes and report the action switch.

## Verified form and evidence boundary

`formal/StrategyInnovation/Value/ChannelElasticity.lean` represents the
accounting identity as an eventual equality on a real neighborhood. From
verified `HasDerivAt` hypotheses it proves exact derivative additivity, the
scaled derivative decomposition, and the total-normalized signed contribution
identity. The latter algebra needs no sign assumption; ordinary percentage
interpretation still requires a nonzero total level, and the manuscript uses
it only at positive total value. The share-weighted component-elasticity
formula is separately proved under strictly positive operational and
generative levels, with positive shares summing to one.

The three affine examples at \(x=1\) are exact Lean calculations, including
their ordinary derivatives where used. All manuscript-facing declarations
are registered in `formal/StrategyInnovation/Audit/Elasticity.lean` and
report exactly `[propext, Classical.choice, Quot.sound]`. The module does not
identify an arbitrary real path with the rational T5 model automatically;
that application must provide the neighborhood accounting identity and the
named derivatives. Parameter-specific economic interpretations remain
corollaries conditional on such a path. No reusable Julia implementation or
empirical claim is added.
