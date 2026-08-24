import Mathlib.Data.Int.Basic

namespace StrategyInnovation.Fixtures.TheoremFeasibility

/-- Exact rational datum represented as numerator and positive denominator. -/
structure QDatum where
  num : Int
  den : Nat
  deriving Repr, DecidableEq

/-- Data-only witness to be mapped into the future formal model. -/
structure ExactFixture where
  id : String
  theoremId : String
  beliefCount : Nat
  strategyCount : Nat
  moduleCount : Nat
  projectCount : Nat
  rationalData : List QDatum
  maskData : List Nat
  expectedFacts : List String
  deriving Repr, DecidableEq

def rawLibraryDependence : ExactFixture where
  id := "CX-T1-RAW-01"
  theoremId := "T1-boundary"
  beliefCount := 1
  strategyCount := 3
  moduleCount := 1
  projectCount := 1
  rationalData := [⟨0, 1⟩, ⟨-1, 1⟩, ⟨1, 1⟩, ⟨1, 2⟩]
  maskData := [1, 3]
  expectedFacts := ["equal frontier", "equal closure", "different value"]

def silentModule : ExactFixture where
  id := "CX-T1-MIN-T2-SILENT-01"
  theoremId := "T1-minimality/T2-converse"
  beliefCount := 1
  strategyCount := 2
  moduleCount := 1
  projectCount := 1
  rationalData := [⟨0, 1⟩, ⟨-1, 1⟩, ⟨1, 2⟩]
  maskData := [1, 3, 0, 1]
  expectedFacts := ["equal frontier", "different closure", "equal signature", "equal value"]

def batchDeletion : ExactFixture where
  id := "CX-T3-BATCH-01"
  theoremId := "T3-batch-extension"
  beliefCount := 1
  strategyCount := 3
  moduleCount := 1
  projectCount := 1
  rationalData := [⟨0, 1⟩, ⟨-1, 1⟩, ⟨-1, 1⟩]
  maskData := [7, 5, 3, 1]
  expectedFacts := ["each single deletion safe", "joint deletion changes K"]

def frontierLoss : ExactFixture where
  id := "CX-T4-BRIDGE-01"
  theoremId := "T4"
  beliefCount := 1
  strategyCount := 3
  moduleCount := 1
  projectCount := 1
  rationalData := [⟨0, 1⟩, ⟨0, 1⟩, ⟨1, 1⟩, ⟨120, 121⟩, ⟨5, 1⟩]
  maskData := [3, 1, 12]
  expectedFacts := ["frontier preserved", "closure changed", "loss greater than five"]

def valueSeparability : ExactFixture where
  id := "CX-T5-SEPARABILITY-01"
  theoremId := "T5-extension"
  beliefCount := 1
  strategyCount := 2
  moduleCount := 1
  projectCount := 1
  rationalData := [⟨1, 2⟩, ⟨1, 1⟩, ⟨2, 1⟩]
  maskData := [1]
  expectedFacts := ["same initial frontier", "same closure", "different innovation premium"]

def disconnectedCoverage : ExactFixture where
  id := "CX-T6-DISCONNECTED-01"
  theoremId := "T6-extension"
  beliefCount := 3
  strategyCount := 2
  moduleCount := 1
  projectCount := 1
  rationalData := [⟨1, 2⟩, ⟨0, 1⟩, ⟨1, 1⟩, ⟨0, 1⟩]
  maskData := [1, 0, 1]
  expectedFacts := ["coverage region is beliefs one and three", "coverage formula still exact"]

def multiGapAdditivity : ExactFixture where
  id := "CX-MULTIGAP-ADDITIVITY-01"
  theoremId := "optional-multi-gap"
  beliefCount := 1
  strategyCount := 3
  moduleCount := 1
  projectCount := 2
  rationalData := [⟨1, 2⟩, ⟨1, 4⟩, ⟨0, 1⟩, ⟨0, 1⟩]
  maskData := [1]
  expectedFacts := ["joint premium positive", "isolated component premia zero"]

def all : List ExactFixture :=
  [rawLibraryDependence, silentModule, batchDeletion, frontierLoss,
   valueSeparability, disconnectedCoverage, multiGapAdditivity]

end StrategyInnovation.Fixtures.TheoremFeasibility
