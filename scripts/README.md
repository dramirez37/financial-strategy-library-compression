# Repository Scripts

`audit_public_repository.sh` checks the staged/current public tree without
printing suspected values. It rejects tracked licensed inputs, credential and
notebook files, secret signatures, local home-directory paths, email
addresses, machine caches, ignored-but-tracked files, proprietary data
formats, raw CRSP-like CSV schemas, and oversized binary artifacts. Top-level
`make public-audit` runs this fast release-surface gate.

`preprint_check.sh` is the nonmutating orchestrator behind
`make preprint-check`. It checks the pinned environment, required public files,
the disclosure boundary, active manuscript/supplement source references,
exact and canonical drift gates, frozen randomized locks and committed-result
reconciliation, public financial aggregate certificates, and all live
manuscript figure/table producers. It does not run Lean, licensed rows, or the
registered `N=1024` replay.

`formal_check.sh` is the single formal workflow behind `make formal` and the
formal stages of `verify.sh`. It runs the clean build, prohibited-marker scan,
comprehensive axiom audit and whitelist, and manuscript linter.

`check_manuscript_sources.sh` follows the active recursive input graphs and
performs the shared nonmutating bibliography, label, and reference audit for
the primary manuscript and Online Supplement as separate documents.
`verify.sh` reuses it after compilation.

`run_financial_licensed.sh` is the explicit licensed-data orchestrator behind
`make financial-licensed`. It requires `ALGOLIB_CRSP_ROOT` and delegates all
presence, schema, identity, preparation, audit, drift, and certificate logic to
the registered Julia scripts. It performs no download and defines no model or
data-processing rule itself.

`verify.sh` is the release-level orchestrator behind top-level `make verify`.
It runs the pinned environment checks, clean Lean build, comprehensive axiom
audit, Julia package and registered experiment gates, public financial
aggregate checks, generated figure/table checks, manuscript build, artifact
drift checks, and bibliography/reference reconciliation in dependency order.
Its environment stage includes the public-repository audit.
It prefers the ignored repository-local Julia 1.12.6 runtime and also accepts
an explicit `JULIA_EXE` pointing to Julia 1.12.6.

`full_check.sh` is retained as a compatibility alias for `verify.sh` so older
commands and documentation execute the same complete gate. Additional scripts
must use Julia for research computation and shell only for orchestration.
