using Test
using StrategyInnovation
using Dates
using TOML

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV1.jl"))
const FSLP1 = FinancialStrategyLibraryPanelV1

include(joinpath(@__DIR__, "..", "scripts", "run_financial_strategy_library_panel_v1.jl"))
const FSLP1Runner = RunFinancialStrategyLibraryPanelV1

include(joinpath(@__DIR__, "..", "scripts", "lock_financial_strategy_library_panel_v1_execution_020.jl"))
const FSLP1ExecutionLock = LockFinancialStrategyLibraryPanelV1Execution020

include(joinpath(@__DIR__, "..", "scripts", "analyze_financial_strategy_library_panel_v1.jl"))
const FSLP1Analysis = AnalyzeFinancialStrategyLibraryPanelV1

@testset "financial panel v1 execution configuration" begin
    @test VERSION == v"1.12.6"
    @test Threads.nthreads() == 8
    config, amendment = FSLP1.load_panel_config()
    @test config["experiment_id"] == "financial-strategy-library-panel-v1"
    @test amendment["threading"]["julia_threads"] == 8
    @test amendment["threading"]["concurrent_job_lanes"] == 8
    @test amendment["threading"]["maximum_simultaneous_heavy_stages"] == 2
    @test amendment["amendment_id"] == "AMENDMENT_020"
    @test amendment["mip_warm_start_projection"]["follow_duplicate_and_dominance_elimination_targets"] === true
    @test amendment["mip_warm_start_projection"]["residual_exact_coverage_required"] === true
    @test amendment["mip_warm_start_projection"]["projected_exact_burden_may_not_increase"] === true
    @test amendment["corrective_resume"]["expected_corrected_row_count"] == 94
    @test amendment["corrective_resume"]["preserve_other_algorithm_rows_per_corrected_instance"] == 6
    @test amendment["corrective_resume"]["rematerialize_all_analysis_partitions"] === true
    @test amendment["checkpoint_recovery"]["prevalidate_before_solver"] === true
    @test amendment["checkpoint_recovery"]["require_all_seven_checkpoint_rows"] === true
    @test amendment["checkpoint_recovery"]["require_exact_lock_005_aggregate"] === true
    @test amendment["audit_parallelism"]["worker_count"] == 8
    @test amendment["audit_parallelism"]["postdecision_worker_count"] == 8
    @test amendment["audit_dispatch"]["new_method_invocation"] == "Base.invokelatest"
    @test amendment["preparation_resume"]["all_manifest_file_hashes_rechecked"] === true
    @test amendment["progress"]["ansi_cursor_control"] === false
    @test amendment["return_rule"]["allowed_missing_flag"] == "NS"
    @test amendment["failure_persistence"]["successful_instances_plus_failure_slots"] == 180
    @test amendment["failure_persistence"]["impute_profile"] === false
    @test amendment["information_firewall"]["shared_cross_origin_return_map_permitted"] === false
    @test amendment["parquet"]["compression"] == "SNAPPY"
    @test amendment["parquet"]["registered_source_file_partitions"] == 3
    @test amendment["analysis_materialization"]["worker_count"] == 8
    @test amendment["analysis_materialization"]["combined_algorithm_rows"] == 1260
    @test amendment["postdecision_field_policy"]["postdecision_close_used"] === false
    @test amendment["postdecision_field_policy"]["postdecision_volume_used"] === false
    @test amendment["postdecision_field_policy"]["postdecision_unused_field_imputation_permitted"] === false
    @test amendment["postdecision_missing_return_policy"]["required_flag"] == "DP"
    @test amendment["postdecision_missing_return_policy"]["return_imputation_permitted"] === false
    @test amendment["postdecision_profile_failure_policy"]["minimum_observations_per_belief"] == 25
    @test amendment["postdecision_profile_failure_policy"]["profile_imputation_permitted"] === false
    @test amendment["postdecision_profile_failure_policy"]["affected_registered_instance_count"] == 72
    @test amendment["postdecision_profile_count_equivalence"]["full_strategy_backtest_in_preflight"] === false
    @test amendment["postdecision_profile_count_equivalence"]["minimum_observations_per_belief"] == 25
    @test amendment["analysis_shape_correction"]["flatten_with_vec_before_sort"] === true
    @test amendment["analysis_shape_correction"]["registered_key_count"] == 180
    @test amendment["resume_aggregate_namespace"]["require_directory_relative_aggregate_for_environment_recovery"] === true
    @test amendment["resume_aggregate_namespace"]["require_root_relative_aggregate_in_result_audit"] === true
    @test amendment["analysis_partition_rebinding"]["require_parquet_hash_validation"] === true
    @test amendment["analysis_partition_rebinding"]["require_current_structural_source_hash"] === true
    @test amendment["analysis_partition_rebinding"]["require_current_postdecision_source_hash"] === true
    @test amendment["analysis_partition_rebinding"]["rewrite_parquet_when_only_certificate_binding_changed"] === false
    analysis_stems = FSLP1Analysis._registered_analysis_stems()
    @test length(analysis_stems) == 180
    @test length(unique(analysis_stems)) == 180
    @test issorted(analysis_stems)
    @test config["postdecision_missing_returns"]["terminal_delisting_pending_expected_memberships"] == 1
    @test length(FSLP1.registered_job_keys()) == 180
    @test length(unique(FSLP1.registered_job_keys())) == 180

    if isfile(FSLP1ExecutionLock.LOCK_PATH)
        aggregate = FSLP1ExecutionLock.verify_execution_lock_020()
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

