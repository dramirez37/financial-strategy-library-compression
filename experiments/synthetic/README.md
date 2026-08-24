# Synthetic Experiments

Exact and numerical finite examples are registered through committed configs
and generated into `experiments/results/`. The comprehensive controlled suite
is `theorem-mechanism-controlled-suite-v2`, configured by
`experiments/configs/theorem_mechanisms.toml` and reported in
`experiments/results/SYNTHETIC_REPORT.md`.

The suite deliberately validates mechanisms rather than profitability. Its
exact A--F fixtures isolate quotient invariance, frontier/closure channels,
safe deletion, frontier-only loss, value decomposition, and coverage geometry.
Family F additionally contains a prospective exact ranking construction fixed
before execution: the target is S4's date-first gross fixed-candidate value,
not a fitted return outcome. It checks ranking identity, a top-two separation
condition under bounded score error, its failure outside that condition, and
redundancy-aware marginal selection. Its seeded Float64 G family maps solved
continue/research policies under cost, delay, persistence, and discount
changes. Version 1 remains available in Git history; version 2 does not alter
or reinterpret the locked 25-ETF analysis.
