import Mathlib.Tactic.DeriveFintype
import StrategyInnovation.Quotient.DynamicInnovation

/-!
# Frontier--closure characterization

This file makes the modular-generator assumption explicit.  A declared
generator receives the current belief, operational frontier, generative
closure, and project.  A research semantics factors through the generator when
its compressed-state transition agrees with that four-argument kernel.

The current-reward component of dynamic innovation equivalence observes the
frontier pointwise, so frontier equality needs no additional identifiability
hypothesis.  The converse for closures requires a genuine separation
condition: at any fixed frontier, distinct realizable closures must change the
transition law for some belief and project.
-/

namespace StrategyInnovation

/--
A modular generator whose exact next-state law can inspect only the current
belief, operational frontier, generative closure, and research project.
-/
structure ModularGenerator (model : FiniteModel) where
  candidateTransition :
    model.Belief → (model.Belief → ℚ) → Finset model.ModuleId →
      model.ResearchProject → RatProb (InnovationState model)

/--
The research-transition semantics factors through a declared modular
generator.  This is the explicit generator-factorization assumption.
-/
def GeneratorFactorsThroughFrontierClosure {model : FiniteModel}
    (semantics : FiniteResearchSemantics model)
    (generator : ModularGenerator model) : Prop :=
  ∀ belief state project,
    semantics.researchTransition belief state project =
      generator.candidateTransition belief state.frontier state.closure project

