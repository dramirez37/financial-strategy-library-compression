const JOURNAL_MIP_SOLUTION_SCHEMA_VERSION =
    "journal-compression-mip-solution-v1"


"""Explicit deterministic HiGHS controls recorded with every MIP run."""
struct JournalMIPControls
    threads::Int
    parallel::String
    random_seed::Int
    time_limit_seconds::Union{Nothing,Float64}
    relative_mip_gap_tolerance::Float64
    absolute_mip_gap_tolerance::Float64
    presolve::String
    log_to_console::Bool
    complete_log_captured::Bool
end


"""Exact fixed-point preprocessing dimensions, mapping, and audit trail."""
struct JournalMIPPreprocessingSummary
    original_strategy_count::Int
    reduced_strategy_count::Int
    original_requirement_count::Int
    reduced_requirement_count::Int
    variables_removed::Int
    requirements_removed::Int
    forced_strategy_indices::Vector{Int}
    remaining_strategy_indices::Vector{Int}
    remaining_requirement_indices::Vector{Int}
    exact_objective_offset::ExactRational
    fixed_point_iterations::Int
    all_optimizer_identities_reconstructable::Bool
    input_preprocessing_was_present::Bool
    rerun_from_original_instance::Bool
    audit::Dict{String,Any}
end


"""Solver-returned diagnostics, including the complete captured HiGHS log."""
struct JournalMIPSolverDiagnostics
    solver_name::String
    solver_version::String
    highs_julia_version::String
    jump_version::String
    solver_invoked::Bool
    termination_status::String
    primal_status::String
    dual_status::String
    raw_status::String
    objective_value::Union{Missing,Float64}
    best_bound::Union{Missing,Float64}
    reported_relative_gap::Union{Missing,Float64}
    solve_time_seconds::Union{Missing,Float64}
    node_count::Union{Missing,Int64}
    presolve_variables_removed::Union{Missing,Int}
    presolve_rows_removed::Union{Missing,Int}
    complete_solver_log::String
end


"""Independent exact-oracle comparison when configured size limits permit it."""
struct JournalMIPCrossCheck
    requested_mode::Symbol
    performed::Bool
    algorithm::Union{Nothing,Symbol}
    applicability_declaration::String
    enumeration_optional_count::Int
    enumeration_limit::Int
    dp_requirement_count::Int
    dp_requirement_limit::Int
    exact_optimum_burden::Union{Missing,ExactRational}
    candidate_available::Bool
    candidate_matches_exact_optimum::Union{Missing,Bool}
end


"""Measured workflow scopes; these are instrumentation, not scaling evidence."""
struct JournalMIPRuntime
    preprocessing_ns::UInt64
    model_build_ns::UInt64
    optimization_wall_ns::UInt64
    reconstruction_and_certification_ns::UInt64
    crosscheck_ns::UInt64
    total_ns::UInt64
end


"""
    JournalMIPSolutionResult

Auditable JuMP/HiGHS result. `candidate_accepted` means only that a returned
exactly binary incumbent was reconstructed and passed the independent exact
source checks. Solver `OPTIMAL` status remains a separate numerical claim.
"""
struct JournalMIPSolutionResult
    schema_version::String
    algorithm::Symbol
    status::Symbol
    instance_sha256::String
    strategy_ids::Tuple{Vararg{StrategyId}}
    controls::JournalMIPControls
    preprocessing::JournalMIPPreprocessingSummary
    formulation::NamedTuple
    diagnostics::JournalMIPSolverDiagnostics
    warm_start_source::String
    raw_reduced_variable_values::Vector{Float64}
    binary_values_exact::Bool
    binary_value_rejection_reason::String
    reconstructed_candidate::Union{Nothing,BitVector}
    candidate_accepted::Bool
    selected_strategy_ids::Tuple{Vararg{StrategyId}}
    exact_burden::Union{Missing,ExactRational}
    exact_feasibility_certificate::Union{Nothing,NamedTuple}
    solver_claimed_optimal::Bool
    exact_global_optimum_verified::Bool
    crosscheck::JournalMIPCrossCheck
    runtime::JournalMIPRuntime
end


function _journal_mip_controls(
    random_seed::Integer,
    time_limit,
    relative_mip_gap_tolerance::Real,
    absolute_mip_gap_tolerance::Real,
)
    0 <= random_seed <= typemax(Int32) || throw(
        ArgumentError("HiGHS random_seed must be in 0:$(typemax(Int32))"),
    )
    resolved_time_limit = nothing
    if !isnothing(time_limit)
        time_limit isa Real || throw(
            ArgumentError("time_limit must be a finite nonnegative real or nothing"),
        )
        converted_time_limit = Float64(time_limit)
        isfinite(converted_time_limit) && converted_time_limit >= 0 || throw(
            ArgumentError("time_limit must be a finite nonnegative real or nothing"),
        )
        resolved_time_limit = converted_time_limit
    end
    relative_gap = Float64(relative_mip_gap_tolerance)
    absolute_gap = Float64(absolute_mip_gap_tolerance)
    isfinite(relative_gap) && relative_gap >= 0 || throw(
        ArgumentError("relative MIP gap tolerance must be finite and nonnegative"),
    )
    isfinite(absolute_gap) && absolute_gap >= 0 || throw(
        ArgumentError("absolute MIP gap tolerance must be finite and nonnegative"),
    )
    return JournalMIPControls(
        1,
        "off",
        Int(random_seed),
        resolved_time_limit,
        relative_gap,
        absolute_gap,
        "on",
        false,
        true,
    )
