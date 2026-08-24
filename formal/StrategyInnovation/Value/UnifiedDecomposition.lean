import Mathlib.Tactic
import StrategyInnovation.Compression.NormalizedPruningLoss
import StrategyInnovation.Quotient.RawFrontierClosure

/-!
# Unified operational--generative insertion value (T5)

This module rebuilds the insertion-value decomposition on the raw process and
the compressed projection of `Projection.RawToCompressed`.

Passive value freezes the current library and permits only Continue.  Full
value is the unified raw finite-calendar value, including positive project
duration, initiation cost, the declared (possibly correlated) completion law,
and the exact incumbent operating-reward block.  The decomposition itself is
an algebraic identity.  Sign and monotonicity conclusions use explicit
frontier or project-dominance assumptions.
-/

namespace StrategyInnovation

namespace Projection

namespace Model

namespace UnifiedDecomposition

variable {model : FiniteModel}
variable {catalog : Raw.StrategyCatalog model}
variable {closure : Raw.ClosureOperator model}

/--
Compressed passive value: Continue at every remaining calendar date while
holding the compressed library state fixed.
-/
noncomputable def compressedPassiveValue
    (process : Model model catalog closure) :
    Nat → model.Belief → CompressedLibraryState catalog closure → ℚ
  | 0, _, _ => 0
  | horizon + 1, belief, state =>
      state.state.frontier belief +
        process.discount *
          (process.beliefTransition belief).expectation
            (fun nextBelief =>
              compressedPassiveValue process horizon nextBelief state)

/--
Raw passive value: Continue at every remaining calendar date with the current
raw library frozen and no research action available.
-/
noncomputable def passiveValue
    (process : Model model catalog closure) :
    Nat → model.Belief → Raw.Library catalog → ℚ
  | 0, _, _ => 0
  | horizon + 1, belief, library =>
      operationalFrontier catalog library belief +
        process.discount *
          (process.beliefTransition belief).expectation
            (fun nextBelief =>
              passiveValue process horizon nextBelief library)

/-- Raw and compressed passive values agree under actual compression. -/
theorem passiveValue_eq_compressedPassiveValue
    (process : Model model catalog closure) :
    ∀ horizon belief library,
      passiveValue process horizon belief library =
        compressedPassiveValue process horizon belief
          (CompressedLibraryState.ofLibrary catalog closure library) := by
  intro horizon
  induction horizon with
  | zero =>
      intro belief library
      rfl
  | succ horizon inductionHypothesis =>
      intro belief library
      simp only [passiveValue, compressedPassiveValue]
      apply congrArg
        (fun continuation =>
          operationalFrontier catalog library belief +
            process.discount * continuation)
      apply RatProb.expectation_congr
      intro nextBelief
      exact inductionHypothesis nextBelief library

/-- Full raw-library value with every feasible unified research action allowed. -/
noncomputable def fullValue (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) : ℚ :=
  process.rawValue horizon belief library

/-- Full value on the finite realizable compressed-state carrier. -/
noncomputable def compressedFullValue
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (state : CompressedLibraryState catalog closure) : ℚ :=
  process.compressedValue horizon belief state

/-- T1 identifies full raw value with full compressed value. -/
theorem fullValue_eq_compressedFullValue
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) :
    fullValue process horizon belief library =
      compressedFullValue process horizon belief
        (CompressedLibraryState.ofLibrary catalog closure library) := by
  exact process.rawValue_eq_compressedValue horizon belief library

/-- Research-option premium: full value less frozen-library passive value. -/
noncomputable def researchOptionPremium
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) : ℚ :=
  fullValue process horizon belief library -
    passiveValue process horizon belief library

/-- Total full-value gain from inserting one catalog strategy. -/
noncomputable def totalInsertionValue
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId) : ℚ :=
  fullValue process horizon belief (library.insert strategy) -
    fullValue process horizon belief library

/-- Frozen-library operational gain from inserting one catalog strategy. -/
noncomputable def operationalInsertionValue
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId) : ℚ :=
  passiveValue process horizon belief (library.insert strategy) -
    passiveValue process horizon belief library

/-- Change in research-option premium caused by one strategy insertion. -/
noncomputable def generativeInsertionValue
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId) : ℚ :=
  researchOptionPremium process horizon belief (library.insert strategy) -
    researchOptionPremium process horizon belief library

/--
T5 accounting identity: total insertion value is operational insertion value
plus the insertion-induced change in the research-option premium.
-/
theorem totalInsertionValue_eq_operational_add_generative
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId) :
    totalInsertionValue process horizon belief library strategy =
      operationalInsertionValue process horizon belief library strategy +
        generativeInsertionValue process horizon belief library strategy := by
  unfold totalInsertionValue operationalInsertionValue
    generativeInsertionValue researchOptionPremium
  ring

