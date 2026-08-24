import StrategyInnovation.Quotient.UnifiedDynamicInnovation

/-!
# Unified raw/compressed Bellman theory

This module derives the discounted Bellman theory for the raw model and its
realizable compressed projection.  It uses the unified calendar convention
from `Projection.RawToCompressed`: Continue consumes one period; a research
project has a strictly positive duration; incumbent operation during research
is controlled by the project's `operates` flag; and continuation is discounted
by `discount ^ duration`.

Unlike the compatibility structure `DiscountedContractionModel`, the
contraction certificates below are theorems derived from the finite exact
model.  The old structure remains available as an API wrapper for downstream
results.
-/

namespace StrategyInnovation

namespace Projection

namespace Model

open Filter Function Topology

variable {model : FiniteModel}
variable {catalog : Raw.StrategyCatalog model}
variable {closure : Raw.ClosureOperator model}

/-! ## Exact finite-horizon action attainment -/

/-- The exact value of one feasible compressed action at a positive horizon. -/
noncomputable def compressedFiniteActionValue
    (process : Model model catalog closure) (horizon : Nat)
    (belief : model.Belief) (state : CompressedLibraryState catalog closure)
    (action : FeasibleAction process (horizon + 1) state) : ℚ :=
  match action.1 with
  | none =>
      state.state.frontier belief + process.discount *
        (process.beliefTransition belief).expectation
          (fun nextBelief => process.compressedValue horizon nextBelief state)
  | some project =>
      -process.researchCost belief state project +
        (process.completion project belief state).expectation
          (fun completion =>
            process.incumbentReward state project completion.1 +
              process.discount ^ process.duration project *
                process.compressedValue
                  ((horizon + 1) - process.duration project)
                  (terminalBelief completion.1)
                  (CompressedLibraryState.add catalog closure state completion.2))

/-- The positive-horizon recursion is the maximum of its feasible action values. -/
theorem compressedValue_succ_eq_actionMaximum
    (process : Model model catalog closure) (horizon : Nat)
    (belief : model.Belief) (state : CompressedLibraryState catalog closure) :
    process.compressedValue (horizon + 1) belief state =
      Finset.univ.sup' Finset.univ_nonempty
        (process.compressedFiniteActionValue horizon belief state) := by
  simp only [compressedValue, compressedFiniteActionValue]
  rfl

/-- A feasible action attains every positive finite-horizon compressed value. -/
theorem finiteHorizonAction_attained
    (process : Model model catalog closure) (horizon : Nat)
    (belief : model.Belief) (state : CompressedLibraryState catalog closure) :
    ∃ action : FeasibleAction process (horizon + 1) state,
      process.compressedFiniteActionValue horizon belief state action =
        process.compressedValue (horizon + 1) belief state := by
  rcases Finset.exists_mem_eq_sup' Finset.univ_nonempty
      (process.compressedFiniteActionValue horizon belief state) with
    ⟨action, _, haction⟩
  refine ⟨action, ?_⟩
  rw [process.compressedValue_succ_eq_actionMaximum]
  exact haction.symm

/-- The exact value of one feasible raw-library action at a positive horizon. -/
noncomputable def rawFiniteActionValue
    (process : Model model catalog closure) (horizon : Nat)
    (belief : model.Belief) (library : Raw.Library catalog)
    (action : FeasibleAction process (horizon + 1)
      (CompressedLibraryState.ofLibrary catalog closure library)) : ℚ :=
  match action.1 with
  | none =>
      operationalFrontier catalog library belief + process.discount *
        (process.beliefTransition belief).expectation
          (fun nextBelief => process.rawValue horizon nextBelief library)
  | some project =>
      -process.researchCost belief
          (CompressedLibraryState.ofLibrary catalog closure library) project +
        (process.completion project belief
          (CompressedLibraryState.ofLibrary catalog closure library)).expectation
          (fun completion =>
            process.incumbentReward
                (CompressedLibraryState.ofLibrary catalog closure library)
                project completion.1 +
              process.discount ^ process.duration project *
                process.rawValue
                  ((horizon + 1) - process.duration project)
                  (terminalBelief completion.1)
                  (Raw.rawLibraryUpdate library completion.2))

