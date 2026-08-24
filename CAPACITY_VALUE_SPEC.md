# Exact Capacity-Constrained Value Specification

## Verdict and status

All seven requested finite-model conclusions are valid after fixing the
capacity domain to \(B\ge 0\). The mandatory inactive-only library has burden
zero, so every such capacity admits at least one library. The resulting
capacity value is an attained, nondecreasing, right-continuous finite step
function. Its value breakpoints are a subset of the finite set of attainable
library burdens.

Diminishing marginal capacity value is false in the general model. It can
fail because weights are lumpy even when productive value is additive, and it
can fail under unit weights because modules are jointly required. Moreover,
monotone submodularity of library value alone does not restore diminishing
returns: an exact four-policy coverage example has optimal cardinality values
\((0,3,4,6,6)\).

This document states and proves theorem CAP, the planned optimization T7.
The requested finite core now has matching Lean declarations and an axiom
audit. The stronger global sorted-partition packaging, optimizer-switch
selection statement, jump-sum identity, and submodular coverage witness remain
human/Julia results unless separately identified below.
`ResourceOptimization.jl` and the registered exact rational fixtures validate
the principal finite instances. `Optimization/CapacityValue.lean`,
`CapacityCounterexample.lean`, and `CapacityDiminishingReturns.lean` supply
the verified scope stated above, with `Audit/CapacityValue.lean` as the
focused axiom/linter gate.

## 1. Exact finite setting

Fix a belief \(b\), productive parameter bundle \(\theta\), and the finite
outer-certified eligible catalog
\[
  S_\theta^{\mathrm{elig}}
\]
containing the mandatory inactive strategy \(s_0\). The primary feasible
library family is
\[
  \mathcal F
  :=
  \mathfrak L(S_\theta^{\mathrm{elig}})
  =
  \{L\subseteq S_\theta^{\mathrm{elig}}:s_0\in L\}.
\]
The theorem also applies to any separately named nonempty finite family
\(\mathcal F\) that is fixed independently of capacity and contains a
zero-burden library.

For each \(L\in\mathcal F\), write
\[
  v_L:=V_\theta(b,L)\in\mathbb Q,
  \qquad
  w_L:=W(L)\in\mathbb Q_{\ge0}.
\]
Under the adopted additive resource convention,
\[
  w_{\{s_0\}}=0
  \quad\text{and}\quad
  w_s>0\ \text{for every active strategy }s.
\]
Thus the inactive-only library
\[
  L_0:=\{s_0\}
\]
is feasible at every nonnegative capacity.

For \(B\in\mathbb Q_{\ge0}\), define the exact capacity-feasible family,
value, and complete optimizer correspondence by
\[
\begin{aligned}
  \mathcal F_B
    &:=
    \{L\in\mathcal F:w_L\le B\},\\
  V^\star(B;b,\theta)
    &:=
    \max_{L\in\mathcal F_B}v_L,\\
  \operatorname{Opt}_B(b,\theta)
    &:=
    \{L\in\mathcal F_B:v_L=V^\star(B;b,\theta)\}.
\end{aligned}
\]
Arguments \(b,\theta\) are suppressed below.

The exact model has rational inputs and rational outputs. To describe
intervals, one-sided limits, and step-function breakpoints without repeatedly
restricting to rational endpoints, use the canonical real-capacity extension
\[
  V^\star(B)
  :=
  \max\{v_L:L\in\mathcal F,\ w_L\le B\},
  \qquad B\in\mathbb R_{\ge0}.
\]
This changes only the domain of the capacity argument. It agrees with the
exact rational problem at every rational capacity and still takes values in
the finite rational set \(\{v_L:L\in\mathcal F\}\).

No sign restriction on \(v_L\), no additivity or submodularity of productive
value, and no optimizer uniqueness is needed for the seven-part theorem.
The proof uses only finiteness, finite values, and the zero-burden feasible
library. Nonnegative weights are part of the adopted resource model.

## 2. Attainable burdens and breakpoint definitions

Define the finite set of attainable burdens
\[
  \Omega
  :=
  \{w_L:L\in\mathcal F\}
  =
  \{\omega_0,\omega_1,\ldots,\omega_m\},
\]
where
\[
  0=\omega_0<\omega_1<\cdots<\omega_m.
\]
For every \(\omega\in\Omega\), define the best productive value at exactly
that burden:
\[
  \bar v(\omega)
  :=
  \max\{v_L:L\in\mathcal F,\ w_L=\omega\}.
\]
Then
\[
  \boxed{
  V^\star(B)
  =
  \max_{\omega\in\Omega:\,\omega\le B}\bar v(\omega).}
  \tag{CV}
\]

