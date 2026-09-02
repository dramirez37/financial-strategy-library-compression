module RunFinancialStrategyLibraryPanelV3ProposalRobustness

using SHA: sha256
using TOML

include(joinpath(@__DIR__, "run_financial_strategy_library_panel_v3_proposal.jl"))
const Primary = RunFinancialStrategyLibraryPanelV3Proposal
const PrimaryProposal = Primary.Proposal
const Predecision =
    PrimaryProposal.FinancialStrategyLibraryPanelV3PredecisionComputation

include(joinpath(
    @__DIR__,
    "..",
    "src",
    "FinancialStrategyLibraryPanelV3ProposalRobustness.jl",
))
using .FinancialStrategyLibraryPanelV3ProposalRobustness
const Robustness = FinancialStrategyLibraryPanelV3ProposalRobustness

export run_proposal_robustness, audit_proposal_robustness, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const ACCESS_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_ROBUSTNESS_FREEZE_AMENDMENT_004_LOCK.toml")
const COMPUTATION_AMENDMENT_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_ROBUSTNESS_COMPUTATION_AMENDMENT_005_LOCK.toml")
const CHAIN_LOCK_PATH = joinpath(
    EXPERIMENT_ROOT,
    "PROPOSAL_POSTCOMPLETION_BINDING_AMENDMENT_003_LOCK_002.toml",
)
const PROPOSAL_RESULT_SEAL_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_POLICY_RESULT_SEAL.toml")
const PREDECISION_RESULT_SEAL_PATH =
    joinpath(EXPERIMENT_ROOT, "PREDECISION_COMPUTATION_RESULT_SEAL.toml")
const LOCAL_PROPOSAL_POLICY_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal_policy",
    "PROPOSAL_POLICY_LOCAL_MANIFEST.toml",
)
const LOCAL_PROPOSAL_STAGE_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "proposal",
    "PROPOSAL_STAGE_LOCAL_MANIFEST.toml",
)
const LOCAL_PREDECISION_RESULT_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "predecision_computation",
    "PREDECISION_COMPUTATION_LOCAL_MANIFEST.toml",
)
const UNIVERSE_SELECTION_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "universe_census",
    "UNIVERSE_SELECTIONS.toml",
)
const PROPOSAL_EXECUTION_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PROPOSAL_EXECUTION_LOCK.toml")
const PUBLIC_RESULT_PATH = joinpath(
    EXPERIMENT_ROOT,
    "proposal_robustness",
    "PROPOSAL_ROBUSTNESS_MANIFEST.toml",
)
const LOCAL_RESULT_ROOT = joinpath(EXPERIMENT_ROOT, "local_data", "proposal_robustness")
const LOCAL_RESULT_PATH = joinpath(LOCAL_RESULT_ROOT, "PROPOSAL_ROBUSTNESS_LOCAL_MANIFEST.toml")
const COSTS_BPS = (0.0, 5.0, 15.0, 30.0)
const RISK_AVERSIONS = (1.0, 3.0)
const HURDLES = (0.0, 0.0025, 0.005)
const GRID_SPEC_COUNT = 24
const GRID_POLICY_COUNT = 2
const EXPECTED_CHAIN_LOCK_SHA256 =
    "27453e2ecb68c165d52301c386d3c95f5cf8cee5d73f9d55d010ece91e91ed98"
const EXPECTED_PROPOSAL_RESULT_SEAL_SHA256 =
    "35ac8541432dfd102944024fde36b82324ea3bc943bc6556aef11ca1b2a251b4"

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

function _write_new_or_identical(path, content)
    if isfile(path)
        read(path, String) == content ||
            error("refusing to replace a nonidentical proposal robustness artifact")
        return path
    end
    mkpath(dirname(path))
    temporary = path * ".tmp.$(getpid()).$(Threads.threadid())"
    open(temporary, "w") do io
        write(io, content)
    end
    mv(temporary, path)
    return path
end

_cell_map(manifest) = Dict(Int(cell["cell_index"]) => cell for cell in manifest["cells"])

