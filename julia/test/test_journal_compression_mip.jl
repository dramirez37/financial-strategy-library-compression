using TOML


function _mip_provenance(instance_id; kind = :synthetic)
    return JournalCompressionProvenance(
        kind,
        String(instance_id),
        "exact in-repository journal MIP fixture";
        generator = "test_journal_compression_mip",
        attributes = ["evidence_class" => "exact finite solver fixture"],
    )
end


function _mip_instance(
    instance_id,
    ids,
    mandatory,
    weights,
    modules;
    tie_handling = default_journal_tie_handling(),
)
    return journal_compression_instance_from_components(
        ids,
        mandatory,
        weights,
        [:zero_frontier],
        zeros(Int, length(ids), 1),
        modules;
        tie_handling,
        provenance = _mip_provenance(instance_id),
    )
end


function _mip_selected_ids(result)
    return Set(strategy_id.id for strategy_id in result.selected_strategy_ids)
end


@testset "auditable JuMP/HiGHS tagged-cover workflow" begin
    instance = _mip_instance(
        "triangle-cover",
        [:inactive, :a, :b, :c],
        Bool[true, false, false, false],
        [0, 2, 2, 2],
        [Symbol[], [:m1, :m2], [:m2, :m3], [:m1, :m3]],
    )
    result = solve_journal_compression_mip(
        instance;
        random_seed = 17,
        time_limit = 10.0,
        warm_start = :full_source,
    )
    repeated = solve_journal_compression_mip(
        instance;
        random_seed = 17,
        time_limit = 10.0,
        warm_start = :full_source,
    )

    @test result.schema_version == JOURNAL_MIP_SOLUTION_SCHEMA_VERSION
    @test result.algorithm == :jump_highs_tagged_cover
    @test result.status == :exactly_rechecked_solver_candidate
    @test result.candidate_accepted
    @test result.binary_values_exact
    @test isempty(result.binary_value_rejection_reason)
    @test result.solver_claimed_optimal
    @test result.exact_global_optimum_verified
    @test result.exact_burden == 4 // 1
    @test journal_compression_burden(
        instance,
        result.reconstructed_candidate,
    ) == result.exact_burden
    @test journal_compression_feasible(instance, result.reconstructed_candidate)
    @test _mip_selected_ids(result) in (
        Set([:inactive, :a, :b]),
        Set([:inactive, :a, :c]),
        Set([:inactive, :b, :c]),
    )
    @test result.reconstructed_candidate == repeated.reconstructed_candidate
    @test result.raw_reduced_variable_values ==
          repeated.raw_reduced_variable_values

    @test result.controls.threads == 1
    @test result.controls.parallel == "off"
    @test result.controls.random_seed == 17
    @test result.controls.time_limit_seconds == 10.0
    @test result.controls.relative_mip_gap_tolerance == 0.0
    @test result.controls.absolute_mip_gap_tolerance == 0.0
    @test result.controls.presolve == "on"
    @test !result.controls.log_to_console
    @test result.controls.complete_log_captured
    @test result.warm_start_source ==
          "complete source library projected through exact preprocessing"

    @test result.formulation.original_binary_strategy_count == 4
    @test result.formulation.original_mandatory_equality_count == 1
    @test result.formulation.original_tagged_cover_row_count == 4
    @test result.formulation.residual_binary_variable_count == 3
    @test result.formulation.residual_tagged_cover_row_count == 3
    @test result.formulation.residual_nonzero_count == 6
    @test result.formulation.objective_scale == 1
    @test result.formulation.scaled_objective_offset == 0
    @test result.formulation.residual_scaled_objective == Int64[2, 2, 2]
    @test result.formulation.mandatory_equalities_substituted_by_exact_preprocessing
    @test result.formulation.closure_kind == :identity

    @test result.preprocessing.variables_removed == 1
    @test result.preprocessing.requirements_removed == 1
    @test result.preprocessing.forced_strategy_indices ==
          sort(result.preprocessing.forced_strategy_indices)
    @test result.preprocessing.rerun_from_original_instance
    @test result.preprocessing.audit["fixed_point"]
    @test result.preprocessing.audit["arithmetic"] == "Rational{BigInt}"
    @test result.preprocessing.audit["rule_counts"]["mandatory_strategy"][
        "applications"
    ] == 1

    @test result.diagnostics.solver_name == "HiGHS"
    @test !isempty(result.diagnostics.solver_version)
    @test result.diagnostics.highs_julia_version ==
          string(Base.pkgversion(StrategyInnovation.HiGHS))
    @test result.diagnostics.jump_version ==
          string(Base.pkgversion(StrategyInnovation.JuMP))
    @test result.diagnostics.solver_invoked
    @test result.diagnostics.termination_status == "OPTIMAL"
    @test result.diagnostics.primal_status == "FEASIBLE_POINT"
    @test result.diagnostics.dual_status == "NO_SOLUTION"
    @test !isempty(result.diagnostics.raw_status)
    @test result.diagnostics.objective_value == 4.0
    @test result.diagnostics.best_bound == 4.0
    @test result.diagnostics.reported_relative_gap == 0.0
    @test result.diagnostics.solve_time_seconds >= 0.0
    @test ismissing(result.diagnostics.node_count) ||
          result.diagnostics.node_count >= 0
    @test ismissing(result.diagnostics.presolve_variables_removed) ||
          result.diagnostics.presolve_variables_removed >= 0
    @test ismissing(result.diagnostics.presolve_rows_removed) ||
          result.diagnostics.presolve_rows_removed >= 0
    @test occursin("Running HiGHS", result.diagnostics.complete_solver_log)
    @test occursin("Presolve", result.diagnostics.complete_solver_log)
    @test occursin("Solving report", result.diagnostics.complete_solver_log)
    parsed_presolve = StrategyInnovation._journal_mip_presolve_reductions(
        "Presolve reductions: rows 2(-3); columns 4(-5); nonzeros 6(-7)",
    )
    @test parsed_presolve.variables == 5
    @test parsed_presolve.rows == 3

    certificate = result.exact_feasibility_certificate
    @test certificate.exact_feasible
    @test certificate.mandatory_retained
    @test certificate.tagged_coverage
    @test certificate.frontier_preserved
    @test certificate.closure_preserved
    @test certificate.burden_reconciled
    @test certificate.arithmetic == "Rational{BigInt}"
    @test !certificate.solver_status_used_as_proof
    @test !certificate.lean_kernel_verified

    @test result.crosscheck.performed
    @test result.crosscheck.algorithm == :complete_enumeration
    @test result.crosscheck.exact_optimum_burden == 4 // 1
    @test result.crosscheck.candidate_matches_exact_optimum === true
    @test result.runtime.total_ns >= result.runtime.preprocessing_ns
    @test result.runtime.total_ns >= result.runtime.model_build_ns
    @test result.runtime.total_ns >= result.runtime.optimization_wall_ns
    @test result.runtime.total_ns >=
          result.runtime.reconstruction_and_certification_ns
    @test result.runtime.total_ns >= result.runtime.crosscheck_ns

    serialized = serialize_journal_mip_solution(result)
    payload = TOML.parse(serialized)
    @test payload["schema_version"] == JOURNAL_MIP_SOLUTION_SCHEMA_VERSION
    @test payload["solver_optimality_is_formal_proof"] == false
    @test payload["solver_diagnostics"]["complete_solver_log"] ==
          result.diagnostics.complete_solver_log
    @test payload["solver_diagnostics"]["solver_version"] ==
          result.diagnostics.solver_version
    @test payload["exact_burden"]["value"] == "4//1"
    @test payload["crosscheck"]["candidate_matches_exact_optimum"]["value"]
    output = IOBuffer()
    write_journal_mip_solution_certificate(output, result)
    @test String(take!(output)) == serialized
