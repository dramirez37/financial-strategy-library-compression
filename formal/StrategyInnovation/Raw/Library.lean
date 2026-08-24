import StrategyInnovation.Library.Library
import StrategyInnovation.Raw.StrategyCatalog

/-!
# Raw libraries

An admissible raw library is a finite set of catalog identifiers containing
the inactive strategy.  The alias deliberately reuses the verified library
implementation, including set-valued insertion and noninactive deletion.
-/

namespace StrategyInnovation.Raw

/-- An inactive-containing finite raw strategy library. -/
abbrev Library {model : FiniteModel} (catalog : Raw.StrategyCatalog model) :=
  StrategyInnovation.Library model catalog.inactiveStrategy

end StrategyInnovation.Raw
