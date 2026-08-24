import StrategyInnovation.Quotient.RawFrontierClosure

/-!
# Unified innovation-safe deletion (T3)

This module rebuilds deletion safety on the raw generator/admission/update
model and the T1 raw-to-compressed projection.  The older top-level
`Compression.SafeDeletion` declarations concern the deprecated primitive
transition model and are not used here.

A noninactive strategy is operationally redundant when erasing it preserves
the raw frontier and generatively redundant when erasing it preserves the raw
closure.  Their conjunction preserves the actual realizable compressed state.
T1 then transports every finite-horizon value, the contraction fixed point,
and stationary optimal action comparisons.

The converse is deliberately observational.  Under T2's
`RawClosureDetectable`, preservation of the unified cost, duration, joint
terminal-law, frontier, and operating-reward observations recovers both
redundancy predicates.  No value-only converse is claimed.
-/

namespace StrategyInnovation

namespace Projection

namespace Model

variable {model : FiniteModel}
variable {catalog : Raw.StrategyCatalog model} {closure : Raw.ClosureOperator model}

/-! ## Single-deletion predicates -/

/-- Erasing the strategy leaves the pointwise operational frontier unchanged. -/
def operationallyRedundant (library : Raw.Library catalog)
    (strategy : model.StrategyId) (hstrategy : strategy ≠ catalog.inactiveStrategy) :
    Prop :=
  operationalFrontier catalog (library.erase strategy hstrategy) =
    operationalFrontier catalog library

/-- Erasing the strategy leaves the closed raw module union unchanged. -/
def generativelyRedundant (library : Raw.Library catalog)
    (strategy : model.StrategyId) (hstrategy : strategy ≠ catalog.inactiveStrategy) :
    Prop :=
  generativeClosure catalog closure (library.erase strategy hstrategy) =
    generativeClosure catalog closure library

/-- Both exact components of the raw compressed state survive deletion. -/
def RedundantDeletion (library : Raw.Library catalog)
    (strategy : model.StrategyId) (hstrategy : strategy ≠ catalog.inactiveStrategy) :
    Prop :=
  operationallyRedundant library strategy hstrategy ∧
    generativelyRedundant (closure := closure) library strategy hstrategy

/--
Unified innovation-safe deletion.

The observation field explicitly contains the current frontier, tagged project
costs, durations, joint next-belief/next-compressed-state laws, and operating
rewards.  The value field records dynamic value preservation for every belief
and every finite horizon.  Infinite-horizon preservation is stated separately,
because it requires a contraction model.
-/
structure InnovationSafeDeletion (process : Model model catalog closure)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (hstrategy : strategy ≠ catalog.inactiveStrategy) : Prop where
  observations :
    DynamicInnovationEquivalent process
      (library.erase strategy hstrategy) library
  finiteHorizonValue : ∀ horizon belief,
    process.rawValue horizon belief (library.erase strategy hstrategy) =
      process.rawValue horizon belief library

/-! ## Compressed-state identity and T1 consequences -/

/-- T3's algebraic core: the two redundancy equalities preserve `K_L`. -/
theorem redundantDeletion_compressedLibraryState_eq
    {library : Raw.Library catalog} {strategy : model.StrategyId}
    {hstrategy : strategy ≠ catalog.inactiveStrategy}
    (hoperational :
      operationallyRedundant library strategy hstrategy)
    (hgenerative :
      generativelyRedundant (closure := closure) library strategy hstrategy) :
    compressedLibraryState catalog closure (library.erase strategy hstrategy) =
      compressedLibraryState catalog closure library := by
  unfold compressedLibraryState
  rw [hoperational, hgenerative]

