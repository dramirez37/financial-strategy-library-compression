# Independent Exactness Audit Protocol

Status: implemented protocol for the AoOR journal algorithm program

Audit schema: `journal-compression-exactness-audit-v1`

Manifest schema: `journal-compression-exactness-manifest-v1`

## Purpose and evidence boundary

This layer tests whether independently implemented algorithms and saved solver
outputs agree on the same exact identity-closure compression instance. It does
not turn a mixed-integer solver status into a proof. The evidence classes remain
separate:

- complete enumeration is an exact finite computation over every admissible
  optional-strategy subset within the declared size limit;
- requirement-mask dynamic programming is a separate exact finite computation;
- HiGHS supplies mixed-integer solver evidence;
- reconstruction, tagged coverage, mandatory retention, operating-frontier
  equality, generative-closure equality, and burden reconciliation are checked
  afterward with exact repository arithmetic; and
- SHA-256 establishes byte identity of saved artifacts, not mathematical truth.

The live audit and the offline audit are intentionally separate. The live audit
invokes algorithms. The offline audit reads existing certificates and instances
only and never invokes enumeration, dynamic programming, HiGHS, or a writer.

## Small-instance protocol

`audit_journal_small_instance(instance)` performs the following operations on
one validated `JournalCompressionInstance`:

1. Solve by complete enumeration with exact rational burden.
2. Solve independently by requirement-mask dynamic programming.
3. Solve the preprocessed binary covering formulation through JuMP and HiGHS
   with one thread, parallel mode off, exact-zero MIP tolerances, a recorded
   seed, and the MIP workflow's complete captured log. The MIP workflow's own
   exact-oracle option is disabled so it cannot make the cross-method comparison
   circular.
4. Recheck each returned representative in original instance coordinates for:
   mandatory retention, complete tagged coverage, exact source-frontier
   equality, exact identity closure, exact burden, and burden reconciliation.
5. Compare the three exact rechecked burdens.
6. Compare the three reconstructed selected-index tuples. Different tuples are
   recorded by `optimizer_identities_differ`; they are not an error when burdens
   agree and all selections are feasible.
7. Preserve HiGHS termination status, best bound, and reported relative gap as
   solver diagnostics. A nontrivial small MIP is conclusive only when HiGHS
   reports `OPTIMAL`. A model eliminated completely by exact preprocessing is
   separately marked `solved_by_exact_preprocessing`; it does not acquire a
   fabricated solver status.

A small audit passes only if both exact searches complete, the MIP pipeline is
conclusive, all three reconstructed representatives pass exact checks, and all
three exact burdens agree. Solver `OPTIMAL` remains a numerical solver report;
the independent exact methods supply the exhaustive finite cross-check.

The audit uses the instance's declared tie mode for enumeration and dynamic
programming. The current MIP result schema intentionally returns one
representative and rejects a `complete` tie declaration. Such an instance
therefore fails three-method auditing rather than silently weakening the tie
contract.

## Medium and financial protocol

`audit_journal_mip_output(instance, result)` is the in-memory path for instances
outside the registered small-oracle limits. It verifies the result's instance
hash and, whenever a candidate is present, independently recomputes exact
feasibility and burden in original coordinates. It retains, without promoting
them to proof:

- termination, primal, and dual status;
- solver objective and best bound when available;
- solver-reported relative gap when available; and
- whether an exactly rechecked incumbent exists.

An honest time-limited result with no incumbent is retained as diagnostics-only
evidence; it is not relabeled infeasible or optimal. An accepted incumbent must
pass the exact recheck. Missing solver fields remain explicitly unavailable.

Financial use is subject to the licensed-data boundary. The in-memory audit is
available in an authorized environment, but bundle writers refuse to serialize
an instance whose provenance sets `redistributable = false`. No raw CRSP/WRDS
row is required or accepted by this audit layer. A distributable financial
bundle may be written only after the instance itself has been approved as a
legal derived artifact.

## Second-solver status

No second open-source MIP solver is present in either pinned Julia environment:
the project and test manifests contain JuMP and HiGHS but not SCIP, Cbc, or
GLPK. This task therefore adds no package and no proprietary dependency. Every
certificate records the limitation as:

`unavailable: no second open-source solver is pinned in the Julia environments`

Adding SCIP solely for this optional check would change the pinned dependency
graph and is deferred unless a separate environment-stability review authorizes
it. The present defense is exact enumeration plus independent exact DP on small
instances and exact post-solve certification at all sizes.

## Certificate bundles

Certificate creation is an explicit mutating step, separate from audit:

- `write_journal_small_exactness_audit_bundle(directory, instance)` runs the
  three-method small audit and writes the instance, two exact certificates, the
  complete MIP certificate/log, and the comparison certificate.