/-- The positive-horizon raw recursion is the maximum of its feasible actions. -/
theorem rawValue_succ_eq_actionMaximum
    (process : Model model catalog closure) (horizon : Nat)
    (belief : model.Belief) (library : Raw.Library catalog) :
    process.rawValue (horizon + 1) belief library =
      Finset.univ.sup' Finset.univ_nonempty
        (process.rawFiniteActionValue horizon belief library) := by
  simp only [rawValue, rawFiniteActionValue]
  rfl

/-- A feasible action also attains every positive raw-library value. -/
theorem rawFiniteHorizonAction_attained
    (process : Model model catalog closure) (horizon : Nat)
    (belief : model.Belief) (library : Raw.Library catalog) :
    ∃ action : FeasibleAction process (horizon + 1)
        (CompressedLibraryState.ofLibrary catalog closure library),
      process.rawFiniteActionValue horizon belief library action =
        process.rawValue (horizon + 1) belief library := by
  rcases Finset.exists_mem_eq_sup' Finset.univ_nonempty
      (process.rawFiniteActionValue horizon belief library) with
    ⟨action, _, haction⟩
  refine ⟨action, ?_⟩
  rw [process.rawValue_succ_eq_actionMaximum]
  exact haction.symm

/-! ## Monotonicity and contraction -/

/-- Pointwise order on compressed stationary value tables. -/
def CompressedValueLE (process : Model model catalog closure)
    (left right : CompressedRealValue process) : Prop :=
  ∀ state, left state ≤ right state

/-- Pointwise order on raw-library stationary value tables. -/
def RawValueLE (process : Model model catalog closure)
    (left right : RawRealValue process) : Prop :=
  ∀ state, left state ≤ right state

/-- Evaluating a compressed table is nonexpansive in the finite sup norm. -/
theorem compressedValue_dist_apply_le
    (process : Model model catalog closure)
    (left right : CompressedRealValue process)
    (state : model.Belief × CompressedLibraryState catalog closure) :
    dist (left state) (right state) ≤ dist left right :=
  (dist_pi_le_iff dist_nonneg).1 le_rfl state

/-- Evaluating a raw table is nonexpansive in the finite sup norm. -/
theorem rawValue_dist_apply_le
    (process : Model model catalog closure)
    (left right : RawRealValue process)
    (state : model.Belief × Raw.Library catalog) :
    dist (left state) (right state) ≤ dist left right :=
  (dist_pi_le_iff dist_nonneg).1 le_rfl state

/-- Every positive project duration has discount coefficient at most `discount`. -/
theorem projectDiscount_le_discount
    (process : Model model catalog closure) (project : model.ResearchProject) :
    (process.discount : ℝ) ^ process.duration project ≤
      (process.discount : ℝ) := by
  apply pow_le_of_le_one
  · exact_mod_cast process.discount_nonnegative
  · exact_mod_cast process.discount_lt_one.le
  · have hpositive := process.duration_positive project
    omega

/-- A compressed stationary action value is monotone in continuation value. -/
theorem compressedInfiniteActionValue_mono
    (process : Model model catalog closure)
    {left right : CompressedRealValue process}
    (hvalue : process.CompressedValueLE left right)
    (belief : model.Belief) (state : CompressedLibraryState catalog closure)
    (action : InfiniteAction process state) :
    process.compressedInfiniteActionValue left belief state action ≤
      process.compressedInfiniteActionValue right belief state action := by
  cases haction : action.1 with
  | none =>
      simp only [compressedInfiniteActionValue, haction]
      apply add_le_add_right
      apply mul_le_mul_of_nonneg_left
      · apply BellmanContraction.realExpectedValue_mono
        intro nextBelief
        exact hvalue (nextBelief, state)
      · exact_mod_cast process.discount_nonnegative
  | some project =>
      simp only [compressedInfiniteActionValue, haction]
      apply add_le_add_right
      apply BellmanContraction.realExpectedValue_mono
      intro completion
      apply add_le_add_right
      apply mul_le_mul_of_nonneg_left
      · exact hvalue
          (terminalBelief completion.1,
            CompressedLibraryState.add catalog closure state completion.2)
      · exact pow_nonneg (by exact_mod_cast process.discount_nonnegative) _

