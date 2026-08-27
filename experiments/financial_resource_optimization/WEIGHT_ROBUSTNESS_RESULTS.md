# Financial retention-weight robustness results

Status: **LOCKED REPLAY, EXACTLY AUDITED, PRIOR OUTCOMES DISCLOSED**.

This analysis is not first-look evidence. The three schedules existed and had prior outcomes before the dedicated robustness lock. The lock prospectively fixed this subset and the identity, rank, burden, unique-carrier, and reporting rules; no schedule was fitted to these outputs.

All returned endpoints below passed exact mandatory-retention, frontier, closure, and burden checks. Global-optimum language is used only where human-proved optimum-preserving preprocessing rules reduced the exact model to an empty residual problem and the lifted solution passed an independent exact check. This is exact finite computation under a human proof, not Lean or solver proof.

## Terminal financial audit

| Schedule | Algorithm | Selected active | Exact burden | Burden saved share | Compression ratio | Rank | Exact optimum |
| --- | --- | --- | --- | --- | --- | --- | --- |
| equal_active_strategy | current_stepwise_safe_deletion | 25 | 25//1 | 11//16 | 5//16 | 1 | true |
| equal_active_strategy | heaviest_safe_first | 25 | 25//1 | 11//16 | 5//16 | 1 | true |
| equal_active_strategy | weighted_greedy | 25 | 25//1 | 11//16 | 5//16 | 1 | true |
| equal_active_strategy | weighted_greedy_reverse_delete | 25 | 25//1 | 11//16 | 5//16 | 1 | true |
| equal_active_strategy | multistart_random_deletion | 25 | 25//1 | 11//16 | 5//16 | 1 | true |
| equal_active_strategy | preprocessed_highs_mip | 25 | 25//1 | 11//16 | 5//16 | 1 | true |
| equal_active_strategy | requirement_mask_dp | — | — | — | — | — | — |
| equal_active_strategy | optional_second_solver_crosscheck | — | — | — | — | — | — |
| validation_computation | current_stepwise_safe_deletion | 25 | 450//1 | 554//779 | 5//16 | 6 | false |
| validation_computation | heaviest_safe_first | 25 | 338//1 | 610//779 | 5//16 | 1 | true |
| validation_computation | weighted_greedy | 26 | 344//1 | 607//779 | 13//40 | 4 | false |
| validation_computation | weighted_greedy_reverse_delete | 25 | 342//1 | 32//41 | 5//16 | 3 | false |
| validation_computation | multistart_random_deletion | 25 | 417//1 | 1141//1558 | 5//16 | 5 | false |
| validation_computation | preprocessed_highs_mip | 25 | 338//1 | 610//779 | 5//16 | 1 | true |
| validation_computation | requirement_mask_dp | — | — | — | — | — | — |
| validation_computation | optional_second_solver_crosscheck | — | — | — | — | — | — |
| governance_complexity | current_stepwise_safe_deletion | 25 | 96//1 | 109//157 | 5//16 | 6 | false |
| governance_complexity | heaviest_safe_first | 25 | 85//1 | 229//314 | 5//16 | 1 | true |
| governance_complexity | weighted_greedy | 25 | 85//1 | 229//314 | 5//16 | 1 | true |
| governance_complexity | weighted_greedy_reverse_delete | 25 | 85//1 | 229//314 | 5//16 | 1 | true |
| governance_complexity | multistart_random_deletion | 25 | 93//1 | 221//314 | 5//16 | 5 | false |
| governance_complexity | preprocessed_highs_mip | 25 | 85//1 | 229//314 | 5//16 | 1 | true |
| governance_complexity | requirement_mask_dp | — | — | — | — | — | — |
| governance_complexity | optional_second_solver_crosscheck | — | — | — | — | — | — |

Distinct active unique carriers: `3`. Every exactly feasible endpoint retained all of them.

| Schedule | Exact preprocessing optimum | Stepwise absolute gap | Stepwise relative gap |
| --- | --- | --- | --- |
| equal_active_strategy | 25//1 | 0//1 | 0//1 |
| validation_computation | 338//1 | 112//1 | 56//169 |
| governance_complexity | 85//1 | 11//1 | 11//85 |

| Algorithm | Equal rank | Validation rank | Governance rank | Top-rank schedules | Rank range |
| --- | --- | --- | --- | --- | --- |
| current_stepwise_safe_deletion | 1 | 6 | 6 | 1 | 5 |
| heaviest_safe_first | 1 | 1 | 1 | 3 | 0 |
| weighted_greedy | 1 | 4 | 1 | 2 | 3 |
| weighted_greedy_reverse_delete | 1 | 3 | 1 | 2 | 2 |
| multistart_random_deletion | 1 | 5 | 5 | 1 | 4 |
| preprocessed_highs_mip | 1 | 1 | 1 | 3 | 0 |
| requirement_mask_dp | — | — | — | 0 | — |
| optional_second_solver_crosscheck | — | — | — | 0 | — |

Schedule identity agreement for the same algorithm:

| Algorithm | Minimum Jaccard | Maximum Jaccard |
| --- | --- | --- |
| current_stepwise_safe_deletion | 1//1 | 1//1 |
| heaviest_safe_first | 3//22 | 2//3 |
| weighted_greedy | 13//38 | 7//10 |
| weighted_greedy_reverse_delete | 13//37 | 21//29 |
| multistart_random_deletion | 3//22 | 1//1 |
| preprocessed_highs_mip | 7//18 | 11//14 |

