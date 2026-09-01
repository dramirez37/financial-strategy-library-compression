# Amendment 015 — exact count-only profile-adequacy preflight

**Date:** 2026-09-01

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

## Information available before this amendment

The Lock 014 continuation passed the structural audit and return-quality merge,
then entered the new eight-lane profile-adequacy preflight. After repeated live
heartbeats remained at 0/8, it was interrupted before any lane completed and
before any new postdecision record was written. The local result state remained
the 108 records bound by Lock 014; no final result audit or analysis artifact
existed. No numerical postdecision value, selected identity, burden result, or
solver status was inspected.

The interruption exposed an implementation inefficiency: the preflight loaded
nine large instances per origin, hashed them to find duplicates, and reran a
complete strategy backtest merely to determine whether `_profile` would have at
least 25 observations in each belief. Neither hashing nor strategy-return
calculation enters that count.

## Semantics-preserving optimization

1. The runner loads one source instance per registered library construction,
   rather than three schedule-specific copies. A burden schedule changes
   weights, not the active security identities relevant to observation counts.
2. Across those three instances, the preflight extracts the stable set of
   distinct active security identifiers.
3. For each security and belief, it counts dates satisfying exactly the same
   predicates used by `_profile`: the date lies in the registered postdecision
   window and the fixed reference-derived `state_by_date` maps that date to the
   belief. A profile is inadequate if and only if any such count is below 25.
4. The preflight does not compute strategy returns, utilities, frontiers,
   losses, selected identities, or solver outcomes. Complete postdecision
   evaluation remains unchanged for an origin that passes.
5. The eight-thread progress record now reports the active `profile-adequacy`
   stage for each lane.

This changes execution cost only. It does not change the registered minimum,
affected-origin rule, expected unavailable counts, scientific estimands, or
audit predicates established by Amendment 014. Locks 001--014 remain immutable
historical artifacts.
