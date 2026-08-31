module LockFinancialStrategyLibraryPanelV1Execution011

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_010.jl"))
const Lock010 = LockFinancialStrategyLibraryPanelV1Execution010

export create_execution_lock_011,
       dry_run,
       main,
       validate_execution_design_011,
       verify_execution_lock_011,
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
    "EXECUTION_AMENDMENT_011.toml",
)
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_010.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_011.json")
const DESIGN_AGGREGATE =
    "a549856760f40b28a02571d04869e522ff421390b362147aa1349c52d4e70cba"
const PREDECESSOR_AGGREGATE =
    "a5a1b53a16f5a238c92b1db04b6d073ee8057f12403c4e5a1b00f19fa59586ae"
const PREDECESSOR_FILE_SHA256 =
    "60f2703825e62111168c7c91ea149e2ff00389b337f0f7cac80f57076e2f12eb"
const STRUCTURAL_RESULT_AGGREGATE =
    "9564a4c9b0ea28f4cf4a9705e8e489398555032e466ba3fac8c16a98094a012a"

const REQUIRED_FILES = (
    Lock010.REQUIRED_FILES...,
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_010.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_011.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_011.toml",
    "julia/src/FinancialPanelParquet.jl",
    "julia/scripts/analyze_financial_strategy_library_panel_v1.jl",
    "julia/scripts/audit_financial_strategy_library_panel_v1_analysis.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_011.jl",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text) = bytes2hex(sha256(codeunits(text)))

