"""
    ApproximateCompressionProblem

Exact finite-horizon approximate-compression problem on a public
[`RawInnovationProcess`](@ref). For a source library `L`, reference belief
`b`, and candidate sublibrary `L′`, the implemented losses are

`OpLoss(L′) = max_b (F_L(b) - F_L′(b))`,

`ValueLoss(L′) = V_H(b,L) - V_H(b,L′)`, and

`GenLoss(L′) = ValueLoss(L′) - (W_H(b,L) - W_H(b,L′))`,

where `W_H` is the frozen-library passive operating value and `V_H` is the
unified raw-model value. Generative loss is signed, exactly as in the
definition; no positive-part transformation is applied.

This is a numerical optimization object. It is not a theorem and supplies no
approximation guarantee for a heuristic.
"""
struct ApproximateCompressionProblem{S,B,T,P,F}
    process::P
    source::RawLibrary{S}
    horizon::Int
    reference_belief::Belief{B}
    epsilon_operational::T
    epsilon_generative::T
    source_frontier::F
    source_value::T
    source_operating_value::T
    value_cache::Dict{RawLibrary{S},Tuple{T,T}}
    raw_value_memo::Dict{Tuple,T}
end

"""
One exact source-relative loss evaluation. `operating_value_loss` is the
bracketed `W` term in the definition of generative loss.
"""
struct ApproximateCompressionRecord{S,T}
    library::RawLibrary{S}
    retained_size::Int
    operational_loss::T
    operating_value_loss::T
    generative_loss::T
    value_loss::T
    feasible::Bool
    decomposition_gate::Bool
end

"""
Result returned by an exact or heuristic approximate-compression solver.
`optimal` is true only for complete subset enumeration.
"""
struct ApproximateCompressionSolution{S,T}
    method::Symbol
    record::ApproximateCompressionRecord{S,T}
    evaluated_count::Int
    exact::Bool
    optimal::Bool
end

"""
Solver-independent operational-cover 0--1 formulation with optional lazy
no-good cuts for already evaluated generative-loss violations.

Binary variables correspond to `strategy_ids`. The operational constraints
are exact:

`min sum(x)`, `x[inactive_index] = 1`, and
`sum(x[s] for s with j_s(b) >= F_L(b)-epsilon_operational) >= 1`
for every belief. The unified `GenLoss` constraint is a black-box Bellman
oracle in general, so each evaluated violating selection contributes one
exact no-good cut. `complete_generative_oracle` is true only when the supplied
records cover every source sublibrary. No external optimizer dependency or
unproved linearization of the dynamic value is introduced.
"""
struct ApproximateCompressionIPFormulation{S,B,T}
    strategy_ids::Tuple{Vararg{StrategyId{S}}}
    beliefs::Tuple{Vararg{Belief{B}}}
    frontier_cover::BitMatrix
    frontier_floor::Tuple{Vararg{T}}
    inactive_index::Int
    objective::Tuple{Vararg{Int}}
    epsilon_operational::T
    epsilon_generative::T
    generative_no_good_cuts::Vector{BitVector}
    evaluated_count::Int
    complete_generative_oracle::Bool
end

function _raw_passive_finite_horizon_value(
    process::RawInnovationProcess,
    horizon::Int,
    belief,
    library,
    memo,
)
    horizon == 0 && return exact_rational(0)
    key = (horizon, belief, library)
    haskey(memo, key) && return memo[key]
    state = compressed_library_state(process.catalog, process.closure, library)
    value = state.frontier[belief] + process.discount * sum(
        transition_probability(process.belief_kernel, belief, next) *
        _raw_passive_finite_horizon_value(
            process,
            horizon - 1,
            next,
            library,
            memo,
        ) for next in process.belief_kernel.space;
        init = exact_rational(0),
    )
    memo[key] = value
    return value
end

"""
    raw_passive_finite_horizon_value(process, horizon, belief, library)

Return the exact frozen-library operating value `W_H(b,L)` under the unified
belief kernel and timing. Research is disabled and the raw library remains
fixed.
"""
function raw_passive_finite_horizon_value(
    process::RawInnovationProcess,
    horizon::Integer,
    belief,
    library,
)
    horizon >= 0 || throw(ArgumentError("horizon must be nonnegative"))
    validate_library(process.catalog, library)
    belief in process.belief_kernel.space ||
        throw(ArgumentError("reference belief is outside the process"))
    return _raw_passive_finite_horizon_value(
        process,
        Int(horizon),
        belief,
        library,
        Dict{Tuple,ExactRational}(),
    )
end

