# Annals of Operations Research baseline audit

Audit date: 2026-08-26

Branch: `journal/aor-v0.2.0`

Audited HEAD before these documents: `cdf70454f43453bd244514c534a850281ebdba79`

Immutable pre-journal baseline: `1f414769459e314e594a8a2b9b679996b04597ba`

## Executive finding

The repository already supports a defensible journal article about exact
frontier--closure compression, its local/global optimization boundary, a
human-readable complexity result, exact finite oracles, independently
rechecked mixed-integer candidates, registered synthetic evidence, and two
retrospective financial comparisons. The strongest existing algorithmic
assets are the exact safe-feasibility predicates, complete small-instance
enumeration, a general-closure JuMP/HiGHS formulation with exact post-solve
certification, and the identity-closure set-cover correspondence.

The proposed journal program is not yet a completed new algorithmic
contribution. In particular, there is no Lean theorem for tagged-cover
equivalence, no parametric worst-case local/global gap family, no proved
preprocessing system, no exact dynamic program for the full safe-compression
problem, and no approximation-guaranteed greedy method. A deterministic MILP
scaling probe and older Float64 pruning diagnostics exist, but there is no
separately registered `experiments/algorithmic_compression_v1/` study. The
financial artifacts already compare stepwise safe pruning, frontier-only
pruning, and HiGHS candidates, but they do not compare the absent preprocessing,
dynamic-programming, or approximation-guaranteed algorithms.

The complexity contribution is stronger than “absent” but weaker than formal
verification: `SC-COMP` has a complete human polynomial reduction in the AOR
draft and exact Julia correspondence fixtures, while the theorem ledger
explicitly records no Lean declaration (`THEOREM_LEDGER.md:339-390`).

## Evidence classes used in this audit

This document preserves the repository's evidence hierarchy
(`README.md:39-51`; `REPRODUCIBILITY.md:16-27`):

- **Human-readable proof:** the mathematical argument printed in TeX or the
  theorem ledger.
- **Lean kernel verification:** only a declaration selected in
  `THEOREM_LEDGER.md`, built with Lean 4.32.0, and covered by the axiom audit.
- **Exact finite computation:** deterministic `Rational{BigInt}` evaluation or
  exhaustive enumeration on the stated finite inputs; not a universal proof.
- **Floating-point numerical evidence:** tolerance-qualified diagnostics or
  timings; not exact arithmetic.
- **Mixed-integer solver evidence:** a solver-returned candidate and status,
  kept distinct from exact feasibility and exhaustive optimality.
- **Synthetic experimental evidence:** conclusions conditional on the frozen
  generator and registry.
- **Retrospective financial evidence:** licensed-data mechanism diagnostics,
  with no causal, prospective, forecasting, alpha, or deployable-performance
  claim.

## Inspection scope

The audit inspected the requested top-level records, both verification scripts,
the active main-paper and supplement source graphs, all manuscript section and
appendix outlines, the bibliography, the Julia project/source/test/script
surfaces, all experiment configuration names, the randomized-v2 locks and
registry schema, the public result inventory, the three financial protocol
directories, the tracked Lean source tree, and the complete tracked
`release/v0.1.1-arxiv/` inventory. No ignored licensed data file was opened.

The active manuscript source graphs are explicit in `manuscript/main.tex:91-126`
and `manuscript/online_supplement/main.tex:81-88`. The latter compiles S1--S7.
The repository-only files `literature_novelty_audit.tex`,
`lean_correspondence.tex`, `validation_matrix.tex`, and `passive_gap_sum.tex`
are indexed as constituent records but intentionally are not compiled into the
standalone supplement (`manuscript/online_supplement/README.md:26-57`). This is
not presently a source-graph error, but journal packaging must say which items
are actually submitted.

## Contribution status

