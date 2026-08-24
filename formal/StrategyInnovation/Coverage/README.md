# Coverage

`Potential.lean` formalizes the exact finite-grid coverage-potential
representation for a declared one-shot gross operational research model. It
uses a nonempty finite linearly ordered belief type, exact rational certified
gaps, and finite time-indexed occupation weights. The file proves the
representation identity, monotonicity, reachable-support zero value, regional
and global bounds, delayed positive coverage, and antitonicity under an
improved existing frontier.

`DiscountSurvivalInteraction.lean` specializes finite occupation to an exact
row-stochastic matrix. It identifies the truncated resolvent applied to a
nonnegative gap, proves monotonicity in discount and survival, factors their
finite cross difference date by date, and derives complementarity without
real differentiation. A one-state exact example shows why gap nonnegativity
is essential.

`KernelComparativeStatics.lean` proves that regime persistence has no
universal coverage sign. It supplies exact raising, lowering, and invariant
two-state witnesses, defines the gap-tailored discounted-occupation order, and
derives the positive comparison from occupation dominance on every
positive-gap state.

`SingleGap.lean` defines finite-grid interval support, single-peakedness,
ordered quasi-concavity, and upper-level-set connectedness. It proves their
basic implications and the monotone-gap upper-threshold theorem: an
increasing nonnegative gap under a first-order stochastically monotone finite
kernel, increasing nonnegative survival, nonnegative discount, and antitone
cost has increasing gross value and an empty-or-upper-threshold one-shot
cost-covering set. This set is not identified with the optimal Bellman
research region. Exact three-state Lean counterexamples show why
single-peakedness alone and unrestricted costs do not imply connected
coverage. `MIGRATION.md` records the retained legacy declaration names.

The model is gross and operational: it does not subtract project cost or model
generation/admission. It therefore does not establish T6's retained-carrier
descendant bound, which is proved separately from the raw process in
`Value/GenerativeLowerBound.lean`.
