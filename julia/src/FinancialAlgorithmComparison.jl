const FINANCIAL_ALGORITHM_COMPARISON_SCHEMA_VERSION =
    "financial-algorithm-comparison-v1"


"""Locked controls that do not accept financial held-out quantities."""
struct FinancialAlgorithmComparisonControls
    dp_requirement_limit::Int
    multistart_count::Int
    multistart_seed::UInt64
    mip_seed::Int
    mip_time_limit_seconds::Float64
    mip_relative_gap_tolerance::Float64
    mip_absolute_gap_tolerance::Float64
    second_solver::Union{Nothing,String}
end


function FinancialAlgorithmComparisonControls(;
    dp_requirement_limit::Integer = 22,
    multistart_count::Integer = 32,
    multistart_seed::Integer = 20_260_827,
    mip_seed::Integer = 0,
    mip_time_limit_seconds::Real = 300.0,
    mip_relative_gap_tolerance::Real = 0.0,
    mip_absolute_gap_tolerance::Real = 0.0,
    second_solver = nothing,
)
    0 <= dp_requirement_limit <= 30 || throw(
        ArgumentError("dp_requirement_limit must be in 0:30"),
    )
    multistart_count > 0 || throw(
        ArgumentError("multistart_count must be positive"),
    )
    0 <= multistart_seed <= typemax(UInt64) || throw(
        ArgumentError("multistart_seed must be representable as UInt64"),
    )
    0 <= mip_seed <= typemax(Int32) || throw(
        ArgumentError("mip_seed must be representable as Int32"),
    )
    time_limit = Float64(mip_time_limit_seconds)
    isfinite(time_limit) && time_limit >= 0 || throw(
        ArgumentError("mip_time_limit_seconds must be finite and nonnegative"),
    )
    relative_gap = Float64(mip_relative_gap_tolerance)
    absolute_gap = Float64(mip_absolute_gap_tolerance)
    isfinite(relative_gap) && relative_gap >= 0 || throw(
        ArgumentError("the relative MIP gap tolerance must be finite and nonnegative"),
    )
    isfinite(absolute_gap) && absolute_gap >= 0 || throw(
        ArgumentError("the absolute MIP gap tolerance must be finite and nonnegative"),
    )
    solver = isnothing(second_solver) ? nothing : strip(String(second_solver))
    !isnothing(solver) && isempty(solver) && throw(
        ArgumentError("second_solver cannot be an empty string"),
    )
    return FinancialAlgorithmComparisonControls(
        Int(dp_requirement_limit),
        Int(multistart_count),
        UInt64(multistart_seed),
        Int(mip_seed),
        time_limit,
        relative_gap,
        absolute_gap,
        solver,
    )
end


"""One audit- and schedule-specific comparison, never pooled across audits."""
struct FinancialAlgorithmComparisonResult
    schema_version::String
    audit_id::String
    audit_label::String
    schedule_id::String
    heldout_unit::String
    instance_sha256::String
    strategy_ids::Tuple{Vararg{StrategyId}}
    structure::NamedTuple
    controls::FinancialAlgorithmComparisonControls
    rows::Vector{NamedTuple}
    selected_by_algorithm::Dict{String,BitVector}
    solver_logs::Dict{String,String}
    benchmark::NamedTuple
    heldout_evaluation_phase::String
end


_financial_id(value::StrategyId) = string(value.id)
_financial_exact_text(value::Rational) =
    "$(numerator(value))//$(denominator(value))"


function _financial_selection_from_ids(
    instance::JournalCompressionInstance,
    ids,
)
    selected = copy(instance.mandatory)
    index = Dict(
        _financial_id(strategy_id) => position for
        (position, strategy_id) in enumerate(instance.strategy_ids)
    )
    values = String.(collect(ids))
    length(values) == length(unique(values)) || throw(
        ArgumentError("the historical stepwise endpoint contains duplicate identifiers"),
    )
    for id in values
        haskey(index, id) || throw(
            ArgumentError("historical stepwise strategy is absent from the source: $id"),
        )
        selected[index[id]] = true
    end
    return selected
