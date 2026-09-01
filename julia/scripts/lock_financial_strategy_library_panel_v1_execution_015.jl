module LockFinancialStrategyLibraryPanelV1Execution015

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_014.jl"))
const Lock014 = LockFinancialStrategyLibraryPanelV1Execution014

export create_execution_lock_015,
       dry_run,
       main,
       validate_execution_design_015,
       verify_execution_lock_015,
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
    "EXECUTION_AMENDMENT_015.toml",
)
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_014.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_015.json")
const DESIGN_AGGREGATE = Lock014.DESIGN_AGGREGATE
const PREDECESSOR_AGGREGATE =
    "993b6af47f6e027a273bb8b3fb5d102b7e9708f696719b6b7a3b575e46edba90"
const PREDECESSOR_FILE_SHA256 =
    "a0bf34e00f00216fb966e5b389e235b792347f8b2f720846acf10552bbfbbb54"
const STRUCTURAL_RESULT_AGGREGATE = Lock014.STRUCTURAL_RESULT_AGGREGATE
const PRELOCK_POSTDECISION_AGGREGATE = Lock014.PRELOCK_POSTDECISION_AGGREGATE
const AFFECTED_ORIGIN_SET_SHA256 = Lock014.AFFECTED_ORIGIN_SET_SHA256

