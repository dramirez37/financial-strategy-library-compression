module FinancialStrategyLibraryPanelV4

using Printf: @sprintf
using Random: rand, randn
using SHA: sha256
using StableRNGs: StableRNG

export MechanismDesign,
       NoiseCalibration,
       RegimeSpec,
       WorldResult,
       RegimeSummary,
       bridge_descendant_gain,
       calibrate_adoption_threshold,
       canonical_world_record,
       mean_ci,
       nearest_rank_quantile,
       record_hash,
       registered_regimes,
       run_experiment,
       simulate_proposal_noise,
       stable_seed,
       structural_first_stage,
       summarize_regime,
       wilson_interval

struct MechanismDesign
    calibration_world_count::Int
    evaluation_world_count_per_regime::Int
    proposal_sessions::Int
    annualization_sessions::Int
    proposal_burnin_sessions::Int
    discount_factor::Float64
    survival_probability::Float64
    admission_probability::Float64
    delay_periods::Int
    economic_hurdle::Float64
    null_quantile::Float64
    null_seed::Int
    proposal_seed::Int
    evaluation_seed::Int
    safe_retention_burden::Int
    frontier_retention_burden::Int
    safe_operating_frontier::Int
    frontier_operating_frontier::Int

    function MechanismDesign(;
        calibration_world_count::Integer,
        evaluation_world_count_per_regime::Integer,
        proposal_sessions::Integer,
        annualization_sessions::Integer,
        proposal_burnin_sessions::Integer,
        discount_factor::Real,
        survival_probability::Real,
        admission_probability::Real,
        delay_periods::Integer,
        economic_hurdle::Real,
        null_quantile::Real,
        null_seed::Integer,
        proposal_seed::Integer,
        evaluation_seed::Integer,
        safe_retention_burden::Integer,
        frontier_retention_burden::Integer,
        safe_operating_frontier::Integer,
        frontier_operating_frontier::Integer,
    )
        calibration_world_count >= 100 ||
            throw(ArgumentError("null calibration needs at least 100 worlds"))
        evaluation_world_count_per_regime >= 100 ||
            throw(ArgumentError("evaluation needs at least 100 worlds per regime"))
        proposal_sessions >= 20 || throw(ArgumentError("proposal window is too short"))
        annualization_sessions > 0 || throw(ArgumentError("annualization must be positive"))
        proposal_burnin_sessions >= 0 || throw(ArgumentError("burn-in cannot be negative"))
        beta = Float64(discount_factor)
        survival = Float64(survival_probability)
        admission = Float64(admission_probability)
        0 < beta <= 1 || throw(ArgumentError("discount factor must be in (0,1]"))
        0 < survival <= 1 || throw(ArgumentError("survival probability must be in (0,1]"))
        0 < admission <= 1 || throw(ArgumentError("admission probability must be in (0,1]"))
        delay_periods >= 1 || throw(ArgumentError("delay must be positive"))
        hurdle = Float64(economic_hurdle)
        isfinite(hurdle) && hurdle > 0 ||
            throw(ArgumentError("economic hurdle must be finite and positive"))
        quantile = Float64(null_quantile)
        0.5 < quantile < 1 || throw(ArgumentError("null quantile must lie in (0.5,1)"))
        safe_retention_burden > 0 && frontier_retention_burden > 0 ||
            throw(ArgumentError("retention burdens must be positive"))
        return new(
            Int(calibration_world_count),
            Int(evaluation_world_count_per_regime),
            Int(proposal_sessions),
            Int(annualization_sessions),
            Int(proposal_burnin_sessions),
            beta,
            survival,
            admission,
            Int(delay_periods),
            hurdle,
            quantile,
            Int(null_seed),
            Int(proposal_seed),
            Int(evaluation_seed),
            Int(safe_retention_burden),
            Int(frontier_retention_burden),
            Int(safe_operating_frontier),
            Int(frontier_operating_frontier),
        )
    end
end

struct NoiseCalibration
    daily_sigma::Float64
    ar1_rho::Float64
    student_t_df::Int

    function NoiseCalibration(daily_sigma::Real, ar1_rho::Real, student_t_df::Integer)
        sigma = Float64(daily_sigma)
        rho = Float64(ar1_rho)
        isfinite(sigma) && sigma > 0 ||
            throw(ArgumentError("daily sigma must be finite and positive"))
        isfinite(rho) && abs(rho) < 0.95 ||
            throw(ArgumentError("AR(1) coefficient must be finite with absolute value below 0.95"))
        student_t_df >= 5 || throw(ArgumentError("Student t degrees of freedom must be at least five"))
        return new(sigma, rho, Int(student_t_df))
    end
