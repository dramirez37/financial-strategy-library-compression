const FINANCIAL_INNOVATION_CHALLENGE_SCHEMA_VERSION =
    "financial-innovation-challenge-v2"

"""A masked, non-source candidate ranked before postdecision data are opened."""
struct FinancialInnovationCandidate
    candidate_id::String
    required_capabilities::Tuple{Vararg{String}}
    predecision_score::ExactRational
    postdecision_score::Union{Missing,ExactRational}

    function FinancialInnovationCandidate(
        candidate_id::AbstractString,
        required_capabilities,
        predecision_score,
        postdecision_score = missing,
    )
        id = strip(String(candidate_id))
        isempty(id) && throw(ArgumentError("challenge candidate identifier cannot be empty"))
        capabilities = sort!(String.(collect(required_capabilities)))
        isempty(capabilities) && throw(
            ArgumentError("challenge candidate must require at least one capability"),
        )
        length(capabilities) == length(unique(capabilities)) || throw(
            ArgumentError("challenge candidate capabilities must be unique"),
        )
        post = ismissing(postdecision_score) ? missing : exact_rational(postdecision_score)
        return new(id, Tuple(capabilities), exact_rational(predecision_score), post)
    end
end

"""One frozen menu. Candidate order is canonical and never carries outcome rank."""
struct FinancialInnovationMenu
    menu_id::String
    candidates::Tuple{Vararg{FinancialInnovationCandidate}}

    function FinancialInnovationMenu(menu_id::AbstractString, candidates)
        id = strip(String(menu_id))
        isempty(id) && throw(ArgumentError("challenge menu identifier cannot be empty"))
        values = FinancialInnovationCandidate[collect(candidates)...]
        isempty(values) && throw(ArgumentError("challenge menu cannot be empty"))
        sort!(values; by = candidate -> candidate.candidate_id)
        ids = getfield.(values, :candidate_id)
        length(ids) == length(unique(ids)) || throw(
            ArgumentError("challenge menu candidate identifiers must be unique"),
        )
        return new(id, Tuple(values))
    end
end

"""
    financial_profile_support(dates, state_by_date; ...)

Check profile support before candidate generation. A failing security can be
excluded without invalidating an otherwise supported origin.
"""
function financial_profile_support(
    dates,
    state_by_date;
    construction_start::AbstractString,
    construction_end::AbstractString,
    compression_start::AbstractString,
    compression_end::AbstractString,
    state_count::Integer = 5,
    minimum_per_state::Integer = 25,
)
    state_count > 0 || throw(ArgumentError("state_count must be positive"))
    minimum_per_state > 0 || throw(
        ArgumentError("minimum_per_state must be positive"),
    )
    values = String.(collect(dates))
    length(values) == length(unique(values)) || throw(
        ArgumentError("profile-support dates must be unique"),
    )
    construction_counts = zeros(Int, state_count)
    compression_counts = zeros(Int, state_count)
    for date in values
        state = get(state_by_date, date, 0)
        0 <= state <= state_count || throw(
            ArgumentError("belief-state map contains an out-of-range state"),
        )
        iszero(state) && continue
        construction_start <= date <= construction_end &&
            (construction_counts[state] += 1)
        compression_start <= date <= compression_end &&
            (compression_counts[state] += 1)
    end
    construction_supported = all(>=(minimum_per_state), construction_counts)
    compression_supported = all(>=(minimum_per_state), compression_counts)
    return (
        supported = construction_supported && compression_supported,
        construction_supported,
        compression_supported,
        construction_counts,
        compression_counts,
        minimum_per_state = Int(minimum_per_state),
    )
end

"""Build the exact frontier-only counterfactual from a safe journal instance."""
function frontier_only_journal_instance(instance::JournalCompressionInstance)
    validate_journal_compression_instance(instance)
    beliefs = [
        requirement.belief.id for requirement in instance.requirements if
        requirement isa FrontierRequirement
    ]
    isempty(beliefs) && error("safe source instance has no frontier requirements")
    provenance = JournalCompressionProvenance(
        :financial,
        "$(instance.provenance.instance_id):frontier-only",
        "frontier-only counterfactual derived before held-out evaluation";
        generator = "financial-strategy-library-panel-v2",
        parent_hashes = [
            "safe_source_instance_sha256" => journal_compression_instance_sha256(instance),
        ],
        attributes = [
            "counterfactual" => "frontier_only",
            "postdecision_information_used" => "false",
        ],
        redistributable = instance.provenance.redistributable,
    )
    return journal_compression_instance_from_components(
        [strategy_id.id for strategy_id in instance.strategy_ids],
        instance.mandatory,
        instance.weights,
        beliefs,
        instance.operating_profiles,
        [String[] for _ in eachindex(instance.strategy_ids)];
        source_frontier = instance.source_frontier,
        source_closure = String[],
        tie_handling = instance.tie_handling,
        provenance,
    )
