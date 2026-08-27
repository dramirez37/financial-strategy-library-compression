# Common journal compression instance schema

## Status

Schema version: `journal-compression-instance-v1`

Julia implementation:
`julia/src/JournalCompressionInstance.jl`

This is the internal, solver-neutral instance representation for the journal
algorithm program. It integrates the package's existing `StrategyId`,
`Belief`, `ModuleId`, `FrontierRequirement`, `ModuleRequirement`,
`ExactRational`, tagged-cover incidence, and preprocessing reconstruction
types. It does not replace `StrategyCatalog`, `RawLibrary`,
`TaggedCoverRepresentation`, or the independent `ResourceOptimization`
oracle.

Version 1 is deliberately restricted to identity module closure. That is the
scope in which independent module-carrier rows are semantically equivalent to
exact source-closure preservation. A future nonidentity version would require
a different requirement representation and separate proof; setting
`identity_closure=false` fails validation.

## Purpose and boundaries

Every journal algorithm should consume the same validated semantic payload:

- original typed strategy identifiers;
- one mandatory flag and one exact weight per strategy;
- source-relative frontier and module requirement tags;
- strategy-to-requirement incidence;
- independent exact strategy profiles and raw module memberships;
- the original exact source frontier and identity closure;
- a preprocessing lift and equal-coverage reconstruction map;
- a declared tie policy;
- canonical ordering; and
- instance provenance.

Constructors defensively copy mutable input arrays. Consumers must treat the
stored arrays as read-only; any semantic change requires construction and
validation of a new instance and therefore a new deterministic hash.

The independent profile and raw-module fields are intentional. They let the
solution checker recompute the original frontier and identity closure instead
of trusting the covering incidence alone. Passing the incidence constraints
is therefore reported separately from exact original-semantic feasibility.

The schema is not an experimental result schema. It contains no runtime,
solver status, bound, stopping status, empirical outcome, or algorithm ranking.
Frozen experiment configurations, registries, locks, and output schemas are
unchanged.

## Top-level Julia representation

`JournalCompressionInstance` has the following fields.

| Field | Exact meaning | Validation |
|---|---|---|
| `schema_version` | Literal `journal-compression-instance-v1`. | Other versions fail closed. |
| `strategy_ids` | Canonically ordered tuple of existing `StrategyId` values. | Nonempty, unique, and ordered by encoded identifier kind and value. |
| `mandatory` | Binary flag aligned with `strategy_ids`. | At least one mandatory strategy; exact length. |
| `weights` | `Vector{Rational{BigInt}}`. Integers are represented with denominator one. | All nonnegative; every nonmandatory weight strictly positive; floating-point inputs rejected. |
| `requirements` | Existing disjoint `FrontierRequirement` rows followed by `ModuleRequirement` rows. | Unique and canonical frontier-then-module order. |
| `coverage` | Bit matrix with requirement rows and strategy columns. | Exact dimensions, every row has a carrier, and every bit agrees with independent profiles or modules. |
| `operating_profiles` | Exact strategy-by-belief matrix aligned with frontier rows. | Its columnwise maxima must equal `source_frontier`. |
| `strategy_modules` | Canonically ordered raw `ModuleId` tuple for every strategy. | Unique within strategy, contained in source closure, and incidence-consistent. |
| `source_frontier` | Exact source maximum at each ordered frontier belief. | Recomputed exactly from `operating_profiles`. |
| `source_closure` | Canonically ordered source `ModuleId` tuple. | Equals both the module requirement sequence and source raw-module union under identity closure. |
| `identity_closure` | Explicit semantic declaration. | Must be `true` in version 1. |
| `preprocessing` | `JournalPreprocessingMap`. | Index, offset, mandatory, residual-carrier, reconstruction, and tie checks below. |
| `tie_handling` | `JournalTieHandling`. | Must declare complete ties or one stable representative. |
| `provenance` | `JournalCompressionProvenance`. | Required kind, IDs, ordered metadata, hashes, and redistribution flag. |

Identifiers serialize losslessly as `symbol`, `string`, or an explicit signed,
unsigned, or arbitrary-precision integer type plus the textual value. Symbols,
strings, and integer widths remain distinct. Other identifier carriers are
rejected rather than serialized through an unstable display representation.

## Canonical ordering

The schema orders strategies by encoded identifier kind and value. It orders
requirements in two stable blocks:

1. frontier requirements, by encoded belief identifier; then
2. module requirements, by encoded module identifier.

Source-closure modules and each strategy's raw module list use the same module
identifier order. Component, tagged, financial, and mask-problem adapters
canonicalize their inputs. The low-level validated constructor rejects an
out-of-order payload, and deserialization checks the two ordering declarations
before constructing an instance.

