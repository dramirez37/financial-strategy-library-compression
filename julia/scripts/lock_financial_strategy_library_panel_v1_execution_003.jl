module LockFinancialStrategyLibraryPanelV1Execution003

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1.jl"))
using .LockFinancialStrategyLibraryPanelV1: verify_design_lock

export create_execution_lock_003,
       dry_run,
       main,
       validate_execution_design_003,
       verify_execution_lock_003,
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
    "EXECUTION_AMENDMENT_003.toml",
)
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_002.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_003.json")
const PREDECESSOR_AGGREGATE =
    "5a68154944b4a27b64cab0ae930aa593878802f2d7b2aa13c7505993fc95a2e1"

const REQUIRED_FILES = (
    "experiments/financial_strategy_library_panel_v1/DESIGN_LOCK.json",
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK.json",
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_002.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_001.md",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_002.md",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_003.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_001.toml",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_002.toml",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_003.toml",
    "experiments/financial_strategy_library_panel_v1/amendments/RETURN_QUALITY_AUDIT_001.md",
    "julia/src/FinancialStrategyLibraryPanelV1.jl",
    "julia/scripts/run_financial_strategy_library_panel_v1.jl",
    "julia/scripts/audit_financial_strategy_library_panel_v1.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_003.jl",
    "julia/test/test_financial_strategy_library_panel_v1_execution.jl",
    "julia/test/run_financial_strategy_library_panel_v1_execution_tests.jl",
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
        isfile(joinpath(REPOSITORY_ROOT, relative)) || error("missing Lock 003 input: $relative")
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

function _verify_predecessor_lock()
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 002 is absent")
    text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"schema_version\": \"financial-strategy-library-panel-execution-lock-v2\"", text) ||
        error("unexpected predecessor execution-lock schema")
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("Execution Lock 002 aggregate differs")
    return _sha256_file(PREDECESSOR_LOCK_PATH)
end

function validate_execution_design_003()
    design_aggregate = verify_design_lock()
    predecessor_sha256 = _verify_predecessor_lock()
    config = TOML.parsefile(CONFIG_PATH)
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] == "financial-strategy-library-panel-execution-amendment-v3" ||
        error("unexpected Amendment 003 schema")
    amendment["amendment_id"] == "AMENDMENT_003" || error("unexpected Amendment 003 identifier")
    amendment["licensed_rows_read_before_amendment"] === true ||
        error("the licensed preparation attempt is not disclosed")
    for key in (
        "registered_seed_consumed_before_amendment",
        "algorithm_or_solver_outcome_observed_before_amendment",
        "selected_library_or_burden_saving_observed_before_amendment",
        "postdecision_outcome_observed_before_amendment",
        "raw_licensed_rows_printed_or_committed",
        "scientific_estimands_changed",
        "minimum_profile_observations_changed",
        "origin_registry_changed",
        "library_registry_changed",
        "burden_schedule_registry_changed",
        "seed_registry_changed",
        "algorithm_registry_changed",
    )
        amendment[key] === false || error("Amendment 003 declaration changed: $key")
    end
    amendment["successful_origin_instance_sets_constructed_before_amendment"] == 12 ||
        error("pre-amendment successful-origin count changed")
    amendment["serialized_source_instances_before_amendment"] == 108 ||
        error("pre-amendment instance count changed")
    amendment["failed_origin_tasks_observed_before_amendment"] == 8 ||
        error("pre-amendment failed-origin count changed")
    persistence = amendment["failure_persistence"]
    persistence["successful_instances_plus_failure_slots"] == 180 ||
        error("failure persistence does not preserve 180 slots")
    persistence["registered_algorithm_terminal_rows"] == 1260 ||
        error("failure persistence does not preserve 1,260 algorithm rows")
    persistence["fabricate_source_instance"] === false || error("source-instance fabrication is forbidden")
    persistence["impute_profile"] === false || error("belief-profile imputation is forbidden")
    return (
        design_aggregate = design_aggregate,
        predecessor_sha256 = predecessor_sha256,
        config = config,
    )
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
        error("Lock 003 requires the disclosed 12 origin metadata records")
    all(path -> startswith(path, "origin_builds/"), data_files) ||
        error("unexpected local-data artifacts predate Lock 003")
    count(path -> startswith(path, "instances/"), result_files) == 108 ||
        error("Lock 003 requires the disclosed 108 serialized instances")
    count(==("ENVIRONMENT.toml"), result_files) == 1 ||
        error("Lock 003 requires the predecessor environment record")
    length(result_files) == 109 || error("unexpected local-result artifacts predate Lock 003")
    isempty(_relative_files(public_results)) || error("public results exist before Lock 003")
    return (data_files = data_files, result_files = result_files)
