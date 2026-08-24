import Mathlib.Data.Finset.Max
import StrategyInnovation.Compression.UnifiedSafeDeletion
import StrategyInnovation.Optimization.ResourceBurden

/-!
# Exact source-relative safe compression

The feasible family consists of inactive-containing sublibraries of a fixed
source whose exact operational frontier and general generative closure agree
with the source.  The file proves finite minimum attainment and connects the
resource-free compressed state to the existing unified dynamic value theorem.
-/

namespace StrategyInnovation

namespace Optimization

variable {model : FiniteModel}
variable {catalog : Raw.StrategyCatalog model}
variable {closure : Raw.ClosureOperator model}

/-- A candidate is a source-relative sublibrary when its strategy set is included. -/
def SublibraryFeasible (source candidate : Raw.Library catalog) : Prop :=
  candidate ≤ source

/--
Exact frontier--closure feasibility relative to a fixed source library.

This predicate says only that the candidate is a sublibrary in the same
productive compressed-state fiber.  It contains neither a local-deletion
condition nor a global optimality condition.
-/
def SafeCompressionFeasible
    (catalog : Raw.StrategyCatalog model) (closure : Raw.ClosureOperator model)
    (source candidate : Raw.Library catalog) : Prop :=
  SublibraryFeasible source candidate ∧
    compressedLibraryState catalog closure candidate =
      compressedLibraryState catalog closure source

/-- Backward-compatible name for exact frontier--closure feasibility. -/
abbrev ExactSafeCompressionFeasible
    (catalog : Raw.StrategyCatalog model) (closure : Raw.ClosureOperator model)
    (source candidate : Raw.Library catalog) : Prop :=
  SafeCompressionFeasible catalog closure source candidate

/-- Exact deletion safety at the current library, including current membership. -/
def ExactSafeDeletion
    (catalog : Raw.StrategyCatalog model) (closure : Raw.ClosureOperator model)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (hactive : strategy ≠ catalog.inactiveStrategy) : Prop :=
  strategy ∈ library ∧
    compressedLibraryState catalog closure (library.erase strategy hactive) =
      compressedLibraryState catalog closure library

/--
A library is one-deletion irreducible when no represented active strategy can
be deleted while preserving its current compressed state.
-/
def OneDeletionIrreducible
    (catalog : Raw.StrategyCatalog model) (closure : Raw.ClosureOperator model)
    (library : Raw.Library catalog) : Prop :=
  ∀ (strategy : model.StrategyId)
    (hactive : strategy ≠ catalog.inactiveStrategy),
      ¬ ExactSafeDeletion catalog closure library strategy hactive

/--
A globally minimum-weight exact safe compression.  Ties are retained: this is
a predicate on every minimizer, not a selected optimizer.
-/
def MinimumWeightSafeCompression
    (catalog : Raw.StrategyCatalog model) (closure : Raw.ClosureOperator model)
    (weights : StrategyResourceWeights model catalog.inactiveStrategy)
    (source optimizer : Raw.Library catalog) : Prop :=
  SafeCompressionFeasible catalog closure source optimizer ∧
    ∀ candidate : Raw.Library catalog,
      SafeCompressionFeasible catalog closure source candidate →
        libraryBurden weights optimizer ≤ libraryBurden weights candidate

/-- Source-relative feasibility expressed through unified dynamic equivalence. -/
def DynamicEquivalentSafeCompressionFeasible
    (process : Projection.Model model catalog closure)
    (source candidate : Raw.Library catalog) : Prop :=
  SublibraryFeasible source candidate ∧
    Projection.Model.DynamicInnovationEquivalent process candidate source

/-- The source library is always feasible for its own exact compression problem. -/
theorem exactSafeCompressionFeasible_source
    (catalog : Raw.StrategyCatalog model) (closure : Raw.ClosureOperator model)
    (source : Raw.Library catalog) :
    ExactSafeCompressionFeasible catalog closure source source :=
  ⟨le_rfl, rfl⟩

