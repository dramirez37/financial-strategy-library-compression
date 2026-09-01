module LockFinancialStrategyLibraryPanelV1Execution020

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_019.jl"))
const Lock019 = LockFinancialStrategyLibraryPanelV1Execution019

export create_execution_lock_020,
       dry_run,
       main,
       validate_execution_design_020,
       verify_execution_lock_020,
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
    "EXECUTION_AMENDMENT_020.toml",
)
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_019.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_020.json")
const DESIGN_AGGREGATE = Lock019.DESIGN_AGGREGATE
const PREDECESSOR_AGGREGATE =
    "bd5b20ff313fc2d8ae1b60387c11c1a00fdcdc432d0ea1fd9f9174505c09298e"
const PREDECESSOR_FILE_SHA256 =
    "e0f7363945ade5ac2a957a887582fa9682317f8d4040b4ab62ebffb7f44b7ed7"
const CHECKPOINT_AGGREGATE =
    "74f8e021f47b53ab4b23718224a8d9879bf95fb30b50f3f547b9841b8ce42d83"
const PRELOCK_RESULT_AUDIT_SHA256 =
    "9cae6c3f93680c7ae8b0c1eacdb1a9b862323a27d6ce8f08a8f2a38f1bc93112"
const PRELOCK_STRUCTURAL_AUDIT_SHA256 =
    "95f49fef87dd407901e685d84e9e95c8dec37aabd6f1b377df99ee8c6e284dcf"
const PRELOCK_ANALYSIS_MANIFEST_SHA256 =
    "fbc85c2658fc21e0bd73aca4c6e0f9c277e41566b2bae7cf6046fea16b51d850"
const PRELOCK_ANALYSIS_AUDIT_SHA256 =
    "df8a47097f3f74f252c0f244c0eea4d28d29b3fa99e41fb9db3abddda5462d11"
const PRELOCK_ENVIRONMENT_SHA256 =
    "b6f3557395c5301ebda739f79ebba27c28869786f5a6690b23466b048bdc977e"
const KNOWN_MIP_FAILURE =
    "ArgumentError: the supplied warm start is not feasible after exact preprocessing projection"
const KNOWN_RECOVERY_FAILURE_PREFIX =
    "corrective checkpoint is not bound to Lock 018:"

