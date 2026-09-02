module AuditFinancialStrategyLibraryPanelV4

using SHA: sha256
using TOML

include(joinpath(@__DIR__, "run_financial_strategy_library_panel_v4.jl"))
using .RunFinancialStrategyLibraryPanelV4
using .RunFinancialStrategyLibraryPanelV4.FinancialStrategyLibraryPanelV4
using .RunFinancialStrategyLibraryPanelV4.LockFinancialStrategyLibraryPanelV4Design

export audit_v4, seal_v4, check_seal, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v4",
)
const RESULT_ROOT = joinpath(EXPERIMENT_ROOT, "results")
const LEDGER_PATH = joinpath(RESULT_ROOT, "V4_WORLD_LEDGER.csv")
const SUMMARY_PATH = joinpath(RESULT_ROOT, "V4_SUMMARY.csv")
const MANIFEST_PATH = joinpath(RESULT_ROOT, "RESULT_MANIFEST.toml")
const SEAL_PATH = joinpath(EXPERIMENT_ROOT, "RESULT_SEAL.toml")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK.toml")

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _atomic_write(path, text)
    temporary = path * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, path; force = true)
    return path
end

function _audit_payload()
    LockFinancialStrategyLibraryPanelV4Design.check_lock()
    all(isfile, (LEDGER_PATH, SUMMARY_PATH, MANIFEST_PATH)) ||
        error("one or more v4 result artifacts are absent")
    inputs = RunFinancialStrategyLibraryPanelV4.design_from_files()
    reproduced = run_experiment(inputs.design, inputs.calibration)
    ledger_text = RunFinancialStrategyLibraryPanelV4.serialize_ledger(reproduced.results)
    summary_text = RunFinancialStrategyLibraryPanelV4.serialize_summary(reproduced.summaries)
    read(LEDGER_PATH, String) == ledger_text || error("v4 world ledger does not reproduce")
    read(SUMMARY_PATH, String) == summary_text || error("v4 summary does not reproduce")
    all(result -> record_hash(result) == result.record_hash, reproduced.results) ||
        error("one or more v4 world record hashes fail")

    manifest = TOML.parsefile(MANIFEST_PATH)
    manifest["design_lock_sha256"] == _sha256_file(LOCK_PATH) ||
        error("v4 manifest design-lock binding changed")
    manifest["world_ledger_sha256"] == _sha256_file(LEDGER_PATH) ||
        error("v4 manifest ledger hash changed")
    manifest["summary_csv_sha256"] == _sha256_file(SUMMARY_PATH) ||
        error("v4 manifest summary hash changed")
    gates = RunFinancialStrategyLibraryPanelV4.result_gate_status(reproduced, inputs.config)
    manifest["gate_status"] == gates || error("v4 manifest gate statuses do not reproduce")

    paired_monotonicity = true
    for world_id in 1:inputs.design.evaluation_world_count_per_regime
        rows = sort!(
            filter(result -> result.world_id == world_id, reproduced.results);
            by = result -> result.true_margin,
        )
        length(unique(getfield.(rows, :proposal_noise))) == 1 ||
            error("common proposal noise changed within a paired world")
        length(unique(getfield.(rows, :project_success))) == 1 ||
            error("common project event changed within a paired world")
        issorted(getfield.(rows, :proposal_margin_estimate)) ||
            (paired_monotonicity = false)
        issorted(Int.(getfield.(rows, :learned_adopt))) ||
            (paired_monotonicity = false)
    end
    paired_monotonicity || error("v4 paired dose response is not monotone")
    gates["all_registered_gates_pass"] || error("one or more registered v4 gates fail")
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v4-result-audit-v1",
        "experiment_id" => "financial-strategy-library-panel-v4",
        "status" => "INDEPENDENT_RECOMPUTATION_PASS",
        "language" => "Julia",
        "design_lock_sha256" => _sha256_file(LOCK_PATH),
        "result_manifest_sha256" => _sha256_file(MANIFEST_PATH),
        "world_ledger_sha256" => _sha256_file(LEDGER_PATH),
        "summary_csv_sha256" => _sha256_file(SUMMARY_PATH),
        "world_rows_recomputed" => length(reproduced.results),
        "world_record_hashes_pass" => true,
        "paired_common_random_numbers_pass" => true,
        "paired_dose_response_monotonicity_pass" => true,
        "registered_gate_status" => gates,
    )
end

audit_v4() = _audit_payload()

function seal_v4()
    isfile(SEAL_PATH) && error("v4 result seal already exists")
    payload = _audit_payload()
    _atomic_write(SEAL_PATH, _toml_text(payload))
    return payload
end

function check_seal()
    isfile(SEAL_PATH) || error("v4 result seal is absent")
    existing = TOML.parsefile(SEAL_PATH)
    expected = _audit_payload()
    existing == expected || error("v4 result seal does not match reproduced results")
    return existing
end

function main(args = ARGS)
    mode = isempty(args) ? "--check" : only(args)
    payload = mode == "--audit" ? audit_v4() :
        mode == "--seal" ? seal_v4() :
        mode == "--check" ? check_seal() :
        error("usage: audit_financial_strategy_library_panel_v4.jl [--audit|--seal|--check]")
    println("V4_RESULT_AUDIT_OK")
    println("world rows recomputed: ", payload["world_rows_recomputed"])
    println("manifest: ", payload["result_manifest_sha256"])
    return payload
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    AuditFinancialStrategyLibraryPanelV4.main()
end

