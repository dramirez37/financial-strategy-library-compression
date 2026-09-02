module LockFinancialStrategyLibraryPanelV2Execution005

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v2_design_002.jl"))
using .LockFinancialStrategyLibraryPanelV2Design002: verify_design_lock_002

export create_execution_lock_005, dry_run, verify_execution_lock_005

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v2",
)
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_strategy_library_panel_v2.toml",
)
const PREDECESSOR_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_004.json")
const DESIGN_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK_002.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_005.json")
const PREDECESSOR_AGGREGATE =
    "2693d24a4a219a76eee76e5cd354f3b0f89359f7ee60241d079b44db277c316a"
const DESIGN_AGGREGATE =
    "f0aa8fe0ba6ef46dd702656a6d00f5f067a38d17b424b2443699d19e213f5f54"
const RECOVERY_RESULTS = (
    "FAILED_ATTEMPT_001_ENVIRONMENT.toml",
    "FAILED_ATTEMPT_002_ENVIRONMENT.toml",
    "FAILED_ATTEMPT_002_SOURCE_AUDIT.toml",
    "FAILED_ATTEMPT_003_ENVIRONMENT.toml",
    "FAILED_ATTEMPT_003_SOURCE_AUDIT.toml",
    "FAILED_ATTEMPT_004_ENVIRONMENT.toml",
    "FAILED_ATTEMPT_004_SOURCE_AUDIT.toml",
)
const RECOVERY_CACHE_DIRECTORY = "FAILED_ATTEMPT_004_reference_series_partitions"
const REQUIRED_FILES = (
    "experiments/financial_strategy_library_panel_v2/DESIGN_LOCK.json",
    "experiments/financial_strategy_library_panel_v2/DESIGN_LOCK_002.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_LOCK.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_LOCK_002.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_LOCK_003.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_LOCK_004.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_PROTOCOL.md",
    "experiments/financial_strategy_library_panel_v2/amendments/DESIGN_AMENDMENT_001.md",
    "experiments/financial_strategy_library_panel_v2/amendments/DESIGN_AMENDMENT_001.toml",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_001.md",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_001.toml",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_002.md",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_002.toml",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_003.md",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_003.toml",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_004.md",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_004.toml",
    "julia/Project.toml",
    "julia/Manifest.toml",
    "julia/src/FinancialStrategyLibraryPanelV2Execution.jl",
    "julia/scripts/run_financial_strategy_library_panel_v2.jl",
    "julia/scripts/audit_financial_strategy_library_panel_v2.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v2_design_002.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v2_execution_005.jl",
    "julia/test/test_financial_strategy_library_panel_v2_execution.jl",
    "julia/test/run_financial_strategy_library_panel_v2_execution_tests.jl",
)

_sha256_text(text) = bytes2hex(sha256(codeunits(text)))
_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

function _hashes()
    hashes = Dict{String,String}()
    for relative in REQUIRED_FILES
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("missing execution-lock-005 input: $relative")
        hashes[relative] = _sha256_file(path)
    end
    for file in RECOVERY_RESULTS
        path = joinpath(EXPERIMENT_ROOT, "local_results", file)
        isfile(path) || error("missing recovery result: $file")
        hashes["local-result:$file"] = _sha256_file(path)
    end
    cache = joinpath(EXPERIMENT_ROOT, "local_data", RECOVERY_CACHE_DIRECTORY)
    for file in sort!(readdir(cache))
        path = joinpath(cache, file)
        isfile(path) || error("attempt-004 cache contains a non-file entry")
        hashes["local-cache:$RECOVERY_CACHE_DIRECTORY/$file"] = _sha256_file(path)
    end
    return hashes
end

function _sources()
    config = TOML.parsefile(CONFIG_PATH)
    source = config["source"]
    configured = String(source["repository_root_default"])
    root = haskey(ENV, "ALGOLIB_CRSP_ROOT") && !isempty(strip(ENV["ALGOLIB_CRSP_ROOT"])) ?
        normpath(ENV["ALGOLIB_CRSP_ROOT"]) : normpath(joinpath(REPOSITORY_ROOT, configured))
    roles = Pair{String,String}[
        "security_history" => joinpath(root, String(source["security_history"])),
    ]
    append!(
        roles,
        "daily_$index" => joinpath(root, String(path))
        for (index, path) in enumerate(source["daily_files"])
    )
    all(pair -> isfile(last(pair)), roles) || error("registered source file is absent")
    return [(
        role,
        byte_size = filesize(path),
        modified_unix_seconds = round(Int, stat(path).mtime),
    ) for (role, path) in roles]
