import Mathlib.Tactic.Linter
import StrategyInnovation.Value.SystemInteraction

/-!
# Focused axiom audit for T7 frontier--closure system interaction
-/

open StrategyInnovation.Projection.Model.SystemInteraction

#print axioms closureIncrement
#print axioms interactionCrossDifference
#print axioms AreSubstitutes
#print axioms AreComplements
#print axioms compressedClosureIncrement
#print axioms compressedInteractionCrossDifference
#print axioms FrontierClosureRectangle
#print axioms FrontierClosureRectangle.poor_sameClosureFrontierLE
#print axioms FrontierClosureRectangle.rich_sameClosureFrontierLE
#print axioms FrontierClosureRectangle.high_closure_subset
#print axioms ActionFeasible
#print axioms nodeActionValue
#print axioms compressedValue_succ_eq_actionMaximum
#print axioms RelativeActionSaturation
#print axioms CommonGapActionDecomposition
#print axioms relativeActionSaturation_of_commonGap
#print axioms SubstitutionAssumptions
#print axioms compressedInteractionCrossDifference_nonpositive
#print axioms PrimitiveSubstitutionAssumptions
#print axioms relativeActionSaturation_of_primitiveSaturation
#print axioms PrimitiveSubstitutionAssumptions.toSubstitutionAssumptions
#print axioms compressedInteractionCrossDifference_nonpositive_of_primitiveSaturation
#print axioms Examples.poorClosure
#print axioms Examples.richClosure
#print axioms Examples.poorClosure_subset_richClosure
#print axioms Examples.oneProjectPremium
#print axioms Examples.substitutionValue
#print axioms Examples.strict_substitution_example
#print axioms Examples.independentMenuSwitchValue
#print axioms Examples.independent_menu_switch_individual_saturation
#print axioms Examples.independent_menu_switch_crossDifference_positive
#print axioms Examples.primitiveProjectReturn
#print axioms Examples.added_exposure_order_insufficient_for_allPairs
#print axioms Examples.frontierDependentSuccessValue
#print axioms Examples.frontier_dependent_success_strict_complementarity
#print axioms Examples.separableValue
#print axioms Examples.separable_zero_interaction

#lint- only checkType unusedArguments simpNF in
  StrategyInnovation.Projection.Model.SystemInteraction
