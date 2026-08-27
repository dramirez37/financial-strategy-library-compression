# Registered Algorithmic Compression Benchmark v1

## Registration statement

This document prospectively registers a synthetic algorithmic benchmark for
identity-closure innovation-safe strategy-library compression. No final
benchmark outcome was generated or inspected when the initial design was
written. The only pre-lock executions permitted are schema validation and the
three trivial dry-run fixtures defined below.

The study is computational evidence, not theorem evidence and not retrospective
financial evidence. Its sampling frame is the finite registered collection of
synthetic and adversarial instances. It makes no population claim about real
financial libraries, investment firms, trading strategies, returns, alpha,
forecasting performance, or deployable performance.

## Scientific question

For a source strategy library with identity module closure, how do exact,
mixed-integer, greedy, and certified-deletion methods compare in retained burden,
solution certification, scaling, and semantic-check cost as the tagged covering
structure changes?

Every instance has:

- a mandatory inactive strategy of weight zero;
- positive exact rational weights for active strategies, with integer weights in
  the structured random families;
- exact rational operating profiles;
- a finite tagged universe of frontier and module requirements;
- identity closure;
- stable strategy and requirement ordering; and
- provenance linking it to one registry row and one seed row.

The source frontier and source closure are computed before any algorithm is
run. Held-out financial outcomes, dynamic values, or empirical performance are
not inputs to generation, preprocessing, weighting, algorithm choice, or
optimization.

## Registered phases

The instance registry contains three phases.

1. `dry_run`: three trivial fixtures used before lock only to test schema
   round trips and the enumeration/DP/HiGHS audit path. They are never analyzed.
2. `pilot`: eleven instances run only after the initial lock to debug resource
   monitoring, runner behavior, output schemas, and failure capture. Pilot
   outcomes cannot change primary estimands and are never pooled with final
   results.
3. `final`: 173 instances constituting the registered benchmark.

Pilot, dry-run, and final seed domains are disjoint. Final seeds may not be used
during dry runs or pilots.

## Family A: small exact instances

Family A contains 24 final instances:

- strategy counts, including inactive: 7, 11, and 15;
- tagged requirement counts: 6 and 10;
- frontier rows: 2 when there are 6 requirements and 4 when there are 10;
- four registered structural replicates per size cell; and
- at most 14 optional strategies and 10 requirements.

Each instance must complete enumeration, requirement-mask DP, and HiGHS MIP
within the registered small-instance limits. Instances declare deterministic
representative tie handling so the one-incumbent MIP workflow remains valid.
Exact enumeration and DP additionally run with `retain_all_ties=true` up to the
registered 100,000-selection certificate capacity; the common exactness layer
compares deterministic representatives with the MIP representative. Every
heuristic gap is computed against the exact minimum burden. If either exact
method fails, the row remains a failed exact row and is not moved to another
family.

The four replicates rotate sparse/dense coverage, low/high module overlap,
low/high bundle prevalence, low/high unique-carrier frequency, low/high exact
integer-weight dispersion, and independent/aligned frontier-module incidence.
These levels provide small sanity checks; Family B, not Family A, is the
registered balanced structural design.

## Family B: structured medium and large instances

Family B contains 128 final instances. Four size cells cross strategy counts
64 and 192, including inactive, with tagged requirement counts 32 and 64. Each
size cell is crossed with a 16-row binary orthogonal array and two independently
seeded replicates.

The array is the complete `2^4` base design. The seven structural columns are
distinct nonzero GF(2) contrasts with masks `1, 2, 4, 8, 3, 5, 9`. Thus each
factor is balanced and every pair is balanced within each size cell. No
interaction is registered for estimation because higher-order aliases remain.

The prospective factors are:

| Factor | Low level | High level |
|---|---|---|
| Frontier-row share | 1/4 of tagged rows | 1/2 of tagged rows |
| Coverage density | target 1/8 | target 3/8 |
| Module overlap | low clustered | high clustered |
| Bundle prevalence | zero active bundles | 1/8 of active strategies |
| Unique-carrier frequency | zero rows | 1/8 of tagged rows |
| Weight dispersion | support 1, 2, 3 | support 1, 2, 4, 8, 16 |
| Frontier-module correlation | independent latent orderings | common aligned latent ordering |

Together with the size cross, the design varies strategy count, total tagged
requirements, frontier-row count, module-row count, density, overlap, bundle
prevalence, unique-carrier frequency, weight dispersion, and frontier-module
correlation.

### Structured generator contract

The generator operates only on registered structural inputs and seeds.

1. It creates the mandatory inactive strategy with weight zero, zero profile,
   and no modules.
