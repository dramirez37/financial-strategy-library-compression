import Mathlib.Tactic.Linter
import StrategyInnovation.Counterexamples.MultiGapRegion

/-!
# Multi-gap cost-covering audit

This file records the dependency footprint of the exact two-gap construction,
its disconnected strict cost-covering set, and the arbitrary-cost topology
boundary counterexample.
-/

#print axioms
  StrategyInnovation.Counterexamples.MultiGapRegion.project_fills_two_separated_strategyLibraryGaps
#print axioms
  StrategyInnovation.Counterexamples.MultiGapRegion.coveragePotential_eq
#print axioms
  StrategyInnovation.Counterexamples.MultiGapRegion.strictCostCoveringSet_eq
#print axioms
  StrategyInnovation.Counterexamples.MultiGapRegion.separatedMultiGap_disconnectedCostCoveringSet
#print axioms
  StrategyInnovation.Counterexamples.MultiGapRegion.constantGapPotential_eq
#print axioms
  StrategyInnovation.Counterexamples.MultiGapRegion.unrestrictedCost_defeats_generalComponentBound

#lint- only checkType unusedArguments simpNF in
  StrategyInnovation.Counterexamples.MultiGapRegion