/-- All source-relative sublibraries form a finite set. -/
theorem sublibrarySet_finite (source : Raw.Library catalog) :
    Set.Finite
      {candidate : Raw.Library catalog | SublibraryFeasible source candidate} :=
  Set.toFinite _

/-- The exact safe-feasible family is finite as a subset of the library carrier. -/
theorem exactSafeCompressionFeasibleSet_finite
    (catalog : Raw.StrategyCatalog model) (closure : Raw.ClosureOperator model)
    (source : Raw.Library catalog) :
    Set.Finite
      {candidate : Raw.Library catalog |
        ExactSafeCompressionFeasible catalog closure source candidate} :=
  Set.toFinite _

/-- A safe deletion preserves the exact frontier and general closure. -/
theorem exactSafeDeletion_preserves_frontier_and_closure
    (catalog : Raw.StrategyCatalog model) (closure : Raw.ClosureOperator model)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (hactive : strategy ≠ catalog.inactiveStrategy)
    (hsafe : ExactSafeDeletion catalog closure library strategy hactive) :
    operationalFrontier catalog (library.erase strategy hactive) =
        operationalFrontier catalog library ∧
      generativeClosure catalog closure (library.erase strategy hactive) =
        generativeClosure catalog closure library :=
  ⟨operationalFrontier_eq_of_compressedLibraryState_eq
      catalog closure hsafe.2,
    generativeClosure_eq_of_compressedLibraryState_eq
      catalog closure hsafe.2⟩

/--
A safe deletion from a source-feasible current library remains source-feasible
and strictly lowers additive burden.
-/
theorem exactSafeDeletion_produces_feasible_lowerWeight
    (catalog : Raw.StrategyCatalog model) (closure : Raw.ClosureOperator model)
    (weights : StrategyResourceWeights model catalog.inactiveStrategy)
    {source current : Raw.Library catalog} {strategy : model.StrategyId}
    (hactive : strategy ≠ catalog.inactiveStrategy)
    (hcurrent : ExactSafeCompressionFeasible catalog closure source current)
    (hsafe : ExactSafeDeletion catalog closure current strategy hactive) :
    ExactSafeCompressionFeasible catalog closure source
        (current.erase strategy hactive) ∧
      libraryBurden weights (current.erase strategy hactive) <
        libraryBurden weights current := by
  constructor
  · exact
      ⟨(Library.erase_le current strategy hactive).trans hcurrent.1,
        hsafe.2.trans hcurrent.2⟩
  · exact libraryBurden_erase_lt weights current strategy hsafe.1 hactive

/-- A minimum-weight exact safe sublibrary exists; no uniqueness is asserted. -/
theorem exists_minimumWeight_exactSafeCompression
    (catalog : Raw.StrategyCatalog model) (closure : Raw.ClosureOperator model)
    (weights : StrategyResourceWeights model catalog.inactiveStrategy)
    (source : Raw.Library catalog) :
    ∃ optimizer : Raw.Library catalog,
      ExactSafeCompressionFeasible catalog closure source optimizer ∧
        ∀ candidate : Raw.Library catalog,
          ExactSafeCompressionFeasible catalog closure source candidate →
            libraryBurden weights optimizer ≤ libraryBurden weights candidate := by
  classical
  let feasibleLibraries : Finset (Raw.Library catalog) :=
    Finset.univ.filter
      (ExactSafeCompressionFeasible catalog closure source)
  have hnonempty : feasibleLibraries.Nonempty := by
    refine ⟨source, ?_⟩
    simp [feasibleLibraries, exactSafeCompressionFeasible_source]
  obtain ⟨optimizer, hoptimizer, hminimum⟩ :=
    Finset.exists_min_image feasibleLibraries (libraryBurden weights) hnonempty
  refine ⟨optimizer, (Finset.mem_filter.mp hoptimizer).2, ?_⟩
  intro candidate hcandidate
  apply hminimum candidate
  exact Finset.mem_filter.mpr ⟨Finset.mem_univ _, hcandidate⟩

