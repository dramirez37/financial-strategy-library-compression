import Mathlib.Data.Fintype.OfMap
import Mathlib.Data.Rat.BigOperators
import Mathlib.Tactic
import StrategyInnovation.Bellman.Contraction
import StrategyInnovation.Raw

/-!
# Raw-to-compressed controlled Markov projection

This module derives the compressed transition and value model from the raw
candidate-generation, admission, and set-valued library-update definitions.
It does not assume the primitive transition factorization used by the older
abstract quotient layer.

Timing follows the unified convention.  A Continue action consumes one
calendar period.  A research project has a strictly positive duration, holds
the incumbent raw library fixed until completion, and carries a declared
joint law of the whole belief path and admitted candidate.  The two marginals
of that joint law are stated explicitly.  Conditional independence is an
optional additional predicate and is not used by the projection theorems.
-/

namespace StrategyInnovation

namespace Projection

open scoped BigOperators

universe u v

namespace RatProb

/-- Push an exact finite-support rational law through a deterministic map. -/
noncomputable def map {α : Type u} {β : Type v}
    (distribution : StrategyInnovation.RatProb α) (f : α → β) :
    StrategyInnovation.RatProb β where
  mass := distribution.mass.mapDomain f
  nonnegative := by
    intro outcome
    exact Finsupp.mapDomain_nonneg (distribution.nonnegative) outcome
  totalMass := by
    calc
      (distribution.mass.mapDomain f).sum (fun _ probability => probability) =
          distribution.mass.sum (fun _ probability => probability) := by
        simpa using
          (Finsupp.sum_mapDomain_index_addMonoidHom
            (f := f) (s := distribution.mass)
            (fun _ => AddMonoidHom.id ℚ))
      _ = 1 := distribution.totalMass

/-- Pointwise-equal deterministic maps induce the same pushed law. -/
theorem map_congr {α : Type u} {β : Type v}
    (distribution : StrategyInnovation.RatProb α) {f g : α → β}
    (hfg : ∀ outcome, f outcome = g outcome) :
    map distribution f = map distribution g := by
  have hfunctions : f = g := funext hfg
  cases hfunctions
  rfl

/-- Mapping in two stages is mapping by the composite deterministic update. -/
theorem map_map {α : Type u} {β : Type v} {γ : Type*}
    (distribution : StrategyInnovation.RatProb α) (f : α → β) (g : β → γ) :
    map (map distribution f) g = map distribution (g ∘ f) := by
  apply StrategyInnovation.RatProb.ext
  exact Finsupp.mapDomain_comp.symm

end RatProb

variable {model : FiniteModel}

/-- The finite carrier of compressed states actually realized by raw libraries. -/
structure CompressedLibraryState
    (catalog : Raw.StrategyCatalog model) (closure : Raw.ClosureOperator model) where
  state : InnovationState model
  realizable : ∃ library : Raw.Library catalog,
    compressedLibraryState catalog closure library = state

namespace CompressedLibraryState

variable (catalog : Raw.StrategyCatalog model) (closure : Raw.ClosureOperator model)

@[ext]
theorem ext {left right : CompressedLibraryState catalog closure}
    (hstate : left.state = right.state) : left = right := by
  cases left
  cases right
  cases hstate
  rfl

/-- Compress a raw library into the finite realizable carrier. -/
def ofLibrary (library : Raw.Library catalog) :
    CompressedLibraryState catalog closure where
  state := compressedLibraryState catalog closure library
  realizable := ⟨library, rfl⟩

noncomputable instance : DecidableEq (CompressedLibraryState catalog closure) :=
  Classical.decEq _

noncomputable instance : Fintype (CompressedLibraryState catalog closure) :=
  Fintype.ofSurjective (ofLibrary catalog closure) (by
    intro state
    rcases state.realizable with ⟨library, hlibrary⟩
    refine ⟨library, ?_⟩
    apply ext
    exact hlibrary)

/-- Apply an admitted candidate to a realizable compressed state. -/
def add (compressed : CompressedLibraryState catalog closure)
    (outcome : Raw.CandidateOutcome model) :
    CompressedLibraryState catalog closure where
  state := Raw.addCompressedState catalog closure compressed.state outcome
  realizable := by
    rcases compressed.realizable with ⟨library, hlibrary⟩
    refine ⟨Raw.rawLibraryUpdate library outcome, ?_⟩
    rw [Raw.compressedLibraryState_rawLibraryUpdate, hlibrary]

