using Aqua
using Random: rand
using StrategyInnovation
using Test

include("core.jl")
include("test_raw_dynamic_programming.jl")
include("test_realizable_rectangles.jl")
include(joinpath(@__DIR__, "..", "scripts", "search_unified_benchmark.jl"))
using .UnifiedBenchmarkSearch
include("test_unified_benchmark_search.jl")
include(joinpath(@__DIR__, "..", "scripts", "solve_unified_canonical_benchmark.jl"))
using .UnifiedCanonicalBenchmarkSolver
include("test_unified_canonical_benchmark.jl")
include(joinpath(@__DIR__, "..", "scripts", "run_unified_comparative_statics.jl"))
using .UnifiedComparativeStaticsExperiment
include("test_comparative_statics.jl")

include(joinpath(@__DIR__, "..", "scripts", "run_randomized_library_stress.jl"))
using .RandomizedLibraryStressExperiment
include(joinpath(@__DIR__, "..", "scripts", "lock_randomized_library_design_v2.jl"))
using .LockRandomizedLibraryDesignV2
include("test_randomized_libraries.jl")
include("test_randomized_design_v2.jl")
include("test_randomized_stability.jl")
include(joinpath(@__DIR__, "..", "scripts", "lock_randomized_library_stability_amendment.jl"))
using .LockRandomizedLibraryStabilityAmendment
include("test_randomized_stability_amendment.jl")
include(joinpath(@__DIR__, "..", "scripts", "run_approximate_compression.jl"))
using .ApproximateCompressionExperiment
include("test_approximate_compression.jl")

include(joinpath(@__DIR__, "..", "scripts", "run_compression_experiments.jl"))
using .CompressionExperiments
include("test_compression.jl")

include(joinpath(@__DIR__, "..", "scripts", "solve_canonical_model.jl"))
using .CanonicalModelSolver
include("test_dynamic_programming.jl")
include(joinpath(@__DIR__, "..", "scripts", "generate_strategy_value_figure.jl"))
using .StrategyValueFigure
include("test_innovation_value.jl")

include(joinpath(@__DIR__, "..", "scripts", "run_coverage_geometry.jl"))
using .CoverageGeometryExperiments
include("test_coverage.jl")
include(joinpath(@__DIR__, "..", "scripts", "run_kernel_persistence_response.jl"))
using .KernelPersistenceResponseExperiment
include("test_kernel_persistence_response.jl")
include(joinpath(@__DIR__, "..", "scripts", "run_system_interaction_surface.jl"))
using .SystemInteractionExperiment
include("test_system_interaction.jl")
include(joinpath(@__DIR__, "..", "scripts", "search_primitive_substitution.jl"))
using .PrimitiveSubstitutionSearch
include("test_primitive_substitution.jl")
include(joinpath(@__DIR__, "..", "scripts", "search_joint_descendant_bound.jl"))
using .JointDescendantBoundGauntlet
include("test_joint_descendant_bound.jl")

include(joinpath(@__DIR__, "..", "scripts", "run_theorem_mechanism_experiments.jl"))
using .TheoremMechanismExperiments
include("test_theorem_mechanisms.jl")

include(joinpath(@__DIR__, "..", "scripts", "run_financial_terminal_audit.jl"))
using .FinancialTerminalAudit
include("test_financial_terminal_audit.jl")

include(joinpath(@__DIR__, "..", "scripts", "run_financial_annual_walkforward_audit.jl"))
using .FinancialAnnualWalkforwardAudit
include("test_financial_annual_walkforward_audit.jl")
include(joinpath(@__DIR__, "..", "scripts", "generate_manuscript_numerical_artifacts.jl"))
using .ManuscriptNumericalArtifacts
include("test_financial_compression_focus.jl")

include(joinpath(@__DIR__, "..", "scripts", "export_exact_fixtures.jl"))
using .ExactFixtureExporter
include("test_exact_fixture_bridge.jl")

include(joinpath(@__DIR__, "..", "scripts", "search_counterexamples.jl"))
using .CounterexampleSearch
include(joinpath(@__DIR__, "..", "scripts", "search_revision_counterexamples.jl"))
using .RevisionCounterexampleGauntlet
include("test_revision_counterexamples.jl")
include(joinpath(@__DIR__, "..", "scripts", "search_single_gap_geometry.jl"))
using .SingleGapGeometrySearch
include(joinpath(@__DIR__, "..", "scripts", "search_multi_gap_topology.jl"))
using .MultiGapTopologySearch

