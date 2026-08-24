# Julia Scripts

`search_counterexamples.jl` is the exact-arithmetic adversarial feasibility
audit for manuscript Theorems T1--T6. It combines finite exhaustive searches,
seeded randomized searches over the locked model bounds, independently checked
boundary witnesses, deterministic JSON export, and generation of a data-only
Lean fixture.

Run it from the repository root with the locked Julia version:

```sh
julia --project=julia julia/scripts/search_counterexamples.jl
```

The committed output is
`experiments/results/theorem_feasibility.json`. The default seed is encoded in
the script and recorded in the result.

`search_revision_counterexamples.jl` is the separate exact falsification
oracle for the unified semi-Markov T1--T7 package. It preserves the legacy
experiment, evolves belief through positive calendar durations, supports
active and suspending operation plus non-product completion couplings, and
checks the reduced persistence, information, delay, T6-cost, and T7-
complementarity fixtures. It also runs the exact
`FX-S2-UNIFIED-STATIONARY-01` compressed policy evaluation under the same
positive-duration timing and requires both its policy and Bellman residuals to
be zero. Run:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/search_revision_counterexamples.jl
```

The committed output is
`experiments/results/revision_counterexample_gauntlet.json`; `--check` performs
a non-mutating drift check. It writes no Lean source.

`search_resource_optimization_counterexamples.jl` exhaustively attacks the 14
resource-optimization claims on minimized finite exact-rational domains. It
enumerates safe sublibraries and deletion traces, capacity and penalty
optimizers, exact breakpoints and support intervals, replacement feasibility,
and elasticity boundary families:

```sh
julia --project=julia \
  julia/scripts/search_resource_optimization_counterexamples.jl
julia --project=julia \
  julia/scripts/search_resource_optimization_counterexamples.jl --check
```

It writes one complete audit plus 14 per-target JSON fixtures. The result is
13 counterexamples and the surviving penalized-burden antitonicity claim. It
does not write Lean source or confer theorem status.

`run_safe_compression_scaling.jl` builds deterministic exact-rational set-cover
instances with increasing strategy and belief counts, solves them with the
JuMP/HiGHS safe-compression adapter, and prints variables, constraints,
selected cardinality, solver time, end-to-end time, node count, and exact
post-solve safety. Exhaustive enumeration is deliberately disabled, so the
output keeps HiGHS's optimality status separate from the exact library
certificate:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_safe_compression_scaling.jl
```

`search_unified_benchmark.jl` performs the deterministic exact-rational search
for the versioned positive-duration canonical benchmark. It enumerates 972
small-grid calibrations, requires Continue, Discover, and capability-gated
Scale in the stationary policy, rejects action gaps below `1//16`, tests local
rational perturbations and five comparative-static axes, and ranks the
survivors by worst action separation with denominator simplicity and distance
from the frozen specification as tie-breakers. The selected candidate then
passes exact value iteration, raw and compressed policy iteration, full
`P^duration` path-marginal checks, raw/compressed value equality, and policy
lift:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/search_unified_benchmark.jl
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/search_unified_benchmark.jl --check
```

The producer writes the search table and exact diagnostic artifacts registered
by `experiments/configs/unified_benchmark_search.toml`. It does not read,
modify, or replace the legacy `canonical_discounted_dp.toml` fixture.

`run_unified_comparative_statics.jl` is the final-model exact/sparse
comparative-statics runner. Exact mode constructs the public raw process and
reproduces selected T4/S2/T6/S6/S7/T7 fixtures. Sparse Float64 mode evaluates
all twelve configured primitive axes, a frontier--closure grid, Bellman
residual/error gates, policy/cutoff diagnostics, theorem-tagged sign checks,
and explicit counterexample flags. It writes four CSV files, one JSON summary,
and two data-linked SVG figures:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_unified_comparative_statics.jl
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_unified_comparative_statics.jl --check
```

`run_randomized_library_stress.jl` generates the registered 90-trial
finite-library robustness suite from the raw model. Every trial uses exact
rational arithmetic and records complete profiles, modules, closure tables,
kernels, projects, seeds, and deletion order. It compares frontier-only,
innovation-safe, passive-loss-budget, and option-premium-loss-budget pruning,
then writes all source CSVs, derived summaries, the standalone technical
report, and three publication SVGs:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_randomized_library_stress.jl
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_randomized_library_stress.jl --check
```

The frequencies are robustness/economic-relevance diagnostics under the
registered generator. They are never theorem evidence.

`lock_randomized_library_design_v2.jl` is the outcome-blind registration
utility for the successor stress test. It materializes the complete
1,024-trial factorial assignment and all 4,096 component seeds, verifies
factor and prefix balance plus frozen-pilot hashes, rejects output-path
collisions, and freezes or checks the aggregate design hash:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/lock_randomized_library_design_v2.jl --write-registry
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/lock_randomized_library_design_v2.jl --freeze
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/lock_randomized_library_design_v2.jl --check
```