/-- The unified compressed Bellman operator is pointwise monotone. -/
theorem compressedBellmanOperator_mono
    (process : Model model catalog closure)
    {left right : CompressedRealValue process}
    (hvalue : process.CompressedValueLE left right) :
    process.CompressedValueLE
      (process.compressedBellmanOperator left)
      (process.compressedBellmanOperator right) := by
  intro state
  apply Finset.sup'_le Finset.univ_nonempty
  intro action haction
  exact (process.compressedInfiniteActionValue_mono hvalue
      state.1 state.2 action).trans
    (Finset.le_sup'
      (fun action : InfiniteAction process state.2 =>
        process.compressedInfiniteActionValue right state.1 state.2 action)
      haction)

/-- A raw stationary action value is monotone in continuation value. -/
theorem rawInfiniteActionValue_mono
    (process : Model model catalog closure)
    {left right : RawRealValue process}
    (hvalue : process.RawValueLE left right)
    (belief : model.Belief) (library : Raw.Library catalog)
    (action : InfiniteAction process
      (CompressedLibraryState.ofLibrary catalog closure library)) :
    process.rawInfiniteActionValue left belief library action ≤
      process.rawInfiniteActionValue right belief library action := by
  cases haction : action.1 with
  | none =>
      simp only [rawInfiniteActionValue, haction]
      apply add_le_add_right
      apply mul_le_mul_of_nonneg_left
      · apply BellmanContraction.realExpectedValue_mono
        intro nextBelief
        exact hvalue (nextBelief, library)
      · exact_mod_cast process.discount_nonnegative
  | some project =>
      simp only [rawInfiniteActionValue, haction]
      apply add_le_add_right
      apply BellmanContraction.realExpectedValue_mono
      intro completion
      apply add_le_add_right
      apply mul_le_mul_of_nonneg_left
      · exact hvalue
          (terminalBelief completion.1,
            Raw.rawLibraryUpdate library completion.2)
      · exact pow_nonneg (by exact_mod_cast process.discount_nonnegative) _

/-- The unified raw Bellman operator is pointwise monotone. -/
theorem rawBellmanOperator_mono
    (process : Model model catalog closure)
    {left right : RawRealValue process}
    (hvalue : process.RawValueLE left right) :
    process.RawValueLE
      (process.rawBellmanOperator left)
      (process.rawBellmanOperator right) := by
  intro state
  apply Finset.sup'_le Finset.univ_nonempty
  intro action haction
  exact (process.rawInfiniteActionValue_mono hvalue
      state.1 state.2 action).trans
    (Finset.le_sup'
      (fun action : InfiniteAction process
          (CompressedLibraryState.ofLibrary catalog closure state.2) =>
        process.rawInfiniteActionValue right state.1 state.2 action)
      haction)

