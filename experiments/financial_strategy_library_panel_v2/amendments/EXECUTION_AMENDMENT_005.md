# Financial Innovation-Challenge Panel v2 — execution amendment 005

Execution attempt 005 stopped during the first retained rows of all three
parallel master-panel source scans. The implementation required every finite
`dlyret` to carry `dlyretmissflg=NA`. A complete aggregate audit of the three
registered daily files found that finite returns carry only `NA` or `MV`:
49,225,176 rows carry `NA`, while 226 carry `MV` (38, 54, and 134 in
registered file order). CRSP defines `MV` as a missing corporate-action value.

The correction does not treat an `MV` row as complete. The master panel
preserves its numeric total return and flag for audit, but the complete-case
census treats any finite return whose flag is not `NA` as an unusable return
session. Such a row excludes a security when it occurs on a predecision SPY
reference session and makes a frozen postdecision candidate unavailable when
it occurs on its held-out calendar. No value is imputed, reconstructed, or set
to zero. A finite return with any flag other than `NA` or the observed `MV`
still fails closed.

Before the stop, attempt 005 wrote only its environment, source audit, and two
security-history staging artifacts. It wrote no daily market chunk, universe
census, strategy score, seed-derived object, arm, solver result, or held-out
outcome.

At the user's direction, local artifacts from execution attempts 001--005 are
cleaned before the successor run. `FAILED_EXECUTION_CENSUS_001.toml` freezes
the path, byte size, and SHA-256 digest of every removed file. The tracked
design locks, execution locks, and amendment records remain in place. No
unrelated experiment directory or user-owned result is included in the
cleanup.

