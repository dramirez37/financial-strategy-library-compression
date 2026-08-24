# Realizable Frontier–Closure Rectangle Construction

## Purpose and claim boundary

This note gives a raw-first method for producing the four corners

\[
L_{00}\mapsto(F_0,C_0),\qquad
L_{01}\mapsto(F_0,C_1),\qquad
L_{10}\mapsto(F_1,C_0),\qquad
L_{11}\mapsto(F_1,C_1),
\]

with \(F_0\le F_1\) pointwise and \(C_0\subseteq C_1\). Every \(L_{ij}\) is an
actual raw library in one shared strategy catalog and one shared module
system. The method never inserts an ambient compressed pair directly.

This is construction and exact Julia-validation infrastructure. It does not
change T7, prove a new interaction sign, or reclassify any registered
randomized, financial, negative, or mixed result.

## Raw primitives

Fix:

- one finite belief space \(B\);
- one finite module universe \(M\);
- one strategy catalog \(S\), including the inactive zero strategy;
- one closure operator \(\operatorname{cl}:2^M\to2^M\);
- for each strategy \(s\), an operational profile \(u_s:B\to\mathbb Q\) and
  supplied module set \(M_s\); and
- one admissible base library \(L_{00}\).

Write

\[
F_L(b)=\max_{s\in L}u_s(b),\qquad
U_L=\bigcup_{s\in L}M_s,\qquad
C_L=\operatorname{cl}(U_L).
\]

Choose two nonempty, finite, disjoint sets of catalog strategies absent from
\(L_{00}\):

1. frontier strategies \(A_F\); and
2. closure carriers \(A_C\).

A simple sufficient primitive certificate, written for one representative
\(s_F\in A_F\) and \(s_C\in A_C\), is:

\[
\begin{aligned}
F_0&=F_{L_{00}},&
C_0&=C_{L_{00}},\\
F_1&=\max\{F_0,u_{s_F}\},&
M_{s_F}&\subseteq C_0,\\
u_{s_C}&\le F_0,&
C_1&=\operatorname{cl}(U_{L_{00}}\cup M_{s_C}),\\
C_0&\subseteq C_1.&&
\end{aligned}
\]

Every carrier can be module-only, \(u_{s_C}=0\), or merely frontier-silent,
\(u_{s_C}\le F_0\). Every frontier strategy may have no modules, which is the
most transparent implementation of \(M_{s_F}\subseteq C_0\). With multiple
additions, replace the displayed maximum and unions by their finite iterated
versions.

## Corner algorithm

Construct only raw libraries:

\[
\begin{aligned}
L_{00}&=L_{\mathrm{base}},\\
L_{01}&=L_{00}\cup A_C,\\
L_{10}&=L_{00}\cup A_F,\\
L_{11}&=L_{00}\cup A_C\cup A_F.
\end{aligned}
\]

Then call the ordinary compression map on each library:

\[
K_{ij}=\bigl(F_{L_{ij}},C_{L_{ij}}\bigr).
\]

No \(K_{ij}\) is accepted as an input.

The frontier identities follow from pointwise maxima:

\[
F_{L_{01}}=\max(F_0,u_{s_C})=F_0,\qquad
F_{L_{11}}=\max(F_1,u_{s_C})=F_1.
\]

The closure identities follow from the closure laws. Because \(C_0\) and
\(C_1\) are closed, \(M_{s_F}\subseteq C_0\subseteq C_1\) makes \(s_F\)
closure-silent on both horizontal edges:

\[
C_{L_{10}}=C_0,\qquad C_{L_{11}}=C_1.
\]

Thus the additions commute at the raw-library level and compress to the
required rectangle.

The implementation accepts this sufficient design and any weaker design that
passes the four actual edge equalities. It rejects a proposed construction if
the closure carrier changes either frontier or the frontier strategy changes
either closure.

## Derived projects, menus, transitions, and values

After the four libraries exist, build one `RawInnovationProcess` from the same
catalog and closure system. For every corner, project behavior is evaluated
against its computed state \(K_{ij}\):

\[
\mathcal A(K_{ij})
 =\{\text{Continue}\}\cup
   \{q:R_q\subseteq C_{L_{ij}}\}.
\]

Generation, verification, cost, and the joint completion law receive the
corner's actual closure or actual compressed image. The raw update inserts the
admitted catalog strategy into \(L_{ij}\). Consequently:

- action menus come from project requirements and \(C_{L_{ij}}\);
- raw embedded transitions come from generation, admission, completion, and
  raw insertion;
- compressed transitions are pushforwards of those raw laws; and
- finite-horizon values and maximizing actions are computed by the raw
  Bellman recursion.

The rectangle generator does not accept menus, transition matrices, action
values, selected actions, or corner values as arguments.

## Julia API

`julia/src/RealizableRectangles.jl` provides:

- `construct_realizable_rectangle`, which takes a catalog, closure, base raw
  library, and nonempty collections of frontier-strategy and closure-carrier
  IDs; a scalar convenience method handles one of each;
- `rectangle_libraries` and `rectangle_states`, with the latter recomputing
  all compressed images from raw libraries;
- `rectangle_action_menus`, derived from project requirements;
- `rectangle_raw_transitions`, derived from the raw embedded process;
- `rectangle_raw_values`, derived from the raw finite-horizon Bellman
  recursion; and
- `rectangle_consistency`, which audits all four corners and the
  raw-to-compressed pushforward/value identities.

The following exact deterministic generators are also public:

- `exact_identity_rectangle_fixture()`: identity closure with a zero-profile
  module-only carrier; and
- `exact_generated_closure_rectangle_fixture()`: a nonzero but
  frontier-silent carrier supplies `trigger`, from which the closure operator
  derives `bridge`.

`exact_realizable_rectangle_fixtures()` returns both.

Both fixtures use exact `Rational{BigInt}` primitives and the same construction
pattern:

| Item | Identity fixture | Generated-closure fixture |
|---|---|---|
| \(F_0\) | \((2,3)\) | \((2,3)\) |
| \(F_1\) | \((4,5)\) | \((4,5)\) |
| \(C_0\) | `{core}` | `{core}` |
| carrier raw modules | `{expansion}` | `{trigger}` |
| \(C_1\) | `{core, expansion}` | `{core, trigger, bridge}` |
| carrier profile | \((0,0)\) | \((1,2)\le F_0\) |
| rich-project requirement | `{expansion}` | `{bridge}` |

The second fixture is deliberately nontrivial: `bridge` is absent from the
raw module union at \(L_{01}\) and is present only in its derived closure.

## Consistency gate

A generated fixture is accepted only if all of the following pass:

1. all four libraries validate against the one catalog and contain the
   inactive strategy;
2. the two raw insertions commute and produce the recorded \(L_{11}\);
3. both frontier-edge and both closure-edge identities hold;
4. \(F_0\le F_1\) and \(C_0\subseteq C_1\);
5. all four libraries occur in the raw process's enumerated carrier;
6. project availability equals the requirement-subset test on each actual
   corner closure;
7. every raw embedded transition pushes forward to the compressed transition;
   and
8. raw and compressed finite-horizon values and maximizing actions agree at
   every corner and belief.

Constructor-level catalog, closure, probability, duration, reference, and
joint-marginal checks remain in force. A failed item raises an error or makes
`rectangle_consistency(...).all_pass` false; it is not repaired by inserting
a compressed corner manually.