The interior capacity-value breakpoint set is
\[
  \mathcal B_C
  :=
  \left\{
    B>0:
    V^\star(B)>V^\star(B^-)
  \right\},
\]
where
\[
  V^\star(B^-):=\lim_{\varepsilon\downarrow0}V^\star(B-\varepsilon).
\]
Equivalently, an attainable burden \(\omega_i>0\) is a value breakpoint
exactly when it establishes a strict record:
\[
  \bar v(\omega_i)
  >
  \max_{0\le j<i}\bar v(\omega_j).
  \tag{record}
\]

This definition concerns jumps of the optimized value. The optimizer
correspondence can also gain a newly feasible tied library at an attainable
burden without a value jump. Such a point is an optimizer-change threshold,
but not a member of \(\mathcal B_C\). Both kinds of threshold can occur only
at attainable burdens.

## 3. The capacity-value theorem

### Theorem CAP — Finite exact capacity value

Under the setting above:

1. **Existence and attainment.** For every
   \(B\in\mathbb R_{\ge0}\),
   \[
     V^\star(B)\in\mathbb R,
     \qquad
     \operatorname{Opt}_B\ne\varnothing.
   \]
   At rational \(B\), the value and every optimizing comparison are exact
   rational quantities.

2. **Monotonicity.** Capacity value is nondecreasing:
   \[
     0\le B_1\le B_2
     \Longrightarrow
     V^\star(B_1)\le V^\star(B_2).
   \]

3. **Finite step structure.** \(V^\star\) is a right-continuous finite step
   function. Specifically, for \(0\le i<m\),
   \[
     V^\star(B)=V^\star(\omega_i)
     \quad\text{whenever}\quad
     B\in[\omega_i,\omega_{i+1}),
   \]
   and
   \[
     V^\star(B)=V^\star(\omega_m)
     \quad\text{for }B\ge\omega_m.
   \]
   Some adjacent steps may have equal heights, so not every attainable
   burden is an actual value breakpoint.

4. **Discrete shadow value.** For a declared increment \(\delta>0\), define
   \[
     \boxed{
     \Delta^\delta_B V^\star
       :=
       V^\star(B+\delta)-V^\star(B).}
   \]
   The user's notation \(\Delta_BV^\star\) abbreviates the same expression
   after \(\delta\) has been fixed. Monotonicity gives
   \[
     \Delta^\delta_BV^\star\ge0.
   \]
   It is an exact finite change, not a derivative or automatically a
   Lagrange multiplier.

5. **Finite breakpoint set.**
   \[
     \boxed{
     \mathcal B_C\subseteq\Omega\setminus\{0\},
     \qquad
     |\mathcal B_C|\le|\Omega|-1<\infty.}
   \]

6. **Discontinuous optimizer switching is possible.** At a capacity-value
   breakpoint the value jumps by definition, and every optimal-library
   selection may have to change its raw library discontinuously. The theorem
   does not assert optimizer uniqueness, continuity, or inclusion nesting.

7. **No general diminishing returns.** In general it is false that
   \[
     \Delta^\delta_{B+\delta}V^\star
     \le
     \Delta^\delta_BV^\star.
   \]
   This failure persists under unit weights.

## 4. Proof

### Part 1: existence and attainment

For every \(B\ge0\),
\[
  W(L_0)=0\le B,
\]
so \(L_0\in\mathcal F_B\). Hence \(\mathcal F_B\) is nonempty. It is a
subset of the finite family \(\mathcal F\), and every \(v_L\) is finite.
Therefore the finite nonempty set
\[
  \{v_L:L\in\mathcal F_B\}
\]
has a finite maximum and at least one maximizer. This proves both existence
of \(V^\star(B)\) and nonemptiness of \(\operatorname{Opt}_B\).

The zero-burden convention is essential to the phrase “for every
\(B\ge0\).” For a generic finite family without such a library, the same
argument begins only at
\(\min_{L\in\mathcal F}w_L\).

### Part 2: monotonicity

