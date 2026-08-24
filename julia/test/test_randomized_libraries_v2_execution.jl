using Test

include(
    joinpath(
        @__DIR__,
        "..",
        "scripts",
        "randomized_library_v2_core.jl",
    ),
)
using .RandomizedLibraryV2Core

function _synthetic_v2_row(
    trial_id;
    theorem_regime = :primitive_eligible,
    boundary_mechanism = :none,
    frontier_density = :sparse,
    module_overlap = :low,
    module_complementarity = :weak,
    project_cost = :low,
    duration = :short,
    admission = :high,
    persistence = :low,
)
    return RegisteredTrialV2(
        trial_id,
        1,
        1,
        "SYNTHETIC",
        1,
        1,
        theorem_regime,
        boundary_mechanism,
        frontier_density,
        module_overlap,
        module_complementarity,
        project_cost,
        duration,
        admission,
        persistence,
        UInt64(trial_id),
        trial_id + 10,
        trial_id + 20,
        trial_id + 30,
        trial_id + 40,
    )
end

@testset "registered v2 executable raw-library protocol" begin
    fixtures = [
        _synthetic_v2_row(900001),
        _synthetic_v2_row(
            900002;
            frontier_density = :dense,
            module_overlap = :high,
            module_complementarity = :strong,
            project_cost = :high,
            duration = :long,
            admission = :low,
            persistence = :high,
        ),
        _synthetic_v2_row(
            900003;
            theorem_regime = :boundary,
            boundary_mechanism = :frontier_dependent_generator,
            module_complementarity = :strong,
            duration = :long,
        ),
        _synthetic_v2_row(
            900004;
            theorem_regime = :boundary,
            boundary_mechanism = :positive_poor_exposure,
            frontier_density = :dense,
            module_overlap = :high,
        ),
    ]
    results = run_registered_v2_trial.(fixtures)
    @test length(results) == 4
    @test all(result.trial_row.all_hard_gates_pass for result in results)
    @test all(
        result.trial_row.raw_compressed_values_agree for
        result in results
    )
    @test all(length(result.corner_rows) == 4 for result in results)
    @test all(
        result.trial_row.all_compressed_states_have_raw_witnesses for
        result in results
    )
    @test all(
        row.raw_library_valid for result in results for
        row in result.corner_rows
    )
    @test all(
        row.witness_valid for result in results for
        row in result.witness_rows
    )
    @test all(
        row.decomposition_gate for result in results for
        row in result.pruning_rows
    )
    @test all(
        row.decomposition_gate for result in results for
        row in result.asset_rows
    )
    @test all(
        row -> row isa Rational{BigInt},
        (
            result.trial_row.source_total_value for result in results
        ),
    )

    eligible = results[1:2]
    @test all(
        result.trial_row.computed_primitive_predicate for
        result in eligible
    )
    @test all(
        result.trial_row.frontier_closure_J <= 0 for
        result in eligible
    )
    frontier_boundary = results[3].trial_row
    @test !frontier_boundary.computed_primitive_predicate
    @test !frontier_boundary.frontier_independent_generation
    poor_boundary = results[4].trial_row
    @test !poor_boundary.computed_primitive_predicate
    @test !poor_boundary.zero_poor_exposure

    for result in results
        safe = only(
            row for row in result.pruning_rows if
            row.method == "innovation_safe"
        )
        @test safe.frontier_loss == 0
        @test safe.closure_loss_count == 0
        @test safe.signed_operational_loss == 0
        @test safe.signed_generative_loss == 0
        @test safe.signed_total_dynamic_loss == 0
    end
end
