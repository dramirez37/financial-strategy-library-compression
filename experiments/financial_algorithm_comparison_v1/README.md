# Retrospective financial algorithm comparison v1

This directory holds the public design boundary for applying the journal
compression algorithms to the two already locked financial source audits.
The comparison is retrospective. It makes no causal, forecasting, alpha, or
deployable-performance claim.

`local_results/` is intentionally ignored. It may contain exact aggregate
optimization instances, selected-library certificates, and solver logs, but
never raw CRSP/WRDS rows. Public aggregate promotion is a separate, manual
step after the nonmutating audit passes and the data-rights policy is checked.
`make aor-financial-algorithm-promote` enforces the aggregate schema, complete
audit/schedule/algorithm grid, exact-certificate fields, and separate terminal
and annual units before writing the rights-cleared public summary, status, and
generated results report.

The existing terminal, annual walk-forward, and cross-audit scripts and their
design locks remain unchanged.
