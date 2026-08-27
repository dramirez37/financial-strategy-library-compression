const ALGORITHMIC_COMPRESSION_GENERATOR_SCHEMA_VERSION =
    "algorithmic-compression-generator-record-v1"

const _ALGORITHMIC_BENCHMARK_ROOT = normpath(
    joinpath(@__DIR__, "..", "..", "experiments", "algorithmic_compression_v1"),
)
const DEFAULT_ALGORITHMIC_INSTANCE_REGISTRY = joinpath(
    _ALGORITHMIC_BENCHMARK_ROOT,
    "registry",
    "INSTANCE_REGISTRY.csv",
)
const DEFAULT_ALGORITHMIC_SEED_REGISTRY = joinpath(
    _ALGORITHMIC_BENCHMARK_ROOT,
    "registry",
    "SEED_REGISTRY.csv",
)
const _ALGORITHMIC_ATTEMPT_SALT = UInt64(0x6a09e667f3bcc909)
const _ALGORITHMIC_INT64_MASK = UInt64(0x7fffffffffffffff)


"""One immutable row of the registered benchmark instance registry."""
struct AlgorithmicBenchmarkInstanceSpec
    instance_id::String
    phase::Symbol
    analysis_included::Bool
    family::Symbol
    generator_id::String
    replicate_id::Int
    strategy_count::Int
    tagged_requirement_count::Int
    frontier_row_count::Int
    module_row_count::Int
    coverage_density_level::Symbol
    module_overlap_level::Symbol
    bundle_prevalence_level::Symbol
    unique_carrier_frequency_level::Symbol
    weight_dispersion_level::Symbol
    frontier_module_correlation_level::Symbol
    mechanism::Symbol
    mechanism_parameter::String
    seed_id::String
    exact_enumeration_required::Bool
    exact_dp_required::Bool
    mip_required::Bool
end


"""One immutable row of the registered benchmark seed registry."""
struct AlgorithmicBenchmarkSeedSpec
    seed_id::String
    instance_id::String
    phase::Symbol
    replicate_id::Int
    execution_order_key::UInt64
    generator_seed::UInt64
    random_order_seed::UInt64
    multistart_seed::UInt64
    mip_seed::UInt64
    randomness_scope::String
end


"""Exact prospective controls copied from one registry row."""
struct AlgorithmicStructuralRequest
    strategy_count::Int
    tagged_requirement_count::Int
    frontier_row_count::Int
    module_row_count::Int
    coverage_density_level::Symbol
    coverage_density_target::Union{Nothing,ExactRational}
    module_overlap_level::Symbol
    bundle_prevalence_level::Symbol
    bundle_count_target::Union{Nothing,Int}
    unique_carrier_frequency_level::Symbol
    unique_carrier_count_target::Union{Nothing,Int}
    weight_dispersion_level::Symbol
    frontier_module_correlation_level::Symbol
    mandatory_strategy_count::Int
end


"""Exact structural statistics recomputed from the realized common instance."""
struct AlgorithmicStructuralStatistics
    strategy_count::Int
    active_strategy_count::Int
    tagged_requirement_count::Int
    frontier_row_count::Int
    module_row_count::Int
    active_incidence_count::Int
    active_coverage_density::ExactRational
    frontier_coverage_density::ExactRational
    module_coverage_density::ExactRational
    minimum_carrier_count::Int
    maximum_carrier_count::Int
    unique_carrier_count::Int
    unique_carrier_frequency::ExactRational
    unique_carrier_strategy_ids::Tuple{Vararg{String}}
    bundle_threshold::Int
    bundle_count::Int
    bundle_prevalence::ExactRational
    mean_pairwise_module_jaccard::ExactRational
    frontier_module_rank_association::ExactRational
    minimum_active_weight::ExactRational
    maximum_active_weight::ExactRational
    distinct_active_weights::Tuple{Vararg{ExactRational}}
    mandatory_strategy_ids::Tuple{Vararg{String}}
    preprocessing_forced_strategy_ids::Tuple{Vararg{String}}
end


"""One rejected structural attempt; reasons are complete and stably ordered."""
struct AlgorithmicGenerationAttempt
    attempt_index::Int
    attempt_seed::UInt64
    accepted::Bool
    reasons::Tuple{Vararg{String}}
end


"""Validated generator output, including requested and realized structure."""
struct AlgorithmicGeneratedInstance
    schema_version::String
    spec::AlgorithmicBenchmarkInstanceSpec
    seed::AlgorithmicBenchmarkSeedSpec
    instance::JournalCompressionInstance
    requested::AlgorithmicStructuralRequest
    realized::AlgorithmicStructuralStatistics
    attempts::Tuple{Vararg{AlgorithmicGenerationAttempt}}
    instance_sha256::String
end


"""Auditable terminal failure after the declared structural attempts."""
struct AlgorithmicGenerationFailure
    schema_version::String
    spec::AlgorithmicBenchmarkInstanceSpec
    seed::AlgorithmicBenchmarkSeedSpec
    requested::AlgorithmicStructuralRequest
    attempts::Tuple{Vararg{AlgorithmicGenerationAttempt}}
    status::Symbol
end


for RecordType in (
    AlgorithmicBenchmarkInstanceSpec,
    AlgorithmicBenchmarkSeedSpec,
    AlgorithmicStructuralRequest,
    AlgorithmicStructuralStatistics,
    AlgorithmicGenerationAttempt,
)
    @eval Base.:(==)(left::$RecordType, right::$RecordType) = all(
        getfield(left, name) == getfield(right, name) for name in fieldnames($RecordType)
    )