- `write_journal_mip_exactness_audit_bundle(directory, instance, result)` writes
  a medium/financial MIP result already obtained by the caller, its exact
  recheck, and the distributable instance.

Writers accept only an absent or empty destination and never overwrite a
nonempty bundle. Each bundle contains `certificate_manifest.toml`. The manifest
records the relative path, byte count, and lowercase SHA-256 for every other
file. It deliberately does not claim a self-hash. The writer returns the
manifest's SHA-256 to the caller.

A successful small bundle contains:

| File | Role |
|---|---|
| `instance.toml` | Canonical exact source instance |
| `enumeration.toml` | Complete-enumeration result and exact certificate |
| `dp.toml` | Requirement-mask DP result and exact certificate |
| `mip.toml` | Complete HiGHS diagnostics, log, candidate, and exact post-check |
| `exactness_audit.toml` | Cross-method burden, feasibility, and identity comparison |
| `certificate_manifest.toml` | Hash and byte-count inventory |

A MIP-only bundle omits the enumeration and DP files. If a live small method
throws or the methods disagree, the writer does not discard the event: it
writes method-specific error certificates and a
`minimized_failure_instance.toml` when minimization is reproducible.

## Disagreement retention and minimization

Any failed live small audit triggers a deterministic delta-minimization attempt
unless the caller explicitly disables it. The minimizer embeds the original
tagged carrier matrix as an identity-closure module-cover instance with a
trivial zero frontier, then repeatedly attempts:

1. removal of one nonmandatory strategy while every retained requirement still
   has a carrier; and
2. removal of one requirement.

A removal is retained only if the three-method failure reproduces. Iteration
continues to a deterministic one-deletion fixed point. The resulting fixture
preserves original exact weights and mandatory flags, records the source
instance hash as provenance, and is included in a written failure bundle. This
is a locally minimized failing fixture, not a claim of minimum possible failure
size. If the carrier embedding cannot reproduce a metadata-specific failure,
the original source instance is retained and the limitation is stated in the
minimization status.

## Offline, nonmutating directory audit

The command

```sh
./.local_runtime/julia-1.12.6/bin/julia --startup-file=no --project=julia \
  julia/scripts/audit_journal_result_directory.jl RESULT_DIRECTORY
```

recursively finds certificate manifests and, without rerunning any solver:

- requires the manifest inventory to equal the bundle's file inventory;
- checks every byte count and SHA-256;
- deserializes and revalidates the canonical instance;
- checks every method certificate against the instance hash;
- reconstructs selections from saved original indices;
- recomputes exact burden, frontier, closure, tagged coverage, and mandatory
  retention;
- compares enumeration, DP, and MIP burdens for small bundles;
- records whether saved optimizer identities differ at equal objective;
- checks that the saved comparison declaration agrees with the independently
  recomputed comparison; and
- retains MIP bound and gap diagnostics for MIP-only bundles.

The command prints machine-readable TOML and exits nonzero on a missing
manifest, hash mismatch, malformed certificate, failed exact check, inconclusive
small MIP, or small-method objective disagreement. Parsing failures become
bundle errors instead of being silently skipped. The audit function performs no
filesystem write; its nonmutation property is covered by before/after content
hash tests.

## CI gate

Run:

```sh
make aor-algorithm-tests
```

The target uses the repository's Julia 1.12.6 executable when present and the
pinned `julia/test` environment. It runs only the focused exactness-audit tests,
including a committed deterministic matrix of small coverage systems. Every
matrix instance is solved by enumeration, DP, and HiGHS and independently
rechecked. Any exact burden or feasibility disagreement fails the test process
and therefore the Make target.

The targeted gate also tests hash corruption, saved-directory nonmutation,
MIP-only bound preservation, failure-fixture minimization, complete-tie
incompatibility, and refusal to serialize nonredistributable instances. It does
not run the frozen N=1024 study, licensed financial workflows, the long final
benchmark, or the complete repository verification suite.

## Claim limitations

- Agreement among three implementations is strong finite-instance evidence but
  is not a general proof of implementation correctness.
- HiGHS `OPTIMAL` is not Lean verification, an exhaustive search claim, or a
  formal proof.
- Floating-point solver objectives, bounds, and gaps are retained exactly as
  diagnostics; only reconstructed library burden and semantic feasibility are
  recomputed with exact rational arithmetic.
- The protocol applies to the tagged identity-closure formulation. It does not
  transfer the covering equivalence or algorithm guarantees to arbitrary
  nonidentity closure.
- No runtime or scaling conclusion follows from the audit tests.
