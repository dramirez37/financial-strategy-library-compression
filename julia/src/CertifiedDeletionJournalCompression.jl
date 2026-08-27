const JOURNAL_DELETION_SOLUTION_SCHEMA_VERSION =
    "journal-compression-certified-deletion-v1"

const _JOURNAL_DELETION_ALGORITHMS = (
    :heaviest_safe_first,
    :lightest_safe_first,
    :maximum_immediate_burden_release,
    :minimum_remaining_unique_carrier_exposure,
    :declared_source_order,
    :random_order_rechecked_deletion,
    :multistart_random_deletion,
)


"""Exactly certified accepted deletion in original instance coordinates."""
struct JournalCertifiedDeletionStep
    step_index::Int
    complete_scan_index::Int
    strategy_index::Int
    strategy_id::StrategyId
    exact_burden_release::ExactRational
    selection_score::NamedTuple
    selected_before_indices::Vector{Int}
    selected_after_indices::Vector{Int}
    mandatory_retained::Bool
    tagged_coverage_preserved::Bool
    frontier_preserved::Bool
    closure_preserved::Bool
    exact_burden_after::ExactRational
end


"""One candidate result from the mandatory final irreducibility scan."""
struct JournalDeletionIrreducibilityCheck
    strategy_index::Int
    strategy_id::StrategyId
    deletion_safe::Bool
    mandatory_retained::Bool
    tagged_coverage_preserved::Bool
    frontier_preserved::Bool
    closure_preserved::Bool
end


"""Complete exact one-deletion irreducibility certificate."""
struct JournalDeletionIrreducibilityCertificate
    complete::Bool
    complete_scan_index::Int
    checks::Vector{JournalDeletionIrreducibilityCheck}
    no_safe_nonmandatory_deletion::Bool
end


"""Auditable counts for semantic recomputation and complete scans."""
struct JournalDeletionCounters
    frontier_checks::BigInt
    closure_checks::BigInt
    complete_scans::BigInt
end


"""Measured wall-clock scopes; these are instrumentation, not scaling evidence."""
struct JournalDeletionRuntime
    algorithm_ns::UInt64
    final_certification_ns::UInt64
    total_ns::UInt64
end


"""Certified endpoint summary for one random multi-start run."""
struct JournalDeletionStartSummary
    start_index::Int
    random_seed::UInt64
    random_order_indices::Vector{Int}
    selected_indices::Vector{Int}
    exact_burden::ExactRational
    deletion_count::Int
    counters::JournalDeletionCounters
    exact_feasible::Bool
    irreducible::Bool
end


"""
    JournalDeletionSolutionResult

Common result for deterministic, random-order, and multi-start rechecked
deletion. `status=:certified_irreducible_heuristic` asserts exact source-safe
feasibility and a complete one-deletion scan, but never global optimality.
"""
struct JournalDeletionSolutionResult
    schema_version::String
    algorithm::Symbol
    status::Symbol
    instance_sha256::String
    selected::BitVector
    selected_strategy_ids::Tuple{Vararg{StrategyId}}
    exact_burden::ExactRational
    deletion_trace::Vector{JournalCertifiedDeletionStep}
    counters::JournalDeletionCounters
    runtime::JournalDeletionRuntime
    random_seed::Union{Nothing,UInt64}
    order_indices::Vector{Int}
    tie_declaration::String
    final_feasibility_certificate::NamedTuple
    irreducibility_certificate::JournalDeletionIrreducibilityCertificate
    start_summaries::Vector{JournalDeletionStartSummary}
end


struct _JournalDeletionCandidateCheck
    strategy_index::Int
    trial::BitVector
    check::NamedTuple
    remaining_unique_carrier_exposure::Int
end


function _journal_deletion_uint64_seed(seed::Integer)
    0 <= seed <= typemax(UInt64) || throw(
        ArgumentError("a deletion seed must be representable as UInt64"),
    )
    return UInt64(seed)
