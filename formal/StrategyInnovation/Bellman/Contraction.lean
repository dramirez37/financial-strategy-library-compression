import Mathlib.Data.Rat.BigOperators
import Mathlib.Topology.MetricSpace.Contracting
import Mathlib.Tactic
import StrategyInnovation.Value.FiniteHorizon

/-!
# Discounted infinite-horizon Bellman contraction

This file lifts the exact rational data of `FiniteHorizon.Process` to real
value functions on the finite belief--compressed-state product.  The real
function space carries mathlib's finite-product sup norm and is complete.

The continue action has Lipschitz modulus `β`.  A research action with delay
`d` has the smaller modulus `β^(d+1)`, hence also modulus `β`.  Taking the
finite maximum over actions preserves the common bound, so Banach's theorem
gives a unique fixed point, uniform value-iteration convergence, and the
standard geometric error estimate.
-/

namespace StrategyInnovation

namespace BellmanContraction

open FiniteHorizon Filter Function Topology

universe u

/-- The finite dynamic state is belief paired with compressed library state. -/
abbrev State {model : FiniteModel} (process : Process.{u} model) :=
  model.Belief × process.CompressedState

/-- Real-valued tables on the finite state, equipped with the sup norm. -/
abbrev RealValueFunction {model : FiniteModel} (process : Process.{u} model) :=
  State process → ℝ

/-- Exact finite-support expectation after casting rational masses to reals. -/
def realExpectedValue {alpha : Type u} (distribution : RatProb alpha)
    (value : alpha → ℝ) : ℝ :=
  distribution.mass.sum fun outcome probability =>
    (probability : ℝ) * value outcome

/-- Real expectation is monotone in its integrand. -/
theorem realExpectedValue_mono {alpha : Type u}
    (distribution : RatProb alpha) {left right : alpha → ℝ}
    (hvalue : ∀ outcome, left outcome ≤ right outcome) :
    realExpectedValue distribution left ≤ realExpectedValue distribution right := by
  unfold realExpectedValue
  apply Finsupp.sum_le_sum
  intro outcome houtcome
  apply mul_le_mul_of_nonneg_left (hvalue outcome)
  exact_mod_cast distribution.nonnegative outcome

/-- The real expectation of a constant under an exact probability is itself. -/
theorem realExpectedValue_const {alpha : Type u}
    (distribution : RatProb alpha) (constant : ℝ) :
    realExpectedValue distribution (fun _ => constant) = constant := by
  classical
  unfold realExpectedValue Finsupp.sum
  rw [← Finset.sum_mul]
  have htotal :
      (∑ outcome ∈ distribution.mass.support,
        (distribution.mass outcome : ℝ)) = 1 := by
    exact_mod_cast distribution.totalMass
  rw [htotal, one_mul]

/-- Casting an exact rational expectation gives the real expectation. -/
theorem realExpectedValue_ratCast {alpha : Type u}
    (distribution : RatProb alpha) (value : alpha → ℚ) :
    realExpectedValue distribution (fun outcome => (value outcome : ℝ)) =
      (expectedValue distribution value : ℝ) := by
  classical
  unfold realExpectedValue expectedValue RatProb.expectation Finsupp.sum
  simp only [Rat.cast_sum, Rat.cast_mul]

/-- Adding a constant commutes with exact real expectation. -/
theorem realExpectedValue_add_const {alpha : Type u}
    (distribution : RatProb alpha) (value : alpha → ℝ) (constant : ℝ) :
    realExpectedValue distribution (fun outcome => value outcome + constant) =
      realExpectedValue distribution value + constant := by
  classical
  unfold realExpectedValue Finsupp.sum
  simp_rw [mul_add]
  rw [Finset.sum_add_distrib, ← Finset.sum_mul]
  have htotal :
      (∑ outcome ∈ distribution.mass.support,
        (distribution.mass outcome : ℝ)) = 1 := by
    exact_mod_cast distribution.totalMass
  rw [htotal, one_mul]

