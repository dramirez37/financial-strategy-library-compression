module LockFinancialStrategyLibraryPanelV1Execution023

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_022.jl"))
const Lock022 = LockFinancialStrategyLibraryPanelV1Execution022

export create_execution_lock_023,
       dry_run,
       main,
       validate_execution_design_023,
       verify_execution_lock_023,
       verify_lock_text

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT =
    joinpath(REPOSITORY_ROOT, "experiments", "financial_strategy_library_panel_v1")
const AMENDMENT_PATH =
    joinpath(EXPERIMENT_ROOT, "amendments", "EXECUTION_AMENDMENT_023.toml")
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_022.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_023.json")
const DESIGN_AGGREGATE = Lock022.DESIGN_AGGREGATE
const PREDECESSOR_AGGREGATE =
    "0f2faa6c76dfedee49f8f8e5209959cad2de8f89fab1cae93dfe4d8735e4ccc1"
const PREDECESSOR_FILE_SHA256 =
    "4e2a9b1490fad5e4504a8948c4a05caf3e08172d9b3a9251d571eb261eed837c"
const LOCK_005_AGGREGATE = Lock022.Lock021.LOCK_005_AGGREGATE
const LOCK_020_AGGREGATE = Lock022.Lock021.PREDECESSOR_AGGREGATE
const CHECKPOINT_DIRECTORY_AGGREGATE =
    "1e8ac2b11353aedddc6b7efe2f0385512d44f825903c5d8dff55c6a21c8cec98"
const SOLVER_LOG_DIRECTORY_AGGREGATE =
    "5764d7336ba8f388d706eb55fd2c3e1860c703ab47656e13ac7acb050a75c9ef"
const PRELOCK_ENVIRONMENT_SHA256 =
    "1f62b4aba6c5192f304c4b2a2d656a2370698598963b1ff8f48cd5100ed4b719"
const PRELOCK_RESULT_AUDIT_SHA256 =
    "9cae6c3f93680c7ae8b0c1eacdb1a9b862323a27d6ce8f08a8f2a38f1bc93112"
const PRELOCK_STRUCTURAL_AUDIT_SHA256 =
    "e6919d98d7ae5c323d6b5d91016486d0409ce85dbb4550be8d0efb927ce7c11c"
const PRELOCK_ANALYSIS_MANIFEST_SHA256 =
    "fbc85c2658fc21e0bd73aca4c6e0f9c277e41566b2bae7cf6046fea16b51d850"
const PRELOCK_ANALYSIS_AUDIT_SHA256 =
    "df8a47097f3f74f252c0f244c0eea4d28d29b3fa99e41fb9db3abddda5462d11"

const REQUIRED_FILES = (
    Lock022.REQUIRED_FILES...,
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_022.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_023.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_023.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_023.jl",
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
        error("Lock 023 input list contains duplicates")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) ||
            error("missing Lock 023 input: $relative")
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
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 022 is absent")
    text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("historical Lock 022 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 ||
        error("historical Lock 022 file hash differs")
end

function validate_execution_design_023()
    _verify_predecessor()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v23" ||
        error("unexpected Amendment 023 schema")
    amendment["amendment_id"] == "AMENDMENT_023" ||
        error("unexpected Amendment 023 identifier")
    amendment["predecessor_amendment_id"] == "AMENDMENT_022" ||
        error("unexpected Amendment 023 predecessor")
    amendment["lock_022_completed_new_mip_solver_runs"] == 90 ||
        error("Amendment 023 Lock 022 solver count changed")
    amendment["lock_022_final_mip_candidate_count"] == 108 ||
        error("Amendment 023 MIP candidate count changed")
    amendment["lock_022_structural_audit_passed"] === false ||
        error("Amendment 023 hides the failed structural audit")
    amendment["lock_022_postdecision_refresh_started"] === false ||
        error("Amendment 023 hides postdecision work")
    amendment["lock_022_analysis_started"] === false ||
        error("Amendment 023 hides analysis work")
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
        "candidate_identities_changed",
        "candidate_burdens_changed",
        "raw_row_values_printed_or_committed",
    )
        amendment[key] === false || error("Amendment 023 declaration changed: $key")
    end
    provenance = amendment["projection_provenance"]
    provenance["affected_successful_mip_records"] == 108 ||
        error("Amendment 023 provenance denominator changed")
    for key in (
        "require_exact_warm_start_feasibility",
        "require_exact_substitution_projection",
        "require_exact_projected_burden_nonincrease",
        "require_substitution_count",
        "require_reconstruction_marker",
    )
        provenance[key] === true || error("Amendment 023 provenance check weakened: $key")
    end
    amendment["checkpoint_recovery"]["new_solver_runs"] == 0 ||
        error("Amendment 023 would rerun a solver")
    return TOML.parsefile(Lock022.Lock021.CONFIG_PATH)
end

function _assert_hash(path, expected, label)
    isfile(path) || error("Lock 023 prelock $label is absent")
    _sha256_file(path) == expected || error("Lock 023 prelock $label differs")
end

