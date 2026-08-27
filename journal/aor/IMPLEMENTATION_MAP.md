# AOR journal implementation map

This map identifies code that was actually inspected. “Reusable” means the
implementation can be called or adapted; it does not imply that its theorem,
scalability, or public-API status is stronger than stated here.

## Canonical domain model

| Requirement | Existing type or function | Location | Reuse boundary |
|---|---|---|---|
| Exact arithmetic | `ExactRational = Rational{BigInt}`; `exact_rational` | `julia/src/Types.jl:7,29` | Canonical for theorem fixtures, weights, finite oracles, and postchecks. Float inputs are deliberately rejected by the exact parser. |
| Beliefs and identifiers | `Belief`, `StrategyId`, `ModuleId` | `julia/src/Types.jl:64-79` | Typed wrappers provide deterministic equality and ordering surfaces. |
| Modules and module sets | `GenerativeModule`, `ModuleSet` | `julia/src/Types.jl:104-181` | Immutable finite module representation used by the package model. |
| Strategies | `Strategy` | `julia/src/Profiles.jl:53-78` | Couples one strategy ID, operating profile, and raw module set. |
| Operating profiles | `OperationalProfile` | `julia/src/Profiles.jl:8-51` | Exact mode is the default; Float64 mode is explicit. |
| Catalog and inactive strategy | `StrategyCatalog`, `StrategyCatalog(...)` | `julia/src/Profiles.jl:84-139` | Constructor validates unique IDs, common belief carrier, and the zero-profile/no-module inactive invariant. |
| Raw libraries | `RawLibrary` | `julia/src/Types.jl:183-220`; catalog adapter in `Profiles.jl` | Retains the inactive strategy by construction; use this invariant in new package-level algorithms. |
| General closure | `GenerativeClosure`, `module_closure` | `julia/src/Libraries.jl:19-73` | Exact and validated for extensivity, monotonicity, and idempotence. The constructor enumerates every module subset and checks every comparable pair; it is unsuitable for a large identity-closure study. |
| Identity closure | `identity_generative_closure` | `julia/src/Libraries.jl:63-65` | Correct for small module universes. Use sparse carrier obligations, not the exponential closure table, for large identity instances. |
| Operating frontier | `operational_frontier`, `frontier` | `julia/src/Libraries.jl:117-136` | Exact maximum with the inactive strategy supplying the zero convention. |
| Raw modules and closure | `raw_module_union`, `module_union`, `generative_closure` | `julia/src/Libraries.jl:144-178` | Canonical general-closure state calculation. |
| Compressed state | `CompressedLibraryState`, `compressed_state` | `julia/src/Libraries.jl:182-221` | Preferred equality object for exact safe feasibility. |

## Exact compression and certification

| Capability | Existing implementation | What it establishes | What it does not establish |
|---|---|---|---|
| Redundancy tests | `operationally_redundant`, `generatively_redundant` in `Libraries.jl:242-277` | Exact one-strategy frontier and closure redundancy at the current library. | Global optimality or batch safety. |
| Frontier-only pruning | `frontier_only_prune` in `Compression.jl:79-108` | Deterministic removal under frontier equality. | Closure or dynamic-value preservation. |
| Rechecked deletion | `innovation_safe_delete` in `Compression.jl:111-147` | Deletes one represented active strategy only when both exact equalities hold. | Optimality of the resulting library. |
| Rechecked fixed point | `innovation_safe_prune_fixed_point` in `Compression.jl:150-199` | Deterministic, rechecked, one-deletion-irreducible endpoint for the requested order. | Minimum cardinality, minimum weight, or approximation ratio; the source comments say so. |
| Independent state/value check | `verify_compressed_equivalence` in `Compression.jl:202-287` | Recomputes frontier, general closure, compressed state, optional DI, and optional value comparisons. | A proof of the optional value oracle itself. |
| Complete small-instance cardinality oracle | `minimum_safe_compression` in `Compression.jl:290-344` | Cardinality-ordered exhaustive search over inactive-containing sublibraries; exact optimum within the enforced optional-strategy cap. | Weighted optimization; scalable execution. |
| Solver-neutral formulation | `BinaryCompressionFormulation`, `minimum_safe_compression_ip_formulation`, `satisfies_compression_formulation` in `Compression.jl:347-480` | Frontier-cover rows and exact minimal-generator representation for the validated closure table. | Solver status, runtime, or post-solve safety by itself. |
| JuMP/HiGHS model | `build_safe_compression_milp` in `SafeCompressionSolver.jl:147-252` | Binary strategy variables, mandatory inactive retention, exact-rational objective scaled to exactly representable integers, frontier rows, and identity/general closure constraints. | Exact feasibility or global proof merely from model construction. |
| Exact post-solve certificate | `certify_safe_compression` in `SafeCompressionSolver.jl:383-403` and its internal exact checker at `:289-363` | Source inclusion, formulation satisfaction, exact frontier, exact general closure, exact burden/objective, and optional exactly rechecked deletion trace. | Exhaustive global optimality unless the independent oracle is also run. |
| Solver orchestration | `solve_safe_compression_milp` in `SafeCompressionSolver.jl:524-733` | Deterministic HiGHS defaults, exact check of every returned vector, optional optimal-face enumeration, and optional independent exhaustive oracle. Reports solver and exact certificates separately. | A formal proof. With the exhaustive cap disabled or exceeded, `solver_claimed_optimal` remains solver evidence only. |

