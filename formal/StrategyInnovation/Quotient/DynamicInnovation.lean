import Mathlib.Data.Setoid.Basic
import Mathlib.Data.Fintype.EquivFin
import StrategyInnovation.Basic.Probability
import StrategyInnovation.Library.InnovationState

/-!
# Legacy primitive dynamic innovation equivalence

This deprecated supporting file studies an abstract cost-free transition
semantics on compressed library states. It proves that equality of current
frontiers and primitive research-transition laws is an equivalence relation,
constructs its quotient, and shows that its abstract finite-horizon recursion
factors through that quotient.

It is not the publication-facing definition. The canonical cost-sensitive raw
relation is `Projection.Model.DynamicInnovationEquivalent` in
`Quotient/UnifiedDynamicInnovation.lean`; `Quotient/MIGRATION.md` records the
name-by-name migration. The declarations here remain compiled because F1--F4
use them as an explicitly legacy primitive supporting layer.
-/

namespace StrategyInnovation

/--
Exact finite research-transition semantics on compressed states.

The belief kernel and research kernel are conditionally independent in the
finite-horizon recursion below.  The rational discount bounds match the finite
model, although only exact equality is needed for preservation.
-/
structure FiniteResearchSemantics (model : FiniteModel) where
  beliefKernel : model.Belief → RatProb model.Belief
  researchTransition :
    model.Belief → InnovationState model → model.ResearchProject →
      RatProb (InnovationState model)
  discount : ℚ
  discount_nonnegative : 0 ≤ discount
  discount_lt_one : discount < 1

/-- The maximum of a rational project-value table on the nonempty finite menu. -/
def finiteProjectMaximum {model : FiniteModel}
    (value : model.ResearchProject → ℚ) : ℚ :=
  Finset.univ.sup' Finset.univ_nonempty value

/-- Pointwise-equal project-value tables have the same finite maximum. -/
theorem finiteProjectMaximum_congr {model : FiniteModel}
    {left right : model.ResearchProject → ℚ}
    (hvalue : ∀ project, left project = right project) :
    finiteProjectMaximum left = finiteProjectMaximum right := by
  have hfunction : left = right := funext hvalue
  cases hfunction
  rfl

/--
Finite-horizon value on a compressed innovation state.

At a positive horizon the planner receives the current frontier, then chooses
between idle and one project.  Idle retains the compressed state; a project
uses the exact research kernel.  In both cases the next belief follows the
library-independent belief kernel.
-/
def compressedFiniteHorizonValue {model : FiniteModel}
    (semantics : FiniteResearchSemantics model) :
    Nat → model.Belief → InnovationState model → ℚ
  | 0, _, _ => 0
  | horizon + 1, belief, state =>
      let idleContinuation :=
        (semantics.beliefKernel belief).expectation fun nextBelief =>
          compressedFiniteHorizonValue semantics horizon nextBelief state
      let projectContinuation :=
        finiteProjectMaximum fun project =>
          (semantics.beliefKernel belief).expectation fun nextBelief =>
            (semantics.researchTransition belief state project).expectation
              fun nextState =>
                compressedFiniteHorizonValue semantics horizon nextBelief nextState
      state.frontier belief +
        semantics.discount * max idleContinuation projectContinuation

