module LockFinancialStrategyLibraryPanelV3EvaluationStagingValidatorAmendment001

using SHA: sha256
using TOML

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const ORIGINAL_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EVALUATION_EXECUTION_LOCK.toml")
const FAILURE_PATH = joinpath(EXPERIMENT_ROOT, "EVALUATION_STAGING_FAILURE_001.toml")
const PUBLIC_ROBUSTNESS_PATH = joinpath(
    EXPERIMENT_ROOT,
    "proposal_robustness",
    "PROPOSAL_ROBUSTNESS_MANIFEST.toml",
)
const LOCAL_ROBUSTNESS_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal_robustness",
    "PROPOSAL_ROBUSTNESS_LOCAL_MANIFEST.toml",
)
const AMENDMENT_LOCK_PATH = joinpath(
    EXPERIMENT_ROOT,
    "EVALUATION_STAGING_VALIDATOR_AMENDMENT_001_LOCK.toml",
)
const PUBLIC_STAGE_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "evaluation_stage",
    "EVALUATION_STAGE_MANIFEST.toml",
)
const LOCAL_STAGE_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "evaluation",
    "EVALUATION_STAGE_LOCAL_MANIFEST.toml",
)
const AMENDMENT_RECEIPT_PATH = joinpath(
    EXPERIMENT_ROOT,
    "evaluation_stage",
    "EVALUATION_STAGING_VALIDATOR_AMENDMENT_001_RECEIPT.toml",
)

const AMENDMENT_PATHS = [
    "experiments/financial_strategy_library_panel_v3/EVALUATION_STAGING_FAILURE_001.toml",
    "experiments/financial_strategy_library_panel_v3/amendments/EVALUATION_STAGING_VALIDATOR_AMENDMENT_001.md",
    "julia/scripts/stage_financial_strategy_library_panel_v3_evaluation_returns_amendment_001.jl",
    "julia/scripts/run_financial_strategy_library_panel_v3_evaluation_amendment_001.jl",
    "julia/scripts/seal_financial_strategy_library_panel_v3_evaluation_result_amendment_001.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_evaluation_staging_validator_amendment_001.jl",
    "julia/test/test_financial_strategy_library_panel_v3_evaluation_staging_amendment_001.jl",
    "julia/test/run_financial_strategy_library_panel_v3_evaluation_staging_amendment_001_tests.jl",
    "julia/test/test_financial_strategy_library_panel_v3_evaluation_result_seal_amendment_001.jl",
    "julia/test/run_financial_strategy_library_panel_v3_evaluation_result_seal_amendment_001_tests.jl",
]

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _original_contract()
    isfile(ORIGINAL_LOCK_PATH) || error("original evaluation execution lock is absent")
    _sha256_file(ORIGINAL_LOCK_PATH) ==
        "3bdab5694d65f2bbf6b8995df0cd4a6939b25eca5b1f8c650f693ad7c9b1a67b" ||
        error("original evaluation execution lock changed")
    lock = TOML.parsefile(ORIGINAL_LOCK_PATH)
    lock["status"] == "LOCKED_EVALUATION_EXECUTION" ||
        error("original evaluation execution lock status changed")
    hashes = Dict{String,String}(lock["sealed_file_sha256"])
    length(hashes) == 114 || error("original evaluation sealed-file denominator changed")
    for (relative, digest) in hashes
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("original evaluation sealed file is absent: $relative")
        _sha256_file(path) == digest ||
            error("original evaluation sealed file changed: $relative")
    end
    return (; lock, hashes)
end

function _failure_contract()
    isfile(FAILURE_PATH) || error("evaluation staging failure record is absent")
    failure = TOML.parsefile(FAILURE_PATH)
    failure["status"] == "RECORDED_PRE_SCAN_EVALUATION_STAGING_FAILURE" ||
        error("evaluation staging failure status changed")
    failure["original_evaluation_execution_lock_sha256"] ==
        _sha256_file(ORIGINAL_LOCK_PATH) ||
        error("failure record is not bound to the original lock")
    failure["original_staging_source_sha256"] == _sha256_file(joinpath(
        REPOSITORY_ROOT,
        "julia/scripts/stage_financial_strategy_library_panel_v3_evaluation_returns.jl",
    )) || error("failure record is not bound to the original staging source")
    for field in (
        "historical_evaluation_values_inspected",
        "historical_evaluation_values_materialized",
        "historical_evaluation_values_used",
        "master_source_parquet_files_opened",
        "master_identifier_date_rows_scanned",
        "evaluation_stage_parquet_artifacts_created",
        "evaluation_stage_output_file_count_after_failure",
    )
        Int(failure[field]) == 0 || error("failure record does not prove zero: $field")
    end
    failure["evaluation_stage_public_manifest_created"] === false &&
        failure["evaluation_stage_local_manifest_created"] === false ||
        error("failure record reports a stage manifest")
    failure["original_evaluation_execution_lock_preserved"] === true ||
        error("failure record does not preserve the original lock")
    return failure
