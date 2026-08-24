import Mathlib.Tactic
import StrategyInnovation.Coverage.SingleGap
import StrategyInnovation.Fixtures.MultiGapRegion

/-!
# A project with two gaps can have a disconnected one-shot cost-covering set

This file kernel-checks an exact five-belief counterexample.  One research
project produces two candidate strategies.  Relative to the zero existing
frontier, the first candidate has certified gap `(4,0,0,0,0)` and the second
has certified gap `(0,0,0,0,4)`.

The transition is the degree-four Bernstein/binomial kernel: at current state
`i`, future belief is the number of successes in four Bernoulli trials with
success probability `i / 4`.  The aggregate one-shot coverage potential is
exactly `(4,41/32,1/2,41/32,4)`.  At constant cost one, the strict research
cost-covering set is the disjoint union `[0,1] ∪ [3,4]`, so it is not
order-connected.

The final result also isolates the boundary of any stronger topology claim:
with belief-dependent costs, even a constant gap and constant potential can
produce three cost-covering components.  None of these sets is an optimal
Bellman research region.
-/

namespace StrategyInnovation
namespace Counterexamples
namespace MultiGapRegion

open Set
open StrategyInnovation.Fixtures.MultiGapRegion

attribute [local simp] Matrix.cons_val_two Matrix.cons_val_three
  Matrix.cons_val_four

abbrev grid : Coverage.FiniteOrderedBeliefGrid where
  Belief := Fin 5
  beliefFintype := inferInstance
  beliefLinearOrder := inferInstance
  beliefNonempty := inferInstance

abbrev Project := Unit
abbrev Candidate := Fin 2

/-- The single project has two candidate-strategy outcomes. -/
def projectCandidates (_project : Project) : Finset Candidate := Finset.univ

/-- Candidate values before subtracting the existing library frontier. -/
def candidateValue (candidate : Candidate) : Fin 5 → ℚ :=
  if candidate = 0 then leftCandidateGap else rightCandidateGap

/-- The current strategy library has zero frontier at every belief. -/
def existingFrontier (_state : Unit) (_belief : Fin 5) : ℚ := 0

/-- Certified candidate gap relative to the existing strategy library. -/
def candidateGap (candidate : Candidate) (belief : Fin 5) : ℚ :=
  Coverage.certifiedGap (grid := grid) candidateValue existingFrontier
    candidate () belief

theorem left_candidateGap_eq : candidateGap 0 = leftCandidateGap := by
  funext belief
  fin_cases belief <;>
    norm_num [candidateGap, candidateValue, existingFrontier,
      Coverage.certifiedGap, leftCandidateGap]

theorem right_candidateGap_eq : candidateGap 1 = rightCandidateGap := by
  funext belief
  fin_cases belief <;>
    norm_num [candidateGap, candidateValue, existingFrontier,
      Coverage.certifiedGap, rightCandidateGap]

/-- The project's aggregate certified gap is the sum of its two outcomes. -/
def projectGap (project : Project) (belief : Fin 5) : ℚ :=
  ∑ candidate ∈ projectCandidates project, candidateGap candidate belief

theorem projectGap_eq : projectGap () = ![4, 0, 0, 0, 4] := by
  funext belief
  fin_cases belief <;>
    norm_num [projectGap, projectCandidates, Fin.sum_univ_two,
      left_candidateGap_eq, right_candidateGap_eq, leftCandidateGap,
      rightCandidateGap]

def leftGapRegion : Set (Fin 5) := {belief | 0 < candidateGap 0 belief}

def rightGapRegion : Set (Fin 5) := {belief | 0 < candidateGap 1 belief}

theorem leftGapRegion_eq : leftGapRegion = Set.Icc (0 : Fin 5) 0 := by
  ext belief
  change (0 < candidateGap 0 belief) ↔ (0 ≤ belief ∧ belief ≤ 0)
  fin_cases belief <;>
    norm_num [candidateGap, candidateValue, existingFrontier,
      Coverage.certifiedGap, leftCandidateGap]

