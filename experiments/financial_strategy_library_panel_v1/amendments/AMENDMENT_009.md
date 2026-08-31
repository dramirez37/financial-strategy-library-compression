# Prospective Amendment 009 — parallel exact structural audit

**Date:** 2026-08-31

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

## Information available before this amendment

Lock 008 preserved all 180 terminal structural records, 756 algorithm
checkpoints, and 14 solver logs. The corrected independent audit traversed the
real result tree for approximately three hours without a Julia warning or
integrity failure, but used only one CPU core and had not completed. At the
author's direction, it was interrupted before writing `STRUCTURAL_AUDIT.toml`.
No postdecision result existed.

The interrupt stack showed the audit inside canonical instance serialization
for `journal_compression_instance_sha256`. The independent audit was
deserializing the already canonical instance file and then serializing the same
object again solely to reproduce the file's SHA-256. This generated more than
261 million allocations in the interrupted process. The 108 valid registered
instances are otherwise independent audit units.

Artifact counts and schemas were inspected only to confirm the failure and
interrupt boundaries. No selected identities, burdens, solver statuses,
held-out financial diagnostics, or comparative scientific outcomes were
inspected.

## Prospective implementation correction

1. Audit the 180 registered slots with a static eight-lane Julia thread
   partition. Each slot's result is written to its preassigned registered
   index.
2. Merge errors, counts, and hashes only in the unchanged lexicographic
   registered-key order. Thread scheduling therefore cannot change the audit
   certificate or error ordering.
3. For the independent on-disk audit only, compare the stored instance hash to
   SHA-256 of the canonical serialized instance file. The same file is still
   deserialized and fully schema-validated before exact solution checks.
4. Preserve the original canonical reserialization check as the default for
   in-memory, resume, smoke, and postdecision callers.
5. Apply the same ordered eight-lane map to the final postdecision artifact
   audit; this verifies already generated analysis records and does not perform
   the financial analysis itself.
6. Emit separate durable `structural-audit` and `postdecision-audit` progress
   records containing only completed and total slot counts. No financial or
   algorithm outcome appears in progress output.
7. Add regression tests for canonical-file/hash equivalence, tamper detection,
   deterministic ordered aggregation, eight-thread execution, and progress.

## Unchanged scientific design

Origins, universes, source instances, capabilities, burden schedules,
algorithms, seeds, solver controls, estimands, denominators, information
boundaries, exact feasibility checks, audit predicates, and nonclaims remain
unchanged. Existing structural records are reused without alteration. Locks
001–008 remain immutable historical artifacts.
