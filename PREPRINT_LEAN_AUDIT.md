# Public Preprint Lean Audit

Audit date: 2026-08-19

Audited branch: `codex/optimization-revision`

Audited scope: the 55 labeled mathematical result environments in the public
preprint, the unnumbered bridge/channel/duration claims that cite formal
support, all 101 project Lean modules under `formal/StrategyInnovation`, the
root module `formal/StrategyInnovation.lean`, the public correspondence table,
and every active theorem-ledger record used by those results.

## Verdict

The clean formal gate passes.  `lake clean && lake build` rebuilt all 3,212
jobs.  The project-source scan found no `sorry`, `admit`, user `axiom`,
`unsafe`, `native_decide`, `implemented_by`, `opaque`, `partial`, `extern`,
tactic hole, TODO/FIXME, or placeholder marker.  The comprehensive audit now
contains 752 individual `#print axioms` commands.  Their exact footprints are:

| Footprint | Declarations |
|---|---:|
| `[propext, Classical.choice, Quot.sound]` | 730 |
| `[propext, Quot.sound]` | 20 |
| no axioms | 2 |

The corrected public correspondence contains 276 exact declaration names.
Every one exists in the expected namespace, is present in
`formal/StrategyInnovation/Audit/AxiomAudit.lean`, elaborates from its stated
module path, and has a standard-only footprint: 271 report
`[propext, Classical.choice, Quot.sound]` and five report
`[propext, Quot.sound]`.  The five smaller-footprint declarations are
`StrategyInnovation.FiniteModel`, `StrategyInnovation.StrategyCatalog`,
`StrategyInnovation.Library`, `StrategyInnovation.InnovationState`, and
`StrategyInnovation.Projection.Model.PruningAlgorithmSpec`.

No project axiom or proof bypass supports a public claim.  Example A.2 remains
a valid exact human calculation with no exact Lean counterpart and is now
marked that way.  The passive gap-sum theorem remains a theorem only for its
named supporting frozen-library process.  The canonical `beta V_beta / V`
rows remain exact fixed-policy numerical elasticities, not an application of
the finite-exposure duration theorem.

## Audit conventions

- `PCQ` abbreviates `[propext, Classical.choice, Quot.sound]`; `PQ`
  abbreviates `[propext, Quot.sound]`.
- Declaration lists below give the principal manuscript-facing names.  The
  exhaustive declaration list is the 276-name table in
  `manuscript/online_supplement/lean_correspondence.tex`; it was checked as a
  set against the 752-name comprehensive axiom gate with zero missing names.
- A name following a fully qualified name in the same table cell inherits that
  namespace.  Source paths are relative to `formal/StrategyInnovation/`.
- The 55 result environments have 58 result-level labels because three carry
  an additional compatibility label.  Three further `eq:` anchors label a
  display inside an already-audited result; they are not separate result
  environments.  The sole extra correspondence label is the manuscript's
  formal assumption `asm:raw-closure-detectability`.
- A row saying `PCQ` means that every listed theorem in that row printed that
  exact footprint.  Mixed definition rows identify the exception explicitly.
- `Deps:` clauses record direct manuscript-level dependencies.  Where a row's
  dependency is definitional, the defining declaration is listed in the same
  row; the complete dependency IDs and proof order remain in
  `THEOREM_LEDGER.md`.  Each reported `#print axioms` footprint was computed
  over Lean's full transitive declaration dependency closure.
- “PASS after wording reconciliation” means the public statement was narrowed
  or made explicit to match an already complete Lean theorem.  No theorem
  scope was expanded and no Lean proof was changed.

## Result-by-result audit

### Main results: model, compression, resources, value, and control

