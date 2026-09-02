module FinancialStrategyLibraryPanelV3PredecisionComputation

using SHA: sha256
using StrategyInnovation: ExactRational,
                          JournalCompressionInstance,
                          JournalCompressionProvenance,
                          check_journal_compression_solution,
                          encode_exact_rational,
                          frontier_only_budget_matched_selection,
                          frontier_only_journal_instance,
                          journal_compression_instance_from_components,
                          journal_compression_instance_sha256,
                          retained_capability_ids,
                          solve_journal_compression_mip

include(joinpath(@__DIR__, "FinancialStrategyLibraryPanelV3.jl"))
using .FinancialStrategyLibraryPanelV3: stable_seed

include(joinpath(@__DIR__, "FinancialStrategyLibraryPanelV3Predecision.jl"))
using .FinancialStrategyLibraryPanelV3Predecision: PortfolioSpecification,
                                                   backtest_portfolio_specification,
                                                   capability_ids,
                                                   portfolio_catalog,
                                                   specification_id,
                                                   strategy_burden

export ArmBundle,
       FormationDocket,
       ProfileBundle,
       StrategyPath,
       build_strategy_paths,
       candidate_id,
       certainty_equivalent,
       compression_arms,
       exact_profile_value,
       freeze_source_docket,
       preproposal_trial_rows,
       profile_bundle,
       profile_identifier,
       render_trial_ledger_csv

const PROFILE_SCALE = big(10)^12
const PROFILE_COSTS_BPS = (5, 30)
const PROFILE_RISK_AVERSIONS = (1, 3)
const CASH_ID = "mandatory_inactive_cash"
const EXACT_MIP_BASE_SEED = 310001

"One complete predecision portfolio path without retaining security weights."
struct StrategyPath
    specification::PortfolioSpecification
    strategy_id::String
    gross_returns::Vector{Union{Missing,Float64}}
    turnover::Vector{Float64}
    available::BitVector
end

"A canonical 12-column year-by-cost-by-risk exact operating-profile grid."
struct ProfileBundle
    years::Vector{Int}
    profile_ids::Vector{String}
    costs_bps::Vector{Int}
    risk_aversions::Vector{Int}
    exact_values::Matrix{ExactRational}
    floating_values::Matrix{Float64}
end

"Formation-only source docket, frozen before compression profiles are used."
struct FormationDocket
    selected::BitVector
    selected_strategy_ids::Vector{String}
    frontier_carrier_indices::Vector{Int}
    capability_carrier_indices::Dict{String,Vector{Int}}
    formation_rank_scores::Vector{ExactRational}
    complete_capability_ids::Vector{String}
end

"Exact primary compression endpoints and their nested preproposal action sets."
struct ArmBundle
    instance::JournalCompressionInstance
    frontier_instance::JournalCompressionInstance
    source_selected::BitVector
    safe_result::Any
    frontier_result::Any
    comparator_selected::BitVector
    source_capabilities::Set{String}
    safe_capabilities::Set{String}
    comparator_capabilities::Set{String}
    innovation_strategy_ids::Vector{String}
    source_action_set::Vector{String}
    safe_action_set::Vector{String}
    comparator_action_set::Vector{String}
    compression_rank_scores::Vector{ExactRational}
end

_sha256_text(value) = bytes2hex(sha256(codeunits(String(value))))

function candidate_id(origin_id, universe_id, specification::PortfolioSpecification)
    return join((String(origin_id), String(universe_id), specification_id(specification)), '|')
end

function profile_identifier(year::Integer, cost_bps::Integer, risk_aversion::Integer)
    return "year=$(Int(year))|cost_bps=$(Int(cost_bps))|risk=$(Int(risk_aversion))"
end

"Map a finite profile to the preregistered 10^-12 exact comparison grid."
function exact_profile_value(value::Real)
    converted = Float64(value)
    isfinite(converted) || throw(ArgumentError("an operating profile is nonfinite"))
    numerator_value = round(BigInt, converted * Float64(PROFILE_SCALE))
    return numerator_value // PROFILE_SCALE
end

