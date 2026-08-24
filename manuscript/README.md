# Manuscript build

The reproducible manuscript path uses latexmk with pdfTeX. The environment
audited on 2026-07-20 provides:

- pdfTeX 3.141592653-2.6-1.40.26 (TeX Live 2024);
- latexmk 4.83;
- BibTeX 0.99d;
- Biber 2.19.

The manuscript has nine main-text sections and Appendices A--F in the
publication order in `main.tex`. The table of contents has been removed and an
abstract added. Appendix F defines the
evidence categories, gives a compact six-channel status matrix, and provides
a one-page declaration-free manuscript-to-formal correspondence summary. The
full declaration-level correspondence, axiom audit, theorem ledger,
implementation map, and extended experiments are indexed under
`manuscript/online_supplement/`.

Active mathematical environments remain restricted to the audited result
families in `THEOREM_LEDGER.md`. The frontier--closure interaction uses the
corrected relative-action-saturation condition because primitive frontier
independence alone is insufficient. Unqualified dynamic innovation
equivalence is the unified cost-sensitive raw-model relation.
The financial section treats the locked terminal and annual walk-forward
exercises as innovation-safe compression audits; their older generated source
drafts remain separate audit artifacts and are not included in the manuscript.

BibTeX is the selected bibliography processor. Biber is detected and recorded
but is not used unless a future, documented bibliography decision selects it.

From the repository root, run:

    ./manuscript/build.sh

The script requires latexmk, pdflatex, bibtex, and rg. It forces a pdfTeX pass
through latexmk, runs enough additional passes to resolve references, then
rejects the final LaTeX log if it contains undefined citations, undefined
references, or missing bibliography/input files. Normal first-pass reference
warnings do not cause a false failure after the final pass has resolved them.
Generated files stay under manuscript/build/ and are ignored except for its
tracked README.
