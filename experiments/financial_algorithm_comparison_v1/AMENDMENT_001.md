# Financial algorithm comparison amendment 001

Recorded: 2026-08-27, after the first locked command failed and before any
parent audit, licensed-row read, algorithm execution, or new comparison result.

The first command verified the initial design lock, then failed while calling
the existing financial-resource module through a function that had lazily
loaded that module with `Base.include`. Julia 1.12 rejected the call because
the newly defined method was outside the caller's world age. The failure
occurred before parent-artifact verification and before any raw or aggregate
financial input was accessed by the comparison run.

The repair loads the same existing `FinancialResourceOptimization` module at
script load time. No source instance, weight, algorithm, tie rule, seed, limit,
solver control, information boundary, result field, failure rule, or analysis
rule changes. The test target uses the pinned package environment so the
existing JuMP and HiGHS dependencies are directly available during wrapper
tests. This is an implementation-only amendment.
