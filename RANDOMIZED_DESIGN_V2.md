# Randomized finite-library stress test, version 2

## Registration status

This document registers `randomized-finite-library-stress-v2` before any v2
outcome is generated. The fixed design has \(N=1024\) exact trials. Its
configuration is
`experiments/configs/randomized_library_stress_v2.toml`, its complete
trial/seed schedule is
`experiments/randomized_library_v2/TRIAL_REGISTRY.csv`, and its hash lock is
`experiments/randomized_library_v2/DESIGN_LOCK.json`.

The earlier \(N=90\) experiment is a frozen pilot. Its configuration, summary,
report, source tables, negative results, and mixed results remain unchanged.
The pilot is used only for disclosed feasibility and precision planning. It is
not pooled with v2 and is not part of any v2 numerator, denominator, mean,
maximum, interval, factor contrast, or stability diagnostic.

Randomized evidence remains a finite-generator robustness diagnostic. It is
not theorem evidence, an economic population model, or a prevalence estimate
for firms or technologies.

## Registered sample size

The registered main sample is

\[
N=1024=2^7\times 8.
\]

This is preferable to an arbitrary \(N=1000\): all \(2^7=128\) principal
factor cells receive exactly eight trials, and every 128-trial batch contains
one trial from every cell.

The frozen v1 \(N=90\) exact `--check` was timed three times on the current
arm64 Apple-M1 host under Julia 1.12.6. The elapsed times were 18.06, 17.21,
and 17.04 seconds, with median 17.21 seconds. Linear scaling gives

\[
17.21(1024/90)=195.81\text{ seconds}
\]

for 1,024 v1-equivalent trials. V2 additionally audits four raw corners and
their induced laws. A conservative 900-second planning allowance still makes
the fixed sample practical. That allowance is not a stopping rule: the final
run must complete all 1,024 trials or be reported incomplete. Lowering \(N\)
requires a new prospective design version and lock.

For a binomial frequency at \(N=1024\), the conservative normal-approximation
95% half-width is at most 3.063 percentage points. Each principal factor level
has 512 observations, giving a worst-case half-width of 4.331 percentage
points. At the disclosed pilot frontier-loss rate \(8/90\), the corresponding
\(N=1024\) approximation is 1.743 percentage points. Wilson intervals will be
shown for presentation, but exact rational counts and frequencies are the
authoritative outputs.

The eight observations within a full seven-factor cell provide design
balance, not adequate standalone cell inference. No cellwise significance
claim is registered.

## Factorial allocation and seed registry

The principal design is the complete binary cross of:

| Factor | Low level | High level |
|---|---|---|
| Frontier density | sparse | dense |
| Module overlap | low | high |
| Module complementarity | weak | strong |
| Project cost | \(1/2\) | \(2\) |
| Duration | 1 | 3 |
| Admission probability | \(1/4\) | \(3/4\) |
| Regime persistence | \(1/4\) | \(3/4\) |

Each of the 128 cells appears once in each of eight batches. The registered
prefixes \(N=256,512,768,1024\) are therefore exactly balanced on every
principal factor and cell. Odd batches use the intended
`primitive_eligible` construction and even batches use a registered boundary
construction. Consequently every principal cell contains four intended
eligible and four intended boundary trials, and each registered prefix is
balanced on that split.

The intended regime label is never substituted for the computed theorem-
assumption predicate. It is only a construction stratum. The outcome runner
must derive and record every assumption field from the raw process and fail if
an intended eligible row does not satisfy the predicate or a boundary row does
not violate its registered condition.

The master seed is:

```text
6075990691714899803
```

`TRIAL_REGISTRY.csv` records, before outcomes:

- execution trial and batch identifiers;
- the full seven-factor assignment;
- the intended theorem regime and boundary mechanism;
- the within-batch schedule key;
- the trial seed;
- the catalog/profile seed;
- the project/law seed; and
- the deletion-order seed.

All are derived by the locked Julia design script using domain-separated
SplitMix64 calls. Seeds passed to `StableRNG` are masked to nonnegative
`Int64`. No other random stream is permitted. Adding or replacing a seed
requires a new design lock before outcomes.

Within each 128-trial batch, cells are executed in ascending registered
schedule-key order. This prevents an interrupted prefix from following
lexicographic factor order. Only the prespecified 256-trial prefixes enter
stability reporting.

## Raw-library generator

### Shared primitives

Every trial creates one three-belief catalog and one seven-module closure
system. The catalog has exactly eight strategies:

