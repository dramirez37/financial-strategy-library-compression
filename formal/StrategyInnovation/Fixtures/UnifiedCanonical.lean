import StrategyInnovation.Bellman.Unified

/-!
# Exact unified canonical benchmark

This file is the kernel-checked counterpart of selected Julia calibration
`C0424`.  It keeps the raw catalog, all eight raw-library encodings, raw
generation and verification, the full positive-duration belief paths, the
non-product Scale completion coupling, deterministic raw insertion, and the
three compressed stages explicit.

The fixture uses exact rational arithmetic throughout.  It is a finite
instance certificate, not a new general theorem.
-/

namespace StrategyInnovation

namespace Projection

namespace Model

namespace UnifiedCanonicalFixture

open scoped BigOperators

inductive Belief
  | low
  | high
  deriving DecidableEq, Fintype

inductive Strategy
  | inactive
  | carrierA
  | carrierB
  | descendant
  deriving DecidableEq, Fintype

inductive Module
  | capability
  deriving DecidableEq, Fintype

inductive Project
  | discover
  | scale
  deriving DecidableEq, Fintype

inductive CompressedState
  | k0
  | k1
  | k2
  deriving DecidableEq, Fintype

inductive Outcome
  | failure
  | carrierA
  | carrierB
  | descendant
  deriving DecidableEq, Fintype

inductive Action
  | continue
  | discover
  | scale
  deriving DecidableEq, Fintype

/--
Every raw library contains the inactive strategy.  The three Boolean fields
record inclusion of the two silent carriers and the profitable descendant, so
the carrier has exactly eight elements.
-/
structure RawLibrary where
  carrierA : Bool
  carrierB : Bool
  descendant : Bool
  deriving DecidableEq, Fintype

/-- Full paths for either the one-period Discover or two-period Scale project. -/
inductive BeliefPath
  | one : Belief → Belief → BeliefPath
  | two : Belief → Belief → Belief → BeliefPath
  deriving DecidableEq, Fintype

/-!
The following four lemmas expose the complete finite carriers to the
arithmetic tactics.  They are proved by a kernel decision on `Finset.univ`;
no evaluator axiom or native-code shortcut is used.
-/

@[simp] theorem sum_belief {α : Type} [AddCommMonoid α] (f : Belief → α) :
    ∑ belief : Belief, f belief = f .low + f .high := by
  rw [show (Finset.univ : Finset Belief) = {.low, .high} by decide]
  simp

@[simp] theorem sum_compressedState {α : Type} [AddCommMonoid α]
    (f : CompressedState → α) :
    ∑ state : CompressedState, f state =
      f .k0 + f .k1 + f .k2 := by
  rw [show (Finset.univ : Finset CompressedState) = {.k0, .k1, .k2} by decide]
  simp [add_assoc]

@[simp] theorem sum_outcome {α : Type} [AddCommMonoid α] (f : Outcome → α) :
    ∑ outcome : Outcome, f outcome =
      f .failure + f .carrierA + f .carrierB + f .descendant := by
  rw [show
    (Finset.univ : Finset Outcome) =
      {.failure, .carrierA, .carrierB, .descendant} by decide]
  simp [add_assoc]

@[simp] theorem sum_beliefPath {α : Type} [AddCommMonoid α]
    (f : BeliefPath → α) :
    ∑ path : BeliefPath, f path =
      f (.one .low .low) +
      f (.one .low .high) +
      f (.one .high .low) +
      f (.one .high .high) +
      f (.two .low .low .low) +
      f (.two .low .low .high) +
      f (.two .low .high .low) +
      f (.two .low .high .high) +
      f (.two .high .low .low) +
      f (.two .high .low .high) +
      f (.two .high .high .low) +
      f (.two .high .high .high) := by
  rw [show
    (Finset.univ : Finset BeliefPath) =
      {
        .one .low .low,
        .one .low .high,
        .one .high .low,
        .one .high .high,
        .two .low .low .low,
        .two .low .low .high,
        .two .low .high .low,
        .two .low .high .high,
        .two .high .low .low,
        .two .high .low .high,
        .two .high .high .low,
        .two .high .high .high
      } by decide]
  simp [add_assoc]

def discount : ℚ := 1 / 2

def transition : Belief → Belief → ℚ
  | .low, .low => 3 / 4
  | .low, .high => 1 / 4
  | .high, .low => 1 / 4
  | .high, .high => 3 / 4

