import StrategyInnovation.Basic.Probability
import Mathlib.Data.Fintype.Option
import StrategyInnovation.Raw.Closure

/-!
# Raw candidate-generation distributions

Candidate generation is a primitive exact rational distribution on the fixed
finite catalog plus a distinguished failure outcome.  Its displayed inputs
make the raw closure-factorization restriction explicit.
-/

namespace StrategyInnovation.Raw

/-- A raw candidate outcome: failure or one catalog strategy identifier. -/
abbrev CandidateOutcome (model : FiniteModel) := Option model.StrategyId

/-- Exact candidate-generation laws indexed by project, belief, and closure. -/
structure CandidateGenerationDistributions (model : FiniteModel) where
  distribution :
    model.ResearchProject → model.Belief → Raw.ModuleSet model →
      RatProb (Raw.CandidateOutcome model)

namespace CandidateGenerationDistributions

variable {model : FiniteModel}

/-- The exact generation mass assigned to one raw candidate outcome. -/
def probability (generation : Raw.CandidateGenerationDistributions model)
    (project : model.ResearchProject) (belief : model.Belief)
    (available : Raw.ModuleSet model)
    (outcome : Raw.CandidateOutcome model) : ℚ :=
  (generation.distribution project belief available).probability outcome

/-- Candidate-generation mass is pointwise nonnegative. -/
theorem probability_nonnegative
    (generation : Raw.CandidateGenerationDistributions model)
    (project : model.ResearchProject) (belief : model.Belief)
    (available : Raw.ModuleSet model)
    (outcome : Raw.CandidateOutcome model) :
    0 ≤ generation.probability project belief available outcome :=
  (generation.distribution project belief available).nonnegative outcome

/-- Candidate-generation mass sums exactly to one on the finite outcome type. -/
theorem probability_totalMass
    (generation : Raw.CandidateGenerationDistributions model)
    (project : model.ResearchProject) (belief : model.Belief)
    (available : Raw.ModuleSet model) :
    ∑ outcome : Raw.CandidateOutcome model,
        generation.probability project belief available outcome = 1 := by
  simpa [probability, RatProb.probability, Finsupp.sum_fintype] using
    (generation.distribution project belief available).totalMass

end CandidateGenerationDistributions

end StrategyInnovation.Raw
