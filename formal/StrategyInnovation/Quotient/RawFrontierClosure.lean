import StrategyInnovation.Quotient.UnifiedDynamicInnovation

/-!
# Raw frontier--closure characterization (T2)

This module proves the publication-facing T2 characterization from the raw
generator, verification/admission law, raw update, and T1 projection.  It does
not use the deprecated abstract transition table or its factorization premise.

The forward restriction is enforced by `Projection.Model` itself: generation
and admission take only project, belief, and closure; project feasibility,
cost, and the completion coupling take only the realizable compressed state;
and operating rewards read its frontier.  The first lemmas below expose these
dependencies directly on raw libraries.

The converse needs an observable raw-process separation assumption.  A change
in a latent candidate or admission primitive counts as detection only when it
survives admission, raw update, and T1 projection into the availability-tagged
joint next-belief/next-compressed-state law observed by dynamic innovation
equivalence.  This qualification is necessary: latent laws can differ while
having the same observable pushforward.
-/

namespace StrategyInnovation

namespace Projection

namespace Model

variable {model : FiniteModel}
variable {catalog : Raw.StrategyCatalog model} {closure : Raw.ClosureOperator model}

/-! ## Raw factorization consequences -/

/-- Candidate generation on a raw library, before verification/admission. -/
def rawCandidateLaw (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog)
    (project : model.ResearchProject) : RatProb (Raw.CandidateOutcome model) :=
  process.generation.distribution project belief
    (generativeClosure catalog closure library)

/-- One primitive verification/admission probability on a raw library. -/
def rawAdmissionProbability (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog)
    (project : model.ResearchProject) (strategy : model.StrategyId) : ℚ :=
  process.admission.probability project belief
    (generativeClosure catalog closure library) strategy

/-- The admitted-candidate law derived from generation and admission on a raw library. -/
noncomputable def rawAdmittedLaw (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog)
    (project : model.ResearchProject) : RatProb (Raw.CandidateOutcome model) :=
  process.admittedLaw belief
    (CompressedLibraryState.ofLibrary catalog closure library) project

/-- Raw candidate generation depends on a library only through its closure. -/
theorem rawCandidateLaw_eq_of_generativeClosure_eq
    (process : Model model catalog closure) (belief : model.Belief)
    (project : model.ResearchProject) {left right : Raw.Library catalog}
    (hclosure : generativeClosure catalog closure left =
      generativeClosure catalog closure right) :
    process.rawCandidateLaw belief left project =
      process.rawCandidateLaw belief right project := by
  unfold rawCandidateLaw
  rw [hclosure]

/-- Primitive admission depends on a library only through its closure. -/
theorem rawAdmissionProbability_eq_of_generativeClosure_eq
    (process : Model model catalog closure) (belief : model.Belief)
    (project : model.ResearchProject) (strategy : model.StrategyId)
    {left right : Raw.Library catalog}
    (hclosure : generativeClosure catalog closure left =
      generativeClosure catalog closure right) :
    process.rawAdmissionProbability belief left project strategy =
      process.rawAdmissionProbability belief right project strategy := by
  unfold rawAdmissionProbability
  rw [hclosure]

/-- The derived admitted law inherits closure factorization from the raw primitives. -/
theorem rawAdmittedLaw_eq_of_generativeClosure_eq
    (process : Model model catalog closure) (belief : model.Belief)
    (project : model.ResearchProject) {left right : Raw.Library catalog}
    (hclosure : generativeClosure catalog closure left =
      generativeClosure catalog closure right) :
    process.rawAdmittedLaw belief left project =
      process.rawAdmittedLaw belief right project := by
  unfold rawAdmittedLaw admittedLaw CompressedLibraryState.ofLibrary
  change
    Raw.admittedCandidateDistribution process.generation process.admission
        project belief (generativeClosure catalog closure left) =
      Raw.admittedCandidateDistribution process.generation process.admission
        project belief (generativeClosure catalog closure right)
  rw [hclosure]

