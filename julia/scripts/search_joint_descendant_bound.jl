module JointDescendantBoundGauntlet

using StrategyInnovation: ExactRational
using TOML

export DEFAULT_CONFIG,
    joint_bound,
    joint_bound_with_harm,
    main,
    render_counterexamples,
    render_summary,
    run_joint_descendant_gauntlet,
    run_joint_descendant_gauntlet_from_config,
    write_outputs

const EXPERIMENT_ID = "joint-descendant-bound-gauntlet-v1"
const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "joint_descendant_bound_gauntlet.toml",
)

_ratio(value::Rational) = "$(numerator(value))//$(denominator(value))"

function _parse_ratio(value::AbstractString)
    pieces = split(value, "//"; limit = 2)
    length(pieces) == 2 ||
        throw(ArgumentError("expected exact ratio numerator//denominator"))
    denominator = parse(BigInt, pieces[2])
    denominator > 0 || throw(ArgumentError("ratio denominator must be positive"))
    return ExactRational(parse(BigInt, pieces[1]), denominator)
end

function _weak_compositions(total::Int, parts::Int)
    total >= 0 || throw(ArgumentError("composition total must be nonnegative"))
    parts >= 1 || throw(ArgumentError("composition must have at least one part"))
    rows = Vector{Vector{Int}}()
    current = zeros(Int, parts)
    function visit(position::Int, remaining::Int)
        if position == parts
            current[position] = remaining
            push!(rows, copy(current))
            return
        end
        for amount in 0:remaining
            current[position] = amount
            visit(position + 1, remaining - amount)
        end
    end
    visit(1, total)
    return rows
end

function _joint_laws(units::Int, belief_count::Int, outcome_count::Int)
    units >= 1 || throw(ArgumentError("joint-mass units must be positive"))
    return [
        reshape(
            ExactRational[
                ExactRational(mass, units) for mass in composition
            ],
            belief_count,
            outcome_count,
        ) for composition in
        _weak_compositions(units, belief_count * outcome_count)
    ]
end

function _weighted_sum(joint::AbstractMatrix{T}, gains::AbstractMatrix{T}) where {T}
    size(joint) == size(gains) ||
        throw(DimensionMismatch("joint law and gain table must have the same size"))
    return sum(joint .* gains; init = zero(T))
end

function _event_gain(
    joint::AbstractMatrix{T},
    outcome::Int,
    gain::AbstractVector{T},
) where {T}
    size(joint, 1) == length(gain) ||
        throw(DimensionMismatch("event gain has the wrong belief count"))
    1 <= outcome <= size(joint, 2) ||
        throw(BoundsError(joint, (:, outcome)))
    return sum(joint[:, outcome] .* gain; init = zero(T))
end

function _premium(
    discount::T,
    duration::Int,
    cost::T,
    operating_adjustment::T,
    expected_continuation_gain::T,
) where {T<:Real}
    return max(
        -cost + operating_adjustment +
        discount^duration * expected_continuation_gain,
        zero(T),
    )
end

"""
    joint_bound(discount, duration, cost, operating_adjustment, joint, g, G)

Evaluate the proposed single-distinguished-event lower bound from the exact
joint terminal-belief/outcome law. `g` is the distinguished outcome column.
"""
function joint_bound(
    discount::T,
    duration::Int,
    cost::T,
    operating_adjustment::T,
    joint::AbstractMatrix{T},
    distinguished::Int,
    gain_floor::AbstractVector{T},
) where {T<:Real}
    duration > 0 || throw(ArgumentError("duration must be positive"))
    zero(T) <= discount <= one(T) ||
        throw(ArgumentError("discount must lie in [0, 1]"))
    cost >= zero(T) || throw(ArgumentError("cost must be nonnegative"))
    all(>=(zero(T)), joint) || throw(ArgumentError("joint masses must be nonnegative"))
    sum(joint; init = zero(T)) == one(T) ||
        throw(ArgumentError("joint masses must sum to one"))
    all(>=(zero(T)), gain_floor) ||
        throw(ArgumentError("gain floor must be nonnegative"))
    success_gain = _event_gain(joint, distinguished, gain_floor)
    return _premium(
        discount,
        duration,
        cost,
        operating_adjustment,
        success_gain,
    )
