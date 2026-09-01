module LockFinancialStrategyLibraryPanelV1Execution019

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_018.jl"))
const Lock018 = LockFinancialStrategyLibraryPanelV1Execution018

export create_execution_lock_019,
       dry_run,
       main,
       validate_execution_design_019,
       verify_execution_lock_019,
       verify_lock_text

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v1",
)
const AMENDMENT_PATH = joinpath(
    EXPERIMENT_ROOT,
    "amendments",
    "EXECUTION_AMENDMENT_019.toml",
)
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_018.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_019.json")
const DESIGN_AGGREGATE = Lock018.DESIGN_AGGREGATE
const PREDECESSOR_AGGREGATE =
    "e1489a49bd9b9a9a49c94f5ad145919133b88fe26622a8a293becd0fd2f9820b"
const PREDECESSOR_FILE_SHA256 =
    "49de4c1d0851e532395795a853cd4e43fac2231f2b0b9dc0681f496501d99a57"
const PRELOCK_RESULT_AUDIT_SHA256 =
    "9cae6c3f93680c7ae8b0c1eacdb1a9b862323a27d6ce8f08a8f2a38f1bc93112"
const PRELOCK_STRUCTURAL_AUDIT_SHA256 =
    "95f49fef87dd407901e685d84e9e95c8dec37aabd6f1b377df99ee8c6e284dcf"
const PRELOCK_ANALYSIS_MANIFEST_SHA256 =
    "fbc85c2658fc21e0bd73aca4c6e0f9c277e41566b2bae7cf6046fea16b51d850"
const PRELOCK_ANALYSIS_AUDIT_SHA256 =
    "df8a47097f3f74f252c0f244c0eea4d28d29b3fa99e41fb9db3abddda5462d11"
const KNOWN_FAILURE_MESSAGE =
    "ArgumentError: the supplied warm start is not feasible after exact preprocessing projection"