end


function _financial_duplicate_coverage_count(
    instance::JournalCompressionInstance,
    active::Vector{Int},
)
    groups = Dict{Tuple{Vararg{Bool}},Int}()
    for column in active
        signature = Tuple(instance.coverage[:, column])
        groups[signature] = get(groups, signature, 0) + 1
    end
    return sum(max(count - 1, 0) for count in values(groups); init = 0)
end


function _financial_structure(instance::JournalCompressionInstance)
    validate_journal_compression_instance(instance)
    active = Int[index for index in eachindex(instance.strategy_ids) if !instance.mandatory[index]]
    frontier_count = count(requirement -> requirement isa FrontierRequirement, instance.requirements)
    module_count = count(requirement -> requirement isa ModuleRequirement, instance.requirements)
    frontier_count + module_count == length(instance.requirements) || throw(
        ArgumentError("financial tagged universe contains an unknown requirement type"),
    )
    incidence = isempty(active) ? 0 : count(instance.coverage[:, active])
    denominator = length(instance.requirements) * length(active)
    density = iszero(denominator) ? zero(ExactRational) :
              BigInt(incidence) // BigInt(denominator)
    carriers = Int[count(instance.coverage[row, :]) for row in axes(instance.coverage, 1)]
    all(>(0), carriers) || throw(
        ArgumentError("a financial tagged requirement has no source carrier"),
    )
    preprocessing = preprocess_tagged_cover(exact_tagged_cover_model(instance))
    preprocessing.feasible || throw(
        ArgumentError("exact preprocessing declared the financial source infeasible"),
    )
    rule_counts = preprocessing.audit["rule_counts"]
    dominance = Int(rule_counts["coverage_dominance"]["variables_removed"])
    forced_active = count(
        index -> !instance.mandatory[index],
        preprocessing.forced_strategy_indices,
    )
    return (
        active_strategy_count = length(active),
        frontier_requirement_count = frontier_count,
        module_requirement_count = module_count,
        tagged_requirement_count = length(instance.requirements),
        active_incidence_count = incidence,
        coverage_density = density,
        duplicate_coverage_count = _financial_duplicate_coverage_count(instance, active),
        dominance_reductions = dominance,
        unique_carrier_count = count(==(1), carriers),
        forced_strategy_count = forced_active,
        variables_before_preprocessing = length(instance.strategy_ids),
        variables_after_preprocessing = length(preprocessing.reduced.strategy_ids),
        constraints_before_preprocessing =
            length(instance.requirements) + count(instance.mandatory),
        constraints_after_preprocessing = length(preprocessing.reduced.requirements),
        mandatory_strategy_count = count(instance.mandatory),
        preprocessing_fixed_point_iterations =
            Int(preprocessing.audit["fixed_point_iterations"]),
        preprocessing_rule_counts = deepcopy(rule_counts),
    )
end


function _financial_base_row(
    algorithm_id::AbstractString,
    applicability::AbstractString,
    status::AbstractString,
    structure::NamedTuple,
)
    return (;
        algorithm_id = String(algorithm_id),
        applicability = String(applicability),
        status = String(status),
        structure...,
        selected_strategy_count = missing,
        exact_reconstructed_burden = missing,
        exact_mandatory_retention = missing,
        exact_tagged_coverage = missing,
        exact_frontier_preservation = missing,
        exact_closure_preservation = missing,
        exact_feasible = missing,
        solve_time_seconds = missing,
        mip_node_count = missing,
        primal_objective = missing,
        best_bound = missing,
        reported_gap = missing,
        mip_termination_status = "NOT_APPLICABLE",
        solver_claimed_optimal = false,
        solver_status_used_as_exact_proof = false,
        dp_state_count = missing,
        exact_frontier_evaluations = missing,
        exact_closure_evaluations = missing,
        complete_deletion_scans = missing,
        multistart_count = missing,
        random_seed = missing,
        best_certified_benchmark_burden = missing,
        absolute_burden_gap = missing,
        relative_burden_gap = missing,
        benchmark_evidence_class = "PENDING",
        heldout_opportunity_diagnostic = missing,
        heldout_timing = "NOT_EVALUATED_DURING_OPTIMIZATION",
        selected_active_strategy_count = missing,
    )
