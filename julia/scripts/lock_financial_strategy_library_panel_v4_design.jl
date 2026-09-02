module LockFinancialStrategyLibraryPanelV4Design

using SHA: sha256
using TOML

export check_lock, lock_design, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v4",
)
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_strategy_library_panel_v4.toml",
)
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_LOCK.toml")
const DESIGN_FILES = [
    CONFIG_PATH,
    joinpath(EXPERIMENT_ROOT, "README.md"),
    joinpath(EXPERIMENT_ROOT, "DESIGN.md"),
    joinpath(EXPERIMENT_ROOT, "ANALYSIS_PLAN.md"),
    joinpath(EXPERIMENT_ROOT, "CLAIM_BOUNDARY.md"),
    joinpath(EXPERIMENT_ROOT, "LITERATURE_ALIGNMENT.md"),
    joinpath(EXPERIMENT_ROOT, "registry", "REGIME_REGISTRY.csv"),
    joinpath(EXPERIMENT_ROOT, "registry", "OUTCOME_REGISTRY.csv"),
    joinpath(EXPERIMENT_ROOT, "registry", "SEED_REGISTRY.csv"),
    joinpath(EXPERIMENT_ROOT, "calibration", "CALIBRATION.toml"),
    joinpath(REPOSITORY_ROOT, "julia", "src", "FinancialStrategyLibraryPanelV4.jl"),
    joinpath(REPOSITORY_ROOT, "julia", "scripts", "calibrate_financial_strategy_library_panel_v4.jl"),
    joinpath(REPOSITORY_ROOT, "julia", "scripts", "lock_financial_strategy_library_panel_v4_design.jl"),
    joinpath(REPOSITORY_ROOT, "julia", "scripts", "run_financial_strategy_library_panel_v4.jl"),
    joinpath(REPOSITORY_ROOT, "julia", "scripts", "audit_financial_strategy_library_panel_v4.jl"),
    joinpath(REPOSITORY_ROOT, "julia", "test", "test_financial_strategy_library_panel_v4.jl"),
    joinpath(REPOSITORY_ROOT, "julia", "test", "run_financial_strategy_library_panel_v4_tests.jl"),
]

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _atomic_write(path, text)
    temporary = path * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, path; force = true)
    return path
end

function _csv_rows(path)
    lines = filter(!isempty, strip.(readlines(path)))
    isempty(lines) && error("empty registry: $(relpath(path, REPOSITORY_ROOT))")
    header = split(first(lines), ',')
    return [
        Dict(String(key) => String(value) for (key, value) in zip(
            header,
            split(line, ','; keepempty = true),
        )) for line in Iterators.drop(lines, 1)
    ]
end

