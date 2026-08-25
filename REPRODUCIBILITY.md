# Reproducibility Protocol

## How to use this document

This file is the complete outside-researcher reproduction record for the
preprint. The short workflows below reproduce the public headline artifacts;
the registered-experiment sections that follow preserve the exact
configuration, seed, arithmetic, command, output, and validation record for
every maintained experiment.

All commands are run from the repository root unless a command explicitly
changes directory. Use a clean checkout, do not execute project source from an
operating-system temporary directory, and do not substitute configuration
files or seeds when reproducing a registered result.

The evidence classes remain separate:

- a human mathematical proof establishes only its stated theorem and
  assumptions;
- a Lean build checks only the encoded declaration and dependencies recorded
  in `THEOREM_LEDGER.md`;
- an exact Julia computation checks its registered finite inputs but is not a
  universal proof;
- a randomized result is conditional on its registered synthetic generator;
  and
- a retrospective financial audit is empirical mechanism evidence, not a
  causal, prospective, forecasting, or alpha result.

See `README.md` for the repository overview, `ARTIFACT_MANIFEST.md` for
artifact lineage, and `DATA_ACCESS.md` for the licensed-data input contract.

## Environment summary

| Component | Pinned or observed environment |
|---|---|
| Julia | 1.12.6; root and test `Project.toml`/`Manifest.toml` pairs are committed |
| Lean | 4.32.0 through `formal/lean-toolchain` |
| Lake | 5.0.0-src+8c9756b |
| mathlib | commit `81a5d257c8e410db227a6665ed08f64fea08e997` through `formal/lake-manifest.json` |
| Documents | latexmk 4.83, pdfTeX from TeX Live 2024, and BibTeX 0.99d on the audited host |

Use `julia` on `PATH` or set `JULIA_EXE` to an absolute Julia 1.12.6
executable for the complete gate. The ignored `.local_runtime/` used on the
audited workstation is not part of the public repository.

## Core public workflows

The public command surface is intentionally small.  Make contains orchestration
only; every target delegates to the existing registered Julia, Lean, shell, or
LaTeX entry point without restating a seed, lock, configuration, estimand, or
numerical rule.

| Command | Purpose | Expected runtime category | Data requirements | Expected key outputs |
|---|---|---|---|---|
| `make preprint-check` | Check the pinned toolchain, required public files, disclosure boundary, source references, exact/canonical drift, frozen randomized locks and committed-result reconciliation, public financial aggregate certificates, and live manuscript figures/tables. It never runs the registered (N=1024) replay. | Short to medium; normally minutes, host dependent. | Public clone only; no licensed rows. | Pass/fail report only; tracked and untracked worktree state must be unchanged. |
| `make canonical` | Run the authoritative deterministic canonical benchmark, then run the manuscript numerical-artifact checker. | Short; normally minutes or less. | Public clone only; no random seed or licensed data. | `unified_canonical_*` CSV/JSON records and the registered canonical manuscript presentation artifacts. |
| `make randomized` | Verify all three frozen design/amendment locks, run the registered (N=1024) study once, then run the independent result-reader audit. | Long; the registered planning allowance is 900 seconds, but runtime is host dependent. | Public synthetic registry, locks, configuration, and committed master/derived seeds only. | `RANDOMIZED_LIBRARY_REPORT_V2.md`, registered randomized CSV/JSON summaries and figures, plus an independent reconciliation report. |
| `make formal` | Run a clean Lean build, prohibited-marker scan, comprehensive axiom audit with the accepted standard-axiom whitelist, and manuscript linter. | Medium to long; clean-build time is host and cache dependent. | Public Lean sources and pinned Lake/mathlib environment; no empirical data. | Local `formal/.lake/` build products and audit output; no tracked source change. |
| `make manuscript` | Compile the main preprint and standalone Online Supplement with their existing warning gates. | Short to medium; normally minutes. | Public LaTeX, bibliography, figure, and table sources; no Julia or licensed data. | `manuscript/build/main.pdf` and `manuscript/build/online_supplement/main.pdf`. |
| `make arxiv-bundle` | Assemble the two top-level TeX documents and only their required public inputs into the versioned arXiv source directory. | Short; normally seconds after `make manuscript`. | Public LaTeX sources plus the generated `main.bbl`; no Julia, Lean, or licensed data. | `release/v0.1.1-arxiv/arxiv-source/` and its uploadable `.tar.gz` archive. |
| `make financial-licensed` | Validate independently supplied licensed inputs, prepare both ignored panels, run the terminal and annual walk-forward audits, and run/check the cross-audit resource optimization. | Long; data volume, storage, and host dependent. | Independent CRSP/WRDS license, the four source files in `DATA_ACCESS.md`, and `ALGOLIB_CRSP_ROOT`. | Six ignored local panel/provenance/audit files; registered public aggregate CSV/JSON/report/figure artifacts; cross-audit exact certificates. |

`make help` prints this component list. `JULIA_EXE` may point to an absolute
Julia 1.12.6 executable; otherwise Make prefers the ignored repository-local
runtime when present and falls back to `julia` on `PATH`.

### Preprint release check

```sh
make preprint-check
```

This is the default public-clone confidence check.  It uses only nonmutating
`--check` producers or read-only verifiers, records the initial Git state, and
fails if any producer changes it.  The randomized portion validates the three
frozen locks and independently reconciles the committed results without
running the study. It checks both active manuscript source graphs but
does not compile them, run Lean proofs, replay licensed rows, or execute the
registered (N=1024) randomized study.  Use the component targets below for
those workflows.

### Public disclosure audit

```sh
make public-audit
```

This shell-only gate rejects tracked licensed data, credential-like material,
machine-local paths, caches, binaries, and other paths outside the public
release policy.

### Lean build and declaration audit

```sh
make formal
```

The target delegates to `scripts/formal_check.sh`, which is also used by the
formal stages of `scripts/verify.sh`. It performs the clean build, release
linter, comprehensive `#print axioms` record, and accepted-axiom gate. A
successful run establishes only the Lean statements described in the theorem
ledger.

### Canonical benchmark

```sh
make canonical
```

The authoritative canonical commands from Online Supplement S7 are:

```sh
julia --project=julia \
  julia/scripts/solve_unified_canonical_benchmark.jl
julia --project=julia \
  julia/scripts/solve_unified_canonical_benchmark.jl --check
```

The producer is deterministic and uses no random seed. The second command
recomputes and checks the registered artifacts without accepting drift.

### Manuscript numerical artifacts

```sh
julia --project=julia \
  julia/scripts/generate_manuscript_numerical_artifacts.jl
julia --project=julia \
  julia/scripts/generate_manuscript_numerical_artifacts.jl --check
```

The first command validates the committed numerical sources before rendering
the manuscript presentation layer. The second is the nonmutating artifact
checker required by the supplement and release gate.

### Registered randomized study v2

```sh
make randomized
```

The registered maximum is `N=1024`; the master seed is
`6075990691714899803`. The design and amendment checks, registered replay, and
independent result-reader audit are:

```sh
julia --project=julia \
  julia/scripts/lock_randomized_library_design_v2.jl --check
julia --project=julia \
  julia/scripts/lock_randomized_library_stability_amendment.jl --check
julia --project=julia \
  julia/scripts/lock_randomized_library_execution_amendment.jl --check
julia --project=julia \
  julia/scripts/run_randomized_library_stress_v2.jl
julia --project=julia \
  julia/scripts/run_randomized_library_stress_v2.jl --check
julia --project=julia \
  julia/scripts/audit_randomized_library_v2_results.jl
```

Do not regenerate or replace the committed trial registry, design locks,
amendments, seed registry, or configuration when reproducing the registered
study. The long-form record below identifies every lock hash and output.

### Paper and online supplement

```sh
make manuscript
```

These scripts require latexmk, pdfTeX, BibTeX, and ripgrep. They compile
committed sources; they do not run Julia or regenerate experiment outputs.
The versioned copies distributed with this release are under
`release/v0.1.1-arxiv/`; their SHA-256 values and archive-expanded source
commit are recorded in `RELEASE_METADATA.md` in that directory.

### arXiv source bundle

```sh
make manuscript
make arxiv-bundle
```

The bundle target copies, but does not reinterpret, the canonical manuscript
sources and generated presentation artifacts. It creates `paper.tex` and
`supplement.tex` at the bundle root, rewrites only the supplement's relative
input paths, includes the matching bibliography and `paper.bbl`, and excludes
the repository, Julia and Lean projects, experiment runners, licensed-data
contracts, logs, and auxiliary build files. Compile the two top-level files
from the bundle root with PDFLaTeX, selecting `paper.tex` first and
`supplement.tex` second when submitting to arXiv.

### Complete public gate

```sh
make verify
```

This is the canonical end-to-end gate. It performs the public audit, clean Lean
build and axiom audit, Julia package tests, registered artifact checks, the
complete v2 randomized replay, generated figure/table checks, and manuscript
compilation. In a public checkout without licensed financial inputs, only the
two raw-row financial replays are skipped; public aggregate hashes and
certificates remain mandatory.

## Licensed financial replays

```sh
ALGOLIB_CRSP_ROOT=data/licensed/crsp make financial-licensed
```

The financial preparation scripts never download data. Researchers with their
own CRSP/WRDS license supply the ignored paths documented in `DATA_ACCESS.md`
and may set `ALGOLIB_CRSP_ROOT=data/licensed/crsp`. Missing sources fail with a
clear licensed-data message and are never replaced by synthetic observations.
Without those inputs, all exact, formal, synthetic, aggregate-financial, and
document artifacts remain inspectable, and `make verify` continues after
reporting the two licensed replays as skipped.

The target fails before invoking Julia when `ALGOLIB_CRSP_ROOT` is unset or
does not name a local directory.  The authoritative preparation scripts then
validate file presence, column schemas, registered identities, and the frozen
universe; no schema logic is duplicated in Make or the shell wrapper.

## Detailed evidence status

