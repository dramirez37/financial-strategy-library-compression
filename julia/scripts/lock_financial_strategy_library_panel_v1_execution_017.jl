module LockFinancialStrategyLibraryPanelV1Execution017

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_016.jl"))
const Lock016 = LockFinancialStrategyLibraryPanelV1Execution016

export create_execution_lock_017,
       dry_run,
       main,
       validate_execution_design_017,
       verify_execution_lock_017,
       verify_lock_text

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(REPOSITORY_ROOT, "experiments", "financial_strategy_library_panel_v1")
const CONFIG_PATH = joinpath(REPOSITORY_ROOT, "experiments", "configs", "financial_strategy_library_panel_v1.toml")
const AMENDMENT_PATH = joinpath(EXPERIMENT_ROOT, "amendments", "EXECUTION_AMENDMENT_017.toml")
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_016.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_017.json")
const DESIGN_AGGREGATE = Lock016.DESIGN_AGGREGATE
const PREDECESSOR_AGGREGATE = "afe87492ee4fd8b368f9052bddec85c43743a005575f26fb65146fffce33532c"
const PREDECESSOR_FILE_SHA256 = "c895737abc4b1190d69448c5293f82ff88c7b3d69008fc2dc40f47cd84a9760a"
const LOCK_015_AGGREGATE = "49c256ff1e61ef513ab656586c8b4e89c1e891959da21a7407135fe5810690de"
const DIRECTORY_AGGREGATE = "f63bb273afc4d6ed69fb12a2f7f35a84f8eb45822f1cce59dd06db90af0fcacc"
const RESULT_AGGREGATE = "79c6eef4f77ea173e7a119ef49454ccb20ccb1cb047581e0cb6dfd509fd19b34"

const REQUIRED_FILES = (
    Lock016.REQUIRED_FILES...,
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_016.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_017.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_017.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_017.jl",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text) = bytes2hex(sha256(codeunits(text)))

function _hashes()
    length(REQUIRED_FILES) == length(unique(REQUIRED_FILES)) || error("Lock 017 input list contains duplicates")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) || error("missing Lock 017 input: $relative")
    end
    return Dict(relative => _sha256_file(joinpath(REPOSITORY_ROOT, relative)) for relative in REQUIRED_FILES)
end

_aggregate(hashes) = _sha256_text(join(
    ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
))

