# Amendment 001 — generation-failure dispatch arity repair

Date: 2026-08-27

## Trigger and observed state

The exact registered command was started after the initial v2 design lock. The
first generated registry row followed the prospectively declared generation-
failure path. Before any algorithm worker launched or any algorithm result was
written, the supervisor stopped with a Julia `MethodError`: the refactored v2
caller passed both the obsolete standalone run-unit argument and the new
schedule-item argument to `_generation_failure_record`, whose registered v2
signature accepts only the schedule item.

At amendment time there were zero raw algorithm records, zero solver logs, and
no active supervisor or worker process. One final generator seed had been
consumed and its immutable generation record existed. The existence and hash of
that generation record, and the dispatch error, were observed; its structural
attempt payload and all burden, selected-library, runtime, node, gap, and
algorithm-comparison outcomes were not inspected.

## Prospective repair

Remove only the obsolete extra run-unit positional argument. The schedule item
already contains the same run unit plus its locked lane, lane position, global
schedule position, and launch wave. Add a nonregistered regression test that
constructs a generation-failure record and checks those fields.

This repair does not alter any registry row, seed, instance generator, attempt
rule, algorithm, preprocessing method, time or memory limit, worker count,
schedule order, statistical rule, or denominator. The existing generation
record is retained and will be expanded into the registered terminal failure
rows on resume. It is not regenerated or replaced.

## Changed files

- `julia/scripts/run_algorithmic_compression_final_v2.jl`
- `julia/test/test_algorithmic_compression_v2.jl`
- `julia/scripts/lock_algorithmic_compression_design_v2.jl`
- `experiments/algorithmic_compression_v2/amendments/EXECUTION_FAILURE_001.toml`
- `experiments/algorithmic_compression_v2/amendments/AMENDMENT_001.md`

The original `DESIGN_LOCK.json` remains byte-for-byte unchanged. The amendment
lock records its SHA-256 and hashes the complete current v2 execution surface.