Buildable Lean, Julia, LaTeX, and CI infrastructure exists. Research
falsification experiments use exact arbitrary-precision rationals,
deterministic enumeration or a stable RNG, and generated Lean fixtures.
Supporting manuscript results F2--F4, F8, S5, and C2, the R0 raw
admission/local-update foundation, UDI, and primary Theorems T1--T7 are Lean
verified. T2 includes the raw frontier--closure characterization and exact
assumption-boundary counterexamples. T3 includes unified single/rechecked
deletion, pruning certificates, value/action preservation, and exact stale-
certificate boundaries. T4 includes the exact raw survival/admission bridge
loss, cap sharpness, full net-opportunity destruction, unit normalization,
scaling boundary, and operation adjustment. T5 adds the unified raw
passive/full insertion decomposition, silence consequences, operational
antitonicity, an explicit project-dominance premium theorem, and the exact raw
bridge witness. T6 derives a cost-adjusted retained-carrier lower bound from
raw generation and admission under explicit conditional independence, exposes
the unified operating/passive timing adjustment, supplies a finite occupation
form and sign/comparative statics, and has a one-belief exact-rational Lean and
Julia fixture. Supporting CS1 adds finite sign-definite frontier, cost,
admission, survival, delay, closure, and action-region comparative statics
under explicit primitive orders. Its exact elapsed-time identity shows that
nonnegative operation and continuation alone do not imply delay antitonicity
when operation continues during research; the verified theorem uses the
additional no-waiting-gain inequality and records an exact rational
counterexample to the weaker claim. Supporting S6 specializes finite
occupation to exact rational matrix powers and proves discount--survival
complementarity by a factorized finite cross difference. The inverse resolvent
remains a Julia-validated interpretation; no derivative is attributed to
Lean. T7 uses relative Bellman-action saturation; an exact project-switching
counterexample proves that primitive frontier independence alone does not
imply the optimized closure cross-difference sign. Its registered Julia
experiment preserves the original 2,430-row boundary grid and adds five exact
canonical fixtures plus a 3,456-row realizability-audited response surface.
Deterministic synthetic coverage figures
and their complete data tables exist. A limited 25-ETF CRSP mechanism
illustration also exists locally and has aggregate tracked outputs, but its
row-level input is ignored. Aggregate artifacts are publishable under D-0041;
licensed reviewers reproduce the raw-data stage with their own CRSP/WRDS
access.

Current pins and manifests:

- Lean `leanprover/lean4:v4.32.0` in `formal/lean-toolchain`;
- Lean commit `8c9756b28d64dab099da31a4c09229a9e6a2ef35`;
- Lake `5.0.0-src+8c9756b`;
- stable mathlib tag `v4.32.0`, pinned by exact commit
  `81a5d257c8e410db227a6665ed08f64fea08e997`;
- complete transitive Lake lockfile in `formal/lake-manifest.json`;
- Julia 1.12.6 in `julia/.julia-version`;
- Julia 1.12.6-generated root and test project/manifest pairs;
- official Julia 1.12.6 Apple Silicon archive checksum
  `277d82fbd2eda99d0963b3e41f3dc979d7486f181399f8430fb637318ccd6a31`,
  installed locally under ignored `.local_runtime/julia-1.12.6`;
- `StableRNGs` 1.0.4 in the runtime manifest and Aqua 0.8.16 in the separate
  test manifest, with all transitive versions recorded;
- observed manuscript path: latexmk 4.83, pdfTeX from TeX Live 2024, and
  BibTeX 0.99d; this host distribution is recorded but not container-pinned.

## Environment policy

Future releases must retain or refine:

- Julia version and `Project.toml`/`Manifest.toml`;
- Lean version through `lean-toolchain`;
- mathlib and other Lean dependencies through the Lake manifest;
- external solver versions, if any;
- document toolchain versions needed for the manuscript;
- operating-system-sensitive requirements.

Python is not part of the planned environment. Any exception requires a prior
decision record identifying the unavailable Julia capability.

## Reproduction levels

| Level | Purpose | Required checks |
|---|---|---|
| governance | ledgers are complete and internally consistent | required files, field scans, link/path checks, clean diff |
| formal | rebuild all encoded theorems | clean Lean build, placeholder scan, `#print axioms` audit |
| software | validate Julia package behavior | unit, property, regression, formatting, and exact-oracle tests |
| numerical | reproduce reported figures and tables | fixed configs, seeds, raw outputs, tolerances, checksums |
| manuscript | reproduce paper artifacts | clean document build and reference/figure reconciliation |
| release | reproduce the complete artifact | all prior levels in a clean environment |

## Experiment identity

Every experiment must have:

- a stable experiment ID;
- a committed configuration;
- input-data provenance and checksum;
- Julia and dependency versions;
- random seed or explicit proof of determinism;
- arithmetic mode and solver tolerances;
- command used;
- raw output path;
- generated figure/table paths;
- expected invariants and validation results.

## Registered experiment

### paper1-theorem-falsification-v1

- **Configuration:** `experiments/configs/theorem_feasibility.toml`
- **Entry point:** `julia/scripts/search_counterexamples.jl`
- **Environment:** Julia 1.12.6 with `julia/Project.toml` and
  `julia/Manifest.toml`
- **Arithmetic:** `Rational{BigInt}`; exact comparisons only
- **RNG:** `StableRNGs.StableRNG`
- **Seed:** `6073180304494120241`
- **Command:** `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/search_counterexamples.jl`
- **Output:** `experiments/results/theorem_feasibility.json`
- **Lean fixture:**
  `formal/StrategyInnovation/Fixtures/TheoremFeasibility.lean`
- **Expected invariants:** no T1--T6 in-assumption failure; every boundary
  witness passes its independent exact check; the optional multi-gap additive
  bound fails.
- **Validation:** the full command was run twice and both outputs were
  byte-identical. The Julia test suite also reruns a smaller deterministic
  property search and every boundary fixture.
- **Scope warning:** exact search survival is not proof and does not satisfy the
  Lean claim gate.

### paper1-unified-semi-markov-falsification-v1

- **Configuration:** `experiments/configs/revision_counterexample_gauntlet.toml`
- **Entry point:** `julia/scripts/search_revision_counterexamples.jl`
- **Environment:** Julia 1.12.6 with `julia/Project.toml` and
  `julia/Manifest.toml`
- **Arithmetic:** `Rational{BigInt}`; exact comparisons only
- **RNG:** `StableRNGs.StableRNG`
- **Seed:** `6073180304494120242`
- **Command:** `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/search_revision_counterexamples.jl`
- **Non-mutating check:** same command with `--check`
- **Output:** `experiments/results/revision_counterexample_gauntlet.json`
- **Expected invariants:** all locked T1--T7 predicates survive; conditional
  dependence changes value without breaking T1; the naive cost-free T6 bound
  fails; frontier-dependent generation creates the T7 complementarity
  boundary; persistence and information fixtures have both signs; positive-
  and negative-frontier raw delay branches have opposite directions.
- **Validation:** 512 random semi-Markov models, 512 T6 instances, 512 T7
  frontier pairs, and the preserved 361,584-configuration exhaustive T3 search
  completed without an in-assumption failure. The dedicated Julia test reruns
  every exact fixture and a deterministic smoke gauntlet.
- **Scope warning:** finite exact search is falsification evidence, not proof.
  No Lean file is generated or modified by this experiment.

### paper1-resource-optimization-counterexample-audit-v1

- **Configuration:**
  `experiments/configs/resource_optimization_counterexamples.toml`
- **Entry point:**
  `julia/scripts/search_resource_optimization_counterexamples.jl`
- **Environment:** Julia 1.12.6 with the committed Julia project and manifest
- **Arithmetic:** `Rational{BigInt}` throughout; floating inputs rejected
- **Randomness:** none
- **Command:** `julia --project=julia
  julia/scripts/search_resource_optimization_counterexamples.jl`
- **Non-mutating check:** same command with `--check`
- **Outputs:** `experiments/results/resource_optimization_claim_audit.json`
  and 14 JSON files under
  `experiments/results/resource_optimization_fixtures/`
- **Expected invariants:** 14 targets; 13 exact counterexamples; one surviving
  burden-order claim; one fixture per target; no Lean changes; exact
  per-fixture hashes in the summary.
- **Validation:** exhaustive enumeration on the versioned carrier, weight,
  value, and module bounds; lexicographic witness minimization; focused Julia
  tests; deterministic byte comparison.
- **Scope warning:** the audit revises theorem statements but does not prove
  them. Carrier-minimality and bounded-search survival are reported separately
  from Lean verification.

### safe-compression-complexity-reduction-v1

- **Entry point:**
  `julia/scripts/verify_safe_compression_complexity_reductions.jl`
- **Environment:** Julia 1.12.6 with the committed Julia project and manifest
- **Arithmetic:** `Rational{BigInt}` throughout; floating inputs rejected
- **Randomness:** none
- **Command:** `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/verify_safe_compression_complexity_reductions.jl`
- **Non-mutating check:** same command with `--check`
- **Output:**
  `experiments/results/safe_compression_complexity_reduction_fixture.json`
- **Expected invariants:** closure-only, frontier-only, and combined
  constructors preserve every candidate mask's feasibility, exact weight,
  and optimizer correspondence for the registered weighted-set-cover
  instance.
- **Focused test:** `./.local_runtime/julia-1.12.6/bin/julia
  --project=julia/test -e 'using StrategyInnovation, Test;
  include("julia/scripts/verify_safe_compression_complexity_reductions.jl");
  using .SafeCompressionComplexityReductionFixture;
  include("julia/test/test_safe_compression_complexity.jl")'`
- **Validation:** 25 constructor assertions, 2,387 exhaustive small-incidence
  assertions, five artifact assertions, and 6,360 counted
  reduction/candidate-mask correspondences.
- **Scope warning:** this is exact executable validation of the polynomial
  constructors. The universal NP-completeness proof is human-readable and has
  no Lean counterpart or axiom audit.

### joint-descendant-bound-gauntlet-v1

- **Configuration:**
  `experiments/configs/joint_descendant_bound_gauntlet.toml`
- **Entry point:** `julia/scripts/search_joint_descendant_bound.jl`
- **Environment:** Julia 1.12.6 with the committed Julia project and manifest
- **Arithmetic:** `Rational{BigInt}` throughout
- **Randomness:** none
- **Grid:** every weak composition of two probability units over two terminal
  beliefs and three admitted outcomes, crossed with the registered
  continuation, gain-floor, discount, duration, cost, and operating-adjustment
  grids
