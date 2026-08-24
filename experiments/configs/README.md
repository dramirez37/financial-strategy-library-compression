# Experiment Configurations

Committed experiment configurations record stable IDs, inputs, arithmetic
modes, search bounds, and expected artifacts. `theorem_feasibility.toml` locks
the Phase 2 theorem audit; `single_gap_geometry.toml` locks the exact
three-state coverage-geometry search; `compression_experiments.toml` locks the
safe-compression run; and `canonical_discounted_dp.toml` locks the primitive
F5/F8 exact and sparse Float64 solvers. `coverage_geometry.toml` locks the
exact S4/S5/C2 fixture set, 121-point Float64 coverage geometry, six sensitivity
axes, and machine-readable/figure outputs.

`unified_comparative_statics.toml` locks the final raw-derived parameterization,
exact fixture and sparse solver modes, residual/error gates, all twelve
one-at-a-time grids, the frontier--closure surface, and every CSV/JSON/SVG
artifact path. It is deterministic, uses no RNG, and is the sole active
policy-map and response-surface configuration used by Section 7.

`unified_benchmark_search.toml` locks the 972-candidate exact rational grid,
the structural positive-duration raw-law primitives, action-separation and
solver gates, local perturbations, five comparative-static contrasts,
selection tie-breakers, and all generated output paths.
`unified_benchmark_selected.toml` is the generated selected calibration and
its exact residual, raw/compressed, policy-lift, and action-margin
certificates. Both files explicitly retain `canonical_discounted_dp.toml` as
the untouched legacy compatibility fixture.

`unified_canonical_benchmark.toml` promotes selected candidate C0424 to the
main canonical implementation. It fixes the finite horizon and exact/Float64
solver gates, five comparative-static contrasts, and nine raw-derived output
paths. Its only dependency on `canonical_discounted_dp.toml` is an explicit
legacy-regression pointer; no primitive compatibility value or transition is
consumed.

`randomized_library_stress.toml` locks the exact 90-trial raw-library
robustness design, StableRNG master seed, marginally balanced three-level
factor columns, horizon and discount, cumulative operational/generative loss
budgets, complete source-data paths, standalone report, and three publication
figures. Randomization selects finite instances; every model calculation is
exact and every output is explicitly non-theorem evidence.

`randomized_library_stress_v2.toml` is the pre-outcome successor lock. It fixes
1,024 trials as eight replicates of the complete seven-factor binary cross,
four raw-realizable interaction corners per trial, exact rational estimands,
balanced deterministic prefixes, the master seed and all permitted component
seed roles, stability alerts, versioned output paths, and the frozen-pilot
boundary. The complete assignment is materialized in
`../randomized_library_v2/TRIAL_REGISTRY.csv`; the initial aggregate lock is
`../randomized_library_v2/DESIGN_LOCK.json`. Every declared output was absent
when this parent lock was frozen.

`randomized_library_stability_amendment_1.toml` is the prospective precision
amendment to that untouched parent design. It fixes cumulative snapshots at
50/100/200/300/500/750/1000/1024, requires the final estimate to use
\(N=1024\), registers descriptive Wilson intervals, exact-variance mean MCSEs,
sparse-support warnings, all seven two-level factor slices, and three output
paths. Its immutable envelope is
`../randomized_library_v2/DESIGN_LOCK_AMENDMENT_1.json`; no outcome was read or
generated before the amendment lock.

`randomized_library_execution_amendment_2.toml` is the final prospective
execution amendment. It freezes the state-dependent generation-law boundary,
exact raw-library generator, all-state witness/value audit, abort-before-write
contract, serialization and figure contract, plus the interaction-sign and
raw-witness output paths. Its immutable envelope is
`../randomized_library_v2/DESIGN_LOCK_AMENDMENT_2.json`, aggregate SHA-256
`8c278c07d998ba118d98c78cc1373a47ab63127f00d606c0042c006dac11e7be`.
It was frozen while both parent locks were current and every v2 outcome path
was absent. The registered \(N=1024\) run has since completed; the v1
\(N=90\) pilot remains separate and unchanged.

`approximate_compression.toml` locks the deterministic six- and eight-strategy
raw-library benchmarks, exact horizon/reference belief, operational and signed
generative budgets, exact-enumeration cap, Pareto-beam widths, and all
CSV/JSON/report/SVG paths. The operational 0--1 formulation is solver-neutral;
no external optimizer is required. Exact enumeration alone certifies
optimality, and every output is marked as a numerical extension rather than
theorem evidence.

`theorem_mechanisms.toml` preregisters the version-2 seven-family controlled
synthetic suite A--G, the shared stable seed, every exact/Float64 parameter,
automatic expected pattern, and all raw, summary, metadata, report,
source-data, and SVG paths. Its prospective Family F ranking block fixes the
transition, six gap vectors, comparator scores, bounded and stress
perturbations, ranking order, and individual/marginal selections before
execution. The preserved Family G map is a regression fixture and no longer
feeds an active manuscript policy map or response surface.

`financial_terminal_audit.toml` fixes the 25-ETF CRSP source, date-valid PERMNO
links, ORATS-covered inventory, source-repository commit, finite 2,400-strategy grammar, development/validation/
locked dates, execution lag, costs, pruning and ranking rules, StableRNG seed,
uncertainty design, and all audit/report/figure outputs. Restricted data and
row-level derivatives remain local and ignored; aggregate artifacts are
publishable under D-0041.
