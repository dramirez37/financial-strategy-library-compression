# Prospective Amendment 013 — terminal delisting-pending return

**Date:** 2026-08-31

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

## Information available before this amendment

The Lock 012 continuation completed all three local-only postdecision Parquet
source partitions and then stopped during their deterministic merge. No
postdecision result, final-result audit, analysis table, or figure existed.
Structural results and their passing Lock 012 re-audit were already terminal.

A row-suppressing audit of the three cached partitions classified the failure
without printing an origin identifier, security identifier, date, return,
price, volume, or raw licensed row. Among 865,661 cached origin-window
memberships there was exactly one missing-return membership. It affected one
origin-security series and one origin, occurred in the registered
postdecision year, was the terminal scoped row, had no later observed return,
carried CRSP return-missing flag `DP`, carried a positive delisting flag, and
had no usable close or volume. CRSP's official return-missing flag table
defines `DP` as “Delisting Pending”:
<https://www.crsp.org/wp-content/uploads/appendix/FlagType_RM.html> (accessed
2026-08-31).

No selected identity, burden, solver status, postdecision frontier, belief
loss, savings result, final comparison, or manuscript outcome was inspected.

## Conservative missing-outcome disposition

The terminal `DP` row does not contain an observed return. It must not be set
to zero, reconstructed from an unavailable price, forward-filled, or silently
omitted while reporting the origin as a complete held-out return diagnostic.
The following rule therefore applies:

1. The earlier first-row `NS` initialization rule remains unchanged.
2. Structural extraction remains fail-closed for every noninitial missing
   return, including `DP`.
3. In postdecision extraction, a noninitial `DP` row is recognized only when
   it is in the registered postdecision year, has a positive delisting flag,
   and is the terminal scoped row with no later source observation for that
   origin-security series. Any other `DP` pattern, or any other unsupported
   missing-return flag, fails closed.
4. The recognized row is not converted into a return observation. No return,
   price, or volume is imputed.
5. To prevent future data availability from selecting a favorable subset of
   libraries or algorithms, all nine secondary postdecision records for the
   affected origin (three registered library constructions by three burden
   schedules) are marked unavailable. The 63 corresponding algorithm rows
   remain in denominators. Structural compression records remain unchanged
   and available.
6. Every unaffected origin continues through the prespecified postdecision
   calculation. The full result audit verifies the unavailable-record schema,
   the origin-wide disposition, the exact aggregate count of one recognized
   terminal `DP` membership, and the absence of imputation.

## Cache compatibility

The three terminal Lock 011/012 Parquet partitions may be reused under Lock
013 only when their phase, source index/count, origin-context hash, source stat
fingerprint, Parquet hash, schema, and row count still match. Their licensed
contents are not copied or promoted. Arbitrary cross-lock cache reuse remains
prohibited.

## Scientific status

This is a prospective data-quality and missing-outcome amendment made after an
ingestion failure and before any postdecision outcome. It changes the
availability rule for one origin's secondary held-out diagnostic, so that
change and its denominator effect must be reported. It does not change any
origin, source library, burden, algorithm, structural result, primary
structural estimand, or analysis formula. Locks 001–012 remain immutable
historical artifacts.