end


function _journal_deletion_optional_indices(
    instance::JournalCompressionInstance,
    selected::AbstractVector{Bool},
)
    return Int[
        index for index in eachindex(selected) if
        selected[index] && !instance.mandatory[index]
    ]
end


function _journal_resolve_declared_source_order(
    instance::JournalCompressionInstance,
    declared_source_order,
)
    optional = Int[
        index for index in eachindex(instance.strategy_ids) if
        !instance.mandatory[index]
    ]
    isnothing(declared_source_order) && return optional
    order = Int[Int(index) for index in declared_source_order]
    length(order) == length(optional) || throw(
        ArgumentError(
            "declared_source_order must list every nonmandatory strategy exactly once",
        ),
    )
    sort(order) == optional || throw(
        ArgumentError(
            "declared_source_order must be a permutation of the original nonmandatory indices",
        ),
    )
    return order
end


function _journal_unique_carrier_exposure(
    instance::JournalCompressionInstance,
    selected::AbstractVector{Bool},
)
    return count(
        row -> count(
            column -> selected[column] && instance.coverage[row, column],
            eachindex(selected),
        ) == 1,
        axes(instance.coverage, 1),
    )
end


function _journal_complete_deletion_scan(
    instance::JournalCompressionInstance,
    current::BitVector,
)
    candidates = _JournalDeletionCandidateCheck[]
    for index in _journal_deletion_optional_indices(instance, current)
        trial = copy(current)
        trial[index] = false
        burden = journal_compression_burden(instance, trial)
        check = check_journal_compression_solution(
            instance,
            trial;
            expected_burden = burden,
        )
        push!(
            candidates,
            _JournalDeletionCandidateCheck(
                index,
                trial,
                check,
                _journal_unique_carrier_exposure(instance, trial),
            ),
        )
    end
    return candidates
end


_journal_deletion_safe(candidate::_JournalDeletionCandidateCheck) =
    candidate.check.exact_feasible && candidate.check.burden_reconciled


function _journal_deletion_tie_declaration(algorithm::Symbol)
    if algorithm == :heaviest_safe_first
        return "maximum exact weight among currently safe deletions; " *
               "ties by lowest canonical original strategy index"
    elseif algorithm == :lightest_safe_first
        return "minimum exact weight among currently safe deletions; " *
               "ties by lowest canonical original strategy index"
    elseif algorithm == :maximum_immediate_burden_release
        return "maximum exact one-strategy burden release; ties by lowest " *
               "canonical original strategy index; equivalent to " *
               "heaviest-safe-first under additive burden"
    elseif algorithm == :minimum_remaining_unique_carrier_exposure
        return "minimum number of tagged requirements with exactly one " *
               "retained carrier after deletion; ties by maximum exact " *
               "burden release, then lowest canonical original strategy index"
    elseif algorithm == :declared_source_order
        return "first currently safe strategy in the complete caller-declared " *
               "order; canonical original order when no order is supplied"
    elseif algorithm == :random_order_rechecked_deletion
        return "first currently safe strategy in one StableRNG permutation; " *
               "the returned UInt64 seed and original-index permutation " *
               "determine all ties"
    elseif algorithm == :multistart_random_deletion
        return "minimum certified endpoint burden across starts; ties by " *
               "lexicographic selected-index tuple, then start index"
    end
    throw(ArgumentError("unsupported journal deletion algorithm: $algorithm"))
end


