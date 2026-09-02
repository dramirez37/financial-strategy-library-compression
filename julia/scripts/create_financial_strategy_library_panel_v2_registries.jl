module FinancialStrategyLibraryPanelV2Registries

using SHA: sha256

export arm_rows,
       burden_rows,
       capability_ids_for_spec,
       capability_rows,
       check_registries,
       docket_rows,
       expected_registry_texts,
       governance_review_units,
       origin_rows,
       scenario_rows,
       seed_rows,
       validate_registry_design,
       validation_work_units,
       write_registries

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const REGISTRY_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v2",
    "registry",
)

function _csv_escape(value)
    text = value isa Bool ? (value ? "true" : "false") : string(value)
    return occursin(r"[\",\n\r]", text) ? "\"$(replace(text, "\"" => "\"\""))\"" : text
end

function _render_csv(rows)
    isempty(rows) && error("cannot render an empty registry")
    columns = propertynames(first(rows))
    all(propertynames(row) == columns for row in rows) || error(
        "registry rows have inconsistent columns",
    )
    output = IOBuffer()
    println(output, join(string.(columns), ","))
    for row in rows
        println(
            output,
            join((_csv_escape(getproperty(row, column)) for column in columns), ","),
        )
    end
    return String(take!(output))
end

function _seed(parts...)
    digest = sha256(codeunits(join(string.(parts), '\0')))
    value = zero(UInt64)
    for byte in digest[1:8]
        value = (value << 8) | UInt64(byte)
    end
    return Int(mod(value, UInt64(9_000_000_000_000_000_000)) + one(UInt64))
end

function origin_rows()
    return [(
        origin_id = "FSLP2-O$year",
        decision_year = year,
        decision_date_rule = "last CRSP trading session on or before December 31",
        construction_start_year = year - 4,
        construction_end_year = year - 2,
        compression_start_year = year - 1,
        compression_end_year = year,
        postdecision_year = year + 1,
        universe_cap = 100,
        minimum_supported_eligible = 20,
        menus_per_docket = 32,
        candidates_per_menu = 8,
        origin_role = "final",
    ) for year in 2005:2024]
end

function scenario_rows()
    rows = NamedTuple[]
    for belief_state in 1:5, transaction_cost_bps in (0, 5, 15), risk_aversion in (1, 3)
        push!(rows, (
            scenario_id = "belief_$(belief_state)|cost_$(transaction_cost_bps)|risk_$(risk_aversion)",
            belief_state,
            transaction_cost_bps,
            risk_aversion,
            role = transaction_cost_bps == 5 && risk_aversion == 3 ? "base_and_robust_frontier" : "robust_frontier",
            estimation_window = "compression window only",
            postdecision_information_permitted = false,
        ))
    end
    return rows
end

function docket_rows()
    return [
        (
            docket_id = "focused_docket",
            reader_label = "Focused research docket",
            per_security_rank_depth = 2,
            per_scenario_rank_depth = 3,
            per_capability_carrier_depth = 3,
            construction_score = "construction-window pooled score at 5 bps and risk aversion 3",
            tie_rule = "retain every exact cutoff tie; stable identifier only orders output",
            role = "primary",
            postdecision_information_permitted = false,
        ),
        (
            docket_id = "broad_docket",
            reader_label = "Broad research docket",
            per_security_rank_depth = 5,
            per_scenario_rank_depth = 5,
            per_capability_carrier_depth = 5,
            construction_score = "construction-window pooled score at 5 bps and risk aversion 3",
            tie_rule = "retain every exact cutoff tie; stable identifier only orders output",
            role = "registered breadth sensitivity",
            postdecision_information_permitted = false,
        ),
    ]
end

