import Mathlib.Tactic
import StrategyInnovation.Counterexamples.FrontierPruningLoss
import StrategyInnovation.Value.FiniteHorizon

/-!
# Finite-horizon strategy-innovation decomposition

This file separates the value of a finite strategy insertion into its passive
operational contribution and its change in the option value of future
research.  The accounting identity is unconditional.  Frontier and closure
consequences use explicit adapter, factorization, and stochastic-monotonicity
hypotheses.

No sign is assigned to generative innovation without those hypotheses.
-/

namespace StrategyInnovation

namespace ValueDecomposition

open FiniteHorizon

universe u

/--
An exact adapter from raw finite libraries to an F5 finite-state process.

The frontier compatibility field makes the process's continue reward exactly
the raw library's operational frontier.  No transition factorization is built
into this basic adapter.
-/
structure LibraryDynamics (model : FiniteModel)
    (catalog : StrategyCatalog model) where
  process : FiniteHorizon.Process.{u, u} model
  compress :
    Library model catalog.inactiveStrategy → process.CompressedState
  frontier_eq : ∀ library belief,
    process.frontier (compress library) belief =
      operationalFrontier catalog library belief

/--
No-research value: repeatedly continue with the raw library frozen.
-/
def passiveValue {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog) :
    Nat → model.Belief → Library model catalog.inactiveStrategy → ℚ
  | 0, _, _ => 0
  | horizon + 1, belief, library =>
      operationalFrontier catalog library belief +
        dynamics.process.discount *
          expectedValue (dynamics.process.beliefTransition belief)
            (fun nextBelief =>
              passiveValue dynamics horizon nextBelief library)

/-- Full finite-horizon value with continue and every research action allowed. -/
def fullValue {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog) (horizon : Nat)
    (belief : model.Belief)
    (library : Library model catalog.inactiveStrategy) : ℚ :=
  finiteHorizonValue dynamics.process horizon belief
    (dynamics.compress library)

/-- The option value of retaining access to future research. -/
def researchOptionPremium {model : FiniteModel}
    {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog) (horizon : Nat)
    (belief : model.Belief)
    (library : Library model catalog.inactiveStrategy) : ℚ :=
  fullValue dynamics horizon belief library -
    passiveValue dynamics horizon belief library

/-- Total value created by inserting one strategy. -/
def totalInnovation {model : FiniteModel}
    {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog) (horizon : Nat)
    (belief : model.Belief)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId) : ℚ :=
  fullValue dynamics horizon belief (library.insert strategy) -
    fullValue dynamics horizon belief library

/-- Passive operational value created by inserting one strategy. -/
def operationalInnovation {model : FiniteModel}
    {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog) (horizon : Nat)
    (belief : model.Belief)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId) : ℚ :=
  passiveValue dynamics horizon belief (library.insert strategy) -
    passiveValue dynamics horizon belief library

/-- Change in the research-option premium caused by one strategy insertion. -/
def generativeInnovation {model : FiniteModel}
    {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog) (horizon : Nat)
    (belief : model.Belief)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId) : ℚ :=
  researchOptionPremium dynamics horizon belief (library.insert strategy) -
    researchOptionPremium dynamics horizon belief library

/--
Total innovation is exactly operational innovation plus generative innovation.
-/
theorem totalInnovation_eq_operational_add_generative
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog) (horizon : Nat)
    (belief : model.Belief)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId) :
    totalInnovation dynamics horizon belief library strategy =
      operationalInnovation dynamics horizon belief library strategy +
        generativeInnovation dynamics horizon belief library strategy := by
  unfold totalInnovation operationalInnovation generativeInnovation
    researchOptionPremium
  ring

/-- Equal raw frontiers give equal passive values at every horizon. -/
theorem passiveValue_eq_of_frontier_eq
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog)
    {left right : Library model catalog.inactiveStrategy}
    (hfrontier :
      operationalFrontier catalog left =
        operationalFrontier catalog right) :
    ∀ horizon belief,
      passiveValue dynamics horizon belief left =
        passiveValue dynamics horizon belief right := by
  intro horizon
  induction horizon with
  | zero =>
      intro belief
      rfl
  | succ horizon inductionHypothesis =>
      intro belief
      simp only [passiveValue]
      rw [congrFun hfrontier belief]
      apply congrArg
        (fun continuation =>
          operationalFrontier catalog right belief +
            dynamics.process.discount * continuation)
      apply expectedValue_extensionality rfl
      intro nextBelief
      exact inductionHypothesis nextBelief