function _selection_map(manifest)
    return Dict(
        (String(cell["origin_id"]), String(cell["universe_id"])) => cell for
        cell in manifest["cells"]
    )
end

function _load_contract()
    for path in (
        ACCESS_LOCK_PATH,
        CHAIN_LOCK_PATH,
        PROPOSAL_RESULT_SEAL_PATH,
        PREDECISION_RESULT_SEAL_PATH,
        LOCAL_PROPOSAL_POLICY_PATH,
        LOCAL_PROPOSAL_STAGE_PATH,
        LOCAL_PREDECISION_RESULT_PATH,
        UNIVERSE_SELECTION_PATH,
        PROPOSAL_EXECUTION_LOCK_PATH,
    )
        isfile(path) || error("proposal robustness input is absent: $(relpath(path, REPOSITORY_ROOT))")
    end
    _sha256_file(CHAIN_LOCK_PATH) == EXPECTED_CHAIN_LOCK_SHA256 ||
        error("proposal postcompletion binding changed")
    _sha256_file(PROPOSAL_RESULT_SEAL_PATH) == EXPECTED_PROPOSAL_RESULT_SEAL_SHA256 ||
        error("proposal result seal changed")
    lock = TOML.parsefile(ACCESS_LOCK_PATH)
    lock["status"] == "LOCKED_PROPOSAL_ROBUSTNESS_FREEZE_AMENDMENT_004" ||
        error("proposal robustness is not locked")
    lock["proposal_postcompletion_binding_amendment_003_sha256"] ==
        _sha256_file(CHAIN_LOCK_PATH) || error("robustness lock does not bind proposal chain")
    lock["proposal_policy_result_seal_sha256"] == _sha256_file(PROPOSAL_RESULT_SEAL_PATH) ||
        error("robustness lock does not bind proposal result")
    lock["historical_proposal_return_reuse_permitted"] === true ||
        error("robustness lock does not permit proposal reuse")
    lock["historical_evaluation_return_access_permitted"] === false ||
        error("robustness lock permits evaluation access")
    for field in (
        "evaluation_values_inspected_before_lock",
        "evaluation_values_materialized_before_lock",
        "evaluation_values_used_before_lock",
    )
        lock[field] == 0 || error("robustness lock records evaluation access")
    end
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
    for (relative, digest) in Dict{String,String}(lock["sealed_file_sha256"])
        actual = _sha256_file(joinpath(REPOSITORY_ROOT, relative))
        actual == digest && continue
        get(amended_hashes, relative, "") == actual ||
            error("proposal robustness sealed input changed without amendment: $relative")
    end
    execution = TOML.parsefile(PROPOSAL_EXECUTION_LOCK_PATH)
    execution["universe_selection_sha256"] == _sha256_file(UNIVERSE_SELECTION_PATH) ||
        error("preproposal universe membership mapping changed")
    policy = TOML.parsefile(LOCAL_PROPOSAL_POLICY_PATH)
    stage = TOML.parsefile(LOCAL_PROPOSAL_STAGE_PATH)
    predecision = TOML.parsefile(LOCAL_PREDECISION_RESULT_PATH)
    selection = TOML.parsefile(UNIVERSE_SELECTION_PATH)
    for manifest in (policy, stage, predecision)
        manifest["cell_count"] == 38 || error("proposal robustness cell denominator changed")
    end
    policy["evaluation_values_inspected"] == 0 || error("evaluation values were inspected")
    policy["evaluation_values_materialized"] == 0 || error("evaluation values were materialized")
    policy["evaluation_values_used"] == 0 || error("evaluation values were used")
    return (;
        lock,
        policy = _cell_map(policy),
        stage = _cell_map(stage),
        predecision = _cell_map(predecision),
        selection = _selection_map(selection),
        predecision_seal = TOML.parsefile(PREDECISION_RESULT_SEAL_PATH),
    )
end

