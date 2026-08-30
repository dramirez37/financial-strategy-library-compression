const JOURNAL_EXACT_SOLUTION_SCHEMA_VERSION =
    "journal-compression-exact-solution-v1"


"""Search counters with algorithm-independent field meanings."""
struct JournalExactSolveCounters
    state_layer_pairs_visited::BigInt
    transitions_evaluated::BigInt
    candidate_selections_evaluated::BigInt
    final_reachable_states::BigInt
end


"""Measured wall-clock scopes for one exact solve, in nanoseconds."""
struct JournalExactRuntime
    preprocessing_ns::UInt64
    search_ns::UInt64
    reconstruction_and_certification_ns::UInt64
    total_ns::UInt64
end


"""Dimension and exact-offset summary for mandatory preprocessing."""
struct JournalExactPreprocessingSummary
    original_strategy_count::Int
    reduced_strategy_count::Int
    original_requirement_count::Int
    reduced_requirement_count::Int
    forced_strategy_indices::Vector{Int}
    exact_objective_offset::ExactRational
    input_preprocessing_reused::Bool
    all_optimizer_identities_reconstructable::Bool
end


"""
    JournalExactSolutionResult

Standard result for the two independent exact finite algorithms. `status`
is `:exact_optimum` only after every returned original-library selection has
passed the independent frontier, closure, burden, and mandatory checks.
Runtime fields are machine measurements, not theorem or scaling evidence.
"""
struct JournalExactSolutionResult
    schema_version::String
    algorithm::Symbol
    status::Symbol
    instance_sha256::String
    exact_burden::ExactRational
    selected::BitVector
    optimal_selections::Vector{BitVector}
    ties_complete::Bool
    tie_declaration::String
    strategy_ids::Tuple{Vararg{StrategyId}}
    preprocessing::JournalExactPreprocessingSummary
    counters::JournalExactSolveCounters
    runtime::JournalExactRuntime
    certificates::Vector{NamedTuple}
end


struct _JournalDPParent
    predecessor_mask::BigInt
    selected_strategy::Bool
end


function _journal_rebuild_with_preprocessing(
    instance::JournalCompressionInstance,
    preprocessing::JournalPreprocessingMap,
)
    return JournalCompressionInstance(
        instance.schema_version,
        instance.strategy_ids,
        instance.mandatory,
        instance.weights,
        instance.requirements,
        instance.coverage,
        instance.operating_profiles,
        instance.strategy_modules,
        instance.source_frontier,
        instance.source_closure,
        instance.identity_closure,
        preprocessing,
        instance.tie_handling,
        instance.provenance,
    )
end


"""
    preprocess_mandatory_journal_instance(instance)

Fix every mandatory strategy, add its exact burden to the objective offset,
and remove the tagged requirements it satisfies. No optional strategy is
removed, so this preprocessing step preserves every optimizer identity.
An already-preprocessed validated instance is returned unchanged.
"""
function preprocess_mandatory_journal_instance(
    instance::JournalCompressionInstance,
)
    validate_journal_compression_instance(instance)
    instance.preprocessing.applied && return instance

    forced = findall(instance.mandatory)
    remaining_strategies = Int[
        index for index in eachindex(instance.strategy_ids) if
        !instance.mandatory[index]
    ]
    remaining_requirements = Int[
        row for row in axes(instance.coverage, 1) if
        !any(instance.coverage[row, column] for column in forced)
    ]
    offset = sum(
        (instance.weights[index] for index in forced);
        init = zero(ExactRational),
    )
    preprocessing = JournalPreprocessingMap(
        true,
        remaining_requirements,
        remaining_strategies,
        forced,
        offset,
        Pair{Int,Tuple{Vararg{Int}}}[];
        all_optimizer_identities_reconstructable = true,
    )
    return _journal_rebuild_with_preprocessing(instance, preprocessing)
end


