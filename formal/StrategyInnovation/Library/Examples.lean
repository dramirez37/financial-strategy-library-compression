import StrategyInnovation.Library.InnovationState
import Mathlib.Tactic.DeriveFintype

/-!
# Foundational examples

These declarations exercise the public foundational interface on a tiny exact
model.  They are examples, not named research theorems.
-/

namespace StrategyInnovation.Examples

inductive ExampleBelief
  | low
  | high
  deriving DecidableEq, Fintype

instance : Nonempty ExampleBelief :=
  ⟨ExampleBelief.low⟩

inductive ExampleStrategy
  | inactive
  | incumbent
  | dominated
  deriving DecidableEq, Fintype

instance : Nonempty ExampleStrategy :=
  ⟨ExampleStrategy.inactive⟩

inductive ExampleModule
  | signal
  deriving DecidableEq, Fintype

instance : Nonempty ExampleModule :=
  ⟨ExampleModule.signal⟩

inductive ExampleProject
  | explore
  deriving DecidableEq, Fintype

instance : Nonempty ExampleProject :=
  ⟨ExampleProject.explore⟩

/-- A two-belief, three-strategy, one-module, one-project finite model. -/
def exampleModel : FiniteModel where
  Belief := ExampleBelief
  StrategyId := ExampleStrategy
  ModuleId := ExampleModule
  ResearchProject := ExampleProject

/-- Exact profiles and module sets for the foundational example. -/
def exampleOperationalProfile : ExampleStrategy → ExampleBelief → ℚ
  | .inactive, _ => 0
  | .incumbent, .low => 1
  | .incumbent, .high => 2
  | .dominated, _ => 0

/-- Module rows for the foundational example. -/
def exampleStrategyModules : ExampleStrategy → Finset ExampleModule
  | .inactive => ∅
  | .incumbent => {ExampleModule.signal}
  | .dominated => {ExampleModule.signal}

/-- Exact profiles and module sets for the foundational example. -/
def exampleCatalog : StrategyCatalog exampleModel where
  operationalProfile := exampleOperationalProfile
  strategyModules := exampleStrategyModules
  inactiveStrategy := ExampleStrategy.inactive
  inactiveProfile := by
    intro belief
    cases belief <;> rfl
  inactiveModules := rfl

/-- The identity closure on the singleton module catalog. -/
def exampleClosure : ModuleClosure exampleModel where
  close := id
  extensive := by
    intro modules
    exact Finset.Subset.refl modules
  monotone := by
    intro left right hinclude
    exact hinclude
  idempotent := by
    intro modules
    rfl

/-- The inactive and incumbent strategies form the example library. -/
def exampleLibrary :
    Library exampleModel exampleCatalog.inactiveStrategy where
  strategies := {ExampleStrategy.inactive, ExampleStrategy.incumbent}
  inactive_mem := by
    change ExampleStrategy.inactive ∈
      ({ExampleStrategy.inactive, ExampleStrategy.incumbent} :
        Finset ExampleStrategy)
    simp

/-- Both module-supplying strategies, plus inactive, form a redundant library. -/
def exampleRedundantLibrary :
    Library exampleModel exampleCatalog.inactiveStrategy where
  strategies :=
    {ExampleStrategy.inactive, ExampleStrategy.incumbent,
      ExampleStrategy.dominated}
  inactive_mem := by
    change ExampleStrategy.inactive ∈
      ({ExampleStrategy.inactive, ExampleStrategy.incumbent,
        ExampleStrategy.dominated} : Finset ExampleStrategy)
    simp

example (belief : exampleModel.Belief) :
    0 ≤ operationalFrontier exampleCatalog exampleLibrary belief :=
  zero_le_operationalFrontier exampleCatalog exampleLibrary belief

example :
    OperationallyRedundant exampleCatalog exampleLibrary
      ExampleStrategy.dominated := by
  intro belief
  change 0 ≤ operationalFrontier exampleCatalog exampleLibrary belief
  exact zero_le_operationalFrontier exampleCatalog exampleLibrary belief

example :
    operationalFrontier exampleCatalog
        (exampleLibrary.insert ExampleStrategy.dominated) =
      operationalFrontier exampleCatalog exampleLibrary :=
  operationalFrontier_insert_of_operationallyRedundant
    exampleCatalog exampleLibrary ExampleStrategy.dominated (by
      intro belief
      change 0 ≤ operationalFrontier exampleCatalog exampleLibrary belief
      exact zero_le_operationalFrontier exampleCatalog exampleLibrary belief)

example :
    rawModuleUnion exampleCatalog exampleLibrary ⊆
      generativeClosure exampleCatalog exampleClosure exampleLibrary :=
  rawModuleUnion_subset_generativeClosure
    exampleCatalog exampleClosure exampleLibrary

example :
    generativeClosure exampleCatalog exampleClosure
        (exampleRedundantLibrary.erase ExampleStrategy.dominated (by
          change ExampleStrategy.dominated ≠ ExampleStrategy.inactive
          decide)) =
      generativeClosure exampleCatalog exampleClosure exampleRedundantLibrary :=
  generativeClosure_erase_of_generativelyRedundant
    exampleCatalog exampleClosure exampleRedundantLibrary
      ExampleStrategy.dominated (by
        change ExampleStrategy.dominated ≠ ExampleStrategy.inactive
        decide) (by
          change {ExampleModule.signal} ⊆
            (({ExampleStrategy.inactive, ExampleStrategy.incumbent,
              ExampleStrategy.dominated} : Finset ExampleStrategy).erase
                ExampleStrategy.dominated).biUnion exampleStrategyModules
          intro moduleId hmodule
          have hmodule' : moduleId = ExampleModule.signal :=
            Finset.mem_singleton.mp hmodule
          subst moduleId
          apply Finset.mem_biUnion.mpr
          refine ⟨ExampleStrategy.incumbent, ?_, ?_⟩
          · simp
          · simp [exampleStrategyModules])

example {left right :
    Library exampleModel exampleCatalog.inactiveStrategy}
    (hstate :
      compressedLibraryState exampleCatalog exampleClosure left =
        compressedLibraryState exampleCatalog exampleClosure right) :
    operationalFrontier exampleCatalog left =
      operationalFrontier exampleCatalog right :=
  operationalFrontier_eq_of_compressedLibraryState_eq
    exampleCatalog exampleClosure hstate

end StrategyInnovation.Examples