function _proposal_paths(origin_id, universe_id, panel, proposal_year, strategy_ids, weight_cap)
    all_paths = Predecision.build_strategy_paths(
        origin_id,
        universe_id,
        panel.returns,
        panel.available,
        panel.terminal_delisting;
        security_weight_cap = weight_cap,
    )
    lookup = Dict(path.strategy_id => path for path in all_paths)
    requested = sort!(unique(filter(!=(Robustness.CASH_ID), String.(strategy_ids))))
    issubset(Set(requested), Set(keys(lookup))) ||
        error("robustness action set is outside the frozen 96-strategy grammar")
    proposal_indices = findall(
        date -> startswith(String(date), "$(Int(proposal_year))-"),
        panel.dates,
    )
    length(proposal_indices) > 1 || error("robustness proposal calendar is incomplete")
    result = RobustnessPath[]
    for strategy_id in requested
        path = lookup[strategy_id]
        push!(result, RobustnessPath(
            strategy_id,
            Union{Missing,Float64}[path.gross_returns[index] for index in proposal_indices],
            Float64[path.turnover[index] for index in proposal_indices],
            BitVector(path.available[proposal_indices]),
        ))
    end
    return result
end

function _subset_panel(panel, permnos)
    index = Dict(permno => position for (position, permno) in enumerate(panel.permnos))
    all(permno -> haskey(index, permno), permnos) ||
        error("cap sensitivity membership is outside the frozen panel")
    columns = [index[permno] for permno in permnos]
    return Primary.CombinedPanel(
        copy(panel.dates),
        Int64.(permnos),
        panel.returns[:, columns],
        panel.available[:, columns],
        panel.terminal_delisting[:, columns],
    )
end

function _spec_id(cost_bps, risk_aversion, hurdle)
    cost = lpad(string(round(Int, cost_bps)), 2, '0')
    risk = string(round(Int, risk_aversion))
    hurdle_bps = lpad(string(round(Int, hurdle * 10_000)), 2, '0')
    return "cost$(cost)_risk$(risk)_hurdle$(hurdle_bps)bp"
end

function _finite_or_blank(value)
    return value isa Real && isfinite(value) ? Float64(value) : ""
end

function _choice_payload(choice)
    return Dict{String,Any}(
        "policy_id" => choice.policy_id,
        "strategy_id" => choice.selected_strategy_id,
        "strategy_ids" => [choice.selected_strategy_id],
        "used_cash" => choice.used_cash,
        "baseline_strategy_id" => choice.baseline_strategy_id,
        "selected_point_delta" => _finite_or_blank(choice.selected_point_delta),
        "selected_lower_bound" => _finite_or_blank(choice.selected_lower_bound),
        "eligible_count" => choice.eligible_count,
        "complete_candidate_count" => choice.complete_candidate_count,
        "failure_code" => choice.failure_code,
    )
end

function _unavailable_choice(policy_id, failure_code)
    return Dict{String,Any}(
        "policy_id" => String(policy_id),
        "strategy_id" => "",
        "strategy_ids" => String[],
        "used_cash" => false,
        "baseline_strategy_id" => "",
        "selected_point_delta" => "",
        "selected_lower_bound" => "",
        "eligible_count" => 0,
        "complete_candidate_count" => 0,
        "failure_code" => String(failure_code),
    )
end

function _inference_payload(policy_id, inference)
    return Dict{String,Any}(
        "policy_id" => String(policy_id),
        "bootstrap_repetitions" => inference.bootstrap_repetitions,
        "moving_block_sessions" => inference.moving_block_sessions,
        "familywise_alpha" => 0.10,
        "seed" => inference.seed,
        "critical_value" => inference.critical_value,
        "shrinkage_center" => inference.shrinkage_center,
        "estimated_between_variance" => inference.estimated_between_variance,
        "simultaneous_family_contrast_count" =>
            inference.simultaneous_family_contrast_count,
        "candidate_count" => length(inference.candidate_ids),
        "candidates" => [
            Dict{String,Any}(
                "strategy_id" => inference.candidate_ids[index],
                "point_delta" => inference.point_deltas[index],
                "standard_error" => inference.standard_errors[index],
                "simultaneous_lower_bound" => inference.lower_bounds[index],
                "shrunk_delta" => inference.shrunk_deltas[index],
            ) for index in eachindex(inference.candidate_ids)
        ],
    )
