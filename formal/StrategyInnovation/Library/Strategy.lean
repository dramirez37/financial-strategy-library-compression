import StrategyInnovation.Basic.Model
import Mathlib.Data.Rat.Defs

/-!
# Exact strategy catalogs

Strategies have exact rational operational profiles and finite module sets.
The distinguished inactive strategy is always available, pays zero at every
belief, and supplies no generative module.
-/

namespace StrategyInnovation

/-- An exact operational payoff table indexed by strategy and belief. -/
abbrev OperationalProfile (model : FiniteModel) :=
  model.StrategyId → model.Belief → ℚ

/-- A finite module table indexed by strategy. -/
abbrev StrategyModules (model : FiniteModel) :=
  model.StrategyId → Finset model.ModuleId

/--
Immutable strategy data for a finite model.

The two proof fields make the inactive identifier a genuine zero strategy
rather than a default value used only to totalize a maximum.
-/
structure StrategyCatalog (model : FiniteModel) where
  operationalProfile : OperationalProfile model
  strategyModules : StrategyModules model
  inactiveStrategy : model.StrategyId
  inactiveProfile : ∀ belief, operationalProfile inactiveStrategy belief = 0
  inactiveModules : strategyModules inactiveStrategy = ∅

namespace StrategyCatalog

variable {model : FiniteModel} (catalog : StrategyCatalog model)

/-- The exact operational profile is rational-valued at every belief. -/
abbrev profile : model.StrategyId → model.Belief → ℚ :=
  catalog.operationalProfile

/-- The finite module set attached to a strategy identifier. -/
abbrev modules : model.StrategyId → Finset model.ModuleId :=
  catalog.strategyModules

end StrategyCatalog

end StrategyInnovation
