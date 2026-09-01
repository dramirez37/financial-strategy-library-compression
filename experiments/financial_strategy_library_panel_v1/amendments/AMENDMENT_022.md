# Amendment 022 — correct the environment successor guard

**Date:** 2026-09-01

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

The first Lock 021 execution attempt stopped before solver work. The saved
environment belonged to Lock 020 and the complete prelock state matched the
state sealed by Lock 021, including 756 algorithm checkpoints and 18 solver
logs. The runtime successor guard nevertheless retained the earlier expectation
of 14 solver logs and rejected the valid state. The four additional logs are the
four terminal Lock 020 MIP checkpoints explicitly sealed by Lock 021.

This amendment replaces the stale count-only check with an exact recovery
fingerprint: the Lock 020 environment hash, result and analysis audit hashes,
instance and origin counts, terminal structural records, postdecision state,
checkpoint count and directory aggregate, and solver-log count and directory
aggregate must all match the Lock 021 prelock state. A synthetic regression test
requires the sealed 18-log state to pass and the stale 14-log state to fail.

No solver was started and no new empirical outcome was produced or inspected
before this amendment. No instance, source row, library, burden, seed, solver
setting, time limit, algorithm definition, candidate, estimand, denominator, or
analysis rule changes. Locks 020 and 021 and all persisted records remain
immutable. No raw licensed row was printed, committed, or promoted.
