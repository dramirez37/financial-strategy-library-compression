# Public Release Manifest

## Scope

This file defines the reader-facing release boundary for *Financial Strategy
Library Compression under Partial Information: Resource Constraints and
Generative Value*. The release is a fresh, squashed snapshot; it does not
publish the private development history.

The public snapshot contains 664 files: 408 PUBLIC CORE and 256 PUBLIC
GENERATED. It contains no tracked licensed input, private file, internal
development record, or row-level CRSP/WRDS observation.

## Evidence boundary

| Evidence | Public source | Interpretation |
|---|---|---|
| Mathematical and Lean results | `manuscript/`, `formal/`, `THEOREM_LEDGER.md`, `PREPRINT_LEAN_AUDIT.md`, `PREPRINT_THEOREM_AUDIT.md` | Applies only to the stated finite results and encoded assumptions. |
| Exact computational checks | `julia/`, `shared/exact_fixtures/`, exact outputs under `experiments/results/` | Certifies the registered finite instances; it is not a universal proof. |
| Randomized synthetic evidence | `experiments/randomized_library_v2/`, registered designs, seeds, and reports | Design-conditional evidence, not population prevalence or theorem proof. |
| Retrospective financial evidence | the two financial-audit directories and public aggregates | Uses licensed CRSP/WRDS inputs; it is neither causal evidence nor an alpha claim. |

## PUBLIC CORE

These are hand-maintained sources, specifications, proof files, configurations,
locks, schemas, and reproduction commands.

### Top-level directories

| Path | Contents |
|---|---|
| `.github/` | Commit-pinned CI workflow. |
| `data/` | Empty local licensed-data template and schema contract. |
| `experiments/` | Configurations, registered locks and seeds, synthetic generators, financial protocols, and public result locations. |
| `formal/` | Lean source, project files, theorem audits, and generated-fixture consumer. |
| `julia/` | Julia package, authoritative scripts, tests, and environment locks. |
| `manuscript/` | Main-paper and Online Supplement source and build scripts. |
| `release/` | Versioned release metadata and compiled documents. |
| `scripts/` | Public audit and reproducibility orchestration. |
| `shared/` | Exact schemas, cross-language fixtures, and theorem-export contracts. |

### Top-level files

Every top-level file in the public snapshot is listed below. Scientific
specifications remain because they define current assumptions, registered
inputs, or reported computations; internal planning and revision records do
not.

```text
.gitattributes
.gitignore
APPROXIMATE_COMPRESSION_REPORT.md
ARTIFACT_MANIFEST.md
ASSUMPTIONS.md
BRIDGE_ELASTICITY_SPEC.md
CAPACITY_ELASTICITY_SPEC.md
CAPACITY_VALUE_SPEC.md
CHANNEL_ELASTICITY_SPEC.md
CITATION.cff
COMPLEXITY_AUDIT.md
COUNTEREXAMPLES.md
DATA_ACCESS.md
EMPIRICAL_INFORMATION_SET_AUDIT.md
FINANCIAL_AUDIT_TAXONOMY.md
FINANCIAL_RESOURCE_OPTIMIZATION.md
FORMALIZATION_GAPS.md
FORMALIZATION_MAP.md
INNOVATION_DURATION_SPEC.md
JOINT_DESCENDANT_BOUND_SPEC.md
LICENSE
LOCAL_VS_GLOBAL_COMPRESSION_SPEC.md
MODEL_SPEC.md
Makefile
NOTATION.md
OPTIMIZATION_PROBLEM_SPEC.md
OPTIMIZATION_THEOREM_REVISIONS.md
PENALIZED_ENVELOPE_SPEC.md
PREPRINT_CLAIM_LEDGER.md
PREPRINT_LEAN_AUDIT.md
PREPRINT_THEOREM_AUDIT.md
PRIMITIVE_SUBSTITUTION_SPEC.md
PUBLIC_RELEASE_MANIFEST.md
RANDOMIZED_DESIGN_V2.md
RANDOMIZED_DESIGN_V2_AMENDMENT_1.md
RANDOMIZED_DESIGN_V2_AMENDMENT_2.md
RANDOMIZED_LIBRARY_OPTIMIZATION_EXTENSION_V1.md
RANDOMIZED_LIBRARY_REPORT.md
RANDOMIZED_LIBRARY_REPORT_V2.md
RAW_TO_COMPRESSED_SPEC.md
README.md
REALIZABLE_RECTANGLE_CONSTRUCTION.md
REPLACEMENT_OPTIMIZATION_SPEC.md
REPRODUCIBILITY.md
RESOURCE_MODEL_SPEC.md
SAFE_COMPRESSION_COMPLEXITY_APPENDIX_PROOF.md
SAFE_COMPRESSION_PROOF_OUTLINE.md
SAFE_COMPRESSION_THEOREM_SPEC.md
THEOREM_LEDGER.md
UNIFIED_CANONICAL_BENCHMARK_SPEC.md
UNIFIED_TIMING_SPEC.md
```

