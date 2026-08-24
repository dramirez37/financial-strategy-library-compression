# Annual Walk-Forward Financial-Audit Amendments

## A-001 — Sparse target-state feasibility

- Initial design lock: `2af8b413e2b37eea94cb9a5ded6b48d6ca268be7d92fcaf0823be9830be994bc`
- Initial execution disposition: failed before producing a ranking or mechanism result.
- Failure: at least one annual five-state target profile had fewer than the
  configured 25 observations, so the generic profile-support gate aborted.
- Outcome information observed: only the support failure and its stack trace;
  no candidate score, target, rank, selection, comparison, or verdict was
  printed or written.
- Amendment: retain the 25-observation requirement for development,
  validation, and each five-year trailing score profile. For a one-year target,
  require one observation in every visited state and assign zero to an
  unvisited state only when its realized discounted occupation is exactly
  zero. The target remains the same risk-adjusted state-profile gap integrated
  against realized occupation.
- Unchanged: universe, candidates, grammar, periods, belief thresholds,
  transition estimator, horizon, discount, survival, costs, top-k, marginal
  selection rule, comparators, bootstrap, target definition, and the rule that
  empirical support is not a hard gate.

The amended design must receive a new lock before rerunning the outcome stage.

## A-002 — Report-only Julia API correction

- Amended analytical lock: `af7708f0b60c1c964412e79ee6317810676fada83618879435814d03e8b6c2de`
- Execution disposition: all five annual decision hashes and analytical gates
  completed, but artifact writing stopped before the report was produced.
- Failure: Julia 1.12 does not support the attempted
  `maximum(comparators; by=...)` report helper.
- Amendment: replace that report-only expression with an explicit deterministic
  sort and take its first row.
- Outcome information used: the stack trace only. Partial result tables were
  not inspected before this amendment.
- Unchanged: every universe, backtest, score, target, ranking, selection,
  comparison, uncertainty, decomposition, identity, and verdict calculation.

This is an implementation amendment after analytical computation, not a new
empirical specification. The initial and amended analytical locks remain
separate, immutable audit artifacts.

## A-003 — Lock-chronology wording correction

- Completed implementation lock: `11fea985cf3b64faa37b01aa8ac128f199b0dbe4f7d63c95123f3ddd94edccb7`.
- Execution disposition: the aggregate run completed, but the generated prose
  incorrectly described the completed implementation hash itself as having
  been frozen before return extraction.
- Amendment: distinguish the initial pre-outcome analytical lock from the
  support-only A-001 amendment, the report-only A-002 correction, and this
  audit-wording correction. The completed lock now truthfully attests that
  support information existed before it was written.
- Outcome information used: only the lock chronology and implementation
  history. No score, target, rank, selection, comparison, uncertainty result,
  or verdict was used to make this change.
- Unchanged: every universe, backtest, score, target, ranking, selection,
  comparison, uncertainty, decomposition, identity, and verdict calculation.

This amendment improves the audit language only. The numerical artifacts must
be regenerated and checked against the completed implementation.

## A-004 — Generated TeX row terminators

- Completed audit-wording lock: `12b89f6573c3dc7e38bb5d2e3dc1be17797f5a4427f7eb715092aa2a569f8fdc`.
- Execution disposition: all analytical and aggregate artifacts completed, but
  the manuscript build gate rejected three generated table rows because each
  ended in one TeX backslash rather than the required two.
- Amendment: emit two TeX backslashes for those three row terminators and
  update amendment-count wording in generated reports.
- Outcome information used: the LaTeX error and lock chronology only. No score,
  target, rank, selection, comparison, uncertainty result, or verdict was used.
- Unchanged: every universe, backtest, score, target, ranking, selection,
  comparison, uncertainty, decomposition, identity, and verdict calculation.

This is a report-only amendment forced by the publication build gate.

## A-005 — Manuscript page balance

- Completed TeX-fix lock: `14936e043517a3513914341af50b639041edb8a578fea8fa25c1bb747323279b`.
- Execution disposition: the manuscript compiled and the annual-audit table was legible,
  but rendered PDF inspection found that the four-line claim-boundary paragraph
  was orphaned on an otherwise empty ninth page.
- Amendment: shorten only the generated section overview by removing details
  already present in its table and the full draft; retain the universe,
  walk-forward decision hashing, marginal-coverage rule, amendment disclosure,
  adverse terminal-audit result, every table value, and the complete boundary paragraph.
- Outcome information used: PDF pagination only. No score, target, rank,
  selection, comparison, uncertainty result, or verdict was used.
- Unchanged: every universe, backtest, score, target, ranking, selection,
  comparison, uncertainty, decomposition, identity, and verdict calculation.

This is a layout-only amendment forced by rendered-PDF quality assurance.

## A-006 — Deliberate empirical-results page

- Completed page-balance lock: `337b7472061af950838ad4a473384bf7baeb8db07b1927b4a2b2fdd2fa4517ac`.
- Execution disposition: the overview and table fit on page eight, but the
  boundary paragraph crowded the page number.
- Amendment: begin a deliberate second empirical page after the table and add
  concise walk-forward, compression/decomposition, and claim-boundary
  paragraphs. Every number was already present in generated aggregate tables
  and the full results draft; no new statistic, comparison, or interpretation
  rule was introduced.
- Outcome information used: PDF pagination and already registered summary
  rows. No score, target, rank, selection, comparison, uncertainty calculation,
  or verdict was changed.
- Unchanged: every universe, backtest, score, target, ranking, selection,
  comparison, uncertainty, decomposition, identity, and verdict calculation.

This is a report-only manuscript composition amendment.

## A-007 — Report-writer uncertainty scope

- Completed empirical-page lock: `46cc2563834f911c8ff4bb442c513a83b8e76123eb0a7051bbd38867c6857d2a`.
- Execution disposition: all five analytical decisions completed, but the
  manuscript writer stopped because the primary uncertainty row was local to
  the draft-writer closure and unavailable to the manuscript-writer closure.
- Amendment: bind the same already-computed uncertainty row once in the parent
  report function and reuse it in both writers.
- Outcome information used: the `UndefVarError` stack trace only. No generated
  score, target, rank, selection, comparison, uncertainty value, or verdict was
  inspected before this correction.
- Unchanged: every universe, backtest, score, target, ranking, selection,
  comparison, uncertainty, decomposition, identity, and verdict calculation.

This is a report-only Julia scoping correction.
