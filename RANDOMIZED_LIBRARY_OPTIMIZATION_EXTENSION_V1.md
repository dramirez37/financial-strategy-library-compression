# Registered randomized-library optimization extension v1

This is a separately versioned exact optimization extension of the frozen
`N = 1024` randomized-library v2 registry. It does not read,
overwrite, or pool the parent outcome tables. Every trial enumerates all 32
inactive-containing sublibraries and all primary numbers below are exact
`Rational{BigInt}` values.

Compact exact fractions appear directly. When an across-trial mean has a very
large reduced denominator, this report prints a secondary decimal and the
factor-summary CSV retains the complete exact rational.

## Registered design

- Outcome-blind burden is zero for inactive and `1 + |raw modules|` for each
  active source strategy.
- Registered capacity fractions are `0, 1/4, 1/2, 3/4, 1`; registered prices
  are `0, 1/4, 1/2, 1, 2, 4`.
- The design lock is `8fd0ce290ea1e91958e91834b4a9bcf989703106d06d1dc6d670148151aea975` and the frozen parent registry is
  `669c055f54c86706bd9b2003c6c9f4628c647245909940eea393f3bd40af115c`.

## Primary exact results

- Positive greedy-gap frequency: `0//1`.
- Mean / maximum greedy burden gap: `0//1` /
  `0//1`.
- Mean weighted / cardinality safe-compression ratio:
  `31//160` /
  `1//8`.
- Frontier-only positive-loss frequency and mean normalized signed loss:
  `199//512` /
  `0.03513792 (full exact value in the factor-summary CSV)`.
- Registered-grid / attainable-grid nonconcavity frequency:
  `97//1024` /
  `921//1024`.
- Mean total / positive active price breakpoints:
  `1043//256` /
  `787//256`.

| Capacity point | Mean exact normalized productive value |
|---|---:|
| B0 | 0//1 |
| B25 | 0.73067129 (full exact value in the factor-summary CSV) |
| B50 | 0.92518480 (full exact value in the factor-summary CSV) |
| B75 | 0.99409713 (full exact value in the factor-summary CSV) |
| B100 | 1//1 |

| Price interval | Demand elasticity | Operational contribution | Generative contribution | Defined demand / channel trials |
|---|---:|---:|---:|---:|
| E025_050 | -3954971//28385280 | -0.02650664 (full exact value in the factor-summary CSV) | 0.00266454 (full exact value in the factor-summary CSV) | 1024 / 1024 |
| E050_100 | -4435883//14192640 | -0.09193489 (full exact value in the factor-summary CSV) | 0.00171916 (full exact value in the factor-summary CSV) | 1024 / 1024 |
| E100_200 | -455797//1290240 | -0.13937934 (full exact value in the factor-summary CSV) | -0.01223120 (full exact value in the factor-summary CSV) | 1024 / 1024 |
| E200_400 | -19//96 | -0.09667582 (full exact value in the factor-summary CSV) | -0.01638676 (full exact value in the factor-summary CSV) | 1024 / 1024 |

## Hard gates

All registered hard gates passed: every reported global optimizer is the full
argmin or argmax correspondence from complete enumeration; all safe optima
preserve frontier and general closure; their productive values equal the
source exactly; channel decompositions close exactly; capacity optima are
feasible; and optimal burden correspondences are weakly decreasing in the
registered price grid. These are finite-instance Julia validation results,
not Lean theorem evidence.
