# Prospective Amendment 002 — CRSP new-security return initialization

**Date:** 2026-08-29

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

## Information available before this amendment

One licensed execution attempt stopped during structural return extraction at
the first missing or nonnumeric return. It created only the ignored environment
record. Licensed rows had therefore been opened, and the ingestion failure was
known. No source instance was constructed, no registered seed was consumed,
and no algorithm, solver, burden, selected-identity, postdecision, or financial
outcome was observed.

The aggregate, row-suppressing audit in `RETURN_QUALITY_AUDIT_001.md` was then
performed solely to classify the ingestion failure. Among 3,950,875 selected
origin-window memberships, all 340 missing returns were the first scoped row of
their origin-security series and carried CRSP flag `NS`; no interior return was
missing. Official CRSP documentation defines `NS` as “New Security.”

## Prospective correction

1. A missing or nonnumeric `dlyret` is excluded only when it occurs on the
   first source row of an origin-security extraction window and
   `dlyretmissflg` is exactly `NS`.
2. The excluded initialization row contributes no return, price, volume,
   signal, profile, burden, eligibility, or postdecision value. It is not
   imputed as zero or reconstructed from prices.
3. A finite return is accepted only when `dlyretmissflg` is exactly `NA` and
   the return is greater than -1.
4. A missing return after the first scoped source row, a first missing return
   with any flag other than `NS`, an `NS` missing return after initialization,
   an invalid finite return, or a finite return with a non-`NA` missing flag
   fails closed.
5. Minimum observations and five-belief profile requirements apply after the
   initialization row is excluded.
6. Every origin records source rows seen, valid return rows retained, and `NS`
   initialization rows excluded. Structural audit verifies the registered
   aggregate count. The later postdecision phase applies the same rule and
   records its own counts without using them to change structural results.
7. The failed attempt's environment-only record may be replaced by the
   successor execution environment record before instance preparation. No
   terminal or scientific record may be replaced.

## Unchanged design

Origins, point-in-time universes, liquidity rules, strategy grammar, belief
definition, source-library constructions, capability ownership, burden
schedules, algorithms, seeds, applicability limits, solver settings,
estimands, postdecision firewall, failure denominators, and nonclaims are
unchanged. The correction neither selects securities nor tunes an algorithm;
it formalizes handling of a CRSP initialization code before any study outcome
exists.

The original design lock and Execution Lock 001 remain immutable historical
records. Execution Lock 002 binds this amendment and the corrected code.
