# Exact Elasticities for the Canonical Bridge Margin

## Status and scope

This specification records Lean-verified supporting result BEM, the
differentiable comparative statics of the exact canonical bridge quantity
from T4. It is a
real-parameter extension of the
exact rational identity
$$
  \beta^d\rho^d\pi C-\kappa.
$$
It does not change the Lean statement or status of T4, and it is not a new
resource-optimization theorem. The formulas below are ordinary point
elasticities on a named smooth path with all primitives other than the named
coordinate held fixed. The positive integer duration $d$ is fixed when a
partial derivative is taken.

The canonical T4 parameter domain permits zero primitive values and a weakly
nonnegative opportunity. Ordinary elasticity needs the stricter interior
domain
$$
  d\in\mathbb N_{\ge 1},\qquad
  0<\beta<1,\qquad
  0<\rho\le1,\qquad
  0<\pi\le1,\qquad
  C>0,\qquad
  \kappa\ge0.
$$
Define gross attainable descendant value, signed innovation margin, and
realized pruning loss by
$$
  A:=\beta^d\rho^d\pi C,
  \qquad
  M:=A-\kappa,
  \qquad
  L:=[M]_+:=\max\{M,0\}.
$$
On the strict action region $M>0$, the canonical T4 Bellman envelope selects
research, so $L=M$. The elasticity results in this specification are
restricted to that region.

## Point-elasticity derivation

For $x\in\{\beta,\rho,\pi,C,\kappa\}$, define
$$
  \varepsilon_x^M
  :=\frac{x}{M}\frac{\partial M}{\partial x},
  \qquad M>0.
$$
All unmentioned primitives, including $d$, are held fixed. Direct
differentiation gives
$$
\begin{aligned}
  \frac{\partial M}{\partial\beta}
    &=d\beta^{d-1}\rho^d\pi C=\frac{dA}{\beta},
  &
  \frac{\partial M}{\partial\rho}
    &=d\beta^d\rho^{d-1}\pi C=\frac{dA}{\rho},\\
  \frac{\partial M}{\partial\pi}
    &=\beta^d\rho^d C=\frac{A}{\pi},
  &
  \frac{\partial M}{\partial C}
    &=\beta^d\rho^d\pi=\frac{A}{C},\\
  \frac{\partial M}{\partial\kappa}
    &=-1.
\end{aligned}
$$
Therefore
$$
  \boxed{
  \varepsilon_\beta^M=\frac{dA}{M},\qquad
  \varepsilon_\rho^M=\frac{dA}{M},\qquad
  \varepsilon_\pi^M=\frac{A}{M},\qquad
  \varepsilon_C^M=\frac{A}{M},\qquad
  \varepsilon_\kappa^M=-\frac{\kappa}{M}.}
$$

These identities are exact on the declared real extension. At rational
parameter points they describe the derivative of that extension; they should
not be confused with an exact finite difference on the rational grid.

## Normalized margin and fragility

Define the normalized innovation margin
$$
  m:=\frac{M}{A}=1-\frac{\kappa}{A}.
$$
Because $M>0$ and $\kappa\ge0$,
$$
  0<m\le1,
  \qquad
  \frac{A}{M}=\frac1m,
  \qquad
  \frac{\kappa}{M}=\frac{1-m}{m}.
$$
Substitution yields
$$
  \boxed{
  \varepsilon_\beta^M=\varepsilon_\rho^M=\frac d m,
  \qquad
  \varepsilon_\pi^M=\varepsilon_C^M=\frac1m,
  \qquad
  \varepsilon_\kappa^M=-\frac{1-m}{m}.}
$$

No starred elasticity is needed: the $d/m$ and $1/m$ expressions are the
same ordinary elasticities after rewriting them in terms of $m$, not a
second normalization.

The canonical **innovation-margin fragility** is
$$
  \boxed{\mathcal F_M:=\frac1m=\frac A M},
  \qquad M>0.
$$
Outside this specification, the notation registry uses the decorated symbol
$\mathcal F_{\mathrm{br}}$.
It is dimensionless, invariant to a common positive rescaling of $A$ and
$\kappa$, and has the direct amplification interpretation
$$
  \varepsilon_\beta^M=\varepsilon_\rho^M=d\mathcal F_M,
  \qquad
  \varepsilon_\pi^M=\varepsilon_C^M=\mathcal F_M,
  \qquad
  \varepsilon_\kappa^M=1-\mathcal F_M.
