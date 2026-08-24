# Innovation Duration and Log-Effective-Discount Convexity

## Status and scope

This specification records the Lean-verified finite core of result IDCV, the
planned optimization T9. It gives a real-parameter formalization for one
fixed finite nonnegative exposure sequence. It is a scalar extension of the
exact finite S6
discount--survival potential, not a new claim about project delay, time to
admission, endogenous policy duration, or Bellman value under changing
primitives.

The existing S6 object is vector-valued:
\[
  \Psi_H(\beta,\rho)
  =
  \sum_{t=0}^{H-1}(\beta\rho)^tP^tg.
\]
After fixing an initial state \(b\), one may set
\[
  z_t:=(P^tg)(b)\ge0
\]
and apply the theorem below componentwise. The abstract scalar formulation
also permits any other fixed nonnegative sequence with the same timing
interpretation.

## Domain and held-fixed convention

Fix
\[
  H\in\mathbb N_{\ge1},\qquad
  \alpha\in\mathbb R_{>0},\qquad
  z_t\in\mathbb R_{\ge0}
  \quad (t=0,\ldots,H-1),
\]
where the finite sequence \(z=(z_0,\ldots,z_{H-1})\) is independent of
\(\alpha\) and is not identically zero. Define
\[
  \Psi_H(\alpha;z)
  :=
  \sum_{t=0}^{H-1}\alpha^t z_t.
\]
Positivity of \(\alpha\), nonnegativity of \(z\), and nonempty support imply
\(\Psi_H(\alpha;z)>0\). The explicit positivity assumption is retained in
statements to make every denominator and logarithm visible.

For the discount--survival interpretation, set
\[
  \alpha=\beta\rho,
  \qquad
  \beta>0,\quad \rho>0.
\]
The probability application may additionally impose
\(0<\beta<1\) and \(0<\rho\le1\), but the finite theorem requires only
positivity. When a derivative is taken, \(H\), the complete sequence \(z\),
and every primitive other than the named coordinate are held fixed.

## Normalized timing distribution

Define the date-\(t\) contribution and normalized timing weight by
\[
  a_t(\alpha):=\alpha^t z_t,
  \qquad
  \omega_t^\Psi(\alpha)
  :=
  \frac{a_t(\alpha)}{\Psi_H(\alpha;z)}
  =
  \frac{\alpha^t z_t}{\Psi_H(\alpha;z)}.
\]
Inside this specification, \(\omega_t\) abbreviates
\(\omega_t^\Psi(\alpha)\). The weights satisfy
\[
  \omega_t\ge0,
  \qquad
  \sum_{t=0}^{H-1}\omega_t=1.
\]
They therefore define an exact probability distribution on the finite timing
set \(\{0,\ldots,H-1\}\).

Define **innovation duration**
\[
  \boxed{
  D_\Psi(\alpha)
  :=
  \sum_{t=0}^{H-1}t\,\omega_t}
\]
and **innovation convexity**
\[
  \boxed{
  C_\Psi(\alpha)
  :=
  \sum_{t=0}^{H-1}
    \omega_t\bigl(t-D_\Psi(\alpha)\bigr)^2.}
\]
Thus \(D_\Psi\) is the mean date and \(C_\Psi\) is the timing variance under
the normalized contribution weights.

## Theorem

Under the declared domain and held-fixed convention:

1. The log elasticity of the scalar potential with respect to effective
   discount is innovation duration:
   \[
     \boxed{
     \frac{\partial\log\Psi_H}{\partial\log\alpha}
     =
     D_\Psi.}
   \]

2. If \(\alpha=\beta\rho\), then, holding the other primitive and \(z\)
   fixed,
   \[
     \boxed{
     \varepsilon_\beta^\Psi
     :=
     \frac{\partial\log\Psi_H}{\partial\log\beta}
     =
     D_\Psi,
     \qquad
     \varepsilon_\rho^\Psi
     :=
     \frac{\partial\log\Psi_H}{\partial\log\rho}
     =
     D_\Psi.}
   \]

