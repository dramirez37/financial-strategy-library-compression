# Proposal Policy Interface

The evaluation stage consumes the proposal result only through two manifest-bound
interfaces and the final proposal policy result seal.

Public manifest: `proposal_policy/PROPOSAL_POLICY_MANIFEST.toml`.

Licensed local manifest:
`local_data/proposal_policy/PROPOSAL_POLICY_LOCAL_MANIFEST.toml`.

Both retain all 38 registered cells. Each public cell contains `cell_index`,
`origin_id`, `universe_id`, `role`, `universe_status`, `universe_gate_passed`,
`evaluation_year`, `security_weight_cap`, `primary_choices`,
`choice_aggregate_sha256`, and `proposal_incremental_point_delta`. Public
`primary_choices` contain policy identifiers, availability, selected counts,
same-as-comparator indicators, eligibility/completeness counts, choice hashes, failure
codes, and proposal deltas. They never contain a return-selected strategy identity.

The local cell contains all public fields plus exact `strategy_ids` inside each choice,
the manifest-bound combined-history Parquet path/hash, the proposal trial-ledger
path/hash, and the local choice-artifact path/hash. A failed universe cell has no
combined-history artifact and all five policies unavailable, but remains in every
denominator.

The evaluation extractor may open only the exact local combined artifact and choices
bound by the local manifest after `PROPOSAL_POLICY_RESULT_SEAL.toml` replays with
status `SEALED_PROPOSAL_POLICY_RESULT`. Proposal artifacts contain no evaluation-year
return values. The evaluation extractor must use a newly sealed identifier/date mask;
this interface does not itself authorize evaluation access.
