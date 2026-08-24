import Mathlib.Tactic
import StrategyInnovation.Compression.SafeDeletion

/-!
# Sharp frontier-only pruning loss

This file gives a small exact construction in which a zero-payoff strategy is
operationally redundant but carries the unique module needed for research.
At horizon two and discount `1 / 2`, the value loss from frontier-only pruning
is exactly half the reward of the future strategy.

The arbitrarily-large theorem scales that future reward.  It is therefore not
the separate normalized-reward, varying-horizon theorem T4.  A sharp
bounded-reward corollary records that, within this construction, reward cap
`C` gives maximum loss exactly `C / 2`.
-/

namespace StrategyInnovation
namespace FrontierPruningLoss

inductive Belief
  | only
  deriving DecidableEq, Fintype

instance : Nonempty Belief :=
  ⟨Belief.only⟩

inductive Strategy
  | inactive
  | dominated
  | future
  deriving DecidableEq, Fintype

instance : Nonempty Strategy :=
  ⟨Strategy.inactive⟩

inductive Module
  | key
  deriving DecidableEq, Fintype

instance : Nonempty Module :=
  ⟨Module.key⟩

inductive Project
  | innovate
  deriving DecidableEq, Fintype

instance : Nonempty Project :=
  ⟨Project.innovate⟩

/-- One-belief, three-strategy, one-module, one-project finite carrier. -/
abbrev model : FiniteModel where
  Belief := Belief
  StrategyId := Strategy
  ModuleId := Module
  ResearchProject := Project

/--
The inactive and dominated strategies pay zero now; the strategy reachable
through research pays the exact rational parameter `reward`.
-/
def profile (reward : ℚ) : Strategy → Belief → ℚ
  | .inactive, _ => 0
  | .dominated, _ => 0
  | .future, _ => reward

/-- Only the dominated bridge contains the key research module. -/
def modules : Strategy → Finset Module
  | .inactive => ∅
  | .dominated => {Module.key}
  | .future => ∅

/-- Exact strategy catalog at future reward `reward`. -/
abbrev catalog (reward : ℚ) : StrategyCatalog model where
  operationalProfile := profile reward
  strategyModules := modules
  inactiveStrategy := Strategy.inactive
  inactiveProfile := by
    intro belief
    cases belief
    rfl
  inactiveModules := rfl

/-- Identity closure on the singleton module type. -/
abbrev moduleClosure : ModuleClosure model where
  close := id
  extensive := fun _ => Finset.Subset.refl _
  monotone := fun hinclude => hinclude
  idempotent := fun _ => rfl

/-- The pruned library contains only the inactive strategy. -/
def prunedLibrary (reward : ℚ) :
    Library model (catalog reward).inactiveStrategy where
  strategies := {Strategy.inactive}
  inactive_mem := by simp

/-- The unpruned current library retains the dominated bridge. -/
def unprunedLibrary (reward : ℚ) :
    Library model (catalog reward).inactiveStrategy where
  strategies := {Strategy.inactive, Strategy.dominated}
  inactive_mem := by simp

/-- The successful research outcome contains the high-value future strategy. -/
def futureLibrary (reward : ℚ) :
    Library model (catalog reward).inactiveStrategy where
  strategies := {Strategy.inactive, Strategy.future}
  inactive_mem := by simp

/-- The dominated bridge is not the distinguished inactive strategy. -/
theorem dominated_ne_inactive :
    Strategy.dominated ≠ Strategy.inactive := by
  decide

/-- Deleting the bridge gives exactly the pruned library. -/
theorem erase_dominated_eq_pruned (reward : ℚ) :
    (unprunedLibrary reward).erase
        Strategy.dominated dominated_ne_inactive =
      prunedLibrary reward := by
  apply Library.ext
  change
    ({Strategy.inactive, Strategy.dominated} : Finset Strategy).erase
        Strategy.dominated =
      {Strategy.inactive}
  decide

/-- Within the current unpruned library, only the dominated bridge has the key. -/
theorem keyModule_unique_to_dominated (reward : ℚ) :
    Module.key ∈ modules Strategy.dominated ∧
      ∀ strategy ∈ unprunedLibrary reward,
        Module.key ∈ modules strategy → strategy = Strategy.dominated := by
  constructor
  · simp [modules]
  · intro strategy hstrategy hmodule
    cases strategy <;> simp [modules] at hmodule ⊢

