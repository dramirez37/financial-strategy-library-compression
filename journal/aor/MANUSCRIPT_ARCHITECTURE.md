# AoOR manuscript architecture

Status: architecture lock before substantive journal implementation

Companion documents: `CONTRIBUTION_SPEC.md`, `CLAIM_BOUNDARY.md`, and
`MATERIAL_MIGRATION_MAP.md`

## Length policy

The official pages inspected for `requirements/OFFICIAL_REQUIREMENTS.md` did
not state a full-manuscript word or page limit. They did state an abstract range
of 150--250 words and a limit of 4--6 keywords. The ranges below are therefore
content-driven planning ranges, not attributed journal requirements. They are
page estimates in the selected Springer journal layout and must be recalibrated
after the new theory and registered results exist.

| Component | Target pages |
|---|---:|
| Main text, Sections 1--9 | 32--42 |
| Title page, abstract, keywords, and required declarations | 1--2 |
| References | 3--5 |
| **Total journal article** | **36--49** |

The Online Resource is outside this total. A provisional 25--40 pages is
reasonable for complete proofs, certificates, study documentation, secondary
results, and reproducibility records, but it is not a journal-imposed limit.

## Main-paper sequence

### 1. Introduction — 3--4 pages

Lead with the financial retention decision: operational redundancy need not be
generative redundancy. State the productive library state, exact
minimum-burden problem, intended algorithmic contribution, and retrospective
evidence. Give the four principal contributions in the order fixed by
`CONTRIBUTION_SPEC.md`. State the nonclaims once, compactly. Do not lead with
the dynamic-programming application or with approximate compression.

Main materials: one motivating bridge figure (`innovation_safe_bridge.tex`)
and no numerical result table.

### 2. Literature and problem positioning — 3--4 pages

Position the work against operations-research covering and library-reduction
problems, safe screening/deletion, strategy and model libraries in quantitative
finance, dynamic operating/research decisions, and empirical model governance.
The section must distinguish the paper from feature selection, portfolio
selection, forecasting, and performance backtests. Citation changes require
source verification; this architecture does not authorize new citations.

### 3. Financial strategy-library model and sufficient state — 4--5 pages

Define strategies, operating profiles, regimes/beliefs, modules, closure,
frontier, burden, and the mandatory inactive strategy. State the
raw-to-compressed projection and make the precise sufficiency claim: frontier
and closure summarize the library component of the controlled state, while
belief and active-project variables remain in the full state. Give the one-time
retention decision separately from subsequent dynamic operation.

Main results: raw-to-compressed projection; minimum-resource representation may
be introduced at the end to bridge to Section 4.

### 4. Exact compression, covering representation, and complexity — 5--6 pages

Formulate exact innovation-safe compression. State the frontier--closure
characterization and the identity-closure tagged weighted covering equivalence,
if proved. Establish the corresponding complexity result without implying that
arbitrary closure evaluation is free. Explain the disjoint operating and module
tag construction and the role of the zero-burden inactive strategy.

This section owns the formal optimization model. Algorithmic implementation
details belong in Section 5. If the tagged-cover theorem fails its proof gate,
the paper reverts to the minimum viable architecture and narrows the complexity
claim accordingly.

### 5. Algorithms and guarantees — 6--8 pages

Present a common instance contract and exact postcheck before individual
methods. Then cover, in dependency order:

1. exact enumeration as the small-instance oracle;
2. proved preprocessing rules;
3. exact joint bitmask dynamic programming;
4. mixed-integer optimization and the solver-evidence boundary;
5. weighted greedy construction, with an approximation guarantee only if one is
   proved under explicit assumptions;
6. certified deletion heuristics.

Use a compact method/guarantee/complexity table generated from committed
artifacts or source metadata. Do not call the existing operational-cover
lower-bound DP an exact joint DP. Every method that returns a library must pass
the same exact four-part postcheck.

### 6. Economic consequences of unsafe and capacity-constrained retention — 3--4 pages

State the sharp normalized frontier-only loss result, keep the established
fixed local/global counterexample, and present capacity-constrained retention
and the penalized value envelope in compressed form. The operational--generative
decomposition should serve interpretation, not open a second broad theory
paper. A parametric local/global gap family appears only after proof and exact
fixture gates pass.

