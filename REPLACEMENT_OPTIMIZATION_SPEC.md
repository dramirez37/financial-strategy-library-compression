# Capacity-Constrained Replacement Optimization Specification

## Verdict and status

The capacity-constrained replacement problem has a compact exact
decomposition:
\[
  \boxed{
  A_c(b,L,B)
  =
  G_c(b,L)-\ell_c^\star(b,L,B),}
  \tag{REP}
\]
where \(G_c\) is the candidate's productive gain in the unconstrained
augmented library and \(\ell_c^\star\) is the least productive loss among
deletion sets that release enough burden to retain the candidate. Additive
resource costs enter through the exact release requirement
\[
  W(D)\ge\bigl[W(L)+w_c-B\bigr]_+.
\]

This identity supports the six requested economic conclusions, with one
necessary correction. The absence of a deletion that is safe relative to the
pre-admission library \(L\) does **not** imply a productive loss: the
candidate can replace the deleted policy's frontier or modules. A true loss
is forced exactly when no capacity-sufficient deletion is zero-loss relative
to the augmented library \(L\cup\{c\}\), or under an additional strict-loss
assumption that makes structural change lower the stated objective.

This document registers REP as a supporting optimization result. It is not a
new main contribution theorem and creates no Lean verification claim. The
existing exact resource fixture validates that capacity release can be
necessary and already exhibits the distinction between pre-admission and
candidate-relative safety.

## 1. Exact finite replacement problem

Fix:

- a belief \(b\) and productive parameter bundle \(\theta\);
- a finite current library
  \(L\in\mathfrak L(S_\theta^{\mathrm{elig}})\);
- a newly outer-certified active candidate
  \[
    c\in S_\theta^{\mathrm{elig}}\setminus L,
    \qquad c\ne s_0;
  \]
- additive exact resource burden
  \[
    W(K)=\sum_{s\in K}w_s,
    \qquad
    w_{s_0}=0,
    \qquad
    w_s>0\text{ for }s\ne s_0;
  \]
- a hard capacity \(B\in\mathbb Q_{\ge0}\); and
- finite productive value \(V_\theta(b,K)\in\mathbb Q\).

The candidate is already retention-eligible. This is a static outer review;
it does not modify raw stochastic generation, verification, or admission.
The word “admission” below means accepting \(c\) into the retained library.

For every active-incumbent deletion set
\[
  D\subseteq L\setminus\{s_0\},
\]
define
\[
  L^{c,D}:=(L\setminus D)\cup\{c\}.
\]
The capacity-feasible deletion family is
\[
  \mathcal D_c(B;L)
  :=
  \left\{
    D\subseteq L\setminus\{s_0\}:
    W(L^{c,D})\le B
  \right\}.
\]
The complete optimizer correspondence is
\[
  \mathcal D_c^\star(b,L,B)
  :=
  \operatorname*{argmax}_{D\in\mathcal D_c(B;L)}
  V_\theta(b,L^{c,D}).
\]
When this set is nonempty, choose any
\[
  D^\star(c)\in\mathcal D_c^\star(b,L,B)
\]
and define the conditional replacement value
\[
  V_c^\star(b,L,B)
  :=
  V_\theta(b,L^{c,D^\star(c)}).
\]
Every optimizer has the same objective value, so \(V_c^\star\) is independent
of the selected optimizer even when the deletion set is not unique.

The user's net admission value is
\[
  \boxed{
  A_c(b,L,B)
  :=
  V_c^\star(b,L,B)-V_\theta(b,L).}
\]
This is a value comparison with the current library, not a resource-penalized
objective.

## 2. Feasibility and exact capacity release

Because \(c\notin L\) and \(D\subseteq L\),
\[
\begin{aligned}
  W(L^{c,D})
  &=W(L)-W(D)+w_c.
\end{aligned}
\]
Define the capacity deficit created by inserting \(c\) without deletion:
\[
  \boxed{
  \kappa_c(L,B)
  :=
  \bigl[W(L)+w_c-B\bigr]_+
  =
  \max\{0,W(L)+w_c-B\}.}
\]
Then
\[
  \boxed{
  D\in\mathcal D_c(B;L)
  \iff
  W(D)\ge\kappa_c(L,B).}
  \tag{capacity}
\]
Thus \(w_c\) and the incumbent weights are fully accounted for by the hard
constraint: the candidate creates the deficit, and the deletion set must
release at least that much burden.

