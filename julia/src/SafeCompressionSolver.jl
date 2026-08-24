import HiGHS
import JuMP

export build_safe_compression_milp,
       certify_safe_compression,
       solve_safe_compression_milp

const _SAFE_COMPRESSION_MOI = JuMP.MOI
const _MAX_EXACT_FLOAT_INTEGER = BigInt(1) << 53

function _aligned_safe_compression_weights(
    formulation::BinaryCompressionFormulation,
    strategy_weights,
    objective::Symbol,
)
    objective in (:weight, :cardinality) ||
        throw(ArgumentError("objective must be :weight or :cardinality"))
    strategy_count = length(formulation.strategy_ids)
    if isnothing(strategy_weights)
        objective == :cardinality ||
            throw(ArgumentError("strategy_weights are required for :weight optimization"))
        resource_weights = ExactRational[
            index == formulation.inactive_index ? 0 // 1 : 1 // 1 for
            index in 1:strategy_count
        ]
    elseif strategy_weights isa AbstractVector
        length(strategy_weights) == strategy_count ||
            throw(DimensionMismatch("strategy_weights must align with formulation columns"))
        resource_weights = ExactRational[
            exact_rational(weight) for weight in strategy_weights
        ]
    elseif strategy_weights isa AbstractDict
        missing_ids = [
            strategy_id for strategy_id in formulation.strategy_ids if
            !haskey(strategy_weights, strategy_id)
        ]
        isempty(missing_ids) ||
            throw(ArgumentError("strategy_weights are missing IDs: $missing_ids"))
        resource_weights = ExactRational[
            exact_rational(strategy_weights[strategy_id]) for
            strategy_id in formulation.strategy_ids
        ]
    else
        throw(
            ArgumentError(
                "strategy_weights must be nothing, an aligned vector, or a dictionary",
            ),
        )
    end

    iszero(resource_weights[formulation.inactive_index]) ||
        throw(ArgumentError("the mandatory inactive strategy must have zero weight"))
    for index in eachindex(resource_weights)
        index == formulation.inactive_index && continue
        resource_weights[index] > 0 ||
            throw(ArgumentError("every active strategy must have positive exact weight"))
    end

    objective_weights = if objective == :weight
        copy(resource_weights)
    else
        ExactRational[
            index == formulation.inactive_index ? 0 // 1 : 1 // 1 for
            index in 1:strategy_count
        ]
    end
    return resource_weights, objective_weights
end

function _scaled_safe_compression_objective(
    objective_weights::Vector{ExactRational},
)
    scale = foldl(
        lcm,
        (BigInt(denominator(weight)) for weight in objective_weights);
        init = BigInt(1),
    )
    scaled_big = BigInt[
        numerator(weight) * div(scale, denominator(weight)) for
        weight in objective_weights
    ]
    all(>=(BigInt(0)), scaled_big) ||
        throw(ArgumentError("safe-compression objective weights must be nonnegative"))
    sum(scaled_big; init = BigInt(0)) <= _MAX_EXACT_FLOAT_INTEGER ||
        throw(
            ArgumentError(
                "the scaled objective exceeds exact Float64 integer representation; " *
                "rescale the resource unit or use exact enumeration",
            ),
        )
    scaled = Int64[Int64(coefficient) for coefficient in scaled_big]
    all(BigInt(scaled[index]) == scaled_big[index] for index in eachindex(scaled)) ||
        error("internal scaled-objective conversion lost an integer coefficient")
    return scale, scaled
end

function _safe_compression_problem_data(
    catalog::StrategyCatalog{S,B,M,ExactRational},
    closure::GenerativeClosure{M},
    source::RawLibrary{S},
    strategy_weights,
    objective::Symbol,
) where {S,B,M}
    formulation = minimum_safe_compression_ip_formulation(
        catalog,
        closure,
        source,
    )
    resource_weights, objective_weights = _aligned_safe_compression_weights(
        formulation,
        strategy_weights,
        objective,
    )
    scale, scaled_objective =
        _scaled_safe_compression_objective(objective_weights)
    return (
        formulation = formulation,
        resource_weights = resource_weights,
        objective_weights = objective_weights,
        objective_scale = scale,
        scaled_objective = scaled_objective,
    )
end

