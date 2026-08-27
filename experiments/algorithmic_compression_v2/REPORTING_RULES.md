# Registered Algorithmic Compression Benchmark v2 — reporting rules

Every run reports instance, seed, algorithm, preprocessing variant, lane,
within-lane position, global schedule position, launch wave, exact burden when
available, selected original identifiers, exact feasibility certificate,
runtime, peak RSS, solver diagnostics, method counters, log paths, and hashes.

The execution environment reports git commit and dirty state, Julia/project/
manifest hashes, OS, CPU, RAM, solver and wrapper versions, supervisor threads,
worker threads, BLAS threads, HiGHS threads, worker count, and UTC start/end.

Eight-worker contention is part of the v2 environment and must be stated beside
every runtime or solved-fraction result. V1 and v2 computational outcomes are
not pooled. Burden or feasibility coincidences may be described only as
cross-version validation after both audits; they do not authorize replacing a
v2 row.

Failures, timeouts, interruptions, infeasibility, and unavailable values remain
visible in denominators and the failure log. No fractional MIP vector is rounded
into feasibility. `OPTIMAL` is never called formal or exhaustive proof.

Amendments are numbered, prospective, independently hashed, preserve every
prior lock, list outcomes already available, and state whether pooling is valid.
Silent changes, result replacement, seed reuse, and retrospective tuning are
forbidden.
