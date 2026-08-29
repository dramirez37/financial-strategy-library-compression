# Return-quality audit after the pre-execution ingestion failure

**Audit date:** 2026-08-29

**Scope:** selected origin-security memberships in the structural windows of
Registered Point-in-Time Financial Strategy-Library Panel v1.

## Trigger and evidence boundary

The first licensed execution attempt stopped before instance construction at
the first nonnumeric `dlyret`. It created only an ignored environment record.
No registered seed was consumed and no burden, selected identity, algorithm,
solver, postdecision, or financial-performance result was observed.

A read-only Julia diagnostic then reconstructed the already locked point-in-
time universes and traversed all selected structural-window memberships. It
reported aggregates only and printed no raw licensed row, PERMNO, ticker,
price, volume, return, or date.

## Aggregate findings

| Check | Result |
|---|---:|
| Registered origins | 20 |
| Origin-security series | 2,670 |
| Selected origin-window memberships | 3,950,875 |
| Missing-return memberships | 340 |
| Missing-return rate | 0.0086057% |
| Missing returns on first scoped row | 340 |
| Missing returns after the first scoped row | 0 |
| Affected origin-security series | 340 |
| Affected origins | 20 |
| Return values at or below -100% | 0 |
| Missing-return flag on every missing return | `NS` |
| Missing-return flag on every finite return | `NA` |

The pattern is deterministic boundary initialization, not interior return
missingness. The initial implementation incorrectly treated the expected first
`NS` row as an unusable series.

## Official interpretation

The official CRSP flag table defines daily return missing flag `NS` as “New
Security” and `NA` as “Not Applicable”; the CRSP file-format guide states that
the missing-return flag describes why a return is absent and is `NA` when the
return is available.

- CRSP, *CRSP US Stock & Indexes Database Guide, Flat File Format 2.0*:
  <https://www.crsp.org/wp-content/uploads/guides/CRSP_US_Stock_%26_Indexes_Database_Guide_Flat_File_Format_2.0.pdf>
- CRSP, *Return Missing Flag—Daily and Delisting*:
  <https://www.crsp.org/wp-content/uploads/appendix/FlagType_RM.html>

Both official pages were accessed on 2026-08-29.

## Disposition

Amendment 002 permits exclusion of exactly one missing-return initialization
row per origin-security series only when it is the first scoped row and its
flag is `NS`. No return is imputed. Every other missing, nonnumeric, invalid, or
flag-inconsistent return remains a hard failure. Counts are recorded in local
phase metadata and audited.

**Data-quality assessment:** high confidence. The incompatibility was critical
for execution because it stopped all preparation; the underlying missingness
is low severity for analysis because it is confined to documented initialization
rows that precede every usable return in the affected series.