/-- Equality of frontier and closure is equality of the raw compressed state. -/
theorem compressedLibraryState_eq_of_frontierClosure_eq
    {left right : Raw.Library catalog}
    (hfrontier : operationalFrontier catalog left =
      operationalFrontier catalog right)
    (hclosure : generativeClosure catalog closure left =
      generativeClosure catalog closure right) :
    compressedLibraryState catalog closure left =
      compressedLibraryState catalog closure right := by
  unfold compressedLibraryState
  rw [hfrontier, hclosure]

/--
T1 turns raw closure-factorized admission and the raw update identity into the
same next compressed-state law for equal frontier--closure pairs.
-/
theorem rawNextCompressedTransition_eq_of_frontierClosure_eq
    (process : Model model catalog closure) (belief : model.Belief)
    (project : model.ResearchProject) {left right : Raw.Library catalog}
    (hfrontier : operationalFrontier catalog left =
      operationalFrontier catalog right)
    (hclosure : generativeClosure catalog closure left =
      generativeClosure catalog closure right) :
    process.rawNextCompressedTransition belief left project =
      process.rawNextCompressedTransition belief right project := by
  have hstate := compressedLibraryState_eq_of_frontierClosure_eq
    (catalog := catalog) (closure := closure) hfrontier hclosure
  apply StrategyInnovation.RatProb.ext
  apply Finsupp.ext
  intro nextState
  exact process.same_compressedState_same_next_probability
    hstate belief project nextState

/-! ## Observable closure detectability -/

/--
An exact raw-process witness separating two realizable compressed states.

The candidate/admission constructors record both the latent primitive change
and the fact that it survives into the observable joint projected law.
-/
inductive RawClosureDetectionWitness
    (process : Model model catalog closure)
    (left right : CompressedLibraryState catalog closure) : Prop
  | projectCost (belief : model.Belief) (project : model.ResearchProject)
      (different :
        process.availableProjectData left project
            (process.researchCost belief left project) ≠
          process.availableProjectData right project
            (process.researchCost belief right project))
  | projectDuration (project : model.ResearchProject)
      (different :
        process.availableProjectData left project (process.duration project) ≠
          process.availableProjectData right project (process.duration project))
  | candidateLaw (belief : model.Belief) (project : model.ResearchProject)
      (rawDifferent :
        process.generation.distribution project belief left.state.closure ≠
          process.generation.distribution project belief right.state.closure)
      (projectedDifferent :
        process.availableProjectData left project
            (process.projectNextStateLaw belief left project) ≠
          process.availableProjectData right project
            (process.projectNextStateLaw belief right project))
  | admissionProbability (belief : model.Belief)
      (project : model.ResearchProject) (strategy : model.StrategyId)
      (rawDifferent :
        process.admission.probability project belief left.state.closure strategy ≠
          process.admission.probability project belief right.state.closure strategy)
      (projectedDifferent :
        process.availableProjectData left project
            (process.projectNextStateLaw belief left project) ≠
          process.availableProjectData right project
            (process.projectNextStateLaw belief right project))
  | compressedTransition (belief : model.Belief) (project : model.ResearchProject)
      (different :
        process.availableProjectData left project
            (process.projectNextStateLaw belief left project) ≠
          process.availableProjectData right project
            (process.projectNextStateLaw belief right project))

/--
Raw closure detectability on the finite realizable carrier.  At a common
frontier, distinct realizable closures must change a tagged project cost,
duration, or joint projected transition, possibly through a witnessed change
in the raw candidate or admission primitive.
-/
def RawClosureDetectable (process : Model model catalog closure) : Prop :=
  ∀ left right : CompressedLibraryState catalog closure,
    left.state.frontier = right.state.frontier →
      left.state.closure ≠ right.state.closure →
        RawClosureDetectionWitness process left right

/-! ## T2 characterization -/