theorem rightGapRegion_eq : rightGapRegion = Set.Icc (4 : Fin 5) 4 := by
  ext belief
  change (0 < candidateGap 1 belief) ↔ (4 ≤ belief ∧ belief ≤ 4)
  fin_cases belief <;>
    norm_num [candidateGap, candidateValue, existingFrontier,
      Coverage.certifiedGap, rightCandidateGap] <;>
    decide

theorem gapRegions_disjoint : Disjoint leftGapRegion rightGapRegion := by
  rw [leftGapRegion_eq, rightGapRegion_eq]
  exact Set.disjoint_left.2 (by
    intro belief hleft hright
    fin_cases belief <;> simp_all)

/-- One project genuinely fills two separated strategy-library gaps. -/
theorem project_fills_two_separated_strategyLibraryGaps :
    (0 : Candidate) ∈ projectCandidates () ∧
      (1 : Candidate) ∈ projectCandidates () ∧
      candidateGap 0 = leftCandidateGap ∧
      candidateGap 1 = rightCandidateGap ∧
      leftGapRegion = Set.Icc (0 : Fin 5) 0 ∧
      rightGapRegion = Set.Icc (4 : Fin 5) 4 ∧
      Disjoint leftGapRegion rightGapRegion := by
  exact ⟨by simp [projectCandidates], by simp [projectCandidates],
    left_candidateGap_eq, right_candidateGap_eq, leftGapRegion_eq,
    rightGapRegion_eq, gapRegions_disjoint⟩

/-- Exact row-stochastic degree-four Bernstein transition kernel. -/
def transitionKernel : Coverage.FiniteTransitionKernel grid where
  weight := bernsteinKernel
  nonnegative := by
    intro initial future
    fin_cases initial <;> fin_cases future <;>
      norm_num [bernsteinKernel]
  rowSum := by
    intro initial
    fin_cases initial <;>
      simp [bernsteinKernel, Fin.sum_univ_succ] <;>
      norm_num

/-- Discount and survival are one, so this is the one-shot gross coverage
value generated by the aggregate certified gap. -/
def coveragePotential (belief : Fin 5) : ℚ :=
  Coverage.grossCoverageValue 1 (fun _ => 1) transitionKernel
    (projectGap ()) belief

theorem coveragePotential_eq : coveragePotential = expectedPotential := by
  funext initial
  fin_cases initial <;>
    simp only [coveragePotential, Coverage.grossCoverageValue,
      Coverage.expectedGap, one_mul, transitionKernel, projectGap_eq] <;>
    rw [Fin.sum_univ_five] <;>
    norm_num [bernsteinKernel, expectedPotential]

theorem coveragePotential_values :
    coveragePotential 0 = 4 ∧
      coveragePotential 1 = 41 / 32 ∧
      coveragePotential 2 = 1 / 2 ∧
      coveragePotential 3 = 41 / 32 ∧
      coveragePotential 4 = 4 := by
  norm_num [coveragePotential_eq, expectedPotential]

/-- Strict one-shot cost-covering set at constant exact cost one. -/
def strictCostCoveringSet : Set (Fin 5) :=
  {belief | researchCost belief < coveragePotential belief}

theorem strictCostCoveringSet_eq :
    strictCostCoveringSet =
      Set.Icc (0 : Fin 5) 1 ∪ Set.Icc (3 : Fin 5) 4 := by
  ext belief
  change (researchCost belief < coveragePotential belief) ↔
    ((0 ≤ belief ∧ belief ≤ 1) ∨ (3 ≤ belief ∧ belief ≤ 4))
  fin_cases belief <;>
    norm_num [researchCost, coveragePotential_eq, expectedPotential] <;>
    decide

