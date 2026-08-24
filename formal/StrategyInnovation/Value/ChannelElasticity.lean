import Mathlib.Analysis.Calculus.Deriv.Add
import StrategyInnovation.Optimization.Elasticity

/-!
# Operational and generative channel elasticity

The accounting identity is required on a neighborhood of the evaluation
point, so differentiation is legitimate.  Signed contribution identities do
not require positivity.  Positivity is introduced only for the usual
weighted-average interpretation in terms of positive levels and shares.
-/

namespace StrategyInnovation

namespace Value

open Filter

/-- Local accounting identity for total, operational, and generative value. -/
def ChannelAccountingAt
    (total operational generative : ℝ → ℝ) (parameter : ℝ) : Prop :=
  total =ᶠ[nhds parameter] fun x => operational x + generative x

/-- Local accounting and verified channel derivatives imply derivative additivity. -/
theorem operational_generative_derivative_decomposition
    {total operational generative : ℝ → ℝ}
    {parameter totalDerivative operationalDerivative generativeDerivative : ℝ}
    (haccounting : ChannelAccountingAt total operational generative parameter)
    (htotal : HasDerivAt total totalDerivative parameter)
    (hoperational : HasDerivAt operational operationalDerivative parameter)
    (hgenerative : HasDerivAt generative generativeDerivative parameter) :
    totalDerivative = operationalDerivative + generativeDerivative := by
  calc
    totalDerivative = deriv total parameter := htotal.deriv.symm
    _ = deriv (fun x => operational x + generative x) parameter :=
      haccounting.deriv_eq
    _ = deriv operational parameter + deriv generative parameter :=
      deriv_fun_add hoperational.differentiableAt hgenerative.differentiableAt
    _ = operationalDerivative + generativeDerivative := by
      rw [hoperational.deriv, hgenerative.deriv]

/-- The local accounting identity holds at the evaluation point itself. -/
theorem channel_level_decomposition
    {total operational generative : ℝ → ℝ} {parameter : ℝ}
    (haccounting : ChannelAccountingAt total operational generative parameter) :
    total parameter = operational parameter + generative parameter :=
  haccounting.self_of_nhds

/-- Scaled derivatives decompose without any level or sign assumption. -/
theorem operational_generative_scaledDerivative_decomposition
    {parameter totalDerivative operationalDerivative generativeDerivative : ℝ}
    (hderivative : totalDerivative =
      operationalDerivative + generativeDerivative) :
    Optimization.scaledDerivative parameter totalDerivative =
      Optimization.scaledDerivative parameter operationalDerivative +
        Optimization.scaledDerivative parameter generativeDerivative := by
  rw [hderivative]
  exact Optimization.scaledDerivative_add parameter
    operationalDerivative generativeDerivative

/--
Total elasticity equals the sum of total-normalized signed channel
contributions.  This algebraic identity requires no positivity assumption.
-/
theorem operational_generative_contribution_decomposition
    {parameter totalLevel totalDerivative operationalDerivative
      generativeDerivative : ℝ}
    (hderivative : totalDerivative =
      operationalDerivative + generativeDerivative) :
    Optimization.pointElasticity parameter totalLevel totalDerivative =
      Optimization.normalizedContribution parameter totalLevel
          operationalDerivative +
        Optimization.normalizedContribution parameter totalLevel
          generativeDerivative :=
  Optimization.pointElasticity_eq_contribution_sum hderivative

/-- Positive operational and generative levels define positive shares. -/
theorem positive_channel_shares
    {totalLevel operationalLevel generativeLevel : ℝ}
    (hlevel : totalLevel = operationalLevel + generativeLevel)
    (hoperational : 0 < operationalLevel)
    (hgenerative : 0 < generativeLevel) :
    0 < operationalLevel / totalLevel ∧
      0 < generativeLevel / totalLevel ∧
      operationalLevel / totalLevel + generativeLevel / totalLevel = 1 := by
  have htotal : 0 < totalLevel := by rw [hlevel]; positivity
  refine ⟨div_pos hoperational htotal, div_pos hgenerative htotal, ?_⟩
  rw [← add_div, ← hlevel, div_self (ne_of_gt htotal)]

/-- Under positive levels, total elasticity is the share-weighted channel average. -/
theorem operational_generative_weightedAverage_elasticity
    {parameter totalLevel operationalLevel generativeLevel totalDerivative
      operationalDerivative generativeDerivative : ℝ}
    (hlevel : totalLevel = operationalLevel + generativeLevel)
    (hderivative : totalDerivative =
      operationalDerivative + generativeDerivative)
    (hoperational : 0 < operationalLevel)
    (hgenerative : 0 < generativeLevel) :
    Optimization.pointElasticity parameter totalLevel totalDerivative =
      (operationalLevel / totalLevel) *
          Optimization.pointElasticity parameter operationalLevel
            operationalDerivative +
        (generativeLevel / totalLevel) *
          Optimization.pointElasticity parameter generativeLevel
            generativeDerivative := by
  have htotal : 0 < totalLevel := by rw [hlevel]; positivity
  simp only [Optimization.pointElasticity]
  field_simp [ne_of_gt htotal, ne_of_gt hoperational, ne_of_gt hgenerative]
  rw [hderivative]

