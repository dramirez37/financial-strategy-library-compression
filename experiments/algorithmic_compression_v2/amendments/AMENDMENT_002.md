# Amendment 002 — chained execution-start lock after Amendment 001

Date: 2026-08-27

## Trigger and observed state

After Amendment 001 was committed and locked, the exact registered command was
run again. All 35 nonregistered readiness assertions passed. Before generation
or algorithm execution resumed, the original execution-start lock correctly
rejected the three files changed and disclosed by Amendment 001 because a
generation artifact already existed.

No new registered seed was consumed during this second attempt. There remained
one generation record, zero raw algorithm records, zero solver logs, and no
active supervisor or worker. No generation-attempt payload, burden, selection,
runtime, node, gap, or algorithm-comparison outcome was inspected.

## Prospective repair

Preserve the original execution-start lock and environment record. Permit one
chained execution-start amendment only when:

- the immutable original design and execution-start locks match their recorded
  hashes;
- Amendments 001 and 002 verify as a complete hash chain;
- the recorded pre-algorithm failure boundary reports zero raw algorithm runs;
- the live raw-run directory is still empty when the execution amendment is
  created.

The resumed execution writes new `EXECUTION_START_LOCK_AMENDMENT_002.json` and
`environment_amendment_002.toml` artifacts that bind the historical records,
the amendment chain, and the current execution surface. The auditor uses the
active amended records while retaining both originals in the artifact
manifest.

This changes no scientific input, seed, generator, algorithm, schedule, limit,
denominator, or analysis rule. It changes only how an explicitly amended runner
authenticates and records the resumed environment.

## Changed files

- `julia/scripts/run_algorithmic_compression_final_v2.jl`
- `julia/scripts/audit_algorithmic_compression_final_v2.jl`
- `julia/scripts/lock_algorithmic_compression_design_v2.jl`
- `julia/test/test_algorithmic_compression_v2.jl`
- `experiments/algorithmic_compression_v2/amendments/EXECUTION_FAILURE_002.toml`
- `experiments/algorithmic_compression_v2/amendments/AMENDMENT_002.md`

The initial design lock and Amendment 001 lock remain byte-for-byte unchanged.