function certainty_equivalent(
    gross_returns,
    turnover,
    available;
    cost_bps::Real,
    risk_aversion::Real,
    annualization_sessions::Integer = 252,
)
    length(gross_returns) == length(turnover) == length(available) ||
        throw(DimensionMismatch("profile path columns do not align"))
    length(gross_returns) > 1 || throw(ArgumentError("a profile needs at least two sessions"))
    all(available) || throw(ArgumentError("a profile touches an unavailable return"))
    cost = Float64(cost_bps) / 10_000
    risk = Float64(risk_aversion)
    isfinite(cost) && cost >= 0 || throw(ArgumentError("profile cost is invalid"))
    isfinite(risk) && risk >= 0 || throw(ArgumentError("profile risk aversion is invalid"))
    values = Vector{Float64}(undef, length(gross_returns))
    for index in eachindex(gross_returns)
        ismissing(gross_returns[index]) &&
            throw(ArgumentError("an available profile return is missing"))
        values[index] =
            Float64(gross_returns[index]) - cost * Float64(turnover[index])
    end
    all(isfinite, values) || throw(ArgumentError("a net profile return is nonfinite"))
    average = sum(values) / length(values)
    variance = sum((value - average)^2 for value in values) / (length(values) - 1)
    return Int(annualization_sessions) * average -
           0.5 * risk * Int(annualization_sessions) * variance
end

function build_strategy_paths(
    origin_id,
    universe_id,
    security_returns::AbstractMatrix,
    return_available::AbstractMatrix{Bool},
    terminal_delisting::AbstractMatrix{Bool};
    security_weight_cap::Real,
    portfolio_volatility_target::Real = 0.10,
    decision_to_first_return_lag_sessions::Integer = 2,
)
    size(security_returns) == size(return_available) == size(terminal_delisting) ||
        throw(DimensionMismatch("the predecision security panels do not align"))
    paths = StrategyPath[]
    for specification in portfolio_catalog()
        result = backtest_portfolio_specification(
            specification,
            security_returns;
            security_weight_cap,
            portfolio_volatility_target,
            decision_to_first_return_lag_sessions,
            one_way_cost_bps = 0.0,
            return_available,
            terminal_delisting,
        )
        push!(paths, StrategyPath(
            specification,
            candidate_id(origin_id, universe_id, specification),
            result.gross_returns,
            result.turnover,
            BitVector(result.available),
        ))
    end
    issorted(getfield.(paths, :strategy_id)) ||
        error("portfolio path catalog is not in canonical strategy order")
    length(paths) == 96 || error("predecision path catalog is incomplete")
    return paths
end

function profile_bundle(paths, dates, years)
    path_values = StrategyPath[collect(paths)...]
    date_values = String.(collect(dates))
    year_values = sort!(unique(Int.(collect(years))))
    isempty(path_values) && throw(ArgumentError("profile bundle has no strategy paths"))
    length(date_values) == length(first(path_values).gross_returns) ||
        throw(DimensionMismatch("profile calendar does not align with strategy paths"))
    calendar_years = Int[parse(Int, date[1:4]) for date in date_values]
    ids = String[]
    costs = Int[]
    risks = Int[]
    column_years = Int[]
    for year in year_values, cost in PROFILE_COSTS_BPS, risk in PROFILE_RISK_AVERSIONS
        push!(ids, profile_identifier(year, cost, risk))
        push!(column_years, year)
        push!(costs, cost)
        push!(risks, risk)
    end
    floating = Matrix{Float64}(undef, length(path_values), length(ids))
    for (column, (year, cost, risk)) in enumerate(zip(column_years, costs, risks))
        indices = findall(==(year), calendar_years)
        length(indices) > 1 || throw(ArgumentError("profile year $year has insufficient sessions"))
        for (row, path) in enumerate(path_values)
            floating[row, column] = certainty_equivalent(
                path.gross_returns[indices],
                path.turnover[indices],
                path.available[indices];
                cost_bps = cost,
                risk_aversion = risk,
            )
        end
    end
    exact = exact_profile_value.(floating)
    return ProfileBundle(column_years, ids, costs, risks, exact, floating)
end

function _mean_exact(values)
    collected = ExactRational[collect(values)...]
    isempty(collected) && throw(ArgumentError("cannot average an empty exact profile"))
    return sum(collected; init = zero(ExactRational)) / length(collected)
end

function _ranking_columns(bundle::ProfileBundle; cost_bps = 5, risk_aversion = 3)
    result = findall(
        index -> bundle.costs_bps[index] == cost_bps &&
                 bundle.risk_aversions[index] == risk_aversion,
        eachindex(bundle.profile_ids),
    )
    length(result) == length(unique(bundle.years)) ||
        error("the registered ranking profile is incomplete")
    return result
end

