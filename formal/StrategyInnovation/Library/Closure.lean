import Mathlib.Data.Finset.Union
import StrategyInnovation.Library.Library

/-!
# Module unions and generative closure

The module closure interface records exactly extensivity, monotonicity, and
idempotence.  Generative redundancy is defined relative to single-strategy
deletion, matching the foundational half of the innovation-safe deletion
criterion.
-/

namespace StrategyInnovation

/-- An extensive, monotone, idempotent closure on finite module sets. -/
structure ModuleClosure (model : FiniteModel) where
  close : Finset model.ModuleId → Finset model.ModuleId
  extensive : ∀ modules, modules ⊆ close modules
  monotone : ∀ {left right}, left ⊆ right → close left ⊆ close right
  idempotent : ∀ modules, close (close modules) = close modules

/-- The union of all module sets supplied by strategies in a library. -/
def rawModuleUnion {model : FiniteModel} (catalog : StrategyCatalog model)
    (library : Library model catalog.inactiveStrategy) :
    Finset model.ModuleId :=
  library.strategies.biUnion catalog.strategyModules

/-- Membership in the raw module union has a supplying strategy witness. -/
theorem mem_rawModuleUnion {model : FiniteModel}
    (catalog : StrategyCatalog model)
    (library : Library model catalog.inactiveStrategy)
    (moduleId : model.ModuleId) :
    moduleId ∈ rawModuleUnion catalog library ↔
      ∃ strategy ∈ library,
        moduleId ∈ catalog.strategyModules strategy := by
  simp [rawModuleUnion]

/-- Library inclusion weakly increases the raw module union. -/
theorem rawModuleUnion_mono {model : FiniteModel}
    (catalog : StrategyCatalog model)
    {left right : Library model catalog.inactiveStrategy}
    (hinclude : left ≤ right) :
    rawModuleUnion catalog left ⊆ rawModuleUnion catalog right :=
  Finset.biUnion_subset_biUnion_of_subset_left _ hinclude

/-- The generative closure of a library's raw module union. -/
def generativeClosure {model : FiniteModel} (catalog : StrategyCatalog model)
    (closure : ModuleClosure model)
    (library : Library model catalog.inactiveStrategy) :
    Finset model.ModuleId :=
  closure.close (rawModuleUnion catalog library)

/-- Every raw module remains available in the generative closure. -/
theorem rawModuleUnion_subset_generativeClosure {model : FiniteModel}
    (catalog : StrategyCatalog model) (closure : ModuleClosure model)
    (library : Library model catalog.inactiveStrategy) :
    rawModuleUnion catalog library ⊆
      generativeClosure catalog closure library :=
  closure.extensive _

/-- Library inclusion weakly increases generative closure. -/
theorem generativeClosure_mono {model : FiniteModel}
    (catalog : StrategyCatalog model) (closure : ModuleClosure model)
    {left right : Library model catalog.inactiveStrategy}
    (hinclude : left ≤ right) :
    generativeClosure catalog closure left ⊆
      generativeClosure catalog closure right :=
  closure.monotone (rawModuleUnion_mono catalog hinclude)

/--
A strategy is generatively redundant when all its modules are already in the
closure obtained after deleting that strategy.
-/
def GenerativelyRedundant {model : FiniteModel}
    (catalog : StrategyCatalog model) (closure : ModuleClosure model)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hstrategy : strategy ≠ catalog.inactiveStrategy) : Prop :=
  catalog.strategyModules strategy ⊆
    generativeClosure catalog closure (library.erase strategy hstrategy)

/-- Removing one generatively redundant strategy preserves generative closure. -/
theorem generativeClosure_erase_of_generativelyRedundant
    {model : FiniteModel} (catalog : StrategyCatalog model)
    (closure : ModuleClosure model)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hstrategy : strategy ≠ catalog.inactiveStrategy)
    (hredundant :
      GenerativelyRedundant catalog closure library strategy hstrategy) :
    generativeClosure catalog closure (library.erase strategy hstrategy) =
      generativeClosure catalog closure library := by
  apply Finset.Subset.antisymm
  · exact generativeClosure_mono catalog closure
      (Library.erase_le library strategy hstrategy)
  · have hunion :
        rawModuleUnion catalog library ⊆
          generativeClosure catalog closure
            (library.erase strategy hstrategy) := by
      intro moduleId hmodule
      rcases (mem_rawModuleUnion catalog library moduleId).mp hmodule with
        ⟨supplier, hsupplier, hsupplies⟩
      by_cases heq : supplier = strategy
      · subst supplier
        exact hredundant hsupplies
      · apply rawModuleUnion_subset_generativeClosure catalog closure
        apply (mem_rawModuleUnion catalog
          (library.erase strategy hstrategy) moduleId).2
        exact ⟨supplier, (Library.mem_erase hstrategy).2 ⟨heq, hsupplier⟩,
          hsupplies⟩
    have hclosed :
        closure.close (rawModuleUnion catalog library) ⊆
          closure.close
            (generativeClosure catalog closure
              (library.erase strategy hstrategy)) :=
      closure.monotone hunion
    simpa [generativeClosure, closure.idempotent] using hclosed

end StrategyInnovation