_is_identity_closure(closure::GenerativeClosure) =
    all(first(entry) == last(entry) for entry in closure.table)

"""
    build_safe_compression_milp(catalog, closure, source;
                                strategy_weights=nothing,
                                objective=:cardinality, silent=true,
                                time_limit=nothing, threads=1)

Translate the exact solver-neutral [`BinaryCompressionFormulation`](@ref) to
a JuMP model backed by HiGHS. Strategy variables are binary, the inactive
strategy is fixed to one, each belief-frontier row is covered, and general
closure is represented by binary generator-choice variables and module-
carrier implications. For identity closure, the unique minimal generator is
the target module set, yielding one carrier-cover requirement per module.

Rational objectives are converted to a common nonnegative integer scale. The
builder rejects objectives whose complete integer range cannot be represented
exactly by HiGHS's `Float64` affine interface. Building or solving this model
does not itself certify exact safety; use [`solve_safe_compression_milp`](@ref)
or [`certify_safe_compression`](@ref).
"""
function build_safe_compression_milp(
    catalog::StrategyCatalog{S,B,M,ExactRational},
    closure::GenerativeClosure{M},
    source::RawLibrary{S};
    strategy_weights = nothing,
    objective::Symbol = :cardinality,
    silent::Bool = true,
    time_limit = nothing,
    threads::Integer = 1,
) where {S,B,M}
    threads >= 1 || throw(ArgumentError("threads must be positive"))
    if !isnothing(time_limit)
        time_limit isa Real && time_limit > 0 ||
            throw(ArgumentError("time_limit must be a positive real or nothing"))
    end
    data = _safe_compression_problem_data(
        catalog,
        closure,
        source,
        strategy_weights,
        objective,
    )
    formulation = data.formulation
    model = JuMP.Model(HiGHS.Optimizer)
    silent && JuMP.set_silent(model)
    JuMP.set_attribute(model, "threads", Int(threads))
    JuMP.set_attribute(model, "random_seed", 0)
    JuMP.set_attribute(model, "mip_abs_gap", 0.0)
    JuMP.set_attribute(model, "mip_rel_gap", 0.0)
    isnothing(time_limit) ||
        JuMP.set_attribute(model, "time_limit", Float64(time_limit))

    strategy_count = length(formulation.strategy_ids)
    generator_count = length(formulation.closure_generators)
    closure_kind = _is_identity_closure(closure) ? :identity : :general
    JuMP.@variable(model, x[1:strategy_count], Bin)
    JuMP.@constraint(model, x[formulation.inactive_index] == 1)

    for belief_row in axes(formulation.frontier_cover, 1)
        attainers = Int[
            column for column in axes(formulation.frontier_cover, 2) if
            formulation.frontier_cover[belief_row, column]
        ]
        isempty(attainers) &&
            error("an exact finite source frontier must have an attainer")
        JuMP.@constraint(model, sum(x[column] for column in attainers) >= 1)
    end

    y = JuMP.VariableRef[]
    closure_constraint_count = 0
    generator_selection_constraint_count = 0
    if closure_kind == :general
        JuMP.@variable(model, generator_choice[1:generator_count], Bin)
        y = collect(generator_choice)
        JuMP.@constraint(model, sum(y) >= 1)
        generator_selection_constraint_count = 1
    else
        generator_count == 1 ||
            error("identity closure must have one minimal target generator")
    end
    for (generator_index, generator) in enumerate(formulation.closure_generators)
        closure_kind == :identity && generator_index != 1 && continue
        for module_id in generator
            module_row = findfirst(==(module_id), formulation.modules)
            isnothing(module_row) &&
                error("a closure generator contains an unknown module")
            carriers = Int[
                column for column in axes(formulation.module_supply, 2) if
                formulation.module_supply[module_row, column]
            ]
            isempty(carriers) &&
                error("a source closure generator module has no carrier")
            JuMP.@constraint(
                model,
                sum(x[column] for column in carriers) >=
                (closure_kind == :identity ? 1 : y[generator_index]),
            )
            closure_constraint_count += 1
        end
    end
    JuMP.@objective(
        model,
        Min,
        sum(
            data.scaled_objective[index] * x[index] for
            index in eachindex(data.scaled_objective)
        ),
    )
    return (;
        data...,
        model = model,
        x = collect(x),
        y = collect(y),
        objective = objective,
        closure_kind = closure_kind,
        frontier_constraint_count = size(formulation.frontier_cover, 1),
        closure_constraint_count = closure_constraint_count,
        generator_count = generator_count,
        generator_variable_count = length(y),
        generator_selection_constraint_count =
            generator_selection_constraint_count,
        linear_constraint_count = 1 + size(formulation.frontier_cover, 1) +
                                  closure_constraint_count +
                                  generator_selection_constraint_count,
    )
