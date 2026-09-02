module LockFinancialStrategyLibraryPanelV2

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "create_financial_strategy_library_panel_v2_registries.jl"))
using .FinancialStrategyLibraryPanelV2Registries

export create_design_lock,
       dry_run,
       main,
       validate_design,
       verify_design_lock,
       verify_lock_text

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_strategy_library_panel_v2.toml",
)
const LOCK_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v2",
    "DESIGN_LOCK.json",
)

# V2 is intentionally locked as a new study after the complete v1 evidence was
# known. The lock binds the audit that motivated the redesign, every protocol
# surface, deterministic registry, public mechanism implementation, and test.
const REQUIRED_FILES = (
    "Makefile",
    "README.md",
    "REPRODUCIBILITY.md",
    "ARTIFACT_MANIFEST.md",
    "scripts/aor_check.sh",
    "experiments/configs/financial_strategy_library_panel_v2.toml",
    "experiments/financial_strategy_library_panel_v2/DESIGN.md",
    "experiments/financial_strategy_library_panel_v2/DATA_CONTRACT.md",
    "experiments/financial_strategy_library_panel_v2/ANALYSIS_PLAN.md",
    "experiments/financial_strategy_library_panel_v2/EXECUTION_PLAN.md",
    "experiments/financial_strategy_library_panel_v2/REPORTING_RULES.md",
    "experiments/financial_strategy_library_panel_v2/registry/ORIGIN_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v2/registry/SCENARIO_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v2/registry/SOURCE_DOCKET_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v2/registry/CAPABILITY_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v2/registry/BURDEN_SCHEDULE_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v2/registry/ARM_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v2/registry/SEED_REGISTRY.csv",
    "journal/aor/reports/FINANCIAL_PANEL_V1_DESIGN_FAILURE_AUDIT.md",
    "julia/Project.toml",
    "julia/Manifest.toml",
    "julia/src/StrategyInnovation.jl",
    "julia/src/FinancialInnovationChallengeV2.jl",
    "julia/scripts/create_financial_strategy_library_panel_v2_registries.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v2.jl",
    "julia/test/test_financial_strategy_library_panel_v2_registration.jl",
    "julia/test/test_financial_strategy_library_panel_v2.jl",
    "julia/test/run_financial_strategy_library_panel_v2_tests.jl",
)

_sha256_file(path::AbstractString) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text::AbstractString) = bytes2hex(sha256(codeunits(text)))

function _require_equal(actual, expected, label)
    actual == expected || error("registered $label changed: expected $expected, found $actual")
end

