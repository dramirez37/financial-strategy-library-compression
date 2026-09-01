# Analysis correction 001 — exclude inapplicable runs from runtime summaries

**Date:** 2026-09-01

**Applies to:** Registered Point-in-Time Financial Strategy-Library Panel v1

The completed Lock 023 experiment, result audit, and first analysis audit were
already available when this reporting defect was identified. The grouped
runtime implementation summarized every nonmissing elapsed time, including
the near-zero time needed to declare complete enumeration inapplicable when
the residual strategy count exceeded its registered limit. In cells with a
majority of such skips, the resulting median did not describe an executed
algorithm.

This correction implements the registered distinction between applicability
and execution. A runtime enters a grouped runtime summary if and only if the
algorithm row is marked `applicable = true` and its elapsed time is present.
Skipped and preparation-failure rows remain in every registered denominator,
status count, and applicability count; they are not converted to successful
runs or deleted. The correction changes no algorithm row, candidate, strategy
identity, burden, certificate, solver status, source instance, weight, seed,
time limit, postdecision diagnostic, or registered analysis question.

The original Lock 023 analysis artifacts remain immutable. Corrected public
summaries are generated in a separate directory, are bound to the passing
Lock 023 result and analysis audits, and are independently checked against an
explicit public-column whitelist. This is a disclosed post-result
implementation correction, not a prospective amendment and not an additional
analysis selected because of its findings.
