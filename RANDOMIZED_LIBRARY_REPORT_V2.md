# Randomized Library Report V2

## Registered result

The fixed registered run completed all **1024** exact trials. Every compressed state had an enumerated raw-library witness, every interaction observation had four raw corners, and every hard gate passed.

Frontier-only pruning produced positive dynamic loss in **398/1024** trials (38.87%). Its conditional mean positive loss was **124909129//78249984** and its maximum normalized loss was **84963//222163**.
Innovation-safe pruning produced positive loss in **0/1024** trials and passed exact zero frontier, closure, operational, generative, and total loss gates in every trial.

The mean compression ratios were **5//12** for frontier-only pruning and **1//8** for innovation-safe pruning.
Operationally silent generative assets occurred in **388/5120** source-asset observations (7.58%) and in **388/1024** libraries.

The raw-realizable interaction signs were **256** substitution, **141** complementarity, and **627** zero cases. Predicate-true rows obeyed the locked nonpositive-interaction gate.

## Design and exactness

The run used the complete locked 2^7 factorial registry, master seed `6075990691714899803`, all recorded derived seeds, horizon four, and exact `Rational{BigInt}` model arithmetic. The final estimate uses N=1,024 regardless of every earlier sequential sign.

The four libraries in each interaction rectangle were constructed from one catalog by commuting frontier and closure additions. Menus, candidate laws, completion paths, transitions, policies, and values were evaluated from those raw primitives. No compressed state, action menu, transition, or value was inserted directly.

## Hard gates

- `all_trials_completed`: `true`
- `all_trial_hard_gates`: `true`
- `every_compressed_state_has_raw_witness`: `true`
- `every_rectangle_has_four_raw_witnesses`: `true`
- `raw_compressed_values_agree`: `true`
- `innovation_safe_frontier_loss_zero`: `true`
- `innovation_safe_closure_loss_zero`: `true`
- `innovation_safe_operational_loss_zero`: `true`
- `innovation_safe_generative_loss_zero`: `true`
- `innovation_safe_total_loss_zero`: `true`
- `all_signed_decompositions_exact`: `true`
- `theorem_flags_mechanically_evaluated`: `true`
- `all_theorem_facing_outputs_exact`: `true`
- `predicate_true_interactions_nonpositive`: `true`
- `theorem_evidence_false`: `true`

## Precision diagnostics

Cumulative diagnostics are reported at N = 50, 100, 200, 300, 500, 750, 1,000, and 1,024. Tables retain exact counts and rational point estimates. Wilson intervals and MCSE square roots are descriptive presentation diagnostics only. Sparse-support warnings remain visible and never change the fixed maximum.

## Evidence boundary

These are finite-generator simulation results, not statistical claims about a real population and not Lean theorem evidence. The mechanically evaluated primitive-condition flags describe only the generated rows. The frozen N=90 pilot was not pooled and none of its files was overwritten.

## Artifact index

- `actions`: `experiments/results/summaries/randomized_library_v2_actions.csv`
- `assets`: `experiments/results/summaries/randomized_library_v2_assets.csv`
- `closures`: `experiments/results/summaries/randomized_library_v2_closures.csv`
- `factor_figure`: `manuscript/figures/randomized_library_v2_factor_contrasts.svg`
- `factor_stability`: `experiments/results/summaries/randomized_library_v2_stability_factor_summary.csv`
- `factor_summary`: `experiments/results/summaries/randomized_library_v2_factor_summary.csv`
- `interaction_signs`: `experiments/results/summaries/randomized_library_v2_interaction_signs.csv`
- `kernels`: `experiments/results/summaries/randomized_library_v2_kernels.csv`
- `method_figure`: `manuscript/figures/randomized_library_v2_method_comparison.svg`
- `method_summary`: `experiments/results/summaries/randomized_library_v2_method_summary.csv`
- `modules`: `experiments/results/summaries/randomized_library_v2_modules.csv`
- `prevalence_figure`: `manuscript/figures/randomized_library_v2_prevalence.svg`
- `profiles`: `experiments/results/summaries/randomized_library_v2_profiles.csv`
- `projects`: `experiments/results/summaries/randomized_library_v2_projects.csv`
- `pruning`: `experiments/results/summaries/randomized_library_v2_pruning.csv`
- `rectangle_corners`: `experiments/results/summaries/randomized_library_v2_rectangle_corners.csv`
- `rectangle_transitions`: `experiments/results/summaries/randomized_library_v2_rectangle_transitions.csv`
- `relationship_summary`: `experiments/results/summaries/randomized_library_v2_relationship_summary.csv`
- `report`: `RANDOMIZED_LIBRARY_REPORT_V2.md`
- `stability_figure`: `manuscript/figures/randomized_library_v2_stability.svg`
- `stability_summary`: `experiments/results/summaries/randomized_library_v2_stability_summary.csv`
- `summary`: `experiments/results/summaries/randomized_library_v2_summary.json`
- `trials`: `experiments/results/summaries/randomized_library_v2_trials.csv`
- `witness_manifest`: `experiments/results/summaries/randomized_library_v2_raw_witness_manifest.csv`