Under unrestricted deletion of every active incumbent,
\(\mathcal D_c(B;L)\) is nonempty exactly when
\[
  w_c\le B,
\]
because deleting all incumbents leaves \(\{s_0,c\}\), whose burden is \(w_c\).
Finiteness then guarantees
\[
  \mathcal D_c^\star(b,L,B)\ne\varnothing.
\]
If \(w_c>B\), conditional retention of \(c\) is infeasible and
\(D^\star(c)\), \(V_c^\star\), and \(A_c\) are undefined unless an explicit
extended-value convention is added.

When the current library is feasible, \(W(L)\le B\):

- if \(\kappa_c=0\), no deletion is required;
- if \(0<\kappa_c\le W(L)\), at least one active incumbent must be deleted;
  and
- feasibility of conditional replacement still requires \(w_c\le B\).

## 3. Gross candidate gain and required deletion loss

Assume productive value is weakly monotone under library inclusion:
\[
  K_1\subseteq K_2
  \Longrightarrow
  V_\theta(b,K_1)\le V_\theta(b,K_2).
  \tag{MON}
\]
This is the value-side property used by the exact Julia retention problem and
the menu-expansion interpretation of the productive model.

Define the candidate's unconstrained incremental productive value by
\[
  G_c(b,L)
  :=
  V_\theta(b,L\cup\{c\})-V_\theta(b,L).
\]
Under (MON),
\[
  G_c(b,L)\ge0.
\]

For a deletion set \(D\), define its candidate-relative displacement loss:
\[
  \ell_c(b,L;D)
  :=
  V_\theta(b,L\cup\{c\})
  -
  V_\theta(b,L^{c,D}).
\]
Since
\[
  L^{c,D}\subseteq L\cup\{c\},
\]
(MON) gives
\[
  \ell_c(b,L;D)\ge0.
\]
Define the least loss needed to satisfy capacity:
\[
  \ell_c^\star(b,L,B)
  :=
  \min_{D\in\mathcal D_c(B;L)}
  \ell_c(b,L;D).
\]
Maximizing post-replacement value is equivalent to minimizing displacement
loss, so every \(D^\star(c)\) attains this minimum.

Adding and subtracting the unconstrained augmented value gives
\[
\begin{aligned}
  A_c(b,L,B)
  &=
  V_\theta(b,L^{c,D^\star(c)})
  -
  V_\theta(b,L)\\
  &=
  \left[
    V_\theta(b,L\cup\{c\})-V_\theta(b,L)
  \right]\\
  &\qquad-
  \left[
    V_\theta(b,L\cup\{c\})
    -
    V_\theta(b,L^{c,D^\star(c)})
  \right]\\
  &=
  \boxed{
  G_c(b,L)-\ell_c^\star(b,L,B).}
\end{aligned}
\]
This is the exact opportunity-cost identity (REP).

## 4. Three safety notions

Write
\[
  K_H:=(F_H,C_H)
\]
for the frontier--closure summary of a library \(H\).

### 4.1 Pre-admission structural safety

A deletion set \(D\) is safe relative to the current library when
\[
  K_{L\setminus D}=K_L.
  \tag{pre-safe}
\]
Under the existing raw factorization, this preserves the current productive
process and all associated finite-horizon values. It is stronger than merely
having the same value at the single fixed state \(b\).

### 4.2 Candidate-relative structural safety

A deletion set \(D\) is structurally safe after inserting \(c\) when
\[
  K_{L^{c,D}}=K_{L\cup\{c\}}.
  \tag{c-safe}
\]
This compares the capacity-feasible replacement with the unconstrained
candidate-augmented library.

Every pre-admission safe deletion is candidate-relative safe. Indeed,
\[
  F_{(L\setminus D)\cup\{c\}}
  =
  \max\{F_{L\setminus D},j_c\}
  =
  \max\{F_L,j_c\}
  =
  F_{L\cup\{c\}},
\]
and closure absorption gives
\[
\begin{aligned}
  C_{(L\setminus D)\cup\{c\}}
  &=
  \operatorname{cl}
  \left(
    C_{L\setminus D}\cup\operatorname{mods}(c)
  \right)\\
  &=
  \operatorname{cl}
  \left(
    C_L\cup\operatorname{mods}(c)
  \right)
  =
  C_{L\cup\{c\}}.
\end{aligned}
\]

