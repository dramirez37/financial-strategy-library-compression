module LockFinancialStrategyLibraryPanelV3PredecisionAccessAmendment002

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
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_ACCESS_AMENDMENT_002_LOCK.toml")
const EXPECTED_IMPLEMENTATION_LOCK_SHA256 =
    "6aaa1cce4c01066ab66c5f371993e326a0e9ec0a469d636731eb506c6e3e5c77"
const EXPECTED_EXTRACTOR_LOCK_001_SHA256 =
    "9bb2050c6f88ba63d1c57882bd5a827ae4c8a94a69d030f5f8edd41adc277953"
const EXPECTED_EXTRACTOR_LOCK_002_SHA256 =
    "fce4f369e5c7ab7069090ea63aaa52ae0e54e5ead9ee625f5e7771acf7ccb427"
const SEALED_PATHS = [
    "experiments/financial_strategy_library_panel_v3/amendments/PREDECISION_ACCESS_AMENDMENT_002.md",
    "experiments/financial_strategy_library_panel_v3/amendments/PREDECISION_ACCESS_AMENDMENT_002.toml",
    "julia/scripts/lock_financial_strategy_library_panel_v3_predecision_access_amendment_002.jl",
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

function _payload()
    _sha256_file(IMPLEMENTATION_LOCK_PATH) == EXPECTED_IMPLEMENTATION_LOCK_SHA256 ||
        error("implementation amendment lock changed")
    _sha256_file(EXTRACTOR_LOCK_001_PATH) == EXPECTED_EXTRACTOR_LOCK_001_SHA256 ||
        error("extractor lock 001 changed")
    _sha256_file(EXTRACTOR_LOCK_002_PATH) == EXPECTED_EXTRACTOR_LOCK_002_SHA256 ||
        error("extractor lock 002 changed")
    implementation = TOML.parsefile(IMPLEMENTATION_LOCK_PATH)
    lock_001 = TOML.parsefile(EXTRACTOR_LOCK_001_PATH)
    lock_002 = TOML.parsefile(EXTRACTOR_LOCK_002_PATH)
    implementation["predecision_access_authority_model"] ==
        "base_eligibility_plus_current_amendment_plus_extractor_lock" ||
        error("predecision authority model changed")
    lock_001["effective_historical_predecision_return_access_permitted"] === true ||
        error("extractor lock 001 did not authorize its access")
    lock_002["effective_historical_predecision_return_access_permitted"] === true ||
        error("extractor lock 002 did not authorize its access")
    all(lock -> lock["historical_proposal_or_evaluation_return_access_permitted"] === false,
        (lock_001, lock_002)) || error("a prior extractor lock permitted postdecision access")

    amendment = TOML.parsefile(joinpath(
        EXPERIMENT_ROOT,
        "amendments",
        "PREDECISION_ACCESS_AMENDMENT_002.toml",
    ))
    amendment["status"] == "performance_only_access_mechanics_amendment" ||
        error("unexpected access-amendment status")
    amendment["predecision_values_accessed_before_amendment_002"] === true ||
        error("access amendment conceals prior predecision access")
    amendment["scientific_design_changed"] === false ||
        error("access amendment changes the scientific design")
    all(key -> amendment[key] === false, (
        "proposal_values_inspected_before_amendment_002",
        "proposal_values_materialized_before_amendment_002",
        "proposal_values_used_before_amendment_002",
        "evaluation_values_inspected_before_amendment_002",
        "evaluation_values_materialized_before_amendment_002",
        "evaluation_values_used_before_amendment_002",
    )) || error("access amendment reports forbidden prior postdecision access")

    hashes = Dict{String,String}()
    for relative in SEALED_PATHS
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("access-amendment input is absent: $relative")
        hashes[relative] = _sha256_file(path)
    end
    canonical = join(
        ("$relative\0$(hashes[relative])\n" for relative in sort!(collect(keys(hashes)))),
    )
    return Dict{String,Any}(
        "schema_version" =>
            "financial-strategy-library-panel-v3-predecision-access-amendment-lock-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "amendment_id" => "FSLP3-PREDECISION-ACCESS-AMENDMENT-002",
        "status" => "LOCKED_PREDECISION_ACCESS_AMENDMENT_002",
        "language" => "Julia",
        "design_lock_sha256" => _sha256_file(DESIGN_LOCK_PATH),
        "implementation_amendment_lock_sha256" => _sha256_file(IMPLEMENTATION_LOCK_PATH),
        "extractor_lock_001_sha256" => _sha256_file(EXTRACTOR_LOCK_001_PATH),
        "extractor_lock_002_sha256" => _sha256_file(EXTRACTOR_LOCK_002_PATH),
        "access_amendment_aggregate_sha256" => _sha256_text(canonical),
        "sealed_file_count" => length(hashes),
        "sealed_file_sha256" => hashes,
        "predecision_values_accessed_before_amendment_002" => true,
        "prior_access_was_authorized" => true,
        "proposal_or_evaluation_values_inspected_materialized_or_used" => false,
        "scientific_design_changed" => false,
        "effective_historical_predecision_return_access_permitted" => false,
        "date_aware_extractor_lock_003_required_for_return_access" => true,
        "next_required_seal" => "predecision extractor lock 003",
    )
end

function lock_access_amendment(; check = false)
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("predecision access-amendment lock is absent")
        read(LOCK_PATH, String) == text || error("predecision access-amendment lock changed")
    elseif isfile(LOCK_PATH)
        read(LOCK_PATH, String) == text ||
            error("refusing to replace a nonidentical access-amendment lock")
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PREDECISION_ACCESS_AMENDMENT_002_LOCK_PASSED")
    println("prior authorized predecision access disclosed: true")
    println("scientific design changed: false")
    println("effective historical predecision access permitted: false")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_access_amendment(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3PredecisionAccessAmendment002.main()
end
