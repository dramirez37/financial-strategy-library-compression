using TOML


function _algorithmic_copy_spec(spec; kwargs...)
    values = Dict{Symbol,Any}(
        name => getfield(spec, name) for name in fieldnames(AlgorithmicBenchmarkInstanceSpec)
    )
    merge!(values, Dict{Symbol,Any}(kwargs))
    return AlgorithmicBenchmarkInstanceSpec(
        (values[name] for name in fieldnames(AlgorithmicBenchmarkInstanceSpec))...,
    )
end


function _algorithmic_copy_seed(seed; kwargs...)
    values = Dict{Symbol,Any}(
        name => getfield(seed, name) for name in fieldnames(AlgorithmicBenchmarkSeedSpec)
    )
    merge!(values, Dict{Symbol,Any}(kwargs))
    return AlgorithmicBenchmarkSeedSpec(
        (values[name] for name in fieldnames(AlgorithmicBenchmarkSeedSpec))...,
    )
end


function _algorithmic_custom_pair(base, suffix; spec_updates...)
    instance_id = base.spec.instance_id * "-" * suffix
    spec = _algorithmic_copy_spec(
        base.spec;
        instance_id,
        seed_id = "SEED-" * instance_id,
        spec_updates...,
    )
    seed = _algorithmic_copy_seed(
        base.seed;
        instance_id,
        seed_id = spec.seed_id,
    )
    return (; spec, seed)
end


function _algorithmic_direct_cover_feasible(instance, selected)
    mandatory = all(
        !instance.mandatory[column] || selected[column] for column in eachindex(selected)
    )
    covered = all(
        any(
            selected[column] && instance.coverage[row, column] for
            column in eachindex(selected)
        ) for row in axes(instance.coverage, 1)
    )
    return mandatory && covered
end


@testset "registered algorithmic compression registries" begin
    registries = load_algorithmic_benchmark_registries()
    @test length(registries.instances) == 187
    @test length(registries.seeds) == 187
    @test count(spec -> spec.phase == :dry_run, registries.instances) == 3
    @test count(spec -> spec.phase == :pilot, registries.instances) == 11
    @test count(spec -> spec.phase == :final, registries.instances) == 173
    pilot = Set{UInt64}()
    final = Set{UInt64}()
    for seed in registries.seeds
        values = (
            seed.generator_seed,
            seed.random_order_seed,
            seed.multistart_seed,
            seed.mip_seed,
        )
        seed.phase == :pilot && union!(pilot, values)
        seed.phase == :final && union!(final, values)
    end
    @test isempty(intersect(pilot, final))
    @test_throws ArgumentError generate_algorithmic_benchmark_instance(
        "A-N007-R006-X01",
    )
end


@testset "generator schema, carrier, and reproducibility checks" begin
    example_ids = [
        "DRY-001",
        "DRY-002",
        "DRY-003",
        "P-A-001",
        "P-A-002",
        "P-B-001",
        "P-B-002",
        ["P-C-" * lpad(string(index), 3, '0') for index in 1:7]...,
    ]
    for instance_id in example_ids
        first_result = generate_algorithmic_benchmark_instance(instance_id)
        second_result = generate_algorithmic_benchmark_instance(instance_id)
        @test first_result isa AlgorithmicGeneratedInstance
        @test second_result isa AlgorithmicGeneratedInstance
        @test validate_journal_compression_instance(first_result.instance) ===
              first_result.instance
        @test all(
            any(first_result.instance.coverage[row, :]) for
            row in axes(first_result.instance.coverage, 1)
        )
        @test first_result.instance == second_result.instance
        @test deserialize_journal_compression_instance(
            serialize_journal_compression_instance(first_result.instance),
        ) == first_result.instance
        @test first_result.instance_sha256 == second_result.instance_sha256
        serialized_record = serialize_algorithmic_generation_record(first_result)
        @test serialized_record == serialize_algorithmic_generation_record(second_result)
        parsed_record = TOML.parse(serialized_record)
        @test parsed_record["requested"]["strategy_count"] ==
              first_result.requested.strategy_count
        @test parsed_record["realized"]["active_coverage_density"] ==
              string(first_result.realized.active_coverage_density)
        @test parsed_record["seed"]["generator_seed"] ==
              string(first_result.seed.generator_seed)
        @test algorithmic_generation_record_sha256(first_result) ==
              algorithmic_generation_record_sha256(second_result)
        @test algorithmic_structural_statistics(first_result.instance) ==
              first_result.realized
        @test all(weight -> weight isa ExactRational, first_result.instance.weights)
        @test first_result.spec.phase != :final
    end