end


function _financial_checked_row(
    instance::JournalCompressionInstance,
    selected::BitVector,
    base::NamedTuple;
    solve_time_seconds = missing,
    mip_node_count = missing,
    primal_objective = missing,
    best_bound = missing,
    reported_gap = missing,
    mip_termination_status = "NOT_APPLICABLE",
    solver_claimed_optimal::Bool = false,
    dp_state_count = missing,
    exact_frontier_evaluations = 1,
    exact_closure_evaluations = 1,
    complete_deletion_scans = missing,
    multistart_count = missing,
    random_seed = missing,
)
    check = check_journal_compression_solution(instance, selected)
    return merge(
        base,
        (
            selected_strategy_count = count(selected),
            selected_active_strategy_count = count(
                index -> selected[index] && !instance.mandatory[index],
                eachindex(selected),
            ),
            exact_reconstructed_burden = check.exact_burden,
            exact_mandatory_retention = check.mandatory_retained,
            exact_tagged_coverage = check.tagged_coverage,
            exact_frontier_preservation = check.frontier_preserved,
            exact_closure_preservation = check.closure_preserved,
            exact_feasible = check.exact_feasible,
            solve_time_seconds,
            mip_node_count,
            primal_objective,
            best_bound,
            reported_gap,
            mip_termination_status = String(mip_termination_status),
            solver_claimed_optimal,
            solver_status_used_as_exact_proof = false,
            dp_state_count,
            exact_frontier_evaluations,
            exact_closure_evaluations,
            complete_deletion_scans,
            multistart_count,
            random_seed,
        ),
    )
end


function _financial_deletion_row(instance, result, structure, algorithm_id)
    base = _financial_base_row(
        algorithm_id,
        "APPLICABLE",
        string(result.status),
        structure,
    )
    return _financial_checked_row(
        instance,
        result.selected,
        base;
        solve_time_seconds = Float64(result.runtime.total_ns) / 1.0e9,
        exact_frontier_evaluations = result.counters.frontier_checks + 1,
        exact_closure_evaluations = result.counters.closure_checks + 1,
        complete_deletion_scans = result.counters.complete_scans,
        multistart_count = isempty(result.start_summaries) ? missing :
                           length(result.start_summaries),
        random_seed = isnothing(result.random_seed) ? missing :
                      string(result.random_seed),
    )
end


function _financial_greedy_row(instance, result, structure, elapsed_ns)
    base = _financial_base_row(
        string(result.algorithm),
        "APPLICABLE_IDENTITY_CLOSURE_ONLY",
        string(result.status),
        structure,
    )
    return _financial_checked_row(
        instance,
        result.selected,
        base;
        solve_time_seconds = Float64(elapsed_ns) / 1.0e9,
        exact_frontier_evaluations = length(result.reverse_deletion_trace) + 2,
        exact_closure_evaluations = length(result.reverse_deletion_trace) + 2,
    )
end


function _financial_dp_row(instance, result, structure)
    base = _financial_base_row(
        "requirement_mask_dp",
        "APPLICABLE_UNDER_REGISTERED_REQUIREMENT_LIMIT",
        string(result.status),
        structure,
    )
    return _financial_checked_row(
        instance,
        result.selected,
        base;
        solve_time_seconds = Float64(result.runtime.total_ns) / 1.0e9,
        dp_state_count = result.counters.state_layer_pairs_visited,
        exact_frontier_evaluations = length(result.certificates) + 1,
        exact_closure_evaluations = length(result.certificates) + 1,
    )
end


