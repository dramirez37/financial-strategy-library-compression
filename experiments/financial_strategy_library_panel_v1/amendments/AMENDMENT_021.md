# Amendment 021 — eliminate redundant full-instance serialization

**Date:** 2026-09-01

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

The Lock 020 run was stopped after four corrected MIP checkpoints had been
atomically persisted and before any corrected structural result completed.
Profiling showed that each completed solver row entered multiple redundant
serializations of the same large exact instance: once when constructing the MIP
result, once when constructing the panel payload, and again during its in-memory
audit. The instance had already been deserialized from a file whose SHA-256 was
independently computed and matched by every predecessor checkpoint. Concurrent
serialization caused severe memory and runtime overhead without adding an
independent check.

This amendment plumbs that file SHA-256 through the MIP result, panel payload,
and exact audit. Generic callers still compute the canonical instance hash when
no precomputed file hash is supplied. The four Lock 020 MIP checkpoints are
validated, resumed, and incorporated without rerunning their solvers; the
remaining 90 matching Lock 005 MIP failures are rerun. The six unaffected
algorithm checkpoints remain under Lock 005 and are independently validated
against the same file hash.

No instance, source row, library, burden, seed, solver setting, time limit,
algorithm definition, candidate, estimand, denominator, or analysis rule
changes. Lock 020 and its four terminal MIP checkpoint records remain immutable.
No raw licensed row was printed, committed, or promoted.
