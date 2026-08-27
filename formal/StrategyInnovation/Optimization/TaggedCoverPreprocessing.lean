import StrategyInnovation.Optimization.TaggedSafeCompression

/-!
# Finite covering identities used by journal preprocessing and mask algorithms

These declarations formalize only feasibility-preserving identities for a
finite pure covering model. They do not formalize preprocessing objective
values, optimizer reconstruction, the complete fixed-point implementation,
dynamic-programming optimality or complexity, or an approximation theorem.
-/

namespace StrategyInnovation

namespace Optimization

namespace TaggedCoverPreprocessing

variable {Strategy Requirement : Type*}
variable [DecidableEq Strategy] [DecidableEq Requirement]

/-- The selected finite columns cover every required row. -/
def SelectedCovers
    (coverage : Strategy → Finset Requirement)
    (requirements : Finset Requirement)
    (selected : Finset Strategy) : Prop :=
  requirements ⊆ selected.biUnion coverage

/-- Inserting a column updates selected coverage by finite union. -/
theorem selectedCoverage_insert
    (coverage : Strategy → Finset Requirement)
    (selected : Finset Strategy) (strategy : Strategy) :
    (insert strategy selected).biUnion coverage =
      coverage strategy ∪ selected.biUnion coverage := by
  ext requirement
  simp

omit [DecidableEq Strategy] in
/-- P1 feasibility core: every cover selects the unique carrier of a required row. -/
theorem uniqueCarrier_mem_of_selectedCovers
    (coverage : Strategy → Finset Requirement)
    (requirements : Finset Requirement)
    (selected : Finset Strategy)
    {requirement : Requirement} {carrier : Strategy}
    (hrequired : requirement ∈ requirements)
    (hunique : ∀ strategy, requirement ∈ coverage strategy → strategy = carrier)
    (hcover : SelectedCovers coverage requirements selected) :
    carrier ∈ selected := by
  have hcovered : requirement ∈ selected.biUnion coverage := hcover hrequired
  simp only [Finset.mem_biUnion] at hcovered
  obtain ⟨strategy, hselected, hstrategy⟩ := hcovered
  simpa [hunique strategy hstrategy] using hselected

/--
P2 feasibility core: replacing one column by a column with a coverage superset
preserves every required row. Weight and optimizer-identity claims are outside
this lemma.
-/
theorem replace_dominated_preserves_selectedCovers
    (coverage : Strategy → Finset Requirement)
    (requirements : Finset Requirement)
    (selected : Finset Strategy)
    {dominated dominator : Strategy}
    (hcoverage : coverage dominated ⊆ coverage dominator)
    (hcover : SelectedCovers coverage requirements selected) :
    SelectedCovers coverage requirements
      (insert dominator (selected.erase dominated)) := by
  intro requirement hrequired
  have hcovered : requirement ∈ selected.biUnion coverage := hcover hrequired
  simp only [Finset.mem_biUnion] at hcovered ⊢
  obtain ⟨strategy, hselected, hstrategy⟩ := hcovered
  by_cases heq : strategy = dominated
  · subst strategy
    exact ⟨dominator, Finset.mem_insert_self _ _, hcoverage hstrategy⟩
  · exact ⟨strategy,
      Finset.mem_insert_of_mem (Finset.mem_erase.mpr ⟨heq, hselected⟩),
      hstrategy⟩

/-- P5 feasibility core: a column covering no required row may be erased. -/
theorem erase_emptyContribution_preserves_selectedCovers
    (coverage : Strategy → Finset Requirement)
    (requirements : Finset Requirement)
    (selected : Finset Strategy)
    {strategy : Strategy}
    (hempty : ∀ requirement ∈ requirements,
      requirement ∉ coverage strategy)
    (hcover : SelectedCovers coverage requirements selected) :
    SelectedCovers coverage requirements (selected.erase strategy) := by
  intro requirement hrequired
  have hcovered : requirement ∈ selected.biUnion coverage := hcover hrequired
  simp only [Finset.mem_biUnion] at hcovered ⊢
  obtain ⟨carrier, hselected, hcarrier⟩ := hcovered
  have hne : carrier ≠ strategy := by
    intro heq
    subst carrier
    exact hempty requirement hrequired hcarrier
  exact ⟨carrier, Finset.mem_erase.mpr ⟨hne, hselected⟩, hcarrier⟩

omit [DecidableEq Strategy] in
/-- Rows with identical carrier predicates are covered simultaneously. -/
theorem selectedCoverage_mem_iff_of_sameCarriers
    (coverage : Strategy → Finset Requirement)
    (selected : Finset Strategy)
    {left right : Requirement}
    (hsame : ∀ strategy, left ∈ coverage strategy ↔ right ∈ coverage strategy) :
    left ∈ selected.biUnion coverage ↔
      right ∈ selected.biUnion coverage := by
  simp only [Finset.mem_biUnion]
  constructor
  · rintro ⟨strategy, hselected, hleft⟩
    exact ⟨strategy, hselected, (hsame strategy).1 hleft⟩
  · rintro ⟨strategy, hselected, hright⟩
    exact ⟨strategy, hselected, (hsame strategy).2 hright⟩

omit [DecidableEq Strategy] in
/--
P6 feasibility core: deleting one of two required rows with identical carrier
predicates leaves the complete selected-cover predicate unchanged.
-/
theorem erase_duplicateRequirement_selectedCovers_iff
    (coverage : Strategy → Finset Requirement)
    (requirements : Finset Requirement)
    (selected : Finset Strategy)
    {representative duplicate : Requirement}
    (hrepresentative : representative ∈ requirements)
    (hne : representative ≠ duplicate)
    (hsame : ∀ strategy,
      representative ∈ coverage strategy ↔ duplicate ∈ coverage strategy) :
    SelectedCovers coverage (requirements.erase duplicate) selected ↔
      SelectedCovers coverage requirements selected := by
  constructor
  · intro hcover requirement hrequired
    by_cases heq : requirement = duplicate
    · subst requirement
      have hrepresentativeErased :
          representative ∈ requirements.erase duplicate :=
        Finset.mem_erase.mpr ⟨hne, hrepresentative⟩
      exact (selectedCoverage_mem_iff_of_sameCarriers
        coverage selected hsame).1 (hcover hrepresentativeErased)
    · exact hcover (Finset.mem_erase.mpr ⟨heq, hrequired⟩)
  · intro hcover requirement hrequired
    exact hcover (Finset.mem_of_mem_erase hrequired)

end TaggedCoverPreprocessing

end Optimization

end StrategyInnovation
