const JOURNAL_COMPRESSION_INSTANCE_SCHEMA_VERSION =
    "journal-compression-instance-v1"

const _JOURNAL_INSTANCE_KINDS = (
    :synthetic,
    :adversarial,
    :canonical,
    :financial,
)

const _JOURNAL_TIE_MODES = (
    :complete,
    :declared_representative,
)

const _JOURNAL_INTEGER_IDENTIFIER_TYPES = Dict{String,Type}(
    "Int8" => Int8,
    "Int16" => Int16,
    "Int32" => Int32,
    "Int64" => Int64,
    "Int128" => Int128,
    "UInt8" => UInt8,
    "UInt16" => UInt16,
    "UInt32" => UInt32,
    "UInt64" => UInt64,
    "UInt128" => UInt128,
    "BigInt" => BigInt,
)


function _journal_string_pairs(values, label::AbstractString)
    collected = Pair{String,String}[]
    iterator = values isa NamedTuple ? Base.pairs(values) : values
    for entry in iterator
        entry isa Pair || throw(
            ArgumentError("$label must contain key-value pairs"),
        )
        push!(collected, String(first(entry)) => String(last(entry)))
    end
    sort!(collected; by = first)
    _require_unique(first.(collected), "$label keys")
    return Tuple(collected)
end


"""Stable provenance carried by every journal compression instance."""
struct JournalCompressionProvenance
    instance_kind::Symbol
    instance_id::String
    source::String
    generator::Union{Nothing,String}
    parent_hashes::Tuple{Vararg{Pair{String,String}}}
    attributes::Tuple{Vararg{Pair{String,String}}}
    redistributable::Bool
end


function JournalCompressionProvenance(
    instance_kind::Symbol,
    instance_id::AbstractString,
    source::AbstractString;
    generator = nothing,
    parent_hashes = Pair{String,String}[],
    attributes = Pair{String,String}[],
    redistributable::Bool = true,
)
    instance_kind in _JOURNAL_INSTANCE_KINDS || throw(
        ArgumentError(
            "instance_kind must be synthetic, adversarial, canonical, or financial",
        ),
    )
    id = String(instance_id)
    source_text = String(source)
    isempty(strip(id)) && throw(ArgumentError("instance_id cannot be empty"))
    isempty(strip(source_text)) && throw(ArgumentError("source cannot be empty"))
    generator_text = isnothing(generator) ? nothing : String(generator)
    if !isnothing(generator_text) && isempty(strip(generator_text))
        throw(ArgumentError("generator cannot be an empty string"))
    end
    hashes = _journal_string_pairs(parent_hashes, "parent hashes")
    for entry in hashes
        occursin(r"^[0-9a-f]{64}$", last(entry)) || throw(
            ArgumentError("parent artifact hashes must be lowercase SHA-256"),
        )
    end
    return JournalCompressionProvenance(
        instance_kind,
        id,
        source_text,
        generator_text,
        hashes,
        _journal_string_pairs(attributes, "provenance attributes"),
        redistributable,
    )
end


Base.:(==)(left::JournalCompressionProvenance, right::JournalCompressionProvenance) =
    left.instance_kind == right.instance_kind &&
    left.instance_id == right.instance_id &&
    left.source == right.source &&
    left.generator == right.generator &&
    left.parent_hashes == right.parent_hashes &&
    left.attributes == right.attributes &&
    left.redistributable == right.redistributable


"""Declare whether an algorithm returns all optima or one stable representative."""
struct JournalTieHandling
    mode::Symbol
    declaration::String
    stable_selector::String
end


function JournalTieHandling(
    mode::Symbol;
    declaration::AbstractString,
    stable_selector::AbstractString,
)
    mode in _JOURNAL_TIE_MODES || throw(
        ArgumentError("tie mode must be complete or declared_representative"),
    )
    declaration_text = String(declaration)
    selector_text = String(stable_selector)
    isempty(strip(declaration_text)) && throw(
        ArgumentError("tie handling requires a nonempty declaration"),
    )
    isempty(strip(selector_text)) && throw(
        ArgumentError("tie handling requires a stable selector description"),
    )
    return JournalTieHandling(mode, declaration_text, selector_text)
end


function default_journal_tie_handling()
    return JournalTieHandling(
        :declared_representative;
        declaration = "one deterministic representative; tied optima are not claimed complete",
        stable_selector = "lexicographic binary selection in canonical strategy order",
    )
end


Base.:(==)(left::JournalTieHandling, right::JournalTieHandling) =
    left.mode == right.mode &&
    left.declaration == right.declaration &&
    left.stable_selector == right.stable_selector


"""Map a preprocessed residual cover back to original schema indices."""
struct JournalPreprocessingMap
    applied::Bool
    remaining_requirement_indices::Vector{Int}
    remaining_strategy_indices::Vector{Int}
    forced_strategy_indices::Vector{Int}
    objective_offset::ExactRational
    equal_coverage_choices::Tuple{Vararg{Pair{Int,Tuple{Vararg{Int}}}}}
    all_optimizer_identities_reconstructable::Bool
end


function JournalPreprocessingMap(
    applied::Bool,
    remaining_requirement_indices,
    remaining_strategy_indices,
    forced_strategy_indices,
    objective_offset,
    equal_coverage_choices;
    all_optimizer_identities_reconstructable::Bool = true,
)
    groups = Pair{Int,Tuple{Vararg{Int}}}[]
    iterator = equal_coverage_choices isa AbstractDict ?
               collect(equal_coverage_choices) : equal_coverage_choices
    for entry in iterator
        entry isa Pair || throw(
            ArgumentError("equal-coverage choices must contain index pairs"),
        )
        push!(groups, Int(first(entry)) => Tuple(Int.(collect(last(entry)))))
    end
    sort!(groups; by = first)
    return JournalPreprocessingMap(
        applied,
        Int.(collect(remaining_requirement_indices)),
        Int.(collect(remaining_strategy_indices)),
        Int.(collect(forced_strategy_indices)),
        exact_rational(objective_offset),
        Tuple(groups),
        all_optimizer_identities_reconstructable,
    )
end


function identity_journal_preprocessing_map(
    requirement_count::Integer,
    strategy_count::Integer,
)
    return JournalPreprocessingMap(
        false,
        collect(1:Int(requirement_count)),
        collect(1:Int(strategy_count)),
        Int[],
        0,
        Pair{Int,Tuple{Vararg{Int}}}[],
    )
end


Base.:(==)(left::JournalPreprocessingMap, right::JournalPreprocessingMap) =
    left.applied == right.applied &&
    left.remaining_requirement_indices == right.remaining_requirement_indices &&
    left.remaining_strategy_indices == right.remaining_strategy_indices &&
    left.forced_strategy_indices == right.forced_strategy_indices &&
    left.objective_offset == right.objective_offset &&
    left.equal_coverage_choices == right.equal_coverage_choices &&
    left.all_optimizer_identities_reconstructable ==
    right.all_optimizer_identities_reconstructable


