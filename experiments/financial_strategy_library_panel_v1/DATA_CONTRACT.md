# Licensed data contract for Financial Strategy-Library Panel v1

The study uses the existing locally licensed CRSP/WRDS delivery described in
`DATA_ACCESS.md`. Registration and lock validation do not open those files.

At execution, the security-history input must provide the column names listed
in the registered configuration. A row is used only to identify the interval
containing an origin, its PERMNO, ticker, name, `FUND`/`ETF` classification, and
active flag. No future interval or endpoint condition may affect eligibility.

The daily inputs must provide the registered date, return, close/price, volume,
delisting flag, and return-missing flag columns. Universe eligibility and
ranking parse only date, price, volume, and flags; the minimum history rule
counts dated rows without examining return values. Returns are opened only
after the origin universe is frozen and hashed. No raw value may be printed in
logs or written outside the ignored local-data boundary.

Missing required fields, duplicate security-date keys, invalid date ordering,
unresolved origin classification, nonnumeric required returns, or an unexpected
return-missing flag fail closed. Prices may use absolute `dlyprc` only when
`dlyclose` is absent or nonpositive; every fallback is counted. Returns are
never interpolated or forward-filled. A security that ends after an origin is
not removed from that origin. After its last valid observation, a modeled
position goes to cash; the absence of separately supplied delisting returns is
reported as a data limitation rather than imputed.

Prospective Amendment 012 distinguishes fields used in structural construction
from fields unused by the returns-only postdecision calculation. Structural
rows still require usable close and nonnegative volume. A finite,
compoundable, `NA`-flagged postdecision total return is not dropped merely
because close or volume is unavailable: the unused field remains `missing`, is
never imputed, and is counted by origin. Dates, total returns, return flags,
ordering, and the first-row-only `NS` rule remain fail-closed.

Amendment 013 handles one separately classified terminal postdecision
missing-return row carrying CRSP flag `DP` and a positive delisting flag. The
row has no observed return and is never set to zero, reconstructed, or treated
as a complete outcome. The affected origin's nine secondary postdecision
records are instead marked unavailable, with all 63 algorithm rows retained in
denominators. Structural extraction remains fail-closed for this pattern, and
any nonterminal, non-postdecision-year, non-delisting, or differently flagged
missing return still stops execution.

Ignored local artifacts may include origin eligibility audits, prepared return
panels, strategy specifications, capability-carrier maps, instances, solver
logs, and run records. Public promotion may copy only aggregates that pass a
schema whitelist and row-level licensed-data audit.

Under prospective Amendment 011, prepared return panels are stored as three
Snappy-compressed Parquet partitions under the ignored local-data root. Their
terminal sidecars bind them to the execution lock, origin windows, source-file
stat fingerprints, schemas, row counts, and Parquet hashes. These local
partitions remain licensed and nonredistributable. The downstream analysis
Parquet files are separate: they contain only registered identifiers,
aggregate measures, algorithm diagnostics, exact certificates, and
postdecision summaries, and an independent audit rejects prohibited raw-row
fields.