/-- Every compressed stationary action is `discount`-Lipschitz. -/
theorem compressedInfiniteActionValue_dist_le
    (process : Model model catalog closure)
    (left right : CompressedRealValue process)
    (belief : model.Belief) (state : CompressedLibraryState catalog closure)
    (action : InfiniteAction process state) :
    dist
        (process.compressedInfiniteActionValue left belief state action)
        (process.compressedInfiniteActionValue right belief state action) ≤
      (process.discount : ℝ) * dist left right := by
  have hdiscount : (0 : ℝ) ≤ process.discount := by
    exact_mod_cast process.discount_nonnegative
  cases haction : action.1 with
  | none =>
      simp only [compressedInfiniteActionValue, haction]
      rw [dist_add_left]
      calc
        _ = |(process.discount : ℝ)| *
            dist
              (BellmanContraction.realExpectedValue
                (process.beliefTransition belief)
                (fun nextBelief => left (nextBelief, state)))
              (BellmanContraction.realExpectedValue
                (process.beliefTransition belief)
                (fun nextBelief => right (nextBelief, state))) := by
          rw [Real.dist_eq, Real.dist_eq, ← mul_sub, abs_mul]
        _ = (process.discount : ℝ) *
            dist
              (BellmanContraction.realExpectedValue
                (process.beliefTransition belief)
                (fun nextBelief => left (nextBelief, state)))
              (BellmanContraction.realExpectedValue
                (process.beliefTransition belief)
                (fun nextBelief => right (nextBelief, state))) := by
          rw [abs_of_nonneg hdiscount]
        _ ≤ (process.discount : ℝ) * dist left right := by
          apply mul_le_mul_of_nonneg_left _ hdiscount
          apply BellmanContraction.realExpectedValue_dist_le _ _ _ dist_nonneg
          intro nextBelief
          exact process.compressedValue_dist_apply_le left right (nextBelief, state)
  | some project =>
      simp only [compressedInfiniteActionValue, haction]
      rw [dist_add_left]
      apply BellmanContraction.realExpectedValue_dist_le _ _ _
        (mul_nonneg hdiscount dist_nonneg)
      intro completion
      rw [dist_add_left]
      have hdiscountPow :
          (0 : ℝ) ≤ (process.discount : ℝ) ^ process.duration project :=
        pow_nonneg hdiscount _
      calc
        _ = |(process.discount : ℝ) ^ process.duration project| *
            dist
              (left (terminalBelief completion.1,
                CompressedLibraryState.add catalog closure state completion.2))
              (right (terminalBelief completion.1,
                CompressedLibraryState.add catalog closure state completion.2)) := by
          rw [Real.dist_eq, Real.dist_eq, ← mul_sub, abs_mul]
        _ = (process.discount : ℝ) ^ process.duration project *
            dist
              (left (terminalBelief completion.1,
                CompressedLibraryState.add catalog closure state completion.2))
              (right (terminalBelief completion.1,
                CompressedLibraryState.add catalog closure state completion.2)) := by
          rw [abs_of_nonneg hdiscountPow]
        _ ≤ (process.discount : ℝ) ^ process.duration project *
            dist left right := by
          apply mul_le_mul_of_nonneg_left _ hdiscountPow
          exact process.compressedValue_dist_apply_le left right _
        _ ≤ (process.discount : ℝ) * dist left right := by
          apply mul_le_mul_of_nonneg_right
            (process.projectDiscount_le_discount project) dist_nonneg

/-- Every raw stationary action is `discount`-Lipschitz. -/
theorem rawInfiniteActionValue_dist_le
    (process : Model model catalog closure)
    (left right : RawRealValue process)
    (belief : model.Belief) (library : Raw.Library catalog)
    (action : InfiniteAction process
      (CompressedLibraryState.ofLibrary catalog closure library)) :
    dist
        (process.rawInfiniteActionValue left belief library action)
        (process.rawInfiniteActionValue right belief library action) ≤
      (process.discount : ℝ) * dist left right := by
  have hdiscount : (0 : ℝ) ≤ process.discount := by
    exact_mod_cast process.discount_nonnegative
  cases haction : action.1 with
  | none =>
      simp only [rawInfiniteActionValue, haction]
      rw [dist_add_left]
      calc
        _ = |(process.discount : ℝ)| *
            dist
              (BellmanContraction.realExpectedValue
                (process.beliefTransition belief)
                (fun nextBelief => left (nextBelief, library)))
              (BellmanContraction.realExpectedValue
                (process.beliefTransition belief)
                (fun nextBelief => right (nextBelief, library))) := by
          rw [Real.dist_eq, Real.dist_eq, ← mul_sub, abs_mul]
        _ = (process.discount : ℝ) *
            dist
              (BellmanContraction.realExpectedValue
                (process.beliefTransition belief)
                (fun nextBelief => left (nextBelief, library)))
              (BellmanContraction.realExpectedValue
                (process.beliefTransition belief)
                (fun nextBelief => right (nextBelief, library))) := by
          rw [abs_of_nonneg hdiscount]
        _ ≤ (process.discount : ℝ) * dist left right := by
          apply mul_le_mul_of_nonneg_left _ hdiscount
          apply BellmanContraction.realExpectedValue_dist_le _ _ _ dist_nonneg
          intro nextBelief
          exact process.rawValue_dist_apply_le left right (nextBelief, library)
  | some project =>
      simp only [rawInfiniteActionValue, haction]
      rw [dist_add_left]
      apply BellmanContraction.realExpectedValue_dist_le _ _ _
        (mul_nonneg hdiscount dist_nonneg)
      intro completion
      rw [dist_add_left]
      have hdiscountPow :
          (0 : ℝ) ≤ (process.discount : ℝ) ^ process.duration project :=
        pow_nonneg hdiscount _
      calc
        _ = |(process.discount : ℝ) ^ process.duration project| *
            dist
              (left (terminalBelief completion.1,
                Raw.rawLibraryUpdate library completion.2))
              (right (terminalBelief completion.1,
                Raw.rawLibraryUpdate library completion.2)) := by
          rw [Real.dist_eq, Real.dist_eq, ← mul_sub, abs_mul]
        _ = (process.discount : ℝ) ^ process.duration project *
            dist
              (left (terminalBelief completion.1,
                Raw.rawLibraryUpdate library completion.2))
              (right (terminalBelief completion.1,
                Raw.rawLibraryUpdate library completion.2)) := by
          rw [abs_of_nonneg hdiscountPow]
        _ ≤ (process.discount : ℝ) ^ process.duration project *
            dist left right := by
          apply mul_le_mul_of_nonneg_left _ hdiscountPow
          exact process.rawValue_dist_apply_le left right _
        _ ≤ (process.discount : ℝ) * dist left right := by
          apply mul_le_mul_of_nonneg_right
            (process.projectDiscount_le_discount project) dist_nonneg

