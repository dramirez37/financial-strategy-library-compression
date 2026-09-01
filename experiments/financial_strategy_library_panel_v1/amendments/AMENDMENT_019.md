# Amendment 019 — exact MIP warm-start projection correction

**Date:** 2026-09-01

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

The passing Lock 018 result audit retained 94 registered HiGHS rows with status
`ERROR`. Inspection after the audit showed one common implementation failure:
the original-coordinate weighted-greedy warm start was projected onto the
preprocessed MIP by simply dropping every eliminated strategy. That operation
need not preserve coverage when a selected strategy was removed by duplicate
or dominance preprocessing. The preprocessor already records a deterministic
elimination target for exactly these substitutions, but the MIP adapter did
not follow it.

This amendment corrects only that adapter. A selected eliminated strategy now
follows the acyclic exact elimination-target chain until it reaches a residual
strategy or a forced selection. Strategies removed for empty residual
contribution need no substitute. The projected residual must cover every
remaining tagged requirement exactly, and its exact offset-plus-residual
burden may not exceed the supplied feasible warm-start burden. Any violation
fails closed before HiGHS is called.

The failure and the availability of all prior outcomes are disclosed rather
than treated as prospective ignorance. The corrective run preserves all six
unaffected algorithm records per successful instance and reruns only the 94
invalid MIP rows. The 14 already valid MIP rows remain unchanged. The
independent audit must observe zero algorithm errors, 108 exactly feasible MIP
candidates, and exact MIP--DP burden agreement on every successful instance.
Postdecision records are refreshed so a newly available MIP selection receives
the same registered diagnostic treatment as every other algorithm. All 180
analysis partitions are rematerialized from the corrected audited sources.

No instance, source row, library construction, burden schedule, seed, time
limit, solver setting, estimator, denominator, table, figure, or claim boundary
changes. Lock 018 and its adverse 94-row failure record remain immutable
historical artifacts. No raw licensed row is printed, committed, or promoted.

