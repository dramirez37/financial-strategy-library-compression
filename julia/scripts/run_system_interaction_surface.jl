module SystemInteractionExperiment

using StrategyInnovation
using TOML

export main,
    render_system_interaction_fixtures_csv,
    render_system_interaction_response_csv,
    render_system_interaction_csv,
    render_system_interaction_summary,
    run_system_interaction_surface,
    run_system_interaction_surface_from_config,
    write_system_interaction_outputs

const EXPERIMENT_ID = "system-interaction-surface-v2"
const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG =
    joinpath(REPOSITORY_ROOT, "experiments", "configs", "system_interaction_surface.toml")

_ratio(value::Rational) = "$(numerator(value))//$(denominator(value))"

function _exact_grid(numerators, denominator)
    denominator > 0 || throw(ArgumentError("grid denominator must be positive"))
    return ExactRational[
        ExactRational(numerator, denominator) for numerator in numerators
    ]
end

function _find_row(rows; kwargs...)
    index = findfirst(rows) do row
        all(getproperty(row, key) == value for (key, value) in kwargs)
    end
    index === nothing && error("missing system-interaction witness row: $kwargs")
    return rows[index]
end

function _premium(discount, frontier, success, cost, candidate)
    return max(
        zero(discount),
        discount * success * max(candidate - frontier, zero(discount)) - cost,
    )
end

_action(label, intercept, exposure) = (
    label = String(label),
    intercept = ExactRational(intercept),
    exposure = ExactRational(exposure),
)

function _select_corner(reward, gap, actions)
    isempty(actions) && throw(ArgumentError("an action menu must be nonempty"))
    selected = first(actions)
    selected_net = selected.intercept + selected.exposure * gap
    for action in Iterators.drop(actions, 1)
        candidate_net = action.intercept + action.exposure * gap
        if candidate_net > selected_net
            selected = action
            selected_net = candidate_net
        end
    end
    return (
        value = reward + selected_net,
        net_value = selected_net,
        selected_project = selected.label,
    )
end

function _menu_included(poor_actions, rich_actions)
    return all(
        poor -> any(rich -> rich == poor, rich_actions),
        poor_actions,
    )
end

_interaction_classification(interaction) =
    interaction < 0 ? :substitutes :
    interaction > 0 ? :complements : :separable

function _rectangle_row(;
    fixture_id,
    mechanism,
    discount,
    frontier0,
    frontier1,
    closure_richness,
    project_cost,
    admission0,
    admission1,
    descendant0,
    descendant1,
    incumbent_reward0,
    incumbent_reward1,
    duration,
    generator_quality_dependence,
    gap0,
    gap1,
    poor_actions0,
    rich_actions0,
    poor_actions1,
    rich_actions1,
    frontier_independent_generator,
)
    frontier0 <= frontier1 ||
        throw(ArgumentError("the low frontier must not exceed the high frontier"))
    duration >= 1 || throw(ArgumentError("project duration must be positive"))
    closure_richness >= 1 ||
        throw(ArgumentError("closure richness must be positive"))

    low_poor = _select_corner(incumbent_reward0, gap0, poor_actions0)
    low_rich = _select_corner(incumbent_reward0, gap0, rich_actions0)
    high_poor = _select_corner(incumbent_reward1, gap1, poor_actions1)
    high_rich = _select_corner(incumbent_reward1, gap1, rich_actions1)

    closure_increment0 = low_rich.value - low_poor.value
    closure_increment1 = high_rich.value - high_poor.value
    interaction = closure_increment1 - closure_increment0
    classification = _interaction_classification(interaction)

    realizable_low_poor = frontier0 == incumbent_reward0
    realizable_low_rich = frontier0 == incumbent_reward0
    realizable_high_poor = frontier1 == incumbent_reward1
    realizable_high_rich = frontier1 == incumbent_reward1
    all_corners_realizable =
        realizable_low_poor && realizable_low_rich &&
        realizable_high_poor && realizable_high_rich

    menus_frontier_independent =
        poor_actions0 == poor_actions1 && rich_actions0 == rich_actions1
    menu_inclusion =
        _menu_included(poor_actions0, rich_actions0) &&
        _menu_included(poor_actions1, rich_actions1)
    gap_antitone = gap1 <= gap0
    rich_nonnegative_exposure =
        all(action -> action.exposure >= 0, rich_actions0) &&
        all(action -> action.exposure >= 0, rich_actions1)
    poor_zero_exposure =
        all(action -> iszero(action.exposure), poor_actions0) &&
        all(action -> iszero(action.exposure), poor_actions1)
    primitive_sufficient_conditions_hold =
        all_corners_realizable &&
        frontier_independent_generator &&
        menus_frontier_independent &&
        menu_inclusion &&
        gap_antitone &&
        rich_nonnegative_exposure &&
        poor_zero_exposure

    return (;
        fixture_id,
        mechanism,
        discount,
        frontier0,
        frontier1,
        closure_richness,
        project_cost,
        admission0,
        admission1,
        descendant0,
        descendant1,
        incumbent_reward0,
        incumbent_reward1,
        duration,
        generator_quality_dependence,
        gap0,
        gap1,
        value_low_poor = low_poor.value,
        value_low_rich = low_rich.value,
        value_high_poor = high_poor.value,
        value_high_rich = high_rich.value,
        closure_increment0,
        closure_increment1,
        interaction,
        classification,
        selected_low_poor = low_poor.selected_project,
        selected_low_rich = low_rich.selected_project,
        selected_high_poor = high_poor.selected_project,
        selected_high_rich = high_rich.selected_project,
        realizable_low_poor,
        realizable_low_rich,
        realizable_high_poor,
        realizable_high_rich,
        all_corners_realizable,
        sign_aggregation_eligible = all_corners_realizable,
        frontier_independent_generator,
        menus_frontier_independent,
        menu_inclusion,
        gap_antitone,
        rich_nonnegative_exposure,
        poor_zero_exposure,
        primitive_sufficient_conditions_hold,
    )