This canonical order is the only order used for binary solution vectors,
reduced-model indices, serialization, deterministic selection rules, and
hashes. The identifiers themselves remain the original identifiers.

## Preprocessing map

`JournalPreprocessingMap` records:

- whether preprocessing was applied;
- original indices of residual requirements;
- original indices of residual strategies;
- original indices of forced strategies;
- the exact forced-strategy objective offset;
- equal-weight duplicate-coverage reconstruction classes; and
- whether all optimizer identities remain reconstructable by the declared
  maps.

Indices are one-based original schema indices, unique, and increasing.
Remaining and forced strategy sets must be disjoint. When preprocessing is
applied, every mandatory strategy must be forced. The objective offset must
equal the independently summed exact weight of the forced strategies.
Every residual requirement must retain a residual carrier.

Each reconstruction class contains its representative, uses equal exact
weights, and has identical coverage on the residual requirements. Classes are
disjoint and cannot contain mandatory strategies. Equal-weight strict
dominance is not manufactured into a reconstruction class: if that rule loses
optimizer identities, the completeness flag is false.

An unapplied map is exactly the identity map: every row and column remains,
there are no forced columns or reconstruction groups, and the offset is zero.

## Tie declaration

`JournalTieHandling` supports exactly two modes.

| Mode | Contract |
|---|---|
| `complete` | The consuming algorithm claims that every exact optimizer identity is returned. The preprocessing map must certify that all identities remain reconstructable. |
| `declared_representative` | The algorithm returns one representative under the recorded stable selector and makes no complete-tie claim. |

Both modes require a human-readable declaration and stable selector. The tie
mode is algorithm metadata, not an optimality proof. A MILP status or a single
optimal vector cannot be relabeled `complete` without an independently valid
complete-face procedure.

## Provenance

`JournalCompressionProvenance` requires one of four kinds:

- `synthetic`;
- `adversarial`;
- `canonical`; or
- `financial`.

It stores a stable `instance_id`, source description, optional generator ID,
sorted parent-artifact SHA-256 pairs, sorted string attributes, and an explicit
redistribution flag. This metadata establishes lineage only; it does not turn
a generated instance into theorem evidence or an empirical input into a
publishable artifact.

The financial adapter requires `instance_kind=:financial` and
`redistributable=true`. Its API accepts only strategy identifiers, exact
aggregate profiles, raw module labels, source frontier and closure, and exact
weights. It has no parameter for market rows, prices, returns, dates, security
identifiers, or provenance-complete licensed extracts. The caller remains
responsible for confirming that each supplied aggregate is legally
redistributable. Raw CRSP/WRDS rows and prohibited row derivatives remain
outside the schema and repository.

## Conversion interfaces

### Current raw strategy-library model

`journal_compression_instance(catalog, closure, source; ...)` calls the
existing `tagged_cover_representation` adapter. It therefore reuses catalog
validation, mandatory inactive semantics, source frontier, identity closure,
and exact tagged-cover construction. Exact source profiles are required;
Float64 profiles are rejected rather than silently rationalized.

### Existing tagged covering form

`journal_compression_instance(representation; ...)` converts
`TaggedCoverRepresentation`, independently extracts profiles and raw modules
from its catalog, recomputes the source compressed state, and canonicalizes
rows and columns. An optional `TaggedCoverPreprocessingResult` is checked
against that exact representation and its old indices are remapped into the
common canonical order.

### Financial optimization inputs

`journal_compression_instance_from_financial` accepts either explicit public
aggregate arrays/dictionaries or the legally distributable fields of the
existing financial resource model `NamedTuple`:

- `source_ids`;
- `rational_profiles`;
- `source_frontier`;
- `source_modules`; and
- the module memberships in `lookup`.

The adapter inserts the existing implicit zero-weight, no-module mandatory
policy. Because the financial sparse model does not assign that policy an
operating profile, the adapter uses an exact per-state value one unit below
the declared source frontier. It therefore cannot become a frontier attainer
and preserves the financial model's active-attainer constraints, including
when a source frontier value is negative. This is an incidence-preserving
embedding, not a claim that the financial inactive policy earns that value.
The adapter then invokes the same component validator used by other sources.
No frozen financial workflow or output schema is modified.

### Synthetic and adversarial generators

`journal_compression_instance_from_mask_problem` converts the existing
`ExactRetentionProblem`-compatible interface used by
`ResourceOptimization`: strategy IDs, exact weights, exact profile matrix,
module masks, and module count. An optional source mask chooses a source
sublibrary; the adapter adds the implicit inactive policy. This covers the
existing safe-deletion gap generator while keeping `ResourceOptimization` an
independent oracle rather than importing its types into the package API.

`journal_compression_instance_from_components` is the lower-level adapter for
new registered synthetic or canonical generators. It requires exact aligned
components and canonicalizes them before validation.

