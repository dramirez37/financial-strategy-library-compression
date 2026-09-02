module SealFinancialStrategyLibraryPanelV3EvaluationResult

using SHA: sha256
using TOML

include(joinpath(@__DIR__, "run_financial_strategy_library_panel_v3_evaluation.jl"))
const Runner = RunFinancialStrategyLibraryPanelV3Evaluation

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const EXECUTION_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "EVALUATION_EXECUTION_LOCK.toml")
const PROPOSAL_RESULT_SEAL_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_RESULT_SEAL.toml")
const PROPOSAL_ROBUSTNESS_RESULT_SEAL_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_ROBUSTNESS_RESULT_SEAL.toml")
const PUBLIC_RESULT_PATH = joinpath(
    EXPERIMENT_ROOT,
    "evaluation_results",
    "EVALUATION_RESULT_MANIFEST.toml",
)
const LOCAL_RESULT_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "evaluation_results",
    "EVALUATION_RESULT_LOCAL_MANIFEST.toml",
)
const RESULT_SEAL_PATH = joinpath(EXPERIMENT_ROOT, "EVALUATION_RESULT_SEAL.toml")

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _payload()
    public = Runner.audit_evaluation()
    for path in (
        EXECUTION_LOCK_PATH,
        PROPOSAL_RESULT_SEAL_PATH,
        PROPOSAL_ROBUSTNESS_RESULT_SEAL_PATH,
        PUBLIC_RESULT_PATH,
        LOCAL_RESULT_PATH,
    )
        isfile(path) || error("evaluation result seal input is absent")
    end
    public["status"] == "HISTORICAL_EVALUATION_COMPLETE" ||
        error("historical evaluation is not complete")
    public["trial_ledger_rows"] == 38 * 485 ||
        error("evaluation result seal denominator changed")
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-evaluation-result-seal-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "SEALED_HISTORICAL_EVALUATION_RESULT",
        "language" => "Julia",
        "historical_block_role" => "retrospective_development_facing",
        "evaluation_scope" => "all five frozen registered policies; primary headline fixed",
        "cell_count" => 38,
        "trial_ledger_rows" => 38 * 485,
        "registered_primary_policy_row_denominator" => 190,
        "proposal_robustness_grid_cell_spec_denominator" => 912,
        "proposal_robustness_grid_policy_choice_denominator" => 1824,
        "leave_one_origin_out_omission_count" => 19,
        "leave_one_origin_out_rule" => "AGGREGATION_ONLY_NO_RESELECTION",
        "full_search_candidate_count_per_gate_passed_cell" => 96,
        "evaluation_execution_lock_sha256" => _sha256_file(EXECUTION_LOCK_PATH),
        "proposal_policy_result_seal_sha256" => _sha256_file(PROPOSAL_RESULT_SEAL_PATH),
        "proposal_robustness_result_seal_sha256" =>
            _sha256_file(PROPOSAL_ROBUSTNESS_RESULT_SEAL_PATH),
        "evaluation_result_manifest_sha256" => _sha256_file(PUBLIC_RESULT_PATH),
        "evaluation_result_local_manifest_sha256" => _sha256_file(LOCAL_RESULT_PATH),
        "raw_returns_in_seal" => false,
        "licensed_security_identifiers_in_seal" => false,
        "selected_strategy_identities_in_seal" => false,
        "result_replay_audit_passed" => true,
    )
end

function main(args = ARGS)
    length(args) == 1 || error("use exactly one of --seal or --check")
    payload = _payload()
    text = _toml_text(payload)
    if args[1] == "--seal"
        isfile(RESULT_SEAL_PATH) && read(RESULT_SEAL_PATH, String) != text &&
            error("refusing to replace a nonidentical evaluation result seal")
        if !isfile(RESULT_SEAL_PATH)
            open(RESULT_SEAL_PATH, "w") do io
                write(io, text)
            end
        end
        println("V3_HISTORICAL_EVALUATION_RESULT_SEALED")
    elseif args[1] == "--check"
        isfile(RESULT_SEAL_PATH) || error("evaluation result seal is absent")
        read(RESULT_SEAL_PATH, String) == text || error("evaluation result seal changed")
        println("V3_HISTORICAL_EVALUATION_RESULT_SEAL_CHECK_PASSED")
    else
        error("unknown argument: $(args[1])")
    end
    println("evaluation result manifest: $(_sha256_file(PUBLIC_RESULT_PATH))")
    println("raw returns/licensed identifiers in seal: false")
    return payload
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    SealFinancialStrategyLibraryPanelV3EvaluationResult.main()
end