end


function _journal_mip_preprocess(
    instance::JournalCompressionInstance,
    supplied::Union{Nothing,TaggedCoverPreprocessingResult} = nothing,
)
    result = isnothing(supplied) ?
             preprocess_tagged_cover(exact_tagged_cover_model(instance)) : supplied
    if !isnothing(supplied)
        original = exact_tagged_cover_model(instance)
        original.requirements == result.original.requirements &&
        original.strategy_ids == result.original.strategy_ids &&
        original.coverage == result.original.coverage &&
        original.weights == result.original.weights &&
        original.mandatory == result.original.mandatory || throw(
            ArgumentError("supplied MIP preprocessing does not belong to the instance"),
        )
    end
    result.feasible || throw(
        ArgumentError("exact tagged-cover preprocessing declared the source infeasible"),
    )
    audit = deepcopy(result.audit)
    audit["objective_offset"] = encode_exact_rational(result.objective_offset)
    summary = JournalMIPPreprocessingSummary(
        length(result.original.strategy_ids),
        length(result.reduced.strategy_ids),
        length(result.original.requirements),
        length(result.reduced.requirements),
        length(result.original.strategy_ids) - length(result.reduced.strategy_ids),
        length(result.original.requirements) - length(result.reduced.requirements),
        sort(copy(result.forced_strategy_indices)),
        copy(result.remaining_strategy_indices),
        copy(result.remaining_requirement_indices),
        result.objective_offset,
        Int(result.audit["fixed_point_iterations"]),
        result.all_optimizer_identities_reconstructable,
        instance.preprocessing.applied,
        true,
        audit,
    )
    return result, summary
end


function _journal_mip_build_model(
    instance::JournalCompressionInstance,
    preprocessing::TaggedCoverPreprocessingResult,
    controls::JournalMIPControls,
)
    objective_scale, full_scaled_objective =
        _scaled_safe_compression_objective(instance.weights)
    residual_scaled_objective = Int64[
        full_scaled_objective[index] for
        index in preprocessing.remaining_strategy_indices
    ]
    scaled_objective_offset = sum(
        (
            full_scaled_objective[index] for
            index in preprocessing.forced_strategy_indices
        );
        init = Int64(0),
    )
    exact_rational(scaled_objective_offset) / exact_rational(objective_scale) ==
    preprocessing.objective_offset || throw(
        ArgumentError("scaled MIP objective offset failed exact reconciliation"),
    )

    model = JuMP.Model(HiGHS.Optimizer)
    JuMP.set_attribute(model, "threads", controls.threads)
    JuMP.set_attribute(model, "parallel", controls.parallel)
    JuMP.set_attribute(model, "random_seed", controls.random_seed)
    JuMP.set_attribute(model, "presolve", controls.presolve)
    JuMP.set_attribute(
        model,
        "mip_rel_gap",
        controls.relative_mip_gap_tolerance,
    )
    JuMP.set_attribute(
        model,
        "mip_abs_gap",
        controls.absolute_mip_gap_tolerance,
    )
    isnothing(controls.time_limit_seconds) || JuMP.set_attribute(
        model,
        "time_limit",
        controls.time_limit_seconds,
    )

    reduced = preprocessing.reduced
    strategy_count = length(reduced.strategy_ids)
    JuMP.@variable(model, x[1:strategy_count], Bin)
    for row in axes(reduced.coverage, 1)
        carriers = Int[
            column for column in axes(reduced.coverage, 2) if
            reduced.coverage[row, column]
        ]
        isempty(carriers) && throw(
            ArgumentError("a preprocessed MIP requirement has no carrier"),
        )
        JuMP.@constraint(model, sum(x[column] for column in carriers) >= 1)
    end
    JuMP.@objective(
        model,
        Min,
        scaled_objective_offset + sum(
            residual_scaled_objective[column] * x[column] for
            column in eachindex(residual_scaled_objective)
        ),
    )
    return (
        model,
        x = collect(x),
        objective_scale,
        full_scaled_objective,
        residual_scaled_objective,
        scaled_objective_offset,
    )
end


