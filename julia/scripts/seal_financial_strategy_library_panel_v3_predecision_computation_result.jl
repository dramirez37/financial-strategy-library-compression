module SealFinancialStrategyLibraryPanelV3PredecisionComputationResult

using SHA: sha256
using TOML

include(joinpath(
    @__DIR__,
    "check_financial_strategy_library_panel_v3_predecision_binding_replay.jl",
))
const Replay = CheckFinancialStrategyLibraryPanelV3PredecisionBindingReplay
const Runner = Replay.Runner

export seal_predecision_computation_result, main

const REPOSITORY_ROOT = Runner.REPOSITORY_ROOT
const EXPERIMENT_ROOT = Runner.EXPERIMENT_ROOT
const AUDIT_AMENDMENT_LOCK_PATH = joinpath(
    EXPERIMENT_ROOT,
    "PREDECISION_AUDIT_AMENDMENT_004_LOCK.toml",
)
const EXPECTED_AUDIT_AMENDMENT_LOCK_SHA256 =
    "0b1203483d68749de37a90be2976a9712248421d5d2b2f1b1899f093e38dede0"
const PUBLIC_RESULT_MANIFEST_PATH = Runner.PUBLIC_RESULT_MANIFEST_PATH
const LOCAL_RESULT_MANIFEST_PATH = Runner.LOCAL_RESULT_MANIFEST_PATH
const SEAL_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_COMPUTATION_RESULT_SEAL.toml")
const SCRIPT_RELATIVE_PATH =
    "julia/scripts/seal_financial_strategy_library_panel_v3_predecision_computation_result.jl"

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

_sha256_text(value) = bytes2hex(sha256(codeunits(String(value))))

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _aggregate(hashes)
    canonical = join(
        ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
    )
    return _sha256_text(canonical)
end

function _artifact_hashes(local_manifest)
    cells = Dict(Int(cell["cell_index"]) => cell for cell in local_manifest["cells"])
    sort!(collect(keys(cells))) == collect(1:38) ||
        error("predecision result seal requires 38 canonical cells")
    hashes = Dict{String,String}()
    for index in 1:38
        cell_hashes = Dict{String,String}(cells[index]["local_artifact_sha256"])
        length(cell_hashes) == 6 || error("cell $index does not bind six local artifacts")
        for (relative, digest) in cell_hashes
            haskey(hashes, relative) && error("duplicate local result artifact: $relative")
            path = joinpath(EXPERIMENT_ROOT, relative)
            isfile(path) || error("local result artifact is absent: $relative")
            _sha256_file(path) == digest || error("local result artifact changed: $relative")
            hashes[relative] = digest
        end
    end
    length(hashes) == 228 || error("predecision artifact denominator changed")
    return hashes
end

function _payload(; replay)
    _sha256_file(AUDIT_AMENDMENT_LOCK_PATH) == EXPECTED_AUDIT_AMENDMENT_LOCK_SHA256 ||
        error("predecision audit amendment 004 lock changed")
    audit_lock = TOML.parsefile(AUDIT_AMENDMENT_LOCK_PATH)
    audit_lock["status"] == "LOCKED_PREDECISION_AUDIT_AMENDMENT_004" ||
        error("unexpected predecision audit amendment status")
    audit_lock["historical_proposal_or_evaluation_return_access_permitted"] === false ||
        error("audit amendment permits forbidden postdecision access")
    replay && Replay.check_binding_replay()

    public = TOML.parsefile(PUBLIC_RESULT_MANIFEST_PATH)
    local_manifest = TOML.parsefile(LOCAL_RESULT_MANIFEST_PATH)
    for manifest in (public, local_manifest)
        manifest["status"] == "PREPROPOSAL_STRUCTURAL_STATE_FROZEN" ||
            error("unexpected predecision computation result status")
        manifest["cell_count"] == 38 || error("predecision result cell count changed")
        manifest["preproposal_trial_ledger_rows"] == 18_430 ||
            error("preproposal ledger denominator changed")
        manifest["proposal_return_values_accessed"] === false ||
            error("proposal returns were accessed before result seal")
        manifest["evaluation_return_values_accessed"] === false ||
            error("evaluation returns were accessed before result seal")
    end
    local_manifest["public_manifest_sha256"] == _sha256_file(PUBLIC_RESULT_MANIFEST_PATH) ||
        error("public/local computation result manifests are not bound")
    artifacts = _artifact_hashes(local_manifest)
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-predecision-computation-result-seal-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "SEALED_PREDECISION_COMPUTATION_RESULT",
        "language" => "Julia",
        "predecision_audit_amendment_004_lock_sha256" =>
            _sha256_file(AUDIT_AMENDMENT_LOCK_PATH),
        "full_deterministic_scientific_replay_passed" => true,
        "full_deterministic_scientific_replay_cell_count" => 38,
        "deterministic_mip_fields_excluded" => [
            "runtime_ns",
            "solver_diagnostics.solve_time_seconds",
            "solver_diagnostics.complete_solver_log",
        ],
        "all_other_mip_fields_identical" => true,
        "path_and_profile_fields_identical" => true,
        "action_sets_and_ledgers_identical" => true,
        "scientific_design_changed" => false,
        "scientific_choices_changed" => false,
        "public_result_manifest_sha256" => _sha256_file(PUBLIC_RESULT_MANIFEST_PATH),
        "local_result_manifest_sha256" => _sha256_file(LOCAL_RESULT_MANIFEST_PATH),
        "local_artifact_count" => length(artifacts),
        "local_artifact_aggregate_sha256" => _aggregate(artifacts),
        "local_artifact_sha256" => artifacts,
        "original_artifacts_and_complete_solver_logs_bound_by_hash" => true,
        "result_cell_count" => public["cell_count"],
        "preproposal_trial_ledger_rows" => public["preproposal_trial_ledger_rows"],
        "failed_universe_cells_retained" => public["failed_universe_cells_retained"],
        "proposal_return_values_accessed_before_result_seal" => false,
        "evaluation_return_values_accessed_before_result_seal" => false,
        "historical_proposal_or_evaluation_return_access_permitted" => false,
        "return_values_included" => false,
        "licensed_security_identifiers_included" => false,
        "seal_script_sha256" => _sha256_file(joinpath(REPOSITORY_ROOT, SCRIPT_RELATIVE_PATH)),
        "next_permitted_stage" => "sealed proposal-year extraction, excluding failed universe cells",
    )
end

function seal_predecision_computation_result(; check = false)
    payload = _payload(; replay = true)
    text = _toml_text(payload)
    if check
        isfile(SEAL_PATH) || error("predecision computation result seal is absent")
        read(SEAL_PATH, String) == text || error("predecision computation result seal changed")
    elseif isfile(SEAL_PATH)
        read(SEAL_PATH, String) == text ||
            error("refusing to replace a nonidentical predecision result seal")
    else
        open(SEAL_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PREDECISION_COMPUTATION_RESULT_SEAL_PASSED")
    println("full deterministic scientific replay cells: 38")
    artifact_count = payload["local_artifact_count"]
    println("local result artifacts bound: $artifact_count")
    println("proposal/evaluation returns accessed: false")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    seal_predecision_computation_result(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    SealFinancialStrategyLibraryPanelV3PredecisionComputationResult.main()
end
