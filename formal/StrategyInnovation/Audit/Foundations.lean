import StrategyInnovation.Library.InnovationState

/-!
# Foundational proof audit

This audit module records kernel dependencies for the principal finite-library
lemmas and runs focused environment linters over the imported foundational
modules.  It is checked explicitly in addition to the ordinary Lake build.
-/

#print axioms StrategyInnovation.Library.ext
#print axioms StrategyInnovation.operationalProfile_le_frontier
#print axioms StrategyInnovation.zero_le_operationalFrontier
#print axioms StrategyInnovation.exists_profile_eq_operationalFrontier
#print axioms StrategyInnovation.operationalFrontier_le_iff
#print axioms StrategyInnovation.operationalFrontier_mono
#print axioms StrategyInnovation.operationalFrontier_insert_of_operationallyRedundant
#print axioms StrategyInnovation.mem_rawModuleUnion
#print axioms StrategyInnovation.rawModuleUnion_mono
#print axioms StrategyInnovation.rawModuleUnion_subset_generativeClosure
#print axioms StrategyInnovation.generativeClosure_mono
#print axioms StrategyInnovation.generativeClosure_erase_of_generativelyRedundant
#print axioms StrategyInnovation.operationalFrontier_eq_of_compressedLibraryState_eq
#print axioms StrategyInnovation.generativeClosure_eq_of_compressedLibraryState_eq

#lint- only checkType unusedArguments simpNF in StrategyInnovation
