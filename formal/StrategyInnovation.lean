import StrategyInnovation.Basic
import StrategyInnovation.Bellman.Contraction
import StrategyInnovation.Bellman.Unified
import StrategyInnovation.Compression.SafeDeletion
import StrategyInnovation.Compression.UnifiedSafeDeletion
import StrategyInnovation.Compression.UnifiedSafeDeletionExamples
import StrategyInnovation.Compression.NormalizedPruningLoss
import StrategyInnovation.Compression.BridgeMarginElasticity
import StrategyInnovation.Counterexamples.FrontierPruningLoss
import StrategyInnovation.Counterexamples.MultiGapRegion
import StrategyInnovation.Coverage.Potential
import StrategyInnovation.Coverage.DiscountSurvivalInteraction
import StrategyInnovation.Coverage.KernelComparativeStatics
import StrategyInnovation.Coverage.InnovationDuration
import StrategyInnovation.Coverage.SingleGap
import StrategyInnovation.Fixtures.Generated
import StrategyInnovation.Fixtures.TheoremFeasibility
import StrategyInnovation.Fixtures.UnifiedBellman
import StrategyInnovation.Fixtures.UnifiedCanonical
import StrategyInnovation.Interaction.PrimitiveSubstitution
import StrategyInnovation.Library
import StrategyInnovation.Optimization.Capacity
import StrategyInnovation.Optimization.CapacityCounterexample
import StrategyInnovation.Optimization.CapacityDiminishingReturns
import StrategyInnovation.Optimization.CapacityValue
import StrategyInnovation.Optimization.Elasticity
import StrategyInnovation.Optimization.PenalizedEnvelope
import StrategyInnovation.Optimization.SafeCompressionCounterexample
import StrategyInnovation.Projection
import StrategyInnovation.Quotient.DynamicInnovation
import StrategyInnovation.Quotient.FrontierClosure
import StrategyInnovation.Quotient.UnifiedDynamicInnovation
import StrategyInnovation.Quotient.RawFrontierClosure
import StrategyInnovation.Raw
import StrategyInnovation.Value.Decomposition
import StrategyInnovation.Value.FiniteHorizon
import StrategyInnovation.Value.InnovationEquation
import StrategyInnovation.Value.UnifiedDecomposition
import StrategyInnovation.Value.GenerativeLowerBound
import StrategyInnovation.Value.JointDescendantLowerBound
import StrategyInnovation.Value.ComparativeStatics
import StrategyInnovation.Value.ChannelElasticity
import StrategyInnovation.Value.SystemInteraction

/-!
# StrategyInnovation

Root module for the formal library.  The finite-library, abstract dynamic
innovation, modular frontier--closure, unified raw safe-deletion, and sharp
frontier-pruning-loss layers are kernel checked; the theorem-feasibility
fixture contains exact data only. The exact finite-state Bellman calculus is
also kernel checked, together with its exact value decomposition and its
discounted real-valued contraction extension. The exact finite-grid
coverage-potential representation, the finite monotone single-gap
upper-threshold result, the kernel-alignment comparative static, and the exact
multi-gap disconnected-region
counterexample are also kernel checked. The exact raw generation, admission,
local update, and T1 controlled semi-Markov projection are derived without
changing the primitive transition layer. Supporting results F1--F8 and
S4--S7 and C2 remain distinct from the primary T1 result. Publication-facing
dynamic innovation equivalence uses the unified cost-sensitive raw model; the
raw T2 theorem characterizes it by frontier--closure equality under observable
raw closure detectability. T3 makes rechecked operational-plus-generative
redundancy exactly innovation-safe under that detectability condition and
derives finite/infinite value and optimal-action preservation from T1. The
raw T4 construction derives descendant mass from its survival-gated generator
and admission row, then proves the exact normalized cost-sensitive loss, cap,
ratio, scaling boundary, and continued-operation adjustment. T5 defines
frozen-library passive value and unified full raw value, proves their
raw-to-compressed projections and the exact operational--generative insertion
decomposition, and records the precise dominance boundary for premium
monotonicity. The
retained-carrier T6 theorem derives its survival--admission event from the raw
generator under explicit conditional independence, exposes the exact unified
operating-timing adjustment, proves the finite occupation form and comparative
statics, and supplies an exact raw carrier example. The finite comparative-
statics module proves sign-definite frontier, cost, admission, survival, delay,
closure, and action-region results under explicit one-way assumptions and
records exact failures outside them. The finite discount--survival interaction
module proves exact matrix-power identities, monotonicity, and supermodular
cross differences without real differentiation. The kernel-comparative-static
module proves that scalar persistence has no universal sign and derives the
positive result from discounted occupation aligned with the gap. T7 defines
the frontier--closure cross difference on the unified compressed value and
proves substitution under explicit relative Bellman-action saturation. Exact
examples record strict substitution, frontier-dependent-success
complementarity, zero interaction, and the project-switching failure of the
weaker frontier-independence-only claim. The primitive interaction module
derives the common descendant-gap order by finite-horizon induction under the
process's fixed belief kernel and then applies the unchanged T7 finite-max
theorem. The
unified Bellman module derives raw and compressed contractions from T1,
proves unique infinite-horizon value and geometric value iteration, and
formalizes a stationary maximizing selector together with its compressed and
lifted-raw policy-evaluation equations. Its raw-derived canonical fixture
kernel-checks the full six-state rational law, value/action table, policy
evaluation, zero residual, and strict action margins. The
older cost-free primitive equivalence and abstract safe-deletion theorem remain
a deprecated supporting layer. The outer optimization foundation now adds
exact strategy resource weights, additive library burden, nonnegative rational
budgets, source-relative exact safe-compression feasibility, strict burden
reduction under certified active deletion, finite minimum attainment, and a
resource-layer wrapper for productive dynamic-value preservation. Penalized
optimization now has a fixed finite-family real affine-envelope layer with
attainment, continuity, convexity, nonincrease, finite switching candidates,
local slopes—including directly away from the actual non-locally-affine
breakpoint set—and antitone optimal burden. The real elasticity layer verifies
positive bridge-loss derivatives and normalized-margin blow-up, finite-sum
innovation duration and timing-variance convexity, and operational--generative
derivative/contribution decompositions with exact examples. Active-face
one-sided formulas and broader switching elasticity remain downstream. The finite
capacity layer now defines the attained hard-budget maximum, proves
monotonicity, half-open constancy cells and finite attainable-burden
breakpoints, and records exact discrete shadows. A joint-capability example
kernel-checks increasing marginal capacity value; additive equal-unit
diminishing grid returns are isolated in a separate sufficient-condition
module and are not attributed to the general model.
-/
