# Appendix-Ready Proof: Complexity of Exact Safe Compression

## Status

This is the complete human proof of proposed theorem SC-COMP. It is ready for
the optimization appendix after the repository's Lean claim gate is met. It
is not itself a Lean verification.

## Theorem SC-COMP

Consider the finite exact safe-compression decision problem with
binary-encoded rational profiles, nonnegative binary-encoded rational
weights, an inactive zero policy, an explicitly listed finite source
library, and a rational budget. Under identity module closure:

1. the joint decision problem is NP-complete;
2. frontier preservation alone is NP-complete;
3. closure preservation alone is exactly weighted set cover and is
   NP-complete; and
4. all three optimization problems are NP-hard, including their unit-weight
   minimum-cardinality restrictions.

More generally, every closure representation class that contains identity
closure inherits these NP-hardness results. If its closure equality predicate
is polynomial-time decidable, its safe-compression decision problem is
NP-complete.

## Proof

### Step 1: membership in NP

A certificate is the \(n\)-bit incidence vector of the retained active
policies; the inactive policy is mandatory and need not be encoded. For
identity closure, scan the selected rows to compute:

\[
 \max_{s\in K}j_s(b)\quad(b\in B),\qquad
 \bigcup_{s\in K}M_s,\qquad
 \sum_{s\in K}w_s.
\]

Compare the first two objects with the corresponding source objects and the
last with the budget. Maxima, unions, exact comparisons, and sums of
binary-encoded rationals require polynomially many bit operations. Rational
addition can increase the bit length by at most the sum of the input bit
lengths, which is polynomial in the explicit input. Hence the identity-
closure decision problem belongs to NP.

The same argument applies to a general closure encoding whenever closure
evaluation and equality are polynomial-time operations for that encoding.

### Step 2: frontier preservation is a hitting condition

Let \(F_L\) be the source frontier. Since the inactive policy is retained and
has profile zero, \(F_L(b)\ge0\). If \(F_L(b)=0\), the inactive policy already
preserves the frontier at \(b\). If \(F_L(b)>0\), define
\[
 T_b=\{s\in L\setminus\{s_0\}:j_s(b)=F_L(b)\}.
\]
Because \(K\subseteq L\), it cannot exceed the source frontier. It equals the
source frontier at \(b\) if and only if \(K\) contains at least one member of
\(T_b\). Thus exact frontier preservation is precisely the requirement that
the selected active policies hit every nonautomatic attainer set \(T_b\).

### Step 3: identity-closure preservation is a hitting condition

With identity closure, let
\[
 U_L=\bigcup_{s\in L}M_s,\qquad
 P_m=\{s\in L\setminus\{s_0\}:m\in M_s\}\quad(m\in U_L).
\]
Again \(K\subseteq L\), so its module union cannot contain an outside module.
It equals \(U_L\) if and only if \(K\) contains at least one member of every
\(P_m\). Therefore joint exact safety is weighted hitting set on
\[
 \{T_b:F_L(b)>0\}\cup\{P_m:m\in U_L\}.
\]
Equivalently, each policy is a weighted set covering the belief and module
obligations it attains or carries. This proves the exact combined-cover
characterization.

### Step 4: polynomial reduction to the closure-only restriction

Reduce from weighted set cover. Let its universe be
\(U=\{e_1,\ldots,e_q\}\), its listed subsets be
\(A_1,\ldots,A_n\), its positive rational weights be
\(w_1,\ldots,w_n\), and its budget be \(R\). Restrict without loss to
instances with \(\bigcup_iA_i=U\); a noncovering source instance is an
immediate no-instance and can be mapped to any fixed no-instance.

Create one belief \(b_\circ\), one active policy \(s_i\) for each \(A_i\),
and the inactive policy. Give every policy the zero profile. Use module
universe \(U\), module row \(M_{s_i}=A_i\), identity closure, and policy
weight \(w_i\).

Every candidate sublibrary preserves the zero frontier, while
\[
 C_K=U
 \quad\Longleftrightarrow\quad
 \bigcup_{s_i\in K}A_i=U.
\]
Moreover \(W(K)=\sum_{s_i\in K}w_i\). Thus a cover of weight at most \(R\)
exists if and only if a closure-preserving sublibrary of weight at most
\(R\) exists. The construction contains \(n+1\) policies, one belief, \(q\)
modules, and the original incidence matrix, so it is polynomial.

This proves NP-hardness of the closure-only restriction. Together with Step 1
it proves NP-completeness. It also shows an exact equivalence in the reverse
direction: every closure-only identity instance is weighted set cover on
universe \(U_L\) with policy rows \(M_s\).

### Step 5: polynomial reduction to the frontier-only restriction

From the same set-cover instance, create one belief \(b_e\) per
\(e\in U\), one active policy \(s_i\) per \(A_i\), and the inactive policy.
Give \(s_i\) the binary profile
\[
 j_{s_i}(b_e)=1_{\{e\in A_i\}}.
\]
Give every policy an empty module row and use identity closure on an inert
dummy module carrier. Preserve the weights.

