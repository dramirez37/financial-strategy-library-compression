module LockFinancialStrategyLibraryPanelV3PredecisionExtractor003

using SHA: sha256
using TOML

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const DESIGN_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK.toml")
const IMPLEMENTATION_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_AMENDMENT_001_LOCK.toml")
const EXTRACTOR_LOCK_001_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_EXTRACTOR_LOCK.toml")
const EXTRACTOR_LOCK_002_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_EXTRACTOR_LOCK_002.toml")
const ACCESS_AMENDMENT_LOCK_PATH =
    joinpath(EXPERIMENT_ROOT, "PREDECISION_ACCESS_AMENDMENT_002_LOCK.toml")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_EXTRACTOR_LOCK_003.toml")
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
const EXPECTED_IMPLEMENTATION_LOCK_SHA256 =
    "6aaa1cce4c01066ab66c5f371993e326a0e9ec0a469d636731eb506c6e3e5c77"
const EXPECTED_EXTRACTOR_LOCK_001_SHA256 =
    "9bb2050c6f88ba63d1c57882bd5a827ae4c8a94a69d030f5f8edd41adc277953"
const EXPECTED_EXTRACTOR_LOCK_002_SHA256 =
    "fce4f369e5c7ab7069090ea63aaa52ae0e54e5ead9ee625f5e7771acf7ccb427"
const EXPECTED_ACCESS_AMENDMENT_LOCK_SHA256 =
    "560aa75d86e016a838d5b6da3544326fdd606ade33b1934190d9ed7d6d9d6e49"
const SEALED_PATHS = [
    "julia/scripts/stage_financial_strategy_library_panel_v3_predecision_returns.jl",
    "julia/test/test_financial_strategy_library_panel_v3_predecision_staging.jl",
    "julia/test/run_financial_strategy_library_panel_v3_predecision_staging_tests.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_predecision_extractor_003.jl",
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
    _sha256_file(IMPLEMENTATION_LOCK_PATH) == EXPECTED_IMPLEMENTATION_LOCK_SHA256 ||
        error("implementation amendment lock changed")
    _sha256_file(EXTRACTOR_LOCK_001_PATH) == EXPECTED_EXTRACTOR_LOCK_001_SHA256 ||
        error("extractor lock 001 changed")
    _sha256_file(EXTRACTOR_LOCK_002_PATH) == EXPECTED_EXTRACTOR_LOCK_002_SHA256 ||
        error("extractor lock 002 changed")
    _sha256_file(ACCESS_AMENDMENT_LOCK_PATH) == EXPECTED_ACCESS_AMENDMENT_LOCK_SHA256 ||
        error("predecision access-amendment lock changed")
    access_amendment = _verify_sealed_files(TOML.parsefile(ACCESS_AMENDMENT_LOCK_PATH))
    access_amendment["status"] == "LOCKED_PREDECISION_ACCESS_AMENDMENT_002" ||
        error("unexpected access-amendment lock status")
    access_amendment["scientific_design_changed"] === false ||
        error("access amendment changes the scientific design")
    access_amendment["effective_historical_predecision_return_access_permitted"] === false ||
        error("access amendment itself grants effective return access")
    access_amendment["date_aware_extractor_lock_003_required_for_return_access"] === true ||
        error("access amendment does not require extractor lock 003")
    lock_001 = TOML.parsefile(EXTRACTOR_LOCK_001_PATH)
    lock_002 = TOML.parsefile(EXTRACTOR_LOCK_002_PATH)
    all(lock -> lock["effective_historical_predecision_return_access_permitted"] === true,
        (lock_001, lock_002)) || error("prior access was not authorized")
    all(lock -> lock["historical_proposal_or_evaluation_return_access_permitted"] === false,
        (lock_001, lock_002)) || error("a prior lock permitted postdecision access")

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
        error("extractor 003 leakage sentinel did not pass")
    sentinel["postdecision_rows_inspected"] == 0 ||
        error("extractor 003 sentinel inspected a postdecision value")
    sentinel["postdecision_rows_materialized"] == 0 ||
        error("extractor 003 sentinel materialized a postdecision value")
    sentinel["postdecision_rows_used"] == 0 ||
        error("extractor 003 sentinel used a postdecision value")
    sentinel["masked_outputs_identical_across_unmasked_variants"] === true ||
        error("unmasked adversarial values changed extractor output")

    hashes = Dict{String,String}()
    for relative in SEALED_PATHS
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("extractor 003 input is absent: $relative")
        hashes[relative] = _sha256_file(path)
    end
    canonical = join(
        ("$relative\0$(hashes[relative])\n" for relative in sort!(collect(keys(hashes)))),
    )
    return Dict{String,Any}(
        "schema_version" =>
            "financial-strategy-library-panel-v3-predecision-extractor-lock-v3",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PREDECISION_EXTRACTOR_003",
        "language" => "Julia",
        "design_lock_sha256" => _sha256_file(DESIGN_LOCK_PATH),
        "implementation_amendment_lock_sha256" => _sha256_file(IMPLEMENTATION_LOCK_PATH),
        "extractor_lock_001_sha256" => _sha256_file(EXTRACTOR_LOCK_001_PATH),
        "previous_extractor_lock_sha256" => _sha256_file(EXTRACTOR_LOCK_002_PATH),
        "access_amendment_002_lock_sha256" => _sha256_file(ACCESS_AMENDMENT_LOCK_PATH),
        "local_universe_selection_sha256" => _sha256_file(SELECTION_PATH),
        "source_master_manifest_sha256" => _sha256_file(MASTER_MANIFEST_PATH),
        "extractor_aggregate_sha256" => _sha256_text(canonical),
        "sealed_file_count" => length(hashes),
        "sealed_file_sha256" => hashes,
        "synthetic_sentinel" => sentinel,
        "predecision_values_accessed_before_003" => true,
        "prior_access_was_authorized" => true,
        "proposal_values_inspected_materialized_or_used_before_003" => false,
        "evaluation_values_inspected_materialized_or_used_before_003" => false,
        "prior_interrupted_attempt_count" => 2,
        "prior_local_stage_artifacts_written" => false,
        "change_scope" =>
            "performance_only_access_mechanics_no_scientific_design_change",
        "identifier_date_selection_frozen_before_return_cursor" => true,
        "return_reader" =>
            "one projected forward Parquet.ColCursor pass per field with a frozen selected-row mask",
        "unmasked_application_action" => "advance opaque iterator state only",
        "unmasked_value_inspection_materialization_or_use_permitted" => false,
        "parquet_page_decompression_disclosed" => true,
        "physical_page_decode_claimed_zero" => false,
        "historical_predecision_return_access_permitted" => true,
        "effective_historical_predecision_return_access_permitted" => true,
        "historical_proposal_or_evaluation_return_access_permitted" => false,
        "next_required_seal" =>
            "frozen predecision libraries exact arms action sets and trial ledger",
    )
end

function lock_extractor_003(; check = false)
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("v3 predecision extractor lock 003 is absent")
        read(LOCK_PATH, String) == text || error("v3 predecision extractor lock 003 changed")
    elseif isfile(LOCK_PATH)
        read(LOCK_PATH, String) == text ||
            error("refusing to replace a nonidentical extractor lock 003")
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PREDECISION_EXTRACTOR_LOCK_003_PASSED")
    println("prior authorized predecision access disclosed: true")
    println("adversarial unmasked-value sentinel: passed")
    println("proposal/evaluation values inspected/materialized/used: 0")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_extractor_003(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3PredecisionExtractor003.main()
end
