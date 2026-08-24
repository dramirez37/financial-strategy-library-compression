# Julia Environment

`StrategyInnovation` is a standard Julia package pinned for Julia 1.12.6.
The root project/manifest records the runtime environment; the separate
`test/Project.toml` and `test/Manifest.toml` pin quality-gate dependencies.

## Dependency policy

Only two non-stdlib packages are currently justified across runtime and test
environments:

- `StableRNGs` is a runtime dependency used to make seeded simulation streams
  stable across Julia versions.
- `Aqua` is a quality-gate dependency used only by `test/runtests.jl` and
  pinned in the test manifest.

`LinearAlgebra`, `SparseArrays`, `TOML`, `SHA`, and `Random` are declared Julia
standard-library runtime dependencies for exact policy evaluation, sparse
Float64 transitions, committed experiment configuration, checksummed metadata,
and deterministic factor shuffling.
DataFrames, CSV, JSON3, StaticArrays, Distributions, Optim, JuMP, Documenter,
and other packages remain unselected until an implemented feature requires
them.

## Raw finite model

The reusable package implements the Lean-aligned finite catalog and raw model
in `src/{Types,Beliefs,Profiles,Libraries,RawDynamicProgramming,IO}.jl`:

- typed finite belief, strategy, module, and project identifiers;
- exact finite `RatProb` distributions and row-stochastic belief kernels;
- validated strategy catalogs, inactive-containing raw libraries, operational
  frontiers, module unions, generative closures, and compressed states;
- exact candidate generation, verification/admission, and the derived
  admitted-candidate law;
- raw insertion, local compressed updates, and induced compressed laws;
- validated joint belief-path/admitted-outcome completion couplings;
- positive project durations, operating/suspending timing, initiation costs,
  and raw-derived embedded transitions; and
- raw/compressed finite-horizon and stationary Bellman operators, policies,
  and exact dynamic-equivalence checks.

`src/RealizableRectangles.jl` adds a raw-first four-corner constructor for T7
validation. It inserts a frontier-only strategy and a module-only or
frontier-silent carrier into one base raw library, recomputes every compressed
image, and derives corner menus, transition laws, finite-horizon values, and
policies through `RawInnovationProcess`. Two deterministic
`Rational{BigInt}` fixtures cover identity and nontrivial generated closure.
The implementation and consistency gate are in
`src/RealizableRectangles.jl` and `test/test_realizable_rectangles.jl`.

`Rational{BigInt}` is the default for all theorem fixtures. A caller must pass
`mode = Float64Mode()` explicitly to construct simulation-mode profiles or
belief kernels. The package intentionally provides no Float64 dynamic-
equivalence method.

The primitive F1 constructor `FiniteResearchSemantics` and F5/F8 constructor
`DiscountedResearchProcess` are deprecated compatibility APIs. Their
constructors emit migration warnings, while their old tests and artifacts
remain reproducible.

## Unified comparative statics

`src/ComparativeStatics.jl` provides the final-model comparative-statics
engine. One validated parameter record covers frontier level/density, closure
richness, module overlap, research cost/duration, admission, survival,
discounting, belief persistence, signal precision, candidate quality, and
frontier-dependent generation. Its result record reports total/passive value,
the research-option premium, operational/generative insertion value, policy
frequency/action/cutoff diagnostics, pruning loss, safe-compression ratio,
descendant quality, the finite frontier--closure interaction $J$, and
Bellman diagnostics.

Exact runs build `RawInnovationProcess` objects and use exact raw policy
iteration. Larger response surfaces compile the same catalog, generation,
verification/admission, insertion-only update, and elapsed-time reward block
to sparse Float64 matrices. Residual and posterior-error gates are mandatory.
The sign checker tags every comparison with its Lean theorem family and marks
the result inapplicable when the proof-critical assumptions are absent.
Persistence, active-operation delay, the Bellman cutoff, and T7 without
relative action saturation are explicit boundary flags rather than universal
sign claims.

## Randomized finite-library robustness

`src/RandomizedLibraries.jl` constructs deterministic exact raw-library
stress trials. Its factor design is marginally balanced and StableRNG seeded;
each trial builds the catalog, closure, belief kernel, candidate projects,
generation/admission/completion law, and raw Bellman process before comparing
four pruning rules. The engine emits complete source rows as well as exact
operational, generative, and total dynamic losses. It hard-gates the signed
loss decomposition, frontier-only passive preservation, innovation-safe value
preservation, and both declared approximation budgets.

This layer is for robustness and economic relevance only. Its randomized
frequencies, factor contrasts, and synthetic compressed-state $J$ diagnostic
do not prove or validate a Lean theorem.

