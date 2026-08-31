module LockFinancialStrategyLibraryPanelV1Execution009

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_008.jl"))
const Lock008 = LockFinancialStrategyLibraryPanelV1Execution008

export create_execution_lock_009,
       dry_run,
       main,
       validate_execution_design_009,
       verify_execution_lock_009,
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
    "EXECUTION_AMENDMENT_009.toml",
)
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_008.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_009.json")
const DESIGN_AGGREGATE =
    "a549856760f40b28a02571d04869e522ff421390b362147aa1349c52d4e70cba"
const PREDECESSOR_AGGREGATE =
    "8aafbf9d9a0dc6a9c5914d98ddaf24ff9b2088eabc75ab5c29fae5b6eb07a9ef"
const PREDECESSOR_FILE_SHA256 =
    "e3c968b220bf678001e7d1023c9b635ca6e51867d8e47d09f4588226dfdaf186"

const REQUIRED_FILES = (
    Lock008.REQUIRED_FILES...,
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_008.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_009.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_009.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_009.jl",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text) = bytes2hex(sha256(codeunits(text)))

function _hashes()
    length(REQUIRED_FILES) == length(unique(REQUIRED_FILES)) ||
        error("Lock 009 input list contains duplicates")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) || error(
            "missing Lock 009 input: $relative",
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
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 008 is absent")
    predecessor_text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", predecessor_text) ||
        error("historical Lock 008 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 ||
        error("historical Lock 008 file hash differs")
    return nothing
end

function validate_execution_design_009()
    _verify_predecessor()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v9" ||
        error("unexpected Amendment 009 schema")
    amendment["amendment_id"] == "AMENDMENT_009" ||
        error("unexpected Amendment 009 identifier")
    amendment["predecessor_amendment_id"] == "AMENDMENT_008" ||
        error("unexpected Amendment 009 predecessor")
    for (key, expected) in (
        "structural_terminal_results_before_amendment" => 180,
        "valid_terminal_instance_results_before_amendment" => 108,
        "preparation_failure_terminal_results_before_amendment" => 72,
        "algorithm_checkpoints_before_amendment" => 756,
        "solver_logs_before_amendment" => 14,
        "structural_audit_files_before_amendment" => 0,
        "postdecision_results_before_amendment" => 0,
    )
        amendment[key] == expected || error("Amendment 009 disclosure changed: $key")
    end
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
        amendment[key] === false || error("Amendment 009 declaration changed: $key")
    end
    amendment["audit_parallelism"]["julia_threads"] == 8 ||
        error("parallel audit Julia thread count changed")
    amendment["audit_parallelism"]["worker_count"] == 8 ||
        error("parallel audit worker count changed")
    amendment["audit_parallelism"]["postdecision_worker_count"] == 8 ||
        error("postdecision audit worker count changed")
    amendment["audit_parallelism"]["aggregation_order"] ==
    "lexicographic registered-key order" || error("parallel audit aggregation order changed")
    amendment["audit_parallelism"]["thread_scheduling_affects_certificate"] === false ||
        error("parallel audit allows scheduling to affect its certificate")
    amendment["audit_instance_hash"]["deserialization_validation_retained"] === true ||
        error("parallel audit removed instance deserialization validation")
    amendment["progress"]["financial_outcomes_included"] === false ||
        error("parallel audit progress exposes financial outcomes")
    amendment["progress"]["algorithm_outcomes_included"] === false ||
        error("parallel audit progress exposes algorithm outcomes")
    String.(amendment["progress"]["stages"]) ==
    ["structural-audit", "postdecision-audit"] || error("audit progress stages changed")
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
        error("Lock 009 requires 12 origin metadata records")
    count(path -> startswith(path, "origin_failures/"), data_files) == 8 ||
        error("Lock 009 requires 8 origin failure records")
    length(data_files) == 20 || error("unexpected local-data artifacts predate Lock 009")
    count(path -> startswith(path, "instances/"), result_files) == 108 ||
        error("Lock 009 requires 108 serialized instances")
    count(path -> startswith(path, "preparation_failures/"), result_files) == 72 ||
        error("Lock 009 requires 72 preparation-failure slots")
    structural = filter(path -> startswith(path, "structural/"), result_files)
    length(structural) == 180 || error("Lock 009 requires 180 structural records")
    valid_count = 0
    preparation_failure_count = 0
    for relative in structural
        payload = TOML.parsefile(joinpath(local_results, relative))
        get(payload, "terminal", false) === true ||
            error("a nonterminal structural record predates Lock 009: $relative")
        schema = get(payload, "schema_version", "")
        schema == "financial-strategy-library-panel-instance-result-v1" && (valid_count += 1)
        schema == "financial-strategy-library-panel-preparation-failure-result-v1" &&
            (preparation_failure_count += 1)
    end
    valid_count == 108 || error("Lock 009 valid structural count differs")
    preparation_failure_count == 72 || error("Lock 009 preparation-failure count differs")
    count(path -> startswith(path, "checkpoints/") && endswith(path, ".toml"), result_files) == 756 ||
        error("Lock 009 requires 756 algorithm checkpoints")
    count(path -> startswith(path, "solver_logs/"), result_files) == 14 ||
        error("Lock 009 requires the disclosed 14 solver logs")
    any(path -> startswith(path, "postdecision/"), result_files) &&
        error("postdecision results predate Lock 009")
    "STRUCTURAL_AUDIT.toml" in result_files && error("structural audit predates Lock 009")
    "RESULT_AUDIT.toml" in result_files && error("final audit predates Lock 009")
    environment = TOML.parsefile(joinpath(local_results, "ENVIRONMENT.toml"))
    get(environment, "execution_lock_aggregate_sha256", "") == PREDECESSOR_AGGREGATE ||
        error("environment does not belong to Lock 008")
    isempty(_relative_files(public_results)) || error("public results predate Lock 009")
    return nothing
end

function _render_lock(hashes)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v9",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_009",
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
  "audit_thread_count": 8,
  "audit_worker_count": 8,
  "audit_aggregation_order": "lexicographic registered-key order",
  "audit_predicates_changed": false,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    validate_execution_design_009()
    occursin("\"schema_version\": \"financial-strategy-library-panel-execution-lock-v9\"", text) ||
        error("unexpected or missing Lock 009 schema")
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("Lock 009 predecessor aggregate differs")
    for declaration in (
        "selected_library_or_burden_saving_inspected_before_successor_lock",
        "solver_status_inspected_before_successor_lock",
        "postdecision_outcome_observed_before_successor_lock",
        "raw_licensed_rows_printed_or_committed",
        "audit_predicates_changed",
    )
        occursin("\"$declaration\": false", text) ||
            error("invalid Lock 009 declaration: $declaration")
    end
    for path in keys(hashes)
        occursin("\"$path\": \"$(hashes[path])\"", text) ||
            error("Lock 009 mismatch: $path")
    end
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("Lock 009 aggregate mismatch")
    return aggregate
end

function dry_run()
    config = validate_execution_design_009()
    _assert_prelock_state(config)
    hashes = _hashes()
    return verify_lock_text(_render_lock(hashes), hashes)
end

function create_execution_lock_009()
    isfile(LOCK_PATH) && error("Execution Lock 009 already exists; it is immutable")
    config = validate_execution_design_009()
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

function verify_execution_lock_009()
    isfile(LOCK_PATH) || error("Execution Lock 009 is absent")
    return verify_lock_text(read(LOCK_PATH, String))
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v1_execution_009.jl --dry-run|--lock|--check",
    )
    mode = only(args)
    mode == "--dry-run" && return println("Lock 009 dry run passed: ", dry_run())
    mode == "--lock" && return println("Lock 009 created: ", create_execution_lock_009())
    mode == "--check" && return println("Lock 009 valid: ", verify_execution_lock_009())
    error("unknown mode: $mode")
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution009.main()
end