function _journal_choose_deletion_candidate(
    instance::JournalCompressionInstance,
    candidates::Vector{_JournalDeletionCandidateCheck},
    algorithm::Symbol,
    order_rank::Dict{Int,Int},
)
    safe = _JournalDeletionCandidateCheck[
        candidate for candidate in candidates if _journal_deletion_safe(candidate)
    ]
    isempty(safe) && return nothing
    if algorithm in (:heaviest_safe_first, :maximum_immediate_burden_release)
        sort!(
            safe;
            by = candidate -> (
                -instance.weights[candidate.strategy_index],
                candidate.strategy_index,
            ),
        )
    elseif algorithm == :lightest_safe_first
        sort!(
            safe;
            by = candidate -> (
                instance.weights[candidate.strategy_index],
                candidate.strategy_index,
            ),
        )
    elseif algorithm == :minimum_remaining_unique_carrier_exposure
        sort!(
            safe;
            by = candidate -> (
                candidate.remaining_unique_carrier_exposure,
                -instance.weights[candidate.strategy_index],
                candidate.strategy_index,
            ),
        )
    elseif algorithm in (:declared_source_order, :random_order_rechecked_deletion)
        sort!(safe; by = candidate -> order_rank[candidate.strategy_index])
    else
        throw(ArgumentError("unsupported single-start deletion algorithm: $algorithm"))
    end
    return first(safe)
end


function _journal_deletion_selection_score(
    instance::JournalCompressionInstance,
    candidate::_JournalDeletionCandidateCheck,
    algorithm::Symbol,
    order_rank::Dict{Int,Int},
)
    weight = instance.weights[candidate.strategy_index]
    algorithm == :heaviest_safe_first && return (exact_weight = weight,)
    algorithm == :lightest_safe_first && return (exact_weight = weight,)
    algorithm == :maximum_immediate_burden_release && return (
        exact_immediate_burden_release = weight,
    )
    algorithm == :minimum_remaining_unique_carrier_exposure && return (
        remaining_unique_carrier_exposure =
            candidate.remaining_unique_carrier_exposure,
        exact_immediate_burden_release = weight,
    )
    algorithm == :declared_source_order && return (
        declared_source_rank = order_rank[candidate.strategy_index],
    )
    algorithm == :random_order_rechecked_deletion && return (
        random_order_rank = order_rank[candidate.strategy_index],
    )
    throw(ArgumentError("unsupported deletion score algorithm: $algorithm"))
end


function _journal_deletion_step(
    instance::JournalCompressionInstance,
    before::BitVector,
    candidate::_JournalDeletionCandidateCheck,
    algorithm::Symbol,
    order_rank::Dict{Int,Int},
    step_index::Int,
    scan_index::Int,
)
    check = candidate.check
    _journal_deletion_safe(candidate) || throw(
        ArgumentError("an uncertified deletion cannot be appended to the trace"),
    )
    index = candidate.strategy_index
    return JournalCertifiedDeletionStep(
        step_index,
        scan_index,
        index,
        instance.strategy_ids[index],
        instance.weights[index],
        _journal_deletion_selection_score(
            instance,
            candidate,
            algorithm,
            order_rank,
        ),
        findall(before),
        findall(candidate.trial),
        check.mandatory_retained,
        check.tagged_coverage,
        check.frontier_preserved,
        check.closure_preserved,
        check.exact_burden,
    )
end


function _journal_irreducibility_certificate(
    instance::JournalCompressionInstance,
    scan_index::Int,
    candidates::Vector{_JournalDeletionCandidateCheck},
)
    checks = JournalDeletionIrreducibilityCheck[
        JournalDeletionIrreducibilityCheck(
            candidate.strategy_index,
            instance.strategy_ids[candidate.strategy_index],
            _journal_deletion_safe(candidate),
            candidate.check.mandatory_retained,
            candidate.check.tagged_coverage,
            candidate.check.frontier_preserved,
            candidate.check.closure_preserved,
        ) for candidate in candidates
    ]
    no_safe = all(!check.deletion_safe for check in checks)
    return JournalDeletionIrreducibilityCertificate(
        true,
        scan_index,
        checks,
        no_safe,
    )
end


