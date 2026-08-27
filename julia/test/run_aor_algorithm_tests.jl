using StrategyInnovation
using Test

include(joinpath(@__DIR__, "..", "scripts", "audit_journal_result_directory.jl"))
using .JournalExactnessAuditCLI

include("test_journal_exactness_audit.jl")
