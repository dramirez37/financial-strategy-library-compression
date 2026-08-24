# Human-Readable Proof Outline for the Exact Safe-Compression Theorem

## Purpose and proof boundary

This note gives the complete paper-level derivation of the seven clauses in
`SAFE_COMPRESSION_THEOREM_SPEC.md`. All arguments are exact and finite. No
floating-point approximation is used.

The argument deliberately separates three kinds of reasoning:

- finite-set optimization for existence;
- productive dynamic equivalence for value and action preservation; and
- a finite counterexample for the failure of global pruning optimality.

The result has not been packaged as one monolithic Lean theorem. OPT-FND and
OPT-T2T4 now encode and axiom-audit parts 1--6 through separate declarations,
including exact finite counterexamples. The registered Julia fixtures remain
an independent exhaustive exact-enumeration check. The equal-weight
cardinality corollary and generic inclusion-wise bridge remain open in Lean.

## 1. The source library is feasible

By assumption \(L\) is an admissible library, so \(L\subseteq L\) and
\(s_0\in L\). Equality is reflexive:
\[
  F_L=F_L,
  \qquad
  C_L=C_L.
\]
These are exactly the membership conditions for
\(\mathfrak F_{\mathrm{safe}}(L)\). Therefore
\[
  L\in\mathfrak F_{\mathrm{safe}}(L),
\]
so the feasible set is nonempty.

No dynamic or weight assumption is needed.

## 2. A minimum-weight feasible sublibrary exists

Because \(L\) is finite, its power set \(\mathcal P(L)\) is finite. The
admissible sublibraries
\[
  \{K\subseteq L:s_0\in K\}
\]
form a finite subset of that power set. Imposing the two exact equalities
\(F_K=F_L\) and \(C_K=C_L\) selects another finite subset, namely
\(\mathfrak F_{\mathrm{safe}}(L)\).

Part 1 shows that this finite set is nonempty. The burden map
\[
  W:\mathfrak F_{\mathrm{safe}}(L)\to\mathbb Q_{\ge0}
\]
therefore has a smallest attained value. Choose any feasible library attaining
it. This proves
\[
  \operatorname{Opt}_{\mathrm{safe}}(L)\ne\varnothing.
\]

The argument proves attainment, not uniqueness. It would work for any
totally ordered exact objective on this finite feasible set; positivity of
weights is not needed until part 5.

## 3. Frontier and closure characterize dynamic innovation equivalence

Fix an admissible \(K\subseteq L\).

### Forward direction

Assume
\[
  F_K=F_L,
  \qquad
  C_K=C_L.
\]
Then the realizable compressed states agree:
\[
  \mathcal K(K)=(F_K,C_K)=(F_L,C_L)=\mathcal K(L).
\]
Under the current T1/UDI factorization restrictions, every one of the five
observations defining unified dynamic innovation equivalence is a function of
this realizable compressed state. Equal inputs therefore give:

- equal current frontiers;
- equal tagged project costs;
- equal tagged durations and hence equal project menus;
- equal tagged terminal belief/compressed-state laws; and
- equal tagged expected operating-reward blocks.

Thus \(K\sim_{\mathrm{DI}}L\). Detectability is not used.

### Reverse direction

Assume \(K\sim_{\mathrm{DI}}L\). Equality of the observed current frontier
immediately gives
\[
  F_K=F_L.
\]
Closure equality does not follow from behavioral equivalence alone: a closure
difference could be invisible to every available project. This is precisely
why A-T2-OBS is required.

`RawClosureDetectable` says that any distinct realizable closures at the
relevant frontier are separated by at least one raw process observation.
Dynamic innovation equivalence says that no such separating observation
exists. Therefore the closures cannot differ:
\[
  C_K=C_L.
\]

Combining the two directions proves
\[
  F_K=F_L\ \land\ C_K=C_L
  \quad\Longleftrightarrow\quad
  K\sim_{\mathrm{DI}}L.
\]

Applying this pointwise to every admissible \(K\subseteq L\) makes the safe
and DI feasible families identical. The two optimization problems then have
the same objective on the same domain, so their optimal values and complete
optimizer correspondences are identical.

## 4. Every feasible library preserves productive values and actions

Let \(K\in\mathfrak F_{\mathrm{safe}}(L)\). By definition,
\[
  F_K=F_L,
  \qquad
  C_K=C_L,
\]
so \(\mathcal K(K)=\mathcal K(L)\). The forward half of part 3 gives
\[
  K\sim_{\mathrm{DI}}L.
\]

### Finite-horizon value

