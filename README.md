# Innovation-Safe Compression of Financial Strategy Libraries

## Paper

- **Title:** *Innovation-Safe Compression of Financial Strategy Libraries:
  Semantics, Complexity, and Algorithms*
- **Author:** David Ramirez
- **ORCID:** [0009-0000-3128-5123](https://orcid.org/0009-0000-3128-5123)
- **Current preprint:** `v0.2.0-ssrn` (September 13, 2026), prepared for SSRN
- **Historical preprint candidate:** `v0.1.1-arxiv` (August 25, 2026; not an arXiv posting)
- **Repository:**
  [github.com/dramirez37/financial-strategy-library-compression](https://github.com/dramirez37/financial-strategy-library-compression)
- **Status:** preprint; not peer reviewed; no SSRN identifier or DOI assigned

Download the [complete SSRN upload PDF](release/v0.2.0-ssrn/financial-strategy-library-compression-ssrn.pdf),
the [article](release/v0.2.0-ssrn/financial-strategy-library-compression-preprint.pdf),
or the [supplement](release/v0.2.0-ssrn/financial-strategy-library-compression-supplement.pdf).
The [SSRN submission guide](ssrn/README.md) provides copy-ready metadata,
requirements, build commands and the quality review. This package uses the
latest research sources, including the complete named financial studies.

`make aor-release` creates the versioned Springer article, Online Resource 1,
editable-source archive, public registered benchmark archive, checksums, and
metadata under `release/v0.2.0-aor-submission/`. The immutable historical
[`v0.1.1-arxiv`](release/v0.1.1-arxiv/) PDFs and arXiv source bundle remain
available with their original provenance.

The paper studies exact compression of finite financial-strategy libraries
when a retained strategy may contribute both current operating value and
modules needed to generate future strategies. It separates frontier-only
compression from innovation-safe compression and studies exact, capacity-
constrained, penalized, and dynamic retention problems.

## What the repository contains

1. A Lean 4 formalization of the finite statements identified in the theorem
   ledger.
2. A Julia implementation of the model, exact finite algorithms, canonical
   benchmark, experiments, and artifact generators.
3. Exact rational fixtures shared between Julia and Lean, with deterministic
   drift checks.
4. A registered randomized finite-library study with fixed designs, seeds,
   amendment locks, complete outputs, and an independent result audit.
5. Two retrospective financial mechanism audits based on licensed CRSP/WRDS
   data, with redistributable aggregate outputs but no distributed source rows.
6. Isolated Springer-compatible LaTeX sources for the journal article and
   Online Resource 1, alongside the preserved preprint sources.

## Evidence hierarchy

| Evidence | What it supports | What it does not support |
|---|---|---|
| Mathematical proof | Human-readable derivations under the assumptions stated in the paper and appendices. | A claim of machine verification unless a corresponding Lean declaration is recorded. |
| Lean verification | Kernel checking of the encoded finite statement and assumptions listed in `THEOREM_LEDGER.md`. | Claims outside that encoding, empirical conclusions, or correctness of Julia experiments. |
| Exact rational computation | Exact evaluation, enumeration, fixtures, and counterexample searches for registered finite inputs. | A universal theorem without a separate proof. |
| Randomized synthetic evidence | Design-conditional behavior under the registered finite generator. | Population prevalence, causal evidence, or theorem proof. |
| Retrospective financial evidence | Mechanism diagnostics in the documented CRSP/WRDS samples. | Causal, prospective, forecasting, alpha, or deployable-performance claims. |

These categories are tracked separately in
[`THEOREM_LEDGER.md`](THEOREM_LEDGER.md) and the manuscript's
validation-status appendix.

## Quick start

The pinned versions are Lean 4.32.0 and Julia 1.12.6. Run commands from the
repository root. Verify the SSRN package with `make ssrn-check` using Python
with `pypdf` installed; rebuild it with `make ssrn-build`. For computational
validation, the broader journal gate does not rerun the
long final algorithmic benchmark, the frozen `N=1024` study, or a licensed
financial workflow:

```sh
make aor-check
```

Run the journal components independently as needed:

```sh
make aor-theory-check
make aor-algorithm-tests
make aor-benchmark-audit
make aor-manuscript
```

After the author declarations and release metadata are final and the worktree
is clean, create and verify the versioned candidate with `make aor-release`.
The historical preprint gates remain available as `make preprint-check`,
`make manuscript`, and `make arxiv-bundle`.

The registered randomized replay is intentionally separate because it is the
long-running (N=1024) workflow:

```sh
make randomized
```

Researchers with the required license run the financial workflow explicitly:

```sh
ALGOLIB_CRSP_ROOT=data/licensed/crsp make financial-licensed
```

The complete developer/release gate remains `make verify`. Detailed purposes,
runtime categories, data requirements, outputs, and underlying authoritative
commands are in [`REPRODUCIBILITY.md`](REPRODUCIBILITY.md).

## Licensed financial data

**The financial audits use licensed CRSP/WRDS data. Raw and row-level licensed
data are not distributed.**

Researchers with independent licensed access can supply the expected local
files under `data/licensed/`, set `ALGOLIB_CRSP_ROOT`, and run the preparation
and audit scripts. The scripts do not download licensed data or silently use a
synthetic substitute. See [`DATA_ACCESS.md`](DATA_ACCESS.md) for the input
contract, commands, and public outputs available without licensed access.

## Repository map

| Path | Contents |
|---|---|
| `formal/` | Lean source, project lockfiles, theorem audits, and generated exact fixtures. |
| `julia/` | Julia environments, package source, tests, registered runners, and artifact generators. |
| `shared/` | Exact fixture schema, JSON fixtures, and theorem-export contracts. |
| `data/` | Empty, ignored local-data template and licensed-source schema contract. |
| `experiments/configs/` | Immutable experiment configurations and registered parameters. |
| `experiments/randomized_library_v2/` | Randomized-study design locks, amendments, trial registry, and seed registry. |
| `experiments/results/` | Redistributable exact, synthetic, and aggregate result artifacts. |
| `experiments/financial_terminal_audit/` | Terminal financial-audit protocol, public records, and ignored local-data contract. |
| `experiments/financial_annual_walkforward_audit/` | Annual walk-forward financial-audit protocol, public records, and ignored local-data contract. |
| `experiments/financial_resource_optimization/` | Cross-audit resource-optimization protocol and public certificates. |
| `experiments/financial_strategy_library_panel_v1/` | Completed and audited first-generation financial panel, including its immutable design history and public aggregates. |
| `experiments/financial_strategy_library_panel_v2/` | Completed sealed panel with audited public aggregate results, exact-arm certificates, and origin-level paired contrasts. |
| `experiments/financial_strategy_library_panel_v2_economic_design_audit/` | Post-hoc falsification audit of the sealed v2 decision mechanism; v2 itself remains unchanged. |
| `experiments/financial_strategy_library_panel_v3/` | Immutable internal provenance for the **Point-in-Time Portfolio-Library Retention Study**: point-in-time liquid universes, nested compression arms, protected adoption, search/capacity diagnostics, and a sealed transparent null result. |
| `experiments/financial_strategy_library_panel_v4/` | Immutable internal provenance for the **Calibrated Closure-Option Mechanism Experiment**: aggregate-calibrated noise, positive/null/adverse regimes, an independently calibrated learner, and a complete hashed world ledger. |
| `experiments/algorithmic_compression_v2/` | Locked journal benchmark, committed final outputs, solver logs, and exact audit certificates. |
| `manuscript/` | Main-paper source, appendices, bibliography, generated figures/tables, and build script. |
| `manuscript/online_supplement/` | Standalone supplement source and build script. |
| `journal/aor/manuscript/` | Springer-compatible journal article and its local editable inputs. |
| `journal/aor/online_resource/` | Independently compiled Online Resource 1 and public-safe canonical inputs. |
| `release/v0.1.1-arxiv/` | Versioned PDFs, arXiv-ready TeX bundle, and SHA-256/commit metadata. |
| `ssrn/` | Current SSRN drivers, official requirements, submission guide and quality review. |
| `release/v0.2.0-ssrn/` | Complete SSRN upload, separate PDFs, editable source, submission metadata, and checksums. |
| `release/v0.2.0-aor-submission/` | Journal PDFs, source and public-benchmark archives, checksums, environment, citation, and Zenodo metadata. |
| `scripts/` | Public disclosure audit and complete verification orchestration. |

## Reproducibility

See [`REPRODUCIBILITY.md`](REPRODUCIBILITY.md) for environments, registered
commands, seeds, and validation gates, and
[`ARTIFACT_MANIFEST.md`](ARTIFACT_MANIFEST.md) for artifact lineage, hashes,
producers, and manuscript consumers. Run `make public-audit` to check the
release and licensed-data boundary.

License terms and third-party exclusions are in [`LICENSE`](LICENSE).
