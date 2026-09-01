# Amendment 023 — preserve exact MIP projection provenance

**Date:** 2026-09-01

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

The Lock 022 structural run completed all registered solver work and produced
108 successful source-instance records plus 72 registered preparation-failure
slots. Its independent structural audit then stopped the workflow because the
panel-level MIP record adapter had not copied the solver result's
`warm_start_source` field. The omission affected all 108 successful MIP
checkpoints; the audit reported it for the 94 Amendment 019 correction rows for
which substitution provenance is mandatory. No postdecision refresh or new
analysis was run, and no empirical outcome was interpreted.

This amendment factors the already exact warm-start projection into a pure
function, records its returned provenance on future MIP rows, and reconstructs
the missing metadata for all 108 terminal candidates from the serialized exact
instance, the saved registered weighted-greedy selection, and exact fixed-point
preprocessing. Reconstruction must repeat all exact feasibility and burden-
nonincrease checks and records its substitution count. All 108 solver
checkpoints and solver logs are validated and reused; no solver is rerun. The 94
scientific correction rows retain their Amendment 021 identity, while all 108
structural records receive a separate Amendment 023 provenance-refresh marker.

No candidate, selected identity, burden, source row, library, weight, seed,
solver setting, time limit, algorithm definition, estimand, denominator, or
analysis rule changes. Locks 020--022, the failed Lock 022 structural audit, and
all terminal checkpoints remain immutable. No raw licensed row was printed,
committed, or promoted.
