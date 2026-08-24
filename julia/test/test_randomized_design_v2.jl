using TOML

@testset "randomized-library v2 pre-outcome design lock" begin
    config_path = joinpath(
        @__DIR__,
        "..",
        "..",
        "experiments",
        "configs",
        "randomized_library_stress_v2.toml",
    )
    config = TOML.parsefile(config_path)
    rows = LockRandomizedLibraryDesignV2.design_rows(config)

    @test length(rows) == 1024
    @test length(unique(row.principal_cell_id for row in rows)) == 128
    @test all(
        count(
            candidate ->
                candidate.principal_cell_id == row.principal_cell_id,
            rows,
        ) == 8 for row in rows
    )
    @test count(
        row -> row.theorem_regime == "primitive_eligible",
        rows,
    ) == 512
    @test count(row -> row.theorem_regime == "boundary", rows) == 512
    @test count(
        row ->
            row.boundary_mechanism == "frontier_dependent_generator",
        rows,
    ) == 256
    @test count(
        row -> row.boundary_mechanism == "positive_poor_exposure",
        rows,
    ) == 256

    for prefix in (256, 512, 768, 1024)
        selected = rows[1:prefix]
        @test count(
            row -> row.theorem_regime == "primitive_eligible",
            selected,
        ) == prefix ÷ 2
        @test all(
            count(
                row -> getproperty(row, factor) == level,
                selected,
            ) == prefix ÷ 2 for
            factor in LockRandomizedLibraryDesignV2.FACTORS for
            level in config["levels"][string(factor)]
        )
    end

    seeds = reduce(
        vcat,
        [
            getproperty.(rows, column) for
            column in
            (:trial_seed, :catalog_seed, :project_seed, :deletion_seed)
        ],
    )
    @test length(seeds) == 4096
    @test length(unique(seeds)) == 4096
    @test all(>=(0), seeds)
    @test rows[1].principal_cell_id == "C038"
    @test rows[1].trial_seed == 88896221981659946
    @test rows[end].principal_cell_id == "C097"
    @test rows[end].deletion_seed == 3160749497465906111

    validation =
        LockRandomizedLibraryDesignV2.validate_design(config)
    @test validation.trials == 1024
    @test validation.cells == 128
    @test validation.seeds == 4096
    @test validation.prefixes == (256, 512, 768, 1024)
    lock_hash =
        LockRandomizedLibraryDesignV2.verify_design_lock(config_path)
    @test length(lock_hash) == 64
end
