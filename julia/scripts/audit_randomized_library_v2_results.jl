using SHA

const REPO = normpath(joinpath(@__DIR__, "..", ".."))
const RESULTS = joinpath(REPO, "experiments", "results", "summaries")

function csv_fields(line::AbstractString)
    fields = String[]
    buffer = IOBuffer()
    quoted = false
    index = firstindex(line)
    while index <= lastindex(line)
        character = line[index]
        if character == '"'
            next_index = nextind(line, index)
            if quoted && next_index <= lastindex(line) && line[next_index] == '"'
                write(buffer, '"')
                index = next_index
            else
                quoted = !quoted
            end
        elseif character == ',' && !quoted
            push!(fields, String(take!(buffer)))
        else
            write(buffer, character)
        end
        index = nextind(line, index)
    end
    quoted && error("unterminated CSV quote")
    push!(fields, String(take!(buffer)))
    return fields
end

function read_csv(name::AbstractString)
    path = joinpath(RESULTS, name)
    lines = readlines(path)
    isempty(lines) && error("empty CSV: $path")
    header = csv_fields(first(lines))
    rows = Vector{Dict{String, String}}(undef, length(lines) - 1)
    for (row_index, line) in enumerate(Iterators.drop(lines, 1))
        fields = csv_fields(line)
        length(fields) == length(header) ||
            error("CSV width mismatch in $name row $(row_index + 1)")
        rows[row_index] = Dict(zip(header, fields))
    end
    return rows
end

function parse_exact(text::AbstractString)
    parts = split(text, "//"; limit = 2)
    length(parts) == 2 ||
        error("expected serialized Rational{BigInt}, received: $text")
    return parse(BigInt, parts[1]) // parse(BigInt, parts[2])
end

function sha256_file(path::AbstractString)
    return bytes2hex(open(SHA.sha256, path))
end

function require_all(rows, column::AbstractString, expected::AbstractString)
    all(row -> row[column] == expected, rows) ||
        error("column $column does not equal $expected on every row")
end

function frequencies(values)
    counts = Dict{eltype(values), Int}()
    for value in values
        counts[value] = get(counts, value, 0) + 1
    end
    return counts
end

const EXPECTED_ROWS = Dict(
    "randomized_library_v2_trials.csv" => 1024,
    "randomized_library_v2_rectangle_corners.csv" => 4096,
    "randomized_library_v2_rectangle_transitions.csv" => 150882,
    "randomized_library_v2_pruning.csv" => 4096,
    "randomized_library_v2_assets.csv" => 5120,
    "randomized_library_v2_actions.csv" => 135678,
    "randomized_library_v2_profiles.csv" => 24576,
    "randomized_library_v2_modules.csv" => 57344,
    "randomized_library_v2_closures.csv" => 131072,
    "randomized_library_v2_kernels.csv" => 9216,
    "randomized_library_v2_projects.csv" => 8192,
    "randomized_library_v2_raw_witness_manifest.csv" => 47458,
    "randomized_library_v2_method_summary.csv" => 4,
    "randomized_library_v2_factor_summary.csv" => 14,
    "randomized_library_v2_relationship_summary.csv" => 10,
    "randomized_library_v2_stability_summary.csv" => 64,
    "randomized_library_v2_stability_factor_summary.csv" => 896,
    "randomized_library_v2_interaction_signs.csv" => 51,
)

for (name, expected) in EXPECTED_ROWS
    actual = countlines(joinpath(RESULTS, name)) - 1
    actual == expected ||
        error("$name has $actual data rows; expected $expected")
end

trials = read_csv("randomized_library_v2_trials.csv")
parse.(Int, getindex.(trials, "trial_id")) == collect(1:1024) ||
    error("trial IDs are not the registered complete sequence")
require_all(trials, "arithmetic", "Rational{BigInt}")
require_all(trials, "theorem_evidence", "false")
for gate in (
    "four_raw_witnesses",
    "all_compressed_states_have_raw_witnesses",
    "raw_compressed_values_agree",
    "rectangle_consistency",
    "project_laws_follow_actual_state",
    "frontier_only_passive_zero_gate",
    "innovation_safe_exact_zero_gate",
    "all_decompositions_exact",
    "all_exact_outputs_rational",
    "all_hard_gates_pass",
)
    require_all(trials, gate, "true")
end
for column in (
    "source_passive_value",
    "source_research_option_premium",
    "source_total_value",
    "frontier_only_signed_total_dynamic_loss",
    "innovation_safe_signed_total_dynamic_loss",
    "frontier_closure_J",
    "frontier_only_compression_ratio",
    "innovation_safe_compression_ratio",
)
    parse_exact.(getindex.(trials, column))
end

frontier_losses =
    parse_exact.(getindex.(trials, "frontier_only_signed_total_dynamic_loss"))
safe_losses =
    parse_exact.(getindex.(trials, "innovation_safe_signed_total_dynamic_loss"))
interactions = parse_exact.(getindex.(trials, "frontier_closure_J"))
signs = getindex.(trials, "interaction_sign")
predicates = getindex.(trials, "computed_primitive_predicate") .== "true"
count(>(0), frontier_losses) == 398 ||
    error("frontier-positive count does not reconcile")
