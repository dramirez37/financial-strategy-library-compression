import Mathlib.Tactic
import StrategyInnovation.Value.GenerativeLowerBound

/-!
# Sign-definite comparative statics in the finite unified model

This module collects one-way comparative statics with their primitive
assumptions exposed.  Full-value monotonicity is proved by strong induction on
the unified calendar horizon.  The declared generative-dominance order is a
one-step stochastic order: it compares frontiers, feasible menus, costs, and
completion expectations for every continuation monotone in that order.

Admission, survival, and research-region results use an exact binary
candidate law.  Delay uses the unified elapsed-time payoff

`-κ + ∑ t < d, β^t F_t + β^d W`.

Nonnegative operating rewards and nonnegative terminal continuation do not by
themselves make that expression antitone in `d`.  The theorem therefore states
the necessary no-waiting-gain inequality explicitly, and the counterexample
namespace records exact failures when assumptions are removed.
-/

namespace StrategyInnovation

namespace Projection

namespace Model

namespace ComparativeStatics

open UnifiedDecomposition
open scoped BigOperators

variable {model : FiniteModel}
variable {catalog : Raw.StrategyCatalog model}
variable {closure : Raw.ClosureOperator model}

/-! ## Dynamic state dominance -/

/--
A primitive generative-dominance order on realizable compressed states.

`completion_mono` compares the complete operating-reward and continuation
block for every continuation table monotone in `StateLE`.  It is a one-step
stochastic dominance assumption, not an assumption about the optimized value.
-/
structure GenerativeDominanceOrder
    (process : Model model catalog closure) where
  StateLE :
    CompressedLibraryState catalog closure →
      CompressedLibraryState catalog closure → Prop
  frontier_le :
    ∀ {left right}, StateLE left right → ∀ belief,
      left.state.frontier belief ≤ right.state.frontier belief
  available_subset :
    ∀ {left right}, StateLE left right →
      process.available left ⊆ process.available right
  researchCost_antitone :
    ∀ {left right}, StateLE left right → ∀ belief project,
      process.researchCost belief right project ≤
        process.researchCost belief left project
  completion_mono :
    ∀ {left right}, StateLE left right →
      ∀ belief project
        (continuation :
          model.Belief → CompressedLibraryState catalog closure → ℚ),
        (∀ terminal {first second}, StateLE first second →
          continuation terminal first ≤ continuation terminal second) →
        (process.completion project belief left).expectation
            (fun completion =>
              process.incumbentReward left project completion.1 +
                process.discount ^ process.duration project *
                  continuation (terminalBelief completion.1)
                    (CompressedLibraryState.add catalog closure left
                      completion.2)) ≤
          (process.completion project belief right).expectation
            (fun completion =>
              process.incumbentReward right project completion.1 +
                process.discount ^ process.duration project *
                  continuation (terminalBelief completion.1)
                    (CompressedLibraryState.add catalog closure right
                      completion.2))

/-- A compressed value table is monotone in a declared generative order. -/
def StateMonotone
    {process : Model model catalog closure}
    (order : GenerativeDominanceOrder process)
    (value : model.Belief → CompressedLibraryState catalog closure → ℚ) : Prop :=
  ∀ belief {left right}, order.StateLE left right →
    value belief left ≤ value belief right

