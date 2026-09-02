module LockFinancialStrategyLibraryPanelV3ProposalComputationAmendment001

using SHA: sha256
using TOML

export lock_proposal_computation_amendment_001, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const PREVIOUS_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PROPOSAL_EXECUTION_LOCK.toml")
const EXPECTED_PREVIOUS_LOCK_SHA256 =
    "86092535a1f8084ecea0b82b8fc41e59ff703536f7ba29fb649c67ac25683fd3"
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PROPOSAL_COMPUTATION_AMENDMENT_001_LOCK.toml")
const PARTIAL_ROOT = joinpath(EXPERIMENT_ROOT, "local_data", "proposal_computation")
const SEALED_PATHS = [
    "experiments/financial_strategy_library_panel_v3/amendments/PROPOSAL_COMPUTATION_AMENDMENT_001.md",
    "experiments/financial_strategy_library_panel_v3/amendments/PROPOSAL_COMPUTATION_AMENDMENT_001.toml",
    "julia/scripts/run_financial_strategy_library_panel_v3_proposal.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_proposal_computation_amendment_001.jl",
    "julia/test/test_financial_strategy_library_panel_v3_proposal.jl",
    "julia/test/run_financial_strategy_library_panel_v3_proposal_tests.jl",
]

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

_sha256_text(value) = bytes2hex(sha256(codeunits(String(value))))

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _aggregate(hashes)
    canonical = join(
        ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
    )
    return _sha256_text(canonical)
end

function _partial_hashes()
    isdir(PARTIAL_ROOT) || error("recorded partial proposal output directory is absent")
    paths = sort!(filter(
        path -> endswith(path, "-paths.parquet"),
        readdir(PARTIAL_ROOT; join = true),
    ))
    length(paths) == 7 || error("partial proposal artifact count changed")
    all(path -> occursin(r"cell-(006|011|016|021|026|031|035)-paths\.parquet$", path), paths) ||
        error("unexpected partial proposal artifact identity")
    return Dict(
        relpath(path, EXPERIMENT_ROOT) => _sha256_file(path) for path in paths
    )
end

function _payload()
    _sha256_file(PREVIOUS_LOCK_PATH) == EXPECTED_PREVIOUS_LOCK_SHA256 ||
        error("proposal execution lock changed")
    previous = TOML.parsefile(PREVIOUS_LOCK_PATH)
    previous["status"] == "LOCKED_PROPOSAL_EXECUTION" ||
        error("unexpected proposal execution-lock status")
    previous["historical_evaluation_return_access_permitted"] === false ||
        error("proposal execution lock permits evaluation access")
    partial = _partial_hashes()
    hashes = Dict{String,String}()
    for relative in SEALED_PATHS
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("proposal computation amendment input is absent: $relative")
        hashes[relative] = _sha256_file(path)
    end
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-computation-amendment-lock-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PROPOSAL_COMPUTATION_AMENDMENT_001",
        "language" => "Julia",
        "previous_proposal_execution_lock_sha256" => _sha256_file(PREVIOUS_LOCK_PATH),
        "change_scope" => "terminal validation correction only",
        "scientific_design_changed" => false,
        "policy_rules_changed" => false,
        "proposal_values_accessed_before_amendment" => true,
        "proposal_path_availability_known_before_amendment" => true,
        "evaluation_values_accessed_before_amendment" => false,
        "partial_path_artifact_count" => length(partial),
        "partial_path_artifact_sha256" => partial,
        "partial_path_artifact_aggregate_sha256" => _aggregate(partial),
        "completed_choice_artifacts_before_amendment" => 0,
        "completed_ledger_artifacts_before_amendment" => 0,
        "result_manifests_before_amendment" => 0,
        "sealed_file_count" => length(hashes),
        "sealed_file_sha256" => hashes,
        "sealed_file_aggregate_sha256" => _aggregate(hashes),
        "historical_proposal_return_computation_permitted" => true,
        "historical_evaluation_return_access_permitted" => false,
        "next_required_seal" => "frozen proposal choices and complete proposal trial ledger",
    )
end

function lock_proposal_computation_amendment_001(; check = false)
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("proposal computation amendment lock is absent")
        read(LOCK_PATH, String) == text || error("proposal computation amendment lock changed")
    elseif isfile(LOCK_PATH)
        read(LOCK_PATH, String) == text ||
            error("refusing to replace a nonidentical proposal computation amendment lock")
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PROPOSAL_COMPUTATION_AMENDMENT_001_PASSED")
    println("partial path artifacts bound: 7")
    println("scientific design/policy rules changed: false")
    println("evaluation values accessed: false")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_proposal_computation_amendment_001(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3ProposalComputationAmendment001.main()
end
