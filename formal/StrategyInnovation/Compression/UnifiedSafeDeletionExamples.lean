import StrategyInnovation.Compression.UnifiedSafeDeletion

/-!
# Exact finite examples for unified safe deletion

One finite rational catalog separates the four cases required by T3:

* a safely deletable duplicate encoding;
* an operationally redundant but generatively essential module carrier;
* a generatively redundant but operationally essential strategy;
* two distinct raw identifiers with identical operational and module rows.

The duplicate pair also gives the exact stale-certificate counterexample:
each identifier is redundant in the original library, but after one deletion
the survivor is essential.  Reusing the original certificate for the second
deletion changes the compressed state.  If redundancy is rechecked, either
order is safe but retains a different raw identifier.
-/

namespace StrategyInnovation

namespace Projection

namespace Model

namespace UnifiedSafeDeletionExamples

inductive Belief
  | only
  deriving DecidableEq, Fintype

instance : Nonempty Belief := ⟨Belief.only⟩

inductive Strategy
  | inactive
  | duplicateLeft
  | duplicateRight
  | operationalOnly
  | moduleOnly
  deriving DecidableEq, Fintype

instance : Nonempty Strategy := ⟨Strategy.inactive⟩

inductive Module
  | signal
  deriving DecidableEq, Fintype

instance : Nonempty Module := ⟨Module.signal⟩

inductive Project
  | probe
  deriving DecidableEq, Fintype

instance : Nonempty Project := ⟨Project.probe⟩

/-- Exact finite carrier for all T3 examples. -/
abbrev exampleModel : FiniteModel where
  Belief := Belief
  StrategyId := Strategy
  ModuleId := Module
  ResearchProject := Project

def profile : Strategy → Belief → ℚ
  | .inactive, _ => 0
  | .duplicateLeft, _ => 1
  | .duplicateRight, _ => 1
  | .operationalOnly, _ => 2
  | .moduleOnly, _ => 0

def modules : Strategy → Finset Module
  | .inactive => ∅
  | .duplicateLeft => {Module.signal}
  | .duplicateRight => {Module.signal}
  | .operationalOnly => ∅
  | .moduleOnly => {Module.signal}

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

def inactiveLibrary : Raw.Library exampleCatalog where
  strategies := {Strategy.inactive}
  inactive_mem := by simp

def duplicateLibrary : Raw.Library exampleCatalog where
  strategies :=
    {Strategy.inactive, Strategy.duplicateLeft, Strategy.duplicateRight}
  inactive_mem := by simp

def leftLibrary : Raw.Library exampleCatalog where
  strategies := {Strategy.inactive, Strategy.duplicateLeft}
  inactive_mem := by simp

def rightLibrary : Raw.Library exampleCatalog where
  strategies := {Strategy.inactive, Strategy.duplicateRight}
  inactive_mem := by simp

def operationalLibrary : Raw.Library exampleCatalog where
  strategies := {Strategy.inactive, Strategy.operationalOnly}
  inactive_mem := by simp

def moduleLibrary : Raw.Library exampleCatalog where
  strategies := {Strategy.inactive, Strategy.moduleOnly}
  inactive_mem := by simp

theorem duplicateLeft_ne_inactive :
    Strategy.duplicateLeft ≠ exampleCatalog.inactiveStrategy := by
  decide

theorem duplicateRight_ne_inactive :
    Strategy.duplicateRight ≠ exampleCatalog.inactiveStrategy := by
  decide

theorem operationalOnly_ne_inactive :
    Strategy.operationalOnly ≠ exampleCatalog.inactiveStrategy := by
  decide

theorem moduleOnly_ne_inactive :
    Strategy.moduleOnly ≠ exampleCatalog.inactiveStrategy := by
  decide

/-! ## Exact erasure identities -/