/--
Full finite-horizon compressed value is monotone under the declared primitive
generative-dominance order.
-/
theorem compressedValue_mono_of_generativeDominanceOrder
    (process : Model model catalog closure)
    (order : GenerativeDominanceOrder process) :
    ∀ horizon,
      StateMonotone order (process.compressedValue horizon) := by
  intro horizon
  induction horizon using Nat.strong_induction_on with
  | h horizon inductionHypothesis =>
      intro belief left right hstate
      cases horizon with
      | zero =>
          simp [compressedValue]
      | succ remaining =>
          let toRight :
              FeasibleAction process (remaining + 1) left →
                FeasibleAction process (remaining + 1) right :=
            fun action =>
              ⟨action.1, by
                cases haction : action.1 with
                | none => trivial
                | some project =>
                    have hfeasible := action.2
                    rw [haction] at hfeasible
                    exact
                      ⟨order.available_subset hstate hfeasible.1,
                        hfeasible.2⟩⟩
          let leftActionValue :
              FeasibleAction process (remaining + 1) left → ℚ :=
            fun action =>
              match action.1 with
              | none =>
                  left.state.frontier belief +
                    process.discount *
                      (process.beliefTransition belief).expectation
                        (fun nextBelief =>
                          process.compressedValue remaining nextBelief left)
              | some project =>
                  -process.researchCost belief left project +
                    (process.completion project belief left).expectation
                      (fun completion =>
                        process.incumbentReward left project completion.1 +
                          process.discount ^ process.duration project *
                            process.compressedValue
                              ((remaining + 1) - process.duration project)
                              (terminalBelief completion.1)
                              (CompressedLibraryState.add catalog closure left
                                completion.2))
          let rightActionValue :
              FeasibleAction process (remaining + 1) right → ℚ :=
            fun action =>
              match action.1 with
              | none =>
                  right.state.frontier belief +
                    process.discount *
                      (process.beliefTransition belief).expectation
                        (fun nextBelief =>
                          process.compressedValue remaining nextBelief right)
              | some project =>
                  -process.researchCost belief right project +
                    (process.completion project belief right).expectation
                      (fun completion =>
                        process.incumbentReward right project completion.1 +
                          process.discount ^ process.duration project *
                            process.compressedValue
                              ((remaining + 1) - process.duration project)
                              (terminalBelief completion.1)
                              (CompressedLibraryState.add catalog closure right
                                completion.2))
          simp only [compressedValue]
          apply Finset.sup'_le Finset.univ_nonempty
          intro action _
          apply le_trans
            (show leftActionValue action ≤
                rightActionValue (toRight action) by
              rcases action with ⟨action, hfeasible⟩
              cases action with
              | none =>
                  dsimp [leftActionValue, rightActionValue, toRight]
                  apply add_le_add
                  · exact order.frontier_le hstate belief
                  · apply mul_le_mul_of_nonneg_left
                    · apply expectation_mono
                      intro nextBelief
                      exact inductionHypothesis remaining
                        (Nat.lt_succ_self remaining) nextBelief hstate
                    · exact process.discount_nonnegative
              | some project =>
                  dsimp [leftActionValue, rightActionValue, toRight]
                  apply add_le_add
                  · exact neg_le_neg
                      (order.researchCost_antitone hstate belief project)
                  · apply order.completion_mono hstate
                    intro terminal first second hnext
                    apply inductionHypothesis
                    · have hpositive := process.duration_positive project
                      omega
                    · exact hnext)
          exact Finset.le_sup' rightActionValue
            (Finset.mem_univ (toRight action))

/--
Raw full value is monotone whenever the compressed images are ordered by a
declared generative-dominance order.
-/
theorem rawValue_mono_of_generativeDominanceOrder
    (process : Model model catalog closure)
    (order : GenerativeDominanceOrder process)
    {left right : Raw.Library catalog}
    (hstate :
      order.StateLE
        (CompressedLibraryState.ofLibrary catalog closure left)
        (CompressedLibraryState.ofLibrary catalog closure right))
    (horizon : Nat) (belief : model.Belief) :
    process.rawValue horizon belief left ≤
      process.rawValue horizon belief right := by
  rw [process.rawValue_eq_compressedValue,
    process.rawValue_eq_compressedValue]
  exact compressedValue_mono_of_generativeDominanceOrder
    process order horizon belief hstate

/-! ## Frontier monotonicity at fixed closure -/

/-- Same closure and pointwise ordered frontiers. -/
def SameClosureFrontierLE
    (left right : CompressedLibraryState catalog closure) : Prop :=
  left.state.closure = right.state.closure ∧
    ∀ belief, left.state.frontier belief ≤ right.state.frontier belief

/-- Inserting the same admitted outcome preserves same-closure frontier order. -/
theorem sameClosureFrontierLE_add
    {left right : CompressedLibraryState catalog closure}
    (hstate : SameClosureFrontierLE left right)
    (outcome : Raw.CandidateOutcome model) :
    SameClosureFrontierLE
      (CompressedLibraryState.add catalog closure left outcome)
      (CompressedLibraryState.add catalog closure right outcome) := by
  cases outcome with
  | none =>
      exact hstate
  | some strategy =>
      constructor
      · change
          closure.close
              (left.state.closure ∪ catalog.strategyModules strategy) =
            closure.close
              (right.state.closure ∪ catalog.strategyModules strategy)
        rw [hstate.1]
      · intro belief
        change
          max (left.state.frontier belief)
              (catalog.operationalProfile strategy belief) ≤
            max (right.state.frontier belief)
              (catalog.operationalProfile strategy belief)
        exact max_le_max (hstate.2 belief) le_rfl

/-- Incumbent operating rewards are monotone in the pointwise frontier. -/
theorem incumbentReward_mono_of_sameClosureFrontierLE
    (process : Model model catalog closure)
    {left right : CompressedLibraryState catalog closure}
    (hstate : SameClosureFrontierLE left right)
    (project : model.ResearchProject)
    (path : BeliefPath model (process.duration project)) :
    process.incumbentReward left project path ≤
      process.incumbentReward right project path := by
  unfold incumbentReward
  apply Finset.sum_le_sum
  intro time _
  by_cases hoperates : process.operates project = true
  · simp only [hoperates, ↓reduceIte]
    exact mul_le_mul_of_nonneg_left
      (hstate.2 (path time.castSucc))
      (pow_nonneg process.discount_nonnegative _)
  · have hfalse : process.operates project = false := Bool.eq_false_of_not_eq_true hoperates
    simp [hfalse]

