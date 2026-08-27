import StrategyInnovation.Fixtures.JournalAlgorithms

/-!
# Exact journal algorithm fixture audit

The shared Julia-Lean fixtures check only the named finite arithmetic and
coverage calculations. They do not upgrade the universal deletion-gap,
preprocessing, DP, or approximation statements.
-/

#print axioms StrategyInnovation.Fixtures.JournalAlgorithms.gapK
#print axioms StrategyInnovation.Fixtures.JournalAlgorithms.gapEpsilon
#print axioms StrategyInnovation.Fixtures.JournalAlgorithms.gapHeuristicBurden
#print axioms StrategyInnovation.Fixtures.JournalAlgorithms.gapOptimumBurden
#print axioms StrategyInnovation.Fixtures.JournalAlgorithms.gap_k4_half_ratio_exact
#print axioms StrategyInnovation.Fixtures.JournalAlgorithms.maskOr
#print axioms StrategyInnovation.Fixtures.JournalAlgorithms.requirementMask_take_union_exact
#print axioms StrategyInnovation.Fixtures.JournalAlgorithms.preprocessingCoverage
#print axioms StrategyInnovation.Fixtures.JournalAlgorithms.preprocessingRequirements
#print axioms StrategyInnovation.Fixtures.JournalAlgorithms.preprocessing_unique_first_carrier
#print axioms StrategyInnovation.Fixtures.JournalAlgorithms.preprocessing_fixture_forces_first
#print axioms StrategyInnovation.Fixtures.JournalAlgorithms.greedySingletonBurden
#print axioms StrategyInnovation.Fixtures.JournalAlgorithms.greedyBundleBurden
#print axioms StrategyInnovation.Fixtures.JournalAlgorithms.greedy_three_row_ratio_exact

#lint- only checkType unusedArguments simpNF in StrategyInnovation.Fixtures.JournalAlgorithms