function _hashes()
    length(REQUIRED_FILES) == length(unique(REQUIRED_FILES)) ||
        error("Lock 011 input list contains duplicates")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) || error(
            "missing Lock 011 input: $relative",
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

function _verify_predecessor()
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 010 is absent")
    predecessor_text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", predecessor_text) ||
        error("historical Lock 010 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 ||
        error("historical Lock 010 file hash differs")
    return nothing
end

function validate_execution_design_011()
    _verify_predecessor()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v11" ||
        error("unexpected Amendment 011 schema")
    amendment["amendment_id"] == "AMENDMENT_011" ||
        error("unexpected Amendment 011 identifier")
    amendment["predecessor_amendment_id"] == "AMENDMENT_010" ||
        error("unexpected Amendment 011 predecessor")
    for (key, expected) in (
        "structural_terminal_results_before_amendment" => 180,
        "valid_terminal_instance_results_before_amendment" => 108,
        "preparation_failure_terminal_results_before_amendment" => 72,
        "algorithm_checkpoints_before_amendment" => 756,
        "solver_logs_before_amendment" => 14,
        "structural_audit_files_before_amendment" => 1,
        "postdecision_results_before_amendment" => 0,
        "final_result_audit_files_before_amendment" => 0,
        "analysis_artifacts_before_amendment" => 0,
    )
        amendment[key] == expected || error("Amendment 011 disclosure changed: $key")
    end
    amendment["structural_audit_passed_before_amendment"] === true ||
        error("Amendment 011 no longer records the passing structural audit")
    amendment["structural_result_aggregate_sha256"] == STRUCTURAL_RESULT_AGGREGATE ||
        error("Amendment 011 structural aggregate changed")
    for key in (
        "selected_library_or_burden_saving_inspected_before_amendment",
        "solver_status_inspected_before_amendment",
        "postdecision_outcome_observed_before_amendment",
        "raw_licensed_rows_printed_or_committed",
        "scientific_estimands_changed",
        "origin_registry_changed",
        "library_registry_changed",
        "burden_schedule_registry_changed",
        "seed_registry_changed",
        "algorithm_registry_changed",
        "source_instance_changed",
        "audit_predicates_changed",
    )
        amendment[key] === false || error("Amendment 011 declaration changed: $key")
    end
    amendment["parquet"]["compression"] == "SNAPPY" ||
        error("Parquet compression changed")
    amendment["parquet"]["registered_source_file_partitions"] == 3 ||
        error("source partition count changed")
    amendment["analysis"]["worker_count"] == 8 ||
        error("analysis worker count changed")
    amendment["analysis"]["combined_algorithm_rows"] == 1260 ||
        error("analysis row denominator changed")
    amendment["analysis"]["instance_row_count"] == 180 ||
        error("instance-analysis row denominator changed")
    amendment["analysis"]["exact_method_agreement_row_count"] == 180 ||
        error("exact-method agreement denominator changed")
    amendment["analysis"]["normalized_output_tables"] == [
        "algorithm_rows",
        "instance_rows",
        "structural_summary",
        "identity_overlap",
        "exact_method_agreement",
        "carrier_multiplicity",
    ] || error("normalized analysis outputs changed")
    amendment["analysis"]["registered_table_count"] == 7 ||
        error("registered analysis table count changed")
    amendment["analysis"]["registered_figure_count"] == 5 ||
        error("registered analysis figure count changed")
    amendment["analysis"]["duplicate_raster_figures"] === false ||
        error("storage-efficient figure policy changed")
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
        error("Lock 011 requires 12 origin metadata records")
    count(path -> startswith(path, "origin_failures/"), data_files) == 8 ||
        error("Lock 011 requires 8 origin failure records")
    any(path -> occursin("parquet", lowercase(path)), data_files) &&
        error("Parquet source cache predates Lock 011")
    count(path -> startswith(path, "instances/"), result_files) == 108 ||
        error("Lock 011 requires 108 serialized instances")
    count(path -> startswith(path, "preparation_failures/"), result_files) == 72 ||
        error("Lock 011 requires 72 preparation-failure slots")
    count(path -> startswith(path, "structural/"), result_files) == 180 ||
        error("Lock 011 requires 180 structural records")
    count(path -> startswith(path, "checkpoints/") && endswith(path, ".toml"), result_files) == 756 ||
        error("Lock 011 requires 756 algorithm checkpoints")
    count(path -> startswith(path, "solver_logs/"), result_files) == 14 ||
        error("Lock 011 requires the disclosed 14 solver logs")
    any(path -> startswith(path, "postdecision/"), result_files) &&
        error("postdecision results predate Lock 011")
    any(path -> startswith(path, "analysis/"), result_files) &&
        error("analysis artifacts predate Lock 011")
    "RESULT_AUDIT.toml" in result_files && error("final result audit predates Lock 011")
    structural_audit_path = joinpath(local_results, "STRUCTURAL_AUDIT.toml")
    isfile(structural_audit_path) || error("passing Lock 010 structural audit is absent")
    structural_audit = TOML.parsefile(structural_audit_path)
    get(structural_audit, "passed", false) === true ||
        error("Lock 010 structural audit did not pass")
    get(structural_audit, "structural_result_aggregate_sha256", "") ==
    STRUCTURAL_RESULT_AGGREGATE || error("Lock 010 structural aggregate differs")
    environment = TOML.parsefile(joinpath(local_results, "ENVIRONMENT.toml"))
    get(environment, "execution_lock_aggregate_sha256", "") == PREDECESSOR_AGGREGATE ||
        error("environment does not belong to Lock 010")
    isempty(_relative_files(public_results)) || error("public results predate Lock 011")
    return nothing
end

function _render_lock(hashes)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v11",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_011",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$PREDECESSOR_FILE_SHA256",
  "licensed_rows_read_before_successor_lock": true,
  "structural_terminal_results_before_successor_lock": 180,
  "structural_audit_files_before_successor_lock": 1,
  "structural_audit_passed_before_successor_lock": true,
  "structural_result_aggregate_sha256": "$STRUCTURAL_RESULT_AGGREGATE",
  "postdecision_results_before_successor_lock": 0,
  "final_result_audit_files_before_successor_lock": 0,
  "analysis_artifacts_before_successor_lock": 0,
  "postdecision_outcome_observed_before_successor_lock": false,
  "raw_licensed_rows_printed_or_committed": false,
  "scientific_estimands_changed": false,
  "parquet_compression": "SNAPPY",
  "analysis_thread_count": 8,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    validate_execution_design_011()
    occursin("\"schema_version\": \"financial-strategy-library-panel-execution-lock-v11\"", text) ||
        error("unexpected or missing Lock 011 schema")
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("Lock 011 predecessor aggregate differs")
    for declaration in (
        "postdecision_outcome_observed_before_successor_lock",
        "raw_licensed_rows_printed_or_committed",
        "scientific_estimands_changed",
    )
        occursin("\"$declaration\": false", text) ||
            error("invalid Lock 011 declaration: $declaration")
    end
    for path in keys(hashes)
        occursin("\"$path\": \"$(hashes[path])\"", text) ||
            error("Lock 011 mismatch: $path")
    end
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("Lock 011 aggregate mismatch")
    return aggregate
end

function dry_run()
    config = validate_execution_design_011()
    _assert_prelock_state(config)
    hashes = _hashes()
    return verify_lock_text(_render_lock(hashes), hashes)
end

function create_execution_lock_011()
    isfile(LOCK_PATH) && error("Execution Lock 011 already exists; it is immutable")
    config = validate_execution_design_011()
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

function verify_execution_lock_011()
    isfile(LOCK_PATH) || error("Execution Lock 011 is absent")
    return verify_lock_text(read(LOCK_PATH, String))
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v1_execution_011.jl --dry-run|--lock|--check",
    )
    mode = only(args)
    mode == "--dry-run" && return println("Lock 011 dry run passed: ", dry_run())
    mode == "--lock" && return println("Lock 011 created: ", create_execution_lock_011())
    mode == "--check" && return println("Lock 011 valid: ", verify_execution_lock_011())
    error("unknown mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution011.main()
end
