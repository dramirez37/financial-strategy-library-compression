module TaggedCoverTheoremFixture

using StrategyInnovation

export build_tagged_cover_theorem_fixture,
       default_output_path,
       render_json,
       write_tagged_cover_theorem_fixture

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_OUTPUT = joinpath(
    REPOSITORY_ROOT,
    "journal",
    "aor",
    "fixtures",
    "tagged_cover_equivalence_v1.json",
)
const SCHEMA_VERSION = "tagged-cover-equivalence-v1"

default_output_path() = DEFAULT_OUTPUT
_ratio(value::Rational) = "$(numerator(value))//$(denominator(value))"
_ratio(value::Integer) = "$(value)//1"
_strategy_id(strategy_id::StrategyId) = String(strategy_id.id)
_module_id(module_id::ModuleId) = String(module_id.id)
_belief_id(belief::Belief) = String(belief.id)

function _module_set(module_ids::Symbol...)
    return ModuleSet(ModuleId{Symbol}[ModuleId(module_id) for module_id in module_ids])
end

function _library(catalog, strategy_ids::Symbol...)
    return RawLibrary(catalog, StrategyId.(collect(strategy_ids)))
end

function _module_ids(catalog, modules)
    return String[
        _module_id(module_row.id) for module_row in catalog.modules if
        module_row.id in modules
    ]
end

function _requirement_record(requirement::FrontierRequirement)
    return Dict(
        "tag" => "frontier",
        "belief" => _belief_id(requirement.belief),
    )
end

function _requirement_record(requirement::ModuleRequirement)
    return Dict(
        "tag" => "module",
        "module" => _module_id(requirement.module_id),
    )
end

function _tag_label(requirement::FrontierRequirement)
    return "frontier:" * _belief_id(requirement.belief)
end

function _tag_label(requirement::ModuleRequirement)
    return "module:" * _module_id(requirement.module_id)
end

function _identity_context()
    beliefs = FiniteBeliefSpace([:shared, :zero])
    modules = [GenerativeModule(:shared), GenerativeModule(:other)]
    strategies = [
        Strategy(
            :inactive,
            OperationalProfile(beliefs, [0, 0]),
            _module_set(),
        ),
        Strategy(
            :alpha,
            OperationalProfile(beliefs, [2, 0]),
            _module_set(:shared),
        ),
        Strategy(
            :beta,
            OperationalProfile(beliefs, [2, -1]),
            _module_set(:shared, :other),
        ),
        Strategy(
            :gamma,
            OperationalProfile(beliefs, [1, 0]),
            _module_set(:other),
        ),
    ]
    catalog = StrategyCatalog(
        beliefs,
        modules,
        strategies,
        StrategyId(:inactive),
    )
    closure = identity_generative_closure(modules)
    source = _library(catalog, :inactive, :alpha, :beta, :gamma)
    weights = Dict(
        StrategyId(:inactive) => 0,
        StrategyId(:alpha) => 3 // 2,
        StrategyId(:beta) => 7 // 3,
        StrategyId(:gamma) => 5 // 4,
    )
    representation = tagged_cover_representation(
        catalog,
        closure,
        source;
        strategy_weights = weights,
    )
    return (; catalog, closure, source, representation)
end

function _candidate_rows(context)
    representation = context.representation
    rows = Dict{String,Any}[]
    active_ids = (:alpha, :beta, :gamma)
    for mask in 0:7
        selected_active = Symbol[
            strategy_id for (index, strategy_id) in enumerate(active_ids) if
            !iszero(mask & (1 << (index - 1)))
        ]
        candidate = _library(context.catalog, :inactive, selected_active...)
        certificate = tagged_cover_certificate(representation, candidate)
        push!(
            rows,
            Dict(
                "mask" => mask,
                "selected_strategies" => [
                    _strategy_id(strategy_id) for strategy_id in candidate
                ],
                "frontier_preserved" => certificate.frontier_preserved,
                "closure_preserved" => certificate.closure_preserved,
                "inactive_retained" => certificate.inactive_retained,
                "exact_safe_feasible" => certificate.exact_safe_feasible,
                "tagged_cover_feasible" => certificate.tagged_cover_feasible,
                "equivalence_holds" => certificate.equivalence_holds,
                "exact_burden" => _ratio(certificate.exact_burden),
            ),
        )
    end
    return rows
