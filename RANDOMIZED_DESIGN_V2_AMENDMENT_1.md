# Randomized-library v2 amendment 1: sequential stability diagnostics

## Status and parent lock

This is a prospective, pre-outcome amendment to
`randomized-finite-library-stress-v2`. It adds sequential simulation-precision
diagnostics and does not alter the raw-library generator, four-corner
construction, factor assignments, seed registry, primary estimands, or fixed
final sample.

The preserved parent design is:

- parent lock file:
  `experiments/randomized_library_v2/DESIGN_LOCK.json`;
- parent lock file SHA-256:
  `3ad48c4c1fc7965705a41cfc1d9dd8b73414d0aca57f5f68d5afb7d79d2be63d`;
- parent aggregate design SHA-256:
  `0b012dfc14f4ea57b0d34877a68d9a546cd499d2270903e772d78b21425d14db`;
  and
- fixed registered maximum:
  \(N_{\max}=1024\).

No v2 outcome was read before this amendment. The final \(N\) was not chosen
after seeing an interaction sign, loss frequency, mean, or plot.

## Fixed cumulative schedule

The sequential diagnostic checkpoints are:

\[
\mathcal N_{\mathrm{seq}}
=\{50,100,200,300,500,750,1000,1024\}.
\]

The first seven values are the requested checkpoints and 1,024 is the
registered maximum. Every main v2 estimate uses all 1,024 trials. A prefix is
never a stopping boundary, sample-size choice, exclusion rule, or permission
to report a favorable sign early.

The parent design's exactly balanced checkpoints
\(\{256,512,768,1024\}\) remain available as separate balance diagnostics.
The new early prefixes need not be exactly factor-balanced. Every cumulative
and factor-stratified table therefore reports its actual denominator.

Rows are accumulated in the locked `TRIAL_REGISTRY.csv` `trial_id` order.
Changing that order, any prefix, or the maximum requires a new prospective
amendment.

## Cumulative estimands

At each \(n\in\mathcal N_{\mathrm{seq}}\), let \(T_n=\{1,\ldots,n\}\).
The following values are reported.

### Frequencies

Positive frontier-only dynamic loss:

\[
\widehat p_{F,n}
=\frac{\#\{t\in T_n:\Delta^V_{F,t}>0\}}{n}.
\]

Innovation-safe dynamic loss:

\[
\widehat p_{\mathrm{safe},n}
=\frac{\#\{t\in T_n:\Delta^V_{\mathrm{safe},t}>0\}}{n}.
\]

Operationally silent generative assets:

\[
\widehat p_{\mathrm{silent},n}
=\frac{\sum_{t\in T_n} A^{\mathrm{silent}}_t}
       {\sum_{t\in T_n} A^{\mathrm{active}}_t}.
\]

Because every v2 rectangle is required to pass the raw four-corner gate,
interaction denominators are the cumulative trial count:

\[
\widehat p_{\mathrm{sub},n}
=\frac{\#\{t\in T_n:J_t<0\}}{n},
\qquad
\widehat p_{\mathrm{comp},n}
=\frac{\#\{t\in T_n:J_t>0\}}{n}.
\]

Every frequency row contains its exact event count, nonevent count,
denominator, and reduced rational estimate.

### Conditional mean positive loss

Let \(E_n=\{t\in T_n:\Delta^V_{F,t}>0\}\). When \(E_n\ne\varnothing\),

\[
\widehat\mu^+_n
=\frac{1}{|E_n|}\sum_{t\in E_n}\Delta^V_{F,t}.
\]

The row records \(|E_n|\), \(n-|E_n|\), the exact rational loss sum, the exact
rational mean, and the exact sample variance supporting its MCSE. If
\(|E_n|=0\), the mean is undefined rather than reported as zero.

### Mean compression ratios

For frontier-only and innovation-safe pruning, let \(R_{m,t}\) be the exact
removed/source library-size ratio. Report

\[
\widehat R_{m,n}=\frac1n\sum_{t\in T_n}R_{m,t}
\]

with exact supporting count, exact sum, exact mean, and exact sample variance.

## Descriptive frequency intervals

For each nonempty frequency denominator, report the two-sided 95% Wilson score
interval using fixed

\[
z=1.959963984540054.
\]

The interval is a decimal display transform of exact counts. It describes
finite-simulation precision under the registered generator. It is not a
confidence interval for a real economic population, is not theorem evidence,
and cannot determine stopping or the final sample.

No binomial interval is attached to a mean.

## Monte Carlo standard errors for means

For a mean supported by exact observations \(x_1,\ldots,x_m\), compute the
exact rational sample variance

\[
s^2=\frac{1}{m-1}\sum_{i=1}^m(x_i-\bar x)^2
\]

when \(m\ge2\), then display

\[
\operatorname{MCSE}(\bar x)=\sqrt{s^2/m}.
\]

The sum, mean, and sample variance are exact. Only the final square root is
converted to `Float64` for presentation. MCSEs are reported for the
conditional positive-loss mean and both mean compression ratios. They are
simulation diagnostics, not real-population standard errors.

## Factor-stratified diagnostics

At every sequential checkpoint, repeat all eight estimands separately for
both levels of each registered principal factor:

1. frontier density;
2. module overlap;
3. module complementarity;
4. project cost;
5. duration;
6. admission; and
7. persistence.

This produces exact level-specific counts, denominators, estimates, Wilson
intervals where applicable, MCSEs for means, and warnings. Early slices use
their realized registry counts. No early-prefix balance is claimed, and no
factor contrast is interpreted causally.

## Sparse-event warnings

Warnings are deterministic annotations:

- `sparse_events` when a frequency numerator is below 20;
- `sparse_nonevents` when its complement is below 20;
- `sparse_mean_support` when a mean has fewer than its registered support
  threshold;
- `undefined_empty_mean` when the positive-loss mean has no positive event;
  and
- `empty_denominator` for any empty factor slice.

The conditional positive-loss mean uses a minimum support threshold of 40.
The two compression means require at least two observations for an MCSE.

Warnings never change a numerator, denominator, estimate, interval, prefix,
trial, factor allocation, or final \(N\). Sparse results remain visible.

## Stabilization figure

The dependency-free SVG contains four panels:

1. positive frontier-only and innovation-safe loss frequencies;
2. conditional mean positive frontier-only loss;
3. silent-generative-asset, substitution, and complementarity frequencies;
   and
4. frontier-only and innovation-safe mean compression ratios.

All fixed checkpoints appear on the horizontal axis. Frequency panels show
descriptive Wilson bars. Mean panels show plus/minus one MCSE where defined.
The figure explicitly states that the final sample is fixed and that the
diagnostics are not inference about a real population.

The factor-stratified values are supplied in a complete machine-readable table
rather than overloading the main stabilization figure.

## Exactness and output contract

The Julia implementation accepts only exact rational theorem-facing loss,
interaction, and compression fields. It emits:

- cumulative rows at
  `experiments/results/summaries/randomized_library_v2_stability_summary.csv`;
- factor-stratified rows at
  `experiments/results/summaries/randomized_library_v2_stability_factor_summary.csv`;
  and
- the stabilization plot at
  `manuscript/figures/randomized_library_v2_stability.svg`.

Every output row carries `simulation_precision_only=true`. No v2 outcome file
is generated as part of this amendment or its tests.

## Lock and amendment rule

The amendment lock hashes the preserved parent lock, this document, the
amendment TOML, the Julia diagnostic implementation and integration, the lock
utility, and the tests. At amendment-lock time all parent v2 output paths and
the added factor-stability path must be absent.

Any change to the checkpoint set, interval convention, MCSE definition,
warning threshold, factor slices, plot panels, final \(N\), or output paths
requires another prospective amendment before outcomes.
