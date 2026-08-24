import Mathlib.Tactic
import StrategyInnovation.Optimization.SafeCompression

/-!
# Exact counterexample to global optimality of rechecked safe deletion

This file gives Lean counterparts of two registered Julia fixtures.  Under
unit active weights it instantiates `CX-OPT-PRUNE-CARDINALITY-01`: deleting
the bundle first leaves a one-deletion-irreducible pair, but retaining the
bundle alone has strictly smaller burden.  Under weights `(2, 2, 3)` it also
instantiates `CX-OPT-GREEDY-WEIGHT-01`: the bundle is the unique heaviest
safely deletable strategy, yet deleting it first is globally suboptimal.
-/

namespace StrategyInnovation

namespace Optimization

namespace SafeCompressionCounterexample

inductive Belief
  | only
  deriving DecidableEq, Fintype

instance : Nonempty Belief := ⟨Belief.only⟩

inductive Strategy
  | inactive
  | singletonOne
  | singletonTwo
  | bundle
  deriving DecidableEq, Fintype

instance : Nonempty Strategy := ⟨Strategy.inactive⟩

inductive Module
  | first
  | second
  deriving DecidableEq, Fintype

instance : Nonempty Module := ⟨Module.first⟩

inductive Project
  | probe
  deriving DecidableEq, Fintype

instance : Nonempty Project := ⟨Project.probe⟩

/-- Exact finite carriers of the registered greedy counterexample. -/
abbrev exampleModel : FiniteModel where
  Belief := Belief
  StrategyId := Strategy
  ModuleId := Module
  ResearchProject := Project

def profile : Strategy → Belief → ℚ := fun _ _ => 0

def modules : Strategy → Finset Module
  | .inactive => ∅
  | .singletonOne => {Module.first}
  | .singletonTwo => {Module.second}
  | .bundle => {Module.first, Module.second}

abbrev exampleCatalog : Raw.StrategyCatalog exampleModel where
  operationalProfile := profile
  strategyModules := modules
  inactiveStrategy := Strategy.inactive
  inactiveProfile := by intro belief; rfl
  inactiveModules := rfl

abbrev identityClosure : Raw.ClosureOperator exampleModel where
  close := id
  extensive := fun _ => Finset.Subset.refl _
  monotone := fun hinclude => hinclude
  idempotent := fun _ => rfl

def weight : Strategy → ℚ
  | .inactive => 0
  | .singletonOne => 1
  | .singletonTwo => 1
  | .bundle => 1

/-- Zero inactive weight and common unit active weight. -/
def exampleWeights :
    StrategyResourceWeights exampleModel exampleCatalog.inactiveStrategy where
  resourceWeight := weight
  nonnegative := by intro strategy; cases strategy <;> norm_num [weight]
  inactive_zero := rfl
  active_positive := by
    intro strategy hactive
    cases strategy <;> simp_all [weight]

def greedyWeight : Strategy → ℚ
  | .inactive => 0
  | .singletonOne => 2
  | .singletonTwo => 2
  | .bundle => 3

/-- The exact `(2, 2, 3)` weights from the strict-heaviest Julia fixture. -/
def greedyWeights :
    StrategyResourceWeights exampleModel exampleCatalog.inactiveStrategy where
  resourceWeight := greedyWeight
  nonnegative := by intro strategy; cases strategy <;> norm_num [greedyWeight]
  inactive_zero := rfl
  active_positive := by
    intro strategy hactive
    cases strategy <;> simp_all [greedyWeight]

/-- Source with both singleton carriers and their bundle. -/
def sourceLibrary : Raw.Library exampleCatalog where
  strategies :=
    {Strategy.inactive, Strategy.singletonOne,
      Strategy.singletonTwo, Strategy.bundle}
  inactive_mem := by simp

/-- The bundle-first rechecked endpoint. -/
def pairLibrary : Raw.Library exampleCatalog where
  strategies :=
    {Strategy.inactive, Strategy.singletonOne, Strategy.singletonTwo}
  inactive_mem := by simp

/-- The globally lighter exact-safe competitor. -/
def bundleLibrary : Raw.Library exampleCatalog where
  strategies := {Strategy.inactive, Strategy.bundle}
  inactive_mem := by simp

