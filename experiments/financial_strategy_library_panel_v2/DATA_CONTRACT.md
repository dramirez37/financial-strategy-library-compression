# Licensed data contract for Financial Innovation-Challenge Panel v2

V2 uses the locally licensed CRSP/WRDS delivery described in `DATA_ACCESS.md`.
Design-lock validation, registry checks, and synthetic tests do not open those
files. The study uses the registered current snapshot and therefore cannot
make a revision-vintage claim.

## Required source fields

The security-history input must contain `permno`, `secinfostartdt`,
`secinfoenddt`, `ticker`, `securitynm`, `securitytype`, `securitysubtype`, and
`securityactiveflg`. A row may identify an origin universe only when its
effective interval contains the origin date. Later security-history intervals,
future tickers, survival, and future classifications may not change that
universe.

The daily inputs must contain `permno`, `dlycaldt`, `dlyret`, `dlyclose`,
`dlyprc`, `dlyvol`, `dlydelflg`, and `dlyretmissflg`. Duplicate
security--date keys, invalid date order, ambiguous history intervals, malformed
required values, or an unknown return-missing code fail closed. Raw values may
not be printed to logs or written outside ignored local roots.

## Point-in-time opening order

For each registered origin, execution opens only the fields needed for the
current stage:

1. history intervals plus predecision dates, prices, and volumes establish the
   origin universe and liquidity order;
2. construction-window returns establish SPY cutpoints, security-level profile
   support, source-docket ranks, and candidate-pool scores;
3. compression-window returns establish the 30-row frontier, burdens,
   predecision challenge rank, and every compression arm;
4. the universe, dockets, challenge menus, arm identities, and chosen menu
   candidate are serialized and hashed; and
5. only then may postdecision returns be opened for the frozen choices.

The evaluator must prove through field-access instrumentation that no stage
reads a prohibited future field. A failed firewall audit invalidates the run.

## Missingness and delistings

Prices may use absolute `dlyprc` only when `dlyclose` is absent or nonpositive;
every fallback is counted. Returns are never interpolated, forward-filled, or
reconstructed from prices.

Profile support is an origin-time security eligibility rule. A security with
fewer than 25 observations in any registered construction or compression
belief cell is excluded before the candidate pool is generated, with a
reason-coded record. It does not invalidate the origin unless fewer than 20
eligible securities remain or SPY fails.

Postdecision outcomes use the complete registered trading calendar and do not
require every belief state. A valid observed delisting transition includes the
observed delisting return and moves the strategy to cash for later sessions.
An unobserved terminal delisting return is not set to zero or imputed. The
already selected menu is unavailable, and the evaluator may not substitute a
different candidate after seeing outcomes.

## Licensed and public artifacts

Prepared panels, security identifiers, row-level returns, strategy return
paths, menus containing licensed-derived scores, and solver inputs remain
ignored and local. Public promotion is a separate operation after the full
result audit. Its whitelist may contain registered origin IDs, docket and arm
IDs, status and reason codes, aggregate counts, exact burdens, paired
origin-level contrasts, solver diagnostics, hashes, certificates, and a fully
synthetic replay. The audit rejects raw CRSP rows, PERMNOs, tickers other than
the registered public SPY reference, dates linked to a security, and row-level
licensed return derivatives.
