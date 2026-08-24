import Mathlib.Data.Finsupp.Order
import Mathlib.Data.Fintype.Option
import Mathlib.Data.Fintype.Prod
import StrategyInnovation.Basic.Model
import StrategyInnovation.Basic.Probability

/-!
# Exact finite-horizon dynamic value

This file defines an exact finite-state decision model on an arbitrary finite
compressed-state carrier.  The action set consists of `none` (continue) and
`some project` (research).  Continue collects the current frontier and advances
the belief.  Research pays its current exact cost and advances both belief and
compressed state.

The horizon counts decision epochs.  A project's finite delay does not add a
second recursion index: it discounts the completion continuation by
`discount ^ (delay + 1)`.  Thus delay zero is ordinary one-period research.
There is no infinite series in this development.
-/

namespace StrategyInnovation

namespace FiniteHorizon

universe u v

/--
Exact finite data for a dynamic program on compressed library states.

The belief transition is common to both actions.  Conditional on the current
belief, compressed state, and project, the research-state and completion-belief
draws enter through nested expectations, hence through their exact product
law.  Research cost is nonnegative and may depend on all current observables.
-/
structure Process (base : FiniteModel) where
  CompressedState : Type u
  [stateFintype : Fintype CompressedState]
  [stateDecidableEq : DecidableEq CompressedState]
  [stateNonempty : Nonempty CompressedState]
  frontier : CompressedState → base.Belief → ℚ
  beliefTransition : base.Belief → RatProb base.Belief
  researchTransition :
    base.Belief → CompressedState → base.ResearchProject →
      RatProb CompressedState
  researchCost :
    base.Belief → CompressedState → base.ResearchProject → ℚ
  researchCost_nonnegative :
    ∀ belief state project, 0 ≤ researchCost belief state project
  researchDelay : base.ResearchProject → Nat
  discount : ℚ
  discount_nonnegative : 0 ≤ discount
  discount_lt_one : discount < 1

instance {model : FiniteModel} (process : Process model) :
    Fintype process.CompressedState :=
  process.stateFintype

instance {model : FiniteModel} (process : Process model) :
    DecidableEq process.CompressedState :=
  process.stateDecidableEq

instance {model : FiniteModel} (process : Process model) :
    Nonempty process.CompressedState :=
  process.stateNonempty

/-- Exact expectation of a rational value under a finite exact distribution. -/
def expectedValue {α : Type v} (distribution : RatProb α)
    (value : α → ℚ) : ℚ :=
  distribution.expectation value

/--
Expectation is extensional in both the exact distribution and its value
function.
-/
theorem expectedValue_extensionality {α : Type v}
    {leftDistribution rightDistribution : RatProb α}
    {leftValue rightValue : α → ℚ}
    (hdistribution : leftDistribution = rightDistribution)
    (hvalue : ∀ outcome, leftValue outcome = rightValue outcome) :
    expectedValue leftDistribution leftValue =
      expectedValue rightDistribution rightValue := by
  cases hdistribution
  exact RatProb.expectation_congr _ hvalue

/-- Pointwise larger values have weakly larger exact expectation. -/
theorem expectedValue_mono {α : Type v} (distribution : RatProb α)
    {left right : α → ℚ} (hvalue : ∀ outcome, left outcome ≤ right outcome) :
    expectedValue distribution left ≤ expectedValue distribution right := by
  unfold expectedValue RatProb.expectation
  apply Finsupp.sum_le_sum
  intro outcome _
  exact mul_le_mul_of_nonneg_left
    (hvalue outcome) (distribution.nonnegative outcome)

/-- A rational continuation-value table on belief and compressed state. -/
abbrev ValueFunction {model : FiniteModel} (process : Process model) :=
  model.Belief → process.CompressedState → ℚ

/-- Pointwise order on continuation-value tables. -/
def ValueFunctionLE {model : FiniteModel} {process : Process model}
    (left right : ValueFunction process) : Prop :=
  ∀ belief state, left belief state ≤ right belief state

