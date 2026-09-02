# AoOR material migration map

Status: disposition lock; no file movement or deletion is authorized

Evidence cut: 2026-08-26

## Scope and disposition vocabulary

This inventory covers the result environments in the editable main manuscript,
Online Supplement, and current AOR overlay; all executable experiment
configurations plus the exact safe-compression reduction fixture; every file in
`manuscript/figures/`; and every labeled or standalone table object found in the
manuscript tree. Alias labels are kept on the same row as their result.

The five dispositions mean:

- **KEEP IN MAIN ARTICLE**: retain as a visible component of the main argument.
- **CONDENSE IN MAIN ARTICLE**: retain the claim or principal result in main,
  with proof/detail/secondary output elsewhere.
- **MOVE TO ONLINE RESOURCE**: remove from main but retain in the submitted
  Online Resource.
- **RETAIN ONLY IN REPOSITORY**: retain for provenance or reproducibility but do
  not submit as article or Online Resource content.
- **REMOVE FROM JOURNAL VERSION**: exclude from both article and Online Resource
  under the locked paper identity. The source remains untouched in this task and
  recoverable in repository history.

An intended but absent object has no migration disposition. It is listed at the
end as a future gate.

## Existing mathematical results

| ID / title | Current source | Disposition | Journal role or reason |
|---|---|---|---|
| `lem:frontier-closure-calculus`, Finite-library frontier and closure calculus | `manuscript/appendices/a_additional_formal_definitions.tex` | MOVE TO ONLINE RESOURCE | Foundational finite identities; useful proof support but not a headline result. |
| `thm:raw-to-compressed-projection`, Raw-to-compressed controlled Markov projection | `manuscript/sections/03_model.tex` | KEEP IN MAIN ARTICLE | Establishes the productive library state under the declared controlled process. |
| `thm:minimum-safe-compression`, Minimum-resource innovation-safe representation | `manuscript/sections/04_dynamic_innovation_equivalence.tex` | KEEP IN MAIN ARTICLE | Defines the exact source-relative retention problem. |
| `thm:raw-frontier-closure-characterization` (alias `thm:unified-safe-deletion`), Frontier--closure characterization and safe deletion | `manuscript/sections/04_dynamic_innovation_equivalence.tex` | KEEP IN MAIN ARTICLE | Central exact characterization connecting semantics to feasibility. |
| `cor:stepwise-safe-compression`, Rechecked pruning certificate | `manuscript/sections/04_dynamic_innovation_equivalence.tex` | CONDENSE IN MAIN ARTICLE | Short algorithmic corollary; full proof and implementation detail belong online. |
| `prop:certified-pruning`, Certified pruning specification | `manuscript/sections/04_dynamic_innovation_equivalence.tex` | CONDENSE IN MAIN ARTICLE | Supplies the exact postcheck contract for certified deletion. |
| `thm:local-global-safe-compression`, Local/global boundary | `manuscript/sections/04_dynamic_innovation_equivalence.tex` | KEEP IN MAIN ARTICLE | Establishes the proved qualitative distinction between local irreducibility and global minimum burden. |
| `thm:normalized-frontier-pruning-loss`, Sharp normalized frontier-only relaxation loss | `manuscript/sections/05_innovation_safe_compression.tex` and AOR overlay | KEEP IN MAIN ARTICLE | Direct economic consequence of ignoring closure. |
| `thm:scaled-frontier-pruning-loss`, Arbitrary additive loss only by scaling | `manuscript/sections/05_innovation_safe_compression.tex` and AOR overlay | MOVE TO ONLINE RESOURCE | Important normalization caveat, but secondary to the sharp normalized result. |
| `thm:capacity-value`, Finite capacity-constrained retention | `manuscript/sections/05_innovation_safe_compression.tex` and AOR overlay | CONDENSE IN MAIN ARTICLE | Supports Section 6 without reopening the full dynamic application. |
| `thm:penalized-envelope`, Finite penalized value envelope | `manuscript/sections/05_innovation_safe_compression.tex` and AOR overlay | CONDENSE IN MAIN ARTICLE | Supports resource-price interpretation; details and breakpoint records move online. |
| `thm:aor-safe-compression-complexity`, Identity-closure safe-compression complexity | `journal/aor/sections/05_innovation_safe_compression.tex` | KEEP IN MAIN ARTICLE | Core intended OR result, conditional on final proof review; human-readable only, not Lean-verified. |
| `thm:value-decomposition`, Operational--generative value decomposition | `manuscript/sections/06_operational_generative_value.tex` | CONDENSE IN MAIN ARTICLE | Interpretive bridge for economic consequences. |
| `cor:frontier-silent-insertion`, Frontier-silent insertion | `manuscript/sections/06_operational_generative_value.tex` | CONDENSE IN MAIN ARTICLE | Gives the cleanest mechanism for closure value without frontier change. |
| `thm:generative-carrier-lower-bound`, Joint descendant-event generative-option lower bound | `manuscript/sections/06_operational_generative_value.tex` | MOVE TO ONLINE RESOURCE | Technical support for the mechanism; not necessary to carry the main OR spine. |
| `cor:t6-independent-product` (alias `cor:t6-comparative-statics`), Product specialization and signs | `manuscript/sections/06_operational_generative_value.tex` | MOVE TO ONLINE RESOURCE | Specialized interpretation of the lower bound. |
| `prop:finite-horizon-action-attainment` (alias `thm:finite-state-contraction`), Finite-state contraction and selectors | `manuscript/sections/08_dynamic_research_control.tex` | MOVE TO ONLINE RESOURCE | Validates the downstream finite control application, not the retention problem itself. |
| `prop:premium-monotonicity`, Research-premium monotonicity under project dominance | `manuscript/appendices/b_long_proofs.tex` | MOVE TO ONLINE RESOURCE | Secondary economic monotonicity. |
| `prop:channel-elasticity`, Operational--generative elasticity contributions | `manuscript/appendices/c_comparative_statics.tex` | MOVE TO ONLINE RESOURCE | Secondary sensitivity calculation. |
| `cx:raw-identifier-generator`, Raw identifiers defeat frontier--closure sufficiency | `manuscript/appendices/a_structural_counterexamples.tex` | MOVE TO ONLINE RESOURCE | Necessary boundary example for the semantic reduction. |
| `cx:raw-closure-invisible`, Behaviorally invisible raw closure | `manuscript/appendices/a_structural_counterexamples.tex` | MOVE TO ONLINE RESOURCE | Necessary boundary example for library-invariant primitives. |
| `thm:passive-innovation-equation`, Passive gap-sum identity | `manuscript/online_supplement/s1_belief_occupation_coverage.tex` | MOVE TO ONLINE RESOURCE | Supports interpretation of operating gains without occupying main. |
| `cor:zero-current-gap-positive-future-value`, Zero current gap, positive future operating value | `manuscript/online_supplement/s1_belief_occupation_coverage.tex` | MOVE TO ONLINE RESOURCE | Compact supporting mechanism. |
| `prop:diminishing-operational-innovation`, Diminishing marginal operational innovation | `manuscript/online_supplement/s1_belief_occupation_coverage.tex` | MOVE TO ONLINE RESOURCE | Secondary property of the operating component. |
| `thm:coverage-potential-representation`, Exact finite coverage representation | `manuscript/online_supplement/s1_belief_occupation_coverage.tex` | MOVE TO ONLINE RESOURCE | Supporting occupation-coverage branch retained outside the main compression spine. |
| `cor:coverage-potential-bounds`, Finite occupation bounds | same | REMOVE FROM JOURNAL VERSION | Dependent coverage result outside the narrowed contribution. |
| `thm:finite-monotone-coverage`, Monotone-gap upper-threshold theorem | same | REMOVE FROM JOURNAL VERSION | Comparative-statics geometry is not a principal contribution here. |
| `thm:discount-survival-complementarity`, Finite patience--survival complementarity | same | MOVE TO ONLINE RESOURCE | Secondary comparative statics retained outside the journal spine. |
| `prop:no-universal-persistence-sign`, Opposite persistence effects | same | REMOVE FROM JOURNAL VERSION | Boundary result for the removed coverage branch. |
| `thm:kernel-occupation-alignment`, Advantage-region occupation alignment | same | REMOVE FROM JOURNAL VERSION | Kernel geometry lies outside the exact compression focus. |
| `thm:frontier-closure-substitution`, Frontier--closure substitution under relative saturation | `manuscript/online_supplement/s2_frontier_closure_interaction.tex` | MOVE TO ONLINE RESOURCE | Preserved as extended theory without creating a second main-paper arc. |
| `prop:primitive-frontier-saturation`, Primitive common-gap frontier saturation | same | REMOVE FROM JOURNAL VERSION | Technical support for the removed interaction arc. |
| `prop:t7-interaction-examples`, Complementarity from project switching | same | REMOVE FROM JOURNAL VERSION | Example family is not needed for the locked OR contribution. |
| `prop:one-shot-cutoff-comparative-statics`, One-shot cutoff comparative statics | `manuscript/online_supplement/s3_comparative_statics_counterexamples.tex` | MOVE TO ONLINE RESOURCE | One-shot coverage geometry is supporting material outside the main article. |
| `cx:single-peaked-disconnected`, A nonmonotone kernel defeats the upper threshold | same | REMOVE FROM JOURNAL VERSION | Counterexample belongs only to the removed coverage branch. |
| `cx:arbitrary-cost-disconnected`, Non-antitone cost disconnects a monotone covering set | same | REMOVE FROM JOURNAL VERSION | Counterexample belongs only to the removed coverage branch. |
| `cx:multi-gap-disconnection`, One-project multi-gap disconnection | same | REMOVE FROM JOURNAL VERSION | Counterexample belongs only to the removed coverage branch. |
| `cx:arbitrary-cost-components`, Arbitrary cost defeats a component bound | same | REMOVE FROM JOURNAL VERSION | Counterexample belongs only to the removed coverage branch. |