/--
Primitive opportunities are frontier independent at a fixed closure.

Availability, cost, and the joint completion law may depend on closure, but
not on the numerical frontier once closure is fixed.
-/
structure FrontierIndependentPrimitives
    (process : Model model catalog closure) : Prop where
  available_eq :
    ∀ {left right}, SameClosureFrontierLE left right →
      process.available left = process.available right
  researchCost_eq :
    ∀ {left right}, SameClosureFrontierLE left right →
      ∀ belief project,
        process.researchCost belief left project =
          process.researchCost belief right project
  completion_eq :
    ∀ {left right}, SameClosureFrontierLE left right →
      ∀ belief project,
        process.completion project belief left =
          process.completion project belief right

/-- Frontier-independent primitives induce a generative-dominance order. -/
def frontierGenerativeDominanceOrder
    (process : Model model catalog closure)
    (hindependent : FrontierIndependentPrimitives process) :
    GenerativeDominanceOrder process where
  StateLE := SameClosureFrontierLE
  frontier_le := fun hstate belief => hstate.2 belief
  available_subset := by
    intro left right hstate
    rw [hindependent.available_eq hstate]
  researchCost_antitone := by
    intro left right hstate belief project
    exact le_of_eq (hindependent.researchCost_eq hstate belief project).symm
  completion_mono := by
    intro left right hstate belief project continuation hcontinuation
    rw [hindependent.completion_eq hstate belief project]
    apply expectation_mono
    intro completion
    apply add_le_add
    · exact incumbentReward_mono_of_sameClosureFrontierLE
        process hstate project completion.1
    · apply mul_le_mul_of_nonneg_left
      · exact hcontinuation (terminalBelief completion.1)
          (sameClosureFrontierLE_add hstate completion.2)
      · exact pow_nonneg process.discount_nonnegative _

/--
Frontier monotonicity at fixed closure: if `F₀ ≤ F₁` and the opportunity
primitives are frontier independent, then `V_h(F₀,C) ≤ V_h(F₁,C)`.
-/
theorem compressedValue_mono_of_frontier_le
    (process : Model model catalog closure)
    (hindependent : FrontierIndependentPrimitives process)
    {left right : CompressedLibraryState catalog closure}
    (hclosure : left.state.closure = right.state.closure)
    (hfrontier :
      ∀ belief, left.state.frontier belief ≤ right.state.frontier belief)
    (horizon : Nat) (belief : model.Belief) :
    process.compressedValue horizon belief left ≤
      process.compressedValue horizon belief right := by
  exact compressedValue_mono_of_generativeDominanceOrder process
    (frontierGenerativeDominanceOrder process hindependent)
    horizon belief ⟨hclosure, hfrontier⟩

/-! ## Frontier saturation -/

/--
For a fixed candidate, raising the incumbent frontier pointwise weakly lowers
its passive operational insertion value at every finite horizon.
-/
theorem operationalInsertionValue_antitone_of_frontier_le
    (process : Model model catalog closure)
    {left right : Raw.Library catalog}
    (hfrontier :
      ∀ belief,
        operationalFrontier catalog left belief ≤
          operationalFrontier catalog right belief)
    (strategy : model.StrategyId) :
    ∀ horizon belief,
      operationalInsertionValue process horizon belief right strategy ≤
        operationalInsertionValue process horizon belief left strategy := by
  intro horizon
  induction horizon with
  | zero =>
      intro belief
      simp [operationalInsertionValue, passiveValue]
  | succ horizon inductionHypothesis =>
      intro belief
      rw [operationalInsertionValue_succ,
        operationalInsertionValue_succ]
      apply add_le_add
      · unfold frontierInsertionGap
        rw [Raw.operationalFrontier_insert,
          Raw.operationalFrontier_insert]
        exact max_sub_self_antitone (hfrontier belief)
      · apply mul_le_mul_of_nonneg_left
        · exact expectation_mono _ inductionHypothesis
        · exact process.discount_nonnegative

/-! ## Dynamic research-cost antitonicity -/

/-- A nonnegative exact research-cost table on the fixed unified process. -/
structure ResearchCostSchedule
    (process : Model model catalog closure) where
  cost :
    model.Belief → CompressedLibraryState catalog closure →
      model.ResearchProject → ℚ
  nonnegative : ∀ belief state project, 0 ≤ cost belief state project