theorem pair_le_source : pairLibrary ≤ sourceLibrary := by
  intro strategy hstrategy
  change strategy ∈ pairLibrary.strategies at hstrategy
  simp [pairLibrary] at hstrategy
  rcases hstrategy with rfl | rfl | rfl <;> simp [sourceLibrary]

theorem bundle_le_source : bundleLibrary ≤ sourceLibrary := by
  intro strategy hstrategy
  change strategy ∈ bundleLibrary.strategies at hstrategy
  simp [bundleLibrary] at hstrategy
  rcases hstrategy with rfl | rfl <;> simp [sourceLibrary]

theorem source_erase_bundle :
    sourceLibrary.erase Strategy.bundle (by decide) = pairLibrary := by
  apply Library.ext
  decide

/-- Every library in the example has the same zero operational frontier. -/
theorem operationalFrontier_eq_zero (library : Raw.Library exampleCatalog) :
    operationalFrontier exampleCatalog library = fun _ => 0 := by
  funext belief
  apply le_antisymm
  · apply (operationalFrontier_le_iff exampleCatalog library belief 0).2
    intro strategy _
    simp [profile]
  · exact zero_le_operationalFrontier exampleCatalog library belief

theorem source_closure :
    generativeClosure exampleCatalog identityClosure sourceLibrary =
      {Module.first, Module.second} := by
  ext moduleId
  cases moduleId <;>
    simp [generativeClosure, rawModuleUnion, sourceLibrary,
      exampleCatalog, modules]

theorem pair_closure :
    generativeClosure exampleCatalog identityClosure pairLibrary =
      {Module.first, Module.second} := by
  ext moduleId
  cases moduleId <;>
    simp [generativeClosure, rawModuleUnion, pairLibrary,
      exampleCatalog, modules]

theorem bundle_closure :
    generativeClosure exampleCatalog identityClosure bundleLibrary =
      {Module.first, Module.second} := by
  ext moduleId
  cases moduleId <;>
    simp [generativeClosure, rawModuleUnion, bundleLibrary,
      exampleCatalog, modules]

theorem pair_erase_singletonOne_closure :
    generativeClosure exampleCatalog identityClosure
        (pairLibrary.erase Strategy.singletonOne (by decide)) =
      {Module.second} := by
  decide

theorem pair_erase_singletonTwo_closure :
    generativeClosure exampleCatalog identityClosure
        (pairLibrary.erase Strategy.singletonTwo (by decide)) =
      {Module.first} := by
  decide

theorem pair_state_eq_source :
    compressedLibraryState exampleCatalog identityClosure pairLibrary =
      compressedLibraryState exampleCatalog identityClosure sourceLibrary := by
  unfold compressedLibraryState
  rw [operationalFrontier_eq_zero, operationalFrontier_eq_zero,
    pair_closure, source_closure]

theorem bundle_state_eq_source :
    compressedLibraryState exampleCatalog identityClosure bundleLibrary =
      compressedLibraryState exampleCatalog identityClosure sourceLibrary := by
  unfold compressedLibraryState
  rw [operationalFrontier_eq_zero, operationalFrontier_eq_zero,
    bundle_closure, source_closure]

/-- The Julia fixture's bundle deletion is structurally safe at the source. -/
theorem bundle_safeDeletion :
    ExactSafeDeletion exampleCatalog identityClosure sourceLibrary
      Strategy.bundle (by decide) := by
  constructor
  · change Strategy.bundle ∈ sourceLibrary.strategies
    simp [sourceLibrary]
  · simpa [source_erase_bundle] using pair_state_eq_source

theorem bundle_operationallyRedundant :
    Projection.Model.operationallyRedundant sourceLibrary
      Strategy.bundle (by decide) := by
  exact operationalFrontier_eq_of_compressedLibraryState_eq
    exampleCatalog identityClosure bundle_safeDeletion.2

theorem bundle_generativelyRedundant :
    Projection.Model.generativelyRedundant (closure := identityClosure)
      sourceLibrary Strategy.bundle (by decide) := by
  exact generativeClosure_eq_of_compressedLibraryState_eq
    exampleCatalog identityClosure bundle_safeDeletion.2