3. Innovation convexity is the curvature of log potential with respect to
   log effective discount:
   \[
     \boxed{
     C_\Psi
     =
     \frac{\partial D_\Psi}{\partial\log\alpha}
     =
     \frac{\partial^2\log\Psi_H}
       {\partial(\log\alpha)^2}
     \ge0.}
   \]
   Hence \(D_\Psi\) is nondecreasing in \(\log\alpha\), and therefore in
   \(\alpha>0\).

4. Innovation duration obeys the sharp finite-horizon bounds
   \[
     \boxed{0\le D_\Psi\le H-1.}
   \]

5. The equality cases are:

   - \(D_\Psi=0\) if and only if
     \(z_0>0\) and \(z_t=0\) for every \(t\ge1\).
   - \(D_\Psi=H-1\) if and only if
     \(z_{H-1}>0\) and \(z_t=0\) for every \(t\le H-2\).
   - \(C_\Psi=0\) if and only if the positive support of \(z\) is a
     singleton. Equivalently, all uncovered-strategy value arrives at one
     date.
   - \(C_\Psi>0\) if and only if \(z_s,z_t>0\) for at least two distinct
     dates \(s\ne t\). On exactly this nondegenerate domain,
     \(D_\Psi\) is strictly increasing in \(\log\alpha\).

For \(H=1\), the two duration bounds coincide:
\(D_\Psi=0=H-1\), and \(C_\Psi=0\).

## Human derivation

