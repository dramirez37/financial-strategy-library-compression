# Execution Amendment 002 — bounded deterministic concurrency

The Execution Lock 002 recovery successfully completed source hashing and
schema validation. During the following decision-session scan, the operator
observed that only one of eight Julia threads was active and stopped the run.
The scan had parsed source rows and held partial decision-date maxima only in
memory. It had not completed a universe, written local data, consumed a seed,
evaluated a strategy, called a solver, opened a postdecision window, or
produced a scientific result.

This prospective execution-only amendment parallelizes independent work while
preserving registered order and deterministic reductions:

1. scan the three nonoverlapping registered daily source files concurrently,
   keep file-local decision, liquidity, support, and ordering state, and merge
   results in the registered file order;
2. use the existing origin-scoped Parquet extractor for reference, structural,
   and postdecision panels; it scans source files on Julia threads and merges
   partitions in registered order;
3. evaluate independent origins concurrently; schedules remain serial within
   an origin and each HiGHS model remains single-threaded; and
4. evaluate independent postdecision origin--docket cells concurrently.

Threaded reductions concatenate file-local liquidity observations in source
file order, sum integer support counts, and take the maximum decision date.
They therefore preserve the serial result exactly. No design, threshold,
registry, arm, menu, seed, burden, estimand, availability gate, or reporting
rule changes. Execution Locks 001 and 002 remain immutable; Execution Lock 003
binds this amendment and both preserved pre-outcome attempt records.
