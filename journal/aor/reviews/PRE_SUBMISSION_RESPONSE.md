# Unified pre-submission response to the OR and finance audits

**Decision date:** 2026-08-28  
**Article:** *Innovation-Safe Compression of Financial Strategy Libraries: Semantics, Complexity, and Algorithms*  
**Status:** author revision record; not a response to an external journal decision

## Revision policy

This response reconciles every FATAL, MAJOR, and MODERATE item in
`OR_REFEREE_REPORT.md`, `OR_ACTION_MATRIX.md`,
`FINANCE_REFEREE_REPORT.md`, and `FINANCE_ACTION_MATRIX.md`. Neither review
identified a FATAL defect. The revision accepts the central criticism that the
paper's strongest defensible identity is an operations-research reduction with
a conditional dynamic interpretation, a locked but limited synthetic study,
and two stylized retrospective financial cases. It does not manufacture a
stronger finance validation or reinterpret the locked benchmark after seeing
its outcomes.

The following labels are used for analysis proposals:

- **REGISTERED:** a new study that would require its own prospective design,
  registry, seeds, lock, and result tree before outcomes are generated;
- **ROBUSTNESS:** a prespecified sensitivity analysis that changes an input
  interpretation while preserving the primary estimand and information set;
- **EXPLORATORY:** a post-lock analysis of existing outcomes that cannot be
  presented as confirmatory.

No new scientific analysis is executed in this revision. Source audits,
theorem-label checks, compilation, and regression tests are verification, not
new empirical analysis.

## Decision on experimental redesign

A new algorithmic design is warranted, but it cannot be spliced into Registered
Algorithmic Compression Benchmark v2. The defensible follow-up is a
**PROPOSED REGISTERED--NOT YET RUN** benchmark in a new directory with new
seeds, registry, design lock, and results. Before locking, it should require:

1. algorithm-specific warm-up outside every timed region and separate compile,
   isolated steady-state, and concurrent-throughput estimands;
2. a mathematical feasibility check for every requested generator cell;
3. a material, prespecified fraction of instances with nonempty residual covers,
   graded residual requirement counts, symmetry, overlap, and relaxation gaps;
4. repeated randomized blocks on a clean committed tree;
5. common success targets: feasibility construction, certified gap attainment,
   and completed exact optimization must have separate profiles;
6. instance-clustered or paired inference, with the instance as the experimental
   unit and an estimability/alias audit before fitting;
7. removal of the maximum-release alias as an independent method;
8. prospective applicability checks for enumeration and DP limits; and
9. a bounded certified exchange baseline and an LP-relaxation lower-bound
   diagnostic.

This future design addresses OR-03--OR-07 and OR-10--OR-13. It is not part of
the current evidence, and no current manuscript statement anticipates its
outcome.

## Decision on expanded licensed financial evidence

The available licensed CRSP/WRDS history should be used in a stronger revision,
but simply generating more rows from the existing endpoint-survivor tuple
grammar would not answer FIN-01, FIN-03, FIN-07, FIN-08, or FIN-12. The warranted
extension is a **PROPOSED REGISTERED--NOT YET RUN** point-in-time financial
library panel with a new protocol and lock. Before any new outcome is computed,
it should fix:

1. multiple calendar decision origins and an origin-eligible universe rebuilt
   from security histories available at each origin, including discontinued
   securities where the license and data fields permit;
2. distinct, economically named source-library constructions rather than
   replicate labels applied to one Cartesian grammar;
3. module ownership, compatibility, and mandatory archival constraints defined
   from predecision metadata;
4. source instances retained regardless of whether preprocessing leaves an
   empty residual, with residual structure reported as an outcome rather than a
   selection criterion;
5. burden schedules calibrated to auditable predecision quantities when such
   logs exist, with scenario indices kept explicitly separate from measured
   resource units;
6. structural compression, algorithm agreement, and burden reduction as the
   primary outcomes; any later return-based quantity as a separate
   postdecision diagnostic;
