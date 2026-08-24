# Financial resource-optimization implementation amendments

## Amendment 1 — use the annual-audit public config loader

- Recorded: 2026-08-04, before any resource MILP was constructed or solved.
- Trigger: the first post-lock execution completed the terminal parent replay, then
  stopped while loading the annual audit because direct `TOML.parsefile` does
  not add the universe tickers from its separately locked selection manifest.
- Change: call `load_financial_annual_config`, the existing public annual-audit
  loader, instead of directly parsing its TOML. The terminal-audit loader is
  used symmetrically.
- Unchanged: all primary and secondary weights, exact frontier rule, closure,
  objectives, gates, parent artifacts, information timing, and parent pruning
  definitions and orders.
- Outcome access: no resource model had been built, no MILP had been solved,
  and no resource-optimization output existed when this amendment was made.

## Amendment 2 — extract annual-audit optimization inputs in one parent pass

- Recorded: 2026-08-04, before any resource MILP was constructed or solved.
- Trigger: the amended run completed all five locked annual decision hashes,
  but the wrapper then retained the full parent result while separately
  recomputing 202 source profiles. This caused repeated garbage collections
  over a roughly 24 GB peak and was stopped after confirming no extension
  output existed.
- Change: call the same frozen annual-audit evaluation, initial-library, pruning, and
  annual-ranking functions once; copy the 202 validation profiles from that
  evaluation; compute the same mean next-year candidate qualities after the
  five annual decision hashes; and discard unneeded parent diagnostics. This
  is an extraction/scaling change, not an analytical change.
- Unchanged: all source-selection, safe and frontier-only pruning functions,
  deletion orders, annual hashing boundary, target computations, primary and
  secondary weights, exact frontier rule, closure, objectives, and gates.
- Outcome access: all five already locked parent annual hashes were observed,
  but no resource model had been built, no MILP had been solved, and no
  resource-optimization output existed when this amendment was made.

## Amendment 3 — retain only the registered annual target-quality sufficient statistic

- Recorded: 2026-08-04, before any resource MILP was constructed or solved.
- Trigger: the one-pass extraction still called the general-purpose parent
  ranking routine, which retains five years of full candidate ranking rows,
  score gaps, target gaps, ranks, correlations, and selection audit rows. The
  run reproduced all five parent decision hashes but was stopped before any
  resource solve or output after repeated large allocation cycles.
- Change: reproduce the frozen pre-target profile construction, scores,
  selections, and `_decision_hash` call exactly. Only after each hash is fixed,
  compute the same target profiles and individual realized opportunity values,
  add them to a running five-year sum, and discard the unregistered ranking
  diagnostics. Check every recomputed annual hash against the committed parent
  status before optimization.
- Unchanged: the frozen source, profile and transition estimators, marginal
  selection, all four comparator selections, annual hashing boundary, target
  profile and occupation formulas, parent pruning, resource weights,
  objectives, exact frontier rule, closure, and gates.
- Outcome access: all five locked parent annual hashes were observed, but no
  resource model had been built, no MILP had been solved, and no extension
  output existed when this amendment was made.

## Amendment 4 — remove the forced whole-heap collection

- Recorded: 2026-08-04, before any resource MILP was constructed or solved.
- Trigger: amendment 3 reproduced all five hashes and bounded the retained
  annual sufficient statistic, but its explicit `GC.gc(false)` after the 2024
  episode forced an hour-long scan of the still-live 9,600-strategy evaluation
  heap. The run was stopped before any resource solve or output.
- Change: continue emptying the unneeded per-year dictionaries, but do not
  force whole-heap garbage collection. The small resource models and MILPs run
  immediately, and normal process exit reclaims the empirical evaluation heap.
- Unchanged: every calculation, hash, weight, objective, constraint, pruning
  rule, information boundary, exact gate, and output schema.
- Outcome access: all five parent annual hashes were observed, but no resource
  model had been built, no MILP had been solved, and no extension output
  existed when this amendment was made.

## Amendment 5 — defer automatic collection until after output writing

- Recorded: 2026-08-04, before any resource MILP was constructed or solved.
- Trigger: removing the explicit collection exposed that Julia automatically
  starts the same whole-heap scan immediately after the fifth episode, before
  model construction. The run was stopped before any resource solve or output.
