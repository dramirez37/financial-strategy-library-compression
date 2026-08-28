# Capability ownership protocol

## Meaning of ownership

For this study, ownership is a narrow, auditable assignment of active-
maintenance responsibility inside a generated strategy catalog. Each strategy
has a canonical, public-safe specification containing its origin, library,
PERMNO, and grammar tuple. The canonical bytes and SHA-256 hash are fixed before
compression. A strategy is a carrier of every registered atomic and interface
capability referenced by that specification.

This convention does not imply intellectual-property ownership, unique physical
storage, a legal archive, institutional approval, or irrecoverable tacit
knowledge. Those objects require a different empirical inventory.

## Registered capabilities

The registry contains six atomic classes and three interface classes:

- directional signal, entry filter, holding horizon, sizing rule, exit rule,
  and risk constraint;
- signal--filter, horizon--exit, and sizing--risk interfaces.

The interface rows are versioned artifacts, not closure-generated combinations.
They therefore prevent the primary model from silently treating every pair of
atomic components as compatible. Primary closure remains identity union over
the resulting capability identifiers.

## Carrier and evidence rules

For each source strategy:

1. serialize the complete specification in stable field order;
2. hash the canonical bytes;
3. derive exactly six atomic and three interface capability identifiers;
4. verify that all nine identifiers occur once in the locked capability
   registry; and
5. append `(origin, library, strategy, capability, specification hash)` to the
   local carrier map.

An unknown capability value, missing specification hash, duplicate strategy
identifier, or carrier not present in the source rejects the instance. The
source closure is the exact set union of its verified carriers. No held-out
quantity can create, remove, or reassign a capability.

Source-library completion uses construction-window scores only. When a
construction lacks a registered capability, every exact best construction-
window carrier is added. This completion rule is part of source construction,
not the later compression algorithm.

## Audit outputs

The public-safe capability audit may report identifiers, carrier counts,
unique-carrier counts, specification hashes, and reconstruction certificates.
It may not report market observations or row-level vendor metadata. The final
result audit recomputes the carrier map from canonical strategy specifications
and rejects any mismatch.
