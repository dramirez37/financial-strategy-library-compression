# Local Versus Global Innovation-Safe Compression

## Status and claim boundary

This document fixes the conceptual role of innovation-safe deletion inside
the exact safe-compression problem \(P_{\mathrm{safe}}(L)\). It does not
change the productive raw process, the existing T1--T3 statements, or the
definition of \(P_{\mathrm{safe}}(L)\).

The single-step and rechecked-trace safety results exist in the productive
theorem layer. The resource-dominance interpretation, global-minimum-to-one-
deletion implication, endpoint feasibility, unit nonglobal endpoint, and
strict-heaviest failure now have exact Lean declarations. The minimized
records are
CX-OPT-PRUNE-CARDINALITY-01, CX-OPT-PRUNE-WEIGHT-01,
CX-OPT-GREEDY-WEIGHT-01, CX-OPT-DELETION-ORDER-WEIGHT-01, and
CX-OPT-LOCAL-NONGLOBAL-01; the other minimized records remain Julia-only
unless named below as Lean counterparts.

## 1. Source problem

Fix an admissible finite source library \(L\) containing the inactive
strategy \(s_0\). Recall
\[
  \mathfrak F_{\mathrm{safe}}(L)
  =
  \left\{
    K\subseteq L:
    s_0\in K,
    F_K=F_L,
    C_K=C_L
  \right\}.
\]
The exact safe-compression problem is
\[
  P_{\mathrm{safe}}(L):
  \qquad
  \min_{K\in\mathfrak F_{\mathrm{safe}}(L)} W(K).
\]
For an active strategy \(s\in K\setminus\{s_0\}\), write
\[
  K^{-s}:=K\setminus\{s\}.
\]

## 2. Safe deletion certificate

A **safe deletion certificate** for \(s\) at the current library \(K\) is the
proof-relevant record
\[
  \mathsf{SafeDel}(K,s)
  :=
  \left(
    s\in K\setminus\{s_0\},\
    F_{K^{-s}}=F_K,\
    C_{K^{-s}}=C_K
  \right).
\]
The equalities are rechecked at \(K\), not inherited from an earlier or larger
library. The certificate is local to the ordered pair \((K,s)\).

Under the current T1/UDI sufficiency assumptions, this certificate also gives
productive dynamic equivalence and productive value equality between \(K\)
and \(K^{-s}\). Detectability is not needed for this forward implication.

### Direct feasibility implication

At the source library itself, if
\[
  F_{L^{-s}}=F_L,
  \qquad
  C_{L^{-s}}=C_L,
\]
then \(L^{-s}\in\mathfrak F_{\mathrm{safe}}(L)\). Thus \(L^{-s}\) is feasible
for \(P_{\mathrm{safe}}(L)\).

Because \(s\ne s_0\), the additive resource convention gives \(w_s>0\).
Since \(s\in L\),
\[
  W(L^{-s})
  =
  W(L)-w_s
  <
  W(L).
\]
Therefore \(L^{-s}\) strictly dominates \(L\) in
\(P_{\mathrm{safe}}(L)\). A library containing a safely deletable
positive-weight strategy cannot be a globally minimum-weight safe library.

The same argument applies at any safe-feasible intermediate library. If
\(K\in\mathfrak F_{\mathrm{safe}}(L)\) and
\(\mathsf{SafeDel}(K,s)\), then
\[
  K^{-s}\in\mathfrak F_{\mathrm{safe}}(L),
  \qquad
  W(K^{-s})<W(K).
\]

## 3. Feasible reduction