"""
    apply_tagged_preprocessing(instance, result)

Attach a validated exact tagged-cover preprocessing result to the common
journal instance. The returned instance keeps every original strategy,
requirement, profile, module membership, and exact weight; only its residual
optimization map changes. This lets independent algorithms solve precisely the
same reduced model without recomputing preprocessing.
"""
function apply_tagged_preprocessing(
    instance::JournalCompressionInstance,
    result::TaggedCoverPreprocessingResult,
)
    validate_journal_compression_instance(instance)
    instance.preprocessing.applied && throw(
        ArgumentError("tagged preprocessing requires an unpreprocessed instance"),
    )
    original = exact_tagged_cover_model(instance)
    original.requirements == result.original.requirements &&
    original.strategy_ids == result.original.strategy_ids &&
    original.coverage == result.original.coverage &&
    original.weights == result.original.weights &&
    original.mandatory == result.original.mandatory || throw(
        ArgumentError("tagged preprocessing result does not belong to the instance"),
    )
    result.feasible || throw(
        ArgumentError("cannot attach an infeasible tagged preprocessing result"),
    )
    preprocessing = JournalPreprocessingMap(
        true,
        sort(copy(result.remaining_requirement_indices)),
        sort(copy(result.remaining_strategy_indices)),
        sort(copy(result.forced_strategy_indices)),
        result.objective_offset,
        result.equal_coverage_choices;
        all_optimizer_identities_reconstructable =
            result.all_optimizer_identities_reconstructable,
    )
    return _journal_rebuild_with_preprocessing(instance, preprocessing)
end


_journal_selection_key(selected::AbstractVector{Bool}) = Tuple(findall(selected))


function _journal_selection_isless(left::BitVector, right::BitVector)
    return isless(_journal_selection_key(left), _journal_selection_key(right))
end


function _journal_sort_unique_selections(selections)
    ordered = BitVector[BitVector(selection) for selection in selections]
    sort!(ordered; lt = _journal_selection_isless)
    seen = Set{Tuple}()
    unique_ordered = BitVector[]
    for selection in ordered
        key = Tuple(selection)
        key in seen && continue
        push!(seen, key)
        push!(unique_ordered, selection)
    end
    return unique_ordered
end


function _journal_validate_exact_solve_options(
    instance::JournalCompressionInstance,
    retain_all_ties::Bool,
    maximum_ties::Integer,
)
    maximum_ties > 0 || throw(ArgumentError("maximum_ties must be positive"))
    if instance.tie_handling.mode == :complete && !retain_all_ties
        throw(
            ArgumentError(
                "an instance declaring complete ties cannot be solved in representative-only mode",
            ),
        )
    end
    return nothing
end


function _journal_prepare_exact_solve(
    instance::JournalCompressionInstance,
    retain_all_ties::Bool,
)
    validate_journal_compression_instance(instance)
    reused = instance.preprocessing.applied
    prepared = preprocess_mandatory_journal_instance(instance)
    if retain_all_ties &&
       !prepared.preprocessing.all_optimizer_identities_reconstructable
        throw(
            ArgumentError(
                "complete tie recovery is impossible under the supplied lossy preprocessing map",
            ),
        )
    end
    reduced = journal_reduced_cover_model(prepared)
    any(reduced.mandatory) && throw(
        ArgumentError("mandatory preprocessing left a mandatory residual strategy"),
    )
    all(row -> any(reduced.coverage[row, :]), axes(reduced.coverage, 1)) || throw(
        ArgumentError("a residual tagged requirement has no available carrier"),
    )
    summary = JournalExactPreprocessingSummary(
        length(prepared.strategy_ids),
        length(reduced.strategy_ids),
        length(prepared.requirements),
        length(reduced.requirements),
        copy(prepared.preprocessing.forced_strategy_indices),
        prepared.preprocessing.objective_offset,
        reused,
        prepared.preprocessing.all_optimizer_identities_reconstructable,
    )
    return prepared, reduced, summary
end


function _journal_reconstruct_reduced_optima(
    prepared::JournalCompressionInstance,
    reduced_selections::Vector{BitVector},
    retain_all_ties::Bool,
    maximum_ties::Integer,
)
    original = BitVector[]
    for reduced_selected in reduced_selections
        candidates = retain_all_ties ?
                     reconstruct_journal_compression_solutions(
            prepared,
            reduced_selected,
        ) : BitVector[lift_journal_compression_solution(prepared, reduced_selected)]
        append!(original, candidates)
        length(original) <= maximum_ties || throw(
            ArgumentError(
                "complete tie reconstruction exceeded maximum_ties=$maximum_ties",
            ),
        )
    end
    original = _journal_sort_unique_selections(original)
    if !retain_all_ties && length(original) > 1
        resize!(original, 1)
    end
    return original
end