function ApproximateCompressionProblem(
    process::RawInnovationProcess{S,B},
    source::RawLibrary{S};
    horizon::Integer,
    reference_belief = first(process.belief_kernel.space),
    epsilon_operational = 0,
    epsilon_generative = 0,
) where {S,B}
    horizon >= 1 || throw(ArgumentError("horizon must be positive"))
    validate_library(process.catalog, source)
    reference_belief in process.belief_kernel.space ||
        throw(ArgumentError("reference belief is outside the process"))
    epsilon_op = exact_rational(epsilon_operational)
    epsilon_gen = exact_rational(epsilon_generative)
    epsilon_op >= 0 ||
        throw(ArgumentError("epsilon_operational must be nonnegative"))
    epsilon_gen >= 0 ||
        throw(ArgumentError("epsilon_generative must be nonnegative"))
    raw_memo = Dict{Tuple,ExactRational}()
    passive_memo = Dict{Tuple,ExactRational}()
    source_value = _raw_finite_value(
        process,
        Int(horizon),
        reference_belief,
        source,
        raw_memo,
    )
    source_operating = _raw_passive_finite_horizon_value(
        process,
        Int(horizon),
        reference_belief,
        source,
        passive_memo,
    )
    cache = Dict{RawLibrary{S},Tuple{ExactRational,ExactRational}}(
        source => (source_operating, source_value),
    )
    return ApproximateCompressionProblem{
        S,
        B,
        ExactRational,
        typeof(process),
        typeof(frontier(process.catalog, source)),
    }(
        process,
        source,
        Int(horizon),
        reference_belief,
        epsilon_op,
        epsilon_gen,
        frontier(process.catalog, source),
        source_value,
        source_operating,
        cache,
        raw_memo,
    )
end

function _approximate_compression_values(
    problem::ApproximateCompressionProblem{S},
    library::RawLibrary{S},
) where {S}
    haskey(problem.value_cache, library) &&
        return problem.value_cache[library]
    passive = _raw_passive_finite_horizon_value(
        problem.process,
        problem.horizon,
        problem.reference_belief,
        library,
        Dict{Tuple,ExactRational}(),
    )
    value = _raw_finite_value(
        problem.process,
        problem.horizon,
        problem.reference_belief,
        library,
        problem.raw_value_memo,
    )
    problem.value_cache[library] = (passive, value)
    return (passive, value)
end

function _validate_sublibrary(
    problem::ApproximateCompressionProblem,
    library::RawLibrary,
)
    validate_library(problem.process.catalog, library)
    issubset(library, problem.source) ||
        throw(ArgumentError("candidate compression must be a source sublibrary"))
    return library
end

"""
    approximate_compression_losses(problem, library)

Evaluate `OpLoss`, the frozen operating-value loss, signed `GenLoss`, and
`ValueLoss` exactly. Feasibility means both requested loss budgets hold.
"""
function approximate_compression_losses(
    problem::ApproximateCompressionProblem{S},
    library::RawLibrary{S},
) where {S}
    _validate_sublibrary(problem, library)
    candidate_frontier = frontier(problem.process.catalog, library)
    operational_loss = maximum(
        problem.source_frontier[belief] - candidate_frontier[belief] for
        belief in problem.process.belief_kernel.space
    )
    operating_value, value =
        _approximate_compression_values(problem, library)
    operating_value_loss =
        problem.source_operating_value - operating_value
    value_loss = problem.source_value - value
    generative_loss = value_loss - operating_value_loss
    decomposition_gate =
        value_loss == operating_value_loss + generative_loss
    feasible =
        operational_loss <= problem.epsilon_operational &&
        generative_loss <= problem.epsilon_generative
    return ApproximateCompressionRecord(
        library,
        length(library),
        operational_loss,
        operating_value_loss,
        generative_loss,
        value_loss,
        feasible,
        decomposition_gate,
    )
end

function _compression_source_ids(
    problem::ApproximateCompressionProblem{S},
) where {S}
    return StrategyId{S}[
        row.id for row in problem.process.catalog.strategies if
        row.id in problem.source
    ]
end

function _compression_optional_ids(
    problem::ApproximateCompressionProblem{S},
) where {S}
    return StrategyId{S}[
        strategy_id for strategy_id in _compression_source_ids(problem) if
        strategy_id != problem.process.catalog.inactive_strategy
    ]
end

function _library_signature(
    problem::ApproximateCompressionProblem,
    library::RawLibrary,
)
    return join(
        (
            string(strategy_id.id) for
            strategy_id in _compression_source_ids(problem) if
            strategy_id in library
        ),
        ";",
    )
end

