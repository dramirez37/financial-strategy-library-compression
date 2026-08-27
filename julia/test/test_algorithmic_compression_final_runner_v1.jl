using Test
using StrategyInnovation

include(joinpath(@__DIR__, "..", "scripts", "run_algorithmic_compression_final_worker_v1.jl"))
using .AlgorithmicCompressionFinalWorkerV1

include(joinpath(@__DIR__, "..", "scripts", "run_algorithmic_compression_final_v1.jl"))
using .AlgorithmicCompressionFinalV1


function _final_runner_fixture()
    return journal_compression_instance_from_components(
        [:inactive, :a, :b, :c],
        Bool[true, false, false, false],
        [0, 2, 2, 2],
        [:zero_frontier],
        zeros(Int, 4, 1),
        [Symbol[], [:m1, :m2], [:m2, :m3], [:m1, :m3]];
        provenance = JournalCompressionProvenance(
            :synthetic,
            "final-runner-dry-fixture",
            "nonregistered readiness fixture";
            generator = "test_algorithmic_compression_final_runner_v1",
        ),
    )
end


@testset "final benchmark worker readiness without registered seeds" begin
    fixture = _final_runner_fixture()
    registries = load_algorithmic_benchmark_registries()
    dry_index = findfirst(spec -> spec.instance_id == "DRY-001", registries.instances)
    dry_spec = registries.instances[dry_index]
    safety_spec = AlgorithmicBenchmarkInstanceSpec(
        "FINAL-SAFETY-GATE-DRY",
        :final,
        false,
        dry_spec.family,
        dry_spec.generator_id,
        dry_spec.replicate_id,
        dry_spec.strategy_count,
        dry_spec.tagged_requirement_count,
        dry_spec.frontier_row_count,
        dry_spec.module_row_count,
        dry_spec.coverage_density_level,
        dry_spec.module_overlap_level,
        dry_spec.bundle_prevalence_level,
        dry_spec.unique_carrier_frequency_level,
        dry_spec.weight_dispersion_level,
        dry_spec.frontier_module_correlation_level,
        dry_spec.mechanism,
        dry_spec.mechanism_parameter,
        "SEED-FINAL-SAFETY-GATE-DRY",
        true,
        true,
        true,
    )
    safety_seed = AlgorithmicBenchmarkSeedSpec(
        safety_spec.seed_id,
        safety_spec.instance_id,
        :final,
        1,
        UInt64(101),
        UInt64(103),
        UInt64(107),
        UInt64(109),
        UInt64(113),
        "nonregistered_final_safety_gate_only",
    )
    @test_throws ArgumentError generate_algorithmic_benchmark_instance(
        safety_spec,
        safety_seed,
    )
    safety_generated = generate_algorithmic_benchmark_instance(
        safety_spec,
        safety_seed;
        allow_final = true,
    )
    @test safety_generated isa AlgorithmicGeneratedInstance
    @test safety_generated.seed.generator_seed == UInt64(103)

    job = Dict{String,Any}(
        "instance_id" => "FINAL-RUNNER-DRY-FIXTURE",
        "instance_sha256" => journal_compression_instance_sha256(fixture),
        "strategy_ids" => [string(id.id) for id in fixture.strategy_ids],
        "random_order_seed" => "17",
        "multistart_seed" => "19",
        "mip_seed" => "23",
        "time_limit_seconds" => 30.0,
    )
    units = [
        (algorithm = :complete_enumeration, variant = :mandatory_only),
        (algorithm = :requirement_mask_dp, variant = :mandatory_only),
        (algorithm = :requirement_mask_dp, variant = :full_fixed_point),
        (algorithm = :jump_highs_tagged_cover, variant = :mandatory_only),
        (algorithm = :jump_highs_tagged_cover, variant = :full_fixed_point),
    ]
    for algorithm in AlgorithmicCompressionFinalV1.HEURISTICS
        push!(units, (algorithm, variant = :mandatory_only))
        push!(units, (algorithm, variant = :full_fixed_point_then_reconstruct))
    end

    exact_burdens = Dict{Tuple{Symbol,Symbol},ExactRational}()
    for unit in units
        execution = AlgorithmicCompressionFinalWorkerV1._execute(
            fixture,
            unit.algorithm,
            unit.variant,
            job,
        )
        @test !isnothing(execution.selected_original)
        @test execution.exact_check.exact_feasible
        @test execution.exact_check.exact_burden >= 0 // 1
        if unit.algorithm in (
            :complete_enumeration,
            :requirement_mask_dp,
            :jump_highs_tagged_cover,
        )
            exact_burdens[(unit.algorithm, unit.variant)] =
                execution.exact_check.exact_burden
        end
    end
    @test length(exact_burdens) == 5
    @test all(burden == 4 // 1 for burden in values(exact_burdens))
    repaired_lock = AlgorithmicCompressionFinalV1._execution_lock_text(
        AlgorithmicCompressionFinalV1._execution_lock_hashes(),
        "2000-01-01T00:00:00.000Z";
        superseded_aggregate = repeat("a", 64),
        failure_record_hash = repeat("b", 64),
    )
    @test occursin("\"pre_final_execution_repair_count\": 1", repaired_lock)
    @test occursin(repeat("a", 64), repaired_lock)
    @test occursin(repeat("b", 64), repaired_lock)

    mktempdir() do directory
        instance_path = joinpath(directory, "instance.toml")
        handshake_path = joinpath(directory, "handshake.toml")
        worker_path = joinpath(directory, "worker.toml")
        job_path = joinpath(directory, "job.toml")
        write(instance_path, serialize_journal_compression_instance(fixture))
        file_job = merge(job, Dict{String,Any}(
            "schema_version" => "algorithmic-compression-final-job-v1",
            "algorithm_id" => "weighted_greedy",
            "preprocessing_variant" => "mandatory_only",
            "instance_path" => instance_path,
            "handshake_path" => handshake_path,
            "worker_output_path" => worker_path,
        ))
        open(job_path, "w") do io
            TOML.print(io, file_job; sorted = true)
        end
        @test AlgorithmicCompressionFinalWorkerV1.run_job(job_path)
        @test isfile(handshake_path)
        payload = TOML.parsefile(worker_path)
        @test payload["worker_status"] == "COMPLETED"
        @test payload["candidate_accepted"]
        @test payload["exact_feasibility_recheck"]["exact_feasible"]

        supervised = joinpath(directory, "supervised")
        mkpath(supervised)
        supervised_paths = (
            job = joinpath(supervised, "job.toml"),
            handshake = joinpath(supervised, "handshake.toml"),
            worker = joinpath(supervised, "worker.toml"),
            stdout = joinpath(supervised, "stdout.log"),
            stderr = joinpath(supervised, "stderr.log"),
        )
        supervised_job = merge(file_job, Dict{String,Any}(
            "instance_path" => instance_path,
            "handshake_path" => supervised_paths.handshake,
            "worker_output_path" => supervised_paths.worker,
        ))
        open(supervised_paths.job, "w") do io
            TOML.print(io, supervised_job; sorted = true)
        end
        supervision = AlgorithmicCompressionFinalV1._supervise(
            supervised_job,
            supervised_paths,
            30.0,
        )
        @test supervision.status == "PROCESS_COMPLETED"
        @test supervision.exit_code == 0
        @test supervision.peak_memory > 0
        @test TOML.parsefile(supervised_paths.worker)["worker_status"] == "COMPLETED"
    end
end