function _financial_mip_row(instance, result, structure)
    base = _financial_base_row(
        "preprocessed_highs_mip",
        "APPLICABLE_IDENTITY_CLOSURE_ONLY",
        string(result.status),
        structure,
    )
    if isnothing(result.reconstructed_candidate)
        return merge(
            base,
            (
                solve_time_seconds = Float64(result.runtime.total_ns) / 1.0e9,
                mip_node_count = result.diagnostics.node_count,
                primal_objective = result.diagnostics.objective_value,
                best_bound = result.diagnostics.best_bound,
                reported_gap = result.diagnostics.reported_relative_gap,
                mip_termination_status = result.diagnostics.termination_status,
                solver_claimed_optimal = result.solver_claimed_optimal,
            ),
        )
    end
    return _financial_checked_row(
        instance,
        result.reconstructed_candidate,
        base;
        solve_time_seconds = Float64(result.runtime.total_ns) / 1.0e9,
        mip_node_count = result.diagnostics.node_count,
        primal_objective = result.diagnostics.objective_value,
        best_bound = result.diagnostics.best_bound,
        reported_gap = result.diagnostics.reported_relative_gap,
        mip_termination_status = result.diagnostics.termination_status,
        solver_claimed_optimal = result.solver_claimed_optimal,
        exact_frontier_evaluations = 2,
        exact_closure_evaluations = 2,
    )
end


function _financial_benchmark(rows)
    exact_dp = findfirst(
        row -> row.algorithm_id == "requirement_mask_dp" && row.exact_feasible === true,
        rows,
    )
    if !isnothing(exact_dp)
        row = rows[exact_dp]
        contradictory_mip = findfirst(
            candidate -> candidate.algorithm_id == "preprocessed_highs_mip" &&
                         candidate.exact_feasible === true &&
                         candidate.solver_claimed_optimal &&
                         candidate.exact_reconstructed_burden !=
                         row.exact_reconstructed_burden,
            rows,
        )
        isnothing(contradictory_mip) || throw(
            ArgumentError(
                "HiGHS-reported OPTIMAL burden disagrees with exact requirement-mask DP",
            ),
        )
        return (
            burden = row.exact_reconstructed_burden,
            algorithm_id = row.algorithm_id,
            evidence_class = "exact finite requirement-mask dynamic programming",
            global_optimum_exactly_verified = true,
        )
    end
    mip = findfirst(
        row -> row.algorithm_id == "preprocessed_highs_mip" &&
               row.exact_feasible === true && row.solver_claimed_optimal,
        rows,
    )
    if !isnothing(mip)
        row = rows[mip]
        return (
            burden = row.exact_reconstructed_burden,
            algorithm_id = row.algorithm_id,
            evidence_class =
                "HiGHS-reported OPTIMAL candidate with independent exact feasibility recheck; not formal or exhaustive proof",
            global_optimum_exactly_verified = false,
        )
    end
    feasible = [row for row in rows if row.exact_feasible === true]
    isempty(feasible) && throw(
        ArgumentError("the financial algorithm suite returned no exactly feasible endpoint"),
    )
    best = minimum(row.exact_reconstructed_burden for row in feasible)
    algorithm = first(row.algorithm_id for row in feasible if row.exact_reconstructed_burden == best)
    return (
        burden = best,
        algorithm_id = algorithm,
        evidence_class = "lowest-burden exactly feasible returned endpoint; no optimality claim",
        global_optimum_exactly_verified = false,
    )
end


function _financial_add_gap(row, benchmark)
    if row.exact_feasible !== true
        return merge(
            row,
            (
                best_certified_benchmark_burden = benchmark.burden,
                benchmark_evidence_class = benchmark.evidence_class,
            ),
        )
    end
    absolute_gap = row.exact_reconstructed_burden - benchmark.burden
    absolute_gap >= 0 || throw(
        ArgumentError("the selected benchmark exceeds an exactly feasible endpoint"),
    )
    relative_gap = iszero(benchmark.burden) ?
                   (iszero(absolute_gap) ? zero(ExactRational) : missing) :
                   absolute_gap / benchmark.burden
    return merge(
        row,
        (
            best_certified_benchmark_burden = benchmark.burden,
            absolute_burden_gap = absolute_gap,
            relative_burden_gap = relative_gap,
            benchmark_evidence_class = benchmark.evidence_class,
        ),
    )