def strategyProfile : Strategy → Belief → ℚ
  | .inactive, _ => 0
  | .carrierA, _ => 0
  | .carrierB, _ => 0
  | .descendant, .low => 2
  | .descendant, .high => 4

def strategyModules : Strategy → Finset Module
  | .inactive => ∅
  | .carrierA => {Module.capability}
  | .carrierB => {Module.capability}
  | .descendant => {Module.capability}

def rawContains (library : RawLibrary) : Strategy → Bool
  | .inactive => true
  | .carrierA => library.carrierA
  | .carrierB => library.carrierB
  | .descendant => library.descendant

def compress (library : RawLibrary) : CompressedState :=
  if library.descendant = true then .k2
  else if library.carrierA = true ∨ library.carrierB = true then .k1
  else .k0

def rawK0 : RawLibrary := ⟨false, false, false⟩
def rawK1 : RawLibrary := ⟨true, false, false⟩
def rawK2 : RawLibrary := ⟨false, false, true⟩

def rawUpdate : RawLibrary → Outcome → RawLibrary
  | library, .failure => library
  | library, .carrierA => { library with carrierA := true }
  | library, .carrierB => { library with carrierB := true }
  | library, .descendant => { library with descendant := true }

def compressedUpdate : CompressedState → Outcome → CompressedState
  | state, .failure => state
  | .k0, .carrierA => .k1
  | .k0, .carrierB => .k1
  | .k0, .descendant => .k2
  | .k1, .carrierA => .k1
  | .k1, .carrierB => .k1
  | .k1, .descendant => .k2
  | .k2, _ => .k2

def frontier : CompressedState → Belief → ℚ
  | .k0, _ => 0
  | .k1, _ => 0
  | .k2, .low => 2
  | .k2, .high => 4

def duration : Project → Nat
  | .discover => 1
  | .scale => 2

def operates : Project → Bool
  | .discover => true
  | .scale => true

def researchCost : Belief → Project → ℚ
  | .low, .discover => 1 / 32
  | .high, .discover => 1
  | _, .scale => 3 / 16

def projectAvailable : CompressedState → Project → Bool
  | .k0, .discover => true
  | .k0, .scale => false
  | .k1, .discover => false
  | .k1, .scale => true
  | .k2, .discover => false
  | .k2, .scale => true

def availableActions : CompressedState → Finset Action
  | .k0 => {Action.continue, Action.discover}
  | .k1 => {Action.continue, Action.scale}
  | .k2 => {Action.continue, Action.scale}

/-- Raw generation before verification. -/
def generationMass : Project → CompressedState → Outcome → ℚ
  | .discover, .k0, .carrierA => 1 / 2
  | .discover, .k0, .carrierB => 1 / 2
  | .discover, .k0, _ => 0
  | .discover, _, .failure => 1
  | .discover, _, _ => 0
  | .scale, .k0, .failure => 1
  | .scale, .k0, _ => 0
  | .scale, _, .descendant => 1
  | .scale, _, _ => 0

/-- Verification/admission probability conditional on a generated candidate. -/
def verificationProbability : Project → CompressedState → Outcome → ℚ
  | _, _, .failure => 1
  | _, _, .carrierA => 1
  | _, _, .carrierB => 1 / 2
  | _, _, .descendant => 3 / 4

/-- Admission is derived from generation and verification. -/
def admittedMass (project : Project) (state : CompressedState) : Outcome → ℚ
  | .failure =>
      generationMass project state .failure +
        ∑ candidate : Outcome,
          if candidate = .failure then 0
          else
            generationMass project state candidate *
              (1 - verificationProbability project state candidate)
  | candidate =>
      generationMass project state candidate *
        verificationProbability project state candidate

def terminalBelief : BeliefPath → Belief
  | .one _ terminal => terminal
  | .two _ _ terminal => terminal

def pathMass : Project → Belief → BeliefPath → ℚ
  | .discover, start, .one initial terminal =>
      if initial = start then transition initial terminal else 0
  | .discover, _, .two _ _ _ => 0
  | .scale, start, .two initial middle terminal =>
      if initial = start then
        transition initial middle * transition middle terminal
      else 0
  | .scale, _, .one _ _ => 0