function _assert_prelock_state(config)
    root = joinpath(REPOSITORY_ROOT, String(config["paths"]["local_results_root"]))
    _assert_hash(joinpath(root, "ENVIRONMENT.toml"), PRELOCK_ENVIRONMENT_SHA256, "environment")
    _assert_hash(joinpath(root, "RESULT_AUDIT.toml"), PRELOCK_RESULT_AUDIT_SHA256, "result audit")
    _assert_hash(joinpath(root, "STRUCTURAL_AUDIT.toml"), PRELOCK_STRUCTURAL_AUDIT_SHA256, "structural audit")
    _assert_hash(joinpath(root, "analysis", "ANALYSIS_MANIFEST.toml"), PRELOCK_ANALYSIS_MANIFEST_SHA256, "analysis manifest")
    _assert_hash(joinpath(root, "analysis", "ANALYSIS_AUDIT.toml"), PRELOCK_ANALYSIS_AUDIT_SHA256, "analysis audit")
    _directory_aggregate(joinpath(root, "checkpoints")) == CHECKPOINT_DIRECTORY_AGGREGATE ||
        error("Lock 023 prelock checkpoint directory differs")
    _directory_aggregate(joinpath(root, "solver_logs")) == SOLVER_LOG_DIRECTORY_AGGREGATE ||
        error("Lock 023 prelock solver-log directory differs")

    lock_counts = Dict(LOCK_005_AGGREGATE => 0, LOCK_020_AGGREGATE => 0, PREDECESSOR_AGGREGATE => 0)
    mip_candidate_count = 0
    mip_error_count = 0
    mip_missing_source_count = 0
    checkpoint_count = 0
    for (directory, _, files) in walkdir(joinpath(root, "checkpoints")), name in files
        endswith(name, ".toml") || continue
        payload = TOML.parsefile(joinpath(directory, name))
        checkpoint_count += 1
        checkpoint_lock = String(payload["execution_lock_aggregate_sha256"])
        haskey(lock_counts, checkpoint_lock) ||
            error("Lock 023 prelock checkpoint uses an undeclared namespace")
        lock_counts[checkpoint_lock] += 1
        payload["algorithm_id"] == "jump_highs_tagged_cover" || continue
        record = payload["record"]
        get(record, "candidate_returned", false) === true && (mip_candidate_count += 1)
        get(record, "status", "") == "ERROR" && (mip_error_count += 1)
        !haskey(record, "warm_start_source") && (mip_missing_source_count += 1)
    end
    checkpoint_count == 756 || error("Lock 023 prelock checkpoint count differs")
    lock_counts[LOCK_005_AGGREGATE] == 662 || error("Lock 023 Lock 005 checkpoint count differs")
    lock_counts[LOCK_020_AGGREGATE] == 4 || error("Lock 023 Lock 020 checkpoint count differs")
    lock_counts[PREDECESSOR_AGGREGATE] == 90 || error("Lock 023 Lock 022 checkpoint count differs")
    mip_candidate_count == 108 || error("Lock 023 MIP candidate count differs")
    mip_error_count == 0 || error("Lock 023 retains a MIP error")
    mip_missing_source_count == 108 || error("Lock 023 missing-provenance count differs")

    schemas = Dict{String,Int}()
    corrected_count = 0
    corrected_missing_source_count = 0
    for name in readdir(joinpath(root, "structural"))
        endswith(name, ".toml") || continue
        payload = TOML.parsefile(joinpath(root, "structural", name))
        schema = String(payload["schema_version"])
        schemas[schema] = get(schemas, schema, 0) + 1
        get(payload, "corrective_execution_amendment_id", "") == "AMENDMENT_021" || continue
        corrected_count += 1
        mip = only(filter(
            row -> row["algorithm_id"] == "jump_highs_tagged_cover",
            payload["algorithms"],
        ))
        !haskey(mip, "warm_start_source") && (corrected_missing_source_count += 1)
    end
    schemas == Dict(
        "financial-strategy-library-panel-instance-result-v1" => 108,
        "financial-strategy-library-panel-preparation-failure-result-v1" => 72,
    ) || error("Lock 023 structural schemas differ")
    corrected_count == 94 || error("Lock 023 corrected structural count differs")
    corrected_missing_source_count == 94 ||
        error("Lock 023 corrected missing-provenance count differs")
end

function _render_lock(hashes)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v23",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_023",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$PREDECESSOR_FILE_SHA256",
  "prelock_checkpoint_directory_aggregate_sha256": "$CHECKPOINT_DIRECTORY_AGGREGATE",
  "prelock_solver_log_directory_aggregate_sha256": "$SOLVER_LOG_DIRECTORY_AGGREGATE",
  "prelock_mip_candidate_count": 108,
  "prelock_missing_projection_provenance_count": 108,
  "new_solver_run_count": 0,
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
    validate_execution_design_023()
    occursin(
        "\"schema_version\": \"financial-strategy-library-panel-execution-lock-v23\"",
        text,
    ) || error("unexpected or missing Lock 023 schema")
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("Lock 023 aggregate differs")
    for (relative, hash) in hashes
        occursin("\"$relative\": \"$hash\"", text) ||
            error("Lock 023 file hash differs: $relative")
    end
    return aggregate
end

function dry_run()
    config = validate_execution_design_023()
    _assert_prelock_state(config)
    return _aggregate(_hashes())
end

function create_execution_lock_023()
    isfile(LOCK_PATH) && error("Execution Lock 023 already exists")
    config = validate_execution_design_023()
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

verify_execution_lock_023() = isfile(LOCK_PATH) ?
    verify_lock_text(read(LOCK_PATH, String), _hashes()) :
    error("Execution Lock 023 is absent")

function main(args = ARGS)
    if "--create" in args
        println("Lock 023 created: ", create_execution_lock_023())
    elseif "--check" in args
        println("Lock 023 valid: ", verify_execution_lock_023())
    elseif "--dry-run" in args
        println("Lock 023 dry run valid: ", dry_run())
    else
        error("usage: lock_financial_strategy_library_panel_v1_execution_023.jl --create|--check|--dry-run")
    end
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution023.main()
end
