# Certified rechecked-deletion algorithm suite

Status: implemented and targeted-test verified

Evidence class: exact finite heuristic computation with human-readable
invariant argument; no global-optimality, solver-status, Lean-verification, or
runtime-scaling claim

## Scope and common API

`solve_journal_compression_deletion(instance; algorithm, ...)` is the common
entry point for every journal deletion method. It accepts the validated
`journal-compression-instance-v1` schema, starts from the complete source
library, retains every mandatory strategy, and returns the common
`journal-compression-certified-deletion-v1` result.

The result contains:

- the original-coordinate selection and selected strategy identifiers;
- exact `Rational{BigInt}` burden;
- every accepted deletion with before/after selections, exact burden release,
  rule score, and exact semantic checks;
- paired counts of frontier and closure recomputations;
- the number of complete candidate scans;
- scoped nanosecond runtime instrumentation;
- the master random seed and winning order where applicable;
- an independent exact endpoint feasibility certificate; and
- the complete final one-deletion irreducibility scan.

The legacy raw-library routine `innovation_safe_prune_fixed_point` remains
available for compatibility and for explicitly supplied nonidentity closure.
The journal suite is integrated with the common identity-closure instance
schema so it can share exact solvers, preprocessing-independent identifiers,
financial converters, and benchmark inputs without duplicating semantic data.

## Rechecking discipline

At complete scan $q$, every retained nonmandatory strategy $s$ is tested by
forming the trial selection $S_q\setminus\{s\}$. The implementation then
recomputes, from original profiles and module memberships:

1. mandatory retention;
2. complete tagged coverage;
3. exact equality with the source operating frontier;
4. exact equality with the source identity closure; and
5. exact burden.

Only a trial passing all checks is eligible for deletion. The accepted trial's
certificate is copied into the deletion trace. After a deletion, all other
candidate certificates are discarded and a new complete scan is performed.
Thus no certificate from a larger retained library is reused after the state
changes.

The first complete scan with no safe candidate is the mandatory final
irreducibility scan. Its per-strategy failed-deletion checks are retained in
the result. An additional endpoint check certifies the returned library itself.
Consequently, for a run with $A$ candidate-deletion attempts, the result
records $A+1$ frontier checks and $A+1$ closure checks; the added pair is
the final endpoint certificate. A complete scan includes every currently
retained nonmandatory strategy, including the empty scan when none remains.

## Deterministic variants and tie rules

All rules choose only among candidates already certified safe in the current
complete scan.

| Algorithm symbol | Primary score | Deterministic tie rule |
|---|---|---|
| `heaviest_safe_first` | Maximum exact strategy weight | Lowest canonical original strategy index |
| `lightest_safe_first` | Minimum exact strategy weight | Lowest canonical original strategy index |
| `maximum_immediate_burden_release` | Maximum exact burden released by the deletion | Lowest canonical original strategy index |
| `minimum_remaining_unique_carrier_exposure` | Minimum remaining unique-carrier exposure | Maximum exact burden release, then lowest canonical original strategy index |
| `declared_source_order` | Earliest position in the complete declared order | The order is a permutation, so no residual tie exists |

Under the additive burden $W(S)=\sum_{s\in S}w_s$, deleting one strategy
releases exactly $w_s$. Therefore maximum immediate burden release and
heaviest-safe-first are identical algorithms on this schema. They are exposed
separately because the experiment design names both interpretations, but the
paper and result metadata must not present them as independent methods.

If no source order is supplied, `declared_source_order` uses increasing
original indices, which are the schema's canonical stable strategy order. A
caller-supplied order must list every nonmandatory original index exactly
once; partial or duplicate orders are rejected.

### Remaining unique-carrier exposure

For current selected set $S$, a certified-safe deletion candidate $s$, and
the fixed tagged universe $U_L$, define

\[
 E(s\mid S)
 =\left|\left\{u\in U_L:
   \sum_{t\in S\setminus\{s\}}\mathbf 1\{u\in R_t\}=1
 \right\}\right|.
\]

The rule minimizes $E(s\mid S)$. This quantity uses only the declared source
frontier/module incidence and the current retained set. It uses no dynamic
value, realized return, held-out financial quality, descendant outcome, or
forecast. Frontier and module tags receive equal unit counts; alternative
weights would define a different algorithm and require prospective
registration.

The score is a structural fragility heuristic, not a theorem that fewer unique
carriers produces lower final burden. Its secondary preference for larger
exact burden release is declared explicitly.

## Stochastic variants

`random_order_rechecked_deletion` uses `StableRNG(seed)` to generate one
permutation of all nonmandatory original indices. At each fresh complete scan,
it deletes the earliest currently safe strategy in that fixed permutation.
The result records the `UInt64` seed and the full permutation.

`multistart_random_deletion` runs a positive declared number of separately
seeded random-order endpoints. The master seed is also the first run seed;
later run seeds are generated deterministically by `StableRNG(master_seed)`.
Every run is feasible and irreducible before it is eligible for comparison.
The method retains the endpoint of minimum exact burden, breaks equal-burden
ties by the lexicographically smallest selected-index tuple, and retains the
earliest start when both are identical. Per-start seeds, orders, endpoint
selections, burdens, deletion counts, counters, and certification booleans are
returned.

Randomness changes deletion order only. It does not alter the instance,
feasibility test, source state, weights, or final certification.

## Safety versus optimization quality

Every returned endpoint has exact source frontier and closure equality and is
one-deletion irreducible. These facts establish safety and local terminality,
not minimum burden. Exact enumeration or requirement-mask dynamic programming
remains the small-instance optimization oracle.

The parameterized singleton--bundle family is the controlling regression:
heaviest-safe-first and maximum immediate release delete the bundle first and
return burden $k$, whereas the exact optimum is the bundle-only library of
burden $1+\epsilon$. Lightest-first, minimum unique-carrier exposure, and a
declared order beginning with a singleton reach the optimum on that family;
this is a property of the fixture, not a universal dominance claim.

No rule in this suite reads financial outcomes, held-out quality, dynamic
value, portfolio returns, or licensed rows. No algorithm has an approximation
guarantee unless a separate theorem supplies one.

## Runtime and experiment boundary

Runtime fields are single-run wall-clock measurements in nanoseconds. They are
returned because the future registered algorithm study needs a common result
schema. They are not benchmark findings and must not be transcribed into the
manuscript before a separate design, registry, seeds, and lock exist under
`experiments/algorithmic_compression_v1/`.
