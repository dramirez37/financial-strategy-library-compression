import StrategyInnovation.Optimization.TaggedSafeCompression

/-!
# Tagged identity-closure safe-compression audit

This focused audit covers the disjoint requirement type, identity closure,
source and per-strategy tag sets, weighted binary objective identity, and the
source-relative safe-feasible-if-and-only-if-cover theorem. It does not make
a complexity, approximation, implementation, or empirical claim.
-/

#print axioms StrategyInnovation.Optimization.TaggedRequirement
#print axioms StrategyInnovation.Optimization.identityModuleClosure
#print axioms StrategyInnovation.Optimization.sourceTaggedRequirements
#print axioms StrategyInnovation.Optimization.strategyTaggedCoverage
#print axioms StrategyInnovation.Optimization.selectedTaggedCoverage
#print axioms StrategyInnovation.Optimization.TaggedCoverFeasible
#print axioms StrategyInnovation.Optimization.libraryBurden_eq_weightedBinaryObjective
#print axioms StrategyInnovation.Optimization.operationalFrontier_eq_iff_sourceAttainers
#print axioms StrategyInnovation.Optimization.inactive_covers_zero_frontier
#print axioms StrategyInnovation.Optimization.generativeClosure_identity_eq_iff_sourceCarriers
#print axioms StrategyInnovation.Optimization.safeCompressionFeasible_identity_iff_taggedCover

#lint- only checkType unusedArguments simpNF in StrategyInnovation.Optimization