theorem duplicateLibrary_erase_left_eq_right :
    duplicateLibrary.erase Strategy.duplicateLeft duplicateLeft_ne_inactive =
      rightLibrary := by
  apply Library.ext
  change
    ({Strategy.inactive, Strategy.duplicateLeft, Strategy.duplicateRight} :
      Finset Strategy).erase Strategy.duplicateLeft =
        {Strategy.inactive, Strategy.duplicateRight}
  decide

theorem duplicateLibrary_erase_right_eq_left :
    duplicateLibrary.erase Strategy.duplicateRight duplicateRight_ne_inactive =
      leftLibrary := by
  apply Library.ext
  change
    ({Strategy.inactive, Strategy.duplicateLeft, Strategy.duplicateRight} :
      Finset Strategy).erase Strategy.duplicateRight =
        {Strategy.inactive, Strategy.duplicateLeft}
  decide

theorem leftLibrary_erase_left_eq_inactive :
    leftLibrary.erase Strategy.duplicateLeft duplicateLeft_ne_inactive =
      inactiveLibrary := by
  apply Library.ext
  change
    ({Strategy.inactive, Strategy.duplicateLeft} : Finset Strategy).erase
        Strategy.duplicateLeft =
      {Strategy.inactive}
  decide

theorem rightLibrary_erase_right_eq_inactive :
    rightLibrary.erase Strategy.duplicateRight duplicateRight_ne_inactive =
      inactiveLibrary := by
  apply Library.ext
  change
    ({Strategy.inactive, Strategy.duplicateRight} : Finset Strategy).erase
        Strategy.duplicateRight =
      {Strategy.inactive}
  decide

theorem operationalLibrary_erase_eq_inactive :
    operationalLibrary.erase Strategy.operationalOnly
        operationalOnly_ne_inactive =
      inactiveLibrary := by
  apply Library.ext
  change
    ({Strategy.inactive, Strategy.operationalOnly} : Finset Strategy).erase
        Strategy.operationalOnly =
      {Strategy.inactive}
  decide

theorem moduleLibrary_erase_eq_inactive :
    moduleLibrary.erase Strategy.moduleOnly moduleOnly_ne_inactive =
      inactiveLibrary := by
  apply Library.ext
  change
    ({Strategy.inactive, Strategy.moduleOnly} : Finset Strategy).erase
        Strategy.moduleOnly =
      {Strategy.inactive}
  decide

/-! ## Exact frontiers -/

theorem inactive_frontier :
    operationalFrontier exampleCatalog inactiveLibrary Belief.only = 0 := by
  apply le_antisymm
  · apply (operationalFrontier_le_iff
      exampleCatalog inactiveLibrary Belief.only 0).2
    intro strategy hstrategy
    change strategy ∈ ({Strategy.inactive} : Finset Strategy) at hstrategy
    simp only [Finset.mem_singleton] at hstrategy
    subst strategy
    rfl
  · exact zero_le_operationalFrontier
      exampleCatalog inactiveLibrary Belief.only

theorem left_frontier :
    operationalFrontier exampleCatalog leftLibrary Belief.only = 1 := by
  apply le_antisymm
  · apply (operationalFrontier_le_iff
      exampleCatalog leftLibrary Belief.only 1).2
    intro strategy hstrategy
    change strategy ∈
      ({Strategy.inactive, Strategy.duplicateLeft} : Finset Strategy) at hstrategy
    simp only [Finset.mem_insert, Finset.mem_singleton] at hstrategy
    rcases hstrategy with rfl | rfl <;> norm_num [exampleCatalog, profile]
  · exact operationalProfile_le_frontier exampleCatalog leftLibrary
      (strategy := Strategy.duplicateLeft)
      (by
        change Strategy.duplicateLeft ∈
          ({Strategy.inactive, Strategy.duplicateLeft} : Finset Strategy)
        decide)
      Belief.only