/-- Frontier-preserving insertion has zero passive operational innovation. -/
theorem operationalInnovation_eq_zero_of_frontier_eq
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog) (horizon : Nat)
    (belief : model.Belief)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hfrontier :
      operationalFrontier catalog (library.insert strategy) =
        operationalFrontier catalog library) :
    operationalInnovation dynamics horizon belief library strategy = 0 := by
  unfold operationalInnovation
  rw [passiveValue_eq_of_frontier_eq dynamics hfrontier horizon belief]
  ring

/--
The finite process's costs and research transitions factor through the raw
library's operational frontier and generative closure.
-/
structure FactorsThroughFrontierClosure
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog)
    (moduleClosure : ModuleClosure model) : Prop where
  researchCost_eq :
    ∀ {left right : Library model catalog.inactiveStrategy},
      operationalFrontier catalog left =
          operationalFrontier catalog right →
        generativeClosure catalog moduleClosure left =
          generativeClosure catalog moduleClosure right →
        ∀ belief project,
          dynamics.process.researchCost belief (dynamics.compress left) project =
            dynamics.process.researchCost belief
              (dynamics.compress right) project
  researchTransition_eq :
    ∀ {left right : Library model catalog.inactiveStrategy},
      operationalFrontier catalog left =
          operationalFrontier catalog right →
        generativeClosure catalog moduleClosure left =
          generativeClosure catalog moduleClosure right →
        ∀ belief project,
          dynamics.process.researchTransition belief
                (dynamics.compress left) project =
            dynamics.process.researchTransition belief
              (dynamics.compress right) project

/-- Equal frontier and closure induce cost-sensitive DI equivalence. -/
theorem dynamicInnovationEquivalent_of_frontier_closure_eq
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog)
    (moduleClosure : ModuleClosure model)
    (hfactors : FactorsThroughFrontierClosure dynamics moduleClosure)
    {left right : Library model catalog.inactiveStrategy}
    (hfrontier :
      operationalFrontier catalog left =
        operationalFrontier catalog right)
    (hclosure :
      generativeClosure catalog moduleClosure left =
        generativeClosure catalog moduleClosure right) :
    FiniteHorizon.DynamicInnovationEquivalent dynamics.process
      (dynamics.compress left) (dynamics.compress right) := by
  constructor
  · intro belief
    exact (dynamics.frontier_eq left belief).trans
      ((congrFun hfrontier belief).trans
        (dynamics.frontier_eq right belief).symm)
  · constructor
    · exact hfactors.researchCost_eq hfrontier hclosure
    · exact hfactors.researchTransition_eq hfrontier hclosure

/-- Equal frontier and closure give equal full finite-horizon values. -/
theorem fullValue_eq_of_frontier_closure_eq
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog)
    (moduleClosure : ModuleClosure model)
    (hfactors : FactorsThroughFrontierClosure dynamics moduleClosure)
    {left right : Library model catalog.inactiveStrategy}
    (hfrontier :
      operationalFrontier catalog left =
        operationalFrontier catalog right)
    (hclosure :
      generativeClosure catalog moduleClosure left =
        generativeClosure catalog moduleClosure right)
    (horizon : Nat) (belief : model.Belief) :
    fullValue dynamics horizon belief left =
      fullValue dynamics horizon belief right := by
  unfold fullValue
  exact FiniteHorizon.finiteHorizonValue_eq_of_dynamicInnovationEquivalent
    dynamics.process
    (dynamicInnovationEquivalent_of_frontier_closure_eq
      dynamics moduleClosure hfactors hfrontier hclosure)
    horizon belief

/-- Insertion preserving both frontier and closure has zero total innovation. -/
theorem totalInnovation_eq_zero_of_frontier_closure_eq
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog)
    (moduleClosure : ModuleClosure model)
    (hfactors : FactorsThroughFrontierClosure dynamics moduleClosure)
    (horizon : Nat) (belief : model.Belief)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hfrontier :
      operationalFrontier catalog (library.insert strategy) =
        operationalFrontier catalog library)
    (hclosure :
      generativeClosure catalog moduleClosure (library.insert strategy) =
        generativeClosure catalog moduleClosure library) :
    totalInnovation dynamics horizon belief library strategy = 0 := by
  unfold totalInnovation
  rw [fullValue_eq_of_frontier_closure_eq dynamics moduleClosure hfactors
    hfrontier hclosure horizon belief]
  ring

/--
Exact stochastic monotonicity assumptions for library expansion.

