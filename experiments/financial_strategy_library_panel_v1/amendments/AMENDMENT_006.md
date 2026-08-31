# Prospective Amendment 006 — Julia 1.12 world-age-safe audit dispatch

**Date:** 2026-08-31

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

## Information available before this amendment

The Lock 005 structural run completed the registered structural accounting and
then stopped at the audit boundary. The local result tree contains 180 terminal
structural records: 108 records for serialized source instances and 72 records
for prospectively declared preparation failures. All 756 registered per-instance
algorithm checkpoints are present, together with 14 solver-log files. No
structural audit file was written and the postdecision phase was not opened.

The terminal exception was a Julia 1.12 world-age `MethodError`. The runner
dynamically included the audit module from inside its already-compiled `main`
method and immediately called the newly defined `audit_structural_results`
method. Julia 1.12 warned that the global binding and method belonged to a newer
world and refused the call. Artifact counts and schemas were inspected to locate
the failure boundary; no selected identities, burdens, solver statuses,
financial diagnostics, or comparative scientific outcomes were inspected.

## Prospective implementation correction

1. Dynamic audit-module lookup uses `isdefined` and `getfield`, avoiding direct
   compiled access to a newly introduced global binding.
2. Calls to `audit_structural_results` and `audit_all_results` use
   `Base.invokelatest`, as required for methods introduced by the dynamic
   `Base.include` in Julia 1.12.
3. The audit definitions, exact checks, result schemas, and audit ordering are
   unchanged. The correction affects dispatch only.
4. Lock 005 structural records are reused only after the runner's existing exact
   per-record validation. The Lock 005 environment may transition to Lock 006
   only when all 180 structural records, all 756 checkpoints, the disclosed
   solver logs, and no postdecision artifact are present.
5. No structural algorithm is rerun for an already terminal record. The
   postdecision phase remains closed until the structural audit passes.

## Validation before successor execution

The dynamic audit loader and invoker must be exercised under
`--depwarn=error`. Existing execution, exact-certificate, checkpoint, progress,
registration, and algorithm-agreement tests must continue to pass. Execution
Lock 006 must bind the unchanged scientific design, all historical locks, this
amendment, and the corrected runner before postdecision data are opened.

## Unchanged scientific design

Origins, point-in-time universes, source instances, capabilities, burden
schedules, algorithms, seeds, solver controls, estimands, denominators,
information boundaries, exact rechecks, and nonclaims are unchanged. No
structural result is deleted or edited. Locks 001–005 remain immutable
historical artifacts.
