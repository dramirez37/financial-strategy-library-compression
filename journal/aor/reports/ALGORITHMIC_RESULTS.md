# Audited algorithmic results: Registered Algorithmic Compression Benchmark v2

## Technical summary

This report analyzes only the committed, locked, independently audited v2 final records. The audit gate is **PASS**: all 3907 registered run units are terminal, all 3526 accepted libraries passed independent exact frontier, identity-closure, mandatory-retention, tagged-coverage, and burden rechecks, and the artifact audit recorded zero errors. Runtime evidence is conditional on the registered eight-worker environment; it is not pooled with v1.

Among 38 exact-capable instances, 31 had complete cross-method burden agreement, 7 were unavailable after recorded failures, and 9 agreed in burden while at least one returned optimizer identity differed. This is exact finite computation, not Lean verification. For Family B, 111/128 registered instances have an exactly feasible HiGHS-`OPTIMAL` reference; 112/128 instances generated successfully.

There were no `TIME_LIMIT` records, so timeout best-bound gaps are not numerically estimable; the empty machine table preserves that result. Multi-start completed all 32 registered starts on 143 rows and improved on start one on 96 of those rows.

## Key findings with visual evidence

- Exact methods agreed whenever the registered exact comparison was available; disagreement was never resolved by majority vote. Different optimizer identities at equal burden are retained as ties, not errors. See [exact-method agreement](../tables/exact_method_agreement.csv).

- Failed generation is the dominant unsuccessful category: 352 run units, arising from 16 structured registry instances. These rows remain in solved fractions, PAR-2, model populations, and failure tables.

- The 14 memory-limit records all belong to the primary mandatory-only 32-start deletion workflow; they are not silently replaced by the successful full-preprocessing sensitivity. See [complete statuses](../tables/failure_statuses.csv) and [multi-start improvements](../tables/multistart_improvement.csv).

- The performance, size-scaling, gap, preprocessing, and multi-start figures use the complete plotted populations and link back to [analysis_row_trace.csv](../tables/analysis_row_trace.csv). Aggregated figure rows include stable join keys; raw-point figure tables carry record paths and SHA-256 hashes.

## Primary heuristic-quality summaries

The following tables show every registered heuristic, not a selected subset. Attainment uses the full reference-available denominator; unsuccessful returned runs therefore count as nonattainment. Gap moments use exactly feasible returned solutions and state that smaller denominator explicitly.

### Family A: exact finite reference

| Algorithm | Attained/reference | Gap n | Mean relative gap | Median | q90 | Worst |
|---|---:|---:|---:|---:|---:|---:|
| Weighted greedy | 16/23 (69.57%) | 23 | 0.08684 | 0 | 0.25 | 0.5 |
| Cardinality greedy | 13/23 (56.52%) | 23 | 0.6375 | 0 | 1.4 | 7 |
| Weighted greedy + reverse deletion | 20/23 (86.96%) | 23 | 0.02923 | 0 | 0.16 | 0.25 |
| Heaviest safe first | 22/23 (95.65%) | 23 | 0.008696 | 0 | 0 | 0.2 |
| Lightest safe first | 5/23 (21.74%) | 23 | 1.586 | 1 | 3.32 | 7 |
| Maximum immediate release | 22/23 (95.65%) | 23 | 0.008696 | 0 | 0 | 0.2 |
| Minimum unique-carrier exposure | 17/23 (73.91%) | 23 | 0.2303 | 0 | 0.2686 | 3 |
| Declared source order | 11/23 (47.83%) | 23 | 0.6965 | 0.2857 | 2 | 3 |
| Random-order deletion | 8/23 (34.78%) | 23 | 1.384 | 0.6667 | 3.3 | 7 |
| 32-start random deletion | 23/23 (100%) | 23 | 0 | 0 | 0 | 0 |

### Family B: HiGHS-optimal, exactly rechecked reference

