LOCAL_JULIA := $(CURDIR)/.local_runtime/julia-1.12.6/bin/julia
JULIA_EXE ?= $(if $(wildcard $(LOCAL_JULIA)),$(LOCAL_JULIA),julia)
export JULIA_EXE
export ALGOLIB_CRSP_ROOT

.PHONY: help preprint-check canonical randomized formal manuscript arxiv-bundle \
	journal journal-check journal-submission-check financial-licensed public-audit verify \
	aor-theory-check aor-algorithm-tests aor-generator-tests aor-benchmark \
	aor-benchmark-v1-audit aor-benchmark-audit aor-manuscript \
	aor-source-completeness aor-public-boundary aor-check aor-release \
	aor-benchmark-v2-tests aor-benchmark-v2-lock aor-benchmark-v2 aor-benchmark-v2-audit \
	aor-benchmark-v2-analysis \
	aor-financial-algorithm-tests aor-financial-algorithm-lock \
	aor-financial-algorithms aor-financial-algorithm-audit \
	aor-financial-algorithm-promote aor-financial-weight-robustness-tests \
	aor-financial-weight-robustness-lock aor-financial-weight-robustness \
	aor-financial-weight-robustness-audit aor-financial-weight-robustness-promote \
	aor-financial-panel-v1-design-check aor-financial-panel-v1-tests \
	aor-financial-panel-v1-execution-lock aor-financial-panel-v1-smoke \
	aor-financial-panel-v1-run aor-financial-panel-v1-continue \
	aor-financial-panel-v1-audit aor-financial-panel-v1-analysis \
	aor-financial-panel-v1-analysis-audit \
	aor-financial-panel-v2-design-check aor-financial-panel-v2-economic-design-audit \
	aor-financial-panel-v3-design-check aor-financial-panel-v3-source-census-check \
	aor-financial-panel-v3-predecision-check \
	aor-financial-panel-v3-predecision-computation-tests \
	aor-financial-panel-v3-predecision-computation-lock \
	aor-financial-panel-v3-predecision-computation-run \
	aor-financial-panel-v3-predecision-computation-audit \
	aor-financial-panel-v3-predecision-result-seal \
	aor-financial-panel-v3-proposal-tests \
	aor-financial-panel-v3-proposal-stage-audit \
	aor-financial-panel-v3-proposal-replay \
	aor-financial-panel-v3-proposal-audit \
	aor-financial-panel-v3-proposal-result-seal \
	aor-financial-panel-v3-proposal-chain-audit \
	aor-financial-panel-v3-proposal-robustness-tests \
	aor-financial-panel-v3-proposal-robustness-run \
	aor-financial-panel-v3-proposal-robustness-audit \
	aor-financial-panel-v3-proposal-robustness-result-seal \
	aor-financial-panel-v3-evaluation-amendment-check \
	aor-financial-panel-v3-evaluation-stage-audit \
	aor-financial-panel-v3-evaluation-run \
	aor-financial-panel-v3-evaluation-audit \
	aor-financial-panel-v3-evaluation-result-seal \
	aor-financial-panel-v4-calibration-check \
	aor-financial-panel-v4-tests \
	aor-financial-panel-v4-design-check \
	aor-financial-panel-v4-run \
	aor-financial-panel-v4-result-audit \
	aor-point-in-time-study-audit aor-closure-option-experiment-audit \
	aor-evidence-status-tests

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
		'make aor-theory-check    Run journal theorem fixtures, Lean build, linter, and axiom audit' \
		'make aor-algorithm-tests  Triangulate journal algorithms and audit saved certificates' \
		'make aor-generator-tests  Validate registered benchmark generators without final runs' \
		'make aor-benchmark       Run the locked final algorithmic benchmark (resume-safe)' \
		'make aor-benchmark-audit Read-only audit of committed final v2 benchmark artifacts' \
		'make aor-manuscript      Compile the Springer article and Online Resource 1' \
		'make aor-check           Run every nonmutating AoOR release gate (no long/licensed replay)' \
		'make aor-release         Build and verify release/v0.2.0-aor-submission/' \
		'make aor-benchmark-v2      Run locked v2 with eight deterministic worker lanes' \
		'make aor-benchmark-v2-audit Independently audit saved v2 benchmark artifacts' \
		'make aor-benchmark-v2-analysis Generate and test locked v2 tables and figures' \
		'make aor-financial-algorithm-tests Test the public-safe financial comparison layer' \
		'make aor-point-in-time-study-audit Verify the sealed public-safe point-in-time financial study inputs' \
		'make aor-closure-option-experiment-audit Recompute and verify the sealed calibrated mechanism experiment' \
		'make aor-financial-algorithm-lock  Verify the financial comparison design lock' \
		'make aor-financial-algorithms Run the locked local licensed comparison' \
		'make aor-financial-algorithm-audit Audit saved local comparison results without solving' \
		'make aor-financial-algorithm-promote Promote only audited public-safe aggregates' \
		'make aor-financial-weight-robustness Run the locked three-schedule robustness study' \
		'make aor-financial-weight-robustness-audit Audit saved robustness results without solving' \
		'make aor-financial-weight-robustness-promote Promote audited robustness aggregates' \
		'make aor-financial-panel-v1-design-check Verify the prospective panel registries and design lock' \
		'make aor-financial-panel-v1-tests Test the eight-thread panel execution and exact certificates' \
		'make aor-financial-panel-v1-smoke Run the eight-lane synthetic execution smoke' \
		'make aor-financial-panel-v1-run Run/resume the locked licensed panel with eight threads' \
		'make aor-financial-panel-v1-continue Resume after the passing structural audit through audited analysis' \
		'make aor-financial-panel-v1-audit Audit completed local panel results without solving' \
		'make aor-financial-panel-v1-analysis Build/resume audited Parquet analysis after the result audit' \
		'make aor-financial-panel-v2-design-check Verify the archived intermediate redesign and public mechanics' \
		'make aor-financial-panel-v2-economic-design-audit Reproduce the sealed-result economic-design diagnosis' \
		'Versioned compatibility targets remain available for immutable lock provenance; use the named study audits above for publication work.' \
		'make aor-evidence-status-tests Check exact Julia-Lean journal evidence fixtures' \
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

