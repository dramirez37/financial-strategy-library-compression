import Mathlib.Tactic

/-!
# Coverage potential on a finite ordered belief grid

This file formalizes a one-shot project's gross operational coverage value.
The project produces one fixed candidate.  At each date before a finite
horizon, the candidate contributes its certified positive gap over the
existing frontier if it survives.  Exact time-specific occupation weights
describe which future beliefs are reached from the initial belief.

The coverage potential is the finite belief sum of the certified gap against
discounted, survival-adjusted occupation weights.  A finite rearrangement
proves that this representation is exactly the declared one-shot gross
operational research value.  No path measure, infinite series, or
measure-theoretic dependency is used.
-/

namespace StrategyInnovation

namespace Coverage

universe u v w

/-- A nonempty finite linearly ordered belief grid. -/
structure FiniteOrderedBeliefGrid where
  Belief : Type u
  [beliefFintype : Fintype Belief]
  [beliefLinearOrder : LinearOrder Belief]
  [beliefNonempty : Nonempty Belief]

instance (grid : FiniteOrderedBeliefGrid) : Fintype grid.Belief :=
  grid.beliefFintype

instance (grid : FiniteOrderedBeliefGrid) : LinearOrder grid.Belief :=
  grid.beliefLinearOrder

instance (grid : FiniteOrderedBeliefGrid) : Nonempty grid.Belief :=
  grid.beliefNonempty

/--
Exact time-specific occupation weights.  `weight t initial future` is the
date-`t` occupation of `future` from `initial`.  The weights need only be
nonnegative; normalization is stated separately so the same interface also
covers subprobability and exposure weights.
-/
structure OccupationWeights (grid : FiniteOrderedBeliefGrid) where
  weight : Nat → grid.Belief → grid.Belief → ℚ
  nonnegative : ∀ time initial future, 0 ≤ weight time initial future

/-- Occupation weights are probability weights at every date and initial belief. -/
def IsProbabilityOccupation {grid : FiniteOrderedBeliefGrid}
    (occupation : OccupationWeights grid) : Prop :=
  ∀ time initial,
    ∑ future : grid.Belief, occupation.weight time initial future = 1

