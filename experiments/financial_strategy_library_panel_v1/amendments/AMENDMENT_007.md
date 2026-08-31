# Prospective Amendment 007 — audit key-shape and latest-world binding lookup

**Date:** 2026-08-31

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

## Information available before this amendment

The Lock 006 continuation preserved all 180 terminal structural records, 756
algorithm checkpoints, and 14 solver logs, then reached the independent audit.
No structural audit file was written and no postdecision result was created.
The audit stopped before iterating over result contents.

Two audit implementation defects were exposed. First, Julia's typed
comprehension with three comma-separated iterators created an
`Array{String,3}`. `_expected_stems` passed that array to `sort`, which in Julia
1.12 requires an explicit `dims` keyword for multidimensional arrays. The audit
requires a sorted one-dimensional key vector. Second, although the audit module
binding and audit call used latest-world dispatch, the intermediate lookup of
the newly defined audit-function binding still used an ordinary `getfield` and
emitted a world-age warning.

Artifact counts and schemas were inspected only to confirm the failure
boundary. No selected identities, burdens, solver statuses, held-out financial
diagnostics, or comparative scientific outcomes were inspected.

## Prospective implementation correction

1. `_expected_stems` explicitly flattens the registered 20-by-3-by-3 Cartesian
   product to a vector and sorts that vector, preserving the same 180 declared
   keys and lexicographic order.
2. The audit-function binding lookup itself uses
   `Base.invokelatest(getfield, module, name)` before the function is called with
   `Base.invokelatest`.
3. Regression tests use the real audit module under `--depwarn=error` to verify
   a unique, sorted 180-key vector matching `registered_job_keys`. A dynamically
   introduced binding also tests latest-world lookup and invocation.
4. No audit predicate, exact certificate, result record, algorithm, or
   postdecision rule changes.

## Unchanged scientific design

Origins, universes, source instances, capabilities, burden schedules,
algorithms, seeds, solver controls, estimands, denominators, information
boundaries, exact rechecks, and nonclaims remain unchanged. Existing structural
records are reused without alteration. Locks 001–006 remain immutable
historical artifacts.