- **Command:** `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/search_joint_descendant_bound.jl`
- **Non-mutating check:** same command with `--check`
- **Outputs:**
  `experiments/results/summaries/joint_descendant_bound_counterexamples.csv`
  and
  `experiments/results/summaries/joint_descendant_bound_summary.json`
- **Expected invariants:** zero failures in 2,204,496 primary joint-bound
  checks, 419,904 correlated checks, 734,832 negative-adjustment checks,
  2,204,496 two-descendant checks, 171,072 harm-corrected checks, and nine
  comparator-corrected checks; positive failures for the uncorrected harmful
  and positive-comparator formulas; eight minimized counterexamples and four
  survivor fixtures
- **Validation:** 37 focused package checks rerun the full exact enumeration,
  verify every gate and minimized boundary, exercise the public bound
  evaluators, and check deterministic CSV/JSON rendering.
- **Scope warning:** this finite enumeration opened the Lean gate only after
  every corrected check passed. It is falsification evidence, not proof; the
  generalized theorem is separately kernel checked.

### randomized-finite-library-stress-v1

- **Configuration:** `experiments/configs/randomized_library_stress.toml`
- **Entry point:** `julia/scripts/run_randomized_library_stress.jl`
- **Environment:** Julia 1.12.6 with the committed root and test manifests
- **Arithmetic:** `Rational{BigInt}` for every within-trial profile,
  probability, Bellman value, pruning loss, decomposition, and $J$;
  Float64 is used only to place report labels and Wilson intervals
- **RNG:** `StableRNGs.StableRNG`
- **Master seed:** `6073180304494120243`; every trial seed and deletion order
  is included in `randomized_library_trials.csv`
- **Design:** 90 trials with independently shuffled, exactly marginally
  balanced three-level columns across all twelve registered factors
- **Commands:**
  `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/run_randomized_library_stress.jl` and the same command with
  `--check`
- **Outputs:** `RANDOMIZED_LIBRARY_REPORT.md`, ten CSV tables and one JSON
  summary under `experiments/results/summaries/`, and three SVGs under
  `manuscript/figures/`
- **Expected invariants:** exact operational-plus-generative loss
  decomposition; frontier-only passive preservation; innovation-safe total
  value preservation; both cumulative approximation budgets; complete
  profile/module/closure/kernel/project source tables; marginal balance; and
  `theorem_evidence = false` on every trial
- **Validation:** 102 targeted tests pass. A separate CSV reconciliation
  confirms all 90 trials, 360 pruning rows, eight frontier-only loss cases,
  exact budgets/decompositions, factor counts, and source-table row formulas.
  The three SVGs were rendered on full-canvas QA wrappers and visually
  inspected.
- **Scope warning:** The random generator is not an economic population
  model. Frequencies and Wilson intervals are design-conditional robustness
  diagnostics, not theorem evidence, causal effects, or population
  prevalence estimates. The synthetic $J$ rectangle need not be realizable
  by four raw libraries and is not a T7 theorem instantiation.

### randomized-finite-library-stress-v2 — registered exact run complete

- **Design document:** `RANDOMIZED_DESIGN_V2.md`
- **Configuration:**
  `experiments/configs/randomized_library_stress_v2.toml`
- **Trial and seed registry:**
  `experiments/randomized_library_v2/TRIAL_REGISTRY.csv`
- **Initial lock:**
  `experiments/randomized_library_v2/DESIGN_LOCK.json`
- **Lock SHA-256:**
  `0b012dfc14f4ea57b0d34877a68d9a546cd499d2270903e772d78b21425d14db`
- **Sequential-stability amendment:**
  `RANDOMIZED_DESIGN_V2_AMENDMENT_1.md`,
  `experiments/configs/randomized_library_stability_amendment_1.toml`, and
  `experiments/randomized_library_v2/DESIGN_LOCK_AMENDMENT_1.json`
- **Amendment design SHA-256:**
  `d9122d258b8fe62d5872c41b0a418b1351a5798b25ddb99ec73b726e324d244f`
- **Prospective execution amendment:**
  `RANDOMIZED_DESIGN_V2_AMENDMENT_2.md`,
  `experiments/configs/randomized_library_execution_amendment_2.toml`, and
  `experiments/randomized_library_v2/DESIGN_LOCK_AMENDMENT_2.json`
- **Execution amendment SHA-256:**
  `8c278c07d998ba118d98c78cc1373a47ab63127f00d606c0042c006dac11e7be`
- **Registration utility:**
  `julia/scripts/lock_randomized_library_design_v2.jl`
- **Environment:** Julia 1.12.6, StableRNGs 1.0.4 for the future component
  streams, and exact `Rational{BigInt}` theorem-facing arithmetic
- **Master seed:** `6075990691714899803`
- **Recorded derived seeds:** 1,024 trial, 1,024 catalog, 1,024 project, and
  1,024 deletion seeds; all 4,096 are distinct and stored before outcomes
- **Design:** complete $2^7$ factorial across frontier density, module
  overlap, module complementarity, project cost, duration, admission, and
  persistence; 128 cells, eight replicates per cell, and eight 128-trial
  batches
- **Registered balance prefixes:** 256, 512, 768, and 1,024; every prefix is exactly
  balanced on all principal factors, cells, and the intended
  primitive-eligible/boundary split
- **Sequential precision prefixes:** 50, 100, 200, 300, 500, 750, 1,000, and
  1,024 in locked `trial_id` order. The early prefixes do not assert balance
  and report actual factor-level denominators. They are snapshots only; every
  final estimate uses the registered maximum $N=1024$.
- **Raw construction:** every source is $L_{11}$ from a
  `RealizableRectangle`; all four corners use one catalog and closure, and
  `rectangle_consistency` must derive and validate states, menus, transition
  pushforwards, values, and policies
- **Exact estimands:** frontier-only positive-loss frequency, conditional
  positive mean, maximum normalized loss, innovation-safe loss frequency,
  compression means, silent generative assets, all three interaction signs,
  theorem-assumption conditional frequencies, action switching, and three
  registered relationship summaries
- **Stability:** eight exact cumulative estimands and the same estimands at
  both levels of all seven factors; exact counts, sums, means, and sample
  variances; descriptive Wilson intervals for frequencies; presentation-only
  MCSEs for means; and deterministic sparse-support warnings. Alerts never
  stop the run, remove rows, select a sign, or change $N$.
- **Feasibility evidence:** three nonmutating v1 `--check` measurements were
  18.06, 17.21, and 17.04 seconds on the current arm64 Apple-M1 host. The
  median projects to 195.81 seconds for 1,024 v1-equivalent trials; the
  registered conservative v2 planning allowance is 900 seconds.
- **Lock verification command:**
  `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/lock_randomized_library_design_v2.jl --check`
- **Amendment verification command:**
  `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/lock_randomized_library_stability_amendment.jl --check`
- **Execution-lock verification command:**
  `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/lock_randomized_library_execution_amendment.jl --check`
- **Run and deterministic replay:**
  `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/run_randomized_library_stress_v2.jl`, followed by the same
  command with `--check`
- **Independent reconciliation:**
  `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/audit_randomized_library_v2_results.jl`
- **Outcome status:** complete at the registered maximum $N=1024$.
  Frontier-only positive loss is 398/1024; conditional mean positive loss is
  `124909129//78249984`; maximum normalized loss is `84963//222163`;
  innovation-safe positive loss is 0/1024; silent generative assets are
  388/5120; and the exact interaction counts are 256 substitution, 141
  complementarity, and 627 zero.
- **Hard gates:** all compressed states have raw witnesses; every rectangle
  has four valid raw corners; raw and compressed values agree in 1,920 checks
  per trial; innovation-safe frontier, closure, operational, generative, and
  total losses are all exactly zero; every signed loss decomposition closes;
  theorem-condition flags are mechanically evaluated; and theorem-facing
  output arithmetic is `Rational{BigInt}`.
- **Outputs:** `RANDOMIZED_LIBRARY_REPORT_V2.md`; complete trial, corner,
  transition, pruning, asset, action, profile, module, closure, kernel,
  project, and raw-witness CSVs; method, factor, relationship, stability, and
  interaction summaries; one JSON summary; and four source-linked SVGs.
- **Manuscript reporting:** Section 8.2 reports only the registered v2
  structural stress test and only interaction counts backed by four raw
  witnesses. Appendix E contains the exact cumulative diagnostics and the
  sole frozen-pilot comparison; the pilot interaction statistic is omitted
  because its compressed rectangle did not require four raw witnesses. The
  online supplement indexes the 64 cumulative and 896 factor-stratified
  stability rows.
- **Pilot boundary:** the v1 $N=90$ configuration, summary, report, source
  tables, and figures are hash-pinned and excluded from every v2 estimator.
- **Interpretation boundary:** all intervals and MCSEs are descriptive
  simulation-precision diagnostics under the registered finite generator.
  The results are not theorem evidence, causal estimates, or inference about
  a real population.
- **Amendment rule:** changing the sample, factor design, seed schedule, raw
  generator, rectangle construction, estimand, prefix, alert, or output path
  requires a new prospective lock before outcomes.

### approximate-library-compression-v1

- **Configuration:** `experiments/configs/approximate_compression.toml`
- **Entry point:** `julia/scripts/run_approximate_compression.jl`
- **Environment:** Julia 1.12.6 with the committed root and test manifests;
  no external optimizer or plotting dependency
- **Arithmetic:** `Rational{BigInt}` for profiles, probabilities, Bellman
  values, losses, feasibility, dominance, and search ordering
- **Randomness:** none during the experiment. The deterministic fixture
  reconstructs registered randomized-library trial 15 from seed `731700466`.
- **Design:** a six-strategy source and an eight-strategy expanded source;
  horizon four; reference belief one; operational budget one; signed
  generative budget $1/4$; exact enumeration plus four greedy scores,
  multistart, Pareto beams of widths 2, 4, 8, and 16, and solver-neutral
  operational 0--1 rows with generative no-good cuts
- **Commands:**
  `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/run_approximate_compression.jl` and the same command with
  `--check`
