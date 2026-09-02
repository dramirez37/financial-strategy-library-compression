# V3 Predecision Access Amendment 002: masked projected-column mechanics

## Timing and history

This execution amendment follows two authorized but interrupted predecision
staging attempts. Extractor lock 001 authorized the first attempt; it
materialized selected predecision rows from eight source chunks before the
process was interrupted for impractical allocation cost. Extractor lock 002
authorized a performance-only rewrite; its exact-range cursor construction was
also interrupted before a chunk completed. Neither attempt wrote a local stage
artifact. No proposal- or evaluation-window value was inspected, materialized,
or used.

This history means the amendment is not outcome-blind. It changes access
mechanics only and does not change an origin, universe, selected permanent
identifier, date boundary, portfolio rule, arm, policy, outcome, or claim.

## Frozen access mechanics

For every sealed source chunk, the extractor must complete an identifier/date-
only pass and freeze the sorted source-row indices belonging to at least one
registered origin-by-universe predecision cell. Only then may it construct a
projected cursor for a return-related field.

Each of `total_return`, `return_flag`, and `delisting_flag` receives one forward
`Parquet.ColCursor` pass. At a frozen selected row, application code may read
and materialize `.value`. At every unmasked row, application code may advance
only opaque iterator state. It may not inspect `.value`, convert it, validate
it, branch on it, log it, hash it, aggregate it, copy it, or assign it to a
cell. Proposal and evaluation values therefore cannot affect application
output or control flow.

Parquet codecs physically decompress encoded pages. Such physical page
decompression is disclosed and is not described as zero physical decoding.
The experimental access claims concern row-level inspection, materialization,
and use by application code.

## Required validation

Extractor lock 003 must seal the implementation and an adversarial synthetic
sentinel. The sentinel must vary nonfinite returns and invalid flags only on
unmasked postdecision rows and establish identical selected outputs with zero
postdecision inspection, materialization, and use. Lock 003 must bind immutable
extractor locks 001 and 002 plus this amendment lock before further historical
staging.
