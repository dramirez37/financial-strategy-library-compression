using Test
using TOML

if !isdefined(Main, :FinancialResourceOptimization)
    include(joinpath(@__DIR__, "..", "scripts", "run_financial_resource_optimization.jl"))
end

const ResourceOptimization = Main.FinancialResourceOptimization

function _financial_resource_fixture()
    common = (
        "filter:always",
        "horizon:5",
        "sizing:unit",
        "exit:horizon",
        "risk:notional_cap_1",
    )
    strategies = [
        ResourceOptimization.TerminalAudit.StrategySpec(
            "A",
            "AAA",
            "momentum_20",
            "always",
            5,
            "unit",
            "horizon",
            "notional_cap_1",
            ("instrument:AAA", "signal:momentum_20", common...),
        ),
        ResourceOptimization.TerminalAudit.StrategySpec(
            "B",
            "BBB",
            "momentum_60",
            "trend_100",
            20,
            "half",
            "signal_flip",
            "vol_target_10",
            (
                "instrument:BBB",
                "signal:momentum_60",
                "filter:trend_100",
                "horizon:20",
                "sizing:half",
                "exit:signal_flip",
                "risk:vol_target_10",
            ),
        ),
        ResourceOptimization.TerminalAudit.StrategySpec(
            "C",
            "AAA",
            "momentum_20",
            "always",
            5,
            "unit",
            "horizon",
            "notional_cap_1",
            ("instrument:AAA", "signal:momentum_20", common...),
        ),
    ]
    profiles = Dict(
        "A" => [2.0, 0.0],
        "B" => [0.0, 2.0],
        "C" => [2.0, 0.0],
    )
    return (; strategies, profiles)
end

@testset "registered financial resource schedules are metadata-only exact integers" begin
    config = TOML.parsefile(ResourceOptimization.DEFAULT_CONFIG)
    fixture = _financial_resource_fixture()
    weights = ResourceOptimization.registered_strategy_weights(fixture.strategies, config)
    @test all(weight == 1 // 1 for weight in values(weights.schedules["uniform_cardinality"]))
    @test weights.schedules["validation_computation"]["A"] == 5 // 1
    @test weights.schedules["validation_computation"]["B"] == 38 // 1
    @test weights.schedules["documented_complexity"]["A"] == 1 // 1
    @test weights.schedules["documented_complexity"]["B"] == 7 // 1
    @test weights.nonshared_counts["B"] == 7
    @test weights.schedules["nonshared_modules"]["B"] == 8 // 1
end

@testset "financial exact frontier-incidence reduction fails closed" begin
    fixture = _financial_resource_fixture()
    model = ResourceOptimization.build_exact_resource_model(fixture.strategies, fixture.profiles)
    @test length(model.source_ids) == 3
    @test model.source_frontier == Rational{BigInt}[2 // 1, 2 // 1]
    @test length(model.frontier_attainers) == 2
    @test length(model.module_carriers) == length(model.source_modules)
    @test ResourceOptimization._certify_original(model, ["A", "B"]).frontier_preserved
    @test_throws ErrorException ResourceOptimization._certify_original(model, ["A"])
end

@testset "financial sparse identity-closure MILP is exactly postverified" begin
    fixture = _financial_resource_fixture()
    model = ResourceOptimization.build_exact_resource_model(fixture.strategies, fixture.profiles)
    weights = Dict(id => Rational{BigInt}(1, 1) for id in model.source_ids)
    solved = ResourceOptimization._solve_identity_resource_milp(model, weights; objective = :cardinality)
    @test solved.solver_certificate.solver_claimed_optimal
    @test solved.exact_certificate.every_returned_library_exactly_safe
    @test solved.exact_certificate.inactive_policy_selected
    @test solved.optimal_objective == 2 // 1
    @test Set(solved.selected_ids) == Set(["B", only(intersect(solved.selected_ids, ["A", "C"]))])
end

@testset "financial resource registration validates" begin
    config = TOML.parsefile(ResourceOptimization.DEFAULT_CONFIG)
    @test ResourceOptimization.DesignLock.validate_design(config)
end
