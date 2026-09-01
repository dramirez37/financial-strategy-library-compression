# Amendment 016 — Julia 1.12 analysis key-shape correction

**Date:** 2026-09-01

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

## Information available before this amendment

The Lock 015 continuation completed the count-only preflight at 8/8, wrote all
180 terminal postdecision records, and passed the independent structural and
postdecision result audits. The audit accounts for 72 structural-construction
failure records, nine terminal-`DP` unavailable records, 72 insufficient-
profile unavailable records, and 27 ordinary postdecision records. It retains
all 1,260 registered algorithm rows. The downstream analysis then stopped
before writing an artifact.

The exception was `UndefKeywordError: keyword argument dims not assigned` at
the construction of the 180 registered analysis keys. Julia 1.12 correctly
preserved the three-dimensional shape of a comma-separated comprehension;
`sort!` requires a dimension for that array. No analysis table, figure,
manifest, or analysis audit existed when this amendment was written. Numerical
postdecision values, selected identities, burden results, and solver statuses
were not inspected during diagnosis; only schema counts and audit aggregates
were read.

## Mechanical correction

The registered key comprehension is flattened with `vec` before stable
lexicographic sorting. This is the same correction already used by the
independent result auditor. The key members, ordering rule, partitions,
algorithms, estimands, denominators, statistical summaries, tables, and figures
are unchanged. A test requires exactly 180 unique, sorted registered analysis
keys.

The audited Lock 015 result records are immutable inputs to the resumed
analysis. Locks 001--015 remain immutable historical artifacts.
