# Annals of Operations Research contribution specification

Status: contribution lock before new theory or experiments

Target: *Annals of Operations Research* special issue identified in
`requirements/OFFICIAL_REQUIREMENTS.md`

Evidence cut: repository state on 2026-08-26

Authority: this document fixes the intended journal identity and claim order; it
does not upgrade the status of any theorem, algorithm, or empirical result.

## Journal identity

The journal version is a financial operations-research paper on minimum-cost
retention of strategy libraries when retained entries must jointly preserve
regime-dependent operating opportunities and capabilities needed for future
strategy generation.

The object being compressed is a finite, source-relative library. For the
declared finite partial-information process, a library contributes two objects:
its regime-dependent operating frontier and its generative closure. These two
objects form the productive **library state**. The full controlled state also
contains the filtered belief and, when a project is in progress, its project and
remaining-duration variables. The paper must not abbreviate this distinction
into a claim that the frontier and closure alone are the entire stochastic state.

The optimization question is therefore:

> Among sublibraries of a declared source library, which minimum-burden
> sublibrary preserves the source operating frontier exactly at every declared
> belief and preserves the source generative closure exactly, while retaining
> the mandatory inactive strategy?

“Exactly” means exact equality in the finite model. It is not a numerical
tolerance, approximate policy equivalence, or a claim about unobserved markets.

## Four principal journal contributions

The following is the intended referee-facing contribution language. Each item
also records its current evidence status so that intended prose cannot be
mistaken for an achieved result.

### 1. Productive-state reduction and exact retention problem

We identify the operating frontier and generative closure as the sufficient
library summary under the declared finite partial-information process, and use
that reduction to formulate source-relative, minimum-burden innovation-safe
compression. The reduction makes explicit why a strategy can be redundant for
current operation yet indispensable for future strategy generation.

Current status: **existing**. The human-readable projection, minimum-resource,
frontier--closure characterization, and rechecked-deletion results are in the
preprint. Their exact formal-verification scope remains only what
`THEOREM_LEDGER.md` records.

### 2. Covering representation, complexity, and the local/global boundary

For identity closure, we intend to show that exact innovation-safe compression
is a tagged weighted covering problem whose tags separately represent operating
frontier obligations and generative-capability obligations. This representation
supports a computational-hardness result and sharpens the distinction between
safe local deletion and globally resource-efficient retention.

Current status: **partial and gated**. The current journal overlay contains a
human-readable identity-closure complexity theorem and the repository contains
an exact finite reduction fixture. A separately stated tagged-cover equivalence
theorem is not yet in the theorem ledger. The current local/global theorem gives
a fixed counterexample; it does not supply a parametric worst-case gap family or
an approximation ratio. The journal may make the full contribution only after
those proposed statements are precisely formulated, proved, tested where
applicable, and entered in the ledger.

### 3. A certified algorithmic portfolio

We intend to develop and compare complementary solution methods: exact
enumeration, exact bitmask dynamic programming, mixed-integer optimization,
proved preprocessing, a weighted greedy construction under an explicit
approximation guarantee, and certified deletion heuristics. Every returned
library is to be independently rechecked for exact frontier equality, exact
closure equality, exact burden, and mandatory inactive-strategy retention.

Current status: **partial and gated**. Exact enumeration, mixed-integer models,
safe-feasibility checks, exact burden evaluation, and rechecked deletion already
exist. The current bitmask routine is only an operating-cover lower-bound
routine, not the proposed exact joint dynamic program. General preprocessing
theory and an approximation-guaranteed weighted greedy algorithm do not yet
exist. A solver status of `OPTIMAL` is solver evidence, not exhaustive or formal
proof; exact postchecking certifies the returned library's feasibility and
burden but does not independently certify global optimality.

### 4. Registered computational and retrospective financial evidence

The journal evidence combines the separately registered algorithmic study with
the Point-in-Time Portfolio-Library Retention Study and the Calibrated
Closure-Option Mechanism Experiment. The former reports retrospective
burden-index compression, option coverage, protected choices, and held-out
contrasts without using postdecision information in retention; the latter
isolates the bridge mechanism under prespecified synthetic regimes.

Current status: **implemented and bounded**. The registered algorithmic
benchmark, point-in-time financial study, and calibrated mechanism experiment
have sealed public-safe outputs and independent audits. The frozen randomized
(N=1024) study remains unchanged prior evidence. Financial findings remain
retrospective and descriptive, and the mechanism experiment remains synthetic:
no causal, forecasting, alpha, or deployable-performance claim is authorized.

## Contribution hierarchy and dependency locks

The journal argument must proceed in this order. A later level may use only
objects and results established at earlier levels.

