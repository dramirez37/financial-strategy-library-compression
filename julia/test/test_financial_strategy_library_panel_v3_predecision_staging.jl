using Parquet
using Test

include(joinpath(
    @__DIR__,
    "..",
    "scripts",
    "stage_financial_strategy_library_panel_v3_predecision_returns.jl",
))
using .StageFinancialStrategyLibraryPanelV3PredecisionReturns

@testset "v3 predecision exact source-row ranges" begin
    @test target_ranges(Int[]) == UnitRange{Int}[]
    @test target_ranges([2, 3, 7, 9, 10]) == [2:3, 7:7, 9:10]
    @test_throws ArgumentError target_ranges([2, 1])
    @test_throws ArgumentError target_ranges([1, 1])
end

@testset "v3 predecision return decode follows identifier/date filter" begin
    mktempdir() do directory
        path = joinpath(directory, "synthetic.parquet")
        Parquet.write_parquet(path, (;
            permno = Int64[10, 10, 10, 10, 20, 20, 20, 20],
            date = [
                "2000-01-03",
                "2000-01-04",
                "2001-01-02",
                "2002-01-02",
                "2000-01-03",
                "2000-01-04",
                "2001-01-02",
                "2002-01-02",
            ],
            total_return = [0.01, -1.0, NaN, -Inf, 0.03, 0.04, Inf, NaN],
            return_flag = ["NA", "NA", "FORBIDDEN", "FORBIDDEN", "NA", "NA", "X", "Y"],
            delisting_flag = ["N", "D", "FORBIDDEN", "FORBIDDEN", "N", "N", "X", "Y"],
        ))
        cells = [CellSpecification(
            1,
            "TEST-O2000",
            "liquid_common_equity",
            "common_equity",
            "primary",
            "PASSED",
            2000,
            2000,
            2001,
            2002,
            "2000-01-01",
            "2000-12-31",
            Set([10, 20]),
            2,
        )]
        extraction = StageFinancialStrategyLibraryPanelV3PredecisionReturns._extract_chunk(
            path,
            StageFinancialStrategyLibraryPanelV3PredecisionReturns._sha256_file(path),
            8,
            cells,
            StageFinancialStrategyLibraryPanelV3PredecisionReturns._cells_by_permno(cells),
        )
        @test extraction.identifier_date_rows_scanned == 8
        @test extraction.return_rows_materialized == 4
        @test extraction.exact_target_range_count == 2
        @test extraction.maximum_materialized_date == "2000-01-04"
        buffer = only(extraction.cell_buffers)
        @test buffer.total_return == [0.01, -1.0, 0.03, 0.04]
        @test all(buffer.return_available)
        @test count(identity, buffer.terminal_delisting) == 1
        @test all(<("2001-01-01"), buffer.date)
        @test StageFinancialStrategyLibraryPanelV3PredecisionReturns._sort_and_validate!(
            buffer,
            only(cells),
        ) === buffer
    end
end

@testset "v3 synthetic proposal/evaluation leakage sentinel" begin
    report = sentinel_leakage_test()
    @test report["status"] == "SYNTHETIC_SENTINEL_PASSED"
    @test report["postdecision_rows_present_in_source"] == 4
    @test report["postdecision_rows_inspected"] == 0
    @test report["postdecision_rows_materialized"] == 0
    @test report["postdecision_rows_used"] == 0
    @test report["terminal_delisting_rows_preserved"] == 1
    @test report["exact_negative_one_return_preserved"] === true
    @test report["adversarial_unmasked_variant_count"] == 2
    @test report["masked_outputs_identical_across_unmasked_variants"] === true
end

@testset "v3 locked selections form bounded predecision cells" begin
    contract = StageFinancialStrategyLibraryPanelV3PredecisionReturns._load_contract()
    cells = StageFinancialStrategyLibraryPanelV3PredecisionReturns._load_cells()
    @test length(cells) == 38
    @test sum(length(cell.selected_permnos) * cell.expected_sessions for cell in cells) == 4_247_707
    @test all(cell -> cell.decision_date < "$(cell.proposal_year)-01-01", cells)
    @test contract.design_lock["historical_proposal_or_evaluation_return_access_permitted"] === false
    @test contract.amendment_lock["historical_predecision_return_access_permitted"] === false
    @test contract.extractor_lock["historical_predecision_return_access_permitted"] === true
    @test contract.extractor_lock["historical_proposal_or_evaluation_return_access_permitted"] === false
end