2. Active frontier incidence determines exact binary profiles: one for an
   attaining strategy and zero otherwise. Every positive frontier row therefore
   has source frontier one.
3. Module incidence is used directly as raw module carriage. Closure is the
   identity, so the source closure is the union of those modules.
4. The overlap level controls whether module carriers are assigned through
   weakly shared or strongly shared latent clusters.
5. Registered bundle strategies receive coverage in every cluster before the
   remaining incidence is filled.
6. The registered unique-row fraction is imposed by selecting rows in stable
   requirement order and assigning exactly one carrier.
7. Independent correlation uses separately permuted latent propensities for
   frontier and module columns. Positive alignment uses the same propensity
   ordering. The realized rank-biserial association is recorded; the level is a
   generation mechanism, not a promised sample correlation coefficient.
8. Low-dispersion weights cycle over 1, 2, 3 after a seeded permutation.
   High-dispersion weights cycle over 1, 2, 4, 8, 16. Weights never depend on an
   algorithm outcome.
9. The realized nonmandatory incidence density must lie within 1/64 of its
   registered target, every requirement must have a carrier, and the realized
   unique and bundle counts must equal their registered integer rounding rules.

The generator examines structural gates only. It takes the first passing attempt
among 128 domain-separated attempt seeds. It may not examine optimum burden,
heuristic behavior, MIP nodes, runtime, or any other study outcome before
accepting an instance. Failure after 128 attempts is reported as
`GENERATION_FAILED`; the row is not replaced.

## Family C: adversarial mechanism families

Family C contains seven mechanisms at registered small, medium, and large
parameters, for 21 deterministic structural rows. A seed permutes labels and
declared source order only. The incidence and weights are fixed by the mechanism.

### Unbounded heaviest-safe-first gap

At parameter `k` in 4, 16, 64, construct `k` unit-weight singleton module
carriers and one bundle of weight `3//2` carrying all `k` modules. All profiles
are zero and inactive covers the zero frontier. This is the proved
bundle-versus-singleton family specialized to epsilon `1//2`. The registered
heaviest-safe-first burden ratio is `2k/3`. This family tests a proved mechanism,
not an empirical discovery.

### Many tied optima

At `q` in 4, 8, 16, create `q` equal-weight strategies with identical complete
coverage. Each individual active strategy is an optimum. Small exact runs retain
the complete optimizer list; larger rows retain registered tie counts and stable
representatives without claiming MIP enumerates all optima.

### Dense duplicate coverage

At duplicate counts 8, 32, and 128, create dense groups of identical columns
over 4, 16, and 32 module rows. Weights contain registered equal and unequal
subgroups so duplicate preprocessing must preserve a reconstruction map for
equal-weight ties while retaining a lower-weight representative for value
optimization.

### Dominance-heavy instances

At base dimensions 4, 12, and 32, create chains of nested coverage columns with
nonincreasing costs toward the superset end plus nondominated anchor columns.
The construction registers many removable dominated variables while preserving
at least two residual requirements after preprocessing.

### Rare mandatory requirements

At module counts 4, 16, and 64, add one mandatory active strategy that is the
only carrier of one tagged module row; all other rows have multiple carriers.
This tests mandatory semantics, forced propagation, and exact objective offsets.
It does not redefine the inactive strategy; inactive remains mandatory as well.

### Symmetric hard instances

At cyclic orders 7, 15, and 31, each equal-weight active strategy covers a
cyclic window of requirements and each row has the same number of carriers.
The label symmetry is intended to stress branching and tie handling. “Hard” is
the registered mechanism name; the study makes no advance claim that every size
or solver version will take long.

### Bundle-versus-singleton structures

At `k` in 4, 16, and 64, construct unit-weight singletons plus two overlapping
bundles whose exact weights straddle the singleton aggregate cost. Unlike the
unbounded-gap family, this mechanism tests near-ties and competing bundles. The
exact small optimum is determined by enumeration, not asserted by construction.

## Algorithms

The registered suite is:

- complete enumeration;
- exact requirement-mask dynamic programming;
- JuMP/HiGHS binary covering optimization;
- weighted greedy;
- cardinality greedy;
- weighted greedy followed by certified reverse deletion;
- heaviest-safe-first deletion;
- lightest-safe-first deletion;
- maximum immediate burden release;
- minimum remaining unique-carrier exposure;
- declared-source-order deletion;
- seeded random-order rechecked deletion; and
- 32-start seeded random deletion retaining the lowest-burden certified endpoint.

Enumeration and DP are mandatory for Family A and for any registered adversarial
row marked exact-capable. MIP and every heuristic are attempted on every final
row. A method that cannot apply is recorded as `NOT_APPLICABLE`; it is not
silently omitted.