theorem right_frontier :
    operationalFrontier exampleCatalog rightLibrary Belief.only = 1 := by
  apply le_antisymm
  · apply (operationalFrontier_le_iff
      exampleCatalog rightLibrary Belief.only 1).2
    intro strategy hstrategy
    change strategy ∈
      ({Strategy.inactive, Strategy.duplicateRight} : Finset Strategy) at hstrategy
    simp only [Finset.mem_insert, Finset.mem_singleton] at hstrategy
    rcases hstrategy with rfl | rfl <;> norm_num [exampleCatalog, profile]
  · exact operationalProfile_le_frontier exampleCatalog rightLibrary
      (strategy := Strategy.duplicateRight)
      (by
        change Strategy.duplicateRight ∈
          ({Strategy.inactive, Strategy.duplicateRight} : Finset Strategy)
        decide)
      Belief.only

theorem duplicate_frontier :
    operationalFrontier exampleCatalog duplicateLibrary Belief.only = 1 := by
  apply le_antisymm
  · apply (operationalFrontier_le_iff
      exampleCatalog duplicateLibrary Belief.only 1).2
    intro strategy hstrategy
    change strategy ∈
      ({Strategy.inactive, Strategy.duplicateLeft, Strategy.duplicateRight} :
        Finset Strategy) at hstrategy
    simp only [Finset.mem_insert, Finset.mem_singleton] at hstrategy
    rcases hstrategy with rfl | rfl | rfl <;>
      norm_num [exampleCatalog, profile]
  · exact operationalProfile_le_frontier exampleCatalog duplicateLibrary
      (strategy := Strategy.duplicateLeft)
      (by
        change Strategy.duplicateLeft ∈
          ({Strategy.inactive, Strategy.duplicateLeft,
            Strategy.duplicateRight} : Finset Strategy)
        decide)
      Belief.only

theorem operational_frontier :
    operationalFrontier exampleCatalog operationalLibrary Belief.only = 2 := by
  apply le_antisymm
  · apply (operationalFrontier_le_iff
      exampleCatalog operationalLibrary Belief.only 2).2
    intro strategy hstrategy
    change strategy ∈
      ({Strategy.inactive, Strategy.operationalOnly} : Finset Strategy) at hstrategy
    simp only [Finset.mem_insert, Finset.mem_singleton] at hstrategy
    rcases hstrategy with rfl | rfl <;> norm_num [exampleCatalog, profile]
  · exact operationalProfile_le_frontier exampleCatalog operationalLibrary
      (strategy := Strategy.operationalOnly)
      (by
        change Strategy.operationalOnly ∈
          ({Strategy.inactive, Strategy.operationalOnly} : Finset Strategy)
        decide)
      Belief.only

theorem module_frontier :
    operationalFrontier exampleCatalog moduleLibrary Belief.only = 0 := by
  apply le_antisymm
  · apply (operationalFrontier_le_iff
      exampleCatalog moduleLibrary Belief.only 0).2
    intro strategy hstrategy
    change strategy ∈
      ({Strategy.inactive, Strategy.moduleOnly} : Finset Strategy) at hstrategy
    simp only [Finset.mem_insert, Finset.mem_singleton] at hstrategy
    rcases hstrategy with rfl | rfl <;> norm_num [exampleCatalog, profile]
  · exact zero_le_operationalFrontier
      exampleCatalog moduleLibrary Belief.only

/-! ## Exact closures -/

theorem inactive_closure :
    generativeClosure exampleCatalog identityClosure inactiveLibrary = ∅ := by
  simp [generativeClosure, rawModuleUnion, inactiveLibrary,
    exampleCatalog, modules]

theorem duplicate_closure :
    generativeClosure exampleCatalog identityClosure duplicateLibrary =
      {Module.signal} := by
  simp [generativeClosure, rawModuleUnion, duplicateLibrary,
    exampleCatalog, modules]

theorem left_closure :
    generativeClosure exampleCatalog identityClosure leftLibrary =
      {Module.signal} := by
  simp [generativeClosure, rawModuleUnion, leftLibrary,
    exampleCatalog, modules]

theorem right_closure :
    generativeClosure exampleCatalog identityClosure rightLibrary =
      {Module.signal} := by
  simp [generativeClosure, rawModuleUnion, rightLibrary,
    exampleCatalog, modules]

