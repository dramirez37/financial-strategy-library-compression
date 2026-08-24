import Mathlib.Tactic
import StrategyInnovation.Value.Decomposition

/-!
# Exact finite-horizon Strategy Innovation Equation

This file identifies the passive operational value of one strategy insertion
with the exact discounted expected sum of its positive frontier gaps along the
finite belief Markov chain.  The result is finite-horizon and uses only exact
rational arithmetic.

The final monotonicity theorem is operational: a larger initial library has a
weakly higher frontier and therefore gives the same candidate weakly smaller
discounted gap value.  No infinite series is used here.
-/

namespace StrategyInnovation

namespace InnovationEquation

open FiniteHorizon ValueDecomposition

universe u

/-- The candidate's exact positive payoff gap over the current frontier. -/
def frontierGap {model : FiniteModel} (catalog : StrategyCatalog model)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId) (belief : model.Belief) : ℚ :=
  max (catalog.operationalProfile strategy belief -
    operationalFrontier catalog library belief) 0

/-- Frontier gaps are pointwise nonnegative. -/
theorem frontierGap_nonnegative {model : FiniteModel}
    (catalog : StrategyCatalog model)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId) (belief : model.Belief) :
    0 ≤ frontierGap catalog library strategy belief := by
  exact le_max_right _ _

/-- Inserting one candidate takes the pointwise maximum with its profile. -/
theorem operationalFrontier_insert_eq_max {model : FiniteModel}
    (catalog : StrategyCatalog model)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId) (belief : model.Belief) :
    operationalFrontier catalog (library.insert strategy) belief =
      max (catalog.operationalProfile strategy belief)
        (operationalFrontier catalog library belief) := by
  apply le_antisymm
  · apply (operationalFrontier_le_iff catalog
      (library.insert strategy) belief _).2
    intro candidate hcandidate
    rcases Library.mem_insert.mp hcandidate with rfl | hmember
    · exact le_max_left _ _
    · exact (operationalProfile_le_frontier catalog library hmember belief).trans
        (le_max_right _ _)
  · apply max_le
    · exact operationalProfile_le_frontier catalog
        (library.insert strategy) (Library.mem_insert.mpr (Or.inl rfl)) belief
    · exact operationalFrontier_mono catalog
        (Library.le_insert library strategy) belief

/--
One-step frontier identity: the payoff increment from insertion is exactly the
positive frontier gap.
-/
theorem operationalFrontier_insert_sub_eq_frontierGap
    {model : FiniteModel} (catalog : StrategyCatalog model)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId) (belief : model.Belief) :
    operationalFrontier catalog (library.insert strategy) belief -
        operationalFrontier catalog library belief =
      frontierGap catalog library strategy belief := by
  rw [operationalFrontier_insert_eq_max]
  unfold frontierGap
  rcases le_total
      (catalog.operationalProfile strategy belief)
      (operationalFrontier catalog library belief) with hdominated | himproves
  · rw [max_eq_right hdominated]
    rw [max_eq_right]
    · ring
    · exact sub_nonpos.mpr hdominated
  · rw [max_eq_left himproves]
    rw [max_eq_left]
    exact sub_nonneg.mpr himproves

/-- Exact expectation commutes with subtraction. -/
theorem expectedValue_sub {alpha : Type u} (distribution : RatProb alpha)
    (left right : alpha → ℚ) :
    expectedValue distribution (fun outcome => left outcome - right outcome) =
      expectedValue distribution left - expectedValue distribution right := by
  classical
  unfold expectedValue RatProb.expectation Finsupp.sum
  rw [← Finset.sum_sub_distrib]
  apply Finset.sum_congr rfl
  intro outcome houtcome
  ring

/--
The exact finite discounted Markov-reward sum.  At horizon `n + 1`, it records
the current gap and then the discounted expectation of the remaining `n`
gaps.  This is the recursive form of
`E_b[∑_{t=0}^{n-1} discount^t gap(B_t)]`.
-/
def discountedGapSum {alpha : Type u}
    (transition : alpha → RatProb alpha) (discount : ℚ)
    (gap : alpha → ℚ) : Nat → alpha → ℚ
  | 0, _ => 0
  | horizon + 1, state =>
      gap state + discount *
        expectedValue (transition state) fun nextState =>
          discountedGapSum transition discount gap horizon nextState

