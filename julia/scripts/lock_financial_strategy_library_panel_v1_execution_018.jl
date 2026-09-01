module LockFinancialStrategyLibraryPanelV1Execution018

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_017.jl"))
const Lock017 = LockFinancialStrategyLibraryPanelV1Execution017

export create_execution_lock_018,
       dry_run,
       main,
       validate_execution_design_018,
       verify_execution_lock_018,
       verify_lock_text

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(REPOSITORY_ROOT, "experiments", "financial_strategy_library_panel_v1")
const CONFIG_PATH = joinpath(REPOSITORY_ROOT, "experiments", "configs", "financial_strategy_library_panel_v1.toml")
const AMENDMENT_PATH = joinpath(EXPERIMENT_ROOT, "amendments", "EXECUTION_AMENDMENT_018.toml")
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_017.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_018.json")
const DESIGN_AGGREGATE = Lock017.DESIGN_AGGREGATE
const PREDECESSOR_AGGREGATE = "9eda494c80aaf31e1fdfc0adaa4bbdb7384e0e96288da224b041175c59fc4401"
const PREDECESSOR_FILE_SHA256 = "c96550505fbeeb574885a97b02f34e2b633befcf1318e45f1eed1da687bf0103"
const POSTDECISION_DIRECTORY_AGGREGATE = "f63bb273afc4d6ed69fb12a2f7f35a84f8eb45822f1cce59dd06db90af0fcacc"
const POSTDECISION_RESULT_AGGREGATE = "79c6eef4f77ea173e7a119ef49454ccb20ccb1cb047581e0cb6dfd509fd19b34"
const PRELOCK_RESULT_AUDIT_SHA256 = "622db49ea493b460fc8e0e60fa8898ab1293e4b89fd99713191cc5a213db374d"
const PRELOCK_ANALYSIS_MANIFEST_SHA256 = "eba4b134ac80d75b49ce7738a725fd54bf3d3a22f78755572467737b89aa5037"
const PRELOCK_ANALYSIS_AUDIT_SHA256 = "8c3e347af9fd601c93ccfafabbb7519da83edc7429dbf34ba8f74ca6ad566217"

const REQUIRED_FILES = (
    Lock017.REQUIRED_FILES...,
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_017.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_018.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_018.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_018.jl",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(value) = bytes2hex(sha256(codeunits(value)))

function _hashes()
    length(REQUIRED_FILES) == length(unique(REQUIRED_FILES)) || error("Lock 018 input list contains duplicates")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) || error("missing Lock 018 input: $relative")
    end
    return Dict(relative => _sha256_file(joinpath(REPOSITORY_ROOT, relative)) for relative in REQUIRED_FILES)
end

_aggregate(hashes) = _sha256_text(join(
    ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
))

function _verify_predecessor()
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 017 is absent")
    text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) || error("historical Lock 017 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 || error("historical Lock 017 file hash differs")
end

function validate_execution_design_018()
    _verify_predecessor()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] == "financial-strategy-library-panel-execution-amendment-v18" || error("unexpected Amendment 018 schema")
    amendment["amendment_id"] == "AMENDMENT_018" || error("unexpected Amendment 018 identifier")
    amendment["predecessor_amendment_id"] == "AMENDMENT_017" || error("unexpected Amendment 018 predecessor")
    amendment["classification"] == "analysis_partition_certificate_rebinding" || error("Amendment 018 classification changed")
    amendment["registered_partition_count"] == 180 || error("Amendment 018 partition count changed")
    amendment["registered_rows_per_partition"] == 7 || error("Amendment 018 row count changed")
    amendment["failed_rerun_partition_binding_mismatch_count"] == 180 || error("Amendment 018 mismatch count changed")
    for key in (
        "analysis_formulas_changed",
        "scientific_estimands_changed",
        "registered_denominators_changed",
        "source_result_records_changed",
        "raw_row_values_printed_or_committed",
    )
        amendment[key] === false || error("Amendment 018 declaration changed: $key")
    end
    policy = amendment["partition_rebinding"]
    policy["allowed_predecessor_execution_lock_aggregate_sha256"] == PREDECESSOR_AGGREGATE || error("Amendment 018 predecessor binding changed")
    for key in (
        "require_parquet_hash_validation",
        "require_parquet_schema_validation",
        "require_registered_row_count",
        "require_current_structural_source_hash",
        "require_current_postdecision_source_hash",
        "update_metadata_atomically",
        "source_hash_mismatch_is_fatal",
        "parquet_hash_mismatch_is_fatal",
        "unrelated_execution_lock_is_fatal",
    )
        policy[key] === true || error("Amendment 018 safety predicate changed: $key")
    end
    policy["rewrite_parquet_when_only_certificate_binding_changed"] === false || error("Amendment 018 permits unnecessary Parquet rewrites")
    return TOML.parsefile(CONFIG_PATH)
end

function _relative_files(root)
    isdir(root) || return String[]
    files = String[]
    for (directory, _, names) in walkdir(root), name in names
        push!(files, relpath(joinpath(directory, name), root))
    end
    return sort!(files)
end

