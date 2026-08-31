# Prospective Amendment 011 — resumable Parquet analysis pipeline

**Date:** 2026-08-31

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

## Information available before this amendment

All 180 structural slots were terminal and the Lock 010 eight-thread exact
structural audit passed. Its structural-result aggregate SHA-256 was
`9564a4c9b0ea28f4cf4a9705e8e489398555032e466ba3fac8c16a98094a012a`.
There were 108 valid source instances, 72 registered preparation failures, 756
algorithm checkpoints, and 14 solver logs. No postdecision result, final result
audit, downstream analysis artifact, or public result existed. Selected
identities, burden savings, solver statuses, and postdecision financial
outcomes were not inspected before this amendment.

## Prospective implementation and storage changes

1. Add the pinned open-source `Parquet.jl` and `Tables.jl` packages to the Julia
   1.12.6 environment. Every Parquet file uses Snappy compression.
2. Scan the three registered CRSP daily source files independently on up to
   three Julia threads. Each scan retains only rows belonging to a registered
   origin window and registered selected security, writes one local-only
   Parquet partition, and never prints row values.
3. Treat the Parquet metadata sidecar as the terminal marker. Reuse requires a
   matching execution-lock hash, phase, registered origin-window hash, source
   file index/count, source basename/size/mtime stat fingerprint, Parquet
   SHA-256, schema, and row count. A terminal mismatch fails closed. A lone
   Parquet file without its sidecar is an interrupted nonterminal write and may
   be replaced.
4. Merge source partitions only in registered source-file order and reapply the
   complete missing-return, ordering, finite-return, price, volume, and
   origin-scope checks before any postdecision calculation.
5. Preserve postdecision computation as 180 deterministic jobs assigned across
   eight Julia lanes. A terminal postdecision TOML remains the job-level resume
   marker.
6. After the independent full result audit passes, flatten each registered
   instance into one seven-row, public-safe, Snappy-compressed Parquet analysis
   partition. The 180 partitions are independently resumable and are compacted
   deterministically into a 1,260-row algorithm table.
7. Produce normalized, storage-efficient Parquet tables for registered
   instance structure, grouped summaries, algorithm/schedule identity overlap,
   exact-method agreement, and tagged-requirement carrier multiplicity. The
   carrier table stores only requirement indices, types, and counts. Exact
   burdens and gaps remain present as rational strings beside floating-point
   analysis columns. Nearest-rank empirical 90th percentiles and the ordinary
   midpoint median are used.
8. Run a separate eight-thread analysis-artifact audit. It checks all hashes,
   schemas, registered keys, denominators, exact-feasibility flags, identity
   hashes, overlap bounds, the seven-table/five-figure analysis catalog,
   accessible SVG metadata, and prohibited raw-row column names. Figures use
   compact editable SVG rather than duplicated raster encodings.
9. The canonical continuation order is: verify passing structural audit; run or
   resume postdecision evaluation; run the independent full result audit; run
   or resume Parquet analysis; audit the analysis artifacts.

## Licensed-data and storage boundary

The three prepared return partitions remain under the ignored local-data tree.
They may contain transformed row-level licensed values and may not be committed,
promoted, printed, or redistributed. Analysis Parquet files contain only
registered identifiers, aggregate structural measures, algorithm diagnostics,
exact certificates, and postdecision summaries. They contain no raw CRSP rows.
No duplicate decompressed text delivery is written. Completed compressed
partitions are reused rather than recopied.

## Unchanged scientific design

Origin, library, burden, seed, algorithm, solver, estimand, exclusion,
postdecision, information-timing, failure-denominator, and nonclaim rules are
unchanged. This amendment changes execution, storage, and already-registered
analysis materialization only. Locks 001–010 remain immutable historical
artifacts.
