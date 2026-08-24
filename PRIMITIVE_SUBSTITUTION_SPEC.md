# Primitive Sufficient Conditions for Frontier--Closure Substitution

## Verdict

The broad proposed subclass is false as a route to the current all-pairs
definition of relative action saturation. Frontier-independent primitives,
menu inclusion, a fixed descendant profile, individual project saturation,
and even an added-project exposure at least as large as the incumbent
project's do not control the pair consisting of rich-menu Continue and a
frontier-sensitive poor-menu project.

The narrow surviving subclass is:

> **Fixed-continuation common-gap expansion with zero poor-menu exposure.**
> Every action value has a frontier-independent intercept plus exposure to one
> common descendant gap; the gap weakly shrinks with the frontier; rich-menu
> exposures are nonnegative; every feasible poor-menu action has zero exposure;
> primitives are frontier independent; and the rich menu contains the poor
> menu.

Continue-only at the poor closure is the leading economic case. More
generally, the poor menu may contain projects with fixed payoffs, provided
they do not load on the descendant improvement gap.

This subclass is narrow for a structural reason. Continue is always feasible
and has zero descendant-gap exposure. If the common gap strictly shrinks and a
poor action has positive exposure, the rich-menu Continue action gains
relative to that poor action. The current all-pairs relative-saturation
condition therefore fails. Within the common-gap/nonnegative-exposure class,
zero poor-menu exposure is not merely convenient; it is the sharp restriction
forced by the all-pairs definition.

The general Theorem 6.12 remains unchanged. The primitive result is a
sufficient-condition corollary that supplies its relative-saturation premise.
The optimizer-switching complementarity example remains unchanged and lies
outside the subclass.

## 1. Exact finite falsification before proof

The versioned exact search
`primitive-substitution-search-v1` evaluates the same 2,430 rational
one-period rows as the existing system-interaction surface:

- six frontiers \(0,2,4,6,8,10\);
- every strict ordered frontier pair;
- common descendant payoffs \(4\) and \(10\);
- incumbent and added success probabilities \(0,1/2,1\);
- incumbent and added costs \(0,1,2\); and
- discount \(1/2\).

For frontier \(F_i\), define the common gap
\[
  g_i=(Y-F_i)_+.
\]
An action with intercept \(\eta\) and exposure \(\lambda\) has return
\[
  R_i=\eta+\lambda g_i.
\]
Continue has \((\eta,\lambda)=(0,0)\). A project with cost \(\kappa\) and
success \(\pi\) has
\[
  (\eta,\lambda)=(-\kappa,\beta\pi).
\]

The poor menu contains Continue and one incumbent project. The rich menu
retains both and adds one project. The search checks every rich/poor action
pair, not only the optimized values.

### Search result

| Diagnostic | Exact count |
|---|---:|
| all rows | 2,430 |
| rows satisfying all-pairs relative saturation | 1,134 |
| rows with added exposure at least incumbent exposure | 1,620 |
| failures within that broader exposure order | 648 |
| rows with zero poor-project exposure and nonnegative rich exposures | 810 |
| failures in the adopted primitive class | 0 |
| substitute / separable / complement rows | 553 / 1,865 / 12 |

This search does not prove the proposition. It falsifies the broader candidate,
checks the exact theorem fixtures, and validates the implementation against
the Lean arithmetic.

### Minimal broader-class failure

Take
\[
  \beta=\frac12,\qquad
  (F_0,F_1)=(0,8),\qquad
  Y=10,
\]
and let both the incumbent and added projects have success one and cost zero.
The added exposure equals the incumbent exposure, so the proposed project
exposure order holds. For rich-menu Continue \(a_1\) and the poor incumbent
project \(a_0\),
\[
\begin{aligned}
 Q(F_1,C_1,a_1)-Q(F_1,C_0,a_0)&=-1,\\
 Q(F_0,C_1,a_1)-Q(F_0,C_0,a_0)&=-5.
\end{aligned}
\]
Relative saturation would require \(-1\le-5\), which is false. Optimized
interaction is nevertheless zero in this example. The failure concerns the
all-pairs premise, not the optimized sign.

The exact Lean theorem
`Examples.added_exposure_order_insufficient_for_allPairs` records the reduced
arithmetic boundary. The exact Julia search finds 648 such failures.

### Preserved optimizer-switching complementarity

The existing fixture remains:
\[
  (F_0,F_1)=(0,8),\quad Y=10,\quad\beta=\frac12,
\]
with incumbent \((\pi,\kappa)=(1,2)\) and added
\((\pi,\kappa)=(1/2,0)\). Its closure increments remain
\[
  0,\quad \frac12,
\]
so \(J=1/2\). The new search reproduces this exact row and requires its
classification to remain complementarity.