| Algorithm | Attained/reference | Gap n | Mean relative gap | Median | q90 | Worst |
|---|---:|---:|---:|---:|---:|---:|
| Weighted greedy | 82/111 (73.87%) | 111 | 0.02982 | 0 | 0.06452 | 0.5 |
| Cardinality greedy | 24/111 (21.62%) | 111 | 0.8904 | 0.25 | 2 | 7.5 |
| Weighted greedy + reverse deletion | 103/111 (92.79%) | 111 | 0.01038 | 0 | 0 | 0.5 |
| Heaviest safe first | 94/111 (84.68%) | 111 | 0.09983 | 0 | 0.2 | 3 |
| Lightest safe first | 11/111 (9.91%) | 111 | 4.128 | 0.7143 | 15 | 63 |
| Maximum immediate release | 94/111 (84.68%) | 111 | 0.09983 | 0 | 0.2 | 3 |
| Minimum unique-carrier exposure | 98/111 (88.29%) | 111 | 0.04435 | 0 | 0.05556 | 1 |
| Declared source order | 36/111 (32.43%) | 111 | 1.533 | 0.1818 | 5 | 20 |
| Random-order deletion | 28/111 (25.23%) | 111 | 1.753 | 0.2222 | 6.8 | 17 |
| 32-start random deletion | 76/111 (68.47%) | 97 | 0.1324 | 0 | 0.5 | 2.667 |

Absolute-gap means, medians, upper quantiles, and maxima are retained alongside these relative summaries in [heuristic_quality.csv](../tables/heuristic_quality.csv). The adversarial mechanisms are reported separately in [adversarial_family.csv](../tables/adversarial_family.csv), because pooling them with the random finite designs would obscure the registered constructions and evidence classes.

## Runtime and resource summaries

The complete per-family, per-size, per-algorithm [computational scaling table](../tables/computational_scaling.csv) reports solved fraction, solved-run wall-clock mean/median/q90/worst, PAR-2 mean/median/interquartile range/q90/worst, MIP nodes, DP states and transitions, and frontier/closure evaluation counts. The [certified deletion table](../tables/certified_deletion.csv) isolates exact semantic-check counts and final irreducibility certificates. [Preprocessing summaries](../tables/preprocessing_summary.csv) report variable and requirement reductions plus paired PAR-2 and node changes, while [multi-start summaries](../tables/multistart_summary.csv) report all registered improvement quantiles. [Timeout best-bound gaps](../tables/timeout_best_bound_gaps.csv) is deliberately header-only because no registered run ended at `TIME_LIMIT`.

## Scope, data, and metric definitions

The analysis population is the 173 `analysis_included=true` final registry instances and their 3,907 registered run units. Dry-run, pilot, v1, and untracked v1 output directories are excluded. Families are reported separately: 24 small exact, 128 structured finite-design, and 21 adversarial mechanism instances. Neither structured nor adversarial instances are a probability sample of real financial libraries.

For a returned exact burden `W` and a registered reference `W*`, absolute gap is `W-W*` and relative gap is `(W-W*)/W*`. Family A uses enumeration/DP exact finite agreement (plus the registered conclusive MIP gate); Family B uses an exactly rechecked, HiGHS-`OPTIMAL` mandatory-only reference. These evidence classes are never pooled in one claimed exact distribution. Optimum/reference-attainment denominators include every registered algorithm row for which the reference exists; an unsuccessful algorithm run does not attain it. Gap distributions require an exactly feasible returned burden and print their unavailable counts.

A run is solved only if it returned an exactly feasible candidate within both registered limits; exact methods additionally require complete search. PAR-2 equals observed supervisor wall time for solved rows and twice the registered limit otherwise. Unavailable nodes, states, frontier checks, and closure checks remain unavailable rather than zero. Quantile levels 0.10, 0.25, 0.50, 0.75, and 0.90 are registered. Because the plan did not name an interpolation convention, the generator uses deterministic Hyndman--Fan type 7 interpolation and records that completion explicitly.

## Methodology

The Julia 1.12.6 generator reads `results/final_algorithm_runs.csv`, the referenced raw TOML records, registry rows, generated instances, exactness certificates, and `audit_summary.toml`. It does not run a solver or algorithm. All burden arithmetic and gap construction originate in exact rational fields; floating point is used only for runtime, solver diagnostics, model fitting, and SVG coordinates.

Primary finite-design summaries report row counts, eligible denominators, unavailable counts, means, medians, interquartile ranges, registered quantiles, minima, and maxima. Runtime comparisons use solved fraction, empirical performance profiles, PAR-2, and paired PAR-2 differences. The registered Family B relative-gap models use `log(1+gap)`, the nine declared structural main effects, replicate block, fixed lane, and only the declared algorithm-by-size interactions. Registered penalized-runtime models use `log(PAR-2)`; logistic models target solved/not solved. HC3 standard errors and Holm adjustment are implemented directly with `LinearAlgebra`.

The registered model suite produced 19 fits and 4 declared failures or nonestimable specifications. A failed IRLS, separation, rank deficiency, or unavailable diagnostic is reported without changing links, penalties, or covariates. See [registered model diagnostics](../tables/registered_model_diagnostics.csv) and [coefficients](../tables/registered_model_coefficients.csv).