function _journal_identifier_parts(value)
    if value isa Symbol
        return ("symbol", String(value))
    elseif value isa AbstractString
        return ("string", String(value))
    elseif value isa Integer && !(value isa Bool)
        type_name = string(nameof(typeof(value)))
        haskey(_JOURNAL_INTEGER_IDENTIFIER_TYPES, type_name) || throw(
            ArgumentError("unsupported integer identifier type: $(typeof(value))"),
        )
        return ("integer-$type_name", string(value))
    end
    throw(
        ArgumentError(
            "journal schema identifiers must be symbols, strings, or integers; " *
            "received $(typeof(value))",
        ),
    )
end


function _journal_decode_identifier(kind::AbstractString, value::AbstractString)
    kind == "symbol" && return Symbol(value)
    kind == "string" && return String(value)
    if startswith(kind, "integer-")
        type_name = chop(kind; head = length("integer-"), tail = 0)
        haskey(_JOURNAL_INTEGER_IDENTIFIER_TYPES, type_name) || throw(
            ArgumentError("unsupported serialized integer identifier type: $type_name"),
        )
        return parse(_JOURNAL_INTEGER_IDENTIFIER_TYPES[type_name], value)
    end
    throw(ArgumentError("unsupported journal identifier kind: $kind"))
end


_journal_identifier_key(value) = _journal_identifier_parts(value)
_journal_strategy_key(value::StrategyId) = _journal_identifier_key(value.id)
_journal_belief_key(value::Belief) = _journal_identifier_key(value.id)
_journal_module_key(value::ModuleId) = _journal_identifier_key(value.id)


function _journal_requirement_key(requirement::TaggedRequirement)
    if requirement isa FrontierRequirement
        return (0, _journal_belief_key(requirement.belief)...)
    elseif requirement isa ModuleRequirement
        return (1, _journal_module_key(requirement.module_id)...)
    end
    throw(ArgumentError("unsupported tagged requirement subtype"))
end


function _journal_is_strictly_sorted(values, key)
    keys = [key(value) for value in values]
    return length(Set(keys)) == length(keys) && issorted(keys)
end


"""
    JournalCompressionInstance

Canonical exact identity-closure input shared by journal algorithms. Strategy
columns and tagged requirement rows use stable identifier order. Independent
profiles and raw module memberships permit semantic checks beyond incidence.
"""
struct JournalCompressionInstance
    schema_version::String
    strategy_ids::Tuple{Vararg{StrategyId}}
    mandatory::BitVector
    weights::Vector{ExactRational}
    requirements::Tuple{Vararg{TaggedRequirement}}
    coverage::BitMatrix
    operating_profiles::Matrix{ExactRational}
    strategy_modules::Tuple{Vararg{Tuple}}
    source_frontier::Vector{ExactRational}
    source_closure::Tuple{Vararg{ModuleId}}
    identity_closure::Bool
    preprocessing::JournalPreprocessingMap
    tie_handling::JournalTieHandling
    provenance::JournalCompressionProvenance

    function JournalCompressionInstance(
        schema_version::String,
        strategy_ids::Tuple,
        mandatory::BitVector,
        weights::Vector{ExactRational},
        requirements::Tuple,
        coverage::BitMatrix,
        operating_profiles::Matrix{ExactRational},
        strategy_modules::Tuple,
        source_frontier::Vector{ExactRational},
        source_closure::Tuple,
        identity_closure::Bool,
        preprocessing::JournalPreprocessingMap,
        tie_handling::JournalTieHandling,
        provenance::JournalCompressionProvenance,
    )
        preprocessing_copy = JournalPreprocessingMap(
            preprocessing.applied,
            preprocessing.remaining_requirement_indices,
            preprocessing.remaining_strategy_indices,
            preprocessing.forced_strategy_indices,
            preprocessing.objective_offset,
            preprocessing.equal_coverage_choices;
            all_optimizer_identities_reconstructable =
                preprocessing.all_optimizer_identities_reconstructable,
        )
        candidate = new(
            schema_version,
            strategy_ids,
            copy(mandatory),
            copy(weights),
            requirements,
            copy(coverage),
            copy(operating_profiles),
            strategy_modules,
            copy(source_frontier),
            source_closure,
            identity_closure,
            preprocessing_copy,
            tie_handling,
            provenance,
        )
        return validate_journal_compression_instance(candidate)
    end
end


function Base.:(==)(left::JournalCompressionInstance, right::JournalCompressionInstance)
    return left.schema_version == right.schema_version &&
           left.strategy_ids == right.strategy_ids &&
           left.mandatory == right.mandatory &&
           left.weights == right.weights &&
           left.requirements == right.requirements &&
           left.coverage == right.coverage &&
           left.operating_profiles == right.operating_profiles &&
           left.strategy_modules == right.strategy_modules &&
           left.source_frontier == right.source_frontier &&
           left.source_closure == right.source_closure &&
           left.identity_closure == right.identity_closure &&
           left.preprocessing == right.preprocessing &&
           left.tie_handling == right.tie_handling &&
           left.provenance == right.provenance
end


function _journal_check_index_vector(values, maximum_value, label)
    all(index -> 1 <= index <= maximum_value, values) || throw(
        ArgumentError("$label contains an out-of-range original index"),
    )
    issorted(values) || throw(ArgumentError("$label must use stable increasing order"))
    _require_unique(values, label)
    return nothing
end


