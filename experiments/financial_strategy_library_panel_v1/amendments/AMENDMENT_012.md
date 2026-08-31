# Prospective Amendment 012 — phase-specific unused market fields

**Date:** 2026-08-31

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

## Information available before this amendment

The Lock 011 continuation stopped during source partition 2 before any
postdecision result was written. The only new information was the failure
class: at least one selected row with a finite, compoundable total return and
the required `NA` return flag had neither a positive close nor a usable
absolute price fallback. No row value, selected identity, burden, solver
status, postdecision diagnostic, final audit, analysis table, or figure was
inspected. Source partitions 1 and 3 completed and their terminal sidecars and
hashes remain in the ignored licensed-data boundary. There are still zero
postdecision result records, zero final-result audits, and zero analysis
artifacts.

## Data-handling correction

The registered postdecision calculation constructs total-return indices and
uses total returns, dates, return-missing flags, and delisting flags. It does
not use close or volume. Requiring usable close and volume on every finite
postdecision return therefore made an unused field capable of deleting the
entire registered postdecision analysis.

Under this amendment:

1. Structural extraction remains unchanged and fail-closed: every finite
   structural return still requires a positive close (with the registered
   absolute-price fallback) and nonnegative volume.
2. Postdecision extraction still requires a finite compoundable total return,
   the exact `NA` return flag, stable ordering, and the existing first-row-only
   `NS` missing-return rule.
3. A missing or invalid close or volume in the postdecision phase is retained
   as `missing`, never imputed, forward-filled, or replaced by a sentinel.
4. The backtest continues to use total returns only. Missing unused close and
   volume counts are recorded for every origin in the local return-quality
   audit fields `unused_close_missing_rows` and
   `unused_volume_missing_rows`.
5. No postdecision return is dropped because an unused close or volume field
   is unavailable. No universe, source library, burden, algorithm, warm start,
   pruning order, or structural result changes.

## Interrupted-cache compatibility

The two Lock 011 source partitions may be reused only if their execution lock
is explicitly listed as compatible and every other terminal condition still
matches: phase, source index/count, origin-context hash, source stat
fingerprint, Parquet hash, schema, and row count. The missing partition 2 is
generated under Lock 012. This narrow compatibility rule avoids rereading and
duplicating two validated licensed partitions; it does not permit arbitrary
cross-lock cache reuse.

## Scientific status

This is a prospective data-validation correction after an infrastructure
failure and before any postdecision outcome. It does not alter an estimand or
analysis rule. It prevents an unused vendor field from determining inclusion
in a returns-only postdecision diagnostic. Locks 001–011 remain immutable
historical artifacts.
