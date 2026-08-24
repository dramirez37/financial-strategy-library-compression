# Joint Descendant-Event Lower-Bound Specification

## Verdict

Theorem 5.9 can be generalized directly with the joint
belief-path/admitted-outcome law already present in the unified model. The
general theorem does **not** require independence. It uses the terminal
pushforward of that law on the distinguished event
\(\{B_d=b',\,O=\operatorname{some}(g)\}\).

There is one sign correction that is mathematically necessary. With the
repository's current operating-adjustment convention, the valid joint-law
bound is
\[
  \boxed{
  \Delta_h^{\mathrm{gen}}(s\mid b,L)
  \ge
  \max\!\left\{
    -\kappa
    +A^{\mathrm{op}}_{q,h}(b,L^+)
    +\beta^d
      \sum_{b'\in B}\eta_{q,g}(b'\mid b,K^+)G(b'),
    0
  \right\}.}
  \tag{JD}
\]
Here \(L^+=L\cup\{s\}\) and \(K^+=K_{L^+}\).

If operating timing is instead recorded with the operating-loss sign
convention
\[
  \mathcal A^{\mathrm{op,loss}}_{q,h}(b,L^+)
  :=-A^{\mathrm{op}}_{q,h}(b,L^+),
\]
the equivalent display is
\[
  \Delta_h^{\mathrm{gen}}(s\mid b,L)
  \ge
  \max\!\left\{
    -\kappa
    -\mathcal A^{\mathrm{op,loss}}_{q,h}(b,L^+)
    +\beta^d
      \sum_{b'\in B}\eta_{q,g}(b'\mid b,K^+)G(b'),
    0
  \right\}.
  \tag{JD-loss}
\]
The loss variable is nonnegative only in cases where research timing weakly
underperforms the passive counterfactual; the algebra does not require that
sign.

The proposed expression with a **negative** descendant term,
\[
  \max\{-\kappa-A^{\mathrm{op}}
          -\beta^d\textstyle\sum_{b'}\eta_{q,g}(b')G(b'),0\},
  \tag{JD-rejected}
\]
cannot satisfy the stated requirements:

1. substituting
   \(\eta_{q,g}(b')=\pi\rho^d\mu_{q,d}(b,b')\) gives the negative of the
   current descendant term rather than the current independence formula;
2. it makes the guarantee weakly decreasing in a beneficial event mass and
   in a nonnegative continuation gain; and
3. when cost and operating loss are nonnegative it collapses to the vacuous
   zero bound.

Accordingly, (JD) is the binding sign-consistent target. Equation (JD-loss)
is the same result under the alternative operating-loss notation.

The primary joint-law declaration now exists in Lean as
`generativeInsertionValue_lowerBound_joint`. Its certificate has no
independence field. The prior product theorem remains available, but its proof
now invokes the joint theorem and factors the joint term only afterward. All
locked experimental results remain unchanged.

### Exact gauntlet verdict

The registered exact search `joint-descendant-bound-gauntlet-v1` evaluates a
two-belief, three-outcome one-project Bellman subclass in
`Rational{BigInt}` arithmetic. Its 21 normalized joint laws include every
weak composition of two probability units over the six terminal
belief/outcome atoms. The search crosses nonnegative continuation tables,
every admissible distinguished-event floor, discounts \(0,1/2,3/4\),
durations one and two, costs zero and one, and operating adjustments
\(-1,0,1\).

| Attack | Exact checks | Failures |
|---|---:|---:|
| primary single-\(g\) joint bound | 2,204,496 | 0 |
| correlated joint laws | 419,904 | 0 |
| negative adjustment, included exactly | 734,832 | 0 |
| two distinguished nonnegative descendants | 2,204,496 | 0 |
| harmful-outcome correction | 171,072 | 0 |
| uncorrected omission with harmful outcomes | 171,072 | 20,736 |
| positive-comparator correction | 9 | 0 |
| uncorrected positive comparator | 9 | 4 |
| enabled on both sides with zero comparator premium | 3 | 0 |

The search preserves eight minimized counterexamples and four surviving
boundary fixtures in
`experiments/results/summaries/joint_descendant_bound_counterexamples.csv`.
The complete counts and gates are in
`experiments/results/summaries/joint_descendant_bound_summary.json`.

The surviving theorem is (JD-theorem) with the following proof-critical
clarifications:

- \(G\) is a supportwise floor on the **complete** completion-continuation
  improvement, not merely a direct operating payoff;
- if continuation can retain full-path memory, the floor is imposed path by
  path or the path-level version below is used;
- \(d\le h\) is required before the project action can enter the comparison;
- the exact operating adjustment is retained even when negative;
- omitted outcomes are nonnegative or receive the explicit correction;
- the primary carrier statement retains both post-insertion-only enablement
  and the zero-premium comparator; and
- the product formula remains an independence corollary only.

The exact search opened the Lean implementation gate for this revised
statement. The subsequent Lean proof is the verification step; the finite
search remains falsification evidence rather than proof.

## 1. Existing unified joint law

Let
\[
  \mathcal O:=\operatorname{Option}(S)
\]
be the admitted-outcome type. For project \(q\), initiation belief \(b\),
realizable compressed state \(K\), and positive duration \(d=d_q\), the
unified model already declares the normalized joint completion law
\[
  \Lambda_q(\mathbf b,o\mid b,K),
  \qquad
  \mathbf b=(b_0,\ldots,b_d),\quad o\in\mathcal O.
\]
Its two required marginals are:

\[
\begin{aligned}
  \sum_{o\in\mathcal O}\Lambda_q(\mathbf b,o\mid b,K)
    &=\mathbb P_b^{(d)}(\mathbf b),\\
  \sum_{\mathbf b}\Lambda_q(\mathbf b,o\mid b,K)
    &=\Gamma(q,b,C)(o),
\end{aligned}
\tag{JD-marginals}
\]
where \(\mathbb P_b^{(d)}\) is the full Markov belief-path law and
\(\Gamma\) is the admitted-outcome law derived from raw generation and
primitive admission. These marginal restrictions do not determine the
dependence between the belief path and the admitted outcome.

Push \(\Lambda_q\) forward to terminal belief and admitted outcome:
\[
  \Xi_q(b',o\mid b,K)
  :=
  \sum_{\mathbf b:\,b_d=b'}
    \Lambda_q(\mathbf b,o\mid b,K).
  \tag{JD-Xi}
\]
Then
\[
\begin{aligned}
  \sum_o\Xi_q(b',o\mid b,K)&=\mu_{q,d}(b,b'),\\
  \sum_{b'}\Xi_q(b',o\mid b,K)&=\Gamma(q,b,C)(o),\\
  \sum_{b',o}\Xi_q(b',o\mid b,K)&=1,
\end{aligned}
\tag{JD-Xi-marginals}
\]
where \(\mu_{q,d}(b,b')=P_B^d(b,b')\) is the terminal-belief marginal in
the current Markov-path model.

For distinguished descendant \(g\), define the requested joint event mass:
\[
  \boxed{
  \eta_{q,g}(b'\mid b,K)
  :=
  \Xi_q(b',\operatorname{some}(g)\mid b,K)
  =
  \Pr\!\left(
    B_d=b',\ O=\operatorname{some}(g)
    \mid B_0=b,K,q
  \right).}
  \tag{JD-eta}
\]

Thus \(\eta_{q,g}\) is a nonnegative subprobability mass function:
\[
  \eta_{q,g}(b'\mid b,K)\ge0,\qquad
  \sum_{b'}\eta_{q,g}(b'\mid b,K)
  =\Gamma(q,b,C)(\operatorname{some}(g))\le1.
  \tag{JD-eta-mass}
\]
No quotient of marginals and no conditional probability is needed. In
particular, the definition remains valid when \(g\)-admission is correlated
with the terminal belief or with the full pre-completion belief path.

### Full-path version

If the continuation state retains path information beyond \(B_d\), define
\[
  \zeta_{q,g}(\mathbf b\mid b,K)
  :=\Lambda_q(\mathbf b,\operatorname{some}(g)\mid b,K).
  \tag{JD-zeta}
\]
For a supportwise path gain floor
\[
  D_{q,h}(\mathbf b,\operatorname{some}(g);L^+)
  \ge G^{\mathrm{path}}(\mathbf b)\ge0,
\]
the distinguished contribution is
\[
  \sum_{\mathbf b}
    \zeta_{q,g}(\mathbf b\mid b,K^+)
      G^{\mathrm{path}}(\mathbf b).
  \tag{JD-path-gain}
\]
The terminal formula follows when a single \(G(b')\) lower-bounds every
positive-mass success path ending at \(b'\). Using an average or one selected
path as \(G(b')\) is invalid. Fixture `CX-T6-JOINT-PATH-FLOOR-01` has two
equiprobable success paths ending at the same terminal belief with gains zero
and two: declaring \(G(b')=2\) predicts one while the discounted exact value
is \(1/2\). The path-level weighted floor gives \(1/2\); the terminal minimum
gives the weaker valid bound zero.

## 2. Comparator and timing objects

Fix a raw library \(L\), an inserted carrier \(s\), and
\[
  L^+:=L\cup\{s\},\qquad K^+:=K_{L^+}.
\]
Let \(q\) have duration \(d=d_q\). The theorem uses the following existing
objects.

The research-option premium and generative insertion value are
\[
\begin{aligned}
  \Omega_h(b,L)&:=U_h(b,L)-P_h(b,L),\\
  \Delta_h^{\mathrm{gen}}(s\mid b,L)
    &:=\Omega_h(b,L^+)-\Omega_h(b,L).
\end{aligned}
\tag{JD-premium}
\]

For terminal belief \(b'\) and admitted outcome \(o\), define the
completion-continuation improvement over the frozen retained library:
\[
  D_{q,h}(b',o;L^+)
  :=
  U_{h-d}(b',L^+\oplus o)-P_{h-d}(b',L^+).
  \tag{JD-completion-gain}
\]

The operating-timing adjustment retains the current manuscript and Lean
sign convention:
\[
  A^{\mathrm{op}}_{q,h}(b,L^+)
  :=
  \mathbb E^q_{b,K^+}\!\left[
    G^{\mathrm{op}}(K^+,q,\mathbf B)
    +\beta^dP_{h-d}(B_d,L^+)
  \right]
  -P_h(b,L^+).
  \tag{JD-operating-adjustment}
\]
It is a benefit relative to the passive counterfactual. It can be positive,
zero, or negative. Suspended operation can make it negative. It must not be
silently set to zero.

The exact committed-project advantage is
\[
\begin{aligned}
  R_{q,h}(b,L^+)-P_h(b,L^+)
  ={}&-\kappa
      +A^{\mathrm{op}}_{q,h}(b,L^+)\\
    &+\beta^d
      \sum_{b'\in B}\sum_{o\in\mathcal O}
        \Xi_q(b',o\mid b,K^+)D_{q,h}(b',o;L^+).
\end{aligned}
\tag{JD-project-identity}
\]
This is the existing unified project-action decomposition rewritten through
the terminal joint law. It is valid without independence.

## 3. Exact assumptions for the primary joint-law theorem

The proposed generalized Theorem 5.9 uses the following conditions.

1. **Finite unified process.** The belief, strategy, module, project, and
   realizable compressed-state types are finite. Probabilities and rewards
   are exact rationals, \(0\le\beta<1\), \(d_q>0\), and \(d_q\le h\).

2. **Frontier silence.**
   \[
     F_{L^+}=F_L.
   \]
   Hence passive insertion value is zero at every belief and horizon.

3. **Enabled only after insertion.**
   \[
     q\in Q(K^+),\qquad q\notin Q(K_L).
   \]
   The carrier creates the displayed feasible project opportunity.

4. **Exact cost.**
   \[
     \kappa_q(b,K^+)=\kappa,\qquad \kappa\ge0.
   \]

5. **Deleted-comparator condition.**
   \[
     \Omega_h(b,L)=0.
   \]
   This condition, rather than project infeasibility by itself, is what
   removes pre-existing research-option value from the comparison.

6. **Declared joint completion law.** The theorem uses
   \(\Lambda_q(\cdot,\cdot\mid b,K^+)\), or equivalently its terminal
   pushforward \(\Xi_q\), with the unified marginal conditions
   (JD-marginals). No independence condition is imposed.

7. **Distinguished descendant floor.** There is a function
   \(G:B\to\mathbb Q_{\ge0}\) such that for every terminal belief with
   positive distinguished-event mass and every positive-mass completion path
   ending at that belief,
   \[
     D_{q,h}(b',\operatorname{some}(g);L^+)\ge G(b').
     \tag{JD-g-floor}
   \]
   Here \(D\) is the complete full-minus-passive continuation difference,
   including every future project-menu change caused by admission. It is
   harmless, and simpler in Lean, to state the floor for every length-\(d\)
   path rather than only on the positive-mass support.

8. **Nonnegative omitted outcomes.** For every
   \(o\ne\operatorname{some}(g)\) and every terminal belief on the support of
   \(\Xi_q(\cdot,o\mid b,K^+)\),
   \[
     D_{q,h}(b',o;L^+)\ge0.
     \tag{JD-omitted-nonnegative}
   \]
   In the current raw model this condition is derived, not assumed; Section 5
   states the exact derivation.

These assumptions preserve the current theorem's frontier, feasibility,
comparator, cost, horizon, update, and operating-timing boundaries while
removing only its independence restriction.

## 4. Generalized theorem and proof

### Proposed Theorem 5.9 — Joint descendant-event lower bound

Under the assumptions in Section 3,
\[
  \Delta_h^{\mathrm{gen}}(s\mid b,L)
  \ge
  \max\!\left\{
    -\kappa
    +A^{\mathrm{op}}_{q,h}(b,L^+)
    +\beta^d
      \sum_{b'\in B}
        \eta_{q,g}(b'\mid b,K^+)G(b'),
    0
  \right\}.
  \tag{JD-theorem}
\]

If passive research-period timing is exactly matched, so that
\[
  A^{\mathrm{op}}_{q,h}(b,L^+)=0,
\]
then
\[
  \Delta_h^{\mathrm{gen}}(s\mid b,L)
  \ge
  \max\!\left\{
    -\kappa
    +\beta^d
      \sum_{b'\in B}
        \eta_{q,g}(b'\mid b,K^+)G(b'),
    0
  \right\}.
  \tag{JD-zero-adjustment}
\]

### Proof

The deleted-comparator condition gives
\[
  \Delta_h^{\mathrm{gen}}(s\mid b,L)
  =\Omega_h(b,L^+).
\]
Because full value allows Continue,
\(\Omega_h(b,L^+)\ge0\).

Because \(q\) is feasible at \(K^+\), full value also weakly dominates the
committed value of \(q\). Subtracting the retained passive value and applying
(JD-project-identity) gives
\[
\begin{aligned}
  \Omega_h(b,L^+)
  \ge{}&-\kappa+A^{\mathrm{op}}_{q,h}(b,L^+)\\
  &+\beta^d
    \sum_{b',o}\Xi_q(b',o\mid b,K^+)
      D_{q,h}(b',o;L^+).
\end{aligned}
\tag{JD-project-lower}
\]

Split the last sum into
\(o=\operatorname{some}(g)\) and all other outcomes. On the distinguished
event, (JD-g-floor) gives
\[
\begin{aligned}
  &\sum_{b'}\Xi_q(b',\operatorname{some}(g)\mid b,K^+)
     D_{q,h}(b',\operatorname{some}(g);L^+)\\
  &\qquad\ge
  \sum_{b'}\eta_{q,g}(b'\mid b,K^+)G(b').
\end{aligned}
\]
Every omitted term is nonnegative by (JD-omitted-nonnegative). Dropping those
terms therefore preserves a lower bound. Combining this project bound with
\(\Omega_h(b,L^+)\ge0\) gives (JD-theorem).

The argument never separates a belief probability from an outcome
probability. Dependence is retained inside \(\eta_{q,g}\).

## 5. When failure and other outcomes may be ignored

“Ignored” means dropped from a lower-bound sum because their contribution is
nonnegative. It does not mean that the outcomes have zero probability or are
independent of the belief path.

### Failure

For \(o=\operatorname{none}\), the current raw update is the identity:
\[
  L^+\oplus\operatorname{none}=L^+.
\]
Therefore
\[
\begin{aligned}
  D_{q,h}(b',\operatorname{none};L^+)
    &=U_{h-d}(b',L^+)-P_{h-d}(b',L^+)\\
    &=\Omega_{h-d}(b',L^+)\ge0,
\end{aligned}
\]
where the last inequality follows because Continue reproduces the frozen
passive policy. Failure may therefore be ignored under exactly these two
conditions:

- failure leaves the raw library unchanged; and
- full continuation retains the option to follow the passive policy.

### Other admitted descendants

For \(o=\operatorname{some}(\widetilde g)\), the current update is
insertion-only:
\[
  L^+\subseteq L^+\oplus\operatorname{some}(\widetilde g).
\]
Passive value is monotone under raw-library inclusion, and full value
dominates passive value. Hence
\[
\begin{aligned}
  U_{h-d}(b',L^+\oplus o)
  &\ge P_{h-d}(b',L^+\oplus o)\\
  &\ge P_{h-d}(b',L^+),
\end{aligned}
\]
so \(D_{q,h}(b',o;L^+)\ge0\). Other admitted outcomes may therefore be
ignored when:

- admission only inserts a catalog strategy and never deletes or replaces an
  incumbent;
- insertion has no compulsory continuation charge or other adverse state
  component omitted from the raw library;
- passive value is monotone under the resulting library inclusion; and
- full value continues to dominate passive value.

These are exact structural reasons, not an extra blanket assumption that
every candidate is beneficial.

### Explicit harmful-outcome correction

If failure or another admitted outcome can be harmful, assign a nonnegative
floor magnitude \(H_o(b')\) satisfying
\[
  D_{q,h}(b',o;L^+)\ge-H_o(b')
  \qquad
  \left(o\ne\operatorname{some}(g)\right).
  \tag{JD-harm-floor}
\]
Define
\[
  \mathcal H_{q,h}(b,K^+)
  :=
  \sum_{\substack{o\in\mathcal O\\o\ne\operatorname{some}(g)}}
  \sum_{b'\in B}
    \Xi_q(b',o\mid b,K^+)H_o(b').
  \tag{JD-harm-correction}
\]
Then the valid corrected theorem is
\[
  \Delta_h^{\mathrm{gen}}(s\mid b,L)
  \ge
  \max\!\left\{
    -\kappa+A^{\mathrm{op}}_{q,h}(b,L^+)
    +\beta^d\left[
      \sum_{b'}\eta_{q,g}(b'\mid b,K^+)G(b')
      -\mathcal H_{q,h}(b,K^+)
    \right],
    0
  \right\}.
  \tag{JD-harmful}
\]
Failure and other outcomes can be ignored exactly when one can take
\(H_o=0\) on every positive-mass omitted atom. Equivalently,
\(\mathcal H_{q,h}=0\). The current insertion-only raw model satisfies this
condition by the preceding argument.

### Positive comparator correction

If the deleted comparator has
\(\Omega_h(b,L)=\Omega^- >0\), the project comparison lower-bounds the rich
premium, not its increment over the comparator. The universally valid
correction is
\[
  \Delta_h^{\mathrm{gen}}(s\mid b,L)
  \ge
  \max\!\left\{
    -\kappa+A^{\mathrm{op}}
    +\beta^d\bigl[S(\eta,G)-\mathcal H\bigr],
    0
  \right\}
  -\Omega^-.
  \tag{JD-positive-comparator}
\]
One may put a further maximum with zero on the right only under an additional
project-dominance or unchanged-action certificate ensuring that insertion
cannot lower the research premium.

Fixture `CX-T6-JOINT-POSITIVE-COMPARATOR-01` keeps \(q\) available only after
insertion but gives the poor library another unit-premium project. The new
project also has premium one, so the actual insertion value is zero while the
uncorrected project certificate is one. Subtracting \(\Omega^-=1\) is exact.

Post-insertion-only enablement and zero comparator premium are logically
distinct. The enumeration finds no failure when \(q\) is enabled on both
sides but the poor premium is exactly zero. Thus
`project_unavailable_without` is mechanism-facing once
`deleted_premium_zero` is imposed, although the carrier theorem retains both
conditions as requested. Fixture `CX-T6-JOINT-ENABLED-BOTH-01` shows why
dropping both restrictions overcounts a pre-existing unit-premium project.

## 6. Independence formula as a corollary

Let
\[
  \mu_{q,d}(b,b')
  :=
  \Pr(B_d=b'\mid B_0=b,K^+,q)
\]
be the terminal-belief marginal. Suppose only for the distinguished event
that
\[
  \eta_{q,g}(b'\mid b,K^+)
  =\pi\rho^d\mu_{q,d}(b,b').
  \tag{JD-product-specialization}
\]
This identity follows from the current stronger assumptions that:

- the full belief path and admitted outcome are conditionally independent;
- raw generation assigns \(g\) probability \(\rho^d\); and
- primitive admission accepts \(g\) with probability \(\pi\).

Full process-wide independence is stronger than necessary for this corollary;
event-specific terminal factorization (JD-product-specialization) suffices.

Substitution gives
\[
\begin{aligned}
  \sum_{b'}\eta_{q,g}(b'\mid b,K^+)G(b')
  &=\pi\rho^d
    \sum_{b'}\mu_{q,d}(b,b')G(b')\\
  &=\pi\rho^d\,\overline G_{q,d}(b).
\end{aligned}
\]
Therefore (JD-theorem) becomes
\[
  \Delta_h^{\mathrm{gen}}(s\mid b,L)
  \ge
  \max\!\left\{
    -\kappa+A^{\mathrm{op}}_{q,h}(b,L^+)
    +\beta^d\pi\rho^d\overline G_{q,d}(b),
    0
  \right\},
  \tag{JD-current-adjusted}
\]
which is the current adjusted Theorem 5.9 formula. If
\(A^{\mathrm{op}}_{q,h}=0\), it further reduces to the current
no-adjustment formula.

### Multiple descendants

Let \(D_\star\subseteq S\) be a finite set of distinct admitted descendants.
For each \(r\in D_\star\), let
\[
  \eta_{q,r}(b'\mid b,K^+)
  =\Xi_q(b',\operatorname{some}(r)\mid b,K^+)
\]
and suppose the complete continuation improvement on that event is at least
\(G_r(b')\ge0\). Since the admitted outcomes are disjoint,
\[
  \Delta_h^{\mathrm{gen}}(s\mid b,L)
  \ge
  \max\!\left\{
    -\kappa+A^{\mathrm{op}}
    +\beta^d
      \sum_{r\in D_\star}\sum_{b'}
        \eta_{q,r}(b'\mid b,K^+)G_r(b'),
    0
  \right\},
  \tag{JD-multiple}
\]
provided every outcome outside \(D_\star\) is nonnegative or receives the
correction in (JD-harmful). Distinctness is essential only to prevent
double-counting the same outcome event.

The exhaustive three-outcome search has zero failures for this disjoint-event
sum. Fixture `FX-T6-JOINT-MULTIPLE-DESCENDANTS-01` has masses \(1/2,1/2\),
gains two and four, and \(\beta=1/2\): the single-\(g\) bound is \(1/2\),
the multi-descendant bound and actual value are both \(3/2\).

## 7. Sign and monotonicity

For the no-harm case define
\[
  S(\eta,G):=\sum_{b'}\eta(b')G(b'),
  \qquad
  N:=-\kappa+A^{\mathrm{op}}+\beta^dS(\eta,G),
  \qquad
  \mathcal B:=\max\{N,0\}.
\]

### Sign

\[
  \mathcal B>0
  \quad\Longleftrightarrow\quad
  A^{\mathrm{op}}+\beta^dS(\eta,G)>\kappa,
  \tag{JD-sign-positive}
\]
and
\[
  \mathcal B=0
  \quad\Longleftrightarrow\quad
  A^{\mathrm{op}}+\beta^dS(\eta,G)\le\kappa.
  \tag{JD-sign-zero}
\]
A positive certificate implies
\(\Delta_h^{\mathrm{gen}}(s\mid b,L)>0\). A zero certificate does not imply
that the actual generative insertion value is zero; omitted positive outcomes
or another rich-library project can still create value.

With harmful outcomes, replace \(S(\eta,G)\) by
\(S(\eta,G)-\mathcal H\).

### Joint descendant-event mass

If
\[
  \eta^0(b')\le\eta^1(b')\qquad\text{for every }b'
\]
and \(G\ge0\), while cost, duration, \(G\), operating adjustment, and any
harmful-outcome correction are fixed, then
\[
  \mathcal B(\eta^0,G)\le\mathcal B(\eta^1,G).
  \tag{JD-mono-eta}
\]

An increase only in the scalar mass
\[
  p_g:=\sum_{b'}\eta_{q,g}(b')
\]
has no unconditional sign when the conditional terminal distribution changes.
Extra mass can be shifted from beliefs with high \(G\) to beliefs with low
\(G\). Scalar-mass monotonicity is valid if the conditional distribution
\(\eta/p_g\) is fixed, or if \(G\) is constant across terminal beliefs.

### Pointwise continuation gain

If \(G^0(b')\le G^1(b')\) for every \(b'\) and \(\eta\ge0\), with all other
objects fixed, then
\[
  \mathcal B(\eta,G^0)\le\mathcal B(\eta,G^1).
  \tag{JD-mono-G}
\]

### Cost

If \(\kappa_0\le\kappa_1\), with all other objects fixed, then
\[
  \mathcal B(\kappa_1)\le\mathcal B(\kappa_0).
  \tag{JD-antitone-cost}
\]

### Operating adjustment

Under the current benefit-adjustment convention, if
\(A^{\mathrm{op}}_0\le A^{\mathrm{op}}_1\), then
\[
  \mathcal B(A^{\mathrm{op}}_0)
  \le\mathcal B(A^{\mathrm{op}}_1).
  \tag{JD-mono-operating-benefit}
\]
Under the operating-loss convention
\(\mathcal A^{\mathrm{op,loss}}=-A^{\mathrm{op}}\), the guarantee is
antitone in \(\mathcal A^{\mathrm{op,loss}}\).

### Harmful-outcome correction

Holding the distinguished-event term fixed, the corrected guarantee is
antitone in \(\mathcal H\). Changing the complete joint law can change both
\(\eta\) and \(\mathcal H\), so neither component may be silently held fixed
when the coupling itself changes.

## 8. Duration has no unconditional sign

In the joint formulation the duration-indexed certificate is
\[
  -\kappa_d+A^{\mathrm{op}}_d
  +\beta^d
    \sum_{b'}\eta_{q,g,d}(b'\mid b,K^+)G_d(b')
  -\beta^d\mathcal H_d.
  \tag{JD-duration}
\]
Changing \(d\) can change:

- the discount factor \(\beta^d\);
- the joint descendant-event law \(\eta_{q,g,d}\);
- terminal-belief occupancy;
- the completion continuation floor \(G_d\);
- the probability and severity of omitted harmful outcomes;
- incumbent operating rewards earned or forgone during research; and
- the passive completion date entering \(A^{\mathrm{op}}_d\).

Therefore duration has no unconditional sign. In particular, the product-law
shortcut \(\pi\rho^d\mu_{q,d}\) cannot be used when duration changes the
coupling.

A narrow conditional comparison remains valid: if
\(\kappa\), \(A^{\mathrm{op}}\), \(\eta\), \(G\), and \(\mathcal H\) are held
fixed, then \(0\le\beta\le1\) makes the guarantee weakly decreasing in \(d\).
More generally, delay antitonicity follows if the complete adjusted gross
term
\[
  A^{\mathrm{op}}_d
  +\beta^d\bigl[S(\eta_d,G_d)-\mathcal H_d\bigr]
\]
is itself weakly decreasing. That is a sufficient comparison condition, not
an unconditional duration theorem.

## 9. Lean implementation and claim audit

The implementation reuses the current unified completion law and
project-action identity; it adds no second transition model.

| Lean object | Verified role |
|---|---|
| `jointDescendantMass` | \(\eta_{q,g}(b'\mid b,K)\) |
| `expectedJointDescendantGain` | \(\sum_{b'}\eta_{q,g}(b')G(b')\) |
| `JointGenerativeCarrierCertificate` | current carrier certificate without `conditional_independence`, `generation_probability`, or scalar `admission_probability`; retains all comparator fields and adds the joint-event gain floor |
| `jointDescendant_expectedGain_le` | lower-bounds the complete continuation expectation by the distinguished joint-event term |
| `generativeInsertionValue_lowerBound_joint` | theorem (JD-theorem) |
| `generativeInsertionValue_lowerBound_joint_terminalWeighted` | terminal sum form of (JD-theorem) |
| `expectedJointDescendantGain_eq_independentProduct` | derives the \(\pi\rho^d\) occupation product under the old independence certificate |
| `generativeInsertionValue_lowerBound_with_operatingAdjustment` | recovers the old product formula by invoking the joint theorem first |
| `jointGenerativeLowerBound_eq_zero_iff`, `jointGenerativeLowerBound_pos_iff` | Section 7 sign conditions |
| `jointGenerativeLowerBound_mono_mass`, `jointGenerativeLowerBound_mono_gainFunction`, `jointGenerativeLowerBound_antitone_researchCost`, `jointGenerativeLowerBound_mono_operatingAdjustment` | Section 7 monotonicities |
| `CarrierExample.exact_joint_carrier_lowerBound_one` | exact kernel-checked joint carrier fixture |

The joint certificate retains:

- `frontier_silent`;
- `project_enabled`;
- `project_unavailable_without`;
- `duration_fits`;
- `researchCost_eq`;
- `deleted_premium_zero`;
- nonnegativity of \(G\); and
- the distinguished-event completion-gain floor.

It removes `ConditionalIndependence` from the primary theorem. The old
generation, admission, survival, and independence fields belong only in an
adapter that proves (JD-product-specialization).

The proof derives nonnegative omitted outcomes from
`library_le_rawLibraryUpdate`,
`passiveValue_mono_of_library_inclusion`, and
`passiveValue_le_fullValue`. The harmful-outcome formula
(JD-harmful), the path-memory extension, and the multi-descendant sum remain
explicit specification/Julia extensions rather than claims about the current
insertion-only Lean interface.

The claim gate records a clean Lean build, the 63-declaration compatibility
T6 audit, the 31-declaration dedicated joint-law audit, prohibited-placeholder
and `unsafe` scans, line-by-line ledger and
assumption reconciliation, manuscript replacement of independence in the
primary theorem, and exact correlated fixtures for which the joint and
product-of-marginals calculations differ. Each audited T6 declaration reports
only the accepted standard foundations `propext`, `Classical.choice`, and
`Quot.sound`, or fewer.

## 10. Preservation and claim boundary

- Frontier silence is unchanged.
- The project remains enabled only after insertion.
- The deleted comparator must still have zero research-option premium.
- Initiation cost is subtracted exactly once.
- The operating-timing adjustment is displayed and never silently discarded.
- Failure and other outcomes are omitted only under proved nonnegativity or
  an explicit harmful-outcome correction.
- The primary theorem imposes no independence assumption.
- The current product formula is retained as a strict corollary.
- Pointwise joint-mass and gain monotonicities are ceteris paribus statements,
  not comparative statics for an unrestricted change in the full coupling.
- Duration has no unconditional sign when it changes the joint law,
  occupancy, continuation gains, harmful-outcome correction, or operating
  rewards.
- The terminal \(G(b')\) is a supportwise minimum over complete continuation
  gains; a direct payoff or path average is insufficient.
- A positive comparator requires (JD-positive-comparator), and a
  multi-descendant strengthening sums only disjoint admitted-outcome events.
- No existing Lean declaration, exact fixture, randomized-library result, or
  locked negative or mixed financial audit is changed by this specification.
