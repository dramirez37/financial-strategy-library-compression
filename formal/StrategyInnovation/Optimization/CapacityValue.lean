import StrategyInnovation.Optimization.PenalizedEnvelope

/-!
# Finite capacity-constrained value

This module formalizes the canonical real-capacity extension of an exact
finite library problem.  The feasible family is fixed independently of the
capacity, and a designated zero-burden inactive library makes every
nonnegative capacity feasible.

The optimized value is deliberately defined for every real capacity, using
the inactive value only as a harmless default when the filtered family is
empty.  Every manuscript-facing theorem below is stated on the intended
nonnegative-capacity domain, where the default branch is never used.
-/

namespace StrategyInnovation

namespace Optimization

open scoped Topology

/--
Data of a fixed finite capacity problem with a designated zero-burden
inactive library.  The inherited fields are the same value/burden interface
used by `FinitePenalizedProblem`.
-/
structure FiniteCapacityProblem (Library : Type*)
    extends FinitePenalizedProblem Library where
  inactiveLibrary : Library
  inactive_mem : inactiveLibrary ∈ feasibleLibraries
  inactive_burden_zero : burden inactiveLibrary = 0

namespace FiniteCapacityProblem

variable {Library : Type*} (problem : FiniteCapacityProblem Library)

/-- Canonical real-capacity extension of exact rational data. -/
noncomputable def ofRational
    (feasibleLibraries : Finset Library)
    (feasibleLibraries_nonempty : feasibleLibraries.Nonempty)
    (inactiveLibrary : Library)
    (inactive_mem : inactiveLibrary ∈ feasibleLibraries)
    (productiveValue burden : Library → ℚ)
    (burden_nonnegative :
      ∀ library ∈ feasibleLibraries, 0 ≤ burden library)
    (inactive_burden_zero : burden inactiveLibrary = 0) :
    FiniteCapacityProblem Library where
  feasibleLibraries := feasibleLibraries
  feasibleLibraries_nonempty := feasibleLibraries_nonempty
  productiveValue := fun library => (productiveValue library : ℝ)
  burden := fun library => (burden library : ℝ)
  burden_nonnegative := by
    intro library hlibrary
    exact Rat.cast_nonneg.mpr (burden_nonnegative library hlibrary)
  inactiveLibrary := inactiveLibrary
  inactive_mem := inactive_mem
  inactive_burden_zero := by
    exact_mod_cast inactive_burden_zero

/-- Libraries whose burdens do not exceed the declared capacity. -/
noncomputable def capacityFeasibleLibraries (capacity : ℝ) : Finset Library := by
  classical
  exact problem.feasibleLibraries.filter
    (fun library => problem.burden library ≤ capacity)

/-- Membership in the capacity-feasible finite family. -/
theorem mem_capacityFeasibleLibraries_iff
    {capacity : ℝ} {library : Library} :
    library ∈ problem.capacityFeasibleLibraries capacity ↔
      library ∈ problem.feasibleLibraries ∧
        problem.burden library ≤ capacity := by
  classical
  simp [capacityFeasibleLibraries]

/-- Every nonnegative capacity admits the designated inactive library. -/
theorem inactive_mem_capacityFeasibleLibraries
    {capacity : ℝ} (hcapacity : 0 ≤ capacity) :
    problem.inactiveLibrary ∈
      problem.capacityFeasibleLibraries capacity := by
  rw [problem.mem_capacityFeasibleLibraries_iff]
  exact ⟨problem.inactive_mem,
    problem.inactive_burden_zero.le.trans hcapacity⟩

/-- The filtered family is nonempty on the nonnegative-capacity domain. -/
theorem capacityFeasibleLibraries_nonempty
    {capacity : ℝ} (hcapacity : 0 ≤ capacity) :
    (problem.capacityFeasibleLibraries capacity).Nonempty :=
  ⟨problem.inactiveLibrary,
    problem.inactive_mem_capacityFeasibleLibraries hcapacity⟩