/-- The declared \(P^d\) terminal-belief marginal. -/
def declaredPowerMarginal : Project → Belief → Belief → ℚ
  | .discover, start, terminal => transition start terminal
  | .scale, start, terminal =>
      ∑ middle : Belief,
        transition start middle * transition middle terminal

/--
Scale admission is tilted toward high terminal beliefs while retaining the
raw admitted-success marginal \(3/4\).  This is the selected non-product
coupling.
-/
def scaleConditionalSuccess : Belief → Belief → ℚ
  | .low, .low => 3 / 5
  | .low, .high => 1
  | .high, .low => 1 / 3
  | .high, .high => 1

/-- Exact joint law of the full belief path and admitted outcome. -/
def jointMass (project : Project) (start : Belief)
    (state : CompressedState) (path : BeliefPath) (outcome : Outcome) : ℚ :=
  match project with
  | .discover =>
      pathMass .discover start path * admittedMass .discover state outcome
  | .scale =>
      if state = .k0 then
        pathMass .scale start path *
          if outcome = .failure then 1 else 0
      else
        let pass := scaleConditionalSuccess start (terminalBelief path)
        pathMass .scale start path *
          match outcome with
          | .failure => 1 - pass
          | .descendant => pass
          | _ => 0

def compressedPushforwardMass (project : Project) (state next : CompressedState) : ℚ :=
  ∑ outcome : Outcome,
    if compressedUpdate state outcome = next then
      admittedMass project state outcome
    else 0

def rawPushforwardMass (project : Project) (library : RawLibrary)
    (next : CompressedState) : ℚ :=
  ∑ outcome : Outcome,
    if compress (rawUpdate library outcome) = next then
      admittedMass project (compress library) outcome
    else 0

def pathOperatingReward (project : Project) (state : CompressedState) :
    BeliefPath → ℚ
  | .one initial _ =>
      if operates project then frontier state initial else 0
  | .two initial middle _ =>
      if operates project then
        frontier state initial + discount * frontier state middle
      else 0

def operatingRewardBlock (project : Project) (start : Belief)
    (state : CompressedState) : ℚ :=
  ∑ path : BeliefPath,
    pathMass project start path * pathOperatingReward project state path

def netResearchRewardBlock (project : Project) (start : Belief)
    (state : CompressedState) : ℚ :=
  operatingRewardBlock project start state - researchCost start project

def compressedContinueQ (value : Belief → CompressedState → ℚ)
    (belief : Belief) (state : CompressedState) : ℚ :=
  frontier state belief +
    discount * ∑ nextBelief : Belief,
      transition belief nextBelief * value nextBelief state

def rawContinueQ (value : Belief → RawLibrary → ℚ)
    (belief : Belief) (library : RawLibrary) : ℚ :=
  frontier (compress library) belief +
    discount * ∑ nextBelief : Belief,
      transition belief nextBelief * value nextBelief library

def compressedResearchQ (value : Belief → CompressedState → ℚ)
    (belief : Belief) (state : CompressedState) (project : Project) : ℚ :=
  -researchCost belief project +
    ∑ path : BeliefPath, ∑ outcome : Outcome,
      jointMass project belief state path outcome *
        (pathOperatingReward project state path +
          discount ^ duration project *
            value (terminalBelief path) (compressedUpdate state outcome))

def rawResearchQ (value : Belief → RawLibrary → ℚ)
    (belief : Belief) (library : RawLibrary) (project : Project) : ℚ :=
  -researchCost belief project +
    ∑ path : BeliefPath, ∑ outcome : Outcome,
      jointMass project belief (compress library) path outcome *
        (pathOperatingReward project (compress library) path +
          discount ^ duration project *
            value (terminalBelief path) (rawUpdate library outcome))

def compressedActionValue (value : Belief → CompressedState → ℚ)
    (belief : Belief) (state : CompressedState) : Action → ℚ
  | .continue => compressedContinueQ value belief state
  | .discover => compressedResearchQ value belief state .discover
  | .scale => compressedResearchQ value belief state .scale

def rawActionValue (value : Belief → RawLibrary → ℚ)
    (belief : Belief) (library : RawLibrary) : Action → ℚ
  | .continue => rawContinueQ value belief library
  | .discover => rawResearchQ value belief library .discover
  | .scale => rawResearchQ value belief library .scale

