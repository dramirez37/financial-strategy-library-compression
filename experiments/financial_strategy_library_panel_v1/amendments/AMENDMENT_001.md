# Prospective Amendment 001 — threaded execution and implementation closure

**Date:** 2026-08-28

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1
**Timing:** before opening any licensed row for this study, constructing any
study instance, consuming any registered seed, or observing any study outcome.

## Reason

Implementation review after the initial design lock found that two inherited
backtest lookbacks and the exact event-counter conventions were referenced but
not stated numerically. The initial topology also reserved eight one-thread
worker processes. The author requested an eight-thread execution that is easier
to reproduce on an eight-core workstation and avoids process duplication of the
licensed panel in memory.

## Prospective changes

1. The runner is one Julia process launched with exactly eight Julia threads.
   Eight stable round-robin lanes are scheduled with `Threads.@spawn`. BLAS and
   every HiGHS model remain single-threaded, so concurrent instance jobs—not
   solver internals—supply parallelism.
2. The trend filter uses 100 sessions; the volatility target uses a 20-session
   rolling volatility; the belief signal uses the already registered 60-session
   SPY return.
3. Construction score is the registered annualized mean--variance utility of
   construction-window net daily returns. The five construction and compression
   profiles use the same utility within the fixed construction-window belief
   quintiles. A missing state minimum rejects that origin.
4. For a strategy with `T` compression-window sessions, the validation counters
   are: `S=T`; `F=0` for `always` and `F=T` for `trend_100`; `R=0` for
   `notional_cap_1` and `R=T` for `vol_target_10`; `D=ceil(T/horizon)`; and
   `X=D` for horizon exit or `X=T` for signal-flip exit. These integers enter
   the already locked burden formula without timing-based calibration.
5. Postdecision opportunity loss is calculated only after every structural
   algorithm record is terminal and audited. At each next-year belief it is the
   source frontier minus the certified retained frontier in the same
   audit-utility units. The unweighted five-belief mean and no-loss share are
   descriptive secondary quantities. They cannot alter any structural record.
6. Raw ingestion, instance building, solving, postdecision evaluation, and
   independent audit are separate resume-safe phases. A full invocation may
   sequence them, but each phase must verify its predecessor.
7. Return maps are origin-scoped. Structural maps contain only a one-year
   signal warm-up through that origin's compression endpoint. Postdecision maps
   are created in the later phase and contain only that origin's one-year
   warm-up through its postdecision endpoint. A shared map containing one
   origin's future observations is prohibited.
8. Identity-closure deletion is implemented by exact tagged carrier counts.
   Carrier counts are updated after every accepted deletion, and every endpoint
   receives a separate exact raw-frontier, raw-closure, mandatory-retention,
   and burden check. This is the same registered deletion rule with a scalable
   certificate update, not a new algorithm or estimand.

## Unchanged scientific design

The 20 origins, three source constructions, three burden schedules, seven
algorithms, registered seeds, applicability thresholds, MIP controls, exact
certification requirements, primary estimands, failure denominators, and all
information prohibitions are unchanged. The amendment changes runtime
comparability: recorded runtime is explicitly conditional on the eight-thread
topology. It does not change selected solutions for deterministic algorithms or
the registered random streams.

No pilot or final financial outcome informed this amendment. The original
design lock remains immutable and is the predecessor of the amendment and
execution locks.
