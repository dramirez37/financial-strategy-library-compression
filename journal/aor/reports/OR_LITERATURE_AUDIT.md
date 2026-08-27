# Operations-research literature audit for the AoOR revision

Status: source audit completed before new theorem or algorithm implementation

Access date: 2026-08-26

Weighted-greedy primary-source recheck: 2026-08-27

Scope: weighted covering, decision complexity, approximation, exact solution,
preprocessing, benchmarking, control and policy libraries, partial-information
control, and financial model governance/resource allocation.

Companion records: `CITATION_CANDIDATES.bib` and
`RELATED_WORK_MATRIX.csv`. The CSV is the row-level authority for the exact
proposition, intended citation location, role, and subsumption assessment of
each candidate. This report does not authorize adding any candidate to
`manuscript/bibliography/references.bib`.

## Outcome

The proposed journal novelty survives, but only under a narrower formulation
than “a new tagged covering problem” or “new set-cover algorithms.” Once the
identity-closure obligations have been encoded as disjoint operating and
module tags, the optimization problem is ordinary weighted set cover with a
fixed mandatory inactive entry handled outside the positive-cost cover. Its
integer program, greedy construction, coverage-mask dynamic program, and many
standard dominance ideas are therefore established methodology, not new
generic algorithms.

No inspected source subsumes the full joint claim: source-relative
minimum-burden retention of a named financial strategy library subject to both
exact regime/belief-indexed operating-frontier equality and exact
parent-conditioned generative-closure equality, with mandatory inactive
retention and exact output rechecking. This is a bounded audit conclusion, not
a claim that no uninspected paper exists.

The defensible contribution boundary is:

1. the semantic reduction from a raw strategy library to its joint productive
   state, operating frontier plus generative closure;
2. a proved, source-relative equivalence between identity-closure compression
   and ordinary weighted set cover on a precisely constructed obligation
   universe;
3. inherited complexity and approximation consequences stated with their
   exact assumptions, not advertised as new generic results;
4. domain-specific preprocessing or certification only where a new rule is
   actually proved against the frontier--closure semantics;
5. an exact-postchecked algorithm portfolio and separately registered
   computational comparison; and
6. retrospective financial evidence under the pre-existing no-causality,
   no-forecasting, no-alpha, and no-deployable-performance boundaries.

The two closest precedents are Dey et al. (2012) and Mutti, Del Col, and
Restelli (2022). Dey et al. optimize static control libraries using
submodular-sequence structure. Mutti et al. construct reward-free policy-space
representatives through a set-cover formulation and state NP-hardness. Both
materially constrain novelty language. Neither inspected formulation preserves
the paper's two semantic objects jointly or models retained policies as
carriers for later parent-conditioned generation.

## Method and source standard

The audit began with the existing bibliography and literature sections, then
checked theorem-supporting claims against primary papers or official publisher
records. Complexity and approximation recommendations rely on the original
papers, not survey summaries. Official publisher pages were preferred for
metadata; stable author or proceedings copies were used when publisher full
text was inaccessible. Regulatory context uses official supervisory guidance.

The source set is deliberately proposition-specific. A source was excluded
from theorem support when it merely shared words such as “compression,”
“library,” “cover,” or “governance.” Publication metadata, URLs, status, and
proposition-to-section mappings are recorded in the companion files.

## Problem-class distinctions and verified constants

These classes must remain distinct in the journal prose.

