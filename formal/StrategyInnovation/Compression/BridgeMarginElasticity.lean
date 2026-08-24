import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Topology.Algebra.Order.Field
import StrategyInnovation.Optimization.Elasticity

/-!
# Bridge-margin derivatives and elasticities

The realized bridge loss is the positive part of gross bridge exposure minus
the threshold cost.  Calculus statements are made only at strictly positive
margins, where continuity supplies a neighborhood on which the positive part
is exactly the signed margin.
-/

namespace StrategyInnovation

namespace Compression

open Filter
open scoped Topology

/-- Gross bridge exposure `β^d ρ^d π C`. -/
def grossBridge
    (duration : ℕ) (discount survival probability consequence : ℝ) : ℝ :=
  discount ^ duration * survival ^ duration * probability * consequence

/-- Signed bridge margin before taking the positive part. -/
def bridgeMargin
    (duration : ℕ) (discount survival probability consequence threshold : ℝ) : ℝ :=
  grossBridge duration discount survival probability consequence - threshold

/-- Realized bridge loss, with inactive nonpositive margins truncated to zero. -/
def bridgeLoss
    (duration : ℕ) (discount survival probability consequence threshold : ℝ) : ℝ :=
  max (bridgeMargin duration discount survival probability consequence threshold) 0

/-- Positive-margin truncation is locally invisible to differentiation. -/
theorem hasDerivAt_max_zero_of_pos
    {f : ℝ → ℝ} {derivative point : ℝ}
    (hf : HasDerivAt f derivative point) (hpositive : 0 < f point) :
    HasDerivAt (fun x => max (f x) 0) derivative point := by
  apply hf.congr_of_eventuallyEq
  have heventually : ∀ᶠ x in nhds point, 0 < f x :=
    hf.continuousAt.eventually (isOpen_Ioi.mem_nhds hpositive)
  filter_upwards [heventually] with x hx
  exact max_eq_left hx.le

