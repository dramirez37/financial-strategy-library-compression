import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Data.Finsupp.Basic
import Mathlib.Data.Finsupp.Single
import Mathlib.Tactic.NormNum

/-!
# Exact finitely supported rational distributions

The abstract dynamic layer uses exact rational mass functions with finite
support.  The carrier need not itself be finite; this permits transitions on
the ambient compressed-state type while retaining finite sums.
-/

namespace StrategyInnovation

universe u

/-- An exact, finitely supported rational probability distribution. -/
structure RatProb (α : Type u) where
  mass : α →₀ ℚ
  nonnegative : ∀ outcome, 0 ≤ mass outcome
  totalMass : mass.sum (fun _ probability => probability) = 1

namespace RatProb

variable {α : Type u}

/-- Two exact distributions are equal when their mass functions are equal. -/
@[ext]
theorem ext {left right : RatProb α} (hmass : left.mass = right.mass) :
    left = right := by
  cases left
  cases right
  cases hmass
  rfl

/-- The exact probability assigned to one outcome. -/
def probability (distribution : RatProb α) (outcome : α) : ℚ :=
  distribution.mass outcome

/-- Exact expectation of a rational-valued function under finite support. -/
def expectation (distribution : RatProb α) (value : α → ℚ) : ℚ :=
  distribution.mass.sum fun outcome probability =>
    probability * value outcome

/-- Pointwise-equal value functions have equal exact expectations. -/
theorem expectation_congr (distribution : RatProb α)
    {left right : α → ℚ} (hvalue : ∀ outcome, left outcome = right outcome) :
    distribution.expectation left = distribution.expectation right := by
  have hfunction : left = right := funext hvalue
  cases hfunction
  rfl

/-- The exact point mass at one outcome. -/
noncomputable def dirac (outcome : α) : RatProb α where
  mass := Finsupp.single outcome 1
  nonnegative := by
    intro other
    classical
    simp only [Finsupp.single_apply]
    split <;> norm_num
  totalMass := by
    simp

@[simp]
theorem expectation_dirac (outcome : α) (value : α → ℚ) :
    (dirac outcome).expectation value = value outcome := by
  simp [expectation, dirac]

end RatProb

end StrategyInnovation
