import StrategyInnovation

/-!
# Comprehensive theorem linter

This is the release-level linter gate after all publication-facing modules
have been imported.  `checkType` and `unusedArguments` cover the complete
project namespace. `simpNF` is then run over the major theorem-bearing
publication namespace families listed below; the generated fixture namespace
is deliberately excluded because its
compiler-generated recursion equations are transparent evaluators rather than
proof declarations or manuscript results.  This complements the
declaration-by-declaration axiom audit in `AxiomAudit.lean`.
-/

#lint- only checkType unusedArguments in StrategyInnovation
#lint- only simpNF in StrategyInnovation.Projection.Model
#lint- only simpNF in StrategyInnovation.Raw
#lint- only simpNF in StrategyInnovation.Coverage
#lint- only simpNF in StrategyInnovation.Counterexamples.MultiGapRegion
#lint- only simpNF in StrategyInnovation.InnovationEquation
#lint- only simpNF in StrategyInnovation.ValueDecomposition
#lint- only simpNF in StrategyInnovation.FiniteHorizon
#lint- only simpNF in StrategyInnovation.BellmanContraction
#lint- only simpNF in StrategyInnovation.FrontierPruningLoss
#lint- only simpNF in StrategyInnovation.Interaction.PrimitiveSubstitution
