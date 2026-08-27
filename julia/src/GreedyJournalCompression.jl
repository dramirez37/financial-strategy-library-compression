const JOURNAL_GREEDY_SOLUTION_SCHEMA_VERSION =
    "journal-compression-greedy-solution-v1"


"""One exact forward-greedy choice in original instance coordinates."""
struct JournalGreedyStep
    step_index::Int
    strategy_index::Int
    strategy_id::StrategyId
    exact_weight::ExactRational
    newly_covered_requirement_indices::Vector{Int}
    newly_covered_count::Int
    uncovered_before::Int
    uncovered_after::Int
    exact_score::ExactRational
end


"""One deterministic reverse-deletion examination."""
struct JournalReverseDeletionStep
    examination_index::Int
    strategy_index::Int
    strategy_id::StrategyId
    removed::Bool
    uncovered_after_trial::Int
    exact_burden_before::ExactRational
    exact_burden_after::ExactRational
end


"""Scope and exact constant of the classical greedy guarantee."""
struct JournalGreedyGuarantee
    primary_source_key::String
    applies_to_exact_burden::Bool
    maximum_residual_set_cardinality::Int
    exact_harmonic_factor::ExactRational
    declaration::String
end


"""
    JournalGreedySolutionResult

Deterministic exact-arithmetic construction result. `status` is deliberately
`:feasible_heuristic`: neither this status nor the feasibility certificate
asserts optimality, exhaustive search, solver evidence, or Lean verification.
"""
struct JournalGreedySolutionResult
    schema_version::String
    algorithm::Symbol
    status::Symbol
    instance_sha256::String
    selected::BitVector
    selected_strategy_ids::Tuple{Vararg{StrategyId}}
    exact_burden::ExactRational
    greedy_burden_before_reverse_deletion::ExactRational
    step_trace::Vector{JournalGreedyStep}
    uncovered_counts::Vector{Int}
    reverse_deletion_trace::Vector{JournalReverseDeletionStep}
    tie_declaration::String
    guarantee::JournalGreedyGuarantee
    final_certificate::NamedTuple
end


