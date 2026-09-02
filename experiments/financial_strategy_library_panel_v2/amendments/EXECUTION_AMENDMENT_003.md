# Execution Amendment 003 — provisional return-shape correction

Execution Lock 003 completed the source audit, decision-date scan, and
liquidity scan. The next function attempted to access the in-memory provisional
result by field name and stopped because the producer had returned the same five
objects as an unlabeled tuple. No provisional object was serialized; profile
support, source dockets, registered seeds, strategy scores, solvers, menus,
postdecision fields, and scientific results had not been opened or computed.

This prospective execution-only amendment changes the return expression from
an unlabeled five-tuple to a named five-tuple with fields `origins`,
`decisions`, `reference_permnos`, `candidates`, and `exclusions`. Values,
ordering, types, and downstream rules are unchanged. Execution Lock 004 binds
the one-line correction and the preserved attempt-003 records before restart.