function _record_order(problem, record)
    return (
        record.retained_size,
        record.value_loss,
        record.operational_loss,
        record.generative_loss,
        _library_signature(problem, record.library),
    )
end

function _dominates(left::ApproximateCompressionRecord, right::ApproximateCompressionRecord)
    weak =
        left.retained_size <= right.retained_size &&
        left.operational_loss <= right.operational_loss &&
        left.generative_loss <= right.generative_loss
    strict =
        left.retained_size < right.retained_size ||
        left.operational_loss < right.operational_loss ||
        left.generative_loss < right.generative_loss
    return weak && strict
end

"""
    pareto_compression_records(records)

Return the exact nondominated rows in the three criteria
`(retained_size, OpLoss, GenLoss)`. Equal objective triples remain distinct
raw libraries and are returned in deterministic signature order.
"""
function pareto_compression_records(records::AbstractVector{<:ApproximateCompressionRecord})
    frontier_rows = ApproximateCompressionRecord[
        row for row in records if
        !any(other -> _dominates(other, row), records)
    ]
    sort!(
        frontier_rows;
        by = row -> (
            row.retained_size,
            row.operational_loss,
            row.generative_loss,
            join(
                sort(collect(string(strategy_id.id) for strategy_id in row.library)),
                ";",
            ),
        ),
    )
    return frontier_rows
end

function _best_feasible_record(problem, records)
    feasible = filter(row -> row.feasible, records)
    isempty(feasible) &&
        error("the source library must be feasible under nonnegative budgets")
    sort!(feasible; by = row -> _record_order(problem, row))
    return first(feasible)
end

"""
    enumerate_approximate_compressions(problem; max_optional=20)

Evaluate every source sublibrary containing the inactive strategy. Return the
minimum-cardinality feasible solution, all exact records, and the exact
three-criterion Pareto frontier. Optimality is asserted only after complete
enumeration.
"""
function enumerate_approximate_compressions(
    problem::ApproximateCompressionProblem{S};
    max_optional::Integer = 20,
) where {S}
    max_optional >= 0 || throw(ArgumentError("max_optional must be nonnegative"))
    optional = _compression_optional_ids(problem)
    length(optional) <= max_optional || throw(
        ArgumentError(
            "exact enumeration has $(length(optional)) optional strategies, " *
            "exceeding max_optional=$max_optional",
        ),
    )
    length(optional) <= 62 || throw(
        ArgumentError("the exact bit-mask enumerator supports at most 62 strategies"),
    )
    records = ApproximateCompressionRecord[]
    upper = UInt64(1) << length(optional)
    for mask in UInt64(0):(upper - UInt64(1))
        retained = StrategyId{S}[problem.process.catalog.inactive_strategy]
        for (index, strategy_id) in enumerate(optional)
            iszero(mask & (UInt64(1) << (index - 1))) ||
                push!(retained, strategy_id)
        end
        library = RawLibrary(problem.process.catalog, retained)
        push!(records, approximate_compression_losses(problem, library))
    end
    sort!(records; by = row -> _record_order(problem, row))
    solution = ApproximateCompressionSolution(
        :exact_enumeration,
        _best_feasible_record(problem, records),
        length(records),
        true,
        true,
    )
    return (
        solution,
        records,
        pareto_records = pareto_compression_records(records),
    )
end

function _budget_ratio(loss, budget)
    loss <= 0 && return exact_rational(0)
    iszero(budget) && return typemax(Int)
    return loss / budget
end

function _greedy_key(problem, record, strategy_id, criterion)
    signature = string(strategy_id.id)
    criterion == :balanced && return (
        max(
            _budget_ratio(record.operational_loss, problem.epsilon_operational),
            _budget_ratio(record.generative_loss, problem.epsilon_generative),
        ),
        record.value_loss,
        record.operational_loss,
        record.generative_loss,
        signature,
    )
    criterion == :operational && return (
        record.operational_loss,
        record.generative_loss,
        record.value_loss,
        signature,
    )
    criterion == :generative && return (
        record.generative_loss,
        record.operational_loss,
        record.value_loss,
        signature,
    )
    criterion == :value && return (
        record.value_loss,
        record.operational_loss,
        record.generative_loss,
        signature,
    )
    throw(ArgumentError(
        "criterion must be balanced, operational, generative, or value",
    ))
end

