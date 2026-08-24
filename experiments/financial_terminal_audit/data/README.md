# Local Financial Inputs

Local licensed inputs and completed provenance records are ignored by Git and
must not be redistributed. Read `../DATA_AUDIT.md` before rebuilding them.

Local files produced or consumed by the pipeline:

- `etf_daily.csv`: one row per `(date,ticker)` with `date`, `ticker`,
  `total_return_index`, `close`, and `volume`;
- `provenance.toml`: a completed copy of `provenance.template.toml` whose
checksum matches `etf_daily.csv`;
- `source_extract_audit.csv`: per-ticker row, date, missingness, and flag audit.

The preparation script reads only the independently licensed source declared in
the committed configuration, or the source root selected by
`ALGOLIB_CRSP_ROOT`, and never downloads data. The recommended public-clone
layout is `../../../data/licensed/crsp/`; the exact source paths and required
columns are documented in `../../../DATA_ACCESS.md`. The runner fails closed on
absent or incomplete provenance. Missing licensed source files produce:

```text
Licensed CRSP/WRDS inputs are not distributed with this repository. See DATA_ACCESS.md.
```

No synthetic substitute is used. Compact results and metadata retain the source
identity, license classification, checksum, period coverage, exclusions, and
decision hash. ORATS is optional because the publication configuration already
freezes the ticker/PERMNO universe.