- **Outputs:** `APPROXIMATE_COMPRESSION_REPORT.md`, four CSV tables and one
  JSON summary under `experiments/results/summaries/`, and two SVGs under
  `manuscript/figures/`
- **Expected invariants:** 32 and 128 exact sublibraries; exact loss
  decomposition; all budget flags; exact cardinality minima 3 and 2; Pareto
  counts 5 and 11; complete-oracle 0--1 consistency; operational lower bound
  two on both benchmarks; deterministic rows; and
  `theorem_evidence = false`
- **Validation boundary:** Exact enumeration certifies only the two finite
  registered minima. Greedy and incomplete beam outputs have no approximation
  guarantee. The 0--1 formulation is exact for generative loss only with a
  complete Bellman-oracle cut set. This experiment does not create or validate
  a Lean theorem.

### multi-gap-topology-audit-v1

- **Configuration:** `experiments/configs/multi_gap_topology.toml`
- **Entry point:** `julia/scripts/search_multi_gap_topology.jl`
- **Environment:** Julia 1.12.6 with `julia/Project.toml` and
  `julia/Manifest.toml`
- **Arithmetic:** `Rational{BigInt}`; exact comparisons and determinants only
- **Randomness:** none; every registered finite grid is exhaustively enumerated
- **Command:** `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/search_multi_gap_topology.jl`
- **Output:** `experiments/results/multi_gap_topology.json`
- **Lean fixture:** `formal/StrategyInnovation/Fixtures/MultiGapRegion.lean`
- **Expected invariants:** row stochasticity; C2 potential
  `(4,41/32,1/2,41/32,4)` and two-component cost-covering set; all 251 square minors
  nonnegative; no sign-variation increase in 3,125 vector tests; no strict-
  superlevel component increase in 28,125 gap--threshold tests; arbitrary-cost
  cost-covering set has three components from a one-component constant gap.
- **Validation boundary:** the C2 and arbitrary-cost propositions are
  independently recomputed and proved in Lean. The finite minor/sign/component
  grids are validation evidence only and do not justify a universal topology
  theorem.

### innovation-safe-library-compression-v1

- **Configuration:** `experiments/configs/compression_experiments.toml`
- **Entry point:** `julia/scripts/run_compression_experiments.jl`
- **Environment:** Julia 1.12.6 with `julia/Project.toml` and
  `julia/Manifest.toml`; no optimizer dependency
- **Arithmetic:** `Rational{BigInt}` for the F3/F4 fixtures and exhaustive
  minimum; explicit `Float64Mode()` only for scaling sizes 16, 32, 64, and 128
- **RNG:** `StableRNGs.StableRNG`
- **Seed:** `4850180331074310995`
- **Command:** `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/run_compression_experiments.jl`
- **Outputs:**
  `experiments/results/summaries/compression_experiments.{json,csv}`
- **Expected invariants:** stepwise safe pruning preserves frontier and closure;
  the exact F4 frontier-only row preserves the current frontier but loses the
  key closure and exact value five; exhaustive and fixed-point output both have
  size three on the comparison fixture; every scaling row preserves frontier,
  closure, compressed state, and the declared passive value oracle.
- **Validation:** 1,495 compression unit/property checks pass, including 40
  explicitly seeded random small libraries and exhaustive validation of every
  0--1 selection on each generated formulation. Together with 439 prior checks,
  the compression-era suite passed 1,934 checks; with the 226 registered
  dynamic-program checks below, the current full suite passes 2,160.
- **Scope warning:** runtime is host-dependent; Float64 rows are scaling
  diagnostics only. The fixed-point method has no Lean-verified approximation
  ratio, and the solver-neutral formulation has no attached solver result.

### unified-canonical-benchmark-v1

- **Configuration:** `experiments/configs/unified_canonical_benchmark.toml`
- **Selected calibration:**
  `experiments/configs/unified_benchmark_selected.toml`, candidate C0424
- **Entry point:**
  `julia/scripts/solve_unified_canonical_benchmark.jl`
- **Environment:** Julia 1.12.6 with `julia/Project.toml` and
  `julia/Manifest.toml`; `LinearAlgebra`, `Printf`, and `TOML` are Julia
  standard libraries
- **Construction:** four raw strategies, all eight inactive-containing raw
  libraries, one capability module, raw generation and verification,
  full positive-duration belief-path/admission couplings, and deterministic
  raw insertion. All three compressed states and every transition are derived.
- **Arithmetic:** `Rational{BigInt}` for finite-horizon recursion, raw and
  compressed policy iteration, and stationary policy evaluation; Float64
  compiled only from the exact embedded raw laws for value iteration and
  policy evaluation
- **Randomness:** none
- **Command:** `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/solve_unified_canonical_benchmark.jl`; append `--check` for
  the nonmutating artifact gate
- **Outputs:** `experiments/results/summaries/unified_canonical_{summary.json,
  values.csv,policies.csv,transition_edges.csv,duration_paths.csv,
  operating_rewards.csv,convergence.csv,comparative_statics.csv}` and
  `manuscript/figures/unified_canonical_transition.tex`
- **Stopping rule:** successive-iterate sup norm at most `1e-12`, with a
  10,000-iteration cap; every row records the Float64 Bellman residual,
  Float64 a-priori contraction bound, and Float64 a-posteriori contraction
  bound
- **Expected invariants:** every duration is positive; research belief
  marginals are $P^d$; 32 embedded transition, 144 finite-value, 128
  finite-policy, 16 stationary-value, and 16 stationary-policy projection
  checks pass; exact policy and Bellman residuals are zero; the exactly
  evaluated error of the rationalized Float64 iterate is below its exactly
  re-evaluated residual-based certificate; and exact and Float64 actions agree
  on all six states.
- **Scope warning:** these are exact and numerical checks of one selected
  finite instance, not a new theorem or empirical result. Float64 evidence is
  not proof.

### unified-canonical-resources-v1

- **Configuration:** `experiments/configs/unified_canonical_resources.toml`
- **Source benchmark:** `unified-canonical-benchmark-v1`, selected C0424
- **Entry point:** `julia/scripts/run_unified_resource_benchmark.jl`
- **Weights:** preregistered in D-0131 before resource outputs. The primary
  model uses `W` schedules `(0,1,1,1)`, `(0,2,2,1)`, and `(0,1,1,2)`, ordered
  as inactive, carrier A, carrier B, descendant. The resource artifacts add a
  common mandatory display unit, `W_display(L) = 1 + W(L)`, and therefore
  store/display `(1,1,1,1)`, `(1,2,2,1)`, and `(1,1,1,2)`. The configuration
  key named `inactive` is this display addend, not a positive primary-model
  weight for the inactive strategy.
- **Arithmetic:** `Rational{BigInt}` for values, display burdens, optima,
  switching prices, derivatives, durations, elasticities, and certificates;
  `Float64` only after exact evaluation for SVG coordinates
- **Randomness:** none
- **Command:** `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/run_unified_resource_benchmark.jl`; append `--check` for the
  nonmutating twelve-artifact drift gate
- **Outputs:** seven exact summaries under
  `experiments/results/summaries/unified_canonical_resource_*`, exact channel
  TeX under `manuscript/tables/`, and four SVGs under `manuscript/figures/`
- **Enumeration domain:** all eight inactive-containing raw libraries, all
  exact safe sublibraries of every source, every attainable displayed total
  burden, all pairwise library intersections, and every globally active
  nonnegative price cell, for both initial beliefs and all three weight
  schedules
- **Expected invariants:** every optimum is feasible and every tie is retained;
  every proper exact-safe deletion strictly lowers positive active burden;
  productive value is constant on every exact safe class; capacity value is
  weakly increasing; and the minimum-burden penalized selection is weakly
  decreasing in price. Operational plus generative value and their normalized
  discount contributions equal productive value and duration exactly.
- **Scope warning:** fixed-policy discount derivatives are local because all
  six benchmark action gaps are positive. Library distance is measured in
  resource-price space; action distance is the half-gap in Bellman-Q
  `l-infinity` space. The finite-instance calculations add no Lean theorem or
  empirical claim.

### unified-elasticity-switching-v1

- **Configuration:**
  `experiments/configs/unified_elasticity_switching_v1.toml`
- **Pre-outcome lock:**
  `experiments/unified_elasticity_switching_v1/DESIGN_LOCK.json`, design
  SHA-256
  `1a6d6f1a41def79773751216101f17169f58bc928e2191ba8362715edcd9c3db`
- **Entry point:**
  `julia/scripts/run_unified_elasticity_switching_experiment.jl`
- **Command:** `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/run_unified_elasticity_switching_experiment.jl`; append
  `--check` for the nonmutating byte-for-byte table/figure drift gate
- **Arithmetic:** exact `Rational{BigInt}` bridge, dynamic derivative,
  curvature, channel, burden, capacity, elasticity, optimizer, and breakpoint
  rows. `Float64` is used only after exact evaluation for SVG coordinates.
- **Registered grids:** normalized bridge margins from `1//16` through `1`,
  durations one through five, five uniform belief coordinates, and three-point
  one-at-a-time grids for admission, survival, discount, research cost, and
  descendant-payoff scale. Resource paths reuse all three D-0131 burden
  schedules, both benchmark beliefs, every attainable capacity, and every
  globally active nonnegative exact price breakpoint.
- **Outputs:** eight exact CSV source tables plus one summary JSON under
  `experiments/results/summaries/unified_elasticity_switching_v1_*` and six
  publication SVGs under
  `manuscript/figures/unified_elasticity_switching_v1_*`. Each SVG embeds the
  exact source-table path in machine-readable metadata.
- **Validation:** rebuild the exact optimal policy, reconstruct its value
  system, solve and check the local discount-derivative system, require zero
  policy/Bellman/derivative residuals, close both channel identities, retain
  complete eight-library resource correspondences, check capacity monotonicity
  and lambda-burden antitonicity, and distinguish exact half-Q-gap action
  distance from registered primitive-coordinate switch brackets.
- **Scope warning:** innovation duration is a local fixed-policy derivative on
  the selected action branch. Belief convexity and adjacent robustness switches
  are results on the registered finite grids. They are not general theorems or
  exact roots in the primitive coordinate.