"""Validate every semantic, ordering, preprocessing, and tie invariant."""
function validate_journal_compression_instance(instance::JournalCompressionInstance)
    instance.schema_version == JOURNAL_COMPRESSION_INSTANCE_SCHEMA_VERSION || throw(
        ArgumentError("unsupported journal compression instance schema version"),
    )
    instance.identity_closure || throw(
        ArgumentError(
            "journal compression schema v1 supports only declared identity closure",
        ),
    )
    strategy_count = length(instance.strategy_ids)
    requirement_count = length(instance.requirements)
    strategy_count > 0 || throw(ArgumentError("a journal instance needs strategies"))
    requirement_count > 0 || throw(
        ArgumentError("a journal instance needs at least one tagged requirement"),
    )
    _require_unique(instance.strategy_ids, "journal strategy identifiers")
    _journal_is_strictly_sorted(instance.strategy_ids, _journal_strategy_key) || throw(
        ArgumentError("journal strategy identifiers are not in canonical stable order"),
    )
    _require_unique(instance.requirements, "journal tagged requirements")
    _journal_is_strictly_sorted(instance.requirements, _journal_requirement_key) || throw(
        ArgumentError("journal requirements are not in frontier-then-module stable order"),
    )

    frontier_requirements = FrontierRequirement[
        requirement for requirement in instance.requirements if
        requirement isa FrontierRequirement
    ]
    module_requirements = ModuleRequirement[
        requirement for requirement in instance.requirements if
        requirement isa ModuleRequirement
    ]
    isempty(frontier_requirements) && throw(
        ArgumentError("a journal instance needs at least one frontier requirement"),
    )
    frontier_count = length(frontier_requirements)
    length(instance.mandatory) == strategy_count || throw(
        DimensionMismatch("mandatory flags do not align with strategies"),
    )
    any(instance.mandatory) || throw(
        ArgumentError("a journal instance needs at least one mandatory strategy"),
    )
    length(instance.weights) == strategy_count || throw(
        DimensionMismatch("weights do not align with strategies"),
    )
    size(instance.coverage) == (requirement_count, strategy_count) || throw(
        DimensionMismatch("coverage dimensions do not align with the schema carriers"),
    )
    size(instance.operating_profiles) == (strategy_count, frontier_count) || throw(
        DimensionMismatch("operating profiles do not align with strategies and beliefs"),
    )
    length(instance.strategy_modules) == strategy_count || throw(
        DimensionMismatch("raw module memberships do not align with strategies"),
    )
    length(instance.source_frontier) == frontier_count || throw(
        DimensionMismatch("source frontier does not align with frontier requirements"),
    )
    all(weight -> weight >= 0, instance.weights) || throw(
        ArgumentError("journal strategy weights cannot be negative"),
    )
    for column in 1:strategy_count
        if !instance.mandatory[column] && !(instance.weights[column] > 0)
            throw(ArgumentError("nonmandatory journal strategy weights must be positive"))
        end
    end
    all(row -> any(instance.coverage[row, :]), 1:requirement_count) || throw(
        ArgumentError("a tagged requirement has no strategy carrier"),
    )

    _require_unique(instance.source_closure, "source closure module identifiers")
    _journal_is_strictly_sorted(instance.source_closure, _journal_module_key) || throw(
        ArgumentError("source closure modules are not in canonical stable order"),
    )
    required_modules = Tuple(requirement.module_id for requirement in module_requirements)
    required_modules == instance.source_closure || throw(
        ArgumentError("module requirements are inconsistent with the source closure"),
    )
    source_module_set = Set(instance.source_closure)
    union_modules = Set{ModuleId}()
    for modules in instance.strategy_modules
        all(module_id -> module_id isa ModuleId, modules) || throw(
            ArgumentError("strategy module memberships must contain ModuleId values"),
        )
        _require_unique(modules, "modules carried by one strategy")
        _journal_is_strictly_sorted(modules, _journal_module_key) || throw(
            ArgumentError("strategy modules are not in canonical stable order"),
        )
        issubset(Set(modules), source_module_set) || throw(
            ArgumentError("a strategy carries a module outside the source closure"),
        )
        union!(union_modules, modules)
    end
    union_modules == source_module_set || throw(
        ArgumentError("the declared source closure differs from the source module union"),
    )

    recomputed_frontier = ExactRational[
        maximum(instance.operating_profiles[:, belief_index]) for
        belief_index in 1:frontier_count
    ]
    recomputed_frontier == instance.source_frontier || throw(
        ArgumentError("the declared source frontier is inconsistent with source profiles"),
    )
    for (row, requirement) in enumerate(instance.requirements)
        if requirement isa FrontierRequirement
            belief_index = findfirst(==(requirement), frontier_requirements)
            for column in 1:strategy_count
                expected = instance.operating_profiles[column, belief_index] ==
                           instance.source_frontier[belief_index]
                instance.coverage[row, column] == expected || throw(
                    ArgumentError("frontier coverage is inconsistent with source profiles"),
                )
            end
        else
            for column in 1:strategy_count
                expected = requirement.module_id in instance.strategy_modules[column]
                instance.coverage[row, column] == expected || throw(
                    ArgumentError("module coverage is inconsistent with raw memberships"),
                )
            end
        end
    end

    preprocessing = instance.preprocessing
    _journal_check_index_vector(
        preprocessing.remaining_requirement_indices,
        requirement_count,
        "remaining requirement indices",
    )
    _journal_check_index_vector(
        preprocessing.remaining_strategy_indices,
        strategy_count,
        "remaining strategy indices",
    )
    _journal_check_index_vector(
        preprocessing.forced_strategy_indices,
        strategy_count,
        "forced strategy indices",
    )
    isempty(
        intersect(
            preprocessing.remaining_strategy_indices,
            preprocessing.forced_strategy_indices,
        ),
    ) || throw(ArgumentError("remaining and forced strategies must be disjoint"))
    if preprocessing.applied
        all(
            index -> index in preprocessing.forced_strategy_indices,
            findall(instance.mandatory),
        ) || throw(ArgumentError("preprocessing must force every mandatory strategy"))
    else
        preprocessing.remaining_requirement_indices == collect(1:requirement_count) &&
        preprocessing.remaining_strategy_indices == collect(1:strategy_count) &&
        isempty(preprocessing.forced_strategy_indices) &&
        iszero(preprocessing.objective_offset) &&
        isempty(preprocessing.equal_coverage_choices) || throw(
            ArgumentError("an unapplied preprocessing map must be the identity map"),
        )
    end
    expected_offset = sum(
        (instance.weights[index] for index in preprocessing.forced_strategy_indices);
        init = zero(ExactRational),
    )
    preprocessing.objective_offset == expected_offset || throw(
        ArgumentError("preprocessing objective offset does not equal forced burden"),
    )
    residual_rows = preprocessing.remaining_requirement_indices
    residual_columns = preprocessing.remaining_strategy_indices
    all(
        row -> any(instance.coverage[row, column] for column in residual_columns),
        residual_rows,
    ) || throw(ArgumentError("a residual requirement has no residual carrier"))
    seen_tie_indices = Set{Int}()
    for (representative, choices) in preprocessing.equal_coverage_choices
        representative in union(residual_columns, preprocessing.forced_strategy_indices) ||
            throw(ArgumentError("a tie representative is not retained or forced"))
        issorted(choices) || throw(
            ArgumentError("equal-coverage choices must use stable increasing order"),
        )
        _require_unique(choices, "equal-coverage choice indices")
        representative in choices || throw(
            ArgumentError("an equal-coverage class must contain its representative"),
        )
        all(index -> 1 <= index <= strategy_count, choices) || throw(
            ArgumentError("an equal-coverage class contains an invalid index"),
        )
        isempty(intersect(seen_tie_indices, Set(choices))) || throw(
            ArgumentError("equal-coverage reconstruction classes must be disjoint"),
        )
        union!(seen_tie_indices, choices)
        all(index -> !instance.mandatory[index], choices) || throw(
            ArgumentError("mandatory strategies cannot be duplicate reconstruction choices"),
        )
        all(index -> instance.weights[index] == instance.weights[representative], choices) ||
            throw(ArgumentError("equal-coverage choices must have equal exact weights"))
        for index in choices
            all(
                row -> instance.coverage[row, index] ==
                       instance.coverage[row, representative],
                residual_rows,
            ) || throw(
                ArgumentError("a reconstruction class differs on residual coverage"),
            )
        end
    end
    if instance.tie_handling.mode == :complete &&
       !preprocessing.all_optimizer_identities_reconstructable
        throw(
            ArgumentError(
                "complete tie handling is inconsistent with a lossy preprocessing map",
            ),
        )
    end
    return instance
