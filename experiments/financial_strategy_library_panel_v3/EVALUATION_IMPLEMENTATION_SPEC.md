# V3 historical evaluation implementation specification

## Access boundary

This Julia stage remains locked until both the primary proposal-policy result
and the independently frozen proposal-robustness result are sealed with zero
historical evaluation values inspected, materialized, or used. The execution
lock binds those seals, the proposal public/local manifests, the replay lock,
this specification, and every Julia implementation and synthetic test file.
The lock also replays `PREDECISION_BINDING_AMENDMENT_003_LOCK.toml`, verifies
all 42 hashes in its sealed runtime closure, and incorporates those hashes into
the evaluation seal. This pins `StrategyInnovation.jl`, all 29 files in its
include order, the Julia environment, and the predecision computation source
actually loaded by the evaluator.

The lock authorizes one immutable evaluation program. It may score the five
already-frozen registered policy choices and all 96 already-frozen grammar
candidates. Candidate-wide scores are used only for the registered White
Reality Check, Hansen SPA, PBO/CSCV, Deflated Sharpe, and ex-post regret
diagnostics. They may never change a policy choice, universe membership,
action set, or primary headline. The headline remains innovation-safe robust
minus frontier-only robust. The failed universe cell has no historical access.

## Sealed choices and extraction mask

The public proposal interface contains all 38 cells and public-safe choice
hashes but no selected identities. The sealed local interface contains the
exact frozen identity vector for each available policy. The loader recomputes
each SHA-256 choice hash in the fixed policy order and the LF-joined aggregate
before selecting any historical field. A failed cell uses the registered
`UNAVAILABLE_UNIVERSE_GATE_FAILED` hash construction.

Because the registered search-wide diagnostics score every frozen candidate,
each gate-passed cell selects evaluation-year returns for every identifier in
its already-frozen universe, even when a policy choice is cash. Capacity
staging additionally selects `close` and `volume` for the proposal and
evaluation years so the first evaluation trade has a lagged point-in-time
liquidity window. The identifier/date scan precedes all value projection.
After row masks are frozen, separate forward-only masked cursors project:

- evaluation-year `total_return`, `return_flag`, and `delisting_flag`; and
- proposal-plus-evaluation-year `close` and `volume`.

At unmasked rows the cursor advances opaque iterator state without application
inspection, following Predecision Access Amendment 002. Source fields that are
missing or nonfinite are preserved as unavailable; they are never invented.
The staged rows are joined to the complete sealed predecision-plus-proposal
history, so portfolio state is not reset at the evaluation boundary.

## Frozen policy and candidate scoring

Every active strategy is reconstructed over the full supplied history with
the registered signal, holding-age, volatility, terminal, and two-session
implementation-lag rules. An observed terminal return is earned and the
position is cash thereafter. A terminal flag without an observed return is an
unresolved event. Any unresolved return touched by nonzero effective exposure
makes the path incomplete rather than zero-filled.

Each available choice among the five registered frozen policies is scored at
5 basis points one-way cost and risk aversion 3. A plural equal-weight policy averages sleeve gross
returns and sleeve effective weights first; policy turnover is then computed
from changes in that aggregate effective portfolio. For gross return `r_t`,
one-way turnover `q_t`, and `n_t = r_t - 0.0005 q_t`, the components are:

- annual mean `252 mean(r_t)`;
- annual cost `252 mean(0.0005 q_t)`;
- annual variance penalty `0.5 * 3 * 252 var(n_t)`; and
- certainty equivalent equal to mean minus cost minus penalty.

The same 5-basis-point/risk-3 rule scores all 96 frozen candidates solely for
diagnostics. Seed derivation is SHA-256 of the decimal base seed, origin ID, and
universe ID joined by NUL, with the first 15 hexadecimal digits parsed as an
integer. The exact registered namespaces are White Reality Check 310003,
Hansen SPA 310004, and PBO/CSCV 310005, each with scope
`origin_id|universe_id`. Seed 310006 remains reserved for the proposal-stage
permuted-closure sham and is never used by evaluation.

