module LockFinancialStrategyLibraryPanelV3ProposalExecution

using SHA: sha256
using TOML

include(joinpath(@__DIR__, "stage_financial_strategy_library_panel_v3_proposal_returns.jl"))
const ProposalStage = StageFinancialStrategyLibraryPanelV3ProposalReturns

export lock_proposal_execution, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PROPOSAL_EXECUTION_LOCK.toml")
const PREDECISION_RESULT_SEAL_PATH =
    joinpath(EXPERIMENT_ROOT, "PREDECISION_COMPUTATION_RESULT_SEAL.toml")
const EXPECTED_PREDECISION_RESULT_SEAL_SHA256 =
    "6d879cbf17c17337d0efb502605f71f75f5f174f29d1e0a5ef9945d9ff11902d"
const PREDECISION_COMPUTATION_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PREDECISION_COMPUTATION_LOCK_002.toml")
const PREDECISION_RESULT_MANIFEST_PATH = joinpath(
    EXPERIMENT_ROOT,
    "predecision_computation",
    "PREDECISION_COMPUTATION_MANIFEST.toml",
)
const ACCESS_AMENDMENT_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PREDECISION_ACCESS_AMENDMENT_002_LOCK.toml")
const EXPECTED_ACCESS_AMENDMENT_LOCK_SHA256 =
    "560aa75d86e016a838d5b6da3544326fdd606ade33b1934190d9ed7d6d9d6e49"
const EXTRACTOR_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PREDECISION_EXTRACTOR_LOCK_003.toml")
const EXPECTED_EXTRACTOR_LOCK_SHA256 =
    "599eeb90d707a8255e641c9990406962dd4c93cb08b8abcca87b39e94d42fdc9"
