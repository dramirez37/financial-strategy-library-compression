import Mathlib.Data.Fintype.EquivFin
import Mathlib.Data.Setoid.Basic
import StrategyInnovation.Projection.RawToCompressed

/-!
# Unified cost-sensitive dynamic innovation equivalence

This module replaces the publication-facing cost-free primitive equivalence
with an equivalence derived from the unified raw model.  Project data are
tagged by availability: `none` means that the project is unavailable, while
`some data` records the corresponding cost, duration, terminal joint law, or
expected operating-reward block.  Consequently equality of the requested
project observations also identifies the feasible project menu.

The terminal law is the exact joint law of next belief and next realizable
compressed state.  The operating-reward observation is the exact expectation
of the discounted incumbent reward block.  This is sufficient because the
unified Bellman action adds that block to a continuation depending only on the
terminal pair; no independence assumption is used.
-/

namespace StrategyInnovation

namespace RatProb

universe u

/-- Exact expectation is additive in its integrand. -/
theorem expectation_add {α : Type u} (distribution : RatProb α)
    (left right : α → ℚ) :
    distribution.expectation (fun outcome => left outcome + right outcome) =
      distribution.expectation left + distribution.expectation right := by
  classical
  unfold expectation Finsupp.sum
  simp_rw [mul_add]
  exact Finset.sum_add_distrib

/-- A constant rational factor can be pulled through exact expectation. -/
theorem expectation_const_mul {α : Type u} (distribution : RatProb α)
    (constant : ℚ) (value : α → ℚ) :
    distribution.expectation (fun outcome => constant * value outcome) =
      constant * distribution.expectation value := by
  classical
  unfold expectation Finsupp.sum
  rw [Finset.mul_sum]
  apply Finset.sum_congr rfl
  intro outcome _
  ring

end RatProb

namespace BellmanContraction

universe u

/-- Exact real expectation is additive in its integrand. -/
theorem realExpectedValue_add {α : Type u} (distribution : RatProb α)
    (left right : α → ℝ) :
    realExpectedValue distribution (fun outcome => left outcome + right outcome) =
      realExpectedValue distribution left + realExpectedValue distribution right := by
  classical
  unfold realExpectedValue Finsupp.sum
  simp_rw [mul_add]
  exact Finset.sum_add_distrib

/-- A constant real factor can be pulled through exact real expectation. -/
theorem realExpectedValue_const_mul {α : Type u} (distribution : RatProb α)
    (constant : ℝ) (value : α → ℝ) :
    realExpectedValue distribution (fun outcome => constant * value outcome) =
      constant * realExpectedValue distribution value := by
  classical
  unfold realExpectedValue Finsupp.sum
  rw [Finset.mul_sum]
  apply Finset.sum_congr rfl
  intro outcome _
  ring

/-- Casting `RatProb.expectation` gives the corresponding exact real expectation. -/
theorem realExpectedValue_ratExpectation {α : Type u} (distribution : RatProb α)
    (value : α → ℚ) :
    realExpectedValue distribution (fun outcome => (value outcome : ℝ)) =
      (distribution.expectation value : ℝ) := by
  classical
  unfold realExpectedValue RatProb.expectation Finsupp.sum
  simp only [Rat.cast_sum, Rat.cast_mul]

end BellmanContraction

namespace Projection

namespace RatProb

universe u v

/-- Expectation under a deterministic pushforward is expectation after composition. -/
theorem expectation_map {α : Type u} {β : Type v}
    (distribution : StrategyInnovation.RatProb α) (f : α → β) (value : β → ℚ) :
    (map distribution f).expectation value =
      distribution.expectation (value ∘ f) := by
  classical
  unfold StrategyInnovation.RatProb.expectation map
  rw [Finsupp.sum_mapDomain_index]
  · rfl
  · intro outcome
    simp
  · intro outcome left right
    ring

/-- Real expectation under a deterministic pushforward is expectation after composition. -/
theorem realExpectedValue_map {α : Type u} {β : Type v}
    (distribution : StrategyInnovation.RatProb α) (f : α → β) (value : β → ℝ) :
    BellmanContraction.realExpectedValue (map distribution f) value =
      BellmanContraction.realExpectedValue distribution (value ∘ f) := by
  classical
  unfold BellmanContraction.realExpectedValue map
  rw [Finsupp.sum_mapDomain_index]
  · rfl
  · intro outcome
    simp
  · intro outcome left right
    push_cast
    ring

end RatProb

namespace Model

open scoped BigOperators

variable {model : FiniteModel}
variable {catalog : Raw.StrategyCatalog model} {closure : Raw.ClosureOperator model}

/-- The exact joint terminal law of next belief and next realizable compressed state. -/
noncomputable def projectNextStateLaw (process : Model model catalog closure)
    (belief : model.Belief) (state : CompressedLibraryState catalog closure)
    (project : model.ResearchProject) :
    RatProb (model.Belief × CompressedLibraryState catalog closure) :=
  Projection.RatProb.map (process.completion project belief state)
    (fun completion =>
      (terminalBelief completion.1,
        CompressedLibraryState.add catalog closure state completion.2))