White Reality Check uses 5,000 circular moving-block bootstrap repetitions and
20-session blocks after centering every candidate at its sample mean. For both
RC and SPA, the performance differential is the candidate's daily return net
of the registered 5-basis-point one-way turnover cost minus the zero daily
return of the cash benchmark; CE is not the resampled RC/SPA differential.
Hansen SPA uses a separate 310004 bootstrap stream, the same circular 20-session
blocks, and candidate-specific Bartlett/Newey-West long-run variance with
bandwidth 19. Its observed and bootstrap statistics include the zero benchmark:
`max(0, max_k sqrt(n) mean_k / omega_k)`. The consistent Hansen recentering is
`mean_k` only when `sqrt(n) mean_k / omega_k < -sqrt(2 log log n)` and zero
otherwise; zero-long-run-variance negative candidates retain their negative
mean and nonnegative candidates recenter at zero. This prevents clearly poor
alternatives from inflating the SPA null while retaining near-null candidates.

PBO uses eight chronological CSCV blocks and all 70 four-block training splits,
ranking candidates by the registered cost-net risk-3 CE. Ex-post regret also
uses that CE scale.
It is exhaustive rather than randomized, but records the registered 310005
scope seed as provenance. Deflated Sharpe is also reported as a secondary
diagnostic: compute each complete candidate's daily net Sharpe, use the
cross-candidate sample variance and the Bailey--López de Prado expected-maximum
normal-order-statistic approximation over all nonzero-variance candidates,
then evaluate the best observed Sharpe with its sample skewness and raw
kurtosis adjustment. The output is the resulting standard-normal probability,
expected-maximum daily Sharpe threshold, and a public-safe hash of the
max-Sharpe identity. It assumes the enumerated trial count in the expected-max
step; dependence across time is addressed by the separate RC/SPA diagnostics.
Ex-post regret is the complete candidate's best realized CE minus each
immutable policy CE. No diagnostic output is fed back into selection.

## Frozen proposal-robustness sensitivity

The evaluator consumes both the public and local manifests sealed by
`PROPOSAL_ROBUSTNESS_RESULT_SEAL.toml` and byte-checks all 38 sealed local
artifacts before access. The registered sensitivity grid contains 24 specs per
cell: one-way cost in 0, 5, 15, or 30 basis points, risk aversion in 1 or 3,
and proposal-selection hurdle in 0, 0.0025, or 0.005. Thus all 38 cells retain
912 spec slots and two frozen policy-choice slots per spec, or 1,824 choice
rows. The gate-failed cell and any individually unavailable choice remain in
those denominators with their sealed failure codes; no unavailable choice is
constructed or evaluated.

The hurdle is a proposal-stage choice-freeze parameter only. Evaluation scores
the identity frozen under that hurdle at the spec's own cost and risk; it does
not reapply the hurdle or select a new identity. Both frozen comparator and
safe identities are evaluated, including exact-identity cases, whose
safe-minus-comparator contrast must be exactly zero. The public result reports
identity-free cell and origin rows, completeness/failure counts, and
mean/CE/variance/cost contrasts by registered spec. It never feeds a
sensitivity result back to any primary or robustness policy choice.

The common-equity liquidity-cap sensitivity is reconstructed from the sealed
preproposal rank in `UNIVERSE_SELECTIONS.toml`. Cap 50 uses ranks 1--50 and an
independently namespaced strategy-path cache, so ranks 51--100 cannot affect
its weights, returns, or cached paths. Cap 100 uses the full frozen top-100
panel. Both score the cap-specific frozen comparator and safe choice at their
sealed cost/risk settings with no reselection. Cap 200 and the permuted-closure
sham remain explicitly unavailable as registered; ETF cells retain their
registered not-applicable dispositions. All public choice hashes are the
already-sealed contextual hashes, never hashes of raw identity vectors.

