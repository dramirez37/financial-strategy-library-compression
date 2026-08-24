module MultiGapTopologySearch

export bernstein_four_kernel,
    exact_multi_gap_witness,
    main,
    run_topology_audit,
    sign_variations,
    strict_component_count,
    topology_cost_counterexample

const Exact = Rational{BigInt}

exact(value::Integer) = Exact(value, 1)

function bernstein_four_kernel()
    return Exact[
        1 0 0 0 0
        81//256 108//256 54//256 12//256 1//256
        1//16 4//16 6//16 4//16 1//16
        1//256 12//256 54//256 108//256 81//256
        0 0 0 0 1
    ]
end

function apply_kernel(kernel::AbstractMatrix, values::AbstractVector)
    size(kernel, 2) == length(values) ||
        throw(DimensionMismatch("kernel columns must match the value vector"))
    return [
        sum(kernel[row, column] * values[column] for column in axes(kernel, 2)) for
        row in axes(kernel, 1)
    ]
end

function is_row_stochastic(kernel::AbstractMatrix)
    return all(entry >= 0 for entry in kernel) &&
           all(sum(kernel[row, :]) == 1 for row in axes(kernel, 1))
end

function sign_variations(values::AbstractVector)
    nonzero_values = filter(!iszero, values)
    length(nonzero_values) <= 1 && return 0
    return count(
        nonzero_values[index] * nonzero_values[index + 1] < 0 for
        index in firstindex(nonzero_values):(lastindex(nonzero_values) - 1)
    )
end

function strict_component_count(values::AbstractVector, level)
    above = values .> level
    return count(index -> above[index] && (index == firstindex(above) || !above[index - 1]),
        eachindex(above))
end

function tuples(values, length_remaining::Int)
    length_remaining == 0 && return [()]
    tails = tuples(values, length_remaining - 1)
    return [(head, tail...) for head in values for tail in tails]
end

function index_subsets(size::Int, subset_size::Int)
    subsets = Vector{Vector{Int}}()
    for mask in 0:((Int(1) << size) - 1)
        count_ones(mask) == subset_size || continue
        push!(subsets, [index for index in 1:size if !iszero(mask & (Int(1) << (index - 1)))])
    end
    return subsets
end

function exact_determinant(matrix::AbstractMatrix)
    rows, columns = size(matrix)
    rows == columns || throw(DimensionMismatch("determinant requires a square matrix"))
    rows == 0 && return one(eltype(matrix))
    rows == 1 && return matrix[1, 1]
    total = zero(eltype(matrix))
    for column in 1:columns
        remaining_columns = [index for index in 1:columns if index != column]
        cofactor = exact_determinant(matrix[2:end, remaining_columns])
        total += (isodd(column) ? 1 : -1) * matrix[1, column] * cofactor
    end
    return total
end

function total_nonnegative_minor_audit(kernel::AbstractMatrix)
    size(kernel, 1) == size(kernel, 2) ||
        throw(DimensionMismatch("minor audit expects a square matrix"))
    dimension = size(kernel, 1)
    checked = 0
    minimum_minor = one(eltype(kernel))
    for minor_size in 1:dimension
        for rows in index_subsets(dimension, minor_size)
            for columns in index_subsets(dimension, minor_size)
                determinant = exact_determinant(kernel[rows, columns])
                checked += 1
                minimum_minor = min(minimum_minor, determinant)
                determinant >= 0 ||
                    return (all_nonnegative = false, checked = checked, minimum = minimum_minor)
            end
        end
    end
    return (all_nonnegative = true, checked = checked, minimum = minimum_minor)
end

function variation_diminishing_grid_audit(kernel::AbstractMatrix)
    checked = 0
    for raw_values in tuples(-2:2, size(kernel, 2))
        values = exact.(collect(raw_values))
        transformed = apply_kernel(kernel, values)
        checked += 1
        sign_variations(transformed) <= sign_variations(values) ||
            return (
                all_hold = false,
                checked = checked,
                input = values,
                output = transformed,
                input_variations = sign_variations(values),
                output_variations = sign_variations(transformed),
            )
    end
    return (all_hold = true, checked = checked)