function _journal_mip_apply_warm_start!(
    variables::Vector{JuMP.VariableRef},
    instance::JournalCompressionInstance,
    preprocessing::TaggedCoverPreprocessingResult,
    warm_start,
    declared_source::AbstractString,
)
    if warm_start == :none
        return "none"
    end
    original = if warm_start == :full_source
        trues(length(instance.strategy_ids))
    elseif warm_start isa AbstractVector{Bool}
        length(warm_start) == length(instance.strategy_ids) || throw(
            DimensionMismatch("an original-coordinate MIP warm start has the wrong length"),
        )
        BitVector(warm_start)
    else
        throw(
            ArgumentError(
                "warm_start must be :none, :full_source, or an original-coordinate Bool vector",
            ),
        )
    end
    check_journal_compression_solution(instance, original).exact_feasible || throw(
        ArgumentError("the supplied original-coordinate warm start is not exactly safe"),
    )
    remaining_position = Dict(
        original_index => position for (position, original_index) in
        enumerate(preprocessing.remaining_strategy_indices)
    )
    forced = BitSet(preprocessing.forced_strategy_indices)
    residual = falses(length(preprocessing.remaining_strategy_indices))
    substitutions = 0
    for original_index in findall(original)
        original_index in forced && continue
        position = get(remaining_position, original_index, 0)
        if !iszero(position)
            residual[position] = true
            continue
        end

        current = original_index
        visited = BitSet()
        while true
            current in visited && throw(
                ArgumentError("exact preprocessing contains a cyclic strategy-elimination map"),
            )
            push!(visited, current)
            target = preprocessing.strategy_elimination_target[current]
            if iszero(target)
                status = preprocessing.strategy_status[current]
                status in (
                    :mandatory_selected,
                    :forced_selected,
                    :empty_contribution,
                ) || throw(
                    ArgumentError(
                        "an eliminated warm-start strategy has no exact preprocessing target",
                    ),
                )
                break
            end
            substitutions += 1
            target in forced && break
            position = get(remaining_position, target, 0)
            if !iszero(position)
                residual[position] = true
                break
            end
            current = target
        end
    end
    exact_tagged_cover_feasible(preprocessing.reduced, residual) || throw(
        ArgumentError(
            "the exact preprocessing warm-start substitution invariant failed",
        ),
    )
    projected_burden = preprocessed_tagged_cover_burden(preprocessing, residual)
    original_burden = exact_tagged_cover_burden(preprocessing.original, original)
    projected_burden <= original_burden || throw(
        ArgumentError("exact preprocessing increased the projected warm-start burden"),
    )
    for (variable, selected) in zip(variables, residual)
        JuMP.set_start_value(variable, selected ? 1.0 : 0.0)
    end
    if warm_start == :full_source
        return "complete source library projected through exact preprocessing"
    end
    source = strip(String(declared_source))
    isempty(source) && throw(
        ArgumentError("a supplied warm-start vector requires a nonempty source label"),
    )
    return iszero(substitutions) ? source :
           source * "; exact preprocessing substitution projection"
end


function _journal_mip_optimize_with_log!(model::JuMP.Model)
    log_path, log_io = mktemp()
    close(log_io)
    solver_log = ""
    optimization_start = time_ns()
    try
        JuMP.set_attribute(model, "output_flag", true)
        JuMP.set_attribute(model, "log_to_console", false)
        JuMP.set_attribute(model, "log_file", log_path)
        JuMP.optimize!(model)
        solver_log = read(log_path, String)
    finally
        isfile(log_path) && rm(log_path; force = true)
    end
    return solver_log, time_ns() - optimization_start
end


function _journal_mip_optional_float(f::Function)
    try
        value = Float64(f())
        return value
    catch
        return missing
    end
end


function _journal_mip_node_count(model::JuMP.Model)
    try
        return Int64(JuMP.node_count(model))
    catch
        return missing
    end
end


function _journal_mip_presolve_reductions(solver_log::AbstractString)
    parsed = match(
        r"Presolve reductions:\s*rows\s+\d+\(-([0-9]+)\);\s*columns\s+\d+\(-([0-9]+)\)",
        solver_log,
    )
    isnothing(parsed) && return (variables = missing, rows = missing)
    return (
        variables = parse(Int, parsed.captures[2]),
        rows = parse(Int, parsed.captures[1]),
    )
end


function _journal_mip_decode_binary_values(raw_values::Vector{Float64})
    selected = falses(length(raw_values))
    for index in eachindex(raw_values)
        value = raw_values[index]
        isfinite(value) || return (
            exact = false,
            selected = nothing,
            reason = "nonfinite binary-variable value at reduced index $index",
        )
        if value == 0.0
            selected[index] = false
        elseif value == 1.0
            selected[index] = true
        else
            return (
                exact = false,
                selected = nothing,
                reason = "fractional binary-variable value at reduced index $index: $value",
            )
        end
    end
    return (exact = true, selected = selected, reason = "")
end


function _journal_mip_diagnostics(
    model::JuMP.Model,
    solver_log::String,
    objective_scale::BigInt,
)
    presolve = _journal_mip_presolve_reductions(solver_log)
    scaled_objective = _journal_mip_optional_float(() -> JuMP.objective_value(model))
    scaled_bound = _journal_mip_optional_float(() -> JuMP.objective_bound(model))
    objective = ismissing(scaled_objective) ? missing : Float64(
        BigFloat(scaled_objective) / BigFloat(objective_scale),
    )
    bound = ismissing(scaled_bound) ? missing : Float64(
        BigFloat(scaled_bound) / BigFloat(objective_scale),
    )
    backend = JuMP.backend(model)
    return JournalMIPSolverDiagnostics(
        String(JuMP.MOI.get(backend, JuMP.MOI.SolverName())),
        String(JuMP.MOI.get(backend, JuMP.MOI.SolverVersion())),
        string(Base.pkgversion(HiGHS)),
        string(Base.pkgversion(JuMP)),
        true,
        string(JuMP.termination_status(model)),
        string(JuMP.primal_status(model)),
        string(JuMP.dual_status(model)),
        JuMP.raw_status(model),
        objective,
        bound,
        _journal_mip_optional_float(() -> JuMP.relative_gap(model)),
        _journal_mip_optional_float(() -> JuMP.solve_time(model)),
        _journal_mip_node_count(model),
        presolve.variables,
        presolve.rows,
        solver_log,
    )
