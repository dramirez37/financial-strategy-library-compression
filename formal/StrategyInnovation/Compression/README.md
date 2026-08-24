# Compression

`UnifiedSafeDeletion.lean` is the publication-facing T3 layer over the raw
generator, admission, update, T1 projection, and unified cost-sensitive
dynamic-equivalence model. It formalizes:

- raw operational and generative redundancy under one noninactive deletion;
- exact preservation of the realizable compressed state;
- all finite-horizon and contraction fixed-point values;
- pairwise stationary action-value comparisons and optimal actions;
- the detectable converse relative to unified raw-process observations;
- proof-relevant rechecked deletion traces; and
- a pruning function specification whose returned trace certifies every step.

`UnifiedSafeDeletionExamples.lean` supplies exact finite rational examples for
safe deletion, the two one-sided redundancy classes, duplicate encodings,
order-dependent retained identifiers, and failure of stale redundancy
certificates.

`NormalizedPruningLoss.lean` is the publication-facing T4 construction. It
derives descendant mass from the raw survival-gated generator and admission
law, proves the exact cost-sensitive loss
`β^d ρ^d π C - κ`, proves cap sharpness and full opportunity destruction,
records the unit-cap normalization, makes arbitrary loss only a scaling
corollary, and states the continued-operation reward-block adjustment.

`SafeDeletion.lean` remains the older abstract safe-deletion layer:

- operational and generative redundancy as exact invariance under deletion;
- compressed-state, dynamic-innovation, and finite-horizon value preservation
  as separate notions;
- the frontier--closure sufficient condition and the observation-level
  identifiable converse;
- proof-relevant repeated safe deletion and innovation-safe sublibraries;
- exact examples for the three possible redundancy combinations; and
- a zero-discount counterexample to the invalid value-only converse.

That older file is supporting family F3 over the primitive compressed
transition semantics. It is superseded for final-model use and is not an alias
for T3.
