# Reproduction guide

Innovation-Safe Compression of Financial Strategy Libraries: Semantics, Complexity, and Algorithms. Prepared 18 September 2026, v0.3.1-ssrn. This is a preprint, not a submitted or peer-reviewed article.

Download the [fixed versioned package](https://github.com/dramirez37/financial-strategy-library-compression/tree/v0.3.1-ssrn/release/v0.3.1-ssrn), including the combined PDF, source archive, public evidence, and hashes.

The article proceeds from the financial retention problem to the model, preservation proofs, covering representation, algorithms and counterexamples, and computational and financial evidence. The supplement contains supporting proofs and methods. The source archive contains only the document inputs and public evidence supporting this paper.

## Rebuild the documents

Requirements: Python 3.11 or later with `pypdf`; a TeX distribution with `latexmk`, pdfTeX and BibTeX; and Poppler (`pdftotext`, `pdffonts`). The TeX distribution must include PGFPlots and scalable T1 fonts (the `cm-super` package on Debian/Ubuntu). Install Python requirements with `python3 -m pip install pypdf` if needed.

From the extracted archive:

```sh
python3 verify_evidence.py
python3 build_figures.py --check
python3 verify_review.py
python3 build.py --output ./release
python3 build.py --output ./release --check
```

The three figures use editable TikZ/PGFPlots sources. `build_figures.py` derives their CSV inputs from the sealed public records and independently recomputes every displayed synthetic interval from the complete world ledger; run it without `--check` to regenerate inputs. The schematic is an explicitly specified exact fixture, not an empirical observation. No external plotting package or new experiment is needed.

The builder produces the article, supplement, and combined PDF, plus submission metadata, source archive and hashes. Article and supplement retain separate destinations and page numbering in the combined PDF. `SOURCE_MANIFEST.json` hashes source paths relative to this directory. `SHA256SUMS` hashes delivered release files. The builder does not contact or submit to SSRN.

## Check public results

`python3 verify_evidence.py` checks every bundled evidence file against `REPRODUCTION_MANIFEST.json`, verifies the benchmark's complete outcome counts and exact-agreement denominator, recomputes synthetic means and adoption rates from all 16,384 worlds, and checks financial input/result seals and summary counts. It does not rerun Julia, solve new instances, certify optimality, or reproduce licensed return paths.

The `evidence/benchmark/` directory contains all 3,907 terminal run rows, the 173-instance registry, exact-agreement and method summaries. `evidence/financial/` contains public predecision, proposal and evaluation manifests, result seals and registries. `evidence/mechanism/` contains the public calibration, configuration, all regime/seed registrations, complete world ledger and summary. Evidence copies retain their original bytes. The two benchmark registry extracts select all registered final-study rows without changing their fields. The manifest records original paths, source hashes, the selection rule, and distributed-file hashes.

## Recompute scientific outputs

Full computation uses the repository at commit `bb58f33fd42f82f51b2866b44a666c3094f2932a`, with Julia 1.12.6 and Lean 4.32.0. The document archive is not a complete Julia/Lean environment. `REPRODUCTION_MANIFEST.json` identifies the selected scientific sources and pinned environments. Obtain that exact repository revision, then initialize the Julia project and test project from their manifests. Run the following commands from its root, with `julia` resolving to 1.12.6:

```sh
julia --startup-file=no --project=julia -e 'using Pkg; Pkg.instantiate()'
julia --startup-file=no --project=julia/test -e 'using Pkg; Pkg.instantiate()'
julia --startup-file=no --project=julia/test julia/test/run_aor_algorithm_tests.jl
julia --startup-file=no --project=julia julia/scripts/verify_safe_compression_complexity_reductions.jl --check
julia --startup-file=no --project=julia julia/scripts/export_safe_deletion_gap_family.jl --check
julia --startup-file=no --project=julia julia/scripts/export_tagged_cover_theorem_fixture.jl --check
julia --threads=8 --startup-file=no --project=julia julia/scripts/check_algorithmic_compression_final_v2.jl
julia --threads=8 --startup-file=no --project=julia julia/scripts/audit_financial_strategy_library_panel_v4.jl --check
```

The benchmark command checks saved results and certificates. The synthetic command recomputes calibration/test calculations using the public calibration, then compares the complete world ledger and summaries with the sealed outputs. It does not recalibrate from market-return paths.

From `formal/`, initialize the pinned Lake dependencies and build the relevant modules:

```sh
lake exe cache get
lake build StrategyInnovation.Audit.RawToCompressed StrategyInnovation.Audit.TaggedSafeCompression StrategyInnovation.Audit.TaggedCoverPreprocessing StrategyInnovation.Audit.UnifiedSafeDeletion StrategyInnovation.Audit.NormalizedPruningLoss StrategyInnovation.Audit.JournalAlgorithms
```

The supplement states the exact boundary between universal Lean results, human proofs, and finite arithmetic fixtures. These commands do not extend that boundary.

## Licensed financial replication

Independent CRSP/WRDS access is needed for return-path computation. The manifest identifies the current data contract, predecision calculation specification, proposal execution specification, evaluation specification, Julia implementations and their hashes. Follow those input contracts and the registered formation/compression/proposal/evaluation windows. No return path, selected strategy identity, or security-level data is in this archive. The public manifests support aggregate verification; they do not substitute for licensed inputs.

## Rights and responsibility

`LICENSE` retains the author's software and manuscript terms and third-party/data exclusions. Author details and declarations are in `article/author_metadata.tex`. The PDF metadata and text identify this as a preprint. Any external submission requires the author's review of this draft and the destination's current requirements.