function _journal_certify_optima(
    instance::JournalCompressionInstance,
    selections::Vector{BitVector},
    exact_burden::ExactRational,
)
    isempty(selections) && throw(ArgumentError("an exact result needs a selection"))
    certificates = NamedTuple[]
    for selected in selections
        check = check_journal_compression_solution(
            instance,
            selected;
            expected_burden = exact_burden,
        )
        check.exact_feasible && check.burden_reconciled || throw(
            ArgumentError(
                "an exact algorithm returned a selection that failed original-library rechecking",
            ),
        )
        push!(
            certificates,
            (
                selected_strategy_indices = findall(selected),
                mandatory_retained = check.mandatory_retained,
                tagged_coverage = check.tagged_coverage,
                frontier_preserved = check.frontier_preserved,
                closure_preserved = check.closure_preserved,
                exact_burden = check.exact_burden,
                burden_reconciled = check.burden_reconciled,
            ),
        )
    end
    return certificates
end


function _journal_exact_result(
    instance::JournalCompressionInstance,
    algorithm::Symbol,
    exact_burden::ExactRational,
    original_selections::Vector{BitVector},
    retain_all_ties::Bool,
    preprocessing::JournalExactPreprocessingSummary,
    counters::JournalExactSolveCounters,
    preprocessing_ns::UInt64,
    search_ns::UInt64,
    reconstruction_start_ns::UInt64,
    total_start_ns::UInt64,
)
    certificates = _journal_certify_optima(
        instance,
        original_selections,
        exact_burden,
    )
    reconstruction_ns = time_ns() - reconstruction_start_ns
    total_ns = time_ns() - total_start_ns
    tie_declaration = if retain_all_ties
        "all exact optimizer identities retained"
    elseif algorithm == :complete_enumeration
        "minimum selected-index list in canonical strategy order"
    else
        "first exact predecessor under increasing masks and skip-before-take order"
    end
    result = JournalExactSolutionResult(
        JOURNAL_EXACT_SOLUTION_SCHEMA_VERSION,
        algorithm,
        :exact_optimum,
        journal_compression_instance_sha256(instance),
        exact_burden,
        copy(first(original_selections)),
        [copy(selection) for selection in original_selections],
        retain_all_ties,
        tie_declaration,
        instance.strategy_ids,
        preprocessing,
        counters,
        JournalExactRuntime(
            preprocessing_ns,
            search_ns,
            reconstruction_ns,
            total_ns,
        ),
        certificates,
    )
    return _validate_journal_exact_solution_result(result)
end


function _validate_journal_exact_solution_result(
    result::JournalExactSolutionResult,
)
    result.schema_version == JOURNAL_EXACT_SOLUTION_SCHEMA_VERSION || throw(
        ArgumentError("unsupported exact journal solution schema version"),
    )
    result.algorithm in (:complete_enumeration, :requirement_mask_dp) || throw(
        ArgumentError("unsupported exact journal solution algorithm"),
    )
    result.status == :exact_optimum || throw(
        ArgumentError("an exact journal result must have exact_optimum status"),
    )
    occursin(r"^[0-9a-f]{64}$", result.instance_sha256) || throw(
        ArgumentError("an exact journal result needs a lowercase SHA-256"),
    )
    isempty(result.optimal_selections) && throw(
        ArgumentError("an exact journal result needs an optimizer"),
    )
    result.selected == first(result.optimal_selections) || throw(
        ArgumentError("the representative selection is not the first optimizer"),
    )
    all(
        selection -> length(selection) == length(result.strategy_ids),
        result.optimal_selections,
    ) || throw(ArgumentError("an optimizer has the wrong strategy count"))
    length(_journal_sort_unique_selections(result.optimal_selections)) ==
    length(result.optimal_selections) || throw(
        ArgumentError("an exact journal result repeats an optimizer"),
    )
    !result.ties_complete && length(result.optimal_selections) != 1 && throw(
        ArgumentError("representative-only output must contain one optimizer"),
    )
    length(result.certificates) == length(result.optimal_selections) || throw(
        ArgumentError("optimizer and certificate counts do not match"),
    )
    for (selection, certificate) in
        zip(result.optimal_selections, result.certificates)
        certificate.selected_strategy_indices == findall(selection) || throw(
            ArgumentError("a certificate has inconsistent selected indices"),
        )
        certificate.exact_burden == result.exact_burden || throw(
            ArgumentError("a certificate has inconsistent exact burden"),
        )
        all(
            getproperty(certificate, field) for field in (
                :mandatory_retained,
                :tagged_coverage,
                :frontier_preserved,
                :closure_preserved,
                :burden_reconciled,
            )
        ) || throw(ArgumentError("a certificate contains a failed exact check"))
    end
    all(
        value -> value >= 0,
        (
            result.counters.state_layer_pairs_visited,
            result.counters.transitions_evaluated,
            result.counters.candidate_selections_evaluated,
            result.counters.final_reachable_states,
        ),
    ) || throw(ArgumentError("exact journal counters cannot be negative"))
    return result