Every accepted solver or heuristic library is independently rechecked for exact
frontier equality, exact identity closure, exact burden, and mandatory retention.
Every deletion endpoint receives a complete irreducibility scan. A MIP incumbent
with a nonbinary value is rejected rather than rounded.

## Preprocessing variants

Primary exact enumeration and DP use mandatory-only preprocessing. The primary
MIP uses the full exact fixed-point preprocessor. Primary greedy and deletion
methods use mandatory-only preprocessing so the heuristic is evaluated on the
declared instance rather than a dominance-altered search path.

The paired preprocessing experiment runs MIP under mandatory-only and full
fixed-point variants. Family A also runs DP under both variants. A secondary
heuristic sensitivity applies full preprocessing and reconstructs the returned
library. The report must distinguish preservation of feasibility and optimum
value from preservation of every optimizer identity.

The final runner may not start until it supports both registered MIP variants,
complete preprocessing audit trails, and solution reconstruction. Current code
support is not inferred merely from this registration.

## Resource limits and execution

Small instances receive 300 seconds for each exact method and MIP, 60 seconds
for deterministic heuristics, and 120 seconds for randomized heuristics. Medium
instances receive 900 seconds for each MIP variant, 300 seconds for deterministic
heuristics, and 600 seconds for randomized heuristics. Large instances receive
1,800, 600, and 900 seconds respectively. Every process has a 16 GiB memory cap.
Any adversarial row marked exact-capable receives 300 seconds for enumeration
and 300 seconds for DP, including when its mechanism scale is named medium or
large; failure to finish remains a registered exact-method failure.

Timed execution is single-process, single-Julia-thread, single-BLAS-thread, and
single-HiGHS-thread. Warm-up fixtures are excluded. A full garbage collection is
requested before each timed run. Instances execute in registered schedule-key
order. Algorithm order uses a deterministic Latin rotation stored with each run.

No timeout is rerun. Runtime for a timeout is recorded at the registered limit,
with the solver's incumbent, best bound, and gap retained when available. A
memory-limit termination, process error, or exact certificate failure is retained
under its declared status. Failed final rows are never replaced.

## HiGHS controls

HiGHS runs with one thread, parallel mode off, presolve on, registered seed,
zero relative MIP gap tolerance, zero absolute MIP gap tolerance, and the
family-size time limit. The complete solver log, solver and wrapper versions,
termination, primal and dual status, objective, best bound, gap, solve time, and
node count are saved. `OPTIMAL` is reported as a solver status and never as a
formal or exhaustive proof.

No proprietary solver is required. No second open-source solver is currently
pinned. Adding one requires a prospective amendment and environment-stability
check; its absence does not change the exact small-instance cross-check.

## Hardware record

Before timing, the runner records machine ID, CPU model, physical and logical
cores, installed memory, OS and kernel, architecture, Julia version, git commit,
hashes of the Julia project and manifest, HiGHS/JuMP versions, Julia and BLAS
thread counts, and UTC start. A material hardware change stops the batch. The
affected batch may be restarted only under a documented deviation or amendment;
results from different machines are not silently pooled.

## Registered outputs

Run-level output stores instance and seed identifiers, algorithm and
preprocessing variant, exact selected identifiers and burden when available,
solver diagnostics, runtime, peak memory, method counters, exact feasibility and
irreducibility certificates, trace/log paths, and certificate hashes. Instance,
run, preprocessing, audit, log, failure-fixture, summary, and narrative outputs
have distinct registered paths.

## Dry-run contract

Before initial lock, only these in-memory fixtures may execute:

- mandatory inactive already covers the only zero-frontier row;
- one positive-weight active strategy uniquely carries one module; and
- two equal-weight active strategies tie while carrying the same module.

Each is serialized and deserialized, then solved by enumeration, DP, and HiGHS
through the independent exactness audit. No dry-run timing, node count, selected
identity, or solver log enters the study. No Family A, B, or C final seed is used.

## Lock and amendments

The initial lock hashes this design, the analysis plan, reporting rules, both
registries, the TOML config, the journal summary, and the lock script. Freeze is
allowed only after deterministic registry equality, schema and balance checks,
seed separation, output-absence checks, and all three trivial dry runs pass.
The lock file is immutable.

Any later change uses `amendments/AMENDMENT_NNN.md` and a new
`DESIGN_LOCK_AMENDMENT_NNN.json`. An amendment states the reason, files and
claims changed, outcomes already seen, and whether the change affects pilot or
final execution. Prior locks are never edited. Outcome-driven silent changes,
row replacement, and retrospective seed changes are prohibited.