function _journal_deletion_feasibility_certificate(
    instance::JournalCompressionInstance,
    selected::BitVector,
)
    burden = journal_compression_burden(instance, selected)
    check = check_journal_compression_solution(
        instance,
        selected;
        expected_burden = burden,
    )
    check.exact_feasible && check.burden_reconciled || throw(
        ArgumentError("a deletion endpoint failed exact original-library certification"),
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
        evidence_class = "exact finite rechecked-deletion computation",
    )
end


function _validate_journal_deletion_result(result::JournalDeletionSolutionResult)
    result.schema_version == JOURNAL_DELETION_SOLUTION_SCHEMA_VERSION || throw(
        ArgumentError("unsupported certified-deletion solution schema"),
    )
    result.algorithm in _JOURNAL_DELETION_ALGORITHMS || throw(
        ArgumentError("unsupported certified-deletion algorithm"),
    )
    result.status == :certified_irreducible_heuristic || throw(
        ArgumentError("a deletion result must be a certified irreducible heuristic"),
    )
    occursin(r"^[0-9a-f]{64}$", result.instance_sha256) || throw(
        ArgumentError("a deletion result needs a lowercase SHA-256"),
    )
    result.final_feasibility_certificate.selected_strategy_indices ==
    findall(result.selected) || throw(
        ArgumentError("the deletion certificate has inconsistent selected indices"),
    )
    result.final_feasibility_certificate.exact_burden == result.exact_burden || throw(
        ArgumentError("the deletion certificate has inconsistent exact burden"),
    )
    all(
        getproperty(result.final_feasibility_certificate, field) for field in (
            :mandatory_retained,
            :tagged_coverage,
            :frontier_preserved,
            :closure_preserved,
            :burden_reconciled,
        )
    ) || throw(ArgumentError("the deletion endpoint certificate contains a failure"))
    result.irreducibility_certificate.complete || throw(
        ArgumentError("the endpoint irreducibility scan is incomplete"),
    )
    result.irreducibility_certificate.no_safe_nonmandatory_deletion || throw(
        ArgumentError("the returned deletion endpoint is not one-deletion irreducible"),
    )
    result.counters.frontier_checks == result.counters.closure_checks || throw(
        ArgumentError("frontier and closure checks must be paired"),
    )
    result.counters.complete_scans > 0 || throw(
        ArgumentError("a deletion result needs a complete final scan"),
    )
    result.runtime.total_ns >= result.runtime.algorithm_ns || throw(
        ArgumentError("deletion runtime scopes are inconsistent"),
    )
    result.runtime.total_ns >= result.runtime.final_certification_ns || throw(
        ArgumentError("deletion certification runtime is inconsistent"),
    )
    stochastic = result.algorithm in (
        :random_order_rechecked_deletion,
        :multistart_random_deletion,
    )
    stochastic == !isnothing(result.random_seed) || throw(
        ArgumentError("random seed presence is inconsistent with the algorithm"),
    )
    return result
end