const REQUIRED_FILES = (
    Lock014.REQUIRED_FILES...,
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_014.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_015.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_015.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_015.jl",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text) = bytes2hex(sha256(codeunits(text)))

function _hashes()
    length(REQUIRED_FILES) == length(unique(REQUIRED_FILES)) ||
        error("Lock 015 input list contains duplicates")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) ||
            error("missing Lock 015 input: $relative")
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
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 014 is absent")
    text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("historical Lock 014 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 ||
        error("historical Lock 014 file hash differs")
    return nothing
end

function validate_execution_design_015()
    _verify_predecessor()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v15" ||
        error("unexpected Amendment 015 schema")
    amendment["amendment_id"] == "AMENDMENT_015" ||
        error("unexpected Amendment 015 identifier")
    amendment["predecessor_amendment_id"] == "AMENDMENT_014" ||
        error("unexpected Amendment 015 predecessor")
    amendment["classification"] == "semantics_preserving_execution_optimization" ||
        error("Amendment 015 classification changed")
    for (key, expected) in (
        "lock_014_profile_preflight_completed_lanes" => 0,
        "new_postdecision_records_written_under_lock_014" => 0,
        "postdecision_result_records_before_amendment" => 108,
        "final_result_audit_files_before_amendment" => 0,
        "analysis_artifacts_before_amendment" => 0,
    )
        amendment[key] == expected || error("Amendment 015 disclosure changed: $key")
    end
    for key in (
        "postdecision_numeric_values_inspected_before_amendment",
        "selected_identity_or_burden_result_inspected_before_amendment",
        "solver_status_inspected_before_amendment",
        "raw_row_values_printed_or_committed",
        "scientific_estimands_changed",
        "minimum_profile_observations_changed",
        "affected_origin_rule_changed",
        "expected_unavailable_counts_changed",
        "audit_predicates_changed",
    )
        amendment[key] === false || error("Amendment 015 declaration changed: $key")
    end
    equivalence = amendment["count_equivalence"]
    equivalence["minimum_observations_per_belief"] == 25 ||
        error("Amendment 015 profile minimum changed")
    equivalence["one_instance_per_library_construction"] === true ||
        error("Amendment 015 library deduplication changed")
    equivalence["schedule_specific_instance_hashing"] === false ||
        error("Amendment 015 re-enables schedule-specific hashing")
    equivalence["full_strategy_backtest_in_preflight"] === false ||
        error("Amendment 015 re-enables full preflight backtests")
    equivalence["complete_evaluation_after_passing_preflight"] === true ||
        error("Amendment 015 disables complete evaluation after preflight")
    config = TOML.parsefile(CONFIG_PATH)
    config["operating_profiles"]["minimum_profile_observations"] == 25 ||
        error("configuration profile minimum changed")
    return config
end

function _relative_files(root)
    isdir(root) || return String[]
    files = String[]
    for (directory, _, names) in walkdir(root), name in names
        push!(files, relpath(joinpath(directory, name), root))
    end
    return sort!(files)
end

function _postdecision_aggregate(postdecision, files)
    hashes = Dict(relpath(path, postdecision) => _sha256_file(path) for path in files)
    return _aggregate(hashes)
end

function _assert_prelock_state(config)
    local_results = joinpath(
        REPOSITORY_ROOT,
        String(config["paths"]["local_results_root"]),
    )
    postdecision = joinpath(local_results, "postdecision")
    files = sort!(String[
        joinpath(postdecision, name) for name in readdir(postdecision) if endswith(name, ".toml")
    ])
    length(files) == 108 || error("Lock 015 requires 108 postdecision records")
    _postdecision_aggregate(postdecision, files) == PRELOCK_POSTDECISION_AGGREGATE ||
        error("Lock 015 preexisting postdecision aggregate differs")
    expected = Lock014._registered_stems()
    existing = Set(first(splitext(basename(path))) for path in files)
    missing = String[stem for stem in expected if !(stem in existing)]
    missing_by_origin = Dict{String,Int}()
    for stem in missing
        origin_id = first(split(stem, "__"))
        missing_by_origin[origin_id] = get(missing_by_origin, origin_id, 0) + 1
    end
    length(missing) == 72 && length(missing_by_origin) == 8 &&
    all(==(9), values(missing_by_origin)) ||
        error("Lock 015 unresolved keys are not eight complete origin blocks")
    _sha256_text(join(sort!(collect(keys(missing_by_origin))), '\n')) ==
    AFFECTED_ORIGIN_SET_SHA256 || error("Lock 015 unresolved origin-set hash differs")
    isfile(joinpath(local_results, "RESULT_AUDIT.toml")) &&
        error("final result audit predates Lock 015")
    isempty(_relative_files(joinpath(local_results, "analysis"))) ||
        error("analysis artifacts predate Lock 015")
    temporary_count = sum(
        count(name -> occursin(".tmp.", name), names) for
        (_, _, names) in walkdir(local_results)
    )
    temporary_count == 0 || error("temporary records predate Lock 015")
    structural = TOML.parsefile(joinpath(local_results, "STRUCTURAL_AUDIT.toml"))
    structural["passed"] === true || error("structural audit did not pass")
    structural["execution_lock_aggregate_sha256"] == PREDECESSOR_AGGREGATE ||
        error("structural audit is not bound to Lock 014")
    structural["structural_result_aggregate_sha256"] == STRUCTURAL_RESULT_AGGREGATE ||
        error("structural result aggregate differs")
    environment = TOML.parsefile(joinpath(local_results, "ENVIRONMENT.toml"))
    environment["execution_lock_aggregate_sha256"] == PREDECESSOR_AGGREGATE ||
        error("environment is not bound to Lock 014")
    public_results = joinpath(
        REPOSITORY_ROOT,
        String(config["paths"]["public_results_root"]),
    )
    isempty(_relative_files(public_results)) || error("public results predate Lock 015")
    return nothing
end

function _render_lock(hashes)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v15",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_015",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$PREDECESSOR_FILE_SHA256",
  "lock_014_completed_profile_preflight_lanes": 0,
  "new_postdecision_records_under_lock_014": 0,
  "postdecision_records_before_successor_lock": 108,
  "minimum_profile_observations": 25,
  "count_only_preflight": true,
  "full_strategy_backtest_in_preflight": false,
  "postdecision_numeric_values_inspected_before_successor_lock": false,
  "scientific_estimands_changed": false,
  "preexisting_postdecision_result_aggregate_sha256": "$PRELOCK_POSTDECISION_AGGREGATE",
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    validate_execution_design_015()
    occursin("\"schema_version\": \"financial-strategy-library-panel-execution-lock-v15\"", text) ||
        error("unexpected or missing Lock 015 schema")
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("Lock 015 predecessor aggregate differs")
    occursin("\"count_only_preflight\": true", text) ||
        error("Lock 015 count-only declaration differs")
    for declaration in (
        "full_strategy_backtest_in_preflight",
        "postdecision_numeric_values_inspected_before_successor_lock",
        "scientific_estimands_changed",
    )
        occursin("\"$declaration\": false", text) ||
            error("invalid Lock 015 declaration: $declaration")
    end
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("Lock 015 aggregate differs")
    for (relative, hash) in hashes
        occursin("\"$relative\": \"$hash\"", text) ||
            error("Lock 015 file hash differs: $relative")
    end
    return aggregate
end


function dry_run()
    config = validate_execution_design_015()
    _assert_prelock_state(config)
    return _aggregate(_hashes())
end

function create_execution_lock_015()
    isfile(LOCK_PATH) && error("Execution Lock 015 already exists")
    config = validate_execution_design_015()
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

function verify_execution_lock_015()
    isfile(LOCK_PATH) || error("Execution Lock 015 is absent")
    return verify_lock_text(read(LOCK_PATH, String), _hashes())
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v1_execution_015.jl --dry-run|--lock|--check",
    )
    mode = only(args)
    mode == "--dry-run" && return println("Lock 015 dry run passed: ", dry_run())
    mode == "--lock" && return println("Lock 015 created: ", create_execution_lock_015())
    mode == "--check" && return println("Lock 015 valid: ", verify_execution_lock_015())
    error("unknown Lock 015 mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution015.main()
end