function validate_design(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    _require_equal(
        config["schema_version"],
        "financial-strategy-library-panel-design-v2",
        "schema version",
    )
    _require_equal(
        config["experiment_id"],
        "financial-strategy-library-panel-v2",
        "experiment identifier",
    )
    _require_equal(config["protocol_date"], "2026-09-01", "protocol date")
    _require_equal(config["julia_version"], "1.12.6", "Julia version")
    _require_equal(
        config["status"],
        "prospective_v2_design_locked_after_v1_results_before_v2_outcomes",
        "registration status",
    )
    config["v1_outcomes_known"] === true || error("v2 must acknowledge known v1 outcomes")
    config["v1_rows_may_enter_v2_estimands"] === false || error("v1 rows cannot enter v2 estimands")
    config["v1_and_v2_may_be_pooled"] === false || error("v1 and v2 cannot be pooled")
    config["licensed_rows_read_for_v2_design"] === false || error("v2 design cannot read licensed rows")
    config["v2_outcomes_observed"] === false || error("v2 outcomes cannot precede the design lock")

    source = config["source"]
    _require_equal(
        source["required_security_history_columns"]["columns"],
        ["permno", "secinfostartdt", "secinfoenddt", "ticker", "securitynm", "securitytype", "securitysubtype", "securityactiveflg"],
        "security-history schema",
    )
    _require_equal(
        source["required_daily_columns"]["columns"],
        ["permno", "dlycaldt", "dlyret", "dlyclose", "dlyprc", "dlyvol", "dlydelflg", "dlyretmissflg"],
        "daily schema",
    )
    source["revision_vintage_available"] === false || error("current-snapshot limitation was removed")
    source["raw_redistribution_permitted"] === false || error("raw redistribution cannot be allowed")
    source["public_aggregate_promotion_requires_independent_audit"] === true || error(
        "public aggregate promotion must require an independent audit",
    )

    decision = config["decision"]
    occursin("budget-matched frontier-only", decision["primary_question"]) || error(
        "primary question no longer identifies the budget-matched mechanism contrast",
    )
    origins = config["origins"]
    _require_equal(origins["origin_count"], 20, "origin count")
    _require_equal(origins["first_decision_year"], 2005, "first decision year")
    _require_equal(origins["last_decision_year"], 2024, "last decision year")
    origins["postdecision_years_overlap"] === false || error("postdecision years cannot overlap")

    universe = config["universe"]
    universe["profile_support_is_security_eligibility_rule"] === true || error(
        "profile support must be a security-level eligibility rule",
    )
    _require_equal(universe["maximum_eligible_by_liquidity"], 100, "universe cap")
    _require_equal(universe["minimum_eligible_for_origin"], 20, "minimum eligible universe")
    universe["postdecision_information_may_define_universe"] === false || error(
        "postdecision rows cannot define the universe",
    )

    grammar = config["grammar"]
    grammar_product = prod(length(grammar[key]) for key in (
        "directional_signal",
        "entry_filter",
        "holding_horizon",
        "sizing_rule",
        "exit_rule",
        "risk_constraint",
    ))
    _require_equal(grammar_product, grammar["strategies_per_instrument"], "grammar size")
    _require_equal(grammar_product, 96, "registered grammar size")

    profiles = config["operating_profiles"]
    _require_equal(profiles["scenario_count"], 30, "scenario count")
    _require_equal(length(profiles["transaction_cost_bps"]), 3, "transaction-cost levels")
    _require_equal(length(profiles["risk_aversion"]), 2, "risk-aversion levels")
    _require_equal(config["source_dockets"]["docket_count"], 2, "source docket count")
    _require_equal(config["capabilities"]["capability_count"], 27, "capability count")
    _require_equal(config["burdens"]["schedule_count"], 3, "burden schedule count")
    config["burdens"]["money_or_labor_hour_interpretation_permitted"] === false || error(
        "proxy burdens cannot be presented as observed money or labor",
    )

    arms = config["arms"]
    _require_equal(arms["arm_count"], 6, "arm count")
    arms["arm_construction_may_read_postdecision"] === false || error(
        "arm construction cannot read postdecision outcomes",
    )
    occursin("innovation-safe exact burden budget", arms["frontier_only_budget_matched"]) || error(
        "primary comparator lost the safe burden cap",
    )

    challenges = config["innovation_challenges"]
    _require_equal(challenges["menus_per_origin_docket"], 32, "menus per origin docket")
    _require_equal(challenges["candidates_per_menu"], 8, "candidates per menu")
    _require_equal(challenges["minimum_full_calendar_sessions"], 200, "minimum postdecision calendar")
    challenges["postdecision_belief_minimum_required"] === false || error(
        "postdecision belief cells cannot recreate v1 attrition",
    )
    challenges["explicit_delisting_to_cash"] === true || error(
        "explicit delisting-to-cash handling is required",
    )
    challenges["unobserved_terminal_delisting_return_imputed"] === false || error(
        "unobserved terminal delisting returns cannot be imputed",
    )

    estimand = config["primary_estimand"]
    _require_equal(estimand["unit"], "origin-level mean of complete masked challenge-menu pairs", "primary unit")
    estimand["causal_claim"] === false || error("causal claims are prohibited")
    estimand["population_claim"] === false || error("population claims are prohibited")
    gates = config["availability_gates"]
    _require_equal(gates["minimum_structurally_evaluable_origins"], 15, "structural availability gate")
    _require_equal(gates["minimum_complete_menus_per_origin_docket"], 24, "menu availability gate")
    _require_equal(gates["minimum_origin_fraction_passing_menu_gate"], 0.75, "origin availability fraction")
    gates["thresholds_may_be_changed_after_v2_outcomes"] === false || error(
        "availability gates cannot change after outcomes",
    )

    stress = config["computational_stress_block"]
    stress["separate_from_population_block"] === true || error("stress block must be separate")
    stress["warmup_outside_timed_region"] === true || error("timing warm-up must be excluded")
    _require_equal(stress["steady_state_repetitions"], 5, "steady-state repetitions")
    publication = config["publication"]
    publication["public_promotion_automatic"] === false || error("public promotion cannot be automatic")
    expected_nonclaims = Set([
        "causal",
        "forecasting",
        "alpha",
        "deployable performance",
        "population resource savings",
        "observed institutional cost",
    ])
    Set(String.(publication["nonclaims"])) == expected_nonclaims || error("registered nonclaims changed")

    registry_counts = check_registries()
    for path in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, path)) || error("missing lock input: $path")
    end
    return (config = config, registry_counts = registry_counts)
