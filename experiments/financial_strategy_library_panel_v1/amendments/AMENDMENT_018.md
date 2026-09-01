# Amendment 018 — analysis-partition certificate rebinding

**Date:** 2026-09-01

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

After the passing Lock 017 execution and independent analysis audit, a
resume-safe rerun recomputed the result-audit certificate. Its timestamp made
the certificate file hash differ even though its execution lock, 180 source
records, postdecision aggregate, row counts, and audit conclusions were
unchanged. All 180 existing Parquet partitions remained bound to the prior
certificate hash. The partition validator treated this expected stale binding
as corruption and stopped before its documented atomic replacement path.

This amendment separates certificate rebinding from data corruption. A
partition may update only its result-audit and successor-lock bindings when:

1. its Parquet hash, schema, and seven-row cardinality validate;
2. its recorded structural and postdecision source hashes equal the current
   audited source files; and
3. its execution-lock binding is either Lock 017 or the current Lock 018.

The Parquet bytes are not rewritten in that case. A source-hash mismatch,
Parquet-hash mismatch, missing file, unexpected schema, or unrelated lock
remains fatal. Analysis formulas, registered keys, algorithms, estimands,
denominators, tables, and figures are unchanged. No structural or
postdecision result is altered, and no raw licensed row is written or exposed.
Locks 001--017 remain immutable historical artifacts.