/-- The finite discounted gap sum has its defining one-step recursion. -/
theorem discountedGapSum_succ {alpha : Type u}
    (transition : alpha → RatProb alpha) (discount : ℚ)
    (gap : alpha → ℚ) (horizon : Nat) (state : alpha) :
    discountedGapSum transition discount gap (horizon + 1) state =
      gap state + discount *
        expectedValue (transition state) fun nextState =>
          discountedGapSum transition discount gap horizon nextState := by
  rfl

/--
Passive operational innovation is the no-future-research value difference
caused by inserting one candidate.
-/
def passiveOperationalInnovation
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog) (horizon : Nat)
    (belief : model.Belief)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId) : ℚ :=
  passiveValue dynamics horizon belief (library.insert strategy) -
    passiveValue dynamics horizon belief library

/-- The equation-specific name agrees with F6 operational innovation. -/
theorem passiveOperationalInnovation_eq_operationalInnovation
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog) (horizon : Nat)
    (belief : model.Belief)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId) :
    passiveOperationalInnovation dynamics horizon belief library strategy =
      operationalInnovation dynamics horizon belief library strategy := by
  rfl

/-- The frozen-library passive value has the exact finite-horizon recursion. -/
theorem passiveValue_succ
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog) (horizon : Nat)
    (belief : model.Belief)
    (library : Library model catalog.inactiveStrategy) :
    passiveValue dynamics (horizon + 1) belief library =
      operationalFrontier catalog library belief +
        dynamics.process.discount *
          expectedValue (dynamics.process.beliefTransition belief)
            (fun nextBelief =>
              passiveValue dynamics horizon nextBelief library) := by
  rfl

/-- Passive operational innovation obeys the frontier-gap recursion. -/
theorem passiveOperationalInnovation_succ
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog) (horizon : Nat)
    (belief : model.Belief)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId) :
    passiveOperationalInnovation dynamics (horizon + 1) belief library strategy =
      frontierGap catalog library strategy belief +
        dynamics.process.discount *
          expectedValue (dynamics.process.beliefTransition belief)
            (fun nextBelief =>
              passiveOperationalInnovation dynamics horizon nextBelief
                library strategy) := by
  unfold passiveOperationalInnovation
  simp only [passiveValue]
  calc
    (operationalFrontier catalog (library.insert strategy) belief +
          dynamics.process.discount *
            expectedValue (dynamics.process.beliefTransition belief)
              (fun nextBelief =>
                passiveValue dynamics horizon nextBelief
                  (library.insert strategy))) -
        (operationalFrontier catalog library belief +
          dynamics.process.discount *
            expectedValue (dynamics.process.beliefTransition belief)
              (fun nextBelief =>
                passiveValue dynamics horizon nextBelief library)) =
      (operationalFrontier catalog (library.insert strategy) belief -
          operationalFrontier catalog library belief) +
        dynamics.process.discount *
          (expectedValue (dynamics.process.beliefTransition belief)
              (fun nextBelief =>
                passiveValue dynamics horizon nextBelief
                  (library.insert strategy)) -
            expectedValue (dynamics.process.beliefTransition belief)
              (fun nextBelief =>
                passiveValue dynamics horizon nextBelief library)) := by ring
    _ = frontierGap catalog library strategy belief +
        dynamics.process.discount *
          expectedValue (dynamics.process.beliefTransition belief)
            (fun nextBelief =>
              passiveValue dynamics horizon nextBelief
                  (library.insert strategy) -
                passiveValue dynamics horizon nextBelief library) := by
      rw [operationalFrontier_insert_sub_eq_frontierGap,
        expectedValue_sub]
    _ = frontierGap catalog library strategy belief +
        dynamics.process.discount *
          expectedValue (dynamics.process.beliefTransition belief)
            (fun nextBelief =>
              passiveOperationalInnovation dynamics horizon nextBelief
                library strategy) := by
      rfl

