import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Rat.BigOperators
import StrategyInnovation.Raw.Library

/-!
# Additive strategy-resource burden

This module adds the conservative outer resource layer without changing the
productive raw process.  Weights are immutable catalog-indexed rationals, the
inactive strategy has zero weight, and every active strategy has positive
weight.  `libraryBurden` is the exact finite sum denoted by `W(L)` in the
optimization specifications.
-/

namespace StrategyInnovation

namespace Optimization

open scoped BigOperators

variable {model : FiniteModel}

/-- Exact immutable resource weights with the mandatory inactive exception. -/
structure StrategyResourceWeights
    (model : FiniteModel) (inactiveStrategy : model.StrategyId) where
  resourceWeight : model.StrategyId → ℚ
  nonnegative : ∀ strategy, 0 ≤ resourceWeight strategy
  inactive_zero : resourceWeight inactiveStrategy = 0
  active_positive : ∀ {strategy}, strategy ≠ inactiveStrategy →
    0 < resourceWeight strategy

/-- Additive resource burden of an arbitrary finite strategy set. -/
def resourceBurden {inactiveStrategy : model.StrategyId}
    (weights : StrategyResourceWeights model inactiveStrategy)
    (strategies : Finset model.StrategyId) : ℚ :=
  strategies.sum weights.resourceWeight

/-- Additive resource burden `W(L)` of an admissible raw library. -/
def libraryBurden {catalog : Raw.StrategyCatalog model}
    (weights : StrategyResourceWeights model catalog.inactiveStrategy)
    (library : Raw.Library catalog) : ℚ :=
  resourceBurden weights library.strategies

/-- The empty finite strategy set has zero additive burden. -/
@[simp]
theorem resourceBurden_empty {inactiveStrategy : model.StrategyId}
    (weights : StrategyResourceWeights model inactiveStrategy) :
    resourceBurden weights ∅ = 0 := by
  simp [resourceBurden]

/-- The admissible library containing only the inactive strategy. -/
def inactiveOnlyLibrary (catalog : Raw.StrategyCatalog model) :
    Raw.Library catalog where
  strategies := {catalog.inactiveStrategy}
  inactive_mem := Finset.mem_singleton_self _

/-- Under the adopted convention, the inactive-only library has zero burden. -/
@[simp]
theorem libraryBurden_inactiveOnly
    (catalog : Raw.StrategyCatalog model)
    (weights : StrategyResourceWeights model catalog.inactiveStrategy) :
    libraryBurden weights (inactiveOnlyLibrary catalog) = 0 := by
  simp [libraryBurden, resourceBurden, inactiveOnlyLibrary,
    weights.inactive_zero]

/-- Additive library burden is nonnegative. -/
theorem libraryBurden_nonnegative
    {catalog : Raw.StrategyCatalog model}
    (weights : StrategyResourceWeights model catalog.inactiveStrategy)
    (library : Raw.Library catalog) :
    0 ≤ libraryBurden weights library := by
  exact Finset.sum_nonneg fun strategy _ => weights.nonnegative strategy

/-- Library inclusion weakly increases additive resource burden. -/
theorem libraryBurden_mono
    {catalog : Raw.StrategyCatalog model}
    (weights : StrategyResourceWeights model catalog.inactiveStrategy)
    {left right : Raw.Library catalog} (hinclude : left ≤ right) :
    libraryBurden weights left ≤ libraryBurden weights right := by
  exact Finset.sum_le_sum_of_subset_of_nonneg hinclude
    (fun strategy _ _ => weights.nonnegative strategy)

/-- Deleting a represented positive-weight strategy strictly lowers burden. -/
theorem libraryBurden_erase_lt
    {catalog : Raw.StrategyCatalog model}
    (weights : StrategyResourceWeights model catalog.inactiveStrategy)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (hmember : strategy ∈ library)
    (hactive : strategy ≠ catalog.inactiveStrategy) :
    libraryBurden weights (library.erase strategy hactive) <
      libraryBurden weights library := by
  have hdecomposition :
      (library.strategies.erase strategy).sum weights.resourceWeight +
          weights.resourceWeight strategy =
        library.strategies.sum weights.resourceWeight :=
    Finset.sum_erase_add _ _ hmember
  change
    (library.strategies.erase strategy).sum weights.resourceWeight <
      library.strategies.sum weights.resourceWeight
  rw [← hdecomposition]
  exact lt_add_of_pos_right _ (weights.active_positive hactive)

end Optimization

end StrategyInnovation
