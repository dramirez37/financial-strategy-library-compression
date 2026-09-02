# Proposal Computation Amendment 001

The first proposal computation attempt ran under the replayed proposal execution lock
and opened only authorized proposal-year staged artifacts. It stopped because the
runner asserted that all five registered policies must select at least one ledger row.
For cells with no complete active proposal path, the preregistered forced-max negative
control has no legal selection: cash is explicitly omitted. The policy engine had
already returned the registered `NO_COMPLETE_ACTIVE_PROPOSAL_PATH` failure, but the
runner rejected that valid state.

At discovery, proposal-path availability for the attempted cells was known. This is
recorded as post-proposal-access operational knowledge; it does not authorize or use
evaluation information.

Seven cell path Parquets were written by other Julia threads before interruption. No
proposal computation manifest, choice artifact, or completed proposal trial ledger was
written. No evaluation-year value was inspected, materialized, or used.

This amendment binds those seven partial artifacts and changes only the terminal
validation predicate. The four cash-capable policies must each freeze a choice. The
forced-max negative control may freeze without a selected path only when its exact
failure is `NO_COMPLETE_ACTIVE_PROPOSAL_PATH`. No estimation, bootstrap, shrinkage,
adoption, tie-break, action-set, or policy rule changes.
