# SSRN submission package

The current preprint is **Innovation-Safe Compression of Financial Strategy
Libraries: Semantics, Complexity, and Algorithms**, David Ramirez,
**v0.3.0-ssrn**, September 18, 2026. It has not been submitted to SSRN or peer
reviewed. No SSRN identifier or DOI is assigned.

## Upload and metadata

Use the [combined manuscript and supplement](../release/v0.3.0-ssrn/financial-strategy-library-compression-ssrn.pdf).
It has separate article and supplement numbering and PDF bookmarks. Separate
PDFs are available in the same release directory for reading.

Paste [abstract_for_ssrn.txt](../release/v0.3.0-ssrn/abstract_for_ssrn.txt),
including its AI disclosure paragraph, into the submission abstract field.
Check extracted fields against [submission_metadata.json](../release/v0.3.0-ssrn/submission_metadata.json).

| Field | Entry |
|---|---|
| Content type | Preprint |
| Date written / this revision | September 18, 2026 |
| Author / primary contact | David Ramirez |
| Affiliation | Independent Researcher, Orlando, FL, USA |
| Email | ramirezdavv@gmail.com |
| ORCID | 0009-0000-3128-5123 |
| Funding | The author received no funding for this work. |
| Competing interests | The author declares no financial or non-financial competing interests. |
| Manuscript reuse | CC BY 4.0, with the repository's third-party and licensed-data exclusions |
| DOI / SSRN number | Leave blank until assigned |

Suggested subject areas are financial economics, portfolio research, and
operations research. Select the closest classifications in the live form;
these are suggestions, not verified current eJournal names. Keywords are
provided in the metadata. Optional JEL codes remain unset.

Review the final PDF, confirm the author profile, and complete the live
publication attestations before submitting. Posting this package on GitHub
does not submit it to SSRN. Add an SSRN URL and identifier only after assignment.

## Build, evidence, and review

```sh
make ssrn-build PYTHON_EXE=python3
make ssrn-check PYTHON_EXE=python3
```

These commands use the current self-contained sources in `ssrn/current/`.
Requirements and commands for rebuilding an extracted source archive and
recomputing scientific outputs are in the [reproduction guide](current/README.md).
The [versioned source archive](../release/v0.3.0-ssrn/financial-strategy-library-compression-ssrn-source.tar.gz)
contains the current document inputs and public evidence.

The [quality review](../release/v0.3.0-ssrn/QUALITY_REVIEW.md) states the checks
actually completed. [SOURCE_MANIFEST.json](../release/v0.3.0-ssrn/SOURCE_MANIFEST.json)
and [SHA256SUMS](../release/v0.3.0-ssrn/SHA256SUMS) bind the source and release.
The [official requirements](REQUIREMENTS.md) cover the upload fields, AI
statement, PDF properties, and posting criteria. SSRN makes its own posting decision.