/-- T2: under detectability, exact and dynamic-equivalence feasibility coincide. -/
theorem safeCompressionFeasible_iff_dynamicEquivalentFeasible
    (process : Projection.Model model catalog closure)
    (hdetectable : Projection.Model.RawClosureDetectable process)
    {source candidate : Raw.Library catalog} :
    SafeCompressionFeasible catalog closure source candidate ↔
      DynamicEquivalentSafeCompressionFeasible process source candidate := by
  constructor
  · rintro ⟨hinclude, hstate⟩
    exact ⟨hinclude,
      (process.dynamicInnovationEquivalent_iff_compressedLibraryState_eq
        hdetectable).2 hstate⟩
  · rintro ⟨hinclude, hequivalent⟩
    exact ⟨hinclude,
      (process.dynamicInnovationEquivalent_iff_compressedLibraryState_eq
        hdetectable).1 hequivalent⟩

/-- Every exact feasible pair is dynamically equivalent; detectability is unnecessary. -/
theorem SafeCompressionFeasible.dynamicInnovationEquivalent
    (process : Projection.Model model catalog closure)
    {source candidate : Raw.Library catalog}
    (hfeasible : SafeCompressionFeasible catalog closure source candidate) :
    Projection.Model.DynamicInnovationEquivalent process candidate source :=
  process.compressedState_eq_implies_dynamicInnovationEquivalent hfeasible.2

/-- Equal productive compressed states preserve every unified finite-horizon value. -/
theorem equalCompressedStates_preserve_dynamicValue
    (process : Projection.Model model catalog closure)
    {left right : Raw.Library catalog}
    (hstate : compressedLibraryState catalog closure left =
      compressedLibraryState catalog closure right) :
    ∀ horizon belief,
      process.rawValue horizon belief left =
        process.rawValue horizon belief right :=
  process.rawValue_eq_of_dynamicInnovationEquivalent
    (process.compressedState_eq_implies_dynamicInnovationEquivalent hstate)

/-- Every exact safe-compression feasible library preserves productive value. -/
theorem ExactSafeCompressionFeasible.preserves_dynamicValue
    (process : Projection.Model model catalog closure)
    {source candidate : Raw.Library catalog}
    (hfeasible :
      ExactSafeCompressionFeasible catalog closure source candidate) :
    ∀ horizon belief,
      process.rawValue horizon belief candidate =
        process.rawValue horizon belief source :=
  equalCompressedStates_preserve_dynamicValue process hfeasible.2

/-- Every exact feasible library preserves every unified finite-horizon value. -/
theorem SafeCompressionFeasible.preserves_finiteHorizonValue
    (process : Projection.Model model catalog closure)
    {source candidate : Raw.Library catalog}
    (hfeasible : SafeCompressionFeasible catalog closure source candidate) :
    ∀ horizon belief,
      process.rawValue horizon belief candidate =
        process.rawValue horizon belief source :=
  equalCompressedStates_preserve_dynamicValue process hfeasible.2

/-- Every exact feasible library preserves the stationary productive value. -/
theorem SafeCompressionFeasible.preserves_infiniteHorizonValue
    {process : Projection.Model model catalog closure}
    (contraction : Projection.Model.DiscountedContractionModel process)
    {source candidate : Raw.Library catalog}
    (hfeasible : SafeCompressionFeasible catalog closure source candidate)
    (belief : model.Belief) :
    contraction.rawFixedPoint (belief, candidate) =
      contraction.rawFixedPoint (belief, source) :=
  contraction.rawFixedPoint_eq_of_dynamicInnovationEquivalent
    (hfeasible.dynamicInnovationEquivalent process) belief

