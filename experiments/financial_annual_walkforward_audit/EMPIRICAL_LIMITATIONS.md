# Empirical Limitations

- **No alpha claim.** The outcome is mechanism coverage, not expected return or a tradable portfolio estimate.
- **Licensed inputs.** CRSP/WRDS rows and row-level derivatives are excluded. Aggregate artifacts are publishable; reviewers supply licensed files.
- **Point in time.** Date-valid identifiers and lagged signals are used, but the CRSP snapshot is not revision-timestamped.
- **Survivorship.** The 100 funds are same-PERMNO ETFs classified at both 2008 and 2024 endpoints. This avoids ticker splicing but is not survivorship-free.
- **Universe iteration.** The first outcome-blind name-keyword pass admitted complex trust products because CRSP omitted product names. Before any return was parsed, the rule was amended to exclude ProShares and Direxion trusts wholesale. Both audit files and the final selection hash are retained.
- **Lock amendments.** The initial analytical design was frozen before return extraction. A-001 changed only sparse target-state support handling after a support abort and before any ranking result was produced; A-002 through A-007 are report-only. The immutable lock chain is retained.
- **Retrospective lock.** Each annual decision is code-separated and hashed before its target statistics are accessed, but 2020--2024 is historical rather than a live prospective trial.
- **Inference.** Five annual bootstrap units provide limited uncertainty resolution and do not absorb design, grammar, universe, or data-revision uncertainty.
- **Costs.** 1/5/10 bp one-way costs omit time-varying spreads, impact, capacity, taxes, financing, and operational constraints.
- **Finite grammar.** The 9600 strategies are fully enumerated and module-representable. No unrestricted or LLM-generated code is used.
- **Theorem boundary.** S4 proves an exact fixed-candidate occupation identity for supplied gaps. It does not prove empirical gap estimation, transition estimation, ranking consistency, set-selection optimality, or market performance.
- **Negative results.** The terminal-audit adverse ranking and any annual walk-forward negative or mixed comparison remain reported; no post-outcome redesign is permitted.