| Class | Objective and information structure | Verified result relevant here | Permitted use |
|---|---|---|---|
| Ordinary set cover | Minimize the number of selected sets whose union covers a finite universe. | Karp's decision version is a classic NP-complete problem. Johnson gives the early greedy logarithmic analysis. | Hardness source for the unit-weight identity-closure subclass after a complete polynomial reduction. |
| Weighted set cover | Minimize the sum of positive set costs subject to complete coverage. | Chvátal's minimum-cost-per-newly-covered-element greedy rule has ratio at most \(H(d)\), where \(d\) is the largest column sum, hence at most \(H(q)\leq 1+\ln q\) for \(q\) obligations. | Direct algorithmic antecedent for a forward greedy construction on the proved tag representation. |
| Maximum coverage / monotone submodular maximization | Maximize covered value subject to a cardinality budget \(|S|\leq K\). | Nemhauser, Wolsey, and Fisher give greedy value at least \(1-((K-1)/K)^K\) of optimum, tending to \(1-1/e\). | Only for a separately formulated capacity-constrained maximization problem. It is not a guarantee for minimum-cost exact retention. |
| Submodular cover | Minimize cost to reach the full value \(z(N)\) of a monotone submodular set function. | Wolsey's integer-valued, normalized case has greedy ratio \(H(\max_j z(\{j\}))\). | Usable only after proving that the proposed coverage objective is nondecreasing, submodular, integer-valued, and normalized. |
| Adaptive submodularity | Choose items sequentially while outcomes are revealed. | Golovin and Krause give greedy guarantees under adaptive monotonicity and adaptive submodularity. | Context for sequential stochastic information acquisition, not the current one-time static retention decision. |

Here \(H(r)=\sum_{i=1}^r 1/i\). The Chvátal guarantee assumes positive
costs for selectable columns. The mandatory inactive strategy has zero burden
in the journal model and should be fixed in advance, not passed as a zero-cost
column to a theorem that assumes positive costs. A safe statement is:

> After fixing the inactive strategy, suppose identity closure makes exact
> feasibility equivalent to covering a finite obligation universe of size
> \(q\) with positive-cost active strategies. The standard weighted greedy
> rule is an \(H(d)\)-approximation, where \(d\) is the maximum number of
> obligations covered by one active strategy; in particular it is an
> \(H(q)\leq 1+\ln q\) approximation.

This is a consequence of Chvátal's result, not a new approximation theorem.
The existing backward rechecked-deletion heuristic is not this forward greedy
algorithm and inherits no such factor.

