import Mathlib.Tactic.Linter
import StrategyInnovation.Coverage.SingleGap

/-!
# Monotone-gap upper-threshold audit

This file records the dependency footprint of the finite order definitions,
the one-shot cost-covering theorem, its cutoff comparative statics, and both
exact boundary counterexamples.  No declaration audited here identifies this
set with an optimal Bellman research region.
-/

#print axioms
  StrategyInnovation.Coverage.quasiConcaveSequence_iff_connectedUpperLevelSets
#print axioms
  StrategyInnovation.Coverage.IsSinglePeaked.quasiConcaveSequence
#print axioms
  StrategyInnovation.Coverage.IsSinglePeaked.intervalSupport
#print axioms
  StrategyInnovation.Coverage.expectedGap_nonnegative
#print axioms
  StrategyInnovation.Coverage.grossCoverageValue_monotone
#print axioms
  StrategyInnovation.Coverage.oneShotCostCoveringSet
#print axioms
  StrategyInnovation.Coverage.oneShotCostCoveringSet_isUpperSet
#print axioms
  StrategyInnovation.Coverage.monotoneGap_upperThreshold
#print axioms
  StrategyInnovation.Coverage.expectedGap_mono_gap
#print axioms
  StrategyInnovation.Coverage.oneShotCostCoveringSet_antitone_cost
#print axioms
  StrategyInnovation.Coverage.oneShotCostCoveringSet_mono_success
#print axioms
  StrategyInnovation.Coverage.oneShotCostCoveringSet_mono_survival
#print axioms
  StrategyInnovation.Coverage.oneShotCostCoveringSet_mono_admissionProbability
#print axioms
  StrategyInnovation.Coverage.oneShotCostCoveringSet_antitone_frontier
#print axioms
  StrategyInnovation.Coverage.cutoff_le_of_Ici_subset
#print axioms
  StrategyInnovation.Coverage.cost_cutoff_mono
#print axioms
  StrategyInnovation.Coverage.survival_cutoff_antitone
#print axioms
  StrategyInnovation.Coverage.admissionProbability_cutoff_antitone
#print axioms
  StrategyInnovation.Coverage.frontier_cutoff_mono
#print axioms
  StrategyInnovation.Coverage.SingleGapCounterexamples.destructiveKernel_expectedGap
#print axioms
  StrategyInnovation.Coverage.SingleGapCounterexamples.singlePeakedGap_disconnectedPotential
#print axioms
  StrategyInnovation.Coverage.SingleGapCounterexamples.destructiveKernel_not_stochasticallyMonotone
#print axioms
  StrategyInnovation.Coverage.SingleGapCounterexamples.nonmonotoneKernel_disconnectedCostCoveringSet
#print axioms
  StrategyInnovation.Coverage.SingleGapCounterexamples.nonAntitoneCost_disconnectedCostCoveringSet

#lint- only checkType unusedArguments simpNF in
  StrategyInnovation.Coverage
