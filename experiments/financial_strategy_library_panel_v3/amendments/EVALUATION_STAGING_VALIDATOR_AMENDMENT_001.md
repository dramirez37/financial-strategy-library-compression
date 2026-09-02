# Evaluation staging validator amendment 001

## Scope

This post-lock amendment repairs one interface-validator predicate. It does not
alter the frozen experiment, proposal or robustness choices, universe
membership, extraction masks, source fields, return handling, portfolio
scoring, diagnostics, capacity formulas, ledger updates, or public outputs.
The original `EVALUATION_EXECUTION_LOCK.toml` is retained byte-for-byte.

The first locked staging attempt stopped while validating the sealed proposal-
robustness interface, before any master-market Parquet file or identifier/date
cursor was opened. `EVALUATION_STAGING_FAILURE_001.toml` records the exact
failure, original lock and source hashes, zero inspected/materialized/used
evaluation values, and zero stage outputs.

## Root cause

Cell 002 is the one registered universe-gate failure. All 24 robustness specs
are unavailable with `UNIVERSE_GATE_FAILED`. Their local comparator and safe
`strategy_ids` vectors are both empty placeholders. The sealed public
interface correctly records `available=false` and `same_choice=false`: an
unavailable pair has no frozen identity and therefore cannot be a shared
choice.

The original validator compared the two vectors without conditioning on
availability. Empty-vector equality evaluated to true and contradicted the
sealed public flag. All 888 available specs already reconcile under ordinary
identity equality; the mismatch is exactly the 24 unavailable specs in cell
002.

## Amended invariant

For a grid record, the validator now defines:

```text
same_choice = record_available && comparator_strategy_ids == safe_strategy_ids
```

An available record must contain two nonempty identity vectors and blank
record/choice failure codes. Its sealed public `same_choice` must equal exact
vector equality. An unavailable record must have public and local record-level
`UNIVERSE_GATE_FAILED`, empty comparator and safe identity vectors, the same
failure on both choice placeholders, and public `same_choice=false`.

Unavailable cap records also require identical sealed public/local failure
dispositions. No unavailable choice is constructed or evaluated. Error
messages now include the cell index and spec ID.

## Implementation and authority

The original sealed staging source remains unchanged. The amendment wrapper
loads it and replaces only `_validate_robustness_binding`; extraction and all
downstream methods remain the versions hashed by the original execution lock.
After a successful amended staging run it writes a deterministic public-safe
receipt binding the Amendment001 lock and the exact original public/local
stage-manifest hashes. It does not rewrite those manifests.

The amended evaluation entrypoint requires and byte-checks that receipt,
installs the same validator delegate into the runner's fresh nested staging
module, and only then delegates to the original sealed evaluation runner. The
amended result-seal entrypoint likewise requires the amended runner and binds
the original execution lock, Amendment001 lock, staging receipt, and final
public/local results in `EVALUATION_RESULT_SEAL.toml`. Thus the amendment is
neither lost after extraction nor orphaned at final sealing.
The amendment lock binds:

- the original execution lock and all 114 files in its transitive seal;
- the failure record and this specification;
- the validator-only staging wrapper, amended runner, amended final sealer,
  and their exact original source dependencies;
- the adversarial and downstream-propagation tests and test runners; and
- both sealed proposal result interfaces.

The adversarial test proves that two empty unavailable placeholders compare
equal as vectors yet are not a same choice, rejects an unavailable `true`
flag or missing failure, and clears all 38 sealed cells pre-scan with exactly
37 gate-passed cells and cell 002 retaining zero access.

Creating or reviewing this amendment lock does not authorize another
historical staging attempt. Rerun requires an explicit independent amendment
go. No original lock or sealed upstream artifact may be replaced.
