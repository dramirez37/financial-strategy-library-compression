# Financial strategy library panel v3

V3 is the flagship economic redesign motivated by the sealed v2 falsification
audit. Julia is the implementation and orchestration language.

Current status: the retrospective 2000--2025 experiment is complete, audited,
and result-sealed. The common-equity safe policy equals its comparator in all
19 origins, so the primary held-out contrast is identically zero. The one
primary ETF replacement loses 0.038958 annual certainty equivalent in its
held-out year. This is a flagship design-validation and transparent null
result, not fresh confirmation of a return premium.

## Reproduce the current checks

```sh
make aor-financial-panel-v3-design-check
make aor-financial-panel-v3-source-census-check
make aor-financial-panel-v3-predecision-result-seal
make aor-financial-panel-v3-proposal-result-seal
make aor-financial-panel-v3-proposal-robustness-result-seal
make aor-financial-panel-v3-evaluation-result-seal
```

Set `JULIA_EXE` to Julia 1.12.6 when it is not the default executable. The
evaluation targets intentionally use only the amendment-aware staging, runner,
and result-seal entrypoints. The original execution lock remains preserved.

The canonical public result is
`evaluation_results/EVALUATION_RESULT_MANIFEST.toml`; the journal-facing
interpretation is
`journal/aor/reports/FINANCIAL_FLAGSHIP_V3_RESULTS.md`.
