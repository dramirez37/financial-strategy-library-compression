using Test
using StrategyInnovation
using Dates

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV1.jl"))
const FSLP1 = FinancialStrategyLibraryPanelV1

include(joinpath(@__DIR__, "..", "scripts", "run_financial_strategy_library_panel_v1.jl"))
const FSLP1Runner = RunFinancialStrategyLibraryPanelV1

include(joinpath(@__DIR__, "..", "scripts", "lock_financial_strategy_library_panel_v1_execution_002.jl"))
const FSLP1ExecutionLock = LockFinancialStrategyLibraryPanelV1Execution002

@testset "financial panel v1 execution configuration" begin
    @test VERSION == v"1.12.6"
    @test Threads.nthreads() == 8
    config, amendment = FSLP1.load_panel_config()
    @test config["experiment_id"] == "financial-strategy-library-panel-v1"
    @test amendment["threading"]["julia_threads"] == 8
    @test amendment["threading"]["concurrent_lanes"] == 8
    @test amendment["amendment_id"] == "AMENDMENT_002"
    @test amendment["return_rule"]["allowed_missing_flag"] == "NS"
    @test amendment["information_firewall"]["shared_cross_origin_return_map_permitted"] === false
    @test length(FSLP1.registered_job_keys()) == 180
    @test length(unique(FSLP1.registered_job_keys())) == 180

    if isfile(FSLP1ExecutionLock.LOCK_PATH)
        aggregate = FSLP1ExecutionLock.verify_execution_lock_002()
        @test occursin(r"^[0-9a-f]{64}$", aggregate)
        lock_text = read(FSLP1ExecutionLock.LOCK_PATH, String)
        one_hash = first(values(FSLP1ExecutionLock._hashes()))
        tampered = replace(lock_text, one_hash => repeat("0", 64); count = 1)
        @test_throws ErrorException FSLP1ExecutionLock.verify_lock_text(
            tampered,
            FSLP1ExecutionLock._hashes(),
        )
    else
        @test occursin(r"^[0-9a-f]{64}$", FSLP1ExecutionLock.dry_run())
    end
end

@testset "synthetic point-in-time library construction" begin
    config, amendment = FSLP1.load_panel_config()
    selected = [(
        permno,
        ticker = permno == 1 ? "SPY" : "SYN",
        security_name_sha256 = repeat(string(permno), 64),
        median_close = 100.0,
        median_dollar_volume = 10_000_000.0,
        preorigin_daily_rows = 1500,
        compression_liquidity_rows = 500,
        invalid_liquidity_rows = 0,
    ) for permno in 1:2]
    origin = FSLP1.OriginUniverse(
        "SMOKE-O99",
        2005,
        "2005-12-30",
        "2001-01-01",
        "2003-12-31",
        "2004-01-01",
        "2005-12-30",
        "2006-01-01",
        "2006-12-31",
        selected,
        2,
        2,
        1,
    )
    dates = filter(
        date -> dayofweek(date) <= 5,
        collect(Date(2000, 1, 3):Day(1):Date(2005, 12, 30)),
    )
    series = Dict{Int,Vector{FSLP1.DailyObservation}}()
    for permno in 1:2
        series[permno] = [
            FSLP1.DailyObservation(
                string(date),
                permno == 1 ?
                0.0002 + 0.008 * sin(2pi * index / 47) + 0.003 * cos(2pi * index / 113) :
                0.0001 + 0.010 * cos(2pi * index / 37) + 0.002 * sin(2pi * index / 89),
                100.0,
                1_000_000.0,
                "N",
                "",
            ) for (index, date) in enumerate(dates)
        ]
    end
    instances, metadata = FSLP1.build_origin_instances(
        origin,
        series,
        config,
        amendment,
    )
    @test length(instances) == 9
    @test metadata["source_strategy_counts"] == Dict(
        "full_factorial_catalog" => 192,
        "decentralized_signal_sleeves" => 14,
        "centralized_research_pool" => 30,
    )
    @test all(instance -> instance.identity_closure, values(instances))
    @test all(
        instance -> all(instance.weights[index] > 0 for index in eachindex(instance.weights) if
                        !instance.mandatory[index]),
        values(instances),
    )
end