end

function _exact_safe_deletion_trace(
    catalog::StrategyCatalog{S},
    closure::GenerativeClosure,
    source::RawLibrary{S},
    selected::RawLibrary{S},
) where {S}
    current = source
    libraries = RawLibrary{S}[source]
    deletions = StrategyId{S}[]
    target_state = compressed_state(catalog, closure, source)
    for row in catalog.strategies
        strategy_id = row.id
        strategy_id == catalog.inactive_strategy && continue
        strategy_id in current || continue
        strategy_id in selected && continue
        candidate = delete_strategy(catalog, current, strategy_id)
        compressed_state(catalog, closure, candidate) == target_state ||
            error("exact deletion trace contains an unsafe intermediate library")
        current = candidate
        push!(deletions, strategy_id)
        push!(libraries, current)
    end
    current == selected ||
        error("exact deletion trace did not terminate at the selected library")
    return (
        deletions = deletions,
        libraries = libraries,
        endpoint = current,
        all_steps_exact_safe = true,
    )
end


function _certify_safe_compression_selection(
    catalog::StrategyCatalog{S,B,M,ExactRational},
    closure::GenerativeClosure{M},
    source::RawLibrary{S},
    data,
    selected::RawLibrary{S},
    include_deletion_trace::Bool,
) where {S,B,M}
    validate_library(catalog, selected)
    issubset(selected, source) ||
        error("exact post-solve verification failed: selection is not a sublibrary")
    selected_vector = Bool[
        strategy_id in selected for strategy_id in data.formulation.strategy_ids
    ]
    satisfies_compression_formulation(data.formulation, selected_vector) ||
        error("exact post-solve verification failed: binary constraints are violated")

    source_frontier = frontier(catalog, source)
    selected_frontier = frontier(catalog, selected)
    source_closure = generative_closure(catalog, closure, source)
    selected_closure = generative_closure(catalog, closure, selected)
    source_frontier == selected_frontier ||
        error("exact post-solve verification failed: frontier is not preserved")
    source_closure == selected_closure ||
        error("exact post-solve verification failed: closure is not preserved")

    burden = sum(
        (
            data.resource_weights[index] for index in eachindex(selected_vector) if
            selected_vector[index]
        );
        init = zero(ExactRational),
    )
    objective_value = sum(
        (
            data.objective_weights[index] for index in eachindex(selected_vector) if
            selected_vector[index]
        );
        init = zero(ExactRational),
    )
    scaled_objective_value = sum(
        (
            data.scaled_objective[index] for index in eachindex(selected_vector) if
            selected_vector[index]
        );
        init = Int64(0),
    )
    exact_rational(scaled_objective_value) / exact_rational(data.objective_scale) ==
    objective_value ||
        error("exact post-solve verification failed: scaled objective is inconsistent")
    trace = if include_deletion_trace
        _exact_safe_deletion_trace(
            catalog,
            closure,
            source,
            selected,
        )
    else
        nothing
    end
    return (
        library = selected,
        selected_vector = selected_vector,
        selected_strategy_ids = collect(selected.strategies),
        objective = objective_value,
        scaled_objective = scaled_objective_value,
        burden = burden,
        active_cardinality = length(selected) - 1,
        frontier = selected_frontier,
        closure = selected_closure,
        deletion_trace = trace,
        exact_certificate = (
            arithmetic = ExactRational,
            sublibrary = true,
            formulation_satisfied = true,
            frontier_preserved = true,
            closure_preserved = true,
            scaled_objective_reconciled = true,
            selected_library_verified = true,
            deletion_trace_verified = include_deletion_trace ? true : missing,
        ),
    )
end

