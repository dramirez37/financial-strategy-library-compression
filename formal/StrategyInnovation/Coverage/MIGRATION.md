# Coverage theorem migration

The publication-facing S5 object is now the one-shot cost-covering set
`oneShotCostCoveringSet`. It compares one-shot gross coverage value with
research cost. It is not the optimal research-action region of the Bellman
problem.

The following Lean names remain source-compatible aliases:

| Legacy name | Publication-facing name | Status |
|---|---|---|
| `singleGapResearchRegion` | `oneShotCostCoveringSet` | definitional abbreviation |
| `singleGapResearchRegion_isUpperSet` | `oneShotCostCoveringSet_isUpperSet` | theorem compatibility wrapper |
| `monotone_singleGap_yields_upperThreshold` | `monotoneGap_upperThreshold` | theorem compatibility wrapper |
| `SingleGapCounterexamples.nonAntitoneCost_disconnectedResearchRegion` | `SingleGapCounterexamples.nonAntitoneCost_disconnectedCostCoveringSet` | theorem compatibility wrapper |
| `MultiGapRegion.researchRegion` | `MultiGapRegion.strictCostCoveringSet` | definitional abbreviation |
| `MultiGapRegion.researchRegion_eq` | `MultiGapRegion.strictCostCoveringSet_eq` | theorem compatibility wrapper |
| `MultiGapRegion.researchRegion_not_ordConnected` | `MultiGapRegion.strictCostCoveringSet_not_ordConnected` | theorem compatibility wrapper |
| `MultiGapRegion.multiGap_project_has_disconnected_researchRegion` | `MultiGapRegion.separatedMultiGap_disconnectedCostCoveringSet` | theorem compatibility wrapper |
| `MultiGapRegion.variableCostResearchRegion` | `MultiGapRegion.variableCostCoveringSet` | definitional abbreviation |
| `MultiGapRegion.variableCostResearchRegion_eq` | `MultiGapRegion.variableCostCoveringSet_eq` | theorem compatibility wrapper |
| `MultiGapRegion.arbitrary_cost_defeats_researchRegion_component_bound` | `MultiGapRegion.unrestrictedCost_defeats_generalComponentBound` | theorem compatibility wrapper |

The Julia function `cost_covering_set` is the publication-facing executable
counterpart. `research_region` remains a compatibility wrapper.

No Bellman-region theorem is renamed or aliased because no analogous optimal
dynamic monotonicity result has been proved.

The publication-facing kernel boundary is
`SingleGapCounterexamples.nonmonotoneKernel_disconnectedCostCoveringSet`.
Unlike the retained single-peaked-gap witness, it holds every other
upper-threshold assumption fixed and uses the increasing gap `(0,1,2)`.
