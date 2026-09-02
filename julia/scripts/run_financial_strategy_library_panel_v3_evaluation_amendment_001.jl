module RunFinancialStrategyLibraryPanelV3EvaluationAmendment001

using SHA: sha256
using TOML

include(joinpath(
    @__DIR__,
    "stage_financial_strategy_library_panel_v3_evaluation_returns_amendment_001.jl",
))
const AmendmentStage =
    StageFinancialStrategyLibraryPanelV3EvaluationReturnsAmendment001

include(joinpath(@__DIR__, "run_financial_strategy_library_panel_v3_evaluation.jl"))
const BaseRunner = RunFinancialStrategyLibraryPanelV3Evaluation

# A fresh runner owns a distinct nested copy of the original staging module.
# Install the same validator-only overlay so no downstream code can reintroduce
# the unavailable-empty-vector predicate.
AmendmentStage.install_validator!(BaseRunner.Stage)

export audit_evaluation, run_evaluation

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

function _staging_amendment_contract()
    amendment = AmendmentStage._amendment_contract()
    isfile(AmendmentStage.AMENDMENT_RECEIPT_PATH) ||
        error("evaluation staging amendment receipt is absent")
    read(AmendmentStage.AMENDMENT_RECEIPT_PATH, String) ==
        AmendmentStage._toml_text(AmendmentStage._receipt_payload()) ||
        error("evaluation staging amendment receipt changed")
    receipt = TOML.parsefile(AmendmentStage.AMENDMENT_RECEIPT_PATH)
    receipt["status"] == "EVALUATION_STAGING_VALIDATOR_AMENDMENT_001_APPLIED" ||
        error("evaluation staging amendment was not applied")
    receipt["evaluation_staging_validator_amendment_001_lock_sha256"] ==
        _sha256_file(AmendmentStage.AMENDMENT_LOCK_PATH) ||
        error("evaluation staging receipt is not bound to the amendment lock")
    receipt["evaluation_stage_public_manifest_sha256"] ==
        _sha256_file(BaseRunner.PUBLIC_STAGE_MANIFEST_PATH) ||
        error("evaluation staging receipt/public manifest binding changed")
    receipt["evaluation_stage_local_manifest_sha256"] ==
        _sha256_file(BaseRunner.LOCAL_STAGE_MANIFEST_PATH) ||
        error("evaluation staging receipt/local manifest binding changed")
    return (; amendment, receipt)
end

function run_evaluation(; check = false)
    _staging_amendment_contract()
    return BaseRunner.run_evaluation(; check)
end

function audit_evaluation()
    _staging_amendment_contract()
    return BaseRunner.audit_evaluation()
end

function main(args = ARGS)
    length(args) == 1 || error("use exactly one of --run or --audit-only")
    args[1] == "--run" && return run_evaluation()
    args[1] == "--audit-only" && return audit_evaluation()
    error("unknown argument: $(args[1])")
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    RunFinancialStrategyLibraryPanelV3EvaluationAmendment001.main()
end