/-- Finite-horizon compressed recursion with the positive duration feasibility gate. -/
def compressedFiniteValue : Nat → Belief → CompressedState → ℚ
  | 0, _, _ => 0
  | horizon + 1, belief, state =>
      let continueValue :=
        compressedContinueQ (compressedFiniteValue horizon) belief state
      match state with
      | .k0 =>
          max continueValue
            (compressedResearchQ (compressedFiniteValue horizon)
              belief state .discover)
      | .k1 =>
          match horizon with
          | 0 => continueValue
          | prior + 1 =>
              max continueValue
                (compressedResearchQ (compressedFiniteValue prior)
                  belief state .scale)
      | .k2 =>
          match horizon with
          | 0 => continueValue
          | prior + 1 =>
              max continueValue
                (compressedResearchQ (compressedFiniteValue prior)
                  belief state .scale)

/-- Separate raw recursion, retaining deterministic raw insertion in continuation. -/
def rawFiniteValue : Nat → Belief → RawLibrary → ℚ
  | 0, _, _ => 0
  | horizon + 1, belief, library =>
      let continueValue :=
        rawContinueQ (rawFiniteValue horizon) belief library
      match compress library with
      | .k0 =>
          max continueValue
            (rawResearchQ (rawFiniteValue horizon)
              belief library .discover)
      | .k1 =>
          match horizon with
          | 0 => continueValue
          | prior + 1 =>
              max continueValue
                (rawResearchQ (rawFiniteValue prior)
                  belief library .scale)
      | .k2 =>
          match horizon with
          | 0 => continueValue
          | prior + 1 =>
              max continueValue
                (rawResearchQ (rawFiniteValue prior)
                  belief library .scale)

def stationaryValue : Belief → CompressedState → ℚ
  | .low, .k0 => 115 / 288
  | .high, .k0 => 23 / 288
  | .low, .k1 => 1
  | .high, .k1 => 7 / 6
  | .low, .k2 => 14 / 3
  | .high, .k2 => 22 / 3

def stationarySelector : Belief → CompressedState → Action
  | .low, .k0 => .discover
  | .high, .k0 => .continue
  | _, .k1 => .scale
  | _, .k2 => .continue

def compressedBellman (value : Belief → CompressedState → ℚ)
    (belief : Belief) : CompressedState → ℚ
  | .k0 =>
      max
        (compressedActionValue value belief .k0 .continue)
        (compressedActionValue value belief .k0 .discover)
  | .k1 =>
      max
        (compressedActionValue value belief .k1 .continue)
        (compressedActionValue value belief .k1 .scale)
  | .k2 =>
      max
        (compressedActionValue value belief .k2 .continue)
        (compressedActionValue value belief .k2 .scale)

def compressedPolicyOperator (value : Belief → CompressedState → ℚ)
    (belief : Belief) (state : CompressedState) : ℚ :=
  compressedActionValue value belief state (stationarySelector belief state)

def liftedRawValue (belief : Belief) (library : RawLibrary) : ℚ :=
  stationaryValue belief (compress library)

def liftedRawSelector (belief : Belief) (library : RawLibrary) : Action :=
  stationarySelector belief (compress library)

def rawPolicyOperator (value : Belief → RawLibrary → ℚ)
    (belief : Belief) (library : RawLibrary) : ℚ :=
  rawActionValue value belief library (liftedRawSelector belief library)

def exactPolicyEvaluationResidual : ℚ :=
  max
    |compressedPolicyOperator stationaryValue .low .k0 -
      stationaryValue .low .k0|
    (max
      |compressedPolicyOperator stationaryValue .high .k0 -
        stationaryValue .high .k0|
      (max
        |compressedPolicyOperator stationaryValue .low .k1 -
          stationaryValue .low .k1|
        (max
          |compressedPolicyOperator stationaryValue .high .k1 -
            stationaryValue .high .k1|
          (max
            |compressedPolicyOperator stationaryValue .low .k2 -
              stationaryValue .low .k2|
            |compressedPolicyOperator stationaryValue .high .k2 -
              stationaryValue .high .k2|))))

abbrev RegisteredHorizon := Fin 9

/-! ## Exact structural and probability certificates -/

theorem rawLibrary_card :
    Fintype.card RawLibrary = 8 := by
  decide

theorem raw_representatives :
    compress rawK0 = .k0 ∧ compress rawK1 = .k1 ∧ compress rawK2 = .k2 := by
  decide