function capability_rows()
    rows = NamedTuple[]
    atomic = [
        ("signal", ["momentum_20", "momentum_60", "mean_reversion_5"]),
        ("filter", ["always", "trend_100"]),
        ("horizon", ["5", "20"]),
        ("sizing", ["unit", "half"]),
        ("exit", ["horizon", "signal_flip"]),
        ("risk", ["notional_cap_1", "vol_target_10"]),
    ]
    for (class, values) in atomic, value in values
        push!(rows, (
            capability_id = "atomic::$class::$value::v2",
            capability_class = "atomic_$class",
            capability_value = value,
            evidence_scope = "canonical_executable_specification",
            carrier_rule = "every frozen source strategy whose specification contains this exact value",
            evidence_rule = "canonical_strategy_spec_sha256",
            minimum_source_carriers = 3,
            closure_role = "primary_identity_union",
        ))
    end
    interfaces = [
        ("signal_filter", ["momentum_20", "momentum_60", "mean_reversion_5"], ["always", "trend_100"]),
        ("horizon_exit", ["5", "20"], ["horizon", "signal_flip"]),
        ("sizing_risk", ["unit", "half"], ["notional_cap_1", "vol_target_10"]),
    ]
    for (class, left_values, right_values) in interfaces,
        left in left_values,
        right in right_values
        value = "$left+$right"
        push!(rows, (
            capability_id = "interface::$class::$value::v2",
            capability_class = "interface_$class",
            capability_value = value,
            evidence_scope = "canonical_executable_specification",
            carrier_rule = "every frozen source strategy whose specification contains this exact interface",
            evidence_rule = "canonical_strategy_spec_sha256",
            minimum_source_carriers = 3,
            closure_role = "primary_identity_union",
        ))
    end
    return rows
end

function capability_ids_for_spec(;
    signal::AbstractString,
    filter::AbstractString,
    horizon::Integer,
    sizing::AbstractString,
    exit_rule::AbstractString,
    risk::AbstractString,
)
    return [
        "atomic::signal::$signal::v2",
        "atomic::filter::$filter::v2",
        "atomic::horizon::$horizon::v2",
        "atomic::sizing::$sizing::v2",
        "atomic::exit::$exit_rule::v2",
        "atomic::risk::$risk::v2",
        "interface::signal_filter::$signal+$filter::v2",
        "interface::horizon_exit::$horizon+$exit_rule::v2",
        "interface::sizing_risk::$sizing+$risk::v2",
    ]
end

_ceildiv(numerator::Integer, denominator::Integer) = cld(numerator, denominator)

function validation_work_units(;
    signal_evaluations::Integer,
    filter_evaluations::Integer,
    risk_updates::Integer,
    position_decisions::Integer,
    exit_evaluations::Integer,
)
    counts = (
        signal_evaluations,
        filter_evaluations,
        risk_updates,
        position_decisions,
        exit_evaluations,
    )
    all(count -> count >= 0, counts) || throw(
        ArgumentError("operation counts must be nonnegative"),
    )
    return 1 +
           _ceildiv(signal_evaluations, 252) +
           _ceildiv(filter_evaluations, 252) +
           _ceildiv(risk_updates, 252) +
           _ceildiv(position_decisions, 52) +
           _ceildiv(exit_evaluations, 252)
end

function governance_review_units(nonbaseline_grammar_fields::Integer)
    0 <= nonbaseline_grammar_fields <= 6 || throw(
        ArgumentError("nonbaseline grammar-field count must lie in 0:6"),
    )
    return 11 + nonbaseline_grammar_fields
end

function burden_rows()
    return [
        (
            schedule_id = "validation_work_units",
            role = "primary",
            units = "predecision validation-operation blocks",
            formula = "1+ceil(signal_evaluations/252)+ceil(filter_evaluations/252)+ceil(risk_updates/252)+ceil(position_decisions/52)+ceil(exit_evaluations/252)",
            permitted_inputs = "compression-window session and deterministic operation counts; grammar fields",
            prohibited_inputs = "menus; postdecision returns; future survival; selected identities; savings; solver status; runtime",
            exact_weight_type = "positive integer",
            interpretation = "auditable index; not money or labor hours",
        ),
        (
            schedule_id = "equal_active_strategy",
            role = "robustness",
            units = "active-maintenance slots",
            formula = "1",
            permitted_inputs = "active versus mandatory-inactive flag",
            prohibited_inputs = "all financial outcomes; menus; selected identities; solver and runtime fields",
            exact_weight_type = "positive integer",
            interpretation = "cardinality only",
        ),
        (
            schedule_id = "governance_review_units",
            role = "robustness",
            units = "registered governance checklist rows",
            formula = "11+count_of_nonbaseline_grammar_fields",
            permitted_inputs = "canonical specification; nine capability references; evidence hash",
            prohibited_inputs = "menus; postdecision returns; future survival; selected identities; savings; solver status; runtime",
            exact_weight_type = "positive integer in 11:17",
            interpretation = "review-complexity index; not observed governance effort",
        ),
    ]