end

function _choice_hash(context_id, choice_payload)
    selected = String.(choice_payload["strategy_ids"])
    identity = isempty(selected) ? String(choice_payload["failure_code"]) : join(selected, '\0')
    return _sha256_text(join((
        String(context_id),
        String(choice_payload["policy_id"]),
        identity,
    ), '\0'))
end

function _primary_choice(policy_cell, policy_id)
    choices = filter(
        choice -> String(choice["policy_id"]) == String(policy_id),
        policy_cell["primary_choices"],
    )
    length(choices) == 1 || error("sealed primary policy choice is missing")
    return only(choices)
end

function _grid_payload(grid)
    local_records = Dict{String,Any}[]
    public_records = Dict{String,Any}[]
    choice_hashes = String[]
    for result in grid
        spec_id = _spec_id(result.cost_bps, result.risk_aversion, result.hurdle)
        comparator = _choice_payload(result.comparator)
        safe = _choice_payload(result.safe)
        comparator_hash = _choice_hash(spec_id, comparator)
        safe_hash = _choice_hash(spec_id, safe)
        append!(choice_hashes, (comparator_hash, safe_hash))
        push!(local_records, Dict{String,Any}(
            "spec_id" => spec_id,
            "cost_bps" => result.cost_bps,
            "risk_aversion" => result.risk_aversion,
            "adoption_hurdle" => result.hurdle,
            "comparator_choice" => comparator,
            "safe_choice" => safe,
            "comparator_choice_sha256" => comparator_hash,
            "safe_choice_sha256" => safe_hash,
            "comparator_inference" => _inference_payload(
                "frontier_only_robust_policy", result.comparator_inference,
            ),
            "safe_inference" => _inference_payload(
                "innovation_safe_robust_policy", result.safe_inference,
            ),
        ))
        push!(public_records, Dict{String,Any}(
            "spec_id" => spec_id,
            "cost_bps" => result.cost_bps,
            "risk_aversion" => result.risk_aversion,
            "adoption_hurdle" => result.hurdle,
            "available" => true,
            "comparator_choice_sha256" => comparator_hash,
            "safe_choice_sha256" => safe_hash,
            "same_choice" => comparator["strategy_id"] == safe["strategy_id"],
            "comparator_used_cash" => comparator["used_cash"],
            "safe_used_cash" => safe["used_cash"],
            "comparator_complete_candidate_count" =>
                comparator["complete_candidate_count"],
            "safe_complete_candidate_count" => safe["complete_candidate_count"],
        ))
    end
    return (;
        local_records,
        public_records,
        choice_hashes,
        aggregate = _sha256_text(join(choice_hashes, '\n')),
    )
end

function _failed_grid_payload()
    local_records = Dict{String,Any}[]
    public_records = Dict{String,Any}[]
    choice_hashes = String[]
    for cost in COSTS_BPS, risk in RISK_AVERSIONS, hurdle in HURDLES
        spec_id = _spec_id(cost, risk, hurdle)
        comparator = _unavailable_choice(
            "frontier_only_robust_policy", "UNIVERSE_GATE_FAILED",
        )
        safe = _unavailable_choice(
            "innovation_safe_robust_policy", "UNIVERSE_GATE_FAILED",
        )
        comparator_hash = _choice_hash(spec_id, comparator)
        safe_hash = _choice_hash(spec_id, safe)
        append!(choice_hashes, (comparator_hash, safe_hash))
        push!(local_records, Dict{String,Any}(
            "spec_id" => spec_id,
            "cost_bps" => cost,
            "risk_aversion" => risk,
            "adoption_hurdle" => hurdle,
            "comparator_choice" => comparator,
            "safe_choice" => safe,
            "comparator_choice_sha256" => comparator_hash,
            "safe_choice_sha256" => safe_hash,
            "failure_code" => "UNIVERSE_GATE_FAILED",
        ))
        push!(public_records, Dict{String,Any}(
            "spec_id" => spec_id,
            "cost_bps" => cost,
            "risk_aversion" => risk,
            "adoption_hurdle" => hurdle,
            "available" => false,
            "failure_code" => "UNIVERSE_GATE_FAILED",
            "comparator_choice_sha256" => comparator_hash,
            "safe_choice_sha256" => safe_hash,
            "same_choice" => false,
            "comparator_used_cash" => false,
            "safe_used_cash" => false,
            "comparator_complete_candidate_count" => 0,
            "safe_complete_candidate_count" => 0,
        ))
    end
    return (;
        local_records,
        public_records,
        choice_hashes,
        aggregate = _sha256_text(join(choice_hashes, '\n')),
    )
