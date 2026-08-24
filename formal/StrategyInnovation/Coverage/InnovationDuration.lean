import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Algebra.BigOperators.Field
import StrategyInnovation.Optimization.Elasticity

/-!
# Innovation duration and convexity for finite exposure sums

For a finite horizon, the exposure potential is a polynomial in the positive
real persistence parameter.  Its scaled derivative is the first timing
moment.  Differentiating the normalized first moment gives the normalized
second central moment, exactly as in the duration/convexity identities.
-/

namespace StrategyInnovation

namespace Coverage

/-- Finite innovation exposure potential `Ψ_H(α; z)`. -/
def innovationPotential (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ) : ℝ :=
  ∑ time ∈ Finset.range horizon, persistence ^ time * exposure time

/-- Unnormalized first timing moment. -/
def innovationFirstMoment
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ) : ℝ :=
  ∑ time ∈ Finset.range horizon,
    (time : ℝ) * persistence ^ time * exposure time

/-- Unnormalized second timing moment. -/
def innovationSecondMoment
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ) : ℝ :=
  ∑ time ∈ Finset.range horizon,
    (time : ℝ) ^ 2 * persistence ^ time * exposure time

/-- The explicit derivative polynomial for the potential. -/
def innovationPotentialDerivative
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ) : ℝ :=
  ∑ time ∈ Finset.range horizon,
    (time : ℝ) * persistence ^ (time - 1) * exposure time

/-- The explicit derivative polynomial for the first moment. -/
def innovationFirstMomentDerivative
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ) : ℝ :=
  ∑ time ∈ Finset.range horizon,
    (time : ℝ) ^ 2 * persistence ^ (time - 1) * exposure time

/-- Innovation duration: normalized first timing moment. -/
noncomputable def innovationDuration
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ) : ℝ :=
  innovationFirstMoment horizon exposure persistence /
    innovationPotential horizon exposure persistence

/-- Normalized exposure weight at a date. -/
noncomputable def innovationWeight
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ)
    (time : ℕ) : ℝ :=
  persistence ^ time * exposure time /
    innovationPotential horizon exposure persistence

/-- Innovation convexity as the normalized timing variance. -/
noncomputable def innovationConvexity
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ) : ℝ :=
  ∑ time ∈ Finset.range horizon,
    innovationWeight horizon exposure persistence time *
      ((time : ℝ) - innovationDuration horizon exposure persistence) ^ 2

/-- Algebraic second-moment expression for the timing variance. -/
noncomputable def innovationTimingVariance
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ) : ℝ :=
  innovationSecondMoment horizon exposure persistence /
      innovationPotential horizon exposure persistence -
    innovationDuration horizon exposure persistence ^ 2