For implementation, the result was rechecked against the official INFORMS
article record and the complete three-page primary paper. The official record
confirms the positive-cost binary covering model, author, venue, date, pages,
and DOI; the paper states the (H(d)) theorem and gives the near-tight family
of singleton costs (1/j) plus a universe-covering set of cost just above one.
Sources: [official INFORMS article page](https://pubsonline.informs.org/doi/10.1287/moor.4.3.233)
and [primary-paper PDF](https://people.stfx.ca/tjsmith/lec/W23CSCI435/Chv79.pdf),
accessed 2026-08-27.

For inapproximability, Feige's 1998 threshold should not be paraphrased as a
plain \(P\ne NP\) result: his \((1-o(1))\ln n\) threshold uses the assumption
that NP does not have slightly superpolynomial-time algorithms. Dinur and
Steurer's Corollary 1.5 gives the cleaner fixed-constant statement that, for
every \(\alpha>0\), approximating set cover within
\((1-\alpha)\ln n\) is NP-hard; the reduction has a dependence on fixed
\(\alpha\). These lower bounds are optional context. Basic NP-hardness needs
only the exact reduction and Karp's decision problem.

## Covering formulation and complexity

### Standard components

Chvátal writes weighted set cover as a binary covering model

\[
  \min\{c^\top x: Ax\geq \mathbf 1,\ x\in\{0,1\}^n\},
\]

with positive column costs. That formulation, its use as a MILP, and the
minimum-cost-per-new-tag greedy rule are established. The journal may claim a
new modeling reduction from its semantic preservation requirements to this
standard form; it must not claim invention of the form.

The proposed “tagged cover” theorem should therefore be named descriptively,
for example “identity-closure reduction to weighted set cover.” The proof must
establish both directions:

- every frontier-preserving and closure-preserving sublibrary covers every
  constructed operating and module obligation; and
- every sublibrary covering those obligations, together with the mandatory
  inactive strategy, has exact source frontier and closure equality.

Operating tags and module tags should be disjoint even if their textual labels
coincide. Frontier ties require exact source-relative treatment: preserving a
frontier value requires at least one strategy attaining that exact value at
each declared belief, not preservation of a preselected maximizer unless the
model explicitly requires identity. Closure tags must match the exact theorem
definition. The reduction size and construction time must be polynomial in the
declared finite encoding.

### Complexity statement that the literature supports

If the reduction embeds ordinary set cover in the identity-closure subclass,
with exact rational data and polynomial construction/evaluation, the decision
version is NP-hard. Membership in NP requires a polynomially checkable
certificate under the chosen encoding. The journal must not extend that
membership statement to an arbitrary black-box closure operator whose equality
may not be polynomially decidable.

The complexity contribution is thus the correct restriction and reduction for
this financial retention model. Computational hardness itself is inherited
from set cover and is not novel.

## Algorithms: what is reusable and what could be new

### Exact enumeration

Enumeration is a transparent finite oracle for small source libraries. It
needs no novelty claim. In this project it remains important because it can
independently check optimal burden and stable tie handling for the dynamic
program and MILP on small instances.

### Coverage-mask dynamic programming

A standard exact recurrence indexes states by a coverage mask. For obligations
\(U\) and candidate coverage masks \(M_i\), one version updates

\[
  D_i(S)=\min\{D_{i-1}(S),\ c_i+D_{i-1}(S\setminus M_i)\},
\]

or equivalently performs forward relaxations
\(D(S\cup M_i)\leftarrow\min(D(S\cup M_i),D(S)+c_i)\).
With \(q=|U|\), this gives an \(O(n2^q)\)-scale exact algorithm, subject to the
chosen recurrence, memory representation, and arithmetic costs. This is
parameterized/exponential in the number of obligations, not polynomial-time in
general input size. Its implementation here can be useful and exact, but the
generic algorithm is standard. The journal's new work is limited to a proved
semantic encoding, exact rational burden, deterministic reconstruction, and
cross-checks against enumeration.

Cygan et al., Chapter 6.1.1 and Theorem 6.1, give the subset-indexed recurrence
for cardinality set cover and a
\(2^{|U|}(|U|+|\mathcal F|)^{O(1)}\) bound. The weighted positive-cost version
needed here replaces the unit increment by an exact candidate cost; that
extension and the repository's tie-reconstruction contract should be proved
directly rather than attributed to the book without qualification.

The recurrence should also be proved directly in the Online Resource so that
the weighted-cost and reconstruction details do not rest on an analogy to the
cardinality version.

### Mixed-integer optimization

The standard weighted covering MILP follows directly from Chvátal's model.
Crowder, Johnson, and Padberg document the importance of preprocessing,
cutting planes, and branch-and-bound for large zero-one programs; Beasley,
Fisher--Kedia, and Caprara--Fischetti--Toth provide set-cover-specific exact or
heuristic computational antecedents. These references support method choice,
not a claim that a solver's `OPTIMAL` status is an exhaustive or formal proof.

Every solver-returned library must still be independently checked for:

1. exact operating-frontier equality;
2. exact generative-closure equality;
3. exact burden under the source weights; and
4. mandatory inactive-strategy retention.

That check certifies feasibility and the reported burden of the returned
library. It does not independently certify global optimality.

### Dominance and preprocessing

Set-cover and MIP practice includes redundant-row removal, forced columns,
column dominance, coefficient strengthening, bound fixing, and logical probing.
Beasley and Savelsbergh are suitable methodological citations. They do not
prove any journal-specific preprocessing rule.

Candidate dominance is safe in the ordinary positive-cost covering instance
when one candidate's obligation set is contained in another's and the latter
has no greater cost, subject to deterministic tie conventions and any fixed
membership constraints. Translating that statement back to strategy libraries
requires care:

- the inactive strategy cannot be eliminated by generic dominance;
- exact frontier ties and module obligations must already be encoded correctly;
- deleting a source entry must not alter how obligations themselves are
  defined unless the theorem explicitly allows recomputation;
- rational cost comparisons and reconstruction ties must be exact; and
- a rule for general, non-identity closure needs a separate semantic proof.

Accordingly, “proved preprocessing for the identity-closure cover” is a
plausible contribution; “new general preprocessing theory” is not yet
supported.

### Approximation-guaranteed construction and certified deletion

The correct approximation candidate is a new implementation of the standard
forward weighted greedy rule after the exact covering reduction. The guarantee
is inherited from Chvátal. The existing deletion procedures may be retained as
certified-feasibility heuristics when every accepted deletion is exactly
rechecked. Local deletion irreducibility is not global optimality and has no
set-cover approximation guarantee without an additional proof.

### Performance profiles

Dolan and Moré define performance profiles as distribution functions of
per-problem performance ratios. They are appropriate only if the registered
study predeclares the performance measure, reference value, treatment of
failures/timeouts, and eligible problem set. For this project, exact
postchecking must precede inclusion in an “exact feasible” runtime profile.
An infeasible or incorrectly burdened output cannot be treated as a merely slow
run. Moré and Wild's data profiles are a conditional addition if the design
compares progress under a computational budget; they are not needed for an
ordinary time-to-solution profile.

## Closest prior work and subsumption assessment

| Source | Material overlap | What it does not establish for this paper | Risk |
|---|---|---|---|
| Mutti, Del Col, and Restelli (2022) | Compresses a policy space into reward-free representatives; set-cover formulation; NP-hardness. | Joint exact frontier and parent-conditioned closure preservation for a named source library; financial source-relative burden; mandatory inactive entry. | High for any broad “first policy-space covering/compression” or generic NP-hardness claim. |
| Dey et al. (2012) | Selects/orders compact control libraries; computational scarcity; submodular-sequence algorithms and guarantees. | Exact preservation of two semantic source objects or retained entries as carriers for later generation. | High for broad “first control-library optimization” or generic greedy-library claim. |
| Chvátal (1979) | Weighted covering IP and greedy approximation. | The semantic construction of the paper's obligation universe. | Decisive: the covering form and guarantee are prior art. |
| Wolsey (1982) | Greedy analysis for submodular cover. | Submodularity of a general generative-closure objective. | High if the journal invokes a submodular guarantee without proving assumptions. |
| Smallwood--Sondik; White | Belief/sufficient-statistic partial-information control. | Endogenous library compression with generative carriers. | High for any general POMDP-sufficiency novelty claim; low for the narrow library-state claim. |
| Cassandra--Littman--Zhang; Givan--Dean--Greig | Exact pruning in POMDP backups and state/model minimization. | Source-entry retention under joint frontier--closure equality. | Moderate; requires a crisp difference from alpha-vector or state reduction. |
| Federal Reserve/OCC SR 11-7 | Model inventory, validation, monitoring, governance, and resource context. | A mathematical retention objective or empirical result. | Context only; cannot support optimization novelty. |

No inspected exact set-cover paper turns the generic coverage-mask DP, weighted
greedy rule, or binary covering formulation into a new contribution here.
Conversely, no inspected control-library, policy-compression, POMDP-reduction,
or governance source encodes both operating opportunities and future
generation capabilities as exact source-relative retention obligations.

## Partial-information control and financial positioning

Smallwood and Sondik support the finite-horizon belief-state architecture and
piecewise-linear value representation. Sondik supplies the infinite-horizon
discounted counterpart. White gives a finite-horizon, partially observed
semi-Markov sufficient-statistic formulation. Li, Nyström, and Olofsson and
Dai, Zhang, and Zhu locate partial-information switching and regime-switching
trading in financial control. These are antecedents, not claims to novelty.

Cassandra, Littman, and Zhang remove redundant alpha vectors from exact POMDP
backups, while Givan, Dean, and Greig study behavioral equivalence and model
minimization in MDPs. The journal must explain why deleting a strategy carrier
from an endogenous source library is not the same object as pruning a value
representation or aggregating model states.

Russell and Wefald, Weitzman, and Baker et al. provide established ways to
motivate scarce computational/search/R&D resources. Their objectives differ
from exact source preservation; they are contextual rather than theorem
support. Dey et al. and Mutti et al. are the methodological comparators.

The inspected primary sources did not yield an established quantitative-finance
model that jointly allocates research resources by deleting entries from an
endogenous strategy library while preserving both current opportunities and
future generation capability. The audit therefore keeps financial model-risk
governance and general R&D/search allocation as two separate contextual
literatures; combining them into a claimed prior optimization model would
overstate the evidence.

Federal Reserve/OCC SR 11-7 is an official source for model-development,
implementation, validation, monitoring, inventory, and governance burdens.
It does not establish that a financial institution should solve the proposed
retention model. Because the OCC revised its model-risk guidance in 2026 for
OCC-supervised banks, the journal should either describe SR 11-7 as Federal
Reserve guidance and separately verify current regulator scope, or avoid a
broad claim that it is the single current US banking standard. Cont and
Glasserman--Xu support model-risk context, not research-resource allocation or
strategy-library compression.

## Recommended citation placement

- **Section 2, Literature and problem positioning:** Karp; Chvátal; Wolsey;
  Dey et al.; Mutti et al.; Smallwood--Sondik; White; Cassandra et al.; Givan et
  al.; selected model-governance/resource context.
- **Section 4, Exact compression, covering representation, and complexity:**
  Karp for the source decision problem; Chvátal for the standard weighted
  covering model; Feige or Dinur--Steurer only if an approximation threshold is
  actually discussed.
- **Section 5, Algorithms and guarantees:** Chvátal for weighted greedy;
  Wolsey only for a proved submodular-cover variant; Beasley,
  Fisher--Kedia, Crowder et al., Savelsbergh, and Caprara et al. for exact,
  preprocessing, MILP, and heuristic antecedents; Dolan--Moré for performance
  profiles.
- **Section 7, Registered computational study:** Dolan--Moré, and Moré--Wild
  only if budget-based data profiles are used.
- **Section 8, Financial case studies:** model-risk/governance sources only as
  motivation; none converts retrospective evidence into a causal, forecasting,
  alpha, or deployable-performance claim.

## Prose boundary

Permitted after the relevant theorem and implementation gates pass:

- “Under identity closure, the source-relative exact compression instance is
  equivalent to a weighted set-cover instance on disjoint operating and module
  obligations.”
- “The decision problem is NP-hard by reduction from set cover.”
- “The forward weighted greedy implementation inherits Chvátal's
  \(H(d)\) guarantee under positive active-entry costs.”
- “The coverage-mask dynamic program is exact and fixed-parameter/exponential
  in the number of obligations,” with the implementation's actual proved time
  and space bounds.
- “Every returned library passed exact semantic postchecks,” only when a
  committed artifact records those checks.

Not permitted:

- “We introduce tagged weighted set cover” as a new generic combinatorial
  problem.
- “We develop the first set-cover MILP/greedy/bitmask DP.”
- “The backward deletion heuristic is an \(H(d)\)-approximation.”
- “The general closure problem is in NP” without a polynomial closure-equality
  verifier in the encoded input model.
- “Submodularity gives a greedy guarantee” without the exact monotonicity,
  normalization, integrality, and submodularity proof required by the cited
  theorem.
- “Performance profiles prove one algorithm is universally faster.”
- Any claim that regulatory guidance proves economic efficiency or empirical
  effectiveness of the proposed compression.

## Existing bibliography and required additions

Already present and reusable include Dey et al.; Golovin--Krause; Mutti et al.;
Smallwood--Sondik; White; Cassandra et al.; Givan et al.; Russell--Wefald; Li et
al.; and Dai et al. The existing literature section already recognizes several
of the correct boundaries.

The minimum new bibliography additions for the planned OR claims are Karp,
Chvátal, Wolsey, Beasley or Fisher--Kedia, Savelsbergh, and Dolan--Moré. Johnson
and Lovász are useful historical antecedents. Feige and Dinur--Steurer should
be added only if the manuscript discusses tight approximation barriers.
Nemhauser--Wolsey--Fisher is needed only to contrast maximum coverage or support
a separately stated capacity-maximization result. The governance and model-risk
sources are optional contextual additions.

## Open verification items

1. A broader legal/regulatory statement about current US model-risk guidance
   requires jurisdiction- and regulator-specific verification because the OCC
   issued revised guidance in 2026.
2. The literature does not prove the proposed tagged-cover equivalence,
   preprocessing rules, stable reconstruction, or general-closure complexity;
   those are mathematical implementation gates for this project.
3. The bounded search found no full subsumption of the joint claim, but the
   novelty conclusion should be revisited after the exact theorem statement is
   written and before submission.

## Source access record

The principal official or primary pages inspected were:

- Karp (Springer): <https://link.springer.com/chapter/10.1007/978-1-4684-2001-2_9>
- Johnson (ScienceDirect): <https://www.sciencedirect.com/science/article/pii/S0022000074800449>
- Lovász (ScienceDirect): <https://www.sciencedirect.com/science/article/pii/0012365X75900588>
- Chvátal (INFORMS): <https://pubsonline.informs.org/doi/10.1287/moor.4.3.233>
- Wolsey (Springer): <https://link.springer.com/article/10.1007/BF02579435>
- Nemhauser--Wolsey--Fisher (Springer): <https://link.springer.com/article/10.1007/BF01588971>
- Feige (primary author/course-hosted paper copy): <https://courses.cs.duke.edu/cps296.2/spring07/papers/p634-feige.pdf>
- Dinur--Steurer (author page and arXiv): <https://www.dsteurer.org/paper/productgames/> and <https://arxiv.org/abs/1305.1979>
- Beasley (ScienceDirect): <https://www.sciencedirect.com/science/article/pii/037722178790141X>
- Fisher--Kedia (INFORMS): <https://pubsonline.informs.org/doi/10.1287/mnsc.36.6.674>
- Crowder--Johnson--Padberg (INFORMS): <https://pubsonline.informs.org/doi/10.1287/opre.31.5.803>
- Savelsbergh (INFORMS): <https://pubsonline.informs.org/doi/10.1287/ijoc.6.4.445>
- Caprara--Fischetti--Toth (INFORMS): <https://pubsonline.informs.org/doi/10.1287/opre.47.5.730>
- Dolan--Moré (Springer): <https://link.springer.com/article/10.1007/s101070100263>
- Moré--Wild (SIAM): <https://epubs.siam.org/doi/10.1137/080724083>
- Cygan et al., Chapter 6 (Springer): <https://link.springer.com/chapter/10.1007/978-3-319-21275-3_6>
- Dey et al. (AAAI): <https://ojs.aaai.org/index.php/AAAI/article/view/8383>
- Mutti et al. (PMLR): <https://proceedings.mlr.press/v151/mutti22a.html>
- Golovin--Krause (JAIR): <https://www.jair.org/index.php/jair/article/view/10731>
- Smallwood--Sondik (INFORMS): <https://pubsonline.informs.org/doi/10.1287/opre.21.5.1071>
- Sondik (INFORMS): <https://pubsonline.informs.org/doi/10.1287/opre.26.2.282>
- White (INFORMS): <https://pubsonline.informs.org/doi/10.1287/opre.24.2.348>
- Federal Reserve/OCC SR 11-7 attachment: <https://www.federalreserve.gov/boarddocs/srletters/2011/sr1107a1.pdf>
- OCC 2026 revision notice: <https://occ.treas.gov/news-issuances/bulletins/2026/bulletin-2026-13.html>
- Cont (Wiley): <https://onlinelibrary.wiley.com/doi/10.1111/j.1467-9965.2006.00281.x>
- Glasserman--Xu (Taylor & Francis): <https://www.tandfonline.com/doi/abs/10.1080/14697688.2013.822989>

All were accessed on 2026-08-26. The companion CSV records the source used for
each candidate rather than treating this list as a substitute for row-level
provenance.
