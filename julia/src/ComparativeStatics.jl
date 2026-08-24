using SparseArrays: SparseMatrixCSC, sparse, spdiagm

"""
    UnifiedComparativeParameters(; mode=ExactMode(), ...)

The twelve primitive inputs varied by the unified comparative-statics engine.
`closure_richness` is the fraction of the finite module closure usable by the
candidate generator, while `module_overlap` is the fraction of missing
candidate requirements already supplied by the incumbent closure.  Their
effective generator coverage is
`closure_richness + module_overlap * (1 - closure_richness)`.

Exact mode rejects floating-point inputs.  Float64 mode is reserved for
response surfaces and never supplies theorem evidence.
"""
struct UnifiedComparativeParameters{T<:Real}
    frontier_level::T
    frontier_density::T
    closure_richness::T
    module_overlap::T
    research_cost::T
    research_duration::Int
    admission_probability::T
    candidate_survival::T
    discount_factor::T
    belief_kernel_persistence::T
    signal_precision_proxy::T
    candidate_profile_quality::T
    generator_frontier_dependence::T
end

function UnifiedComparativeParameters(;
    mode::ArithmeticMode = ExactMode(),
    frontier_level = 1,
    frontier_density = 1 // 2,
    closure_richness = 3 // 4,
    module_overlap = 1 // 4,
    research_cost = 1 // 4,
    research_duration::Integer = 1,
    admission_probability = 3 // 4,
    candidate_survival = 9 // 10,
    discount_factor = 4 // 5,
    belief_kernel_persistence = 3 // 4,
    signal_precision_proxy = 1 // 2,
    candidate_profile_quality = 2,
    generator_frontier_dependence = 0,
)
    T = _coefficient_type(mode)
    value = UnifiedComparativeParameters{T}(
        _coerce_scalar(mode, frontier_level),
        _coerce_scalar(mode, frontier_density),
        _coerce_scalar(mode, closure_richness),
        _coerce_scalar(mode, module_overlap),
        _coerce_scalar(mode, research_cost),
        Int(research_duration),
        _coerce_scalar(mode, admission_probability),
        _coerce_scalar(mode, candidate_survival),
        _coerce_scalar(mode, discount_factor),
        _coerce_scalar(mode, belief_kernel_persistence),
        _coerce_scalar(mode, signal_precision_proxy),
        _coerce_scalar(mode, candidate_profile_quality),
        _coerce_scalar(mode, generator_frontier_dependence),
    )
    return _validate_comparative_parameters(value)
end

function _validate_comparative_parameters(parameters::UnifiedComparativeParameters)
    fields = (
        parameters.frontier_level,
        parameters.frontier_density,
        parameters.closure_richness,
        parameters.module_overlap,
        parameters.research_cost,
        parameters.admission_probability,
        parameters.candidate_survival,
        parameters.discount_factor,
        parameters.belief_kernel_persistence,
        parameters.signal_precision_proxy,
        parameters.candidate_profile_quality,
        parameters.generator_frontier_dependence,
    )
    all(isfinite, fields) ||
        throw(ArgumentError("comparative-statics parameters must be finite"))
    parameters.frontier_level >= 0 ||
        throw(ArgumentError("frontier level must be nonnegative"))
    parameters.research_cost >= 0 ||
        throw(ArgumentError("research cost must be nonnegative"))
    parameters.candidate_profile_quality >= 0 ||
        throw(ArgumentError("candidate profile quality must be nonnegative"))
    parameters.research_duration >= 1 ||
        throw(ArgumentError("research duration must be strictly positive"))
    for (label, value) in (
        ("frontier density", parameters.frontier_density),
        ("closure richness", parameters.closure_richness),
        ("module overlap", parameters.module_overlap),
        ("admission probability", parameters.admission_probability),
        ("candidate survival", parameters.candidate_survival),
        ("belief-kernel persistence", parameters.belief_kernel_persistence),
        ("signal precision proxy", parameters.signal_precision_proxy),
    )
        0 <= value <= 1 || throw(ArgumentError("$label must lie in [0, 1]"))
    end
    0 <= parameters.discount_factor < 1 ||
        throw(ArgumentError("discount factor must lie in [0, 1)"))
    -1 <= parameters.generator_frontier_dependence <= 1 || throw(
        ArgumentError("generator dependence on the frontier must lie in [-1, 1]"),
    )
    return parameters
end

"""
    ComparativeStaticsConfig(; mode=ExactMode(), ...)

Deterministic solver, finite-interaction, and numerical gate configuration.
`operates_during_research` implements the unified elapsed-time incumbent reward
stream.  Exact mode requires zero iteration tolerance and zero residual gates.
"""
struct ComparativeStaticsConfig{T<:Real}
    belief_count::Int
    reference_index::Int
    finite_horizon::Int
    value_tolerance::T
    residual_gate::T
    error_gate::T
    max_iterations::Int
    frontier_step::T
    closure_step::T
    parameter_step::T
    operates_during_research::Bool
end