@testset "registered Parquet analysis shapes and denominators" begin
    rows = NamedTuple[]
    for (origin_id, library_id, schedule_id) in FSLP1.registered_job_keys()
        for algorithm_id in FSLP1Analysis.ALGORITHM_IDS
            push!(rows, FSLP1Analysis._failure_row(
                origin_id,
                library_id,
                schedule_id,
                algorithm_id,
                "PREPARATION_FAILURE",
                repeat("a", 64),
                repeat("b", 64),
            ))
        end
    end
    @test length(rows) == 1260
    instances = FSLP1Analysis._instance_rows(rows)
    @test length(instances) == 180
    @test all(row -> row.instance_status == "PREPARATION_FAILURE", instances)
    summaries = FSLP1Analysis._summary_rows(rows)
    @test length(summaries) == 63
    @test all(row -> row.registered_instance_count == 20, summaries)
    @test all(row -> row.failure_instance_count == 20, summaries)
    overlaps = FSLP1Analysis._overlap_rows(rows)
    @test length(overlaps) == 5040
    @test all(row -> !row.available, overlaps)
    agreements = FSLP1Analysis._agreement_rows(rows)
    @test length(agreements) == 180
    @test all(row -> !row.mip_solver_status_used_as_exact_proof, agreements)
    mktempdir() do root
        path = joinpath(root, "analysis.parquet")
        columns = FSLP1Analysis._column_table(rows, FSLP1Analysis.ALGORITHM_SCHEMA)
        FSLP1.FinancialPanelParquet.atomic_write_parquet(path, columns)
        restored = FSLP1.FinancialPanelParquet.validate_parquet(
            path;
            expected_columns = propertynames(FSLP1Analysis.ALGORITHM_SCHEMA),
            expected_rows = 1260,
        )
        @test restored.origin_id == columns.origin_id
        @test filesize(path) < 500_000

        figure_paths = FSLP1Analysis._analysis_figures(
            rows,
            instances,
            overlaps,
            NamedTuple[],
            (figures = joinpath(root, "figures"),),
        )
        @test length(figure_paths) == 5
        @test all(path -> filesize(path) < 100_000, figure_paths)
        @test all(path -> occursin("<title", read(path, String)) &&
                         occursin("<desc", read(path, String)), figure_paths)
    end

    config, _ = FSLP1.load_panel_config()
    job = first(FSLP1.build_synthetic_smoke_instances())
    structural, _ = FSLP1.run_algorithm_suite(
        job.instance;
        origin_id = "FSLP1-O2005",
        library_id = "centralized_research_pool",
        schedule_id = "equal_active_strategy",
        config,
    )
    post_algorithms = Dict{String,Any}[]
    for record in structural["algorithms"]
        if record["candidate_returned"] === true
            push!(post_algorithms, Dict{String,Any}(
                "algorithm_id" => record["algorithm_id"],
                "available" => true,
                "belief_losses" => fill("0//1", 5),
                "mean_belief_loss" => "0//1",
                "no_loss_share" => "1//1",
                "identity_persistence_to_next_origin" => "1//1",
            ))
        else
            push!(post_algorithms, Dict{String,Any}(
                "algorithm_id" => record["algorithm_id"],
                "available" => false,
            ))
        end
    end
    postdecision = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-postdecision-v1",
        "source_security_count_with_delisting_flag" => 0,
        "algorithms" => post_algorithms,
    )
    mktempdir() do root
        paths = (
            structural = joinpath(root, "structural"),
            postdecision = joinpath(root, "postdecision"),
            instances = joinpath(root, "instances"),
            partitions = joinpath(root, "partitions"),
        )
        foreach(mkpath, paths)
        stem = "FSLP1-O2005__centralized_research_pool__equal_active_strategy"
        write(joinpath(paths.structural, stem * ".toml"), FSLP1.toml_text(structural))
        write(joinpath(paths.postdecision, stem * ".toml"), FSLP1.toml_text(postdecision))
        open(joinpath(paths.instances, stem * ".toml"), "w") do io
            write(io, serialize_journal_compression_instance(job.instance))
        end
        flattened = FSLP1Analysis._algorithm_rows(stem, paths)
        @test length(flattened) == 7
        @test all(row -> row.instance_status == "SUCCESS", flattened)
        @test all(row -> !row.candidate_returned || row.exact_feasible === true, flattened)
        @test count(row -> row.postdecision_available, flattened) ==
              count(row -> row.candidate_returned, flattened)
        carriers = FSLP1Analysis._carrier_rows([stem], paths)
        @test length(carriers) == length(job.instance.requirements)
        @test all(row -> row.carrier_count > 0, carriers)
        @test count(row -> row.unique_carrier, carriers) ==
              count(row -> count(job.instance.coverage[row, :]) == 1,
                    axes(job.instance.coverage, 1))

        first_audit = repeat("c", 64)
        successor_audit = repeat("d", 64)
        successor_lock = repeat("e", 64)
        @test FSLP1Analysis._write_partition(
            stem,
            paths,
            first_audit,
            FSLP1Analysis.LOCK_017_AGGREGATE,
        ) == :created
        partition = FSLP1Analysis._partition_paths(paths, stem)
        parquet_sha = FSLP1.FinancialPanelParquet.sha256_file(partition.parquet)
        @test FSLP1Analysis._write_partition(
            stem,
            paths,
            successor_audit,
            successor_lock,
        ) == :reused
        rebound = TOML.parsefile(partition.metadata)
        @test rebound["result_audit_sha256"] == successor_audit
        @test rebound["execution_lock_aggregate_sha256"] == successor_lock
        @test FSLP1.FinancialPanelParquet.sha256_file(partition.parquet) == parquet_sha

        rm(partition.parquet)
        rm(partition.metadata)
        @test FSLP1Analysis._write_partition(
            stem,
            paths,
            first_audit,
            FSLP1Analysis.LOCK_018_AGGREGATE,
        ) == :created
        corrective_parquet_sha =
            FSLP1.FinancialPanelParquet.sha256_file(partition.parquet)
        @test FSLP1Analysis._write_partition(
            stem,
            paths,
            successor_audit,
            successor_lock,
        ) == :rematerialized
        rematerialized = TOML.parsefile(partition.metadata)
        @test rematerialized["corrective_execution_amendment_id"] == "AMENDMENT_020"
        @test rematerialized["rematerialized_from_execution_lock_aggregate_sha256"] ==
              FSLP1Analysis.LOCK_018_AGGREGATE
        @test rematerialized["execution_lock_aggregate_sha256"] == successor_lock
        @test FSLP1.FinancialPanelParquet.sha256_file(partition.parquet) ==
              corrective_parquet_sha
        write(joinpath(paths.postdecision, stem * ".toml"), FSLP1.toml_text(Dict(
            "schema_version" => "changed-source-fixture",
        )))
        @test_throws ErrorException FSLP1Analysis._write_partition(
            stem,
            paths,
            repeat("f", 64),
            successor_lock,
        )
    end