end

function _aggregate(hashes, sources)
    rows = ["$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))]
    append!(
        rows,
        "source:$(source.role)\0$(source.byte_size)\0$(source.modified_unix_seconds)\n"
        for source in sources
    )
    return _sha256_text(join(rows))
end

function _preflight()
    verify_design_lock_002() == DESIGN_AGGREGATE || error("amended design lock changed")
    amendment = TOML.parsefile(joinpath(
        EXPERIMENT_ROOT,
        "amendments",
        "EXECUTION_AMENDMENT_004.toml",
    ))
    amendment["profile_support_computed_before_amendment"] === false ||
        error("profile-support boundary changed")
    amendment["scientific_estimand_changed"] === true || error("estimand disclosure changed")
    amendment["estimand_change_governed_by_design_amendment"] === true ||
        error("design-amendment linkage changed")
    for key in (
        "registered_seed_consumed_before_amendment",
        "candidate_score_observed_before_amendment",
        "arm_or_solver_outcome_observed_before_amendment",
        "postdecision_outcome_observed_before_amendment",
    )
        amendment[key] === false || error("outcome boundary changed: $key")
    end
    amendment["staging"]["master_market_panel_single_pass"] === true ||
        error("master-panel staging declaration changed")
    results = joinpath(EXPERIMENT_ROOT, "local_results")
    Set(readdir(results)) == Set(RECOVERY_RESULTS) || error("result recovery boundary changed")
    data = joinpath(EXPERIMENT_ROOT, "local_data")
    Set(readdir(data)) == Set([RECOVERY_CACHE_DIRECTORY]) || error("data recovery boundary changed")
    cache = joinpath(data, RECOVERY_CACHE_DIRECTORY)
    length(readdir(cache)) == 6 || error("attempt-004 cache file count changed")
    return true
end

function _render(hashes, sources)
    files = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    source_rows = join((
        "    {\"role\": \"$(source.role)\", \"byte_size\": $(source.byte_size), " *
        "\"modified_unix_seconds\": $(source.modified_unix_seconds)}"
        for source in sources
    ), ",\n")
    return """{
  "schema_version": "financial-strategy-library-panel-v2-execution-lock-v5",
  "experiment_id": "financial-strategy-library-panel-v2",
  "design_amendment_id": "DESIGN_AMENDMENT_001",
  "execution_amendment_id": "EXECUTION_AMENDMENT_004",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "predecessor_design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_design_lock_file_sha256": "$(_sha256_file(DESIGN_LOCK_PATH))",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$(_sha256_file(PREDECESSOR_PATH))",
  "data_quality_informed_design_amendment": true,
  "scientific_estimand_changed": true,
  "profile_support_computed_before_amendment": false,
  "candidate_score_observed_before_amendment": false,
  "registered_seed_consumed_before_amendment": false,
  "arm_or_solver_outcome_observed_before_amendment": false,
  "postdecision_outcome_observed_before_amendment": false,
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

function _verify(text, hashes, sources)
    aggregate = _aggregate(hashes, sources)
    occursin("\"predecessor_design_lock_aggregate_sha256\": \"$DESIGN_AGGREGATE\"", text) ||
        error("execution-lock-005 design predecessor mismatch")
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("execution-lock-005 execution predecessor mismatch")
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("execution-lock-005 aggregate mismatch")
    for (path, digest) in hashes
        occursin("\"$path\": \"$digest\"", text) ||
            error("execution-lock-005 file mismatch: $path")
    end
    return aggregate
end

function dry_run()
    _preflight()
    hashes = _hashes()
    sources = _sources()
    return _verify(_render(hashes, sources), hashes, sources)
end

function create_execution_lock_005()
    isfile(LOCK_PATH) && error("execution lock 005 already exists")
    _preflight()
    hashes = _hashes()
    sources = _sources()
    text = _render(hashes, sources)
    _verify(text, hashes, sources)
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, LOCK_PATH; force = false)
    return LOCK_PATH
end

function verify_execution_lock_005()
    isfile(LOCK_PATH) || error("execution lock 005 is absent")
    _preflight()
    hashes = _hashes()
    sources = _sources()
    return _verify(read(LOCK_PATH, String), hashes, sources)
end

end

