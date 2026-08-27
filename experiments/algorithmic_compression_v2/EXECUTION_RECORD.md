# Registered Algorithmic Compression Benchmark v2 — execution record

## Outcome

The registered final runner produced 3907 terminal run records. Exactly
3526 records contain returned libraries that were independently rechecked;
381 records contain no accepted library. These counts are execution
facts, not interpretive performance claims.

## Reproducibility envelope

| Field | Recorded value |
|---|---|
| Active execution-start lock aggregate | `458b221fb256b82c47ddc5a16df03f6bcd7552a6e6fc2c238083c84c4e583862` |
| Git commit at execution start | `e0242cfb43f936d9ae383ba4cfa3c1929e2a1b0d` |
| Dirty worktree at execution start | yes |
| Dirty-status hash | `eca3bba443ef096303829e24562ac60d124550d52525693208d935be3dc5ed32` |
| Julia | `1.12.6` |
| Manifest SHA-256 | `4f75e819e1e3fa28cc39e0600937d0d28345e74ee3e0f9a092aa71dfd1a6f666` |
| Operating system | macOS 26.6.2 |
| Kernel / architecture | `25.6.0` / `arm64` |
| CPU | Apple M1 Pro |
| RAM (bytes) | `17179869184` |
| HiGHS / HiGHS.jl / JuMP | `v1.15.1` / `1.24.1` / `1.31.1` |
| Julia / BLAS / HiGHS threads | 8 / 1 / 1 |
| Process concurrency | 8 |
| UTC start | `2026-08-27T15:02:35.694Z` |
| UTC end | `2026-08-27T18:42:13.828Z` |

The machine identifier is stored only as `sha256:ac84fa6899d5165f3ac008ba4cb47d1a91b5498f0330a18ee2a0319d4dacc395`.
The raw dirty-worktree paths are retained in the active environment artifact;
the original and amended environment records are both included in the manifest.

## Registered execution controls

The runner used final registry rows only, deterministic registry schedule-key
order, the registered Latin rotation, eight concurrent worker lanes with at
most one isolated subprocess per lane, exact registered seeds, registered
size-class time limits, and a 1.5 GiB resident-memory cap per worker. It requested
a full garbage collection before each timing handshake. All HiGHS runs used one
thread, parallel mode off, presolve on, zero relative and absolute MIP gap
tolerances, and their registered MIP seed. The mandatory-only MIP formulation is
implemented in the locked external runner because the committed package MIP API
exposes the registered full fixed-point formulation; both variants reconstruct
in original coordinates and undergo the same exact post-check.

## Terminal-record census

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


The raw matrix is `results/final_algorithm_runs.csv`. Per-run TOML records,
worker handshakes, stdout/stderr, solver logs, generated instances, generation
records, and hashes are retained below `results/`.

## Commands

```text
make aor-benchmark-v2
make aor-benchmark-v2-audit
```
