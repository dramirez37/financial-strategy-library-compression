# Registered Algorithmic Compression Benchmark v1: generator dry run

Status: **DRY/PILOT GENERATION ONLY; NO FINAL INSTANCE OR ALGORITHM OUTCOME GENERATED**

This report exercises the common instance schema and the registered generator mechanisms. It records requested and realized structure, not optimum burden, heuristic gaps, solver behavior, runtime, or any other comparative outcome. Final-registry rows were neither instantiated nor solved.

All numbers below are emitted from generator records. Densities, overlap, association, and weights use exact `Rational{BigInt}` arithmetic.

| Instance | Phase/family | Generator or mechanism | Requested density | Realized density | Unique rows (requested/realized) | Bundles (requested/realized) | Module Jaccard | Frontier-module rank association | Instance SHA-256 |
|---|---|---|---:|---:|---:|---:|---:|---:|---|
| `DRY-001` | dry_run/dry_run | `trivial-mandatory-only-v1` | UNSPECIFIED | 1//1 | UNSPECIFIED/0 | UNSPECIFIED/1 | 0//1 | 0//1 | `0162e2a18e3e39eb5c57aec6e778b07b0258d1f04059418a5786f9bb30342325` |
| `DRY-002` | dry_run/dry_run | `trivial-unique-module-v1` | UNSPECIFIED | 1//1 | 2/2 | UNSPECIFIED/1 | 0//1 | 0//1 | `415ddd82481018057280db04421b057c82f1abe44dafba345577f645ba339724` |
| `DRY-003` | dry_run/dry_run | `trivial-triangle-v1` | UNSPECIFIED | 3//4 | 0/0 | 0/3 | 1//3 | 0//1 | `a69599abf461e01bbb6f1f618bcb5223b3193236745bfd1d4ed6c8209c7820d1` |
| `P-A-001` | pilot/small_exact | `small-exact-tagged-v1` | 1//8 | 11//36 | 1/1 | 0/0 | 1//9 | 0//1 | `3f3e4f56414b8b7ced3e9422c272990c2afedf3cc3d2bd2df726fa2ee919ad4e` |
| `P-A-002` | pilot/small_exact | `small-exact-tagged-v1` | 3//8 | 7//18 | 0/0 | 1/1 | 1//8 | 3//5 | `81e5508433d648106a9006a29c2126c99601e40e12b0f4eb0805252fbd16ce38` |
| `P-B-001` | pilot/structured | `structured-tagged-incidence-v1` | 1//8 | 1//8 | 0/0 | 0/0 | 6263//144900 | 34//465 | `c5f9dee94085b8baa74c56e57b49eb6cb49d257d5b450cc212379c58b81b17e8` |
| `P-B-002` | pilot/structured | `structured-tagged-incidence-v1` | 3//8 | 3//8 | 2/2 | 4/4 | 63//230 | 97//465 | `7085e4d4348bad6371afbe5b20773774a3728bb524e712c447e91482a77b7775` |
| `P-C-001` | pilot/adversarial | `unbounded_heaviest_safe_first_gap` | UNSPECIFIED | 13//25 | UNSPECIFIED/0 | UNSPECIFIED/1 | 1//10 | 0//1 | `65cbe49716284c74f44acbf3b8694a797df4e9dab0d02930629bb536ead8e9b6` |
| `P-C-002` | pilot/adversarial | `many_tied_optima` | UNSPECIFIED | 1//1 | UNSPECIFIED/0 | UNSPECIFIED/4 | 1//1 | 0//1 | `c75a64c83c01a506b7737df5b20171f97bc5f73aa317a10dfd258818192292e5` |
| `P-C-003` | pilot/adversarial | `dense_duplicate_coverage` | UNSPECIFIED | 1//1 | UNSPECIFIED/0 | UNSPECIFIED/8 | 1//1 | 0//1 | `56a7aa0bd8790478fda949d7e0303dfd6fa48ecc58a388ca8762554a4a2049a1` |
| `P-C-004` | pilot/adversarial | `dominance_heavy` | UNSPECIFIED | 1//2 | UNSPECIFIED/0 | UNSPECIFIED/0 | 4//21 | 0//1 | `3a4d645cf15ed4469f7848e5689e5a2ee0ebdbf2efd26ec4da3afea9b69c0e4c` |
| `P-C-005` | pilot/adversarial | `rare_mandatory_requirements` | UNSPECIFIED | 13//25 | UNSPECIFIED/1 | UNSPECIFIED/0 | 1//5 | 0//1 | `119ec64e2f02b61e98c8dc67e561951528949bd56e3ebf1aa89385aa8a99397e` |
| `P-C-006` | pilot/adversarial | `symmetric_hard` | UNSPECIFIED | 5//8 | UNSPECIFIED/0 | UNSPECIFIED/0 | 113//315 | 0//1 | `59669c7d4ef8942a6ff0d1a1bde9a9b2249415ee5289efc477e11f13f8e3b322` |
| `P-C-007` | pilot/adversarial | `bundle_versus_singleton` | UNSPECIFIED | 8//15 | UNSPECIFIED/0 | UNSPECIFIED/2 | 1//6 | 0//1 | `4df0a0ae08125cf414f82aa0456b56150258f5c9bd90e25abf921e631689e77e` |

## Validation observations

- Pilot and final seed domains were checked for disjointness while loading the registries. No final seed was passed to a generator.
- Every example passed `validate_journal_compression_instance`; every realized tagged row has at least one carrier.
- Requested factor levels and realized exact statistics coexist in each serialized generation record. A label such as `low_clustered` is a mechanism setting, while the Jaccard value is measured from the realized module sets.
- Structured pilot densities equal their registered targets; registered unique-row and bundle counts equal the realized counts under the documented half-up integer rounding rule.
- The sparse seven-strategy pilot cannot attain density `1//8` while retaining six covered rows and exactly one unique row. Family A treats factor names as small-instance sanity settings, as registered; the report exposes the realized `11//36` density rather than silently relabeling it.
- Adversarial seeds permute logical strategy labels only. The mathematical incidence and exact weights remain mechanism-defined.

## Realized-statistic definitions

- Active strategies are all strategies other than the identifier `inactive`, including a mandatory active strategy in the rare-mandatory family.
- Active coverage density is the number of realized active-strategy incidences divided by tagged rows times active strategies.
- A realized bundle covers at least `ceil(3r/4)` tagged requirements. This threshold is applied to incidence, not to a generator label.
- Unique-carrier frequency is measured over the complete realized tagged universe, including the inactive strategy as a possible zero-frontier carrier.
- Module overlap is the exact mean pairwise Jaccard index among active module sets, omitting pairs whose union is empty.
- Frontier-module association is exact Kendall tau-a on each active strategy's frontier- and module-row carrier counts. Ties contribute zero; the registered correlation level remains a generation mechanism rather than a promised coefficient.

## Scope boundary

This dry run is synthetic generator evidence only. It is not a final registered benchmark, theorem proof, solver certificate, financial audit, runtime study, or empirical finding.