/-- Equality of compressed states is exactly the two deletion equalities. -/
theorem redundantDeletion_iff_compressedLibraryState_eq
    {library : Raw.Library catalog} {strategy : model.StrategyId}
    {hstrategy : strategy ≠ catalog.inactiveStrategy} :
    RedundantDeletion (closure := closure) library strategy hstrategy ↔
      compressedLibraryState catalog closure (library.erase strategy hstrategy) =
        compressedLibraryState catalog closure library := by
  constructor
  · rintro ⟨hoperational, hgenerative⟩
    exact redundantDeletion_compressedLibraryState_eq
      hoperational hgenerative
  · intro hstate
    exact
      ⟨operationalFrontier_eq_of_compressedLibraryState_eq
          catalog closure hstate,
        generativeClosure_eq_of_compressedLibraryState_eq
          catalog closure hstate⟩

/-- The realizable compressed carriers agree after a redundant deletion. -/
theorem redundantDeletion_ofLibrary_eq
    {library : Raw.Library catalog} {strategy : model.StrategyId}
    {hstrategy : strategy ≠ catalog.inactiveStrategy}
    (hoperational :
      operationallyRedundant library strategy hstrategy)
    (hgenerative :
      generativelyRedundant (closure := closure) library strategy hstrategy) :
    CompressedLibraryState.ofLibrary catalog closure
        (library.erase strategy hstrategy) =
      CompressedLibraryState.ofLibrary catalog closure library := by
  apply CompressedLibraryState.ext
  exact redundantDeletion_compressedLibraryState_eq hoperational hgenerative

/-- Redundant deletion preserves the unified process observations. -/
theorem redundantDeletion_dynamicInnovationEquivalent
    (process : Model model catalog closure)
    {library : Raw.Library catalog} {strategy : model.StrategyId}
    {hstrategy : strategy ≠ catalog.inactiveStrategy}
    (hoperational :
      operationallyRedundant library strategy hstrategy)
    (hgenerative :
      generativelyRedundant (closure := closure) library strategy hstrategy) :
    DynamicInnovationEquivalent process
      (library.erase strategy hstrategy) library :=
  process.compressedState_eq_implies_dynamicInnovationEquivalent
    (redundantDeletion_compressedLibraryState_eq hoperational hgenerative)

/--
T1 finite-horizon projection makes raw value invariant under a redundant
deletion, for every horizon and belief.
-/
theorem redundantDeletion_preserves_finiteHorizonValue
    (process : Model model catalog closure)
    {library : Raw.Library catalog} {strategy : model.StrategyId}
    {hstrategy : strategy ≠ catalog.inactiveStrategy}
    (hoperational :
      operationallyRedundant library strategy hstrategy)
    (hgenerative :
      generativelyRedundant (closure := closure) library strategy hstrategy) :
    ∀ horizon belief,
      process.rawValue horizon belief (library.erase strategy hstrategy) =
        process.rawValue horizon belief library := by
  intro horizon belief
  rw [process.rawValue_eq_compressedValue,
    process.rawValue_eq_compressedValue]
  rw [redundantDeletion_ofLibrary_eq hoperational hgenerative]

/-- The two redundancy checks construct a unified innovation-safety certificate. -/
theorem redundantDeletion_innovationSafe
    (process : Model model catalog closure)
    {library : Raw.Library catalog} {strategy : model.StrategyId}
    {hstrategy : strategy ≠ catalog.inactiveStrategy}
    (hoperational :
      operationallyRedundant library strategy hstrategy)
    (hgenerative :
      generativelyRedundant (closure := closure) library strategy hstrategy) :
    InnovationSafeDeletion process library strategy hstrategy where
  observations :=
    process.redundantDeletion_dynamicInnovationEquivalent
      hoperational hgenerative
  finiteHorizonValue :=
    process.redundantDeletion_preserves_finiteHorizonValue
      hoperational hgenerative