/--
Finite unified value with the process's research-cost table replaced by an
explicit schedule.  All other primitives, including the completion coupling,
duration, operation flag, and feasible menu, remain fixed.
-/
noncomputable def compressedValueWithCost
    (process : Model model catalog closure)
    (schedule : ResearchCostSchedule process) :
    Nat → model.Belief → CompressedLibraryState catalog closure → ℚ
  | 0, _, _ => 0
  | horizon + 1, belief, state =>
      Finset.univ.sup' Finset.univ_nonempty
        (fun action : FeasibleAction process (horizon + 1) state =>
          match action.1 with
          | none =>
              state.state.frontier belief +
                process.discount *
                  (process.beliefTransition belief).expectation
                    (fun nextBelief =>
                      compressedValueWithCost process schedule horizon
                        nextBelief state)
          | some project =>
              -schedule.cost belief state project +
                (process.completion project belief state).expectation
                  (fun completion =>
                    process.incumbentReward state project completion.1 +
                      process.discount ^ process.duration project *
                        compressedValueWithCost process schedule
                          ((horizon + 1) - process.duration project)
                          (terminalBelief completion.1)
                          (CompressedLibraryState.add catalog closure state
                            completion.2)))
termination_by horizon => horizon
decreasing_by
  · omega
  · have hpositive := process.duration_positive project
    omega

/--
Research-cost antitonicity: a pointwise lower cost schedule weakly raises the
full optimized finite-horizon value when every other primitive is fixed.
-/
theorem compressedValueWithCost_antitone
    (process : Model model catalog closure)
    {lowerCost higherCost : ResearchCostSchedule process}
    (hcost :
      ∀ belief state project,
        lowerCost.cost belief state project ≤
          higherCost.cost belief state project) :
    ∀ horizon belief state,
      compressedValueWithCost process higherCost horizon belief state ≤
        compressedValueWithCost process lowerCost horizon belief state := by
  intro horizon
  induction horizon using Nat.strong_induction_on with
  | h horizon inductionHypothesis =>
      intro belief state
      cases horizon with
      | zero =>
          simp [compressedValueWithCost]
      | succ remaining =>
          let higherActionValue :
              FeasibleAction process (remaining + 1) state → ℚ :=
            fun action =>
              match action.1 with
              | none =>
                  state.state.frontier belief +
                    process.discount *
                      (process.beliefTransition belief).expectation
                        (fun nextBelief =>
                          compressedValueWithCost process higherCost remaining
                            nextBelief state)
              | some project =>
                  -higherCost.cost belief state project +
                    (process.completion project belief state).expectation
                      (fun completion =>
                        process.incumbentReward state project completion.1 +
                          process.discount ^ process.duration project *
                            compressedValueWithCost process higherCost
                              ((remaining + 1) - process.duration project)
                              (terminalBelief completion.1)
                              (CompressedLibraryState.add catalog closure state
                                completion.2))
          let lowerActionValue :
              FeasibleAction process (remaining + 1) state → ℚ :=
            fun action =>
              match action.1 with
              | none =>
                  state.state.frontier belief +
                    process.discount *
                      (process.beliefTransition belief).expectation
                        (fun nextBelief =>
                          compressedValueWithCost process lowerCost remaining
                            nextBelief state)
              | some project =>
                  -lowerCost.cost belief state project +
                    (process.completion project belief state).expectation
                      (fun completion =>
                        process.incumbentReward state project completion.1 +
                          process.discount ^ process.duration project *
                            compressedValueWithCost process lowerCost
                              ((remaining + 1) - process.duration project)
                              (terminalBelief completion.1)
                              (CompressedLibraryState.add catalog closure state
                                completion.2))
          simp only [compressedValueWithCost]
          apply Finset.sup'_le Finset.univ_nonempty
          intro action haction
          apply le_trans
            (show higherActionValue action ≤ lowerActionValue action by
              cases hproject : action.1 with
              | none =>
                  simp only [higherActionValue, lowerActionValue, hproject]
                  apply add_le_add_right
                  apply mul_le_mul_of_nonneg_left
                  · apply expectation_mono
                    intro nextBelief
                    exact inductionHypothesis remaining
                      (Nat.lt_succ_self remaining) nextBelief state
                  · exact process.discount_nonnegative
              | some project =>
                  simp only [higherActionValue, lowerActionValue, hproject]
                  apply add_le_add
                  · exact neg_le_neg (hcost belief state project)
                  · apply expectation_mono
                    intro completion
                    apply add_le_add le_rfl
                    apply mul_le_mul_of_nonneg_left
                    · apply inductionHypothesis
                      · have hpositive := process.duration_positive project
                        omega
                    · exact pow_nonneg process.discount_nonnegative _)
          exact Finset.le_sup' lowerActionValue haction