/-- Exact expected discounted incumbent reward earned during a project. -/
def expectedOperatingReward (process : Model model catalog closure)
    (belief : model.Belief) (state : CompressedLibraryState catalog closure)
    (project : model.ResearchProject) : ℚ :=
  (process.completion project belief state).expectation
    (process.incumbentReward state project ∘ Prod.fst)

/-- Tag project data by membership in the state's feasible project menu. -/
def availableProjectData (process : Model model catalog closure)
    (state : CompressedLibraryState catalog closure)
    (project : model.ResearchProject) {α : Type*} (data : α) : Option α :=
  if project ∈ process.available state then some data else none

/--
Cost-sensitive unified dynamic innovation equivalence on realizable compressed
states.  Its five fields are exactly the publication-facing observations.
-/
structure CompressedDynamicInnovationEquivalent
    (process : Model model catalog closure)
    (left right : CompressedLibraryState catalog closure) : Prop where
  frontier : ∀ belief, left.state.frontier belief = right.state.frontier belief
  projectCost : ∀ belief project,
    process.availableProjectData left project
        (process.researchCost belief left project) =
      process.availableProjectData right project
        (process.researchCost belief right project)
  projectDuration : ∀ project,
    process.availableProjectData left project (process.duration project) =
      process.availableProjectData right project (process.duration project)
  nextStateLaw : ∀ belief project,
    process.availableProjectData left project
        (process.projectNextStateLaw belief left project) =
      process.availableProjectData right project
        (process.projectNextStateLaw belief right project)
  operatingReward : ∀ belief project,
    process.availableProjectData left project
        (process.expectedOperatingReward belief left project) =
      process.availableProjectData right project
        (process.expectedOperatingReward belief right project)

/-- Publication-facing dynamic innovation equivalence on raw libraries. -/
def DynamicInnovationEquivalent (process : Model model catalog closure)
    (left right : Raw.Library catalog) : Prop :=
  CompressedDynamicInnovationEquivalent process
    (CompressedLibraryState.ofLibrary catalog closure left)
    (CompressedLibraryState.ofLibrary catalog closure right)

/-- Unified compressed-state equivalence is reflexive. -/
theorem compressedDynamicInnovationEquivalent_refl
    (process : Model model catalog closure)
    (state : CompressedLibraryState catalog closure) :
    CompressedDynamicInnovationEquivalent process state state := by
  constructor <;> intros <;> rfl

/-- Unified compressed-state equivalence is symmetric. -/
theorem compressedDynamicInnovationEquivalent_symm
    (process : Model model catalog closure)
    {left right : CompressedLibraryState catalog closure}
    (hequivalent : CompressedDynamicInnovationEquivalent process left right) :
    CompressedDynamicInnovationEquivalent process right left := by
  constructor
  · intro belief
    exact (hequivalent.frontier belief).symm
  · intro belief project
    exact (hequivalent.projectCost belief project).symm
  · intro project
    exact (hequivalent.projectDuration project).symm
  · intro belief project
    exact (hequivalent.nextStateLaw belief project).symm
  · intro belief project
    exact (hequivalent.operatingReward belief project).symm

/-- Unified compressed-state equivalence is transitive. -/
theorem compressedDynamicInnovationEquivalent_trans
    (process : Model model catalog closure)
    {first second third : CompressedLibraryState catalog closure}
    (hfirst : CompressedDynamicInnovationEquivalent process first second)
    (hsecond : CompressedDynamicInnovationEquivalent process second third) :
    CompressedDynamicInnovationEquivalent process first third := by
  constructor
  · intro belief
    exact (hfirst.frontier belief).trans (hsecond.frontier belief)
  · intro belief project
    exact (hfirst.projectCost belief project).trans
      (hsecond.projectCost belief project)
  · intro project
    exact (hfirst.projectDuration project).trans
      (hsecond.projectDuration project)
  · intro belief project
    exact (hfirst.nextStateLaw belief project).trans
      (hsecond.nextStateLaw belief project)
  · intro belief project
    exact (hfirst.operatingReward belief project).trans
      (hsecond.operatingReward belief project)

/-- Unified raw-library dynamic innovation equivalence is reflexive. -/
theorem dynamicInnovationEquivalent_refl
    (process : Model model catalog closure) (library : Raw.Library catalog) :
    DynamicInnovationEquivalent process library library :=
  compressedDynamicInnovationEquivalent_refl process _

/-- Unified raw-library dynamic innovation equivalence is symmetric. -/
theorem dynamicInnovationEquivalent_symm
    (process : Model model catalog closure) {left right : Raw.Library catalog}
    (hequivalent : DynamicInnovationEquivalent process left right) :
    DynamicInnovationEquivalent process right left :=
  compressedDynamicInnovationEquivalent_symm process hequivalent

/-- Unified raw-library dynamic innovation equivalence is transitive. -/
theorem dynamicInnovationEquivalent_trans
    (process : Model model catalog closure) {first second third : Raw.Library catalog}
    (hfirst : DynamicInnovationEquivalent process first second)
    (hsecond : DynamicInnovationEquivalent process second third) :
    DynamicInnovationEquivalent process first third :=
  compressedDynamicInnovationEquivalent_trans process hfirst hsecond