end


_algorithmic_parse_bool(value::AbstractString) = if value == "true"
    true
elseif value == "false"
    false
else
    throw(ArgumentError("invalid registry Boolean token: $(repr(value))"))
end


function _algorithmic_registry_rows(path::AbstractString, expected_header)
    lines = readlines(path)
    isempty(lines) && throw(ArgumentError("empty registry: $path"))
    header = Tuple(Symbol.(split(chomp(first(lines)), ',')))
    header == expected_header || throw(
        ArgumentError("unexpected registry columns in $path"),
    )
    rows = Vector{Vector{String}}()
    for (line_number, line) in enumerate(Iterators.drop(lines, 1))
        isempty(strip(line)) && continue
        fields = String.(split(chomp(line), ','; keepempty = true))
        length(fields) == length(header) || throw(
            ArgumentError("malformed registry row $(line_number + 1) in $path"),
        )
        push!(rows, fields)
    end
    return rows
end


const _ALGORITHMIC_INSTANCE_HEADER = (
    :instance_id,
    :phase,
    :analysis_included,
    :family,
    :generator_id,
    :replicate_id,
    :strategy_count,
    :tagged_requirement_count,
    :frontier_row_count,
    :module_row_count,
    :coverage_density_level,
    :module_overlap_level,
    :bundle_prevalence_level,
    :unique_carrier_frequency_level,
    :weight_dispersion_level,
    :frontier_module_correlation_level,
    :mechanism,
    :mechanism_parameter,
    :seed_id,
    :exact_enumeration_required,
    :exact_dp_required,
    :mip_required,
)

const _ALGORITHMIC_SEED_HEADER = (
    :seed_id,
    :instance_id,
    :phase,
    :replicate_id,
    :execution_order_key,
    :generator_seed,
    :random_order_seed,
    :multistart_seed,
    :mip_seed,
    :randomness_scope,
)


function load_algorithmic_benchmark_registries(
    instance_path::AbstractString = DEFAULT_ALGORITHMIC_INSTANCE_REGISTRY,
    seed_path::AbstractString = DEFAULT_ALGORITHMIC_SEED_REGISTRY,
)
    instance_rows = _algorithmic_registry_rows(instance_path, _ALGORITHMIC_INSTANCE_HEADER)
    seed_rows = _algorithmic_registry_rows(seed_path, _ALGORITHMIC_SEED_HEADER)
    instances = AlgorithmicBenchmarkInstanceSpec[
        AlgorithmicBenchmarkInstanceSpec(
            row[1],
            Symbol(row[2]),
            _algorithmic_parse_bool(row[3]),
            Symbol(row[4]),
            row[5],
            parse(Int, row[6]),
            parse(Int, row[7]),
            parse(Int, row[8]),
            parse(Int, row[9]),
            parse(Int, row[10]),
            Symbol(row[11]),
            Symbol(row[12]),
            Symbol(row[13]),
            Symbol(row[14]),
            Symbol(row[15]),
            Symbol(row[16]),
            Symbol(row[17]),
            row[18],
            row[19],
            _algorithmic_parse_bool(row[20]),
            _algorithmic_parse_bool(row[21]),
            _algorithmic_parse_bool(row[22]),
        ) for row in instance_rows
    ]
    seeds = AlgorithmicBenchmarkSeedSpec[
        AlgorithmicBenchmarkSeedSpec(
            row[1],
            row[2],
            Symbol(row[3]),
            parse(Int, row[4]),
            parse(UInt64, row[5]),
            parse(UInt64, row[6]),
            parse(UInt64, row[7]),
            parse(UInt64, row[8]),
            parse(UInt64, row[9]),
            row[10],
        ) for row in seed_rows
    ]
    length(instances) == length(seeds) || throw(
        ArgumentError("instance and seed registries have different row counts"),
    )
    length(Set(spec.instance_id for spec in instances)) == length(instances) || throw(
        ArgumentError("duplicate instance ID in registry"),
    )
    length(Set(seed.seed_id for seed in seeds)) == length(seeds) || throw(
        ArgumentError("duplicate seed ID in registry"),
    )
    for (spec, seed) in zip(instances, seeds)
        (spec.instance_id, spec.seed_id, spec.phase, spec.replicate_id) ==
        (seed.instance_id, seed.seed_id, seed.phase, seed.replicate_id) || throw(
            ArgumentError("instance and seed registries are not row-aligned"),
        )
    end
    pilot_values = Set{UInt64}()
    final_values = Set{UInt64}()
    for seed in seeds
        target = seed.phase == :pilot ? pilot_values :
                 seed.phase == :final ? final_values : nothing
        isnothing(target) && continue
        union!(
            target,
            (
                seed.generator_seed,
                seed.random_order_seed,
                seed.multistart_seed,
                seed.mip_seed,
            ),
        )
    end
    isempty(intersect(pilot_values, final_values)) || throw(
        ArgumentError("pilot and final seed domains overlap"),
    )
    return (; instances, seeds)
end