theorem operational_closure :
    generativeClosure exampleCatalog identityClosure operationalLibrary = ∅ := by
  simp [generativeClosure, rawModuleUnion, operationalLibrary,
    exampleCatalog, modules]

theorem module_closure :
    generativeClosure exampleCatalog identityClosure moduleLibrary =
      {Module.signal} := by
  simp [generativeClosure, rawModuleUnion, moduleLibrary,
    exampleCatalog, modules]

/-! ## The four required classifications -/

/-- Duplicate-left is operationally redundant in the two-encoding library. -/
theorem duplicateLeft_operationallyRedundant :
    operationallyRedundant duplicateLibrary Strategy.duplicateLeft
      duplicateLeft_ne_inactive := by
  unfold operationallyRedundant
  rw [duplicateLibrary_erase_left_eq_right]
  funext belief
  cases belief
  rw [right_frontier, duplicate_frontier]

/-- Duplicate-left is generatively redundant in the two-encoding library. -/
theorem duplicateLeft_generativelyRedundant :
    generativelyRedundant (closure := identityClosure)
      duplicateLibrary Strategy.duplicateLeft duplicateLeft_ne_inactive := by
  unfold generativelyRedundant
  rw [duplicateLibrary_erase_left_eq_right, right_closure, duplicate_closure]

/-- Duplicate-right is also redundant in the original library. -/
theorem duplicateRight_redundant :
    RedundantDeletion (closure := identityClosure)
      duplicateLibrary Strategy.duplicateRight duplicateRight_ne_inactive := by
  constructor
  · unfold operationallyRedundant
    rw [duplicateLibrary_erase_right_eq_left]
    funext belief
    cases belief
    rw [left_frontier, duplicate_frontier]
  · unfold generativelyRedundant
    rw [duplicateLibrary_erase_right_eq_left, left_closure, duplicate_closure]

/--
Exact safely deletable example: either duplicate encoding is safe for every
accepted unified raw process on this catalog.
-/
theorem duplicateLeft_innovationSafe
    (process : Model exampleModel exampleCatalog identityClosure) :
    InnovationSafeDeletion process duplicateLibrary Strategy.duplicateLeft
      duplicateLeft_ne_inactive :=
  process.redundantDeletion_innovationSafe
    duplicateLeft_operationallyRedundant
    duplicateLeft_generativelyRedundant

/--
Exact operational-only redundancy: the zero-profile module carrier leaves the
frontier unchanged but is generatively essential.
-/
theorem moduleOnly_operationallyRedundant_generativelyEssential :
    operationallyRedundant moduleLibrary Strategy.moduleOnly
        moduleOnly_ne_inactive ∧
      ¬ generativelyRedundant (closure := identityClosure)
        moduleLibrary Strategy.moduleOnly moduleOnly_ne_inactive := by
  constructor
  · unfold operationallyRedundant
    rw [moduleLibrary_erase_eq_inactive]
    funext belief
    cases belief
    rw [inactive_frontier, module_frontier]
  · intro hgenerative
    unfold generativelyRedundant at hgenerative
    rw [moduleLibrary_erase_eq_inactive, inactive_closure, module_closure]
      at hgenerative
    simp at hgenerative

/--
Exact generative-only redundancy: the positive operational strategy adds no
module but is essential to the current frontier.
-/
theorem operationalOnly_generativelyRedundant_operationallyEssential :
    generativelyRedundant (closure := identityClosure)
        operationalLibrary Strategy.operationalOnly operationalOnly_ne_inactive ∧
      ¬ operationallyRedundant operationalLibrary Strategy.operationalOnly
        operationalOnly_ne_inactive := by
  constructor
  · unfold generativelyRedundant
    rw [operationalLibrary_erase_eq_inactive,
      inactive_closure, operational_closure]
  · intro hoperational
    unfold operationallyRedundant at hoperational
    rw [operationalLibrary_erase_eq_inactive] at hoperational
    have hpoint := congrFun hoperational Belief.only
    rw [inactive_frontier, operational_frontier] at hpoint
    norm_num at hpoint

