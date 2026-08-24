import Mathlib.Order.UpperLower.Basic
import Mathlib.Tactic
import StrategyInnovation.Coverage.Potential
import StrategyInnovation.Fixtures.SingleGapGeometry

/-!
# Monotone-gap one-shot coverage geometry on a finite ordered belief grid

Single-peakedness of a nonnegative gap does not by itself make its expected
coverage potential single-peaked: a three-state deterministic transition
kernel already gives a counterexample.  The strongest non-tautological result
proved here instead uses first-order stochastic monotonicity.  An increasing
gap is mapped to an increasing expected gap; a nonnegative increasing survival,
success, or admission factor and nonnegative discount preserve this order; and
an antitone cost makes the one-shot cost-covering set an upper set.  On a
finite linear order that upper set is empty or an upper threshold interval.

All expectations are exact finite sums over `ℚ`.  No continuous interval or
measure-theoretic claim is made.  In particular, this file does not define or
characterize the optimal Bellman research region.
-/

namespace StrategyInnovation

namespace Coverage

open Set

universe u v w

variable {Belief : Type u} [LinearOrder Belief]

/-- The strictly positive support of a gap is an interval in the order. -/
def HasIntervalSupport (gap : Belief → ℚ) : Prop :=
  Set.OrdConnected {belief | 0 < gap belief}

/-- A sequence is single-peaked when it is increasing up to some peak and
decreasing thereafter. Weak inequalities allow flat portions. -/
def IsSinglePeaked (gap : Belief → ℚ) : Prop :=
  ∃ peak,
    MonotoneOn gap (Set.Iic peak) ∧
      AntitoneOn gap (Set.Ici peak)

/-- A certified gap is pointwise nonnegative and single-peaked. -/
def IsNonnegativeSinglePeaked (gap : Belief → ℚ) : Prop :=
  (∀ belief, 0 ≤ gap belief) ∧ IsSinglePeaked gap

/-- Ordered-sequence quasi-concavity: an interior value is at least the
minimum of the two endpoint values. -/
def IsQuasiConcaveSequence (gap : Belief → ℚ) : Prop :=
  ∀ ⦃left middle right : Belief⦄,
    left ≤ middle → middle ≤ right →
      min (gap left) (gap right) ≤ gap middle

/-- Every weak upper level set is order-connected. -/
def HasConnectedUpperLevelSets (gap : Belief → ℚ) : Prop :=
  ∀ level, Set.OrdConnected {belief | level ≤ gap belief}

/-- On a linear order, the three-point definition of quasi-concavity is
equivalent to connectedness of every weak upper level set. -/
theorem quasiConcaveSequence_iff_connectedUpperLevelSets (gap : Belief → ℚ) :
    IsQuasiConcaveSequence gap ↔ HasConnectedUpperLevelSets gap := by
  constructor
  · intro hquasi level
    rw [Set.ordConnected_iff]
    intro left hleft right hright hle middle hmiddle
    change level ≤ gap middle
    exact (le_min hleft hright).trans (hquasi hmiddle.1 hmiddle.2)
  · intro hlevels left middle right hleft hright
    have hconnected := hlevels (min (gap left) (gap right))
    have hleftLevel :
        left ∈ {belief | min (gap left) (gap right) ≤ gap belief} :=
      by
        change min (gap left) (gap right) ≤ gap left
        exact min_le_left _ _
    have hrightLevel :
        right ∈ {belief | min (gap left) (gap right) ≤ gap belief} :=
      by
        change min (gap left) (gap right) ≤ gap right
        exact min_le_right _ _
    exact hconnected.out hleftLevel hrightLevel ⟨hleft, hright⟩

/-- A single-peaked ordered sequence is quasi-concave. -/
theorem IsSinglePeaked.quasiConcaveSequence {gap : Belief → ℚ}
    (hpeak : IsSinglePeaked gap) : IsQuasiConcaveSequence gap := by
  rcases hpeak with ⟨peak, hincreasing, hdecreasing⟩
  intro left middle right hleft hright
  rcases le_total middle peak with hmiddlePeak | hpeakMiddle
  · exact (min_le_left (gap left) (gap right)).trans
      (hincreasing (hleft.trans hmiddlePeak) hmiddlePeak hleft)
  · exact (min_le_right (gap left) (gap right)).trans
      (hdecreasing hpeakMiddle (hpeakMiddle.trans hright) hright)

/-- Hence every upper level set of a single-peaked sequence is an interval on
the finite grid (and, in fact, on any linear order). -/
theorem IsSinglePeaked.connectedUpperLevelSets {gap : Belief → ℚ}
    (hpeak : IsSinglePeaked gap) : HasConnectedUpperLevelSets gap :=
  (quasiConcaveSequence_iff_connectedUpperLevelSets gap).mp
    hpeak.quasiConcaveSequence