/-! ## Admission and survival -/

/-- Success mass under primitive admission `π` and per-period survival `ρ`. -/
def admittedSurvivingMass
    (admission survival : ℚ) (duration : Nat) : ℚ :=
  admission * survival ^ duration

/--
Exact continuation under an otherwise fixed binary candidate law.
`failureValue` and `successValue` already include any finite belief-path
expectation at completion.
-/
def binaryCandidateContinuation
    (admission survival : ℚ) (duration : Nat)
    (failureValue successValue : ℚ) : ℚ :=
  (1 - admittedSurvivingMass admission survival duration) * failureValue +
    admittedSurvivingMass admission survival duration * successValue

/-- Exact cost-sensitive unified project return for the fixed binary law. -/
def binaryCandidateProjectValue
    (discount : ℚ) (duration : Nat) (researchCost operatingReward
      admission survival failureValue successValue : ℚ) : ℚ :=
  -researchCost + operatingReward +
    discount ^ duration *
      binaryCandidateContinuation admission survival duration
        failureValue successValue

/--
Admission-probability monotonicity.  Candidate laws are otherwise identical,
and successful admission must weakly dominate failure at completion.
-/
theorem binaryCandidateProjectValue_mono_admission
    {discount researchCost operatingReward leftAdmission rightAdmission
      survival failureValue successValue : ℚ}
    {duration : Nat}
    (_hduration : 0 < duration)
    (hdiscount : 0 ≤ discount)
    (_hleftAdmission : 0 ≤ leftAdmission)
    (hadmission : leftAdmission ≤ rightAdmission)
    (_hrightAdmission : rightAdmission ≤ 1)
    (hsurvival0 : 0 ≤ survival) (_hsurvival1 : survival ≤ 1)
    (hsuccess : failureValue ≤ successValue) :
    binaryCandidateProjectValue discount duration researchCost operatingReward
        leftAdmission survival failureValue successValue ≤
      binaryCandidateProjectValue discount duration researchCost operatingReward
        rightAdmission survival failureValue successValue := by
  have hmass :
      admittedSurvivingMass leftAdmission survival duration ≤
        admittedSurvivingMass rightAdmission survival duration := by
    unfold admittedSurvivingMass
    exact mul_le_mul_of_nonneg_right hadmission
      (pow_nonneg hsurvival0 _)
  have hdiscountPower : 0 ≤ discount ^ duration :=
    pow_nonneg hdiscount _
  have hcontinuation :
      binaryCandidateContinuation leftAdmission survival duration
          failureValue successValue ≤
        binaryCandidateContinuation rightAdmission survival duration
          failureValue successValue := by
    unfold binaryCandidateContinuation
    nlinarith [
      mul_nonneg (sub_nonneg.mpr hmass) (sub_nonneg.mpr hsuccess)]
  unfold binaryCandidateProjectValue
  exact add_le_add_right
    (mul_le_mul_of_nonneg_left hcontinuation hdiscountPower) _

/--
Strategy-survival monotonicity under the same success-dominates-failure
condition and otherwise identical candidate law.
-/
theorem binaryCandidateProjectValue_mono_survival
    {discount researchCost operatingReward admission
      leftSurvival rightSurvival failureValue successValue : ℚ}
    {duration : Nat}
    (_hduration : 0 < duration)
    (hdiscount : 0 ≤ discount)
    (hadmission0 : 0 ≤ admission) (_hadmission1 : admission ≤ 1)
    (hleftSurvival : 0 ≤ leftSurvival)
    (hsurvival : leftSurvival ≤ rightSurvival)
    (_hrightSurvival : rightSurvival ≤ 1)
    (hsuccess : failureValue ≤ successValue) :
    binaryCandidateProjectValue discount duration researchCost operatingReward
        admission leftSurvival failureValue successValue ≤
      binaryCandidateProjectValue discount duration researchCost operatingReward
        admission rightSurvival failureValue successValue := by
  have hpower :
      leftSurvival ^ duration ≤ rightSurvival ^ duration :=
    pow_le_pow_left₀ hleftSurvival hsurvival duration
  have hmass :
      admittedSurvivingMass admission leftSurvival duration ≤
        admittedSurvivingMass admission rightSurvival duration := by
    unfold admittedSurvivingMass
    exact mul_le_mul_of_nonneg_left hpower hadmission0
  have hdiscountPower : 0 ≤ discount ^ duration :=
    pow_nonneg hdiscount _
  have hcontinuation :
      binaryCandidateContinuation admission leftSurvival duration
          failureValue successValue ≤
        binaryCandidateContinuation admission rightSurvival duration
          failureValue successValue := by
    unfold binaryCandidateContinuation
    nlinarith [
      mul_nonneg (sub_nonneg.mpr hmass) (sub_nonneg.mpr hsuccess)]
  unfold binaryCandidateProjectValue
  exact add_le_add_right
    (mul_le_mul_of_nonneg_left hcontinuation hdiscountPower) _

