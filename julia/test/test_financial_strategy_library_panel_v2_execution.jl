using Test

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV2Execution.jl"))
using .FinancialStrategyLibraryPanelV2Execution

@testset "financial strategy-library panel v2 execution smoke" begin
    smoke = run_synthetic_smoke()
    @test smoke["passed"]
    @test smoke["solver_claimed_optimal"]
    @test !smoke["exact_global_optimum_verified"]
    @test smoke["exact_burden"] == "4//1"
end

@testset "financial panel v2 complete-case missing-return registry" begin
    known = Set(["DG", "DM", "DP", "GP", "MP", "MV", "NS", "NT", "RA"])
    @test all(
        FinancialStrategyLibraryPanelV2Execution._known_missing_return_flag,
        known,
    )
    @test !FinancialStrategyLibraryPanelV2Execution._known_missing_return_flag("NA")
    @test !FinancialStrategyLibraryPanelV2Execution._known_missing_return_flag("")
    @test !FinancialStrategyLibraryPanelV2Execution._known_missing_return_flag("ZZ")
end

@testset "financial panel v2 mixed liquid-market classification" begin
    common = FinancialStrategyLibraryPanelV2Execution.V2MarketInterval(
        1, "2000-01-01", "2025-12-31", "ABC", "ABC CORP", "N", "RW", "A",
        "Y", "CORP", "EQTY", "COM", "NS",
    )
    etf = FinancialStrategyLibraryPanelV2Execution.V2MarketInterval(
        2, "2000-01-01", "2025-12-31", "ETF", "PLAIN ETF", "R", "RW", "A",
        "Y", "ACOR", "FUND", "ETF", "NS",
    )
    adr = FinancialStrategyLibraryPanelV2Execution.V2MarketInterval(
        3, "2000-01-01", "2025-12-31", "ADR", "ADR", "N", "RW", "A",
        "Y", "CORP", "EQTY", "COM", "AD",
    )
    @test FinancialStrategyLibraryPanelV2Execution._instrument_class(common) == "common_equity"
    @test FinancialStrategyLibraryPanelV2Execution._instrument_class(etf) == "plain_etf"
    @test isempty(FinancialStrategyLibraryPanelV2Execution._instrument_class(adr))
end

@testset "financial panel v2 file-local parallel staging buffers" begin
    if Threads.nthreads() > 1
        mktempdir() do directory
            config = load_execution_config()
            root = joinpath(directory, "chunks")
            mkpath(root)
            sources = String[]
            for file_index in 1:3
                csv = joinpath(directory, "source-$file_index.csv")
                gzip = csv * ".gz"
                open(csv, "w") do io
                    println(io, "permno,dlycaldt,dlyret,dlyclose,dlyprc,dlyvol,dlydelflg,dlyretmissflg")
                    println(io, "1,200$(file_index)-01-02,0.01,10,10,100,N,NA")
                    println(io, "1,200$(file_index)-01-03,-1.0,10,10,100,Y,NA")
                    println(io, "1,200$(file_index)-01-04,0.00,10,10,100,Y,MV")
                    println(io, "1,200$(file_index)-01-05,,10,10,100,N,NS")
                end
                open(gzip, "w") do io
                    run(pipeline(`gzip -c -- $csv`; stdout = io))
                end
                push!(sources, gzip)
            end
            chunks = Vector{Any}(undef, 3)
            quality = Vector{Any}(undef, 3)
            Threads.@threads :static for file_index in 1:3
                chunks[file_index], quality[file_index] =
                    FinancialStrategyLibraryPanelV2Execution._stage_master_market_file(
                        config,
                        sources[file_index],
                        Set([1]),
                        root,
                        file_index,
                        3,
                    )
            end
            @test length.(chunks) == [1, 1, 1]
            @test [row["retained_master_rows"] for row in quality] == [4, 4, 4]
            @test [row["flagged_finite_return_rows"] for row in quality] == [1, 1, 1]
            @test length(filter(endswith(".parquet"), readdir(root))) == 3
        end
    else
        @test_skip "parallel staging smoke requires multiple Julia threads"
    end
end


@testset "financial strategy-library panel v2 structural smoke" begin
    smoke = run_structural_smoke()
    @test smoke["passed"]
    @test smoke["menu_count"] == 32
    @test smoke["source_strategy_count"] > 0
end

@testset "financial panel flagship regime-profile shrinkage" begin
    shrink = FinancialStrategyLibraryPanelV2Execution._shrunk_regime_utility
    @test shrink(9.0, 3.0, 0, 25) == 3.0
    @test shrink(9.0, 3.0, 25, 25) == 6.0
    @test shrink(9.0, 3.0, 2500, 25) > 8.9
    @test_throws ArgumentError shrink(9.0, 3.0, -1, 25)
    @test_throws ArgumentError shrink(9.0, 3.0, 1, -1)
end

@testset "financial panel flagship seeds are fresh and deterministic" begin
    registry = FinancialStrategyLibraryPanelV2Execution.FinancialStrategyLibraryPanelV2Registries
    original = get(ENV, "ALGOLIB_FINANCIAL_PANEL_SEED_NAMESPACE", nothing)
    try
        ENV["ALGOLIB_FINANCIAL_PANEL_SEED_NAMESPACE"] =
            registry.DEFAULT_SEED_NAMESPACE
        predecessor = registry.seed_rows()
        ENV["ALGOLIB_FINANCIAL_PANEL_SEED_NAMESPACE"] =
            "financial-strategy-library-panel-v2-flagship-restart-003"
        first_pass = registry.seed_rows()
        second_pass = registry.seed_rows()
        predecessor_values = Set(vcat(
            getfield.(predecessor, :menu_seed),
            getfield.(predecessor, :multistart_seed),
            getfield.(predecessor, :origin_bootstrap_seed),
        ))
        flagship_values = Set(vcat(
            getfield.(first_pass, :menu_seed),
            getfield.(first_pass, :multistart_seed),
            getfield.(first_pass, :origin_bootstrap_seed),
        ))
        @test isempty(intersect(predecessor_values, flagship_values))
        @test first_pass == second_pass
    finally
        if isnothing(original)
            delete!(ENV, "ALGOLIB_FINANCIAL_PANEL_SEED_NAMESPACE")
        else
            ENV["ALGOLIB_FINANCIAL_PANEL_SEED_NAMESPACE"] = original
        end
    end
end
