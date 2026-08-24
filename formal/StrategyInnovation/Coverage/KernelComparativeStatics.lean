import StrategyInnovation.Coverage.DiscountSurvivalInteraction

/-!
# Comparative statics for changes in the belief kernel

This module shows that a scalar label called “persistence” has no universal
sign for finite strategy-innovation coverage.  The sign depends on whether the
kernel change moves discounted occupation toward or away from states with a
positive certified gap.

The exact two-state family

`P(θ) = [[θ, 1 - θ], [1 - θ, θ]]`

is row stochastic for `θ ∈ [0,1]`.  At the current state, increasing `θ`
raises coverage for a gap concentrated at that state, lowers coverage for a
gap concentrated at the other state, and leaves a constant gap unchanged.

The positive theorem uses an explicit alignment condition: discounted
occupation under the second kernel weakly dominates on every positive-gap
state.  The gap-tailored occupation order is then exactly the desired
pointwise comparison of finite coverage potentials.
-/

namespace StrategyInnovation

namespace Coverage

namespace KernelComparativeStatics

open scoped BigOperators

variable {State : Type*} [Fintype State] [DecidableEq State]

/-- Discounted finite occupation of `target` from `initial`. -/
def discountedOccupation
    (horizon : Nat) (alpha : ℚ)
    (transition : Matrix State State ℚ)
    (initial target : State) : ℚ :=
  ∑ time ∈ Finset.range horizon,
    alpha ^ time * (transition ^ time) initial target

/-- States on which the certified gap is strictly positive. -/
def advantageRegion (gap : State → ℚ) : Finset State :=
  Finset.univ.filter fun state => 0 < gap state

/--
Kernel `transition1` is aligned above `transition0` for `gap` when it places
at least as much discounted occupation on every positive-gap state, from
every initial state.
-/
def OccupationDominatesOnAdvantage
    (horizon : Nat) (alpha : ℚ) (gap : State → ℚ)
    (transition1 transition0 : Matrix State State ℚ) : Prop :=
  ∀ initial state,
    state ∈ advantageRegion gap →
      discountedOccupation horizon alpha transition0 initial state ≤
        discountedOccupation horizon alpha transition1 initial state

/--
The gap-tailored discounted-occupation order:
`transition1 ≽_g transition0` exactly when its finite potential is pointwise
larger.
-/
def GapOccupationDominates
    (horizon : Nat) (alpha : ℚ) (gap : State → ℚ)
    (transition1 transition0 : Matrix State State ℚ) : Prop :=
  ∀ initial,
    DiscountSurvivalInteraction.finiteEffectivePotential
        horizon alpha transition0 gap initial ≤
      DiscountSurvivalInteraction.finiteEffectivePotential
        horizon alpha transition1 gap initial

/--
Finite coverage is the gap-weighted discounted occupation of every state.
-/
theorem finiteEffectivePotential_eq_discountedOccupation
    (horizon : Nat) (alpha : ℚ)
    (transition : Matrix State State ℚ)
    (gap : State → ℚ) (initial : State) :
    DiscountSurvivalInteraction.finiteEffectivePotential
        horizon alpha transition gap initial =
      ∑ state, discountedOccupation horizon alpha transition initial state *
        gap state := by
  classical
  unfold DiscountSurvivalInteraction.finiteEffectivePotential
    DiscountSurvivalInteraction.matrixPowerGap discountedOccupation
  simp only [Matrix.mulVec, dotProduct, Finset.mul_sum, Finset.sum_mul]
  rw [Finset.sum_comm]
  apply Finset.sum_congr rfl
  intro state hstate
  apply Finset.sum_congr rfl
  intro time htime
  ring