/-- The unified cost-sensitive setoid on raw libraries. -/
def dynamicInnovationSetoid (process : Model model catalog closure) :
    Setoid (Raw.Library catalog) where
  r := DynamicInnovationEquivalent process
  iseqv :=
    ⟨dynamicInnovationEquivalent_refl process,
      dynamicInnovationEquivalent_symm process,
      dynamicInnovationEquivalent_trans process⟩

/-- Raw libraries modulo unified cost-sensitive dynamic innovation equivalence. -/
abbrev DynamicInnovationQuotient (process : Model model catalog closure) :=
  Quotient (dynamicInnovationSetoid process)

/-- The unified dynamic innovation quotient is finite. -/
instance dynamicInnovationQuotientFinite (process : Model model catalog closure) :
    Finite (DynamicInnovationQuotient process) :=
  inferInstance

/-- The unified dynamic innovation class of a raw library. -/
def dynamicInnovationClass (process : Model model catalog closure)
    (library : Raw.Library catalog) : DynamicInnovationQuotient process :=
  Quotient.mk _ library

/-- Equality of actual compressed states is sufficient for unified DI equivalence. -/
theorem compressedState_eq_implies_dynamicInnovationEquivalent
    (process : Model model catalog closure) {left right : Raw.Library catalog}
    (hstate : compressedLibraryState catalog closure left =
      compressedLibraryState catalog closure right) :
    DynamicInnovationEquivalent process left right := by
  have hofLibrary :
      CompressedLibraryState.ofLibrary catalog closure left =
        CompressedLibraryState.ofLibrary catalog closure right := by
    apply CompressedLibraryState.ext
    exact hstate
  unfold DynamicInnovationEquivalent
  rw [hofLibrary]
  exact compressedDynamicInnovationEquivalent_refl process _

/-- Equivalent compressed states have identical available project sets. -/
theorem available_eq_of_compressedDynamicInnovationEquivalent
    (process : Model model catalog closure)
    {left right : CompressedLibraryState catalog closure}
    (hequivalent : CompressedDynamicInnovationEquivalent process left right) :
    process.available left = process.available right := by
  ext project
  constructor
  · intro hleft
    by_contra hright
    have hduration := hequivalent.projectDuration project
    simp [availableProjectData, hleft, hright] at hduration
  · intro hright
    by_contra hleft
    have hduration := hequivalent.projectDuration project
    simp [availableProjectData, hleft, hright] at hduration

/-- On an available project, the tagged cost equality reduces to ordinary equality. -/
theorem researchCost_eq_of_compressedDynamicInnovationEquivalent
    (process : Model model catalog closure)
    {left right : CompressedLibraryState catalog closure}
    (hequivalent : CompressedDynamicInnovationEquivalent process left right)
    (belief : model.Belief) (project : model.ResearchProject)
    (hleft : project ∈ process.available left) :
    process.researchCost belief left project =
      process.researchCost belief right project := by
  have hright : project ∈ process.available right := by
    rw [← process.available_eq_of_compressedDynamicInnovationEquivalent hequivalent]
    exact hleft
  simpa [availableProjectData, hleft, hright] using
    hequivalent.projectCost belief project

/-- On an available project, tagged terminal-law equality reduces to law equality. -/
theorem projectNextStateLaw_eq_of_compressedDynamicInnovationEquivalent
    (process : Model model catalog closure)
    {left right : CompressedLibraryState catalog closure}
    (hequivalent : CompressedDynamicInnovationEquivalent process left right)
    (belief : model.Belief) (project : model.ResearchProject)
    (hleft : project ∈ process.available left) :
    process.projectNextStateLaw belief left project =
      process.projectNextStateLaw belief right project := by
  have hright : project ∈ process.available right := by
    rw [← process.available_eq_of_compressedDynamicInnovationEquivalent hequivalent]
    exact hleft
  simpa [availableProjectData, hleft, hright] using
    hequivalent.nextStateLaw belief project

/-- On an available project, tagged operating-reward equality reduces to equality. -/
theorem expectedOperatingReward_eq_of_compressedDynamicInnovationEquivalent
    (process : Model model catalog closure)
    {left right : CompressedLibraryState catalog closure}
    (hequivalent : CompressedDynamicInnovationEquivalent process left right)
    (belief : model.Belief) (project : model.ResearchProject)
    (hleft : project ∈ process.available left) :
    process.expectedOperatingReward belief left project =
      process.expectedOperatingReward belief right project := by
  have hright : project ∈ process.available right := by
    rw [← process.available_eq_of_compressedDynamicInnovationEquivalent hequivalent]
    exact hleft
  simpa [availableProjectData, hleft, hright] using
    hequivalent.operatingReward belief project

