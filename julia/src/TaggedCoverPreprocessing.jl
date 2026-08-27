"""
    ExactTaggedCoverModel

Solver-neutral exact weighted covering model used by tagged-cover
preprocessing. `mandatory[column]` fixes that strategy to one. Nonmandatory
weights must be strictly positive; mandatory weights may be zero.
"""
struct ExactTaggedCoverModel
    requirements::Tuple
    strategy_ids::Tuple
    coverage::BitMatrix
    weights::Vector{ExactRational}
    mandatory::BitVector
end


function ExactTaggedCoverModel(
    requirements,
    strategy_ids,
    coverage::AbstractMatrix{Bool},
    weights,
    mandatory::AbstractVector{Bool},
)
    requirement_tuple = Tuple(requirements)
    strategy_tuple = Tuple(strategy_ids)
    row_count = length(requirement_tuple)
    column_count = length(strategy_tuple)
    size(coverage) == (row_count, column_count) || throw(
        DimensionMismatch("coverage dimensions do not match requirements and strategies"),
    )
    length(weights) == column_count ||
        throw(DimensionMismatch("one exact weight is required per strategy"))
    length(mandatory) == column_count ||
        throw(DimensionMismatch("one mandatory flag is required per strategy"))
    length(Set(strategy_tuple)) == column_count ||
        throw(ArgumentError("tagged-cover strategy identifiers must be unique"))

    exact_weights = ExactRational[exact_rational(weight) for weight in weights]
    mandatory_bits = BitVector(mandatory)
    for column in 1:column_count
        if mandatory_bits[column]
            exact_weights[column] >= 0 || throw(
                ArgumentError("mandatory strategy weights must be nonnegative"),
            )
        else
            exact_weights[column] > 0 || throw(
                ArgumentError("nonmandatory strategy weights must be strictly positive"),
            )
        end
    end
    return ExactTaggedCoverModel(
        requirement_tuple,
        strategy_tuple,
        BitMatrix(coverage),
        exact_weights,
        mandatory_bits,
    )
end


"""Convert an identity-closure representation to its exact preprocessing model."""
function exact_tagged_cover_model(
    representation::TaggedCoverRepresentation,
)
    mandatory = falses(length(representation.strategy_ids))
    mandatory[representation.inactive_index] = true
    return ExactTaggedCoverModel(
        representation.requirements,
        representation.strategy_ids,
        representation.coverage,
        representation.weights,
        mandatory,
    )
end


function _validate_exact_tagged_selection(
    model::ExactTaggedCoverModel,
    selected::AbstractVector{Bool},
)
    length(selected) == length(model.strategy_ids) || throw(
        DimensionMismatch("the tagged-cover selection has the wrong length"),
    )
    return selected
end


"""Test feasibility of a binary selection in an exact tagged covering model."""
function exact_tagged_cover_feasible(
    model::ExactTaggedCoverModel,
    selected::AbstractVector{Bool},
)
    _validate_exact_tagged_selection(model, selected)
    all(!model.mandatory[column] || selected[column] for column in eachindex(selected)) ||
        return false
    return all(
        any(
            selected[column] && model.coverage[row, column] for
            column in eachindex(selected)
        ) for row in axes(model.coverage, 1)
    )
end


"""Return the exact objective of a tagged-cover model selection."""
function exact_tagged_cover_burden(
    model::ExactTaggedCoverModel,
    selected::AbstractVector{Bool},
)
    _validate_exact_tagged_selection(model, selected)
    return sum(
        (
            model.weights[column] for column in eachindex(selected) if
            selected[column]
        );
        init = zero(ExactRational),
    )
end


"""
    TaggedCoverPreprocessingResult

Deterministic fixed-point reduction of an `ExactTaggedCoverModel`. Indices in
the mapping fields always refer to the original model. Equal-coverage
reconstruction choices contain only exact equal-weight substitutions.
"""
struct TaggedCoverPreprocessingResult
    original::ExactTaggedCoverModel
    reduced::ExactTaggedCoverModel
    remaining_requirement_indices::Vector{Int}
    remaining_strategy_indices::Vector{Int}
    forced_strategy_indices::Vector{Int}
    objective_offset::ExactRational
    equal_coverage_choices::Dict{Int,Vector{Int}}
    strategy_status::Vector{Symbol}
    strategy_elimination_target::Vector{Int}
    requirement_status::Vector{Symbol}
    requirement_representative::Vector{Int}
    feasible::Bool
    all_optimizer_identities_reconstructable::Bool
    audit::Dict{String,Any}
