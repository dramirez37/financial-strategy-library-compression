import Mathlib.Data.Finset.Max
import Mathlib.Algebra.Order.Ring.Unbundled.Rat
import StrategyInnovation.Library.Library

/-!
# Operational frontiers

The frontier is the actual maximum of the finitely many rational profiles in
an admissible library.  Nonemptiness comes from membership of the inactive
zero strategy, so no arbitrary empty-maximum convention is used.
-/

namespace StrategyInnovation

namespace Library

variable {model : FiniteModel} (catalog : StrategyCatalog model)
  (library : Library model catalog.inactiveStrategy)

/-- The finite set of payoffs represented in a library at one belief. -/
def payoffValues (belief : model.Belief) : Finset ℚ :=
  library.strategies.image fun strategy =>
    catalog.operationalProfile strategy belief

/-- The payoff-value set is nonempty because the inactive strategy is present. -/
theorem payoffValues_nonempty (belief : model.Belief) :
    (library.payoffValues catalog belief).Nonempty := by
  refine ⟨catalog.operationalProfile catalog.inactiveStrategy belief, ?_⟩
  exact Finset.mem_image.mpr
    ⟨catalog.inactiveStrategy, library.inactive_mem, rfl⟩

end Library

/-- The pointwise finite maximum of exact operational profiles in a library. -/
def operationalFrontier {model : FiniteModel} (catalog : StrategyCatalog model)
    (library : Library model catalog.inactiveStrategy) :
    model.Belief → ℚ :=
  fun belief =>
    (library.payoffValues catalog belief).max'
      (library.payoffValues_nonempty catalog belief)

/--
Every represented strategy profile is bounded above by the operational
frontier.
-/
theorem operationalProfile_le_frontier {model : FiniteModel}
    (catalog : StrategyCatalog model)
    (library : Library model catalog.inactiveStrategy)
    {strategy : model.StrategyId} (hstrategy : strategy ∈ library)
    (belief : model.Belief) :
    catalog.operationalProfile strategy belief ≤
      operationalFrontier catalog library belief := by
  unfold operationalFrontier
  apply Finset.le_max'
  exact Finset.mem_image.mpr ⟨strategy, hstrategy, rfl⟩

/-- The inactive zero profile gives a zero lower bound for every frontier. -/
theorem zero_le_operationalFrontier {model : FiniteModel}
    (catalog : StrategyCatalog model)
    (library : Library model catalog.inactiveStrategy)
    (belief : model.Belief) :
    0 ≤ operationalFrontier catalog library belief := by
  rw [← catalog.inactiveProfile belief]
  exact operationalProfile_le_frontier catalog library library.inactive_mem belief

/-- A finite-library strategy attains the operational frontier at each belief. -/
theorem exists_profile_eq_operationalFrontier {model : FiniteModel}
    (catalog : StrategyCatalog model)
    (library : Library model catalog.inactiveStrategy)
    (belief : model.Belief) :
    ∃ strategy ∈ library,
      catalog.operationalProfile strategy belief =
        operationalFrontier catalog library belief := by
  unfold operationalFrontier
  have hmaximum :
      (library.payoffValues catalog belief).max'
          (library.payoffValues_nonempty catalog belief) ∈
        library.payoffValues catalog belief :=
    Finset.max'_mem _ _
  rcases Finset.mem_image.mp hmaximum with ⟨strategy, hstrategy, hvalue⟩
  exact ⟨strategy, hstrategy, hvalue⟩

/-- A pointwise upper bound for all profiles is exactly a frontier upper bound. -/
theorem operationalFrontier_le_iff {model : FiniteModel}
    (catalog : StrategyCatalog model)
    (library : Library model catalog.inactiveStrategy)
    (belief : model.Belief) (bound : ℚ) :
    operationalFrontier catalog library belief ≤ bound ↔
      ∀ strategy ∈ library,
        catalog.operationalProfile strategy belief ≤ bound := by
  unfold operationalFrontier
  constructor
  · intro hbound strategy hstrategy
    exact (operationalProfile_le_frontier catalog library hstrategy belief).trans hbound
  · intro hprofiles
    apply Finset.max'_le
    intro value hvalue
    rcases Finset.mem_image.mp hvalue with ⟨strategy, hstrategy, rfl⟩
    exact hprofiles strategy hstrategy

/-- Library inclusion weakly increases the operational frontier pointwise. -/
theorem operationalFrontier_mono {model : FiniteModel}
    (catalog : StrategyCatalog model)
    {left right : Library model catalog.inactiveStrategy}
    (hinclude : left ≤ right) :
    ∀ belief,
      operationalFrontier catalog left belief ≤
        operationalFrontier catalog right belief := by
  intro belief
  apply (operationalFrontier_le_iff catalog left belief _).2
  intro strategy hstrategy
  exact operationalProfile_le_frontier catalog right (hinclude hstrategy) belief

/-- A candidate is operationally redundant when the current frontier dominates it. -/
def OperationallyRedundant {model : FiniteModel}
    (catalog : StrategyCatalog model)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId) : Prop :=
  ∀ belief,
    catalog.operationalProfile strategy belief ≤
      operationalFrontier catalog library belief

/-- Adding an operationally dominated strategy preserves the entire frontier. -/
theorem operationalFrontier_insert_of_operationallyRedundant
    {model : FiniteModel} (catalog : StrategyCatalog model)
    (library : Library model catalog.inactiveStrategy)
    (strategy : model.StrategyId)
    (hredundant : OperationallyRedundant catalog library strategy) :
    operationalFrontier catalog (library.insert strategy) =
      operationalFrontier catalog library := by
  funext belief
  apply le_antisymm
  · apply (operationalFrontier_le_iff catalog (library.insert strategy) belief _).2
    intro candidate hcandidate
    rcases (Library.mem_insert.mp hcandidate) with rfl | hmember
    · exact hredundant belief
    · exact operationalProfile_le_frontier catalog library hmember belief
  · exact operationalFrontier_mono catalog (Library.le_insert library strategy) belief

end StrategyInnovation