/-- Derivative of the signed margin with respect to discount. -/
theorem hasDerivAt_bridgeMargin_discount
    (duration : ℕ) (discount survival probability consequence threshold : ℝ) :
    HasDerivAt
      (fun x => bridgeMargin duration x survival probability consequence threshold)
      ((duration : ℝ) * discount ^ (duration - 1) *
        survival ^ duration * probability * consequence)
      discount := by
  have hscaled : HasDerivAt
      (fun x : ℝ => x ^ duration *
        (survival ^ duration * probability * consequence))
      ((duration : ℝ) * discount ^ (duration - 1) *
        (survival ^ duration * probability * consequence)) discount := by
    simpa only [Pi.pow_apply, id_eq, mul_one] using
      ((hasDerivAt_id' discount).pow duration).mul_const
        (survival ^ duration * probability * consequence)
  have hmargin : HasDerivAt
      (fun x : ℝ => x ^ duration *
        (survival ^ duration * probability * consequence) - threshold)
      ((duration : ℝ) * discount ^ (duration - 1) *
        (survival ^ duration * probability * consequence)) discount :=
    hscaled.sub_const threshold
  rw [show
    (duration : ℝ) * discount ^ (duration - 1) *
        survival ^ duration * probability * consequence =
      (duration : ℝ) * discount ^ (duration - 1) *
        (survival ^ duration * probability * consequence) by ring]
  apply hmargin.congr_of_eventuallyEq
  filter_upwards with x
  simp only [bridgeMargin, grossBridge]
  ring

/-- Derivative of the signed margin with respect to survival. -/
theorem hasDerivAt_bridgeMargin_survival
    (duration : ℕ) (discount survival probability consequence threshold : ℝ) :
    HasDerivAt
      (fun x => bridgeMargin duration discount x probability consequence threshold)
      ((duration : ℝ) * survival ^ (duration - 1) *
        discount ^ duration * probability * consequence)
      survival := by
  have hscaled : HasDerivAt
      (fun x : ℝ => discount ^ duration * x ^ duration *
        (probability * consequence))
      ((duration : ℝ) * survival ^ (duration - 1) *
        discount ^ duration * probability * consequence) survival := by
    simpa only [Pi.pow_apply, id_eq, mul_one, mul_assoc, mul_comm,
      mul_left_comm] using
        ((((hasDerivAt_id' survival).pow duration).const_mul
          (discount ^ duration)).mul_const (probability * consequence))
  have hmargin : HasDerivAt
      (fun x : ℝ => discount ^ duration * x ^ duration *
        (probability * consequence) - threshold)
      ((duration : ℝ) * survival ^ (duration - 1) *
        discount ^ duration * probability * consequence) survival :=
    hscaled.sub_const threshold
  apply hmargin.congr_of_eventuallyEq
  filter_upwards with x
  simp only [bridgeMargin, grossBridge]
  ring

/-- Derivative of the signed margin with respect to event probability. -/
theorem hasDerivAt_bridgeMargin_probability
    (duration : ℕ) (discount survival probability consequence threshold : ℝ) :
    HasDerivAt
      (fun x => bridgeMargin duration discount survival x consequence threshold)
      (discount ^ duration * survival ^ duration * consequence)
      probability := by
  have hlinear : HasDerivAt
      (fun x : ℝ => discount ^ duration * survival ^ duration * x * consequence)
      (discount ^ duration * survival ^ duration * consequence) probability := by
    simpa only [id_eq, mul_one] using
      (((hasDerivAt_id' probability).const_mul
        (discount ^ duration * survival ^ duration)).mul_const consequence)
  have hmargin : HasDerivAt
      (fun x : ℝ => discount ^ duration * survival ^ duration * x * consequence -
        threshold)
      (discount ^ duration * survival ^ duration * consequence) probability :=
    hlinear.sub_const threshold
  simpa only [bridgeMargin, grossBridge] using hmargin

/-- Derivative of the signed margin with respect to consequence. -/
theorem hasDerivAt_bridgeMargin_consequence
    (duration : ℕ) (discount survival probability consequence threshold : ℝ) :
    HasDerivAt
      (fun x => bridgeMargin duration discount survival probability x threshold)
      (discount ^ duration * survival ^ duration * probability)
      consequence := by
  have hlinear : HasDerivAt
      (fun x : ℝ => discount ^ duration * survival ^ duration * probability * x)
      (discount ^ duration * survival ^ duration * probability) consequence := by
    simpa only [id_eq, mul_one] using
      (hasDerivAt_id' consequence).const_mul
        (discount ^ duration * survival ^ duration * probability)
  have hmargin : HasDerivAt
      (fun x : ℝ => discount ^ duration * survival ^ duration * probability * x -
        threshold)
      (discount ^ duration * survival ^ duration * probability) consequence :=
    hlinear.sub_const threshold
  simpa only [bridgeMargin, grossBridge] using hmargin

/-- Derivative of the signed margin with respect to the threshold. -/
theorem hasDerivAt_bridgeMargin_threshold
    (duration : ℕ) (discount survival probability consequence threshold : ℝ) :
    HasDerivAt
      (fun x => bridgeMargin duration discount survival probability consequence x)
      (-1) threshold := by
  have hlinear : HasDerivAt (fun x : ℝ => (-1) * x) (-1) threshold := by
    simpa using (hasDerivAt_id' threshold).const_mul (-1)
  have haffine : HasDerivAt
      (fun x : ℝ => (-1) * x +
        grossBridge duration discount survival probability consequence)
      (-1) threshold :=
    hlinear.add_const
      (grossBridge duration discount survival probability consequence)
  apply haffine.congr_of_eventuallyEq
  filter_upwards with x
  simp only [bridgeMargin]
  ring

/-- On a positive margin, realized bridge-loss sensitivity to discount. -/
theorem hasDerivAt_bridgeLoss_discount
    (duration : ℕ) (discount survival probability consequence threshold : ℝ)
    (hpositive :
      0 < bridgeMargin duration discount survival probability consequence threshold) :
    HasDerivAt
      (fun x => bridgeLoss duration x survival probability consequence threshold)
      ((duration : ℝ) * discount ^ (duration - 1) *
        survival ^ duration * probability * consequence)
      discount :=
  hasDerivAt_max_zero_of_pos
    (hasDerivAt_bridgeMargin_discount duration discount survival probability
      consequence threshold) hpositive

/-- On a positive margin, realized bridge-loss sensitivity to survival. -/
theorem hasDerivAt_bridgeLoss_survival
    (duration : ℕ) (discount survival probability consequence threshold : ℝ)
    (hpositive :
      0 < bridgeMargin duration discount survival probability consequence threshold) :
    HasDerivAt
      (fun x => bridgeLoss duration discount x probability consequence threshold)
      ((duration : ℝ) * survival ^ (duration - 1) *
        discount ^ duration * probability * consequence)
      survival :=
  hasDerivAt_max_zero_of_pos
    (hasDerivAt_bridgeMargin_survival duration discount survival probability
      consequence threshold) hpositive

/-- On a positive margin, realized bridge-loss sensitivity to probability. -/
theorem hasDerivAt_bridgeLoss_probability
    (duration : ℕ) (discount survival probability consequence threshold : ℝ)
    (hpositive :
      0 < bridgeMargin duration discount survival probability consequence threshold) :
    HasDerivAt
      (fun x => bridgeLoss duration discount survival x consequence threshold)
      (discount ^ duration * survival ^ duration * consequence)
      probability :=
  hasDerivAt_max_zero_of_pos
    (hasDerivAt_bridgeMargin_probability duration discount survival probability
      consequence threshold) hpositive

/-- On a positive margin, realized bridge-loss sensitivity to consequence. -/
theorem hasDerivAt_bridgeLoss_consequence
    (duration : ℕ) (discount survival probability consequence threshold : ℝ)
    (hpositive :
      0 < bridgeMargin duration discount survival probability consequence threshold) :
    HasDerivAt
      (fun x => bridgeLoss duration discount survival probability x threshold)
      (discount ^ duration * survival ^ duration * probability)
      consequence :=
  hasDerivAt_max_zero_of_pos
    (hasDerivAt_bridgeMargin_consequence duration discount survival probability
      consequence threshold) hpositive

/-- On a positive margin, realized bridge-loss sensitivity to the threshold. -/
theorem hasDerivAt_bridgeLoss_threshold
    (duration : ℕ) (discount survival probability consequence threshold : ℝ)
    (hpositive :
      0 < bridgeMargin duration discount survival probability consequence threshold) :
    HasDerivAt
      (fun x => bridgeLoss duration discount survival probability consequence x)
      (-1) threshold :=
  hasDerivAt_max_zero_of_pos
    (hasDerivAt_bridgeMargin_threshold duration discount survival probability
      consequence threshold) hpositive

/-- Margin normalized by gross bridge exposure. -/
noncomputable def normalizedBridgeMargin
    (duration : ℕ) (discount survival probability consequence threshold : ℝ) : ℝ :=
  bridgeMargin duration discount survival probability consequence threshold /
    grossBridge duration discount survival probability consequence

/-- Gross-to-margin amplification. -/
noncomputable def bridgeFragility
    (duration : ℕ) (discount survival probability consequence threshold : ℝ) : ℝ :=
  grossBridge duration discount survival probability consequence /
    bridgeMargin duration discount survival probability consequence threshold

/-- Discount elasticity on the positive-margin branch is `d A / M`. -/
theorem bridgeLoss_discount_elasticity
    {duration : ℕ} (hduration : 1 ≤ duration)
    (discount survival probability consequence threshold : ℝ) :
    Optimization.pointElasticity discount
        (bridgeMargin duration discount survival probability consequence threshold)
        ((duration : ℝ) * discount ^ (duration - 1) *
          survival ^ duration * probability * consequence) =
      (duration : ℝ) *
        bridgeFragility duration discount survival probability consequence threshold := by
  have hpow : discount ^ duration = discount ^ (duration - 1) * discount := by
    conv_lhs => rw [← Nat.sub_add_cancel hduration]
    rw [pow_succ]
  simp only [Optimization.pointElasticity, bridgeFragility, grossBridge]
  rw [hpow]
  ring

/-- Survival elasticity on the positive-margin branch is `d A / M`. -/
theorem bridgeLoss_survival_elasticity
    {duration : ℕ} (hduration : 1 ≤ duration)
    (discount survival probability consequence threshold : ℝ) :
    Optimization.pointElasticity survival
        (bridgeMargin duration discount survival probability consequence threshold)
        ((duration : ℝ) * survival ^ (duration - 1) *
          discount ^ duration * probability * consequence) =
      (duration : ℝ) *
        bridgeFragility duration discount survival probability consequence threshold := by
  have hpow : survival ^ duration = survival ^ (duration - 1) * survival := by
    conv_lhs => rw [← Nat.sub_add_cancel hduration]
    rw [pow_succ]
  simp only [Optimization.pointElasticity, bridgeFragility, grossBridge]
  rw [hpow]
  ring

/-- Probability elasticity on the positive-margin branch is `A / M`. -/
theorem bridgeLoss_probability_elasticity
    (duration : ℕ) (discount survival probability consequence threshold : ℝ) :
    Optimization.pointElasticity probability
        (bridgeMargin duration discount survival probability consequence threshold)
        (discount ^ duration * survival ^ duration * consequence) =
      bridgeFragility duration discount survival probability consequence threshold := by
  simp [Optimization.pointElasticity, bridgeFragility, grossBridge]
  ring

/-- Consequence elasticity on the positive-margin branch is `A / M`. -/
theorem bridgeLoss_consequence_elasticity
    (duration : ℕ) (discount survival probability consequence threshold : ℝ) :
    Optimization.pointElasticity consequence
        (bridgeMargin duration discount survival probability consequence threshold)
        (discount ^ duration * survival ^ duration * probability) =
      bridgeFragility duration discount survival probability consequence threshold := by
  simp [Optimization.pointElasticity, bridgeFragility, grossBridge]
  ring

/-- Threshold elasticity on the positive-margin branch is `-κ / M`. -/
theorem bridgeLoss_threshold_elasticity
    (duration : ℕ) (discount survival probability consequence threshold : ℝ) :
    Optimization.pointElasticity threshold
        (bridgeMargin duration discount survival probability consequence threshold) (-1) =
      -threshold /
        bridgeMargin duration discount survival probability consequence threshold := by
  simp [Optimization.pointElasticity]

/-- Fragility is the inverse normalized margin whenever gross exposure is nonzero. -/
theorem bridgeFragility_eq_inv_normalizedMargin
    (duration : ℕ) (discount survival probability consequence threshold : ℝ)
    (hgross : grossBridge duration discount survival probability consequence ≠ 0) :
    bridgeFragility duration discount survival probability consequence threshold =
      (normalizedBridgeMargin duration discount survival probability consequence threshold)⁻¹ := by
  simp only [bridgeFragility, normalizedBridgeMargin]
  field_simp

/-- Inverse normalized margin diverges as the positive normalized margin tends to zero. -/
theorem normalizedMargin_fragility_tendsto_atTop :
    Tendsto (fun margin : ℝ => margin⁻¹)
      (nhdsWithin (0 : ℝ) (Set.Ioi 0)) atTop :=
  tendsto_inv_nhdsGT_zero

/--
For a fixed positive threshold, its elasticity `-κ / M` tends to negative
infinity as the positive margin `M` approaches zero from the right.
-/
theorem positiveMargin_thresholdElasticity_tendsto_atBot
    {threshold : ℝ} (hthreshold : 0 < threshold) :
    Tendsto (fun margin : ℝ => -threshold / margin)
      (nhdsWithin (0 : ℝ) (Set.Ioi 0)) atBot := by
  have hscaled :
      Tendsto (fun margin : ℝ => (-threshold) * margin⁻¹)
        (nhdsWithin (0 : ℝ) (Set.Ioi 0)) atBot :=
    Tendsto.const_mul_atTop_of_neg (neg_lt_zero.mpr hthreshold)
      normalizedMargin_fragility_tendsto_atTop
  simpa only [div_eq_mul_inv] using hscaled

/--
For fixed positive gross exposure, gross divided by the shrinking positive
margin `gross * m` diverges as the normalized margin `m → 0+`.
-/
theorem fixedGross_fragility_tendsto_atTop {gross : ℝ} (hgross : 0 < gross) :
    Tendsto (fun margin : ℝ => gross / (gross * margin))
      (nhdsWithin (0 : ℝ) (Set.Ioi 0)) atTop := by
  apply normalizedMargin_fragility_tendsto_atTop.congr'
  filter_upwards [self_mem_nhdsWithin] with margin hmargin
  have hmargin_ne : margin ≠ 0 := ne_of_gt hmargin
  field_simp [ne_of_gt hgross, hmargin_ne]

/-- Vanishing gross scale with zero threshold keeps fragility equal to one. -/
theorem costless_vanishingGross_fragility_eq_one {gross : ℝ}
    (hgross : gross ≠ 0) :
    gross / (gross - 0) = 1 := by
  simpa using div_self hgross

namespace BridgeExample

/-- Exact example gross exposure: `(½)^2 · 1^2 · 1 · 8 = 2`. -/
theorem gross_exact : grossBridge 2 (1 / 2) 1 1 8 = 2 := by
  norm_num [grossBridge]

/-- Exact example signed and realized margin. -/
theorem margin_exact : bridgeMargin 2 (1 / 2) 1 1 8 1 = 1 := by
  norm_num [bridgeMargin, grossBridge]

theorem loss_exact : bridgeLoss 2 (1 / 2) 1 1 8 1 = 1 := by
  norm_num [bridgeLoss, bridgeMargin, grossBridge]

/-- Exact normalized margin and fragility. -/
theorem normalizedMargin_exact : normalizedBridgeMargin 2 (1 / 2) 1 1 8 1 = 1 / 2 := by
  norm_num [normalizedBridgeMargin, bridgeMargin, grossBridge]

theorem fragility_exact : bridgeFragility 2 (1 / 2) 1 1 8 1 = 2 := by
  norm_num [bridgeFragility, bridgeMargin, grossBridge]

/-- Exact discount/survival, probability/consequence, and threshold elasticities. -/
theorem discount_elasticity_exact :
    Optimization.pointElasticity (1 / 2) 1 8 = 4 := by
  norm_num [Optimization.pointElasticity]

theorem probability_elasticity_exact :
    Optimization.pointElasticity 1 1 2 = 2 := by
  norm_num [Optimization.pointElasticity]

theorem threshold_elasticity_exact :
    Optimization.pointElasticity 1 1 (-1) = -1 := by
  norm_num [Optimization.pointElasticity]

end BridgeExample

end Compression

end StrategyInnovation