end

function _cap_payload(universe_id, grid, cap50_result)
    local_records = Dict{String,Any}[]
    public_records = Dict{String,Any}[]
    if universe_id != "liquid_common_equity"
        for cap in (50, 100, 200)
            push!(local_records, Dict{String,Any}(
                "liquidity_cap" => cap,
                "available" => false,
                "failure_code" => "NOT_APPLICABLE_COMMON_EQUITY_UNIVERSE",
            ))
            push!(public_records, copy(last(local_records)))
        end
        return (; local_records, public_records)
    end
    primary = only(filter(
        row -> row.cost_bps == 5 && row.risk_aversion == 3 && row.hurdle == 0.0025,
        grid,
    ))
    for (cap, result, source) in (
        (50, cap50_result, "PREPROPOSAL_RANKED_TOP50"),
        (100, primary, "PRIMARY_FROZEN_TOP100"),
    )
        context = "common_equity_cap$(cap)"
        comparator = _choice_payload(result.comparator)
        safe = _choice_payload(result.safe)
        comparator_hash = _choice_hash(context, comparator)
        safe_hash = _choice_hash(context, safe)
        push!(local_records, Dict{String,Any}(
            "liquidity_cap" => cap,
            "available" => true,
            "membership_source" => source,
            "cost_bps" => 5.0,
            "risk_aversion" => 3.0,
            "adoption_hurdle" => 0.0025,
            "comparator_choice" => comparator,
            "safe_choice" => safe,
            "comparator_choice_sha256" => comparator_hash,
            "safe_choice_sha256" => safe_hash,
        ))
        push!(public_records, Dict{String,Any}(
            "liquidity_cap" => cap,
            "available" => true,
            "membership_source" => source,
            "comparator_choice_sha256" => comparator_hash,
            "safe_choice_sha256" => safe_hash,
            "same_choice" => comparator["strategy_id"] == safe["strategy_id"],
        ))
    end
    unavailable = Dict{String,Any}(
        "liquidity_cap" => 200,
        "available" => false,
        "failure_code" => "DESIGN_NOT_FROZEN_BEFORE_PROPOSAL",
    )
    push!(local_records, unavailable)
    push!(public_records, copy(unavailable))
    return (; local_records, public_records)
end