function algorithmic_benchmark_registry_entry(
    instance_id::AbstractString;
    instance_path::AbstractString = DEFAULT_ALGORITHMIC_INSTANCE_REGISTRY,
    seed_path::AbstractString = DEFAULT_ALGORITHMIC_SEED_REGISTRY,
)
    registries = load_algorithmic_benchmark_registries(instance_path, seed_path)
    index = findfirst(spec -> spec.instance_id == instance_id, registries.instances)
    isnothing(index) && throw(ArgumentError("unknown registered instance: $instance_id"))
    return (spec = registries.instances[index], seed = registries.seeds[index])
end


function _algorithmic_splitmix64(input::UInt64)
    mixed = input + UInt64(0x9e3779b97f4a7c15)
    mixed = xor(mixed, mixed >> 30) * UInt64(0xbf58476d1ce4e5b9)
    mixed = xor(mixed, mixed >> 27) * UInt64(0x94d049bb133111eb)
    return xor(mixed, mixed >> 31)
end


function _algorithmic_attempt_seed(seed::UInt64, attempt::Int)
    value = _algorithmic_splitmix64(xor(seed, _ALGORITHMIC_ATTEMPT_SALT, UInt64(attempt))) &
            _ALGORITHMIC_INT64_MASK
    return iszero(value) ? one(UInt64) : value
end


_algorithmic_round_count(total::Int, fraction::ExactRational) =
    Int(fld(BigInt(total) * numerator(fraction) * 2 + denominator(fraction),
            2 * denominator(fraction)))


function _algorithmic_level_fraction(level::Symbol)
    level == :one_eighth && return BigInt(1) // BigInt(8)
    level == :three_eighths && return BigInt(3) // BigInt(8)
    level == :zero && return zero(ExactRational)
    level == :all && return one(ExactRational)
    return nothing
end


function _algorithmic_request(spec::AlgorithmicBenchmarkInstanceSpec)
    density = _algorithmic_level_fraction(spec.coverage_density_level)
    bundle_fraction = _algorithmic_level_fraction(spec.bundle_prevalence_level)
    unique_fraction = _algorithmic_level_fraction(spec.unique_carrier_frequency_level)
    active_count = spec.strategy_count - 1
    mandatory_count = spec.mechanism == :rare_mandatory_requirements ? 2 : 1
    return AlgorithmicStructuralRequest(
        spec.strategy_count,
        spec.tagged_requirement_count,
        spec.frontier_row_count,
        spec.module_row_count,
        spec.coverage_density_level,
        density,
        spec.module_overlap_level,
        spec.bundle_prevalence_level,
        isnothing(bundle_fraction) ? nothing :
            _algorithmic_round_count(active_count, bundle_fraction),
        spec.unique_carrier_frequency_level,
        isnothing(unique_fraction) ? nothing :
            _algorithmic_round_count(spec.tagged_requirement_count, unique_fraction),
        spec.weight_dispersion_level,
        spec.frontier_module_correlation_level,
        mandatory_count,
    )
end


_algorithmic_id(value::StrategyId) = string(value.id)


function _algorithmic_rank_association(frontier_counts, module_counts)
    length(frontier_counts) == length(module_counts) || throw(DimensionMismatch())
    numerator_value = 0
    pair_count = 0
    for left in 1:(length(frontier_counts) - 1), right in (left + 1):length(frontier_counts)
        frontier_sign = sign(frontier_counts[left] - frontier_counts[right])
        module_sign = sign(module_counts[left] - module_counts[right])
        numerator_value += frontier_sign * module_sign
        pair_count += 1
    end
    return iszero(pair_count) ? zero(ExactRational) :
           BigInt(numerator_value) // BigInt(pair_count)
end


function _algorithmic_mean_module_jaccard(instance::JournalCompressionInstance, active)
    total = zero(ExactRational)
    pairs = 0
    for left_position in 1:(length(active) - 1), right_position in (left_position + 1):length(active)
        left = Set(instance.strategy_modules[active[left_position]])
        right = Set(instance.strategy_modules[active[right_position]])
        union_count = length(union(left, right))
        iszero(union_count) && continue
        total += BigInt(length(intersect(left, right))) // BigInt(union_count)
        pairs += 1
    end
    return iszero(pairs) ? zero(ExactRational) : total / pairs
end