The initial lock already exists, so normal use is `--check`; `--freeze`
refuses to overwrite it. The script does not instantiate a trial library or
compute an outcome.

`lock_randomized_library_stability_amendment.jl` verifies the prospective
sequential-precision amendment against the current parent lock. It fixes the
requested cumulative snapshots plus $N=1024$, exact cumulative and
factor-stratified estimands, descriptive interval and MCSE conventions,
sparse-support warnings, and output paths. It also verifies that no v2 outcome
artifact existed when freezing:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/lock_randomized_library_stability_amendment.jl --check
```

The amendment lock already exists and cannot be overwritten. The associated
`RandomizedStability.jl` package component renders cumulative and factor CSV
content plus a four-panel SVG from exact outcome rows once the registered run
is executed; the lock utility itself computes no outcome.

`lock_randomized_library_execution_amendment.jl` verifies the final
prospective executable-protocol amendment against both current parent locks.
The amendment freezes the v2-specific state-generation boundary, raw generator
and audit implementation, exact runner, focused fixtures, abort contract, and
the two additional source-table paths:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/lock_randomized_library_execution_amendment.jl --check
```

`run_randomized_library_stress_v2.jl` executes all 1,024 registered trials,
derives every corner, closure, menu, transition, value, pruning comparison,
theorem-condition flag, and interaction from raw primitives, and writes the
complete exact evidence bundle only after every hard gate passes. `--check`
reruns the complete fixed design and byte-compares all 24 artifacts:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_randomized_library_stress_v2.jl
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_randomized_library_stress_v2.jl --check
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/audit_randomized_library_v2_results.jl
```

The last command is an independent result-reader audit: it reconciles row
counts, factor balance, exact losses and interaction signs, innovation-safe
zero components, raw witnesses, final stability counts, summary fields, and
the frozen-pilot hashes without regenerating outcomes.

`run_approximate_compression.jl` reconstructs the registered exact raw-library
fixture and evaluates both its six-strategy source and an eight-strategy
expanded source. It computes every sublibrary, the exact
`(size, OpLoss, GenLoss)` Pareto frontier, four greedy deletion scores,
multistart and Pareto-beam searches, and the operational set-cover/lazy-cut
0--1 summaries. It writes four source-complete CSVs, one JSON summary, the
standalone technical report, and two publication SVGs:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_approximate_compression.jl
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_approximate_compression.jl --check
```

All model calculations use exact rationals. Negative generative loss is
preserved, and heuristic rows never receive an optimality certificate unless
the Pareto beam happens to visit the complete subset space. The experiment is
numerical only.

`run_system_interaction_surface.jl` preserves the registered 2,430-row T7
boundary grid and adds five exact four-corner fixtures plus a 3,456-row
response surface. The expanded surface varies frontier pairs, closure
richness, project cost, admission, descendant payoff, incumbent reward,
duration, and generator-quality frontier dependence:

```sh
julia --project=julia julia/scripts/run_system_interaction_surface.jl
julia --project=julia julia/scripts/run_system_interaction_surface.jl --check
```

The committed CSVs and JSON summary are under
`experiments/results/summaries/`. Every row reports both closure increments,
$J$, selected projects at all four corners, corner realizability, and the
primitive-condition certificate. Aggregate sign counts use only the 576
rectangles with four realizable corners; 2,880 diagnostic nonrealizable
rectangles are explicitly excluded. The surface is validation and boundary
evidence; T7's general corrected substitution theorem is proved separately in
Lean.

`search_single_gap_geometry.jl` exhaustively searches exact three-point grids
for failures of single-peaked coverage geometry. It emits the compact result
`experiments/results/single_gap_geometry.json` and the data-only Lean fixture
`formal/StrategyInnovation/Fixtures/SingleGapGeometry.lean`.

`solve_unified_canonical_benchmark.jl` is the main canonical-model producer.
It starts from the selected raw strategy catalog, all eight raw libraries,
module closure, candidate generation, verification, full belief-path/admission
couplings, and deterministic insertion updates. It derives all compressed
states and embedded transitions, solves exact finite-horizon recursion, raw
and compressed rational policy iteration, exact stationary policy evaluation,
and Float64 value iteration, and writes the registered value, policy,
transition, path, reward-block, convergence, and comparative-static artifacts:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/solve_unified_canonical_benchmark.jl
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/solve_unified_canonical_benchmark.jl --check
```

`run_unified_resource_benchmark.jl` adds the preregistered exact resource
layer to that canonical benchmark. It evaluates all eight raw libraries under
equal-active, carrier-heavy, and descendant-heavy weights; exhausts every
safe-compression, attainable-capacity, and penalized-price problem; separates
candidate from globally active switching prices; and computes exact passive
operational/generative values, fixed-policy discount derivatives, innovation
duration, channel elasticities, action-tie distances, and library-breakpoint
distances. It writes exact CSV/JSON/TeX tables and secondary SVG renderings:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_unified_resource_benchmark.jl
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_unified_resource_benchmark.jl --check
```