### canonical-discounted-dp-v1 — legacy compatibility fixture

- **Configuration:** `experiments/configs/canonical_discounted_dp.toml`
- **Entry point:** `julia/scripts/solve_canonical_model.jl`
- **Status:** deprecated from main-manuscript artifact generation; retained
  unchanged for primitive F5/F8 regression and the Appendix D compatibility
  note
- **Outputs:** historical `canonical_model_summary.json`,
  `canonical_model_convergence.csv`, and `canonical_model_policy.csv`
- **Boundary:** its primitive transition and
  $\beta^{\mathrm{delay}+1}$ convention are not the unified canonical law.

### manuscript-numerical-artifacts-v1

- **Entry point:**
  `julia/scripts/generate_manuscript_numerical_artifacts.jl`
- **Environment:** Julia 1.12.6; only the `Printf` and `TOML` standard
  libraries are used
- **Randomness:** none; the renderer consumes committed, already registered
  summaries
- **Command:** `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/generate_manuscript_numerical_artifacts.jl`; append `--check`
  for the nonmutating byte-drift gate
- **Inputs:** unified canonical convergence, exact compression, exact theorem-
  mechanism pruning/decomposition/geometry, locked-terminal and annual
  walk-forward configurations and complete grammar/candidate tables, both
  mechanism/decomposition/uncertainty summaries, and the committed annual
  episode-ranking table under `experiments/results/summaries/`
- **Outputs:** `manuscript/figures/{unified_canonical_convergence,
  financial_innovation_safe_compression,
  financial_coverage_comparison}.tex`,
  `manuscript/tables/{numerical_mechanism_summary,
  financial_design_summary}.tex`, and
  `experiments/results/summaries/financial_compression_{policy_characteristics,
  predictor_summary,estimand_metadata}.csv`
- **Information-set companion:** `EMPIRICAL_INFORMATION_SET_AUDIT.md`
  classifies pruning-time, validation/pre-target, held-out, retrospective,
  and oracle quantities and records actual algorithm use separately from
  logical availability
- **Validation:** requires all 42 unified canonical iterations and the registered
  stopping rule; exact safe-compression, scaled-loss, decomposition, and
  component-count identities; complete 2,400/9,600 strategy grammars; both
  financial safe-compression frontier, closure, and ex post opportunity-quality
  identities; the operational--generative decomposition; the carrier/predictor
  identification boundaries; and exact declared uncertainty method sets
  before any output is written
- **Visual contract:** the convergence plot uses distinct solid, dashed, and
  dotted paths and places a marker at every one of the 42 integer iterations.
  The primary financial figure is a natural-size three-panel mechanism audit
  with `\scriptsize` body text and `\footnotesize` one-line titles. It reports
  strategy and module retention fractions with exact counts plus separately
  scaled audit-specific ex post enabled-descendant opportunity-quality cards.
  The bridge figure owns the carrier-path mechanism, so it is not repeated in
  the financial figure. No enclosing resize operation reduces the declared
  fonts, and the figure never pools incomparable quality magnitudes. The
  metadata records held-out outcome timing,
  `algorithm_input=false`, and the separate pruning acceptance tests without
  changing any numerical column. The secondary coverage comparison uses
  separate axes and estimands, distinct markers, and explicit zero lines.
  Main Figure 4 remains wholly on page 26; the controlled experiments occupy
  pages 24--27 and the conclusion occupies pages 28--29 of the 66-page paper.
- **Scope warning:** this is a presentation renderer. It creates no theorem,
  changes no experiment result, and does not authorize licensed-row
  redistribution. Manual edits to its generated outputs are prohibited.

### figure-audit-artifacts-v1

- **Entry point:** `julia/scripts/generate_figure_audit_artifacts.jl`
- **Inputs:** `experiments/results/summaries/innovation_safe_bridge.csv` and
  `unified_elasticity_switching_v1_{capacity,penalized_path}.csv` under the same
  summaries directory
- **Outputs:** `manuscript/figures/innovation_safe_bridge.tex` and
  `manuscript/figures/unified_economic_geometry.tex`
- **Validation:** the renderer checks the five exact bridge entities, parses
  all source numerics as `Rational{BigInt}`, and rejects incomplete capacity
  optimizers or penalty ties. `--check` is nonmutating and byte-sensitive.
- **Visual contract:** exact profiles use publication notation; the combined
  geometry uses right-continuous stairs, exact active affine branches, and
  open/filled endpoints at exact tie prices. Only TikZ coordinate placement is
  floating-point. `ARTIFACT_MANIFEST.md` records the public figure inventory,
  sources, producers, arithmetic, and hashes.

### strategy-value-equation-figure-v1

- **Configuration:** `experiments/configs/strategy_value_figure.toml`
- **Entry point:** `julia/scripts/generate_strategy_value_figure.jl`
- **Environment:** Julia 1.12.6 with `julia/Project.toml` and
  `julia/Manifest.toml`; the manuscript renderer additionally uses the pinned
  host pdfTeX/TikZ path recorded above
- **Arithmetic:** `Rational{BigInt}` throughout the finite model, recursion,
  occupancy expansion, and output table; decimal labels are display-only
- **Randomness:** none
- **Command:** `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/generate_strategy_value_figure.jl`; pass `--check` for the
  nonmutating byte-drift gate
- **Outputs:**
  `experiments/results/summaries/strategy_value_equation_figure.csv` and
  `manuscript/figures/strategy_innovation_equation.tex`
- **Expected invariants:** the current frontier gap is zero; a future occupied
  belief has positive gap; the passive insertion difference, F7 discounted-gap
  recursion, and occupancy-weighted gap sum are exactly equal to `3891//2048`;
  the generated plot contains the existing frontier, dashed candidate profile,
  positive-gap shading, and discounted occupancy bars.
- **Validation:** dedicated package tests check the exact identities and
  channel separation; the drift command passes; the complete manuscript compiles
  without reference or citation warnings; and every rendered page is visually
  inspected, with Section 6 kept within its four-page allocation.
- **Scope warning:** this is a deterministic canonical illustration of the
  primitive F7 adapter, not empirical evidence or T5/T6 proof evidence.
  Its occupancy weights are a finite discrete-time expansion, not a
  continuous-time or infinite-horizon result.

### coverage-potential-geometry-v1

- **Configuration:** `experiments/configs/coverage_geometry.toml`
- **Entry point:** `julia/scripts/run_coverage_geometry.jl`
- **Environment:** Julia 1.12.6 with `julia/Project.toml` and
  `julia/Manifest.toml`; only the declared standard linear-algebra dependency
  is used for coverage solves, and SVG rendering has no external plotting
  dependency
- **Arithmetic:** `Rational{BigInt}` for exact S4/S5/S6/C2 fixtures,
  finite discount--survival interactions, and resolvent tests; explicit
  `Float64Mode()` for the 121-state smooth geometry and one-at-a-time
  sensitivities
- **Randomness:** none
- **Command:** `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/run_coverage_geometry.jl`
- **Outputs:** `experiments/results/summaries/coverage_geometry_summary.json`,
  six `coverage_*.csv` tables in the same directory, and five
  `manuscript/figures/coverage_*.svg` figures
- **Expected invariants:** exact delayed S4 potential one; exact S5 destructive
  potential `(1,0,1)` and failed stochastic-monotonicity hypothesis; exact C2
  potential `(4,41/32,1/2,41/32,4)` with two strict components; one connected
  smooth baseline cost-covering set; every detected smooth boundary transverse at the
  declared tolerance; every figure linked to complete CSV data
- **Validation:** 266 dedicated tests cover finite-sum/resolvent agreement,
  the independently evaluated S6 four-corner and factorized cross differences,
  exact fixtures, positive and failed theorem assumptions, one-shot cutoff
  directions, components, thresholds, boundaries, six sensitivities, four
  grid refinements, 30 seeded
  exact rational kernels, and isolated JSON/CSV/SVG output. Five rendered SVG
  previews were inspected for legibility, line-style/color redundancy, labels,
  and clipping.
- **Scope warning:** `P^t` is a Markov specialization of Lean S4's primitive
  occupation table. S6 verifies only the exact finite sum and finite
  difference; the infinite resolvent, lifetime delay, transversality,
  sensitivity, and smooth figures are numerical diagnostics, not Lean proofs.
  This experiment does not implement raw generation, verification, admission,
  or T6's separately verified retained-carrier descendant bound.

### kernel-persistence-response-surface-v1

- **Configuration:**
  `experiments/configs/kernel_persistence_response.toml`
- **Entry point:**
  `julia/scripts/run_kernel_persistence_response.jl`
- **Environment:** Julia 1.12.6 with the committed Julia project and manifest
- **Arithmetic:** `Rational{BigInt}` throughout kernel construction, finite
  matrix powers, discounted occupation, coverage, and output rendering
- **Randomness:** none
- **Grid:** persistence $\theta=0,1/8,\ldots,1$; effective discount
  $\alpha=0,1/4,\ldots,1$; horizon two; initial state one in Julia's
  one-based indexing; three exact gap locations
- **Command:** `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/run_kernel_persistence_response.jl`; append `--check` for the
  nonmutating byte-drift gate
- **Outputs:**
  `experiments/results/summaries/kernel_persistence_response_surface.csv`
  and
  `experiments/results/summaries/kernel_persistence_response_summary.json`
- **Expected invariants:** 135 exact rows; at
  $(\alpha,\theta_0,\theta_1)=(1/2,1/4,3/4)$, current-state gap coverage
  rises $9/8\to11/8$, other-state gap coverage falls $3/8\to1/8$, and
  constant-gap coverage remains $3/2$. The associated advantage-region
  occupations move in the same directions.
- **Validation:** 35 dedicated package checks cover exact witness values,
  every response-surface direction, constant-gap invariance, invalid gaps and
  initial states, deterministic rendering, and output schema/drift.
- **Scope warning:** the response surface validates S7's exact examples. The
  general occupation-alignment implication is proved in Lean, not by this
  finite grid. Neither artifact supports a universal scalar persistence sign.

### system-interaction-surface-v2

- **Configuration:**
  `experiments/configs/system_interaction_surface.toml`