/-- Continuing collects the current frontier and advances only the belief. -/
def continueValue {model : FiniteModel} (process : Process model)
    (continuation : ValueFunction process) (belief : model.Belief)
    (state : process.CompressedState) : ℚ :=
  process.frontier state belief +
    process.discount *
      expectedValue (process.beliefTransition belief) fun nextBelief =>
        continuation nextBelief state

/--
Research pays current cost and advances belief and compressed state.

The completion continuation is discounted by one ordinary transition plus the
declared nonnegative integer delay.
-/
def researchValue {model : FiniteModel} (process : Process model)
    (continuation : ValueFunction process) (belief : model.Belief)
    (state : process.CompressedState) (project : model.ResearchProject) : ℚ :=
  -process.researchCost belief state project +
    process.discount ^ (process.researchDelay project + 1) *
      expectedValue (process.beliefTransition belief) fun nextBelief =>
        expectedValue (process.researchTransition belief state project)
          fun nextState => continuation nextBelief nextState

/-- `none` is continue; `some project` is the corresponding research action. -/
abbrev Action (model : FiniteModel) :=
  Option model.ResearchProject

/-- Exact value of one available action against a continuation table. -/
def actionValue {model : FiniteModel} (process : Process model)
    (continuation : ValueFunction process) (belief : model.Belief)
    (state : process.CompressedState) : Action model → ℚ
  | none => continueValue process continuation belief state
  | some project => researchValue process continuation belief state project

/-- The Bellman operator is the genuine maximum over the finite action set. -/
def bellmanStep {model : FiniteModel} (process : Process model)
    (continuation : ValueFunction process) : ValueFunction process :=
  fun belief state =>
    Finset.univ.sup' Finset.univ_nonempty
      (actionValue process continuation belief state)

/-- The continue action is monotone in its continuation table. -/
theorem continueValue_mono {model : FiniteModel} (process : Process model)
    {left right : ValueFunction process} (hvalue : ValueFunctionLE left right)
    (belief : model.Belief) (state : process.CompressedState) :
    continueValue process left belief state ≤
      continueValue process right belief state := by
  unfold continueValue
  apply add_le_add_right
  apply mul_le_mul_of_nonneg_left
  · apply expectedValue_mono
    intro nextBelief
    exact hvalue nextBelief state
  · exact process.discount_nonnegative

/-- Every research action is monotone in its continuation table. -/
theorem researchValue_mono {model : FiniteModel} (process : Process model)
    {left right : ValueFunction process} (hvalue : ValueFunctionLE left right)
    (belief : model.Belief) (state : process.CompressedState)
    (project : model.ResearchProject) :
    researchValue process left belief state project ≤
      researchValue process right belief state project := by
  unfold researchValue
  apply add_le_add_right
  apply mul_le_mul_of_nonneg_left
  · apply expectedValue_mono
    intro nextBelief
    apply expectedValue_mono
    intro nextState
    exact hvalue nextBelief nextState
  · exact pow_nonneg process.discount_nonnegative _

/-- Every finite action value is monotone in its continuation table. -/
theorem actionValue_mono {model : FiniteModel} (process : Process model)
    {left right : ValueFunction process} (hvalue : ValueFunctionLE left right)
    (belief : model.Belief) (state : process.CompressedState)
    (action : Action model) :
    actionValue process left belief state action ≤
      actionValue process right belief state action := by
  cases action with
  | none => exact continueValue_mono process hvalue belief state
  | some project => exact researchValue_mono process hvalue belief state project

/-- The exact finite-action Bellman operator is pointwise monotone. -/
theorem bellmanStep_mono {model : FiniteModel} (process : Process model)
    {left right : ValueFunction process} (hvalue : ValueFunctionLE left right) :
    ValueFunctionLE (bellmanStep process left) (bellmanStep process right) := by
  intro belief state
  apply Finset.sup'_le Finset.univ_nonempty
  intro action haction
  exact (actionValue_mono process hvalue belief state action).trans
    (Finset.le_sup'
      (actionValue process right belief state) haction)

/-- Exact finite-horizon value, with zero terminal value. -/
def finiteHorizonValue {model : FiniteModel} (process : Process model) :
    Nat → ValueFunction process
  | 0 => fun _ _ => 0
  | horizon + 1 => bellmanStep process (finiteHorizonValue process horizon)

