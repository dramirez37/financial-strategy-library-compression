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

Ignored local artifacts may include origin eligibility audits, prepared return
panels, strategy specifications, capability-carrier maps, instances, solver
logs, and run records. Public promotion may copy only aggregates that pass a
schema whitelist and row-level licensed-data audit.
