# Complexity Audit for Exact Safe Compression

## Verdict

The finite exact problem has a clean complexity classification once its input
representation is fixed.

1. With identity module closure, the budgeted decision version of exact safe
   compression is NP-complete. Hence minimum-weight exact safe compression is
   NP-hard.
2. Frontier preservation alone is NP-complete, even with binary profiles,
   identity closure carrying no modules, and unit weights.
3. Closure preservation alone under identity closure is exactly weighted set
   cover. It is NP-complete in decision form, even with one belief and zero
   operational profiles.
4. Under identity closure, the combined problem is one weighted hitting-set
   instance whose hyperedges are the frontier-attainer sets and the module-
   carrier sets.
5. General closure remains NP-hard because identity closure is a special
   case. The decision problem is NP-complete when the chosen representation
   permits polynomial-time closure evaluation. Without a closure
   representation and evaluation bound, a uniform NP-membership statement is
   not well posed.

These are finite combinatorial results. They do not depend on the dynamic
innovation process, Bellman equations, or floating-point calculations.

## Claim status

This audit and `SAFE_COMPRESSION_COMPLEXITY_APPENDIX_PROOF.md` give a complete
paper-level polynomial reduction. The exact Julia fixture checks the
construction on finite instances, including every candidate sublibrary in an
exhaustive small-instance sweep.

There is no Lean complexity declaration or axiom audit. Accordingly:

- SC-COMP is a proposed theorem with a complete human proof;
- the executable fixture is validation of the construction, not a universal
  proof; and
- the active manuscript is not changed to call NP-hardness proved or Lean
  verified.

## 1. Finite exact decision problem

Let the input contain:

- a finite belief set \(B\);
- a finite source library
  \(L=\{s_0,s_1,\ldots,s_n\}\), with mandatory inactive policy \(s_0\);
- binary-encoded nonnegative rational weights \(w_i\) for active policies;
- binary-encoded rational profiles \(j_i(b)\);
- finite module rows \(M_i\subseteq M\); and
- a representation of a closure operator
  \(\operatorname{cl}:2^M\to2^M\).

The inactive policy has weight zero, profile zero, and an empty module row.
For \(K\subseteq L\) containing \(s_0\), define
\[
 F_K(b)=\max_{s\in K}j_s(b),\qquad
 C_K=\operatorname{cl}\!\left(\bigcup_{s\in K}M_s\right),\qquad
 W(K)=\sum_{s\in K}w_s.
\]

The decision problem `SAFE-COMPRESSION` asks, for a rational budget \(R\),
whether there is an admissible \(K\subseteq L\) such that
\[
 F_K=F_L,\qquad C_K=C_L,\qquad W(K)\le R.
\]

For identity closure, a proposed policy mask is a polynomial-size
certificate. Frontier equality, module-union equality, and a binary-rational
weight sum are computable in polynomial time. Thus the identity-closure
decision problem is in NP.

For a general closure representation, the same verification is polynomial
provided both required closure evaluations and their equality test are
polynomial in the encoded input size. Examples include identity closure, an
explicit closure table measured as part of the input, and finite Horn
implications evaluated by forward chaining.

## 2. Identity closure is one weighted cover problem

Fix a source library \(L\) and let closure be the identity. For each belief
whose source frontier is positive, define its active attainer set
\[
 T_b=\{s\in L\setminus\{s_0\}:j_s(b)=F_L(b)\}.
\]
No obligation is needed when \(F_L(b)=0\), because \(s_0\) is retained and
attains zero. For each module in the source union, define its carrier set
\[
 P_m=\{s\in L\setminus\{s_0\}:m\in M_s\}.
\]

Then \(K\) is exactly safe if and only if its active policies hit every set
in
\[
 \mathcal H_L=
 \{T_b:F_L(b)>0\}\ \cup\
 \{P_m:m\in\bigcup_{s\in L}M_s\}.
\]
Equivalently, put one obligation on each relevant belief and source module,
and let policy \(s\) cover the obligations for which \(s\in T_b\) or
\(s\in P_m\). The exact integer program is
\[
\begin{aligned}
 \min\quad &\sum_{s\ne s_0}w_sx_s\\
 \text{s.t.}\quad
 &\sum_{s\in T_b}x_s\ge1
   &&(b\in B,\ F_L(b)>0),\\
 &\sum_{s\in P_m}x_s\ge1
   &&\left(m\in\bigcup_{s\in L}M_s\right),\\
 &x_s\in\{0,1\}.
\end{aligned}
\]

