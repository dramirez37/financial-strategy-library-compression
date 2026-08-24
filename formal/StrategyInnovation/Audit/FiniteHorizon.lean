import Mathlib.Tactic.Linter
import StrategyInnovation.Value.FiniteHorizon

/-!
# Finite-horizon value audit

This file records the dependency footprint of every principal exact finite-horizon
value theorem and runs the focused environment linters.
-/

#print axioms StrategyInnovation.FiniteHorizon.expectedValue_extensionality
#print axioms StrategyInnovation.FiniteHorizon.expectedValue_mono
#print axioms StrategyInnovation.FiniteHorizon.bellmanStep_mono
#print axioms
  StrategyInnovation.FiniteHorizon.bellmanStep_respectsDynamicInnovation
#print axioms
  StrategyInnovation.FiniteHorizon.finiteHorizonValue_eq_of_dynamicInnovationEquivalent
#print axioms
  StrategyInnovation.FiniteHorizon.abs_finiteHorizonValue_le_bound
#print axioms StrategyInnovation.FiniteHorizon.finiteHorizonValue_bounded
#print axioms
  StrategyInnovation.FiniteHorizon.rawFiniteHorizonValue_eq_of_compressedState_eq
#print axioms
  StrategyInnovation.FiniteHorizon.finiteHorizonValue_factors_through_compressedState
#print axioms StrategyInnovation.FiniteHorizon.finiteHorizon_optimalAction_exists

#lint- only checkType unusedArguments simpNF in
  StrategyInnovation.FiniteHorizon