## Scalable exact-safe compression

`src/SafeCompressionSolver.jl` translates the exact solver-neutral
`BinaryCompressionFormulation` into a JuMP/HiGHS binary program. It supports
positive rational weights or active cardinality, fixes the inactive strategy,
covers every source-frontier attainer row, and preserves identity closure by
module-carrier cover. For general finite closure, binary generator variables
select one inclusion-minimal raw module set whose exact closure equals the
source closure.

HiGHS output is candidate search, not an exact certificate. The solver entry
point reconstructs each selected `RawLibrary` and recomputes its formulation,
frontier, general closure, burden, and scaled objective using
`Rational{BigInt}`; any mismatch throws. `include_deletion_trace=true` adds a
stepwise exact deletion trace. Small cases are independently enumerated by
default, while larger cases report numerical solver optimality separately
from exact selected-library safety. `enumerate_all_optima=true` fixes the exact
integer objective and adds no-good cuts to recover the optimal face.

The public entry points are `build_safe_compression_milp`,
`solve_safe_compression_milp`, and `certify_safe_compression`. The deterministic
scaling probe is documented in `scripts/README.md`.

## Approximate library compression

`src/ApproximateCompression.jl` defines the source-relative finite-horizon
problem using exact operational frontier loss, frozen-library operating value
loss, signed generative loss, and unified raw total-value loss. It provides
complete subset and Pareto enumeration for small libraries, four deterministic
backward-deletion heuristics with multistart selection, and a width-controlled
Pareto beam for larger candidate pools.

The solver-neutral 0--1 representation is exact for the operational
set-cover rows. Dynamic generative loss is evaluated by the raw Bellman oracle;
violations add exact no-good cuts. A partial cut pool is explicitly an outer
approximation, and no external optimizer dependency is included. Exact
enumeration is the only method that reports an optimality certificate. The
module and its generated report are numerical extensions, not theorem
evidence.

## Exact resource optimization

`src/ResourceOptimization.jl` defines an exact finite outer-library problem
with an implicit zero-burden inactive strategy, positive rational active
weights, operational profiles, identity-closure module masks, and a monotone
productive value table. It enumerates exact safe compressions, rechecked
deletion traces, capacity and penalized optima, price breakpoints,
supporting-price intervals, and discrete capacity marginals. Floating-point
weights are rejected.

The rich exhaustive API consists of `enumerate_sublibraries`,
`exact_safe_feasible`, `minimum_weight_safe_compression`,
`minimum_cardinality_safe_compression`, `capacity_optimal_library`,
`penalized_optimal_library`, `optimizer_breakpoints`, and
`optimal_admission_deletion_set`. Optimizer results retain every tie and
report exact objectives, library masks and IDs, burdens, frontiers,
identity-closure module sets, operational/generative/total values, and a
complete-enumeration certificate. Optional operational and generative value
tables must sum exactly to the productive total; when omitted, the legacy
total table is treated as operational and generative value is zero.

The routine named `penalty_breakpoints` returns zero together with every
nonnegative pairwise switching-price candidate. A candidate is an actual
envelope breakpoint only when unequal-burden branches are globally optimal
there.
The manuscript and `THEOREM_LEDGER.md` record this filter and the exact
active-face one-sided slope theorem; the current Julia routine does not claim
that every returned candidate is a kink.

The manuscript and `THEOREM_LEDGER.md` state the finite attainable-burden step
theorem, distinguish value breakpoints from tied optimizer thresholds, and
record the exact boundary examples. The current Julia routines evaluate
rational capacities; the manuscript's real-capacity domain is the canonical
analytic extension of the same exact burden--value pairs.

The online supplement and `THEOREM_LEDGER.md` keep conditional candidate
replacement as a supporting result. They distinguish current-library safety
from candidate-relative safety and record why positive standalone value need
not justify displacement. `optimal_admission_deletion_set` provides the reusable exact
enumerator; the audit script continues to reproduce the registered minimized
capacity-release fixture independently.

`scripts/search_resource_optimization_counterexamples.jl` uses this API to
minimize the 14 requested claim audits. Its committed JSON outputs are
byte-checked in the test suite. The implementation deliberately leaves the raw
productive transition unchanged and supplies no Lean proof.

`src/SafeCompressionComplexity.jl` gives exact, weight-preserving
constructors from weighted set cover to closure-only, frontier-only, and
combined identity-closure safe compression. It also extracts the exact
frontier-attainer/module-carrier obligation cover from an identity-closure
problem. `scripts/verify_safe_compression_complexity_reductions.jl` writes the
deterministic correspondence fixture, and
`test/test_safe_compression_complexity.jl` checks every candidate mask in the
fixture plus every covering three-set/three-element incidence system. The
bit-mask limits are fixture implementation limits, not assumptions of the
polynomial reduction. These checks validate the constructors and do not
constitute a Lean or universal complexity proof.