- Change: after the fifth target-quality sufficient statistic and decision hash
  are complete, temporarily disable automatic collection; run the small exact
  model construction, MILPs, verification, and output writing; then restore
  the caller's prior GC-enabled state in a `finally` block. Normal process exit
  reclaims the dead empirical heap.
- Unchanged: every empirical and optimization calculation, annual hash,
  information boundary, weight, objective, constraint, pruning rule, exact
  gate, certificate, and output field.
- Outcome access: all five locked parent annual hashes were observed, but no
  resource model had been built, no MILP had been solved, and no extension
  output existed when this amendment was made.

## Amendment 6 — isolate the annual-audit extraction heap in a child Julia process

- Recorded: 2026-08-04, before any resource MILP was constructed or solved.
- Trigger: amendment 5 again reproduced all five locked annual decision
  hashes, but disabling collection retained the large 9,600-strategy
  evaluation heap while the parent process began post-extraction work. The
  operating system killed that process with exit status 137 before the first
  resource-model construction message or any extension output.
- Change: execute only the frozen annual-audit extraction in a child Julia process,
  return the compact source catalog, 202 validation profiles, pruning
  endpoints, annual hashes, and registered opportunity-quality sufficient
  statistics through Julia's typed serialization stream, then terminate the
  child before constructing any resource model. Operating-system process exit
  releases the empirical heap without a whole-heap collection in the MILP
  process.
- Unchanged: every empirical and optimization calculation, annual hash,
  information boundary, weight, objective, constraint, pruning rule, exact
  gate, certificate, and output field. The serialized payload contains only
  values already computed by amendment 5; it is not a cache or analytical
  input change.
- Outcome access: all five locked parent annual hashes were observed, but no
  resource model had been built, no MILP had been solved, and no extension
  output existed when this amendment was made.

## Amendment 7 — use the registered repository project for the child

- Recorded: 2026-08-04, before any child extraction, resource-model
  construction, resource MILP, or extension output.
- Trigger: the first amendment-6 invocation completed only the terminal-audit replay, then
  failed before spawning the child because `Base.active_project()` returned
  `nothing` in script mode even though the parent command used
  `--project=julia`.
- Change: launch the child with the fixed repository-local `julia` project
  directory already used by the registered command and test suite.
- Unchanged: the child executable, extraction function, serialized payload,
  all empirical and optimization calculations, weights, objectives,
  constraints, pruning rules, exact gates, and outputs.
- Outcome access: no annual-audit extraction ran in this attempt, no resource model was
  built, no MILP was solved, and no extension output existed when this
  amendment was made.

## Amendment 8 — use sparse identity-closure incidence constraints

- Recorded: 2026-08-04, before any resource MILP was constructed or solved and
  before any extension output.
- Trigger: the amendment-7 child reproduced all five locked hashes and
  returned the compact payload. Stack inspection then showed that the parent
  was materializing every subset of the financial module universe solely to
  represent identity closure; the run was interrupted inside
  `identity_generative_closure` before reaching the first solver call. The
  child also logged a final broken pipe because the parent closed a buffered
  serialization stream immediately after reading its first object.
- Change: formulate identity closure directly as one sparse carrier-cover row
  per frozen source module, alongside one exact-attainer row per belief and a
  binary mandatory-inactive-policy row. Read the complete child byte stream
  before deserializing it. This is the registered scalable identity-closure
  MILP and has size linear in the observed carrier incidence rather than
  exponential in the number of modules.
- Exact boundary: rationalize every original profile coordinate losslessly;
  after HiGHS proposes a vector, recompute the original rational frontier,
  original module-string union, exact burden, scaled integer objective, every
  belief row, every module row, and the inactive-policy constraint. Solver
  tolerances remain explicitly non-probative.
- Unchanged: source libraries, parent pruning endpoints and orders, all
  weights, objectives, empirical calculations, annual hashes, information
  timing, quality statistics, exact preservation gates, certificates, and
  output fields.
- Outcome access: all five locked parent annual hashes were observed, but no
  resource MILP was constructed or solved and no extension output existed
  when this amendment was made.