Three labeled prose statements in
`manuscript/appendices/a_additional_formal_definitions.tex`—
`prop:di-equivalence-relation`, `thm:di-quotient-sufficiency`, and
`prop:di-refinement-minimality`—are **MOVE TO ONLINE RESOURCE**. They are
auxiliary semantic results rather than standalone environment objects in the
current source.

No disposition changes a theorem's assumptions or conclusion. Aliases must be
consolidated during editing so the journal version has one stable label per
retained result.

## Existing experiments and computational records

The experiment unit below is the executable configuration/registered study
family, not each generated row. Existing design locks and results remain
immutable even when presentation moves.

| Experiment or fixture | Primary configuration or record | Disposition | Journal role or reason |
|---|---|---|---|
| Approximate compression | `experiments/configs/approximate_compression.toml` | RETAIN ONLY IN REPOSITORY | Preliminary tolerance-based problem; must not blur exact preservation. |
| Legacy canonical discounted DP | `experiments/configs/canonical_discounted_dp.toml` | RETAIN ONLY IN REPOSITORY | Superseded canonical path retained for provenance. |
| Early compression experiments | `experiments/configs/compression_experiments.toml` | RETAIN ONLY IN REPOSITORY | Development fixtures superseded by exact registered and financial records. |
| Coverage geometry | `experiments/configs/coverage_geometry.toml` | REMOVE FROM JOURNAL VERSION | Supports the removed coverage branch. |
| Annual-universe construction audit | `experiments/configs/financial_annual_universe_audit.toml` | MOVE TO ONLINE RESOURCE | Documents the larger-universe information set and selection boundary. |
| Annual walk-forward financial audit | `experiments/configs/financial_annual_walkforward_audit.toml`; `experiments/financial_annual_walkforward_audit/` | RETAIN ONLY IN REPOSITORY | Superseded financial case retained as historical provenance. |
| Cross-audit financial resource optimization | `experiments/configs/financial_resource_optimization.toml`; `experiments/financial_resource_optimization/` | RETAIN ONLY IN REPOSITORY | Superseded algorithm-comparison case retained as historical provenance. |
| Locked financial weight robustness | `experiments/financial_resource_optimization/WEIGHT_ROBUSTNESS_PROTOCOL.md`; public aggregate robustness tables | RETAIN ONLY IN REPOSITORY | Superseded weight replay and empty-residual certificates remain auditable but are not active journal evidence. |
| Terminal financial audit | `experiments/configs/financial_terminal_audit.toml`; `experiments/financial_terminal_audit/` | RETAIN ONLY IN REPOSITORY | Superseded financial case retained as historical provenance. |
| Point-in-Time Portfolio-Library Retention Study | `experiments/financial_strategy_library_panel_v3/` | KEEP IN MAIN ARTICLE | Primary retrospective financial case: structural compression, protected proposal policy, transparent held-out null/adverse result, and licensed-data boundary. |
| Calibrated Closure-Option Mechanism Experiment | `experiments/financial_strategy_library_panel_v4/` | KEEP IN MAIN ARTICLE | Synthetic mechanism evidence in Section 6; never relabeled as financial or market evidence. |
| Joint-descendant bound gauntlet | `experiments/configs/joint_descendant_bound_gauntlet.toml` | MOVE TO ONLINE RESOURCE | Exact/numerical support for the lower-bound result moved online. |
| Kernel persistence response | `experiments/configs/kernel_persistence_response.toml` | REMOVE FROM JOURNAL VERSION | Supports removed occupation/kernel theory. |
| Multi-gap topology | `experiments/configs/multi_gap_topology.toml` | REMOVE FROM JOURNAL VERSION | Supports removed coverage counterexamples. |
| Primitive substitution search | `experiments/configs/primitive_substitution_search.toml` | REMOVE FROM JOURNAL VERSION | Supports removed frontier--closure interaction theory. |
| Frozen randomized execution amendment 2 | `experiments/configs/randomized_library_execution_amendment_2.toml` | MOVE TO ONLINE RESOURCE | Historical registered (N=1024) execution record; immutable and not the new algorithm benchmark. |
| Frozen randomized optimization extension v1 | `experiments/configs/randomized_library_optimization_extension_v1.toml`; `experiments/randomized_library_v2_optimization/` | MOVE TO ONLINE RESOURCE | Historical resource-optimization extension; immutable prior evidence. |
| Frozen randomized stability amendment 1 | `experiments/configs/randomized_library_stability_amendment_1.toml` | MOVE TO ONLINE RESOURCE | Historical stability record; immutable. |
| Randomized (N=90) pilot | `experiments/configs/randomized_library_stress.toml` | RETAIN ONLY IN REPOSITORY | Pilot provenance; not needed in the submitted resource. |
| Frozen randomized library v2 parent study | `experiments/configs/randomized_library_stress_v2.toml`; `experiments/randomized_library_v2/` | MOVE TO ONLINE RESOURCE | Prior structural evidence only; immutable and distinct from proposed scaling study. |
| Resource-optimization counterexamples | `experiments/configs/resource_optimization_counterexamples.toml` | CONDENSE IN MAIN ARTICLE | Exact fixed local/global witnesses; full fixture online or repository. |
| Revision counterexample gauntlet | `experiments/configs/revision_counterexample_gauntlet.toml` | RETAIN ONLY IN REPOSITORY | Development/adversarial audit trail. |
| Single-gap geometry | `experiments/configs/single_gap_geometry.toml` | REMOVE FROM JOURNAL VERSION | Supports removed coverage theory. |
| Strategy-value figure experiment | `experiments/configs/strategy_value_figure.toml` | RETAIN ONLY IN REPOSITORY | Superseded exposition asset. |
| System interaction surface | `experiments/configs/system_interaction_surface.toml` | REMOVE FROM JOURNAL VERSION | Broad interaction surface outside the locked contribution. |
| Theorem feasibility fixtures | `experiments/configs/theorem_feasibility.toml` | RETAIN ONLY IN REPOSITORY | Internal exact fixture/oracle support, not standalone evidence. |
| Theorem-mechanism figures | `experiments/configs/theorem_mechanisms.toml` | RETAIN ONLY IN REPOSITORY | Superseded explanatory figure family. |
| Unified benchmark search | `experiments/configs/unified_benchmark_search.toml` | RETAIN ONLY IN REPOSITORY | Calibration/search trail, not confirmatory evidence. |
| Unified benchmark selected | `experiments/configs/unified_benchmark_selected.toml` | RETAIN ONLY IN REPOSITORY | Selection trail for the canonical example. |
| Unified canonical benchmark | `experiments/configs/unified_canonical_benchmark.toml` | MOVE TO ONLINE RESOURCE | Complete dynamic-control example supporting economic interpretation. |
| Unified canonical resources | `experiments/configs/unified_canonical_resources.toml` | MOVE TO ONLINE RESOURCE | Exact capacity/price paths supporting condensed Section 6 claims. |
| Unified comparative statics | `experiments/configs/unified_comparative_statics.toml` | MOVE TO ONLINE RESOURCE | Broad comparative-statics records retained as supporting material, not a main contribution. |
| Unified elasticity and switching v1 | `experiments/configs/unified_elasticity_switching_v1.toml` | REMOVE FROM JOURNAL VERSION | Broad sensitivity surface outside scope. |
| SC-COMP exact reduction fixture | `experiments/results/safe_compression_complexity_reduction_fixture.json` | MOVE TO ONLINE RESOURCE | Exact finite validation of the complexity construction; not a proof. |