/--
Duplicate encodings are raw-distinct but compress to the same state.  A
rechecked pruning order may therefore retain different identifiers while
remaining dynamically equivalent.
-/
theorem duplicateEncoding_orderChangesRawRepresentative :
    leftLibrary ≠ rightLibrary ∧
      compressedLibraryState exampleCatalog identityClosure leftLibrary =
        compressedLibraryState exampleCatalog identityClosure rightLibrary := by
  constructor
  · intro hequal
    have hstrategies := congrArg Library.strategies hequal
    change
      ({Strategy.inactive, Strategy.duplicateLeft} : Finset Strategy) =
        {Strategy.inactive, Strategy.duplicateRight} at hstrategies
    have hleft :
        Strategy.duplicateLeft ∈
          ({Strategy.inactive, Strategy.duplicateLeft} : Finset Strategy) := by
      simp
    rw [hstrategies] at hleft
    simp at hleft
  · exact
      (redundantDeletion_compressedLibraryState_eq
        duplicateRight_redundant.1 duplicateRight_redundant.2).symm.trans
        (redundantDeletion_compressedLibraryState_eq
          duplicateLeft_operationallyRedundant
          duplicateLeft_generativelyRedundant)

/-! ## Exact stale-certificate/order boundary -/

theorem duplicateRight_generativelyEssential_after_leftDeletion :
    ¬ generativelyRedundant (closure := identityClosure)
      rightLibrary Strategy.duplicateRight duplicateRight_ne_inactive := by
  intro hgenerative
  unfold generativelyRedundant at hgenerative
  rw [rightLibrary_erase_right_eq_inactive, inactive_closure, right_closure]
    at hgenerative
  simp at hgenerative

theorem stale_doubleDeletion_changes_compressedState :
    compressedLibraryState exampleCatalog identityClosure
        ((duplicateLibrary.erase Strategy.duplicateLeft duplicateLeft_ne_inactive).erase
          Strategy.duplicateRight duplicateRight_ne_inactive) ≠
      compressedLibraryState exampleCatalog identityClosure duplicateLibrary := by
  rw [duplicateLibrary_erase_left_eq_right,
    rightLibrary_erase_right_eq_inactive]
  intro hstate
  have hclosure := generativeClosure_eq_of_compressedLibraryState_eq
    exampleCatalog identityClosure hstate
  rw [inactive_closure, duplicate_closure] at hclosure
  simp at hclosure

/--
The exact no-recheck counterexample: both original certificates are valid, but
they do not compose.  After deleting left, right is no longer redundant, and
using its stale original certificate changes `K`.
-/
theorem staleOriginalRedundancyChecks_doNotCompose :
    RedundantDeletion (closure := identityClosure)
        duplicateLibrary Strategy.duplicateLeft duplicateLeft_ne_inactive ∧
      RedundantDeletion (closure := identityClosure)
        duplicateLibrary Strategy.duplicateRight duplicateRight_ne_inactive ∧
      ¬ RedundantDeletion (closure := identityClosure)
        rightLibrary Strategy.duplicateRight duplicateRight_ne_inactive ∧
      compressedLibraryState exampleCatalog identityClosure
          ((duplicateLibrary.erase Strategy.duplicateLeft
            duplicateLeft_ne_inactive).erase
              Strategy.duplicateRight duplicateRight_ne_inactive) ≠
        compressedLibraryState exampleCatalog identityClosure duplicateLibrary := by
  exact
    ⟨⟨duplicateLeft_operationallyRedundant,
        duplicateLeft_generativelyRedundant⟩,
      duplicateRight_redundant,
      fun hredundant =>
        duplicateRight_generativelyEssential_after_leftDeletion hredundant.2,
      stale_doubleDeletion_changes_compressedState⟩

end UnifiedSafeDeletionExamples

end Model

end Projection

end StrategyInnovation