1. the required inactive strategy;
2. three active base strategies;
3. one frontier addition;
4. one closure carrier; and
5. two possible descendant strategies.

The base library \(L_{00}\) contains the inactive strategy and the three base
strategies. The two descendants are catalog members but are absent from every
initial corner. The full sampled source library is \(L_{11}\), which contains
six strategies including inactive.

All profile entries, probabilities, costs, transition masses, rewards, and
Bellman values use `Rational{BigInt}`. Random profile perturbations are drawn
only from

\[
\{-1/4,0,1/4\},
\]

inside fixed structural margins, so they cannot reverse a registered sparse/
dense or silent/active inequality. Descendant increments are drawn only from
\(\{1,2,3\}\). A trial is never resampled in response to an action, value,
loss, or interaction sign.

### Sparse and dense frontiers

In a sparse trial one base strategy supplies the strict base maximum at every
belief, while the other base profiles are separated below it. In a dense
trial each of the three base strategies supplies a strict maximum at its
designated belief. The frontier addition strictly raises the base frontier in
at least one designated belief and is weakly below it elsewhere.

The closure carrier is pointwise below \(F_0\). The registered realized-
density gate is computed on the four non-carrier active strategies in
\(L_{11}\):

- sparse: at most one half are unique frontier suppliers;
- dense: at least three quarters are unique frontier suppliers.

Thus density is verified from the generated profiles, not inferred from the
stratum label.

### Low and high module overlap

The catalog seed permutes module labels within one of two fixed incidence
templates for the three base strategies. The exact mean pairwise Jaccard
overlap of their raw module sets must satisfy:

\[
\text{low}\le 1/4,\qquad \text{high}\ge 2/3.
\]

The frontier addition has either no module or modules already in \(C_0\), so it
cannot change closure on either horizontal edge.

### Weak and strong complementarity

Under weak complementarity, the closure carrier supplies one expansion module
and the added rich-menu project requires that one module.

Under strong complementarity, the carrier supplies two trigger modules. The
closure operator derives a bridge module only when both triggers are present,
and the rich-menu project requires the derived bridge. The bridge is absent
from the raw module union and is obtained only through the actual closure
operator.

Both constructions strictly enlarge closure from \(C_0\) to \(C_1\). Their
closure tables and requirement sets are emitted as source data.

### Costs, durations, admission, and persistence

Project cost, duration, and admission use the exact levels in the factor
table. The three-belief kernel is the cyclic exact Markov law

\[
P=pI+(1-p)S,
\]

where \(S\) advances to the next belief and \(p\in\{1/4,3/4\}\) is the
registered persistence level. Completion enumerates every positive-mass
belief path for the registered duration and combines it with the exact
admission law. Candidate insertion is the ordinary raw catalog insertion.

## Four realizable corners

Every interaction observation is formed by commuting raw additions:

\[
\begin{aligned}
L_{00}&=L_{\mathrm{base}},\\
L_{01}&=L_{\mathrm{base}}\cup\{s_C\},\\
L_{10}&=L_{\mathrm{base}}\cup\{s_F\},\\
L_{11}&=L_{\mathrm{base}}\cup\{s_C,s_F\}.
\end{aligned}
\]

The public `construct_realizable_rectangle` constructor builds these four
libraries from the trial's one catalog and closure system. It does not accept
compressed states. The ordinary compression map is then applied:

\[
L_{00}\mapsto(F_0,C_0),\quad
L_{01}\mapsto(F_0,C_1),\quad
L_{10}\mapsto(F_1,C_0),\quad
L_{11}\mapsto(F_1,C_1),
\]

with \(F_0\le F_1\) and \(C_0\subsetneq C_1\).

`rectangle_consistency` must pass on every trial. In particular:

- all four raw libraries validate against the shared catalog;
- both insertion orders give the same \(L_{11}\);
- the two frontier edges and two closure edges are exact;
- every corner belongs to the raw process carrier;
- project availability is the requirement-subset test on the computed corner
  closure;
- generated/admitted candidate, cost, and completion marginals follow the
  computed closure;
- raw embedded transitions push forward to the compressed transitions; and
- raw and compressed finite-horizon values and selected actions agree.

No frontier scaling, synthetic compressed state, direct menu assignment,
transition assignment, action-value assignment, or corner-value assignment is
allowed. Failure aborts the registered run; it does not trigger replacement
sampling.

## Source pruning and exact values

The source for pruning is the actual raw library \(L_{11}\). The reference
value is the uniform exact mean over the three initial beliefs:

