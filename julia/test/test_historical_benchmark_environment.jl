using Test
include(joinpath(@__DIR__, "../scripts/check_algorithmic_compression_final_v2.jl"))
using .CheckAlgorithmicCompressionFinalV2: verify_environment_extension

@testset "Historical benchmark environment extension guard" begin
    project = Dict{String,Any}("name" => "StrategyInnovation",
        "deps" => Dict("Solver" => "solver-uuid"),
        "compat" => Dict("Solver" => "1"))
    manifest = Dict{String,Any}("julia_version" => "1.12.6", "manifest_format" => "2.0",
        "deps" => Dict{String,Any}(
            "Solver" => [Dict("uuid" => "solver-uuid", "version" => "1.0.0", "git-tree-sha1" => "original")],
            "StrategyInnovation" => [Dict{String,Any}("path" => ".", "deps" => ["Solver"]) ]))
    current_project = deepcopy(project)
    current_project["deps"]["Storage"] = "storage-uuid"
    current_project["compat"]["Storage"] = "2"
    current_manifest = deepcopy(manifest)
    current_manifest["deps"]["Storage"] = [Dict("uuid" => "storage-uuid", "version" => "2.0.0")]
    push!(only(current_manifest["deps"]["StrategyInnovation"])["deps"], "Storage")
    @test isnothing(verify_environment_extension(project, current_project, manifest, current_manifest))
    for key in ("uuid", "version", "git-tree-sha1")
        altered = deepcopy(current_manifest)
        only(altered["deps"]["Solver"])[key] = "changed"
        @test_throws ErrorException verify_environment_extension(project, current_project, manifest, altered)
    end
    altered = deepcopy(current_manifest)
    delete!(altered["deps"], "Solver")
    @test_throws ErrorException verify_environment_extension(project, current_project, manifest, altered)
    altered = deepcopy(current_project)
    altered["compat"]["Solver"] = "2"
    @test_throws ErrorException verify_environment_extension(project, altered, manifest, current_manifest)
    altered = deepcopy(current_manifest)
    only(altered["deps"]["StrategyInnovation"])["path"] = "elsewhere"
    @test_throws ErrorException verify_environment_extension(project, current_project, manifest, altered)
    altered = deepcopy(current_manifest)
    only(altered["deps"]["StrategyInnovation"])["deps"] = ["Storage"]
    @test_throws ErrorException verify_environment_extension(project, current_project, manifest, altered)
end