| Proposed contribution | Baseline status | Defensible evidence | Missing before a stronger claim |
|---|---|---|---|
| Tagged-cover equivalence as a formal theorem | **Partial, not formally verified.** Identity closure is described as weighted hitting set on separately labeled belief-attainer and module-carrier obligations. `IdentitySafeCover` constructs these obligations. | Human SC-COMP proof; exact Julia reduction/correspondence checks in `SafeCompressionComplexity.jl`; journal prose at `journal/aor/sections/05_innovation_safe_compression.tex:184-244`. | A precise theorem statement, proof, theorem-ledger selection, Lean encoding, axiom audit, and tests against collisions between belief and module tags. Do not generalize it to arbitrary closure. |
| Complexity result | **Substantially present.** | Human NP-completeness/NP-hardness proof; polynomial-size constructors; exact registered fixture; 6,360 small-incidence correspondences. | No Lean complexity encoding or reduction framework. The current defensible status is human proof plus exact finite validation, not Lean verification. |
| Worst-case local/global gap family | **Absent.** | Fixed cardinality and `(2,2,3)` weighted counterexamples exist in Julia and Lean. | A parameterized family, a proved gap formula, exact fixtures for multiple parameter values, and a statement specifying additive versus multiplicative gap. |
| Preprocessing theory | **Absent.** | The MILP builds attainer and carrier rows; scripts use sparse identity incidence. | Sound reduction rules, proofs that the optimum/tie set is preserved, deterministic reconstruction, and exhaustive small-instance regression. |
| Exact bitmask dynamic programming | **Partial components only.** | Full subset enumeration exists; `operational_ip_cardinality_lower_bound` is a bitmask DP for the operational-cover relaxation. | A DP solving the full tagged frontier-plus-closure objective, weight/cardinality support, tie policy, reconstruction, state-cap failures, and comparison with independent enumeration. |
| Approximation-guaranteed greedy construction | **Absent.** | Four deterministic backward-deletion scores, multistart, Pareto beam search, and a fixed exact counterexample to strict-heaviest-first optimality exist. | A true theorem under explicit structural assumptions. The generic exact problem currently has no claimed ratio, and existing counterexamples prohibit an unsupported optimality claim. |
| Algorithmic scaling study | **Prototype only.** | Registered Float64 fixed-point-pruning diagnostics at sizes 16--128; an unregistered deterministic safe-compression MILP probe with exact postchecks; tiny solver-scaling regression tests. | A new directory, registry, seed policy, design lock, result schema, hardware/runtime fields, time-limit/censoring rules, independent certificate checks, and an explicit authorization before the long run. |
| Financial algorithm comparison | **Existing comparison, proposed extension absent.** | The two locked audits compare stepwise safe, frontier-only, HiGHS minimum-cardinality, and HiGHS minimum-weight candidates with exact frontier/closure/burden postchecks. | No comparison to the absent DP, preprocessing, or guaranteed greedy algorithms. Any extension needs a new lock and must keep held-out quantities out of pruning, weighting, algorithm choice, and optimization. |

## Reusable scientific foundation

The detailed symbol map is in `IMPLEMENTATION_MAP.md`. At a high level:

- `julia/src/{Types,Profiles,Libraries}.jl` supplies exact identifiers,
  strategies, operating profiles, modules, closure, frontier, and compressed
  state.
- `julia/src/Compression.jl` supplies local deletion, fixed-point pruning,
  complete small-instance enumeration, a solver-neutral binary formulation,
  and exact equivalence verification.
- `julia/src/SafeCompressionSolver.jl` supplies JuMP/HiGHS construction and an
  independent exact certification layer. It fixes the inactive variable to one
  and rechecks source inclusion, frontier, general closure, exact burden, and
  exact scaled objective (`SafeCompressionSolver.jl:183-249,289-363`).
- `julia/src/ResourceOptimization.jl` supplies a second, identity-closure,
  bitmask-oriented exact finite optimizer and pruning trace.
- `julia/src/SafeCompressionComplexity.jl` supplies set-cover decision types,
  three weight-preserving reductions, tagged identity obligations, and exact
  correspondence checks.
- `julia/src/ApproximateCompression.jl` supplies exact loss evaluation,
  complete subset/Pareto enumeration, deterministic heuristics, and an
  operational-cover DP lower bound, while explicitly disclaiming a heuristic
  approximation guarantee (`ApproximateCompression.jl:14-20`).

## Manuscript, ledger, code, and artifact reconciliation

### Aligned boundaries

1. The main paper defines exact compression as source inclusion plus exact
   frontier and closure equality (`manuscript/sections/03_model.tex:190-221`).
   Julia and Lean use the same productive compressed state.
