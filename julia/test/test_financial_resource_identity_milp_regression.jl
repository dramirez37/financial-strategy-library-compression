using Test

const FINANCIAL_ER = Rational{BigInt}

function _enumerated_financial_optima(model, weights)
    best = nothing
    optima = Set{Set{String}}()
    strategy_count = length(model.source_ids)
    for mask in 0:(Int(1) << strategy_count) - 1
        ids = [
            model.source_ids[index] for index in 1:strategy_count if
            !iszero(mask & (Int(1) << (index - 1)))
        ]
        isempty(ids) && continue
        try
            FinancialResourceOptimization._certify_original(model, ids)
        catch
            continue
        end
        burden = FinancialResourceOptimization._burden(ids, weights)
        if isnothing(best) || burden < best
            best = burden
            empty!(optima)
            push!(optima, Set(ids))
        elseif burden == best
            push!(optima, Set(ids))
        end
    end
    return (; best, optima)
end

@testset "sparse financial identity MILP agrees with exhaustive enumeration" begin
    fixture = _financial_resource_fixture()
    model = FinancialResourceOptimization.build_exact_resource_model(
        fixture.strategies,
        fixture.profiles,
    )
    schedules = [
        Dict(id => FINANCIAL_ER(1, 1) for id in model.source_ids),
        Dict("A" => FINANCIAL_ER(1, 1), "B" => FINANCIAL_ER(3, 1), "C" => FINANCIAL_ER(2, 1)),
    ]
    for (index, weights) in enumerate(schedules)
        objective = index == 1 ? :cardinality : :weight
        solved = FinancialResourceOptimization._solve_identity_resource_milp(
            model,
            weights;
            objective,
        )
        objective_weights = objective == :cardinality ? schedules[1] : weights
        enumerated = _enumerated_financial_optima(model, objective_weights)
        @test solved.optimal_objective == enumerated.best
        @test Set(solved.selected_ids) in enumerated.optima
        @test solved.exact_certificate.every_returned_library_exactly_safe
    end
end
