# Financial Audit Taxonomy

The repository contains two complementary retrospective financial audits, not
two releases of one experiment. Public paths and commands therefore use
descriptive names:

| Reader-facing audit | Scope | Active namespace |
|---|---|---|
| Terminal audit | Fixed 25-ETF library with development, validation, and terminal 2020--2024 scoring periods | `financial_terminal_audit` |
| Annual walk-forward audit | Outcome-blind 100-ETF universe with five annual 2020--2024 decisions | `financial_annual_walkforward_audit` |
| Cross-audit resource optimization | Exact post-solve comparison of the two locked audits | `financial_resource_optimization` |

The former active namespaces were `financial_illustration`,
`financial_illustration_v2`, and
`financial_audit_resource_optimization_v1`. They were replaced only to remove
the misleading suggestion that one included audit supersedes another.

## Registration continuity

Historical schema strings, experiment identifiers, audit identifiers, and
pre-taxonomy design locks retain their original version markers. Those values
are immutable provenance identifiers, not reader-facing experiment labels.
The original active locks are preserved as `DESIGN_LOCK_REGISTERED.json` in
the annual walk-forward and cross-audit resource directories. Current
`DESIGN_LOCK.json` files bind the descriptive paths to the same registered
protocols and explicitly identify the change as taxonomy-only.

The migration changes no seed, date window, universe membership, strategy
grammar, cost assumption, pruning decision, selected library, solver result,
CSV row, numerical field, theorem, or empirical claim. No licensed-data
analysis is rerun to perform the rename. Path-derived hashes and command
metadata are refreshed from the renamed files, and the preserved registered
locks provide the backward link to the pre-migration namespaces.