function ComparativeStaticsConfig(;
    mode::ArithmeticMode = ExactMode(),
    belief_count::Integer = mode isa ExactMode ? 3 : 61,
    reference_index::Integer = cld(Int(belief_count), 2),
    finite_horizon::Integer = 5,
    value_tolerance = mode isa ExactMode ? 0 : 1e-10,
    residual_gate = mode isa ExactMode ? 0 : 1e-9,
    error_gate = mode isa ExactMode ? 0 : 1e-7,
    max_iterations::Integer = 20_000,
    frontier_step = mode isa ExactMode ? 1 // 4 : 0.25,
    closure_step = mode isa ExactMode ? 1 // 4 : 0.25,
    parameter_step = mode isa ExactMode ? 1 // 10 : 0.10,
    operates_during_research::Bool = true,
)
    T = _coefficient_type(mode)
    config = ComparativeStaticsConfig{T}(
        Int(belief_count),
        Int(reference_index),
        Int(finite_horizon),
        _coerce_scalar(mode, value_tolerance),
        _coerce_scalar(mode, residual_gate),
        _coerce_scalar(mode, error_gate),
        Int(max_iterations),
        _coerce_scalar(mode, frontier_step),
        _coerce_scalar(mode, closure_step),
        _coerce_scalar(mode, parameter_step),
        operates_during_research,
    )
    config.belief_count >= 1 ||
        throw(ArgumentError("belief count must be positive"))
    1 <= config.reference_index <= config.belief_count ||
        throw(ArgumentError("reference index must resolve on the belief grid"))
    config.finite_horizon >= 1 ||
        throw(ArgumentError("finite interaction horizon must be positive"))
    config.max_iterations >= 1 ||
        throw(ArgumentError("maximum iterations must be positive"))
    all(
        value -> isfinite(value) && value >= 0,
        (
            config.value_tolerance,
            config.residual_gate,
            config.error_gate,
            config.frontier_step,
            config.closure_step,
            config.parameter_step,
        ),
    ) || throw(ArgumentError("solver tolerances and comparison steps must be nonnegative"))
    if T == ExactRational &&
       (config.value_tolerance != zero(T) ||
        config.residual_gate != zero(T) ||
        config.error_gate != zero(T))
        throw(ArgumentError("ExactRational configurations require zero solver tolerances and gates"))
    end
    return config
end

"""Explicit theorem-boundary and numerical-regime flags for one solve."""
struct ComparativeStaticsFlags
    frontier_dependent_generator::Bool
    persistence_has_no_universal_sign::Bool
    bellman_cutoff_is_numerical_only::Bool
    delay_no_waiting_gain_unverified::Bool
    relative_saturation_unverified::Bool
    research_set_disconnected::Bool
    bellman_gate_failed::Bool
end

"""One assumption-gated, theorem-ID-tagged automated sign check."""
struct ComparativeStaticsSignCheck{T<:Real}
    check_id::Symbol
    theorem_id::String
    expected_direction::Symbol
    observed_difference::T
    applicable::Bool
    passed::Bool
    boundary_flag::Symbol
    detail::String
end

"""
All requested comparative-static outcomes at one reference belief.

`research_frequency` is the fraction of belief-grid states selecting Research
at the baseline raw library. `research_cutoff` is populated only when that
Bellman action set is an upper threshold; it is a numerical diagnostic, not
Lean S5's one-shot cost-covering cutoff. `compression_ratio` is the exact
fraction of raw strategies safely removed.
"""
struct ComparativeStaticsResult{T<:Real}
    parameters::UnifiedComparativeParameters{T}
    total_value::T
    passive_value::T
    research_option_premium::T
    operational_innovation::T
    generative_innovation::T
    research_frequency::T
    optimal_action::Symbol
    research_cutoff::Union{Nothing,T}
    cutoff_kind::Symbol
    pruning_loss::T
    compression_ratio::ExactRational
    descendant_quality::T
    frontier_closure_cross_difference::T
    bellman_residual::T
    value_error_bound::T
    iterations::Int
    converged::Bool
    gate_passed::Bool
    sparse_mode::Bool
    raw_source_of_truth::Bool
    policy::Vector{Symbol}
    flags::ComparativeStaticsFlags
end

"""
Sparse numerical compilation of the canonical raw catalog and admitted law.
The two library states are the baseline library and the same library after
candidate admission.
"""
struct CompiledUnifiedComparativeModel{
    T<:Real,
    MT<:AbstractMatrix{T},
}
    kernel::MT
    terminal_kernel::MT
    frontier::Matrix{T}
    generation_probability::Vector{T}
    admitted_probability::Vector{T}
    operating_reward::Matrix{T}
    discount::T
    duration::Int
    research_cost::T
    coordinates::Vector{T}
end

function _coordinate_vector(::Type{ExactRational}, count::Int)
    count == 1 && return ExactRational[0]
    return ExactRational[
        exact_rational(index - 1) / exact_rational(count - 1) for index in 1:count
    ]
end
function _coordinate_vector(::Type{Float64}, count::Int)
    count == 1 && return Float64[0]
    return collect(range(0.0, 1.0; length = count))
end

function _comparative_transition_matrix(
    parameters::UnifiedComparativeParameters{T},
    count::Int,
) where {T}
    matrix = zeros(T, count, count)
    count == 1 && (matrix[1, 1] = one(T); return matrix)
    persistence = parameters.belief_kernel_persistence
    upward_share = (one(T) + parameters.signal_precision_proxy) / (one(T) + one(T))
    downward_share = one(T) - upward_share
    move = one(T) - persistence
    for index in 1:count
        matrix[index, index] += persistence
        if index < count
            matrix[index, index + 1] += move * upward_share
        else
            matrix[index, index] += move * upward_share
        end
        if index > 1
            matrix[index, index - 1] += move * downward_share
        else
            matrix[index, index] += move * downward_share
        end
    end
    return matrix
end

function _comparative_profiles(
    parameters::UnifiedComparativeParameters{T},
    coordinates::AbstractVector{T},
) where {T}
    incumbent = T[
        parameters.frontier_level * (
            parameters.frontier_density +
            (one(T) - parameters.frontier_density) * coordinate
        ) for coordinate in coordinates
    ]
    candidate = fill(parameters.candidate_profile_quality, length(coordinates))
    admitted = max.(incumbent, candidate)
    return incumbent, candidate, admitted
end

function _generation_probabilities(
    parameters::UnifiedComparativeParameters{T},
    incumbent::AbstractVector{T},
) where {T}
    coverage =
        parameters.closure_richness +
        parameters.module_overlap * (one(T) - parameters.closure_richness)
    survival_mass = parameters.candidate_survival^parameters.research_duration
    scale = max(
        one(T),
        parameters.frontier_level,
        parameters.candidate_profile_quality,
    )
    return T[
        clamp(
            survival_mass * coverage * (
                one(T) +
                parameters.generator_frontier_dependence * (
                    incumbent_value / scale - one(T) / (one(T) + one(T))
                )
            ),
            zero(T),
            one(T),
        ) for incumbent_value in incumbent
    ]
