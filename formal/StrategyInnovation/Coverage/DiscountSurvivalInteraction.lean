import Mathlib.LinearAlgebra.Matrix.Stochastic
import Mathlib.Tactic

/-!
# Finite interaction between discounting and candidate survival

For a finite exact row-stochastic matrix `P`, a pointwise nonnegative gap
vector `g`, discount `β`, and survival `ρ`, this module studies the truncated
potential

`Ψ_H(β,ρ) = ∑ t < H, (β * ρ)^t (P^t *ᵥ g)`.

The finite-difference interaction is exact.  Its cross difference factors
date by date as

`(β₁^t - β₀^t) * (ρ₁^t - ρ₀^t) * (P^t *ᵥ g)`.

Every factor is nonnegative under the stated order assumptions, so patience
and survival are complements without invoking real differentiation or an
infinite-series inverse.  The finite resolvent below is the truncated analogue
of `(I - αP)⁻¹`; no infinite-resolvent theorem is claimed here.
-/

namespace StrategyInnovation

namespace Coverage

namespace DiscountSurvivalInteraction

open scoped BigOperators

variable {State : Type*} [Fintype State] [DecidableEq State]

/-- The exact effective discount multiplying one transition step. -/
def effectiveDiscount (discount survival : ℚ) : ℚ :=
  discount * survival

/-- The date-`t` gap vector `P^t g`. -/
def matrixPowerGap
    (transition : Matrix State State ℚ) (gap : State → ℚ)
    (time : Nat) : State → ℚ :=
  (transition ^ time).mulVec gap

/-- The truncated matrix resolvent `∑ t < H, α^t P^t`. -/
def finiteResolvent
    (horizon : Nat) (alpha : ℚ)
    (transition : Matrix State State ℚ) : Matrix State State ℚ :=
  ∑ time ∈ Finset.range horizon, alpha ^ time • transition ^ time

/-- The finite potential at one effective discount `α`. -/
def finiteEffectivePotential
    (horizon : Nat) (alpha : ℚ)
    (transition : Matrix State State ℚ) (gap : State → ℚ) :
    State → ℚ :=
  fun initial =>
    ∑ time ∈ Finset.range horizon,
      alpha ^ time * matrixPowerGap transition gap time initial

/-- The finite discount-survival potential `Ψ_H(β,ρ)`. -/
def finiteHorizonPotential
    (horizon : Nat) (discount survival : ℚ)
    (transition : Matrix State State ℚ) (gap : State → ℚ) :
    State → ℚ :=
  finiteEffectivePotential horizon
    (effectiveDiscount discount survival) transition gap

/--
Finite-horizon identity:
`Ψ_H = ∑ t < H, (βρ)^t P^t g`.
-/
theorem finiteHorizonPotential_eq_sum
    (horizon : Nat) (discount survival : ℚ)
    (transition : Matrix State State ℚ) (gap : State → ℚ)
    (initial : State) :
    finiteHorizonPotential horizon discount survival transition gap initial =
      ∑ time ∈ Finset.range horizon,
        (discount * survival) ^ time *
          matrixPowerGap transition gap time initial := by
  rfl

/-- The finite potential is the truncated resolvent applied to the gap. -/
theorem finiteResolvent_mulVec_eq_finiteEffectivePotential
    (horizon : Nat) (alpha : ℚ)
    (transition : Matrix State State ℚ) (gap : State → ℚ) :
    (finiteResolvent horizon alpha transition).mulVec gap =
      finiteEffectivePotential horizon alpha transition gap := by
  classical
  unfold finiteResolvent finiteEffectivePotential
  rw [Matrix.sum_mulVec]
  funext initial
  simp [matrixPowerGap, Matrix.smul_mulVec, smul_eq_mul]

/-- Every iterated expected gap is nonnegative under stochastic `P` and `g ≥ 0`. -/
theorem matrixPowerGap_nonnegative
    {transition : Matrix State State ℚ}
    (htransition :
      transition ∈ Matrix.rowStochastic ℚ State)
    {gap : State → ℚ} (hgap : ∀ state, 0 ≤ gap state)
    (time : Nat) (initial : State) :
    0 ≤ matrixPowerGap transition gap time initial := by
  exact Matrix.nonneg_mulVec_of_mem_rowStochastic
    ((Matrix.rowStochastic ℚ State).pow_mem htransition time) hgap initial

