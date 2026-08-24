import StrategyInnovation.Raw

/-!
# Raw-model foundation proof audit

This audit records the kernel dependencies of the derived exact admission law
and the local raw-to-compressed update facts.  It intentionally contains no
primitive transition or Bellman theorem.
-/

#print axioms StrategyInnovation.Raw.admittedCandidateDistribution_nonnegative
#print axioms StrategyInnovation.Raw.admittedCandidateDistribution_totalMass
#print axioms StrategyInnovation.Raw.rawLibraryUpdate_none
#print axioms StrategyInnovation.Raw.rawLibraryUpdate_some
#print axioms StrategyInnovation.Raw.closure_absorption
#print axioms StrategyInnovation.Raw.rawModuleUnion_insert
#print axioms StrategyInnovation.Raw.generativeClosure_insert
#print axioms StrategyInnovation.Raw.operationalFrontier_insert
#print axioms StrategyInnovation.Raw.compressedLibraryState_rawLibraryUpdate

#lint- only checkType unusedArguments simpNF in StrategyInnovation.Raw