end


function _financial_apply_heldout(rows, selections, evaluator)
    isnothing(evaluator) && return rows
    frozen_rows = copy(rows)
    return NamedTuple[
        if row.exact_feasible === true
            value = evaluator(copy(selections[row.algorithm_id]), frozen_rows)
            merge(
                row,
                (
                    heldout_opportunity_diagnostic = value,
                    heldout_timing =
                        "EX_POST_AFTER_ALL_OPTIMIZATION_AND_BENCHMARK_ASSIGNMENT",
                ),
            )
        else
            row
        end for row in rows
    ]
end


"""
    compare_financial_algorithm_suite(instance; ...)

Run the journal suite on one exact financial source instance and one fixed
weight schedule. The optimization routines receive only `instance` and fixed
controls. When supplied, `heldout_evaluator(selected, frozen_rows)` is invoked
only after every algorithm has finished and the benchmark and burden gaps are
frozen. Its return value cannot affect any selection, preprocessing, warm
start, pruning order, objective, or algorithm-applicability decision.
"""
function compare_financial_algorithm_suite(
    instance::JournalCompressionInstance;
    audit_id::AbstractString,
    audit_label::AbstractString,
    schedule_id::AbstractString,
    heldout_unit::AbstractString,
    current_stepwise_ids,
    controls::FinancialAlgorithmComparisonControls =
        FinancialAlgorithmComparisonControls(),
    heldout_evaluator = nothing,
)
    validate_journal_compression_instance(instance)
    instance.provenance.instance_kind == :financial || throw(
        ArgumentError("the financial comparison requires financial provenance"),
    )
    instance.identity_closure || throw(
        ArgumentError("the registered financial suite applies only to identity closure"),
    )
    for (label, value) in (
        ("audit_id", audit_id),
        ("audit_label", audit_label),
        ("schedule_id", schedule_id),
        ("heldout_unit", heldout_unit),
    )
        isempty(strip(String(value))) && throw(ArgumentError("$label cannot be empty"))
    end
    structure = _financial_structure(instance)
    rows = NamedTuple[]
    selections = Dict{String,BitVector}()
    solver_logs = Dict{String,String}()

    historical = _financial_selection_from_ids(instance, current_stepwise_ids)
    historical_check = check_journal_compression_solution(instance, historical)
    historical_status = historical_check.exact_feasible ?
        "HISTORICAL_LOCKED_ENDPOINT_EXACTLY_RECHECKED" :
        "HISTORICAL_LOCKED_ENDPOINT_FAILS_EXACT_JOURNAL_RECHECK"
    historical_base = _financial_base_row(
        "current_stepwise_safe_deletion",
        "LOCKED_PARENT_ENDPOINT",
        historical_status,
        structure,
    )
    push!(rows, _financial_checked_row(
        instance,
        historical,
        historical_base;
        solve_time_seconds = missing,
    ))
    selections["current_stepwise_safe_deletion"] = historical

    heaviest = solve_journal_compression_heaviest_safe_first(instance)
    push!(rows, _financial_deletion_row(
        instance,
        heaviest,
        structure,
        "heaviest_safe_first",
    ))
    selections["heaviest_safe_first"] = copy(heaviest.selected)

    greedy_start = time_ns()
    greedy = solve_journal_compression_weighted_greedy(instance)
    greedy_elapsed = time_ns() - greedy_start
    push!(rows, _financial_greedy_row(
        instance,
        greedy,
        structure,
        greedy_elapsed,
    ))
    selections[string(greedy.algorithm)] = copy(greedy.selected)

    reverse_start = time_ns()
    reverse = solve_journal_compression_weighted_greedy_reverse_delete(instance)
    reverse_elapsed = time_ns() - reverse_start
    push!(rows, _financial_greedy_row(
        instance,
        reverse,
        structure,
        reverse_elapsed,
    ))
    selections[string(reverse.algorithm)] = copy(reverse.selected)

    multistart = solve_journal_compression_multistart_random(
        instance;
        seed = controls.multistart_seed,
        starts = controls.multistart_count,
    )
    push!(rows, _financial_deletion_row(
        instance,
        multistart,
        structure,
        "multistart_random_deletion",
    ))
    selections["multistart_random_deletion"] = copy(multistart.selected)

    mip = solve_journal_compression_mip(
        instance;
        random_seed = controls.mip_seed,
        time_limit = controls.mip_time_limit_seconds,
        relative_mip_gap_tolerance = controls.mip_relative_gap_tolerance,
        absolute_mip_gap_tolerance = controls.mip_absolute_gap_tolerance,
        warm_start = :none,
        exact_crosscheck = :none,
    )
    push!(rows, _financial_mip_row(instance, mip, structure))
    solver_logs["preprocessed_highs_mip"] = mip.diagnostics.complete_solver_log
    if !isnothing(mip.reconstructed_candidate)
        selections["preprocessed_highs_mip"] = copy(mip.reconstructed_candidate)
    end

    mandatory = preprocess_mandatory_journal_instance(instance)
    residual = journal_reduced_cover_model(mandatory)
    if length(residual.requirements) <= controls.dp_requirement_limit
        dp = solve_journal_compression_dp(instance; retain_all_ties = false)
        push!(rows, _financial_dp_row(instance, dp, structure))
        selections["requirement_mask_dp"] = copy(dp.selected)
    else
        push!(
            rows,
            _financial_base_row(
                "requirement_mask_dp",
                "NOT_APPLICABLE_REQUIREMENT_LIMIT",
                "SKIPPED_RESIDUAL_REQUIREMENTS_$(length(residual.requirements))_EXCEED_LIMIT_$(controls.dp_requirement_limit)",
                structure,
            ),
        )
    end

    second_status = isnothing(controls.second_solver) ?
        "UNAVAILABLE_NO_SECOND_SOLVER_DECLARED" :
        "UNAVAILABLE_SECOND_SOLVER_ADAPTER_NOT_IMPLEMENTED"
    push!(
        rows,
        _financial_base_row(
            "optional_second_solver_crosscheck",
            "OPTIONAL",
            second_status,
            structure,
        ),
    )

    benchmark = _financial_benchmark(rows)
    rows = NamedTuple[_financial_add_gap(row, benchmark) for row in rows]
    rows = _financial_apply_heldout(rows, selections, heldout_evaluator)
    return FinancialAlgorithmComparisonResult(
        FINANCIAL_ALGORITHM_COMPARISON_SCHEMA_VERSION,
        String(audit_id),
        String(audit_label),
        String(schedule_id),
        String(heldout_unit),
        journal_compression_instance_sha256(instance),
        instance.strategy_ids,
        structure,
        controls,
        rows,
        selections,
        solver_logs,
        benchmark,
        "held-out evaluator is called only after all optimization rows and burden gaps are frozen",
    )