aor-theory-check:
	@./scripts/aor_theory_check.sh

aor-algorithm-tests:
	@./scripts/aor_algorithm_tests.sh

aor-generator-tests:
	@"$(JULIA_EXE)" --startup-file=no --project=julia/test julia/test/run_algorithmic_compression_generator_tests.jl

aor-benchmark:
	@"$(JULIA_EXE)" --startup-file=no --project=julia/test julia/test/run_algorithmic_compression_final_runner_tests.jl
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/run_algorithmic_compression_final_v1.jl --check
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/run_algorithmic_compression_final_v1.jl --run

aor-benchmark-v1-audit:
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/audit_algorithmic_compression_final_v1.jl

aor-benchmark-audit:
	@./scripts/aor_benchmark_audit.sh

aor-manuscript:
	@./scripts/aor_manuscript.sh

aor-source-completeness:
	@./scripts/aor_source_completeness.sh

aor-public-boundary:
	@./scripts/aor_public_boundary_audit.sh

aor-check:
	@./scripts/aor_check.sh

aor-release: aor-check
	@./scripts/build_aor_release.sh --build

aor-benchmark-v2-tests:
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia/test julia/test/run_algorithmic_compression_v2_tests.jl

aor-benchmark-v2-lock:
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/lock_algorithmic_compression_design_v2.jl --check

aor-benchmark-v2: aor-benchmark-v2-tests aor-benchmark-v2-lock
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/run_algorithmic_compression_final_v2.jl --check
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/run_algorithmic_compression_final_v2.jl --run

aor-benchmark-v2-audit:
	@./scripts/aor_benchmark_audit.sh

aor-benchmark-v2-analysis:
	@"$(JULIA_EXE)" --startup-file=no --project=julia/test julia/test/run_algorithmic_compression_v2_analysis_tests.jl
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/analyze_algorithmic_compression_v2.jl