/-- Compression commutes with the raw admitted-candidate update in the realizable carrier. -/
theorem ofLibrary_rawLibraryUpdate (library : Raw.Library catalog)
    (outcome : Raw.CandidateOutcome model) :
    ofLibrary catalog closure (Raw.rawLibraryUpdate library outcome) =
      add catalog closure (ofLibrary catalog closure library) outcome := by
  apply ext
  exact Raw.compressedLibraryState_rawLibraryUpdate catalog closure library outcome

end CompressedLibraryState

/-- A full belief path over a project's calendar duration. -/
abbrev BeliefPath (model : FiniteModel) (duration : Nat) :=
  Fin (duration + 1) → model.Belief

/-- The exact Markov mass of a full path, including its prescribed initial belief. -/
def markovPathMass (beliefTransition : model.Belief → RatProb model.Belief)
    (belief : model.Belief) (duration : Nat) (path : BeliefPath model duration) : ℚ :=
  if path 0 = belief then
    ∏ time : Fin duration,
      (beliefTransition (path time.castSucc)).probability (path time.succ)
  else 0

/-- Terminal belief of a full project path. -/
def terminalBelief {duration : Nat} (path : BeliefPath model duration) : model.Belief :=
  path (Fin.last duration)

/--
Raw primitives and unified-timing data for T1.

The joint `completion` law may correlate belief paths with admission outcomes.
Its admitted-outcome marginal is the law derived from `generation` and
`admission`; its path marginal is the exact Markov path law.  Every displayed
input depends on a raw library only through the realizable compressed state.
-/
structure Model (model : FiniteModel)
    (catalog : Raw.StrategyCatalog model) (closure : Raw.ClosureOperator model) where
  generation : Raw.CandidateGenerationDistributions model
  admission : Raw.AdmissionProbabilities model
  beliefTransition : model.Belief → RatProb model.Belief
  duration : model.ResearchProject → Nat
  duration_positive : ∀ project, 0 < duration project
  operates : model.ResearchProject → Bool
  available : CompressedLibraryState catalog closure → Finset model.ResearchProject
  researchCost : model.Belief → CompressedLibraryState catalog closure →
    model.ResearchProject → ℚ
  researchCost_nonnegative : ∀ belief state project,
    0 ≤ researchCost belief state project
  discount : ℚ
  discount_nonnegative : 0 ≤ discount
  discount_lt_one : discount < 1
  completion : ∀ (project : model.ResearchProject) (_belief : model.Belief)
    (_state : CompressedLibraryState catalog closure),
    RatProb (BeliefPath model (duration project) × Raw.CandidateOutcome model)
  completion_path_marginal : ∀ (project : model.ResearchProject)
    (belief : model.Belief) (state : CompressedLibraryState catalog closure)
    (path : BeliefPath model (duration project)),
    ∑ outcome : Raw.CandidateOutcome model,
      (completion project belief state).probability (path, outcome) =
        markovPathMass beliefTransition belief (duration project) path
  completion_outcome_marginal : ∀ (project : model.ResearchProject)
    (belief : model.Belief) (state : CompressedLibraryState catalog closure)
    (outcome : Raw.CandidateOutcome model),
    ∑ path : BeliefPath model (duration project),
      (completion project belief state).probability (path, outcome) =
        (Raw.admittedCandidateDistribution generation admission project belief
          state.state.closure).probability outcome

namespace Model

variable {catalog : Raw.StrategyCatalog model} {closure : Raw.ClosureOperator model}

/-- Optional product specialization; no main T1 declaration assumes it. -/
def ConditionalIndependence (process : Model model catalog closure) : Prop :=
  ∀ project belief state path outcome,
    (process.completion project belief state).probability (path, outcome) =
      markovPathMass process.beliefTransition belief (process.duration project) path *
        (Raw.admittedCandidateDistribution process.generation process.admission
          project belief state.state.closure).probability outcome

/-- The admitted law derived at a realizable compressed state. -/
noncomputable def admittedLaw (process : Model model catalog closure)
    (belief : model.Belief) (state : CompressedLibraryState catalog closure)
    (project : model.ResearchProject) : RatProb (Raw.CandidateOutcome model) :=
  Raw.admittedCandidateDistribution process.generation process.admission
    project belief state.state.closure

