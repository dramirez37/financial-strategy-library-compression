module LockFinancialStrategyLibraryPanelV1Execution010

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_009.jl"))
const Lock009 = LockFinancialStrategyLibraryPanelV1Execution009

export create_execution_lock_010,
       dry_run,
       main,
       validate_execution_design_010,
       verify_execution_lock_010,
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
    "EXECUTION_AMENDMENT_010.toml",
)
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_009.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_010.json")
const DESIGN_AGGREGATE =
    "a549856760f40b28a02571d04869e522ff421390b362147aa1349c52d4e70cba"
const PREDECESSOR_AGGREGATE =
    "1df3b73878a7856d530aa6e7744591ba591c9fae1e1424ef324acb9ff4fee309"
const PREDECESSOR_FILE_SHA256 =
    "9bcb68b9f1c715277cd703ea6ac5b2bd7e040762baedbeb29108da4124e4573a"
const STRUCTURAL_RESULT_AGGREGATE =
    "9564a4c9b0ea28f4cf4a9705e8e489398555032e466ba3fac8c16a98094a012a"

const REQUIRED_FILES = (
    Lock009.REQUIRED_FILES...,
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_009.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_010.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_010.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_010.jl",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text) = bytes2hex(sha256(codeunits(text)))

function _hashes()
    length(REQUIRED_FILES) == length(unique(REQUIRED_FILES)) ||
        error("Lock 010 input list contains duplicates")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) || error(
            "missing Lock 010 input: $relative",
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
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 009 is absent")
    predecessor_text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", predecessor_text) ||
        error("historical Lock 009 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 ||
        error("historical Lock 009 file hash differs")
    return nothing
end

function validate_execution_design_010()
    _verify_predecessor()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v10" ||
        error("unexpected Amendment 010 schema")
    amendment["amendment_id"] == "AMENDMENT_010" ||
        error("unexpected Amendment 010 identifier")
    amendment["predecessor_amendment_id"] == "AMENDMENT_009" ||
        error("unexpected Amendment 010 predecessor")
    for (key, expected) in (
        "structural_terminal_results_before_amendment" => 180,
        "valid_terminal_instance_results_before_amendment" => 108,
        "preparation_failure_terminal_results_before_amendment" => 72,
        "algorithm_checkpoints_before_amendment" => 756,
        "solver_logs_before_amendment" => 14,
        "structural_audit_files_before_amendment" => 1,
        "postdecision_results_before_amendment" => 0,
    )
        amendment[key] == expected || error("Amendment 010 disclosure changed: $key")
    end
    amendment["structural_audit_passed_before_amendment"] === true ||
        error("Amendment 010 no longer records the passing predecessor audit")
    amendment["structural_result_aggregate_sha256"] == STRUCTURAL_RESULT_AGGREGATE ||
        error("Amendment 010 structural aggregate changed")
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
        amendment[key] === false || error("Amendment 010 declaration changed: $key")
    end
    amendment["progress"]["counter_increment_inside_output_lock"] === true ||
        error("progress counter is no longer serialized with output")
    amendment["progress"]["render_inside_output_lock"] === true ||
        error("progress rendering is no longer protected")
    amendment["progress"]["result_computation_inside_output_lock"] === false ||
        error("audit result computation was serialized")
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
        error("Lock 010 requires 12 origin metadata records")
    count(path -> startswith(path, "origin_failures/"), data_files) == 8 ||
        error("Lock 010 requires 8 origin failure records")
    length(data_files) == 20 || error("unexpected local-data artifacts predate Lock 010")
    count(path -> startswith(path, "instances/"), result_files) == 108 ||
        error("Lock 010 requires 108 serialized instances")
    count(path -> startswith(path, "preparation_failures/"), result_files) == 72 ||
        error("Lock 010 requires 72 preparation-failure slots")
    structural = filter(path -> startswith(path, "structural/"), result_files)
    length(structural) == 180 || error("Lock 010 requires 180 structural records")
    count(path -> startswith(path, "checkpoints/") && endswith(path, ".toml"), result_files) == 756 ||
        error("Lock 010 requires 756 algorithm checkpoints")
    count(path -> startswith(path, "solver_logs/"), result_files) == 14 ||
        error("Lock 010 requires the disclosed 14 solver logs")
    any(path -> startswith(path, "postdecision/"), result_files) &&
        error("postdecision results predate Lock 010")
    "RESULT_AUDIT.toml" in result_files && error("final audit predates Lock 010")
    structural_audit_path = joinpath(local_results, "STRUCTURAL_AUDIT.toml")
    isfile(structural_audit_path) || error("passing Lock 009 structural audit is absent")
    structural_audit = TOML.parsefile(structural_audit_path)
    get(structural_audit, "passed", false) === true ||
        error("Lock 009 structural audit did not pass")
    get(structural_audit, "structural_result_aggregate_sha256", "") ==
    STRUCTURAL_RESULT_AGGREGATE || error("Lock 009 structural audit aggregate differs")
    environment = TOML.parsefile(joinpath(local_results, "ENVIRONMENT.toml"))
    get(environment, "execution_lock_aggregate_sha256", "") == PREDECESSOR_AGGREGATE ||
        error("environment does not belong to Lock 009")
    isempty(_relative_files(public_results)) || error("public results predate Lock 010")
    return nothing
end

function _render_lock(hashes)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v10",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_010",
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
  "selected_library_or_burden_saving_inspected_before_successor_lock": false,
  "solver_status_inspected_before_successor_lock": false,
  "postdecision_outcome_observed_before_successor_lock": false,
  "raw_licensed_rows_printed_or_committed": false,
  "audit_predicates_changed": false,
  "progress_sequence": "0:registered_slot_count",
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    validate_execution_design_010()
    occursin("\"schema_version\": \"financial-strategy-library-panel-execution-lock-v10\"", text) ||
        error("unexpected or missing Lock 010 schema")
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("Lock 010 predecessor aggregate differs")
    for declaration in (
        "selected_library_or_burden_saving_inspected_before_successor_lock",
        "solver_status_inspected_before_successor_lock",
        "postdecision_outcome_observed_before_successor_lock",
        "raw_licensed_rows_printed_or_committed",
        "audit_predicates_changed",
    )
        occursin("\"$declaration\": false", text) ||
            error("invalid Lock 010 declaration: $declaration")
    end
    for path in keys(hashes)
        occursin("\"$path\": \"$(hashes[path])\"", text) ||
            error("Lock 010 mismatch: $path")
    end
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("Lock 010 aggregate mismatch")
    return aggregate
end

function dry_run()
    config = validate_execution_design_010()
    _assert_prelock_state(config)
    hashes = _hashes()
    return verify_lock_text(_render_lock(hashes), hashes)
end

function create_execution_lock_010()
    isfile(LOCK_PATH) && error("Execution Lock 010 already exists; it is immutable")
    config = validate_execution_design_010()
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

function verify_execution_lock_010()
    isfile(LOCK_PATH) || error("Execution Lock 010 is absent")
    return verify_lock_text(read(LOCK_PATH, String))
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v1_execution_010.jl --dry-run|--lock|--check",
    )
    mode = only(args)
    mode == "--dry-run" && return println("Lock 010 dry run passed: ", dry_run())
    mode == "--lock" && return println("Lock 010 created: ", create_execution_lock_010())
    mode == "--check" && return println("Lock 010 valid: ", verify_execution_lock_010())
    error("unknown mode: $mode")
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution010.main()
end
