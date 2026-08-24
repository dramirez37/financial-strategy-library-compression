# Annual Walk-Forward Financial Audit

This is the annual walk-forward audit. It does not overwrite or reinterpret the
adverse 25-ETF terminal-audit result.

The universe audit selects 100 endpoint-stable ETFs without parsing returns.
The empirical stage enumerates a finite 9,600-strategy grammar and evaluates
five annual walk-forward decisions. The primary rule scores state-gap coverage
under predicted belief occupation and selects a top-five set by sequential
marginal coverage. The target is analogous next-year realized gap coverage,
not portfolio return.

Run from the repository root with the pinned Julia 1.12.6 binary:

```sh
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/audit_financial_annual_universe.jl
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/freeze_financial_annual_walkforward_audit.jl --check
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/prepare_financial_annual_walkforward_audit_data.jl
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_financial_annual_walkforward_audit.jl
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/run_financial_annual_walkforward_audit.jl --check
```

The scripts download nothing. Raw and row-level CRSP/WRDS derivatives remain
ignored; reviewers provide independently licensed input files. The committed
directory contains the universe audit, exact selection manifest, immutable
lock/amendment chain, aggregate results draft, data audit, and limitations
note. Aggregate tables and figures are under `experiments/results/summaries/`
and `manuscript/figures/`.