/--
The finite capacity value
`V⋆(B) = max {V_L : L ∈ ℱ, W_L ≤ B}`.

Outside the intended nonnegative domain an empty filtered family receives the
inactive value as a total-function default.
-/
noncomputable def capacityValue (capacity : ℝ) : ℝ := by
  classical
  exact if hfeasible : (problem.capacityFeasibleLibraries capacity).Nonempty then
    (problem.capacityFeasibleLibraries capacity).sup' hfeasible
      problem.productiveValue
  else
    problem.productiveValue problem.inactiveLibrary

/-- Membership in the complete, tie-retaining capacity optimizer set. -/
def IsCapacityOptimizer (capacity : ℝ) (library : Library) : Prop :=
  library ∈ problem.capacityFeasibleLibraries capacity ∧
    problem.productiveValue library = problem.capacityValue capacity

/-- The complete capacity optimizer correspondence. -/
def capacityOptimizerSet (capacity : ℝ) : Set Library :=
  {library | problem.IsCapacityOptimizer capacity library}

/-- On every nonempty filtered family, `capacityValue` is its finite maximum. -/
theorem capacityValue_eq_sup'_of_nonempty
    {capacity : ℝ}
    (hfeasible : (problem.capacityFeasibleLibraries capacity).Nonempty) :
    problem.capacityValue capacity =
      (problem.capacityFeasibleLibraries capacity).sup' hfeasible
        problem.productiveValue := by
  classical
  simp [capacityValue, hfeasible]