The converse can fail. A candidate can replace the operational profile or
modules of an incumbent whose deletion was unsafe before the candidate
arrived.

### 4.3 Objective-specific zero-loss safety

A deletion set is zero-loss for this replacement objective when
\[
  \ell_c(b,L;D)=0.
  \tag{zero-loss}
\]
Candidate-relative structural safety implies zero loss under the existing
frontier--closure factorization:
\[
  \text{pre-safe}
  \Longrightarrow
  c\text{-safe}
  \Longrightarrow
  \text{zero-loss}.
\]
Neither converse is unconditional. Equality of one value at one belief and
horizon need not identify the entire frontier--closure state.

## 5. Supporting proposition REP

Define the maximum burden releasable by the three classes:
\[
\begin{aligned}
  R_L^{\mathrm{pre}}
  &:=
  \max\left\{
    W(D):
    D\subseteq L\setminus\{s_0\},\
    K_{L\setminus D}=K_L
  \right\},\\
  R_{L,c}^{\mathrm{str}}
  &:=
  \max\left\{
    W(D):
    D\subseteq L\setminus\{s_0\},\
    K_{L^{c,D}}=K_{L\cup\{c\}}
  \right\},\\
  R_{L,c}^{0}
  &:=
  \max\left\{
    W(D):
    D\subseteq L\setminus\{s_0\},\
    \ell_c(b,L;D)=0
  \right\}.
\end{aligned}
\]
The empty deletion belongs to all three classes, so the maxima exist and are
nonnegative. The implications above give
\[
  R_L^{\mathrm{pre}}
  \le
  R_{L,c}^{\mathrm{str}}
  \le
  R_{L,c}^{0}.
\]

### Proposition REP — Safe release and replacement opportunity cost

Assume the finite exact setting, additive burden, (MON), \(w_c\le B\), and
the existing frontier--closure value factorization.

1. **Safe release has priority.** If
   \[
     \kappa_c(L,B)\le R_L^{\mathrm{pre}},
   \]
   some deletion is both pre-admission safe and capacity-feasible. Every such
   deletion is replacement-optimal and satisfies
   \[
     V_\theta(b,L^{c,D})
     =
     V_\theta(b,L\cup\{c\}).
   \]
   Hence a value-losing deletion is unnecessary.

2. **Candidate-relative safe release is sufficient.** More generally, if
   \[
     \kappa_c(L,B)\le R_{L,c}^{\mathrm{str}},
   \]
   admission can meet capacity without sacrificing any productive value
   relative to the unconstrained augmented library.

3. **Exact true-trade-off criterion.**
   \[
     \boxed{
     \ell_c^\star(b,L,B)=0
     \iff
     \kappa_c(L,B)\le R_{L,c}^{0}.}
   \]
   Therefore
   \[
     \boxed{
     \kappa_c(L,B)>R_{L,c}^{0}
     \Longrightarrow
     \ell_c^\star(b,L,B)>0.}
   \]
   In that case every capacity-feasible admission sacrifices productive value
   relative to \(L\cup\{c\}\).

4. **Admission opportunity-cost test.** Suppose \(W(L)\le B\) and rejection
   means retaining \(L\). Then admission is weakly optimal exactly when
   \[
     G_c(b,L)\ge\ell_c^\star(b,L,B),
   \]
   strictly optimal exactly when
   \[
     G_c(b,L)>\ell_c^\star(b,L,B),
   \]
   tied with rejection exactly when the two sides are equal, and rejected
   exactly when
   \[
     G_c(b,L)<\ell_c^\star(b,L,B).
   \]

The result is set-valued in \(D\). Multiple optimal deletion sets can release
different burdens or alter different raw carriers while attaining the same
post-replacement value.

### Proof

For part 1, the definition of \(R_L^{\mathrm{pre}}\) supplies a pre-safe
deletion \(D\) with \(W(D)\ge\kappa_c\). Formula \((\mathrm{capacity})\)
makes it feasible. Pre-safety implies candidate-relative structural safety,
which gives
\[
  V_\theta(b,L^{c,D})=V_\theta(b,L\cup\{c\}).
\]
By (MON), no deletion outcome can exceed the value of its superset
\(L\cup\{c\}\). Thus \(D\) attains the replacement optimum. Part 2 is the
same argument starting from candidate-relative safety.

