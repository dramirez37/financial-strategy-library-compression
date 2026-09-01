# Amendment 017 — resume aggregate namespace correction

**Date:** 2026-09-01

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

The Lock 016 continuation re-audited all structural records, then stopped in
environment recovery before postdecision or analysis work. The recovery gate
computed an aggregate over filenames relative to the `postdecision/` directory
but compared it with the result-audit aggregate, whose keys are relative to the
local-results root and therefore begin with `postdecision/`. Both aggregates
hash the same 180 files in the same order, but the intentionally hashed key
names differ. No analysis artifact existed, and no result value was inspected.

The correction binds both namespaces explicitly. The resume gate compares its
directory-local aggregate with the registered directory-local value, while the
independent result audit continues to bind the root-relative aggregate. File
bytes, result schemas, audit predicates, algorithms, formulas, denominators,
and estimands are unchanged. Locks 001--016 remain immutable historical
artifacts.
