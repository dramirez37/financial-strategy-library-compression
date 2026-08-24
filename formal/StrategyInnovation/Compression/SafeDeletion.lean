import StrategyInnovation.Quotient.FrontierClosure

/-!
# Innovation-safe single and repeated deletion

This file separates three notions that need not coincide:

* exact equality of the frontier--closure compressed state after deletion;
* dynamic innovation equivalence, which observes current rewards and every
  allowed project-transition distribution; and
* equality of the abstract finite-horizon values.

Frontier and closure preservation imply dynamic innovation equivalence for a
factorized modular generator, and hence imply value preservation.  The reverse
implication from transition observations uses closure identifiability.  Value
equality alone has no such converse in the present semantics; an exact finite
counterexample below uses zero discount.
-/

namespace StrategyInnovation

/--
A noninactive strategy is operationally redundant in a library when deleting
it leaves the complete operational frontier unchanged.
-/
def operationallyRedundant {model : FiniteModel}
    (catalog : StrategyCatalog model)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hstrategy : strategy ≠ catalog.inactiveStrategy) : Prop :=
  operationalFrontier catalog (library.erase strategy hstrategy) =
    operationalFrontier catalog library

/--
A noninactive strategy is generatively redundant in a library when deleting it
leaves the complete generative closure unchanged.
-/
def generativelyRedundant {model : FiniteModel}
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hstrategy : strategy ≠ catalog.inactiveStrategy) : Prop :=
  generativeClosure catalog moduleClosure (library.erase strategy hstrategy) =
    generativeClosure catalog moduleClosure library

/--
Deleting a strategy preserves the exact frontier--closure compressed state.

This predicate is intentionally distinct from both dynamic innovation
equivalence and finite-horizon value equality.
-/
def compressedStatePreservingDeletion {model : FiniteModel}
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hstrategy : strategy ≠ catalog.inactiveStrategy) : Prop :=
  compressedLibraryState catalog moduleClosure
      (library.erase strategy hstrategy) =
    compressedLibraryState catalog moduleClosure library

/--
A strategy is safely deletable for an abstract research semantics when its
deletion preserves exact dynamic value at every finite horizon and belief.

No converse from this value-only predicate to compressed-state equality is
built into the definition.
-/
def safelyDeletable {model : FiniteModel}
    (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hstrategy : strategy ≠ catalog.inactiveStrategy) : Prop :=
  ∀ horizon belief,
    dynamicLibraryValue semantics catalog moduleClosure horizon belief library =
      dynamicLibraryValue semantics catalog moduleClosure horizon belief
        (library.erase strategy hstrategy)

/--
Deletion preserves the observations defining dynamic innovation equivalence:
every current reward and every allowed project-transition distribution.
-/
def deletionPreservesCurrentRewardAndProjects {model : FiniteModel}
    (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hstrategy : strategy ≠ catalog.inactiveStrategy) : Prop :=
  OperationallyEquivalent catalog library (library.erase strategy hstrategy) ∧
    ∀ belief project,
      semantics.researchTransition belief
          (compressedLibraryState catalog moduleClosure library) project =
        semantics.researchTransition belief
          (compressedLibraryState catalog moduleClosure
            (library.erase strategy hstrategy)) project

/--
Operational and generative redundancy are exactly equality of the declared
frontier--closure compressed state after deletion.
-/
theorem redundantDeletion_iff_compressedStatePreservingDeletion
    {model : FiniteModel}
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hstrategy : strategy ≠ catalog.inactiveStrategy) :
    operationallyRedundant catalog library strategy hstrategy ∧
        generativelyRedundant catalog moduleClosure library strategy hstrategy ↔
      compressedStatePreservingDeletion
        catalog moduleClosure library strategy hstrategy := by
  constructor
  · rintro ⟨hfrontier, hclosure⟩
    unfold compressedStatePreservingDeletion compressedLibraryState
    rw [hfrontier, hclosure]
  · intro hstate
    exact
      ⟨operationalFrontier_eq_of_compressedLibraryState_eq
          catalog moduleClosure hstate,
        generativeClosure_eq_of_compressedLibraryState_eq
          catalog moduleClosure hstate⟩