2. Lean proves finite minimum attainment, safe-deletion preservation,
   productive value/action preservation, and fixed local/global counterexamples
   in `formal/StrategyInnovation/Optimization/{SafeCompression,
   SafeCompressionCounterexample}.lean`. These declarations are explicitly
   axiom-audited.
3. Solver `OPTIMAL` is kept separate from exhaustive or formal proof in code,
   tests, financial prose, and the financial status artifact. The main paper's
   table caption states the distinction at
   `manuscript/sections/10_financial_compression_audit.tex:27-31`.
4. Held-out financial opportunity quality is ex post only and cannot define
   weights (`experiments/configs/financial_resource_optimization.toml:60-63`).
5. The frozen randomized study is described as generator-conditional exact
   synthetic evidence, not theorem or population evidence.

### Mismatches and gaps

1. **Artifact-manifest hash drift.** A read-only SHA-256 comparison found 25
   standard Artifact-ID rows whose recorded hash does not equal the current
   file at the recorded path. The affected IDs are:

   `LJB-SCHEMA-v1`, `LJB-CODE-v1`, `LJB-TEST-v1`, `LJB-LEAN-v1`,
   `LJB-CURRENT-FUTURE-v1`, `LJB-FRONTIER-LOSS-v1`, `LJB-MULTIGAP-v1`,
   `LJB-DECOMPOSITION-v1`, `LJB-SAFE-DELETE-v1`, `LJB-SINGLE-GAP-v1`,
   `LJB-INNOVATION-EQUATION-v1`, `UCS-CORE-v1`, `TF-CODE-v1`,
   `TF-LEAN-DATA-v1`, `CMP-CORE-v1`, `CMP-TEST-v1`, `RO-CORE-v1`,
   `RO-TEST-v1`, `DP-CORE-v1`, `UB-CANONICAL-TEST-v1`, `SVE-CODE-v1`,
   `SVE-TEST-v1`, `SVE-FIG-v1`, `MG-CODE-v1`, and `MG-LEAN-DATA-v1`.

   This does not show that the current computations are wrong; several
   producer-specific `--check` gates still pass. It does show that
   `ARTIFACT_MANIFEST.md:18-21` is not currently a reliable hash index for all
   mutable paths. Historical identifiers should point to immutable versioned
   copies, or the current IDs/hashes must be revised with an explicit lineage
   decision. Do not rewrite the frozen release to conceal this drift.
2. **Public-audit incompatibility on the journal branch.** The lightweight
   public audit fails because the existing `journal/aor/cover_letter.md`,
   `main.tex`, and `supplement.tex` contain email addresses requiring
   publication review. This is a packaging/governance blocker, not a
   mathematical failure.
3. **Known preprint-check incompatibility.** The journal revision ledger records
   that `make preprint-check` regenerates the historical arXiv bundle from the
   mutable bibliography and therefore fails against the frozen bundle
   (`journal/aor/REVISION_LEDGER.md:24-31`). This audit did not rerun that broader
   gate.
4. **Complexity location is journal-only.** The preprint compression section
   has no SC-COMP theorem; the theorem is in the journal-specific section and
   controlled ledger. This is intentional version divergence but must remain
   visible in release metadata.
5. **Package/API split.** `ResourceOptimization.jl` and
   `SafeCompressionComplexity.jl` are standalone modules included by scripts,
   not by `StrategyInnovation.jl`. Their tests run through special verification
   stages rather than ordinary package export. Reuse is possible, but journal
   algorithm work should first choose one canonical data model rather than
   silently maintain two semantics.
6. **Version metadata.** Both the Julia package and Lean project remain version
   `0.1.0`, while the working branch is `journal/aor-v0.2.0`. This is not a
   scientific contradiction, but submission/release packaging needs an
   explicit versioning decision.
7. **Scaling evidence is not one coherent study.** The committed
   `compression_experiments` rows are Float64 fixed-point-pruning diagnostics;
   `run_safe_compression_scaling.jl` is a deterministic MILP probe that only
   prints rows and disables exhaustive optimality checking. Neither is the
   proposed registered multi-algorithm study.