const MASTER_MANIFEST_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v2",
    "local_data",
    "master_market_panel",
    "MASTER_MANIFEST.toml",
)
const SELECTION_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "universe_census",
    "UNIVERSE_SELECTIONS.toml",
)
const LOCAL_OUTPUT_PATHS = [
    joinpath(EXPERIMENT_ROOT, "local_data", "proposal"),
    joinpath(EXPERIMENT_ROOT, "proposal_stage"),
    joinpath(EXPERIMENT_ROOT, "local_data", "proposal_computation"),
    joinpath(EXPERIMENT_ROOT, "proposal_computation"),
]
const SEALED_PATHS = [
    "experiments/financial_strategy_library_panel_v3/PROPOSAL_EXECUTION_SPEC.md",
    "experiments/financial_strategy_library_panel_v3/registry/ORIGIN_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v3/registry/POLICY_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v3/registry/SEED_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v3/registry/TRIAL_LEDGER_SCHEMA.csv",
    "julia/Project.toml",
    "julia/Manifest.toml",
    "julia/src/FinancialStrategyLibraryPanelV3Proposal.jl",
    "julia/scripts/stage_financial_strategy_library_panel_v3_predecision_returns.jl",
    "julia/scripts/stage_financial_strategy_library_panel_v3_proposal_returns.jl",
    "julia/scripts/run_financial_strategy_library_panel_v3_proposal.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_proposal_execution.jl",
    "julia/test/test_financial_strategy_library_panel_v3_proposal.jl",
    "julia/test/run_financial_strategy_library_panel_v3_proposal_tests.jl",
    "julia/test/test_financial_strategy_library_panel_v3_proposal_staging.jl",
    "julia/test/run_financial_strategy_library_panel_v3_proposal_staging_tests.jl",
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

function _validate_predecision_seal()
    _sha256_file(PREDECISION_RESULT_SEAL_PATH) ==
        EXPECTED_PREDECISION_RESULT_SEAL_SHA256 ||
        error("predecision computation result seal changed")
    seal = TOML.parsefile(PREDECISION_RESULT_SEAL_PATH)
    seal["status"] == "SEALED_PREDECISION_COMPUTATION_RESULT" ||
        error("predecision computation result is not sealed")
    seal["full_deterministic_scientific_replay_passed"] === true ||
        error("predecision computation did not pass full replay")
    seal["local_artifact_count"] == 228 || error("predecision result artifact count changed")
    seal["proposal_return_values_accessed_before_result_seal"] === false ||
        error("predecision result seal records proposal access")
    seal["evaluation_return_values_accessed_before_result_seal"] === false ||
        error("predecision result seal records evaluation access")
    return seal
end

function _validate_master()
    isfile(MASTER_MANIFEST_PATH) || error("licensed master manifest is absent")
    master = TOML.parsefile(MASTER_MANIFEST_PATH)
    chunks = collect(master["chunks"])
    master["retained_master_rows"] == sum(Int(chunk["row_count"]) for chunk in chunks) ||
        error("licensed master manifest row count does not reconcile")
    return master, chunks
end

function _payload()
    VERSION == v"1.12.6" || error("proposal execution lock requires Julia 1.12.6")
    _sha256_file(ACCESS_AMENDMENT_LOCK_PATH) == EXPECTED_ACCESS_AMENDMENT_LOCK_SHA256 ||
        error("predecision access amendment 002 changed")
    _sha256_file(EXTRACTOR_LOCK_PATH) == EXPECTED_EXTRACTOR_LOCK_SHA256 ||
        error("predecision extractor lock 003 changed")
    access = TOML.parsefile(ACCESS_AMENDMENT_LOCK_PATH)
    access["status"] == "LOCKED_PREDECISION_ACCESS_AMENDMENT_002" ||
        error("masked-column access amendment is not locked")
    _validate_predecision_seal()
    master, chunks = _validate_master()
    selections = TOML.parsefile(SELECTION_PATH)
    selections["outcome_values_accessed"] === false ||
        error("universe selections claim outcome access")
    count(cell -> String(cell["status"]) != "PASSED", selections["cells"]) == 1 ||
        error("proposal failed-cell count changed")
    hashes = Dict{String,String}()
    for relative in SEALED_PATHS
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("proposal execution input is absent: $relative")
        hashes[relative] = _sha256_file(path)
    end
    sentinel = ProposalStage.proposal_leakage_sentinel()
    sentinel["failed_cell_rows_materialized"] == 0 ||
        error("proposal sentinel accessed a failed cell")
    sentinel["evaluation_rows_inspected_materialized_or_used"] == 0 ||
        error("proposal sentinel crossed the evaluation boundary")
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-proposal-execution-lock-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PROPOSAL_EXECUTION",
        "language" => "Julia",
        "julia_version" => string(VERSION),
        "predecision_computation_result_seal_sha256" =>
            _sha256_file(PREDECISION_RESULT_SEAL_PATH),
        "predecision_computation_lock_sha256" =>
            _sha256_file(PREDECISION_COMPUTATION_LOCK_PATH),
        "predecision_result_manifest_sha256" =>
            _sha256_file(PREDECISION_RESULT_MANIFEST_PATH),
        "predecision_access_amendment_002_lock_sha256" =>
            _sha256_file(ACCESS_AMENDMENT_LOCK_PATH),
        "predecision_extractor_lock_003_sha256" => _sha256_file(EXTRACTOR_LOCK_PATH),
        "licensed_master_manifest_sha256" => _sha256_file(MASTER_MANIFEST_PATH),
        "licensed_master_chunk_count" => length(chunks),
        "licensed_master_row_count" => master["retained_master_rows"],
        "universe_selection_sha256" => _sha256_file(SELECTION_PATH),
        "sealed_file_count" => length(hashes),
        "sealed_file_sha256" => hashes,
        "sealed_file_aggregate_sha256" => _aggregate(hashes),
        "proposal_masked_access_sentinel" => sentinel,
        "proposal_accessed_cell_count" => 37,
        "failed_universe_cell_count_retained_without_access" => 1,
        "bootstrap_repetitions" => 5_000,
        "moving_block_sessions" => 20,
        "familywise_alpha" => 0.10,
        "adoption_hurdle" => 0.0025,
        "stable_seed_base" => 310002,
        "historical_proposal_return_access_permitted" => true,
        "historical_evaluation_return_access_permitted" => false,
        "failed_universe_cell_proposal_access_permitted" => false,
        "proposal_return_values_accessed_before_lock" => false,
        "evaluation_return_values_accessed_before_lock" => false,
        "next_required_seal" => "frozen proposal choices and complete proposal trial ledger",
    )
end

function lock_proposal_execution(; check = false)
    if !check
        for path in LOCAL_OUTPUT_PATHS
            ispath(path) && error("proposal artifact exists before execution lock: $(relpath(path, REPOSITORY_ROOT))")
        end
    end
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("proposal execution lock is absent")
        read(LOCK_PATH, String) == text || error("proposal execution lock changed")
    elseif isfile(LOCK_PATH)
        read(LOCK_PATH, String) == text || error("refusing to replace a nonidentical proposal lock")
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PROPOSAL_EXECUTION_LOCK_PASSED")
    println("proposal cells authorized: 37/38")
    println("failed-cell proposal access authorized: false")
    println("evaluation access authorized: false")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_proposal_execution(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3ProposalExecution.main()
end
