# Registered Algorithmic Compression Benchmark v2 — result audit

## Audit verdict

**PASS.** The independent artifact audit read saved instances and raw run
records; it did not rerun a solver or heuristic. It reconstructed every returned
selection in original strategy coordinates and recomputed mandatory retention,
tagged coverage, source-frontier equality, identity-closure equality, and exact
burden using repository exact arithmetic.

| Audit quantity | Count |
|---|---:|
| Expected terminal run units | 3907 |
| Raw terminal records found | 3907 |
| Accepted solutions exactly rechecked | 3526 |
| Exact-capable instances checked | 38 |
| Exact objective agreements | 31 |
| Exact comparisons unavailable after recorded failure | 7 |
| Equal-objective optimizer-identity differences | 9 |
| MIP records | 346 |
| MIP solver logs retained | 312 |
| Audit errors | 0 |

## Terminal outcomes retained in denominators

| Terminal status | Count |
|---|---:|
| `GENERATION_FAILED` | 352 |
| `IMPLEMENTATION_ERROR` | 6 |
| `MEMORY_LIMIT` | 14 |
| `NO_PRIMAL_CANDIDATE` | 1 |
| `PROCESS_INTERRUPTED` | 7 |
| `REJECTED_NONBINARY_SOLVER_CANDIDATE` | 1 |
| `SOLVED` | 3420 |
| `SOLVED_BY_EXACT_PREPROCESSING` | 106 |


An unsuccessful terminal record is not treated as a missing row. Solver
`OPTIMAL` remains mixed-integer solver evidence; this audit does not relabel it
as exhaustive search or formal proof. Exact comparison certificates are stored
under `results/audit/certificates/`. The SHA-256 manifest is
`results/ARTIFACT_MANIFEST.csv` (manifest file hash `b751bb99132c86f5a008dc6245f0d1b17f7858e830420c21356e222483788dd1`).

## Limits

No second open-source MIP solver is pinned in the registered environment. Medium
and large instances therefore receive exact feasibility and burden rechecks plus
saved HiGHS bounds/status/log diagnostics, not a second-solver optimality claim.
Where an exact method or MIP run ended unsuccessfully, agreement is explicitly
unavailable rather than inferred.
