# Value

`FiniteHorizon.lean` defines the exact finite-state Bellman calculus. It
provides finite belief, compressed-state, project, and action spaces; exact
rational transition laws, rewards, costs, discounting, and project delays;
expectation and Bellman monotonicity; cost-sensitive dynamic-innovation value
preservation; uniform finite-horizon boundedness; compressed-state
factorization; and existence of an optimal finite action.

The horizon counts decision epochs. A project delay `d` discounts completion
by `β^(d+1)` rather than introducing an infinite series or a second recursion
index.

`Decomposition.lean` adapts raw finite libraries to that process, defines the
frozen-library passive value, full value, research-option premium, and total,
operational, and generative innovation of a strategy insertion. The exact
accounting decomposition is unconditional. Closure sufficiency and positive
monotonicity conclusions use separately named factorization and stochastic
candidate-generation assumptions.

`InnovationEquation.lean` proves that passive operational innovation from one
candidate is the exact expected discounted finite sum of its positive frontier
gap along the belief kernel. It also provides a reachable-state zero criterion,
diminishing marginal operational innovation under library inclusion, and an
exact example with zero current gap but positive value at a reachable future
belief.

`UnifiedDecomposition.lean` is the publication-facing T5 layer. It defines
frozen-library passive value and T1's unified full raw/compressed value,
research-option premium, and total, operational, and generative insertion
values. It proves the exact decomposition, both silent-insertion results,
diminishing fixed-candidate operational insertion value under raw-library
inclusion, premium monotonicity under an explicit closure-enrichment/project-
dominance certificate, and an exact raw bridge with zero operational but
strictly positive generative insertion value.

`MIGRATION.md` records how the older F6/F7 names relate to the unified T5
interface. They remain compiled supporting declarations; none is an alias.

`GenerativeLowerBound.lean` proves T6's retained-carrier lower bound from the
raw generator, admission law, and unified completion timing.

`ComparativeStatics.lean` proves one-way finite comparative statics for
frontiers, operational saturation, research costs, admission, survival,
elapsed project duration, closure dominance, and exact finite action regions.
Its delay theorem includes the required no-waiting-gain inequality for
continued operation, and its exact counterexamples show why the omitted
assumptions cannot be dropped.

`SystemInteraction.lean` is the publication-facing T7 layer. It defines the
closure value increment and frontier--closure cross difference on T1's
realizable compressed carrier. The corrected theorem derives substitution
from primitive frontier independence, closure-menu expansion, and an explicit
relative Bellman-action saturation condition. Exact rational examples show
strict substitution, frontier-dependent-success complementarity, separability,
and why individual candidate saturation does not imply the optimized sign.