/-- Equal raw frontiers give equal passive values at every calendar horizon. -/
theorem passiveValue_eq_of_frontier_eq
    (process : Model model catalog closure)
    {left right : Raw.Library catalog}
    (hfrontier :
      operationalFrontier catalog left =
        operationalFrontier catalog right) :
    ∀ horizon belief,
      passiveValue process horizon belief left =
        passiveValue process horizon belief right := by
  intro horizon
  induction horizon with
  | zero =>
      intro belief
      rfl
  | succ horizon inductionHypothesis =>
      intro belief
      simp only [passiveValue]
      rw [congrFun hfrontier belief]
      apply congrArg
        (fun continuation =>
          operationalFrontier catalog right belief +
            process.discount * continuation)
      apply RatProb.expectation_congr
      intro nextBelief
      exact inductionHypothesis nextBelief

/-- A frontier-silent insertion has zero operational insertion value. -/
theorem operationalInsertionValue_eq_zero_of_frontier_eq
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (hfrontier :
      operationalFrontier catalog (library.insert strategy) =
        operationalFrontier catalog library) :
    operationalInsertionValue process horizon belief library strategy = 0 := by
  unfold operationalInsertionValue
  rw [passiveValue_eq_of_frontier_eq process hfrontier horizon belief]
  ring

/--
An insertion silent in both frontier and closure has zero total value.  The
proof uses T1's raw-to-compressed value projection and the exact compressed
state identity.
-/
theorem totalInsertionValue_eq_zero_of_frontier_closure_eq
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (hfrontier :
      operationalFrontier catalog (library.insert strategy) =
        operationalFrontier catalog library)
    (hclosure :
      generativeClosure catalog closure (library.insert strategy) =
        generativeClosure catalog closure library) :
    totalInsertionValue process horizon belief library strategy = 0 := by
  have hstate :
      compressedLibraryState catalog closure (library.insert strategy) =
        compressedLibraryState catalog closure library :=
    compressedLibraryState_eq_of_frontierClosure_eq hfrontier hclosure
  have hofLibrary :
      CompressedLibraryState.ofLibrary catalog closure
          (library.insert strategy) =
        CompressedLibraryState.ofLibrary catalog closure library := by
    apply CompressedLibraryState.ext
    exact hstate
  unfold totalInsertionValue fullValue
  rw [process.rawValue_eq_compressedValue,
    process.rawValue_eq_compressedValue, hofLibrary]
  ring

/-- Pointwise expectation preserves rational inequalities. -/
theorem expectation_mono
    {α : Type*} (distribution : RatProb α)
    {left right : α → ℚ}
    (hvalue : ∀ outcome, left outcome ≤ right outcome) :
    distribution.expectation left ≤ distribution.expectation right := by
  unfold RatProb.expectation
  apply Finsupp.sum_le_sum
  intro outcome _
  exact mul_le_mul_of_nonneg_left
    (hvalue outcome) (distribution.nonnegative outcome)

/-- Exact expectation distributes over subtraction. -/
theorem expectation_sub
    {α : Type*} (distribution : RatProb α)
    (left right : α → ℚ) :
    distribution.expectation (fun outcome => left outcome - right outcome) =
      distribution.expectation left - distribution.expectation right := by
  classical
  unfold RatProb.expectation Finsupp.sum
  simp_rw [mul_sub]
  rw [Finset.sum_sub_distrib]

/-- Current pointwise frontier gain from inserting a fixed strategy. -/
def frontierInsertionGap
    (library : Raw.Library catalog) (strategy : model.StrategyId)
    (belief : model.Belief) : ℚ :=
  operationalFrontier catalog (library.insert strategy) belief -
    operationalFrontier catalog library belief

/-- Raising a scalar baseline weakly lowers the positive gain from a fixed value. -/
theorem max_sub_self_antitone {left right candidate : ℚ}
    (hleftRight : left ≤ right) :
    max right candidate - right ≤ max left candidate - left := by
  rcases le_total candidate left with hcandidateLeft | hleftCandidate
  · rw [max_eq_left hcandidateLeft,
      max_eq_left (hcandidateLeft.trans hleftRight)]
    linarith
  · by_cases hcandidateRight : candidate ≤ right
    · rw [max_eq_left hcandidateRight, max_eq_right hleftCandidate]
      linarith
    · have hrightCandidate : right ≤ candidate :=
        le_of_not_ge hcandidateRight
      rw [max_eq_right hrightCandidate,
        max_eq_right (hleftRight.trans hrightCandidate)]
      linarith

/--
Library inclusion weakly lowers the current frontier gain of inserting a
fixed candidate.
-/
theorem frontierInsertionGap_antitone_of_library_inclusion
    {left right : Raw.Library catalog}
    (hinclude : left ≤ right) (strategy : model.StrategyId)
    (belief : model.Belief) :
    frontierInsertionGap (catalog := catalog) right strategy belief ≤
      frontierInsertionGap (catalog := catalog) left strategy belief := by
  unfold frontierInsertionGap
  rw [Raw.operationalFrontier_insert, Raw.operationalFrontier_insert]
  exact max_sub_self_antitone
    (operationalFrontier_mono catalog hinclude belief)

