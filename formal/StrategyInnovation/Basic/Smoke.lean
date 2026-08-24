import Mathlib.Data.Nat.Basic

namespace StrategyInnovation

/-- Infrastructure-only smoke theorem for the pinned Lean/mathlib environment. -/
theorem smokeNatAddZero (n : ℕ) : n + 0 = n := by
  rfl

#print axioms StrategyInnovation.smokeNatAddZero

end StrategyInnovation
