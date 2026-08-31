module LockFinancialStrategyLibraryPanelV1Execution006

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_005.jl"))
const Lock005 = LockFinancialStrategyLibraryPanelV1Execution005

export create_execution_lock_006,
       dry_run,
       main,
       validate_execution_design_006,
       verify_execution_lock_006,
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
    "EXECUTION_AMENDMENT_006.toml",
)
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_005.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_006.json")
const DESIGN_AGGREGATE =
    "a549856760f40b28a02571d04869e522ff421390b362147aa1349c52d4e70cba"
const PREDECESSOR_AGGREGATE =
    "74f8e021f47b53ab4b23718224a8d9879bf95fb30b50f3f547b9841b8ce42d83"
const PREDECESSOR_FILE_SHA256 =
    "1297eb9f118e3136029373c0447b0d3c8798e458dc064d3a9a0ae9bfd5ce1151"

const REQUIRED_FILES = (
    Lock005.REQUIRED_FILES...,
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_005.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_006.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_006.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_006.jl",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text) = bytes2hex(sha256(codeunits(text)))

function _hashes()
    length(REQUIRED_FILES) == length(unique(REQUIRED_FILES)) ||
        error("Lock 006 input list contains duplicates")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) || error(
            "missing Lock 006 input: $relative",
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
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 005 is absent")
    predecessor_text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", predecessor_text) ||
        error("historical Lock 005 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 ||
        error("historical Lock 005 file hash differs")
    return nothing
end

function validate_execution_design_006()
    _verify_predecessor()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v6" ||
        error("unexpected Amendment 006 schema")
    amendment["amendment_id"] == "AMENDMENT_006" ||
        error("unexpected Amendment 006 identifier")
    amendment["predecessor_amendment_id"] == "AMENDMENT_005" ||
        error("unexpected Amendment 006 predecessor")
    amendment["structural_terminal_results_before_amendment"] == 180 ||
        error("Amendment 006 structural-result disclosure changed")
    amendment["valid_terminal_instance_results_before_amendment"] == 108 ||
        error("Amendment 006 valid-result disclosure changed")
    amendment["preparation_failure_terminal_results_before_amendment"] == 72 ||
        error("Amendment 006 preparation-failure disclosure changed")
    amendment["algorithm_checkpoints_before_amendment"] == 756 ||
        error("Amendment 006 checkpoint disclosure changed")
    amendment["solver_logs_before_amendment"] == 14 ||
        error("Amendment 006 solver-log disclosure changed")
    amendment["structural_audit_files_before_amendment"] == 0 ||
        error("a structural audit predates Amendment 006")
    amendment["postdecision_results_before_amendment"] == 0 ||
        error("postdecision results predate Amendment 006")
    amendment["algorithm_or_solver_outcomes_persisted_before_amendment"] === true ||
        error("Amendment 006 must disclose persisted structural outcomes")
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
    )
        amendment[key] === false || error("Amendment 006 declaration changed: $key")
    end
    amendment["dispatch"]["new_method_invocation"] == "Base.invokelatest" ||
        error("world-age-safe invocation changed")
    amendment["threading"]["julia_threads"] == 8 || error("thread count changed")
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
        error("Lock 006 requires 12 origin metadata records")
    count(path -> startswith(path, "origin_failures/"), data_files) == 8 ||
        error("Lock 006 requires 8 origin failure records")
    length(data_files) == 20 || error("unexpected local-data artifacts predate Lock 006")
    count(path -> startswith(path, "instances/"), result_files) == 108 ||
        error("Lock 006 requires 108 serialized instances")
    count(path -> startswith(path, "preparation_failures/"), result_files) == 72 ||
        error("Lock 006 requires 72 preparation-failure slots")
    structural = filter(path -> startswith(path, "structural/"), result_files)
    length(structural) == 180 || error("Lock 006 requires 180 structural records")
    valid_count = 0
    preparation_failure_count = 0
    for relative in structural
        payload = TOML.parsefile(joinpath(local_results, relative))
        get(payload, "terminal", false) === true ||
            error("a nonterminal structural record predates Lock 006: $relative")
        schema = get(payload, "schema_version", "")
        schema == "financial-strategy-library-panel-instance-result-v1" && (valid_count += 1)
        schema == "financial-strategy-library-panel-preparation-failure-result-v1" &&
            (preparation_failure_count += 1)
    end
    valid_count == 108 || error("Lock 006 valid structural count differs")
    preparation_failure_count == 72 || error("Lock 006 preparation-failure count differs")
    count(path -> startswith(path, "checkpoints/") && endswith(path, ".toml"), result_files) == 756 ||
        error("Lock 006 requires 756 algorithm checkpoints")
    count(path -> startswith(path, "solver_logs/"), result_files) == 14 ||
        error("Lock 006 requires the disclosed 14 solver logs")
    any(path -> startswith(path, "postdecision/"), result_files) &&
        error("postdecision results predate Lock 006")
    "STRUCTURAL_AUDIT.toml" in result_files && error("structural audit predates Lock 006")
    "RESULT_AUDIT.toml" in result_files && error("final audit predates Lock 006")
    environment = TOML.parsefile(joinpath(local_results, "ENVIRONMENT.toml"))
    get(environment, "execution_lock_aggregate_sha256", "") == PREDECESSOR_AGGREGATE ||
        error("environment does not belong to Lock 005")
    isempty(_relative_files(public_results)) || error("public results predate Lock 006")
    return nothing
end

function _render_lock(hashes)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v6",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_006",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$PREDECESSOR_FILE_SHA256",
  "licensed_rows_read_before_successor_lock": true,
  "structural_terminal_results_before_successor_lock": 180,
  "valid_terminal_instance_results_before_successor_lock": 108,
  "preparation_failure_terminal_results_before_successor_lock": 72,
  "algorithm_checkpoints_before_successor_lock": 756,
  "solver_logs_before_successor_lock": 14,
  "structural_audit_files_before_successor_lock": 0,
  "postdecision_results_before_successor_lock": 0,
  "selected_library_or_burden_saving_inspected_before_successor_lock": false,
  "solver_status_inspected_before_successor_lock": false,
  "postdecision_outcome_observed_before_successor_lock": false,
  "raw_licensed_rows_printed_or_committed": false,
  "julia_threads": 8,
  "world_age_safe_audit_dispatch": true,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    validate_execution_design_006()
    occursin("\"schema_version\": \"financial-strategy-library-panel-execution-lock-v6\"", text) ||
        error("unexpected or missing Lock 006 schema")
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("Lock 006 predecessor aggregate differs")
    for declaration in (
        "selected_library_or_burden_saving_inspected_before_successor_lock",
        "solver_status_inspected_before_successor_lock",
        "postdecision_outcome_observed_before_successor_lock",
        "raw_licensed_rows_printed_or_committed",
    )
        occursin("\"$declaration\": false", text) ||
            error("invalid Lock 006 declaration: $declaration")
    end
    for path in keys(hashes)
        occursin("\"$path\": \"$(hashes[path])\"", text) ||
            error("Lock 006 mismatch: $path")
    end
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("Lock 006 aggregate mismatch")
    return aggregate
end

function dry_run()
    config = validate_execution_design_006()
    _assert_prelock_state(config)
    hashes = _hashes()
    return verify_lock_text(_render_lock(hashes), hashes)
end

function create_execution_lock_006()
    isfile(LOCK_PATH) && error("Execution Lock 006 already exists; it is immutable")
    config = validate_execution_design_006()
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

function verify_execution_lock_006()
    isfile(LOCK_PATH) || error("Execution Lock 006 is absent")
    return verify_lock_text(read(LOCK_PATH, String))
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v1_execution_006.jl --dry-run|--lock|--check",
    )
    mode = only(args)
    mode == "--dry-run" && return println("Lock 006 dry run passed: ", dry_run())
    mode == "--lock" && return println("Lock 006 created: ", create_execution_lock_006())
    mode == "--check" && return println("Lock 006 valid: ", verify_execution_lock_006())
    error("unknown mode: $mode")
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution006.main()
end