"""Recompute all structural controls from the canonical realized instance."""
function algorithmic_structural_statistics(instance::JournalCompressionInstance)
    validate_journal_compression_instance(instance)
    inactive_index = findfirst(
        strategy_id -> _algorithmic_id(strategy_id) == "inactive",
        instance.strategy_ids,
    )
    isnothing(inactive_index) && throw(
        ArgumentError("algorithmic benchmark instance lacks its declared inactive strategy"),
    )
    active = Int[index for index in eachindex(instance.strategy_ids) if index != inactive_index]
    frontier_count = length(instance.source_frontier)
    requirement_count = length(instance.requirements)
    module_count = requirement_count - frontier_count
    active_count = length(active)
    active_incidence = isempty(active) ? 0 : count(instance.coverage[:, active])
    density_denominator = requirement_count * active_count
    density = iszero(density_denominator) ? zero(ExactRational) :
              BigInt(active_incidence) // BigInt(density_denominator)
    frontier_incidence = isempty(active) ? 0 : count(instance.coverage[1:frontier_count, active])
    frontier_denominator = frontier_count * active_count
    frontier_density = iszero(frontier_denominator) ? zero(ExactRational) :
                       BigInt(frontier_incidence) // BigInt(frontier_denominator)
    module_incidence = module_count == 0 || isempty(active) ? 0 :
                       count(instance.coverage[(frontier_count + 1):end, active])
    module_denominator = module_count * active_count
    module_density = iszero(module_denominator) ? zero(ExactRational) :
                     BigInt(module_incidence) // BigInt(module_denominator)
    carrier_counts = [count(instance.coverage[row, :]) for row in 1:requirement_count]
    unique_rows = findall(==(1), carrier_counts)
    unique_ids = sort!(unique(String[
        _algorithmic_id(instance.strategy_ids[only(findall(instance.coverage[row, :]))])
        for row in unique_rows
    ]))
    bundle_threshold = cld(3 * requirement_count, 4)
    bundle_indices = Int[
        column for column in active if
        count(instance.coverage[:, column]) >= bundle_threshold
    ]
    frontier_counts = Int[
        count(instance.coverage[1:frontier_count, column]) for column in active
    ]
    module_counts = Int[
        module_count == 0 ? 0 :
        count(instance.coverage[(frontier_count + 1):end, column]) for column in active
    ]
    active_weights = ExactRational[instance.weights[index] for index in active]
    forced = preprocess_tagged_cover(exact_tagged_cover_model(instance))
    forced_ids = Tuple(
        sort!(collect(_algorithmic_id.(instance.strategy_ids[forced.forced_strategy_indices]))),
    )
    mandatory_ids = Tuple(
        sort!(collect(_algorithmic_id.(instance.strategy_ids[findall(instance.mandatory)]))),
    )
    return AlgorithmicStructuralStatistics(
        length(instance.strategy_ids),
        active_count,
        requirement_count,
        frontier_count,
        module_count,
        active_incidence,
        density,
        frontier_density,
        module_density,
        minimum(carrier_counts),
        maximum(carrier_counts),
        length(unique_rows),
        BigInt(length(unique_rows)) // BigInt(requirement_count),
        Tuple(unique_ids),
        bundle_threshold,
        length(bundle_indices),
        iszero(active_count) ? zero(ExactRational) :
            BigInt(length(bundle_indices)) // BigInt(active_count),
        _algorithmic_mean_module_jaccard(instance, active),
        _algorithmic_rank_association(frontier_counts, module_counts),
        isempty(active_weights) ? zero(ExactRational) : minimum(active_weights),
        isempty(active_weights) ? zero(ExactRational) : maximum(active_weights),
        Tuple(sort!(unique(active_weights))),
        mandatory_ids,
        forced_ids,
    )
end


