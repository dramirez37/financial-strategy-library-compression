# AOR journal workplan

## Program objective

Produce the strongest defensible AOR submission without changing the frozen
preprint, randomized-v2 study, registered financial parents, or evidence
classifications. The implementation order is theorem first, exact oracle
second, registered experiment third, and manuscript integration last.

No later phase is authorized by this document. Each phase is a separate task
and stops at its declared gate.

## Contribution choices

### Smallest viable journal contribution

The smallest viable package uses only evidence that substantially exists:

1. retain the Lean-verified exact frontier--closure, safe-feasibility,
   minimum-attainment, and local/global boundary results;
2. present SC-COMP as a human-readable complexity theorem with exact finite
   Julia correspondence validation and no Lean claim;
3. foreground the independently exact certification of solver-returned
   libraries and the distinction between solver `OPTIMAL` and exhaustive
   optimality;
4. reuse the registered exact fixtures, bounded approximate-compression
   analysis, frozen N=1024 results, and locked financial algorithm comparisons;
   and
5. repair provenance and submission gates without creating new experimental
   findings.

This package does not need a new long benchmark. Its novelty claim must be
limited to the exact compression framework, resource optimization boundary,
complexity characterization, and multi-layer validation already supported by
the repository.

### Stronger preferred contribution

The preferred package adds one coherent exact algorithmic layer:

1. a precisely stated identity-closure tagged-cover equivalence, with a Lean
   theorem only for the finite equivalence selected in the theorem ledger;
2. proved, reversible preprocessing rules;
3. an exact bitmask DP for bounded tagged-obligation count, independently
   checked against complete enumeration;
4. the existing general-closure JuMP/HiGHS implementation as the scalable
   solver baseline with exact post-solve certification;
5. a separately registered synthetic scaling comparison; and
6. a locked financial comparison using compression-time information only.

An approximation-guaranteed greedy result is optional. It enters the preferred
package only if a correct theorem with explicit structural assumptions is
proved. Otherwise the paper should report the existing negative boundary and
label greedy/beam methods as certified candidate generators.

## Dependency-ordered plan

### Phase 0 — provenance and governance repair

Purpose: make the current baseline trustworthy before adding outcomes.

Tasks:

1. Decide whether the 25 mismatched Artifact-ID rows are historical IDs that
   require immutable versioned paths or current IDs whose hashes require a new
   manifest revision. Do not overwrite the arXiv release.
2. Add an explicit journal-version table distinguishing package `0.1.0`,
   preprint `v0.1.1-arxiv`, and journal program `v0.2.0`.
3. Decide how the public audit should treat submission-only email metadata;
   do not weaken credential or licensed-data checks.
4. Define a journal gate that verifies the frozen release hashes without
   regenerating the frozen bundle from mutable sources.
5. Decide which indexed supplement records are actually part of the submitted
   supplement.

Gate G0:

- frozen release hash/diff checks pass;
- manifest lineage has no unexplained mismatch for journal-consumed inputs;
- submission-only metadata policy is explicit; and
- no mathematical, experiment, or manuscript claim changes occur in the same
  commit as a purely provenance repair.

Suggested commits: one decision/provenance commit, then one gate-test commit.

### Phase 1 — lock the mathematical specification

Purpose: remove ambiguity before implementation.

Create under `journal/aor/`:

- a theorem specification for finite source-relative exact safe compression
  under identity closure;
- a tagged obligation definition with disjoint constructors for
  positive-frontier belief obligations and source-module obligations;
- a weight/cardinality objective convention including zero-weight mandatory
  inactive retention;
- a bidirectional equivalence statement between safe libraries and covers;
- a precise complexity corollary boundary; and
- a worst-case local/global gap target specifying additive or multiplicative
  gap, parameter range, and all weights.

Required review questions:

1. Are zero-frontier beliefs correctly excluded because the inactive strategy
   already attains zero?
2. Are belief and module tags disjoint even when raw labels coincide?
3. Does source-relative module equality reduce to covering every source module
   only under identity closure?
4. Are weights positive for active strategies and zero only for inactive?
5. Is the claimed gap metric defined when the optimum burden is zero?

