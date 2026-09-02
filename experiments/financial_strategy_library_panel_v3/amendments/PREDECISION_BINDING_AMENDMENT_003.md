# Predecision Binding Amendment 003

## Purpose

This is a provenance-only, post-result binding amendment. The registered scientific
design, formation and compression samples, source dockets, optimization instances,
exact solutions, burden-matched comparators, nested action sets, and preproposal
trial ledger are unchanged.

The initial computation seals bound the experiment-specific Julia engine and runner,
but did not bind the complete local source closure loaded by the `StrategyInnovation`
package. Because that package supplies the exact compression formulation, solver,
serialization, and independent postchecks, the omission left the computation less
reproducible than the experiment requires.

## Timing and access boundary

Amendment 003 is declared after the predecision computation artifacts exist and their
predecision-derived contents are known. This fact is recorded transparently. At the
time of declaration, no proposal-year or evaluation-year return value had been
inspected, materialized, or used. The amendment does not authorize either access.

## Frozen implementation closure

The amendment freezes:

- `julia/src/StrategyInnovation.jl` and every source file it includes, in declared
  load order;
- the v3 predecision computation engine and runner;
- the Julia project and manifest;
- the computation specification and both computation locks; and
- the public and licensed-local computation manifests that existed when the gap was
  discovered.

The lock records both every file hash and a deterministic aggregate over canonical
repository-relative paths. A replay must resolve the same `StrategyInnovation`
include closure, in the same order, and reproduce the existing 38-cell artifacts
byte for byte. No scientific choice may change during this replay.

## Required result seal

After the deterministic full replay succeeds, a separate predecision computation
result seal must bind the public manifest, licensed-local manifest, and the hash of
every local result artifact. Proposal-year access remains forbidden until that result
seal exists and replays successfully.