function _solve_journal_deletion_single(
    instance::JournalCompressionInstance,
    algorithm::Symbol;
    declared_source_order = nothing,
    random_seed::Union{Nothing,UInt64} = nothing,
)
    algorithm in _JOURNAL_DELETION_ALGORITHMS || throw(
        ArgumentError("unsupported journal deletion algorithm: $algorithm"),
    )
    algorithm == :multistart_random_deletion && throw(
        ArgumentError("multi-start deletion requires the multi-start driver"),
    )
    validate_journal_compression_instance(instance)
    total_start = time_ns()
    optional = _journal_resolve_declared_source_order(instance, nothing)
    order = if algorithm == :declared_source_order
        _journal_resolve_declared_source_order(instance, declared_source_order)
    elseif algorithm == :random_order_rechecked_deletion
        isnothing(random_seed) && throw(
            ArgumentError("random-order deletion requires a UInt64 seed"),
        )
        optional[randperm(StableRNG(random_seed), length(optional))]
    else
        optional
    end
    order_rank = Dict(index => rank for (rank, index) in enumerate(order))
    current = trues(length(instance.strategy_ids))
    trace = JournalCertifiedDeletionStep[]
    scan_count = 0
    candidate_check_count = 0
    final_scan = _JournalDeletionCandidateCheck[]

    algorithm_start = time_ns()
    while true
        scan_count += 1
        scan = _journal_complete_deletion_scan(instance, current)
        candidate_check_count += length(scan)
        candidate = _journal_choose_deletion_candidate(
            instance,
            scan,
            algorithm,
            order_rank,
        )
        if isnothing(candidate)
            final_scan = scan
            break
        end
        before = copy(current)
        push!(
            trace,
            _journal_deletion_step(
                instance,
                before,
                candidate,
                algorithm,
                order_rank,
                length(trace) + 1,
                scan_count,
            ),
        )
        current = candidate.trial
        # No candidate certificate survives this mutation: the next loop
        # performs a new complete scan against the new retained library.
    end
    algorithm_ns = time_ns() - algorithm_start

    certification_start = time_ns()
    irreducibility = _journal_irreducibility_certificate(
        instance,
        scan_count,
        final_scan,
    )
    irreducibility.no_safe_nonmandatory_deletion || throw(
        ArgumentError("the final complete scan found a safe deletion"),
    )
    feasibility = _journal_deletion_feasibility_certificate(instance, current)
    certification_ns = time_ns() - certification_start
    counters = JournalDeletionCounters(
        BigInt(candidate_check_count + 1),
        BigInt(candidate_check_count + 1),
        BigInt(scan_count),
    )
    selected_ids = Tuple(instance.strategy_ids[index] for index in findall(current))
    result = JournalDeletionSolutionResult(
        JOURNAL_DELETION_SOLUTION_SCHEMA_VERSION,
        algorithm,
        :certified_irreducible_heuristic,
        journal_compression_instance_sha256(instance),
        copy(current),
        selected_ids,
        feasibility.exact_burden,
        trace,
        counters,
        JournalDeletionRuntime(
            algorithm_ns,
            certification_ns,
            time_ns() - total_start,
        ),
        random_seed,
        copy(order),
        _journal_deletion_tie_declaration(algorithm),
        feasibility,
        irreducibility,
        JournalDeletionStartSummary[],
    )
    return _validate_journal_deletion_result(result)
end


function _journal_multistart_random_deletion(
    instance::JournalCompressionInstance,
    seed::UInt64,
    starts::Integer,
)
    starts > 0 || throw(ArgumentError("multi-start deletion requires starts > 0"))
    total_start = time_ns()
    seed_rng = StableRNG(seed)
    run_seeds = UInt64[seed]
    for _ in 2:Int(starts)
        push!(run_seeds, rand(seed_rng, UInt64))
    end
    runs = JournalDeletionSolutionResult[]
    summaries = JournalDeletionStartSummary[]
    for (start_index, run_seed) in enumerate(run_seeds)
        run = _solve_journal_deletion_single(
            instance,
            :random_order_rechecked_deletion;
            random_seed = run_seed,
        )
        push!(runs, run)
        push!(
            summaries,
            JournalDeletionStartSummary(
                start_index,
                run_seed,
                copy(run.order_indices),
                findall(run.selected),
                run.exact_burden,
                length(run.deletion_trace),
                run.counters,
                true,
                run.irreducibility_certificate.no_safe_nonmandatory_deletion,
            ),
        )
    end
    best_index = 1
    for index in 2:length(runs)
        left = runs[index]
        right = runs[best_index]
        if left.exact_burden < right.exact_burden ||
           (
            left.exact_burden == right.exact_burden &&
            _journal_selection_isless(left.selected, right.selected)
        )
            best_index = index
        end
    end
    best = runs[best_index]
    counters = JournalDeletionCounters(
        sum((run.counters.frontier_checks for run in runs); init = BigInt(0)),
        sum((run.counters.closure_checks for run in runs); init = BigInt(0)),
        sum((run.counters.complete_scans for run in runs); init = BigInt(0)),
    )
    algorithm_ns = sum(
        (run.runtime.algorithm_ns for run in runs);
        init = UInt64(0),
    )
    certification_ns = sum(
        (run.runtime.final_certification_ns for run in runs);
        init = UInt64(0),
    )
    result = JournalDeletionSolutionResult(
        JOURNAL_DELETION_SOLUTION_SCHEMA_VERSION,
        :multistart_random_deletion,
        :certified_irreducible_heuristic,
        best.instance_sha256,
        copy(best.selected),
        best.selected_strategy_ids,
        best.exact_burden,
        copy(best.deletion_trace),
        counters,
        JournalDeletionRuntime(
            algorithm_ns,
            certification_ns,
            time_ns() - total_start,
        ),
        seed,
        copy(best.order_indices),
        _journal_deletion_tie_declaration(:multistart_random_deletion),
        best.final_feasibility_certificate,
        best.irreducibility_certificate,
        summaries,
    )
    return _validate_journal_deletion_result(result)