end

function _choice_ids(choice)
    return String.(collect(get(choice, "strategy_ids", String[])))
end

function _semantic_audit()
    public = TOML.parsefile(PUBLIC_ROBUSTNESS_PATH)
    local_manifest = TOML.parsefile(LOCAL_ROBUSTNESS_PATH)
    public_cells = Dict(Int(cell["cell_index"]) => cell for cell in public["cells"])
    local_cells = Dict(
        Int(cell["cell_index"]) => cell for cell in local_manifest["cells"]
    )
    sort!(collect(keys(public_cells))) == collect(1:38) ==
        sort!(collect(keys(local_cells))) ||
        error("proposal robustness cell denominator changed")
    original_mismatch_cells = Int[]
    original_mismatch_specs = String[]
    corrected_mismatches = 0
    available_mismatches = 0
    unavailable_failure_records = 0
    for index in 1:38
        public_cell = public_cells[index]
        local_cell = local_cells[index]
        artifact_path = joinpath(
            EXPERIMENT_ROOT, String(local_cell["local_artifact_relative_path"]),
        )
        _sha256_file(artifact_path) == String(local_cell["local_artifact_sha256"]) ||
            error("proposal robustness artifact changed for cell $index")
        artifact = TOML.parsefile(artifact_path)
        public_grid = Dict(String(row["spec_id"]) => row for row in public_cell["grid_records"])
        for local_record in artifact["grid_records"]
            spec_id = String(local_record["spec_id"])
            public_record = public_grid[spec_id]
            comparator = local_record["comparator_choice"]
            safe = local_record["safe_choice"]
            raw_equal = _choice_ids(comparator) == _choice_ids(safe)
            available = Bool(public_record["available"])
            sealed_same = Bool(public_record["same_choice"])
            corrected_same = available && raw_equal
            if raw_equal != sealed_same
                push!(original_mismatch_cells, index)
                push!(original_mismatch_specs, spec_id)
                available && (available_mismatches += 1)
            end
            corrected_same == sealed_same || (corrected_mismatches += 1)
            if !available
                String(public_record["failure_code"]) == "UNIVERSE_GATE_FAILED" ||
                    error("unavailable public failure changed")
                String(local_record["failure_code"]) == "UNIVERSE_GATE_FAILED" ||
                    error("unavailable local failure changed")
                isempty(_choice_ids(comparator)) && isempty(_choice_ids(safe)) ||
                    error("unavailable robustness record contains an identity")
                String(comparator["failure_code"]) == "UNIVERSE_GATE_FAILED" &&
                    String(safe["failure_code"]) == "UNIVERSE_GATE_FAILED" ||
                    error("unavailable choice failure changed")
                unavailable_failure_records += 1
            end
        end
    end
    length(original_mismatch_specs) == 24 ||
        error("original validator mismatch denominator changed")
    Set(original_mismatch_cells) == Set([2]) ||
        error("original validator mismatch escaped failed cell 002")
    length(unique(original_mismatch_specs)) == 24 ||
        error("original validator mismatch spec set changed")
    available_mismatches == 0 ||
        error("validator amendment would alter an available choice")
    unavailable_failure_records == 24 ||
        error("unavailable failed-cell grid denominator changed")
    corrected_mismatches == 0 ||
        error("amended validator does not reconcile the sealed interface")
    return (;
        original_mismatch_count = length(original_mismatch_specs),
        original_mismatch_cell_index = only(Set(original_mismatch_cells)),
        available_mismatch_count = available_mismatches,
        unavailable_failure_record_count = unavailable_failure_records,
        corrected_mismatch_count = corrected_mismatches,
    )
end

