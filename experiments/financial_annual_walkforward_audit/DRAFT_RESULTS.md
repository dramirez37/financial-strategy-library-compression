# Draft Results: Annual Walk-Forward Financial Audit

**Status:** the annual walk-forward mechanism run is complete under the documented lock and amendment chain. The locked terminal-audit adverse ranking remains reported separately. Licensed rows are excluded; aggregate outputs are publishable.

## Design

The outcome-blind audit selected 100 liquid, endpoint-stable ETFs from 427 CRSP ETF identities, versus the 25-ETF terminal-audit universe. The full finite grammar contains 9600 strategies. Development (2009--2014) fixes the universe, belief quintiles, and initial library. Validation (2015--2019) fixes the first ranking episode and the compression audit. Five annual walk-forward episodes then estimate profiles and transitions from the preceding five calendar years and score the next year, 2020 through 2024. Each annual ranking and top-five selection is SHA-256 hashed before its target-year sufficient statistics are accessed. The score is aligned with S4's empirical estimand: positive state-profile gaps are integrated against predicted discounted belief occupation. Candidate sets are chosen by sequential marginal rather than independent coverage.

The target is the analogous next-year gap integrated against realized discounted belief occupation. This is a mechanism target, not portfolio return and not an alpha estimand. The universe, ranking rules, 5 bp one-way base cost, 1/10 bp sensitivities, seed `6075990691714899802`, and non-gating support verdict were frozen in the initial analytical lock `2af8b413e2b37eea94cb9a5ded6b48d6ca268be7d92fcaf0823be9830be994bc` before return extraction. A sparse-state feasibility amendment and six report-only corrections are disclosed in `DESIGN_AMENDMENTS.md`; no candidate result changed the analytical specification. The completed implementation lock is `6c92ad2b12196f6e481fac5a4c3b3703591f4ec20861df44b75bee3618c51e88`.

## Compression mechanisms

The initial library contained 202 strategies. Frontier-only pruning retained 5; its validation-value change was 0.0000 and its future candidate-quality change was -0.1020, yielding **supportive**. Innovation-safe deletion retained 100 and passed both registered identities: validation frontier and module closure were unchanged, and future enabled-candidate quality changed by 0.0000. Any deviation beyond tolerance would have aborted the run.

## Coverage ranking

Across five walk-forward years, marginal coverage achieved mean realized set coverage 0.0704 and mean regret 0.3150 relative to the target-year greedy oracle. Its mean candidate-level Spearman association was 0.1279. The strongest comparator by realized set value was `average_trailing_score` at 0.0119 with regret 0.3735. The frozen annual walk-forward verdict is **supportive**; no score or universe rule is changed in response.

A deterministic StableRNG bootstrap over the five annual episodes gives a 95% interval [0.0190, 0.1187] for mean realized set coverage. With only five annual units, this interval is descriptive and coarse. It does not account for universe choice, grammar choice, provider revisions, or repeated research iterations.

## Operational--generative decomposition

Every safely retained policy was deleted alone. The operational term is its validation-frontier contribution; the generative term is its contribution to best enabled future candidate quality. Totals are the exact numerical sum and fail on mismatch. The run found 1 currently dominated policies with positive generative retention value; the verdict is **supportive**. This explains why a currently dominated module carrier can remain worth retaining without claiming that the carrier itself forecasts returns.

## Interpretation

The larger universe improves breadth and the redesigned score aligns prediction and evaluation with the coverage-potential object, while the walk-forward layout exposes five separate decisions instead of one terminal ranking. It still does not establish a universal ranking theorem. The scientific contribution is whether frontier preservation, closure preservation, marginal coverage, and the operational--generative accounting organize a transparent finite library. Profitability is not the contribution, and negative or mixed results remain visible in the tables.