| Level | Intended contribution | Current repository evidence | Gate for journal claim |
|---|---|---|---|
| 1. Semantic reduction | The operating frontier and generative closure form the productive library state. | Human-readable core results and selected formal artifacts identified in `THEOREM_LEDGER.md`. | State assumptions and the boundary between library state and full controlled state; retain the existing theorem meanings. |
| 2. Combinatorial optimization | Exact innovation-safe compression minimizes retention burden subject to exact preservation of both objects. | Existing definitions, feasibility tests, exact burden routines, enumeration, and MILP implementations. | Preserve source-relative equality, mandatory inactivity, exact rechecking, stable ties, and the solver/evidence distinction. |
| 3. Computational complexity | The identity-closure subclass is a tagged weighted covering problem and is computationally hard. | Human complexity theorem in the journal overlay; exact finite fixture; partial prose reduction. | Add a precise tagged-cover equivalence theorem and proof; delimit identity closure; state the polynomial-evaluation condition for any general-closure membership claim. |
| 4. Algorithms | Enumeration, exact joint bitmask DP, MILP, preprocessing, weighted greedy, and certified deletion. | Enumeration, MILP, lower-bound DP, and certified deletion are reusable. | Prove preprocessing; implement and oracle-test the joint DP; prove any greedy guarantee under explicit assumptions; exact-postcheck every output. |
| 5. Worst-case distinction | Safe local deletion need not imply global resource efficiency. | Existing fixed cardinality and weighted witnesses. | Keep the fixed theorem as proved. Add a parametric family only if a correct statement and proof survive counterexample search and exact fixtures. |
| 6. Computational evidence | A separately registered benchmark identifies scaling and structural difficulty. | No `algorithmic_compression_v1` study exists. The frozen (N=1024) study addresses different questions. | Lock a new design, registry, seeds, schemas, stopping rules, and feasible compute budget before running; do not use the long final benchmark unless explicitly authorized. |
| 7. Financial evidence | Point-in-time retention quantifies declared burden reduction and option coverage, while protected choices reveal whether those options are exercised. | Sealed common-equity panel and ETF replication with exact output rechecks, fixed proposal choices, and held-out evaluation boundary. | Keep the retrospective claim boundary, retain failures and adverse outcomes, exclude licensed rows, and source every number from committed manifests. |

## Formal problem contract

The exact journal formulation must include all of the following.

- A finite source library, a finite declared belief grid or state set, finite
  operating profiles, finite module sets, a declared closure operator, and a
  nonnegative retention-burden function.
- A mandatory inactive strategy retained at zero burden, including when a
  zero-valued frontier obligation would otherwise appear uncovered.
- Exact operating-frontier equality and exact generative-closure equality
  relative to the same source library.
- Positive weights for active entries in the identity-closure covering
  subclass, with belief tags and module tags kept disjoint.
- Stable ordering and exact tie handling so that enumeration, preprocessing,
  dynamic programming, MILP construction, heuristics, and exported artifacts
  use the same instance semantics.
- Independent exact postchecks of every algorithm-returned library for the four
  required invariants: frontier, closure, burden, and inactive retention.

The paper must distinguish the outer one-time retention decision from the
subsequent dynamic operating and research-control problem. A result about one is
not automatically a result about the other.

## Minimum viable and preferred journal versions

### Smallest defensible journal contribution

The smallest viable version retains the established productive-state reduction
and exact compression problem, adds a correct and fully proved identity-closure
tagged-cover equivalence and complexity result, presents exact enumeration and
postchecked MILP as complementary exact methods, keeps the established fixed
local/global counterexample, and reports the two existing retrospective
financial audits. The frozen (N=1024) randomized study may appear only as
condensed prior structural evidence in the Online Resource. This version does
not claim a joint exact DP, general preprocessing theory, a greedy
approximation guarantee, a parametric gap family, a scaling benchmark, or a new
financial algorithm comparison.

This is the minimum because it creates a coherent operations-research advance:
a financially motivated sufficient-state reduction, an exact weighted covering
model with hardness, auditable exact solution paths, and retrospective resource
consequences.

### Stronger preferred contribution

The preferred version adds proved reduction rules, an exact joint bitmask DP,
an approximation-guaranteed weighted greedy construction under explicit
assumptions, a proved worst-case local/global gap family, a separately
registered algorithmic scaling study, and a locked comparison of the resulting
algorithms in both financial audits. Any component that misses its proof,
validation, or design-lock gate is removed from the contribution list rather
than presented as completed.

## Exclusions from the journal identity

The following subjects may be retained as background or secondary Online
Resource material only when they directly support the locked paper. They are
not principal contributions: broad belief-occupation geometry, expansive
comparative-statics catalogues, approximate compression under numerical
tolerances, prediction, trading performance, alpha discovery, causal inference,
or a general theory of arbitrary closure computation.

## Evidence and source precedence

The immutable release PDFs are the historical preprint and supplement. The
editable manuscript sources, theorem ledger, artifact manifest, baseline audit,
and official-requirements audit are the working evidence. When they disagree,
the discrepancy must be resolved explicitly; the journal specification must not
silently overwrite the historical release or treat a generated artifact as more
authoritative than its registered source.

This specification authorizes no theorem, experiment, or manuscript change. It
defines the gates that later work must satisfy.