end

function _exhaustive_small_library_audit()
    beliefs = FiniteBeliefSpace([:b1, :b2])
    modules = [GenerativeModule(:m1), GenerativeModule(:m2)]
    closure = identity_generative_closure(modules)
    profile_options = collect(Iterators.product((-1, 0, 1), (-1, 0, 1)))
    catalogs_checked = 0
    sublibraries_checked = 0
    mismatches = Dict{String,Any}[]

    for first_profile in profile_options,
        second_profile in profile_options,
        first_mask in 0:3,
        second_mask in 0:3
        first_modules = _module_set(
            (module_id for (index, module_id) in enumerate((:m1, :m2)) if
             !iszero(first_mask & (1 << (index - 1))))...,
        )
        second_modules = _module_set(
            (module_id for (index, module_id) in enumerate((:m1, :m2)) if
             !iszero(second_mask & (1 << (index - 1))))...,
        )
        catalog = StrategyCatalog(
            beliefs,
            modules,
            [
                Strategy(
                    :inactive,
                    OperationalProfile(beliefs, [0, 0]),
                    _module_set(),
                ),
                Strategy(
                    :s1,
                    OperationalProfile(beliefs, collect(first_profile)),
                    first_modules,
                ),
                Strategy(
                    :s2,
                    OperationalProfile(beliefs, collect(second_profile)),
                    second_modules,
                ),
            ],
            StrategyId(:inactive),
        )
        source = _library(catalog, :inactive, :s1, :s2)
        representation = tagged_cover_representation(catalog, closure, source)
        for candidate_mask in 0:3
            selected_active = Symbol[
                strategy_id for (index, strategy_id) in enumerate((:s1, :s2)) if
                !iszero(candidate_mask & (1 << (index - 1)))
            ]
            candidate = _library(catalog, :inactive, selected_active...)
            exact_feasible =
                compressed_state(catalog, closure, candidate) ==
                compressed_state(catalog, closure, source)
            cover_feasible = tagged_cover_feasible(representation, candidate)
            if exact_feasible != cover_feasible
                push!(
                    mismatches,
                    Dict(
                        "first_profile" => collect(first_profile),
                        "second_profile" => collect(second_profile),
                        "first_module_mask" => first_mask,
                        "second_module_mask" => second_mask,
                        "candidate_mask" => candidate_mask,
                        "exact_safe_feasible" => exact_feasible,
                        "tagged_cover_feasible" => cover_feasible,
                    ),
                )
            end
            sublibraries_checked += 1
        end
        catalogs_checked += 1
    end
    return Dict(
        "profile_value_grid" => [-1, 0, 1],
        "belief_count" => 2,
        "module_count" => 2,
        "active_strategy_count" => 2,
        "catalogs_checked" => catalogs_checked,
        "sublibraries_checked" => sublibraries_checked,
        "mismatch_count" => length(mismatches),
        "mismatches" => mismatches,
        "all_correspondences_hold" => isempty(mismatches),
    )
end