/--
Sufficient deletion criterion: preserving both frontier and closure implies
dynamic innovation equivalence for any factorized modular generator.
-/
theorem redundantDeletion_dynamicInnovationEquivalent
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (generator : ModularGenerator model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (hfactor : GeneratorFactorsThroughFrontierClosure semantics generator)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hstrategy : strategy ≠ catalog.inactiveStrategy)
    (hredundant :
      operationallyRedundant catalog library strategy hstrategy ∧
        generativelyRedundant
          catalog moduleClosure library strategy hstrategy) :
    DynamicInnovationEquivalent semantics catalog moduleClosure
      library (library.erase strategy hstrategy) :=
  frontierClosure_eq_implies_dynamicInnovationEquivalent
    semantics generator catalog moduleClosure hfactor
      hredundant.1.symm hredundant.2.symm

/--
Operational and generative redundancy imply exact finite-horizon value
preservation for the deletion.
-/
theorem redundantDeletion_safelyDeletable
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (generator : ModularGenerator model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (hfactor : GeneratorFactorsThroughFrontierClosure semantics generator)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hstrategy : strategy ≠ catalog.inactiveStrategy)
    (hredundant :
      operationallyRedundant catalog library strategy hstrategy ∧
        generativelyRedundant
          catalog moduleClosure library strategy hstrategy) :
    safelyDeletable semantics catalog moduleClosure
      library strategy hstrategy :=
  finiteHorizonValue_eq_of_dynamicInnovationEquivalent
    semantics catalog moduleClosure
      (redundantDeletion_dynamicInnovationEquivalent
        semantics generator catalog moduleClosure hfactor
        library strategy hstrategy hredundant)

/--
The explicit deletion observations are precisely dynamic innovation
equivalence between the original and erased libraries.
-/
theorem deletionPreservesCurrentRewardAndProjects_iff_dynamicInnovationEquivalent
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hstrategy : strategy ≠ catalog.inactiveStrategy) :
    deletionPreservesCurrentRewardAndProjects
        semantics catalog moduleClosure library strategy hstrategy ↔
      DynamicInnovationEquivalent semantics catalog moduleClosure
        library (library.erase strategy hstrategy) :=
  Iff.rfl

/--
Converse under the exact detectability assumptions: preservation of every
current reward and every allowed project-transition law forces preservation of
both the frontier and the generative closure.

This theorem does not replace its observation hypothesis by value equality.
-/
theorem deletionObservations_imply_operationallyAndGenerativelyRedundant
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (generator : ModularGenerator model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (hfactor : GeneratorFactorsThroughFrontierClosure semantics generator)
    (hidentifiable : ClosureIdentifiable generator catalog moduleClosure)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hstrategy : strategy ≠ catalog.inactiveStrategy)
    (hpreserves :
      deletionPreservesCurrentRewardAndProjects
        semantics catalog moduleClosure library strategy hstrategy) :
    operationallyRedundant catalog library strategy hstrategy ∧
      generativelyRedundant
        catalog moduleClosure library strategy hstrategy := by
  rcases dynamicInnovationEquivalent_implies_frontierClosure_eq
      semantics generator catalog moduleClosure hfactor hidentifiable
      hpreserves with
    ⟨hfrontier, hclosure⟩
  exact ⟨hfrontier.symm, hclosure.symm⟩

/--
Under factorization and closure identifiability, deletion preserves the
defining dynamic observations exactly when it preserves frontier and closure.
-/
theorem deletionPreservesCurrentRewardAndProjects_iff_redundant
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (generator : ModularGenerator model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (hfactor : GeneratorFactorsThroughFrontierClosure semantics generator)
    (hidentifiable : ClosureIdentifiable generator catalog moduleClosure)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hstrategy : strategy ≠ catalog.inactiveStrategy) :
    deletionPreservesCurrentRewardAndProjects
        semantics catalog moduleClosure library strategy hstrategy ↔
      operationallyRedundant catalog library strategy hstrategy ∧
        generativelyRedundant
          catalog moduleClosure library strategy hstrategy := by
  constructor
  · exact deletionObservations_imply_operationallyAndGenerativelyRedundant
      semantics generator catalog moduleClosure hfactor hidentifiable
      library strategy hstrategy
  · intro hredundant
    exact redundantDeletion_dynamicInnovationEquivalent
      semantics generator catalog moduleClosure hfactor
      library strategy hstrategy hredundant

