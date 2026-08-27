# Financial algorithm comparison amendment 004

Recorded: 2026-08-27, after the amendment-003 execution stopped and before any
new algorithm call, comparison outcome, or local result artifact.

The run reconstructed the terminal source and built its first exact weighted
instance. It then stopped during keyword type validation for the comparison
call. A line break after Julia's `return` keyword made the held-out unit helper
return `nothing`; consequently, the comparison function body was never entered.

This amendment replaces the two line-broken expressions with explicit
`if`/`elseif` string returns and adds direct tests that both audit units are
strings, are distinct, and reject an unknown audit. It does not change any
financial observation, source, profile, weight, algorithm, control, seed,
time limit, tie rule, estimand, information boundary, or output schema. No
algorithm result was available when this implementation-only repair was made.
