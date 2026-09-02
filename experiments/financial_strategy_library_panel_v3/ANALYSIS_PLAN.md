# Analysis plan for the robust portfolio innovation-option panel v3

## Evidence order

Results are opened and reported in this order:

1. source, calendar, and point-in-time universe quality;
2. portfolio grammar and executable capability audit;
3. exact compression instances and solution certificates;
4. nested action-set and always-feasible outside-option audit;
5. proposal-year estimation and simultaneous-uncertainty audit;
6. frozen policy choices and availability gate;
7. held-out origin-level economic outcomes;
8. registered robustness and negative controls; and
9. computational performance.

No later block may repair or redefine an earlier block after evaluation-year
outcomes are opened.

## Primary estimands

For origin `o` and universe `u`, let `P^S_ou` and `P^F_ou` be the frozen safe
and comparator evaluation portfolios. The primary economic contrast is

`D_ou = CE(P^S_ou) - CE(P^F_ou)`.

The common-equity universe is primary. The ETF universe is a separately
reported replication and is never averaged into the common-equity headline.

The finite historical panel reports the arithmetic mean, nearest-rank median,
Huber M-estimate, IQR, full range, sign count, and every origin value. A
whole-origin or moving-block interval is descriptive because adjacent origins
share formation, compression, and market histories.

## Structural and policy decomposition

Report separately:

- source, safe, and comparator burden;
- exact optimality and completion status;
- complete innovation-option coverage by arm;
- comparator decisions versus cash;
- safe defaults versus closure-enabled adoptions;
- proposal-year predicted advantage and simultaneous lower bound;
- proposal-to-evaluation calibration;
- held-out mean-return difference;
- held-out variance-penalty difference;
- turnover-cost difference; and
- realized regret relative to the best evaluation-year feasible candidate,
  explicitly labeled an ex-post upper-bound diagnostic.

## Availability gate

An origin-universe cell is economically evaluable only when:

- its point-in-time universe gate passes;
- both exact primary compression arms return independently certified solutions;
- the comparator action set is a subset of the safe action set;
- cash and the exact comparator choice are present in the safe policy;
- proposal paths exist for every candidate entering the simultaneous test; and
- the two frozen evaluation choices have complete held-out paths under the
  registered delisting rule.

Failure rows remain visible. A failed ETF cell does not remove its paired
common-equity origin. The historical primary requires at least 15 complete
common-equity origins; otherwise its economic conclusion is inconclusive.

## Multiple search and uncertainty

The proposal selector considers the complete enumerated alternative family.
The family size, every estimated candidate, and every failure are recorded.
The primary policy uses the registered simultaneous moving-block max-t lower
bound. Pointwise candidate intervals may not be substituted.

The historical report includes a full-search White Reality Check and Hansen SPA
diagnostic over the frozen trial ledger. Any strategy-performance statement
outside the policy estimand must reconcile with those results. Deflated Sharpe
and PBO/CSCV are secondary diagnostics and do not replace the primary policy
evaluation. All resampling keeps a calendar block intact; securities are never
resampled as independent observations.

## Robustness hierarchy

Registered robustness is reported in this order:

1. fixed one-way costs of 0, 5, 15, and 30 basis points;
2. risk aversion 1 and 3;
3. adoption hurdles of 0, 0.0025, and 0.005, with 0.0025 primary;
4. common-equity caps of 50, 100, and 200 when data permit;
5. ETF replication;
6. leave-one-origin-out influence;
7. permuted-closure sham; and
8. forced-maximum legacy policy as a negative control.

The registered capacity appendix reports AUM of USD 1 million, 10 million,
100 million, and 1 billion under the frozen spread and square-root-impact grid.
An order that breaches the 10 percent daily-volume participation cap is marked
unavailable at that AUM rather than truncated or filled at an invented price.

The primary specification is never selected from this robustness family.

## Historical versus confirmatory reporting

The 2000--2025 CRSP block is explicitly retrospective and development-facing.
It may show whether v3 repairs the v2 decision mechanism, but it cannot be
called a fresh confirmation. Confirmatory financial reporting remains locked
until a new source contract, origin registry, and design hash are sealed before
outcome access.