end


"""Independently recompute every saved endpoint and its exact burden."""
function audit_financial_algorithm_comparison(
    instance::JournalCompressionInstance,
    result::FinancialAlgorithmComparisonResult,
)
    validate_journal_compression_instance(instance)
    result.schema_version == FINANCIAL_ALGORITHM_COMPARISON_SCHEMA_VERSION || throw(
        ArgumentError("unexpected financial comparison schema"),
    )
    journal_compression_instance_sha256(instance) == result.instance_sha256 || throw(
        ArgumentError("financial comparison instance hash mismatch"),
    )
    errors = String[]
    checked = 0
    for row in result.rows
        haskey(result.selected_by_algorithm, row.algorithm_id) || begin
            row.exact_feasible === true && push!(
                errors,
                "$(row.algorithm_id) claims exact feasibility without a saved selection",
            )
            continue
        end
        selected = result.selected_by_algorithm[row.algorithm_id]
        check = check_journal_compression_solution(instance, selected)
        checked += 1
        check.exact_feasible == row.exact_feasible || push!(
            errors,
            "$(row.algorithm_id) exact-feasibility field disagrees with audit",
        )
        check.exact_burden == row.exact_reconstructed_burden || push!(
            errors,
            "$(row.algorithm_id) exact burden disagrees with audit",
        )
        check.mandatory_retained == row.exact_mandatory_retention || push!(
            errors,
            "$(row.algorithm_id) mandatory-retention field disagrees with audit",
        )
        check.frontier_preserved == row.exact_frontier_preservation || push!(
            errors,
            "$(row.algorithm_id) frontier field disagrees with audit",
        )
        check.closure_preserved == row.exact_closure_preservation || push!(
            errors,
            "$(row.algorithm_id) closure field disagrees with audit",
        )
    end
    any(row -> row.solver_status_used_as_exact_proof, result.rows) && push!(
        errors,
        "a solver status is marked as exact proof",
    )
    isempty(strip(result.audit_id)) && push!(errors, "audit identifier is empty")
    isempty(strip(result.heldout_unit)) && push!(errors, "held-out unit is empty")
    return (
        passed = isempty(errors),
        errors,
        checked_selection_count = checked,
        audit_id = result.audit_id,
        schedule_id = result.schedule_id,
        heldout_unit = result.heldout_unit,
        instance_sha256 = result.instance_sha256,
        evidence_class = "independent exact finite recomputation",
        solver_status_used_as_proof = false,
    )