`StateLE` orders compressed states by available innovation opportunities.
Research transitions preserve that order in expectation for every monotone
continuation, research costs weakly fall, and frontiers weakly rise.  These
are primitive one-step assumptions, not a premise about the optimized value or
the research-option premium.
-/
structure CandidateGenerationMonotone
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog) where
  StateLE :
    dynamics.process.CompressedState →
      dynamics.process.CompressedState → Prop
  compress_mono :
    ∀ {left right : Library model catalog.inactiveStrategy},
      left ≤ right → StateLE (dynamics.compress left) (dynamics.compress right)
  frontier_mono :
    ∀ {left right}, StateLE left right → ∀ belief,
      dynamics.process.frontier left belief ≤
        dynamics.process.frontier right belief
  researchCost_antitone :
    ∀ {left right}, StateLE left right → ∀ belief project,
      dynamics.process.researchCost belief right project ≤
        dynamics.process.researchCost belief left project
  candidateTransition_mono :
    ∀ {left right}, StateLE left right → ∀ belief project
      (value : dynamics.process.CompressedState → ℚ),
      (∀ {first second}, StateLE first second →
        value first ≤ value second) →
      expectedValue
          (dynamics.process.researchTransition belief left project) value ≤
        expectedValue
          (dynamics.process.researchTransition belief right project) value

/-- A continuation table is monotone in the declared compressed-state order. -/
def StateMonotone
    {model : FiniteModel} {catalog : StrategyCatalog model}
    {dynamics : LibraryDynamics model catalog}
    (hmonotone : CandidateGenerationMonotone dynamics)
    (value : ValueFunction dynamics.process) : Prop :=
  ∀ belief {left right}, hmonotone.StateLE left right →
    value belief left ≤ value belief right

/-- Continue values preserve the declared compressed-state order. -/
theorem continueValue_state_mono
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog)
    (hmonotone : CandidateGenerationMonotone dynamics)
    {continuation : ValueFunction dynamics.process}
    (hcontinuation : StateMonotone hmonotone continuation)
    (belief : model.Belief) {left right}
    (hstate : hmonotone.StateLE left right) :
    continueValue dynamics.process continuation belief left ≤
      continueValue dynamics.process continuation belief right := by
  unfold continueValue
  apply add_le_add
  · exact hmonotone.frontier_mono hstate belief
  · apply mul_le_mul_of_nonneg_left
    · apply expectedValue_mono
      intro nextBelief
      exact hcontinuation nextBelief hstate
    · exact dynamics.process.discount_nonnegative

/-- Research values preserve the declared compressed-state order. -/
theorem researchValue_state_mono
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog)
    (hmonotone : CandidateGenerationMonotone dynamics)
    {continuation : ValueFunction dynamics.process}
    (hcontinuation : StateMonotone hmonotone continuation)
    (belief : model.Belief) (project : model.ResearchProject)
    {left right} (hstate : hmonotone.StateLE left right) :
    researchValue dynamics.process continuation belief left project ≤
      researchValue dynamics.process continuation belief right project := by
  unfold researchValue
  apply add_le_add
  · exact neg_le_neg (hmonotone.researchCost_antitone hstate belief project)
  · apply mul_le_mul_of_nonneg_left
    · apply expectedValue_mono
      intro nextBelief
      apply hmonotone.candidateTransition_mono hstate belief project
      intro first second hnextState
      exact hcontinuation nextBelief hnextState
    · exact pow_nonneg dynamics.process.discount_nonnegative _

/-- Every finite action value preserves the declared state order. -/
theorem actionValue_state_mono
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog)
    (hmonotone : CandidateGenerationMonotone dynamics)
    {continuation : ValueFunction dynamics.process}
    (hcontinuation : StateMonotone hmonotone continuation)
    (belief : model.Belief) (action : Action model)
    {left right} (hstate : hmonotone.StateLE left right) :
    actionValue dynamics.process continuation belief left action ≤
      actionValue dynamics.process continuation belief right action := by
  cases action with
  | none =>
      exact continueValue_state_mono
        dynamics hmonotone hcontinuation belief hstate
  | some project =>
      exact researchValue_state_mono
        dynamics hmonotone hcontinuation belief project hstate

/-- One Bellman step preserves stochastic state monotonicity. -/
theorem bellmanStep_state_mono
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog)
    (hmonotone : CandidateGenerationMonotone dynamics)
    {continuation : ValueFunction dynamics.process}
    (hcontinuation : StateMonotone hmonotone continuation) :
    StateMonotone hmonotone
      (bellmanStep dynamics.process continuation) := by
  intro belief left right hstate
  unfold bellmanStep
  apply Finset.sup'_le Finset.univ_nonempty
  intro action haction
  exact (actionValue_state_mono dynamics hmonotone hcontinuation
    belief action hstate).trans
      (Finset.le_sup'
        (actionValue dynamics.process continuation belief right) haction)

