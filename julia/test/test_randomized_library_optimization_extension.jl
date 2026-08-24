using TOML

const RLOE = Main.RandomizedLibraryOptimizationExtension
const RLOELock = Main.LockRandomizedLibraryOptimizationExtension
const RLOE_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const RLOE_CONFIG = joinpath(
    RLOE_ROOT,
    "experiments",
    "configs",
    "randomized_library_optimization_extension_v1.toml",
)

@testset "registered randomized-library optimization extension" begin
    config = TOML.parsefile(RLOE_CONFIG)
    @test RLOELock.validate_design(config)
    @test RLOELock.verify_design_lock(RLOE_CONFIG) isa String
    @test config["sample_size"] == 1024
    @test config["parent_outcomes_are_inputs"] === false
    @test config["pooled_with_parent_results"] === false
    @test config["weights"]["forbidden_information"] ==
          "profiles, frontier attainment, closure contribution, dynamic values, actions, trial outcomes, pruning outcomes, and deletion order"

    results = RLOE.run_extension(RLOE_CONFIG; trial_limit = 4)
    @test length(results) == 4
    for result in results
        trial = result.trial_row
        @test trial.enumerated_sublibraries == 32
        @test occursin("inactive:0//1", trial.source_strategy_weights)
        @test length(result.sublibrary_rows) == 32
        @test all(row -> row.channel_decomposition_gate, result.sublibrary_rows)
        @test all(row -> row.capacity_feasible_gate, result.capacity_rows)
        @test trial.global_enumeration_gate
        @test trial.all_safe_optima_preserve_frontier_closure
        @test trial.all_safe_productive_values_preserved
        @test trial.all_channel_decompositions_close
        @test trial.all_capacity_optima_feasible
        @test trial.capacity_value_monotone
        @test trial.safe_pruning_weakly_lowers_burden
        @test trial.penalty_burden_monotone
        @test trial.rechecked_pruning_burden <= trial.source_burden
        @test trial.minimum_safe_weight <= trial.rechecked_pruning_burden
        @test trial.greedy_optimality_gap >= 0
        @test trial.safe_weight_compression_ratio >= 0
        @test trial.safe_cardinality_compression_ratio >= 0

        safe_rows = filter(
            row -> row.method in (
                "minimum_weight_safe",
                "minimum_cardinality_safe",
                "rechecked_safe_pruning_endpoint",
            ),
            result.compression_rows,
        )
        @test length(safe_rows) == 3
        @test all(row -> row.frontier_preserved, safe_rows)
        @test all(row -> row.closure_preserved, safe_rows)
        @test all(row -> row.exact_productive_value_preserved, safe_rows)
        @test all(row -> row.enumeration_certificate == "complete-enumeration:32", safe_rows)

        capacity = filter(row -> row.grid == "registered", result.capacity_rows)
        @test length(capacity) == 5
        @test issorted(row.optimal_total_value for row in capacity)
        @test all(row -> row.optimizer_count >= 1, capacity)

        @test !isempty(result.breakpoint_rows)
        @test all(row -> row.optimizer_count >= 2, result.breakpoint_rows)
        @test all(row -> row.enumeration_certificate == "complete-enumeration:32", result.breakpoint_rows)
        @test all(row -> row.channel_decomposition_gate, result.elasticity_rows)
    end

    parent_config = TOML.parsefile(joinpath(
        RLOE_ROOT,
        config["parent_config"],
    ))
    @test isempty(intersect(
        Set(String.(collect(values(parent_config["outputs"])))),
        Set(String.(collect(values(config["outputs"])))),
    ))

    if all(isfile(joinpath(RLOE_ROOT, path)) for path in values(config["outputs"]))
        summary = read(joinpath(RLOE_ROOT, config["outputs"]["summary"]), String)
        @test occursin("\"trial_count\": 1024", summary)
        @test occursin("\"sublibraries_per_trial\": 32", summary)
        @test occursin("\"all_hard_gates_pass\": true", summary)
        @test occursin("\"pooled_with_parent_results\": false", summary)
        capacity_header = first(readlines(joinpath(
            RLOE_ROOT,
            config["outputs"]["capacity"],
        )))
        @test occursin("forward_shadow_value", capacity_header)
    end
end
