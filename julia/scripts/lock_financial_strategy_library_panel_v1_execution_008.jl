module LockFinancialStrategyLibraryPanelV1Execution008

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_007.jl"))
const Lock007 = LockFinancialStrategyLibraryPanelV1Execution007

export create_execution_lock_008,
       dry_run,
       main,
       validate_execution_design_008,
       verify_execution_lock_008,
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
    "EXECUTION_AMENDMENT_008.toml",
)
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_007.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_008.json")
const DESIGN_AGGREGATE =
    "a549856760f40b28a02571d04869e522ff421390b362147aa1349c52d4e70cba"
const PREDECESSOR_AGGREGATE =
    "38b159fedf921333a0f00e037c58845b415d2ec7cc4bdd99983115af0e69e055"
const PREDECESSOR_FILE_SHA256 =
    "bfcfe3fed5a775b3fcb976c6000d0c3eabe334b2ba002c80c1be1d4ae3146ece"

const REQUIRED_FILES = (
    Lock007.REQUIRED_FILES...,
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_007.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_008.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_008.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_008.jl",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text) = bytes2hex(sha256(codeunits(text)))

function _hashes()
    length(REQUIRED_FILES) == length(unique(REQUIRED_FILES)) ||
        error("Lock 008 input list contains duplicates")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) || error(
            "missing Lock 008 input: $relative",
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
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 007 is absent")
    predecessor_text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", predecessor_text) ||
        error("historical Lock 007 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 ||
        error("historical Lock 007 file hash differs")
    return nothing
end

function validate_execution_design_008()
    _verify_predecessor()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v8" ||
        error("unexpected Amendment 008 schema")
    amendment["amendment_id"] == "AMENDMENT_008" ||
        error("unexpected Amendment 008 identifier")
    amendment["predecessor_amendment_id"] == "AMENDMENT_007" ||
        error("unexpected Amendment 008 predecessor")
    for (key, expected) in (
        "structural_terminal_results_before_amendment" => 180,
        "valid_terminal_instance_results_before_amendment" => 108,
        "preparation_failure_terminal_results_before_amendment" => 72,
        "algorithm_checkpoints_before_amendment" => 756,
        "solver_logs_before_amendment" => 14,
        "structural_audit_files_before_amendment" => 0,
        "postdecision_results_before_amendment" => 0,
    )
        amendment[key] == expected || error("Amendment 008 disclosure changed: $key")
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
    )
        amendment[key] === false || error("Amendment 008 declaration changed: $key")
    end
    amendment["audit_collection"]["representation"] == "sorted Vector{String}" ||
        error("audit collection representation changed")
    amendment["audit_collection"]["filter"] == ".toml suffix" ||
        error("audit filename filter changed")
    amendment["audit_collection"]["registered_key_count"] == 180 ||
        error("registered audit key count changed")
    amendment["audit_collection"]["audit_predicates_changed"] === false ||
        error("audit predicates changed")
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
        error("Lock 008 requires 12 origin metadata records")
    count(path -> startswith(path, "origin_failures/"), data_files) == 8 ||
        error("Lock 008 requires 8 origin failure records")
    length(data_files) == 20 || error("unexpected local-data artifacts predate Lock 008")
    count(path -> startswith(path, "instances/"), result_files) == 108 ||
        error("Lock 008 requires 108 serialized instances")
    count(path -> startswith(path, "preparation_failures/"), result_files) == 72 ||
        error("Lock 008 requires 72 preparation-failure slots")
    structural = filter(path -> startswith(path, "structural/"), result_files)
    length(structural) == 180 || error("Lock 008 requires 180 structural records")
    valid_count = 0
    preparation_failure_count = 0
    for relative in structural
        payload = TOML.parsefile(joinpath(local_results, relative))
        get(payload, "terminal", false) === true ||
            error("a nonterminal structural record predates Lock 008: $relative")
        schema = get(payload, "schema_version", "")
        schema == "financial-strategy-library-panel-instance-result-v1" && (valid_count += 1)
        schema == "financial-strategy-library-panel-preparation-failure-result-v1" &&
            (preparation_failure_count += 1)
    end
    valid_count == 108 || error("Lock 008 valid structural count differs")
    preparation_failure_count == 72 || error("Lock 008 preparation-failure count differs")
    count(path -> startswith(path, "checkpoints/") && endswith(path, ".toml"), result_files) == 756 ||
        error("Lock 008 requires 756 algorithm checkpoints")
    count(path -> startswith(path, "solver_logs/"), result_files) == 14 ||
        error("Lock 008 requires the disclosed 14 solver logs")
    any(path -> startswith(path, "postdecision/"), result_files) &&
        error("postdecision results predate Lock 008")
    "STRUCTURAL_AUDIT.toml" in result_files && error("structural audit predates Lock 008")
    "RESULT_AUDIT.toml" in result_files && error("final audit predates Lock 008")
    environment = TOML.parsefile(joinpath(local_results, "ENVIRONMENT.toml"))
    get(environment, "execution_lock_aggregate_sha256", "") == PREDECESSOR_AGGREGATE ||
        error("environment does not belong to Lock 007")
    isempty(_relative_files(public_results)) || error("public results predate Lock 008")
    return nothing
end

function _render_lock(hashes)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v8",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_008",
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
  "audit_collection_representation": "sorted Vector{String}",
  "audit_filename_filter": ".toml suffix",
  "registered_audit_key_count": 180,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    validate_execution_design_008()
    occursin("\"schema_version\": \"financial-strategy-library-panel-execution-lock-v8\"", text) ||
        error("unexpected or missing Lock 008 schema")
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("Lock 008 predecessor aggregate differs")
    for declaration in (
        "selected_library_or_burden_saving_inspected_before_successor_lock",
        "solver_status_inspected_before_successor_lock",
        "postdecision_outcome_observed_before_successor_lock",
        "raw_licensed_rows_printed_or_committed",
    )
        occursin("\"$declaration\": false", text) ||
            error("invalid Lock 008 declaration: $declaration")
    end
    for path in keys(hashes)
        occursin("\"$path\": \"$(hashes[path])\"", text) ||
            error("Lock 008 mismatch: $path")
    end
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("Lock 008 aggregate mismatch")
    return aggregate
end

function dry_run()
    config = validate_execution_design_008()
    _assert_prelock_state(config)
    hashes = _hashes()
    return verify_lock_text(_render_lock(hashes), hashes)
end

function create_execution_lock_008()
    isfile(LOCK_PATH) && error("Execution Lock 008 already exists; it is immutable")
    config = validate_execution_design_008()
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

function verify_execution_lock_008()
    isfile(LOCK_PATH) || error("Execution Lock 008 is absent")
    return verify_lock_text(read(LOCK_PATH, String))
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v1_execution_008.jl --dry-run|--lock|--check",
    )
    mode = only(args)
    mode == "--dry-run" && return println("Lock 008 dry run passed: ", dry_run())
    mode == "--lock" && return println("Lock 008 created: ", create_execution_lock_008())
    mode == "--check" && return println("Lock 008 valid: ", verify_execution_lock_008())
    error("unknown mode: $mode")
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution008.main()
end