end

function arm_rows()
    return [
        (
            arm_id = "source",
            reader_label = "Uncompressed source docket",
            preserves_frontier = true,
            preserves_closure = true,
            burden_match_target = "none",
            selection_rule = "retain every frozen source strategy",
            role = "reference",
        ),
        (
            arm_id = "innovation_safe_exact",
            reader_label = "Innovation-safe exact",
            preserves_frontier = true,
            preserves_closure = true,
            burden_match_target = "global minimum under the registered schedule",
            selection_rule = "exact tagged-cover optimum; stable representative",
            role = "primary treatment",
        ),
        (
            arm_id = "frontier_only_exact",
            reader_label = "Frontier-only exact",
            preserves_frontier = true,
            preserves_closure = false,
            burden_match_target = "global minimum under the registered schedule",
            selection_rule = "exact frontier-cover optimum; stable representative",
            role = "closure-price reference",
        ),
        (
            arm_id = "frontier_only_budget_matched",
            reader_label = "Frontier-only budget matched",
            preserves_frontier = true,
            preserves_closure = false,
            burden_match_target = "innovation_safe_exact burden upper bound",
            selection_rule = "scan all strategies in descending frozen predecision pooled score and add each whole strategy that fits the safe exact burden cap",
            role = "primary comparator",
        ),
        (
            arm_id = "innovation_safe_greedy",
            reader_label = "Innovation-safe weighted greedy",
            preserves_frontier = true,
            preserves_closure = true,
            burden_match_target = "none",
            selection_rule = "weighted greedy plus reverse deletion with exact recheck",
            role = "algorithm diagnostic",
        ),
        (
            arm_id = "innovation_safe_multistart_64",
            reader_label = "Innovation-safe 64-start deletion",
            preserves_frontier = true,
            preserves_closure = true,
            burden_match_target = "none",
            selection_rule = "best exact-feasible endpoint from 64 registered seeded deletion orders",
            role = "algorithm diagnostic",
        ),
    ]
end

function seed_rows()
    rows = NamedTuple[]
    for origin in origin_rows(), docket in docket_rows()
        push!(rows, (
            origin_id = origin.origin_id,
            docket_id = docket.docket_id,
            seed_role = "final",
            menu_seed = _seed("financial-strategy-library-panel-v2", origin.origin_id, docket.docket_id, "menus"),
            multistart_seed = _seed("financial-strategy-library-panel-v2", origin.origin_id, docket.docket_id, "multistart"),
            origin_bootstrap_seed = _seed("financial-strategy-library-panel-v2", origin.origin_id, docket.docket_id, "bootstrap"),
        ))
    end
    return rows
end

