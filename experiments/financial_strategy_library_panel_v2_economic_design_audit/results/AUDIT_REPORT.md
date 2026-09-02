# Economic-design falsification audit: sealed financial panel v2

## Verdict

**V3_ECONOMIC_DIRECTION_SUPPORTED**. The audit triggered 4 of 4 diagnostic conditions; at least 3 were required to proceed with the economic v3 direction.

This is a post-hoc design diagnosis, not a replacement v2 result. The sealed v2 primary remains registered and unchanged.

## Controlling data and reconciliation

- 40 sealed origin--docket predecision files were hash-matched to 40 postdecision files.
- 1,280 registered menu pairs were recovered; 1277 were complete and 3 remained unavailable.
- The independently recomputed registered origin mean was `0.013739943160905252`, matching the promoted summary.

## Findings

| Finding | Evidence | Interpretation |
|---|---:|---|
| Unequal opportunity-set optimization | Safe rank-one choices: 1280/1,280; comparator lower-rank or cash: 861/1,280 | Closure is combined with greater exposure to the maximum of noisy estimates. |
| Weak rank calibration | Active changed pre-gap/held-out correlation: 0.024958461556193638 | The ranking rule does not reliably distinguish the subsequently better choice. |
| Security-identity confounding | Different-security share among active changed pairs: 0.988388969521045 | Nearly every active contrast changes both the rule and the security. |
| Cash outside option omitted | Safe estimated-negative active choices: 15; comparator: 327 | Both arms can be forced to exercise an estimated-negative option even though cash has utility zero. |
| Primary sensitivity to cash floor | Mean 0.013739943160905252 → 0.005959353518453454; 2007 contribution 0.776992768915916 → 0.1940846842362316 | A rational outside option materially reduces both magnitude and outlier dependence. |

## Policy diagnostics

| Policy | Origin mean | Median | Positive / negative | 2007 signed contribution |
|---|---:|---:|---:|---:|
| Registered forced-active rule | 0.013739943160905252 | 9.18037759449152e-5 | 11 / 9 | 0.776992768915916 |
| Cash floor | 0.005959353518453454 | 0.0022848213837507385 | 12 / 8 | 0.1940846842362316 |
| Nested no-harm, threshold 0 | 0.005959353518453454 | 0.0022848213837507385 | 12 / 8 | 0.1940846842362316 |

The threshold grid is diagnostic only. Selecting a favorable threshold from this historical panel would be another form of outcome-driven specification search.

## Instrument-class heterogeneity

| Safe class | Comparator class | Changed pairs | Mean | Median |
|---|---|---:|---:|---:|
| common_equity | cash | 146 | 0.010611236918495932 | 0.022413531305645988 |
| common_equity | common_equity | 427 | 0.03810183510912132 | 0.01107887469976892 |
| common_equity | plain_etf | 162 | 0.0002923594492342019 | -0.0019150296756749452 |
| plain_etf | cash | 23 | -0.005694926841214787 | -0.0010793445941923406 |
| plain_etf | common_equity | 59 | 0.008331237769242012 | 0.01330285785989245 |
| plain_etf | plain_etf | 41 | -0.01981967214584299 | -0.015050509818667943 |

## Decision for v3

The gate supports proceeding with a v3 economic design that: (1) treats cash and the comparator choice as always-feasible outside options; (2) uses diversified portfolio strategies rather than ticker--strategy candidates; (3) separates opportunity coverage, ranking calibration, and realized policy value; and (4) evaluates incremental portfolio certainty equivalent under a common risk and cost budget.

## Limitations

- Every alternative policy was evaluated after the v2 outcome was known.
- Candidate-level correlations are range-restricted by the frozen selection rules.
- The audit can diagnose the current decision rule but cannot establish the performance of v3.
- A genuinely confirmatory v3 economic result still requires an untouched time period or independent market panel.