@testset "StrategyInnovation infrastructure" begin
    @test nameof(StrategyInnovation) == :StrategyInnovation
end

@testset "exact multi-gap topology audit" begin
    witness = exact_multi_gap_witness()
    @test witness.left_gap == [4 // 1, 0 // 1, 0 // 1, 0 // 1, 0 // 1]
    @test witness.right_gap == [0 // 1, 0 // 1, 0 // 1, 0 // 1, 4 // 1]
    @test witness.potential == [4 // 1, 41 // 32, 1 // 2, 41 // 32, 4 // 1]
    @test witness.region == [true, true, false, true, true]
    @test witness.components == 2
    @test witness.independent_check

    audit = run_topology_audit()
    @test audit["kernel_row_stochastic"]
    @test audit["total_nonnegative_minor_audit"].all_nonnegative
    @test audit["total_nonnegative_minor_audit"].checked == 251
    @test audit["variation_diminishing_grid_audit"].all_hold
    @test audit["variation_diminishing_grid_audit"].checked == 3125
    @test audit["superlevel_component_grid_audit"].all_hold
    @test audit["superlevel_component_grid_audit"].checked == 28125

    cost_boundary = topology_cost_counterexample()
    @test cost_boundary.gap_positive_components == 1
    @test cost_boundary.research_region_components == 3
    @test cost_boundary.region == [true, false, true, false, true]
    @test cost_boundary.independent_check
end

@testset "exact single-gap geometry search" begin
    kernel = deterministic_kernel_witness()
    @test kernel.gap == [0 // 1, 1 // 1, 0 // 1]
    @test kernel.destinations == [2, 1, 2]
    @test kernel.potential == [1 // 1, 0 // 1, 1 // 1]
    @test kernel.gap_single_peaked
    @test kernel.gap_quasiconcave
    @test kernel.gap_interval_support
    @test !kernel.potential_quasiconcave
    @test !kernel.kernel_stochastically_monotone
    @test kernel.region == [true, false, true]

    cost = cost_disconnection_witness()
    @test cost.potential == [1 // 1, 2 // 1, 3 // 1]
    @test cost.cost == [0 // 1, 3 // 1, 0 // 1]
    @test cost.potential_monotone
    @test !cost.cost_antitone
    @test cost.region == [true, false, true]

    positive_class = verify_monotone_threshold_class()
    @test positive_class.all_hold
    @test positive_class.checks == 60_000
end

@testset "deterministic RNG convention" begin
    seed = UInt64(42)
    @test rand(research_rng(seed), UInt64, 8) ==
          rand(research_rng(seed), UInt64, 8)
    @test rand(research_rng(), UInt64, 8) ==
          rand(research_rng(DEFAULT_RESEARCH_SEED), UInt64, 8)
end

@testset "Aqua" begin
    # Printf and TOML are direct project dependencies for the repository's shipped
    # experiment runners; the package module does not load script-only IO.
    Aqua.test_all(StrategyInnovation; stale_deps = (ignore = [:Printf, :TOML],))
end

@testset "exact theorem feasibility witnesses" begin
    silent = silent_module_witness()
    @test silent.same_frontier
    @test silent.different_closure
    @test silent.same_signature
    @test silent.same_values

    batch = t3_batch_witness()
    @test batch.first_safe
    @test batch.second_safe
    @test batch.batch_unsafe

    large_loss = t4_witness(5 // 1)
    @test large_loss.loss > large_loss.target
    @test large_loss.independent_check

    separability = t5_separability_witness()
    @test separability.low_premium == 1 // 2
    @test separability.high_premium == 1 // 1
    @test separability.independent_check

    disconnected = t6_disconnected_witness()
    @test disconnected.region == [true, false, true]
    @test disconnected.independent_check

    multi_gap = multi_gap_additivity_witness()
    @test multi_gap.violates_additive_upper_bound
    @test multi_gap.independent_check
end

@testset "deterministic exact theorem smoke search" begin
    first = run_feasibility_search(
        seed = DEFAULT_FEASIBILITY_SEED,
        random_trials = 8,
        single_gap_trials = 16,
        exhaustive = false,
    )
    second = run_feasibility_search(
        seed = DEFAULT_FEASIBILITY_SEED,
        random_trials = 8,
        single_gap_trials = 16,
        exhaustive = false,
    )
    @test first == second
    @test first["all_current_t1_t6_survived"]
    @test isempty(first["random_failures"])
    @test !first["main_novelty_collapsed"]
end
