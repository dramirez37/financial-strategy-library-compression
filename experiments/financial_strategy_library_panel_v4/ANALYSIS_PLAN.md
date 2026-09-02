# V4 analysis plan

## Primary estimand

For the powered-positive regime, estimate the arithmetic mean across test
worlds of

`realized safe-oracle productive value - frontier-only productive value`.

The frontier value is zero because the project is closure-infeasible. The
registered two-sided 95% interval is the mean plus or minus 1.96 standard
errors. Success requires a strictly positive lower endpoint and inclusion of
the analytic value `M`.

## Secondary estimands

- learned-policy mean productive value and adoption rate by regime;
- oracle and learned regret relative to the analytic value;
- null false-adoption rate and Wilson interval;
- adversarial adoption rate and Wilson interval;
- paired monotonicity of proposal estimates and adoption across margin doses;
- exact equality of burden and current operating frontier in every world.

The powered-positive learned policy must have a positive lower mean interval
and at least 90% adoption. Null adoption may not exceed 6.5%; adversarial
adoption may not exceed 1%.

## Multiplicity and exclusions

Only the powered-positive oracle contrast is primary. The target descendant is
specified by its bridge lineage before simulation; no best-of-family statistic
enters the primary policy. All four regimes and all worlds remain in the
ledger. Failed structural assertions are experiment failures, not exclusions.