Gate G1:

- complete human proofs exist for every selected statement;
- exact counterexample/falsification fixtures find no issue within their
  declared bounds; and
- any false or underspecified statement is moved to a documented issue rather
  than implemented as a theorem.

Do not edit Lean or manuscript theorem status before G1.

### Phase 2 — exact tagged-obligation adapter and certificate

Purpose: establish one canonical implementation shared by later algorithms.

Integrate under `julia/src/`:

1. an adapter from `StrategyCatalog`/`RawLibrary` to a stable tagged-obligation
   incidence representation for identity closure;
2. exact objective weights and stable strategy/obligation ordering;
3. exact feasibility and burden evaluators; and
4. a lifting/certification interface that returns a `RawLibrary` and invokes
   the existing original-problem checks.

Reuse `SafeCompressionComplexity.IdentitySafeCover` as a reference, but avoid
duplicating the package domain model in the production API. Preserve
`ResourceOptimization` as an independent oracle.

Tests:

- exhaustive tiny identity instances;
- belief/module raw-label collisions;
- zero and tied frontiers;
- unique and duplicate module carriers;
- mandatory inactive retention;
- cardinality and rational weights;
- stable ordering and tie sets; and
- adapter result versus `compressed_state` equality.

Gate G2:

- every adapter-feasible mask is safe in the original package model and every
  original safe sublibrary covers all obligations;
- all exact tests pass under Julia 1.12.6; and
- no large identity instance constructs `GenerativeClosure`'s powerset table.

### Phase 3 — theorem-ledger selection and focused Lean proof

Purpose: formalize only the theorem that adds real assurance.

If G1 selects the finite tagged-cover equivalence, add a focused Lean file such
as `formal/StrategyInnovation/Optimization/TaggedSafeCompression.lean` and a
matching audit file. Encode:

- the two tagged obligation constructors;
- cover feasibility;
- the identity-closure frontier/module characterization; and
- the safe-feasible-if-and-only-if-cover theorem, including weight equality if
  useful and simple.

Do not formalize NP-completeness, polynomial-time reductions, the DP, or the
entire algorithm stack merely for appearance. Update `THEOREM_LEDGER.md` only
after the declaration builds without prohibited placeholders and its
`#print axioms` output passes the accepted audit.

Gate G3:

- focused Lean build/lint/axiom audit passes under Lean 4.32.0; and
- manuscript wording matches exactly the encoded assumptions and conclusion.

If formalization exposes a false or mismatched theorem, stop and return to
Phase 1.

### Phase 4 — proved preprocessing

Purpose: reduce exact algorithm state without changing the problem.

Candidate rules may be considered only after proof. Examples to investigate,
not assume, include duplicate incidence with unequal weight, forced singleton
carriers, and obligations implied by another obligation's carrier set.

For each accepted rule provide:

1. applicability predicate;
2. exact reduced instance;
3. objective-offset or forced-selection accounting;
4. deterministic lifting of every optimum;
5. proof of optimum-value and required tie-set preservation; and
6. a machine-readable reduction trace.

Tests compare the complete reduced-and-lifted optimum set with unreduced
enumeration on exhaustive and seeded small instances. A rule that preserves one
selected optimum but loses valid ties must say so and cannot support a
complete-correspondence claim.

Gate G4: all preprocessing equivalence tests and exact original-library
certificates pass.

### Phase 5 — exact bitmask DP

Purpose: add a bounded exact oracle over tagged obligations.

Implement both cardinality and positive rational weight objectives. The DP
must provide:

- deterministic state transitions over obligation masks;
- exact costs;
- stable reconstruction;
- explicit handling of ties according to the registered policy;
- preprocessing trace and lifted library;
- state count and cap diagnostics; and
- a fail-closed result when the obligation/bit/state cap is exceeded.

Validation hierarchy:

1. hand fixtures;
2. exhaustive incidence families;
3. seeded small package-model instances;
4. package enumeration versus DP;
5. independent `ResourceOptimization` enumeration versus DP; and
6. exact certification of every reconstructed library.

