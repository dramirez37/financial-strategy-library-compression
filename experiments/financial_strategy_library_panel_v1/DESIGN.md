# Registered Point-in-Time Financial Strategy-Library Panel v1

**Protocol date:** 2026-08-28  
**Status:** prospectively specified before reading licensed rows for this study
or generating any study outcome.

## Purpose and claim boundary

This study asks how much declared active-maintenance burden can be removed from
financial strategy libraries constructed at repeated historical decision
origins while preserving the source library's predecision operating frontier
and verified capability inventory. It is a finite operations-research panel,
not a trading-strategy test. It makes no causal, forecasting, alpha,
deployable-performance, or population resource-savings claim.

The prior terminal and annual audits, their limitations, and their outcomes are
known. They are not pooled with this study. Their endpoint-survivor construction
motivated the present point-in-time correction, but no prior identity, burden
saving, algorithm ranking, or held-out score is an input to this design.

## Prospective timing and scientific units

The registry fixes 20 annual decision origins from 2005 through 2024. At each
origin, the actual decision date is the last CRSP trading session on or before
December 31. The preceding five calendar years are partitioned before any
calculation:

- years \(y-4,\ldots,y-2\): source-library construction and belief-cutpoint
  estimation;
- years \(y-1,y\): compression-time operating profiles and burden calibration;
- year \(y+1\): postdecision diagnostic only.

The primary scientific unit is one origin--library-construction--burden-schedule
instance. Algorithm rows are repeated measurements within that instance; the
decision origin is the dependence cluster. Formation windows overlap across
origins, but the registered postdecision calendar years do not.

## Origin-eligible universe

Universe selection is reconstructed independently at every origin. A security
must be classified as `FUND`/`ETF` and active in the security-history interval
containing the origin. The rule never asks whether the PERMNO or ticker survives
to a later endpoint. A later delisting therefore does not remove an otherwise
eligible origin record.

Eligibility uses only security-history fields and pre-origin prices and volume:

1. at least 1,000 pre-origin daily records, before parsing return values, to
   establish sufficient history for strategy estimation;
2. at least 400 valid price--volume observations in the two-year compression
   window;
3. median close of at least USD 5 and median dollar volume of at least USD 5
   million in that window;
4. exclusion of the registered complex-product name keywords using the
   origin-valid security name; and
5. the 150 most liquid eligible PERMNOs, ordered by descending median dollar
   volume and ascending PERMNO.

`dlyret` is not parsed for eligibility or universe ranking. The universe step records every
eligible and excluded PERMNO with a reason in an ignored licensed audit; public
outputs contain counts and hashes only. Fewer than 20 eligible securities or a
missing SPY reference record produces a registered origin failure, not a
replacement universe.

This corrects future-survival conditioning, but the available CRSP files are a
current snapshot without provider revision timestamps. The study is therefore
origin-eligible, not vintage-database certified.

## Fixed candidate grammar

For every eligible PERMNO, the candidate grammar is the same 96-row factorial
of three directional signals, two entry filters, two holding horizons, two
sizing rules, two exit rules, and two risk constraints. Strategy identifiers
use PERMNO and the complete grammar tuple; ticker changes never splice different
PERMNOs. Signals formed through close (t) first earn the return from (t+1)
to (t+2).

Belief rows are five SPY trailing-60-session-return states. Quintile cutpoints
are estimated only in the construction window and then applied unchanged to
the compression and postdecision windows.

## Three source-library constructions

The three constructions model different research organizations and are not
replicate labels for one catalog.

1. **Full factorial research catalog.** Every valid grammar row for every
   eligible PERMNO is retained in the source. This represents an unconsolidated
   candidate archive in active maintenance.
2. **Decentralized signal sleeves.** Within each PERMNO and directional-signal
   family, the two highest construction-window scores are retained, including
   every exact cutoff tie. Missing registered capabilities are completed by all
   best construction-window carriers. This represents asset sleeves maintaining
   local champions.
