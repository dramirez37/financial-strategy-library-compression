module ExportFinancialStrategyLibraryPanelV3ProposalPolicy

using SHA: sha256
using TOML

export export_proposal_policy, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const INTERFACE_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_INTERFACE_LOCK_003.toml")
const PUBLIC_STAGE_PATH =
    joinpath(EXPERIMENT_ROOT, "proposal_stage", "PROPOSAL_STAGE_MANIFEST.toml")
const LOCAL_STAGE_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal",
    "PROPOSAL_STAGE_LOCAL_MANIFEST.toml",
)
const PUBLIC_COMPUTATION_PATH = joinpath(
    EXPERIMENT_ROOT,
    "proposal_computation",
    "PROPOSAL_COMPUTATION_MANIFEST.toml",
)
const LOCAL_COMPUTATION_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal_computation",
    "PROPOSAL_COMPUTATION_LOCAL_MANIFEST.toml",
)
const PUBLIC_OUTPUT_PATH = joinpath(
    EXPERIMENT_ROOT,
    "proposal_policy",
    "PROPOSAL_POLICY_MANIFEST.toml",
)
const LOCAL_OUTPUT_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal_policy",
    "PROPOSAL_POLICY_LOCAL_MANIFEST.toml",
)
const POLICY_IDS = (
    "frontier_only_robust_policy",
    "innovation_safe_robust_policy",
    "innovation_safe_forced_max",
    "equal_weight_available_policy",
    "source_uncompressed_robust_policy",
)

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

_sha256_text(value) = bytes2hex(sha256(codeunits(String(value))))

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _write_new_or_identical(path, text; check)
    if check
        isfile(path) || error("proposal policy manifest is absent")
        read(path, String) == text || error("proposal policy manifest changed")
    elseif isfile(path)
        read(path, String) == text || error("refusing to replace nonidentical policy manifest")
    else
        mkpath(dirname(path))
        open(path, "w") do io
            write(io, text)
        end
    end
    return path
end

_cell_map(manifest) = Dict(Int(cell["cell_index"]) => cell for cell in manifest["cells"])

function _load_contract()
    for path in (
        INTERFACE_LOCK_PATH,
        PUBLIC_STAGE_PATH,
        LOCAL_STAGE_PATH,
        PUBLIC_COMPUTATION_PATH,
        LOCAL_COMPUTATION_PATH,
    )
        isfile(path) || error("proposal policy interface input is absent")
    end
    lock = TOML.parsefile(INTERFACE_LOCK_PATH)
    lock["status"] == "LOCKED_PROPOSAL_POLICY_INTERFACE_003" ||
        error("proposal policy interface is not locked")
    lock["historical_evaluation_return_access_permitted"] === false ||
        error("proposal policy interface permits evaluation access")
    for (relative, digest) in Dict{String,String}(lock["sealed_file_sha256"])
        _sha256_file(joinpath(REPOSITORY_ROOT, relative)) == digest ||
            error("proposal policy interface input changed: $relative")
    end
    for (path, field) in (
        (PUBLIC_STAGE_PATH, "public_proposal_stage_manifest_sha256"),
        (LOCAL_STAGE_PATH, "local_proposal_stage_manifest_sha256"),
        (PUBLIC_COMPUTATION_PATH, "public_proposal_computation_manifest_sha256"),
        (LOCAL_COMPUTATION_PATH, "local_proposal_computation_manifest_sha256"),
    )
        lock[field] == _sha256_file(path) || error("proposal interface manifest binding changed")
    end
    return (;
        lock,
        public_stage = TOML.parsefile(PUBLIC_STAGE_PATH),
        local_stage = TOML.parsefile(LOCAL_STAGE_PATH),
        public_computation = TOML.parsefile(PUBLIC_COMPUTATION_PATH),
        local_computation = TOML.parsefile(LOCAL_COMPUTATION_PATH),
    )
end