Since \(\bigcup_iA_i=U\), the source frontier equals one at every belief. For
any selected sublibrary \(K\),
\[
\begin{aligned}
 F_K=F_L
 &\Longleftrightarrow
   \forall e\in U,\ \exists i\text{ with }s_i\in K\text{ and }e\in A_i\\
 &\Longleftrightarrow
   \{A_i:s_i\in K\}\text{ covers }U.
\end{aligned}
\]
The module condition is automatic and weight is preserved. The construction
is the transpose-free reuse of the listed incidence matrix and is
polynomial. Frontier-only safe compression is therefore NP-hard and, by Step
1, NP-complete.

These binary profiles also have a literal finite-state realization: take one
hidden state per element, use degenerate beliefs, and give policy \(s_i\)
state payoff \(1_{\{e\in A_i\}}\).

### Step 6: joint restriction and unit weights

For a direct joint reduction, retain the profiles from Step 5 and give policy
\(s_i\) module row \(A_i\). Both the frontier obligations and the module
obligations are satisfied exactly by set covers. Hence the joint problem is
NP-hard; Step 1 makes it NP-complete.

Ordinary unweighted set cover is the unit-weight special case. Therefore all
three reductions remain NP-hard when every active policy has the same
positive weight. The associated optimization problems are NP-hard because a
polynomial optimization algorithm would answer the budgeted decision problem
by comparing its optimum with \(R\).

### Step 7: general closure

Identity is an extensive, monotone, idempotent closure operator. Any general-
closure representation class capable of encoding identity closure therefore
contains every hard instance above and is NP-hard. If that class also
supports polynomial-time closure equality verification, the certificate
argument in Step 1 gives membership in NP and hence NP-completeness.

Without an encoding or evaluation bound for the closure operator, there is no
single finite language whose membership in NP can be assessed. In
particular, the claim is not that an arbitrarily supplied closure oracle is
polynomial.

This completes the proof. \(\square\)

## Sharp special-case boundaries

The following consequences help delimit the theorem.

### Proposition 1: one frontier belief

For frontier-only compression with one belief, retain only the inactive
policy if the source frontier is zero. Otherwise retain a cheapest policy
attaining the positive source frontier. This is optimal because feasibility
requires at least one maximizer and one maximizer suffices.

The statement does not extend to the joint problem: Step 4 already uses one
belief and retains closure-only NP-hardness.

### Proposition 2: unique maximizers

If every positive-frontier belief has a unique active source maximizer, every
such maximizer is forced. Their union is the unique inclusion-minimal
frontier-preserving active set, so the frontier-only optimum is immediate.
Residual closure obligations in the joint problem may still encode weighted
set cover.

Exactly two maximizers do not suffice. Given a graph, create one policy per
vertex and one belief per edge, with the two endpoints as the only value-one
maximizers. Selecting policies that preserve all frontier entries is vertex
cover.

### Proposition 3: laminar identity-closure rows

For closure-only identity compression, suppose distinct policy module rows
form a laminar family. Consolidate duplicate rows by retaining their cheapest
policy. Order the remaining sets as an inclusion forest. At a node \(A\),
compare selecting \(A\) with optimally covering its maximal proper child
sets. If \(A\) contains an element outside those children, the child-only
option is infeasible. This bottom-up recurrence finds the minimum cover in
polynomial time.

Frontier attainer rows can cross this laminar forest, so laminarity of module
rows alone does not make the joint problem tractable.

### Proposition 4: bounded module incidence

If every required module has one carrier, that carrier is forced. Frequency
two is already weighted vertex cover: use one policy per graph vertex and one
module per edge, carried by its two endpoints. The case is polynomial when
this carrier graph is bipartite.

This differs from bounding the number of modules carried by one policy.
Closure-only weighted set cover with row size at most two reduces to a
minimum-weight edge-cover/matching computation and is polynomial.

### Proposition 5: matroid and tree closure

If closure is matroid span and each selectable policy carries exactly one
ground element, closure preservation asks for a minimum-weight spanning set.
Positive weights remove redundant dependent elements, so an optimum is a
minimum-weight basis and the matroid greedy algorithm applies.

Bundled rows invalidate this conclusion. Identity closure is the free-matroid
closure, and the closure-only reduction uses arbitrary bundles.

Likewise, for ancestor closure on a tree and one node per policy, the maximal
nodes of the target closed set are forced generators. With arbitrary policy
bundles, even an edgeless forest recovers identity-closure set cover.

### Proposition 6: few obligations

For identity closure, encode each nonautomatic frontier or module obligation
as a bit. A standard recurrence over policies and covered-obligation masks
finds the minimum weight in \(O(n2^d)\) time and \(O(2^d)\) space, where \(d\)
is the number of obligations. Thus the problem is fixed-parameter tractable
in \(d\) and polynomial for fixed \(d\).
