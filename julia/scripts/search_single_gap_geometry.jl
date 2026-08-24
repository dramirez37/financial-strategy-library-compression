module SingleGapGeometrySearch

export cost_disconnection_witness,
    deterministic_kernel_witness,
    is_quasiconcave,
    is_single_peaked,
    main,
    run_search,
    verify_monotone_threshold_class

const Exact = Rational{BigInt}

exact(value::Integer) = Exact(value, 1)

function is_single_peaked(values::AbstractVector)
    return any(eachindex(values)) do peak
        all(values[index] <= values[index + 1] for index in firstindex(values):(peak - 1)) &&
            all(
                values[index] >= values[index + 1] for
                index in peak:(lastindex(values) - 1)
            )
    end
end

function is_quasiconcave(values::AbstractVector)
    indices = eachindex(values)
    return all(
        min(values[left], values[right]) <= values[middle] for left in indices for
        middle in indices for right in indices if left <= middle <= right
    )
end

function positive_support_connected(values::AbstractVector)
    positive = findall(>(zero(eltype(values))), values)
    isempty(positive) && return true
    return positive == collect(first(positive):last(positive))
end

function has_strict_interior_peak(values::AbstractVector)
    length(values) >= 3 || return false
    maximum(values) > 0 || return false
    peaks = findall(==(maximum(values)), values)
    length(peaks) == 1 || return false
    peak = only(peaks)
    return firstindex(values) < peak < lastindex(values) &&
           values[firstindex(values)] < values[peak] &&
           values[lastindex(values)] < values[peak]
end

function deterministic_expectation(destinations, gap)
    return [gap[destination] for destination in destinations]
end

function is_stochastically_monotone_deterministic(destinations)
    return issorted(destinations)
end

function tuples(values, length_remaining::Int)
    length_remaining == 0 && return [()]
    tails = tuples(values, length_remaining - 1)
    return [(head, tail...) for head in values for tail in tails]
end

function deterministic_kernel_witness(; state_count::Int = 3, value_max::Int = 2)
    state_count >= 3 || throw(ArgumentError("at least three states are required"))
    checked = 0
    for raw_gap in tuples(0:value_max, state_count)
        gap = exact.(collect(raw_gap))
        is_single_peaked(gap) || continue
        positive_support_connected(gap) || continue
        has_strict_interior_peak(gap) || continue
        for destinations in tuples(1:state_count, state_count)
            checked += 1
            potential = deterministic_expectation(destinations, gap)
            if !is_quasiconcave(potential)
                threshold = maximum(
                    min(potential[left], potential[right]) for
                    left in eachindex(potential) for middle in eachindex(potential) for
                    right in eachindex(potential) if left < middle < right &&
                    min(potential[left], potential[right]) > potential[middle]
                )
                region = potential .>= threshold
                return (
                    id = "CX-SG-KERNEL-01",
                    gap = gap,
                    destinations = collect(destinations),
                    potential = potential,
                    threshold = threshold,
                    region = region,
                    gap_single_peaked = is_single_peaked(gap),
                    gap_quasiconcave = is_quasiconcave(gap),
                    gap_interval_support = positive_support_connected(gap),
                    potential_quasiconcave = is_quasiconcave(potential),
                    kernel_stochastically_monotone =
                        is_stochastically_monotone_deterministic(destinations),
                    checked = checked,
                )
            end
        end
    end
    error("no deterministic-kernel counterexample found")
end

function is_upper_region(region::AbstractVector{Bool})
    return all(!region[left] || region[right] for left in eachindex(region) for
               right in eachindex(region) if left <= right)
end

function verify_monotone_threshold_class()
    checks = 0
    for raw_gap in tuples(0:2, 3)
        gap = exact.(collect(raw_gap))
        issorted(gap) || continue
        for destinations in tuples(1:3, 3)
            is_stochastically_monotone_deterministic(destinations) || continue
            expectation = deterministic_expectation(destinations, gap)
            for raw_survival in tuples(0:2, 3)
                survival = exact.(collect(raw_survival))
                issorted(survival) || continue
                for discount in exact.([0, 1, 2])
                    gross = discount .* survival .* expectation
                    issorted(gross) || return (checks = checks, all_hold = false)
                    for raw_cost in tuples(0:3, 3)
                        cost = exact.(collect(raw_cost))
                        issorted(cost; rev = true) || continue
                        checks += 1
                        is_upper_region(gross .>= cost) ||
                            return (checks = checks, all_hold = false)
                    end
                end
            end
        end
    end
    return (checks = checks, all_hold = true)