/-- A single-peaked gap has connected strictly positive support. -/
theorem IsSinglePeaked.intervalSupport {gap : Belief → ℚ}
    (hpeak : IsSinglePeaked gap) : HasIntervalSupport gap := by
  unfold HasIntervalSupport
  rw [Set.ordConnected_iff]
  intro left hleft right hright hle middle hmiddle
  change 0 < gap middle
  exact (lt_min hleft hright).trans_le
    (hpeak.quasiConcaveSequence hmiddle.1 hmiddle.2)

/-- An exact finite row-stochastic transition kernel on the belief grid. -/
structure FiniteTransitionKernel (grid : FiniteOrderedBeliefGrid) where
  weight : grid.Belief → grid.Belief → ℚ
  nonnegative : ∀ initial future, 0 ≤ weight initial future
  rowSum : ∀ initial, ∑ future : grid.Belief, weight initial future = 1

/-- Exact expected future gap under one row of a transition kernel. -/
def expectedGap {grid : FiniteOrderedBeliefGrid}
    (kernel : FiniteTransitionKernel grid) (gap : grid.Belief → ℚ)
    (initial : grid.Belief) : ℚ :=
  ∑ future : grid.Belief, kernel.weight initial future * gap future

/-- First-order stochastic monotonicity, stated by its exact finite
expectation characterization. It is the preservation property used below. -/
def IsStochasticallyMonotone {grid : FiniteOrderedBeliefGrid}
    (kernel : FiniteTransitionKernel grid) : Prop :=
  ∀ gap : grid.Belief → ℚ, Monotone gap → Monotone (expectedGap kernel gap)

/-- The exact discounted gross single-gap research value. `survival` may vary
with the initial belief. -/
def grossCoverageValue {grid : FiniteOrderedBeliefGrid}
    (discount : ℚ) (survival : grid.Belief → ℚ)
    (kernel : FiniteTransitionKernel grid) (gap : grid.Belief → ℚ)
    (initial : grid.Belief) : ℚ :=
  discount * survival initial * expectedGap kernel gap initial

/--
Beliefs at which exact one-shot gross single-gap value weakly covers research
cost.  This is not an optimal dynamic research region.
-/
def oneShotCostCoveringSet {grid : FiniteOrderedBeliefGrid}
    (discount : ℚ) (survival : grid.Belief → ℚ)
    (kernel : FiniteTransitionKernel grid) (gap cost : grid.Belief → ℚ) :
    Set grid.Belief :=
  {initial | cost initial ≤
    grossCoverageValue discount survival kernel gap initial}

/--
Compatibility alias for the pre-revision name.  Publication-facing results use
`oneShotCostCoveringSet`; no optimal Bellman interpretation is attached.
-/
abbrev singleGapResearchRegion {grid : FiniteOrderedBeliefGrid}
    (discount : ℚ) (survival : grid.Belief → ℚ)
    (kernel : FiniteTransitionKernel grid) (gap cost : grid.Belief → ℚ) :
    Set grid.Belief :=
  oneShotCostCoveringSet discount survival kernel gap cost

/-- A nonnegative gap has nonnegative exact expectation under a finite
transition kernel. -/
theorem expectedGap_nonnegative {grid : FiniteOrderedBeliefGrid}
    (kernel : FiniteTransitionKernel grid) (gap : grid.Belief → ℚ)
    (hgap : ∀ belief, 0 ≤ gap belief) (initial : grid.Belief) :
    0 ≤ expectedGap kernel gap initial := by
  classical
  unfold expectedGap
  exact Finset.sum_nonneg fun future _ =>
    mul_nonneg (kernel.nonnegative initial future) (hgap future)

/-- A stochastically monotone finite kernel maps an increasing gap to an
increasing expected gap. -/
theorem expectedGap_monotone {grid : FiniteOrderedBeliefGrid}
    (kernel : FiniteTransitionKernel grid)
    (hstochastic : IsStochasticallyMonotone kernel)
    (gap : grid.Belief → ℚ) (hgap : Monotone gap) :
    Monotone (expectedGap kernel gap) :=
  hstochastic gap hgap

