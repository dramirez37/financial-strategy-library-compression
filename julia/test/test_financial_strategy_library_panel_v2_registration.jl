include(joinpath(@__DIR__, "..", "scripts", "lock_financial_strategy_library_panel_v2.jl"))

const FSLP2Lock = LockFinancialStrategyLibraryPanelV2
const FSLP2Registries =
    LockFinancialStrategyLibraryPanelV2.FinancialStrategyLibraryPanelV2Registries

@testset "financial strategy-library panel v2 registration" begin
    counts = FSLP2Registries.check_registries()
    @test counts == (
        origin_count = 20,
        scenario_count = 30,
        docket_count = 2,
        capability_count = 27,
        burden_count = 3,
        arm_count = 6,
        seed_count = 40,
    )

    origins = FSLP2Registries.origin_rows()
    @test getfield.(origins, :decision_year) == collect(2005:2024)
    @test all(row.construction_end_year + 1 == row.compression_start_year for row in origins)
    @test all(row.compression_end_year + 1 == row.postdecision_year for row in origins)
    @test all(row.menus_per_docket == 32 for row in origins)

    scenarios = FSLP2Registries.scenario_rows()
    @test Set(getfield.(scenarios, :transaction_cost_bps)) == Set([0, 5, 15])
    @test Set(getfield.(scenarios, :risk_aversion)) == Set([1, 3])
    @test Set(getfield.(scenarios, :belief_state)) == Set(1:5)

    arms = FSLP2Registries.arm_rows()
    safe = only(filter(row -> row.arm_id == "innovation_safe_exact", arms))
    comparator = only(filter(row -> row.arm_id == "frontier_only_budget_matched", arms))
    @test safe.preserves_frontier && safe.preserves_closure
    @test comparator.preserves_frontier && !comparator.preserves_closure
    @test occursin("safe exact burden cap", comparator.selection_rule)

    validated = FSLP2Lock.validate_design()
    @test validated.registry_counts == counts
    aggregate = isfile(FSLP2Lock.LOCK_PATH) ?
                FSLP2Lock.verify_design_lock() :
                FSLP2Lock.dry_run().aggregate_sha256
    @test occursin(r"^[0-9a-f]{64}$", aggregate)

    hashes = FSLP2Lock._hashes()
    lock_text = isfile(FSLP2Lock.LOCK_PATH) ?
                read(FSLP2Lock.LOCK_PATH, String) :
                FSLP2Lock._render_lock(hashes, counts)
    one_hash = first(values(hashes))
    tampered = replace(lock_text, one_hash => repeat("0", 64); count = 1)
    @test_throws ErrorException FSLP2Lock.verify_lock_text(tampered, hashes)
end
