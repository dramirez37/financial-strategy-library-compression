using Test

include(joinpath(
    @__DIR__,
    "..",
    "src",
    "FinancialStrategyLibraryPanelV3PredecisionComputation.jl",
))
using .FinancialStrategyLibraryPanelV3PredecisionComputation

const V3C = FinancialStrategyLibraryPanelV3PredecisionComputation

function _synthetic_paths()
    return StrategyPath[
        StrategyPath(
            specification,
            candidate_id("TEST-O2005", "liquid_common_equity", specification),
            Union{Missing,Float64}[0.0, 0.0],
            [0.0, 0.0],
            trues(2),
        ) for specification in V3C.portfolio_catalog()
    ]
end

function _synthetic_profile_bundle(paths; reverse = false)
    years = Int[]
    ids = String[]
    costs = Int[]
    risks = Int[]
    for year in 2000:2002, cost in (5, 30), risk in (1, 3)
        push!(years, year)
        push!(ids, profile_identifier(year, cost, risk))
        push!(costs, cost)
        push!(risks, risk)
    end
    values = Matrix{V3C.ExactRational}(undef, length(paths), length(ids))
    floating = zeros(Float64, size(values))
    for row in axes(values, 1), column in axes(values, 2)
        rank = reverse ? length(paths) - row + 1 : row
        values[row, column] = (10_000 * rank + column * ((row % 7) + 1)) // 1_000_000
        floating[row, column] = Float64(values[row, column])
    end
    return ProfileBundle(years, ids, costs, risks, values, floating)
end

@testset "v3 exact profile construction" begin
    gross = Union{Missing,Float64}[0.01, -0.01, 0.02]
    turnover = [1.0, 0.0, 0.5]
    available = trues(3)
    value = certainty_equivalent(
        gross,
        turnover,
        available;
        cost_bps = 5,
        risk_aversion = 3,
        annualization_sessions = 3,
    )
    @test isfinite(value)
    @test denominator(exact_profile_value(value)) <= V3C.PROFILE_SCALE
    @test_throws ArgumentError certainty_equivalent(
        gross,
        turnover,
        BitVector([true, false, true]);
        cost_bps = 5,
        risk_aversion = 3,
    )
end

@testset "v3 all-grammar path engine" begin
    sessions = 130
    securities = 4
    returns = [
        0.0004 + 0.0002 * sin(0.17 * session + security) for
        session in 1:sessions, security in 1:securities
    ]
    paths = build_strategy_paths(
        "TEST-O2005",
        "liquid_common_equity",
        returns,
        trues(size(returns)),
        falses(size(returns));
        security_weight_cap = 0.25,
    )
    @test length(paths) == 96
    @test all(path -> length(path.gross_returns) == sessions, paths)
    @test issorted(getfield.(paths, :strategy_id))
end

@testset "v3 formation-only docket and exact nested arms" begin
    paths = _synthetic_paths()
    formation = _synthetic_profile_bundle(paths)
    docket = freeze_source_docket(paths, formation, "liquid_common_equity")
    @test count(docket.selected) < 96
    @test count(docket.selected) >= 3
    @test length(docket.complete_capability_ids) == 31
    @test all(length(carriers) == 3 for carriers in values(docket.capability_carrier_indices))

    compression = _synthetic_profile_bundle(paths; reverse = true)
    arms = compression_arms(
        "TEST-O2005",
        "liquid_common_equity",
        paths,
        docket,
        compression,
    )
    @test arms.safe_result.candidate_accepted
    @test arms.safe_result.solver_claimed_optimal ||
          !arms.safe_result.diagnostics.solver_invoked
    @test arms.frontier_result.candidate_accepted
    @test arms.frontier_result.solver_claimed_optimal ||
          !arms.frontier_result.diagnostics.solver_invoked
    @test Set(arms.comparator_action_set) ⊆ Set(arms.safe_action_set)
    @test Set(arms.safe_action_set) ⊆ Set(arms.source_action_set)
    @test arms.safe_action_set == arms.innovation_strategy_ids

    rows = preproposal_trial_rows(
        "TEST-O2005",
        "liquid_common_equity",
        paths,
        docket,
        arms,
    )
    @test length(rows) == 485
    @test count(row -> row["strategy_id"] == V3C.CASH_ID, rows) == 5
    @test count(row -> row["generatable"], rows) > 0
    @test startswith(render_trial_ledger_csv(rows), "trial_id,origin_id,universe_id")

    failed = preproposal_trial_rows(
        "TEST-O2005",
        "liquid_common_equity",
        paths,
        docket,
        arms;
        universe_status = "FAILED",
    )
    @test all(!row["generatable"] for row in failed)
    @test all(row["failure_code"] == "UNIVERSE_GATE_FAILED" for row in failed)
end
