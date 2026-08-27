using Test

include(joinpath(@__DIR__, "..", "scripts", "export_journal_evidence_fixtures.jl"))
using .JournalEvidenceFixtureExporter

include("test_journal_evidence_fixtures.jl")
