module CheckFinancialStrategyLibraryPanelV3Design

using SHA: sha256
using TOML

export check_design, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_strategy_library_panel_v3.toml",
)
const CHECK_PATH = joinpath(EXPERIMENT_ROOT, "DESIGN_CHECK.toml")
const SOURCE_CENSUS_ROOT = joinpath(EXPERIMENT_ROOT, "source_census")
const LOCAL_SELECTION_PATH = joinpath(
    EXPERIMENT_ROOT,
    "local_data",
    "universe_census",
    "UNIVERSE_SELECTIONS.toml",
)
const DESIGN_FILES = [
    CONFIG_PATH,
    joinpath(EXPERIMENT_ROOT, "DESIGN.md"),
    joinpath(EXPERIMENT_ROOT, "ANALYSIS_PLAN.md"),
    joinpath(EXPERIMENT_ROOT, "CLAIM_BOUNDARY.md"),
    joinpath(EXPERIMENT_ROOT, "DATA_CONTRACT.md"),
    joinpath(EXPERIMENT_ROOT, "LITERATURE_ALIGNMENT.md"),
    joinpath(EXPERIMENT_ROOT, "README.md"),
    joinpath(EXPERIMENT_ROOT, "registry", "ORIGIN_REGISTRY.csv"),
    joinpath(EXPERIMENT_ROOT, "registry", "UNIVERSE_REGISTRY.csv"),
    joinpath(EXPERIMENT_ROOT, "registry", "ARM_REGISTRY.csv"),
    joinpath(EXPERIMENT_ROOT, "registry", "POLICY_REGISTRY.csv"),
    joinpath(EXPERIMENT_ROOT, "registry", "OUTCOME_REGISTRY.csv"),
    joinpath(EXPERIMENT_ROOT, "registry", "CAPABILITY_REGISTRY.csv"),
    joinpath(EXPERIMENT_ROOT, "registry", "SEED_REGISTRY.csv"),
    joinpath(EXPERIMENT_ROOT, "registry", "TRIAL_LEDGER_SCHEMA.csv"),
    joinpath(REPOSITORY_ROOT, "julia", "src", "FinancialStrategyLibraryPanelV3.jl"),
    joinpath(
        REPOSITORY_ROOT,
        "julia",
        "scripts",
        "build_financial_strategy_library_panel_v3_universe_census.jl",
    ),
    joinpath(SOURCE_CENSUS_ROOT, "SOURCE_CENSUS.toml"),
    joinpath(SOURCE_CENSUS_ROOT, "SOURCE_CENSUS.csv"),
    joinpath(SOURCE_CENSUS_ROOT, "SOURCE_CENSUS_MANIFEST.toml"),
]

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

function _csv_rows(path)
    lines = filter(!isempty, strip.(readlines(path)))
    isempty(lines) && error("empty registry: $(relpath(path, REPOSITORY_ROOT))")
    header = split(first(lines), ',')
    rows = Dict{String,String}[]
    for line in Iterators.drop(lines, 1)
        fields = split(line, ','; keepempty = true)
        length(fields) == length(header) ||
            error("registry row width changed in $(relpath(path, REPOSITORY_ROOT))")
        push!(rows, Dict(String(key) => String(value) for (key, value) in zip(header, fields)))
    end
    return rows
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

