import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Convex.Function
import Mathlib.Topology.Order.Lattice

/-!
# Finite penalized affine envelopes

This module formalizes the real-price extension of a fixed nonempty finite
library family.  Every library supplies a productive value and a nonnegative
resource burden, hence the affine branch `V_L - λ W_L`.  The envelope retains
all ties and does not impose a library-inclusion order or a tie breaker.
-/

namespace StrategyInnovation

namespace Optimization

open scoped Topology

/-- Data of a fixed nonempty finite penalized optimization problem. -/
structure FinitePenalizedProblem (Library : Type*) where
  feasibleLibraries : Finset Library
  feasibleLibraries_nonempty : feasibleLibraries.Nonempty
  productiveValue : Library → ℝ
  burden : Library → ℝ
  burden_nonnegative :
    ∀ library ∈ feasibleLibraries, 0 ≤ burden library

namespace FinitePenalizedProblem

variable {Library : Type*} (problem : FinitePenalizedProblem Library)

/-- Canonical real-price extension of exact rational value and burden data. -/
noncomputable def ofRational
    (feasibleLibraries : Finset Library)
    (feasibleLibraries_nonempty : feasibleLibraries.Nonempty)
    (productiveValue burden : Library → ℚ)
    (burden_nonnegative :
      ∀ library ∈ feasibleLibraries, 0 ≤ burden library) :
    FinitePenalizedProblem Library where
  feasibleLibraries := feasibleLibraries
  feasibleLibraries_nonempty := feasibleLibraries_nonempty
  productiveValue := fun library => (productiveValue library : ℝ)
  burden := fun library => (burden library : ℝ)
  burden_nonnegative := by
    intro library hlibrary
    exact Rat.cast_nonneg.mpr (burden_nonnegative library hlibrary)

/-- The affine penalized objective `J_L(λ) = V_L - λ W_L`. -/
def branch (library : Library) (price : ℝ) : ℝ :=
  problem.productiveValue library - price * problem.burden library

/-- The rational adapter has exactly the intended cast affine branch. -/
@[simp]
theorem ofRational_branch
    (feasibleLibraries : Finset Library)
    (feasibleLibraries_nonempty : feasibleLibraries.Nonempty)
    (productiveValue burden : Library → ℚ)
    (burden_nonnegative :
      ∀ library ∈ feasibleLibraries, 0 ≤ burden library)
    (library : Library) (price : ℝ) :
    (ofRational feasibleLibraries feasibleLibraries_nonempty productiveValue
        burden burden_nonnegative).branch library price =
      (productiveValue library : ℝ) - price * (burden library : ℝ) :=
  rfl

/-- The maximum penalized value over the fixed nonempty finite family. -/
def envelope (price : ℝ) : ℝ :=
  problem.feasibleLibraries.sup' problem.feasibleLibraries_nonempty
    (fun library => problem.branch library price)

/-- Membership in the complete, tie-retaining optimizer correspondence. -/
def IsOptimizer (price : ℝ) (library : Library) : Prop :=
  library ∈ problem.feasibleLibraries ∧
    problem.branch library price = problem.envelope price

/-- The optimizer correspondence as a set. -/
def optimizerSet (price : ℝ) : Set Library :=
  {library | problem.IsOptimizer price library}

/-- Every feasible branch lies weakly below the finite envelope. -/
theorem branch_le_envelope {library : Library}
    (hlibrary : library ∈ problem.feasibleLibraries) (price : ℝ) :
    problem.branch library price ≤ problem.envelope price := by
  exact Finset.le_sup' (fun candidate => problem.branch candidate price) hlibrary

/-- The finite envelope is attained by a feasible library at every price. -/
theorem exists_optimizer (price : ℝ) :
    ∃ library : Library, problem.IsOptimizer price library := by
  obtain ⟨library, hlibrary, hmaximum⟩ :=
    Finset.exists_mem_eq_sup' problem.feasibleLibraries_nonempty
      (fun candidate => problem.branch candidate price)
  exact ⟨library, hlibrary, hmaximum.symm⟩

/-- The optimizer correspondence is nonempty at every price. -/
theorem optimizerSet_nonempty (price : ℝ) :
    (problem.optimizerSet price).Nonempty := by
  obtain ⟨library, hoptimizer⟩ := problem.exists_optimizer price
  exact ⟨library, hoptimizer⟩

