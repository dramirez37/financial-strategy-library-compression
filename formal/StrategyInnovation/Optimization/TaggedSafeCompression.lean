import StrategyInnovation.Optimization.SafeCompression

/-!
# Tagged covering for identity-closure safe compression

This file formalizes only the finite source-relative equivalence used by the
journal theorem.  It does not formalize NP-completeness, approximation, or a
solver claim.
-/

namespace StrategyInnovation

namespace Optimization

variable {model : FiniteModel}

/-- Disjoint operating-frontier and generative-module requirements. -/
inductive TaggedRequirement (model : FiniteModel) where
  | frontier (belief : model.Belief)
  | module (moduleId : model.ModuleId)
  deriving DecidableEq

/-- The identity closure on the model's finite module carrier. -/
def identityModuleClosure (model : FiniteModel) : Raw.ClosureOperator model where
  close := id
  extensive := fun _ => Finset.Subset.refl _
  monotone := fun hinclude => hinclude
  idempotent := fun _ => rfl

@[simp]
theorem identityModuleClosure_close (modules : Finset model.ModuleId) :
    (identityModuleClosure model).close modules = modules :=
  rfl

@[simp]
theorem generativeClosure_identity
    (catalog : Raw.StrategyCatalog model) (library : Raw.Library catalog) :
    generativeClosure catalog (identityModuleClosure model) library =
      rawModuleUnion catalog library :=
  rfl

/--
The source requirement universe is the disjoint union of one tag per belief
and one tag per source-closure module.
-/
def sourceTaggedRequirements (catalog : Raw.StrategyCatalog model)
    (source : Raw.Library catalog) : Finset (TaggedRequirement model) :=
  (Finset.univ.image TaggedRequirement.frontier) ∪
    ((generativeClosure catalog (identityModuleClosure model) source).image
      TaggedRequirement.module)

/--
The tags covered by one strategy: source-frontier ties at beliefs and the
strategy's immutable raw modules.
-/
def strategyTaggedCoverage (catalog : Raw.StrategyCatalog model)
    (source : Raw.Library catalog) (strategy : model.StrategyId) :
    Finset (TaggedRequirement model) :=
  ((Finset.univ.filter fun belief =>
      catalog.operationalProfile strategy belief =
        operationalFrontier catalog source belief).image
      TaggedRequirement.frontier) ∪
    ((catalog.strategyModules strategy).image TaggedRequirement.module)

/-- The union of the tag sets covered by all selected strategies. -/
def selectedTaggedCoverage (catalog : Raw.StrategyCatalog model)
    (source candidate : Raw.Library catalog) :
    Finset (TaggedRequirement model) :=
  candidate.strategies.biUnion (strategyTaggedCoverage catalog source)

/-- A source sublibrary covers every source tag. -/
def TaggedCoverFeasible (catalog : Raw.StrategyCatalog model)
    (source candidate : Raw.Library catalog) : Prop :=
  candidate ≤ source ∧
    sourceTaggedRequirements catalog source ⊆
      selectedTaggedCoverage catalog source candidate

/-- Exact binary indicator of retained strategy membership. -/
noncomputable def retentionIndicator {catalog : Raw.StrategyCatalog model}
    (candidate : Raw.Library catalog) (strategy : model.StrategyId) : ℚ := by
  classical
  exact if strategy ∈ candidate then 1 else 0

/-- Additive library burden is exactly the weighted binary-cover objective. -/
theorem libraryBurden_eq_weightedBinaryObjective
    {catalog : Raw.StrategyCatalog model}
    (weights : StrategyResourceWeights model catalog.inactiveStrategy)
    (candidate : Raw.Library catalog) :
    libraryBurden weights candidate =
      ∑ strategy : model.StrategyId,
        weights.resourceWeight strategy * retentionIndicator candidate strategy := by
  classical
  unfold libraryBurden resourceBurden
  calc
    candidate.strategies.sum weights.resourceWeight =
        ((Finset.univ : Finset model.StrategyId).filter fun strategy =>
          strategy ∈ candidate).sum weights.resourceWeight := by
      congr 1
      ext strategy
      simp
    _ = ∑ strategy : model.StrategyId,
          if strategy ∈ candidate then weights.resourceWeight strategy else 0 := by
      rw [Finset.sum_filter]
    _ = ∑ strategy : model.StrategyId,
          weights.resourceWeight strategy * retentionIndicator candidate strategy := by
      apply Finset.sum_congr rfl
      intro strategy _
      by_cases hmember : strategy ∈ candidate <;>
        simp [retentionIndicator, hmember]