end

function _compile_comparative_model(
    parameters::UnifiedComparativeParameters{Float64},
    config::ComparativeStaticsConfig{Float64},
)
    coordinates = _coordinate_vector(Float64, config.belief_count)
    dense_kernel = _comparative_transition_matrix(parameters, config.belief_count)
    kernel = sparse(dense_kernel)
    terminal_kernel = kernel^parameters.research_duration
    incumbent, _, admitted_frontier = _comparative_profiles(parameters, coordinates)
    generation = _generation_probabilities(parameters, incumbent)
    admitted = generation .* parameters.admission_probability
    frontiers = hcat(incumbent, admitted_frontier)
    operating = zeros(Float64, config.belief_count, 2)
    if config.operates_during_research
        transition_power = spdiagm(0 => ones(Float64, config.belief_count))
        for elapsed in 0:(parameters.research_duration - 1)
            for stage in 1:2
                operating[:, stage] .+=
                    parameters.discount_factor^elapsed .* (transition_power * frontiers[:, stage])
            end
            transition_power = transition_power * kernel
        end
    end
    operating .-= parameters.research_cost
    return CompiledUnifiedComparativeModel(
        kernel,
        terminal_kernel,
        frontiers,
        generation,
        admitted,
        operating,
        parameters.discount_factor,
        parameters.research_duration,
        parameters.research_cost,
        coordinates,
    )
end

function _compile_dense_comparative_model(
    parameters::UnifiedComparativeParameters{ExactRational},
    config::ComparativeStaticsConfig{ExactRational},
)
    coordinates = _coordinate_vector(ExactRational, config.belief_count)
    kernel = _comparative_transition_matrix(parameters, config.belief_count)
    terminal_kernel = kernel^parameters.research_duration
    incumbent, _, admitted_frontier = _comparative_profiles(parameters, coordinates)
    generation = _generation_probabilities(parameters, incumbent)
    admitted = generation .* parameters.admission_probability
    frontiers = hcat(incumbent, admitted_frontier)
    operating = zeros(ExactRational, config.belief_count, 2)
    if config.operates_during_research
        transition_power =
            Matrix{ExactRational}(I, config.belief_count, config.belief_count)
        for elapsed in 0:(parameters.research_duration - 1)
            for stage in 1:2
                operating[:, stage] .+=
                    parameters.discount_factor^elapsed .* (transition_power * frontiers[:, stage])
            end
            transition_power = transition_power * kernel
        end
    end
    operating .-= parameters.research_cost
    return CompiledUnifiedComparativeModel(
        kernel,
        terminal_kernel,
        frontiers,
        generation,
        admitted,
        operating,
        parameters.discount_factor,
        parameters.research_duration,
        parameters.research_cost,
        coordinates,
    )
end

function _comparative_catalog(
    parameters::UnifiedComparativeParameters{T},
    config::ComparativeStaticsConfig{T},
) where {T<:Union{ExactRational,Float64}}
    mode = T == ExactRational ? ExactMode() : Float64Mode()
    beliefs = FiniteBeliefSpace(collect(1:config.belief_count))
    coordinates = _coordinate_vector(T, config.belief_count)
    incumbent, candidate, _ = _comparative_profiles(parameters, coordinates)
    modules = GenerativeModule.([:core, :bridge, :descendant])
    empty_modules = ModuleSet{Symbol}()
    core_modules = ModuleSet([ModuleId(:core)])
    bridge_modules = ModuleSet([ModuleId(:bridge)])
    candidate_modules = parameters.module_overlap == one(T) ?
                        core_modules : ModuleSet([ModuleId(:descendant)])
    rows = [
        Strategy(
            :inactive,
            OperationalProfile(beliefs, zeros(T, config.belief_count); mode),
            empty_modules,
        ),
        Strategy(
            :incumbent,
            OperationalProfile(beliefs, incumbent; mode),
            core_modules,
        ),
        Strategy(
            :carrier,
            OperationalProfile(beliefs, zeros(T, config.belief_count); mode),
            bridge_modules,
        ),
        Strategy(
            :duplicate,
            OperationalProfile(beliefs, incumbent; mode),
            core_modules,
        ),
        Strategy(
            :candidate,
            OperationalProfile(beliefs, candidate; mode),
            candidate_modules,
        ),
    ]
    catalog = StrategyCatalog(beliefs, modules, rows, StrategyId(:inactive))
    closure = identity_generative_closure(modules)
    base = RawLibrary(
        catalog,
        StrategyId{Symbol}[
            StrategyId(:inactive),
            StrategyId(:incumbent),
            StrategyId(:carrier),
            StrategyId(:duplicate),
        ],
    )
    candidate_library = insert_strategy(catalog, base, StrategyId(:candidate))
    pruned = frontier_only_prune(catalog, base)
    safe = minimum_safe_compression(catalog, closure, base)
    return (; catalog, closure, base, candidate_library, pruned, safe, coordinates)
end