end

struct RegimeSpec
    regime_id::String
    true_margin::Float64
    role::String

    function RegimeSpec(regime_id, true_margin::Real, role)
        id = String(regime_id)
        isempty(id) && throw(ArgumentError("regime identifier cannot be empty"))
        margin = Float64(true_margin)
        isfinite(margin) || throw(ArgumentError("true margin must be finite"))
        return new(id, margin, String(role))
    end
end

struct WorldResult
    regime_id::String
    world_id::Int
    true_margin::Float64
    proposal_noise::Float64
    proposal_margin_estimate::Float64
    adoption_threshold::Float64
    research_cost::Float64
    gross_descendant_gain::Float64
    project_success::Bool
    oracle_adopt::Bool
    learned_adopt::Bool
    realized_project_value::Float64
    oracle_value::Float64
    learned_value::Float64
    frontier_value::Float64
    safe_retention_burden::Int
    frontier_retention_burden::Int
    safe_operating_frontier::Int
    frontier_operating_frontier::Int
    safe_bridge_capability::Bool
    frontier_bridge_capability::Bool
    cash_feasible::Bool
    structural_valid::Bool
    record_hash::String
end

struct RegimeSummary
    regime_id::String
    role::String
    world_count::Int
    true_margin::Float64
    theoretical_oracle_value::Float64
    oracle_mean::Float64
    oracle_median::Float64
    oracle_standard_error::Float64
    oracle_ci_lower::Float64
    oracle_ci_upper::Float64
    learned_mean::Float64
    learned_median::Float64
    learned_standard_error::Float64
    learned_ci_lower::Float64
    learned_ci_upper::Float64
    adoption_rate::Float64
    adoption_wilson_lower::Float64
    adoption_wilson_upper::Float64
    project_success_rate::Float64
    structural_pass_rate::Float64
end

function _mean(values)
    isempty(values) && throw(ArgumentError("mean requires observations"))
    return sum(values) / length(values)
end

function _sample_variance(values)
    length(values) <= 1 && return 0.0
    center = _mean(values)
    return sum((value - center)^2 for value in values) / (length(values) - 1)
end

function _median(values)
    isempty(values) && throw(ArgumentError("median requires observations"))
    ordered = sort!(Float64.(collect(values)))
    n = length(ordered)
    return isodd(n) ? ordered[(n + 1) ÷ 2] :
        (ordered[n ÷ 2] + ordered[n ÷ 2 + 1]) / 2
end

function nearest_rank_quantile(values, probability::Real)
    isempty(values) && throw(ArgumentError("quantile requires observations"))
    p = Float64(probability)
    0 <= p <= 1 || throw(ArgumentError("probability must lie in [0,1]"))
    ordered = sort!(Float64.(collect(values)))
    index = clamp(ceil(Int, p * length(ordered)), 1, length(ordered))
    return ordered[index]
end

function mean_ci(values; z::Real = 1.96)
    collected = Float64.(collect(values))
    isempty(collected) && throw(ArgumentError("confidence interval requires observations"))
    average = _mean(collected)
    standard_error = sqrt(_sample_variance(collected) / length(collected))
    critical = Float64(z)
    return (
        mean = average,
        standard_error,
        lower = average - critical * standard_error,
        upper = average + critical * standard_error,
    )
end

function wilson_interval(successes::Integer, trials::Integer; z::Real = 1.96)
    0 <= successes <= trials || throw(ArgumentError("invalid binomial counts"))
    trials > 0 || throw(ArgumentError("Wilson interval requires positive trials"))
    critical = Float64(z)
    proportion = successes / trials
    denominator = 1 + critical^2 / trials
    center = (proportion + critical^2 / (2trials)) / denominator
    radius = critical / denominator * sqrt(
        proportion * (1 - proportion) / trials + critical^2 / (4trials^2),
    )
    return (lower = max(0.0, center - radius), upper = min(1.0, center + radius))
end

"""Derive a stable 31-bit seed from a registered purpose and scope."""
function stable_seed(base_seed::Integer, purpose_id, scope_values...)
    digest = sha256(join(string.((base_seed, purpose_id, scope_values...)), '|'))
    value = foldl(
        (accumulator, byte) -> (accumulator << 8) | UInt64(byte),
        @view(digest[1:8]);
        init = UInt64(0),
    )
    return Int(mod(value, UInt64(2_147_483_647)))
end

function _unit_variance_student_t(rng, degrees_of_freedom::Int)
    chi_square = sum(randn(rng)^2 for _ in 1:degrees_of_freedom)
    return randn(rng) * sqrt((degrees_of_freedom - 2) / chi_square)