/-- Nonnegative discounting and an increasing nonnegative survival factor
preserve monotonicity of expected gap. -/
theorem grossCoverageValue_monotone {grid : FiniteOrderedBeliefGrid}
    {discount : ℚ} {survival gap : grid.Belief → ℚ}
    (kernel : FiniteTransitionKernel grid)
    (hdiscount : 0 ≤ discount)
    (hsurvivalNonnegative : ∀ belief, 0 ≤ survival belief)
    (hsurvival : Monotone survival)
    (hgapNonnegative : ∀ belief, 0 ≤ gap belief)
    (hgap : Monotone gap)
    (hstochastic : IsStochasticallyMonotone kernel) :
    Monotone (grossCoverageValue discount survival kernel gap) := by
  intro initial₁ initial₂ hinitial
  have hexpectation :
      expectedGap kernel gap initial₁ ≤ expectedGap kernel gap initial₂ :=
    hstochastic gap hgap hinitial
  calc
    grossCoverageValue discount survival kernel gap initial₁ =
        (discount * survival initial₁) * expectedGap kernel gap initial₁ := rfl
    _ ≤ (discount * survival initial₂) * expectedGap kernel gap initial₁ :=
      mul_le_mul_of_nonneg_right
        (mul_le_mul_of_nonneg_left (hsurvival hinitial) hdiscount)
        (expectedGap_nonnegative kernel gap hgapNonnegative initial₁)
    _ ≤ (discount * survival initial₂) * expectedGap kernel gap initial₂ :=
      mul_le_mul_of_nonneg_left hexpectation
        (mul_nonneg hdiscount (hsurvivalNonnegative initial₂))
    _ = grossCoverageValue discount survival kernel gap initial₂ := rfl

/-- Under monotone primitives, the one-shot cost-covering set is upward closed. -/
theorem oneShotCostCoveringSet_isUpperSet
    {grid : FiniteOrderedBeliefGrid}
    {discount : ℚ} {survival gap cost : grid.Belief → ℚ}
    (kernel : FiniteTransitionKernel grid)
    (hdiscount : 0 ≤ discount)
    (hsurvivalNonnegative : ∀ belief, 0 ≤ survival belief)
    (hsurvival : Monotone survival)
    (hgapNonnegative : ∀ belief, 0 ≤ gap belief)
    (hgap : Monotone gap)
    (hstochastic : IsStochasticallyMonotone kernel)
    (hcost : Antitone cost) :
    IsUpperSet
      (oneShotCostCoveringSet discount survival kernel gap cost) := by
  have hgross := grossCoverageValue_monotone kernel hdiscount
    hsurvivalNonnegative hsurvival hgapNonnegative hgap hstochastic
  intro initial₁ initial₂ hinitial hcovered
  exact (hcost hinitial).trans (hcovered.trans (hgross hinitial))

/--
Compatibility theorem for the former declaration name.  It is a one-shot
cost-covering result, not a Bellman-policy theorem.
-/
theorem singleGapResearchRegion_isUpperSet
    {grid : FiniteOrderedBeliefGrid}
    {discount : ℚ} {survival gap cost : grid.Belief → ℚ}
    (kernel : FiniteTransitionKernel grid)
    (hdiscount : 0 ≤ discount)
    (hsurvivalNonnegative : ∀ belief, 0 ≤ survival belief)
    (hsurvival : Monotone survival)
    (hgapNonnegative : ∀ belief, 0 ≤ gap belief)
    (hgap : Monotone gap)
    (hstochastic : IsStochasticallyMonotone kernel)
    (hcost : Antitone cost) :
    IsUpperSet
      (singleGapResearchRegion discount survival kernel gap cost) :=
  oneShotCostCoveringSet_isUpperSet kernel hdiscount
    hsurvivalNonnegative hsurvival hgapNonnegative hgap hstochastic hcost

/-- **Monotone-gap upper-threshold theorem.** An increasing
nonnegative gap, a first-order stochastically monotone transition kernel, an
increasing nonnegative survival, success, or admission factor, a nonnegative
discount, and an antitone research cost produce an increasing gross value and
an upper one-shot cost-covering set. The set is order-connected and, on the
finite grid, is either empty or exactly `Ici cutoff` for some grid point. -/
theorem monotoneGap_upperThreshold
    {grid : FiniteOrderedBeliefGrid}
    {discount : ℚ} {survival gap cost : grid.Belief → ℚ}
    (kernel : FiniteTransitionKernel grid)
    (hdiscount : 0 ≤ discount)
    (hsurvivalNonnegative : ∀ belief, 0 ≤ survival belief)
    (hsurvival : Monotone survival)
    (hgapNonnegative : ∀ belief, 0 ≤ gap belief)
    (hgap : Monotone gap)
    (hstochastic : IsStochasticallyMonotone kernel)
    (hcost : Antitone cost) :
    Monotone (grossCoverageValue discount survival kernel gap) ∧
      IsUpperSet (oneShotCostCoveringSet discount survival kernel gap cost) ∧
      Set.OrdConnected
        (oneShotCostCoveringSet discount survival kernel gap cost) ∧
      (oneShotCostCoveringSet discount survival kernel gap cost = ∅ ∨
        ∃ cutoff : grid.Belief,
          oneShotCostCoveringSet discount survival kernel gap cost =
            Set.Ici cutoff) := by
  have hgross := grossCoverageValue_monotone kernel hdiscount
    hsurvivalNonnegative hsurvival hgapNonnegative hgap hstochastic
  have hupper := oneShotCostCoveringSet_isUpperSet kernel hdiscount
    hsurvivalNonnegative hsurvival hgapNonnegative hgap hstochastic hcost
  exact ⟨hgross, hupper, hupper.ordConnected, hupper.eq_empty_or_Ici⟩

