# SSRN submission package

The current preprint is **Innovation-Safe Compression of Financial Strategy
Libraries: Semantics, Complexity, and Algorithms**, David Ramirez,
`v0.2.0-ssrn`, September 13, 2026. It is prepared for SSRN, has not been peer
reviewed, and has no assigned SSRN identifier or DOI.

## Upload files and fields

Upload `release/v0.2.0-ssrn/financial-strategy-library-compression-ssrn.pdf`.
It contains the research article followed by the complete Online Resource 1,
with separate numbering and PDF bookmarks. The separate article and supplement
PDFs are convenience copies, not additional SSRN submissions.

Paste `release/v0.2.0-ssrn/abstract_for_ssrn.txt` into the abstract field,
including its AI disclosure paragraph. Check the automatically extracted
title and author fields against `submission_metadata.json`.

| Field | Entry |
|---|---|
| Content type | Preprint |
| Date written / this revision | September 13, 2026 |
| Author / primary contact | David Ramirez |
| Affiliation | Independent Researcher, Orlando, FL, USA |
| Email | ramirezdavv@gmail.com |
| ORCID | 0009-0000-3128-5123 |
| Funding | The author received no funding for this work. |
| Competing interests | The author declares no financial or non-financial competing interests. |
| Manuscript reuse | CC BY 4.0, with the repository's third-party and licensed-data exclusions |
| DOI / SSRN number | Leave blank until assigned |

Suggested subject areas are financial economics, portfolio research, and
operations research. Choose the closest classifications available in the live
form; these are suggestions, not verified current SSRN eJournal names.
Keywords are in the metadata. Optional JEL codes are left unset.

Before submitting, review the final PDF, confirm your SSRN author profile is
current, and complete the live authorship and rights attestations. The author
confirmed no competing interests on September 13, 2026; identity, affiliation
and no funding were already recorded as author-confirmed. Account state and
portal attestations cannot be established from repository files. After SSRN
posts the paper, add its actual URL and assigned identifier to README and
citation metadata. Preserve the versioned package.

## Build and verify

Requirements: TeX Live with latexmk, pdfTeX, BibTeX and the packages used by
the journal sources; Poppler (`pdftotext`, `pdffonts`); Python 3.11 or newer;
and `pypdf` 6.10.0 (the recorded packaging version). Set `PYTHON_EXE` for a
different Python environment. No licensed data are required.

```sh
make ssrn-build PYTHON_EXE=python3
make ssrn-check PYTHON_EXE=python3
```

To rebuild the editable document archive, extract it into an empty directory
and run `python3 scripts/build_ssrn_release.py` there. This archive contains
document inputs, not the complete computational replication repository.

The SSRN drivers reuse the authoritative sources in `journal/aor/`. The
switch changes front matter and publication status, not mathematical or
empirical content. Readable benchmark tables retain every original row and
column; split tables repeat identifying columns. Their generator never
rewrites locked experiments. `SOURCE_MANIFEST.json` binds the exact document
sources. `PDF_AUDIT.json` records fonts, text, links, pages and hashes.
TeX timestamps can change PDF bytes on rebuild; each delivered package is
checked against its own `SHA256SUMS`.

See `QUALITY_REVIEW.md` for checks actually executed and their limitations,
and `REQUIREMENTS.md` for official SSRN sources. These controls improve
submission quality; SSRN makes its own posting decision.

The earlier `v0.1.1-arxiv` files remain immutable historical candidates.
Their name records an intended submission route, not an arXiv posting.
