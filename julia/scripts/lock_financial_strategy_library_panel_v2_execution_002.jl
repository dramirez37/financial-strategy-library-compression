module LockFinancialStrategyLibraryPanelV2Execution002

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v2.jl"))
using .LockFinancialStrategyLibraryPanelV2: verify_design_lock

export create_execution_lock_002, dry_run, verify_execution_lock_002, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const CONFIG_PATH = joinpath(REPOSITORY_ROOT, "experiments", "configs", "financial_strategy_library_panel_v2.toml")
const EXPERIMENT_ROOT = joinpath(REPOSITORY_ROOT, "experiments", "financial_strategy_library_panel_v2")
const PREDECESSOR_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_002.json")
const FAILURE_RECORD = joinpath(EXPERIMENT_ROOT, "local_results", "FAILED_ATTEMPT_001_ENVIRONMENT.toml")
const PREDECESSOR_AGGREGATE = "9490af81fd3578d610af6b3618a035be5842f2a3b9fe5aeaa0de45e1b8dae99d"
const REQUIRED_FILES = (
    "experiments/financial_strategy_library_panel_v2/DESIGN_LOCK.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_LOCK.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_PROTOCOL.md",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_001.md",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_001.toml",
    "julia/Project.toml",
    "julia/Manifest.toml",
    "julia/src/FinancialStrategyLibraryPanelV2Execution.jl",
    "julia/scripts/run_financial_strategy_library_panel_v2.jl",
    "julia/scripts/audit_financial_strategy_library_panel_v2.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v2_execution_002.jl",
    "julia/test/test_financial_strategy_library_panel_v2_execution.jl",
    "julia/test/run_financial_strategy_library_panel_v2_execution_tests.jl",
)

_sha256_text(text) = bytes2hex(sha256(codeunits(text)))
_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

function _hashes()
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) || error("missing lock-002 input: $relative")
    end
    isfile(FAILURE_RECORD) || error("preserved failed-attempt environment is absent")
    hashes = Dict(relative => _sha256_file(joinpath(REPOSITORY_ROOT, relative)) for relative in REQUIRED_FILES)
    hashes["local:FAILED_ATTEMPT_001_ENVIRONMENT.toml"] = _sha256_file(FAILURE_RECORD)
    return hashes
end

function _source_metadata()
    config = TOML.parsefile(CONFIG_PATH)
    source = config["source"]
    configured = String(source["repository_root_default"])
    root = if haskey(ENV, "ALGOLIB_CRSP_ROOT") && !isempty(strip(ENV["ALGOLIB_CRSP_ROOT"]))
        value = ENV["ALGOLIB_CRSP_ROOT"]
        isabspath(value) ? normpath(value) : normpath(joinpath(REPOSITORY_ROOT, value))
    else
        normpath(joinpath(REPOSITORY_ROOT, configured))
    end
    roles = Pair{String,String}["security_history" => joinpath(root, String(source["security_history"]))]
    append!(roles, "daily_$index" => joinpath(root, String(path)) for (index, path) in enumerate(source["daily_files"]))
    all(pair -> isfile(last(pair)), roles) || error("registered source file is absent")
    return [(role, byte_size = filesize(path), modified_unix_seconds = round(Int, stat(path).mtime)) for (role, path) in roles]
end