"""
    build_exact_comparative_process(parameters, config)

Build the exact `RawInnovationProcess` used by theorem fixtures. Candidate
generation, verification, admitted failure mass, raw update, completion paths,
and elapsed-time operating rewards are all derived through the public raw
model. The returned named tuple also identifies the baseline, admitted,
frontier-pruned, and safely compressed raw libraries.
"""
function build_exact_comparative_process(
    parameters::UnifiedComparativeParameters{ExactRational},
    config::ComparativeStaticsConfig{ExactRational},
)
    bundle = _comparative_catalog(parameters, config)
    kernel_matrix = _comparative_transition_matrix(parameters, config.belief_count)
    kernel = MarkovKernel(bundle.catalog.beliefs, kernel_matrix)
    bridge_modules = ModuleSet([ModuleId(:bridge)])
    project = UnifiedResearchProject(
        :research,
        bridge_modules,
        parameters.research_duration,
        true,
    )
    incumbent = collect(operational_frontier(bundle.catalog, bundle.base).values)
    generation_probabilities = _generation_probabilities(parameters, incumbent)
    failure = CandidateOutcome{Symbol}()
    success = CandidateOutcome(StrategyId(:candidate))

    generation = function (_, belief, available)
        ModuleId(:bridge) in available || return dirac(failure)
        mass = generation_probabilities[belief_index(bundle.catalog.beliefs, belief)]
        return RatProb([failure, success], [one(ExactRational) - mass, mass])
    end
    verification = function (_, _, _, strategy_id)
        return strategy_id == StrategyId(:candidate) ?
               parameters.admission_probability : zero(ExactRational)
    end
    cost = (_, _, _) -> parameters.research_cost
    completion = function (_, belief, state)
        generated = ModuleId(:bridge) in state.closure ?
                    generation_probabilities[
                        belief_index(bundle.catalog.beliefs, belief)
                    ] : zero(ExactRational)
        admitted = generated * parameters.admission_probability
        outcomes = ProjectCompletionOutcome{Int,Symbol}[]
        masses = ExactRational[]
        for path in _positive_belief_paths(
            kernel,
            belief,
            parameters.research_duration,
        )
            path_mass = _markov_path_probability(kernel, belief, path)
            push!(
                outcomes,
                ProjectCompletionOutcome(collect(path), failure),
            )
            push!(masses, path_mass * (one(ExactRational) - admitted))
            push!(
                outcomes,
                ProjectCompletionOutcome(collect(path), success),
            )
            push!(masses, path_mass * admitted)
        end
        return RatProb(outcomes, masses)
    end
    process = RawInnovationProcess(
        bundle.catalog,
        bundle.closure,
        kernel,
        [project],
        generation,
        verification,
        cost,
        completion,
        parameters.discount_factor,
    )
    return merge(bundle, (; process, project, failure, success))
end

function _passive_values(model::CompiledUnifiedComparativeModel{T}) where {T}
    count = size(model.kernel, 1)
    identity_matrix = T == Float64 ?
                      spdiagm(0 => ones(Float64, count)) :
                      Matrix{ExactRational}(I, count, count)
    operator = identity_matrix - model.discount .* model.kernel
    return hcat(
        operator \ model.frontier[:, 1],
        operator \ model.frontier[:, 2],
    )
end

function _compiled_action_values(model, values)
    continue_values = similar(values)
    research_values = similar(values)
    beta_duration = model.discount^model.duration
    continuation_base = model.terminal_kernel * values[:, 1]
    continuation_admitted = model.terminal_kernel * values[:, 2]
    for stage in 1:2
        continue_values[:, stage] =
            model.frontier[:, stage] + model.discount .* (model.kernel * values[:, stage])
    end
    research_values[:, 1] =
        model.operating_reward[:, 1] +
        beta_duration .* (
            (one(eltype(values)) .- model.admitted_probability) .* continuation_base +
            model.admitted_probability .* continuation_admitted
        )
    research_values[:, 2] =
        model.operating_reward[:, 2] +
        beta_duration .* continuation_admitted
    return continue_values, research_values
end

function _float_value_iteration(model, config)
    values = zeros(Float64, size(model.frontier))
    converged = false
    iterations = config.max_iterations
    for iteration in 1:config.max_iterations
        continue_values, research_values = _compiled_action_values(model, values)
        next_values = max.(continue_values, research_values)
        next_continue, next_research = _compiled_action_values(model, next_values)
        residual = maximum(abs.(max.(next_continue, next_research) .- next_values))
        error_bound = residual / (1 - model.discount)
        values = next_values
        if error_bound <= config.value_tolerance
            converged = true
            iterations = iteration
            break
        end
    end
    continue_values, research_values = _compiled_action_values(model, values)
    residual = maximum(abs.(max.(continue_values, research_values) .- values))
    error_bound = residual / (1 - model.discount)
    policy = research_values .> continue_values
    return (; values, policy, residual, error_bound, iterations, converged)
end

function _finite_compiled_values(model, horizon::Int)
    T = eltype(model.frontier)
    history = Matrix{T}[zeros(T, size(model.frontier))]
    for remaining in 1:horizon
        prior = history[remaining]
        continue_values = similar(prior)
        for stage in 1:2
            continue_values[:, stage] =
                model.frontier[:, stage] +
                model.discount .* (model.kernel * prior[:, stage])
        end
        if model.duration <= remaining
            continuation = history[remaining - model.duration + 1]
            beta_duration = model.discount^model.duration
            continuation_base = model.terminal_kernel * continuation[:, 1]
            continuation_admitted =
                model.terminal_kernel * continuation[:, 2]
            research_values = similar(prior)
            research_values[:, 1] =
                model.operating_reward[:, 1] +
                beta_duration .* (
                    (one(T) .- model.admitted_probability) .* continuation_base +
                    model.admitted_probability .* continuation_admitted
                )
            research_values[:, 2] =
                model.operating_reward[:, 2] +
                beta_duration .* continuation_admitted
            push!(history, max.(continue_values, research_values))
        else
            push!(history, continue_values)
        end
    end
    return last(history)
end

function _action_region(policy::AbstractMatrix{Bool})
    return BitVector(policy[:, 1])
end

function _cutoff_diagnostic(region::AbstractVector{Bool}, coordinates)
    isempty(findall(identity, region)) && return (:empty, nothing)
    all(region) && return (:full, first(coordinates))
    first_research = findfirst(identity, region)
    upper = all(!region[index] for index in 1:(first_research - 1)) &&
            all(region[index] for index in first_research:length(region))
    upper && return (:upper, coordinates[first_research])
    last_research = findlast(identity, region)
    lower = all(region[index] for index in 1:last_research) &&
            all(!region[index] for index in (last_research + 1):length(region))
    lower && return (:lower, coordinates[last_research])
    return (:nonthreshold, nothing)
end

