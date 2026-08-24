# Local Licensed-Data Template

This directory is a public input contract, not a dataset. The repository does
not distribute CRSP, WRDS, ORATS, or any row-level financial observation.

Researchers with independent CRSP/WRDS access may create a local source root
under `data/licensed/`, for example:

```text
data/licensed/crsp/
  data/raw/crsp_a_stock/security_history/stksecurityinfohist.csv
  data/raw/crsp_a_stock/daily_security/stkdlysecuritydata_00_10.csv.gz
  data/raw/crsp_a_stock/daily_security/stkdlysecuritydata_10_20.csv.gz
  data/raw/crsp_a_stock/daily_security/stkdlysecuritydata_20_25.csv.gz
```

Point the preparation scripts at that root without changing a registered
configuration:

```sh
ALGOLIB_CRSP_ROOT=data/licensed/crsp julia --project=julia \
  julia/scripts/prepare_financial_terminal_audit_data.jl
ALGOLIB_CRSP_ROOT=data/licensed/crsp julia --project=julia \
  julia/scripts/prepare_financial_annual_walkforward_audit_data.jl
```

Everything below `data/licensed/` is ignored except `.gitkeep`. The scripts
perform no download and fail if the licensed source root or any required file
is missing. They write ignored row-level derivatives only to the experiment-
specific data directories documented in `DATA_ACCESS.md`.

## Required source schemas

The daily-security CSV files must contain these columns:

```text
permno,dlycaldt,dlyret,dlyclose,dlyprc,dlyvol,dlydelflg,dlyretmissflg
```

The security-history CSV must contain these columns:

```text
permno,secinfostartdt,secinfoenddt,ticker,securitytype,securitysubtype
```

The prepared local ETF panels have this schema:

```text
date,ticker,total_return_index,close,volume
```

These are column contracts only. No licensed observation, example row,
credential, vendor query, or connection string is included.