function _algorithmic_weights(level::Symbol, active_count::Int, rng)
    support = if level in (:high_powers_of_two, :heterogeneous)
        BigInt[1, 2, 4, 8, 16]
    elseif level == :low_1_to_3
        BigInt[1, 2, 3]
    elseif level in (:homogeneous, :none, :trivial, :mechanism)
        BigInt[1]
    else
        throw(ArgumentError("unsupported weight-dispersion level: $level"))
    end
    logical = ExactRational[support[mod1(index, length(support))] // 1 for index in 1:active_count]
    permutation = randperm(rng, active_count)
    return logical[permutation]
end


function _algorithmic_provenance(spec, seed, attempt_seed; kind = :synthetic)
    return JournalCompressionProvenance(
        kind,
        spec.instance_id,
        "Registered Algorithmic Compression Benchmark v1 registry";
        generator = spec.generator_id,
        attributes = [
            "evidence_class" => kind == :adversarial ?
                "exact adversarial construction" : "synthetic registered generator",
            "phase" => string(spec.phase),
            "seed_id" => seed.seed_id,
            "generator_seed" => string(seed.generator_seed),
            "accepted_attempt_seed" => string(attempt_seed),
            "mechanism" => string(spec.mechanism),
        ],
        redistributable = true,
    )
end


function _algorithmic_instance_from_incidence(
    spec,
    seed,
    attempt_seed,
    incidence::BitMatrix,
    weights,
    mandatory;
    zero_frontier::Bool = false,
    kind::Symbol = :synthetic,
)
    active_count = size(incidence, 2)
    size(incidence, 1) == spec.tagged_requirement_count || throw(DimensionMismatch())
    active_count + 1 == spec.strategy_count || throw(DimensionMismatch())
    strategy_ids = String["inactive"]
    append!(strategy_ids, ["s" * lpad(string(index), 4, '0') for index in 1:active_count])
    belief_ids = ["b" * lpad(string(index), 4, '0') for index in 1:spec.frontier_row_count]
    module_ids = ["m" * lpad(string(index), 4, '0') for index in 1:spec.module_row_count]
    profiles = zeros(ExactRational, spec.strategy_count, spec.frontier_row_count)
    if !zero_frontier
        for row in 1:spec.frontier_row_count, active_column in 1:active_count
            profiles[active_column + 1, row] = incidence[row, active_column] ? 1 // 1 : 0 // 1
        end
    end
    modules = Vector{Vector{String}}(undef, spec.strategy_count)
    modules[1] = String[]
    for active_column in 1:active_count
        modules[active_column + 1] = String[
            module_ids[module_row] for module_row in 1:spec.module_row_count if
            incidence[spec.frontier_row_count + module_row, active_column]
        ]
    end
    all_weights = ExactRational[0 // 1; exact_rational.(weights)]
    return journal_compression_instance_from_components(
        strategy_ids,
        mandatory,
        all_weights,
        belief_ids,
        profiles,
        modules;
        provenance = _algorithmic_provenance(spec, seed, attempt_seed; kind),
    )
end


function _algorithmic_structured_candidate(spec, seed, attempt_seed)
    rng = StableRNG(Int(attempt_seed))
    r = spec.tagged_requirement_count
    a = spec.strategy_count - 1
    f = spec.frontier_row_count
    (r == f + spec.module_row_count && r > 0 && f > 0 && a > 0) || return (
        nothing,
        ["registry dimensions are inconsistent or empty"],
    )
    density_target = _algorithmic_level_fraction(spec.coverage_density_level)
    unique_fraction = _algorithmic_level_fraction(spec.unique_carrier_frequency_level)
    bundle_fraction = _algorithmic_level_fraction(spec.bundle_prevalence_level)
    any(isnothing, (density_target, unique_fraction, bundle_fraction)) && return (
        nothing,
        ["structured row contains an unsupported factor level"],
    )
    unique_count = _algorithmic_round_count(r, unique_fraction)
    bundle_count = _algorithmic_round_count(a, bundle_fraction)
    unique_count <= min(r, a - bundle_count) || return (
        nothing,
        ["requested unique carriers cannot be assigned distinctly outside bundles"],
    )
    incidence = falses(r, a)
    aligned_order = randperm(rng, a)
    frontier_order = copy(aligned_order)
    module_order = spec.frontier_module_correlation_level == :positive_aligned ?
                   copy(aligned_order) : randperm(rng, a)
    bundle_columns = bundle_count == 0 ? Int[] : sort!(aligned_order[1:bundle_count])
    nonbundle_order = Int[column for column in aligned_order if column ∉ bundle_columns]
    isempty(nonbundle_order) && unique_count > 0 && return (
        nothing,
        ["no nonbundle carrier remains for unique requirements"],
    )
    for row in 1:unique_count
        incidence[row, nonbundle_order[mod1(row, length(nonbundle_order))]] = true
    end
    for row in (unique_count + 1):r, column in bundle_columns
        incidence[row, column] = true
    end
    for row in (unique_count + 1):r
        base = row <= f ? frontier_order : module_order
        shift = if row > f && spec.module_overlap_level == :low_clustered
            mod(row - f - 1, a)
        elseif row <= f
            mod(row - 1, a)
        else
            0
        end
        order = circshift(base, shift)
        for column in order
            count(incidence[row, :]) >= 2 && break
            if column ∉ bundle_columns &&
               count(incidence[:, column]) >= cld(3 * r, 4) - 1
                continue
            end
            incidence[row, column] = true
        end
    end
    target_count = _algorithmic_round_count(r * a, density_target)
    if spec.family == :small_exact
        target_count = max(target_count, count(incidence))
    end
    count(incidence) > target_count && return (
        nothing,
        ["forced bundle and unique structure exceeds requested density"],
    )
    bundle_threshold = cld(3 * r, 4)
    candidates = Tuple{Int,Int,Int,Int}[]
    for row in (unique_count + 1):r
        base = row <= f ? frontier_order : module_order
        shift = if row > f && spec.module_overlap_level == :low_clustered
            mod(row - f - 1, a)
        elseif row <= f
            mod(row - 1, a)
        else
            0
        end
        order = circshift(base, shift)
        for (rank, column) in enumerate(order)
            incidence[row, column] && continue
            push!(candidates, (rank, row, column, rand(rng, 1:typemax(Int32))))
        end
    end
    sort!(candidates; by = candidate -> (candidate[1], candidate[4], candidate[2], candidate[3]))
    for (_, row, column, _) in candidates
        count(incidence) >= target_count && break
        if column ∉ bundle_columns && count(incidence[:, column]) >= bundle_threshold - 1
            continue
        end
        incidence[row, column] = true
    end
    reasons = String[]
    count(incidence) == target_count || push!(reasons, "density target cannot be reached under bundle cap")
    all(any(incidence[row, :]) for row in 1:r) || push!(reasons, "a requirement has no active carrier")
    carrier_counts = [count(incidence[row, :]) for row in 1:r]
    count(==(1), carrier_counts) == unique_count || push!(reasons, "realized unique-carrier count differs from target")
    realized_bundles = count(column -> count(incidence[:, column]) >= bundle_threshold, 1:a)
    realized_bundles == bundle_count || push!(reasons, "realized bundle count differs from target")
    if spec.family == :structured
        realized_density = BigInt(count(incidence)) // BigInt(r * a)
        abs(realized_density - density_target) <= BigInt(1) // BigInt(64) || push!(
            reasons,
            "realized density lies outside the registered tolerance",
        )
    end
    isempty(reasons) || return (nothing, reasons)
    weights = _algorithmic_weights(spec.weight_dispersion_level, a, rng)
    mandatory = Bool[true; falses(a)]
    instance = try
        _algorithmic_instance_from_incidence(
            spec,
            seed,
            attempt_seed,
            incidence,
            weights,
            mandatory,
        )
    catch error
        return (nothing, ["common-schema rejection: $(sprint(showerror, error))"])
    end
    return (instance, String[])
end


function _algorithmic_parse_parameters(text::AbstractString)
    values = Dict{String,String}()
    text == "none" && return values
    for term in split(text, ';')
        pieces = split(term, '='; limit = 2)
        length(pieces) == 2 || throw(ArgumentError("invalid mechanism parameter: $term"))
        values[pieces[1]] = pieces[2]
    end
    return values
end


function _algorithmic_adversarial_logical(spec)
    parameters = _algorithmic_parse_parameters(spec.mechanism_parameter)
    mechanism = spec.mechanism
    r = spec.tagged_requirement_count
    a = spec.strategy_count - 1
    incidence = falses(r, a)
    incidence[1, :] .= true
    weights = fill(one(ExactRational), a)
    mandatory_active = falses(a)
    if mechanism == :unbounded_heaviest_safe_first_gap
        k = parse(Int, parameters["k"])
        a == k + 1 || throw(ArgumentError("unbounded-gap strategy count mismatch"))
        for index in 1:k
            incidence[index + 1, index] = true
        end
        incidence[2:end, k + 1] .= true
        weights[k + 1] = exact_rational(parameters["epsilon"]) + 1
    elseif mechanism == :many_tied_optima
        incidence[2:end, :] .= true
    elseif mechanism == :dense_duplicate_coverage
        incidence[2:end, :] .= true
        for index in 1:a
            weights[index] = index <= cld(a, 2) ? 1 // 1 : 2 // 1
        end
    elseif mechanism == :dominance_heavy
        q = parse(Int, parameters["base_dimension"])
        a == 2q || throw(ArgumentError("dominance-heavy strategy count mismatch"))
        for index in 1:q
            incidence[1 + index, index] = true
            incidence[1 + mod1(index + 1, q), index] = true
            incidence[1 + index, q + index] = true
            weights[q + index] = 2 // 1
        end
    elseif mechanism == :rare_mandatory_requirements
        modules = parse(Int, parameters["modules"])
        a == modules + 1 || throw(ArgumentError("rare-mandatory strategy count mismatch"))
        mandatory_active[1] = true
        incidence[2, 1] = true
        for index in 1:modules
            first_row = 1 + max(2, index)
            second_row = 1 + max(2, mod1(index + 1, modules))
            incidence[first_row, index + 1] = true
            incidence[second_row, index + 1] = true
        end
    elseif mechanism == :symmetric_hard
        q = parse(Int, parameters["cyclic_order"])
        a == q || throw(ArgumentError("symmetric strategy count mismatch"))
        window = cld(q, 2)
        for column in 1:q, offset in 0:(window - 1)
            incidence[1 + mod1(column + offset, q), column] = true
        end
    elseif mechanism == :bundle_versus_singleton
        k = parse(Int, parameters["k"])
        a == k + 2 || throw(ArgumentError("bundle-versus-singleton strategy count mismatch"))
        for index in 1:k
            incidence[index + 1, index] = true
        end
        left_end = cld(3k, 4)
        right_start = fld(k, 4) + 1
        incidence[2:(1 + left_end), k + 1] .= true
        incidence[(1 + right_start):(1 + k), k + 2] .= true
        left_singleton_cost = exact_rational(left_end)
        right_singleton_cost = exact_rational(k - right_start + 1)
        weights[k + 1] = left_singleton_cost - BigInt(1) // BigInt(4)
        weights[k + 2] = right_singleton_cost + BigInt(1) // BigInt(4)
    else
        throw(ArgumentError("unsupported adversarial mechanism: $mechanism"))
    end
    return (; incidence, weights, mandatory_active)
end


function _algorithmic_adversarial_candidate(spec, seed, attempt_seed)
    logical = try
        _algorithmic_adversarial_logical(spec)
    catch error
        return (nothing, ["adversarial construction rejection: $(sprint(showerror, error))"])
    end
    rng = StableRNG(Int(attempt_seed))
    permutation = randperm(rng, size(logical.incidence, 2))
    incidence = logical.incidence[:, permutation]
    weights = logical.weights[permutation]
    mandatory = Bool[true; logical.mandatory_active[permutation]]
    instance = try
        _algorithmic_instance_from_incidence(
            spec,
            seed,
            attempt_seed,
            incidence,
            weights,
            mandatory;
            zero_frontier = true,
            kind = :adversarial,
        )
    catch error
        return (nothing, ["common-schema rejection: $(sprint(showerror, error))"])
    end
    return (instance, String[])
end


function _algorithmic_dry_candidate(spec, seed, attempt_seed)
    a = spec.strategy_count - 1
    incidence = falses(spec.tagged_requirement_count, a)
    weights = fill(one(ExactRational), a)
    if spec.generator_id == "trivial-mandatory-only-v1"
        incidence[1, :] .= true
    elseif spec.generator_id == "trivial-unique-module-v1"
        incidence[:, 1] .= true
    elseif spec.generator_id == "trivial-triangle-v1"
        incidence[1, :] .= true
        for column in 1:3
            incidence[1 + column, column] = true
            incidence[1 + mod1(column + 1, 3), column] = true
        end
    else
        return (nothing, ["unsupported dry-run generator"])
    end
    instance = try
        _algorithmic_instance_from_incidence(
            spec,
            seed,
            attempt_seed,
            incidence,
            weights,
            Bool[true; falses(a)];
            zero_frontier = spec.generator_id != "trivial-unique-module-v1",
        )
    catch error
        return (nothing, ["common-schema rejection: $(sprint(showerror, error))"])
    end
    return (instance, String[])
end


function _algorithmic_gate_reasons(spec, request, instance, realized)
    reasons = String[]
    validate_journal_compression_instance(instance)
    realized.minimum_carrier_count >= 1 || push!(reasons, "a tagged requirement has no carrier")
    realized.strategy_count == request.strategy_count || push!(reasons, "realized strategy count differs from registry")
    realized.tagged_requirement_count == request.tagged_requirement_count || push!(reasons, "realized requirement count differs from registry")
    realized.frontier_row_count == request.frontier_row_count || push!(reasons, "realized frontier count differs from registry")
    realized.module_row_count == request.module_row_count || push!(reasons, "realized module count differs from registry")
    length(realized.mandatory_strategy_ids) == request.mandatory_strategy_count || push!(reasons, "realized mandatory-strategy count differs from declaration")
    if spec.family in (:structured, :small_exact)
        !isnothing(request.unique_carrier_count_target) &&
            realized.unique_carrier_count != request.unique_carrier_count_target &&
            push!(reasons, "realized unique-carrier count differs from request")
        !isnothing(request.bundle_count_target) &&
            realized.bundle_count != request.bundle_count_target &&
            push!(reasons, "realized bundle count differs from request")
    end
    if spec.family == :structured && !isnothing(request.coverage_density_target)
        abs(realized.active_coverage_density - request.coverage_density_target) <= 1 // 64 || push!(
            reasons,
            "realized coverage density misses registered tolerance",
        )
    end
    if spec.mechanism == :rare_mandatory_requirements
        realized.unique_carrier_count == 1 || push!(reasons, "rare-mandatory construction must have exactly one unique requirement")
        length(realized.mandatory_strategy_ids) == 2 || push!(reasons, "rare-mandatory construction must retain inactive and one active mandatory strategy")
    end
    return sort!(unique!(reasons))