/-- The finite exposure potential has the displayed polynomial derivative. -/
theorem hasDerivAt_innovationPotential
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ) :
    HasDerivAt (innovationPotential horizon exposure)
      (innovationPotentialDerivative horizon exposure persistence) persistence := by
  unfold innovationPotential innovationPotentialDerivative
  apply HasDerivAt.fun_sum
  intro time _
  simpa only [Pi.pow_apply, id_eq, mul_one] using
    ((hasDerivAt_id' persistence).pow time).mul_const (exposure time)

/-- The finite first moment has the displayed polynomial derivative. -/
theorem hasDerivAt_innovationFirstMoment
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ) :
    HasDerivAt (innovationFirstMoment horizon exposure)
      (innovationFirstMomentDerivative horizon exposure persistence) persistence := by
  unfold innovationFirstMoment innovationFirstMomentDerivative
  apply HasDerivAt.fun_sum
  intro time _
  have hterm :=
    (((hasDerivAt_id' persistence).pow time).const_mul (time : ℝ)).mul_const
      (exposure time)
  simpa only [Pi.pow_apply, id_eq, mul_one, pow_two, mul_assoc] using hterm

/-- Scaled potential derivative equals the first timing moment. -/
theorem scaled_potentialDerivative_eq_firstMoment
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ) :
    persistence * innovationPotentialDerivative horizon exposure persistence =
      innovationFirstMoment horizon exposure persistence := by
  unfold innovationPotentialDerivative innovationFirstMoment
  rw [Finset.mul_sum]
  apply Finset.sum_congr rfl
  intro time _
  cases time with
  | zero => simp
  | succ time =>
      simp only [Nat.cast_add, Nat.cast_one, Nat.add_sub_cancel, pow_succ]
      ring

/-- Scaled first-moment derivative equals the second timing moment. -/
theorem scaled_firstMomentDerivative_eq_secondMoment
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ) :
    persistence * innovationFirstMomentDerivative horizon exposure persistence =
      innovationSecondMoment horizon exposure persistence := by
  unfold innovationFirstMomentDerivative innovationSecondMoment
  rw [Finset.mul_sum]
  apply Finset.sum_congr rfl
  intro time _
  cases time with
  | zero => simp
  | succ time =>
      simp only [Nat.cast_add, Nat.cast_one, Nat.add_sub_cancel, pow_succ]
      ring

/-- Innovation duration is the point elasticity of the finite potential. -/
theorem innovationDuration_identity
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ) :
    Optimization.pointElasticity persistence
        (innovationPotential horizon exposure persistence)
        (innovationPotentialDerivative horizon exposure persistence) =
      innovationDuration horizon exposure persistence := by
  rw [Optimization.pointElasticity, innovationDuration,
    scaled_potentialDerivative_eq_firstMoment]

/-- Normalized finite weights sum to one when the potential is nonzero. -/
theorem sum_innovationWeight_eq_one
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ)
    (hpotential : innovationPotential horizon exposure persistence ≠ 0) :
    ∑ time ∈ Finset.range horizon,
        innovationWeight horizon exposure persistence time = 1 := by
  unfold innovationWeight innovationPotential
  rw [← Finset.sum_div]
  exact div_self hpotential

/-- Duration is the weighted average timing date. -/
theorem sum_time_mul_innovationWeight_eq_duration
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ) :
    ∑ time ∈ Finset.range horizon,
        (time : ℝ) * innovationWeight horizon exposure persistence time =
      innovationDuration horizon exposure persistence := by
  unfold innovationWeight innovationDuration innovationFirstMoment
  calc
    ∑ time ∈ Finset.range horizon,
        (time : ℝ) *
          (persistence ^ time * exposure time /
            innovationPotential horizon exposure persistence) =
      ∑ time ∈ Finset.range horizon,
        ((time : ℝ) * persistence ^ time * exposure time) /
          innovationPotential horizon exposure persistence := by
            apply Finset.sum_congr rfl
            intro time _
            ring
    _ = (∑ time ∈ Finset.range horizon,
          (time : ℝ) * persistence ^ time * exposure time) /
        innovationPotential horizon exposure persistence :=
      (Finset.sum_div _ _ _).symm

/-- A generic finite weighted-variance identity. -/
theorem finite_weighted_variance_identity
    {Index : Type*} (indices : Finset Index) (weight timing : Index → ℝ)
    (mean : ℝ)
    (hweight : ∑ index ∈ indices, weight index = 1)
    (hmean : ∑ index ∈ indices, timing index * weight index = mean) :
    ∑ index ∈ indices,
        weight index * (timing index - mean) ^ 2 =
      (∑ index ∈ indices, timing index ^ 2 * weight index) - mean ^ 2 := by
  calc
    ∑ index ∈ indices, weight index * (timing index - mean) ^ 2 =
        ∑ index ∈ indices,
          (timing index ^ 2 * weight index -
            2 * mean * (timing index * weight index) +
            mean ^ 2 * weight index) := by
              apply Finset.sum_congr rfl
              intro index _
              ring
    _ = (∑ index ∈ indices, timing index ^ 2 * weight index) -
          2 * mean * (∑ index ∈ indices, timing index * weight index) +
          mean ^ 2 * (∑ index ∈ indices, weight index) := by
            simp only [Finset.sum_add_distrib, Finset.sum_sub_distrib,
              ← Finset.mul_sum]
    _ = (∑ index ∈ indices, timing index ^ 2 * weight index) -
          mean ^ 2 := by rw [hweight, hmean]; ring

