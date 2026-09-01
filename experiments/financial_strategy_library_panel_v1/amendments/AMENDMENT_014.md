# Amendment 014 — postdecision profile-adequacy failure persistence

**Date:** 2026-09-01

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

## Information available before this amendment

The Lock 013 continuation reused the three validated local-only source
partitions, passed the registered return-quality merge, and attempted all
remaining postdecision jobs. It then stopped because 72 jobs raised the exact
registered condition “a registered belief profile has too few observations.”
The 72 jobs form eight complete origin blocks of nine registered
library--burden slots each. The registered minimum remains 25 observations in
every belief profile.

At the stop, 108 of 180 terminal postdecision records existed: 72 records for
the eight prespecified structural-construction failure origins, nine
origin-wide unavailable records under Amendment 013, and 27 ordinary
postdecision records. No final result audit or downstream analysis artifact
existed. The availability counts and failure class were inspected to diagnose
the interruption. Numerical postdecision values, selected identities, burden
results, and solver statuses in the 27 ordinary records were not inspected.
This is therefore not represented as an outcome-blind prospective amendment.

## Registered failure-persistence correction

1. The minimum of 25 observations in every declared belief profile is
   unchanged. No belief is pooled, no profile is imputed, and no threshold is
   relaxed.
2. Before evaluating an unresolved origin, the runner checks every distinct
   active strategy occurring in its three source-library constructions against
   the unchanged postdecision profile rule. The check returns only adequacy,
   the number of checked strategies, and the fixed minimum; it does not expose
   postdecision scores.
3. If any strategy at an origin raises the registered insufficient-profile
   condition, all nine secondary postdecision records for that origin are
   terminal and unavailable. This origin-wide rule prevents library, burden,
   or algorithm selection based on future data adequacy.
4. Each unavailable record accounts for all seven registered algorithm rows.
   The 72 instance records and 504 algorithm rows remain in denominators.
5. Any missing series, unexpected exception, or different data-contract error
   still fails closed. The correction is not a general exception catcher.
6. The independent audit verifies the unavailable schema, unchanged minimum,
   no imputation or belief pooling, exact eight-origin/nine-slot block shape,
   and complete 1,260-row accounting.
7. The 108 existing terminal records may be reused only when their registered
   key set and aggregate SHA-256 equal the values bound by Execution Lock 014.
   They are not overwritten.

## Scientific status

This amendment implements the failure-denominator rule already stated in the
analysis plan, reporting rules, and Amendment 003. It changes no universe,
library construction, capability, burden, algorithm, solver setting,
estimand, minimum-observation rule, or completed structural result. It changes
postdecision failure serialization and the corresponding audit predicate.
Locks 001--013 remain immutable historical artifacts.
