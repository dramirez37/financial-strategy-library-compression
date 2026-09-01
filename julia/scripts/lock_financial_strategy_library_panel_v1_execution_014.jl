module LockFinancialStrategyLibraryPanelV1Execution014

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "lock_financial_strategy_library_panel_v1_execution_013.jl"))
const Lock013 = LockFinancialStrategyLibraryPanelV1Execution013
include(joinpath(@__DIR__, "create_financial_strategy_library_panel_v1_registries.jl"))
const Registries = FinancialStrategyLibraryPanelV1Registries

export create_execution_lock_014,
       dry_run,
       main,
       validate_execution_design_014,
       verify_execution_lock_014,
       verify_lock_text

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v1",
)
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_strategy_library_panel_v1.toml",
)
const AMENDMENT_PATH = joinpath(
    EXPERIMENT_ROOT,
    "amendments",
    "EXECUTION_AMENDMENT_014.toml",
)
const PREDECESSOR_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_013.json")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_014.json")
const DESIGN_AGGREGATE = Lock013.DESIGN_AGGREGATE
const PREDECESSOR_AGGREGATE =
    "a1c6393ea636c87c8f7106b97b2ac37b8670d7d2957bddd1b3ff7bce8ae3fe40"
const PREDECESSOR_FILE_SHA256 =
    "8d450848c5ef0065ebbc8ac0f09bd851cedf0ebaea6c5a8b643ea19c254ae4f2"
const STRUCTURAL_RESULT_AGGREGATE =
    "9564a4c9b0ea28f4cf4a9705e8e489398555032e466ba3fac8c16a98094a012a"
const PRELOCK_POSTDECISION_AGGREGATE =
    "3214c2ee9fa7bee99089b5017b5ec8d5b1bc26b2b0cee174921ae2fd958ff9a1"
const AFFECTED_ORIGIN_SET_SHA256 =
    "6676e4f55e2ace5f1b7ed58e65fa3b882f3640b7577caedb046b9def82eb7ca2"

const REQUIRED_FILES = (
    Lock013.REQUIRED_FILES...,
    "experiments/financial_strategy_library_panel_v1/EXECUTION_LOCK_013.json",
    "experiments/financial_strategy_library_panel_v1/amendments/AMENDMENT_014.md",
    "experiments/financial_strategy_library_panel_v1/amendments/EXECUTION_AMENDMENT_014.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v1_execution_014.jl",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text) = bytes2hex(sha256(codeunits(text)))

function _hashes()
    length(REQUIRED_FILES) == length(unique(REQUIRED_FILES)) ||
        error("Lock 014 input list contains duplicates")
    for relative in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, relative)) ||
            error("missing Lock 014 input: $relative")
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

function _file_aggregate(root, paths)
    hashes = Dict(relpath(path, root) => _sha256_file(path) for path in paths)
    return _aggregate(hashes)
end

function _relative_files(root)
    isdir(root) || return String[]
    files = String[]
    for (directory, _, names) in walkdir(root), name in names
        push!(files, relpath(joinpath(directory, name), root))
    end
    return sort!(files)
end

function _verify_predecessor()
    isfile(PREDECESSOR_LOCK_PATH) || error("Execution Lock 013 is absent")
    predecessor_text = read(PREDECESSOR_LOCK_PATH, String)
    occursin("\"aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", predecessor_text) ||
        error("historical Lock 013 aggregate differs")
    _sha256_file(PREDECESSOR_LOCK_PATH) == PREDECESSOR_FILE_SHA256 ||
        error("historical Lock 013 file hash differs")
    return nothing
end

