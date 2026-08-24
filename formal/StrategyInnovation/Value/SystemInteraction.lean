import Mathlib.Tactic
import StrategyInnovation.Value.ComparativeStatics

/-!
# Frontier--closure system interaction (T7)

This module defines the closure increment and its frontier cross difference on
the unified compressed value.  A finite maximum theorem proves substitution
when every closure-rich feasible action loses weakly more relative to every
closure-poor feasible action as the frontier rises.

Primitive frontier independence is retained explicitly, but it is not enough
for the cross-difference sign.  An exact one-belief counterexample shows that
the optimizer can switch from a high-success/high-cost old project to a
lower-success/zero-cost added project.  Both project returns saturate in the
frontier and every primitive is frontier independent, yet closure enrichment
is more valuable at the higher frontier.

The corrected theorem therefore exposes `RelativeActionSaturation`.  This is a
finite Bellman-node single-crossing condition, not an assumption about the
optimized cross difference.  Separate exact examples give strict
substitution, strict complementarity from frontier-dependent success, and
zero interaction.
-/

namespace StrategyInnovation

namespace Projection

namespace Model

namespace SystemInteraction

open ComparativeStatics

variable {model : FiniteModel}
variable {catalog : Raw.StrategyCatalog model}
variable {closure : Raw.ClosureOperator model}

/-! ## Cross-difference definitions -/

/-- The value increment from replacing `closure0` by `closure1` at a frontier. -/
def closureIncrement
    {Frontier Closure : Type*}
    (value : Frontier → Closure → ℚ)
    (frontier : Frontier) (closure1 closure0 : Closure) : ℚ :=
  value frontier closure1 - value frontier closure0

/--
The frontier--closure cross difference.  Nonpositive values mean substitution;
nonnegative values mean complementarity.
-/
def interactionCrossDifference
    {Frontier Closure : Type*}
    (value : Frontier → Closure → ℚ)
    (frontier1 frontier0 : Frontier) (closure1 closure0 : Closure) : ℚ :=
  closureIncrement value frontier1 closure1 closure0 -
    closureIncrement value frontier0 closure1 closure0

/-- Frontier and closure are substitutes on the displayed rectangle. -/
def AreSubstitutes
    {Frontier Closure : Type*}
    (value : Frontier → Closure → ℚ)
    (frontier1 frontier0 : Frontier) (closure1 closure0 : Closure) : Prop :=
  interactionCrossDifference value frontier1 frontier0 closure1 closure0 ≤ 0

/-- Frontier and closure are complements on the displayed rectangle. -/
def AreComplements
    {Frontier Closure : Type*}
    (value : Frontier → Closure → ℚ)
    (frontier1 frontier0 : Frontier) (closure1 closure0 : Closure) : Prop :=
  0 ≤ interactionCrossDifference value frontier1 frontier0 closure1 closure0

/-- Closure increment for the final finite-horizon compressed value. -/
noncomputable def compressedClosureIncrement
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (rich poor : CompressedLibraryState catalog closure) : ℚ :=
  process.compressedValue horizon belief rich -
    process.compressedValue horizon belief poor

/-- T7 cross difference on four realizable compressed states. -/
noncomputable def compressedInteractionCrossDifference
    (process : Model model catalog closure)
    (horizon : Nat) (belief : model.Belief)
    (lowPoor lowRich highPoor highRich :
      CompressedLibraryState catalog closure) : ℚ :=
  compressedClosureIncrement process horizon belief highRich highPoor -
    compressedClosureIncrement process horizon belief lowRich lowPoor

/-! ## A frontier--closure rectangle in the realizable state space -/

/--
Four realizable compressed states form an ordered frontier--closure rectangle.
Rows have the same frontier, columns have the same closure, the frontier rises
down the columns, and the closure expands across the rows.
-/
structure FrontierClosureRectangle
    (lowPoor lowRich highPoor highRich :
      CompressedLibraryState catalog closure) : Prop where
  low_frontier_eq :
    lowPoor.state.frontier = lowRich.state.frontier
  high_frontier_eq :
    highPoor.state.frontier = highRich.state.frontier
  poor_closure_eq :
    lowPoor.state.closure = highPoor.state.closure
  rich_closure_eq :
    lowRich.state.closure = highRich.state.closure
  frontier_le :
    ∀ belief,
      lowPoor.state.frontier belief ≤ highPoor.state.frontier belief
  closure_subset :
    lowPoor.state.closure ⊆ lowRich.state.closure

namespace FrontierClosureRectangle

