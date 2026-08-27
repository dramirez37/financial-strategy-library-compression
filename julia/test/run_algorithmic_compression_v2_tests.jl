using Pkg

Pkg.activate(joinpath(@__DIR__, ".."))

using Test
using StrategyInnovation
using TOML

include(joinpath(@__DIR__, "test_algorithmic_compression_v2.jl"))
