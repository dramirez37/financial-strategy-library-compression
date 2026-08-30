# Prospective Amendment 004 — exact-kernel scalability and resumable execution

**Date:** 2026-08-30

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

## Information available before this amendment

The Lock 003 structural execution was started against the 108 serialized source
instances and 72 registered preparation-failure slots. Six terminal records
were written, all for previously declared preparation failures. No valid source
instance completed its seven-algorithm suite; no valid terminal algorithm row,
selected identity, burden, solver log, postdecision diagnostic, or public result
was saved or inspected. Postdecision data remained closed.

The interrupted process may have computed heuristic endpoints and consumed
registered multi-start seeds in memory before entering exact preprocessing.
Those values were neither persisted nor inspected. Operational diagnosis used
only process resource measurements, source-instance dimensions, source code,
and the absence of terminal records. It found a peak process footprint of
47.6 GB and two implementation defects: exact dominance preprocessing removed
one column and restarted its pairwise scan, and DP applicability was checked on
the fully reduced model although the original mandatory-only model was passed
to the DP. The DP also scanned the complete integer mask interval instead of
its reachable states.

## Prospective implementation correction

1. Tagged coverage is packed into deterministic machine-word tuples for
   duplicate detection and subset checks. Exact `Rational{BigInt}` source
   weights, feasibility, burden, reconstruction, and audit semantics remain
   authoritative.
2. Duplicate rows, empty columns, duplicate columns, and dominance removals are
   processed in deterministic batches. Forced-carrier propagation is repeated
   to a fixed point. Every removed column retains its rule, witness, and
   reconstruction status.
3. Full exact preprocessing is computed once per source instance and burden
   schedule. DP, enumeration applicability, MIP, and structural summaries reuse
   that result. Weighted greedy retains its registered mandatory-only starting
   semantics.
4. DP receives exactly the residual model used by its registered requirement
   limit and iterates only reachable masks. Its recurrence, exact objective,
   tie rule, certificate, and (O(n2^r)) worst-case bound are unchanged.
5. Eight Julia threads remain required. A deterministic semaphore permits at
   most two simultaneous memory-heavy preprocessing, exact-search, or MIP
   stages; lightweight greedy and deletion work may occupy the other lanes.
   HiGHS remains single-threaded per model.
6. Each completed algorithm row is written atomically to a local checkpoint
   bound to the instance hash and successor execution lock. Resume rechecks any
   selected library exactly before reuse. The registered instance result is
   still emitted only after all seven rows and the independent in-memory audit
   complete.
7. The terminal display flushes stage changes immediately and emits a heartbeat
   at least every 30 seconds, including lane, instance, stage, algorithm, and
   elapsed stage time. Progress content contains no financial rows or outcomes.
8. The six existing preparation-failure terminal records may be reused only
   byte-for-byte. No incomplete valid-instance output from Lock 003 exists.

## Validation before successor execution

The optimized preprocessing must pass the existing exhaustive randomized
small-instance oracle. DP must agree with enumeration on the existing exhaustive
fixture suite. The seven-algorithm synthetic smoke audit, checkpoint round trip,
interruption/resume test, progress test, and a synthetic 14,401-strategy by
32-requirement scalability fixture must pass before Execution Lock 004 is
created.

## Unchanged scientific design

Origins, point-in-time universes, source instances, strategy grammar,
capabilities, burden schedules, algorithm identities, seeds, solver controls,
estimands, failure denominators, information firewall, exact rechecks, and
nonclaims are unchanged. No failed run is removed. Runtime evidence from the
aborted Lock 003 attempt is not a scientific result and is not combined with
successor timings. Locks 001–003 remain immutable historical artifacts.
