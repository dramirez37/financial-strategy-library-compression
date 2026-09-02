module LockFinancialStrategyLibraryPanelV2Design005

using Dates
using SHA: sha256
using TOML

export create_design_lock_005, dry_run, verify_design_lock_005

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(REPOSITORY_ROOT, "experiments", "financial_strategy_library_panel_v2")
const PREDECESSOR_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK_004.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK_005.json")
const PREDECESSOR_AGGREGATE =
    "cc37bce028386de03000562e54acfe97d3f007c1acd8042df00cc1f830b1af10"
const MASTER_AGGREGATE =
    "585fe9f1312dd00c5633e750021cafef83e830b2e0da9029d20576c6c0bd5a61"
const REQUIRED_FILES = (
    "experiments/financial_strategy_library_panel_v2/DESIGN_LOCK_004.json",
    "experiments/financial_strategy_library_panel_v2/amendments/DESIGN_AMENDMENT_004.md",
    "experiments/financial_strategy_library_panel_v2/amendments/DESIGN_AMENDMENT_004.toml",
    "experiments/financial_strategy_library_panel_v2/amendments/FAILED_EXECUTION_CENSUS_006.toml",
    "experiments/configs/financial_strategy_library_panel_v2_flagship_override.toml",
    "experiments/financial_strategy_library_panel_v2/registry/SEED_REGISTRY_FLAGSHIP_003.csv",
    "julia/scripts/lock_financial_strategy_library_panel_v2_design_005.jl",
)

_sha256_text(text) = bytes2hex(sha256(codeunits(text)))
_sha256_file(path) = open(path, "r") do io; bytes2hex(sha256(io)); end

function _hashes()
    hashes = Dict{String,String}()
    for relative in REQUIRED_FILES
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("missing design-lock-005 input: $relative")
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
        union!(values, parse.(Int, split(line, ',')[4:6]))
    end
    return values
end

function _preflight()
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", read(PREDECESSOR_PATH, String)) ||
        error("design-lock-004 aggregate changed")
    amendment = TOML.parsefile(joinpath(EXPERIMENT_ROOT, "amendments", "DESIGN_AMENDMENT_004.toml"))
    amendment["postdecision_outcome_observed_before_amendment"] === false ||
        error("postdecision boundary changed")
    amendment["population_arms"]["primary_safe_arm"] == "innovation_safe_greedy" ||
        error("operational primary arm changed")
    amendment["computational_benchmark"]["may_affect_heldout_estimand"] === false ||
        error("benchmark isolation changed")
    census = TOML.parsefile(joinpath(EXPERIMENT_ROOT, "amendments", "FAILED_EXECUTION_CENSUS_006.toml"))
    census["local_artifacts_removed_after_census"] === true || error("attempt 010 was not cleaned")
    Set(readdir(joinpath(EXPERIMENT_ROOT, "local_data"))) == Set(["master_market_panel"]) ||
        error("design-lock-005 local-data boundary changed")
    isempty(readdir(joinpath(EXPERIMENT_ROOT, "local_results"))) ||
        error("design-lock-005 requires clean local results")
    latest = _seed_values(joinpath(EXPERIMENT_ROOT, "registry", "SEED_REGISTRY_FLAGSHIP_003.csv"))
    for predecessor in ("SEED_REGISTRY.csv", "SEED_REGISTRY_FLAGSHIP.csv", "SEED_REGISTRY_FLAGSHIP_002.csv")
        isempty(intersect(latest, _seed_values(joinpath(EXPERIMENT_ROOT, "registry", predecessor)))) ||
            error("restart-003 seed collision: $predecessor")
    end
    return true
end

function _render(hashes)
    files = join(("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))), ",\n")
    return """{
  "schema_version": "financial-strategy-library-panel-design-lock-v6",
  "experiment_id": "financial-strategy-library-panel-v2",
  "amendment_id": "DESIGN_AMENDMENT_004",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "predecessor_design_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_design_lock_file_sha256": "$(_sha256_file(PREDECESSOR_PATH))",
  "predecision_computational_pilot_informed": true,
  "postdecision_outcome_observed_before_amendment": false,
  "primary_safe_arm": "innovation_safe_greedy",
  "primary_comparator_arm": "frontier_only_budget_matched",
  "exact_and_multistart_population_arms_deferred": true,
  "fresh_seed_namespace": "financial-strategy-library-panel-v2-flagship-restart-003",
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
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) || error("design-lock-005 aggregate mismatch")
    for (path, digest) in hashes
        occursin("\"$path\": \"$digest\"", text) || error("design-lock-005 file mismatch: $path")
    end
    return aggregate
end

dry_run() = (_preflight(); hashes = _hashes(); _verify(_render(hashes), hashes))

function create_design_lock_005()
    isfile(LOCK_PATH) && error("design lock 005 already exists")
    _preflight(); hashes = _hashes(); text = _render(hashes); _verify(text, hashes)
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io; write(io, text); end
    mv(temporary, LOCK_PATH; force = false)
    return LOCK_PATH
end

function verify_design_lock_005()
    isfile(LOCK_PATH) || error("design lock 005 is absent")
    _preflight(); hashes = _hashes(); _verify(read(LOCK_PATH, String), hashes)
end

end
