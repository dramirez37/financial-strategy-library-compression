module LockFinancialStrategyLibraryPanelV1Execution002

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1.jl"))
using .LockFinancialStrategyLibraryPanelV1: verify_design_lock

export create_execution_lock_002,
       dry_run,
       main,
       validate_execution_design_002,
       verify_execution_lock_002,
       verify_lock_text

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_strategy_library_panel_v1.toml",
)
const AMENDMENT_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v1",
    "amendments",
    "EXECUTION_AMENDMENT_002.toml",
)
const PREDECESSOR_LOCK_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v1",
    "EXECUTION_LOCK.json",
)
const LOCK_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v1",
    "EXECUTION_LOCK_002.json",
)
const PREDECESSOR_AGGREGATE =
    "3eec7e8136d4f4dcdf7eee37fc23ce15b8bcc703b42a9002fe6d19db68496983"

const REQUIRED_FILES = (
    "experiments/financial_strategy_library_panel_v1/DESIGN_LOCK.json",
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_001.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_001.toml",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_002.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_002.toml",
    "experiments/financial_strategy_library_panel_v1/amendments/RETURN_QUALITY_AUDIT_001.md",
    "julia/src/FinancialStrategyLibraryPanelV1.jl",
    "julia/scripts/run_financial_strategy_library_panel_v1.jl",
    "julia/scripts/audit_financial_strategy_library_panel_v1.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_002.jl",
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
        isfile(joinpath(REPOSITORY_ROOT, relative)) || error("missing successor lock input: $relative")
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
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 001 is absent")
    text = read(PREDECESSOR_LOCK_PATH, String)
    occursin(
        "\"schema_version\": \"financial-strategy-library-panel-execution-lock-v1\"",
        text,
    ) || error("unexpected predecessor execution-lock schema")
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("Execution Lock 001 aggregate differs")
    occursin("\"study_outcome_observed_before_execution_lock\": false", text) ||
        error("Execution Lock 001 outcome declaration differs")
    return _sha256_file(PREDECESSOR_LOCK_PATH)
end

function validate_execution_design_002()
    design_aggregate = verify_design_lock()
    predecessor_sha256 = _verify_predecessor_lock()
    config = TOML.parsefile(CONFIG_PATH)
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] == "financial-strategy-library-panel-execution-amendment-v2" ||
        error("unexpected successor amendment schema")
    amendment["amendment_id"] == "AMENDMENT_002" ||
        error("unexpected successor amendment identifier")
    amendment["licensed_rows_read_before_amendment"] === true ||
        error("the observed licensed ingestion attempt is not disclosed")
    amendment["ingestion_failure_observed_before_amendment"] === true ||
        error("the observed ingestion failure is not disclosed")
    amendment["environment_record_created_before_amendment"] === true ||
        error("the failed-attempt environment record is not disclosed")
    for key in (
        "registered_seed_consumed_before_amendment",
        "study_instance_constructed_before_amendment",
        "algorithm_or_solver_outcome_observed_before_amendment",
        "burden_or_identity_outcome_observed_before_amendment",
        "postdecision_outcome_observed_before_amendment",
        "raw_licensed_rows_printed_or_committed",
        "scientific_estimands_changed",
        "origin_registry_changed",
        "library_registry_changed",
        "burden_schedule_registry_changed",
        "seed_registry_changed",
        "algorithm_registry_changed",
    )
        amendment[key] === false || error("successor amendment declaration changed: $key")
    end
    diagnostic = amendment["diagnostic"]
    diagnostic["selected_origin_membership_rows"] == 3_950_875 ||
        error("return-quality diagnostic denominator changed")
    diagnostic["missing_return_membership_rows"] == 340 ||
        error("return-quality diagnostic missing count changed")
    diagnostic["missing_first_rows"] == 340 || error("first-row missing count changed")
    diagnostic["missing_interior_rows"] == 0 || error("interior missing count changed")
    diagnostic["missing_flag"] == "NS" || error("missing-return flag changed")
    diagnostic["finite_return_flag"] == "NA" || error("finite-return flag changed")
    diagnostic["raw_rows_printed"] === false || error("raw rows cannot be printed")
    rule = amendment["return_rule"]
    rule["allowed_missing_flag"] == "NS" || error("allowed missing flag changed")
    rule["action"] == "exclude initialization row without imputation" ||
        error("missing-return action changed")
    rule["allowed_finite_flag"] == "NA" || error("finite-return flag rule changed")
    rule["other_missing_action"] == "fail closed" || error("other missing returns must fail")
    length(config["algorithms"]["algorithm_ids"]) == 7 || error("algorithm registry changed")
    return (
        design_aggregate = design_aggregate,
        predecessor_sha256 = predecessor_sha256,
        config = config,
        amendment = amendment,
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
    isempty(_relative_files(local_data)) ||
        error("local study data exist before successor execution lock")
    result_files = _relative_files(local_results)
    result_files in (String[], ["ENVIRONMENT.toml"]) ||
        error("only the disclosed environment-only failed-attempt record may predate Lock 002")
    isempty(_relative_files(public_results)) ||
        error("public study results exist before successor execution lock")
    return result_files
end

function _render_lock(hashes, validated, preexisting_result_files)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    environment_only = preexisting_result_files == ["ENVIRONMENT.toml"]
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v2",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_002",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "design_lock_aggregate_sha256": "$(validated.design_aggregate)",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$(validated.predecessor_sha256)",
  "licensed_rows_read_before_successor_lock": true,
  "ingestion_failure_observed_before_successor_lock": true,
  "environment_only_record_present_before_successor_lock": $environment_only,
  "registered_seed_consumed_before_successor_lock": false,
  "study_instance_constructed_before_successor_lock": false,
  "algorithm_or_solver_outcome_observed_before_successor_lock": false,
  "postdecision_outcome_observed_before_successor_lock": false,
  "raw_licensed_rows_printed_or_committed": false,
  "registered_origins": 20,
  "registered_compression_instances": 180,
  "registered_algorithm_terminal_rows": 1260,
  "julia_threads": 8,
  "crsp_ns_initialization_rows_excluded": 340,
  "interior_missing_return_rows": 0,
  "missing_return_imputation_permitted": false,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    validated = validate_execution_design_002()
    occursin(
        "\"schema_version\": \"financial-strategy-library-panel-execution-lock-v2\"",
        text,
    ) || error("unexpected or missing successor execution-lock schema")
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("successor lock predecessor aggregate differs")
    occursin(
        "\"predecessor_execution_lock_file_sha256\": \"$(validated.predecessor_sha256)\"",
        text,
    ) || error("successor lock predecessor file differs")
    for declaration in (
        "registered_seed_consumed_before_successor_lock",
        "study_instance_constructed_before_successor_lock",
        "algorithm_or_solver_outcome_observed_before_successor_lock",
        "postdecision_outcome_observed_before_successor_lock",
        "raw_licensed_rows_printed_or_committed",
        "missing_return_imputation_permitted",
    )
        occursin("\"$declaration\": false", text) ||
            error("invalid successor lock declaration: $declaration")
    end
    occursin("\"crsp_ns_initialization_rows_excluded\": 340", text) ||
        error("successor lock initialization count differs")
    occursin("\"interior_missing_return_rows\": 0", text) ||
        error("successor lock interior missing count differs")
    for path in keys(hashes)
        occursin("\"$path\": \"$(hashes[path])\"", text) ||
            error("successor execution-lock mismatch: $path")
    end
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("successor execution-lock aggregate mismatch")
    return aggregate
end

function dry_run()
    validated = validate_execution_design_002()
    preexisting = _assert_prelock_state(validated.config)
    hashes = _hashes()
    text = _render_lock(hashes, validated, preexisting)
    return verify_lock_text(text, hashes)
end

function create_execution_lock_002()
    isfile(LOCK_PATH) && error("Execution Lock 002 already exists; do not rewrite it")
    validated = validate_execution_design_002()
    preexisting = _assert_prelock_state(validated.config)
    hashes = _hashes()
    text = _render_lock(hashes, validated, preexisting)
    verify_lock_text(text, hashes)
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, LOCK_PATH; force = false)
    println("created financial strategy-library panel v1 Execution Lock 002")
    return LOCK_PATH
end

function verify_execution_lock_002()
    isfile(LOCK_PATH) || error("financial panel v1 Execution Lock 002 is absent")
    return verify_lock_text(read(LOCK_PATH, String), _hashes())
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v1_execution_002.jl --dry-run|--create|--check",
    )
    mode = only(args)
    mode == "--dry-run" && return println("financial panel Execution Lock 002 dry run valid: $(dry_run())")
    mode == "--create" && return create_execution_lock_002()
    mode == "--check" && return println(
        "financial panel Execution Lock 002 valid: $(verify_execution_lock_002())",
    )
    error("unknown Execution Lock 002 mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution002.main()
end
