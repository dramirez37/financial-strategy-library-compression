# Proposal Robustness Computation Amendment 005

The first sealed robustness run completed three ETF cell artifacts and then stopped.
Before gate-passed computation, a local initialization expression called the
common-equity cap formatter with an empty placeholder grid; equity tasks therefore
failed before writing artifacts.  No public or local manifest and no result seal
existed.  No evaluation-year value was inspected, materialized, or used.

This amendment binds the three completed ETF artifacts and changes only initializer
control flow: ETF cap dispositions are initialized immediately, while common-equity
cap dispositions are constructed after the real grid and top-50 computation exist.
The registered grid, action sets, resampling, seeds, max-t families, shrinkage,
hurdles, cap/sham dispositions, public boundary, and primary-choice reproduction
check are unchanged.  The result-seal verifier is amended only to recognize this
lock.  Historical files and partial artifacts are not overwritten.