end

"""
    joint_bound_with_harm(..., harm)

Evaluate the joint bound after subtracting the declared expected harmful
omitted-outcome correction.
"""
function joint_bound_with_harm(
    discount::T,
    duration::Int,
    cost::T,
    operating_adjustment::T,
    joint::AbstractMatrix{T},
    distinguished::Int,
    gain_floor::AbstractVector{T},
    harm_floor::AbstractMatrix{T},
) where {T<:Real}
    size(joint) == size(harm_floor) ||
        throw(DimensionMismatch("harm floor has the wrong shape"))
    all(>=(zero(T)), harm_floor) ||
        throw(ArgumentError("harm floor must be nonnegative"))
    harm = sum(
        joint[belief, outcome] * harm_floor[belief, outcome] for
        belief in axes(joint, 1), outcome in axes(joint, 2) if
        outcome != distinguished;
        init = zero(T),
    )
    success_gain = _event_gain(joint, distinguished, gain_floor)
    return _premium(
        discount,
        duration,
        cost,
        operating_adjustment,
        success_gain - harm,
    )
end

function _product_event_gain(
    joint::AbstractMatrix{T},
    distinguished::Int,
    gain::AbstractVector{T},
) where {T}
    terminal = vec(sum(joint; dims = 2))
    event_mass = sum(joint[:, distinguished]; init = zero(T))
    return event_mass * sum(terminal .* gain; init = zero(T))
end

function _event_independent(
    joint::AbstractMatrix{T},
    distinguished::Int,
) where {T}
    terminal = vec(sum(joint; dims = 2))
    event_mass = sum(joint[:, distinguished]; init = zero(T))
    return all(
        joint[belief, distinguished] == terminal[belief] * event_mass for
        belief in axes(joint, 1)
    )
end

function _gain_tables(grid, belief_count::Int, outcome_count::Int)
    return (
        reshape(collect(values), belief_count, outcome_count) for
        values in Iterators.product(
            ntuple(_ -> grid, belief_count * outcome_count)...,
        )
    )
end

function _floor_vectors(grid, upper::AbstractVector)
    belief_count = length(upper)
    return (
        collect(values) for values in
        Iterators.product(ntuple(_ -> grid, belief_count)...) if
        all(values[index] <= upper[index] for index in 1:belief_count)
    )
end

function _run_primary_search(
    laws,
    discounts,
    durations,
    costs,
    operating_adjustments,
    gains,
    distinguished::Int,
    other_descendant::Int,
)
    single_checks = 0
    single_failures = 0
    multiple_checks = 0
    multiple_failures = 0
    correlated_checks = 0
    correlated_failures = 0
    negative_adjustment_checks = 0
    negative_adjustment_failures = 0

    belief_count = size(first(laws), 1)
    outcome_count = size(first(laws), 2)
    for joint in laws
        correlated = !_event_independent(joint, distinguished)
        for continuation_gain in
            _gain_tables(gains, belief_count, outcome_count)
            expected_gain = _weighted_sum(joint, continuation_gain)
            for gain_floor in
                _floor_vectors(gains, continuation_gain[:, distinguished])
                for discount in discounts,
                    duration in durations,
                    cost in costs,
                    operating_adjustment in operating_adjustments

                    actual = _premium(
                        discount,
                        duration,
                        cost,
                        operating_adjustment,
                        expected_gain,
                    )
                    bound = joint_bound(
                        discount,
                        duration,
                        cost,
                        operating_adjustment,
                        joint,
                        distinguished,
                        gain_floor,
                    )
                    single_checks += 1
                    bound <= actual || (single_failures += 1)

                    if correlated
                        correlated_checks += 1
                        bound <= actual || (correlated_failures += 1)
                    end
                    if operating_adjustment < 0
                        negative_adjustment_checks += 1
                        bound <= actual || (negative_adjustment_failures += 1)
                    end

                    multiple_gain =
                        _event_gain(
                            joint,
                            distinguished,
                            continuation_gain[:, distinguished],
                        ) +
                        _event_gain(
                            joint,
                            other_descendant,
                            continuation_gain[:, other_descendant],
                        )
                    multiple_bound = _premium(
                        discount,
                        duration,
                        cost,
                        operating_adjustment,
                        multiple_gain,
                    )
                    multiple_checks += 1
                    multiple_bound <= actual || (multiple_failures += 1)
                end
            end
        end
    end
    return (;
        single_checks,
        single_failures,
        multiple_checks,
        multiple_failures,
        correlated_checks,
        correlated_failures,
        negative_adjustment_checks,
        negative_adjustment_failures,
    )