/-- Equal compressed states preserve optimality of every stationary action. -/
theorem isOptimalFixedPointAction_iff_of_compressedState_eq
    {process : Projection.Model model catalog closure}
    (contraction : Projection.Model.DiscountedContractionModel process)
    {left right : Raw.Library catalog}
    (hstate : compressedLibraryState catalog closure left =
      compressedLibraryState catalog closure right)
    (belief : model.Belief) (action : Projection.Model.Action model) :
    Projection.Model.IsOptimalFixedPointAction contraction belief left action ↔
      Projection.Model.IsOptimalFixedPointAction contraction belief right action := by
  have havailable :=
    process.stationaryActionAvailable_iff_of_compressedState_eq hstate
  have hvalue :=
    contraction.fixedPointActionValue_eq_of_compressedState_eq hstate belief
  constructor
  · rintro ⟨haction, hoptimal⟩
    refine ⟨(havailable action).mp haction, ?_⟩
    intro other hother
    have hleftOther := (havailable other).mpr hother
    have hcomparison := hoptimal other hleftOther
    simpa [hvalue other, hvalue action] using hcomparison
  · rintro ⟨haction, hoptimal⟩
    refine ⟨(havailable action).mpr haction, ?_⟩
    intro other hother
    have hrightOther := (havailable other).mp hother
    have hcomparison := hoptimal other hrightOther
    simpa [hvalue other, hvalue action] using hcomparison

/-- The complete set of stationary fixed-point optimal action signatures. -/
def optimalFixedPointActions
    {process : Projection.Model model catalog closure}
    (contraction : Projection.Model.DiscountedContractionModel process)
    (belief : model.Belief) (library : Raw.Library catalog) :
    Set (Projection.Model.Action model) :=
  {action |
    Projection.Model.IsOptimalFixedPointAction
      contraction belief library action}

/-- T3: every exact feasible library preserves the full optimal-action set. -/
theorem SafeCompressionFeasible.preserves_optimalActions
    {process : Projection.Model model catalog closure}
    (contraction : Projection.Model.DiscountedContractionModel process)
    {source candidate : Raw.Library catalog}
    (hfeasible : SafeCompressionFeasible catalog closure source candidate)
    (belief : model.Belief) :
    optimalFixedPointActions contraction belief candidate =
      optimalFixedPointActions contraction belief source := by
  ext action
  exact isOptimalFixedPointAction_iff_of_compressedState_eq
    contraction hfeasible.2 belief action

/-- A minimum-weight exact safe compression exists; uniqueness is not assumed. -/
theorem exists_minimumWeightSafeCompression
    (catalog : Raw.StrategyCatalog model) (closure : Raw.ClosureOperator model)
    (weights : StrategyResourceWeights model catalog.inactiveStrategy)
    (source : Raw.Library catalog) :
    ∃ optimizer : Raw.Library catalog,
      MinimumWeightSafeCompression catalog closure weights source optimizer := by
  rcases exists_minimumWeight_exactSafeCompression
      catalog closure weights source with ⟨optimizer, hfeasible, hminimum⟩
  exact ⟨optimizer, hfeasible, hminimum⟩

/-- T3: every global minimum is one-deletion irreducible. -/
theorem MinimumWeightSafeCompression.oneDeletionIrreducible
    (catalog : Raw.StrategyCatalog model) (closure : Raw.ClosureOperator model)
    (weights : StrategyResourceWeights model catalog.inactiveStrategy)
    {source optimizer : Raw.Library catalog}
    (hminimum :
      MinimumWeightSafeCompression catalog closure weights source optimizer) :
    OneDeletionIrreducible catalog closure optimizer := by
  intro strategy hactive hsafe
  have hreduction := exactSafeDeletion_produces_feasible_lowerWeight
    catalog closure weights hactive hminimum.1 hsafe
  exact (not_lt_of_ge (hminimum.2 _ hreduction.1)) hreduction.2

/-- T3: the endpoint of every rechecked structural deletion trace is feasible. -/
theorem recheckedSafeDeletionEndpoint_feasible
    {initial final : Raw.Library catalog} {deletions : List model.StrategyId}
    (sequence :
      Projection.Model.RedundantDeletionSequence
        catalog closure initial deletions final) :
    SafeCompressionFeasible catalog closure initial final :=
  ⟨sequence.final_le_initial,
    sequence.compressedLibraryState_final_eq_initial⟩

end Optimization

end StrategyInnovation
