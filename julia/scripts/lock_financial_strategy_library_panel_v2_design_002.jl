module LockFinancialStrategyLibraryPanelV2Design002

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v2.jl"))
using .LockFinancialStrategyLibraryPanelV2: verify_design_lock

export create_design_lock_002, dry_run, verify_design_lock_002

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
const PREDECESSOR_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK_002.json")
const PREDECESSOR_AGGREGATE =
    "0f2305d0187247cd048035fb03f6912e9ea7028ac05212adf76396af05b61964"
const REQUIRED_FILES = (
    "experiments/financial_strategy_library_panel_v2/DESIGN_LOCK.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_PROTOCOL.md",
    "experiments/financial_strategy_library_panel_v2/amendments/DESIGN_AMENDMENT_001.md",
    "experiments/financial_strategy_library_panel_v2/amendments/DESIGN_AMENDMENT_001.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v2_design_002.jl",
)
const RECOVERY_RESULTS = Set((
    "FAILED_ATTEMPT_001_ENVIRONMENT.toml",
    "FAILED_ATTEMPT_002_ENVIRONMENT.toml",
    "FAILED_ATTEMPT_002_SOURCE_AUDIT.toml",
    "FAILED_ATTEMPT_003_ENVIRONMENT.toml",
    "FAILED_ATTEMPT_003_SOURCE_AUDIT.toml",
    "FAILED_ATTEMPT_004_ENVIRONMENT.toml",
    "FAILED_ATTEMPT_004_SOURCE_AUDIT.toml",
))

_sha256_text(text) = bytes2hex(sha256(codeunits(text)))
_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

function _hashes()
    hashes = Dict{String,String}()
    for relative in REQUIRED_FILES
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("missing design-lock-002 input: $relative")
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
    verify_design_lock() == PREDECESSOR_AGGREGATE || error("predecessor design lock changed")
    amendment = TOML.parsefile(joinpath(
        EXPERIMENT_ROOT,
        "amendments",
        "DESIGN_AMENDMENT_001.toml",
    ))
    amendment["data_quality_informed"] === true || error("data-quality disclosure changed")
    amendment["scientific_estimand_changed"] === true || error("estimand disclosure changed")
    amendment["security_level_profile_support_computed_before_amendment"] === false ||
        error("profile-support disclosure changed")
    for key in (
        "candidate_score_observed_before_amendment",
        "registered_seed_consumed_before_amendment",
        "arm_or_solver_outcome_observed_before_amendment",
        "postdecision_outcome_observed_before_amendment",
    )
        amendment[key] === false || error("outcome boundary changed: $key")
    end
    amendment["postdecision_information_may_define_universe"] === false ||
        error("postdecision information was allowed into eligibility")
    results = joinpath(EXPERIMENT_ROOT, "local_results")
    Set(readdir(results)) == RECOVERY_RESULTS || error("result recovery boundary changed")
    data = joinpath(EXPERIMENT_ROOT, "local_data")
    Set(readdir(data)) == Set(["FAILED_ATTEMPT_004_reference_series_partitions"]) ||
        error("data recovery boundary changed")
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
  "schema_version": "financial-strategy-library-panel-design-lock-v3",
  "experiment_id": "financial-strategy-library-panel-v2",
  "amendment_id": "DESIGN_AMENDMENT_001",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "predecessor_design_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_design_lock_file_sha256": "$(_sha256_file(PREDECESSOR_PATH))",
  "data_quality_informed": true,
  "scientific_estimand_changed": true,
  "security_level_profile_support_computed_before_amendment": false,
  "candidate_score_observed_before_amendment": false,
  "registered_seed_consumed_before_amendment": false,
  "arm_or_solver_outcome_observed_before_amendment": false,
  "postdecision_outcome_observed_before_amendment": false,
  "postdecision_information_may_define_universe": false,
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
    occursin("\"predecessor_design_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("design-lock-002 predecessor mismatch")
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("design-lock-002 aggregate mismatch")
    for (path, digest) in hashes
        occursin("\"$path\": \"$digest\"", text) ||
            error("design-lock-002 file mismatch: $path")
    end
    return aggregate
end

function dry_run()
    _preflight()
    hashes = _hashes()
    sources = _sources()
    return _verify(_render(hashes, sources), hashes, sources)
end

function create_design_lock_002()
    isfile(LOCK_PATH) && error("design lock 002 already exists")
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

function verify_design_lock_002()
    isfile(LOCK_PATH) || error("design lock 002 is absent")
    _preflight()
    hashes = _hashes()
    sources = _sources()
    return _verify(read(LOCK_PATH, String), hashes, sources)
end

end

