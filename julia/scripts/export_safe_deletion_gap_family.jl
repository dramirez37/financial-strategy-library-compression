module SafeDeletionGapFamilyFixture

using SHA: sha256
using StrategyInnovation

include(joinpath(@__DIR__, "..", "src", "ResourceOptimization.jl"))
using .ResourceOptimization

export build_safe_deletion_gap_fixture,
       default_output_path,
       render_json,
       write_safe_deletion_gap_fixture

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_OUTPUT = joinpath(
    REPOSITORY_ROOT,
    "journal",
    "aor",
    "fixtures",
    "safe_deletion_gap_family_v1.json",
)
const SCHEMA_VERSION = "safe-deletion-gap-family-v1"

default_output_path() = DEFAULT_OUTPUT
_ratio(value::Rational) = "$(numerator(value))//$(denominator(value))"

function _mask_row(problem::ExactRetentionProblem, mask::UInt64)
    return Dict{String,Any}(
        "mask" => Int(mask),
        "strategies" => library_strategy_ids(problem, mask),
        "burden" => _ratio(library_weight(problem, mask)),
        "frontier" => [_ratio(value) for value in library_frontier(problem, mask)],
        "closure" => library_closure(problem, mask),
    )
end

function _fixture_row(fixture_id::String, k::Int, epsilon)
    family = safe_deletion_gap_problem(k, epsilon)
    problem = family.problem
    source = family.source_mask
    source_frontier = library_frontier(problem, source)
    source_closure = library_module_mask(problem, source)
    safely_deletable_indices = Int[
        index for index in 1:active_strategy_count(problem) if
        safely_deletable(problem, source, index)
    ]
    trace = heaviest_safe_first_trace(problem, source)
    optimum = minimum_weight_safe_compression(problem, source)
    optimum_masks = [library.mask for library in optimum.optimal_libraries]
    alternative = safe_pruning_trace(
        problem,
        source,
        vcat(family.singleton_indices, [family.bundle_index]),
    )
    safe_masks = safe_sublibraries(problem, source)
    approximation_ratio =
        library_weight(problem, trace.endpoint) / optimum.optimal_objective

    all_source_strategies_safe = safely_deletable_indices ==
                                 collect(1:active_strategy_count(problem))
    bundle_unique_heaviest = all_source_strategies_safe &&
                             all(
        problem.weights[index] < problem.weights[family.bundle_index] for
        index in family.singleton_indices
    )
    exact_safe_rows = all(
        mask ->
            safe_feasible(problem, source, mask) ==
            (
                library_frontier(problem, mask) == source_frontier &&
                library_module_mask(problem, mask) == source_closure
            ),
        library_masks(problem),
    )
    trace_steps_rechecked =
        length(trace.masks) == length(trace.deletions) + 1 &&
        all(eachindex(trace.deletions)) do step
            before = trace.masks[step]
            strategy_index = trace.deletions[step]
            bit = UInt64(1) << (strategy_index - 1)
            after = trace.masks[step + 1]
            return safely_deletable(problem, before, strategy_index) &&
                   after == (before & ~bit)
        end
    trace_source_safe = all(
        mask -> safe_feasible(problem, source, mask),
        trace.masks,
    )
    mandatory_inactive_retained = all(
        mask -> first(library_strategy_ids(problem, mask)) == "inactive",
        library_masks(problem),
    )
    gates = Dict{String,Any}(
        "all_source_active_strategies_safely_deletable" =>
            all_source_strategies_safe,
        "bundle_unique_heaviest_safely_deletable" => bundle_unique_heaviest,
        "heaviest_safe_first_deletes_bundle_first" =>
            first(trace.deletions) == family.bundle_index,
        "heaviest_safe_first_stops_after_bundle" =>
            trace.deletions == [family.bundle_index],
        "heaviest_safe_first_steps_exactly_rechecked" => trace_steps_rechecked,
        "heaviest_safe_first_trace_source_safe" => trace_source_safe,
        "endpoint_is_all_singletons" =>
            trace.endpoint == family.singleton_library_mask,
        "endpoint_inclusion_irreducible" =>
            inclusion_irreducible(problem, trace.endpoint),
        "endpoint_burden_equals_k" =>
            library_weight(problem, trace.endpoint) == k,
        "bundle_only_unique_global_optimum" =>
            optimum_masks == [family.bundle_mask],
        "optimum_burden_equals_one_plus_epsilon" =>
            optimum.optimal_objective == 1 + family.epsilon,
        "ratio_equals_k_over_one_plus_epsilon" =>
            approximation_ratio == k / (1 + family.epsilon),
        "singleton_first_trace_reaches_optimum" =>
            alternative.endpoint == family.bundle_mask,
        "frontier_and_closure_rechecked_for_every_mask" => exact_safe_rows,
        "safe_mask_count_matches_family" =>
            length(safe_masks) == (Int(1) << k) + 1,
        "mandatory_inactive_retained" => mandatory_inactive_retained,
    )
    gates["all_gates_pass"] = all(values(gates))

    return Dict{String,Any}(
        "fixture_id" => fixture_id,
        "k" => k,
        "epsilon" => _ratio(family.epsilon),
        "identity_closure" => true,
        "belief_count" => 1,
        "inactive" => Dict(
            "id" => family.inactive_strategy_id,
            "weight" => "0//1",
            "profile" => ["0//1"],
            "modules" => Int[],
            "mandatory" => true,
        ),
        "source" => _mask_row(problem, source),
        "safely_deletable_at_source" => problem.strategy_ids[safely_deletable_indices],
        "unique_heaviest_safely_deletable" =>
            problem.strategy_ids[family.bundle_index],
        "heaviest_safe_first" => Dict(
            "selection_rule" => string(trace.selection_rule),
            "exact_recheck_before_every_deletion" =>
                trace.every_deletion_rechecked,
            "deletions" => problem.strategy_ids[trace.deletions],
            "masks" => Int.(trace.masks),
            "endpoint" => _mask_row(problem, trace.endpoint),
        ),
        "global_optimum" => Dict(
            "algorithm" => "complete submask enumeration",
            "masks" => Int.(optimum_masks),
            "libraries" => [
                _mask_row(problem, mask) for mask in optimum_masks
            ],
            "burden" => _ratio(optimum.optimal_objective),
            "ties_complete" => optimum.certificate.ties_complete,
        ),
        "approximation_ratio" => _ratio(approximation_ratio),
        "ratio_formula" => "k//1 / (1//1 + epsilon)",
        "safe_sublibrary_count" => length(safe_masks),
        "singleton_first_endpoint" => _mask_row(problem, alternative.endpoint),
        "gates" => gates,
    )