| Manuscript result | Lean declaration | Source file | Assumptions | `#print axioms` | Build status | Scope match | Result |
|---|---|---|---|---|---|---|---|
| Definition 3.1, compressed frontier--closure state | `StrategyInnovation.FiniteModel`; `StrategyCatalog`; `Library`; `operationalFrontier`; `rawModuleUnion`; `generativeClosure`; `InnovationState`; `compressedLibraryState` | `Library/{Strategy,Library,Frontier,Closure,InnovationState}.lean` | Finite carriers, inactive-containing library, exact profiles, extensive/monotone/idempotent closure. Deps: F0 library calculus. | Four carrier declarations `PQ`; four functions `PCQ` | PASS | Exact. Productive state excludes burden. | **PASS** |
| Theorem 3.2, raw-to-compressed projection | `Projection.Model.inducedCompressedTransition_wellDefined`; `same_compressedState_same_next_probability`; `projectedProcess_controlledMarkov`; `rawValue_eq_compressedValue`; `rawInfiniteHorizonValue_eq_compressed`; `liftedRawStationarySelector_policyEvaluationEquation` | `Projection/RawToCompressed.lean`; `Bellman/Unified.lean` | Finite exact raw model; factorization through compressed state; declared joint path/outcome law; positive duration; stationary clauses use `0 <= beta < 1`. Deps: R0, S2. | `PCQ` | PASS | Exact for the profile-table model. No independence, hidden-state expectation adapter, or unaugmented calendar-time Markov claim. | **PASS** |
| Theorem 4.1, minimum-resource safe representation | `Optimization.exactSafeCompressionFeasible_source`; `exactSafeCompressionFeasibleSet_finite`; `exists_minimumWeight_exactSafeCompression`; `exists_minimumWeightSafeCompression`; `SafeCompressionFeasible.preserves_finiteHorizonValue`; `.preserves_infiniteHorizonValue`; `.preserves_optimalActions` | `Optimization/SafeCompression.lean` | Finite source-relative exact-safe fiber and additive burden; stationary clauses add contraction. Deps: F0, T1, S2. No uniqueness or detectability for forward preservation. | `PCQ` | PASS | Exact through separate declarations; no monolithic theorem is claimed. | **PASS** |
| Definition 4.2, deletion redundancy | `Projection.Model.operationallyRedundant`; `generativelyRedundant`; `InnovationSafeDeletion` | `Compression/UnifiedSafeDeletion.lean` | Active retained strategy; full frontier and closed-capability equality after erasure. Deps: F0. | `PCQ` | PASS | Exact raw-library deletion predicates. | **PASS** |
| Definition 4.3, dynamic innovation equivalence | `Projection.Model.DynamicInnovationEquivalent` | `Quotient/UnifiedDynamicInnovation.lean` | Equality of five availability-tagged observations for every belief/project, including the joint terminal law. Deps: T1 raw process. | `PCQ` | PASS | Exact; conditional independence is not assumed. | **PASS** |
| Theorem 4.5, frontier--closure characterization and safe deletion | `frontierClosure_eq_implies_rawLaws_and_dynamicEquivalence`; `frontierClosure_eq_implies_dynamicInnovationEquivalent`; `dynamicInnovationEquivalent_implies_frontierClosure_eq`; `dynamicInnovationEquivalent_iff_frontierClosure_eq`; `redundantDeletion_iff_compressedLibraryState_eq`; `deletionProcessObservations_iff_redundant`; stationary preservation declarations | `Quotient/RawFrontierClosure.lean`; `Compression/UnifiedSafeDeletion.lean` | Raw factorization for sufficiency; `RawClosureDetectable` only for the converse; contraction only for stationary value/action clauses. Deps: T1, UDI. | `PCQ` | PASS | Exact; closure, factorization, and detectability remain distinct. | **PASS** |
| Corollary 4.6, rechecked pruning | `RedundantDeletionSequence.compressedLibraryState_final_eq_initial`; `.everyDeletion_innovationSafe`; `.dynamicInnovationEquivalent`; `.preserves_finiteHorizonValue`; `.preserves_infiniteHorizonValue`; `Optimization.recheckedSafeDeletionEndpoint_feasible` | `Compression/UnifiedSafeDeletion.lean`; `Optimization/SafeCompression.lean` | Every deletion is recomputed on the current library; final scan complete for irreducibility. Deps: Theorem 4.5. | `PCQ` | PASS | PASS after correcting the prose: one-deletion and inclusion-wise irreducibility coincide in this monotone fiber; neither is global optimality. | **PASS after wording reconciliation** |
| Proposition 4.7, certified pruning | `Projection.Model.PruningAlgorithmSpec`; `.everyDeletion_safe`; `.output_dynamicInnovationEquivalent`; `.output_preserves_finiteHorizonValue` | `Compression/UnifiedSafeDeletion.lean` | Output carries a current-state-rechecked trace. Deps: Theorem 4.5, Corollary 4.6. | structure `PQ`; theorem fields `PCQ` | PASS | Exact; no optimizer claim. | **PASS** |
| Example 4.8, rechecking deletion classes | `UnifiedSafeDeletionExamples.duplicateLeft_innovationSafe`; `.moduleOnly_operationallyRedundant_generativelyEssential`; `.operationalOnly_generativelyRedundant_operationallyEssential`; `.duplicateEncoding_orderChangesRawRepresentative`; `.stale_doubleDeletion_changes_compressedState`; `.staleOriginalRedundancyChecks_doNotCompose` | `Compression/UnifiedSafeDeletionExamples.lean` | Exact finite catalog with duplicate/unique carriers. Deps: T3 definitions. | `PCQ` | PASS | Exact counterexample to stale reuse only. | **PASS** |
| Theorem 4.9, local/global boundary | `Optimization.MinimumWeightSafeCompression.oneDeletionIrreducible`; `recheckedSafeDeletionEndpoint_feasible`; `SafeCompressionCounterexample.recheckedEndpoint_need_not_be_globallyMinimum`; `.strictHeaviestFirst_greedy_not_globallyOptimal` | `Optimization/SafeCompression.lean`; `Optimization/SafeCompressionCounterexample.lean` | Strictly positive active weights and exact-safe fiber. Deps: burden erasure strictness and finite exact counterexamples. | `PCQ` | PASS | Exact; no converse, approximation ratio, or hidden uniqueness. | **PASS** |
| Example 4.10, safe greedy versus global optimum | `SafeCompressionCounterexample.greedy_pair_weight_eq_four`; `.greedy_bundle_weight_eq_three`; `.bundle_is_uniqueHeaviestSafeDeletion`; `.strictHeaviestFirst_greedy_not_globallyOptimal` | `Optimization/SafeCompressionCounterexample.lean` | Identity closure; weights `(2,2,3)`; zero profiles; exact carrier sets. | `PCQ` | PASS | Exact exhaustive finite witness. | **PASS** |
| Theorem 4.11, sharp normalized frontier-only loss | `NormalizedPruningLoss.canonicalConstruction_certificate`; `.canonicalPruningLoss_exact`; `.rewardCap_sharp`; `.destroys_all_attainable_descendant_value`; `.unitRewardCap_loss_le_one`; `.canonicalPruningLossWithOperation_exact`; `.continuedOperation_cancels_under_operationalRedundancy` | `Compression/NormalizedPruningLoss.lean` | Canonical one-project bridge; complete capped terminal gain; common operating comparator; `d >= 1`; rational probability/discount bounds; worthwhile margin. Deps: T1 timing. | `PCQ` | PASS | PASS after defining `Loss_d` and the canonical comparison class. | **PASS after wording reconciliation** |
| Corollary 4.12, arbitrary additive loss by scaling | `NormalizedPruningLoss.arbitraryLoss_by_rewardScaling` | `Compression/NormalizedPruningLoss.lean` | Theorem 4.11 with `(d,beta,rho,pi,kappa,C)=(1,1/2,1,1,0,2M)`. | `PCQ` | PASS | Exact; additive, not normalized, unboundedness. | **PASS** |
| Theorem 4.13, capacity-constrained retention | `FiniteCapacityProblem.exists_capacityOptimizer_of_inactive_feasible`; `.capacityValue_mono`; `.capacityValue_constant_between_attainableBurdens`; `.capacityBreakpointSet_subset_attainableBurdens`; `.capacityBreakpointSet_finite`; `.discreteShadowValue_nonnegative`; `CapacityComplementarityCounterexample.capacityValue_zero`; `.capacityValue_one`; `.capacityValue_two`; `.increasing_marginal_capacity_value`; `.diminishing_capacity_returns_fail` | `Optimization/CapacityValue.lean`; `Optimization/CapacityCounterexample.lean` | Fixed finite capacity-independent family with zero-burden inactive library; finite values; no uniqueness/nesting. Deps: finite maximum and feasible-set inclusion. | `PCQ` | PASS | PASS after replacing ordinary-concavity wording in the formal theorem with the exact failure of diminishing unit increments. The broader human observation remains unbranded as Lean verification. | **PASS after wording reconciliation** |
| Theorem 4.14, penalized finite envelope | `FinitePenalizedProblem.envelope_is_finite_maximum`; `.envelope_antitone`; `.envelope_convex`; `.continuous_envelope`; `.pairwiseSwitchingPriceSet_finite`; `.breakpointSet_subset_pairwiseSwitchingPrices`; `.breakpointSet_finite`; `.optimalBurden_antitone`; `.hasDerivAt_envelope_of_strictlyDominatesOn` | `Optimization/PenalizedEnvelope.lean` | Fixed nonempty finite price-independent family, finite values, nonnegative burdens, real `lambda >= 0`; derivative only on a strictly dominant branch. | `PCQ` | PASS | Exact; candidates are not asserted to be active kinks and ties are retained. | **PASS** |
| Definition 5.1, insertion channels | `UnifiedDecomposition.compressedPassiveValue`; `.passiveValue`; `.fullValue`; `.compressedFullValue`; `.researchOptionPremium`; `.totalInsertionValue`; `.operationalInsertionValue`; `.generativeInsertionValue` | `Value/UnifiedDecomposition.lean` | Unified finite raw process and passive frozen-library recursion. Deps: T1. | `PCQ` | PASS | Exact; generative value is a residual with no unconditional sign. | **PASS** |
| Theorem 5.2, operational--generative decomposition | `UnifiedDecomposition.passiveValue_eq_compressedPassiveValue`; `.fullValue_eq_compressedFullValue`; `.totalInsertionValue_eq_operational_add_generative` | `Value/UnifiedDecomposition.lean` | Same horizon/belief/library/candidate across full and passive values. Deps: Definition 5.1 and T1 projection. | `PCQ` | PASS | Exact identity; no independence or closure-only split. | **PASS** |
| Corollary 5.3, frontier-silent insertion | `UnifiedDecomposition.operationalInsertionValue_eq_zero_of_frontier_eq`; `.totalInsertionValue_eq_zero_of_frontier_closure_eq` | `Value/UnifiedDecomposition.lean` | Frontier equality for operational zero; frontier and closure equality for total zero. Deps: Theorem 5.2, T1. | `PCQ` | PASS | Exact one-way statements. | **PASS** |
| Example 5.4, operationally silent bridge | `UnifiedDecomposition.BridgeExample.bridge_operational_zero_generative_positive` | `Value/UnifiedDecomposition.lean` | One belief, duration one, zero cost, unique module carrier, descendant payoff two. | `PCQ` | PASS | Exact positive generative residual. | **PASS** |
| Theorem 5.5, joint descendant-event lower bound | `GenerativeLowerBound.JointGenerativeCarrierCertificate`; `.jointDescendantMass`; `.jointDescendantEventMass`; `.expectedJointDescendantGain_eq_terminalWeighted`; `.operatingResearchAdjustment_eq_exactBlocks`; `.projectCommitmentValue_eq_cost_operating_joint_remaining`; `.expectedRemainingContinuationGain_nonnegative`; `.generalizedGenerativeOptionLowerBound` | `Value/GenerativeLowerBound.lean`; `Value/JointDescendantLowerBound.lean` | Frontier silent; project enabled only with carrier; `d <= h`; explicit cost, operating block, frozen continuation, joint event gain floor, nonnegative omitted outcomes, zero-premium comparator. | `PCQ` | PASS | Exact; duration has no unconditional sign. | **PASS** |
| Corollary 5.6, independent product and signs | `expectedJointDescendantGain_eq_independentProduct`; `generalizedJointDescendantGain_eq_independentProduct`; `GenerativeCarrierCertificate`; `.toJoint`; `generalizedGenerativeOptionLowerBound_of_independence`; joint bound sign/monotonicity declarations | `Value/GenerativeLowerBound.lean`; `Value/JointDescendantLowerBound.lean` | Adds conditional factorization only for the product specialization; sign clauses keep cost and operating adjustment explicit. | `PCQ` | PASS | Exact; independence is not imported into the parent theorem. | **PASS** |
| Proposition 5.7, channel elasticity contributions | `Value.ChannelAccountingAt`; `operational_generative_derivative_decomposition`; `operational_generative_scaledDerivative_decomposition`; `operational_generative_contribution_decomposition`; `positive_channel_shares`; `operational_generative_weightedAverage_elasticity` | `Value/ChannelElasticity.lean` | `I=O+G` on a neighborhood; same named path; common differentiable perturbation; `x0>0`; total positivity for normalized contributions; channel positivity for component log elasticities. | `PCQ` | PASS | PASS after moving the neighborhood accounting identity into the proposition. | **PASS after wording reconciliation** |
| Definition 5.8, positive gap and discounted gap sum | `InnovationEquation.frontierGap`; `.discountedGapSum`; `.passiveOperationalInnovation` | `Value/InnovationEquation.lean` | Fixed candidate, frozen library, finite horizon and belief kernel. | `PCQ` | PASS | Exact supporting process definitions. | **PASS** |
| Proposition 5.9, passive gap-sum identity | `InnovationEquation.passiveOperationalInnovation_eq_discountedGapSum` | `Value/InnovationEquation.lean` | Supporting frozen-library/no-research process; auxiliary insertion is the passive-value difference. Deps: Definition 5.8. | `PCQ` | PASS | Exact after defining the manuscript auxiliary notation; not a generic adapter to every unified process. | **PASS after wording reconciliation** |
| Corollary 5.10, zero current gap and positive future value | `InnovationEquation.DelayedBenefitExample.zero_currentGap_positive_passiveOperationalInnovation` | `Value/InnovationEquation.lean` | Exact two-date deterministic transition with later gap two and `beta=1/2`. | `PCQ` | PASS | Exact finite example. | **PASS** |
| Proposition 5.11, diminishing operational insertion | `UnifiedDecomposition.operationalInsertionValue_antitone_of_library_inclusion` | `Value/UnifiedDecomposition.lean` | Library inclusion and fixed candidate/process. Deps: frontier monotonicity and passive recursion. | `PCQ` | PASS | Exact operational channel only. | **PASS** |
| Definition 6.1, Bellman operators | `Projection.Model.compressedInfiniteActionValue`; `.compressedBellmanOperator`; `.rawBellmanOperator` | `Bellman/Unified.lean` | Finite Continue-augmented action carrier; exact joint completion law; positive project duration. | `PCQ` | PASS | Exact after making the empty-project-menu convention explicit. | **PASS after wording reconciliation** |
| Proposition 6.2, contraction and selectors | `finiteHorizonAction_attained`; `rawFiniteHorizonAction_attained`; `compressedBellmanOperator_mono`; `rawBellmanOperator_mono`; `compressedBellmanOperator_contracting`; `rawBellmanOperator_contracting`; `infiniteHorizonValue_isFixedPoint`; `infiniteHorizonValue_unique`; `valueIteration_tendsto_infiniteHorizonValue`; `valueIteration_geometric_error_bound`; `finiteHorizon_rawValue_eq_compressedValue`; `rawInfiniteHorizonValue_eq_compressed`; `exists_stationaryOptimalSelector`; `stationaryOptimalSelector_attains`; `stationaryOptimalSelector_policyEvaluationEquation`; `stationaryOptimalSelector_value_eq_infiniteHorizonValue`; `liftedRawStationarySelector_policyEvaluationEquation` | `Bellman/Unified.lean` | Finite carriers/actions; exact finite rewards; `0 <= beta < 1`; positive duration ensures research modulus no larger than `beta`. Deps: T1. | `PCQ` | PASS | Exact; uniqueness is for the fixed point, not the selector. | **PASS** |

