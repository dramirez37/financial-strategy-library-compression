using Test

include(joinpath(
    @__DIR__,
    "..",
    "scripts",
    "stage_financial_strategy_library_panel_v3_proposal_returns.jl",
))
const ProposalStage = StageFinancialStrategyLibraryPanelV3ProposalReturns

@testset "v3 proposal masked staging excludes failed and evaluation rows" begin
    result = ProposalStage.proposal_leakage_sentinel()
    @test result["status"] == "SYNTHETIC_PROPOSAL_MASK_PASSED"
    @test result["proposal_rows_materialized"] == 1
    @test result["failed_cell_rows_materialized"] == 0
    @test result["evaluation_rows_inspected_materialized_or_used"] == 0
end

@testset "v3 proposal combined history is security-contiguous and terminal-safe" begin
    cell = ProposalStage.ProposalCell(
        1,
        "O",
        "u",
        "primary",
        "PASSED",
        true,
        2001,
        2002,
        "2000-12-31",
        Set([10, 20]),
        "",
        "",
    )
    pre = (;
        permno = Int64[10, 10, 20, 20],
        date = ["2000-12-28", "2000-12-29", "2000-12-28", "2000-12-29"],
        total_return = Union{Missing,Float64}[0.01, -1.0, 0.02, 0.03],
        return_available = trues(4),
        terminal_delisting = Bool[false, true, false, false],
        return_flag = fill("NA", 4),
        delisting_flag = ["N", "D", "N", "N"],
    )
    sparse = ProposalStage.SparseProposalBuffer()
    append!(sparse.permno, Int64[20, 20])
    append!(sparse.date, ["2001-01-02", "2001-01-03"])
    append!(sparse.total_return, Union{Missing,Float64}[0.04, missing])
    append!(sparse.return_available, Bool[true, false])
    append!(sparse.terminal_delisting, falses(2))
    append!(sparse.return_flag, ["NA", "MISSING"])
    append!(sparse.delisting_flag, ["N", "N"])
    combined = ProposalStage._combine_columns(
        cell,
        sparse,
        ["2001-01-02", "2001-01-03"],
        pre,
    )
    @test combined.permno == Int64[10, 10, 10, 10, 20, 20, 20, 20]
    @test combined.date[1:4] == [
        "2000-12-28", "2000-12-29", "2001-01-02", "2001-01-03",
    ]
    @test combined.return_flag[3:4] == ["POST_TERMINAL_CASH", "POST_TERMINAL_CASH"]
    @test combined.return_available[7:8] == Bool[true, false]
    @test combined.total_return[7] == 0.04
    @test ismissing(combined.total_return[8])
end