function _directory_aggregate(directory)
    hashes = Dict{String,String}()
    for name in readdir(directory)
        endswith(name, ".toml") || continue
        hashes[name] = _sha256_file(joinpath(directory, name))
    end
    return length(hashes), _aggregate(hashes)
end

function _assert_prelock_state(config)
    root = joinpath(REPOSITORY_ROOT, String(config["paths"]["local_results_root"]))
    post_count, post_aggregate = _directory_aggregate(joinpath(root, "postdecision"))
    post_count == 180 || error("Lock 018 requires 180 postdecision records")
    post_aggregate == POSTDECISION_DIRECTORY_AGGREGATE || error("Lock 018 postdecision directory aggregate differs")

    result_path = joinpath(root, "RESULT_AUDIT.toml")
    _sha256_file(result_path) == PRELOCK_RESULT_AUDIT_SHA256 || error("Lock 018 prelock result-audit state differs")
    result = TOML.parsefile(result_path)
    result["passed"] === true || error("prelock result audit did not pass")
    result["execution_lock_aggregate_sha256"] == PREDECESSOR_AGGREGATE || error("prelock result audit is not bound to Lock 017")
    result["postdecision_result_aggregate_sha256"] == POSTDECISION_RESULT_AGGREGATE || error("prelock postdecision result aggregate differs")

    analysis = joinpath(root, "analysis")
    manifest_path = joinpath(analysis, "ANALYSIS_MANIFEST.toml")
    audit_path = joinpath(analysis, "ANALYSIS_AUDIT.toml")
    _sha256_file(manifest_path) == PRELOCK_ANALYSIS_MANIFEST_SHA256 || error("Lock 018 prelock analysis manifest differs")
    _sha256_file(audit_path) == PRELOCK_ANALYSIS_AUDIT_SHA256 || error("Lock 018 prelock analysis audit differs")
    manifest = TOML.parsefile(manifest_path)
    audit = TOML.parsefile(audit_path)
    manifest["execution_lock_aggregate_sha256"] == PREDECESSOR_AGGREGATE || error("prelock analysis manifest is not bound to Lock 017")
    manifest["result_audit_postdecision_aggregate_sha256"] == POSTDECISION_RESULT_AGGREGATE || error("prelock analysis source aggregate differs")
    manifest["result_audit_sha256"] != PRELOCK_RESULT_AUDIT_SHA256 || error("Lock 018 requires the observed stale certificate binding")
    audit["passed"] === true || error("prelock analysis audit did not pass")
    audit["execution_lock_aggregate_sha256"] == PREDECESSOR_AGGREGATE || error("prelock analysis audit is not bound to Lock 017")
    audit["analysis_manifest_sha256"] == PRELOCK_ANALYSIS_MANIFEST_SHA256 || error("prelock analysis audit manifest binding differs")

    partition_root = joinpath(analysis, "partitions")
    count(name -> endswith(name, ".parquet"), readdir(partition_root)) == 180 || error("Lock 018 requires 180 Parquet partitions")
    count(name -> endswith(name, ".toml"), readdir(partition_root)) == 180 || error("Lock 018 requires 180 partition metadata files")
    temporary_count = sum(count(name -> occursin(".tmp.", name), names) for (_, _, names) in walkdir(root))
    temporary_count == 0 || error("temporary artifacts predate Lock 018")
    public_root = joinpath(REPOSITORY_ROOT, String(config["paths"]["public_results_root"]))
    isempty(_relative_files(public_root)) || error("public results predate Lock 018")
end

function _render_lock(hashes)
    rows = join(("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))), ",\n")
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v18",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_018",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$PREDECESSOR_FILE_SHA256",
  "postdecision_record_count": 180,
  "registered_analysis_partition_count": 180,
  "source_result_records_changed": false,
  "analysis_formulas_changed": false,
  "scientific_estimands_changed": false,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    validate_execution_design_018()
    occursin("\"schema_version\": \"financial-strategy-library-panel-execution-lock-v18\"", text) || error("unexpected or missing Lock 018 schema")
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) || error("Lock 018 predecessor differs")
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) || error("Lock 018 aggregate differs")
    for (relative, hash) in hashes
        occursin("\"$relative\": \"$hash\"", text) || error("Lock 018 file hash differs: $relative")
    end
    return aggregate
end

function dry_run()
    config = validate_execution_design_018()
    _assert_prelock_state(config)
    return _aggregate(_hashes())
end

function create_execution_lock_018()
    isfile(LOCK_PATH) && error("Execution Lock 018 already exists")
    config = validate_execution_design_018()
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

verify_execution_lock_018() = isfile(LOCK_PATH) ? verify_lock_text(read(LOCK_PATH, String), _hashes()) : error("Execution Lock 018 is absent")

function main(args = ARGS)
    length(args) == 1 || error("usage: lock_financial_strategy_library_panel_v1_execution_018.jl --dry-run|--lock|--check")
    mode = only(args)
    mode == "--dry-run" && return println("Lock 018 dry run passed: ", dry_run())
    mode == "--lock" && return println("Lock 018 created: ", create_execution_lock_018())
    mode == "--check" && return println("Lock 018 valid: ", verify_execution_lock_018())
    error("unknown Lock 018 mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution018.main()
end