For part 3, \(\kappa_c\le R_{L,c}^{0}\) holds exactly when some zero-loss
deletion releases at least the required deficit, which by
\((\mathrm{capacity})\) is exactly when a feasible zero-loss deletion exists.
The feasible family is finite and every loss is nonnegative, so absence of a
zero-loss feasible deletion makes its minimum strictly positive.

Part 4 follows immediately from
\[
  A_c=G_c-\ell_c^\star
\]
and comparison of the conditional replacement value with the feasible
outside option \(V_\theta(b,L)\).

## 6. Why “no current safe deletion” is not enough

The unqualified statement

> If no deletion safe relative to \(L\) releases enough capacity, admission
> must sacrifice productive value

is false.

The registered exact fixture
CX-OPT-ADMISSION-REQUIRES-DELETION-01 has:

- one unit-weight incumbent \(s_1\);
- one unit-weight candidate \(c=s_2\);
- capacity \(B=1\);
- identity closure; and
- \(\operatorname{mods}(s_1)=\operatorname{mods}(c)=\{m_1\}\).

Deleting \(s_1\) before adding \(c\) changes closure from \(\{m_1\}\) to the
empty set, so it is not pre-admission safe. Yet after \(c\) is inserted,
deleting \(s_1\) preserves the candidate-augmented closure because \(c\)
carries the same module. The deletion is candidate-relative safe and creates
the required capacity with no productive loss.

There is a second logical boundary. If no structurally \(c\)-safe deletion is
large enough, a fixed value can still tie across structurally distinct
libraries. Therefore structural non-safety implies a strict objective loss
only under an additional condition such as
\[
  K_{L^{c,D}}\ne K_{L\cup\{c\}}
  \Longrightarrow
  V_\theta(b,L^{c,D})
  <
  V_\theta(b,L\cup\{c\})
\]
for every capacity-feasible \(D\). Without that condition, the exact
criterion must use \(R_{L,c}^{0}\), not only structural safety.

## 7. Equal capacity release can have different loss channels

Consider three unit-weight active strategies:

- incumbent \(o\) has operational profile \(j_o(b)=2\) and no module;
- incumbent \(g\) has profile zero and carries module \(m\); and
- candidate \(c\) has operational profile \(j_c(b)=1\) and no module.

Let
\[
  V_\theta(b,H)
  =
  F_H(b)
  +
  3\,\mathbf 1\{m\in C_H\},
\]
which separates an exact operational component from an exact generative
module component. Take
\[
  L=\{s_0,o,g\},
  \qquad
  B=2.
\]
The unconstrained augmented library has burden three and value
\[
  V_\theta(b,L\cup\{c\})=2+3=5.
\]
One unit must be released. Both singleton deletions meet capacity, but:
\[
\begin{array}{c|c|c|c|c}
  D & W(D) & F_{L^{c,D}}(b) & C_{L^{c,D}} & \ell_c(D)\\
  \hline
  \{o\} & 1 & 1 & \{m\} & 1\\
  \{g\} & 1 & 2 & \varnothing & 3
\end{array}
\]
Deleting \(o\) creates an operational loss of one. Deleting \(g\) creates a
generative loss of three. Equal released capacity therefore does not identify
equal productive opportunity cost, and the optimal deletion is
\(D^\star(c)=\{o\}\).

With the same incumbents but \(j_c(b)=4\), neither singleton deletion is
pre-admission safe, yet deleting \(o\) after insertion is candidate-relative
safe:
\[
  F_{L\cup\{c\}}(b)
  =
  F_{L^{c,\{o\}}}(b)
  =
  4,
  \qquad
  C_{L\cup\{c\}}
  =
  C_{L^{c,\{o\}}}
  =
  \{m\}.
\]
This is the operational analogue of the module-substitution boundary in the
registered fixture.

## 8. Positive standalone value does not guarantee acceptance

