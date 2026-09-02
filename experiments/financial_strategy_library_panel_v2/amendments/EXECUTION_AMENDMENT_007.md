# Financial Innovation-Challenge Panel v2 — execution amendment 007

Execution attempt 007 passed the missing-return, finite-flag, and exact-total-
loss boundaries. During parallel staging, the actual source-003 file count was
44 chunks while its in-memory progress/manifest vector reported 86. The run
then terminated with Julia's `ConcurrencyViolationError` when another source
attempted to resize a shared vector.

The cause was language-specific: assignments written syntactically inside a
`Threads.@threads` loop remained variables in the enclosing function scope.
The three iterations therefore replaced and mutated captured buffers rather
than owning independent buffers. Output filenames were source-indexed, but the
buffer contents and manifest vectors could not be certified. No master
manifest, universe census, strategy score, seed-derived object, solver result,
or held-out outcome was produced.

The correction moves the complete per-source scan, buffer, flush closure,
quality counters, and chunk manifest into `_stage_master_market_file`. Each
thread now makes a normal function call and therefore receives independent
stack-local state. The threaded loop writes only to distinct preallocated
result slots. Origin-level predecision work is similarly moved into a
per-origin function, and postdecision jobs no longer assign shared loop-body
locals.

A new four-thread synthetic replay runs three gzip sources simultaneously and
requires exactly one four-row chunk, one flagged-finite row, and one quality
record per source. It passes. The change affects concurrency isolation only,
not data values, sample rules, strategies, seeds, or estimands.

The 102 partial data files and two local result files are hash-censused in
`FAILED_EXECUTION_CENSUS_003.toml` and removed under the user's cleanup
instruction before the successor run.