/-- Operational insertion value obeys the frozen-library gap recursion. -/
theorem operationalInsertionValue_succ
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (library : Raw.Library catalog) (strategy : model.StrategyId) :
    operationalInsertionValue process (horizon + 1) belief library strategy =
      frontierInsertionGap (catalog := catalog) library strategy belief +
        process.discount *
          (process.beliefTransition belief).expectation
            (fun nextBelief =>
              operationalInsertionValue process horizon nextBelief
                library strategy) := by
  unfold operationalInsertionValue frontierInsertionGap
  simp only [passiveValue]
  rw [expectation_sub]
  ring

/--
Library inclusion weakly lowers a fixed candidate's operational insertion
value at every belief and finite calendar horizon.
-/
theorem operationalInsertionValue_antitone_of_library_inclusion
    (process : Model model catalog closure)
    {left right : Raw.Library catalog}
    (hinclude : left ≤ right) (strategy : model.StrategyId) :
    ∀ horizon belief,
      operationalInsertionValue process horizon belief right strategy ≤
        operationalInsertionValue process horizon belief left strategy := by
  intro horizon
  induction horizon with
  | zero =>
      intro belief
      simp [operationalInsertionValue, passiveValue]
  | succ horizon inductionHypothesis =>
      intro belief
      rw [operationalInsertionValue_succ,
        operationalInsertionValue_succ]
      apply add_le_add
      · exact frontierInsertionGap_antitone_of_library_inclusion
          hinclude strategy belief
      · apply mul_le_mul_of_nonneg_left
        · exact expectation_mono _ inductionHypothesis
        · exact process.discount_nonnegative

/--
Explicit project dominance for a closure-enriched raw library.

The fields separate the structural enrichment from the behavioral assumption:
the frontier is unchanged, closure and the feasible project menu expand, and
each formerly available project's exact unified action value is weakly larger
for every remaining horizon.  `compressedProjectActionValue` includes cost,
duration, the correlated joint terminal law, operation during research, and
the T1 compressed continuation value.
-/
structure ClosureEnrichmentProjectDominance
    (process : Model model catalog closure)
    (left right : Raw.Library catalog) : Prop where
  frontier_eq :
    operationalFrontier catalog left =
      operationalFrontier catalog right
  closure_subset :
    generativeClosure catalog closure left ⊆
      generativeClosure catalog closure right
  available_subset :
    process.available
        (CompressedLibraryState.ofLibrary catalog closure left) ⊆
      process.available
        (CompressedLibraryState.ofLibrary catalog closure right)
  projectValue_le :
    ∀ remainingHorizon belief project,
      project ∈ process.available
        (CompressedLibraryState.ofLibrary catalog closure left) →
      process.compressedProjectActionValue remainingHorizon belief
          (CompressedLibraryState.ofLibrary catalog closure left) project ≤
        process.compressedProjectActionValue remainingHorizon belief
          (CompressedLibraryState.ofLibrary catalog closure right) project

