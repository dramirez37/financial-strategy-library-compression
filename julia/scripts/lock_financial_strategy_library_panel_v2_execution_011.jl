module LockFinancialStrategyLibraryPanelV2Execution011

using Dates
using SHA: sha256
using TOML

export create_execution_lock_011, dry_run, verify_execution_lock_011

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(REPOSITORY_ROOT, "experiments", "financial_strategy_library_panel_v2")
const CONFIG_PATH = joinpath(REPOSITORY_ROOT, "experiments", "configs", "financial_strategy_library_panel_v2.toml")
const PREDECESSOR_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_010.json")
const DESIGN_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK_005.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_011.json")
const PREDECESSOR_AGGREGATE =
    "4f7f0baf0b2a7cedcea66f43af4154f98219965426a9b0db1b0b877ebd027685"
const DESIGN_AGGREGATE =
    "d05c3fbc420a233ec881513a9c77a0cf6abf42ca233b7df56f2b18f1de5b82ce"
const MASTER_AGGREGATE =
    "585fe9f1312dd00c5633e750021cafef83e830b2e0da9029d20576c6c0bd5a61"
const MASTER_MANIFEST_SHA256 =
    "0aaec2b748a9e2043b8ce6583b4318874b4efd8abbfa9a10b197df6d5e124e2d"
const REQUIRED_FILES = (
    "experiments/financial_strategy_library_panel_v2/DESIGN_LOCK_005.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_LOCK_010.json",
    "experiments/financial_strategy_library_panel_v2/amendments/DESIGN_AMENDMENT_004.md",
    "experiments/financial_strategy_library_panel_v2/amendments/DESIGN_AMENDMENT_004.toml",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_010.md",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_010.toml",
    "experiments/financial_strategy_library_panel_v2/amendments/FAILED_EXECUTION_CENSUS_006.toml",
    "experiments/configs/financial_strategy_library_panel_v2_flagship_override.toml",
    "experiments/financial_strategy_library_panel_v2/registry/SEED_REGISTRY_FLAGSHIP_003.csv",
    "julia/Project.toml",
    "julia/Manifest.toml",
    "julia/src/FinancialStrategyLibraryPanelV2Execution.jl",
    "julia/scripts/create_financial_strategy_library_panel_v2_flagship_registries.jl",
    "julia/scripts/run_financial_strategy_library_panel_v2_flagship.jl",
    "julia/scripts/audit_financial_strategy_library_panel_v2.jl",
    "julia/scripts/audit_financial_strategy_library_panel_v2_flagship.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v2_execution_011.jl",
    "julia/test/test_financial_strategy_library_panel_v2_execution.jl",
    "julia/test/run_financial_strategy_library_panel_v2_execution_tests.jl",
)

_sha256_text(text) = bytes2hex(sha256(codeunits(text)))
_sha256_file(path) = open(path, "r") do io; bytes2hex(sha256(io)); end

function _directory_aggregate(directory)
    entries = Dict{String,String}()
    for (root, _, files) in walkdir(directory), file in files
        path = joinpath(root, file)
        entries[relpath(path, directory)] = _sha256_file(path)
    end
    canonical = join(("$path\0$(entries[path])\n" for path in sort!(collect(keys(entries)))))
    return _sha256_text(canonical), length(entries)
end

function _hashes()
    hashes = Dict{String,String}()
    for relative in REQUIRED_FILES
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("missing execution-lock-011 input: $relative")
        hashes[relative] = _sha256_file(path)
    end
    return hashes
end


function _sources()
    source = TOML.parsefile(CONFIG_PATH)["source"]
    root = haskey(ENV, "ALGOLIB_CRSP_ROOT") && !isempty(strip(ENV["ALGOLIB_CRSP_ROOT"])) ?
        normpath(ENV["ALGOLIB_CRSP_ROOT"]) :
        normpath(joinpath(REPOSITORY_ROOT, String(source["repository_root_default"])))
    roles = Pair{String,String}["security_history" => joinpath(root, String(source["security_history"]))]
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
    push!(rows, "adopted-master-directory\0$MASTER_AGGREGATE\n")
    return _sha256_text(join(rows))
