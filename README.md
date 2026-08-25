# Financial Strategy Library Compression under Partial Information

## Paper

- **Full title:** *Financial Strategy Library Compression under Partial
  Information: Resource Constraints and Generative Value*
- **Author:** David Ramirez
- **ORCID:** [0009-0000-3128-5123](https://orcid.org/0009-0000-3128-5123)
- **Release candidate:** `v0.1.1-arxiv`
- **Preprint date:** August 25, 2026
- **Repository:**
  [github.com/dramirez37/financial-strategy-library-compression](https://github.com/dramirez37/financial-strategy-library-compression)
- **Preprint record:** URL forthcoming

The versioned release candidate includes the compiled
[`main paper`](release/v0.1.1-arxiv/financial-strategy-library-compression-preprint.pdf)
and [`Online Supplement`](release/v0.1.1-arxiv/financial-strategy-library-compression-online-supplement.pdf).

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
6. LaTeX source for the paper and standalone online supplement.

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
repository root. Start with the nonmutating public-release check; it does not
rerun the registered (N=1024) study:

```sh
make preprint-check
```

Run the component workflows as needed:

```sh
make formal
make canonical
make manuscript
```

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
| `manuscript/` | Main-paper source, appendices, bibliography, generated figures/tables, and build script. |
| `manuscript/online_supplement/` | Standalone supplement source and build script. |
| `release/v0.1.1-arxiv/` | Versioned PDFs, arXiv-ready TeX bundle, and SHA-256/commit metadata. |
| `scripts/` | Public disclosure audit and complete verification orchestration. |

## Reproducibility

See [`REPRODUCIBILITY.md`](REPRODUCIBILITY.md) for environments, registered
commands, seeds, and validation gates, and
[`ARTIFACT_MANIFEST.md`](ARTIFACT_MANIFEST.md) for artifact lineage, hashes,
producers, and manuscript consumers. Run `make public-audit` to check the
release and licensed-data boundary.

License terms and third-party exclusions are in [`LICENSE`](LICENSE).