end

function build_safe_deletion_gap_fixture()
    specifications = [
        ("GAP-K2-EPS-1-2", 2, 1 // 2),
        ("GAP-K3-EPS-1-2", 3, 1 // 2),
        ("GAP-K4-EPS-1-3", 4, 1 // 3),
        ("GAP-K5-EPS-3-4", 5, 3 // 4),
        ("GAP-K6-EPS-1-5", 6, 1 // 5),
    ]
    fixtures = [
        _fixture_row(fixture_id, k, epsilon) for
        (fixture_id, k, epsilon) in specifications
    ]
    return Dict{String,Any}(
        "schema_version" => SCHEMA_VERSION,
        "arithmetic" => "Rational{BigInt}",
        "evidence_class" =>
            "exact finite Julia computation; not a universal proof and " *
            "not Lean verification",
        "family_assumptions" => Dict(
            "k" => "integer k >= 2",
            "epsilon" => "positive rational with 1 + epsilon < k",
            "closure" => "identity",
            "active_profiles" => "zero at the single declared belief",
            "inactive" => "mandatory, zero burden, zero profile, no modules",
        ),
        "fixtures" => fixtures,
        "gates" => Dict(
            "fixture_count" => length(fixtures),
            "all_fixture_gates_pass" =>
                all(row["gates"]["all_gates_pass"] for row in fixtures),
        ),
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

function write_safe_deletion_gap_fixture(
    ;
    output_path::AbstractString = DEFAULT_OUTPUT,
    check::Bool = false,
)
    fixture = build_safe_deletion_gap_fixture()
    rendered = render_json(fixture)
    if check
        isfile(output_path) || error("missing safe-deletion gap fixture: $output_path")
        read(output_path, String) == rendered ||
            error("safe-deletion gap fixture drift: $output_path")
    else
        mkpath(dirname(output_path))
        open(output_path, "w") do io
            print(io, rendered)
        end
    end
    return (
        fixture = fixture,
        sha256 = bytes2hex(sha256(rendered)),
        output_path = normpath(output_path),
    )
end

function main(args = ARGS)
    check = false
    for argument in args
        argument == "--check" || throw(ArgumentError("unknown argument: $argument"))
        check = true
    end
    result = write_safe_deletion_gap_fixture(; check)
    schema_version = result.fixture["schema_version"]
    all_gates_pass = result.fixture["gates"]["all_fixture_gates_pass"]
    println("schema=$schema_version")
    println("all_fixture_gates_pass=$all_gates_pass")
    println("sha256=$(result.sha256)")
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