$$
Thus $\mathcal F_M\ge1$. It measures fragility of the positive bridge margin,
not the distinct retained-library or research-action switching fragility
reserved for a set-valued optimizer correspondence.

## Exact consequences and boundaries

### 1. Divergence at the positive action boundary

The correct scale-free boundary condition is
$$
  m=\frac M A\downarrow0,
$$
not $M\downarrow0$ without qualification. Along any sequence in the strict
action region with fixed $d\ge1$ and $m_n\downarrow0$,
$$
\begin{aligned}
  \lvert\varepsilon_{\beta,n}^M\rvert
    &=\lvert\varepsilon_{\rho,n}^M\rvert=\frac d{m_n}\longrightarrow\infty,\\
  \lvert\varepsilon_{\pi,n}^M\rvert
    &=\lvert\varepsilon_{C,n}^M\rvert=\frac1{m_n}\longrightarrow\infty,\\
  \lvert\varepsilon_{\kappa,n}^M\rvert
    &=\frac{1-m_n}{m_n}=\frac1{m_n}-1\longrightarrow\infty.
\end{aligned}
$$
In particular, $M_n\downarrow0$ implies this divergence whenever the gross
scale is bounded away from zero: if $A_n\ge \underline A>0$, then
$0<m_n=M_n/A_n\le M_n/\underline A\to0$.

The unqualified statement “elasticities diverge as $M\downarrow0$” is
false. For example, set $\kappa=0$ and let $C\downarrow0$ with
$(\beta,\rho,\pi,d)$ fixed. Then $M=A\downarrow0$, but $m=1$ and the
elasticities remain at their gross-value benchmarks. This family is registered
as CX-BEM-VANISHING-GROSS-SCALE-01. Together with the divergent fixed-gross-
scale family CX-OPT-ELASTICITY-ZERO-MARGIN-01, it identifies the normalized
margin, rather than the net level alone, as the exact boundary variable.

### 2. Zero-cost benchmark

If $\kappa=0$, then $M=A>0$, $m=1$, and $\mathcal F_M=1$. Hence
$$
  \boxed{
  \varepsilon_\beta^M=\varepsilon_\rho^M=d,
  \qquad
  \varepsilon_\pi^M=\varepsilon_C^M=1,
  \qquad
  \varepsilon_\kappa^M=0.}
$$
These are exactly the Cobb--Douglas elasticities of the gross opportunity
$A$. Positive cost does not change the primitive exponents; it magnifies
their effect on the smaller net margin by the factor $\mathcal F_M=A/M$.
For the zero-valued cost coordinate, the displayed level-form definition gives
$\varepsilon_\kappa^M=0$; a log--log interpretation with respect to
$\kappa$ itself is unavailable at $\kappa=0$.

### 3. Duration amplification

At a common normalized margin $m$, duration enters the discount and survival
elasticities multiplicatively:
$$
  \frac{\varepsilon_\beta^M}{\varepsilon_\pi^M}
  =\frac{\varepsilon_\rho^M}{\varepsilon_C^M}=d.
$$
A one-percent local change in either $\beta$ or $\rho$ therefore has $d$
times the percentage effect on $M$ of the same local percentage change in
either $\pi$ or $C$, when evaluated at the same positive-margin point.
The direct source is the $d$-fold exposure in $\beta^d\rho^d$.

There is also a within-construction cross-duration comparison. Hold
$(\beta,\rho,\pi,C,\kappa)$ fixed and write
$$
  A_d=\pi C(\beta\rho)^d,
  \qquad
  m_d=1-\frac{\kappa}{A_d}.
$$
For two positive integers $d_2>d_1$ such that both margins remain positive,
$0<\beta\rho<1$ gives $A_{d_2}<A_{d_1}$. If $\kappa>0$, then
$m_{d_2}<m_{d_1}$ and $\mathcal F_{M,d_2}>\mathcal F_{M,d_1}$; if
$\kappa=0$, both fragility factors equal one. In either case,
$$
  d_2\mathcal F_{M,d_2}>d_1\mathcal F_{M,d_1}.