end

function _preflight()
    occursin("\"aggregate_sha256\": \"$DESIGN_AGGREGATE\"", read(DESIGN_LOCK_PATH, String)) ||
        error("design-lock-005 aggregate changed")
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", read(PREDECESSOR_PATH, String)) ||
        error("execution-lock-010 aggregate changed")
    Set(readdir(joinpath(EXPERIMENT_ROOT, "local_data"))) == Set(["master_market_panel"]) ||
        error("execution-lock-011 local-data boundary changed")
    isempty(readdir(joinpath(EXPERIMENT_ROOT, "local_results"))) ||
        error("execution-lock-011 requires clean local results")
    master = joinpath(EXPERIMENT_ROOT, "local_data", "master_market_panel")
    aggregate, count = _directory_aggregate(master)
    aggregate == MASTER_AGGREGATE || error("adopted master aggregate changed")
    count == 158 || error("adopted master file count changed")
    _sha256_file(joinpath(master, "MASTER_MANIFEST.toml")) == MASTER_MANIFEST_SHA256 ||
        error("adopted master manifest changed")
    amendment = TOML.parsefile(joinpath(EXPERIMENT_ROOT, "amendments", "EXECUTION_AMENDMENT_010.toml"))
    amendment["postdecision_outcome_observed_before_amendment"] === false ||
        error("postdecision boundary changed")
    amendment["execution"]["population_mip_invoked"] === false ||
        error("population MIP boundary changed")
    return true
end

function _render(hashes, sources)
    files = join(("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))), ",\n")
    source_rows = join((
        "    {\"role\": \"$(source.role)\", \"byte_size\": $(source.byte_size), " *
        "\"modified_unix_seconds\": $(source.modified_unix_seconds)}" for source in sources
    ), ",\n")
    return """{
  "schema_version": "financial-strategy-library-panel-v2-execution-lock-v11",
  "experiment_id": "financial-strategy-library-panel-v2",
  "execution_amendment_id": "EXECUTION_AMENDMENT_010",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "predecessor_design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "postdecision_outcome_observed_before_lock": false,
  "primary_safe_arm": "innovation_safe_greedy",
  "primary_comparator_arm": "frontier_only_budget_matched",
  "population_mip_invoked": false,
  "population_multistart_invoked": false,
  "fresh_seed_namespace": "financial-strategy-library-panel-v2-flagship-restart-003",
  "adopted_master_directory_aggregate_sha256": "$MASTER_AGGREGATE",
  "adopted_master_manifest_sha256": "$MASTER_MANIFEST_SHA256",
  "adopted_master_file_count": 158,
  "adopted_master_chunk_count": 155,
  "adopted_master_retained_rows": 38327975,
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
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) || error("execution-lock-011 aggregate mismatch")
    for (path, digest) in hashes
        occursin("\"$path\": \"$digest\"", text) || error("execution-lock-011 file mismatch: $path")
    end
    return aggregate
end

dry_run() = (_preflight(); hashes = _hashes(); sources = _sources(); _verify(_render(hashes, sources), hashes, sources))

function create_execution_lock_011()
    isfile(LOCK_PATH) && error("execution lock 011 already exists")
    _preflight(); hashes = _hashes(); sources = _sources(); text = _render(hashes, sources)
    _verify(text, hashes, sources)
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io; write(io, text); end
    mv(temporary, LOCK_PATH; force = false)
    return LOCK_PATH
end

function verify_execution_lock_011()
    isfile(LOCK_PATH) || error("execution lock 011 is absent")
    _preflight(); hashes = _hashes(); sources = _sources(); _verify(read(LOCK_PATH, String), hashes, sources)
end

end