function _cell_computation(index, contract)
    stage_cell = contract.stage[index]
    policy_cell = contract.policy[index]
    predecision_cell = contract.predecision[index]
    origin_id = String(stage_cell["origin_id"])
    universe_id = String(stage_cell["universe_id"])
    gate = Bool(stage_cell["universe_gate_passed"])
    grid_payload = _failed_grid_payload()
    cap_payload = universe_id == "liquid_common_equity" ? nothing :
        _cap_payload(universe_id, NamedTuple[], nothing)
    if gate
        panel = Primary._load_combined_panel(stage_cell)
        proposal_year = Int(stage_cell["proposal_year"])
        arms = Primary._arm_payload(index, predecision_cell, contract.predecision_seal)
        source_ids = String.(arms["source_action_set_strategy_ids"])
        safe_ids = String.(arms["safe_action_set_strategy_ids"])
        comparator_ids = String.(arms["comparator_action_set_strategy_ids"])
        Set(comparator_ids) ⊆ Set(safe_ids) ⊆ Set(source_ids) ||
            error("robustness action sets are not nested")
        weight_cap = Float64(policy_cell["security_weight_cap"])
        paths = _proposal_paths(
            origin_id,
            universe_id,
            panel,
            proposal_year,
            source_ids,
            weight_cap,
        )
        lookup = Dict(path.strategy_id => path for path in paths)
        safe_paths = RobustnessPath[lookup[id] for id in safe_ids if id != Robustness.CASH_ID]
        comparator_paths = RobustnessPath[
            lookup[id] for id in comparator_ids if id != Robustness.CASH_ID
        ]
        grid = freeze_cost_risk_hurdle_grid(
            safe_paths,
            comparator_paths,
            origin_id,
            universe_id,
        )
        length(grid) == GRID_SPEC_COUNT || error("registered robustness grid changed")
        grid_payload = _grid_payload(grid)
        primary = only(filter(
            row -> row.cost_bps == 5 && row.risk_aversion == 3 && row.hurdle == 0.0025,
            grid,
        ))
        primary_comparator = _primary_choice(policy_cell, "frontier_only_robust_policy")
        primary_safe = _primary_choice(policy_cell, "innovation_safe_robust_policy")
        primary.comparator.selected_strategy_id == String(primary_comparator["strategy_id"]) ||
            error("robustness primary comparator does not reproduce sealed choice")
        primary.safe.selected_strategy_id == String(primary_safe["strategy_id"]) ||
            error("robustness primary safe policy does not reproduce sealed choice")

        cap50_result = nothing
        if universe_id == "liquid_common_equity"
            selection = contract.selection[(origin_id, universe_id)]
            selected = sort!(collect(selection["selected"]); by = row -> Int(row["rank"]))
            length(selected) == 100 || error("frozen common-equity membership changed")
            ranked_permnos = Int64.(getindex.(selected, "permno"))
            Set(ranked_permnos) == Set(panel.permnos) ||
                error("ranked common-equity membership differs from staged panel")
            cap50_panel = _subset_panel(panel, ranked_permnos[1:50])
            cap50_paths = _proposal_paths(
                origin_id,
                universe_id,
                cap50_panel,
                proposal_year,
                source_ids,
                weight_cap,
            )
            cap50_lookup = Dict(path.strategy_id => path for path in cap50_paths)
            cap50_result = primary_cap_choices(
                RobustnessPath[
                    cap50_lookup[id] for id in safe_ids if id != Robustness.CASH_ID
                ],
                RobustnessPath[
                    cap50_lookup[id] for id in comparator_ids if id != Robustness.CASH_ID
                ],
                origin_id,
                universe_id,
            )
        end
        cap_payload = _cap_payload(universe_id, grid, cap50_result)
    end
    isnothing(cap_payload) && error("common-equity cap disposition was not frozen")

    prefix = "cell-$(lpad(index, 3, '0'))"
    relative = joinpath("local_data", "proposal_robustness", "$prefix.toml")
    local_payload = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-robustness-cell-v1",
        "cell_index" => index,
        "origin_id" => origin_id,
        "universe_id" => universe_id,
        "role" => String(stage_cell["role"]),
        "universe_gate_passed" => gate,
        "grid_spec_count" => GRID_SPEC_COUNT,
        "grid_policy_choice_count" => GRID_SPEC_COUNT * GRID_POLICY_COUNT,
        "grid_choice_aggregate_sha256" => grid_payload.aggregate,
        "grid_records" => grid_payload.local_records,
        "common_equity_cap_records" => cap_payload.local_records,
        "permuted_closure_sham" => Dict{String,Any}(
            "available" => false,
            "failure_code" => "DESIGN_NOT_FROZEN_BEFORE_PROPOSAL",
        ),
        "evaluation_values_inspected_materialized_or_used" => 0,
        "return_values_included" => false,
        "selected_strategy_identities_included" => gate,
    )
    local_text = _toml_text(local_payload)
    _write_new_or_identical(joinpath(EXPERIMENT_ROOT, relative), local_text)
    artifact_hash = _sha256_text(local_text)
    public = Dict{String,Any}(
        "cell_index" => index,
        "origin_id" => origin_id,
        "universe_id" => universe_id,
        "role" => String(stage_cell["role"]),
        "universe_gate_passed" => gate,
        "grid_spec_count" => GRID_SPEC_COUNT,
        "grid_policy_choice_count" => GRID_SPEC_COUNT * GRID_POLICY_COUNT,
        "available_grid_spec_count" => gate ? GRID_SPEC_COUNT : 0,
        "grid_choice_aggregate_sha256" => grid_payload.aggregate,
        "grid_records" => grid_payload.public_records,
        "common_equity_cap_records" => cap_payload.public_records,
        "permuted_closure_sham_available" => false,
        "permuted_closure_sham_failure_code" => "DESIGN_NOT_FROZEN_BEFORE_PROPOSAL",
        "return_values_included" => false,
        "selected_strategy_identities_included" => false,
        "evaluation_values_inspected_materialized_or_used" => 0,
    )
    local_cell = copy(public)
    local_cell["local_artifact_relative_path"] = relative
    local_cell["local_artifact_sha256"] = artifact_hash
    local_cell["selected_strategy_identities_included"] = gate
    println(stderr, "v3 proposal robustness completed cell $index/38 $origin_id $universe_id")
    return (; public, local_cell, relative, artifact_hash)
