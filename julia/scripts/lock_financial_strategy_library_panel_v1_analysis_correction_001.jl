module LockFinancialStrategyLibraryPanelV1AnalysisCorrection001

using Dates
using SHA: sha256
using TOML

export create_lock, main, verify_lock

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v1",
)
const CORRECTION_ROOT = joinpath(EXPERIMENT_ROOT, "analysis_corrections")
const LOCK_PATH = joinpath(CORRECTION_ROOT, "ANALYSIS_LOCK_001.json")
const EXECUTION_LOCK_AGGREGATE =
    "0fcfb4fb0a9fb1af0a2ebe7eb79389e90fc6713cf7cd11e99e1077c1e9f91fc3"
const EXECUTION_LOCK_FILE_SHA256 =
    "86bb8c87030ae7e0e48979ef27807c6ac69686bec6503f89e57169b9ce06c2de"
const REQUIRED_FILES = (
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_023.json",
    "experiments/financial_strategy_library_panel_v1/ANALYSIS_PLAN.md",
    "experiments/financial_strategy_library_panel_v1/DATA_CONTRACT.md",
    "experiments/financial_strategy_library_panel_v1/REPORTING_RULES.md",
    "experiments/financial_strategy_library_panel_v1/analysis_corrections/ANALYSIS_CORRECTION_001.md",
    "experiments/financial_strategy_library_panel_v1/analysis_corrections/ANALYSIS_CORRECTION_001.toml",
    "julia/Project.toml",
    "julia/Manifest.toml",
    "julia/src/FinancialPanelParquet.jl",
    "julia/scripts/analyze_financial_strategy_library_panel_v1_corrected.jl",
    "julia/scripts/audit_financial_strategy_library_panel_v1_corrected_analysis.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v1_analysis_correction_001.jl",
    "julia/test/test_financial_strategy_library_panel_v1_analysis_correction.jl",
    "julia/test/run_financial_strategy_library_panel_v1_analysis_correction_tests.jl",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(value) = bytes2hex(sha256(codeunits(value)))

function _hashes()
    length(REQUIRED_FILES) == length(unique(REQUIRED_FILES)) || error("analysis lock inputs duplicate")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) || error("missing analysis lock input: $relative")
    end
    return Dict(
        relative => _sha256_file(joinpath(REPOSITORY_ROOT, relative)) for
        relative in REQUIRED_FILES
    )
end

_aggregate(hashes) = _sha256_text(join(
    ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes))))
))

function _validate_correction()
    correction = TOML.parsefile(joinpath(CORRECTION_ROOT, "ANALYSIS_CORRECTION_001.toml"))
    correction["schema_version"] ==
    "financial-strategy-library-panel-analysis-correction-v1" || error(
        "unexpected analysis correction schema",
    )
    correction["correction_id"] == "ANALYSIS_CORRECTION_001" || error(
        "unexpected analysis correction identifier",
    )
    correction["source_execution_lock_aggregate_sha256"] == EXECUTION_LOCK_AGGREGATE ||
        error("analysis correction uses a different execution lock")
    for key in (
        "scientific_estimands_changed",
        "registered_analysis_plan_changed",
        "algorithm_rows_changed",
        "candidate_identities_changed",
        "candidate_burdens_changed",
        "certificates_changed",
        "solver_results_changed",
        "postdecision_results_changed",
        "registered_denominators_changed",
        "raw_licensed_rows_included",
    )
        correction[key] === false || error("analysis correction declaration changed: $key")
    end
    runtime = correction["runtime_summary"]
    runtime["corrected_inclusion_rule"] ==
    "applicable is true and wall_clock_seconds is present" || error(
        "runtime correction rule changed",
    )
    for key in (
        "skipped_rows_retained_in_registered_denominator",
        "skipped_rows_retained_in_applicability_census",
        "skipped_rows_excluded_from_executed_runtime_distribution",
    )
        runtime[key] === true || error("runtime correction invariant changed: $key")
    end
    execution_lock = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_023.json")
    _sha256_file(execution_lock) == EXECUTION_LOCK_FILE_SHA256 || error(
        "immutable Execution Lock 023 file differs",
    )
    occursin("\"aggregate_sha256\": \"$EXECUTION_LOCK_AGGREGATE\"", read(execution_lock, String)) ||
        error("immutable Execution Lock 023 aggregate differs")
    return true
end

function _render(hashes)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-analysis-lock-v1",
  "experiment_id": "financial-strategy-library-panel-v1",
  "analysis_correction_id": "ANALYSIS_CORRECTION_001",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "source_execution_lock_aggregate_sha256": "$EXECUTION_LOCK_AGGREGATE",
  "runtime_summary_excludes_inapplicable_rows": true,
  "registered_denominators_changed": false,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock()
    _validate_correction()
    isfile(LOCK_PATH) || error("analysis correction lock is absent")
    hashes = _hashes()
    text = read(LOCK_PATH, String)
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("analysis correction lock aggregate differs")
    for (relative, hash) in hashes
        occursin("\"$relative\": \"$hash\"", text) ||
            error("analysis correction lock file hash differs: $relative")
    end
    return aggregate
end

function create_lock()
    _validate_correction()
    hashes = _hashes()
    mkpath(dirname(LOCK_PATH))
    open(LOCK_PATH, "w") do io
        write(io, _render(hashes))
    end
    return verify_lock()
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v1_analysis_correction_001.jl --create|--check",
    )
    mode = only(args)
    mode == "--create" && return println("analysis correction lock created: ", create_lock())
    mode == "--check" && return println("analysis correction lock valid: ", verify_lock())
    error("unknown mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1AnalysisCorrection001.main()
end