The compatibility F5/F8 layer in `src/DynamicProgramming.jl` adds exact
finite-horizon Bellman recursion, delays and candidate distributions,
cost-sensitive exact dynamic equivalence, exact small-state policy iteration,
and guarded sparse Float64 value iteration with residual and contraction-bound
logs. It intentionally retains F5's action-specific
`β^(delay+1)` timing and must not be used for new final-model processes.

The F6/F7 layer in `src/InnovationValue.jl` adds exact passive and full values,
research-option premia, total/operational/generative insertion values, frontier
gaps, finite discounted gap sums, and discounted belief occupancy. These are
the exact finite-library counterparts of the verified insertion decomposition
and passive Strategy Innovation Equation; they do not implement the unverified
raw T5 premium recursion.

The coverage layer in `src/Coverage.jl` adds the finite Markov specialization
of Lean S4 occupation weights, exact/Float64 discounted occupation matrices,
direct resolvent gap solves, certified candidate and aggregate project gaps,
S5 one-step gross values and one-shot cost-covering sets, ordered-grid components and
thresholds, boundary-transversality diagnostics, and one-at-a-time
cost/discount/persistence/delay/survival/signal-kernel sensitivity. It also
provides the exact S7 persistence response surface over effective discount,
kernel persistence, and gap location. Infinite
resolvents, lifetime delay calculations, and interpolated boundaries are
computational extensions; they are not Lean declarations or a raw T6 bridge.
The legacy `research_region` API is a compatibility wrapper for
`cost_covering_set`, not an optimal Bellman policy-region solver.

## Exact bootstrap and test

Install/select Julia 1.12.6, then run from the repository root:

```sh
julia --version
julia --project=julia -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

The version command must report `julia version 1.12.6`. With Juliaup, an exact
bootstrap is:

```sh
juliaup add 1.12.6
juliaup default 1.12.6
julia --project=julia -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

The current suite runs 3,785 deterministic checks, including 215 reusable
raw-model checks, 63 raw-first rectangle checks, 80 unified
comparative-statics checks, 102 randomized-library checks, 119
approximate-compression checks, exhaustive foundational/compression
properties, 226 dynamic-program checks, 249 coverage checks, 35
kernel-persistence response checks, 22 F6/F7 value-and-figure checks, 80 T7
system-interaction checks, 38 primitive-substitution checks, 37 joint-law
gauntlet checks, 110 Lean–Julia bridge checks, 61 controlled
theorem-mechanism checks, 70 financial-illustration/presentation checks, and
the existing exact counterexample regressions.

The unified comparative-static artifacts can be regenerated with:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_unified_comparative_statics.jl
```

The run emits exact Lean-fixture checks, sparse Float64 one-at-a-time and
frontier--closure surfaces, assumption-gated sign checks, a JSON summary, and
two dependency-free publication SVGs. Pass `--check` for the non-mutating
artifact drift gate.

The randomized finite-library report and complete source data can be
regenerated with:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_randomized_library_stress.jl
```

It writes `RANDOMIZED_LIBRARY_REPORT.md`, ten CSV tables, one JSON summary,
and three SVG figures. Pass `--check` for the non-mutating byte-drift gate.

The approximate-compression report, complete exact subset surfaces, heuristic
diagnostics, and publication figures can be regenerated with:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_approximate_compression.jl
```

It writes `APPROXIMATE_COMPRESSION_REPORT.md`, four CSV tables, one JSON
summary, and two SVG figures. Pass `--check` for the non-mutating byte-drift
gate. The exact enumerator certifies the registered small instances; greedy
and incomplete beam rows are explicitly uncertified.

The exact consistency bridge can be regenerated separately:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/export_exact_fixtures.jl
```

It writes eighteen schema-versioned JSON fixtures under
`shared/exact_fixtures/` and the paired
`formal/StrategyInnovation/Fixtures/Generated.lean`. Pass `--check` to compare
in memory without writing. The version-2 records use positive unified project
duration. Thirteen records cover the unified claim-boundary list and five
retain the earlier exact examples as compatibility fixtures. Fixture agreement
validates exact implementation correspondence on the selected finite inputs;
it does not replace the general Lean theorem proofs.

