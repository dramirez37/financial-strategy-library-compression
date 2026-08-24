# Data Access

**The financial audits use licensed CRSP/WRDS data. Raw and row-level licensed
data are not distributed.**

## Licensed source and publication boundary

The two financial mechanism audits use the CRSP US Stock Database daily
security and date-varying security-history products accessed through WRDS.
CRSP/WRDS source files, row-level observations, row-level derivatives, cached
vendor downloads, completed provenance records, and extraction audits are
licensed and are not distributed by this repository.

The public repository does not provide credentials, automate vendor login, or
bypass CRSP or WRDS access controls. An independent researcher must obtain and
use CRSP/WRDS data under their own institution's license. ORATS data are not
required for the registered audit replays; they are optional only for
re-auditing the origin of the frozen terminal-audit ticker inventory.

## Source files an independently licensed researcher supplies

For a registered raw-data replay, mirror the relative source layout declared
in `experiments/configs/financial_terminal_audit.toml` and
`experiments/configs/financial_annual_walkforward_audit.toml`. Relative to the source
root, the preparation scripts expect:

```text
data/raw/crsp_a_stock/security_history/stksecurityinfohist.csv
data/raw/crsp_a_stock/daily_security/stkdlysecuritydata_00_10.csv.gz
data/raw/crsp_a_stock/daily_security/stkdlysecuritydata_10_20.csv.gz
data/raw/crsp_a_stock/daily_security/stkdlysecuritydata_20_25.csv.gz
```

The committed configurations resolve that source root at:

```text
../curv-risk/curvrisk/research/bachelier_revision
```

This is a relative input contract, not a distributed sibling repository. A
public clone also provides the empty template `data/licensed/`. The recommended
local layout is `data/licensed/crsp/` followed by the four relative paths above.
Set the source root without changing a registered configuration:

```sh
export ALGOLIB_CRSP_ROOT=data/licensed/crsp
```

The environment variable changes only where the scripts look for independently
licensed inputs. It does not change a registered configuration, seed, design
lock, or numerical procedure. The preparation entry points still accept a
positional configuration path for nonregistered local work, but a changed
annual-audit configuration is not the registered experiment.

The source schemas and required fields are validated by the preparation
scripts. The daily-security files must contain:

```text
permno,dlycaldt,dlyret,dlyclose,dlyprc,dlyvol,dlydelflg,dlyretmissflg
```

The security-history file must contain:

```text
permno,secinfostartdt,secinfoenddt,ticker,securitytype,securitysubtype
```

The ignored prepared ETF panels contain:

```text
date,ticker,total_return_index,close,volume
```

The ignored extraction audits contain:

```text
ticker,permno,first_date,last_date,observations,duplicate_dates,missing_required_values,delisting_flag_rows,nonblank_return_missing_flag_rows,dlyprc_fallback_rows
```

These are column contracts only; the repository supplies no licensed example
row, identifier extract, query result, or vendor metadata table.

## Ignored local outputs

Preparation creates the following local, nonredistributable files:

```text
experiments/financial_terminal_audit/data/etf_daily.csv
experiments/financial_terminal_audit/data/source_extract_audit.csv
experiments/financial_terminal_audit/data/provenance.toml
experiments/financial_annual_walkforward_audit/data/etf_daily.csv
experiments/financial_annual_walkforward_audit/data/source_extract_audit.csv
experiments/financial_annual_walkforward_audit/data/provenance.toml
```

All six paths are ignored by Git. The only distributed files in those data
directories are `README.md` and `provenance.template.toml`. Do not add licensed
files to Git, archives, issue attachments, or public replication bundles.

## Preparation and replay commands

Run from the repository root with Julia 1.12.6 and the committed Julia
environment.

The complete licensed workflow is exposed through one explicit public target:

```sh
ALGOLIB_CRSP_ROOT=data/licensed/crsp make financial-licensed
```

It requires the independently licensed source root, runs the authoritative
preparation and audit scripts listed below, and never downloads or substitutes
data. The individual commands remain documented for inspection and focused
replay.

Terminal financial audit:

```sh
ALGOLIB_CRSP_ROOT=data/licensed/crsp julia --project=julia \
  julia/scripts/prepare_financial_terminal_audit_data.jl
julia --project=julia julia/scripts/run_financial_terminal_audit.jl
julia --project=julia julia/scripts/run_financial_terminal_audit.jl --check
```

Annual walk-forward financial audit:

```sh
ALGOLIB_CRSP_ROOT=data/licensed/crsp julia --project=julia \
  julia/scripts/audit_financial_annual_universe.jl
julia --project=julia julia/scripts/freeze_financial_annual_walkforward_audit.jl --check
ALGOLIB_CRSP_ROOT=data/licensed/crsp julia --project=julia \
  julia/scripts/prepare_financial_annual_walkforward_audit_data.jl
julia --project=julia julia/scripts/run_financial_annual_walkforward_audit.jl
julia --project=julia julia/scripts/run_financial_annual_walkforward_audit.jl --check
```

The preparation and audit scripts do not download CRSP, WRDS, ORATS, or any
other licensed data. They read existing local files, validate schemas and
registered identities, extract the fixed universes, write ignored local
derivatives and provenance, and fail closed when required inputs or metadata
are absent. Missing source inputs terminate with:

```text
Licensed CRSP/WRDS inputs are not distributed with this repository. See DATA_ACCESS.md.
```

No synthetic data are substituted for a missing licensed source.

## What is public without licensed access

The following redistributable materials can be inspected and checked without
CRSP/WRDS access:

- the configurations, universe selection, design locks, amendments, data
  audits, result narratives, and empirical-limitations records under
  `experiments/financial_terminal_audit/` and
  `experiments/financial_annual_walkforward_audit/`;
- public aggregate CSV and JSON outputs with prefixes
  `financial_terminal_audit_*`, `financial_annual_walkforward_audit_*`, and
  `financial_resource_optimization_*` under
  `experiments/results/summaries/`;
- the financial figures and generated table sources under
  `manuscript/figures/` and `manuscript/tables/`;
- committed status metadata, aggregate hashes, design hashes, and exact
  post-solve frontier/closure/burden certificates; and
- the paper and Online Supplement S6, which report the retrospective scope,
  adverse and mixed findings, and data limitations.

In a checkout without licensed inputs, `make verify` reports both raw-data
replays as skipped but still validates the redistributable aggregate hashes,
publication flags, design locks, synthetic regressions, certificates, and
manuscript artifacts.

These audits are retrospective mechanism diagnostics. They are not causal,
prospective, survivorship-free, forecasting, market-alpha, or deployable-
performance evidence.