theorem coverage_exceeds_cost_on_left_region :
    ∀ belief ∈ Set.Icc (0 : Fin 5) 1,
      researchCost belief < coveragePotential belief := by
  intro belief hbelief
  change belief ∈ strictCostCoveringSet
  rw [strictCostCoveringSet_eq]
  exact Or.inl hbelief

theorem coverage_exceeds_cost_on_right_region :
    ∀ belief ∈ Set.Icc (3 : Fin 5) 4,
      researchCost belief < coveragePotential belief := by
  intro belief hbelief
  change belief ∈ strictCostCoveringSet
  rw [strictCostCoveringSet_eq]
  exact Or.inr hbelief

theorem coverage_does_not_cover_middle_cost :
    ¬ researchCost 2 < coveragePotential 2 := by
  norm_num [researchCost, coveragePotential_eq, expectedPotential]

theorem strictCostCoveringSet_not_ordConnected :
    ¬ Set.OrdConnected strictCostCoveringSet := by
  intro hconnected
  have hleft : (1 : Fin 5) ∈ strictCostCoveringSet := by
    rw [strictCostCoveringSet_eq]
    exact Or.inl ⟨by decide, by decide⟩
  have hright : (3 : Fin 5) ∈ strictCostCoveringSet := by
    rw [strictCostCoveringSet_eq]
    exact Or.inr ⟨by decide, by decide⟩
  have hmiddle := hconnected.out (x := (1 : Fin 5)) (y := (3 : Fin 5))
    hleft hright
    (show (2 : Fin 5) ∈ Set.Icc (1 : Fin 5) 3 by decide)
  exact coverage_does_not_cover_middle_cost hmiddle

/-- **Multi-gap limitation.** One project fills two separated certified gaps,
and its exact one-shot potential covers a constant research cost on two
separated, nonempty belief intervals but not at the intervening belief. -/
theorem separatedMultiGap_disconnectedCostCoveringSet :
    (0 : Candidate) ∈ projectCandidates () ∧
      (1 : Candidate) ∈ projectCandidates () ∧
      Disjoint leftGapRegion rightGapRegion ∧
      (∀ belief ∈ Set.Icc (0 : Fin 5) 1,
        researchCost belief < coveragePotential belief) ∧
      (∀ belief ∈ Set.Icc (3 : Fin 5) 4,
        researchCost belief < coveragePotential belief) ∧
      ¬ researchCost 2 < coveragePotential 2 ∧
      ¬ Set.OrdConnected strictCostCoveringSet := by
  exact ⟨by simp [projectCandidates], by simp [projectCandidates],
    gapRegions_disjoint, coverage_exceeds_cost_on_left_region,
    coverage_exceeds_cost_on_right_region,
    coverage_does_not_cover_middle_cost,
    strictCostCoveringSet_not_ordConnected⟩

/-- Compatibility alias for the pre-revision set name. -/
abbrev researchRegion := strictCostCoveringSet

/-- Compatibility alias for the pre-revision exact set theorem. -/
theorem researchRegion_eq :
    researchRegion = Set.Icc (0 : Fin 5) 1 ∪ Set.Icc (3 : Fin 5) 4 :=
  strictCostCoveringSet_eq

/-- Compatibility alias for the pre-revision disconnected-set theorem. -/
theorem researchRegion_not_ordConnected :
    ¬ Set.OrdConnected researchRegion :=
  strictCostCoveringSet_not_ordConnected

/-- Compatibility alias for the pre-revision packaged counterexample name. -/
theorem multiGap_project_has_disconnected_researchRegion :
    (0 : Candidate) ∈ projectCandidates () ∧
      (1 : Candidate) ∈ projectCandidates () ∧
      Disjoint leftGapRegion rightGapRegion ∧
      (∀ belief ∈ Set.Icc (0 : Fin 5) 1,
        researchCost belief < coveragePotential belief) ∧
      (∀ belief ∈ Set.Icc (3 : Fin 5) 4,
        researchCost belief < coveragePotential belief) ∧
      ¬ researchCost 2 < coveragePotential 2 ∧
      ¬ Set.OrdConnected researchRegion :=
  separatedMultiGap_disconnectedCostCoveringSet