Registered Algorithmic Compression Benchmark v2 is the only final algorithmic
study assigned to the journal article. Its compact audited summaries are kept
in Section 7 and its complete rows and figures move to Online Resource 1. The
incomplete v1 output directory is excluded, and neither study reuses or alters
the frozen (N=1024) registry, seeds, locks, amendments, or results.

## Existing figures

| Figure source | Disposition | Journal role or reason |
|---|---|---|
| `manuscript/figures/approximate_compression_pareto.svg` | RETAIN ONLY IN REPOSITORY | Approximate-problem evidence outside the exact claim. |
| `manuscript/figures/approximate_compression_search.svg` | RETAIN ONLY IN REPOSITORY | Approximate-problem search record. |
| `manuscript/figures/canonical_compressed_transition.tex` | RETAIN ONLY IN REPOSITORY | Legacy canonical transition asset superseded by unified version. |
| `manuscript/figures/canonical_convergence.tex` | RETAIN ONLY IN REPOSITORY | Legacy convergence asset superseded by unified version. |
| `manuscript/figures/coverage_connected_disconnected.svg` | REMOVE FROM JOURNAL VERSION | Removed coverage branch. |
| `manuscript/figures/coverage_discounted_occupation.svg` | REMOVE FROM JOURNAL VERSION | Removed coverage branch. |
| `manuscript/figures/coverage_frontier_candidate_gap.svg` | REMOVE FROM JOURNAL VERSION | Removed coverage branch. |
| `manuscript/figures/coverage_potential.svg` | REMOVE FROM JOURNAL VERSION | Removed coverage branch. |
| `manuscript/figures/coverage_research_region_boundaries.svg` | REMOVE FROM JOURNAL VERSION | Removed coverage branch. |
| `manuscript/figures/dynamic_research_policy_regions.tex` | MOVE TO ONLINE RESOURCE | Complete downstream control-policy illustration. |
| `manuscript/figures/financial_annual_walkforward_audit_mechanisms.svg` | MOVE TO ONLINE RESOURCE | Secondary annual-audit mechanism evidence. |
| `manuscript/figures/financial_annual_walkforward_audit_ranking.svg` | MOVE TO ONLINE RESOURCE | Secondary ex-post ranking evidence; must retain nonforecasting boundary. |
| `manuscript/figures/financial_annual_walkforward_audit_universe.svg` | MOVE TO ONLINE RESOURCE | Audit-design and universe support. |
| `manuscript/figures/financial_coverage_comparison.tex` | MOVE TO ONLINE RESOURCE | Secondary cross-audit comparison. |
| `manuscript/figures/financial_innovation_safe_compression.tex` | KEEP IN MAIN ARTICLE | Principal visual comparison for the two financial audits. |
| `manuscript/figures/financial_terminal_audit_candidate_ranking.svg` | MOVE TO ONLINE RESOURCE | Secondary ex-post terminal-audit evidence. |
| `manuscript/figures/financial_terminal_audit_decomposition.svg` | MOVE TO ONLINE RESOURCE | Full terminal mechanism decomposition. |
| `manuscript/figures/financial_terminal_audit_frontier_pruning.svg` | MOVE TO ONLINE RESOURCE | Full frontier-only comparison. |
| `manuscript/figures/innovation_safe_bridge.tex` | KEEP IN MAIN ARTICLE | Motivating operating-versus-generative bridge. |
| `manuscript/figures/randomized_library_factor_contrasts.svg` | RETAIN ONLY IN REPOSITORY | Pilot figure superseded by frozen v2 study. |
| `manuscript/figures/randomized_library_method_comparison.svg` | RETAIN ONLY IN REPOSITORY | Pilot figure superseded by frozen v2 study. |
| `manuscript/figures/randomized_library_prevalence.svg` | RETAIN ONLY IN REPOSITORY | Pilot figure superseded by frozen v2 study. |
| `manuscript/figures/randomized_library_v2_factor_contrasts.svg` | MOVE TO ONLINE RESOURCE | Frozen prior structural evidence. |
| `manuscript/figures/randomized_library_v2_method_comparison.svg` | MOVE TO ONLINE RESOURCE | Frozen prior method comparison, not the new benchmark. |
| `manuscript/figures/randomized_library_v2_optimization_v1_channel_contributions.svg` | MOVE TO ONLINE RESOURCE | Frozen optimization-extension evidence. |
| `manuscript/figures/randomized_library_v2_optimization_v1_greedy_gap.svg` | MOVE TO ONLINE RESOURCE | Existing heuristic-gap evidence without a new approximation claim. |
| `manuscript/figures/randomized_library_v2_optimization_v1_resource_demand.svg` | MOVE TO ONLINE RESOURCE | Frozen resource-demand evidence. |
| `manuscript/figures/randomized_library_v2_optimization_v1_value_capacity.svg` | MOVE TO ONLINE RESOURCE | Frozen capacity evidence. |
| `manuscript/figures/randomized_library_v2_prevalence.svg` | MOVE TO ONLINE RESOURCE | Frozen prior structural evidence. |
| `manuscript/figures/randomized_library_v2_stability.svg` | MOVE TO ONLINE RESOURCE | Frozen stability evidence. |
| `manuscript/figures/strategy_innovation_equation.tex` | RETAIN ONLY IN REPOSITORY | Superseded conceptual exposition. |
| `manuscript/figures/theorem_mechanism_coverage_geometry.svg` | RETAIN ONLY IN REPOSITORY | Supporting development visualization for removed branch. |
| `manuscript/figures/theorem_mechanism_coverage_ranking.svg` | RETAIN ONLY IN REPOSITORY | Supporting development visualization. |
| `manuscript/figures/theorem_mechanism_policy_map.svg` | RETAIN ONLY IN REPOSITORY | Supporting development visualization. |
| `manuscript/figures/theorem_mechanism_pruning_loss.svg` | RETAIN ONLY IN REPOSITORY | Superseded by a more direct main presentation. |
| `manuscript/figures/theorem_mechanism_value_decomposition.svg` | RETAIN ONLY IN REPOSITORY | Superseded by condensed analytic treatment. |
| `manuscript/figures/unified_canonical_convergence.tex` | MOVE TO ONLINE RESOURCE | Numerical convergence record. |
| `manuscript/figures/unified_canonical_resource_library_path.svg` | MOVE TO ONLINE RESOURCE | Detailed capacity/retention path. |
| `manuscript/figures/unified_canonical_resource_switching.svg` | MOVE TO ONLINE RESOURCE | Detailed price-switching path. |
| `manuscript/figures/unified_canonical_resource_value_capacity.svg` | MOVE TO ONLINE RESOURCE | Detailed value-capacity path. |
| `manuscript/figures/unified_canonical_resource_value_price.svg` | MOVE TO ONLINE RESOURCE | Detailed value-price path. |
| `manuscript/figures/unified_canonical_transition.tex` | MOVE TO ONLINE RESOURCE | Complete finite transition diagram. |
| `manuscript/figures/unified_comparative_statics_policy.svg` | MOVE TO ONLINE RESOURCE | Broad comparative-statics branch retained only as supporting evidence. |
| `manuscript/figures/unified_comparative_statics_value.svg` | MOVE TO ONLINE RESOURCE | Broad comparative-statics branch retained only as supporting evidence. |
| `manuscript/figures/unified_economic_geometry.tex` | CONDENSE IN MAIN ARTICLE | At most one compact composite for capacity and price consequences. |
| `manuscript/figures/unified_elasticity_switching_v1_innovation_duration.svg` | REMOVE FROM JOURNAL VERSION | Broad elasticity branch. |
| `manuscript/figures/unified_elasticity_switching_v1_margin_elasticity.svg` | REMOVE FROM JOURNAL VERSION | Broad elasticity branch. |
| `manuscript/figures/unified_elasticity_switching_v1_penalized_envelope.svg` | REMOVE FROM JOURNAL VERSION | Detailed surface redundant with condensed envelope result. |
| `manuscript/figures/unified_elasticity_switching_v1_selected_burden.svg` | REMOVE FROM JOURNAL VERSION | Broad elasticity branch. |
| `manuscript/figures/unified_elasticity_switching_v1_switching_map.svg` | REMOVE FROM JOURNAL VERSION | Broad elasticity branch. |
| `manuscript/figures/unified_elasticity_switching_v1_value_capacity.svg` | REMOVE FROM JOURNAL VERSION | Broad elasticity branch. |

