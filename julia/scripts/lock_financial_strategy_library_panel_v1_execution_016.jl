module LockFinancialStrategyLibraryPanelV1Execution016

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_015.jl"))
const Lock015 = LockFinancialStrategyLibraryPanelV1Execution015

export create_execution_lock_016,
       dry_run,
       main,
       validate_execution_design_016,
       verify_execution_lock_016,
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
    "EXECUTION_AMENDMENT_016.toml",
)
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_015.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_016.json")
const DESIGN_AGGREGATE = Lock015.DESIGN_AGGREGATE
const PREDECESSOR_AGGREGATE =
    "49c256ff1e61ef513ab656586c8b4e89c1e891959da21a7407135fe5810690de"
const PREDECESSOR_FILE_SHA256 =
    "0e0a0511a74caaa7fee25e0ab65d779e43363cfd802754c5e982d32e8564db4d"
const STRUCTURAL_RESULT_AGGREGATE =
    "9564a4c9b0ea28f4cf4a9705e8e489398555032e466ba3fac8c16a98094a012a"
const POSTDECISION_RESULT_AGGREGATE =
    "79c6eef4f77ea173e7a119ef49454ccb20ccb1cb047581e0cb6dfd509fd19b34"
const RESULT_AUDIT_FILE_SHA256 =
    "a0fe009066d010e92c6d0ce846c9746b6c1dd9a70895841a1c3826883ce1ef6f"