/--
A proof-relevant sequence of safe deletions.  Each step is checked against the
library produced by all preceding deletions.
-/
inductive SafeDeletionSequence {model : FiniteModel}
    (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model) :
    Library model catalog.inactiveStrategy → List model.StrategyId →
      Library model catalog.inactiveStrategy → Prop
  | nil (library) : SafeDeletionSequence semantics catalog moduleClosure
      library [] library
  | cons {library finalLibrary}
      (strategy : model.StrategyId)
      (hstrategy : strategy ≠ catalog.inactiveStrategy)
      (hsafe :
        safelyDeletable semantics catalog moduleClosure
          library strategy hstrategy)
      {remaining : List model.StrategyId}
      (htail :
        SafeDeletionSequence semantics catalog moduleClosure
          (library.erase strategy hstrategy) remaining finalLibrary) :
      SafeDeletionSequence semantics catalog moduleClosure
        library (strategy :: remaining) finalLibrary

/-- Every safe deletion sequence ends in a sublibrary of its initial library. -/
theorem safeDeletionSequence_sublibrary
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    {initial finalLibrary : Library model catalog.inactiveStrategy}
    {strategies : List model.StrategyId}
    (hsequence :
      SafeDeletionSequence semantics catalog moduleClosure
        initial strategies finalLibrary) :
    finalLibrary ≤ initial := by
  induction hsequence with
  | nil =>
      exact le_rfl
  | cons strategy hstrategy hsafe htail inductionHypothesis =>
      exact inductionHypothesis.trans
        (Library.erase_le _ strategy hstrategy)

/--
Repeated safe deletion preserves exact finite-horizon value at every belief.
-/
theorem safeDeletionSequence_preserves_finiteHorizonValue
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    {initial finalLibrary : Library model catalog.inactiveStrategy}
    {strategies : List model.StrategyId}
    (hsequence :
      SafeDeletionSequence semantics catalog moduleClosure
        initial strategies finalLibrary) :
    ∀ horizon belief,
      dynamicLibraryValue semantics catalog moduleClosure
          horizon belief initial =
        dynamicLibraryValue semantics catalog moduleClosure
          horizon belief finalLibrary := by
  induction hsequence with
  | nil =>
      intro horizon belief
      rfl
  | cons strategy hstrategy hsafe htail inductionHypothesis =>
      intro horizon belief
      exact (hsafe horizon belief).trans
        (inductionHypothesis horizon belief)