end

"""Return the exact capability identifiers carried by a selected library."""
function retained_capability_ids(
    instance::JournalCompressionInstance,
    selected::AbstractVector{Bool},
)
    validate_journal_compression_instance(instance)
    length(selected) == length(instance.strategy_ids) || throw(
        DimensionMismatch("selection does not align with the financial source instance"),
    )
    capabilities = Set{String}()
    for index in eachindex(selected)
        selected[index] || continue
        for module_id in instance.strategy_modules[index]
            push!(capabilities, string(module_id.id))
        end
    end
    return capabilities
end

"""
    frontier_only_budget_matched_selection(...)

Augment a certified frontier-only endpoint in frozen predecision-score order.
Every whole strategy that fits is added; no menu or held-out field is accepted.
"""
function frontier_only_budget_matched_selection(
    safe_instance::JournalCompressionInstance,
    frontier_selected::AbstractVector{Bool},
    safe_selected::AbstractVector{Bool},
    predecision_scores::AbstractVector,
)
    validate_journal_compression_instance(safe_instance)
    n = length(safe_instance.strategy_ids)
    length(frontier_selected) == n || throw(DimensionMismatch("frontier selection length"))
    length(safe_selected) == n || throw(DimensionMismatch("safe selection length"))
    length(predecision_scores) == n || throw(DimensionMismatch("predecision score length"))
    frontier_instance = frontier_only_journal_instance(safe_instance)
    frontier_check = check_journal_compression_solution(
        frontier_instance,
        BitVector(frontier_selected),
    )
    frontier_check.exact_feasible || throw(
        ArgumentError("budget matching requires an exactly feasible frontier endpoint"),
    )
    safe_check = check_journal_compression_solution(
        safe_instance,
        BitVector(safe_selected),
    )
    safe_check.exact_feasible || throw(
        ArgumentError("budget matching requires an exactly feasible safe endpoint"),
    )
    selected = BitVector(frontier_selected)
    burden = frontier_check.exact_burden
    cap = safe_check.exact_burden
    burden <= cap || throw(
        ArgumentError("frontier-only optimum exceeds the safe exact burden cap"),
    )
    scores = ExactRational[exact_rational(value) for value in predecision_scores]
    candidates = Int[
        index for index in eachindex(selected) if
        !selected[index] && !safe_instance.mandatory[index]
    ]
    sort!(candidates; by = index -> (-scores[index], string(safe_instance.strategy_ids[index].id)))
    additions = Int[]
    for index in candidates
        candidate_burden = burden + safe_instance.weights[index]
        candidate_burden <= cap || continue
        selected[index] = true
        burden = candidate_burden
        push!(additions, index)
    end
    matched_check = check_journal_compression_solution(frontier_instance, selected)
    matched_check.exact_feasible || error("budget-matched endpoint lost frontier feasibility")
    burden == matched_check.exact_burden || error("budget-matched burden did not reconcile")
    return (
        selected,
        exact_burden = burden,
        exact_burden_cap = cap,
        additions,
        closure_recovered = retained_capability_ids(safe_instance, selected) ==
                            Set(string(module_id.id) for module_id in safe_instance.source_closure),
    )
end

"""Select one innovation candidate using capabilities and predecision rank only."""
function select_financial_innovation_candidate(
    menu::FinancialInnovationMenu,
    retained_capabilities,
)
    capability_set = Set(String.(collect(retained_capabilities)))
    ordered = sort(
        collect(menu.candidates);
        by = candidate -> (-candidate.predecision_score, candidate.candidate_id),
    )
    for (rank, candidate) in enumerate(ordered)
        issubset(Set(candidate.required_capabilities), capability_set) || continue
        return (
            schema_version = FINANCIAL_INNOVATION_CHALLENGE_SCHEMA_VERSION,
            menu_id = menu.menu_id,
            candidate_id = candidate.candidate_id,
            predecision_rank = rank,
            used_cash_fallback = false,
            postdecision_available = !ismissing(candidate.postdecision_score),
            postdecision_score = candidate.postdecision_score,
            reason = ismissing(candidate.postdecision_score) ?
                     "selected_candidate_postdecision_score_unavailable" : "",
        )
    end
    return (
        schema_version = FINANCIAL_INNOVATION_CHALLENGE_SCHEMA_VERSION,
        menu_id = menu.menu_id,
        candidate_id = "mandatory_inactive_cash",
        predecision_rank = missing,
        used_cash_fallback = true,
        postdecision_available = true,
        postdecision_score = zero(ExactRational),
        reason = "no_generatable_candidate",
    )