/-- Every finite-horizon full-value table is state-monotone. -/
theorem finiteHorizonValue_state_mono
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog)
    (hmonotone : CandidateGenerationMonotone dynamics) :
    ∀ horizon,
      StateMonotone hmonotone
        (finiteHorizonValue dynamics.process horizon) := by
  intro horizon
  induction horizon with
  | zero =>
      intro belief left right hstate
      exact le_rfl
  | succ horizon inductionHypothesis =>
      exact bellmanStep_state_mono
        dynamics hmonotone inductionHypothesis

/-- Library inclusion weakly increases full value under the monotone kernel. -/
theorem fullValue_mono_of_library_inclusion
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog)
    (hmonotone : CandidateGenerationMonotone dynamics)
    {left right : Library model catalog.inactiveStrategy}
    (hinclude : left ≤ right) (horizon : Nat) (belief : model.Belief) :
    fullValue dynamics horizon belief left ≤
      fullValue dynamics horizon belief right := by
  unfold fullValue
  exact finiteHorizonValue_state_mono dynamics hmonotone horizon
    belief (hmonotone.compress_mono hinclude)

/--
Under stochastic candidate-generation monotonicity, inserting an
operationally redundant strategy cannot reduce the research-option premium.
-/
theorem researchOptionPremium_mono_of_candidateGenerationMonotone
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog)
    (hmonotone : CandidateGenerationMonotone dynamics)
    (horizon : Nat) (belief : model.Belief)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hfrontier :
      operationalFrontier catalog (library.insert strategy) =
        operationalFrontier catalog library) :
    researchOptionPremium dynamics horizon belief library ≤
      researchOptionPremium dynamics horizon belief
        (library.insert strategy) := by
  have hfull := fullValue_mono_of_library_inclusion
    dynamics hmonotone (Library.le_insert library strategy) horizon belief
  have hpassive := passiveValue_eq_of_frontier_eq
    dynamics hfrontier horizon belief
  unfold researchOptionPremium
  rw [hpassive]
  linarith

/--
Library insertion can only add closed modules and, under the explicit
monotonicity assumptions and unchanged frontier, cannot lower research-option
value.
-/
theorem moduleInsertion_does_not_reduce_researchOptionPremium
    {model : FiniteModel} {catalog : StrategyCatalog model}
    (dynamics : LibraryDynamics model catalog)
    (moduleClosure : ModuleClosure model)
    (hmonotone : CandidateGenerationMonotone dynamics)
    (horizon : Nat) (belief : model.Belief)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hfrontier :
      operationalFrontier catalog (library.insert strategy) =
        operationalFrontier catalog library) :
    generativeClosure catalog moduleClosure library ⊆
        generativeClosure catalog moduleClosure (library.insert strategy) ∧
      researchOptionPremium dynamics horizon belief library ≤
        researchOptionPremium dynamics horizon belief
          (library.insert strategy) := by
  constructor
  · exact generativeClosure_mono catalog moduleClosure
      (Library.le_insert library strategy)
  · exact researchOptionPremium_mono_of_candidateGenerationMonotone
      dynamics hmonotone horizon belief library strategy hfrontier

namespace ExactExample

open FrontierPruningLoss

/-- Exact F5 process for the zero-operational, positive-generative example. -/
noncomputable def process :
    FiniteHorizon.Process FrontierPruningLoss.model where
  CompressedState :=
    Library FrontierPruningLoss.model (catalog 2).inactiveStrategy
  stateFintype := inferInstance
  stateDecidableEq := Classical.decEq _
  stateNonempty := ⟨prunedLibrary 2⟩
  frontier := operationalFrontier (catalog 2)
  beliefTransition := fun _ => RatProb.dirac Belief.only
  researchTransition := fun _ library _ =>
    if Module.key ∈ generativeClosure (catalog 2) moduleClosure library then
      RatProb.dirac (futureLibrary 2)
    else
      RatProb.dirac (prunedLibrary 2)
  researchCost := fun _ _ _ => 0
  researchCost_nonnegative := by
    intros
    exact le_rfl
  researchDelay := fun _ => 0
  discount := 1 / 2
  discount_nonnegative := by norm_num
  discount_lt_one := by norm_num

/-- Raw libraries are the finite process states in the exact example. -/
noncomputable def dynamics :
    LibraryDynamics FrontierPruningLoss.model (catalog 2) where
  process := process
  compress := id
  frontier_eq := fun _ _ => rfl

/-- Inserting the bridge into the inactive library gives the unpruned library. -/
theorem insert_dominated_eq_unpruned :
    (prunedLibrary 2).insert Strategy.dominated =
      unprunedLibrary 2 := by
  apply Library.ext
  change
    Insert.insert Strategy.dominated ({Strategy.inactive} : Finset Strategy) =
      {Strategy.inactive, Strategy.dominated}
  decide