end


"""
    generate_algorithmic_benchmark_instance(spec, seed; maximum_attempts=128,
                                            allow_final=false)

Generate one registered instance without running any compression algorithm.
Final rows require the caller to opt in explicitly, preventing dry-run and test
commands from accidentally producing final benchmark inputs.
"""
function generate_algorithmic_benchmark_instance(
    spec::AlgorithmicBenchmarkInstanceSpec,
    seed::AlgorithmicBenchmarkSeedSpec;
    maximum_attempts::Int = 128,
    allow_final::Bool = false,
)
    (spec.instance_id, spec.seed_id, spec.phase, spec.replicate_id) ==
    (seed.instance_id, seed.seed_id, seed.phase, seed.replicate_id) || throw(
        ArgumentError("instance and seed rows do not correspond"),
    )
    spec.phase == :final && !allow_final && throw(
        ArgumentError("final benchmark generation requires allow_final=true"),
    )
    maximum_attempts >= 1 || throw(ArgumentError("maximum_attempts must be positive"))
    request = _algorithmic_request(spec)
    attempts = AlgorithmicGenerationAttempt[]
    attempt_limit = spec.family in (:structured, :small_exact) ? maximum_attempts : 1
    for attempt in 1:attempt_limit
        attempt_seed = _algorithmic_attempt_seed(seed.generator_seed, attempt)
        instance, reasons = if spec.family in (:structured, :small_exact)
            _algorithmic_structured_candidate(spec, seed, attempt_seed)
        elseif spec.family == :adversarial
            _algorithmic_adversarial_candidate(spec, seed, attempt_seed)
        elseif spec.family == :dry_run
            _algorithmic_dry_candidate(spec, seed, attempt_seed)
        else
            (nothing, ["unsupported registered family: $(spec.family)"])
        end
        if !isnothing(instance)
            realized = algorithmic_structural_statistics(instance)
            append!(reasons, _algorithmic_gate_reasons(spec, request, instance, realized))
            sort!(unique!(reasons))
            if isempty(reasons)
                push!(attempts, AlgorithmicGenerationAttempt(attempt, attempt_seed, true, ()))
                return AlgorithmicGeneratedInstance(
                    ALGORITHMIC_COMPRESSION_GENERATOR_SCHEMA_VERSION,
                    spec,
                    seed,
                    instance,
                    request,
                    realized,
                    Tuple(attempts),
                    journal_compression_instance_sha256(instance),
                )
            end
        end
        push!(
            attempts,
            AlgorithmicGenerationAttempt(
                attempt,
                attempt_seed,
                false,
                Tuple(sort!(unique!(String.(reasons)))),
            ),
        )
    end
    return AlgorithmicGenerationFailure(
        ALGORITHMIC_COMPRESSION_GENERATOR_SCHEMA_VERSION,
        spec,
        seed,
        request,
        Tuple(attempts),
        :GENERATION_FAILED,
    )