/-- Every finite potential is nonnegative for nonnegative effective discount. -/
theorem finiteEffectivePotential_nonnegative
    {transition : Matrix State State ℚ}
    (htransition :
      transition ∈ Matrix.rowStochastic ℚ State)
    {gap : State → ℚ} (hgap : ∀ state, 0 ≤ gap state)
    (horizon : Nat) {alpha : ℚ} (halpha : 0 ≤ alpha)
    (initial : State) :
    0 ≤ finiteEffectivePotential horizon alpha transition gap initial := by
  unfold finiteEffectivePotential
  apply Finset.sum_nonneg
  intro time htime
  exact mul_nonneg (pow_nonneg halpha _)
    (matrixPowerGap_nonnegative htransition hgap time initial)

/-- The finite potential is monotone in the effective discount `α`. -/
theorem finiteEffectivePotential_mono
    {transition : Matrix State State ℚ}
    (htransition :
      transition ∈ Matrix.rowStochastic ℚ State)
    {gap : State → ℚ} (hgap : ∀ state, 0 ≤ gap state)
    (horizon : Nat) {leftAlpha rightAlpha : ℚ}
    (hleftAlpha : 0 ≤ leftAlpha)
    (halpha : leftAlpha ≤ rightAlpha)
    (initial : State) :
    finiteEffectivePotential horizon leftAlpha transition gap initial ≤
      finiteEffectivePotential horizon rightAlpha transition gap initial := by
  unfold finiteEffectivePotential
  apply Finset.sum_le_sum
  intro time htime
  apply mul_le_mul_of_nonneg_right
  · exact pow_le_pow_left₀ hleftAlpha halpha time
  · exact matrixPowerGap_nonnegative htransition hgap time initial

/-- `Ψ_H` is monotone in discount when survival is nonnegative. -/
theorem finiteHorizonPotential_mono_discount
    {transition : Matrix State State ℚ}
    (htransition :
      transition ∈ Matrix.rowStochastic ℚ State)
    {gap : State → ℚ} (hgap : ∀ state, 0 ≤ gap state)
    (horizon : Nat)
    {leftDiscount rightDiscount survival : ℚ}
    (hleftDiscount : 0 ≤ leftDiscount)
    (hdiscount : leftDiscount ≤ rightDiscount)
    (hsurvival : 0 ≤ survival)
    (initial : State) :
    finiteHorizonPotential horizon leftDiscount survival transition gap initial ≤
      finiteHorizonPotential horizon rightDiscount survival transition gap initial := by
  apply finiteEffectivePotential_mono htransition hgap horizon
  · exact mul_nonneg hleftDiscount hsurvival
  · exact mul_le_mul_of_nonneg_right hdiscount hsurvival

/-- `Ψ_H` is monotone in survival when discount is nonnegative. -/
theorem finiteHorizonPotential_mono_survival
    {transition : Matrix State State ℚ}
    (htransition :
      transition ∈ Matrix.rowStochastic ℚ State)
    {gap : State → ℚ} (hgap : ∀ state, 0 ≤ gap state)
    (horizon : Nat)
    {discount leftSurvival rightSurvival : ℚ}
    (hdiscount : 0 ≤ discount)
    (hleftSurvival : 0 ≤ leftSurvival)
    (hsurvival : leftSurvival ≤ rightSurvival)
    (initial : State) :
    finiteHorizonPotential horizon discount leftSurvival transition gap initial ≤
      finiteHorizonPotential horizon discount rightSurvival transition gap initial := by
  apply finiteEffectivePotential_mono htransition hgap horizon
  · exact mul_nonneg hdiscount hleftSurvival
  · exact mul_le_mul_of_nonneg_left hsurvival hdiscount