/-- The compressed Bellman maximum is pointwise `discount`-Lipschitz. -/
theorem compressedBellmanOperator_pointwise_dist_le
    (process : Model model catalog closure)
    (left right : CompressedRealValue process)
    (state : model.Belief × CompressedLibraryState catalog closure) :
    dist
        (process.compressedBellmanOperator left state)
        (process.compressedBellmanOperator right state) ≤
      (process.discount : ℝ) * dist left right := by
  unfold compressedBellmanOperator
  apply BellmanContraction.dist_finset_sup'_le _ _
    (mul_nonneg (by exact_mod_cast process.discount_nonnegative) dist_nonneg)
  intro action
  exact process.compressedInfiniteActionValue_dist_le
    left right state.1 state.2 action

/-- The raw Bellman maximum is pointwise `discount`-Lipschitz. -/
theorem rawBellmanOperator_pointwise_dist_le
    (process : Model model catalog closure)
    (left right : RawRealValue process)
    (state : model.Belief × Raw.Library catalog) :
    dist
        (process.rawBellmanOperator left state)
        (process.rawBellmanOperator right state) ≤
      (process.discount : ℝ) * dist left right := by
  unfold rawBellmanOperator
  apply BellmanContraction.dist_finset_sup'_le _ _
    (mul_nonneg (by exact_mod_cast process.discount_nonnegative) dist_nonneg)
  intro action
  exact process.rawInfiniteActionValue_dist_le
    left right state.1 state.2 action

/-- The unified compressed Bellman operator is globally Lipschitz. -/
theorem compressedBellmanOperator_lipschitz
    (process : Model model catalog closure) :
    LipschitzWith process.discountNNReal process.compressedBellmanOperator := by
  apply LipschitzWith.of_dist_le_mul
  intro left right
  rw [dist_pi_le_iff
    (mul_nonneg process.discountNNReal.coe_nonneg dist_nonneg)]
  intro state
  exact process.compressedBellmanOperator_pointwise_dist_le left right state

/-- The unified raw Bellman operator is globally Lipschitz. -/
theorem rawBellmanOperator_lipschitz
    (process : Model model catalog closure) :
    LipschitzWith process.discountNNReal process.rawBellmanOperator := by
  apply LipschitzWith.of_dist_le_mul
  intro left right
  rw [dist_pi_le_iff
    (mul_nonneg process.discountNNReal.coe_nonneg dist_nonneg)]
  intro state
  exact process.rawBellmanOperator_pointwise_dist_le left right state

/-- The unified compressed Bellman operator is a contraction. -/
theorem compressedBellmanOperator_contracting
    (process : Model model catalog closure) :
    ContractingWith process.discountNNReal process.compressedBellmanOperator :=
  ⟨process.discountNNReal_lt_one, process.compressedBellmanOperator_lipschitz⟩