end


function _journal_as_strategy_id(value)
    return value isa StrategyId ? value : StrategyId(value)
end


function _journal_as_belief(value)
    return value isa Belief ? value : Belief(value)
end


function _journal_as_module_id(value)
    return value isa ModuleId ? value : ModuleId(value)
end


"""Build a canonical schema instance from exact component arrays."""
function journal_compression_instance_from_components(
    strategy_ids::AbstractVector,
    mandatory::AbstractVector{Bool},
    weights::AbstractVector,
    belief_ids::AbstractVector,
    operating_profiles::AbstractMatrix,
    strategy_modules::AbstractVector;
    source_frontier = nothing,
    source_closure = nothing,
    preprocessing = nothing,
    tie_handling::JournalTieHandling = default_journal_tie_handling(),
    provenance::JournalCompressionProvenance,
)
    ids = StrategyId[_journal_as_strategy_id(value) for value in strategy_ids]
    beliefs = Belief[_journal_as_belief(value) for value in belief_ids]
    length(mandatory) == length(ids) || throw(
        DimensionMismatch("mandatory flags do not align with component strategies"),
    )
    length(weights) == length(ids) || throw(
        DimensionMismatch("weights do not align with component strategies"),
    )
    size(operating_profiles) == (length(ids), length(beliefs)) || throw(
        DimensionMismatch("component profiles do not align with strategies and beliefs"),
    )
    length(strategy_modules) == length(ids) || throw(
        DimensionMismatch("component module rows do not align with strategies"),
    )
    exact_profiles = ExactRational[
        exact_rational(operating_profiles[row, column]) for
        row in axes(operating_profiles, 1), column in axes(operating_profiles, 2)
    ]
    modules = [
        ModuleId[_journal_as_module_id(value) for value in row] for
        row in strategy_modules
    ]
    closure_values = if isnothing(source_closure)
        unique(ModuleId[module_id for row in modules for module_id in row])
    else
        ModuleId[_journal_as_module_id(value) for value in source_closure]
    end

    strategy_permutation = sortperm(eachindex(ids); by = index -> _journal_strategy_key(ids[index]))
    belief_permutation = sortperm(
        eachindex(beliefs);
        by = index -> _journal_belief_key(beliefs[index]),
    )
    canonical_ids = Tuple(ids[strategy_permutation])
    canonical_beliefs = beliefs[belief_permutation]
    canonical_profiles = exact_profiles[strategy_permutation, belief_permutation]
    canonical_mandatory = BitVector(mandatory[strategy_permutation])
    canonical_weights = ExactRational[
        exact_rational(weights[index]) for index in strategy_permutation
    ]
    canonical_modules = Tuple(
        Tuple(sort(modules[index]; by = _journal_module_key)) for
        index in strategy_permutation
    )
    canonical_closure = Tuple(sort(closure_values; by = _journal_module_key))
    frontier_values = if isnothing(source_frontier)
        ExactRational[
            maximum(canonical_profiles[:, column]) for
            column in axes(canonical_profiles, 2)
        ]
    else
        length(source_frontier) == length(beliefs) || throw(
            DimensionMismatch("declared source frontier does not align with beliefs"),
        )
        exact = ExactRational[exact_rational(value) for value in source_frontier]
        exact[belief_permutation]
    end
    requirements = Tuple(
        TaggedRequirement[
            [FrontierRequirement(belief) for belief in canonical_beliefs]...,
            [ModuleRequirement(module_id) for module_id in canonical_closure]...,
        ],
    )
    coverage = falses(length(requirements), length(canonical_ids))
    frontier_count = length(canonical_beliefs)
    for row in 1:frontier_count, column in eachindex(canonical_ids)
        coverage[row, column] =
            canonical_profiles[column, row] == frontier_values[row]
    end
    for (module_position, module_id) in enumerate(canonical_closure)
        row = frontier_count + module_position
        for column in eachindex(canonical_ids)
            coverage[row, column] = module_id in canonical_modules[column]
        end
    end
    map = isnothing(preprocessing) ?
          identity_journal_preprocessing_map(length(requirements), length(canonical_ids)) :
          preprocessing
    return JournalCompressionInstance(
        JOURNAL_COMPRESSION_INSTANCE_SCHEMA_VERSION,
        canonical_ids,
        canonical_mandatory,
        canonical_weights,
        requirements,
        coverage,
        canonical_profiles,
        canonical_modules,
        frontier_values,
        canonical_closure,
        true,
        map,
        tie_handling,
        provenance,
    )
end


function _journal_preprocessing_map(
    representation::TaggedCoverRepresentation,
    result::TaggedCoverPreprocessingResult,
    strategy_permutation,
    requirement_permutation,
)
    original = exact_tagged_cover_model(representation)
    original.strategy_ids == result.original.strategy_ids &&
    original.requirements == result.original.requirements &&
    original.coverage == result.original.coverage &&
    original.weights == result.original.weights &&
    original.mandatory == result.original.mandatory || throw(
        ArgumentError("preprocessing result does not belong to the tagged representation"),
    )
    strategy_old_to_new = zeros(Int, length(strategy_permutation))
    for (new_index, old_index) in enumerate(strategy_permutation)
        strategy_old_to_new[old_index] = new_index
    end
    requirement_old_to_new = zeros(Int, length(requirement_permutation))
    for (new_index, old_index) in enumerate(requirement_permutation)
        requirement_old_to_new[old_index] = new_index
    end
    tie_groups = Pair{Int,Tuple{Vararg{Int}}}[
        strategy_old_to_new[representative] => Tuple(
            sort(Int[strategy_old_to_new[index] for index in choices]),
        ) for (representative, choices) in result.equal_coverage_choices
    ]
    sort!(tie_groups; by = first)
    return JournalPreprocessingMap(
        true,
        sort(Int[
            requirement_old_to_new[index] for
            index in result.remaining_requirement_indices
        ]),
        sort(Int[
            strategy_old_to_new[index] for index in result.remaining_strategy_indices
        ]),
        sort(Int[
            strategy_old_to_new[index] for index in result.forced_strategy_indices
        ]),
        result.objective_offset,
        tie_groups;
        all_optimizer_identities_reconstructable =
            result.all_optimizer_identities_reconstructable,
    )
