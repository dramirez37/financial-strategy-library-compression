# Draft Results: Terminal Financial Audit

**Status:** aggregate mechanism results are publication-ready; licensed raw and row-level inputs are not redistributed. The exercise validates mechanisms, not expected returns or market alpha.

## Design and audit boundary

We applied the preregistered finite grammar to 25 ETFs using a fixed CRSP/WRDS snapshot. The grammar contains 2400 fully enumerated strategies: three directional signals, two entry filters, two holding horizons, two sizing rules, two exit rules, and two risk constraints for each fund. No strategy code was generated adaptively. Development (2009-01-01 through 2014-12-31) determined belief thresholds and the initial library; validation (2015–2019) determined all pruning and candidate rankings; the 2020–2024 terminal audit period was accessed only after a SHA-256 decision record froze those choices. Signals use information through close t, positions are delayed so the first earned return is t+1 to t+2, and the base calculation charges 5 basis points per unit of one-way turnover.

The source audit retained 4279 common trading dates from 2008-01-02 through 2024-12-31, excluding 0 incomplete cross-sectional dates. CRSP `dlyret` was compounded into a total-return index; closing prices and volumes were not interpolated. The fixed surviving ETF set is deliberately transparent but not survivorship-free, and the current CRSP snapshot is point-in-time-conscious rather than point-in-time certified. These boundaries rule out an alpha interpretation even if some backtest scores are positive.

## A. Frontier-only pruning

Frontier-only pruning reduced the initial library from 80 to 3 strategies, changed the validation frontier value by 0.0000, and changed the best enabled locked-period candidate quality by -0.0016. The mechanism verdict is **supportive**. Thus the current-value identity was checked directly, while the forward-quality effect was allowed to be zero or negative rather than forced to support the theory. The result distinguishes a theorem mechanism—closure can matter after current domination—from a universal empirical claim that every frontier-only deletion must be harmful.

## B. Innovation-safe compression

Innovation-safe deletion reduced the library from 80 to 25 strategies. Automated gates verified that both the three-state validation frontier and the complete module closure were unchanged. The resulting current-value change was 0.0000; the best enabled locked-candidate quality change was 0.0000. Any nonzero value beyond the configured numerical tolerance would fail the experiment rather than be reported as approximate support. This is the closest empirical analogue to the paper’s safe-compression identity.

## C. Coverage-potential ranking

Coverage potential ranked candidates from validation-state gaps weighted by a development-estimated belief transition kernel. Its frozen top-10 set achieved a mean locked-period utility improvement of -0.1560, compared with -0.0685 for the best of current-belief improvement, average validation score, and raw module novelty. The difference is -0.0874; the preregistered verdict is **negative_or_tied**. Across all candidates, the Spearman association between coverage score and locked quality was -0.0982.

A circular block bootstrap with 500 deterministic StableRNG replications and 20-session blocks gave a 95% interval of [-0.4531, -0.1301] for the coverage-ranked top-k improvement. This uncertainty describes dependence-sensitive variation within the locked sample; it does not repair model selection, universe selection, or snapshot-revision risk. Negative or tied ranking results remain part of the intended evidence.

## D. Operational–generative decomposition

For every strategy in the safely compressed library, we removed that strategy alone and measured (i) the validation-frontier loss and (ii) the reduction in best enabled locked candidate quality. The reported total is the exact sum of these operational and generative components, and the script fails if the accounting identity is violated. We found 1 currently dominated policy with a strictly positive generative component; the mechanism verdict is **supportive**. The identified carrier was GLD `GLD__momentum_60__trend_100__h20__unit__horizon__vol_target_10` (operational 0.0000, generative 0.0016). This shows why a policy can be dispensable for current operation yet worth retaining as a carrier of modules used by later candidates. In either case, the decomposition does not imply that a retained policy itself earns an abnormal return.

## Interpretation

The terminal audit is deliberately small and falsifiable. Its primary outcomes are identity checks, pruning decisions, closure losses, ranking comparisons, and decomposition terms. Profit levels are nuisance quantities used to instantiate the finite model, not the paper’s contribution. Results are reported gross and net in the candidate audit, with 1, 5, and 10 basis-point frozen cost sensitivities in the companion table. The appropriate conclusion is therefore about whether the proposed compression and coverage mechanisms organize a transparent finite strategy library—not whether any rule predicts returns outside this retrospective audit.