end

@testset "resumable threaded Parquet origin-series cache" begin
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
    origin = FSLP1.OriginUniverse(
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
    )
    config, _ = FSLP1.load_panel_config()
    mktempdir() do root
        files = String[]
        rows_by_file = [
            [
                "1,2005-01-03,,9,9,1000,N,NS",
                "1,2005-12-30,0.01,10,10,1000,N,NA",
            ],
            ["1,2006-12-29,0.02,,,,N,NA"],
        ]
        for (index, rows) in enumerate(rows_by_file)
            csv_path = joinpath(root, "daily-$index.csv")
            gzip_path = csv_path * ".gz"
            open(csv_path, "w") do io
                println(io, "permno,dlycaldt,dlyret,dlyclose,dlyprc,dlyvol,dlydelflg,dlyretmissflg")
                foreach(row -> println(io, row), rows)
            end
            open(gzip_path, "w") do output
                run(pipeline(`gzip -c -- $csv_path`; stdout = output))
            end
            push!(files, gzip_path)
        end
        cache_root = joinpath(root, "cache")
        updates = NamedTuple[]
        update_lock = ReentrantLock()
        quality = Dict{String,Any}()
        result = FSLP1.extract_origin_series_parquet(
            config,
            files,
            [origin];
            phase = :postdecision,
            cache_root,
            execution_lock_aggregate = repeat("a", 64),
            diagnostics = quality,
            progress_callback = update -> lock(update_lock) do
                push!(updates, update)
            end,
        )
        @test getfield.(result[origin.origin_id][1], :date) ==
              ["2005-12-30", "2006-12-29"]
        @test quality[origin.origin_id]["new_security_initialization_rows_excluded"] == 1
        @test quality[origin.origin_id]["unused_close_missing_rows"] == 1
        @test quality[origin.origin_id]["unused_volume_missing_rows"] == 1
        @test ismissing(last(result[origin.origin_id][1]).close)
        @test ismissing(last(result[origin.origin_id][1]).volume)
        @test count(name -> endswith(name, ".parquet"), readdir(cache_root)) == 2
        @test count(name -> endswith(name, ".toml"), readdir(cache_root)) == 2
        @test all(path -> filesize(path) > 4, filter(path -> endswith(path, ".parquet"),
            readdir(cache_root; join = true)))
        empty!(updates)
        resumed = FSLP1.extract_origin_series_parquet(
            config,
            files,
            [origin];
            phase = :postdecision,
            cache_root,
            execution_lock_aggregate = repeat("a", 64),
            progress_callback = update -> lock(update_lock) do
                push!(updates, update)
            end,
        )
        @test resumed == result
        @test count(update -> update.state == "file-reused", updates) == 2
        predecessor_reused = FSLP1.extract_origin_series_parquet(
            config,
            files,
            [origin];
            phase = :postdecision,
            cache_root,
            execution_lock_aggregate = repeat("b", 64),
            compatible_execution_lock_aggregates = (repeat("a", 64), repeat("b", 64)),
        )
        @test predecessor_reused == result
        sidecar = first(filter(path -> endswith(path, ".toml"), readdir(cache_root; join = true)))
        metadata = TOML.parsefile(sidecar)
        metadata["execution_lock_aggregate_sha256"] = repeat("c", 64)
        open(sidecar, "w") do io
            write(io, FSLP1.toml_text(metadata))
        end
        @test_throws ErrorException FSLP1.extract_origin_series_parquet(
            config,
            files,
            [origin];
            phase = :postdecision,
            cache_root,
            execution_lock_aggregate = repeat("a", 64),
        )
    end