end


function generate_algorithmic_benchmark_instance(
    instance_id::AbstractString;
    kwargs...,
)
    row = algorithmic_benchmark_registry_entry(instance_id)
    return generate_algorithmic_benchmark_instance(row.spec, row.seed; kwargs...)
end


_algorithmic_exact_text(value::ExactRational) = encode_exact_rational(value)


function _algorithmic_request_payload(request::AlgorithmicStructuralRequest)
    return Dict{String,Any}(
        "strategy_count" => request.strategy_count,
        "tagged_requirement_count" => request.tagged_requirement_count,
        "frontier_row_count" => request.frontier_row_count,
        "module_row_count" => request.module_row_count,
        "coverage_density_level" => string(request.coverage_density_level),
        "coverage_density_target" => isnothing(request.coverage_density_target) ? "UNSPECIFIED" : _algorithmic_exact_text(request.coverage_density_target),
        "module_overlap_level" => string(request.module_overlap_level),
        "bundle_prevalence_level" => string(request.bundle_prevalence_level),
        "bundle_count_target" => something(request.bundle_count_target, -1),
        "unique_carrier_frequency_level" => string(request.unique_carrier_frequency_level),
        "unique_carrier_count_target" => something(request.unique_carrier_count_target, -1),
        "weight_dispersion_level" => string(request.weight_dispersion_level),
        "frontier_module_correlation_level" => string(request.frontier_module_correlation_level),
        "mandatory_strategy_count" => request.mandatory_strategy_count,
    )