theorem rawUpdate_compresses (library : RawLibrary) (outcome : Outcome) :
    compress (rawUpdate library outcome) =
      compressedUpdate (compress library) outcome := by
  rcases library with ⟨carrierA, carrierB, descendant⟩
  cases carrierA <;> cases carrierB <;> cases descendant <;>
    cases outcome <;> decide

theorem rawUpdates_compress_to_declaredStates :
    compress (rawUpdate rawK0 .failure) = .k0 ∧
    compress (rawUpdate rawK0 .carrierA) = .k1 ∧
    compress (rawUpdate rawK0 .carrierB) = .k1 ∧
    compress (rawUpdate rawK1 .failure) = .k1 ∧
    compress (rawUpdate rawK1 .descendant) = .k2 ∧
    compress (rawUpdate rawK2 .failure) = .k2 ∧
    compress (rawUpdate rawK2 .descendant) = .k2 := by
  decide

theorem projectDurations_positive (project : Project) :
    0 < duration project := by
  cases project <;> norm_num [duration]

theorem beliefTransition_normalized (belief : Belief) :
    ∑ nextBelief : Belief, transition belief nextBelief = 1 := by
  cases belief <;> norm_num [sum_belief, transition]

theorem generation_normalized (project : Project) (state : CompressedState) :
    ∑ outcome : Outcome, generationMass project state outcome = 1 := by
  cases project <;> cases state <;>
    norm_num [sum_outcome, generationMass]

theorem verification_in_unit_interval (project : Project)
    (state : CompressedState) (outcome : Outcome) :
    0 ≤ verificationProbability project state outcome ∧
      verificationProbability project state outcome ≤ 1 := by
  cases project <;> cases state <;> cases outcome <;>
    norm_num [verificationProbability]

theorem admitted_normalized (project : Project) (state : CompressedState) :
    ∑ outcome : Outcome, admittedMass project state outcome = 1 := by
  cases project <;> cases state <;>
    simp [sum_outcome, admittedMass, generationMass,
      verificationProbability]
  all_goals norm_num

theorem joint_path_marginal (project : Project) (start : Belief)
    (state : CompressedState) (path : BeliefPath) :
    ∑ outcome : Outcome, jointMass project start state path outcome =
      pathMass project start path := by
  cases project with
  | discover =>
      simp only [jointMass]
      rw [← Finset.mul_sum, admitted_normalized, mul_one]
  | scale =>
      cases state <;>
        simp [sum_outcome, jointMass] <;> ring

theorem pathMass_normalized (project : Project) (start : Belief) :
    ∑ path : BeliefPath, pathMass project start path = 1 := by
  cases project <;> cases start <;>
    simp [sum_beliefPath, pathMass, transition] <;> norm_num

theorem joint_outcome_marginal (project : Project) (start : Belief)
    (state : CompressedState) (outcome : Outcome) :
    ∑ path : BeliefPath, jointMass project start state path outcome =
      admittedMass project state outcome := by
  cases project with
  | discover =>
      simp only [jointMass]
      rw [← Finset.sum_mul, pathMass_normalized, one_mul]
  | scale =>
      cases start <;> cases state <;> cases outcome <;>
        simp [sum_beliefPath, sum_outcome, jointMass, admittedMass,
          generationMass, verificationProbability, pathMass, transition,
          scaleConditionalSuccess, terminalBelief] <;> norm_num

theorem joint_normalized (project : Project) (start : Belief)
    (state : CompressedState) :
    ∑ path : BeliefPath, ∑ outcome : Outcome,
      jointMass project start state path outcome = 1 := by
  rw [show
    (∑ path : BeliefPath, ∑ outcome : Outcome,
      jointMass project start state path outcome) =
      ∑ path : BeliefPath, pathMass project start path by
        apply Finset.sum_congr rfl
        intro path _
        exact joint_path_marginal project start state path]
  exact pathMass_normalized project start

/-- Requirement 1: every primitive or derived raw probability law is normalized. -/
theorem rawProbabilityLaws_normalized :
    (∀ belief, ∑ nextBelief : Belief, transition belief nextBelief = 1) ∧
    (∀ project state,
      ∑ outcome : Outcome, generationMass project state outcome = 1) ∧
    (∀ project state,
      ∑ outcome : Outcome, admittedMass project state outcome = 1) ∧
    (∀ project start state,
      ∑ path : BeliefPath, ∑ outcome : Outcome,
        jointMass project start state path outcome = 1) := by
  exact ⟨beliefTransition_normalized, generation_normalized,
    admitted_normalized, joint_normalized⟩