/-- Safety exposes exact availability-tagged project-cost preservation. -/
theorem InnovationSafeDeletion.projectCost
    {process : Model model catalog closure}
    {library : Raw.Library catalog} {strategy : model.StrategyId}
    {hstrategy : strategy ≠ catalog.inactiveStrategy}
    (hsafe : InnovationSafeDeletion process library strategy hstrategy)
    (belief : model.Belief) (project : model.ResearchProject) :
    process.availableProjectData
        (CompressedLibraryState.ofLibrary catalog closure
          (library.erase strategy hstrategy)) project
        (process.researchCost belief
          (CompressedLibraryState.ofLibrary catalog closure
            (library.erase strategy hstrategy)) project) =
      process.availableProjectData
        (CompressedLibraryState.ofLibrary catalog closure library) project
        (process.researchCost belief
          (CompressedLibraryState.ofLibrary catalog closure library) project) :=
  hsafe.observations.projectCost belief project

/-- Safety exposes exact availability-tagged duration preservation. -/
theorem InnovationSafeDeletion.projectDuration
    {process : Model model catalog closure}
    {library : Raw.Library catalog} {strategy : model.StrategyId}
    {hstrategy : strategy ≠ catalog.inactiveStrategy}
    (hsafe : InnovationSafeDeletion process library strategy hstrategy)
    (project : model.ResearchProject) :
    process.availableProjectData
        (CompressedLibraryState.ofLibrary catalog closure
          (library.erase strategy hstrategy)) project
        (process.duration project) =
      process.availableProjectData
        (CompressedLibraryState.ofLibrary catalog closure library) project
        (process.duration project) :=
  hsafe.observations.projectDuration project

/-- Safety exposes the exact tagged joint terminal-law preservation. -/
theorem InnovationSafeDeletion.nextStateLaw
    {process : Model model catalog closure}
    {library : Raw.Library catalog} {strategy : model.StrategyId}
    {hstrategy : strategy ≠ catalog.inactiveStrategy}
    (hsafe : InnovationSafeDeletion process library strategy hstrategy)
    (belief : model.Belief) (project : model.ResearchProject) :
    process.availableProjectData
        (CompressedLibraryState.ofLibrary catalog closure
          (library.erase strategy hstrategy)) project
        (process.projectNextStateLaw belief
          (CompressedLibraryState.ofLibrary catalog closure
            (library.erase strategy hstrategy)) project) =
      process.availableProjectData
        (CompressedLibraryState.ofLibrary catalog closure library) project
        (process.projectNextStateLaw belief
          (CompressedLibraryState.ofLibrary catalog closure library) project) :=
  hsafe.observations.nextStateLaw belief project

/-- Safety also preserves the exact operating-reward block during research. -/
theorem InnovationSafeDeletion.operatingReward
    {process : Model model catalog closure}
    {library : Raw.Library catalog} {strategy : model.StrategyId}
    {hstrategy : strategy ≠ catalog.inactiveStrategy}
    (hsafe : InnovationSafeDeletion process library strategy hstrategy)
    (belief : model.Belief) (project : model.ResearchProject) :
    process.availableProjectData
        (CompressedLibraryState.ofLibrary catalog closure
          (library.erase strategy hstrategy)) project
        (process.expectedOperatingReward belief
          (CompressedLibraryState.ofLibrary catalog closure
            (library.erase strategy hstrategy)) project) =
      process.availableProjectData
        (CompressedLibraryState.ofLibrary catalog closure library) project
        (process.expectedOperatingReward belief
          (CompressedLibraryState.ofLibrary catalog closure library) project) :=
  hsafe.observations.operatingReward belief project