end

"""Simulate one annualized proposal-estimation error from the calibrated AR(1)-t law."""
function simulate_proposal_noise(
    rng,
    design::MechanismDesign,
    calibration::NoiseCalibration,
)
    rho = calibration.ar1_rho
    innovation_scale = calibration.daily_sigma * sqrt(1 - rho^2)
    state = calibration.daily_sigma * _unit_variance_student_t(rng, calibration.student_t_df)
    total = 0.0
    total_sessions = design.proposal_burnin_sessions + design.proposal_sessions
    for session in 1:total_sessions
        state = rho * state + innovation_scale *
            _unit_variance_student_t(rng, calibration.student_t_df)
        session > design.proposal_burnin_sessions && (total += state)
    end
    return design.annualization_sessions * total / design.proposal_sessions
end

function calibrate_adoption_threshold(
    design::MechanismDesign,
    calibration::NoiseCalibration,
)
    estimates = Vector{Float64}(undef, design.calibration_world_count)
    for world_id in eachindex(estimates)
        rng = StableRNG(stable_seed(design.null_seed, "null_threshold", world_id))
        estimates[world_id] = simulate_proposal_noise(rng, design, calibration)
    end
    null_cutoff = nearest_rank_quantile(estimates, design.null_quantile)
    threshold = max(design.economic_hurdle, null_cutoff)
    return (; threshold, null_cutoff, estimates)
end

function registered_regimes(design::MechanismDesign, threshold::Real)
    cutoff = Float64(threshold)
    cutoff > 0 || throw(ArgumentError("calibrated threshold must be positive"))
    return [
        RegimeSpec("adversarial_margin", -cutoff, "negative_control"),
        RegimeSpec("null_margin", 0.0, "size_control"),
        RegimeSpec("low_dose_positive", design.economic_hurdle, "secondary_positive"),
        RegimeSpec("powered_positive", 2cutoff, "primary_positive"),
    ]
end

function structural_first_stage(design::MechanismDesign)
    equal_burden = design.safe_retention_burden == design.frontier_retention_burden
    equal_frontier = design.safe_operating_frontier == design.frontier_operating_frontier
    safe_bridge_capability = true
    frontier_bridge_capability = false
    cash_feasible = true
    valid = equal_burden && equal_frontier && safe_bridge_capability &&
        !frontier_bridge_capability && cash_feasible
    return (;
        equal_burden,
        equal_frontier,
        safe_bridge_capability,
        frontier_bridge_capability,
        cash_feasible,
        valid,
    )
end

function _success_probability(design::MechanismDesign)
    return design.survival_probability^design.delay_periods *
           design.admission_probability
end

function bridge_descendant_gain(
    design::MechanismDesign,
    research_cost::Real,
    true_margin::Real,
)
    cost = Float64(research_cost)
    margin = Float64(true_margin)
    probability = _success_probability(design)
    discounted_probability = design.discount_factor^design.delay_periods * probability
    gain = (cost + margin) / discounted_probability
    gain >= 0 || throw(ArgumentError("registered regime implies a negative descendant gain"))
    return gain
end

_float_string(value::Real) = @sprintf("%.17g", Float64(value))

function canonical_world_record(result::WorldResult)
    return join((
        result.regime_id,
        string(result.world_id),
        _float_string(result.true_margin),
        _float_string(result.proposal_noise),
        _float_string(result.proposal_margin_estimate),
        _float_string(result.adoption_threshold),
        _float_string(result.research_cost),
        _float_string(result.gross_descendant_gain),
        lowercase(string(result.project_success)),
        lowercase(string(result.oracle_adopt)),
        lowercase(string(result.learned_adopt)),
        _float_string(result.realized_project_value),
        _float_string(result.oracle_value),
        _float_string(result.learned_value),
        _float_string(result.frontier_value),
        string(result.safe_retention_burden),
        string(result.frontier_retention_burden),
        string(result.safe_operating_frontier),
        string(result.frontier_operating_frontier),
        lowercase(string(result.safe_bridge_capability)),
        lowercase(string(result.frontier_bridge_capability)),
        lowercase(string(result.cash_feasible)),
        lowercase(string(result.structural_valid)),
    ), '\0')
end

record_hash(result::WorldResult) = bytes2hex(sha256(canonical_world_record(result)))