end

function _render_lock(hashes, validated)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v3",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_003",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "design_lock_aggregate_sha256": "$(validated.design_aggregate)",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$(validated.predecessor_sha256)",
  "licensed_rows_read_before_successor_lock": true,
  "successful_origins_observed_before_successor_lock": 12,
  "failed_origins_observed_before_successor_lock": 8,
  "serialized_instances_observed_before_successor_lock": 108,
  "registered_seed_consumed_before_successor_lock": false,
  "algorithm_or_solver_outcome_observed_before_successor_lock": false,
  "postdecision_outcome_observed_before_successor_lock": false,
  "raw_licensed_rows_printed_or_committed": false,
  "registered_origins": 20,
  "registered_compression_slots": 180,
  "registered_algorithm_terminal_rows": 1260,
  "julia_threads": 8,
  "profile_imputation_permitted": false,
  "source_instance_fabrication_permitted": false,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    validated = validate_execution_design_003()
    occursin("\"schema_version\": \"financial-strategy-library-panel-execution-lock-v3\"", text) ||
        error("unexpected or missing Lock 003 schema")
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("Lock 003 predecessor aggregate differs")
    occursin(
        "\"predecessor_execution_lock_file_sha256\": \"$(validated.predecessor_sha256)\"",
        text,
    ) || error("Lock 003 predecessor file differs")
    for declaration in (
        "registered_seed_consumed_before_successor_lock",
        "algorithm_or_solver_outcome_observed_before_successor_lock",
        "postdecision_outcome_observed_before_successor_lock",
        "raw_licensed_rows_printed_or_committed",
        "profile_imputation_permitted",
        "source_instance_fabrication_permitted",
    )
        occursin("\"$declaration\": false", text) ||
            error("invalid Lock 003 declaration: $declaration")
    end
    for path in keys(hashes)
        occursin("\"$path\": \"$(hashes[path])\"", text) ||
            error("Lock 003 mismatch: $path")
    end
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("Lock 003 aggregate mismatch")
    return aggregate
end

function dry_run()
    validated = validate_execution_design_003()
    _assert_prelock_state(validated.config)
    hashes = _hashes()
    return verify_lock_text(_render_lock(hashes, validated), hashes)
end

function create_execution_lock_003()
    isfile(LOCK_PATH) && error("Execution Lock 003 already exists; it is immutable")
    validated = validate_execution_design_003()
    _assert_prelock_state(validated.config)
    hashes = _hashes()
    text = _render_lock(hashes, validated)
    verify_lock_text(text, hashes)
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, LOCK_PATH; force = false)
    return _aggregate(hashes)
end

function verify_execution_lock_003()
    isfile(LOCK_PATH) || error("Execution Lock 003 is absent")
    return verify_lock_text(read(LOCK_PATH, String))
end

function main(args = ARGS)
    length(args) == 1 || error("usage: lock_financial_strategy_library_panel_v1_execution_003.jl --dry-run|--lock|--check")
    mode = only(args)
    mode == "--dry-run" && return println("Lock 003 dry run passed: ", dry_run())
    mode == "--lock" && return println("Lock 003 created: ", create_execution_lock_003())
    mode == "--check" && return println("Lock 003 valid: ", verify_execution_lock_003())
    error("unknown mode: $mode")
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution003.main()
end