/--
Finite-horizon Strategy Innovation Equation: passive operational innovation is
the exact expected discounted sum of future positive frontier gaps.
-/
theorem passiveOperationalInnovation_eq_discountedGapSum
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog) :
    ∀ horizon belief library strategy,
      passiveOperationalInnovation dynamics horizon belief library strategy =
        discountedGapSum dynamics.process.beliefTransition
          dynamics.process.discount (frontierGap catalog library strategy)
          horizon belief := by
  intro horizon
  induction horizon with
  | zero =>
      intro belief library strategy
      simp [passiveOperationalInnovation, passiveValue, discountedGapSum]
  | succ horizon inductionHypothesis =>
      intro belief library strategy
      rw [passiveOperationalInnovation_succ]
      simp only [discountedGapSum]
      apply congrArg
        (fun continuation =>
          frontierGap catalog library strategy belief +
            dynamics.process.discount * continuation)
      apply expectedValue_extensionality rfl
      intro nextBelief
      exact inductionHypothesis nextBelief library strategy

/-- Exact positive-mass reachability in a finite belief Markov chain. -/
inductive BeliefReachableIn {alpha : Type u}
    (transition : alpha → RatProb alpha) : Nat → alpha → alpha → Prop
  | refl (state : alpha) : BeliefReachableIn transition 0 state state
  | step {horizon : Nat} {start current nextState : alpha} :
      BeliefReachableIn transition horizon start current →
      (transition current).probability nextState ≠ 0 →
      BeliefReachableIn transition (horizon + 1) start nextState

/-- Exact-step reachability composes by addition of horizons. -/
theorem BeliefReachableIn.trans {alpha : Type u}
    {transition : alpha → RatProb alpha}
    {first second third : alpha} {leftHorizon rightHorizon : Nat}
    (hleft : BeliefReachableIn transition leftHorizon first second)
    (hright : BeliefReachableIn transition rightHorizon second third) :
    BeliefReachableIn transition (leftHorizon + rightHorizon) first third := by
  induction hright with
  | refl =>
      simpa using hleft
  | @step horizon start current nextState hpath hprob inductionHypothesis =>
      simpa [Nat.add_assoc] using
        BeliefReachableIn.step (inductionHypothesis hleft) hprob

/-- A supported one-step transition is a one-period reachable state. -/
theorem beliefReachableIn_one {alpha : Type u}
    {transition : alpha → RatProb alpha} {start nextState : alpha}
    (hprobability : (transition start).probability nextState ≠ 0) :
    BeliefReachableIn transition 1 start nextState := by
  simpa using BeliefReachableIn.step
    (BeliefReachableIn.refl (transition := transition) start) hprobability

/-- An expectation is zero when its integrand vanishes on exact support. -/
theorem expectedValue_eq_zero_of_probability_ne_zero
    {alpha : Type u} (distribution : RatProb alpha) (value : alpha → ℚ)
    (hzero : ∀ outcome, distribution.probability outcome ≠ 0 →
      value outcome = 0) :
    expectedValue distribution value = 0 := by
  classical
  unfold expectedValue RatProb.expectation Finsupp.sum
  apply Finset.sum_eq_zero
  intro outcome houtcome
  simp only [hzero outcome (Finsupp.mem_support_iff.mp houtcome), mul_zero]

/--
If the gap vanishes at every positive-probability state reachable before the
terminal horizon, then its exact discounted finite sum is zero.
-/
theorem discountedGapSum_eq_zero_of_gap_eq_zero_on_reachable
    {alpha : Type u} (transition : alpha → RatProb alpha)
    (discount : ℚ) (gap : alpha → ℚ) :
    ∀ horizon start,
      (∀ time, time < horizon → ∀ state,
        BeliefReachableIn transition time start state → gap state = 0) →
      discountedGapSum transition discount gap horizon start = 0 := by
  intro horizon
  induction horizon with
  | zero =>
      intro start hgap
      rfl
  | succ horizon inductionHypothesis =>
      intro start hgap
      simp only [discountedGapSum]
      rw [hgap 0 (Nat.zero_lt_succ horizon) start
        (BeliefReachableIn.refl (transition := transition) start)]
      simp only [zero_add]
      apply mul_eq_zero_of_right
      apply expectedValue_eq_zero_of_probability_ne_zero
      intro nextState hprobability
      apply inductionHypothesis nextState
      intro time htime state hreachable
      apply hgap (time + 1)
      · omega
      · have hprefix : BeliefReachableIn transition 1 start nextState :=
          beliefReachableIn_one hprobability
        have hcomposed := BeliefReachableIn.trans hprefix hreachable
        simpa [Nat.add_comm] using hcomposed

