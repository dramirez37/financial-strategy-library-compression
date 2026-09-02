module LockFinancialStrategyLibraryPanelV2Execution

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v2.jl"))
using .LockFinancialStrategyLibraryPanelV2: verify_design_lock

export create_execution_lock, dry_run, verify_execution_lock, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_strategy_library_panel_v2.toml",
)
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v2",
)
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK.json")
const REQUIRED_FILES = (
    ".gitignore",
    "experiments/financial_strategy_library_panel_v2/DESIGN_LOCK.json",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_PROTOCOL.md",
    "julia/Project.toml",
    "julia/Manifest.toml",
    "julia/src/FinancialStrategyLibraryPanelV2Execution.jl",
    "julia/scripts/run_financial_strategy_library_panel_v2.jl",
    "julia/scripts/audit_financial_strategy_library_panel_v2.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v2_execution.jl",
    "julia/test/test_financial_strategy_library_panel_v2_execution.jl",
    "julia/test/run_financial_strategy_library_panel_v2_execution_tests.jl",
)

_sha256_text(text) = bytes2hex(sha256(codeunits(text)))
_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

function _hashes()
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) || error("missing execution-lock input: $relative")
    end
    return Dict(
        relative => _sha256_file(joinpath(REPOSITORY_ROOT, relative)) for
        relative in REQUIRED_FILES
    )
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
    roles = Pair{String,String}[
        "security_history" => joinpath(root, String(source["security_history"])),
    ]
    append!(roles, "daily_$index" => joinpath(root, String(path)) for (index, path) in enumerate(source["daily_files"]))
    for (_, path) in roles
        isfile(path) || error("registered source file is absent")
    end
    return [(
        role,
        byte_size = filesize(path),
        modified_unix_seconds = round(Int, stat(path).mtime),
    ) for (role, path) in roles]
end

function _aggregate(hashes, sources)
    rows = ["$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))]
    append!(rows, "source:$(item.role)\0$(item.byte_size)\0$(item.modified_unix_seconds)\n" for item in sources)
    return _sha256_text(join(rows))
end

function _assert_no_outputs(config)
    for key in ("local_data_root", "local_results_root", "public_results_root")
        path = joinpath(REPOSITORY_ROOT, String(config["paths"][key]))
        ispath(path) && (!isdir(path) || !isempty(readdir(path))) &&
            error("cannot freeze v2 execution after outputs exist: $(config["paths"][key])")
    end
    return true
end

function _render(hashes, sources, predecessor)
    file_rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    source_rows = join((
        "    {\"role\": \"$(item.role)\", \"byte_size\": $(item.byte_size), \"modified_unix_seconds\": $(item.modified_unix_seconds)}"
        for item in sources
    ), ",\n")
    aggregate = _aggregate(hashes, sources)
    return """{
  "schema_version": "financial-strategy-library-panel-v2-execution-lock-v1",
  "experiment_id": "financial-strategy-library-panel-v2",
  "execution_protocol_id": "EXECUTION_PROTOCOL_001",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "predecessor_design_lock_aggregate_sha256": "$predecessor",
  "licensed_rows_parsed_before_execution_lock": false,
  "v2_candidate_scores_observed_before_execution_lock": false,
  "v2_arm_outcomes_observed_before_execution_lock": false,
  "v2_postdecision_outcomes_observed_before_execution_lock": false,
  "registered_origins": 20,
  "registered_dockets": 2,
  "registered_schedules": 3,
  "registered_arms": 6,
  "registered_menus_per_origin_docket": 32,
  "julia_version": "1.12.6",
  "blas_threads": 1,
  "highs_threads_per_model": 1,
  "predecision_information_firewall": true,
  "aggregate_sha256": "$aggregate",
  "source_stat_fingerprints": [
$source_rows
  ],
  "files": {
$file_rows
  }
}
"""
end

function _validate_lock_text(text, hashes, sources, predecessor)
    for declaration in (
        "licensed_rows_parsed_before_execution_lock",
        "v2_candidate_scores_observed_before_execution_lock",
        "v2_arm_outcomes_observed_before_execution_lock",
        "v2_postdecision_outcomes_observed_before_execution_lock",
    )
        occursin("\"$declaration\": false", text) || error("prospective declaration changed: $declaration")
    end
    occursin("\"predecessor_design_lock_aggregate_sha256\": \"$predecessor\"", text) ||
        error("execution lock has wrong design predecessor")
    aggregate = _aggregate(hashes, sources)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) || error("execution aggregate mismatch")
    for (path, digest) in hashes
        occursin("\"$path\": \"$digest\"", text) || error("execution file hash mismatch: $path")
    end
    for item in sources
        needle = "{\"role\": \"$(item.role)\", \"byte_size\": $(item.byte_size), \"modified_unix_seconds\": $(item.modified_unix_seconds)}"
        occursin(needle, text) || error("source stat fingerprint mismatch: $(item.role)")
    end
    return aggregate
end

function dry_run()
    predecessor = verify_design_lock()
    config = TOML.parsefile(CONFIG_PATH)
    _assert_no_outputs(config)
    hashes = _hashes()
    sources = _source_metadata()
    text = _render(hashes, sources, predecessor)
    return _validate_lock_text(text, hashes, sources, predecessor)
end

function create_execution_lock()
    isfile(LOCK_PATH) && error("v2 execution lock already exists and is immutable")
    predecessor = verify_design_lock()
    config = TOML.parsefile(CONFIG_PATH)
    _assert_no_outputs(config)
    hashes = _hashes()
    sources = _source_metadata()
    text = _render(hashes, sources, predecessor)
    _validate_lock_text(text, hashes, sources, predecessor)
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, LOCK_PATH; force = false)
    return LOCK_PATH
end

function verify_execution_lock()
    isfile(LOCK_PATH) || error("v2 execution lock is absent")
    predecessor = verify_design_lock()
    return _validate_lock_text(
        read(LOCK_PATH, String),
        _hashes(),
        _source_metadata(),
        predecessor,
    )
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v2_execution.jl --dry-run|--create|--check",
    )
    mode = only(args)
    mode == "--dry-run" && return println("v2 execution lock dry run valid: $(dry_run())")
    mode == "--create" && return println("created v2 execution lock: $(create_execution_lock())")
    mode == "--check" && return println("v2 execution lock valid: $(verify_execution_lock())")
    error("unknown v2 execution-lock mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV2Execution.main()
end
