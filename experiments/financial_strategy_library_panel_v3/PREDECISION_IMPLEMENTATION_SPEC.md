# Frozen v3 predecision implementation specification

This specification is adopted by Design Amendment 001 before any v3
predecision return value is extracted. It refines mechanics already fixed by
the base design and changes no outcome, claim, universe, arm, or policy.

## Security signals and positions

For each security and close `t`, the total-return index compounds source total
returns through `t`.

- `momentum_20` is active when the 20-session index return is positive.
- `momentum_60` is active when the 60-session index return is positive.
- `mean_reversion_5` is active when the 5-session index return is negative.
- `always` passes every otherwise valid signal.
- `trend_100` passes when the current index is strictly above its trailing
  100-session arithmetic mean.

A flat security enters when its signal and filter both pass. Its age is one on
the entry close. `horizon` exits after exactly the registered number of active
signal closes. `signal_flip` exits at the earlier of that horizon or the first
close on which the directional signal no longer passes. An exit close cannot
also re-enter.

## Portfolio weights and timing

All positions are long or cash. `equal_weight` assigns raw weight one to every
active security. `inverse_volatility` assigns the reciprocal of annualized
sample volatility from the trailing 20 daily returns; a missing, zero, or
nonfinite estimate receives raw weight zero.

Raw active weights are deterministically water-filled subject to the frozen
per-security cap. The realized gross target is

`min(registered gross target, active positive-weight count * security cap)`.

The capped weights are then applied to each of the trailing 20 session security
return vectors through close `t`. Their annualized sample volatility is the
point-in-time portfolio volatility estimate. Capped weights are multiplied by
`min(1, 0.10 / estimated volatility)`: volatility scaling may reduce exposure
but never lever it above the registered gross target. Zero estimated volatility
does not reduce exposure; a missing or nonfinite estimate moves the portfolio
to cash. Scaling preserves every security cap. Any residual is cash. Thus an
underpopulated or volatility-scaled signal never violates the cap and is never
forced into an unregistered security.

Intended weights formed at close `t` first earn the close-to-close return
indexed `t+2`. Portfolio turnover is the full one-way dollar-weight change,
including entry from and exit to cash.

An observed terminal delisting return, including exactly -100%, is earned by
the effective position on that session. The security is forced to cash after
that close and cannot re-enter. A terminal flag without an observed return, or
an observed return after a terminal flag, is an input error. Any other missing
return touched by a positive effective weight marks that portfolio session
unavailable; it is never replaced by zero.

## Formation operating profiles

Each portfolio grammar candidate receives 12 formation profiles: three frozen
formation calendar years crossed with one-way costs of 5 and 30 basis points
and risk aversion of 1 and 3. Every profile is annual arithmetic certainty
equivalent using 252 sessions and sample variance. Profile identifiers are
ordered by year then cost then risk.

The source docket is the union of:

1. every candidate attaining an exact maximum in at least one formation
   profile; and
2. the first three candidates carrying each required capability under
   descending mean formation certainty equivalent at 5 basis points and risk
   aversion 3 with strategy identifier as tie-break.

The union is frozen before compression-window profiles are computed. The
compression instance uses the same 12 year/cost/risk profiles on the three
compression years.

## Capabilities and innovation pool

A portfolio candidate requires its six atomic rule capabilities, its three
declared interfaces, the point-in-time data capability for its own universe,
and the corporate-action, portfolio-aggregation, and cost-model platform
capabilities. The opposite instrument-class data capability is irrelevant to
that cell. Complete closure therefore has 31 capabilities per cell.

Every one of the 96 grammar candidates not in the frozen source docket is an
innovation trial. No random menu or post-formation candidate filtering is
permitted.

## Burden

Strategy burden is the exact integer sum of the registered components in
`registry/BURDEN_REGISTRY.csv`. The primary safe MIP minimizes this burden
subject to exact frontier and complete-closure coverage. The frontier-only
parent minimizes the same burden under frontier constraints alone. Its
budget-matched endpoint adds candidates in descending mean compression score
then identifier order whenever the addition fits below the safe burden cap.

Cash is mandatory with zero burden. All MIP endpoints are independently
rechecked against the original unpreprocessed instance. Solver optimality is a
computational certificate and is not described as a formal proof.

## Data-access boundary

No historical return value may be decoded under this amendment alone. A
date-aware extractor, access manifest, and sentinel leakage tests must be
independently sealed first. That extractor may then consume return values dated
no later than each origin's compression decision and must select identifier and
date rows before decoding a return column. Proposal- and evaluation-window
return values remain unread until the full predecision seal passes. The access
authority is explicitly layered: the base lock establishes eligibility but is
never sufficient by itself; the current amendment lock and the separate
extractor lock must also verify before effective predecision access becomes
true.
