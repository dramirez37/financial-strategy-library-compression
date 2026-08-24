import StrategyInnovation.Library.InnovationState
import StrategyInnovation.Raw.Closure
import StrategyInnovation.Raw.LibraryUpdate

/-!
# Local compressed-library updates

This module derives the local frontier--closure update from the raw set-valued
library operation.  It does not introduce or alter any primitive transition
kernel.
-/

namespace StrategyInnovation.Raw

variable {model : FiniteModel}

/-- Inserting a candidate updates the raw module union by finite union. -/
theorem rawModuleUnion_insert
    (catalog : Raw.StrategyCatalog model) (library : Raw.Library catalog)
    (strategy : model.StrategyId) :
    rawModuleUnion catalog (library.insert strategy) =
      rawModuleUnion catalog library ∪ catalog.strategyModules strategy := by
  ext moduleId
  simp [rawModuleUnion, or_comm]

/-- Inserting a candidate closes the old closure together with its module row. -/
theorem generativeClosure_insert
    (catalog : Raw.StrategyCatalog model)
    (closure : Raw.ClosureOperator model)
    (library : Raw.Library catalog) (strategy : model.StrategyId) :
    generativeClosure catalog closure (library.insert strategy) =
      closure.close
        (generativeClosure catalog closure library ∪
          catalog.strategyModules strategy) := by
  calc
    generativeClosure catalog closure (library.insert strategy) =
        closure.close
          (rawModuleUnion catalog library ∪ catalog.strategyModules strategy) := by
      rw [generativeClosure, rawModuleUnion_insert]
    _ = closure.close
          (closure.close (rawModuleUnion catalog library) ∪
            catalog.strategyModules strategy) :=
      (closure_absorption closure (rawModuleUnion catalog library)
        (catalog.strategyModules strategy)).symm
    _ = closure.close
          (generativeClosure catalog closure library ∪
            catalog.strategyModules strategy) := rfl

/-- Candidate insertion updates the operational frontier by pointwise maximum. -/
theorem operationalFrontier_insert
    (catalog : Raw.StrategyCatalog model) (library : Raw.Library catalog)
    (strategy : model.StrategyId) :
    operationalFrontier catalog (library.insert strategy) =
      fun belief =>
        max (operationalFrontier catalog library belief)
          (catalog.operationalProfile strategy belief) := by
  funext belief
  apply le_antisymm
  · apply (operationalFrontier_le_iff catalog (library.insert strategy) belief _).2
    intro candidate hcandidate
    rcases (StrategyInnovation.Library.mem_insert.mp hcandidate) with rfl | hmember
    · exact le_max_right _ _
    · exact (operationalProfile_le_frontier catalog library hmember belief).trans
        (le_max_left _ _)
  · apply max_le
    · exact operationalFrontier_mono catalog
        (StrategyInnovation.Library.le_insert library strategy) belief
    · exact operationalProfile_le_frontier catalog (library.insert strategy)
        (StrategyInnovation.Library.mem_insert.mpr (Or.inl rfl)) belief

/-- Apply an admitted outcome directly to an ambient compressed state. -/
def addCompressedState
    (catalog : Raw.StrategyCatalog model)
    (closure : Raw.ClosureOperator model)
    (state : InnovationState model) :
    Raw.CandidateOutcome model → InnovationState model
  | none => state
  | some strategy =>
      { frontier := fun belief =>
          max (state.frontier belief)
            (catalog.operationalProfile strategy belief)
        closure := closure.close
          (state.closure ∪ catalog.strategyModules strategy) }

@[simp]
theorem addCompressedState_none
    (catalog : Raw.StrategyCatalog model)
    (closure : Raw.ClosureOperator model)
    (state : InnovationState model) :
    addCompressedState catalog closure state none = state :=
  rfl

@[simp]
theorem addCompressedState_some
    (catalog : Raw.StrategyCatalog model)
    (closure : Raw.ClosureOperator model)
    (state : InnovationState model) (strategy : model.StrategyId) :
    addCompressedState catalog closure state (some strategy) =
      { frontier := fun belief =>
          max (state.frontier belief)
            (catalog.operationalProfile strategy belief)
        closure := closure.close
          (state.closure ∪ catalog.strategyModules strategy) } :=
  rfl

/--
Compression commutes with one raw admitted-candidate update (RC1).

This is the local raw-to-compressed identity only; it does not modify or rely
on an abstract primitive transition theorem.
-/
theorem compressedLibraryState_rawLibraryUpdate
    (catalog : Raw.StrategyCatalog model)
    (closure : Raw.ClosureOperator model)
    (library : Raw.Library catalog) (outcome : Raw.CandidateOutcome model) :
    compressedLibraryState catalog closure (rawLibraryUpdate library outcome) =
      addCompressedState catalog closure
        (compressedLibraryState catalog closure library) outcome := by
  cases outcome with
  | none => rfl
  | some strategy =>
      change
        InnovationState.mk
            (operationalFrontier catalog (library.insert strategy))
            (generativeClosure catalog closure (library.insert strategy)) =
          InnovationState.mk
            (fun belief =>
              max (operationalFrontier catalog library belief)
                (catalog.operationalProfile strategy belief))
            (closure.close
              (generativeClosure catalog closure library ∪
                catalog.strategyModules strategy))
      rw [operationalFrontier_insert, generativeClosure_insert]

end StrategyInnovation.Raw