/--
Exact finite cross-difference factorization.  No sign assumptions are needed
for this algebraic identity.
-/
theorem finiteHorizonPotential_crossDifference_eq_factorized
    (horizon : Nat)
    (discount0 discount1 survival0 survival1 : ℚ)
    (transition : Matrix State State ℚ) (gap : State → ℚ)
    (initial : State) :
    finiteHorizonPotential horizon discount1 survival1 transition gap initial +
          finiteHorizonPotential horizon discount0 survival0 transition gap initial -
          finiteHorizonPotential horizon discount1 survival0 transition gap initial -
          finiteHorizonPotential horizon discount0 survival1 transition gap initial =
      ∑ time ∈ Finset.range horizon,
        (discount1 ^ time - discount0 ^ time) *
          (survival1 ^ time - survival0 ^ time) *
          matrixPowerGap transition gap time initial := by
  unfold finiteHorizonPotential finiteEffectivePotential effectiveDiscount
  rw [← Finset.sum_add_distrib, ← Finset.sum_sub_distrib,
    ← Finset.sum_sub_distrib]
  apply Finset.sum_congr rfl
  intro time htime
  rw [mul_pow, mul_pow, mul_pow, mul_pow]
  ring

/-- The increase in `β` evaluated at a fixed survival factor. -/
def discountIncrement
    (horizon : Nat) (discount0 discount1 survival : ℚ)
    (transition : Matrix State State ℚ) (gap : State → ℚ)
    (initial : State) : ℚ :=
  finiteHorizonPotential horizon discount1 survival transition gap initial -
    finiteHorizonPotential horizon discount0 survival transition gap initial

/--
Exact finite-difference interaction: the change in the discount increment
between two survival factors is the factorized finite sum.
-/
theorem discountIncrement_difference_eq_factorized
    (horizon : Nat)
    (discount0 discount1 survival0 survival1 : ℚ)
    (transition : Matrix State State ℚ) (gap : State → ℚ)
    (initial : State) :
    discountIncrement horizon discount0 discount1 survival1 transition gap initial -
          discountIncrement horizon discount0 discount1 survival0 transition gap initial =
      ∑ time ∈ Finset.range horizon,
        (discount1 ^ time - discount0 ^ time) *
          (survival1 ^ time - survival0 ^ time) *
          matrixPowerGap transition gap time initial := by
  rw [← finiteHorizonPotential_crossDifference_eq_factorized horizon
    discount0 discount1 survival0 survival1 transition gap initial]
  unfold discountIncrement
  ring

/--
Patience and survival are complements: increasing `β` has a weakly larger
effect at the higher survival factor.
-/
theorem discountIncrement_mono_survival
    {transition : Matrix State State ℚ}
    (htransition :
      transition ∈ Matrix.rowStochastic ℚ State)
    {gap : State → ℚ} (hgap : ∀ state, 0 ≤ gap state)
    (horizon : Nat)
    {discount0 discount1 survival0 survival1 : ℚ}
    (hdiscount0 : 0 ≤ discount0)
    (hdiscount : discount0 ≤ discount1)
    (hsurvival0 : 0 ≤ survival0)
    (hsurvival : survival0 ≤ survival1)
    (initial : State) :
    discountIncrement horizon discount0 discount1 survival0 transition gap initial ≤
      discountIncrement horizon discount0 discount1 survival1 transition gap initial := by
  have hfactor :
      0 ≤
        ∑ time ∈ Finset.range horizon,
          (discount1 ^ time - discount0 ^ time) *
            (survival1 ^ time - survival0 ^ time) *
            matrixPowerGap transition gap time initial := by
    apply Finset.sum_nonneg
    intro time htime
    have hdiscountPower :
        discount0 ^ time ≤ discount1 ^ time :=
      pow_le_pow_left₀ hdiscount0 hdiscount time
    have hsurvivalPower :
        survival0 ^ time ≤ survival1 ^ time :=
      pow_le_pow_left₀ hsurvival0 hsurvival time
    exact mul_nonneg
      (mul_nonneg (sub_nonneg.mpr hdiscountPower)
        (sub_nonneg.mpr hsurvivalPower))
      (matrixPowerGap_nonnegative htransition hgap time initial)
  rw [← discountIncrement_difference_eq_factorized horizon discount0 discount1
    survival0 survival1 transition gap initial] at hfactor
  linarith

