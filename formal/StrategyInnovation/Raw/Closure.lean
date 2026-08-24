import StrategyInnovation.Library.Closure
import StrategyInnovation.Raw.ModuleSet

/-!
# Raw module closure

The raw layer reuses the extensive, monotone, idempotent finite closure
operator.  The closure-absorption identity is the algebraic step needed for a
local compressed update after one admitted candidate.
-/

namespace StrategyInnovation.Raw

/-- The raw module closure operator. -/
abbrev ClosureOperator (model : FiniteModel) := ModuleClosure model

/-- Closing an already closed base before adjoining modules changes nothing. -/
theorem closure_absorption {model : FiniteModel}
    (closure : Raw.ClosureOperator model)
    (base added : Raw.ModuleSet model) :
    closure.close (closure.close base ∪ added) =
      closure.close (base ∪ added) := by
  apply Finset.Subset.antisymm
  · have hinner :
        closure.close base ∪ added ⊆ closure.close (base ∪ added) := by
      apply Finset.union_subset
      · exact closure.monotone Finset.subset_union_left
      · exact Finset.subset_union_right.trans (closure.extensive _)
    calc
      closure.close (closure.close base ∪ added) ⊆
          closure.close (closure.close (base ∪ added)) :=
        closure.monotone hinner
      _ = closure.close (base ∪ added) := closure.idempotent _
  · apply closure.monotone
    apply Finset.union_subset
    · exact (closure.extensive base).trans Finset.subset_union_left
    · exact Finset.subset_union_right

end StrategyInnovation.Raw