- **Entry point:**
  `julia/scripts/run_system_interaction_surface.jl`
- **Environment:** Julia 1.12.6 with the committed Julia project and manifest
- **Arithmetic:** `Rational{BigInt}` throughout project premia, optimized
  closure increments, cross differences, classifications, and rendering
- **Randomness:** none
- **Legacy grid:** six frontiers, two fixed candidate values, three success
  probabilities for each of the old and added projects, three costs for each
  project, every strict ordered frontier pair, and discount $1/2$; 2,430
  rows in total. This registered v1 output is preserved byte-for-byte. Its
  incumbent operating reward is the reported frontier, so every legacy
  rectangle is realizable in its constructed one-belief model.
- **Expanded response:** every strict pair from four frontier levels, every
  strict pair from four incumbent-reward levels, two closure-richness levels,
  two project costs, two admission probabilities, two descendant payoffs, two
  durations, and three generator-quality frontier-dependence levels; 3,456
  exact rows in total
- **Command:** `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/run_system_interaction_surface.jl`; append `--check` for the
  nonmutating byte-drift gate
- **Outputs:** the preserved
  `experiments/results/summaries/system_interaction_surface.csv`, the five-row
  `system_interaction_exact_fixtures.csv`, the 3,456-row
  `system_interaction_response_surface.csv`, and
  `system_interaction_summary.json`, all under
  `experiments/results/summaries/`
- **Expected invariants:** 553 substitute, 1,865 separable, and 12 complement
  rows remain in the legacy grid. The five canonical fixtures record primitive
  strict substitution $J=-1$, a saturation boundary $J=0$,
  frontier-independent optimizer switching $J=1/2$,
  frontier-dependent success $J=1/2$, and a nontrivial separable case
  $J=0$, together with all four selected projects, corner realizability, and
  the primitive-condition certificate. Of 3,456 expanded rectangles, 576
  have all four constructed compressed corners realizable and therefore enter
  the sign summary: 156 substitutes, 183 complements, and 237 separable
  cases. The other 2,880 rows are reported but excluded from every aggregate
  interaction-sign count. All 192 primitive-certified response rows have
  $J\leq0$.
- **Realizability rule:** a corner is realizable in the constructed one-belief
  model exactly when its reported frontier equals its incumbent operating
  reward. `sign_aggregation_eligible` is true exactly when this holds at all
  four corners.
- **Validation:** 80 dedicated package checks cover the generic increment and
  cross-difference APIs, all five fixtures and their corner policies,
  requested response axes, exact conditioned counts, primitive sign
  restriction, invalid-input guards, deterministic rendering, and artifact
  drift.
- **Scope warning:** the positive fixed-primitives rows are evidence that
  primitive frontier independence and individual candidate saturation do not
  imply T7. The general corrected substitution theorem uses relative
  Bellman-action saturation and is proved in Lean; the grid is not its proof.
  Computed $J$ values on nonrealizable compressed rectangles are diagnostic
  only and are never pooled with realizable interaction signs.

### raw-realizable-rectangle-fixtures-v1

- **Implementation:** `julia/src/RealizableRectangles.jl`
- **Tests:** `julia/test/test_realizable_rectangles.jl`
- **Environment:** Julia 1.12.6 with the committed Julia project and manifest
- **Arithmetic:** exact `Rational{BigInt}` profiles, probabilities, costs,
  transition rewards, and finite-horizon values
- **Randomness:** none
- **Generators:** `exact_identity_rectangle_fixture()` and
  `exact_generated_closure_rectangle_fixture()`; the first uses identity
  closure and a module-only carrier, while the second derives `bridge` from a
  frontier-silent `trigger` carrier
- **Focused command:** `./.local_runtime/julia-1.12.6/bin/julia
  --project=julia -e 'using StrategyInnovation, Test;
  include("julia/test/test_realizable_rectangles.jl")'`
- **Expected invariants:** both fixtures share one catalog and closure object
  across their four raw corners; the raw additions commute; the four images
  are exactly $(F_0,C_0),(F_0,C_1),(F_1,C_0),(F_1,C_1)$; menus equal the
  requirement-derived feasible actions; every raw embedded law pushes forward
  to its compressed counterpart; and two-period raw/compressed values and
  policies agree
- **Validation:** 63 focused exact checks
- **Scope warning:** these are two exact realizability witnesses and reusable
  construction infrastructure. They do not prove T7, determine the sign of
  $J$, or change the registered D-0090 response surface.

### primitive-substitution-search-v1

- **Configuration:**
  `experiments/configs/primitive_substitution_search.toml`
- **Entry point:**
  `julia/scripts/search_primitive_substitution.jl`
- **Environment:** Julia 1.12.6 with the committed Julia project and manifest
- **Arithmetic:** `Rational{BigInt}` throughout action returns, pairwise
  relative-saturation checks, optimized closure increments, and rendering
- **Randomness:** none
- **Grid:** the same preserved 2,430 strict-frontier-pair,
  fixed-descendant, success, and cost rows as the legacy component of
  `system-interaction-surface-v2`
- **Command:** `julia --project=julia
  julia/scripts/search_primitive_substitution.jl`; append `--check` for the
  nonmutating byte-drift gate
- **Outputs:**
  `experiments/results/summaries/primitive_substitution_search.csv` and
  `experiments/results/summaries/primitive_substitution_summary.json`
- **Expected invariants:** 1,134 rows satisfy all-pairs relative saturation.
  The broader added-exposure order holds on 1,620 rows but fails on 648.
  Zero poor exposure and nonnegative rich exposure hold on 810 rows, with no
  relative-saturation failure. The $J=-1$ strict-substitution and $J=1/2$
  optimizer-switching fixtures are reproduced exactly, and all 12 complement
  rows remain visible.
- **Validation:** 38 dedicated checks cover exact counts, the broader
  counterexample, the primitive survivor class, the preserved optimizer
  switch, invalid gap order, deterministic rendering, and output drift.
- **Scope warning:** the search falsifies the broader primitive proposal and
  validates finite instances of A-T7-COMMON-GAP. The general implication from
  the common-gap certificate to relative action saturation is proved in Lean.
  The fixed-continuation representation is not claimed for arbitrary
  action-dependent successor closures.

### lean-julia-exact-fixture-bridge-v2

- **Entry point:** `julia/scripts/export_exact_fixtures.jl`
- **Schema:** `shared/schemas/exact_fixture.schema.json`, version
  `lean-julia-exact-fixture-v2`
- **Environment:** Julia 1.12.6 with the committed Julia environment; Lean
  4.32.0 and the pinned mathlib revision for generated examples
- **Arithmetic:** `Rational{BigInt}` in Julia and `ℚ` in Lean; no Float64 path
- **Randomness:** none
- **Command:** `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/export_exact_fixtures.jl`
- **Outputs:** eighteen JSON files in `shared/exact_fixtures/` and
  `formal/StrategyInnovation/Fixtures/Generated.lean`
- **Expected invariants:** canonical version/rational encoding; positive
  unified project duration; lexicographic fixture order; exact stochastic
  rows; resolved references; byte-identical rerender; all generated Lean
  equality and inequality examples compile
- **Validation:** 110 deterministic Julia bridge checks, exporter `--check`, CI
  regeneration followed by a generated-path Git-diff gate, and `lake build`
- **Scope warning:** fixture agreement validates exact implementation
  correspondence on selected finite inputs. It does not prove or replace the
  corresponding general theorems and does not change any theorem-ledger
  status.

### theorem-mechanism-controlled-suite-v2

- **Configuration:** `experiments/configs/theorem_mechanisms.toml`
- **Entry point:** `julia/scripts/run_theorem_mechanism_experiments.jl`
- **Environment:** Julia 1.12.6 with the committed root/test project and
  manifests; standard-library `TOML` and `SHA` support configuration and
  metadata handling
- **Arithmetic:** `Rational{BigInt}` for exact families A--F; explicit
  `Float64` for the 61-belief family G policy map
- **RNG:** order-independent `StableRNGs.StableRNG` streams initialized from
  the recorded seed
- **Seed:** `6075990691714899795`
- **Command:** `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/run_theorem_mechanism_experiments.jl`
- **Drift check:** rerun the same command with `--check`; tracked outputs are
  regenerated in transient storage and compared byte-for-byte
- **Raw output:**
  `experiments/results/raw/theorem_mechanism_observations.csv` (850 rows;
  ignored but recreated and SHA-256 checked through metadata)
- **Committed outputs:** `experiments/results/SYNTHETIC_REPORT.md`, the
  `theorem_mechanism_*` summary/figure-data files under
  `experiments/results/summaries/`, and five matching SVGs under
  `manuscript/figures/`
- **Expected invariants:** distinct code aliases with equal frontier/closure
  have equal values and policies; isolated frontier and closure changes enter
  the passive and premium channels respectively; stepwise redundant deletion
  preserves state/value/policy; F4 loss equals half future reward; all three
  F6 decompositions close exactly; the four S5/C2 cost-covering geometries have component
  counts `(1,1,2,2)`; prospective S4 coverage scores equal independently
  evaluated date-first gross values for all six candidates and recover their
  exact ranking; the configured half-margin error preserves the top candidate,
  the larger stress error flips it, and marginal top-two selection rejects a
  redundant clone; all Float64 solves converge, policy regions are connected,
  and configured cost/delay/discount policy directions hold
- **Validation:** 367 automatic experiment validations; 61 Julia family,
  determinism, exact ranking, identity-gate, and artifact-generation regression
  checks; metadata records source/config/manifest and artifact SHA-256 values;
  all five SVGs are generated from committed source tables and visually checked
- **Scope warning:** A--F validate selected exact supporting mechanisms and G
  is numerical evidence only. The ranking construction targets exactly S4's
  fixed-candidate gross occupation value; it is not evidence for a universal
  ranking theorem, misspecified occupations, candidate-dependent admission,
  costs, or the empirical ETF ordering. The suite does not implement the
  accepted raw generation/admission model, prove a stationary-policy theorem,
  or change any T1--T7 status. Version 1 is retained in Git history; version 2
  is a prospective extension relative to execution, not a post-hoc empirical
  analysis.

