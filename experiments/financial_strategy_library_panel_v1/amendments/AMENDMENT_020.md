# Amendment 020 — corrective checkpoint-namespace recovery

**Date:** 2026-09-01

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

The first Lock 019 corrective run was stopped after one new implementation
failure. The correction runner correctly identified a Lock 018 structural MIP
error, solved its replacement MIP, and then failed closed before overwriting
the predecessor checkpoint because it incorrectly assumed that the resumable
algorithm checkpoint itself was bound to Lock 018. All 756 algorithm
checkpoints intentionally retain their Lock 005 namespace, as declared when
Amendment 006 reused them without rerunning structural algorithms. No corrected
MIP checkpoint or corrected MIP result was persisted before the stop.

This amendment changes only corrective recovery provenance. Before starting a
solver, the runner must verify that the full seven-record checkpoint set is
bound to the exact Lock 005 aggregate, matches the serialized instance, and
contains the exact registered MIP projection failure. The six unaffected
records are resumed from that set. Only the matching MIP checkpoint may be
atomically replaced. The single Lock 019 execution-failure result is recovered
through the same validated checkpoint set rather than treated as scientific
infeasibility.

No instance, source row, library, burden, seed, solver setting, time limit,
algorithm definition, estimand, denominator, or analysis rule changes. Lock
019 and its failed recovery attempt remain immutable. No raw licensed row was
printed, committed, or promoted.