### Appendix A results

| Manuscript result | Lean declaration | Source file | Assumptions | `#print axioms` | Build status | Scope match | Result |
|---|---|---|---|---|---|---|---|
| Lemma A.1, frontier and closure calculus | `operationalProfile_le_frontier`; `zero_le_operationalFrontier`; `exists_profile_eq_operationalFrontier`; `operationalFrontier_mono`; `rawModuleUnion_mono`; `generativeClosure_mono` | `Library/{Frontier,Closure}.lean` | Finite nonempty inactive-containing library, zero inactive profile, monotone closure. | `PCQ` | PASS | Exact. | **PASS** |
| Example A.2, two-module generator | none claimed | none | Exact displayed rational calculation and identity closure. | N/A | N/A | Valid human calculation; no exact Lean example declaration. | **HUMAN ONLY — not Lean-verified** |
| Proposition A.3, DI equivalence relation | `Projection.Model.dynamicInnovationEquivalent_refl`; `_symm`; `_trans` | `Quotient/UnifiedDynamicInnovation.lean` | Definition 4.3. | `PCQ` | PASS | Exact. | **PASS** |
| Theorem A.4, DI quotient and value sufficiency | `rawValue_eq_of_dynamicInnovationEquivalent`; `finiteHorizonValue_depends_only_on_dynamicInnovationClass`; `dynamicInnovationQuotientFinite`; `compressedState_eq_implies_dynamicInnovationEquivalent`; `DiscountedContractionModel.rawFixedPoint_eq_of_dynamicInnovationEquivalent` | `Quotient/UnifiedDynamicInnovation.lean`; `Bellman/Unified.lean` | DI equality; finite carrier; stationary clause adds contraction. | `PCQ` | PASS | Exact; no generic quotient minimality. | **PASS** |
| Proposition A.5, restricted representation refinement | `Projection.Model.representation_refines_dynamicInnovationEquivalent` | `Quotient/UnifiedDynamicInnovation.lean` | Representation equality is assumed to preserve all five DI observations. | `PCQ` | PASS | Exact restricted implication. | **PASS** |
| Proposition A.6, premium monotonicity | `UnifiedDecomposition.ClosureEnrichmentProjectDominance`; `.compressedValue_mono_of_closureEnrichmentProjectDominance`; `.fullValue_mono_of_closureEnrichmentProjectDominance`; `.researchOptionPremium_mono_of_closureEnrichmentProjectDominance` | `Value/UnifiedDecomposition.lean` | Equal frontier, preserved old menu, complete action-value dominance, possible added actions. | `PCQ` | PASS | Exact sufficient condition; closure inclusion alone is not used as dominance. | **PASS** |
| Example A.7, exact retained carrier | `GenerativeLowerBound.CarrierExample.jointCertificate`; `.operatingResearchAdjustment_eq_zero`; `.expectedJointDescendantGain_eq_two`; `.exact_joint_carrier_lowerBound_one`; `OneBeliefExample.exact_lowerBound_one`; `TwoBeliefExample` exact declarations | `Value/GenerativeLowerBound.lean`; `Value/JointDescendantLowerBound.lean` | Exact one-/two-belief carrier fixtures with positive duration and stated masses/gains. | `PCQ` | PASS | Exact. | **PASS** |
| Counterexample A.8, raw identifiers | `RawFrontierClosureCounterexamples.sufficiency_fails_when_generator_uses_raw_identifiers`; `.rawIdentifierGenerator_not_factorized` | `Quotient/RawFrontierClosure.lean` | Same frontier/closure; generator inspects raw identity, violating factorization. | `PCQ` | PASS | Exact boundary to forward sufficiency. | **PASS** |
| Counterexample A.9, invisible closure | `RawFrontierClosureCounterexamples.converse_fails_when_closure_behaviorally_invisible`; `.silentProcess_not_rawClosureDetectable` | `Quotient/RawFrontierClosure.lean` | Empty project menu; equal frontier; unequal but behaviorally silent closure. | `PCQ` | PASS | Exact boundary to detectability; empty menu is now total in Definition 6.1. | **PASS** |