/-- The bridge insertion leaves the exact operational frontier unchanged. -/
theorem insertion_frontier_eq :
    operationalFrontier (catalog 2)
        ((prunedLibrary 2).insert Strategy.dominated) =
      operationalFrontier (catalog 2) (prunedLibrary 2) := by
  rw [insert_dominated_eq_unpruned, unpruned_frontier_eq_zero,
    pruned_frontier_eq_zero]

/-- The two exact actions are continue and the singleton research project. -/
theorem actionMaximum_eq_max
    (value : Action FrontierPruningLoss.model → ℚ) :
    Finset.univ.sup' Finset.univ_nonempty value =
      max (value none) (value (some Project.innovate)) := by
  apply le_antisymm
  · apply Finset.sup'_le Finset.univ_nonempty
    intro action _
    cases action with
    | none => exact le_max_left _ _
    | some project =>
        cases project
        exact le_max_right _ _
  · apply max_le
    · exact Finset.le_sup' value (Finset.mem_univ none)
    · exact Finset.le_sup' value (Finset.mem_univ (some Project.innovate))

/-- The future library has exact full value two at horizon one. -/
theorem future_fullValue_one_eq_two :
    fullValue dynamics 1 Belief.only (futureLibrary 2) = 2 := by
  simp [fullValue, dynamics, process, finiteHorizonValue, bellmanStep,
    actionValue, continueValue, researchValue, expectedValue,
    actionMaximum_eq_max,
    future_frontier_eq_reward (2 : ℚ) (by norm_num),
    future_closure_eq_empty]

/-- The inactive-only library has zero full value through horizon two. -/
theorem pruned_fullValue_two_eq_zero :
    fullValue dynamics 2 Belief.only (prunedLibrary 2) = 0 := by
  simp [fullValue, dynamics, process, finiteHorizonValue, bellmanStep,
    actionValue, continueValue, researchValue, expectedValue,
    actionMaximum_eq_max,
    pruned_frontier_eq_zero, pruned_closure_eq_empty]

/-- Retaining the bridge gives exact horizon-two full value one. -/
theorem unpruned_fullValue_two_eq_one :
    fullValue dynamics 2 Belief.only (unprunedLibrary 2) = 1 := by
  simp [fullValue, dynamics, process, finiteHorizonValue, bellmanStep,
    actionValue, continueValue, researchValue, expectedValue,
    actionMaximum_eq_max,
    unpruned_frontier_eq_zero, unpruned_closure_eq_key,
    future_frontier_eq_reward (2 : ℚ) (by norm_num),
    future_closure_eq_empty]

/-- Both current libraries have zero passive horizon-two value. -/
theorem passive_values_two_eq_zero :
    passiveValue dynamics 2 Belief.only (prunedLibrary 2) = 0 ∧
      passiveValue dynamics 2 Belief.only (unprunedLibrary 2) = 0 := by
  simp [passiveValue, dynamics, process, pruned_frontier_eq_zero,
    unpruned_frontier_eq_zero, expectedValue]

/--
Exact bridge example: operational innovation is zero, while generative
innovation is exactly one and hence strictly positive.
-/
theorem operationalInnovation_zero_generativeInnovation_positive :
    operationalInnovation dynamics 2 Belief.only (prunedLibrary 2)
          Strategy.dominated = 0 ∧
      generativeInnovation dynamics 2 Belief.only (prunedLibrary 2)
          Strategy.dominated = 1 ∧
      0 < generativeInnovation dynamics 2 Belief.only (prunedLibrary 2)
          Strategy.dominated := by
  have hoperational :
      operationalInnovation dynamics 2 Belief.only (prunedLibrary 2)
          Strategy.dominated = 0 :=
    operationalInnovation_eq_zero_of_frontier_eq
      dynamics 2 Belief.only (prunedLibrary 2) Strategy.dominated
        insertion_frontier_eq
  have hgenerative :
      generativeInnovation dynamics 2 Belief.only (prunedLibrary 2)
          Strategy.dominated = 1 := by
    unfold generativeInnovation researchOptionPremium
    rw [insert_dominated_eq_unpruned, unpruned_fullValue_two_eq_one,
      pruned_fullValue_two_eq_zero, passive_values_two_eq_zero.1,
      passive_values_two_eq_zero.2]
    norm_num
  exact ⟨hoperational, hgenerative, by rw [hgenerative]; norm_num⟩

end ExactExample

end ValueDecomposition

end StrategyInnovation
