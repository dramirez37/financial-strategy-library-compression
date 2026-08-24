# Raw model foundation

This directory derives the first raw-to-compressed prerequisites while reusing
the verified F0 catalog, library, frontier, and closure objects.

- `StrategyCatalog.lean`, `Library.lean`, and `ModuleSet.lean` give the existing
  finite exact objects explicit raw-layer names.
- `Closure.lean` exposes the raw closure operator and proves closure
  absorption.
- `CandidateGeneration.lean` and `Admission.lean` define the primitive exact
  generation and bounded verification inputs.
- `AdmittedCandidate.lean` derives the normalized admitted-candidate law.
- `LibraryUpdate.lean` defines failure/success updates on raw libraries.
- `CompressedUpdate.lean` proves the frontier, module, closure, and RC1 local
  compressed updates.

No file here defines or changes a primitive research transition, joint
belief/outcome coupling, Bellman recursion, or T1 theorem.