/-- Compatibility alias for the former main theorem name. -/
theorem monotone_singleGap_yields_upperThreshold
    {grid : FiniteOrderedBeliefGrid}
    {discount : ℚ} {survival gap cost : grid.Belief → ℚ}
    (kernel : FiniteTransitionKernel grid)
    (hdiscount : 0 ≤ discount)
    (hsurvivalNonnegative : ∀ belief, 0 ≤ survival belief)
    (hsurvival : Monotone survival)
    (hgapNonnegative : ∀ belief, 0 ≤ gap belief)
    (hgap : Monotone gap)
    (hstochastic : IsStochasticallyMonotone kernel)
    (hcost : Antitone cost) :
    Monotone (grossCoverageValue discount survival kernel gap) ∧
      IsUpperSet (singleGapResearchRegion discount survival kernel gap cost) ∧
      Set.OrdConnected
        (singleGapResearchRegion discount survival kernel gap cost) ∧
      (singleGapResearchRegion discount survival kernel gap cost = ∅ ∨
        ∃ cutoff : grid.Belief,
          singleGapResearchRegion discount survival kernel gap cost =
            Set.Ici cutoff) :=
  monotoneGap_upperThreshold kernel hdiscount hsurvivalNonnegative hsurvival
    hgapNonnegative hgap hstochastic hcost

/-! ## One-shot cutoff comparative statics -/

/-- Exact finite expectation is monotone in the pointwise gap table. -/
theorem expectedGap_mono_gap {grid : FiniteOrderedBeliefGrid}
    (kernel : FiniteTransitionKernel grid)
    {gap₀ gap₁ : grid.Belief → ℚ}
    (hgap : ∀ belief, gap₀ belief ≤ gap₁ belief)
    (initial : grid.Belief) :
    expectedGap kernel gap₀ initial ≤ expectedGap kernel gap₁ initial := by
  classical
  unfold expectedGap
  apply Finset.sum_le_sum
  intro future hfuture
  exact mul_le_mul_of_nonneg_left (hgap future)
    (kernel.nonnegative initial future)

/-- Higher pointwise research cost weakly shrinks the one-shot covering set. -/
theorem oneShotCostCoveringSet_antitone_cost
    {grid : FiniteOrderedBeliefGrid}
    (discount : ℚ) (survival : grid.Belief → ℚ)
    (kernel : FiniteTransitionKernel grid) (gap : grid.Belief → ℚ)
    {cost₀ cost₁ : grid.Belief → ℚ}
    (hcost : ∀ belief, cost₀ belief ≤ cost₁ belief) :
    oneShotCostCoveringSet discount survival kernel gap cost₁ ⊆
      oneShotCostCoveringSet discount survival kernel gap cost₀ := by
  intro belief hcovered
  exact (hcost belief).trans hcovered

/-- A higher nonnegative survival/success factor expands the covering set. -/
theorem oneShotCostCoveringSet_mono_success
    {grid : FiniteOrderedBeliefGrid}
    {discount : ℚ} {success₀ success₁ gap cost : grid.Belief → ℚ}
    (kernel : FiniteTransitionKernel grid)
    (hdiscount : 0 ≤ discount)
    (hsuccess : ∀ belief, success₀ belief ≤ success₁ belief)
    (hgap : ∀ belief, 0 ≤ gap belief) :
    oneShotCostCoveringSet discount success₀ kernel gap cost ⊆
      oneShotCostCoveringSet discount success₁ kernel gap cost := by
  intro belief hcovered
  change cost belief ≤
    grossCoverageValue discount success₁ kernel gap belief
  change cost belief ≤
    grossCoverageValue discount success₀ kernel gap belief at hcovered
  apply hcovered.trans
  unfold grossCoverageValue
  apply mul_le_mul_of_nonneg_right
  · exact mul_le_mul_of_nonneg_left (hsuccess belief) hdiscount
  · exact expectedGap_nonnegative kernel gap hgap belief

