include(joinpath(@__DIR__, "..", "scripts", "lock_financial_strategy_library_panel_v1.jl"))
include(joinpath(@__DIR__, "..", "scripts", "lock_financial_strategy_library_panel_v1_execution_007.jl"))

const FSLP1Lock = LockFinancialStrategyLibraryPanelV1
const FSLP1SuccessorLock = LockFinancialStrategyLibraryPanelV1Execution007
const FSLP1Registries =
    LockFinancialStrategyLibraryPanelV1.FinancialStrategyLibraryPanelV1Registries

@testset "financial strategy-library panel v1 prospective registration" begin
    counts = FSLP1Registries.check_registries()
    @test counts == (
        origin_count = 20,
        library_count = 3,
        capability_count = 27,
        burden_count = 3,
        seed_count = 60,
    )

    origins = FSLP1Registries.origin_rows()
    @test getfield.(origins, :decision_year) == collect(2005:2024)
    @test all(row.construction_end_year + 1 == row.compression_start_year for row in origins)
    @test all(row.compression_end_year + 1 == row.postdecision_year for row in origins)
    @test all(row.origin_role == "final" for row in origins)

    capabilities = FSLP1Registries.capability_rows()
    @test count(row -> startswith(row.capability_class, "atomic_"), capabilities) == 13
    @test count(row -> startswith(row.capability_class, "interface_"), capabilities) == 14
    carried = FSLP1Registries.capability_ids_for_spec(
        signal = "mean_reversion_5",
        filter = "trend_100",
        horizon = 20,
        sizing = "half",
        exit_rule = "signal_flip",
        risk = "vol_target_10",
    )
    @test length(carried) == 9
    @test all(in(Set(getfield.(capabilities, :capability_id))), carried)

    @test FSLP1Registries.validation_work_units(
        signal_evaluations = 0,
        filter_evaluations = 0,
        risk_updates = 0,
        position_decisions = 0,
        exit_evaluations = 0,
    ) == 1
    @test FSLP1Registries.validation_work_units(
        signal_evaluations = 253,
        filter_evaluations = 252,
        risk_updates = 1,
        position_decisions = 53,
        exit_evaluations = 504,
    ) == 9
    @test_throws ArgumentError FSLP1Registries.validation_work_units(
        signal_evaluations = -1,
        filter_evaluations = 0,
        risk_updates = 0,
        position_decisions = 0,
        exit_evaluations = 0,
    )
    @test FSLP1Registries.governance_review_units(0) == 11
    @test FSLP1Registries.governance_review_units(6) == 17
    @test_throws ArgumentError FSLP1Registries.governance_review_units(7)

    validated = FSLP1Lock.validate_design()
    @test validated.registry_counts == counts
    historical_text = read(FSLP1Lock.LOCK_PATH, String)
    @test occursin(
        "\"aggregate_sha256\": \"$(FSLP1SuccessorLock.DESIGN_AGGREGATE)\"",
        historical_text,
    )
    aggregate = isfile(FSLP1SuccessorLock.LOCK_PATH) ?
                FSLP1SuccessorLock.verify_execution_lock_007() :
                FSLP1SuccessorLock.dry_run()
    @test occursin(r"^[0-9a-f]{64}$", aggregate)
    lock_text = isfile(FSLP1SuccessorLock.LOCK_PATH) ?
                read(FSLP1SuccessorLock.LOCK_PATH, String) :
                FSLP1SuccessorLock._render_lock(FSLP1SuccessorLock._hashes())
    one_hash = first(values(FSLP1SuccessorLock._hashes()))
    tampered = replace(lock_text, one_hash => repeat("0", 64); count = 1)
    @test_throws ErrorException FSLP1SuccessorLock.verify_lock_text(
        tampered,
        FSLP1SuccessorLock._hashes(),
    )
end