/--
The complete forward raw factorization package.  Equal frontier--closure pairs
have the same pre-admission candidate laws, primitive admission probabilities,
T1-projected raw next-state laws, and final dynamic observations.
-/
theorem frontierClosure_eq_implies_rawLaws_and_dynamicEquivalence
    (process : Model model catalog closure) {left right : Raw.Library catalog}
    (hfrontier : operationalFrontier catalog left =
      operationalFrontier catalog right)
    (hclosure : generativeClosure catalog closure left =
      generativeClosure catalog closure right) :
    (∀ belief project,
        process.rawCandidateLaw belief left project =
          process.rawCandidateLaw belief right project) ∧
      (∀ belief project strategy,
        process.rawAdmissionProbability belief left project strategy =
          process.rawAdmissionProbability belief right project strategy) ∧
      (∀ belief project,
        process.rawNextCompressedTransition belief left project =
          process.rawNextCompressedTransition belief right project) ∧
      DynamicInnovationEquivalent process left right := by
  refine ⟨fun belief project =>
      process.rawCandidateLaw_eq_of_generativeClosure_eq belief project hclosure,
    fun belief project strategy =>
      process.rawAdmissionProbability_eq_of_generativeClosure_eq
        belief project strategy hclosure,
    fun belief project =>
      process.rawNextCompressedTransition_eq_of_frontierClosure_eq
        belief project hfrontier hclosure,
    ?_⟩
  exact process.compressedState_eq_implies_dynamicInnovationEquivalent
    (compressedLibraryState_eq_of_frontierClosure_eq
      (catalog := catalog) (closure := closure) hfrontier hclosure)

/--
Forward T2.  The accepted raw model's typed generator/admission inputs and T1
projection make equality of frontier and closure sufficient for final dynamic
innovation equivalence.
-/
theorem frontierClosure_eq_implies_dynamicInnovationEquivalent
    (process : Model model catalog closure) {left right : Raw.Library catalog}
    (hfrontier : operationalFrontier catalog left =
      operationalFrontier catalog right)
    (hclosure : generativeClosure catalog closure left =
      generativeClosure catalog closure right) :
    DynamicInnovationEquivalent process left right :=
  (process.frontierClosure_eq_implies_rawLaws_and_dynamicEquivalence
    hfrontier hclosure).2.2.2

/-- Converse T2 under observable raw closure detectability. -/
theorem dynamicInnovationEquivalent_implies_frontierClosure_eq
    (process : Model model catalog closure)
    (hdetectable : RawClosureDetectable process)
    {left right : Raw.Library catalog}
    (hequivalent : DynamicInnovationEquivalent process left right) :
    operationalFrontier catalog left = operationalFrontier catalog right ∧
      generativeClosure catalog closure left =
        generativeClosure catalog closure right := by
  have hfrontier : operationalFrontier catalog left =
      operationalFrontier catalog right :=
    funext hequivalent.frontier
  refine ⟨hfrontier, ?_⟩
  by_contra hclosure
  have hwitness := hdetectable
    (CompressedLibraryState.ofLibrary catalog closure left)
    (CompressedLibraryState.ofLibrary catalog closure right)
    hfrontier hclosure
  cases hwitness with
  | projectCost belief project different =>
      exact different (hequivalent.projectCost belief project)
  | projectDuration project different =>
      exact different (hequivalent.projectDuration project)
  | candidateLaw belief project _ projectedDifferent =>
      exact projectedDifferent (hequivalent.nextStateLaw belief project)
  | admissionProbability belief project strategy _ projectedDifferent =>
      exact projectedDifferent (hequivalent.nextStateLaw belief project)
  | compressedTransition belief project different =>
      exact different (hequivalent.nextStateLaw belief project)