/-- Survival-probability comparative static for the one-shot covering set. -/
theorem oneShotCostCoveringSet_mono_survival
    {grid : FiniteOrderedBeliefGrid}
    {discount : ℚ} {survival₀ survival₁ gap cost : grid.Belief → ℚ}
    (kernel : FiniteTransitionKernel grid)
    (hdiscount : 0 ≤ discount)
    (hsurvival : ∀ belief, survival₀ belief ≤ survival₁ belief)
    (hgap : ∀ belief, 0 ≤ gap belief) :
    oneShotCostCoveringSet discount survival₀ kernel gap cost ⊆
      oneShotCostCoveringSet discount survival₁ kernel gap cost :=
  oneShotCostCoveringSet_mono_success kernel hdiscount hsurvival hgap

/-- Admission-probability comparative static for the same one-shot factor. -/
theorem oneShotCostCoveringSet_mono_admissionProbability
    {grid : FiniteOrderedBeliefGrid}
    {discount : ℚ} {admission₀ admission₁ gap cost : grid.Belief → ℚ}
    (kernel : FiniteTransitionKernel grid)
    (hdiscount : 0 ≤ discount)
    (hadmission : ∀ belief, admission₀ belief ≤ admission₁ belief)
    (hgap : ∀ belief, 0 ≤ gap belief) :
    oneShotCostCoveringSet discount admission₀ kernel gap cost ⊆
      oneShotCostCoveringSet discount admission₁ kernel gap cost :=
  oneShotCostCoveringSet_mono_success kernel hdiscount hadmission hgap

/--
A pointwise higher frontier shrinks a fixed candidate's gap (wherever that
candidate has an advantage), and hence shrinks its one-shot covering set.
-/
theorem oneShotCostCoveringSet_antitone_frontier
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    {discount : ℚ} {success cost : grid.Belief → ℚ}
    (kernel : FiniteTransitionKernel grid)
    (candidateValue : Project → grid.Belief → ℚ)
    (frontier : LibraryState → grid.Belief → ℚ)
    {oldState newState : LibraryState}
    (himproves : FrontierImproves frontier oldState newState)
    (project : Project)
    (hdiscount : 0 ≤ discount)
    (hsuccess : ∀ belief, 0 ≤ success belief) :
    oneShotCostCoveringSet discount success kernel
        (certifiedGap candidateValue frontier project newState) cost ⊆
      oneShotCostCoveringSet discount success kernel
        (certifiedGap candidateValue frontier project oldState) cost := by
  intro belief hcovered
  change cost belief ≤
    grossCoverageValue discount success kernel
      (certifiedGap candidateValue frontier project oldState) belief
  change cost belief ≤
    grossCoverageValue discount success kernel
      (certifiedGap candidateValue frontier project newState) belief at hcovered
  apply hcovered.trans
  unfold grossCoverageValue
  apply mul_le_mul_of_nonneg_left
  · exact expectedGap_mono_gap kernel
      (fun future =>
        certifiedGap_antitone_of_frontier_improves candidateValue frontier
          himproves project future)
      belief
  · exact mul_nonneg hdiscount (hsuccess belief)

/-- Inclusion of upper threshold sets orders their represented cutoffs. -/
theorem cutoff_le_of_Ici_subset
    {grid : FiniteOrderedBeliefGrid}
    {lowerSet upperSet : Set grid.Belief}
    {lowerCutoff upperCutoff : grid.Belief}
    (hlower : lowerSet = Set.Ici lowerCutoff)
    (hupper : upperSet = Set.Ici upperCutoff)
    (hsubset : upperSet ⊆ lowerSet) :
    lowerCutoff ≤ upperCutoff := by
  have hmem : upperCutoff ∈ lowerSet := by
    apply hsubset
    rw [hupper]
    exact Set.mem_Ici.mpr le_rfl
  rw [hlower] at hmem
  exact Set.mem_Ici.mp hmem

/-- Higher cost weakly raises the cutoff whenever both sets are nonempty thresholds. -/
theorem cost_cutoff_mono
    {grid : FiniteOrderedBeliefGrid}
    (discount : ℚ) (success : grid.Belief → ℚ)
    (kernel : FiniteTransitionKernel grid) (gap : grid.Belief → ℚ)
    {cost₀ cost₁ : grid.Belief → ℚ}
    {cutoff₀ cutoff₁ : grid.Belief}
    (hcost : ∀ belief, cost₀ belief ≤ cost₁ belief)
    (hcutoff₀ :
      oneShotCostCoveringSet discount success kernel gap cost₀ =
        Set.Ici cutoff₀)
    (hcutoff₁ :
      oneShotCostCoveringSet discount success kernel gap cost₁ =
        Set.Ici cutoff₁) :
    cutoff₀ ≤ cutoff₁ :=
  cutoff_le_of_Ici_subset hcutoff₀ hcutoff₁
    (oneShotCostCoveringSet_antitone_cost discount success kernel gap hcost)