/-- The unified raw Bellman operator is a contraction. -/
theorem rawBellmanOperator_contracting
    (process : Model model catalog closure) :
    ContractingWith process.discountNNReal process.rawBellmanOperator :=
  ⟨process.discountNNReal_lt_one, process.rawBellmanOperator_lipschitz⟩

/-- Canonical contraction certificates derived from the unified finite model. -/
theorem contractionModel (process : Model model catalog closure) :
    DiscountedContractionModel process where
  compressed_contracting := process.compressedBellmanOperator_contracting
  raw_contracting := process.rawBellmanOperator_contracting

/-! ## Fixed points, convergence, and raw/compressed value equality -/

/-- The unique unified compressed infinite-horizon value. -/
noncomputable def infiniteHorizonValue
    (process : Model model catalog closure) : CompressedRealValue process :=
  process.contractionModel.compressedFixedPoint

/-- The unique unified raw-library infinite-horizon value. -/
noncomputable def rawInfiniteHorizonValue
    (process : Model model catalog closure) : RawRealValue process :=
  process.contractionModel.rawFixedPoint

/-- The compressed infinite-horizon value satisfies the Bellman equation. -/
theorem infiniteHorizonValue_isFixedPoint
    (process : Model model catalog closure) :
    Function.IsFixedPt process.compressedBellmanOperator
      process.infiniteHorizonValue :=
  process.contractionModel.compressedFixedPoint_isFixedPoint

/-- The raw infinite-horizon value satisfies the raw Bellman equation. -/
theorem rawInfiniteHorizonValue_isFixedPoint
    (process : Model model catalog closure) :
    Function.IsFixedPt process.rawBellmanOperator
      process.rawInfiniteHorizonValue :=
  process.contractionModel.rawFixedPoint_isFixedPoint

/-- The unified compressed Bellman fixed point is unique. -/
theorem infiniteHorizonValue_unique
    (process : Model model catalog closure)
    {value : CompressedRealValue process}
    (hvalue : Function.IsFixedPt process.compressedBellmanOperator value) :
    value = process.infiniteHorizonValue :=
  process.compressedBellmanOperator_contracting.fixedPoint_unique hvalue

/-- The unified raw-library Bellman fixed point is unique. -/
theorem rawInfiniteHorizonValue_unique
    (process : Model model catalog closure)
    {value : RawRealValue process}
    (hvalue : Function.IsFixedPt process.rawBellmanOperator value) :
    value = process.rawInfiniteHorizonValue :=
  process.rawBellmanOperator_contracting.fixedPoint_unique hvalue

/-- Stationary compressed value iteration from an arbitrary real table. -/
noncomputable def valueIteration (process : Model model catalog closure)
    (initial : CompressedRealValue process) (iteration : Nat) :
    CompressedRealValue process :=
  (process.compressedBellmanOperator^[iteration]) initial

/-- Unified stationary value iteration converges in finite-state sup norm. -/
theorem valueIteration_tendsto_infiniteHorizonValue
    (process : Model model catalog closure)
    (initial : CompressedRealValue process) :
    Tendsto (fun iteration => process.valueIteration initial iteration) atTop
      (𝓝 process.infiniteHorizonValue) :=
  process.compressedBellmanOperator_contracting.tendsto_iterate_fixedPoint initial

/-- The Banach a priori geometric error bound for unified value iteration. -/
theorem valueIteration_geometric_error_bound
    (process : Model model catalog closure)
    (initial : CompressedRealValue process) (iteration : Nat) :
    dist (process.valueIteration initial iteration)
        process.infiniteHorizonValue ≤
      dist initial (process.compressedBellmanOperator initial) *
          (process.discountNNReal : ℝ) ^ iteration /
        (1 - (process.discountNNReal : ℝ)) :=
  process.compressedBellmanOperator_contracting
    |>.apriori_dist_iterate_fixedPoint_le initial iteration

/-- Stationary raw-library value iteration from an arbitrary real table. -/
noncomputable def rawValueIteration (process : Model model catalog closure)
    (initial : RawRealValue process) (iteration : Nat) :
    RawRealValue process :=
  (process.rawBellmanOperator^[iteration]) initial