/--
T2: final raw dynamic innovation equivalence is exactly equality of frontier
and closure under observable raw closure detectability.
-/
theorem dynamicInnovationEquivalent_iff_frontierClosure_eq
    (process : Model model catalog closure)
    (hdetectable : RawClosureDetectable process)
    {left right : Raw.Library catalog} :
    DynamicInnovationEquivalent process left right ↔
      operationalFrontier catalog left = operationalFrontier catalog right ∧
        generativeClosure catalog closure left =
          generativeClosure catalog closure right := by
  constructor
  · exact process.dynamicInnovationEquivalent_implies_frontierClosure_eq hdetectable
  · rintro ⟨hfrontier, hclosure⟩
    exact process.frontierClosure_eq_implies_dynamicInnovationEquivalent
      hfrontier hclosure

/--
Equivalent final criterion: under raw detectability, dynamic innovation
equivalence is exactly equality of the realizable compressed library state.
-/
theorem dynamicInnovationEquivalent_iff_compressedLibraryState_eq
    (process : Model model catalog closure)
    (hdetectable : RawClosureDetectable process)
    {left right : Raw.Library catalog} :
    DynamicInnovationEquivalent process left right ↔
      compressedLibraryState catalog closure left =
        compressedLibraryState catalog closure right := by
  constructor
  · intro hequivalent
    rcases process.dynamicInnovationEquivalent_implies_frontierClosure_eq
      hdetectable hequivalent with ⟨hfrontier, hclosure⟩
    exact compressedLibraryState_eq_of_frontierClosure_eq
      (catalog := catalog) (closure := closure) hfrontier hclosure
  · exact process.compressedState_eq_implies_dynamicInnovationEquivalent

/-! ## Exact finite counterexamples -/

namespace RawFrontierClosureCounterexamples

inductive Belief
  | only
  deriving DecidableEq, Fintype

instance : Nonempty Belief := ⟨Belief.only⟩

instance : Subsingleton Belief where
  allEq := by intro left right; cases left; cases right; rfl

inductive Strategy
  | inactive
  | hiddenId
  | moduleCarrier
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

/-- Exact finite carriers shared by both T2 boundary examples. -/
abbrev counterexampleModel : FiniteModel where
  Belief := Belief
  StrategyId := Strategy
  ModuleId := Module
  ResearchProject := Project

def profile : Strategy → Belief → ℚ := fun _ _ => 0

def modules : Strategy → Finset Module
  | .inactive => ∅
  | .hiddenId => ∅
  | .moduleCarrier => {Module.signal}

abbrev counterexampleCatalog : Raw.StrategyCatalog counterexampleModel where
  operationalProfile := profile
  strategyModules := modules
  inactiveStrategy := Strategy.inactive
  inactiveProfile := by intro belief; rfl
  inactiveModules := rfl

abbrev identityClosure : Raw.ClosureOperator counterexampleModel where
  close := id
  extensive := fun _ => Finset.Subset.refl _
  monotone := fun hinclude => hinclude
  idempotent := fun _ => rfl

def inactiveLibrary : Raw.Library counterexampleCatalog where
  strategies := {Strategy.inactive}
  inactive_mem := by simp

def hiddenIdentifierLibrary : Raw.Library counterexampleCatalog where
  strategies := {Strategy.inactive, Strategy.hiddenId}
  inactive_mem := by simp

def moduleLibrary : Raw.Library counterexampleCatalog where
  strategies := {Strategy.inactive, Strategy.moduleCarrier}
  inactive_mem := by simp

