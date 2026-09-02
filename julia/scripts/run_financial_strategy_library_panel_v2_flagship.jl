const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
ENV["ALGOLIB_FINANCIAL_PANEL_CONFIG_OVERRIDE_PATH"] = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_strategy_library_panel_v2_flagship_override.toml",
)
ENV["ALGOLIB_FINANCIAL_PANEL_SEED_NAMESPACE"] =
    "financial-strategy-library-panel-v2-flagship-restart-003"

include(joinpath(@__DIR__, "..", "src", "FinancialStrategyLibraryPanelV2Execution.jl"))
using .FinancialStrategyLibraryPanelV2Execution

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: run_financial_strategy_library_panel_v2_flagship.jl --smoke|--run-all|--verify-seal",
    )
    mode = only(args)
    mode == "--smoke" && return println(FinancialStrategyLibraryPanelV2Execution.run_synthetic_smoke())
    mode == "--run-all" && return println(FinancialStrategyLibraryPanelV2Execution.run_all())
    mode == "--verify-seal" && return println(FinancialStrategyLibraryPanelV2Execution.verify_predecision_seal())
    error("unknown flagship financial-panel execution mode: $mode")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