end

@testset "terminal CRSP DP makes an origin postdecision diagnostic unavailable" begin
    selected = [(
        permno = 1,
        ticker = "TEST",
        security_name = "Test Fund",
        median_dollar_volume = 10_000_000.0,
        median_close = 10.0,
        preorigin_daily_rows = 1000,
        compression_liquidity_rows = 400,
        invalid_liquidity_rows = 0,
    )]
    origin = FSLP1.OriginUniverse(
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
    )
    config, _ = FSLP1.load_panel_config()
    mktempdir() do root
        function gzip_fixture(name, rows)
            csv_path = joinpath(root, name * ".csv")
            gzip_path = csv_path * ".gz"
            open(csv_path, "w") do io
                println(io, "permno,dlycaldt,dlyret,dlyclose,dlyprc,dlyvol,dlydelflg,dlyretmissflg")
                foreach(row -> println(io, row), rows)
            end
            open(gzip_path, "w") do output
                run(pipeline(`gzip -c -- $csv_path`; stdout = output))
            end
            return gzip_path
        end

        terminal_dp = gzip_fixture("terminal-dp", [
            "1,2005-12-30,0.01,10,10,1000,N,NA",
            "1,2006-12-29,,,,,Y,DP",
        ])
        direct_quality = Dict{String,Any}()
        direct = FSLP1.extract_origin_series(
            config,
            [terminal_dp],
            [origin];
            phase = :postdecision,
            diagnostics = direct_quality,
        )
        @test getfield.(direct[origin.origin_id][1], :date) == ["2005-12-30"]
        @test direct_quality[origin.origin_id]["terminal_delisting_pending_rows"] == 1
        @test direct_quality[origin.origin_id]["postdecision_return_complete"] == 0
        @test FSLP1.validate_postdecision_return_quality(direct_quality, config) ==
              Set([origin.origin_id])

        parquet_quality = Dict{String,Any}()
        parquet = FSLP1.extract_origin_series_parquet(
            config,
            [terminal_dp],
            [origin];
            phase = :postdecision,
            cache_root = joinpath(root, "terminal-cache"),
            execution_lock_aggregate = repeat("d", 64),
            diagnostics = parquet_quality,
        )
        @test parquet == direct
        @test parquet_quality == direct_quality
        @test FSLP1.validate_postdecision_return_quality(parquet_quality, config) ==
              Set([origin.origin_id])

        nonterminal_dp = gzip_fixture("nonterminal-dp", [
            "1,2005-12-30,0.01,10,10,1000,N,NA",
            "1,2006-06-30,,,,,Y,DP",
            "1,2006-12-29,0.02,11,11,1000,N,NA",
        ])
        @test_throws ErrorException FSLP1.extract_origin_series(
            config,
            [nonterminal_dp],
            [origin];
            phase = :postdecision,
        )
        @test_throws ErrorException FSLP1.extract_origin_series_parquet(
            config,
            [nonterminal_dp],
            [origin];
            phase = :postdecision,
            cache_root = joinpath(root, "nonterminal-cache"),
            execution_lock_aggregate = repeat("e", 64),
        )

        nondelisting_dp = gzip_fixture("nondelisting-dp", [
            "1,2005-12-30,0.01,10,10,1000,N,NA",
            "1,2006-12-29,,,,,N,DP",
        ])
        @test_throws ErrorException FSLP1.extract_origin_series(
            config,
            [nondelisting_dp],
            [origin];
            phase = :postdecision,
        )

        warmup_dp = gzip_fixture("warmup-dp", [
            "1,2005-06-30,0.01,10,10,1000,N,NA",
            "1,2005-12-30,,,,,Y,DP",
        ])
        @test_throws ErrorException FSLP1.extract_origin_series(
            config,
            [warmup_dp],
            [origin];
            phase = :postdecision,
        )

        structural_origin = FSLP1.OriginUniverse(
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
        )
        @test_throws ErrorException FSLP1.extract_origin_series(
            config,
            [terminal_dp],
            [structural_origin];
            phase = :structural,
        )
    end
end