/--
Two libraries have the same generator transition signature, without including
their current operational rewards.
-/
def GeneratorTransitionEquivalent {model : FiniteModel}
    (generator : ModularGenerator model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (left right : Library model catalog.inactiveStrategy) : Prop :=
  ∀ belief project,
    generator.candidateTransition belief
        (operationalFrontier catalog left)
        (generativeClosure catalog moduleClosure left) project =
      generator.candidateTransition belief
        (operationalFrontier catalog right)
        (generativeClosure catalog moduleClosure right) project

/-- A frontier--closure pair is realizable when some admissible library has it. -/
def RealizableFrontierClosure {model : FiniteModel}
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (frontier : model.Belief → ℚ) (closure : Finset model.ModuleId) : Prop :=
  ∃ library : Library model catalog.inactiveStrategy,
    operationalFrontier catalog library = frontier ∧
      generativeClosure catalog moduleClosure library = closure

/--
Closure identifiability on realizable pairs: at a fixed frontier, every pair
of distinct realizable closures is separated by the transition law of some
belief--project experiment.
-/
def ClosureIdentifiable {model : FiniteModel}
    (generator : ModularGenerator model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model) :
    Prop :=
  ∀ frontier {leftClosure rightClosure : Finset model.ModuleId},
    RealizableFrontierClosure catalog moduleClosure frontier leftClosure →
      RealizableFrontierClosure catalog moduleClosure frontier rightClosure →
        leftClosure ≠ rightClosure →
          ∃ belief project,
            generator.candidateTransition belief frontier leftClosure project ≠
              generator.candidateTransition
                belief frontier rightClosure project

/--
The current reward observation is frontier evaluation and therefore detects
the entire frontier without an extra assumption.
-/
theorem currentReward_detects_frontier {model : FiniteModel}
    {leftFrontier rightFrontier : model.Belief → ℚ}
    (hreward : ∀ belief, leftFrontier belief = rightFrontier belief) :
    leftFrontier = rightFrontier :=
  funext hreward

/-- Operational equivalence detects equality of the complete frontier. -/
theorem frontier_eq_of_operationallyEquivalent {model : FiniteModel}
    (catalog : StrategyCatalog model)
    {left right : Library model catalog.inactiveStrategy}
    (hequivalent : OperationallyEquivalent catalog left right) :
    operationalFrontier catalog left =
      operationalFrontier catalog right :=
  currentReward_detects_frontier hequivalent

/--
On a raw library, the factorization assumption exposes exactly the frontier
and closure arguments supplied to the modular generator.
-/
theorem researchTransition_eq_modularGenerator_on_library
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (generator : ModularGenerator model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (hfactor :
      GeneratorFactorsThroughFrontierClosure semantics generator)
    (belief : model.Belief) (project : model.ResearchProject)
    (library : Library model catalog.inactiveStrategy) :
    semantics.researchTransition belief
        (compressedLibraryState catalog moduleClosure library) project =
      generator.candidateTransition belief
        (operationalFrontier catalog library)
        (generativeClosure catalog moduleClosure library) project := by
  simpa [compressedLibraryState] using
    hfactor belief (compressedLibraryState catalog moduleClosure library) project

/--
Forward direction: equal operational frontiers and equal generative closures
imply dynamic innovation equivalence for a factorized generator.
-/
theorem frontierClosure_eq_implies_dynamicInnovationEquivalent
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (generator : ModularGenerator model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (hfactor :
      GeneratorFactorsThroughFrontierClosure semantics generator)
    {left right : Library model catalog.inactiveStrategy}
    (hfrontier :
      operationalFrontier catalog left =
        operationalFrontier catalog right)
    (hclosure :
      generativeClosure catalog moduleClosure left =
        generativeClosure catalog moduleClosure right) :
    DynamicInnovationEquivalent semantics catalog moduleClosure left right := by
  constructor
  · intro belief
    exact congrFun hfrontier belief
  · intro belief project
    rw [researchTransition_eq_modularGenerator_on_library
      semantics generator catalog moduleClosure hfactor]
    rw [researchTransition_eq_modularGenerator_on_library
      semantics generator catalog moduleClosure hfactor]
    rw [hfrontier, hclosure]

/--
Converse direction under closure identifiability: dynamic innovation
equivalence recovers both the frontier and the generative closure.
-/
theorem dynamicInnovationEquivalent_implies_frontierClosure_eq
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (generator : ModularGenerator model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (hfactor :
      GeneratorFactorsThroughFrontierClosure semantics generator)
    (hidentifiable :
      ClosureIdentifiable generator catalog moduleClosure)
    {left right : Library model catalog.inactiveStrategy}
    (hequivalent :
      DynamicInnovationEquivalent semantics catalog moduleClosure left right) :
    operationalFrontier catalog left =
        operationalFrontier catalog right ∧
      generativeClosure catalog moduleClosure left =
        generativeClosure catalog moduleClosure right := by
  have hfrontier :
      operationalFrontier catalog left =
        operationalFrontier catalog right :=
    frontier_eq_of_operationallyEquivalent catalog hequivalent.1
  refine ⟨hfrontier, ?_⟩
  by_contra hclosure
  have hleftRealizable :
      RealizableFrontierClosure catalog moduleClosure
        (operationalFrontier catalog left)
        (generativeClosure catalog moduleClosure left) :=
    ⟨left, rfl, rfl⟩
  have hrightRealizable :
      RealizableFrontierClosure catalog moduleClosure
        (operationalFrontier catalog left)
        (generativeClosure catalog moduleClosure right) :=
    ⟨right, hfrontier.symm, rfl⟩
  obtain ⟨belief, project, hseparates⟩ :=
    hidentifiable (operationalFrontier catalog left)
      hleftRealizable hrightRealizable hclosure
  apply hseparates
  calc
    generator.candidateTransition belief
          (operationalFrontier catalog left)
          (generativeClosure catalog moduleClosure left) project =
        semantics.researchTransition belief
          (compressedLibraryState catalog moduleClosure left) project :=
      (researchTransition_eq_modularGenerator_on_library
        semantics generator catalog moduleClosure hfactor
        belief project left).symm
    _ = semantics.researchTransition belief
          (compressedLibraryState catalog moduleClosure right) project :=
      hequivalent.2 belief project
    _ = generator.candidateTransition belief
          (operationalFrontier catalog right)
          (generativeClosure catalog moduleClosure right) project :=
      researchTransition_eq_modularGenerator_on_library
        semantics generator catalog moduleClosure hfactor
        belief project right
    _ = generator.candidateTransition belief
          (operationalFrontier catalog left)
          (generativeClosure catalog moduleClosure right) project := by
      rw [hfrontier]

/--
Frontier--closure characterization.  The iff requires both generator
factorization and closure identifiability; neither is hidden in the statement.
-/
theorem dynamicInnovationEquivalent_iff_frontierClosure_eq
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (generator : ModularGenerator model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (hfactor :
      GeneratorFactorsThroughFrontierClosure semantics generator)
    (hidentifiable :
      ClosureIdentifiable generator catalog moduleClosure)
    {left right : Library model catalog.inactiveStrategy} :
    DynamicInnovationEquivalent semantics catalog moduleClosure left right ↔
      operationalFrontier catalog left =
          operationalFrontier catalog right ∧
        generativeClosure catalog moduleClosure left =
          generativeClosure catalog moduleClosure right := by
  constructor
  · exact dynamicInnovationEquivalent_implies_frontierClosure_eq
      semantics generator catalog moduleClosure hfactor hidentifiable
  · rintro ⟨hfrontier, hclosure⟩
    exact frontierClosure_eq_implies_dynamicInnovationEquivalent
      semantics generator catalog moduleClosure hfactor hfrontier hclosure

/--
Equivalent formulation: under the exact assumptions, DI equivalence is
equality of the compressed frontier--closure state.
-/
theorem dynamicInnovationEquivalent_iff_compressedLibraryState_eq
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (generator : ModularGenerator model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (hfactor :
      GeneratorFactorsThroughFrontierClosure semantics generator)
    (hidentifiable :
      ClosureIdentifiable generator catalog moduleClosure)
    {left right : Library model catalog.inactiveStrategy} :
    DynamicInnovationEquivalent semantics catalog moduleClosure left right ↔
      compressedLibraryState catalog moduleClosure left =
        compressedLibraryState catalog moduleClosure right := by
  constructor
  · intro hequivalent
    rcases
        dynamicInnovationEquivalent_implies_frontierClosure_eq
          semantics generator catalog moduleClosure hfactor hidentifiable
          hequivalent with
      ⟨hfrontier, hclosure⟩
    unfold compressedLibraryState
    rw [hfrontier, hclosure]
  · intro hstate
    exact frontierClosure_eq_implies_dynamicInnovationEquivalent
      semantics generator catalog moduleClosure hfactor
      (operationalFrontier_eq_of_compressedLibraryState_eq
        catalog moduleClosure hstate)
      (generativeClosure_eq_of_compressedLibraryState_eq
        catalog moduleClosure hstate)

/--
Sufficiency of `(frontier, closure)`: equal component pairs imply equal
finite-horizon values at every belief, without using identifiability.
-/
theorem frontierClosure_eq_preserves_finiteHorizonValue
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (generator : ModularGenerator model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (hfactor :
      GeneratorFactorsThroughFrontierClosure semantics generator)
    {left right : Library model catalog.inactiveStrategy}
    (hfrontier :
      operationalFrontier catalog left =
        operationalFrontier catalog right)
    (hclosure :
      generativeClosure catalog moduleClosure left =
        generativeClosure catalog moduleClosure right) :
    ∀ horizon belief,
      dynamicLibraryValue semantics catalog moduleClosure horizon belief left =
        dynamicLibraryValue semantics catalog moduleClosure horizon belief right :=
  finiteHorizonValue_eq_of_dynamicInnovationEquivalent
    semantics catalog moduleClosure
      (frontierClosure_eq_implies_dynamicInnovationEquivalent
        semantics generator catalog moduleClosure hfactor hfrontier hclosure)

/-! ## Exact finite counterexamples -/

namespace FrontierClosureCounterexamples

inductive Belief
  | only
  deriving DecidableEq, Fintype

instance : Nonempty Belief :=
  ⟨Belief.only⟩

inductive Strategy
  | inactive
  | productive
  | bridge
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

/-- One-belief counterexample carrier with three strategies and one module. -/
abbrev model : FiniteModel where
  Belief := Belief
  StrategyId := Strategy
  ModuleId := Module
  ResearchProject := Project

def profile : Strategy → Belief → ℚ
  | .inactive, _ => 0
  | .productive, _ => 1
  | .bridge, _ => 0

def modules : Strategy → Finset Module
  | .inactive => ∅
  | .productive => {Module.signal}
  | .bridge => {Module.signal}

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

def inactiveLibrary : Library model catalog.inactiveStrategy where
  strategies := {Strategy.inactive}
  inactive_mem := by simp

def productiveLibrary : Library model catalog.inactiveStrategy where
  strategies := {Strategy.inactive, Strategy.productive}
  inactive_mem := by simp

def bridgeLibrary : Library model catalog.inactiveStrategy where
  strategies := {Strategy.inactive, Strategy.bridge}
  inactive_mem := by simp

noncomputable def constantGenerator : ModularGenerator model where
  candidateTransition := fun _ _ _ _ =>
    RatProb.dirac
      (compressedLibraryState catalog moduleClosure inactiveLibrary)

noncomputable def constantSemantics : FiniteResearchSemantics model where
  beliefKernel := fun _ => RatProb.dirac Belief.only
  researchTransition := fun _ _ _ =>
    RatProb.dirac
      (compressedLibraryState catalog moduleClosure inactiveLibrary)
  discount := 0
  discount_nonnegative := by norm_num
  discount_lt_one := by norm_num

theorem constantSemantics_factors :
    GeneratorFactorsThroughFrontierClosure
      constantSemantics constantGenerator := by
  intro belief state project
  rfl

theorem productive_bridge_frontiers_ne :
    operationalFrontier catalog productiveLibrary ≠
      operationalFrontier catalog bridgeLibrary := by
  intro hfrontier
  have hproductive :
      (1 : ℚ) ≤
        operationalFrontier catalog productiveLibrary Belief.only := by
    have hmember : Strategy.productive ∈ productiveLibrary := by
      change Strategy.productive ∈
        ({Strategy.inactive, Strategy.productive} : Finset Strategy)
      simp
    exact operationalProfile_le_frontier
      catalog productiveLibrary hmember Belief.only
  have hbridge :
      operationalFrontier catalog bridgeLibrary Belief.only ≤ 0 := by
    apply (operationalFrontier_le_iff
      catalog bridgeLibrary Belief.only 0).2
    intro strategy hstrategy
    change strategy ∈
      ({Strategy.inactive, Strategy.bridge} : Finset Strategy) at hstrategy
    simp only [Finset.mem_insert, Finset.mem_singleton] at hstrategy
    rcases hstrategy with rfl | rfl <;> rfl
  rw [hfrontier] at hproductive
  have himpossible : (1 : ℚ) ≤ 0 :=
    hproductive.trans hbridge
  norm_num at himpossible

theorem inactive_bridge_frontiers_eq :
    operationalFrontier catalog inactiveLibrary =
      operationalFrontier catalog bridgeLibrary := by
  funext belief
  apply le_antisymm
  · apply (operationalFrontier_le_iff
      catalog inactiveLibrary belief _).2
    intro strategy hstrategy
    change strategy ∈ ({Strategy.inactive} : Finset Strategy) at hstrategy
    simp only [Finset.mem_singleton] at hstrategy
    subst strategy
    change 0 ≤ operationalFrontier catalog bridgeLibrary belief
    exact zero_le_operationalFrontier catalog bridgeLibrary belief
  · apply (operationalFrontier_le_iff
      catalog bridgeLibrary belief _).2
    intro strategy hstrategy
    change strategy ∈
      ({Strategy.inactive, Strategy.bridge} : Finset Strategy) at hstrategy
    simp only [Finset.mem_insert, Finset.mem_singleton] at hstrategy
    rcases hstrategy with rfl | rfl
    · change 0 ≤ operationalFrontier catalog inactiveLibrary belief
      exact zero_le_operationalFrontier catalog inactiveLibrary belief
    · change 0 ≤ operationalFrontier catalog inactiveLibrary belief
      exact zero_le_operationalFrontier catalog inactiveLibrary belief

theorem inactive_bridge_closures_ne :
    generativeClosure catalog moduleClosure inactiveLibrary ≠
      generativeClosure catalog moduleClosure bridgeLibrary := by
  simp [generativeClosure, rawModuleUnion, inactiveLibrary,
    bridgeLibrary, catalog, modules]

/--
Without current-reward/frontier observation, transition signatures alone can
identify libraries with different frontiers.
-/
theorem frontier_converse_fails_without_currentReward :
    GeneratorTransitionEquivalent constantGenerator catalog moduleClosure
        productiveLibrary bridgeLibrary ∧
      operationalFrontier catalog productiveLibrary ≠
        operationalFrontier catalog bridgeLibrary := by
  refine ⟨?_, productive_bridge_frontiers_ne⟩
  intro belief project
  rfl

/--
Without closure identifiability, full dynamic innovation equivalence can hold
for libraries with different frontier--closure states.
-/
theorem closure_converse_fails_without_identifiability :
    DynamicInnovationEquivalent constantSemantics catalog moduleClosure
        inactiveLibrary bridgeLibrary ∧
      compressedLibraryState catalog moduleClosure inactiveLibrary ≠
        compressedLibraryState catalog moduleClosure bridgeLibrary := by
  constructor
  · constructor
    · intro belief
      exact congrFun inactive_bridge_frontiers_eq belief
    · intro belief project
      rfl
  · intro hstate
    apply inactive_bridge_closures_ne
    exact congrArg InnovationState.closure hstate

/-- The constant generator fails the closure-identifiability condition. -/
theorem constantGenerator_not_closureIdentifiable :
    ¬ ClosureIdentifiable constantGenerator catalog moduleClosure := by
  intro hidentifiable
  obtain ⟨belief, project, hseparates⟩ :=
    hidentifiable
      (operationalFrontier catalog inactiveLibrary)
      ⟨inactiveLibrary, rfl, rfl⟩
      ⟨bridgeLibrary, inactive_bridge_frontiers_eq.symm, rfl⟩
      inactive_bridge_closures_ne
  exact hseparates rfl

end FrontierClosureCounterexamples

end StrategyInnovation