function _public_choice(policy_id, choice, comparator_ids)
    ids = String.(choice["selected_strategy_ids"])
    choice_hash = _sha256_text(join(String[policy_id; ids], '\0'))
    return Dict{String,Any}(
        "policy_id" => String(policy_id),
        "available" => !isempty(ids),
        "selected_strategy_count" => length(ids),
        "same_choice_as_comparator" => ids == comparator_ids,
        "choice_sha256" => choice_hash,
        "used_cash" => Bool(choice["used_cash"]),
        "eligible_count" => Int(choice["eligible_count"]),
        "complete_candidate_count" => Int(choice["complete_candidate_count"]),
        "failure_code" => String(choice["failure_code"]),
        "proposal_incremental_point_delta" => choice["selected_point_delta"],
    )
end

function _failed_choices()
    return [Dict{String,Any}(
        "policy_id" => policy,
        "available" => false,
        "selected_strategy_count" => 0,
        "same_choice_as_comparator" => false,
        "choice_sha256" => _sha256_text(policy * "\0UNAVAILABLE_UNIVERSE_GATE_FAILED"),
        "used_cash" => false,
        "eligible_count" => 0,
        "complete_candidate_count" => 0,
        "failure_code" => "UNIVERSE_GATE_FAILED",
        "proposal_incremental_point_delta" => "",
    ) for policy in POLICY_IDS]
end