/-- Project action value expressed only through the unified DI observations. -/
noncomputable def compressedProjectActionValue
    (process : Model model catalog closure) (remainingHorizon : Nat)
    (belief : model.Belief) (state : CompressedLibraryState catalog closure)
    (project : model.ResearchProject) : ℚ :=
  -process.researchCost belief state project +
    process.expectedOperatingReward belief state project +
      process.discount ^ process.duration project *
        (process.projectNextStateLaw belief state project).expectation
          (fun nextState =>
            process.compressedValue remainingHorizon nextState.1 nextState.2)

/-- The signature form is exactly the completion-coupling action expression. -/
theorem compressedProjectActionValue_eq_completion
    (process : Model model catalog closure) (remainingHorizon : Nat)
    (belief : model.Belief) (state : CompressedLibraryState catalog closure)
    (project : model.ResearchProject) :
    process.compressedProjectActionValue remainingHorizon belief state project =
      -process.researchCost belief state project +
        (process.completion project belief state).expectation
          (fun completion =>
            process.incumbentReward state project completion.1 +
              process.discount ^ process.duration project *
                process.compressedValue remainingHorizon
                  (terminalBelief completion.1)
                  (CompressedLibraryState.add catalog closure state completion.2)) := by
  unfold compressedProjectActionValue expectedOperatingReward projectNextStateLaw
  rw [Projection.RatProb.expectation_map]
  rw [RatProb.expectation_add, RatProb.expectation_const_mul]
  change
    -process.researchCost belief state project +
          (process.completion project belief state).expectation
            (fun completion => process.incumbentReward state project completion.1) +
        process.discount ^ process.duration project *
          (process.completion project belief state).expectation
            (fun completion =>
              process.compressedValue remainingHorizon
                (terminalBelief completion.1)
                (CompressedLibraryState.add catalog closure state completion.2)) =
      -process.researchCost belief state project +
        ((process.completion project belief state).expectation
            (fun completion => process.incumbentReward state project completion.1) +
          process.discount ^ process.duration project *
            (process.completion project belief state).expectation
              (fun completion =>
                process.compressedValue remainingHorizon
                  (terminalBelief completion.1)
                  (CompressedLibraryState.add catalog closure state completion.2)))
  ring

/-- Available unified project action values agree under compressed DI equivalence. -/
theorem compressedProjectActionValue_eq_of_compressedDynamicInnovationEquivalent
    (process : Model model catalog closure) (remainingHorizon : Nat)
    {left right : CompressedLibraryState catalog closure}
    (hequivalent : CompressedDynamicInnovationEquivalent process left right)
    (belief : model.Belief) (project : model.ResearchProject)
    (hleft : project ∈ process.available left) :
    process.compressedProjectActionValue remainingHorizon belief left project =
      process.compressedProjectActionValue remainingHorizon belief right project := by
  unfold compressedProjectActionValue
  rw [process.researchCost_eq_of_compressedDynamicInnovationEquivalent
    hequivalent belief project hleft]
  rw [process.expectedOperatingReward_eq_of_compressedDynamicInnovationEquivalent
    hequivalent belief project hleft]
  rw [process.projectNextStateLaw_eq_of_compressedDynamicInnovationEquivalent
    hequivalent belief project hleft]

