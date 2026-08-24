import Mathlib.Tactic.Linter
import StrategyInnovation.Coverage.KernelComparativeStatics

/-!
# Focused axiom audit for belief-kernel comparative statics
-/

open StrategyInnovation.Coverage.KernelComparativeStatics

#print axioms discountedOccupation
#print axioms advantageRegion
#print axioms OccupationDominatesOnAdvantage
#print axioms GapOccupationDominates
#print axioms finiteEffectivePotential_eq_discountedOccupation
#print axioms coverage_mono_of_occupationDominatesOnAdvantage
#print axioms gapOccupationDominates_of_occupationDominatesOnAdvantage
#print axioms gapOccupationDominates_iff
#print axioms persistenceKernel
#print axioms persistenceKernel_stochastic
#print axioms persistenceCoverage
#print axioms currentAdvantageGap
#print axioms otherAdvantageGap
#print axioms constantAdvantageGap
#print axioms higherPersistence_raises_coverage
#print axioms higherPersistence_lowers_coverage
#print axioms higherPersistence_no_effect
#print axioms no_universal_persistence_increase
#print axioms no_universal_persistence_decrease

#lint- only checkType unusedArguments simpNF in
  StrategyInnovation.Coverage.KernelComparativeStatics