theorem compressedPushforward_normalized
    (project : Project) (state : CompressedState) :
    ∑ next : CompressedState,
      compressedPushforwardMass project state next = 1 := by
  cases project <;> cases state <;>
    simp [sum_compressedState, sum_outcome,
      compressedPushforwardMass, compressedUpdate, admittedMass,
      generationMass, verificationProbability]
  all_goals norm_num

/-- Requirement 2: every compressed admitted-outcome pushforward is normalized. -/
theorem compressedPushforwardLaws_normalized :
    ∀ project state,
      ∑ next : CompressedState,
        compressedPushforwardMass project state next = 1 :=
  compressedPushforward_normalized

theorem rawPushforward_eq_compressed (project : Project)
    (library : RawLibrary) (next : CompressedState) :
    rawPushforwardMass project library next =
      compressedPushforwardMass project (compress library) next := by
  unfold rawPushforwardMass compressedPushforwardMass
  apply Finset.sum_congr rfl
  intro outcome _
  rw [rawUpdate_compresses]

/-! ## Exact path and operating-block certificates -/

theorem beliefPath_terminal_marginal (project : Project) (start terminal : Belief) :
    (∑ path : BeliefPath,
      if terminalBelief path = terminal then pathMass project start path else 0) =
        declaredPowerMarginal project start terminal := by
  cases project <;> cases start <;> cases terminal <;>
    simp [sum_belief, sum_beliefPath, terminalBelief, pathMass,
      declaredPowerMarginal, transition]

/-- Requirement 5: full path probabilities induce the declared \(P^d\) marginals. -/
theorem beliefPathProbabilities_eq_declaredPowers :
    ∀ project start terminal,
      (∑ path : BeliefPath,
        if terminalBelief path = terminal then pathMass project start path else 0) =
      declaredPowerMarginal project start terminal :=
  beliefPath_terminal_marginal

/-- Requirement 6: exact operating and net reward blocks used by the manuscript. -/
theorem operatingRewardBlocks_eq_declared :
    operatingRewardBlock .discover .low .k0 = 0 ∧
    operatingRewardBlock .discover .high .k0 = 0 ∧
    operatingRewardBlock .scale .low .k1 = 0 ∧
    operatingRewardBlock .scale .high .k1 = 0 ∧
    operatingRewardBlock .scale .low .k2 = 13 / 4 ∧
    operatingRewardBlock .scale .high .k2 = 23 / 4 ∧
    netResearchRewardBlock .discover .low .k0 = -(1 / 32) ∧
    netResearchRewardBlock .discover .high .k0 = -1 ∧
    netResearchRewardBlock .scale .low .k1 = -(3 / 16) ∧
    netResearchRewardBlock .scale .high .k1 = -(3 / 16) ∧
    netResearchRewardBlock .scale .low .k2 = 49 / 16 ∧
    netResearchRewardBlock .scale .high .k2 = 89 / 16 := by
  simp [sum_beliefPath, operatingRewardBlock, pathOperatingReward,
    pathMass, transition, discount, operates, frontier, netResearchRewardBlock,
    researchCost]
  all_goals norm_num

/-! ## Raw/compressed finite-horizon correspondence -/

theorem rawContinueQ_lift
    (rawValue : Belief → RawLibrary → ℚ)
    (compressedValue : Belief → CompressedState → ℚ)
    (hlift : ∀ belief library,
      rawValue belief library = compressedValue belief (compress library))
    (belief : Belief) (library : RawLibrary) :
    rawContinueQ rawValue belief library =
      compressedContinueQ compressedValue belief (compress library) := by
  unfold rawContinueQ compressedContinueQ
  congr 1
  simp_rw [hlift]

