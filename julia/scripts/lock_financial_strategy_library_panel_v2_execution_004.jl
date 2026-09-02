module LockFinancialStrategyLibraryPanelV2Execution004

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v2.jl"))
using .LockFinancialStrategyLibraryPanelV2: verify_design_lock

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const CONFIG_PATH = joinpath(REPOSITORY_ROOT, "experiments", "configs", "financial_strategy_library_panel_v2.toml")
const EXPERIMENT_ROOT = joinpath(REPOSITORY_ROOT, "experiments", "financial_strategy_library_panel_v2")
const PREDECESSOR_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_003.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_004.json")
const PREDECESSOR_AGGREGATE = "e80982a605f4a435bdedcf9c9a07e8bc4bfb538a3198528c3fec6e9c69449bf8"
const RECOVERY_FILES = (
    "FAILED_ATTEMPT_001_ENVIRONMENT.toml",
    "FAILED_ATTEMPT_002_ENVIRONMENT.toml",
    "FAILED_ATTEMPT_002_SOURCE_AUDIT.toml",
    "FAILED_ATTEMPT_003_ENVIRONMENT.toml",
    "FAILED_ATTEMPT_003_SOURCE_AUDIT.toml",
)
const REQUIRED_FILES = (
    "experiments/financial_strategy_library_panel_v2/DESIGN_LOCK.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_LOCK.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_LOCK_002.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_LOCK_003.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_PROTOCOL.md",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_001.md",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_001.toml",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_002.md",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_002.toml",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_003.md",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_003.toml",
    "julia/Project.toml",
    "julia/Manifest.toml",
    "julia/src/FinancialStrategyLibraryPanelV2Execution.jl",
    "julia/scripts/run_financial_strategy_library_panel_v2.jl",
    "julia/scripts/audit_financial_strategy_library_panel_v2.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v2_execution_004.jl",
    "julia/test/test_financial_strategy_library_panel_v2_execution.jl",
    "julia/test/run_financial_strategy_library_panel_v2_execution_tests.jl",
)

_sha256_text(text) = bytes2hex(sha256(codeunits(text)))
_sha256_file(path) = open(path, "r") do io; bytes2hex(sha256(io)); end

function _hashes()
    hashes = Dict{String,String}()
    for relative in REQUIRED_FILES
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("missing lock-004 input: $relative")
        hashes[relative] = _sha256_file(path)
    end
    for file in RECOVERY_FILES
        path = joinpath(EXPERIMENT_ROOT, "local_results", file)
        isfile(path) || error("missing recovery record: $file")
        hashes["local:$file"] = _sha256_file(path)
    end
    return hashes
end

function _sources()
    config = TOML.parsefile(CONFIG_PATH); source = config["source"]
    configured = String(source["repository_root_default"])
    root = haskey(ENV, "ALGOLIB_CRSP_ROOT") && !isempty(strip(ENV["ALGOLIB_CRSP_ROOT"])) ?
        normpath(ENV["ALGOLIB_CRSP_ROOT"]) : normpath(joinpath(REPOSITORY_ROOT, configured))
    roles = Pair{String,String}["security_history" => joinpath(root, String(source["security_history"]))]
    append!(roles, "daily_$i" => joinpath(root, String(path)) for (i, path) in enumerate(source["daily_files"]))
    all(pair -> isfile(last(pair)), roles) || error("registered source file is absent")
    return [(role, byte_size = filesize(path), modified_unix_seconds = round(Int, stat(path).mtime)) for (role, path) in roles]
end

