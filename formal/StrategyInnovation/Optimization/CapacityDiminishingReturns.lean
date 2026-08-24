import StrategyInnovation.Optimization.CapacityValue

/-!
# A separate sufficient condition for discrete diminishing returns

The unconditional finite capacity theorem does not imply concavity or
diminishing marginal capacity value.  This module records only the standard
additive equal-unit sufficient specialization: after independent nonnegative
increments are sorted in weakly decreasing order, the exact value at the
`k`-unit grid point is the baseline plus the first `k` increments.

The result is lattice diminishing returns on this declared grid.  It is not
ordinary concavity of the real-capacity step function and is not exported as
a property of an arbitrary `FiniteCapacityProblem`.
-/

namespace StrategyInnovation

namespace Optimization

/--
Exact sorted-prefix representation induced by additive independent value and
equal positive resource units.
-/
structure AdditiveUnitCapacityProfile where
  baseValue : ℝ
  unitBurden : ℝ
  unitBurden_positive : 0 < unitBurden
  increments : List ℝ
  increments_nonnegative : ∀ increment ∈ increments, 0 ≤ increment
  increments_sorted : increments.Pairwise (fun left right => right ≤ left)

namespace AdditiveUnitCapacityProfile

variable (profile : AdditiveUnitCapacityProfile)

/-- The capacity at grid index `k`. -/
def gridCapacity (k : ℕ) : ℝ :=
  (k : ℝ) * profile.unitBurden

/-- Consecutive grid capacities differ by exactly the common resource unit. -/
theorem gridCapacity_succ (k : ℕ) :
    profile.gridCapacity (k + 1) =
      profile.gridCapacity k + profile.unitBurden := by
  simp [gridCapacity, Nat.cast_add]
  ring

/-- Baseline plus the `k` largest independent increments. -/
def gridValue (k : ℕ) : ℝ :=
  profile.baseValue + (profile.increments.take k).sum

/-- Exact one-unit forward capacity shadow on the declared grid. -/
def gridShadow (k : ℕ) : ℝ :=
  profile.gridValue (k + 1) - profile.gridValue k

/-- The next sorted increment, extended by zero past the finite catalog. -/
def nextIncrement (k : ℕ) : ℝ :=
  (profile.increments[k]?).getD 0

/-- Every extended next increment is nonnegative. -/
theorem nextIncrement_nonnegative (k : ℕ) :
    0 ≤ profile.nextIncrement k := by
  by_cases hk : k < profile.increments.length
  · rw [nextIncrement, List.getElem?_eq_getElem hk]
    simp only [Option.getD_some]
    exact profile.increments_nonnegative profile.increments[k]
      (List.getElem_mem hk)
  · rw [nextIncrement,
      List.getElem?_eq_none (Nat.le_of_not_gt hk)]
    simp

/-- The exact grid shadow is the next sorted increment. -/
theorem gridShadow_eq_nextIncrement (k : ℕ) :
    profile.gridShadow k = profile.nextIncrement k := by
  unfold gridShadow gridValue nextIncrement
  rw [List.take_add_one]
  cases h : profile.increments[k]? <;> simp

/-- Successive sorted increments, including the terminal zeros, cannot rise. -/
theorem nextIncrement_succ_le (k : ℕ) :
    profile.nextIncrement (k + 1) ≤ profile.nextIncrement k := by
  by_cases hnext : k + 1 < profile.increments.length
  · have hk : k < profile.increments.length :=
      (Nat.lt_succ_self k).trans hnext
    have horder :
        profile.increments[k + 1] ≤ profile.increments[k] :=
      (List.pairwise_iff_getElem.mp profile.increments_sorted)
        k (k + 1) hk hnext (Nat.lt_succ_self k)
    unfold nextIncrement
    rw [List.getElem?_eq_getElem hnext,
      List.getElem?_eq_getElem hk]
    simpa using horder
  · unfold nextIncrement
    rw [List.getElem?_eq_none (Nat.le_of_not_gt hnext)]
    simp only [Option.getD_none]
    simpa [nextIncrement] using profile.nextIncrement_nonnegative k

/-- Additive equal-unit grid shadows are weakly nonincreasing. -/
theorem gridShadow_antitone : Antitone profile.gridShadow := by
  apply antitone_nat_of_succ_le
  intro k
  rw [profile.gridShadow_eq_nextIncrement,
    profile.gridShadow_eq_nextIncrement]
  exact profile.nextIncrement_succ_le k

/-- The exact discrete diminishing-returns inequality at every adjacent grid pair. -/
theorem gridShadow_succ_le (k : ℕ) :
    profile.gridShadow (k + 1) ≤ profile.gridShadow k :=
  profile.gridShadow_antitone (Nat.le_succ k)

end AdditiveUnitCapacityProfile

end Optimization

end StrategyInnovation