/-- Verified local channel calculus implies the signed contribution identity. -/
theorem operational_generative_contribution_decomposition_of_hasDerivAt
    {total operational generative : ℝ → ℝ}
    {parameter totalDerivative operationalDerivative generativeDerivative : ℝ}
    (haccounting : ChannelAccountingAt total operational generative parameter)
    (htotal : HasDerivAt total totalDerivative parameter)
    (hoperational : HasDerivAt operational operationalDerivative parameter)
    (hgenerative : HasDerivAt generative generativeDerivative parameter) :
    Optimization.pointElasticity parameter (total parameter) totalDerivative =
      Optimization.normalizedContribution parameter (total parameter)
          operationalDerivative +
        Optimization.normalizedContribution parameter (total parameter)
          generativeDerivative := by
  apply operational_generative_contribution_decomposition
  exact operational_generative_derivative_decomposition haccounting htotal
    hoperational hgenerative

namespace ChannelElasticityExamples

def operationalPositive (x : ℝ) : ℝ := 100 + x
def generativePositive (x : ℝ) : ℝ := 1 + 10 * x
def totalPositive (x : ℝ) : ℝ := 101 + 11 * x

theorem positive_accounting (x : ℝ) :
    totalPositive x = operationalPositive x + generativePositive x := by
  simp [totalPositive, operationalPositive, generativePositive]
  ring

theorem deriv_operationalPositive (x : ℝ) :
    deriv operationalPositive x = 1 := by
  change deriv (fun y : ℝ => 100 + y) x = 1
  exact ((hasDerivAt_id' x).const_add 100).deriv

theorem deriv_generativePositive (x : ℝ) :
    deriv generativePositive x = 10 := by
  have hlinear : HasDerivAt (fun y : ℝ => 10 * y) 10 x := by
    simpa using (hasDerivAt_id' x).const_mul 10
  change deriv (fun y : ℝ => 1 + 10 * y) x = 10
  exact (hlinear.const_add 1).deriv

theorem deriv_totalPositive (x : ℝ) :
    deriv totalPositive x = 11 := by
  have hlinear : HasDerivAt (fun y : ℝ => 11 * y) 11 x := by
    simpa using (hasDerivAt_id' x).const_mul 11
  change deriv (fun y : ℝ => 101 + 11 * y) x = 11
  exact (hlinear.const_add 101).deriv

/-- Exact positive-level example at `x = 1`. -/
theorem positive_levels_exact :
    operationalPositive 1 = 101 ∧
    generativePositive 1 = 11 ∧
    totalPositive 1 = 112 := by
  norm_num [operationalPositive, generativePositive, totalPositive]

theorem positive_contributions_exact :
    Optimization.normalizedContribution 1 112 1 = 1 / 112 ∧
    Optimization.normalizedContribution 1 112 10 = 10 / 112 ∧
    Optimization.pointElasticity 1 112 11 = 11 / 112 := by
  norm_num [Optimization.normalizedContribution, Optimization.pointElasticity]

def operationalSigned (x : ℝ) : ℝ := 10 + 4 * x
def generativeSigned (x : ℝ) : ℝ := 10 - 3 * x
def totalSigned (x : ℝ) : ℝ := 20 + x

theorem signed_accounting (x : ℝ) :
    totalSigned x = operationalSigned x + generativeSigned x := by
  simp [totalSigned, operationalSigned, generativeSigned]
  ring

/-- Exact signed example: a negative generative contribution offsets operations. -/
theorem signed_contributions_exact :
    operationalSigned 1 = 14 ∧
    generativeSigned 1 = 7 ∧
    totalSigned 1 = 21 ∧
    Optimization.normalizedContribution 1 21 4 = 4 / 21 ∧
    Optimization.normalizedContribution 1 21 (-3) = -3 / 21 ∧
    Optimization.pointElasticity 1 21 1 = 1 / 21 := by
  norm_num [operationalSigned, generativeSigned, totalSigned,
    Optimization.normalizedContribution, Optimization.pointElasticity]

def operationalZero (_ : ℝ) : ℝ := 0
def generativeOnly (x : ℝ) : ℝ := x
def totalGenerativeOnly (x : ℝ) : ℝ := x

/-- Contribution accounting remains exact when a channel level is zero. -/
theorem zero_operational_level_exact :
    operationalZero 1 = 0 ∧
    generativeOnly 1 = 1 ∧
    totalGenerativeOnly 1 = 1 ∧
    Optimization.normalizedContribution 1 1 0 = 0 ∧
    Optimization.normalizedContribution 1 1 1 = 1 ∧
    Optimization.pointElasticity 1 1 1 = 1 := by
  norm_num [operationalZero, generativeOnly, totalGenerativeOnly,
    Optimization.normalizedContribution, Optimization.pointElasticity]

end ChannelElasticityExamples

end Value

end StrategyInnovation
