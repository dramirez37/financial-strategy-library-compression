import Mathlib.Tactic.Linter
import StrategyInnovation.Coverage.Potential

/-!
# Coverage-potential audit

This file records the dependency footprint of the principal exact finite-grid
coverage-potential declarations and runs focused linters.
-/

#print axioms
  StrategyInnovation.Coverage.certifiedGap_nonnegative
#print axioms
  StrategyInnovation.Coverage.coveragePotential_eq_oneShotGrossOperationalResearchValue
#print axioms
  StrategyInnovation.Coverage.coveragePotential_mono_gap
#print axioms
  StrategyInnovation.Coverage.coveragePotential_mono_discount
#print axioms
  StrategyInnovation.Coverage.coveragePotential_mono_survival
#print axioms
  StrategyInnovation.Coverage.coveragePotential_mono_occupation
#print axioms
  StrategyInnovation.Coverage.coveragePotential_eq_zero_of_gap_eq_zero_on_reachable
#print axioms
  StrategyInnovation.Coverage.totalDiscountedOccupation_eq_geometricSum
#print axioms
  StrategyInnovation.Coverage.minimumGapOn_mul_regionOccupation_le_coveragePotential
#print axioms
  StrategyInnovation.Coverage.advantageRegion_minimumGap_mul_occupation_le_coveragePotential
#print axioms
  StrategyInnovation.Coverage.coveragePotential_le_maximumGap_mul_totalOccupation
#print axioms
  StrategyInnovation.Coverage.coveragePotential_le_maximumGap_mul_advantageRegionOccupation
#print axioms
  StrategyInnovation.Coverage.coveragePotential_le_maxGap_mul_regionOccupation
#print axioms
  StrategyInnovation.Coverage.OneShotModel.coveragePotential_eq_grossOperationalResearchValue
#print axioms
  StrategyInnovation.Coverage.OneShotModel.coveragePotential_antitone_of_frontier_improves
#print axioms
  StrategyInnovation.Coverage.DelayedCoverageExample.zero_currentGap_positive_coveragePotential

#lint- only checkType unusedArguments simpNF in
  StrategyInnovation.Coverage