Postdecision held-out diagnostic: `8162187676336809//72057594037927936` in terminal locked-2020-2024 enabled-descendant net-utility opportunity units. It did not enter weights, algorithms, ranks, overlap, or exclusions.

## Annual walk-forward financial audit

| Schedule | Algorithm | Selected active | Exact burden | Burden saved share | Compression ratio | Rank | Exact optimum |
| --- | --- | --- | --- | --- | --- | --- | --- |
| equal_active_strategy | current_stepwise_safe_deletion | 100 | 100//1 | 51//101 | 50//101 | 1 | true |
| equal_active_strategy | heaviest_safe_first | 100 | 100//1 | 51//101 | 50//101 | 1 | true |
| equal_active_strategy | weighted_greedy | 100 | 100//1 | 51//101 | 50//101 | 1 | true |
| equal_active_strategy | weighted_greedy_reverse_delete | 100 | 100//1 | 51//101 | 50//101 | 1 | true |
| equal_active_strategy | multistart_random_deletion | 100 | 100//1 | 51//101 | 50//101 | 1 | true |
| equal_active_strategy | preprocessed_highs_mip | 100 | 100//1 | 51//101 | 50//101 | 1 | true |
| equal_active_strategy | requirement_mask_dp | — | — | — | — | — | — |
| equal_active_strategy | optional_second_solver_crosscheck | — | — | — | — | — | — |
| validation_computation | current_stepwise_safe_deletion | 100 | 1566//1 | 971//1754 | 50//101 | 5 | false |
| validation_computation | heaviest_safe_first | 100 | 1170//1 | 1169//1754 | 50//101 | 1 | true |
| validation_computation | weighted_greedy | 101 | 1172//1 | 584//877 | 1//2 | 4 | false |
| validation_computation | weighted_greedy_reverse_delete | 100 | 1170//1 | 1169//1754 | 50//101 | 1 | true |
| validation_computation | multistart_random_deletion | 100 | 1579//1 | 1929//3508 | 50//101 | 6 | false |
| validation_computation | preprocessed_highs_mip | 100 | 1170//1 | 1169//1754 | 50//101 | 1 | true |
| validation_computation | requirement_mask_dp | — | — | — | — | — | — |
| validation_computation | optional_second_solver_crosscheck | — | — | — | — | — | — |
| governance_complexity | current_stepwise_safe_deletion | 100 | 355//1 | 379//734 | 50//101 | 6 | false |
| governance_complexity | heaviest_safe_first | 100 | 315//1 | 419//734 | 50//101 | 1 | true |
| governance_complexity | weighted_greedy | 100 | 315//1 | 419//734 | 50//101 | 1 | true |
| governance_complexity | weighted_greedy_reverse_delete | 100 | 315//1 | 419//734 | 50//101 | 1 | true |
| governance_complexity | multistart_random_deletion | 100 | 350//1 | 192//367 | 50//101 | 5 | false |
| governance_complexity | preprocessed_highs_mip | 100 | 315//1 | 419//734 | 50//101 | 1 | true |
| governance_complexity | requirement_mask_dp | — | — | — | — | — | — |
| governance_complexity | optional_second_solver_crosscheck | — | — | — | — | — | — |

Distinct active unique carriers: `5`. Every exactly feasible endpoint retained all of them.

| Schedule | Exact preprocessing optimum | Stepwise absolute gap | Stepwise relative gap |
| --- | --- | --- | --- |
| equal_active_strategy | 100//1 | 0//1 | 0//1 |
| validation_computation | 1170//1 | 396//1 | 22//65 |
| governance_complexity | 315//1 | 40//1 | 8//63 |

| Algorithm | Equal rank | Validation rank | Governance rank | Top-rank schedules | Rank range |
| --- | --- | --- | --- | --- | --- |
| current_stepwise_safe_deletion | 1 | 5 | 6 | 1 | 5 |
| heaviest_safe_first | 1 | 1 | 1 | 3 | 0 |
| weighted_greedy | 1 | 4 | 1 | 2 | 3 |
| weighted_greedy_reverse_delete | 1 | 1 | 1 | 3 | 0 |
| multistart_random_deletion | 1 | 6 | 5 | 1 | 5 |
| preprocessed_highs_mip | 1 | 1 | 1 | 3 | 0 |
| requirement_mask_dp | — | — | — | 0 | — |
| optional_second_solver_crosscheck | — | — | — | 0 | — |

Schedule identity agreement for the same algorithm:

| Algorithm | Minimum Jaccard | Maximum Jaccard |
| --- | --- | --- |
| current_stepwise_safe_deletion | 1//1 | 1//1 |
| heaviest_safe_first | 3//22 | 17//23 |
| weighted_greedy | 77//123 | 31//36 |
| weighted_greedy_reverse_delete | 77//123 | 93//107 |
| multistart_random_deletion | 13//37 | 3//7 |
| preprocessed_highs_mip | 79//121 | 19//21 |

Postdecision held-out diagnostic: `7728204652088667//72057594037927936` in annual mean next-year enabled-descendant opportunity units. It did not enter weights, algorithms, ranks, overlap, or exclusions.

## Limits

Terminal and annual units are not pooled. Unavailable second-solver and inapplicable DP rows remain in the machine-readable summary. Strategy identifiers are aggregate library labels, not CRSP/WRDS rows. The study makes no causal, forecasting, alpha, or deployable-performance claim.