Leave-one-origin-out influence is aggregation-only. For the primary common-
equity contrast, the evaluator emits exactly 19 deterministic omissions, one
for every registered origin, and recomputes the failure-aware complete-origin
count, arithmetic mean, and registered robust center after each omission. No
leave-one-out value is used for selection, scoring, or policy repair.

## Capacity appendix

Capacity scores only the frozen policy aggregate weight paths. It never scores
or selects a replacement. The grid is fixed before evaluation access:

- AUM: USD 1 million, 10 million, 100 million, and 1 billion;
- half-spread: 2.5, 7.5, and 15 basis points;
- square-root impact coefficient: 0.5 and 1.0; and
- hard participation cap: 10% of lagged average daily dollar volume.

For an order executed on session `t`, lagged ADV is the arithmetic mean of
`close * volume` over exactly sessions `t-20` through `t-1`; lagged volatility
is the corrected daily return standard deviation over the same window. The
impact rate per traded dollar is
`coefficient * lagged_daily_volatility * sqrt(order_dollars / lagged_ADV)`.
Spread and impact dollars are divided by AUM and subtracted from gross return.
An order above 10% ADV is unavailable and is not truncated. A nonzero order
with an incomplete lag window, invalid price/volume, zero ADV, or unresolved
lagged return is explicitly `CAPACITY_SOURCE_FIELDS_UNAVAILABLE`. Cash or a
zero-order session needs no liquidity inputs.

Capacity CE uses annual gross mean minus annual execution cost minus the
risk-3 variance penalty of the capacity-net daily return. Public outputs give
policy IDs, grid coordinates, completeness, failure codes, aggregate metrics,
and origin-level summaries without licensed identifiers or frozen identities.
Capacity is deterministic and consumes no random draws, but each AUM surface
records the registered 310007 provenance seed derived over the exact scope
`origin_id|universe_id|aum_id`, where `aum_id` is `aum_` followed by the integer
USD amount.

## Ledger and public boundary

Every one of the 485 rows in each cell ledger remains in its original order;
the experiment denominator stays 18,430. Evaluation fields are filled for
selected policy rows and, where generatable, for the 96 candidate rows used by
the registered search-wide diagnostics. Structurally inapplicable and failed
rows retain explicit blank/failure semantics. No row or trial identifier is
added, removed, or repurposed, and every row receives a new canonical hash.

Raw returns, price/volume values, licensed identifiers, frozen identities, and
trial ledgers remain in ignored local artifacts. Public manifests contain only
policy IDs, choice hashes, counts, economic components, search diagnostics,
capacity grid results, registered summaries, and artifact hashes. The common
equity primary contrast is inconclusive unless at least 15 of 19 origins are
complete; ETF results remain a separate 19-origin replication.
Every cell exposes all five registered primary-policy records, including an
explicit evaluation-unavailable record when its sealed proposal choice was
unavailable. The public primary-policy denominator is therefore 38 times 5,
or 190, without constructing missing paths.

## Required checks

Before the execution lock may be written, synthetic tests must establish full
state continuation, immutable-choice scoring, observed-delisting and unresolved
availability semantics, all-96 deterministic diagnostics, unchanged ledger
denominators, masked return and capacity-field isolation, security-contiguous
panel reconstruction, capacity point-in-time lags, hard ADV-cap failure,
explicit missing-source failure, the 24-spec own-cost/risk robustness grid,
hurdle-as-freeze-only behavior, exact-identity zero contrasts, cap-50 rank
exclusion with an isolated cache, all 912/1,824 public rows including failed
dispositions, all 190 primary-policy rows including unavailable policies, 19
failure-aware leave-one-origin-out omissions, sealed contextual choice hashes,
and the complete 42-file runtime-source closure. Historical access begins only after this
implementation is independently audited and the parent task gives an explicit
go. After execution, replay must rehash the lock, both upstream result seals,
stage manifests, 38 ledgers, public result, and local manifest before the final
evaluation result seal is eligible.