8. **Numerical lineage gate remains incomplete for a journal release.** The
   active source-reference audit passes, and selected artifact `--check` gates
   pass, but this audit did not trace every manuscript scalar to a committed
   result. That belongs at a declared manuscript gate after new artifacts are
   locked.

## Frozen and immutable surface

The following must not be edited by the journal implementation program:

- the entire `release/v0.1.1-arxiv/` tree, including both PDFs, the source
  archive, and bundled sources;
- any current preprint PDF treated as a historical artifact;
- `RANDOMIZED_DESIGN_V2.md`, its amendments, the randomized-v2 configuration,
  all three design/amendment locks, the trial/seed registry, the optimization
  extension lock, and all committed `randomized_library_v2_*` results and
  reports;
- the terminal, annual walk-forward, and financial-resource design locks and
  amendments, their parent decision hashes, and their committed results;
- registered exact, approximate, canonical, and counterexample result files
  when used as baseline evidence; new outcomes require new IDs and paths;
- all ignored CRSP/WRDS source rows, row derivatives, completed provenance, and
  extraction audits, which remain outside the distributable repository.

The three frozen release hashes match `RELEASE_METADATA.md`, and
`git diff 1f414769... -- release/v0.1.1-arxiv/` is empty. The raw-data boundary
is stated in `DATA_ACCESS.md:1-18,83-98` and was respected by this audit.

Any new algorithmic study must live under
`experiments/algorithmic_compression_v1/` with a new configuration, registry,
seeds, design lock, and result prefixes. It must not reuse the randomized-v2
registry as a mutable study substrate.

## Lightweight checks run

| Check | Result |
|---|---|
| Branch/status and baseline release diff | Correct branch; only the pre-existing untracked `instability_specialists/`; frozen release diff empty. |
| Release PDF/archive SHA-256 | All three match `RELEASE_METADATA.md`. |
| `scripts/check_manuscript_sources.sh` | Passed: main 138 labels/48 references; supplement 76 labels/16 references; bibliography 49 entries/28 cited keys. |
| Shell syntax for verification and journal scripts | Passed. |
| `scripts/audit_public_repository.sh` | Failed only on publication-review email policy in three existing journal files. |
| SC-COMP exact tests under repository-local Julia 1.12.6 | Passed 25/25, 2,387/2,387, and 5/5 tests; the 2,387 assertions include 6,360 reduction/mask correspondences. |
| SC-COMP registered fixture `--check` | Passed; fixture SHA-256 `e9b9dd98...b050`. |
| Core/compression/solver targeted tests under Julia 1.12.6 | Passed all displayed test sets, including 1,376 seeded properties, 110 MILP-versus-enumeration assertions, and the tiny scaling probe. |
| Approximate-compression artifact `--check` | Passed. |
| Financial resource unit/regression tests without licensed rows | Passed 25/25 assertions, including exact post-solve and exhaustive small-instance comparisons. |
| Artifact-manifest SHA audit | Found the 25 standard-row mismatches listed above. |

One attempted targeted test invoked the system `julia` and stopped during
precompilation because that executable is Julia 1.11 and could not write its
home-depot pidfile in the sandbox. No test result is attributed to that
attempt. All reported Julia passes used the repository-local Julia 1.12.6
binary and the pinned project.

The full verification suite, N=1024 replay, long solver scaling run, manuscript
compilation, and licensed workflows were not run.

## Baseline conclusion

The smallest defensible journal package is already close: retain the exact
frontier--closure theory, add the existing human SC-COMP theorem with its exact
finite correspondence evidence, present the exact post-solve certification
layer, and reuse the already locked synthetic and financial comparisons without
new outcome mining. Its immediate blockers are provenance reconciliation,
submission packaging, and careful status language—not a need to invent a new
theorem or benchmark result.

The stronger preferred package is an exact algorithmic contribution built in
dependency order: precise identity-closure tagged-cover equivalence, proved
preprocessing rules, a full exact bitmask DP oracle, hardened MILP comparison,
and a separately locked synthetic scaling study followed by a governance-safe
financial algorithm comparison. A greedy approximation guarantee belongs only
if a correct theorem under explicit assumptions is proved; otherwise the
counterexample boundary and heuristic evidence must remain the result.