function validate_execution_design_014()
    _verify_predecessor()
    amendment = TOML.parsefile(AMENDMENT_PATH)
    amendment["schema_version"] ==
    "financial-strategy-library-panel-execution-amendment-v14" ||
        error("unexpected Amendment 014 schema")
    amendment["amendment_id"] == "AMENDMENT_014" ||
        error("unexpected Amendment 014 identifier")
    amendment["predecessor_amendment_id"] == "AMENDMENT_013" ||
        error("unexpected Amendment 014 predecessor")
    amendment["classification"] ==
    "registered_failure_persistence_implementation_correction" ||
        error("Amendment 014 classification changed")
    amendment["outcome_blind_prospective_amendment"] === false ||
        error("Amendment 014 conceals existing postdecision records")
    for (key, expected) in (
        "postdecision_result_records_before_amendment" => 108,
        "ordinary_postdecision_records_before_amendment" => 27,
        "terminal_dp_unavailable_records_before_amendment" => 9,
        "structural_failure_postdecision_records_before_amendment" => 72,
        "unresolved_postdecision_records_before_amendment" => 72,
        "observed_insufficient_profile_job_failures" => 72,
        "observed_affected_origin_count" => 8,
        "observed_registered_slots_per_affected_origin" => 9,
        "final_result_audit_files_before_amendment" => 0,
        "analysis_artifacts_before_amendment" => 0,
        "temporary_postdecision_records_before_amendment" => 0,
    )
        amendment[key] == expected || error("Amendment 014 disclosure changed: $key")
    end
    for key in (
        "postdecision_numeric_values_inspected_before_amendment",
        "selected_identity_or_burden_result_inspected_before_amendment",
        "solver_status_inspected_before_amendment",
        "raw_row_values_printed_or_committed",
        "raw_identifiers_or_dates_printed_or_committed",
        "scientific_estimands_changed",
        "minimum_profile_observations_changed",
        "origin_registry_changed",
        "library_registry_changed",
        "burden_schedule_registry_changed",
        "seed_registry_changed",
        "algorithm_registry_changed",
        "structural_results_changed",
    )
        amendment[key] === false || error("Amendment 014 declaration changed: $key")
    end
    policy = amendment["profile_failure_policy"]
    policy["exact_failure_message"] ==
    "a registered belief profile has too few observations" ||
        error("registered profile failure class changed")
    policy["minimum_observations_per_belief"] == 25 ||
        error("registered profile minimum changed")
    policy["affected_origin_count"] == 8 || error("affected origin count changed")
    policy["affected_registered_instance_count"] == 72 ||
        error("affected registered-instance count changed")
    policy["affected_algorithm_row_count"] == 504 ||
        error("affected algorithm-row count changed")
    policy["affected_origin_id_set_sha256"] == AFFECTED_ORIGIN_SET_SHA256 ||
        error("affected origin-set hash changed")
    for key in (
        "belief_pooling_permitted",
        "profile_imputation_permitted",
        "minimum_relaxation_permitted",
        "fabricate_postdecision_score",
    )
        policy[key] === false || error("Amendment 014 enables $key")
    end
    config = TOML.parsefile(CONFIG_PATH)
    config["operating_profiles"]["minimum_profile_observations"] == 25 ||
        error("configuration profile minimum changed")
    return config
end

function _registered_stems()
    return sort!(vec(String[
        "$(origin.origin_id)__$(library.library_id)__$(burden.schedule_id)" for
        origin in Registries.origin_rows(), library in Registries.library_rows(),
        burden in Registries.burden_rows()
    ]))
end

function _assert_prelock_state(config)
    local_results = joinpath(
        REPOSITORY_ROOT,
        String(config["paths"]["local_results_root"]),
    )
    postdecision = joinpath(local_results, "postdecision")
    expected = _registered_stems()
    existing_files = sort!(String[
        joinpath(postdecision, name) for name in readdir(postdecision) if endswith(name, ".toml")
    ])
    length(existing_files) == 108 || error("Lock 014 requires 108 postdecision records")
    _file_aggregate(postdecision, existing_files) == PRELOCK_POSTDECISION_AGGREGATE ||
        error("Lock 014 preexisting postdecision aggregate differs")
    existing_stems = Set(first(splitext(basename(path))) for path in existing_files)
    missing_stems = String[stem for stem in expected if !(stem in existing_stems)]
    length(missing_stems) == 72 || error("Lock 014 unresolved key count differs")
    missing_by_origin = Dict{String,Int}()
    for stem in missing_stems
        origin_id = first(split(stem, "__"))
        missing_by_origin[origin_id] = get(missing_by_origin, origin_id, 0) + 1
    end
    length(missing_by_origin) == 8 || error("Lock 014 unresolved origin count differs")
    all(==(9), values(missing_by_origin)) ||
        error("Lock 014 unresolved keys are not eight complete origin blocks")
    _sha256_text(join(sort!(collect(keys(missing_by_origin))), '\n')) ==
    AFFECTED_ORIGIN_SET_SHA256 || error("Lock 014 unresolved origin-set hash differs")
    schema_counts = Dict{String,Int}()
    for path in existing_files
        schema = String(get(TOML.parsefile(path), "schema_version", ""))
        schema_counts[schema] = get(schema_counts, schema, 0) + 1
    end
    schema_counts == Dict(
        "financial-strategy-library-panel-postdecision-v1" => 27,
        "financial-strategy-library-panel-postdecision-data-unavailable-v1" => 9,
        "financial-strategy-library-panel-postdecision-failure-v1" => 72,
    ) || error("Lock 014 preexisting postdecision schema census differs")
    isfile(joinpath(local_results, "RESULT_AUDIT.toml")) &&
        error("final result audit predates Lock 014")
    analysis = joinpath(local_results, "analysis")
    isempty(_relative_files(analysis)) || error("analysis artifacts predate Lock 014")
    temporary_count = sum(
        count(name -> occursin(".tmp.", name), files) for
        (_, _, files) in walkdir(local_results)
    )
    temporary_count == 0 || error("temporary records predate Lock 014")
    structural_audit = TOML.parsefile(joinpath(local_results, "STRUCTURAL_AUDIT.toml"))
    structural_audit["passed"] === true || error("structural audit did not pass")
    structural_audit["execution_lock_aggregate_sha256"] == PREDECESSOR_AGGREGATE ||
        error("structural audit is not bound to Lock 013")
    structural_audit["structural_result_aggregate_sha256"] == STRUCTURAL_RESULT_AGGREGATE ||
        error("structural result aggregate differs")
    public_results = joinpath(
        REPOSITORY_ROOT,
        String(config["paths"]["public_results_root"]),
    )
    isempty(_relative_files(public_results)) || error("public results predate Lock 014")
    return nothing
