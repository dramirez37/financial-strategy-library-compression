# Exact Lean–Julia Consistency Bridge

## Contract

The bridge has one source of fixture construction:
`julia/scripts/export_exact_fixtures.jl`. Each fixture is built with
`Rational{BigInt}`, validated through the reusable Julia finite-model
constructors, and evaluated with the Julia frontier, closure, gap, occupation,
coverage, and one-shot cost-covering operations. The exporter renders the same typed fixture
object to:

- one versioned JSON record in `shared/exact_fixtures/`; and
- one definition plus kernel-checked calculation examples in
  `formal/StrategyInnovation/Fixtures/Generated.lean`.

The generated Lean module defines exact strategies, libraries, projects,
transition rows, discounts, and expected outputs. Its transparent finite-list
evaluators independently reduce frontiers, module availability, candidate and
project gaps, discounted gap sums, gross coverage, one-shot cost-covering sets, and
connected-component counts. The examples close with ordinary kernel-checked
`simp` and `norm_num` tactics; they use neither `native_decide` nor a generated
axiom.

## Determinism and schema evolution

Version 1 is identified by `lean-julia-exact-fixture-v1`. Fixture files are
emitted in lexicographic fixture-ID order. Object field order, catalog order,
expected-output order, whitespace, and final newlines are deterministic.
Rationals are reduced and emitted as canonical strings. A semantic or field
change requires a new schema version rather than an in-place reinterpretation
of version 1.

Regenerate:

```sh
julia --project=julia julia/scripts/export_exact_fixtures.jl
```

Check without writing:

```sh
julia --project=julia julia/scripts/export_exact_fixtures.jl --check
```

The Julia tests compare every in-memory render byte-for-byte with the
committed artifacts and exercise invalid kernels, discounts, duplicate IDs,
and unresolved references. CI runs the exporter normally and then runs
`git diff --exit-code` on both generated destinations. `lake build` compiles
the generated examples through the formal root module.

## Claim boundary

The bridge establishes that the two implementations agree on seven selected
finite exact records and that Lean's kernel accepts the stated calculations.
It catches serialization drift, arithmetic disagreement, ordering changes,
and fixture-specific definition mismatches.

It does not establish that Julia is correct on all inputs, prove a general
Lean theorem, replace any theorem's assumptions or axiom audit, connect the
primitive fixture evaluator to every richer raw-model definition, or turn a
Float64 experiment into proof evidence. General claims remain governed by
`THEOREM_LEDGER.md` and require their own named Lean declarations and recorded
`#print axioms` results.