/-- The compressed transition is the deterministic update pushforward of the derived admitted law. -/
noncomputable def inducedCompressedTransition
    (process : Model model catalog closure) (belief : model.Belief)
    (state : CompressedLibraryState catalog closure)
    (project : model.ResearchProject) :
    RatProb (CompressedLibraryState catalog closure) :=
  Projection.RatProb.map (process.admittedLaw belief state project)
    (CompressedLibraryState.add catalog closure state)

/-- Point masses of the induced compressed transition are nonnegative. -/
theorem inducedCompressedTransition_nonnegative
    (process : Model model catalog closure) (belief : model.Belief)
    (state : CompressedLibraryState catalog closure)
    (project : model.ResearchProject) (nextState : CompressedLibraryState catalog closure) :
    0 ≤ (process.inducedCompressedTransition belief state project).probability nextState :=
  (process.inducedCompressedTransition belief state project).nonnegative nextState

/-- The induced compressed transition has total mass one. -/
theorem inducedCompressedTransition_totalMass
    (process : Model model catalog closure) (belief : model.Belief)
    (state : CompressedLibraryState catalog closure)
    (project : model.ResearchProject) :
    ∑ nextState : CompressedLibraryState catalog closure,
      (process.inducedCompressedTransition belief state project).probability nextState = 1 := by
  simpa [RatProb.probability, Finsupp.sum_fintype] using
    (process.inducedCompressedTransition belief state project).totalMass

/-- Well-definedness packages exact nonnegativity and normalization. -/
theorem inducedCompressedTransition_wellDefined
    (process : Model model catalog closure) (belief : model.Belief)
    (state : CompressedLibraryState catalog closure)
    (project : model.ResearchProject) :
    (∀ nextState, 0 ≤
      (process.inducedCompressedTransition belief state project).probability nextState) ∧
    (∑ nextState : CompressedLibraryState catalog closure,
      (process.inducedCompressedTransition belief state project).probability nextState = 1) :=
  ⟨process.inducedCompressedTransition_nonnegative belief state project,
    process.inducedCompressedTransition_totalMass belief state project⟩

/-- Compress the raw successor after drawing from the derived admitted law. -/
noncomputable def rawNextCompressedTransition
    (process : Model model catalog closure) (belief : model.Belief)
    (library : Raw.Library catalog) (project : model.ResearchProject) :
    RatProb (CompressedLibraryState catalog closure) :=
  Projection.RatProb.map
    (process.admittedLaw belief
      (CompressedLibraryState.ofLibrary catalog closure library) project)
    (fun outcome => CompressedLibraryState.ofLibrary catalog closure
      (Raw.rawLibraryUpdate library outcome))

/-- The raw successor pushforward is exactly the induced compressed transition. -/
theorem rawNextCompressedTransition_eq_induced
    (process : Model model catalog closure) (belief : model.Belief)
    (library : Raw.Library catalog) (project : model.ResearchProject) :
    process.rawNextCompressedTransition belief library project =
      process.inducedCompressedTransition belief
        (CompressedLibraryState.ofLibrary catalog closure library) project := by
  unfold rawNextCompressedTransition inducedCompressedTransition
  apply Projection.RatProb.map_congr
  intro outcome
  exact CompressedLibraryState.ofLibrary_rawLibraryUpdate
    catalog closure library outcome

/--
Raw libraries in one compression fiber assign the same probability to every
next measurable singleton compressed state.  On this finite carrier every
subset is measurable, and singleton equality determines the complete law.
-/
theorem same_compressedState_same_next_probability
    (process : Model model catalog closure) {left right : Raw.Library catalog}
    (hstate : compressedLibraryState catalog closure left =
      compressedLibraryState catalog closure right)
    (belief : model.Belief) (project : model.ResearchProject)
    (nextState : CompressedLibraryState catalog closure) :
    (process.rawNextCompressedTransition belief left project).probability nextState =
      (process.rawNextCompressedTransition belief right project).probability nextState := by
  have hcompressed :
      CompressedLibraryState.ofLibrary catalog closure left =
        CompressedLibraryState.ofLibrary catalog closure right := by
    apply CompressedLibraryState.ext
    exact hstate
  rw [process.rawNextCompressedTransition_eq_induced,
    process.rawNextCompressedTransition_eq_induced, hcompressed]

/-- One embedded transition outcome, including holding time and reward block. -/
structure EmbeddedOutcome (State : Type u) where
  holdingTime : Nat
  reward : ℚ
  nextState : State