@[simp]
theorem frontier_mem_sourceTaggedRequirements
    (catalog : Raw.StrategyCatalog model) (source : Raw.Library catalog)
    (belief : model.Belief) :
    TaggedRequirement.frontier belief ∈
      sourceTaggedRequirements catalog source := by
  simp [sourceTaggedRequirements]

@[simp]
theorem module_mem_sourceTaggedRequirements_iff
    (catalog : Raw.StrategyCatalog model) (source : Raw.Library catalog)
    (moduleId : model.ModuleId) :
    TaggedRequirement.module moduleId ∈
        sourceTaggedRequirements catalog source ↔
      moduleId ∈ rawModuleUnion catalog source := by
  simp [sourceTaggedRequirements]

@[simp]
theorem frontier_mem_strategyTaggedCoverage_iff
    (catalog : Raw.StrategyCatalog model) (source : Raw.Library catalog)
    (strategy : model.StrategyId) (belief : model.Belief) :
    TaggedRequirement.frontier belief ∈
        strategyTaggedCoverage catalog source strategy ↔
      catalog.operationalProfile strategy belief =
        operationalFrontier catalog source belief := by
  simp [strategyTaggedCoverage]

/-- Every zero-source-frontier row is covered by the mandatory inactive strategy. -/
theorem inactive_covers_zero_frontier
    (catalog : Raw.StrategyCatalog model) (source : Raw.Library catalog)
    (belief : model.Belief)
    (hzero : operationalFrontier catalog source belief = 0) :
    TaggedRequirement.frontier belief ∈
      strategyTaggedCoverage catalog source catalog.inactiveStrategy := by
  exact (frontier_mem_strategyTaggedCoverage_iff
    catalog source catalog.inactiveStrategy belief).2
      ((catalog.inactiveProfile belief).trans hzero.symm)

@[simp]
theorem module_mem_strategyTaggedCoverage_iff
    (catalog : Raw.StrategyCatalog model) (source : Raw.Library catalog)
    (strategy : model.StrategyId) (moduleId : model.ModuleId) :
    TaggedRequirement.module moduleId ∈
        strategyTaggedCoverage catalog source strategy ↔
      moduleId ∈ catalog.strategyModules strategy := by
  simp [strategyTaggedCoverage]

@[simp]
theorem mem_selectedTaggedCoverage_iff
    (catalog : Raw.StrategyCatalog model) (source candidate : Raw.Library catalog)
    (requirement : TaggedRequirement model) :
    requirement ∈ selectedTaggedCoverage catalog source candidate ↔
      ∃ strategy ∈ candidate,
        requirement ∈ strategyTaggedCoverage catalog source strategy := by
  simp [selectedTaggedCoverage]

/--
For a source sublibrary, frontier equality is equivalent to retaining a source
frontier attainer at every belief.  Ties are existential: no distinguished
maximizer is selected.
-/
theorem operationalFrontier_eq_iff_sourceAttainers
    (catalog : Raw.StrategyCatalog model) {source candidate : Raw.Library catalog}
    (hinclude : candidate ≤ source) :
    operationalFrontier catalog candidate = operationalFrontier catalog source ↔
      ∀ belief, ∃ strategy ∈ candidate,
        catalog.operationalProfile strategy belief =
          operationalFrontier catalog source belief := by
  constructor
  · intro hfrontier belief
    obtain ⟨strategy, hstrategy, hattains⟩ :=
      exists_profile_eq_operationalFrontier catalog candidate belief
    exact ⟨strategy, hstrategy, hattains.trans (congrFun hfrontier belief)⟩
  · intro hattainers
    funext belief
    apply le_antisymm
    · exact operationalFrontier_mono catalog hinclude belief
    · obtain ⟨strategy, hstrategy, hattains⟩ := hattainers belief
      calc
        operationalFrontier catalog source belief =
            catalog.operationalProfile strategy belief := hattains.symm
        _ ≤ operationalFrontier catalog candidate belief :=
          operationalProfile_le_frontier catalog candidate hstrategy belief

/--
Under identity closure, closure equality is equivalent to retaining a carrier
of every source module.  Multiple carriers are handled existentially.
-/
theorem generativeClosure_identity_eq_iff_sourceCarriers
    (catalog : Raw.StrategyCatalog model) {source candidate : Raw.Library catalog}
    (hinclude : candidate ≤ source) :
    generativeClosure catalog (identityModuleClosure model) candidate =
        generativeClosure catalog (identityModuleClosure model) source ↔
      ∀ moduleId ∈ rawModuleUnion catalog source,
        ∃ strategy ∈ candidate,
          moduleId ∈ catalog.strategyModules strategy := by
  constructor
  · intro hclosure moduleId hsource
    have hcandidateClosed :
        moduleId ∈
          generativeClosure catalog (identityModuleClosure model) candidate := by
      rw [hclosure]
      simpa using hsource
    have hcandidate : moduleId ∈ rawModuleUnion catalog candidate := by
      simpa using hcandidateClosed
    exact (mem_rawModuleUnion catalog candidate moduleId).mp hcandidate
  · intro hcarriers
    apply Finset.Subset.antisymm
    · simpa using rawModuleUnion_mono catalog hinclude
    · intro moduleId hsource
      obtain ⟨strategy, hstrategy, hmodule⟩ := hcarriers moduleId hsource
      simpa using
        (mem_rawModuleUnion catalog candidate moduleId).2
          ⟨strategy, hstrategy, hmodule⟩