/-- The pruned library's current frontier is identically zero. -/
theorem pruned_frontier_eq_zero (reward : ℚ) :
    operationalFrontier (catalog reward) (prunedLibrary reward) =
      fun _ => 0 := by
  funext belief
  apply le_antisymm
  · apply (operationalFrontier_le_iff
      (catalog reward) (prunedLibrary reward) belief 0).2
    intro strategy hstrategy
    change strategy ∈ ({Strategy.inactive} : Finset Strategy) at hstrategy
    simp only [Finset.mem_singleton] at hstrategy
    subst strategy
    rfl
  · exact zero_le_operationalFrontier
      (catalog reward) (prunedLibrary reward) belief

/-- Retaining the dominated bridge also leaves the current frontier at zero. -/
theorem unpruned_frontier_eq_zero (reward : ℚ) :
    operationalFrontier (catalog reward) (unprunedLibrary reward) =
      fun _ => 0 := by
  funext belief
  apply le_antisymm
  · apply (operationalFrontier_le_iff
      (catalog reward) (unprunedLibrary reward) belief 0).2
    intro strategy hstrategy
    change strategy ∈
      ({Strategy.inactive, Strategy.dominated} : Finset Strategy) at hstrategy
    simp only [Finset.mem_insert, Finset.mem_singleton] at hstrategy
    rcases hstrategy with rfl | rfl <;> rfl
  · exact zero_le_operationalFrontier
      (catalog reward) (unprunedLibrary reward) belief

/-- The future library's frontier is exactly its nonnegative reward. -/
theorem future_frontier_eq_reward (reward : ℚ) (hreward : 0 ≤ reward) :
    operationalFrontier (catalog reward) (futureLibrary reward) =
      fun _ => reward := by
  funext belief
  apply le_antisymm
  · apply (operationalFrontier_le_iff
      (catalog reward) (futureLibrary reward) belief reward).2
    intro strategy hstrategy
    change strategy ∈
      ({Strategy.inactive, Strategy.future} : Finset Strategy) at hstrategy
    simp only [Finset.mem_insert, Finset.mem_singleton] at hstrategy
    rcases hstrategy with rfl | rfl
    · exact hreward
    · exact le_rfl
  · exact operationalProfile_le_frontier
      (catalog reward) (futureLibrary reward)
      (strategy := Strategy.future) (by
        change Strategy.future ∈
          ({Strategy.inactive, Strategy.future} : Finset Strategy)
        simp) belief

/-- Deleting the bridge preserves the current frontier exactly. -/
theorem dominated_operationallyRedundant (reward : ℚ) :
    operationallyRedundant (catalog reward) (unprunedLibrary reward)
      Strategy.dominated dominated_ne_inactive := by
  unfold operationallyRedundant
  rw [erase_dominated_eq_pruned, pruned_frontier_eq_zero,
    unpruned_frontier_eq_zero]

/-- The pruned library has empty generative closure. -/
theorem pruned_closure_eq_empty (reward : ℚ) :
    generativeClosure (catalog reward) moduleClosure
      (prunedLibrary reward) = ∅ := by
  simp [generativeClosure, rawModuleUnion, prunedLibrary, catalog, modules]

/-- The unpruned library's closure is exactly the bridge's key module. -/
theorem unpruned_closure_eq_key (reward : ℚ) :
    generativeClosure (catalog reward) moduleClosure
      (unprunedLibrary reward) = {Module.key} := by
  simp [generativeClosure, rawModuleUnion, unprunedLibrary, catalog, modules]

/-- The future strategy itself carries no module. -/
theorem future_closure_eq_empty (reward : ℚ) :
    generativeClosure (catalog reward) moduleClosure
      (futureLibrary reward) = ∅ := by
  simp [generativeClosure, rawModuleUnion, futureLibrary, catalog, modules]

/-- The bridge is generatively essential despite being operationally redundant. -/
theorem dominated_not_generativelyRedundant (reward : ℚ) :
    ¬ generativelyRedundant (catalog reward) moduleClosure
      (unprunedLibrary reward) Strategy.dominated dominated_ne_inactive := by
  intro hredundant
  unfold generativelyRedundant at hredundant
  rw [erase_dominated_eq_pruned, pruned_closure_eq_empty,
    unpruned_closure_eq_key] at hredundant
  simp at hredundant

/--
A literal frontier-only pruning rule: erase the bridge exactly when deletion
preserves the operational frontier.
-/
noncomputable def frontierOnlyPrune (reward : ℚ) :
    Library model (catalog reward).inactiveStrategy := by
  classical
  exact
    if operationallyRedundant (catalog reward) (unprunedLibrary reward)
        Strategy.dominated dominated_ne_inactive then
      (unprunedLibrary reward).erase
        Strategy.dominated dominated_ne_inactive
    else
      unprunedLibrary reward

/-- Frontier-only pruning deletes the dominated bridge. -/
theorem frontierOnlyPrune_eq_pruned (reward : ℚ) :
    frontierOnlyPrune reward = prunedLibrary reward := by
  rw [frontierOnlyPrune, if_pos (dominated_operationallyRedundant reward),
    erase_dominated_eq_pruned]

