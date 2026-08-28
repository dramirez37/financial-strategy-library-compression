module FinancialStrategyLibraryPanelV1Registries

using SHA: sha256

export check_registries,
       capability_ids_for_spec,
       expected_registry_texts,
       governance_review_units,
       origin_rows,
       library_rows,
       capability_rows,
       burden_rows,
       seed_rows,
       validation_work_units,
       validate_registry_design,
       write_registries

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const REGISTRY_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v1",
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
        origin_id = "FSLP1-O$year",
        decision_year = year,
        decision_date_rule = "last CRSP trading session on or before December 31",
        construction_start_year = year - 4,
        construction_end_year = year - 2,
        compression_start_year = year - 1,
        compression_end_year = year,
        postdecision_year = year + 1,
        universe_cap = 150,
        minimum_eligible = 20,
        origin_role = "final",
    ) for year in 2005:2024]
end

function library_rows()
    return [
        (
            library_id = "full_factorial_catalog",
            reader_label = "Full factorial research catalog",
            economic_organization = "all valid candidate specifications remain in active maintenance",
            construction_rule = "all 96 registered grammar rows for every origin-eligible PERMNO",
            score_window = "none for membership; construction window estimates belief cutpoints only",
            capability_completion_rule = "not needed after schema validation; reject any missing registered capability",
            tie_rule = "stable PERMNO and grammar order",
            postdecision_information_permitted = false,
        ),
        (
            library_id = "decentralized_signal_sleeves",
            reader_label = "Decentralized signal sleeves",
            economic_organization = "each instrument-signal sleeve maintains local construction-window champions",
            construction_rule = "within each PERMNO and directional signal retain top 2 construction scores with every exact cutoff tie",
            score_window = "construction window only",
            capability_completion_rule = "add every exact best construction-window carrier of each missing registered capability",
            tie_rule = "retain every exact score tie; stable identifier orders output only",
            postdecision_information_permitted = false,
        ),
        (
            library_id = "centralized_research_pool",
            reader_label = "Centralized research pool",
            economic_organization = "a central committee screens globally while preserving predecision productive completeness",
            construction_rule = "retain globally top 2*N_origin construction scores with every exact cutoff tie",
            score_window = "construction window only",
            capability_completion_rule = "add all construction-belief frontier attainers and every exact best carrier of each missing capability",
            tie_rule = "retain every exact score or frontier tie; stable identifier orders output only",
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
            capability_id = "atomic::$class::$value::v1",
            capability_class = "atomic_$class",
            capability_value = value,
            ownership_scope = "active_maintenance_responsibility",
            owner_rule = "every source strategy whose canonical specification contains this exact value",
            artifact_evidence_rule = "canonical_strategy_spec_sha256",
            carrier_multiplicity_rule = "all matching source strategies",
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
            capability_id = "interface::$class::$value::v1",
            capability_class = "interface_$class",
            capability_value = value,
            ownership_scope = "active_maintenance_responsibility",
            owner_rule = "every source strategy whose canonical specification contains this exact registered interface",
            artifact_evidence_rule = "canonical_strategy_spec_sha256",
            carrier_multiplicity_rule = "all matching source strategies",
            closure_role = "primary_identity_union",
        ))
    end
    return rows
end

"""Return the nine registered capabilities carried by one canonical strategy specification."""
function capability_ids_for_spec(;
    signal::AbstractString,
    filter::AbstractString,
    horizon::Integer,
    sizing::AbstractString,
    exit_rule::AbstractString,
    risk::AbstractString,
)
    return [
        "atomic::signal::$signal::v1",
        "atomic::filter::$filter::v1",
        "atomic::horizon::$horizon::v1",
        "atomic::sizing::$sizing::v1",
        "atomic::exit::$exit_rule::v1",
        "atomic::risk::$risk::v1",
        "interface::signal_filter::$signal+$filter::v1",
        "interface::horizon_exit::$horizon+$exit_rule::v1",
        "interface::sizing_risk::$sizing+$risk::v1",
    ]
end

_ceildiv(numerator::Integer, denominator::Integer) = cld(numerator, denominator)

"""Compute the primary exact predecision burden in registered operation-block units."""
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

"""Compute the registered governance checklist burden (11 through 17 units)."""
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
            permitted_inputs = "compression-window valid-session and deterministic operation counts; grammar fields",
            prohibited_inputs = "postdecision returns; future survival; selected identities; savings; solver status; runtime",
            exact_weight_type = "positive integer",
            missing_data_rule = "reject instance",
        ),
        (
            schedule_id = "equal_active_strategy",
            role = "robustness",
            units = "active-maintenance slots",
            formula = "1",
            permitted_inputs = "active versus mandatory-inactive flag",
            prohibited_inputs = "all financial outcomes; capability multiplicity; selected identities; solver or runtime fields",
            exact_weight_type = "positive integer",
            missing_data_rule = "reject missing active or mandatory flag",
        ),
        (
            schedule_id = "governance_review_units",
            role = "robustness",
            units = "registered governance checklist rows",
            formula = "11+count_of_nonbaseline_grammar_fields",
            permitted_inputs = "canonical strategy specification; nine registered capability references; one evidence hash",
            prohibited_inputs = "postdecision returns; future survival; selected identities; savings; solver status; runtime",
            exact_weight_type = "positive integer in 11:17",
            missing_data_rule = "reject missing specification, capability, or hash",
        ),
    ]
