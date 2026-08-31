module LockFinancialStrategyLibraryPanelV1Execution012

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_011.jl"))
const Lock011 = LockFinancialStrategyLibraryPanelV1Execution011

export create_execution_lock_012,
       dry_run,
       main,
       validate_execution_design_012,
       verify_execution_lock_012,
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
    "EXECUTION_AMENDMENT_012.toml",
)
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_011.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_012.json")
const DESIGN_AGGREGATE =
    "a549856760f40b28a02571d04869e522ff421390b362147aa1349c52d4e70cba"
const PREDECESSOR_AGGREGATE =
    "59cb6795ad35986bdc5c102da900147efad952dd557b94eaba107ead85393e9f"
const PREDECESSOR_FILE_SHA256 =
    "c1ad8037a4232a6785d7a9ab17b08d44c81d5c1070e9375541081d12cb3d252c"
const STRUCTURAL_RESULT_AGGREGATE =
    "9564a4c9b0ea28f4cf4a9705e8e489398555032e466ba3fac8c16a98094a012a"

const REQUIRED_FILES = (
    Lock011.REQUIRED_FILES...,
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_011.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_012.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_012.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_012.jl",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text) = bytes2hex(sha256(codeunits(text)))

function _hashes()
    length(REQUIRED_FILES) == length(unique(REQUIRED_FILES)) ||
        error("Lock 012 input list contains duplicates")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) ||
            error("missing Lock 012 input: $relative")
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
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 011 is absent")
    predecessor_text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", predecessor_text) ||
        error("historical Lock 011 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 ||
        error("historical Lock 011 file hash differs")
    return nothing
end

function validate_execution_design_012()
    _verify_predecessor()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v12" ||
        error("unexpected Amendment 012 schema")
    amendment["amendment_id"] == "AMENDMENT_012" ||
        error("unexpected Amendment 012 identifier")
    amendment["predecessor_amendment_id"] == "AMENDMENT_011" ||
        error("unexpected Amendment 012 predecessor")
    for (key, expected) in (
        "postdecision_results_before_amendment" => 0,
        "final_result_audit_files_before_amendment" => 0,
        "analysis_artifacts_before_amendment" => 0,
        "completed_source_partitions_before_amendment" => 2,
        "failed_source_partition_index" => 2,
    )
        amendment[key] == expected || error("Amendment 012 disclosure changed: $key")
    end
    for key in (
        "raw_row_values_inspected",
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
        "structural_results_changed",
        "analysis_rules_changed",
    )
        amendment[key] === false || error("Amendment 012 declaration changed: $key")
    end
    amendment["audit_predicates_changed"] === true ||
        error("Amendment 012 must audit its new missing-unused-field declarations")
    policy = amendment["field_policy"]
    policy["structural_close_required"] === true || error("structural close rule changed")
    policy["structural_nonnegative_volume_required"] === true ||
        error("structural volume rule changed")
    policy["postdecision_close_used"] === false || error("postdecision close use changed")
    policy["postdecision_volume_used"] === false || error("postdecision volume use changed")
    policy["postdecision_unused_field_imputation_permitted"] === false ||
        error("unused-field imputation was enabled")
    policy["postdecision_return_drop_for_unused_market_field_permitted"] === false ||
        error("unused-field return dropping was enabled")
    cache = amendment["cache_compatibility"]
    cache["compatible_predecessor_execution_lock_aggregate_sha256"] ==
    PREDECESSOR_AGGREGATE || error("cache predecessor binding changed")
    cache["permitted_predecessor_partition_indices"] == [1, 3] ||
        error("cache-compatible partition set changed")
    cache["arbitrary_cross_lock_reuse_permitted"] === false ||
        error("arbitrary cross-lock cache reuse was enabled")
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

function _audit_predecessor_partition(cache_root, index)
    stem = "postdecision-source-$(lpad(index, 3, '0'))"
    metadata_path = joinpath(cache_root, stem * ".toml")
    parquet_path = joinpath(cache_root, stem * ".parquet")
    isfile(metadata_path) && isfile(parquet_path) ||
        error("Lock 012 requires predecessor source partition $index")
    metadata = TOML.parsefile(metadata_path)
    metadata["schema_version"] == "financial-panel-origin-series-parquet-v1" ||
        error("predecessor partition schema differs")
    metadata["phase"] == "postdecision" || error("predecessor cache phase differs")
    metadata["source_file_index"] == index || error("predecessor source index differs")
    metadata["source_file_count"] == 3 || error("predecessor source count differs")
    metadata["execution_lock_aggregate_sha256"] == PREDECESSOR_AGGREGATE ||
        error("predecessor cache lock binding differs")
    metadata["parquet_sha256"] == _sha256_file(parquet_path) ||
        error("predecessor Parquet hash differs")
    metadata["local_licensed_rows_included"] === true ||
        error("predecessor cache licensing declaration differs")
    metadata["public_promotion_permitted"] === false ||
        error("predecessor cache promotion declaration differs")
    return nothing
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
        "postdecision-source-003.parquet",
        "postdecision-source-003.toml",
    ] || error("Lock 012 interrupted-cache file set differs")
    _audit_predecessor_partition(cache_root, 1)
    _audit_predecessor_partition(cache_root, 3)
    result_files = _relative_files(local_results)
    any(path -> startswith(path, "postdecision/"), result_files) &&
        error("postdecision results predate Lock 012")
    any(path -> startswith(path, "analysis/"), result_files) &&
        error("analysis artifacts predate Lock 012")
    "RESULT_AUDIT.toml" in result_files && error("final result audit predates Lock 012")
    structural_audit_path = joinpath(local_results, "STRUCTURAL_AUDIT.toml")
    isfile(structural_audit_path) || error("passing Lock 011 structural audit is absent")
    structural_audit = TOML.parsefile(structural_audit_path)
    structural_audit["passed"] === true || error("Lock 011 structural audit did not pass")
    structural_audit["execution_lock_aggregate_sha256"] == PREDECESSOR_AGGREGATE ||
        error("structural audit does not belong to Lock 011")
    structural_audit["structural_result_aggregate_sha256"] == STRUCTURAL_RESULT_AGGREGATE ||
        error("structural result aggregate differs")
    isempty(_relative_files(public_results)) || error("public results predate Lock 012")
    return nothing
