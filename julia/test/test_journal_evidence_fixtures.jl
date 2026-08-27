using Test
using TOML

@testset "exact Julia-Lean journal evidence fixture bridge" begin
    @test JournalEvidenceFixtureExporter.GAP_OPTIMUM_BURDEN == 3 // 2
    @test JournalEvidenceFixtureExporter.GAP_RATIO == 8 // 3
    @test JournalEvidenceFixtureExporter.DP_TAKE_MASK == Bool[true, true, true]
    @test JournalEvidenceFixtureExporter.GREEDY_FIXTURE_BURDEN == 11 // 6
    @test JournalEvidenceFixtureExporter.GREEDY_FIXTURE_OPTIMUM == 13 // 12
    @test JournalEvidenceFixtureExporter.GREEDY_FIXTURE_RATIO == 22 // 13
    @test JournalEvidenceFixtureExporter.check_outputs()
    fixture = TOML.parsefile(JournalEvidenceFixtureExporter.FIXTURE_PATH)
    @test fixture["schema_version"] == "journal-formal-evidence-fixture-v1"
    @test fixture["gap"]["ratio"] == "8//3"
    @test fixture["requirement_mask"]["take_union"] == [true, true, true]
    @test fixture["preprocessing"]["unique_requirement_index"] == 0
    @test fixture["preprocessing"]["forced_strategy_index"] == 0
    @test fixture["weighted_greedy"]["ratio"] == "22//13"
end
