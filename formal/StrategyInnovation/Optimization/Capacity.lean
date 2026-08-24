import StrategyInnovation.Optimization.SafeCompression

/-!
# Exact resource budgets and capacity feasibility

Capacity is a nonnegative rational outer-retention budget.  It constrains the
initial retained library only and does not modify raw admission or productive
dynamics.
-/

namespace StrategyInnovation

namespace Optimization

variable {model : FiniteModel}
variable {catalog : Raw.StrategyCatalog model}

/-- A nonnegative exact rational resource budget `B`. -/
structure ResourceBudget where
  amount : ℚ
  nonnegative : 0 ≤ amount

/-- A retained library is capacity feasible when `W(L) ≤ B`. -/
def CapacityFeasible
    (weights : StrategyResourceWeights model catalog.inactiveStrategy)
    (budget : ResourceBudget) (library : Raw.Library catalog) : Prop :=
  libraryBurden weights library ≤ budget.amount

/-- Source-relative sublibrary feasibility combined with a hard resource budget. -/
def SublibraryCapacityFeasible
    (weights : StrategyResourceWeights model catalog.inactiveStrategy)
    (budget : ResourceBudget) (source candidate : Raw.Library catalog) : Prop :=
  SublibraryFeasible source candidate ∧
    CapacityFeasible weights budget candidate

/-- Every nonnegative budget admits the inactive-only library. -/
theorem inactiveOnly_capacityFeasible
    (catalog : Raw.StrategyCatalog model)
    (weights : StrategyResourceWeights model catalog.inactiveStrategy)
    (budget : ResourceBudget) :
    CapacityFeasible weights budget (inactiveOnlyLibrary catalog) := by
  simpa [CapacityFeasible] using budget.nonnegative

/-- Increasing the budget preserves capacity feasibility. -/
theorem CapacityFeasible.mono_budget
    {weights : StrategyResourceWeights model catalog.inactiveStrategy}
    {small large : ResourceBudget} (hbudget : small.amount ≤ large.amount)
    {library : Raw.Library catalog}
    (hfeasible : CapacityFeasible weights small library) :
    CapacityFeasible weights large library :=
  hfeasible.trans hbudget

/-- Passing to a sublibrary preserves capacity feasibility. -/
theorem CapacityFeasible.of_sublibrary
    {weights : StrategyResourceWeights model catalog.inactiveStrategy}
    {budget : ResourceBudget} {source candidate : Raw.Library catalog}
    (hinclude : SublibraryFeasible source candidate)
    (hsource : CapacityFeasible weights budget source) :
    CapacityFeasible weights budget candidate :=
  (libraryBurden_mono weights hinclude).trans hsource

end Optimization

end StrategyInnovation