all(iszero, safe_losses) || error("innovation-safe trial loss is nonzero")
count(<(0), interactions) == 256 || error("substitution count does not reconcile")
count(>(0), interactions) == 141 || error("complementarity count does not reconcile")
count(iszero, interactions) == 627 || error("zero-interaction count does not reconcile")
all(
    (value < 0 && sign == "substitution") ||
    (value > 0 && sign == "complementarity") ||
    (iszero(value) && sign == "zero") for (value, sign) in zip(interactions, signs)
) || error("interaction signs do not match exact J values")
count(predicates) == 512 || error("mechanical primitive predicate is not 512/512")
all(interactions[predicates] .<= 0) ||
    error("a mechanically eligible interaction is positive")
for factor in (
    "frontier_density",
    "module_overlap",
    "module_complementarity",
    "project_cost",
    "duration",
    "admission",
    "persistence",
)
    counts = sort(collect(values(frequencies(getindex.(trials, factor)))))
    counts == [512, 512] || error("$factor is not balanced 512/512")
end

corners = read_csv("randomized_library_v2_rectangle_corners.csv")
for gate in (
    "raw_library_valid",
    "shared_catalog",
    "shared_closure",
    "raw_compressed_value_gate",
)
    require_all(corners, gate, "true")
end
corner_counts = frequencies(parse.(Int, getindex.(corners, "trial_id")))
all(get(corner_counts, trial_id, 0) == 4 for trial_id in 1:1024) ||
    error("a rectangle does not have exactly four raw corners")

witnesses = read_csv("randomized_library_v2_raw_witness_manifest.csv")
require_all(witnesses, "witness_valid", "true")
witness_counts = frequencies(parse.(Int, getindex.(witnesses, "trial_id")))
all(get(witness_counts, trial_id, 0) > 0 for trial_id in 1:1024) ||
    error("a compressed state has no recorded raw witness")

pruning = read_csv("randomized_library_v2_pruning.csv")
require_all(pruning, "decomposition_gate", "true")
for row in pruning
    operational = parse_exact(row["signed_operational_loss"])
    generative = parse_exact(row["signed_generative_loss"])
    total = parse_exact(row["signed_total_dynamic_loss"])
    operational + generative == total ||
        error("signed decomposition fails on trial $(row["trial_id"])")
    if row["method"] == "innovation_safe"
        parse_exact(row["frontier_loss"]) == 0 ||
            error("innovation-safe frontier loss is nonzero")
        parse(Int, row["closure_loss_count"]) == 0 ||
            error("innovation-safe closure loss is nonzero")
        operational == 0 ||
            error("innovation-safe operational loss is nonzero")
        generative == 0 ||
            error("innovation-safe generative loss is nonzero")
        total == 0 || error("innovation-safe total loss is nonzero")
    elseif row["method"] == "frontier_only"
        operational == 0 ||
            error("frontier-only operational loss is nonzero")
    end
end

stability = read_csv("randomized_library_v2_stability_summary.csv")
final_rows = filter(
    row -> row["scope"] == "cumulative" && row["prefix_n"] == "1024",
    stability,
)
final_counts = Dict(
    row["estimand"] => parse(Int, row["event_count"]) for row in final_rows
)
for (estimand, expected) in (
    "frontier_positive_loss_frequency" => 398,
    "innovation_safe_loss_frequency" => 0,
    "silent_generative_asset_frequency" => 388,
    "substitution_frequency" => 256,
    "complementarity_frequency" => 141,
)
    get(final_counts, estimand, -1) == expected ||
        error("final stability count for $estimand does not reconcile")
end

pilot_hashes = Dict(
    "experiments/configs/randomized_library_stress.toml" =>
        "aa3c04898123b50546dcbf142bd91bbd9da9f926b71ae910e6819b9f5ad31794",
    "experiments/results/summaries/randomized_library_summary.json" =>
        "82340ff1a92219cd653f8741996a615d21d93667d37bee81048b37c462805571",
    "RANDOMIZED_LIBRARY_REPORT.md" =>
        "ecaba2b6a19cee7333da7b8a36c5a480d2548f80e2d3d2057e41ff6cc444b559",
)
for (path, expected_hash) in pilot_hashes
    sha256_file(joinpath(REPO, path)) == expected_hash ||
        error("frozen N=90 pilot drifted: $path")
end

summary = read(
    joinpath(RESULTS, "randomized_library_v2_summary.json"),
    String,
)
for fragment in (
    "\"trial_count\": 1024",
    "\"frontier_positive_count\": 398",
    "\"innovation_safe_positive_count\": 0",
    "\"substitution_count\": 256",
    "\"complementarity_count\": 141",
    "\"zero_count\": 627",
    "\"all_trial_hard_gates\": true",
    "\"theorem_evidence_false\": true",
)
    occursin(fragment, summary) ||
        error("summary JSON is missing reconciled fragment: $fragment")
end

println(
    "independent v2 audit passed: ",
    length(trials),
    " trials; interactions 256/141/627; ",
    "frontier-positive 398; innovation-safe positive 0; ",
    length(witnesses),
    " raw witnesses",
)
