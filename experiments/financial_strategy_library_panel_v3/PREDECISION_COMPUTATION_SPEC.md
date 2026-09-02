# V3 predecision computation and preproposal-seal specification

This stage is implemented in Julia and may run only after the base design,
Implementation Amendment 001, Predecision Access Amendment 002, final
outcome-safe Extractor Lock 003, and bounded predecision stage all verify
transitively. It consumes no return dated after a cell's compression decision.
Proposal- and evaluation-year return values remain closed.

## Ordered computation

For every registered origin-universe cell, including a cell whose universe
gate failed, the stage computes the 96 frozen portfolio grammar paths on its
staged formation and compression calendar. A failed universe cell remains
marked failed in every trial-ledger row and is never removed or backfilled.

The following ordering is binding:

1. compute complete portfolio paths under Amendment 001;
2. compute the 12 formation profiles only;
3. freeze the source docket from formation frontier carriers and the three
   registered formation-ranked carriers per capability;
4. compute the 12 compression profiles;
5. construct and independently validate the original exact tagged-cover
   instance;
6. solve the innovation-safe and frontier-only exact MIPs with their frozen
   seeds, then augment the frontier endpoint in frozen compression-score order
   without exceeding the safe burden;
7. enumerate exact requirement-inclusion action sets and verify
   `comparator subset safe subset source`; and
8. write the complete preproposal ledger before any proposal return is read.

Cash is mandatory in every compression instance at zero profile and zero
burden. It is added to every registered policy action set except the explicitly
cash-omitting forced-maximum negative control.

## Exact profile grid

Calendar-year certainty equivalents use 252-session annualization, sample
variance, costs of 5 and 30 basis points, and risk aversion 1 and 3. Each finite
floating profile is deterministically rounded to the nearest `10^-12` and then
represented as an arbitrary-precision rational. Frontier equality, carrier
ties, MIP coefficients, burden matching, and compression ranks use only these
exact rational values. Strategy identifier breaks every remaining rank tie.

The exact grid is numerical-comparison discipline for the historical financial
block; it is not a claim that measured returns are mathematically exact.

## Exact-arm evidence

Both primary endpoints use the repository's canonical
`StrategyInnovation.solve_journal_compression_mip` implementation with one
HiGHS thread, zero MIP gaps, stable registered seeds, complete captured logs,
and independent exact checks against the original unpreprocessed instance. An
endpoint solved entirely by exact fixed-point preprocessing is accepted without
invoking HiGHS. Solver optimality is computational evidence, not a formal proof.

The budget-matched comparator starts at the exact frontier-only endpoint and
adds whole source strategies in descending mean compression CE, then identifier
order, whenever the addition fits under the realized safe exact burden cap.

## Complete preproposal ledger

Every cell receives 485 frozen rows: 96 grammar strategies plus mandatory cash,
crossed with all five registered policies. Source-docket strategies remain as
explicit `SOURCE_DOCKET_MEMBER_EXCLUDED_FROM_INNOVATION_POOL` rows. Missing
capabilities, the forced-policy cash omission, and universe-gate failures have
explicit codes. Proposal and evaluation counts are zero; their value fields
are empty. No row can be added or removed after this seal.

## Artifact boundary

Licensed return paths, exact profiles, complete MIP certificates, endpoint
identities, action-set identities, and trial ledgers remain under ignored
`local_data/predecision_computation`. The public manifest contains no return,
security identifier, profile value, or strategy identity selected from returns.
It reports only registered counts, exact burdens, nesting checks, solver status,
artifact hashes, and failure denominators.

The ex-ante `PREDECISION_COMPUTATION_LOCK.toml` binds every prerequisite lock,
including the immutable extractor history and access-mechanics amendment, the
stage manifests and Parquet hashes, this specification, Julia sources, runner,
and tests before computation. The result manifests then hash-freeze all local
outputs. Neither artifact authorizes proposal or evaluation access by itself;
a later proposal extractor and policy-freeze seal remain required.
