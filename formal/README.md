# Lean Environment

This is a standalone mathlib-based Lean project. The environment is pinned to
matching stable releases; no release candidate or nightly toolchain is used.

## Pinned versions

| Component | Pin |
|---|---|
| Lean | `leanprover/lean4:v4.32.0` |
| Lean commit | `8c9756b28d64dab099da31a4c09229a9e6a2ef35` |
| mathlib | stable tag `v4.32.0` |
| mathlib commit | `81a5d257c8e410db227a6665ed08f64fea08e997` |
| Lake | `5.0.0-src+8c9756b` |

The mathlib tag's `lean-toolchain` file specifies the same Lean 4.32.0
toolchain. `lakefile.toml` pins the exact mathlib commit, and
`lake-manifest.json` pins all transitive dependencies resolved by Lake.

## Exact bootstrap

From the repository root:

```sh
cd formal
elan toolchain install leanprover/lean4:v4.32.0
lake update
lake exe cache get
lake build
```

`lake update` is required to verify that the committed manifest is reproducible.
`lake exe cache get` retrieves mathlib's precompiled cache and is safe to rerun.

## Smoke theorem

`StrategyInnovation.Basic.Smoke` contains
`StrategyInnovation.smokeNatAddZero`. It is an infrastructure theorem, not a
manuscript theorem. Its `#print axioms` output must report an empty dependency
list before the environment is marked successful.

## Focused proof audits

After `lake build`, the supporting theorem families can be audited with:

```sh
lake env lean StrategyInnovation/Audit/ManuscriptLint.lean
lake env lean StrategyInnovation/Audit/AxiomAudit.lean
lake env lean StrategyInnovation/Audit/Foundations.lean
lake env lean StrategyInnovation/Audit/RawModel.lean
lake env lean StrategyInnovation/Audit/RawToCompressed.lean
lake env lean StrategyInnovation/Audit/UnifiedDynamicInnovation.lean
lake env lean StrategyInnovation/Audit/RawFrontierClosure.lean
lake env lean StrategyInnovation/Audit/DynamicInnovation.lean
lake env lean StrategyInnovation/Audit/FrontierClosure.lean
lake env lean StrategyInnovation/Audit/SafeDeletion.lean
lake env lean StrategyInnovation/Audit/FrontierPruningLoss.lean
lake env lean StrategyInnovation/Audit/FiniteHorizon.lean
lake env lean StrategyInnovation/Audit/Decomposition.lean
lake env lean StrategyInnovation/Audit/InnovationEquation.lean
lake env lean StrategyInnovation/Audit/Contraction.lean
lake env lean StrategyInnovation/Audit/UnifiedCanonical.lean
lake env lean StrategyInnovation/Audit/SystemInteraction.lean
lake env lean StrategyInnovation/Audit/PrimitiveSubstitution.lean
lake env lean StrategyInnovation/Audit/JointDescendantLowerBound.lean
lake env lean StrategyInnovation/Audit/CoveragePotential.lean
lake env lean StrategyInnovation/Audit/SingleGap.lean
lake env lean StrategyInnovation/Audit/MultiGapRegion.lean
lake env lean StrategyInnovation/Audit/SafeCompressionOptimization.lean
lake env lean StrategyInnovation/Audit/PenalizedEnvelope.lean
lake env lean StrategyInnovation/Audit/CapacityValue.lean
lake env lean StrategyInnovation/Audit/Elasticity.lean
```

The first command is the release linter; the second executes the comprehensive
752-command axiom audit, including every declaration and definition named in
the active manuscript correspondence. See `../THEOREM_LEDGER.md` for the
current reconciliation.

These commands cover F0, R0, T1--T7, UDI, supporting F1--F8, S4--S7, C2,
OPT-FND, finite PEN/CAP, BEM, CED, and the finite IDCV core:
foundations, derived admission and local compression, raw projection, unified
quotient and raw characterization, legacy quotient and characterization,
deletion, pruning loss, finite value, insertion decomposition, passive
innovation equation, discounted contraction, finite coverage-potential and
single-gap geometry, and the multi-gap limitation construction. Each audit
records declared axiom dependencies and runs focused linter sets.

## Generated exact consistency fixtures

`StrategyInnovation/Fixtures/Generated.lean` is generated together with the
versioned JSON records by `julia/scripts/export_exact_fixtures.jl` and is
imported by the root module. Its transparent `ℚ` evaluators and anonymous
examples check seven finite Julia/Lean fixture calculations. They use ordinary
kernel-checked tactics and make no general theorem claim. Regenerate from the
repository root; do not edit the generated Lean file by hand.