aor-financial-algorithm-tests:
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/test/run_financial_algorithm_comparison_tests.jl

aor-financial-algorithm-lock:
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/lock_financial_algorithm_comparison_v1.jl --check

aor-financial-algorithms: aor-financial-algorithm-lock
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/run_financial_algorithm_comparison_v1.jl --licensed

aor-financial-algorithm-audit: aor-financial-algorithm-lock
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/run_financial_algorithm_comparison_v1.jl --audit-only

aor-financial-algorithm-promote: aor-financial-algorithm-lock
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/run_financial_algorithm_comparison_v1.jl --promote-public

aor-financial-weight-robustness-tests:
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/test/run_financial_weight_robustness_tests.jl

aor-financial-weight-robustness-lock:
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/lock_financial_weight_robustness_v1.jl --check

aor-financial-weight-robustness: aor-financial-weight-robustness-lock
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/run_financial_weight_robustness_v1.jl --licensed

aor-financial-weight-robustness-audit: aor-financial-weight-robustness-lock
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/run_financial_weight_robustness_v1.jl --audit-only

aor-financial-weight-robustness-promote: aor-financial-weight-robustness-lock
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/run_financial_weight_robustness_v1.jl --promote-public

aor-financial-panel-v1-design-check:
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/create_financial_strategy_library_panel_v1_registries.jl --check
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/lock_financial_strategy_library_panel_v1_execution_023.jl --check
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/test/run_financial_strategy_library_panel_v1_registration_tests.jl

aor-financial-panel-v2-design-check:
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/create_financial_strategy_library_panel_v2_registries.jl --check
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/lock_financial_strategy_library_panel_v2.jl --check
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/test/run_financial_strategy_library_panel_v2_tests.jl

aor-financial-panel-v2-economic-design-audit:
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/run_financial_strategy_library_panel_v2_economic_design_audit.jl --check

aor-financial-panel-v3-design-check:
	@if test -d experiments/financial_strategy_library_panel_v3/evaluation_results; then \
		echo 'V3_POSTCOMPLETION_DESIGN_CLOSURE_CHECK'; \
		"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/lock_financial_strategy_library_panel_v3_evaluation_staging_validator_amendment_001.jl --check; \
	else \
		"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/check_financial_strategy_library_panel_v3_design.jl --check; \
		"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/lock_financial_strategy_library_panel_v3_design.jl --check; \
	fi
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/test/run_financial_strategy_library_panel_v3_tests.jl

aor-financial-panel-v3-source-census-check:
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/build_financial_strategy_library_panel_v3_universe_census.jl --check

aor-financial-panel-v3-predecision-check: aor-financial-panel-v3-design-check
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/lock_financial_strategy_library_panel_v3_predecision_amendment_001.jl --check
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/test/run_financial_strategy_library_panel_v3_predecision_tests.jl

aor-financial-panel-v3-predecision-computation-tests:
	@"$(JULIA_EXE)" --threads=2 --startup-file=no --project=julia julia/test/run_financial_strategy_library_panel_v3_predecision_computation_tests.jl
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/test/run_financial_strategy_library_panel_v3_predecision_computation_io_tests.jl

aor-financial-panel-v3-predecision-computation-lock: aor-financial-panel-v3-predecision-computation-tests
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/lock_financial_strategy_library_panel_v3_predecision_computation_002.jl --check

aor-financial-panel-v3-predecision-computation-run: aor-financial-panel-v3-predecision-computation-lock
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/run_financial_strategy_library_panel_v3_predecision_computation.jl --run

aor-financial-panel-v3-predecision-computation-audit: aor-financial-panel-v3-predecision-computation-lock
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/run_financial_strategy_library_panel_v3_predecision_computation.jl --audit-only

aor-financial-panel-v3-predecision-result-seal:
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/lock_financial_strategy_library_panel_v3_predecision_binding_amendment_003.jl --check
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/lock_financial_strategy_library_panel_v3_predecision_audit_amendment_004.jl --check
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/seal_financial_strategy_library_panel_v3_predecision_computation_result.jl --check

