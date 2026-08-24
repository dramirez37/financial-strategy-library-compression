import StrategyInnovation.Counterexamples.FrontierPruningLoss

/-!
# Frontier-only pruning loss proof audit

This module records the kernel dependencies of the explicit finite
construction, exact two-period loss calculation, arbitrary scaled-loss
theorem, and sharp bounded-reward corollary.
-/

#print axioms
  StrategyInnovation.FrontierPruningLoss.keyModule_unique_to_dominated
#print axioms
  StrategyInnovation.FrontierPruningLoss.pruned_frontier_eq_zero
#print axioms
  StrategyInnovation.FrontierPruningLoss.unpruned_frontier_eq_zero
#print axioms
  StrategyInnovation.FrontierPruningLoss.dominated_operationallyRedundant
#print axioms
  StrategyInnovation.FrontierPruningLoss.dominated_not_generativelyRedundant
#print axioms
  StrategyInnovation.FrontierPruningLoss.frontierOnlyPrune_eq_pruned
#print axioms
  StrategyInnovation.FrontierPruningLoss.current_frontiers_equal
#print axioms StrategyInnovation.FrontierPruningLoss.semantics_factors
#print axioms
  StrategyInnovation.FrontierPruningLoss.researchTransition_unpruned
#print axioms
  StrategyInnovation.FrontierPruningLoss.researchTransition_pruned
#print axioms
  StrategyInnovation.FrontierPruningLoss.pruned_value_two_eq_zero
#print axioms
  StrategyInnovation.FrontierPruningLoss.unpruned_value_two_eq_half_reward
#print axioms StrategyInnovation.FrontierPruningLoss.frontierPruningLoss_exact
#print axioms
  StrategyInnovation.FrontierPruningLoss.frontierPruningLoss_scaledTarget_exact
#print axioms
  StrategyInnovation.FrontierPruningLoss.frontierPruningLoss_arbitrarilyLarge
#print axioms
  StrategyInnovation.FrontierPruningLoss.boundedReward_frontierPruningLoss_sharp

#lint- only checkType unusedArguments simpNF in
  StrategyInnovation.FrontierPruningLoss