At horizon zero the unified raw values agree by the common base convention.
For the induction step, dynamic innovation equivalence supplies the same
feasible menu and the same exact value for each corresponding Continue or
research action once the continuation value is constant on equivalence
classes. Taking the maximum over identical action-value tables preserves
equality. Strong induction over the calendar horizon therefore gives
\[
  V_h(b,K)=V_h(b,L)
\]
for every finite \(h\) and belief \(b\).

This is the content of the existing Lean theorem
`rawValue_eq_of_dynamicInnovationEquivalent`.

### Stationary value

Start stationary Bellman iteration from the zero table. The Bellman operator
maps a table constant on dynamic-innovation classes to another table constant
on those classes, because equivalent libraries have identical action
observations and menus. Hence every iterate agrees at \(K\) and \(L\).

The raw and compressed contraction certificates make these iterates converge
to the unique fixed points. Equality is preserved under the limit, so
\[
  V_\infty(b,K)=V_\infty(b,L).
\]

This is the existing Lean theorem
`DiscountedContractionModel.rawFixedPoint_eq_of_dynamicInnovationEquivalent`.

### Stationary action comparisons

Compressed-state equality gives identical stationary availability:
\[
  \operatorname{Avail}(K,a)
  \Longleftrightarrow
  \operatorname{Avail}(L,a).
\]
It also gives equality of every fixed-point action-signature value:
\[
  Q_\infty(b,K,a)=Q_\infty(b,L,a).
\]
Therefore, for any two signatures \(a,a'\), replacing both sides by their
equal counterparts yields
\[
  Q_\infty(b,K,a)\le Q_\infty(b,K,a')
  \Longleftrightarrow
  Q_\infty(b,L,a)\le Q_\infty(b,L,a').
\]
The same reasoning preserves strict inequalities and ties.

### Optimal stationary action set

An action belongs to \(\mathcal A^\star(b,K)\) exactly when it is available at
\(K\) and weakly beats every other available action. Both the availability
predicate and every comparison are identical at \(K\) and \(L\). Thus, action
by action,
\[
  a\in\mathcal A^\star(b,K)
  \Longleftrightarrow
  a\in\mathcal A^\star(b,L).
\]
Extensionality gives
\[
  \mathcal A^\star(b,K)=\mathcal A^\star(b,L).
\]
This proves equality of the full optimizer sets, including ties, rather than
only equality of one selected policy.

Detectability was not used anywhere in part 4. Exact frontier and closure
equality already supply the forward dynamic equivalence needed for
preservation.

## 5. A minimum-weight solution has no safe positive-weight deletion

Take
\[
  K^\star\in\operatorname{Opt}_{\mathrm{safe}}(L).
\]
Suppose for contradiction that \(s\in K^\star\setminus\{s_0\}\) is safely
deletable and \(w_s>0\). Write
\[
  K^-:=K^\star\setminus\{s\}.
\]
Safe deletion at the current library gives
\[
  F_{K^-}=F_{K^\star},
  \qquad
  C_{K^-}=C_{K^\star}.
\]
Feasibility of \(K^\star\) gives
\[
  F_{K^\star}=F_L,
  \qquad
  C_{K^\star}=C_L.
\]
By transitivity,
\[
  F_{K^-}=F_L,
  \qquad
  C_{K^-}=C_L.
\]
Also \(K^-\subseteq L\) and \(s_0\in K^-\), since the deleted strategy was
active. Hence
\[
  K^-\in\mathfrak F_{\mathrm{safe}}(L).
\]

Additivity and set-valued libraries give
\[
  W(K^-)=W(K^\star)-w_s<W(K^\star).
\]
This contradicts the minimum-weight property of \(K^\star\). Therefore no
positive-weight strategy is safely deletable from a minimum-weight solution.

Under the primary convention all active weights are positive, so every
global safe optimum is one-deletion irreducible. If a strict feasible
sublibrary existed, frontier and closure monotonicity would sandwich an
intermediate single deletion between equal feasible endpoints, producing a
safe deletion. Thus the optimum is also inclusion-wise irreducible.

The argument is one-way. It does not show that every irreducible library is
globally optimal.

## 6. A complete pruning endpoint can be globally suboptimal

Consider one belief and two modules \(m_1,m_2\). Use identity closure. Let
\[
  L=\{s_0,x_1,x_2,a\},
\]
give every strategy the zero operational profile, and assign modules and
weights by
\[
\begin{array}{c|c|c}
\text{strategy}&\text{modules}&\text{weight}\\ \hline
s_0&\varnothing&0\\
x_1&\{m_1\}&1\\
x_2&\{m_2\}&1\\
a&\{m_1,m_2\}&1.
\end{array}
\]

Every library has zero frontier. The source closure is
\(\{m_1,m_2\}\).

At the source, delete the bundle \(a\). The remaining singletons still carry
both modules, so the deletion preserves closure and is safe. The endpoint is
\[
  K_{\mathrm{pair}}=\{s_0,x_1,x_2\}.
\]
Neither singleton can now be deleted: removing \(x_1\) loses \(m_1\), and
removing \(x_2\) loses \(m_2\). The trace is therefore complete and the
endpoint is one-deletion and inclusion-wise irreducible. It is safe-feasible
for the source and has
\[
  W(K_{\mathrm{pair}})=2.
\]

Now compare the incomparable safe library
\[
  K_{\mathrm{bundle}}=\{s_0,a\}.
\]
It has the same zero frontier and the same closure as the source, but
\[
  W(K_{\mathrm{bundle}})=1.
\]
Therefore
\[
  K_{\mathrm{pair}}
  \notin\operatorname{Opt}_{\mathrm{safe}}(L).
\]

This proves more than failure of an arbitrarily stopped trace: even a
complete, irreducible endpoint need not be globally minimum weight. The exact
registered fixture CX-OPT-PRUNE-CARDINALITY-01 enumerates the entire
safe-feasible family and checks these statements with exact rational
arithmetic.

## 7. Equal active weights reduce the problem to minimum cardinality

Assume every active strategy in the source has the same exact weight
\(\bar w>0\). Every admissible \(K\subseteq L\) contains \(s_0\), whose
weight is zero. Therefore
\[
\begin{aligned}
  W(K)
    &=\sum_{s\in K\setminus\{s_0\}}w_s\\
    &=\sum_{s\in K\setminus\{s_0\}}\bar w\\
    &=\bar w\,|K\setminus\{s_0\}|\\
    &=\bar w\,(|K|-1).
\end{aligned}
\]
For any two feasible libraries \(K_1,K_2\), positivity of \(\bar w\) gives
\[
  W(K_1)\le W(K_2)
  \quad\Longleftrightarrow\quad
  |K_1|\le|K_2|.
\]
Thus the burden order and cardinality order are identical on the complete
safe-feasible family. Their argmin sets are exactly equal:
\[
  \operatorname*{argmin}_{K\in\mathfrak F_{\mathrm{safe}}(L)}W(K)
  =
  \operatorname*{argmin}_{K\in\mathfrak F_{\mathrm{safe}}(L)}|K|.
\]

The zero-weight inactive strategy causes no discrepancy because it is present
in every feasible library. This is the precise meaning of the equal-weight
specialization in the primary model.

## Lean dependencies and remaining wrapper

| Paper-level step | Existing Lean declaration |
|---|---|
| Compressed-state equality implies UDI | `Projection.Model.compressedState_eq_implies_dynamicInnovationEquivalent` |
| UDI iff frontier and closure equality under detectability | `Projection.Model.dynamicInnovationEquivalent_iff_frontierClosure_eq` |
| Finite-horizon value preservation | `Projection.Model.rawValue_eq_of_dynamicInnovationEquivalent` |
| Stationary fixed-point value preservation | `Projection.Model.DiscountedContractionModel.rawFixedPoint_eq_of_dynamicInnovationEquivalent` |
| Stationary availability under equal compressed state | `Projection.Model.stationaryActionAvailable_iff_of_compressedState_eq` |
| Stationary action-value equality under equal compressed state | `Projection.Model.DiscountedContractionModel.fixedPointActionValue_eq_of_compressedState_eq` |
| Single-deletion action comparisons | `Projection.Model.DiscountedContractionModel.redundantDeletion_preserves_actionValueComparison` |
| Single-deletion optimal-action membership | `Projection.Model.DiscountedContractionModel.redundantDeletion_preserves_optimalAction` |
| Exact safe feasibility and global optimum | `Optimization.SafeCompressionFeasible`, `Optimization.MinimumWeightSafeCompression` |
| Minimum existence and one-deletion irreducibility | `Optimization.exists_minimumWeightSafeCompression`, `Optimization.MinimumWeightSafeCompression.oneDeletionIrreducible` |
| Rechecked endpoint feasibility | `Optimization.recheckedSafeDeletionEndpoint_feasible` |
| Nonglobal endpoint and strict-heaviest boundary | `Optimization.SafeCompressionCounterexample.recheckedEndpoint_need_not_be_globallyMinimum`, `Optimization.SafeCompressionCounterexample.strictHeaviestFirst_greedy_not_globallyOptimal` |

Parts 1--6 are Lean verified through these separate declarations. A future
composite theorem may package them and add part 7, but it must not upgrade the
still-open equal-weight or generic inclusion-wise clauses by implication.
