import Mathlib.Tactic
import StrategyInnovation.Value.UnifiedDecomposition

/-!
# Generative strategy lower bound (T6)

This module proves the retained-carrier lower bound on the unified raw process.
The project completion law is the T1 law derived from raw generation and
admission.  The product formula for the distinguished descendant uses an
explicit conditional-independence assumption; the general T1 projection does
not require that assumption.

The timing correction is exposed as `operatingResearchAdjustment`.  It is the
difference between (i) incumbent rewards earned during the project plus the
frozen-library passive continuation at completion and (ii) the passive value
of not starting the project.  Thus the no-adjustment formula is asserted only
when those two passive baselines match.  Suspended operation can make the
adjustment negative.
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

/-- Exact raw unified-timing value of committing to one project now. -/
noncomputable def rawProjectActionValue
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (project : model.ResearchProject) : ℚ :=
  -process.researchCost belief
      (CompressedLibraryState.ofLibrary catalog closure library) project +
    (process.completion project belief
      (CompressedLibraryState.ofLibrary catalog closure library)).expectation
      (fun completion =>
        process.incumbentReward
            (CompressedLibraryState.ofLibrary catalog closure library)
            project completion.1 +
          process.discount ^ process.duration project *
            fullValue process (horizon - process.duration project)
              (terminalBelief completion.1)
              (Raw.rawLibraryUpdate library completion.2))

/--
Exact timing adjustment relative to keeping the current library frozen.
Continued operation with the declared Markov path law is the economically
important zero-adjustment case; suspended operation records foregone passive
rewards here instead of silently dropping them.
-/
noncomputable def operatingResearchAdjustment
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (project : model.ResearchProject) : ℚ :=
  (process.completion project belief
    (CompressedLibraryState.ofLibrary catalog closure library)).expectation
      (fun completion =>
        process.incumbentReward
            (CompressedLibraryState.ofLibrary catalog closure library)
            project completion.1 +
          process.discount ^ process.duration project *
            passiveValue process (horizon - process.duration project)
              (terminalBelief completion.1) library) -
    passiveValue process horizon belief library

/-- Completion-date full-value improvement over the frozen retained library. -/
noncomputable def completionContinuationGain
    (process : Model model catalog closure)
    (horizon : Nat) (library : Raw.Library catalog)
    (project : model.ResearchProject)
    (completion :
      BeliefPath model (process.duration project) × Raw.CandidateOutcome model) : ℚ :=
  fullValue process (horizon - process.duration project)
      (terminalBelief completion.1)
      (Raw.rawLibraryUpdate library completion.2) -
    passiveValue process (horizon - process.duration project)
      (terminalBelief completion.1) library

/-- The full Bellman value weakly dominates every feasible committed project. -/
theorem rawProjectActionValue_le_fullValue
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (project : model.ResearchProject)
    (havailable :
      project ∈ process.available
        (CompressedLibraryState.ofLibrary catalog closure library))
    (hfits : process.duration project ≤ horizon) :
    rawProjectActionValue process horizon belief library project ≤
      fullValue process horizon belief library := by
  have hhorizon : 0 < horizon :=
    lt_of_lt_of_le (process.duration_positive project) hfits
  obtain ⟨remaining, rfl⟩ := Nat.exists_eq_succ_of_ne_zero (Nat.ne_of_gt hhorizon)
  unfold fullValue rawProjectActionValue
  simp only [rawValue]
  let action :
      FeasibleAction process (remaining + 1)
        (CompressedLibraryState.ofLibrary catalog closure library) :=
    ⟨some project, ⟨havailable, hfits⟩⟩
  exact Finset.le_sup'
    (fun feasible :
      FeasibleAction process (remaining + 1)
        (CompressedLibraryState.ofLibrary catalog closure library) =>
      match feasible.1 with
      | none =>
          operationalFrontier catalog library belief +
            process.discount *
              (process.beliefTransition belief).expectation
                (fun nextBelief =>
                  process.rawValue remaining nextBelief library)
      | some selected =>
          -process.researchCost belief
              (CompressedLibraryState.ofLibrary catalog closure library) selected +
            (process.completion selected belief
              (CompressedLibraryState.ofLibrary catalog closure library)).expectation
              (fun completion =>
                process.incumbentReward
                    (CompressedLibraryState.ofLibrary catalog closure library)
                    selected completion.1 +
                  process.discount ^ process.duration selected *
                    process.rawValue
                      ((remaining + 1) - process.duration selected)
                      (terminalBelief completion.1)
                      (Raw.rawLibraryUpdate library completion.2)))
    (Finset.mem_univ action)

/-- Passive value is monotone under raw library inclusion. -/
theorem passiveValue_mono_of_library_inclusion
    (process : Model model catalog closure)
    {left right : Raw.Library catalog} (hinclude : left ≤ right) :
    ∀ horizon belief,
      passiveValue process horizon belief left ≤
        passiveValue process horizon belief right := by
  intro horizon
  induction horizon with
  | zero =>
      intro belief
      rfl
  | succ horizon inductionHypothesis =>
      intro belief
      simp only [passiveValue]
      apply add_le_add
      · exact operationalFrontier_mono catalog hinclude belief
      · apply mul_le_mul_of_nonneg_left
        · exact expectation_mono _ inductionHypothesis
        · exact process.discount_nonnegative

/-- Frozen-library passive value is nonnegative because the inactive strategy is present. -/
theorem passiveValue_nonnegative
    (process : Model model catalog closure) :
    ∀ horizon belief library,
      0 ≤ passiveValue process horizon belief library := by
  intro horizon
  induction horizon with
  | zero =>
      intros
      simp [passiveValue]
  | succ horizon inductionHypothesis =>
      intro belief library
      simp only [passiveValue]
      apply add_nonneg
      · exact zero_le_operationalFrontier catalog library belief
      · apply mul_nonneg process.discount_nonnegative
        have hexpectation :=
          expectation_mono
            (process.beliefTransition belief)
            (left := fun _ => (0 : ℚ))
            (right := fun nextBelief =>
              passiveValue process horizon nextBelief library)
            (fun nextBelief => inductionHypothesis nextBelief library)
        simpa [RatProb.expectation] using hexpectation

/-- Allowing research cannot lower value below the frozen Continue policy. -/
theorem passiveValue_le_fullValue
    (process : Model model catalog closure) :
    ∀ horizon belief library,
      passiveValue process horizon belief library ≤
        fullValue process horizon belief library := by
  intro horizon
  induction horizon with
  | zero =>
      intro belief library
      simp [passiveValue, fullValue, rawValue]
  | succ horizon inductionHypothesis =>
      intro belief library
      unfold fullValue
      simp only [passiveValue, rawValue]
      let action :
          FeasibleAction process (horizon + 1)
            (CompressedLibraryState.ofLibrary catalog closure library) :=
        ⟨none, trivial⟩
      apply le_trans
        (show
          operationalFrontier catalog library belief +
                process.discount *
                  (process.beliefTransition belief).expectation
                    (fun nextBelief =>
                      passiveValue process horizon nextBelief library) ≤
            operationalFrontier catalog library belief +
                process.discount *
                  (process.beliefTransition belief).expectation
                    (fun nextBelief =>
                      process.rawValue horizon nextBelief library) by
          have hcontinuation :
              process.discount *
                    (process.beliefTransition belief).expectation
                      (fun nextBelief =>
                        passiveValue process horizon nextBelief library) ≤
                process.discount *
                    (process.beliefTransition belief).expectation
                      (fun nextBelief =>
                        process.rawValue horizon nextBelief library) := by
            apply mul_le_mul_of_nonneg_left
            · apply expectation_mono
              intro nextBelief
              exact inductionHypothesis nextBelief library
            · exact process.discount_nonnegative
          linarith)
      exact Finset.le_sup'
        (fun feasible :
          FeasibleAction process (horizon + 1)
            (CompressedLibraryState.ofLibrary catalog closure library) =>
          match feasible.1 with
          | none =>
              operationalFrontier catalog library belief +
                process.discount *
                  (process.beliefTransition belief).expectation
                    (fun nextBelief =>
                      process.rawValue horizon nextBelief library)
          | some selected =>
              -process.researchCost belief
                  (CompressedLibraryState.ofLibrary catalog closure library) selected +
                (process.completion selected belief
                  (CompressedLibraryState.ofLibrary catalog closure library)).expectation
                  (fun completion =>
                    process.incumbentReward
                        (CompressedLibraryState.ofLibrary catalog closure library)
                        selected completion.1 +
                      process.discount ^ process.duration selected *
                        process.rawValue
                          ((horizon + 1) - process.duration selected)
                          (terminalBelief completion.1)
                          (Raw.rawLibraryUpdate library completion.2)))
        (Finset.mem_univ action)

/-- A raw completion never removes an incumbent catalog strategy. -/
theorem library_le_rawLibraryUpdate
    (library : Raw.Library catalog) (outcome : Raw.CandidateOutcome model) :
    library ≤ Raw.rawLibraryUpdate library outcome := by
  cases outcome with
  | none => rfl
  | some strategy =>
      exact StrategyInnovation.Library.le_insert library strategy

