module LockFinancialStrategyLibraryPanelV1Execution013

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_012.jl"))
const Lock012 = LockFinancialStrategyLibraryPanelV1Execution012

export create_execution_lock_013,
       dry_run,
       main,
       validate_execution_design_013,
       verify_execution_lock_013,
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
    "EXECUTION_AMENDMENT_013.toml",
)
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_012.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_013.json")
const DESIGN_AGGREGATE = Lock012.DESIGN_AGGREGATE
const PREDECESSOR_AGGREGATE =
    "cf364daa5f00991819c4ac514cfe6b7416690f154ce83bfd7734c01143d8244e"
const PREDECESSOR_FILE_SHA256 =
    "964782b77e40839e30ac589c41e5090f14d9b9b716aa01a2c5d474ee1c183568"
const LOCK_011_AGGREGATE =
    "59cb6795ad35986bdc5c102da900147efad952dd557b94eaba107ead85393e9f"
const STRUCTURAL_RESULT_AGGREGATE = Lock012.STRUCTURAL_RESULT_AGGREGATE

const REQUIRED_FILES = (
    Lock012.REQUIRED_FILES...,
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_012.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_013.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_013.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_013.jl",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text) = bytes2hex(sha256(codeunits(text)))

function _hashes()
    length(REQUIRED_FILES) == length(unique(REQUIRED_FILES)) ||
        error("Lock 013 input list contains duplicates")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) ||
            error("missing Lock 013 input: $relative")
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
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 012 is absent")
    predecessor_text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", predecessor_text) ||
        error("historical Lock 012 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 ||
        error("historical Lock 012 file hash differs")
    return nothing
end

function validate_execution_design_013()
    _verify_predecessor()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v13" ||
        error("unexpected Amendment 013 schema")
    amendment["amendment_id"] == "AMENDMENT_013" ||
        error("unexpected Amendment 013 identifier")
    amendment["predecessor_amendment_id"] == "AMENDMENT_012" ||
        error("unexpected Amendment 013 predecessor")
    for (key, expected) in (
        "postdecision_results_before_amendment" => 0,
        "final_result_audit_files_before_amendment" => 0,
        "analysis_artifacts_before_amendment" => 0,
        "completed_source_partitions_before_amendment" => 3,
        "cached_origin_window_memberships_audited" => 865661,
        "missing_return_memberships_observed" => 1,
        "affected_origin_security_series_observed" => 1,
        "affected_origins_observed" => 1,
        "postdecision_year_missing_rows_observed" => 1,
        "terminal_missing_rows_observed" => 1,
        "missing_rows_with_later_finite_return_observed" => 0,
    )
        amendment[key] == expected || error("Amendment 013 disclosure changed: $key")
    end
    for key in (
        "raw_row_values_printed_or_committed",
        "raw_identifiers_or_dates_printed_or_committed",
        "selected_library_or_burden_saving_inspected_before_amendment",
        "solver_status_inspected_before_amendment",
        "postdecision_outcome_observed_before_amendment",
        "scientific_estimands_changed",
        "primary_structural_analysis_changed",
        "analysis_formulas_changed",
        "origin_registry_changed",
        "library_registry_changed",
        "burden_schedule_registry_changed",
        "seed_registry_changed",
        "algorithm_registry_changed",
        "structural_results_changed",
    )
        amendment[key] === false || error("Amendment 013 declaration changed: $key")
    end
    amendment["secondary_postdecision_availability_rule_changed"] === true ||
        error("Amendment 013 must disclose its availability-rule change")
    amendment["audit_predicates_changed"] === true ||
        error("Amendment 013 must audit its unavailable records")
    policy = amendment["missing_return_policy"]
    policy["required_flag"] == "DP" || error("terminal missing-return flag changed")
    policy["required_delisting_flag"] == "positive" ||
        error("terminal delisting requirement changed")
    policy["required_window"] == "registered postdecision year" ||
        error("terminal missing-return window changed")
    policy["return_imputation_permitted"] === false ||
        error("terminal-DP return imputation was enabled")
    policy["zero_substitution_permitted"] === false ||
        error("terminal-DP zero substitution was enabled")
    policy["origin_wide_postdecision_unavailability"] === true ||
        error("origin-wide postdecision unavailability was disabled")
    policy["affected_registered_instance_count"] == 9 ||
        error("affected registered-instance count changed")
    policy["affected_algorithm_row_count"] == 63 ||
        error("affected algorithm-row count changed")
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

function _audit_partition(cache_root, index, expected_lock)
    stem = "postdecision-source-$(lpad(index, 3, '0'))"
    metadata_path = joinpath(cache_root, stem * ".toml")
    parquet_path = joinpath(cache_root, stem * ".parquet")
    isfile(metadata_path) && isfile(parquet_path) ||
        error("Lock 013 requires source partition $index")
    metadata = TOML.parsefile(metadata_path)
    metadata["schema_version"] == "financial-panel-origin-series-parquet-v1" ||
        error("partition $index schema differs")
    metadata["phase"] == "postdecision" || error("partition $index phase differs")
    metadata["source_file_index"] == index || error("partition $index source index differs")
    metadata["source_file_count"] == 3 || error("partition $index source count differs")
    metadata["execution_lock_aggregate_sha256"] == expected_lock ||
        error("partition $index lock binding differs")
    metadata["parquet_sha256"] == _sha256_file(parquet_path) ||
        error("partition $index Parquet hash differs")
    metadata["local_licensed_rows_included"] === true ||
        error("partition $index licensing declaration differs")
    metadata["public_promotion_permitted"] === false ||
        error("partition $index promotion declaration differs")
    return Int(metadata["retained_origin_rows"])
end

function _assert_prelock_state(config)
    paths = config["paths"]
    local_data = joinpath(REPOSITORY_ROOT, String(paths["local_data_root"]))
    local_results = joinpath(REPOSITORY_ROOT, String(paths["local_results_root"]))
    public_results = joinpath(REPOSITORY_ROOT, String(paths["public_results_root"]))
    cache_root = joinpath(local_data, "prepared_return_panels")
    _relative_files(cache_root) == [
        "postdecision-source-001.parquet",
        "postdecision-source-001.toml",
        "postdecision-source-002.parquet",
        "postdecision-source-002.toml",
        "postdecision-source-003.parquet",
        "postdecision-source-003.toml",
    ] || error("Lock 013 interrupted-cache file set differs")
    cached_rows =
        _audit_partition(cache_root, 1, LOCK_011_AGGREGATE) +
        _audit_partition(cache_root, 2, PREDECESSOR_AGGREGATE) +
        _audit_partition(cache_root, 3, LOCK_011_AGGREGATE)
    cached_rows == 865661 || error("Lock 013 cached membership count differs")
    result_files = _relative_files(local_results)
    any(path -> startswith(path, "postdecision/"), result_files) &&
        error("postdecision results predate Lock 013")
    any(path -> startswith(path, "analysis/"), result_files) &&
        error("analysis artifacts predate Lock 013")
    "RESULT_AUDIT.toml" in result_files && error("final result audit predates Lock 013")
    structural_audit_path = joinpath(local_results, "STRUCTURAL_AUDIT.toml")
    isfile(structural_audit_path) || error("passing structural audit is absent")
    structural_audit = TOML.parsefile(structural_audit_path)
    structural_audit["passed"] === true || error("structural audit did not pass")
    structural_audit["execution_lock_aggregate_sha256"] == PREDECESSOR_AGGREGATE ||
        error("structural audit does not belong to Lock 012")
    structural_audit["structural_result_aggregate_sha256"] == STRUCTURAL_RESULT_AGGREGATE ||
        error("structural result aggregate differs")
    isempty(_relative_files(public_results)) || error("public results predate Lock 013")
    return nothing
end

function _render_lock(hashes)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v13",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_013",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$PREDECESSOR_FILE_SHA256",
  "completed_predecessor_source_partitions": 3,
  "postdecision_results_before_successor_lock": 0,
  "postdecision_outcome_observed_before_successor_lock": false,
  "raw_row_values_printed_or_committed": false,
  "terminal_delisting_pending_memberships": 1,
  "affected_postdecision_origins": 1,
  "affected_registered_instances": 9,
  "affected_algorithm_rows": 63,
  "terminal_missing_return_imputed": false,
  "scientific_estimands_changed": false,
  "secondary_postdecision_availability_rule_changed": true,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    validate_execution_design_013()
    occursin("\"schema_version\": \"financial-strategy-library-panel-execution-lock-v13\"", text) ||
        error("unexpected or missing Lock 013 schema")
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("Lock 013 predecessor aggregate differs")
    for declaration in (
        "postdecision_outcome_observed_before_successor_lock",
        "raw_row_values_printed_or_committed",
        "terminal_missing_return_imputed",
        "scientific_estimands_changed",
    )
        occursin("\"$declaration\": false", text) ||
            error("invalid Lock 013 declaration: $declaration")
    end
    occursin("\"secondary_postdecision_availability_rule_changed\": true", text) ||
        error("Lock 013 availability-rule disclosure differs")
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("Lock 013 aggregate differs")
    for (relative, hash) in hashes
        occursin("\"$relative\": \"$hash\"", text) ||
            error("Lock 013 file hash differs: $relative")
    end
    return aggregate
end

function dry_run()
    config = validate_execution_design_013()
    _assert_prelock_state(config)
    return _aggregate(_hashes())
end

function create_execution_lock_013()
    isfile(LOCK_PATH) && error("Execution Lock 013 already exists")
    config = validate_execution_design_013()
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

function verify_execution_lock_013()
    isfile(LOCK_PATH) || error("Execution Lock 013 is absent")
    return verify_lock_text(read(LOCK_PATH, String), _hashes())
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v1_execution_013.jl --dry-run|--lock|--check",
    )
    mode = only(args)
    mode == "--dry-run" && return println("Lock 013 dry run passed: ", dry_run())
    mode == "--lock" && return println("Lock 013 created: ", create_execution_lock_013())
    mode == "--check" && return println("Lock 013 valid: ", verify_execution_lock_013())
    error("unknown Lock 013 mode: $mode")
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution013.main()
end