/--
Zero-gap criterion for passive operational innovation on every belief state
reachable before the finite horizon.
-/
theorem passiveOperationalInnovation_eq_zero_of_gap_eq_zero_on_reachable
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog) (horizon : Nat)
    (belief : model.Belief)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hgap : ∀ time, time < horizon → ∀ nextBelief,
      BeliefReachableIn dynamics.process.beliefTransition time belief
          nextBelief →
        frontierGap catalog library strategy nextBelief = 0) :
    passiveOperationalInnovation dynamics horizon belief library strategy = 0 := by
  rw [passiveOperationalInnovation_eq_discountedGapSum]
  exact discountedGapSum_eq_zero_of_gap_eq_zero_on_reachable
    dynamics.process.beliefTransition dynamics.process.discount
      (frontierGap catalog library strategy) horizon belief hgap

/-- Enlarging a library weakly lowers every candidate frontier gap. -/
theorem frontierGap_antitone_of_library_inclusion
    {model : FiniteModel} (catalog : StrategyCatalog model)
    {left right : Library model catalog.inactiveStrategy}
    (hinclude : left ≤ right) (strategy : model.StrategyId)
    (belief : model.Belief) :
    frontierGap catalog right strategy belief ≤
      frontierGap catalog left strategy belief := by
  unfold frontierGap
  apply max_le_max_right
  exact sub_le_sub_left (operationalFrontier_mono catalog hinclude belief) _

/-- Discounted gap sums are monotone in a pointwise larger gap table. -/
theorem discountedGapSum_mono {alpha : Type u}
    (transition : alpha → RatProb alpha) {discount : ℚ}
    (hdiscount : 0 ≤ discount) {left right : alpha → ℚ}
    (hgap : ∀ state, left state ≤ right state) :
    ∀ horizon state,
      discountedGapSum transition discount left horizon state ≤
        discountedGapSum transition discount right horizon state := by
  intro horizon
  induction horizon with
  | zero =>
      intro state
      exact le_rfl
  | succ horizon inductionHypothesis =>
      intro state
      simp only [discountedGapSum]
      apply add_le_add
      · exact hgap state
      · apply mul_le_mul_of_nonneg_left
        · apply expectedValue_mono
          intro nextState
          exact inductionHypothesis nextState
        · exact hdiscount

/--
Diminishing marginal passive operational innovation: the same candidate has a
weakly smaller discounted frontier-gap value against a larger library.
-/
theorem passiveOperationalInnovation_antitone_of_library_inclusion
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog)
    {left right : Library model catalog.inactiveStrategy}
    (hinclude : left ≤ right) (horizon : Nat) (belief : model.Belief)
    (strategy : model.StrategyId) :
    passiveOperationalInnovation dynamics horizon belief right strategy ≤
      passiveOperationalInnovation dynamics horizon belief left strategy := by
  rw [passiveOperationalInnovation_eq_discountedGapSum,
    passiveOperationalInnovation_eq_discountedGapSum]
  apply discountedGapSum_mono dynamics.process.beliefTransition
    dynamics.process.discount_nonnegative
  intro nextBelief
  exact frontierGap_antitone_of_library_inclusion catalog hinclude
    strategy nextBelief

namespace DelayedBenefitExample

inductive Belief
  | current
  | future
  deriving DecidableEq, Fintype

instance : Nonempty Belief := ⟨Belief.current⟩

inductive Strategy
  | inactive
  | candidate
  deriving DecidableEq, Fintype

instance : Nonempty Strategy := ⟨Strategy.inactive⟩

inductive Module
  | token
  deriving DecidableEq, Fintype

instance : Nonempty Module := ⟨Module.token⟩

inductive Project
  | dummy
  deriving DecidableEq, Fintype

instance : Nonempty Project := ⟨Project.dummy⟩

/-- Two beliefs and one candidate suffice for delayed operational value. -/
abbrev model : FiniteModel where
  Belief := Belief
  StrategyId := Strategy
  ModuleId := Module
  ResearchProject := Project

/-- The candidate ties now and pays two at the reachable future belief. -/
def profile : Strategy → Belief → ℚ
  | .inactive, _ => 0
  | .candidate, .current => 0
  | .candidate, .future => 2