end

"""Compute the registered paired menu contrast without replacing missing choices."""
function paired_financial_innovation_contrast(safe_choice, comparator_choice)
    safe_choice.menu_id == comparator_choice.menu_id || throw(
        ArgumentError("paired innovation choices come from different menus"),
    )
    available = safe_choice.postdecision_available &&
                comparator_choice.postdecision_available
    value = available ?
            safe_choice.postdecision_score - comparator_choice.postdecision_score : missing
    return (
        menu_id = safe_choice.menu_id,
        available,
        heldout_innovation_utility_delta = value,
        safe_candidate_id = safe_choice.candidate_id,
        comparator_candidate_id = comparator_choice.candidate_id,
        same_candidate = safe_choice.candidate_id == comparator_choice.candidate_id,
        reason = available ? "" : "one_or_both_frozen_candidate_outcomes_unavailable",
    )
end

"""
    full_calendar_postdecision_utility(...)

Align observations to the registered reference calendar. Zero returns are
inserted only after an explicit delisting date, representing cash after the
observed delisting transition; other missing dates make the score unavailable.
"""
function full_calendar_postdecision_utility(
    expected_dates,
    observed_dates,
    net_returns;
    explicit_delisting_date = nothing,
    annualization_sessions::Integer = 252,
    risk_aversion::Real = 3,
    minimum_sessions::Integer = 100,
)
    calendar = String.(collect(expected_dates))
    dates = String.(collect(observed_dates))
    values = collect(net_returns)
    length(dates) == length(values) || throw(
        DimensionMismatch("postdecision dates and returns do not align"),
    )
    length(calendar) == length(unique(calendar)) || throw(
        ArgumentError("expected postdecision calendar contains duplicate dates"),
    )
    length(dates) == length(unique(dates)) || throw(
        ArgumentError("observed postdecision dates contain duplicate dates"),
    )
    issorted(calendar) || throw(ArgumentError("expected postdecision calendar is not sorted"))
    issorted(dates) || throw(ArgumentError("observed postdecision dates are not sorted"))
    annualization_sessions > 0 || throw(
        ArgumentError("annualization_sessions must be positive"),
    )
    minimum_sessions > 1 || throw(ArgumentError("minimum_sessions must exceed one"))
    risk = Float64(risk_aversion)
    isfinite(risk) && risk >= 0 || throw(
        ArgumentError("risk_aversion must be finite and nonnegative"),
    )
    observed = Dict{String,Float64}()
    expected = Set(calendar)
    all(in(expected), dates) || throw(
        ArgumentError("observed postdecision dates fall outside the registered calendar"),
    )
    delisting = isnothing(explicit_delisting_date) ? nothing : String(explicit_delisting_date)
    if !isnothing(delisting)
        delisting in dates || throw(
            ArgumentError("explicit delisting requires an observed delisting-return row"),
        )
        all(date <= delisting for date in dates) || throw(
            ArgumentError("observed returns continue after the explicit delisting date"),
        )
    end
    for (date, value) in zip(dates, values)
        ismissing(value) && return (
            available = false,
            score = missing,
            reason = "observed_return_is_missing",
            observed_sessions = length(observed),
            cash_sessions = 0,
        )
        number = Float64(value)
        isfinite(number) && number > -1 || throw(
            ArgumentError("postdecision net returns must be finite and compoundable"),
        )
        observed[date] = number
    end
    aligned = Float64[]
    cash_sessions = 0
    for date in calendar
        if haskey(observed, date)
            push!(aligned, observed[date])
        elseif !isnothing(delisting) && date > delisting
            push!(aligned, 0.0)
            cash_sessions += 1
        else
            return (
                available = false,
                score = missing,
                reason = "calendar_return_unavailable_without_cash_transition",
                observed_sessions = length(observed),
                cash_sessions,
            )
        end
    end
    length(aligned) >= minimum_sessions || return (
        available = false,
        score = missing,
        reason = "too_few_full_calendar_sessions",
        observed_sessions = length(observed),
        cash_sessions,
    )
    mean_return = sum(aligned) / length(aligned)
    centered_squares = sum((value - mean_return)^2 for value in aligned)
    sample_variance = centered_squares / (length(aligned) - 1)
    score = annualization_sessions * mean_return -
            0.5 * risk * annualization_sessions * sample_variance
    return (
        available = true,
        score,
        reason = "",
        observed_sessions = length(observed),
        cash_sessions,
    )
end