The inactive-policy weight is included in every reported total burden. The
underlying small-library optimizer keeps it implicit, so the runner translates
capacity and penalty objectives exactly and rechecks the translated objective
against direct enumeration.

`solve_canonical_model.jl` is the deprecated primitive F5/F8 compatibility
runner. It retains the obsolete `beta^(delay+1)` process, exact regression
fixtures, and historical outputs for appendix comparison only. It is never an
input to the main canonical-model manuscript artifacts:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/solve_canonical_model.jl
```

`run_coverage_geometry.jl` exercises the reusable coverage API. It reproduces
the Lean S4/S5/C2 fixtures in exact rational arithmetic, solves a deterministic
121-state Float64 coverage model, evaluates six sensitivity axes, writes one
JSON summary and six CSV data tables, and generates five publication SVGs:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_coverage_geometry.jl
```

All figure data are under `experiments/results/summaries/`; generated SVGs are
under `manuscript/figures/`. The script uses no global RNG state or plotting
dependency.

`run_theorem_mechanism_experiments.jl` executes the preregistered A--G
controlled suite. A--F use exact `Rational{BigInt}` identities; the preserved
G fixture contains twelve seeded Float64 policy maps on 61 beliefs. G is now
an Appendix-D regression fixture rather than an active manuscript policy-map
or response-surface input. The script writes raw observations,
summary and figure-data tables, checksummed metadata,
`experiments/results/SYNTHETIC_REPORT.md`, and five publication SVGs. Family F
includes a prospective fixed-candidate ranking fixture with an independent
date-first value calculation, exact comparator ranks, bounded-error and stress
regimes, and redundancy-aware set selection. Any
expected identity or comparative-static failure aborts the run.

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_theorem_mechanism_experiments.jl
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_theorem_mechanism_experiments.jl --check
```

The second command regenerates into transient storage and byte-compares every
tracked artifact. Raw data remain ignored but are regenerated and checked by
their committed SHA-256 metadata.

`generate_dynamic_policy_figure.jl` renders the active Section 7 compact
policy map from `unified_comparative_statics_surface.csv`. It selects nine
cost/duration/discount slices and rejects any row that is not raw-derived,
strictly positive-duration, sparse Float64, converged, and within the
registered numerical gates:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/generate_dynamic_policy_figure.jl --check
```

`generate_figure_audit_artifacts.jl` renders the two exact-source main-text
figures owned by the figure audit: the bridge mechanism and the combined
capacity/envelope/selected-burden geometry. It validates the five bridge rows,
parses source values as `Rational{BigInt}`, and rejects incomplete optimizer or
tie correspondences. The geometry uses stairs and explicit open/filled
endpoints so its discrete objects are not presented as smooth curves:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/generate_figure_audit_artifacts.jl
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/generate_figure_audit_artifacts.jl --check
```

`generate_main_text_tables.jl` owns the five retained main-text tables and the
two canonical resource tables moved to Appendix D.  It recomputes the exact
greedy counterexample, parses the committed canonical, randomized, and
financial CSVs, checks complete-enumeration and post-solve certificates, and
renders compact TeX.  Exact fractions remain fractions; long-denominator
across-trial means are marked with `\approx`; HiGHS results remain solver-
qualified; and undefined elasticities are rejected rather than averaged as
zero:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/generate_main_text_tables.jl
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/generate_main_text_tables.jl --check
```

`prepare_financial_terminal_audit_data.jl` performs the licensed local CRSP
extraction declared in `experiments/configs/financial_terminal_audit.toml`. It
validates point-in-time ETF/PERMNO links, streams the three compressed daily
files, writes a nonredistributable ignored ETF panel, and records source and
derived checksums. It performs no download. The frozen configuration permits
reviewer reproduction from CRSP/WRDS alone; ORATS is optional and, when
available, re-audits the original covered-instrument inventory. In a public
clone, place the documented inputs beneath `data/licensed/crsp` and set
`ALGOLIB_CRSP_ROOT=data/licensed/crsp`. Missing licensed inputs fail with the
public boundary message in `DATA_ACCESS.md`; no synthetic substitute is used.

`run_financial_terminal_audit.jl` enumerates the 2,400-strategy grammar over the
25-ETF universe, freezes all pruning and rankings on development/validation
data, forms a decision hash, and only then scores the locked illustration. It writes every
candidate and pruning decision, aggregate mechanism/ranking/decomposition/cost
tables, deterministic block-bootstrap uncertainty, a draft results section,
limitations, and three SVG figures. Expected safe-compression identities are
hard failures.

```sh
ALGOLIB_CRSP_ROOT=data/licensed/crsp julia --project=julia \
  julia/scripts/prepare_financial_terminal_audit_data.jl
julia --project=julia julia/scripts/run_financial_terminal_audit.jl
julia --project=julia julia/scripts/run_financial_terminal_audit.jl --check
```

The aggregate financial outputs are publication artifacts under D-0041. The
point-in-time boundary remains a scientific limitation, and licensed raw or
row-level inputs remain excluded.