/-- The unpruned and frontier-pruned libraries have equal current frontiers. -/
theorem current_frontiers_equal (reward : ℚ) :
    operationalFrontier (catalog reward) (unprunedLibrary reward) =
      operationalFrontier (catalog reward) (frontierOnlyPrune reward) := by
  rw [frontierOnlyPrune_eq_pruned, pruned_frontier_eq_zero,
    unpruned_frontier_eq_zero]

/--
Research deterministically reaches the future strategy exactly when the key
module is in the supplied generative closure; otherwise it remains pruned.
-/
noncomputable def generator (reward : ℚ) : ModularGenerator model where
  candidateTransition := fun _ _ closure _ =>
    if Module.key ∈ closure then
      RatProb.dirac
        (compressedLibraryState
          (catalog reward) moduleClosure (futureLibrary reward))
    else
      RatProb.dirac
        (compressedLibraryState
          (catalog reward) moduleClosure (prunedLibrary reward))

/-- Exact research semantics with deterministic belief and discount one half. -/
noncomputable def semantics (reward : ℚ) : FiniteResearchSemantics model where
  beliefKernel := fun _ => RatProb.dirac Belief.only
  researchTransition := fun belief state project =>
    (generator reward).candidateTransition
      belief state.frontier state.closure project
  discount := 1 / 2
  discount_nonnegative := by norm_num
  discount_lt_one := by norm_num

/-- The research semantics definitionally factors through the modular generator. -/
theorem semantics_factors (reward : ℚ) :
    GeneratorFactorsThroughFrontierClosure
      (semantics reward) (generator reward) := by
  intro belief state project
  rfl

/-- With the bridge retained, research reaches the future-strategy state. -/
theorem researchTransition_unpruned (reward : ℚ) :
    (semantics reward).researchTransition Belief.only
        (compressedLibraryState
          (catalog reward) moduleClosure (unprunedLibrary reward))
        Project.innovate =
      RatProb.dirac
        (compressedLibraryState
          (catalog reward) moduleClosure (futureLibrary reward)) := by
  simp [semantics, generator, compressedLibraryState,
    unpruned_closure_eq_key]

/-- After frontier-only pruning, the same project remains in the pruned state. -/
theorem researchTransition_pruned (reward : ℚ) :
    (semantics reward).researchTransition Belief.only
        (compressedLibraryState
          (catalog reward) moduleClosure (prunedLibrary reward))
        Project.innovate =
      RatProb.dirac
        (compressedLibraryState
          (catalog reward) moduleClosure (prunedLibrary reward)) := by
  simp [semantics, generator, compressedLibraryState,
    pruned_closure_eq_empty]

/-- At horizon two, the pruned library has exact value zero. -/
theorem pruned_value_two_eq_zero (reward : ℚ) :
    dynamicLibraryValue (semantics reward) (catalog reward) moduleClosure
      2 Belief.only (prunedLibrary reward) = 0 := by
  simp [dynamicLibraryValue, compressedFiniteHorizonValue, semantics,
    generator, finiteProjectMaximum, compressedLibraryState,
    pruned_frontier_eq_zero, pruned_closure_eq_empty]

/-- At horizon two, retaining the bridge has exact value `reward / 2`. -/
theorem unpruned_value_two_eq_half_reward
    (reward : ℚ) (hreward : 0 ≤ reward) :
    dynamicLibraryValue (semantics reward) (catalog reward) moduleClosure
      2 Belief.only (unprunedLibrary reward) = reward / 2 := by
  simp [dynamicLibraryValue, compressedFiniteHorizonValue, semantics,
    generator, finiteProjectMaximum, compressedLibraryState,
    pruned_frontier_eq_zero, pruned_closure_eq_empty,
    unpruned_frontier_eq_zero, unpruned_closure_eq_key,
    future_frontier_eq_reward reward hreward, future_closure_eq_empty,
    hreward]
  ring

/-- The two-period frontier-pruning loss is exactly half the future reward. -/
theorem frontierPruningLoss_exact
    (reward : ℚ) (hreward : 0 ≤ reward) :
    dynamicLibraryValue (semantics reward) (catalog reward) moduleClosure
          2 Belief.only (unprunedLibrary reward) -
        dynamicLibraryValue (semantics reward) (catalog reward) moduleClosure
          2 Belief.only (frontierOnlyPrune reward) =
      reward / 2 := by
  rw [frontierOnlyPrune_eq_pruned,
    unpruned_value_two_eq_half_reward reward hreward,
    pruned_value_two_eq_zero]
  ring