/--
Under the explicit dominance certificate, full compressed value is monotone
from the closure-poor library to the closure-enriched library.
-/
theorem compressedValue_mono_of_closureEnrichmentProjectDominance
    (process : Model model catalog closure)
    {left right : Raw.Library catalog}
    (hdominance :
      ClosureEnrichmentProjectDominance process left right) :
    ∀ horizon belief,
      process.compressedValue horizon belief
          (CompressedLibraryState.ofLibrary catalog closure left) ≤
        process.compressedValue horizon belief
          (CompressedLibraryState.ofLibrary catalog closure right) := by
  intro horizon
  induction horizon using Nat.strong_induction_on with
  | h horizon inductionHypothesis =>
      intro belief
      cases horizon with
      | zero =>
          simp [compressedValue]
      | succ horizon =>
          let leftState :=
            CompressedLibraryState.ofLibrary catalog closure left
          let rightState :=
            CompressedLibraryState.ofLibrary catalog closure right
          let toRight :
              FeasibleAction process (horizon + 1) leftState →
                FeasibleAction process (horizon + 1) rightState :=
            fun action =>
              ⟨action.1, by
                cases haction : action.1 with
                | none => trivial
                | some project =>
                    have hfeasible := action.2
                    rw [haction] at hfeasible
                    exact
                      ⟨hdominance.available_subset hfeasible.1,
                        hfeasible.2⟩⟩
          let leftActionValue :
              FeasibleAction process (horizon + 1) leftState → ℚ :=
            fun action =>
              match action.1 with
              | none =>
                  leftState.state.frontier belief +
                    process.discount *
                      (process.beliefTransition belief).expectation
                        (fun nextBelief =>
                          process.compressedValue horizon nextBelief leftState)
              | some project =>
                  -process.researchCost belief leftState project +
                    (process.completion project belief leftState).expectation
                      (fun completion =>
                        process.incumbentReward leftState project completion.1 +
                          process.discount ^ process.duration project *
                            process.compressedValue
                              ((horizon + 1) - process.duration project)
                              (terminalBelief completion.1)
                              (CompressedLibraryState.add catalog closure
                                leftState completion.2))
          let rightActionValue :
              FeasibleAction process (horizon + 1) rightState → ℚ :=
            fun action =>
              match action.1 with
              | none =>
                  rightState.state.frontier belief +
                    process.discount *
                      (process.beliefTransition belief).expectation
                        (fun nextBelief =>
                          process.compressedValue horizon nextBelief rightState)
              | some project =>
                  -process.researchCost belief rightState project +
                    (process.completion project belief rightState).expectation
                      (fun completion =>
                        process.incumbentReward rightState project completion.1 +
                          process.discount ^ process.duration project *
                            process.compressedValue
                              ((horizon + 1) - process.duration project)
                              (terminalBelief completion.1)
                              (CompressedLibraryState.add catalog closure
                                rightState completion.2))
          simp only [compressedValue]
          apply Finset.sup'_le Finset.univ_nonempty
          intro action _
          apply le_trans
            (show leftActionValue action ≤
              rightActionValue (toRight action) by
              rcases action with ⟨action, hfeasible⟩
              cases action with
              | none =>
                  dsimp [leftActionValue, rightActionValue, toRight,
                    leftState, rightState]
                  change
                    operationalFrontier catalog left belief +
                          process.discount *
                            (process.beliefTransition belief).expectation
                              (fun nextBelief =>
                                process.compressedValue horizon nextBelief
                                  (CompressedLibraryState.ofLibrary
                                    catalog closure left)) ≤
                      operationalFrontier catalog right belief +
                          process.discount *
                            (process.beliefTransition belief).expectation
                              (fun nextBelief =>
                                process.compressedValue horizon nextBelief
                                  (CompressedLibraryState.ofLibrary
                                    catalog closure right))
                  rw [congrFun hdominance.frontier_eq belief]
                  apply add_le_add_right
                  apply mul_le_mul_of_nonneg_left
                  · apply expectation_mono
                    intro nextBelief
                    exact inductionHypothesis horizon
                      (Nat.lt_succ_self horizon) nextBelief
                  · exact process.discount_nonnegative
              | some project =>
                  dsimp [leftActionValue, rightActionValue, toRight,
                    leftState, rightState]
                  have havailable :
                      project ∈ process.available
                        (CompressedLibraryState.ofLibrary catalog closure left) := by
                    exact hfeasible.1
                  rw [← process.compressedProjectActionValue_eq_completion,
                    ← process.compressedProjectActionValue_eq_completion]
                  exact hdominance.projectValue_le _ belief project havailable)
          exact Finset.le_sup' rightActionValue
            (Finset.mem_univ (toRight action))

/-- Full raw value is monotone under explicit closure-enrichment dominance. -/
theorem fullValue_mono_of_closureEnrichmentProjectDominance
    (process : Model model catalog closure)
    {left right : Raw.Library catalog}
    (hdominance :
      ClosureEnrichmentProjectDominance process left right)
    (horizon : Nat) (belief : model.Belief) :
    fullValue process horizon belief left ≤
      fullValue process horizon belief right := by
  unfold fullValue
  rw [process.rawValue_eq_compressedValue,
    process.rawValue_eq_compressedValue]
  exact compressedValue_mono_of_closureEnrichmentProjectDominance
    process hdominance horizon belief

/--
Closure enrichment cannot lower the research-option premium under the
explicit project-dominance assumptions and an unchanged frontier.
-/
theorem researchOptionPremium_mono_of_closureEnrichmentProjectDominance
    (process : Model model catalog closure)
    {left right : Raw.Library catalog}
    (hdominance :
      ClosureEnrichmentProjectDominance process left right)
    (horizon : Nat) (belief : model.Belief) :
    researchOptionPremium process horizon belief left ≤
      researchOptionPremium process horizon belief right := by
  have hfull :=
    fullValue_mono_of_closureEnrichmentProjectDominance
      process hdominance horizon belief
  have hpassive :=
    passiveValue_eq_of_frontier_eq process
      hdominance.frontier_eq horizon belief
  unfold researchOptionPremium
  rw [hpassive]
  linarith

namespace BridgeExample

open FrontierPruningLoss

/-- Deterministic raw generation: the bridge key produces the future strategy. -/
noncomputable def generation :
    Raw.CandidateGenerationDistributions FrontierPruningLoss.model where
  distribution := fun _project _belief available =>
    if Module.key ∈ available then
      RatProb.dirac (some Strategy.future)
    else
      RatProb.dirac none

/-- Every generated catalog strategy is admitted with probability one. -/
def admission :
    Raw.AdmissionProbabilities FrontierPruningLoss.model where
  probability := fun _project _belief _available _strategy => 1
  nonnegative := by intros; norm_num
  le_one := by intros; norm_num