end

function _render_lock(hashes)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-execution-lock-v14",
  "experiment_id": "financial-strategy-library-panel-v1",
  "amendment_id": "AMENDMENT_014",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "design_lock_aggregate_sha256": "$DESIGN_AGGREGATE",
  "predecessor_execution_lock_aggregate_sha256": "$PREDECESSOR_AGGREGATE",
  "predecessor_execution_lock_file_sha256": "$PREDECESSOR_FILE_SHA256",
  "postdecision_records_before_successor_lock": 108,
  "ordinary_postdecision_records_before_successor_lock": 27,
  "unresolved_insufficient_profile_jobs": 72,
  "affected_postdecision_origins": 8,
  "affected_registered_instances": 72,
  "affected_algorithm_rows": 504,
  "minimum_profile_observations": 25,
  "postdecision_numeric_values_inspected_before_successor_lock": false,
  "outcome_blind_prospective_amendment": false,
  "profile_imputation_permitted": false,
  "scientific_estimands_changed": false,
  "preexisting_postdecision_result_aggregate_sha256": "$PRELOCK_POSTDECISION_AGGREGATE",
  "affected_origin_id_set_sha256": "$AFFECTED_ORIGIN_SET_SHA256",
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    validate_execution_design_014()
    occursin("\"schema_version\": \"financial-strategy-library-panel-execution-lock-v14\"", text) ||
        error("unexpected or missing Lock 014 schema")
    occursin("\"predecessor_execution_lock_aggregate_sha256\": \"$PREDECESSOR_AGGREGATE\"", text) ||
        error("Lock 014 predecessor aggregate differs")
    occursin("\"preexisting_postdecision_result_aggregate_sha256\": \"$PRELOCK_POSTDECISION_AGGREGATE\"", text) ||
        error("Lock 014 preexisting result aggregate differs")
    occursin("\"affected_origin_id_set_sha256\": \"$AFFECTED_ORIGIN_SET_SHA256\"", text) ||
        error("Lock 014 affected-origin hash differs")
    for declaration in (
        "postdecision_numeric_values_inspected_before_successor_lock",
        "outcome_blind_prospective_amendment",
        "profile_imputation_permitted",
        "scientific_estimands_changed",
    )
        occursin("\"$declaration\": false", text) ||
            error("invalid Lock 014 declaration: $declaration")
    end
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("Lock 014 aggregate differs")
    for (relative, hash) in hashes
        occursin("\"$relative\": \"$hash\"", text) ||
            error("Lock 014 file hash differs: $relative")
    end
    return aggregate
end

function dry_run()
    config = validate_execution_design_014()
    _assert_prelock_state(config)
    return _aggregate(_hashes())
end

function create_execution_lock_014()
    isfile(LOCK_PATH) && error("Execution Lock 014 already exists")
    config = validate_execution_design_014()
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

function verify_execution_lock_014()
    isfile(LOCK_PATH) || error("Execution Lock 014 is absent")
    return verify_lock_text(read(LOCK_PATH, String), _hashes())
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v1_execution_014.jl --dry-run|--lock|--check",
    )
    mode = only(args)
    mode == "--dry-run" && return println("Lock 014 dry run passed: ", dry_run())
    mode == "--lock" && return println("Lock 014 created: ", create_execution_lock_014())
    mode == "--check" && return println("Lock 014 valid: ", verify_execution_lock_014())
    error("unknown Lock 014 mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1Execution014.main()
end
