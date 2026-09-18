# Manuscript and supplement review

Version: v0.3.1-ssrn. Reviewed 18 September 2026.

## Disposition

The current article and supplement have undergone a substantive, mathematical,
statistical, reproducibility, and presentation review. The revision adds three
reproducible figures and corrects the claim boundaries described below.
**An unqualified SSRN-readiness claim is withheld.** The paper-specific local
checks pass, but the repository-wide Julia regression gate has an unresolved
source-lock mismatch. The financial adoption screen also has no established
simultaneous coverage guarantee; the paper now reports it only as a fixed
screening policy. Publication of this review package is not an SSRN submission.

The scientific contribution is a conditional retention principle and its exact
weighted-cover representation, supported by proofs, counterexamples, a bounded
computational comparison, and descriptive financial and synthetic applications.
The evidence does not establish a market premium, institutional monetary cost
savings, or the efficacy of an inferentially qualified investment policy.

## Review and resolutions

| Area | Finding and action | Evidence and remaining boundary |
|---|---|---|
| Financial motivation | The opening now asks about preserving the best modeled operating value and declared research capabilities. Figure 1 supplies a concrete equal-burden example. | The model selects a catalog entry; it does not preserve every raw strategy identity or an unmodeled allocation across entries. |
| Contribution and literature | The article distinguishes its retention semantics from classical weighted set cover, ordinary state aggregation, costly learning, and organization capital. | Generic cover algorithms are not claimed as new; capabilities and burden are specified inputs, not institutional estimates. |
| Projection theorem | The supplement now gives the finite-calendar Bellman expressions, zero terminal salvage, and the requirement that a project fit within the remaining horizon. The result is stated at embedded decision epochs. | Arbitrary path--outcome coupling can require history during an unfinished project. Current belief, project identity, and time remaining alone are not asserted sufficient. |
| Stationary scope | The supplement uses the same discount range as the article, including zero, and distinguishes the human contraction argument from supplied formal contraction obligations. | The Lean encoding has project-only duration and operation flags. Its scope is recorded explicitly rather than equated with every possible application. |
| Bridge-loss result | The actual optional value is the positive part of discounted expected gain minus cost. The cap expression is a sharp upper bound, attained when the gain equals the cap. | A cap alone does not justify equality for a smaller gain. The small exact check covers zero gain, unprofitable research, the break-even point, and attainment of the cap. |
| Covering and algorithms | Reviewed tagged-cover equivalence, nonidentity-closure counterexample, NP membership/reduction, preprocessing qualifications, DP invariant, greedy transfer, and deletion-gap proof. Clarified the unit-weight normalization branch and the optimal-predecessor argument. | Solver optimality, exact feasibility, universal proof, and finite fixture evidence remain distinct. No new complexity or approximation claim is introduced. |
| Formal correspondence | Added the projection, canonical bridge-loss construction, and value decomposition to the supplement's evidence table. | The identity is elementary algebra; finite Lean arithmetic checks do not prove the universal deletion-gap theorem. The full local Lean build and 784-declaration axiom audit passed. |
| Benchmark interpretation | Checked the complete census and original-coordinate certificates. All 3,907 outcomes, 381 unsuccessful units, and 31 complete agreements out of 38 required comparisons remain. | Failed generation cells, solved-by-preprocessing instances, incomplete comparisons, compilation time, and worker contention preclude general solver-speed or population claims. |
| Financial information boundary | Reviewed the formation, compression, proposal, and evaluation timing; exact quantized profiles; comparator budget cap; cash fallback; and source/result seals. | This is retrospective development evidence. Overlapping origins are not independent replications. Licensed return paths were not recomputed in this review. |
| Financial inference | Confirmed that the implementation uses reflected bootstrap errors and fixed resampling standard errors. Replaced confidence-guarantee language with “registered screening score,” and added the exact rule and an analytic asymmetric-error counterexample. | Nominal 90% tuning does not establish familywise coverage. All recorded policies and outcomes remain unchanged. No claim is made that the counterexample estimates coverage in these data. |
| Financial results | Figure 2 separates mean burden-index reduction, mean additional options, and every complete origin's held-out CE contrast. | The failed ETF universe remains missing. All equity contrasts are zero; the sole ETF replacement is negative. Counts of candidate options are not counts of independent market observations. |
| Synthetic experiment | Figure 3 retains all four regimes, mean intervals, Wilson adoption intervals, and a clearly marked low-value detail panel. Every interval was recomputed independently from individual worlds. The Julia replay reproduced all 16,384 rows. | The powered margin is a designed dose; calibration sets noise, not economic prevalence. This learner is separate from the financial bootstrap screen and does not validate its coverage. |
| Reproduction | The package includes editable figures, deterministic data generation, evidence checks, focused mathematical checks, source hashes, and a clean archive build. | Public aggregates support record verification. Full licensed financial replication still requires independent CRSP/WRDS access. No Genealogies pilot was run or altered. |
| Editorial and PDF quality | The paper starts in plain language, then develops the model, proofs, counterexamples, algorithms, and evidence. Rendered review checks figure labels, scales, negative/missing outcomes, tables, page flow, and link destinations. | No new scientific result is inferred from improved graphics. The current package contains only the manuscript's supporting material. |
| Submission materials | Rechecked SSRN's current submission and AI-disclosure guidance. Title, author, affiliation, contact, English PDF, abstract, date, and disclosure are supplied. | Author verification of content, rights, profile, and portal declarations remains an upload-time responsibility; no submission or peer review is claimed. |

