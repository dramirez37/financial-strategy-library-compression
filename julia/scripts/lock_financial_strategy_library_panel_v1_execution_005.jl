module LockFinancialStrategyLibraryPanelV1Execution005

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_004.jl"))
const Lock004 = LockFinancialStrategyLibraryPanelV1Execution004

export create_execution_lock_005,
       dry_run,
       main,
       validate_execution_design_005,
       verify_execution_lock_005,
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
    "EXECUTION_AMENDMENT_005.toml",
)
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_004.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_005.json")
const DESIGN_AGGREGATE =
    "a549856760f40b28a02571d04869e522ff421390b362147aa1349c52d4e70cba"
const PREDECESSOR_AGGREGATE =
    "823a725a778ab3476faad2a81cf78ae96b4be1bc2549376eb25a82f9632431a9"
const PREDECESSOR_FILE_SHA256 =
    "8cb79f0a66384fb9890e29b2f0298bc7e73d68bfeb5503b3f9fd899c166f5695"

const REQUIRED_FILES = (
    Lock004.REQUIRED_FILES...,
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_004.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_005.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_005.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_005.jl",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text) = bytes2hex(sha256(codeunits(text)))

function _hashes()
    length(REQUIRED_FILES) == length(unique(REQUIRED_FILES)) ||
        error("Lock 005 input list contains duplicates")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) || error(
            "missing Lock 005 input: $relative",
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
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 004 is absent")
    predecessor_text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", predecessor_text) ||
        error("historical Lock 004 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 ||
        error("historical Lock 004 file hash differs")
    return nothing
end

function validate_execution_design_005()
    _verify_predecessor()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v5" ||
        error("unexpected Amendment 005 schema")
    amendment["amendment_id"] == "AMENDMENT_005" ||
        error("unexpected Amendment 005 identifier")
    amendment["predecessor_amendment_id"] == "AMENDMENT_004" ||
        error("unexpected Amendment 005 predecessor")
    amendment["valid_terminal_instance_results_before_amendment"] == 0 ||
        error("Amendment 005 valid-result disclosure changed")
    amendment["preparation_failure_terminal_results_before_amendment"] == 6 ||
        error("Amendment 005 failure-result disclosure changed")
    amendment["solver_logs_before_amendment"] == 0 ||
        error("solver-log disclosure changed")
    amendment["algorithm_checkpoints_before_amendment"] == 0 ||
        error("checkpoint disclosure changed")
    amendment["postdecision_results_before_amendment"] == 0 ||
        error("postdecision disclosure changed")
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
        amendment[key] === false || error("Amendment 005 declaration changed: $key")
    end
    amendment["threading"]["julia_threads"] == 8 || error("thread count changed")
    amendment["threading"]["maximum_simultaneous_heavy_stages"] == 2 ||
        error("heavy-stage concurrency changed")
    amendment["preparation_resume"]["all_manifest_file_hashes_rechecked"] === true ||
        error("preparation hash validation changed")
    amendment["progress"]["ansi_cursor_control"] === false ||
        error("progress output is not durable")
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
        error("Lock 005 requires 12 origin metadata records")
    count(path -> startswith(path, "origin_failures/"), data_files) == 8 ||
        error("Lock 005 requires 8 origin failure records")
    length(data_files) == 20 || error("unexpected local-data artifacts predate Lock 005")
    count(path -> startswith(path, "instances/"), result_files) == 108 ||
        error("Lock 005 requires 108 serialized instances")
    count(path -> startswith(path, "preparation_failures/"), result_files) == 72 ||
        error("Lock 005 requires 72 preparation-failure slots")
    structural = filter(path -> startswith(path, "structural/"), result_files)
    length(structural) == 6 || error("Lock 005 requires the disclosed 6 structural records")
    for relative in structural
        payload = TOML.parsefile(joinpath(local_results, relative))
        payload["schema_version"] ==
        "financial-strategy-library-panel-preparation-failure-result-v1" ||
            error("a valid-instance outcome predates Lock 005: $relative")
    end
    any(path -> startswith(path, "checkpoints/"), result_files) &&
        error("algorithm checkpoints predate Lock 005")
    any(path -> startswith(path, "solver_logs/"), result_files) &&
        error("solver logs predate Lock 005")
    any(path -> startswith(path, "postdecision/"), result_files) &&
        error("postdecision results predate Lock 005")
    count(==("ENVIRONMENT.toml"), result_files) == 1 || error("environment record absent")
    count(==("PREPARATION_MANIFEST.toml"), result_files) == 1 ||
        error("preparation manifest absent")
    length(result_files) == 188 || error("unexpected local-result artifacts predate Lock 005")
    isempty(_relative_files(public_results)) || error("public results predate Lock 005")
    return nothing
end

function _render_lock(hashes)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v5",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_005",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$PREDECESSOR_FILE_SHA256",
  "licensed_rows_read_before_successor_lock": true,
  "valid_terminal_instance_results_before_successor_lock": 0,
  "preparation_failure_terminal_results_before_successor_lock": 6,
  "algorithm_or_solver_outcome_inspected_before_successor_lock": false,
  "postdecision_outcome_observed_before_successor_lock": false,
  "raw_licensed_rows_printed_or_committed": false,
  "registered_compression_slots": 180,
  "registered_algorithm_terminal_rows": 1260,
  "julia_threads": 8,
  "maximum_simultaneous_heavy_stages": 2,
  "durable_newline_progress": true,
  "validated_preparation_reuse": true,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    validate_execution_design_005()
    occursin("\"schema_version\": \"financial-strategy-library-panel-execution-lock-v5\"", text) ||
        error("unexpected or missing Lock 005 schema")
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("Lock 005 predecessor aggregate differs")
    for declaration in (
        "algorithm_or_solver_outcome_inspected_before_successor_lock",
        "postdecision_outcome_observed_before_successor_lock",
        "raw_licensed_rows_printed_or_committed",
    )
        occursin("\"$declaration\": false", text) ||
            error("invalid Lock 005 declaration: $declaration")
    end
    for path in keys(hashes)
        occursin("\"$path\": \"$(hashes[path])\"", text) ||
            error("Lock 005 mismatch: $path")
    end
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("Lock 005 aggregate mismatch")
    return aggregate
end

function dry_run()
    config = validate_execution_design_005()
    _assert_prelock_state(config)
    hashes = _hashes()
    return verify_lock_text(_render_lock(hashes), hashes)
end

function create_execution_lock_005()
    isfile(LOCK_PATH) && error("Execution Lock 005 already exists; it is immutable")
    config = validate_execution_design_005()
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

function verify_execution_lock_005()
    isfile(LOCK_PATH) || error("Execution Lock 005 is absent")
    return verify_lock_text(read(LOCK_PATH, String))
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v1_execution_005.jl --dry-run|--lock|--check",
    )
    mode = only(args)
    mode == "--dry-run" && return println("Lock 005 dry run passed: ", dry_run())
    mode == "--lock" && return println("Lock 005 created: ", create_execution_lock_005())
    mode == "--check" && return println("Lock 005 valid: ", verify_execution_lock_005())
    error("unknown mode: $mode")
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution005.main()
end