/--
T1 fixed-point projection makes the discounted infinite-horizon raw value
invariant under a redundant deletion.
-/
theorem DiscountedContractionModel.redundantDeletion_preserves_infiniteHorizonValue
    {process : Model model catalog closure}
    (contraction : DiscountedContractionModel process)
    {library : Raw.Library catalog} {strategy : model.StrategyId}
    {hstrategy : strategy ≠ catalog.inactiveStrategy}
    (hoperational :
      operationallyRedundant library strategy hstrategy)
    (hgenerative :
      generativelyRedundant (closure := closure) library strategy hstrategy)
    (belief : model.Belief) :
    contraction.rawFixedPoint
        (belief, library.erase strategy hstrategy) =
      contraction.rawFixedPoint (belief, library) := by
  rw [contraction.raw_fixedPoint_value_eq_compressed,
    contraction.raw_fixedPoint_value_eq_compressed]
  rw [redundantDeletion_ofLibrary_eq hoperational hgenerative]

/-! ## Stationary action comparisons -/

/-- Availability of a stationary raw-library action, expressed without subtypes. -/
def stationaryActionAvailable (process : Model model catalog closure)
    (library : Raw.Library catalog) : Action model → Prop
  | none => True
  | some project =>
      project ∈ process.available
        (CompressedLibraryState.ofLibrary catalog closure library)

/--
The stationary fixed-point value of an action signature.  Project signatures
use the unified cost/reward/joint-law form; unavailable signatures are harmless
because optimality below quantifies only over `stationaryActionAvailable`.
-/
noncomputable def fixedPointActionValue
    {process : Model model catalog closure}
    (contraction : DiscountedContractionModel process)
    (belief : model.Belief) (library : Raw.Library catalog) :
    Action model → ℝ
  | none =>
      let state := CompressedLibraryState.ofLibrary catalog closure library
      (state.state.frontier belief : ℝ) + (process.discount : ℝ) *
        BellmanContraction.realExpectedValue (process.beliefTransition belief)
          (fun nextBelief =>
            contraction.compressedFixedPoint (nextBelief, state))
  | some project =>
      process.compressedInfiniteProjectActionValue
        contraction.compressedFixedPoint belief
        (CompressedLibraryState.ofLibrary catalog closure library) project

/-- A stationary action maximizes the fixed-point value over the feasible menu. -/
def IsOptimalFixedPointAction
    {process : Model model catalog closure}
    (contraction : DiscountedContractionModel process)
    (belief : model.Belief) (library : Raw.Library catalog)
    (action : Action model) : Prop :=
  process.stationaryActionAvailable library action ∧
    ∀ other,
      process.stationaryActionAvailable library other →
      fixedPointActionValue contraction belief library other ≤
          fixedPointActionValue contraction belief library action

/-- Equal raw compressed states give identical stationary action availability. -/
theorem stationaryActionAvailable_iff_of_compressedState_eq
    (process : Model model catalog closure) {left right : Raw.Library catalog}
    (hstate :
      compressedLibraryState catalog closure left =
        compressedLibraryState catalog closure right)
    (action : Action model) :
    process.stationaryActionAvailable left action ↔
      process.stationaryActionAvailable right action := by
  have hofLibrary :
      CompressedLibraryState.ofLibrary catalog closure left =
        CompressedLibraryState.ofLibrary catalog closure right := by
    apply CompressedLibraryState.ext
    exact hstate
  cases action <;> simp [stationaryActionAvailable, hofLibrary]

/-- Equal raw compressed states give identical stationary action values. -/
theorem DiscountedContractionModel.fixedPointActionValue_eq_of_compressedState_eq
    {process : Model model catalog closure}
    (contraction : DiscountedContractionModel process)
    {left right : Raw.Library catalog}
    (hstate :
      compressedLibraryState catalog closure left =
        compressedLibraryState catalog closure right)
    (belief : model.Belief) (action : Action model) :
    fixedPointActionValue contraction belief left action =
      fixedPointActionValue contraction belief right action := by
  have hofLibrary :
      CompressedLibraryState.ofLibrary catalog closure left =
        CompressedLibraryState.ofLibrary catalog closure right := by
    apply CompressedLibraryState.ext
    exact hstate
  cases action <;> simp [fixedPointActionValue, hofLibrary]

