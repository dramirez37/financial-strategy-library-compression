import Mathlib.Algebra.BigOperators.Finsupp.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Fintype.Option
import Mathlib.Tactic.Ring
import StrategyInnovation.Raw.Admission

/-!
# Derived admitted-candidate distributions

The admitted law is derived from raw generation and exact admission
probabilities.  Generated failures and rejected candidates are collected in
`none`; a verified candidate retains its catalog identifier.
-/

namespace StrategyInnovation.Raw

variable {model : FiniteModel}

/-- The derived exact mass of one admitted candidate outcome. -/
def admittedCandidateMass
    (generation : Raw.CandidateGenerationDistributions model)
    (admission : Raw.AdmissionProbabilities model)
    (project : model.ResearchProject) (belief : model.Belief)
    (available : Raw.ModuleSet model) :
    Raw.CandidateOutcome model → ℚ
  | none =>
      generation.probability project belief available none +
        ∑ strategy : model.StrategyId,
          generation.probability project belief available (some strategy) *
            (1 - admission.probability project belief available strategy)
  | some strategy =>
      generation.probability project belief available (some strategy) *
        admission.probability project belief available strategy

/-- Every mass in the derived admitted-candidate law is nonnegative. -/
theorem admittedCandidateMass_nonnegative
    (generation : Raw.CandidateGenerationDistributions model)
    (admission : Raw.AdmissionProbabilities model)
    (project : model.ResearchProject) (belief : model.Belief)
    (available : Raw.ModuleSet model)
    (outcome : Raw.CandidateOutcome model) :
    0 ≤ admittedCandidateMass generation admission project belief available outcome := by
  cases outcome with
  | none =>
      apply add_nonneg
      · exact generation.probability_nonnegative project belief available none
      · exact Finset.sum_nonneg fun strategy _ =>
          mul_nonneg
            (generation.probability_nonnegative project belief available
              (some strategy))
            (admission.failureProbability_nonnegative project belief available strategy)
  | some strategy =>
      exact mul_nonneg
        (generation.probability_nonnegative project belief available
          (some strategy))
        (admission.nonnegative project belief available strategy)

/-- The derived admitted-candidate mass sums exactly to one. -/
theorem admittedCandidateMass_totalMass
    (generation : Raw.CandidateGenerationDistributions model)
    (admission : Raw.AdmissionProbabilities model)
    (project : model.ResearchProject) (belief : model.Belief)
    (available : Raw.ModuleSet model) :
    ∑ outcome : Raw.CandidateOutcome model,
        admittedCandidateMass generation admission project belief available outcome = 1 := by
  classical
  rw [Fintype.sum_option]
  simp only [admittedCandidateMass]
  calc
    generation.probability project belief available none +
          ∑ strategy : model.StrategyId,
            generation.probability project belief available (some strategy) *
              (1 - admission.probability project belief available strategy) +
        ∑ strategy : model.StrategyId,
          generation.probability project belief available (some strategy) *
            admission.probability project belief available strategy =
        generation.probability project belief available none +
          ∑ strategy : model.StrategyId,
            (generation.probability project belief available (some strategy) *
                (1 - admission.probability project belief available strategy) +
              generation.probability project belief available (some strategy) *
                admission.probability project belief available strategy) := by
          rw [Finset.sum_add_distrib]
          ring
    _ = generation.probability project belief available none +
          ∑ strategy : model.StrategyId,
            generation.probability project belief available (some strategy) := by
          congr 1
          apply Finset.sum_congr rfl
          intro strategy _
          ring
    _ = ∑ outcome : Raw.CandidateOutcome model,
          generation.probability project belief available outcome := by
          rw [Fintype.sum_option]
    _ = 1 := generation.probability_totalMass project belief available

/-- The normalized exact admitted-candidate distribution derived from the primitives. -/
noncomputable def admittedCandidateDistribution
    (generation : Raw.CandidateGenerationDistributions model)
    (admission : Raw.AdmissionProbabilities model)
    (project : model.ResearchProject) (belief : model.Belief)
    (available : Raw.ModuleSet model) :
    RatProb (Raw.CandidateOutcome model) where
  mass := Finsupp.equivFunOnFinite.symm
    (admittedCandidateMass generation admission project belief available)
  nonnegative := by
    intro outcome
    exact admittedCandidateMass_nonnegative generation admission project belief
      available outcome
  totalMass := by
    rw [Finsupp.equivFunOnFinite_symm_sum]
    exact admittedCandidateMass_totalMass generation admission project belief available

@[simp]
theorem admittedCandidateDistribution_probability
    (generation : Raw.CandidateGenerationDistributions model)
    (admission : Raw.AdmissionProbabilities model)
    (project : model.ResearchProject) (belief : model.Belief)
    (available : Raw.ModuleSet model)
    (outcome : Raw.CandidateOutcome model) :
    (admittedCandidateDistribution generation admission project belief available).probability
        outcome =
      admittedCandidateMass generation admission project belief available outcome :=
  rfl

/-- The packaged admitted-candidate law is pointwise nonnegative. -/
theorem admittedCandidateDistribution_nonnegative
    (generation : Raw.CandidateGenerationDistributions model)
    (admission : Raw.AdmissionProbabilities model)
    (project : model.ResearchProject) (belief : model.Belief)
    (available : Raw.ModuleSet model)
    (outcome : Raw.CandidateOutcome model) :
    0 ≤
      (admittedCandidateDistribution generation admission project belief available).probability
        outcome :=
  (admittedCandidateDistribution generation admission project belief available).nonnegative
    outcome

/-- The packaged admitted-candidate law has total mass one. -/
theorem admittedCandidateDistribution_totalMass
    (generation : Raw.CandidateGenerationDistributions model)
    (admission : Raw.AdmissionProbabilities model)
    (project : model.ResearchProject) (belief : model.Belief)
    (available : Raw.ModuleSet model) :
    ∑ outcome : Raw.CandidateOutcome model,
        (admittedCandidateDistribution generation admission project belief available).probability
          outcome = 1 := by
  simpa only [admittedCandidateDistribution_probability] using
    admittedCandidateMass_totalMass generation admission project belief available

end StrategyInnovation.Raw