function _world_result(
    design::MechanismDesign,
    regime::RegimeSpec,
    world_id::Int,
    proposal_noise::Float64,
    project_success::Bool,
    threshold::Float64,
    research_cost::Float64,
)
    structure = structural_first_stage(design)
    proposal_estimate = regime.true_margin + proposal_noise
    oracle_adopt = regime.true_margin > 0
    learned_adopt = proposal_estimate > threshold
    gain = bridge_descendant_gain(design, research_cost, regime.true_margin)
    realized_project_value = -research_cost +
        design.discount_factor^design.delay_periods * (project_success ? gain : 0.0)
    oracle_value = oracle_adopt ? realized_project_value : 0.0
    learned_value = learned_adopt ? realized_project_value : 0.0
    unsealed = WorldResult(
        regime.regime_id,
        world_id,
        regime.true_margin,
        proposal_noise,
        proposal_estimate,
        threshold,
        research_cost,
        gain,
        project_success,
        oracle_adopt,
        learned_adopt,
        realized_project_value,
        oracle_value,
        learned_value,
        0.0,
        design.safe_retention_burden,
        design.frontier_retention_burden,
        design.safe_operating_frontier,
        design.frontier_operating_frontier,
        structure.safe_bridge_capability,
        structure.frontier_bridge_capability,
        structure.cash_feasible,
        structure.valid,
        "",
    )
    return WorldResult(
        unsealed.regime_id,
        unsealed.world_id,
        unsealed.true_margin,
        unsealed.proposal_noise,
        unsealed.proposal_margin_estimate,
        unsealed.adoption_threshold,
        unsealed.research_cost,
        unsealed.gross_descendant_gain,
        unsealed.project_success,
        unsealed.oracle_adopt,
        unsealed.learned_adopt,
        unsealed.realized_project_value,
        unsealed.oracle_value,
        unsealed.learned_value,
        unsealed.frontier_value,
        unsealed.safe_retention_burden,
        unsealed.frontier_retention_burden,
        unsealed.safe_operating_frontier,
        unsealed.frontier_operating_frontier,
        unsealed.safe_bridge_capability,
        unsealed.frontier_bridge_capability,
        unsealed.cash_feasible,
        unsealed.structural_valid,
        bytes2hex(sha256(canonical_world_record(unsealed))),
    )
end

function summarize_regime(results, regime::RegimeSpec, ::Val{:validated})
    rows = filter(result -> result.regime_id == regime.regime_id, collect(results))
    isempty(rows) && throw(ArgumentError("no rows for regime $(regime.regime_id)"))
    oracle_values = getfield.(rows, :oracle_value)
    learned_values = getfield.(rows, :learned_value)
    oracle = mean_ci(oracle_values)
    learned = mean_ci(learned_values)
    adoption_count = count(result -> result.learned_adopt, rows)
    success_count = count(result -> result.project_success, rows)
    structural_count = count(result -> result.structural_valid, rows)
    adoption_interval = wilson_interval(adoption_count, length(rows))
    return RegimeSummary(
        regime.regime_id,
        regime.role,
        length(rows),
        regime.true_margin,
        max(0.0, regime.true_margin),
        oracle.mean,
        _median(oracle_values),
        oracle.standard_error,
        oracle.lower,
        oracle.upper,
        learned.mean,
        _median(learned_values),
        learned.standard_error,
        learned.lower,
        learned.upper,
        adoption_count / length(rows),
        adoption_interval.lower,
        adoption_interval.upper,
        success_count / length(rows),
        structural_count / length(rows),
    )
end

summarize_regime(results, regime::RegimeSpec) =
    summarize_regime(results, regime, Val(:validated))

function run_experiment(design::MechanismDesign, calibration::NoiseCalibration)
    calibration_result = calibrate_adoption_threshold(design, calibration)
    threshold = calibration_result.threshold
    research_cost = 2threshold
    regimes = registered_regimes(design, threshold)
    world_count = design.evaluation_world_count_per_regime
    results = Vector{WorldResult}(undef, world_count * length(regimes))
    success_probability = _success_probability(design)

    Threads.@threads for world_id in 1:world_count
        proposal_rng = StableRNG(stable_seed(design.proposal_seed, "proposal_world", world_id))
        evaluation_rng = StableRNG(stable_seed(design.evaluation_seed, "project_event", world_id))
        proposal_noise = simulate_proposal_noise(proposal_rng, design, calibration)
        project_success = rand(evaluation_rng) < success_probability
        for (regime_index, regime) in enumerate(regimes)
            index = (regime_index - 1) * world_count + world_id
            results[index] = _world_result(
                design,
                regime,
                world_id,
                proposal_noise,
                project_success,
                threshold,
                research_cost,
            )
        end
    end

    summaries = [summarize_regime(results, regime) for regime in regimes]
    return (;
        threshold,
        null_cutoff = calibration_result.null_cutoff,
        research_cost,
        success_probability,
        regimes,
        results,
        summaries,
    )
end

end
