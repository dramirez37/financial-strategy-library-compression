module LockFinancialStrategyLibraryPanelV2Design004

using Dates
using SHA: sha256
using TOML

export create_design_lock_004, dry_run, verify_design_lock_004

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(REPOSITORY_ROOT, "experiments", "financial_strategy_library_panel_v2")
const PREDECESSOR_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK_003.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK_004.json")
const PREDECESSOR_AGGREGATE =
    "5ff26284091909c7bf3dc1d3066a1e7cd1bf165bb418d30a15753c298f8d3e33"
const MASTER_AGGREGATE =
    "585fe9f1312dd00c5633e750021cafef83e830b2e0da9029d20576c6c0bd5a61"
const REQUIRED_FILES = (
    "experiments/financial_strategy_library_panel_v2/DESIGN_LOCK_003.json",
    "experiments/financial_strategy_library_panel_v2/amendments/DESIGN_AMENDMENT_003.md",
    "experiments/financial_strategy_library_panel_v2/amendments/DESIGN_AMENDMENT_003.toml",
    "experiments/financial_strategy_library_panel_v2/amendments/FAILED_EXECUTION_CENSUS_005.toml",
    "experiments/configs/financial_strategy_library_panel_v2_flagship_override.toml",
    "experiments/financial_strategy_library_panel_v2/registry/SEED_REGISTRY_FLAGSHIP_002.csv",
    "julia/scripts/lock_financial_strategy_library_panel_v2_design_004.jl",
)

_sha256_text(text) = bytes2hex(sha256(codeunits(text)))
_sha256_file(path) = open(path, "r") do io; bytes2hex(sha256(io)); end

function _hashes()
    hashes = Dict{String,String}()
    for relative in REQUIRED_FILES
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("missing design-lock-004 input: $relative")
        hashes[relative] = _sha256_file(path)
    end
    return hashes
end

function _aggregate(hashes)
    rows = ["$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))]
    push!(rows, "adopted-master-directory\0$MASTER_AGGREGATE\n")
    return _sha256_text(join(rows))
end

function _seed_values(path)
    values = Set{Int}()
    for line in readlines(path)[2:end]
        fields = split(line, ',')
        union!(values, parse.(Int, fields[4:6]))
    end
    return values
end

function _preflight()
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", read(PREDECESSOR_PATH, String)) ||
        error("design-lock-003 aggregate changed")
    amendment = TOML.parsefile(joinpath(EXPERIMENT_ROOT, "amendments", "DESIGN_AMENDMENT_003.toml"))
    amendment["postdecision_outcome_observed_before_amendment"] === false ||
        error("postdecision boundary changed")
    amendment["source_docket_revision"]["all_100_securities_remain_in_candidate_grammar"] === true ||
        error("candidate-universe boundary changed")
    amendment["stress_revision"]["inline_population_timing"] === false ||
        error("stress separation changed")
    census = TOML.parsefile(joinpath(EXPERIMENT_ROOT, "amendments", "FAILED_EXECUTION_CENSUS_005.toml"))
    census["local_artifacts_removed_after_census"] === true || error("attempt 009 was not cleaned")
    Set(readdir(joinpath(EXPERIMENT_ROOT, "local_data"))) == Set(["master_market_panel"]) ||
        error("design-lock-004 local-data boundary changed")
    isempty(readdir(joinpath(EXPERIMENT_ROOT, "local_results"))) ||
        error("design-lock-004 requires clean local results")
    registries = [
        joinpath(EXPERIMENT_ROOT, "registry", "SEED_REGISTRY.csv"),
        joinpath(EXPERIMENT_ROOT, "registry", "SEED_REGISTRY_FLAGSHIP.csv"),
        joinpath(EXPERIMENT_ROOT, "registry", "SEED_REGISTRY_FLAGSHIP_002.csv"),
    ]
    sets = _seed_values.(registries)
    isempty(intersect(sets[1], sets[3])) || error("restart-002 seed collision with original")
    isempty(intersect(sets[2], sets[3])) || error("restart-002 seed collision with restart-001")
    return true
end

function _render(hashes)
    files = join(("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))), ",\n")
    return """{
  "schema_version": "financial-strategy-library-panel-design-lock-v5",
  "experiment_id": "financial-strategy-library-panel-v2",
  "amendment_id": "DESIGN_AMENDMENT_003",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "predecessor_design_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_design_lock_file_sha256": "$(_sha256_file(PREDECESSOR_PATH))",
  "predecision_computational_pilot_informed": true,
  "postdecision_outcome_observed_before_amendment": false,
  "per_security_source_quota_removed": true,
  "all_securities_remain_in_candidate_grammar": true,
  "inline_stress_timing": false,
  "main_mip_time_limit_seconds": 180,
  "fresh_seed_namespace": "financial-strategy-library-panel-v2-flagship-restart-002",
  "adopted_master_directory_aggregate_sha256": "$MASTER_AGGREGATE",
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$files
  }
}
"""
end

function _verify(text, hashes)
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) || error("design-lock-004 aggregate mismatch")
    for (path, digest) in hashes
        occursin("\"$path\": \"$digest\"", text) || error("design-lock-004 file mismatch: $path")
    end
    return aggregate
end

function dry_run()
    _preflight(); hashes = _hashes(); return _verify(_render(hashes), hashes)
end

function create_design_lock_004()
    isfile(LOCK_PATH) && error("design lock 004 already exists")
    _preflight(); hashes = _hashes(); text = _render(hashes); _verify(text, hashes)
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io; write(io, text); end
    mv(temporary, LOCK_PATH; force = false)
    return LOCK_PATH
end

function verify_design_lock_004()
    isfile(LOCK_PATH) || error("design lock 004 is absent")
    _preflight(); hashes = _hashes(); return _verify(read(LOCK_PATH, String), hashes)
end

end
