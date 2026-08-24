module SafeCompressionComplexityReductionFixture

using SHA: sha256
using StrategyInnovation

include(joinpath(@__DIR__, "..", "src", "SafeCompressionComplexity.jl"))
using .SafeCompressionComplexity

export build_complexity_reduction_fixture,
       default_output_path,
       render_json,
       write_complexity_reduction_fixture

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_OUTPUT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "results",
    "safe_compression_complexity_reduction_fixture.json",
)
const SCHEMA_VERSION = "safe-compression-complexity-reduction-v1"

default_output_path() = DEFAULT_OUTPUT
_ratio(value::Rational) = "$(numerator(value))//$(denominator(value))"
_ratio(value::Integer) = "$(value)//1"

function _selected_ids(instance::WeightedSetCoverInstance, mask::UInt64)
    return String[
        instance.set_ids[index] for index in eachindex(instance.set_ids) if
        !iszero(mask & (UInt64(1) << (index - 1)))
    ]
end

function _set_rows(instance::WeightedSetCoverInstance)
    return [
        Dict(
            "id" => instance.set_ids[index],
            "weight" => _ratio(instance.weights[index]),
            "elements" => String[
                instance.element_ids[element_index] for
                element_index in eachindex(instance.element_ids) if
                !iszero(
                    instance.set_masks[index] &
                    (UInt64(1) << (element_index - 1)),
                )
            ],
        ) for index in eachindex(instance.set_ids)
    ]
end

function _candidate_rows(
    instance::WeightedSetCoverInstance,
    reduction,
)
    problem = reduction.problem
    cover = reduction.identity_cover
    return [
        Dict(
            "mask" => Int(mask),
            "selected_sets" => _selected_ids(instance, mask),
            "weight" => _ratio(set_cover_weight(instance, mask)),
            "set_cover_feasible" => set_cover_feasible(instance, mask),
            "safe_compression_feasible" =>
                safe_feasible(problem, reduction.source_mask, mask),
            "combined_obligation_cover_feasible" =>
                covers_identity_obligations(cover, mask),
        ) for mask in UInt64(0):reduction.source_mask
    ]
end

function _reduction_row(
    instance::WeightedSetCoverInstance,
    reduction,
)
    problem = reduction.problem
    cover = reduction.identity_cover
    return Dict(
        "mode" => String(reduction.mode),
        "belief_count" => size(problem.profiles, 2),
        "module_count" => problem.module_count,
        "source_frontier" => [
            _ratio(value) for value in
            library_frontier(problem, reduction.source_mask)
        ],
        "source_module_mask" =>
            Int(library_module_mask(problem, reduction.source_mask)),
        "obligation_labels" => cover.obligation_labels,
        "policy_obligation_masks" => [
            Int(mask) for mask in cover.policy_obligation_masks
        ],
        "correspondence_for_every_mask" => reduction.correspondence,
        "weight_preserved_for_every_mask" => reduction.weight_preservation,
        "optimizer_correspondence" => reduction.optimizer_correspondence,
        "optimal_masks" => [Int(mask) for mask in reduction.safe_optima],
        "optimal_selected_sets" => [
            _selected_ids(instance, mask) for mask in reduction.safe_optima
        ],
        "minimum_weight" =>
            _ratio(library_weight(problem, only(reduction.safe_optima))),
        "candidate_rows" => _candidate_rows(instance, reduction),
    )
end

function build_complexity_reduction_fixture()
    instance = WeightedSetCoverInstance(
        ["e1", "e2", "e3"],
        ["A", "B", "C", "D"],
        [3, 2, 1, 4],
        UInt64[0x03, 0x06, 0x01, 0x04],
    )
    reductions = [
        reduction_correspondence(instance, :closure_only),
        reduction_correspondence(instance, :frontier_only),
        reduction_correspondence(instance, :combined),
    ]
    all_gates = all(
        reduction.correspondence &&
        reduction.weight_preservation &&
        reduction.optimizer_correspondence for reduction in reductions
    )
    return Dict(
        "schema_version" => SCHEMA_VERSION,
        "arithmetic" => "Rational{BigInt}",
        "evidence_class" =>
            "exact finite executable reduction fixture; not a complexity proof",
        "source_problem" => Dict(
            "problem" => "weighted set cover",
            "elements" => instance.element_ids,
            "sets" => _set_rows(instance),
            "source_mask" => Int(set_cover_source_mask(instance)),
            "optimal_masks" => [
                Int(mask) for mask in set_cover_optimal_masks(instance)
            ],
            "optimal_selected_sets" => [
                _selected_ids(instance, mask) for
                mask in set_cover_optimal_masks(instance)
            ],
        ),
        "reductions" => [
            _reduction_row(instance, reduction) for reduction in reductions
        ],
        "gates" => Dict(
            "all_candidate_masks_checked" => true,
            "all_feasibility_correspondences_hold" => all(
                reduction.correspondence for reduction in reductions
            ),
            "all_weights_preserved" => all(
                reduction.weight_preservation for reduction in reductions
            ),
            "all_optimizer_sets_preserved" => all(
                reduction.optimizer_correspondence for reduction in reductions
            ),
            "all_gates_pass" => all_gates,
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

function write_complexity_reduction_fixture(
    ;
    output_path::AbstractString = DEFAULT_OUTPUT,
    check::Bool = false,
)
    fixture = build_complexity_reduction_fixture()
    rendered = render_json(fixture)
    if check
        isfile(output_path) ||
            error("missing safe-compression complexity fixture: $output_path")
        read(output_path, String) == rendered ||
            error("safe-compression complexity fixture drift: $output_path")
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
        if argument == "--check"
            check = true
        else
            throw(ArgumentError("unknown argument: $argument"))
        end
    end
    result = write_complexity_reduction_fixture(; check)
    println("schema=$(result.fixture["schema_version"])")
    println("all_gates_pass=$(result.fixture["gates"]["all_gates_pass"])")
    println("sha256=$(result.sha256)")
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
