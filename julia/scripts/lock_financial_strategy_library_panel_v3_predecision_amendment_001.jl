module LockFinancialStrategyLibraryPanelV3PredecisionAmendment001

using SHA: sha256
using TOML

export lock_amendment, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const BASE_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK.toml")
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_AMENDMENT_001_LOCK.toml")
const AMENDMENT_PATHS = [
    "experiments/financial_strategy_library_panel_v3/PREDECISION_IMPLEMENTATION_SPEC.md",
    "experiments/financial_strategy_library_panel_v3/registry/BURDEN_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v3/amendments/DESIGN_AMENDMENT_001.md",
    "experiments/financial_strategy_library_panel_v3/amendments/DESIGN_AMENDMENT_001.toml",
    "julia/src/FinancialStrategyLibraryPanelV3Predecision.jl",
    "julia/test/test_financial_strategy_library_panel_v3_predecision.jl",
    "julia/test/run_financial_strategy_library_panel_v3_predecision_tests.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_predecision_amendment_001.jl",
]

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

_sha256_text(text) = bytes2hex(sha256(codeunits(String(text))))


function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end


function _atomic_write(path, content)
    temporary = path * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, content)
    end
    mv(temporary, path; force = true)
    return path
end


function _payload(; check = false)
    base = TOML.parsefile(BASE_LOCK_PATH)
    base["status"] == "LOCKED_PREDECISION" || error("unexpected base v3 design-lock status")
    base["v3_outcomes_opened"] === false || error("base v3 design lock opened outcomes")
    base_hashes = Dict{String,String}(base["sealed_file_sha256"])
    for relative in sort!(collect(keys(base_hashes)))
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("base-sealed input is absent: $relative")
        _sha256_file(path) == base_hashes[relative] ||
            error("base-sealed input changed: $relative")
    end
    base_canonical = join(
        ("$relative\0$(base_hashes[relative])\n" for relative in sort!(collect(keys(base_hashes)))),
    )
    _sha256_text(base_canonical) == base["design_aggregate_sha256"] ||
        error("base design aggregate does not verify")
    amendment = TOML.parsefile(joinpath(
        EXPERIMENT_ROOT,
        "amendments",
        "DESIGN_AMENDMENT_001.toml",
    ))
    amendment["status"] == "outcome_blind_predecision_clarification" ||
        error("unexpected v3 predecision-amendment status")
    all(key -> amendment[key] === false, (
        "v3_predecision_return_values_accessed_before_amendment",
        "v3_proposal_return_values_accessed_before_amendment",
        "v3_evaluation_return_values_accessed_before_amendment",
        "candidate_grammar_changed",
        "universe_changed",
        "primary_arms_changed",
        "primary_estimand_changed",
        "claim_boundary_changed",
    )) || error("v3 amendment changes a prohibited field or follows outcome access")
    ispath(joinpath(EXPERIMENT_ROOT, "local_data", "predecision")) && !check &&
        error("predecision data exist before the amendment lock")
    hashes = Dict{String,String}()
    for relative in AMENDMENT_PATHS
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("amendment input is absent: $relative")
        hashes[relative] = _sha256_file(path)
    end
    canonical = join(
        ("$relative\0$(hashes[relative])\n" for relative in sort!(collect(keys(hashes)))),
    )
    aggregate = bytes2hex(sha256(codeunits(canonical)))
    return Dict{String,Any}(
        "schema_version" =>
            "financial-strategy-library-panel-v3-predecision-amendment-lock-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "amendment_id" => "FSLP3-DESIGN-AMENDMENT-001",
        "status" => "LOCKED_PREDECISION_IMPLEMENTATION",
        "language" => "Julia",
        "base_design_lock_sha256" => _sha256_file(BASE_LOCK_PATH),
        "amendment_aggregate_sha256" => aggregate,
        "sealed_file_count" => length(hashes),
        "sealed_file_sha256" => hashes,
        "predecision_access_authority_model" =>
            "base_eligibility_plus_current_amendment_plus_extractor_lock",
        "base_design_lock_alone_authorizes_return_access" => false,
        "current_amendment_lock_required_for_return_access" => true,
        "date_aware_extractor_lock_required_for_return_access" => true,
        "effective_historical_predecision_return_access_permitted" => false,
        "historical_predecision_return_access_permitted" => false,
        "historical_proposal_or_evaluation_return_access_permitted" => false,
        "v3_outcomes_opened" => false,
        "next_required_seal" =>
            "sealed date-aware extractor access manifest and sentinel leakage tests",
    )
end


function lock_amendment(; check = false)
    payload = _payload(; check)
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("v3 predecision amendment lock is absent")
        read(LOCK_PATH, String) == text || error("v3 predecision amendment lock changed")
    else
        _atomic_write(LOCK_PATH, text)
    end
    println("V3_PREDECISION_AMENDMENT_LOCK_PASSED")
    println("historical predecision return access permitted: false")
    println("historical proposal/evaluation return access permitted: false")
    return payload
end


function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_amendment(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3PredecisionAmendment001.main()
end
