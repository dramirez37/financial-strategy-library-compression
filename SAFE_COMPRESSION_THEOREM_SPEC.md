# Exact Safe-Compression Theorem Specification

## Verdict and status

The seven-part safe-compression result below is valid in the exact finite
model. It combines:

- elementary finite-set and additive-weight arguments;
- the existing raw frontier--closure characterization of unified dynamic
  innovation equivalence;
- the existing finite-horizon, stationary-value, and stationary-action
  preservation results; and
- an exact finite counterexample to global optimality of stepwise pruning.

The complete paper-level argument is in
`SAFE_COMPRESSION_PROOF_OUTLINE.md`.

This document does not itself create a Lean verification claim. Subsequent
OPT-FND and OPT-T2T4 ledger entries now record building, axiom-audited Lean
declarations for parts 1--6: the resource domain, optimizer existence,
detectability-guarded feasibility equivalence, productive value/action
preservation, minimum-to-one-deletion irreducibility, rechecked endpoint
feasibility, and exact nonglobal endpoint and strict-heaviest boundaries. The
equal-weight corollary, generic inclusion-wise bridge, and one monolithic SC
declaration remain open.

## 1. Exact finite setting

Fix the following data.

1. \(B,S,M,Q\) are nonempty finite sets of beliefs, catalog strategies,
   modules, and research projects.
2. The catalog has a distinguished inactive strategy \(s_0\). Its
   operational profile is zero and its module row is empty.
3. Each \(s\in S\) has an exact rational operational profile
   \(j_s:B\to\mathbb Q\) and a finite module set
   \(\operatorname{mods}(s)\subseteq M\).
4. The module operator
   \[
     \operatorname{cl}:\mathcal P(M)\to\mathcal P(M)
   \]
   is extensive, monotone, and idempotent.
5. A raw library \(K\subseteq S\) is admissible when \(s_0\in K\).
6. Resource weights satisfy
   \[
     w:S\to\mathbb Q_{\ge0},\qquad
     w_{s_0}=0,\qquad
     s\ne s_0\Longrightarrow w_s>0,
   \]
   and library burden is additive:
   \[
     W(K):=\sum_{s\in K}w_s.
   \]

For every admissible library \(K\), define
\[
  F_K(b):=\max_{s\in K}j_s(b),
  \qquad
  C_K:=
  \operatorname{cl}\!\left(
    \bigcup_{s\in K}\operatorname{mods}(s)
  \right),
  \qquad
  \mathcal K(K):=(F_K,C_K).
\]

Fix an admissible finite source library \(L\). Its safe-feasible family is
\[
  \mathfrak F_{\mathrm{safe}}(L)
  :=
  \left\{
    K\subseteq L:
    s_0\in K,\quad
    F_K=F_L,\quad
    C_K=C_L
  \right\}.
\]
The exact equalities mean extensional equality of rational frontier functions
and equality of finite closed module sets.

The exact safe-compression problem is
\[
  P_{\mathrm{safe}}(L):
  \qquad
  \min_{K\in\mathfrak F_{\mathrm{safe}}(L)}W(K),
\]
with optimizer correspondence
\[
  \operatorname{Opt}_{\mathrm{safe}}(L)
  :=
  \operatorname*{argmin}_{K\in\mathfrak F_{\mathrm{safe}}(L)}W(K).
\]
No uniqueness or tie breaker is assumed.

## 2. Dynamic assumptions and action objects

Fix one exact rational raw innovation process on the catalog satisfying the
current T1/UDI factorization restrictions:

- generation, primitive admission, availability, research cost, duration,
  operation, and the joint completion law depend on a raw library only
  through the displayed realizable compressed state wherever required by the
  current model; and
- raw update and the compressed update commute as in T1.

Write
\[
  K\sim_{\mathrm{DI}}K'
\]
for the current unified cost-sensitive dynamic innovation equivalence. It
compares:

1. current frontier;
2. availability-tagged research costs;
3. availability-tagged durations;
4. availability-tagged joint terminal belief/compressed-state laws; and
5. availability-tagged expected operating-reward blocks.

For the converse characterization, additionally assume A-T2-OBS, implemented
by `RawClosureDetectable`, on the realizable frontier--closure pairs of this
process.

Let \(V_h(b,K)\in\mathbb Q\) denote the current unified calendar-horizon raw
value. For stationary claims, additionally fix the current
`DiscountedContractionModel`; in particular, the exact discount lies in
\([0,1)\) and the stated raw and compressed Bellman contraction certificates
hold. Write
\[
  V_\infty(b,K)\in\mathbb R
\]
for its raw fixed-point value.

