const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
ENV["ALGOLIB_FINANCIAL_PANEL_SEED_NAMESPACE"] =
    "financial-strategy-library-panel-v2-flagship-restart-003"

include(joinpath(@__DIR__, "audit_financial_strategy_library_panel_v2.jl"))

if abspath(PROGRAM_FILE) == @__FILE__
    AuditFinancialStrategyLibraryPanelV2.main()
end
