# Financial Innovation-Challenge Panel v2 — execution amendment 004

Execution attempt 004 completed the source audit, point-in-time decision scan,
liquidity scan, and SPY reference-state cache. It then stopped in the
profile-support scan because the implementation treated every non-initial
missing return as a run-fatal error. The observed values were recognized CRSP
missing-return reasons. No profile-support result was completed, and no score,
seed, docket, menu, arm, solver result, or postdecision outcome was opened.

The partial environment record, source audit, and six SPY-cache files are
renamed with an immutable `FAILED_ATTEMPT_004` prefix and hash-bound into the
successor execution lock. They are not reused by the revised scientific run.

The user then directed that the complete dataset be built first and that
equities without complete usable data be removed. Because that instruction
changes eligibility rather than merely repairing control flow, it is governed
by `DESIGN_AMENDMENT_001`, not hidden inside this execution amendment.

The successor runner stages one nonduplicated 2000--2025 master panel of
eligible common equities and plain ETFs from the three registered raw files
concurrently. It writes bounded local Parquet chunks so memory is independent
of the 20-year row count. Every origin view, completeness census, SPY-state
construction, strategy evaluation, and predecision docket is derived from
that same hash-sealed dataset. Scientific loaders enforce origin-specific date
cutoffs; the postdecision loader remains disabled until the predecision seal.

Known CRSP missing-return reasons remain explicit missing values in the staged
panel. They are never filled, reconstructed, or converted to zero. Unknown or
contradictory codes abort. Per-file work is isolated on Julia threads, and
partitions are merged only in registered source-file order.