deriving DecidableEq

/-- The finite embedded action set; `none` denotes Continue. -/
abbrev Action (model : FiniteModel) := Option model.ResearchProject

/-- Discounted incumbent reward along a project's complete belief path. -/
def incumbentReward (process : Model model catalog closure)
    (state : CompressedLibraryState catalog closure)
    (project : model.ResearchProject)
    (path : BeliefPath model (process.duration project)) : ℚ :=
  ∑ time : Fin (process.duration project),
    process.discount ^ time.val *
      if process.operates project then state.state.frontier (path time.castSucc) else 0

/-- The raw embedded semi-Markov law, derived from completion and raw update. -/
noncomputable def rawEmbeddedLaw (process : Model model catalog closure)
    (belief : model.Belief) (library : Raw.Library catalog) :
    Action model → RatProb (EmbeddedOutcome (model.Belief × Raw.Library catalog))
  | none => Projection.RatProb.map (process.beliefTransition belief)
      (fun nextBelief =>
        { holdingTime := 1
          reward := operationalFrontier catalog library belief
          nextState := (nextBelief, library) })
  | some project => Projection.RatProb.map
      (process.completion project belief
        (CompressedLibraryState.ofLibrary catalog closure library))
      (fun completion =>
        { holdingTime := process.duration project
          reward := -process.researchCost belief
              (CompressedLibraryState.ofLibrary catalog closure library) project +
            process.incumbentReward
              (CompressedLibraryState.ofLibrary catalog closure library)
              project completion.1
          nextState := (terminalBelief completion.1,
            Raw.rawLibraryUpdate library completion.2) })

/-- The compressed embedded semi-Markov law derived from the same completion coupling. -/
noncomputable def compressedEmbeddedLaw (process : Model model catalog closure)
    (belief : model.Belief) (state : CompressedLibraryState catalog closure) :
    Action model → RatProb
      (EmbeddedOutcome (model.Belief × CompressedLibraryState catalog closure))
  | none => Projection.RatProb.map (process.beliefTransition belief)
      (fun nextBelief =>
        { holdingTime := 1
          reward := state.state.frontier belief
          nextState := (nextBelief, state) })
  | some project => Projection.RatProb.map
      (process.completion project belief state)
      (fun completion =>
        { holdingTime := process.duration project
          reward := -process.researchCost belief state project +
            process.incumbentReward state project completion.1
          nextState := (terminalBelief completion.1,
            CompressedLibraryState.add catalog closure state completion.2) })

/-- Project an embedded raw outcome by compressing only its next library. -/
def compressEmbeddedOutcome
    (outcome : EmbeddedOutcome (model.Belief × Raw.Library catalog)) :
    EmbeddedOutcome (model.Belief × CompressedLibraryState catalog closure) where
  holdingTime := outcome.holdingTime
  reward := outcome.reward
  nextState := (outcome.nextState.1,
    CompressedLibraryState.ofLibrary catalog closure outcome.nextState.2)

/--
The decision-epoch process on belief and compressed library state is
controlled Markov (indeed controlled semi-Markov): the projected raw law of
holding time, reward block, and next state is the derived compressed law.
-/
theorem projectedProcess_controlledMarkov
    (process : Model model catalog closure) (belief : model.Belief)
    (library : Raw.Library catalog) (action : Action model) :
    Projection.RatProb.map (process.rawEmbeddedLaw belief library action)
        (compressEmbeddedOutcome (catalog := catalog) (closure := closure)) =
      process.compressedEmbeddedLaw belief
        (CompressedLibraryState.ofLibrary catalog closure library) action := by
  cases action with
  | none =>
      simp only [rawEmbeddedLaw, compressedEmbeddedLaw]
      rw [Projection.RatProb.map_map]
      apply Projection.RatProb.map_congr
      intro nextBelief
      rfl
  | some project =>
      simp only [rawEmbeddedLaw, compressedEmbeddedLaw]
      rw [Projection.RatProb.map_map]
      apply Projection.RatProb.map_congr
      intro completion
      simp only [Function.comp_apply, compressEmbeddedOutcome]
      congr 2
      exact CompressedLibraryState.ofLibrary_rawLibraryUpdate
        catalog closure library completion.2

/-- Actions feasible with the stated number of calendar reward dates remaining. -/
def FeasibleAction (process : Model model catalog closure) (horizon : Nat)
    (state : CompressedLibraryState catalog closure) :=
  { action : Action model //
    match action with
    | none => True
    | some project =>
        project ∈ process.available state ∧ process.duration project ≤ horizon }