end


function _algorithmic_realized_payload(stats::AlgorithmicStructuralStatistics)
    return Dict{String,Any}(
        "strategy_count" => stats.strategy_count,
        "active_strategy_count" => stats.active_strategy_count,
        "tagged_requirement_count" => stats.tagged_requirement_count,
        "frontier_row_count" => stats.frontier_row_count,
        "module_row_count" => stats.module_row_count,
        "active_incidence_count" => stats.active_incidence_count,
        "active_coverage_density" => _algorithmic_exact_text(stats.active_coverage_density),
        "frontier_coverage_density" => _algorithmic_exact_text(stats.frontier_coverage_density),
        "module_coverage_density" => _algorithmic_exact_text(stats.module_coverage_density),
        "minimum_carrier_count" => stats.minimum_carrier_count,
        "maximum_carrier_count" => stats.maximum_carrier_count,
        "unique_carrier_count" => stats.unique_carrier_count,
        "unique_carrier_frequency" => _algorithmic_exact_text(stats.unique_carrier_frequency),
        "unique_carrier_strategy_ids" => collect(stats.unique_carrier_strategy_ids),
        "bundle_threshold" => stats.bundle_threshold,
        "bundle_count" => stats.bundle_count,
        "bundle_prevalence" => _algorithmic_exact_text(stats.bundle_prevalence),
        "mean_pairwise_module_jaccard" => _algorithmic_exact_text(stats.mean_pairwise_module_jaccard),
        "frontier_module_rank_association" => _algorithmic_exact_text(stats.frontier_module_rank_association),
        "minimum_active_weight" => _algorithmic_exact_text(stats.minimum_active_weight),
        "maximum_active_weight" => _algorithmic_exact_text(stats.maximum_active_weight),
        "distinct_active_weights" => collect(
            _algorithmic_exact_text.(stats.distinct_active_weights),
        ),
        "mandatory_strategy_ids" => collect(stats.mandatory_strategy_ids),
        "preprocessing_forced_strategy_ids" => collect(stats.preprocessing_forced_strategy_ids),
    )
end


function _algorithmic_spec_payload(spec::AlgorithmicBenchmarkInstanceSpec)
    return Dict{String,Any}(
        "instance_id" => spec.instance_id,
        "phase" => string(spec.phase),
        "analysis_included" => spec.analysis_included,
        "family" => string(spec.family),
        "generator_id" => spec.generator_id,
        "replicate_id" => spec.replicate_id,
        "mechanism" => string(spec.mechanism),
        "mechanism_parameter" => spec.mechanism_parameter,
        "seed_id" => spec.seed_id,
    )
end


function _algorithmic_seed_payload(seed::AlgorithmicBenchmarkSeedSpec)
    return Dict{String,Any}(
        "seed_id" => seed.seed_id,
        "instance_id" => seed.instance_id,
        "phase" => string(seed.phase),
        "replicate_id" => seed.replicate_id,
        "execution_order_key" => string(seed.execution_order_key),
        "generator_seed" => string(seed.generator_seed),
        "random_order_seed" => string(seed.random_order_seed),
        "multistart_seed" => string(seed.multistart_seed),
        "mip_seed" => string(seed.mip_seed),
        "randomness_scope" => seed.randomness_scope,
    )
end


function _algorithmic_attempt_payload(attempt::AlgorithmicGenerationAttempt)
    return Dict{String,Any}(
        "attempt_index" => attempt.attempt_index,
        "attempt_seed" => string(attempt.attempt_seed),
        "accepted" => attempt.accepted,
        "reasons" => collect(attempt.reasons),
    )
end


"""Serialize requested structure, realized structure, rejection trace, and hashes."""
function serialize_algorithmic_generation_record(result::AlgorithmicGeneratedInstance)
    payload = Dict{String,Any}(
        "schema_version" => result.schema_version,
        "status" => "GENERATED",
        "instance_sha256" => result.instance_sha256,
        "spec" => _algorithmic_spec_payload(result.spec),
        "seed" => _algorithmic_seed_payload(result.seed),
        "requested" => _algorithmic_request_payload(result.requested),
        "realized" => _algorithmic_realized_payload(result.realized),
        "attempts" => _algorithmic_attempt_payload.(collect(result.attempts)),
    )
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end


function serialize_algorithmic_generation_record(result::AlgorithmicGenerationFailure)
    payload = Dict{String,Any}(
        "schema_version" => result.schema_version,
        "status" => string(result.status),
        "spec" => _algorithmic_spec_payload(result.spec),
        "seed" => _algorithmic_seed_payload(result.seed),
        "requested" => _algorithmic_request_payload(result.requested),
        "attempts" => _algorithmic_attempt_payload.(collect(result.attempts)),
    )
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end


algorithmic_generation_record_sha256(result) =
    bytes2hex(sha256(serialize_algorithmic_generation_record(result)))