## Requested publication artifacts

Tables distinguish theorem/proof claims from exact computation and synthetic evidence:

1. [Algorithm guarantees](../tables/algorithm_guarantees.tex) — human proofs or transferred approximation theorem; no benchmark result establishes a guarantee.
2. [Exact-method agreement](../tables/exact_method_agreement.tex) — exact finite computation plus exact semantic audit; not Lean verification.
3. [Computational scaling](../tables/computational_scaling.tex) — synthetic runtime/resource evidence under eight-worker contention.
4. [Heuristic quality](../tables/heuristic_quality.tex) — exact or MIP-reference burden evidence, labeled per row.
5. [Adversarial family](../tables/adversarial_family.tex) — synthetic exact-feasibility computation; analytic ratios appear only for the proved heaviest-safe-first family.

Figures are publication SVGs with machine-readable sources: [performance profile](../figures/performance_profile.svg), [runtime versus size](../figures/runtime_vs_size.svg), [heuristic-gap heat map](../figures/heuristic_gap_heatmap.svg), [preprocessing reductions](../figures/preprocessing_reduction.svg), and [multi-start improvement](../figures/multistart_improvement.svg). Registered supplementary figures are [Family A gap distributions](../figures/family_a_exact_gap_distributions.svg), [Family B burden/runtime frontier](../figures/family_b_burden_runtime_frontier.svg), [solved-fraction grid](../figures/solved_fraction_grid.svg), [semantic evaluation counts](../figures/semantic_evaluation_counts.svg), and [adversarial mechanisms](../figures/adversarial_mechanisms.svg).

## EXPLORATORY — reference-attainment regression

The locked analysis plan does **not** prespecify a logistic regression for probability of exact optimum. It prespecifies an exact/reference-attainment frequency and a separate solved/not-solved logistic model. To avoid rewriting the registration after outcomes, the requested attainment regression is isolated here as `EXPLORATORY_NOT_PRESPECIFIED`; Family A targets exact finite attainment and Family B targets MIP-reference attainment. It must not be described as confirmatory. See [exploratory diagnostics](../tables/exploratory_reference_attainment_diagnostics.csv) and [coefficients](../tables/exploratory_reference_attainment_coefficients.csv).

## Limitations, uncertainty, and robustness

- Eight concurrent one-thread subprocesses define the runtime estimand. CPU, cache, and memory-bandwidth contention are part of v2; v1 timing is not pooled or compared numerically.
- Six adversarial enumeration runs ended in implementation error, seven run units were process-interrupted, fourteen primary multi-start rows hit the memory limit, and two MIP candidates were unavailable/rejected under exact binary-value handling. All remain visible.
- The 7 exact-capable instances without complete agreement have no inferred exact optimum in exact-gap summaries.
- HiGHS `OPTIMAL` plus an exact post-check is mixed-integer solver evidence, not a formal or exhaustive proof. No second solver was pinned.
- No timeout occurred, so the registered timeout-bound analysis is an explicit zero-row result rather than evidence about bound quality under time limits.
- Statistical intervals summarize the registered finite design. They do not license population, causal, forecasting, alpha, or deployable-performance claims.
- The benchmark is identity-closure only and supplies no algorithmic guarantee for arbitrary nonidentity closure.

## Validation report

**Overall assessment: Ready to share with stated caveats.** The source audit passes, exact-agreement counts reconcile to the committed audit, every generated result is traceable, failed-run denominators are retained, and no negative reference gap was observed. Remaining caveats are the registered unsuccessful rows, eight-worker conditionality, absent second solver, and the explicitly exploratory attainment regression.

Calculation spot-checks performed by the generator:

- terminal matrix: 3907 = 3907;
- exact agreements: 31 = 31;
- exact unavailable: 7 = 7;
- optimizer-identity differences: 9 = 9;
- time-limit rows: 0;
- generated artifacts listed in [ANALYSIS_ARTIFACT_MANIFEST.csv](../tables/ANALYSIS_ARTIFACT_MANIFEST.csv).

## Recommended next step

Integrate only the audited table/figure inputs selected by the locked manuscript architecture into Section 7, preserving the evidence-class captions and the failed-run caveats. Do not rerun or retune the benchmark.

## Further questions

The manuscript revision should decide which registered supplementary figures stay in the main article versus the online resource, without changing their data, denominators, axes, or evidence labels.
