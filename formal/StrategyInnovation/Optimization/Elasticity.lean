import StrategyInnovation.Optimization.PenalizedEnvelope

/-!
# Shared real-parameter elasticity algebra

This module fixes the normalization used by the manuscript-facing elasticity
results.  The definitions are deliberately algebraic: calculus modules supply
verified derivatives, while these lemmas turn them into scaled derivatives,
point elasticities, and total-normalized signed contributions.
-/

namespace StrategyInnovation

namespace Optimization

/-- A derivative scaled by the parameter level, without division by an output. -/
def scaledDerivative (parameter derivative : ℝ) : ℝ :=
  parameter * derivative

/-- Point elasticity `x f'(x) / f(x)` at supplied real data. -/
noncomputable def pointElasticity (parameter level derivative : ℝ) : ℝ :=
  parameter * derivative / level

/-- A channel's scaled derivative normalized by the total level. -/
noncomputable def normalizedContribution
    (parameter totalLevel channelDerivative : ℝ) : ℝ :=
  parameter * channelDerivative / totalLevel

/-- Point elasticity is scaled derivative divided by the level. -/
theorem pointElasticity_eq_scaledDerivative_div
    (parameter level derivative : ℝ) :
    pointElasticity parameter level derivative =
      scaledDerivative parameter derivative / level :=
  rfl

/-- Scaling distributes across an exact derivative decomposition. -/
theorem scaledDerivative_add
    (parameter leftDerivative rightDerivative : ℝ) :
    scaledDerivative parameter (leftDerivative + rightDerivative) =
      scaledDerivative parameter leftDerivative +
        scaledDerivative parameter rightDerivative := by
  simp [scaledDerivative, mul_add]

/-- Signed total-normalized contributions add with no sign assumptions. -/
theorem normalizedContribution_add
    (parameter totalLevel leftDerivative rightDerivative : ℝ) :
    normalizedContribution parameter totalLevel
        (leftDerivative + rightDerivative) =
      normalizedContribution parameter totalLevel leftDerivative +
        normalizedContribution parameter totalLevel rightDerivative := by
  simp [normalizedContribution, mul_add, add_div]

/-- Under an exact derivative sum, elasticity equals summed contributions. -/
theorem pointElasticity_eq_contribution_sum
    {parameter totalLevel totalDerivative leftDerivative rightDerivative : ℝ}
    (hderivative : totalDerivative = leftDerivative + rightDerivative) :
    pointElasticity parameter totalLevel totalDerivative =
      normalizedContribution parameter totalLevel leftDerivative +
        normalizedContribution parameter totalLevel rightDerivative := by
  rw [hderivative]
  exact normalizedContribution_add parameter totalLevel
    leftDerivative rightDerivative

end Optimization

end StrategyInnovation
