# Financial Innovation-Challenge Panel v2 — execution amendment 006

Execution attempt 006 staged registered daily source file 2 into 88 terminal
Parquet chunks and then stopped because source files 1 and 3 each contained a
return equal to `-1.0`, while the implementation required `dlyret > -1`.
No provisional universe, completeness census, strategy score, seed-derived
object, solver result, or held-out outcome had been computed.

A complete aggregate audit of the registered delivery found eight returns at
or below `-1.0`: four, one, and three in registered file order. All eight are
exactly `-1.0`; none is below `-1.0`; all eight carry an observed delisting
flag. Seven carry return-quality flag `MV` and are already unusable under
Execution Amendment 005. One carries `NA` and represents a valid observed
total loss.

The corrected staging rule accepts finite total returns greater than or equal
to `-1.0` and continues to fail closed on any value below `-1.0`. A value of
`-1.0` has gross return zero and is mathematically compoundable. The existing
`MV` incompleteness rule and explicit-delisting outcome rule are unchanged.
This correction does not change the estimand.

At the user's earlier cleanup direction, the 90 partial local-data files and
two local result files from attempt 006 are removed after their counts, total
bytes, hashes, and directory aggregate are frozen in
`FAILED_EXECUTION_CENSUS_002.toml`. No unrelated experiment is touched.