variable
  {lowPoor lowRich highPoor highRich :
    CompressedLibraryState catalog closure}

/-- The closure-poor column has the required same-closure frontier order. -/
theorem poor_sameClosureFrontierLE
    (rectangle :
      FrontierClosureRectangle lowPoor lowRich highPoor highRich) :
    SameClosureFrontierLE lowPoor highPoor :=
  ⟨rectangle.poor_closure_eq, rectangle.frontier_le⟩

/-- The closure-rich column inherits the same frontier order. -/
theorem rich_sameClosureFrontierLE
    (rectangle :
      FrontierClosureRectangle lowPoor lowRich highPoor highRich) :
    SameClosureFrontierLE lowRich highRich := by
  constructor
  · exact rectangle.rich_closure_eq
  · intro belief
    rw [← rectangle.low_frontier_eq, ← rectangle.high_frontier_eq]
    exact rectangle.frontier_le belief

/-- The high-frontier row inherits the same closure inclusion. -/
theorem high_closure_subset
    (rectangle :
      FrontierClosureRectangle lowPoor lowRich highPoor highRich) :
    highPoor.state.closure ⊆ highRich.state.closure := by
  rw [← rectangle.poor_closure_eq, ← rectangle.rich_closure_eq]
  exact rectangle.closure_subset

end FrontierClosureRectangle

/-! ## Exact Bellman-node saturation -/

/-- Feasibility stated on the common raw action type. -/
def ActionFeasible
    (process : Model model catalog closure)
    (horizon : Nat) (state : CompressedLibraryState catalog closure) :
    Action model → Prop
  | none => True
  | some project =>
      project ∈ process.available state ∧
        process.duration project ≤ horizon

/-- The exact unified action value at a positive-horizon Bellman node. -/
noncomputable def nodeActionValue
    (process : Model model catalog closure)
    (remaining : Nat) (belief : model.Belief)
    (state : CompressedLibraryState catalog closure) :
    Action model → ℚ
  | none =>
      state.state.frontier belief +
        process.discount *
          (process.beliefTransition belief).expectation
            (fun nextBelief =>
              process.compressedValue remaining nextBelief state)
  | some project =>
      -process.researchCost belief state project +
        (process.completion project belief state).expectation
          (fun completion =>
            process.incumbentReward state project completion.1 +
              process.discount ^ process.duration project *
                process.compressedValue
                  ((remaining + 1) - process.duration project)
                  (terminalBelief completion.1)
                  (CompressedLibraryState.add catalog closure state
                    completion.2))