end


"""
    solve_journal_compression_deletion(instance; algorithm, ...)

Common API for all certified deletion variants. Every iteration performs a
complete fresh scan of retained nonmandatory strategies against the original
source frontier and closure. Random methods use `StableRNG` and return their
seed and permutation. `starts` is used only by multi-start random deletion.
"""
function solve_journal_compression_deletion(
    instance::JournalCompressionInstance;
    algorithm::Symbol = :heaviest_safe_first,
    declared_source_order = nothing,
    seed::Integer = DEFAULT_RESEARCH_SEED,
    starts::Integer = 16,
)
    algorithm in _JOURNAL_DELETION_ALGORITHMS || throw(
        ArgumentError("unsupported journal deletion algorithm: $algorithm"),
    )
    if algorithm == :multistart_random_deletion
        return _journal_multistart_random_deletion(
            instance,
            _journal_deletion_uint64_seed(seed),
            starts,
        )
    end
    random_seed = algorithm == :random_order_rechecked_deletion ?
                  _journal_deletion_uint64_seed(seed) : nothing
    return _solve_journal_deletion_single(
        instance,
        algorithm;
        declared_source_order,
        random_seed,
    )
end


solve_journal_compression_heaviest_safe_first(instance::JournalCompressionInstance) =
    solve_journal_compression_deletion(instance; algorithm = :heaviest_safe_first)

solve_journal_compression_lightest_safe_first(instance::JournalCompressionInstance) =
    solve_journal_compression_deletion(instance; algorithm = :lightest_safe_first)

function solve_journal_compression_maximum_immediate_burden_release(
    instance::JournalCompressionInstance,
)
    return solve_journal_compression_deletion(
        instance;
        algorithm = :maximum_immediate_burden_release,
    )
end

function solve_journal_compression_minimum_unique_carrier_exposure(
    instance::JournalCompressionInstance,
)
    return solve_journal_compression_deletion(
        instance;
        algorithm = :minimum_remaining_unique_carrier_exposure,
    )
end

function solve_journal_compression_declared_order(
    instance::JournalCompressionInstance;
    declared_source_order = nothing,
)
    return solve_journal_compression_deletion(
        instance;
        algorithm = :declared_source_order,
        declared_source_order,
    )
end

function solve_journal_compression_random_order(
    instance::JournalCompressionInstance;
    seed::Integer = DEFAULT_RESEARCH_SEED,
)
    return solve_journal_compression_deletion(
        instance;
        algorithm = :random_order_rechecked_deletion,
        seed,
    )
end

function solve_journal_compression_multistart_random(
    instance::JournalCompressionInstance;
    seed::Integer = DEFAULT_RESEARCH_SEED,
    starts::Integer = 16,
)
    return solve_journal_compression_deletion(
        instance;
        algorithm = :multistart_random_deletion,
        seed,
        starts,
    )
end