end


function _financial_payload_value(value)
    value === missing && return Dict{String,Any}("available" => false)
    value === nothing && return Dict{String,Any}("available" => false)
    value isa Rational && return _financial_exact_text(value)
    value isa BigInt && return string(value)
    value isa UInt64 && return string(value)
    value isa Symbol && return string(value)
    value isa NamedTuple && return Dict{String,Any}(
        string(key) => _financial_payload_value(getproperty(value, key)) for
        key in keys(value)
    )
    value isa AbstractDict && return Dict{String,Any}(
        string(key) => _financial_payload_value(entry) for (key, entry) in value
    )
    value isa Tuple && return [_financial_payload_value(entry) for entry in value]
    value isa AbstractVector && return [_financial_payload_value(entry) for entry in value]
    return value
end


"""Machine-readable, raw-row-free payload for one comparison result."""
function financial_algorithm_comparison_payload(result::FinancialAlgorithmComparisonResult)
    selection_payload = Dict{String,Any}(
        algorithm => Dict(
            "selected_strategy_indices" => findall(selected),
            "selected_strategy_ids" => [
                _financial_id(result.strategy_ids[index]) for index in findall(selected)
            ],
        ) for (algorithm, selected) in result.selected_by_algorithm
    )
    return Dict{String,Any}(
        "schema_version" => result.schema_version,
        "audit_id" => result.audit_id,
        "audit_label" => result.audit_label,
        "schedule_id" => result.schedule_id,
        "heldout_unit" => result.heldout_unit,
        "instance_sha256" => result.instance_sha256,
        "heldout_evaluation_phase" => result.heldout_evaluation_phase,
        "structure" => _financial_payload_value(result.structure),
        "controls" => _financial_payload_value((;
            dp_requirement_limit = result.controls.dp_requirement_limit,
            multistart_count = result.controls.multistart_count,
            multistart_seed = result.controls.multistart_seed,
            mip_seed = result.controls.mip_seed,
            mip_time_limit_seconds = result.controls.mip_time_limit_seconds,
            mip_relative_gap_tolerance = result.controls.mip_relative_gap_tolerance,
            mip_absolute_gap_tolerance = result.controls.mip_absolute_gap_tolerance,
            second_solver = result.controls.second_solver,
        )),
        "benchmark" => _financial_payload_value(result.benchmark),
        "rows" => [_financial_payload_value(row) for row in result.rows],
        "selections" => selection_payload,
        "solver_log_algorithms" => sort!(collect(keys(result.solver_logs))),
        "licensed_rows_included" => false,
    )
end


function serialize_financial_algorithm_comparison(
    result::FinancialAlgorithmComparisonResult,
)
    io = IOBuffer()
    TOML.print(io, financial_algorithm_comparison_payload(result); sorted = true)
    return String(take!(io))
end