Gate G5: objective, tie policy, selected libraries, frontier, closure, burden,
and inactive retention agree across the declared oracles.

### Phase 6 — greedy theorem decision

Purpose: determine whether an approximation guarantee is mathematically
available, without promising one in advance.

Tasks:

1. Specify the candidate greedy direction (forward cover construction is the
   natural set-cover analogue; existing backward deletion is a different
   method).
2. Identify explicit assumptions under which the objective reduces to a
   standard weighted cover problem or another proved class.
3. Attempt the human proof and search exact small instances for violations.
4. Compare with the existing strict-heaviest-first counterexample.

Decision:

- if a theorem is proved, implement the exact deterministic rule, its bound
  calculation, and assumption checker;
- if not, retain the method as a heuristic candidate generator and make the
  failed assumptions/counterexamples part of the contribution boundary.

Gate G6: no result field or prose says “approximation guarantee” unless the
theorem, assumption checker, and regression suite all pass.

### Phase 7 — harden the MILP baseline

Purpose: compare algorithms through one certificate surface.

Reuse `solve_safe_compression_milp` with deterministic single-thread defaults
and exact postchecks. Add only what the registered study needs:

- sparse identity tagged-obligation construction;
- preprocessing trace ingestion;
- time-limit and censored-status fields;
- separate build, solve, certification, and end-to-end timing scopes;
- explicit lower/upper bounds when available; and
- exact selected-library certificate hashes.

Do not alter the meaning of `solver_claimed_optimal` or set
`exact_optimality_verified=true` without independent enumeration/DP.

Gate G7: targeted solver tests pass for identity/general closure, rational
objectives, ties, invalid candidates, time limits, and exact original-problem
certification.

### Phase 8 — preregister `algorithmic_compression_v1`

Purpose: freeze the study before registered outcomes.

Create a new self-contained tree:

```text
experiments/algorithmic_compression_v1/
  README.md
  DESIGN.toml
  DESIGN_LOCK.json
  INSTANCE_REGISTRY.csv
  SEED_REGISTRY.csv
  amendments/
  results/
```

The design must freeze:

- instance families and parameters;
- family rationale and exclusion rules;
- independent master/component seeds;
- algorithm versions, orders, tie policy, preprocessing, and tuning;
- DP caps and MILP time/memory policies;
- warm-up, repetitions, timing scopes, environment fields, and censoring;
- primary/secondary estimands;
- exact certificate requirements;
- result schemas, ordering, filenames, and hashes;
- smoke grid versus final grid; and
- explicit attestation that no final outcomes were read before lock.

Do not copy the N=1024 registry or seeds. Existing frozen results may motivate
the design but must not be rewritten, pooled, or treated as new outcomes.

Gate G8: lock validator, registry validator, schema tests, and output-absence
attestation pass before the first registered run.

### Phase 9 — smoke and registered synthetic scaling

Purpose: execute only the work authorized at each gate.

1. Run tiny unregistered development smoke cases during implementation.
2. After G8, run the registered smoke grid and check every artifact/certificate.
3. Inspect only preregistered operational diagnostics needed to decide whether
   the implementation is functioning; any design change requires a documented
   pre-final amendment.
4. Run the long final grid only after an explicit user request.
5. Run an independent result-reader audit and byte-stability check excluding
   declared host-dependent timing values.

Every algorithm/instance pair emits a row, including failures and censoring.
No manual result is transcribed into TeX.

Gate G9: schema, counts, seeds, stable order, exact certificates, failure-row
completeness, and source hashes reconcile independently.

### Phase 10 — locked financial algorithm comparison

Purpose: test algorithmic behavior in the two existing financial compression
instances without outcome leakage or parent mutation.

Place the extension under
`experiments/algorithmic_compression_v1/financial/` and create a separate lock
referencing the existing parent hashes. Algorithm inputs are limited to the
already frozen compression-time source IDs, losslessly rationalized validation
profiles, module incidence, and prespecified resource weights.

Prohibited inputs include held-out opportunity quality, target-year outcomes,
oracle rankings, retrospective regret, and any result used to select an
algorithm or tune it. Read held-out aggregate diagnostics only after every new
algorithm decision hash is committed by the run.