/--
The finite-difference inequality and the four-corner cross-difference
inequality are algebraically equivalent.
-/
theorem discountIncrement_le_iff_crossDifference
    (horizon : Nat)
    (discount0 discount1 survival0 survival1 : ℚ)
    (transition : Matrix State State ℚ) (gap : State → ℚ)
    (initial : State) :
    discountIncrement horizon discount0 discount1 survival0 transition gap initial ≤
        discountIncrement horizon discount0 discount1 survival1 transition gap initial ↔
      finiteHorizonPotential horizon discount1 survival0 transition gap initial +
          finiteHorizonPotential horizon discount0 survival1 transition gap initial ≤
        finiteHorizonPotential horizon discount1 survival1 transition gap initial +
          finiteHorizonPotential horizon discount0 survival0 transition gap initial := by
  unfold discountIncrement
  constructor <;> intro h <;> linarith

/--
Equivalent cross-difference inequality:
`Ψ(β₁,ρ₁) + Ψ(β₀,ρ₀) ≥ Ψ(β₁,ρ₀) + Ψ(β₀,ρ₁)`.
-/
theorem finiteHorizonPotential_crossDifference_nonnegative
    {transition : Matrix State State ℚ}
    (htransition :
      transition ∈ Matrix.rowStochastic ℚ State)
    {gap : State → ℚ} (hgap : ∀ state, 0 ≤ gap state)
    (horizon : Nat)
    {discount0 discount1 survival0 survival1 : ℚ}
    (hdiscount0 : 0 ≤ discount0)
    (hdiscount : discount0 ≤ discount1)
    (hsurvival0 : 0 ≤ survival0)
    (hsurvival : survival0 ≤ survival1)
    (initial : State) :
    finiteHorizonPotential horizon discount1 survival0 transition gap initial +
          finiteHorizonPotential horizon discount0 survival1 transition gap initial ≤
      finiteHorizonPotential horizon discount1 survival1 transition gap initial +
          finiteHorizonPotential horizon discount0 survival0 transition gap initial := by
  rw [← discountIncrement_le_iff_crossDifference horizon discount0 discount1
    survival0 survival1 transition gap initial]
  exact discountIncrement_mono_survival htransition hgap horizon
    hdiscount0 hdiscount hsurvival0 hsurvival initial

/-! ## Exact assumption boundary -/

namespace Counterexamples

/-- The unique one-state stochastic matrix. -/
def oneStateTransition : Matrix (Fin 1) (Fin 1) ℚ :=
  fun _ _ => 1

theorem oneStateTransition_eq_one :
    oneStateTransition = 1 := by
  ext i j
  fin_cases i
  fin_cases j
  simp [oneStateTransition]

theorem oneStateTransition_stochastic :
    oneStateTransition ∈ Matrix.rowStochastic ℚ (Fin 1) := by
  rw [Matrix.mem_rowStochastic_iff_sum]
  constructor
  · intro i j
    norm_num [oneStateTransition]
  · intro i
    simp [oneStateTransition]

/-- Complementarity can fail when the gap vector is negative. -/
theorem crossDifference_fails_without_nonnegativeGap :
    finiteHorizonPotential 2 1 1 oneStateTransition (fun _ : Fin 1 => -1) 0 +
          finiteHorizonPotential 2 0 0 oneStateTransition (fun _ : Fin 1 => -1) 0 <
      finiteHorizonPotential 2 1 0 oneStateTransition (fun _ : Fin 1 => -1) 0 +
          finiteHorizonPotential 2 0 1 oneStateTransition (fun _ : Fin 1 => -1) 0 := by
  norm_num [finiteHorizonPotential, finiteEffectivePotential, effectiveDiscount,
    matrixPowerGap, oneStateTransition_eq_one, Matrix.mulVec, dotProduct]

end Counterexamples

end DiscountSurvivalInteraction

end Coverage

end StrategyInnovation