theorem inactive_hidden_frontiers_eq :
    operationalFrontier counterexampleCatalog inactiveLibrary =
      operationalFrontier counterexampleCatalog hiddenIdentifierLibrary := by
  funext belief
  apply le_antisymm
  · exact operationalFrontier_mono counterexampleCatalog
      (by intro strategy hstrategy; simp_all [inactiveLibrary,
        hiddenIdentifierLibrary]) belief
  · apply (operationalFrontier_le_iff counterexampleCatalog
      hiddenIdentifierLibrary belief _).2
    intro strategy hstrategy
    change strategy ∈ ({Strategy.inactive, Strategy.hiddenId} : Finset Strategy)
      at hstrategy
    simp only [Finset.mem_insert, Finset.mem_singleton] at hstrategy
    rcases hstrategy with rfl | rfl
    · exact operationalProfile_le_frontier counterexampleCatalog inactiveLibrary
        inactiveLibrary.inactive_mem belief
    · change 0 ≤ operationalFrontier counterexampleCatalog inactiveLibrary belief
      exact zero_le_operationalFrontier counterexampleCatalog inactiveLibrary belief

theorem inactive_hidden_closures_eq :
    generativeClosure counterexampleCatalog identityClosure inactiveLibrary =
      generativeClosure counterexampleCatalog identityClosure
        hiddenIdentifierLibrary := by
  simp [generativeClosure, rawModuleUnion, inactiveLibrary,
    hiddenIdentifierLibrary, counterexampleCatalog, modules]

/-- A broader raw generator that is allowed to inspect raw library identifiers. -/
structure LibraryIndexedGenerator where
  distribution : counterexampleModel.ResearchProject →
    counterexampleModel.Belief → Raw.Library counterexampleCatalog →
      RatProb (Raw.CandidateOutcome counterexampleModel)

/-- Equality of the library-indexed generator observations. -/
def LibraryIndexedGeneratorEquivalent (generator : LibraryIndexedGenerator)
    (left right : Raw.Library counterexampleCatalog) : Prop :=
  ∀ project belief, generator.distribution project belief left =
    generator.distribution project belief right

/-- Factorization condition excluded by the accepted raw model's input types. -/
def LibraryIndexedGeneratorFactorsThroughFrontierClosure
    (generator : LibraryIndexedGenerator) : Prop :=
  ∀ project belief (left right : Raw.Library counterexampleCatalog),
    operationalFrontier counterexampleCatalog left =
        operationalFrontier counterexampleCatalog right →
      generativeClosure counterexampleCatalog identityClosure left =
          generativeClosure counterexampleCatalog identityClosure right →
        generator.distribution project belief left =
          generator.distribution project belief right

/--
Exact generator whose candidate law reads membership of a hidden raw
identifier.  When the identifier is present it produces the distinct
module-bearing strategy, so the violation survives compression.
-/
noncomputable def rawIdentifierGenerator : LibraryIndexedGenerator where
  distribution := fun _ _ library =>
    if Strategy.hiddenId ∈ library.strategies then
      RatProb.dirac (some Strategy.moduleCarrier)
    else RatProb.dirac none

/--
Next compressed-state law for the broader generator when every generated
candidate is admitted (primitive admission probability one).
-/
noncomputable def libraryIndexedNextCompressedLaw
    (generator : LibraryIndexedGenerator)
    (library : Raw.Library counterexampleCatalog)
    (project : counterexampleModel.ResearchProject)
    (belief : counterexampleModel.Belief) :
    RatProb (CompressedLibraryState counterexampleCatalog identityClosure) :=
  Projection.RatProb.map (generator.distribution project belief library)
    (fun outcome => CompressedLibraryState.ofLibrary
      counterexampleCatalog identityClosure
      (Raw.rawLibraryUpdate library outcome))