@testset "origin-scoped return information firewall" begin
    selected = [(
        permno = 1,
        ticker = "SYN",
        security_name_sha256 = repeat("0", 64),
        median_close = 10.0,
        median_dollar_volume = 10_000_000.0,
        preorigin_daily_rows = 1000,
        compression_liquidity_rows = 400,
        invalid_liquidity_rows = 0,
    )]
    origins = [
        FSLP1.OriginUniverse(
            "TEST-O2005",
            2005,
            "2005-12-30",
            "2001-01-01",
            "2003-12-31",
            "2004-01-01",
            "2005-12-30",
            "2006-01-01",
            "2006-12-31",
            selected,
            1,
            1,
            1,
        ),
        FSLP1.OriginUniverse(
            "TEST-O2006",
            2006,
            "2006-12-29",
            "2002-01-01",
            "2004-12-31",
            "2005-01-01",
            "2006-12-29",
            "2007-01-01",
            "2007-12-31",
            selected,
            1,
            1,
            1,
        ),
    ]
    config, _ = FSLP1.load_panel_config()
    mktempdir() do root
        csv_path = joinpath(root, "daily.csv")
        gzip_path = csv_path * ".gz"
        open(csv_path, "w") do io
            println(io, "permno,dlycaldt,dlyret,dlyclose,dlyprc,dlyvol,dlydelflg,dlyretmissflg")
            println(io, "1,2004-01-02,,9,9,1000,N,NS")
            println(io, "1,2005-12-30,0.01,10,10,1000,N,NA")
            println(io, "1,2006-12-29,0.02,11,11,1000,N,NA")
            println(io, "1,2007-12-31,0.03,12,12,1000,N,NA")
        end
        open(gzip_path, "w") do output
            run(pipeline(`gzip -c -- $csv_path`; stdout = output))
        end
        structural_quality = Dict{String,Any}()
        structural = FSLP1.extract_origin_series(
            config,
            [gzip_path],
            origins;
            phase = :structural,
            diagnostics = structural_quality,
        )
        @test getfield.(structural["TEST-O2005"][1], :date) == ["2005-12-30"]
        @test getfield.(structural["TEST-O2006"][1], :date) ==
              ["2005-12-30", "2006-12-29"]
        @test structural_quality["TEST-O2005"]["new_security_initialization_rows_excluded"] == 1
        @test structural_quality["TEST-O2006"]["new_security_initialization_rows_excluded"] == 1
        postdecision = FSLP1.extract_origin_series(
            config,
            [gzip_path],
            origins;
            phase = :postdecision,
        )
        @test getfield.(postdecision["TEST-O2005"][1], :date) ==
              ["2005-12-30", "2006-12-29"]
        @test getfield.(postdecision["TEST-O2006"][1], :date) ==
              ["2006-12-29", "2007-12-31"]

        invalid_csv_path = joinpath(root, "invalid_daily.csv")
        invalid_gzip_path = invalid_csv_path * ".gz"
        open(invalid_csv_path, "w") do io
            println(io, "permno,dlycaldt,dlyret,dlyclose,dlyprc,dlyvol,dlydelflg,dlyretmissflg")
            println(io, "1,2005-12-30,0.01,10,10,1000,N,NA")
            println(io, "1,2006-12-29,,11,11,1000,N,NS")
        end
        open(invalid_gzip_path, "w") do output
            run(pipeline(`gzip -c -- $invalid_csv_path`; stdout = output))
        end
        @test_throws ErrorException FSLP1.extract_origin_series(
            config,
            [invalid_gzip_path],
            origins;
            phase = :structural,
        )
    end
end

@testset "exact scalable carrier-count deletion" begin
    job = first(FSLP1.build_synthetic_smoke_instances())
    instance = job.instance
    fast_heaviest = FSLP1._panel_deletion(instance, "heaviest_safe_first", UInt64(17), 1)
    generic_heaviest = solve_journal_compression_heaviest_safe_first(instance)
    @test fast_heaviest.selected == generic_heaviest.selected
    @test fast_heaviest.exact_burden == generic_heaviest.exact_burden

    fast_declared = FSLP1._panel_deletion(instance, "declared_source_order", UInt64(17), 1)
    generic_declared = solve_journal_compression_declared_order(instance)
    @test fast_declared.selected == generic_declared.selected
    @test fast_declared.exact_burden == generic_declared.exact_burden

    fast_random = FSLP1._panel_deletion(
        instance,
        "multistart_random_rechecked_deletion_32",
        UInt64(17),
        4,
    )
    generic_random = solve_journal_compression_multistart_random(instance; seed = 17, starts = 4)
    @test fast_random.selected == generic_random.selected
    @test fast_random.exact_burden == generic_random.exact_burden
    @test check_journal_compression_solution(instance, fast_random.selected).exact_feasible
end

@testset "seven-algorithm exact audit and deterministic serialization" begin
    config, _ = FSLP1.load_panel_config()
    job = first(FSLP1.build_synthetic_smoke_instances())
    first_payload, first_logs = FSLP1.run_algorithm_suite(
        job.instance;
        origin_id = job.origin_id,
        library_id = job.library_id,
        schedule_id = job.schedule_id,
        config,
    )
    @test first_payload["algorithm_terminal_row_count"] == 7
    @test FSLP1.audit_instance_result(job.instance, first_payload)["passed"]
    @test haskey(first_logs, "jump_highs_tagged_cover")
    @test all(
        row -> !row["candidate_returned"] || row["selection"]["exact_feasible"],
        first_payload["algorithms"],
    )
    serialized = serialize_journal_compression_instance(job.instance)
    restored = read_journal_compression_instance(IOBuffer(serialized))
    @test restored == job.instance
    @test journal_compression_instance_sha256(restored) ==
          journal_compression_instance_sha256(job.instance)

    tampered = deepcopy(first_payload)
    row = first(filter(record -> record["candidate_returned"], tampered["algorithms"]))
    row["selection"]["exact_burden"] = "999//1"
    @test !FSLP1.audit_instance_result(job.instance, tampered)["passed"]
end

@testset "thread lanes terminate and expose failures" begin
    lanes_seen = zeros(Int, 8)
    lane_lock = ReentrantLock()
    run_lane = function(job, lane)
        lock(lane_lock) do
            lanes_seen[lane] += 1
        end
        @test job == lane
    end
    FSLP1Runner._run_threaded_lanes!(collect(1:8), "lane-test", run_lane; lanes = 8)
    @test lanes_seen == ones(Int, 8)
    fail_lane = function(job, lane)
        job == 3 && error("intentional threaded fixture failure")
        nothing
    end
    @test_throws ErrorException FSLP1Runner._run_threaded_lanes!(
        collect(1:8),
        "failure-test",
        fail_lane;
        lanes = 8,
    )
end