"""
    certify_safe_compression(catalog, closure, source, selected;
                             strategy_weights=nothing,
                             objective=:cardinality,
                             include_deletion_trace=false)

Recompute a proposed compressed library entirely with exact finite objects.
The function throws if the proposal is not a source sublibrary, violates the
binary formulation, changes the rational frontier, changes the general module
closure, or has inconsistent exact objective arithmetic. Optionally include
an exactly rechecked deletion trace in the returned certificate.
"""
function certify_safe_compression(
    catalog::StrategyCatalog{S,B,M,ExactRational},
    closure::GenerativeClosure{M},
    source::RawLibrary{S},
    selected::RawLibrary{S};
    strategy_weights = nothing,
    objective::Symbol = :cardinality,
    include_deletion_trace::Bool = false,
) where {S,B,M}
    data = _safe_compression_problem_data(
        catalog,
        closure,
        source,
        strategy_weights,
        objective,
    )
    return _certify_safe_compression_selection(
        catalog,
        closure,
        source,
        data,
        selected,
        include_deletion_trace,
    )
end

function _library_from_solver_vector(
    catalog::StrategyCatalog{S},
    formulation::BinaryCompressionFormulation{S},
    raw_values::Vector{Float64},
) where {S}
    all(isfinite, raw_values) ||
        error("the solver returned a nonfinite binary-variable value")
    selected = Bool[value >= 0.5 for value in raw_values]
    ids = StrategyId{S}[
        formulation.strategy_ids[index] for index in eachindex(selected) if
        selected[index]
    ]
    return RawLibrary(catalog, ids), selected
end

function _add_safe_compression_no_good!(model, x, selected::Vector{Bool})
    expression = JuMP.AffExpr(count(selected))
    for index in eachindex(selected)
        JuMP.add_to_expression!(
            expression,
            selected[index] ? -1 : 1,
            x[index],
        )
    end
    JuMP.@constraint(model, expression >= 1)
    return nothing
end

function _exact_safe_compression_enumeration(
    catalog::StrategyCatalog{S,B,M,ExactRational},
    closure::GenerativeClosure{M},
    source::RawLibrary{S},
    data,
    maximum_optional::Integer,
) where {S,B,M}
    optional_indices = Int[
        index for index in eachindex(data.formulation.strategy_ids) if
        index != data.formulation.inactive_index
    ]
    optional_count = length(optional_indices)
    optional_count <= maximum_optional || return nothing
    optional_count <= 62 || return nothing
    target_state = compressed_state(catalog, closure, source)
    best::Union{Nothing,ExactRational} = nothing
    optimal_vectors = Vector{Bool}[]
    enumerated = Int(1) << optional_count
    for mask in UInt64(0):UInt64(enumerated - 1)
        selected = falses(length(data.formulation.strategy_ids))
        selected[data.formulation.inactive_index] = true
        for (bit_index, column) in enumerate(optional_indices)
            selected[column] = !iszero(mask & (UInt64(1) << (bit_index - 1)))
        end
        ids = StrategyId{S}[
            data.formulation.strategy_ids[index] for index in eachindex(selected) if
            selected[index]
        ]
        candidate = RawLibrary(catalog, ids)
        compressed_state(catalog, closure, candidate) == target_state || continue
        value = sum(
            (
                data.objective_weights[index] for index in eachindex(selected) if
                selected[index]
            );
            init = zero(ExactRational),
        )
        if isnothing(best) || value < best
            best = value
            empty!(optimal_vectors)
            push!(optimal_vectors, selected)
        elseif value == best
            push!(optimal_vectors, selected)
        end
    end
    isnothing(best) && error("the source library must be exactly safe feasible")
    return (
        optimal_objective = best,
        optimal_vectors = optimal_vectors,
        enumerated_sublibraries = enumerated,
    )
end

function _safe_node_count(model)
    try
        return Int(JuMP.node_count(model))
    catch
        return missing
    end
end