end

function _run_harm_search(
    laws,
    discounts,
    costs,
    operating_adjustments,
    nonnegative_gains,
    signed_gains,
    distinguished::Int,
)
    corrected_checks = 0
    corrected_failures = 0
    naive_failures = 0
    harmful_rows = 0
    belief_count = size(first(laws), 1)
    outcome_count = size(first(laws), 2)

    for joint in laws
        for continuation_gain in
            _gain_tables(signed_gains, belief_count, outcome_count)
            all(>=(zero(ExactRational)), continuation_gain[:, distinguished]) ||
                continue
            harm_floor = max.(-continuation_gain, zero(ExactRational))
            has_harm = any(
                continuation_gain[belief, outcome] < 0 &&
                joint[belief, outcome] > 0 for belief in 1:belief_count,
                outcome in 1:outcome_count if outcome != distinguished
            )
            has_harm || continue
            harmful_rows += 1
            expected_gain = _weighted_sum(joint, continuation_gain)
            for gain_floor in _floor_vectors(
                nonnegative_gains,
                continuation_gain[:, distinguished],
            )
                for discount in discounts,
                    cost in costs,
                    operating_adjustment in operating_adjustments

                    actual = _premium(
                        discount,
                        1,
                        cost,
                        operating_adjustment,
                        expected_gain,
                    )
                    naive = joint_bound(
                        discount,
                        1,
                        cost,
                        operating_adjustment,
                        joint,
                        distinguished,
                        gain_floor,
                    )
                    corrected = joint_bound_with_harm(
                        discount,
                        1,
                        cost,
                        operating_adjustment,
                        joint,
                        distinguished,
                        gain_floor,
                        harm_floor,
                    )
                    corrected_checks += 1
                    corrected <= actual || (corrected_failures += 1)
                    naive > actual && (naive_failures += 1)
                end
            end
        end
    end
    return (;
        harmful_rows,
        corrected_checks,
        corrected_failures,
        naive_failures,
    )
end

function _run_comparator_search(comparator_premia, project_values)
    corrected_checks = 0
    corrected_failures = 0
    naive_failures = 0
    enabled_both_zero_comparator_checks = 0
    enabled_both_zero_comparator_failures = 0
    for poor_premium in comparator_premia, project_bound in project_values
        rich_premium = max(poor_premium, project_bound)
        actual_delta = rich_premium - poor_premium
        naive = project_bound
        corrected = project_bound - poor_premium
        corrected_checks += 1
        corrected <= actual_delta || (corrected_failures += 1)
        naive > actual_delta && (naive_failures += 1)
        if iszero(poor_premium)
            enabled_both_zero_comparator_checks += 1
            naive <= actual_delta ||
                (enabled_both_zero_comparator_failures += 1)
        end
    end
    return (;
        corrected_checks,
        corrected_failures,
        naive_failures,
        enabled_both_zero_comparator_checks,
        enabled_both_zero_comparator_failures,
    )
end

function _fixture(
    id,
    channel,
    classification,
    actual,
    attacked_bound,
    revised_bound,
    missing_assumption,
    revision;
    detail = "",
)
    return (;
        id,
        channel,
        classification,
        actual,
        attacked_bound,
        revised_bound,
        missing_assumption,
        revision,
        detail,
    )
end

