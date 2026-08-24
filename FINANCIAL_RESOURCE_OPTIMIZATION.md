# Financial audit resource optimization

This separately registered extension leaves every parent numerical result unchanged. The primary burden is `w_s = 1`; three secondary schedules were frozen before any resource-optimization result was computed. Held-out opportunity quality is reported only after selection and never enters a weight.

Design lock: `18a9d13f4a17d128d66b0d221b2938ab95f0de9c82c268e20e4d2d2167055f20`. Exact `Rational{BigInt}` values in the CSVs are authoritative.

## Primary minimum-cardinality results

| audit | source | stepwise safe | global safe | gap | frontier only | modules | global maintenance saved |
|---|---:|---:|---:|---:|---:|---:|---:|
| Terminal financial audit | 80 | 25 | 25 | 0 | 3 | 38 | 55//1 |
| Annual walk-forward financial audit | 202 | 100 | 100 | 0 | 5 | 113 | 102//1 |

Every global safe selection exactly reproduces the losslessly rationalized validation frontier and the complete identity closure. Existing stepwise and frontier-only endpoints are reported under both exact equality and their original frozen tolerance; their rules and orders were not changed.

## Registered burden schedules

| audit | schedule | global size | source burden | selected burden | burden saved |
|---|---|---:|---:|---:|---:|
| Terminal financial audit | `uniform_cardinality` | 25 | 80//1 | 25//1 | 55//1 |
| Terminal financial audit | `nonshared_modules` | 25 | 80//1 | 25//1 | 55//1 |
| Terminal financial audit | `validation_computation` | 25 | 1558//1 | 338//1 | 1220//1 |
| Terminal financial audit | `documented_complexity` | 25 | 314//1 | 85//1 | 229//1 |
| Annual walk-forward financial audit | `uniform_cardinality` | 100 | 202//1 | 100//1 | 102//1 |
| Annual walk-forward financial audit | `nonshared_modules` | 100 | 202//1 | 100//1 | 102//1 |
| Annual walk-forward financial audit | `validation_computation` | 100 | 3508//1 | 1170//1 | 2338//1 |
| Annual walk-forward financial audit | `documented_complexity` | 100 | 734//1 | 315//1 | 419//1 |

The schedules are fixed maintenance (`uniform_cardinality`), fixed maintenance plus source-local uniquely carried modules, documented rolling validation computation, and documented nonbaseline model complexity.

## Ex post enabled-descendant opportunity quality

- **Terminal financial audit:** source/global/stepwise = `8162187676336809//72057594037927936`; frontier-only = `8050087745711267//72057594037927936`; exact loss = `56049965312771//36028797018963968`.
- **Annual walk-forward financial audit:** source/global/stepwise = `7728204652088667//72057594037927936`; frontier-only = `3007756162559999//576460752303423488`; exact loss = `58817881054149337//576460752303423488`.

These quality values retain the parent information timing: the terminal audit uses the locked 2020–2024 period after its validation decision hash; the annual walk-forward audit uses next-year targets after each annual decision hash.

## Certificates and claim boundary

HiGHS reported `OPTIMAL` for every global search. Each binary vector was then reconstructed and checked with exact rational frontier arithmetic, exact module-set closure, exact integer burdens, and a SHA-256 selected-library certificate. Numerical solver tolerances are not treated as a proof of global optimality; the global-search claim and exact post-solve safety certificate are reported separately. Full membership certificates, retained modules, frontier coordinates, and burdens are in the companion CSVs.

Parent artifacts rechecked during the registered solve: 40 files; all hashes were unchanged before and after execution.
