# Financial algorithm comparison results

Status: **AUDITED RETROSPECTIVE FINANCIAL RESULTS**.

This report is generated from the public aggregate `experiments/results/summaries/financial_algorithm_comparison_v1.csv` (SHA-256 `97edde869be03b07b0f97c33ee8b8909e11d07b431edbeb5f841d33b067e2011`). Every number below is derived from a committed row; none is manually transcribed.

## Evidence boundary

The licensed panels were used to recompute validation profiles for the committed source libraries. Before algorithm dispatch, those profiles reproduced the committed exact source frontiers and module unions. Every returned library was then independently rechecked for mandatory inactive retention, exact frontier equality, exact closure equality, and exact burden. HiGHS `OPTIMAL` remains solver evidence, not formal or exhaustive proof. Held-out opportunity diagnostics were evaluated only after all selections and burden gaps were frozen. Terminal and annual diagnostic units are reported separately and are not pooled.

These are retrospective resource-allocation diagnostics. They support no causal, forecasting, alpha, or deployable-performance claim.

## Source structure and preprocessing

| Audit | Active | Frontier rows | Module rows | Density | Duplicates | Dominance | Unique carriers | Forced | Variables | Constraints |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Locked terminal audit | 80 | 3 | 38 | 563//3280 | 0 | 0 | 3 | 25 | 81 → 0 | 42 → 0 |
| Annual walk-forward audit | 202 | 5 | 113 | 1419//23836 | 0 | 0 | 5 | 100 | 203 → 0 | 119 → 0 |

Coverage density is exact active strategy-to-tagged-requirement incidence. Reductions are computed by the registered fixed-point exact preprocessor.

## Locked terminal audit

| Schedule | Algorithm | Status | Selected active | Exact burden | Absolute gap | Relative gap | Seconds | MIP nodes | DP states |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| uniform_cardinality | Locked stepwise deletion | HISTORICAL_LOCKED_ENDPOINT_EXACTLY_RECHECKED | 25 | 25//1 | 0//1 | 0//1 | — | — | — |
| uniform_cardinality | Heaviest-safe-first | certified_irreducible_heuristic | 25 | 25//1 | 0//1 | 0//1 | 0.469991958 | — | — |
| uniform_cardinality | Weighted greedy | feasible_heuristic | 25 | 25//1 | 0//1 | 0//1 | 0.073366708 | — | — |
| uniform_cardinality | Weighted greedy + reverse deletion | feasible_heuristic | 25 | 25//1 | 0//1 | 0//1 | 0.018190667 | — | — |
| uniform_cardinality | 32-start random deletion | certified_irreducible_heuristic | 25 | 25//1 | 0//1 | 0//1 | 9.92784875 | — | — |
| uniform_cardinality | Preprocessed HiGHS MIP | exactly_rechecked_solver_candidate | 25 | 25//1 | 0//1 | 0//1 | 0.323454666 | — | — |
| uniform_cardinality | Exact requirement-mask DP | SKIPPED_RESIDUAL_REQUIREMENTS_41_EXCEED_LIMIT_22 | — | — | — | — | — | — | — |
| uniform_cardinality | Optional second solver | UNAVAILABLE_NO_SECOND_SOLVER_DECLARED | — | — | — | — | — | — | — |
| nonshared_modules | Locked stepwise deletion | HISTORICAL_LOCKED_ENDPOINT_EXACTLY_RECHECKED | 25 | 25//1 | 0//1 | 0//1 | — | — | — |
| nonshared_modules | Heaviest-safe-first | certified_irreducible_heuristic | 25 | 25//1 | 0//1 | 0//1 | 0.355968167 | — | — |
| nonshared_modules | Weighted greedy | feasible_heuristic | 25 | 25//1 | 0//1 | 0//1 | 0.017628875 | — | — |
| nonshared_modules | Weighted greedy + reverse deletion | feasible_heuristic | 25 | 25//1 | 0//1 | 0//1 | 0.018577 | — | — |
| nonshared_modules | 32-start random deletion | certified_irreducible_heuristic | 25 | 25//1 | 0//1 | 0//1 | 9.727691917 | — | — |
| nonshared_modules | Preprocessed HiGHS MIP | exactly_rechecked_solver_candidate | 25 | 25//1 | 0//1 | 0//1 | 0.025347792 | — | — |
| nonshared_modules | Exact requirement-mask DP | SKIPPED_RESIDUAL_REQUIREMENTS_41_EXCEED_LIMIT_22 | — | — | — | — | — | — | — |
| nonshared_modules | Optional second solver | UNAVAILABLE_NO_SECOND_SOLVER_DECLARED | — | — | — | — | — | — | — |
| validation_computation | Locked stepwise deletion | HISTORICAL_LOCKED_ENDPOINT_EXACTLY_RECHECKED | 25 | 450//1 | 112//1 | 56//169 | — | — | — |
| validation_computation | Heaviest-safe-first | certified_irreducible_heuristic | 25 | 338//1 | 0//1 | 0//1 | 0.205695875 | — | — |
| validation_computation | Weighted greedy | feasible_heuristic | 26 | 344//1 | 6//1 | 3//169 | 0.035682084 | — | — |
| validation_computation | Weighted greedy + reverse deletion | feasible_heuristic | 25 | 342//1 | 4//1 | 2//169 | 0.019056125 | — | — |
| validation_computation | 32-start random deletion | certified_irreducible_heuristic | 25 | 417//1 | 79//1 | 79//338 | 10.173682709 | — | — |
| validation_computation | Preprocessed HiGHS MIP | exactly_rechecked_solver_candidate | 25 | 338//1 | 0//1 | 0//1 | 0.026535375 | — | — |
| validation_computation | Exact requirement-mask DP | SKIPPED_RESIDUAL_REQUIREMENTS_41_EXCEED_LIMIT_22 | — | — | — | — | — | — | — |
| validation_computation | Optional second solver | UNAVAILABLE_NO_SECOND_SOLVER_DECLARED | — | — | — | — | — | — | — |
| documented_complexity | Locked stepwise deletion | HISTORICAL_LOCKED_ENDPOINT_EXACTLY_RECHECKED | 25 | 96//1 | 11//1 | 11//85 | — | — | — |
| documented_complexity | Heaviest-safe-first | certified_irreducible_heuristic | 25 | 85//1 | 0//1 | 0//1 | 0.219080125 | — | — |
| documented_complexity | Weighted greedy | feasible_heuristic | 25 | 85//1 | 0//1 | 0//1 | 0.017760542 | — | — |
| documented_complexity | Weighted greedy + reverse deletion | feasible_heuristic | 25 | 85//1 | 0//1 | 0//1 | 0.01823825 | — | — |
| documented_complexity | 32-start random deletion | certified_irreducible_heuristic | 25 | 93//1 | 8//1 | 8//85 | 9.797286875 | — | — |
| documented_complexity | Preprocessed HiGHS MIP | exactly_rechecked_solver_candidate | 25 | 85//1 | 0//1 | 0//1 | 0.025486 | — | — |
| documented_complexity | Exact requirement-mask DP | SKIPPED_RESIDUAL_REQUIREMENTS_41_EXCEED_LIMIT_22 | — | — | — | — | — | — | — |
| documented_complexity | Optional second solver | UNAVAILABLE_NO_SECOND_SOLVER_DECLARED | — | — | — | — | — | — | — |

