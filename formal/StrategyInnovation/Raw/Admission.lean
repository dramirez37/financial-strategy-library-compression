import StrategyInnovation.Raw.CandidateGeneration

/-!
# Exact admission probabilities

Verification/admission probabilities are exact rationals in the closed unit
interval.  They are indexed by the same project, belief, and closure inputs as
generation, plus the generated catalog candidate.
-/

namespace StrategyInnovation.Raw

/-- Exact verification-pass probabilities for generated candidates. -/
structure AdmissionProbabilities (model : FiniteModel) where
  probability :
    model.ResearchProject → model.Belief → Raw.ModuleSet model →
      model.StrategyId → ℚ
  nonnegative : ∀ project belief available strategy,
    0 ≤ probability project belief available strategy
  le_one : ∀ project belief available strategy,
    probability project belief available strategy ≤ 1

namespace AdmissionProbabilities

variable {model : FiniteModel}

/-- Verification failure has exact nonnegative probability. -/
theorem failureProbability_nonnegative
    (admission : Raw.AdmissionProbabilities model)
    (project : model.ResearchProject) (belief : model.Belief)
    (available : Raw.ModuleSet model) (strategy : model.StrategyId) :
    0 ≤ 1 - admission.probability project belief available strategy :=
  sub_nonneg.mpr (admission.le_one project belief available strategy)

end AdmissionProbabilities

end StrategyInnovation.Raw