aor-financial-panel-v3-proposal-tests:
	@"$(JULIA_EXE)" --threads=2 --startup-file=no --project=julia julia/test/run_financial_strategy_library_panel_v3_proposal_tests.jl
	@"$(JULIA_EXE)" --threads=2 --startup-file=no --project=julia julia/test/run_financial_strategy_library_panel_v3_proposal_staging_tests.jl

aor-financial-panel-v3-proposal-stage-audit:
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/lock_financial_strategy_library_panel_v3_proposal_stage_replay_amendment_002.jl --check
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/check_financial_strategy_library_panel_v3_proposal_stage_replay.jl

aor-financial-panel-v3-proposal-replay:
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/run_financial_strategy_library_panel_v3_proposal.jl --run

aor-financial-panel-v3-proposal-audit:
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/run_financial_strategy_library_panel_v3_proposal.jl --audit-only

aor-financial-panel-v3-proposal-result-seal: aor-financial-panel-v3-proposal-stage-audit aor-financial-panel-v3-proposal-audit aor-financial-panel-v3-proposal-chain-audit
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/lock_financial_strategy_library_panel_v3_proposal_policy_interface_003.jl --check
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/export_financial_strategy_library_panel_v3_proposal_policy.jl --check
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/seal_financial_strategy_library_panel_v3_proposal_policy_result.jl --check

aor-financial-panel-v3-proposal-chain-audit:
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/lock_financial_strategy_library_panel_v3_proposal_postcompletion_binding_amendment_003.jl --check
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/lock_financial_strategy_library_panel_v3_proposal_postcompletion_binding_amendment_003_002.jl --check

aor-financial-panel-v3-proposal-robustness-tests:
	@"$(JULIA_EXE)" --threads=2 --startup-file=no --project=julia julia/test/run_financial_strategy_library_panel_v3_proposal_robustness_tests.jl
	@"$(JULIA_EXE)" --threads=2 --startup-file=no --project=julia julia/test/run_financial_strategy_library_panel_v3_proposal_robustness_runner_tests.jl

aor-financial-panel-v3-proposal-robustness-run: aor-financial-panel-v3-proposal-chain-audit aor-financial-panel-v3-proposal-robustness-tests
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/lock_financial_strategy_library_panel_v3_proposal_robustness_computation_amendment_005.jl --check
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/run_financial_strategy_library_panel_v3_proposal_robustness.jl --run

aor-financial-panel-v3-proposal-robustness-audit: aor-financial-panel-v3-proposal-chain-audit
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/lock_financial_strategy_library_panel_v3_proposal_robustness_computation_amendment_005.jl --check
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/run_financial_strategy_library_panel_v3_proposal_robustness.jl --audit-only

aor-financial-panel-v3-proposal-robustness-result-seal: aor-financial-panel-v3-proposal-robustness-audit
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/seal_financial_strategy_library_panel_v3_proposal_robustness_result.jl --check

aor-financial-panel-v3-evaluation-amendment-check:
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/lock_financial_strategy_library_panel_v3_evaluation_staging_validator_amendment_001.jl --check
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/test/run_financial_strategy_library_panel_v3_evaluation_staging_amendment_001_tests.jl
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/test/run_financial_strategy_library_panel_v3_evaluation_result_seal_amendment_001_tests.jl
	@"$(JULIA_EXE)" --threads=2 --startup-file=no --project=julia julia/test/run_financial_strategy_library_panel_v3_evaluation_staging_tests.jl
	@"$(JULIA_EXE)" --threads=2 --startup-file=no --project=julia julia/test/run_financial_strategy_library_panel_v3_evaluation_tests.jl
	@"$(JULIA_EXE)" --threads=2 --startup-file=no --project=julia julia/test/run_financial_strategy_library_panel_v3_evaluation_runner_tests.jl

aor-financial-panel-v3-evaluation-stage-audit: aor-financial-panel-v3-evaluation-amendment-check
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/stage_financial_strategy_library_panel_v3_evaluation_returns_amendment_001.jl --check

