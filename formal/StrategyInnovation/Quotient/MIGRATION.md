# Dynamic innovation equivalence migration

The publication-facing interface is now the unified raw-model namespace
`StrategyInnovation.Projection.Model`. The old top-level interface in
`StrategyInnovation.Quotient.DynamicInnovation` remains compiled only for the
legacy F1--F4 primitive-transition supporting layer.

## Aliases

No old declaration is an alias for a new unified declaration. The model
binders and mathematical statements changed: the old relation consumes a
cost-free `FiniteResearchSemantics`, while the new relation consumes the raw
`Projection.Model` and observes availability-tagged costs, durations, joint
terminal laws, and operating rewards. Treating either statement as an alias
would hide a real assumption change.

## Superseded final-model names

| Old top-level declaration | Unified replacement | Migration status |
|---|---|---|
| `StrategyInnovation.DynamicInnovationEquivalent` | `StrategyInnovation.Projection.Model.DynamicInnovationEquivalent` | superseded; old relation is primitive and cost-free |
| `dynamicInnovationEquivalent_refl` | `Projection.Model.dynamicInnovationEquivalent_refl` | superseded |
| `dynamicInnovationEquivalent_symm` | `Projection.Model.dynamicInnovationEquivalent_symm` | superseded |
| `dynamicInnovationEquivalent_trans` | `Projection.Model.dynamicInnovationEquivalent_trans` | superseded |
| `dynamicInnovationSetoid` | `Projection.Model.dynamicInnovationSetoid` | superseded |
| `DynamicInnovationQuotient` | `Projection.Model.DynamicInnovationQuotient` | superseded |
| `dynamicInnovationQuotientFinite` | `Projection.Model.dynamicInnovationQuotientFinite` | superseded |
| `dynamicInnovationClass` | `Projection.Model.dynamicInnovationClass` | superseded |
| `finiteHorizonValue_eq_of_dynamicInnovationEquivalent` | `Projection.Model.rawValue_eq_of_dynamicInnovationEquivalent` | superseded; value and timing changed |
| `quotientFiniteHorizonValue` | `Projection.Model.quotientFiniteHorizonValue` | superseded |
| `quotientFiniteHorizonValue_mk` | `Projection.Model.quotientFiniteHorizonValue_mk` | superseded |
| `finiteHorizonValue_depends_only_on_dynamicInnovationClass` | `Projection.Model.finiteHorizonValue_depends_only_on_dynamicInnovationClass` | superseded |
| `representation_refines_dynamicInnovationEquivalent` | `Projection.Model.representation_refines_dynamicInnovationEquivalent` | superseded; comparison class now preserves all five unified observations |
| `representationQuotientToDynamicInnovationQuotient` and `_mk` | no canonical replacement | legacy quotient-map convenience; restricted refinement is retained only as a proposition |

## Superseded frontier--closure names

The raw T2 declarations deliberately live in `Projection.Model`. They are not
aliases for the identically suffixed top-level F2 declarations: the old
theorems consume `FiniteResearchSemantics` and an abstract `T` table, whereas
the replacements consume the unified raw `Projection.Model`, its derived T1
projection, and `RawClosureDetectable`.

| Old primitive declaration | Raw T2 replacement | Migration status |
|---|---|---|
| `StrategyInnovation.frontierClosure_eq_implies_dynamicInnovationEquivalent` | `StrategyInnovation.Projection.Model.frontierClosure_eq_implies_dynamicInnovationEquivalent` | superseded; forward proof now exposes raw generation, admission, and projected-law equality |
| `StrategyInnovation.dynamicInnovationEquivalent_implies_frontierClosure_eq` | `StrategyInnovation.Projection.Model.dynamicInnovationEquivalent_implies_frontierClosure_eq` | superseded; converse uses raw-process detectability rather than abstract `T` identifiability |
| `StrategyInnovation.dynamicInnovationEquivalent_iff_frontierClosure_eq` | `StrategyInnovation.Projection.Model.dynamicInnovationEquivalent_iff_frontierClosure_eq` | superseded final-model characterization |
| `StrategyInnovation.dynamicInnovationEquivalent_iff_compressedLibraryState_eq` | `StrategyInnovation.Projection.Model.dynamicInnovationEquivalent_iff_compressedLibraryState_eq` | superseded final compressed-state criterion |
| `StrategyInnovation.ClosureIdentifiable` | `StrategyInnovation.Projection.Model.RawClosureDetectable` | superseded for the final model; old predicate remains supporting F2 only |

