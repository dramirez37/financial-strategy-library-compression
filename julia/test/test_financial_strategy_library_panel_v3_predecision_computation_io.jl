using Parquet
using Test

include(joinpath(
    @__DIR__,
    "..",
    "scripts",
    "run_financial_strategy_library_panel_v3_predecision_computation.jl",
))

const V3RUN = RunFinancialStrategyLibraryPanelV3PredecisionComputation

@testset "v3 computation Parquet.Table compatibility sentinel" begin
    mktempdir() do directory
        path = joinpath(directory, "synthetic-stage.parquet")
        Parquet.write_parquet(path, (;
            permno = Int64[10, 10, 20, 20],
            date = ["2000-01-03", "2000-01-04", "2000-01-03", "2000-01-04"],
            total_return = [0.01, -1.0, 0.02, 0.03],
            return_available = trues(4),
            terminal_delisting = Bool[false, true, false, false],
            return_flag = fill("NA", 4),
            delisting_flag = ["N", "D", "N", "N"],
        ))
        columns = V3RUN._parquet_columns(path)
        @test propertynames(columns) == (
            :permno,
            :date,
            :total_return,
            :return_available,
            :terminal_delisting,
            :return_flag,
            :delisting_flag,
        )
        @test collect(skipmissing(columns.permno)) == [10, 10, 20, 20]
        @test collect(skipmissing(columns.total_return)) == [0.01, -1.0, 0.02, 0.03]
        @test count(identity, collect(skipmissing(columns.terminal_delisting))) == 1
    end
end