end


const _TAGGED_PREPROCESSING_RULES = (
    :mandatory_strategy,
    :mandatory_strategy_propagation,
    :redundant_requirement,
    :mandatory_requirement_carrier,
    :forced_selection_propagation,
    :empty_contribution,
    :duplicate_coverage,
    :coverage_dominance,
    :infeasible_requirement,
)

_tagged_label(value) = sprint(show, value)


function _rule_counts()
    return Dict{String,Any}(
        string(rule) => Dict{String,Any}(
            "applications" => 0,
            "variables_removed" => 0,
            "requirements_removed" => 0,
        ) for rule in _TAGGED_PREPROCESSING_RULES
    )
end


function _record_preprocessing_event!(
    trace::Vector{Dict{String,Any}},
    counts::Dict{String,Any},
    model::ExactTaggedCoverModel,
    iteration::Int,
    rule::Symbol;
    removed_columns = Int[],
    removed_rows = Int[],
    details = Dict{String,Any}(),
)
    rule_key = string(rule)
    row = Dict{String,Any}(
        "event_index" => length(trace) + 1,
        "iteration" => iteration,
        "rule" => rule_key,
        "removed_strategy_indices" => copy(removed_columns),
        "removed_strategy_ids" => [
            _tagged_label(model.strategy_ids[column]) for column in removed_columns
        ],
        "removed_requirement_indices" => copy(removed_rows),
        "removed_requirements" => [
            _tagged_label(model.requirements[requirement]) for
            requirement in removed_rows
        ],
        "details" => details,
    )
    push!(trace, row)
    counts[rule_key]["applications"] += 1
    counts[rule_key]["variables_removed"] += length(removed_columns)
    counts[rule_key]["requirements_removed"] += length(removed_rows)
    return row
end


_column_signature(model, rows, column) =
    Tuple(model.coverage[row, column] for row in rows)
_row_signature(model, row, columns) =
    Tuple(model.coverage[row, column] for column in columns)


function _first_duplicate_group(values, signature)
    groups = Dict{Any,Vector{Int}}()
    order = Any[]
    for value in values
        key = signature(value)
        if !haskey(groups, key)
            groups[key] = Int[]
            push!(order, key)
        end
        push!(groups[key], value)
    end
    for key in order
        length(groups[key]) > 1 && return groups[key]
    end
    return Int[]
end


function _strict_coverage_subset(model, rows, left::Int, right::Int)
    subset = all(
        !model.coverage[row, left] || model.coverage[row, right] for row in rows
    )
    strict = any(
        model.coverage[row, right] && !model.coverage[row, left] for row in rows
    )
    return subset && strict
end