function _minimal_fixtures()
    half = ExactRational(1 // 2)
    zeroq = zero(ExactRational)
    oneq = one(ExactRational)

    harmful_joint = ExactRational[0 1 // 2 1 // 2]
    harmful_continuation = ExactRational[0 2 -2]
    harmful_actual = _premium(
        half,
        1,
        zeroq,
        zeroq,
        _weighted_sum(harmful_joint, harmful_continuation),
    )
    harmful_attacked =
        joint_bound(half, 1, zeroq, zeroq, harmful_joint, 2, ExactRational[2])
    harmful_revised = joint_bound_with_harm(
        half,
        1,
        zeroq,
        zeroq,
        harmful_joint,
        2,
        ExactRational[2],
        ExactRational[0 0 2],
    )
    harmful = _fixture(
        "CX-T6-JOINT-HARMFUL-NONG-01",
        "harmful_non_g_outcome",
        "counterexample",
        harmful_actual,
        harmful_attacked,
        harmful_revised,
        "nonnegative omitted outcomes",
        "subtract the expected harmful-outcome correction",
        detail = "one belief; masses g=1/2, r=1/2; gains 2 and -2",
    )

    certain_g = ExactRational[0 1 0]
    negative_adjustment_actual = _premium(half, 1, zeroq, -half, oneq)
    negative_adjustment_attacked =
        joint_bound(half, 1, zeroq, zeroq, certain_g, 2, ExactRational[1])
    negative_adjustment_revised =
        joint_bound(half, 1, zeroq, -half, certain_g, 2, ExactRational[1])
    negative_adjustment = _fixture(
        "CX-T6-JOINT-OPERATING-ADJUSTMENT-01",
        "negative_operating_adjustment",
        "counterexample_to_omitting_adjustment",
        negative_adjustment_actual,
        negative_adjustment_attacked,
        negative_adjustment_revised,
        "the exact operating adjustment must be retained",
        "use Aop=-1/2 rather than silently setting Aop=0",
        detail = "one belief; g certain; G=1; beta=1/2; Aop=-1/2",
    )

    common_project_premium = _premium(half, 1, zeroq, zeroq, ExactRational(2))
    enabled_both_actual = common_project_premium - common_project_premium
    enabled_both_revised =
        common_project_premium - common_project_premium
    enabled_both = _fixture(
        "CX-T6-JOINT-ENABLED-BOTH-01",
        "project_enabled_in_both_libraries",
        "counterexample",
        enabled_both_actual,
        common_project_premium,
        enabled_both_revised,
        "project unavailable without insertion, or zero comparator premium",
        "retain post-insertion-only enablement and the zero-premium comparator",
        detail = "one belief; the same unit-premium project is feasible on both sides",
    )

    old_project_premium = _premium(half, 1, zeroq, zeroq, ExactRational(2))
    new_project_certificate = _premium(half, 1, zeroq, zeroq, ExactRational(2))
    rich_premium = max(old_project_premium, new_project_certificate)
    positive_comparator_actual = rich_premium - old_project_premium
    positive_comparator_revised =
        new_project_certificate - old_project_premium
    positive_comparator = _fixture(
        "CX-T6-JOINT-POSITIVE-COMPARATOR-01",
        "positive_comparator_premium",
        "counterexample",
        positive_comparator_actual,
        new_project_certificate,
        positive_comparator_revised,
        "deleted comparator has zero research-option premium",
        "otherwise subtract the comparator premium from the project certificate",
        detail = "q is new with premium 1; a retained old project already has premium 1",
    )

    path_masses = ExactRational[half, half]
    path_gains = ExactRational[0, 2]
    path_actual =
        _premium(half, 1, zeroq, zeroq, sum(path_masses .* path_gains))
    invalid_terminal_floor = ExactRational(2)
    path_attacked = _premium(
        half,
        1,
        zeroq,
        zeroq,
        sum(path_masses) * invalid_terminal_floor,
    )
    path_revised =
        _premium(half, 1, zeroq, zeroq, sum(path_masses .* path_gains))
    path_dependent = _fixture(
        "CX-T6-JOINT-PATH-FLOOR-01",
        "full_path_dependent_gain",
        "counterexample",
        path_actual,
        path_attacked,
        path_revised,
        "G(b') is a supportwise floor over every success path ending at b'",
        "use path-level joint masses and floors, or take the terminal-path minimum",
        detail = "two equiprobable g paths share one terminal belief; gains 0 and 2",
    )

    direct_gain = ExactRational(2)
    displaced_menu_gain = ExactRational(-4)
    complete_gain = direct_gain + displaced_menu_gain
    menu_displacement_actual =
        _premium(half, 1, zeroq, zeroq, complete_gain)
    menu_displacement_attacked =
        joint_bound(half, 1, zeroq, zeroq, certain_g, 2, [direct_gain])
    menu_displacement_revised =
        joint_bound(half, 1, zeroq, zeroq, certain_g, 2, ExactRational[0])
    menu_displacement = _fixture(
        "CX-T6-JOINT-MENU-DISPLACEMENT-01",
        "admission_changes_future_menus",
        "counterexample",
        menu_displacement_actual,
        menu_displacement_attacked,
        menu_displacement_revised,
        "G lower-bounds complete continuation gain, including menu changes",
        "do not substitute a direct operating gain for the complete continuation floor",
        detail = "g has direct gain 2 but removes a future option worth 4",
    )

    short_horizon_actual = zeroq
    short_horizon_attacked = joint_bound(
        half,
        2,
        zeroq,
        zeroq,
        certain_g,
        2,
        ExactRational[4],
    )
    short_horizon_revised = zeroq
    short_horizon = _fixture(
        "CX-T6-JOINT-HORIZON-01",
        "horizon_shorter_than_duration",
        "counterexample",
        short_horizon_actual,
        short_horizon_attacked,
        short_horizon_revised,
        "project duration fits the remaining horizon",
        "require d<=h before using the committed-project comparison",
        detail = "h=1; d=2; beta=1/2; g certain; G=4",
    )

    negatively_correlated_joint = ExactRational[0 half 0; half 0 0]
    correlated_gain = ExactRational[0, 2]
    correlation_actual = _premium(half, 1, zeroq, zeroq, zeroq)
    correlation_attacked = _premium(
        half,
        1,
        zeroq,
        zeroq,
        _product_event_gain(negatively_correlated_joint, 2, correlated_gain),
    )
    correlation_revised = joint_bound(
        half,
        1,
        zeroq,
        zeroq,
        negatively_correlated_joint,
        2,
        correlated_gain,
    )
    correlation = _fixture(
        "CX-T6-JOINT-PRODUCT-SHORTCUT-01",
        "correlated_admission_and_terminal_belief",
        "counterexample_to_product_shortcut",
        correlation_actual,
        correlation_attacked,
        correlation_revised,
        "event-specific terminal independence for the product formula",
        "use eta directly; reserve pi*rho^d*mu for the independence corollary",
        detail = "terminal marginals 1/2,1/2; g occurs only at zero-gain belief",
    )

    multiple_joint = ExactRational[0 half half]
    multiple_continuation = ExactRational[0 2 4]
    multiple_actual = _premium(
        half,
        1,
        zeroq,
        zeroq,
        _weighted_sum(multiple_joint, multiple_continuation),
    )
    multiple_attacked =
        joint_bound(half, 1, zeroq, zeroq, multiple_joint, 2, ExactRational[2])
    multiple_revised = _premium(
        half,
        1,
        zeroq,
        zeroq,
        _event_gain(multiple_joint, 2, ExactRational[2]) +
        _event_gain(multiple_joint, 3, ExactRational[4]),
    )
    multiple = _fixture(
        "FX-T6-JOINT-MULTIPLE-DESCENDANTS-01",
        "multiple_descendants",
        "survives",
        multiple_actual,
        multiple_attacked,
        multiple_revised,
        "none beyond distinct outcome events and nonnegative omitted gains",
        "single-g bound remains valid; disjoint descendant events may be summed",
        detail = "one belief; masses g=1/2,r=1/2; gains 2 and 4; beta=1/2",
    )

    positively_correlated_joint = ExactRational[half 0 0; 0 half 0]
    correlated_survivor_actual = _premium(
        oneq,
        1,
        zeroq,
        zeroq,
        _event_gain(positively_correlated_joint, 2, correlated_gain),
    )
    correlated_survivor_bound = joint_bound(
        oneq,
        1,
        zeroq,
        zeroq,
        positively_correlated_joint,
        2,
        correlated_gain,
    )
    correlated_survivor = _fixture(
        "FX-T6-JOINT-CORRELATED-01",
        "correlated_admission_and_terminal_belief",
        "survives_joint_bound",
        correlated_survivor_actual,
        correlated_survivor_bound,
        correlated_survivor_bound,
        "none for the joint-law theorem",
        "retain the non-product eta term",
        detail = "terminal marginals 1/2,1/2; g occurs only at gain-2 belief",
    )

    enabled_both_zero_poor = zeroq
    enabled_both_zero_rich =
        _premium(half, 1, zeroq, zeroq, ExactRational(2))
    enabled_both_zero_actual =
        enabled_both_zero_rich - enabled_both_zero_poor
    enabled_both_zero = _fixture(
        "FX-T6-JOINT-ENABLED-BOTH-ZERO-PREMIUM-01",
        "project_enabled_in_both_libraries",
        "survives_with_zero_comparator",
        enabled_both_zero_actual,
        enabled_both_zero_rich,
        enabled_both_zero_rich,
        "post-insertion-only enablement is mechanism-facing, not sign-bearing once comparator premium is zero",
        "retain the condition for the carrier interpretation",
        detail = "q is feasible on both sides but has zero poor-library premium",
    )

    menu_expansion_complete_gain = direct_gain + ExactRational(2)
    menu_expansion_actual =
        _premium(half, 1, zeroq, zeroq, menu_expansion_complete_gain)
    menu_expansion_bound =
        joint_bound(half, 1, zeroq, zeroq, certain_g, 2, [direct_gain])
    menu_expansion = _fixture(
        "FX-T6-JOINT-MENU-EXPANSION-01",
        "admission_changes_future_menus",
        "survives",
        menu_expansion_actual,
        menu_expansion_bound,
        menu_expansion_bound,
        "none when G is a lower bound on the complete continuation gain",
        "positive menu effects may be omitted from a lower bound",
        detail = "g direct gain 2 plus an additional future-menu gain 2",
    )
    return [
        harmful,
        negative_adjustment,
        enabled_both,
        positive_comparator,
        path_dependent,
        menu_displacement,
        short_horizon,
        correlation,
        multiple,
        correlated_survivor,
        enabled_both_zero,
        menu_expansion,
    ]
end

function run_joint_descendant_gauntlet(;
    joint_mass_units::Int = 2,
    belief_count::Int = 2,
    outcome_count::Int = 3,
    discounts = ExactRational[0, 1 // 2, 3 // 4],
    durations = [1, 2],
    costs = ExactRational[0, 1],
    operating_adjustments = ExactRational[-1, 0, 1],
    nonnegative_gains = ExactRational[0, 1, 2],
    signed_gains = ExactRational[-2, 0, 2],
    comparator_premia = ExactRational[0, 1, 2],
    failure::Int = 1,
    distinguished::Int = 2,
    other_descendant::Int = 3,
)
    outcome_count == 3 ||
        throw(ArgumentError("the registered gauntlet uses exactly three outcomes"))
    sort([failure, distinguished, other_descendant]) == collect(1:outcome_count) ||
        throw(ArgumentError("outcome indices must be a permutation of 1:3"))
    laws = _joint_laws(joint_mass_units, belief_count, outcome_count)
    primary = _run_primary_search(
        laws,
        discounts,
        durations,
        costs,
        operating_adjustments,
        nonnegative_gains,
        distinguished,
        other_descendant,
    )
    harm = _run_harm_search(
        laws,
        discounts,
        costs,
        operating_adjustments,
        nonnegative_gains,
        signed_gains,
        distinguished,
    )
    comparator = _run_comparator_search(
        comparator_premia,
        nonnegative_gains,
    )
    fixtures = _minimal_fixtures()
    checks = (
        primary_joint_bound_survives = primary.single_failures == 0,
        correlated_joint_bound_survives =
            primary.correlated_checks > 0 &&
            primary.correlated_failures == 0,
        negative_adjustment_survives_when_included =
            primary.negative_adjustment_checks > 0 &&
            primary.negative_adjustment_failures == 0,
        multiple_descendant_sum_survives =
            primary.multiple_failures == 0,
        harmful_naive_bound_falsified = harm.naive_failures > 0,
        harmful_corrected_bound_survives =
            harm.corrected_failures == 0,
        positive_comparator_naive_bound_falsified =
            comparator.naive_failures > 0,
        comparator_corrected_bound_survives =
            comparator.corrected_failures == 0,
        enabled_both_zero_comparator_survives =
            comparator.enabled_both_zero_comparator_failures == 0,
        every_requested_channel_preserved =
            length(unique(fixture.channel for fixture in fixtures)) == 9,
        every_counterexample_has_revision = all(
            !isempty(fixture.missing_assumption) && !isempty(fixture.revision) for
            fixture in fixtures if occursin("counterexample", fixture.classification)
        ),
    )
    all(values(checks)) ||
        error("joint descendant-bound gauntlet failed its registered checks: $checks")

    counts = (;
        joint_laws = length(laws),
        correlated_joint_laws =
            count(law -> !_event_independent(law, distinguished), laws),
        primary...,
        harmful_rows = harm.harmful_rows,
        harmful_corrected_checks = harm.corrected_checks,
        harmful_corrected_failures = harm.corrected_failures,
        harmful_naive_failures = harm.naive_failures,
        comparator_corrected_checks = comparator.corrected_checks,
        comparator_corrected_failures = comparator.corrected_failures,
        comparator_naive_failures = comparator.naive_failures,
        enabled_both_zero_comparator_checks =
            comparator.enabled_both_zero_comparator_checks,
        enabled_both_zero_comparator_failures =
            comparator.enabled_both_zero_comparator_failures,
        preserved_fixtures = length(fixtures),
        counterexample_fixtures =
            count(fixture -> occursin("counterexample", fixture.classification), fixtures),
        survivor_fixtures =
            count(fixture -> occursin("survive", fixture.classification), fixtures),
    )
    return (;
        experiment_id = EXPERIMENT_ID,
        arithmetic = "Rational{BigInt}",
        randomness = "none",
        model = "exact one-project Bellman subclass with joint terminal belief/outcome law",
        grid = (;
            joint_mass_units,
            belief_count,
            outcome_count,
            discounts,
            durations,
            costs,
            operating_adjustments,
            nonnegative_gains,
            signed_gains,
            comparator_premia,
        ),
        counts,
        checks,
        fixtures,
        lean_gate_open = all(values(checks)),
    )
end

function run_joint_descendant_gauntlet_from_config(
    path::AbstractString = DEFAULT_CONFIG,
)
    config = TOML.parsefile(path)
    grid = config["grid"]
    outcomes = config["outcomes"]
    parse_grid(name) = ExactRational[_parse_ratio(value) for value in grid[name]]
    return run_joint_descendant_gauntlet(
        joint_mass_units = grid["joint_mass_units"],
        belief_count = grid["belief_count"],
        outcome_count = grid["outcome_count"],
        discounts = parse_grid("discounts"),
        durations = grid["durations"],
        costs = parse_grid("costs"),
        operating_adjustments = parse_grid("operating_adjustments"),
        nonnegative_gains = parse_grid("nonnegative_gains"),
        signed_gains = parse_grid("signed_gains"),
        comparator_premia = parse_grid("comparator_premia"),
        failure = outcomes["failure"],
        distinguished = outcomes["distinguished"],
        other_descendant = outcomes["other_descendant"],
    )
end

function _csv_quote(value)
    rendered = value isa Rational ? _ratio(value) : string(value)
    return "\"" * replace(rendered, "\"" => "\"\"") * "\""
end

function render_counterexamples(result)
    io = IOBuffer()
    println(
        io,
        "fixture_id,channel,classification,actual,attacked_bound,revised_bound," *
        "missing_assumption,theorem_revision,detail",
    )
    for fixture in result.fixtures
        println(
            io,
            join(
                (
                    _csv_quote(fixture.id),
                    _csv_quote(fixture.channel),
                    _csv_quote(fixture.classification),
                    _csv_quote(fixture.actual),
                    _csv_quote(fixture.attacked_bound),
                    _csv_quote(fixture.revised_bound),
                    _csv_quote(fixture.missing_assumption),
                    _csv_quote(fixture.revision),
                    _csv_quote(fixture.detail),
                ),
                ",",
            ),
        )
    end
    return String(take!(io))
end

function _json_escape(value::AbstractString)
    return replace(
        value,
        "\\" => "\\\\",
        "\"" => "\\\"",
        "\n" => "\\n",
        "\r" => "\\r",
        "\t" => "\\t",
    )
end

function _write_json(io::IO, value, indent::Int = 0)
    padding = " "^indent
    child = " "^(indent + 2)
    if value isa NamedTuple
        _write_json(io, Dict(string(key) => getproperty(value, key) for key in keys(value)), indent)
    elseif value isa AbstractDict
        ordered = sort!(collect(keys(value)); by = string)
        print(io, "{")
        if !isempty(ordered)
            println(io)
            for (index, key) in enumerate(ordered)
                print(io, child, "\"", _json_escape(string(key)), "\": ")
                _write_json(io, value[key], indent + 2)
                index == length(ordered) || print(io, ",")
                println(io)
            end
            print(io, padding)
        end
        print(io, "}")
    elseif value isa AbstractVector || value isa Tuple
        print(io, "[")
        if !isempty(value)
            println(io)
            for (index, item) in enumerate(value)
                print(io, child)
                _write_json(io, item, indent + 2)
                index == length(value) || print(io, ",")
                println(io)
            end
            print(io, padding)
        end
        print(io, "]")
    elseif value isa AbstractString || value isa Symbol
        print(io, "\"", _json_escape(string(value)), "\"")
    elseif value isa Bool
        print(io, value ? "true" : "false")
    elseif value === nothing
        print(io, "null")
    elseif value isa Rational
        print(io, "\"", _ratio(value), "\"")
    elseif value isa Integer
        print(io, value)
    else
        throw(ArgumentError("unsupported JSON type $(typeof(value))"))
    end
end

function render_summary(result)
    summary = Dict{String,Any}(
        "arithmetic" => result.arithmetic,
        "checks" => result.checks,
        "counts" => result.counts,
        "experiment_id" => result.experiment_id,
        "fixtures" => result.fixtures,
        "grid" => result.grid,
        "lean_gate_open" => result.lean_gate_open,
        "model" => result.model,
        "randomness" => result.randomness,
    )
    return sprint() do io
        _write_json(io, summary)
        println(io)
    end
end

function _configured_paths(config_path::AbstractString)
    outputs = TOML.parsefile(config_path)["outputs"]
    return (
        counterexamples = joinpath(REPOSITORY_ROOT, outputs["counterexamples"]),
        summary = joinpath(REPOSITORY_ROOT, outputs["summary"]),
    )
end

function write_outputs(
    result;
    config_path::AbstractString = DEFAULT_CONFIG,
    check::Bool = false,
)
    paths = _configured_paths(config_path)
    rendered = (
        counterexamples = render_counterexamples(result),
        summary = render_summary(result),
    )
    for key in keys(paths)
        path = getproperty(paths, key)
        content = getproperty(rendered, key)
        if check
            isfile(path) || error("missing registered output: $path")
            read(path, String) == content ||
                error("registered joint-bound output drift: $path")
        else
            mkpath(dirname(path))
            write(path, content)
        end
    end
    return paths
end

function main(args = ARGS)
    all(argument -> argument == "--check", args) ||
        throw(ArgumentError("usage: search_joint_descendant_bound.jl [--check]"))
    check = "--check" in args
    result = run_joint_descendant_gauntlet_from_config()
    paths = write_outputs(result; check)
    println(check ? "Joint-bound outputs are current." : "Wrote joint-bound outputs.")
    println("Primary checks: ", result.counts.single_checks)
    println("Primary failures: ", result.counts.single_failures)
    println("Harm-corrected failures: ", result.counts.harmful_corrected_failures)
    println("Lean gate open: ", result.lean_gate_open)
    return paths
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
