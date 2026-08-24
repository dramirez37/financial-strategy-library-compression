# Terminal Financial Audit

This directory contains the bounded terminal ETF audit. It uses the
finite module grammar and frozen development/validation/locked protocol in
`experiments/configs/financial_terminal_audit.toml`. It does not use unrestricted
strategy generation and is not a return-prediction or market-alpha study.

Read `DATA_AUDIT.md` first. The audited source is an existing local licensed
CRSP/WRDS extract in the sibling `curv-risk` repository. Raw and row-level data
are nonredistributable. Aggregate tables, figures, reports, and metadata are
publication artifacts under D-0041. The local ETF derivative and completed
provenance record remain under the ignored `data/` directory.

From the repository root, reproduce the local extract and run the illustration:

```sh
julia --project=julia julia/scripts/prepare_financial_terminal_audit_data.jl
julia --project=julia julia/scripts/run_financial_terminal_audit.jl
julia --project=julia julia/scripts/run_financial_terminal_audit.jl --check
```

The extractor performs no download. It verifies source existence, date-valid
ETF/PERMNO links, schemas, required values, date bounds, and source checksums.
The committed universe is sufficient for a licensed CRSP reproduction; if the
ORATS inventory is present, the extractor also re-audits the origin of the
frozen covered-ticker list.
The experiment records all 2,400 candidates across 25 ETFs and every pruning decision, writes
summary and figure-data tables, creates three SVG figures from the script, and
fails if a formal expected compression identity is violated.

Deliverables:

- `DRAFT_RESULTS.md`: data-driven 2–3 page draft results section;
- `EMPIRICAL_LIMITATIONS.md`: empirical and licensing limitations;
- `manuscript/sections/financial_terminal_audit.tex`: generated manuscript draft;
- `experiments/results/summaries/financial_terminal_audit_*.csv`: candidate,
  pruning, ranking, decomposition, uncertainty, cost, and figure data; and
- `manuscript/figures/financial_terminal_audit_*.svg`: script-generated figures.

The committed complete-run status is
`empirical_complete_aggregate_publishable`. This permits public use of
aggregate artifacts only; it does not permit redistribution of the ignored
licensed inputs or strengthen the point-in-time and alpha-claim boundaries.