/-- With the bridge key, the derived admitted law is the future point mass. -/
theorem admittedLaw_eq_dirac_future
    (available : Raw.ModuleSet FrontierPruningLoss.model)
    (hkey : Module.key ∈ available) :
    Raw.admittedCandidateDistribution generation admission
        Project.innovate Belief.only available =
      RatProb.dirac (some Strategy.future) := by
  apply RatProb.ext
  apply Finsupp.ext
  intro outcome
  change
    (Raw.admittedCandidateDistribution generation admission
        Project.innovate Belief.only available).probability outcome =
      (RatProb.dirac (some Strategy.future)).probability outcome
  rw [Raw.admittedCandidateDistribution_probability]
  cases outcome with
  | none =>
      simp [Raw.admittedCandidateMass, generation, admission, hkey,
        Raw.CandidateGenerationDistributions.probability,
        RatProb.probability, RatProb.dirac]
  | some strategy =>
      cases strategy <;>
        simp [Raw.admittedCandidateMass, generation, admission, hkey,
          Raw.CandidateGenerationDistributions.probability,
          RatProb.probability, RatProb.dirac]

/-- Without the bridge key, the derived admitted law is the failure point mass. -/
theorem admittedLaw_eq_dirac_none
    (available : Raw.ModuleSet FrontierPruningLoss.model)
    (hkey : Module.key ∉ available) :
    Raw.admittedCandidateDistribution generation admission
        Project.innovate Belief.only available =
      RatProb.dirac none := by
  apply RatProb.ext
  apply Finsupp.ext
  intro outcome
  change
    (Raw.admittedCandidateDistribution generation admission
        Project.innovate Belief.only available).probability outcome =
      (RatProb.dirac none).probability outcome
  rw [Raw.admittedCandidateDistribution_probability]
  cases outcome with
  | none =>
      simp [Raw.admittedCandidateMass, generation, admission, hkey,
        Raw.CandidateGenerationDistributions.probability,
        RatProb.probability, RatProb.dirac]
  | some strategy =>
      cases strategy <;>
        simp [Raw.admittedCandidateMass, generation, admission, hkey,
          Raw.CandidateGenerationDistributions.probability,
          RatProb.probability, RatProb.dirac]

/-- The unique one-period belief path in the one-belief bridge model. -/
def onlyPath :
    BeliefPath FrontierPruningLoss.model 1 :=
  fun _ => Belief.only

/-- Every one-period path in the bridge model is the displayed constant path. -/
theorem path_eq_onlyPath
    (path : BeliefPath FrontierPruningLoss.model 1) :
    path = onlyPath := by
  funext time
  cases path time
  rfl

/-- Exact deterministic belief transition in the bridge example. -/
noncomputable def beliefTransition :
    FrontierPruningLoss.model.Belief →
      RatProb FrontierPruningLoss.model.Belief :=
  fun _ => RatProb.dirac Belief.only

/-- Mapping a point mass gives the point mass of its image. -/
theorem map_dirac {α β : Type*} (outcome : α) (map : α → β) :
    Projection.RatProb.map (RatProb.dirac outcome) map =
      RatProb.dirac (map outcome) := by
  apply RatProb.ext
  simp [Projection.RatProb.map, RatProb.dirac]

/--
The exact completion coupling attaches the unique belief path to the admitted
outcome.  It is a product coupling in this example, although T5 does not
assume conditional independence.
-/
noncomputable def completion
    (_project : FrontierPruningLoss.model.ResearchProject)
    (_belief : FrontierPruningLoss.model.Belief)
    (state : CompressedLibraryState
      (FrontierPruningLoss.catalog 2) moduleClosure) :
    RatProb
      (BeliefPath FrontierPruningLoss.model 1 ×
        Raw.CandidateOutcome FrontierPruningLoss.model) :=
  Projection.RatProb.map
    (Raw.admittedCandidateDistribution generation admission
      Project.innovate Belief.only state.state.closure)
    (fun outcome => (onlyPath, outcome))

/-- The bridge completion coupling has the required Markov path marginal. -/
theorem completion_path_marginal
    (project : FrontierPruningLoss.model.ResearchProject)
    (belief : FrontierPruningLoss.model.Belief)
    (state : CompressedLibraryState
      (FrontierPruningLoss.catalog 2) moduleClosure)
    (path : BeliefPath FrontierPruningLoss.model 1) :
    ∑ outcome : Raw.CandidateOutcome FrontierPruningLoss.model,
        (completion project belief state).probability (path, outcome) =
      markovPathMass beliefTransition belief 1 path := by
  cases project
  cases belief
  rw [path_eq_onlyPath path]
  have hinjective :
      Function.Injective
        (fun outcome : Raw.CandidateOutcome FrontierPruningLoss.model =>
          (onlyPath, outcome)) := by
    intro left right hequal
    exact congrArg Prod.snd hequal
  change
    ∑ outcome : Raw.CandidateOutcome FrontierPruningLoss.model,
        (Projection.RatProb.map
          (Raw.admittedCandidateDistribution generation admission
            Project.innovate Belief.only state.state.closure)
          (fun candidate => (onlyPath, candidate))).probability
          (onlyPath, outcome) =
      markovPathMass beliefTransition Belief.only 1 onlyPath
  simp only [Projection.RatProb.map, RatProb.probability,
    Finsupp.mapDomain_apply hinjective]
  rw [show markovPathMass beliefTransition Belief.only 1 onlyPath = 1 by
    simp [markovPathMass, beliefTransition, onlyPath,
      RatProb.probability, RatProb.dirac]]
  simpa [Finsupp.sum_fintype] using
    (Raw.admittedCandidateDistribution generation admission
      Project.innovate Belief.only state.state.closure).totalMass