function _research_components(region::AbstractVector{Bool})
    components = 0
    active = false
    for value in region
        if value && !active
            components += 1
            active = true
        elseif !value
            active = false
        end
    end
    return components
end

function _descendant_quality(model, reference_index)
    gap = max.(model.frontier[:, 2] .- model.frontier[:, 1], zero(eltype(model.frontier)))
    return sum(
        model.terminal_kernel[reference_index, :] .* gap;
        init = zero(eltype(model.frontier)),
    )
end

function _parameter_replace(
    parameters::UnifiedComparativeParameters{T};
    frontier_level = parameters.frontier_level,
    frontier_density = parameters.frontier_density,
    closure_richness = parameters.closure_richness,
    module_overlap = parameters.module_overlap,
    research_cost = parameters.research_cost,
    research_duration = parameters.research_duration,
    admission_probability = parameters.admission_probability,
    candidate_survival = parameters.candidate_survival,
    discount_factor = parameters.discount_factor,
    belief_kernel_persistence = parameters.belief_kernel_persistence,
    signal_precision_proxy = parameters.signal_precision_proxy,
    candidate_profile_quality = parameters.candidate_profile_quality,
    generator_frontier_dependence = parameters.generator_frontier_dependence,
) where {T}
    return _validate_comparative_parameters(
        UnifiedComparativeParameters{T}(
            frontier_level,
            frontier_density,
            closure_richness,
            module_overlap,
            research_cost,
            Int(research_duration),
            admission_probability,
            candidate_survival,
            discount_factor,
            belief_kernel_persistence,
            signal_precision_proxy,
            candidate_profile_quality,
            generator_frontier_dependence,
        ),
    )
end

"""
    with_comparative_parameter(parameters, name, value)

Return a validated copy with one named primitive changed. This deterministic
helper is intended for one-at-a-time response surfaces.
"""
_comparative_parameter_scalar(::Type{ExactRational}, value) =
    exact_rational(value)
_comparative_parameter_scalar(::Type{Float64}, value) = Float64(value)

function with_comparative_parameter(
    parameters::UnifiedComparativeParameters{T},
    name::Symbol,
    value,
) where {T}
    name == :research_duration &&
        return _parameter_replace(parameters; research_duration = Int(value))
    converted = _comparative_parameter_scalar(T, value)
    name == :frontier_level &&
        return _parameter_replace(parameters; frontier_level = converted)
    name == :frontier_density &&
        return _parameter_replace(parameters; frontier_density = converted)
    name == :closure_richness &&
        return _parameter_replace(parameters; closure_richness = converted)
    name == :module_overlap &&
        return _parameter_replace(parameters; module_overlap = converted)
    name == :research_cost &&
        return _parameter_replace(parameters; research_cost = converted)
    name == :admission_probability &&
        return _parameter_replace(parameters; admission_probability = converted)
    name == :candidate_survival &&
        return _parameter_replace(parameters; candidate_survival = converted)
    name == :discount_factor &&
        return _parameter_replace(parameters; discount_factor = converted)
    name == :belief_kernel_persistence &&
        return _parameter_replace(parameters; belief_kernel_persistence = converted)
    name == :signal_precision_proxy &&
        return _parameter_replace(parameters; signal_precision_proxy = converted)
    name == :candidate_profile_quality &&
        return _parameter_replace(parameters; candidate_profile_quality = converted)
    name == :generator_frontier_dependence &&
        return _parameter_replace(parameters; generator_frontier_dependence = converted)
    throw(ArgumentError("unknown comparative-statics parameter: $name"))
end

function _finite_reference_value(
    parameters::UnifiedComparativeParameters{Float64},
    config::ComparativeStaticsConfig{Float64},
)
    model = _compile_comparative_model(parameters, config)
    return _finite_compiled_values(model, config.finite_horizon)[config.reference_index, 1]
end
function _finite_reference_value(
    parameters::UnifiedComparativeParameters{ExactRational},
    config::ComparativeStaticsConfig{ExactRational},
)
    bundle = build_exact_comparative_process(parameters, config)
    belief = bundle.catalog.beliefs.states[config.reference_index]
    return raw_finite_horizon_value(
        bundle.process,
        config.finite_horizon,
        belief,
        bundle.base,
    )
end

function _interaction_diagnostic(parameters, config)
    low_frontier = max(zero(parameters.frontier_level), parameters.frontier_level - config.frontier_step)
    high_frontier = parameters.frontier_level + config.frontier_step
    low_closure = max(zero(parameters.closure_richness), parameters.closure_richness - config.closure_step)
    high_closure = min(one(parameters.closure_richness), parameters.closure_richness + config.closure_step)
    poor_low = _finite_reference_value(
        _parameter_replace(
            parameters;
            frontier_level = low_frontier,
            closure_richness = low_closure,
        ),
        config,
    )
    rich_low = _finite_reference_value(
        _parameter_replace(
            parameters;
            frontier_level = low_frontier,
            closure_richness = high_closure,
        ),
        config,
    )
    poor_high = _finite_reference_value(
        _parameter_replace(
            parameters;
            frontier_level = high_frontier,
            closure_richness = low_closure,
        ),
        config,
    )
    rich_high = _finite_reference_value(
        _parameter_replace(
            parameters;
            frontier_level = high_frontier,
            closure_richness = high_closure,
        ),
        config,
    )
    return (rich_high - poor_high) - (rich_low - poor_low)
end

