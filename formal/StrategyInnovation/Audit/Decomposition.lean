import Mathlib.Tactic.Linter
import StrategyInnovation.Value.Decomposition

/-!
# Value-decomposition audit

This file records the dependency footprint of the principal exact
finite-horizon decomposition declarations and runs focused linters.
-/

#print axioms
  StrategyInnovation.ValueDecomposition.totalInnovation_eq_operational_add_generative
#print axioms
  StrategyInnovation.ValueDecomposition.passiveValue_eq_of_frontier_eq
#print axioms
  StrategyInnovation.ValueDecomposition.operationalInnovation_eq_zero_of_frontier_eq
#print axioms
  StrategyInnovation.ValueDecomposition.dynamicInnovationEquivalent_of_frontier_closure_eq
#print axioms
  StrategyInnovation.ValueDecomposition.fullValue_eq_of_frontier_closure_eq
#print axioms
  StrategyInnovation.ValueDecomposition.totalInnovation_eq_zero_of_frontier_closure_eq
#print axioms
  StrategyInnovation.ValueDecomposition.finiteHorizonValue_state_mono
#print axioms
  StrategyInnovation.ValueDecomposition.fullValue_mono_of_library_inclusion
#print axioms
  StrategyInnovation.ValueDecomposition.researchOptionPremium_mono_of_candidateGenerationMonotone
#print axioms
  StrategyInnovation.ValueDecomposition.moduleInsertion_does_not_reduce_researchOptionPremium
#print axioms
  StrategyInnovation.ValueDecomposition.ExactExample.operationalInnovation_zero_generativeInnovation_positive

#lint- only checkType unusedArguments simpNF in
  StrategyInnovation.ValueDecomposition