const REQUIRED_FILES = (
    Lock015.REQUIRED_FILES...,
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_015.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_016.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_016.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_016.jl",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text) = bytes2hex(sha256(codeunits(text)))

function _hashes()
    length(REQUIRED_FILES) == length(unique(REQUIRED_FILES)) ||
        error("Lock 016 input list contains duplicates")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) ||
            error("missing Lock 016 input: $relative")
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
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 015 is absent")
    text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("historical Lock 015 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 ||
        error("historical Lock 015 file hash differs")
    return nothing
end

function validate_execution_design_016()
    _verify_predecessor()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v16" ||
        error("unexpected Amendment 016 schema")
    amendment["amendment_id"] == "AMENDMENT_016" ||
        error("unexpected Amendment 016 identifier")
    amendment["predecessor_amendment_id"] == "AMENDMENT_015" ||
        error("unexpected Amendment 016 predecessor")
    amendment["classification"] == "julia_1_12_analysis_shape_correction" ||
        error("Amendment 016 classification changed")
    for (key, expected) in (
        "postdecision_result_records_before_amendment" => 180,
        "postdecision_result_aggregate_sha256" => POSTDECISION_RESULT_AGGREGATE,
        "structural_result_aggregate_sha256" => STRUCTURAL_RESULT_AGGREGATE,
        "structural_failure_records" => 72,
        "terminal_dp_unavailable_records" => 9,
        "profile_unavailable_records" => 72,
        "ordinary_postdecision_records" => 27,
        "registered_algorithm_rows_retained" => 1260,
        "analysis_artifacts_before_amendment" => 0,
    )
        amendment[key] == expected || error("Amendment 016 disclosure changed: $key")
    end
    amendment["result_audit_passed_before_amendment"] === true ||
        error("Amendment 016 must bind the passing result audit")
    for key in (
        "postdecision_numeric_values_inspected_before_amendment",
        "selected_identity_or_burden_result_inspected_before_amendment",
        "solver_status_inspected_before_amendment",
        "raw_row_values_printed_or_committed",
        "scientific_estimands_changed",
        "analysis_formulas_changed",
        "registered_keys_changed",
        "registered_key_order_changed",
        "result_records_changed",
        "audit_predicates_changed",
    )
        amendment[key] === false || error("Amendment 016 declaration changed: $key")
    end
    correction = amendment["shape_correction"]
    correction["registered_key_count"] == 180 || error("analysis key count changed")
    correction["original_comprehension_dimensions"] == 3 ||
        error("analysis comprehension shape disclosure changed")
    correction["flatten_with_vec_before_sort"] === true ||
        error("analysis shape correction changed")
    correction["stable_lexicographic_order"] === true ||
        error("analysis key ordering changed")
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

function _postdecision_aggregate(postdecision)
    hashes = Dict{String,String}()
    for name in readdir(postdecision)
        endswith(name, ".toml") || continue
        hashes[joinpath("postdecision", name)] = _sha256_file(joinpath(postdecision, name))
    end
    return length(hashes), _aggregate(hashes)
end

function _assert_prelock_state(config)
    local_results = joinpath(
        REPOSITORY_ROOT,
        String(config["paths"]["local_results_root"]),
    )
    record_count, aggregate = _postdecision_aggregate(joinpath(local_results, "postdecision"))
    record_count == 180 || error("Lock 016 requires 180 postdecision records")
    aggregate == POSTDECISION_RESULT_AGGREGATE ||
        error("Lock 016 postdecision result aggregate differs")
    result_audit_path = joinpath(local_results, "RESULT_AUDIT.toml")
    _sha256_file(result_audit_path) == RESULT_AUDIT_FILE_SHA256 ||
        error("Lock 016 result-audit file hash differs")
    result_audit = TOML.parsefile(result_audit_path)
    result_audit["passed"] === true || error("result audit did not pass")
    result_audit["execution_lock_aggregate_sha256"] == PREDECESSOR_AGGREGATE ||
        error("result audit is not bound to Lock 015")
    result_audit["postdecision_result_aggregate_sha256"] ==
    POSTDECISION_RESULT_AGGREGATE || error("result audit aggregate differs")
    result_audit["registered_algorithm_terminal_rows"] == 1260 ||
        error("result audit denominator differs")
    result_audit["postdecision_profile_unavailable_instance_count"] == 72 ||
        error("result audit profile-unavailable count differs")
    isempty(_relative_files(joinpath(local_results, "analysis"))) ||
        error("analysis artifacts predate Lock 016")
    temporary_count = sum(
        count(name -> occursin(".tmp.", name), names) for
        (_, _, names) in walkdir(local_results)
    )
    temporary_count == 0 || error("temporary records predate Lock 016")
    structural = TOML.parsefile(joinpath(local_results, "STRUCTURAL_AUDIT.toml"))
    structural["execution_lock_aggregate_sha256"] == PREDECESSOR_AGGREGATE ||
        error("structural audit is not bound to Lock 015")
    environment = TOML.parsefile(joinpath(local_results, "ENVIRONMENT.toml"))
    environment["execution_lock_aggregate_sha256"] == PREDECESSOR_AGGREGATE ||
        error("environment is not bound to Lock 015")
    public_results = joinpath(
        REPOSITORY_ROOT,
        String(config["paths"]["public_results_root"]),
    )
    isempty(_relative_files(public_results)) || error("public results predate Lock 016")
    return nothing
end

function _render_lock(hashes)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v16",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_016",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$PREDECESSOR_FILE_SHA256",
  "audited_postdecision_record_count": 180,
  "audited_postdecision_result_aggregate_sha256": "$POSTDECISION_RESULT_AGGREGATE",
  "registered_analysis_key_count": 180,
  "flatten_key_array_before_sort": true,
  "analysis_artifacts_before_successor_lock": 0,
  "postdecision_numeric_values_inspected_before_successor_lock": false,
  "scientific_estimands_changed": false,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    validate_execution_design_016()
    occursin("\"schema_version\": \"financial-strategy-library-panel-execution-lock-v16\"", text) ||
        error("unexpected or missing Lock 016 schema")
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("Lock 016 predecessor aggregate differs")
    occursin("\"audited_postdecision_result_aggregate_sha256\": \"$POSTDECISION_RESULT_AGGREGATE\"", text) ||
        error("Lock 016 audited-result aggregate differs")
    occursin("\"flatten_key_array_before_sort\": true", text) ||
        error("Lock 016 shape correction differs")
    for declaration in (
        "postdecision_numeric_values_inspected_before_successor_lock",
        "scientific_estimands_changed",
    )
        occursin("\"$declaration\": false", text) ||
            error("invalid Lock 016 declaration: $declaration")
    end
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("Lock 016 aggregate differs")
    for (relative, hash) in hashes
        occursin("\"$relative\": \"$hash\"", text) ||
            error("Lock 016 file hash differs: $relative")
    end
    return aggregate
end

function dry_run()
    config = validate_execution_design_016()
    _assert_prelock_state(config)
    return _aggregate(_hashes())
end

function create_execution_lock_016()
    isfile(LOCK_PATH) && error("Execution Lock 016 already exists")
    config = validate_execution_design_016()
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

function verify_execution_lock_016()
    isfile(LOCK_PATH) || error("Execution Lock 016 is absent")
    return verify_lock_text(read(LOCK_PATH, String), _hashes())
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v1_execution_016.jl --dry-run|--lock|--check",
    )
    mode = only(args)
    mode == "--dry-run" && return println("Lock 016 dry run passed: ", dry_run())
    mode == "--lock" && return println("Lock 016 created: ", create_execution_lock_016())
    mode == "--check" && return println("Lock 016 valid: ", verify_execution_lock_016())
    error("unknown Lock 016 mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution016.main()
end
