# SSRN preprint quality review

Review date: September 13, 2026. Package: `v0.2.0-ssrn`.

## Submission preparation

The latest research article and complete supporting resource are prepared as
one 163-page SSRN upload (37-page article, 126-page supplement), approximately
2 MB. Separate component PDFs are supplied for convenient reading. All three
files are bound by `release/v0.2.0-ssrn/SHA256SUMS`.

The title agrees with the current manuscript and citation metadata. Author,
affiliation, email, ORCID, revision date, preprint status and AI disclosure
are present. The author confirmed no competing interests on September 13,
2026. Funding retains the existing author-confirmed statement. No arXiv
posting, SSRN identifier, DOI, acceptance or peer review is implied.

## Corrections made during this review

- Repaired clipped supplementary benchmark tables. The readable tables retain
  all 502 source rows across five tables, and every original column. Split
  tables repeat identifying columns; original analysis tables and locked
  results are unchanged.
- Reflowed long canonical records and the theorem/evidence table, repaired
  landscape page headers, and removed four unnecessary page breaks.
- Resolved bookmark-level warnings and verified that merging the PDFs keeps
  every internal and external link pointed at its original target. The viewer
  labels run from 1 to 37, then S1 to S126.
- Replaced incomplete declarations and provisional data/code availability
  wording with the confirmed disclosure, actual repository and existing
  license terms. Financial-source restrictions remain explicit.
- Made the historical benchmark audit work with the later expanded project
  environment, while checking the historical execution bytes against the
  immutable lock and rejecting changes to historical dependency pins.
- Included bibliography databases and styles explicitly in the source
  archive: pdfTeX recorder files alone do not enumerate BibTeX dependencies.
- Kept journal-specific citation metadata under `journal/aor/release/` so
  current SSRN citation metadata do not break the separate journal packager.

## Checks executed

| Check | Outcome |
|---|---|
| `make aor-theory-check` | PASS: exact theorem fixtures, Lean build, manuscript lint and axiom audit; 784 declarations use only the recorded standard axioms or fewer. |
| `make aor-algorithm-tests` | PASS: enumeration, dynamic programming, greedy, deletion, preprocessing, MIP and exactness-audit tests. |
| `make aor-benchmark-audit` | PASS: 3,907 terminal records, 3,526 accepted libraries, 31 exact agreements, 381 unsuccessful records. Regenerated audit artifacts match the frozen bytes; no outcomes or timings rerun. |
| Historical-environment regression tests | PASS: eight checks, including rejected changed pins, compatibility, package identity and removed dependencies. |
| `make aor-point-in-time-study-audit` | PASS: current published evidence inputs match the committed public records. |
| `make aor-closure-option-experiment-audit` | PASS: design lock and all 16,384 synthetic world rows recomputed and verified. |
| `make aor-public-boundary` | PASS: tracked public repository, registered outputs, licensed-row exclusions and public financial manifests. |
| `make aor-manuscript` | PASS: both journal documents and recorder/source-completeness checks. |
| `make ssrn-build` and `make ssrn-check` | PASS: source hashes, metadata, fonts, text, PDF links and frozen package checksums. |
| Final LaTeX logs | Zero warnings, unresolved citations/references, missing-glyph diagnostics or overflowing boxes in either SSRN component. The article bibliography contains 31 references. |
| PDF structure | All fonts embedded; no Type 3 fonts, encryption or image-only pages. All 211 internal links retained; destination pages and external link targets match the component PDFs. |
| Visual review | Rendered-page overview of the complete documents, followed by detailed inspection of title, financial text, repaired tables and reproducibility pages. No clipped table columns remain. Rotation-aware text bounds show no words within 8 points of a page edge. |
| Editable source replay | Clean extracted source builds both documents; extracted PDF text matches the delivered article, supplement and complete upload. |
| Repository hygiene | `git diff --check`; only this task's files staged. Pre-existing untracked research remains outside the change. |

## Limits and upload-day actions

This is a technical, presentation and evidence-consistency review, not peer
review, a plagiarism certification, or independent re-proof of every theorem.
The original evidence distinctions remain: universal human proofs, encoded
Lean statements, exact finite computations, solver certificates, synthetic
results and retrospective financial evidence support different claims.
The paper retains null/adverse outcomes and does not claim alpha, forecasting,
causal effects or deployable performance. Licensed-data analysis was not rerun.

The SSRN author account, current profile, rights attestations and final upload
are completed by the author in the live portal. SSRN's own editorial and
research-integrity screening determines posting. Use the copy-ready abstract
with its AI disclosure, and enter an SSRN number or DOI only after assignment.