function freeze_source_docket(paths, formation::ProfileBundle, universe_id)
    path_values = StrategyPath[collect(paths)...]
    size(formation.exact_values, 1) == length(path_values) ||
        throw(DimensionMismatch("formation profiles do not align with path catalog"))
    selected = falses(length(path_values))
    frontier_carriers = Int[]
    for column in axes(formation.exact_values, 2)
        maximum_value = maximum(@view formation.exact_values[:, column])
        for row in axes(formation.exact_values, 1)
            formation.exact_values[row, column] == maximum_value || continue
            selected[row] = true
            push!(frontier_carriers, row)
        end
    end
    unique!(sort!(frontier_carriers))

    ranking_columns = _ranking_columns(formation)
    ranking_scores = ExactRational[
        _mean_exact(@view formation.exact_values[row, ranking_columns]) for
        row in axes(formation.exact_values, 1)
    ]
    order = sortperm(eachindex(path_values); by = index -> (
        -ranking_scores[index],
        path_values[index].strategy_id,
    ))
    complete_capabilities = sort!(unique(String[
        capability for path in path_values for
        capability in capability_ids(path.specification, universe_id)
    ]))
    length(complete_capabilities) == 31 ||
        error("v3 cell closure does not contain exactly 31 capabilities")
    capability_carriers = Dict{String,Vector{Int}}()
    for capability in complete_capabilities
        carriers = Int[
            index for index in order if
            capability in capability_ids(path_values[index].specification, universe_id)
        ]
        length(carriers) >= 3 || error("capability has fewer than three docket carriers")
        capability_carriers[capability] = carriers[1:3]
        selected[carriers[1:3]] .= true
    end
    selected_ids = sort!(getfield.(path_values[findall(selected)], :strategy_id))
    retained_closure = sort!(unique(String[
        capability for index in findall(selected) for
        capability in capability_ids(path_values[index].specification, universe_id)
    ]))
    retained_closure == complete_capabilities ||
        error("formation docket failed complete capability coverage")
    return FormationDocket(
        selected,
        selected_ids,
        frontier_carriers,
        capability_carriers,
        ranking_scores,
        complete_capabilities,
    )
end

function _compression_instance(
    origin_id,
    universe_id,
    paths,
    docket::FormationDocket,
    compression::ProfileBundle,
)
    path_values = StrategyPath[collect(paths)...]
    selected_indices = findall(docket.selected)
    size(compression.exact_values, 1) == length(path_values) ||
        throw(DimensionMismatch("compression profiles do not align with path catalog"))
    ids = String[CASH_ID; getfield.(path_values[selected_indices], :strategy_id)]
    mandatory = Bool[true; falses(length(selected_indices))]
    weights = Any[0; [
        strategy_burden(path_values[index].specification) for index in selected_indices
    ]...]
    profiles = Matrix{ExactRational}(
        undef,
        length(selected_indices) + 1,
        size(compression.exact_values, 2),
    )
    profiles[1, :] .= zero(ExactRational)
    profiles[2:end, :] .= compression.exact_values[selected_indices, :]
    modules = Vector{Vector{String}}(undef, length(ids))
    modules[1] = String[]
    for (position, index) in enumerate(selected_indices)
        modules[position + 1] = capability_ids(path_values[index].specification, universe_id)
    end
    provenance = JournalCompressionProvenance(
        :financial,
        "$(String(origin_id))|$(String(universe_id))|v3-predecision",
        "sealed v3 formation docket and compression profiles";
        generator = "FinancialStrategyLibraryPanelV3PredecisionComputation",
        attributes = [
            "proposal_information_used" => "false",
            "evaluation_information_used" => "false",
            "profile_exact_grid" => "1e-12",
        ],
        redistributable = false,
    )
    instance = journal_compression_instance_from_components(
        ids,
        mandatory,
        weights,
        compression.profile_ids,
        profiles,
        modules;
        source_closure = docket.complete_capability_ids,
        provenance,
    )
    return instance
end

function _action_set(
    paths,
    docket::FormationDocket,
    retained_capabilities,
    innovation_indices,
    universe_id,
)
    capability_set = Set(String.(collect(retained_capabilities)))
    return sort!(String[
        paths[index].strategy_id for index in innovation_indices if
        issubset(
            Set(capability_ids(paths[index].specification, universe_id)),
            capability_set,
        )
    ])
end