/-- Unified DI-equivalent compressed states have identical finite-horizon values. -/
theorem compressedValue_eq_of_compressedDynamicInnovationEquivalent
    (process : Model model catalog closure) :
    ∀ horizon {left right : CompressedLibraryState catalog closure},
      CompressedDynamicInnovationEquivalent process left right →
        ∀ belief,
          process.compressedValue horizon belief left =
            process.compressedValue horizon belief right := by
  intro horizon
  induction horizon using Nat.strong_induction_on with
  | h horizon inductionHypothesis =>
      intro left right hequivalent belief
      cases horizon with
      | zero =>
          simp [compressedValue]
      | succ horizon =>
          have havailable : process.available left = process.available right :=
            process.available_eq_of_compressedDynamicInnovationEquivalent hequivalent
          let toRight : FeasibleAction process (horizon + 1) left →
              FeasibleAction process (horizon + 1) right :=
            fun action =>
              ⟨action.1, by
                cases haction : action.1 with
                | none => trivial
                | some project =>
                    have hfeasible := action.2
                    rw [haction] at hfeasible
                    exact ⟨by
                      rw [← havailable]
                      exact hfeasible.1, hfeasible.2⟩⟩
          let toLeft : FeasibleAction process (horizon + 1) right →
              FeasibleAction process (horizon + 1) left :=
            fun action =>
              ⟨action.1, by
                cases haction : action.1 with
                | none => trivial
                | some project =>
                    have hfeasible := action.2
                    rw [haction] at hfeasible
                    exact ⟨by
                      rw [havailable]
                      exact hfeasible.1, hfeasible.2⟩⟩
          let leftActionValue : FeasibleAction process (horizon + 1) left → ℚ :=
            fun action =>
              match action.1 with
              | none =>
                  left.state.frontier belief + process.discount *
                    (process.beliefTransition belief).expectation
                      (fun nextBelief =>
                        process.compressedValue horizon nextBelief left)
              | some project =>
                  -process.researchCost belief left project +
                    (process.completion project belief left).expectation
                      (fun completion =>
                        process.incumbentReward left project completion.1 +
                          process.discount ^ process.duration project *
                            process.compressedValue
                              ((horizon + 1) - process.duration project)
                              (terminalBelief completion.1)
                              (CompressedLibraryState.add catalog closure left
                                completion.2))
          let rightActionValue : FeasibleAction process (horizon + 1) right → ℚ :=
            fun action =>
              match action.1 with
              | none =>
                  right.state.frontier belief + process.discount *
                    (process.beliefTransition belief).expectation
                      (fun nextBelief =>
                        process.compressedValue horizon nextBelief right)
              | some project =>
                  -process.researchCost belief right project +
                    (process.completion project belief right).expectation
                      (fun completion =>
                        process.incumbentReward right project completion.1 +
                          process.discount ^ process.duration project *
                            process.compressedValue
                              ((horizon + 1) - process.duration project)
                              (terminalBelief completion.1)
                              (CompressedLibraryState.add catalog closure right
                                completion.2))
          have hleftAction : ∀ action,
              leftActionValue action = rightActionValue (toRight action) := by
            intro action
            rcases action with ⟨action, hfeasible⟩
            cases action with
            | none =>
                dsimp [leftActionValue, rightActionValue, toRight]
                rw [hequivalent.frontier belief]
                apply congrArg
                  (fun continuation =>
                    right.state.frontier belief + process.discount * continuation)
                apply StrategyInnovation.RatProb.expectation_congr
                intro nextBelief
                exact inductionHypothesis horizon (Nat.lt_succ_self horizon)
                  hequivalent nextBelief
            | some project =>
                have hmember : project ∈ process.available left := hfeasible.1
                dsimp [leftActionValue, rightActionValue, toRight]
                rw [← process.compressedProjectActionValue_eq_completion
                  ((horizon + 1) - process.duration project) belief left project]
                rw [← process.compressedProjectActionValue_eq_completion
                  ((horizon + 1) - process.duration project) belief right project]
                exact process.compressedProjectActionValue_eq_of_compressedDynamicInnovationEquivalent
                  ((horizon + 1) - process.duration project) hequivalent
                  belief project hmember
          have hrightAction : ∀ action,
              rightActionValue action = leftActionValue (toLeft action) := by
            intro action
            rcases action with ⟨action, hfeasible⟩
            cases action with
            | none =>
                dsimp [leftActionValue, rightActionValue, toLeft]
                rw [← hequivalent.frontier belief]
                apply congrArg
                  (fun continuation =>
                    left.state.frontier belief + process.discount * continuation)
                apply StrategyInnovation.RatProb.expectation_congr
                intro nextBelief
                exact (inductionHypothesis horizon (Nat.lt_succ_self horizon)
                  hequivalent nextBelief).symm
            | some project =>
                have hmember : project ∈ process.available right := hfeasible.1
                have hmemberLeft : project ∈ process.available left := by
                  rw [havailable]
                  exact hmember
                dsimp [leftActionValue, rightActionValue, toLeft]
                rw [← process.compressedProjectActionValue_eq_completion
                  ((horizon + 1) - process.duration project) belief right project]
                rw [← process.compressedProjectActionValue_eq_completion
                  ((horizon + 1) - process.duration project) belief left project]
                exact (process.compressedProjectActionValue_eq_of_compressedDynamicInnovationEquivalent
                  ((horizon + 1) - process.duration project) hequivalent
                  belief project hmemberLeft).symm
          simp only [compressedValue]
          change
            Finset.univ.sup' Finset.univ_nonempty leftActionValue =
              Finset.univ.sup' Finset.univ_nonempty rightActionValue
          apply le_antisymm
          · apply Finset.sup'_le Finset.univ_nonempty
            intro action _
            rw [hleftAction action]
            exact Finset.le_sup' rightActionValue (Finset.mem_univ (toRight action))
          · apply Finset.sup'_le Finset.univ_nonempty
            intro action _
            rw [hrightAction action]
            exact Finset.le_sup' leftActionValue (Finset.mem_univ (toLeft action))

/-- Unified DI-equivalent raw libraries have identical finite-horizon values. -/
theorem rawValue_eq_of_dynamicInnovationEquivalent
    (process : Model model catalog closure) {left right : Raw.Library catalog}
    (hequivalent : DynamicInnovationEquivalent process left right) :
    ∀ horizon belief,
      process.rawValue horizon belief left = process.rawValue horizon belief right := by
  intro horizon belief
  rw [process.rawValue_eq_compressedValue, process.rawValue_eq_compressedValue]
  exact process.compressedValue_eq_of_compressedDynamicInnovationEquivalent
    horizon hequivalent belief

/-- Finite-horizon value is well defined on unified DI equivalence classes. -/
noncomputable def quotientFiniteHorizonValue
    (process : Model model catalog closure) (horizon : Nat) (belief : model.Belief) :
    DynamicInnovationQuotient process → ℚ :=
  Quotient.lift
    (process.rawValue horizon belief)
    (fun _ _ hequivalent =>
      process.rawValue_eq_of_dynamicInnovationEquivalent hequivalent horizon belief)