theorem rawResearchQ_lift
    (rawValue : Belief → RawLibrary → ℚ)
    (compressedValue : Belief → CompressedState → ℚ)
    (hlift : ∀ belief library,
      rawValue belief library = compressedValue belief (compress library))
    (belief : Belief) (library : RawLibrary) (project : Project) :
    rawResearchQ rawValue belief library project =
      compressedResearchQ compressedValue belief (compress library) project := by
  unfold rawResearchQ compressedResearchQ
  congr 1
  apply Finset.sum_congr rfl
  intro path _
  apply Finset.sum_congr rfl
  intro outcome _
  rw [hlift, rawUpdate_compresses]

theorem rawCompressedFiniteValue_eq :
    ∀ horizon belief library,
      rawFiniteValue horizon belief library =
        compressedFiniteValue horizon belief (compress library) := by
  intro horizon
  induction horizon using Nat.strong_induction_on with
  | h horizon inductionHypothesis =>
      intro belief library
      cases horizon with
      | zero => rfl
      | succ horizon =>
          unfold rawFiniteValue compressedFiniteValue
          rw [rawContinueQ_lift
            (rawFiniteValue horizon) (compressedFiniteValue horizon)
            (fun nextBelief nextLibrary =>
              inductionHypothesis horizon (Nat.lt_succ_self horizon)
                nextBelief nextLibrary)]
          cases hstate : compress library with
          | k0 =>
              simp only
              rw [rawResearchQ_lift
                (rawFiniteValue horizon) (compressedFiniteValue horizon)
                (fun nextBelief nextLibrary =>
                  inductionHypothesis horizon (Nat.lt_succ_self horizon)
                    nextBelief nextLibrary)]
              simp only [hstate]
          | k1 =>
              cases horizon with
              | zero => rfl
              | succ prior =>
                  simp only
                  rw [rawResearchQ_lift
                    (rawFiniteValue prior) (compressedFiniteValue prior)
                    (fun nextBelief nextLibrary =>
                      inductionHypothesis prior (by omega)
                        nextBelief nextLibrary)]
                  simp only [hstate]
          | k2 =>
              cases horizon with
              | zero => rfl
              | succ prior =>
                  simp only
                  rw [rawResearchQ_lift
                    (rawFiniteValue prior) (compressedFiniteValue prior)
                    (fun nextBelief nextLibrary =>
                      inductionHypothesis prior (by omega)
                        nextBelief nextLibrary)]
                  simp only [hstate]

/-- Requirement 7: equality holds for every registered horizon zero through eight. -/
theorem registeredFiniteHorizon_raw_eq_compressed
    (horizon : RegisteredHorizon) (belief : Belief) (library : RawLibrary) :
    rawFiniteValue horizon.val belief library =
      compressedFiniteValue horizon.val belief (compress library) :=
  rawCompressedFiniteValue_eq horizon.val belief library

/-! ## Exact stationary solution and policy certificates -/

theorem stationaryActionValues_eq_declared :
    compressedActionValue stationaryValue .low .k0 .continue = 23 / 144 ∧
    compressedActionValue stationaryValue .low .k0 .discover = 115 / 288 ∧
    compressedActionValue stationaryValue .high .k0 .continue = 23 / 288 ∧
    compressedActionValue stationaryValue .high .k0 .discover = -(643 / 1152) ∧
    compressedActionValue stationaryValue .low .k1 .continue = 25 / 48 ∧
    compressedActionValue stationaryValue .low .k1 .scale = 1 ∧
    compressedActionValue stationaryValue .high .k1 .continue = 9 / 16 ∧
    compressedActionValue stationaryValue .high .k1 .scale = 7 / 6 ∧
    compressedActionValue stationaryValue .low .k2 .continue = 14 / 3 ∧
    compressedActionValue stationaryValue .low .k2 .scale = 215 / 48 ∧
    compressedActionValue stationaryValue .high .k2 .continue = 22 / 3 ∧
    compressedActionValue stationaryValue .high .k2 .scale = 343 / 48 := by
  simp [sum_belief, sum_beliefPath, sum_outcome,
    compressedActionValue, compressedContinueQ, compressedResearchQ,
    stationaryValue, frontier, transition, discount, researchCost, jointMass,
    pathMass, admittedMass, generationMass, verificationProbability,
    pathOperatingReward, operates, compressedUpdate, duration, scaleConditionalSuccess,
    terminalBelief]
  all_goals norm_num