This is simultaneously a weighted hitting-set formulation on policy
vertices and a weighted set-cover formulation on the obligation universe.
It is an exact characterization, not a relaxation.

## 3. Explicit closure-only reduction

Take a weighted set-cover instance
\[
 U=\{e_1,\ldots,e_q\},\qquad
 A_1,\ldots,A_n\subseteq U,\qquad
 \bigcup_iA_i=U,
\]
with positive rational weights \(w_i\) and budget \(R\).

Construct a safe-compression instance as follows:

- one belief \(b_\circ\);
- inactive \(s_0\) and one active policy \(s_i\) per set \(A_i\);
- \(j_{s_i}(b_\circ)=j_{s_0}(b_\circ)=0\);
- module universe \(M=U\), row \(M_{s_i}=A_i\), and identity closure;
- policy weight \(w_{s_i}=w_i\).

Every admissible sublibrary preserves the zero frontier. Its closure equals
the source closure exactly when
\[
 \bigcup_{s_i\in K}A_i=U.
\]
The construction preserves the selected indices and their total weight.
Therefore the set-cover instance has a cover of weight at most \(R\) if and
only if the safe-compression instance has a closure-preserving sublibrary of
weight at most \(R\). The construction writes the incidence matrix once and
has polynomial size.

This also proves that arbitrary closure-only identity instances are weighted
set cover: the source module union is the cover universe and policy module
rows are its sets.

## 4. Explicit frontier-only reduction

Use the same weighted set-cover instance. Construct:

- one belief \(b_e\) for every element \(e\in U\);
- inactive \(s_0\) and one active policy \(s_i\) per set \(A_i\);
- binary profiles
  \[
    j_{s_i}(b_e)=
    \begin{cases}
      1,&e\in A_i,\\
      0,&e\notin A_i;
    \end{cases}
  \]
- no carried modules, with identity closure on an inert dummy module
  carrier; and
- policy weight \(w_{s_i}=w_i\).

Because the source set family covers \(U\), its frontier is one at every
belief. A selected sublibrary reproduces this frontier exactly when, for
every \(e\), it retains at least one \(s_i\) with \(e\in A_i\). This is
precisely set-cover feasibility, with weight unchanged.

Thus frontier preservation alone is NP-complete in decision form. The
reduction uses only \(0/1\) profiles and remains valid with unit weights,
which gives minimum-cardinality hardness. If a hidden-state realization is
desired, take hidden states indexed by \(U\), use the degenerate beliefs
\(\delta_e\), and assign policy payoff \(1_{\{e\in A_i\}}\).

A sharper boundary follows from vertex cover. Give one policy to each vertex
and one belief to each edge; exactly the two endpoint policies attain value
one at that belief. Hence frontier-only compression remains NP-hard when
every positive-frontier belief has exactly two maximizers. Unique
maximizers, not merely bounded multiplicity two, are the tractable boundary.

## 5. Combined reduction

The combined reduction may place both copies of each obligation in the same
instance:

- use the binary incidence profiles from the frontier reduction; and
- also give \(s_i\) the identity-closure row \(A_i\).

A selected policy family preserves both objects if and only if it covers
\(U\). The duplicated belief and module obligations do not change the
feasible masks or weights. This supplies a direct polynomial reduction to the
joint problem in addition to the two restricted-problem reductions.

## 6. Complexity theorem

### Theorem SC-COMP — Complexity of exact safe compression

Under the finite binary encoding above:

1. `SAFE-COMPRESSION` with identity closure is NP-complete, and its
   minimum-weight optimization problem is NP-hard.
2. The frontier-only restriction is NP-complete.
3. The closure-only identity-closure restriction is exactly weighted set
   cover and is NP-complete.
4. These statements remain NP-hard with unit weights.
5. The joint identity-closure problem is exactly the weighted hitting-set
   instance \(\mathcal H_L\) displayed above.
6. Any general-closure input class containing polynomially encoded identity
   closure is NP-hard. It is NP-complete if closure equality is verifiable in
   polynomial time for that class.

The reductions preserve the candidate mask and objective exactly. No
approximation, oracle, or pseudo-polynomial arithmetic assumption is used.

## 7. Identity versus general closure

Identity closure is additive at the module level:
\[
 C_K=\bigcup_{s\in K}M_s.
\]
That is why every module becomes an independent cover obligation.