/-- Every pairwise stationary action-value comparison survives deletion. -/
theorem DiscountedContractionModel.redundantDeletion_preserves_actionValueComparison
    {process : Model model catalog closure}
    (contraction : DiscountedContractionModel process)
    {library : Raw.Library catalog} {strategy : model.StrategyId}
    {hstrategy : strategy ≠ catalog.inactiveStrategy}
    (hoperational :
      operationallyRedundant library strategy hstrategy)
    (hgenerative :
      generativelyRedundant (closure := closure) library strategy hstrategy)
    (belief : model.Belief) (leftAction rightAction : Action model) :
    (fixedPointActionValue contraction belief
        (library.erase strategy hstrategy) leftAction ≤
      fixedPointActionValue contraction belief
        (library.erase strategy hstrategy) rightAction) ↔
    (fixedPointActionValue contraction belief library leftAction ≤
      fixedPointActionValue contraction belief library rightAction) := by
  have hstate :=
    redundantDeletion_compressedLibraryState_eq hoperational hgenerative
  rw [contraction.fixedPointActionValue_eq_of_compressedState_eq
      hstate belief leftAction,
    contraction.fixedPointActionValue_eq_of_compressedState_eq
      hstate belief rightAction]

/-- Optimal stationary actions are exactly preserved by redundant deletion. -/
theorem DiscountedContractionModel.redundantDeletion_preserves_optimalAction
    {process : Model model catalog closure}
    (contraction : DiscountedContractionModel process)
    {library : Raw.Library catalog} {strategy : model.StrategyId}
    {hstrategy : strategy ≠ catalog.inactiveStrategy}
    (hoperational :
      operationallyRedundant library strategy hstrategy)
    (hgenerative :
      generativelyRedundant (closure := closure) library strategy hstrategy)
    (belief : model.Belief) (action : Action model) :
    IsOptimalFixedPointAction contraction belief
        (library.erase strategy hstrategy) action ↔
      IsOptimalFixedPointAction contraction belief library action := by
  have hstate :=
    redundantDeletion_compressedLibraryState_eq hoperational hgenerative
  have havailable := process.stationaryActionAvailable_iff_of_compressedState_eq
    hstate
  have hvalue := contraction.fixedPointActionValue_eq_of_compressedState_eq
    hstate belief
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

/-! ## Detectable converse -/

/--
Under raw closure detectability, preservation of the unified process
observations is equivalent to operational and generative redundancy.
-/
theorem deletionProcessObservations_iff_redundant
    (process : Model model catalog closure)
    (hdetectable : RawClosureDetectable process)
    {library : Raw.Library catalog} {strategy : model.StrategyId}
    {hstrategy : strategy ≠ catalog.inactiveStrategy} :
    DynamicInnovationEquivalent process
        (library.erase strategy hstrategy) library ↔
      RedundantDeletion (closure := closure) library strategy hstrategy := by
  simpa [RedundantDeletion, operationallyRedundant, generativelyRedundant] using
    (process.dynamicInnovationEquivalent_iff_frontierClosure_eq
      hdetectable
      (left := library.erase strategy hstrategy) (right := library))

/--
T3 converse relative to process observations.  Detectability is needed only
for the implication from observable safety back to latent closure preservation.
-/
theorem innovationSafeDeletion_iff_redundant
    (process : Model model catalog closure)
    (hdetectable : RawClosureDetectable process)
    {library : Raw.Library catalog} {strategy : model.StrategyId}
    {hstrategy : strategy ≠ catalog.inactiveStrategy} :
    InnovationSafeDeletion process library strategy hstrategy ↔
      RedundantDeletion (closure := closure) library strategy hstrategy := by
  constructor
  · intro hsafe
    exact (process.deletionProcessObservations_iff_redundant
      hdetectable).mp hsafe.observations
  · rintro ⟨hoperational, hgenerative⟩
    exact process.redundantDeletion_innovationSafe
      hoperational hgenerative