Every new solver-returned library should pass the existing certificate layer
or an equally strict adapter. The required journal certificate fields are:

1. mandatory inactive strategy retained;
2. candidate is a sublibrary of the declared source;
3. exact operating frontier equals the source frontier;
4. exact generative closure equals the source closure;
5. exact burden equals the independently recomputed objective;
6. the binary formulation is satisfied exactly; and
7. solver status, exact safety, and exhaustive optimality are separate fields.

## Second exact finite optimizer

`julia/src/ResourceOptimization.jl` is a standalone module with an implicit
inactive strategy and identity module-union closure. It is useful as an
independent oracle because it does not use the package's `RawLibrary` or
`GenerativeClosure` representation.

| Capability | Symbols | Location |
|---|---|---|
| Problem and exact weights | `ExactRetentionProblem` | `ResourceOptimization.jl:65-184` |
| Exact burden | `library_weight` | `ResourceOptimization.jl:233-246` |
| Exact frontier and identity closure mask | `library_frontier`, `library_module_mask`, `library_closure` | `ResourceOptimization.jl:269-310` |
| Complete enumeration certificate | `enumerate_sublibraries` | `ResourceOptimization.jl:340-363` |
| Exact safe feasibility | `safe_feasible`, `exact_safe_feasible` | `ResourceOptimization.jl:366-390` |
| Safe family and rechecked deletion | `safe_sublibraries`, `safely_deletable`, `safe_pruning_trace` | `ResourceOptimization.jl:392-443` |
| Local irreducibility | `inclusion_irreducible` | `ResourceOptimization.jl:446-454` |
| Complete optimum tie sets | `minimum_safe_cardinality_masks`, `minimum_safe_weight_masks` and the result constructors below them | `ResourceOptimization.jl:457-560` |

This module should remain an independent test oracle unless an explicit design
decision unifies it with the package API. Mixing its identity-closure mask with
the package's general closure without an adapter would change semantics.

## Complexity and tagged-cover machinery

`julia/src/SafeCompressionComplexity.jl` is also a standalone module.

| Capability | Symbols | Evidence boundary |
|---|---|---|
| Weighted set-cover source | `WeightedSetCoverInstance`, `set_cover_feasible`, `set_cover_within_budget`, `set_cover_weight`, `set_cover_optimal_masks` | Positive-integer-cost, nonnegative-integer-budget, full-union exact finite definition, up to the fixture's 62-bit carrier limit. |
| Safe-compression decision source | `SafeCompressionDecisionInstance`, its `safe_feasible`, `safe_compression_within_budget`, `minimum_safe_weight_masks` | Identity-closure exact fixture model with an explicit mandatory inactive identifier; active-selection masks omit its fixed zero burden. |
| Polynomial constructors | `closure_only_safe_compression_reduction`, `frontier_only_safe_compression_reduction`, `combined_safe_compression_reduction` | SC-COMP uses and proves only the closure-only construction. The other pre-existing executable constructors are outside the narrowed theorem; execution is never a universal proof. |
| Tagged obligations | `IdentitySafeCover`, `identity_safe_cover`, `covers_identity_obligations` | Builds distinct string labels `belief:i` and `module:j`, and carrier masks, for identity closure. This is the executable precursor to a tagged-cover theorem. |
| Cross-model audit | `reduction_correspondence` | Checks feasibility, exact weight, copied threshold, budgeted yes/no answer, and optimizer correspondence by complete finite enumeration on a fixture. |

The theorem ledger's `SC-COMP` record is the authoritative claim boundary. No
corresponding Lean file, finite-complexity encoding, polynomial-time reduction
framework, or NP-completeness bridge exists.

## Approximate algorithms and partial dynamic programming