3. **Centralized research pool.** The globally highest (2N_y) construction-
   window scores are retained for an origin with (N_y) eligible PERMNOs,
   including exact cutoff ties, then every construction-window belief-frontier
   attainer and all best carriers of missing capabilities are added. This
   represents centralized screening with explicit productive-completeness
   constraints.

Construction scores use the registered mean--variance audit functional and
only construction-window observations. Stable strategy identifiers resolve
ordering. A construction-score tie means bitwise equality of the deterministic
`Float64` calculation; the registered tolerance is a cross-computation
validation threshold and never creates or removes a tie. After instance
coordinates are frozen and losslessly converted to rationals, frontier ties use
exact rational equality. Every tie at a registered construction cutoff is
retained rather than broken silently.

## Capability ownership and closure

`registry/CAPABILITY_REGISTRY.csv` defines 27 versioned capabilities: 13 atomic
grammar components and 14 software-interface combinations. A generated strategy
specification owns active-maintenance responsibility for every matching atomic
and interface capability. The owner map is a deterministic function of its
canonical public specification and SHA-256 hash. An unresolved, unversioned, or
unhashed capability rejects the source instance.

Ownership here means registered maintenance responsibility inside this finite
catalog. It does not assert intellectual-property ownership, sole physical
storage, institutional approval, or irreplaceable tacit knowledge. The exact
scope and evidence rules are in `CAPABILITY_OWNERSHIP.md`.

Primary closure is identity union over these versioned capability identifiers.
Compound interface identifiers prevent the audit from treating every atomic
component pairing as automatically interchangeable, while retaining the tagged
identity-closure algorithmic boundary.

## Calibrated predecision burden schedules

The primary burden is an exact integer count of validation work blocks computed
from compression-window event counts. Equal active-strategy burden and a
governance-review checklist count are registered robustness schedules. Formulas,
units, missing-data rules, and prohibited inputs are fixed in
`BURDEN_CALIBRATION.md` and the burden registry. None is a dollar, labor-hour,
or realized-performance measure unless a future separately registered study
collects such data.

## Algorithms and certification

Every instance uses full fixed-point preprocessing with reconstruction,
preprocessed HiGHS MIP, weighted greedy plus reverse deletion,
heaviest-safe-first, declared source order, and 32-start random rechecked
deletion. Requirement-mask DP applies only at at most 22 residual requirements;
enumeration applies only at at most 24 residual optional strategies. Inapplicable
methods receive explicit terminal rows.

Every returned original-identifier library is independently rechecked for:

- all mandatory strategies;
- exact tagged coverage;
- exact source operating-frontier equality;
- exact identity-closure equality; and
- exact rational burden.

HiGHS `OPTIMAL` is solver evidence plus an exact incumbent certificate, not
formal or exhaustive proof. Exact finite agreement is reported only where DP
or enumeration is applicable and completes.

## Parallel execution and outcome firewall

The future runner uses eight supervisor workers. Each algorithm subprocess uses
one Julia, BLAS, and HiGHS thread. Stable round-robin assignment is fixed before
outcomes. Progress displays may read terminal-record counts only.

No postdecision return or diagnostic may alter universe membership, source
construction, capability ownership, weights, preprocessing, applicability,
algorithm choice, warm start, tie handling, or exclusions. Postdecision data
are opened only after the instance, algorithm outputs, and exact certificates
are sealed.

## Registration, dry run, and lock

Registration validation reads only these public design files. Synthetic dry
runs use no registered final seed and no licensed row. The design lock hashes
the design, analysis plan, reporting rules, data/capability/burden protocols,
configuration, registries, validation and lock code, targeted tests, algorithm
implementations, environment, data boundary, and journal artifact manifest.

Any scientific change after locking requires a new study or a numbered,
prospective amendment that lists all outcomes already accessible. The original
lock is never rewritten.
