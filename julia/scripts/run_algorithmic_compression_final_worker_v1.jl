module AlgorithmicCompressionFinalWorkerV1

using Dates
using HiGHS
using LinearAlgebra
using JuMP
using StrategyInnovation
using TOML

include(joinpath(@__DIR__, "run_algorithmic_compression_pilot_v1.jl"))
using .AlgorithmicCompressionPilotV1

export main, run_job

const WORKER_SCHEMA_VERSION = "algorithmic-compression-final-worker-v1"


struct RegisteredMandatoryMIPResult
    status::String
    candidate_accepted::Bool
    selected::Union{Nothing,BitVector}
    exact_check::Union{Nothing,NamedTuple}
    solver_claimed_optimal::Bool
    complete_solver_log::String
    payload::Dict{String,Any}
end


_utc_now() = Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")


function _write_atomic_toml(path::AbstractString, payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    text = String(take!(io))
    mkpath(dirname(path))
    temporary = path * ".tmp.$(getpid())"
    open(temporary, "w") do output
        write(output, text)
    end
    mv(temporary, path; force = false)
    return text
end


function _full_preprocessed_search_instance(instance::JournalCompressionInstance)
    preprocessing = preprocess_tagged_cover(exact_tagged_cover_model(instance))
    preprocessing.feasible || error("full preprocessing declared the instance infeasible")
    retained = sort!(unique(vcat(
        preprocessing.forced_strategy_indices,
        preprocessing.remaining_strategy_indices,
    )))
    retained_ids = [instance.strategy_ids[index] for index in retained]
    retained_mandatory = BitVector(
        index in preprocessing.forced_strategy_indices for index in retained
    )
    frontier_requirements = FrontierRequirement[
        requirement for requirement in instance.requirements if
        requirement isa FrontierRequirement
    ]
    search = journal_compression_instance_from_components(
        retained_ids,
        retained_mandatory,
        instance.weights[retained],
        [requirement.belief for requirement in frontier_requirements],
        instance.operating_profiles[retained, :],
        [instance.strategy_modules[index] for index in retained];
        source_frontier = instance.source_frontier,
        source_closure = instance.source_closure,
        tie_handling = instance.tie_handling,
        provenance = instance.provenance,
    )
    index_by_id = Dict(
        strategy_id => index for (index, strategy_id) in enumerate(instance.strategy_ids)
    )
    search_to_original = Int[
        index_by_id[strategy_id] for strategy_id in search.strategy_ids
    ]
    return (; search, search_to_original, preprocessing)
end


function _solve_registered_mandatory_mip(
    instance::JournalCompressionInstance,
    random_seed::Int,
    time_limit::Float64,
)
    model_data = exact_tagged_cover_model(instance)
    forced = findall(model_data.mandatory)
    remaining_columns = Int[
        column for column in eachindex(model_data.strategy_ids) if
        !model_data.mandatory[column]
    ]
    satisfied_rows = Int[
        row for row in eachindex(model_data.requirements) if
        any(model_data.coverage[row, column] for column in forced)
    ]
    remaining_rows = Int[
        row for row in eachindex(model_data.requirements) if row ∉ satisfied_rows
    ]
    all(
        any(model_data.coverage[row, column] for column in remaining_columns) for
        row in remaining_rows
    ) || error("mandatory-only residual cover has a requirement without a carrier")

    objective_scale, scaled_weights =
        StrategyInnovation._scaled_safe_compression_objective(instance.weights)
    objective_offset = sum(
        (instance.weights[column] for column in forced);
        init = zero(ExactRational),
    )
    optimization_model = JuMP.Model(HiGHS.Optimizer)
    JuMP.set_attribute(optimization_model, "threads", 1)
    JuMP.set_attribute(optimization_model, "parallel", "off")
    JuMP.set_attribute(optimization_model, "random_seed", random_seed)
    JuMP.set_attribute(optimization_model, "time_limit", time_limit)
    JuMP.set_attribute(optimization_model, "mip_rel_gap", 0.0)
    JuMP.set_attribute(optimization_model, "mip_abs_gap", 0.0)
    JuMP.set_attribute(optimization_model, "presolve", "on")
    JuMP.set_silent(optimization_model)
    JuMP.@variable(optimization_model, x[remaining_columns], Bin)
    JuMP.@objective(
        optimization_model,
        Min,
        sum(scaled_weights[column] * x[column] for column in remaining_columns),
    )
    for row in remaining_rows
        carriers = Int[
            column for column in remaining_columns if
            model_data.coverage[row, column]
        ]
        JuMP.@constraint(
            optimization_model,
            sum(x[column] for column in carriers) >= 1,
        )
    end
    solver_log, optimization_wall_ns =
        StrategyInnovation._journal_mip_optimize_with_log!(optimization_model)
    termination = string(JuMP.termination_status(optimization_model))
    solver_claimed_optimal = termination == "OPTIMAL"
    has_primal = JuMP.has_values(optimization_model)
    raw_values = has_primal ? Float64[
        JuMP.value(x[column]) for column in remaining_columns
    ] : Float64[]
    decoded = has_primal ?
              StrategyInnovation._journal_mip_decode_binary_values(raw_values) :
              (exact = false, selected = nothing, reason = "solver returned no primal values")
    selected = nothing
    exact_check = nothing
    accepted = false
    if has_primal && decoded.exact
        candidate = falses(length(instance.strategy_ids))
        candidate[forced] .= true
        for (position, column) in enumerate(remaining_columns)
            candidate[column] = decoded.selected[position]
        end
        check = check_journal_compression_solution(instance, candidate)
        if check.exact_feasible
            selected = candidate
            exact_check = check
            accepted = true
        end
    end
    crosscheck = StrategyInnovation._journal_mip_crosscheck(
        instance,
        isnothing(exact_check) ? missing : exact_check.exact_burden,
        :auto,
        20,
        18,
    )
    if accepted && solver_claimed_optimal && crosscheck.performed &&
       crosscheck.candidate_matches_exact_optimum === false
        error("mandatory-only MIP OPTIMAL claim contradicts the exact oracle")
    end
    backend = JuMP.backend(optimization_model)
    optional_float(f) = try
        Float64(f())
    catch
        missing
    end
    scaled_objective = optional_float(() -> JuMP.objective_value(optimization_model))
    scaled_bound = optional_float(() -> JuMP.objective_bound(optimization_model))
    objective = ismissing(scaled_objective) ? missing : Float64(
        BigFloat(scaled_objective) / BigFloat(objective_scale) +
        BigFloat(numerator(objective_offset)) / BigFloat(denominator(objective_offset)),
    )
    bound = ismissing(scaled_bound) ? missing : Float64(
        BigFloat(scaled_bound) / BigFloat(objective_scale) +
        BigFloat(numerator(objective_offset)) / BigFloat(denominator(objective_offset)),
    )
    presolve = StrategyInnovation._journal_mip_presolve_reductions(solver_log)
    node_count = StrategyInnovation._journal_mip_node_count(optimization_model)
    status = accepted ? (solver_claimed_optimal ? "SOLVED" : "FEASIBLE_INCUMBENT") :
             "NO_PRIMAL_CANDIDATE"
    payload = Dict{String,Any}(
        "schema_version" => JOURNAL_MIP_SOLUTION_SCHEMA_VERSION,
        "algorithm" => "jump_highs_tagged_cover",
        "registered_external_variant" => true,
        "status" => status,
        "candidate_accepted" => accepted,
        "binary_values_exact" => has_primal && decoded.exact,
        "binary_value_rejection_reason" => decoded.reason,
        "solver_claimed_optimal" => solver_claimed_optimal,
        "solver_optimality_is_formal_proof" => false,
        "instance_sha256" => journal_compression_instance_sha256(instance),
        "raw_reduced_variable_values" => raw_values,
        "selected_strategy_indices" => isnothing(selected) ? Int[] : findall(selected),
        "selected_strategy_ids" => isnothing(selected) ? String[] :
            [string(instance.strategy_ids[index].id) for index in findall(selected)],
        "exact_burden" => isnothing(exact_check) ?
            Dict{String,Any}("available" => false) :
            Dict{String,Any}(
                "available" => true,
                "value" => encode_exact_rational(exact_check.exact_burden),
            ),
        "preprocessing" => Dict{String,Any}(
            "variant" => "mandatory_only",
            "original_strategy_count" => length(instance.strategy_ids),
            "reduced_strategy_count" => length(remaining_columns),
            "original_requirement_count" => length(instance.requirements),
            "reduced_requirement_count" => length(remaining_rows),
            "variables_removed" => length(forced),
            "requirements_removed" => length(satisfied_rows),
            "forced_strategy_indices" => forced,
            "remaining_strategy_indices" => remaining_columns,
            "remaining_requirement_indices" => remaining_rows,
            "exact_objective_offset" => encode_exact_rational(objective_offset),
            "fixed_point_iterations" => 0,
            "all_optimizer_identities_reconstructable" => true,
        ),
        "formulation" => Dict{String,Any}(
            "preprocessing_variant" => "mandatory_only",
            "original_binary_strategy_count" => length(instance.strategy_ids),
            "original_mandatory_equality_count" => length(forced),
            "original_tagged_cover_row_count" => length(instance.requirements),
            "residual_binary_variable_count" => length(remaining_columns),
            "residual_tagged_cover_row_count" => length(remaining_rows),
            "objective_scale" => string(objective_scale),
            "residual_scaled_objective" => scaled_weights[remaining_columns],
            "closure_kind" => "identity",
        ),
        "controls" => Dict{String,Any}(
            "threads" => 1,
            "parallel" => "off",
            "random_seed" => random_seed,
            "time_limit_seconds" => time_limit,
            "relative_mip_gap_tolerance" => 0.0,
            "absolute_mip_gap_tolerance" => 0.0,
            "presolve" => "on",
            "fractional_binary_rounding_permitted" => false,
        ),
        "solver_diagnostics" => Dict{String,Any}(
            "solver_name" => String(JuMP.MOI.get(backend, JuMP.MOI.SolverName())),
            "solver_version" => String(JuMP.MOI.get(backend, JuMP.MOI.SolverVersion())),
            "highs_julia_version" => string(Base.pkgversion(HiGHS)),
            "jump_version" => string(Base.pkgversion(JuMP)),
            "solver_invoked" => true,
            "termination_status" => termination,
            "primal_status" => string(JuMP.primal_status(optimization_model)),
            "dual_status" => string(JuMP.dual_status(optimization_model)),
            "raw_status" => JuMP.raw_status(optimization_model),
            "objective_value" => AlgorithmicCompressionPilotV1._serializable(objective),
            "best_bound" => AlgorithmicCompressionPilotV1._serializable(bound),
            "reported_relative_gap" => AlgorithmicCompressionPilotV1._serializable(
                optional_float(() -> JuMP.relative_gap(optimization_model)),
            ),
            "solve_time_seconds" => AlgorithmicCompressionPilotV1._serializable(
                optional_float(() -> JuMP.solve_time(optimization_model)),
            ),
            "node_count" => AlgorithmicCompressionPilotV1._serializable(node_count),
            "presolve_variables_removed" =>
                AlgorithmicCompressionPilotV1._serializable(presolve.variables),
            "presolve_rows_removed" =>
                AlgorithmicCompressionPilotV1._serializable(presolve.rows),
            "complete_solver_log" => solver_log,
        ),
        "exact_feasibility_certificate" => isnothing(exact_check) ?
            Dict{String,Any}("available" => false) :
            merge(
                Dict{String,Any}("available" => true),
                AlgorithmicCompressionPilotV1._serializable(exact_check),
            ),
        "crosscheck" => AlgorithmicCompressionPilotV1._serializable(crosscheck),
        "runtime" => Dict{String,Any}(
            "optimization_wall_ns" => string(optimization_wall_ns),
        ),
    )
    return RegisteredMandatoryMIPResult(
        status,
        accepted,
        selected,
        exact_check,
        solver_claimed_optimal,
        solver_log,
        payload,
    )
end


function _execute(instance, algorithm::Symbol, variant::Symbol, job)
    seed = parse(Int, String(job["random_order_seed"]))
    multistart_seed = parse(Int, String(job["multistart_seed"]))
    mip_seed = parse(Int, String(job["mip_seed"]))
    time_limit = Float64(job["time_limit_seconds"])

    search_instance = instance
    search_to_original = collect(eachindex(instance.strategy_ids))
    preprocessing = nothing
    if algorithm != :jump_highs_tagged_cover && variant in (
        :full_fixed_point,
        :full_fixed_point_then_reconstruct,
    )
        prepared = _full_preprocessed_search_instance(instance)
        search_instance = prepared.search
        search_to_original = prepared.search_to_original
        preprocessing = prepared.preprocessing
    end

    result = if algorithm == :complete_enumeration
        solve_journal_compression_enumeration(
            search_instance;
            retain_all_ties = true,
            maximum_optional_strategies = 14,
            maximum_ties = 100_000,
        )
    elseif algorithm == :requirement_mask_dp
        solve_journal_compression_dp(
            search_instance;
            retain_all_ties = variant == :mandatory_only,
            maximum_ties = 100_000,
        )
    elseif algorithm == :jump_highs_tagged_cover
        if variant == :mandatory_only
            _solve_registered_mandatory_mip(instance, mip_seed, time_limit)
        else
            solve_journal_compression_mip(
                instance;
                random_seed = mip_seed,
                time_limit,
                relative_mip_gap_tolerance = 0.0,
                absolute_mip_gap_tolerance = 0.0,
                exact_crosscheck = :auto,
                enumeration_crosscheck_limit = 20,
                dp_crosscheck_requirement_limit = 18,
            )
        end
    elseif algorithm == :weighted_greedy
        solve_journal_compression_weighted_greedy(search_instance)
    elseif algorithm == :cardinality_greedy
        solve_journal_compression_cardinality_greedy(search_instance)
    elseif algorithm == :weighted_greedy_reverse_delete
        solve_journal_compression_weighted_greedy_reverse_delete(search_instance)
    elseif algorithm == :heaviest_safe_first
        solve_journal_compression_heaviest_safe_first(search_instance)
    elseif algorithm == :lightest_safe_first
        solve_journal_compression_lightest_safe_first(search_instance)
    elseif algorithm == :maximum_immediate_burden_release
        solve_journal_compression_maximum_immediate_burden_release(search_instance)
    elseif algorithm == :minimum_unique_carrier_exposure
        solve_journal_compression_minimum_unique_carrier_exposure(search_instance)
    elseif algorithm == :declared_source_order
        solve_journal_compression_declared_order(search_instance)
    elseif algorithm == :random_order_rechecked_deletion
        solve_journal_compression_random_order(search_instance; seed)
    elseif algorithm == :multistart_random_rechecked_deletion_32
        solve_journal_compression_multistart_random(
            search_instance;
            seed = multistart_seed,
            starts = 32,
        )
    else
        error("unsupported final algorithm $algorithm")
    end

    selected_local = if result isa JournalMIPSolutionResult
        result.reconstructed_candidate
    elseif result isa RegisteredMandatoryMIPResult
        result.selected
    else
        result.selected
    end
    selected_original = if isnothing(selected_local)
        nothing
    else
        selected = falses(length(instance.strategy_ids))
        for (local_index, retained) in enumerate(selected_local)
            retained || continue
            selected[search_to_original[local_index]] = true
        end
        selected
    end
    exact_check = isnothing(selected_original) ? nothing :
                  check_journal_compression_solution(instance, selected_original)
    if !isnothing(exact_check)
        exact_check.exact_feasible || error(
            "returned solution failed the independent original-instance exact recheck",
        )
    end
    preprocessing_payload = isnothing(preprocessing) ?
        Dict{String,Any}("available" => false) :
        Dict{String,Any}(
            "available" => true,
            "audit" => AlgorithmicCompressionPilotV1._serializable(preprocessing.audit),
            "forced_strategy_indices" => preprocessing.forced_strategy_indices,
            "remaining_strategy_indices" => preprocessing.remaining_strategy_indices,
            "remaining_requirement_indices" => preprocessing.remaining_requirement_indices,
            "objective_offset" => encode_exact_rational(preprocessing.objective_offset),
            "all_optimizer_identities_reconstructable" =>
                preprocessing.all_optimizer_identities_reconstructable,
        )
    return (; result, selected_original, exact_check, preprocessing_payload)
end


function _worker_payload(job, timed, execution, started_at, finished_at)
    result = execution.result
    selected = execution.selected_original
    exact_check = execution.exact_check
    candidate_accepted = !isnothing(selected)
    status = if result isa JournalMIPSolutionResult
        if result.candidate_accepted && !result.diagnostics.solver_invoked
            "SOLVED_BY_EXACT_PREPROCESSING"
        elseif result.candidate_accepted && result.solver_claimed_optimal
            "SOLVED"
        elseif result.candidate_accepted
            "FEASIBLE_INCUMBENT"
        else
            uppercase(string(result.status))
        end
    elseif result isa RegisteredMandatoryMIPResult
        result.status
    else
        "SOLVED"
    end
    evidence_class = if result isa JournalExactSolutionResult
        "exact finite computation"
    elseif result isa Union{JournalMIPSolutionResult,RegisteredMandatoryMIPResult}
        solver_invoked = result isa JournalMIPSolutionResult ?
            result.diagnostics.solver_invoked : true
        solver_invoked ?
        "mixed-integer solver evidence plus exact post-check" :
        "exact finite preprocessing computation"
    elseif result isa JournalGreedySolutionResult
        "synthetic heuristic evidence plus exact feasibility check"
    else
        "synthetic rechecked-deletion evidence plus exact feasibility check"
    end
    compile_time = :compile_time in propertynames(timed) ? timed.compile_time : nothing
    return Dict{String,Any}(
        "schema_version" => WORKER_SCHEMA_VERSION,
        "worker_status" => "COMPLETED",
        "status" => status,
        "candidate_accepted" => candidate_accepted,
        "evidence_class" => evidence_class,
        "algorithm_id" => String(job["algorithm_id"]),
        "preprocessing_variant" => String(job["preprocessing_variant"]),
        "julia_threads" => Threads.nthreads(),
        "blas_threads" => LinearAlgebra.BLAS.get_num_threads(),
        "highs_threads" => 1,
        "instance_id" => String(job["instance_id"]),
        "instance_sha256" => String(job["instance_sha256"]),
        "started_at_utc" => started_at,
        "finished_at_utc" => finished_at,
        "algorithm_wall_clock_ns" => Int(round(timed.time * 1.0e9)),
        "julia_allocated_bytes" => timed.bytes,
        "gc_time_seconds" => timed.gctime,
        "compile_time_seconds" => isnothing(compile_time) ? "UNAVAILABLE" : compile_time,
        "selected_original_strategy_indices" =>
            isnothing(selected) ? Int[] : findall(selected),
        "selected_original_strategy_ids" => isnothing(selected) ? String[] :
            [string(job["strategy_ids"][index]) for index in findall(selected)],
        "exact_burden" => isnothing(exact_check) ?
            Dict{String,Any}("available" => false) :
            Dict{String,Any}(
                "available" => true,
                "value" => encode_exact_rational(exact_check.exact_burden),
            ),
        "exact_feasibility_recheck" => isnothing(exact_check) ?
            Dict{String,Any}("available" => false) :
            merge(
                Dict{String,Any}("available" => true),
                AlgorithmicCompressionPilotV1._serializable(exact_check),
            ),
        "full_preprocessing_sensitivity" => execution.preprocessing_payload,
        "method_result" => result isa RegisteredMandatoryMIPResult ?
            result.payload : AlgorithmicCompressionPilotV1._result_payload(result),
    )
end


function run_job(path::AbstractString)
    job = TOML.parsefile(path)
    job["schema_version"] == "algorithmic-compression-final-job-v1" || error(
        "unsupported final worker job schema",
    )
    Threads.nthreads() == 1 || error("final worker requires one Julia thread")
    LinearAlgebra.BLAS.set_num_threads(1)
    instance = open(read_journal_compression_instance, String(job["instance_path"]))
    journal_compression_instance_sha256(instance) == job["instance_sha256"] || error(
        "final worker instance hash mismatch",
    )
    GC.gc(true)
    handshake = Dict{String,Any}(
        "schema_version" => "algorithmic-compression-final-handshake-v1",
        "worker_pid" => getpid(),
        "instance_id" => String(job["instance_id"]),
        "algorithm_id" => String(job["algorithm_id"]),
        "preprocessing_variant" => String(job["preprocessing_variant"]),
        "timing_scope_started_at_utc" => _utc_now(),
    )
    _write_atomic_toml(String(job["handshake_path"]), handshake)
    started_at = _utc_now()
    payload = try
        timed = @timed _execute(
            instance,
            Symbol(job["algorithm_id"]),
            Symbol(job["preprocessing_variant"]),
            job,
        )
        _worker_payload(job, timed, timed.value, started_at, _utc_now())
    catch error
        Dict{String,Any}(
            "schema_version" => WORKER_SCHEMA_VERSION,
            "worker_status" => "ERROR",
            "status" => "IMPLEMENTATION_ERROR",
            "candidate_accepted" => false,
            "algorithm_id" => String(job["algorithm_id"]),
            "preprocessing_variant" => String(job["preprocessing_variant"]),
            "instance_id" => String(job["instance_id"]),
            "instance_sha256" => String(job["instance_sha256"]),
            "started_at_utc" => started_at,
            "finished_at_utc" => _utc_now(),
            "exception_type" => string(typeof(error)),
            "message" => sprint(showerror, error),
            "backtrace" => sprint(Base.show_backtrace, catch_backtrace()),
        )
    end
    _write_atomic_toml(String(job["worker_output_path"]), payload)
    return payload["worker_status"] == "COMPLETED"
end


function main(args = ARGS)
    length(args) == 1 || error(
        "usage: run_algorithmic_compression_final_worker_v1.jl JOB.toml",
    )
    run_job(only(args)) || exit(2)
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    AlgorithmicCompressionFinalWorkerV1.main()
end