/-- Quotient evaluation recovers raw finite-horizon value. -/
@[simp]
theorem quotientFiniteHorizonValue_mk
    (process : Model model catalog closure) (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) :
    process.quotientFiniteHorizonValue horizon belief
        (process.dynamicInnovationClass library) =
      process.rawValue horizon belief library :=
  rfl

/-- Finite-horizon raw value factors through the unified DI quotient. -/
theorem finiteHorizonValue_depends_only_on_dynamicInnovationClass
    (process : Model model catalog closure) (horizon : Nat) (belief : model.Belief) :
    ∃ valueOnClasses : DynamicInnovationQuotient process → ℚ,
      ∀ library,
        process.rawValue horizon belief library =
          valueOnClasses (process.dynamicInnovationClass library) := by
  refine ⟨process.quotientFiniteHorizonValue horizon belief, ?_⟩
  intro library
  rfl

/-- Stationary project action value expressed through the unified DI observations. -/
noncomputable def compressedInfiniteProjectActionValue
    (process : Model model catalog closure) (value : CompressedRealValue process)
    (belief : model.Belief) (state : CompressedLibraryState catalog closure)
    (project : model.ResearchProject) : ℝ :=
  -(process.researchCost belief state project : ℝ) +
    (process.expectedOperatingReward belief state project : ℝ) +
      (process.discount : ℝ) ^ process.duration project *
        BellmanContraction.realExpectedValue
          (process.projectNextStateLaw belief state project)
          (fun nextState => value nextState)

/-- The stationary signature form equals the completion-coupling expression. -/
theorem compressedInfiniteProjectActionValue_eq_completion
    (process : Model model catalog closure) (value : CompressedRealValue process)
    (belief : model.Belief) (state : CompressedLibraryState catalog closure)
    (project : model.ResearchProject) :
    process.compressedInfiniteProjectActionValue value belief state project =
      -(process.researchCost belief state project : ℝ) +
        BellmanContraction.realExpectedValue
          (process.completion project belief state)
          (fun completion =>
            (process.incumbentReward state project completion.1 : ℝ) +
              (process.discount : ℝ) ^ process.duration project *
                value (terminalBelief completion.1,
                  CompressedLibraryState.add catalog closure state completion.2)) := by
  unfold compressedInfiniteProjectActionValue expectedOperatingReward projectNextStateLaw
  rw [Projection.RatProb.realExpectedValue_map]
  rw [BellmanContraction.realExpectedValue_add,
    BellmanContraction.realExpectedValue_const_mul]
  rw [← BellmanContraction.realExpectedValue_ratExpectation
    (process.completion project belief state)
    (process.incumbentReward state project ∘ Prod.fst)]
  change
    -(process.researchCost belief state project : ℝ) +
          BellmanContraction.realExpectedValue
            (process.completion project belief state)
            (fun completion => (process.incumbentReward state project completion.1 : ℝ)) +
        (process.discount : ℝ) ^ process.duration project *
          BellmanContraction.realExpectedValue
            (process.completion project belief state)
            (fun completion =>
              value (terminalBelief completion.1,
                CompressedLibraryState.add catalog closure state completion.2)) =
      -(process.researchCost belief state project : ℝ) +
        (BellmanContraction.realExpectedValue
            (process.completion project belief state)
            (fun completion => (process.incumbentReward state project completion.1 : ℝ)) +
          (process.discount : ℝ) ^ process.duration project *
            BellmanContraction.realExpectedValue
              (process.completion project belief state)
              (fun completion =>
                value (terminalBelief completion.1,
                  CompressedLibraryState.add catalog closure state completion.2)))
  ring

/-- Available stationary project action values agree under unified DI equivalence. -/
theorem compressedInfiniteProjectActionValue_eq_of_equivalent
    (process : Model model catalog closure) (value : CompressedRealValue process)
    {left right : CompressedLibraryState catalog closure}
    (hequivalent : CompressedDynamicInnovationEquivalent process left right)
    (belief : model.Belief) (project : model.ResearchProject)
    (hleft : project ∈ process.available left) :
    process.compressedInfiniteProjectActionValue value belief left project =
      process.compressedInfiniteProjectActionValue value belief right project := by
  unfold compressedInfiniteProjectActionValue
  rw [process.researchCost_eq_of_compressedDynamicInnovationEquivalent
    hequivalent belief project hleft]
  rw [process.expectedOperatingReward_eq_of_compressedDynamicInnovationEquivalent
    hequivalent belief project hleft]
  rw [process.projectNextStateLaw_eq_of_compressedDynamicInnovationEquivalent
    hequivalent belief project hleft]

/-- A stationary real value table is constant on unified DI classes. -/
def RespectsDynamicInnovation (process : Model model catalog closure)
    (value : CompressedRealValue process) : Prop :=
  ∀ ⦃left right⦄,
    CompressedDynamicInnovationEquivalent process left right →
      ∀ belief, value (belief, left) = value (belief, right)

/-- The zero stationary table respects unified DI equivalence. -/
theorem zero_respectsDynamicInnovation (process : Model model catalog closure) :
    process.RespectsDynamicInnovation (fun _ => 0) := by
  intro left right _ belief
  rfl