end


"""Convert the current source-relative tagged cover to the common schema."""
function journal_compression_instance(
    representation::TaggedCoverRepresentation;
    preprocessing::Union{Nothing,TaggedCoverPreprocessingResult} = nothing,
    tie_handling::JournalTieHandling = default_journal_tie_handling(),
    provenance::JournalCompressionProvenance,
)
    strategy_permutation = sortperm(
        eachindex(representation.strategy_ids);
        by = index -> _journal_strategy_key(representation.strategy_ids[index]),
    )
    requirement_permutation = sortperm(
        eachindex(representation.requirements);
        by = index -> _journal_requirement_key(representation.requirements[index]),
    )
    strategy_ids = Tuple(representation.strategy_ids[strategy_permutation])
    requirements = Tuple(representation.requirements[requirement_permutation])
    coverage = representation.coverage[requirement_permutation, strategy_permutation]
    frontier_requirements = FrontierRequirement[
        requirement for requirement in requirements if
        requirement isa FrontierRequirement
    ]
    operating_profiles = ExactRational[
        exact_rational(
            operational_profile(representation.catalog, strategy_id)[requirement.belief],
        ) for strategy_id in strategy_ids, requirement in frontier_requirements
    ]
    modules = Tuple(
        Tuple(
            sort(
                collect(strategy_modules(representation.catalog, strategy_id));
                by = _journal_module_key,
            ),
        ) for strategy_id in strategy_ids
    )
    source_state = compressed_state(
        representation.catalog,
        representation.closure,
        representation.source,
    )
    source_frontier = ExactRational[
        exact_rational(source_state.frontier[requirement.belief]) for
        requirement in frontier_requirements
    ]
    source_closure = Tuple(sort(collect(source_state.closure); by = _journal_module_key))
    old_inactive = representation.inactive_index
    new_inactive = findfirst(==(old_inactive), strategy_permutation)
    mandatory = falses(length(strategy_ids))
    mandatory[new_inactive] = true
    weights = ExactRational[representation.weights[index] for index in strategy_permutation]
    map = isnothing(preprocessing) ?
          identity_journal_preprocessing_map(length(requirements), length(strategy_ids)) :
          _journal_preprocessing_map(
              representation,
              preprocessing,
              strategy_permutation,
              requirement_permutation,
          )
    return JournalCompressionInstance(
        JOURNAL_COMPRESSION_INSTANCE_SCHEMA_VERSION,
        strategy_ids,
        mandatory,
        weights,
        requirements,
        BitMatrix(coverage),
        operating_profiles,
        modules,
        source_frontier,
        source_closure,
        true,
        map,
        tie_handling,
        provenance,
    )
end


"""Convert the current exact raw strategy-library model through tagged cover."""
function journal_compression_instance(
    catalog::StrategyCatalog,
    closure::GenerativeClosure,
    source::RawLibrary;
    strategy_weights = nothing,
    preprocessing::Union{Nothing,TaggedCoverPreprocessingResult} = nothing,
    tie_handling::JournalTieHandling = default_journal_tie_handling(),
    provenance::JournalCompressionProvenance,
)
    representation = tagged_cover_representation(
        catalog,
        closure,
        source;
        strategy_weights,
    )
    return journal_compression_instance(
        representation;
        preprocessing,
        tie_handling,
        provenance,
    )
end


"""
Convert legally distributable sparse financial optimization inputs. No raw
market rows, returns, prices, or dates are accepted or serialized.
"""
function journal_compression_instance_from_financial(
    source_ids::AbstractVector,
    rational_profiles::AbstractDict,
    strategy_modules::AbstractDict,
    source_frontier::AbstractVector,
    source_closure,
    weights::AbstractDict;
    inactive_id = "inactive",
    belief_ids = ["financial_state:$index" for index in eachindex(source_frontier)],
    tie_handling::JournalTieHandling = default_journal_tie_handling(),
    provenance::JournalCompressionProvenance,
)
    provenance.instance_kind == :financial || throw(
        ArgumentError("the financial adapter requires financial provenance"),
    )
    provenance.redistributable || throw(
        ArgumentError("financial schema conversion requires redistributable inputs"),
    )
    inactive_id in source_ids && throw(
        ArgumentError("implicit financial inactive identifier collides with an active ID"),
    )
    ids = Any[inactive_id; collect(source_ids)]
    profiles = Matrix{ExactRational}(undef, length(ids), length(source_frontier))
    for column in eachindex(source_frontier)
        profiles[1, column] = exact_rational(source_frontier[column]) - 1 // 1
    end
    modules = Vector{Vector{Any}}(undef, length(ids))
    modules[1] = Any[]
    exact_weights = Any[0]
    for (position, id) in enumerate(source_ids)
        haskey(rational_profiles, id) || throw(
            ArgumentError("financial profiles are missing strategy $id"),
        )
        haskey(strategy_modules, id) || throw(
            ArgumentError("financial modules are missing strategy $id"),
        )
        haskey(weights, id) || throw(
            ArgumentError("financial weights are missing strategy $id"),
        )
        values = rational_profiles[id]
        length(values) == length(source_frontier) || throw(
            DimensionMismatch("a financial profile has the wrong state count"),
        )
        for column in eachindex(values)
            profiles[position + 1, column] = exact_rational(values[column])
        end
        modules[position + 1] = Any[collect(strategy_modules[id])...]
        push!(exact_weights, weights[id])
    end
    return journal_compression_instance_from_components(
        ids,
        Bool[true; falses(length(source_ids))],
        exact_weights,
        belief_ids,
        profiles,
        modules;
        source_frontier,
        source_closure,
        tie_handling,
        provenance,
    )
end


function journal_compression_instance_from_financial(
    model::NamedTuple,
    weights::AbstractDict;
    kwargs...,
)
    required = (
        :source_ids,
        :rational_profiles,
        :source_frontier,
        :source_modules,
        :lookup,
    )
    all(field -> hasproperty(model, field), required) || throw(
        ArgumentError("financial model lacks a required public aggregate field"),
    )
    modules = Dict(
        id => collect(getproperty(model.lookup[id], :modules)) for id in model.source_ids
    )
    return journal_compression_instance_from_financial(
        collect(model.source_ids),
        model.rational_profiles,
        modules,
        model.source_frontier,
        collect(model.source_modules),
        weights;
        kwargs...,
    )
end