/--
The candidate's certified nonnegative operational gap over an existing
frontier.  The candidate value is fixed across library states; only the
existing frontier depends on the state.
-/
def certifiedGap {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (candidateValue : Project → grid.Belief → ℚ)
    (frontier : LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (belief : grid.Belief) : ℚ :=
  max (candidateValue project belief - frontier state belief) 0

/-- Every certified gap is nonnegative. -/
theorem certifiedGap_nonnegative {grid : FiniteOrderedBeliefGrid}
    {Project : Type v} {LibraryState : Type w}
    (candidateValue : Project → grid.Belief → ℚ)
    (frontier : LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (belief : grid.Belief) :
    0 ≤ certifiedGap candidateValue frontier project state belief := by
  exact le_max_right _ _

/-- Pointwise improvement of an existing operational frontier. -/
def FrontierImproves {grid : FiniteOrderedBeliefGrid} {LibraryState : Type w}
    (frontier : LibraryState → grid.Belief → ℚ)
    (oldState newState : LibraryState) : Prop :=
  ∀ belief, frontier oldState belief ≤ frontier newState belief

/-- A fixed candidate's certified gap is antitone in the existing frontier. -/
theorem certifiedGap_antitone_of_frontier_improves
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (candidateValue : Project → grid.Belief → ℚ)
    (frontier : LibraryState → grid.Belief → ℚ)
    {oldState newState : LibraryState}
    (himproves : FrontierImproves frontier oldState newState)
    (project : Project) (belief : grid.Belief) :
    certifiedGap candidateValue frontier project newState belief ≤
      certifiedGap candidateValue frontier project oldState belief := by
  unfold certifiedGap
  apply max_le_max_right
  exact sub_le_sub_left (himproves belief) _

/--
The exact discounted, survival-adjusted occupation weight of one future
belief.  Date `t` receives the factor `discount ^ t * survival ^ t`.
-/
def discountedOccupationWeight {grid : FiniteOrderedBeliefGrid}
    (horizon : Nat) (discount survival : ℚ)
    (occupation : OccupationWeights grid)
    (initial future : grid.Belief) : ℚ :=
  ∑ time ∈ Finset.range horizon,
    discount ^ time * survival ^ time *
      occupation.weight time initial future

/--
Coverage potential is the exact finite sum of certified gaps weighted by
discounted future-belief occupation.
-/
def coveragePotential {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (horizon : Nat) (discount survival : ℚ)
    (occupation : OccupationWeights grid)
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (initial : grid.Belief) : ℚ :=
  ∑ future : grid.Belief,
    discountedOccupationWeight horizon discount survival occupation
        initial future *
      gap project state future

/--
The declared one-shot gross operational research value, written as the
date-by-date exact expectation of the surviving candidate gap.
-/
def oneShotGrossOperationalResearchValue
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (horizon : Nat) (discount survival : ℚ)
    (occupation : OccupationWeights grid)
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (initial : grid.Belief) : ℚ :=
  ∑ time ∈ Finset.range horizon,
    ∑ future : grid.Belief,
      discount ^ time * survival ^ time *
          occupation.weight time initial future *
        gap project state future

/--
Coverage-potential representation: the weighted belief sum is exactly the
one-shot gross operational research value.
-/
theorem coveragePotential_eq_oneShotGrossOperationalResearchValue
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (horizon : Nat) (discount survival : ℚ)
    (occupation : OccupationWeights grid)
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (initial : grid.Belief) :
    coveragePotential horizon discount survival occupation gap project state
        initial =
      oneShotGrossOperationalResearchValue horizon discount survival
        occupation gap project state initial := by
  classical
  unfold coveragePotential discountedOccupationWeight
    oneShotGrossOperationalResearchValue
  simp only [Finset.sum_mul]
  rw [Finset.sum_comm]

/-- Discounted occupation weights are nonnegative. -/
theorem discountedOccupationWeight_nonnegative
    {grid : FiniteOrderedBeliefGrid}
    (horizon : Nat) {discount survival : ℚ}
    (hdiscount : 0 ≤ discount) (hsurvival : 0 ≤ survival)
    (occupation : OccupationWeights grid)
    (initial future : grid.Belief) :
    0 ≤ discountedOccupationWeight horizon discount survival occupation
      initial future := by
  classical
  unfold discountedOccupationWeight
  apply Finset.sum_nonneg
  intro time htime
  exact mul_nonneg
    (mul_nonneg (pow_nonneg hdiscount _) (pow_nonneg hsurvival _))
    (occupation.nonnegative time initial future)

/-- Coverage potential is nonnegative for a nonnegative gap. -/
theorem coveragePotential_nonnegative
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (horizon : Nat) {discount survival : ℚ}
    (hdiscount : 0 ≤ discount) (hsurvival : 0 ≤ survival)
    (occupation : OccupationWeights grid)
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (initial : grid.Belief)
    (hgap : ∀ belief, 0 ≤ gap project state belief) :
    0 ≤ coveragePotential horizon discount survival occupation gap project
      state initial := by
  classical
  unfold coveragePotential
  apply Finset.sum_nonneg
  intro future hfuture
  exact mul_nonneg
    (discountedOccupationWeight_nonnegative horizon hdiscount hsurvival
      occupation initial future)
    (hgap future)

/-- Discounted occupation is monotone in a nonnegative discount factor. -/
theorem discountedOccupationWeight_mono_discount
    {grid : FiniteOrderedBeliefGrid}
    (horizon : Nat) {leftDiscount rightDiscount survival : ℚ}
    (hleftDiscount : 0 ≤ leftDiscount)
    (hdiscount : leftDiscount ≤ rightDiscount)
    (hsurvival : 0 ≤ survival)
    (occupation : OccupationWeights grid)
    (initial future : grid.Belief) :
    discountedOccupationWeight horizon leftDiscount survival occupation
        initial future ≤
      discountedOccupationWeight horizon rightDiscount survival occupation
        initial future := by
  classical
  unfold discountedOccupationWeight
  apply Finset.sum_le_sum
  intro time htime
  apply mul_le_mul_of_nonneg_right
  · apply mul_le_mul_of_nonneg_right
    · exact pow_le_pow_left₀ hleftDiscount hdiscount time
    · exact pow_nonneg hsurvival time
  · exact occupation.nonnegative time initial future

/-- Coverage potential is monotone in the discount factor. -/
theorem coveragePotential_mono_discount
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (horizon : Nat) {leftDiscount rightDiscount survival : ℚ}
    (hleftDiscount : 0 ≤ leftDiscount)
    (hdiscount : leftDiscount ≤ rightDiscount)
    (hsurvival : 0 ≤ survival)
    (occupation : OccupationWeights grid)
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (initial : grid.Belief)
    (hgap : ∀ belief, 0 ≤ gap project state belief) :
    coveragePotential horizon leftDiscount survival occupation gap project
        state initial ≤
      coveragePotential horizon rightDiscount survival occupation gap project
        state initial := by
  classical
  unfold coveragePotential
  apply Finset.sum_le_sum
  intro future hfuture
  apply mul_le_mul_of_nonneg_right
  · exact discountedOccupationWeight_mono_discount horizon hleftDiscount
      hdiscount hsurvival occupation initial future
  · exact hgap future

/-- Discounted occupation is monotone in candidate survival probability. -/
theorem discountedOccupationWeight_mono_survival
    {grid : FiniteOrderedBeliefGrid}
    (horizon : Nat) {discount leftSurvival rightSurvival : ℚ}
    (hdiscount : 0 ≤ discount)
    (hleftSurvival : 0 ≤ leftSurvival)
    (hsurvival : leftSurvival ≤ rightSurvival)
    (occupation : OccupationWeights grid)
    (initial future : grid.Belief) :
    discountedOccupationWeight horizon discount leftSurvival occupation
        initial future ≤
      discountedOccupationWeight horizon discount rightSurvival occupation
        initial future := by
  classical
  unfold discountedOccupationWeight
  apply Finset.sum_le_sum
  intro time htime
  apply mul_le_mul_of_nonneg_right
  · apply mul_le_mul_of_nonneg_left
    · exact pow_le_pow_left₀ hleftSurvival hsurvival time
    · exact pow_nonneg hdiscount time
  · exact occupation.nonnegative time initial future

/-- Coverage potential is monotone in candidate survival probability. -/
theorem coveragePotential_mono_survival
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (horizon : Nat) {discount leftSurvival rightSurvival : ℚ}
    (hdiscount : 0 ≤ discount)
    (hleftSurvival : 0 ≤ leftSurvival)
    (hsurvival : leftSurvival ≤ rightSurvival)
    (occupation : OccupationWeights grid)
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (initial : grid.Belief)
    (hgap : ∀ belief, 0 ≤ gap project state belief) :
    coveragePotential horizon discount leftSurvival occupation gap project
        state initial ≤
      coveragePotential horizon discount rightSurvival occupation gap project
        state initial := by
  classical
  unfold coveragePotential
  apply Finset.sum_le_sum
  intro future hfuture
  apply mul_le_mul_of_nonneg_right
  · exact discountedOccupationWeight_mono_survival horizon hdiscount
      hleftSurvival hsurvival occupation initial future
  · exact hgap future

/-- Discounted occupation is monotone in pointwise transition occupation. -/
theorem discountedOccupationWeight_mono_occupation
    {grid : FiniteOrderedBeliefGrid}
    (horizon : Nat) {discount survival : ℚ}
    (hdiscount : 0 ≤ discount) (hsurvival : 0 ≤ survival)
    (leftOccupation rightOccupation : OccupationWeights grid)
    (hoccupation : ∀ time initial future,
      leftOccupation.weight time initial future ≤
        rightOccupation.weight time initial future)
    (initial future : grid.Belief) :
    discountedOccupationWeight horizon discount survival leftOccupation
        initial future ≤
      discountedOccupationWeight horizon discount survival rightOccupation
        initial future := by
  classical
  unfold discountedOccupationWeight
  apply Finset.sum_le_sum
  intro time htime
  apply mul_le_mul_of_nonneg_left
  · exact hoccupation time initial future
  · exact mul_nonneg (pow_nonneg hdiscount time)
      (pow_nonneg hsurvival time)

/-- Coverage potential is monotone in pointwise transition occupation. -/
theorem coveragePotential_mono_occupation
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (horizon : Nat) {discount survival : ℚ}
    (hdiscount : 0 ≤ discount) (hsurvival : 0 ≤ survival)
    (leftOccupation rightOccupation : OccupationWeights grid)
    (hoccupation : ∀ time initial future,
      leftOccupation.weight time initial future ≤
        rightOccupation.weight time initial future)
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (initial : grid.Belief)
    (hgap : ∀ belief, 0 ≤ gap project state belief) :
    coveragePotential horizon discount survival leftOccupation gap project
        state initial ≤
      coveragePotential horizon discount survival rightOccupation gap project
        state initial := by
  classical
  unfold coveragePotential
  apply Finset.sum_le_sum
  intro future hfuture
  apply mul_le_mul_of_nonneg_right
  · exact discountedOccupationWeight_mono_occupation horizon hdiscount
      hsurvival leftOccupation rightOccupation hoccupation initial future
  · exact hgap future

/-- Coverage potential is monotone in its pointwise gap table. -/
theorem coveragePotential_mono_gap
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (horizon : Nat) {discount survival : ℚ}
    (hdiscount : 0 ≤ discount) (hsurvival : 0 ≤ survival)
    (occupation : OccupationWeights grid)
    (leftGap rightGap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (leftState rightState : LibraryState)
    (initial : grid.Belief)
    (hgap : ∀ belief,
      leftGap project leftState belief ≤ rightGap project rightState belief) :
    coveragePotential horizon discount survival occupation leftGap project
        leftState initial ≤
      coveragePotential horizon discount survival occupation rightGap project
        rightState initial := by
  classical
  unfold coveragePotential
  apply Finset.sum_le_sum
  intro future hfuture
  apply mul_le_mul_of_nonneg_left
  · exact hgap future
  · exact discountedOccupationWeight_nonnegative horizon hdiscount hsurvival
      occupation initial future

/-- Exact support reachability under the time-indexed occupation weights. -/
def Reachable {grid : FiniteOrderedBeliefGrid}
    (horizon : Nat) (occupation : OccupationWeights grid)
    (initial future : grid.Belief) : Prop :=
  ∃ time, time < horizon ∧ occupation.weight time initial future ≠ 0

/--
No-value condition: zero certified gap on every occupation-reachable belief
implies zero coverage potential.
-/
theorem coveragePotential_eq_zero_of_gap_eq_zero_on_reachable
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (horizon : Nat) (discount survival : ℚ)
    (occupation : OccupationWeights grid)
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (initial : grid.Belief)
    (hgap : ∀ future,
      Reachable horizon occupation initial future → gap project state future = 0) :
    coveragePotential horizon discount survival occupation gap project state
      initial = 0 := by
  classical
  unfold coveragePotential
  apply Finset.sum_eq_zero
  intro future hfuture
  by_cases hreachable : Reachable horizon occupation initial future
  · rw [hgap future hreachable, mul_zero]
  · have hweight :
        discountedOccupationWeight horizon discount survival occupation
            initial future = 0 := by
      unfold discountedOccupationWeight
      apply Finset.sum_eq_zero
      intro time htime
      have hoccupation : occupation.weight time initial future = 0 := by
        by_contra hne
        exact hreachable ⟨time, Finset.mem_range.mp htime, hne⟩
      rw [hoccupation, mul_zero]
    rw [hweight, zero_mul]

/-- The finite advantage region where the fixed project/state gap is strict. -/
def advantageRegion {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) : Finset grid.Belief :=
  Finset.univ.filter fun belief => 0 < gap project state belief

@[simp]
theorem mem_advantageRegion_iff {grid : FiniteOrderedBeliefGrid}
    {Project : Type v} {LibraryState : Type w}
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (belief : grid.Belief) :
    belief ∈ advantageRegion gap project state ↔
      0 < gap project state belief := by
  simp [advantageRegion]

/-- Discounted occupation of a finite belief region. -/
def discountedRegionOccupation {grid : FiniteOrderedBeliefGrid}
    (horizon : Nat) (discount survival : ℚ)
    (occupation : OccupationWeights grid) (initial : grid.Belief)
    (region : Finset grid.Belief) : ℚ :=
  ∑ future ∈ region,
    discountedOccupationWeight horizon discount survival occupation
      initial future

/-- Total discounted occupation of the belief grid. -/
def totalDiscountedOccupation {grid : FiniteOrderedBeliefGrid}
    (horizon : Nat) (discount survival : ℚ)
    (occupation : OccupationWeights grid) (initial : grid.Belief) : ℚ :=
  ∑ future : grid.Belief,
    discountedOccupationWeight horizon discount survival occupation
      initial future

/-- A region's discounted occupation is bounded by total occupation. -/
theorem discountedRegionOccupation_le_total
    {grid : FiniteOrderedBeliefGrid}
    (horizon : Nat) {discount survival : ℚ}
    (hdiscount : 0 ≤ discount) (hsurvival : 0 ≤ survival)
    (occupation : OccupationWeights grid) (initial : grid.Belief)
    (region : Finset grid.Belief) :
    discountedRegionOccupation horizon discount survival occupation initial
        region ≤
      totalDiscountedOccupation horizon discount survival occupation
        initial := by
  classical
  unfold discountedRegionOccupation totalDiscountedOccupation
  apply Finset.sum_le_sum_of_subset_of_nonneg (Finset.subset_univ region)
  intro future hfuture houtside
  exact discountedOccupationWeight_nonnegative horizon hdiscount hsurvival
    occupation initial future

/--
For normalized date-specific belief probabilities, total discounted occupation
is the exact finite geometric sum of discount times survival.
-/
theorem totalDiscountedOccupation_eq_geometricSum
    {grid : FiniteOrderedBeliefGrid}
    (horizon : Nat) (discount survival : ℚ)
    (occupation : OccupationWeights grid)
    (hprobability : IsProbabilityOccupation occupation)
    (initial : grid.Belief) :
    totalDiscountedOccupation horizon discount survival occupation initial =
      ∑ time ∈ Finset.range horizon, discount ^ time * survival ^ time := by
  classical
  unfold totalDiscountedOccupation discountedOccupationWeight
  rw [Finset.sum_comm]
  apply Finset.sum_congr rfl
  intro time htime
  rw [← Finset.mul_sum]
  rw [hprobability time initial]
  ring

/-- A supplied regional gap floor yields a coverage lower bound. -/
theorem minGap_mul_regionOccupation_le_coveragePotential
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (horizon : Nat) {discount survival minGap : ℚ}
    (hdiscount : 0 ≤ discount) (hsurvival : 0 ≤ survival)
    (occupation : OccupationWeights grid)
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (initial : grid.Belief)
    (region : Finset grid.Belief)
    (hgapNonnegative : ∀ belief, 0 ≤ gap project state belief)
    (hgapFloor : ∀ belief ∈ region, minGap ≤ gap project state belief) :
    minGap * discountedRegionOccupation horizon discount survival occupation
        initial region ≤
      coveragePotential horizon discount survival occupation gap project state
        initial := by
  classical
  let weight : grid.Belief → ℚ := fun belief =>
    discountedOccupationWeight horizon discount survival occupation initial
      belief
  calc
    minGap * discountedRegionOccupation horizon discount survival occupation
        initial region = ∑ belief ∈ region, weight belief * minGap := by
          simp [discountedRegionOccupation, weight, Finset.mul_sum, mul_comm]
    _ ≤ ∑ belief ∈ region, weight belief * gap project state belief := by
      apply Finset.sum_le_sum
      intro belief hbelief
      exact mul_le_mul_of_nonneg_left (hgapFloor belief hbelief)
        (discountedOccupationWeight_nonnegative horizon hdiscount hsurvival
          occupation initial belief)
    _ ≤ ∑ belief : grid.Belief,
        weight belief * gap project state belief := by
      apply Finset.sum_le_sum_of_subset_of_nonneg
        (Finset.subset_univ region)
      intro belief hbelief houtside
      exact mul_nonneg
        (discountedOccupationWeight_nonnegative horizon hdiscount hsurvival
          occupation initial belief)
        (hgapNonnegative belief)
    _ = coveragePotential horizon discount survival occupation gap project
        state initial := by
      rfl

/-- A supplied pointwise gap ceiling yields a total-occupation upper bound. -/
theorem coveragePotential_le_maxGap_mul_totalOccupation
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (horizon : Nat) {discount survival maxGap : ℚ}
    (hdiscount : 0 ≤ discount) (hsurvival : 0 ≤ survival)
    (occupation : OccupationWeights grid)
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (initial : grid.Belief)
    (hgapCeiling : ∀ belief, gap project state belief ≤ maxGap) :
    coveragePotential horizon discount survival occupation gap project state
        initial ≤
      maxGap * totalDiscountedOccupation horizon discount survival occupation
        initial := by
  classical
  unfold coveragePotential totalDiscountedOccupation
  calc
    ∑ belief : grid.Belief,
        discountedOccupationWeight horizon discount survival occupation
            initial belief *
          gap project state belief ≤
      ∑ belief : grid.Belief,
        discountedOccupationWeight horizon discount survival occupation
            initial belief *
          maxGap := by
      apply Finset.sum_le_sum
      intro belief hbelief
      exact mul_le_mul_of_nonneg_left (hgapCeiling belief)
        (discountedOccupationWeight_nonnegative horizon hdiscount hsurvival
          occupation initial belief)
    _ = maxGap * ∑ belief : grid.Belief,
        discountedOccupationWeight horizon discount survival occupation
          initial belief := by
      simp [Finset.mul_sum, mul_comm]

/--
If the gap is supported on a region, its maximum times that region's
discounted occupation is an upper bound.
-/
theorem coveragePotential_le_maxGap_mul_regionOccupation
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (horizon : Nat) {discount survival maxGap : ℚ}
    (hdiscount : 0 ≤ discount) (hsurvival : 0 ≤ survival)
    (occupation : OccupationWeights grid)
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (initial : grid.Belief)
    (region : Finset grid.Belief)
    (hgapCeiling : ∀ belief ∈ region, gap project state belief ≤ maxGap)
    (hsupport : ∀ belief, belief ∉ region → gap project state belief = 0) :
    coveragePotential horizon discount survival occupation gap project state
        initial ≤
      maxGap * discountedRegionOccupation horizon discount survival occupation
        initial region := by
  classical
  let weight : grid.Belief → ℚ := fun belief =>
    discountedOccupationWeight horizon discount survival occupation initial
      belief
  have hrestrict :
      (∑ belief ∈ region, weight belief * gap project state belief) =
        ∑ belief : grid.Belief,
          weight belief * gap project state belief := by
    apply Finset.sum_subset (Finset.subset_univ region)
    intro belief hbelief houtside
    rw [hsupport belief houtside, mul_zero]
  calc
    coveragePotential horizon discount survival occupation gap project state
        initial = ∑ belief ∈ region,
          weight belief * gap project state belief := by
      exact hrestrict.symm
    _ ≤ ∑ belief ∈ region, weight belief * maxGap := by
      apply Finset.sum_le_sum
      intro belief hbelief
      exact mul_le_mul_of_nonneg_left (hgapCeiling belief hbelief)
        (discountedOccupationWeight_nonnegative horizon hdiscount hsurvival
          occupation initial belief)
    _ = maxGap * discountedRegionOccupation horizon discount survival
        occupation initial region := by
      simp [discountedRegionOccupation, weight, Finset.mul_sum, mul_comm]

/-- The exact maximum certified gap on the finite belief grid. -/
def maximumGap {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) : ℚ :=
  Finset.univ.sup' Finset.univ_nonempty (gap project state)

/-- Every pointwise gap is bounded by the finite-grid maximum gap. -/
theorem gap_le_maximumGap {grid : FiniteOrderedBeliefGrid}
    {Project : Type v} {LibraryState : Type w}
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (belief : grid.Belief) :
    gap project state belief ≤ maximumGap gap project state := by
  exact Finset.le_sup' (gap project state) (Finset.mem_univ belief)

/--
For a nonnegative gap, the actual global maximum times discounted occupation
of the strict advantage region is an upper bound.
-/
theorem coveragePotential_le_maximumGap_mul_advantageRegionOccupation
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (horizon : Nat) {discount survival : ℚ}
    (hdiscount : 0 ≤ discount) (hsurvival : 0 ≤ survival)
    (occupation : OccupationWeights grid)
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (initial : grid.Belief)
    (hgap : ∀ belief, 0 ≤ gap project state belief) :
    coveragePotential horizon discount survival occupation gap project state
        initial ≤
      maximumGap gap project state *
        discountedRegionOccupation horizon discount survival occupation
          initial (advantageRegion gap project state) := by
  apply coveragePotential_le_maxGap_mul_regionOccupation horizon hdiscount
    hsurvival occupation gap project state initial
    (advantageRegion gap project state)
  · intro belief hbelief
    exact gap_le_maximumGap gap project state belief
  · intro belief houtside
    have hnotPositive : ¬ 0 < gap project state belief := by
      intro hpositive
      exact houtside
        ((mem_advantageRegion_iff gap project state belief).2 hpositive)
    exact le_antisymm (le_of_not_gt hnotPositive) (hgap belief)

/-- The exact minimum gap on a nonempty finite advantage region. -/
def minimumGapOn {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (region : Finset grid.Belief) (hregion : region.Nonempty)
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) : ℚ :=
  region.inf' hregion (gap project state)

/-- The regional minimum is below every gap in the advantage region. -/
theorem minimumGapOn_le_gap {grid : FiniteOrderedBeliefGrid}
    {Project : Type v} {LibraryState : Type w}
    (region : Finset grid.Belief) (hregion : region.Nonempty)
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (belief : grid.Belief)
    (hbelief : belief ∈ region) :
    minimumGapOn region hregion gap project state ≤ gap project state belief := by
  exact Finset.inf'_le (gap project state) hbelief

/-- A nonnegative gap has a nonnegative minimum on every nonempty region. -/
theorem minimumGapOn_nonnegative {grid : FiniteOrderedBeliefGrid}
    {Project : Type v} {LibraryState : Type w}
    (region : Finset grid.Belief) (hregion : region.Nonempty)
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState)
    (hgap : ∀ belief, 0 ≤ gap project state belief) :
    0 ≤ minimumGapOn region hregion gap project state := by
  unfold minimumGapOn
  exact Finset.le_inf' hregion (gap project state) fun belief hbelief =>
    hgap belief

/-- A nonempty advantage region has a strictly positive minimum gap. -/
theorem minimumGapOn_advantageRegion_positive
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState)
    (hregion : (advantageRegion gap project state).Nonempty) :
    0 < minimumGapOn (advantageRegion gap project state) hregion gap project
      state := by
  unfold minimumGapOn
  exact (Finset.lt_inf'_iff hregion).2 fun belief hbelief =>
    (mem_advantageRegion_iff gap project state belief).1 hbelief

/--
The regional-minimum lower bound, stated using the actual minimum on the
finite advantage region.
-/
theorem minimumGapOn_mul_regionOccupation_le_coveragePotential
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (horizon : Nat) {discount survival : ℚ}
    (hdiscount : 0 ≤ discount) (hsurvival : 0 ≤ survival)
    (occupation : OccupationWeights grid)
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (initial : grid.Belief)
    (region : Finset grid.Belief) (hregion : region.Nonempty)
    (hgap : ∀ belief, 0 ≤ gap project state belief) :
    minimumGapOn region hregion gap project state *
        discountedRegionOccupation horizon discount survival occupation
          initial region ≤
      coveragePotential horizon discount survival occupation gap project state
        initial := by
  apply minGap_mul_regionOccupation_le_coveragePotential horizon hdiscount
    hsurvival occupation gap project state initial region hgap
  intro belief hbelief
  exact minimumGapOn_le_gap region hregion gap project state belief hbelief

/-- The lower bound specialized to the candidate's strict advantage region. -/
theorem advantageRegion_minimumGap_mul_occupation_le_coveragePotential
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (horizon : Nat) {discount survival : ℚ}
    (hdiscount : 0 ≤ discount) (hsurvival : 0 ≤ survival)
    (occupation : OccupationWeights grid)
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (initial : grid.Belief)
    (hregion : (advantageRegion gap project state).Nonempty)
    (hgap : ∀ belief, 0 ≤ gap project state belief) :
    minimumGapOn (advantageRegion gap project state) hregion gap project state *
        discountedRegionOccupation horizon discount survival occupation
          initial (advantageRegion gap project state) ≤
      coveragePotential horizon discount survival occupation gap project state
        initial := by
  exact minimumGapOn_mul_regionOccupation_le_coveragePotential horizon
    hdiscount hsurvival occupation gap project state initial
    (advantageRegion gap project state) hregion hgap

/--
The global maximum-gap upper bound, stated using the actual finite-grid
maximum.
-/
theorem coveragePotential_le_maximumGap_mul_totalOccupation
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w}
    (horizon : Nat) {discount survival : ℚ}
    (hdiscount : 0 ≤ discount) (hsurvival : 0 ≤ survival)
    (occupation : OccupationWeights grid)
    (gap : Project → LibraryState → grid.Belief → ℚ)
    (project : Project) (state : LibraryState) (initial : grid.Belief) :
    coveragePotential horizon discount survival occupation gap project state
        initial ≤
      maximumGap gap project state *
        totalDiscountedOccupation horizon discount survival occupation
          initial := by
  apply coveragePotential_le_maxGap_mul_totalOccupation horizon hdiscount
    hsurvival occupation gap project state initial
  intro belief
  exact gap_le_maximumGap gap project state belief

/--
Finite one-shot coverage model with semantically bounded discount and survival
probabilities and normalized future-belief occupation probabilities.
-/
structure OneShotModel (grid : FiniteOrderedBeliefGrid)
    (Project : Type v) (LibraryState : Type w) where
  horizon : Nat
  discount : ℚ
  discount_nonnegative : 0 ≤ discount
  discount_le_one : discount ≤ 1
  candidateSurvival : Project → ℚ
  candidateSurvival_nonnegative : ∀ project, 0 ≤ candidateSurvival project
  candidateSurvival_le_one : ∀ project, candidateSurvival project ≤ 1
  occupation : OccupationWeights grid
  occupation_is_probability : IsProbabilityOccupation occupation
  candidateValue : Project → grid.Belief → ℚ
  frontier : LibraryState → grid.Belief → ℚ

namespace OneShotModel

/-- The model's expected nonnegative certified gap `gap q K b`. -/
def gap {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w} (model : OneShotModel grid Project LibraryState) :
    Project → LibraryState → grid.Belief → ℚ :=
  certifiedGap model.candidateValue model.frontier

/-- The model's exact coverage potential. -/
def coveragePotential {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w} (model : OneShotModel grid Project LibraryState)
    (project : Project) (state : LibraryState) (initial : grid.Belief) : ℚ :=
  Coverage.coveragePotential model.horizon model.discount
    (model.candidateSurvival project) model.occupation model.gap project state
    initial

/-- The model's date-by-date one-shot gross operational research value. -/
def grossOperationalResearchValue
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w} (model : OneShotModel grid Project LibraryState)
    (project : Project) (state : LibraryState) (initial : grid.Belief) : ℚ :=
  oneShotGrossOperationalResearchValue model.horizon model.discount
    (model.candidateSurvival project) model.occupation model.gap project state
    initial

/-- The declared model gap is certified nonnegative. -/
theorem gap_nonnegative {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w} (model : OneShotModel grid Project LibraryState)
    (project : Project) (state : LibraryState) (belief : grid.Belief) :
    0 ≤ model.gap project state belief := by
  exact certifiedGap_nonnegative model.candidateValue model.frontier project
    state belief

/--
In the declared one-shot model, coverage potential equals gross operational
research value.
-/
theorem coveragePotential_eq_grossOperationalResearchValue
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w} (model : OneShotModel grid Project LibraryState)
    (project : Project) (state : LibraryState) (initial : grid.Belief) :
    model.coveragePotential project state initial =
      model.grossOperationalResearchValue project state initial := by
  exact coveragePotential_eq_oneShotGrossOperationalResearchValue
    model.horizon model.discount (model.candidateSurvival project)
    model.occupation model.gap project state initial

/-- Improving the existing frontier weakly reduces fixed-candidate coverage. -/
theorem coveragePotential_antitone_of_frontier_improves
    {grid : FiniteOrderedBeliefGrid} {Project : Type v}
    {LibraryState : Type w} (model : OneShotModel grid Project LibraryState)
    {oldState newState : LibraryState}
    (himproves : FrontierImproves model.frontier oldState newState)
    (project : Project) (initial : grid.Belief) :
    model.coveragePotential project newState initial ≤
      model.coveragePotential project oldState initial := by
  unfold coveragePotential
  apply StrategyInnovation.Coverage.coveragePotential_mono_gap model.horizon
    model.discount_nonnegative
    (model.candidateSurvival_nonnegative project) model.occupation model.gap
    model.gap project newState oldState initial
  · intro belief
    exact certifiedGap_antitone_of_frontier_improves model.candidateValue
      model.frontier himproves project belief

end OneShotModel

namespace DelayedCoverageExample

/-- A two-point ordered belief grid. -/
abbrev grid : FiniteOrderedBeliefGrid where
  Belief := Fin 2
  beliefFintype := inferInstance
  beliefLinearOrder := inferInstance
  beliefNonempty := inferInstance

/-- Current belief `0` is occupied at date zero; future belief `1` thereafter. -/
def occupationWeight (time : Nat) (_initial future : grid.Belief) : ℚ :=
  if time = 0 then
    if future = 0 then 1 else 0
  else
    if future = 1 then 1 else 0

/-- Exact deterministic occupation weights for the delayed-benefit example. -/
def occupation : OccupationWeights grid where
  weight := occupationWeight
  nonnegative := by
    intro time initial future
    simp only [occupationWeight]
    split_ifs <;> norm_num

/-- The example occupation is a probability distribution at every date. -/
theorem occupation_is_probability : IsProbabilityOccupation occupation := by
  intro time initial
  rw [Fin.sum_univ_two]
  by_cases htime : time = 0
  · subst time
    norm_num [occupation, occupationWeight]
  · norm_num [occupation, occupationWeight, htime]

/-- The candidate ties at belief zero and has gap two at belief one. -/
def candidateValue (_project : Unit) (belief : grid.Belief) : ℚ :=
  if belief = 0 then 0 else 2

/-- The existing frontier is zero at both beliefs. -/
def frontier (_state : Unit) (_belief : grid.Belief) : ℚ := 0

/-- Exact two-period one-shot delayed-coverage model. -/
def model : OneShotModel grid Unit Unit where
  horizon := 2
  discount := 1 / 2
  discount_nonnegative := by norm_num
  discount_le_one := by norm_num
  candidateSurvival := fun _ => 1
  candidateSurvival_nonnegative := by intro project; norm_num
  candidateSurvival_le_one := by intro project; norm_num
  occupation := occupation
  occupation_is_probability := occupation_is_probability
  candidateValue := candidateValue
  frontier := frontier

/--
Zero current gap does not imply zero coverage: the future occupied belief has
gap two, giving exact coverage potential one.
-/
theorem zero_currentGap_positive_coveragePotential :
    model.gap () () (0 : grid.Belief) = 0 ∧
      model.gap () () (1 : grid.Belief) = 2 ∧
      model.coveragePotential () () (0 : grid.Belief) = 1 ∧
      0 < model.coveragePotential () () (0 : grid.Belief) := by
  norm_num [OneShotModel.gap, OneShotModel.coveragePotential, certifiedGap,
    Coverage.coveragePotential, discountedOccupationWeight, model,
    candidateValue, frontier, occupation, occupationWeight]
  constructor
  · rw [Fin.sum_univ_two]
    norm_num [Finset.sum_range_succ]
  · rw [Fin.sum_univ_two]
    norm_num [Finset.sum_range_succ]

end DelayedCoverageExample

end Coverage

end StrategyInnovation