## Focused mathematical checks

`python3 verify_review.py` checks the figure inputs and the following small
fixtures. They support the review; they are not replacements for proofs.

| Check | Independent calculation | Result |
|---|---|---|
| Figure 1 | Source frontier 1 and closure `{m}`; both retained burdens 2; safe closure `{m}`, frontier-only closure empty. | Pass |
| Optional bridge value | Discount 1/2, success 1/2, cost 1/2, cap 4. Gains 0, 1, 2, 4 give losses 0, 0, 0, 1/2. | Pass; cap bound attained only at endpoint in this fixture. |
| Reflected-error counterexample | For error `E = Exp(1) - 1`, a 90th-percentile critical value from `-E` gives coverage `1 - exp(-2)/0.9 = 0.849627463...`; the upper-error critical gives 0.90. | Confirms lack of an unconditional 90% guarantee. |
| Finite-horizon boundary | Start only projects with duration no greater than remaining horizon; horizon zero has zero value. | Bellman statement now matches the encoded finite-horizon rule. |
| Within-project history | Two Markov paths merge at the current state, but admission records which earlier branch occurred. | Project identity and remaining time alone cannot generally discard observed history. |
| Unit-weight normalization | One required element, its singleton carrier of cost 1, budget 0. | Fixed no-instance remains inside the unit-weight subclass. |
| Synthetic uncertainty | All four regimes' sample SEs, mean intervals, and Wilson intervals recalculated from 4,096 individual worlds each. | Match sealed summaries to absolute tolerance `1e-14`. |

The bootstrap comparison follows the error-law orientation in Romano and Wolf,
[*Stepwise Multiple Testing as Formalized Data Snooping*](https://www.econ.uzh.ch/dam/jcr:ffffffff-935a-b0d6-ffff-ffffa286d4d1/etca.pdf) (2005), particularly the
one-sided confidence regions and bootstrap maxima in Sections 3–4. The exact
asymmetric-error example is a direct calculation supplied by this review, not a
new finding about the financial sample.

## Remaining blocker and limits

The repository-wide Julia CI run fails in
`julia/test/test_randomized_stability_amendment.jl` because the registered lock
is stale for `julia/src/StrategyInnovation.jl`. The focused current-paper theory,
algorithm, benchmark, and synthetic checks pass. That distinction does not turn
the broader gate green. The lock and study outcomes were not rewritten, the test
was not disabled, and no alternative source was silently substituted. Resolving
this source-binding failure requires a separate auditable repair of that study's
reproduction contract before claiming all repository checks pass.

The financial coverage limitation is addressed by narrowing the present claim,
not by retrospectively changing the policy. A future claim about qualified error
control would require a correct, validated inference procedure and a newly
registered evaluation. It is not necessary to invent favorable investment
results to publish the present theoretical and descriptive findings.

The review does not certify journal acceptance, replace independent peer review,
or verify unobserved licensed inputs. These limits and the open repository gate
are part of the disposition, not deferred conditions hidden behind “ready.”