/-! ## Unified elapsed-time delay -/

/--
Exact unified elapsed-time value of a project with a deterministic operating
reward stream and terminal descendant continuation.
-/
def unifiedElapsedProjectValue
    (discount researchCost : ℚ) (duration : Nat)
    (operatingFrontier : Nat → ℚ) (descendantContinuation : ℚ) : ℚ :=
  -researchCost +
    ∑ time ∈ Finset.range duration,
      discount ^ time * operatingFrontier time +
    discount ^ duration * descendantContinuation

/-- One extra elapsed period has the exact displayed marginal contribution. -/
theorem unifiedElapsedProjectValue_succ
    (discount researchCost : ℚ) (duration : Nat)
    (operatingFrontier : Nat → ℚ) (descendantContinuation : ℚ) :
    unifiedElapsedProjectValue discount researchCost (duration + 1)
        operatingFrontier descendantContinuation =
      unifiedElapsedProjectValue discount researchCost duration
          operatingFrontier descendantContinuation +
        discount ^ duration *
          (operatingFrontier duration -
            (1 - discount) * descendantContinuation) := by
  unfold unifiedElapsedProjectValue
  rw [Finset.sum_range_succ, pow_succ]
  ring

/--
Assumptions for delay antitonicity under unified elapsed time.

The first two fields record the requested sign conditions.  The final field is
the additional no-waiting-gain condition required when operation continues:
one more incumbent reward cannot exceed the discount opportunity cost of
postponing the descendant continuation.
-/
structure DelayAntitoneCertificate
    (discount : ℚ) (short long : Nat)
    (operatingFrontier : Nat → ℚ)
    (descendantContinuation : ℚ) : Prop where
  operating_nonnegative :
    ∀ time, short ≤ time → time < long →
      0 ≤ operatingFrontier time
  continuation_nonnegative : 0 ≤ descendantContinuation
  no_waiting_gain :
    ∀ time, short ≤ time → time < long →
      operatingFrontier time ≤
        (1 - discount) * descendantContinuation

/--
Delay antitonicity under the exact unified elapsed-time model and the explicit
no-waiting-gain condition.
-/
theorem unifiedElapsedProjectValue_antitone_duration
    {discount researchCost descendantContinuation : ℚ}
    {short long : Nat} {operatingFrontier : Nat → ℚ}
    (_hshortPositive : 0 < short)
    (hdelay : short ≤ long)
    (hdiscount0 : 0 ≤ discount) (_hdiscount1 : discount ≤ 1)
    (certificate :
      DelayAntitoneCertificate discount short long operatingFrontier
        descendantContinuation) :
    unifiedElapsedProjectValue discount researchCost long operatingFrontier
        descendantContinuation ≤
      unifiedElapsedProjectValue discount researchCost short operatingFrontier
        descendantContinuation := by
  induction long, hdelay using Nat.le_induction with
  | base =>
      exact le_rfl
  | succ duration hshortDuration inductionHypothesis =>
      rw [unifiedElapsedProjectValue_succ]
      have hmarginal :
          discount ^ duration *
              (operatingFrontier duration -
                (1 - discount) * descendantContinuation) ≤ 0 :=
        mul_nonpos_of_nonneg_of_nonpos
          (pow_nonneg hdiscount0 _)
          (sub_nonpos.mpr
            (certificate.no_waiting_gain duration hshortDuration
              (Nat.lt_succ_self duration)))
      have hstep :
          unifiedElapsedProjectValue discount researchCost duration
                operatingFrontier descendantContinuation +
              discount ^ duration *
                (operatingFrontier duration -
                  (1 - discount) * descendantContinuation) ≤
            unifiedElapsedProjectValue discount researchCost duration
              operatingFrontier descendantContinuation := by
        linarith
      have hrestricted :
          DelayAntitoneCertificate discount short duration operatingFrontier
            descendantContinuation := by
        refine ⟨?_, certificate.continuation_nonnegative, ?_⟩
        · intro time hshort htime
          exact certificate.operating_nonnegative time hshort
            (htime.trans (Nat.lt_succ_self duration))
        · intro time hshort htime
          exact certificate.no_waiting_gain time hshort
            (htime.trans (Nat.lt_succ_self duration))
      exact hstep.trans (inductionHypothesis hrestricted)

