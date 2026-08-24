import StrategyInnovation.Library.Closure
import StrategyInnovation.Library.Frontier

/-!
# Compressed library states

The foundational compressed state retains exactly the pointwise operational
frontier and the generative module closure.
-/

namespace StrategyInnovation

/-- The operational-frontier/generative-closure pair of a finite library. -/
structure InnovationState (model : FiniteModel) where
  frontier : model.Belief → ℚ
  closure : Finset model.ModuleId

/-- Compress a raw finite library to its operational and generative state. -/
def compressedLibraryState {model : FiniteModel}
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (library : Library model catalog.inactiveStrategy) :
    InnovationState model where
  frontier := operationalFrontier catalog library
  closure := generativeClosure catalog moduleClosure library

/-- Equal compressed states have equal operational frontiers. -/
theorem operationalFrontier_eq_of_compressedLibraryState_eq
    {model : FiniteModel} (catalog : StrategyCatalog model)
    (moduleClosure : ModuleClosure model)
    {left right : Library model catalog.inactiveStrategy}
    (hstate :
      compressedLibraryState catalog moduleClosure left =
        compressedLibraryState catalog moduleClosure right) :
    operationalFrontier catalog left =
      operationalFrontier catalog right :=
  congrArg InnovationState.frontier hstate

/-- Equal compressed states have equal generative closures. -/
theorem generativeClosure_eq_of_compressedLibraryState_eq
    {model : FiniteModel} (catalog : StrategyCatalog model)
    (moduleClosure : ModuleClosure model)
    {left right : Library model catalog.inactiveStrategy}
    (hstate :
      compressedLibraryState catalog moduleClosure left =
        compressedLibraryState catalog moduleClosure right) :
    generativeClosure catalog moduleClosure left =
      generativeClosure catalog moduleClosure right :=
  congrArg InnovationState.closure hstate

end StrategyInnovation