/-- The bridge completion coupling has the derived admitted-outcome marginal. -/
theorem completion_outcome_marginal
    (project : FrontierPruningLoss.model.ResearchProject)
    (belief : FrontierPruningLoss.model.Belief)
    (state : CompressedLibraryState
      (FrontierPruningLoss.catalog 2) moduleClosure)
    (outcome : Raw.CandidateOutcome FrontierPruningLoss.model) :
    ∑ path : BeliefPath FrontierPruningLoss.model 1,
        (completion project belief state).probability (path, outcome) =
      (Raw.admittedCandidateDistribution generation admission project belief
        state.state.closure).probability outcome := by
  cases project
  cases belief
  classical
  have huniv :
      (Finset.univ :
        Finset (BeliefPath FrontierPruningLoss.model 1)) =
          {onlyPath} := by
    ext path
    simp [path_eq_onlyPath path]
  rw [huniv]
  simp only [Finset.sum_singleton]
  have hinjective :
      Function.Injective
        (fun candidate : Raw.CandidateOutcome FrontierPruningLoss.model =>
          (onlyPath, candidate)) := by
    intro left right hequal
    exact congrArg Prod.snd hequal
  change
    (Projection.RatProb.map
      (Raw.admittedCandidateDistribution generation admission
        Project.innovate Belief.only state.state.closure)
      (fun candidate => (onlyPath, candidate))).probability
        (onlyPath, outcome) =
      (Raw.admittedCandidateDistribution generation admission
        Project.innovate Belief.only state.state.closure).probability outcome
  exact Finsupp.mapDomain_apply hinjective _ outcome

/-- With the bridge closure, completion admits the future strategy surely. -/
theorem completion_eq_dirac_future
    (state : CompressedLibraryState
      (FrontierPruningLoss.catalog 2) moduleClosure)
    (hkey : Module.key ∈ state.state.closure) :
    completion Project.innovate Belief.only state =
      RatProb.dirac (onlyPath, some Strategy.future) := by
  unfold completion
  rw [admittedLaw_eq_dirac_future state.state.closure hkey]
  exact map_dirac _ _

/-- Without the bridge closure, completion surely returns failure. -/
theorem completion_eq_dirac_none
    (state : CompressedLibraryState
      (FrontierPruningLoss.catalog 2) moduleClosure)
    (hkey : Module.key ∉ state.state.closure) :
    completion Project.innovate Belief.only state =
      RatProb.dirac (onlyPath, none) := by
  unfold completion
  rw [admittedLaw_eq_dirac_none state.state.closure hkey]
  exact map_dirac _ _

/-- Unified raw/compressed process for the exact positive generative-value witness. -/
noncomputable def process :
    Model FrontierPruningLoss.model
      (FrontierPruningLoss.catalog 2) moduleClosure where
  generation := generation
  admission := admission
  beliefTransition := beliefTransition
  duration := fun _ => 1
  duration_positive := by intros; norm_num
  operates := fun _ => false
  available := fun _ => Finset.univ
  researchCost := fun _ _ _ => 0
  researchCost_nonnegative := by intros; norm_num
  discount := 1 / 2
  discount_nonnegative := by norm_num
  discount_lt_one := by norm_num
  completion := completion
  completion_path_marginal := completion_path_marginal
  completion_outcome_marginal := completion_outcome_marginal

/-- Continue is feasible at every finite horizon. -/
def continueAction (horizon : Nat)
    (state : CompressedLibraryState
      (FrontierPruningLoss.catalog 2) moduleClosure) :
    FeasibleAction process horizon state :=
  ⟨none, trivial⟩

/-- The unique project is feasible whenever at least one date remains. -/
def researchAction (horizon : Nat)
    (state : CompressedLibraryState
      (FrontierPruningLoss.catalog 2) moduleClosure)
    (hpositive : 1 ≤ horizon) :
    FeasibleAction process horizon state :=
  ⟨some Project.innovate, by
    constructor
    · simp [process]
    · simpa [process] using hpositive⟩

/-- The bridge model's feasible-action supremum is a two-way maximum. -/
theorem feasibleActionMaximum_eq_max
    (horizon : Nat)
    (state : CompressedLibraryState
      (FrontierPruningLoss.catalog 2) moduleClosure)
    (hpositive : 1 ≤ horizon)
    (value : FeasibleAction process horizon state → ℚ) :
    Finset.univ.sup' Finset.univ_nonempty value =
      max (value (continueAction horizon state))
        (value (researchAction horizon state hpositive)) := by
  apply le_antisymm
  · apply Finset.sup'_le Finset.univ_nonempty
    intro action _
    rcases action with ⟨action, hfeasible⟩
    cases action with
    | none =>
        exact le_max_left
          (value (continueAction horizon state))
          (value (researchAction horizon state hpositive))
    | some project =>
        cases project
        exact le_max_right
          (value (continueAction horizon state))
          (value (researchAction horizon state hpositive))
  · apply max_le
    · exact Finset.le_sup' value
        (Finset.mem_univ (continueAction horizon state))
    · exact Finset.le_sup' value
        (Finset.mem_univ (researchAction horizon state hpositive))

