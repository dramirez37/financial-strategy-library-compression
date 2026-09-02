module LockFinancialStrategyLibraryPanelV2Execution006

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v2_design_002.jl"))
using .LockFinancialStrategyLibraryPanelV2Design002: verify_design_lock_002

export create_execution_lock_006, dry_run, verify_execution_lock_006

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(REPOSITORY_ROOT, "experiments", "financial_strategy_library_panel_v2")
const CONFIG_PATH = joinpath(REPOSITORY_ROOT, "experiments", "configs", "financial_strategy_library_panel_v2.toml")
const PREDECESSOR_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_005.json")
const DESIGN_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK_002.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_006.json")
const PREDECESSOR_AGGREGATE =
    "3d8f6416ad9e0d504eca4d576f0e51d8d373ecfd1bc84e1907cef803d01297c2"
const DESIGN_AGGREGATE =
    "f0aa8fe0ba6ef46dd702656a6d00f5f067a38d17b424b2443699d19e213f5f54"
const REQUIRED_FILES = (
    "experiments/financial_strategy_library_panel_v2/DESIGN_LOCK.json",
    "experiments/financial_strategy_library_panel_v2/DESIGN_LOCK_002.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_LOCK.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_LOCK_002.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_LOCK_003.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_LOCK_004.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_LOCK_005.json",
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
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_005.md",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_005.toml",
    "experiments/financial_strategy_library_panel_v2/amendments/FAILED_EXECUTION_CENSUS_001.toml",
    "julia/Project.toml",
    "julia/Manifest.toml",
    "julia/src/FinancialStrategyLibraryPanelV2Execution.jl",
    "julia/scripts/run_financial_strategy_library_panel_v2.jl",
    "julia/scripts/audit_financial_strategy_library_panel_v2.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v2_design_002.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v2_execution_006.jl",
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
        isfile(path) || error("missing execution-lock-006 input: $relative")
        hashes[relative] = _sha256_file(path)
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
    append!(roles, "daily_$index" => joinpath(root, String(path)) for
        (index, path) in enumerate(source["daily_files"]))
    all(pair -> isfile(last(pair)), roles) || error("registered source file is absent")
    return [(role, byte_size = filesize(path), modified_unix_seconds = round(Int, stat(path).mtime))
        for (role, path) in roles]
end

function _aggregate(hashes, sources)
    rows = ["$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))]
    append!(rows, "source:$(source.role)\0$(source.byte_size)\0$(source.modified_unix_seconds)\n"
        for source in sources)
    return _sha256_text(join(rows))
end

function _preflight()
    design_lock_text = read(DESIGN_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$DESIGN_AGGREGATE\"", design_lock_text) ||
        error("amended design-lock aggregate changed")
    amendment = TOML.parsefile(joinpath(EXPERIMENT_ROOT, "amendments", "EXECUTION_AMENDMENT_005.toml"))
    amendment["daily_master_chunk_written_before_amendment"] === false ||
        error("daily-master-chunk boundary changed")
    amendment["scientific_estimand_changed"] === false || error("estimand disclosure changed")
    for key in (
        "universe_census_computed_before_amendment",
        "profile_support_computed_before_amendment",
        "registered_seed_consumed_before_amendment",
        "candidate_score_observed_before_amendment",
        "arm_or_solver_outcome_observed_before_amendment",
        "postdecision_outcome_observed_before_amendment",
    )
        amendment[key] === false || error("outcome boundary changed: $key")
    end
    audit = amendment["finite_return_flag_audit"]
    audit["allowed_staged_flags"] == ["NA", "MV"] || error("finite-flag registry changed")
    audit["mv_count"] == 226 || error("finite-MV audit count changed")
    audit["mv_treated_as_complete_return"] === false || error("MV completeness rule changed")
    census = TOML.parsefile(joinpath(EXPERIMENT_ROOT, "amendments", "FAILED_EXECUTION_CENSUS_001.toml"))
    census["failed_attempt_count"] == 5 || error("failed-attempt census changed")
    length(census["artifacts"]) == 17 || error("failed-artifact census changed")
    isempty(readdir(joinpath(EXPERIMENT_ROOT, "local_results"))) || error("local results were not cleaned")
    isempty(readdir(joinpath(EXPERIMENT_ROOT, "local_data"))) || error("local data were not cleaned")
    return true
end

function _render(hashes, sources)
    files = join(("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))), ",\n")
    source_rows = join((
        "    {\"role\": \"$(source.role)\", \"byte_size\": $(source.byte_size), " *
        "\"modified_unix_seconds\": $(source.modified_unix_seconds)}" for source in sources
    ), ",\n")
    return """{
  "schema_version": "financial-strategy-library-panel-v2-execution-lock-v6",
  "experiment_id": "financial-strategy-library-panel-v2",
  "execution_amendment_id": "EXECUTION_AMENDMENT_005",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "predecessor_design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_design_lock_file_sha256": "$(_sha256_file(DESIGN_LOCK_PATH))",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$(_sha256_file(PREDECESSOR_PATH))",
  "failed_local_artifacts_cleaned_after_hash_census": true,
  "finite_mv_rows_treated_as_complete": false,
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
        error("execution-lock-006 design predecessor mismatch")
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("execution-lock-006 execution predecessor mismatch")
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("execution-lock-006 aggregate mismatch")
    for (path, digest) in hashes
        occursin("\"$path\": \"$digest\"", text) || error("execution-lock-006 file mismatch: $path")
    end
    return aggregate
end

function dry_run()
    _preflight(); hashes = _hashes(); sources = _sources()
    return _verify(_render(hashes, sources), hashes, sources)
end

function create_execution_lock_006()
    isfile(LOCK_PATH) && error("execution lock 006 already exists")
    _preflight(); hashes = _hashes(); sources = _sources(); text = _render(hashes, sources)
    _verify(text, hashes, sources)
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io; write(io, text); end
    mv(temporary, LOCK_PATH; force = false)
    return LOCK_PATH
end

function verify_execution_lock_006()
    isfile(LOCK_PATH) || error("execution lock 006 is absent")
    _preflight(); hashes = _hashes(); sources = _sources()
    return _verify(read(LOCK_PATH, String), hashes, sources)
end

end