Take one unit-weight incumbent \(p\), one unit-weight candidate \(c\), and
capacity \(B=1\). Let the exact monotone productive-value table be
\[
\begin{array}{c|cccc}
  H
  &\{s_0\}
  &\{s_0,p\}
  &\{s_0,c\}
  &\{s_0,p,c\}\\
  \hline
  V_\theta(b,H)
  &0&5&4&6.
\end{array}
\]
The candidate's standalone value is positive:
\[
  V_\theta(b,\{s_0,c\})-V_\theta(b,\{s_0\})=4.
\]
Its unconstrained incremental value in the current library is also positive:
\[
  G_c=6-5=1.
\]
But retaining \(c\) requires deleting \(p\), so
\[
  \ell_c^\star=6-4=2
\]
and
\[
  A_c=1-2=-1.
\]
Keeping \(L=\{s_0,p\}\) yields value five, while accepting \(c\) yields value
four. The candidate is rejected because the required displaced incumbent is
more valuable than the candidate's incremental contribution.

## 9. How resource prices would change the comparison

In the hard-capacity problem, resource costs are accounted for through
\[
  W(D)\ge\kappa_c(L,B).
\]
There is no direct subtraction of \(W\) from the user's productive-value
objective.

If a separate resource price \(\lambda\ge0\) is imposed, the net change from
a particular deletion \(D\) is instead
\[
\begin{aligned}
  A_{c,\lambda}(D)
  &:=
  \left[
    V_\theta(b,L^{c,D})-\lambda W(L^{c,D})
  \right]
  -
  \left[
    V_\theta(b,L)-\lambda W(L)
  \right]\\
  &=
  G_c-\ell_c(D)-\lambda\bigl(w_c-W(D)\bigr).
\end{aligned}
\]
That is a different penalized replacement problem. Its deletion optimizer
need not equal \(D^\star(c)\), which maximizes productive value subject to a
hard capacity. The two objectives must not be conflated.

## 10. Interpretation of the six requested conclusions

1. **Safe-capacity release.** Search first for a capacity-sufficient
   candidate-relative safe deletion. Every pre-admission safe deletion is in
   that class. If one exists, it attains the unconstrained augmented value, so
   a value-losing replacement is dominated. “First” is a dominance rule, not
   a claim that a greedy one-policy-at-a-time procedure finds the best set.

2. **No necessary sacrifice after sufficient safe release.** If safe
   deletions release at least \(\kappa_c\), then
   \(\ell_c^\star=0\) and \(A_c=G_c\).

3. **True trade-off.** A strict productive sacrifice is forced exactly when
   no capacity-feasible zero-loss deletion exists. Absence of only a
   pre-admission or structural safety certificate is insufficient without the
   stated strict-loss condition.

4. **Admission test.** With feasible outside option \(L\), accept weakly iff
   \(G_c\ge\ell_c^\star\), accept strictly iff
   \(G_c>\ell_c^\star\), and reject iff
   \(G_c<\ell_c^\star\). Resource weights determine
   \(\ell_c^\star\) through the capacity deficit and feasible deletion sets.

5. **Deletion-set heterogeneity.** Equal \(W(D)\) does not imply equal
   \(\ell_c(D)\). Deletions can damage the operational frontier, generative
   closure, both, or neither after the candidate is inserted.

6. **Positive candidates can be rejected.** Positive standalone or even
   positive unconstrained incremental value does not ensure acceptance when
   the least harmful capacity-sufficient deletion loses more value.

## 11. Claim boundary

REP assumes:

1. the finite exact outer-retention domain;
2. additive nonnegative rational burden with a zero-weight inactive strategy;
3. an outer-certified \(c\notin L\);
4. unrestricted deletion sets
   \(D\subseteq L\setminus\{s_0\}\);
5. \(w_c\le B\) for conditional feasibility;
6. inclusion-monotone productive value (MON); and
7. frontier--closure factorization only for structural-safety preservation.

The acceptance test additionally assumes \(W(L)\le B\) and that rejection
means keeping \(L\). If rejection instead permits a separate capacity
reoptimization without \(c\), the correct outside option is that optimized
value rather than \(V_\theta(b,L)\).

REP does not claim:

- that the candidate became eligible through raw generation or verification;
- that every pre-admission unsafe deletion causes loss after insertion;
- that every structural change strictly lowers the fixed value objective;
- uniqueness of \(D^\star(c)\);
- that equal released burden implies equal loss;
- that greedy safe deletion is globally optimal;
- that the hard-capacity and penalized replacement optimizers coincide; or
- that a positive standalone candidate must be accepted.

The result is compact enough for a supporting proposition or appendix lemma,
but it should not become a main-text contribution pillar. No matching Lean
declaration or axiom audit currently exists.