Let the common action-signature type be
\[
  \mathcal A:=\{\mathsf{Continue}\}\cup Q.
\]
For \(a\in\mathcal A\), let
\(\operatorname{Avail}(K,a)\) be stationary availability and let
\[
  Q_\infty(b,K,a)
\]
be the fixed-point value of the action signature. The optimal stationary
action set is
\[
  \mathcal A^\star(b,K)
  :=
  \left\{
    a\in\mathcal A:
    \operatorname{Avail}(K,a),\
    Q_\infty(b,K,a)\ge Q_\infty(b,K,a')
    \text{ for every available }a'
  \right\}.
\]
This is a set-valued object and retains all ties.

## 3. Local deletion and pruning definitions

For an admissible \(K\) and active \(s\in K\setminus\{s_0\}\), write
\[
  K^{-s}:=K\setminus\{s\}.
\]
The strategy \(s\) is **safely deletable at \(K\)** when
\[
  F_{K^{-s}}=F_K
  \qquad\text{and}\qquad
  C_{K^{-s}}=C_K.
\]
The certificate is current-library-relative.

A **rechecked stepwise safe-deletion trace** from \(L\) is a finite sequence
\[
  L=L_0,L_1,\ldots,L_T
\]
such that, for every \(t<T\), some active \(s_t\in L_t\) is safely deletable
at the current library and
\[
  L_{t+1}=L_t^{-s_t}.
\]
The trace is **complete** when no active strategy is safely deletable at
\(L_T\).

## 4. The exact safe-compression theorem

### Theorem SC

Under the exact finite setting above:

1. **Nonempty feasible set.**
   \[
     L\in\mathfrak F_{\mathrm{safe}}(L).
   \]
   Hence \(P_{\mathrm{safe}}(L)\) is feasible.

2. **Attainment of minimum burden.**
   \[
     \operatorname{Opt}_{\mathrm{safe}}(L)\ne\varnothing.
   \]
   Thus at least one minimum-weight safe sublibrary exists.

3. **Frontier--closure characterization.** Under the T1/UDI factorization
   assumptions and A-T2-OBS/`RawClosureDetectable`, every admissible
   \(K\subseteq L\) satisfies
   \[
     \boxed{
     F_K=F_L\ \land\ C_K=C_L
     \quad\Longleftrightarrow\quad
     K\sim_{\mathrm{DI}}L.}
   \]
   Consequently the frontier--closure and DI formulations of
   \(P_{\mathrm{safe}}(L)\) have the same feasible set, objective, optimal
   value, and optimizer correspondence.

4. **Productive preservation by every feasible library.** Under the forward
   T1/UDI factorization assumptions, every
   \(K\in\mathfrak F_{\mathrm{safe}}(L)\) preserves finite-horizon value.
   Under the additionally fixed `DiscountedContractionModel`, it also
   preserves the stationary quantities below:

   \[
   \begin{aligned}
     V_h(b,K)&=V_h(b,L)
       &&\text{for every }h\in\mathbb N,\ b\in B,\\
     V_\infty(b,K)&=V_\infty(b,L)
       &&\text{for every }b\in B,\\
     \operatorname{Avail}(K,a)
       &\Longleftrightarrow \operatorname{Avail}(L,a)
       &&\text{for every }a\in\mathcal A,\\
     Q_\infty(b,K,a)&=Q_\infty(b,L,a)
       &&\text{for every }b\in B,\ a\in\mathcal A.
   \end{aligned}
   \]

   Therefore every pairwise stationary action comparison is preserved:
   \[
     Q_\infty(b,K,a)\le Q_\infty(b,K,a')
     \quad\Longleftrightarrow\quad
     Q_\infty(b,L,a)\le Q_\infty(b,L,a'),
   \]
   and the complete optimal stationary action correspondence is preserved:
   \[
     \boxed{\mathcal A^\star(b,K)=\mathcal A^\star(b,L)}
     \qquad\text{for every }b\in B.
   \]
   Detectability is not needed for this forward preservation result.

5. **No safely deletable positive-weight strategy at an optimum.** Every
   \(K^\star\in\operatorname{Opt}_{\mathrm{safe}}(L)\) satisfies
   \[
     \forall s\in K^\star\setminus\{s_0\},\qquad
     \neg\bigl(
       F_{(K^\star)^{-s}}=F_{K^\star}
       \ \land\
       C_{(K^\star)^{-s}}=C_{K^\star}
     \bigr).
   \]
   More generally, the conclusion excludes any safely deletable strategy
   with \(w_s>0\). Under the primary model every active strategy has positive
   weight, so every optimum is one-deletion irreducible. Frontier and closure
   monotonicity then also make it inclusion-wise irreducible relative to
   \(\mathfrak F_{\mathrm{safe}}(L)\).

6. **Stepwise pruning is not a global optimizer in general.** There exists an
   exact finite instance with unit active weights and a complete rechecked
   safe-deletion trace whose endpoint is safe-feasible and inclusion-wise
   irreducible but is not globally minimum weight:
   \[
     L_T\in\mathfrak F_{\mathrm{safe}}(L),
     \qquad
     L_T\notin\operatorname{Opt}_{\mathrm{safe}}(L).
   \]
   Thus feasibility, trace completeness, and local irreducibility do not
   imply global optimality.

7. **Equal-weight specialization.** Suppose there is a common
   \(\bar w\in\mathbb Q_{>0}\) such that
   \[
     w_s=\bar w
     \qquad
     \text{for every }s\in L\setminus\{s_0\}.
   \]
   Then, for every admissible \(K\subseteq L\),
   \[
     W(K)=\bar w\,|K\setminus\{s_0\}|
          =\bar w\,(|K|-1).
   \]
   Hence
   \[
     \boxed{
     \operatorname*{argmin}_{K\in\mathfrak F_{\mathrm{safe}}(L)}W(K)
     =
     \operatorname*{argmin}_{K\in\mathfrak F_{\mathrm{safe}}(L)}|K|.}
   \]
   In the primary model, “all weights equal” always means all **active**
   weights are equal; the mandatory inactive strategy retains its fixed
   zero-weight exception.

## 5. Exact counterexample for part 6

Use one belief, two modules \(m_1,m_2\), identity closure, and four strategies
\[
  L=\{s_0,x_1,x_2,a\}.
\]
All operational profiles are zero. The exact catalog rows are:

| Strategy | Modules | Weight |
|---|---|---:|
| \(s_0\) | \(\varnothing\) | \(0\) |
| \(x_1\) | \(\{m_1\}\) | \(1\) |
| \(x_2\) | \(\{m_2\}\) | \(1\) |
| \(a\) | \(\{m_1,m_2\}\) | \(1\) |

The source frontier is zero and its closure is \(\{m_1,m_2\}\). Deleting the
bundle \(a\) is safe because \(x_1,x_2\) retain both modules. The endpoint
\[
  K_{\mathrm{pair}}=\{s_0,x_1,x_2\}
\]
is complete and irreducible: deleting either singleton loses one module. Its
burden is \(2\).

But
\[
  K_{\mathrm{bundle}}=\{s_0,a\}
\]
has the same zero frontier and the same closure, so it is safe-feasible, and
its burden is \(1\). Therefore the complete endpoint
\(K_{\mathrm{pair}}\) is not globally minimum weight.

This is CX-OPT-PRUNE-CARDINALITY-01 in
`experiments/results/resource_optimization_fixtures/01_cx_opt_prune_cardinality_01.json`.
The fixture uses `Rational{BigInt}`, enumerates the full safe-feasible family,
and verifies trace safety, endpoint irreducibility, and the global optimizer
set. The identity closure is a valid specialization of the theorem's general
extensive, monotone, idempotent closure.

## 6. Assumption-to-conclusion map

| Part | Finiteness | Positive active weights | T1/UDI forward factorization | Raw closure detectability | Stationary contraction |
|---|---:|---:|---:|---:|---:|
| 1. Feasibility | yes | no | no | no | no |
| 2. Attainment | yes | no | no | no | no |
| 3. FC iff DI | yes | no | yes | yes, for DI \(\Rightarrow\) FC | no |
| 4. Finite value | yes | no | yes | no | no |
| 4. Stationary value/actions | yes | no | yes | no | yes |
| 5. No safe positive-weight deletion | yes | only for strict decrease | no | no | no |
| 6. Nonglobal pruning endpoint | yes | witness uses unit weights | no | no | no |
| 7. Weight/cardinality equivalence | yes | common \(\bar w>0\) | no | no | no |

## 7. Claim and formalization boundary

The composite theorem has the following evidence status.

| Component | Human argument | Lean status | Julia status |
|---|---|---|---|
| Parts 1--2 | complete | Lean verified through OPT-FND/OPT-T2T4 | exact enumeration implements the domain and optimizer |
| Part 3 | complete | detectability-guarded source-relative biconditional Lean verified | exact raw signature checks exist |
| Part 4 | complete | finite/stationary value and full optimal-action-set wrappers Lean verified | exact raw/compressed value and policy checks exist |
| Part 5 | complete | global minimum implies one-deletion irreducible Lean verified; generic inclusion-wise bridge open | exact positive-weight checks exist |
| Part 6 | complete counterexample argument | unit endpoint and `(2,2,3)` strict-heaviest counterexamples Lean verified | both registered Julia fixtures pass the exact gauntlet |
| Part 7 | complete | resource corollary open | follows exactly from the implemented additive objective |

Any later monolithic Lean theorem must reuse the compiled predicates and must
not claim that a complete pruning trace is globally optimal.