Preferred development path:

1. validate algorithms on public aggregate/incidence fixtures and existing
   small financial regression fixtures;
2. compare selected IDs, burdens, exact safety, and solver/DP agreement;
3. use existing committed ex post aggregates only where the locked adapter can
   evaluate an already selected library without raw rows; and
4. run licensed raw-data replays only if explicitly requested and necessary.

Gate G10:

- parent hashes unchanged;
- no raw or row-level file tracked or logged;
- every selected library exactly certified;
- held-out inputs absent from all decision functions;
- algorithm decisions hashed before ex post reads; and
- retrospective nonclaims present in every consumer.

### Phase 11 — manuscript and artifact integration

Purpose: let committed artifacts, not manual transcription, supply every new
number.

Create journal-only generators under `journal/aor/generated/` or integrated
Julia source. The generator must read only committed algorithmic results,
validate schemas and hashes, and emit macros/tables with evidence labels:

- exact optimum or exact lower bound;
- exact selected-library safety certificate;
- solver-reported status;
- floating-point runtime diagnostic;
- synthetic result; or
- retrospective financial result.

Update the theorem ledger, artifact manifest, reproducibility record, risk
register, journal sections, supplement graph, and cover letter in separate
coherent commits. Do not modify the frozen preprint or its release bundle.

Gate G11:

- every new manuscript number has a committed source artifact and generator;
- all references/citations resolve;
- theorem and evidence labels agree across prose, ledger, code, and tables;
- the public/license audit passes under the decided journal policy; and
- submission-only author confirmations are resolved.

### Phase 12 — declared final gates

Run targeted tests throughout Phases 1--11. At the first release-candidate gate,
run the full Julia package suite, selected Lean build/audit, all new nonmutating
artifact checks, manuscript/supplement compilation, bibliography checks, and
journal submission checks.

Run the repository's complete verification suite only at the declared final
gate. Do not run the N=1024 study or licensed workflows merely because they are
part of a generic target; use immutable committed results and separately scoped
public checks unless the replay itself is explicitly requested.

## Proposed experiment matrix

The final cells and sizes must be locked later; this table fixes roles, not
unregistered parameters.

| Evidence layer | Algorithms | Primary purpose | Required oracle/certificate | Risk |
|---|---|---|---|---|
| Exact hand and exhaustive fixtures | enumeration, DP, MILP, rechecked deletion, preprocessing, optional greedy | correctness and counterexamples | at least two independent complete oracles plus original-problem certificate | Low to medium |
| Synthetic scaling | DP, MILP, rechecked deletion, preprocessing variants, optional theorem-qualified greedy | finite runtime/state/model-size and solution-quality comparisons | exact original-problem safety for every candidate; exact optimality only where oracle completes | High |
| Financial locked comparison | same algorithms supported by identity incidence | real-instance burden and agreement diagnostics | exact original frontier/closure/burden/inactive certificate; decision hash before ex post read | Medium compute, high governance |
| Frozen N=1024 | no new algorithms | prior evidence only | existing committed audit | Must remain unchanged |

## Commit discipline

Prefer small commits after their targeted gate:

1. provenance decision and tests;
2. theorem specification and exact falsification fixtures;
3. tagged adapter and tests;
4. focused Lean theorem and audit;
5. one preprocessing rule family and tests per commit;
6. DP plus independent-oracle tests;
7. greedy boundary or proved conditional theorem;
8. MILP/schema hardening;
9. design/registry/lock with no outcomes;
10. smoke results and audit;
11. explicitly authorized final results and audit;
12. locked financial comparison; and
13. manuscript/provenance integration.

Never combine a design lock with result generation in the same commit.

## Exact next recommended task

The next task should be **Phase 0 only**: reconcile the 25 stale Artifact-ID
hash rows by deciding which paths are historical and which need new versioned
IDs, then make the journal gate verify the frozen release without regenerating
it. Do not modify `release/v0.1.1-arxiv/`. After G0, the next scientific task is
the Phase 1 tagged-cover and worst-case-gap specification; no algorithm or new
study should begin before that specification survives G1.
