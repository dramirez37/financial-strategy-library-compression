# Counterexamples

`FrontierPruningLoss.lean` gives an exact one-belief, one-project construction
showing why frontier-only pruning is not innovation-safe. A zero-payoff bridge
is operationally redundant but uniquely carries the module that makes a
high-value future strategy reachable.

At horizon two and discount one half, the exact pruning loss is half the
future strategy's reward. Reward scaling yields arbitrarily large loss, while
a cap `C` gives the sharp maximum `C / 2` within this fixed construction.

The publication-facing normalized theorem is now
`Compression/NormalizedPruningLoss.lean`. It makes the exact
`β^d ρ^d π C - κ` cap formula primary and retains this file's arbitrary loss
only as a reward-scaling specialization.

`MultiGapRegion.lean` gives an exact five-belief construction in which one
project yields two candidate strategies that fill separated endpoint gaps.
Under the degree-four Bernstein/binomial transition kernel, their aggregate
potential is `(4, 41/32, 1/2, 41/32, 4)`. At constant cost one, the strict
one-shot cost-covering set is `[0,1] ∪ [3,4]` and is therefore disconnected.
The same file proves that unrestricted belief-dependent costs defeat any
cost-covering component bound based on the kernel alone. Neither statement
characterizes an optimal Bellman research region.