"""
    greedy_approximate_compression(problem; criterion=:balanced)

Backward deletion heuristic. At every step, evaluate all feasible one-strategy
deletions relative to the original source and choose the exact lexicographic
score selected by `criterion`. The returned library is one-deletion maximal,
not guaranteed minimum cardinality.
"""
function greedy_approximate_compression(
    problem::ApproximateCompressionProblem;
    criterion::Symbol = :balanced,
)
    current = problem.source
    evaluated = Dict{typeof(problem.source),ApproximateCompressionRecord}()
    evaluated[current] = approximate_compression_losses(problem, current)
    while true
        candidates = Tuple[]
        for strategy_id in _compression_optional_ids(problem)
            strategy_id in current || continue
            candidate = delete_strategy(
                problem.process.catalog,
                current,
                strategy_id,
            )
            record = approximate_compression_losses(problem, candidate)
            evaluated[candidate] = record
            record.feasible || continue
            push!(
                candidates,
                (
                    _greedy_key(problem, record, strategy_id, criterion),
                    candidate,
                ),
            )
        end
        isempty(candidates) && break
        sort!(candidates; by = first)
        current = first(candidates)[2]
    end
    record = evaluated[current]
    return ApproximateCompressionSolution(
        Symbol("greedy_", criterion),
        record,
        length(evaluated),
        false,
        false,
    )
end

"""
    multistart_greedy_approximate_compression(problem)

Run all four deterministic greedy criteria and return their best feasible
solution together with the individual starts.
"""
function multistart_greedy_approximate_compression(
    problem::ApproximateCompressionProblem,
)
    starts = ApproximateCompressionSolution[
        greedy_approximate_compression(problem; criterion) for criterion in
        (:balanced, :operational, :generative, :value)
    ]
    sort!(
        starts;
        by = solution -> _record_order(problem, solution.record),
    )
    best = first(starts)
    total_evaluated = sum(solution.evaluated_count for solution in starts)
    solution = ApproximateCompressionSolution(
        :greedy_multistart,
        best.record,
        total_evaluated,
        false,
        false,
    )
    return (; solution, starts)
end

function _beam_key(problem, record)
    operational_violation =
        max(exact_rational(0), record.operational_loss - problem.epsilon_operational)
    generative_violation =
        max(exact_rational(0), record.generative_loss - problem.epsilon_generative)
    return (
        operational_violation + generative_violation,
        max(operational_violation, generative_violation),
        record.retained_size,
        record.value_loss,
        record.operational_loss,
        record.generative_loss,
        _library_signature(problem, record.library),
    )
end

"""
    pareto_beam_compression(problem; beam_width=64)

Levelwise deletion search for larger libraries. It retains the nondominated
`(OpLoss, GenLoss)` rows at each cardinality and fills any remaining beam
capacity by budget-violation rank. The returned Pareto frontier is exact only
when every source sublibrary was visited; otherwise it is explicitly a
candidate-pool frontier.
"""
function pareto_beam_compression(
    problem::ApproximateCompressionProblem;
    beam_width::Integer = 64,
)
    beam_width >= 1 || throw(ArgumentError("beam_width must be positive"))
    source_record = approximate_compression_losses(problem, problem.source)
    visited = Dict(problem.source => source_record)
    current = ApproximateCompressionRecord[source_record]
    while any(record -> record.retained_size > 1, current)
        next_records = Dict{typeof(problem.source),ApproximateCompressionRecord}()
        for record in current
            for strategy_id in _compression_optional_ids(problem)
                strategy_id in record.library || continue
                candidate = delete_strategy(
                    problem.process.catalog,
                    record.library,
                    strategy_id,
                )
                candidate_record = get!(visited, candidate) do
                    approximate_compression_losses(problem, candidate)
                end
                next_records[candidate] = candidate_record
            end
        end
        isempty(next_records) && break
        rows = collect(values(next_records))
        nondominated = pareto_compression_records(rows)
        selected = copy(nondominated)
        if length(selected) < beam_width
            remaining = [
                row for row in rows if
                !any(selected_row -> selected_row.library == row.library, selected)
            ]
            sort!(remaining; by = row -> _beam_key(problem, row))
            append!(
                selected,
                first(remaining, min(beam_width - length(selected), length(remaining))),
            )
        end
        sort!(selected; by = row -> _beam_key(problem, row))
        current = first(selected, min(beam_width, length(selected)))
    end
    records = collect(values(visited))
    sort!(records; by = row -> _record_order(problem, row))
    complete_count = big(1) << length(_compression_optional_ids(problem))
    complete = big(length(records)) == complete_count
    solution = ApproximateCompressionSolution(
        :pareto_beam,
        _best_feasible_record(problem, records),
        length(records),
        complete,
        complete,
    )
    return (
        solution,
        records,
        pareto_records = pareto_compression_records(records),
        complete,
    )
end

function _selection_vector(problem, library)
    return BitVector(
        strategy_id in library for strategy_id in
        _compression_source_ids(problem)
    )