function _frontier_rows_only_counterexample()
    beliefs = FiniteBeliefSpace([:only])
    modules = [GenerativeModule(:m)]
    catalog = StrategyCatalog(
        beliefs,
        modules,
        [
            Strategy(:inactive, OperationalProfile(beliefs, [0]), _module_set()),
            Strategy(:carrier, OperationalProfile(beliefs, [0]), _module_set(:m)),
        ],
        StrategyId(:inactive),
    )
    closure = identity_generative_closure(modules)
    source = _library(catalog, :inactive, :carrier)
    candidate = _library(catalog, :inactive)
    frontier_equal = frontier(catalog, candidate) == frontier(catalog, source)
    closure_equal = generative_closure(catalog, closure, candidate) ==
                    generative_closure(catalog, closure, source)
    return Dict(
        "counterexample_id" => "CX-TAG-FRONTIER-ONLY-01",
        "closure" => "identity",
        "source_strategies" => [_strategy_id(strategy_id) for strategy_id in source],
        "candidate_strategies" => [
            _strategy_id(strategy_id) for strategy_id in candidate
        ],
        "source_frontier" => [_ratio(value) for value in frontier(catalog, source).values],
        "candidate_frontier" => [
            _ratio(value) for value in frontier(catalog, candidate).values
        ],
        "source_closure" => _module_ids(
            catalog,
            generative_closure(catalog, closure, source),
        ),
        "candidate_closure" => _module_ids(
            catalog,
            generative_closure(catalog, closure, candidate),
        ),
        "frontier_rows_feasible" => frontier_equal,
        "exact_safe_feasible" => frontier_equal && closure_equal,
    )
end

function _module_rows_only_counterexample()
    beliefs = FiniteBeliefSpace([:only])
    modules = [GenerativeModule(:m)]
    catalog = StrategyCatalog(
        beliefs,
        modules,
        [
            Strategy(:inactive, OperationalProfile(beliefs, [0]), _module_set()),
            Strategy(:leader, OperationalProfile(beliefs, [1]), _module_set()),
        ],
        StrategyId(:inactive),
    )
    closure = identity_generative_closure(modules)
    source = _library(catalog, :inactive, :leader)
    candidate = _library(catalog, :inactive)
    frontier_equal = frontier(catalog, candidate) == frontier(catalog, source)
    closure_equal = generative_closure(catalog, closure, candidate) ==
                    generative_closure(catalog, closure, source)
    return Dict(
        "counterexample_id" => "CX-TAG-MODULE-ONLY-01",
        "closure" => "identity",
        "source_strategies" => [_strategy_id(strategy_id) for strategy_id in source],
        "candidate_strategies" => [
            _strategy_id(strategy_id) for strategy_id in candidate
        ],
        "source_frontier" => [_ratio(value) for value in frontier(catalog, source).values],
        "candidate_frontier" => [
            _ratio(value) for value in frontier(catalog, candidate).values
        ],
        "source_closure" => _module_ids(
            catalog,
            generative_closure(catalog, closure, source),
        ),
        "candidate_closure" => _module_ids(
            catalog,
            generative_closure(catalog, closure, candidate),
        ),
        "module_rows_feasible" => closure_equal,
        "exact_safe_feasible" => frontier_equal && closure_equal,
    )
end

function _closure_complementarity_counterexample()
    beliefs = FiniteBeliefSpace([:only])
    modules = GenerativeModule.(collect((:a, :b, :c)))
    universe = ModuleSet(modules)
    closure = GenerativeClosure(
        modules,
        raw_modules -> begin
            has_pair =
                ModuleId(:a) in raw_modules && ModuleId(:b) in raw_modules
            return has_pair ? universe : raw_modules
        end,
    )
    catalog = StrategyCatalog(
        beliefs,
        modules,
        [
            Strategy(:inactive, OperationalProfile(beliefs, [0]), _module_set()),
            Strategy(:a_carrier, OperationalProfile(beliefs, [0]), _module_set(:a)),
            Strategy(:b_carrier, OperationalProfile(beliefs, [0]), _module_set(:b)),
            Strategy(:c_carrier, OperationalProfile(beliefs, [0]), _module_set(:c)),
        ],
        StrategyId(:inactive),
    )
    source = _library(catalog, :inactive, :a_carrier, :b_carrier)
    candidate = source
    source_closure = generative_closure(catalog, closure, source)
    candidate_closure = generative_closure(catalog, closure, candidate)
    closed_module_raw_carriers = Dict(
        _module_id(module_id) => String[
            _strategy_id(strategy_id) for strategy_id in source if
            module_id in strategy_modules(catalog, strategy_id)
        ] for module_id in source_closure
    )
    naive_rows_feasible = all(
        !isempty(closed_module_raw_carriers[_module_id(module_id)]) for
        module_id in source_closure
    )
    adapter_rejected = try
        tagged_cover_representation(catalog, closure, source)
        false
    catch error
        error isa ArgumentError
    end
    return Dict(
        "counterexample_id" => "CX-TAG-CLOSURE-COMPLEMENTARITY-01",
        "closure_rule" => "close({a,b})={a,b,c}; otherwise identity, extended monotonically",
        "source_strategies" => [_strategy_id(strategy_id) for strategy_id in source],
        "candidate_strategies" => [
            _strategy_id(strategy_id) for strategy_id in candidate
        ],
        "source_raw_modules" => _module_ids(catalog, raw_module_union(catalog, source)),
        "source_closure" => _module_ids(catalog, source_closure),
        "candidate_closure" => _module_ids(catalog, candidate_closure),
        "raw_carriers_by_closed_module" => closed_module_raw_carriers,
        "exact_safe_feasible" =>
            compressed_state(catalog, closure, candidate) ==
            compressed_state(catalog, closure, source),
        "naive_independent_closed_module_rows_feasible" => naive_rows_feasible,
        "identity_only_adapter_rejected_nonidentity_closure" => adapter_rejected,
    )