The common ex-post opportunity diagnostic for exactly safe endpoints is `8162187676336809//72057594037927936` in terminal locked-2020-2024 enabled-descendant net-utility opportunity units. Equality here follows from exact closure preservation; it was not used to choose an algorithm or library.

## Annual walk-forward audit

| Schedule | Algorithm | Status | Selected active | Exact burden | Absolute gap | Relative gap | Seconds | MIP nodes | DP states |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| uniform_cardinality | Locked stepwise deletion | HISTORICAL_LOCKED_ENDPOINT_EXACTLY_RECHECKED | 100 | 100//1 | 0//1 | 0//1 | — | — | — |
| uniform_cardinality | Heaviest-safe-first | certified_irreducible_heuristic | 100 | 100//1 | 0//1 | 0//1 | 5.868533917 | — | — |
| uniform_cardinality | Weighted greedy | feasible_heuristic | 100 | 100//1 | 0//1 | 0//1 | 0.133650917 | — | — |
| uniform_cardinality | Weighted greedy + reverse deletion | feasible_heuristic | 100 | 100//1 | 0//1 | 0//1 | 0.189760709 | — | — |
| uniform_cardinality | 32-start random deletion | certified_irreducible_heuristic | 100 | 100//1 | 0//1 | 0//1 | 183.775857209 | — | — |
| uniform_cardinality | Preprocessed HiGHS MIP | exactly_rechecked_solver_candidate | 100 | 100//1 | 0//1 | 0//1 | 0.217719875 | — | — |
| uniform_cardinality | Exact requirement-mask DP | SKIPPED_RESIDUAL_REQUIREMENTS_118_EXCEED_LIMIT_22 | — | — | — | — | — | — | — |
| uniform_cardinality | Optional second solver | UNAVAILABLE_NO_SECOND_SOLVER_DECLARED | — | — | — | — | — | — | — |
| nonshared_modules | Locked stepwise deletion | HISTORICAL_LOCKED_ENDPOINT_EXACTLY_RECHECKED | 100 | 100//1 | 0//1 | 0//1 | — | — | — |
| nonshared_modules | Heaviest-safe-first | certified_irreducible_heuristic | 100 | 100//1 | 0//1 | 0//1 | 5.783980417 | — | — |
| nonshared_modules | Weighted greedy | feasible_heuristic | 100 | 100//1 | 0//1 | 0//1 | 0.104687041 | — | — |
| nonshared_modules | Weighted greedy + reverse deletion | feasible_heuristic | 100 | 100//1 | 0//1 | 0//1 | 0.122880333 | — | — |
| nonshared_modules | 32-start random deletion | certified_irreducible_heuristic | 100 | 100//1 | 0//1 | 0//1 | 203.96899975 | — | — |
| nonshared_modules | Preprocessed HiGHS MIP | exactly_rechecked_solver_candidate | 100 | 100//1 | 0//1 | 0//1 | 0.203579666 | — | — |
| nonshared_modules | Exact requirement-mask DP | SKIPPED_RESIDUAL_REQUIREMENTS_118_EXCEED_LIMIT_22 | — | — | — | — | — | — | — |
| nonshared_modules | Optional second solver | UNAVAILABLE_NO_SECOND_SOLVER_DECLARED | — | — | — | — | — | — | — |
| validation_computation | Locked stepwise deletion | HISTORICAL_LOCKED_ENDPOINT_EXACTLY_RECHECKED | 100 | 1566//1 | 396//1 | 22//65 | — | — | — |
| validation_computation | Heaviest-safe-first | certified_irreducible_heuristic | 100 | 1170//1 | 0//1 | 0//1 | 5.939227125 | — | — |
| validation_computation | Weighted greedy | feasible_heuristic | 101 | 1172//1 | 2//1 | 1//585 | 0.160767667 | — | — |
| validation_computation | Weighted greedy + reverse deletion | feasible_heuristic | 100 | 1170//1 | 0//1 | 0//1 | 0.149717333 | — | — |
| validation_computation | 32-start random deletion | certified_irreducible_heuristic | 100 | 1579//1 | 409//1 | 409//1170 | 214.738911459 | — | — |
| validation_computation | Preprocessed HiGHS MIP | exactly_rechecked_solver_candidate | 100 | 1170//1 | 0//1 | 0//1 | 0.202563542 | — | — |
| validation_computation | Exact requirement-mask DP | SKIPPED_RESIDUAL_REQUIREMENTS_118_EXCEED_LIMIT_22 | — | — | — | — | — | — | — |
| validation_computation | Optional second solver | UNAVAILABLE_NO_SECOND_SOLVER_DECLARED | — | — | — | — | — | — | — |
| documented_complexity | Locked stepwise deletion | HISTORICAL_LOCKED_ENDPOINT_EXACTLY_RECHECKED | 100 | 355//1 | 40//1 | 8//63 | — | — | — |
| documented_complexity | Heaviest-safe-first | certified_irreducible_heuristic | 100 | 315//1 | 0//1 | 0//1 | 5.219200834 | — | — |
| documented_complexity | Weighted greedy | feasible_heuristic | 100 | 315//1 | 0//1 | 0//1 | 0.105457375 | — | — |
| documented_complexity | Weighted greedy + reverse deletion | feasible_heuristic | 100 | 315//1 | 0//1 | 0//1 | 0.122288333 | — | — |
| documented_complexity | 32-start random deletion | certified_irreducible_heuristic | 100 | 350//1 | 35//1 | 1//9 | 228.166060833 | — | — |
| documented_complexity | Preprocessed HiGHS MIP | exactly_rechecked_solver_candidate | 100 | 315//1 | 0//1 | 0//1 | 0.268077209 | — | — |
| documented_complexity | Exact requirement-mask DP | SKIPPED_RESIDUAL_REQUIREMENTS_118_EXCEED_LIMIT_22 | — | — | — | — | — | — | — |
| documented_complexity | Optional second solver | UNAVAILABLE_NO_SECOND_SOLVER_DECLARED | — | — | — | — | — | — | — |

The common ex-post opportunity diagnostic for exactly safe endpoints is `7728204652088667//72057594037927936` in annual mean next-year enabled-descendant opportunity units. Equality here follows from exact closure preservation; it was not used to choose an algorithm or library.

## Interpretation limits

Runtime is machine-specific floating-point timing evidence. DP burdens are exact finite-computation results when the registered residual-requirement limit applies. MIP objectives, bounds, gaps, nodes, and statuses are solver diagnostics followed by independent exact feasibility and burden checks. Heuristic gaps inherit the benchmark evidence class stored in each machine-readable row. The unavailable second-solver rows remain visible rather than being dropped.