/-- Every completion's continuation gain is nonnegative. -/
theorem completionContinuationGain_nonnegative
    (process : Model model catalog closure)
    (horizon : Nat) (library : Raw.Library catalog)
    (project : model.ResearchProject)
    (completion :
      BeliefPath model (process.duration project) × Raw.CandidateOutcome model) :
    0 ≤ completionContinuationGain process horizon library project completion := by
  have hpassiveUpdate :
      passiveValue process (horizon - process.duration project)
          (terminalBelief completion.1) library ≤
        passiveValue process (horizon - process.duration project)
          (terminalBelief completion.1)
          (Raw.rawLibraryUpdate library completion.2) :=
    passiveValue_mono_of_library_inclusion process
      (library_le_rawLibraryUpdate library completion.2) _ _
  have hfull :
      passiveValue process (horizon - process.duration project)
          (terminalBelief completion.1)
          (Raw.rawLibraryUpdate library completion.2) ≤
        fullValue process (horizon - process.duration project)
          (terminalBelief completion.1)
          (Raw.rawLibraryUpdate library completion.2) :=
    passiveValue_le_fullValue process _ _ _
  unfold completionContinuationGain
  linarith

/-- Exact decomposition of committed-project advantage under unified timing. -/
theorem rawProjectActionValue_sub_passive
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (project : model.ResearchProject) :
    rawProjectActionValue process horizon belief library project -
        passiveValue process horizon belief library =
      -process.researchCost belief
          (CompressedLibraryState.ofLibrary catalog closure library) project +
        operatingResearchAdjustment process horizon belief library project +
        process.discount ^ process.duration project *
          (process.completion project belief
            (CompressedLibraryState.ofLibrary catalog closure library)).expectation
            (completionContinuationGain process horizon library project) := by
  let distribution :=
    process.completion project belief
      (CompressedLibraryState.ofLibrary catalog closure library)
  have hsplit :
      distribution.expectation
          (fun completion =>
            process.incumbentReward
                (CompressedLibraryState.ofLibrary catalog closure library)
                project completion.1 +
              process.discount ^ process.duration project *
                fullValue process (horizon - process.duration project)
                  (terminalBelief completion.1)
                  (Raw.rawLibraryUpdate library completion.2)) =
        distribution.expectation
            (fun completion =>
              process.incumbentReward
                  (CompressedLibraryState.ofLibrary catalog closure library)
                  project completion.1 +
                process.discount ^ process.duration project *
                  passiveValue process (horizon - process.duration project)
                    (terminalBelief completion.1) library) +
          process.discount ^ process.duration project *
            distribution.expectation
              (completionContinuationGain process horizon library project) := by
    calc
      _ = distribution.expectation
          (fun completion =>
            (process.incumbentReward
                (CompressedLibraryState.ofLibrary catalog closure library)
                project completion.1 +
              process.discount ^ process.duration project *
                passiveValue process (horizon - process.duration project)
                  (terminalBelief completion.1) library) +
            process.discount ^ process.duration project *
              completionContinuationGain process horizon library project completion) := by
            apply RatProb.expectation_congr
            intro completion
            unfold completionContinuationGain
            ring
      _ = distribution.expectation
            (fun completion =>
              process.incumbentReward
                  (CompressedLibraryState.ofLibrary catalog closure library)
                  project completion.1 +
                process.discount ^ process.duration project *
                  passiveValue process (horizon - process.duration project)
                    (terminalBelief completion.1) library) +
          distribution.expectation
            (fun completion =>
              process.discount ^ process.duration project *
                completionContinuationGain process horizon library project completion) := by
            rw [RatProb.expectation_add]
      _ = _ := by
            rw [RatProb.expectation_const_mul]
  unfold rawProjectActionValue operatingResearchAdjustment
  change
    -process.researchCost belief
          (CompressedLibraryState.ofLibrary catalog closure library) project +
        distribution.expectation
          (fun completion =>
            process.incumbentReward
                (CompressedLibraryState.ofLibrary catalog closure library)
                project completion.1 +
              process.discount ^ process.duration project *
                fullValue process (horizon - process.duration project)
                  (terminalBelief completion.1)
                  (Raw.rawLibraryUpdate library completion.2)) -
        passiveValue process horizon belief library =
      -process.researchCost belief
          (CompressedLibraryState.ofLibrary catalog closure library) project +
        (distribution.expectation
            (fun completion =>
              process.incumbentReward
                  (CompressedLibraryState.ofLibrary catalog closure library)
                  project completion.1 +
                process.discount ^ process.duration project *
                  passiveValue process (horizon - process.duration project)
                    (terminalBelief completion.1) library) -
          passiveValue process horizon belief library) +
        process.discount ^ process.duration project *
          distribution.expectation
            (completionContinuationGain process horizon library project)
  rw [hsplit]
  ring

/-- Exact finite path occupation of a terminal-gain function. -/
noncomputable def expectedTerminalGain
    (process : Model model catalog closure)
    (belief : model.Belief) (project : model.ResearchProject)
    (gain : model.Belief → ℚ) : ℚ :=
  ∑ path : BeliefPath model (process.duration project),
    markovPathMass process.beliefTransition belief
      (process.duration project) path * gain (terminalBelief path)

/-- Terminal-belief occupation weight induced by all full project paths. -/
noncomputable def terminalOccupationWeight
    (process : Model model catalog closure)
    (belief : model.Belief) (project : model.ResearchProject)
    (terminal : model.Belief) : ℚ :=
  ∑ path : BeliefPath model (process.duration project),
    if terminalBelief path = terminal then
      markovPathMass process.beliefTransition belief
        (process.duration project) path
    else 0

/-- Markov path masses are nonnegative. -/
theorem markovPathMass_nonnegative
    (process : Model model catalog closure)
    (belief : model.Belief) (project : model.ResearchProject)
    (path : BeliefPath model (process.duration project)) :
    0 ≤ markovPathMass process.beliefTransition belief
      (process.duration project) path := by
  unfold markovPathMass
  split
  · exact Finset.prod_nonneg fun time _ =>
      (process.beliefTransition (path time.castSucc)).nonnegative
        (path time.succ)
  · norm_num

/-- Expected terminal gain is monotone pointwise in the gain function. -/
theorem expectedTerminalGain_mono
    (process : Model model catalog closure)
    (belief : model.Belief) (project : model.ResearchProject)
    {left right : model.Belief → ℚ}
    (hgain : ∀ terminal, left terminal ≤ right terminal) :
    expectedTerminalGain process belief project left ≤
      expectedTerminalGain process belief project right := by
  unfold expectedTerminalGain
  apply Finset.sum_le_sum
  intro path _
  exact mul_le_mul_of_nonneg_left
    (hgain (terminalBelief path))
    (markovPathMass_nonnegative process belief project path)

/-- The path expectation is the finite occupation-weighted belief sum. -/
theorem expectedTerminalGain_eq_occupationWeighted
    (process : Model model catalog closure)
    (belief : model.Belief) (project : model.ResearchProject)
    (gain : model.Belief → ℚ) :
    expectedTerminalGain process belief project gain =
      ∑ terminal : model.Belief,
        terminalOccupationWeight process belief project terminal *
          gain terminal := by
  classical
  unfold expectedTerminalGain terminalOccupationWeight
  simp_rw [Finset.sum_mul]
  rw [Finset.sum_comm]
  apply Finset.sum_congr rfl
  intro path _
  simp

