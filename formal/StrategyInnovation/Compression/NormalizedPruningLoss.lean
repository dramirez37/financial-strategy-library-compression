import Mathlib.Tactic
import StrategyInnovation.Compression.UnifiedSafeDeletion
import StrategyInnovation.Counterexamples.FrontierPruningLoss

/-!
# Normalized frontier-only pruning loss (T4)

This module replaces reward-scaling as the primary pruning-loss statement.
It reuses only the finite bridge catalog from the older F4 example and builds
the probability calculation from the raw candidate-generation and admission
definitions.

For project duration `d`, discount `β`, per-period survival factor `ρ`,
admission probability `π`, descendant reward `C`, and initiation cost `κ`,
the bridge makes the derived admitted-descendant mass exactly `ρ ^ d * π`.
Under the unified timing convention, the descendant continuation is discounted
by `β ^ d`, so the exact net pruning loss is

`β ^ d * ρ ^ d * π * C - κ`.

The construction assumes this net opportunity is nonnegative, so the research
action is selected over the zero-valued Continue action.  The old
reward-scaled theorem remains compiled only as a corollary/boundary example.
-/

namespace StrategyInnovation

namespace Projection

namespace Model

namespace NormalizedPruningLoss

namespace Bridge

abbrev model := StrategyInnovation.FrontierPruningLoss.model
abbrev catalog := StrategyInnovation.FrontierPruningLoss.catalog
abbrev moduleClosure := StrategyInnovation.FrontierPruningLoss.moduleClosure
abbrev unprunedLibrary := StrategyInnovation.FrontierPruningLoss.unprunedLibrary
abbrev prunedLibrary := StrategyInnovation.FrontierPruningLoss.prunedLibrary

namespace Belief

abbrev only : StrategyInnovation.FrontierPruningLoss.Belief :=
  .only

end Belief

namespace Strategy

abbrev future : StrategyInnovation.FrontierPruningLoss.Strategy :=
  .future

end Strategy

namespace Module

abbrev key : StrategyInnovation.FrontierPruningLoss.Module :=
  .key

end Module

namespace Project

abbrev innovate : StrategyInnovation.FrontierPruningLoss.Project :=
  .innovate

end Project

end Bridge

/-- Exact rational parameters for the canonical normalized T4 construction. -/
structure Parameters where
  duration : Nat
  duration_positive : 0 < duration
  discount : ℚ
  discount_nonnegative : 0 ≤ discount
  discount_lt_one : discount < 1
  survival : ℚ
  survival_nonnegative : 0 ≤ survival
  survival_le_one : survival ≤ 1
  admission : ℚ
  admission_nonnegative : 0 ≤ admission
  admission_le_one : admission ≤ 1
  rewardCap : ℚ
  rewardCap_nonnegative : 0 ≤ rewardCap
  researchCost : ℚ
  researchCost_nonnegative : 0 ≤ researchCost
  researchWorthwhile :
    researchCost ≤
      discount ^ duration * survival ^ duration * admission * rewardCap

