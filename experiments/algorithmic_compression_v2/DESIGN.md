# Registered Algorithmic Compression Benchmark v2

## Purpose and relation to v1

V2 estimates exactness, burden quality, failure behavior, and computational
performance for the same prospectively declared structural families as v1 in a
fixed eight-worker execution environment. V1 stopped incomplete and is not
pooled with v2. V2 uses new instance identifiers, a new seed registry, a new
result directory, and a new design lock.

## Scientific units and algorithms

The structural grid, algorithm identifiers, preprocessing variants, exact
arithmetic, time limits, tie rules, and per-instance estimands are copied from
the v1 design without using v1 scientific outcomes. Every final row remains in
the denominator after generation failure, timeout, memory failure, solver error,
certificate failure, or infrastructure interruption.

Each run unit is one registered `(instance, algorithm, preprocessing)` triple.
The expected final matrix has 3,907 run units over 173 instances. Enumeration
and requirement-mask DP are used only on rows marked exact-capable. Both MIP
preprocessing variants and both heuristic preprocessing sensitivities remain
registered.

## Eight-worker execution

The supervisor runs with exactly eight Julia threads and creates eight fixed
worker lanes. The flattened registered schedule is assigned round-robin by
zero-based schedule position, so lane identity and within-lane order are stable.
Each lane launches at most one isolated Julia subprocess at a time.

Each algorithm subprocess uses:

- one Julia thread;
- one BLAS thread;
- one HiGHS thread with parallel mode off;
- its registered seed and time limit;
- a 1.5 GiB resident-memory cap;
- a full garbage collection before the timing handshake.

This is supervisor-level parallelism, not a change to enumeration, DP, greedy,
deletion, preprocessing, exact checking, or MIP semantics. Eight simultaneous
subprocesses may contend for CPU, memory bandwidth, and cache. Therefore v2
runtime, timeout, memory, and node evidence is explicitly conditional on the
declared eight-worker environment and is not compared numerically with v1.

## Runtime and reproducibility estimands

Per-run monotonic wall time remains recorded from the post-load/post-GC worker
handshake. V2 additionally records lane, lane position, global schedule
position, aggregate launch wave, and total batch
elapsed time. Primary performance summaries use the fixed eight-worker v2
environment. Other worker counts are unsupported for the registered final run.

The deterministic progress display reads only terminal-record counts. It never
reads burdens, solver statuses, runtimes, or selected identities and cannot
affect scheduling.

## Resume, interruption, and audit

Raw results are written atomically after every terminal run. A rerun skips a
valid terminal record. A preexisting control record without a terminal raw
record becomes `PROCESS_INTERRUPTED`; it is not silently rerun. Solver logs and
exact post-check certificates are retained. Every returned library is rechecked
for mandatory retention, exact tagged coverage, exact source frontier, exact
identity closure, and exact burden.

The independent audit requires the complete 3,907-row matrix, all accepted
solutions to pass exact checks, exact-method burden agreement where available,
and stable hashes for instances, raw records, controls, and logs. Solver
`OPTIMAL` remains solver evidence, not formal or exhaustive proof.

## Pilot and lock

The 11 inherited pilot-shaped rows receive new v2 seeds and are reserved but
are not required to set a new grid: the grid and per-run limits transfer from
the prospectively completed v1 runtime pilot, before inspection of partial v1
final outcomes. Before the final lock, nonregistered trivial fixtures must test
eight-lane assignment, concurrent process isolation, progress accounting,
interruption recovery, and exact agreement. No v2 registered seed, pilot or
final, is consumed by those fixtures, and no v2 final seed may be used before
the lock.

The v2 lock hashes this design, analysis plan, reporting rules, configuration,
both registries, runner, worker, registry generator, targeted tests, Julia
project, and Julia manifest. Any later change requires a new numbered v2
amendment; prior locks and outputs are never rewritten.
