# Financial Strategy Library Panel v3 — Proposal Execution Specification

## Access boundary

Proposal execution may begin only after `PREDECISION_COMPUTATION_RESULT_SEAL.toml`
and the proposal execution lock both replay exactly. The extractor first freezes an
identifier/date row mask and then uses the masked-column mechanics authorized by
Predecision Access Amendment 002. Unmasked projected values advance opaque iterator
state only; application code does not inspect, convert, validate, branch on, log,
hash, or copy them.

Only rows in a registered proposal year may be materialized. Evaluation-year values
remain unopened. The failed 2005 ETF cell remains in all denominators and ledgers but
its identifiers are omitted from proposal masks and no proposal return is staged for
it.

## Continuous histories and proposal calendar

For each gate-passed cell, the stage contains every frozen security identifier, its
complete sealed predecision history, and every session of the proposal-year reference
calendar. Histories are security-contiguous, with predecision and proposal dates in
ascending order, so the registered signals, filters, positions, exits, turnover, and
volatility state continue without reinitialization at the proposal boundary.

An ordinary source row has `return_flag = "NA"` and a finite total return no smaller
than -1. Other flags remain explicit missing observations. A non-`N` delisting flag is
terminal. No observed return may follow a terminal delisting; later reference-calendar
rows are explicit unavailable post-terminal cash states. A missing observation before
terminal remains unavailable and is not imputed.

## Frozen action paths

All 96 registered portfolio specifications are recomputed on the combined history.
Only predecision-frozen action sets are eligible:

- `frontier_only_robust_policy`: comparator-generatable innovation paths plus cash;
- `innovation_safe_robust_policy`: safe-generatable innovation paths, defaulting to
  the exact comparator policy choice;
- `innovation_safe_forced_max`: safe-generatable innovation paths, cash omitted;
- `equal_weight_available_policy`: safe-generatable innovation paths plus cash; and
- `source_uncompressed_robust_policy`: source-generatable innovation paths plus cash.

Net path returns use the registered 5-basis-point one-way cost and the primary annual
certainty equivalent uses 252 sessions and risk aversion 3. A path is complete only
when every proposal-calendar session is available and finite. Incomplete paths remain
in the trial ledger but are ineligible.

## Paired simultaneous inference

Each robust family uses 5,000 paired circular moving-block bootstrap repetitions with
20-session blocks and a stable registered seed scoped by origin, universe, and policy.
Every candidate and its baseline use the same resampled session indices. For candidate
`i`, let `delta_i` be its annual certainty-equivalent difference and `se_i` the sample
standard deviation of its bootstrap differences. Each repetition contributes
`(delta_i - delta_i*) / se_i` when `se_i` is positive and zero otherwise. The 90th
empirical percentile of the within-repetition maximum across the complete candidate
family is the one-sided max-t critical value. The simultaneous lower bound is
`delta_i - critical * se_i`.

The comparator is itself selected on proposal data. The safe-policy critical value
therefore ranges over every complete safe-candidate by complete comparator-candidate
contrast, including cash, in the same paired bootstrap. After the comparator cash gate
selects its baseline, the safe policy uses the corresponding pairwise lower bounds.
This simultaneous family protects the no-harm decision against the data-dependent
choice of comparator; it does not condition the max-t reference distribution on a
fixed comparator chosen from the same sample.

For family shrinkage, the center is the mean candidate delta, the latent between-path
variance is the nonnegative part of the sample between-path variance minus the median
`se_i^2`, and candidate reliability is `latent / (latent + se_i^2 + eps())`. The
shrunk delta is the family center plus reliability times the candidate deviation from
that center. Shrinkage ranks candidates only after the simultaneous adoption gate; it
does not replace or relax the max-t lower bound.

## Frozen policy choices

The annual adoption hurdle is 0.0025.

- The frontier-only and source-uncompressed robust policies choose cash unless at
  least one candidate has a simultaneous lower bound above the hurdle. Among eligible
  candidates, the greatest shrunk delta wins, with strategy identifier as the exact
  tie-break.
- The innovation-safe robust policy defaults to the exact comparator policy choice.
  It adopts an alternative only when that alternative's paired incremental lower
  bound over the comparator exceeds the hurdle. The same shrunk-delta and identifier
  tie-break applies. This is the registered no-harm gate.
- The forced-max negative control selects the complete safe candidate with greatest
  raw proposal certainty equivalent, with identifier tie-break, and has no cash arm.
- The equal-weight policy selects every complete safe candidate with positive raw
  certainty equivalent; it selects cash if none are positive.

## Trial ledger and seal

Every one of the 485 preproposal trials per registered cell remains present. Proposal
observation counts, family-shrunk proposal certainty equivalents, simultaneous lower
bounds, eligibility, selection, and registered failure codes are filled without
altering trial identifiers or capability hashes. Evaluation fields remain blank and
their observation counts remain zero. After all choices are frozen, a proposal seal
binds the execution lock, proposal-stage manifests, every licensed local artifact,
every policy choice, and all 18,430 proposal-ledger rows. Evaluation access remains
forbidden until that seal replays.