### Appendix C coverage, comparative statics, and interaction

| Manuscript result | Lean declaration | Source file | Assumptions | `#print axioms` | Build status | Scope match | Result |
|---|---|---|---|---|---|---|---|
| Counterexample C.1, nonmonotone kernel | `SingleGapCounterexamples.destructiveKernel_expectedGap`; `.singlePeakedGap_disconnectedPotential`; `.destructiveKernel_not_stochasticallyMonotone`; `.nonmonotoneKernel_disconnectedCostCoveringSet` | `Coverage/SingleGap.lean` | Exact three-state row-stochastic but nonmonotone kernel. | `PCQ` | PASS | Exact. | **PASS** |
| Counterexample C.2, non-antitone cost | `SingleGapCounterexamples.nonAntitoneCost_disconnectedCostCoveringSet` | `Coverage/SingleGap.lean` | Increasing potential and non-antitone cost `(0,3,0)`. | `PCQ` | PASS | Exact. | **PASS** |
| Counterexample C.3, multi-gap disconnection | `Counterexamples.MultiGapRegion.project_fills_two_separated_strategyLibraryGaps`; `.coveragePotential_eq`; `.strictCostCoveringSet_eq`; `.separatedMultiGap_disconnectedCostCoveringSet` | `Counterexamples/MultiGapRegion.lean` | Exact five-belief Bernstein kernel and two separated gaps. | `PCQ` | PASS | Exact one-shot boundary. | **PASS** |
| Counterexample C.4, arbitrary cost components | `Counterexamples.MultiGapRegion.unrestrictedCost_defeats_generalComponentBound` | `Counterexamples/MultiGapRegion.lean` | Constant potential and alternating unrestricted cost. | `PCQ` | PASS | Exact. | **PASS** |
| Definition C.5, coverage potential | `Coverage.certifiedGap`; `.expectedGap`; `.discountedOccupationWeight`; `.coveragePotential` | `Coverage/Potential.lean` | Fixed candidate, nonnegative finite occupation/gap tables. | `PCQ` | PASS | Exact gross operational object. | **PASS** |
| Theorem C.6, finite coverage representation | `Coverage.coveragePotential_eq_oneShotGrossOperationalResearchValue` | `Coverage/Potential.lean` | Definition C.5 finite tables. | `PCQ` | PASS | Exact finite rearrangement. | **PASS** |
| Corollary C.7, occupation bounds | `minimumGapOn_mul_regionOccupation_le_coveragePotential`; `coveragePotential_le_maximumGap_mul_totalOccupation`; `coveragePotential_le_maxGap_mul_regionOccupation` | `Coverage/Potential.lean` | Nonnegative gaps/weights; nonempty lower-bound region; support restriction for regional upper bound. | `PCQ` | PASS | Exact. | **PASS** |
| Example C.8, delayed coverage | `Coverage.DelayedCoverageExample.zero_currentGap_positive_coveragePotential` | `Coverage/Potential.lean` | Two beliefs, two dates, later gap two, `beta=1/2`. | `PCQ` | PASS | Exact. | **PASS** |
| Definition C.9, one-shot cost-covering region | `Coverage.grossCoverageValue`; `.oneShotCostCoveringSet` | `Coverage/SingleGap.lean` | Finite ordered grid, exact kernel, scale, gap, and cost tables. | `PCQ` | PASS | Exact one-shot definition, not Bellman region. | **PASS** |
| Theorem C.10, monotone-gap threshold | `Coverage.grossCoverageValue_monotone`; `.oneShotCostCoveringSet_isUpperSet`; `.monotoneGap_upperThreshold` | `Coverage/SingleGap.lean` | Nonempty finite linear order; row-stochastic stochastically monotone kernel; increasing nonnegative gap; nonnegative scale/discount; antitone cost. | `PCQ` | PASS | Exact. | **PASS** |
| Proposition C.11, cutoff comparative statics | `oneShotCostCoveringSet_antitone_cost`; `_mono_survival`; `_mono_admissionProbability`; `_antitone_frontier`; `cost_cutoff_mono`; `survival_cutoff_antitone`; `admissionProbability_cutoff_antitone`; `frontier_cutoff_mono` | `Coverage/SingleGap.lean` | Pointwise one-primitive change; other primitives fixed; nonempty sets for cutoff comparisons. | `PCQ` | PASS | Exact one-shot directions. | **PASS** |
| Theorem C.12, patience--survival complementarity | `DiscountSurvivalInteraction.finiteHorizonPotential_eq_sum`; `.finiteResolvent_mulVec_eq_finiteEffectivePotential`; `.finiteHorizonPotential_mono_discount`; `.finiteHorizonPotential_mono_survival`; `.discountIncrement_difference_eq_factorized`; `.discountIncrement_mono_survival`; `.finiteHorizonPotential_crossDifference_nonnegative` | `Coverage/DiscountSurvivalInteraction.lean` | Finite exact nonnegative row-stochastic matrix, nonnegative gap, finite horizon, ordered nonnegative discount/survival. | `PCQ` | PASS | Exact finite-horizon statement; no stationary resolvent derivative. | **PASS** |
| Proposition C.13, opposite persistence effects | `KernelComparativeStatics.persistenceKernel_stochastic`; `.higherPersistence_raises_coverage`; `.higherPersistence_lowers_coverage`; `.higherPersistence_no_effect`; `.no_universal_persistence_increase`; `.no_universal_persistence_decrease` | `Coverage/KernelComparativeStatics.lean` | Exact two-state, two-date persistence fixtures and three gaps. | `PCQ` | PASS | Exact; no universal sign. | **PASS** |
| Theorem C.14, occupation alignment | `KernelComparativeStatics.finiteEffectivePotential_eq_discountedOccupation`; `.coverage_mono_of_occupationDominatesOnAdvantage`; `.gapOccupationDominates_of_occupationDominatesOnAdvantage`; `.gapOccupationDominates_iff` | `Coverage/KernelComparativeStatics.lean` | Nonnegative gap and discounted-occupation dominance on every positive-gap state. | `PCQ` | PASS | Exact; scalar persistence is not substituted for alignment. | **PASS** |
| Definition C.15, closure interaction | `SystemInteraction.closureIncrement`; `.interactionCrossDifference`; `.compressedClosureIncrement`; `.compressedInteractionCrossDifference`; `.AreSubstitutes`; `.AreComplements` | `Value/SystemInteraction.lean` | Four realizable frontier--closure corners. | `PCQ` | PASS | Exact. | **PASS** |
| Theorem C.16, frontier--closure substitution | `SystemInteraction.FrontierClosureRectangle`; `.RelativeActionSaturation`; `.SubstitutionAssumptions`; `.compressedInteractionCrossDifference_nonpositive` | `Value/SystemInteraction.lean` | Realizable rectangle; frontier-independent primitives; rich-menu inclusion; all rich/poor action pairs satisfy relative saturation. | `PCQ` | PASS | Exact; optimizer switching is covered by the all-pairs premise. | **PASS** |
| Proposition C.17, primitive common-gap saturation | `SystemInteraction.CommonGapActionDecomposition`; `.relativeActionSaturation_of_commonGap`; `.PrimitiveSubstitutionAssumptions`; `.compressedInteractionCrossDifference_nonpositive_of_primitiveSaturation`; `PrimitiveSubstitution.recursiveGapValue`; `.recursiveGapValue_antitone`; `.RecursiveCommonGapActionDecomposition`; `.canonical_frontier_closure_substitutes` | `Value/SystemInteraction.lean`; `Interaction/PrimitiveSubstitution.lean` | Common-gap factorization, ordered gaps, nonnegative rich exposure, zero poor exposure, common positive kernel for recursion. | `PCQ` | PASS | Exact narrow sufficient condition. | **PASS** |
| Proposition C.18, complementarity by switching | `SystemInteraction.Examples.strict_substitution_example`; `.independent_menu_switch_individual_saturation`; `.independent_menu_switch_crossDifference_positive`; `.added_exposure_order_insufficient_for_allPairs`; `.frontier_dependent_success_strict_complementarity`; `.separable_zero_interaction`; corresponding `PrimitiveSubstitution.Examples` declarations | `Value/SystemInteraction.lean`; `Interaction/PrimitiveSubstitution.lean` | Exact one-belief menu-switch and boundary fixtures. | `PCQ` | PASS | Exact counterexample outside the relative-all-pairs premise. | **PASS** |