`julia/src/ApproximateCompression.jl` can be reused as a candidate-generation
and exact-small-oracle layer:

- `ApproximateCompressionProblem`, `ApproximateCompressionRecord`, and
  `ApproximateCompressionSolution` define exact loss budgets and result
  records (`:21-67`).
- `enumerate_approximate_compressions` performs complete bitmask enumeration
  and certifies its own search completeness (`:371-430`).
- `pareto_compression_records` extracts exact nondominated rows (`:329-368`).
- `greedy_approximate_compression` and
  `multistart_greedy_approximate_compression` implement deterministic
  backward-deletion candidates (`:461-553`).
- `pareto_beam_compression` is a deterministic width-bounded heuristic
  (`:556-628`).
- `approximate_compression_ip_formulation` and
  `satisfies_approximate_compression_ip_formulation` represent exact operating
  rows plus evaluated generative no-good cuts (`:631-708`). A partial cut pool
  is an outer approximation.
- `operational_ip_cardinality_lower_bound` is exact dynamic programming over
  belief-attainer masks for the operating relaxation (`:711-750`). It is not a
  full frontier-plus-closure DP and is not an upper-bound construction.

The existing fixed `(2,2,3)` counterexample proves that a strict-heaviest
safely-deletable rule can be globally suboptimal. Any approximation theorem
must therefore name stronger assumptions than the current generic model.

## Financial identity-closure implementation

The financial resource script contains a large-instance sparse identity
adapter that avoids constructing the package's exponential closure table:

- `registered_strategy_weights` (`run_financial_resource_optimization.jl:423`)
  derives only prespecified, outcome-blind exact weights;
- `build_exact_resource_model` (`:493`) losslessly converts the frozen
  validation profiles to rationals and constructs frontier-attainer and
  module-carrier incidence;
- `_solve_identity_resource_milp` (`:537`) solves the sparse carrier-cover
  model;
- `_certify_original` (`:618`) independently rechecks the selected IDs against
  the original rational frontier and original module strings; and
- `_render_outputs`/`_check_outputs` (`:916,995`) produce and drift-check the
  registered public aggregates.

These underscore the proposed tagged-cover implementation, but the leading
underscores correctly signal that the solver and certificate are currently
experiment-local, not a stable package API.

## Enumeration inventory

The repository contains three distinct complete-enumeration roles:

1. `minimum_safe_compression` for package-model minimum cardinality;
2. `ResourceOptimization.enumerate_sublibraries` and optimum routines for
   identity-closure weight/cardinality and resource problems; and
3. `enumerate_approximate_compressions` for exact tolerance-based loss
   surfaces.

The MILP solver additionally invokes its own independent exhaustive oracle
when the optional-strategy count does not exceed
`exact_enumeration_limit` (default 16, maximum 62). Retain these as separate
implementations for cross-checking; do not refactor away oracle independence
before the new algorithms are validated.

## Result export and machine-readable schemas

There is no single generic result-schema library. Reusable pieces are:

- `encode_exact_rational`, `write_exact_matrix`, and `read_exact_matrix` in
  `julia/src/IO.jl:7-53`;
- stable render-then-compare patterns in
  `verify_safe_compression_complexity_reductions.jl:169-241`;
- JSON/CSV writers in `run_compression_experiments.jl:461-575`;
- exact CSV and JSON renderers in `run_approximate_compression.jl:352-930`;
- generated-file SHA maps and `--check` comparison in the financial resource
  script; and
- stable row ordering and render functions in the randomized-v2 scripts.

For `algorithmic_compression_v1`, define one versioned schema before outcomes,
store rationals as canonical numerator/denominator strings, and include at
least: instance ID; seed; instance family and parameters; algorithm/version;
objective; selected IDs in stable order; exact frontier/closure/burden gates;
inactive-retention gate; solver status if any; exhaustive-optimality status;
candidate lower/upper bounds; time limit/censoring; runtime scope; environment;
and artifact hashes. Runtime fields must be labeled host-dependent
floating-point measurements.

## Dependencies available without adding packages

The pinned Julia environment already contains everything needed for the
preferred exact algorithmic program (`julia/Project.toml:5-25`):

