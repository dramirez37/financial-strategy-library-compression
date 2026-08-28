# Online Resource 1 source migration and provenance

This manifest records the source of every content class used in Online
Resource 1. It is an editorial reorganization: no frozen design, seed,
registry, theorem meaning, solver status, or empirical result is changed.

## Section map

| Online Resource section | Content | Primary source | Transformation and evidence boundary |
|---|---|---|---|
| S1 | Probability normalization and complete projection proof | `journal/aor/manuscript/online_resource/01_probability_normalization.tex`; proof material in `manuscript/appendices/a_additional_formal_definitions.tex` | Normalization text migrated; projection proof restated against the journal assumptions so the resource compiles independently. Human proof. |
| S2 | Productive preservation and quotient boundary | `manuscript/appendices/a_additional_formal_definitions.tex`; `journal/aor/manuscript/03_model_projection.tex`; `journal/aor/manuscript/04_cover_complexity.tex` | Condensed theorem support; detectability is isolated to the converse. Human proof. |
| S3 | Belief occupation and coverage | `manuscript/online_supplement/s1_belief_occupation_coverage.tex` | Preserved extended theory; moved out of the journal main article. |
| S4 | Tagged-cover equivalence, boundary examples, NP-completeness, reduction audit | `journal/aor/manuscript/04_tagged_cover_equivalence.tex`; `journal/aor/manuscript/05_identity_closure_complexity.tex` | Complete journal-program proofs retained outside the main article. The equivalence has a Lean-verified universal core; NP-completeness is human proof only. |
| S5 | Preprocessing propositions | `journal/aor/reports/PREPROCESSING_THEORY.md`; `journal/aor/manuscript/04_cover_complexity.tex` | Proofs reorganized into one section; optimizer-identity limits stated explicitly. Human proof, with narrower Lean feasibility cores. |
| S6 | Enumeration, mask DP, greedy, and certified deletion | `journal/aor/manuscript/07_exact_requirement_mask_algorithms.tex`; `08_weighted_greedy_construction.tex`; `09_certified_deletion_suite.tex` | Full proofs, pseudocode, certificates, and scope boundaries. Approximation transfer remains human proof only. |
| S7 | Parameterized local/global gap | `journal/aor/manuscript/06_safe_deletion_gap_family.tex` | Complete family proof and exact fixture boundary. Human proof; one finite arithmetic fixture is Lean verified. |
| S8 | Frontier--closure interaction | `manuscript/online_supplement/s2_frontier_closure_interaction.tex` | Preserved extended result, not part of the main compression spine. |
| S9 | Comparative statics, auxiliary models, and counterexamples | `manuscript/online_supplement/s3_comparative_statics_counterexamples.tex`; `s3_auxiliary_models.tex`; `journal/aor/manuscript/online_resource/03_secondary_comparative_statics.tex` | Reorganized under one section. Not used for algorithm selection or financial weighting. |
| S10 | Canonical numerical records | `manuscript/online_supplement/s4_complete_canonical_numerical_records.tex` | Preserved; tables continue to read committed machine CSVs. Exact rational and Float64 evidence remain distinguished. |
| S11 | Frozen randomized-library study | `manuscript/online_supplement/s5_complete_registered_randomized_study.tex`; `experiments/randomized_library_v2/`; `experiments/results/summaries/randomized_library_v2_*` | Historical preprint-era N=1024 study. No design, seed, registry, amendment, or result file is modified or relabeled. The historical pilot comparison is marked as provenance, not final evidence. |
| S12 | Registered Algorithmic Compression Benchmark v2 | `experiments/algorithmic_compression_v2/`; `journal/aor/reports/ALGORITHMIC_RESULTS.md`; generated `journal/aor/tables/` inputs | Separate new registered synthetic study. Final audited results only; v1 outputs excluded. Solver evidence and exact finite agreement are labeled separately. |
| S13 | Financial secondary tests and algorithm comparison | `manuscript/online_supplement/s6_full_financial_audit_secondary_tests.tex`; `journal/aor/reports/FINANCIAL_ALGORITHM_RESULTS.md`; committed public aggregate financial tables | Retrospective licensed-data analyses represented only by redistributable aggregates. Terminal and annual held-out units remain separate. |
| S14 | Solver and exactness records | `journal/aor/reports/MIP_SPECIFICATION.md`; `EXACTNESS_AUDIT_PROTOCOL.md`; benchmark and financial audit certificates | Status and postcheck boundary restated. Empty-residual certificates are exact finite computation plus human preprocessing theory, not solver or Lean proof. |
| S15 | Theorem--evidence correspondence | `THEOREM_LEDGER.md`; `ARTIFACT_MANIFEST.md`; formal audit sources | Short ledger-derived table replaces stale long-form correspondence. |
| S16 | Reproducibility | `manuscript/online_supplement/s7_reproducibility_records.tex`; `REPRODUCIBILITY.md`; v2 execution/audit records | Historical commands preserved and journal-program commands added. Compilation reruns no experiment. |

## Tables and figures

The local `tables/` and `figures/` copies of legacy TeX inputs are byte-for-byte
source copies except where the surrounding section changes the input path.
Algorithmic tables are generated by
`julia/scripts/analyze_algorithmic_compression_v2.jl`; compact financial tables
are generated by `julia/scripts/build_aor_manuscript_evidence_inputs.jl`.
Canonical record tables read committed CSV rows directly through `csvsimple`.
All table and figure counters receive an `S` prefix in `main.tex`.

## Exclusions

- `release/v0.1.1-arxiv/`, current preprint PDFs, and
  `experiments/randomized_library_v2/` are immutable inputs and were not edited.
- `experiments/algorithmic_compression_v1/results/` is not a source for this
  Online Resource.
- Raw CRSP/WRDS rows and row-level licensed transformations are excluded.
- Stale `manuscript/online_supplement/lean_correspondence.tex` and
  `validation_matrix.tex` are not copied; Section S15 is derived from the
  authoritative current ledger instead.
- Main-article tables and figures are not duplicated unless the resource needs
  a complete computational record or independent interpretation.

## Independent-reference rule

All numbered LaTeX references in the resource resolve within this source tree.
References to the journal article are descriptive (for example, “the journal
article's projection theorem”) rather than external `\ref` links, so separate
compilation cannot silently produce unresolved labels.
