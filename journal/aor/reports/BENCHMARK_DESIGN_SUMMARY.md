# Benchmark Design Summary

## Registered study

**Registered Algorithmic Compression Benchmark v1** is a prospective synthetic
study of identity-closure innovation-safe strategy-library compression. It
contains 173 final instances and explicitly excludes financial-population,
causal, forecasting, alpha, and deployable-performance claims.

The benchmark is separate from the frozen N=1024 randomized study. It has a new
directory, configuration, instance registry, seed registry, and design lock. No
old seed, registry row, design lock, amendment, or result is an input.

## Final design

| Family | Final N | Registered role | Exact reference |
|---|---:|---|---|
| A: small exact | 24 | Cross-method correctness and exact heuristic gaps | Enumeration, DP, and exactly rechecked HiGHS |
| B: structured | 128 | Scaling and structural-factor comparison | Exactly feasible HiGHS reference when solver-reported optimal; not exhaustive/formal proof; otherwise bound diagnostics |
| C: adversarial | 21 | Seven mechanism-specific stress families at three scales | Exact algorithms where registry limits permit; analytical ratio only where already proved |

Family B crosses two strategy counts, two tagged-requirement counts, a 16-cell
pairwise-balanced structural array, and two replicates. It varies frontier and
module row counts, density, overlap, bundles, unique carriers, weights, and
frontier-module correlation. Family C registers the unbounded deletion gap,
many ties, dense duplicates, dominance, rare mandatory rows, cyclic symmetry,
and competing bundle/singleton mechanisms.

Three trivial dry-run rows and eleven pilot rows have separately derived seeds
and are excluded from final analysis.

## Algorithms and certification

The registered suite contains complete enumeration, requirement-mask DP, JuMP/
HiGHS, weighted and cardinality greedy methods, reverse deletion, five
deterministic certified-deletion orders, random-order deletion, and 32-start
random deletion.

Every returned library is rechecked in original coordinates for exact burden,
mandatory retention, tagged coverage, frontier equality, and identity closure.
Every deletion result receives a complete irreducibility scan. Small rows must
pass the independent enumeration/DP/HiGHS exactness layer. Different optimizer
identities at equal exact burden are reported rather than treated as errors.

HiGHS is single-threaded with parallel mode off, presolve on, zero registered
MIP gap tolerances, a registered seed, a size-specific time limit, and a complete
saved log. Solver `OPTIMAL` remains solver evidence, not formal proof.

## Primary outcomes

- exact relative burden gap and exact optimum attainment on exact-reference rows;
- separately labeled MIP-reference gap and attainment on structured rows;
- solved fraction retaining failures and timeouts;
- wall-clock time and PAR-2;
- HiGHS node count and bound diagnostics;
- DP state and transition counts;
- per-rule and total preprocessing reduction; and
- frontier and closure evaluation counts for deletion algorithms.

Primary summaries are finite-registry descriptions. Registered models use
paired instance blocks, main effects, limited size interactions, HC3 standard
errors, and explicit nonconvergence reporting. They do not support population
claims about real financial libraries.

## Resource and computational risk

| Component | Risk | Registered control |
|---|---|---|
| Family A enumeration | Low to moderate | At most 14 optional strategies (`2^14` subsets), 300 s, 16 GiB |
| Family A DP | Low | At most 10 tagged rows (`2^10` masks), 300 s, 16 GiB |
| Family B medium cell | Moderate | 64 strategies/32 requirements, 900 s per MIP variant |
| Family B large cells | High | 192 strategies or 64 requirements, 1,800 s per MIP variant |
| Family C small | Low to moderate | Exact methods only where registry flags permit |
| Family C medium/large | Mechanism-dependent, potentially high | 900/1,800 s MIP limits; no reruns |
| Random multistart | Moderate aggregate cost | Exactly 32 registered starts; 120–900 s family-size cap |

Family B contains 32 medium and 96 large rows. With two registered MIP
preprocessing variants, the serial worst-case MIP time cap is 112 hours before
heuristics. This is a resource ceiling, not a runtime prediction. The final run
must therefore be treated as a declared benchmark gate and must not begin until
the generator, runner, memory enforcement, artifact schemas, and pilot have all
passed.

Timeouts, memory limits, generator failures, solver errors, and certificate
failures remain in denominators. No failed row is replaced. Exact-method
disagreement stops the affected batch and produces a minimized fixture.

## Preprocessing comparison

The primary MIP uses full fixed-point preprocessing. A paired MIP experiment
compares mandatory-only against full preprocessing. Family A pairs the same
variants for DP. Primary heuristic comparisons use mandatory-only preprocessing;
a separately labeled sensitivity applies the full preprocessor and reconstructs
solutions.

The final benchmark is blocked until the MIP workflow exposes the registered
mandatory-only variant. This specification does not claim that all execution
support already exists.

## Registration and lock

The lock script deterministically renders both registries, verifies 187 total
rows (3 dry, 11 pilot, 173 final), checks all 935 registered seed values for
uniqueness and phase separation, checks Family B balance, validates required
files and absent outcome paths, and runs only three trivial in-memory exactness
fixtures. It then hashes:

- the design;
- analysis plan;
- reporting rules;
- instance and seed registries;
- benchmark config;
- this summary; and
- the lock script itself.

No final benchmark was run while preparing or locking this design. Any later
change requires a numbered prospective amendment preserving the initial lock and
disclosing outcomes already seen.

## Execution prerequisites still absent

The present task registers the study but intentionally does not implement or run
the final benchmark. Before pilot execution, a later task must implement and
test:

- the structured and all adversarial generators;
- the result schema and full benchmark runner;
- mandatory-only versus full MIP execution;
- hard memory-limit monitoring and hardware capture;
- deterministic algorithm-order rotation;
- complete run/certificate/log hashing; and
- analysis and figure generation from committed artifacts.