function _aggregate(hashes, sources)
    rows = ["$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))]
    append!(rows, "source:$(item.role)\0$(item.byte_size)\0$(item.modified_unix_seconds)\n" for item in sources)
    return _sha256_text(join(rows))
end

function _validate_amendment()
    amendment = TOML.parsefile(joinpath(EXPERIMENT_ROOT, "amendments", "EXECUTION_AMENDMENT_001.toml"))
    for key in (
        "licensed_daily_data_row_parsed_before_amendment",
        "universe_constructed_before_amendment",
        "registered_seed_consumed_before_amendment",
        "candidate_score_observed_before_amendment",
        "arm_or_solver_outcome_observed_before_amendment",
        "postdecision_outcome_observed_before_amendment",
        "scientific_estimand_changed",
        "eligibility_rule_changed",
        "registry_changed",
        "information_firewall_changed",
    )
        amendment[key] === false || error("amendment declaration changed: $key")
    end
    amendment["correction"]["drain_compressed_schema_stream_after_header"] === true ||
        error("amendment does not specify the header drain")
    return amendment
end

function _assert_recovery_boundary(config)
    results = joinpath(REPOSITORY_ROOT, String(config["paths"]["local_results_root"]))
    Set(readdir(results)) == Set(["FAILED_ATTEMPT_001_ENVIRONMENT.toml"]) ||
        error("recovery result root contains more than the preserved failed-attempt record")
    data = joinpath(REPOSITORY_ROOT, String(config["paths"]["local_data_root"]))
    ispath(data) && !isempty(readdir(data)) && error("local data exist before lock 002")
    public = joinpath(REPOSITORY_ROOT, String(config["paths"]["public_results_root"]))
    ispath(public) && !isempty(readdir(public)) && error("public results exist before lock 002")
    return true
end

function _render(hashes, sources, design_predecessor)
    file_rows = join(("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))), ",\n")
    source_rows = join((
        "    {\"role\": \"$(item.role)\", \"byte_size\": $(item.byte_size), \"modified_unix_seconds\": $(item.modified_unix_seconds)}"
        for item in sources
    ), ",\n")
    return """{
  "schema_version": "financial-strategy-library-panel-v2-execution-lock-v2",
  "experiment_id": "financial-strategy-library-panel-v2",
  "amendment_id": "EXECUTION_AMENDMENT_001",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "predecessor_design_lock_aggregate_sha256": "$design_predecessor",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$(_sha256_file(PREDECESSOR_PATH))",
  "licensed_daily_header_parsed_before_amendment": true,
  "licensed_daily_data_row_parsed_before_amendment": false,
  "universe_constructed_before_amendment": false,
  "candidate_score_observed_before_amendment": false,
  "arm_or_solver_outcome_observed_before_amendment": false,
  "postdecision_outcome_observed_before_amendment": false,
  "scientific_estimand_changed": false,
  "aggregate_sha256": "$(_aggregate(hashes, sources))",
  "source_stat_fingerprints": [
$source_rows
  ],
  "files": {
$file_rows
  }
}
"""
end

function _verify(text, hashes, sources, design_predecessor)
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("lock 002 predecessor aggregate mismatch")
    occursin("\"predecessor_design_lock_aggregate_sha256\": \"$design_predecessor\"", text) ||
        error("lock 002 design predecessor mismatch")
    for declaration in (
        "licensed_daily_data_row_parsed_before_amendment",
        "universe_constructed_before_amendment",
        "candidate_score_observed_before_amendment",
        "arm_or_solver_outcome_observed_before_amendment",
        "postdecision_outcome_observed_before_amendment",
        "scientific_estimand_changed",
    )
        occursin("\"$declaration\": false", text) || error("lock 002 declaration changed: $declaration")
    end
    aggregate = _aggregate(hashes, sources)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) || error("lock 002 aggregate mismatch")
    for (path, digest) in hashes
        occursin("\"$path\": \"$digest\"", text) || error("lock 002 file mismatch: $path")
    end
    return aggregate
end

function dry_run()
    design = verify_design_lock()
    _validate_amendment()
    config = TOML.parsefile(CONFIG_PATH)
    _assert_recovery_boundary(config)
    hashes = _hashes()
    sources = _source_metadata()
    return _verify(_render(hashes, sources, design), hashes, sources, design)
end

function create_execution_lock_002()
    isfile(LOCK_PATH) && error("execution lock 002 already exists")
    design = verify_design_lock()
    _validate_amendment()
    config = TOML.parsefile(CONFIG_PATH)
    _assert_recovery_boundary(config)
    hashes = _hashes()
    sources = _source_metadata()
    text = _render(hashes, sources, design)
    _verify(text, hashes, sources, design)
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, LOCK_PATH; force = false)
    return LOCK_PATH
end

function verify_execution_lock_002()
    isfile(LOCK_PATH) || error("execution lock 002 is absent")
    design = verify_design_lock()
    return _verify(read(LOCK_PATH, String), _hashes(), _source_metadata(), design)
end

function main(args = ARGS)
    length(args) == 1 || error("usage: lock_financial_strategy_library_panel_v2_execution_002.jl --dry-run|--create|--check")
    mode = only(args)
    mode == "--dry-run" && return println("lock 002 dry run valid: $(dry_run())")
    mode == "--create" && return println("created lock 002: $(create_execution_lock_002())")
    mode == "--check" && return println("lock 002 valid: $(verify_execution_lock_002())")
    error("unknown lock-002 mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV2Execution002.main()
end