\[
V(L)=\frac13\sum_b V_4(b,L).
\]

The passive value \(W(L)\) freezes the library and operates through the same
belief timing. The research-option premium is \(G(L)=V(L)-W(L)\).

Frontier-only pruning repeatedly deletes a strategy only if the current
frontier is preserved, rechecking after each deletion. Innovation-safe
pruning repeatedly deletes only if both current frontier and actual closure
are preserved. The registered deletion order comes from the recorded
deletion seed. Approximate 10% passive-loss-budget and 5% option-premium-loss-
budget methods remain secondary comparators and use the same source and
deletion order as the two main rules.

For method \(m\),

\[
\Delta_m^V=V(L_{11})-V(P_m(L_{11})),\quad
\Delta_m^W=W(L_{11})-W(P_m(L_{11})),\quad
\Delta_m^G=G(L_{11})-G(P_m(L_{11})).
\]

The signed identity

\[
\Delta_m^V=\Delta_m^W+\Delta_m^G
\]

is an exact gate. Positive-loss indicators use \(\Delta_m^V>0\), without
truncating negative signed changes in the source data.

## Interaction estimand

For the exact four-period mean value at each raw corner,

\[
J=
\bigl[V(L_{11})-V(L_{10})\bigr]
-
\bigl[V(L_{01})-V(L_{00})\bigr].
\]

The registered labels are:

- substitution when \(J<0\);
- complementarity when \(J>0\); and
- zero interaction when \(J=0\).

All 1,024 rectangles enter this sign denominator because four-corner
realizability and strict closure contrast are construction gates. A failed
rectangle is a failed run, not an excluded observation.

## Primitive-assumption conditioning

The exact outcome tables record the following separately:

1. four-corner raw realizability;
2. frontier independence of project availability, cost, generation,
   verification, and joint completion laws at a fixed closure;
3. frontier-independent menus and poor-to-rich menu inclusion;
4. antitonicity of the recursively generated descendant gap;
5. nonnegative rich-menu exposure;
6. zero poor-menu exposure; and
7. every common-gap action-value identity at each registered belief, action,
   and remaining horizon.

Their conjunction is the computed primitive-assumption predicate. It mirrors
the executable ingredients of the canonical primitive T7 subclass. It is
computed from raw primitives and exact action values; the assigned
`theorem_regime` column is not used in its calculation.

Odd batches use a construction intended to satisfy the conjunction. Even
batches alternate two disclosed boundary mechanisms:

- frontier-dependent candidate generation; and
- positive exposure for a poor-closure action.

The full design therefore has a planned 512/512 support split while preserving
all principal-factor balances. The realized exact predicate is authoritative.
All primary frequencies are reported conditionally on predicate true and
false. A positive \(J\) among predicate-true rows is an exact hard-gate
failure requiring investigation and an explicit amendment or formalization
gap; it is never silently removed.

Even when the executable predicate passes, the randomized row remains
`theorem_evidence=false`. Lean verification applies only to the encoded
theorem, not automatically to generated economic instances.

## Primary estimands

All counts, frequencies, means, maxima, and compression ratios below are
computed exactly.

1. **Frontier-only positive dynamic-loss frequency**

   \[
   N^{-1}\sum_t 1\{\Delta_{F,t}^V>0\}.
   \]

2. **Conditional mean positive loss**

   \[
   \frac{\sum_t\Delta_{F,t}^V1\{\Delta_{F,t}^V>0\}}
        {\sum_t1\{\Delta_{F,t}^V>0\}}.
   \]

   If the denominator is zero, the result is recorded as undefined, not zero.

3. **Maximum normalized loss**

   \[
   \max_t\frac{\max(\Delta_{F,t}^V,0)}{V_t(L_{11})}.
   \]

   Strict positivity of every source value is a construction gate.

4. **Innovation-safe loss frequency**

   \[
   N^{-1}\sum_t1\{\Delta_{\mathrm{safe},t}^V>0\}.
   \]

5. **Mean compression ratios.** For frontier-only and innovation-safe
   pruning, report both exact mean retention
   \(|P_m(L_{11})|/|L_{11}|\) and exact mean reduction
   \(1-|P_m(L_{11})|/|L_{11}|\).

6. **Operationally silent generative assets.** For every non-inactive source
   asset \(s\), define

   \[
   \operatorname{Silent}(s)
     \iff F_{L_{11}\setminus\{s\}}=F_{L_{11}},
   \]

   and define it as generatively valuable when deleting it changes actual
   closure and strictly lowers total value. Report the asset-level frequency
   over all non-inactive source assets, the conditional frequency among
   silent assets, and the library-level frequency of at least one such asset.

