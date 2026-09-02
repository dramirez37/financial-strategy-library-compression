module LockFinancialStrategyLibraryPanelV3Design

using SHA: sha256
using TOML

include(joinpath(@__DIR__, "check_financial_strategy_library_panel_v3_design.jl"))
using .CheckFinancialStrategyLibraryPanelV3Design

export lock_design, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK.toml")
const AUDIT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v2_economic_design_audit",
)
const AUDIT_SUMMARY_PATH = joinpath(AUDIT_ROOT, "results", "AUDIT_SUMMARY.toml")
const SOURCE_CENSUS_ROOT = joinpath(EXPERIMENT_ROOT, "source_census")
const LOCAL_SELECTION_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "universe_census",
    "UNIVERSE_SELECTIONS.toml",
)

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

function _sealed_paths(design_check)
    design_paths = String.(collect(keys(design_check["design_file_sha256"])))
    additional = [
        "experiments/financial_strategy_library_panel_v3/DESIGN_CHECK.toml",
        "experiments/financial_strategy_library_panel_v2_economic_design_audit/AUDIT_PLAN.md",
        "experiments/financial_strategy_library_panel_v2_economic_design_audit/results/AUDIT_SUMMARY.toml",
        "experiments/financial_strategy_library_panel_v2_economic_design_audit/results/AUDIT_REPORT.md",
        "julia/scripts/run_financial_strategy_library_panel_v2_economic_design_audit.jl",
        "julia/scripts/check_financial_strategy_library_panel_v3_design.jl",
        "julia/scripts/lock_financial_strategy_library_panel_v3_design.jl",
        "julia/test/test_financial_strategy_library_panel_v3.jl",
        "julia/test/run_financial_strategy_library_panel_v3_tests.jl",
        "julia/Project.toml",
        "julia/Manifest.toml",
    ]
    return sort!(unique(vcat(design_paths, additional)))
end

function _payload()
    CheckFinancialStrategyLibraryPanelV3Design.check_design(; check = true)
    design_check_path = joinpath(EXPERIMENT_ROOT, "DESIGN_CHECK.toml")
    design_check = TOML.parsefile(design_check_path)
    design_check["passed"] === true || error("v3 design check did not pass")
    design_check["outcomes_access_permitted"] === false ||
        error("v3 design check improperly permits outcomes")

    audit = TOML.parsefile(AUDIT_SUMMARY_PATH)
    audit["status"] == "V3_ECONOMIC_DIRECTION_SUPPORTED" ||
        error("sealed v2 economic-design audit did not support v3")
    audit["direction_gate"]["trigger_count"] == 4 ||
        error("unexpected v2 economic-design gate count")

    census = TOML.parsefile(joinpath(SOURCE_CENSUS_ROOT, "SOURCE_CENSUS.toml"))
    census_manifest = TOML.parsefile(joinpath(
        SOURCE_CENSUS_ROOT,
        "SOURCE_CENSUS_MANIFEST.toml",
    ))
    census["primary_common_equity_cells_passed"] == 19 ||
        error("the primary v3 universe census is incomplete")
    census["outcome_values_accessed"] === false ||
        error("the v3 source census accessed outcomes")
    _sha256_file(LOCAL_SELECTION_PATH) == census_manifest["local_selection_sha256"] ||
        error("the exact local universe selection changed")

    sealed_paths = _sealed_paths(design_check)
    all(path -> isfile(joinpath(REPOSITORY_ROOT, path)), sealed_paths) ||
        error("one or more v3 design-lock inputs are absent")
    hashes = Dict(
        path => _sha256_file(joinpath(REPOSITORY_ROOT, path)) for path in sealed_paths
    )
    for (path, digest) in design_check["design_file_sha256"]
        hashes[path] == digest || error("design-check hash changed before lock: $path")
    end
    canonical = join(("$path\0$(hashes[path])\n" for path in sealed_paths))
    aggregate = _sha256_text(canonical)
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-design-lock-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PREDECISION",
        "language" => "Julia",
        "design_aggregate_sha256" => aggregate,
        "sealed_file_count" => length(sealed_paths),
        "sealed_file_sha256" => hashes,
        "v2_economic_direction_status" => audit["status"],
        "v2_economic_direction_gate_trigger_count" => audit["direction_gate"]["trigger_count"],
        "v2_economic_audit_summary_sha256" => _sha256_file(AUDIT_SUMMARY_PATH),
        "source_directory_aggregate_sha256" => census["source_directory_aggregate_sha256"],
        "local_universe_selection_sha256" => census_manifest["local_selection_sha256"],
        "primary_common_equity_census_cells_passed" =>
            census["primary_common_equity_cells_passed"],
        "etf_replication_census_cells_passed" => census["etf_replication_cells_passed"],
        "full_predecision_calendar_required" => true,
        "future_survival_used_for_membership" => false,
        "historical_block_is_confirmatory" => false,
        "historical_predecision_return_access_permitted" => true,
        "historical_proposal_or_evaluation_return_access_permitted" => false,
        "confirmatory_source_access_permitted" => false,
        "v3_outcomes_opened" => false,
        "next_required_seal" =>
            "frozen predecision libraries arms action sets and proposal candidate ledger",
    )
end

function lock_design(; check = false)
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("v3 design lock is absent")
        read(LOCK_PATH, String) == text || error("v3 design lock changed")
    else
        _atomic_write(LOCK_PATH, text)
    end
    println("V3_DESIGN_LOCK_PASSED")
    println("status: LOCKED_PREDECISION")
    println("historical proposal/evaluation return access permitted: false")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_design(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3Design.main()
end
