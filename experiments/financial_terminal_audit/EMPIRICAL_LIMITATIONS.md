# Empirical Limitations

Aggregate results are publication-ready; licensed inputs remain outside the replication package. The terminal financial audit is a retrospective mechanism audit and must not be described as evidence of market alpha.

- **Licensed source.** CRSP/WRDS rows and the local ETF extract are nonredistributable. The aggregate tables, figures, reports, and metadata may be published; reviewers reproduce them with their own licensed CRSP/WRDS extract.
- **Point-in-time boundary.** The CRSP snapshot preserves dated observations and date-valid PERMNO/ticker links, but historical corrections and corporate-action revisions are not revision-timestamped. It is point-in-time-conscious, not certified.
- **Survivorship and identifiers.** The 25 funds were fixed before CRSP return extraction, but all survive through the illustration end. The set uses 24 stable-identifier ORATS-covered ETFs plus SHY; SMH is excluded rather than spliced across two different CRSP funds. The universe is transparent rather than survivorship-free.
- **Holdout status.** The 2020–2024 period is code-locked in the protocol but is a retrospective holdout, not a prospective trial.
- **Costs.** The base 5 bp one-way turnover charge and 1/10 bp sensitivities are reduced-form assumptions; they omit time-varying spreads, impact, capacity, taxes, and implementation frictions.
- **Finite grammar.** Conclusions apply only to the 2400 enumerated long-only strategies and the declared module closure. They do not cover unrestricted search or LLM-generated code.
- **Inference.** Block-bootstrap intervals address serial dependence within one locked sample. They do not account for universe choice, grammar choice, multiple research iterations, or provider revisions.
- **Negative results.** Zero or adverse pruning and ranking comparisons are retained. No mechanism outcome is redefined after observing the locked period.