end


@testset "requested and realized structural controls" begin
    sparse = generate_algorithmic_benchmark_instance("P-B-001")
    dense = generate_algorithmic_benchmark_instance("P-B-002")
    @test sparse.realized.active_coverage_density == 1 // 8
    @test dense.realized.active_coverage_density == 3 // 8
    @test sparse.realized.bundle_count == sparse.requested.bundle_count_target == 0
    @test dense.realized.bundle_count == dense.requested.bundle_count_target == 4
    @test sparse.realized.unique_carrier_count ==
          sparse.requested.unique_carrier_count_target == 0
    @test dense.realized.unique_carrier_count ==
          dense.requested.unique_carrier_count_target == 2
    @test all(
        id -> id in dense.realized.preprocessing_forced_strategy_ids,
        dense.realized.unique_carrier_strategy_ids,
    )
    @test sparse.realized.distinct_active_weights == (1 // 1, 2 // 1, 3 // 1)
    @test dense.realized.distinct_active_weights ==
          (1 // 1, 2 // 1, 4 // 1, 8 // 1, 16 // 1)

    sparse_row = algorithmic_benchmark_registry_entry("P-B-001")
    alternate_seed_row = _algorithmic_custom_pair(sparse_row, "ALTERNATE-SEED")
    alternate_seed = _algorithmic_copy_seed(
        alternate_seed_row.seed;
        generator_seed = alternate_seed_row.seed.generator_seed + UInt64(1),
    )
    alternate = generate_algorithmic_benchmark_instance(
        alternate_seed_row.spec,
        alternate_seed,
    )
    @test alternate isa AlgorithmicGeneratedInstance
    @test alternate.instance_sha256 != sparse.instance_sha256
    @test algorithmic_generation_record_sha256(alternate) !=
          algorithmic_generation_record_sha256(sparse)

    base = algorithmic_benchmark_registry_entry("P-B-002")
    low_overlap_row = _algorithmic_custom_pair(
        base,
        "LOW-OVERLAP";
        module_overlap_level = :low_clustered,
    )
    high_overlap_row = _algorithmic_custom_pair(
        base,
        "HIGH-OVERLAP";
        module_overlap_level = :high_clustered,
    )
    low_overlap = generate_algorithmic_benchmark_instance(
        low_overlap_row.spec,
        low_overlap_row.seed,
    )
    high_overlap = generate_algorithmic_benchmark_instance(
        high_overlap_row.spec,
        high_overlap_row.seed,
    )
    @test low_overlap isa AlgorithmicGeneratedInstance
    @test high_overlap isa AlgorithmicGeneratedInstance
    @test high_overlap.realized.mean_pairwise_module_jaccard >=
          low_overlap.realized.mean_pairwise_module_jaccard

    independent_row = _algorithmic_custom_pair(
        base,
        "INDEPENDENT";
        frontier_module_correlation_level = :independent,
    )
    aligned_row = _algorithmic_custom_pair(
        base,
        "ALIGNED";
        frontier_module_correlation_level = :positive_aligned,
    )
    independent = generate_algorithmic_benchmark_instance(
        independent_row.spec,
        independent_row.seed,
    )
    aligned = generate_algorithmic_benchmark_instance(aligned_row.spec, aligned_row.seed)
    @test independent isa AlgorithmicGeneratedInstance
    @test aligned isa AlgorithmicGeneratedInstance
    @test independent.realized.frontier_module_rank_association isa ExactRational
    @test aligned.realized.frontier_module_rank_association isa ExactRational

    homogeneous_row = _algorithmic_custom_pair(
        base,
        "HOMOGENEOUS";
        weight_dispersion_level = :homogeneous,
    )
    heterogeneous_row = _algorithmic_custom_pair(
        base,
        "HETEROGENEOUS";
        weight_dispersion_level = :heterogeneous,
    )
    homogeneous = generate_algorithmic_benchmark_instance(
        homogeneous_row.spec,
        homogeneous_row.seed,
    )
    heterogeneous = generate_algorithmic_benchmark_instance(
        heterogeneous_row.spec,
        heterogeneous_row.seed,
    )
    @test homogeneous.realized.distinct_active_weights == (1 // 1,)
    @test length(heterogeneous.realized.distinct_active_weights) == 5
end


@testset "adversarial mechanisms and declared mandatory structure" begin
    tied = generate_algorithmic_benchmark_instance("P-C-002")
    duplicate = generate_algorithmic_benchmark_instance("P-C-003")
    dominance = generate_algorithmic_benchmark_instance("P-C-004")
    rare = generate_algorithmic_benchmark_instance("P-C-005")
    gap = generate_algorithmic_benchmark_instance("P-C-001")
    bundle_singleton = generate_algorithmic_benchmark_instance("P-C-007")

    active_tied = 2:length(tied.instance.strategy_ids)
    @test all(
        tied.instance.coverage[:, column] == tied.instance.coverage[:, first(active_tied)]
        for column in active_tied
    )
    @test all(tied.instance.weights[column] == 1 // 1 for column in active_tied)

    active_duplicate = 2:length(duplicate.instance.strategy_ids)
    @test all(
        duplicate.instance.coverage[:, column] ==
        duplicate.instance.coverage[:, first(active_duplicate)] for
        column in active_duplicate
    )
    @test duplicate.realized.distinct_active_weights == (1 // 1, 2 // 1)

    preprocessing = preprocess_tagged_cover(exact_tagged_cover_model(dominance.instance))
    @test preprocessing.audit["rule_counts"]["coverage_dominance"]["variables_removed"] > 0
    @test length(rare.realized.mandatory_strategy_ids) == 2
    @test rare.realized.unique_carrier_count == 1
    @test only(rare.realized.unique_carrier_strategy_ids) in
          rare.realized.mandatory_strategy_ids
    @test all(id -> id in rare.realized.preprocessing_forced_strategy_ids,
              rare.realized.mandatory_strategy_ids)

    module_rows = 2:size(gap.instance.coverage, 1)
    active_gap = 2:length(gap.instance.strategy_ids)
    coverage_sizes = [count(gap.instance.coverage[module_rows, column]) for column in active_gap]
    bundle_position = only(findall(==(4), coverage_sizes))
    @test gap.instance.weights[active_gap[bundle_position]] == 3 // 2
    @test count(==(1), coverage_sizes) == 4

    active_bundle = 2:length(bundle_singleton.instance.strategy_ids)
    module_rows_bundle = 2:size(bundle_singleton.instance.coverage, 1)
    bundle_columns = Int[
        column for column in active_bundle if
        count(bundle_singleton.instance.coverage[module_rows_bundle, column]) > 1
    ]
    signed_differences = sort!(ExactRational[
        bundle_singleton.instance.weights[column] -
        count(bundle_singleton.instance.coverage[module_rows_bundle, column]) // 1
        for column in bundle_columns
    ])
    @test signed_differences == ExactRational[-1 // 4, 1 // 4]
end


@testset "small exhaustive feasibility equivalence" begin
    for instance_id in ("P-A-001", "P-C-001", "P-C-004", "P-C-005")
        generated = generate_algorithmic_benchmark_instance(instance_id)
        instance = generated.instance
        n = length(instance.strategy_ids)
        @test n <= 9
        for mask in UInt(0):(UInt(1) << n) - UInt(1)
            selected = BitVector(((mask >> (index - 1)) & UInt(1)) == UInt(1) for index in 1:n)
            semantic = check_journal_compression_solution(instance, selected).exact_feasible
            @test semantic == _algorithmic_direct_cover_feasible(instance, selected)
        end
    end
end


@testset "invalid candidates are rejected without repair" begin
    base = algorithmic_benchmark_registry_entry("P-B-001")
    invalid = _algorithmic_custom_pair(
        base,
        "INVALID";
        module_row_count = base.spec.module_row_count - 1,
    )
    failure = generate_algorithmic_benchmark_instance(
        invalid.spec,
        invalid.seed;
        maximum_attempts = 3,
    )
    @test failure isa AlgorithmicGenerationFailure
    @test failure.status == :GENERATION_FAILED
    @test length(failure.attempts) == 3
    @test all(!attempt.accepted for attempt in failure.attempts)
    @test all(!isempty(attempt.reasons) for attempt in failure.attempts)
    failure_payload = TOML.parse(serialize_algorithmic_generation_record(failure))
    @test failure_payload["status"] == "GENERATION_FAILED"
    @test length(failure_payload["attempts"]) == 3
end
