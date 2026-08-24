import StrategyInnovation.Library.Strategy

/-!
# Raw strategy catalog

The raw model uses the immutable exact catalog already verified by the
finite-library foundation.  This module gives that object an explicit raw-layer
name without duplicating its data or weakening its inactive-strategy
certificates.
-/

namespace StrategyInnovation.Raw

/-- The raw strategy catalog is the existing exact finite strategy catalog. -/
abbrev StrategyCatalog (model : FiniteModel) :=
  StrategyInnovation.StrategyCatalog model

end StrategyInnovation.Raw
