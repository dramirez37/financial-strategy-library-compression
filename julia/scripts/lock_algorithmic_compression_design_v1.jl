module LockAlgorithmicCompressionDesignV1

using Dates
using SHA: sha256
using StrategyInnovation
using TOML

export dry_run,
       freeze_design,
       instance_rows,
       main,
       render_instance_registry,
       render_seed_registry,
       seed_rows,
       validate_design,
       verify_design_lock,
       write_registries

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "algorithmic_compression_v1.toml",
)
const NONNEGATIVE_INT64_MASK = UInt64(0x7fffffffffffffff)
const GENERATOR_SALT = UInt64(0x243f6a8885a308d3)
const RANDOM_ORDER_SALT = UInt64(0xa4093822299f31d0)
const MULTISTART_SALT = UInt64(0x13198a2e03707344)
const MIP_SALT = UInt64(0x94d049bb133111eb)
const EXECUTION_SALT = UInt64(0xd1b54a32d192ed03)

const INSTANCE_COLUMNS = (
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

const SEED_COLUMNS = (
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

const ADVERSARIAL_MECHANISMS = (
    "unbounded_heaviest_safe_first_gap",
    "many_tied_optima",
    "dense_duplicate_coverage",
    "dominance_heavy",
    "rare_mandatory_requirements",
    "symmetric_hard",
    "bundle_versus_singleton",
)


_require(condition::Bool, message::AbstractString) =
    condition ? true : error(message)

_repo_path(path::AbstractString) =
    isabspath(path) ? normpath(path) :
    normpath(joinpath(REPOSITORY_ROOT, path))


function _sha256_file(path::AbstractString)
    return open(path, "r") do io
        bytes2hex(sha256(io))
    end
end


function _splitmix64(input::UInt64)
    mixed = input + UInt64(0x9e3779b97f4a7c15)
    mixed = (mixed ⊻ (mixed >> 30)) * UInt64(0xbf58476d1ce4e5b9)
    mixed = (mixed ⊻ (mixed >> 27)) * UInt64(0x94d049bb133111eb)
    return mixed ⊻ (mixed >> 31)
end


function _stable_seed(master::UInt64, index::Integer, salt::UInt64)
    value = _splitmix64(master ⊻ salt ⊻ UInt64(index)) &
            NONNEGATIVE_INT64_MASK
    return Int(iszero(value) ? one(UInt64) : value)
end


function _stable_mip_seed(master::UInt64, index::Integer)
    value = _splitmix64(master ⊻ MIP_SALT ⊻ UInt64(index)) %
            UInt64(typemax(Int32))
    return Int(value + one(UInt64))
end


function _row(;
    instance_id,
    phase,
    analysis_included,
    family,
    generator_id,
    replicate_id,
    strategy_count,
    tagged_requirement_count,
    frontier_row_count,
    module_row_count,
    coverage_density_level,
    module_overlap_level,
    bundle_prevalence_level,
    unique_carrier_frequency_level,
    weight_dispersion_level,
    frontier_module_correlation_level,
    mechanism = "none",
    mechanism_parameter = "none",
    exact_enumeration_required,
    exact_dp_required,
    mip_required = true,
)
    return (
        instance_id = String(instance_id),
        phase = String(phase),
        analysis_included = Bool(analysis_included),
        family = String(family),
        generator_id = String(generator_id),
        replicate_id = Int(replicate_id),
        strategy_count = Int(strategy_count),
        tagged_requirement_count = Int(tagged_requirement_count),
        frontier_row_count = Int(frontier_row_count),
        module_row_count = Int(module_row_count),
        coverage_density_level = String(coverage_density_level),
        module_overlap_level = String(module_overlap_level),
        bundle_prevalence_level = String(bundle_prevalence_level),
        unique_carrier_frequency_level =
            String(unique_carrier_frequency_level),
        weight_dispersion_level = String(weight_dispersion_level),
        frontier_module_correlation_level =
            String(frontier_module_correlation_level),
        mechanism = String(mechanism),
        mechanism_parameter = String(mechanism_parameter),
        seed_id = "SEED-$(String(instance_id))",
        exact_enumeration_required = Bool(exact_enumeration_required),
        exact_dp_required = Bool(exact_dp_required),
        mip_required = Bool(mip_required),
    )
end


function _dry_rows()
    return [
        _row(
            instance_id = "DRY-001",
            phase = "dry_run",
            analysis_included = false,
            family = "dry_run",
            generator_id = "trivial-mandatory-only-v1",
            replicate_id = 1,
            strategy_count = 2,
            tagged_requirement_count = 1,
            frontier_row_count = 1,
            module_row_count = 0,
            coverage_density_level = "trivial",
            module_overlap_level = "trivial",
            bundle_prevalence_level = "trivial",
            unique_carrier_frequency_level = "trivial",
            weight_dispersion_level = "trivial",
            frontier_module_correlation_level = "trivial",
            exact_enumeration_required = true,
            exact_dp_required = true,
        ),
        _row(
            instance_id = "DRY-002",
            phase = "dry_run",
            analysis_included = false,
            family = "dry_run",
            generator_id = "trivial-unique-module-v1",
            replicate_id = 1,
            strategy_count = 2,
            tagged_requirement_count = 2,
            frontier_row_count = 1,
            module_row_count = 1,
            coverage_density_level = "trivial",
            module_overlap_level = "trivial",
            bundle_prevalence_level = "trivial",
            unique_carrier_frequency_level = "all",
            weight_dispersion_level = "trivial",
            frontier_module_correlation_level = "trivial",
            exact_enumeration_required = true,
            exact_dp_required = true,
        ),
        _row(
            instance_id = "DRY-003",
            phase = "dry_run",
            analysis_included = false,
            family = "dry_run",
            generator_id = "trivial-triangle-v1",
            replicate_id = 1,
            strategy_count = 4,
            tagged_requirement_count = 4,
            frontier_row_count = 1,
            module_row_count = 3,
            coverage_density_level = "trivial",
            module_overlap_level = "symmetric",
            bundle_prevalence_level = "zero",
            unique_carrier_frequency_level = "zero",
            weight_dispersion_level = "none",
            frontier_module_correlation_level = "trivial",
            exact_enumeration_required = true,
            exact_dp_required = true,
        ),
    ]
end


function _pilot_rows()
    rows = NamedTuple[]
    for replicate in 1:2
        push!(
            rows,
            _row(
                instance_id = "P-A-$(lpad(string(replicate), 3, '0'))",
                phase = "pilot",
                analysis_included = false,
                family = "small_exact",
                generator_id = "small-exact-tagged-v1",
                replicate_id = replicate,
                strategy_count = 7,
                tagged_requirement_count = 6,
                frontier_row_count = 2,
                module_row_count = 4,
                coverage_density_level = isodd(replicate) ?
                    "one_eighth" : "three_eighths",
                module_overlap_level = isodd(replicate) ?
                    "low_clustered" : "high_clustered",
                bundle_prevalence_level = isodd(replicate) ?
                    "zero" : "one_eighth",
                unique_carrier_frequency_level = isodd(replicate) ?
                    "one_eighth" : "zero",
                weight_dispersion_level = isodd(replicate) ?
                    "low_1_to_3" : "high_powers_of_two",
                frontier_module_correlation_level = isodd(replicate) ?
                    "independent" : "positive_aligned",
                exact_enumeration_required = true,
                exact_dp_required = true,
            ),
        )
    end
    for replicate in 1:2
        frontier_rows = isodd(replicate) ? 4 : 8
        push!(
            rows,
            _row(
                instance_id = "P-B-$(lpad(string(replicate), 3, '0'))",
                phase = "pilot",
                analysis_included = false,
                family = "structured",
                generator_id = "structured-tagged-incidence-v1",
                replicate_id = replicate,
                strategy_count = 32,
                tagged_requirement_count = 16,
                frontier_row_count = frontier_rows,
                module_row_count = 16 - frontier_rows,
                coverage_density_level = isodd(replicate) ?
                    "one_eighth" : "three_eighths",
                module_overlap_level = isodd(replicate) ?
                    "low_clustered" : "high_clustered",
                bundle_prevalence_level = isodd(replicate) ?
                    "zero" : "one_eighth",
                unique_carrier_frequency_level = isodd(replicate) ?
                    "zero" : "one_eighth",
                weight_dispersion_level = isodd(replicate) ?
                    "low_1_to_3" : "high_powers_of_two",
                frontier_module_correlation_level = isodd(replicate) ?
                    "independent" : "positive_aligned",
                exact_enumeration_required = false,
                exact_dp_required = true,
            ),
        )
    end
    for (index, mechanism) in enumerate(ADVERSARIAL_MECHANISMS)
        metadata = _adversarial_metadata(mechanism, "small")
        push!(
            rows,
            _row(
                instance_id = "P-C-$(lpad(string(index), 3, '0'))",
                phase = "pilot",
                analysis_included = false,
                family = "adversarial",
                generator_id = "adversarial-mechanism-v1",
                replicate_id = 1,
                strategy_count = metadata.strategy_count,
                tagged_requirement_count =
                    metadata.tagged_requirement_count,
                frontier_row_count = 1,
                module_row_count = metadata.module_row_count,
                coverage_density_level = "mechanism",
                module_overlap_level = "mechanism",
                bundle_prevalence_level = "mechanism",
                unique_carrier_frequency_level = "mechanism",
                weight_dispersion_level = "mechanism",
                frontier_module_correlation_level = "mechanism",
                mechanism = mechanism,
                mechanism_parameter = metadata.parameter,
                exact_enumeration_required =
                    metadata.strategy_count - 1 <= 24,
                exact_dp_required =
                    metadata.tagged_requirement_count <= 24,
            ),
        )
    end
    return rows
end


function _family_a_rows(config)
    rows = NamedTuple[]
    strategy_counts = Int.(config["family_a"]["strategy_counts_including_inactive"])
    requirement_counts = Int.(config["family_a"]["tagged_requirement_counts"])
    frontier_counts = Int.(config["family_a"]["frontier_rows_by_requirement_count"])
    replicate_count = Int(config["family_a"]["replicates_per_size_cell"])
    for strategy_count in strategy_counts
        for (requirement_position, requirement_count) in
            enumerate(requirement_counts)
            frontier_count = frontier_counts[requirement_position]
            for replicate in 1:replicate_count
                density = replicate <= 2 ? "one_eighth" : "three_eighths"
                overlap = isodd(replicate) ?
                          "low_clustered" : "high_clustered"
                bundle = replicate in (2, 4) ? "one_eighth" : "zero"
                unique_level = replicate in (1, 4) ?
                               "one_eighth" : "zero"
                dispersion = replicate in (1, 3) ?
                             "low_1_to_3" : "high_powers_of_two"
                correlation = replicate in (1, 2) ?
                              "independent" : "positive_aligned"
                id = "A-N$(lpad(string(strategy_count), 3, '0'))-" *
                     "R$(lpad(string(requirement_count), 3, '0'))-" *
                     "X$(lpad(string(replicate), 2, '0'))"
                push!(
                    rows,
                    _row(
                        instance_id = id,
                        phase = "final",
                        analysis_included = true,
                        family = "small_exact",
                        generator_id = "small-exact-tagged-v1",
                        replicate_id = replicate,
                        strategy_count = strategy_count,
                        tagged_requirement_count = requirement_count,
                        frontier_row_count = frontier_count,
                        module_row_count = requirement_count - frontier_count,
                        coverage_density_level = density,
                        module_overlap_level = overlap,
                        bundle_prevalence_level = bundle,
                        unique_carrier_frequency_level = unique_level,
                        weight_dispersion_level = dispersion,
                        frontier_module_correlation_level = correlation,
                        exact_enumeration_required = true,
                        exact_dp_required = true,
                    ),
                )
            end
        end
    end
    return rows
end


_contrast_high(cell_code::Integer, mask::Integer) =
    isodd(count_ones(Int(cell_code) & Int(mask)))


function _family_b_rows(config)
    rows = NamedTuple[]
    section = config["family_b"]
    strategy_counts = Int.(section["strategy_counts_including_inactive"])
    requirement_counts = Int.(section["tagged_requirement_counts"])
    cell_count = Int(section["structure_cells"])
    replicate_count = Int(section["replicates_per_cell"])
    masks = Int.(section["base_contrast_masks"])
    _require(length(masks) == 7, "Family B needs seven contrast masks")
    for strategy_count in strategy_counts
        for requirement_count in requirement_counts
            for cell in 1:cell_count
                code = cell - 1
                high = [_contrast_high(code, mask) for mask in masks]
                frontier_count = high[1] ?
                                 requirement_count ÷ 2 :
                                 requirement_count ÷ 4
                levels = (
                    density = high[2] ? "three_eighths" : "one_eighth",
                    overlap = high[3] ? "high_clustered" : "low_clustered",
                    bundle = high[4] ? "one_eighth" : "zero",
                    unique_level = high[5] ? "one_eighth" : "zero",
                    dispersion = high[6] ?
                                 "high_powers_of_two" : "low_1_to_3",
                    correlation = high[7] ?
                                  "positive_aligned" : "independent",
                )
                for replicate in 1:replicate_count
                    id = "B-N$(lpad(string(strategy_count), 3, '0'))-" *
                         "R$(lpad(string(requirement_count), 3, '0'))-" *
                         "C$(lpad(string(cell), 2, '0'))-" *
                         "X$(lpad(string(replicate), 2, '0'))"
                    push!(
                        rows,
                        _row(
                            instance_id = id,
                            phase = "final",
                            analysis_included = true,
                            family = "structured",
                            generator_id =
                                "structured-tagged-incidence-v1",
                            replicate_id = replicate,
                            strategy_count = strategy_count,
                            tagged_requirement_count = requirement_count,
                            frontier_row_count = frontier_count,
                            module_row_count =
                                requirement_count - frontier_count,
                            coverage_density_level = levels.density,
                            module_overlap_level = levels.overlap,
                            bundle_prevalence_level = levels.bundle,
                            unique_carrier_frequency_level =
                                levels.unique_level,
                            weight_dispersion_level = levels.dispersion,
                            frontier_module_correlation_level =
                                levels.correlation,
                            exact_enumeration_required = false,
                            exact_dp_required = false,
                        ),
                    )
                end
            end
        end
    end
    return rows
end


function _adversarial_metadata(mechanism::AbstractString, scale::AbstractString)
    position = findfirst(==(String(scale)), ["small", "medium", "large"])
    isnothing(position) && error("unknown adversarial scale: $scale")
    if mechanism == "unbounded_heaviest_safe_first_gap"
        k = [4, 16, 64][position]
        return (
            strategy_count = k + 2,
            module_row_count = k,
            tagged_requirement_count = k + 1,
            parameter = "k=$k;epsilon=1//2",
        )
    elseif mechanism == "many_tied_optima"
        q = [4, 8, 16][position]
        return (
            strategy_count = q + 1,
            module_row_count = 4,
            tagged_requirement_count = 5,
            parameter = "q=$q",
        )
    elseif mechanism == "dense_duplicate_coverage"
        q = [8, 32, 128][position]
        module_count = [4, 16, 32][position]
        return (
            strategy_count = q + 1,
            module_row_count = module_count,
            tagged_requirement_count = module_count + 1,
            parameter = "duplicates=$q;modules=$module_count",
        )
    elseif mechanism == "dominance_heavy"
        q = [4, 12, 32][position]
        return (
            strategy_count = 2 * q + 1,
            module_row_count = q,
            tagged_requirement_count = q + 1,
            parameter = "base_dimension=$q",
        )
    elseif mechanism == "rare_mandatory_requirements"
        q = [4, 16, 64][position]
        return (
            strategy_count = q + 2,
            module_row_count = q,
            tagged_requirement_count = q + 1,
            parameter = "modules=$q;rare_rows=1",
        )
    elseif mechanism == "symmetric_hard"
        q = [7, 15, 31][position]
        return (
            strategy_count = q + 1,
            module_row_count = q,
            tagged_requirement_count = q + 1,
            parameter = "cyclic_order=$q",
        )
    elseif mechanism == "bundle_versus_singleton"
        q = [4, 16, 64][position]
        return (
            strategy_count = q + 3,
            module_row_count = q,
            tagged_requirement_count = q + 1,
            parameter = "k=$q;bundles=2",
        )
    end
    error("unknown adversarial mechanism: $mechanism")
end


function _family_c_rows(config)
    rows = NamedTuple[]
    scales = String.(config["family_c"]["scale_labels"])
    mechanisms = String.(config["family_c"]["mechanisms"])
    for (mechanism_index, mechanism) in enumerate(mechanisms)
        for (scale_index, scale) in enumerate(scales)
            metadata = _adversarial_metadata(mechanism, scale)
            id = "C-M$(lpad(string(mechanism_index), 2, '0'))-" *
                 "S$(lpad(string(scale_index), 2, '0'))"
            push!(
                rows,
                _row(
                    instance_id = id,
                    phase = "final",
                    analysis_included = true,
                    family = "adversarial",
                    generator_id = "adversarial-mechanism-v1",
                    replicate_id = 1,
                    strategy_count = metadata.strategy_count,
                    tagged_requirement_count =
                        metadata.tagged_requirement_count,
                    frontier_row_count = 1,
                    module_row_count = metadata.module_row_count,
                    coverage_density_level = "mechanism",
                    module_overlap_level = "mechanism",
                    bundle_prevalence_level = "mechanism",
                    unique_carrier_frequency_level = "mechanism",
                    weight_dispersion_level = "mechanism",
                    frontier_module_correlation_level = "mechanism",
                    mechanism = mechanism,
                    mechanism_parameter = metadata.parameter,
                    exact_enumeration_required =
                        metadata.strategy_count - 1 <= 24,
                    exact_dp_required =
                        metadata.tagged_requirement_count <= 24,
                ),
            )
        end
    end
    return rows
end


"""Construct the complete dry-run, pilot, and final instance registry."""
function instance_rows(config::AbstractDict)
    rows = NamedTuple[]
    append!(rows, _dry_rows())
    append!(rows, _pilot_rows())
    append!(rows, _family_a_rows(config))
    append!(rows, _family_b_rows(config))
    append!(rows, _family_c_rows(config))
    return rows
end


function _phase_master_seed(config, phase::AbstractString)
    key = phase == "dry_run" ? "dry_run_master_seed" :
          phase == "pilot" ? "pilot_master_seed" : "final_master_seed"
    return UInt64(config["seeds"][key])
end


"""Derive all registered random streams from phase-separated master seeds."""
function seed_rows(config::AbstractDict)
    rows = NamedTuple[]
    phase_indices = Dict("dry_run" => 0, "pilot" => 0, "final" => 0)
    for instance in instance_rows(config)
        phase_indices[instance.phase] += 1
        index = phase_indices[instance.phase]
        master = _phase_master_seed(config, instance.phase)
        scope = instance.family == "adversarial" ?
                "label_permutation_and_stochastic_algorithms" :
                instance.phase == "dry_run" ?
                "dry_run_algorithms_only" :
                "instance_generation_and_stochastic_algorithms"
        push!(
            rows,
            (
                seed_id = instance.seed_id,
                instance_id = instance.instance_id,
                phase = instance.phase,
                replicate_id = instance.replicate_id,
                execution_order_key =
                    _stable_seed(master, index, EXECUTION_SALT),
                generator_seed =
                    _stable_seed(master, index, GENERATOR_SALT),
                random_order_seed =
                    _stable_seed(master, index, RANDOM_ORDER_SALT),
                multistart_seed =
                    _stable_seed(master, index, MULTISTART_SALT),
                mip_seed = _stable_mip_seed(master, index),
                randomness_scope = scope,
            ),
        )
    end
    return rows
end


function _csv_cell(value)
    text = value isa Bool ? lowercase(string(value)) : string(value)
    (occursin(',', text) || occursin('\n', text) || occursin('\r', text)) &&
        error("registry value requires unsupported CSV escaping: $(repr(text))")
    return text
end


function _render_registry(rows, columns)
    io = IOBuffer()
    println(io, join(string.(columns), ","))
    for row in rows
        println(
            io,
            join(
                (_csv_cell(getproperty(row, column)) for column in columns),
                ",",
            ),
        )
    end
    return String(take!(io))
end


render_instance_registry(config::AbstractDict) =
    _render_registry(instance_rows(config), INSTANCE_COLUMNS)

render_seed_registry(config::AbstractDict) =
    _render_registry(seed_rows(config), SEED_COLUMNS)


function _validate_family_b(config, rows)
    structured = filter(
        row -> row.phase == "final" && row.family == "structured",
        rows,
    )
    _require(length(structured) == 128, "Family B row count changed")
    fields = (
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
    )
    for field in fields
        _require(
            length(unique(getproperty(row, field) for row in structured)) >= 2,
            "Family B does not vary $field",
        )
    end
    for strategy_count in Int.(config["family_b"]["strategy_counts_including_inactive"])
        for requirement_count in Int.(config["family_b"]["tagged_requirement_counts"])
            size_rows = filter(
                row -> row.strategy_count == strategy_count &&
                       row.tagged_requirement_count == requirement_count,
                structured,
            )
            _require(length(size_rows) == 32, "Family B size cell is not N=32")
            factor_fields = (
                :frontier_row_count,
                :coverage_density_level,
                :module_overlap_level,
                :bundle_prevalence_level,
                :unique_carrier_frequency_level,
                :weight_dispersion_level,
                :frontier_module_correlation_level,
            )
            for field in factor_fields
                counts = sort(collect(values(countmap(
                    getproperty(row, field) for row in size_rows
                ))))
                _require(counts == [16, 16], "Family B factor $field is unbalanced")
            end
            for left in 1:(length(factor_fields) - 1)
                for right in (left + 1):length(factor_fields)
                    pairs = countmap(
                        (
                            getproperty(row, factor_fields[left]),
                            getproperty(row, factor_fields[right]),
                        ) for row in size_rows
                    )
                    _require(
                        sort(collect(values(pairs))) == [8, 8, 8, 8],
                        "Family B factors $(factor_fields[left]) and " *
                        "$(factor_fields[right]) are not pairwise balanced",
                    )
                end
            end
        end
    end
    return true
end


function countmap(values)
    counts = Dict{Any,Int}()
    for value in values
        counts[value] = get(counts, value, 0) + 1
    end
    return counts
end


function _validate_rows(config, rows)
    counts = config["counts"]
    _require(
        count(row -> row.phase == "dry_run", rows) ==
        Int(counts["dry_run_instances"]),
        "dry-run row count changed",
    )
    _require(
        count(row -> row.phase == "pilot", rows) ==
        Int(counts["pilot_instances"]),
        "pilot row count changed",
    )
    final_rows = filter(row -> row.phase == "final", rows)
    _require(
        length(final_rows) == Int(counts["final_instances"]),
        "final registry row count changed",
    )
    _require(
        count(row -> row.family == "small_exact", final_rows) ==
        Int(counts["final_small_exact"]),
        "Family A count changed",
    )
    _require(
        count(row -> row.family == "structured", final_rows) ==
        Int(counts["final_structured"]),
        "Family B count changed",
    )
    _require(
        count(row -> row.family == "adversarial", final_rows) ==
        Int(counts["final_adversarial"]),
        "Family C count changed",
    )
    _require(
        length(unique(row.instance_id for row in rows)) == length(rows),
        "instance identifiers are not unique",
    )
    _require(
        length(unique(row.seed_id for row in rows)) == length(rows),
        "seed identifiers are not unique",
    )
    for row in rows
        _require(row.strategy_count >= 2, "$(row.instance_id) has too few strategies")
        _require(
            row.tagged_requirement_count ==
            row.frontier_row_count + row.module_row_count,
            "$(row.instance_id) requirement partition does not add up",
        )
        _require(row.frontier_row_count >= 1, "$(row.instance_id) has no frontier row")
        _require(row.module_row_count >= 0, "$(row.instance_id) has negative module rows")
        _require(
            row.analysis_included == (row.phase == "final"),
            "$(row.instance_id) analysis flag disagrees with phase",
        )
        _require(row.mip_required, "$(row.instance_id) does not require MIP")
    end
    small = filter(
        row -> row.phase == "final" && row.family == "small_exact",
        rows,
    )
    _require(
        all(row.exact_enumeration_required && row.exact_dp_required for row in small),
        "Family A must require both exact methods",
    )
    adversarial = filter(
        row -> row.phase == "final" && row.family == "adversarial",
        rows,
    )
    _require(
        Set(row.mechanism for row in adversarial) == Set(ADVERSARIAL_MECHANISMS),
        "adversarial mechanism set changed",
    )
    for mechanism in ADVERSARIAL_MECHANISMS
        _require(
            count(row -> row.mechanism == mechanism, adversarial) == 3,
            "adversarial mechanism $mechanism does not have three scales",
        )
    end
    _validate_family_b(config, rows)
    return true
end


function _validate_seeds(rows, seeds)
    _require(length(rows) == length(seeds), "seed and instance counts differ")
    for (instance, seed) in zip(rows, seeds)
        _require(seed.seed_id == instance.seed_id, "seed registry order changed")
        _require(seed.instance_id == instance.instance_id, "seed instance mismatch")
        _require(seed.phase == instance.phase, "seed phase mismatch")
        _require(seed.replicate_id == instance.replicate_id, "seed replicate mismatch")
        _require(0 < seed.mip_seed <= typemax(Int32), "invalid MIP seed")
    end
    seed_fields = (
        :execution_order_key,
        :generator_seed,
        :random_order_seed,
        :multistart_seed,
        :mip_seed,
    )
    for field in seed_fields
        values = getproperty.(seeds, field)
        _require(all(>(0), values), "$field contains a nonpositive value")
        _require(length(unique(values)) == length(values), "$field repeats")
    end
    all_values = reduce(vcat, [getproperty.(seeds, field) for field in seed_fields])
    _require(length(unique(all_values)) == length(all_values), "seed domains collide")
    pilot_values = Set(
        value for row in seeds if row.phase == "pilot" for
        value in (
            row.execution_order_key,
            row.generator_seed,
            row.random_order_seed,
            row.multistart_seed,
            row.mip_seed,
        )
    )
    final_values = Set(
        value for row in seeds if row.phase == "final" for
        value in (
            row.execution_order_key,
            row.generator_seed,
            row.random_order_seed,
            row.multistart_seed,
            row.mip_seed,
        )
    )
    _require(isempty(intersect(pilot_values, final_values)), "pilot and final seeds overlap")
    return true
end


function _validate_files_and_outputs(
    config;
    require_registries::Bool,
    require_outputs_absent::Bool,
)
    registry_paths = Set(
        [
            String(config["registries"]["instance_path"]),
            String(config["registries"]["seed_path"]),
        ],
    )
    for path in String.(config["design_lock"]["required_files"])
        !require_registries && path in registry_paths && continue
        _require(isfile(_repo_path(path)), "design-lock input is absent: $path")
    end
    if require_outputs_absent
        present = sort(
            collect(
                path for path in
                String.(config["design_lock"]["required_absent_outputs"]) if
                ispath(_repo_path(path))
            ),
        )
        _require(
            isempty(present),
            "pilot or final output exists before lock: $(join(present, ", "))",
        )
    end
    return true
end


"""Validate config, deterministic registries, balance, seeds, and lock inputs."""
function validate_design(
    config::AbstractDict;
    require_registries::Bool = true,
    require_outputs_absent::Bool = false,
)
    _require(
        config["schema_version"] ==
        "registered-algorithmic-compression-benchmark-v1",
        "unsupported algorithmic benchmark schema",
    )
    _require(
        config["registration_status"] ==
        "prospective_design_outcomes_not_run",
        "benchmark is not in the prospective no-outcome state",
    )
    _require(config["julia_version"] == "1.12.6", "Julia version changed")
    _require(config["identity_closure_only"] === true, "closure scope changed")
    _require(config["theorem_evidence"] === false, "benchmark cannot be theorem evidence")
    _require(
        config["population_claims_about_financial_libraries"] === false,
        "financial-population nonclaim changed",
    )
    _require(
        config["final_benchmark_run_in_this_task"] === false,
        "config improperly authorizes a final run",
    )
    counts = config["counts"]
    _require(
        Int(counts["final_instances"]) ==
        Int(counts["final_small_exact"]) +
        Int(counts["final_structured"]) +
        Int(counts["final_adversarial"]),
        "final family counts do not sum to final N",
    )
    _require(
        Int(counts["final_structured"]) ==
        Int(counts["structured_design_cells"]) *
        Int(counts["structured_replicates_per_cell"]),
        "structured design count is inconsistent",
    )
    _require(
        Int(counts["final_adversarial"]) ==
        Int(counts["adversarial_mechanisms"]) *
        Int(counts["adversarial_scales_per_mechanism"]),
        "adversarial design count is inconsistent",
    )
    master_seeds = Int[
        config["seeds"]["dry_run_master_seed"],
        config["seeds"]["pilot_master_seed"],
        config["seeds"]["final_master_seed"],
    ]
    _require(length(unique(master_seeds)) == 3, "phase master seeds overlap")
    _require(
        Int(config["seeds"]["maximum_generator_attempts"]) == 128,
        "generator attempt limit changed",
    )
    _require(
        Int(config["seeds"]["random_multistart_count"]) == 32,
        "multistart count changed",
    )
    _require(
        config["seeds"]["unrecorded_random_streams_permitted"] === false,
        "unrecorded random streams are permitted",
    )
    _require(
        config["peeking"]["interim_final_analysis_permitted"] === false,
        "interim final analysis is permitted",
    )
    _require(
        config["failure"]["failed_instances_replaced"] === false,
        "failed instance replacement is permitted",
    )
    _require(
        config["failure"]["disagreements_retained"] === true &&
        config["failure"]["minimized_failure_fixture_required"] === true,
        "disagreement preservation changed",
    )
    _require(
        config["solver"]["highs"]["threads"] == 1 &&
        config["solver"]["highs"]["parallel"] == "off",
        "HiGHS deterministic settings changed",
    )
    _require(
        config["limits"]["small"]["memory_gib_per_process"] == 16 &&
        config["limits"]["medium"]["memory_gib_per_process"] == 16 &&
        config["limits"]["large"]["memory_gib_per_process"] == 16,
        "registered memory limit changed",
    )
    expected_algorithms = Set(
        [
            "exact_enumeration",
            "exact_dp",
            "mip",
            "weighted_greedy",
            "cardinality_greedy",
            "weighted_greedy_reverse_delete",
            "heaviest_safe_first",
            "lightest_safe_first",
            "maximum_immediate_burden_release",
            "minimum_unique_carrier_exposure",
            "declared_source_order",
            "random_order",
            "multistart_random",
        ],
    )
    _require(
        Set(String.(collect(keys(config["algorithms"])))) == expected_algorithms,
        "registered algorithm set changed",
    )
    expected_primary = Set(
        [
            "relative_burden_gap",
            "optimum_attainment_frequency",
            "solved_fraction",
            "wall_clock_time",
            "mip_node_count",
            "dp_state_count",
            "preprocessing_reduction",
            "frontier_closure_evaluation_count",
        ],
    )
    _require(
        Set(String.(config["analysis"]["primary_estimands"])) ==
        expected_primary,
        "primary estimand set changed",
    )
    output_paths = Set(String.(collect(values(config["outputs"]))))
    absent_paths = Set(String.(config["design_lock"]["required_absent_outputs"]))
    _require(
        output_paths == absent_paths,
        "required-absent paths differ from registered outputs",
    )
    _require(
        config["design_lock"]["pilot_outcomes_read_before_lock"] === false &&
        config["design_lock"]["final_outcomes_read_before_lock"] === false,
        "pre-lock outcome attestation changed",
    )
    _require(
        config["amendments"]["silent_edits_forbidden"] === true &&
        config["amendments"]["must_preserve_prior_lock"] === true,
        "amendment safeguards changed",
    )
    _require(
        String.(config["registries"]["instance_columns"]) ==
        collect(string.(INSTANCE_COLUMNS)),
        "instance registry column schema changed",
    )
    _require(
        String.(config["registries"]["seed_columns"]) ==
        collect(string.(SEED_COLUMNS)),
        "seed registry column schema changed",
    )
    rows = instance_rows(config)
    seeds = seed_rows(config)
    _validate_rows(config, rows)
    _validate_seeds(rows, seeds)
    _validate_files_and_outputs(
        config;
        require_registries,
        require_outputs_absent,
    )
    if require_registries
        instance_path = _repo_path(config["registries"]["instance_path"])
        seed_path = _repo_path(config["registries"]["seed_path"])
        _require(isfile(instance_path), "instance registry is absent")
        _require(isfile(seed_path), "seed registry is absent")
        _require(
            read(instance_path, String) == render_instance_registry(config),
            "instance registry differs from deterministic design",
        )
        _require(
            read(seed_path, String) == render_seed_registry(config),
            "seed registry differs from deterministic design",
        )
    end
    return (
        total_instances = length(rows),
        dry_run_instances = count(row -> row.phase == "dry_run", rows),
        pilot_instances = count(row -> row.phase == "pilot", rows),
        final_instances = count(row -> row.phase == "final", rows),
        registered_seed_values = 5 * length(seeds),
    )
end


function _write_exact(path, contents, label)
    if isfile(path)
        _require(read(path, String) == contents, "refusing to overwrite mismatched $label")
    else
        mkpath(dirname(path))
        open(path, "w") do io
            write(io, contents)
        end
    end
    return path
end


"""Write both deterministic registries without instantiating a benchmark row."""
function write_registries(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    validation = validate_design(config; require_registries = false)
    instance_path = _repo_path(config["registries"]["instance_path"])
    seed_path = _repo_path(config["registries"]["seed_path"])
    _write_exact(
        instance_path,
        render_instance_registry(config),
        "instance registry",
    )
    _write_exact(seed_path, render_seed_registry(config), "seed registry")
    validate_design(config)
    println(
        "registered $(validation.total_instances) rows: " *
        "dry=$(validation.dry_run_instances), " *
        "pilot=$(validation.pilot_instances), " *
        "final=$(validation.final_instances)",
    )
    return (; instance_path, seed_path)
end


function _dry_instance(row)
    provenance = JournalCompressionProvenance(
        :synthetic,
        row.instance_id,
        "pre-lock trivial schema-and-solver dry run";
        generator = row.generator_id,
        attributes = [
            "phase" => "dry_run",
            "analysis_included" => "false",
        ],
    )
    if row.instance_id == "DRY-001"
        return journal_compression_instance_from_components(
            [:inactive, :unused],
            Bool[true, false],
            [0, 7],
            [:zero],
            zeros(Int, 2, 1),
            [Symbol[], Symbol[]];
            provenance,
        ), 0 // 1
    elseif row.instance_id == "DRY-002"
        return journal_compression_instance_from_components(
            [:inactive, :carrier],
            Bool[true, false],
            [0, 2],
            [:zero],
            zeros(Int, 2, 1),
            [Symbol[], [:m]];
            provenance,
        ), 2 // 1
    elseif row.instance_id == "DRY-003"
        return journal_compression_instance_from_components(
            [:inactive, :a, :b, :c],
            Bool[true, false, false, false],
            [0, 1, 1, 1],
            [:zero],
            zeros(Int, 4, 1),
            [Symbol[], [:m1, :m2], [:m2, :m3], [:m1, :m3]];
            provenance,
        ), 2 // 1
    end
    error("unregistered dry-run fixture: $(row.instance_id)")
end


"""Run only the three registered trivial in-memory fixtures; write no result."""
function dry_run(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    validate_design(
        config;
        require_registries = true,
        require_outputs_absent = true,
    )
    seeds = Dict(row.instance_id => row for row in seed_rows(config))
    results = NamedTuple[]
    for row in filter(instance -> instance.phase == "dry_run", instance_rows(config))
        instance, expected_burden = _dry_instance(row)
        serialized = serialize_journal_compression_instance(instance)
        restored = deserialize_journal_compression_instance(serialized)
        _require(
            serialize_journal_compression_instance(restored) == serialized,
            "$(row.instance_id) schema round trip changed",
        )
        audit = audit_journal_small_instance(
            restored;
            random_seed = seeds[row.instance_id].mip_seed,
            time_limit = 10.0,
            maximum_optional_strategies = 8,
            maximum_ties = 100,
            minimize_failure = false,
        )
        _require(audit.passed, "$(row.instance_id) exactness dry run failed")
        _require(
            audit.enumeration.exact_burden == expected_burden &&
            audit.dynamic_programming.exact_burden == expected_burden &&
            audit.mip.exact_burden == expected_burden,
            "$(row.instance_id) dry-run burden changed",
        )
        push!(
            results,
            (
                instance_id = row.instance_id,
                passed = true,
                exact_burden = expected_burden,
            ),
        )
    end
    _require(length(results) == 3, "dry-run fixture count changed")
    println("trivial dry run passed for DRY-001, DRY-002, and DRY-003; no outputs written")
    return results
end


function _design_hashes(config)
    paths = String.(config["design_lock"]["required_files"])
    hashes = Dict{String,String}()
    for path in paths
        full_path = _repo_path(path)
        _require(isfile(full_path), "design-lock input is absent: $path")
        hashes[path] = _sha256_file(full_path)
    end
    aggregate = bytes2hex(
        sha256(join(("$path:$(hashes[path])" for path in paths), "\n")),
    )
    return (; paths, hashes, aggregate)
end


_json_escape(value::AbstractString) =
    replace(value, "\\" => "\\\\", "\"" => "\\\"")


function _lock_text(config, design, validation, locked_at)
    file_rows = join(
        (
            "    \"$(_json_escape(path))\": \"$(design.hashes[path])\"" for
            path in design.paths
        ),
        ",\n",
    )
    return """{
  \"schema_version\": \"$(config["design_lock"]["schema_version"])\",
  \"experiment_id\": \"$(config["experiment_id"])\",
  \"study_title\": \"$(config["study_title"])\",
  \"locked_at_utc\": \"$locked_at\",
  \"lock_stage\": \"$(config["design_lock"]["lock_stage"])\",
  \"pilot_outcomes_read_before_lock\": false,
  \"final_outcomes_read_before_lock\": false,
  \"outcome_files_absent_at_lock\": true,
  \"dry_run_trivial_only\": true,
  \"dry_run_fixture_count\": 3,
  \"pilot_instance_count\": $(validation.pilot_instances),
  \"final_instance_count\": $(validation.final_instances),
  \"registered_seed_value_count\": $(validation.registered_seed_values),
  \"design_sha256\": \"$(design.aggregate)\",
  \"files\": {
$file_rows
  }
}
"""
end


"""Validate, run trivial dry fixtures, attest output absence, then freeze."""
function freeze_design(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    validation = validate_design(
        config;
        require_registries = true,
        require_outputs_absent = true,
    )
    dry_run(config_path)
    lock_path = _repo_path(config["design_lock"]["path"])
    _require(
        !isfile(lock_path),
        "initial algorithmic benchmark lock exists; verify instead of overwriting",
    )
    design = _design_hashes(config)
    locked_at = Dates.format(
        Dates.now(Dates.UTC),
        dateformat"yyyy-mm-ddTHH:MM:SSZ",
    )
    mkpath(dirname(lock_path))
    open(lock_path, "w") do io
        write(io, _lock_text(config, design, validation, locked_at))
    end
    println(
        "locked algorithmic compression benchmark design=$(design.aggregate) " *
        "before pilot and final outcomes at $locked_at",
    )
    return design.aggregate
end


"""Recompute every input hash and verify the immutable initial lock."""
function verify_design_lock(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    validation = validate_design(config; require_registries = true)
    lock_path = _repo_path(config["design_lock"]["path"])
    _require(isfile(lock_path), "algorithmic benchmark design lock is absent")
    text = read(lock_path, String)
    design = _design_hashes(config)
    fragments = (
        "\"pilot_outcomes_read_before_lock\": false",
        "\"final_outcomes_read_before_lock\": false",
        "\"outcome_files_absent_at_lock\": true",
        "\"dry_run_trivial_only\": true",
        "\"dry_run_fixture_count\": 3",
        "\"pilot_instance_count\": $(validation.pilot_instances)",
        "\"final_instance_count\": $(validation.final_instances)",
        "\"registered_seed_value_count\": $(validation.registered_seed_values)",
        "\"design_sha256\": \"$(design.aggregate)\"",
    )
    for fragment in fragments
        _require(occursin(fragment, text), "design lock is missing: $fragment")
    end
    for path in design.paths
        fragment = "\"$(_json_escape(path))\": \"$(design.hashes[path])\""
        _require(occursin(fragment, text), "design lock is stale for $path")
    end
    println(
        "algorithmic benchmark design lock current: $(design.aggregate); " *
        "final_N=$(validation.final_instances)",
    )
    return design.aggregate
end


function main(args = ARGS)
    positional = [argument for argument in args if !startswith(argument, "--")]
    length(positional) <= 1 || error(
        "usage: lock_algorithmic_compression_design_v1.jl [config] " *
        "[--write-registries|--validate|--dry-run|--freeze|--check]",
    )
    config_path = isempty(positional) ? DEFAULT_CONFIG : only(positional)
    modes = filter(
        argument -> argument in (
            "--write-registries",
            "--validate",
            "--dry-run",
            "--freeze",
            "--check",
        ),
        args,
    )
    length(modes) <= 1 || error("choose exactly one design-lock mode")
    mode = isempty(modes) ? "--check" : only(modes)
    if mode == "--write-registries"
        return write_registries(config_path)
    elseif mode == "--validate"
        config = TOML.parsefile(config_path)
        result = validate_design(
            config;
            require_registries = true,
            require_outputs_absent = true,
        )
        println(
            "algorithmic benchmark schema valid: total=$(result.total_instances), " *
            "final=$(result.final_instances), seeds=$(result.registered_seed_values)",
        )
        return result
    elseif mode == "--dry-run"
        return dry_run(config_path)
    elseif mode == "--freeze"
        return freeze_design(config_path)
    end
    return verify_design_lock(config_path)
end


if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
