# Financial Innovation-Challenge Panel v2 — analysis plan

## Evidence order

No outcome summary is read until the design lock verifies, every predecision
artifact is terminal, all menu selections are frozen, and the postdecision
information-firewall audit passes. Analysis proceeds in this order:

1. origin and security eligibility census;
2. source-docket structure and capability-carrier audit;
3. arm feasibility, exact certificates, burden, and preprocessing;
4. challenge-menu generation and predecision selection audit;
5. postdecision completeness and registered availability gates;
6. primary paired contrast;
7. secondary mechanism and algorithm contrasts; and
8. computational stress-block timing.

## Primary estimand

For menu \(m\), docket \(d\), and origin \(o\), let
\(Y^{S}_{odm}\) be the frozen safe arm's next-year candidate score and
\(Y^{F}_{odm}\) the budget-matched frontier-only score. Define

\[
 D_{odm}=Y^{S}_{odm}-Y^{F}_{odm}.
\]

The origin--docket estimate is the arithmetic mean of complete paired menu
contrasts. It is available only with at least 24 of 32 complete menu pairs. The
study reports both dockets separately, then a cross-docket summary that first
averages the two available docket estimates within origin. The finite-panel
headline is the mean and median across registered origins, with IQR, full
range, sign count, denominator, and a 10,000-replicate percentile interval from
resampling whole origins. The interval is descriptive sensitivity, not a
population or causal confidence statement.

Positive values favor innovation-safe compression. Zero and negative values
remain fully reportable. No alternative outcome, window, menu subset, or
regression may replace this estimand.

## Availability gate

The held-out flagship analysis requires:

- at least 15 structurally evaluable origins;
- at least 24 complete paired menus for an origin--docket estimate; and
- at least 75% of structurally evaluable origins passing the menu rule.

Failure makes the primary conclusion `INCONCLUSIVE_BY_REGISTERED_AVAILABILITY_GATE`.
The analysis must still report every missingness reason and every structural
result. It may not pool belief cells, impute an unobserved delisting return,
switch candidates after outcomes, lower the menu count, or extend the window.

## Secondary estimands

Report, in registered order:

1. top-ranked menu-candidate availability by arm;
2. exact burden premium of safe over frontier-only compression;
3. source-to-safe burden reduction under each burden schedule;
4. postdecision operating-frontier loss of each arm;
5. greedy and 64-start burden gaps to the safe exact reference;
6. selected-library and selected-innovation identity stability; and
7. steady-state computational stress-block time.

Each metric keeps its natural denominator and unit. Missingness cannot be
recoded as zero. Displayed secondary p-values, if any, use Holm familywise
adjustment; estimates, paired denominators, and intervals remain the primary
evidence.

## Burden and comparator checks

For every origin--docket--schedule cell, independently verify:

- both primary arms preserve the source's 30-row frontier exactly;
- the safe arm preserves all 27 capability identifiers exactly;
- the budget-matched comparator burden does not exceed the safe burden, and
  its unused indivisible slack is reported;
- all additions to the comparator follow the locked predecision ranking;
- no challenge menu or postdecision field enters arm construction; and
- all exact rational burdens reconcile to the serialized arm record.

Report the fraction of comparator cells that accidentally recover full closure.
Those cells remain in the primary analysis and are interpreted as zero
treatment separation for the availability mechanism, not deleted.

## Challenge checks

For every origin and docket, verify that the 32 menus contain eight distinct
non-source candidates, match the registered seed and strata, and were hashed
before arm construction. For every arm--menu selection, recompute capability
availability and the stable predecision rank. The source and safe arms must
select the same candidate; disagreement is a hard implementation failure.

## Computational stress block

The stress block is conditional on the registered nontriviality criteria and is
not used to estimate how often financial libraries are hard. Report admitted
and rejected cells with reasons. Timing begins after algorithm-specific warm-up
and excludes compilation. Five repetitions report the median and full range of
search time; preprocessing, reconstruction, and exact certification are shown
separately. Feasibility construction, quality-qualified attainment, and exact
completion are never pooled into one performance profile.

## Failure retention

Every origin, docket, schedule, arm, menu, and algorithm has a terminal row.
Retain universe failures, insufficient menu pairs, candidate-return failures,
timeouts, infeasible arms, missing incumbents, certificate failures, and method
inapplicability in registered denominators. No row is removed because its
result is null, negative, trivial, slow, or unfavorable to the mechanism.

## Prespecified tables and figures

Tables:

1. v1 failure diagnosis and v2 design response;
2. origin eligibility and profile-support census;
3. docket size, 30-row frontier, and carrier multiplicity;
4. exact arm burden and safe burden premium;
5. challenge availability and completeness gate;
6. primary origin-level paired contrast;
7. heuristic burden gap and exact agreement; and
8. stress-block timing and completion targets.

Figures:

1. origin-level paired innovation-utility contrast with every origin shown;
2. burden versus held-out score by arm, connected within origin;
3. menu-candidate availability by arm and docket;
4. safe burden premium over frontier-only compression; and
5. separate stress-block feasibility, quality, and exact-completion profiles.

All axes include every finite observation. Any transformation must be fixed in
the design or labeled exploratory.
