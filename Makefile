LOCAL_JULIA := $(CURDIR)/.local_runtime/julia-1.12.6/bin/julia
JULIA_EXE ?= $(if $(wildcard $(LOCAL_JULIA)),$(LOCAL_JULIA),julia)
export JULIA_EXE
export ALGOLIB_CRSP_ROOT

.PHONY: help preprint-check canonical randomized formal manuscript arxiv-bundle \
	journal journal-check journal-submission-check financial-licensed public-audit verify \
	aor-algorithm-tests aor-generator-tests

help:
	@printf '%s\n' \
		'make preprint-check     Fast nonmutating public-release checks (no N=1024 replay)' \
		'make canonical          Reproduce the canonical benchmark and check manuscript artifacts' \
		'make randomized         Reproduce and independently audit the registered N=1024 study' \
		'make formal             Run the declared Lean build, linter, and axiom audit' \
		'make manuscript         Compile the main preprint and online supplement' \
		'make arxiv-bundle       Assemble the minimal two-document arXiv source package' \
		'make journal            Build the Annals of Operations Research journal draft' \
		'make journal-check      Run the targeted journal-source and artifact gate' \
		'make journal-submission-check  Reject unresolved author confirmations' \
		'make aor-algorithm-tests  Triangulate journal algorithms and audit saved certificates' \
		'make aor-generator-tests  Validate registered benchmark generators without final runs' \
		'make financial-licensed Run both licensed-data audits and the cross-audit optimization' \
		'make verify             Run the complete release gate'

preprint-check:
	@./scripts/preprint_check.sh

canonical:
	@"$(JULIA_EXE)" --project=julia julia/scripts/solve_unified_canonical_benchmark.jl
	@"$(JULIA_EXE)" --project=julia julia/scripts/generate_manuscript_numerical_artifacts.jl --check

randomized:
	@"$(JULIA_EXE)" --project=julia julia/scripts/lock_randomized_library_design_v2.jl --check
	@"$(JULIA_EXE)" --project=julia julia/scripts/lock_randomized_library_stability_amendment.jl --check
	@"$(JULIA_EXE)" --project=julia julia/scripts/lock_randomized_library_execution_amendment.jl --check
	@"$(JULIA_EXE)" --project=julia julia/scripts/run_randomized_library_stress_v2.jl
	@"$(JULIA_EXE)" --project=julia julia/scripts/audit_randomized_library_v2_results.jl

formal:
	@./scripts/formal_check.sh

manuscript:
	@./manuscript/build.sh
	@./manuscript/online_supplement/build.sh

arxiv-bundle:
	@./scripts/build_arxiv_bundle.sh

journal:
	@./journal/aor/build.sh

journal-check:
	@./journal/aor/check.sh

journal-submission-check:
	@./journal/aor/check.sh --submission-ready

aor-algorithm-tests:
	@"$(JULIA_EXE)" --startup-file=no --project=julia/test julia/test/run_aor_algorithm_tests.jl

aor-generator-tests:
	@"$(JULIA_EXE)" --startup-file=no --project=julia/test julia/test/run_algorithmic_compression_generator_tests.jl

financial-licensed:
	@./scripts/run_financial_licensed.sh

public-audit:
	@./scripts/audit_public_repository.sh

verify:
	@./scripts/verify.sh