namespace FeasibleAction

noncomputable instance (process : Model model catalog closure) (horizon : Nat)
    (state : CompressedLibraryState catalog closure) :
    Fintype (FeasibleAction process horizon state) :=
  Fintype.ofInjective Subtype.val Subtype.val_injective

instance (process : Model model catalog closure) (horizon : Nat)
    (state : CompressedLibraryState catalog closure) :
    Nonempty (FeasibleAction process horizon state) :=
  ⟨⟨none, trivial⟩⟩

end FeasibleAction

/--
Compressed optimal value with `horizon` calendar reward dates remaining.
Continue consumes one date.  Project `q` is selectable only when its positive
duration fits, earns the incumbent reward block, and continues at
`horizon - duration q`.
-/
noncomputable def compressedValue (process : Model model catalog closure) :
    (horizon : Nat) → model.Belief → CompressedLibraryState catalog closure → ℚ
  | 0, _, _ => 0
  | horizon + 1, belief, state =>
      Finset.univ.sup' Finset.univ_nonempty
        (fun action : FeasibleAction process (horizon + 1) state =>
          match action.1 with
          | none =>
              state.state.frontier belief + process.discount *
                (process.beliefTransition belief).expectation
                  (fun nextBelief => compressedValue process horizon nextBelief state)
          | some project =>
              -process.researchCost belief state project +
                (process.completion project belief state).expectation
                  (fun completion =>
                    process.incumbentReward state project completion.1 +
                      process.discount ^ process.duration project *
                        compressedValue process
                          ((horizon + 1) - process.duration project)
                          (terminalBelief completion.1)
                          (CompressedLibraryState.add catalog closure state completion.2)))
termination_by horizon => horizon
decreasing_by
  · omega
  · have hpositive := process.duration_positive project
    omega

/-- Raw-library optimal value under the same unified calendar timing. -/
noncomputable def rawValue (process : Model model catalog closure) :
    (horizon : Nat) → model.Belief → Raw.Library catalog → ℚ
  | 0, _, _ => 0
  | horizon + 1, belief, library =>
      Finset.univ.sup' Finset.univ_nonempty
        (fun action : FeasibleAction process (horizon + 1)
            (CompressedLibraryState.ofLibrary catalog closure library) =>
          match action.1 with
          | none =>
              operationalFrontier catalog library belief + process.discount *
                (process.beliefTransition belief).expectation
                  (fun nextBelief => rawValue process horizon nextBelief library)
          | some project =>
              -process.researchCost belief
                  (CompressedLibraryState.ofLibrary catalog closure library) project +
                (process.completion project belief
                    (CompressedLibraryState.ofLibrary catalog closure library)).expectation
                  (fun completion =>
                    process.incumbentReward
                        (CompressedLibraryState.ofLibrary catalog closure library)
                        project completion.1 +
                      process.discount ^ process.duration project *
                        rawValue process
                          ((horizon + 1) - process.duration project)
                          (terminalBelief completion.1)
                          (Raw.rawLibraryUpdate library completion.2)))
termination_by horizon => horizon
decreasing_by
  · omega
  · have hpositive := process.duration_positive project
    omega