function _verify_predecessor()
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 016 is absent")
    text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) || error("historical Lock 016 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 || error("historical Lock 016 file hash differs")
end

function validate_execution_design_017()
    _verify_predecessor()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] == "financial-strategy-library-panel-execution-amendment-v17" || error("unexpected Amendment 017 schema")
    amendment["amendment_id"] == "AMENDMENT_017" || error("unexpected Amendment 017 identifier")
    amendment["predecessor_amendment_id"] == "AMENDMENT_016" || error("unexpected Amendment 017 predecessor")
    amendment["classification"] == "resume_aggregate_namespace_correction" || error("Amendment 017 classification changed")
    amendment["postdecision_record_count"] == 180 || error("Amendment 017 record count changed")
    amendment["directory_relative_postdecision_aggregate_sha256"] == DIRECTORY_AGGREGATE || error("directory aggregate changed")
    amendment["result_root_relative_postdecision_aggregate_sha256"] == RESULT_AGGREGATE || error("result aggregate changed")
    for key in ("aggregate_file_bytes_identical", "aggregate_order_identical", "aggregate_key_namespace_only_difference")
        amendment[key] === true || error("Amendment 017 namespace declaration changed: $key")
    end
    for key in (
        "postdecision_numeric_values_inspected_before_amendment",
        "raw_row_values_printed_or_committed",
        "scientific_estimands_changed",
        "analysis_formulas_changed",
        "result_records_changed",
        "audit_predicates_changed",
    )
        amendment[key] === false || error("Amendment 017 declaration changed: $key")
    end
    amendment["new_postdecision_records_written_under_lock_016"] == 0 || error("Lock 016 wrote postdecision records")
    amendment["analysis_artifacts_before_amendment"] == 0 || error("analysis predates Amendment 017")
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
    record_count, aggregate = _directory_aggregate(joinpath(root, "postdecision"))
    record_count == 180 || error("Lock 017 requires 180 postdecision records")
    aggregate == DIRECTORY_AGGREGATE || error("Lock 017 directory aggregate differs")
    result = TOML.parsefile(joinpath(root, "RESULT_AUDIT.toml"))
    result["passed"] === true || error("result audit did not pass")
    result["execution_lock_aggregate_sha256"] == LOCK_015_AGGREGATE || error("result audit binding changed")
    result["postdecision_result_aggregate_sha256"] == RESULT_AGGREGATE || error("result audit aggregate changed")
    structural = TOML.parsefile(joinpath(root, "STRUCTURAL_AUDIT.toml"))
    structural["execution_lock_aggregate_sha256"] == PREDECESSOR_AGGREGATE || error("structural audit is not bound to Lock 016")
    environment = TOML.parsefile(joinpath(root, "ENVIRONMENT.toml"))
    environment["execution_lock_aggregate_sha256"] == LOCK_015_AGGREGATE || error("environment recovery state changed")
    isempty(_relative_files(joinpath(root, "analysis"))) || error("analysis artifacts predate Lock 017")
    temporary_count = sum(count(name -> occursin(".tmp.", name), names) for (_, _, names) in walkdir(root))
    temporary_count == 0 || error("temporary records predate Lock 017")
    public_root = joinpath(REPOSITORY_ROOT, String(config["paths"]["public_results_root"]))
    isempty(_relative_files(public_root)) || error("public results predate Lock 017")
end

function _render_lock(hashes)
    rows = join(("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))), ",\n")
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v17",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_017",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$PREDECESSOR_FILE_SHA256",
  "postdecision_record_count": 180,
  "directory_relative_postdecision_aggregate_sha256": "$DIRECTORY_AGGREGATE",
  "result_root_relative_postdecision_aggregate_sha256": "$RESULT_AGGREGATE",
  "result_records_changed": false,
  "scientific_estimands_changed": false,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    validate_execution_design_017()
    occursin("\"schema_version\": \"financial-strategy-library-panel-execution-lock-v17\"", text) || error("unexpected or missing Lock 017 schema")
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) || error("Lock 017 predecessor differs")
    occursin("\"directory_relative_postdecision_aggregate_sha256\": \"$DIRECTORY_AGGREGATE\"", text) || error("Lock 017 directory aggregate differs")
    occursin("\"result_root_relative_postdecision_aggregate_sha256\": \"$RESULT_AGGREGATE\"", text) || error("Lock 017 result aggregate differs")
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) || error("Lock 017 aggregate differs")
    for (relative, hash) in hashes
        occursin("\"$relative\": \"$hash\"", text) || error("Lock 017 file hash differs: $relative")
    end
    return aggregate
end

function dry_run()
    config = validate_execution_design_017()
    _assert_prelock_state(config)
    return _aggregate(_hashes())
end

function create_execution_lock_017()
    isfile(LOCK_PATH) && error("Execution Lock 017 already exists")
    config = validate_execution_design_017()
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

verify_execution_lock_017() = isfile(LOCK_PATH) ? verify_lock_text(read(LOCK_PATH, String), _hashes()) : error("Execution Lock 017 is absent")

function main(args = ARGS)
    length(args) == 1 || error("usage: lock_financial_strategy_library_panel_v1_execution_017.jl --dry-run|--lock|--check")
    mode = only(args)
    mode == "--dry-run" && return println("Lock 017 dry run passed: ", dry_run())
    mode == "--lock" && return println("Lock 017 created: ", create_execution_lock_017())
    mode == "--check" && return println("Lock 017 valid: ", verify_execution_lock_017())
    error("unknown Lock 017 mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution017.main()
end