/-! ## Rechecked stepwise deletion and pruning specifications -/

/--
A finite deletion trace whose two redundancy predicates are rechecked at the
current intermediate library before every erasure.
-/
inductive RedundantDeletionSequence
    (catalog : Raw.StrategyCatalog model) (closure : Raw.ClosureOperator model) :
    Raw.Library catalog → List model.StrategyId → Raw.Library catalog → Prop
  | nil (library : Raw.Library catalog) :
      RedundantDeletionSequence catalog closure library [] library
  | cons (library : Raw.Library catalog) (strategy : model.StrategyId)
      (hstrategy : strategy ≠ catalog.inactiveStrategy)
      (hoperational :
        operationallyRedundant library strategy hstrategy)
      (hgenerative :
        generativelyRedundant (closure := closure) library strategy hstrategy)
      {deletions : List model.StrategyId} {final : Raw.Library catalog}
      (tail :
        RedundantDeletionSequence catalog closure
          (library.erase strategy hstrategy) deletions final) :
      RedundantDeletionSequence catalog closure
        library (strategy :: deletions) final

/-- A trace carrying an innovation-safety certificate at every deletion. -/
inductive InnovationSafeDeletionSequence
    (process : Model model catalog closure) :
    Raw.Library catalog → List model.StrategyId → Raw.Library catalog → Prop
  | nil (library : Raw.Library catalog) :
      InnovationSafeDeletionSequence process library [] library
  | cons (library : Raw.Library catalog) (strategy : model.StrategyId)
      (hstrategy : strategy ≠ catalog.inactiveStrategy)
      (hsafe : InnovationSafeDeletion process library strategy hstrategy)
      {deletions : List model.StrategyId} {final : Raw.Library catalog}
      (tail :
        InnovationSafeDeletionSequence process
          (library.erase strategy hstrategy) deletions final) :
      InnovationSafeDeletionSequence process
        library (strategy :: deletions) final

/-- Rechecked deletions leave the final library as a sublibrary of the initial one. -/
theorem RedundantDeletionSequence.final_le_initial
    {initial final : Raw.Library catalog} {deletions : List model.StrategyId}
    (sequence :
      RedundantDeletionSequence catalog closure initial deletions final) :
    final ≤ initial := by
  induction sequence with
  | nil library => exact le_rfl
  | cons library strategy hstrategy _ _ tail inductionHypothesis =>
      exact inductionHypothesis.trans
        (Library.erase_le library strategy hstrategy)

/-- Rechecked deletion preserves the compressed state through the whole trace. -/
theorem RedundantDeletionSequence.compressedLibraryState_final_eq_initial
    {initial final : Raw.Library catalog} {deletions : List model.StrategyId}
    (sequence :
      RedundantDeletionSequence catalog closure initial deletions final) :
    compressedLibraryState catalog closure final =
      compressedLibraryState catalog closure initial := by
  induction sequence with
  | nil library => rfl
  | cons library strategy hstrategy hoperational hgenerative tail
      inductionHypothesis =>
      exact inductionHypothesis.trans
        (redundantDeletion_compressedLibraryState_eq
          hoperational hgenerative)

/-- Every rechecked step receives a unified innovation-safety certificate. -/
theorem RedundantDeletionSequence.everyDeletion_innovationSafe
    (process : Model model catalog closure)
    {initial final : Raw.Library catalog} {deletions : List model.StrategyId}
    (sequence :
      RedundantDeletionSequence catalog closure initial deletions final) :
    InnovationSafeDeletionSequence process initial deletions final := by
  induction sequence with
  | nil library =>
      exact InnovationSafeDeletionSequence.nil library
  | cons library strategy hstrategy hoperational hgenerative tail
      inductionHypothesis =>
      exact InnovationSafeDeletionSequence.cons library strategy hstrategy
        (process.redundantDeletion_innovationSafe
          hoperational hgenerative)
        inductionHypothesis