/-- Modules are irrelevant to this purely operational example. -/
def modules : Strategy → Finset Module := fun _ => ∅

/-- Exact catalog for the delayed-benefit example. -/
abbrev catalog : StrategyCatalog model where
  operationalProfile := profile
  strategyModules := modules
  inactiveStrategy := Strategy.inactive
  inactiveProfile := by intro belief; cases belief <;> rfl
  inactiveModules := rfl

/-- The current library contains only the inactive strategy. -/
def library : Library model catalog.inactiveStrategy where
  strategies := {Strategy.inactive}
  inactive_mem := by simp

/-- Current belief moves deterministically to the future belief. -/
def nextBelief : Belief → Belief
  | .current => .future
  | .future => .future

/-- Exact finite process; research fields are inert in the passive theorem. -/
noncomputable def process : FiniteHorizon.Process model where
  CompressedState := Library model catalog.inactiveStrategy
  stateFintype := inferInstance
  stateDecidableEq := Classical.decEq _
  stateNonempty := ⟨library⟩
  frontier := operationalFrontier catalog
  beliefTransition := fun belief => RatProb.dirac (nextBelief belief)
  researchTransition := fun _ state _ => RatProb.dirac state
  researchCost := fun _ _ _ => 0
  researchCost_nonnegative := by intros; exact le_rfl
  researchDelay := fun _ => 0
  discount := 1 / 2
  discount_nonnegative := by norm_num
  discount_lt_one := by norm_num

/-- Raw libraries are the compressed states in the delayed-benefit example. -/
noncomputable def dynamics : LibraryDynamics model catalog where
  process := process
  compress := id
  frontier_eq := fun _ _ => rfl

/-- The inactive-only frontier is zero at both beliefs. -/
theorem library_frontier_eq_zero :
    operationalFrontier catalog library = fun _ => 0 := by
  funext belief
  apply le_antisymm
  · apply (operationalFrontier_le_iff catalog library belief 0).2
    intro strategy hstrategy
    change strategy ∈ ({Strategy.inactive} : Finset Strategy) at hstrategy
    simp only [Finset.mem_singleton] at hstrategy
    subst strategy
    rfl
  · exact zero_le_operationalFrontier catalog library belief

/-- The candidate has zero current frontier gap. -/
theorem current_frontierGap_eq_zero :
    frontierGap catalog library Strategy.candidate Belief.current = 0 := by
  simp [frontierGap, profile, library_frontier_eq_zero]

/-- The deterministic next belief exposes a strictly positive frontier gap. -/
theorem future_frontierGap_eq_two :
    frontierGap catalog library Strategy.candidate Belief.future = 2 := by
  simp [frontierGap, profile, library_frontier_eq_zero]

/-- The future belief is reached in exactly one positive-probability step. -/
theorem future_reachable_in_one :
    BeliefReachableIn process.beliefTransition 1
      Belief.current Belief.future := by
  apply beliefReachableIn_one
  simp [process, nextBelief, RatProb.probability, RatProb.dirac]

/--
Current nondominance is unnecessary: the current gap is zero, the reachable
next gap is two, and horizon-two passive operational innovation is one.
-/
theorem zero_currentGap_positive_passiveOperationalInnovation :
    frontierGap catalog library Strategy.candidate Belief.current = 0 ∧
      BeliefReachableIn process.beliefTransition 1
        Belief.current Belief.future ∧
      frontierGap catalog library Strategy.candidate Belief.future = 2 ∧
      passiveOperationalInnovation dynamics 2 Belief.current library
          Strategy.candidate = 1 ∧
      0 < passiveOperationalInnovation dynamics 2 Belief.current library
        Strategy.candidate := by
  have hvalue :
      passiveOperationalInnovation dynamics 2 Belief.current library
          Strategy.candidate = 1 := by
    rw [passiveOperationalInnovation_eq_discountedGapSum]
    norm_num [discountedGapSum, dynamics, process, nextBelief, expectedValue,
      current_frontierGap_eq_zero, future_frontierGap_eq_two]
  exact ⟨current_frontierGap_eq_zero, future_reachable_in_one,
    future_frontierGap_eq_two, hvalue, by rw [hvalue]; norm_num⟩

end DelayedBenefitExample

end InnovationEquation

end StrategyInnovation