/--
Exact tagged-cover equivalence for identity closure.

Both library values already contain the mandatory inactive strategy by type.
Consequently every zero-frontier belief tag is covered by that strategy.  The
theorem retains all belief tags rather than deleting those automatic rows.
-/
theorem safeCompressionFeasible_identity_iff_taggedCover
    (catalog : Raw.StrategyCatalog model) (source candidate : Raw.Library catalog) :
    SafeCompressionFeasible catalog (identityModuleClosure model) source candidate ↔
      TaggedCoverFeasible catalog source candidate := by
  constructor
  · rintro ⟨hinclude, hstate⟩
    refine ⟨hinclude, ?_⟩
    have hfrontier :
        operationalFrontier catalog candidate =
          operationalFrontier catalog source :=
      operationalFrontier_eq_of_compressedLibraryState_eq
        catalog (identityModuleClosure model) hstate
    have hclosure :
        generativeClosure catalog (identityModuleClosure model) candidate =
          generativeClosure catalog (identityModuleClosure model) source :=
      generativeClosure_eq_of_compressedLibraryState_eq
        catalog (identityModuleClosure model) hstate
    intro requirement hrequirement
    cases requirement with
    | frontier belief =>
        obtain ⟨strategy, hstrategy, hattains⟩ :=
          (operationalFrontier_eq_iff_sourceAttainers catalog hinclude).1
            hfrontier belief
        exact (mem_selectedTaggedCoverage_iff
          catalog source candidate (TaggedRequirement.frontier belief)).2
          ⟨strategy, hstrategy,
            (frontier_mem_strategyTaggedCoverage_iff
              catalog source strategy belief).2 hattains⟩
    | module moduleId =>
        have hsource : moduleId ∈ rawModuleUnion catalog source :=
          (module_mem_sourceTaggedRequirements_iff
            catalog source moduleId).1 hrequirement
        obtain ⟨strategy, hstrategy, hmodule⟩ :=
          (generativeClosure_identity_eq_iff_sourceCarriers
            catalog hinclude).1 hclosure moduleId hsource
        exact (mem_selectedTaggedCoverage_iff
          catalog source candidate (TaggedRequirement.module moduleId)).2
          ⟨strategy, hstrategy,
            (module_mem_strategyTaggedCoverage_iff
              catalog source strategy moduleId).2 hmodule⟩
  · rintro ⟨hinclude, hcover⟩
    refine ⟨hinclude, ?_⟩
    have hfrontier :
        operationalFrontier catalog candidate =
          operationalFrontier catalog source :=
      (operationalFrontier_eq_iff_sourceAttainers catalog hinclude).2 fun belief => by
        have hcovered := hcover (frontier_mem_sourceTaggedRequirements
          catalog source belief)
        obtain ⟨strategy, hstrategy, hattains⟩ :=
          (mem_selectedTaggedCoverage_iff
            catalog source candidate (TaggedRequirement.frontier belief)).1 hcovered
        exact ⟨strategy, hstrategy,
          (frontier_mem_strategyTaggedCoverage_iff
            catalog source strategy belief).1 hattains⟩
    have hclosure :
        generativeClosure catalog (identityModuleClosure model) candidate =
          generativeClosure catalog (identityModuleClosure model) source :=
      (generativeClosure_identity_eq_iff_sourceCarriers catalog hinclude).2
        fun moduleId hsource => by
          have hrequired : TaggedRequirement.module moduleId ∈
              sourceTaggedRequirements catalog source :=
            (module_mem_sourceTaggedRequirements_iff
              catalog source moduleId).2 hsource
          obtain ⟨strategy, hstrategy, hmodule⟩ :=
            (mem_selectedTaggedCoverage_iff
              catalog source candidate (TaggedRequirement.module moduleId)).1
              (hcover hrequired)
          exact ⟨strategy, hstrategy,
            (module_mem_strategyTaggedCoverage_iff
              catalog source strategy moduleId).1 hmodule⟩
    unfold compressedLibraryState
    rw [hfrontier, hclosure]

end Optimization

end StrategyInnovation