/-- Evaluate the abstract finite-horizon recursion at a raw library's state. -/
def dynamicLibraryValue {model : FiniteModel}
    (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (horizon : Nat) (belief : model.Belief)
    (library : Library model catalog.inactiveStrategy) : ℚ :=
  compressedFiniteHorizonValue semantics horizon belief
    (compressedLibraryState catalog moduleClosure library)

/-- Two libraries are operationally equivalent when all frontier values agree. -/
def OperationallyEquivalent {model : FiniteModel}
    (catalog : StrategyCatalog model)
    (left right : Library model catalog.inactiveStrategy) : Prop :=
  ∀ belief,
    operationalFrontier catalog left belief =
      operationalFrontier catalog right belief

/--
Deprecated primitive equivalence: equal current frontiers and cost-free
primitive research-transition distributions. Use
`Projection.Model.DynamicInnovationEquivalent` for the unified raw model.
-/
def DynamicInnovationEquivalent {model : FiniteModel}
    (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (left right : Library model catalog.inactiveStrategy) : Prop :=
  OperationallyEquivalent catalog left right ∧
    ∀ belief project,
      semantics.researchTransition belief
          (compressedLibraryState catalog moduleClosure left) project =
        semantics.researchTransition belief
          (compressedLibraryState catalog moduleClosure right) project

/-- Operational equivalence is reflexive. -/
theorem operationallyEquivalent_refl {model : FiniteModel}
    (catalog : StrategyCatalog model)
    (library : Library model catalog.inactiveStrategy) :
    OperationallyEquivalent catalog library library := by
  intro belief
  rfl

/-- Operational equivalence is symmetric. -/
theorem operationallyEquivalent_symm {model : FiniteModel}
    (catalog : StrategyCatalog model)
    {left right : Library model catalog.inactiveStrategy}
    (hequivalent : OperationallyEquivalent catalog left right) :
    OperationallyEquivalent catalog right left := by
  intro belief
  exact (hequivalent belief).symm

/-- Operational equivalence is transitive. -/
theorem operationallyEquivalent_trans {model : FiniteModel}
    (catalog : StrategyCatalog model)
    {first second third : Library model catalog.inactiveStrategy}
    (hfirst : OperationallyEquivalent catalog first second)
    (hsecond : OperationallyEquivalent catalog second third) :
    OperationallyEquivalent catalog first third := by
  intro belief
  exact (hfirst belief).trans (hsecond belief)

/-- Dynamic innovation equivalence is reflexive. -/
theorem dynamicInnovationEquivalent_refl {model : FiniteModel}
    (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (library : Library model catalog.inactiveStrategy) :
    DynamicInnovationEquivalent semantics catalog moduleClosure library library := by
  constructor
  · exact operationallyEquivalent_refl catalog library
  · intro belief project
    rfl

/-- Dynamic innovation equivalence is symmetric. -/
theorem dynamicInnovationEquivalent_symm {model : FiniteModel}
    (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    {left right : Library model catalog.inactiveStrategy}
    (hequivalent :
      DynamicInnovationEquivalent semantics catalog moduleClosure left right) :
    DynamicInnovationEquivalent semantics catalog moduleClosure right left := by
  constructor
  · exact operationallyEquivalent_symm catalog hequivalent.1
  · intro belief project
    exact (hequivalent.2 belief project).symm

/-- Dynamic innovation equivalence is transitive. -/
theorem dynamicInnovationEquivalent_trans {model : FiniteModel}
    (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    {first second third : Library model catalog.inactiveStrategy}
    (hfirst :
      DynamicInnovationEquivalent semantics catalog moduleClosure first second)
    (hsecond :
      DynamicInnovationEquivalent semantics catalog moduleClosure second third) :
    DynamicInnovationEquivalent semantics catalog moduleClosure first third := by
  constructor
  · exact operationallyEquivalent_trans catalog hfirst.1 hsecond.1
  · intro belief project
    exact (hfirst.2 belief project).trans (hsecond.2 belief project)

/-- The setoid of raw libraries under dynamic innovation equivalence. -/
def dynamicInnovationSetoid {model : FiniteModel}
    (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model) :
    Setoid (Library model catalog.inactiveStrategy) where
  r := DynamicInnovationEquivalent semantics catalog moduleClosure
  iseqv :=
    ⟨dynamicInnovationEquivalent_refl semantics catalog moduleClosure,
      dynamicInnovationEquivalent_symm semantics catalog moduleClosure,
      dynamicInnovationEquivalent_trans semantics catalog moduleClosure⟩

/-- Raw libraries modulo dynamic innovation equivalence. -/
abbrev DynamicInnovationQuotient {model : FiniteModel}
    (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model) :=
  Quotient (dynamicInnovationSetoid semantics catalog moduleClosure)

/-- The dynamic innovation quotient is finite because the raw library type is finite. -/
instance dynamicInnovationQuotientFinite {model : FiniteModel}
    (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model) :
    Finite (DynamicInnovationQuotient semantics catalog moduleClosure) :=
  inferInstance

/-- The dynamic innovation equivalence class of one raw library. -/
def dynamicInnovationClass {model : FiniteModel}
    (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (library : Library model catalog.inactiveStrategy) :
    DynamicInnovationQuotient semantics catalog moduleClosure :=
  Quotient.mk _ library

/--
Equal frontiers and equal research kernels preserve compressed finite-horizon
value at every horizon and belief.
-/
theorem compressedFiniteHorizonValue_eq_of_frontier_and_transition_eq
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    {left right : InnovationState model}
    (hfrontier : ∀ belief, left.frontier belief = right.frontier belief)
    (htransition : ∀ belief project,
      semantics.researchTransition belief left project =
        semantics.researchTransition belief right project) :
    ∀ horizon belief,
      compressedFiniteHorizonValue semantics horizon belief left =
        compressedFiniteHorizonValue semantics horizon belief right := by
  intro horizon
  induction horizon with
  | zero =>
      intro belief
      rfl
  | succ horizon inductionHypothesis =>
      intro belief
      have hidle :
          (semantics.beliefKernel belief).expectation
              (fun nextBelief =>
                compressedFiniteHorizonValue semantics horizon nextBelief left) =
            (semantics.beliefKernel belief).expectation
              (fun nextBelief =>
                compressedFiniteHorizonValue semantics horizon nextBelief right) :=
        RatProb.expectation_congr _ inductionHypothesis
      have hprojectPointwise : ∀ project,
          (semantics.beliefKernel belief).expectation
              (fun nextBelief =>
                (semantics.researchTransition belief left project).expectation
                  (fun nextState =>
                    compressedFiniteHorizonValue semantics horizon
                      nextBelief nextState)) =
            (semantics.beliefKernel belief).expectation
              (fun nextBelief =>
                (semantics.researchTransition belief right project).expectation
                  (fun nextState =>
                    compressedFiniteHorizonValue semantics horizon
                      nextBelief nextState)) := by
        intro project
        rw [htransition belief project]
      have hprojects :=
        finiteProjectMaximum_congr hprojectPointwise
      simp only [compressedFiniteHorizonValue]
      rw [hfrontier belief, hidle, hprojects]

/--
Dynamic innovation equivalent libraries have equal finite-horizon values at
every horizon and belief.
-/
theorem finiteHorizonValue_eq_of_dynamicInnovationEquivalent
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    {left right : Library model catalog.inactiveStrategy}
    (hequivalent :
      DynamicInnovationEquivalent semantics catalog moduleClosure left right) :
    ∀ horizon belief,
      dynamicLibraryValue semantics catalog moduleClosure horizon belief left =
        dynamicLibraryValue semantics catalog moduleClosure horizon belief right := by
  apply compressedFiniteHorizonValue_eq_of_frontier_and_transition_eq semantics
  · intro belief
    exact hequivalent.1 belief
  · exact hequivalent.2

/-- Finite-horizon value as a well-defined function on equivalence classes. -/
def quotientFiniteHorizonValue {model : FiniteModel}
    (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (horizon : Nat) (belief : model.Belief) :
    DynamicInnovationQuotient semantics catalog moduleClosure → ℚ :=
  Quotient.lift
    (dynamicLibraryValue semantics catalog moduleClosure horizon belief)
    (fun _ _ hequivalent =>
      finiteHorizonValue_eq_of_dynamicInnovationEquivalent
        semantics catalog moduleClosure hequivalent horizon belief)

/-- Evaluating quotient value on a class recovers the raw-library value. -/
@[simp]
theorem quotientFiniteHorizonValue_mk {model : FiniteModel}
    (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (horizon : Nat) (belief : model.Belief)
    (library : Library model catalog.inactiveStrategy) :
    quotientFiniteHorizonValue semantics catalog moduleClosure horizon belief
        (dynamicInnovationClass semantics catalog moduleClosure library) =
      dynamicLibraryValue semantics catalog moduleClosure horizon belief library :=
  rfl

/--
Finite-horizon value depends on a raw library only through its dynamic
innovation equivalence class.
-/
theorem finiteHorizonValue_depends_only_on_dynamicInnovationClass
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    (horizon : Nat) (belief : model.Belief) :
    ∃ valueOnClasses :
        DynamicInnovationQuotient semantics catalog moduleClosure → ℚ,
      ∀ library,
        dynamicLibraryValue semantics catalog moduleClosure horizon belief library =
          valueOnClasses
            (dynamicInnovationClass semantics catalog moduleClosure library) := by
  refine
    ⟨quotientFiniteHorizonValue semantics catalog moduleClosure horizon belief, ?_⟩
  intro library
  rfl

/--
A representation preserves operational rewards when equal representations
force equality of all current frontier values.
-/
def PreservesOperationalRewards {model : FiniteModel}
    (catalog : StrategyCatalog model) {Representation : Type*}
    (representation :
      Library model catalog.inactiveStrategy → Representation) : Prop :=
  ∀ ⦃left right⦄, representation left = representation right →
    OperationallyEquivalent catalog left right

/--
A representation preserves research transitions when equal representations
force equality of every induced compressed-state transition law.
-/
def PreservesResearchTransitions {model : FiniteModel}
    (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    {Representation : Type*}
    (representation :
      Library model catalog.inactiveStrategy → Representation) : Prop :=
  ∀ ⦃left right⦄, representation left = representation right →
    ∀ belief project,
      semantics.researchTransition belief
          (compressedLibraryState catalog moduleClosure left) project =
        semantics.researchTransition belief
          (compressedLibraryState catalog moduleClosure right) project

/--
Explicit minimality in the comparison class: every representation preserving
current rewards and all research transitions refines dynamic innovation
equivalence.
-/
theorem representation_refines_dynamicInnovationEquivalent
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    {Representation : Type*}
    (representation :
      Library model catalog.inactiveStrategy → Representation)
    (hreward : PreservesOperationalRewards catalog representation)
    (htransition :
      PreservesResearchTransitions semantics catalog moduleClosure representation)
    {left right : Library model catalog.inactiveStrategy}
    (hrepresentation : representation left = representation right) :
    DynamicInnovationEquivalent semantics catalog moduleClosure left right :=
  ⟨hreward hrepresentation, htransition hrepresentation⟩

/-- The kernel setoid induced by equality of an arbitrary representation. -/
def representationSetoid {model : FiniteModel}
    (catalog : StrategyCatalog model) {Representation : Type*}
    (representation :
      Library model catalog.inactiveStrategy → Representation) :
    Setoid (Library model catalog.inactiveStrategy) where
  r left right := representation left = representation right
  iseqv := ⟨fun _ => rfl, fun h => h.symm, fun h₁ h₂ => h₁.trans h₂⟩

/--
The quotient of any reward/transition-preserving representation maps
canonically to the dynamic innovation quotient.
-/
def representationQuotientToDynamicInnovationQuotient
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    {Representation : Type*}
    (representation :
      Library model catalog.inactiveStrategy → Representation)
    (hreward : PreservesOperationalRewards catalog representation)
    (htransition :
      PreservesResearchTransitions semantics catalog moduleClosure representation) :
    Quotient (representationSetoid catalog representation) →
      DynamicInnovationQuotient semantics catalog moduleClosure :=
  Quotient.lift
    (dynamicInnovationClass semantics catalog moduleClosure)
    (fun _ _ hrepresentation =>
      Quotient.sound
        (representation_refines_dynamicInnovationEquivalent
          semantics catalog moduleClosure representation hreward htransition
          hrepresentation))

/-- The canonical refinement map sends a representation class to its DI class. -/
@[simp]
theorem representationQuotientToDynamicInnovationQuotient_mk
    {model : FiniteModel} (semantics : FiniteResearchSemantics model)
    (catalog : StrategyCatalog model) (moduleClosure : ModuleClosure model)
    {Representation : Type*}
    (representation :
      Library model catalog.inactiveStrategy → Representation)
    (hreward : PreservesOperationalRewards catalog representation)
    (htransition :
      PreservesResearchTransitions semantics catalog moduleClosure representation)
    (library : Library model catalog.inactiveStrategy) :
    representationQuotientToDynamicInnovationQuotient
        semantics catalog moduleClosure representation hreward htransition
        (Quotient.mk _ library) =
      dynamicInnovationClass semantics catalog moduleClosure library :=
  rfl

end StrategyInnovation