/-- The registered one-step trace rechecks safety before deleting the bundle. -/
theorem bundleFirst_recheckedSequence :
    Projection.Model.RedundantDeletionSequence exampleCatalog identityClosure
      sourceLibrary [Strategy.bundle] pairLibrary := by
  apply Projection.Model.RedundantDeletionSequence.cons
    sourceLibrary Strategy.bundle (by decide)
    bundle_operationallyRedundant bundle_generativelyRedundant
  simpa [source_erase_bundle] using
    (Projection.Model.RedundantDeletionSequence.nil pairLibrary)

/-- The bundle-first endpoint remains exact-safe relative to the source. -/
theorem pair_safeCompressionFeasible :
    SafeCompressionFeasible exampleCatalog identityClosure
      sourceLibrary pairLibrary :=
  recheckedSafeDeletionEndpoint_feasible bundleFirst_recheckedSequence

/-- The bundle-only competitor is also exact-safe relative to the source. -/
theorem bundle_safeCompressionFeasible :
    SafeCompressionFeasible exampleCatalog identityClosure
      sourceLibrary bundleLibrary :=
  ⟨bundle_le_source, bundle_state_eq_source⟩

theorem pair_weight_eq_two :
    libraryBurden exampleWeights pairLibrary = 2 := by
  change
    ({Strategy.inactive, Strategy.singletonOne, Strategy.singletonTwo} :
      Finset Strategy).sum weight = 2
  rw [Finset.sum_insert]
  · rw [Finset.sum_insert]
    · norm_num [weight]
    · simp
  · simp

theorem bundle_weight_eq_one :
    libraryBurden exampleWeights bundleLibrary = 1 := by
  norm_num [libraryBurden, resourceBurden, bundleLibrary, exampleWeights, weight]

theorem greedy_pair_weight_eq_four :
    libraryBurden greedyWeights pairLibrary = 4 := by
  change
    ({Strategy.inactive, Strategy.singletonOne, Strategy.singletonTwo} :
      Finset Strategy).sum greedyWeight = 4
  rw [Finset.sum_insert]
  · rw [Finset.sum_insert]
    · norm_num [greedyWeight]
    · simp
  · simp

theorem greedy_bundle_weight_eq_three :
    libraryBurden greedyWeights bundleLibrary = 3 := by
  norm_num [libraryBurden, resourceBurden, bundleLibrary, greedyWeights,
    greedyWeight]

/-- At the source, the bundle is the unique heaviest safely deletable strategy. -/
theorem bundle_is_uniqueHeaviestSafeDeletion :
    ExactSafeDeletion exampleCatalog identityClosure sourceLibrary
        Strategy.bundle (by decide) ∧
      ∀ (strategy : Strategy)
        (hactive : strategy ≠ exampleCatalog.inactiveStrategy),
        ExactSafeDeletion exampleCatalog identityClosure sourceLibrary
            strategy hactive →
          strategy ≠ Strategy.bundle →
            greedyWeights.resourceWeight strategy <
              greedyWeights.resourceWeight Strategy.bundle := by
  refine ⟨bundle_safeDeletion, ?_⟩
  intro strategy hactive _ hnotBundle
  cases strategy <;> simp_all [greedyWeights, greedyWeight] <;> norm_num

/-- No active strategy is safely deletable from the two-singleton endpoint. -/
theorem pair_oneDeletionIrreducible :
    OneDeletionIrreducible exampleCatalog identityClosure pairLibrary := by
  intro strategy hactive hsafe
  cases strategy with
  | inactive => exact hactive rfl
  | singletonOne =>
      have hclosure := generativeClosure_eq_of_compressedLibraryState_eq
        exampleCatalog identityClosure hsafe.2
      have hmembership := congrArg
        (fun modules : Finset Module => Module.first ∈ modules) hclosure
      rw [pair_erase_singletonOne_closure, pair_closure] at hmembership
      simp at hmembership
  | singletonTwo =>
      have hclosure := generativeClosure_eq_of_compressedLibraryState_eq
        exampleCatalog identityClosure hsafe.2
      have hmembership := congrArg
        (fun modules : Finset Module => Module.second ∈ modules) hclosure
      rw [pair_erase_singletonTwo_closure, pair_closure] at hmembership
      simp at hmembership
  | bundle =>
      have hmember := hsafe.1
      change Strategy.bundle ∈ pairLibrary.strategies at hmember
      simp [pairLibrary] at hmember