/-- The final and initial libraries in a rechecked trace are unified DI-equivalent. -/
theorem RedundantDeletionSequence.dynamicInnovationEquivalent
    (process : Model model catalog closure)
    {initial final : Raw.Library catalog} {deletions : List model.StrategyId}
    (sequence :
      RedundantDeletionSequence catalog closure initial deletions final) :
    DynamicInnovationEquivalent process initial final := by
  apply process.dynamicInnovationEquivalent_symm
  exact process.compressedState_eq_implies_dynamicInnovationEquivalent
    sequence.compressedLibraryState_final_eq_initial

/-- Rechecked stepwise deletion preserves every finite-horizon raw value. -/
theorem RedundantDeletionSequence.preserves_finiteHorizonValue
    (process : Model model catalog closure)
    {initial final : Raw.Library catalog} {deletions : List model.StrategyId}
    (sequence :
      RedundantDeletionSequence catalog closure initial deletions final)
    (horizon : Nat) (belief : model.Belief) :
    process.rawValue horizon belief initial =
      process.rawValue horizon belief final :=
  process.rawValue_eq_of_dynamicInnovationEquivalent
    (sequence.dynamicInnovationEquivalent process) horizon belief

/-- Rechecked stepwise deletion preserves the contraction fixed-point value. -/
theorem RedundantDeletionSequence.preserves_infiniteHorizonValue
    {process : Model model catalog closure}
    (contraction : DiscountedContractionModel process)
    {initial final : Raw.Library catalog} {deletions : List model.StrategyId}
    (sequence :
      RedundantDeletionSequence catalog closure initial deletions final)
    (belief : model.Belief) :
    contraction.rawFixedPoint (belief, initial) =
      contraction.rawFixedPoint (belief, final) :=
  contraction.rawFixedPoint_eq_of_dynamicInnovationEquivalent
    (sequence.dynamicInnovationEquivalent process) belief

/--
Specification of a pruning algorithm: its output is accompanied by a finite
trace that rechecks both redundancy predicates at every intermediate library.
-/
structure PruningAlgorithmSpec
    (catalog : Raw.StrategyCatalog model) (closure : Raw.ClosureOperator model) where
  prune : Raw.Library catalog → Raw.Library catalog
  deletions : Raw.Library catalog → List model.StrategyId
  valid : ∀ library,
    RedundantDeletionSequence catalog closure
      library (deletions library) (prune library)

/-- Every individual deletion certified by a conforming pruning algorithm is safe. -/
theorem PruningAlgorithmSpec.everyDeletion_safe
    (specification : PruningAlgorithmSpec catalog closure)
    (process : Model model catalog closure) (library : Raw.Library catalog) :
    InnovationSafeDeletionSequence process library
      (specification.deletions library) (specification.prune library) :=
  (specification.valid library).everyDeletion_innovationSafe process

/-- A conforming pruning algorithm returns a dynamically equivalent library. -/
theorem PruningAlgorithmSpec.output_dynamicInnovationEquivalent
    (specification : PruningAlgorithmSpec catalog closure)
    (process : Model model catalog closure) (library : Raw.Library catalog) :
    DynamicInnovationEquivalent process library (specification.prune library) :=
  (specification.valid library).dynamicInnovationEquivalent process

/-- A conforming pruning algorithm preserves every finite-horizon raw value. -/
theorem PruningAlgorithmSpec.output_preserves_finiteHorizonValue
    (specification : PruningAlgorithmSpec catalog closure)
    (process : Model model catalog closure) (library : Raw.Library catalog)
    (horizon : Nat) (belief : model.Belief) :
    process.rawValue horizon belief library =
      process.rawValue horizon belief (specification.prune library) :=
  (specification.valid library).preserves_finiteHorizonValue
    process horizon belief

end Model

end Projection

end StrategyInnovation
