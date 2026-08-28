using StrategyInnovation
using Test

include(joinpath(@__DIR__, "..", "scripts", "export_tagged_cover_theorem_fixture.jl"))
using .TaggedCoverTheoremFixture

include(joinpath(@__DIR__, "..", "scripts", "audit_journal_result_directory.jl"))
using .JournalExactnessAuditCLI

include(joinpath(@__DIR__, "..", "scripts", "solve_journal_compression_instance.jl"))
using .JournalCompressionExactCLI

include("test_tagged_cover.jl")
include("test_tagged_cover_preprocessing.jl")
include("test_journal_compression_instance.jl")
include("test_exact_journal_compression.jl")
include("test_greedy_journal_compression.jl")
include("test_certified_deletion_journal_compression.jl")
include("test_journal_compression_mip.jl")
include("test_journal_exactness_audit.jl")
