import Mathlib.Tactic.Linter
import StrategyInnovation.Value.InnovationEquation

/-!
# Strategy Innovation Equation audit

This file records the dependency footprint of the principal exact
finite-horizon Strategy Innovation Equation declarations and runs focused
linters.
-/

#print axioms
  StrategyInnovation.InnovationEquation.operationalFrontier_insert_sub_eq_frontierGap
#print axioms
  StrategyInnovation.InnovationEquation.passiveValue_succ
#print axioms
  StrategyInnovation.InnovationEquation.passiveOperationalInnovation_succ
#print axioms
  StrategyInnovation.InnovationEquation.passiveOperationalInnovation_eq_discountedGapSum
#print axioms
  StrategyInnovation.InnovationEquation.discountedGapSum_eq_zero_of_gap_eq_zero_on_reachable
#print axioms
  StrategyInnovation.InnovationEquation.passiveOperationalInnovation_eq_zero_of_gap_eq_zero_on_reachable
#print axioms
  StrategyInnovation.InnovationEquation.passiveOperationalInnovation_antitone_of_library_inclusion
#print axioms
  StrategyInnovation.InnovationEquation.DelayedBenefitExample.zero_currentGap_positive_passiveOperationalInnovation

#lint- only checkType unusedArguments simpNF in
  StrategyInnovation.InnovationEquation