function _aggregate(hashes, sources)
    rows = ["$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))]
    append!(rows, "source:$(s.role)\0$(s.byte_size)\0$(s.modified_unix_seconds)\n" for s in sources)
    return _sha256_text(join(rows))
end

function _preflight()
    design = verify_design_lock()
    amendment = TOML.parsefile(joinpath(EXPERIMENT_ROOT, "amendments", "EXECUTION_AMENDMENT_003.toml"))
    amendment["provisional_liquidity_candidates_computed_in_memory_before_amendment"] === true || error("amendment disclosure changed")
    for key in ("local_origin_data_written_before_amendment", "profile_support_computed_before_amendment", "registered_seed_consumed_before_amendment", "candidate_score_observed_before_amendment", "arm_or_solver_outcome_observed_before_amendment", "postdecision_outcome_observed_before_amendment", "scientific_estimand_changed")
        amendment[key] === false || error("amendment declaration changed: $key")
    end
    amendment["correction"]["value_or_order_change"] === false || error("return-shape correction changes values")
    config = TOML.parsefile(CONFIG_PATH)
    results = joinpath(REPOSITORY_ROOT, String(config["paths"]["local_results_root"]))
    Set(readdir(results)) == Set(RECOVERY_FILES) || error("result root exceeds lock-004 recovery boundary")
    data = joinpath(REPOSITORY_ROOT, String(config["paths"]["local_data_root"]))
    ispath(data) && !isempty(readdir(data)) && error("local data exist before lock 004")
    return design
end

function _render(hashes, sources, design)
    files = join(("    \"$p\": \"$(hashes[p])\"" for p in sort!(collect(keys(hashes)))), ",\n")
    source_rows = join(("    {\"role\": \"$(s.role)\", \"byte_size\": $(s.byte_size), \"modified_unix_seconds\": $(s.modified_unix_seconds)}" for s in sources), ",\n")
    return """{
  "schema_version": "financial-strategy-library-panel-v2-execution-lock-v4",
  "experiment_id": "financial-strategy-library-panel-v2",
  "amendment_id": "EXECUTION_AMENDMENT_003",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "predecessor_design_lock_aggregate_sha256": "$design",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$(_sha256_file(PREDECESSOR_PATH))",
  "provisional_liquidity_candidates_computed_in_memory_before_amendment": true,
  "local_origin_data_written_before_amendment": false,
  "profile_support_computed_before_amendment": false,
  "registered_seed_consumed_before_amendment": false,
  "candidate_score_observed_before_amendment": false,
  "arm_or_solver_outcome_observed_before_amendment": false,
  "postdecision_outcome_observed_before_amendment": false,
  "scientific_estimand_changed": false,
  "aggregate_sha256": "$(_aggregate(hashes, sources))",
  "source_stat_fingerprints": [
$source_rows
  ],
  "files": {
$files
  }
}
"""
end

function _verify(text, hashes, sources, design)
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) || error("lock 004 predecessor mismatch")
    occursin("\"predecessor_design_lock_aggregate_sha256\": \"$design\"", text) || error("lock 004 design mismatch")
    aggregate = _aggregate(hashes, sources)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) || error("lock 004 aggregate mismatch")
    for (path, digest) in hashes
        occursin("\"$path\": \"$digest\"", text) || error("lock 004 file mismatch: $path")
    end
    return aggregate
end

function dry_run()
    design = _preflight(); hashes = _hashes(); sources = _sources()
    return _verify(_render(hashes, sources, design), hashes, sources, design)
end

function create_execution_lock_004()
    isfile(LOCK_PATH) && error("execution lock 004 already exists")
    design = _preflight(); hashes = _hashes(); sources = _sources(); text = _render(hashes, sources, design)
    _verify(text, hashes, sources, design)
    temporary = LOCK_PATH * ".tmp.$(getpid())"; open(temporary, "w") do io; write(io, text); end
    mv(temporary, LOCK_PATH; force = false); return LOCK_PATH
end

function verify_execution_lock_004()
    isfile(LOCK_PATH) || error("execution lock 004 is absent")
    design = verify_design_lock(); return _verify(read(LOCK_PATH, String), _hashes(), _sources(), design)
end

function main(args = ARGS)
    length(args) == 1 || error("usage: lock_financial_strategy_library_panel_v2_execution_004.jl --dry-run|--create|--check")
    mode = only(args)
    mode == "--dry-run" && return println("lock 004 dry run valid: $(dry_run())")
    mode == "--create" && return println("created lock 004: $(create_execution_lock_004())")
    mode == "--check" && return println("lock 004 valid: $(verify_execution_lock_004())")
    error("unknown lock-004 mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV2Execution004.main()
end
