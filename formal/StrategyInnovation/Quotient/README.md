# Quotient

`UnifiedDynamicInnovation.lean` is the canonical publication-facing layer. It
defines cost-sensitive dynamic innovation equivalence from the unified raw
model, proves finite- and infinite-value preservation, constructs the finite
quotient, proves compressed-state sufficiency, and retains only restricted
representation refinement.

`RawFrontierClosure.lean` is the canonical T2 characterization layer. It
derives the forward direction from the raw closure-indexed generator and
admission definitions plus T1, and obtains the converse from an explicit
observable raw closure-detectability predicate. It contains exact finite
counterexamples for raw-identifier-sensitive generation and behaviorally
invisible closure.

`DynamicInnovation.lean` is deprecated as a final-model interface. It retains
the abstract cost-free primitive equivalence and quotient needed by the legacy
F1--F4 supporting results. `MIGRATION.md` gives the exact name map.
`FrontierClosure.lean` declares a modular generator, states its exact
frontier--closure factorization condition, proves the characterization under
closure identifiability, and supplies finite counterexamples to both missing
observation channels. It remains only the deprecated primitive F2 supporting
layer and is not the proof of raw T2.