If \(B_1\le B_2\), then
\[
  \mathcal F_{B_1}\subseteq\mathcal F_{B_2}.
\]
Maximizing the same productive-value function over a larger feasible set
cannot lower its maximum. Therefore
\[
  V^\star(B_1)\le V^\star(B_2).
\]

### Parts 3 and 5: step structure and breakpoint containment

Fix \(i<m\) and \(B\in[\omega_i,\omega_{i+1})\). No library burden lies
strictly between \(\omega_i\) and \(\omega_{i+1}\), so
\[
  w_L\le B
  \iff
  w_L\le\omega_i.
\]
Thus
\[
  \mathcal F_B=\mathcal F_{\omega_i}
\]
throughout that half-closed interval, and \(V^\star\) is constant there. For
\(B\ge\omega_m\), every library is feasible and the value is constant on the
final ray.

At \(B=\omega_i\), all libraries of burden \(\omega_i\) are already feasible.
No further library becomes feasible immediately to its right, so the
half-closed interval convention proves right-continuity. Because feasible
sets can change only when \(B\) crosses a member of \(\Omega\), a strict
value jump can occur only at an attainable burden. This gives
\[
  \mathcal B_C\subseteq\Omega\setminus\{0\}.
\]
Finiteness and the cardinality bound follow immediately. Formula
\((\mathrm{record})\) is just formula \((\mathrm{CV})\) evaluated at the
left and right of \(\omega_i\).

### Part 4: discrete shadow value

The definition is the exact gain from relaxing the resource bound from
\(B\) to \(B+\delta\). Part 2 gives its nonnegativity. If
\[
  d(\omega):=
  V^\star(\omega)-V^\star(\omega^-)
\]
denotes the jump at a positive attainable burden, then the finite step
representation also gives
\[
  \Delta^\delta_BV^\star
  =
  \sum_{\omega\in\mathcal B_C\cap(B,B+\delta]}d(\omega).
\]
Thus the discrete shadow value aggregates exactly the capacity jumps crossed
by the increment. It can be zero even when a more distant capacity increase
has positive value.

### Part 6: an exact optimizer jump

Use one active strategy \(s\) with
\[
  w_s=2,\qquad
  V(\{s_0\})=0,\qquad
  V(\{s_0,s\})=1.
\]
For every \(0\le B<2\), the inactive-only library is the unique feasible
library and therefore the unique optimal library. At \(B=2\), the active
library becomes feasible and is uniquely optimal. Hence
\[
  V^\star(B)
  =
  \begin{cases}
    0,&0\le B<2,\\
    1,&B\ge2,
  \end{cases}
\]
and every optimizer selection switches from \(\{s_0\}\) to
\(\{s_0,s\}\) at the breakpoint. This is the registered exact fixture
CX-OPT-CAPACITY-NONCONCAVE-01.

### Part 7: exact two-module complementarity

Take two unit-weight active strategies \(s_1,s_2\). Under identity closure,
let them carry separate modules:
\[
  \operatorname{mods}(s_1)=\{m_1\},
  \qquad
  \operatorname{mods}(s_2)=\{m_2\}.
\]
All current operational profiles are zero. Let the productive opportunity
require both modules jointly and have exact net value one when both are
available. The retained-library value table is
\[
\begin{array}{c|c|c|c}
  A & C_{\{s_0\}\cup A} & W(\{s_0\}\cup A) & V(\{s_0\}\cup A)\\
  \hline
  \varnothing & \varnothing & 0 & 0\\
  \{s_1\} & \{m_1\} & 1 & 0\\
  \{s_2\} & \{m_2\} & 1 & 0\\
  \{s_1,s_2\} & \{m_1,m_2\} & 2 & 1
\end{array}
\]
Equivalently,
\[
  V(\{s_0\}\cup A)
  =
  \mathbf 1\{\{m_1,m_2\}\subseteq C_{\{s_0\}\cup A}\}.
\]
This is an exact finite module-gated opportunity: either module alone cannot
launch the productive project, while the pair can.

The capacity profile is
\[
  V^\star(0)=0,\qquad
  V^\star(1)=0,\qquad
  V^\star(2)=1.
\]
Taking \(B=0\) and \(\delta=1\),
\[
  \boxed{
  V^\star(B+2)-V^\star(B+1)
  =
  1
  >
  0
  =
  V^\star(B+1)-V^\star(B).}
\]
The second unit is valuable only because it completes the jointly required
module set. This is CX-OPT-CAPACITY-INCREASING-RETURNS-01. It proves that
equal weights and capacity monotonicity do not imply diminishing marginal
capacity value.