## Exact solution interfaces

`check_journal_compression_solution(instance, selected)` reports separately:

- mandatory strategies retained;
- tagged rows covered;
- exact independently recomputed source frontier preserved;
- exact independently recomputed identity closure preserved;
- exact burden; and
- optional expected-burden reconciliation.

`journal_compression_feasible` is true only when all four feasibility checks
pass. `journal_compression_burden` sums exact schema weights without
floating-point conversion.

`journal_reduced_cover_model` exposes the residual `ExactTaggedCoverModel` for
algorithms. `lift_journal_compression_solution` restores forced selections,
checks original semantic feasibility, and reconciles the exact residual
objective plus preprocessing offset. `reconstruct_journal_compression_solutions`
then enumerates every declared equal-weight duplicate substitution and
rechecks feasibility and burden for each reconstruction.

These checks certify a returned library's exact feasibility and burden. They
do not prove algorithmic optimality, reproduce a solver search, or establish
that two implementations are independent.

## Exact algorithm result schema

The independent exact enumeration and requirement-mask dynamic-programming
methods use the separate result schema
`journal-compression-exact-solution-v1`, implemented in
`julia/src/ExactJournalCompression.jl`. This does not change the version-1
instance schema or any frozen experiment result schema.

`JournalExactSolutionResult` records:

- algorithm identity and `:exact_optimum` completion status;
- the canonical instance SHA-256;
- exact `Rational{BigInt}` optimum burden;
- one deterministic original-order selection and, when requested, every
  retained exact tie;
- a mandatory-preprocessing dimension and objective-offset summary;
- algorithm-independent counters for reachable state-layer pairs,
  transitions, enumerated candidate selections, and final reachable states;
- separate wall-clock nanoseconds for preprocessing, search, and
  reconstruction/certification; and
- one independent original-library certificate per returned selection.

The certificate payload repeats mandatory retention, tagged coverage, exact
source-frontier equality, exact source-closure equality, and exact burden
reconciliation separately. Its `evidence_class` is `exact finite
computation`, and `solver_status_used=false`; neither the status label nor the
certificate is a Lean or mixed-integer-solver claim. Runtime fields are
single-run measurements and are not scaling evidence.

`serialize_journal_exact_solution` emits sorted TOML. Exact rationals and
arbitrary-size counters use canonical strings. The command

```text
./.local_runtime/julia-1.12.6/bin/julia --project=julia \
  julia/scripts/solve_journal_compression_instance.jl INSTANCE.toml \
  --algorithm dp --output CERTIFICATE.toml
```

reads a validated serialized instance and emits that machine-readable
certificate. `--algorithm enumeration` selects the independent small-library
oracle. `--all-ties` requests complete tie storage; both methods fail closed
if the caller's `--maximum-ties` cap is exceeded or if a supplied preprocessing
map declares optimizer identities unreconstructable.

## Serialization and deterministic hash

`serialize_journal_compression_instance` emits sorted TOML using the pinned
Julia `TOML` standard library. Rationals are canonical
`numerator//denominator` strings; incidence is stored as ordered one-based
covered-requirement indices. No floating-point field is emitted.

`deserialize_journal_compression_instance` parses the versioned document and
reruns the complete constructor validation. The read/write stream wrappers are
`read_journal_compression_instance` and
`write_journal_compression_instance`.

`journal_compression_instance_sha256` hashes the exact canonical serialized
bytes with SHA-256. Thus the hash includes semantic inputs, stable ordering,
preprocessing map, tie declaration, and provenance. Runtime or solver data is
not part of the instance hash.

## Validation coverage

`julia/test/test_journal_compression_instance.jl` contains targeted exact
tests for:

- missing requirement carriers;
- duplicate strategy identifiers;
- negative weights;
- a solution omitting a mandatory strategy;
- inconsistent source frontier;
- inconsistent source closure;
- nonidentity declarations;
- unstable strategy and serialized ordering;
- incompatible complete-tie and preprocessing declarations;
- exact feasibility and burden reconciliation;
- canonical TOML round trips and byte-stable hashes;
- raw-library and tagged-cover conversions;
- preprocessing lift and equal-coverage tie reconstruction;
- redistributable financial aggregate conversion and fail-closed private
  provenance; and
- the existing adversarial mask generator.

The tests are exact finite software validation. They are not Lean kernel
verification, a mathematical proof, solver evidence, runtime evidence,
synthetic findings, or retrospective financial findings.

## Versioning rule

Any change to field meaning, identifier codec, canonical ordering, exact
arithmetic, preprocessing index semantics, tie contract, provenance contract,
or serialized byte representation requires a new schema version. Additive
algorithm result fields belong in a separate versioned result schema and must
not silently mutate this instance schema or any frozen experiment schema.