end


function _journal_mip_preprocessing_only_diagnostics(
    model::JuMP.Model,
    exact_objective::ExactRational,
    solver_log::String,
)
    backend = JuMP.backend(model)
    numerical_objective = Float64(
        BigFloat(numerator(exact_objective)) /
        BigFloat(denominator(exact_objective)),
    )
    return JournalMIPSolverDiagnostics(
        String(JuMP.MOI.get(backend, JuMP.MOI.SolverName())),
        String(JuMP.MOI.get(backend, JuMP.MOI.SolverVersion())),
        string(Base.pkgversion(HiGHS)),
        string(Base.pkgversion(JuMP)),
        false,
        "NOT_CALLED_PREPROCESSING_SOLVED",
        "NO_SOLUTION",
        "NO_SOLUTION",
        "exact preprocessing produced an empty residual model",
        numerical_objective,
        numerical_objective,
        0.0,
        0.0,
        missing,
        missing,
        missing,
        solver_log,
    )
end


function _journal_mip_exact_certificate(
    instance::JournalCompressionInstance,
    selected::BitVector,
)
    burden = journal_compression_burden(instance, selected)
    check = check_journal_compression_solution(
        instance,
        selected;
        expected_burden = burden,
    )
    certificate = (
        selected_strategy_indices = findall(selected),
        mandatory_retained = check.mandatory_retained,
        tagged_coverage = check.tagged_coverage,
        frontier_preserved = check.frontier_preserved,
        closure_preserved = check.closure_preserved,
        exact_burden = check.exact_burden,
        burden_reconciled = check.burden_reconciled,
        exact_feasible = check.exact_feasible && check.burden_reconciled,
        arithmetic = "Rational{BigInt}",
        evidence_class = "exact finite post-solve computation",
        solver_status_used_as_proof = false,
        lean_kernel_verified = false,
    )
    return certificate
end


function _journal_mip_validate_crosscheck_options(
    requested_mode::Symbol,
    enumeration_limit::Integer,
    dp_requirement_limit::Integer,
)
    requested_mode in (:auto, :enumeration, :dp, :none) || throw(
        ArgumentError("exact_crosscheck must be :auto, :enumeration, :dp, or :none"),
    )
    0 <= enumeration_limit <= 62 || throw(
        ArgumentError("enumeration_crosscheck_limit must be in 0:62"),
    )
    0 <= dp_requirement_limit <= 30 || throw(
        ArgumentError("dp_crosscheck_requirement_limit must be in 0:30"),
    )
    return nothing
end


function _journal_mip_crosscheck(
    instance::JournalCompressionInstance,
    exact_candidate_burden,
    requested_mode::Symbol,
    enumeration_limit::Integer,
    dp_requirement_limit::Integer,
)
    _journal_mip_validate_crosscheck_options(
        requested_mode,
        enumeration_limit,
        dp_requirement_limit,
    )
    base = _journal_unpreprocessed_instance(instance)
    mandatory_prepared = preprocess_mandatory_journal_instance(base)
    mandatory_reduced = journal_reduced_cover_model(mandatory_prepared)
    optional_count = length(mandatory_reduced.strategy_ids)
    requirement_count = length(mandatory_reduced.requirements)

    algorithm = nothing
    declaration = ""
    if requested_mode == :none
        declaration = "disabled explicitly"
    elseif requested_mode == :enumeration
        optional_count <= enumeration_limit || throw(
            ArgumentError(
                "enumeration cross-check has $optional_count optional strategies; " *
                "the declared limit is $enumeration_limit",
            ),
        )
        algorithm = :complete_enumeration
        declaration = "complete enumeration applicable under the declared optional-strategy limit"
    elseif requested_mode == :dp
        requirement_count <= dp_requirement_limit || throw(
            ArgumentError(
                "DP cross-check has $requirement_count requirements; " *
                "the declared limit is $dp_requirement_limit",
            ),
        )
        algorithm = :requirement_mask_dp
        declaration = "requirement-mask DP applicable under the declared requirement limit"
    elseif optional_count <= enumeration_limit
        algorithm = :complete_enumeration
        declaration =
            "auto-selected complete enumeration under the declared " *
            "optional-strategy limit"
    elseif requirement_count <= dp_requirement_limit
        algorithm = :requirement_mask_dp
        declaration = "auto-selected requirement-mask DP under the declared requirement limit"
    else
        declaration = "neither exact oracle is applicable under the declared size limits"
    end

    if isnothing(algorithm)
        return JournalMIPCrossCheck(
            requested_mode,
            false,
            nothing,
            declaration,
            optional_count,
            Int(enumeration_limit),
            requirement_count,
            Int(dp_requirement_limit),
            missing,
            !ismissing(exact_candidate_burden),
            missing,
        )
    end
    exact = if algorithm == :complete_enumeration
        solve_journal_compression_enumeration(
            instance;
            retain_all_ties = false,
            maximum_optional_strategies = enumeration_limit,
        )
    else
        solve_journal_compression_dp(instance; retain_all_ties = false)
    end
    candidate_available = !ismissing(exact_candidate_burden)
    matches = candidate_available ?
              exact_candidate_burden == exact.exact_burden : missing
    return JournalMIPCrossCheck(
        requested_mode,
        true,
        algorithm,
        declaration,
        optional_count,
        Int(enumeration_limit),
        requirement_count,
        Int(dp_requirement_limit),
        exact.exact_burden,
        candidate_available,
        matches,
    )
