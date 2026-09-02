# Robust Portfolio Innovation-Option Panel v3

## Status

V3 is a new, prelock design scaffold. No v3 evaluation-year outcome may be
opened until the design, registries, seeds, source census, portfolio grammar,
compression instances, enumerated innovation option sets, and proposal-year
choices are frozen and hash-sealed.

The sealed v2 result is not changed. V2 outcomes and the post-hoc
economic-design audit are known and may inform this protocol, so the
2000--2025 CRSP block is historical development evidence rather than a fresh
confirmatory sample.

## Research question

Does innovation-safe compression preserve economically valuable future
portfolio-strategy options, relative to a frontier-only library under the same
realized burden cap, when innovation adoption is nested, cash is always
feasible, and proposal estimates are adjusted for selection uncertainty?

## Why v3 differs economically from v2

V2 used ticker--strategy candidates and selected the largest predecision point
estimate among every generatable menu candidate. That combined closure with a
larger optimization search, changed security identity in nearly every active
contrast, and used cash only when no active candidate was generatable.

V3 changes four primitives:

1. A candidate is a diversified portfolio strategy applied to an entire
   point-in-time universe, never one rule attached to one security.
2. Cash is always feasible and the safe policy may always retain the exact
   comparator decision.
3. A closure-enabled candidate is adopted only when a simultaneous lower
   confidence bound for its incremental proposal-year value clears a fixed
   economic hurdle.
4. Economic value is the held-out incremental certainty equivalent of the
   complete portfolio under common risk, exposure, and cost rules.

## Sequential information structure

For compression-decision year `y`:

- years `y-5:y-3` construct the source portfolio-strategy library and its
  operating frontier;
- years `y-2:y` estimate compression profiles and solve all library arms;
- year `y+1` presents the exact enumerated innovation-option set, estimates
  proposal value, and freezes both policy choices; and
- year `y+2` supplies the held-out portfolio return paths.

No proposal-year value enters compression. No evaluation-year value enters
compression, option generation, uncertainty estimation, or choice.

All stochastic procedures use the frozen seed registry and stable SHA-256 seed
derivation. Every candidate considered by any arm or policy receives a row in
the registered trial ledger, including unavailable and rejected candidates.

## Point-in-time universes

The primary universe is the 100 most liquid eligible US common equities at the
compression decision. A separate top-50 plain-ETF universe is a registered
replication when at least 20 ETFs pass its point-in-time gate. Equities and
ETFs are not mixed in the primary portfolio.

Eligibility never requires survival into the proposal or evaluation year.
Observed delisting returns are retained and followed by cash. Missing terminal
delisting returns are not silently replaced.

The completeness screen uses predecision data only. A security may not be
removed because it later delists or lacks a future observation; doing so would
condition the liquid universe on survival. `DATA_CONTRACT.md` fixes the exact
classification, liquidity, completeness, and terminal-return rules.

## Portfolio strategies

The full factorial grammar contains 96 portfolio specifications:

- three directional signals;
- two entry filters;
- two holding horizons;
- two cross-sectional allocation rules;
- two gross-exposure targets; and
- two exit rules.

At every session, a specification forms security-level intended positions from
information available at that session, applies the registered implementation
lag, caps individual weights, and normalizes the active portfolio to its gross
target. The same implementation is used in formation, compression, proposal,
and evaluation windows.

## Explicit capability artifacts

Closure contains executable rule and interface capabilities plus platform
artifacts for point-in-time data, corporate actions and delistings, portfolio
aggregation, and the cost/capacity model. A portfolio candidate is generatable
only when the compressed library retains every required rule and platform
capability. Security identifiers are not capability substitutes.

## Compression arms

The primary safe arm is the exact minimum-burden library preserving the frozen
operating frontier and complete declared closure. The comparator is the exact
frontier-only solution augmented, without exceeding the safe realized burden
cap, using a frozen preproposal ordering. Exact MIP is primary; greedy and sham
closure arms are algorithmic or negative-control evidence.

Every returned solution is independently rechecked against the original
integer instance. Timeouts and unsuccessful solves remain in their registered
denominators.

## Exact innovation-option enumeration

V3 has no random challenge menus. Every portfolio grammar candidate excluded
from the frozen source docket is enumerated. Each arm's feasible option set is
obtained by exact requirement inclusion. The safe feasible set must contain
the comparator feasible set before any proposal-year score is read.

## Nested robust adoption

The comparator first chooses between cash and the highest-estimate feasible
proposal whose simultaneous lower confidence bound over cash clears the fixed
economic hurdle. The safe policy receives that exact comparator choice as its
default. Proposal-year incremental portfolio return paths are evaluated with a
paired 20-session moving-block max-t procedure across every candidate in the
relevant policy family. The safe policy adopts a new candidate only if its
simultaneous lower confidence bound over the comparator exceeds 0.0025 annual
certainty-equivalent return.

This makes closure an option rather than a forced trade and directly controls
the unequal-search problem identified in v2.

## Primary outcomes

The structural primary outcome is exact burden conditional on frontier and
closure feasibility. The mechanism primary is enumerated option coverage. The
financial primary is origin-level held-out incremental portfolio certainty
equivalent:

`CE(safe evaluation portfolio) - CE(comparator evaluation portfolio)`.

Mean return, variance penalty, turnover cost, decision changes, calibration,
and regret are reported separately. The origin is the financial unit; neither
securities nor portfolio specifications are independent replicates.

The primary cost rule is the frozen five-basis-point one-way specification. A
registered AUM surface adds lagged spread and square-root impact with an
explicit daily-volume participation cap. It is capacity sensitivity evidence,
not a deployability claim.

## Evidence and claim boundary

The exact structural and algorithmic block is the principal AOR evidence.
The 2000--2025 financial block is retrospective design validation because its
history was known during v3 design. A general or confirmatory performance claim
requires a separately locked later vintage or independent market panel.

`LITERATURE_ALIGNMENT.md` maps these safeguards to the search-bias, delisting,
trading-cost, and dependence literature without changing the claim boundary.
