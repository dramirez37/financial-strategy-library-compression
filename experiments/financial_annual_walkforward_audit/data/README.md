# Local licensed annual-audit input

This directory is an input contract, not a distributed dataset. Run the annual
preparation script against an independently licensed CRSP/WRDS extract. The
generated ETF panel, extraction audit, and completed provenance record remain
ignored because they contain row-level licensed derivatives.

Place an independently licensed source under `../../../data/licensed/crsp/`
and set `ALGOLIB_CRSP_ROOT=data/licensed/crsp`, or use the relative source root
already declared in the committed configuration. Required source paths and
column contracts are in `../../../DATA_ACCESS.md`. The scripts do not download
data or substitute synthetic observations. Missing licensed inputs terminate
with:

```text
Licensed CRSP/WRDS inputs are not distributed with this repository. See DATA_ACCESS.md.
```
