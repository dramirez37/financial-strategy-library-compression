# Innovation-Safe Compression of Financial Strategy Libraries

**David Ramirez · Independent Researcher · [ORCID](https://orcid.org/0009-0000-3128-5123)**

Current preprint: **v0.3.1-ssrn**, September 18, 2026. Revised review package;
not submitted or peer reviewed. No SSRN identifier or DOI has been assigned.
The [substantive review](ssrn/current/READINESS_REVIEW.md) records the repairs,
financial-inference limitation, and unresolved repository-wide source-lock
failure. An unqualified SSRN-readiness claim is withheld.

## Read the paper

- [Complete manuscript and supplement](release/v0.3.1-ssrn/financial-strategy-library-compression-ssrn.pdf)
- [Research article](release/v0.3.1-ssrn/financial-strategy-library-compression-preprint.pdf)
- [Supporting proofs, methods, and reproduction](release/v0.3.1-ssrn/financial-strategy-library-compression-supplement.pdf)
- [Editable source and public evidence](release/v0.3.1-ssrn/financial-strategy-library-compression-ssrn-source.tar.gz)
- [Submission metadata and instructions](ssrn/README.md)

The paper asks when a portfolio research team can reduce its active strategy
library without losing the modeled operating choices or reusable inputs to
future research. It establishes a conditional preservation principle, gives
its exact weighted-cover representation under identity closure, and shows
how weaker deletion rules fail. The operating decision selects a catalog
entry, which may itself be a portfolio; the guarantee does not automatically
preserve diversification across several entries.

The evidence consists of a registered computational benchmark, a retrospective
point-in-time financial study, and a calibrated synthetic mechanism experiment.
The financial study treats its registered bootstrap rule as an adoption screen,
with no established finite-sample simultaneous coverage guarantee. It retains
its null common-equity contrasts and adverse ETF
replacement. A larger research menu does not establish a return premium.

## Reproduce the current paper

The [reproduction guide](ssrn/current/README.md) distinguishes document building,
public-record verification, and full scientific computation. Python 3.11+,
`pypdf`, LaTeX with `latexmk`, and Poppler are needed for the document commands:

```sh
make ssrn-check PYTHON_EXE=python3
make ssrn-build PYTHON_EXE=python3
```

The source archive also rebuilds independently after extraction:

```sh
python3 verify_evidence.py
python3 build.py --output ./release
python3 build.py --output ./release --check
```

The [release directory](release/v0.3.1-ssrn/) includes source and PDF hashes,
submission fields, the PDF audit, and the [quality review](release/v0.3.1-ssrn/QUALITY_REVIEW.md).
The [reproduction manifest](release/v0.3.1-ssrn/REPRODUCTION_MANIFEST.json)
binds the 136 selected scientific sources to commit
`bb58f33fd42f82f51b2866b44a666c3094f2932a`, using Julia 1.12.6 and Lean 4.32.0.
The [versioned package](https://github.com/dramirez37/financial-strategy-library-compression/tree/v0.3.1-ssrn/release/v0.3.1-ssrn)
is the fixed reference for this preprint.

| Material | Location |
|---|---|
| Current article and supplement sources | `ssrn/current/article/`, `ssrn/current/supplement/` |
| Public benchmark, financial aggregates, and synthetic ledger | `ssrn/current/evidence/` |
| Scientific source bindings and reproduction commands | `ssrn/current/REPRODUCTION_MANIFEST.json`, `ssrn/current/README.md` |
| Downloadable PDFs, source archive, and checksums | `release/v0.3.1-ssrn/` |

## Evidence and access

Human proofs, selected Lean results, finite exact checks, solver conclusions,
and experimental findings have distinct scopes. The supplement records those
boundaries. Public checks retain all 3,907 benchmark terminal outcomes and all
16,384 synthetic test worlds; they do not rerun the scientific computations.

The financial study uses licensed CRSP/WRDS inputs. Raw observations, return
paths, and security-level identifiers are excluded from the current package.
Independent financial replication requires separate licensed access under the
input contracts identified in the reproduction manifest. The distributed
aggregates support public table verification.

Original software is MIT-licensed and manuscript material is CC BY 4.0,
subject to the third-party and licensed-data exclusions in [LICENSE](LICENSE).
Permanent repository: https://github.com/dramirez37/financial-strategy-library-compression
