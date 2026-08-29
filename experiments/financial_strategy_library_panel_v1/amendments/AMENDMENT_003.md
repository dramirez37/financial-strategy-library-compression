# Prospective Amendment 003 — terminal origin-construction failures

**Date:** 2026-08-29

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

## Information available before this amendment

After Execution Lock 002, the corrected licensed extractor passed the complete
structural panel and reconciled the registered 340 first-row `NS` exclusions.
During the subsequent unchanged construction phase, 12 origins serialized 108
source instances and 8 origin tasks produced no instance. The supervisor's
first reported exception was “a registered belief profile has too few
observations.” No registered seed was consumed; no algorithm, solver,
postdecision, selected-library, burden-saving, or comparative result was run or
inspected. Existing instance contents were not summarized or compared.

The original design already states that an incomplete operating profile rejects
the source instance and that registered failures remain in denominators. The
implementation defect was that preparation deferred task exceptions and then
aborted without serializing the required failure records, preventing the study
from continuing with visible failures.

## Prospective implementation correction

1. The minimum of 25 observations in every declared belief-state profile is
   unchanged. No missing profile is imputed and no failed origin is repaired.
2. Each failed origin receives one terminal origin-construction record containing
   its phase, exception class and sanitized message, origin-universe aggregate,
   return-quality counts, and `licensed_rows_included=false`.
3. Each failed origin produces nine terminal preparation-failure slots—one for
   every registered library and burden-schedule combination—and therefore 63
   registered algorithm failure rows. No `JournalCompressionInstance` is
   fabricated for those slots.
4. Successful serialized instances and preparation-failure slots must be
   disjoint and together equal all 180 registered instance keys. Their implied
   algorithm rows must equal 1,260.
5. Structural and postdecision audits retain every failed slot in denominators.
   Postdecision data cannot convert a failed structural slot into an available
   result.
6. Threaded progress counts terminal origin tasks. At completion, the runner
   records all construction failures instead of aborting solely because an
   origin failed a registered rule. Infrastructure exceptions outside the
   origin construction function still abort.
7. Existing 108 instances from the interrupted Lock 002 run may be reused only
   if byte-identical to the recomputed instances. No valid terminal record may
   be overwritten.

## Unchanged design

Origins, universe construction, strategy grammar, lookbacks, belief states,
minimum observations, library constructions, capabilities, weights, algorithms,
seeds, solver settings, estimands, postdecision firewall, and nonclaims are
unchanged. This amendment implements the prespecified failure denominator; it
does not alter which origin passes.

Execution Locks 001 and 002 remain immutable. Execution Lock 003 binds this
failure-persistence correction and acknowledges the 108 preexisting instances.