end

function seed_rows()
    rows = NamedTuple[]
    for origin in origin_rows(), library in library_rows()
        push!(rows, (
            origin_id = origin.origin_id,
            library_id = library.library_id,
            seed_role = "final",
            multistart_seed = _seed("financial-strategy-library-panel-v1", origin.origin_id, library.library_id, "multistart"),
            origin_bootstrap_seed = _seed("financial-strategy-library-panel-v1", origin.origin_id, library.library_id, "bootstrap"),
        ))
    end
    return rows
end

function validate_registry_design()
    origins = origin_rows()
    libraries = library_rows()
    capabilities = capability_rows()
    burdens = burden_rows()
    seeds = seed_rows()
    length(origins) == 20 || error("origin registry must contain 20 rows")
    getfield.(origins, :decision_year) == collect(2005:2024) || error(
        "origin years are not the registered consecutive range",
    )
    all(row.postdecision_year == row.decision_year + 1 for row in origins) || error(
        "postdecision year mismatch",
    )
    length(libraries) == 3 || error("library registry must contain three constructions")
    length(unique(getfield.(libraries, :library_id))) == 3 || error(
        "duplicate library identifier",
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
    example_capabilities = capability_ids_for_spec(
        signal = "momentum_20",
        filter = "always",
        horizon = 5,
        sizing = "unit",
        exit_rule = "horizon",
        risk = "notional_cap_1",
    )
    length(example_capabilities) == 9 || error("canonical strategy must carry nine capabilities")
    all(in(registered_capabilities), example_capabilities) || error(
        "canonical strategy maps outside the registered capability universe",
    )
    validation_work_units(
        signal_evaluations = 252,
        filter_evaluations = 252,
        risk_updates = 252,
        position_decisions = 52,
        exit_evaluations = 252,
    ) == 6 || error("validation burden formula drift")
    governance_review_units(0) == 11 || error("governance burden lower endpoint drift")
    governance_review_units(6) == 17 || error("governance burden upper endpoint drift")
    length(burdens) == 3 || error("burden registry must contain three schedules")
    count(row -> row.role == "primary", burdens) == 1 || error(
        "burden registry must have one primary schedule",
    )
    length(seeds) == 60 || error("seed registry must contain the full 20x3 grid")
    length(unique((row.origin_id, row.library_id) for row in seeds)) == 60 || error(
        "duplicate origin-library seed row",
    )
    all(row.seed_role == "final" for row in seeds) || error("nonfinal seed role")
    all_seeds = vcat(getfield.(seeds, :multistart_seed), getfield.(seeds, :origin_bootstrap_seed))
    length(unique(all_seeds)) == length(all_seeds) || error("registered seed collision")
    return (
        origin_count = length(origins),
        library_count = length(libraries),
        capability_count = length(capabilities),
        burden_count = length(burdens),
        seed_count = length(seeds),
    )
end

function expected_registry_texts()
    validate_registry_design()
    return Dict(
        joinpath(REGISTRY_ROOT, "ORIGIN_REGISTRY.csv") => _render_csv(origin_rows()),
        joinpath(REGISTRY_ROOT, "LIBRARY_CONSTRUCTION_REGISTRY.csv") => _render_csv(library_rows()),
        joinpath(REGISTRY_ROOT, "CAPABILITY_REGISTRY.csv") => _render_csv(capability_rows()),
        joinpath(REGISTRY_ROOT, "BURDEN_SCHEDULE_REGISTRY.csv") => _render_csv(burden_rows()),
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
    println("financial panel v1 registries written")
    return REGISTRY_ROOT
end

function check_registries()
    for (path, expected) in expected_registry_texts()
        isfile(path) || error("missing registered file: $(relpath(path, REPOSITORY_ROOT))")
        read(path, String) == expected || error(
            "registered file is not the deterministic generator output: $(relpath(path, REPOSITORY_ROOT))",
        )
    end
    return validate_registry_design()
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: create_financial_strategy_library_panel_v1_registries.jl --write|--check",
    )
    only(args) == "--write" && return write_registries()
    only(args) == "--check" && return println(
        "financial panel v1 registries valid: $(check_registries())",
    )
    error("unknown mode: $(only(args))")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    FinancialStrategyLibraryPanelV1Registries.main()
end