7. origin-level dependence, overlap, delisting, revision, and missing-data
   handling, with terminal and annual estimands kept separate; and
8. a public aggregate schema that never exports raw licensed rows.

This data extension is scientifically preferable to enlarging the current two
case studies after their outcomes are known. It is a later registered phase,
not a hidden amendment to the present submission evidence.

## Primary design precedents for the proposed studies

The future designs above are not based on superficial vocabulary matches. They
adapt concrete safeguards from primary methodological sources:

- Dolan and Moré's performance-profile framework requires a common problem set
  and common performance target. That supports separate profiles for feasible
  construction, quality-qualified solutions, and completed exact search rather
  than the v2 mixed-success profile ([official Springer article](https://doi.org/10.1007/s101070100263)).
- MIPLIB 2017 uses feature-based diversity controls to avoid overrepresenting a
  narrow model family. The proposed benchmark adapts that principle to realized
  tagged-cover and residual-after-preprocessing features; it does not import
  MIPLIB instances or claim representativeness of financial libraries
  ([official MIPLIB selection methodology](https://miplib.zib.de/Selection_Methodology.html),
  [official MIPLIB article metadata](https://miplib.zib.de/)).
- Sullivan, Timmermann, and White evaluate trading rules relative to the full
  rule universe, while White formalizes the data-snooping problem. Those designs
  motivate freezing the candidate catalog, recording every tried specification,
  and separating structural retention outcomes from any return-based diagnostic
  ([official Journal of Finance page](https://doi.org/10.1111/0022-1082.00163),
  [official Econometrica page](https://doi.org/10.1111/1468-0262.00152)).
- Harvey, Liu, and Zhu show why large predictor collections require explicit
  multiple-testing discipline. The proposed panel therefore cannot treat the
  maximum realized descendant score as ordinary validation evidence
  ([official Review of Financial Studies page](https://doi.org/10.1093/rfs/hhv059)).
- McLean and Pontiff's post-publication design motivates origin-time cohorts and
  separate pre/post decision periods rather than a single endpoint-stable
  snapshot ([official Journal of Finance page](https://doi.org/10.1111/jofi.12365)).
- Lakner supplies an established financial partial-information model. It
  clarifies what a genuine filtering extension would require; merely renaming
  observed signal bins as beliefs would not instantiate it
  ([official journal DOI](https://doi.org/10.1016/S0304-4149(98)00032-5)).

These are design inspirations, not evidence about the outcomes of either
proposed study. The exact adapted protocol must be written, internally audited,
and locked before the expanded licensed rows or new benchmark outcomes are
examined.

## Operations-research issues

| ID | Decision | Reason | Files to change | Tests or evidence required | Can locked v2 answer without post hoc alteration? | Analysis label |
|---|---|---|---|---|---|---|
| OR-01 | **PARTIALLY ACCEPT** | The projection theorem is valid as a conditional factorization result, so the proof is not circular; the novelty language nevertheless overstated how much the factorization is derived. | `journal/aor/manuscript/main.tex`; `01_introduction.tex`; `03_model_projection.tex`; `09_conclusion.tex`; `journal/aor/online_resource/sections/02_productive_equivalence.tex` | Preserve the theorem assumptions; add an operational factorization checklist, one model class satisfying it, and a countermodel where raw identity or cardinality matters. Run theorem-label and LaTeX checks; no theorem weakening. | **No.** V2 begins after a tagged instance exists and contains no dynamic-process evidence. | None; theory clarification only. |
| OR-02 | **ACCEPT** | Identity-closure compression is weighted set cover after the semantic reduction. Set-cover algorithms, MIP, mask DP, and generic preprocessing are antecedents, not new OR theory. | `main.tex`; `01_introduction.tex`; `02_literature.tex`; `04_cover_complexity.tex`; `05_algorithms.tex`; `09_conclusion.tex` | Citation consistency and claim audit; retain the tagged semantic mapping and the named deletion-gap theorem as the application-specific consequences. | **No.** A benchmark cannot create theoretical novelty. | None. |
| OR-03 | **ACCEPT** | Cold Julia compilation is inside the v2 timing estimand and often dominates it. Existing wall times cannot identify steady-state algorithm speed. | `main.tex`; `01_introduction.tex`; `07_computational_study.tex`; `09_conclusion.tex`; `online_resource/sections/12_registered_algorithmic_benchmark_v2.tex` | Preserve raw timings and provenance; remove runtime rankings/scaling inference and label all v2 times cold-start concurrent records. A valid speed study requires the proposed new lock. | **No.** The missing steady-state estimand cannot be recovered from v2. | **REGISTERED** future benchmark. |
| OR-04 | **ACCEPT** | A profile that treats heuristic feasibility and completed exact search as one success event lacks a common target. | `07_computational_study.tex`; `online_resource/sections/12_registered_algorithmic_benchmark_v2.tex`; submission narrative and figure-routing text | Do not use the existing profile for a comparative claim. A future design must separate feasibility, quality-qualified, and exact-completion profiles. Audit submitted PDFs for any unqualified performance-profile claim. | **No.** Redefining success after lock would be post hoc. | **REGISTERED** future benchmark; any v2 reprofile would be **EXPLORATORY** and is not added. |
| OR-05 | **ACCEPT** | Complete structured factor cells are absent because the requested incidence constraints are infeasible. Retaining failures is correct but does not restore estimability. | `07_computational_study.tex`; `online_resource/sections/12_registered_algorithmic_benchmark_v2.tex` | State the 16-instance/352-run-unit structural failure and prohibit interpretation of missing effects/interactions. Future generator cells require a feasibility proof/check before lock. | **Only descriptively.** V2 identifies the failure; it cannot estimate absent cells. | **REGISTERED** future benchmark. |
| OR-06 | **ACCEPT** | Family B primarily demonstrates forced preprocessing; it is weak evidence about residual MIP/DP search difficulty. | `main.tex`; `01_introduction.tex`; `07_computational_study.tex`; `09_conclusion.tex`; OR1 Section S12 | Limit the finding to preprocessing prevalence and certified burden comparisons. Do not claim general algorithmic scaling. Future instances must control residual difficulty. | **Yes for preprocessing prevalence; no for nontrivial search scaling.** | **REGISTERED** future benchmark. |
| OR-07 | **ACCEPT** | HC3 does not address repeated algorithm observations within an instance, and complete missing cells impair estimability. | `07_computational_study.tex`; OR1 Section S12 | Withdraw inferential use of the registered coefficients and intervals; preserve them as an executed-analysis record with an explicit invalid-for-inference warning. Do not substitute an unregistered clustered model. | **No confirmatory answer.** Existing rows could support an **EXPLORATORY** clustered reanalysis, but none is used here. | **EXPLORATORY** only if later requested; future confirmatory analysis must be **REGISTERED**. |
| OR-08 | **ACCEPT** | The two financial instances are informative audits but both have empty residual models and proxy burdens. | `main.tex`; `01_introduction.tex`; `08_financial_case_studies.tex`; `09_conclusion.tex`; OR1 Section S13 | Recast as stylized retrospective cases; use burden-index language; state that held-out equality is implied by exact closure equality. Preserve exact certificates and separate units. | **No.** V2 is synthetic and cannot expand financial external validity. | New broad financial evidence would be **REGISTERED**. |
| OR-09 | **ACCEPT** | The manuscript is overextended relative to the evidence. | `main.tex`; `01_introduction.tex`; `06_economic_implications.tex`; `07_computational_study.tex`; `08_financial_case_studies.tex`; `09_conclusion.tex`; OR1 | Center the article on conditional semantics, the tagged reduction, exact/certified algorithms, and bounded evidence. Move capacity/price theorem detail online and remove unsupported runtime/statistical narratives. Compile and inspect page allocation. | **Not applicable.** | None. |
| OR-10 | **ACCEPT, WITH IMMUTABLE-RESULT QUALIFICATION** | Maximum immediate additive burden release is exactly heaviest-safe-first. It is not an independent scientific method. | `05_algorithms.tex`; `07_computational_study.tex`; OR1 Section S12 | State the alias explicitly and do not use it as independent corroboration. Preserve the locked raw rows and generated result tables rather than deleting an observed category after lock. A future registry contains one method. | **Yes.** V2 proves the rows coincide, but its registered raw records remain immutable. | None; future removal is **REGISTERED** design hygiene. |
| OR-11 | **PARTIALLY ACCEPT** | The six statuses are registered implementation errors, but substantively arose because enumeration exceeded its declared applicability cap. Historical statuses must not be rewritten. | `07_computational_study.tex`; OR1 Section S12 | Report method-specific denominators and explain policy inapplicability without changing raw/audit statuses. Add future pre-lock applicability validation. | **Yes descriptively.** The committed records identify all six cases; they do not provide enumeration results. | None; future validation is **REGISTERED**. |
| OR-12 | **ACCEPT AS A SCOPE LIMIT** | A bounded exchange method and LP lower bound would improve the local/global comparison, but adding them now would be a post-outcome algorithm expansion. | `05_algorithms.tex`; `07_computational_study.tex`; `09_conclusion.tex`; response's proposed design | State that the theorem concerns one-deletion irreducibility and the named rule, not stronger neighborhoods. Place both baselines in the future design. | **No.** They were not registered or run. | **REGISTERED** future benchmark. |
| OR-13 | **ACCEPT** | One cold observation under eight-worker contention and a dirty tree is inadequate for close rankings. | `07_computational_study.tex`; OR1 Section S12; `09_conclusion.tex` | Preserve the execution record; remove fine runtime rankings. The future design records clean commit state and repeated isolated/blocked timing. | **No.** | **REGISTERED** future benchmark. |
| OR-14 | **ACCEPT** | The partial v1 execution is salient provenance even though no v1 outcome was pooled or used to tune v2. | `online_resource/sections/12_registered_algorithmic_benchmark_v2.tex` | Add dates, terminal-record/instance counts, what was visible, what changed, and the infrastructure-only claim boundary; preserve both histories. Run source/provenance audit. | **Yes.** Existing committed notices supply the chronology. | None. |
| OR-15 | **ACCEPT** | Literal `(AOR...)` tokens are a submission-integrity defect. | `online_resource/sections/12_registered_algorithmic_benchmark_v2.tex`; `scripts/aor_source_completeness.sh` | Replace literals with generated LaTeX commands and add source/PDF placeholder scans. Recompile both PDFs and extract text. | **Yes.** Correct macros already exist; no result changes. | None. |
| OR-16 | **ACCEPT** | Active ledger locations should point to compiled theorem files, with migration sources retained only as provenance. | `THEOREM_LEDGER.md`; `scripts/aor_source_completeness.sh` | Update SC-TAG, SC-COMP, SC-DP, SC-GREEDY, SC-DEL-SUITE, and related active mappings. Add a uniqueness/existence gate for principal labels. Run `make aor-theory-check`. | **Not applicable.** | None. |

## Quantitative-finance and stochastic-control issues

| ID | Decision | Reason | Files to change | Tests or evidence required | Can locked v2 answer without post hoc alteration? | Analysis label |
|---|---|---|---|---|---|---|
| FIN-01 | **PARTIALLY ACCEPT** | A finite strategy catalog is a credible stylized object, but the audits do not show that deleting a row destroys separately versioned code, data, tests, or knowledge. | `main.tex`; `01_introduction.tex`; `03_model_projection.tex`; `08_financial_case_studies.tex`; OR1 Section S13 | Define retention as active-maintenance status in a declared tuple grammar. State that modules are audit tags, not proof of physical artifact ownership. Do not add separate module-cost variables without a new model and data. | **No.** V2 has abstract tagged rows only. | A real inventory study would be **REGISTERED**. |
| FIN-02 | **PARTIALLY ACCEPT** | Partial information is essential to the conditional control theorem but not to tagged covering or the financial cases, whose rows are observed SPY-signal bins. | `main.tex`; `01_introduction.tex`; `02_literature.tex`; `03_model_projection.tex`; `08_financial_case_studies.tex`; `09_conclusion.tex`; OR1 title/front matter | Remove partial information from the title and empirical contribution. State exactly where filtering enters the theorem and where only a finite regime index is used. | **No.** | None; an empirical hidden-state extension would be **REGISTERED**. |
| FIN-03 | **ACCEPT** | Identity union is a strong compatibility assumption and the audits do not establish frictionless organizational recombination. | `03_model_projection.tex`; `04_cover_complexity.tex`; `08_financial_case_studies.tex`; OR1 Section S13 | Confine empirical claims to the declared tuple grammar and identity-union enablement rule. Retain existing nonidentity counterexamples. Do not claim organizational generative capability. | **No.** V2 is identity-closure by design. | A compatibility-aware sensitivity would be **ROBUSTNESS**, prospectively specified. |
| FIN-04 | **ACCEPT** | The article and resource omit the actual mean--variance validation-profile formula and its units. | `08_financial_case_studies.tex`; `online_resource/sections/13_financial_secondary_tests.tex` | State the implemented formula, annualization 252, risk aversion 3, sample-variance convention, turnover-cost deduction, 5 bp primary cost, 1/5/10 bp sensitivity, and that the quantity is an estimated audit score. Cross-check against both Julia scripts and locked configs. | **No.** This is disclosure from existing financial artifacts, not v2. | None; alternative preference/cost schedules would be **ROBUSTNESS**. |
| FIN-05 | **ACCEPT** | Generation, verification, admission, and duration are mathematically specified but not empirically instantiated. | `main.tex`; `01_introduction.tex`; `03_model_projection.tex`; `08_financial_case_studies.tex`; `09_conclusion.tex`; OR1 Sections S1/S13 | Separate the conditional dynamic theorem from the static retrospective grammar audits. Do not imply the financial cases estimate project laws or durations. | **No.** | A documented dynamic workflow would require **REGISTERED** new evidence. |
| FIN-06 | **ACCEPT** | Exact reconstruction is conditional on committed tables and does not remove sampling error, drift, or model misspecification. | `main.tex`; `01_introduction.tex`; `03_model_projection.tex`; `08_financial_case_studies.tex`; `09_conclusion.tex`; OR1 Section S13 | Use “table-exact” or “artifact-exact” for financial preservation and state the original registered floating tolerances. Preserve the distinction from exact rational theorem fixtures. | **No.** | Profile-uncertainty sensitivity would be **ROBUSTNESS**. |
| FIN-07 | **ACCEPT** | Equal, validation-computation, and governance schedules are exact burden indices, not measured dollars, labor hours, or compute consumption. | `main.tex`; `01_introduction.tex`; `03_model_projection.tex`; `08_financial_case_studies.tex`; `09_conclusion.tex`; OR1 Section S13 | Replace “resource savings” with “burden-index reduction” for the audits; retain formulas and predecision boundary; state that additivity is a modeling assumption. | **No.** | Measured cost calibration would be **REGISTERED**. |
| FIN-08 | **PARTIALLY ACCEPT** | No direct outcome leakage was detected, but endpoint-stable universes and a current CRSP snapshot create disclosed population-level look-ahead. | `08_financial_case_studies.tex`; OR1 Section S13; `09_conclusion.tex` | Put survivorship, endpoint identity, and snapshot-revision limits in the main article; avoid prospective/out-of-sample population language. Preserve the decision-time outcome firewall. | **No.** | Point-in-time universe evidence would be **REGISTERED**. |
| FIN-09 | **ACCEPT** | Safe-library `Q_a` equality follows mechanically from enabled-set equality, and the frontier-only loss is an ex post maximum over a large fixed grammar. | `main.tex`; `01_introduction.tex`; `08_financial_case_studies.tex`; OR1 Section S13; finance figure caption; `09_conclusion.tex` | Rename `Q_a` an ex post catalog witness; state that safe equality is deterministic and frontier-only loss is not independent validation. Do not add multiplicity corrections post hoc. | **No.** | A predesignated/multiplicity-aware extension would be **REGISTERED** or prespecified **ROBUSTNESS**. |
| FIN-10 | **ACCEPT** | Some “highest-quality,” “worth retaining,” and “financial evidence” language invites alpha or forecasting interpretations despite explicit disclaimers. | `main.tex`; `01_introduction.tex`; `08_financial_case_studies.tex`; OR1 Section S13; finance figure; `09_conclusion.tex` | Use neutral mechanism/case/witness language and move named ex post carriers out of the main narrative. Retain all unfavorable outcomes and nonclaims. | **No.** | None. |
| FIN-12 | **ACCEPT** | Two empty-residual source instances cannot establish general finance-library performance or algorithm choice. | `main.tex`; `01_introduction.tex`; `08_financial_case_studies.tex`; `09_conclusion.tex`; OR1 Section S13 | Call them two stylized retrospective audits of the registered tuple grammar; state the sample and residual limitations adjacent to results. | **No.** | Broader point-in-time, nonempty-residual cases would be **REGISTERED**. |
| FIN-13 | **ACCEPT** | Binary retention currently conflates active maintenance with archival and legal-record retention. | `01_introduction.tex`; `03_model_projection.tex`; `08_financial_case_studies.tex`; `02_literature.tex` | Define the decision as removal from the active maintenance/validation set, not physical deletion. State that mandatory legal archive, ownership, independent validation, and reactivation are outside the binary model. | **No.** | A multi-tier governance model would be **REGISTERED** if quantified. |
| FIN-14 | **ACCEPT** | The fixed grammar and ex post maximum require direct engagement with data snooping, multiple testing, backtest overfitting, decay, financial filtering, and model lifecycle. | `02_literature.tex`; `journal/aor/manuscript/bibliography/references.bib`; `journal/aor/online_resource/bibliography/references.bib` | Add only primary, metadata-verified sources and connect them to specific design limits. Run bibliography and citation checks. | **No.** | None. |
| FIN-15 | **PARTIALLY ACCEPT** | The paper belongs in OR, but its finance title and framing exceeded the evidence. A full new finance inventory is not available in this revision. | `main.tex`; `01_introduction.tex`; `06_economic_implications.tex`; `07_computational_study.tex`; `08_financial_case_studies.tex`; `09_conclusion.tex`; OR1 title/front matter | Retain the OR core, shorten secondary economics and invalid computational inference, and present finance as two bounded applications rather than validation. | **No.** | Stronger finance identity would require **REGISTERED** new evidence. |
| FIN-16 | **ACCEPT** | The dedicated weight lock governs a retrospective replay after schedules and some outcomes were already known. | `08_financial_case_studies.tex`; OR1 Section S13; `09_conclusion.tex` | Rename it “locked retrospective weight replay” and repeat the chronology; reserve prospective language for genuinely first-look studies. | **No.** | None. |

## Implementation record

**Implementation status:** COMPLETE.

No locked v2 design file, registry, seed, raw result, audit certificate, or
analysis rule was changed. No frozen v1/N=1024 artifact, arXiv release artifact,
or licensed row was changed. No new benchmark or financial outcome was run. The
two proposed studies above remain proposals: they are neither registered nor
evidence in the article.

### Exact change locations

Line references below identify the revised source at this commit. The decision
tables above remain the issue-by-issue record; this table maps every accepted or
partly accepted FATAL/MAJOR/MODERATE issue to the implemented text or gate.

| Issues | Implemented location |
|---|---|
| OR-01; FIN-02; FIN-05; FIN-06 | Conditional representation and evidence boundary: `journal/aor/manuscript/main.tex:73-94`; `journal/aor/manuscript/01_introduction.tex:28-46,78-99,127-168`; operational audit, countermodel, theorem assumptions, and table-exact burden boundary: `journal/aor/manuscript/03_model_projection.tex:127-192,194-218`; full audit and countermodel: `journal/aor/online_resource/sections/02_productive_equivalence.tex:62-82`. |
| OR-02 | Explicit established-cover/non-novelty boundary: `journal/aor/manuscript/01_introduction.tex:52-76,135-148`; `journal/aor/manuscript/04_cover_complexity.tex:67-83`; `journal/aor/manuscript/05_algorithms.tex:24-45`; `journal/aor/manuscript/09_conclusion.tex:13-31`. |
| OR-03; OR-04; OR-05; OR-06; OR-07; OR-10; OR-11; OR-13 | Immutable-result interpretation and failure accounting: `journal/aor/manuscript/07_computational_study.tex:24-53,76-135`; generated 16-instance/352-run count: `julia/scripts/build_aor_manuscript_evidence_inputs.jl:208-240`; full executed-record limits and v1/v2 provenance: `journal/aor/online_resource/sections/12_registered_algorithmic_benchmark_v2.tex:54-152`. |
| OR-12 | One-deletion and named-rule scope plus deferred exchange/LP baselines: `journal/aor/manuscript/05_algorithms.tex:220-244,326-339`; `journal/aor/manuscript/07_computational_study.tex:124-136`; `journal/aor/online_resource/sections/12_registered_algorithmic_benchmark_v2.tex:133-152`. |
| OR-08; FIN-01; FIN-03; FIN-04; FIN-07; FIN-08; FIN-09; FIN-10; FIN-12; FIN-13; FIN-15; FIN-16 | Retrospective-case scope, timing, implemented utility, exact-preprocessing certificate, tuple ontology, burden indices, survivor boundary, catalog-maximum interpretation, and archival distinction: `journal/aor/manuscript/08_financial_case_studies.tex:6-77,81-193`; detailed formulas and secondary-record limits: `journal/aor/online_resource/sections/13_financial_secondary_tests.tex:21-101,137-183,196-259,321-335`; neutral figure labels and caption: `journal/aor/manuscript/figures/financial_innovation_safe_compression.tex:1-77`; `journal/aor/manuscript/figures/generated_inputs.tex:12-25`; compact generated tables: `journal/aor/manuscript/tables/financial_instance_summary.tex:1-19` and `journal/aor/online_resource/tables/financial_design_summary.tex:1-19`. |
| OR-09 | Breadth reduction and article identity: title/abstract at `journal/aor/manuscript/main.tex:55-97`; contribution hierarchy at `journal/aor/manuscript/01_introduction.tex:123-168`; condensed economic consequences at `journal/aor/manuscript/06_economic_implications.tex:1-131`; bounded conclusion at `journal/aor/manuscript/09_conclusion.tex:1-60`; displaced capacity/price proofs at `journal/aor/online_resource/sections/09_extended_comparative_statics.tex:1-81`. |
| OR-14 | Partial v1 chronology, visible-result boundary, and non-pooling statement: `journal/aor/online_resource/sections/12_registered_algorithmic_benchmark_v2.tex:24-53`. |
| OR-15 | Literal placeholders replaced by evidence macros in `journal/aor/online_resource/sections/12_registered_algorithmic_benchmark_v2.tex:54-152`; source and extracted-PDF scans at `scripts/aor_source_completeness.sh:15-16,84-103`. |
| OR-16 | Active compiled theorem sources in `THEOREM_LEDGER.md:439-902`; source/label uniqueness gate in `scripts/aor_source_completeness.sh:104-127`. |
| FIN-14 | Financial filtering, data-snooping, multiple-testing, and decay literature: `journal/aor/manuscript/02_literature.tex:154-194`; verified entries in `journal/aor/manuscript/bibliography/references.bib` and `journal/aor/online_resource/bibliography/references.bib`. |

The future-design discussion informed by Dolan--Moré, MIPLIB, financial
data-snooping, multiple-testing, post-publication decay, and financial filtering
appears only in this response and in prospective-limit prose at
`journal/aor/manuscript/07_computational_study.tex:131-136`,
`journal/aor/manuscript/08_financial_case_studies.tex:183-193`, and
`journal/aor/manuscript/09_conclusion.tex:50-60`. It does not relabel any new or
post hoc result as registered evidence.

### Verification performed

- `julia --project=julia julia/scripts/build_aor_manuscript_evidence_inputs.jl --write`
  generated nine LaTeX inputs exclusively from committed evidence artifacts;
  the corresponding `--check` passed.
- `make aor-theory-check` passed exact Julia theorem fixtures, the 3,207-job
  Lean build, manuscript theorem lint, fixture bridging, and the axiom audit of
  784 declarations. The allowed axiom set remained `propext`,
  `Classical.choice`, and `Quot.sound` or fewer.
- `make aor-algorithm-tests` passed tagged-cover, preprocessing, schema,
  enumeration, requirement-mask DP, greedy, deletion, JuMP/HiGHS, exactness,
  failure-retention, and committed small-matrix tests. This included exhaustive
  enumeration--DP comparisons and enumeration--MIP comparisons.
- `make aor-manuscript` compiled the 39-page article and 101-page Online
  Resource 1 and passed bibliography, unresolved-reference, input-completeness,
  placeholder, and theorem-label audits. The abstract contains 192 words and
  the PDF metadata carry the revised title.
- Pages affected by the compact financial table and mechanism figure were
  rendered and inspected after the final compilation; no collision or
  color-only distinction remained.
- `make aor-check` passed all nonmutating gates. Its committed-result audit
  reproduced the audit summary byte-for-byte: 3,907 terminal records, 3,526
  accepted solutions, 31 exact-agreement instances, and 381 unsuccessful
  records. Its public-boundary audit found zero tracked licensed or private
  rows. It explicitly did not rerun the final benchmark or licensed financial
  workflows.

### Remaining risks after revision

1. The semantic projection remains conditional on the stated factorization
   assumptions; it is not an empirically established minimal state.
2. Generic identity-closure algorithms are established set-cover machinery.
   The defensible contribution is the semantic reduction, tagged mapping,
   certified integration, and named deletion-gap consequence.
3. Benchmark v2 cannot support steady-state runtime rankings, complete-factorial
   structural inference, or broad claims about difficult residual search. The
   registered model outputs remain archived but are not used inferentially.
4. The previous terminal and annual cases have been replaced in the active
   manuscript by the point-in-time portfolio-library study. That study repairs
   future-survivor conditioning and unequal option-set comparisons, but it
   remains retrospective, uses a declared capability grammar and proxy burden
   index, and produces a common-equity policy null plus one adverse ETF
   exercise. The calibrated closure-option experiment is synthetic and cannot
   cure external-validity limits.
5. The article does not solve arbitrary nonidentity closure, calibrate actual
   institutional maintenance costs, or establish alpha, forecasting, causal,
   population, or deployable-performance claims.

**Exact next recommended task:** obtain or define a newly locked market vintage
or independent panel before outcome access, with documented institutional
capability ownership and monetary maintenance costs calibrated independently
of postdecision returns. The completed point-in-time and calibrated mechanism
studies must remain sealed and must not be amended to manufacture a stronger
financial result.
