module CreateAlgorithmicCompressionV2Registries

using SHA: sha256

const ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const V1_ROOT = joinpath(ROOT, "experiments", "algorithmic_compression_v1", "registry")
const V2_ROOT = joinpath(ROOT, "experiments", "algorithmic_compression_v2", "registry")
const V1_INSTANCES = joinpath(V1_ROOT, "INSTANCE_REGISTRY.csv")
const V1_SEEDS = joinpath(V1_ROOT, "SEED_REGISTRY.csv")
const V2_INSTANCES = joinpath(V2_ROOT, "INSTANCE_REGISTRY.csv")
const V2_SEEDS = joinpath(V2_ROOT, "SEED_REGISTRY.csv")


function _rows(path)
    lines = readlines(path)
    return only(lines[1:1]), [split(line, ','; keepempty = true) for line in lines[2:end]]
end


function _candidate(label::AbstractString, counter::Int, bits::Int)
    digest = sha256("registered-algorithmic-compression-benchmark-v2\0$label\0$counter")
    value = zero(UInt64)
    bytes = bits == 31 ? @view(digest[1:4]) : @view(digest[1:8])
    for byte in bytes
        value = (value << 8) | UInt64(byte)
    end
    mask = bits == 31 ? UInt64(0x7fffffff) : UInt64(0x7fffffffffffffff)
    return value & mask
end


function _fresh(label, bits, used, forbidden)
    counter = 0
    while true
        value = _candidate(label, counter, bits)
        if value != 0 && value ∉ used && value ∉ forbidden
            push!(used, value)
            return value
        end
        counter += 1
    end
end


function create_registries()
    instance_header, instance_rows = _rows(V1_INSTANCES)
    seed_header, seed_rows = _rows(V1_SEEDS)
    length(instance_rows) == length(seed_rows) || error("v1 registries are not aligned")

    forbidden = Set{UInt64}()
    for row in seed_rows, column in 5:9
        push!(forbidden, parse(UInt64, row[column]))
    end
    used = Set{UInt64}()
    v2_instances = Vector{Vector{String}}()
    v2_seeds = Vector{Vector{String}}()
    for (instance, seed) in zip(instance_rows, seed_rows)
        length(instance) == 22 || error("unexpected v1 instance registry width")
        length(seed) == 10 || error("unexpected v1 seed registry width")
        instance[1] == seed[2] || error("v1 registry identifier mismatch")
        instance[19] == seed[1] || error("v1 registry seed identifier mismatch")
        v2_instance_id = "V2-" * instance[1]
        v2_seed_id = "SEED-V2-" * replace(instance[1], "SEED-" => "")
        instance_copy = copy(instance)
        instance_copy[1] = v2_instance_id
        instance_copy[19] = v2_seed_id
        push!(v2_instances, instance_copy)

        labels = (
            "$(v2_instance_id)/execution-order",
            "$(v2_instance_id)/generator",
            "$(v2_instance_id)/random-order",
            "$(v2_instance_id)/multistart",
            "$(v2_instance_id)/mip",
        )
        values = UInt64[
            _fresh(labels[1], 63, used, forbidden),
            _fresh(labels[2], 63, used, forbidden),
            _fresh(labels[3], 63, used, forbidden),
            _fresh(labels[4], 63, used, forbidden),
            _fresh(labels[5], 31, used, forbidden),
        ]
        push!(v2_seeds, String[
            v2_seed_id,
            v2_instance_id,
            seed[3],
            seed[4],
            string(values[1]),
            string(values[2]),
            string(values[3]),
            string(values[4]),
            string(values[5]),
            seed[10] * ";v2_eight_worker_domain",
        ])
    end

    mkpath(V2_ROOT)
    open(V2_INSTANCES, "w") do io
        println(io, instance_header)
        foreach(row -> println(io, join(row, ',')), v2_instances)
    end
    open(V2_SEEDS, "w") do io
        println(io, seed_header)
        foreach(row -> println(io, join(row, ',')), v2_seeds)
    end
    isempty(intersect(used, forbidden)) || error("v1/v2 seed collision")
    length(used) == 5 * length(v2_seeds) || error("v2 seed collision")
    phase_counts = Dict{String,Int}()
    for row in v2_seeds
        phase_counts[row[3]] = get(phase_counts, row[3], 0) + 1
    end
    println(
        "wrote v2 registries: rows=$(length(v2_seeds)); " *
        "dry=$(get(phase_counts, "dry_run", 0)); " *
        "pilot=$(get(phase_counts, "pilot", 0)); " *
        "final=$(get(phase_counts, "final", 0)); " *
        "v1_seed_intersection=0",
    )
    return true
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    CreateAlgorithmicCompressionV2Registries.create_registries()
end