end

function superlevel_component_grid_audit(kernel::AbstractMatrix)
    checked = 0
    levels = [Exact(numerator, 2) for numerator in 0:8]
    for raw_values in tuples(0:4, size(kernel, 2))
        values = exact.(collect(raw_values))
        transformed = apply_kernel(kernel, values)
        for level in levels
            input_components = strict_component_count(values, level)
            output_components = strict_component_count(transformed, level)
            checked += 1
            output_components <= input_components ||
                return (
                    all_hold = false,
                    checked = checked,
                    input = values,
                    output = transformed,
                    level = level,
                    input_components = input_components,
                    output_components = output_components,
                )
        end
    end
    return (all_hold = true, checked = checked)
end

function exact_multi_gap_witness()
    kernel = bernstein_four_kernel()
    left_gap = exact.([4, 0, 0, 0, 0])
    right_gap = exact.([0, 0, 0, 0, 4])
    aggregate_gap = left_gap + right_gap
    potential = apply_kernel(kernel, aggregate_gap)
    cost = exact.([1, 1, 1, 1, 1])
    region = potential .> cost
    return (
        id = "CX-MULTIGAP-REGION-01",
        left_gap = left_gap,
        right_gap = right_gap,
        aggregate_gap = aggregate_gap,
        potential = potential,
        cost = cost,
        region = region,
        components = strict_component_count(potential, exact(1)),
        independent_check = potential == Exact[4, 41//32, 1//2, 41//32, 4] &&
                            region == [true, true, false, true, true],
    )
end

function topology_cost_counterexample()
    kernel = bernstein_four_kernel()
    gap = exact.([2, 2, 2, 2, 2])
    potential = apply_kernel(kernel, gap)
    cost = exact.([0, 3, 0, 3, 0])
    region = potential .> cost
    return (
        id = "CX-TOPOLOGY-COST-01",
        gap = gap,
        potential = potential,
        cost = cost,
        region = region,
        gap_positive_components = strict_component_count(gap, exact(0)),
        research_region_components = count(
            index -> region[index] && (index == firstindex(region) || !region[index - 1]),
            eachindex(region),
        ),
        independent_check = potential == gap &&
                            region == [true, false, true, false, true],
    )
end

function json_escape(value::AbstractString)
    return replace(value, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n")
end

rat_string(value::Rational) = "$(numerator(value))//$(denominator(value))"

function write_json(io::IO, value, indent::Int = 0)
    padding = " "^indent
    child_padding = " "^(indent + 2)
    if value isa NamedTuple
        write_json(io, Dict(string(key) => getproperty(value, key) for key in keys(value)), indent)
    elseif value isa AbstractDict
        sorted_keys = sort!(collect(keys(value)); by = string)
        print(io, "{")
        isempty(sorted_keys) || print(io, "\n")
        for (index, key) in enumerate(sorted_keys)
            print(io, child_padding, "\"", json_escape(string(key)), "\": ")
            write_json(io, value[key], indent + 2)
            index == length(sorted_keys) || print(io, ",")
            print(io, "\n")
        end
        isempty(sorted_keys) || print(io, padding)
        print(io, "}")
    elseif value isa AbstractMatrix
        write_json(io, [collect(row) for row in eachrow(value)], indent)
    elseif value isa AbstractVector || value isa Tuple
        print(io, "[")
        isempty(value) || print(io, "\n")
        for (index, item) in enumerate(value)
            print(io, child_padding)
            write_json(io, item, indent + 2)
            index == length(value) || print(io, ",")
            print(io, "\n")
        end
        isempty(value) || print(io, padding)
        print(io, "]")
    elseif value isa AbstractString
        print(io, "\"", json_escape(value), "\"")
    elseif value isa Rational
        print(io, "\"", rat_string(value), "\"")
    elseif value isa Bool
        print(io, value ? "true" : "false")
    elseif value isa Integer
        print(io, value)
    else
        throw(ArgumentError("unsupported JSON value $(typeof(value))"))
    end
end

function write_json_result(path::AbstractString, result)
    mkpath(dirname(path))
    open(path, "w") do io
        write_json(io, result)
        print(io, "\n")
    end
    return path
end

function lean_rational(value::Rational)
    denominator(value) == 1 && return string(numerator(value))
    return "($(numerator(value)) / $(denominator(value)) : ℚ)"
end

lean_vector(values) = "![" * join(lean_rational.(values), ", ") * "]"

function write_lean_fixture(path::AbstractString)
    kernel = bernstein_four_kernel()
    witness = exact_multi_gap_witness()
    topology_cost = topology_cost_counterexample()
    matrix_rows = [lean_vector(row) for row in eachrow(kernel)]
    source = """import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Rat.Defs

namespace StrategyInnovation.Fixtures.MultiGapRegion

/- Exact data generated by julia/scripts/search_multi_gap_topology.jl.
Proofs belong in StrategyInnovation.Counterexamples.MultiGapRegion. -/

def leftCandidateGap : Fin 5 → ℚ := $(lean_vector(witness.left_gap))

def rightCandidateGap : Fin 5 → ℚ := $(lean_vector(witness.right_gap))

def bernsteinKernel : Fin 5 → Fin 5 → ℚ :=
  ![$(join(matrix_rows, ", "))]

def researchCost : Fin 5 → ℚ := $(lean_vector(witness.cost))

def expectedPotential : Fin 5 → ℚ := $(lean_vector(witness.potential))

def topologyConstantGap : Fin 5 → ℚ := $(lean_vector(topology_cost.gap))

def topologyVariableCost : Fin 5 → ℚ := $(lean_vector(topology_cost.cost))

end StrategyInnovation.Fixtures.MultiGapRegion
"""
    mkpath(dirname(path))
    open(path, "w") do io
        print(io, source)
    end
    return path
end

function run_topology_audit()
    kernel = bernstein_four_kernel()
    return Dict(
        "arithmetic" => "Rational{BigInt}",
        "config_file" => "experiments/configs/multi_gap_topology.toml",
        "experiment_id" => "multi-gap-topology-audit-v1",
        "julia_version" => string(VERSION),
        "kernel" => kernel,
        "kernel_interpretation" =>
            "future state is the success count in four Bernoulli signals with p = current_index/4",
        "kernel_row_stochastic" => is_row_stochastic(kernel),
        "multi_gap_witness" => exact_multi_gap_witness(),
        "schema_version" => "multi-gap-topology-v1",
        "superlevel_component_grid_audit" => superlevel_component_grid_audit(kernel),
        "topology_cost_counterexample" => topology_cost_counterexample(),
        "total_nonnegative_minor_audit" => total_nonnegative_minor_audit(kernel),
        "variation_diminishing_grid_audit" => variation_diminishing_grid_audit(kernel),
    )
end

function main()
    result = run_topology_audit()
    repository_root = normpath(joinpath(@__DIR__, "..", ".."))
    result_path = joinpath(
        repository_root,
        "experiments",
        "results",
        "multi_gap_topology.json",
    )
    fixture_path = joinpath(
        repository_root,
        "formal",
        "StrategyInnovation",
        "Fixtures",
        "MultiGapRegion.lean",
    )
    write_json_result(result_path, result)
    write_lean_fixture(fixture_path)
    println("Wrote ", result_path)
    println("Wrote ", fixture_path)
    return result
end

end # module MultiGapTopologySearch

if abspath(PROGRAM_FILE) == @__FILE__
    MultiGapTopologySearch.main()
end
