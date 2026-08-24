# Unified T5--T6 migration

`StrategyInnovation.ValueDecomposition` and
`StrategyInnovation.InnovationEquation` remain compiled supporting namespaces.
They use the primitive F5 adapter and are not aliases for the unified T1 raw
process.

| Supporting declaration | Unified T5 declaration | Disposition |
|---|---|---|
| `ValueDecomposition.passiveValue` | `Projection.Model.UnifiedDecomposition.passiveValue` | Superseded for final-model use; different process binder and timing |
| `ValueDecomposition.fullValue` | `Projection.Model.UnifiedDecomposition.fullValue` | Superseded; the replacement is T1 `rawValue` |
| `ValueDecomposition.researchOptionPremium` | `Projection.Model.UnifiedDecomposition.researchOptionPremium` | Superseded; not an alias |
| `ValueDecomposition.totalInnovation` | `Projection.Model.UnifiedDecomposition.totalInsertionValue` | Superseded; not an alias |
| `ValueDecomposition.operationalInnovation` | `Projection.Model.UnifiedDecomposition.operationalInsertionValue` | Superseded; not an alias |
| `ValueDecomposition.generativeInnovation` | `Projection.Model.UnifiedDecomposition.generativeInsertionValue` | Superseded; not an alias |
| `ValueDecomposition.totalInnovation_eq_operational_add_generative` | `Projection.Model.UnifiedDecomposition.totalInsertionValue_eq_operational_add_generative` | Same algebraic pattern on a different model; superseded, not aliased |
| `ValueDecomposition.operationalInnovation_eq_zero_of_frontier_eq` | `Projection.Model.UnifiedDecomposition.operationalInsertionValue_eq_zero_of_frontier_eq` | Superseded; not aliased |
| `ValueDecomposition.totalInnovation_eq_zero_of_frontier_closure_eq` | `Projection.Model.UnifiedDecomposition.totalInsertionValue_eq_zero_of_frontier_closure_eq` | Superseded; the replacement uses T1 rather than primitive factorization |
| `ValueDecomposition.moduleInsertion_does_not_reduce_researchOptionPremium` | `Projection.Model.UnifiedDecomposition.researchOptionPremium_mono_of_closureEnrichmentProjectDominance` | Superseded by a different explicit dominance certificate; not an alias |
| `ValueDecomposition.ExactExample.operationalInnovation_zero_generativeInnovation_positive` | `Projection.Model.UnifiedDecomposition.BridgeExample.bridge_operational_zero_generative_positive` | Superseded by a raw generation/admission and T1-coupling witness |
| `InnovationEquation.passiveOperationalInnovation_antitone_of_library_inclusion` | `Projection.Model.UnifiedDecomposition.operationalInsertionValue_antitone_of_library_inclusion` | Superseded for final-model use; the F7 gap theorem remains supporting |
| Legacy one-gap/coverage fixtures previously labeled T6 | `Projection.Model.GenerativeLowerBound.generativeInsertionValue_lowerBound_with_operatingAdjustment` | Superseded; the old objects have no raw carrier comparator, initiation-cost term, T1 completion coupling, or unified operating adjustment |
| `Coverage.coveragePotential_eq_oneShotGrossOperationalResearchValue` | `Projection.Model.GenerativeLowerBound.generativeInsertionValue_lowerBound_occupationWeighted` | Supporting only, not an alias; S4 is a supplied gross fixed-candidate occupation identity, while T6 derives a net marginal raw-project bound |

No old declaration was renamed or changed. No compatibility alias is
introduced because every replacement has a materially different process
interface or assumption signature.

T6 introduces no alias for a prior Lean theorem. Its principal declarations
are new because no older module simultaneously binds a raw library carrier,
raw generation probability, primitive admission probability, positive
calendar duration, zero-premium deleted comparator, and the exact incumbent
operating/passive-baseline adjustment.