/-- The normalized second raw moment is the weighted second timing moment. -/
theorem sum_time_sq_mul_innovationWeight
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ) :
    ∑ time ∈ Finset.range horizon,
        (time : ℝ) ^ 2 * innovationWeight horizon exposure persistence time =
      innovationSecondMoment horizon exposure persistence /
        innovationPotential horizon exposure persistence := by
  unfold innovationWeight innovationSecondMoment
  calc
    ∑ time ∈ Finset.range horizon,
        (time : ℝ) ^ 2 *
          (persistence ^ time * exposure time /
            innovationPotential horizon exposure persistence) =
      ∑ time ∈ Finset.range horizon,
        ((time : ℝ) ^ 2 * persistence ^ time * exposure time) /
          innovationPotential horizon exposure persistence := by
            apply Finset.sum_congr rfl
            intro time _
            ring
    _ = (∑ time ∈ Finset.range horizon,
          (time : ℝ) ^ 2 * persistence ^ time * exposure time) /
        innovationPotential horizon exposure persistence :=
      (Finset.sum_div _ _ _).symm

/-- Innovation convexity is exactly normalized timing variance. -/
theorem innovationConvexity_eq_timingVariance
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ)
    (hpotential : innovationPotential horizon exposure persistence ≠ 0) :
    innovationConvexity horizon exposure persistence =
      innovationTimingVariance horizon exposure persistence := by
  unfold innovationConvexity innovationTimingVariance
  rw [finite_weighted_variance_identity
    (Finset.range horizon)
    (innovationWeight horizon exposure persistence)
    (fun time => (time : ℝ))
    (innovationDuration horizon exposure persistence)
    (sum_innovationWeight_eq_one horizon exposure persistence hpotential)
    (sum_time_mul_innovationWeight_eq_duration horizon exposure persistence)]
  rw [sum_time_sq_mul_innovationWeight]

/-- Duration has the exact quotient-rule derivative. -/
theorem hasDerivAt_innovationDuration
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ)
    (hpotential : innovationPotential horizon exposure persistence ≠ 0) :
    HasDerivAt (innovationDuration horizon exposure)
      ((innovationFirstMomentDerivative horizon exposure persistence *
          innovationPotential horizon exposure persistence -
        innovationFirstMoment horizon exposure persistence *
          innovationPotentialDerivative horizon exposure persistence) /
        innovationPotential horizon exposure persistence ^ 2)
      persistence := by
  unfold innovationDuration
  exact
    (hasDerivAt_innovationFirstMoment horizon exposure persistence).fun_div
      (hasDerivAt_innovationPotential horizon exposure persistence) hpotential

/-- Scaled duration derivative is innovation timing variance. -/
theorem scaled_durationDerivative_eq_timingVariance
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ)
    (hpotential : innovationPotential horizon exposure persistence ≠ 0) :
    persistence *
        ((innovationFirstMomentDerivative horizon exposure persistence *
            innovationPotential horizon exposure persistence -
          innovationFirstMoment horizon exposure persistence *
            innovationPotentialDerivative horizon exposure persistence) /
          innovationPotential horizon exposure persistence ^ 2) =
      innovationTimingVariance horizon exposure persistence := by
  rw [innovationTimingVariance, innovationDuration]
  have hfirst :=
    scaled_potentialDerivative_eq_firstMoment horizon exposure persistence
  have hsecond :=
    scaled_firstMomentDerivative_eq_secondMoment horizon exposure persistence
  field_simp [hpotential]
  calc
    persistence *
          (innovationFirstMomentDerivative horizon exposure persistence *
              innovationPotential horizon exposure persistence -
            innovationFirstMoment horizon exposure persistence *
              innovationPotentialDerivative horizon exposure persistence) =
        (persistence *
            innovationFirstMomentDerivative horizon exposure persistence) *
              innovationPotential horizon exposure persistence -
          innovationFirstMoment horizon exposure persistence *
            (persistence *
              innovationPotentialDerivative horizon exposure persistence) := by ring
    _ = innovationSecondMoment horizon exposure persistence *
          innovationPotential horizon exposure persistence -
        innovationFirstMoment horizon exposure persistence ^ 2 := by
          rw [hfirst, hsecond]
          ring
    _ = innovationPotential horizon exposure persistence *
          innovationSecondMoment horizon exposure persistence -
        innovationFirstMoment horizon exposure persistence ^ 2 := by ring

