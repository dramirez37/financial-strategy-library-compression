module StageFinancialStrategyLibraryPanelV3EvaluationReturnsAmendment001

using SHA: sha256
using TOML

include(joinpath(@__DIR__, "stage_financial_strategy_library_panel_v3_evaluation_returns.jl"))
const BaseStage = StageFinancialStrategyLibraryPanelV3EvaluationReturns

export evaluation_leakage_sentinel, install_validator!, stage_evaluation_returns

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const ORIGINAL_EXECUTION_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "EVALUATION_EXECUTION_LOCK.toml")
const AMENDMENT_LOCK_PATH = joinpath(
    EXPERIMENT_ROOT,
    "EVALUATION_STAGING_VALIDATOR_AMENDMENT_001_LOCK.toml",
)
const AMENDMENT_RECEIPT_PATH = joinpath(
    EXPERIMENT_ROOT,
    "evaluation_stage",
    "EVALUATION_STAGING_VALIDATOR_AMENDMENT_001_RECEIPT.toml",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

"""
Return the sealed same-choice meaning for one robustness grid record.

An unavailable pair has no frozen identity. Two empty placeholder vectors are
not a shared choice: `same_choice` is false by construction, and both local
choice failures must equal the sealed record-level failure. An available pair
is the same choice exactly when its two nonempty frozen identity vectors agree.
"""
function _validate_grid_same_choice(public_record, local_record, comparator, safe)
    comparator_ids = BaseStage._choice_strategy_ids(comparator)
    safe_ids = BaseStage._choice_strategy_ids(safe)
    available = Bool(public_record["available"])
    public_same = Bool(public_record["same_choice"])
    if available
        isempty(comparator_ids) && error("available robustness comparator identity is empty")
        isempty(safe_ids) && error("available robustness safe identity is empty")
        isempty(String(get(local_record, "failure_code", ""))) ||
            error("available robustness record has a failure disposition")
        isempty(String(get(comparator, "failure_code", ""))) ||
            error("available robustness comparator has a failure disposition")
        isempty(String(get(safe, "failure_code", ""))) ||
            error("available robustness safe choice has a failure disposition")
        local_same = comparator_ids == safe_ids
        public_same == local_same || error("available robustness same-choice flag changed")
        return local_same
    end

    failure = String(public_record["failure_code"])
    failure == "UNIVERSE_GATE_FAILED" ||
        error("unavailable robustness record has an unexpected failure disposition")
    String(get(local_record, "failure_code", "")) == failure ||
        error("public/local unavailable robustness record failure changed")
    isempty(comparator_ids) && isempty(safe_ids) ||
        error("unavailable robustness record exposes a frozen identity")
    String(get(comparator, "failure_code", "")) == failure ||
        error("unavailable robustness comparator failure changed")
    String(get(safe, "failure_code", "")) == failure ||
        error("unavailable robustness safe failure changed")
    public_same === false ||
        error("unavailable robustness pair cannot be marked same-choice")
    return false
end

# Validator-only post-lock amendment. All extraction, masking, staging, and
# evaluation methods remain the byte-identical methods sealed by the original
# execution lock.
@eval BaseStage const _amendment_001_validate_grid_same_choice =
    $(_validate_grid_same_choice)
@eval BaseStage begin
    function _validate_robustness_binding(public, local_manifest_cell, selection)
        relative = String(local_manifest_cell["local_artifact_relative_path"])
        path = joinpath(EXPERIMENT_ROOT, relative)
        _sha256_file(path) == String(local_manifest_cell["local_artifact_sha256"]) ||
            error("proposal robustness cell artifact changed")
        artifact = TOML.parsefile(path)
        for field in ("cell_index", "origin_id", "universe_id", "universe_gate_passed")
            artifact[field] == public[field] ||
                error("proposal robustness cell identity changed: $field")
        end
        public_grid = Dict(String(row["spec_id"]) => row for row in public["grid_records"])
        local_grid = collect(artifact["grid_records"])
        length(public_grid) == length(local_grid) == 24 ||
            error("proposal robustness cell does not have 24 grid specs")
        choice_hashes = String[]
        selected_strategy_ids = Set{String}()
        for local_record in local_grid
            spec_id = String(local_record["spec_id"])
            haskey(public_grid, spec_id) || error("public robustness grid omitted $spec_id")
            public_record = public_grid[spec_id]
            for field in ("cost_bps", "risk_aversion", "adoption_hurdle")
                Float64(local_record[field]) == Float64(public_record[field]) ||
                    error("robustness grid metadata changed: $spec_id/$field")
            end
            comparator = local_record["comparator_choice"]
            safe = local_record["safe_choice"]
            String(comparator["policy_id"]) == "frontier_only_robust_policy" ||
                error("robustness comparator policy changed")
            String(safe["policy_id"]) == "innovation_safe_robust_policy" ||
                error("robustness safe policy changed")
            comparator_hash = _robustness_choice_hash(spec_id, comparator)
            safe_hash = _robustness_choice_hash(spec_id, safe)
            comparator_hash == String(local_record["comparator_choice_sha256"]) ==
                String(public_record["comparator_choice_sha256"]) ||
                error("robustness comparator identity binding changed: $spec_id")
            safe_hash == String(local_record["safe_choice_sha256"]) ==
                String(public_record["safe_choice_sha256"]) ||
                error("robustness safe identity binding changed: $spec_id")
            try
                _amendment_001_validate_grid_same_choice(
                    public_record, local_record, comparator, safe,
                )
            catch exception
                error(
                    "robustness same-choice semantics changed for cell " *
                    "$(public["cell_index"]), $spec_id: $(sprint(showerror, exception))",
                )
            end
            append!(choice_hashes, (comparator_hash, safe_hash))
            for choice in (comparator, safe), strategy_id in _choice_strategy_ids(choice)
                strategy_id == CASH_ID || push!(selected_strategy_ids, strategy_id)
            end
        end
        aggregate = _sha256_text(join(choice_hashes, '\n'))
        aggregate == String(public["grid_choice_aggregate_sha256"]) ==
            String(local_manifest_cell["grid_choice_aggregate_sha256"]) ==
            String(artifact["grid_choice_aggregate_sha256"]) ||
            error("proposal robustness grid aggregate changed")

        public_caps = Dict(
            Int(row["liquidity_cap"]) => row for
            row in public["common_equity_cap_records"]
        )
        local_caps = Dict(
            Int(row["liquidity_cap"]) => row for
            row in artifact["common_equity_cap_records"]
        )
        Set(keys(public_caps)) == Set((50, 100, 200)) == Set(keys(local_caps)) ||
            error("proposal robustness cap dispositions changed")
        for cap in (50, 100, 200)
            public_record = public_caps[cap]
            local_record = local_caps[cap]
            Bool(public_record["available"]) == Bool(local_record["available"]) ||
                error("proposal robustness cap availability changed")
            if !Bool(local_record["available"])
                String(public_record["failure_code"]) ==
                    String(local_record["failure_code"]) ||
                    error("proposal robustness cap failure disposition changed")
                continue
            end
            context = "common_equity_cap$(cap)"
            comparator = local_record["comparator_choice"]
            safe = local_record["safe_choice"]
            comparator_hash = _robustness_choice_hash(context, comparator)
            safe_hash = _robustness_choice_hash(context, safe)
            comparator_hash == String(public_record["comparator_choice_sha256"]) ==
                String(local_record["comparator_choice_sha256"]) ||
                error("robustness cap comparator binding changed")
            safe_hash == String(public_record["safe_choice_sha256"]) ==
                String(local_record["safe_choice_sha256"]) ||
                error("robustness cap safe binding changed")
            Bool(public_record["same_choice"]) ==
                (_choice_strategy_ids(comparator) == _choice_strategy_ids(safe)) ||
                error("robustness cap same-choice flag changed")
            for choice in (comparator, safe), strategy_id in _choice_strategy_ids(choice)
                strategy_id == CASH_ID || push!(selected_strategy_ids, strategy_id)
            end
        end
        ranked = sort!(collect(selection["selected"]); by = row -> Int(row["rank"]))
        cap50_permnos = if String(selection["universe_id"]) == "liquid_common_equity"
            length(ranked) == 100 || error("common-equity top100 membership changed")
            Set(Int(row["permno"]) for row in ranked[1:50])
        else
            Set{Int}()
        end
        return (; selected_strategy_ids, cap50_permnos)
    end
end

"Install the sealed amended validator into another fresh staging module."
function install_validator!(stage_module::Module)
    stage_module === BaseStage && return stage_module
    validator = BaseStage._validate_robustness_binding
    Core.eval(stage_module, :(
        const _amendment_001_robustness_validator_delegate = $validator
    ))
    Core.eval(stage_module, quote
        function _validate_robustness_binding(public, local_manifest_cell, selection)
            return _amendment_001_robustness_validator_delegate(
                public, local_manifest_cell, selection,
            )
        end
    end)
    return stage_module
end

function _amendment_contract()
    isfile(ORIGINAL_EXECUTION_LOCK_PATH) || error("original evaluation lock is absent")
    isfile(AMENDMENT_LOCK_PATH) || error("staging validator amendment lock is absent")
    lock = TOML.parsefile(AMENDMENT_LOCK_PATH)
    lock["status"] == "LOCKED_EVALUATION_STAGING_VALIDATOR_AMENDMENT_001" ||
        error("staging validator amendment is not locked")
    lock["original_evaluation_execution_lock_sha256"] ==
        _sha256_file(ORIGINAL_EXECUTION_LOCK_PATH) ||
        error("staging validator amendment does not bind the original lock")
    for (relative, digest) in Dict{String,String}(lock["sealed_file_sha256"])
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("staging validator amendment file is absent: $relative")
        _sha256_file(path) == digest ||
            error("staging validator amendment file changed: $relative")
    end
    return lock
end

evaluation_leakage_sentinel() = BaseStage.evaluation_leakage_sentinel()

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _receipt_payload()
    for path in (BaseStage.PUBLIC_STAGE_MANIFEST_PATH, BaseStage.LOCAL_STAGE_MANIFEST_PATH)
        isfile(path) || error("evaluation stage manifest is absent; receipt is not eligible")
    end
    public_sha = _sha256_file(BaseStage.PUBLIC_STAGE_MANIFEST_PATH)
    local_sha = _sha256_file(BaseStage.LOCAL_STAGE_MANIFEST_PATH)
    local_manifest = TOML.parsefile(BaseStage.LOCAL_STAGE_MANIFEST_PATH)
    local_manifest["public_manifest_sha256"] == public_sha ||
        error("evaluation stage public/local manifests are not bound")
    return Dict{String,Any}(
        "schema_version" =>
            "financial-strategy-library-panel-v3-evaluation-staging-amendment-receipt-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "EVALUATION_STAGING_VALIDATOR_AMENDMENT_001_APPLIED",
        "amendment_scope" => "VALIDATOR_ONLY",
        "original_evaluation_execution_lock_sha256" =>
            _sha256_file(ORIGINAL_EXECUTION_LOCK_PATH),
        "evaluation_staging_validator_amendment_001_lock_sha256" =>
            _sha256_file(AMENDMENT_LOCK_PATH),
        "evaluation_stage_public_manifest_sha256" => public_sha,
        "evaluation_stage_local_manifest_sha256" => local_sha,
        "historical_evaluation_values_included" => false,
        "selected_strategy_identities_included" => false,
        "scientific_design_changed" => false,
    )
end

function _write_or_check_receipt(; check)
    text = _toml_text(_receipt_payload())
    if check
        isfile(AMENDMENT_RECEIPT_PATH) || error("staging amendment receipt is absent")
        read(AMENDMENT_RECEIPT_PATH, String) == text ||
            error("staging amendment receipt changed")
    elseif isfile(AMENDMENT_RECEIPT_PATH)
        read(AMENDMENT_RECEIPT_PATH, String) == text ||
            error("refusing to replace a nonidentical staging amendment receipt")
    else
        mkpath(dirname(AMENDMENT_RECEIPT_PATH))
        open(AMENDMENT_RECEIPT_PATH, "w") do io
            write(io, text)
        end
    end
    return AMENDMENT_RECEIPT_PATH
end

function stage_evaluation_returns(; check = false)
    _amendment_contract()
    payload = BaseStage.stage_evaluation_returns(; check)
    _write_or_check_receipt(; check)
    return payload
end

function main(args = ARGS)
    length(args) <= 1 || error("use no argument to stage or --check to verify")
    return stage_evaluation_returns(; check = "--check" in args)
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    StageFinancialStrategyLibraryPanelV3EvaluationReturnsAmendment001.main()
end
