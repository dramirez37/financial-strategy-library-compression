module LockFinancialStrategyLibraryPanelV1Execution021

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_020.jl"))
const Lock020 = LockFinancialStrategyLibraryPanelV1Execution020

export create_execution_lock_021,
       dry_run,
       main,
       validate_execution_design_021,
       verify_execution_lock_021,
       verify_lock_text

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(REPOSITORY_ROOT, "experiments", "financial_strategy_library_panel_v1")
const CONFIG_PATH = joinpath(REPOSITORY_ROOT, "experiments", "configs", "financial_strategy_library_panel_v1.toml")
const AMENDMENT_PATH = joinpath(EXPERIMENT_ROOT, "amendments", "EXECUTION_AMENDMENT_021.toml")
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_020.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_021.json")
const DESIGN_AGGREGATE = Lock020.DESIGN_AGGREGATE
const PREDECESSOR_AGGREGATE =
    "2f1322c99baeca02f78daf56d210efb64110b54ad4f517a40cb2efb5e581f74c"
const PREDECESSOR_FILE_SHA256 =
    "0da1c01dce5436c26b9285c3ce8646f21f4201211f443b829efe598b495be19d"
const LOCK_005_AGGREGATE =
    "74f8e021f47b53ab4b23718224a8d9879bf95fb30b50f3f547b9841b8ce42d83"
const CHECKPOINT_DIRECTORY_AGGREGATE =
    "8d467bf976dbbb32bac76bf5c7519ed25c7f5f803440df00349b871207f89141"
const SOLVER_LOG_DIRECTORY_AGGREGATE =
    "66cbfcf201cb7a9c4e530b5debfcecb82faade931ba3e8c476f1ea26d46bde50"
const PRELOCK_ENVIRONMENT_SHA256 =
    "ab0450a6ed876a13a5baf7513118e179e5bdbd6101bf91458a9fcc441649d0d0"
const PRELOCK_RESULT_AUDIT_SHA256 =
    "9cae6c3f93680c7ae8b0c1eacdb1a9b862323a27d6ce8f08a8f2a38f1bc93112"
const PRELOCK_STRUCTURAL_AUDIT_SHA256 =
    "95f49fef87dd407901e685d84e9e95c8dec37aabd6f1b377df99ee8c6e284dcf"
const PRELOCK_ANALYSIS_MANIFEST_SHA256 =
    "fbc85c2658fc21e0bd73aca4c6e0f9c277e41566b2bae7cf6046fea16b51d850"
const PRELOCK_ANALYSIS_AUDIT_SHA256 =
    "df8a47097f3f74f252c0f244c0eea4d28d29b3fa99e41fb9db3abddda5462d11"
const KNOWN_MIP_FAILURE =
    "ArgumentError: the supplied warm start is not feasible after exact preprocessing projection"

const REQUIRED_FILES = (
    Lock020.REQUIRED_FILES...,
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_020.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_021.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_021.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_021.jl",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(value) = bytes2hex(sha256(codeunits(value)))

function _directory_aggregate(directory)
    entries = Dict{String,String}()
    for (root, _, files) in walkdir(directory), file in files
        path = joinpath(root, file)
        entries[relpath(path, directory)] = _sha256_file(path)
    end
    return _sha256_text(join(
        ("$path\0$(entries[path])\n" for path in sort!(collect(keys(entries)))),
    ))
end

function _hashes()
    length(REQUIRED_FILES) == length(unique(REQUIRED_FILES)) ||
        error("Lock 021 input list contains duplicates")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) || error("missing Lock 021 input: $relative")
    end
    return Dict(relative => _sha256_file(joinpath(REPOSITORY_ROOT, relative)) for relative in REQUIRED_FILES)
end

_aggregate(hashes) = _sha256_text(join(
    ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
))

