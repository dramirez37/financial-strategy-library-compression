module VerifyFinancialResourceOptimizationOutputs

using SHA: sha256
using TOML

if !isdefined(Main, :FinancialResourceOptimization)
    Base.include(Main, joinpath(@__DIR__, "run_financial_resource_optimization.jl"))
end

const ResourceOptimization = Main.FinancialResourceOptimization
const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = ResourceOptimization.DEFAULT_CONFIG

_require(condition::Bool, message::AbstractString) =
    condition ? true : error(message)
_repo_path(path::AbstractString) =
    isabspath(path) ? normpath(path) : normpath(joinpath(REPOSITORY_ROOT, path))

function _sha256_file(path::AbstractString)
    return open(path, "r") do io
        bytes2hex(sha256(io))
    end
end

function verify_outputs(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    design_hash = ResourceOptimization.DesignLock.verify_design_lock(config_path)
    parent_hashes = Dict{String,String}()
    for audit in config["audits"]
        merge!(parent_hashes, ResourceOptimization._verify_parent_artifacts(audit))
    end

    status_path = String(config["outputs"]["status_json"])
    _require(isfile(_repo_path(status_path)), "financial resource status is absent")
    status_text = read(_repo_path(status_path), String)
    for fragment in (
        "\"design_sha256\":\"$design_hash\"",
        "\"all_global_milp_statuses_optimal\":true",
        "\"all_global_safe_libraries_exactly_verified\":true",
        "\"all_safe_opportunity_quality_equalities_exact\":true",
        "\"parent_artifact_hashes_unchanged\":true",
        "\"held_out_quality_used_to_define_weights\":false",
        "\"parent_pruning_rules_redefined\":false",
        "\"solver_tolerances_used_as_proof\":false",
    )
        _require(occursin(fragment, status_text), "financial resource status is missing: $fragment")
    end
    for (path, digest) in parent_hashes
        _require(
            occursin("\"$path\":\"$digest\"", status_text),
            "financial resource status has a stale parent hash: $path",
        )
    end
    for path in String.(collect(values(config["outputs"])))
        path == status_path && continue
        full_path = _repo_path(path)
        _require(isfile(full_path), "financial resource output is absent: $path")
        expected = ResourceOptimization._status_expected_hash(status_text, path)
        actual = _sha256_file(full_path)
        actual == expected || error("financial resource output hash drifted: $path")
    end
    println(
        "financial resource output certificates current; design=$design_hash; " *
        "parent_artifacts=$(length(parent_hashes))",
    )
    return true
end

main(args = ARGS) = begin
    length(args) <= 1 || error("usage: verify_financial_resource_optimization_outputs.jl [config]")
    verify_outputs(isempty(args) ? DEFAULT_CONFIG : only(args))
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    VerifyFinancialResourceOptimizationOutputs.main()
end