aor-financial-panel-v3-evaluation-run: aor-financial-panel-v3-evaluation-amendment-check
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/stage_financial_strategy_library_panel_v3_evaluation_returns_amendment_001.jl
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/run_financial_strategy_library_panel_v3_evaluation_amendment_001.jl --run

aor-financial-panel-v3-evaluation-audit: aor-financial-panel-v3-evaluation-stage-audit
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/run_financial_strategy_library_panel_v3_evaluation_amendment_001.jl --audit-only

aor-financial-panel-v3-evaluation-result-seal: aor-financial-panel-v3-evaluation-audit
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/seal_financial_strategy_library_panel_v3_evaluation_result_amendment_001.jl --check

aor-financial-panel-v4-calibration-check:
	@"$(JULIA_EXE)" --threads=4 --startup-file=no --project=julia julia/scripts/calibrate_financial_strategy_library_panel_v4.jl --check

aor-financial-panel-v4-tests:
	@"$(JULIA_EXE)" --threads=4 --startup-file=no --project=julia julia/test/run_financial_strategy_library_panel_v4_tests.jl

aor-financial-panel-v4-design-check: aor-financial-panel-v4-tests
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/lock_financial_strategy_library_panel_v4_design.jl --check

aor-financial-panel-v4-run: aor-financial-panel-v4-design-check
	@if test -f experiments/financial_strategy_library_panel_v4/RESULT_SEAL.toml; then \
		"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/audit_financial_strategy_library_panel_v4.jl --check; \
	else \
		"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/run_financial_strategy_library_panel_v4.jl --run; \
		"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/audit_financial_strategy_library_panel_v4.jl --seal; \
	fi

aor-financial-panel-v4-result-audit: aor-financial-panel-v4-design-check
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/audit_financial_strategy_library_panel_v4.jl --check

# Publication-facing aliases. Versioned targets and directories remain stable
# because their names are part of immutable design and result provenance.
aor-point-in-time-study-audit:
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/scripts/build_aor_manuscript_evidence_inputs.jl --check

aor-closure-option-experiment-audit: aor-financial-panel-v4-result-audit

aor-financial-panel-v1-tests:
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/test/run_financial_strategy_library_panel_v1_execution_tests.jl

aor-financial-panel-v1-execution-lock:
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/lock_financial_strategy_library_panel_v1_execution_023.jl --check

aor-financial-panel-v1-smoke: aor-financial-panel-v1-execution-lock
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/run_financial_strategy_library_panel_v1.jl --smoke

aor-financial-panel-v1-run: aor-financial-panel-v1-execution-lock
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/run_financial_strategy_library_panel_v1.jl --check
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/run_financial_strategy_library_panel_v1.jl --run

aor-financial-panel-v1-continue: aor-financial-panel-v1-execution-lock
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/run_financial_strategy_library_panel_v1.jl --check
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/run_financial_strategy_library_panel_v1.jl --continue-after-structural-audit

aor-financial-panel-v1-audit: aor-financial-panel-v1-execution-lock
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/audit_financial_strategy_library_panel_v1.jl --all

aor-financial-panel-v1-analysis: aor-financial-panel-v1-execution-lock
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/analyze_financial_strategy_library_panel_v1.jl --run

aor-financial-panel-v1-analysis-audit: aor-financial-panel-v1-execution-lock
	@"$(JULIA_EXE)" --threads=8 --startup-file=no --project=julia julia/scripts/audit_financial_strategy_library_panel_v1_analysis.jl --check

aor-evidence-status-tests:
	@"$(JULIA_EXE)" --startup-file=no --project=julia julia/test/run_journal_evidence_audit_tests.jl

financial-licensed:
	@./scripts/run_financial_licensed.sh

public-audit:
	@./scripts/audit_public_repository.sh

verify:
	@./scripts/verify.sh
.PHONY: ssrn-build ssrn-check
PYTHON_EXE ?= python3

ssrn-build:
	@"$(PYTHON_EXE)" ssrn/current/build.py --output release/v0.3.1-ssrn

ssrn-check:
	@"$(PYTHON_EXE)" ssrn/current/build.py --output release/v0.3.1-ssrn --check