/-- The unified stationary Bellman operator preserves class-constant tables. -/
theorem compressedBellmanOperator_respectsDynamicInnovation
    (process : Model model catalog closure) {value : CompressedRealValue process}
    (hvalue : process.RespectsDynamicInnovation value) :
    process.RespectsDynamicInnovation (process.compressedBellmanOperator value) := by
  intro left right hequivalent belief
  have havailable : process.available left = process.available right :=
    process.available_eq_of_compressedDynamicInnovationEquivalent hequivalent
  let toRight : InfiniteAction process left → InfiniteAction process right :=
    fun action =>
      ⟨action.1, by
        cases haction : action.1 with
        | none => trivial
        | some project =>
            have hfeasible := action.2
            rw [haction] at hfeasible
            rw [← havailable]
            exact hfeasible⟩
  let toLeft : InfiniteAction process right → InfiniteAction process left :=
    fun action =>
      ⟨action.1, by
        cases haction : action.1 with
        | none => trivial
        | some project =>
            have hfeasible := action.2
            rw [haction] at hfeasible
            rw [havailable]
            exact hfeasible⟩
  let leftActionValue : InfiniteAction process left → ℝ :=
    fun action => process.compressedInfiniteActionValue value belief left action
  let rightActionValue : InfiniteAction process right → ℝ :=
    fun action => process.compressedInfiniteActionValue value belief right action
  have hleftAction : ∀ action,
      leftActionValue action = rightActionValue (toRight action) := by
    intro action
    rcases action with ⟨action, hfeasible⟩
    cases action with
    | none =>
        dsimp [leftActionValue, rightActionValue, toRight,
          compressedInfiniteActionValue]
        rw [hequivalent.frontier belief]
        apply congrArg
          (fun continuation =>
            (right.state.frontier belief : ℝ) +
              (process.discount : ℝ) * continuation)
        apply congrArg
          (BellmanContraction.realExpectedValue
            (process.beliefTransition belief))
        funext nextBelief
        exact hvalue hequivalent nextBelief
    | some project =>
        have hmember : project ∈ process.available left := hfeasible
        dsimp [leftActionValue, rightActionValue, toRight,
          compressedInfiniteActionValue]
        rw [← process.compressedInfiniteProjectActionValue_eq_completion
          value belief left project]
        rw [← process.compressedInfiniteProjectActionValue_eq_completion
          value belief right project]
        exact process.compressedInfiniteProjectActionValue_eq_of_equivalent
          value hequivalent belief project hmember
  have hrightAction : ∀ action,
      rightActionValue action = leftActionValue (toLeft action) := by
    intro action
    rcases action with ⟨action, hfeasible⟩
    cases action with
    | none =>
        dsimp [leftActionValue, rightActionValue, toLeft,
          compressedInfiniteActionValue]
        rw [← hequivalent.frontier belief]
        apply congrArg
          (fun continuation =>
            (left.state.frontier belief : ℝ) +
              (process.discount : ℝ) * continuation)
        apply congrArg
          (BellmanContraction.realExpectedValue
            (process.beliefTransition belief))
        funext nextBelief
        exact (hvalue hequivalent nextBelief).symm
    | some project =>
        have hmember : project ∈ process.available right := hfeasible
        have hmemberLeft : project ∈ process.available left := by
          rw [havailable]
          exact hmember
        dsimp [leftActionValue, rightActionValue, toLeft,
          compressedInfiniteActionValue]
        rw [← process.compressedInfiniteProjectActionValue_eq_completion
          value belief right project]
        rw [← process.compressedInfiniteProjectActionValue_eq_completion
          value belief left project]
        exact (process.compressedInfiniteProjectActionValue_eq_of_equivalent
          value hequivalent belief project hmemberLeft).symm
  change
    Finset.univ.sup' Finset.univ_nonempty leftActionValue =
      Finset.univ.sup' Finset.univ_nonempty rightActionValue
  apply le_antisymm
  · apply Finset.sup'_le Finset.univ_nonempty
    intro action _
    rw [hleftAction action]
    exact Finset.le_sup' rightActionValue (Finset.mem_univ (toRight action))
  · apply Finset.sup'_le Finset.univ_nonempty
    intro action _
    rw [hrightAction action]
    exact Finset.le_sup' leftActionValue (Finset.mem_univ (toLeft action))

