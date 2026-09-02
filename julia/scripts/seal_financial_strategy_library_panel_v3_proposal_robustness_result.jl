module SealFinancialStrategyLibraryPanelV3ProposalRobustnessResult

using SHA: sha256
using TOML

export seal_proposal_robustness_result, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT, "experiments", "financial_strategy_library_panel_v3",
)
const ACCESS_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_ROBUSTNESS_FREEZE_AMENDMENT_004_LOCK.toml")
const COMPUTATION_AMENDMENT_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_ROBUSTNESS_COMPUTATION_AMENDMENT_005_LOCK.toml")
const PRIMARY_RESULT_SEAL_PATH = joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_RESULT_SEAL.toml")
const PUBLIC_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT, "proposal_robustness", "PROPOSAL_ROBUSTNESS_MANIFEST.toml",
)
const LOCAL_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal_robustness",
    "PROPOSAL_ROBUSTNESS_LOCAL_MANIFEST.toml",
)
const SEAL_PATH = joinpath(EXPERIMENT_ROOT, "PROPOSAL_ROBUSTNESS_RESULT_SEAL.toml")

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

function _payload()
    access = TOML.parsefile(ACCESS_LOCK_PATH)
    access["status"] == "LOCKED_PROPOSAL_ROBUSTNESS_FREEZE_AMENDMENT_004" ||
        error("proposal robustness access is not locked")
    access["historical_evaluation_return_access_permitted"] === false ||
        error("proposal robustness access lock permits evaluation")
    amendment = TOML.parsefile(COMPUTATION_AMENDMENT_PATH)
    amendment["status"] == "LOCKED_PROPOSAL_ROBUSTNESS_COMPUTATION_AMENDMENT_005" ||
        error("proposal robustness computation amendment is not locked")
    amendment["previous_proposal_robustness_freeze_lock_sha256"] ==
        _sha256_file(ACCESS_LOCK_PATH) || error("computation amendment does not bind access lock")
    amendment["historical_evaluation_return_access_permitted"] === false ||
        error("proposal robustness computation amendment permits evaluation")
    amended_hashes = Dict{String,String}(amendment["sealed_file_sha256"])
    for (relative, digest) in amended_hashes
        _sha256_file(joinpath(REPOSITORY_ROOT, relative)) == digest ||
            error("proposal robustness amended input changed: $relative")
    end
    for (relative, digest) in Dict{String,String}(access["sealed_file_sha256"])
        actual = _sha256_file(joinpath(REPOSITORY_ROOT, relative))
        actual == digest && continue
        get(amended_hashes, relative, "") == actual ||
            error("proposal robustness sealed input changed without amendment: $relative")
    end
    public = TOML.parsefile(PUBLIC_MANIFEST_PATH)
    local_manifest = TOML.parsefile(LOCAL_MANIFEST_PATH)
    for manifest in (public, local_manifest)
        manifest["status"] == "PROPOSAL_ROBUSTNESS_CHOICES_FROZEN" ||
            error("unexpected proposal robustness result status")
        manifest["cell_count"] == 38 || error("robustness cell denominator changed")
        manifest["grid_cell_spec_denominator"] == 912 ||
            error("robustness grid denominator changed")
        manifest["grid_policy_choice_denominator"] == 1_824 ||
            error("robustness policy-choice denominator changed")
        manifest["evaluation_values_inspected"] == 0 || error("evaluation was inspected")
        manifest["evaluation_values_materialized"] == 0 ||
            error("evaluation was materialized")
        manifest["evaluation_values_used"] == 0 || error("evaluation was used")
    end
    public["selected_strategy_identities_included"] === false ||
        error("public robustness manifest contains selected identities")
    local_manifest["public_manifest_sha256"] == _sha256_file(PUBLIC_MANIFEST_PATH) ||
        error("robustness public/local manifests are not bound")
    hashes = Dict{String,String}(local_manifest["local_artifact_sha256"])
    length(hashes) == 38 || error("robustness local artifact denominator changed")
    _aggregate(hashes) == local_manifest["local_artifact_aggregate_sha256"] ||
        error("robustness local artifact aggregate changed")
    for (relative, digest) in hashes
        _sha256_file(joinpath(EXPERIMENT_ROOT, relative)) == digest ||
            error("proposal robustness artifact changed: $relative")
    end
    primary_seal = TOML.parsefile(PRIMARY_RESULT_SEAL_PATH)
    primary_seal["status"] == "SEALED_PROPOSAL_POLICY_RESULT" ||
        error("primary proposal result is not sealed")
    primary_seal["historical_evaluation_return_access_permitted"] === false ||
        error("primary proposal seal permits evaluation")
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-robustness-result-seal-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "SEALED_PROPOSAL_ROBUSTNESS_RESULT",
        "language" => "Julia",
        "proposal_robustness_freeze_amendment_004_lock_sha256" =>
            _sha256_file(ACCESS_LOCK_PATH),
        "proposal_robustness_computation_amendment_005_lock_sha256" =>
            _sha256_file(COMPUTATION_AMENDMENT_PATH),
        "proposal_policy_result_seal_sha256" => _sha256_file(PRIMARY_RESULT_SEAL_PATH),
        "public_proposal_robustness_manifest_sha256" => _sha256_file(PUBLIC_MANIFEST_PATH),
        "local_proposal_robustness_manifest_sha256" => _sha256_file(LOCAL_MANIFEST_PATH),
        "bound_local_artifact_count" => length(hashes),
        "bound_local_artifact_aggregate_sha256" => _aggregate(hashes),
        "all_bound_local_artifact_hashes_verified" => true,
        "cell_count" => 38,
        "available_cell_count" => 37,
        "failed_universe_cells_retained" => 1,
        "grid_cell_spec_denominator" => 912,
        "grid_policy_choice_denominator" => 1_824,
        "bootstrap_repetitions" => 5_000,
        "moving_block_sessions" => 20,
        "common_equity_cap50_available_cells" => 19,
        "common_equity_cap100_available_cells" => 19,
        "common_equity_cap200_unavailable_cells" => 19,
        "permuted_closure_sham_unavailable_cells" => 38,
        "unfrozen_design_failure_code" => "DESIGN_NOT_FROZEN_BEFORE_PROPOSAL",
        "leave_one_origin_out_rule" => "AGGREGATION_ONLY_NO_RESELECTION",
        "capacity_status" => "DEFERRED_PRE_EVALUATION_FORMULA_GRID_LOCK_REQUIRED",
        "capacity_choice_rule" => "SCORE_FROZEN_CHOICES_ONLY_NO_RESELECTION",
        "public_selected_strategy_identities_included" => false,
        "local_selected_strategy_identities_sealed" => true,
        "evaluation_values_inspected_before_seal" => 0,
        "evaluation_values_materialized_before_seal" => 0,
        "evaluation_values_used_before_seal" => 0,
        "historical_evaluation_return_access_permitted" => false,
        "next_permitted_stage" =>
            "evaluation extraction bound to both primary and robustness result seals",
    )
end

function seal_proposal_robustness_result(; check = false)
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(SEAL_PATH) || error("proposal robustness result seal is absent")
        read(SEAL_PATH, String) == text || error("proposal robustness result seal changed")
    elseif isfile(SEAL_PATH)
        read(SEAL_PATH, String) == text ||
            error("refusing to replace nonidentical proposal robustness result seal")
    else
        open(SEAL_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PROPOSAL_ROBUSTNESS_RESULT_SEAL_PASSED")
    println("grid cell-spec denominator sealed: 912; policy choices: 1824")
    println("evaluation values inspected/materialized/used: 0")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    seal_proposal_robustness_result(; check = "--check" in args)
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    SealFinancialStrategyLibraryPanelV3ProposalRobustnessResult.main()
end