/--
Exact counterexample: equal frontier and closure do not suffice when candidate
generation is allowed to inspect raw identifiers.
-/
theorem sufficiency_fails_when_generator_uses_raw_identifiers :
    operationalFrontier counterexampleCatalog inactiveLibrary =
        operationalFrontier counterexampleCatalog hiddenIdentifierLibrary ∧
      generativeClosure counterexampleCatalog identityClosure inactiveLibrary =
        generativeClosure counterexampleCatalog identityClosure
          hiddenIdentifierLibrary ∧
      ¬ LibraryIndexedGeneratorEquivalent rawIdentifierGenerator
          inactiveLibrary hiddenIdentifierLibrary ∧
      libraryIndexedNextCompressedLaw rawIdentifierGenerator inactiveLibrary
          Project.probe Belief.only ≠
        libraryIndexedNextCompressedLaw rawIdentifierGenerator
          hiddenIdentifierLibrary Project.probe Belief.only := by
  refine ⟨inactive_hidden_frontiers_eq, inactive_hidden_closures_eq, ?_, ?_⟩
  · intro hequivalent
    have hlaw := hequivalent Project.probe Belief.only
    have hnone := congrArg (fun law => law.probability none) hlaw
    simp [rawIdentifierGenerator, inactiveLibrary, hiddenIdentifierLibrary,
      RatProb.probability, RatProb.dirac] at hnone
  · intro hlaw
    have hleft := congrArg
      (fun law => law.probability
        (CompressedLibraryState.ofLibrary counterexampleCatalog identityClosure
          inactiveLibrary)) hlaw
    simp [libraryIndexedNextCompressedLaw, rawIdentifierGenerator,
      Projection.RatProb.map, RatProb.probability, RatProb.dirac,
      inactiveLibrary, hiddenIdentifierLibrary, Raw.rawLibraryUpdate,
      CompressedLibraryState.ofLibrary, compressedLibraryState,
      generativeClosure, rawModuleUnion, counterexampleCatalog, modules,
      identityClosure] at hleft

theorem rawIdentifierGenerator_not_factorized :
    ¬ LibraryIndexedGeneratorFactorsThroughFrontierClosure
      rawIdentifierGenerator := by
  intro hfactor
  have hlaw := hfactor Project.probe Belief.only inactiveLibrary
    hiddenIdentifierLibrary inactive_hidden_frontiers_eq inactive_hidden_closures_eq
  have hnone := congrArg (fun law => law.probability none) hlaw
  simp [rawIdentifierGenerator, inactiveLibrary, hiddenIdentifierLibrary,
    RatProb.probability, RatProb.dirac] at hnone

noncomputable def constantGeneration :
    Raw.CandidateGenerationDistributions counterexampleModel where
  distribution := fun _ _ _ => RatProb.dirac none

def zeroAdmission : Raw.AdmissionProbabilities counterexampleModel where
  probability := fun _ _ _ _ => 0
  nonnegative := by intros; norm_num
  le_one := by intros; norm_num

noncomputable def constantBeliefTransition
    (_ : counterexampleModel.Belief) : RatProb counterexampleModel.Belief :=
  RatProb.dirac Belief.only

def onlyPath : BeliefPath counterexampleModel 1 := fun _ => Belief.only

/--
A raw process in which every research project is unavailable.  Its completion
coupling is still exact and has the required raw generation/admission marginals.
-/
noncomputable def silentProcess :
    Model counterexampleModel counterexampleCatalog identityClosure where
  generation := constantGeneration
  admission := zeroAdmission
  beliefTransition := constantBeliefTransition
  duration := fun _ => 1
  duration_positive := by intros; norm_num
  operates := fun _ => false
  available := fun _ => ∅
  researchCost := fun _ _ _ => 0
  researchCost_nonnegative := by intros; norm_num
  discount := 0
  discount_nonnegative := by norm_num
  discount_lt_one := by norm_num
  completion := fun _ _ _ => RatProb.dirac (onlyPath, none)
  completion_path_marginal := by
    intro project belief state path
    have hpath : path = onlyPath := Subsingleton.elim _ _
    subst path
    simp [RatProb.probability, RatProb.dirac, markovPathMass,
      constantBeliefTransition]
  completion_outcome_marginal := by
    intro project belief state outcome
    cases outcome with
    | none =>
        rw [Raw.admittedCandidateDistribution_probability]
        change
          (∑ path : BeliefPath counterexampleModel 1,
            (Finsupp.single (onlyPath, none) 1) (path, none)) = _
        rw [Finset.sum_eq_single onlyPath]
        · simp [Raw.admittedCandidateMass, constantGeneration, zeroAdmission,
            Raw.CandidateGenerationDistributions.probability,
            RatProb.probability, RatProb.dirac]
        · intro path _ hpath
          simp [hpath]
        · simp
    | some strategy =>
        rw [Raw.admittedCandidateDistribution_probability]
        simp [RatProb.probability, RatProb.dirac,
          Raw.admittedCandidateMass, constantGeneration, zeroAdmission,
          Raw.CandidateGenerationDistributions.probability]