end

function cost_disconnection_witness(; state_count::Int = 3, cost_max::Int = 3)
    state_count >= 3 || throw(ArgumentError("at least three states are required"))
    potential = exact.(collect(1:state_count))
    checked = 0
    for raw_cost in tuples(0:cost_max, state_count)
        checked += 1
        cost = exact.(collect(raw_cost))
        region = potential .>= cost
        if region[begin] && !region[begin + 1] && region[end]
            return (
                id = "CX-SG-COST-01",
                potential = potential,
                cost = cost,
                region = region,
                potential_monotone = issorted(potential),
                cost_antitone = issorted(cost; rev = true),
                checked = checked,
            )
        end
    end
    error("no cost counterexample found")
end

rat_string(value::Rational) = "$(numerator(value))//$(denominator(value))"

function json_escape(value::AbstractString)
    return replace(value, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n")
end

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

function kernel_matrix(destinations)
    state_count = length(destinations)
    return [exact(destination == column) for destination in destinations, column in 1:state_count]
end

function json_witness(witness)
    return Dict(string(key) => getproperty(witness, key) for key in keys(witness))
end

function run_search()
    kernel = deterministic_kernel_witness()
    cost = cost_disconnection_witness()
    positive_class = verify_monotone_threshold_class()
    return Dict(
        "arithmetic" => "Rational{BigInt}",
        "complete_finite_search_order" => true,
        "config_file" => "experiments/configs/single_gap_geometry.toml",
        "experiment_id" => "single-gap-coverage-region-audit-v1",
        "julia_version" => string(VERSION),
        "schema_version" => "single-gap-geometry-v1",
        "state_count" => 3,
        "stop_after_first_witness" => true,
        "verified_monotone_deterministic_class" => json_witness(positive_class),
        "witnesses" => Dict(
            "cost_disconnection" => json_witness(cost),
            "kernel_destroys_unimodality" => merge(
                json_witness(kernel),
                Dict("kernel" => eachrow(kernel_matrix(kernel.destinations)) .|> collect),
            ),
        ),
    )
end

function write_result(path::AbstractString, result)
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

function write_lean_fixture(path::AbstractString, kernel, cost)
    matrix_rows = [lean_vector(row) for row in eachrow(kernel_matrix(kernel.destinations))]
    source = """import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Rat.Defs

namespace StrategyInnovation.Fixtures.SingleGapGeometry

/- This exact data-only fixture is generated by
`julia/scripts/search_single_gap_geometry.jl`. Proofs belong in
`StrategyInnovation.Coverage.SingleGap`. -/

def peakedGap : Fin 3 → ℚ := $(lean_vector(kernel.gap))

def destructiveKernel : Fin 3 → Fin 3 → ℚ :=
  ![$(join(matrix_rows, ", "))]

def disconnectedPotential : Fin 3 → ℚ := $(lean_vector(kernel.potential))

def increasingPotential : Fin 3 → ℚ := $(lean_vector(cost.potential))

def disconnectedCost : Fin 3 → ℚ := $(lean_vector(cost.cost))

end StrategyInnovation.Fixtures.SingleGapGeometry
"""
    mkpath(dirname(path))
    open(path, "w") do io
        print(io, source)
    end
    return path
end

function main()
    result = run_search()
    kernel = deterministic_kernel_witness()
    cost = cost_disconnection_witness()
    repository_root = normpath(joinpath(@__DIR__, "..", ".."))
    result_path = joinpath(
        repository_root,
        "experiments",
        "results",
        "single_gap_geometry.json",
    )
    fixture_path = joinpath(
        repository_root,
        "formal",
        "StrategyInnovation",
        "Fixtures",
        "SingleGapGeometry.lean",
    )
    write_result(result_path, result)
    write_lean_fixture(fixture_path, kernel, cost)
    println("Wrote ", result_path)
    println("Wrote ", fixture_path)
    return result
end

end # module SingleGapGeometrySearch

if abspath(PROGRAM_FILE) == @__FILE__
    SingleGapGeometrySearch.main()
end