/-- With suspended operation, nonnegative continuation is sufficient. -/
theorem unifiedElapsedProjectValue_antitone_duration_of_suspendedOperation
    {discount researchCost descendantContinuation : ℚ}
    {short long : Nat}
    (hshortPositive : 0 < short)
    (hdelay : short ≤ long)
    (hdiscount0 : 0 ≤ discount) (hdiscount1 : discount ≤ 1)
    (hcontinuation : 0 ≤ descendantContinuation) :
    unifiedElapsedProjectValue discount researchCost long (fun _ => 0)
        descendantContinuation ≤
      unifiedElapsedProjectValue discount researchCost short (fun _ => 0)
        descendantContinuation := by
  apply unifiedElapsedProjectValue_antitone_duration hshortPositive hdelay
    hdiscount0 hdiscount1
  refine
    { operating_nonnegative := ?_
      continuation_nonnegative := hcontinuation
      no_waiting_gain := ?_ }
  · intros
    exact le_rfl
  · intro time hshort hlong
    apply mul_nonneg
    · linarith
    · exact hcontinuation

/-! ## Closure monotonicity -/

/-- The declared generative-dominance relation on raw libraries. -/
def GenerativelyDominates
    (process : Model model catalog closure)
    (left right : Raw.Library catalog) : Prop :=
  ClosureEnrichmentProjectDominance process left right

/--
Closure monotonicity is one-way under the declared generative-dominance order.
Closure inclusion alone is deliberately insufficient.
-/
theorem fullValue_mono_of_generativeDominance
    (process : Model model catalog closure)
    {left right : Raw.Library catalog}
    (hdominance : GenerativelyDominates process left right)
    (horizon : Nat) (belief : model.Belief) :
    fullValue process horizon belief left ≤
      fullValue process horizon belief right :=
  fullValue_mono_of_closureEnrichmentProjectDominance
    process hdominance horizon belief

/-! ## Exact finite action regions -/

/-- States where one fixed research action weakly dominates Continue. -/
def exactFiniteActionRegion
    {State : Type*} [Fintype State]
    (continueValue researchValue : State → ℚ) : Finset State :=
  Finset.univ.filter fun state => continueValue state ≤ researchValue state

@[simp]
theorem mem_exactFiniteActionRegion_iff
    {State : Type*} [Fintype State]
    (continueValue researchValue : State → ℚ) (state : State) :
    state ∈ exactFiniteActionRegion continueValue researchValue ↔
      continueValue state ≤ researchValue state := by
  simp [exactFiniteActionRegion]

/-- Pointwise higher research returns weakly expand the exact action region. -/
theorem exactFiniteActionRegion_mono
    {State : Type*} [Fintype State]
    (continueValue leftResearch rightResearch : State → ℚ)
    (hresearch : ∀ state, leftResearch state ≤ rightResearch state) :
    exactFiniteActionRegion continueValue leftResearch ⊆
      exactFiniteActionRegion continueValue rightResearch := by
  intro state hstate
  rw [mem_exactFiniteActionRegion_iff] at hstate ⊢
  exact hstate.trans (hresearch state)

/-- Binary-candidate research return indexed by a finite decision state. -/
def binaryCandidateResearchReturn
    {State : Type*}
    (discount : ℚ) (duration : Nat)
    (researchCost operatingReward admission survival
      failureValue successValue : State → ℚ) :
    State → ℚ :=
  fun state =>
    binaryCandidateProjectValue discount duration
      (researchCost state) (operatingReward state)
      (admission state) (survival state)
      (failureValue state) (successValue state)

/--
Lower costs weakly expand the exact finite research-action region when every
other primitive is fixed.
-/
theorem exactFiniteActionRegion_subset_of_lower_cost
    {State : Type*} [Fintype State]
    (continueValue : State → ℚ)
    (discount : ℚ) (duration : Nat)
    (lowerCost higherCost operatingReward admission survival
      failureValue successValue : State → ℚ)
    (_hduration : 0 < duration)
    (hcost : ∀ state, lowerCost state ≤ higherCost state) :
    exactFiniteActionRegion continueValue
        (binaryCandidateResearchReturn discount duration higherCost
          operatingReward admission survival failureValue successValue) ⊆
      exactFiniteActionRegion continueValue
        (binaryCandidateResearchReturn discount duration lowerCost
          operatingReward admission survival failureValue successValue) := by
  apply exactFiniteActionRegion_mono
  intro state
  unfold binaryCandidateResearchReturn binaryCandidateProjectValue
  linarith [hcost state]