function _exact_core(parameters, config)
    bundle = build_exact_comparative_process(parameters, config)
    result = raw_infinite_horizon_policy_iteration(
        bundle.process;
        max_iterations = config.max_iterations,
    )
    belief = bundle.catalog.beliefs.states[config.reference_index]
    model = _compile_dense_comparative_model(parameters, config)
    passive = _passive_values(model)
    total = state_value(result, belief, bundle.base)
    candidate_total = state_value(result, belief, bundle.candidate_library)
    pruned_total = state_value(result, belief, bundle.pruned)
    base_passive = passive[config.reference_index, 1]
    candidate_passive = passive[config.reference_index, 2]
    policy = Symbol[
        policy_action(result, current, bundle.base) isa ResearchAction ?
        :research : :continue for current in bundle.catalog.beliefs
    ]
    return (;
        model,
        bundle,
        total,
        passive = base_passive,
        premium = total - base_passive,
        operational = candidate_passive - base_passive,
        generative =
            (candidate_total - candidate_passive) - (total - base_passive),
        pruning_loss = total - pruned_total,
        compression_ratio = _compression_ratio(bundle.base, bundle.safe),
        descendant_quality = _descendant_quality(model, config.reference_index),
        policy,
        residual = result.bellman_residual,
        error_bound = zero(ExactRational),
        iterations = result.iterations,
        converged = result.converged,
        sparse_mode = false,
        raw_source = true,
    )
end

function _float_core(parameters, config)
    model = _compile_comparative_model(parameters, config)
    solve = _float_value_iteration(model, config)
    passive = _passive_values(model)
    structural = _comparative_catalog(parameters, config)
    reference = config.reference_index
    policy = Symbol[
        solve.policy[index, 1] ? :research : :continue for
        index in 1:config.belief_count
    ]
    return (;
        model,
        structural,
        total = solve.values[reference, 1],
        passive = passive[reference, 1],
        premium = solve.values[reference, 1] - passive[reference, 1],
        operational = passive[reference, 2] - passive[reference, 1],
        generative =
            (solve.values[reference, 2] - passive[reference, 2]) -
            (solve.values[reference, 1] - passive[reference, 1]),
        pruning_loss = solve.values[reference, 1] - passive[reference, 1],
        compression_ratio = _compression_ratio(structural.base, structural.safe),
        descendant_quality = _descendant_quality(model, reference),
        policy,
        residual = solve.residual,
        error_bound = solve.error_bound,
        iterations = solve.iterations,
        converged = solve.converged,
        sparse_mode = model.kernel isa SparseMatrixCSC,
        raw_source = true,
    )
end

"""
    run_unified_comparative_statics(parameters, config)

Solve the unified model and return every requested outcome. Exact inputs route
through [`build_exact_comparative_process`](@ref) and exact raw policy
iteration. Float64 inputs use sparse value iteration with explicit residual
and posterior-error gates.
"""
function run_unified_comparative_statics(
    parameters::UnifiedComparativeParameters{T},
    config::ComparativeStaticsConfig{T},
) where {T<:Union{ExactRational,Float64}}
    core = T == ExactRational ?
           _exact_core(parameters, config) : _float_core(parameters, config)
    region = BitVector(action == :research for action in core.policy)
    cutoff_kind, cutoff = _cutoff_diagnostic(region, core.model.coordinates)
    components = _research_components(region)
    gate_passed =
        core.converged &&
        core.residual <= config.residual_gate &&
        core.error_bound <= config.error_gate
    interaction = _interaction_diagnostic(parameters, config)
    flags = ComparativeStaticsFlags(
        !iszero(parameters.generator_frontier_dependence),
        true,
        true,
        config.operates_during_research,
        true,
        components > 1,
        !gate_passed,
    )
    frequency = exact_rational(count(region)) / exact_rational(length(region))
    typed_frequency = T == ExactRational ? frequency : Float64(frequency)
    return ComparativeStaticsResult{T}(
        parameters,
        core.total,
        core.passive,
        core.premium,
        core.operational,
        core.generative,
        typed_frequency,
        core.policy[config.reference_index],
        cutoff,
        cutoff_kind,
        core.pruning_loss,
        core.compression_ratio,
        core.descendant_quality,
        interaction,
        core.residual,
        core.error_bound,
        core.iterations,
        core.converged,
        gate_passed,
        core.sparse_mode,
        core.raw_source,
        core.policy,
        flags,
    )
end

function _comparison_tolerance(::Type{ExactRational}, config)
    return zero(ExactRational)
end
function _comparison_tolerance(::Type{Float64}, config)
    return max(config.residual_gate, config.value_tolerance)
end

function _sign_check(
    ::Type{T},
    id,
    theorem,
    expected,
    observed,
    applicable,
    passed,
    flag,
    detail,
) where {T<:Real}
    return ComparativeStaticsSignCheck{T}(
        id,
        theorem,
        expected,
        observed,
        applicable,
        !applicable || passed,
        flag,
        detail,
    )
end