/--
Sufficient alignment theorem.  If the second kernel has weakly more discounted
occupation on every state in the advantage region, then its coverage is
pointwise weakly larger.
-/
theorem coverage_mono_of_occupationDominatesOnAdvantage
    {horizon : Nat} {alpha : ℚ} {gap : State → ℚ}
    {transition1 transition0 : Matrix State State ℚ}
    (hgap : ∀ state, 0 ≤ gap state)
    (halignment :
      OccupationDominatesOnAdvantage
        horizon alpha gap transition1 transition0)
    (initial : State) :
    DiscountSurvivalInteraction.finiteEffectivePotential
        horizon alpha transition0 gap initial ≤
      DiscountSurvivalInteraction.finiteEffectivePotential
        horizon alpha transition1 gap initial := by
  rw [finiteEffectivePotential_eq_discountedOccupation,
    finiteEffectivePotential_eq_discountedOccupation]
  apply Finset.sum_le_sum
  intro state hstate
  by_cases hpositive : 0 < gap state
  · apply mul_le_mul_of_nonneg_right
    · exact halignment initial state (by
        simp [advantageRegion, hpositive])
    · exact hgap state
  · have hzero : gap state = 0 :=
      le_antisymm (le_of_not_gt hpositive) (hgap state)
    simp [hzero]

/-- Alignment on the advantage region implies the gap-tailored order. -/
theorem gapOccupationDominates_of_occupationDominatesOnAdvantage
    {horizon : Nat} {alpha : ℚ} {gap : State → ℚ}
    {transition1 transition0 : Matrix State State ℚ}
    (hgap : ∀ state, 0 ≤ gap state)
    (halignment :
      OccupationDominatesOnAdvantage
        horizon alpha gap transition1 transition0) :
    GapOccupationDominates
      horizon alpha gap transition1 transition0 := by
  intro initial
  exact coverage_mono_of_occupationDominatesOnAdvantage
    hgap halignment initial

/--
The gap-tailored order is definitionally equivalent to the requested
pointwise finite-sum comparison.
-/
theorem gapOccupationDominates_iff
    (horizon : Nat) (alpha : ℚ) (gap : State → ℚ)
    (transition1 transition0 : Matrix State State ℚ) :
    GapOccupationDominates horizon alpha gap transition1 transition0 ↔
      ∀ initial,
        (∑ time ∈ Finset.range horizon,
            alpha ^ time *
              DiscountSurvivalInteraction.matrixPowerGap
                transition0 gap time initial) ≤
          ∑ time ∈ Finset.range horizon,
            alpha ^ time *
              DiscountSurvivalInteraction.matrixPowerGap
                transition1 gap time initial := by
  rfl

/-! ## Exact two-state persistence family and sign counterexamples -/

/--
The exact symmetric two-state persistence family.  A larger `theta` puts more
one-step mass on remaining in the current state.
-/
def persistenceKernel (theta : ℚ) : Matrix (Fin 2) (Fin 2) ℚ :=
  fun initial next => if initial = next then theta else 1 - theta

/-- The family is row stochastic on the probability interval. -/
theorem persistenceKernel_stochastic
    {theta : ℚ} (htheta0 : 0 ≤ theta) (htheta1 : theta ≤ 1) :
    persistenceKernel theta ∈ Matrix.rowStochastic ℚ (Fin 2) := by
  rw [Matrix.mem_rowStochastic_iff_sum]
  constructor
  · intro initial next
    simp only [persistenceKernel]
    split_ifs
    · exact htheta0
    · linarith
  · intro initial
    fin_cases initial <;>
      norm_num [persistenceKernel]

/-- Coverage induced by the parameterized persistence family. -/
def persistenceCoverage
    (horizon : Nat) (alpha theta : ℚ)
    (gap : Fin 2 → ℚ) (initial : Fin 2) : ℚ :=
  DiscountSurvivalInteraction.finiteEffectivePotential
    horizon alpha (persistenceKernel theta) gap initial

/-- Gap concentrated in the initial, uncovered-advantage state. -/
def currentAdvantageGap : Fin 2 → ℚ
  | 0 => 1
  | 1 => 0

/-- Gap concentrated away from the current, already-covered state. -/
def otherAdvantageGap : Fin 2 → ℚ
  | 0 => 0
  | 1 => 1

