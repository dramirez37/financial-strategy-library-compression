include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV2Execution.jl"))
using .FinancialStrategyLibraryPanelV2Execution

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: run_financial_strategy_library_panel_v2.jl --smoke|--run-all|--verify-seal",
    )
    mode = only(args)
    mode == "--smoke" && return println(FinancialStrategyLibraryPanelV2Execution.run_synthetic_smoke())
    mode == "--run-all" && return println(FinancialStrategyLibraryPanelV2Execution.run_all())
    mode == "--verify-seal" && return println(FinancialStrategyLibraryPanelV2Execution.verify_predecision_seal())
    error("unknown v2 execution mode: $mode")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