/--
Joint mass of reaching `terminal` and admitting the distinguished descendant.
Unlike `terminalOccupationWeight`, this is read directly from the unified
completion law and makes no path/outcome independence assumption.
-/
noncomputable def jointDescendantMass
    (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (terminal : model.Belief) : ℚ :=
  ∑ path : BeliefPath model (process.duration project),
    if terminalBelief path = terminal then
      (process.completion project belief
        (CompressedLibraryState.ofLibrary catalog closure library)).probability
          (path, some descendant)
    else 0

/--
The distinguished descendant's gain under the joint path/admission law.  This
is the primitive quantity in the generalized T6 bound.
-/
noncomputable def expectedJointDescendantGain
    (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (gain : model.Belief → ℚ) : ℚ :=
  (process.completion project belief
    (CompressedLibraryState.ofLibrary catalog closure library)).expectation
      (fun completion =>
        if completion.2 = some descendant then
          gain (terminalBelief completion.1)
        else 0)

/-- Joint descendant gain is the exact terminal-belief weighted joint mass. -/
theorem expectedJointDescendantGain_eq_terminalWeighted
    (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (gain : model.Belief → ℚ) :
    expectedJointDescendantGain process belief library project descendant gain =
      ∑ terminal : model.Belief,
        jointDescendantMass process belief library project descendant terminal *
          gain terminal := by
  classical
  unfold expectedJointDescendantGain jointDescendantMass RatProb.expectation
  rw [Finsupp.sum_fintype _ _ (by simp), Fintype.sum_prod_type]
  change
    (∑ path, ∑ outcome,
      (process.completion project belief
        (CompressedLibraryState.ofLibrary catalog closure library)).probability
          (path, outcome) *
        (if outcome = some descendant then gain (terminalBelief path) else 0)) =
      ∑ terminal,
        (∑ path,
          if terminalBelief path = terminal then
            (process.completion project belief
              (CompressedLibraryState.ofLibrary catalog closure library)).probability
                (path, some descendant)
          else 0) *
        gain terminal
  simp_rw [Finset.sum_mul]
  conv_rhs => rw [Finset.sum_comm]
  apply Finset.sum_congr rfl
  intro path _
  simp

/-- Joint descendant gain is monotone in the pointwise gain floor. -/
theorem expectedJointDescendantGain_mono
    (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    {left right : model.Belief → ℚ}
    (hgain : ∀ terminal, left terminal ≤ right terminal) :
    expectedJointDescendantGain process belief library project descendant left ≤
      expectedJointDescendantGain process belief library project descendant right := by
  unfold expectedJointDescendantGain
  apply expectation_mono
  intro completion
  split
  · exact hgain (terminalBelief completion.1)
  · rfl

/-- Success-only continuation expectation under explicit raw independence. -/
theorem expected_success_gain_eq
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
    (process.completion project belief
      (CompressedLibraryState.ofLibrary catalog closure library)).expectation
        (fun completion =>
          if completion.2 = some descendant then gain (terminalBelief completion.1)
          else 0) =
      survival ^ process.duration project * admission *
        expectedTerminalGain process belief project gain := by
  classical
  have hadmitted :
      (Raw.admittedCandidateDistribution process.generation process.admission
        project belief (generativeClosure catalog closure library)).probability
          (some descendant) =
        survival ^ process.duration project * admission := by
    rw [Raw.admittedCandidateDistribution_probability]
    simp only [Raw.admittedCandidateMass]
    rw [hgeneration, hadmission]
  unfold RatProb.expectation
  rw [Finsupp.sum_fintype _ _ (by simp), Fintype.sum_prod_type]
  change
    (∑ path, ∑ outcome,
      (process.completion project belief
        (CompressedLibraryState.ofLibrary catalog closure library)).probability
          (path, outcome) *
        (if outcome = some descendant then gain (terminalBelief path) else 0)) =
      survival ^ process.duration project * admission *
        expectedTerminalGain process belief project gain
  simp_rw [hindependent project belief
    (CompressedLibraryState.ofLibrary catalog closure library)]
  change
    (∑ path, ∑ outcome,
      (markovPathMass process.beliefTransition belief
          (process.duration project) path *
        (Raw.admittedCandidateDistribution process.generation process.admission
          project belief (generativeClosure catalog closure library)).probability
            outcome) *
        (if outcome = some descendant then gain (terminalBelief path) else 0)) =
      survival ^ process.duration project * admission *
        expectedTerminalGain process belief project gain
  unfold expectedTerminalGain
  rw [Finset.mul_sum]
  apply Finset.sum_congr rfl
  intro path _
  simp [Raw.admittedCandidateDistribution_probability,
    Raw.admittedCandidateMass, hgeneration, hadmission]
  ring

/--
Independence factors the joint descendant term into the current
`π ρ^d` terminal-occupation formula.  This is a corollary of the joint object,
not an assumption of the generalized theorem.
-/
theorem expectedJointDescendantGain_eq_independentProduct
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
        expectedTerminalGain process belief project gain := by
  exact expected_success_gain_eq process belief library project descendant
    admission survival gain hindependent hgeneration hadmission

/--
Raw carrier assumptions for the joint-law T6 theorem.  The inserted strategy
is frontier-silent, enables a project absent without it, and the deleted
comparator has zero research premium.  The gain floor holds path by path for
the complete continuation value after admitting the distinguished descendant.
No independence between the belief path and admitted outcome is assumed.
-/
structure JointGenerativeCarrierCertificate
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (researchCost : ℚ)
    (gain : model.Belief → ℚ) : Prop where
  frontier_silent :
    operationalFrontier catalog (library.insert strategy) =
      operationalFrontier catalog library
  project_enabled :
    project ∈ process.available
      (CompressedLibraryState.ofLibrary catalog closure
        (library.insert strategy))
  project_unavailable_without :
    project ∉ process.available
      (CompressedLibraryState.ofLibrary catalog closure library)
  duration_fits : process.duration project ≤ horizon
  researchCost_eq :
    process.researchCost belief
        (CompressedLibraryState.ofLibrary catalog closure
          (library.insert strategy)) project =
      researchCost
  deleted_premium_zero :
    researchOptionPremium process horizon belief library = 0
  gain_nonnegative : ∀ terminal, 0 ≤ gain terminal
  descendant_gain :
    ∀ path : BeliefPath model (process.duration project),
      gain (terminalBelief path) ≤
        completionContinuationGain process horizon
          (library.insert strategy) project (path, some descendant)

/--
Product-form carrier assumptions retained for the independence corollary.
Primitive generation and admission supply `ρ^d` and `π`; conditional
independence is used only to factor the joint descendant mass.
-/
structure GenerativeCarrierCertificate
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (researchCost admission survival : ℚ)
    (gain : model.Belief → ℚ) : Prop where
  frontier_silent :
    operationalFrontier catalog (library.insert strategy) =
      operationalFrontier catalog library
  project_enabled :
    project ∈ process.available
      (CompressedLibraryState.ofLibrary catalog closure
        (library.insert strategy))
  project_unavailable_without :
    project ∉ process.available
      (CompressedLibraryState.ofLibrary catalog closure library)
  duration_fits : process.duration project ≤ horizon
  researchCost_eq :
    process.researchCost belief
        (CompressedLibraryState.ofLibrary catalog closure
          (library.insert strategy)) project =
      researchCost
  deleted_premium_zero :
    researchOptionPremium process horizon belief library = 0
  conditional_independence : process.ConditionalIndependence
  generation_probability :
    process.generation.probability project belief
        (generativeClosure catalog closure (library.insert strategy))
        (some descendant) =
      survival ^ process.duration project
  admission_probability :
    process.admission.probability project belief
        (generativeClosure catalog closure (library.insert strategy))
        descendant =
      admission
  admission_nonnegative : 0 ≤ admission
  admission_le_one : admission ≤ 1
  survival_nonnegative : 0 ≤ survival
  survival_le_one : survival ≤ 1
  gain_nonnegative : ∀ terminal, 0 ≤ gain terminal
  descendant_gain :
    ∀ path : BeliefPath model (process.duration project),
      gain (terminalBelief path) ≤
        completionContinuationGain process horizon
          (library.insert strategy) project (path, some descendant)

/-- Forget the product factorization and retain exactly the joint-law hypotheses. -/
theorem GenerativeCarrierCertificate.toJoint
    {process : Model model catalog closure}
    {horizon : Nat} {belief : model.Belief}
    {library : Raw.Library catalog} {strategy : model.StrategyId}
    {project : model.ResearchProject} {descendant : model.StrategyId}
    {researchCost admission survival : ℚ}
    {gain : model.Belief → ℚ}
    (certificate :
      GenerativeCarrierCertificate process horizon belief library strategy
        project descendant researchCost admission survival gain) :
    JointGenerativeCarrierCertificate process horizon belief library strategy
      project descendant researchCost gain where
  frontier_silent := certificate.frontier_silent
  project_enabled := certificate.project_enabled
  project_unavailable_without := certificate.project_unavailable_without
  duration_fits := certificate.duration_fits
  researchCost_eq := certificate.researchCost_eq
  deleted_premium_zero := certificate.deleted_premium_zero
  gain_nonnegative := certificate.gain_nonnegative
  descendant_gain := certificate.descendant_gain

/-- Exact joint-law scalar guarantee, including the unified operating adjustment. -/
def jointGenerativeLowerBound
    (discount : ℚ) (duration : Nat)
    (researchCost expectedJointGain operatingAdjustment : ℚ) : ℚ :=
  max
    (-researchCost + operatingAdjustment +
      discount ^ duration * expectedJointGain)
    0

/-- The exact scalar guarantee, including the unified operating adjustment. -/
def generativeLowerBound
    (discount : ℚ) (duration : Nat) (researchCost admission survival
      expectedGain operatingAdjustment : ℚ) : ℚ :=
  max
    (-researchCost + operatingAdjustment +
      discount ^ duration * admission * survival ^ duration * expectedGain)
    0

/--
The complete continuation expectation weakly exceeds the distinguished
descendant term under the joint law.  Non-distinguished outcomes may be
ignored here because raw insertion never removes an incumbent, passive value
is monotone under insertion, and full value dominates passive value.
-/
theorem jointDescendant_expectedGain_le
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (researchCost : ℚ) (gain : model.Belief → ℚ)
    (certificate :
      JointGenerativeCarrierCertificate process horizon belief library strategy
        project descendant researchCost gain) :
    expectedJointDescendantGain process belief (library.insert strategy)
        project descendant gain ≤
      (process.completion project belief
        (CompressedLibraryState.ofLibrary catalog closure
          (library.insert strategy))).expectation
        (completionContinuationGain process horizon
          (library.insert strategy) project) := by
  unfold expectedJointDescendantGain
  apply expectation_mono
  intro completion
  by_cases hsuccess : completion.2 = some descendant
  · rw [if_pos hsuccess]
    have hcompletion :
        completion = (completion.1, some descendant) := by
      apply Prod.ext
      · rfl
      · exact hsuccess
    rw [hcompletion]
    exact certificate.descendant_gain completion.1
  · rw [if_neg hsuccess]
    exact completionContinuationGain_nonnegative process horizon
      (library.insert strategy) project completion

/--
Generalized T6 under the joint path/admission law.  This theorem does not
assume conditional independence.  The exact operating adjustment is retained,
and `duration_fits` excludes projects that complete after the finite horizon.
-/
theorem generativeInsertionValue_lowerBound_joint
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (researchCost : ℚ) (gain : model.Belief → ℚ)
    (certificate :
      JointGenerativeCarrierCertificate process horizon belief library strategy
        project descendant researchCost gain) :
    jointGenerativeLowerBound process.discount (process.duration project)
        researchCost
        (expectedJointDescendantGain process belief (library.insert strategy)
          project descendant gain)
        (operatingResearchAdjustment process horizon belief
          (library.insert strategy) project) ≤
      generativeInsertionValue process horizon belief library strategy := by
  have hgenerativeNonnegative :
      0 ≤ generativeInsertionValue process horizon belief library strategy := by
    unfold generativeInsertionValue
    rw [certificate.deleted_premium_zero]
    have hrichPremiumNonnegative :
        0 ≤ researchOptionPremium process horizon belief
          (library.insert strategy) := by
      unfold researchOptionPremium
      exact sub_nonneg.mpr
        (passiveValue_le_fullValue process horizon belief
          (library.insert strategy))
    linarith
  have hproject :
      rawProjectActionValue process horizon belief
          (library.insert strategy) project ≤
        fullValue process horizon belief (library.insert strategy) :=
    rawProjectActionValue_le_fullValue process horizon belief
      (library.insert strategy) project certificate.project_enabled
      certificate.duration_fits
  have hjoint :=
    jointDescendant_expectedGain_le process horizon belief library strategy
      project descendant researchCost gain certificate
  have hdiscountPow :
      0 ≤ process.discount ^ process.duration project :=
    pow_nonneg process.discount_nonnegative _
  have hjointDiscounted :
      process.discount ^ process.duration project *
          expectedJointDescendantGain process belief (library.insert strategy)
            project descendant gain ≤
        process.discount ^ process.duration project *
          (process.completion project belief
            (CompressedLibraryState.ofLibrary catalog closure
              (library.insert strategy))).expectation
            (completionContinuationGain process horizon
              (library.insert strategy) project) :=
    mul_le_mul_of_nonneg_left hjoint hdiscountPow
  have hidentity :=
    rawProjectActionValue_sub_passive process horizon belief
      (library.insert strategy) project
  rw [certificate.researchCost_eq] at hidentity
  have hgenerative :
      generativeInsertionValue process horizon belief library strategy =
        fullValue process horizon belief (library.insert strategy) -
          passiveValue process horizon belief (library.insert strategy) := by
    unfold generativeInsertionValue
    rw [certificate.deleted_premium_zero]
    unfold researchOptionPremium
    ring
  have hnet :
      -researchCost +
          operatingResearchAdjustment process horizon belief
            (library.insert strategy) project +
          process.discount ^ process.duration project *
            expectedJointDescendantGain process belief
              (library.insert strategy) project descendant gain ≤
        generativeInsertionValue process horizon belief library strategy := by
    rw [hgenerative]
    nlinarith
  unfold jointGenerativeLowerBound
  exact max_le hnet hgenerativeNonnegative

/-- Terminal-belief sum form of the joint-law theorem. -/
theorem generativeInsertionValue_lowerBound_joint_terminalWeighted
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
      generativeInsertionValue process horizon belief library strategy := by
  have hbound :=
    generativeInsertionValue_lowerBound_joint process horizon belief library
      strategy project descendant researchCost gain certificate
  rw [expectedJointDescendantGain_eq_terminalWeighted] at hbound
  simpa [jointGenerativeLowerBound] using hbound

/-- Each terminal component of the joint descendant law is nonnegative. -/
theorem jointDescendantMass_nonnegative
    (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (terminal : model.Belief) :
    0 ≤ jointDescendantMass process belief library project descendant terminal := by
  classical
  unfold jointDescendantMass
  apply Finset.sum_nonneg
  intro path _
  by_cases hterminal : terminalBelief path = terminal
  · rw [if_pos hterminal]
    exact
      (process.completion project belief
        (CompressedLibraryState.ofLibrary catalog closure library)).nonnegative
          (path, some descendant)
  · rw [if_neg hterminal]

/-- The joint terminal sum is monotone in pointwise descendant-event mass. -/
theorem jointTerminalWeightedGain_mono_mass
    {leftMass rightMass gain : model.Belief → ℚ}
    (hmass : ∀ terminal, leftMass terminal ≤ rightMass terminal)
    (hgain : ∀ terminal, 0 ≤ gain terminal) :
    (∑ terminal, leftMass terminal * gain terminal) ≤
      ∑ terminal, rightMass terminal * gain terminal := by
  apply Finset.sum_le_sum
  intro terminal _
  exact mul_le_mul_of_nonneg_right (hmass terminal) (hgain terminal)

/-- The joint terminal sum is monotone in the pointwise continuation floor. -/
theorem jointTerminalWeightedGain_mono_gain
    {mass leftGain rightGain : model.Belief → ℚ}
    (hmass : ∀ terminal, 0 ≤ mass terminal)
    (hgain : ∀ terminal, leftGain terminal ≤ rightGain terminal) :
    (∑ terminal, mass terminal * leftGain terminal) ≤
      ∑ terminal, mass terminal * rightGain terminal := by
  apply Finset.sum_le_sum
  intro terminal _
  exact mul_le_mul_of_nonneg_left (hgain terminal) (hmass terminal)

/-- Nonnegative pointwise floors give a nonnegative joint descendant term. -/
theorem expectedJointDescendantGain_nonnegative
    (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (gain : model.Belief → ℚ) (hgain : ∀ terminal, 0 ≤ gain terminal) :
    0 ≤ expectedJointDescendantGain process belief library project descendant gain := by
  rw [expectedJointDescendantGain_eq_terminalWeighted]
  apply Finset.sum_nonneg
  intro terminal _
  exact mul_nonneg
    (jointDescendantMass_nonnegative process belief library project descendant terminal)
    (hgain terminal)

/-- The joint guarantee is zero exactly when adjusted joint gain does not cover cost. -/
theorem jointGenerativeLowerBound_eq_zero_iff
    {discount researchCost expectedJointGain operatingAdjustment : ℚ}
    {duration : Nat} :
    jointGenerativeLowerBound discount duration researchCost expectedJointGain
        operatingAdjustment = 0 ↔
      operatingAdjustment + discount ^ duration * expectedJointGain ≤
        researchCost := by
  unfold jointGenerativeLowerBound
  rw [max_eq_right_iff]
  constructor <;> intro h <;> linarith

/-- The joint guarantee is positive exactly when adjusted joint gain covers cost strictly. -/
theorem jointGenerativeLowerBound_pos_iff
    {discount researchCost expectedJointGain operatingAdjustment : ℚ}
    {duration : Nat} :
    0 <
        jointGenerativeLowerBound discount duration researchCost
          expectedJointGain operatingAdjustment ↔
      researchCost <
        operatingAdjustment + discount ^ duration * expectedJointGain := by
  unfold jointGenerativeLowerBound
  by_cases hnet :
      -researchCost + operatingAdjustment +
          discount ^ duration * expectedJointGain ≤ 0
  · rw [max_eq_right hnet]
    constructor <;> intro h <;> linarith
  · have hnetPositive :
        0 <
          -researchCost + operatingAdjustment +
            discount ^ duration * expectedJointGain :=
      lt_of_not_ge hnet
    rw [max_eq_left hnetPositive.le]
    constructor <;> intro h <;> linarith

/-- Strictly profitable adjusted joint gain makes the carrier strictly valuable. -/
theorem generativeInsertionValue_pos_joint
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (researchCost : ℚ) (gain : model.Belief → ℚ)
    (certificate :
      JointGenerativeCarrierCertificate process horizon belief library strategy
        project descendant researchCost gain)
    (hprofitable :
      researchCost <
        operatingResearchAdjustment process horizon belief
            (library.insert strategy) project +
          process.discount ^ process.duration project *
            expectedJointDescendantGain process belief
              (library.insert strategy) project descendant gain) :
    0 < generativeInsertionValue process horizon belief library strategy := by
  have hbound :=
    generativeInsertionValue_lowerBound_joint process horizon belief library
      strategy project descendant researchCost gain certificate
  have hpositive :
      0 <
        jointGenerativeLowerBound process.discount (process.duration project)
          researchCost
          (expectedJointDescendantGain process belief (library.insert strategy)
            project descendant gain)
          (operatingResearchAdjustment process horizon belief
            (library.insert strategy) project) :=
    jointGenerativeLowerBound_pos_iff.mpr hprofitable
  exact lt_of_lt_of_le hpositive hbound

/-- The joint-law scalar guarantee is monotone in expected descendant gain. -/
theorem jointGenerativeLowerBound_mono_expectedJointGain
    {discount researchCost leftGain rightGain operatingAdjustment : ℚ}
    {duration : Nat}
    (hgain : leftGain ≤ rightGain) (hdiscount : 0 ≤ discount) :
    jointGenerativeLowerBound discount duration researchCost leftGain
        operatingAdjustment ≤
      jointGenerativeLowerBound discount duration researchCost rightGain
        operatingAdjustment := by
  unfold jointGenerativeLowerBound
  apply max_le_max_right
  have hscaled :
      discount ^ duration * leftGain ≤ discount ^ duration * rightGain :=
    mul_le_mul_of_nonneg_left hgain (pow_nonneg hdiscount _)
  linarith

/-- The joint-law scalar guarantee is antitone in initiation cost. -/
theorem jointGenerativeLowerBound_antitone_researchCost
    {discount leftCost rightCost expectedJointGain operatingAdjustment : ℚ}
    {duration : Nat} (hcost : leftCost ≤ rightCost) :
    jointGenerativeLowerBound discount duration rightCost expectedJointGain
        operatingAdjustment ≤
      jointGenerativeLowerBound discount duration leftCost expectedJointGain
        operatingAdjustment := by
  unfold jointGenerativeLowerBound
  apply max_le_max_right
  linarith

/-- The joint-law scalar guarantee is monotone in the operating adjustment. -/
theorem jointGenerativeLowerBound_mono_operatingAdjustment
    {discount researchCost expectedJointGain leftAdjustment rightAdjustment : ℚ}
    {duration : Nat} (hadjustment : leftAdjustment ≤ rightAdjustment) :
    jointGenerativeLowerBound discount duration researchCost expectedJointGain
        leftAdjustment ≤
      jointGenerativeLowerBound discount duration researchCost expectedJointGain
        rightAdjustment := by
  unfold jointGenerativeLowerBound
  apply max_le_max_right
  linarith

/-- Pointwise larger joint mass weakly raises the joint-law scalar bound. -/
theorem jointGenerativeLowerBound_mono_mass
    {discount researchCost operatingAdjustment : ℚ} {duration : Nat}
    {leftMass rightMass gain : model.Belief → ℚ}
    (hmass : ∀ terminal, leftMass terminal ≤ rightMass terminal)
    (hgain : ∀ terminal, 0 ≤ gain terminal)
    (hdiscount : 0 ≤ discount) :
    jointGenerativeLowerBound discount duration researchCost
        (∑ terminal, leftMass terminal * gain terminal) operatingAdjustment ≤
      jointGenerativeLowerBound discount duration researchCost
        (∑ terminal, rightMass terminal * gain terminal) operatingAdjustment := by
  apply jointGenerativeLowerBound_mono_expectedJointGain
  · exact jointTerminalWeightedGain_mono_mass hmass hgain
  · exact hdiscount

/-- Pointwise larger gain floors weakly raise the joint-law scalar bound. -/
theorem jointGenerativeLowerBound_mono_gainFunction
    {discount researchCost operatingAdjustment : ℚ} {duration : Nat}
    {mass leftGain rightGain : model.Belief → ℚ}
    (hmass : ∀ terminal, 0 ≤ mass terminal)
    (hgain : ∀ terminal, leftGain terminal ≤ rightGain terminal)
    (hdiscount : 0 ≤ discount) :
    jointGenerativeLowerBound discount duration researchCost
        (∑ terminal, mass terminal * leftGain terminal) operatingAdjustment ≤
      jointGenerativeLowerBound discount duration researchCost
        (∑ terminal, mass terminal * rightGain terminal) operatingAdjustment := by
  apply jointGenerativeLowerBound_mono_expectedJointGain
  · exact jointTerminalWeightedGain_mono_gain hmass hgain
  · exact hdiscount

/-- Expected continuation gain weakly exceeds the raw success-event term. -/
theorem successEvent_expectedGain_le
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (researchCost admission survival : ℚ)
    (gain : model.Belief → ℚ)
    (certificate :
      GenerativeCarrierCertificate process horizon belief library strategy
        project descendant researchCost admission survival gain) :
    survival ^ process.duration project * admission *
        expectedTerminalGain process belief project gain ≤
      (process.completion project belief
        (CompressedLibraryState.ofLibrary catalog closure
          (library.insert strategy))).expectation
        (completionContinuationGain process horizon
          (library.insert strategy) project) := by
  calc
    _ = (process.completion project belief
          (CompressedLibraryState.ofLibrary catalog closure
            (library.insert strategy))).expectation
          (fun completion =>
            if completion.2 = some descendant then
              gain (terminalBelief completion.1)
            else 0) := by
          symm
          exact expected_success_gain_eq process belief
            (library.insert strategy) project descendant admission survival gain
            certificate.conditional_independence
            certificate.generation_probability
            certificate.admission_probability
    _ ≤ _ := by
      apply expectation_mono
      intro completion
      by_cases hsuccess : completion.2 = some descendant
      · rw [if_pos hsuccess]
        have hcompletion :
            completion = (completion.1, some descendant) := by
          apply Prod.ext
          · rfl
          · exact hsuccess
        rw [hcompletion]
        exact certificate.descendant_gain completion.1
      · rw [if_neg hsuccess]
        exact completionContinuationGain_nonnegative process horizon
          (library.insert strategy) project completion

/--
Independence corollary of the joint-law T6 theorem.  Operation during research
enters through the same exact adjustment; independence is used only to replace
the joint descendant term by `π ρ^d` times terminal occupation.
-/
theorem generativeInsertionValue_lowerBound_with_operatingAdjustment
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
      generativeInsertionValue process horizon belief library strategy := by
  have hbound :=
    generativeInsertionValue_lowerBound_joint process horizon belief library
      strategy project descendant researchCost gain certificate.toJoint
  have hfactor :=
    expectedJointDescendantGain_eq_independentProduct process belief
      (library.insert strategy) project descendant admission survival gain
      certificate.conditional_independence
      certificate.generation_probability
      certificate.admission_probability
  rw [hfactor] at hbound
  simpa [jointGenerativeLowerBound, generativeLowerBound, mul_assoc,
    mul_left_comm, mul_comm] using hbound

/--
Target no-adjustment formula.  `hbaseline` is the exact statement that
operating during research reproduces the passive reward block and passive
continuation under the unified calendar convention.
-/
theorem generativeInsertionValue_lowerBound
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (researchCost admission survival : ℚ)
    (gain : model.Belief → ℚ)
    (certificate :
      GenerativeCarrierCertificate process horizon belief library strategy
        project descendant researchCost admission survival gain)
    (hbaseline :
      operatingResearchAdjustment process horizon belief
        (library.insert strategy) project = 0) :
    max
        (-researchCost +
          process.discount ^ process.duration project * admission *
            survival ^ process.duration project *
              expectedTerminalGain process belief project gain)
        0 ≤
      generativeInsertionValue process horizon belief library strategy := by
  have hbound :=
    generativeInsertionValue_lowerBound_with_operatingAdjustment
      process horizon belief library strategy project descendant researchCost
        admission survival gain certificate
  rw [hbaseline] at hbound
  simpa [generativeLowerBound] using hbound

/-- Finite occupation-weighted version of the target T6 bound. -/
theorem generativeInsertionValue_lowerBound_occupationWeighted
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (researchCost admission survival : ℚ)
    (gain : model.Belief → ℚ)
    (certificate :
      GenerativeCarrierCertificate process horizon belief library strategy
        project descendant researchCost admission survival gain)
    (hbaseline :
      operatingResearchAdjustment process horizon belief
        (library.insert strategy) project = 0) :
    max
        (-researchCost +
          process.discount ^ process.duration project * admission *
            survival ^ process.duration project *
              ∑ terminal : model.Belief,
                terminalOccupationWeight process belief project terminal *
                  gain terminal)
        0 ≤
      generativeInsertionValue process horizon belief library strategy := by
  rw [← expectedTerminalGain_eq_occupationWeighted]
  exact generativeInsertionValue_lowerBound process horizon belief library
    strategy project descendant researchCost admission survival gain
    certificate hbaseline

/-- The scalar guarantee is zero exactly when adjusted gross gain does not cover cost. -/
theorem generativeLowerBound_eq_zero_iff
    {discount researchCost admission survival expectedGain operatingAdjustment : ℚ}
    {duration : Nat} :
    generativeLowerBound discount duration researchCost admission survival
        expectedGain operatingAdjustment = 0 ↔
      operatingAdjustment +
          discount ^ duration * admission * survival ^ duration * expectedGain ≤
        researchCost := by
  unfold generativeLowerBound
  rw [max_eq_right_iff]
  constructor <;> intro h <;> linarith

/-- Zero premiums on both sides give exact zero generative insertion value. -/
theorem generativeInsertionValue_eq_zero_of_premia_zero
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (hpoor : researchOptionPremium process horizon belief library = 0)
    (hrich :
      researchOptionPremium process horizon belief (library.insert strategy) = 0) :
    generativeInsertionValue process horizon belief library strategy = 0 := by
  unfold generativeInsertionValue
  rw [hpoor, hrich]
  ring

/-- Positive adjusted net gain makes the retained carrier strictly valuable. -/
theorem generativeInsertionValue_pos_with_operatingAdjustment
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (researchCost admission survival : ℚ)
    (gain : model.Belief → ℚ)
    (certificate :
      GenerativeCarrierCertificate process horizon belief library strategy
        project descendant researchCost admission survival gain)
    (hprofitable :
      researchCost <
        operatingResearchAdjustment process horizon belief
            (library.insert strategy) project +
          process.discount ^ process.duration project * admission *
            survival ^ process.duration project *
              expectedTerminalGain process belief project gain) :
    0 < generativeInsertionValue process horizon belief library strategy := by
  have hbound :=
    generativeInsertionValue_lowerBound_with_operatingAdjustment
      process horizon belief library strategy project descendant researchCost
        admission survival gain certificate
  have hpositive :
      0 <
        generativeLowerBound process.discount (process.duration project)
          researchCost admission survival
            (expectedTerminalGain process belief project gain)
            (operatingResearchAdjustment process horizon belief
              (library.insert strategy) project) := by
    unfold generativeLowerBound
    rw [max_eq_left]
    · linarith
    · linarith
  exact lt_of_lt_of_le hpositive hbound

/-- Zero timing adjustment specializes the strict condition to the target formula. -/
theorem generativeInsertionValue_pos
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (project : model.ResearchProject) (descendant : model.StrategyId)
    (researchCost admission survival : ℚ)
    (gain : model.Belief → ℚ)
    (certificate :
      GenerativeCarrierCertificate process horizon belief library strategy
        project descendant researchCost admission survival gain)
    (hbaseline :
      operatingResearchAdjustment process horizon belief
        (library.insert strategy) project = 0)
    (hprofitable :
      researchCost <
        process.discount ^ process.duration project * admission *
          survival ^ process.duration project *
            expectedTerminalGain process belief project gain) :
    0 < generativeInsertionValue process horizon belief library strategy := by
  apply generativeInsertionValue_pos_with_operatingAdjustment
    process horizon belief library strategy project descendant researchCost
      admission survival gain certificate
  rw [hbaseline]
  simpa using hprofitable

/-- The scalar guarantee is monotone in valid-admission probability. -/
theorem generativeLowerBound_mono_admission
    {discount researchCost leftAdmission rightAdmission survival
      expectedGain operatingAdjustment : ℚ} {duration : Nat}
    (hadmission : leftAdmission ≤ rightAdmission)
    (hdiscount : 0 ≤ discount) (hsurvival : 0 ≤ survival)
    (hgain : 0 ≤ expectedGain) :
    generativeLowerBound discount duration researchCost leftAdmission survival
        expectedGain operatingAdjustment ≤
      generativeLowerBound discount duration researchCost rightAdmission survival
        expectedGain operatingAdjustment := by
  unfold generativeLowerBound
  apply max_le_max_right
  have hcoefficient :
      0 ≤ discount ^ duration * survival ^ duration * expectedGain :=
    mul_nonneg
      (mul_nonneg (pow_nonneg hdiscount _) (pow_nonneg hsurvival _)) hgain
  nlinarith

/-- The scalar guarantee is monotone in per-period survival. -/
theorem generativeLowerBound_mono_survival
    {discount researchCost admission leftSurvival rightSurvival
      expectedGain operatingAdjustment : ℚ} {duration : Nat}
    (hsurvival : leftSurvival ≤ rightSurvival)
    (hleft : 0 ≤ leftSurvival) (hdiscount : 0 ≤ discount)
    (hadmission : 0 ≤ admission) (hgain : 0 ≤ expectedGain) :
    generativeLowerBound discount duration researchCost admission leftSurvival
        expectedGain operatingAdjustment ≤
      generativeLowerBound discount duration researchCost admission rightSurvival
        expectedGain operatingAdjustment := by
  unfold generativeLowerBound
  apply max_le_max_right
  have hpow : leftSurvival ^ duration ≤ rightSurvival ^ duration :=
    pow_le_pow_left₀ hleft hsurvival duration
  have hcoefficient :
      0 ≤ discount ^ duration * admission * expectedGain :=
    mul_nonneg (mul_nonneg (pow_nonneg hdiscount _) hadmission) hgain
  nlinarith

/-- The scalar guarantee is monotone in expected continuation improvement. -/
theorem generativeLowerBound_mono_expectedGain
    {discount researchCost admission survival leftGain rightGain
      operatingAdjustment : ℚ} {duration : Nat}
    (hgain : leftGain ≤ rightGain)
    (hdiscount : 0 ≤ discount) (hadmission : 0 ≤ admission)
    (hsurvival : 0 ≤ survival) :
    generativeLowerBound discount duration researchCost admission survival
        leftGain operatingAdjustment ≤
      generativeLowerBound discount duration researchCost admission survival
        rightGain operatingAdjustment := by
  unfold generativeLowerBound
  apply max_le_max_right
  have hcoefficient :
      0 ≤ discount ^ duration * admission * survival ^ duration :=
    mul_nonneg
      (mul_nonneg (pow_nonneg hdiscount _) hadmission)
      (pow_nonneg hsurvival _)
  nlinarith

/-- Pointwise larger terminal gains weakly raise the finite occupation bound. -/
theorem generativeLowerBound_mono_gainFunction
    (process : Model model catalog closure)
    (belief : model.Belief) (project : model.ResearchProject)
    (researchCost admission survival operatingAdjustment : ℚ)
    {left right : model.Belief → ℚ}
    (hgain : ∀ terminal, left terminal ≤ right terminal)
    (hadmission : 0 ≤ admission) (hsurvival : 0 ≤ survival) :
    generativeLowerBound process.discount (process.duration project)
        researchCost admission survival
        (expectedTerminalGain process belief project left)
        operatingAdjustment ≤
      generativeLowerBound process.discount (process.duration project)
        researchCost admission survival
        (expectedTerminalGain process belief project right)
        operatingAdjustment := by
  apply generativeLowerBound_mono_expectedGain
  · exact expectedTerminalGain_mono process belief project hgain
  · exact process.discount_nonnegative
  · exact hadmission
  · exact hsurvival

/-- The scalar guarantee is antitone in initiation cost. -/
theorem generativeLowerBound_antitone_researchCost
    {discount leftCost rightCost admission survival expectedGain
      operatingAdjustment : ℚ} {duration : Nat}
    (hcost : leftCost ≤ rightCost) :
    generativeLowerBound discount duration rightCost admission survival
        expectedGain operatingAdjustment ≤
      generativeLowerBound discount duration leftCost admission survival
        expectedGain operatingAdjustment := by
  unfold generativeLowerBound
  apply max_le_max_right
  linarith

/--
With nonnegative continuation and fixed operating adjustment, the scalar
guarantee is antitone in delay when both discount and survival lie in `[0,1]`.
-/
theorem generativeLowerBound_antitone_duration
    {discount researchCost admission survival expectedGain
      operatingAdjustment : ℚ} {short long : Nat}
    (hdelay : short ≤ long)
    (hdiscount0 : 0 ≤ discount) (hdiscount1 : discount ≤ 1)
    (hsurvival0 : 0 ≤ survival) (hsurvival1 : survival ≤ 1)
    (hadmission : 0 ≤ admission) (hgain : 0 ≤ expectedGain) :
    generativeLowerBound discount long researchCost admission survival
        expectedGain operatingAdjustment ≤
      generativeLowerBound discount short researchCost admission survival
        expectedGain operatingAdjustment := by
  unfold generativeLowerBound
  apply max_le_max_right
  have hbase0 : 0 ≤ discount * survival :=
    mul_nonneg hdiscount0 hsurvival0
  have hbase1 : discount * survival ≤ 1 := by
    nlinarith
  have hpow :
      (discount * survival) ^ long ≤ (discount * survival) ^ short :=
    pow_le_pow_of_le_one hbase0 hbase1 hdelay
  have hscale : 0 ≤ admission * expectedGain :=
    mul_nonneg hadmission hgain
  calc
    -researchCost + operatingAdjustment +
          discount ^ long * admission * survival ^ long * expectedGain =
        -researchCost + operatingAdjustment +
          (discount * survival) ^ long * (admission * expectedGain) := by
            rw [mul_pow]
            ring
    _ ≤ -researchCost + operatingAdjustment +
          (discount * survival) ^ short * (admission * expectedGain) := by
            gcongr
    _ = -researchCost + operatingAdjustment +
          discount ^ short * admission * survival ^ short * expectedGain := by
            rw [mul_pow]
            ring

namespace CarrierExample

open StrategyInnovation.FrontierPruningLoss
open UnifiedDecomposition.BridgeExample

abbrev exampleModel := StrategyInnovation.FrontierPruningLoss.model
abbrev exampleCatalog := StrategyInnovation.FrontierPruningLoss.catalog
abbrev exampleClosure := StrategyInnovation.FrontierPruningLoss.moduleClosure

/--
Exact one-belief raw carrier process.  The bridge closure makes the unique
project feasible; deleting the bridge makes the feasible project set empty.
Operation is declared to continue during the one-period project.
-/
noncomputable def process :
    Model exampleModel (exampleCatalog 2) exampleClosure where
  generation := UnifiedDecomposition.BridgeExample.generation
  admission := UnifiedDecomposition.BridgeExample.admission
  beliefTransition := UnifiedDecomposition.BridgeExample.beliefTransition
  duration := fun _ => 1
  duration_positive := by intros; norm_num
  operates := fun _ => true
  available := fun state =>
    if Module.key ∈ state.state.closure then Finset.univ else ∅
  researchCost := fun _ _ _ => 0
  researchCost_nonnegative := by intros; norm_num
  discount := 1 / 2
  discount_nonnegative := by norm_num
  discount_lt_one := by norm_num
  completion := UnifiedDecomposition.BridgeExample.completion
  completion_path_marginal :=
    UnifiedDecomposition.BridgeExample.completion_path_marginal
  completion_outcome_marginal :=
    UnifiedDecomposition.BridgeExample.completion_outcome_marginal

/-- The exact one-path coupling satisfies the explicit T6 independence assumption. -/
theorem conditionalIndependence :
    process.ConditionalIndependence := by
  intro project belief state path outcome
  cases project
  cases belief
  rw [UnifiedDecomposition.BridgeExample.path_eq_onlyPath path]
  have hmarginal :=
    UnifiedDecomposition.BridgeExample.completion_outcome_marginal
      Project.innovate Belief.only state outcome
  have huniv :
      (Finset.univ : Finset (BeliefPath exampleModel 1)) =
        {UnifiedDecomposition.BridgeExample.onlyPath} := by
    ext candidatePath
    simp [UnifiedDecomposition.BridgeExample.path_eq_onlyPath candidatePath]
  rw [huniv] at hmarginal
  simp only [Finset.sum_singleton] at hmarginal
  change
    (UnifiedDecomposition.BridgeExample.completion
      Project.innovate Belief.only state).probability
        (UnifiedDecomposition.BridgeExample.onlyPath, outcome) =
      markovPathMass UnifiedDecomposition.BridgeExample.beliefTransition
          Belief.only 1 UnifiedDecomposition.BridgeExample.onlyPath *
        (Raw.admittedCandidateDistribution
          UnifiedDecomposition.BridgeExample.generation
          UnifiedDecomposition.BridgeExample.admission
          Project.innovate Belief.only state.state.closure).probability outcome
  rw [show
      markovPathMass UnifiedDecomposition.BridgeExample.beliefTransition
        Belief.only 1 UnifiedDecomposition.BridgeExample.onlyPath = 1 by
    simp [markovPathMass,
      UnifiedDecomposition.BridgeExample.beliefTransition,
      UnifiedDecomposition.BridgeExample.onlyPath,
      RatProb.probability, RatProb.dirac]]
  simpa using hmarginal

/-- The bridge insertion reconstructs the retained raw library. -/
theorem inserted_eq_retained :
    (prunedLibrary 2).insert Strategy.dominated = unprunedLibrary 2 :=
  UnifiedDecomposition.BridgeExample.insert_dominated_eq_unpruned

/-- The bridge makes the unique project feasible. -/
theorem project_enabled :
    Project.innovate ∈
      process.available
        (CompressedLibraryState.ofLibrary
          (exampleCatalog 2) exampleClosure (unprunedLibrary 2)) := by
  have hkey :
      Module.key ∈
        generativeClosure (exampleCatalog 2) exampleClosure
          (unprunedLibrary 2) := by
    rw [unpruned_closure_eq_key]
    simp
  change
    Module.key ∈
      (CompressedLibraryState.ofLibrary
        (exampleCatalog 2) exampleClosure (unprunedLibrary 2)).state.closure
    at hkey
  simp [process, hkey]

/-- Without the bridge the unique project is infeasible. -/
theorem project_unavailable_without :
    Project.innovate ∉
      process.available
        (CompressedLibraryState.ofLibrary
          (exampleCatalog 2) exampleClosure (prunedLibrary 2)) := by
  have hkey :
      Module.key ∉
        generativeClosure (exampleCatalog 2) exampleClosure
          (prunedLibrary 2) := by
    rw [pruned_closure_eq_empty]
    simp
  change
    Module.key ∉
      (CompressedLibraryState.ofLibrary
        (exampleCatalog 2) exampleClosure (prunedLibrary 2)).state.closure
    at hkey
  simp [process, hkey]

/-- The bridge-free library has zero full value at every finite horizon. -/
theorem pruned_fullValue_eq_zero :
    ∀ horizon,
      fullValue process horizon Belief.only (prunedLibrary 2) = 0 := by
  intro horizon
  induction horizon with
  | zero =>
      simp [fullValue, rawValue]
  | succ horizon inductionHypothesis =>
      change
        process.rawValue horizon Belief.only (prunedLibrary 2) = 0
        at inductionHypothesis
      unfold fullValue
      simp only [rawValue]
      apply le_antisymm
      · apply Finset.sup'_le Finset.univ_nonempty
        intro action _
        rcases action with ⟨action, hfeasible⟩
        cases action with
        | none =>
            rw [show
              operationalFrontier (exampleCatalog 2)
                (prunedLibrary 2) Belief.only = 0 by
                  rw [congrFun (pruned_frontier_eq_zero 2) Belief.only]]
            rw [show process.discount = 1 / 2 by rfl]
            rw [show
              process.beliefTransition Belief.only =
                RatProb.dirac Belief.only by rfl]
            rw [RatProb.expectation_dirac, inductionHypothesis]
            norm_num
        | some project =>
            exfalso
            exact project_unavailable_without hfeasible.1
      · let action :
            FeasibleAction process (horizon + 1)
              (CompressedLibraryState.ofLibrary
                (exampleCatalog 2) exampleClosure (prunedLibrary 2)) :=
          ⟨none, trivial⟩
        refine le_trans ?_ (Finset.le_sup' _ (Finset.mem_univ action))
        dsimp [action]
        rw [show
          operationalFrontier (exampleCatalog 2)
            (prunedLibrary 2) Belief.only = 0 by
              rw [congrFun (pruned_frontier_eq_zero 2) Belief.only]]
        rw [show process.discount = 1 / 2 by rfl]
        rw [show
          process.beliefTransition Belief.only =
            RatProb.dirac Belief.only by rfl]
        rw [RatProb.expectation_dirac, inductionHypothesis]
        norm_num

/-- The frozen bridge-free and retained libraries both have zero passive value. -/
theorem passive_values_eq_zero :
    ∀ horizon,
      passiveValue process horizon Belief.only (prunedLibrary 2) = 0 ∧
        passiveValue process horizon Belief.only (unprunedLibrary 2) = 0 := by
  intro horizon
  induction horizon with
  | zero =>
      simp [passiveValue]
  | succ horizon inductionHypothesis =>
      constructor
      · simp only [passiveValue]
        rw [show
          operationalFrontier (exampleCatalog 2)
            (prunedLibrary 2) Belief.only = 0 by
              rw [congrFun (pruned_frontier_eq_zero 2) Belief.only]]
        rw [show process.discount = 1 / 2 by rfl]
        rw [show
          process.beliefTransition Belief.only =
            RatProb.dirac Belief.only by rfl]
        rw [RatProb.expectation_dirac, inductionHypothesis.1]
        norm_num
      · simp only [passiveValue]
        rw [show
          operationalFrontier (exampleCatalog 2)
            (unprunedLibrary 2) Belief.only = 0 by
              rw [congrFun (unpruned_frontier_eq_zero 2) Belief.only]]
        rw [show process.discount = 1 / 2 by rfl]
        rw [show
          process.beliefTransition Belief.only =
            RatProb.dirac Belief.only by rfl]
        rw [RatProb.expectation_dirac, inductionHypothesis.2]
        norm_num

/-- The deleted comparator has zero research-option premium at horizon two. -/
theorem deleted_premium_zero :
    researchOptionPremium process 2 Belief.only (prunedLibrary 2) = 0 := by
  unfold researchOptionPremium
  rw [pruned_fullValue_eq_zero, (passive_values_eq_zero 2).1]
  ring

/-- The raw generator assigns unit survival mass to the descendant. -/
theorem generation_probability :
    process.generation.probability Project.innovate Belief.only
        (generativeClosure (exampleCatalog 2) exampleClosure
          (unprunedLibrary 2))
        (some Strategy.future) =
      (1 : ℚ) ^ process.duration Project.innovate := by
  change
    UnifiedDecomposition.BridgeExample.generation.probability
        Project.innovate Belief.only
        (generativeClosure (exampleCatalog 2) exampleClosure
          (unprunedLibrary 2))
        (some Strategy.future) = 1
  simp [Raw.CandidateGenerationDistributions.probability,
    UnifiedDecomposition.BridgeExample.generation,
    unpruned_closure_eq_key, RatProb.probability, RatProb.dirac]

/-- Primitive admission is exactly one in the example. -/
theorem admission_probability :
    process.admission.probability Project.innovate Belief.only
        (generativeClosure (exampleCatalog 2) exampleClosure
          (unprunedLibrary 2))
        Strategy.future = 1 := by
  rfl

/-- The distinguished descendant improves completion continuation by at least two. -/
theorem descendant_gain
    (path : BeliefPath exampleModel (process.duration Project.innovate)) :
    (2 : ℚ) ≤
      completionContinuationGain process 2 (unprunedLibrary 2)
        Project.innovate (path, some Strategy.future) := by
  change BeliefPath exampleModel 1 at path
  have hsuccessPassive :
      (2 : ℚ) ≤
        passiveValue process 1 (terminalBelief path)
          (Raw.rawLibraryUpdate (unprunedLibrary 2) (some Strategy.future)) := by
    simp only [passiveValue]
    simp [process, UnifiedDecomposition.BridgeExample.beliefTransition]
    rw [show
      Raw.rawLibraryUpdate (unprunedLibrary 2) (some Strategy.future) =
        UnifiedDecomposition.BridgeExample.successfulLibrary by rfl]
    rw [congrFun
      UnifiedDecomposition.BridgeExample.successfulLibrary_frontier_eq_two
      (terminalBelief path)]
  have hsuccessFull :
      (2 : ℚ) ≤
        fullValue process 1 (terminalBelief path)
          (Raw.rawLibraryUpdate (unprunedLibrary 2) (some Strategy.future)) :=
    hsuccessPassive.trans
      (passiveValue_le_fullValue process 1 (terminalBelief path)
        (Raw.rawLibraryUpdate (unprunedLibrary 2) (some Strategy.future)))
  have hretainedPassive :
      passiveValue process 1 (terminalBelief path) (unprunedLibrary 2) = 0 := by
    cases terminalBelief path
    exact (passive_values_eq_zero 1).2
  unfold completionContinuationGain
  change
    (2 : ℚ) ≤
      fullValue process 1 (terminalBelief path)
          (Raw.rawLibraryUpdate (unprunedLibrary 2) (some Strategy.future)) -
        passiveValue process 1 (terminalBelief path) (unprunedLibrary 2)
  rw [hretainedPassive]
  linarith

/-- Exact T6 carrier certificate for `κ=0`, `π=ρ=1`, and `G≡2`. -/
theorem certificate :
    GenerativeCarrierCertificate process 2 Belief.only (prunedLibrary 2)
      Strategy.dominated Project.innovate Strategy.future 0 1 1
      (fun _ => 2) where
  frontier_silent := by
    rw [inserted_eq_retained, unpruned_frontier_eq_zero,
      pruned_frontier_eq_zero]
  project_enabled := by
    rw [inserted_eq_retained]
    exact project_enabled
  project_unavailable_without := project_unavailable_without
  duration_fits := by norm_num [process]
  researchCost_eq := rfl
  deleted_premium_zero := deleted_premium_zero
  conditional_independence := conditionalIndependence
  generation_probability := by
    rw [inserted_eq_retained]
    exact generation_probability
  admission_probability := by
    rw [inserted_eq_retained]
    exact admission_probability
  admission_nonnegative := by norm_num
  admission_le_one := by norm_num
  survival_nonnegative := by norm_num
  survival_le_one := by norm_num
  gain_nonnegative := by intros; norm_num
  descendant_gain := by
    intro path
    rw [inserted_eq_retained]
    exact descendant_gain path

/-- The same exact carrier certificate with independence information forgotten. -/
theorem jointCertificate :
    JointGenerativeCarrierCertificate process 2 Belief.only (prunedLibrary 2)
      Strategy.dominated Project.innovate Strategy.future 0
      (fun _ => 2) :=
  certificate.toJoint

/-- Continued operation has zero timing adjustment in the zero-frontier example. -/
theorem operatingResearchAdjustment_eq_zero :
    operatingResearchAdjustment process 2 Belief.only
      ((prunedLibrary 2).insert Strategy.dominated) Project.innovate = 0 := by
  rw [inserted_eq_retained]
  unfold operatingResearchAdjustment
  have hpassiveOne := (passive_values_eq_zero 1).2
  have hpassiveTwo := (passive_values_eq_zero 2).2
  simp only [process] at hpassiveOne hpassiveTwo ⊢
  have hkey :
      Module.key ∈
        (CompressedLibraryState.ofLibrary
          (exampleCatalog 2) exampleClosure (unprunedLibrary 2)).state.closure := by
    change Module.key ∈
      generativeClosure (exampleCatalog 2) exampleClosure (unprunedLibrary 2)
    rw [unpruned_closure_eq_key]
    simp
  have hcompletion :
      UnifiedDecomposition.BridgeExample.completion
          Project.innovate Belief.only
          (CompressedLibraryState.ofLibrary
            (exampleCatalog 2) exampleClosure (unprunedLibrary 2)) =
        RatProb.dirac
          (UnifiedDecomposition.BridgeExample.onlyPath, some Strategy.future) := by
    exact
      UnifiedDecomposition.BridgeExample.completion_eq_dirac_future _ hkey
  rw [hcompletion]
  rw [RatProb.expectation_dirac]
  norm_num
  rw [hpassiveOne, hpassiveTwo]
  have hfrontier :
      ∀ terminal,
        (CompressedLibraryState.ofLibrary
          (exampleCatalog 2) exampleClosure
          (unprunedLibrary 2)).state.frontier terminal = 0 := by
    intro terminal
    change
      operationalFrontier (exampleCatalog 2) (unprunedLibrary 2) terminal = 0
    rw [congrFun (unpruned_frontier_eq_zero 2) terminal]
  simp [incumbentReward, hfrontier]

/-- The exact terminal occupation expectation of `G≡2` is two. -/
theorem expectedTerminalGain_eq_two :
    expectedTerminalGain process Belief.only Project.innovate
      (fun _ => 2) = 2 := by
  unfold expectedTerminalGain
  classical
  have huniv :
      (Finset.univ : Finset (BeliefPath exampleModel 1)) =
        {UnifiedDecomposition.BridgeExample.onlyPath} := by
    ext path
    simp [UnifiedDecomposition.BridgeExample.path_eq_onlyPath path]
  rw [show process.duration Project.innovate = 1 by rfl]
  rw [huniv]
  simp [markovPathMass, process,
    UnifiedDecomposition.BridgeExample.beliefTransition,
    RatProb.probability, RatProb.dirac]

/-- The exact joint descendant expectation of `G≡2` is two. -/
theorem expectedJointDescendantGain_eq_two :
    expectedJointDescendantGain process Belief.only
      ((prunedLibrary 2).insert Strategy.dominated)
      Project.innovate Strategy.future (fun _ => 2) = 2 := by
  rw [expectedJointDescendantGain_eq_independentProduct process Belief.only
    ((prunedLibrary 2).insert Strategy.dominated) Project.innovate
    Strategy.future 1 1 (fun _ => 2) conditionalIndependence]
  · rw [expectedTerminalGain_eq_two]
    norm_num [process]
  · rw [inserted_eq_retained]
    exact generation_probability
  · rw [inserted_eq_retained]
    exact admission_probability

/--
Small exact joint-law example: the generalized guarantee is exactly one and
the bridge's generative insertion value is at least that amount.
-/
theorem exact_joint_carrier_lowerBound_one :
    jointGenerativeLowerBound process.discount
        (process.duration Project.innovate) 0
        (expectedJointDescendantGain process Belief.only
          ((prunedLibrary 2).insert Strategy.dominated)
          Project.innovate Strategy.future (fun _ => 2))
        0 = 1 ∧
      (1 : ℚ) ≤
        generativeInsertionValue process 2 Belief.only (prunedLibrary 2)
          Strategy.dominated := by
  constructor
  · rw [expectedJointDescendantGain_eq_two]
    norm_num [jointGenerativeLowerBound, process]
  · have hbound :=
      generativeInsertionValue_lowerBound_joint process 2 Belief.only
        (prunedLibrary 2) Strategy.dominated Project.innovate Strategy.future
        0 (fun _ => 2) jointCertificate
    rw [expectedJointDescendantGain_eq_two,
      operatingResearchAdjustment_eq_zero] at hbound
    norm_num [jointGenerativeLowerBound, process] at hbound ⊢
    exact hbound

/--
Small exact example: the raw T6 guarantee is exactly one and the bridge's
generative insertion value is at least that amount.
-/
theorem exact_carrier_lowerBound_one :
    generativeLowerBound process.discount (process.duration Project.innovate)
        0 1 1
        (expectedTerminalGain process Belief.only Project.innovate (fun _ => 2))
        0 = 1 ∧
      (1 : ℚ) ≤
        generativeInsertionValue process 2 Belief.only (prunedLibrary 2)
          Strategy.dominated := by
  constructor
  · rw [expectedTerminalGain_eq_two]
    norm_num [generativeLowerBound, process]
  · have hbound :=
      generativeInsertionValue_lowerBound process 2 Belief.only
        (prunedLibrary 2) Strategy.dominated Project.innovate Strategy.future
        0 1 1 (fun _ => 2) certificate operatingResearchAdjustment_eq_zero
    rw [expectedTerminalGain_eq_two] at hbound
    norm_num [process] at hbound ⊢
    exact hbound

end CarrierExample

end GenerativeLowerBound

end Model

end Projection

end StrategyInnovation