end


"""
    solve_journal_compression_enumeration(instance; ...)

Enumerate every subset of the residual optional strategies after mandatory
preprocessing. This is an exact finite oracle for small libraries and shares
no search recurrence with the requirement-mask dynamic program.
"""
function solve_journal_compression_enumeration(
    instance::JournalCompressionInstance;
    retain_all_ties::Bool = instance.tie_handling.mode == :complete,
    maximum_optional_strategies::Integer = 24,
    maximum_ties::Integer = 100_000,
)
    _journal_validate_exact_solve_options(instance, retain_all_ties, maximum_ties)
    0 <= maximum_optional_strategies <= 62 || throw(
        ArgumentError("maximum_optional_strategies must be in 0:62"),
    )
    total_start = time_ns()
    preprocessing_start = time_ns()
    prepared, reduced, preprocessing =
        _journal_prepare_exact_solve(instance, retain_all_ties)
    preprocessing_ns = time_ns() - preprocessing_start

    optional_count = length(reduced.strategy_ids)
    optional_count <= maximum_optional_strategies || throw(
        ArgumentError(
            "complete enumeration has $optional_count residual strategies; " *
            "the declared limit is $maximum_optional_strategies",
        ),
    )
    search_start = time_ns()
    best_burden = nothing
    best_reduced = BitVector[]
    candidate_count = UInt64(1) << optional_count
    for raw_mask in UInt64(0):(candidate_count - UInt64(1))
        selected = BitVector(
            !iszero(raw_mask & (UInt64(1) << (index - 1))) for
            index in 1:optional_count
        )
        exact_tagged_cover_feasible(reduced, selected) || continue
        burden = prepared.preprocessing.objective_offset +
                 exact_tagged_cover_burden(reduced, selected)
        if isnothing(best_burden) || burden < best_burden
            best_burden = burden
            empty!(best_reduced)
            push!(best_reduced, selected)
        elseif burden == best_burden
            if retain_all_ties
                push!(best_reduced, selected)
                length(best_reduced) <= maximum_ties || throw(
                    ArgumentError(
                        "complete enumeration exceeded maximum_ties=$maximum_ties",
                    ),
                )
            elseif _journal_selection_isless(selected, first(best_reduced))
                best_reduced[1] = selected
            end
        end
    end
    isnothing(best_burden) && throw(
        ArgumentError("the residual tagged-cover instance is infeasible"),
    )
    search_ns = time_ns() - search_start
    reconstruction_start = time_ns()
    original_selections = _journal_reconstruct_reduced_optima(
        prepared,
        _journal_sort_unique_selections(best_reduced),
        retain_all_ties,
        maximum_ties,
    )
    counters = JournalExactSolveCounters(
        BigInt(candidate_count),
        BigInt(0),
        BigInt(candidate_count),
        BigInt(0),
    )
    return _journal_exact_result(
        instance,
        :complete_enumeration,
        best_burden,
        original_selections,
        retain_all_ties,
        preprocessing,
        counters,
        preprocessing_ns,
        search_ns,
        reconstruction_start,
        total_start,
    )
end


function _journal_requirement_masks(model::ExactTaggedCoverModel)
    masks = BigInt[]
    for column in axes(model.coverage, 2)
        mask = BigInt(0)
        for row in axes(model.coverage, 1)
            model.coverage[row, column] || continue
            mask |= BigInt(1) << (row - 1)
        end
        push!(masks, mask)
    end
    full_mask = isempty(model.requirements) ?
                BigInt(0) : (BigInt(1) << length(model.requirements)) - 1
    return masks, full_mask
end


function _journal_relax_dp_state!(
    costs::Dict{BigInt,ExactRational},
    parents::Dict{BigInt,Vector{_JournalDPParent}},
    mask::BigInt,
    burden::ExactRational,
    parent::_JournalDPParent,
    retain_all_ties::Bool,
)
    if !haskey(costs, mask) || burden < costs[mask]
        costs[mask] = burden
        parents[mask] = _JournalDPParent[parent]
        return nothing
    end
    burden == costs[mask] || return nothing
    if retain_all_ties
        push!(parents[mask], parent)
    end
    return nothing
