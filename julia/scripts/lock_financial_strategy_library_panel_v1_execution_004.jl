module LockFinancialStrategyLibraryPanelV1Execution004

using Dates
using SHA: sha256
using TOML

export create_execution_lock_004,
       dry_run,
       main,
       validate_execution_design_004,
       verify_execution_lock_004,
       verify_lock_text

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v1",
)
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_strategy_library_panel_v1.toml",
)
const AMENDMENT_PATH = joinpath(
    EXPERIMENT_ROOT,
    "amendments",
    "EXECUTION_AMENDMENT_004.toml",
)
const DESIGN_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK.json")
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_003.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_004.json")
const DESIGN_AGGREGATE =
    "a549856760f40b28a02571d04869e522ff421390b362147aa1349c52d4e70cba"
const PREDECESSOR_AGGREGATE =
    "f6ad9e0bcbcb04b18aa2b9eee338b2647c5e05e8e5553dbdd5ff2df9bcc9d718"
const PREDECESSOR_FILE_SHA256 =
    "6b3f63e269a8be8eb6f7a7863168e9d5123829151ece218679d20393e7e04488"

const REQUIRED_FILES = (
    "DATA_ACCESS.md",
    "ARTIFACT_MANIFEST.md",
    "experiments/configs/financial_strategy_library_panel_v1.toml",
    "experiments/financial_strategy_library_panel_v1/DESIGN.md",
    "experiments/financial_strategy_library_panel_v1/ANALYSIS_PLAN.md",
    "experiments/financial_strategy_library_panel_v1/REPORTING_RULES.md",
    "experiments/financial_strategy_library_panel_v1/DATA_CONTRACT.md",
    "experiments/financial_strategy_library_panel_v1/CAPABILITY_OWNERSHIP.md",
    "experiments/financial_strategy_library_panel_v1/BURDEN_CALIBRATION.md",
    "experiments/financial_strategy_library_panel_v1/registry/ORIGIN_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v1/registry/LIBRARY_CONSTRUCTION_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v1/registry/CAPABILITY_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v1/registry/BURDEN_SCHEDULE_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v1/registry/SEED_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v1/DESIGN_LOCK.json",
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK.json",
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_002.json",
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_003.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_001.md",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_002.md",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_003.md",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_004.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_001.toml",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_002.toml",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_003.toml",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_004.toml",
    "experiments/financial_strategy_library_panel_v1/amendments/RETURN_QUALITY_AUDIT_001.md",
    "julia/src/TaggedCoverPreprocessing.jl",
    "julia/src/TaggedCover.jl",
    "julia/src/JournalCompressionInstance.jl",
    "julia/src/ExactJournalCompression.jl",
    "julia/src/GreedyJournalCompression.jl",
    "julia/src/CertifiedDeletionJournalCompression.jl",
    "julia/src/JournalCompressionMIP.jl",
    "julia/src/FinancialAlgorithmComparison.jl",
    "julia/src/FinancialStrategyLibraryPanelV1.jl",
    "julia/src/StrategyInnovation.jl",
    "julia/scripts/run_financial_strategy_library_panel_v1.jl",
    "julia/scripts/create_financial_strategy_library_panel_v1_registries.jl",
    "julia/scripts/audit_financial_strategy_library_panel_v1.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_004.jl",
    "julia/test/test_tagged_cover_preprocessing.jl",
    "julia/test/test_exact_journal_compression.jl",
    "julia/test/test_greedy_journal_compression.jl",
    "julia/test/test_certified_deletion_journal_compression.jl",
    "julia/test/test_journal_compression_mip.jl",
    "julia/test/run_aor_algorithm_tests.jl",
    "julia/test/test_financial_strategy_library_panel_v1_execution.jl",
    "julia/test/run_financial_strategy_library_panel_v1_execution_tests.jl",
    "julia/test/test_financial_strategy_library_panel_v1_registration.jl",
    "julia/test/run_financial_strategy_library_panel_v1_registration_tests.jl",
    "julia/Project.toml",
    "julia/Manifest.toml",
    "Makefile",
    "REPRODUCIBILITY.md",
    "scripts/aor_check.sh",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text) = bytes2hex(sha256(codeunits(text)))