end

function _render_lock(hashes)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v12",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_012",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$PREDECESSOR_FILE_SHA256",
  "completed_predecessor_source_partitions": 2,
  "failed_source_partition_index": 2,
  "postdecision_results_before_successor_lock": 0,
  "postdecision_outcome_observed_before_successor_lock": false,
  "raw_row_values_inspected_before_successor_lock": false,
  "unused_postdecision_fields_imputed": false,
  "scientific_estimands_changed": false,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    validate_execution_design_012()
    occursin("\"schema_version\": \"financial-strategy-library-panel-execution-lock-v12\"", text) ||
        error("unexpected or missing Lock 012 schema")
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("Lock 012 predecessor aggregate differs")
    for declaration in (
        "postdecision_outcome_observed_before_successor_lock",
        "raw_row_values_inspected_before_successor_lock",
        "unused_postdecision_fields_imputed",
        "scientific_estimands_changed",
    )
        occursin("\"$declaration\": false", text) ||
            error("invalid Lock 012 declaration: $declaration")
    end
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("Lock 012 aggregate differs")
    for (relative, hash) in hashes
        occursin("\"$relative\": \"$hash\"", text) ||
            error("Lock 012 file hash differs: $relative")
    end
    return aggregate
end

function dry_run()
    config = validate_execution_design_012()
    _assert_prelock_state(config)
    return _aggregate(_hashes())
end

function create_execution_lock_012()
    isfile(LOCK_PATH) && error("Execution Lock 012 already exists")
    config = validate_execution_design_012()
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

function verify_execution_lock_012()
    isfile(LOCK_PATH) || error("Execution Lock 012 is absent")
    return verify_lock_text(read(LOCK_PATH, String), _hashes())
end

function main(args = ARGS)
    length(args) == 1 || error("usage: lock_financial_strategy_library_panel_v1_execution_012.jl --dry-run|--lock|--check")
    mode = only(args)
    mode == "--dry-run" && return println("Lock 012 dry run passed: ", dry_run())
    mode == "--lock" && return println("Lock 012 created: ", create_execution_lock_012())
    mode == "--check" && return println("Lock 012 valid: ", verify_execution_lock_012())
    error("unknown Lock 012 mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution012.main()
end