/--
Cost-sensitive dynamic innovation equivalence on compressed states.

Two states have the same current frontier, every current research cost, and
every induced exact next-compressed-state distribution.  Cost equality is
necessary for value preservation because research has an action-specific
current payoff.
-/
def DynamicInnovationEquivalent {model : FiniteModel} (process : Process model)
    (left right : process.CompressedState) : Prop :=
  (∀ belief, process.frontier left belief = process.frontier right belief) ∧
  (∀ belief project,
    process.researchCost belief left project =
      process.researchCost belief right project) ∧
  (∀ belief project,
    process.researchTransition belief left project =
      process.researchTransition belief right project)

/-- A continuation table respects dynamic innovation equivalence. -/
def RespectsDynamicInnovation {model : FiniteModel} (process : Process model)
    (value : ValueFunction process) : Prop :=
  ∀ {left right},
    DynamicInnovationEquivalent process left right →
      ∀ belief, value belief left = value belief right

/-- Continue values agree at dynamically innovation-equivalent states. -/
theorem continueValue_eq_of_dynamicInnovationEquivalent
    {model : FiniteModel} (process : Process model)
    {continuation : ValueFunction process}
    (hcontinuation : RespectsDynamicInnovation process continuation)
    {left right : process.CompressedState}
    (hequivalent : DynamicInnovationEquivalent process left right)
    (belief : model.Belief) :
    continueValue process continuation belief left =
      continueValue process continuation belief right := by
  unfold continueValue
  rw [hequivalent.1 belief]
  apply congrArg
    (fun continuationValue =>
      process.frontier right belief +
        process.discount * continuationValue)
  apply expectedValue_extensionality rfl
  intro nextBelief
  exact hcontinuation hequivalent nextBelief

/-- Research values agree at dynamically innovation-equivalent states. -/
theorem researchValue_eq_of_dynamicInnovationEquivalent
    {model : FiniteModel} (process : Process model)
    (continuation : ValueFunction process)
    {left right : process.CompressedState}
    (hequivalent : DynamicInnovationEquivalent process left right)
    (belief : model.Belief) (project : model.ResearchProject) :
    researchValue process continuation belief left project =
      researchValue process continuation belief right project := by
  unfold researchValue
  rw [hequivalent.2.1 belief project, hequivalent.2.2 belief project]

