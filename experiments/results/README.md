# Generated Results

Raw and bulky generated results are ignored. Reproducible compact summaries
belong in `summaries/` and must link to configurations, code commits, and raw
artifact checksums.

The compact committed summaries `theorem_feasibility.json`,
`single_gap_geometry.json`, and `multi_gap_topology.json` are deterministic
exact-arithmetic audit records.

`revision_counterexample_gauntlet.json` includes the unified
`FX-S2-UNIFIED-STATIONARY-01` positive-duration raw/compressed policy fixture.
Its exact policy-evaluation and Bellman residuals are zero; this is an
instance-level check of the general Lean S2 theorem.

`resource_optimization_claim_audit.json` and
`resource_optimization_fixtures/` are deterministic exact-rational
counterexample records for 14 proposed outer optimization claims. The audit
contains 13 counterexamples, one surviving burden-order claim, exact search
counts, theorem revisions, and per-fixture SHA-256 values. They are Julia
falsification evidence, not Lean proof or empirical evidence.

`safe_compression_complexity_reduction_fixture.json` is the deterministic
exact-rational correspondence record for the closure-only, frontier-only, and
combined weighted-set-cover reductions. It checks every selected-policy mask
in the registered instance. This is executable validation of the reduction
constructors, not a universal complexity proof or Lean evidence.

`unified_benchmark_search.csv` is the complete 972-candidate exact rational
search record for the versioned unified canonical benchmark. It preserves
every alternative's parameters, policy, minimum action gap, status, and
rejection reason. `UNIFIED_BENCHMARK_ACTION_MARGIN_REPORT.md` gives the
answer-first audit of the selected candidate; the accompanying policy/value,
perturbation, comparative-static, and rejection CSVs expose every exact
reported quantity. These are deterministic instance-level validation
artifacts, not theorem evidence. The legacy canonical outputs under
`summaries/` are unchanged.

The main canonical outputs are the `summaries/unified_canonical_*` files
generated from the selected raw law. They include exact finite and stationary
values, exact and Float64 policies, full-duration paths, operating-reward
blocks, derived transitions, convergence data, comparative statics, and a
machine-readable equality audit. The older `canonical_model_*` outputs are
unchanged primitive-timing regression fixtures and are not manuscript inputs.

`SYNTHETIC_REPORT.md` is the generated answer-first report for the controlled
seven-family theorem-mechanism suite. Its raw long-form CSV is written to the
ignored `raw/` directory and checksummed in the committed metadata. The report,
compact tables, figure data, metadata, and SVGs are byte-checked by the suite's
`--check` mode.

The `financial_terminal_audit_*.csv` summaries and status JSON instantiate the
paper's mechanisms on a finite ETF grammar. The licensed CRSP source and local
row-level extract are ignored. The committed aggregate outputs are publishable
under D-0041 and must not be presented as alpha evidence or as permission to
redistribute provider data.