const REQUIRED_FILES = (
    Lock019.REQUIRED_FILES...,
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_019.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_020.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_020.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_020.jl",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(value) = bytes2hex(sha256(codeunits(value)))

function _hashes()
    length(REQUIRED_FILES) == length(unique(REQUIRED_FILES)) ||
        error("Lock 020 input list contains duplicates")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) ||
            error("missing Lock 020 input: $relative")
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
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 019 is absent")
    text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("historical Lock 019 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 ||
        error("historical Lock 019 file hash differs")
end

function validate_execution_design_020()
    _verify_predecessor()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v20" ||
        error("unexpected Amendment 020 schema")
    amendment["amendment_id"] == "AMENDMENT_020" ||
        error("unexpected Amendment 020 identifier")
    amendment["predecessor_amendment_id"] == "AMENDMENT_019" ||
        error("unexpected Amendment 020 predecessor")
    amendment["checkpoint_predecessor_aggregate_sha256"] == CHECKPOINT_AGGREGATE ||
        error("Amendment 020 checkpoint aggregate changed")
    amendment["corrected_mip_checkpoint_persisted_before_amendment"] === false ||
        error("Amendment 020 hides a persisted corrected checkpoint")
    amendment["corrected_mip_result_persisted_before_amendment"] === false ||
        error("Amendment 020 hides a persisted corrected result")
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
        amendment[key] === false || error("Amendment 020 declaration changed: $key")
    end
    recovery = amendment["checkpoint_recovery"]
    recovery["prevalidate_before_solver"] === true ||
        error("Amendment 020 no longer prevalidates checkpoints")
    recovery["require_exact_lock_005_aggregate"] === true ||
        error("Amendment 020 checkpoint namespace weakened")
    recovery["preserve_unaffected_algorithm_rows"] == 6 ||
        error("Amendment 020 preserved algorithm count changed")
    return TOML.parsefile(Lock019.Lock018.CONFIG_PATH)
end

function _assert_hash(path, expected, label)
    isfile(path) || error("Lock 020 prelock $label is absent")
    _sha256_file(path) == expected || error("Lock 020 prelock $label differs")
end

function _assert_prelock_state(config)
    root = joinpath(REPOSITORY_ROOT, String(config["paths"]["local_results_root"]))
    _assert_hash(joinpath(root, "RESULT_AUDIT.toml"), PRELOCK_RESULT_AUDIT_SHA256, "result audit")
    _assert_hash(joinpath(root, "STRUCTURAL_AUDIT.toml"), PRELOCK_STRUCTURAL_AUDIT_SHA256, "structural audit")
    _assert_hash(joinpath(root, "analysis", "ANALYSIS_MANIFEST.toml"), PRELOCK_ANALYSIS_MANIFEST_SHA256, "analysis manifest")
    _assert_hash(joinpath(root, "analysis", "ANALYSIS_AUDIT.toml"), PRELOCK_ANALYSIS_AUDIT_SHA256, "analysis audit")
    _assert_hash(joinpath(root, "ENVIRONMENT.toml"), PRELOCK_ENVIRONMENT_SHA256, "environment")

    structural_counts = Dict("result" => 0, "failure" => 0, "preparation" => 0)
    for name in readdir(joinpath(root, "structural"))
        endswith(name, ".toml") || continue
        payload = TOML.parsefile(joinpath(root, "structural", name))
        schema = get(payload, "schema_version", "")
        if schema == "financial-strategy-library-panel-instance-result-v1"
            structural_counts["result"] += 1
        elseif schema == "financial-strategy-library-panel-instance-failure-v1"
            structural_counts["failure"] += 1
            get(payload, "failure_type", "") == "ErrorException" ||
                error("Lock 020 prelock recovery failure type differs")
            startswith(get(payload, "failure_message", ""), KNOWN_RECOVERY_FAILURE_PREFIX) ||
                error("Lock 020 prelock recovery failure message differs")
        elseif schema == "financial-strategy-library-panel-preparation-failure-result-v1"
            structural_counts["preparation"] += 1
        else
            error("Lock 020 prelock structural schema differs")
        end
    end
    structural_counts == Dict("result" => 107, "failure" => 1, "preparation" => 72) ||
        error("Lock 020 prelock structural counts differ")

    checkpoint_count = 0
    mip_error_count = 0
    mip_candidate_count = 0
    corrected_count = 0
    for (directory, _, files) in walkdir(joinpath(root, "checkpoints")), name in files
        endswith(name, ".toml") || continue
        payload = TOML.parsefile(joinpath(directory, name))
        checkpoint_count += 1
        payload["execution_lock_aggregate_sha256"] == CHECKPOINT_AGGREGATE ||
            error("Lock 020 prelock checkpoint namespace differs")
        get(payload, "corrective_execution_amendment_id", "") == "" ||
            (corrected_count += 1)
        payload["algorithm_id"] == "jump_highs_tagged_cover" || continue
        record = payload["record"]
        if get(record, "status", "") == "ERROR"
            get(record, "failure_message", "") == KNOWN_MIP_FAILURE ||
                error("Lock 020 prelock MIP failure differs")
            mip_error_count += 1
        elseif get(record, "candidate_returned", false) === true
            mip_candidate_count += 1
        else
            error("Lock 020 prelock MIP checkpoint has an unexpected state")
        end
    end
    checkpoint_count == 756 || error("Lock 020 prelock checkpoint count differs")
    mip_error_count == 94 || error("Lock 020 prelock MIP error count differs")
    mip_candidate_count == 14 || error("Lock 020 prelock MIP candidate count differs")
    corrected_count == 0 || error("Lock 020 prelock includes a corrected checkpoint")
end

function _render_lock(hashes)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v20",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_020",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$PREDECESSOR_FILE_SHA256",
  "checkpoint_predecessor_execution_lock_aggregate_sha256": "$CHECKPOINT_AGGREGATE",
  "lock_019_execution_failure_count": 1,
  "corrected_mip_checkpoint_count_before_lock": 0,
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
    validate_execution_design_020()
    occursin(
        "\"schema_version\": \"financial-strategy-library-panel-execution-lock-v20\"",
        text,
    ) || error("unexpected or missing Lock 020 schema")
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("Lock 020 aggregate differs")
    for (relative, hash) in hashes
        occursin("\"$relative\": \"$hash\"", text) ||
            error("Lock 020 file hash differs: $relative")
    end
    return aggregate
end

function dry_run()
    config = validate_execution_design_020()
    _assert_prelock_state(config)
    return _aggregate(_hashes())
end

function create_execution_lock_020()
    isfile(LOCK_PATH) && error("Execution Lock 020 already exists")
    config = validate_execution_design_020()
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

verify_execution_lock_020() = isfile(LOCK_PATH) ?
    verify_lock_text(read(LOCK_PATH, String), _hashes()) :
    error("Execution Lock 020 is absent")

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v1_execution_020.jl --dry-run|--lock|--check",
    )
    mode = only(args)
    mode == "--dry-run" && return println("Lock 020 dry run passed: ", dry_run())
    mode == "--lock" && return println("Lock 020 created: ", create_execution_lock_020())
    mode == "--check" && return println("Lock 020 valid: ", verify_execution_lock_020())
    error("unknown Lock 020 mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution020.main()
end
