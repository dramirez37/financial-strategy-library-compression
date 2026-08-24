import Mathlib.Tactic.Linter
import StrategyInnovation.Bellman.Contraction

/-!
# Discounted Bellman contraction audit

This file records the dependency footprint of every principal infinite-horizon
contraction declaration and runs focused environment linters.
-/

#print axioms
  StrategyInnovation.BellmanContraction.realValueFunction_bounded
#print axioms
  StrategyInnovation.BellmanContraction.actionOperator_lipschitz
#print axioms
  StrategyInnovation.BellmanContraction.bellmanOperator_lipschitz
#print axioms
  StrategyInnovation.BellmanContraction.bellmanOperator_contracting
#print axioms
  StrategyInnovation.BellmanContraction.infiniteHorizonValue_isFixedPoint
#print axioms
  StrategyInnovation.BellmanContraction.exists_bellman_fixedPoint
#print axioms
  StrategyInnovation.BellmanContraction.bellman_fixedPoint_unique
#print axioms
  StrategyInnovation.BellmanContraction.valueIteration_tendsto_infiniteHorizonValue
#print axioms
  StrategyInnovation.BellmanContraction.valueIteration_geometric_error_bound
#print axioms
  StrategyInnovation.BellmanContraction.realFiniteHorizonValue_eq_valueIteration_zero
#print axioms
  StrategyInnovation.BellmanContraction.realFiniteHorizonValue_eq_ratCast
#print axioms
  StrategyInnovation.BellmanContraction.rationalFiniteHorizonValue_ratCast_tendsto_infiniteHorizonValue
#print axioms
  StrategyInnovation.BellmanContraction.rationalFiniteHorizonValue_ratCast_geometric_error_bound
#print axioms
  StrategyInnovation.BellmanContraction.finiteHorizonValue_ratCast_tendsto_infiniteHorizonValue
#print axioms
  StrategyInnovation.BellmanContraction.infiniteHorizonValue_eq_of_dynamicInnovationEquivalent

#lint- only checkType unusedArguments simpNF in
  StrategyInnovation.BellmanContraction