/-- The unified raw Bellman step reduces to Continue versus the one project. -/
theorem rawValue_succ_eq_max
    (horizon : Nat)
    (library : Raw.Library (FrontierPruningLoss.catalog 2)) :
    process.rawValue (horizon + 1) Belief.only library =
      max
        (operationalFrontier (FrontierPruningLoss.catalog 2)
            library Belief.only +
          (1 / 2 : ℚ) *
            (beliefTransition Belief.only).expectation
              (fun nextBelief =>
                process.rawValue horizon nextBelief library))
        ((process.completion Project.innovate Belief.only
            (CompressedLibraryState.ofLibrary
              (FrontierPruningLoss.catalog 2) moduleClosure library)).expectation
          (fun completed =>
            (1 / 2 : ℚ) *
              process.rawValue horizon
                (terminalBelief completed.1)
                (Raw.rawLibraryUpdate library completed.2))) := by
  rw [rawValue]
  rw [feasibleActionMaximum_eq_max (horizon + 1)
    (CompressedLibraryState.ofLibrary
      (FrontierPruningLoss.catalog 2) moduleClosure library)
    (Nat.succ_le_succ (Nat.zero_le horizon))]
  simp [continueAction, researchAction, process, incumbentReward]

/-- At one remaining date, unified full value is exactly the current frontier. -/
theorem rawValue_one_eq_frontier
    (library : Raw.Library (FrontierPruningLoss.catalog 2)) :
    process.rawValue 1 Belief.only library =
      operationalFrontier (FrontierPruningLoss.catalog 2)
        library Belief.only := by
  simp only [rawValue]
  rw [feasibleActionMaximum_eq_max 1
    (CompressedLibraryState.ofLibrary
      (FrontierPruningLoss.catalog 2) moduleClosure library) (by norm_num)]
  simp [continueAction, researchAction, process, incumbentReward,
    beliefTransition, rawValue, RatProb.expectation]
  exact zero_le_operationalFrontier
    (FrontierPruningLoss.catalog 2) library Belief.only

/-- Inserting the bridge into the inactive library gives the retained library. -/
theorem insert_dominated_eq_unpruned :
    (prunedLibrary 2).insert Strategy.dominated =
      unprunedLibrary 2 := by
  apply Library.ext
  change
    Insert.insert Strategy.dominated
        ({Strategy.inactive} : Finset Strategy) =
      {Strategy.inactive, Strategy.dominated}
  decide

/-- Successful admission inserts the payoff-two descendant into the retained library. -/
def successfulLibrary :
    Raw.Library (FrontierPruningLoss.catalog 2) :=
  Raw.rawLibraryUpdate (unprunedLibrary 2) (some Strategy.future)

/-- The successful raw successor has frontier two. -/
theorem successfulLibrary_frontier_eq_two :
    operationalFrontier (FrontierPruningLoss.catalog 2) successfulLibrary =
      fun _ => 2 := by
  unfold successfulLibrary
  rw [Raw.rawLibraryUpdate_some, Raw.operationalFrontier_insert,
    unpruned_frontier_eq_zero]
  funext belief
  cases belief
  norm_num [profile]

/-- Retaining the bridge gives deterministic successful completion. -/
theorem process_completion_unpruned :
    process.completion Project.innovate Belief.only
        (CompressedLibraryState.ofLibrary
          (FrontierPruningLoss.catalog 2) moduleClosure
          (unprunedLibrary 2)) =
      RatProb.dirac (onlyPath, some Strategy.future) := by
  change
    completion Project.innovate Belief.only
        (CompressedLibraryState.ofLibrary
          (FrontierPruningLoss.catalog 2) moduleClosure
          (unprunedLibrary 2)) =
      RatProb.dirac (onlyPath, some Strategy.future)
  apply completion_eq_dirac_future
  change Module.key ∈
    generativeClosure (FrontierPruningLoss.catalog 2)
      moduleClosure (unprunedLibrary 2)
  rw [unpruned_closure_eq_key]
  simp

/-- Without the bridge, project completion deterministically fails. -/
theorem process_completion_pruned :
    process.completion Project.innovate Belief.only
        (CompressedLibraryState.ofLibrary
          (FrontierPruningLoss.catalog 2) moduleClosure
          (prunedLibrary 2)) =
      RatProb.dirac (onlyPath, none) := by
  change
    completion Project.innovate Belief.only
        (CompressedLibraryState.ofLibrary
          (FrontierPruningLoss.catalog 2) moduleClosure
          (prunedLibrary 2)) =
      RatProb.dirac (onlyPath, none)
  apply completion_eq_dirac_none
  change Module.key ∉
    generativeClosure (FrontierPruningLoss.catalog 2)
      moduleClosure (prunedLibrary 2)
  rw [pruned_closure_eq_empty]
  simp

