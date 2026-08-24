import StrategyInnovation.Bellman.Unified
import StrategyInnovation.Value.GenerativeLowerBound

/-!
# Exact unified Bellman fixture

This fixture instantiates the general stationary-selector and policy-evaluation
theorems on the one-belief, positive-duration raw carrier used by T6.  Julia's
paired fixture computes the selected actions and exact values; the declarations
here check that the same raw model is covered by the kernel-verified theorem.
-/

namespace StrategyInnovation

namespace Projection

namespace Model

namespace UnifiedBellmanFixture

open GenerativeLowerBound.CarrierExample
open StrategyInnovation.FrontierPruningLoss

/-- The fixture uses the unified one-calendar-period research duration. -/
theorem projectDuration_eq_one :
    process.duration Project.innovate = 1 :=
  rfl

/-- The fixture's exact discount is one half. -/
theorem discount_eq_one_half :
    process.discount = 1 / 2 :=
  rfl

/-- The finite raw and compressed fixture recursions agree at every horizon. -/
theorem rawCompressedFiniteValue_eq
    (horizon : Nat) (library : Raw.Library (exampleCatalog 2)) :
    process.rawValue horizon Belief.only library =
      process.compressedValue horizon Belief.only
        (CompressedLibraryState.ofLibrary
          (exampleCatalog 2) exampleClosure library) :=
  process.finiteHorizon_rawValue_eq_compressedValue horizon Belief.only library

/-- The fixture's raw and compressed infinite-horizon values agree. -/
theorem rawCompressedInfiniteValue_eq
    (library : Raw.Library (exampleCatalog 2)) :
    process.rawInfiniteHorizonValue (Belief.only, library) =
      process.infiniteHorizonValue
        (Belief.only, CompressedLibraryState.ofLibrary
          (exampleCatalog 2) exampleClosure library) :=
  process.rawInfiniteHorizonValue_eq_compressed Belief.only library

/-- The exact fixture selector satisfies its policy-evaluation equation. -/
theorem stationarySelector_policyEvaluationEquation :
    Function.IsFixedPt
      (process.policyOperator process.stationaryOptimalSelector)
      process.infiniteHorizonValue :=
  process.stationaryOptimalSelector_policyEvaluationEquation

/-- The exact fixture policy value is the optimal Bellman value. -/
theorem stationarySelector_value_eq :
    process.stationaryPolicyValue process.stationaryOptimalSelector =
      process.infiniteHorizonValue :=
  process.stationaryOptimalSelector_value_eq_infiniteHorizonValue

end UnifiedBellmanFixture

end Model

end Projection

end StrategyInnovation