end

function build_tagged_cover_theorem_fixture()
    context = _identity_context()
    representation = context.representation
    candidate_rows = _candidate_rows(context)
    exhaustive_audit = _exhaustive_small_library_audit()
    frontier_counterexample = _frontier_rows_only_counterexample()
    module_counterexample = _module_rows_only_counterexample()
    complementarity_counterexample = _closure_complementarity_counterexample()
    source_frontier = frontier(context.catalog, context.source)
    source_closure = generative_closure(
        context.catalog,
        context.closure,
        context.source,
    )

    all_candidate_rows_agree = all(row["equivalence_holds"] for row in candidate_rows)
    gates = Dict(
        "all_representative_sublibraries_checked" => length(candidate_rows) == 8,
        "all_representative_correspondences_hold" => all_candidate_rows_agree,
        "all_exhaustive_small_correspondences_hold" =>
            exhaustive_audit["all_correspondences_hold"],
        "frontier_rows_alone_rejected" =>
            frontier_counterexample["frontier_rows_feasible"] &&
            !frontier_counterexample["exact_safe_feasible"],
        "module_rows_alone_rejected" =>
            module_counterexample["module_rows_feasible"] &&
            !module_counterexample["exact_safe_feasible"],
        "general_closure_raw_rows_rejected" =>
            complementarity_counterexample["exact_safe_feasible"] &&
            !complementarity_counterexample[
                "naive_independent_closed_module_rows_feasible"
            ] &&
            complementarity_counterexample[
                "identity_only_adapter_rejected_nonidentity_closure"
            ],
    )
    gates["all_gates_pass"] = all(values(gates))

    return Dict(
        "schema_version" => SCHEMA_VERSION,
        "theorem_id" => "SC-TAG",
        "arithmetic" => "Rational{BigInt}",
        "evidence_class" =>
            "exact finite computation; not a universal mathematical proof or solver certificate",
        "scope" => Dict(
            "closure" => "identity",
            "candidate_domain" => "inactive-containing source sublibraries",
            "frontier_rows" => "all declared beliefs, including zero-frontier beliefs",
            "module_rows" => "all modules in the source identity closure",
        ),
        "representative_instance" => Dict(
            "beliefs" => [_belief_id(belief) for belief in context.catalog.beliefs],
            "modules" => [
                _module_id(module_row.id) for module_row in context.catalog.modules
            ],
            "source_strategies" => [
                _strategy_id(strategy_id) for strategy_id in context.source
            ],
            "inactive_strategy" => "inactive",
            "source_frontier" => [_ratio(value) for value in source_frontier.values],
            "source_closure" => _module_ids(context.catalog, source_closure),
            "requirements" => [
                _requirement_record(requirement) for
                requirement in representation.requirements
            ],
            "incidence_rows" => [
                Dict(
                    "requirement" => _tag_label(requirement),
                    "covered_by" => String[
                        _strategy_id(representation.strategy_ids[column]) for
                        column in axes(representation.coverage, 2) if
                        representation.coverage[row, column]
                    ],
                ) for (row, requirement) in enumerate(representation.requirements)
            ],
            "weights" => Dict(
                _strategy_id(strategy_id) => _ratio(representation.weights[index]) for
                (index, strategy_id) in enumerate(representation.strategy_ids)
            ),
            "binary_formulation" => Dict(
                "objective" => "min sum_s w_s x_s",
                "row_constraints" => "sum_s incidence[u,s] x_s >= 1 for every tagged row u",
                "inactive_constraint" => "x_inactive = 1",
                "domain" => "x_s in {0,1} for source strategies",
            ),
            "tie_frontier_attainers_at_shared" => ["alpha", "beta"],
            "zero_frontier_belief" => "zero",
            "inactive_covers_zero_frontier" => true,
            "multiple_carriers" => Dict(
                "shared" => ["alpha", "beta"],
                "other" => ["beta", "gamma"],
            ),
            "candidate_rows" => candidate_rows,
        ),
        "exhaustive_small_library_audit" => exhaustive_audit,
        "counterexamples" => [
            frontier_counterexample,
            module_counterexample,
            complementarity_counterexample,
        ],
        "gates" => gates,
    )
