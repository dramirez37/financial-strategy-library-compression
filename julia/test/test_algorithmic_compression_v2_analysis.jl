using Test

include(joinpath(@__DIR__, "..", "scripts", "analyze_algorithmic_compression_v2.jl"))
using .AlgorithmicCompressionAnalysisV2

@testset "Locked v2 analysis inputs and reference rules" begin
    @test AlgorithmicCompressionAnalysisV2.parse_exact("3//2") == 3 // 2
    @test AlgorithmicCompressionAnalysisV2.parse_exact("UNAVAILABLE") === missing
    escaped = AlgorithmicCompressionAnalysisV2.latex_escape("O(n 2^r) & x_y \$z")
    @test occursin("\\textasciicircum{}", escaped)
    @test occursin("\\&", escaped)
    @test occursin("\\_", escaped)
    @test occursin("\\\$", escaped)
    @test AlgorithmicCompressionAnalysisV2.latex_escape("\\") == "\\textbackslash{}"
    @test AlgorithmicCompressionAnalysisV2.latex_display("MIP_OPTIMAL_EXACTLY_RECHECKED") == "MIP-optimal, exactly rechecked"
    @test AlgorithmicCompressionAnalysisV2.latex_display("UNAVAILABLE") == "--"

    data = AlgorithmicCompressionAnalysisV2.load_analysis_data()
    @test length(data.final_specs) == 173
    @test length(data.runs) == 3907
    @test data.audit["passed"] === true
    @test count(run -> run["solved"], data.runs) == data.audit["accepted_solution_count"]

    references, exact_rows = AlgorithmicCompressionAnalysisV2.establish_references(data)
    AlgorithmicCompressionAnalysisV2.enrich_runs!(data, references)
    @test length(exact_rows) == data.audit["exact_instance_count"] == 38
    @test count(row -> row["exact_agreement"] === true, exact_rows) == data.audit["exact_agreement_count"] == 31
    @test count(row -> row["optimizer_identity_difference"] === true, exact_rows) == data.audit["optimizer_identity_difference_count"] == 9
    @test count(row -> row["exact_agreement"] !== true, exact_rows) == data.audit["exact_agreement_unavailable_count"] == 7
    @test all(run -> run["relative_gap"] === missing || run["relative_gap"] >= 0, data.runs)
    @test isempty(AlgorithmicCompressionAnalysisV2.timeout_rows(data))

    trace = AlgorithmicCompressionAnalysisV2.trace_rows(data)
    @test length(trace) == 3907
    @test all(row -> isfile(joinpath(AlgorithmicCompressionAnalysisV2.REPOSITORY_ROOT, row["record_path"])), trace)
    @test all(row -> length(row["record_sha256"]) == 64, trace)
    @test all(row -> AlgorithmicCompressionAnalysisV2.sha256_file(joinpath(AlgorithmicCompressionAnalysisV2.REPOSITORY_ROOT, row["record_path"])) == row["record_sha256"], trace)

    manifest = AlgorithmicCompressionAnalysisV2.read_csv(joinpath(AlgorithmicCompressionAnalysisV2.TABLE_ROOT, "ANALYSIS_ARTIFACT_MANIFEST.csv"))
    @test length(manifest) == 67
    @test all(row -> AlgorithmicCompressionAnalysisV2.sha256_file(joinpath(AlgorithmicCompressionAnalysisV2.REPOSITORY_ROOT, row["path"])) == row["sha256"], manifest)

    runtime_table = joinpath(AlgorithmicCompressionAnalysisV2.TABLE_ROOT, "figure_runtime_vs_size_data.csv")
    @test AlgorithmicCompressionAnalysisV2.csv_fields(first(readlines(runtime_table))) == ["family", "requirement_count", "strategy_count", "algorithm_id", "algorithm", "registered_n", "median_par2_seconds", "q25_par2_seconds", "q75_par2_seconds", "trace_join_key"]
    solved_svg = read(joinpath(AlgorithmicCompressionAnalysisV2.FIGURE_ROOT, "solved_fraction_grid.svg"), String)
    root_match = match(r"<svg[^>]*width=\"([0-9.]+)\" height=\"([0-9.]+)\"", solved_svg)
    @test root_match !== nothing
    @test parse(Float64, root_match.captures[1]) >= 2190
    @test occursin("role=\"img\"", solved_svg)
end
