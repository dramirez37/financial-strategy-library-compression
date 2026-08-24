"""
    DEFAULT_RESEARCH_SEED

Repository-wide default seed for infrastructure smoke tests. Manuscript
experiments must still record an explicit seed in their committed
configuration.
"""
const DEFAULT_RESEARCH_SEED = UInt64(20260720)

"""
    research_rng(seed::Integer=DEFAULT_RESEARCH_SEED)

Construct a `StableRNG` for deterministic research computation. Stochastic
algorithms should accept an RNG or explicit seed rather than mutate Julia's
global RNG.
"""
research_rng(seed::Integer = DEFAULT_RESEARCH_SEED) = StableRNG(seed)
