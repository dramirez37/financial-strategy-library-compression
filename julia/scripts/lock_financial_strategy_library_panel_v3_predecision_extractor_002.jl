module LockFinancialStrategyLibraryPanelV3PredecisionExtractor002

using SHA: sha256
using TOML

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const DESIGN_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK.toml")
const AMENDMENT_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_AMENDMENT_001_LOCK.toml")
const PREVIOUS_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_EXTRACTOR_LOCK.toml")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_EXTRACTOR_LOCK_002.toml")
const SELECTION_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "universe_census",
    "UNIVERSE_SELECTIONS.toml",
)
const MASTER_MANIFEST_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v2",
    "local_data",
    "master_market_panel",
    "MASTER_MANIFEST.toml",
)
const EXPECTED_AMENDMENT_LOCK_SHA256 =
    "6aaa1cce4c01066ab66c5f371993e326a0e9ec0a469d636731eb506c6e3e5c77"
const EXPECTED_PREVIOUS_LOCK_SHA256 =
    "9bb2050c6f88ba63d1c57882bd5a827ae4c8a94a69d030f5f8edd41adc277953"
const SEALED_PATHS = [
    "julia/scripts/stage_financial_strategy_library_panel_v3_predecision_returns.jl",
    "julia/test/test_financial_strategy_library_panel_v3_predecision_staging.jl",
    "julia/test/run_financial_strategy_library_panel_v3_predecision_staging_tests.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_predecision_extractor_002.jl",
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

function _verify_sealed_files(lock)
    hashes = Dict{String,String}(lock["sealed_file_sha256"])
    for relative in sort!(collect(keys(hashes)))
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("sealed prerequisite is absent: $relative")
        _sha256_file(path) == hashes[relative] || error("sealed prerequisite changed: $relative")
    end
    return lock
end

function _payload()
    design = _verify_sealed_files(TOML.parsefile(DESIGN_LOCK_PATH))
    amendment = _verify_sealed_files(TOML.parsefile(AMENDMENT_LOCK_PATH))
    design["status"] == "LOCKED_PREDECISION" || error("unexpected v3 design-lock status")
    amendment["status"] == "LOCKED_PREDECISION_IMPLEMENTATION" ||
        error("unexpected v3 implementation-amendment status")
    _sha256_file(AMENDMENT_LOCK_PATH) == EXPECTED_AMENDMENT_LOCK_SHA256 ||
        error("current implementation-amendment lock hash changed")
    _sha256_file(PREVIOUS_LOCK_PATH) == EXPECTED_PREVIOUS_LOCK_SHA256 ||
        error("extractor lock 001 changed")
    previous = TOML.parsefile(PREVIOUS_LOCK_PATH)
    previous["status"] == "LOCKED_PREDECISION_EXTRACTOR" ||
        error("unexpected extractor lock 001 status")
    previous["effective_historical_predecision_return_access_permitted"] === true ||
        error("extractor lock 001 did not authorize the interrupted access")
    previous["historical_proposal_or_evaluation_return_access_permitted"] === false ||
        error("extractor lock 001 permitted postdecision access")
    previous["predecision_amendment_lock_sha256"] == EXPECTED_AMENDMENT_LOCK_SHA256 ||
        error("extractor lock 001 was not bound to the current amendment")
    design["local_universe_selection_sha256"] == _sha256_file(SELECTION_PATH) ||
        error("locked local universe selection changed")

    include(joinpath(
        REPOSITORY_ROOT,
        "julia",
        "scripts",
        "stage_financial_strategy_library_panel_v3_predecision_returns.jl",
    ))
    sentinel = Base.invokelatest(
        StageFinancialStrategyLibraryPanelV3PredecisionReturns.sentinel_leakage_test,
    )
    sentinel["status"] == "SYNTHETIC_SENTINEL_PASSED" ||
        error("optimized extractor leakage sentinel did not pass")

    hashes = Dict{String,String}()
    for relative in SEALED_PATHS
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("extractor 002 input is absent: $relative")
        hashes[relative] = _sha256_file(path)
    end
    canonical = join(
        ("$relative\0$(hashes[relative])\n" for relative in sort!(collect(keys(hashes)))),
    )
    return Dict{String,Any}(
        "schema_version" =>
            "financial-strategy-library-panel-v3-predecision-extractor-lock-v2",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PREDECISION_EXTRACTOR_002",
        "language" => "Julia",
        "previous_extractor_lock_sha256" => _sha256_file(PREVIOUS_LOCK_PATH),
        "predecision_amendment_lock_sha256" => _sha256_file(AMENDMENT_LOCK_PATH),
        "design_lock_sha256" => _sha256_file(DESIGN_LOCK_PATH),
        "local_universe_selection_sha256" => _sha256_file(SELECTION_PATH),
        "source_master_manifest_sha256" => _sha256_file(MASTER_MANIFEST_PATH),
        "extractor_aggregate_sha256" => _sha256_text(canonical),
        "sealed_file_count" => length(hashes),
        "sealed_file_sha256" => hashes,
        "synthetic_sentinel" => sentinel,
        "predecision_values_accessed_before_002" => true,
        "access_was_authorized_by_001" => true,
        "proposal_values_accessed_before_002" => false,
        "evaluation_values_accessed_before_002" => false,
        "interrupted_run_completed_chunk_count" => 8,
        "interrupted_run_local_artifacts_written" => false,
        "change_scope" => "performance_only_no_selection_or_semantic_change",
        "performance_change" =>
            "replace allocating row dictionaries with aligned projected column cursors",
        "identifier_date_reader" => "aligned Parquet.ColCursor streams",
        "return_reader" => "aligned exact-source-range Parquet.ColCursor streams",
        "historical_predecision_return_access_permitted" => true,
        "effective_historical_predecision_return_access_permitted" => true,
        "historical_proposal_or_evaluation_return_access_permitted" => false,
        "identifier_date_filter_must_precede_return_decode" => true,
        "terminal_delisting_fields_required" => true,
        "next_required_seal" =>
            "frozen predecision libraries exact arms action sets and trial ledger",
    )
end

function lock_extractor_002(; check = false)
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("v3 predecision extractor lock 002 is absent")
        read(LOCK_PATH, String) == text || error("v3 predecision extractor lock 002 changed")
    elseif isfile(LOCK_PATH)
        read(LOCK_PATH, String) == text ||
            error("refusing to replace a nonidentical extractor lock 002")
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PREDECISION_EXTRACTOR_LOCK_002_PASSED")
    println("prior authorized predecision access disclosed: true")
    println("performance-only change: aligned projected column cursors")
    println("historical proposal/evaluation return access permitted: false")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_extractor_002(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3PredecisionExtractor002.main()
end