end

function run_proposal_robustness()
    contract = _load_contract()
    sort!(collect(keys(contract.stage))) == collect(1:38) ||
        error("proposal robustness denominator changed")
    results = Vector{Any}(undef, 38)
    Threads.@threads :static for index in 1:38
        results[index] = _cell_computation(index, contract)
    end
    public_cells = [results[index].public for index in 1:38]
    local_cells = [results[index].local_cell for index in 1:38]
    artifacts = Dict(
        results[index].relative => results[index].artifact_hash for index in 1:38
    )
    cell_aggregate = _sha256_text(join(
        (String(cell["grid_choice_aggregate_sha256"]) for cell in public_cells),
        '\n',
    ))
    common = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-robustness-manifest-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "PROPOSAL_ROBUSTNESS_CHOICES_FROZEN",
        "language" => "Julia",
        "cell_count" => 38,
        "available_cell_count" => 37,
        "failed_universe_cells_retained" => 1,
        "costs_bps" => collect(COSTS_BPS),
        "risk_aversions" => collect(RISK_AVERSIONS),
        "adoption_hurdles" => collect(HURDLES),
        "grid_spec_count_per_cell" => GRID_SPEC_COUNT,
        "grid_policy_count" => GRID_POLICY_COUNT,
        "grid_cell_spec_denominator" => 38 * GRID_SPEC_COUNT,
        "grid_policy_choice_denominator" => 38 * GRID_SPEC_COUNT * GRID_POLICY_COUNT,
        "available_grid_cell_specs" => 37 * GRID_SPEC_COUNT,
        "bootstrap_repetitions" => 5_000,
        "moving_block_sessions" => 20,
        "familywise_alpha" => 0.10,
        "family_shrinkage_applied" => true,
        "comparator_cash_max_t_applied" => true,
        "safe_joint_all_comparator_max_t_applied" => true,
        "data_dependent_comparator_selection_covered" => true,
        "cell_choice_aggregate_sha256" => cell_aggregate,
        "common_equity_cap50_available_cells" => 19,
        "common_equity_cap100_available_cells" => 19,
        "common_equity_cap200_unavailable_cells" => 19,
        "common_equity_cap200_failure_code" => "DESIGN_NOT_FROZEN_BEFORE_PROPOSAL",
        "permuted_closure_sham_available_cells" => 0,
        "permuted_closure_sham_unavailable_cells" => 38,
        "permuted_closure_sham_failure_code" => "DESIGN_NOT_FROZEN_BEFORE_PROPOSAL",
        "leave_one_origin_out_rule" => "AGGREGATION_ONLY_NO_RESELECTION",
        "capacity_status" => "DEFERRED_PRE_EVALUATION_FORMULA_GRID_LOCK_REQUIRED",
        "capacity_choice_rule" => "SCORE_FROZEN_CHOICES_ONLY_NO_RESELECTION",
        "capacity_aum_usd" => [1_000_000, 10_000_000, 100_000_000, 1_000_000_000],
        "capacity_participation_cap" => 0.10,
        "proposal_postcompletion_binding_amendment_003_sha256" =>
            _sha256_file(CHAIN_LOCK_PATH),
        "proposal_policy_result_seal_sha256" => _sha256_file(PROPOSAL_RESULT_SEAL_PATH),
        "proposal_robustness_freeze_amendment_004_lock_sha256" =>
            _sha256_file(ACCESS_LOCK_PATH),
        "evaluation_values_inspected" => 0,
        "evaluation_values_materialized" => 0,
        "evaluation_values_used" => 0,
    )
    public_payload = copy(common)
    public_payload["return_values_included"] = false
    public_payload["selected_strategy_identities_included"] = false
    public_payload["public_promotion_permitted"] = true
    public_payload["cells"] = public_cells
    public_text = _toml_text(public_payload)
    _write_new_or_identical(PUBLIC_RESULT_PATH, public_text)
    local_payload = copy(common)
    local_payload["return_values_included"] = false
    local_payload["selected_strategy_identities_included"] = true
    local_payload["public_promotion_permitted"] = false
    local_payload["public_manifest_sha256"] = _sha256_text(public_text)
    local_payload["local_artifact_count"] = length(artifacts)
    local_payload["local_artifact_aggregate_sha256"] = _aggregate(artifacts)
    local_payload["local_artifact_sha256"] = artifacts
    local_payload["cells"] = local_cells
    local_text = _toml_text(local_payload)
    _write_new_or_identical(LOCAL_RESULT_PATH, local_text)
    println("V3_PROPOSAL_ROBUSTNESS_FREEZE_PASSED")
    println("grid choices frozen: 37/38 cells x 24 specs x 2 policies")
    println("cap50/cap100 available: 19/19; cap200 and sham invented: false")
    println("evaluation values inspected/materialized/used: 0")
    return public_payload