/--
Finite-calendar-horizon T1 value factorization.  The proof is strong induction
on calendar horizon and substitutes the derived raw update identity inside
every completion continuation.
-/
theorem rawValue_eq_compressedValue (process : Model model catalog closure) :
    ∀ horizon belief library,
      process.rawValue horizon belief library =
        process.compressedValue horizon belief
          (CompressedLibraryState.ofLibrary catalog closure library) := by
  intro horizon
  induction horizon using Nat.strong_induction_on with
  | h horizon inductionHypothesis =>
      intro belief library
      cases horizon with
      | zero => simp [rawValue, compressedValue]
      | succ horizon =>
          simp only [rawValue, compressedValue]
          apply congrArg
            (fun values :
                FeasibleAction process (horizon + 1)
                  (CompressedLibraryState.ofLibrary catalog closure library) → ℚ =>
              Finset.univ.sup' Finset.univ_nonempty values)
          funext action
          cases haction : action.1 with
          | none =>
              apply congrArg
                (fun continuation =>
                  operationalFrontier catalog library belief +
                    process.discount * continuation)
              apply StrategyInnovation.RatProb.expectation_congr
              intro nextBelief
              exact inductionHypothesis horizon (Nat.lt_succ_self horizon)
                nextBelief library
          | some project =>
              apply congrArg
                (fun continuation =>
                  -process.researchCost belief
                      (CompressedLibraryState.ofLibrary catalog closure library) project +
                    continuation)
              apply StrategyInnovation.RatProb.expectation_congr
              intro completion
              apply congrArg
                (fun continuation =>
                  process.incumbentReward
                      (CompressedLibraryState.ofLibrary catalog closure library)
                      project completion.1 +
                    process.discount ^ process.duration project * continuation)
              rw [inductionHypothesis]
              · exact congrArg
                  (process.compressedValue
                    ((horizon + 1) - process.duration project)
                    (terminalBelief completion.1))
                  (CompressedLibraryState.ofLibrary_rawLibraryUpdate
                    catalog closure library completion.2)
              · have hpositive := process.duration_positive project
                omega

/-- Actions feasible in the stationary infinite-horizon problem. -/
def InfiniteAction (process : Model model catalog closure)
    (state : CompressedLibraryState catalog closure) :=
  { action : Action model //
    match action with
    | none => True
    | some project => project ∈ process.available state }

namespace InfiniteAction

noncomputable instance (process : Model model catalog closure)
    (state : CompressedLibraryState catalog closure) :
    Fintype (InfiniteAction process state) :=
  Fintype.ofInjective Subtype.val Subtype.val_injective

instance (process : Model model catalog closure)
    (state : CompressedLibraryState catalog closure) :
    Nonempty (InfiniteAction process state) :=
  ⟨⟨none, trivial⟩⟩

end InfiniteAction

/-- Real compressed value tables for the stationary discounted model. -/
@[nolint unusedArguments]
abbrev CompressedRealValue (_process : Model model catalog closure) :=
  (model.Belief × CompressedLibraryState catalog closure) → ℝ

/-- Real raw-library value tables for the stationary discounted model. -/
@[nolint unusedArguments]
abbrev RawRealValue (_process : Model model catalog closure) :=
  (model.Belief × Raw.Library catalog) → ℝ

/-- Lift a compressed value table to raw libraries through actual compression. -/
def liftValue (process : Model model catalog closure)
    (value : CompressedRealValue process) : RawRealValue process :=
  fun state => value
    (state.1, CompressedLibraryState.ofLibrary catalog closure state.2)

/-- Stationary compressed action value under unified semi-Markov timing. -/
def compressedInfiniteActionValue (process : Model model catalog closure)
    (value : CompressedRealValue process) (belief : model.Belief)
    (state : CompressedLibraryState catalog closure)
    (action : InfiniteAction process state) : ℝ :=
  match action.1 with
  | none =>
      (state.state.frontier belief : ℝ) + (process.discount : ℝ) *
        BellmanContraction.realExpectedValue (process.beliefTransition belief)
          (fun nextBelief => value (nextBelief, state))
  | some project =>
      -(process.researchCost belief state project : ℝ) +
        BellmanContraction.realExpectedValue
          (process.completion project belief state)
          (fun completion =>
            (process.incumbentReward state project completion.1 : ℝ) +
              (process.discount : ℝ) ^ process.duration project *
                value (terminalBelief completion.1,
                  CompressedLibraryState.add catalog closure state completion.2))

/-- Stationary raw action value, with the raw set update retained in continuation. -/
def rawInfiniteActionValue (process : Model model catalog closure)
    (value : RawRealValue process) (belief : model.Belief)
    (library : Raw.Library catalog)
    (action : InfiniteAction process
      (CompressedLibraryState.ofLibrary catalog closure library)) : ℝ :=
  match action.1 with
  | none =>
      (operationalFrontier catalog library belief : ℝ) +
        (process.discount : ℝ) *
          BellmanContraction.realExpectedValue (process.beliefTransition belief)
            (fun nextBelief => value (nextBelief, library))
  | some project =>
      -(process.researchCost belief
          (CompressedLibraryState.ofLibrary catalog closure library) project : ℝ) +
        BellmanContraction.realExpectedValue
          (process.completion project belief
            (CompressedLibraryState.ofLibrary catalog closure library))
          (fun completion =>
            (process.incumbentReward
                (CompressedLibraryState.ofLibrary catalog closure library)
                project completion.1 : ℝ) +
              (process.discount : ℝ) ^ process.duration project *
                value (terminalBelief completion.1,
                  Raw.rawLibraryUpdate library completion.2))

/-- Stationary compressed Bellman operator. -/
noncomputable def compressedBellmanOperator (process : Model model catalog closure)
    (value : CompressedRealValue process) : CompressedRealValue process :=
  fun state =>
    Finset.univ.sup' Finset.univ_nonempty
      (fun action : InfiniteAction process state.2 =>
        process.compressedInfiniteActionValue value state.1 state.2 action)

/-- Stationary raw-library Bellman operator. -/
noncomputable def rawBellmanOperator (process : Model model catalog closure)
    (value : RawRealValue process) : RawRealValue process :=
  fun state =>
    Finset.univ.sup' Finset.univ_nonempty
      (fun action : InfiniteAction process
          (CompressedLibraryState.ofLibrary catalog closure state.2) =>
        process.rawInfiniteActionValue value state.1 state.2 action)

/-- Every raw action value agrees with its compressed counterpart on lifted continuations. -/
theorem rawInfiniteActionValue_lift
    (process : Model model catalog closure) (value : CompressedRealValue process)
    (belief : model.Belief) (library : Raw.Library catalog)
    (action : InfiniteAction process
      (CompressedLibraryState.ofLibrary catalog closure library)) :
    process.rawInfiniteActionValue (process.liftValue value) belief library action =
      process.compressedInfiniteActionValue value belief
        (CompressedLibraryState.ofLibrary catalog closure library) action := by
  cases haction : action.1 with
  | none =>
      simp [rawInfiniteActionValue, compressedInfiniteActionValue,
        haction, liftValue]
      rfl
  | some project =>
      simp only [rawInfiniteActionValue, compressedInfiniteActionValue,
        haction, liftValue]
      apply congrArg
        (fun continuation =>
          -(process.researchCost belief
              (CompressedLibraryState.ofLibrary catalog closure library) project : ℝ) +
            continuation)
      apply congrArg
        (BellmanContraction.realExpectedValue
          (process.completion project belief
            (CompressedLibraryState.ofLibrary catalog closure library)))
      funext completion
      apply congrArg
        (fun continuation =>
          (process.incumbentReward
              (CompressedLibraryState.ofLibrary catalog closure library)
              project completion.1 : ℝ) +
            (process.discount : ℝ) ^ process.duration project * continuation)
      exact congrArg value (Prod.ext rfl
        (CompressedLibraryState.ofLibrary_rawLibraryUpdate
          catalog closure library completion.2))

/-- The stationary Bellman operators commute with compression. -/
theorem rawBellmanOperator_lift
    (process : Model model catalog closure) (value : CompressedRealValue process) :
    process.rawBellmanOperator (process.liftValue value) =
      process.liftValue (process.compressedBellmanOperator value) := by
  funext state
  apply congrArg
    (fun actionValues : InfiniteAction process
        (CompressedLibraryState.ofLibrary catalog closure state.2) → ℝ =>
      Finset.univ.sup' Finset.univ_nonempty actionValues)
  funext action
  exact process.rawInfiniteActionValue_lift value state.1 state.2 action

/-- The process discount as a nonnegative contraction modulus. -/
def discountNNReal (process : Model model catalog closure) : NNReal :=
  ⟨(process.discount : ℝ), by exact_mod_cast process.discount_nonnegative⟩

theorem discountNNReal_lt_one (process : Model model catalog closure) :
    process.discountNNReal < 1 := by
  change (process.discount : ℝ) < 1
  exact_mod_cast process.discount_lt_one

/--
The discounted infinite-horizon contraction model.  The two fields state the
analytic contraction obligations for the raw and derived compressed Bellman
operators; the algebraic intertwining theorem above is proved from the raw
generation/admission/update layer and is not a field of this structure.
-/
structure DiscountedContractionModel (process : Model model catalog closure) where
  compressed_contracting :
    ContractingWith process.discountNNReal process.compressedBellmanOperator
  raw_contracting :
    ContractingWith process.discountNNReal process.rawBellmanOperator

namespace DiscountedContractionModel

variable {process : Model model catalog closure}

/-- Unique compressed Bellman fixed point in the declared contraction model. -/
noncomputable def compressedFixedPoint
    (contraction : DiscountedContractionModel process) :
    CompressedRealValue process :=
  ContractingWith.fixedPoint process.compressedBellmanOperator
    contraction.compressed_contracting

/-- Unique raw-library Bellman fixed point in the declared contraction model. -/
noncomputable def rawFixedPoint
    (contraction : DiscountedContractionModel process) : RawRealValue process :=
  ContractingWith.fixedPoint process.rawBellmanOperator contraction.raw_contracting

theorem compressedFixedPoint_isFixedPoint
    (contraction : DiscountedContractionModel process) :
    Function.IsFixedPt process.compressedBellmanOperator contraction.compressedFixedPoint :=
  contraction.compressed_contracting.fixedPoint_isFixedPt

theorem rawFixedPoint_isFixedPoint
    (contraction : DiscountedContractionModel process) :
    Function.IsFixedPt process.rawBellmanOperator contraction.rawFixedPoint :=
  contraction.raw_contracting.fixedPoint_isFixedPt

/-- The raw fixed point is exactly the lift of the compressed fixed point. -/
theorem rawFixedPoint_eq_lift
    (contraction : DiscountedContractionModel process) :
    contraction.rawFixedPoint = process.liftValue contraction.compressedFixedPoint := by
  symm
  apply contraction.raw_contracting.fixedPoint_unique
  unfold Function.IsFixedPt
  rw [process.rawBellmanOperator_lift]
  exact congrArg process.liftValue contraction.compressedFixedPoint_isFixedPoint

/-- Infinite-horizon T1 value agreement at every raw library. -/
theorem raw_fixedPoint_value_eq_compressed
    (contraction : DiscountedContractionModel process)
    (belief : model.Belief) (library : Raw.Library catalog) :
    contraction.rawFixedPoint (belief, library) =
      contraction.compressedFixedPoint
        (belief, CompressedLibraryState.ofLibrary catalog closure library) := by
  rw [contraction.rawFixedPoint_eq_lift]
  rfl

/-- A stationary compressed selector that attains the fixed-point Bellman maximum. -/
noncomputable def optimalCompressedPolicy
    (contraction : DiscountedContractionModel process)
    (state : model.Belief × CompressedLibraryState catalog closure) :
    InfiniteAction process state.2 :=
  Classical.choose
    (Finset.exists_mem_eq_sup' Finset.univ_nonempty
      (fun action : InfiniteAction process state.2 =>
        process.compressedInfiniteActionValue contraction.compressedFixedPoint
          state.1 state.2 action))

/-- The selected compressed action attains the compressed Bellman value. -/
theorem optimalCompressedPolicy_attains
    (contraction : DiscountedContractionModel process)
    (state : model.Belief × CompressedLibraryState catalog closure) :
    process.compressedInfiniteActionValue contraction.compressedFixedPoint
        state.1 state.2 (contraction.optimalCompressedPolicy state) =
      process.compressedBellmanOperator contraction.compressedFixedPoint state := by
  unfold optimalCompressedPolicy compressedBellmanOperator
  exact (Classical.choose_spec
    (Finset.exists_mem_eq_sup' Finset.univ_nonempty
      (fun action : InfiniteAction process state.2 =>
        process.compressedInfiniteActionValue contraction.compressedFixedPoint
          state.1 state.2 action))).2.symm

/-- Lift the compressed selector to a feasible raw-library selector. -/
noncomputable def liftedRawPolicy
    (contraction : DiscountedContractionModel process)
    (belief : model.Belief) (library : Raw.Library catalog) :
    InfiniteAction process
      (CompressedLibraryState.ofLibrary catalog closure library) :=
  contraction.optimalCompressedPolicy
    (belief, CompressedLibraryState.ofLibrary catalog closure library)

/-- The lifted compressed selector is Bellman-optimal in every raw state. -/
theorem liftedRawPolicy_optimal
    (contraction : DiscountedContractionModel process)
    (belief : model.Belief) (library : Raw.Library catalog) :
    process.rawInfiniteActionValue contraction.rawFixedPoint belief library
        (contraction.liftedRawPolicy belief library) =
      process.rawBellmanOperator contraction.rawFixedPoint (belief, library) := by
  rw [contraction.rawFixedPoint_eq_lift]
  rw [process.rawInfiniteActionValue_lift]
  unfold liftedRawPolicy
  rw [process.rawBellmanOperator_lift]
  exact contraction.optimalCompressedPolicy_attains
    (belief, CompressedLibraryState.ofLibrary catalog closure library)

end DiscountedContractionModel

end Model

end Projection

end StrategyInnovation