## 2. Adopted primitive subclass

Fix a belief and a finite Bellman node. For
\[
  i\in\{0,1\},\qquad j\in\{0,1\},
\]
let \(i\) index the low/high frontier and \(j\) the poor/rich closure.
Assume the exact action values have the common-gap representation
\[
\begin{aligned}
 Q_h(F_i,C_1,a)
   &=B_{h,i}+\eta^1_{h,a}+\lambda^1_{h,a}g_{h,i},\\
 Q_h(F_i,C_0,a)
   &=B_{h,i}+\eta^0_{h,a}+\lambda^0_{h,a}g_{h,i}.
\end{aligned}
\tag{CG}
\]
The components have the following primitive interpretation.

| Component | Interpretation |
|---|---|
| \(B_{h,i}\) | incumbent operating value and every continuation component common across closures at frontier \(F_i\) |
| \(\eta^j_{h,a}\) | frontier-independent project cost, fixed operating/timing adjustment, and fixed-continuation intercept |
| \(\lambda^j_{h,a}\) | discounted exposure to the admitted fixed descendant; e.g. \(\beta^d\rho^d\pi\) in the product specialization |
| \(g_{h,i}\) | common positive-part value gap generated by the fixed descendant profile |

The adopted assumptions are:

1. the four compressed states form the existing realizable ordered rectangle;
2. project availability, cost, duration, operation, and complete completion law
   are frontier independent;
3. the rich closure contains every poor-menu project;
4. the fixed-continuation representation (CG) holds at every finite node and
   belief with the same intercept and exposure for each action across the two
   frontiers;
5. \(g_{h,1}\le g_{h,0}\);
6. \(\lambda^1_{h,a}\ge0\) for every rich action; and
7. \(\lambda^0_{h,a}=0\) for every feasible poor action.

Assumption 4 is the exact decreasing-differences preservation restriction. It
is automatic in a terminal one-decision model with a single fixed descendant.
At longer horizons it defines the fixed-continuation subclass: the continuation
term must preserve the same common-gap form. The paper does not claim that an
arbitrary closure-dependent optimized continuation kernel has this property.

### Recursion-stable transition specialization

