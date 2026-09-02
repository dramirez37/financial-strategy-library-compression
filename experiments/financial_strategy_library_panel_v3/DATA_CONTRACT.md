# Point-in-time data contract for v3

## Scope and purpose

The historical development block uses the immutable v2 CRSP/WRDS daily master
panel. The contract is evaluated separately for every compression-decision
origin and never conditions primary equity eligibility on proposal-year or
evaluation-year survival.

The primary universe contains liquid US common equities. Plain ETFs are
allowed only in the registered ETF replication. The two instrument classes are
never mixed in a primary portfolio or headline estimand.

## Point-in-time classification

At each compression decision date the historical CRSP share and exchange codes
classify common equities. The ETF replication uses the historical security-type
fields available at that date. A later reclassification may not rewrite an
earlier universe.

Security identity is the permanent source identifier. Ticker symbols are
display labels only and changes in ticker do not create a new security.

## Predecision completeness and liquidity

An equity can enter the ranked eligible set only when all of the following are
true using data available through the compression decision:

- price is at least USD 5 at the decision date;
- trailing median daily dollar volume is at least USD 5 million;
- every expected reference-market session has a finite price and a source flag
  certifying an ordinary return observation in the complete six-year
  predecision window; and
- the minimum lookback for the longest signal and volatility estimator is
  present before the first position can be formed.

Eligible securities are ranked by trailing median dollar volume with permanent
identifier as the deterministic tie-break. The primary common-equity panel
keeps the first 100 and requires at least 80. The ETF replication keeps the
first 50 and requires at least 20.

This is the experiment's full-data rule: completeness is assessed only with
information that exists at the decision. Requiring complete future data would
select on survival and is prohibited.

## Corporate actions and terminal observations

Returns and prices use the source's split and distribution adjustments. An
observed delisting return is retained on its recorded date and the position is
then placed in cash. A terminal disappearance without a resolved delisting
return is recorded as unavailable under a frozen failure code; it is never
silently set to zero and the origin remains in the denominator.

A security that becomes temporarily missing after universe formation receives
no newly inferred price. The last executable position remains subject to the
registered stale-price and terminal-availability rules. No security is removed
from a frozen universe because of information first observed in the proposal
or evaluation year.

## Leakage controls

- Universe construction reads no field dated after the compression decision.
- Portfolio signals are shifted by the registered two-session implementation
  lag before returns are accrued.
- Volume and volatility used in costs or weights are lagged.
- Proposal data can rank frozen generatable candidates but cannot alter a
  library or universe.
- Evaluation data can score only the two frozen policy choices.

## Required quality artifact

Before a v3 design lock can permit any historical proposal or evaluation read,
the Julia census must emit one row per origin and universe containing eligible
counts, selected counts, completeness failures, classification failures,
delisting coverage, calendar coverage, and source-manifest hashes. Failed cells
remain visible.