7. **Interaction signs.** Report substitution, complementarity, and zero
   frequencies on the common denominator 1,024.

8. **Primitive-assumption frequencies.** Repeat the primary frequency table
   by the computed primitive-assumption predicate and separately by every
   principal factor level. Factor summaries are descriptive design contrasts,
   not causal effects.

## Secondary estimands

### Action switching

At every belief and remaining horizon, record the selected action at all four
raw corners and after each pruning method. Report exact count distributions
for:

- vertical closure moves \(L_{00}\to L_{01}\) and
  \(L_{10}\to L_{11}\);
- horizontal frontier moves \(L_{00}\to L_{10}\) and
  \(L_{01}\to L_{11}\); and
- source-to-pruned moves for frontier-only and innovation-safe pruning.

Ties use the package's fixed action order and are flagged separately.

### Frontier density and pruning loss

Report the dense-minus-sparse exact mean positive and signed frontier-only
loss contrasts. Also report the exact rational OLS slope of signed loss on
the realized frontier-supplier fraction, with an intercept. This is a
descriptive relationship, not a causal coefficient.

### Module uniqueness and generative value

For source asset \(s\), module uniqueness is

\[
U_s=\left|C_{L_{11}}\setminus C_{L_{11}\setminus\{s\}}\right|.
\]

Generative deletion value is the exact signed option-premium loss
\(\Delta_s^G\). Report group means by \(U_s=0\) versus \(U_s>0\) and the exact
rational OLS slope of \(\Delta_s^G\) on \(U_s\).

### Closure richness and descendant quality

Closure richness is \(|C_{L_{11}}|\). Descendant quality is the best exact
admitted descendant improvement over the source frontier, averaged over
beliefs using the registered completion law. Report low/high complementarity
group means and the exact rational OLS slope of descendant quality on closure
richness.

No secondary relationship is used to alter trials, factors, estimands, or
reporting.

## Stability and uncertainty

Main estimates use \(N=1024\) only. The deterministic prefixes
\(256,512,768,1024\) and eight nonoverlapping 128-trial batches diagnose
stability.

For every primary frequency, mean loss, and compression mean, report:

- the exact estimate at every registered prefix;
- the exact final-minus-768 difference;
- all eight exact batch estimates; and
- the batch range.

An absolute final-prefix frequency change above \(1/40\) or compression change
above \(1/100\) raises a visible stability alert. Conditional mean positive
loss receives an insufficient-support alert when fewer than 40 positive
events occur. Alerts do not stop the run, exclude rows, change \(N\), or
suppress results.

Wilson intervals are decimal presentation diagnostics for frequencies.
Theorem-facing values, gates, decompositions, point estimates, and sign
classifications remain exact rationals or exact integer counts. No bootstrap
or floating-point solver determines a primary result.

## Required output and failure gates

The versioned paths in the locked TOML must be used. No v1 result path may be
overwritten. The v2 runner must emit complete trial, corner, transition,
pruning, asset, action, profile, module, closure, kernel, and project tables,
plus exact method, factor, relationship, stability, and JSON summaries.

The run fails unless:

- the registry, seed schedule, balance, and prefixes match the lock;
- every source and corner is a valid raw library;
- every rectangle passes the full consistency audit;
- every menu, transition, candidate law, and value is derived from the raw
  process;
- all theorem-facing quantities are exact;
- frontier-only pruning preserves passive value;
- innovation-safe pruning preserves frontier, closure, and total value;
- every loss decomposition holds;
- the intended primitive and boundary constructions match the computed
  predicate;
- predicate-true interaction signs satisfy the registered nonpositivity gate;
  and
- every row remains explicitly outside the theorem-evidence channel.

A deterministic nonmutating rerun must be byte-identical. Host runtime is
reported separately and is not part of any scientific output hash.

## Lock and amendment rule

The design lock hashes this document, the TOML configuration, the complete
trial registry, the locking script, and the raw rectangle constructor source.
At lock time all declared v2 outcome paths must be absent. The lock discloses
that the frozen pilot was known and that no v2 candidate outcome was read.

Any change to \(N\), a factor, a level, a seed, a raw generator rule, a
rectangle rule, an estimand, a prefix, a threshold, or an output path requires
a prospective amendment with a new hash before any v2 outcome run. Outcome-
motivated tuning may not be folded into this design version.