function _validate_design()
    all(isfile, DESIGN_FILES) || error("one or more v4 design files are absent")
    config = TOML.parsefile(CONFIG_PATH)
    config["experiment_id"] == "financial-strategy-library-panel-v4" ||
        error("unexpected v4 experiment identifier")
    config["language"] == "Julia" || error("v4 main language is not Julia")
    config["v3_result_is_immutable_input_context"] === true ||
        error("v3 immutability is not registered")
    config["v3_policy_outcomes_enter_v4_treatment_margins"] === false ||
        error("v3 policy outcomes may not set v4 treatment margins")
    config["decision"]["empirical_alpha_claim_permitted"] === false ||
        error("v4 claim boundary was broadened to market alpha")
    config["calibration"]["gate_passed_cells_only"] === true ||
        error("calibration gate changed")
    config["calibration"]["use_every_complete_candidate_path"] === true ||
        error("complete calibration path census is not mandatory")
    simulation = config["simulation"]
    simulation["calibration_world_count"] == 4096 || error("null calibration size changed")
    simulation["evaluation_world_count_per_regime"] == 4096 ||
        error("test world count changed")
    simulation["common_random_numbers_across_regimes"] === true ||
        error("paired regime shocks are no longer required")
    selection = config["selection"]
    selection["target_candidate_count"] == 1 || error("v4 primary search family changed")
    selection["candidate_is_predeclared_by_module_lineage"] === true ||
        error("target descendant is no longer lineage-designated")
    selection["historical_best_candidate_search_permitted"] === false ||
        error("historical best-candidate selection was enabled")
    config["structure"]["safe_retention_burden"] ==
        config["structure"]["frontier_retention_burden"] ||
        error("structural arms no longer have equal burden")
    config["structure"]["safe_operating_frontier"] ==
        config["structure"]["frontier_operating_frontier"] ||
        error("structural arms no longer have equal current frontier")
    config["structure"]["safe_bridge_capability"] === true ||
        error("safe arm lost the bridge capability")
    config["structure"]["frontier_bridge_capability"] === false ||
        error("frontier arm gained the bridge capability")
    config["structure"]["cash_is_always_feasible"] === true ||
        error("cash outside option is not mandatory")

    regimes = _csv_rows(joinpath(EXPERIMENT_ROOT, "registry", "REGIME_REGISTRY.csv"))
    length(regimes) == 4 || error("v4 must retain four registered regimes")
    regime_ids = getindex.(regimes, "regime_id")
    regime_ids == [
        "adversarial_margin",
        "null_margin",
        "low_dose_positive",
        "powered_positive",
    ] || error("v4 regime order or identities changed")
    count(row -> row["role"] == "primary_positive", regimes) == 1 ||
        error("v4 must have one primary positive regime")

    outcomes = _csv_rows(joinpath(EXPERIMENT_ROOT, "registry", "OUTCOME_REGISTRY.csv"))
    count(row -> row["role"] == "primary", outcomes) == 1 ||
        error("v4 must have one primary estimand")
    only(filter(row -> row["role"] == "primary", outcomes))["outcome_id"] ==
        "oracle_productive_value" || error("v4 primary outcome changed")

    seeds = _csv_rows(joinpath(EXPERIMENT_ROOT, "registry", "SEED_REGISTRY.csv"))
    length(unique(getindex.(seeds, "base_seed"))) == length(seeds) ||
        error("v4 seed registry contains duplicates")
    all(row -> row["mutable_after_lock"] == "false", seeds) ||
        error("a v4 seed remains mutable")

    calibration = TOML.parsefile(joinpath(EXPERIMENT_ROOT, "calibration", "CALIBRATION.toml"))
    calibration["source_file_count"] == 37 || error("v4 calibration lost a gate-passed cell")
    calibration["security_identifiers_included"] === false ||
        error("v4 calibration exported security identifiers")
    calibration["return_values_included"] === false ||
        error("v4 calibration exported licensed returns")
    calibration["config_sha256"] == _sha256_file(CONFIG_PATH) ||
        error("v4 calibration is not bound to the current config")
    return true
end

function _lock_payload()
    _validate_design()
    file_rows = [
        Dict(
            "path" => relpath(path, REPOSITORY_ROOT),
            "sha256" => _sha256_file(path),
        ) for path in DESIGN_FILES
    ]
    aggregate = bytes2hex(sha256(join(
        (row["path"] * ":" * row["sha256"] for row in file_rows),
        '\n',
    )))
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v4-design-lock-v1",
        "experiment_id" => "financial-strategy-library-panel-v4",
        "status" => "LOCKED_BEFORE_SIMULATED_TEST_WORLD_GENERATION",
        "language" => "Julia",
        "result_values_accessed" => false,
        "design_file_count" => length(file_rows),
        "design_aggregate_sha256" => aggregate,
        "files" => file_rows,
    )
end

function lock_design()
    result_files = isdir(joinpath(EXPERIMENT_ROOT, "results")) ?
        readdir(joinpath(EXPERIMENT_ROOT, "results")) : String[]
    isempty(result_files) || error("v4 results already exist; design cannot be newly locked")
    isfile(LOCK_PATH) && error("v4 design lock already exists")
    payload = _lock_payload()
    _atomic_write(LOCK_PATH, _toml_text(payload))
    return payload
end

function check_lock()
    isfile(LOCK_PATH) || error("v4 design lock is absent")
    existing = TOML.parsefile(LOCK_PATH)
    expected = _lock_payload()
    existing == expected || error("v4 design lock does not match current design files")
    return existing
end

function main(args = ARGS)
    mode = isempty(args) ? "--check" : only(args)
    payload = mode == "--lock" ? lock_design() :
        mode == "--check" ? check_lock() :
        error("usage: lock_financial_strategy_library_panel_v4_design.jl [--lock|--check]")
    println("V4_DESIGN_LOCK_OK")
    println("design aggregate: ", payload["design_aggregate_sha256"])
    return payload
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV4Design.main()
end