/-- Every iterate from the zero table respects unified DI equivalence. -/
theorem compressedBellmanIterate_zero_respectsDynamicInnovation
    (process : Model model catalog closure) (iteration : Nat) :
    process.RespectsDynamicInnovation
      ((process.compressedBellmanOperator^[iteration]) (fun _ => 0)) := by
  induction iteration with
  | zero =>
      simpa using process.zero_respectsDynamicInnovation
  | succ iteration inductionHypothesis =>
      rw [Function.iterate_succ_apply']
      exact process.compressedBellmanOperator_respectsDynamicInnovation
        inductionHypothesis

/-- The compressed contraction fixed point is constant on unified DI classes. -/
theorem DiscountedContractionModel.compressedFixedPoint_eq_of_equivalent
    {process : Model model catalog closure}
    (contraction : DiscountedContractionModel process)
    {left right : CompressedLibraryState catalog closure}
    (hequivalent : CompressedDynamicInnovationEquivalent process left right)
    (belief : model.Belief) :
    contraction.compressedFixedPoint (belief, left) =
      contraction.compressedFixedPoint (belief, right) := by
  let zero : CompressedRealValue process := fun _ => 0
  have hconvergence :=
    contraction.compressed_contracting.tendsto_iterate_fixedPoint zero
  have hleft := hconvergence.apply_nhds (belief, left)
  have hright := hconvergence.apply_nhds (belief, right)
  have hsequences :
      (fun iteration =>
        ((process.compressedBellmanOperator^[iteration]) zero) (belief, left)) =
      (fun iteration =>
        ((process.compressedBellmanOperator^[iteration]) zero) (belief, right)) := by
    funext iteration
    exact process.compressedBellmanIterate_zero_respectsDynamicInnovation
      iteration hequivalent belief
  rw [hsequences] at hleft
  exact tendsto_nhds_unique hleft hright

/-- Unified DI-equivalent raw libraries have equal contraction fixed-point values. -/
theorem DiscountedContractionModel.rawFixedPoint_eq_of_dynamicInnovationEquivalent
    {process : Model model catalog closure}
    (contraction : DiscountedContractionModel process)
    {left right : Raw.Library catalog}
    (hequivalent : DynamicInnovationEquivalent process left right)
    (belief : model.Belief) :
    contraction.rawFixedPoint (belief, left) =
      contraction.rawFixedPoint (belief, right) := by
  rw [contraction.raw_fixedPoint_value_eq_compressed,
    contraction.raw_fixedPoint_value_eq_compressed]
  exact contraction.compressedFixedPoint_eq_of_equivalent hequivalent belief

/--
A comparison representation preserves every displayed unified DI observation.
This is the deliberately restricted comparison class for the supporting
refinement proposition below.
-/
structure PreservesDynamicInnovationObservations
    (process : Model model catalog closure) {Representation : Type*}
    (representation : Raw.Library catalog → Representation) : Prop where
  frontier : ∀ ⦃left right⦄, representation left = representation right →
    ∀ belief,
      (CompressedLibraryState.ofLibrary catalog closure left).state.frontier belief =
        (CompressedLibraryState.ofLibrary catalog closure right).state.frontier belief
  projectCost : ∀ ⦃left right⦄, representation left = representation right →
    ∀ belief project,
      process.availableProjectData
          (CompressedLibraryState.ofLibrary catalog closure left) project
          (process.researchCost belief
            (CompressedLibraryState.ofLibrary catalog closure left) project) =
        process.availableProjectData
          (CompressedLibraryState.ofLibrary catalog closure right) project
          (process.researchCost belief
            (CompressedLibraryState.ofLibrary catalog closure right) project)
  projectDuration : ∀ ⦃left right⦄, representation left = representation right →
    ∀ project,
      process.availableProjectData
          (CompressedLibraryState.ofLibrary catalog closure left) project
          (process.duration project) =
        process.availableProjectData
          (CompressedLibraryState.ofLibrary catalog closure right) project
          (process.duration project)
  nextStateLaw : ∀ ⦃left right⦄, representation left = representation right →
    ∀ belief project,
      process.availableProjectData
          (CompressedLibraryState.ofLibrary catalog closure left) project
          (process.projectNextStateLaw belief
            (CompressedLibraryState.ofLibrary catalog closure left) project) =
        process.availableProjectData
          (CompressedLibraryState.ofLibrary catalog closure right) project
          (process.projectNextStateLaw belief
            (CompressedLibraryState.ofLibrary catalog closure right) project)
  operatingReward : ∀ ⦃left right⦄, representation left = representation right →
    ∀ belief project,
      process.availableProjectData
          (CompressedLibraryState.ofLibrary catalog closure left) project
          (process.expectedOperatingReward belief
            (CompressedLibraryState.ofLibrary catalog closure left) project) =
        process.availableProjectData
          (CompressedLibraryState.ofLibrary catalog closure right) project
          (process.expectedOperatingReward belief
            (CompressedLibraryState.ofLibrary catalog closure right) project)

/--
Restricted refinement minimality: a representation preserving all five
declared observations refines unified dynamic innovation equivalence.
-/
theorem representation_refines_dynamicInnovationEquivalent
    (process : Model model catalog closure) {Representation : Type*}
    (representation : Raw.Library catalog → Representation)
    (hpreserves : process.PreservesDynamicInnovationObservations representation)
    {left right : Raw.Library catalog}
    (hrepresentation : representation left = representation right) :
    DynamicInnovationEquivalent process left right := by
  constructor
  · exact hpreserves.frontier hrepresentation
  · exact hpreserves.projectCost hrepresentation
  · exact hpreserves.projectDuration hrepresentation
  · exact hpreserves.nextStateLaw hrepresentation
  · exact hpreserves.operatingReward hrepresentation

end Model

end Projection

end StrategyInnovation