/--
An innovation-safe compression is a sublibrary with exactly the same
finite-horizon value at every belief.
-/
def InnovationSafeCompression {model : FiniteModel}
    (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (source compressed : Library model catalog.inactiveStrategy) : Prop :=
  compressed ≤ source ∧
    ∀ horizon belief,
      dynamicLibraryValue semantics catalog moduleClosure horizon belief source =
        dynamicLibraryValue semantics catalog moduleClosure
          horizon belief compressed

/--
The endpoint of any safe deletion sequence is an innovation-safe compression
of its initial library.
-/
theorem safeDeletionSequence_innovationSafeCompression
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    {initial finalLibrary : Library model catalog.inactiveStrategy}
    {strategies : List model.StrategyId}
    (hsequence :
      SafeDeletionSequence semantics catalog moduleClosure
        initial strategies finalLibrary) :
    InnovationSafeCompression semantics catalog moduleClosure
      initial finalLibrary :=
  ⟨safeDeletionSequence_sublibrary
      semantics catalog moduleClosure hsequence,
    safeDeletionSequence_preserves_finiteHorizonValue
      semantics catalog moduleClosure hsequence⟩

/-! ## Exact examples and the value-only converse boundary -/

namespace SafeDeletionCounterexamples

open FrontierClosureCounterexamples

/-- Point masses on the ambient innovation state reveal their state exactly. -/
theorem ratProb_dirac_injective {α : Type*} :
    Function.Injective (@RatProb.dirac α) := by
  intro left right hequal
  apply Finsupp.single_left_injective (by norm_num : (1 : ℚ) ≠ 0)
  exact congrArg RatProb.mass hequal

/--
An exact generator that returns a point mass at the supplied frontier--closure
pair, making distinct closures transition-detectable.
-/
noncomputable def revealingGenerator : ModularGenerator model where
  candidateTransition := fun _ frontier closure _ =>
    RatProb.dirac ⟨frontier, closure⟩

/-- Exact zero-discount semantics induced by the revealing generator. -/
noncomputable def revealingSemantics : FiniteResearchSemantics model where
  beliefKernel := fun _ => RatProb.dirac Belief.only
  researchTransition := fun belief state project =>
    revealingGenerator.candidateTransition
      belief state.frontier state.closure project
  discount := 0
  discount_nonnegative := by norm_num
  discount_lt_one := by norm_num

/-- The bridge is distinct from the distinguished inactive strategy. -/
theorem bridge_ne_inactive :
    Strategy.bridge ≠ catalog.inactiveStrategy := by
  decide

/-- The revealing semantics satisfies generator factorization definitionally. -/
theorem revealingSemantics_factors :
    GeneratorFactorsThroughFrontierClosure
      revealingSemantics revealingGenerator := by
  intro belief state project
  rfl

/-- The revealing generator identifies all distinct closures, realizable or not. -/
theorem revealingGenerator_closureIdentifiable :
    ClosureIdentifiable revealingGenerator catalog moduleClosure := by
  intro frontier leftClosure rightClosure
      hleftRealizable hrightRealizable hne
  refine ⟨Belief.only, Project.probe, ?_⟩
  intro hequal
  apply hne
  have hstate :
      (⟨frontier, leftClosure⟩ : InnovationState model) =
        ⟨frontier, rightClosure⟩ := by
    exact ratProb_dirac_injective hequal
  exact congrArg InnovationState.closure hstate

/-- Deleting the bridge leaves exactly the inactive-only library. -/
theorem bridgeLibrary_erase_eq_inactiveLibrary :
    bridgeLibrary.erase Strategy.bridge bridge_ne_inactive =
      inactiveLibrary := by
  apply Library.ext
  change
    ({Strategy.inactive, Strategy.bridge} : Finset Strategy).erase
        Strategy.bridge =
      {Strategy.inactive}
  decide

/--
Even under factorization and closure identifiability, equality of all
finite-horizon values need not detect closure: with zero discount, the
operationally redundant bridge is value-safe but generatively essential.
-/
theorem finiteHorizonValuePreservation_does_not_imply_generativeRedundancy :
    GeneratorFactorsThroughFrontierClosure
        revealingSemantics revealingGenerator ∧
      ClosureIdentifiable revealingGenerator catalog moduleClosure ∧
      safelyDeletable revealingSemantics catalog moduleClosure
        bridgeLibrary Strategy.bridge bridge_ne_inactive ∧
      ¬ generativelyRedundant catalog moduleClosure
        bridgeLibrary Strategy.bridge bridge_ne_inactive := by
  refine
    ⟨revealingSemantics_factors,
      revealingGenerator_closureIdentifiable, ?_, ?_⟩
  · intro horizon belief
    rw [bridgeLibrary_erase_eq_inactiveLibrary]
    cases horizon with
    | zero =>
        rfl
    | succ horizon =>
        simp only [dynamicLibraryValue, compressedFiniteHorizonValue]
        simp only [revealingSemantics, zero_mul, add_zero]
        change
          operationalFrontier catalog bridgeLibrary belief =
            operationalFrontier catalog inactiveLibrary belief
        exact congrFun inactive_bridge_frontiers_eq.symm belief
  · intro hredundant
    apply inactive_bridge_closures_ne
    rw [← bridgeLibrary_erase_eq_inactiveLibrary]
    exact hredundant

end SafeDeletionCounterexamples

/-! ## Small executable examples of the three redundancy combinations -/

namespace SafeDeletionExamples

inductive Belief
  | only
  deriving DecidableEq, Fintype

instance : Nonempty Belief :=
  ⟨Belief.only⟩

inductive Strategy
  | inactive
  | leader
  | duplicate
  deriving DecidableEq, Fintype

instance : Nonempty Strategy :=
  ⟨Strategy.inactive⟩

inductive Module
  | signal
  deriving DecidableEq, Fintype

instance : Nonempty Module :=
  ⟨Module.signal⟩

inductive Project
  | probe
  deriving DecidableEq, Fintype

instance : Nonempty Project :=
  ⟨Project.probe⟩

/-- One-belief carrier for exact deletion examples. -/
abbrev model : FiniteModel where
  Belief := Belief
  StrategyId := Strategy
  ModuleId := Module
  ResearchProject := Project

def profile : Strategy → Belief → ℚ
  | .inactive, _ => 0
  | .leader, _ => 1
  | .duplicate, _ => 0

def modules : Strategy → Finset Module
  | .inactive => ∅
  | .leader => {Module.signal}
  | .duplicate => {Module.signal}

abbrev catalog : StrategyCatalog model where
  operationalProfile := profile
  strategyModules := modules
  inactiveStrategy := Strategy.inactive
  inactiveProfile := by
    intro belief
    cases belief
    rfl
  inactiveModules := rfl

abbrev moduleClosure : ModuleClosure model where
  close := id
  extensive := fun _ => Finset.Subset.refl _
  monotone := fun hinclude => hinclude
  idempotent := fun _ => rfl

def fullLibrary : Library model catalog.inactiveStrategy where
  strategies := {Strategy.inactive, Strategy.leader, Strategy.duplicate}
  inactive_mem := by simp

def leaderLibrary : Library model catalog.inactiveStrategy where
  strategies := {Strategy.inactive, Strategy.leader}
  inactive_mem := by simp

def duplicateLibrary : Library model catalog.inactiveStrategy where
  strategies := {Strategy.inactive, Strategy.duplicate}
  inactive_mem := by simp

/-- The duplicate example strategy is noninactive. -/
theorem duplicate_ne_inactive :
    Strategy.duplicate ≠ catalog.inactiveStrategy := by
  decide

/-- The leader example strategy is noninactive. -/
theorem leader_ne_inactive :
    Strategy.leader ≠ catalog.inactiveStrategy := by
  decide

example :
    operationallyRedundant catalog fullLibrary
        Strategy.duplicate duplicate_ne_inactive ∧
      generativelyRedundant catalog moduleClosure
        fullLibrary Strategy.duplicate duplicate_ne_inactive := by
  have herase :
      fullLibrary.erase Strategy.duplicate duplicate_ne_inactive =
        leaderLibrary := by
    apply Library.ext
    change
      ({Strategy.inactive, Strategy.leader, Strategy.duplicate} :
        Finset Strategy).erase Strategy.duplicate =
          {Strategy.inactive, Strategy.leader}
    decide
  have hinsert :
      fullLibrary = leaderLibrary.insert Strategy.duplicate := by
    apply Library.ext
    change
      ({Strategy.inactive, Strategy.leader, Strategy.duplicate} :
        Finset Strategy) =
          Insert.insert Strategy.duplicate
            {Strategy.inactive, Strategy.leader}
    decide
  constructor
  · change
      operationalFrontier catalog
          (fullLibrary.erase Strategy.duplicate duplicate_ne_inactive) =
        operationalFrontier catalog fullLibrary
    rw [herase, hinsert]
    exact (operationalFrontier_insert_of_operationallyRedundant
      catalog leaderLibrary Strategy.duplicate (by
        intro belief
        change 0 ≤ operationalFrontier catalog leaderLibrary belief
        exact zero_le_operationalFrontier
          catalog leaderLibrary belief)).symm
  · change
      generativeClosure catalog moduleClosure
          (fullLibrary.erase Strategy.duplicate duplicate_ne_inactive) =
        generativeClosure catalog moduleClosure fullLibrary
    rw [herase]
    simp [generativeClosure, rawModuleUnion,
      leaderLibrary, fullLibrary, catalog, modules]

example :
    operationallyRedundant
        FrontierClosureCounterexamples.catalog
        FrontierClosureCounterexamples.bridgeLibrary
        FrontierClosureCounterexamples.Strategy.bridge
          SafeDeletionCounterexamples.bridge_ne_inactive ∧
      ¬ generativelyRedundant
        FrontierClosureCounterexamples.catalog
        FrontierClosureCounterexamples.moduleClosure
        FrontierClosureCounterexamples.bridgeLibrary
        FrontierClosureCounterexamples.Strategy.bridge
          SafeDeletionCounterexamples.bridge_ne_inactive := by
  constructor
  · change
      operationalFrontier FrontierClosureCounterexamples.catalog
          (FrontierClosureCounterexamples.bridgeLibrary.erase
            FrontierClosureCounterexamples.Strategy.bridge
              SafeDeletionCounterexamples.bridge_ne_inactive) =
        operationalFrontier FrontierClosureCounterexamples.catalog
          FrontierClosureCounterexamples.bridgeLibrary
    rw [SafeDeletionCounterexamples.bridgeLibrary_erase_eq_inactiveLibrary]
    exact FrontierClosureCounterexamples.inactive_bridge_frontiers_eq
  · intro hredundant
    change
      generativeClosure
          FrontierClosureCounterexamples.catalog
          FrontierClosureCounterexamples.moduleClosure
          (FrontierClosureCounterexamples.bridgeLibrary.erase
            FrontierClosureCounterexamples.Strategy.bridge
              SafeDeletionCounterexamples.bridge_ne_inactive) =
        generativeClosure
          FrontierClosureCounterexamples.catalog
          FrontierClosureCounterexamples.moduleClosure
          FrontierClosureCounterexamples.bridgeLibrary at hredundant
    apply FrontierClosureCounterexamples.inactive_bridge_closures_ne
    rw [← SafeDeletionCounterexamples.bridgeLibrary_erase_eq_inactiveLibrary]
    exact hredundant

example :
    ¬ operationallyRedundant catalog fullLibrary
        Strategy.leader leader_ne_inactive ∧
      generativelyRedundant catalog moduleClosure
        fullLibrary Strategy.leader leader_ne_inactive := by
  have herase :
      fullLibrary.erase Strategy.leader leader_ne_inactive =
        duplicateLibrary := by
    apply Library.ext
    change
      ({Strategy.inactive, Strategy.leader, Strategy.duplicate} :
        Finset Strategy).erase Strategy.leader =
          {Strategy.inactive, Strategy.duplicate}
    decide
  constructor
  · intro hredundant
    change
      operationalFrontier catalog
          (fullLibrary.erase Strategy.leader leader_ne_inactive) =
        operationalFrontier catalog fullLibrary at hredundant
    have hremaining :
        operationalFrontier catalog
            (fullLibrary.erase Strategy.leader leader_ne_inactive)
            Belief.only ≤ 0 := by
      apply (operationalFrontier_le_iff catalog _ _ _).2
      intro strategy hstrategy
      change strategy ∈
        (({Strategy.inactive, Strategy.leader, Strategy.duplicate} :
          Finset Strategy).erase Strategy.leader) at hstrategy
      rcases Finset.mem_erase.mp hstrategy with
        ⟨hne, hmember⟩
      simp only [Finset.mem_insert, Finset.mem_singleton] at hmember
      have hcases :
          strategy = Strategy.inactive ∨
            strategy = Strategy.duplicate := by
        rcases hmember with hinactive | hleader | hduplicate
        · exact Or.inl hinactive
        · exact (hne hleader).elim
        · exact Or.inr hduplicate
      rcases hcases with rfl | rfl <;> rfl
    have hleader :
        (1 : ℚ) ≤
          operationalFrontier catalog fullLibrary Belief.only :=
      operationalProfile_le_frontier catalog _
        (strategy := Strategy.leader)
        (by
          change Strategy.leader ∈
            ({Strategy.inactive, Strategy.leader, Strategy.duplicate} :
              Finset Strategy)
          decide)
        Belief.only
    rw [← congrFun hredundant Belief.only] at hleader
    have : (1 : ℚ) ≤ 0 := hleader.trans hremaining
    norm_num at this
  · change
      generativeClosure catalog moduleClosure
          (fullLibrary.erase Strategy.leader leader_ne_inactive) =
        generativeClosure catalog moduleClosure fullLibrary
    rw [herase]
    simp [generativeClosure, rawModuleUnion,
      duplicateLibrary, fullLibrary, catalog, modules]

end SafeDeletionExamples

end StrategyInnovation