function compression_arms(
    origin_id,
    universe_id,
    paths,
    docket::FormationDocket,
    compression::ProfileBundle,
)
    path_values = StrategyPath[collect(paths)...]
    instance = _compression_instance(
        origin_id,
        universe_id,
        path_values,
        docket,
        compression,
    )
    frontier_instance = frontier_only_journal_instance(instance)
    safe_seed = stable_seed(
        EXACT_MIP_BASE_SEED,
        "exact_mip_solver",
        origin_id,
        universe_id,
        "innovation_safe_exact",
    )
    frontier_seed = stable_seed(
        EXACT_MIP_BASE_SEED,
        "exact_mip_solver",
        origin_id,
        universe_id,
        "frontier_only_exact",
    )
    safe_result = solve_journal_compression_mip(
        instance;
        random_seed = safe_seed,
        exact_crosscheck = :auto,
    )
    frontier_result = solve_journal_compression_mip(
        frontier_instance;
        random_seed = frontier_seed,
        exact_crosscheck = :auto,
    )
    safe_optimal = safe_result.solver_claimed_optimal ||
                   !safe_result.diagnostics.solver_invoked
    frontier_optimal = frontier_result.solver_claimed_optimal ||
                       !frontier_result.diagnostics.solver_invoked
    safe_result.candidate_accepted && safe_optimal ||
        error("safe exact MIP did not return an accepted optimal endpoint")
    frontier_result.candidate_accepted && frontier_optimal ||
        error("frontier exact MIP did not return an accepted optimal endpoint")
    safe_selected = BitVector(safe_result.reconstructed_candidate)
    frontier_selected = BitVector(frontier_result.reconstructed_candidate)
    check_journal_compression_solution(instance, safe_selected).exact_feasible ||
        error("safe MIP endpoint failed independent exact source check")
    check_journal_compression_solution(frontier_instance, frontier_selected).exact_feasible ||
        error("frontier MIP endpoint failed independent exact source check")

    ranking_columns = _ranking_columns(compression)
    path_rank_scores = ExactRational[
        _mean_exact(@view compression.exact_values[row, ranking_columns]) for
        row in axes(compression.exact_values, 1)
    ]
    score_lookup = Dict(
        path.strategy_id => path_rank_scores[index] for
        (index, path) in enumerate(path_values)
    )
    instance_scores = ExactRational[
        String(strategy_id.id) == CASH_ID ? zero(ExactRational) :
        score_lookup[String(strategy_id.id)] for strategy_id in instance.strategy_ids
    ]
    matched = frontier_only_budget_matched_selection(
        instance,
        frontier_selected,
        safe_selected,
        instance_scores,
    )
    comparator_selected = BitVector(matched.selected)
    matched.exact_burden <= matched.exact_burden_cap ||
        error("budget-matched comparator exceeds safe burden")
    check_journal_compression_solution(frontier_instance, comparator_selected).exact_feasible ||
        error("budget-matched comparator lost exact frontier feasibility")

    source_selected = trues(length(instance.strategy_ids))
    source_capabilities = retained_capability_ids(instance, source_selected)
    safe_capabilities = retained_capability_ids(instance, safe_selected)
    comparator_capabilities = retained_capability_ids(instance, comparator_selected)
    innovation_indices = findall(.!docket.selected)
    innovation_ids = sort!(getfield.(path_values[innovation_indices], :strategy_id))
    source_action = _action_set(
        path_values,
        docket,
        source_capabilities,
        innovation_indices,
        universe_id,
    )
    safe_action = _action_set(
        path_values,
        docket,
        safe_capabilities,
        innovation_indices,
        universe_id,
    )
    comparator_action = _action_set(
        path_values,
        docket,
        comparator_capabilities,
        innovation_indices,
        universe_id,
    )
    Set(comparator_action) ⊆ Set(safe_action) ||
        error("comparator action set is not nested inside safe action set")
    Set(safe_action) ⊆ Set(source_action) ||
        error("safe action set is not nested inside source action set")
    safe_capabilities == Set(docket.complete_capability_ids) ||
        error("innovation-safe exact endpoint did not preserve complete closure")
    safe_action == innovation_ids ||
        error("innovation-safe exact endpoint does not generate the complete innovation pool")
    return ArmBundle(
        instance,
        frontier_instance,
        source_selected,
        safe_result,
        frontier_result,
        comparator_selected,
        source_capabilities,
        safe_capabilities,
        comparator_capabilities,
        innovation_ids,
        source_action,
        safe_action,
        comparator_action,
        path_rank_scores,
    )
end

const POLICY_ARM = (
    ("frontier_only_robust_policy", "frontier_only_exact_budget_matched", :comparator, true),
    ("innovation_safe_robust_policy", "innovation_safe_exact", :safe, true),
    ("innovation_safe_forced_max", "innovation_safe_exact", :safe, false),
    ("equal_weight_available_policy", "innovation_safe_exact", :safe, true),
    ("source_uncompressed_robust_policy", "source", :source, true),
)