### dynamic-policy-region-view-v1

- **Source:**
  `experiments/results/summaries/theorem_mechanism_policy_summary.csv`,
  produced by `theorem-mechanism-controlled-suite-v2`
- **Entry point:** `julia/scripts/generate_dynamic_policy_figure.jl`
- **Environment:** Julia 1.12.6 with the committed Julia environment; the
  manuscript renderer uses the pinned pdfTeX/TikZ path
- **Arithmetic:** display-only parsing of the committed Float64 cutoff table;
  no Bellman solve is rerun by this view generator
- **Randomness:** none beyond the already registered upstream family-G seed
- **Command:** `./.local_runtime/julia-1.12.6/bin/julia --project=julia
  julia/scripts/generate_dynamic_policy_figure.jl`; pass `--check` for the
  nonmutating byte-drift gate
- **Output:** `manuscript/figures/dynamic_research_policy_regions.tex`
- **Expected invariants:** nine requested cost/delay/discount scenarios are
  present; every row reports convergence, one connected component, 61 belief
  points, and a cutoff in the finite grid; cost and delay cutoffs are
  nondecreasing, while discount cutoffs are nonincreasing
- **Validation boundary:** the figure is a compact numerical observation. It
  proves neither a continuous policy boundary nor a stationary optimal-policy
  theorem and changes no Lean or T1--T7 status.

### terminal-financial-audit

- **Configuration:** `experiments/configs/financial_terminal_audit.toml`
- **Entry points:** `julia/scripts/prepare_financial_terminal_audit_data.jl` and
  `julia/scripts/run_financial_terminal_audit.jl`
- **Environment:** Julia 1.12.6 with the committed root/test project and
  manifests
- **Source:** existing licensed CRSP/WRDS daily-security and security-history
  extracts at sibling commit
  `3146029aa71dfe7639ede9ca79f81602165125e8`; the ORATS master is used only to
  audit the covered ETF inventory
- **Universe:** 24 stable-identifier ORATS-covered ETFs plus SHY; SMH is
  excluded rather than spliced across two different CRSP funds
- **Arithmetic:** `Float64` for the empirical backtest; configured hard
  tolerances for formal expected identities
- **RNG:** `StableRNGs.StableRNG`
- **Seed:** `6075990691714899801`
- **Commands:**
  `julia --project=julia julia/scripts/prepare_financial_terminal_audit_data.jl`,
  then `julia --project=julia julia/scripts/run_financial_terminal_audit.jl`;
  append `--check` to the latter for the non-mutating byte-drift gate
- **Reviewer access:** point a copied configuration at an independently
  licensed CRSP/WRDS extract with the documented schemas. The frozen
  ticker/PERMNO universe makes ORATS optional; if present, it is re-audited.
- **Local raw input:** ignored 106,975-row, 25-fund panel with SHA-256
  `8fad82e719a97160072835b5c4d02a5581283473919aad67cf2346ea8da17af4`
- **Committed outputs:** every strategy and pruning decision; ranking,
  decomposition, uncertainty, cost, and figure-data tables; self-checksummed
  status metadata; a draft results section; an empirical limitations note;
  and three SVG figures
- **Expected invariants:** frontier-only pruning preserves the validation
  frontier; innovation-safe compression preserves both frontier and closure;
  its current and ex post enabled-descendant opportunity-quality values are
  unchanged; and every operational--generative decomposition closes at the
  configured tolerance
- **Information-set audit:** the pruning calls and decision hash precede the
  first locked-period quality access. Frontier-only deletion accepts on
  frontier equality; innovation-safe deletion accepts on frontier and closure
  equality. Neither acceptance test reads $Q_a$. The enabled set is
  structurally derivable but not tested by pruning; coverage scores are
  validation-only ranking inputs fixed after compression. Compression ratio,
  module uniqueness, and descendant dependence are retrospective structural
  summaries. Locked net utility, $Q_a$, ex post generative contribution,
  support for the best descendant, and rank diagnostics are held out.
- **Validation result:** frontier-only compression reduced 80 strategies to 3
  and ex post enabled-descendant opportunity quality by about 0.00156;
  innovation-safe compression reduced 80 to 25 with both registered changes
  zero; coverage ranking underperformed all declared comparators; one
  dominated GLD carrier had zero operational and positive generative value and
  uniquely supported the best enabled descendant
- **Publication boundary:** raw and row-level licensed inputs are excluded;
  aggregate tables, figures, reports, and metadata are publishable.
- **Scope warning:** the snapshot is point-in-time-conscious but not certified,
  the surviving universe is not survivorship-free, the holdout is
  retrospective, and transaction costs are reduced-form. This is mechanism
  evidence only, not an alpha or Lean-verification claim.

### annual-walk-forward-financial-audit

- **Configurations:** `experiments/configs/financial_annual_universe_audit.toml`
  and `experiments/configs/financial_annual_walkforward_audit.toml`
- **Entry points:** `julia/scripts/audit_financial_annual_universe.jl`,
  `julia/scripts/freeze_financial_annual_walkforward_audit.jl`,
  `julia/scripts/prepare_financial_annual_walkforward_audit_data.jl`, and
  `julia/scripts/run_financial_annual_walkforward_audit.jl`
- **Environment:** Julia 1.12.6 with the committed root/test project and
  manifests
- **Source:** the existing licensed CRSP/WRDS snapshot and source commit used
  by the terminal audit; no network request or download occurs
- **Outcome-blind universe:** 100 same-PERMNO endpoint-stable ETFs selected
  from 159 eligible funds, themselves drawn from 427 endpoint ETF identities,
  by 2009--2014 median dollar volume; the universe audit does not parse returns
- **Arithmetic:** `Float64` empirical sufficient statistics with hard
  registered identity tolerances; theorem fixtures elsewhere remain exact
- **RNG and seed:** `StableRNGs.StableRNG`, seed `6075990691714899802`; 2,000
  deterministic annual-episode bootstrap replications
- **Periods:** development 2009--2014, validation 2015--2019, and five locked
  annual walk-forward audit periods from 2020 through 2024, each using a
  trailing five-year estimation window
- **Commands:** run the four entry points above with
  `./.local_runtime/julia-1.12.6/bin/julia --project=julia`; the final runner
  accepts `--check` for non-mutating artifact drift validation
- **Lock chain:** the initial analytical design hash is
  `2af8b413e2b37eea94cb9a5ded6b48d6ca268be7d92fcaf0823be9830be994bc`.
  A-001 is a sparse-state support amendment made after a support-only abort and
  before any ranking result; A-002 through A-007 are report-only corrections. The
  completed implementation hash is
  `6c92ad2b12196f6e481fac5a4c3b3703591f4ec20861df44b75bee3618c51e88`.
- **Local raw input:** ignored 427,900-row, 100-fund panel with SHA-256
  `029b623b18836190d196e6543539380582e0ec046671d6f0d9a4db026e207ffc`
- **Committed outputs:** 9,600 grammar and candidate rows, 404 pruning
  decisions, 46,990 annual candidate rankings, 100 recorded top-five selection
  decisions, decomposition/uncertainty/cost/figure-data tables, three SVGs,
  a generated manuscript section, data audit, results draft, limitations note,
  and self-checksummed status metadata
- **Information-set audit:** pruning is completed before the annual ranking
  routine, and each walk-forward decision hash is fixed before target-year
  outcomes are accessed. Frontier-only deletion accepts on frontier equality;
  innovation-safe deletion accepts on frontier and closure equality. Neither
  acceptance test reads $Q_a$. Each coverage score uses only trailing data
  through the prior year. Compression ratio, module uniqueness, and descendant
  dependence are retrospective structural summaries. Realized coverage,
  $Q_a$, ex post generative contribution, support for the best descendant,
  rank diagnostics, and resampling inputs are held out; greedy-oracle regret
  is an infeasible target-year comparator.
- **Validation result:** frontier-only pruning preserves current validation
  value and reduces ex post enabled-descendant opportunity quality by about
  0.1020; innovation-safe compression preserves frontier, closure, and that ex
  post diagnostic exactly at the registered tolerance. Marginal coverage
  averages 0.0704 realized set coverage versus 0.0119 for the strongest
  comparator, with positive values in three of five years and a coarse
  annual-bootstrap interval of
  [0.0190, 0.1187]. One dominated UNG carrier has zero operational and about
  0.0534 generative value and uniquely supports the best enabled descendant.
- **Publication boundary:** licensed rows remain excluded. Aggregate mechanism
  outputs are publishable and reviewer reproduction uses independently
  licensed CRSP/WRDS files.
- **Scope warning:** the 100-fund universe remains survivorship-biased, the
  snapshot is not revision-timestamped, costs are reduced-form, the annual
  lock is retrospective, and five years give coarse uncertainty. The score's
  candidate-level mean Spearman association is only 0.128 and mean oracle
  regret remains 0.315. This is mechanism evidence, not alpha, ranking
  consistency, or Lean verification.

## Randomness policy

- Use explicit seeds and record the random-number generator.
- Separate exploratory seeds from manuscript seeds.
- Do not select a favorable seed without reporting the selection protocol.
- Prefer deterministic exact enumeration for theorem-sized finite instances.

## Numerical diagnostics

Value-iteration reporting must include, as applicable:

- norm and residual definition;
- stopping tolerance;
- iteration cap and achieved iteration count;
- contraction-based error bound when assumptions justify it;
- sensitivity to tighter tolerances;
- comparison with exact or enumerated small-instance solutions;
- monotonicity or feasibility invariants;
- solver failure and nonconvergence logs.

## Artifact generation

- Figures, tables, and processed data are generated by Julia.
- Generated artifacts must identify their source script/configuration.
- Raw results are immutable inputs to later presentation steps.
- Manual edits to reported figures or tables are prohibited.
- Checksums belong in `ARTIFACT_MANIFEST.md` or a generated manifest it links.

### Main-text table renderer

Five concise displays remain in the main paper and two complete canonical
correspondences appear in Appendix D. `ARTIFACT_MANIFEST.md` records each
public table's source configuration, arithmetic, producer, hash, and release
consumer.