function validate_registry_design()
    origins = origin_rows()
    scenarios = scenario_rows()
    dockets = docket_rows()
    capabilities = capability_rows()
    burdens = burden_rows()
    arms = arm_rows()
    seeds = seed_rows()
    length(origins) == 20 || error("origin registry must contain 20 rows")
    getfield.(origins, :decision_year) == collect(2005:2024) || error(
        "origin years are not the registered consecutive range",
    )
    all(row.postdecision_year == row.decision_year + 1 for row in origins) || error(
        "postdecision year mismatch",
    )
    length(scenarios) == 30 || error("scenario registry must contain the 5x3x2 cross")
    length(unique(getfield.(scenarios, :scenario_id))) == 30 || error(
        "duplicate scenario identifier",
    )
    length(dockets) == 2 || error("source-docket registry must contain two rows")
    all(row.per_capability_carrier_depth >= 3 for row in dockets) || error(
        "each source docket must register at least three carriers per capability",
    )
    length(capabilities) == 27 || error("capability registry must contain 27 rows")
    length(unique(getfield.(capabilities, :capability_id))) == 27 || error(
        "duplicate capability identifier",
    )
    count(row -> startswith(row.capability_class, "atomic_"), capabilities) == 13 ||
        error("unexpected atomic capability count")
    count(row -> startswith(row.capability_class, "interface_"), capabilities) == 14 ||
        error("unexpected interface capability count")
    registered_capabilities = Set(getfield.(capabilities, :capability_id))
    example = capability_ids_for_spec(
        signal = "momentum_20",
        filter = "always",
        horizon = 5,
        sizing = "unit",
        exit_rule = "horizon",
        risk = "notional_cap_1",
    )
    length(example) == 9 || error("canonical strategy must carry nine capabilities")
    all(in(registered_capabilities), example) || error(
        "canonical strategy maps outside the capability registry",
    )
    length(burdens) == 3 || error("burden registry must contain three schedules")
    count(row -> row.role == "primary", burdens) == 1 || error(
        "burden registry must have one primary schedule",
    )
    length(arms) == 6 || error("arm registry must contain six rows")
    count(row -> row.role == "primary treatment", arms) == 1 || error(
        "arm registry must have one primary treatment",
    )
    count(row -> row.role == "primary comparator", arms) == 1 || error(
        "arm registry must have one primary comparator",
    )
    treatment = only(filter(row -> row.role == "primary treatment", arms))
    comparator = only(filter(row -> row.role == "primary comparator", arms))
    treatment.preserves_frontier && treatment.preserves_closure || error(
        "primary treatment must preserve frontier and closure",
    )
    comparator.preserves_frontier && !comparator.preserves_closure || error(
        "primary comparator must preserve the frontier without a closure constraint",
    )
    length(seeds) == 40 || error("seed registry must contain the full 20x2 grid")
    length(unique((row.origin_id, row.docket_id) for row in seeds)) == 40 || error(
        "duplicate origin-docket seed row",
    )
    all(row.seed_role == "final" for row in seeds) || error("nonfinal seed role")
    all_seeds = vcat(
        getfield.(seeds, :menu_seed),
        getfield.(seeds, :multistart_seed),
        getfield.(seeds, :origin_bootstrap_seed),
    )
    length(unique(all_seeds)) == length(all_seeds) || error("registered seed collision")
    validation_work_units(
        signal_evaluations = 252,
        filter_evaluations = 252,
        risk_updates = 252,
        position_decisions = 52,
        exit_evaluations = 252,
    ) == 6 || error("validation burden formula drift")
    governance_review_units(0) == 11 || error("governance burden lower endpoint drift")
    governance_review_units(6) == 17 || error("governance burden upper endpoint drift")
    return (
        origin_count = length(origins),
        scenario_count = length(scenarios),
        docket_count = length(dockets),
        capability_count = length(capabilities),
        burden_count = length(burdens),
        arm_count = length(arms),
        seed_count = length(seeds),
    )
end

function expected_registry_texts()
    validate_registry_design()
    return Dict(
        joinpath(REGISTRY_ROOT, "ORIGIN_REGISTRY.csv") => _render_csv(origin_rows()),
        joinpath(REGISTRY_ROOT, "SCENARIO_REGISTRY.csv") => _render_csv(scenario_rows()),
        joinpath(REGISTRY_ROOT, "SOURCE_DOCKET_REGISTRY.csv") => _render_csv(docket_rows()),
        joinpath(REGISTRY_ROOT, "CAPABILITY_REGISTRY.csv") => _render_csv(capability_rows()),
        joinpath(REGISTRY_ROOT, "BURDEN_SCHEDULE_REGISTRY.csv") => _render_csv(burden_rows()),
        joinpath(REGISTRY_ROOT, "ARM_REGISTRY.csv") => _render_csv(arm_rows()),
        joinpath(REGISTRY_ROOT, "SEED_REGISTRY.csv") => _render_csv(seed_rows()),
    )
end

function write_registries()
    mkpath(REGISTRY_ROOT)
    for (path, expected) in expected_registry_texts()
        open(path, "w") do io
            write(io, expected)
        end
    end
    println("financial panel v2 registries written")
    return REGISTRY_ROOT
end

function check_registries()
    for (path, expected) in expected_registry_texts()
        isfile(path) || error("missing registered file: $(relpath(path, REPOSITORY_ROOT))")
        read(path, String) == expected || error(
            "registered file is not deterministic generator output: $(relpath(path, REPOSITORY_ROOT))",
        )
    end
    return validate_registry_design()
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: create_financial_strategy_library_panel_v2_registries.jl --write|--check",
    )
    only(args) == "--write" && return write_registries()
    only(args) == "--check" && return println(
        "financial panel v2 registries valid: $(check_registries())",
    )
    error("unknown mode: $(only(args))")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    FinancialStrategyLibraryPanelV2Registries.main()
end