| Dependency | Existing use | Proposed reuse |
|---|---|---|
| Julia/Base | integers, `Rational{BigInt}`, collections, serialization | exact masks, DP tables, deterministic reconstruction, lightweight JSON/CSV rendering |
| `JuMP` 1.31.1 | solver-neutral model construction | MILP baseline and optional branch-and-cut interface |
| `HiGHS` 1.24.1 | mixed-integer optimization | deterministic single-thread solver baseline |
| `StableRNGs` 1.0.4 | registered randomized designs | new study's independently registered instance and order seeds |
| `Random` | local random APIs | only through a committed deterministic seed protocol |
| `SHA` | design/artifact hashing | locks, source hashes, result manifests, selected-library certificates |
| `TOML` | experiment configurations | new design configuration and lock metadata |
| `SparseArrays` | sparse numerical/model structures | sparse obligation incidence and preprocessing |
| `LinearAlgebra` | existing numerical routines | no new package required for exact cover DP |
| `Printf` | deterministic presentation | runtime/result summaries, never authoritative exact numbers |
| `Test` and `Aqua` in the test environment | unit/property/API checks | targeted algorithm and schema tests |

Lean 4.32.0 and pinned mathlib are available for only the theorem-ledger items
selected for formalization. No dependency should be added merely to make an
algorithm look more sophisticated.

## Current test coverage

| Surface | Existing coverage |
|---|---|
| Domain model | Exact probability/belief core, catalog validation, 314 frontier/closure properties, exact IO, explicit Float64 mode. |
| Rechecked deletion | Single and fixed-point deletion, stale/batch-certificate rejection, frontier-only loss witness, deterministic deletion order. |
| Exact enumeration/formulation | Minimum cardinality, solver-neutral formulation satisfaction, 1,376 seeded small-library properties. |
| JuMP/HiGHS | Identity and general closure, cardinality versus weight, all-optimum ties, exact objective scaling failures, Float weight rejection, exact postchecks, 12 random MILP-versus-independent-enumeration instances, deletion traces. |
| Complexity | Closure-only SC-COMP reduction, explicit inactive identifier and budget, five registered yes/no fixtures, and 5,565 budgeted variants of all 265 full-union three-set/three-element incidence systems (44,520 selected masks), with exact feasibility/weight/threshold/decision correspondence and artifact drift. |
| Approximate methods | Exact loss definitions, complete subset and Pareto oracles, four greedy rules, multistart, beam search, operational lower bound, complete/partial no-good cut behavior, committed outputs. |
| Resource optimization | Exact burdens, complete safe families and optimizer ties, local/global/capacity/penalty counterexamples, artifact drift. |
| Financial resource layer | Outcome-blind weights, exact incidence construction, fail-closed original-object certification, mandatory inactive selection, exact small-instance MILP/enumeration agreement, design-lock validation. |
| Scaling | Only two tiny deterministic MILP sizes assert increasing model size and exact safety; no runtime threshold is tested. |

## Missing tests for the preferred contribution

1. Tagged-cover theorem fixtures that deliberately reuse the same underlying
   identifier text on the belief and module sides and prove tags remain
   disjoint.
2. Formal and Julia equivalence tests covering every source-relative identity
   instance, including zero-frontier beliefs and source modules with multiple
   carriers.
3. Preprocessing rule tests for soundness, optimum/tie-set preservation,
   deterministic lifting, chained reductions, empty obligations, and fail-closed
   reconstruction.
4. Full exact DP versus two independent oracles (package enumeration and
   `ResourceOptimization`) on exhaustive and seeded small instances, for both
   weight and cardinality with ties.
5. DP state-cap, bit-width, overflow, duplicate-obligation, and stable-order
   tests.
6. Greedy worst-case family regression and, only if a theorem is proved,
   property tests of every required structural assumption and guarantee bound.
7. Scaling schema/lock validation, deterministic instance replay, warm-up and
   timing-scope checks, time-limit/censoring behavior, memory/result-size
   fields, and byte-stable non-runtime output checks.
8. Cross-algorithm certificate tests requiring every returned library to pass
   exact frontier, closure, burden, and inactive-retention checks.
9. Financial comparison tests proving held-out columns cannot enter
   preprocessing, weights, algorithm selection, tuning, or optimization.
10. Package integration tests if the two standalone exact modules are promoted
    into the public `StrategyInnovation` API.

## Recommended canonical layering

```text
StrategyCatalog / RawLibrary / exact profiles
        |
        v
identity tagged-obligation adapter ---- general-closure existing formulation
        |
        +--> proved preprocessing + reconstruction certificate
        |
        +--> exact bitmask DP oracle (small obligation count)
        +--> JuMP/HiGHS baseline (larger instances)
        +--> theorem-qualified greedy candidate, if proved
        +--> existing rechecked deletion baseline
        |
        v
one independent exact selected-library certificate
        |
        v
versioned result schema and artifact renderer
```

This layering keeps algorithm construction, solver evidence, exact finite
certification, and formal theorem status separate while reusing the strongest
existing code.