/--
Higher survival weakly expands the exact finite research-action region when
all other primitives are fixed and success weakly dominates failure.
-/
theorem exactFiniteActionRegion_subset_of_higher_survival
    {State : Type*} [Fintype State]
    (continueValue : State → ℚ)
    (discount : ℚ) (duration : Nat)
    (researchCost operatingReward admission
      lowerSurvival higherSurvival failureValue successValue : State → ℚ)
    (hduration : 0 < duration)
    (hdiscount : 0 ≤ discount)
    (hadmission0 : ∀ state, 0 ≤ admission state)
    (hadmission1 : ∀ state, admission state ≤ 1)
    (hlowerSurvival : ∀ state, 0 ≤ lowerSurvival state)
    (hsurvival : ∀ state, lowerSurvival state ≤ higherSurvival state)
    (hhigherSurvival : ∀ state, higherSurvival state ≤ 1)
    (hsuccess : ∀ state, failureValue state ≤ successValue state) :
    exactFiniteActionRegion continueValue
        (binaryCandidateResearchReturn discount duration researchCost
          operatingReward admission lowerSurvival failureValue successValue) ⊆
      exactFiniteActionRegion continueValue
        (binaryCandidateResearchReturn discount duration researchCost
          operatingReward admission higherSurvival failureValue successValue) := by
  apply exactFiniteActionRegion_mono
  intro state
  exact binaryCandidateProjectValue_mono_survival
    hduration hdiscount (hadmission0 state) (hadmission1 state)
    (hlowerSurvival state) (hsurvival state) (hhigherSurvival state)
    (hsuccess state)

/-! ## Exact sign-failure counterexamples -/

namespace Counterexamples

/-- One-period value when both Continue and one research return are available. -/
def oneStepValue (frontier researchReturn : ℚ) : ℚ :=
  max frontier researchReturn

/--
Raising the frontier can lower value if the research opportunity is allowed
to change at the same time.
-/
theorem frontier_mono_fails_without_fixed_opportunities :
    (0 : ℚ) ≤ 1 ∧ oneStepValue 1 0 < oneStepValue 0 2 := by
  norm_num [oneStepValue]

/-- Higher admission can lower value when successful admission is harmful. -/
theorem admission_mono_fails_without_successDominance :
    binaryCandidateProjectValue 1 1 0 0 1 1 1 0 <
      binaryCandidateProjectValue 1 1 0 0 0 1 1 0 := by
  norm_num [binaryCandidateProjectValue, binaryCandidateContinuation,
    admittedSurvivingMass]

/-- Higher survival can lower value when the surviving strategy is harmful. -/
theorem survival_mono_fails_without_successDominance :
    binaryCandidateProjectValue 1 1 0 0 1 1 1 0 <
      binaryCandidateProjectValue 1 1 0 0 1 0 1 0 := by
  norm_num [binaryCandidateProjectValue, binaryCandidateContinuation,
    admittedSurvivingMass]

/--
Nonnegative operation and nonnegative continuation alone do not imply delay
antitonicity under unified elapsed time.
-/
theorem delay_antitone_fails_without_noWaitingGain :
    unifiedElapsedProjectValue (1 / 2) 0 1 (fun _ => 1) 1 <
      unifiedElapsedProjectValue (1 / 2) 0 2 (fun _ => 1) 1 := by
  norm_num [unifiedElapsedProjectValue]

/-- Nonnegative terminal continuation is necessary under suspended operation. -/
theorem delay_antitone_fails_with_negativeContinuation :
    unifiedElapsedProjectValue (1 / 2) 0 1 (fun _ => 0) (-1) <
      unifiedElapsedProjectValue (1 / 2) 0 2 (fun _ => 0) (-1) := by
  norm_num [unifiedElapsedProjectValue]

/-- Closure inclusion alone has no value sign without generative dominance. -/
def closureValue (modules : Finset Unit) : ℚ :=
  if () ∈ modules then 1 else 2

theorem closure_mono_fails_without_generativeDominance :
    (∅ : Finset Unit) ⊆ {()} ∧
      closureValue {()} < closureValue ∅ := by
  constructor
  · simp
  · norm_num [closureValue]

/--
A lower cost does not expand the action region if another primitive is allowed
to deteriorate simultaneously.
-/
theorem lower_cost_region_fails_when_returns_change :
    (0 : ℚ) ≤ 1 ∧
      (0 : Fin 1) ∈ exactFiniteActionRegion (fun _ : Fin 1 => 0)
        (fun _ => oneStepValue 0 (2 - 1)) ∧
      (0 : Fin 1) ∉ exactFiniteActionRegion (fun _ : Fin 1 => 0)
        (fun _ => -1) := by
  norm_num [exactFiniteActionRegion, oneStepValue]

end Counterexamples

end ComparativeStatics

end Model

end Projection

end StrategyInnovation
