# Journal revision ledger

## Decisions implemented

1. Build the journal article from the immutable preprint baseline without
   changing `release/v0.1.1-arxiv/`.
2. Use the official Springer Nature LaTeX wrapper and the journal's required
   author--year citation convention.
3. Preserve the audited scientific sections by reference; journal-only copies
   exist only where the introduction, compression section, experiment section,
   or conclusion needs a submission-specific change.
4. Promote SC-COMP into the journal manuscript as a HUMAN PROOF for the
   explicitly encoded identity-closure decision problem. Its hardness source
   is normalized full-union weighted set cover; the proved restricted target
   has one belief, all-zero profiles, mandatory zero-burden inactivity, and
   module rows equal to the source set family. The theorem has exact budgeted
   Julia reduction fixtures but no Lean declaration, and the prose says so
   explicitly. Frontier-only and arbitrary-closure NP-completeness claims are
   outside this theorem.
5. Integrate the existing `approximate-library-compression-v1` artifacts as a
   bounded numerical subsection. This is not a new study, does not alter the
   frozen N=1024 registry, and creates no approximation guarantee.
6. Do not launch a new algorithmic benchmark. A new study would require its
   own `experiments/algorithmic_compression_v1/` registry, seeds, design lock,
   and an explicit request before the long final run.
7. Keep personal affiliation, funding, competing-interest, and contribution
   statements as visible blockers until the author confirms them.
8. State SC-TAG as an identity-closure theorem with all belief tags retained,
   a disjoint module-tag carrier, mandatory inactive retention, exact weighted
   binary formulation, and an explicit nonidentity-closure boundary. The
   manuscript proof remains labeled HUMAN PROOF; its exact core biconditional
   and burden identity are separately Lean verified, while the Julia fixture
   is identified only as exact finite computation.

## Baseline gate finding

The pre-existing `make preprint-check` fails after its public and manuscript
source audits because it regenerates the frozen arXiv source bundle from the
mutable manuscript bibliography and compares the result with the historical
bundle. The journal revision does not modify the frozen release to mask that
defect. The journal gate instead checks the release tree against baseline
commit `1f414769459e314e594a8a2b9b679996b04597ba`.
