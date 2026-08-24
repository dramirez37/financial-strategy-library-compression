using TOML

@testset "randomized-library stability pre-outcome amendment" begin
    config_path = joinpath(
        @__DIR__,
        "..",
        "..",
        "experiments",
        "configs",
        "randomized_library_stability_amendment_1.toml",
    )
    config = TOML.parsefile(config_path)
    validation =
        LockRandomizedLibraryStabilityAmendment.validate_amendment(config)
    @test validation.maximum_n == 1024
    @test validation.requested_prefixes ==
          (50, 100, 200, 300, 500, 750, 1000)
    @test validation.reported_prefixes ==
          (50, 100, 200, 300, 500, 750, 1000, 1024)
    @test validation.factors == 7
    @test validation.estimands == 8

    lock_hash =
        LockRandomizedLibraryStabilityAmendment.verify_amendment_lock(
            config_path,
        )
    @test length(lock_hash) == 64

    changed = deepcopy(config)
    changed["sequential"]["final_estimate_n"] = 1000
    @test_throws ErrorException LockRandomizedLibraryStabilityAmendment.validate_amendment(
        changed,
    )
    changed = deepcopy(config)
    changed["parent"]["maximum_n_selected_after_outcomes"] = true
    @test_throws ErrorException LockRandomizedLibraryStabilityAmendment.validate_amendment(
        changed,
    )
end