No old frontier--closure declaration remains an alias. The old theorem names
continue to compile for legacy F2--F4 dependencies only.

## Superseded safe-deletion names

Unified T3 lives in `StrategyInnovation.Projection.Model` and consumes the raw
`Projection.Model`. The older top-level declarations in
`StrategyInnovation.Compression.SafeDeletion` consume the cost-free primitive
semantics. Their similar suffixes are not aliases.

| Old primitive declaration | Unified T3 replacement | Migration status |
|---|---|---|
| `StrategyInnovation.operationallyRedundant` | `StrategyInnovation.Projection.Model.operationallyRedundant` | superseded final-model predicate; the equality is now explicitly a raw-library deletion |
| `StrategyInnovation.generativelyRedundant` | `StrategyInnovation.Projection.Model.generativelyRedundant` | superseded final-model predicate |
| `StrategyInnovation.compressedStatePreservingDeletion` | `StrategyInnovation.Projection.Model.redundantDeletion_iff_compressedLibraryState_eq` | superseded by an exact theorem rather than a separate final predicate |
| `StrategyInnovation.SafelyDeletable` | `StrategyInnovation.Projection.Model.InnovationSafeDeletion` | superseded; the new certificate records all unified observations and all finite-horizon raw values |
| `StrategyInnovation.redundantDeletion_dynamicInnovationEquivalent` | `StrategyInnovation.Projection.Model.redundantDeletion_dynamicInnovationEquivalent` | superseded; the new result uses T1/UDI rather than the primitive transition table |
| `StrategyInnovation.redundantDeletion_safelyDeletable` | `StrategyInnovation.Projection.Model.redundantDeletion_innovationSafe` | superseded |
| `StrategyInnovation.deletionPreservesCurrentRewardAndProjects_iff_redundant` | `StrategyInnovation.Projection.Model.deletionProcessObservations_iff_redundant` | superseded; the converse now uses `RawClosureDetectable` and the unified cost/duration/joint-law/reward observations |
| `StrategyInnovation.SafeDeletionSequence` | `StrategyInnovation.Projection.Model.RedundantDeletionSequence` | superseded; the new trace rechecks the raw frontier and closure at each intermediate library |
| `StrategyInnovation.safeDeletionSequence_innovationSafeCompression` | `StrategyInnovation.Projection.Model.RedundantDeletionSequence.dynamicInnovationEquivalent` | superseded final-model endpoint theorem |
| `StrategyInnovation.InnovationSafeCompression` | `StrategyInnovation.Projection.Model.PruningAlgorithmSpec` | superseded by a function-plus-certified-trace specification |

No old safe-deletion theorem remains an alias. The old declarations remain
compiled as supporting F3/F4 dependencies. New code should not open both
interfaces unqualified; use the `Projection.Model` names for the final model.

## Other legacy cost-sensitive names

`StrategyInnovation.FiniteHorizon.DynamicInnovationEquivalent` and
`StrategyInnovation.BellmanContraction.infiniteHorizonValue_eq_of_dynamicInnovationEquivalent`
belong to the primitive F5/F8 action timing. They remain supporting results,
not aliases. Final-model code should use
`Projection.Model.DynamicInnovationEquivalent`,
`Projection.Model.rawValue_eq_of_dynamicInnovationEquivalent`, and
`Projection.Model.DiscountedContractionModel.rawFixedPoint_eq_of_dynamicInnovationEquivalent`.