/-- A constant gap, for which every stochastic kernel has the same coverage. -/
def constantAdvantageGap : Fin 2 → ℚ :=
  fun _ => 1

/--
Increasing persistence raises coverage when the current belief itself lies in
the uncovered advantage region.
-/
theorem higherPersistence_raises_coverage :
    persistenceCoverage 2 (1 / 2) (1 / 4) currentAdvantageGap 0 = 9 / 8 ∧
    persistenceCoverage 2 (1 / 2) (3 / 4) currentAdvantageGap 0 = 11 / 8 ∧
    persistenceCoverage 2 (1 / 2) (1 / 4) currentAdvantageGap 0 <
      persistenceCoverage 2 (1 / 2) (3 / 4) currentAdvantageGap 0 := by
  norm_num [persistenceCoverage,
    DiscountSurvivalInteraction.finiteEffectivePotential,
    DiscountSurvivalInteraction.matrixPowerGap,
    persistenceKernel, currentAdvantageGap, Matrix.mulVec, dotProduct,
    Finset.sum_range_succ]

/--
Increasing persistence lowers coverage when it traps the process at a
well-covered current belief and away from the uncovered advantage state.
-/
theorem higherPersistence_lowers_coverage :
    persistenceCoverage 2 (1 / 2) (1 / 4) otherAdvantageGap 0 = 3 / 8 ∧
    persistenceCoverage 2 (1 / 2) (3 / 4) otherAdvantageGap 0 = 1 / 8 ∧
    persistenceCoverage 2 (1 / 2) (3 / 4) otherAdvantageGap 0 <
      persistenceCoverage 2 (1 / 2) (1 / 4) otherAdvantageGap 0 := by
  norm_num [persistenceCoverage,
    DiscountSurvivalInteraction.finiteEffectivePotential,
    DiscountSurvivalInteraction.matrixPowerGap,
    persistenceKernel, otherAdvantageGap, Matrix.mulVec, dotProduct,
    Finset.sum_range_succ]

/-- Increasing persistence has no effect when the gap is constant. -/
theorem higherPersistence_no_effect :
    persistenceCoverage 2 (1 / 2) (1 / 4) constantAdvantageGap 0 = 3 / 2 ∧
    persistenceCoverage 2 (1 / 2) (3 / 4) constantAdvantageGap 0 = 3 / 2 := by
  norm_num [persistenceCoverage,
    DiscountSurvivalInteraction.finiteEffectivePotential,
    DiscountSurvivalInteraction.matrixPowerGap,
    persistenceKernel, constantAdvantageGap, Matrix.mulVec, dotProduct,
    Finset.sum_range_succ]

/--
There is no universal weakly increasing persistence theorem, even within one
exact row-stochastic kernel family and with a nonnegative gap.
-/
theorem no_universal_persistence_increase :
    ∃ gap : Fin 2 → ℚ,
      (∀ state, 0 ≤ gap state) ∧
      persistenceCoverage 2 (1 / 2) (3 / 4) gap 0 <
        persistenceCoverage 2 (1 / 2) (1 / 4) gap 0 := by
  refine ⟨otherAdvantageGap, ?_, higherPersistence_lowers_coverage.2.2⟩
  intro state
  fin_cases state <;> norm_num [otherAdvantageGap]

/--
There is no universal weakly decreasing persistence theorem either.
-/
theorem no_universal_persistence_decrease :
    ∃ gap : Fin 2 → ℚ,
      (∀ state, 0 ≤ gap state) ∧
      persistenceCoverage 2 (1 / 2) (1 / 4) gap 0 <
        persistenceCoverage 2 (1 / 2) (3 / 4) gap 0 := by
  refine ⟨currentAdvantageGap, ?_, higherPersistence_raises_coverage.2.2⟩
  intro state
  fin_cases state <;> norm_num [currentAdvantageGap]

end KernelComparativeStatics

end Coverage

end StrategyInnovation