function _journal_harmonic_number(d::Integer)
    d >= 0 || throw(ArgumentError("a harmonic-number index cannot be negative"))
    d == 0 && return one(ExactRational)
    return sum(
        (BigInt(1) // BigInt(index) for index in 1:Int(d));
        init = zero(ExactRational),
    )
end


function _journal_unpreprocessed_instance(instance::JournalCompressionInstance)
    validate_journal_compression_instance(instance)
    !instance.preprocessing.applied && return instance
    identity = identity_journal_preprocessing_map(
        length(instance.requirements),
        length(instance.strategy_ids),
    )
    return _journal_rebuild_with_preprocessing(instance, identity)
end


function _journal_prepare_greedy(instance::JournalCompressionInstance)
    # The published algorithm starts from mandatory strategies only. Rebuild
    # that residual model even when a caller supplies a stronger valid map, so
    # preprocessing choices cannot silently change its trace or tie outcome.
    base = _journal_unpreprocessed_instance(instance)
    prepared = preprocess_mandatory_journal_instance(base)
    reduced = journal_reduced_cover_model(prepared)
    any(reduced.mandatory) && throw(
        ArgumentError("mandatory preprocessing left a mandatory residual strategy"),
    )
    all(row -> any(reduced.coverage[row, :]), axes(reduced.coverage, 1)) || throw(
        ArgumentError("a residual tagged requirement has no available carrier"),
    )
    return prepared, reduced
end


function _journal_newly_covered_rows(
    coverage::BitMatrix,
    uncovered::BitVector,
    column::Int,
)
    return Int[
        row for row in axes(coverage, 1) if
        uncovered[row] && coverage[row, column]
    ]
end


function _journal_greedy_score(
    mode::Symbol,
    weight::ExactRational,
    newly_covered_count::Int,
)
    newly_covered_count > 0 || throw(
        ArgumentError("a greedy score requires positive new coverage"),
    )
    numerator = mode == :weighted ? weight : one(ExactRational)
    return numerator / exact_rational(newly_covered_count)
end


function _journal_greedy_guarantee(
    mode::Symbol,
    reduced::ExactTaggedCoverModel,
)
    column_sizes = Int[
        count(reduced.coverage[:, column]) for
        column in axes(reduced.coverage, 2)
    ]
    d = isempty(column_sizes) ? 0 : maximum(column_sizes)
    harmonic = _journal_harmonic_number(d)
    equal_weights = isempty(reduced.weights) ||
                    all(==(first(reduced.weights)), reduced.weights)
    applies = mode == :weighted || equal_weights
    declaration = if isempty(reduced.requirements)
        "No residual requirement remains; the mandatory selection is exact and the factor is one."
    elseif mode == :weighted
        "Chvatal's positive-cost weighted-set-cover H(d) guarantee applies to exact burden."
    elseif equal_weights
        "All residual optional weights are equal, so cardinality greedy is weighted greedy after common scaling and the H(d) burden guarantee applies."
    else
        "Cardinality greedy ignores unequal weights; no approximation guarantee for exact burden is asserted."
    end
    return JournalGreedyGuarantee(
        "Chvatal1979",
        applies,
        d,
        harmonic,
        declaration,
    )
end


function _journal_count_uncovered(
    instance::JournalCompressionInstance,
    selected::AbstractVector{Bool},
)
    return count(
        row -> !any(
            selected[column] && instance.coverage[row, column] for
            column in eachindex(selected)
        ),
        axes(instance.coverage, 1),
    )
end


function _journal_reverse_delete(
    instance::JournalCompressionInstance,
    selected::BitVector,
    greedy_steps::Vector{JournalGreedyStep},
)
    trace = JournalReverseDeletionStep[]
    for step in Iterators.reverse(greedy_steps)
        index = step.strategy_index
        instance.mandatory[index] && continue
        before = journal_compression_burden(instance, selected)
        trial = copy(selected)
        trial[index] = false
        uncovered = _journal_count_uncovered(instance, trial)
        check = check_journal_compression_solution(instance, trial)
        removable = uncovered == 0 && check.exact_feasible
        removable && (selected = trial)
        after = journal_compression_burden(instance, selected)
        push!(
            trace,
            JournalReverseDeletionStep(
                length(trace) + 1,
                index,
                instance.strategy_ids[index],
                removable,
                uncovered,
                before,
                after,
            ),
        )
    end
    return selected, trace
end


function _journal_greedy_certificate(
    instance::JournalCompressionInstance,
    selected::BitVector,
    exact_burden::ExactRational,
)
    check = check_journal_compression_solution(
        instance,
        selected;
        expected_burden = exact_burden,
    )
    check.exact_feasible && check.burden_reconciled || throw(
        ArgumentError(
            "greedy construction failed independent original-library rechecking",
        ),
    )
    return (
        selected_strategy_indices = findall(selected),
        mandatory_retained = check.mandatory_retained,
        tagged_coverage = check.tagged_coverage,
        frontier_preserved = check.frontier_preserved,
        closure_preserved = check.closure_preserved,
        exact_burden = check.exact_burden,
        burden_reconciled = check.burden_reconciled,
        solver_status_used = false,
        search_complete = false,
        lean_kernel_verified = false,
        evidence_class = "exact finite heuristic computation",
    )
end


function _validate_journal_greedy_result(result::JournalGreedySolutionResult)
    result.schema_version == JOURNAL_GREEDY_SOLUTION_SCHEMA_VERSION || throw(
        ArgumentError("unsupported greedy journal solution schema version"),
    )
    result.algorithm in (
        :weighted_greedy,
        :cardinality_greedy,
        :weighted_greedy_reverse_delete,
    ) || throw(ArgumentError("unsupported journal greedy algorithm"))
    result.status == :feasible_heuristic || throw(
        ArgumentError("a greedy journal result must have feasible_heuristic status"),
    )
    occursin(r"^[0-9a-f]{64}$", result.instance_sha256) || throw(
        ArgumentError("a greedy journal result needs a lowercase SHA-256"),
    )
    length(result.selected_strategy_ids) == count(result.selected) || throw(
        ArgumentError("selected strategy identifiers do not match the selection size"),
    )
    length(Set(result.selected_strategy_ids)) == length(result.selected_strategy_ids) || throw(
        ArgumentError("selected strategy identifiers are not unique"),
    )
    result.final_certificate.selected_strategy_indices == findall(result.selected) || throw(
        ArgumentError("the final certificate has inconsistent selected indices"),
    )
    length(result.uncovered_counts) == length(result.step_trace) + 1 || throw(
        ArgumentError("greedy uncovered-count trace has inconsistent length"),
    )
    all(value -> value >= 0, result.uncovered_counts) || throw(
        ArgumentError("greedy uncovered counts cannot be negative"),
    )
    issorted(result.uncovered_counts; rev = true) || throw(
        ArgumentError("greedy uncovered counts must be nonincreasing"),
    )
    last(result.uncovered_counts) == 0 || throw(
        ArgumentError("greedy construction stopped with uncovered requirements"),
    )
    all(step -> step.exact_score > 0, result.step_trace) || throw(
        ArgumentError("greedy scores must be positive"),
    )
    result.exact_burden <= result.greedy_burden_before_reverse_deletion || throw(
        ArgumentError("reverse deletion increased exact burden"),
    )
    all(
        getproperty(result.final_certificate, field) for field in (
            :mandatory_retained,
            :tagged_coverage,
            :frontier_preserved,
            :closure_preserved,
            :burden_reconciled,
        )
    ) || throw(ArgumentError("the final greedy certificate contains a failed check"))
    result.final_certificate.exact_burden == result.exact_burden || throw(
        ArgumentError("the final greedy certificate has inconsistent burden"),
    )
    return result
end


function _solve_journal_compression_greedy(
    instance::JournalCompressionInstance,
    mode::Symbol;
    reverse_delete::Bool,
)
    mode in (:weighted, :cardinality) || throw(
        ArgumentError("greedy mode must be weighted or cardinality"),
    )
    prepared, reduced = _journal_prepare_greedy(instance)
    original_rows = prepared.preprocessing.remaining_requirement_indices
    original_columns = prepared.preprocessing.remaining_strategy_indices
    uncovered = trues(length(reduced.requirements))
    reduced_selected = falses(length(reduced.strategy_ids))
    steps = JournalGreedyStep[]
    uncovered_counts = Int[count(uncovered)]

    while any(uncovered)
        best_column = 0
        best_rows = Int[]
        best_score = nothing
        for column in axes(reduced.coverage, 2)
            reduced_selected[column] && continue
            newly_covered = _journal_newly_covered_rows(
                reduced.coverage,
                uncovered,
                column,
            )
            isempty(newly_covered) && continue
            score = _journal_greedy_score(
                mode,
                reduced.weights[column],
                length(newly_covered),
            )
            original_index = original_columns[column]
            incumbent_original_index = best_column == 0 ? typemax(Int) :
                                       original_columns[best_column]
            if isnothing(best_score) || score < best_score ||
               (score == best_score && original_index < incumbent_original_index)
                best_column = column
                best_rows = newly_covered
                best_score = score
            end
        end
        best_column != 0 || throw(
            ArgumentError("greedy construction reached an uncovered requirement with no carrier"),
        )
        before = count(uncovered)
        reduced_selected[best_column] = true
        uncovered[best_rows] .= false
        after = count(uncovered)
        original_index = original_columns[best_column]
        push!(
            steps,
            JournalGreedyStep(
                length(steps) + 1,
                original_index,
                instance.strategy_ids[original_index],
                reduced.weights[best_column],
                original_rows[best_rows],
                length(best_rows),
                before,
                after,
                best_score,
            ),
        )
        push!(uncovered_counts, after)
    end

    selected = lift_journal_compression_solution(prepared, reduced_selected)
    greedy_burden = journal_compression_burden(instance, selected)
    reverse_trace = JournalReverseDeletionStep[]
    if reverse_delete
        selected, reverse_trace = _journal_reverse_delete(instance, selected, steps)
    end
    burden = journal_compression_burden(instance, selected)
    certificate = _journal_greedy_certificate(instance, selected, burden)
    algorithm = if mode == :cardinality
        :cardinality_greedy
    elseif reverse_delete
        :weighted_greedy_reverse_delete
    else
        :weighted_greedy
    end
    selected_ids = Tuple(instance.strategy_ids[index] for index in findall(selected))
    result = JournalGreedySolutionResult(
        JOURNAL_GREEDY_SOLUTION_SCHEMA_VERSION,
        algorithm,
        :feasible_heuristic,
        journal_compression_instance_sha256(instance),
        copy(selected),
        selected_ids,
        burden,
        greedy_burden,
        steps,
        uncovered_counts,
        reverse_trace,
        "minimum exact score, then lowest original strategy index in canonical order",
        _journal_greedy_guarantee(mode, reduced),
        certificate,
    )
    return _validate_journal_greedy_result(result)
end


"""Construct a safe library by exact positive-weight cost-per-new-tag greedy."""
function solve_journal_compression_weighted_greedy(
    instance::JournalCompressionInstance,
)
    return _solve_journal_compression_greedy(
        instance,
        :weighted;
        reverse_delete = false,
    )
end


"""Construct a safe library by maximum-new-tag cardinality greedy."""
function solve_journal_compression_cardinality_greedy(
    instance::JournalCompressionInstance,
)
    return _solve_journal_compression_greedy(
        instance,
        :cardinality;
        reverse_delete = false,
    )
end


"""Run weighted greedy and deterministic reverse deletion."""
function solve_journal_compression_weighted_greedy_reverse_delete(
    instance::JournalCompressionInstance,
)
    return _solve_journal_compression_greedy(
        instance,
        :weighted;
        reverse_delete = true,
    )
end


"""
    chvatal_weighted_greedy_tightness_instance(m; epsilon=1//1000)

Exact tagged-cover realization of Chvatal's 1979 near-tight family: `m`
singleton columns of costs `1/j` and one universe column of cost `1+epsilon`.
The mandatory inactive strategy covers the sole zero-frontier requirement.
"""
function chvatal_weighted_greedy_tightness_instance(
    m::Integer;
    epsilon = BigInt(1) // BigInt(1000),
)
    m >= 2 || throw(ArgumentError("the Chvatal fixture requires m >= 2"))
    eps = exact_rational(epsilon)
    eps > 0 || throw(ArgumentError("epsilon must be positive"))
    harmonic = _journal_harmonic_number(m)
    one(ExactRational) + eps < harmonic || throw(
        ArgumentError("the fixture requires 1 + epsilon < H(m)"),
    )
    width = ndigits(Int(m))
    singleton_ids = Symbol[
        Symbol("singleton_", lpad(string(index), width, '0')) for index in 1:Int(m)
    ]
    module_ids = Symbol[Symbol("element_", lpad(string(index), width, '0')) for index in 1:Int(m)]
    strategy_ids = Symbol[:inactive; singleton_ids; :universe]
    mandatory = Bool[true; falses(Int(m) + 1)]
    weights = Any[
        0;
        [BigInt(1) // BigInt(index) for index in 1:Int(m)];
        one(ExactRational) + eps
    ]
    modules = Any[Symbol[]]
    append!(modules, Any[[module_ids[index]] for index in 1:Int(m)])
    push!(modules, module_ids)
    profiles = zeros(Int, length(strategy_ids), 1)
    provenance = JournalCompressionProvenance(
        :adversarial,
        "chvatal-weighted-greedy-tightness-m$(m)-epsilon-$(numerator(eps))-$(denominator(eps))",
        "Chvatal (1979), DOI 10.1287/moor.4.3.233";
        generator = "chvatal_weighted_greedy_tightness_instance",
        attributes = [
            "evidence_class" => "exact finite literature fixture",
            "epsilon" => string(numerator(eps), "//", denominator(eps)),
            "element_count" => string(m),
        ],
    )
    return journal_compression_instance_from_components(
        strategy_ids,
        mandatory,
        weights,
        [:zero_frontier],
        profiles,
        modules;
        provenance,
    )
end