/-- The recursive compressed value is the maximum of the node action values. -/
theorem compressedValue_succ_eq_actionMaximum
    (process : Model model catalog closure)
    (remaining : Nat) (belief : model.Belief)
    (state : CompressedLibraryState catalog closure) :
    process.compressedValue (remaining + 1) belief state =
      Finset.univ.sup' Finset.univ_nonempty
        (fun action : FeasibleAction process (remaining + 1) state =>
          nodeActionValue process remaining belief state action.1) := by
  simp only [compressedValue]
  apply congrArg
    (fun payoff :
        FeasibleAction process (remaining + 1) state → ℚ =>
      Finset.univ.sup' Finset.univ_nonempty payoff)
  funext action
  cases action.1 <;> rfl

/--
Relative action saturation is the missing single-crossing condition.

For every Bellman node, each action feasible with the rich closure at the high
frontier has a weakly smaller payoff advantage over every action feasible with
the poor closure than the corresponding advantage at the low frontier.
The action values include the exact optimized lower-horizon continuation, but
the condition does not assume the desired four-value cross difference.
-/
def RelativeActionSaturation
    (process : Model model catalog closure)
    (lowPoor lowRich highPoor highRich :
      CompressedLibraryState catalog closure) : Prop :=
  ∀ remaining belief richAction poorAction,
    ActionFeasible process (remaining + 1) highRich richAction →
    ActionFeasible process (remaining + 1) lowPoor poorAction →
      nodeActionValue process remaining belief highRich richAction -
          nodeActionValue process remaining belief highPoor poorAction ≤
        nodeActionValue process remaining belief lowRich richAction -
          nodeActionValue process remaining belief lowPoor poorAction

/-! ## Primitive common-gap sufficient condition -/

/--
A fixed-continuation, single-descendant common-gap decomposition.

At every Bellman node, the four action-value tables share a frontier-specific
base.  Rich-closure actions have a frontier-independent intercept and a
nonnegative exposure to one common descendant gap.  Every poor-closure action
that is actually feasible has zero exposure to that gap.  The common gap is
weakly smaller at the high frontier.

The equalities encode the economically narrow preservation restriction:
project cost, timing, operation, completion law, and the continuation component
outside the displayed descendant gap do not retune with the frontier.  A
Continue-only poor menu is the leading special case.
-/
structure CommonGapActionDecomposition
    (process : Model model catalog closure)
    (lowPoor lowRich highPoor highRich :
      CompressedLibraryState catalog closure) where
  baseLow : Nat → model.Belief → ℚ
  baseHigh : Nat → model.Belief → ℚ
  gapLow : Nat → model.Belief → ℚ
  gapHigh : Nat → model.Belief → ℚ
  richIntercept : Nat → model.Belief → Action model → ℚ
  poorIntercept : Nat → model.Belief → Action model → ℚ
  richExposure : Nat → model.Belief → Action model → ℚ
  poorExposure : Nat → model.Belief → Action model → ℚ
  gap_antitone :
    ∀ remaining belief,
      gapHigh remaining belief ≤ gapLow remaining belief
  richExposure_nonnegative :
    ∀ remaining belief action,
      0 ≤ richExposure remaining belief action
  poorExposure_zero :
    ∀ remaining belief action,
      ActionFeasible process (remaining + 1) lowPoor action →
        poorExposure remaining belief action = 0
  highRich_value :
    ∀ remaining belief action,
      nodeActionValue process remaining belief highRich action =
        baseHigh remaining belief +
          richIntercept remaining belief action +
            richExposure remaining belief action * gapHigh remaining belief
  highPoor_value :
    ∀ remaining belief action,
      nodeActionValue process remaining belief highPoor action =
        baseHigh remaining belief +
          poorIntercept remaining belief action +
            poorExposure remaining belief action * gapHigh remaining belief
  lowRich_value :
    ∀ remaining belief action,
      nodeActionValue process remaining belief lowRich action =
        baseLow remaining belief +
          richIntercept remaining belief action +
            richExposure remaining belief action * gapLow remaining belief
  lowPoor_value :
    ∀ remaining belief action,
      nodeActionValue process remaining belief lowPoor action =
        baseLow remaining belief +
          poorIntercept remaining belief action +
            poorExposure remaining belief action * gapLow remaining belief

/--
Primitive common-gap saturation implies exact relative action saturation.

The proof is the primitive exposure factorization
`richExposure * (gapHigh - gapLow) ≤ 0`.  Zero poor-menu exposure is necessary
for this all-pairs conclusion in the nonnegative-exposure subclass because
Continue is always a rich action and itself has zero descendant-gap exposure.
-/
theorem relativeActionSaturation_of_commonGap
    (process : Model model catalog closure)
    {lowPoor lowRich highPoor highRich :
      CompressedLibraryState catalog closure}
    (decomposition :
      CommonGapActionDecomposition process
        lowPoor lowRich highPoor highRich) :
    RelativeActionSaturation process lowPoor lowRich highPoor highRich := by
  intro remaining belief richAction poorAction _ hpoor
  rw [decomposition.highRich_value, decomposition.highPoor_value,
    decomposition.lowRich_value, decomposition.lowPoor_value]
  have hgap := decomposition.gap_antitone remaining belief
  have hexposure :=
    decomposition.richExposure_nonnegative remaining belief richAction
  have hpoorExposure :=
    decomposition.poorExposure_zero remaining belief poorAction hpoor
  rw [hpoorExposure]
  have hproduct :=
    mul_le_mul_of_nonneg_left hgap hexposure
  linarith

/--
Corrected T7 assumptions.

The first three fields encode the requested frontier order, primitive
frontier independence, and opportunity-only closure expansion.  The final
field is the additional relative-saturation condition required after
CX-T7-INDEPENDENT-MENU-SWITCH-02.
-/
structure SubstitutionAssumptions
    (process : Model model catalog closure)
    (lowPoor lowRich highPoor highRich :
      CompressedLibraryState catalog closure) : Prop where
  rectangle :
    FrontierClosureRectangle lowPoor lowRich highPoor highRich
  frontier_independent :
    FrontierIndependentPrimitives process
  opportunities_expand :
    process.available lowPoor ⊆ process.available lowRich
  relative_saturation :
    RelativeActionSaturation process lowPoor lowRich highPoor highRich

/--
T7, corrected finite substitution theorem.

Under primitive frontier independence, closure menu expansion, and relative
Bellman-action saturation, the optimized closure increment is antitone in the
frontier at every finite horizon and belief.
-/
theorem compressedInteractionCrossDifference_nonpositive
    (process : Model model catalog closure)
    {lowPoor lowRich highPoor highRich :
      CompressedLibraryState catalog closure}
    (assumptions :
      SubstitutionAssumptions process lowPoor lowRich highPoor highRich) :
    ∀ horizon belief,
      compressedInteractionCrossDifference process horizon belief
        lowPoor lowRich highPoor highRich ≤ 0 := by
  intro horizon belief
  cases horizon with
  | zero =>
      simp [compressedInteractionCrossDifference,
        compressedClosureIncrement, compressedValue]
  | succ remaining =>
      have poorAvailable :
          process.available lowPoor = process.available highPoor :=
        assumptions.frontier_independent.available_eq
          assumptions.rectangle.poor_sameClosureFrontierLE
      have richAvailable :
          process.available lowRich = process.available highRich :=
        assumptions.frontier_independent.available_eq
          assumptions.rectangle.rich_sameClosureFrontierLE
      let highRichPayoff :
          FeasibleAction process (remaining + 1) highRich → ℚ :=
        fun action =>
          nodeActionValue process remaining belief highRich action.1
      let lowPoorPayoff :
          FeasibleAction process (remaining + 1) lowPoor → ℚ :=
        fun action =>
          nodeActionValue process remaining belief lowPoor action.1
      obtain ⟨richAction, _, hrichMaximum⟩ :=
        Finset.exists_mem_eq_sup' Finset.univ_nonempty highRichPayoff
      obtain ⟨poorAction, _, hpoorMaximum⟩ :=
        Finset.exists_mem_eq_sup' Finset.univ_nonempty lowPoorPayoff
      let richActionLow :
          FeasibleAction process (remaining + 1) lowRich :=
        ⟨richAction.1, by
          cases haction : richAction.1 with
          | none => trivial
          | some project =>
              have hfeasible := richAction.2
              rw [haction] at hfeasible
              change
                project ∈ process.available highRich ∧
                  process.duration project ≤ remaining + 1 at hfeasible
              change
                project ∈ process.available lowRich ∧
                  process.duration project ≤ remaining + 1
              constructor
              · rw [richAvailable]
                exact hfeasible.1
              · exact hfeasible.2⟩
      let poorActionHigh :
          FeasibleAction process (remaining + 1) highPoor :=
        ⟨poorAction.1, by
          cases haction : poorAction.1 with
          | none => trivial
          | some project =>
              have hfeasible := poorAction.2
              rw [haction] at hfeasible
              change
                project ∈ process.available lowPoor ∧
                  process.duration project ≤ remaining + 1 at hfeasible
              change
                project ∈ process.available highPoor ∧
                  process.duration project ≤ remaining + 1
              constructor
              · rw [← poorAvailable]
                exact hfeasible.1
              · exact hfeasible.2⟩
      have hsaturation :=
        assumptions.relative_saturation remaining belief
          richAction.1 poorAction.1 richAction.2 poorAction.2
      have hhighPoor :
          nodeActionValue process remaining belief highPoor poorAction.1 ≤
            process.compressedValue (remaining + 1) belief highPoor := by
        rw [compressedValue_succ_eq_actionMaximum]
        exact Finset.le_sup'
          (fun action : FeasibleAction process (remaining + 1) highPoor =>
            nodeActionValue process remaining belief highPoor action.1)
          (Finset.mem_univ poorActionHigh)
      have hlowRich :
          nodeActionValue process remaining belief lowRich richAction.1 ≤
            process.compressedValue (remaining + 1) belief lowRich := by
        rw [compressedValue_succ_eq_actionMaximum]
        exact Finset.le_sup'
          (fun action : FeasibleAction process (remaining + 1) lowRich =>
            nodeActionValue process remaining belief lowRich action.1)
          (Finset.mem_univ richActionLow)
      have hhighRich :
          process.compressedValue (remaining + 1) belief highRich =
            nodeActionValue process remaining belief highRich richAction.1 := by
        rw [compressedValue_succ_eq_actionMaximum]
        exact hrichMaximum
      have hlowPoor :
          process.compressedValue (remaining + 1) belief lowPoor =
            nodeActionValue process remaining belief lowPoor poorAction.1 := by
        rw [compressedValue_succ_eq_actionMaximum]
        exact hpoorMaximum
      unfold compressedInteractionCrossDifference
        compressedClosureIncrement
      rw [hhighRich, hlowPoor]
      linarith

/-! ## Primitive sufficient-condition corollary -/

/--
Primitive assumptions for the economically interpretable common-gap subclass.

The rectangle and frontier-independence fields retain the unified model's
primitive comparison.  Opportunity expansion makes the closure comparison a
menu enrichment.  `commonGap` supplies the fixed-continuation,
single-descendant decomposition that derives, rather than assumes, relative
action saturation.
-/
structure PrimitiveSubstitutionAssumptions
    (process : Model model catalog closure)
    (lowPoor lowRich highPoor highRich :
      CompressedLibraryState catalog closure) where
  rectangle :
    FrontierClosureRectangle lowPoor lowRich highPoor highRich
  frontier_independent :
    FrontierIndependentPrimitives process
  opportunities_expand :
    process.available lowPoor ⊆ process.available lowRich
  commonGap :
    CommonGapActionDecomposition process
      lowPoor lowRich highPoor highRich

/--
The full primitive assumption package implies relative action saturation.

The common-gap preservation certificate is the sign-bearing premise for this
subimplication. Frontier independence and menu inclusion remain in the package
because they transport feasibility and give the comparison its economic
closure-expansion interpretation when general T7 is invoked.
-/
theorem relativeActionSaturation_of_primitiveSaturation
    (process : Model model catalog closure)
    {lowPoor lowRich highPoor highRich :
      CompressedLibraryState catalog closure}
    (assumptions :
      PrimitiveSubstitutionAssumptions process
        lowPoor lowRich highPoor highRich) :
    RelativeActionSaturation process lowPoor lowRich highPoor highRich :=
  relativeActionSaturation_of_commonGap process assumptions.commonGap

/-- The primitive common-gap certificate supplies every corrected T7 field. -/
theorem PrimitiveSubstitutionAssumptions.toSubstitutionAssumptions
    (process : Model model catalog closure)
    {lowPoor lowRich highPoor highRich :
      CompressedLibraryState catalog closure}
    (assumptions :
      PrimitiveSubstitutionAssumptions process
        lowPoor lowRich highPoor highRich) :
    SubstitutionAssumptions process lowPoor lowRich highPoor highRich where
  rectangle := assumptions.rectangle
  frontier_independent := assumptions.frontier_independent
  opportunities_expand := assumptions.opportunities_expand
  relative_saturation :=
    relativeActionSaturation_of_primitiveSaturation process assumptions

/--
Primitive common-gap frontier saturation yields frontier--closure substitution.

This is an interpretable sufficient-condition corollary of general T7, not a
replacement for it.  The optimizer-switching complementarity example remains
outside the subclass because its poor project has positive gap exposure.
-/
theorem compressedInteractionCrossDifference_nonpositive_of_primitiveSaturation
    (process : Model model catalog closure)
    {lowPoor lowRich highPoor highRich :
      CompressedLibraryState catalog closure}
    (assumptions :
      PrimitiveSubstitutionAssumptions process
        lowPoor lowRich highPoor highRich) :
    ∀ horizon belief,
      compressedInteractionCrossDifference process horizon belief
        lowPoor lowRich highPoor highRich ≤ 0 :=
  compressedInteractionCrossDifference_nonpositive process
    (assumptions.toSubstitutionAssumptions process)

/-! ## Exact examples and the insufficiency boundary -/

namespace Examples

/-- The closure-poor module set. -/
def poorClosure : Finset (Fin 1) := ∅

/-- The closure-rich module set. -/
def richClosure : Finset (Fin 1) := Finset.univ

theorem poorClosure_subset_richClosure :
    poorClosure ⊆ richClosure := by
  simp [poorClosure, richClosure]

/-- Exact one-project net premium over a frozen frontier. -/
def oneProjectPremium
    (frontier success cost candidate : ℚ) : ℚ :=
  max 0 ((1 / 2) * success * max (candidate - frontier) 0 - cost)

/--
Strict substitution by frontier saturation: closure adds one fixed,
frontier-independent candidate opportunity.
-/
def substitutionValue
    (frontier : ℚ) (modules : Finset (Fin 1)) : ℚ :=
  frontier +
    if (0 : Fin 1) ∈ modules then
      oneProjectPremium frontier 1 0 4
    else 0

theorem strict_substitution_example :
    closureIncrement substitutionValue 0 richClosure poorClosure = 2 ∧
    closureIncrement substitutionValue 2 richClosure poorClosure = 1 ∧
    interactionCrossDifference substitutionValue 2 0
      richClosure poorClosure = -1 ∧
    AreSubstitutes substitutionValue 2 0 richClosure poorClosure := by
  norm_num [closureIncrement, interactionCrossDifference, AreSubstitutes,
    substitutionValue, oneProjectPremium, poorClosure, richClosure]

/--
The five requested primitive conditions are insufficient.  Both project rows
are frontier independent and both fixed-candidate premia fall as the frontier
rises, but closure enrichment changes which project is optimal.
-/
def independentMenuSwitchValue
    (frontier : ℚ) (modules : Finset (Fin 1)) : ℚ :=
  frontier +
    max (oneProjectPremium frontier 1 2 10)
      (if (0 : Fin 1) ∈ modules then
        oneProjectPremium frontier (1 / 2) 0 10
      else 0)

theorem independent_menu_switch_individual_saturation :
    oneProjectPremium 8 1 2 10 ≤ oneProjectPremium 0 1 2 10 ∧
    oneProjectPremium 8 (1 / 2) 0 10 ≤
      oneProjectPremium 0 (1 / 2) 0 10 := by
  norm_num [oneProjectPremium]

theorem independent_menu_switch_crossDifference_positive :
    closureIncrement independentMenuSwitchValue 0
        richClosure poorClosure = 0 ∧
    closureIncrement independentMenuSwitchValue 8
        richClosure poorClosure = 1 / 2 ∧
    interactionCrossDifference independentMenuSwitchValue 8 0
        richClosure poorClosure = 1 / 2 ∧
    AreComplements independentMenuSwitchValue 8 0
      richClosure poorClosure := by
  norm_num [closureIncrement, interactionCrossDifference, AreComplements,
    independentMenuSwitchValue, oneProjectPremium, poorClosure, richClosure]

/-- Exact unclipped project return used to test all-pairs saturation. -/
def primitiveProjectReturn
    (frontier success cost candidate : ℚ) : ℚ :=
  (1 / 2) * success * max (candidate - frontier) 0 - cost

/--
Ordering the added exposure above the incumbent exposure is not enough for
all-pairs relative saturation when the poor menu already contains a
frontier-sensitive project.  Rich-menu Continue gains relative to that poor
project as the frontier rises.
-/
theorem added_exposure_order_insufficient_for_allPairs :
    (1 / 2 : ℚ) * 1 ≤ (1 / 2 : ℚ) * 1 ∧
      ¬ (0 - primitiveProjectReturn 8 1 0 10 ≤
        0 - primitiveProjectReturn 0 1 0 10) := by
  norm_num [primitiveProjectReturn]

/--
Requested complementarity mechanism: success is zero at the low frontier and
one at the high frontier, so closure enrichment is strictly more valuable.
-/
def frontierDependentSuccessValue
    (frontier : ℚ) (modules : Finset (Fin 1)) : ℚ :=
  frontier +
    if (0 : Fin 1) ∈ modules then
      oneProjectPremium frontier frontier 0 2
    else 0

theorem frontier_dependent_success_strict_complementarity :
    closureIncrement frontierDependentSuccessValue 0
        richClosure poorClosure = 0 ∧
    closureIncrement frontierDependentSuccessValue 1
        richClosure poorClosure = 1 / 2 ∧
    interactionCrossDifference frontierDependentSuccessValue 1 0
        richClosure poorClosure = 1 / 2 ∧
    AreComplements frontierDependentSuccessValue 1 0
      richClosure poorClosure := by
  norm_num [closureIncrement, interactionCrossDifference, AreComplements,
    frontierDependentSuccessValue, oneProjectPremium, poorClosure, richClosure]

/-- A nontrivial separable surface has exactly zero interaction. -/
def separableValue
    (frontier : ℚ) (modules : Finset (Fin 1)) : ℚ :=
  frontier + if (0 : Fin 1) ∈ modules then 3 / 2 else 0

theorem separable_zero_interaction :
    closureIncrement separableValue 0 richClosure poorClosure = 3 / 2 ∧
    closureIncrement separableValue 8 richClosure poorClosure = 3 / 2 ∧
    interactionCrossDifference separableValue 8 0
        richClosure poorClosure = 0 ∧
    AreSubstitutes separableValue 8 0 richClosure poorClosure ∧
    AreComplements separableValue 8 0 richClosure poorClosure := by
  norm_num [closureIncrement, interactionCrossDifference, AreSubstitutes,
    AreComplements, separableValue, poorClosure, richClosure]

end Examples

end SystemInteraction

end Model

end Projection

end StrategyInnovation
