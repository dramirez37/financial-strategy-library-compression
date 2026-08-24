import StrategyInnovation.Raw.AdmittedCandidate
import StrategyInnovation.Raw.Library

/-!
# Raw library updates

The admitted outcome is applied directly to the set-valued raw library.
Failure is the identity and success inserts the catalog identifier.
-/

namespace StrategyInnovation.Raw

variable {model : FiniteModel} {catalog : Raw.StrategyCatalog model}

/-- Update a raw library with one admitted candidate outcome. -/
def rawLibraryUpdate (library : Raw.Library catalog) :
    Raw.CandidateOutcome model → Raw.Library catalog
  | none => library
  | some strategy => library.insert strategy

/-- Failed generation or verification leaves the raw library unchanged. -/
@[simp]
theorem rawLibraryUpdate_none (library : Raw.Library catalog) :
    rawLibraryUpdate library none = library :=
  rfl

/-- Successful admission inserts the verified candidate identifier. -/
@[simp]
theorem rawLibraryUpdate_some (library : Raw.Library catalog)
    (strategy : model.StrategyId) :
    rawLibraryUpdate library (some strategy) = library.insert strategy :=
  rfl

end StrategyInnovation.Raw
