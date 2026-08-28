# Isolated AoOR journal manuscript

This tree is the canonical journal-facing manuscript source. It does not
modify or compile from the
historical `manuscript/` tree or the frozen arXiv release.
The audited Springer Nature class and author--year bibliography style are
included locally so the editable source package is self-contained.
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
`journal/aor/manuscript/build/aor-journal-manuscript.pdf`.
`SOURCE_MIGRATION_MANIFEST.csv` records content provenance and `LABEL_MAP.csv`
records retained mathematical labels. The compliance report in
`journal/aor/requirements/COMPLIANCE_REPORT.md` records submission-time checks
and any remaining author or Editorial Manager confirmations.