function _verify_predecessor()
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 020 is absent")
    text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("historical Lock 020 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 ||
        error("historical Lock 020 file hash differs")
end

function validate_execution_design_021()
    _verify_predecessor()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] == "financial-strategy-library-panel-execution-amendment-v21" ||
        error("unexpected Amendment 021 schema")
    amendment["amendment_id"] == "AMENDMENT_021" || error("unexpected Amendment 021 identifier")
    amendment["predecessor_amendment_id"] == "AMENDMENT_020" ||
        error("unexpected Amendment 021 predecessor")
    amendment["lock_020_corrected_mip_checkpoint_count"] == 4 ||
        error("Amendment 021 persisted MIP count changed")
    amendment["lock_020_corrected_structural_result_count"] == 0 ||
        error("Amendment 021 hides a corrected structural result")
    for key in (
        "scientific_estimands_changed", "algorithm_definition_changed",
        "registered_instances_changed", "weights_changed", "seeds_changed",
        "time_limits_changed", "solver_settings_changed", "analysis_formulas_changed",
        "registered_denominators_changed", "raw_row_values_printed_or_committed",
    )
        amendment[key] === false || error("Amendment 021 declaration changed: $key")
    end
    amendment["instance_hash_reuse"]["hash_value_or_schema_changed"] === false ||
        error("Amendment 021 changes the instance hash contract")
    amendment["mixed_checkpoint_recovery"]["expected_new_mip_solver_runs"] == 90 ||
        error("Amendment 021 remaining MIP count changed")
    return TOML.parsefile(CONFIG_PATH)
end

function _assert_hash(path, expected, label)
    isfile(path) || error("Lock 021 prelock $label is absent")
    _sha256_file(path) == expected || error("Lock 021 prelock $label differs")
end

function _assert_prelock_state(config)
    root = joinpath(REPOSITORY_ROOT, String(config["paths"]["local_results_root"]))
    _assert_hash(joinpath(root, "ENVIRONMENT.toml"), PRELOCK_ENVIRONMENT_SHA256, "environment")
    _assert_hash(joinpath(root, "RESULT_AUDIT.toml"), PRELOCK_RESULT_AUDIT_SHA256, "result audit")
    _assert_hash(joinpath(root, "STRUCTURAL_AUDIT.toml"), PRELOCK_STRUCTURAL_AUDIT_SHA256, "structural audit")
    _assert_hash(joinpath(root, "analysis", "ANALYSIS_MANIFEST.toml"), PRELOCK_ANALYSIS_MANIFEST_SHA256, "analysis manifest")
    _assert_hash(joinpath(root, "analysis", "ANALYSIS_AUDIT.toml"), PRELOCK_ANALYSIS_AUDIT_SHA256, "analysis audit")
    _directory_aggregate(joinpath(root, "checkpoints")) == CHECKPOINT_DIRECTORY_AGGREGATE ||
        error("Lock 021 prelock checkpoint directory differs")
    _directory_aggregate(joinpath(root, "solver_logs")) == SOLVER_LOG_DIRECTORY_AGGREGATE ||
        error("Lock 021 prelock solver-log directory differs")

    schemas = Dict{String,Int}()
    for name in readdir(joinpath(root, "structural"))
        endswith(name, ".toml") || continue
        schema = String(TOML.parsefile(joinpath(root, "structural", name))["schema_version"])
        schemas[schema] = get(schemas, schema, 0) + 1
    end
    schemas == Dict(
        "financial-strategy-library-panel-instance-result-v1" => 107,
        "financial-strategy-library-panel-instance-failure-v1" => 1,
        "financial-strategy-library-panel-preparation-failure-result-v1" => 72,
    ) || error("Lock 021 prelock structural counts differ")

    lock005_count = 0
    lock020_count = 0
    mip_error_count = 0
    mip_candidate_count = 0
    corrected_mip_count = 0
    for (directory, _, files) in walkdir(joinpath(root, "checkpoints")), name in files
        endswith(name, ".toml") || continue
        payload = TOML.parsefile(joinpath(directory, name))
        checkpoint_lock = String(payload["execution_lock_aggregate_sha256"])
        lock005_count += checkpoint_lock == LOCK_005_AGGREGATE
        lock020_count += checkpoint_lock == PREDECESSOR_AGGREGATE
        checkpoint_lock in (LOCK_005_AGGREGATE, PREDECESSOR_AGGREGATE) ||
            error("Lock 021 prelock checkpoint uses an undeclared namespace")
        payload["algorithm_id"] == "jump_highs_tagged_cover" || continue
        record = payload["record"]
        if checkpoint_lock == LOCK_005_AGGREGATE
            if get(record, "status", "") == "ERROR"
                get(record, "failure_message", "") == KNOWN_MIP_FAILURE ||
                    error("Lock 021 prelock MIP error differs")
                mip_error_count += 1
            elseif get(record, "candidate_returned", false) === true
                mip_candidate_count += 1
            else
                error("Lock 021 prelock Lock 005 MIP state differs")
            end
        else
            get(payload, "corrective_execution_amendment_id", "") == "AMENDMENT_020" ||
                error("Lock 021 prelock corrected MIP provenance differs")
            get(record, "candidate_returned", false) === true ||
                error("Lock 021 prelock corrected MIP lacks a candidate")
            get(record["selection"], "exact_feasible", false) === true ||
                error("Lock 021 prelock corrected MIP lacks its exact certificate")
            mip_candidate_count += 1
            corrected_mip_count += 1
        end
    end
    lock005_count == 752 || error("Lock 021 prelock Lock 005 checkpoint count differs")
    lock020_count == 4 || error("Lock 021 prelock Lock 020 checkpoint count differs")
    mip_error_count == 90 || error("Lock 021 prelock remaining MIP error count differs")
    mip_candidate_count == 18 || error("Lock 021 prelock MIP candidate count differs")
    corrected_mip_count == 4 || error("Lock 021 prelock corrected MIP count differs")