end


function _validate_journal_mip_result(result::JournalMIPSolutionResult)
    result.schema_version == JOURNAL_MIP_SOLUTION_SCHEMA_VERSION || throw(
        ArgumentError("unsupported journal MIP solution schema version"),
    )
    result.algorithm == :jump_highs_tagged_cover || throw(
        ArgumentError("unsupported journal MIP algorithm"),
    )
    occursin(r"^[0-9a-f]{64}$", result.instance_sha256) || throw(
        ArgumentError("a journal MIP result needs a lowercase SHA-256"),
    )
    result.controls.threads == 1 && result.controls.parallel == "off" || throw(
        ArgumentError("the journal MIP result is not configured deterministically"),
    )
    result.controls.complete_log_captured || throw(
        ArgumentError("the journal MIP result did not capture a complete solver log"),
    )
    isempty(result.diagnostics.complete_solver_log) && throw(
        ArgumentError("the journal MIP solver log is empty"),
    )
    result.diagnostics.solver_name == "HiGHS" || throw(
        ArgumentError("the journal MIP result was not produced by HiGHS"),
    )
    if result.candidate_accepted
        isnothing(result.reconstructed_candidate) && throw(
            ArgumentError("an accepted MIP candidate has no reconstructed selection"),
        )
        ismissing(result.exact_burden) && throw(
            ArgumentError("an accepted MIP candidate has no exact burden"),
        )
        isnothing(result.exact_feasibility_certificate) && throw(
            ArgumentError("an accepted MIP candidate has no exact certificate"),
        )
        result.binary_values_exact || throw(
            ArgumentError("an accepted MIP candidate was not exactly binary"),
        )
        result.exact_feasibility_certificate.exact_feasible || throw(
            ArgumentError("an accepted MIP candidate failed exact feasibility"),
        )
        result.exact_feasibility_certificate.exact_burden == result.exact_burden || throw(
            ArgumentError("the MIP exact burden and certificate disagree"),
        )
        length(result.selected_strategy_ids) == count(result.reconstructed_candidate) || throw(
            ArgumentError("the accepted MIP strategy identifiers are inconsistent"),
        )
        expected_ids = Tuple(
            result.strategy_ids[index] for
            index in findall(result.reconstructed_candidate)
        )
        result.selected_strategy_ids == expected_ids || throw(
            ArgumentError("the accepted MIP strategy identifiers are not original-coordinate IDs"),
        )
    else
        !isempty(result.selected_strategy_ids) && throw(
            ArgumentError("a rejected MIP candidate exposes certified selected IDs"),
        )
        !ismissing(result.exact_burden) && throw(
            ArgumentError("a rejected MIP candidate exposes a certified burden"),
        )
    end
    result.exact_global_optimum_verified &&
        !(result.crosscheck.performed &&
          result.crosscheck.candidate_matches_exact_optimum === true) && throw(
        ArgumentError("exact MIP optimality is claimed without an exact oracle match"),
    )
    result.solver_claimed_optimal ==
    (result.diagnostics.solver_invoked &&
     result.diagnostics.termination_status == "OPTIMAL") || throw(
        ArgumentError("the MIP optimality flag disagrees with solver invocation/status"),
    )
    return result
end


