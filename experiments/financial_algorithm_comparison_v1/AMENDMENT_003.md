# Financial algorithm comparison amendment 003

Recorded: 2026-08-27, after the first amendment-002 execution stopped and
before any source reconstruction, new algorithm dispatch, comparison outcome,
or local result artifact in that execution.

The run verified the comparison design lock, resource design lock, and parent
artifact hashes, then stopped while reading the registered weight schedules.
In TOML, bare keys following `[failure_rules]` remain members of that table.
The unchanged four-element `registered_weight_schedules` array had therefore
been serialized under `failure_rules`, while the runner expected this design
field at the document root.

This amendment moves the unchanged schedule array above the first table header
and adds an exact value-and-order assertion to the lock validator. It does not
change an audit, source, weight, algorithm, control, seed, time limit, tie rule,
information boundary, estimand, or output schema. No comparison result was
available when this implementation-only correction was made.
