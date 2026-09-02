module LockFinancialStrategyLibraryPanelV2Execution009

using Dates
using SHA: sha256
using TOML

export create_execution_lock_009, dry_run, verify_execution_lock_009

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(REPOSITORY_ROOT, "experiments", "financial_strategy_library_panel_v2")
const CONFIG_PATH = joinpath(REPOSITORY_ROOT, "experiments", "configs", "financial_strategy_library_panel_v2.toml")
const PREDECESSOR_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_008.json")
const DESIGN_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK_003.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_009.json")
const PREDECESSOR_AGGREGATE =
    "c3c00f22322b504f83e4fa2394c7d68e43437f81de369544e0d8c621280f46f2"
const DESIGN_AGGREGATE =
    "5ff26284091909c7bf3dc1d3066a1e7cd1bf165bb418d30a15753c298f8d3e33"
const MASTER_AGGREGATE =
    "585fe9f1312dd00c5633e750021cafef83e830b2e0da9029d20576c6c0bd5a61"
const MASTER_MANIFEST_SHA256 =
    "0aaec2b748a9e2043b8ce6583b4318874b4efd8abbfa9a10b197df6d5e124e2d"
const REQUIRED_FILES = (
    "experiments/financial_strategy_library_panel_v2/DESIGN_LOCK_003.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_LOCK_008.json",
    "experiments/financial_strategy_library_panel_v2/amendments/DESIGN_AMENDMENT_002.md",
    "experiments/financial_strategy_library_panel_v2/amendments/DESIGN_AMENDMENT_002.toml",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_008.md",
    "experiments/financial_strategy_library_panel_v2/amendments/EXECUTION_AMENDMENT_008.toml",
    "experiments/financial_strategy_library_panel_v2/amendments/FAILED_EXECUTION_CENSUS_004.toml",
    "experiments/configs/financial_strategy_library_panel_v2_flagship_override.toml",
    "experiments/financial_strategy_library_panel_v2/registry/SEED_REGISTRY_FLAGSHIP.csv",
    "julia/Project.toml",
    "julia/Manifest.toml",
    "julia/src/FinancialStrategyLibraryPanelV2Execution.jl",
    "julia/scripts/create_financial_strategy_library_panel_v2_flagship_registries.jl",
    "julia/scripts/run_financial_strategy_library_panel_v2_flagship.jl",
    "julia/scripts/audit_financial_strategy_library_panel_v2.jl",
    "julia/scripts/audit_financial_strategy_library_panel_v2_flagship.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v2_execution_009.jl",
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
        isfile(path) || error("missing execution-lock-009 input: $relative")
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
    push!(rows, "adopted-master-manifest\0$MASTER_MANIFEST_SHA256\n")
    return _sha256_text(join(rows))
end

function _preflight()
    occursin("\"aggregate_sha256\": \"$DESIGN_AGGREGATE\"", read(DESIGN_LOCK_PATH, String)) ||
        error("design-lock-003 aggregate changed")
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", read(PREDECESSOR_PATH, String)) ||
        error("execution-lock-008 aggregate changed")
    data_root = joinpath(EXPERIMENT_ROOT, "local_data")
    Set(readdir(data_root)) == Set(["master_market_panel"]) ||
        error("execution-lock-009 requires only the adopted master panel in local_data")
    isempty(readdir(joinpath(EXPERIMENT_ROOT, "local_results"))) ||
        error("execution-lock-009 requires clean local results")
    master_root = joinpath(data_root, "master_market_panel")
    aggregate, file_count = _directory_aggregate(master_root)
    aggregate == MASTER_AGGREGATE || error("adopted master directory aggregate changed")
    file_count == 158 || error("adopted master file count changed")
    _sha256_file(joinpath(master_root, "MASTER_MANIFEST.toml")) == MASTER_MANIFEST_SHA256 ||
        error("adopted master manifest digest changed")
    amendment = TOML.parsefile(joinpath(
        EXPERIMENT_ROOT,
        "amendments",
        "EXECUTION_AMENDMENT_008.toml",
    ))
    amendment["postdecision_outcome_observed_before_amendment"] === false ||
        error("postdecision boundary changed")
    amendment["scientific_restart"]["fresh_seed_registry_required"] === true ||
        error("fresh-seed requirement changed")
    return true
end

function _render(hashes, sources)
    files = join(("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))), ",\n")
    source_rows = join((
        "    {\"role\": \"$(source.role)\", \"byte_size\": $(source.byte_size), " *
        "\"modified_unix_seconds\": $(source.modified_unix_seconds)}" for source in sources
    ), ",\n")
    return """{
  "schema_version": "financial-strategy-library-panel-v2-execution-lock-v9",
  "experiment_id": "financial-strategy-library-panel-v2",
  "execution_amendment_id": "EXECUTION_AMENDMENT_008",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "predecessor_design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_design_lock_file_sha256": "$(_sha256_file(DESIGN_LOCK_PATH))",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$(_sha256_file(PREDECESSOR_PATH))",
  "predecision_pilot_informed": true,
  "postdecision_outcome_observed_before_lock": false,
  "fresh_seed_namespace": "financial-strategy-library-panel-v2-flagship-restart-001",
  "adopted_master_builder_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
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
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("execution-lock-009 aggregate mismatch")
    for (path, digest) in hashes
        occursin("\"$path\": \"$digest\"", text) ||
            error("execution-lock-009 file mismatch: $path")
    end
    return aggregate
end

function dry_run()
    _preflight()
    hashes = _hashes()
    sources = _sources()
    return _verify(_render(hashes, sources), hashes, sources)
end

function create_execution_lock_009()
    isfile(LOCK_PATH) && error("execution lock 009 already exists")
    _preflight()
    hashes = _hashes()
    sources = _sources()
    text = _render(hashes, sources)
    _verify(text, hashes, sources)
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io; write(io, text); end
    mv(temporary, LOCK_PATH; force = false)
    return LOCK_PATH
end

function verify_execution_lock_009()
    isfile(LOCK_PATH) || error("execution lock 009 is absent")
    _preflight()
    hashes = _hashes()
    sources = _sources()
    return _verify(read(LOCK_PATH, String), hashes, sources)
end

end
