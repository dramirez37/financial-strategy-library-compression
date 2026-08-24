import StrategyInnovation.Raw.StrategyCatalog

/-!
# Raw module sets

All module collections in the raw model are finite sets over the model's fixed
finite module carrier.
-/

namespace StrategyInnovation.Raw

/-- A finite set of generative modules. -/
abbrev ModuleSet (model : FiniteModel) := Finset model.ModuleId

/-- The immutable raw module row of each strategy. -/
abbrev StrategyModuleSets (model : FiniteModel) :=
  model.StrategyId → Raw.ModuleSet model

end StrategyInnovation.Raw
