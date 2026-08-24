import Mathlib.Tactic
import StrategyInnovation.Value.GenerativeLowerBound

/-!
# Joint descendant-event generative-option lower bound

This module is the publication-facing interface for the generalized T6 bound.
It uses the joint completion law already carried by the unified raw model and
does not assume independence between the belief path and the admitted outcome.

The module adds three ingredients to the underlying retained-carrier
development:

* every terminal joint descendant mass lies in `[0, 1]`;
* project commitment is decomposed exactly into cost, the operating block,
  frozen passive continuation, the distinguished joint descendant term, and
  the remaining continuation term;
* exact examples show the one-belief carrier, a correlated two-belief joint
  law, and the absence of any unconditional duration ordering.
-/

namespace StrategyInnovation

namespace Projection

namespace Model

namespace GenerativeLowerBound

open UnifiedDecomposition
open scoped BigOperators

variable {model : FiniteModel}
variable {catalog : Raw.StrategyCatalog model}
variable {closure : Raw.ClosureOperator model}

/-- Expected incumbent operating reward earned during the project block. -/
noncomputable def expectedOperatingBlock
    (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog)
    (project : model.ResearchProject) : ℚ :=
  (process.completion project belief
    (CompressedLibraryState.ofLibrary catalog closure library)).expectation
      (fun completion =>
        process.incumbentReward
          (CompressedLibraryState.ofLibrary catalog closure library)
          project completion.1)

/-- Expected frozen-library passive continuation at project completion. -/
noncomputable def expectedFrozenPassiveContinuation
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (project : model.ResearchProject) : ℚ :=
  (process.completion project belief
    (CompressedLibraryState.ofLibrary catalog closure library)).expectation
      (fun completion =>
        passiveValue process (horizon - process.duration project)
          (terminalBelief completion.1) library)

/--
Continuation gain not assigned to the declared descendant floor.

On the distinguished outcome this is the surplus above the floor `gain`; on
every other outcome it is the complete continuation gain.  Thus it contains
all continuation after other outcomes without double-counting the joint term.
-/
noncomputable def remainingContinuationGain
    (process : Model model catalog closure)
    (horizon : Nat) (library : Raw.Library catalog)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (gain : model.Belief → ℚ)
    (completion :
      BeliefPath model (process.duration project) × Raw.CandidateOutcome model) : ℚ :=
  if completion.2 = some descendant then
    completionContinuationGain process horizon library project completion -
      gain (terminalBelief completion.1)
  else
    completionContinuationGain process horizon library project completion

/-- Expected continuation not assigned to the distinguished joint-event floor. -/
noncomputable def expectedRemainingContinuationGain
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (project : model.ResearchProject)
    (descendant : model.StrategyId) (gain : model.Belief → ℚ) : ℚ :=
  (process.completion project belief
    (CompressedLibraryState.ofLibrary catalog closure library)).expectation
      (remainingContinuationGain process horizon library project descendant gain)