Regenerate the retained and moved data tables with:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/generate_main_text_tables.jl
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/generate_main_text_tables.jl --check
```

The renderer reruns and checks the exact greedy counterexample, validates the
canonical and randomized complete-enumeration gates, verifies exact channel
addition, and checks the financial selected-library certificates and HiGHS
status boundary.  Denominator-one exact rationals are integers, compact exact
fractions remain fractions, and a leading `\approx` is mandatory for rendered
long-denominator means.  The randomized elasticity table requires all 1,024
observations on each arc to be defined, so no undefined main-table elasticity
can be silently imputed as zero.

## Current entry points

### Public-release surface

Run the fast disclosure and packaging gate before preparing a public snapshot:

```sh
make public-audit
```

The command scans the tracked tree for licensed inputs, raw CRSP-like and
row-level financial-observation schemas, credential and private-key signatures,
WRDS/database identities and connection strings, local home paths, email
addresses, notebooks, ignored-but-tracked files, caches, temporary/compiled
products, proprietary or serialized formats, large CSVs, and oversized
binaries. It also checks the licensed-input failure contract, verifies that any
locally present financial inputs remain ignored, and requires both financial
status records to preserve the nonredistributable-input/publishable-aggregate
boundary.

`make public-audit` checks the public reproduction and licensed-data boundary.
The public repository begins from a fresh or squashed snapshot of the audited
release tree; private development refs and local
machine metadata are outside the cleared release surface.

### Top-level release verification

From the repository root, run:

```sh
make verify
```

This is the canonical public reproducibility command.  It delegates to
`scripts/verify.sh` and fails on the first unsatisfied hard gate. Set
`JULIA_EXE` to an absolute Julia 1.12.6 executable when the ignored repository-
local runtime is unavailable.

Stage 1 includes `make public-audit`, so a disclosure-policy regression fails
before formal, computational, or manuscript work begins.

The command runs these stages in dependency order:

| Stage | Gate |
|---:|---|
| 1 | exact Julia, Lean, Lake, mathlib-lock, and LaTeX/BibTeX environment and version checks |
| 2 | `lake clean` followed by the complete Lean library build |
| 3 | prohibited-marker scan, comprehensive 752-declaration `#print axioms` audit, accepted-standard-axiom check, and manuscript Lean linter |
| 4 | Julia root-environment instantiation and complete package test suite |
| 5 | exact Lean--Julia fixture drift, revision gauntlet, resource-optimization witness, and safe-compression reduction fixtures |
| 6 | unified benchmark search, canonical solution, comparative statics, resource benchmark, and elasticity/switching replication |
| 7 | all three randomized-v2 lock checks, the complete registered `N=1024` replay, independent result reconciliation, and the `N=1024` resource-optimization extension |
| 8 | financial design locks, optional licensed-row replays, public aggregate publication/license flags, synthetic exact/MILP regressions, and aggregate hash/certificate verification |
| 9 | every live manuscript figure and table renderer in nonmutating `--check` mode |
| 10 | clean forced manuscript compilation through latexmk, pdfTeX, and BibTeX |
| 11 | remaining registered experiment `--check` gates, whitespace validation, and proof that the verification run did not change worktree state |
| 12 | compiled-log checks plus duplicate/missing BibTeX-key and LaTeX-label/reference checks |

The command may start from a dirty worktree: it snapshots the tracked and
untracked state and requires the same state after every nonmutating artifact
gate.  This preserves unrelated local work while still rejecting a producer
that writes or changes a registered artifact during verification. Julia writes
package logs and precompilation caches to the ignored repository-local
`julia/.julia/` depot, while retaining the caller's existing depots as
read-through sources.

#### Licensed-data boundary

The following two raw-data replays require locally supplied, ignored,
licensed CRSP/WRDS panels and completed provenance records:

| Audit | Required local inputs | Raw-derived registered outputs |
|---|---|---|
| terminal financial audit | `experiments/financial_terminal_audit/data/etf_daily.csv` and `experiments/financial_terminal_audit/data/provenance.toml` | every path in `[outputs]` of `experiments/configs/financial_terminal_audit.toml`: strategy/candidate/pruning, ranking, decomposition, uncertainty, cost, figure-data, report, section, status, and SVG artifacts |
| annual walk-forward financial audit | `experiments/financial_annual_walkforward_audit/data/etf_daily.csv` and `experiments/financial_annual_walkforward_audit/data/provenance.toml` | every path in `[outputs]` of `experiments/configs/financial_annual_walkforward_audit.toml`: universe/grammar/candidate/pruning/annual-selection, ranking, decomposition, uncertainty, cost, figure-data, report, section, status, and SVG artifacts |

Neither licensed panel is redistributed.  When either input pair is absent,
stage 8 reports the exact missing paths, skips only that raw-row replay, and
continues.  It still requires both committed status records to declare
`raw_data_redistribution_permitted=false`,
`aggregate_outputs_publishable=true`, and complete aggregate status.  It then
independently verifies every publishable parent-output SHA-256 recorded in the
status metadata, both financial resource design locks, all downstream
`financial_resource_optimization_*` hashes, exact selected-library
frontier/closure/burden certificates, and small exhaustive-enumeration/MILP
regressions.  Thus a public checkout can pass all distributable gates without
licensed rows; a reviewer who supplies both licensed panels additionally gets
byte-for-byte raw-derived replay checks.

To create either ignored panel from an independently licensed source while
preserving the registered configuration bytes, use the empty public template
and source-root override documented in `DATA_ACCESS.md`:

```sh
ALGOLIB_CRSP_ROOT=data/licensed/crsp julia --project=julia \
  julia/scripts/prepare_financial_terminal_audit_data.jl
ALGOLIB_CRSP_ROOT=data/licensed/crsp julia --project=julia \
  julia/scripts/audit_financial_annual_universe.jl
ALGOLIB_CRSP_ROOT=data/licensed/crsp julia --project=julia \
  julia/scripts/prepare_financial_annual_walkforward_audit_data.jl
```

These commands are licensed-data preparation steps, not part of a
licensed-free public replay. They do not download data and do not substitute
synthetic observations when a required source is missing.

### Lean bootstrap and build

Run from the repository root:

```sh
cd formal
elan toolchain install leanprover/lean4:v4.32.0
lake update
lake exe cache get
lake clean
lake build
lake env lean StrategyInnovation/Audit/RawToCompressed.lean
lake env lean StrategyInnovation/Audit/UnifiedDynamicInnovation.lean
lake env lean StrategyInnovation/Audit/JointDescendantLowerBound.lean
lake env lean StrategyInnovation/Audit/ComparativeStatics.lean
lake env lean StrategyInnovation/Audit/DiscountSurvivalInteraction.lean
lake env lean StrategyInnovation/Audit/KernelComparativeStatics.lean
lake env lean StrategyInnovation/Audit/SystemInteraction.lean
lake env lean StrategyInnovation/Audit/AxiomAudit.lean
```

`lake update` must leave the committed `lake-manifest.json` unchanged. The
mathlib cache command is an acceleration only. The clean build is the source
verification gate; the focused T1, UDI, CS1, S6, S7, and T7 audits print the
dependencies of their main declarations, and the comprehensive audit covers
every ledger-facing declaration.

### Julia bootstrap and test

Install/select Julia 1.12.6. With Juliaup:

```sh
juliaup add 1.12.6
juliaup default 1.12.6
julia --version
julia --project=julia -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

The version line must say `julia version 1.12.6`. Use that executable directly
or set `JULIA_EXE` to its absolute path. The audited local runtime lived under
the ignored `.local_runtime/` directory and is not distributed; a fresh
checkout must install or select Julia 1.12.6. No project executable is run
from a system temporary directory.

The reusable final-model checks can also be run alone:

```sh
julia --project=julia/test -e \
  'using Test, StrategyInnovation; include("julia/test/test_raw_dynamic_programming.jl")'
```

These exact checks compare raw and compressed local updates, embedded
transition laws, finite-horizon values and policies, stationary Bellman steps,
fixed-point values and policies, dynamic-equivalence classes, and the
correlated T1 and stationary S2 Lean fixtures.

### Exact fixture regeneration

```sh
julia --project=julia julia/scripts/export_exact_fixtures.jl
julia --project=julia julia/scripts/export_exact_fixtures.jl --check
```

The first command writes the deterministic JSON/Lean pair. The second is a
non-mutating byte-for-byte check. CI intentionally runs the writing command
and then `git diff --exit-code` on the two generated destinations.

### Manuscript build

```sh
./manuscript/build.sh
```

The script requires latexmk, pdfTeX, BibTeX, and ripgrep. It rejects broken
citations, references, and missing files after latexmk finishes.

### Full local gate

```sh
make verify
```

The Lean build validates all registered formal modules, including the derived
T1 raw-to-compressed projection, and the generated fixture calculations;
fixture examples establish only fixture agreement, not a general theorem.
The Julia test validates package loading, deterministic streams, Aqua, the
reusable raw-derived transition/Bellman equivalences, exact boundary
witnesses, controlled theorem mechanisms, financial aggregate certificates,
and the registered finite search audits.  The complete ordered gate adds the
clean build, executable axiom whitelist, registered `N=1024` replays,
canonical-resource replication, live presentation-artifact checks, worktree
drift guard, and final bibliography/reference reconciliation described above.

## CI action pins

The workflow uses full commits rather than floating tags:

| Action | Release label | Commit |
|---|---|---|
| `actions/checkout` | v7 | `3d3c42e5aac5ba805825da76410c181273ba90b1` |
| `actions/cache` | v5 | `caa296126883cff596d87d8935842f9db880ef25` |
| `actions/upload-artifact` | v7 | `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a` |
| `leanprover/lean-action` | v1 | `38fbc41a8c28c4cbaec22d7f7de508ec2e7c0dd9` |
| `julia-actions/setup-julia` | v3 | `fa02766e078afaaf09b14210362cee14137e6a32` |
| `julia-actions/cache` | v3 | `a45e8fa8be21c18a06b7177052533149e61e9b38` |

Lean cache compatibility is keyed by operating system, architecture, the
nested Lean toolchain file, and the exact Lake manifest. Julia's cache key
includes both Julia manifests; failed jobs do not save cache state and the
workflow does not request cache-deletion permission.