/-- Scaling the future reward to `2 * target` makes loss exactly `target`. -/
theorem frontierPruningLoss_scaledTarget_exact (target : ℕ) :
    dynamicLibraryValue
          (semantics (2 * target)) (catalog (2 * target)) moduleClosure
          2 Belief.only (unprunedLibrary (2 * target)) -
        dynamicLibraryValue
          (semantics (2 * target)) (catalog (2 * target)) moduleClosure
          2 Belief.only (frontierOnlyPrune (2 * target)) =
      target := by
  have hreward : (0 : ℚ) ≤ 2 * target := by positivity
  rw [frontierPruningLoss_exact (2 * target) hreward]
  norm_num

/-- Exact data asserted by the parameterized frontier-pruning witness. -/
def FrontierPruningWitness (target reward : ℚ) : Prop :=
  0 ≤ reward ∧
    operationallyRedundant (catalog reward) (unprunedLibrary reward)
      Strategy.dominated dominated_ne_inactive ∧
    ¬ generativelyRedundant (catalog reward) moduleClosure
      (unprunedLibrary reward) Strategy.dominated dominated_ne_inactive ∧
    frontierOnlyPrune reward = prunedLibrary reward ∧
    operationalFrontier (catalog reward) (unprunedLibrary reward) =
      operationalFrontier (catalog reward) (frontierOnlyPrune reward) ∧
    target ≤
      dynamicLibraryValue (semantics reward) (catalog reward) moduleClosure
          2 Belief.only (unprunedLibrary reward) -
        dynamicLibraryValue (semantics reward) (catalog reward) moduleClosure
          2 Belief.only (frontierOnlyPrune reward)

/--
For every natural target loss, scaling the future reward to `2 * M` supplies a
finite exact witness whose frontier-pruning loss is at least `M`.
-/
theorem frontierPruningLoss_arbitrarilyLarge :
    ∀ target : ℕ, ∃ reward : ℚ,
      FrontierPruningWitness target reward := by
  intro target
  let reward : ℚ := 2 * target
  refine ⟨reward, ?_⟩
  have hreward : 0 ≤ reward := by
    dsimp [reward]
    positivity
  refine
    ⟨hreward,
      dominated_operationallyRedundant reward,
      dominated_not_generativelyRedundant reward,
      frontierOnlyPrune_eq_pruned reward,
      current_frontiers_equal reward, ?_⟩
  change
    (target : ℚ) ≤
      dynamicLibraryValue
            (semantics (2 * target)) (catalog (2 * target)) moduleClosure
            2 Belief.only (unprunedLibrary (2 * target)) -
          dynamicLibraryValue
            (semantics (2 * target)) (catalog (2 * target)) moduleClosure
            2 Belief.only (frontierOnlyPrune (2 * target))
  rw [frontierPruningLoss_scaledTarget_exact target]

/-- All catalog rewards lie in the interval from zero to `cap`. -/
def RewardsBoundedBy (reward cap : ℚ) : Prop :=
  ∀ strategy belief,
    0 ≤ profile reward strategy belief ∧
      profile reward strategy belief ≤ cap

/--
Under a nonnegative reward cap, every member of the explicit construction has
loss at most `cap / 2`, and choosing future reward equal to `cap` attains the
bound. Thus `cap / 2` is sharp within this fixed two-period construction.
-/
theorem boundedReward_frontierPruningLoss_sharp
    (cap : ℚ) (hcap : 0 ≤ cap) :
    (∀ reward : ℚ, RewardsBoundedBy reward cap →
      dynamicLibraryValue (semantics reward) (catalog reward) moduleClosure
            2 Belief.only (unprunedLibrary reward) -
          dynamicLibraryValue (semantics reward) (catalog reward) moduleClosure
            2 Belief.only (frontierOnlyPrune reward) ≤
        cap / 2) ∧
      RewardsBoundedBy cap cap ∧
      dynamicLibraryValue (semantics cap) (catalog cap) moduleClosure
            2 Belief.only (unprunedLibrary cap) -
          dynamicLibraryValue (semantics cap) (catalog cap) moduleClosure
            2 Belief.only (frontierOnlyPrune cap) =
        cap / 2 := by
  constructor
  · intro reward hbounded
    have hreward : 0 ≤ reward :=
      (hbounded Strategy.future Belief.only).1
    have hrewardCap : reward ≤ cap :=
      (hbounded Strategy.future Belief.only).2
    rw [frontierPruningLoss_exact reward hreward]
    linarith
  · constructor
    · intro strategy belief
      cases strategy <;> cases belief <;>
        simp [profile, hcap]
    · exact frontierPruningLoss_exact cap hcap

end FrontierPruningLoss
end StrategyInnovation