## 5. What “concavity” can mean in the exact model

The canonical real-capacity extension is a step function. A finite concave
real-valued function is continuous on the interior of its domain, so a
nonconstant \(V^\star\) with a positive interior jump cannot be concave as an
ordinary function on \(\mathbb R_{\ge0}\). Consequently, useful positive
shape results must refer to one of two different objects:

1. **Discrete diminishing returns on a declared grid.** For a resource unit
   \(\delta>0\), put
   \[
     D_k
     :=
     V^\star((k+1)\delta)-V^\star(k\delta).
   \]
   Lattice concavity means
   \[
     D_{k+1}\le D_k
   \]
   at every relevant integer \(k\).

2. **A convexified capacity problem.** If fractional retention or
   randomization over whole libraries is allowed, the capacity-value function
   is no longer the deterministic step function. Concavity may then be
   meaningful on the real capacity axis.

Neither interpretation is part of the unconditional theorem.

## 6. Sufficient conditions and insufficiency boundaries

### 6.1 Additive independent policy value

Suppose the active catalog is \(E\), every active strategy consumes the same
resource unit \(\delta>0\), and
\[
  W(\{s_0\}\cup A)=\delta|A|,
  \qquad
  V(\{s_0\}\cup A)=v_0+\sum_{s\in A}a_s,
  \qquad a_s\ge0.
\]
Order the increments as
\[
  a_{(1)}\ge a_{(2)}\ge\cdots\ge a_{(n)}.
\]
At budget \(k\delta\), an optimal library contains the
\(\min(k,n)\) largest increments, so
\[
  V^\star(k\delta)
  =
  v_0+\sum_{i=1}^{\min(k,n)}a_{(i)}.
\]
Therefore
\[
  D_k=
  \begin{cases}
    a_{(k+1)},&k<n,\\
    0,&k\ge n,
  \end{cases}
\]
which is weakly nonincreasing. Thus additive independent value plus equal
indivisible resource units is a clean sufficient condition for discrete
diminishing returns.

Additivity alone is not sufficient with arbitrary positive weights. A single
item of weight two and value one gives the profile \((0,0,1)\) on unit
budgets, exactly as in the optimizer-jump example above. The resulting
problem is ordinary zero-one knapsack, whose lumpy capacity profile need not
be discretely concave.

### 6.2 Submodular library value

Monotone submodularity alone is **not** sufficient, even under unit weights.
Here is an exact coverage counterexample. Let four active policies cover
subsets of the six-element universe:
\[
\begin{aligned}
  A_1&=\{1,4,6\},&
  A_2&=\{3,6\},\\
  A_3&=\{1,5\},&
  A_4&=\{2,4\}.
\end{aligned}
\]
For a selected policy set \(A\), define
\[
  f(A):=\left|\bigcup_{i\in A}A_i\right|.
\]
Coverage is normalized, monotone, and submodular. Direct enumeration gives
\[
  \max_{|A|\le k}f(A)
  =
  (0,3,4,6,6)
  \quad\text{for }k=0,1,2,3,4.
\]
Indeed, the best singleton has value three, every pair covers at most four
elements, and policies \(2,3,4\) together cover all six. The marginal
sequence is
\[
  (3,1,2,0),
\]
so the third unit has value two after the second unit had value one.

This failure does not contradict submodularity. Submodularity controls the
marginal value of adding a fixed policy to nested libraries. Capacity
optimization may switch between nonnested optimal libraries at successive
cardinalities.

A useful stronger sufficient condition is:

- value is monotone submodular;
- all active weights equal \(\delta\);
- one greedy chain \(G_0\subset G_1\subset\cdots\) is exactly optimal for
  every cardinality.

For a submodular function, the largest available greedy marginal cannot rise
as the selected set grows. If the greedy prefix \(G_k\) is an exact
cardinality-\(k\) optimizer for every \(k\), these nonincreasing greedy gains
are exactly the capacity marginals \(D_k\). Modular value and matroid-rank
value under a cardinality budget are standard subclasses with this property.
The exact-optimal-greedy condition is additional structure; it does not
follow from submodularity alone.

### 6.3 No module complementarity