## Unnumbered manuscript-facing formal claims

| Manuscript result | Lean declaration | Source file | Assumptions | `#print axioms` | Build status | Scope match | Result |
|---|---|---|---|---|---|---|---|
| Bridge-margin derivatives and elasticities | `Compression.grossBridge`; `bridgeMargin`; `bridgeLoss`; all five `hasDerivAt_bridgeMargin_*`; all five `hasDerivAt_bridgeLoss_*`; `normalizedBridgeMargin`; `bridgeFragility`; all five `bridgeLoss_*_elasticity`; the four fragility-limit/boundary declarations; exact `BridgeExample` declarations | `Compression/BridgeMarginElasticity.lean` | Fixed integer duration; positive gross coordinates; strictly positive net margin for realized-loss derivatives; named coordinate varied alone. | `PCQ` | PASS | Exact on the positive-margin branch only. | **PASS** |
| Fixed-exposure innovation duration/convexity | `Coverage.innovationPotential`; `innovationFirstMoment`; `innovationSecondMoment`; derivative definitions; `innovationDuration`; `innovationWeight`; `innovationConvexity`; `innovationTimingVariance`; `scaled_potentialDerivative_eq_firstMoment`; `scaled_firstMomentDerivative_eq_secondMoment`; `innovationDuration_identity`; weighted-sum identities; `innovationConvexity_eq_timingVariance`; `scaled_durationDerivative_eq_timingVariance`; nonnegativity and exact examples | `Coverage/InnovationDuration.lean` | `alpha > 0`; fixed nonnegative nonzero finite exposure sequence; positive potential for normalization. | `PCQ` | PASS | PASS after displaying the verified scaled identities. Separate derivatives of `log(Psi(exp theta))` are not claimed as named Lean declarations. | **PASS after wording reconciliation** |
| Canonical `D_beta = beta V_beta / V` rows | no model-specific Lean adapter claimed | exact Julia benchmark artifacts | Fixed selected policy/library and positive value; exact rational local derivative. | N/A | N/A for Lean | Explicitly labeled fixed-policy discount elasticities, not finite-exposure duration. | **EXACT JULIA ONLY — not Lean-verified** |

