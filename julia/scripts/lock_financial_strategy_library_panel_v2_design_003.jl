module LockFinancialStrategyLibraryPanelV2Design003

using Dates
using SHA: sha256
using TOML

export create_design_lock_003, dry_run, verify_design_lock_003

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(REPOSITORY_ROOT, "experiments", "financial_strategy_library_panel_v2")
const PREDECESSOR_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK_002.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK_003.json")
const PREDECESSOR_AGGREGATE =
    "f0aa8fe0ba6ef46dd702656a6d00f5f067a38d17b424b2443699d19e213f5f54"
const MASTER_AGGREGATE =
    "585fe9f1312dd00c5633e750021cafef83e830b2e0da9029d20576c6c0bd5a61"
const MASTER_MANIFEST_SHA256 =
    "0aaec2b748a9e2043b8ce6583b4318874b4efd8abbfa9a10b197df6d5e124e2d"
const REQUIRED_FILES = (
    "experiments/financial_strategy_library_panel_v2/DESIGN_LOCK_002.json",
    "experiments/financial_strategy_library_panel_v2/amendments/DESIGN_AMENDMENT_002.md",
    "experiments/financial_strategy_library_panel_v2/amendments/DESIGN_AMENDMENT_002.toml",
    "experiments/financial_strategy_library_panel_v2/amendments/FAILED_EXECUTION_CENSUS_004.toml",
    "experiments/configs/financial_strategy_library_panel_v2_flagship_override.toml",
    "experiments/financial_strategy_library_panel_v2/registry/SEED_REGISTRY_FLAGSHIP.csv",
    "julia/scripts/lock_financial_strategy_library_panel_v2_design_003.jl",
)

_sha256_text(text) = bytes2hex(sha256(codeunits(text)))
_sha256_file(path) = open(path, "r") do io; bytes2hex(sha256(io)); end

function _hashes()
    hashes = Dict{String,String}()
    for relative in REQUIRED_FILES
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("missing design-lock-003 input: $relative")
        hashes[relative] = _sha256_file(path)
    end
    return hashes
end

function _aggregate(hashes)
    rows = ["$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))]
    push!(rows, "adopted-master-directory\0$MASTER_AGGREGATE\n")
    push!(rows, "adopted-master-manifest\0$MASTER_MANIFEST_SHA256\n")
    return _sha256_text(join(rows))
end

function _seed_values(path)
    lines = readlines(path)
    values = Set{Int}()
    for line in lines[2:end]
        fields = split(line, ',')
        length(fields) == 6 || error("unexpected seed-registry row")
        union!(values, parse.(Int, fields[4:6]))
    end
    return values
end

function _preflight()
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", read(PREDECESSOR_PATH, String)) ||
        error("design-lock-002 aggregate changed")
    amendment = TOML.parsefile(joinpath(
        EXPERIMENT_ROOT,
        "amendments",
        "DESIGN_AMENDMENT_002.toml",
    ))
    amendment["postdecision_outcome_observed_before_amendment"] === false ||
        error("held-out outcome boundary changed")
    amendment["predecessor_run_may_enter_flagship_estimands"] === false ||
        error("pilot exclusion boundary changed")
    amendment["replacement_eligibility"]["state_cell_counts_are_diagnostic_only"] === true ||
        error("replacement eligibility changed")
    amendment["replacement_profile_estimator"]["prior_strength_sessions"] == 25 ||
        error("profile prior strength changed")
    census = TOML.parsefile(joinpath(
        EXPERIMENT_ROOT,
        "amendments",
        "FAILED_EXECUTION_CENSUS_004.toml",
    ))
    census["local_artifacts_removed_after_census"] === true || error("failed run was not cleaned")
    census["postdecision_outcome_observed"] === false || error("postdecision boundary changed")
    data_root = joinpath(EXPERIMENT_ROOT, "local_data")
    Set(readdir(data_root)) == Set(["master_market_panel"]) ||
        error("design-lock-003 requires only the adopted master panel in local_data")
    isempty(readdir(joinpath(EXPERIMENT_ROOT, "local_results"))) ||
        error("design-lock-003 requires clean local results")
    predecessor_seeds = _seed_values(joinpath(EXPERIMENT_ROOT, "registry", "SEED_REGISTRY.csv"))
    flagship_seeds = _seed_values(joinpath(EXPERIMENT_ROOT, "registry", "SEED_REGISTRY_FLAGSHIP.csv"))
    isempty(intersect(predecessor_seeds, flagship_seeds)) || error("flagship seed collision")
    return true
end

function _render(hashes)
    files = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-design-lock-v4",
  "experiment_id": "financial-strategy-library-panel-v2",
  "amendment_id": "DESIGN_AMENDMENT_002",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "predecessor_design_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_design_lock_file_sha256": "$(_sha256_file(PREDECESSOR_PATH))",
  "predecision_pilot_informed": true,
  "candidate_score_observed_before_amendment": true,
  "registered_seed_consumed_before_amendment": true,
  "arm_or_solver_outcome_observed_before_amendment": true,
  "postdecision_outcome_observed_before_amendment": false,
  "predecessor_run_excluded_from_flagship_estimands": true,
  "fresh_seed_namespace": "financial-strategy-library-panel-v2-flagship-restart-001",
  "adopted_master_directory_aggregate_sha256": "$MASTER_AGGREGATE",
  "adopted_master_manifest_sha256": "$MASTER_MANIFEST_SHA256",
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$files
  }
}
"""
end

function _verify(text, hashes)
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("design-lock-003 aggregate mismatch")
    for (path, digest) in hashes
        occursin("\"$path\": \"$digest\"", text) ||
            error("design-lock-003 file mismatch: $path")
    end
    return aggregate
end

function dry_run()
    _preflight()
    hashes = _hashes()
    return _verify(_render(hashes), hashes)
end

function create_design_lock_003()
    isfile(LOCK_PATH) && error("design lock 003 already exists")
    _preflight()
    hashes = _hashes()
    text = _render(hashes)
    _verify(text, hashes)
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io; write(io, text); end
    mv(temporary, LOCK_PATH; force = false)
    return LOCK_PATH
end

function verify_design_lock_003()
    isfile(LOCK_PATH) || error("design lock 003 is absent")
    _preflight()
    hashes = _hashes()
    return _verify(read(LOCK_PATH, String), hashes)
end

end