theorem inactive_module_frontiers_eq :
    operationalFrontier counterexampleCatalog inactiveLibrary =
      operationalFrontier counterexampleCatalog moduleLibrary := by
  funext belief
  apply le_antisymm
  · exact operationalFrontier_mono counterexampleCatalog
      (by intro strategy hstrategy; simp_all [inactiveLibrary, moduleLibrary]) belief
  · apply (operationalFrontier_le_iff counterexampleCatalog
      moduleLibrary belief _).2
    intro strategy hstrategy
    change strategy ∈ ({Strategy.inactive, Strategy.moduleCarrier} : Finset Strategy)
      at hstrategy
    simp only [Finset.mem_insert, Finset.mem_singleton] at hstrategy
    rcases hstrategy with rfl | rfl
    · exact operationalProfile_le_frontier counterexampleCatalog inactiveLibrary
        inactiveLibrary.inactive_mem belief
    · change 0 ≤ operationalFrontier counterexampleCatalog inactiveLibrary belief
      exact zero_le_operationalFrontier counterexampleCatalog inactiveLibrary belief

theorem inactive_module_closures_ne :
    generativeClosure counterexampleCatalog identityClosure inactiveLibrary ≠
      generativeClosure counterexampleCatalog identityClosure moduleLibrary := by
  simp [generativeClosure, rawModuleUnion, inactiveLibrary, moduleLibrary,
    counterexampleCatalog, modules]

/-- Exact counterexample: a behaviorally invisible closure defeats the converse. -/
theorem converse_fails_when_closure_behaviorally_invisible :
    DynamicInnovationEquivalent silentProcess inactiveLibrary moduleLibrary ∧
      generativeClosure counterexampleCatalog identityClosure inactiveLibrary ≠
        generativeClosure counterexampleCatalog identityClosure moduleLibrary := by
  refine ⟨?_, inactive_module_closures_ne⟩
  constructor
  · exact fun belief => congrFun inactive_module_frontiers_eq belief
  · intro belief project
    simp [availableProjectData, silentProcess]
  · intro project
    simp [availableProjectData, silentProcess]
  · intro belief project
    simp [availableProjectData, silentProcess]
  · intro belief project
    simp [availableProjectData, silentProcess]

theorem silentProcess_not_rawClosureDetectable :
    ¬ RawClosureDetectable silentProcess := by
  intro hdetectable
  have hwitness := hdetectable
    (CompressedLibraryState.ofLibrary counterexampleCatalog identityClosure
      inactiveLibrary)
    (CompressedLibraryState.ofLibrary counterexampleCatalog identityClosure
      moduleLibrary)
    inactive_module_frontiers_eq inactive_module_closures_ne
  cases hwitness with
  | projectCost belief project different =>
      exact different (by simp [availableProjectData, silentProcess])
  | projectDuration project different =>
      exact different (by simp [availableProjectData, silentProcess])
  | candidateLaw belief project rawDifferent projectedDifferent =>
      exact rawDifferent (by rfl)
  | admissionProbability belief project strategy rawDifferent projectedDifferent =>
      exact rawDifferent (by rfl)
  | compressedTransition belief project different =>
      exact different (by simp [availableProjectData, silentProcess])

end RawFrontierClosureCounterexamples

end Model

end Projection

end StrategyInnovation
