# Economic-design falsification audit for the sealed v2 panel

## Status and purpose

This is a post-outcome diagnostic audit of the sealed
`financial-strategy-library-panel-v2` experiment. It does not amend, replace,
or re-estimate the registered v2 primary result. Its purpose is to determine
whether the observed origin instability is plausibly induced by the economic
decision design rather than merely by a small historical sample.

The audit was specified after the v2 outcomes and exploratory aggregate
diagnostics were visible. Every result is therefore descriptive and may be
used to design v3, but not to promote a new confirmatory v2 claim.

## Controlling source and grain

The controlling records are the 40 sealed predecision docket files and their
40 hash-bound postdecision docket files. The registered grain is one
origin--docket--menu pair:

- 20 annual origins;
- two source dockets per origin;
- 32 menus per origin--docket cell; and
- 1,280 registered primary pairs in total.

The audit first verifies the file join, predecision hashes, arm identities,
menu identifiers, frozen-choice identifiers, postdecision arithmetic, and the
promoted 1,277-of-1,280 completeness count.

## Diagnostic hypotheses

### H1: unequal opportunity-set optimization

The innovation-safe arm preserves the complete declared closure, while the
comparator carries only a subset. If the safe arm always selects the top noisy
predecision estimate and the comparator frequently selects a lower rank or
cash, the experiment combines closure preservation with unequal optimizer's-
curse exposure.

### H2: weak decision-score calibration

For complete changed choices, compare the safe-minus-comparator predecision
score gap with the held-out utility difference. Report pooled and within-cell
Pearson correlations. This is a calibration diagnostic, not an inferential
test; range restriction among selected choices is an explicit limitation.

### H3: security-identity confounding

For changed active--active choices, determine whether the two arms select the
same point-in-time security. Report only disclosure-safe counts. If most pairs
also change security identity, the economic contrast does not isolate the
strategy-capability difference.

### H4: misspecified outside option

The registered inactive-cash candidate has utility zero but the frozen choice
rule uses it only when no active candidate is generatable. Recompute two
descriptive policies from the already frozen candidate outcomes:

1. `cash_floor`: each arm chooses its frozen active candidate only when that
   candidate's predecision utility is positive; otherwise it chooses cash.
2. `nested_no_harm(h)`: the safe policy defaults to the cash-floored comparator
   and adopts its closure-enabled candidate only when its predecision advantage
   over the comparator/cash outside option exceeds threshold `h`.

The registered result remains the only v2 primary result. These policies test
whether instability depends on forcing estimated-negative active choices or
on exercising small estimated advantages.

### H5: mixed-instrument outcome heterogeneity

Stratify changed pairs by the safe and comparator instrument classes
(`common_equity`, `plain_etf`, or `cash`). Report counts, means, and medians.
The audit never publishes security identifiers.

## Direction gate for v3

The Julia audit recommends the economic v3 direction when at least three of
the following four diagnostic conditions hold:

1. the comparator selects a lower rank or cash in more than 50% of registered
   menus while the safe arm selects rank one in every menu;
2. the absolute correlation between the predecision advantage and held-out
   advantage is below 0.10 among changed active--active choices;
3. more than 90% of changed active--active choices change security identity;
4. adding the cash outside option changes the absolute origin-level mean by
   more than 25%, or reduces the 2007 signed-sum contribution by more than 25
   percentage points.

These thresholds are diagnostic decision rules declared before the formal
Julia audit was run, but after exploratory inspection. Passing the gate means
the proposed economic redesign is sufficiently supported to specify v3. It
does not mean that any v3 financial effect has been established.

## Outputs

The audit writes only aggregate, redistributable artifacts under `results/`:

- `AUDIT_SUMMARY.toml`;
- `AUDIT_REPORT.md`;
- `selection_rank_distribution.csv`;
- `origin_policy_diagnostics.csv`;
- `threshold_policy_diagnostics.csv`; and
- `instrument_class_diagnostics.csv`.

All outputs are deterministic and replayable with the Julia audit's `--check`
mode.