end

function _hashes()
    return Dict(path => _sha256_file(joinpath(REPOSITORY_ROOT, path)) for path in REQUIRED_FILES)
end

function _aggregate(hashes)
    return _sha256_text(join(
        ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
    ))
end

function _assert_no_v2_outputs(config)
    for key in ("local_data_root", "local_results_root", "public_results_root")
        relative = config["paths"][key]
        path = joinpath(REPOSITORY_ROOT, relative)
        ispath(path) && (!isdir(path) || !isempty(readdir(path))) && error(
            "cannot lock after v2 data or results exist: $relative",
        )
    end
    return true
end

function _render_lock(hashes, counts)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-design-lock-v2",
  "experiment_id": "financial-strategy-library-panel-v2",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "parent_commit": "e0a324c497500d868aef981bbdda4c2466832c46",
  "v1_outcomes_known_before_v2_design": true,
  "v1_rows_permitted_in_v2_estimands": false,
  "v2_licensed_rows_read_before_lock": false,
  "v2_outcomes_observed_before_lock": false,
  "v2_result_artifacts_present_before_lock": false,
  "origin_count": $(counts.origin_count),
  "operating_scenario_count": $(counts.scenario_count),
  "source_docket_count": $(counts.docket_count),
  "capability_count": $(counts.capability_count),
  "burden_schedule_count": $(counts.burden_count),
  "arm_count": $(counts.arm_count),
  "origin_docket_seed_rows": $(counts.seed_count),
  "registered_challenge_menus": 1280,
  "registered_challenge_candidates": 10240,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    occursin(
        "\"schema_version\": \"financial-strategy-library-panel-design-lock-v2\"",
        text,
    ) || error("unexpected or missing v2 design-lock schema")
    occursin("\"v1_outcomes_known_before_v2_design\": true", text) || error(
        "known v1 evidence is not acknowledged",
    )
    occursin("\"v2_licensed_rows_read_before_lock\": false", text) || error(
        "invalid v2 licensed-row declaration",
    )
    occursin("\"v2_outcomes_observed_before_lock\": false", text) || error(
        "invalid v2 outcome declaration",
    )
    for path in keys(hashes)
        occursin("\"$path\": \"$(hashes[path])\"", text) || error(
            "financial panel v2 design-lock mismatch: $path",
        )
    end
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) || error(
        "financial panel v2 design-lock aggregate mismatch",
    )
    return aggregate
end

function dry_run(config_path::AbstractString = DEFAULT_CONFIG)
    validated = validate_design(config_path)
    _assert_no_v2_outputs(validated.config)
    hashes = _hashes()
    text = _render_lock(hashes, validated.registry_counts)
    aggregate = verify_lock_text(text, hashes)
    return (aggregate_sha256 = aggregate, registry_counts = validated.registry_counts)
end

function create_design_lock(config_path::AbstractString = DEFAULT_CONFIG)
    isfile(LOCK_PATH) && error("financial panel v2 design lock already exists; do not rewrite it")
    validated = validate_design(config_path)
    _assert_no_v2_outputs(validated.config)
    hashes = _hashes()
    text = _render_lock(hashes, validated.registry_counts)
    verify_lock_text(text, hashes)
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, LOCK_PATH; force = false)
    println("created financial strategy-library panel v2 design lock")
    return LOCK_PATH
end

function verify_design_lock(config_path::AbstractString = DEFAULT_CONFIG)
    validate_design(config_path)
    isfile(LOCK_PATH) || error("financial panel v2 design lock is absent")
    return verify_lock_text(read(LOCK_PATH, String), _hashes())
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v2.jl --dry-run|--create|--check",
    )
    mode = only(args)
    mode == "--dry-run" && return println("financial panel v2 dry run valid: $(dry_run())")
    mode == "--create" && return create_design_lock()
    mode == "--check" && return println(
        "financial panel v2 design lock valid: $(verify_design_lock())",
    )
    error("unknown lock mode: $mode")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV2.main()
end