/-- Unified raw-library value iteration converges in finite-state sup norm. -/
theorem rawValueIteration_tendsto_rawInfiniteHorizonValue
    (process : Model model catalog closure)
    (initial : RawRealValue process) :
    Tendsto (fun iteration => process.rawValueIteration initial iteration) atTop
      (𝓝 process.rawInfiniteHorizonValue) :=
  process.rawBellmanOperator_contracting.tendsto_iterate_fixedPoint initial

/-- The Banach a priori geometric error bound for raw-library value iteration. -/
theorem rawValueIteration_geometric_error_bound
    (process : Model model catalog closure)
    (initial : RawRealValue process) (iteration : Nat) :
    dist (process.rawValueIteration initial iteration)
        process.rawInfiniteHorizonValue ≤
      dist initial (process.rawBellmanOperator initial) *
          (process.discountNNReal : ℝ) ^ iteration /
        (1 - (process.discountNNReal : ℝ)) :=
  process.rawBellmanOperator_contracting
    |>.apriori_dist_iterate_fixedPoint_le initial iteration

/-- Finite-horizon raw and compressed values agree under actual compression. -/
theorem finiteHorizon_rawValue_eq_compressedValue
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief) (library : Raw.Library catalog) :
    process.rawValue horizon belief library =
      process.compressedValue horizon belief
        (CompressedLibraryState.ofLibrary catalog closure library) :=
  process.rawValue_eq_compressedValue horizon belief library

/-- Infinite-horizon raw and compressed fixed-point values agree. -/
theorem rawInfiniteHorizonValue_eq_compressed
    (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog) :
    process.rawInfiniteHorizonValue (belief, library) =
      process.infiniteHorizonValue
        (belief, CompressedLibraryState.ofLibrary catalog closure library) :=
  process.contractionModel.raw_fixedPoint_value_eq_compressed belief library

/-- Unified DI-equivalent raw libraries have equal finite-horizon value. -/
theorem finiteHorizonValue_eq_of_dynamicInnovationEquivalent
    (process : Model model catalog closure)
    {left right : Raw.Library catalog}
    (hequivalent : DynamicInnovationEquivalent process left right)
    (horizon : Nat) (belief : model.Belief) :
    process.rawValue horizon belief left =
      process.rawValue horizon belief right :=
  process.rawValue_eq_of_dynamicInnovationEquivalent
    hequivalent horizon belief

/-- Unified DI-equivalent raw libraries have equal infinite-horizon value. -/
theorem infiniteHorizonValue_eq_of_dynamicInnovationEquivalent
    (process : Model model catalog closure)
    {left right : Raw.Library catalog}
    (hequivalent : DynamicInnovationEquivalent process left right)
    (belief : model.Belief) :
    process.rawInfiniteHorizonValue (belief, left) =
      process.rawInfiniteHorizonValue (belief, right) :=
  process.contractionModel.rawFixedPoint_eq_of_dynamicInnovationEquivalent
    hequivalent belief

/-! ## Stationary selectors and policy evaluation -/

/-- A feasible stationary policy on the realizable compressed state. -/
abbrev StationaryPolicy (process : Model model catalog closure) :=
  (state : model.Belief × CompressedLibraryState catalog closure) →
    InfiniteAction process state.2

/-- The fixed-action policy-evaluation operator. -/
def policyOperator (process : Model model catalog closure)
    (policy : StationaryPolicy process)
    (value : CompressedRealValue process) : CompressedRealValue process :=
  fun state =>
    process.compressedInfiniteActionValue value state.1 state.2 (policy state)

/-- Every stationary compressed policy operator is a contraction. -/
theorem policyOperator_contracting
    (process : Model model catalog closure)
    (policy : StationaryPolicy process) :
    ContractingWith process.discountNNReal (process.policyOperator policy) := by
  refine ⟨process.discountNNReal_lt_one, ?_⟩
  apply LipschitzWith.of_dist_le_mul
  intro left right
  rw [dist_pi_le_iff
    (mul_nonneg process.discountNNReal.coe_nonneg dist_nonneg)]
  intro state
  exact process.compressedInfiniteActionValue_dist_le
    left right state.1 state.2 (policy state)