end

function _json_escape(value::AbstractString)
    return replace(
        value,
        "\\" => "\\\\",
        "\"" => "\\\"",
        "\n" => "\\n",
        "\r" => "\\r",
        "\t" => "\\t",
    )
end

function _write_json(io::IO, value, indent::Int = 0)
    padding = " "^indent
    child_padding = " "^(indent + 2)
    if value isa AbstractDict
        keys_sorted = sort!(collect(keys(value)); by = string)
        print(io, "{")
        if !isempty(keys_sorted)
            print(io, "\n")
            for (index, key) in enumerate(keys_sorted)
                print(io, child_padding, "\"", _json_escape(string(key)), "\": ")
                _write_json(io, value[key], indent + 2)
                index == length(keys_sorted) || print(io, ",")
                print(io, "\n")
            end
            print(io, padding)
        end
        print(io, "}")
    elseif value isa AbstractVector || value isa Tuple
        print(io, "[")
        if !isempty(value)
            print(io, "\n")
            for (index, item) in enumerate(value)
                print(io, child_padding)
                _write_json(io, item, indent + 2)
                index == length(value) || print(io, ",")
                print(io, "\n")
            end
            print(io, padding)
        end
        print(io, "]")
    elseif value isa AbstractString
        print(io, "\"", _json_escape(value), "\"")
    elseif value isa Bool
        print(io, value ? "true" : "false")
    elseif value === nothing
        print(io, "null")
    elseif value isa Integer
        print(io, value)
    elseif value isa Rational
        print(io, "\"", _ratio(value), "\"")
    else
        throw(ArgumentError("unsupported JSON value $(typeof(value))"))
    end
end

function render_json(value)
    return sprint() do io
        _write_json(io, value)
        print(io, "\n")
    end
end

function write_tagged_cover_theorem_fixture(
    path::AbstractString = default_output_path();
    check::Bool = false,
)
    fixture = build_tagged_cover_theorem_fixture()
    fixture["gates"]["all_gates_pass"] || error(
        "tagged-cover theorem fixture failed one or more exact gates",
    )
    rendered = render_json(fixture)
    if check
        isfile(path) || error("tagged-cover fixture is absent: $path")
        read(path, String) == rendered || error(
            "tagged-cover fixture differs from exact regeneration: $path",
        )
    else
        mkpath(dirname(path))
        open(path, "w") do io
            write(io, rendered)
        end
    end
    return (; fixture, path, check)
end

function _main(args)
    length(args) <= 1 || error("usage: export_tagged_cover_theorem_fixture.jl [--check]")
    check = !isempty(args) && only(args) == "--check"
    result = write_tagged_cover_theorem_fixture(; check)
    println(
        check ? "verified " : "wrote ",
        relpath(result.path, REPOSITORY_ROOT),
    )
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    TaggedCoverTheoremFixture._main(ARGS)
end
