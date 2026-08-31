# Prospective Amendment 010 — monotone concurrent audit progress

**Date:** 2026-08-31

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

## Information available before this amendment

The Lock 009 eight-thread structural audit completed all 180 registered slots
in approximately 15 seconds and wrote a passing structural-audit certificate
with structural-result aggregate SHA-256
`9564a4c9b0ea28f4cf4a9705e8e489398555032e466ba3fac8c16a98094a012a`.
No postdecision result existed, and no selected identities, burdens, solver
statuses, held-out financial diagnostics, or comparative scientific outcomes
were inspected.

The durable progress output exposed a display-only race. A worker could reserve
completed count 2, acquire the output lock, and print before the worker that had
already reserved count 1. Every count was present and the audit certificate was
unaffected, but the displayed bar could briefly move backward.

## Prospective implementation correction

Move both atomic completed-count increment and progress rendering inside the
same output lock. Result computation remains outside the lock. This makes the
displayed sequence exactly 0, 1, ..., N without serializing audit work. Add a
regression that parses every progress record and requires this complete
monotone sequence.

## Unchanged scientific design

Thread partition, registered ordering, audit predicates, exact checks,
canonical file hashing, source instances, algorithms, burden schedules,
estimands, information boundaries, and postdecision rules remain unchanged.
The passing Lock 009 structural audit remains an immutable historical execution
record. Locks 001–009 remain immutable historical artifacts.
