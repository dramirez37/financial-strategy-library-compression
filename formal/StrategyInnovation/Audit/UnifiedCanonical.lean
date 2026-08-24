import StrategyInnovation.Fixtures.UnifiedCanonical

/-!
# Axiom audit for the unified canonical benchmark

This focused audit prints every theorem introduced by the exact six-state
fixture.  The four finite-sum expansion lemmas are included because they are
proof-critical: all remaining probability, reward, value, selector, and
uniqueness certificates reduce through them using kernel-checked finite
enumeration.
-/

open StrategyInnovation.Projection.Model.UnifiedCanonicalFixture

#print axioms sum_belief
#print axioms sum_compressedState
#print axioms sum_outcome
#print axioms sum_beliefPath
#print axioms rawLibrary_card
#print axioms raw_representatives
#print axioms rawUpdate_compresses
#print axioms rawUpdates_compress_to_declaredStates
#print axioms projectDurations_positive
#print axioms beliefTransition_normalized
#print axioms generation_normalized
#print axioms verification_in_unit_interval
#print axioms admitted_normalized
#print axioms joint_path_marginal
#print axioms pathMass_normalized
#print axioms joint_outcome_marginal
#print axioms joint_normalized
#print axioms rawProbabilityLaws_normalized
#print axioms compressedPushforward_normalized
#print axioms compressedPushforwardLaws_normalized
#print axioms rawPushforward_eq_compressed
#print axioms beliefPath_terminal_marginal
#print axioms beliefPathProbabilities_eq_declaredPowers
#print axioms operatingRewardBlocks_eq_declared
#print axioms rawContinueQ_lift
#print axioms rawResearchQ_lift
#print axioms rawCompressedFiniteValue_eq
#print axioms registeredFiniteHorizon_raw_eq_compressed
#print axioms stationaryActionValues_eq_declared
#print axioms stationaryValue_bellmanFixedPoint
#print axioms stationarySelector_attains
#print axioms stationarySelector_policyEvaluationValue
#print axioms rawActionValue_lift
#print axioms liftedRawSelector_policyEvaluationValue
#print axioms exactPolicyEvaluationResidual_eq_zero
#print axioms optimalActions_unique
