# Predecision Audit Amendment 004

The first Amendment 003 replay attempted byte-for-byte reproduction of every local
artifact. It stopped at cell 001 because the complete MIP certificate deliberately
contains single-run wall-clock measurements and the complete HiGHS log, which itself
contains timing and path-dependent diagnostics. A second isolated cell-001 replay
returned the identical selected strategies, raw binary solution, exact burden, and
exact feasibility certificate, while the serialized hash changed again. This proves
that raw byte equality is not a coherent deterministic replay predicate for that
diagnostic artifact.

No proposal-year or evaluation-year return was inspected, materialized, or used
during either failed replay attempt. No existing artifact was overwritten.

Audit Amendment 004 retains Amendment 003's complete source closure and adds a full
38-cell scientific replay. The replay recomputes every path, operating profile,
formation docket, exact safe and frontier solution, budget-matched comparator,
nested action set, and trial-ledger row. It compares path/profile data semantically,
ledger and arm files exactly, and MIP certificates after removing only:

- the `runtime_ns` table;
- `solver_diagnostics.solve_time_seconds`; and
- `solver_diagnostics.complete_solver_log`.

All solution identities, raw variable values, exact burdens, solver statuses,
controls, preprocessing maps and events, formulation, exact feasibility certificate,
and crosscheck fields remain in the deterministic comparison. Correction 002 also
binds the Julia executable, Julia version, Julia executable hash, native HiGHS library
hash, and Julia package/manifest identities.

This amendment follows observed nondeterminism and changes the audit predicate only.
It does not change the scientific design,
choices, or existing result artifacts.