/-! ## Why unrestricted research-cost topology is impossible -/

def constantGapPotential (belief : Fin 5) : ℚ :=
  Coverage.expectedGap transitionKernel topologyConstantGap belief

theorem constantGapPotential_eq : constantGapPotential = topologyConstantGap := by
  funext initial
  fin_cases initial <;>
    simp only [constantGapPotential, Coverage.expectedGap, transitionKernel] <;>
    rw [Fin.sum_univ_five] <;>
    norm_num [topologyConstantGap, bernsteinKernel]

def variableCostCoveringSet : Set (Fin 5) :=
  {belief | topologyVariableCost belief < constantGapPotential belief}

theorem variableCostCoveringSet_eq :
    variableCostCoveringSet =
      Set.Icc (0 : Fin 5) 0 ∪ Set.Icc (2 : Fin 5) 2 ∪
        Set.Icc (4 : Fin 5) 4 := by
  ext belief
  change (topologyVariableCost belief < constantGapPotential belief) ↔
    (((0 ≤ belief ∧ belief ≤ 0) ∨ (2 ≤ belief ∧ belief ≤ 2)) ∨
      (4 ≤ belief ∧ belief ≤ 4))
  fin_cases belief <;>
    norm_num [topologyVariableCost, constantGapPotential_eq,
      topologyConstantGap] <;>
    decide

/-- A one-component constant gap can induce a three-component cost-covering set
under unrestricted belief-dependent cost.  Thus variation diminution of the
kernel alone cannot bound the topology of the net-value set. -/
theorem unrestrictedCost_defeats_generalComponentBound :
    Set.OrdConnected {belief : Fin 5 | 0 < topologyConstantGap belief} ∧
      ¬ Set.OrdConnected variableCostCoveringSet := by
  constructor
  · have hall : {belief : Fin 5 | 0 < topologyConstantGap belief} = Set.univ := by
      ext belief
      change (0 < topologyConstantGap belief) ↔ True
      fin_cases belief <;> norm_num [topologyConstantGap]
    rw [hall]
    exact Set.ordConnected_univ
  · intro hconnected
    have hzero : (0 : Fin 5) ∈ variableCostCoveringSet := by
      rw [variableCostCoveringSet_eq]
      exact Or.inl (Or.inl ⟨by decide, by decide⟩)
    have htwo : (2 : Fin 5) ∈ variableCostCoveringSet := by
      rw [variableCostCoveringSet_eq]
      exact Or.inl (Or.inr ⟨by decide, by decide⟩)
    have hmiddle := hconnected.out (x := (0 : Fin 5)) (y := (2 : Fin 5))
      hzero htwo
      (show (1 : Fin 5) ∈ Set.Icc (0 : Fin 5) 2 by decide)
    rw [variableCostCoveringSet_eq] at hmiddle
    simp only [Set.mem_union, Set.mem_Icc] at hmiddle
    omega

/-- Compatibility alias for the pre-revision variable-cost set name. -/
abbrev variableCostResearchRegion := variableCostCoveringSet

/-- Compatibility alias for the pre-revision exact set theorem. -/
theorem variableCostResearchRegion_eq :
    variableCostResearchRegion =
      Set.Icc (0 : Fin 5) 0 ∪ Set.Icc (2 : Fin 5) 2 ∪
        Set.Icc (4 : Fin 5) 4 :=
  variableCostCoveringSet_eq

/-- Compatibility alias for the pre-revision component-bound theorem name. -/
theorem arbitrary_cost_defeats_researchRegion_component_bound :
    Set.OrdConnected {belief : Fin 5 | 0 < topologyConstantGap belief} ∧
      ¬ Set.OrdConnected variableCostResearchRegion :=
  unrestrictedCost_defeats_generalComponentBound

end MultiGapRegion
end Counterexamples
end StrategyInnovation