"""Convert an `ExactRetentionProblem`-compatible synthetic mask problem."""
function journal_compression_instance_from_mask_problem(
    problem;
    source_mask = nothing,
    inactive_id = "inactive",
    module_ids = nothing,
    belief_ids = nothing,
    tie_handling::JournalTieHandling = default_journal_tie_handling(),
    provenance::JournalCompressionProvenance,
)
    required = (:strategy_ids, :weights, :profiles, :module_masks, :module_count)
    all(field -> hasproperty(problem, field), required) || throw(
        ArgumentError("synthetic mask problem lacks a required field"),
    )
    provenance.instance_kind in (:synthetic, :adversarial, :canonical) || throw(
        ArgumentError("mask-problem conversion requires synthetic provenance"),
    )
    active_count = length(problem.strategy_ids)
    active_count <= 62 || throw(
        ArgumentError("mask-problem conversion supports at most 62 active strategies"),
    )
    length(problem.weights) == active_count || throw(
        DimensionMismatch("mask-problem weights do not align with strategies"),
    )
    size(problem.profiles, 1) == active_count || throw(
        DimensionMismatch("mask-problem profiles do not align with strategies"),
    )
    size(problem.profiles, 2) > 0 || throw(
        DimensionMismatch("mask-problem profiles need at least one belief"),
    )
    length(problem.module_masks) == active_count || throw(
        DimensionMismatch("mask-problem module masks do not align with strategies"),
    )
    module_count = Int(problem.module_count)
    1 <= module_count <= 62 || throw(
        ArgumentError("mask-problem conversion supports between 1 and 62 modules"),
    )
    resolved_module_ids = isnothing(module_ids) ?
                          ["module:$index" for index in 1:module_count] :
                          collect(module_ids)
    resolved_belief_ids = isnothing(belief_ids) ?
                          ["belief:$index" for index in axes(problem.profiles, 2)] :
                          collect(belief_ids)
    maximum_mask = (UInt64(1) << active_count) - UInt64(1)
    selected_mask = isnothing(source_mask) ? maximum_mask : UInt64(source_mask)
    (selected_mask & ~maximum_mask) == 0 || throw(
        ArgumentError("synthetic source mask exceeds the strategy carrier"),
    )
    selected_indices = Int[
        index for index in 1:active_count if
        !iszero(selected_mask & (UInt64(1) << (index - 1)))
    ]
    isempty(selected_indices) && throw(
        ArgumentError("synthetic source mask must retain an active strategy"),
    )
    length(resolved_module_ids) == module_count || throw(
        DimensionMismatch("synthetic module IDs do not match module_count"),
    )
    ids = Any[inactive_id; problem.strategy_ids[selected_indices]]
    profiles = Matrix{ExactRational}(
        undef,
        length(selected_indices) + 1,
        size(problem.profiles, 2),
    )
    profiles[1, :] .= zero(ExactRational)
    modules = Vector{Vector{Any}}(undef, length(ids))
    modules[1] = Any[]
    weights = Any[0]
    for (position, index) in enumerate(selected_indices)
        for column in axes(problem.profiles, 2)
            profiles[position + 1, column] = exact_rational(problem.profiles[index, column])
        end
        mask = UInt64(problem.module_masks[index])
        universe_mask = (UInt64(1) << module_count) - UInt64(1)
        iszero(mask & ~universe_mask) || throw(
            ArgumentError("a synthetic strategy module mask exceeds the universe"),
        )
        modules[position + 1] = Any[
            resolved_module_ids[module_index] for
            module_index in eachindex(resolved_module_ids) if
            !iszero(mask & (UInt64(1) << (module_index - 1)))
        ]
        push!(weights, problem.weights[index])
    end
    source_closure = unique(Any[module_id for row in modules for module_id in row])
    return journal_compression_instance_from_components(
        ids,
        Bool[true; falses(length(selected_indices))],
        weights,
        resolved_belief_ids,
        profiles,
        modules;
        source_closure,
        tie_handling,
        provenance,
    )
end


"""Return the original exact tagged-cover model stored by the schema."""
function exact_tagged_cover_model(instance::JournalCompressionInstance)
    return ExactTaggedCoverModel(
        instance.requirements,
        instance.strategy_ids,
        instance.coverage,
        instance.weights,
        instance.mandatory,
    )
end


"""Return the residual cover after the schema's preprocessing map."""
function journal_reduced_cover_model(instance::JournalCompressionInstance)
    rows = instance.preprocessing.remaining_requirement_indices
    columns = instance.preprocessing.remaining_strategy_indices
    mandatory = instance.preprocessing.applied ?
                falses(length(columns)) : instance.mandatory[columns]
    return ExactTaggedCoverModel(
        instance.requirements[rows],
        instance.strategy_ids[columns],
        instance.coverage[rows, columns],
        instance.weights[columns],
        mandatory,
    )
end


function _validate_journal_selection(instance, selected)
    length(selected) == length(instance.strategy_ids) || throw(
        DimensionMismatch("journal solution has the wrong strategy count"),
    )
    return selected
end


"""Compute exact source-order burden for an original binary selection."""
function journal_compression_burden(
    instance::JournalCompressionInstance,
    selected::AbstractVector{Bool},
)
    _validate_journal_selection(instance, selected)
    return sum(
        (instance.weights[index] for index in eachindex(selected) if selected[index]);
        init = zero(ExactRational),
    )
end


"""Return separate exact incidence and original-semantic solution checks."""
function check_journal_compression_solution(
    instance::JournalCompressionInstance,
    selected::AbstractVector{Bool};
    expected_burden = nothing,
)
    _validate_journal_selection(instance, selected)
    mandatory_retained = all(
        !instance.mandatory[index] || selected[index] for index in eachindex(selected)
    )
    tagged_coverage = all(
        any(selected[column] && instance.coverage[row, column] for column in eachindex(selected))
        for row in axes(instance.coverage, 1)
    )
    selected_indices = findall(selected)
    frontier_preserved = !isempty(selected_indices) && all(
        maximum(instance.operating_profiles[index, belief] for index in selected_indices) ==
        instance.source_frontier[belief] for belief in eachindex(instance.source_frontier)
    )
    selected_modules = Set{ModuleId}()
    for index in selected_indices
        union!(selected_modules, instance.strategy_modules[index])
    end
    closure_preserved = selected_modules == Set(instance.source_closure)
    burden = journal_compression_burden(instance, selected)
    burden_reconciled = isnothing(expected_burden) ? true :
                        burden == exact_rational(expected_burden)
    return (
        exact_feasible = mandatory_retained && tagged_coverage &&
                         frontier_preserved && closure_preserved,
        mandatory_retained,
        tagged_coverage,
        frontier_preserved,
        closure_preserved,
        exact_burden = burden,
        burden_reconciled,
    )
end


function journal_compression_feasible(
    instance::JournalCompressionInstance,
    selected::AbstractVector{Bool},
)
    return check_journal_compression_solution(instance, selected).exact_feasible
end