## Public correspondence and ledger reconciliation

The previous online correspondence table omitted seven active result labels.
It now includes minimum safe compression, the local/global theorem, the
worked greedy example, capacity retention, the penalized envelope, channel
elasticity, and the two-module example.  The last is explicitly marked as
having no exact Lean counterpart.  The resulting label comparison is exact:
all 58 active result labels (55 environments plus three deliberate alias
labels) occur in the correspondence, together with the separately labeled
closure-detectability assumption.

The theorem ledger's stale “planned optimization T6/T7/T8/T9” locations were
replaced by the current public labels `thm:penalized-envelope`,
`thm:capacity-value`, `prop:channel-elasticity`,
`eq:bridge-elasticities`, and `eq:innovation-duration`.  Every declaration
named by those records exists in its recorded namespace/module.  The ledger
continues to distinguish human validity, Lean verification of the encoded
slice, exact Julia validation, and empirical evidence.

## Release rule

Only rows classified **PASS** or **PASS after wording reconciliation** may be
described as Lean-verified, and only for the encoded scope in the row.
Example A.2 and the canonical fixed-policy discount-elasticity rows must not
be described as Lean-verified.  The supporting F7 passive equation must not
be promoted to a generic unified-process adapter.  No Lean-verification text
was added to the abstract or introduction.