const REQUIRED_FILES = (
    Lock018.REQUIRED_FILES...,
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_018.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_019.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_019.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_019.jl",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(value) = bytes2hex(sha256(codeunits(value)))

function _hashes()
    length(REQUIRED_FILES) == length(unique(REQUIRED_FILES)) ||
        error("Lock 019 input list contains duplicates")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) ||
            error("missing Lock 019 input: $relative")
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
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 018 is absent")
    text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("historical Lock 018 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 ||
        error("historical Lock 018 file hash differs")
end

function validate_execution_design_019()
    _verify_predecessor()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v19" ||
        error("unexpected Amendment 019 schema")
    amendment["amendment_id"] == "AMENDMENT_019" ||
        error("unexpected Amendment 019 identifier")
    amendment["predecessor_amendment_id"] == "AMENDMENT_018" ||
        error("unexpected Amendment 019 predecessor")
    amendment["classification"] == "correct_invalid_mip_warm_start_projection" ||
        error("Amendment 019 classification changed")
    amendment["algorithm_or_solver_outcomes_observed_before_amendment"] === true ||
        error("Amendment 019 hides prior outcome access")
    amendment["observed_mip_error_count"] == 94 ||
        error("Amendment 019 observed MIP error count changed")
    amendment["observed_mip_candidate_count"] == 14 ||
        error("Amendment 019 observed MIP candidate count changed")
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
        amendment[key] === false || error("Amendment 019 declaration changed: $key")
    end
    correction = amendment["corrective_resume"]
    correction["rerun_algorithm_id"] == "jump_highs_tagged_cover" ||
        error("Amendment 019 rerun algorithm changed")
    correction["matching_predecessor_failure_message"] == KNOWN_FAILURE_MESSAGE ||
        error("Amendment 019 predecessor failure changed")
    correction["expected_corrected_row_count"] == 94 ||
        error("Amendment 019 corrected row count changed")
    correction["preserve_other_algorithm_rows_per_corrected_instance"] == 6 ||
        error("Amendment 019 preserved algorithm count changed")
    return TOML.parsefile(Lock018.CONFIG_PATH)
end

function _assert_prelock_state(config)
    root = joinpath(REPOSITORY_ROOT, String(config["paths"]["local_results_root"]))
    result_path = joinpath(root, "RESULT_AUDIT.toml")
    structural_audit_path = joinpath(root, "STRUCTURAL_AUDIT.toml")
    manifest_path = joinpath(root, "analysis", "ANALYSIS_MANIFEST.toml")
    analysis_audit_path = joinpath(root, "analysis", "ANALYSIS_AUDIT.toml")
    _sha256_file(result_path) == PRELOCK_RESULT_AUDIT_SHA256 ||
        error("Lock 019 prelock result audit differs")
    _sha256_file(structural_audit_path) == PRELOCK_STRUCTURAL_AUDIT_SHA256 ||
        error("Lock 019 prelock structural audit differs")
    _sha256_file(manifest_path) == PRELOCK_ANALYSIS_MANIFEST_SHA256 ||
        error("Lock 019 prelock analysis manifest differs")
    _sha256_file(analysis_audit_path) == PRELOCK_ANALYSIS_AUDIT_SHA256 ||
        error("Lock 019 prelock analysis audit differs")
    for path in (result_path, structural_audit_path, analysis_audit_path)
        audit = TOML.parsefile(path)
        audit["passed"] === true || error("Lock 019 requires passing predecessor audits")
        audit["execution_lock_aggregate_sha256"] == PREDECESSOR_AGGREGATE ||
            error("Lock 019 predecessor audit binding differs")
    end

    structural = joinpath(root, "structural")
    error_count = 0
    candidate_count = 0
    successful_count = 0
    for name in readdir(structural)
        endswith(name, ".toml") || continue
        payload = TOML.parsefile(joinpath(structural, name))
        get(payload, "schema_version", "") ==
        "financial-strategy-library-panel-instance-result-v1" || continue
        successful_count += 1
        mip = only(filter(
            row -> row["algorithm_id"] == "jump_highs_tagged_cover",
            payload["algorithms"],
        ))
        if mip["status"] == "ERROR"
            mip["failure_type"] == "ArgumentError" ||
                error("Lock 019 predecessor MIP failure type differs")
            mip["failure_message"] == KNOWN_FAILURE_MESSAGE ||
                error("Lock 019 predecessor MIP failure message differs")
            error_count += 1
        elseif mip["candidate_returned"] === true
            candidate_count += 1
        else
            error("Lock 019 predecessor MIP row has an unexpected state")
        end
    end
    successful_count == 108 || error("Lock 019 predecessor success count differs")
    error_count == 94 || error("Lock 019 predecessor MIP error count differs")
    candidate_count == 14 || error("Lock 019 predecessor MIP candidate count differs")
end

function _render_lock(hashes)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v19",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_019",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$PREDECESSOR_FILE_SHA256",
  "observed_predecessor_mip_error_count": 94,
  "corrective_mip_row_count": 94,
  "preserved_algorithm_rows_per_corrected_instance": 6,
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
    validate_execution_design_019()
    occursin(
        "\"schema_version\": \"financial-strategy-library-panel-execution-lock-v19\"",
        text,
    ) || error("unexpected or missing Lock 019 schema")
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("Lock 019 aggregate differs")
    for (relative, hash) in hashes
        occursin("\"$relative\": \"$hash\"", text) ||
            error("Lock 019 file hash differs: $relative")
    end
    return aggregate
end

function dry_run()
    config = validate_execution_design_019()
    _assert_prelock_state(config)
    return _aggregate(_hashes())
end

function create_execution_lock_019()
    isfile(LOCK_PATH) && error("Execution Lock 019 already exists")
    config = validate_execution_design_019()
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

verify_execution_lock_019() = isfile(LOCK_PATH) ?
    verify_lock_text(read(LOCK_PATH, String), _hashes()) :
    error("Execution Lock 019 is absent")

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v1_execution_019.jl --dry-run|--lock|--check",
    )
    mode = only(args)
    mode == "--dry-run" && return println("Lock 019 dry run passed: ", dry_run())
    mode == "--lock" && return println("Lock 019 created: ", create_execution_lock_019())
    mode == "--check" && return println("Lock 019 valid: ", verify_execution_lock_019())
    error("unknown Lock 019 mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution019.main()
end