"""Lift a residual solution through forced selections to original columns."""
function lift_journal_compression_solution(
    instance::JournalCompressionInstance,
    reduced_selected::AbstractVector{Bool},
)
    columns = instance.preprocessing.remaining_strategy_indices
    length(reduced_selected) == length(columns) || throw(
        DimensionMismatch("residual solution has the wrong strategy count"),
    )
    lifted = falses(length(instance.strategy_ids))
    lifted[instance.preprocessing.forced_strategy_indices] .= true
    for (position, original_index) in enumerate(columns)
        reduced_selected[position] && (lifted[original_index] = true)
    end
    journal_compression_feasible(instance, lifted) || throw(
        ArgumentError("a reconstructed journal solution is not exactly feasible"),
    )
    residual_burden = sum(
        (
            instance.weights[columns[position]] for position in eachindex(columns) if
            reduced_selected[position]
        );
        init = zero(ExactRational),
    )
    journal_compression_burden(instance, lifted) ==
    instance.preprocessing.objective_offset + residual_burden || throw(
        ArgumentError("a reconstructed solution does not reconcile exact burden"),
    )
    return lifted
end


"""Reconstruct every equal-weight duplicate substitution recorded by preprocessing."""
function reconstruct_journal_compression_solutions(
    instance::JournalCompressionInstance,
    reduced_selected::AbstractVector{Bool},
)
    canonical = lift_journal_compression_solution(instance, reduced_selected)
    solutions = BitVector[canonical]
    for (representative, choices) in instance.preprocessing.equal_coverage_choices
        canonical[representative] || continue
        expanded = BitVector[]
        for solution in solutions, choice in choices
            candidate = copy(solution)
            candidate[representative] = false
            candidate[choice] = true
            journal_compression_feasible(instance, candidate) || throw(
                ArgumentError("a declared tie reconstruction is not exactly feasible"),
            )
            journal_compression_burden(instance, candidate) ==
            journal_compression_burden(instance, canonical) || throw(
                ArgumentError("a declared tie reconstruction changes exact burden"),
            )
            push!(expanded, candidate)
        end
        solutions = expanded
    end
    sort!(solutions; by = findall)
    return solutions
end


function _journal_identifier_payload(value)
    kind, encoded = _journal_identifier_parts(value)
    return Dict{String,Any}("id_kind" => kind, "id_value" => encoded)
end


function _journal_payload(instance::JournalCompressionInstance)
    source_closure_kinds = String[]
    source_closure_values = String[]
    for module_id in instance.source_closure
        kind, value = _journal_identifier_parts(module_id.id)
        push!(source_closure_kinds, kind)
        push!(source_closure_values, value)
    end
    strategies = Dict{String,Any}[]
    for (column, strategy_id) in enumerate(instance.strategy_ids)
        row = _journal_identifier_payload(strategy_id.id)
        row["mandatory"] = instance.mandatory[column]
        row["weight"] = encode_exact_rational(instance.weights[column])
        row["profile"] = encode_exact_rational.(instance.operating_profiles[column, :])
        module_kinds = String[]
        module_values = String[]
        for module_id in instance.strategy_modules[column]
            kind, value = _journal_identifier_parts(module_id.id)
            push!(module_kinds, kind)
            push!(module_values, value)
        end
        row["module_id_kinds"] = module_kinds
        row["module_id_values"] = module_values
        row["covered_requirement_indices"] = findall(instance.coverage[:, column])
        push!(strategies, row)
    end
    requirements = Dict{String,Any}[]
    for requirement in instance.requirements
        if requirement isa FrontierRequirement
            row = _journal_identifier_payload(requirement.belief.id)
            row["tag"] = "frontier"
        else
            row = _journal_identifier_payload(requirement.module_id.id)
            row["tag"] = "module"
        end
        push!(requirements, row)
    end
    tie_groups = Dict{String,Any}[
        Dict(
            "representative_index" => representative,
            "choice_indices" => collect(choices),
        ) for (representative, choices) in
        instance.preprocessing.equal_coverage_choices
    ]
    return Dict{String,Any}(
        "schema_version" => instance.schema_version,
        "identity_closure" => instance.identity_closure,
        "strategy_ordering" => "canonical-identifier-order",
        "requirement_ordering" => "frontier-then-module-canonical-identifier-order",
        "source_frontier" => encode_exact_rational.(instance.source_frontier),
        "source_closure_id_kinds" => source_closure_kinds,
        "source_closure_id_values" => source_closure_values,
        "strategies" => strategies,
        "requirements" => requirements,
        "preprocessing" => Dict{String,Any}(
            "applied" => instance.preprocessing.applied,
            "remaining_requirement_indices" =>
                instance.preprocessing.remaining_requirement_indices,
            "remaining_strategy_indices" =>
                instance.preprocessing.remaining_strategy_indices,
            "forced_strategy_indices" =>
                instance.preprocessing.forced_strategy_indices,
            "objective_offset" =>
                encode_exact_rational(instance.preprocessing.objective_offset),
            "all_optimizer_identities_reconstructable" =>
                instance.preprocessing.all_optimizer_identities_reconstructable,
            "equal_coverage_groups" => tie_groups,
        ),
        "tie_handling" => Dict{String,Any}(
            "mode" => string(instance.tie_handling.mode),
            "declaration" => instance.tie_handling.declaration,
            "stable_selector" => instance.tie_handling.stable_selector,
        ),
        "provenance" => Dict{String,Any}(
            "instance_kind" => string(instance.provenance.instance_kind),
            "instance_id" => instance.provenance.instance_id,
            "source" => instance.provenance.source,
            "generator" => something(instance.provenance.generator, ""),
            "redistributable" => instance.provenance.redistributable,
            "parent_hashes" => Dict{String,Any}[
                Dict("key" => first(entry), "sha256" => last(entry)) for
                entry in instance.provenance.parent_hashes
            ],
            "attributes" => Dict{String,Any}[
                Dict("key" => first(entry), "value" => last(entry)) for
                entry in instance.provenance.attributes
            ],
        ),
    )
end


"""Serialize to canonical sorted TOML text without floating-point conversion."""
function serialize_journal_compression_instance(instance::JournalCompressionInstance)
    validate_journal_compression_instance(instance)
    io = IOBuffer()
    TOML.print(io, _journal_payload(instance); sorted = true)
    return String(take!(io))
end


function write_journal_compression_instance(
    io::IO,
    instance::JournalCompressionInstance,
)
    write(io, serialize_journal_compression_instance(instance))
    return nothing
end


function journal_compression_instance_sha256(instance::JournalCompressionInstance)
    return bytes2hex(sha256(serialize_journal_compression_instance(instance)))
end


function _journal_required(payload, key, context)
    haskey(payload, key) || throw(ArgumentError("$context is missing $key"))
    return payload[key]
end