$$
Thus longer feasible duration raises the canonical discount and survival
elasticities through the exponent $d$, and positive cost adds boundary
amplification by shrinking $m_d$. This is a comparison across integer
durations, not a derivative with respect to $d$, and it does not assert an
unconditional duration sign for the general dynamic model.

### 4. The zero-margin point

At $M=0$, the ordinary elasticity
$$
  \frac{x}{M}\frac{\partial M}{\partial x}
$$
is undefined because its denominator is zero. Equivalently, the log-derivative
interpretation $\partial\log M/\partial\log x$ is unavailable. The signed
margin $M=A-\kappa$ remains smooth in the continuous primitives, but the
realized pruning loss $L=[M]_+$ has an action-boundary kink. A finite or
infinite limiting value along one path does not define an elasticity at the
boundary itself.

### 5. Nonpositive margins

For $A>0$, define the cost-to-gross threshold ratio and signed normalized
margin by
$$
  \tau:=\frac\kappa A,
  \qquad
  g:=\frac M A=1-\tau.
$$
They classify the canonical action regions without dividing by the net
margin:

| Region | Equivalent condition | Canonical implication |
|---|---:|---|
| strict research region | $M>0$, $\tau<1$, or $g>0$ | $L=M$; ordinary elasticity is admissible |
| action boundary | $M=0$, $\tau=1$, or $g=0$ | research and Continue tie; ordinary elasticity is undefined |
| no-research region | $M<0$, $\tau>1$, or $g<0$ | the envelope selects Continue and $L=0$ |

Although the algebraic ratio $(x/M)(\partial M/\partial x)$ can be evaluated
for the signed latent margin when $M<0$, it is not a percentage elasticity
of positive pruning loss: the realized loss is zero, and signs can be driven
only by the negative denominator. At and below the boundary, report the
signed level margin $M$, the threshold ratio $\tau$, exact level changes,
and whether a perturbation crosses the action region.

For exact rational computations, the coordinatewise level changes are
available without a real derivative:
$$
\begin{aligned}
  \Delta_\beta M
    &=\rho^d\pi C\bigl((\beta')^d-\beta^d\bigr),&
  \Delta_\rho M
    &=\beta^d\pi C\bigl((\rho')^d-\rho^d\bigr),\\
  \Delta_\pi M
    &=\beta^d\rho^d C(\pi'-\pi),&
  \Delta_C M
    &=\beta^d\rho^d\pi(C'-C),\\
  \Delta_\kappa M
    &=-(\kappa'-\kappa).
\end{aligned}
$$
These exact finite changes, together with the sign of the endpoint margins,
are the preferred rational-layer report whenever $M\le0$, an endpoint has
zero margin, or a perturbation crosses the action boundary.

## Verified form and evidence boundary

`formal/StrategyInnovation/Compression/BridgeMarginElasticity.lean` defines
the real gross exposure, signed margin, and realized positive-part loss. It
uses mathlib `HasDerivAt` to verify all five named-coordinate margin
derivatives and, under a strictly positive margin, the corresponding realized
loss derivatives. It proves the displayed elasticity identities, the inverse
normalized-margin formula, the right-neighborhood limit
`Tendsto (fun m => m⁻¹) (nhdsWithin 0 (Set.Ioi 0)) atTop`, its fixed-positive-
gross specialization, the direct fixed-positive-threshold limit
`Tendsto (fun M => -κ / M) (nhdsWithin 0 (Set.Ioi 0)) atBot`, and the costless
vanishing-gross boundary. The exact
`(d,β,ρ,π,C,κ)=(2,1/2,1,1,8,1)` example is kernel checked.

`formal/StrategyInnovation/Audit/Elasticity.lean` records `#print axioms` for
every manuscript-facing BEM declaration; each reports exactly
`[propext, Classical.choice, Quot.sound]`. No Julia validation or empirical
interpretation is added. Any manuscript use must preserve the strict
positive-margin domain for realized-loss derivatives and ordinary
elasticities, the named one-coordinate perturbation, the held-fixed
primitives, and the distinction between $M\downarrow0$ and
$M/A\downarrow0$.