The phrase “no module complementarity” is not by itself a mathematical
condition. One sufficient formal specialization is:

- identity closure;
- every active unit-cost strategy supplies one independent module;
- retaining multiple carriers of the same module adds no value;
- productive value is an additive sum of nonnegative module contributions;
  and
- no project or descendant requires a conjunction of distinct modules.

After choosing the best carrier for each module, this reduces to the additive
equal-unit model in Section 6.1, so discrete marginal capacity value is
nonincreasing.

Dropping any of the resource-regularity clauses reopens the failure. Lumpy
carrier weights reproduce zero-one-knapsack jumps. Policies that bundle
several modules can reproduce the submodular coverage counterexample.
Nonnested optimizer switching can therefore raise optimized capacity
marginals even without positive pairwise complementarity in the library-value
set function. In particular, merely excluding jointly required modules is
not sufficient for the general theorem.

### 6.4 Fractional or randomized convexification

Two extension models do yield genuine real-variable concavity:

1. With additive values and fractional retentions
   \(x_s\in[0,1]\), the fractional-knapsack value has nonincreasing slopes
   ordered by value-to-weight ratio.
2. If the decision maker may randomize over whole libraries subject to an
   expected-burden constraint, then
   \[
     \max_p
     \left\{
       \sum_Lp_Lv_L:
       \sum_Lp_Lw_L\le B,\qquad
       \sum_Lp_L=1,\qquad
       p_L\ge0
     \right\}
   \]
   is the upper boundary of the convex hull of the attainable
   \((w_L,v_L)\) points. It is finite, nondecreasing, concave, and piecewise
   affine.

Both constructions change the deterministic one-time retention problem.
They are extension results, not properties of the primary exact model.

## 7. Assumption and claim boundary

The theorem depends on:

1. A-FIN;
2. A-RESOURCE-WEIGHT, including \(W(\{s_0\})=0\);
3. A-RESOURCE-OUTER and A-OPTIMIZATION-DOMAIN;
4. A-CAPACITY-VALUE, including the fixed finite capacity-independent family
   and canonical real-capacity extension; and
5. finite productive values \(V_\theta(b,L)\).

It does **not** assume or conclude:

- ordinary concavity of the deterministic real-capacity step function;
- lattice diminishing returns without additional structure;
- submodularity of the general productive library value;
- that monotone submodularity alone suffices;
- uniqueness or raw-inclusion nesting of capacity optimizers;
- continuity of an optimal-library selection;
- support of every capacity optimum by a nonnegative resource price;
- zero Lagrangian duality gap; or
- statewise capacity enforcement after the outer retention decision.

The exact joint-capability complementarity fixture now has a Lean counterpart
proving the capacity profile `(0,0,1)` and increasing unit shadows. The
lumpy-weight fixture remains Julia validation, and the coverage construction
in Section 6.2 remains a direct finite exact calculation. The separate Lean
`AdditiveUnitCapacityProfile` verifies diminishing grid shadows for the sorted
prefix formula only; it does not imply that arbitrary capacity problems are
concave or have diminishing returns.

## 8. Human-readable proof outline

The whole theorem is driven by one finite ordered list: the attainable
library burdens. The inactive library puts zero on that list and guarantees a
feasible option at every nonnegative capacity. Between two consecutive
attainable burdens, the feasible library family cannot change, so neither can
its maximum value. At an attainable burden, new libraries enter immediately,
which gives the right-continuous step convention. A value breakpoint is
exactly an attainable burden whose best exact-burden value beats every
lower-burden record.

Increasing capacity nests feasible sets, proving monotonicity and
nonnegative finite-difference shadow values. Nothing in this nesting argument
orders successive gains. A weight-two item delays all gain until the second
unit, while two separately carried, jointly required modules make the first
unit worthless and the second valuable. Those exact examples separate
lumpiness from productive complementarity.

Positive diminishing-returns results require stronger structure. Additive
value with equal unit weights sorts independent increments and therefore
sorts capacity marginals downward. Arbitrary weights destroy that argument.
Submodularity controls additions along a fixed nested path, but the exact
coverage example shows that globally optimal paths can switch and generate an
increasing capacity marginal. Submodularity becomes sufficient when an
exactly optimal greedy chain exists at every cardinality. Genuine concavity
on the real capacity axis requires convexifying the indivisible choice, for
example through fractional retention or randomized libraries.