"""
    solve_journal_compression_mip(instance; ...)

Solve the fully preprocessed tagged identity-closure cover with JuMP and
HiGHS. The workflow captures the complete solver log and preserves time-limit
or other nonoptimal termination statuses. A primal vector is reconstructed
only when every returned binary value is exactly `0.0` or `1.0`; no threshold
rounding is used. The reconstructed original selection must then pass exact
mandatory, tagged-coverage, frontier, closure, and burden checks.
"""
function solve_journal_compression_mip(
    instance::JournalCompressionInstance;
    random_seed::Integer = 0,
    time_limit = nothing,
    relative_mip_gap_tolerance::Real = 0.0,
    absolute_mip_gap_tolerance::Real = 0.0,
    warm_start = :none,
    warm_start_source::AbstractString = "user-provided original selection",
    exact_crosscheck::Symbol = :auto,
    enumeration_crosscheck_limit::Integer = 20,
    dp_crosscheck_requirement_limit::Integer = 18,
    preprocessing_result::Union{Nothing,TaggedCoverPreprocessingResult} = nothing,
    precomputed_instance_sha256::Union{Nothing,AbstractString} = nothing,
)
    validate_journal_compression_instance(instance)
    instance.tie_handling.mode == :complete && throw(
        ArgumentError(
            "the MIP workflow returns one incumbent and cannot satisfy complete tie handling",
        ),
    )
    _journal_mip_validate_crosscheck_options(
        exact_crosscheck,
        enumeration_crosscheck_limit,
        dp_crosscheck_requirement_limit,
    )
    instance_sha256 = if isnothing(precomputed_instance_sha256)
        journal_compression_instance_sha256(instance)
    else
        value = String(precomputed_instance_sha256)
        occursin(r"^[0-9a-f]{64}$", value) || throw(
            ArgumentError("precomputed_instance_sha256 must be a lowercase SHA-256 digest"),
        )
        value
    end
    total_start = time_ns()
    controls = _journal_mip_controls(
        random_seed,
        time_limit,
        relative_mip_gap_tolerance,
        absolute_mip_gap_tolerance,
    )

    preprocessing_start = time_ns()
    preprocessing, preprocessing_summary =
        _journal_mip_preprocess(instance, preprocessing_result)
    preprocessing_ns = time_ns() - preprocessing_start

    model_build_start = time_ns()
    mip = _journal_mip_build_model(instance, preprocessing, controls)
    resolved_warm_start = _journal_mip_apply_warm_start!(
        mip.x,
        instance,
        preprocessing,
        warm_start,
        warm_start_source,
    )
    model_build_ns = time_ns() - model_build_start

    preprocessing_solved = isempty(preprocessing.reduced.strategy_ids) &&
                           isempty(preprocessing.reduced.requirements)
    solver_log, optimization_wall_ns = if preprocessing_solved
        (
            "HiGHS not invoked: exact fixed-point preprocessing removed " *
            "all residual variables and requirements.\n",
            UInt64(0),
        )
    else
        _journal_mip_optimize_with_log!(mip.model)
    end
    diagnostics = if preprocessing_solved
        _journal_mip_preprocessing_only_diagnostics(
            mip.model,
            preprocessing.objective_offset,
            solver_log,
        )
    else
        _journal_mip_diagnostics(
            mip.model,
            solver_log,
            mip.objective_scale,
        )
    end
    termination = preprocessing_solved ? nothing :
                  JuMP.termination_status(mip.model)
    solver_claimed_optimal = !isnothing(termination) &&
                             termination == JuMP.MOI.OPTIMAL

    certification_start = time_ns()
    has_primal = preprocessing_solved || JuMP.has_values(mip.model)
    raw_values = has_primal ?
                 Float64[JuMP.value(variable) for variable in mip.x] : Float64[]
    decoded = has_primal ? _journal_mip_decode_binary_values(raw_values) : (
        exact = false,
        selected = nothing,
        reason = "solver returned no primal variable values",
    )
    reconstructed = nothing
    exact_certificate = nothing
    accepted = false
    exact_burden = missing
    selected_ids = ()
    status = :no_primal_candidate
    if has_primal && !decoded.exact
        status = :rejected_nonbinary_solver_candidate
    elseif has_primal
        reconstructed = lift_preprocessed_tagged_selection(
            preprocessing,
            decoded.selected,
        )
        exact_certificate = _journal_mip_exact_certificate(
            instance,
            reconstructed,
        )
        if exact_certificate.exact_feasible
            accepted = true
            exact_burden = exact_certificate.exact_burden
            selected_ids = Tuple(
                instance.strategy_ids[index] for index in findall(reconstructed)
            )
            status = :exactly_rechecked_solver_candidate
        else
            status = :rejected_exact_infeasible_solver_candidate
        end
    end
    certification_ns = time_ns() - certification_start

    crosscheck_start = time_ns()
    crosscheck = _journal_mip_crosscheck(
        instance,
        exact_burden,
        exact_crosscheck,
        enumeration_crosscheck_limit,
        dp_crosscheck_requirement_limit,
    )
    crosscheck_ns = time_ns() - crosscheck_start
    exact_global_optimum_verified =
        crosscheck.performed &&
        crosscheck.candidate_matches_exact_optimum === true
    if accepted && solver_claimed_optimal && crosscheck.performed &&
       crosscheck.candidate_matches_exact_optimum === false
        status = :solver_optimality_contradicted_by_exact_oracle
    end

    formulation = (
        original_binary_strategy_count = length(instance.strategy_ids),
        original_mandatory_equality_count = count(instance.mandatory),
        original_tagged_cover_row_count = length(instance.requirements),
        residual_binary_variable_count = length(preprocessing.reduced.strategy_ids),
        residual_tagged_cover_row_count = length(preprocessing.reduced.requirements),
        residual_nonzero_count = count(preprocessing.reduced.coverage),
        objective_scale = mip.objective_scale,
        scaled_objective_offset = mip.scaled_objective_offset,
        residual_scaled_objective = copy(mip.residual_scaled_objective),
        mandatory_equalities_substituted_by_exact_preprocessing = true,
        closure_kind = :identity,
    )
    result = JournalMIPSolutionResult(
        JOURNAL_MIP_SOLUTION_SCHEMA_VERSION,
        :jump_highs_tagged_cover,
        status,
        instance_sha256,
        instance.strategy_ids,
        controls,
        preprocessing_summary,
        formulation,
        diagnostics,
        resolved_warm_start,
        raw_values,
        has_primal && decoded.exact,
        decoded.reason,
        reconstructed,
        accepted,
        selected_ids,
        exact_burden,
        exact_certificate,
        solver_claimed_optimal,
        exact_global_optimum_verified,
        crosscheck,
        JournalMIPRuntime(
            preprocessing_ns,
            model_build_ns,
            optimization_wall_ns,
            certification_ns,
            crosscheck_ns,
            time_ns() - total_start,
        ),
    )
    return _validate_journal_mip_result(result)
