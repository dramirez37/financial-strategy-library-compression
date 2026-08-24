import Mathlib.Data.Fintype.OfMap
import Mathlib.Data.Fintype.Powerset
import StrategyInnovation.Library.Strategy

/-!
# Finite verified libraries

An admissible library is a finite set of strategy identifiers containing the
distinguished inactive strategy.  Candidate insertion and noninactive deletion
preserve admissibility.
-/

namespace StrategyInnovation

/-- A finite strategy library containing its distinguished inactive strategy. -/
structure Library (model : FiniteModel) (inactiveStrategy : model.StrategyId) where
  strategies : Finset model.StrategyId
  inactive_mem : inactiveStrategy ∈ strategies

namespace Library

variable {model : FiniteModel} {inactiveStrategy : model.StrategyId}

/-- Two libraries are equal when their finite strategy sets are equal. -/
@[ext]
theorem ext {left right : Library model inactiveStrategy}
    (h : left.strategies = right.strategies) : left = right := by
  cases left
  cases right
  cases h
  rfl

instance : Membership model.StrategyId (Library model inactiveStrategy) where
  mem library strategy := strategy ∈ library.strategies

@[simp]
theorem mem_strategies {library : Library model inactiveStrategy}
    {strategy : model.StrategyId} :
    strategy ∈ library.strategies ↔ strategy ∈ library :=
  Iff.rfl

@[simp]
theorem inactive_mem' (library : Library model inactiveStrategy) :
    inactiveStrategy ∈ library :=
  library.inactive_mem

/-- Enumerate admissible libraries through their finite strategy sets. -/
noncomputable instance : Fintype (Library model inactiveStrategy) :=
  Fintype.ofInjective Library.strategies fun _ _ hstrategies =>
    ext hstrategies

instance : PartialOrder (Library model inactiveStrategy) where
  le left right := left.strategies ⊆ right.strategies
  le_refl _ := Finset.Subset.refl _
  le_trans _ _ _ := Finset.Subset.trans
  le_antisymm left right hleft hright :=
    ext (Finset.Subset.antisymm hleft hright)

/-- Library inclusion is inclusion of the underlying finite strategy sets. -/
theorem le_def {left right : Library model inactiveStrategy} :
    left ≤ right ↔ left.strategies ⊆ right.strategies :=
  Iff.rfl

/-- Insert one verified strategy into an admissible library. -/
def insert (strategy : model.StrategyId)
    (library : Library model inactiveStrategy) :
    Library model inactiveStrategy where
  strategies := Insert.insert strategy library.strategies
  inactive_mem := Finset.mem_insert_of_mem library.inactive_mem

@[simp]
theorem strategies_insert (strategy : model.StrategyId)
    (library : Library model inactiveStrategy) :
    (library.insert strategy).strategies =
      Insert.insert strategy library.strategies :=
  rfl

@[simp]
theorem mem_insert {strategy candidate : model.StrategyId}
    {library : Library model inactiveStrategy} :
    strategy ∈ library.insert candidate ↔
      strategy = candidate ∨ strategy ∈ library := by
  change strategy ∈ Insert.insert candidate library.strategies ↔
    strategy = candidate ∨ strategy ∈ library.strategies
  exact Finset.mem_insert

/-- Every library is included in the result of inserting a strategy. -/
theorem le_insert (library : Library model inactiveStrategy)
    (strategy : model.StrategyId) :
    library ≤ library.insert strategy := by
  change library.strategies ⊆ Insert.insert strategy library.strategies
  intro candidate hcandidate
  exact Finset.mem_insert_of_mem hcandidate

/--
Remove a noninactive strategy from a library.

The inequality hypothesis is proof-relevant only for constructing the retained
inactive-membership certificate.
-/
def erase (library : Library model inactiveStrategy)
    (strategy : model.StrategyId) (hstrategy : strategy ≠ inactiveStrategy) :
    Library model inactiveStrategy where
  strategies := library.strategies.erase strategy
  inactive_mem :=
    Finset.mem_erase.mpr ⟨hstrategy.symm, library.inactive_mem⟩

@[simp]
theorem strategies_erase (library : Library model inactiveStrategy)
    (strategy : model.StrategyId) (hstrategy : strategy ≠ inactiveStrategy) :
    (library.erase strategy hstrategy).strategies =
      library.strategies.erase strategy :=
  rfl

@[simp]
theorem mem_erase {library : Library model inactiveStrategy}
    {strategy candidate : model.StrategyId}
    (hstrategy : strategy ≠ inactiveStrategy) :
    candidate ∈ library.erase strategy hstrategy ↔
      candidate ≠ strategy ∧ candidate ∈ library := by
  change candidate ∈ library.strategies.erase strategy ↔
    candidate ≠ strategy ∧ candidate ∈ library.strategies
  exact Finset.mem_erase

/-- Deleting a noninactive strategy produces a sublibrary. -/
theorem erase_le (library : Library model inactiveStrategy)
    (strategy : model.StrategyId) (hstrategy : strategy ≠ inactiveStrategy) :
    library.erase strategy hstrategy ≤ library := by
  intro candidate hcandidate
  exact (Finset.mem_erase.mp hcandidate).2

end Library

end StrategyInnovation