function _validate()
    all(isfile, DESIGN_FILES) || error("one or more v3 design files are absent")
    config = TOML.parsefile(CONFIG_PATH)
    config["language"] == "Julia" || error("v3 main language is not Julia")
    config["status"] == "locked_predecision_no_v3_outcomes_opened" ||
        error("unexpected v3 design status")
    config["v3_outcomes_opened"] === false || error("v3 outcome access is not locked")
    config["historical_v3_block_is_confirmatory"] === false ||
        error("historical v3 block was mislabeled confirmatory")
    config["decision"]["candidate_unit"] ==
        "diversified portfolio strategy; never security-by-strategy identity" ||
        error("v3 candidate unit changed")
    config["innovation_options"]["cash_is_always_feasible"] === true ||
        error("cash outside option is not mandatory")
    config["innovation_options"]["comparator_choice_is_always_feasible_to_safe_policy"] === true ||
        error("safe policy lost its comparator default")
    config["innovation_options"]["safe_action_set_must_contain_comparator_action_set"] === true ||
        error("action-set nesting is not mandatory")
    config["innovation_options"]["forced_active_choice_permitted"] === false ||
        error("forced active choice was re-enabled")
    config["innovation_options"]["random_challenge_menus"] === false ||
        error("random menus were re-enabled")
    config["proposal_policy"]["simultaneous_uncertainty_method"] ==
        "paired moving-block bootstrap max-t over every considered incremental candidate" ||
        error("simultaneous proposal uncertainty rule changed")
    config["analysis"]["multiple_testing_trial_ledger_required"] === true ||
        error("complete trial ledger is no longer mandatory")
    config["compression"]["exact_mip_is_primary"] === true ||
        error("exact MIP is not the primary structural benchmark")
    grammar = config["portfolio_grammar"]
    grammar_count = prod(length(grammar[key]) for key in (
        "directional_signal",
        "entry_filter",
        "holding_horizon",
        "allocation_rule",
        "gross_target",
        "exit_rule",
    ))
    grammar_count == 96 || error("portfolio grammar no longer has 96 strategies")
    grammar_count == grammar["portfolio_strategies_per_universe"] ||
        error("registered portfolio grammar count does not reconcile")

    origins = _csv_rows(joinpath(EXPERIMENT_ROOT, "registry", "ORIGIN_REGISTRY.csv"))
    length(origins) == 19 || error("origin registry does not contain 19 origins")
    years = parse.(Int, getindex.(origins, "compression_decision_year"))
    years == collect(2005:2023) || error("origin decision years changed")
    for row in origins
        year = parse(Int, row["compression_decision_year"])
        parse(Int, row["formation_start_year"]) == year - 5 || error("formation start changed")
        parse(Int, row["formation_end_year"]) == year - 3 || error("formation end changed")
        parse(Int, row["compression_start_year"]) == year - 2 || error("compression start changed")
        parse(Int, row["compression_end_year"]) == year || error("compression end changed")
        parse(Int, row["proposal_year"]) == year + 1 || error("proposal year changed")
        parse(Int, row["evaluation_year"]) == year + 2 || error("evaluation year changed")
        row["role"] == "historical_development" || error("historical origin role changed")
    end

    universes = _csv_rows(joinpath(EXPERIMENT_ROOT, "registry", "UNIVERSE_REGISTRY.csv"))
    length(universes) == 2 || error("universe registry must contain two separate panels")
    count(row -> row["role"] == "primary", universes) == 1 ||
        error("v3 must have exactly one primary universe")
    all(row -> row["mixing_permitted"] == "false", universes) ||
        error("equity/ETF mixing was re-enabled")
    all(row -> row["predecision_calendar_completeness"] == "1.0", universes) ||
        error("a v3 universe no longer requires complete predecision data")
    config["universes"]["future_survival_may_define_membership"] === false ||
        error("future survival was enabled as a universe rule")

    arms = _csv_rows(joinpath(EXPERIMENT_ROOT, "registry", "ARM_REGISTRY.csv"))
    arm_ids = Set(getindex.(arms, "arm_id"))
    Set(("innovation_safe_exact", "frontier_only_exact_budget_matched")) ⊆ arm_ids ||
        error("primary structural arms are absent")
    all(row -> row["exact_primary"] == "true", filter(
        row -> row["arm_id"] in ("innovation_safe_exact", "frontier_only_exact_budget_matched"),
        arms,
    )) || error("a primary structural arm is not exact")

    policies = _csv_rows(joinpath(EXPERIMENT_ROOT, "registry", "POLICY_REGISTRY.csv"))
    policy_ids = Set(getindex.(policies, "policy_id"))
    Set(("frontier_only_robust_policy", "innovation_safe_robust_policy")) ⊆ policy_ids ||
        error("primary economic policies are absent")
    safe_policy = only(filter(row -> row["policy_id"] == "innovation_safe_robust_policy", policies))
    safe_policy["outside_option"] == "exact comparator choice" ||
        error("safe policy no longer defaults to the comparator")

    outcomes = _csv_rows(joinpath(EXPERIMENT_ROOT, "registry", "OUTCOME_REGISTRY.csv"))
    economic_primary = filter(row -> row["role"] == "primary economic", outcomes)
    length(economic_primary) == 1 || error("v3 must have one primary economic outcome")
    only(economic_primary)["outcome_id"] == "incremental_portfolio_certainty_equivalent" ||
        error("primary economic outcome changed")

    capabilities = _csv_rows(joinpath(EXPERIMENT_ROOT, "registry", "CAPABILITY_REGISTRY.csv"))
    length(capabilities) == 32 || error("v3 capability registry must contain 32 capabilities")
    capability_ids = getindex.(capabilities, "capability_id")
    length(unique(capability_ids)) == length(capability_ids) ||
        error("v3 capability identifiers are not unique")
    count(row -> row["component_type"] == "platform_artifact", capabilities) == 5 ||
        error("platform capability artifacts changed")

    seeds = _csv_rows(joinpath(EXPERIMENT_ROOT, "registry", "SEED_REGISTRY.csv"))
    seed_purposes = getindex.(seeds, "purpose_id")
    length(unique(seed_purposes)) == length(seed_purposes) ||
        error("v3 seed purposes are not unique")
    base_seeds = parse.(Int, getindex.(seeds, "base_seed"))
    length(unique(base_seeds)) == length(base_seeds) ||
        error("v3 base seeds are not unique")
    all(row -> row["mutable_after_lock"] == "false", seeds) ||
        error("a registered v3 seed is mutable after lock")
    Set(("proposal_max_t", "reality_check", "spa", "pbo_cscv")) ⊆ Set(seed_purposes) ||
        error("one or more registered search-control seeds are absent")

    ledger = _csv_rows(joinpath(EXPERIMENT_ROOT, "registry", "TRIAL_LEDGER_SCHEMA.csv"))
    ledger_fields = Set(getindex.(ledger, "field_id"))
    Set((
        "trial_id",
        "strategy_id",
        "generatable",
        "failure_code",
        "proposal_incremental_lower_bound",
        "policy_selected",
        "evaluation_ce",
        "record_hash",
    )) ⊆ ledger_fields || error("v3 trial ledger omits a mandatory field")

    costs = config["cost_capacity"]
    costs["primary_one_way_cost_bps"] == config["economic_outcome"]["baseline_one_way_cost_bps"] ||
        error("primary transaction-cost parameters disagree")
    costs["maximum_daily_adv_participation"] == 0.10 ||
        error("capacity participation cap changed")
    costs["volume_and_volatility_inputs_are_lagged"] === true ||
        error("capacity inputs are not lagged")

    census = TOML.parsefile(joinpath(SOURCE_CENSUS_ROOT, "SOURCE_CENSUS.toml"))
    census_manifest = TOML.parsefile(joinpath(
        SOURCE_CENSUS_ROOT,
        "SOURCE_CENSUS_MANIFEST.toml",
    ))
    census["outcome_values_accessed"] === false ||
        error("source census accessed outcome values")
    census["future_survival_used_for_membership"] === false ||
        error("source census conditioned on future survival")
    census["full_predecision_calendar_required"] === true ||
        error("source census did not enforce full predecision data")
    census["primary_common_equity_cells_passed"] == 19 ||
        error("not every primary common-equity census cell passed")
    census["etf_replication_cells_passed"] == 18 ||
        error("unexpected ETF replication census count")
    census_manifest["source_census_toml_sha256"] ==
        _sha256_file(joinpath(SOURCE_CENSUS_ROOT, "SOURCE_CENSUS.toml")) ||
        error("source census TOML hash changed")
    census_manifest["source_census_csv_sha256"] ==
        _sha256_file(joinpath(SOURCE_CENSUS_ROOT, "SOURCE_CENSUS.csv")) ||
        error("source census CSV hash changed")
    census_manifest["config_sha256"] == _sha256_file(CONFIG_PATH) ||
        error("source census config binding changed")
    census_manifest["data_contract_sha256"] ==
        _sha256_file(joinpath(EXPERIMENT_ROOT, "DATA_CONTRACT.md")) ||
        error("source census data-contract binding changed")
    census_manifest["script_sha256"] == _sha256_file(joinpath(
        REPOSITORY_ROOT,
        "julia",
        "scripts",
        "build_financial_strategy_library_panel_v3_universe_census.jl",
    )) || error("source census implementation binding changed")
    isfile(LOCAL_SELECTION_PATH) || error("local exact universe selection is absent")
    census_manifest["local_selection_sha256"] == _sha256_file(LOCAL_SELECTION_PATH) ||
        error("local exact universe selection hash changed")

    for forbidden in ("local_results", "postdecision", "evaluation_results")
        ispath(joinpath(EXPERIMENT_ROOT, forbidden)) &&
            error("v3 outcome-bearing path exists before design lock: $forbidden")
    end

    hashes = Dict(
        relpath(path, REPOSITORY_ROOT) => _sha256_file(path) for path in DESIGN_FILES
    )
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-design-check-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "passed" => true,
        "language" => "Julia",
        "design_ready_for_review_and_lock" => true,
        "outcomes_access_permitted" => false,
        "historical_block_is_confirmatory" => false,
        "origin_count" => length(origins),
        "universe_count" => length(universes),
        "portfolio_grammar_count_per_universe" => grammar_count,
        "capability_count" => length(capabilities),
        "seed_purpose_count" => length(seeds),
        "trial_ledger_field_count" => length(ledger),
        "primary_common_equity_census_cells_passed" =>
            census["primary_common_equity_cells_passed"],
        "etf_replication_census_cells_passed" => census["etf_replication_cells_passed"],
        "primary_structural_arm_count" => 2,
        "primary_economic_outcome_count" => length(economic_primary),
        "design_file_sha256" => hashes,
    )
end

function check_design(; check = false)
    payload = _validate()
    text = _toml_text(payload)
    if check
        isfile(CHECK_PATH) || error("v3 design-check artifact is absent")
        read(CHECK_PATH, String) == text || error("v3 design-check artifact changed")
    else
        _atomic_write(CHECK_PATH, text)
    end
    println("V3_DESIGN_CHECK_PASSED")
    println("outcomes access permitted: false")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    check_design(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    CheckFinancialStrategyLibraryPanelV3Design.main()
end