/-- Higher survival weakly lowers the cutoff for nonempty threshold sets. -/
theorem survival_cutoff_antitone
    {grid : FiniteOrderedBeliefGrid}
    {discount : ℚ} {survival₀ survival₁ gap cost : grid.Belief → ℚ}
    (kernel : FiniteTransitionKernel grid)
    {cutoff₀ cutoff₁ : grid.Belief}
    (hdiscount : 0 ≤ discount)
    (hsurvival : ∀ belief, survival₀ belief ≤ survival₁ belief)
    (hgap : ∀ belief, 0 ≤ gap belief)
    (hcutoff₀ :
      oneShotCostCoveringSet discount survival₀ kernel gap cost =
        Set.Ici cutoff₀)
    (hcutoff₁ :
      oneShotCostCoveringSet discount survival₁ kernel gap cost =
        Set.Ici cutoff₁) :
    cutoff₁ ≤ cutoff₀ :=
  cutoff_le_of_Ici_subset hcutoff₁ hcutoff₀
    (oneShotCostCoveringSet_mono_survival kernel hdiscount hsurvival hgap)

/-- Higher admission probability weakly lowers the one-shot cutoff. -/
theorem admissionProbability_cutoff_antitone
    {grid : FiniteOrderedBeliefGrid}
    {discount : ℚ} {admission₀ admission₁ gap cost : grid.Belief → ℚ}
    (kernel : FiniteTransitionKernel grid)
    {cutoff₀ cutoff₁ : grid.Belief}
    (hdiscount : 0 ≤ discount)
    (hadmission : ∀ belief, admission₀ belief ≤ admission₁ belief)
    (hgap : ∀ belief, 0 ≤ gap belief)
    (hcutoff₀ :
      oneShotCostCoveringSet discount admission₀ kernel gap cost =
        Set.Ici cutoff₀)
    (hcutoff₁ :
      oneShotCostCoveringSet discount admission₁ kernel gap cost =
        Set.Ici cutoff₁) :
    cutoff₁ ≤ cutoff₀ :=
  cutoff_le_of_Ici_subset hcutoff₁ hcutoff₀
    (oneShotCostCoveringSet_mono_admissionProbability kernel hdiscount
      hadmission hgap)

/-- A pointwise frontier increase weakly raises the fixed-candidate cutoff. -/
theorem frontier_cutoff_mono
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    {discount : ℚ} {success cost : grid.Belief → ℚ}
    (kernel : FiniteTransitionKernel grid)
    (candidateValue : Project → grid.Belief → ℚ)
    (frontier : LibraryState → grid.Belief → ℚ)
    {oldState newState : LibraryState}
    (himproves : FrontierImproves frontier oldState newState)
    (project : Project)
    {oldCutoff newCutoff : grid.Belief}
    (hdiscount : 0 ≤ discount)
    (hsuccess : ∀ belief, 0 ≤ success belief)
    (holdCutoff :
      oneShotCostCoveringSet discount success kernel
          (certifiedGap candidateValue frontier project oldState) cost =
        Set.Ici oldCutoff)
    (hnewCutoff :
      oneShotCostCoveringSet discount success kernel
          (certifiedGap candidateValue frontier project newState) cost =
        Set.Ici newCutoff) :
    oldCutoff ≤ newCutoff :=
  cutoff_le_of_Ici_subset holdCutoff hnewCutoff
    (oneShotCostCoveringSet_antitone_frontier kernel candidateValue frontier
      himproves project hdiscount hsuccess)

namespace SingleGapCounterexamples

open StrategyInnovation.Fixtures.SingleGapGeometry

abbrev grid : FiniteOrderedBeliefGrid where
  Belief := Fin 3
  beliefFintype := inferInstance
  beliefLinearOrder := inferInstance
  beliefNonempty := inferInstance

/-- The exact row-stochastic kernel found by the Julia search. -/
def destructiveTransitionKernel : FiniteTransitionKernel grid where
  weight := destructiveKernel
  nonnegative := by
    intro initial future
    fin_cases initial <;> fin_cases future <;>
      norm_num [destructiveKernel]
  rowSum := by
    intro initial
    fin_cases initial <;>
      simp [destructiveKernel, Fin.sum_univ_three]

/-- Julia's expected vector `(1,0,1)` is reproduced by the exact Lean sum. -/
theorem destructiveKernel_expectedGap :
    expectedGap destructiveTransitionKernel peakedGap =
      disconnectedPotential := by
  funext initial
  fin_cases initial <;>
    simp [expectedGap, destructiveTransitionKernel, destructiveKernel,
      peakedGap, disconnectedPotential, Fin.sum_univ_three]

