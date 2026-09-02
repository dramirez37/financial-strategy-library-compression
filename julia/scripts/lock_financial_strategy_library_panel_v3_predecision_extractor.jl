module LockFinancialStrategyLibraryPanelV3PredecisionExtractor

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
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_EXTRACTOR_LOCK.toml")
const EXPECTED_AMENDMENT_LOCK_SHA256 =
    "6aaa1cce4c01066ab66c5f371993e326a0e9ec0a469d636731eb506c6e3e5c77"
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
const SEALED_PATHS = [
    "julia/scripts/stage_financial_strategy_library_panel_v3_predecision_returns.jl",
    "julia/test/test_financial_strategy_library_panel_v3_predecision_staging.jl",
    "julia/test/run_financial_strategy_library_panel_v3_predecision_staging_tests.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_predecision_extractor.jl",
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

function _verify_seal(path)
    lock = TOML.parsefile(path)
    hashes = Dict{String,String}(lock["sealed_file_sha256"])
    for relative in sort!(collect(keys(hashes)))
        source = joinpath(REPOSITORY_ROOT, relative)
        isfile(source) || error("sealed prerequisite is absent: $relative")
        _sha256_file(source) == hashes[relative] || error("sealed prerequisite changed: $relative")
    end
    return lock
end

function _payload()
    design = _verify_seal(DESIGN_LOCK_PATH)
    amendment = _verify_seal(AMENDMENT_LOCK_PATH)
    design["status"] == "LOCKED_PREDECISION" || error("unexpected v3 design-lock status")
    amendment["status"] == "LOCKED_PREDECISION_IMPLEMENTATION" ||
        error("unexpected v3 implementation-amendment status")
    _sha256_file(AMENDMENT_LOCK_PATH) == EXPECTED_AMENDMENT_LOCK_SHA256 ||
        error("current implementation-amendment lock hash changed")
    amendment["predecision_access_authority_model"] ==
        "base_eligibility_plus_current_amendment_plus_extractor_lock" ||
        error("predecision access authority model changed")
    amendment["base_design_lock_alone_authorizes_return_access"] === false ||
        error("base design lock alone was allowed to authorize return access")
    amendment["current_amendment_lock_required_for_return_access"] === true ||
        error("current implementation amendment is not required for return access")
    amendment["date_aware_extractor_lock_required_for_return_access"] === true ||
        error("date-aware extractor lock is not required for return access")
    amendment["effective_historical_predecision_return_access_permitted"] === false ||
        error("implementation amendment claims effective access before extractor seal")
    amendment["historical_predecision_return_access_permitted"] === false ||
        error("implementation amendment itself granted return access")
    amendment["historical_proposal_or_evaluation_return_access_permitted"] === false ||
        error("implementation amendment permits postdecision return access")
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
        error("synthetic proposal/evaluation leakage sentinel did not pass")

    hashes = Dict{String,String}()
    for relative in SEALED_PATHS
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("extractor input is absent: $relative")
        hashes[relative] = _sha256_file(path)
    end
    canonical = join(
        ("$relative\0$(hashes[relative])\n" for relative in sort!(collect(keys(hashes)))),
    )
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-predecision-extractor-lock-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PREDECISION_EXTRACTOR",
        "language" => "Julia",
        "predecision_amendment_lock_sha256" => _sha256_file(AMENDMENT_LOCK_PATH),
        "design_lock_sha256" => _sha256_file(DESIGN_LOCK_PATH),
        "local_universe_selection_sha256" => _sha256_file(SELECTION_PATH),
        "source_master_manifest_sha256" => _sha256_file(MASTER_MANIFEST_PATH),
        "extractor_aggregate_sha256" => _sha256_text(canonical),
        "sealed_file_count" => length(hashes),
        "sealed_file_sha256" => hashes,
        "synthetic_sentinel" => sentinel,
        "v3_predecision_return_values_accessed_before_lock" => false,
        "v3_proposal_return_values_accessed_before_lock" => false,
        "v3_evaluation_return_values_accessed_before_lock" => false,
        "historical_predecision_return_access_permitted" => true,
        "effective_historical_predecision_return_access_permitted" => true,
        "historical_proposal_or_evaluation_return_access_permitted" => false,
        "predecision_access_authority_model" =>
            "base_eligibility_plus_current_amendment_plus_extractor_lock",
        "base_design_lock_alone_authorizes_return_access" => false,
        "current_amendment_lock_required_for_return_access" => true,
        "date_aware_extractor_lock_required_for_return_access" => true,
        "identifier_date_filter_must_precede_return_decode" => true,
        "terminal_delisting_fields_required" => true,
        "next_required_seal" => "frozen predecision libraries exact arms action sets and trial ledger",
    )
end

function lock_extractor(; check = false)
    ispath(joinpath(EXPERIMENT_ROOT, "local_data", "predecision")) && !check &&
        error("predecision return data exist before the extractor lock")
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("v3 predecision extractor lock is absent")
        read(LOCK_PATH, String) == text || error("v3 predecision extractor lock changed")
    elseif isfile(LOCK_PATH)
        if read(LOCK_PATH, String) != text
            temporary = LOCK_PATH * ".tmp.$(getpid())"
            open(temporary, "w") do io
                write(io, text)
            end
            mv(temporary, LOCK_PATH; force = true)
        end
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PREDECISION_EXTRACTOR_LOCK_PASSED")
    println("synthetic proposal/evaluation leakage sentinel: passed")
    println("historical predecision return access permitted: true")
    println("historical proposal/evaluation return access permitted: false")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_extractor(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3PredecisionExtractor.main()
end