@testset "Julia 1.12 world-age-safe audit dispatch" begin
    fixture = Module(:FinancialPanelAuditDispatchFixture)
    Core.eval(fixture, :(audit_fixture() = :world_age_safe))
    @test FSLP1Runner._invoke_latest_binding(fixture, :audit_fixture) == :world_age_safe
    @test_throws ErrorException FSLP1Runner._invoke_latest_binding(fixture, :missing_fixture)
    audit_module = FSLP1Runner._load_audit_module()
    @test nameof(audit_module) == :AuditFinancialStrategyLibraryPanelV1
    @test isdefined(audit_module, :audit_structural_results)
    @test isdefined(audit_module, :audit_all_results)
    expected_stems = FSLP1Runner._invoke_latest_binding(audit_module, :_expected_stems)
    @test expected_stems isa Vector{String}
    @test length(expected_stems) == 180
    @test length(unique(expected_stems)) == 180
    @test issorted(expected_stems)
    @test expected_stems == sort!(vec(String[
        "$(origin_id)__$(library_id)__$(schedule_id)" for
        (origin_id, library_id, schedule_id) in FSLP1.registered_job_keys()
    ]))
    mktempdir() do directory
        write(joinpath(directory, "second.toml"), "terminal = true\n")
        write(joinpath(directory, "ignored.txt"), "not an audit record\n")
        write(joinpath(directory, "first.toml"), "terminal = true\n")
        toml_stems = FSLP1Runner._invoke_latest_binding(
            audit_module,
            :_toml_stems,
            directory,
        )
        @test toml_stems isa Vector{String}
        @test toml_stems == ["first", "second"]
    end
    mktempdir() do directory
        structural_directory = joinpath(directory, "structural")
        postdecision_directory = joinpath(directory, "postdecision")
        mkpath(structural_directory)
        mkpath(postdecision_directory)
        stem = "TEST-O2005__full_factorial_catalog__equal_active"
        structural = Dict{String,Any}(
            "schema_version" => "financial-strategy-library-panel-instance-result-v1",
            "instance_sha256" => repeat("1", 64),
        )
        postdecision = Dict{String,Any}(
            "schema_version" =>
                "financial-strategy-library-panel-postdecision-data-unavailable-v1",
            "structural_instance_sha256" => repeat("1", 64),
            "structural_result_terminal_and_audited_before_open" => true,
            "available" => false,
            "postdecision_opened" => true,
            "origin_wide_unavailability" => true,
            "return_imputed" => false,
            "zero_return_substituted" => false,
            "unavailable_algorithm_row_count" => 7,
            "licensed_rows_included" => false,
            "corrective_execution_amendment_id" => "AMENDMENT_020",
            "return_quality" => Dict(
                "interior_missing_return_rows" => 0,
                "unexpected_return_flag_rows" => 0,
                "unused_close_missing_rows" => 0,
                "unused_volume_missing_rows" => 0,
                "terminal_delisting_pending_rows" => 1,
                "postdecision_return_complete" => 0,
            ),
        )
        write(joinpath(structural_directory, stem * ".toml"), FSLP1.toml_text(structural))
        write(joinpath(postdecision_directory, stem * ".toml"), FSLP1.toml_text(postdecision))
        paths = (
            root = directory,
            structural = structural_directory,
            postdecision = postdecision_directory,
        )
        audit = FSLP1Runner._invoke_latest_binding(
            audit_module,
            :_audit_postdecision_stem,
            stem,
            paths,
        )
        @test isempty(audit.errors)
        @test audit.checked_rows == 7
        @test audit.postdecision_data_unavailable_count == 1
        profile_unavailable = Dict{String,Any}(
            "schema_version" =>
                "financial-strategy-library-panel-postdecision-profile-unavailable-v1",
            "structural_instance_sha256" => repeat("1", 64),
            "structural_result_terminal_and_audited_before_open" => true,
            "available" => false,
            "reason" => "registered belief profile has too few observations",
            "postdecision_opened" => true,
            "origin_wide_unavailability" => true,
            "minimum_observations_per_belief" => 25,
            "checked_distinct_security_count" => 3,
            "profile_imputed" => false,
            "belief_states_pooled" => false,
            "minimum_relaxed" => false,
            "postdecision_score_fabricated" => false,
            "unavailable_algorithm_row_count" => 7,
            "licensed_rows_included" => false,
            "corrective_execution_amendment_id" => "AMENDMENT_020",
            "return_quality" => Dict(
                "interior_missing_return_rows" => 0,
                "unexpected_return_flag_rows" => 0,
                "unused_close_missing_rows" => 0,
                "unused_volume_missing_rows" => 0,
                "terminal_delisting_pending_rows" => 0,
                "postdecision_return_complete" => 1,
            ),
        )
        write(
            joinpath(postdecision_directory, stem * ".toml"),
            FSLP1.toml_text(profile_unavailable),
        )
        profile_audit = FSLP1Runner._invoke_latest_binding(
            audit_module,
            :_audit_postdecision_stem,
            stem,
            paths,
        )
        @test isempty(profile_audit.errors)
        @test profile_audit.checked_rows == 7
        @test profile_audit.postdecision_profile_unavailable_count == 1
    end
    progress = IOBuffer()
    parallel_results, worker_thread_ids = FSLP1Runner._invoke_latest_binding(
        audit_module,
        :_parallel_indexed_audits,
        identity,
        collect(1:64);
        progress_io = progress,
    )
    @test parallel_results == collect(1:64)
    @test length(unique(worker_thread_ids)) == 8
    progress_text = String(take!(progress))
    @test occursin("0/64", progress_text)
    @test occursin("64/64", progress_text)
    @test occursin("structural-audit", progress_text)
    progress_counts = Int[
        parse(Int, first(split(last(split(line)), '/'))) for
        line in split(chomp(progress_text), '\n')
    ]
    @test progress_counts == collect(0:64)
    postdecision_progress = IOBuffer()
    _, postdecision_thread_ids = FSLP1Runner._invoke_latest_binding(
        audit_module,
        :_parallel_indexed_audits,
        identity,
        collect(1:64);
        progress_io = postdecision_progress,
        progress_label = "postdecision-audit",
    )
    @test length(unique(postdecision_thread_ids)) == 8
    @test occursin("postdecision-audit", String(take!(postdecision_progress)))
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
    adequacy = FSLP1.postdecision_profile_adequacy(
        collect(values(instances)),
        origin,
        series,
        Float64.(metadata["belief_thresholds"]),
        config,
        amendment,
    )
    @test adequacy.available === false
    @test adequacy.minimum_observations_per_belief == 25
    @test adequacy.reason == "registered belief profile has too few observations"
    @test adequacy.checked_security_count > 0
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
        scan_updates = NamedTuple[]
        structural = FSLP1.extract_origin_series(
            config,
            [gzip_path],
            origins;
            phase = :structural,
            diagnostics = structural_quality,
            progress_callback = update -> push!(scan_updates, update),
        )
        @test getfield.(structural["TEST-O2005"][1], :date) == ["2005-12-30"]
        @test getfield.(structural["TEST-O2006"][1], :date) ==
              ["2005-12-30", "2006-12-29"]
        @test structural_quality["TEST-O2005"]["new_security_initialization_rows_excluded"] == 1
        @test structural_quality["TEST-O2006"]["new_security_initialization_rows_excluded"] == 1
        @test first(scan_updates).state == "file-started"
        @test last(scan_updates).state == "file-completed"
        @test last(scan_updates).file_index == 1
        @test last(scan_updates).file_count == 1
        @test last(scan_updates).source_rows_scanned == 4
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

        unused_csv_path = joinpath(root, "unused_market_fields.csv")
        unused_gzip_path = unused_csv_path * ".gz"
        open(unused_csv_path, "w") do io
            println(io, "permno,dlycaldt,dlyret,dlyclose,dlyprc,dlyvol,dlydelflg,dlyretmissflg")
            println(io, "1,2005-12-30,0.01,10,10,1000,N,NA")
            println(io, "1,2006-12-29,0.02,,,,N,NA")
        end
        open(unused_gzip_path, "w") do output
            run(pipeline(`gzip -c -- $unused_csv_path`; stdout = output))
        end
        unused_quality = Dict{String,Any}()
        unused_postdecision = FSLP1.extract_origin_series(
            config,
            [unused_gzip_path],
            [origins[1]];
            phase = :postdecision,
            diagnostics = unused_quality,
        )
        @test ismissing(last(unused_postdecision["TEST-O2005"][1]).close)
        @test ismissing(last(unused_postdecision["TEST-O2005"][1]).volume)
        @test unused_quality["TEST-O2005"]["unused_close_missing_rows"] == 1
        @test unused_quality["TEST-O2005"]["unused_volume_missing_rows"] == 1
        @test_throws ErrorException FSLP1.extract_origin_series(
            config,
            [unused_gzip_path],
            [origins[2]];
            phase = :structural,
        )

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
    mktemp() do path, io
        write(io, serialized)
        flush(io)
        file_sha256 = FSLP1Runner._sha256_file(path)
        @test file_sha256 == journal_compression_instance_sha256(job.instance)
        @test FSLP1.audit_instance_result(
            job.instance,
            first_payload;
            precomputed_instance_sha256 = file_sha256,
        )["passed"]
        @test !FSLP1.audit_instance_result(
            job.instance,
            first_payload;
            precomputed_instance_sha256 = repeat("0", 64),
        )["passed"]
    end

    tampered = deepcopy(first_payload)
    row = first(filter(record -> record["candidate_returned"], tampered["algorithms"]))
    row["selection"]["exact_burden"] = "999//1"
    @test !FSLP1.audit_instance_result(job.instance, tampered)["passed"]
