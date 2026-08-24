# Online supplement

This directory indexes the complete online-supplement bundle intentionally
excluded from the main manuscript PDF. Linked repository paths below are
constituent supplement artifacts rather than abbreviated manuscript
references.

`main.tex` is the standalone supplement driver. Build it with:

```text
bash build.sh
```

The current compiled supplement contains:

- S1. Belief Occupation and Coverage;
- S2. Frontier--Closure Interaction; and
- S3. Additional Comparative Statics and Counterexamples, including the
  auxiliary finite-model illustration and conditional replacement
  formulation moved from the primary appendix; and
- S4. Complete Canonical Numerical Records;
- S5. Complete Registered Randomized Study;
- S6. Full Financial Audits and Secondary Tests; and
- S7. Reproducibility Records.

The files indexed below are constituent records supporting the compiled
S1--S7 supplement.

## Literature audit

- `literature_novelty_audit.tex` contains the complete source-by-source audit
  against the four exact novelty claims, moved out of the main literature
  review.

## Full Lean correspondence

- `lean_correspondence.tex` contains the declaration-level manuscript-to-Lean
  table.
- `validation_matrix.tex` preserves the full evidence matrix and
  manuscript-to-formal correspondence moved out of Appendix F.
- `passive_gap_sum.tex` contains the extended occupancy-weight illustration
  and exact delayed-benefit example moved out of the main PDF.
- `../../formal/StrategyInnovation/Audit/AxiomAudit.lean` is the executable
  comprehensive axiom audit, containing the complete declaration audit rather
  than a selected table.
- `../../THEOREM_LEDGER.md` records the claim-level correspondence and axiom
  status.

## Theorem and implementation correspondence

- `../../formal/README.md` and `../../julia/README.md` map the proof and
  computational components.
- `../../ARTIFACT_MANIFEST.md` and `../../REPRODUCIBILITY.md` map generated
  outputs to their producers and drift checks.
- `../../shared/exact_fixtures/` and
  `../../formal/StrategyInnovation/Fixtures/Generated.lean` provide the exact
  Julia--Lean implementation bridge.

## Extended experiments

- `s5_complete_registered_randomized_study.tex` records the complete registered
  study, factor and prefix diagnostics, frozen pilot, and policy map.
- `s6_full_financial_audit_secondary_tests.tex` records the full financial
  estimands, audit results, resampling design, and secondary coverage tests.
- `s7_reproducibility_records.tex` records commands, configuration and
  amendment histories, hashes, and exhaustive artifact-prefix locations.
- `../../RANDOMIZED_LIBRARY_REPORT_V2.md` reports the registered
  $N=1024$ raw-realizable finite-library stress test.
- `../../RANDOMIZED_LIBRARY_OPTIMIZATION_EXTENSION_V1.md` and the matching
  `../../experiments/results/summaries/randomized_library_v2_optimization_v1_*`
  tables contain the complete global-compression, capacity, breakpoint, and
  elasticity results summarized in Section 7.
- `../../RANDOMIZED_LIBRARY_REPORT.md` is the frozen $N=90$ pilot report and
  is not pooled with v2.
- `../../APPROXIMATE_COMPRESSION_REPORT.md` reports exact and heuristic
  size--loss trade-offs.
- `../../experiments/results/SYNTHETIC_REPORT.md` reports the controlled
  mechanism suite.
- `../../experiments/results/summaries/` contains the complete exact
  falsification grids, persistence surfaces, one-at-a-time response surfaces,
  and switch-bracket tables; the compiled appendix retains only selected
  witnesses and diagnostics.
- `../../experiments/financial_terminal_audit/` and
  `../../experiments/financial_annual_walkforward_audit/` contain the two locked
  financial audit protocols and aggregate reports.

The detailed records preserve mathematical validity, kernel verification,
Julia validation, and empirical relevance as separate evidence dimensions.
