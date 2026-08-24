module SafeCompressionScaling

using Printf
using StrategyInnovation

export safe_compression_scaling_instance, run_safe_compression_scaling

function safe_compression_scaling_instance(
    active_strategy_count::Integer,
    belief_count::Integer,
)
    active_strategy_count >= belief_count >= 2 || throw(
        ArgumentError(
            "scaling instances require active_strategy_count >= belief_count >= 2",
        ),
    )
    beliefs = FiniteBeliefSpace([
        Symbol("belief_$index") for index in 1:belief_count
    ])
    modules = [GenerativeModule(:inert)]
    empty_modules = ModuleSet{Symbol}()
    strategies = [
        Strategy(
            :inactive,
            OperationalProfile(beliefs, zeros(Int, belief_count)),
            empty_modules,
        ),
    ]
    for strategy_index in 1:active_strategy_count
        values = zeros(Int, belief_count)
        positions = (
            mod1(strategy_index, belief_count),
            mod1(3 * strategy_index + 1, belief_count),
            mod1(7 * strategy_index + 3, belief_count),
        )
        for position in positions
            values[position] = 1
        end
        push!(
            strategies,
            Strategy(
                Symbol("strategy_$strategy_index"),
                OperationalProfile(beliefs, values),
                empty_modules,
            ),
        )
    end
    catalog = StrategyCatalog(
        beliefs,
        modules,
        strategies,
        StrategyId(:inactive),
    )
    closure = identity_generative_closure(modules)
    source = RawLibrary(catalog, [row.id for row in strategies])
    return (; catalog, closure, source)
end

function _scaling_row(active_strategy_count, belief_count)
    fixture = safe_compression_scaling_instance(
        active_strategy_count,
        belief_count,
    )
    result = nothing
    elapsed_seconds = @elapsed result = solve_safe_compression_milp(
        fixture.catalog,
        fixture.closure,
        fixture.source;
        objective = :cardinality,
        enumerate_all_optima = false,
        exact_enumeration_limit = 0,
        silent = true,
        threads = 1,
    )
    run = only(result.solver_certificate.runs)
    return (
        active_strategies = Int(active_strategy_count),
        beliefs = Int(belief_count),
        binary_variables = result.formulation.strategy_count +
                           result.formulation.generator_variable_count,
        linear_constraints = result.formulation.linear_constraint_count,
        selected_active_strategies = only(result.active_cardinalities),
        exact_objective = result.optimal_objective,
        solver_seconds = run.solve_time_seconds,
        end_to_end_seconds = elapsed_seconds,
        branch_and_bound_nodes = run.node_count,
        exact_safety_verified =
            result.exact_certificate.every_returned_library_exactly_safe,
        solver_claimed_optimal = result.solver_certificate.solver_claimed_optimal,
        exact_global_optimality_by_enumeration =
            result.exact_certificate.exact_optimality_verified,
    )
end

"""
    run_safe_compression_scaling(; sizes=((32, 16), (64, 32),
                                            (128, 64), (256, 128)),
                                   warmup=true, print_table=true)

Run a deterministic increasing-size MILP probe. The reported wall time covers
model construction, HiGHS, and exact post-solve certification; solver time is
reported separately. These are implementation diagnostics, not theorem or
global-optimality certificates. Exact enumeration is deliberately disabled.
"""
function run_safe_compression_scaling(;
    sizes = ((32, 16), (64, 32), (128, 64), (256, 128)),
    warmup::Bool = true,
    print_table::Bool = true,
)
    warmup && _scaling_row(8, 4)
    rows = [
        _scaling_row(active_strategy_count, belief_count) for
        (active_strategy_count, belief_count) in sizes
    ]
    if print_table
        println(
            "active\tbeliefs\tbinaries\tconstraints\tselected\t" *
            "solver_s\ttotal_s\tnodes\texact_safe",
        )
        for row in rows
            @printf(
                "%d\t%d\t%d\t%d\t%d\t%.6f\t%.6f\t%s\t%s\n",
                row.active_strategies,
                row.beliefs,
                row.binary_variables,
                row.linear_constraints,
                row.selected_active_strategies,
                row.solver_seconds,
                row.end_to_end_seconds,
                string(row.branch_and_bound_nodes),
                string(row.exact_safety_verified),
            )
        end
    end
    return rows
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_safe_compression_scaling()
end

end
