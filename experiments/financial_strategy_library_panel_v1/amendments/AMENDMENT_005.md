# Prospective Amendment 005 — visible progress and validated preparation reuse

**Date:** 2026-08-30

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

## Information available before this amendment

The Lock 004 command was started after the registered preparation manifest had
already accounted for all 180 source-instance slots. The process spent about
ten minutes rescanning licensed daily files before any terminal progress line
appeared. Process status and artifact counts showed that it was active in
preparation, not stalled. The run was terminated before structural algorithms
started. No new algorithm checkpoint, solver log, valid terminal instance
result, selected identity, burden, postdecision diagnostic, or public result
was written or inspected. The six existing terminal structural records remain
the previously declared preparation-failure records.

Two execution defects were identified without inspecting licensed rows or
scientific outcomes. First, `--run` rebuilt preparation even when the complete
preparation manifest and every artifact named by it were already present and
hash-valid. Second, progress used a carriage-return redraw on `stderr` and did
not begin until after several licensed-file scans. Terminals or frontends that
do not render carriage returns therefore showed no durable progress, and the
initial scans were silent by construction.

## Prospective implementation correction

1. `--run` validates the complete registered preparation manifest and all file
   hashes. If validation succeeds, it reuses those immutable prepared artifacts
   and proceeds directly to structural execution. A missing or invalid manifest
   is never silently accepted; missing preparation invokes the registered
   preparation workflow, while invalid preparation stops with an error.
2. First-time universe and origin-series scans report durable newline progress
   records. Reports identify only the phase, scan pass, completed input-file
   count, cumulative source-row count, and elapsed time. They contain no file
   names, security identifiers, returns, prices, volumes, selections, burdens,
   or algorithm outcomes.
3. Threaded preparation, structural, and postdecision execution reports durable
   newline records for start, stage transition, heartbeat, and job completion.
   ANSI cursor movement and carriage-return-only redraws are removed.
4. The heartbeat interval remains 30 seconds. Output is explicitly flushed
   after every record. Eight Julia job lanes, the two-token heavy-stage
   semaphore, single-threaded HiGHS models, exact checkpoints, and all scientific
   algorithms remain unchanged.
5. Lock 004 preparation artifacts and its six byte-identical preparation-failure
   results may be reused. No Lock 004 valid-instance algorithm checkpoint or
   outcome exists to migrate.

## Validation before successor execution

Tests must show that newline progress is emitted on noninteractive streams,
that scan callbacks report activity before a scan completes, that a valid
preparation manifest bypasses reconstruction only after all hashes pass, and
that a tampered manifest artifact is rejected. The existing eight-lane smoke,
checkpoint, exact-certificate, registration, and algorithm-agreement tests must
continue to pass before Execution Lock 005 is created.

## Unchanged scientific design

Origins, point-in-time universes, strategy libraries, capabilities, burden
schedules, algorithms, seeds, solver settings, estimands, denominators,
information boundaries, exact rechecks, and nonclaims are unchanged. This
amendment changes observability and avoids redundant reconstruction; it does not
change any source instance or scientific result. Locks 001–004 remain immutable
historical artifacts.