function _payload()
    original = _original_contract()
    failure = _failure_contract()
    audit = _semantic_audit()
    sealed = copy(original.hashes)
    sealed[relpath(ORIGINAL_LOCK_PATH, REPOSITORY_ROOT)] = _sha256_file(ORIGINAL_LOCK_PATH)
    for relative in AMENDMENT_PATHS
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("amendment source is absent: $relative")
        haskey(sealed, relative) && sealed[relative] != _sha256_file(path) &&
            error("amendment/original sealed hash conflict: $relative")
        sealed[relative] = _sha256_file(path)
    end
    return Dict{String,Any}(
        "schema_version" =>
            "financial-strategy-library-panel-v3-evaluation-staging-validator-amendment-lock-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_EVALUATION_STAGING_VALIDATOR_AMENDMENT_001",
        "language" => "Julia",
        "amendment_scope" => "VALIDATOR_ONLY",
        "scientific_design_changed" => false,
        "frozen_choices_or_hashes_changed" => false,
        "universe_membership_or_access_mask_changed" => false,
        "extraction_scoring_diagnostics_capacity_or_ledger_code_changed" => false,
        "original_evaluation_execution_lock_preserved" => true,
        "original_evaluation_execution_lock_sha256" =>
            _sha256_file(ORIGINAL_LOCK_PATH),
        "evaluation_staging_failure_001_sha256" => _sha256_file(FAILURE_PATH),
        "historical_evaluation_values_inspected_before_amendment" =>
            failure["historical_evaluation_values_inspected"],
        "historical_evaluation_values_materialized_before_amendment" =>
            failure["historical_evaluation_values_materialized"],
        "historical_evaluation_values_used_before_amendment" =>
            failure["historical_evaluation_values_used"],
        "master_source_parquet_files_opened_before_amendment" => 0,
        "master_identifier_date_rows_scanned_before_amendment" => 0,
        "evaluation_stage_outputs_created_before_amendment" => 0,
        "original_validator_mismatch_count" => audit.original_mismatch_count,
        "original_validator_mismatch_cell_index" =>
            audit.original_mismatch_cell_index,
        "available_record_mismatch_count" => audit.available_mismatch_count,
        "unavailable_failed_cell_record_count" =>
            audit.unavailable_failure_record_count,
        "amended_validator_mismatch_count" => audit.corrected_mismatch_count,
        "amended_same_choice_semantics" =>
            "record_available && comparator_strategy_ids == safe_strategy_ids",
        "unavailable_failure_required" => "UNIVERSE_GATE_FAILED",
        "amended_staging_entrypoint" =>
            "julia/scripts/stage_financial_strategy_library_panel_v3_evaluation_returns_amendment_001.jl",
        "amended_evaluation_entrypoint" =>
            "julia/scripts/run_financial_strategy_library_panel_v3_evaluation_amendment_001.jl",
        "amended_result_seal_entrypoint" =>
            "julia/scripts/seal_financial_strategy_library_panel_v3_evaluation_result_amendment_001.jl",
        "required_staging_receipt_relative_path" =>
            relpath(AMENDMENT_RECEIPT_PATH, EXPERIMENT_ROOT),
        "staging_receipt_binds_amendment_and_stage_manifests" => true,
        "evaluation_runner_requires_staging_receipt" => true,
        "final_result_seal_requires_amendment_lock_and_receipt" => true,
        "historical_evaluation_return_access_newly_permitted_by_amendment" => false,
        "historical_staging_rerun_requires_explicit_independent_amendment_go" => true,
        "synthetic_assertion_count" => 29,
        "original_sealed_file_count" => 114,
        "amendment_and_transitive_sealed_file_count" => length(sealed),
        "sealed_file_sha256" => sealed,
    )
end

function _verify_no_pre_amendment_outputs()
    for path in (
        PUBLIC_STAGE_MANIFEST_PATH,
        LOCAL_STAGE_MANIFEST_PATH,
        AMENDMENT_RECEIPT_PATH,
    )
        !isfile(path) || error("pre-amendment evaluation stage output exists")
    end
    local_root = joinpath(EXPERIMENT_ROOT, "local_data", "evaluation")
    if isdir(local_root)
        isempty(readdir(local_root)) || error("pre-amendment local stage directory is not empty")
    end
    return true
end

function main(args = ARGS)
    length(args) <= 1 || error("use no argument to lock or --check to verify")
    check = "--check" in args
    !check && !isfile(AMENDMENT_LOCK_PATH) && _verify_no_pre_amendment_outputs()
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(AMENDMENT_LOCK_PATH) || error("staging validator amendment lock is absent")
        read(AMENDMENT_LOCK_PATH, String) == text ||
            error("staging validator amendment lock changed")
        println("V3_EVALUATION_STAGING_VALIDATOR_AMENDMENT_001_CHECK_PASSED")
    else
        isfile(AMENDMENT_LOCK_PATH) && read(AMENDMENT_LOCK_PATH, String) != text &&
            error("refusing to replace a nonidentical staging validator amendment lock")
        if !isfile(AMENDMENT_LOCK_PATH)
            open(AMENDMENT_LOCK_PATH, "w") do io
                write(io, text)
            end
        end
        println("V3_EVALUATION_STAGING_VALIDATOR_AMENDMENT_001_LOCKED")
    end
    println("historical evaluation values inspected/materialized/used: 0/0/0")
    println("historical staging rerun requires explicit independent amendment go: true")
    return payload
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3EvaluationStagingValidatorAmendment001.main()
end