end

function _exact_fixture_rows(discount::ExactRational)
    continue_action = _action("Continue", 0 // 1, 0 // 1)

    primitive_action = _action("Added-1", 0 // 1, discount)
    primitive = _rectangle_row(;
        fixture_id = "primitive_strict_substitution",
        mechanism = "fixed-generator common-gap exposure",
        discount,
        frontier0 = ExactRational(0),
        frontier1 = ExactRational(2),
        closure_richness = 1,
        project_cost = ExactRational(0),
        admission0 = ExactRational(1),
        admission1 = ExactRational(1),
        descendant0 = ExactRational(4),
        descendant1 = ExactRational(4),
        incumbent_reward0 = ExactRational(0),
        incumbent_reward1 = ExactRational(2),
        duration = 1,
        generator_quality_dependence = ExactRational(0),
        gap0 = ExactRational(4),
        gap1 = ExactRational(2),
        poor_actions0 = (continue_action,),
        rich_actions0 = (continue_action, primitive_action),
        poor_actions1 = (continue_action,),
        rich_actions1 = (continue_action, primitive_action),
        frontier_independent_generator = true,
    )

    saturated_action = _action("Added-1", 0 // 1, discount)
    saturation = _rectangle_row(;
        fixture_id = "saturation_boundary",
        mechanism = "positive-part gap saturated at both frontiers",
        discount,
        frontier0 = ExactRational(4),
        frontier1 = ExactRational(6),
        closure_richness = 1,
        project_cost = ExactRational(0),
        admission0 = ExactRational(1),
        admission1 = ExactRational(1),
        descendant0 = ExactRational(4),
        descendant1 = ExactRational(4),
        incumbent_reward0 = ExactRational(4),
        incumbent_reward1 = ExactRational(6),
        duration = 1,
        generator_quality_dependence = ExactRational(0),
        gap0 = ExactRational(0),
        gap1 = ExactRational(0),
        poor_actions0 = (continue_action,),
        rich_actions0 = (continue_action, saturated_action),
        poor_actions1 = (continue_action,),
        rich_actions1 = (continue_action, saturated_action),
        frontier_independent_generator = true,
    )

    old_action = _action("Old", -2 // 1, discount)
    switching_action = _action("Added-1", 0 // 1, discount / 2)
    optimizer_switch = _rectangle_row(;
        fixture_id = "optimizer_switching_complementarity",
        mechanism = "frontier-independent project switching",
        discount,
        frontier0 = ExactRational(0),
        frontier1 = ExactRational(8),
        closure_richness = 1,
        project_cost = ExactRational(0),
        admission0 = ExactRational(1 // 2),
        admission1 = ExactRational(1 // 2),
        descendant0 = ExactRational(10),
        descendant1 = ExactRational(10),
        incumbent_reward0 = ExactRational(0),
        incumbent_reward1 = ExactRational(8),
        duration = 1,
        generator_quality_dependence = ExactRational(0),
        gap0 = ExactRational(10),
        gap1 = ExactRational(2),
        poor_actions0 = (continue_action, old_action),
        rich_actions0 = (continue_action, old_action, switching_action),
        poor_actions1 = (continue_action, old_action),
        rich_actions1 = (continue_action, old_action, switching_action),
        frontier_independent_generator = true,
    )

    dependent_low_action = _action("Added-1", 0 // 1, 0 // 1)
    dependent_high_action = _action("Added-1", 0 // 1, discount)
    dependent_success = _rectangle_row(;
        fixture_id = "frontier_dependent_success_complementarity",
        mechanism = "candidate success rises with the frontier",
        discount,
        frontier0 = ExactRational(0),
        frontier1 = ExactRational(1),
        closure_richness = 1,
        project_cost = ExactRational(0),
        admission0 = ExactRational(0),
        admission1 = ExactRational(1),
        descendant0 = ExactRational(2),
        descendant1 = ExactRational(2),
        incumbent_reward0 = ExactRational(0),
        incumbent_reward1 = ExactRational(1),
        duration = 1,
        generator_quality_dependence = ExactRational(1),
        gap0 = ExactRational(2),
        gap1 = ExactRational(1),
        poor_actions0 = (continue_action,),
        rich_actions0 = (continue_action, dependent_low_action),
        poor_actions1 = (continue_action,),
        rich_actions1 = (continue_action, dependent_high_action),
        frontier_independent_generator = false,
    )

    separable_action = _action("Added-1", 3 // 2, 0 // 1)
    separable = _rectangle_row(;
        fixture_id = "separable_zero_interaction",
        mechanism = "frontier-additive closure intercept",
        discount,
        frontier0 = ExactRational(0),
        frontier1 = ExactRational(8),
        closure_richness = 1,
        project_cost = ExactRational(0),
        admission0 = ExactRational(0),
        admission1 = ExactRational(0),
        descendant0 = ExactRational(0),
        descendant1 = ExactRational(0),
        incumbent_reward0 = ExactRational(0),
        incumbent_reward1 = ExactRational(8),
        duration = 1,
        generator_quality_dependence = ExactRational(0),
        gap0 = ExactRational(0),
        gap1 = ExactRational(0),
        poor_actions0 = (continue_action,),
        rich_actions0 = (continue_action, separable_action),
        poor_actions1 = (continue_action,),
        rich_actions1 = (continue_action, separable_action),
        frontier_independent_generator = true,
    )

    return [primitive, saturation, optimizer_switch, dependent_success, separable]
end

function _strict_pairs(values)
    return [
        (low, high) for low in values for high in values if low < high
    ]
end

function _expanded_response_surface(;
    discount::ExactRational,
    frontiers,
    closure_richness_levels,
    project_costs,
    admission_probabilities,
    descendant_payoffs,
    incumbent_operating_rewards,
    durations,
    generator_quality_dependence,
)
    all(duration -> duration >= 1, durations) ||
        throw(ArgumentError("all project durations must be positive"))
    all(level -> level in (1, 2), closure_richness_levels) ||
        throw(ArgumentError("closure richness must be one or two"))
    all(probability -> 0 <= probability <= 1, admission_probabilities) ||
        throw(ArgumentError("admission probabilities must lie in [0, 1]"))
    all(>=(zero(ExactRational)), project_costs) ||
        throw(ArgumentError("project costs must be nonnegative"))

    frontier_pairs = _strict_pairs(frontiers)
    reward_pairs = _strict_pairs(incumbent_operating_rewards)
    isempty(frontier_pairs) &&
        throw(ArgumentError("the frontier grid has no strict ordered pair"))
    isempty(reward_pairs) &&
        throw(ArgumentError("the operating-reward grid has no strict ordered pair"))

    rows = NamedTuple[]
    continue_action = _action("Continue", 0 // 1, 0 // 1)
    for (frontier0, frontier1) in frontier_pairs,
        (reward0, reward1) in reward_pairs,
        closure_richness in closure_richness_levels,
        project_cost in project_costs,
        admission in admission_probabilities,
        descendant0 in descendant_payoffs,
        duration in durations,
        dependence in generator_quality_dependence

        descendant1 =
            descendant0 + dependence * (frontier1 - frontier0)
        gap0 = max(descendant0 - frontier0, zero(ExactRational))
        gap1 = max(descendant1 - frontier1, zero(ExactRational))
        exposure = discount^duration * admission
        project1 = _action("Added-1", -project_cost, exposure)
        project2 = _action("Added-2", 0 // 1, exposure / 2)
        rich_actions = closure_richness == 1 ?
                       (continue_action, project1) :
                       (continue_action, project1, project2)

        push!(
            rows,
            _rectangle_row(;
                fixture_id = "",
                mechanism = "expanded fixed-continuation response surface",
                discount,
                frontier0,
                frontier1,
                closure_richness,
                project_cost,
                admission0 = admission,
                admission1 = admission,
                descendant0,
                descendant1,
                incumbent_reward0 = reward0,
                incumbent_reward1 = reward1,
                duration,
                generator_quality_dependence = dependence,
                gap0,
                gap1,
                poor_actions0 = (continue_action,),
                rich_actions0 = rich_actions,
                poor_actions1 = (continue_action,),
                rich_actions1 = rich_actions,
                frontier_independent_generator = iszero(dependence),
            ),
        )
    end
    return rows
end

function _response_counts(rows)
    eligible = filter(row -> row.sign_aggregation_eligible, rows)
    primitive = filter(row -> row.primitive_sufficient_conditions_hold, rows)
    return (
        total_rows = length(rows),
        realizable_rectangles = length(eligible),
        excluded_nonrealizable_rectangles = length(rows) - length(eligible),
        eligible_substitutes =
            count(row -> row.classification == :substitutes, eligible),
        eligible_complements =
            count(row -> row.classification == :complements, eligible),
        eligible_separable =
            count(row -> row.classification == :separable, eligible),
        primitive_rows = length(primitive),
        primitive_positive_interactions =
            count(row -> row.interaction > 0, primitive),
    )
end

"""
    run_system_interaction_surface(; ...)

Preserve the registered exact frontier-pair grid, add five canonical
four-corner fixtures, and evaluate an expanded response surface over closure
richness, project primitives, incumbent rewards, durations, and generator
quality dependence. Interaction signs on the expanded surface are aggregated
only for rectangles whose four compressed corners are jointly realizable.
"""
function run_system_interaction_surface(;
    frontiers = ExactRational[0, 2, 4, 6, 8, 10],
    candidates = ExactRational[4, 10],
    successes = ExactRational[0, 1 // 2, 1],
    costs = ExactRational[0, 1, 2],
    discount::ExactRational = ExactRational(1 // 2),
    include_equal_frontiers::Bool = false,
    response_frontiers = ExactRational[0, 2, 4, 8],
    closure_richness_levels = [1, 2],
    response_project_costs = ExactRational[0, 1],
    admission_probabilities = ExactRational[1 // 2, 1],
    descendant_payoffs = ExactRational[4, 10],
    incumbent_operating_rewards = ExactRational[0, 2, 4, 8],
    durations = [1, 2],
    generator_quality_dependence = ExactRational[0, 1, 2],
)
    rows = frontier_closure_interaction_surface(
        frontiers,
        candidates,
        successes,
        successes,
        costs,
        costs;
        discount,
        include_equal_frontiers,
    )
    isempty(rows) && error("the system-interaction grid produced no rows")

    substitution = _find_row(
        rows;
        frontier0 = ExactRational(0),
        frontier1 = ExactRational(2),
        candidate = ExactRational(4),
        old_success = ExactRational(0),
        added_success = ExactRational(1),
        old_cost = ExactRational(0),
        added_cost = ExactRational(0),
    )
    independent_switch = _find_row(
        rows;
        frontier0 = ExactRational(0),
        frontier1 = ExactRational(8),
        candidate = ExactRational(10),
        old_success = ExactRational(1),
        added_success = ExactRational(1 // 2),
        old_cost = ExactRational(2),
        added_cost = ExactRational(0),
    )

    dependent_value = (frontier, rich) ->
        frontier + (
            rich ?
            _premium(discount, frontier, frontier, ExactRational(0), ExactRational(2)) :
            ExactRational(0)
        )
    dependent_interaction = interaction_cross_difference(
        dependent_value,
        ExactRational(1),
        ExactRational(0),
        true,
        false,
    )
    separable_value = (frontier, rich) ->
        frontier + (rich ? ExactRational(3 // 2) : ExactRational(0))
    separable_interaction = interaction_cross_difference(
        separable_value,
        ExactRational(8),
        ExactRational(0),
        true,
        false,
    )

    fixtures = _exact_fixture_rows(discount)
    response_rows = _expanded_response_surface(
        ;
        discount,
        frontiers = response_frontiers,
        closure_richness_levels,
        project_costs = response_project_costs,
        admission_probabilities,
        descendant_payoffs,
        incumbent_operating_rewards,
        durations,
        generator_quality_dependence,
    )
    response_counts = _response_counts(response_rows)
    fixture_by_id = Dict(row.fixture_id => row for row in fixtures)

    counts = (
        substitutes = count(row -> row.classification == :substitutes, rows),
        complements = count(row -> row.classification == :complements, rows),
        separable = count(row -> row.classification == :separable, rows),
    )
    checks = (
        row_count = length(rows) == 2430,
        all_exact = all(
            row ->
                row.interaction isa ExactRational &&
                row.closure_increment0 isa ExactRational &&
                row.closure_increment1 isa ExactRational,
            rows,
        ),
        all_three_fixed_primitive_signs =
            counts.substitutes > 0 && counts.complements > 0 &&
            counts.separable > 0,
        substitution_matches_lean =
            substitution.closure_increment0 == 2 &&
            substitution.closure_increment1 == 1 &&
            substitution.interaction == -1,
        independent_switch_matches_lean =
            independent_switch.closure_increment0 == 0 &&
            independent_switch.closure_increment1 == 1 // 2 &&
            independent_switch.interaction == 1 // 2,
        dependent_success_matches_lean = dependent_interaction == 1 // 2,
        separable_matches_lean = separable_interaction == 0,
        five_exact_fixtures =
            length(fixtures) == 5 &&
            fixture_by_id["primitive_strict_substitution"].interaction < 0 &&
            fixture_by_id["saturation_boundary"].interaction == 0 &&
            fixture_by_id["optimizer_switching_complementarity"].interaction > 0 &&
            fixture_by_id[
                "frontier_dependent_success_complementarity"
            ].interaction > 0 &&
            fixture_by_id["separable_zero_interaction"].interaction == 0,
        fixture_corner_policies_complete = all(
            row ->
                !isempty(row.selected_low_poor) &&
                !isempty(row.selected_low_rich) &&
                !isempty(row.selected_high_poor) &&
                !isempty(row.selected_high_rich),
            fixtures,
        ),
        fixture_realizability_complete =
            all(row -> row.all_corners_realizable, fixtures),
        response_row_count = response_counts.total_rows == 3456,
        response_realizability_partition =
            response_counts.realizable_rectangles == 576 &&
            response_counts.excluded_nonrealizable_rectangles == 2880,
        response_sign_counts_conditioned_on_realizability =
            response_counts.eligible_substitutes +
            response_counts.eligible_complements +
            response_counts.eligible_separable ==
            response_counts.realizable_rectangles,
        nonrealizable_rows_excluded_from_sign_aggregation = all(
            row ->
                row.sign_aggregation_eligible == row.all_corners_realizable,
            response_rows,
        ),
        primitive_response_rows_nonpositive =
            response_counts.primitive_rows > 0 &&
            response_counts.primitive_positive_interactions == 0,
        response_reports_all_requested_fields = all(
            row ->
                row.interaction isa ExactRational &&
                row.closure_increment0 isa ExactRational &&
                row.closure_increment1 isa ExactRational &&
                row.duration isa Int &&
                row.closure_richness isa Int,
            response_rows,
        ),
    )
    all(values(checks)) || error("system-interaction response checks failed")

    return (
        experiment_id = EXPERIMENT_ID,
        arithmetic = "Rational{BigInt}",
        randomness = "none",
        model =
            "legacy two-project grid plus realizability-gated fixed-continuation response",
        frontiers = collect(frontiers),
        candidates = collect(candidates),
        successes = collect(successes),
        costs = collect(costs),
        discount,
        include_equal_frontiers,
        rows,
        counts,
        fixtures,
        response_rows,
        response_counts,
        response_axes = (
            frontiers = collect(response_frontiers),
            closure_richness = collect(closure_richness_levels),
            project_costs = collect(response_project_costs),
            admission_probabilities = collect(admission_probabilities),
            descendant_payoffs = collect(descendant_payoffs),
            incumbent_operating_rewards = collect(incumbent_operating_rewards),
            durations = collect(durations),
            generator_quality_dependence =
                collect(generator_quality_dependence),
        ),
        witnesses = (
            substitution,
            independent_switch,
            dependent_success_interaction = dependent_interaction,
            separable_interaction,
        ),
        checks,
    )
end

function run_system_interaction_surface_from_config(
    path::AbstractString = DEFAULT_CONFIG,
)
    config = TOML.parsefile(path)
    grid = config["grid"]
    model = config["model"]
    response = config["response"]
    return run_system_interaction_surface(
        frontiers = _exact_grid(
            grid["frontier_numerators"],
            grid["frontier_denominator"],
        ),
        candidates = _exact_grid(
            grid["candidate_numerators"],
            grid["candidate_denominator"],
        ),
        successes = _exact_grid(
            grid["success_numerators"],
            grid["success_denominator"],
        ),
        costs = _exact_grid(
            grid["cost_numerators"],
            grid["cost_denominator"],
        ),
        discount = ExactRational(
            model["discount_numerator"],
            model["discount_denominator"],
        ),
        include_equal_frontiers = grid["include_equal_frontiers"],
        response_frontiers = _exact_grid(
            response["frontier_numerators"],
            response["frontier_denominator"],
        ),
        closure_richness_levels = Int.(response["closure_richness"]),
        response_project_costs = _exact_grid(
            response["project_cost_numerators"],
            response["project_cost_denominator"],
        ),
        admission_probabilities = _exact_grid(
            response["admission_numerators"],
            response["admission_denominator"],
        ),
        descendant_payoffs = _exact_grid(
            response["descendant_payoff_numerators"],
            response["descendant_payoff_denominator"],
        ),
        incumbent_operating_rewards = _exact_grid(
            response["incumbent_reward_numerators"],
            response["incumbent_reward_denominator"],
        ),
        durations = Int.(response["durations"]),
        generator_quality_dependence = _exact_grid(
            response["generator_dependence_numerators"],
            response["generator_dependence_denominator"],
        ),
    )
end

function render_system_interaction_csv(result)
    io = IOBuffer()
    println(
        io,
        "discount,frontier0,frontier1,candidate,old_success,added_success," *
        "old_cost,added_cost,old_premium0,old_premium1,added_premium0," *
        "added_premium1,closure_increment0,closure_increment1,interaction," *
        "classification",
    )
    for row in result.rows
        println(
            io,
            join(
                (
                    _ratio(row.discount),
                    _ratio(row.frontier0),
                    _ratio(row.frontier1),
                    _ratio(row.candidate),
                    _ratio(row.old_success),
                    _ratio(row.added_success),
                    _ratio(row.old_cost),
                    _ratio(row.added_cost),
                    _ratio(row.old_premium0),
                    _ratio(row.old_premium1),
                    _ratio(row.added_premium0),
                    _ratio(row.added_premium1),
                    _ratio(row.closure_increment0),
                    _ratio(row.closure_increment1),
                    _ratio(row.interaction),
                    row.classification,
                ),
                ",",
            ),
        )
    end
    return String(take!(io))
end

function _render_rectangle_rows(rows)
    io = IOBuffer()
    println(
        io,
        "fixture_id,mechanism,discount,frontier_low,frontier_high," *
        "closure_richness,project_cost,admission_low,admission_high," *
        "descendant_payoff_low,descendant_payoff_high," *
        "incumbent_operating_reward_low,incumbent_operating_reward_high," *
        "project_duration,generator_quality_frontier_dependence,gap_low," *
        "gap_high,value_low_poor,value_low_rich,value_high_poor," *
        "value_high_rich,closure_increment_low,closure_increment_high," *
        "cross_difference_J,interaction_sign,selected_low_poor," *
        "selected_low_rich,selected_high_poor,selected_high_rich," *
        "realizable_low_poor,realizable_low_rich,realizable_high_poor," *
        "realizable_high_rich,all_corners_realizable," *
        "sign_aggregation_eligible,frontier_independent_generator," *
        "menus_frontier_independent,menu_inclusion,gap_antitone," *
        "rich_nonnegative_exposure,poor_zero_exposure," *
        "primitive_sufficient_conditions_hold",
    )
    for row in rows
        println(
            io,
            join(
                (
                    row.fixture_id,
                    row.mechanism,
                    _ratio(row.discount),
                    _ratio(row.frontier0),
                    _ratio(row.frontier1),
                    row.closure_richness,
                    _ratio(row.project_cost),
                    _ratio(row.admission0),
                    _ratio(row.admission1),
                    _ratio(row.descendant0),
                    _ratio(row.descendant1),
                    _ratio(row.incumbent_reward0),
                    _ratio(row.incumbent_reward1),
                    row.duration,
                    _ratio(row.generator_quality_dependence),
                    _ratio(row.gap0),
                    _ratio(row.gap1),
                    _ratio(row.value_low_poor),
                    _ratio(row.value_low_rich),
                    _ratio(row.value_high_poor),
                    _ratio(row.value_high_rich),
                    _ratio(row.closure_increment0),
                    _ratio(row.closure_increment1),
                    _ratio(row.interaction),
                    row.classification,
                    row.selected_low_poor,
                    row.selected_low_rich,
                    row.selected_high_poor,
                    row.selected_high_rich,
                    row.realizable_low_poor,
                    row.realizable_low_rich,
                    row.realizable_high_poor,
                    row.realizable_high_rich,
                    row.all_corners_realizable,
                    row.sign_aggregation_eligible,
                    row.frontier_independent_generator,
                    row.menus_frontier_independent,
                    row.menu_inclusion,
                    row.gap_antitone,
                    row.rich_nonnegative_exposure,
                    row.poor_zero_exposure,
                    row.primitive_sufficient_conditions_hold,
                ),
                ",",
            ),
        )
    end
    return String(take!(io))
end

render_system_interaction_fixtures_csv(result) =
    _render_rectangle_rows(result.fixtures)

render_system_interaction_response_csv(result) =
    _render_rectangle_rows(result.response_rows)

function render_system_interaction_summary(result)
    io = IOBuffer()
    println(io, "{")
    println(io, "  \"arithmetic\": \"$(result.arithmetic)\",")
    println(io, "  \"checks\": {")
    check_keys = collect(keys(result.checks))
    for (index, key) in enumerate(check_keys)
        comma = index == length(check_keys) ? "" : ","
        println(io, "    \"$key\": $(getproperty(result.checks, key))$comma")
    end
    println(io, "  },")
    println(io, "  \"classification_counts\": {")
    println(io, "    \"complements\": $(result.counts.complements),")
    println(io, "    \"separable\": $(result.counts.separable),")
    println(io, "    \"substitutes\": $(result.counts.substitutes)")
    println(io, "  },")
    println(io, "  \"exact_fixtures\": {")
    for (index, row) in enumerate(result.fixtures)
        comma = index == length(result.fixtures) ? "" : ","
        println(io, "    \"$(row.fixture_id)\": {")
        println(
            io,
            "      \"closure_increment_high\": " *
            "\"$(_ratio(row.closure_increment1))\",",
        )
        println(
            io,
            "      \"closure_increment_low\": " *
            "\"$(_ratio(row.closure_increment0))\",",
        )
        println(
            io,
            "      \"cross_difference_J\": \"$(_ratio(row.interaction))\",",
        )
        println(
            io,
            "      \"primitive_sufficient_conditions_hold\": " *
            "$(row.primitive_sufficient_conditions_hold),",
        )
        println(
            io,
            "      \"selected_projects\": [" *
            "\"$(row.selected_low_poor)\", " *
            "\"$(row.selected_low_rich)\", " *
            "\"$(row.selected_high_poor)\", " *
            "\"$(row.selected_high_rich)\"],",
        )
        println(
            io,
            "      \"all_corners_realizable\": $(row.all_corners_realizable)",
        )
        println(io, "    }$comma")
    end
    println(io, "  },")
    println(io, "  \"experiment_id\": \"$(result.experiment_id)\",")
    println(
        io,
        "  \"legacy_grid_realizability\": " *
        "\"all rows set incumbent operating reward equal to the reported frontier\",",
    )
    println(io, "  \"model\": \"$(result.model)\",")
    println(io, "  \"randomness\": \"$(result.randomness)\",")
    println(io, "  \"row_count\": $(length(result.rows)),")
    println(io, "  \"expanded_response\": {")
    println(
        io,
        "    \"aggregation_rule\": " *
        "\"interaction signs are counted only when all four corners are realizable\",",
    )
    println(
        io,
        "    \"excluded_nonrealizable_rectangles\": " *
        "$(result.response_counts.excluded_nonrealizable_rectangles),",
    )
    println(
        io,
        "    \"realizable_interaction_counts\": {",
    )
    println(
        io,
        "      \"complements\": $(result.response_counts.eligible_complements),",
    )
    println(
        io,
        "      \"separable\": $(result.response_counts.eligible_separable),",
    )
    println(
        io,
        "      \"substitutes\": $(result.response_counts.eligible_substitutes)",
    )
    println(io, "    },")
    println(
        io,
        "    \"realizable_rectangles\": " *
        "$(result.response_counts.realizable_rectangles),",
    )
    println(
        io,
        "    \"realizability_rule\": " *
        "\"each reported frontier equals its constructed incumbent operating reward\",",
    )
    println(
        io,
        "    \"primitive_positive_interactions\": " *
        "$(result.response_counts.primitive_positive_interactions),",
    )
    println(
        io,
        "    \"primitive_rows\": $(result.response_counts.primitive_rows),",
    )
    println(io, "    \"total_rows\": $(result.response_counts.total_rows)")
    println(io, "  },")
    println(io, "  \"witnesses\": {")
    println(
        io,
        "    \"dependent_success_interaction\": " *
        "\"$(_ratio(result.witnesses.dependent_success_interaction))\",",
    )
    println(
        io,
        "    \"independent_switch_interaction\": " *
        "\"$(_ratio(result.witnesses.independent_switch.interaction))\",",
    )
    println(
        io,
        "    \"separable_interaction\": " *
        "\"$(_ratio(result.witnesses.separable_interaction))\",",
    )
    println(
        io,
        "    \"substitution_interaction\": " *
        "\"$(_ratio(result.witnesses.substitution.interaction))\"",
    )
    println(io, "  }")
    println(io, "}")
    return String(take!(io))
end

function write_system_interaction_outputs(
    result;
    output_dir = joinpath(REPOSITORY_ROOT, "experiments", "results", "summaries"),
)
    mkpath(output_dir)
    csv_path = joinpath(output_dir, "system_interaction_surface.csv")
    fixtures_path =
        joinpath(output_dir, "system_interaction_exact_fixtures.csv")
    response_path =
        joinpath(output_dir, "system_interaction_response_surface.csv")
    summary_path = joinpath(output_dir, "system_interaction_summary.json")
    write(csv_path, render_system_interaction_csv(result))
    write(fixtures_path, render_system_interaction_fixtures_csv(result))
    write(response_path, render_system_interaction_response_csv(result))
    write(summary_path, render_system_interaction_summary(result))
    return (
        csv = csv_path,
        fixtures = fixtures_path,
        response = response_path,
        summary = summary_path,
    )
end

function _configured_output_paths(config_path)
    config = TOML.parsefile(config_path)
    outputs = config["outputs"]
    return (
        csv = joinpath(REPOSITORY_ROOT, outputs["response_surface"]),
        fixtures = joinpath(REPOSITORY_ROOT, outputs["exact_fixtures"]),
        response = joinpath(REPOSITORY_ROOT, outputs["expanded_response_surface"]),
        summary = joinpath(REPOSITORY_ROOT, outputs["summary"]),
    )
end

function main(args = ARGS)
    all(argument -> argument == "--check", args) ||
        throw(ArgumentError("usage: run_system_interaction_surface.jl [--check]"))
    check_only = "--check" in args
    config_path = DEFAULT_CONFIG
    result = run_system_interaction_surface_from_config(config_path)
    paths = _configured_output_paths(config_path)
    rendered = (
        csv = render_system_interaction_csv(result),
        fixtures = render_system_interaction_fixtures_csv(result),
        response = render_system_interaction_response_csv(result),
        summary = render_system_interaction_summary(result),
    )
    if check_only
        for key in keys(paths)
            path = getproperty(paths, key)
            isfile(path) || error("missing registered output: $path")
            read(path, String) == getproperty(rendered, key) ||
                error("registered output drift: $path")
        end
        println("System-interaction response outputs are current.")
    else
        mkpath(dirname(paths.csv))
        for key in keys(paths)
            path = getproperty(paths, key)
            write(path, getproperty(rendered, key))
            println("Wrote $path")
        end
    end
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