/-- The survival gate either produces the descendant or produces no candidate. -/
noncomputable def survivalGenerationLaw
    (survival : ℚ) (hsurvival0 : 0 ≤ survival) (hsurvival1 : survival ≤ 1) :
    RatProb (Raw.CandidateOutcome Bridge.model) where
  mass :=
    Finsupp.single none (1 - survival) +
      Finsupp.single (some Bridge.Strategy.future) survival
  nonnegative := by
    intro outcome
    classical
    by_cases hnone : outcome = none
    · subst outcome
      simp
      exact hsurvival1
    · by_cases hfuture : outcome = some Bridge.Strategy.future
      · subst outcome
        simp
        exact hsurvival0
      · simp [hnone, hfuture]
  totalMass := by
    classical
    rw [Finsupp.sum_add_index' (by intros; rfl) (by intros; rfl)]
    rw [Finsupp.sum_single_index (by rfl),
      Finsupp.sum_single_index (by rfl)]
    ring

/--
The raw generator uses the bridge closure.  With the key module it generates
the descendant after the declared survival gate; without the key it fails.
-/
noncomputable def generation (parameters : Parameters) :
    Raw.CandidateGenerationDistributions Bridge.model where
  distribution := fun _project _belief available =>
    if Bridge.Module.key ∈ available then
      survivalGenerationLaw
        (parameters.survival ^ parameters.duration)
        (pow_nonneg parameters.survival_nonnegative _)
        (pow_le_one₀ parameters.survival_nonnegative parameters.survival_le_one)
    else
      RatProb.dirac none

/-- The descendant passes admission with exact probability `π`. -/
def admission (parameters : Parameters) :
    Raw.AdmissionProbabilities Bridge.model where
  probability := fun _project _belief _available strategy =>
    if strategy = Bridge.Strategy.future then parameters.admission else 0
  nonnegative := by
    intro project belief available strategy
    split_ifs
    · exact parameters.admission_nonnegative
    · norm_num
  le_one := by
    intro project belief available strategy
    split_ifs
    · exact parameters.admission_le_one
    · norm_num

/-- The retained bridge supplies exactly the required raw module. -/
theorem retained_closure_has_key (reward : ℚ) :
    Bridge.Module.key ∈
      generativeClosure (Bridge.catalog reward)
        Bridge.moduleClosure (Bridge.unprunedLibrary reward) := by
  rw [StrategyInnovation.FrontierPruningLoss.unpruned_closure_eq_key]
  simp

/-- Frontier-only deletion removes the unique required raw module. -/
theorem pruned_closure_lacks_key (reward : ℚ) :
    Bridge.Module.key ∉
      generativeClosure (Bridge.catalog reward)
        Bridge.moduleClosure (Bridge.prunedLibrary reward) := by
  rw [StrategyInnovation.FrontierPruningLoss.pruned_closure_eq_empty]
  simp

/-- The bridge is operationally dominated in the unified raw-library sense. -/
theorem bridge_operationallyRedundant (parameters : Parameters) :
    operationallyRedundant
      (Bridge.unprunedLibrary parameters.rewardCap)
      StrategyInnovation.FrontierPruningLoss.Strategy.dominated
      StrategyInnovation.FrontierPruningLoss.dominated_ne_inactive := by
  unfold operationallyRedundant
  rw [StrategyInnovation.FrontierPruningLoss.erase_dominated_eq_pruned,
    StrategyInnovation.FrontierPruningLoss.pruned_frontier_eq_zero,
    StrategyInnovation.FrontierPruningLoss.unpruned_frontier_eq_zero]

/-- The operationally dominated bridge is generatively essential. -/
theorem bridge_generativelyEssential (parameters : Parameters) :
    ¬ generativelyRedundant (closure := Bridge.moduleClosure)
      (Bridge.unprunedLibrary parameters.rewardCap)
      StrategyInnovation.FrontierPruningLoss.Strategy.dominated
      StrategyInnovation.FrontierPruningLoss.dominated_ne_inactive := by
  intro hredundant
  unfold generativelyRedundant at hredundant
  rw [StrategyInnovation.FrontierPruningLoss.erase_dominated_eq_pruned,
    StrategyInnovation.FrontierPruningLoss.pruned_closure_eq_empty,
    StrategyInnovation.FrontierPruningLoss.unpruned_closure_eq_key]
    at hredundant
  simp at hredundant

/-- The required module is carried uniquely by the bridge. -/
theorem bridge_uniquelyCarriesRequiredModule (parameters : Parameters) :
    StrategyInnovation.FrontierPruningLoss.Module.key ∈
        StrategyInnovation.FrontierPruningLoss.modules
          StrategyInnovation.FrontierPruningLoss.Strategy.dominated ∧
      ∀ strategy ∈ Bridge.unprunedLibrary parameters.rewardCap,
        StrategyInnovation.FrontierPruningLoss.Module.key ∈
            StrategyInnovation.FrontierPruningLoss.modules strategy →
          strategy =
            StrategyInnovation.FrontierPruningLoss.Strategy.dominated :=
  StrategyInnovation.FrontierPruningLoss.keyModule_unique_to_dominated
    parameters.rewardCap

/-- The bridge itself has zero reward and is dominated by the inactive frontier. -/
theorem bridge_profile_eq_zero (parameters : Parameters) :
    ∀ belief,
      StrategyInnovation.FrontierPruningLoss.profile parameters.rewardCap
          StrategyInnovation.FrontierPruningLoss.Strategy.dominated belief = 0 := by
  intro belief
  cases belief
  rfl

/-- Every reward in the canonical catalog lies between zero and the cap. -/
def RewardsBoundedByCap (parameters : Parameters) : Prop :=
  ∀ strategy belief,
    0 ≤ StrategyInnovation.FrontierPruningLoss.profile
        parameters.rewardCap strategy belief ∧
      StrategyInnovation.FrontierPruningLoss.profile
          parameters.rewardCap strategy belief ≤ parameters.rewardCap

theorem rewards_boundedByCap (parameters : Parameters) :
    RewardsBoundedByCap parameters := by
  intro strategy belief
  cases strategy <;> cases belief <;>
    simp [StrategyInnovation.FrontierPruningLoss.profile,
      parameters.rewardCap_nonnegative]

/-- Raw generation assigns the survival mass `ρ^d` to the descendant. -/
theorem generation_descendant_probability_retained
    (parameters : Parameters) (reward : ℚ) :
    (generation parameters).probability Bridge.Project.innovate Bridge.Belief.only
        (generativeClosure (Bridge.catalog reward)
          Bridge.moduleClosure (Bridge.unprunedLibrary reward))
        (some Bridge.Strategy.future) =
      parameters.survival ^ parameters.duration := by
  simp [Raw.CandidateGenerationDistributions.probability, generation,
    retained_closure_has_key, survivalGenerationLaw, RatProb.probability]

/-- Without the bridge module, raw generation never produces the descendant. -/
theorem generation_descendant_probability_pruned
    (parameters : Parameters) (reward : ℚ) :
    (generation parameters).probability Bridge.Project.innovate Bridge.Belief.only
        (generativeClosure (Bridge.catalog reward)
          Bridge.moduleClosure (Bridge.prunedLibrary reward))
        (some Bridge.Strategy.future) = 0 := by
  simp [Raw.CandidateGenerationDistributions.probability, generation,
    pruned_closure_lacks_key, RatProb.probability, RatProb.dirac]

/-- The primitive admission row for the descendant is exactly `π`. -/
theorem descendant_admission_probability (parameters : Parameters)
    (available : Raw.ModuleSet Bridge.model) :
    (admission parameters).probability Bridge.Project.innovate Bridge.Belief.only
        available Bridge.Strategy.future =
      parameters.admission := by
  simp [admission]

/--
Raw generation and admission give admitted-descendant mass exactly `ρ^d π`
when the bridge is retained.
-/
theorem admitted_descendant_probability_retained
    (parameters : Parameters) (reward : ℚ) :
    (Raw.admittedCandidateDistribution (generation parameters)
        (admission parameters) Bridge.Project.innovate Bridge.Belief.only
        (generativeClosure (Bridge.catalog reward)
          Bridge.moduleClosure (Bridge.unprunedLibrary reward))).probability
        (some Bridge.Strategy.future) =
      parameters.survival ^ parameters.duration * parameters.admission := by
  rw [Raw.admittedCandidateDistribution_probability]
  simp only [Raw.admittedCandidateMass]
  rw [generation_descendant_probability_retained,
    descendant_admission_probability]

/-- After frontier-only pruning the admitted-descendant mass is exactly zero. -/
theorem admitted_descendant_probability_pruned
    (parameters : Parameters) (reward : ℚ) :
    (Raw.admittedCandidateDistribution (generation parameters)
        (admission parameters) Bridge.Project.innovate Bridge.Belief.only
        (generativeClosure (Bridge.catalog reward)
          Bridge.moduleClosure (Bridge.prunedLibrary reward))).probability
        (some Bridge.Strategy.future) = 0 := by
  rw [Raw.admittedCandidateDistribution_probability]
  simp only [Raw.admittedCandidateMass]
  rw [generation_descendant_probability_pruned]
  ring

/-- Unified-timing discounted terminal payoff of one admitted outcome. -/
def discountedDescendantPayoff (parameters : Parameters) (reward : ℚ) :
    Raw.CandidateOutcome Bridge.model → ℚ :=
  fun outcome =>
    if outcome = some Bridge.Strategy.future then
      parameters.discount ^ parameters.duration * reward
    else 0

/-- Expectation of a point-supported payoff under an exact rational law. -/
theorem expectation_indicator
    {α : Type*} [Fintype α] [DecidableEq α]
    (distribution : RatProb α) (target : α) (payoff : ℚ) :
    distribution.expectation (fun outcome => if outcome = target then payoff else 0) =
      distribution.probability target * payoff := by
  classical
  simp [RatProb.expectation, RatProb.probability, Finsupp.sum_fintype]

/-- The retained bridge has exact gross discounted descendant value. -/
theorem retained_expected_descendant_value
    (parameters : Parameters) (reward : ℚ) :
    (Raw.admittedCandidateDistribution (generation parameters)
        (admission parameters) Bridge.Project.innovate Bridge.Belief.only
        (generativeClosure (Bridge.catalog reward)
          Bridge.moduleClosure (Bridge.unprunedLibrary reward))).expectation
        (discountedDescendantPayoff parameters reward) =
      parameters.discount ^ parameters.duration *
        parameters.survival ^ parameters.duration *
        parameters.admission * reward := by
  rw [show discountedDescendantPayoff parameters reward =
      fun outcome =>
        if outcome = some Bridge.Strategy.future then
          parameters.discount ^ parameters.duration * reward
        else 0 by
      funext outcome
      cases outcome with
      | none => rfl
      | some strategy =>
          cases strategy <;> simp [discountedDescendantPayoff]]
  rw [expectation_indicator,
    admitted_descendant_probability_retained parameters reward]
  ring

/-- The pruned library has zero attainable discounted descendant value. -/
theorem pruned_expected_descendant_value
    (parameters : Parameters) (reward : ℚ) :
    (Raw.admittedCandidateDistribution (generation parameters)
        (admission parameters) Bridge.Project.innovate Bridge.Belief.only
        (generativeClosure (Bridge.catalog reward)
          Bridge.moduleClosure (Bridge.prunedLibrary reward))).expectation
        (discountedDescendantPayoff parameters reward) = 0 := by
  rw [show discountedDescendantPayoff parameters reward =
      fun outcome =>
        if outcome = some Bridge.Strategy.future then
          parameters.discount ^ parameters.duration * reward
        else 0 by
      funext outcome
      cases outcome with
      | none => rfl
      | some strategy =>
          cases strategy <;> simp [discountedDescendantPayoff]]
  rw [expectation_indicator,
    admitted_descendant_probability_pruned parameters reward]
  ring

/-- Gross attainable discounted descendant value before initiation cost. -/
def maxAttainableGrossDescendantValue
    (parameters : Parameters) (reward : ℚ) : ℚ :=
  parameters.discount ^ parameters.duration *
    parameters.survival ^ parameters.duration *
    parameters.admission * reward

/-- Net attainable descendant value after the declared initiation cost. -/
def maxAttainableDescendantValue
    (parameters : Parameters) (reward : ℚ) : ℚ :=
  maxAttainableGrossDescendantValue parameters reward -
    parameters.researchCost

/--
The one-project Bellman envelope derived from the raw admitted law: Continue
pays zero and research pays the expected discounted descendant reward less
the initiation cost.
-/
noncomputable def canonicalUnprunedValue
    (parameters : Parameters) (reward : ℚ) : ℚ :=
  max 0
    (-parameters.researchCost +
      (Raw.admittedCandidateDistribution (generation parameters)
        (admission parameters) Bridge.Project.innovate Bridge.Belief.only
        (generativeClosure (Bridge.catalog reward)
          Bridge.moduleClosure
          (Bridge.unprunedLibrary reward))).expectation
        (discountedDescendantPayoff parameters reward))

/--
After frontier-only pruning the same raw project law has no descendant payoff;
the zero-valued Continue option therefore leaves value zero.
-/
noncomputable def canonicalPrunedValue
    (parameters : Parameters) (reward : ℚ) : ℚ :=
  max 0
    ((Raw.admittedCandidateDistribution (generation parameters)
      (admission parameters) Bridge.Project.innovate Bridge.Belief.only
      (generativeClosure (Bridge.catalog reward)
        Bridge.moduleClosure
        (Bridge.prunedLibrary reward))).expectation
      (discountedDescendantPayoff parameters reward))

/-- Exact value loss in the declared one-project construction. -/
noncomputable def canonicalPruningLoss (parameters : Parameters) (reward : ℚ) : ℚ :=
  canonicalUnprunedValue parameters reward -
    canonicalPrunedValue parameters reward

/-- The raw-law Bellman envelope reduces to the displayed scalar maximum. -/
theorem canonicalUnprunedValue_eq
    (parameters : Parameters) (reward : ℚ) :
    canonicalUnprunedValue parameters reward =
      max 0 (maxAttainableDescendantValue parameters reward) := by
  unfold canonicalUnprunedValue maxAttainableDescendantValue
    maxAttainableGrossDescendantValue
  rw [retained_expected_descendant_value]
  congr 1
  ring

/-- The frontier-pruned Bellman envelope is exactly zero. -/
theorem canonicalPrunedValue_eq_zero
    (parameters : Parameters) (reward : ℚ) :
    canonicalPrunedValue parameters reward = 0 := by
  unfold canonicalPrunedValue
  rw [pruned_expected_descendant_value]
  simp

/--
T4 exact formula at the reward cap.  The raw law supplies `ρ^d π`, unified
timing supplies `β^d`, and the initiation-cost difference is `κ - 0 = κ`.
-/
theorem canonicalPruningLoss_exact (parameters : Parameters) :
    canonicalPruningLoss parameters parameters.rewardCap =
      parameters.discount ^ parameters.duration *
        parameters.survival ^ parameters.duration *
        parameters.admission * parameters.rewardCap -
        parameters.researchCost := by
  rw [canonicalPruningLoss, canonicalUnprunedValue_eq,
    canonicalPrunedValue_eq_zero]
  unfold maxAttainableDescendantValue maxAttainableGrossDescendantValue
  rw [max_eq_right (sub_nonneg.mpr parameters.researchWorthwhile)]
  ring

/--
One certificate records that the parameterized scalar formula is attached to
the declared raw bridge, generator, admission row, and reward cap.
-/
structure CanonicalConstructionCertificate (parameters : Parameters) : Prop where
  operationallyDominated : operationallyRedundant
    (Bridge.unprunedLibrary parameters.rewardCap)
    StrategyInnovation.FrontierPruningLoss.Strategy.dominated
    StrategyInnovation.FrontierPruningLoss.dominated_ne_inactive
  bridgeZeroProfile : ∀ belief,
    StrategyInnovation.FrontierPruningLoss.profile parameters.rewardCap
      StrategyInnovation.FrontierPruningLoss.Strategy.dominated belief = 0
  generativelyEssential : ¬ generativelyRedundant
    (closure := Bridge.moduleClosure)
    (Bridge.unprunedLibrary parameters.rewardCap)
    StrategyInnovation.FrontierPruningLoss.Strategy.dominated
    StrategyInnovation.FrontierPruningLoss.dominated_ne_inactive
  uniqueRequiredModule :
    StrategyInnovation.FrontierPruningLoss.Module.key ∈
        StrategyInnovation.FrontierPruningLoss.modules
          StrategyInnovation.FrontierPruningLoss.Strategy.dominated ∧
      ∀ strategy ∈ Bridge.unprunedLibrary parameters.rewardCap,
        StrategyInnovation.FrontierPruningLoss.Module.key ∈
            StrategyInnovation.FrontierPruningLoss.modules strategy →
          strategy =
            StrategyInnovation.FrontierPruningLoss.Strategy.dominated
  survivalGate :
    (generation parameters).probability Bridge.Project.innovate Bridge.Belief.only
        (generativeClosure (Bridge.catalog parameters.rewardCap)
          Bridge.moduleClosure (Bridge.unprunedLibrary parameters.rewardCap))
        (some Bridge.Strategy.future) =
      parameters.survival ^ parameters.duration
  descendantAdmission :
    (admission parameters).probability Bridge.Project.innovate Bridge.Belief.only
        (generativeClosure (Bridge.catalog parameters.rewardCap)
          Bridge.moduleClosure (Bridge.unprunedLibrary parameters.rewardCap))
        Bridge.Strategy.future =
      parameters.admission
  admittedDescendant :
    (Raw.admittedCandidateDistribution (generation parameters)
        (admission parameters) Bridge.Project.innovate Bridge.Belief.only
        (generativeClosure (Bridge.catalog parameters.rewardCap)
          Bridge.moduleClosure (Bridge.unprunedLibrary parameters.rewardCap))).probability
        (some Bridge.Strategy.future) =
      parameters.survival ^ parameters.duration * parameters.admission
  rewardBound : RewardsBoundedByCap parameters
  exactLoss :
    canonicalPruningLoss parameters parameters.rewardCap =
      parameters.discount ^ parameters.duration *
        parameters.survival ^ parameters.duration *
        parameters.admission * parameters.rewardCap -
        parameters.researchCost

/-- The canonical raw bridge satisfies every declared T4 construction property. -/
theorem canonicalConstruction_certificate (parameters : Parameters) :
    CanonicalConstructionCertificate parameters where
  operationallyDominated := bridge_operationallyRedundant parameters
  bridgeZeroProfile := bridge_profile_eq_zero parameters
  generativelyEssential := bridge_generativelyEssential parameters
  uniqueRequiredModule := bridge_uniquelyCarriesRequiredModule parameters
  survivalGate :=
    generation_descendant_probability_retained parameters parameters.rewardCap
  descendantAdmission :=
    descendant_admission_probability parameters _
  admittedDescendant :=
    admitted_descendant_probability_retained parameters parameters.rewardCap
  rewardBound := rewards_boundedByCap parameters
  exactLoss := canonicalPruningLoss_exact parameters

/--
Under the reward cap, the displayed bound is attained at the cap and is
therefore sharp within the canonical construction.
-/
theorem rewardCap_sharp
    (parameters : Parameters) :
    (∀ reward : ℚ, 0 ≤ reward → reward ≤ parameters.rewardCap →
      canonicalPruningLoss parameters reward ≤
        parameters.discount ^ parameters.duration *
          parameters.survival ^ parameters.duration *
          parameters.admission * parameters.rewardCap -
          parameters.researchCost) ∧
    canonicalPruningLoss parameters parameters.rewardCap =
      parameters.discount ^ parameters.duration *
        parameters.survival ^ parameters.duration *
        parameters.admission * parameters.rewardCap -
        parameters.researchCost := by
  constructor
  · intro reward hreward0 hrewardCap
    rw [canonicalPruningLoss, canonicalUnprunedValue_eq,
      canonicalPrunedValue_eq_zero]
    unfold maxAttainableDescendantValue maxAttainableGrossDescendantValue
    simp only [sub_zero]
    rw [max_le_iff]
    constructor
    · linarith [parameters.researchWorthwhile]
    · have hfactor :
        0 ≤ parameters.discount ^ parameters.duration *
          parameters.survival ^ parameters.duration *
          parameters.admission := by
        exact mul_nonneg
          (mul_nonneg
            (pow_nonneg parameters.discount_nonnegative _)
            (pow_nonneg parameters.survival_nonnegative _))
          parameters.admission_nonnegative
      nlinarith
  · exact canonicalPruningLoss_exact parameters

/--
Frontier-only pruning destroys all net attainable descendant value.  The ratio
is exactly one whenever that net opportunity is strictly positive.
-/
theorem destroys_all_attainable_descendant_value
    (parameters : Parameters)
    (hpositive : 0 <
      maxAttainableDescendantValue parameters parameters.rewardCap) :
    canonicalPruningLoss parameters parameters.rewardCap /
        maxAttainableDescendantValue parameters parameters.rewardCap = 1 := by
  rw [canonicalPruningLoss_exact]
  unfold maxAttainableDescendantValue maxAttainableGrossDescendantValue
  exact div_self (ne_of_gt hpositive)

/--
With rewards normalized by cap one, the exact loss is at most one.  Thus the
primary T4 theorem does not require unbounded rewards.
-/
theorem unitRewardCap_loss_le_one
    (parameters : Parameters) (hcap : parameters.rewardCap ≤ 1) :
    canonicalPruningLoss parameters parameters.rewardCap ≤ 1 := by
  rw [canonicalPruningLoss_exact]
  have hdiscountPow :
      parameters.discount ^ parameters.duration ≤ 1 :=
    pow_le_one₀ parameters.discount_nonnegative parameters.discount_lt_one.le
  have hsurvivalPow :
      parameters.survival ^ parameters.duration ≤ 1 :=
    pow_le_one₀ parameters.survival_nonnegative parameters.survival_le_one
  have hdiscountPow0 :
      0 ≤ parameters.discount ^ parameters.duration :=
    pow_nonneg parameters.discount_nonnegative _
  have hsurvivalPow0 :
      0 ≤ parameters.survival ^ parameters.duration :=
    pow_nonneg parameters.survival_nonnegative _
  have hdiscountSurvival0 :
      0 ≤ parameters.discount ^ parameters.duration *
        parameters.survival ^ parameters.duration :=
    mul_nonneg hdiscountPow0 hsurvivalPow0
  have hdiscountSurvival1 :
      parameters.discount ^ parameters.duration *
          parameters.survival ^ parameters.duration ≤ 1 :=
    mul_le_one₀ hdiscountPow hsurvivalPow0 hsurvivalPow
  have hfactor0 :
      0 ≤ parameters.discount ^ parameters.duration *
          parameters.survival ^ parameters.duration * parameters.admission :=
    mul_nonneg hdiscountSurvival0 parameters.admission_nonnegative
  have hfactor1 :
      parameters.discount ^ parameters.duration *
          parameters.survival ^ parameters.duration * parameters.admission ≤ 1 :=
    mul_le_one₀ hdiscountSurvival1 parameters.admission_nonnegative
      parameters.admission_le_one
  have hgross1 :
      parameters.discount ^ parameters.duration *
          parameters.survival ^ parameters.duration * parameters.admission *
          parameters.rewardCap ≤ 1 :=
    mul_le_one₀ hfactor1 parameters.rewardCap_nonnegative hcap
  linarith [parameters.researchCost_nonnegative]

/--
Arbitrarily large loss follows only by scaling the reward cap.  This corollary
sets `β = 1/2`, `ρ = π = 1`, cost zero, and reward cap `2 * target`.
-/
theorem arbitraryLoss_by_rewardScaling (target : ℚ) (htarget : 0 ≤ target) :
    ∃ parameters : Parameters,
      parameters.rewardCap = 2 * target ∧
      canonicalPruningLoss parameters parameters.rewardCap = target := by
  let parameters : Parameters :=
    { duration := 1
      duration_positive := by norm_num
      discount := 1 / 2
      discount_nonnegative := by norm_num
      discount_lt_one := by norm_num
      survival := 1
      survival_nonnegative := by norm_num
      survival_le_one := by norm_num
      admission := 1
      admission_nonnegative := by norm_num
      admission_le_one := by norm_num
      rewardCap := 2 * target
      rewardCap_nonnegative := by positivity
      researchCost := 0
      researchCost_nonnegative := by norm_num
      researchWorthwhile := by
        norm_num
        exact htarget }
  refine ⟨parameters, rfl, ?_⟩
  rw [canonicalPruningLoss_exact]
  simp [parameters]

/--
If operation continues during research, the pruning-loss formula gains the
difference between the two incumbent operating-reward blocks.
-/
noncomputable def canonicalPruningLossWithOperation
    (parameters : Parameters) (reward operatingRewardDifference : ℚ) : ℚ :=
  canonicalPruningLoss parameters reward + operatingRewardDifference

theorem canonicalPruningLossWithOperation_exact
    (parameters : Parameters) (operatingRewardDifference : ℚ) :
    canonicalPruningLossWithOperation parameters parameters.rewardCap
        operatingRewardDifference =
      parameters.discount ^ parameters.duration *
        parameters.survival ^ parameters.duration *
        parameters.admission * parameters.rewardCap -
        parameters.researchCost + operatingRewardDifference := by
  rw [canonicalPruningLossWithOperation, canonicalPruningLoss_exact]

/--
For operationally redundant deletion, continued operation has the same
incumbent block on both sides, so its difference is zero and T4 is unchanged.
-/
theorem continuedOperation_cancels_under_operationalRedundancy
    (parameters : Parameters) :
    canonicalPruningLossWithOperation parameters parameters.rewardCap 0 =
      parameters.discount ^ parameters.duration *
        parameters.survival ^ parameters.duration *
        parameters.admission * parameters.rewardCap -
        parameters.researchCost := by
  rw [canonicalPruningLossWithOperation_exact]
  ring

end NormalizedPruningLoss

end Model

end Projection

end StrategyInnovation