end

function _render_lock(hashes)
    rows = join(("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))), ",\n")
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v21",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_021",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$PREDECESSOR_FILE_SHA256",
  "prelock_checkpoint_directory_aggregate_sha256": "$CHECKPOINT_DIRECTORY_AGGREGATE",
  "prelock_solver_log_directory_aggregate_sha256": "$SOLVER_LOG_DIRECTORY_AGGREGATE",
  "prelock_corrected_mip_checkpoint_count": 4,
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
    validate_execution_design_021()
    occursin("\"schema_version\": \"financial-strategy-library-panel-execution-lock-v21\"", text) ||
        error("unexpected or missing Lock 021 schema")
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) || error("Lock 021 aggregate differs")
    for (relative, hash) in hashes
        occursin("\"$relative\": \"$hash\"", text) || error("Lock 021 file hash differs: $relative")
    end
    return aggregate
end

function dry_run()
    config = validate_execution_design_021()
    _assert_prelock_state(config)
    return _aggregate(_hashes())
end

function create_execution_lock_021()
    isfile(LOCK_PATH) && error("Execution Lock 021 already exists")
    config = validate_execution_design_021()
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

verify_execution_lock_021() = isfile(LOCK_PATH) ?
    verify_lock_text(read(LOCK_PATH, String), _hashes()) : error("Execution Lock 021 is absent")

function main(args = ARGS)
    length(args) == 1 || error("usage: lock_financial_strategy_library_panel_v1_execution_021.jl --dry-run|--lock|--check")
    mode = only(args)
    mode == "--dry-run" && return println("Lock 021 dry run passed: ", dry_run())
    mode == "--lock" && return println("Lock 021 created: ", create_execution_lock_021())
    mode == "--check" && return println("Lock 021 valid: ", verify_execution_lock_021())
    error("unknown Lock 021 mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution021.main()
end