/-- Exact expectation reduction for retained-bridge completion. -/
theorem process_completion_expectation_unpruned
    (value :
      BeliefPath FrontierPruningLoss.model 1 ×
          Raw.CandidateOutcome FrontierPruningLoss.model → ℚ) :
    (process.completion Project.innovate Belief.only
        (CompressedLibraryState.ofLibrary
          (FrontierPruningLoss.catalog 2) moduleClosure
          (unprunedLibrary 2))).expectation value =
      value (onlyPath, some Strategy.future) := by
  rw [process_completion_unpruned]
  exact RatProb.expectation_dirac _ _

/-- Exact expectation reduction for bridge-free completion. -/
theorem process_completion_expectation_pruned
    (value :
      BeliefPath FrontierPruningLoss.model 1 ×
          Raw.CandidateOutcome FrontierPruningLoss.model → ℚ) :
    (process.completion Project.innovate Belief.only
        (CompressedLibraryState.ofLibrary
          (FrontierPruningLoss.catalog 2) moduleClosure
          (prunedLibrary 2))).expectation value =
      value (onlyPath, none) := by
  rw [process_completion_pruned]
  exact RatProb.expectation_dirac _ _

/-- Bridge insertion leaves the complete current frontier unchanged. -/
theorem insertion_frontier_eq :
    operationalFrontier (FrontierPruningLoss.catalog 2)
        ((prunedLibrary 2).insert Strategy.dominated) =
      operationalFrontier (FrontierPruningLoss.catalog 2)
        (prunedLibrary 2) := by
  rw [insert_dominated_eq_unpruned, unpruned_frontier_eq_zero,
    pruned_frontier_eq_zero]

/-- The inactive-only library has zero unified full value through horizon two. -/
theorem pruned_fullValue_two_eq_zero :
    fullValue process 2 Belief.only (prunedLibrary 2) = 0 := by
  unfold fullValue
  rw [show (2 : Nat) = 1 + 1 by norm_num, rawValue_succ_eq_max]
  rw [process_completion_expectation_pruned]
  simp only [beliefTransition, RatProb.expectation_dirac]
  rw [rawValue_one_eq_frontier, Raw.rawLibraryUpdate_none,
    rawValue_one_eq_frontier]
  simp [pruned_frontier_eq_zero]

/-- Retaining the bridge gives exact unified full value one at horizon two. -/
theorem unpruned_fullValue_two_eq_one :
    fullValue process 2 Belief.only (unprunedLibrary 2) = 1 := by
  unfold fullValue
  rw [show (2 : Nat) = 1 + 1 by norm_num, rawValue_succ_eq_max]
  rw [process_completion_expectation_unpruned]
  simp only [beliefTransition, RatProb.expectation_dirac]
  rw [rawValue_one_eq_frontier, rawValue_one_eq_frontier]
  rw [show
    Raw.rawLibraryUpdate (unprunedLibrary 2) (some Strategy.future) =
      successfulLibrary by rfl]
  rw [congrFun successfulLibrary_frontier_eq_two Belief.only]
  simp [unpruned_frontier_eq_zero]

/-- Both current bridge libraries have zero frozen-library passive value. -/
theorem passive_values_two_eq_zero :
    passiveValue process 2 Belief.only (prunedLibrary 2) = 0 ∧
      passiveValue process 2 Belief.only (unprunedLibrary 2) = 0 := by
  simp [passiveValue, process, beliefTransition, RatProb.expectation,
    pruned_frontier_eq_zero, unpruned_frontier_eq_zero]

/--
Exact unified bridge witness: the insertion is operationally silent but has
generative insertion value exactly one and therefore strictly positive.
-/
theorem bridge_operational_zero_generative_positive :
    operationalInsertionValue process 2 Belief.only
          (prunedLibrary 2) Strategy.dominated = 0 ∧
      generativeInsertionValue process 2 Belief.only
          (prunedLibrary 2) Strategy.dominated = 1 ∧
      0 < generativeInsertionValue process 2 Belief.only
          (prunedLibrary 2) Strategy.dominated := by
  have hoperational :
      operationalInsertionValue process 2 Belief.only
          (prunedLibrary 2) Strategy.dominated = 0 :=
    operationalInsertionValue_eq_zero_of_frontier_eq
      process 2 Belief.only (prunedLibrary 2) Strategy.dominated
        insertion_frontier_eq
  have hgenerative :
      generativeInsertionValue process 2 Belief.only
          (prunedLibrary 2) Strategy.dominated = 1 := by
    unfold generativeInsertionValue researchOptionPremium
    rw [insert_dominated_eq_unpruned, unpruned_fullValue_two_eq_one,
      pruned_fullValue_two_eq_zero, passive_values_two_eq_zero.1,
      passive_values_two_eq_zero.2]
    norm_num
  exact ⟨hoperational, hgenerative, by rw [hgenerative]; norm_num⟩

end BridgeExample

end UnifiedDecomposition

end Model

end Projection

end StrategyInnovation