end

function audit_proposal_robustness()
    _load_contract()
    public = TOML.parsefile(PUBLIC_RESULT_PATH)
    local_manifest = TOML.parsefile(LOCAL_RESULT_PATH)
    for manifest in (public, local_manifest)
        manifest["status"] == "PROPOSAL_ROBUSTNESS_CHOICES_FROZEN" ||
            error("unexpected proposal robustness status")
        manifest["cell_count"] == 38 || error("robustness cell denominator changed")
        manifest["grid_cell_spec_denominator"] == 912 ||
            error("robustness grid denominator changed")
        manifest["grid_policy_choice_denominator"] == 1_824 ||
            error("robustness choice denominator changed")
        manifest["evaluation_values_inspected"] == 0 || error("evaluation was inspected")
        manifest["evaluation_values_materialized"] == 0 ||
            error("evaluation was materialized")
        manifest["evaluation_values_used"] == 0 || error("evaluation was used")
    end
    public["selected_strategy_identities_included"] === false ||
        error("public robustness manifest contains identities")
    local_manifest["public_manifest_sha256"] == _sha256_file(PUBLIC_RESULT_PATH) ||
        error("public/local robustness manifests are not bound")
    hashes = Dict{String,String}(local_manifest["local_artifact_sha256"])
    length(hashes) == 38 || error("robustness local artifact denominator changed")
    _aggregate(hashes) == local_manifest["local_artifact_aggregate_sha256"] ||
        error("robustness artifact aggregate changed")
    for (relative, digest) in hashes
        _sha256_file(joinpath(EXPERIMENT_ROOT, relative)) == digest ||
            error("proposal robustness artifact changed: $relative")
    end
    println("V3_PROPOSAL_ROBUSTNESS_AUDIT_PASSED")
    println("grid cell-spec denominator: 912; policy choices: 1824")
    println("evaluation values inspected/materialized/used: 0")
    return public
end

function main(args = ARGS)
    length(args) == 1 || error("use exactly one of --run or --audit-only")
    args[1] == "--run" && return run_proposal_robustness()
    args[1] == "--audit-only" && return audit_proposal_robustness()
    error("unknown argument: $(args[1])")
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    RunFinancialStrategyLibraryPanelV3ProposalRobustness.main()
end