/-- Requirement 8: the manuscript's rational table is an exact Bellman fixed point. -/
theorem stationaryValue_bellmanFixedPoint :
    ∀ belief state,
      compressedBellman stationaryValue belief state =
        stationaryValue belief state := by
  rcases stationaryActionValues_eq_declared with
    ⟨hk0lc, hk0ld, hk0hc, hk0hd, hk1lc, hk1ls,
      hk1hc, hk1hs, hk2lc, hk2ls, hk2hc, hk2hs⟩
  intro belief state
  cases belief <;> cases state <;>
    simp [compressedBellman, stationaryValue, hk0lc, hk0ld, hk0hc, hk0hd,
      hk1lc, hk1ls, hk1hc, hk1hs, hk2lc, hk2ls, hk2hc, hk2hs] <;>
    norm_num

/-- Requirement 9: the declared selector attains the Bellman maximum everywhere. -/
theorem stationarySelector_attains :
    ∀ belief state,
      compressedActionValue stationaryValue belief state
          (stationarySelector belief state) =
        compressedBellman stationaryValue belief state := by
  rcases stationaryActionValues_eq_declared with
    ⟨hk0lc, hk0ld, hk0hc, hk0hd, hk1lc, hk1ls,
      hk1hc, hk1hs, hk2lc, hk2ls, hk2hc, hk2hs⟩
  intro belief state
  cases belief <;> cases state <;>
    simp [stationarySelector, compressedBellman, hk0lc, hk0ld, hk0hc, hk0hd,
      hk1lc, hk1ls, hk1hc, hk1hs, hk2lc, hk2ls, hk2hc, hk2hs] <;>
    norm_num

theorem stationarySelector_policyEvaluationValue :
    ∀ belief state,
      compressedPolicyOperator stationaryValue belief state =
        stationaryValue belief state := by
  intro belief state
  rw [compressedPolicyOperator, stationarySelector_attains,
    stationaryValue_bellmanFixedPoint]

theorem rawActionValue_lift
    (rawValue : Belief → RawLibrary → ℚ)
    (compressedValue : Belief → CompressedState → ℚ)
    (hlift : ∀ belief library,
      rawValue belief library = compressedValue belief (compress library))
    (belief : Belief) (library : RawLibrary) (action : Action) :
    rawActionValue rawValue belief library action =
      compressedActionValue compressedValue belief (compress library) action := by
  cases action <;>
    simp only [rawActionValue, compressedActionValue]
  · exact rawContinueQ_lift rawValue compressedValue hlift belief library
  · exact rawResearchQ_lift rawValue compressedValue hlift
      belief library Project.discover
  · exact rawResearchQ_lift rawValue compressedValue hlift
      belief library Project.scale

/-- Requirement 10: the lifted raw selector has the same policy-evaluation value. -/
theorem liftedRawSelector_policyEvaluationValue
    (belief : Belief) (library : RawLibrary) :
    rawPolicyOperator liftedRawValue belief library =
      liftedRawValue belief library := by
  change
    rawActionValue liftedRawValue belief library
        (stationarySelector belief (compress library)) =
      stationaryValue belief (compress library)
  rw [rawActionValue_lift liftedRawValue stationaryValue
    (fun _ _ => rfl)]
  exact stationarySelector_policyEvaluationValue belief (compress library)

/-- Requirement 11: the exact policy-evaluation residual is zero. -/
theorem exactPolicyEvaluationResidual_eq_zero :
    exactPolicyEvaluationResidual = 0 := by
  norm_num [exactPolicyEvaluationResidual,
    stationarySelector_policyEvaluationValue]

/-- Requirement 12: every manuscript-displayed optimal action is unique. -/
theorem optimalActions_unique (belief : Belief) (state : CompressedState)
    (action : Action) (havailable : action ∈ availableActions state)
    (hoptimal :
      compressedActionValue stationaryValue belief state action =
        stationaryValue belief state) :
    action = stationarySelector belief state := by
  rcases stationaryActionValues_eq_declared with
    ⟨hk0lc, _, _, hk0hd, hk1lc, _, hk1hc, _, _, hk2ls, _, hk2hs⟩
  cases belief <;> cases state <;> cases action <;>
    simp [availableActions, stationarySelector] at havailable ⊢ <;>
    simp [stationaryValue, hk0lc, hk0hd, hk1lc, hk1hc, hk2ls, hk2hs]
      at hoptimal <;>
    norm_num at hoptimal

end UnifiedCanonicalFixture

end Model

end Projection

end StrategyInnovation