end

@testset "full-preprocessing DP guard and algorithm-level resume" begin
    modules = [Symbol("m$index") for index in 1:31]
    provenance = JournalCompressionProvenance(
        :synthetic,
        "panel-dp-guard-32",
        "synthetic execution guard fixture";
        generator = "test_financial_strategy_library_panel_v1_execution",
    )
    instance = journal_compression_instance_from_components(
        [:inactive, :bundle],
        Bool[true, false],
        [0, 1],
        [:zero],
        zeros(Int, 2, 1),
        [Symbol[], modules];
        provenance,
    )
    @test length(instance.requirements) == 32
    config, _ = FSLP1.load_panel_config()
    checkpoints = Dict{String,Any}()
    progress = Any[]
    payload, _ = FSLP1.run_algorithm_suite(
        instance;
        origin_id = "SMOKE-O99",
        library_id = "full_factorial_catalog",
        schedule_id = "validation_work_units",
        config,
        progress_callback = update -> push!(progress, update),
        checkpoint_callback = function(algorithm_id, record, selection, logs)
            checkpoints[algorithm_id] = (
                record = deepcopy(record),
                selection = isnothing(selection) ? nothing : copy(selection),
            )
        end,
    )
    dp = only(filter(
        record -> record["algorithm_id"] == "requirement_mask_dp",
        payload["algorithms"],
    ))
    @test dp["applicable"]
    @test dp["candidate_returned"]
    @test dp["selection"]["exact_burden"] == "1//1"
    completed_preprocessing = only(filter(
        update -> update.stage == "preprocessing" && update.state == "completed",
        progress,
    ))
    @test completed_preprocessing.residual_requirements == 0
    @test completed_preprocessing.residual_strategies == 0
    @test length(checkpoints) == 7

    resumed_progress = Any[]
    resumed_payload, resumed_logs = FSLP1.run_algorithm_suite(
        instance;
        origin_id = "SMOKE-O99",
        library_id = "full_factorial_catalog",
        schedule_id = "validation_work_units",
        config,
        progress_callback = update -> push!(resumed_progress, update),
        checkpoint_callback = (args...) -> error("a resumed algorithm was rerun"),
        resume_algorithms = checkpoints,
    )
    @test isempty(resumed_logs)
    @test count(update -> update.state == "resumed", resumed_progress) == 7
    @test resumed_payload["benchmark_burden"] == payload["benchmark_burden"]
    @test resumed_payload["algorithms"] == payload["algorithms"]
    @test FSLP1.audit_instance_result(instance, resumed_payload)["passed"]
