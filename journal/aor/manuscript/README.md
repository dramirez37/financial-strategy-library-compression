# Isolated AoOR journal manuscript

This tree is the DRAFT journal-facing manuscript source. The front matter,
Introduction, literature section, model, covering/complexity section, and
algorithm section contain journal-draft prose; Sections 6--9 remain scaffolded.
The tree does not modify or compile from the
historical `manuscript/` tree or the frozen arXiv release.
The only shared LaTeX dependency is the repository's audited Springer working
template in `journal/aor/template/`; a submission bundle must later copy the
class and bibliography style into the upload package.
The `sn-mathphys-ay` option is a local implementation choice that supplies the
verified author--year behavior; the official audit does not claim that AoOR
mandates that exact option or `.bst` filename.

The pre-existing files `04_tagged_cover_equivalence.tex`,
`05_identity_closure_complexity.tex`, `06_safe_deletion_gap_family.tex`,
`07_exact_requirement_mask_algorithms.tex`,
`08_weighted_greedy_construction.tex`, and
`09_certified_deletion_suite.tex` remain unchanged migration sources. The new
`main.tex` does not input them directly, so the scaffold has one section and
one numbering location for every future result.

Build from the repository root with:

```sh
./journal/aor/manuscript/build.sh
```

The PDF is written to
`journal/aor/manuscript/build/aor-journal-scaffold.pdf`. All visible DRAFT
markers and author-confirmation placeholders are intentional stop conditions
for submission. `SOURCE_MIGRATION_MANIFEST.csv` records content provenance and
`LABEL_MAP.csv` reserves the retained mathematical labels.
