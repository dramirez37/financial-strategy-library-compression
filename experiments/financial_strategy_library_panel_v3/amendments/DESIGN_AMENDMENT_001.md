# V3 Design Amendment 001: executable predecision mechanics

## Timing

This amendment was written after the base v3 design and point-in-time universe
census were locked and before any v3 predecision return value was extracted.
Proposal and evaluation return values remain unopened.

An independent pre-access implementation review identified missing executable
definitions for the registered volatility target, terminal returns, and the
extractor boundary. Those blockers were corrected before this amendment was
sealed and before any historical return value was decoded.

## Reason

Implementation review found that the base protocol fixed the grammar, timing,
candidate unit, universes, policies, and estimands but did not fully define the
security position state machine, partial-gross cash rule, 12 operating
profiles, or additive burden schedule. Leaving those choices to code would
create researcher degrees of freedom.

## Action

`PREDECISION_IMPLEMENTATION_SPEC.md` and `BURDEN_REGISTRY.csv` freeze those
mechanics. A separate Julia module and tests implement them. The amendment does
not change the 96-candidate grammar, exact arms, source census, outcome,
uncertainty rule, claim boundary, or historical-development label.

## Boundary

The base design lock remains immutable. This amendment is valid only when its
lock verifies every base-sealed file and aggregate, the base-lock hash, and
every amendment implementation hash. It does not itself authorize historical
return access; a separate outcome-safe extractor seal must do so.

Machine-readable authority is layered. The base design lock establishes only
eligibility. It cannot authorize access by itself: the current amendment lock
and a date-aware extractor lock must both verify before effective historical
predecision access becomes true.