end


@testset "rational objective, DP cross-check, and declared warm start" begin
    instance = _mip_instance(
        "rational-triangle-cover",
        [:inactive, :a, :b, :c],
        Bool[true, false, false, false],
        [0, 1 // 3, 1 // 2, 2 // 3],
        [Symbol[], [:m1, :m2], [:m2, :m3], [:m1, :m3]],
    )
    result = solve_journal_compression_mip(
        instance;
        warm_start = trues(length(instance.strategy_ids)),
        warm_start_source = "test full-source vector",
        exact_crosscheck = :dp,
        enumeration_crosscheck_limit = 0,
        dp_crosscheck_requirement_limit = 3,
    )
    @test result.candidate_accepted
    @test result.exact_burden == 5 // 6
    @test _mip_selected_ids(result) == Set([:inactive, :a, :b])
    @test result.formulation.objective_scale == 6
    @test result.formulation.residual_scaled_objective == Int64[2, 3, 4]
    @test result.warm_start_source == "test full-source vector"
    @test result.crosscheck.performed
    @test result.crosscheck.algorithm == :requirement_mask_dp
    @test result.crosscheck.exact_optimum_burden == 5 // 6
    @test result.crosscheck.candidate_matches_exact_optimum === true
    @test isapprox(
        result.diagnostics.objective_value,
        Float64(5 // 6);
        atol = 0,
        rtol = eps(Float64),
    )
end


@testset "warm start follows exact preprocessing elimination targets" begin
    instance = _mip_instance(
        "dominated-warm-start-projection",
        [:inactive, :dominated, :dominator, :right, :alternate],
        Bool[true, false, false, false, false],
        [0, 2, 1, 2, 3],
        [
            Symbol[],
            [:m1],
            [:m1, :m2],
            [:m2, :m3],
            [:m1, :m3],
        ],
    )
    inactive_index = findfirst(strategy -> strategy.id == :inactive, instance.strategy_ids)
    dominated_index = findfirst(strategy -> strategy.id == :dominated, instance.strategy_ids)
    dominator_index = findfirst(strategy -> strategy.id == :dominator, instance.strategy_ids)
    right_index = findfirst(strategy -> strategy.id == :right, instance.strategy_ids)
    warm_start = falses(length(instance.strategy_ids))
    warm_start[[inactive_index, dominated_index, right_index]] .= true
    @test journal_compression_feasible(instance, warm_start)
    preprocessing = preprocess_tagged_cover(exact_tagged_cover_model(instance))
    @test preprocessing.strategy_status[dominated_index] == :dominated_strict_weight
    @test preprocessing.strategy_elimination_target[dominated_index] == dominator_index

    result = solve_journal_compression_mip(
        instance;
        warm_start,
        warm_start_source = "dominated feasible test candidate",
        preprocessing_result = preprocessing,
        exact_crosscheck = :enumeration,
        enumeration_crosscheck_limit = 4,
    )
    @test result.candidate_accepted
    @test result.solver_claimed_optimal
    @test result.exact_global_optimum_verified
    @test result.exact_burden == 3 // 1
    @test journal_compression_feasible(instance, result.reconstructed_candidate)
    @test result.warm_start_source ==
          "dominated feasible test candidate; exact preprocessing substitution projection"
end


@testset "exact preprocessing can solve the residual before HiGHS" begin
    instance = _mip_instance(
        "preprocessing-solved",
        [:inactive, :a, :b, :c],
        Bool[true, false, false, false],
        [0, 1, 2, 3],
        [Symbol[], [:m1], [:m1], [:m2]],
    )
    result = solve_journal_compression_mip(instance)
    preprocessing = preprocess_tagged_cover(exact_tagged_cover_model(instance))
    reused = solve_journal_compression_mip(
        instance;
        preprocessing_result = preprocessing,
    )
    @test result.candidate_accepted
    @test result.exact_burden == 4 // 1
    @test _mip_selected_ids(result) == Set([:inactive, :a, :c])
    @test result.formulation.residual_binary_variable_count == 0
    @test result.formulation.residual_tagged_cover_row_count == 0
    @test result.preprocessing.variables_removed == 4
    @test result.preprocessing.requirements_removed == 3
    @test result.preprocessing.forced_strategy_indices ==
          sort(result.preprocessing.forced_strategy_indices)
    @test result.preprocessing.audit["rule_counts"]["duplicate_coverage"][
        "applications"
    ] >= 1
    @test !result.diagnostics.solver_invoked
    @test result.diagnostics.termination_status ==
          "NOT_CALLED_PREPROCESSING_SOLVED"
    @test occursin("HiGHS not invoked", result.diagnostics.complete_solver_log)
    @test !result.solver_claimed_optimal
    @test result.exact_global_optimum_verified
    @test result.crosscheck.algorithm == :complete_enumeration
    @test result.crosscheck.candidate_matches_exact_optimum === true
    @test isempty(result.raw_reduced_variable_values)
    @test reused.exact_burden == result.exact_burden
    @test reused.reconstructed_candidate == result.reconstructed_candidate
    other = _mip_instance(
        "mismatched-preprocessing",
        [:inactive, :only],
        Bool[true, false],
        [0, 1],
        [Symbol[], [:other]],
    )
    @test_throws ArgumentError solve_journal_compression_mip(
        instance;
        preprocessing_result = preprocess_tagged_cover(exact_tagged_cover_model(other)),
    )
end


@testset "exhaustive small MIP comparison with exact enumeration" begin
    checked_instances = 0
    for active_count in 1:3, module_count in 1:2
        carrier_pattern_count = (1 << active_count) - 1
        system_count = carrier_pattern_count^module_count
        for encoded_system in 0:(system_count - 1)
            patterns = Int[]
            remainder = encoded_system
            for _ in 1:module_count
                push!(patterns, (remainder % carrier_pattern_count) + 1)
                remainder = div(remainder, carrier_pattern_count)
            end
            ids = Any[
                :inactive;
                [Symbol("s_$index") for index in 1:active_count]
            ]
            modules = [Symbol[] for _ in eachindex(ids)]
            for module_index in 1:module_count
                module_id = Symbol("m_$module_index")
                for active_index in 1:active_count
                    iszero(
                        patterns[module_index] & (1 << (active_index - 1)),
                    ) && continue
                    push!(modules[active_index + 1], module_id)
                end
            end
            weights = Any[0]
            for active_index in 1:active_count
                push!(
                    weights,
                    BigInt(1 + mod(active_index + encoded_system, 5)) //
                    BigInt(1 + mod(active_index, 2)),
                )
            end
            instance = _mip_instance(
                "exhaustive-a$(active_count)-m$(module_count)-$(encoded_system)",
                ids,
                Bool[true; falses(active_count)],
                weights,
                modules,
            )
            oracle = solve_journal_compression_enumeration(
                instance;
                retain_all_ties = false,
                maximum_optional_strategies = 3,
            )
            result = solve_journal_compression_mip(
                instance;
                enumeration_crosscheck_limit = 3,
            )
            warm_started = solve_journal_compression_mip(
                instance;
                warm_start = oracle.selected,
                warm_start_source = "exhaustive exact feasible candidate",
                enumeration_crosscheck_limit = 3,
            )
            @test result.candidate_accepted
            @test result.exact_burden == oracle.exact_burden
            @test result.exact_global_optimum_verified
            @test result.crosscheck.algorithm == :complete_enumeration
            @test journal_compression_feasible(
                instance,
                result.reconstructed_candidate,
            )
            @test result.diagnostics.solver_invoked ?
                  result.diagnostics.termination_status == "OPTIMAL" :
                  result.diagnostics.termination_status ==
                  "NOT_CALLED_PREPROCESSING_SOLVED"
            @test warm_started.candidate_accepted
            @test warm_started.exact_burden == oracle.exact_burden
            @test warm_started.exact_global_optimum_verified
            checked_instances += 1
        end
    end
    @test checked_instances == 70
end


@testset "time limit and nonbinary rejection remain explicit" begin
    strategy_count = 40
    ids = Any[:inactive; [Symbol("s_$index") for index in 1:strategy_count]]
    modules = Any[Symbol[]]
    for index in 1:strategy_count
        push!(
            modules,
            [
                Symbol("m_$index"),
                Symbol("m_$(mod(index, strategy_count) + 1)"),
            ],
        )
    end
    instance = _mip_instance(
        "zero-time-limit-cycle",
        ids,
        Bool[true; falses(strategy_count)],
        Any[0; fill(1, strategy_count)],
        modules,
    )
    result = solve_journal_compression_mip(
        instance;
        time_limit = 0.0,
        exact_crosscheck = :none,
    )
    @test result.diagnostics.solver_invoked
    @test result.diagnostics.termination_status == "TIME_LIMIT"
    @test result.diagnostics.primal_status == "NO_SOLUTION"
    @test result.status == :no_primal_candidate
    @test !result.candidate_accepted
    @test !result.solver_claimed_optimal
    @test !result.exact_global_optimum_verified
    @test ismissing(result.exact_burden)
    @test isnothing(result.reconstructed_candidate)
    @test isempty(result.selected_strategy_ids)
    @test ismissing(result.diagnostics.objective_value)
    @test !ismissing(result.diagnostics.best_bound)
    @test !ismissing(result.diagnostics.reported_relative_gap)
    @test !result.crosscheck.performed
    @test result.crosscheck.applicability_declaration == "disabled explicitly"
    @test occursin("Time limit reached", result.diagnostics.complete_solver_log)
    timeout_payload = TOML.parse(serialize_journal_mip_solution(result))
    @test !timeout_payload["solver_diagnostics"]["objective_value"]["available"]
    @test timeout_payload["solver_diagnostics"]["best_bound"]["available"]

    fractional = StrategyInnovation._journal_mip_decode_binary_values(
        [0.0, 0.5, 1.0],
    )
    @test !fractional.exact
    @test isnothing(fractional.selected)
    @test occursin("fractional", fractional.reason)
    exact = StrategyInnovation._journal_mip_decode_binary_values(
        [-0.0, 1.0],
    )
    @test exact.exact
    @test exact.selected == Bool[false, true]
end


@testset "journal MIP option and claim-boundary validation" begin
    instance = _mip_instance(
        "option-validation",
        [:inactive, :a, :b],
        Bool[true, false, false],
        [0, 1, 1],
        [Symbol[], [:m], [:m]],
    )
    @test_throws ArgumentError solve_journal_compression_mip(
        instance;
        random_seed = -1,
    )
    @test_throws ArgumentError solve_journal_compression_mip(
        instance;
        time_limit = -1,
    )
    @test_throws ArgumentError solve_journal_compression_mip(
        instance;
        relative_mip_gap_tolerance = -eps(),
    )
    @test_throws ArgumentError solve_journal_compression_mip(
        instance;
        absolute_mip_gap_tolerance = Inf,
    )
    @test_throws ArgumentError solve_journal_compression_mip(
        instance;
        warm_start = falses(length(instance.strategy_ids)),
    )
    @test_throws ArgumentError solve_journal_compression_mip(
        instance;
        exact_crosscheck = :unknown,
    )
    @test_throws ArgumentError solve_journal_compression_mip(
        instance;
        exact_crosscheck = :enumeration,
        enumeration_crosscheck_limit = 0,
    )

    complete_ties = JournalTieHandling(
        :complete;
        declaration = "all exact ties required",
        stable_selector = "canonical presentation order",
    )
    complete_instance = _mip_instance(
        "complete-tie-rejection",
        [:inactive, :a, :b],
        Bool[true, false, false],
        [0, 1, 1],
        [Symbol[], [:m], [:m]];
        tie_handling = complete_ties,
    )
    @test_throws ArgumentError solve_journal_compression_mip(complete_instance)
end