"""Deserialize canonical schema TOML and rerun all validation."""
function deserialize_journal_compression_instance(text::AbstractString)
    payload = TOML.parse(String(text))
    schema = String(_journal_required(payload, "schema_version", "instance"))
    schema == JOURNAL_COMPRESSION_INSTANCE_SCHEMA_VERSION || throw(
        ArgumentError("unsupported journal compression instance schema version"),
    )
    get(payload, "strategy_ordering", "") == "canonical-identifier-order" || throw(
        ArgumentError("serialized strategy ordering declaration is unstable"),
    )
    get(payload, "requirement_ordering", "") ==
    "frontier-then-module-canonical-identifier-order" || throw(
        ArgumentError("serialized requirement ordering declaration is unstable"),
    )
    strategy_rows = _journal_required(payload, "strategies", "instance")
    requirement_rows = _journal_required(payload, "requirements", "instance")
    strategies = StrategyId[
        StrategyId(
            _journal_decode_identifier(
                String(_journal_required(row, "id_kind", "strategy")),
                String(_journal_required(row, "id_value", "strategy")),
            ),
        ) for row in strategy_rows
    ]
    mandatory = BitVector(
        Bool(_journal_required(row, "mandatory", "strategy")) for row in strategy_rows
    )
    weights = ExactRational[
        exact_rational(String(_journal_required(row, "weight", "strategy"))) for
        row in strategy_rows
    ]
    requirements = TaggedRequirement[]
    for row in requirement_rows
        value = _journal_decode_identifier(
            String(_journal_required(row, "id_kind", "requirement")),
            String(_journal_required(row, "id_value", "requirement")),
        )
        tag = String(_journal_required(row, "tag", "requirement"))
        if tag == "frontier"
            push!(requirements, FrontierRequirement(Belief(value)))
        elseif tag == "module"
            push!(requirements, ModuleRequirement(ModuleId(value)))
        else
            throw(ArgumentError("unsupported serialized requirement tag: $tag"))
        end
    end
    frontier_count = count(requirement -> requirement isa FrontierRequirement, requirements)
    profiles = Matrix{ExactRational}(undef, length(strategies), frontier_count)
    strategy_modules_rows = Tuple[]
    coverage = falses(length(requirements), length(strategies))
    for (column, row) in enumerate(strategy_rows)
        profile = _journal_required(row, "profile", "strategy")
        length(profile) == frontier_count || throw(
            DimensionMismatch("serialized profile has the wrong belief count"),
        )
        profiles[column, :] .= exact_rational.(String.(profile))
        kinds = _journal_required(row, "module_id_kinds", "strategy")
        values = _journal_required(row, "module_id_values", "strategy")
        length(kinds) == length(values) || throw(
            DimensionMismatch("serialized strategy module identifiers are misaligned"),
        )
        push!(
            strategy_modules_rows,
            Tuple(
                ModuleId(_journal_decode_identifier(String(kind), String(value))) for
                (kind, value) in zip(kinds, values)
            ),
        )
        for raw_index in _journal_required(
            row,
            "covered_requirement_indices",
            "strategy",
        )
            index = Int(raw_index)
            1 <= index <= length(requirements) || throw(
                ArgumentError("serialized coverage index is out of range"),
            )
            coverage[index, column] = true
        end
    end
    closure_kinds = _journal_required(payload, "source_closure_id_kinds", "instance")
    closure_values = _journal_required(payload, "source_closure_id_values", "instance")
    length(closure_kinds) == length(closure_values) || throw(
        DimensionMismatch("serialized source closure identifiers are misaligned"),
    )
    source_closure = Tuple(
        ModuleId(_journal_decode_identifier(String(kind), String(value))) for
        (kind, value) in zip(closure_kinds, closure_values)
    )
    preprocessing_row = _journal_required(payload, "preprocessing", "instance")
    groups = Pair{Int,Tuple{Vararg{Int}}}[
        Int(_journal_required(row, "representative_index", "tie group")) =>
        Tuple(Int.(_journal_required(row, "choice_indices", "tie group"))) for
        row in get(preprocessing_row, "equal_coverage_groups", Any[])
    ]
    preprocessing = JournalPreprocessingMap(
        Bool(_journal_required(preprocessing_row, "applied", "preprocessing")),
        _journal_required(
            preprocessing_row,
            "remaining_requirement_indices",
            "preprocessing",
        ),
        _journal_required(
            preprocessing_row,
            "remaining_strategy_indices",
            "preprocessing",
        ),
        _journal_required(
            preprocessing_row,
            "forced_strategy_indices",
            "preprocessing",
        ),
        String(_journal_required(preprocessing_row, "objective_offset", "preprocessing")),
        groups;
        all_optimizer_identities_reconstructable = Bool(
            _journal_required(
                preprocessing_row,
                "all_optimizer_identities_reconstructable",
                "preprocessing",
            ),
        ),
    )
    tie_row = _journal_required(payload, "tie_handling", "instance")
    tie_handling = JournalTieHandling(
        Symbol(_journal_required(tie_row, "mode", "tie handling"));
        declaration = String(
            _journal_required(tie_row, "declaration", "tie handling"),
        ),
        stable_selector = String(
            _journal_required(tie_row, "stable_selector", "tie handling"),
        ),
    )
    provenance_row = _journal_required(payload, "provenance", "instance")
    generator = String(get(provenance_row, "generator", ""))
    provenance = JournalCompressionProvenance(
        Symbol(_journal_required(provenance_row, "instance_kind", "provenance")),
        String(_journal_required(provenance_row, "instance_id", "provenance")),
        String(_journal_required(provenance_row, "source", "provenance"));
        generator = isempty(generator) ? nothing : generator,
        parent_hashes = Pair{String,String}[
            String(_journal_required(row, "key", "parent hash")) =>
            String(_journal_required(row, "sha256", "parent hash")) for
            row in get(provenance_row, "parent_hashes", Any[])
        ],
        attributes = Pair{String,String}[
            String(_journal_required(row, "key", "provenance attribute")) =>
            String(_journal_required(row, "value", "provenance attribute")) for
            row in get(provenance_row, "attributes", Any[])
        ],
        redistributable = Bool(
            _journal_required(provenance_row, "redistributable", "provenance"),
        ),
    )
    return JournalCompressionInstance(
        schema,
        Tuple(strategies),
        mandatory,
        weights,
        Tuple(requirements),
        BitMatrix(coverage),
        profiles,
        Tuple(strategy_modules_rows),
        exact_rational.(String.(_journal_required(payload, "source_frontier", "instance"))),
        source_closure,
        Bool(_journal_required(payload, "identity_closure", "instance")),
        preprocessing,
        tie_handling,
        provenance,
    )
end


function read_journal_compression_instance(io::IO)
    return deserialize_journal_compression_instance(read(io, String))
end