For general closure,
\[
 C_K=\operatorname{cl}\!\left(\bigcup_{s\in K}M_s\right)
\]
can contain complementarities. For example, a Horn rule
\[
 a\wedge b\longrightarrow c
\]
can make \(c\) available only when policies carrying \(a\) and \(b\) are
selected together. Neither policy singly “covers” the derived module \(c\).
Consequently general closure preservation is not, in general, the
per-module weighted set-cover instance obtained from singleton carrier rows.
It is a minimum-weight grouped generator problem whose precise upper
complexity depends on how closure is represented and evaluated.

The lower bound is nevertheless unconditional for any general-closure model
class that includes identity closure.

## 8. Tractable and non-tractable special cases

| Restriction | Exact conclusion |
|---|---|
| \(d\) total nonautomatic identity obligations | Dynamic programming over obligation masks solves the problem in \(O(n2^d)\) time and \(O(2^d)\) space; fixed \(d\) is polynomial and the problem is FPT in \(d\). |
| Frontier-only, one belief | If the source frontier is zero, retain only the inactive policy. Otherwise retain a cheapest source maximizer. |
| Combined problem, one belief | Not sufficient for tractability: the closure-only reduction already uses one belief. |
| Unique active maximizer at every positive-frontier belief | All such maximizers are forced, so frontier-only compression is trivial after deduplication. In the combined problem, residual closure obligations can still encode set cover. |
| Exactly two frontier maximizers per belief | Not sufficient: the vertex-cover reduction has exactly two attainers per belief. The special case is polynomial when the resulting policy graph is bipartite. |
| Identity closure with laminar policy module rows | Closure-only optimization is polynomial by dynamic programming on the laminar inclusion forest after equal rows are consolidated at minimum weight. General frontier rows can cross the laminar family and restore hardness. |
| Module frequency one | Each required module forces its unique carrier; closure-only optimization is polynomial. |
| Module frequency two | Not sufficient: modules as graph edges and policies as vertices give weighted vertex cover. It is polynomial when that carrier graph is bipartite. |
| Each policy carries at most two modules | Unlike frequency two, this is a polynomial weighted edge-cover/matching case for closure-only identity compression. |
| Matroid closure, one module element per policy | Closure preservation is minimum-weight spanning set, hence a minimum-weight matroid basis, solvable greedily with an independence or rank oracle. |
| Matroid closure with arbitrary bundled module rows | Not sufficient: identity closure is the free-matroid closure, and bundled rows recover set cover. Frontier ties can also restore hitting-set hardness. |
| Ancestor closure on a dependency tree, one node per policy | The maximal target nodes are forced generators; choose the cheapest carrier of each, so closure-only compression is polynomial. |
| Tree dependencies with laminar subtree rows | Closure-only optimization admits a tree/laminar dynamic program. |
| Tree dependencies with arbitrary bundles | Not sufficient: an edgeless forest is identity closure, and arbitrary bundles recover set cover. |
| Fixed number of beliefs, frontier-only | Bit-mask dynamic programming over uncovered positive-frontier beliefs is polynomial for a fixed belief count. |

The two commonly confused bounded-incidence conditions therefore have
different behavior: “each module occurs in at most two policies” already
contains vertex cover, whereas “each policy carries at most two modules”
reduces to a matching-based cover problem.

## 9. Executable reduction fixture

The fixture uses exact `Rational{BigInt}` arithmetic:

- `julia/src/SafeCompressionComplexity.jl` implements the three polynomial
  constructors and the exact identity-obligation cover;
- `julia/scripts/verify_safe_compression_complexity_reductions.jl` emits a
  deterministic weighted-set-cover correspondence record;
- `julia/test/test_safe_compression_complexity.jl` checks all masks in the
  registered fixture and exhausts all 265 covering three-set/three-element
  incidence systems; and
- `experiments/results/safe_compression_complexity_reduction_fixture.json`
  records the closure-only, frontier-only, and combined correspondences.

The exhaustive small sweep checks 6,360 reduction/mask combinations. It is a
regression gate for the constructors, not evidence substituting for the
polynomial proof.

## 10. Manuscript disposition

A clean proof was obtained, so SC-COMP and an appendix-ready proof have been
added to the research specification. The active manuscript remains unchanged
under the repository claim policy. The planned optimization revision may add
the theorem to Section 4 and its proof to Appendix B only after a matching
Lean declaration builds, contains no prohibited placeholder, and receives a
recorded `#print axioms` audit.