end

"""
    approximate_compression_ip_formulation(problem; records=[])

Build the exact operational-cover MILP rows and no-good cuts for all supplied
records whose signed generative loss exceeds `epsilon_generative`. If
`records` is a complete enumeration, the resulting finite 0--1 formulation
represents the full bi-criterion problem exactly. Otherwise it is an outer
approximation requiring lazy Bellman-oracle cuts.
"""
function approximate_compression_ip_formulation(
    problem::ApproximateCompressionProblem{S,B,T};
    records::AbstractVector{<:ApproximateCompressionRecord} =
        ApproximateCompressionRecord[],
) where {S,B,T}
    strategy_ids = Tuple(_compression_source_ids(problem))
    beliefs = Tuple(problem.process.belief_kernel.space.states)
    frontier_floor = Tuple(
        problem.source_frontier[belief] - problem.epsilon_operational for
        belief in beliefs
    )
    frontier_cover = falses(length(beliefs), length(strategy_ids))
    for (belief_row, belief) in enumerate(beliefs)
        for (column, strategy_id) in enumerate(strategy_ids)
            frontier_cover[belief_row, column] =
                operational_profile(problem.process.catalog, strategy_id)[belief] >=
                frontier_floor[belief_row]
        end
    end
    inactive_index = findfirst(
        ==(problem.process.catalog.inactive_strategy),
        strategy_ids,
    )
    isnothing(inactive_index) &&
        error("validated source library lost its inactive strategy")
    unique_records = Dict(record.library => record for record in records)
    cuts = BitVector[
        _selection_vector(problem, record.library) for
        record in values(unique_records) if
        record.generative_loss > problem.epsilon_generative
    ]
    sort!(cuts; by = cut -> join(Int.(cut)))
    expected = big(1) << length(_compression_optional_ids(problem))
    complete = big(length(unique_records)) == expected
    return ApproximateCompressionIPFormulation{S,B,T}(
        strategy_ids,
        beliefs,
        frontier_cover,
        frontier_floor,
        inactive_index,
        Tuple(ones(Int, length(strategy_ids))),
        problem.epsilon_operational,
        problem.epsilon_generative,
        cuts,
        length(unique_records),
        complete,
    )
end

"""
    satisfies_approximate_compression_ip_formulation(formulation, selected)

Check the operational-cover constraints and all currently registered no-good
cuts. Unless `complete_generative_oracle` is true, success certifies only the
current outer approximation, not the full generative-loss constraint.
"""
function satisfies_approximate_compression_ip_formulation(
    formulation::ApproximateCompressionIPFormulation,
    selected::AbstractVector{Bool},
)
    length(selected) == length(formulation.strategy_ids) ||
        throw(DimensionMismatch("binary selection has the wrong length"))
    selected[formulation.inactive_index] || return false
    for belief_row in axes(formulation.frontier_cover, 1)
        any(
            selected[column] && formulation.frontier_cover[belief_row, column]
            for column in axes(formulation.frontier_cover, 2)
        ) || return false
    end
    for cut in formulation.generative_no_good_cuts
        selected == cut && return false
    end
    return true
end

"""
    operational_ip_cardinality_lower_bound(formulation)

Solve the operational-cover relaxation exactly by dynamic programming over
belief-coverage masks. The result includes the inactive strategy and is a
certified cardinality lower bound for the full bi-criterion numerical problem.
"""
function operational_ip_cardinality_lower_bound(
    formulation::ApproximateCompressionIPFormulation,
)
    belief_count = length(formulation.beliefs)
    belief_count <= 62 ||
        throw(ArgumentError("coverage-mask lower bound supports at most 62 beliefs"))
    full_mask = (UInt64(1) << belief_count) - UInt64(1)
    inactive_mask = UInt64(0)
    for row in 1:belief_count
        formulation.frontier_cover[row, formulation.inactive_index] &&
            (inactive_mask |= UInt64(1) << (row - 1))
    end
    best = Dict{UInt64,Int}(inactive_mask => 1)
    for column in eachindex(formulation.strategy_ids)
        column == formulation.inactive_index && continue
        cover = UInt64(0)
        for row in 1:belief_count
            formulation.frontier_cover[row, column] &&
                (cover |= UInt64(1) << (row - 1))
        end
        prior = collect(best)
        for (mask, count) in prior
            combined = mask | cover
            best[combined] = min(get(best, combined, typemax(Int)), count + 1)
        end
    end
    haskey(best, full_mask) ||
        error("the source library must cover its own operational-loss floor")
    return best[full_mask]
end
