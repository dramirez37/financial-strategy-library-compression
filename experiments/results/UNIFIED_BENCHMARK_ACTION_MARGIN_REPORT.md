# Unified Benchmark Exact Search and Action-Margin Report

The exact grid search selected `C0424` from 972 candidates; 601 passed every economic, separation, perturbation, and comparative-static gate.

This is deterministic Julia `Rational{BigInt}` validation evidence, not a theorem or a Lean proof. The legacy canonical benchmark remains an unchanged appendix compatibility fixture.

## Selected primitives

| Primitive | Exact value |
|---|---:|
| Discount | `1//2` |
| Discover cost, low belief | `1//32` |
| Discover cost, high belief | `1//1` |
| Scale cost | `3//16` |
| Scale admission | `3//4` |
| Survival | `1//1` |
| Scale raw generation, survival^duration | `1//1` |
| Scale admitted success | `3//4` |
| Scale duration | `2` |

## Exact policy, values, and action margins

| State | Belief | Value | Optimal action | Continue Q | Research Q | Margin |
|---|---|---:|---|---:|---:|---:|
| K0 | low | `115//288` | research:discover | `23//144` | `115//288` | `23//96` |
| K0 | high | `23//288` | continue | `23//288` | `-643//1152` | `245//384` |
| K1 | low | `1//1` | research:scale | `25//48` | `1//1` | `23//48` |
| K1 | high | `7//6` | research:scale | `9//16` | `7//6` | `29//48` |
| K2 | low | `14//3` | continue | `14//3` | `215//48` | `3//16` |
| K2 | high | `22//3` | continue | `22//3` | `343//48` | `3//16` |

The worst baseline action margin is `3//16`; the worst margin across all accepted local perturbations is `11//64`.

## Structural and solver checks

| Check | Result |
|---|---|
| `raw_library_count` | true |
| `compressed_state_count` | true |
| `representative_counts` | true |
| `positive_durations` | true |
| `full_path_lengths` | true |
| `terminal_kernel_power` | true |
| `unified_operation_flags` | true |
| `raw_policy_converged` | true |
| `compressed_policy_converged` | true |
| `raw_policy_equation_residual` | true |
| `compressed_policy_equation_residual` | true |
| `raw_bellman_residual` | true |
| `compressed_bellman_residual` | true |
| `raw_compressed_equal` | true |
| `policy_lift` | true |
| `value_iteration_converged` | true |
| `value_iteration_monotone` | true |
| `value_iteration_contraction` | true |
| `value_iteration_policy_matches` | true |
| Raw representatives K0/K1/K2 | 1/3/4 |
| Compressed policy iterations | 3 |
| Raw policy iterations | 3 |
| Exact value-iteration iterations | 41 |
| Exact value-iteration terminal residual | `42880953483265//77371252455336267181195264` |

Every project duration is positive. Completion support contains `duration + 1` beliefs, and each terminal marginal equals the corresponding row of `P^duration`. Research reward blocks are generated solely through each project's unified operating flag.

## Local perturbation stability

| Scenario | Baseline | Perturbed | Same policy | Minimum margin |
|---|---:|---:|---|---:|
| discover_cost_low_down | `1//32` | `1//64` | true | `3//16` |
| discover_cost_low_up | `1//32` | `3//64` | true | `3//16` |
| discover_cost_high_down | `1//1` | `15//16` | true | `3//16` |
| discover_cost_high_up | `1//1` | `17//16` | true | `3//16` |
| scale_cost_down | `3//16` | `11//64` | true | `11//64` |
| scale_cost_up | `3//16` | `13//64` | true | `13//64` |
| discount_down | `1//2` | `15//32` | true | `277950131//1558704128` |
| discount_up | `1//2` | `17//32` | true | `3//16` |
| scale_admission_down | `3//4` | `23//32` | true | `3//16` |
| scale_admission_up | `3//4` | `25//32` | true | `3//16` |
| survival_down | `1//1` | `31//32` | true | `3//16` |

## Comparative statics

| Axis | Level | Parameter | K1 low value | K1 high value |
|---|---|---:|---:|---:|
| cost | low | `1//16` | `17//15` | `13//10` |
| cost | high | `1//4` | `14//15` | `11//10` |
| duration | low | `1//1` | `13//6` | `17//6` |
| duration | high | `3//1` | `38//93` | `335//744` |
| discount | low | `2//5` | `55//128` | `339//640` |
| discount | high | `3//5` | `105//52` | `4143//1820` |
| admission | low | `2//3` | `11//12` | `13//12` |
| admission | high | `4//5` | `239//228` | `277//228` |
| survival | low | `3//4` | `142//219` | `12086//17739` |
| survival | high | `1//1` | `1//1` | `7//6` |

The exact directional gates require K1 value to fall with cost and duration and to rise with discount, admission, and survival. All five inequalities are strict for the selected candidate.

## Alternative-candidate rejection accounting

| Reason | Candidate count |
|---|---:|
| `dominated_by_selection_score` | 600 |
| `missing_descendant` | 6 |
| `missing_discovery` | 94 |
| `near_action_tie` | 292 |
| `perturbation_instability` | 79 |

The complete candidate-level parameters, margins, policy signatures, statuses, and rejection reasons are in `experiments/results/unified_benchmark_search.csv`.
