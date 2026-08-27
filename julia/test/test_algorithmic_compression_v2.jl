using Test
using StrategyInnovation
using TOML

include(joinpath(@__DIR__, "..", "scripts", "run_algorithmic_compression_final_v2.jl"))
using .AlgorithmicCompressionFinalV2

const V2 = AlgorithmicCompressionFinalV2

function _v2_fixture()
    return journal_compression_instance_from_components(
        [:inactive, :a, :b, :c],
        Bool[true, false, false, false],
        [0, 2, 2, 2],
        [:zero_frontier],
        zeros(Int, 4, 1),
        [Symbol[], [:m1, :m2], [:m2, :m3], [:m1, :m3]];
        provenance = JournalCompressionProvenance(
            :synthetic,
            "v2-concurrency-fixture",
            "nonregistered eight-lane test fixture";
            generator = "test_algorithmic_compression_v2",
        ),
    )
end

@testset "v2 registries and deterministic eight-lane schedule" begin
    @test Threads.nthreads() == 8
    registries = load_algorithmic_benchmark_registries(
        V2.INSTANCE_REGISTRY_PATH,
        V2.SEED_REGISTRY_PATH,
    )
    schedule = V2._registered_schedule(registries)
    @test length(schedule) == 3907
    @test schedule == V2._registered_schedule(registries)
    @test all(item.worker_lane == mod(item.global_schedule_position - 1, 8) + 1 for item in schedule)
    @test all(item.launch_wave == cld(item.global_schedule_position, 8) for item in schedule)
    counts = [count(item -> item.worker_lane == lane, schedule) for lane in 1:8]
    @test maximum(counts) - minimum(counts) == 1
    @test sum(counts) == 3907
    @test V2._progress_line(0, 8; width = 8) == "[........] 0/8 (0.0%)"
    @test V2._progress_line(8, 8; width = 8) == "[========] 8/8 (100.0%)"

    v2_values = Set{UInt64}()
    for seed in registries.seeds
        union!(v2_values, UInt64[
            seed.execution_order_key,
            seed.generator_seed,
            seed.random_order_seed,
            seed.multistart_seed,
            seed.mip_seed,
        ])
    end
    @test length(v2_values) == 5 * length(registries.seeds)
    v1 = load_algorithmic_benchmark_registries()
    v1_values = Set{UInt64}()
    for seed in v1.seeds
        union!(v1_values, UInt64[
            seed.execution_order_key,
            seed.generator_seed,
            seed.random_order_seed,
            seed.multistart_seed,
            seed.mip_seed,
        ])
    end
    @test isempty(intersect(v1_values, v2_values))
end

@testset "eight lanes execute concurrently with deterministic membership" begin
    lanes = [[Dict{String,Any}(
        "worker_lane" => lane,
        "global_schedule_position" => lane,
    )] for lane in 1:8]
    state_lock = ReentrantLock()
    active = Ref(0)
    maximum_active = Ref(0)
    visited = Int[]
    function fake_run(job)
        lock(state_lock) do
            active[] += 1
            maximum_active[] = max(maximum_active[], active[])
        end
        sleep(0.15)
        lock(state_lock) do
            push!(visited, job["worker_lane"])
            active[] -= 1
        end
        return Dict{String,Any}("terminal" => true)
    end
    withenv("AOR_PROGRESS" => "0") do
        @test V2._run_lanes!(lanes, 8; run_one = fake_run) == 8
    end
    @test maximum_active[] == 8
    @test sort(visited) == collect(1:8)
end

@testset "isolated worker process is one-threaded and exact" begin
    fixture = _v2_fixture()
    mktempdir() do directory
        instance_path = joinpath(directory, "instance.toml")
        write(instance_path, serialize_journal_compression_instance(fixture))
        paths = (
            job = joinpath(directory, "job.toml"),
            handshake = joinpath(directory, "handshake.toml"),
            worker = joinpath(directory, "worker.toml"),
            stdout = joinpath(directory, "stdout.log"),
            stderr = joinpath(directory, "stderr.log"),
        )
        job = Dict{String,Any}(
            "schema_version" => V2.FINAL_JOB_SCHEMA_VERSION,
            "instance_id" => "V2-NONREGISTERED-THREAD-TEST",
            "instance_path" => instance_path,
            "instance_sha256" => journal_compression_instance_sha256(fixture),
            "strategy_ids" => [string(id.id) for id in fixture.strategy_ids],
            "algorithm_id" => "weighted_greedy",
            "preprocessing_variant" => "mandatory_only",
            "random_order_seed" => "17",
            "multistart_seed" => "19",
            "mip_seed" => "23",
            "time_limit_seconds" => 30.0,
            "handshake_path" => paths.handshake,
            "worker_output_path" => paths.worker,
        )
        open(paths.job, "w") do io
            TOML.print(io, job; sorted = true)
        end
        supervision = V2._supervise(job, paths, 30.0)
        @test supervision.status == "PROCESS_COMPLETED"
        @test supervision.exit_code == 0
        worker = TOML.parsefile(paths.worker)
        @test worker["worker_status"] == "COMPLETED"
        @test worker["candidate_accepted"]
        @test worker["exact_feasibility_recheck"]["exact_feasible"]
        @test worker["julia_threads"] == 1
        @test worker["blas_threads"] == 1
        @test worker["highs_threads"] == 1
    end
end

@testset "resume and interrupted-control classification" begin
    mktempdir() do directory
        paths = (
            job = joinpath(directory, "job.toml"),
            handshake = joinpath(directory, "handshake.toml"),
            worker = joinpath(directory, "worker.toml"),
            stdout = joinpath(directory, "stdout.log"),
            stderr = joinpath(directory, "stderr.log"),
        )
        @test V2._control_resume_state(paths) == :fresh
        write(paths.job, "schema_version = \"test\"\n")
        @test V2._control_resume_state(paths) == :interrupted
        write(paths.worker, "worker_status = \"COMPLETED\"\n")
        @test V2._control_resume_state(paths) == :completed_worker

        terminal_path = joinpath(directory, "terminal.toml")
        open(terminal_path, "w") do io
            TOML.print(io, Dict{String,Any}(
                "schema_version" => V2.FINAL_RUN_SCHEMA_VERSION,
                "instance_id" => "fixture",
                "algorithm_id" => "weighted_greedy",
                "preprocessing_variant" => "mandatory_only",
                "terminal" => true,
            ); sorted = true)
        end
        validated = V2._validate_existing_record(
            terminal_path,
            "fixture",
            :weighted_greedy,
            :mandatory_only,
        )
        @test validated["terminal"]
    end
end

@testset "lock manifest detects any changed input hash" begin
    hashes = V2.LockAlgorithmicCompressionDesignV2._hashes()
    text = V2.LockAlgorithmicCompressionDesignV2._render_lock(hashes)
    @test V2.LockAlgorithmicCompressionDesignV2._verify_hash_manifest(text, hashes)
    changed = copy(hashes)
    changed[first(sort!(collect(keys(changed))))] = repeat("0", 64)
    @test_throws ErrorException V2.LockAlgorithmicCompressionDesignV2._verify_hash_manifest(
        text,
        changed,
    )
end
