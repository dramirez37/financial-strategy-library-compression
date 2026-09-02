# Execution Amendment 001 — gzip header-drain recovery

The first licensed execution attempt terminated during the required-schema
check. The reader opened the first compressed daily file, read only its header,
and closed the pipe. The `gzip` producer then returned `EPIPE`, which Julia
correctly treated as an I/O failure. No daily data row was parsed, no universe
was constructed, no registered seed was consumed, no candidate score or arm
was computed, and no postdecision field or scientific outcome was observed.

This prospective execution-only amendment makes two changes:

1. after reading and validating each compressed-file header, drain the stream
   without parsing or retaining its rows so the producer exits successfully;
2. permit a restart only when the local result root contains the preserved
   `FAILED_ATTEMPT_001_ENVIRONMENT.toml` record and no other prior artifact.

No design input, eligibility rule, threshold, menu rule, arm, burden, scenario,
estimand, availability gate, or reporting rule changes. Execution Lock 001
remains immutable; Execution Lock 002 binds this amendment, the corrected
runner, the predecessor lock, and the preserved failure record before the run
resumes.