/-- The unique value of a stationary compressed policy. -/
noncomputable def stationaryPolicyValue
    (process : Model model catalog closure)
    (policy : StationaryPolicy process) : CompressedRealValue process :=
  ContractingWith.fixedPoint (process.policyOperator policy)
    (process.policyOperator_contracting policy)

/-- A stationary policy's value satisfies its policy-evaluation equation. -/
theorem stationaryPolicyValue_isFixedPoint
    (process : Model model catalog closure)
    (policy : StationaryPolicy process) :
    Function.IsFixedPt (process.policyOperator policy)
      (process.stationaryPolicyValue policy) :=
  (process.policyOperator_contracting policy).fixedPoint_isFixedPt

/-- The finite action maximum defines a stationary optimal selector. -/
noncomputable def stationaryOptimalSelector
    (process : Model model catalog closure) : StationaryPolicy process :=
  process.contractionModel.optimalCompressedPolicy

/-- The stationary selector attains the Bellman maximum in every state. -/
theorem stationaryOptimalSelector_attains
    (process : Model model catalog closure)
    (state : model.Belief × CompressedLibraryState catalog closure) :
    process.compressedInfiniteActionValue process.infiniteHorizonValue
        state.1 state.2 (process.stationaryOptimalSelector state) =
      process.compressedBellmanOperator process.infiniteHorizonValue state :=
  process.contractionModel.optimalCompressedPolicy_attains state

/-- A stationary Bellman-optimal selector exists on the finite compressed state. -/
theorem exists_stationaryOptimalSelector
    (process : Model model catalog closure) :
    ∃ policy : StationaryPolicy process,
      ∀ state,
        process.compressedInfiniteActionValue process.infiniteHorizonValue
            state.1 state.2 (policy state) =
          process.compressedBellmanOperator process.infiniteHorizonValue state :=
  ⟨process.stationaryOptimalSelector,
    process.stationaryOptimalSelector_attains⟩

/-- The optimal selector satisfies its exact policy-evaluation equation. -/
theorem stationaryOptimalSelector_policyEvaluationEquation
    (process : Model model catalog closure) :
    Function.IsFixedPt
      (process.policyOperator process.stationaryOptimalSelector)
      process.infiniteHorizonValue := by
  funext state
  exact (process.stationaryOptimalSelector_attains state).trans
    (congrFun process.infiniteHorizonValue_isFixedPoint state)

/-- Policy evaluation of the selected stationary policy recovers optimal value. -/
theorem stationaryOptimalSelector_value_eq_infiniteHorizonValue
    (process : Model model catalog closure) :
    process.stationaryPolicyValue process.stationaryOptimalSelector =
      process.infiniteHorizonValue := by
  symm
  exact (process.policyOperator_contracting process.stationaryOptimalSelector)
    |>.fixedPoint_unique
      process.stationaryOptimalSelector_policyEvaluationEquation

/-- Lift the optimal compressed selector to raw libraries. -/
noncomputable def liftedRawStationarySelector
    (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog) :
    InfiniteAction process
      (CompressedLibraryState.ofLibrary catalog closure library) :=
  process.contractionModel.liftedRawPolicy belief library

/-- The lifted selector attains the raw Bellman maximum. -/
theorem liftedRawStationarySelector_attains
    (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog) :
    process.rawInfiniteActionValue process.rawInfiniteHorizonValue belief library
        (process.liftedRawStationarySelector belief library) =
      process.rawBellmanOperator process.rawInfiniteHorizonValue
        (belief, library) :=
  process.contractionModel.liftedRawPolicy_optimal belief library

/-- The lifted selector's raw action value equals the raw optimal value. -/
theorem liftedRawStationarySelector_policyEvaluationEquation
    (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog) :
    process.rawInfiniteActionValue process.rawInfiniteHorizonValue belief library
        (process.liftedRawStationarySelector belief library) =
      process.rawInfiniteHorizonValue (belief, library) := by
  exact (process.liftedRawStationarySelector_attains belief library).trans
    (congrFun process.rawInfiniteHorizonValue_isFixedPoint (belief, library))

end Model

end Projection

end StrategyInnovation
