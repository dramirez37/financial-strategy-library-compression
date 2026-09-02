# Proposal Stage Replay Amendment 002

The immutable proposal execution lock correctly freezes the original proposal runner.
Proposal Computation Amendment 001 later changed only runner validation and namespace
qualification after authorized proposal access. Consequently, the original stage
`--check` rejects the now-amended runner even though proposal extraction code, masks,
staged artifacts, and manifests are unchanged.

This amendment adds a separate checker rather than altering the original lock, stage
script, or results. The checker validates the original proposal execution lock and the
final computation-amendment chain, then reruns the exact 37-cell masked extraction,
reconstructs every combined artifact, and compares both manifests. The failed universe
cell remains outside proposal masks. Evaluation-year values remain unopened. No
scientific design, path, choice, or result changes.