end


function _journal_reconstruct_dp_selections(
    parent_layers::Vector{Dict{BigInt,Vector{_JournalDPParent}}},
    full_mask::BigInt,
    strategy_count::Int,
    retain_all_ties::Bool,
    maximum_ties::Integer,
)
    partial = Tuple{BigInt,BitVector}[(full_mask, falses(strategy_count))]
    for strategy_index in strategy_count:-1:1
        expanded = Tuple{BigInt,BitVector}[]
        parents = parent_layers[strategy_index]
        for (mask, selected) in partial
            haskey(parents, mask) || throw(
                ArgumentError("a dynamic-programming reconstruction parent is missing"),
            )
            choices = retain_all_ties ? parents[mask] : parents[mask][1:1]
            for parent in choices
                candidate = copy(selected)
                candidate[strategy_index] = parent.selected_strategy
                push!(expanded, (parent.predecessor_mask, candidate))
                length(expanded) <= maximum_ties || throw(
                    ArgumentError(
                        "dynamic-programming tie reconstruction exceeded " *
                        "maximum_ties=$maximum_ties",
                    ),
                )
            end
        end
        partial = expanded
    end
    all(iszero(mask) for (mask, _) in partial) || throw(
        ArgumentError("a dynamic-programming reconstruction did not reach the base state"),
    )
    return _journal_sort_unique_selections(
        BitVector[selected for (_, selected) in partial],
    )
end


"""
    solve_journal_compression_dp(instance; ...)

Solve the mandatory-preprocessed tagged cover exactly by dynamic programming
over reachable requirement masks. The implementation stores exact rational
costs and optimal predecessor records and iterates masks deterministically.
"""
function solve_journal_compression_dp(
    instance::JournalCompressionInstance;
    retain_all_ties::Bool = instance.tie_handling.mode == :complete,
    maximum_ties::Integer = 100_000,
)
    _journal_validate_exact_solve_options(instance, retain_all_ties, maximum_ties)
    total_start = time_ns()
    preprocessing_start = time_ns()
    prepared, reduced, preprocessing =
        _journal_prepare_exact_solve(instance, retain_all_ties)
    preprocessing_ns = time_ns() - preprocessing_start

    search_start = time_ns()
    masks, full_mask = _journal_requirement_masks(reduced)
    strategy_count = length(reduced.strategy_ids)
    current = Dict{BigInt,ExactRational}(
        BigInt(0) => zero(ExactRational),
    )
    parent_layers = Vector{Dict{BigInt,Vector{_JournalDPParent}}}()
    state_visits = BigInt(0)
    transitions = BigInt(0)
    for strategy_index in 1:strategy_count
        next = Dict{BigInt,ExactRational}()
        next_parents = Dict{BigInt,Vector{_JournalDPParent}}()
        for reached_mask in sort!(collect(keys(current)))
            state_visits += 1
            burden = current[reached_mask]
            transitions += 1
            _journal_relax_dp_state!(
                next,
                next_parents,
                reached_mask,
                burden,
                _JournalDPParent(reached_mask, false),
                retain_all_ties,
            )

            transitions += 1
            _journal_relax_dp_state!(
                next,
                next_parents,
                reached_mask | masks[strategy_index],
                burden + reduced.weights[strategy_index],
                _JournalDPParent(reached_mask, true),
                retain_all_ties,
            )
        end
        current = next
        push!(parent_layers, next_parents)
    end
    haskey(current, full_mask) || throw(
        ArgumentError("the residual tagged-cover instance is infeasible"),
    )
    final_burden = current[full_mask]
    search_ns = time_ns() - search_start
    reconstruction_start = time_ns()
    reduced_selections = _journal_reconstruct_dp_selections(
        parent_layers,
        full_mask,
        strategy_count,
        retain_all_ties,
        maximum_ties,
    )
    original_selections = _journal_reconstruct_reduced_optima(
        prepared,
        reduced_selections,
        retain_all_ties,
        maximum_ties,
    )
    exact_burden = prepared.preprocessing.objective_offset + final_burden
    counters = JournalExactSolveCounters(
        state_visits,
        transitions,
        BigInt(0),
        BigInt(length(current)),
    )
    return _journal_exact_result(
        instance,
        :requirement_mask_dp,
        exact_burden,
        original_selections,
        retain_all_ties,
        preprocessing,
        counters,
        preprocessing_ns,
        search_ns,
        reconstruction_start,
        total_start,
    )
