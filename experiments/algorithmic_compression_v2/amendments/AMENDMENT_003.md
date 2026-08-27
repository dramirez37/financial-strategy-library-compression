# Amendment 003 — execution-record reporting correction

Date: 2026-08-27

## Trigger and outcomes already available

The complete 3,907-row v2 benchmark and independent saved-artifact audit were
available. The audit had passed with zero audit errors. Inspection of the
generated execution-record prose found three copied v1 descriptions that
contradicted the locked v2 configuration: “one process at a time,” a 16 GiB
process cap, and the v1 Make target names. The table label also called the
active execution-start-lock aggregate a design-lock hash.

No result row, certificate, status, burden, selected library, solver diagnostic,
runtime, denominator, or audit calculation is changed by this amendment.

## Reporting-only correction

The execution-record generator is corrected to report:

- eight concurrent worker lanes, with at most one isolated subprocess per lane;
- a 1.5 GiB resident-memory cap per worker;
- `make aor-benchmark-v2` and `make aor-benchmark-v2-audit`;
- the aggregate as the active execution-start-lock aggregate; and
- both original and amended environment records as manifest-retained artifacts.

The non-solving audit is rerun only to regenerate reports and hashes. It must
still find 3,907 terminal rows and zero audit errors. Prior locks and the
incorrect pre-correction report remain identified by SHA-256 in the correction
record.

## Changed files

- `julia/scripts/audit_algorithmic_compression_final_v2.jl`
- `julia/scripts/lock_algorithmic_compression_design_v2.jl`
- `experiments/algorithmic_compression_v2/amendments/AMENDMENT_003.md`
- `experiments/algorithmic_compression_v2/amendments/REPORTING_CORRECTION_001.toml`

No experiment runner, worker, registry, seed, algorithm, configuration, or raw
result file is changed.
