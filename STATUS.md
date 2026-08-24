# Release Status

The `v0.1.0-preprint` source tree is reader-facing and reproducible through the
commands in `REPRODUCIBILITY.md`.

- Formal claim status: `THEOREM_LEDGER.md`
- Generated-artifact lineage: `ARTIFACT_MANIFEST.md`
- Licensed-data boundary: `DATA_ACCESS.md`
- Public release gate: `make preprint-check`

The latest documentation curation removed redundant root-level technical
notes without changing manuscript source, model code, registered designs,
seeds, numerical outputs, or theorem statements.

The public Markdown math audit standardized eligible reader-facing formulas
on GitHub-supported `$...$` and `$$...$$` delimiters, repaired two previously
undelimited expressions, and synchronized the approximate-compression report
renderer. Byte-frozen registered design inputs remain unchanged. Mathematical
statements and scientific results are unchanged.

The preprint-facing resource terminology now distinguishes the primary burden
$W$, with zero-weight inactive strategy, from the canonical benchmark's
translated display burden $\widetilde W=1+W$. Figure 3, the canonical tables,
the supplement, reproducibility notes, theorem ledger, and public artifact
metadata use that distinction consistently. Table 2 now correctly labels
$31/160$ and $1/8$ as burden and cardinality shares removed. The randomized
study, numerical values, theorem statements, Lean sources, and registered
resource inputs were not changed. Generated-artifact checks, source-reference
checks, and both LaTeX builds pass; the affected PDF pages were visually
inspected.

The public GitHub tree also retains the documented `full_check.sh`
compatibility alias and executable modes for the public audit and preprint
entry points. `make preprint-check` passes on the exact publication tree.