end


function _journal_mip_optional_payload(value)
    ismissing(value) && return Dict{String,Any}("available" => false)
    return Dict{String,Any}("available" => true, "value" => value)
end


function _journal_mip_serializable(value)
    value isa Rational && return encode_exact_rational(value)
    value isa BigInt && return string(value)
    value isa Symbol && return string(value)
    value isa NamedTuple && return Dict{String,Any}(
        string(key) => _journal_mip_serializable(getproperty(value, key)) for
        key in keys(value)
    )
    value isa AbstractDict && return Dict{String,Any}(
        string(key) => _journal_mip_serializable(entry) for
        (key, entry) in value
    )
    value isa AbstractVector && return [_journal_mip_serializable(entry) for entry in value]
    value isa Tuple && return [_journal_mip_serializable(entry) for entry in value]
    return value
end


function _journal_mip_selected_identifier_payload(result::JournalMIPSolutionResult)
    kinds = String[]
    values = String[]
    for strategy_id in result.selected_strategy_ids
        kind, value = _journal_identifier_parts(strategy_id.id)
        push!(kinds, kind)
        push!(values, value)
    end
    return kinds, values
end


"""Return the complete machine-readable MIP result and audit payload."""
function journal_mip_solution_certificate(result::JournalMIPSolutionResult)
    _validate_journal_mip_result(result)
    selected_kinds, selected_values =
        _journal_mip_selected_identifier_payload(result)
    exact_certificate = isnothing(result.exact_feasibility_certificate) ?
                        Dict{String,Any}("available" => false) :
                        merge(
        Dict{String,Any}("available" => true),
        _journal_mip_serializable(result.exact_feasibility_certificate),
    )
    crosscheck_optimum = _journal_mip_optional_payload(
        result.crosscheck.exact_optimum_burden,
    )
    if crosscheck_optimum["available"]
        crosscheck_optimum["value"] = encode_exact_rational(
            result.crosscheck.exact_optimum_burden,
        )
    end
    candidate_match = _journal_mip_optional_payload(
        result.crosscheck.candidate_matches_exact_optimum,
    )
    return Dict{String,Any}(
        "schema_version" => result.schema_version,
        "algorithm" => string(result.algorithm),
        "status" => string(result.status),
        "evidence_class" => "mixed-integer solver evidence plus exact finite post-check",
        "instance_sha256" => result.instance_sha256,
        "solver_claimed_optimal" => result.solver_claimed_optimal,
        "solver_optimality_is_formal_proof" => false,
        "candidate_accepted" => result.candidate_accepted,
        "binary_values_exact" => result.binary_values_exact,
        "binary_value_rejection_reason" => result.binary_value_rejection_reason,
        "raw_reduced_variable_values" => result.raw_reduced_variable_values,
        "reconstructed_candidate_available" =>
            !isnothing(result.reconstructed_candidate),
        "reconstructed_candidate_indices" =>
            isnothing(result.reconstructed_candidate) ? Int[] :
            findall(result.reconstructed_candidate),
        "selected_strategy_indices" => result.candidate_accepted ?
            findall(result.reconstructed_candidate) : Int[],
        "selected_strategy_id_kinds" => selected_kinds,
        "selected_strategy_id_values" => selected_values,
        "exact_burden" => ismissing(result.exact_burden) ?
            Dict{String,Any}("available" => false) : Dict{String,Any}(
            "available" => true,
            "value" => encode_exact_rational(result.exact_burden),
        ),
        "exact_feasibility_certificate" => exact_certificate,
        "exact_global_optimum_verified" => result.exact_global_optimum_verified,
        "controls" => Dict{String,Any}(
            "threads" => result.controls.threads,
            "parallel" => result.controls.parallel,
            "random_seed" => result.controls.random_seed,
            "time_limit_seconds" => isnothing(result.controls.time_limit_seconds) ?
                Dict{String,Any}("set" => false) : Dict{String,Any}(
                "set" => true,
                "value" => result.controls.time_limit_seconds,
            ),
            "relative_mip_gap_tolerance" =>
                result.controls.relative_mip_gap_tolerance,
            "absolute_mip_gap_tolerance" =>
                result.controls.absolute_mip_gap_tolerance,
            "presolve" => result.controls.presolve,
            "log_to_console" => result.controls.log_to_console,
            "complete_log_captured" => result.controls.complete_log_captured,
        ),
        "warm_start_source" => result.warm_start_source,
        "formulation" => _journal_mip_serializable(result.formulation),
        "preprocessing" => Dict{String,Any}(
            "original_strategy_count" =>
                result.preprocessing.original_strategy_count,
            "reduced_strategy_count" =>
                result.preprocessing.reduced_strategy_count,
            "original_requirement_count" =>
                result.preprocessing.original_requirement_count,
            "reduced_requirement_count" =>
                result.preprocessing.reduced_requirement_count,
            "variables_removed" => result.preprocessing.variables_removed,
            "requirements_removed" => result.preprocessing.requirements_removed,
            "forced_strategy_indices" =>
                result.preprocessing.forced_strategy_indices,
            "remaining_strategy_indices" =>
                result.preprocessing.remaining_strategy_indices,
            "remaining_requirement_indices" =>
                result.preprocessing.remaining_requirement_indices,
            "exact_objective_offset" => encode_exact_rational(
                result.preprocessing.exact_objective_offset,
            ),
            "fixed_point_iterations" =>
                result.preprocessing.fixed_point_iterations,
            "all_optimizer_identities_reconstructable" =>
                result.preprocessing.all_optimizer_identities_reconstructable,
            "input_preprocessing_was_present" =>
                result.preprocessing.input_preprocessing_was_present,
            "rerun_from_original_instance" =>
                result.preprocessing.rerun_from_original_instance,
            "audit" => _journal_mip_serializable(result.preprocessing.audit),
        ),
        "solver_diagnostics" => Dict{String,Any}(
            "solver_name" => result.diagnostics.solver_name,
            "solver_version" => result.diagnostics.solver_version,
            "highs_julia_version" => result.diagnostics.highs_julia_version,
            "jump_version" => result.diagnostics.jump_version,
            "solver_invoked" => result.diagnostics.solver_invoked,
            "termination_status" => result.diagnostics.termination_status,
            "primal_status" => result.diagnostics.primal_status,
            "dual_status" => result.diagnostics.dual_status,
            "raw_status" => result.diagnostics.raw_status,
            "objective_value" =>
                _journal_mip_optional_payload(result.diagnostics.objective_value),
            "best_bound" =>
                _journal_mip_optional_payload(result.diagnostics.best_bound),
            "reported_relative_gap" => _journal_mip_optional_payload(
                result.diagnostics.reported_relative_gap,
            ),
            "solve_time_seconds" => _journal_mip_optional_payload(
                result.diagnostics.solve_time_seconds,
            ),
            "node_count" =>
                _journal_mip_optional_payload(result.diagnostics.node_count),
            "presolve_variables_removed" => _journal_mip_optional_payload(
                result.diagnostics.presolve_variables_removed,
            ),
            "presolve_rows_removed" => _journal_mip_optional_payload(
                result.diagnostics.presolve_rows_removed,
            ),
            "complete_solver_log" => result.diagnostics.complete_solver_log,
        ),
        "crosscheck" => Dict{String,Any}(
            "requested_mode" => string(result.crosscheck.requested_mode),
            "performed" => result.crosscheck.performed,
            "algorithm" => isnothing(result.crosscheck.algorithm) ?
                "none" : string(result.crosscheck.algorithm),
            "applicability_declaration" =>
                result.crosscheck.applicability_declaration,
            "enumeration_optional_count" =>
                result.crosscheck.enumeration_optional_count,
            "enumeration_limit" => result.crosscheck.enumeration_limit,
            "dp_requirement_count" => result.crosscheck.dp_requirement_count,
            "dp_requirement_limit" => result.crosscheck.dp_requirement_limit,
            "exact_optimum_burden" => crosscheck_optimum,
            "candidate_available" => result.crosscheck.candidate_available,
            "candidate_matches_exact_optimum" => candidate_match,
        ),
        "runtime_ns" => Dict{String,Any}(
            "evidence_class" => "single-run wall-clock instrumentation",
            "preprocessing" => Int(result.runtime.preprocessing_ns),
            "model_build" => Int(result.runtime.model_build_ns),
            "optimization_wall" => Int(result.runtime.optimization_wall_ns),
            "reconstruction_and_certification" =>
                Int(result.runtime.reconstruction_and_certification_ns),
            "crosscheck" => Int(result.runtime.crosscheck_ns),
            "total" => Int(result.runtime.total_ns),
        ),
    )
end


"""Serialize the complete MIP result, diagnostics, log, and certificate."""
function serialize_journal_mip_solution(result::JournalMIPSolutionResult)
    io = IOBuffer()
    TOML.print(io, journal_mip_solution_certificate(result); sorted = true)
    return String(take!(io))
end


function write_journal_mip_solution_certificate(
    io::IO,
    result::JournalMIPSolutionResult,
)
    write(io, serialize_journal_mip_solution(result))
    return nothing
end