end

@testset "atomic algorithm checkpoint round trip" begin
    config, _ = FSLP1.load_panel_config()
    job = first(FSLP1.build_synthetic_smoke_instances())
    payload, logs = FSLP1.run_algorithm_suite(
        job.instance;
        origin_id = job.origin_id,
        library_id = job.library_id,
        schedule_id = job.schedule_id,
        config,
    )
    record = first(payload["algorithms"])
    selected = FSLP1Runner._checkpoint_selection(job.instance, record)
    mktempdir() do root
        output = (
            local_results = root,
            checkpoints = joinpath(root, "checkpoints"),
            solver_logs = joinpath(root, "solver_logs"),
        )
        lock_hash = repeat("a", 64)
        algorithm_logs = haskey(logs, record["algorithm_id"]) ?
                         Dict(record["algorithm_id"] => logs[record["algorithm_id"]]) :
                         Dict{String,String}()
        path = FSLP1Runner._write_algorithm_checkpoint(
            output,
            "fixture",
            job.instance,
            lock_hash,
            record["algorithm_id"],
            record,
            selected,
            algorithm_logs,
        )
        @test isfile(path)
        restored = FSLP1Runner._load_algorithm_checkpoints(
            output,
            "fixture",
            job.instance,
            lock_hash,
        )
        @test haskey(restored, record["algorithm_id"])
        @test restored[record["algorithm_id"]].record == record
        @test restored[record["algorithm_id"]].selection == selected
        @test_throws ErrorException FSLP1Runner._write_algorithm_checkpoint(
            output,
            "fixture",
            job.instance,
            lock_hash,
            record["algorithm_id"],
            record,
            selected,
            algorithm_logs,
        )
        @test_throws ErrorException FSLP1Runner._load_algorithm_checkpoints(
            output,
            "fixture",
            job.instance,
            repeat("b", 64),
        )
    end

    mip_record = only(filter(
        row -> row["algorithm_id"] == "jump_highs_tagged_cover",
        payload["algorithms"],
    ))
    mip_selection = FSLP1Runner._checkpoint_selection(job.instance, mip_record)
    failed_mip_record = deepcopy(mip_record)
    failed_mip_record["status"] = "ERROR"
    failed_mip_record["candidate_returned"] = false
    failed_mip_record["failure_type"] = "ArgumentError"
    failed_mip_record["failure_message"] =
        "ArgumentError: the supplied warm start is not feasible after exact preprocessing projection"
    pop!(failed_mip_record, "selection", nothing)
    @test FSLP1Runner._known_mip_projection_failure(failed_mip_record)
    mktempdir() do root
        output = (
            local_results = root,
            checkpoints = joinpath(root, "checkpoints"),
            solver_logs = joinpath(root, "solver_logs"),
        )
        predecessor_path = FSLP1Runner._write_algorithm_checkpoint(
            output,
            "corrective-fixture",
            job.instance,
            FSLP1Runner.LOCK_005_AGGREGATE,
            "jump_highs_tagged_cover",
            failed_mip_record,
            nothing,
            Dict{String,String}(),
        )
        @test isfile(predecessor_path)
        mip_logs = haskey(logs, "jump_highs_tagged_cover") ?
                   Dict("jump_highs_tagged_cover" => logs["jump_highs_tagged_cover"]) :
                   Dict{String,String}()
        corrected_lock = repeat("c", 64)
        corrected_path = FSLP1Runner._write_algorithm_checkpoint(
            output,
            "corrective-fixture",
            job.instance,
            corrected_lock,
            "jump_highs_tagged_cover",
            mip_record,
            mip_selection,
            mip_logs;
            replace_known_mip_projection_failure = true,
        )
        @test corrected_path == predecessor_path
        corrected = TOML.parsefile(corrected_path)
        @test corrected["corrective_execution_amendment_id"] == "AMENDMENT_020"
        @test corrected["corrected_predecessor_execution_lock_aggregate_sha256"] ==
              FSLP1Runner.LOCK_005_AGGREGATE
        @test corrected["execution_lock_aggregate_sha256"] == corrected_lock
        @test corrected["record"]["candidate_returned"] === true
        @test_throws ErrorException FSLP1Runner._write_algorithm_checkpoint(
            output,
            "corrective-fixture",
            job.instance,
            repeat("d", 64),
            "jump_highs_tagged_cover",
            mip_record,
            mip_selection,
            mip_logs;
            replace_known_mip_projection_failure = true,
        )
    end
    @test FSLP1Runner._known_lock019_checkpoint_namespace_failure(Dict(
        "schema_version" => "financial-strategy-library-panel-instance-failure-v1",
        "failure_type" => "ErrorException",
        "failure_message" => "corrective checkpoint is not bound to Lock 018: fixture",
    ))
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
    completed = FSLP1Runner._run_threaded_lanes!(collect(1:8), "lane-test", run_lane; lanes = 8)
    @test completed.completed == 8
    @test isempty(completed.failures)
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
    retained = FSLP1Runner._run_threaded_lanes!(
        collect(1:8),
        "retained-failure-test",
        fail_lane;
        lanes = 8,
        allow_failures = true,
    )
    @test retained.completed == 8
    @test length(retained.failures) == 1
    @test only(retained.failures).job == 3
    progress_seen = Threads.Atomic{Int}(0)
    progress_lane = function(job, lane, report)
        report((
            stage = "preprocessing",
            state = "started",
            algorithm_id = nothing,
        ))
        Threads.atomic_add!(progress_seen, 1)
        sleep(0.05)
        return nothing
    end
    progress_text = mktemp() do _, io
        progress_result = redirect_stderr(io) do
            FSLP1Runner._run_threaded_lanes!(
                [1],
                "heartbeat-test",
                progress_lane;
                lanes = 1,
                heartbeat_seconds = 0.01,
            )
        end
        @test progress_result.completed == 1
        flush(io)
        seekstart(io)
        read(io, String)
    end
    @test progress_seen[] == 1
    @test occursin("heartbeat-test", progress_text)
    @test occursin("preprocessing", progress_text)
    @test count(==('\n'), progress_text) >= 3
    @test !occursin('\r', progress_text)
    @test !occursin('\e', progress_text)
    @test_throws ErrorException FSLP1Runner._run_threaded_lanes!(
        [1],
        "invalid-heartbeat",
        (job, lane) -> nothing;
        lanes = 1,
        heartbeat_seconds = 0,
    )