Write
\[
  \theta:=\log\alpha,
  \qquad
  \widetilde\Psi_H(\theta)
  :=
  \Psi_H(e^\theta;z)
  =
  \sum_{t=0}^{H-1}e^{t\theta}z_t.
\]
Because the sum is finite,
\[
  \frac{\partial\widetilde\Psi_H}{\partial\theta}
  =
  \sum_{t=0}^{H-1}t e^{t\theta}z_t.
\]
Therefore
\[
\begin{aligned}
  \frac{\partial\log\Psi_H}{\partial\log\alpha}
  &=
  \frac{1}{\widetilde\Psi_H(\theta)}
  \frac{\partial\widetilde\Psi_H(\theta)}{\partial\theta}\\
  &=
  \sum_{t=0}^{H-1}
  t\frac{e^{t\theta}z_t}{\widetilde\Psi_H(\theta)}
  =
  \sum_{t=0}^{H-1}t\omega_t
  =
  D_\Psi.
\end{aligned}
\]
Equivalently,
\[
  D_\Psi
  =
  \frac{\alpha\Psi_H'(\alpha)}{\Psi_H(\alpha)}.
\]

When \(\alpha=\beta\rho\),
\[
  \log\alpha=\log\beta+\log\rho.
\]
Holding \(\rho\) fixed gives
\(\partial\log\alpha/\partial\log\beta=1\), and holding \(\beta\) fixed gives
\(\partial\log\alpha/\partial\log\rho=1\). The chain rule proves both
primitive-elasticity identities.

For the curvature result, differentiate one normalized timing weight:
\[
\begin{aligned}
  \frac{\partial\omega_t}{\partial\theta}
  &=
  \frac{t e^{t\theta}z_t}{\widetilde\Psi_H}
  -
  \frac{e^{t\theta}z_t}{\widetilde\Psi_H}
  \frac{1}{\widetilde\Psi_H}
  \frac{\partial\widetilde\Psi_H}{\partial\theta}\\
  &=
  (t-D_\Psi)\omega_t.
\end{aligned}
\]
It follows that
\[
\begin{aligned}
  \frac{\partial D_\Psi}{\partial\log\alpha}
  &=
  \sum_t t(t-D_\Psi)\omega_t\\
  &=
  \sum_t t^2\omega_t-D_\Psi^2\\
  &=
  \sum_t\omega_t(t-D_\Psi)^2
  =
  C_\Psi
  \ge0.
\end{aligned}
\]

The duration bounds follow because \(D_\Psi\) is a convex combination of
dates in \([0,H-1]\):
\[
  0
  =
  \sum_t0\omega_t
  \le
  \sum_t t\omega_t
  \le
  \sum_t(H-1)\omega_t
  =
  H-1.
\]
For the lower equality, every nonnegative term \(t\omega_t\) with \(t>0\)
must vanish, so all positive weight lies at date zero. Because \(\alpha>0\),
\(\omega_t>0\) exactly when \(z_t>0\). The upper equality is identical after
replacing \(t\) by \(H-1-t\).

Finally, each summand in \(C_\Psi\) is nonnegative. The sum is zero exactly
when every positive-weight date equals its mean, which is possible exactly
when positive support is concentrated at one date. This gives every stated
equality and strictness case.

## Exact rational evaluation form

At rational \(\alpha>0\) and rational \(z_t\ge0\), the levels
\(\Psi_H,D_\Psi,C_\Psi\) are exact rational numbers. With
\(a_t=\alpha^t z_t\),
\[
  D_\Psi
  =
  \frac{\sum_t t\,a_t}{\sum_t a_t},
  \qquad
  C_\Psi
  =
  \frac{\sum_t t^2a_t}{\sum_t a_t}
  -
  \left(\frac{\sum_t t\,a_t}{\sum_t a_t}\right)^2.
\]
The pairwise identity
\[
  \boxed{
  C_\Psi
  =
  \frac{1}{2\Psi_H^2}
  \sum_{s=0}^{H-1}\sum_{t=0}^{H-1}
  (s-t)^2a_sa_t}
\]
is an exact finite nonnegativity certificate. It also proves
\(C_\Psi=0\) exactly when no two distinct dates both carry positive
contribution.

The derivative interpretation belongs to the real extension, while these
finite sums and the examples below remain exact over the rational input
layer.

## Exact finite examples

Take
\[
  H=3,\qquad
  \beta=\frac23,\qquad
  \rho=\frac34,\qquad
  \alpha=\beta\rho=\frac12.
\]
All entries below are exact integers or rationals.

### Same potential level, different duration

| Exposure \(z=(z_0,z_1,z_2)\) | Contributions \(a_t=\alpha^tz_t\) | \(\Psi_3\) | Weights \(\omega\) | \(D_\Psi\) | \(C_\Psi\) |
|---|---|---:|---|---:|---:|
| \((2,0,0)\) | \((2,0,0)\) | \(2\) | \((1,0,0)\) | \(0\) | \(0\) |
| \((0,0,8)\) | \((0,0,2)\) | \(2\) | \((0,0,1)\) | \(2\) | \(0\) |

The two instances have the same evaluated potential
\(\Psi_3(1/2)=2\), but their innovation durations are the opposite sharp
bounds \(0\) and \(2\). Their discount and survival elasticities are
accordingly \(0\) and \(2\).

“Same \(\Psi\)” here means the same potential level at the declared
\(\alpha\). If two finite polynomials \(\Psi_H(\alpha;z)\) are identical for
every \(\alpha\), coefficient uniqueness forces the same \(z\), and hence the
same duration and convexity at every positive \(\alpha\).

### Same duration, different convexity

| Exposure \(z=(z_0,z_1,z_2)\) | Contributions \(a_t=\alpha^tz_t\) | \(\Psi_3\) | Weights \(\omega\) | \(D_\Psi\) | \(C_\Psi\) |
|---|---|---:|---|---:|---:|
| \((0,4,0)\) | \((0,2,0)\) | \(2\) | \((0,1,0)\) | \(1\) | \(0\) |
| \((1,0,4)\) | \((1,0,1)\) | \(2\) | \((1/2,0,1/2)\) | \(1\) | \(1\) |

Both instances have the same potential level and innovation duration. The
first concentrates all value at date one, so its timing variance is zero. The
second splits value equally between dates zero and two, so
\[
  C_\Psi
  =
  \frac12(0-1)^2+\frac12(2-1)^2
  =
  1.
\]
Thus a first-moment duration statistic does not identify timing dispersion.

## Interpretation

If \(z_t\) is undiscounted expected uncovered-strategy value at date \(t\),
then \(a_t=\alpha^tz_t\) is its discounted-and-survival-weighted contribution
to \(\Psi_H\). Normalizing these contributions turns timing into a probability
distribution:

- \(D_\Psi\) is the average date at which uncovered strategy value contributes
  to the finite potential.
- \(C_\Psi\) is the dispersion of that contribution timing, measured in
  squared periods.
- A larger \(\alpha\) tilts normalized weight toward later positive-support
  dates. The exact rate at which the mean date moves is its current timing
  variance.

Multiplying every \(z_t\) by the same positive constant changes
\(\Psi_H\) by that constant but leaves \(\omega_t,D_\Psi,C_\Psi\), and all
three log elasticities unchanged.

## Boundary discipline

- At \(\alpha=0\), \(\log\alpha\) and log elasticity are undefined. A separate
  right-limit statement may exist for a named support pattern, but it is not
  an elasticity at zero.
- If \(\Psi_H=0\), the normalized weights, duration, and convexity are
  undefined. Under \(\alpha>0\) and \(z_t\ge0\), this occurs exactly when
  every \(z_t=0\).
- If some \(z_t<0\), the normalized terms need not be probability weights,
  \(C_\Psi\) need not be a variance, and the sign result is unavailable.
- If \(z_t\) changes with \(\alpha\), \(\beta\), or \(\rho\), differentiation
  produces additional exposure-response terms. The displayed identities then
  do not apply without including those terms.
- \(D_\Psi\) is a contribution-weighted timing centroid. It is not the
  primitive project duration \(d_q\), a stopping time, expected time to first
  admission, or duration generated by an optimized policy.
- \(C_\Psi\ge0\) is convexity of \(\log\Psi_H\) in \(\log\alpha\) for fixed
  exposures. It is not a claim that Bellman value is convex in project delay,
  capacity, or a changing transition kernel.

The existing opposite-sign project-delay examples therefore remain binding.
IDCV resolves the formerly underspecified duration/convexity target only for
the fixed-exposure effective-discount channel.

## Verified form and evidence boundary

`formal/StrategyInnovation/Coverage/InnovationDuration.lean` defines the
finite real potential, its first and second timing moments, normalized
weights, duration, convexity, and the algebraic timing variance. Mathlib
derivative machinery verifies the potential and first-moment polynomial
derivatives and the duration quotient rule. Exact finite identities then prove
\(α\Psi'_H=N_1\), \(αN'_1=N_2\),
\(α\Psi'_H/\Psi_H=D_\Psi\), and
\(αD'_\Psi=C_\Psi\), with convexity equal to the normalized weighted
timing variance and nonnegative under nonnegative exposures and positive
total potential.

This is the strongest verified manuscript form. The familiar statements
using differentiation with respect to \(\log\alpha\), and the second
derivative of \(\log\Psi_H\), are chain-rule corollaries of these scaled
derivative identities, but they are not separately encoded and must not be
labeled as distinct Lean declarations. Likewise, the support equality cases,
strictness result, and endpoint duration bounds in the broader human theorem
remain outside the current Lean slice. The early, middle, late, and spread
three-date examples are kernel checked exactly.

Every manuscript-facing IDCV declaration is registered in
`formal/StrategyInnovation/Audit/Elasticity.lean` and reports exactly
`[propext, Classical.choice, Quot.sound]`. No reusable Julia implementation or
empirical interpretation is added.