function preproposal_trial_rows(
    origin_id,
    universe_id,
    paths,
    docket::FormationDocket,
    arms::ArmBundle;
    universe_status::AbstractString = "PASSED",
)
    path_values = StrategyPath[collect(paths)...]
    docket_ids = Set(docket.selected_strategy_ids)
    action_sets = Dict(
        :source => Set(arms.source_action_set),
        :safe => Set(arms.safe_action_set),
        :comparator => Set(arms.comparator_action_set),
    )
    candidate_rows = [(id = CASH_ID, requirements = String[])]
    append!(candidate_rows, [
        (
            id = path.strategy_id,
            requirements = capability_ids(path.specification, universe_id),
        ) for path in path_values
    ])
    rows = Dict{String,Any}[]
    gate_passed = String(universe_status) == "PASSED"
    for (policy_id, arm_id, action_key, cash_included) in POLICY_ARM
        action_set = action_sets[action_key]
        for candidate in candidate_rows
            requirements_hash = _sha256_text(join(sort(candidate.requirements), '\n'))
            is_cash = candidate.id == CASH_ID
            in_docket = candidate.id in docket_ids
            generatable = gate_passed && if is_cash
                cash_included
            elseif in_docket
                false
            else
                candidate.id in action_set
            end
            failure_code = if !gate_passed
                "UNIVERSE_GATE_FAILED"
            elseif is_cash && !cash_included
                "CASH_OMITTED_BY_REGISTERED_NEGATIVE_CONTROL"
            elseif in_docket
                "SOURCE_DOCKET_MEMBER_EXCLUDED_FROM_INNOVATION_POOL"
            elseif !generatable
                "MISSING_RETAINED_CAPABILITY"
            else
                ""
            end
            trial_id = _sha256_text(join((
                origin_id,
                universe_id,
                candidate.id,
                arm_id,
                policy_id,
            ), '\0'))
            record_values = String[
                trial_id,
                String(origin_id),
                String(universe_id),
                candidate.id,
                arm_id,
                policy_id,
                requirements_hash,
                string(generatable),
                failure_code,
                "0",
                "",
                "",
                "false",
                "false",
                "0",
                "",
                "",
                "",
                "",
            ]
            record_hash = _sha256_text(join(record_values, '\0'))
            push!(rows, Dict{String,Any}(
                "trial_id" => trial_id,
                "origin_id" => String(origin_id),
                "universe_id" => String(universe_id),
                "strategy_id" => candidate.id,
                "compression_arm_id" => arm_id,
                "policy_id" => policy_id,
                "requirements_hash" => requirements_hash,
                "generatable" => generatable,
                "failure_code" => failure_code,
                "proposal_observation_count" => 0,
                "proposal_ce" => "",
                "proposal_incremental_lower_bound" => "",
                "policy_eligible" => false,
                "policy_selected" => false,
                "evaluation_observation_count" => 0,
                "evaluation_ce" => "",
                "evaluation_mean_component" => "",
                "evaluation_variance_penalty" => "",
                "evaluation_turnover_cost" => "",
                "record_hash" => record_hash,
            ))
        end
    end
    length(rows) == 5 * (length(path_values) + 1) ||
        error("preproposal trial ledger is incomplete")
    length(unique(row["trial_id"] for row in rows)) == length(rows) ||
        error("preproposal trial identifiers are not unique")
    return rows
end

const TRIAL_LEDGER_FIELDS = (
    "trial_id",
    "origin_id",
    "universe_id",
    "strategy_id",
    "compression_arm_id",
    "policy_id",
    "requirements_hash",
    "generatable",
    "failure_code",
    "proposal_observation_count",
    "proposal_ce",
    "proposal_incremental_lower_bound",
    "policy_eligible",
    "policy_selected",
    "evaluation_observation_count",
    "evaluation_ce",
    "evaluation_mean_component",
    "evaluation_variance_penalty",
    "evaluation_turnover_cost",
    "record_hash",
)

function _csv_field(value)
    text = string(value)
    if occursin(',', text) || occursin('"', text) || occursin('\n', text)
        return "\"$(replace(text, "\"" => "\"\""))\""
    end
    return text
end

function render_trial_ledger_csv(rows)
    io = IOBuffer()
    println(io, join(TRIAL_LEDGER_FIELDS, ','))
    for row in rows
        println(io, join((_csv_field(row[field]) for field in TRIAL_LEDGER_FIELDS), ','))
    end
    return String(take!(io))
end

end # module