function _hashes()
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) || error(
            "missing Lock 004 input: $relative",
        )
    end
    return Dict(
        relative => _sha256_file(joinpath(REPOSITORY_ROOT, relative)) for
        relative in REQUIRED_FILES
    )
end

function _aggregate(hashes)
    return _sha256_text(join(
        ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
    ))
end

function _verify_historical_locks()
    isfile(DESIGN_LOCK_PATH) || error("design lock is absent")
    design_text = read(DESIGN_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$DESIGN_AGGREGATE\"", design_text) ||
        error("historical design-lock aggregate differs")
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 003 is absent")
    predecessor_text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", predecessor_text) ||
        error("historical Lock 003 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 ||
        error("historical Lock 003 file hash differs")
    return nothing
end

function validate_execution_design_004()
    _verify_historical_locks()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v4" ||
        error("unexpected Amendment 004 schema")
    amendment["amendment_id"] == "AMENDMENT_004" ||
        error("unexpected Amendment 004 identifier")
    amendment["valid_terminal_instance_results_before_amendment"] == 0 ||
        error("Amendment 004 valid-result disclosure changed")
    amendment["preparation_failure_terminal_results_before_amendment"] == 6 ||
        error("Amendment 004 failure-result disclosure changed")
    amendment["registered_seed_may_have_been_consumed_in_memory_before_amendment"] === true ||
        error("Amendment 004 must disclose possible in-memory seed consumption")
    for key in (
        "algorithm_or_solver_outcome_persisted_before_amendment",
        "algorithm_or_solver_outcome_inspected_before_amendment",
        "selected_library_or_burden_saving_inspected_before_amendment",
        "postdecision_outcome_observed_before_amendment",
        "raw_licensed_rows_printed_or_committed",
        "scientific_estimands_changed",
        "origin_registry_changed",
        "library_registry_changed",
        "burden_schedule_registry_changed",
        "seed_registry_changed",
        "algorithm_registry_changed",
        "source_instance_changed",
    )
        amendment[key] === false || error("Amendment 004 declaration changed: $key")
    end
    amendment["threading"]["julia_threads"] == 8 || error("thread count changed")
    amendment["threading"]["maximum_simultaneous_heavy_stages"] == 2 ||
        error("heavy-stage concurrency changed")
    return TOML.parsefile(CONFIG_PATH)
end

function _relative_files(root)
    isdir(root) || return String[]
    result = String[]
    for (directory, _, files) in walkdir(root), file in files
        push!(result, relpath(joinpath(directory, file), root))
    end
    return sort!(result)
end

function _assert_prelock_state(config)
    paths = config["paths"]
    local_data = joinpath(REPOSITORY_ROOT, String(paths["local_data_root"]))
    local_results = joinpath(REPOSITORY_ROOT, String(paths["local_results_root"]))
    public_results = joinpath(REPOSITORY_ROOT, String(paths["public_results_root"]))
    data_files = _relative_files(local_data)
    result_files = _relative_files(local_results)
    count(path -> startswith(path, "origin_builds/"), data_files) == 12 ||
        error("Lock 004 requires 12 origin metadata records")
    count(path -> startswith(path, "origin_failures/"), data_files) == 8 ||
        error("Lock 004 requires 8 terminal origin-failure records")
    length(data_files) == 20 || error("unexpected local-data artifacts predate Lock 004")
    count(path -> startswith(path, "instances/"), result_files) == 108 ||
        error("Lock 004 requires 108 serialized instances")
    count(path -> startswith(path, "preparation_failures/"), result_files) == 72 ||
        error("Lock 004 requires 72 preparation-failure slots")
    structural = filter(path -> startswith(path, "structural/"), result_files)
    length(structural) == 6 || error("Lock 004 requires the disclosed 6 structural records")
    for relative in structural
        payload = TOML.parsefile(joinpath(local_results, relative))
        payload["schema_version"] ==
        "financial-strategy-library-panel-preparation-failure-result-v1" ||
            error("a valid-instance outcome predates Lock 004: $relative")
    end
    any(path -> startswith(path, "checkpoints/"), result_files) &&
        error("algorithm checkpoints predate Lock 004")
    any(path -> startswith(path, "solver_logs/"), result_files) &&
        error("solver logs predate Lock 004")
    any(path -> startswith(path, "postdecision/"), result_files) &&
        error("postdecision results predate Lock 004")
    count(==("ENVIRONMENT.toml"), result_files) == 1 || error("environment record absent")
    count(==("PREPARATION_MANIFEST.toml"), result_files) == 1 ||
        error("preparation manifest absent")
    length(result_files) == 188 || error("unexpected local-result artifacts predate Lock 004")
    isempty(_relative_files(public_results)) || error("public results predate Lock 004")
    return nothing
end

function _render_lock(hashes)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v4",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_004",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$PREDECESSOR_FILE_SHA256",
  "licensed_rows_read_before_successor_lock": true,
  "registered_seed_may_have_been_consumed_in_memory": true,
  "valid_terminal_instance_results_before_successor_lock": 0,
  "preparation_failure_terminal_results_before_successor_lock": 6,
  "algorithm_or_solver_outcome_inspected_before_successor_lock": false,
  "postdecision_outcome_observed_before_successor_lock": false,
  "raw_licensed_rows_printed_or_committed": false,
  "registered_compression_slots": 180,
  "registered_algorithm_terminal_rows": 1260,
  "julia_threads": 8,
  "maximum_simultaneous_heavy_stages": 2,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    validate_execution_design_004()
    occursin("\"schema_version\": \"financial-strategy-library-panel-execution-lock-v4\"", text) ||
        error("unexpected or missing Lock 004 schema")
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("Lock 004 predecessor aggregate differs")
    for declaration in (
        "algorithm_or_solver_outcome_inspected_before_successor_lock",
        "postdecision_outcome_observed_before_successor_lock",
        "raw_licensed_rows_printed_or_committed",
    )
        occursin("\"$declaration\": false", text) ||
            error("invalid Lock 004 declaration: $declaration")
    end
    for path in keys(hashes)
        occursin("\"$path\": \"$(hashes[path])\"", text) ||
            error("Lock 004 mismatch: $path")
    end
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("Lock 004 aggregate mismatch")
    return aggregate
end

function dry_run()
    config = validate_execution_design_004()
    _assert_prelock_state(config)
    hashes = _hashes()
    return verify_lock_text(_render_lock(hashes), hashes)
end

function create_execution_lock_004()
    isfile(LOCK_PATH) && error("Execution Lock 004 already exists; it is immutable")
    config = validate_execution_design_004()
    _assert_prelock_state(config)
    hashes = _hashes()
    text = _render_lock(hashes)
    verify_lock_text(text, hashes)
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, LOCK_PATH; force = false)
    return _aggregate(hashes)
end

function verify_execution_lock_004()
    isfile(LOCK_PATH) || error("Execution Lock 004 is absent")
    return verify_lock_text(read(LOCK_PATH, String))
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v1_execution_004.jl --dry-run|--lock|--check",
    )
    mode = only(args)
    mode == "--dry-run" && return println("Lock 004 dry run passed: ", dry_run())
    mode == "--lock" && return println("Lock 004 created: ", create_execution_lock_004())
    mode == "--check" && return println("Lock 004 valid: ", verify_execution_lock_004())
    error("unknown mode: $mode")
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution004.main()
end
