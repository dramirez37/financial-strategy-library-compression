module LockFinancialStrategyLibraryPanelV1Execution022

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_021.jl"))
const Lock021 = LockFinancialStrategyLibraryPanelV1Execution021

export create_execution_lock_022,
       dry_run,
       main,
       validate_execution_design_022,
       verify_execution_lock_022,
       verify_lock_text

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT =
    joinpath(REPOSITORY_ROOT, "experiments", "financial_strategy_library_panel_v1")
const AMENDMENT_PATH =
    joinpath(EXPERIMENT_ROOT, "amendments", "EXECUTION_AMENDMENT_022.toml")
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_021.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_022.json")
const DESIGN_AGGREGATE = Lock021.DESIGN_AGGREGATE
const PREDECESSOR_AGGREGATE =
    "eb8431487e6f16f58cad9f32b6e020852e83b7e3ea0f2ed395348a074f0b8268"
const PREDECESSOR_FILE_SHA256 =
    "aefefb0ff47ef9fc17c085fa6569061f2b3b6427dc0f891eff75b5551a545741"

const REQUIRED_FILES = (
    Lock021.REQUIRED_FILES...,
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_021.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_022.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_022.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_022.jl",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(value) = bytes2hex(sha256(codeunits(value)))

function _hashes()
    length(REQUIRED_FILES) == length(unique(REQUIRED_FILES)) ||
        error("Lock 022 input list contains duplicates")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) ||
            error("missing Lock 022 input: $relative")
    end
    return Dict(
        relative => _sha256_file(joinpath(REPOSITORY_ROOT, relative)) for
        relative in REQUIRED_FILES
    )
end

_aggregate(hashes) = _sha256_text(join(
    ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
))

function _verify_predecessor()
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 021 is absent")
    text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("historical Lock 021 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 ||
        error("historical Lock 021 file hash differs")
end

function validate_execution_design_022()
    _verify_predecessor()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v22" ||
        error("unexpected Amendment 022 schema")
    amendment["amendment_id"] == "AMENDMENT_022" ||
        error("unexpected Amendment 022 identifier")
    amendment["predecessor_amendment_id"] == "AMENDMENT_021" ||
        error("unexpected Amendment 022 predecessor")
    amendment["lock_021_solver_started_before_amendment"] === false ||
        error("Amendment 022 hides solver work")
    amendment["lock_021_empirical_outcome_produced_before_amendment"] === false ||
        error("Amendment 022 hides a new empirical outcome")
    for key in (
        "scientific_estimands_changed",
        "algorithm_definition_changed",
        "registered_instances_changed",
        "weights_changed",
        "seeds_changed",
        "time_limits_changed",
        "solver_settings_changed",
        "analysis_formulas_changed",
        "registered_denominators_changed",
        "raw_row_values_printed_or_committed",
    )
        amendment[key] === false || error("Amendment 022 declaration changed: $key")
    end
    recovery = amendment["environment_recovery"]
    recovery["sealed_solver_log_count"] == 18 ||
        error("Amendment 022 sealed solver-log count changed")
    recovery["stale_solver_log_count"] == 14 ||
        error("Amendment 022 stale solver-log count changed")
    for key in (
        "require_exact_environment_hash",
        "require_exact_result_audit_hashes",
        "require_exact_checkpoint_directory_aggregate",
        "require_exact_solver_log_directory_aggregate",
        "require_terminal_structural_records",
        "require_recovery_regression_test",
    )
        recovery[key] === true || error("Amendment 022 recovery guard weakened: $key")
    end
    return TOML.parsefile(Lock021.CONFIG_PATH)
end

function _assert_prelock_state(config)
    # Lock 021 sealed this exact local state before its pre-solver guard failed.
    Lock021._assert_prelock_state(config)
    return nothing
end

function _render_lock(hashes)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v22",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_022",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$PREDECESSOR_FILE_SHA256",
  "prelock_checkpoint_directory_aggregate_sha256": "$(Lock021.CHECKPOINT_DIRECTORY_AGGREGATE)",
  "prelock_solver_log_directory_aggregate_sha256": "$(Lock021.SOLVER_LOG_DIRECTORY_AGGREGATE)",
  "prelock_solver_log_count": 18,
  "remaining_mip_solver_run_count": 90,
  "scientific_estimands_changed": false,
  "algorithm_definition_changed": false,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    validate_execution_design_022()
    occursin(
        "\"schema_version\": \"financial-strategy-library-panel-execution-lock-v22\"",
        text,
    ) || error("unexpected or missing Lock 022 schema")
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("Lock 022 aggregate differs")
    for (relative, hash) in hashes
        occursin("\"$relative\": \"$hash\"", text) ||
            error("Lock 022 file hash differs: $relative")
    end
    return aggregate
end

function dry_run()
    config = validate_execution_design_022()
    _assert_prelock_state(config)
    return _aggregate(_hashes())
end

function create_execution_lock_022()
    isfile(LOCK_PATH) && error("Execution Lock 022 already exists")
    config = validate_execution_design_022()
    _assert_prelock_state(config)
    hashes = _hashes()
    text = _render_lock(hashes)
    verify_lock_text(text, hashes)
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, LOCK_PATH; force = false)
    return _aggregate(hashes)
end

verify_execution_lock_022() = isfile(LOCK_PATH) ?
    verify_lock_text(read(LOCK_PATH, String), _hashes()) :
    error("Execution Lock 022 is absent")

function main(args = ARGS)
    if "--create" in args
        println("Lock 022 created: ", create_execution_lock_022())
    elseif "--check" in args
        println("Lock 022 valid: ", verify_execution_lock_022())
    elseif "--dry-run" in args
        println("Lock 022 dry run valid: ", dry_run())
    else
        error("usage: lock_financial_strategy_library_panel_v1_execution_022.jl --create|--check|--dry-run")
    end
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution022.main()
end