/-- The exported gap is nonnegative and genuinely single-peaked at the middle
grid point. -/
theorem peakedGap_nonnegative_singlePeaked :
    IsNonnegativeSinglePeaked peakedGap := by
  constructor
  · intro belief
    fin_cases belief <;> norm_num [peakedGap]
  · refine ⟨(1 : Fin 3), ?_, ?_⟩
    · intro left hleft right hright hle
      fin_cases left
      all_goals fin_cases right
      all_goals simp_all [peakedGap]
    · intro left hleft right hright hle
      fin_cases left
      all_goals fin_cases right
      all_goals simp_all [peakedGap]

/-- Despite a nonnegative single-peaked input gap, the kernel produces a
non-quasi-concave potential and hence a disconnected upper level set. -/
theorem singlePeakedGap_disconnectedPotential :
    IsNonnegativeSinglePeaked peakedGap ∧
      ¬ IsQuasiConcaveSequence
        (expectedGap destructiveTransitionKernel peakedGap) ∧
      ¬ HasConnectedUpperLevelSets
        (expectedGap destructiveTransitionKernel peakedGap) := by
  refine ⟨peakedGap_nonnegative_singlePeaked, ?_, ?_⟩
  · rw [destructiveKernel_expectedGap]
    intro hquasi
    have hmiddle := hquasi (left := (0 : Fin 3)) (middle := (1 : Fin 3))
      (right := (2 : Fin 3)) (by decide) (by decide)
    have himpossible : ¬ (1 : ℚ) ≤ 0 := by norm_num
    apply himpossible
    simpa [disconnectedPotential] using hmiddle
  · rw [destructiveKernel_expectedGap]
    intro hlevels
    have hconnected := hlevels 1
    have hmiddle := hconnected.out (x := (0 : Fin 3)) (y := (2 : Fin 3))
      (show 1 ≤ disconnectedPotential (0 : Fin 3) by
        simp [disconnectedPotential])
      (show 1 ≤ disconnectedPotential (2 : Fin 3) by
        simp [disconnectedPotential])
      (show (1 : Fin 3) ∈ Set.Icc (0 : Fin 3) (2 : Fin 3) by decide)
    norm_num [disconnectedPotential] at hmiddle

/-- The destructive kernel lies outside the theorem: it is not first-order
stochastically monotone. -/
theorem destructiveKernel_not_stochasticallyMonotone :
    ¬ IsStochasticallyMonotone destructiveTransitionKernel := by
  intro hstochastic
  let increasingIndex : Fin 3 → ℚ := fun belief => belief.val
  have hincreasing : Monotone increasingIndex := by
    intro left right hle
    change (left.val : ℚ) ≤ right.val
    exact_mod_cast hle
  have hbad := hstochastic increasingIndex hincreasing
    (show (0 : Fin 3) ≤ (1 : Fin 3) by norm_num)
  simp [expectedGap, destructiveTransitionKernel, destructiveKernel,
    increasingIndex, Fin.sum_univ_three] at hbad
  norm_num at hbad

/-- An increasing nonnegative gap used to isolate failure of stochastic
monotonicity, rather than failure of the gap assumption. -/
def increasingIndexGap (belief : Fin 3) : ℚ := belief.val

/--
With every other upper-threshold assumption satisfied, the nonmonotone kernel
maps the increasing gap `(0,1,2)` to `(1,0,1)`. Constant unit cost is
antitone, yet the resulting one-shot cost-covering set contains the two
endpoints and excludes the middle; it is neither upper nor order-connected.
-/
theorem nonmonotoneKernel_disconnectedCostCoveringSet :
    (∀ belief, 0 ≤ increasingIndexGap belief) ∧
      Monotone increasingIndexGap ∧
      ¬ IsStochasticallyMonotone destructiveTransitionKernel ∧
      Antitone (fun _ : Fin 3 => (1 : ℚ)) ∧
      ¬ IsUpperSet
        (oneShotCostCoveringSet 1 (fun _ => 1)
          destructiveTransitionKernel increasingIndexGap (fun _ => 1)) ∧
      ¬ Set.OrdConnected
        (oneShotCostCoveringSet 1 (fun _ => 1)
          destructiveTransitionKernel increasingIndexGap (fun _ => 1)) := by
  have hleft :
      (0 : Fin 3) ∈
        oneShotCostCoveringSet 1 (fun _ => 1)
          destructiveTransitionKernel increasingIndexGap (fun _ => 1) := by
    simp [oneShotCostCoveringSet, grossCoverageValue, expectedGap,
      destructiveTransitionKernel, destructiveKernel, increasingIndexGap,
      Fin.sum_univ_three]
  have hright :
      (2 : Fin 3) ∈
        oneShotCostCoveringSet 1 (fun _ => 1)
          destructiveTransitionKernel increasingIndexGap (fun _ => 1) := by
    simp [oneShotCostCoveringSet, grossCoverageValue, expectedGap,
      destructiveTransitionKernel, destructiveKernel, increasingIndexGap,
      Fin.sum_univ_three]
  have hmiddle :
      (1 : Fin 3) ∉
        oneShotCostCoveringSet 1 (fun _ => 1)
          destructiveTransitionKernel increasingIndexGap (fun _ => 1) := by
    simp [oneShotCostCoveringSet, grossCoverageValue, expectedGap,
      destructiveTransitionKernel, destructiveKernel, increasingIndexGap,
      Fin.sum_univ_three]
  refine ⟨?_, ?_, destructiveKernel_not_stochasticallyMonotone, ?_, ?_, ?_⟩
  · intro belief
    change (0 : ℚ) ≤ belief.val
    exact_mod_cast Nat.zero_le belief.val
  · intro left right hle
    change (left.val : ℚ) ≤ right.val
    exact_mod_cast hle
  · intro left right hle
    rfl
  · intro hupper
    exact hmiddle (hupper (show (0 : Fin 3) ≤ (1 : Fin 3) by decide) hleft)
  · intro hconnected
    exact hmiddle
      (hconnected.out hleft hright
        (show (1 : Fin 3) ∈ Set.Icc (0 : Fin 3) 2 by decide))