Main materials: a compact local/global witness table and, at most, one composite
economic-geometry figure (`unified_economic_geometry.tex`). Detailed canonical
dynamics and comparative statics move to the Online Resource.

### 7. Registered computational study — 3--4 pages

Report only the future, separately locked
`experiments/algorithmic_compression_v1/` benchmark. Describe instance classes,
factor ranges, new seed registry, design lock and amendments, hardware/runtime
protocol, stopping/status rules, exact-oracle regime, postchecks, and the
predeclared estimands for scaling and structural difficulty.

The frozen (N=1024) randomized study is not this benchmark. It may be cited as
prior structural evidence and summarized in the Online Resource, but its files,
seeds, design locks, amendments, and committed results remain unchanged. If the
new study is not completed, Section 7 is removed and the title/contribution list
must not promise algorithmic scaling evidence.

### 8. Financial case studies — 4--5 pages

Present the Point-in-Time Portfolio-Library Retention Study as the retrospective
financial case study, with its common-equity origins and ETF replication kept
separate. Report exact source-relative frontier, closure, inactive-retention,
and burden rechecks; burden-index reduction; additional option coverage;
protected proposal choices; and the complete held-out null/adverse result. The
Calibrated Closure-Option Mechanism Experiment belongs in Section 6 as
synthetic mechanism evidence, not in Section 8 as financial evidence.

Held-out financial information is evaluation-only. Raw CRSP/WRDS rows remain
outside the repository and submission bundle. The section must retain the
noncausal, nonforecasting, non-alpha, and nondeployable boundaries.

### 9. Conclusion — 1--2 pages

Restate the OR problem, sufficient library state, algorithmic lessons, and
retrospective resource implications. Separate proved results from computational
evidence and name the most important limitations: finite declared state space,
source-relative equality, closure specification, solver optimality evidence,
and nonprospective financial analysis.

## Online Resource architecture

The current supplement should be reorganized, not expanded indiscriminately.
The target order is:

1. complete assumptions, auxiliary definitions, and long proofs;
2. tagged-cover, complexity, preprocessing, DP, and any gap-family proof details;
3. exact finite fixtures and oracle/postcheck certificates;
4. full registered algorithmic-study design and secondary results;
5. condensed frozen randomized-study record, explicitly marked historical and
   immutable;
6. full financial audit designs, information sets, uncertainty/secondary tests,
   and licensed-data boundary;
7. formal-verification correspondence and reproducibility records.

The coverage-geometry and broad comparative-statics branch is removed from the
journal package under the current identity unless a later documented decision
shows that a specific item is necessary to support a retained claim. It remains
in repository history.

## Cross-section claim flow

The dependency chain is:

`library semantics -> exact preservation constraints -> tagged cover and
complexity -> algorithms and certificates -> economic failure modes ->
registered scaling evidence -> retrospective financial evidence`.

No later section may repair a missing earlier proof with numerical evidence. In
particular, a successful MILP run cannot establish the covering theorem, a
synthetic benchmark cannot establish a financial claim, and retrospective
financial findings cannot choose the algorithms or weights being evaluated.

## Submission-facing architecture constraints

Later manuscript implementation must also satisfy the official-requirements
audit:

- a 150--250 word abstract and 4--6 keywords;
- an editable title page with complete author information;
- the required data-availability, competing-interest, author-contribution, and
  generative-AI declarations as applicable;
- editable manuscript, figure, and table sources, with supplementary files
  identified as Online Resource material;
- accessible figure captions and non-color-only encodings;
- journal-consistent reference formatting without assuming that the locally
  bundled style file is officially mandated.

The local AOR build and its bundled template are working materials. The exact
submission format and routing remain governed by the official pages recorded in
`requirements/OFFICIAL_REQUIREMENTS.md`.

## Implementation rule

No source section is moved or rewritten merely because it appears in this plan.
Migration occurs only after the relevant theorem or experiment gate is resolved,
and every manuscript number must be generated from a committed artifact rather
than transcribed by hand.