The exact multi-gap witness and topology audit can be regenerated separately:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/search_multi_gap_topology.jl
```

It uses `Rational{BigInt}` throughout, writes
`experiments/results/multi_gap_topology.json`, and regenerates the exact Lean
fixture `formal/StrategyInnovation/Fixtures/MultiGapRegion.lean`.

The selected unified canonical model can be regenerated from its raw law with:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/solve_unified_canonical_benchmark.jl
```

It writes exact finite/stationary values, exact and Float64 policies,
raw-derived transition/path/reward tables, convergence data, and comparative
statics under `experiments/results/summaries/`, plus the generated transition
diagram source. `solve_canonical_model.jl` remains available only for the
deprecated primitive-timing regression fixture.

The exact data and TikZ source for the Section 6 Strategy Innovation Equation
figure can be regenerated with:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/generate_strategy_value_figure.jl
```

It checks the F7 operational value three ways---by passive insertion value,
discounted gap recursion, and occupancy-weighted gap---then writes the exact
CSV and dependency-free TikZ source. Pass `--check` for the non-mutating drift
gate.

The coverage geometry and its exact S4/S5/C2 regressions can be regenerated
with:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_coverage_geometry.jl
```

It writes one JSON audit summary and six data-rich CSV files under
`experiments/results/summaries/`, plus five dependency-free SVG figures under
`manuscript/figures/`. The exact fixtures use `Rational{BigInt}`; the 121-state
geometry uses explicit Float64 mode and no randomness.

The exact S7 kernel-persistence response surface can be regenerated with:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_kernel_persistence_response.jl
```

It writes an exact-rational CSV and a compact JSON summary under
`experiments/results/summaries/`. The surface checks strict positive, strict
negative, and zero persistence effects for different gap locations. Pass
`--check` for the non-mutating byte-drift gate.

The exact T7 frontier--closure interaction surface can be regenerated with:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_system_interaction_surface.jl
```

It preserves the 2,430 exact-rational frontier, candidate, success, and cost
grid, then adds five canonical fixtures and a 3,456-row response surface over
frontier pairs, closure richness, cost, admission, descendant payoff,
incumbent reward, duration, and generator-quality frontier dependence. Every
expanded row reports both closure increments, $J$, selected projects at the
four corners, corner realizability, and the primitive-condition certificate.
Only rectangles with all four corners realizable enter aggregate sign counts.
Pass `--check` for the non-mutating byte-drift gate.

The exact T6 joint descendant-event gauntlet can be regenerated with:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/search_joint_descendant_bound.jl
```

It exhausts the registered two-belief, three-outcome joint laws and attacks
harmful omitted outcomes, operating adjustment, comparator conditions,
pathwise and future-menu gain floors, horizon fit, correlation, and multiple
descendants. It writes the minimized exact fixtures and summary under
`experiments/results/summaries/`. Pass `--check` for the non-mutating
byte-drift gate.

The seven-family controlled suite can be regenerated with:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_theorem_mechanism_experiments.jl
```

It writes 850 raw observations, compact summaries, checksummed metadata, the
synthetic report, and five data-linked SVGs. Pass `--check` for the non-mutating
artifact drift gate. A--F use exact rationals; G uses the config-recorded stable
seed and explicit Float64.

The compact finite-grid policy map included in Section 8 is derived from that
suite's committed policy summary with:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/generate_dynamic_policy_figure.jl
```

The script selects nine cost/delay/discount scenarios, validates their
61-point cutoffs and direction checks, and writes dependency-free TikZ. Pass
`--check` for the non-mutating drift gate. The map is a Float64 numerical
observation, not a continuous-boundary or comparative-static theorem.

The larger-universe ETF mechanism illustration is reproduced from existing
licensed CRSP/WRDS files with:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/audit_financial_annual_universe.jl
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/freeze_financial_annual_walkforward_audit.jl --check
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/prepare_financial_annual_walkforward_audit_data.jl
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_financial_annual_walkforward_audit.jl
```

The universe audit never parses returns. The preparation stage performs no
download and keeps licensed row-level derivatives ignored. The run enumerates
all 9,600 finite-grammar strategies, records all candidates and pruning
decisions, and writes only aggregate publication artifacts. Pass `--check` to
the final command for a non-mutating byte-drift gate.

## Deterministic RNG convention

- Stochastic functions must accept an `AbstractRNG` or an explicit integer
  seed.
- Use `research_rng(seed)` to construct a `StableRNG`.
- Do not call `Random.seed!` on Julia's global RNG in package or experiment
  code.
- Every experiment configuration must record its seed and RNG convention.
- `DEFAULT_RESEARCH_SEED` is for infrastructure defaults, not a substitute for
  an experiment-specific recorded seed.
