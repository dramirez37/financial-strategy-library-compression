# Prospective Amendment 008 — materialize audit filename keys

**Date:** 2026-08-31

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

## Information available before this amendment

Lock 007 preserved all 180 terminal structural records, 756 algorithm
checkpoints, and 14 solver logs. After Lock 007 was committed, the independent
structural audit was invoked once. The corrected registered-key construction
completed, but the audit then stopped in `_toml_stems` before comparing the
registered keys with result files or parsing any result payload. No structural
audit file or postdecision result was written.

Julia 1.12 does not define `sort` directly on the lazy filtered generator that
`_toml_stems` supplied. The audit requires a sorted vector of filename stems,
so this is an audit implementation defect rather than a scientific-design
choice.

Artifact counts and schemas were inspected only to confirm the failure
boundary. No selected identities, burdens, solver statuses, held-out financial
diagnostics, or comparative scientific outcomes were inspected.

## Prospective implementation correction

1. `_toml_stems` materializes matching TOML filenames as a `Vector{String}` and
   sorts that vector lexicographically.
2. The directory filter remains exactly `.toml`; the stem operation and
   comparison with the registered 180-key vector remain unchanged.
3. A regression test invokes the real audit helper on an unsorted temporary
   directory containing two TOML files and one ignored non-TOML file.
4. The audit script was searched for other direct `sort` calls on generators;
   no additional instance remains.
5. No audit predicate, exact certificate, result record, algorithm, or
   postdecision rule changes.

## Unchanged scientific design

Origins, universes, source instances, capabilities, burden schedules,
algorithms, seeds, solver controls, estimands, denominators, information
boundaries, exact rechecks, and nonclaims remain unchanged. Existing structural
records are reused without alteration. Locks 001–007 remain immutable
historical artifacts.