The preservation restriction now has a transition-level sufficient
condition. Let the low- and high-frontier common gaps use the process's same
belief kernel \(P\) and nonnegative discount \(\beta\):
\[
\begin{aligned}
 g_{0,i}(b)&=\bar g_i(b),\\
 g_{h+1,i}(b)
   &=s_i(b)+\beta\sum_{b'}P(b,b')g_{h,i}(b'),
 \qquad i\in\{0,1\}.
\end{aligned}
\]
Assume pointwise terminal and flow saturation,
\(\bar g_1\le\bar g_0\) and \(s_1\le s_0\). Because \(P\) is a rational
probability kernel, its masses are nonnegative. Finite-horizon induction
therefore gives
\[
  g_{h,1}(b)\le g_{h,0}(b)
\]
for every horizon and belief. This is the canonical fixed-transition,
single-descendant subclass formalized in
`StrategyInnovation/Interaction/PrimitiveSubstitution.lean`.

The result does not move the optimized continuation inside the gap recursion.
It proves preservation for the explicitly stated fixed kernel; arbitrary
action-dependent successor closures remain outside the theorem.

## 3. Proposition and proof

### Primitive common-gap frontier saturation

Under assumptions 1--7, relative action saturation holds:
\[
 Q_h(F_1,C_1,a_1)-Q_h(F_1,C_0,a_0)
 \le
 Q_h(F_0,C_1,a_1)-Q_h(F_0,C_0,a_0)
\]
for every rich feasible action \(a_1\) and poor feasible action \(a_0\).
Consequently Theorem 6.12 gives
\[
 [V_h(F_1,C_1)-V_h(F_1,C_0)]
 \le
 [V_h(F_0,C_1)-V_h(F_0,C_0)].
\]

### Proof

First, the recursion-stable specialization preserves the gap order. At horizon
zero this is the terminal order. If it holds at horizon \(h\), expectation
under the common nonnegative kernel preserves it; multiplication by
\(\beta\ge0\) and addition of the ordered gap flow preserve it at horizon
\(h+1\).

Next substitute (CG). The frontier-specific base cancels within each action
difference. Zero poor exposure removes its gap term. The change in relative
advantage from the low to the high frontier is exactly
\[
  \lambda^1_{h,a_1}(g_{h,1}-g_{h,0})\le0.
\]
This is relative action saturation. Theorem 6.12 then passes the inequality
through the finite Bellman maxima.

The Lean declaration
`relativeActionSaturation_of_commonGap` proves the first implication.
`relativeActionSaturation_of_primitiveSaturation` states that implication from
the complete primitive package, including frontier-independent primitives and
menu inclusion; its proof makes clear that the common-gap preservation
certificate is the sign-bearing part.
`compressedInteractionCrossDifference_nonpositive_of_primitiveSaturation`
constructs the existing T7 assumption package and invokes the unchanged
general theorem.

## 4. Sharpness inside the common-gap class

Suppose \(g_{h,1}<g_{h,0}\), all exposures are nonnegative, and Continue has
zero exposure.

- Comparing any rich action with poor Continue requires the rich exposure to
  be nonnegative.
- Comparing rich Continue with any poor action requires that poor action's
  exposure be nonpositive.
- Nonnegative poor exposures therefore must equal zero.

Thus the sign restrictions used by the proposition are the narrowest possible
uniform restrictions within this common-gap class if the paper retains the
current all-pairs definition of relative action saturation. A weaker
selected-optimizer or added-versus-incumbent comparison could admit broader
classes, but it would be a different assumption and a different theorem
interface.

## 5. Lean correspondence

| Mathematical object | Lean declaration |
|---|---|
| common-gap action-value representation | `CommonGapActionDecomposition` |
| primitive representation implies relative saturation | `relativeActionSaturation_of_commonGap` |
| rectangle, primitive independence, menu inclusion, and common-gap certificate | `PrimitiveSubstitutionAssumptions` |
| full primitive package implies relative saturation | `relativeActionSaturation_of_primitiveSaturation` |
| adapter to unchanged T7 | `PrimitiveSubstitutionAssumptions.toSubstitutionAssumptions` |
| primitive substitution corollary | `compressedInteractionCrossDifference_nonpositive_of_primitiveSaturation` |
| broader exposure-order boundary | `Examples.added_exposure_order_insufficient_for_allPairs` |
| fixed-kernel descendant-gap recursion | `Interaction.PrimitiveSubstitution.recursiveGapValue` |
| finite-horizon preservation induction | `Interaction.PrimitiveSubstitution.recursiveGapValue_antitone` |
| recursive action-value certificate | `Interaction.PrimitiveSubstitution.RecursiveCommonGapActionDecomposition` |
| recursive certificate implies relative saturation | `Interaction.PrimitiveSubstitution.recursive_primitives_imply_relativeActionSaturation` |
| canonical primitive assumption package | `Interaction.PrimitiveSubstitution.CanonicalPrimitiveSubstitutionAssumptions` |
| canonical finite-horizon substitution theorem | `Interaction.PrimitiveSubstitution.canonical_frontier_closure_substitutes` |
| project-switching complementarity boundary | `Interaction.PrimitiveSubstitution.Examples.project_switching_complementarity_outside_primitive_subclass` |
| frontier-dependent-success complementarity | `Interaction.PrimitiveSubstitution.Examples.frontier_dependent_success_complementarity_exact` |
| separable zero interaction | `Interaction.PrimitiveSubstitution.Examples.separable_zero_interaction_exact` |

The general T7 declarations live in
`formal/StrategyInnovation/Value/SystemInteraction.lean`. The transition-level
specialization lives in
`formal/StrategyInnovation/Interaction/PrimitiveSubstitution.lean`. Its
focused audit is
`formal/StrategyInnovation/Audit/PrimitiveSubstitution.lean`.

## 6. Exact Julia fixtures

- Configuration:
  `experiments/configs/primitive_substitution_search.toml`
- Producer:
  `julia/scripts/search_primitive_substitution.jl`
- Tests:
  `julia/test/test_primitive_substitution.jl`
- Complete exact rows:
  `experiments/results/summaries/primitive_substitution_search.csv`
- Machine-readable summary:
  `experiments/results/summaries/primitive_substitution_summary.json`

The nonmutating drift check is:

```sh
julia --project=julia julia/scripts/search_primitive_substitution.jl --check
```

The fixtures are computational validation and counterexample evidence. The
general implication is a Lean theorem.

## 7. Claim boundary

- The general relative-saturation Theorem 6.12 is retained unchanged.
- The primitive result is sufficient, not necessary, outside the common-gap
  class.
- No claim is made for arbitrary action-dependent successor closures.
- No claim is made that menu inclusion alone preserves the payoffs of retained
  projects.
- The 648 broader-class failures and the 12 complement rows remain visible.
- The optimizer-switching complementarity fixture remains registered with
  \(J=1/2\).
- Frontier-dependent success remains a separate economic complementarity
  mechanism.
