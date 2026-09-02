# Financial Innovation-Challenge Panel v2 — design amendment 001

## Timing and disclosure

This amendment was adopted on 2026-09-01 after execution attempt 004 reached
the profile-support scan and exposed standard CRSP reason codes on missing
returns. The source schemas, file hashes, point-in-time decision dates, and
provisional liquidity candidates had been computed. A SPY-only local Parquet
cache had also been written. No security-level profile-support result,
strategy score, registered random seed, docket, challenge menu, compression
arm, solver result, or postdecision outcome had been computed or observed.

The amendment is therefore prospective with respect to every scientific
outcome, but it is data-quality informed rather than part of the pristine
pre-data v2 registration. Any journal report must say so.

## Master liquid-market panel

The security universe and data architecture change at the user's direction.
Before scientific evaluation, the runner builds one local master daily panel
for 2000-01-01 through 2025-12-31. It contains every PERMNO whose point-in-time
history has at least one eligible interval during the study period. Eligible
intervals are regular-way, actively trading US listings with no special share
form and are either:

1. CRSP common equities (`EQTY`, `COM`, `NS`, US incorporated, issuer `ACOR`
   or `CORP`); or
2. CRSP exchange-traded funds (`FUND`, `ETF`, `NS`, US incorporated).

The eligible primary-exchange set is `N`, `Q`, `A`, `R`, and `B`. ADRs, units,
closed-end funds, REIT share-code classes, non-US incorporations,
non-regular-way rows, halted or suspended intervals, and leveraged/inverse or
otherwise complex products matching the registered name keywords are
excluded. Common equities and plain ETFs receive no quotas: they compete in a
single liquidity ranking.

For each annual origin, security classification is resolved from the history
interval effective on that origin's decision session. The origin view runs
from January 1 of the calendar year before the registered construction window
through the decision date. The extra year is the fixed warm-up required by the
longest grammar lookback. No later classification, survival, or liquidity may
alter that view.

SPY's valid sessions in that interval define the predecision reference
calendar. A provisional security is complete only if every reference session
has all of the following:

1. a finite compoundable total return carrying CRSP return flag `NA`;
2. a positive close, using absolute `dlyprc` only under the already registered
   close-fallback rule; and
3. a finite nonnegative daily volume.

A known CRSP missing-return reason (`DG`, `DM`, `DP`, `GP`, `MP`, `MV`, `NS`,
`NT`, or `RA`) remains missing, is never imputed, and causes that security to
fail the complete-case rule when it falls on a reference session. Unknown or
contradictory return flags still fail the entire run closed. Nonreference dates
are counted for diagnosis but are not added to the aligned structural panel.

The original minimum of 25 valid observations in each of the five registered
SPY states remains an additional check in both the construction and
compression windows. Complete common equities and ETFs are pooled, ranked by
median predecision compression-window dollar volume and then ascending
PERMNO, after which the first 100 are retained. An origin still requires at
least 20 retained securities and SPY.

## Information firewall

The master panel is a hash-sealed data-engineering artifact, not an authorized
scientific view. Origin-scoped loaders enforce date cutoffs and emit access
logs. Universe construction, state estimation, scoring, docket construction,
and arm selection cannot request a row after the origin decision date. The
postdecision loader cannot be called until all sources, menus, arm identities,
and selected menu candidates have been serialized and the predecision seal
has been verified. Missing postdecision sessions continue to make the already
frozen candidate unavailable; they never trigger ex post replacement.

## Estimand consequence

This amendment changes the eligible-security sample from an ETF-only
state-cell-support population to the most-liquid fully observed US common
equities and plain ETFs. It therefore changes the scientific estimand and must
not be described as a mere runtime repair. The primary mechanism contrast,
origins, standard 96-strategy grammar, dockets, menus, burdens, arms, seeds,
postdecision outcome rule, availability gates, and reporting nonclaims are
unchanged.

The registered rationale is measurement integrity: structural differences
should not be confounded by irregular security calendars or by silently
collapsing missing trading sessions. This comes at the cost of a narrower,
more liquid and longer-lived sample; survivorship claims remain prohibited.