/-- Under nonnegative data, every normalized timing weight is nonnegative. -/
theorem innovationWeight_nonnegative
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ)
    (hpersistence : 0 ≤ persistence)
    (hexposure : ∀ time ∈ Finset.range horizon, 0 ≤ exposure time)
    (hpotential : 0 < innovationPotential horizon exposure persistence)
    {time : ℕ} (htime : time ∈ Finset.range horizon) :
    0 ≤ innovationWeight horizon exposure persistence time := by
  exact div_nonneg (mul_nonneg (pow_nonneg hpersistence _) (hexposure time htime))
    hpotential.le

/-- Under positive total exposure, innovation convexity is nonnegative. -/
theorem innovationConvexity_nonnegative
    (horizon : ℕ) (exposure : ℕ → ℝ) (persistence : ℝ)
    (hpersistence : 0 ≤ persistence)
    (hexposure : ∀ time ∈ Finset.range horizon, 0 ≤ exposure time)
    (hpotential : 0 < innovationPotential horizon exposure persistence) :
    0 ≤ innovationConvexity horizon exposure persistence := by
  unfold innovationConvexity
  exact Finset.sum_nonneg fun time htime =>
    mul_nonneg
      (innovationWeight_nonnegative horizon exposure persistence hpersistence
        hexposure hpotential htime)
      (sq_nonneg _)

namespace InnovationDurationExamples

def earlyExposure : ℕ → ℝ
  | 0 => 2
  | _ => 0

def lateExposure : ℕ → ℝ
  | 2 => 8
  | _ => 0

def middleExposure : ℕ → ℝ
  | 1 => 4
  | _ => 0

def spreadExposure : ℕ → ℝ
  | 0 => 1
  | 2 => 4
  | _ => 0

theorem early_exact :
    innovationPotential 3 earlyExposure (1 / 2) = 2 ∧
    innovationDuration 3 earlyExposure (1 / 2) = 0 ∧
    innovationConvexity 3 earlyExposure (1 / 2) = 0 := by
  norm_num [innovationPotential, innovationDuration, innovationFirstMoment,
    innovationConvexity, innovationWeight, earlyExposure, Finset.sum_range_succ]

theorem late_exact :
    innovationPotential 3 lateExposure (1 / 2) = 2 ∧
    innovationDuration 3 lateExposure (1 / 2) = 2 ∧
    innovationConvexity 3 lateExposure (1 / 2) = 0 := by
  norm_num [innovationPotential, innovationDuration, innovationFirstMoment,
    innovationConvexity, innovationWeight, lateExposure, Finset.sum_range_succ]

theorem middle_exact :
    innovationPotential 3 middleExposure (1 / 2) = 2 ∧
    innovationDuration 3 middleExposure (1 / 2) = 1 ∧
    innovationConvexity 3 middleExposure (1 / 2) = 0 := by
  norm_num [innovationPotential, innovationDuration, innovationFirstMoment,
    innovationConvexity, innovationWeight, middleExposure, Finset.sum_range_succ]

theorem spread_exact :
    innovationPotential 3 spreadExposure (1 / 2) = 2 ∧
    innovationDuration 3 spreadExposure (1 / 2) = 1 ∧
    innovationConvexity 3 spreadExposure (1 / 2) = 1 := by
  norm_num [innovationPotential, innovationDuration, innovationFirstMoment,
    innovationConvexity, innovationWeight, spreadExposure, Finset.sum_range_succ]

end InnovationDurationExamples

end Coverage

end StrategyInnovation