end


function _journal_solution_identifier_arrays(result::JournalExactSolutionResult)
    kinds = String[]
    values = String[]
    for original_index in findall(result.selected)
        kind, value = _journal_identifier_parts(result.strategy_ids[original_index].id)
        push!(kinds, kind)
        push!(values, value)
    end
    return kinds, values
end


"""Return the standard machine-readable exact-solution certificate payload."""
function journal_exact_solution_certificate(result::JournalExactSolutionResult)
    _validate_journal_exact_solution_result(result)
    selected_kinds, selected_values =
        _journal_solution_identifier_arrays(result)
    selection_rows = Dict{String,Any}[]
    for (index, selection) in enumerate(result.optimal_selections)
        certificate = result.certificates[index]
        push!(
            selection_rows,
            Dict{String,Any}(
                "selection_index" => index,
                "selected_strategy_indices" => certificate.selected_strategy_indices,
                "exact_burden" => encode_exact_rational(certificate.exact_burden),
                "mandatory_retained" => certificate.mandatory_retained,
                "tagged_coverage" => certificate.tagged_coverage,
                "frontier_preserved" => certificate.frontier_preserved,
                "closure_preserved" => certificate.closure_preserved,
                "burden_reconciled" => certificate.burden_reconciled,
            ),
        )
    end
    return Dict{String,Any}(
        "schema_version" => result.schema_version,
        "algorithm" => string(result.algorithm),
        "status" => string(result.status),
        "evidence_class" => "exact finite computation",
        "arithmetic" => "Rational{BigInt}",
        "instance_sha256" => result.instance_sha256,
        "search_complete" => true,
        "solver_status_used" => false,
        "exact_burden" => encode_exact_rational(result.exact_burden),
        "selected_strategy_indices" => findall(result.selected),
        "selected_strategy_id_kinds" => selected_kinds,
        "selected_strategy_id_values" => selected_values,
        "ties_complete" => result.ties_complete,
        "tie_declaration" => result.tie_declaration,
        "optimal_selection_count_returned" => length(result.optimal_selections),
        "optimal_selections" => selection_rows,
        "preprocessing" => Dict{String,Any}(
            "original_strategy_count" =>
                result.preprocessing.original_strategy_count,
            "reduced_strategy_count" =>
                result.preprocessing.reduced_strategy_count,
            "original_requirement_count" =>
                result.preprocessing.original_requirement_count,
            "reduced_requirement_count" =>
                result.preprocessing.reduced_requirement_count,
            "forced_strategy_indices" =>
                result.preprocessing.forced_strategy_indices,
            "exact_objective_offset" => encode_exact_rational(
                result.preprocessing.exact_objective_offset,
            ),
            "input_preprocessing_reused" =>
                result.preprocessing.input_preprocessing_reused,
            "all_optimizer_identities_reconstructable" =>
                result.preprocessing.all_optimizer_identities_reconstructable,
        ),
        "counters" => Dict{String,Any}(
            "integer_encoding" => "decimal BigInt string",
            "state_layer_pairs_visited" =>
                string(result.counters.state_layer_pairs_visited),
            "transitions_evaluated" =>
                string(result.counters.transitions_evaluated),
            "candidate_selections_evaluated" =>
                string(result.counters.candidate_selections_evaluated),
            "final_reachable_states" =>
                string(result.counters.final_reachable_states),
        ),
        "runtime_ns" => Dict{String,Any}(
            "evidence_class" => "single-run wall-clock measurement",
            "preprocessing" => Int(result.runtime.preprocessing_ns),
            "search" => Int(result.runtime.search_ns),
            "reconstruction_and_certification" =>
                Int(result.runtime.reconstruction_and_certification_ns),
            "total" => Int(result.runtime.total_ns),
        ),
    )
end


"""Serialize an exact-solution certificate as sorted TOML."""
function serialize_journal_exact_solution(result::JournalExactSolutionResult)
    io = IOBuffer()
    TOML.print(io, journal_exact_solution_certificate(result); sorted = true)
    return String(take!(io))
end


function write_journal_exact_solution_certificate(
    io::IO,
    result::JournalExactSolutionResult,
)
    write(io, serialize_journal_exact_solution(result))
    return nothing
end