## Existing tables

Where a table body is generated in `manuscript/tables/`, that source is named
on the same row as its caption/label. Repeated inclusions are treated as one
content object unless the main and supplement provide materially different
records.

| Table object | Current source | Disposition | Journal role or reason |
|---|---|---|---|
| `tab:aor-approximate-compression`, approximate-compression summary | `journal/aor/sections/09_canonical_finite_model.tex`; generated AOR summary | RETAIN ONLY IN REPOSITORY | Preliminary approximate problem is outside the exact paper. |
| `tab:canonical-channel-elasticities` | `manuscript/appendices/c_comparative_statics.tex`; `manuscript/tables/unified_canonical_resource_channel_elasticities.tex` | MOVE TO ONLINE RESOURCE | Secondary channel sensitivities. |
| `tab:canonical-exact-solution` | `manuscript/sections/08_dynamic_research_control.tex`; `manuscript/tables/main_canonical_stationary_solution.tex` | MOVE TO ONLINE RESOURCE | Complete canonical dynamic solution. |
| `tab:canonical-verification-record` | `manuscript/appendices/d_numerical_convergence.tex` | MOVE TO ONLINE RESOURCE | Numerical verification record, with exact/numerical distinctions retained. |
| `tab:financial-annual-walkforward` | `manuscript/sections/financial_annual_walkforward_audit.tex` | RETAIN ONLY IN REPOSITORY | Standalone generated table is superseded by the cross-audit main table; values remain available. |
| `tab:financial-information-sets` | `manuscript/appendices/e_experiment_protocol.tex` | CONDENSE IN MAIN ARTICLE | A compact information-timing table is needed to make leakage boundaries auditable. |
| `tab:financial-resource-compression` | `manuscript/sections/10_financial_compression_audit.tex`; `manuscript/tables/main_financial_resource_compression.tex` | KEEP IN MAIN ARTICLE | Principal two-audit resource comparison. |
| `tab:financial-terminal-audit` | `manuscript/sections/financial_terminal_audit.tex` | RETAIN ONLY IN REPOSITORY | Standalone generated table is superseded by the cross-audit main table. |
| `tab:manuscript-lean-correspondence` | `manuscript/online_supplement/lean_correspondence.tex` | RETAIN ONLY IN REPOSITORY | Current long-form correspondence is an audit artifact; a shorter ledger-derived status table may be generated online later. |
| `tab:randomized-optimization-summary` | `manuscript/sections/09_canonical_finite_model.tex`; `manuscript/tables/main_randomized_optimization_summary.tex` | MOVE TO ONLINE RESOURCE | Frozen prior optimization evidence, not the new algorithm benchmark. |
| `tab:randomized-price-elasticities` | same section; `manuscript/tables/main_randomized_price_elasticities.tex` | MOVE TO ONLINE RESOURCE | Frozen prior price evidence. |
| `tab:supp-action-values` | `manuscript/online_supplement/s4_complete_canonical_numerical_records.tex` | MOVE TO ONLINE RESOURCE | Complete canonical numerical record. |
| `tab:supp-capacity-paths` | same | MOVE TO ONLINE RESOURCE | Complete capacity path. |
| `tab:supp-convergence-history` | same | MOVE TO ONLINE RESOURCE | Full convergence history. |
| `tab:supp-financial-design-summary` | `manuscript/online_supplement/s6_full_financial_audit_secondary_tests.tex`; `manuscript/tables/financial_design_summary.tex` | MOVE TO ONLINE RESOURCE | Full audit design and information boundaries. |
| `tab:supp-horizon-actions` | `manuscript/online_supplement/s4_complete_canonical_numerical_records.tex` | MOVE TO ONLINE RESOURCE | Complete horizon record. |
| `tab:supp-horizon-values` | same | MOVE TO ONLINE RESOURCE | Complete horizon record. |
| `tab:supp-numerical-mechanisms` | `manuscript/online_supplement/s5_complete_registered_randomized_study.tex`; `manuscript/tables/numerical_mechanism_summary.tex` | MOVE TO ONLINE RESOURCE | Frozen mechanism summary. |
| `tab:supp-operating-rewards` | `manuscript/online_supplement/s4_complete_canonical_numerical_records.tex` | MOVE TO ONLINE RESOURCE | Complete canonical rewards. |
| `tab:supp-pairwise-crossings` | same | MOVE TO ONLINE RESOURCE | Exact candidate crossings and filtering detail. |
| `tab:supp-path-admission-atoms` | same | MOVE TO ONLINE RESOURCE | Complete finite transition atoms. |
| `tab:supp-penalized-intervals` | same | MOVE TO ONLINE RESOURCE | Exact penalized-envelope intervals. |
| `tab:supp-randomized-library-v2` | `manuscript/online_supplement/s5_complete_registered_randomized_study.tex` | MOVE TO ONLINE RESOURCE | Frozen (N=1024) aggregate record. |
| `tab:supp-randomized-pilot-comparison` | same | MOVE TO ONLINE RESOURCE | Historical pilot provenance retained and explicitly excluded from final-evidence claims. |
| `tab:supp-randomized-v2-stability-events` | same | MOVE TO ONLINE RESOURCE | Frozen stability events. |
| `tab:supp-randomized-v2-stability-means` | same | MOVE TO ONLINE RESOURCE | Frozen stability means. |
| `tab:supp-safe-compression` | `manuscript/online_supplement/s4_complete_canonical_numerical_records.tex`; related generated table `manuscript/tables/appendix_canonical_safe_compression.tex` | MOVE TO ONLINE RESOURCE | Exact canonical compression record. |
| `tab:supp-stationary-solution` | same; `manuscript/tables/main_canonical_stationary_solution.tex` | MOVE TO ONLINE RESOURCE | Complete stationary solution. |
| Main local/global greedy comparison (unlabeled) | `manuscript/tables/main_greedy_global_comparison.tex`, included by `manuscript/sections/04_dynamic_innovation_equivalence.tex` | CONDENSE IN MAIN ARTICLE | Compact exact witness for the proved local/global distinction; must not imply a worst-case ratio. |
| Main validation/evidence-status matrix (unlabeled) | `manuscript/appendices/f_validation_status.tex` | MOVE TO ONLINE RESOURCE | Useful evidence-class summary, too detailed for main. |
| Comparative-statics direction table (unlabeled) | `manuscript/online_supplement/s3_comparative_statics_counterexamples.tex` | MOVE TO ONLINE RESOURCE | Supporting table retained outside the main compression argument. |
| Detailed result-by-result validation matrix (unlabeled) | `manuscript/online_supplement/validation_matrix.tex` | RETAIN ONLY IN REPOSITORY | Repository audit trail; replace any submitted status table from the authoritative ledger. |
| One-page manuscript/formal summary (unlabeled) | `manuscript/online_supplement/validation_matrix.tex` | RETAIN ONLY IN REPOSITORY | Repository audit trail; may be stale relative to the theorem ledger. |
| Canonical display-burden/resource summary (standalone, unlabeled) | `manuscript/tables/appendix_canonical_resource_summary.tex` | MOVE TO ONLINE RESOURCE | Exact resource schedule support for Section 6. |
| Canonical safe-compression summary (standalone, unlabeled) | `manuscript/tables/appendix_canonical_safe_compression.tex` | MOVE TO ONLINE RESOURCE | Exact source/minimum-library support for Section 6. |