/-- The irreducible rechecked endpoint is not a global minimum-weight solution. -/
theorem pair_not_minimumWeightSafeCompression :
    ¬ MinimumWeightSafeCompression exampleCatalog identityClosure exampleWeights
      sourceLibrary pairLibrary := by
  intro hminimum
  have hle := hminimum.2 bundleLibrary bundle_safeCompressionFeasible
  rw [pair_weight_eq_two, bundle_weight_eq_one] at hle
  norm_num at hle

/--
T4 boundary: a complete rechecked safe-deletion endpoint can be feasible and
one-deletion irreducible without being globally minimum weight.
-/
theorem recheckedEndpoint_need_not_be_globallyMinimum :
    ∃ endpoint : Raw.Library exampleCatalog,
      ∃ deletions : List Strategy,
        Projection.Model.RedundantDeletionSequence exampleCatalog identityClosure
            sourceLibrary deletions endpoint ∧
          SafeCompressionFeasible exampleCatalog identityClosure
            sourceLibrary endpoint ∧
          OneDeletionIrreducible exampleCatalog identityClosure endpoint ∧
          ¬ MinimumWeightSafeCompression exampleCatalog identityClosure
            exampleWeights sourceLibrary endpoint :=
  ⟨pairLibrary, [Strategy.bundle], bundleFirst_recheckedSequence,
    pair_safeCompressionFeasible, pair_oneDeletionIrreducible,
    pair_not_minimumWeightSafeCompression⟩

/--
Exact registered counterexample to global greedy optimality: the fixture's
bundle-first safe trace terminates locally but is beaten by the bundle-only
safe library of burden one.
-/
theorem bundleFirst_rechecked_not_globallyOptimal :
    Projection.Model.RedundantDeletionSequence exampleCatalog identityClosure
        sourceLibrary [Strategy.bundle] pairLibrary ∧
      OneDeletionIrreducible exampleCatalog identityClosure pairLibrary ∧
      SafeCompressionFeasible exampleCatalog identityClosure
        sourceLibrary bundleLibrary ∧
      libraryBurden exampleWeights bundleLibrary <
        libraryBurden exampleWeights pairLibrary := by
  refine ⟨bundleFirst_recheckedSequence, pair_oneDeletionIrreducible,
    bundle_safeCompressionFeasible, ?_⟩
  rw [pair_weight_eq_two, bundle_weight_eq_one]
  norm_num

/--
Exact strict-heaviest greedy counterexample from `CX-OPT-GREEDY-WEIGHT-01`.
The uniquely heaviest safe first deletion terminates at burden four, while a
safe bundle-only library has burden three.
-/
theorem strictHeaviestFirst_greedy_not_globallyOptimal :
    (ExactSafeDeletion exampleCatalog identityClosure sourceLibrary
        Strategy.bundle (by decide) ∧
      ∀ (strategy : Strategy)
        (hactive : strategy ≠ exampleCatalog.inactiveStrategy),
        ExactSafeDeletion exampleCatalog identityClosure sourceLibrary
            strategy hactive →
          strategy ≠ Strategy.bundle →
            greedyWeights.resourceWeight strategy <
              greedyWeights.resourceWeight Strategy.bundle) ∧
      Projection.Model.RedundantDeletionSequence exampleCatalog identityClosure
        sourceLibrary [Strategy.bundle] pairLibrary ∧
      OneDeletionIrreducible exampleCatalog identityClosure pairLibrary ∧
      SafeCompressionFeasible exampleCatalog identityClosure
        sourceLibrary bundleLibrary ∧
      libraryBurden greedyWeights bundleLibrary <
        libraryBurden greedyWeights pairLibrary := by
  refine ⟨bundle_is_uniqueHeaviestSafeDeletion,
    bundleFirst_recheckedSequence, pair_oneDeletionIrreducible,
    bundle_safeCompressionFeasible, ?_⟩
  rw [greedy_pair_weight_eq_four, greedy_bundle_weight_eq_three]
  norm_num

end SafeCompressionCounterexample

end Optimization

end StrategyInnovation