/-- Expectation is nonexpansive for a uniform pointwise distance bound. -/
theorem realExpectedValue_dist_le {alpha : Type u}
    (distribution : RatProb alpha) (left right : alpha → ℝ)
    {bound : ℝ} (_hbound : 0 ≤ bound)
    (hvalue : ∀ outcome, dist (left outcome) (right outcome) ≤ bound) :
    dist (realExpectedValue distribution left)
        (realExpectedValue distribution right) ≤ bound := by
  have hleft : ∀ outcome, left outcome ≤ right outcome + bound := by
    intro outcome
    rw [← sub_le_iff_le_add']
    exact (le_abs_self _).trans (by
      simpa [Real.dist_eq] using hvalue outcome)
  have hright : ∀ outcome, right outcome ≤ left outcome + bound := by
    intro outcome
    rw [← sub_le_iff_le_add']
    exact (le_abs_self _).trans (by
      simpa [Real.dist_eq, abs_sub_comm] using hvalue outcome)
  have hleftExpectation := realExpectedValue_mono distribution hleft
  have hrightExpectation := realExpectedValue_mono distribution hright
  rw [realExpectedValue_add_const] at hleftExpectation hrightExpectation
  rw [Real.dist_eq]
  exact abs_le.2 ⟨by linarith, by linarith⟩

/-- The process discount represented as the nonnegative Lipschitz modulus. -/
def discountNNReal {model : FiniteModel} (process : Process.{u} model) : NNReal :=
  ⟨(process.discount : ℝ), by exact_mod_cast process.discount_nonnegative⟩

@[simp]
theorem discountNNReal_coe {model : FiniteModel} (process : Process.{u} model) :
    (discountNNReal process : ℝ) = (process.discount : ℝ) :=
  rfl

/-- The real discount lies in `[0,1)`. -/
theorem discountNNReal_lt_one {model : FiniteModel}
    (process : Process.{u} model) : discountNNReal process < 1 := by
  change (process.discount : ℝ) < 1
  exact_mod_cast process.discount_lt_one

/-- Evaluating a value table at one finite state is sup-norm nonexpansive. -/
theorem value_dist_apply_le {model : FiniteModel} (process : Process.{u} model)
    (left right : RealValueFunction process) (state : State process) :
    dist (left state) (right state) ≤ dist left right := by
  exact (dist_pi_le_iff dist_nonneg).1 le_rfl state

/-- Every real value table is bounded by its finite-product sup norm. -/
theorem realValueFunction_abs_apply_le_norm {model : FiniteModel}
    (process : Process.{u} model) (value : RealValueFunction process)
    (state : State process) :
    |value state| ≤ ‖value‖ := by
  simpa only [Real.norm_eq_abs] using norm_le_pi_norm value state

/-- Boundedness is automatic for real functions on the declared finite state. -/
theorem realValueFunction_bounded {model : FiniteModel}
    (process : Process.{u} model) (value : RealValueFunction process) :
    ∃ bound : ℝ, 0 ≤ bound ∧ ∀ state, |value state| ≤ bound :=
  ⟨‖value‖, norm_nonneg _, realValueFunction_abs_apply_le_norm process value⟩

/-- Continue: collect the frontier, then evolve only the belief. -/
def continueOperator {model : FiniteModel} (process : Process.{u} model)
    (value : RealValueFunction process) : RealValueFunction process :=
  fun state =>
    (process.frontier state.2 state.1 : ℝ) +
      (process.discount : ℝ) *
        realExpectedValue (process.beliefTransition state.1)
          (fun nextBelief => value (nextBelief, state.2))

/-- Research: pay cost and evolve both belief and compressed state. -/
def researchOperator {model : FiniteModel} (process : Process.{u} model)
    (project : model.ResearchProject) (value : RealValueFunction process) :
    RealValueFunction process :=
  fun state =>
    -(process.researchCost state.1 state.2 project : ℝ) +
      (process.discount : ℝ) ^ (process.researchDelay project + 1) *
        realExpectedValue (process.beliefTransition state.1)
          (fun nextBelief =>
            realExpectedValue
              (process.researchTransition state.1 state.2 project)
              (fun nextState => value (nextBelief, nextState)))

/-- Real action-value operator, with `none` denoting continue. -/
def actionOperator {model : FiniteModel} (process : Process.{u} model)
    (action : Action model) (value : RealValueFunction process) :
    RealValueFunction process :=
  match action with
  | none => continueOperator process value
  | some project => researchOperator process project value

/-- Bellman operator: the genuine maximum over the finite action set. -/
def bellmanOperator {model : FiniteModel} (process : Process.{u} model)
    (value : RealValueFunction process) : RealValueFunction process :=
  fun state =>
    Finset.univ.sup' Finset.univ_nonempty
      (fun action : Action model => actionOperator process action value state)

/-- The belief expectation in the continue action is sup-norm nonexpansive. -/
theorem continueExpectation_dist_le {model : FiniteModel}
    (process : Process.{u} model) (left right : RealValueFunction process)
    (state : State process) :
    dist
        (realExpectedValue (process.beliefTransition state.1)
          (fun nextBelief => left (nextBelief, state.2)))
        (realExpectedValue (process.beliefTransition state.1)
          (fun nextBelief => right (nextBelief, state.2))) ≤
      dist left right := by
  apply realExpectedValue_dist_le _ _ _ dist_nonneg
  intro nextBelief
  exact value_dist_apply_le process left right (nextBelief, state.2)

/-- Nested belief/research expectation is sup-norm nonexpansive. -/
theorem researchExpectation_dist_le {model : FiniteModel}
    (process : Process.{u} model) (project : model.ResearchProject)
    (left right : RealValueFunction process) (state : State process) :
    dist
        (realExpectedValue (process.beliefTransition state.1)
          (fun nextBelief =>
            realExpectedValue
              (process.researchTransition state.1 state.2 project)
              (fun nextState => left (nextBelief, nextState))))
        (realExpectedValue (process.beliefTransition state.1)
          (fun nextBelief =>
            realExpectedValue
              (process.researchTransition state.1 state.2 project)
              (fun nextState => right (nextBelief, nextState)))) ≤
      dist left right := by
  apply realExpectedValue_dist_le _ _ _ dist_nonneg
  intro nextBelief
  apply realExpectedValue_dist_le _ _ _ dist_nonneg
  intro nextState
  exact value_dist_apply_le process left right (nextBelief, nextState)

/-- Continue action values are `β`-Lipschitz in the value table. -/
theorem continueOperator_dist_le {model : FiniteModel}
    (process : Process.{u} model) (left right : RealValueFunction process)
    (state : State process) :
    dist (continueOperator process left state)
        (continueOperator process right state) ≤
      (process.discount : ℝ) * dist left right := by
  have hdiscount : (0 : ℝ) ≤ process.discount := by
    exact_mod_cast process.discount_nonnegative
  unfold continueOperator
  rw [dist_add_left]
  calc
    _ = |(process.discount : ℝ)| *
        dist
          (realExpectedValue (process.beliefTransition state.1)
            (fun nextBelief => left (nextBelief, state.2)))
          (realExpectedValue (process.beliefTransition state.1)
            (fun nextBelief => right (nextBelief, state.2))) := by
      rw [Real.dist_eq, Real.dist_eq, ← mul_sub, abs_mul]
    _ = (process.discount : ℝ) *
        dist
          (realExpectedValue (process.beliefTransition state.1)
            (fun nextBelief => left (nextBelief, state.2)))
          (realExpectedValue (process.beliefTransition state.1)
            (fun nextBelief => right (nextBelief, state.2))) := by
      rw [abs_of_nonneg hdiscount]
    _ ≤ (process.discount : ℝ) * dist left right :=
      mul_le_mul_of_nonneg_left
        (continueExpectation_dist_le process left right state) hdiscount

/-- Every delayed research discount is bounded by the one-period discount. -/
theorem researchDiscount_le_discount {model : FiniteModel}
    (process : Process.{u} model) (project : model.ResearchProject) :
    (process.discount : ℝ) ^ (process.researchDelay project + 1) ≤
      (process.discount : ℝ) := by
  apply pow_le_of_le_one
  · exact_mod_cast process.discount_nonnegative
  · exact_mod_cast process.discount_lt_one.le
  · omega

/-- Every research action is `β`-Lipschitz in the value table. -/
theorem researchOperator_dist_le {model : FiniteModel}
    (process : Process.{u} model) (project : model.ResearchProject)
    (left right : RealValueFunction process) (state : State process) :
    dist (researchOperator process project left state)
        (researchOperator process project right state) ≤
      (process.discount : ℝ) * dist left right := by
  have hdiscount : (0 : ℝ) ≤ process.discount := by
    exact_mod_cast process.discount_nonnegative
  have hdiscountPow :
      (0 : ℝ) ≤ (process.discount : ℝ) ^
        (process.researchDelay project + 1) :=
    pow_nonneg hdiscount _
  unfold researchOperator
  rw [dist_add_left]
  calc
    _ = |(process.discount : ℝ) ^
          (process.researchDelay project + 1)| *
        dist
          (realExpectedValue (process.beliefTransition state.1)
            (fun nextBelief =>
              realExpectedValue
                (process.researchTransition state.1 state.2 project)
                (fun nextState => left (nextBelief, nextState))))
          (realExpectedValue (process.beliefTransition state.1)
            (fun nextBelief =>
              realExpectedValue
                (process.researchTransition state.1 state.2 project)
                (fun nextState => right (nextBelief, nextState)))) := by
      rw [Real.dist_eq, Real.dist_eq, ← mul_sub, abs_mul]
    _ = (process.discount : ℝ) ^ (process.researchDelay project + 1) *
        dist
          (realExpectedValue (process.beliefTransition state.1)
            (fun nextBelief =>
              realExpectedValue
                (process.researchTransition state.1 state.2 project)
                (fun nextState => left (nextBelief, nextState))))
          (realExpectedValue (process.beliefTransition state.1)
            (fun nextBelief =>
              realExpectedValue
                (process.researchTransition state.1 state.2 project)
                (fun nextState => right (nextBelief, nextState)))) := by
      rw [abs_of_nonneg hdiscountPow]
    _ ≤ (process.discount : ℝ) ^ (process.researchDelay project + 1) *
        dist left right := by
          apply mul_le_mul_of_nonneg_left
            (researchExpectation_dist_le process project left right state)
          exact hdiscountPow
    _ ≤ (process.discount : ℝ) * dist left right := by
      apply mul_le_mul_of_nonneg_right
        (researchDiscount_le_discount process project) dist_nonneg

/-- Every finite action-value operator is `β`-Lipschitz pointwise. -/
theorem actionOperator_dist_le {model : FiniteModel}
    (process : Process.{u} model) (action : Action model)
    (left right : RealValueFunction process) (state : State process) :
    dist (actionOperator process action left state)
        (actionOperator process action right state) ≤
      (process.discount : ℝ) * dist left right := by
  cases action with
  | none => exact continueOperator_dist_le process left right state
  | some project =>
      exact researchOperator_dist_le process project left right state

/-- The continue operator is globally `β`-Lipschitz in sup norm. -/
theorem continueOperator_lipschitz {model : FiniteModel}
    (process : Process.{u} model) :
    LipschitzWith (discountNNReal process) (continueOperator process) := by
  apply LipschitzWith.of_dist_le_mul
  intro left right
  rw [dist_pi_le_iff
    (mul_nonneg (discountNNReal process).coe_nonneg dist_nonneg)]
  intro state
  exact continueOperator_dist_le process left right state

/-- Each research operator is globally `β`-Lipschitz in sup norm. -/
theorem researchOperator_lipschitz {model : FiniteModel}
    (process : Process.{u} model) (project : model.ResearchProject) :
    LipschitzWith (discountNNReal process)
      (researchOperator process project) := by
  apply LipschitzWith.of_dist_le_mul
  intro left right
  rw [dist_pi_le_iff
    (mul_nonneg (discountNNReal process).coe_nonneg dist_nonneg)]
  intro state
  exact researchOperator_dist_le process project left right state

/-- Every finite action operator is globally `β`-Lipschitz in sup norm. -/
theorem actionOperator_lipschitz {model : FiniteModel}
    (process : Process.{u} model) (action : Action model) :
    LipschitzWith (discountNNReal process)
      (actionOperator process action) := by
  cases action with
  | none => exact continueOperator_lipschitz process
  | some project => exact researchOperator_lipschitz process project

/-- A finite maximum preserves a common pointwise distance bound. -/
theorem dist_finset_sup'_le {alpha : Type u} [Fintype alpha] [Nonempty alpha]
    (left right : alpha → ℝ) {bound : ℝ} (_hbound : 0 ≤ bound)
    (hvalue : ∀ action, dist (left action) (right action) ≤ bound) :
    dist (Finset.univ.sup' Finset.univ_nonempty left)
        (Finset.univ.sup' Finset.univ_nonempty right) ≤ bound := by
  have hleft :
      Finset.univ.sup' Finset.univ_nonempty left ≤
        Finset.univ.sup' Finset.univ_nonempty right + bound := by
    apply Finset.sup'_le Finset.univ_nonempty
    intro action haction
    have ha := hvalue action
    rw [Real.dist_eq] at ha
    have hsub : left action - right action ≤ bound :=
      (le_abs_self _).trans ha
    have hmaximum := Finset.le_sup' right haction
    linarith
  have hright :
      Finset.univ.sup' Finset.univ_nonempty right ≤
        Finset.univ.sup' Finset.univ_nonempty left + bound := by
    apply Finset.sup'_le Finset.univ_nonempty
    intro action haction
    have ha := hvalue action
    rw [Real.dist_eq] at ha
    have hsub : right action - left action ≤ bound := by
      exact (le_abs_self _).trans (by simpa [abs_sub_comm] using ha)
    have hmaximum := Finset.le_sup' left haction
    linarith
  rw [Real.dist_eq]
  exact abs_le.2 ⟨by linarith, by linarith⟩

/-- The Bellman operator has pointwise distance modulus `β`. -/
theorem bellmanOperator_pointwise_dist_le {model : FiniteModel}
    (process : Process.{u} model) (left right : RealValueFunction process)
    (state : State process) :
    dist (bellmanOperator process left state)
        (bellmanOperator process right state) ≤
      (process.discount : ℝ) * dist left right := by
  unfold bellmanOperator
  apply dist_finset_sup'_le _ _
    (mul_nonneg (by exact_mod_cast process.discount_nonnegative) dist_nonneg)
  intro action
  exact actionOperator_dist_le process action left right state

/-- The Bellman operator is `β`-Lipschitz in the finite-state sup norm. -/
theorem bellmanOperator_lipschitz {model : FiniteModel}
    (process : Process.{u} model) :
    LipschitzWith (discountNNReal process) (bellmanOperator process) := by
  apply LipschitzWith.of_dist_le_mul
  intro left right
  rw [dist_pi_le_iff
    (mul_nonneg (discountNNReal process).coe_nonneg dist_nonneg)]
  intro state
  exact bellmanOperator_pointwise_dist_le process left right state

/-- The discounted Bellman operator is a contraction with modulus `β`. -/
theorem bellmanOperator_contracting {model : FiniteModel}
    (process : Process.{u} model) :
    ContractingWith (discountNNReal process) (bellmanOperator process) :=
  ⟨discountNNReal_lt_one process, bellmanOperator_lipschitz process⟩

/-- The unique discounted infinite-horizon Bellman fixed point. -/
noncomputable def infiniteHorizonValue {model : FiniteModel}
    (process : Process.{u} model) : RealValueFunction process :=
  ContractingWith.fixedPoint (bellmanOperator process)
    (bellmanOperator_contracting process)

/-- The declared infinite-horizon value is a Bellman fixed point. -/
theorem infiniteHorizonValue_isFixedPoint {model : FiniteModel}
    (process : Process.{u} model) :
    IsFixedPt (bellmanOperator process) (infiniteHorizonValue process) := by
  exact (bellmanOperator_contracting process).fixedPoint_isFixedPt

/-- A discounted Bellman fixed point exists. -/
theorem exists_bellman_fixedPoint {model : FiniteModel}
    (process : Process.{u} model) :
    ∃ value : RealValueFunction process,
      IsFixedPt (bellmanOperator process) value :=
  ⟨infiniteHorizonValue process,
    infiniteHorizonValue_isFixedPoint process⟩

/-- The discounted Bellman fixed point is unique. -/
theorem bellman_fixedPoint_unique {model : FiniteModel}
    (process : Process.{u} model) {value : RealValueFunction process}
    (hvalue : IsFixedPt (bellmanOperator process) value) :
    value = infiniteHorizonValue process := by
  exact (bellmanOperator_contracting process).fixedPoint_unique hvalue

/-- Bellman value iteration from an arbitrary real initial table. -/
def valueIteration {model : FiniteModel} (process : Process.{u} model)
    (initial : RealValueFunction process) (horizon : Nat) :
    RealValueFunction process :=
  (bellmanOperator process)^[horizon] initial

/-- Value iteration converges uniformly in the finite-state sup norm. -/
theorem valueIteration_tendsto_infiniteHorizonValue
    {model : FiniteModel} (process : Process.{u} model)
    (initial : RealValueFunction process) :
    Tendsto (fun horizon => valueIteration process initial horizon) atTop
      (𝓝 (infiniteHorizonValue process)) := by
  exact (bellmanOperator_contracting process).tendsto_iterate_fixedPoint initial

/-- The Banach a priori geometric error bound for value iteration. -/
theorem valueIteration_geometric_error_bound
    {model : FiniteModel} (process : Process.{u} model)
    (initial : RealValueFunction process) (horizon : Nat) :
    dist (valueIteration process initial horizon)
        (infiniteHorizonValue process) ≤
      dist initial (bellmanOperator process initial) *
          (discountNNReal process : ℝ) ^ horizon /
        (1 - (discountNNReal process : ℝ)) := by
  exact (bellmanOperator_contracting process).apriori_dist_iterate_fixedPoint_le
    initial horizon

/-- Real finite-horizon values, initialized at zero terminal value. -/
def realFiniteHorizonValue {model : FiniteModel}
    (process : Process.{u} model) : Nat → RealValueFunction process
  | 0 => 0
  | horizon + 1 => bellmanOperator process (realFiniteHorizonValue process horizon)

/-- Real finite-horizon recursion equals Bellman iteration from zero. -/
theorem realFiniteHorizonValue_eq_valueIteration_zero
    {model : FiniteModel} (process : Process.{u} model) :
    ∀ horizon,
      realFiniteHorizonValue process horizon =
        valueIteration process 0 horizon := by
  intro horizon
  induction horizon with
  | zero => rfl
  | succ horizon inductionHypothesis =>
      change realFiniteHorizonValue process horizon =
        (bellmanOperator process)^[horizon] 0 at inductionHypothesis
      simp only [realFiniteHorizonValue, valueIteration,
        Function.iterate_succ_apply']
      rw [inductionHypothesis]

/-- Finite-horizon values converge uniformly to the fixed point. -/
theorem realFiniteHorizonValue_tendsto_infiniteHorizonValue
    {model : FiniteModel} (process : Process.{u} model) :
    Tendsto (fun horizon => realFiniteHorizonValue process horizon) atTop
      (𝓝 (infiniteHorizonValue process)) := by
  simpa only [realFiniteHorizonValue_eq_valueIteration_zero] using
    valueIteration_tendsto_infiniteHorizonValue process 0

/-- The finite-horizon geometric error bound, uniformly over all states. -/
theorem realFiniteHorizonValue_geometric_error_bound
    {model : FiniteModel} (process : Process.{u} model) (horizon : Nat) :
    dist (realFiniteHorizonValue process horizon)
        (infiniteHorizonValue process) ≤
      dist (0 : RealValueFunction process) (bellmanOperator process 0) *
          (discountNNReal process : ℝ) ^ horizon /
        (1 - (discountNNReal process : ℝ)) := by
  rw [realFiniteHorizonValue_eq_valueIteration_zero]
  exact valueIteration_geometric_error_bound process 0 horizon

/-- Pointwise cast of an exact rational continuation table to reals. -/
def rationalValueToReal {model : FiniteModel} (process : Process.{u} model)
    (value : FiniteHorizon.ValueFunction process) :
    RealValueFunction process :=
  fun state => (value state.1 state.2 : ℝ)

/-- The real continue operator is the cast of the exact rational one. -/
theorem continueOperator_ratCast {model : FiniteModel}
    (process : Process.{u} model)
    (value : FiniteHorizon.ValueFunction process) (state : State process) :
    continueOperator process (rationalValueToReal process value) state =
      (FiniteHorizon.continueValue process value state.1 state.2 : ℝ) := by
  simp only [continueOperator, rationalValueToReal,
    FiniteHorizon.continueValue, realExpectedValue_ratCast,
    Rat.cast_add, Rat.cast_mul]

/-- The real research operator is the cast of the exact rational one. -/
theorem researchOperator_ratCast {model : FiniteModel}
    (process : Process.{u} model) (project : model.ResearchProject)
    (value : FiniteHorizon.ValueFunction process) (state : State process) :
    researchOperator process project (rationalValueToReal process value) state =
      (FiniteHorizon.researchValue process value state.1 state.2 project : ℝ) := by
  simp only [researchOperator, rationalValueToReal,
    FiniteHorizon.researchValue, realExpectedValue_ratCast,
    Rat.cast_add, Rat.cast_neg, Rat.cast_mul, Rat.cast_pow]

/-- Every real action operator is the cast of its exact rational counterpart. -/
theorem actionOperator_ratCast {model : FiniteModel}
    (process : Process.{u} model) (action : Action model)
    (value : FiniteHorizon.ValueFunction process) (state : State process) :
    actionOperator process action (rationalValueToReal process value) state =
      (FiniteHorizon.actionValue process value state.1 state.2 action : ℝ) := by
  cases action with
  | none => exact continueOperator_ratCast process value state
  | some project => exact researchOperator_ratCast process project value state

/-- The real Bellman operator commutes with casting exact rational tables. -/
theorem bellmanOperator_ratCast {model : FiniteModel}
    (process : Process.{u} model)
    (value : FiniteHorizon.ValueFunction process) :
    bellmanOperator process (rationalValueToReal process value) =
      rationalValueToReal process (FiniteHorizon.bellmanStep process value) := by
  funext state
  unfold bellmanOperator rationalValueToReal FiniteHorizon.bellmanStep
  rw [Finset.apply_sup'_eq_sup'_comp Finset.univ_nonempty
    (fun rational : ℚ => (rational : ℝ))
    (fun left right => by simp only [Rat.cast_max])]
  apply congrArg
    (fun actionValues : Action model → ℝ =>
      Finset.univ.sup' Finset.univ_nonempty actionValues)
  funext action
  change
    actionOperator process action (rationalValueToReal process value) state =
      (FiniteHorizon.actionValue process value state.1 state.2 action : ℝ)
  exact actionOperator_ratCast process action value state

/-- The real recursion is exactly the cast of the rational finite-horizon value. -/
theorem realFiniteHorizonValue_eq_ratCast {model : FiniteModel}
    (process : Process.{u} model) :
    ∀ horizon,
      realFiniteHorizonValue process horizon =
        rationalValueToReal process
          (FiniteHorizon.finiteHorizonValue process horizon) := by
  intro horizon
  induction horizon with
  | zero =>
      funext state
      simp only [realFiniteHorizonValue, rationalValueToReal,
        FiniteHorizon.finiteHorizonValue, Pi.zero_apply, Rat.cast_zero]
  | succ horizon inductionHypothesis =>
      simp only [realFiniteHorizonValue, FiniteHorizon.finiteHorizonValue]
      rw [inductionHypothesis, bellmanOperator_ratCast]

/-- Cast exact finite-horizon tables converge uniformly in the sup norm. -/
theorem rationalFiniteHorizonValue_ratCast_tendsto_infiniteHorizonValue
    {model : FiniteModel} (process : Process.{u} model) :
    Tendsto
      (fun horizon =>
        rationalValueToReal process
          (FiniteHorizon.finiteHorizonValue process horizon))
      atTop (𝓝 (infiniteHorizonValue process)) := by
  simpa only [← realFiniteHorizonValue_eq_ratCast] using
    realFiniteHorizonValue_tendsto_infiniteHorizonValue process

/-- The geometric sup-norm bound applies to the cast exact horizon values. -/
theorem rationalFiniteHorizonValue_ratCast_geometric_error_bound
    {model : FiniteModel} (process : Process.{u} model) (horizon : Nat) :
    dist
        (rationalValueToReal process
          (FiniteHorizon.finiteHorizonValue process horizon))
        (infiniteHorizonValue process) ≤
      dist (0 : RealValueFunction process) (bellmanOperator process 0) *
          (discountNNReal process : ℝ) ^ horizon /
        (1 - (discountNNReal process : ℝ)) := by
  rw [← realFiniteHorizonValue_eq_ratCast]
  exact realFiniteHorizonValue_geometric_error_bound process horizon

/-- The exact rational finite-horizon values, cast to reals, converge pointwise. -/
theorem finiteHorizonValue_ratCast_tendsto_infiniteHorizonValue
    {model : FiniteModel} (process : Process.{u} model)
    (belief : model.Belief) (state : process.CompressedState) :
    Tendsto
      (fun horizon =>
        (FiniteHorizon.finiteHorizonValue process horizon belief state : ℝ))
      atTop (𝓝 (infiniteHorizonValue process (belief, state))) := by
  have hconvergence :=
    (rationalFiniteHorizonValue_ratCast_tendsto_infiniteHorizonValue
      process).apply_nhds (belief, state)
  simpa only [rationalValueToReal] using
    hconvergence

/-- Dynamic innovation equivalent states have equal infinite-horizon value. -/
theorem infiniteHorizonValue_eq_of_dynamicInnovationEquivalent
    {model : FiniteModel} (process : Process.{u} model)
    {left right : process.CompressedState}
    (hequivalent :
      FiniteHorizon.DynamicInnovationEquivalent process left right)
    (belief : model.Belief) :
    infiniteHorizonValue process (belief, left) =
      infiniteHorizonValue process (belief, right) := by
  have hleft :=
    finiteHorizonValue_ratCast_tendsto_infiniteHorizonValue
      process belief left
  have hright :=
    finiteHorizonValue_ratCast_tendsto_infiniteHorizonValue
      process belief right
  have hsequences :
      (fun horizon =>
        (FiniteHorizon.finiteHorizonValue process horizon belief left : ℝ)) =
      (fun horizon =>
        (FiniteHorizon.finiteHorizonValue process horizon belief right : ℝ)) := by
    funext horizon
    exact_mod_cast
      FiniteHorizon.finiteHorizonValue_eq_of_dynamicInnovationEquivalent
        process hequivalent horizon belief
  rw [hsequences] at hleft
  exact tendsto_nhds_unique hleft hright

end BellmanContraction

end StrategyInnovation