"""
    preprocess_tagged_cover(model)

Apply exact preprocessing to a fixed point. The stable rule order is:
mandatory initialization, redundant rows, unique residual carriers and
propagation, empty columns, duplicate columns, then strict coverage dominance.
After every change the scan restarts, so forced selections and dominance are
recomputed on the current residual model.
"""
function preprocess_tagged_cover(model::ExactTaggedCoverModel)
    row_count = length(model.requirements)
    column_count = length(model.strategy_ids)
    rows = collect(1:row_count)
    columns = collect(1:column_count)
    forced = Int[]
    objective_offset = zero(ExactRational)
    tie_choices = Dict{Int,Vector{Int}}(
        column => [column] for column in 1:column_count
    )
    strategy_status = fill(:remaining, column_count)
    strategy_target = zeros(Int, column_count)
    requirement_status = fill(:remaining, row_count)
    requirement_representative = collect(1:row_count)
    trace = Vector{Dict{String,Any}}()
    counts = _rule_counts()
    all_identities_reconstructable = true

    mandatory_columns = Int[
        column for column in columns if model.mandatory[column]
    ]
    if !isempty(mandatory_columns)
        append!(forced, mandatory_columns)
        objective_offset += sum(
            (model.weights[column] for column in mandatory_columns);
            init = zero(ExactRational),
        )
        for column in mandatory_columns
            strategy_status[column] = :mandatory_selected
        end
        columns = Int[
            column for column in columns if column ∉ mandatory_columns
        ]
        _record_preprocessing_event!(
            trace,
            counts,
            model,
            0,
            :mandatory_strategy;
            removed_columns = mandatory_columns,
            details = Dict("action" => "fixed_to_one"),
        )
        satisfied_rows = Int[
            row for row in rows if
            any(model.coverage[row, column] for column in mandatory_columns)
        ]
        if !isempty(satisfied_rows)
            for row in satisfied_rows
                requirement_status[row] = :satisfied_by_mandatory
                requirement_representative[row] = 0
            end
            rows = Int[row for row in rows if row ∉ satisfied_rows]
            _record_preprocessing_event!(
                trace,
                counts,
                model,
                0,
                :mandatory_strategy_propagation;
                removed_rows = satisfied_rows,
            )
        end
    end

    feasible = true
    fixed_point = false
    iteration = 0
    while feasible && !fixed_point
        iteration += 1

        duplicate_rows = _first_duplicate_group(
            rows,
            row -> _row_signature(model, row, columns),
        )
        if !isempty(duplicate_rows)
            representative = first(duplicate_rows)
            removed = duplicate_rows[2:end]
            for row in removed
                requirement_status[row] = :duplicate_requirement
                requirement_representative[row] = representative
            end
            rows = Int[row for row in rows if row ∉ removed]
            _record_preprocessing_event!(
                trace,
                counts,
                model,
                iteration,
                :redundant_requirement;
                removed_rows = removed,
                details = Dict(
                    "representative_requirement_index" => representative,
                    "representative_requirement" =>
                        _tagged_label(model.requirements[representative]),
                ),
            )
            continue
        end

        infeasible_position = findfirst(
            row -> !any(model.coverage[row, column] for column in columns),
            rows,
        )
        if !isnothing(infeasible_position)
            row = rows[infeasible_position]
            requirement_status[row] = :infeasible_no_carrier
            feasible = false
            _record_preprocessing_event!(
                trace,
                counts,
                model,
                iteration,
                :infeasible_requirement;
                details = Dict(
                    "requirement_index" => row,
                    "requirement" => _tagged_label(model.requirements[row]),
                ),
            )
            break
        end

        forced_row = 0
        forced_column = 0
        for row in rows
            carriers = Int[
                column for column in columns if model.coverage[row, column]
            ]
            if length(carriers) == 1
                forced_row = row
                forced_column = only(carriers)
                break
            end
        end
        if !iszero(forced_column)
            push!(forced, forced_column)
            objective_offset += model.weights[forced_column]
            strategy_status[forced_column] = :forced_selected
            columns = Int[column for column in columns if column != forced_column]
            _record_preprocessing_event!(
                trace,
                counts,
                model,
                iteration,
                :mandatory_requirement_carrier;
                removed_columns = [forced_column],
                details = Dict(
                    "triggering_requirement_index" => forced_row,
                    "triggering_requirement" =>
                        _tagged_label(model.requirements[forced_row]),
                    "equal_coverage_choice_indices" =>
                        copy(tie_choices[forced_column]),
                ),
            )
            satisfied_rows = Int[
                row for row in rows if model.coverage[row, forced_column]
            ]
            for row in satisfied_rows
                requirement_status[row] = :satisfied_by_forced_selection
                requirement_representative[row] = 0
            end
            rows = Int[row for row in rows if row ∉ satisfied_rows]
            _record_preprocessing_event!(
                trace,
                counts,
                model,
                iteration,
                :forced_selection_propagation;
                removed_rows = satisfied_rows,
                details = Dict("forced_strategy_index" => forced_column),
            )
            continue
        end

        empty_position = findfirst(
            column -> !any(model.coverage[row, column] for row in rows),
            columns,
        )
        if !isnothing(empty_position)
            column = columns[empty_position]
            strategy_status[column] = :empty_contribution
            columns = Int[candidate for candidate in columns if candidate != column]
            delete!(tie_choices, column)
            _record_preprocessing_event!(
                trace,
                counts,
                model,
                iteration,
                :empty_contribution;
                removed_columns = [column],
            )
            continue
        end

        duplicate_columns = _first_duplicate_group(
            columns,
            column -> _column_signature(model, rows, column),
        )
        if !isempty(duplicate_columns)
            minimum_weight = minimum(model.weights[column] for column in duplicate_columns)
            minimum_columns = Int[
                column for column in duplicate_columns if
                model.weights[column] == minimum_weight
            ]
            representative = minimum(minimum_columns)
            removed = Int[
                column for column in duplicate_columns if column != representative
            ]
            equal_ties = Int[]
            heavier = Int[]
            for column in removed
                strategy_target[column] = representative
                if model.weights[column] == minimum_weight
                    append!(equal_ties, tie_choices[column])
                    append!(tie_choices[representative], tie_choices[column])
                    sort!(unique!(tie_choices[representative]))
                    strategy_status[column] = :duplicate_equal_weight
                else
                    append!(heavier, tie_choices[column])
                    strategy_status[column] = :duplicate_heavier
                end
                delete!(tie_choices, column)
            end
            columns = Int[column for column in columns if column ∉ removed]
            _record_preprocessing_event!(
                trace,
                counts,
                model,
                iteration,
                :duplicate_coverage;
                removed_columns = removed,
                details = Dict(
                    "representative_strategy_index" => representative,
                    "representative_strategy" =>
                        _tagged_label(model.strategy_ids[representative]),
                    "equal_weight_tie_indices" => sort!(unique!(equal_ties)),
                    "strictly_heavier_indices" => sort!(unique!(heavier)),
                ),
            )
            continue
        end

        dominated_column = 0
        dominating_column = 0
        for candidate in columns
            dominators = Int[
                comparison for comparison in columns if
                comparison != candidate &&
                model.weights[comparison] <= model.weights[candidate] &&
                _strict_coverage_subset(model, rows, candidate, comparison)
            ]
            isempty(dominators) && continue
            sort!(
                dominators;
                by = comparison -> (
                    model.weights[comparison],
                    -count(model.coverage[row, comparison] for row in rows),
                    comparison,
                ),
            )
            dominated_column = candidate
            dominating_column = first(dominators)
            break
        end
        if !iszero(dominated_column)
            equal_weight = model.weights[dominating_column] ==
                           model.weights[dominated_column]
            strategy_status[dominated_column] = equal_weight ?
                :dominated_equal_weight : :dominated_strict_weight
            strategy_target[dominated_column] = dominating_column
            lost_identity_indices = copy(tie_choices[dominated_column])
            delete!(tie_choices, dominated_column)
            columns = Int[
                column for column in columns if column != dominated_column
            ]
            all_identities_reconstructable &= !equal_weight
            _record_preprocessing_event!(
                trace,
                counts,
                model,
                iteration,
                :coverage_dominance;
                removed_columns = [dominated_column],
                details = Dict(
                    "dominating_strategy_index" => dominating_column,
                    "dominating_strategy" =>
                        _tagged_label(model.strategy_ids[dominating_column]),
                    "weight_relation" => equal_weight ? "equal" : "strictly_lower",
                    "all_optimizer_identities_preserved" => !equal_weight,
                    "unreconstructable_equal_weight_identity_indices" =>
                        equal_weight ? lost_identity_indices : Int[],
                ),
            )
            continue
        end

        fixed_point = true
    end

    reduced_coverage = BitMatrix(model.coverage[rows, columns])
    reduced = ExactTaggedCoverModel(
        [model.requirements[row] for row in rows],
        [model.strategy_ids[column] for column in columns],
        reduced_coverage,
        [model.weights[column] for column in columns],
        falses(length(columns)),
    )
    tie_map = Dict{Int,Vector{Int}}(
        representative => copy(choices) for
        (representative, choices) in sort!(collect(tie_choices); by = first) if
        length(choices) > 1
    )
    audit = Dict{String,Any}(
        "schema_version" => "tagged-cover-preprocessing-audit-v1",
        "arithmetic" => "Rational{BigInt}",
        "fixed_point" => fixed_point,
        "fixed_point_iterations" => iteration,
        "feasible" => feasible,
        "objective_offset" => objective_offset,
        "original_variable_count" => column_count,
        "reduced_variable_count" => length(columns),
        "original_requirement_count" => row_count,
        "reduced_requirement_count" => length(rows),
        "forced_strategy_indices" => copy(forced),
        "forced_strategy_ids" => [
            _tagged_label(model.strategy_ids[column]) for column in forced
        ],
        "remaining_strategy_indices" => copy(columns),
        "remaining_requirement_indices" => copy(rows),
        "strategy_status" => string.(strategy_status),
        "strategy_elimination_target" => copy(strategy_target),
        "requirement_status" => string.(requirement_status),
        "requirement_representative" => copy(requirement_representative),
        "equal_coverage_reconstruction_map" => Dict(
            string(representative) => copy(choices) for
            (representative, choices) in tie_map
        ),
        "all_optimizer_identities_reconstructable_by_declared_maps" =>
            all_identities_reconstructable,
        "rule_counts" => counts,
        "events" => trace,
    )
    return TaggedCoverPreprocessingResult(
        model,
        reduced,
        rows,
        columns,
        forced,
        objective_offset,
        tie_map,
        strategy_status,
        strategy_target,
        requirement_status,
        requirement_representative,
        feasible,
        all_identities_reconstructable,
        audit,
    )
