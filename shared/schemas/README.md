# Shared Schemas

`exact_fixture.schema.json` is the adopted JSON Schema for exact finite
Lean–Julia consistency fixtures. Its current version is
`lean-julia-exact-fixture-v1`.

The schema fixes the field names and JSON types for belief labels, exact
rational transition rows, the discount, module and strategy catalogs,
libraries, research projects, and typed expected outputs. Exact numbers are
canonical strings of the form `numerator//positive_denominator`; theorem
fixtures never pass through a binary floating representation.

JSON Schema checks the record shape. The Julia exporter additionally enforces
the finite-model semantics that JSON Schema cannot express conveniently:
square transition matrices, exact row sums of one, nonnegative probabilities
and costs, valid discount and survival factors, unique identifiers, inactive
strategy invariants, dimension agreement, and complete reference resolution.

See [`../LEAN_JULIA_BRIDGE.md`](../LEAN_JULIA_BRIDGE.md) for the generation and
verification contract.