"""
    solve_safe_compression_milp(catalog, closure, source;
                                strategy_weights=nothing,
                                objective=:cardinality,
                                enumerate_all_optima=false,
                                maximum_optima=10_000,
                                exact_enumeration_limit=16,
                                include_deletion_trace=false,
                                silent=true, time_limit=nothing, threads=1)

Solve exact safe compression through JuMP and HiGHS, then treat each solver
vector only as a candidate. Every returned library is reconstructed and
checked with `Rational{BigInt}` frontier arithmetic, exact general closure,
the solver-neutral binary formulation, and exact burden/objective arithmetic.
Any mismatch throws. Set `include_deletion_trace=true` to additionally return
and exactly recheck every intermediate deletion; the default selected-library
certificate avoids the trace's quadratic-size work on large libraries.

When `enumerate_all_optima=true`, the routine fixes the exactly recomputed
scaled integer objective and adds no-good cuts until HiGHS reports the optimal
face exhausted or `maximum_optima` is reached. If the number of optional
source strategies does not exceed `exact_enumeration_limit`, independent
exhaustive enumeration certifies the global objective and, when requested,
the complete tie set. For larger instances, solver optimality and exact safety
are reported separately; solver tolerances are never labeled an exact proof.
"""
function solve_safe_compression_milp(
    catalog::StrategyCatalog{S,B,M,ExactRational},
    closure::GenerativeClosure{M},
    source::RawLibrary{S};
    strategy_weights = nothing,
    objective::Symbol = :cardinality,
    enumerate_all_optima::Bool = false,
    maximum_optima::Integer = 10_000,
    exact_enumeration_limit::Union{Nothing,Integer} = 16,
    include_deletion_trace::Bool = false,
    silent::Bool = true,
    time_limit = nothing,
    threads::Integer = 1,
) where {S,B,M}
    maximum_optima >= 1 || throw(ArgumentError("maximum_optima must be positive"))
    if !isnothing(exact_enumeration_limit)
        0 <= exact_enumeration_limit <= 62 ||
            throw(ArgumentError("exact_enumeration_limit must be in 0:62 or nothing"))
    end
    milp = build_safe_compression_milp(
        catalog,
        closure,
        source;
        strategy_weights = strategy_weights,
        objective = objective,
        silent = silent,
        time_limit = time_limit,
        threads = threads,
    )
    reports = NamedTuple[]
    solver_runs = NamedTuple[]
    best_objective::Union{Nothing,ExactRational} = nothing
    best_scaled::Union{Nothing,Int64} = nothing
    optimal_face_fixed = false
    solver_exhausted_optimal_face = false
    truncated = false

    while true
        JuMP.optimize!(milp.model)
        termination = JuMP.termination_status(milp.model)
        primal = JuMP.primal_status(milp.model)
        raw = JuMP.raw_status(milp.model)
        if !isempty(reports) && termination == _SAFE_COMPRESSION_MOI.INFEASIBLE
            solver_exhausted_optimal_face = true
            push!(
                solver_runs,
                (
                    termination_status = termination,
                    primal_status = primal,
                    raw_status = raw,
                    solve_time_seconds = JuMP.solve_time(milp.model),
                    node_count = _safe_node_count(milp.model),
                ),
            )
            break
        end
        termination == _SAFE_COMPRESSION_MOI.OPTIMAL ||
            error("HiGHS did not report an optimal solution: $termination ($raw)")
        primal == _SAFE_COMPRESSION_MOI.FEASIBLE_POINT ||
            error("HiGHS did not return a feasible primal point: $primal")

        raw_values = Float64[JuMP.value(variable) for variable in milp.x]
        selected_library, rounded_selection = _library_from_solver_vector(
            catalog,
            milp.formulation,
            raw_values,
        )
        report = _certify_safe_compression_selection(
            catalog,
            closure,
            source,
            milp,
            selected_library,
            include_deletion_trace,
        )
        report.selected_vector == rounded_selection ||
            error("solver-vector reconstruction changed the selected library")
        if isnothing(best_objective)
            best_objective = report.objective
            best_scaled = report.scaled_objective
        else
            report.objective == best_objective ||
                error("solver returned a library outside the exact optimal face")
            report.scaled_objective == best_scaled ||
                error("solver returned an inconsistent scaled optimal objective")
        end
        any(existing.library == report.library for existing in reports) &&
            error("solver optimal-face enumeration returned a duplicate library")
        push!(reports, report)
        push!(
            solver_runs,
            (
                termination_status = termination,
                primal_status = primal,
                raw_status = raw,
                solve_time_seconds = JuMP.solve_time(milp.model),
                node_count = _safe_node_count(milp.model),
                raw_binary_values = raw_values,
                maximum_integrality_residual = maximum(
                    abs(value - round(value)) for value in raw_values
                ),
                numerical_objective = JuMP.objective_value(milp.model),
            ),
        )

        enumerate_all_optima || break
        if length(reports) >= maximum_optima
            truncated = true
            break
        end
        if !optimal_face_fixed
            JuMP.@constraint(
                milp.model,
                sum(
                    milp.scaled_objective[index] * milp.x[index] for
                    index in eachindex(milp.x)
                ) == best_scaled,
            )
            optimal_face_fixed = true
        end
        _add_safe_compression_no_good!(
            milp.model,
            milp.x,
            rounded_selection,
        )
    end

    exhaustive = isnothing(exact_enumeration_limit) ? nothing :
                 _exact_safe_compression_enumeration(
        catalog,
        closure,
        source,
        milp,
        exact_enumeration_limit,
    )
    exact_optimality_verified = !isnothing(exhaustive)
    complete_tie_set_exactly_verified = false
    if !isnothing(exhaustive)
        exhaustive.optimal_objective == best_objective ||
            error("HiGHS objective disagrees with exact exhaustive enumeration")
        solver_vectors = Set(Tuple(report.selected_vector) for report in reports)
        exact_vectors = Set(Tuple(vector) for vector in exhaustive.optimal_vectors)
        all(vector -> vector in exact_vectors, solver_vectors) ||
            error("HiGHS returned a nonoptimal exact library")
        if enumerate_all_optima && solver_exhausted_optimal_face && !truncated
            solver_vectors == exact_vectors ||
                error("HiGHS optimal-face enumeration missed an exact optimum")
            complete_tie_set_exactly_verified = true
        end
    end

    return (
        optimal_objective = best_objective,
        optimal_libraries = [report.library for report in reports],
        burdens = ExactRational[report.burden for report in reports],
        active_cardinalities = [report.active_cardinality for report in reports],
        frontiers = [report.frontier for report in reports],
        closures = [report.closure for report in reports],
        deletion_traces = [report.deletion_trace for report in reports],
        selected_library_certificates = reports,
        formulation = (
            strategy_count = length(milp.formulation.strategy_ids),
            belief_count = length(milp.formulation.beliefs),
            module_count = length(milp.formulation.modules),
            frontier_constraint_count = milp.frontier_constraint_count,
            closure_constraint_count = milp.closure_constraint_count,
            generator_count = milp.generator_count,
            generator_variable_count = milp.generator_variable_count,
            generator_selection_constraint_count =
                milp.generator_selection_constraint_count,
            linear_constraint_count = milp.linear_constraint_count,
            closure_kind = milp.closure_kind,
            objective = objective,
            objective_scale = milp.objective_scale,
            scaled_objective = milp.scaled_objective,
        ),
        solver_certificate = (
            solver = :HiGHS,
            highs_julia_version = string(Base.pkgversion(HiGHS)),
            jump_version = string(Base.pkgversion(JuMP)),
            threads = Int(threads),
            runs = solver_runs,
            solver_claimed_optimal = true,
            enumerate_all_optima = enumerate_all_optima,
            solver_exhausted_optimal_face = solver_exhausted_optimal_face,
            truncated = truncated,
        ),
        exact_certificate = (
            arithmetic = ExactRational,
            every_returned_library_exactly_safe = all(
                report.exact_certificate.frontier_preserved &&
                report.exact_certificate.closure_preserved for report in reports
            ),
            every_objective_exactly_recomputed = true,
            every_selected_library_exactly_verified = true,
            every_deletion_trace_exactly_verified =
                include_deletion_trace ? true : missing,
            deletion_traces_included = include_deletion_trace,
            solver_tolerances_used_as_proof = false,
            exact_optimality_verified = exact_optimality_verified,
            complete_tie_set_exactly_verified =
                complete_tie_set_exactly_verified,
            exhaustive_sublibraries = isnothing(exhaustive) ? nothing :
                                      exhaustive.enumerated_sublibraries,
            exact_optimum_count = isnothing(exhaustive) ? nothing :
                                  length(exhaustive.optimal_vectors),
        ),
    )
end