/-- Every capacity-feasible library lies weakly below `V⋆`. -/
theorem productiveValue_le_capacityValue
    {capacity : ℝ} {library : Library}
    (hlibrary : library ∈ problem.capacityFeasibleLibraries capacity) :
    problem.productiveValue library ≤ problem.capacityValue capacity := by
  have hfeasible : (problem.capacityFeasibleLibraries capacity).Nonempty :=
    ⟨library, hlibrary⟩
  rw [problem.capacityValue_eq_sup'_of_nonempty hfeasible]
  exact Finset.le_sup' problem.productiveValue hlibrary

/-- A feasible library dominating every feasible competitor is an optimizer. -/
theorem isCapacityOptimizer_of_dominates
    {capacity : ℝ} {library : Library}
    (hlibrary : library ∈ problem.capacityFeasibleLibraries capacity)
    (hdominates : ∀ competitor ∈ problem.capacityFeasibleLibraries capacity,
      problem.productiveValue competitor ≤ problem.productiveValue library) :
    problem.IsCapacityOptimizer capacity library := by
  refine ⟨hlibrary, le_antisymm
    (problem.productiveValue_le_capacityValue hlibrary) ?_⟩
  have hfeasible : (problem.capacityFeasibleLibraries capacity).Nonempty :=
    ⟨library, hlibrary⟩
  rw [problem.capacityValue_eq_sup'_of_nonempty hfeasible]
  exact Finset.sup'_le hfeasible problem.productiveValue hdominates

/-- An optimizer exists whenever the designated inactive library is feasible. -/
theorem exists_capacityOptimizer_of_inactive_feasible
    {capacity : ℝ}
    (hinactive : problem.inactiveLibrary ∈
      problem.capacityFeasibleLibraries capacity) :
    ∃ library : Library, problem.IsCapacityOptimizer capacity library := by
  have hfeasible : (problem.capacityFeasibleLibraries capacity).Nonempty :=
    ⟨problem.inactiveLibrary, hinactive⟩
  obtain ⟨library, hlibrary, hmaximum⟩ :=
    Finset.exists_mem_eq_sup' hfeasible problem.productiveValue
  refine ⟨library, hlibrary, ?_⟩
  rw [problem.capacityValue_eq_sup'_of_nonempty hfeasible]
  exact hmaximum.symm

/-- Every nonnegative capacity has a capacity-feasible optimizer. -/
theorem exists_capacityOptimizer
    {capacity : ℝ} (hcapacity : 0 ≤ capacity) :
    ∃ library : Library, problem.IsCapacityOptimizer capacity library :=
  problem.exists_capacityOptimizer_of_inactive_feasible
    (problem.inactive_mem_capacityFeasibleLibraries hcapacity)

/-- The optimizer correspondence is nonempty at every nonnegative capacity. -/
theorem capacityOptimizerSet_nonempty
    {capacity : ℝ} (hcapacity : 0 ≤ capacity) :
    (problem.capacityOptimizerSet capacity).Nonempty := by
  obtain ⟨library, hoptimizer⟩ :=
    problem.exists_capacityOptimizer hcapacity
  exact ⟨library, hoptimizer⟩

/--
`V⋆(B)` is exactly an attained maximum of the nonempty finite feasible
family at every nonnegative capacity.
-/
theorem capacityValue_is_finite_maximum
    {capacity : ℝ} (hcapacity : 0 ≤ capacity) :
    (∀ library ∈ problem.feasibleLibraries,
        problem.burden library ≤ capacity →
          problem.productiveValue library ≤ problem.capacityValue capacity) ∧
      ∃ library ∈ problem.feasibleLibraries,
        problem.burden library ≤ capacity ∧
          problem.capacityValue capacity = problem.productiveValue library := by
  constructor
  · intro library hlibrary hburden
    exact problem.productiveValue_le_capacityValue
      (problem.mem_capacityFeasibleLibraries_iff.mpr ⟨hlibrary, hburden⟩)
  · obtain ⟨library, hoptimizer⟩ :=
      problem.exists_capacityOptimizer hcapacity
    rcases hoptimizer with ⟨hfeasible, hvalue⟩
    rw [problem.mem_capacityFeasibleLibraries_iff] at hfeasible
    exact ⟨library, hfeasible.1, hfeasible.2, hvalue.symm⟩

/-- Increasing capacity enlarges the filtered feasible family. -/
theorem capacityFeasibleLibraries_mono
    {small large : ℝ} (hcapacity : small ≤ large) :
    problem.capacityFeasibleLibraries small ⊆
      problem.capacityFeasibleLibraries large := by
  intro library hlibrary
  rw [problem.mem_capacityFeasibleLibraries_iff] at hlibrary ⊢
  exact ⟨hlibrary.1, hlibrary.2.trans hcapacity⟩

/-- Capacity value is nondecreasing on the nonnegative-capacity domain. -/
theorem capacityValue_mono
    {small large : ℝ} (hsmall : 0 ≤ small) (hcapacity : small ≤ large) :
    problem.capacityValue small ≤ problem.capacityValue large := by
  obtain ⟨library, hoptimizer⟩ :=
    problem.exists_capacityOptimizer hsmall
  rw [← hoptimizer.2]
  exact problem.productiveValue_le_capacityValue
    (problem.capacityFeasibleLibraries_mono hcapacity hoptimizer.1)

/-- The finite set of burdens attained by libraries in the fixed family. -/
noncomputable def attainableBurdens : Finset ℝ := by
  classical
  exact problem.feasibleLibraries.image problem.burden

/-- Every represented library burden is attainable. -/
theorem burden_mem_attainableBurdens
    {library : Library} (hlibrary : library ∈ problem.feasibleLibraries) :
    problem.burden library ∈ problem.attainableBurdens := by
  classical
  exact Finset.mem_image.mpr ⟨library, hlibrary, rfl⟩

/-- Zero is an attainable burden because the inactive library has burden zero. -/
theorem zero_mem_attainableBurdens :
    (0 : ℝ) ∈ problem.attainableBurdens := by
  rw [← problem.inactive_burden_zero]
  exact problem.burden_mem_attainableBurdens problem.inactive_mem

/-- The attainable-burden set is finite. -/
theorem attainableBurdenSet_finite :
    Set.Finite (problem.attainableBurdens : Set ℝ) :=
  Finset.finite_toSet problem.attainableBurdens

/--
If no attainable burden lies in `(lower, upper]`, the capacity-feasible
families at the two endpoints coincide.
-/
theorem capacityFeasibleLibraries_eq_of_no_attainableBurden
    {lower upper : ℝ} (horder : lower ≤ upper)
    (hgap : ∀ burden ∈ problem.attainableBurdens,
      ¬ (lower < burden ∧ burden ≤ upper)) :
    problem.capacityFeasibleLibraries lower =
      problem.capacityFeasibleLibraries upper := by
  classical
  ext library
  rw [problem.mem_capacityFeasibleLibraries_iff,
    problem.mem_capacityFeasibleLibraries_iff]
  constructor
  · rintro ⟨hlibrary, hburden⟩
    exact ⟨hlibrary, hburden.trans horder⟩
  · rintro ⟨hlibrary, hburden⟩
    refine ⟨hlibrary, ?_⟩
    by_contra hnot
    exact hgap (problem.burden library)
      (problem.burden_mem_attainableBurdens hlibrary)
      ⟨lt_of_not_ge hnot, hburden⟩

/-- Capacity value is constant across an interval containing no new burden. -/
theorem capacityValue_eq_of_no_attainableBurden
    {lower upper : ℝ} (horder : lower ≤ upper)
    (hgap : ∀ burden ∈ problem.attainableBurdens,
      ¬ (lower < burden ∧ burden ≤ upper)) :
    problem.capacityValue lower = problem.capacityValue upper := by
  have hfamilies :=
    problem.capacityFeasibleLibraries_eq_of_no_attainableBurden horder hgap
  unfold capacityValue
  rw [hfamilies]

/-- Two adjacent elements of the attainable-burden set. -/
def AreConsecutiveAttainableBurdens (lower upper : ℝ) : Prop :=
  lower ∈ problem.attainableBurdens ∧
    upper ∈ problem.attainableBurdens ∧
      lower < upper ∧
        ∀ burden ∈ problem.attainableBurdens,
          lower < burden → upper ≤ burden

/--
Between consecutive attainable burden levels, `V⋆` equals its value at
the lower level throughout the half-closed cell `[lower, upper)`.
-/
theorem capacityValue_constant_between_attainableBurdens
    {lower upper capacity : ℝ}
    (hconsecutive :
      problem.AreConsecutiveAttainableBurdens lower upper)
    (hlower : lower ≤ capacity) (hupper : capacity < upper) :
    problem.capacityValue capacity = problem.capacityValue lower := by
  symm
  apply problem.capacityValue_eq_of_no_attainableBurden hlower
  intro burden hburden hbetween
  have hnext : upper ≤ burden :=
    hconsecutive.2.2.2 burden hburden hbetween.1
  linarith

/-- The capacity value is locally constant at a capacity. -/
def IsLocallyConstantAt (capacity : ℝ) : Prop :=
  problem.capacityValue =ᶠ[𝓝 capacity]
    (fun _ => problem.capacityValue capacity)

/-- Positive capacities at which the optimized value is not locally constant. -/
def capacityBreakpointSet : Set ℝ :=
  {capacity | 0 < capacity ∧ ¬ problem.IsLocallyConstantAt capacity}

/-- Every library's feasibility status is locally stable off its burden. -/
theorem eventually_capacityFeasibleLibraries_eq_of_not_attainable
    {capacity : ℝ} (hcapacity : capacity ∉ problem.attainableBurdens) :
    ∀ᶠ nearby in 𝓝 capacity,
      problem.capacityFeasibleLibraries nearby =
        problem.capacityFeasibleLibraries capacity := by
  classical
  have hstable :
      ∀ library ∈ problem.feasibleLibraries,
        ∀ᶠ nearby in 𝓝 capacity,
          (problem.burden library ≤ nearby ↔
            problem.burden library ≤ capacity) := by
    intro library hlibrary
    have hne : problem.burden library ≠ capacity := by
      intro heq
      exact hcapacity (heq ▸ problem.burden_mem_attainableBurdens hlibrary)
    rcases lt_or_gt_of_ne hne with hbelow | habove
    · filter_upwards [isOpen_Ioi.mem_nhds hbelow] with nearby hnearby
      constructor
      · intro _
        exact hbelow.le
      · intro _
        exact hnearby.le
    · filter_upwards [isOpen_Iio.mem_nhds habove] with nearby hnearby
      change nearby < problem.burden library at hnearby
      constructor
      · intro hle
        exact (not_le_of_gt hnearby hle).elim
      · intro hle
        exact (not_le_of_gt habove hle).elim
  have hall :
      ∀ᶠ nearby in 𝓝 capacity,
        ∀ library ∈ problem.feasibleLibraries,
          (problem.burden library ≤ nearby ↔
            problem.burden library ≤ capacity) :=
    (problem.feasibleLibraries.eventually_all).2 hstable
  filter_upwards [hall] with nearby hnearby
  ext library
  rw [problem.mem_capacityFeasibleLibraries_iff,
    problem.mem_capacityFeasibleLibraries_iff]
  by_cases hlibrary : library ∈ problem.feasibleLibraries
  · exact and_congr_right (fun _ => hnearby library hlibrary)
  · simp [hlibrary]

/-- Outside the attainable burdens, the optimized capacity value is local constant. -/
theorem isLocallyConstantAt_of_not_mem_attainableBurdens
    {capacity : ℝ} (hcapacity : capacity ∉ problem.attainableBurdens) :
    problem.IsLocallyConstantAt capacity := by
  filter_upwards [
    problem.eventually_capacityFeasibleLibraries_eq_of_not_attainable hcapacity
  ] with nearby hfamilies
  unfold capacityValue
  rw [hfamilies]

/-- Every positive capacity-value breakpoint is an attainable burden. -/
theorem capacityBreakpointSet_subset_attainableBurdens :
    problem.capacityBreakpointSet ⊆
      (problem.attainableBurdens : Set ℝ) := by
  intro capacity hbreakpoint
  by_contra hcapacity
  exact hbreakpoint.2
    (problem.isLocallyConstantAt_of_not_mem_attainableBurdens hcapacity)

/-- The capacity-value breakpoint set is finite. -/
theorem capacityBreakpointSet_finite :
    Set.Finite problem.capacityBreakpointSet :=
  problem.attainableBurdenSet_finite.subset
    problem.capacityBreakpointSet_subset_attainableBurdens

/-- Exact forward discrete shadow value for a declared capacity increment. -/
noncomputable def discreteShadowValue (capacity increment : ℝ) : ℝ :=
  problem.capacityValue (capacity + increment) -
    problem.capacityValue capacity

/-- Every nonnegative capacity increment has nonnegative exact shadow value. -/
theorem discreteShadowValue_nonnegative
    {capacity increment : ℝ}
    (hcapacity : 0 ≤ capacity) (hincrement : 0 ≤ increment) :
    0 ≤ problem.discreteShadowValue capacity increment := by
  rw [discreteShadowValue, sub_nonneg]
  exact problem.capacityValue_mono hcapacity (by linarith)

/-- Discrete diminishing returns for one declared positive resource unit. -/
def HasDiminishingDiscreteCapacityReturns (increment : ℝ) : Prop :=
  0 < increment ∧
    ∀ capacity, 0 ≤ capacity →
      problem.discreteShadowValue (capacity + increment) increment ≤
        problem.discreteShadowValue capacity increment

end FiniteCapacityProblem

end Optimization

end StrategyInnovation
