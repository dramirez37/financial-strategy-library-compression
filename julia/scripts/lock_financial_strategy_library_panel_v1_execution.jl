module LockFinancialStrategyLibraryPanelV1Execution

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1.jl"))
using .LockFinancialStrategyLibraryPanelV1: verify_design_lock

export create_execution_lock,
       dry_run,
       main,
       validate_execution_design,
       verify_execution_lock,
       verify_lock_text

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_strategy_library_panel_v1.toml",
)
const AMENDMENT_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v1",
    "amendments",
    "EXECUTION_AMENDMENT_001.toml",
)
const LOCK_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v1",
    "EXECUTION_LOCK.json",
)

const REQUIRED_FILES = (
    "experiments/financial_strategy_library_panel_v1/DESIGN_LOCK.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_001.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_001.toml",
    "julia/src/FinancialStrategyLibraryPanelV1.jl",
    "julia/scripts/run_financial_strategy_library_panel_v1.jl",
    "julia/scripts/audit_financial_strategy_library_panel_v1.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution.jl",
    "julia/test/test_financial_strategy_library_panel_v1_execution.jl",
    "julia/test/run_financial_strategy_library_panel_v1_execution_tests.jl",
    "Makefile",
    "REPRODUCIBILITY.md",
    "scripts/aor_check.sh",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text) = bytes2hex(sha256(codeunits(text)))

function _hashes()
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) || error("missing execution-lock input: $relative")
    end
    return Dict(
        relative => _sha256_file(joinpath(REPOSITORY_ROOT, relative)) for
        relative in REQUIRED_FILES
    )
end

function _aggregate(hashes)
    return _sha256_text(join(
        ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
    ))
end

function validate_execution_design()
    predecessor = verify_design_lock()
    config = TOML.parsefile(CONFIG_PATH)
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] == "financial-strategy-library-panel-execution-amendment-v1" ||
        error("unexpected execution amendment schema")
    amendment["amendment_id"] == "AMENDMENT_001" || error("unexpected amendment identifier")
    for key in (
        "licensed_rows_read_before_amendment",
        "registered_seed_consumed_before_amendment",
        "study_instance_constructed_before_amendment",
        "study_outcome_observed_before_amendment",
        "scientific_estimands_changed",
        "origin_registry_changed",
        "library_registry_changed",
        "burden_schedule_registry_changed",
        "seed_registry_changed",
        "algorithm_registry_changed",
    )
        amendment[key] === false || error("prospective execution declaration changed: $key")
    end
    threading = amendment["threading"]
    threading["julia_threads"] == 8 || error("execution must use eight Julia threads")
    threading["concurrent_lanes"] == 8 || error("execution must use eight concurrent lanes")
    threading["blas_threads"] == 1 || error("BLAS must be single threaded within a lane")
    threading["highs_threads_per_model"] == 1 ||
        error("HiGHS must be single threaded within a lane")
    firewall = amendment["information_firewall"]
    firewall["shared_cross_origin_return_map_permitted"] === false ||
        error("cross-origin future return maps cannot be permitted")
    config["algorithms"]["highs_threads"] == 1 || error("registered HiGHS thread count changed")
    length(config["algorithms"]["algorithm_ids"]) == 7 || error("registered algorithm count changed")
    return (predecessor = predecessor, config = config, amendment = amendment)
end

function _assert_no_outputs(config)
    for key in ("local_data_root", "local_results_root", "public_results_root")
        relative = String(config["paths"][key])
        path = joinpath(REPOSITORY_ROOT, relative)
        ispath(path) && (!isdir(path) || !isempty(readdir(path))) && error(
            "cannot create the execution lock after study outputs exist: $relative",
        )
    end
    return true
end

function _render_lock(hashes, predecessor)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v1",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_001",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "predecessor_design_lock_aggregate_sha256": "$predecessor",
  "licensed_rows_read_before_execution_lock": false,
  "registered_seed_consumed_before_execution_lock": false,
  "study_instance_constructed_before_execution_lock": false,
  "study_outcome_observed_before_execution_lock": false,
  "registered_origins": 20,
  "registered_source_libraries": 60,
  "registered_compression_instances": 180,
  "registered_algorithm_terminal_rows": 1260,
  "julia_threads": 8,
  "concurrent_lanes": 8,
  "blas_threads": 1,
  "highs_threads_per_model": 1,
  "origin_scoped_return_firewall": true,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    validated = validate_execution_design()
    occursin(
        "\"schema_version\": \"financial-strategy-library-panel-execution-lock-v1\"",
        text,
    ) || error("unexpected or missing execution-lock schema")
    for declaration in (
        "licensed_rows_read_before_execution_lock",
        "registered_seed_consumed_before_execution_lock",
        "study_instance_constructed_before_execution_lock",
        "study_outcome_observed_before_execution_lock",
    )
        occursin("\"$declaration\": false", text) ||
            error("invalid prospective execution-lock declaration: $declaration")
    end
    occursin("\"julia_threads\": 8", text) || error("execution lock is not eight threaded")
    occursin("\"origin_scoped_return_firewall\": true", text) ||
        error("execution lock lacks the origin-scoped return firewall")
    occursin(
        "\"predecessor_design_lock_aggregate_sha256\": \"$(validated.predecessor)\"",
        text,
    ) || error("execution lock predecessor differs")
    for path in keys(hashes)
        occursin("\"$path\": \"$(hashes[path])\"", text) ||
            error("execution-lock mismatch: $path")
    end
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("execution-lock aggregate mismatch")
    return aggregate
end

function dry_run()
    validated = validate_execution_design()
    _assert_no_outputs(validated.config)
    hashes = _hashes()
    text = _render_lock(hashes, validated.predecessor)
    return verify_lock_text(text, hashes)
end

function create_execution_lock()
    isfile(LOCK_PATH) && error("execution lock already exists; do not rewrite it")
    validated = validate_execution_design()
    _assert_no_outputs(validated.config)
    hashes = _hashes()
    text = _render_lock(hashes, validated.predecessor)
    verify_lock_text(text, hashes)
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, LOCK_PATH; force = false)
    println("created financial strategy-library panel v1 execution lock")
    return LOCK_PATH
end

function verify_execution_lock()
    isfile(LOCK_PATH) || error("financial panel v1 execution lock is absent")
    return verify_lock_text(read(LOCK_PATH, String), _hashes())
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v1_execution.jl --dry-run|--create|--check",
    )
    mode = only(args)
    mode == "--dry-run" && return println("financial panel execution dry run valid: $(dry_run())")
    mode == "--create" && return create_execution_lock()
    mode == "--check" && return println(
        "financial panel execution lock valid: $(verify_execution_lock())",
    )
    error("unknown execution-lock mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution.main()
end