/--
`J⋆` is exactly the attained maximum of the fixed finite nonempty branch
family: it bounds every feasible branch and equals at least one of them.
-/
theorem envelope_is_finite_maximum (price : ℝ) :
    (∀ library ∈ problem.feasibleLibraries,
        problem.branch library price ≤ problem.envelope price) ∧
      ∃ library ∈ problem.feasibleLibraries,
        problem.envelope price = problem.branch library price := by
  constructor
  · intro library hlibrary
    exact problem.branch_le_envelope hlibrary price
  · obtain ⟨library, hlibrary, hoptimal⟩ := problem.exists_optimizer price
    exact ⟨library, hlibrary, hoptimal.symm⟩

/-- Each library branch is continuous on the entire real price line. -/
theorem continuous_branch (library : Library) :
    Continuous (problem.branch library) := by
  unfold branch
  exact continuous_const.sub (continuous_id.mul continuous_const)

/-- Each library branch has constant slope `-W_L`. -/
theorem hasDerivAt_branch (library : Library) (price : ℝ) :
    HasDerivAt (problem.branch library) (-problem.burden library) price := by
  change HasDerivAt
    (fun candidatePrice : ℝ =>
      problem.productiveValue library -
        candidatePrice * problem.burden library)
    (-problem.burden library) price
  have hlinear : HasDerivAt
      (fun candidatePrice : ℝ =>
        (-problem.burden library) * candidatePrice)
      (-problem.burden library) price := by
    simpa using
      (hasDerivAt_id' price).const_mul (-problem.burden library)
  have haffine : HasDerivAt
      (fun candidatePrice : ℝ =>
        (-problem.burden library) * candidatePrice +
          problem.productiveValue library)
      (-problem.burden library) price :=
    hlinear.add_const (problem.productiveValue library)
  apply haffine.congr_of_eventuallyEq
  filter_upwards with candidatePrice
  ring

/-- Nonnegative burdens make the penalized envelope nonincreasing in price. -/
theorem envelope_antitone : Antitone problem.envelope := by
  intro price₁ price₂ hprice
  apply (Finset.sup'_le_iff
    problem.feasibleLibraries_nonempty
    (fun library => problem.branch library price₂)).2
  intro library hlibrary
  calc
    problem.branch library price₂ ≤ problem.branch library price₁ := by
      have hmul :
          price₁ * problem.burden library ≤
            price₂ * problem.burden library :=
        mul_le_mul_of_nonneg_right hprice
          (problem.burden_nonnegative library hlibrary)
      dsimp [branch]
      linarith
    _ ≤ problem.envelope price₁ :=
      problem.branch_le_envelope hlibrary price₁

/-- The upper envelope of the finite affine family is convex on `ℝ`. -/
theorem envelope_convex : ConvexOn ℝ Set.univ problem.envelope := by
  refine ⟨convex_univ, ?_⟩
  intro price₁ _ price₂ _ a b ha hb hab
  apply (Finset.sup'_le_iff
    problem.feasibleLibraries_nonempty
    (fun library => problem.branch library
      (a • price₁ + b • price₂))).2
  intro library hlibrary
  calc
    problem.branch library (a • price₁ + b • price₂) =
        a • problem.branch library price₁ +
          b • problem.branch library price₂ := by
      simp only [smul_eq_mul]
      dsimp [branch]
      calc
        problem.productiveValue library -
              (a * price₁ + b * price₂) * problem.burden library =
            (a + b) * problem.productiveValue library -
              (a * price₁ + b * price₂) * problem.burden library := by
                rw [hab, one_mul]
        _ = a *
              (problem.productiveValue library -
                price₁ * problem.burden library) +
              b *
              (problem.productiveValue library -
                price₂ * problem.burden library) := by ring
    _ ≤ a • problem.envelope price₁ + b • problem.envelope price₂ := by
      exact add_le_add
        (smul_le_smul_of_nonneg_left
          (problem.branch_le_envelope hlibrary price₁) ha)
        (smul_le_smul_of_nonneg_left
          (problem.branch_le_envelope hlibrary price₂) hb)

/-- The maximum of the finite continuous branch family is continuous. -/
theorem continuous_envelope : Continuous problem.envelope := by
  unfold envelope
  exact Continuous.finset_sup'_apply problem.feasibleLibraries_nonempty
    (fun library _ => problem.continuous_branch library)

/-- Pairwise switching price for two branches with distinct burdens. -/
noncomputable def switchingPrice (left right : Library) : ℝ :=
  (problem.productiveValue left - problem.productiveValue right) /
    (problem.burden left - problem.burden right)

/-- All unequal-burden pairwise switching prices form a finite set. -/
noncomputable def pairwiseSwitchingPrices : Finset ℝ := by
  classical
  exact
    ((problem.feasibleLibraries.product problem.feasibleLibraries).filter
      (fun pair => problem.burden pair.1 ≠ problem.burden pair.2)).image
      (fun pair => problem.switchingPrice pair.1 pair.2)

/-- The candidate switching-price set is finite. -/
theorem pairwiseSwitchingPriceSet_finite :
    Set.Finite (problem.pairwiseSwitchingPrices : Set ℝ) :=
  Finset.finite_toSet problem.pairwiseSwitchingPrices

/-- Every feasible unequal-burden pair contributes its finite switching price. -/
theorem switchingPrice_mem_pairwiseSwitchingPrices
    {left right : Library}
    (hleft : left ∈ problem.feasibleLibraries)
    (hright : right ∈ problem.feasibleLibraries)
    (hburden : problem.burden left ≠ problem.burden right) :
    problem.switchingPrice left right ∈ problem.pairwiseSwitchingPrices := by
  classical
  unfold pairwiseSwitchingPrices
  apply Finset.mem_image.mpr
  exact ⟨(left, right), by simp [hleft, hright, hburden], rfl⟩

/-- Unequal-burden branches agree at their pairwise switching price. -/
theorem branch_eq_at_switchingPrice {left right : Library}
    (hburden : problem.burden left ≠ problem.burden right) :
    problem.branch left (problem.switchingPrice left right) =
      problem.branch right (problem.switchingPrice left right) := by
  have hdenom : problem.burden left - problem.burden right ≠ 0 :=
    sub_ne_zero.mpr hburden
  have hquotient :
      ((problem.productiveValue left - problem.productiveValue right) /
          (problem.burden left - problem.burden right)) *
          (problem.burden left - problem.burden right) =
        problem.productiveValue left - problem.productiveValue right :=
    div_mul_cancel₀ _ hdenom
  dsimp [branch, switchingPrice]
  nlinarith

/--
Any optimizer tie between branches of different burdens occurs at their
pairwise switching price, hence in the finite candidate-price set.
-/
theorem optimizer_tie_eq_switchingPrice
    {price : ℝ} {left right : Library}
    (hleft : problem.IsOptimizer price left)
    (hright : problem.IsOptimizer price right)
    (hburden : problem.burden left ≠ problem.burden right) :
    price = problem.switchingPrice left right := by
  have hbranches :
      problem.branch left price = problem.branch right price :=
    hleft.2.trans hright.2.symm
  rw [switchingPrice, eq_div_iff (sub_ne_zero.mpr hburden)]
  dsimp [branch] at hbranches
  nlinarith

/-- A different-burden optimizer tie belongs to the finite candidate set. -/
theorem optimizer_tie_mem_pairwiseSwitchingPrices
    {price : ℝ} {left right : Library}
    (hleft : problem.IsOptimizer price left)
    (hright : problem.IsOptimizer price right)
    (hburden : problem.burden left ≠ problem.burden right) :
    price ∈ problem.pairwiseSwitchingPrices := by
  rw [problem.optimizer_tie_eq_switchingPrice hleft hright hburden]
  exact problem.switchingPrice_mem_pairwiseSwitchingPrices
    hleft.1 hright.1 hburden

/-- Outside the finite candidate set, all simultaneously optimal burdens agree. -/
theorem optimizer_burdens_eq_of_not_mem_pairwiseSwitchingPrices
    {price : ℝ}
    (hprice : price ∉ problem.pairwiseSwitchingPrices)
    {left right : Library}
    (hleft : problem.IsOptimizer price left)
    (hright : problem.IsOptimizer price right) :
    problem.burden left = problem.burden right := by
  by_contra hburden
  exact hprice
    (problem.optimizer_tie_mem_pairwiseSwitchingPrices
      hleft hright hburden)

/--
Direct finite-breakpoint characterization: outside the finite pairwise
candidate set, some optimal affine branch agrees with the envelope throughout
a neighborhood of the price.
-/
theorem exists_eventuallyEq_branch_of_not_mem_pairwiseSwitchingPrices
    {price : ℝ}
    (hprice : price ∉ problem.pairwiseSwitchingPrices) :
    ∃ winner : Library,
      problem.IsOptimizer price winner ∧
        problem.envelope =ᶠ[𝓝 price] problem.branch winner := by
  obtain ⟨winner, hwinner⟩ := problem.exists_optimizer price
  refine ⟨winner, hwinner, ?_⟩
  have hcompetitor :
      ∀ competitor ∈ problem.feasibleLibraries,
        ∀ᶠ nearby in 𝓝 price,
          problem.branch competitor nearby ≤ problem.branch winner nearby := by
    intro competitor hfeasible
    have hle :
        problem.branch competitor price ≤ problem.branch winner price := by
      calc
        problem.branch competitor price ≤ problem.envelope price :=
          problem.branch_le_envelope hfeasible price
        _ = problem.branch winner price := hwinner.2.symm
    rcases hle.eq_or_lt with heq | hlt
    · have hcompetitorOptimal : problem.IsOptimizer price competitor :=
        ⟨hfeasible, heq.trans hwinner.2⟩
      have hburden :
          problem.burden competitor = problem.burden winner :=
        problem.optimizer_burdens_eq_of_not_mem_pairwiseSwitchingPrices
          hprice hcompetitorOptimal hwinner
      have hvalue :
          problem.productiveValue competitor =
            problem.productiveValue winner := by
        dsimp [branch] at heq
        rw [hburden] at heq
        linarith
      filter_upwards with nearby
      simp [branch, hburden, hvalue]
    · filter_upwards [
        (isOpen_lt (problem.continuous_branch competitor)
          (problem.continuous_branch winner)).mem_nhds hlt
      ] with nearby hstrict
      exact hstrict.le
  have hall :
      ∀ᶠ nearby in 𝓝 price,
        ∀ competitor ∈ problem.feasibleLibraries,
          problem.branch competitor nearby ≤ problem.branch winner nearby :=
    (problem.feasibleLibraries.eventually_all).2 hcompetitor
  filter_upwards [hall] with nearby hnearby
  apply le_antisymm
  · exact Finset.sup'_le problem.feasibleLibraries_nonempty
      (fun competitor => problem.branch competitor nearby) hnearby
  · exact problem.branch_le_envelope hwinner.1 nearby

/-- The envelope agrees locally with one optimal affine branch at this price. -/
def IsLocallyAffineAt (price : ℝ) : Prop :=
  ∃ winner : Library,
    problem.IsOptimizer price winner ∧
      problem.envelope =ᶠ[𝓝 price] problem.branch winner

/-- Prices where no optimal affine branch represents the envelope locally. -/
def breakpointSet : Set ℝ :=
  {price | ¬ problem.IsLocallyAffineAt price}

/-- Every price outside the pairwise candidates is locally affine. -/
theorem isLocallyAffineAt_of_not_mem_pairwiseSwitchingPrices
    {price : ℝ}
    (hprice : price ∉ problem.pairwiseSwitchingPrices) :
    problem.IsLocallyAffineAt price :=
  problem.exists_eventuallyEq_branch_of_not_mem_pairwiseSwitchingPrices hprice

/-- Every non-locally-affine price is a pairwise switching candidate. -/
theorem breakpointSet_subset_pairwiseSwitchingPrices :
    problem.breakpointSet ⊆
      (problem.pairwiseSwitchingPrices : Set ℝ) := by
  intro price hbreakpoint
  by_contra hprice
  exact hbreakpoint
    (problem.isLocallyAffineAt_of_not_mem_pairwiseSwitchingPrices hprice)

/-- The direct breakpoint set is finite. -/
theorem breakpointSet_finite : Set.Finite problem.breakpointSet :=
  problem.pairwiseSwitchingPriceSet_finite.subset
    problem.breakpointSet_subset_pairwiseSwitchingPrices

/--
Away from the actual breakpoint set (not merely away from the larger pairwise
candidate set), the envelope agrees locally with an optimal branch and has
that branch's exact affine slope `-W_L`.
-/
theorem exists_hasDerivAt_envelope_of_not_mem_breakpointSet
    {price : ℝ}
    (hprice : price ∉ problem.breakpointSet) :
    ∃ winner : Library,
      problem.IsOptimizer price winner ∧
        HasDerivAt problem.envelope (-problem.burden winner) price := by
  have hlocal : problem.IsLocallyAffineAt price := by
    simpa [breakpointSet] using hprice
  obtain ⟨winner, hwinner, heventually⟩ := hlocal
  exact ⟨winner, hwinner,
    (problem.hasDerivAt_branch winner price).congr_of_eventuallyEq heventually⟩

/-- Outside the finite switching candidates, the envelope has an affine slope. -/
theorem exists_hasDerivAt_envelope_of_not_mem_pairwiseSwitchingPrices
    {price : ℝ}
    (hprice : price ∉ problem.pairwiseSwitchingPrices) :
    ∃ winner : Library,
      problem.IsOptimizer price winner ∧
        HasDerivAt problem.envelope (-problem.burden winner) price := by
  obtain ⟨winner, hwinner, heventually⟩ :=
    problem.exists_eventuallyEq_branch_of_not_mem_pairwiseSwitchingPrices hprice
  exact ⟨winner, hwinner,
    (problem.hasDerivAt_branch winner price).congr_of_eventuallyEq heventually⟩

/-- A fixed library strictly dominates every competitor throughout a price set. -/
def StrictlyDominatesOn (winner : Library) (prices : Set ℝ) : Prop :=
  winner ∈ problem.feasibleLibraries ∧
    ∀ price ∈ prices, ∀ competitor ∈ problem.feasibleLibraries,
      competitor ≠ winner →
        problem.branch competitor price < problem.branch winner price

/-- On a strict-dominance region, the envelope equals the winning branch. -/
theorem envelope_eq_branch_of_strictlyDominatesOn
    {winner : Library} {prices : Set ℝ}
    (hdominates : problem.StrictlyDominatesOn winner prices)
    {price : ℝ} (hprice : price ∈ prices) :
    problem.envelope price = problem.branch winner price := by
  apply le_antisymm
  · apply (Finset.sup'_le_iff
      problem.feasibleLibraries_nonempty
      (fun library => problem.branch library price)).2
    intro competitor hcompetitor
    by_cases heq : competitor = winner
    · subst competitor
      exact le_rfl
    · exact (hdominates.2 price hprice competitor hcompetitor heq).le
  · exact problem.branch_le_envelope hdominates.1 price

/--
On an open strict-dominance interval, the envelope derivative is exactly the
winning affine slope `-W_L`.
-/
theorem hasDerivAt_envelope_of_strictlyDominatesOn
    {winner : Library} {prices : Set ℝ}
    (hopen : IsOpen prices)
    (hdominates : problem.StrictlyDominatesOn winner prices)
    {price : ℝ} (hprice : price ∈ prices) :
    HasDerivAt problem.envelope (-problem.burden winner) price := by
  apply (problem.hasDerivAt_branch winner price).congr_of_eventuallyEq
  filter_upwards [hopen.mem_nhds hprice] with nearby hnearby
  exact problem.envelope_eq_branch_of_strictlyDominatesOn
    hdominates hnearby

/--
At two strictly ordered prices, every later optimizer has weakly lower burden
than every earlier optimizer.
-/
theorem optimalBurden_antitone
    {price₁ price₂ : ℝ} (hprice : price₁ < price₂)
    {early late : Library}
    (hearly : problem.IsOptimizer price₁ early)
    (hlate : problem.IsOptimizer price₂ late) :
    problem.burden late ≤ problem.burden early := by
  have hearlyComparison :
      problem.branch late price₁ ≤ problem.branch early price₁ := by
    calc
      problem.branch late price₁ ≤ problem.envelope price₁ :=
        problem.branch_le_envelope hlate.1 price₁
      _ = problem.branch early price₁ := hearly.2.symm
  have hlateComparison :
      problem.branch early price₂ ≤ problem.branch late price₂ := by
    calc
      problem.branch early price₂ ≤ problem.envelope price₂ :=
        problem.branch_le_envelope hearly.1 price₂
      _ = problem.branch late price₂ := hlate.2.symm
  dsimp [branch] at hearlyComparison hlateComparison
  nlinarith

/-- A choice of an optimizer at every real price. -/
noncomputable def selectedOptimizer (price : ℝ) : Library :=
  Classical.choose (problem.exists_optimizer price)

/-- The selected library is genuinely optimal; no uniqueness is asserted. -/
theorem selectedOptimizer_isOptimizer (price : ℝ) :
    problem.IsOptimizer price (problem.selectedOptimizer price) :=
  Classical.choose_spec (problem.exists_optimizer price)

/-- The burden of the chosen optimizer is weakly nonincreasing in price. -/
theorem selectedBurden_antitone :
    Antitone (fun price => problem.burden (problem.selectedOptimizer price)) := by
  intro price₁ price₂ hprice
  rcases hprice.eq_or_lt with hEq | hlt
  · subst price₂
    exact le_rfl
  · exact problem.optimalBurden_antitone hlt
      (problem.selectedOptimizer_isOptimizer price₁)
      (problem.selectedOptimizer_isOptimizer price₂)

end FinitePenalizedProblem

end Optimization

end StrategyInnovation