## PUBLIC GENERATED

| Path | Contents |
|---|---|
| `experiments/results/**` | Exact and synthetic outputs, registered randomized outputs, public financial aggregates, hashes, and certificates. |
| `manuscript/figures/**` | Generated SVG and TikZ figure sources. |
| `manuscript/tables/**` | Generated manuscript table source. |
| `shared/exact_fixtures/*.json` | Exact Julia–Lean fixtures. |
| `formal/StrategyInnovation/Fixtures/Generated.lean` | Generated Lean fixture source. |
| `release/v0.1.0-preprint/*.pdf` | Compiled 44-page paper and 41-page Online Supplement. |

Generated artifacts are retained when they are displayed, independently
checked, or required for artifact-drift verification.

## LICENSED / DO NOT DISTRIBUTE

The following categories must remain local:

- raw CRSP files and WRDS extracts;
- security-date or row-level licensed observations;
- cached vendor queries and downloads;
- completed provenance and extraction-audit records containing licensed query
  details;
- derivatives from which licensed rows could be reconstructed.

Researchers with their own license provide inputs below
`data/licensed/crsp/` as described in `DATA_ACCESS.md`. The preparation
scripts download nothing and never substitute synthetic data.

Only the following empty contracts are public in licensed-input locations:

```text
data/README.md
data/licensed/.gitkeep
experiments/financial_terminal_audit/data/README.md
experiments/financial_terminal_audit/data/provenance.template.toml
experiments/financial_annual_walkforward_audit/data/README.md
experiments/financial_annual_walkforward_audit/data/provenance.template.toml
```

## DEVELOPMENT-ONLY / REMOVE FROM RELEASE

The private source tree retains 47 export-ignored paths. They comprise:

- agent instructions, decision logs, status journals, and research planning;
- draft baselines, revision maps, triage notes, and referee-style reports;
- superseded citation, novelty, proof, figure, table, and repository audits;
- redundant directory-policy READMEs;
- the deprecated `scripts/full_check.sh` compatibility alias.

The exact denylist is machine-readable in `.gitattributes` and enforced by
`scripts/audit_public_repository.sh`. A valid private source tree contains
all 47 paths; a valid public export contains none. Partial exports and
untracked copies are rejected.

Local runtimes, caches, notebooks, manuscript build products, temporary PDFs,
editor state, and the private `.git/` history are ignored and must not be
copied into a release.

## Reproduction and packaging

From a clean public checkout:

```sh
make public-audit
make verify
```

`make verify` checks formal, exact, synthetic, aggregate, generated-artifact,
and manuscript stages. Without local licensed inputs it skips only the two raw
financial replays and still validates the redistributable aggregates.

Release packaging uses `git archive` so `.gitattributes` omits all internal
records and expands the exact source commit in
`release/v0.1.0-preprint/RELEASE_METADATA.md`. The permanent repository is
<https://github.com/dramirez37/financial-strategy-library-compression>.