/-- Every component of the joint terminal-belief/descendant mass is at most one. -/
theorem jointDescendantMass_le_one
    (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (terminal : model.Belief) :
    jointDescendantMass process belief library project descendant terminal ≤ 1 := by
  classical
  let distribution :=
    process.completion project belief
      (CompressedLibraryState.ofLibrary catalog closure library)
  calc
    jointDescendantMass process belief library project descendant terminal ≤
        ∑ path : BeliefPath model (process.duration project),
          ∑ outcome : Raw.CandidateOutcome model,
            distribution.probability (path, outcome) := by
      unfold jointDescendantMass
      apply Finset.sum_le_sum
      intro path _
      by_cases hterminal : terminalBelief path = terminal
      · rw [if_pos hterminal]
        exact Finset.single_le_sum
          (fun outcome _ => distribution.nonnegative (path, outcome))
          (Finset.mem_univ (some descendant))
      · rw [if_neg hterminal]
        exact Finset.sum_nonneg fun outcome _ =>
          distribution.nonnegative (path, outcome)
    _ = 1 := by
      simpa [RatProb.probability, Finsupp.sum_fintype,
        Fintype.sum_prod_type] using distribution.totalMass

/-- The joint terminal-belief/descendant mass lies in the probability interval. -/
theorem jointDescendantMass_mem_unitInterval
    (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (terminal : model.Belief) :
    jointDescendantMass process belief library project descendant terminal ∈
      Set.Icc (0 : ℚ) 1 :=
  ⟨jointDescendantMass_nonnegative process belief library project descendant terminal,
    jointDescendantMass_le_one process belief library project descendant terminal⟩

/-- Total probability of admitting the distinguished descendant. -/
noncomputable def jointDescendantEventMass
    (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog)
    (project : model.ResearchProject) (descendant : model.StrategyId) : ℚ :=
  ∑ terminal : model.Belief,
    jointDescendantMass process belief library project descendant terminal

/-- The total distinguished-descendant event mass is nonnegative. -/
theorem jointDescendantEventMass_nonnegative
    (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog)
    (project : model.ResearchProject) (descendant : model.StrategyId) :
    0 ≤ jointDescendantEventMass process belief library project descendant := by
  unfold jointDescendantEventMass
  exact Finset.sum_nonneg fun terminal _ =>
    jointDescendantMass_nonnegative process belief library project descendant terminal

/-- The total distinguished-descendant event mass is at most one. -/
theorem jointDescendantEventMass_le_one
    (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog)
    (project : model.ResearchProject) (descendant : model.StrategyId) :
    jointDescendantEventMass process belief library project descendant ≤ 1 := by
  classical
  let distribution :=
    process.completion project belief
      (CompressedLibraryState.ofLibrary catalog closure library)
  calc
    jointDescendantEventMass process belief library project descendant =
        ∑ path : BeliefPath model (process.duration project),
          distribution.probability (path, some descendant) := by
      unfold jointDescendantEventMass jointDescendantMass
      rw [Finset.sum_comm]
      apply Finset.sum_congr rfl
      intro path _
      simp [distribution]
    _ ≤ ∑ path : BeliefPath model (process.duration project),
        ∑ outcome : Raw.CandidateOutcome model,
          distribution.probability (path, outcome) := by
      apply Finset.sum_le_sum
      intro path _
      exact Finset.single_le_sum
        (fun outcome _ => distribution.nonnegative (path, outcome))
        (Finset.mem_univ (some descendant))
    _ = 1 := by
      simpa [RatProb.probability, Finsupp.sum_fintype,
        Fintype.sum_prod_type] using distribution.totalMass

/-- The operating adjustment exposes its exact operating and passive blocks. -/
theorem operatingResearchAdjustment_eq_exactBlocks
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (project : model.ResearchProject) :
    operatingResearchAdjustment process horizon belief library project =
      expectedOperatingBlock process belief library project +
        process.discount ^ process.duration project *
          expectedFrozenPassiveContinuation process horizon belief library project -
        passiveValue process horizon belief library := by
  unfold operatingResearchAdjustment expectedOperatingBlock
    expectedFrozenPassiveContinuation
  rw [RatProb.expectation_add, RatProb.expectation_const_mul]

/-- Pointwise completion gain is the joint descendant floor plus the remainder. -/
theorem completionContinuationGain_eq_joint_add_remaining
    (process : Model model catalog closure)
    (horizon : Nat) (library : Raw.Library catalog)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (gain : model.Belief → ℚ)
    (completion :
      BeliefPath model (process.duration project) × Raw.CandidateOutcome model) :
    completionContinuationGain process horizon library project completion =
      (if completion.2 = some descendant then
          gain (terminalBelief completion.1)
        else 0) +
        remainingContinuationGain process horizon library project descendant gain
          completion := by
  by_cases hdescendant : completion.2 = some descendant
  · simp [remainingContinuationGain, hdescendant]
  · simp [remainingContinuationGain, hdescendant]

/-- Expected complete continuation splits into joint and remaining terms. -/
theorem expectedCompletionContinuationGain_eq_joint_add_remaining
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (project : model.ResearchProject)
    (descendant : model.StrategyId) (gain : model.Belief → ℚ) :
    (process.completion project belief
      (CompressedLibraryState.ofLibrary catalog closure library)).expectation
        (completionContinuationGain process horizon library project) =
      expectedJointDescendantGain process belief library project descendant gain +
        expectedRemainingContinuationGain process horizon belief library project
          descendant gain := by
  unfold expectedJointDescendantGain expectedRemainingContinuationGain
  rw [← RatProb.expectation_add]
  apply RatProb.expectation_congr
  exact completionContinuationGain_eq_joint_add_remaining
    process horizon library project descendant gain

/--
Exact project commitment accounting.

The initiation cost is paid once.  The operating block is kept separate from
the discounted frozen passive continuation.  The continuation increment then
splits into the declared joint descendant gain and the remaining continuation
after all other outcomes (plus any surplus above the declared floor).
-/
theorem projectCommitmentValue_eq_cost_operating_joint_remaining
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (project : model.ResearchProject)
    (descendant : model.StrategyId) (gain : model.Belief → ℚ) :
    rawProjectActionValue process horizon belief library project =
      -process.researchCost belief
          (CompressedLibraryState.ofLibrary catalog closure library) project +
        expectedOperatingBlock process belief library project +
        process.discount ^ process.duration project *
          (expectedFrozenPassiveContinuation process horizon belief library project +
            expectedJointDescendantGain process belief library project descendant gain +
            expectedRemainingContinuationGain process horizon belief library project
              descendant gain) := by
  have hdecomposition :=
    rawProjectActionValue_sub_passive process horizon belief library project
  have hadjustment :=
    operatingResearchAdjustment_eq_exactBlocks
      process horizon belief library project
  have hcontinuation :=
    expectedCompletionContinuationGain_eq_joint_add_remaining
      process horizon belief library project descendant gain
  calc
    rawProjectActionValue process horizon belief library project =
        passiveValue process horizon belief library +
          (rawProjectActionValue process horizon belief library project -
            passiveValue process horizon belief library) := by ring
    _ = passiveValue process horizon belief library +
          (-process.researchCost belief
              (CompressedLibraryState.ofLibrary catalog closure library) project +
            operatingResearchAdjustment process horizon belief library project +
            process.discount ^ process.duration project *
              (process.completion project belief
                (CompressedLibraryState.ofLibrary catalog closure library)).expectation
                (completionContinuationGain process horizon library project)) := by
          rw [hdecomposition]
    _ = _ := by
          rw [hadjustment, hcontinuation]
          ring

/-- The residual continuation term is pointwise nonnegative under the final certificate. -/
theorem remainingContinuationGain_nonnegative
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (researchCost : ℚ) (gain : model.Belief → ℚ)
    (certificate :
      JointGenerativeCarrierCertificate process horizon belief library strategy
        project descendant researchCost gain)
    (completion :
      BeliefPath model (process.duration project) × Raw.CandidateOutcome model) :
    0 ≤ remainingContinuationGain process horizon (library.insert strategy)
      project descendant gain completion := by
  unfold remainingContinuationGain
  by_cases hdescendant : completion.2 = some descendant
  · rw [if_pos hdescendant]
    have hcompletion :
        completion = (completion.1, some descendant) := by
      apply Prod.ext
      · rfl
      · exact hdescendant
    rw [hcompletion]
    exact sub_nonneg.mpr (certificate.descendant_gain completion.1)
  · rw [if_neg hdescendant]
    exact completionContinuationGain_nonnegative process horizon
      (library.insert strategy) project completion

/-- The expected continuation after omitted outcomes is nonnegative. -/
theorem expectedRemainingContinuationGain_nonnegative
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (researchCost : ℚ) (gain : model.Belief → ℚ)
    (certificate :
      JointGenerativeCarrierCertificate process horizon belief library strategy
        project descendant researchCost gain) :
    0 ≤ expectedRemainingContinuationGain process horizon belief
      (library.insert strategy) project descendant gain := by
  unfold expectedRemainingContinuationGain RatProb.expectation
  apply Finsupp.sum_nonneg
  intro completion _
  exact mul_nonneg
    ((process.completion project belief
      (CompressedLibraryState.ofLibrary catalog closure
        (library.insert strategy))).nonnegative completion)
    (remainingContinuationGain_nonnegative process horizon belief library strategy
      project descendant researchCost gain certificate completion)

/-- Publication-facing generalized T6 under the final no-independence assumptions. -/
theorem generalizedGenerativeOptionLowerBound
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (researchCost : ℚ) (gain : model.Belief → ℚ)
    (certificate :
      JointGenerativeCarrierCertificate process horizon belief library strategy
        project descendant researchCost gain) :
    max
        (-researchCost +
          operatingResearchAdjustment process horizon belief
            (library.insert strategy) project +
          process.discount ^ process.duration project *
            ∑ terminal : model.Belief,
              jointDescendantMass process belief (library.insert strategy)
                project descendant terminal * gain terminal)
        0 ≤
      generativeInsertionValue process horizon belief library strategy :=
  generativeInsertionValue_lowerBound_joint_terminalWeighted
    process horizon belief library strategy project descendant researchCost gain
      certificate

/-- Conditional independence factors the joint gain into admission, survival, and occupation. -/
theorem generalizedJointDescendantGain_eq_independentProduct
    (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (admission survival : ℚ) (gain : model.Belief → ℚ)
    (hindependent : process.ConditionalIndependence)
    (hgeneration :
      process.generation.probability project belief
          (generativeClosure catalog closure library) (some descendant) =
        survival ^ process.duration project)
    (hadmission :
      process.admission.probability project belief
          (generativeClosure catalog closure library) descendant = admission) :
    expectedJointDescendantGain process belief library project descendant gain =
      survival ^ process.duration project * admission *
        expectedTerminalGain process belief project gain :=
  expectedJointDescendantGain_eq_independentProduct process belief library project
    descendant admission survival gain hindependent hgeneration hadmission

/-- Independence factors the joint term and is only a corollary. -/
theorem generalizedGenerativeOptionLowerBound_of_independence
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (researchCost admission survival : ℚ)
    (gain : model.Belief → ℚ)
    (certificate :
      GenerativeCarrierCertificate process horizon belief library strategy
        project descendant researchCost admission survival gain) :
    generativeLowerBound process.discount (process.duration project)
        researchCost admission survival
        (expectedTerminalGain process belief project gain)
        (operatingResearchAdjustment process horizon belief
          (library.insert strategy) project) ≤
      generativeInsertionValue process horizon belief library strategy :=
  generativeInsertionValue_lowerBound_with_operatingAdjustment
    process horizon belief library strategy project descendant researchCost
      admission survival gain certificate

/-- The joint lower-bound expression is monotone in pointwise event mass. -/
theorem generalizedGenerativeOptionLowerBound_mono_jointMass
    {discount researchCost operatingAdjustment : ℚ} {duration : Nat}
    {leftMass rightMass gain : model.Belief → ℚ}
    (hmass : ∀ terminal, leftMass terminal ≤ rightMass terminal)
    (hgain : ∀ terminal, 0 ≤ gain terminal)
    (hdiscount : 0 ≤ discount) :
    jointGenerativeLowerBound discount duration researchCost
        (∑ terminal, leftMass terminal * gain terminal) operatingAdjustment ≤
      jointGenerativeLowerBound discount duration researchCost
        (∑ terminal, rightMass terminal * gain terminal) operatingAdjustment :=
  jointGenerativeLowerBound_mono_mass hmass hgain hdiscount

/-- The joint lower-bound expression is monotone in the pointwise gain floor. -/
theorem generalizedGenerativeOptionLowerBound_mono_gain
    {discount researchCost operatingAdjustment : ℚ} {duration : Nat}
    {mass leftGain rightGain : model.Belief → ℚ}
    (hmass : ∀ terminal, 0 ≤ mass terminal)
    (hgain : ∀ terminal, leftGain terminal ≤ rightGain terminal)
    (hdiscount : 0 ≤ discount) :
    jointGenerativeLowerBound discount duration researchCost
        (∑ terminal, mass terminal * leftGain terminal) operatingAdjustment ≤
      jointGenerativeLowerBound discount duration researchCost
        (∑ terminal, mass terminal * rightGain terminal) operatingAdjustment :=
  jointGenerativeLowerBound_mono_gainFunction hmass hgain hdiscount

/-- The joint lower-bound expression is antitone in initiation cost. -/
theorem generalizedGenerativeOptionLowerBound_antitone_cost
    {discount leftCost rightCost expectedJointGain operatingAdjustment : ℚ}
    {duration : Nat} (hcost : leftCost ≤ rightCost) :
    jointGenerativeLowerBound discount duration rightCost expectedJointGain
        operatingAdjustment ≤
      jointGenerativeLowerBound discount duration leftCost expectedJointGain
        operatingAdjustment :=
  jointGenerativeLowerBound_antitone_researchCost hcost

/--
There is no unconditional duration monotonicity when duration changes the
joint term or operating block.  The first exact comparison increases the
joint term at the longer duration; the second holds the joint term fixed and
shows ordinary discounting in the opposite direction.
-/
theorem no_unconditional_duration_monotonicity :
    jointGenerativeLowerBound (1 / 2 : ℚ) 1 0 0 0 <
        jointGenerativeLowerBound (1 / 2 : ℚ) 2 0 8 0 ∧
      jointGenerativeLowerBound (1 / 2 : ℚ) 2 0 1 0 <
        jointGenerativeLowerBound (1 / 2 : ℚ) 1 0 1 0 := by
  norm_num [jointGenerativeLowerBound]

namespace OneBeliefExample

/-- The existing exact carrier is the canonical one-belief joint-law example. -/
theorem exact_lowerBound_one :
    jointGenerativeLowerBound CarrierExample.process.discount
        (CarrierExample.process.duration
          StrategyInnovation.FrontierPruningLoss.Project.innovate)
        0
        (expectedJointDescendantGain CarrierExample.process
          StrategyInnovation.FrontierPruningLoss.Belief.only
          ((StrategyInnovation.FrontierPruningLoss.prunedLibrary 2).insert
            StrategyInnovation.FrontierPruningLoss.Strategy.dominated)
          StrategyInnovation.FrontierPruningLoss.Project.innovate
          StrategyInnovation.FrontierPruningLoss.Strategy.future
          (fun _ => 2))
        0 = 1 :=
  CarrierExample.exact_joint_carrier_lowerBound_one.1

end OneBeliefExample

namespace TwoBeliefExample

inductive Belief
  | low
  | high
  deriving DecidableEq, Fintype

inductive Outcome
  | failure
  | descendant
  deriving DecidableEq, Fintype

/-- A correlated exact joint law: failure occurs low and the descendant occurs high. -/
noncomputable def completionLaw : RatProb (Belief × Outcome) where
  mass :=
    Finsupp.single (Belief.low, Outcome.failure) (1 / 2) +
      Finsupp.single (Belief.high, Outcome.descendant) (1 / 2)
  nonnegative := by
    classical
    intro completion
    rcases completion with ⟨belief, outcome⟩
    cases belief <;> cases outcome <;>
      simp
  totalMass := by
    classical
    rw [Finsupp.sum_add_index' (by intros; rfl) (by intros; rfl)]
    rw [Finsupp.sum_single_index (by rfl),
      Finsupp.sum_single_index (by rfl)]
    norm_num

/-- Terminal joint descendant mass in the exact two-belief law. -/
noncomputable def jointMass (terminal : Belief) : ℚ :=
  completionLaw.probability (terminal, Outcome.descendant)

/-- The descendant has zero joint mass at low belief and one-half at high belief. -/
theorem jointMass_exact :
    jointMass Belief.low = 0 ∧ jointMass Belief.high = 1 / 2 := by
  classical
  simp [jointMass, completionLaw, RatProb.probability]

/-- The exact gain floor is zero at low belief and four at high belief. -/
def gain : Belief → ℚ
  | .low => 0
  | .high => 4

/-- The correlated two-belief joint descendant gain is exactly two. -/
theorem expectedJointGain_eq_two :
    ∑ terminal : Belief, jointMass terminal * gain terminal = 2 := by
  classical
  rw [show (Finset.univ : Finset Belief) = {Belief.low, Belief.high} by decide]
  simp [jointMass, gain, completionLaw, RatProb.probability]
  norm_num

/-- At discount one-half and duration one, the exact joint guarantee is one. -/
theorem exact_lowerBound_one :
    jointGenerativeLowerBound (1 / 2 : ℚ) 1 0
        (∑ terminal : Belief, jointMass terminal * gain terminal) 0 = 1 := by
  rw [expectedJointGain_eq_two]
  norm_num [jointGenerativeLowerBound]

end TwoBeliefExample

end GenerativeLowerBound

end Model

end Projection

end StrategyInnovation