A library \(K'\) is a **feasible reduction** of \(K\), relative to source
\(L\), when
\[
  K',K\in\mathfrak F_{\mathrm{safe}}(L),
  \qquad
  K'\subsetneq K.
\]
Write
\[
  K'\prec_{\mathrm{safe},L}K.
\]

A certified single deletion from a safe-feasible \(K\) produces the feasible
reduction \(K^{-s}\prec_{\mathrm{safe},L}K\). A feasible reduction need not
come with a single-deletion trace; it is a comparison between two points in
the global feasible set.

With strictly positive active weights, inclusion gives strict resource
improvement:
\[
  K'\prec_{\mathrm{safe},L}K
  \quad\Longrightarrow\quad
  W(K')<W(K).
\]

## 4. Stepwise safe-deletion traces

A **stepwise safe-deletion trace** from \(L_0=L\) is a finite sequence
\[
  L_0,L_1,\ldots,L_T
\]
with active strategies \(s_t\in L_t\setminus\{s_0\}\) such that
\[
  L_{t+1}=L_t^{-s_t}
\]
and \(\mathsf{SafeDel}(L_t,s_t)\) is supplied for every
\(t=0,\ldots,T-1\).

Each certificate is evaluated against the current intermediate library. A
collection of deletion certificates evaluated only at \(L_0\) is not a
trace certificate and does not justify simultaneous deletion.

### Trace feasibility

For every \(t\),
\[
  F_{L_t}=F_{L_0},
  \qquad
  C_{L_t}=C_{L_0}.
\]
Hence
\[
  L_t\in\mathfrak F_{\mathrm{safe}}(L_0)
\]
at every step. The proof is induction using equality transitivity.

Resource burden strictly decreases at every nonempty step:
\[
  W(L_{t+1})
  =
  W(L_t)-w_{s_t}
  <
  W(L_t).
\]
Thus a trace is simultaneously:

- a sequence of productive-state-preserving transformations;
- a path through the feasible set of the original
  \(P_{\mathrm{safe}}(L_0)\); and
- a strictly descending resource path.

Finiteness of \(L_0\) makes every procedure that continues deleting terminate
after at most \(|L_0|-1\) active deletions. It does not make an arbitrarily
stopped trace irreducible.

## 5. Inclusion-wise irreducible safe libraries

A safe-feasible library \(K\in\mathfrak F_{\mathrm{safe}}(L)\) is
**one-deletion irreducible** if
\[
  \forall s\in K\setminus\{s_0\},\qquad
  \neg\mathsf{SafeDel}(K,s).
\]

It is **inclusion-wise irreducible relative to \(L\)** if
\[
  K\in\mathfrak F_{\mathrm{safe}}(L)
\]
and there is no \(K'\in\mathfrak F_{\mathrm{safe}}(L)\) with
\(K'\subsetneq K\).

Under the current monotone frontier and closure constructions, these two
notions coincide. To see the nontrivial direction, suppose a strict feasible
sublibrary \(K'\subsetneq K\) exists. Choose
\(s\in K\setminus K'\). Then
\[
  K'\subseteq K^{-s}\subseteq K.
\]
Frontier monotonicity and closure monotonicity sandwich the intermediate
frontier and closure between equal endpoints:
\[
  F_{K'}=F_K,
  \qquad
  C_{K'}=C_K.
\]
Therefore \(F_{K^{-s}}=F_K\) and \(C_{K^{-s}}=C_K\), contradicting
one-deletion irreducibility.

A trace is **complete** when its endpoint \(L_T\) admits no safe deletion
certificate. Only a complete trace has an inclusion-wise irreducible
endpoint. The existing rechecked-trace theorem proves safety of every step;
terminal irreducibility is an additional completeness property of the
deletion procedure.

## 6. Globally minimum-weight safe libraries

A library \(K^\star\) is a **globally minimum-weight safe library** for source
\(L\) when
\[
  K^\star
  \in
  \operatorname*{argmin}_{K\in\mathfrak F_{\mathrm{safe}}(L)}
  W(K).
\]
Equivalently,
\[
  K^\star\in\mathfrak F_{\mathrm{safe}}(L)
  \quad\text{and}\quad
  W(K^\star)\le W(K)
  \quad
  \text{for every }K\in\mathfrak F_{\mathrm{safe}}(L).
\]

Every globally minimum-weight safe library is inclusion-wise irreducible.
Otherwise a feasible reduction would have strictly lower burden.

The converse is not assumed. Inclusion-wise irreducibility rules out only
strictly smaller feasible sublibraries of the endpoint. Global optimality
compares the endpoint with every safe-feasible sublibrary of the source,
including incomparable libraries reached by different deletion choices.

Innovation-safe deletion is therefore a certified feasible-reduction method,
not by itself a global optimization algorithm.

## 7. Exact status of the proposed statements

1. **Every stepwise safe-deletion trace remains feasible.** Yes, provided
   safety is rechecked at every intermediate library. Existing T3 already
   proves preservation of compressed state and productive value along such a
   trace. `Optimization.recheckedSafeDeletionEndpoint_feasible` is the exact
   \(P_{\mathrm{safe}}\)-feasibility wrapper.

2. **The final library is inclusion-wise irreducible under one-strategy
   deletion.** Yes only for a complete trace whose endpoint admits no safe
   deletion certificate. It is false as phrased for an arbitrary trace that
   is allowed to stop early.

3. **The final irreducible library need not be globally minimum weight.**
   Yes. The unit-weight bundle-versus-singletons construction is now a Lean
   counterexample, while CX-OPT-LOCAL-NONGLOBAL-01 remains a smaller exact
   Julia witness. The positive one-way implication from global minimum to
   one-deletion irreducibility is Lean verified.

4. **Different deletion orders can yield different feasible endpoints.**
   Yes. CX-OPT-DELETION-ORDER-WEIGHT-01 uses two duplicate carriers of weights
   one and two. The two complete orders end at burdens two and one while
   preserving the same source frontier and closure.

5. **Equal compressed states imply equal productive value but not equal
   resource burden.** Productive value equality follows through the existing
   T1/UDI layer. Resource equality does not follow because \(w_s\) is an
   independent catalog primitive; this is the existing D-0111 and
   CX-RESOURCE-K-NET-01 boundary. No new resource theorem is claimed here.

## 8. Deletion order and greedy rules

The phrase “greedy safe deletion” is incomplete until its selection rule is
specified. This specification distinguishes:

- **fixed-order rechecked deletion:** scan a declared priority order and
  delete the first currently certified strategy;
- **maximum-burden rechecked deletion:** among currently certified
  strategies, delete one with maximum \(w_s\), using a declared tie breaker;
  and
- **global safe compression:** enumerate or otherwise optimize over all of
  \(\mathfrak F_{\mathrm{safe}}(L)\).

The first two rules return safe endpoints when every step is rechecked. They
have no automatic approximation ratio and no automatic global-optimality
guarantee. A failure claim for either rule requires an exact witness tied to
that precise rule.

## 9. Exact minimized witnesses

### Witness A — unequal-weight duplicate representatives

Use one belief, identity closure, one module \(m\), and source
\[
  L_A=\{s_0,a,c\}.
\]
The exact catalog rows are:

| Strategy | Operational profile | Modules | Resource weight |
|---|---:|---|---:|
| \(s_0\) | \(0\) | \(\varnothing\) | \(0\) |
| \(a\) | \(0\) | \(\{m\}\) | \(1\) |
| \(c\) | \(0\) | \(\{m\}\) | \(2\) |

Exact enumeration verifies that:

- deleting \(a\) first produces endpoint \(\{s_0,c\}\);
- deleting \(c\) first produces endpoint \(\{s_0,a\}\);
- both traces preserve the source frontier and closure;
- both endpoints are inclusion-wise irreducible;
- their burdens are respectively \(2\) and \(1\); and
- fixed-order deletion with \(a\) first returns a heavier endpoint than the
  global safe optimum.

This two-active carrier is minimal for unequal raw endpoints. It is recorded
separately under CX-OPT-PRUNE-WEIGHT-01,
CX-OPT-DELETION-ORDER-WEIGHT-01, and CX-OPT-LOCAL-NONGLOBAL-01 because the
three rejected implications are logically distinct.

### Witness B — bundle carrier versus singleton carriers

Use one belief, identity closure, modules
\[
  M=\{m_1,m_2\},
\]
and source
\[
  L_B=\{s_0,x_1,x_2,a\}.
\]
All operational profiles are zero. The exact module and weight rows are:

| Strategy | Modules | Resource weight |
|---|---|---:|
| \(s_0\) | \(\varnothing\) | \(0\) |
| \(a\) | \(\{m_1,m_2\}\) | \(3\) |
| \(x_1\) | \(\{m_1\}\) | \(2\) |
| \(x_2\) | \(\{m_2\}\) | \(2\) |

Exact enumeration verifies two complete rechecked outcomes:

1. the unique-heaviest-safe-first rule deletes \(a\), producing endpoint
   \(\{s_0,x_1,x_2\}\) of burden \(4\); and
2. deleting the singleton carriers produces endpoint
   \(\{s_0,a\}\) of burden \(3\).

Both endpoints preserve the source frontier and closure and are
inclusion-wise irreducible. The bundle-only library is the unique global
minimum-weight safe library. Exhaustive search through two active strategies
rules out a smaller strict-maximum greedy failure. This is
CX-OPT-GREEDY-WEIGHT-01.

The unit-weight version of the same two-module, three-active carrier is
CX-OPT-PRUNE-CARDINALITY-01: deleting the bundle first leaves two active
singletons while the bundle alone is the global minimum-cardinality safe
library.

## 10. Exact-search record

The completed Julia search:

1. instantiated the finite catalog, inactive row, identity closure, and
   positive rational resource table;
2. enumerated every inactive-containing sublibrary of the source;
3. computed frontier equality, closure equality, and \(W\) exactly;
4. identified the complete set
   \(\mathfrak F_{\mathrm{safe}}(L)\) and all global minimizers;
5. replayed each proposed deletion order with safety rechecked after every
   deletion;
6. verified endpoint inclusion-wise irreducibility by testing every remaining
   active strategy;
7. implemented the named greedy selection rule and its tie breaker exactly;
8. minimized the witness subject to the requested properties; and
9. saved the catalog, traces, feasible set, burdens, optimizer set, and command
   provenance as a reproducible fixture.

The configuration is
`experiments/configs/resource_optimization_counterexamples.toml`, the complete
machine-readable result is
`experiments/results/resource_optimization_claim_audit.json`, and individual
fixtures 01--04 are under
`experiments/results/resource_optimization_fixtures/`. `--check` reproduces
them byte for byte. Fixtures CX-OPT-PRUNE-CARDINALITY-01 and
CX-OPT-GREEDY-WEIGHT-01 now also have exact, separately axiom-audited Lean
counterparts; no such status transfers automatically to the other fixtures.

## Definition freeze

For the next implementation step:

1. a safe deletion certificate is current-library-relative;
2. every certified active deletion is a strict feasible resource reduction;
3. a trace must recheck safety after every deletion;
4. only complete traces have irreducible endpoints;
5. global optimality compares all safe-feasible sublibraries of the source;
6. local irreducibility does not carry a global-optimality claim;
7. every greedy rule must specify its selection and tie-breaking rule; and
8. the exact weighted witnesses carry Julia-validation status only.