/-- Identity transition used to isolate the effect of nonmonotone research
cost in the second Julia witness. -/
def identityTransitionKernel : FiniteTransitionKernel grid where
  weight := fun initial future => if initial = future then 1 else 0
  nonnegative := by
    intro initial future
    split_ifs <;> norm_num
  rowSum := by
    intro initial
    simp

/-- The identity transition returns every exact gap table unchanged. -/
theorem identityTransitionKernel_expectedGap (gap : Fin 3 → ℚ) :
    expectedGap identityTransitionKernel gap = gap := by
  funext initial
  simp [expectedGap, identityTransitionKernel]

/-- Even an increasing potential can have a disconnected one-shot
cost-covering set when cost is unrestricted. -/
theorem nonAntitoneCost_disconnectedCostCoveringSet :
    Monotone increasingPotential ∧
      ¬ Antitone disconnectedCost ∧
      ¬ Set.OrdConnected
        (oneShotCostCoveringSet 1 (fun _ => 1) identityTransitionKernel
          increasingPotential disconnectedCost) := by
  constructor
  · decide
  constructor
  · intro hcost
    have hbad := hcost (show (0 : Fin 3) ≤ (1 : Fin 3) by norm_num)
    norm_num [disconnectedCost] at hbad
  · intro hconnected
    have hgross :
        grossCoverageValue 1 (fun _ => 1) identityTransitionKernel
            increasingPotential = increasingPotential := by
      funext belief
      simp [grossCoverageValue,
        congrFun (identityTransitionKernel_expectedGap increasingPotential)
          belief]
    have hmiddle := hconnected.out (x := (0 : Fin 3)) (y := (2 : Fin 3))
      (show (0 : Fin 3) ∈ oneShotCostCoveringSet 1 (fun _ => 1)
          identityTransitionKernel increasingPotential disconnectedCost by
        change disconnectedCost (0 : Fin 3) ≤
          grossCoverageValue 1 (fun _ => 1) identityTransitionKernel
            increasingPotential (0 : Fin 3)
        rw [hgross]
        simp [disconnectedCost, increasingPotential])
      (show (2 : Fin 3) ∈ oneShotCostCoveringSet 1 (fun _ => 1)
          identityTransitionKernel increasingPotential disconnectedCost by
        change disconnectedCost (2 : Fin 3) ≤
          grossCoverageValue 1 (fun _ => 1) identityTransitionKernel
            increasingPotential (2 : Fin 3)
        rw [hgross]
        simp [disconnectedCost, increasingPotential])
      (show (1 : Fin 3) ∈ Set.Icc (0 : Fin 3) (2 : Fin 3) by decide)
    change disconnectedCost (1 : Fin 3) ≤
      grossCoverageValue 1 (fun _ => 1) identityTransitionKernel
        increasingPotential (1 : Fin 3) at hmiddle
    rw [hgross] at hmiddle
    norm_num [disconnectedCost, increasingPotential] at hmiddle

/-- Compatibility alias for the pre-revision counterexample name. -/
theorem nonAntitoneCost_disconnectedResearchRegion :
    Monotone increasingPotential ∧
      ¬ Antitone disconnectedCost ∧
      ¬ Set.OrdConnected
        (singleGapResearchRegion 1 (fun _ => 1) identityTransitionKernel
          increasingPotential disconnectedCost) :=
  nonAntitoneCost_disconnectedCostCoveringSet

end SingleGapCounterexamples

end Coverage

end StrategyInnovation