end

@testset "validated preparation reuse dispatch" begin
    mktempdir() do root
        output = (preparation_manifest = joinpath(root, "PREPARATION_MANIFEST.toml"),)
        prepared = Ref(0)
        validated = Ref(0)
        prepare_callback = function()
            prepared[] += 1
            write(output.preparation_manifest, "fixture = true\n")
            return nothing
        end
        validate_callback = function(candidate)
            validated[] += 1
            read(candidate.preparation_manifest, String) == "fixture = true\n" ||
                error("tampered preparation fixture")
            return true
        end
        @test FSLP1Runner._ensure_preparation_for_run(
            output;
            prepare_callback,
            validate_callback,
        ) == :created
        @test prepared[] == 1
        @test validated[] == 1
        @test FSLP1Runner._ensure_preparation_for_run(
            output;
            prepare_callback,
            validate_callback,
        ) == :reused
        @test prepared[] == 1
        @test validated[] == 2
        write(output.preparation_manifest, "fixture = false\n")
        @test_throws ErrorException FSLP1Runner._ensure_preparation_for_run(
            output;
            prepare_callback,
            validate_callback,
        )
        @test prepared[] == 1
    end
end

@testset "registered preparation failure records" begin
    job = (
        origin_id = "FSLP1-O2005",
        library_id = "centralized_research_pool",
        schedule_id = "equal_active_strategy",
        stem = "fixture",
    )
    exception = ErrorException("a registered belief profile has too few observations")
    @test FSLP1Runner._is_registered_origin_rejection(exception)
    @test !FSLP1Runner._is_registered_origin_rejection(ErrorException("unexpected fixture"))
    payload = FSLP1Runner._preparation_failure_payload(
        job,
        "../local_data/origin_failures/FSLP1-O2005.toml",
        repeat("a", 64),
        exception,
    )
    @test payload["terminal"] === true
    @test payload["source_instance_available"] === false
    @test payload["source_instance_fabricated"] === false
    @test payload["algorithm_terminal_row_count"] == 7
    @test payload["failure_message"] == "registered belief profile has too few observations"
    @test payload["postdecision_opened"] === false
    structural = FSLP1Runner._preparation_failure_result(
        job,
        merge(payload, Dict("record_sha256" => repeat("b", 64))),
        4,
    )
    @test structural["terminal"] === true
    @test structural["source_instance_available"] === false
    @test structural["preparation_failure_sha256"] == repeat("b", 64)
end