## Absent future materials and their gates

These objects are required by the preferred contribution but do not currently
exist as completed contributions:

| Future object | Required gate before manuscript claim |
|---|---|
| Tagged-cover equivalence as a separately stated theorem | Precise identity-closure statement, complete human proof, exact fixtures, theorem-ledger entry. |
| Parametric worst-case local/global gap family | Correct statement, complete proof, adversarial counterexample search, exact rational fixtures. |
| Preprocessing theorem and implementation | Proved reduction rules, stable reconstruction map, oracle equivalence tests, exact postchecks. |
| Exact joint bitmask DP | Specification covering both frontier and closure tags, exhaustive rational oracle comparisons, stable ties, schema and postchecks. |
| Approximation-guaranteed weighted greedy construction | Explicit assumptions, complete approximation proof, implementation matching the proof, exact feasibility repair/postcheck, adversarial tests. |
| Registered algorithmic scaling study | New directory, registry, deterministic seeds, design lock, schemas, estimands, compute-risk budget, and explicit authorization before long execution. |
| Financial algorithm comparison | Completed algorithm stack, dated leakage-safe design lock, no held-out selection inputs, exact output postchecks, committed aggregate artifacts only. |

Failure of any gate removes that object from the preferred contribution. It does
not license a weaker result to be described with the stronger label.

## Migration order

When implementation begins, migration follows dependencies rather than current
file order:

1. reconcile theorem and evidence labels with `THEOREM_LEDGER.md`;
2. settle the tagged-cover and local/global theorem gates;
3. implement and validate algorithms against one shared exact instance contract;
4. lock and run the new algorithmic study only when requested;
5. lock any financial re-comparison without held-out leakage;
6. generate all tables, figures, and numbers from committed artifacts;
7. rewrite the main article to the nine-section architecture;
8. assemble the Online Resource and source-completeness manifest;
9. run the full verification suite only at the declared release gate.

Until then, this map is a planning classification only. No preprint,
supplement, experiment, result, figure, or table file is to be moved, deleted,
or rewritten as a consequence of this document alone.