end


preprocess_tagged_cover(representation::TaggedCoverRepresentation) =
    preprocess_tagged_cover(exact_tagged_cover_model(representation))


"""Test a selection in the residual preprocessed model."""
function preprocessed_tagged_cover_feasible(
    result::TaggedCoverPreprocessingResult,
    selected::AbstractVector{Bool},
)
    result.feasible || return false
    return exact_tagged_cover_feasible(result.reduced, selected)
end


"""Return objective offset plus exact residual burden."""
function preprocessed_tagged_cover_burden(
    result::TaggedCoverPreprocessingResult,
    selected::AbstractVector{Bool},
)
    return result.objective_offset +
           exact_tagged_cover_burden(result.reduced, selected)
end


"""
    lift_preprocessed_tagged_selection(result, selected)

Lift one residual selection to the original column order using the stable
representative for every equal-coverage tie group.
"""
function lift_preprocessed_tagged_selection(
    result::TaggedCoverPreprocessingResult,
    selected::AbstractVector{Bool},
)
    _validate_exact_tagged_selection(result.reduced, selected)
    lifted = falses(length(result.original.strategy_ids))
    lifted[result.forced_strategy_indices] .= true
    for (reduced_column, original_column) in
        enumerate(result.remaining_strategy_indices)
        selected[reduced_column] || continue
        lifted[original_column] = true
    end
    return lifted
end


"""
    reconstruct_equal_coverage_ties(result, selected)

Return every exact equal-weight duplicate substitution of the canonical lift.
This reconstructs duplicate-coverage identities only. It deliberately does
not claim to recover identities lost by equal-weight strict dominance.
"""
function reconstruct_equal_coverage_ties(
    result::TaggedCoverPreprocessingResult,
    selected::AbstractVector{Bool},
)
    canonical = lift_preprocessed_tagged_selection(result, selected)
    selected_representatives = Int[
        representative for
        representative in sort!(collect(keys(result.equal_coverage_choices))) if
        canonical[representative]
    ]
    reconstructions = BitVector[BitVector(canonical)]
    for representative in selected_representatives
        choices = result.equal_coverage_choices[representative]
        expanded = BitVector[]
        for reconstruction in reconstructions, choice in choices
            candidate = copy(reconstruction)
            candidate[representative] = false
            candidate[choice] = true
            push!(expanded, candidate)
        end
        reconstructions = expanded
    end
    sort!(reconstructions; by = selection -> findall(selection))
    return reconstructions
end