"""
    run_comparative_static_sign_checks(parameters, config)

Run paired, one-at-a-time comparisons and tag each check with the exact Lean
family that supports it. A theorem check is marked inapplicable—not failed—
when its proof-critical assumptions are absent. Persistence, signal precision,
the Bellman cutoff, and T7 without a relative-saturation certificate are
therefore reported as explicit boundary regimes.
"""
function run_comparative_static_sign_checks(
    parameters::UnifiedComparativeParameters{T},
    config::ComparativeStaticsConfig{T},
) where {T<:Union{ExactRational,Float64}}
    tolerance = _comparison_tolerance(T, config)
    step = config.parameter_step
    solve = candidate -> run_unified_comparative_statics(candidate, config)
    checks = ComparativeStaticsSignCheck{T}[]

    low_frontier = solve(
        _parameter_replace(
            parameters;
            frontier_level = max(zero(T), parameters.frontier_level - step),
        ),
    )
    high_frontier = solve(
        _parameter_replace(
            parameters;
            frontier_level = parameters.frontier_level + step,
        ),
    )
    frontier_difference = high_frontier.total_value - low_frontier.total_value
    frontier_applicable = iszero(parameters.generator_frontier_dependence)
    push!(
        checks,
        _sign_check(
            T,
            :frontier_value,
            "CS1",
            :nonnegative,
            frontier_difference,
            frontier_applicable,
            frontier_difference >= -tolerance,
            frontier_applicable ? :none : :frontier_dependent_generator,
            "Full-value frontier order requires fixed, frontier-independent opportunities.",
        ),
    )
    operational_difference =
        high_frontier.operational_innovation -
        low_frontier.operational_innovation
    push!(
        checks,
        _sign_check(
            T,
            :frontier_operational_saturation,
            "CS1",
            :nonpositive,
            operational_difference,
            true,
            operational_difference <= tolerance,
            :none,
            "A fixed candidate's passive insertion value is antitone in the incumbent frontier.",
        ),
    )

    low_cost = solve(
        _parameter_replace(
            parameters;
            research_cost = max(zero(T), parameters.research_cost - step),
        ),
    )
    high_cost = solve(
        _parameter_replace(
            parameters;
            research_cost = parameters.research_cost + step,
        ),
    )
    cost_difference = low_cost.total_value - high_cost.total_value
    push!(
        checks,
        _sign_check(
            T,
            :research_cost_value,
            "CS1",
            :nonnegative,
            cost_difference,
            true,
            cost_difference >= -tolerance,
            :none,
            "Only the research-cost schedule changes.",
        ),
    )
    region_inclusion = all(
        high_cost.policy[index] != :research ||
        low_cost.policy[index] == :research for index in eachindex(low_cost.policy)
    )
    push!(
        checks,
        _sign_check(
            T,
            :research_cost_region,
            "CS1",
            :set_inclusion,
            region_inclusion ? one(T) : zero(T),
            true,
            region_inclusion,
            :none,
            "The higher-cost weak research set must be contained in the lower-cost set.",
        ),
    )

    for (id, field, theorem) in (
        (:admission_value, :admission_probability, "CS1"),
        (:survival_value, :candidate_survival, "CS1"),
        (:closure_value, :closure_richness, "CS1/T5"),
    )
        current = getfield(parameters, field)
        low_value = max(zero(T), current - step)
        high_value = min(one(T), current + step)
        low_parameters =
            field == :admission_probability ?
            _parameter_replace(parameters; admission_probability = low_value) :
            field == :candidate_survival ?
            _parameter_replace(parameters; candidate_survival = low_value) :
            _parameter_replace(parameters; closure_richness = low_value)
        high_parameters =
            field == :admission_probability ?
            _parameter_replace(parameters; admission_probability = high_value) :
            field == :candidate_survival ?
            _parameter_replace(parameters; candidate_survival = high_value) :
            _parameter_replace(parameters; closure_richness = high_value)
        difference = solve(high_parameters).total_value - solve(low_parameters).total_value
        push!(
            checks,
            _sign_check(
                T,
                id,
                theorem,
                :nonnegative,
                difference,
                true,
                difference >= -tolerance,
                :none,
                "Candidate admission is insertion-only, so success weakly dominates failure.",
            ),
        )
    end

    model = T == ExactRational ?
            _compile_dense_comparative_model(parameters, config) :
            _compile_comparative_model(parameters, config)
    gap = max.(model.frontier[:, 2] .- model.frontier[:, 1], zero(T))
    beta0 = max(zero(T), parameters.discount_factor - step)
    beta1 = min(T == ExactRational ? exact_rational(99 // 100) : T(0.99), parameters.discount_factor + step)
    rho0 = max(zero(T), parameters.candidate_survival - step)
    rho1 = min(one(T), parameters.candidate_survival + step)
    belief_space = FiniteBeliefSpace(collect(1:config.belief_count))
    kernel = T == ExactRational ?
             MarkovKernel(belief_space, Matrix(model.kernel)) :
             MarkovKernel(
        belief_space,
        Matrix(model.kernel);
        mode = Float64Mode(),
    )
    interaction = finite_discount_survival_interaction(
        kernel,
        gap,
        beta0,
        beta1,
        rho0,
        rho1,
        config.finite_horizon,
    )
    minimum_interaction = minimum(interaction.cross_difference)
    push!(
        checks,
        _sign_check(
            T,
            :discount_survival_cross_difference,
            "S6",
            :nonnegative,
            minimum_interaction,
            true,
            minimum_interaction >= -tolerance,
            :none,
            "Finite nonnegative-gap patience-survival complementarity.",
        ),
    )
    push!(
        checks,
        _sign_check(
            T,
            :persistence_direction,
            "S7",
            :no_universal_sign,
            zero(T),
            false,
            true,
            :persistence_unaligned,
            "A scalar persistence change has no sign without gap-aligned occupation dominance.",
        ),
    )
    push!(
        checks,
        _sign_check(
            T,
            :research_duration,
            "CS1",
            :nonpositive,
            zero(T),
            false,
            true,
            :no_waiting_gain_unverified,
            "Active operation and changing terminal occupation do not satisfy the scalar no-waiting-gain certificate automatically.",
        ),
    )
    push!(
        checks,
        _sign_check(
            T,
            :frontier_closure_J,
            "T7",
            :nonpositive,
            run_unified_comparative_statics(parameters, config).frontier_closure_cross_difference,
            false,
            true,
            :relative_saturation_unverified,
            "Frontier-independent primitives alone do not imply J ≤ 0; relative action saturation must be certified.",
        ),
    )
    return checks
end

function _fixture_row(id, theorem, observed, expected, passed, detail)
    return (
        fixture_id = id,
        theorem_id = theorem,
        observed = observed,
        expected = expected,
        passed,
        detail,
    )
end

"""
    exact_comparative_statics_fixtures()

Reproduce selected exact Lean fixtures used by the unified comparative-static
claim boundary: raw T4/S2, T6, S6, S7, and T7. The function returns
machine-renderable rows and throws no claim beyond equality on these finite
inputs.
"""
function exact_comparative_statics_fixtures()
    parameters = UnifiedComparativeParameters(
        frontier_level = 0,
        frontier_density = 1,
        closure_richness = 1,
        module_overlap = 0,
        research_cost = 0,
        research_duration = 1,
        admission_probability = 1,
        candidate_survival = 1,
        discount_factor = 1 // 2,
        belief_kernel_persistence = 1,
        signal_precision_proxy = 0,
        candidate_profile_quality = 2,
        generator_frontier_dependence = 0,
    )
    config = ComparativeStaticsConfig(
        belief_count = 1,
        reference_index = 1,
        finite_horizon = 2,
    )
    bundle = build_exact_comparative_process(parameters, config)
    belief = first(bundle.catalog.beliefs.states)
    stationary = raw_infinite_horizon_policy_iteration(bundle.process)
    base_value = state_value(stationary, belief, bundle.base)
    descendant_value = state_value(stationary, belief, bundle.candidate_library)
    pruning_loss =
        raw_finite_horizon_value(bundle.process, 2, belief, bundle.base) -
        raw_finite_horizon_value(bundle.process, 2, belief, bundle.pruned)
    base_action = policy_action(stationary, belief, bundle.base)
    descendant_action = policy_action(stationary, belief, bundle.candidate_library)

    rows = NamedTuple[]
    push!(
        rows,
        _fixture_row(
            "FX-T4-UNIFIED-01",
            "T4",
            string(pruning_loss),
            "1//1",
            pruning_loss == 1,
            "Two-calendar-period raw frontier-only pruning loss.",
        ),
    )
    push!(
        rows,
        _fixture_row(
            "FX-S2-UNIFIED-STATIONARY-01/base",
            "S2",
            string(base_value),
            "2//1",
            base_value == 2 && base_action isa ResearchAction,
            "Raw stationary base value and Research selector.",
        ),
    )
    push!(
        rows,
        _fixture_row(
            "FX-S2-UNIFIED-STATIONARY-01/descendant",
            "S2",
            string(descendant_value),
            "4//1",
            descendant_value == 4 &&
            descendant_action isa ContinueAction &&
            stationary.bellman_residual == 0 &&
            stationary.policy_equation_residual == 0,
            "Raw descendant value, Continue selector, and zero exact residuals.",
        ),
    )

    t6 = generative_lower_bound_fixture()
    push!(
        rows,
        _fixture_row(
            "FX-T6-CARRIER-01",
            "T6",
            string(t6.lower_bound),
            "1//1",
            t6.lower_bound == 1,
            "Cost-adjusted retained-carrier lower bound.",
        ),
    )

    s6_space = FiniteBeliefSpace([:low, :high])
    s6_kernel = MarkovKernel(s6_space, [3 // 4 1 // 4; 1 // 2 1 // 2])
    s6 = finite_discount_survival_interaction(
        s6_kernel,
        ExactRational[1, 3],
        1 // 4,
        3 // 4,
        1 // 3,
        2 // 3,
        5,
    )
    s6_expected = ExactRational[43771 // 55296, 24869 // 27648]
    push!(
        rows,
        _fixture_row(
            "FX-S6-CROSS-01",
            "S6",
            join(string.(s6.cross_difference), ";"),
            join(string.(s6_expected), ";"),
            s6.cross_difference == s6_expected && s6.factorization_holds,
            "Factorized finite discount-survival cross difference.",
        ),
    )

    switch_kernel = MarkovKernel(s6_space, [0 1; 1 0])
    persistences = ExactRational[1 // 4, 3 // 4]
    current_rows = persistence_coverage_response_surface(
        switch_kernel,
        ExactRational[1, 0],
        persistences,
        ExactRational[1 // 2],
        2,
    )
    other_rows = persistence_coverage_response_surface(
        switch_kernel,
        ExactRational[0, 1],
        persistences,
        ExactRational[1 // 2],
        2,
    )
    constant_rows = persistence_coverage_response_surface(
        switch_kernel,
        ExactRational[1, 1],
        persistences,
        ExactRational[1 // 2],
        2,
    )
    observed_s7 = ExactRational[
        current_rows[1].coverage,
        current_rows[2].coverage,
        other_rows[1].coverage,
        other_rows[2].coverage,
        constant_rows[1].coverage,
        constant_rows[2].coverage,
    ]
    expected_s7 = ExactRational[9 // 8, 11 // 8, 3 // 8, 1 // 8, 3 // 2, 3 // 2]
    push!(
        rows,
        _fixture_row(
            "FX-S7-PERSISTENCE-01",
            "S7",
            join(string.(observed_s7), ";"),
            join(string.(expected_s7), ";"),
            observed_s7 == expected_s7,
            "Higher persistence raises, lowers, or leaves coverage unchanged by gap location.",
        ),
    )

    surface = frontier_closure_interaction_surface(
        ExactRational[0, 2, 8],
        ExactRational[4, 10],
        ExactRational[0, 1 // 2, 1],
        ExactRational[0, 1 // 2, 1],
        ExactRational[0, 2],
        ExactRational[0, 2];
        discount = exact_rational(1 // 2),
    )
    substitute = only(
        row for row in surface if
        row.frontier0 == 0 &&
        row.frontier1 == 2 &&
        row.candidate == 4 &&
        row.old_success == 0 &&
        row.added_success == 1 &&
        row.old_cost == 0 &&
        row.added_cost == 0
    )
    switch = only(
        row for row in surface if
        row.frontier0 == 0 &&
        row.frontier1 == 8 &&
        row.candidate == 10 &&
        row.old_success == 1 &&
        row.added_success == 1 // 2 &&
        row.old_cost == 2 &&
        row.added_cost == 0
    )
    push!(
        rows,
        _fixture_row(
            "FX-T7-SUBSTITUTION-01",
            "T7",
            string(substitute.interaction),
            "-1//1",
            substitute.interaction == -1,
            "Strict relative-saturation substitution witness.",
        ),
    )
    push!(
        rows,
        _fixture_row(
            "CX-T7-INDEPENDENT-MENU-SWITCH-02",
            "T7 boundary",
            string(switch.interaction),
            "1//2",
            switch.interaction == 1 // 2,
            "Frontier-independent project switching violates the rejected primitive-only sign.",
        ),
    )
    return (
        parameters,
        config,
        rows,
        all_passed = all(row.passed for row in rows),
    )
end