function export_proposal_policy(; check = false)
    contract = _load_contract()
    public_stage = _cell_map(contract.public_stage)
    local_stage = _cell_map(contract.local_stage)
    public_computation = _cell_map(contract.public_computation)
    local_computation = _cell_map(contract.local_computation)
    for cells in (public_stage, local_stage, public_computation, local_computation)
        sort!(collect(keys(cells))) == collect(1:38) ||
            error("proposal policy cell denominator changed")
    end
    public_cells = Dict{String,Any}[]
    local_cells = Dict{String,Any}[]
    for index in 1:38
        stage_cell = public_stage[index]
        local_stage_cell = local_stage[index]
        computation_cell = public_computation[index]
        local_computation_cell = local_computation[index]
        prefix = "cell-$(lpad(index, 3, '0'))"
        computation_hashes = Dict{String,String}(
            local_computation_cell["local_artifact_sha256"],
        )
        choice_relative = joinpath("local_data", "proposal_computation", "$prefix-choices.toml")
        ledger_relative = joinpath("local_data", "proposal_computation", "$prefix-trial-ledger.csv")
        choice_hash = computation_hashes[choice_relative]
        ledger_hash = computation_hashes[ledger_relative]
        choice_path = joinpath(EXPERIMENT_ROOT, choice_relative)
        _sha256_file(choice_path) == choice_hash || error("proposal choice artifact changed")
        choices_file = TOML.parsefile(choice_path)
        if Bool(stage_cell["universe_gate_passed"])
            exact_choices = Dict(String(row["policy_id"]) => row for row in choices_file["choices"])
            sort!(collect(keys(exact_choices))) == sort!(collect(POLICY_IDS)) ||
                error("proposal choice policy family changed")
            comparator_ids = String.(
                exact_choices["frontier_only_robust_policy"]["selected_strategy_ids"],
            )
            choices = [
                _public_choice(policy, exact_choices[policy], comparator_ids) for
                policy in POLICY_IDS
            ]
            local_choices = [
                merge(copy(choices[position]), Dict{String,Any}(
                    "strategy_ids" => String.(exact_choices[policy]["selected_strategy_ids"]),
                    "strategy_id" => length(exact_choices[policy]["selected_strategy_ids"]) == 1 ?
                        String(only(exact_choices[policy]["selected_strategy_ids"])) : "",
                    "baseline_strategy_id" => String(exact_choices[policy]["baseline_strategy_id"]),
                    "selected_lower_bound" => exact_choices[policy]["selected_lower_bound"],
                )) for (position, policy) in enumerate(POLICY_IDS)
            ]
        else
            choices = _failed_choices()
            local_choices = [merge(copy(choice), Dict{String,Any}(
                "strategy_ids" => String[],
                "strategy_id" => "",
                "baseline_strategy_id" => "",
                "selected_lower_bound" => "",
            )) for choice in choices]
        end
        choice_aggregate = _sha256_text(join(
            (String(choice["choice_sha256"]) for choice in choices),
            '\n',
        ))
        safe_choice = only(filter(
            choice -> choice["policy_id"] == "innovation_safe_robust_policy",
            choices,
        ))
        public = Dict{String,Any}(
            "cell_index" => index,
            "origin_id" => String(stage_cell["origin_id"]),
            "universe_id" => String(stage_cell["universe_id"]),
            "role" => String(stage_cell["role"]),
            "universe_status" => String(stage_cell["universe_status"]),
            "universe_gate_passed" => Bool(stage_cell["universe_gate_passed"]),
            "evaluation_year" => Int(stage_cell["evaluation_year"]),
            "security_weight_cap" => String(stage_cell["universe_id"]) ==
                "liquid_common_equity" ? 0.05 : 0.10,
            "primary_choices" => choices,
            "choice_aggregate_sha256" => choice_aggregate,
            "proposal_incremental_point_delta" =>
                safe_choice["proposal_incremental_point_delta"],
            "proposal_trial_ledger_rows" => Int(computation_cell["proposal_trial_ledger_rows"]),
            "evaluation_values_inspected_materialized_or_used" => 0,
            "selected_strategy_identities_included" => false,
            "return_values_included" => false,
        )
        local_cell = copy(public)
        local_cell["primary_choices"] = local_choices
        local_cell["selected_strategy_identities_included"] = Bool(stage_cell["universe_gate_passed"])
        local_cell["proposal_combined_relative_path"] =
            String(local_stage_cell["local_artifact_relative_path"])
        local_cell["proposal_combined_sha256"] =
            String(local_stage_cell["local_artifact_sha256"])
        local_cell["proposal_trial_ledger_relative_path"] = ledger_relative
        local_cell["proposal_trial_ledger_sha256"] = ledger_hash
        local_cell["proposal_choice_relative_path"] = choice_relative
        local_cell["proposal_choice_sha256"] = choice_hash
        push!(public_cells, public)
        push!(local_cells, local_cell)
    end
    common = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-policy-manifest-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "PROPOSAL_POLICY_INTERFACE_FROZEN",
        "language" => "Julia",
        "cell_count" => 38,
        "available_cell_count" => 37,
        "failed_universe_cells_retained" => 1,
        "registered_policy_count" => 5,
        "proposal_trial_ledger_rows" => 18_430,
        "forced_max_unavailable_gate_passed_cells" =>
            contract.public_computation["forced_max_unavailable_gate_passed_cells"],
        "proposal_policy_interface_lock_sha256" => _sha256_file(INTERFACE_LOCK_PATH),
        "public_proposal_computation_manifest_sha256" => _sha256_file(PUBLIC_COMPUTATION_PATH),
        "local_proposal_computation_manifest_sha256" => _sha256_file(LOCAL_COMPUTATION_PATH),
        "evaluation_values_inspected" => 0,
        "evaluation_values_materialized" => 0,
        "evaluation_values_used" => 0,
    )
    public_payload = copy(common)
    public_payload["return_values_included"] = false
    public_payload["selected_strategy_identities_included"] = false
    public_payload["cells"] = public_cells
    public_text = _toml_text(public_payload)
    local_payload = copy(common)
    local_payload["return_values_included"] = false
    local_payload["selected_strategy_identities_included"] = true
    local_payload["public_manifest_sha256"] = _sha256_text(public_text)
    local_payload["cells"] = local_cells
    local_text = _toml_text(local_payload)
    _write_new_or_identical(PUBLIC_OUTPUT_PATH, public_text; check)
    _write_new_or_identical(LOCAL_OUTPUT_PATH, local_text; check)
    println("V3_PROPOSAL_POLICY_INTERFACE_PASSED")
    println("cells retained: 38; locally available: 37")
    println("public selected strategy identities included: false")
    println("evaluation values inspected/materialized/used: 0")
    return public_payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    export_proposal_policy(; check = "--check" in args)
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    ExportFinancialStrategyLibraryPanelV3ProposalPolicy.main()
end