/-- One Bellman step preserves dynamic innovation equivalence. -/
theorem bellmanStep_respectsDynamicInnovation
    {model : FiniteModel} (process : Process model)
    {continuation : ValueFunction process}
    (hcontinuation : RespectsDynamicInnovation process continuation) :
    RespectsDynamicInnovation process (bellmanStep process continuation) := by
  intro left right hequivalent belief
  unfold bellmanStep
  apply congrArg
    (fun value : Action model → ℚ =>
      Finset.univ.sup' Finset.univ_nonempty value)
  funext action
  cases action with
  | none =>
      exact continueValue_eq_of_dynamicInnovationEquivalent
        process hcontinuation hequivalent belief
  | some project =>
      exact researchValue_eq_of_dynamicInnovationEquivalent
        process continuation hequivalent belief project

/-- Every finite-horizon value respects dynamic innovation equivalence. -/
theorem finiteHorizonValue_respectsDynamicInnovation
    {model : FiniteModel} (process : Process model) (horizon : Nat) :
    RespectsDynamicInnovation process
      (finiteHorizonValue process horizon) := by
  induction horizon with
  | zero =>
      intro left right _ belief
      rfl
  | succ horizon inductionHypothesis =>
      exact bellmanStep_respectsDynamicInnovation
        process inductionHypothesis

/--
Dynamically innovation-equivalent compressed states have equal value at every
finite horizon and belief.
-/
theorem finiteHorizonValue_eq_of_dynamicInnovationEquivalent
    {model : FiniteModel} (process : Process model)
    {left right : process.CompressedState}
    (hequivalent : DynamicInnovationEquivalent process left right) :
    ∀ horizon belief,
      finiteHorizonValue process horizon belief left =
        finiteHorizonValue process horizon belief right := by
  intro horizon belief
  exact finiteHorizonValue_respectsDynamicInnovation
    process horizon hequivalent belief

/-- A finite exact upper bound on absolute horizon value over all finite states. -/
def finiteHorizonValueBound {model : FiniteModel} (process : Process model)
    (horizon : Nat) : ℚ :=
  max 0 <|
    Finset.univ.sup' Finset.univ_nonempty
      (fun state : model.Belief × process.CompressedState =>
        |finiteHorizonValue process horizon state.1 state.2|)

/-- Every finite-horizon value is bounded by the declared finite maximum. -/
theorem abs_finiteHorizonValue_le_bound
    {model : FiniteModel} (process : Process model)
    (horizon : Nat) (belief : model.Belief)
    (state : process.CompressedState) :
    |finiteHorizonValue process horizon belief state| ≤
      finiteHorizonValueBound process horizon := by
  apply le_trans
    (Finset.le_sup'
      (fun state : model.Belief × process.CompressedState =>
        |finiteHorizonValue process horizon state.1 state.2|)
      (Finset.mem_univ (belief, state)))
  exact le_max_right _ _

/-- Finite-horizon values have a nonnegative uniform finite-state bound. -/
theorem finiteHorizonValue_bounded
    {model : FiniteModel} (process : Process model) (horizon : Nat) :
    ∃ bound : ℚ, 0 ≤ bound ∧
      ∀ belief state,
        |finiteHorizonValue process horizon belief state| ≤ bound := by
  refine ⟨finiteHorizonValueBound process horizon, ?_, ?_⟩
  · unfold finiteHorizonValueBound
    exact le_max_left _ _
  exact abs_finiteHorizonValue_le_bound process horizon

/-- Evaluate compressed finite-horizon value after an arbitrary raw encoding. -/
def rawFiniteHorizonValue {model : FiniteModel} (process : Process model)
    {RawState : Type v} (compress : RawState → process.CompressedState)
    (horizon : Nat) (belief : model.Belief) (raw : RawState) : ℚ :=
  finiteHorizonValue process horizon belief (compress raw)

/--
Raw inputs with the same compressed state have the same finite-horizon value.
-/
theorem rawFiniteHorizonValue_eq_of_compressedState_eq
    {model : FiniteModel} (process : Process model)
    {RawState : Type v} (compress : RawState → process.CompressedState)
    (horizon : Nat) (belief : model.Belief) {left right : RawState}
    (hstate : compress left = compress right) :
    rawFiniteHorizonValue process compress horizon belief left =
      rawFiniteHorizonValue process compress horizon belief right := by
  unfold rawFiniteHorizonValue
  rw [hstate]

/-- The raw evaluation map factors explicitly through compressed state. -/
theorem finiteHorizonValue_factors_through_compressedState
    {model : FiniteModel} (process : Process model)
    {RawState : Type v} (compress : RawState → process.CompressedState)
    (horizon : Nat) :
    ∃ compressedValue : ValueFunction process,
      ∀ belief raw,
        rawFiniteHorizonValue process compress horizon belief raw =
          compressedValue belief (compress raw) := by
  exact ⟨finiteHorizonValue process horizon, fun _ _ => rfl⟩

/-- A maximizing action exists for every Bellman step. -/
theorem exists_optimalAction {model : FiniteModel} (process : Process model)
    (continuation : ValueFunction process) (belief : model.Belief)
    (state : process.CompressedState) :
    ∃ action : Action model,
      actionValue process continuation belief state action =
        bellmanStep process continuation belief state := by
  obtain ⟨action, _, haction⟩ :=
    Finset.exists_mem_eq_sup' Finset.univ_nonempty
      (actionValue process continuation belief state)
  exact ⟨action, haction.symm⟩

/-- An optimal action exists at every finite horizon, belief, and state. -/
theorem finiteHorizon_optimalAction_exists
    {model : FiniteModel} (process : Process model)
    (horizon : Nat) (belief : model.Belief)
    (state : process.CompressedState) :
    ∃ action : Action model,
      actionValue process (finiteHorizonValue process horizon)
          belief state action =
        finiteHorizonValue process (horizon + 1) belief state := by
  exact exists_optimalAction process
    (finiteHorizonValue process horizon) belief state

end FiniteHorizon

end StrategyInnovation
