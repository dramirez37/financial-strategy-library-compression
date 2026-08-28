# Predecision burden calibration

Every active strategy receives a positive integer weight; the mandatory
inactive strategy has weight zero. Weights are frozen before any postdecision
return is opened. Missing inputs reject the instance—there is no imputation,
fallback schedule, or outcome-dependent rescaling.

## Validation work units — primary

Interpretation: exact blocks of strategy-specific validation operations in the
two-year compression window.

For strategy \(s\), let \(T_s\) be its valid compression-window sessions,
\(S_s\) the number of signal evaluations, \(F_s\) the number of nontrivial
filter evaluations, \(R_s\) the number of rolling-risk updates, \(D_s\) the
number of scheduled position decisions, and \(X_s\) the number of exit-rule
evaluations. The registered weight is

\[
 w_s^{\mathrm{val}}
 =1+\left\lceil S_s/252\right\rceil
   +\left\lceil F_s/252\right\rceil
   +\left\lceil R_s/252\right\rceil
   +\left\lceil D_s/52\right\rceil
   +\left\lceil X_s/252\right\rceil .
\]

The counts come from a dry operation-counter pass over predecision dates, not
wall-clock timing. `always` contributes \(F_s=0\), `notional_cap_1` contributes
\(R_s=0\), horizon exit contributes \(X_s=D_s\), and signal-flip exit contributes
\(X_s=T_s\). Scheduled decisions use the declared holding horizon. Units are
validation-operation blocks, not seconds or compute charges.

## Equal active-strategy units — robustness

\(w_s^{\mathrm{equal}}=1\) for every active strategy. The unit is one active-
maintenance slot. Exact ties use the algorithm's registered stable ordering;
the study does not claim to enumerate every optimizer identity.

## Governance review units — robustness

Every canonical strategy specification references six atomic and three
interface capabilities and produces one evidence specification. Let \(d_s\) be
the number of its six grammar fields that differ from the registered baseline
`momentum_20/always/5/unit/horizon/notional_cap_1`. Then

\[
 w_s^{\mathrm{gov}}=1+9+1+d_s=11+d_s,
\]

with exact range 11 through 17. The unit is one registered checklist row. It is
a governance-complexity index, not observed labor, money, approval difficulty,
or model risk.

## Permitted and prohibited inputs

Permitted inputs are origin-valid strategy specifications, predecision session
counts, declared grammar values, canonical specification hashes, and registered
capability references. Prohibited inputs include postdecision returns, source or
retained held-out quality, selected identities, compression savings, solver
status, algorithm runtime, future survival, and any quantity computed after the
decision origin.
