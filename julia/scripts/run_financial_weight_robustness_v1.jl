module FinancialWeightRobustnessV1

using SHA: sha256
using StrategyInnovation
using TOML

if !isdefined(Main, :FinancialAlgorithmComparisonV1)
    Base.include(Main, joinpath(@__DIR__, "run_financial_algorithm_comparison_v1.jl"))
end
const FinancialComparison = Main.FinancialAlgorithmComparisonV1
const ResourceOptimization = FinancialComparison.ResourceOptimization

include(joinpath(@__DIR__, "lock_financial_weight_robustness_v1.jl"))
using .LockFinancialWeightRobustnessV1: verify_design_lock

export audit_saved_robustness, main, promote_public_robustness, run_licensed_robustness

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_weight_robustness_v1.toml",
)
const ANALYSIS_FILES = (
    "summary.csv",
    "selections.csv",
    "identity_overlap.csv",
    "rank_stability.csv",
    "empty_residual_certificates.csv",
    "results.md",
)
const SUMMARY_COLUMNS = (
    :audit_id,
    :audit_label,
    :schedule_id,
    :algorithm_id,
    :applicability,
    :status,
    :source_active_count,
    :selected_active_count,
    :source_exact_burden,
    :selected_exact_burden,
    :burden_saved,
    :burden_savings_ratio,
    :compression_ratio,
    :algorithm_competition_rank,
    :attains_exact_preprocessing_optimum,
    :exact_preprocessing_optimum_burden,
    :exact_preprocessing_optimum_certified,
    :global_stepwise_absolute_gap,
    :global_stepwise_relative_gap,
    :distinct_active_unique_carrier_count,
    :all_active_unique_carriers_retained,
    :exact_mandatory_retention,
    :exact_frontier_preservation,
    :exact_closure_preservation,
    :exact_feasible,
    :heldout_opportunity_diagnostic,
    :heldout_unit,
    :heldout_timing,
    :benchmark_evidence_class,
)
const SELECTION_COLUMNS = (
    :audit_id,
    :schedule_id,
    :algorithm_id,
    :strategy_id,
    :active_unique_carrier,
)
const OVERLAP_COLUMNS = (
    :audit_id,
    :algorithm_id,
    :left_schedule_id,
    :right_schedule_id,
    :left_selected_active_count,
    :right_selected_active_count,
    :intersection_count,
    :union_count,
    :symmetric_difference_count,
    :jaccard_similarity,
)
const RANK_COLUMNS = (
    :audit_id,
    :algorithm_id,
    :equal_active_strategy_rank,
    :validation_computation_rank,
    :governance_complexity_rank,
    :feasible_schedule_count,
    :top_rank_count,
    :minimum_rank,
    :maximum_rank,
    :rank_range,
)
const CERTIFICATE_COLUMNS = (
    :audit_id,
    :schedule_id,
    :instance_sha256,
    :status,
    :certified_global_optimum,
    :preprocessing_feasible,
    :residual_strategy_count,
    :residual_requirement_count,
    :forced_strategy_count,
    :selected_active_strategy_count,
    :exact_optimum_burden,
    :exact_mandatory_retention,
    :exact_tagged_coverage,
    :exact_frontier_preservation,
    :exact_closure_preservation,
    :exact_feasible,
    :theorem_basis,
    :evidence_class,
    :lean_verified,
    :solver_invoked,
    :solver_status_used_as_proof,
)

_repo_path(path::AbstractString) = isabspath(path) ? normpath(path) :
    normpath(joinpath(REPOSITORY_ROOT, path))
_sha256_file(path::AbstractString) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_exact_text(value::Rational) = "$(numerator(value))//$(denominator(value))"


function _write_replace(path::AbstractString, text::AbstractString)
    mkpath(dirname(path))
    temporary = path * ".replace.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, path; force = true)
    return path
end


function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end


function _csv_cell(value)
    text = if value === missing || value === nothing
        ""
    elseif value isa Rational
        _exact_text(value)
    else
        string(value)
    end
    return any(character -> character in text, (',', '"', '\n', '\r')) ?
           "\"" * replace(text, "\"" => "\"\"") * "\"" : text
end


function _csv_text(columns, rows)
    io = IOBuffer()
    println(io, join(string.(columns), ','))
    for row in rows
        println(io, join((_csv_cell(getproperty(row, column)) for column in columns), ','))
    end
    return String(take!(io))
end


function _empty_residual_optimum_certificate(instance::JournalCompressionInstance)
    raw = certify_empty_residual_optimum(instance)
    return (
        certified = raw.certified_global_optimum,
        burden = raw.exact_optimum_burden,
        selected = raw.selected,
        evidence = raw.evidence_class,
        raw,
    )
end


function _active_unique_carriers(instance::JournalCompressionInstance)
    carriers = Set{Int}()
    for row in axes(instance.coverage, 1)
        columns = findall(instance.coverage[row, :])
        length(columns) == 1 || continue
        column = only(columns)
        instance.mandatory[column] || push!(carriers, column)
    end
    return sort!(collect(carriers))
end


function _schedule_declarations(config)
    return [(
        schedule_id = String(row["schedule_id"]),
        source_schedule_id = String(row["source_schedule_id"]),
        expected_min = Int(row["expected_min"]),
        expected_max = Int(row["expected_max"]),
    ) for row in config["schedules"]]
end


function _load_saved_comparisons(root::AbstractString)
    records = NamedTuple[]
    comparison_paths = sort!(filter(
        endswith(".toml"),
        readdir(joinpath(root, "comparisons"); join = true),
    ))
    for comparison_path in comparison_paths
        comparison = TOML.parsefile(comparison_path)
        stem = splitext(basename(comparison_path))[1]
        instance_path = joinpath(root, "instances", stem * ".toml")
        instance = open(instance_path, "r") do io
            read_journal_compression_instance(io)
        end
        journal_compression_instance_sha256(instance) == comparison["instance_sha256"] ||
            error("saved robustness instance hash mismatch: $stem")
        push!(records, (; comparison, instance, stem))
    end
    return records
end


function _analysis_rows(root::AbstractString, config)
    records = _load_saved_comparisons(root)
    schedules = [row.schedule_id for row in _schedule_declarations(config)]
    expected = Set(
        (audit_id, schedule_id) for audit_id in FinancialComparison.REGISTERED_AUDITS,
        schedule_id in schedules
    )
    actual = Set(
        (String(record.comparison["audit_id"]), String(record.comparison["schedule_id"]))
        for record in records
    )
    actual == expected || error("saved robustness comparisons do not match the locked grid")
    summary = NamedTuple[]
    selections = NamedTuple[]
    certificates = NamedTuple[]
    selection_sets = Dict{Tuple{String,String,String},Set{String}}()
    rank_lookup = Dict{Tuple{String,String,String},Int}()
    certificate_lookup = Dict{Tuple{String,String},Any}()

    for record in records
        comparison = record.comparison
        instance = record.instance
        audit_id = String(comparison["audit_id"])
        schedule_id = String(comparison["schedule_id"])
        audit_label = String(comparison["audit_label"])
        rows = Dict(String(row["algorithm_id"]) => row for row in comparison["rows"])
        exact_certificate = _empty_residual_optimum_certificate(instance)
        certificate_lookup[(audit_id, schedule_id)] = exact_certificate
        exact_certificate.certified || error(
            "the locked robustness protocol requires an empty-residual certificate: $audit_id/$schedule_id",
        )
        source_active = count(!, instance.mandatory)
        source_burden = sum(
            (instance.weights[index] for index in eachindex(instance.weights) if
             !instance.mandatory[index]);
            init = zero(ExactRational),
        )
        unique_carriers = _active_unique_carriers(instance)
        raw_certificate = exact_certificate.raw
        selected_active_certificate = count(
            index -> raw_certificate.selected[index] && !instance.mandatory[index],
            eachindex(instance.strategy_ids),
        )
        push!(certificates, (
            audit_id,
            schedule_id,
            instance_sha256 = raw_certificate.instance_sha256,
            status = string(raw_certificate.status),
            certified_global_optimum = raw_certificate.certified_global_optimum,
            preprocessing_feasible = raw_certificate.preprocessing_feasible,
            residual_strategy_count = raw_certificate.residual_strategy_count,
            residual_requirement_count = raw_certificate.residual_requirement_count,
            forced_strategy_count = length(raw_certificate.forced_strategy_indices),
            selected_active_strategy_count = selected_active_certificate,
            exact_optimum_burden = raw_certificate.exact_optimum_burden,
            exact_mandatory_retention = raw_certificate.exact_mandatory_retention,
            exact_tagged_coverage = raw_certificate.exact_tagged_coverage,
            exact_frontier_preservation = raw_certificate.exact_frontier_preservation,
            exact_closure_preservation = raw_certificate.exact_closure_preservation,
            exact_feasible = raw_certificate.exact_feasible,
            theorem_basis = raw_certificate.theorem_basis,
            evidence_class = raw_certificate.evidence_class,
            lean_verified = false,
            solver_invoked = false,
            solver_status_used_as_proof = false,
        ))
        feasible_burdens = Dict{String,ExactRational}()
        checks = Dict{String,Any}()
        selected_bits = Dict{String,BitVector}()
        for (algorithm_id, selection) in comparison["selections"]
            indices = Int.(selection["selected_strategy_indices"])
            selected = falses(length(instance.strategy_ids))
            selected[indices] .= true
            check = check_journal_compression_solution(instance, selected)
            check.exact_feasible || error(
                "saved robustness selection is not exactly feasible: $audit_id/$schedule_id/$algorithm_id",
            )
            recorded_ids = String.(selection["selected_strategy_ids"])
            expected_ids = [string(instance.strategy_ids[index].id) for index in indices]
            recorded_ids == expected_ids || error(
                "saved robustness identities disagree with indices: $audit_id/$schedule_id/$algorithm_id",
            )
            row = rows[algorithm_id]
            exact_rational(row["exact_reconstructed_burden"]) == check.exact_burden ||
                error("saved robustness burden fails exact recheck")
            feasible_burdens[algorithm_id] = check.exact_burden
            checks[algorithm_id] = check
            selected_bits[algorithm_id] = selected
        end
        ranks = Dict(
            algorithm_id => 1 + count(other -> other < burden, values(feasible_burdens)) for
            (algorithm_id, burden) in feasible_burdens
        )
        stepwise_burden = feasible_burdens["current_stepwise_safe_deletion"]
        global_gap = stepwise_burden - exact_certificate.burden
        global_gap >= 0 || error("historical stepwise burden is below the exact optimum")
        global_relative = iszero(exact_certificate.burden) ? missing :
                          global_gap / exact_certificate.burden

        for algorithm_id in FinancialComparison.REGISTERED_ALGORITHMS
            row = rows[algorithm_id]
            has_selection = haskey(selected_bits, algorithm_id)
            selected = has_selection ? selected_bits[algorithm_id] : nothing
            check = has_selection ? checks[algorithm_id] : nothing
            selected_active = has_selection ? count(
                index -> selected[index] && !instance.mandatory[index],
                eachindex(selected),
            ) : missing
            selected_burden = has_selection ? check.exact_burden : missing
            burden_saved = has_selection ? source_burden - selected_burden : missing
            savings_ratio = has_selection && !iszero(source_burden) ?
                            burden_saved / source_burden : missing
            compression_ratio = has_selection ?
                                BigInt(selected_active) // BigInt(source_active) : missing
            unique_retained = has_selection ?
                              all(selected[index] for index in unique_carriers) : missing
            if has_selection
                ids = Set{String}()
                for index in eachindex(selected)
                    selected[index] && !instance.mandatory[index] || continue
                    id = string(instance.strategy_ids[index].id)
                    push!(ids, id)
                    push!(selections, (
                        audit_id,
                        schedule_id,
                        algorithm_id,
                        strategy_id = id,
                        active_unique_carrier = index in unique_carriers,
                    ))
                end
                selection_sets[(audit_id, schedule_id, algorithm_id)] = ids
                rank_lookup[(audit_id, schedule_id, algorithm_id)] = ranks[algorithm_id]
            end
            heldout = get(row, "heldout_opportunity_diagnostic", Dict("available" => false))
            heldout_value = heldout isa AbstractString ? exact_rational(heldout) : missing
            push!(summary, (
                audit_id,
                audit_label,
                schedule_id,
                algorithm_id,
                applicability = String(row["applicability"]),
                status = String(row["status"]),
                source_active_count = source_active,
                selected_active_count = selected_active,
                source_exact_burden = source_burden,
                selected_exact_burden = selected_burden,
                burden_saved,
                burden_savings_ratio = savings_ratio,
                compression_ratio,
                algorithm_competition_rank = has_selection ? ranks[algorithm_id] : missing,
                attains_exact_preprocessing_optimum = has_selection ?
                    selected_burden == exact_certificate.burden : missing,
                exact_preprocessing_optimum_burden = exact_certificate.burden,
                exact_preprocessing_optimum_certified = exact_certificate.certified,
                global_stepwise_absolute_gap = global_gap,
                global_stepwise_relative_gap = global_relative,
                distinct_active_unique_carrier_count = length(unique_carriers),
                all_active_unique_carriers_retained = unique_retained,
                exact_mandatory_retention = has_selection ? check.mandatory_retained : missing,
                exact_frontier_preservation = has_selection ? check.frontier_preserved : missing,
                exact_closure_preservation = has_selection ? check.closure_preserved : missing,
                exact_feasible = has_selection ? check.exact_feasible : missing,
                heldout_opportunity_diagnostic = heldout_value,
                heldout_unit = String(comparison["heldout_unit"]),
                heldout_timing = String(row["heldout_timing"]),
                benchmark_evidence_class = exact_certificate.evidence,
            ))
        end
    end

    sort!(summary; by = row -> (
        findfirst(==(row.audit_id), FinancialComparison.REGISTERED_AUDITS),
        findfirst(==(row.schedule_id), schedules),
        findfirst(==(row.algorithm_id), FinancialComparison.REGISTERED_ALGORITHMS),
    ))
    sort!(selections; by = row -> (
        row.audit_id,
        findfirst(==(row.schedule_id), schedules),
        row.algorithm_id,
        row.strategy_id,
    ))

    overlaps = NamedTuple[]
    for audit_id in FinancialComparison.REGISTERED_AUDITS,
        algorithm_id in FinancialComparison.REGISTERED_ALGORITHMS,
        left_index in 1:(length(schedules) - 1), right_index in (left_index + 1):length(schedules)
        left_schedule = schedules[left_index]
        right_schedule = schedules[right_index]
        left_key = (audit_id, left_schedule, algorithm_id)
        right_key = (audit_id, right_schedule, algorithm_id)
        haskey(selection_sets, left_key) && haskey(selection_sets, right_key) || continue
        left = selection_sets[left_key]
        right = selection_sets[right_key]
        intersection_count = length(intersect(left, right))
        union_count = length(union(left, right))
        push!(overlaps, (
            audit_id,
            algorithm_id,
            left_schedule_id = left_schedule,
            right_schedule_id = right_schedule,
            left_selected_active_count = length(left),
            right_selected_active_count = length(right),
            intersection_count,
            union_count,
            symmetric_difference_count = length(symdiff(left, right)),
            jaccard_similarity = iszero(union_count) ? one(ExactRational) :
                                 BigInt(intersection_count) // BigInt(union_count),
        ))
    end

    ranks = NamedTuple[]
    for audit_id in FinancialComparison.REGISTERED_AUDITS,
        algorithm_id in FinancialComparison.REGISTERED_ALGORITHMS
        values = Union{Missing,Int}[
            get(rank_lookup, (audit_id, schedule_id, algorithm_id), missing) for
            schedule_id in schedules
        ]
        available = Int[value for value in values if !ismissing(value)]
        push!(ranks, (
            audit_id,
            algorithm_id,
            equal_active_strategy_rank = values[1],
            validation_computation_rank = values[2],
            governance_complexity_rank = values[3],
            feasible_schedule_count = length(available),
            top_rank_count = count(==(1), available),
            minimum_rank = isempty(available) ? missing : minimum(available),
            maximum_rank = isempty(available) ? missing : maximum(available),
            rank_range = isempty(available) ? missing : maximum(available) - minimum(available),
        ))
    end
    sort!(certificates; by = row -> (
        findfirst(==(row.audit_id), FinancialComparison.REGISTERED_AUDITS),
        findfirst(==(row.schedule_id), schedules),
    ))
    return (;
        summary,
        selections,
        overlaps,
        ranks,
        certificates,
        schedules,
        certificate_lookup,
    )
end


_md(value) = value === missing ? "—" : value isa Rational ? _exact_text(value) : string(value)


function _markdown_table(io, header, rows)
    println(io, "| ", join(header, " | "), " |")
    println(io, "| ", join(fill("---", length(header)), " | "), " |")
    for row in rows
        println(io, "| ", join((_md(value) for value in row), " | "), " |")
    end
end


function _results_markdown(analysis)
    io = IOBuffer()
    println(io, "# Financial retention-weight robustness results\n")
    println(io, "Status: **LOCKED REPLAY, EXACTLY AUDITED, PRIOR OUTCOMES DISCLOSED**.\n")
    println(io, "This analysis is not first-look evidence. The three schedules existed and had prior outcomes before the dedicated robustness lock. The lock prospectively fixed this subset and the identity, rank, burden, unique-carrier, and reporting rules; no schedule was fitted to these outputs.\n")
    println(io, "All returned endpoints below passed exact mandatory-retention, frontier, closure, and burden checks. Global-optimum language is used only where human-proved optimum-preserving preprocessing rules reduced the exact model to an empty residual problem and the lifted solution passed an independent exact check. This is exact finite computation under a human proof, not Lean or solver proof.\n")
    for audit_id in FinancialComparison.REGISTERED_AUDITS
        label = first(row.audit_label for row in analysis.summary if row.audit_id == audit_id)
        println(io, "## ", label, "\n")
        rows = Vector{Vector{Any}}()
        for row in analysis.summary
            row.audit_id == audit_id || continue
            push!(rows, Any[
                row.schedule_id,
                row.algorithm_id,
                row.selected_active_count,
                row.selected_exact_burden,
                row.burden_savings_ratio,
                row.compression_ratio,
                row.algorithm_competition_rank,
                row.attains_exact_preprocessing_optimum,
            ])
        end
        _markdown_table(
            io,
            ["Schedule", "Algorithm", "Selected active", "Exact burden", "Burden saved share", "Compression ratio", "Rank", "Exact optimum"],
            rows,
        )
        representative = first(row for row in analysis.summary if
            row.audit_id == audit_id &&
            row.schedule_id == "equal_active_strategy" &&
            row.algorithm_id == "current_stepwise_safe_deletion")
        println(io, "\nDistinct active unique carriers: `", representative.distinct_active_unique_carrier_count, "`. Every exactly feasible endpoint retained all of them.\n")
        gap_rows = Vector{Vector{Any}}()
        for schedule_id in analysis.schedules
            row = first(row for row in analysis.summary if
                row.audit_id == audit_id && row.schedule_id == schedule_id)
            push!(gap_rows, Any[
                schedule_id,
                row.exact_preprocessing_optimum_burden,
                row.global_stepwise_absolute_gap,
                row.global_stepwise_relative_gap,
            ])
        end
        _markdown_table(
            io,
            ["Schedule", "Exact preprocessing optimum", "Stepwise absolute gap", "Stepwise relative gap"],
            gap_rows,
        )
        println(io)
        rank_rows = Vector{Vector{Any}}()
        for row in analysis.ranks
            row.audit_id == audit_id || continue
            push!(rank_rows, Any[
                row.algorithm_id,
                row.equal_active_strategy_rank,
                row.validation_computation_rank,
                row.governance_complexity_rank,
                row.top_rank_count,
                row.rank_range,
            ])
        end
        _markdown_table(
            io,
            ["Algorithm", "Equal rank", "Validation rank", "Governance rank", "Top-rank schedules", "Rank range"],
            rank_rows,
        )
        feasible_overlap = [row for row in analysis.overlaps if row.audit_id == audit_id]
        if !isempty(feasible_overlap)
            overlap_rows = Vector{Vector{Any}}()
            for algorithm_id in unique(row.algorithm_id for row in feasible_overlap)
                values = [row.jaccard_similarity for row in feasible_overlap if row.algorithm_id == algorithm_id]
                push!(overlap_rows, Any[algorithm_id, minimum(values), maximum(values)])
            end
            println(io, "\nSchedule identity agreement for the same algorithm:\n")
            _markdown_table(
                io,
                ["Algorithm", "Minimum Jaccard", "Maximum Jaccard"],
                overlap_rows,
            )
        end
        diagnostic = only(unique(
            row.heldout_opportunity_diagnostic for row in analysis.summary if
            row.audit_id == audit_id && row.exact_feasible === true
        ))
        unit = first(row.heldout_unit for row in analysis.summary if row.audit_id == audit_id)
        println(io, "\nPostdecision held-out diagnostic: `", _md(diagnostic), "` in ", unit, ". It did not enter weights, algorithms, ranks, overlap, or exclusions.\n")
    end
    println(io, "## Limits\n")
    println(io, "Terminal and annual units are not pooled. Unavailable second-solver and inapplicable DP rows remain in the machine-readable summary. Strategy identifiers are aggregate library labels, not CRSP/WRDS rows. The study makes no causal, forecasting, alpha, or deployable-performance claim.")
    return chomp(String(take!(io))) * "\n"
end


function _analysis_texts(root::AbstractString, config)
    analysis = _analysis_rows(root, config)
    return Dict(
        "summary.csv" => _csv_text(SUMMARY_COLUMNS, analysis.summary),
        "selections.csv" => _csv_text(SELECTION_COLUMNS, analysis.selections),
        "identity_overlap.csv" => _csv_text(OVERLAP_COLUMNS, analysis.overlaps),
        "rank_stability.csv" => _csv_text(RANK_COLUMNS, analysis.ranks),
        "empty_residual_certificates.csv" =>
            _csv_text(CERTIFICATE_COLUMNS, analysis.certificates),
        "results.md" => _results_markdown(analysis),
    )
end


function _write_analysis(root::AbstractString, config)
    analysis_root = joinpath(root, "robustness_analysis")
    texts = _analysis_texts(root, config)
    hashes = Dict{String,String}()
    for filename in ANALYSIS_FILES
        path = joinpath(analysis_root, filename)
        _write_replace(path, texts[filename])
        hashes[filename] = _sha256_file(path)
    end
    manifest = Dict{String,Any}(
        "schema_version" => "financial-weight-robustness-local-analysis-manifest-v1",
        "files" => hashes,
        "audit_count" => 2,
        "schedule_count" => 3,
        "algorithm_rows_per_comparison" => 8,
        "prior_schedule_outcomes_exist" => true,
        "heldout_units_pooled" => false,
        "licensed_rows_included" => false,
    )
    _write_replace(joinpath(analysis_root, "MANIFEST.toml"), _toml_text(manifest))
    return analysis_root
end


function audit_saved_robustness(config_path::AbstractString = CONFIG_PATH)
    verify_design_lock(config_path)
    config = TOML.parsefile(config_path)
    root = _repo_path(config["local_results_root"])
    FinancialComparison.audit_saved_results(root)
    analysis_root = joinpath(root, "robustness_analysis")
    manifest_path = joinpath(analysis_root, "MANIFEST.toml")
    isfile(manifest_path) || error("robustness analysis manifest is absent")
    manifest = TOML.parsefile(manifest_path)
    expected = _analysis_texts(root, config)
    errors = String[]
    for filename in ANALYSIS_FILES
        path = joinpath(analysis_root, filename)
        isfile(path) || begin
            push!(errors, "missing robustness analysis artifact: $filename")
            continue
        end
        read(path, String) == expected[filename] || push!(
            errors,
            "robustness analysis content mismatch: $filename",
        )
        get(manifest["files"], filename, "") == _sha256_file(path) || push!(
            errors,
            "robustness analysis hash mismatch: $filename",
        )
    end
    audit = Dict{String,Any}(
        "schema_version" => "financial-weight-robustness-local-audit-v1",
        "passed" => isempty(errors),
        "errors" => errors,
        "comparison_count" => 6,
        "algorithm_row_count" => 48,
        "heldout_units_pooled" => false,
        "licensed_rows_included" => false,
        "raw_or_row_level_data_included" => false,
        "solver_status_used_as_exact_proof" => false,
        "manifest_sha256" => _sha256_file(manifest_path),
    )
    _write_replace(joinpath(analysis_root, "AUDIT.toml"), _toml_text(audit))
    isempty(errors) || error("financial weight-robustness audit failed: $(join(errors, "; "))")
    println("financial weight-robustness audit passed; comparisons=6; rows=48")
    return audit
end


function run_licensed_robustness(config_path::AbstractString = CONFIG_PATH)
    verify_design_lock(config_path)
    config = TOML.parsefile(config_path)
    financial_config_path = _repo_path(config["financial_algorithm_config"])
    FinancialComparison.verify_design_lock(financial_config_path)
    financial_config = TOML.parsefile(financial_config_path)
    resource_config_path = _repo_path(config["financial_resource_config"])
    resource_config = TOML.parsefile(resource_config_path)
    ResourceOptimization.DesignLock.verify_design_lock(resource_config_path)
    parent_hashes = Dict{String,String}()
    for audit in resource_config["audits"]
        merge!(parent_hashes, ResourceOptimization._verify_parent_artifacts(audit))
    end
    tables = FinancialComparison._committed_resource_tables(resource_config)
    controls = FinancialComparison._controls(financial_config)
    schedule_declarations = _schedule_declarations(config)
    instances = JournalCompressionInstance[]
    results = FinancialAlgorithmComparisonResult[]
    source_certificates = Dict{String,Any}()
    for audit in resource_config["audits"]
        parent = FinancialComparison._reconstruct_locked_parent(
            audit,
            resource_config,
            tables,
        )
        source_certificates[parent.audit_id] = Dict{String,Any}(
            "committed_membership_reused" => true,
            "licensed_validation_profiles_recomputed" => true,
            "exact_frontier_matches_committed" => true,
            "exact_closure_matches_committed" => true,
            "registered_weights_match_committed" => true,
            "stepwise_endpoint_schedule_invariant" => true,
            "source_strategy_count" => length(parent.source_specs),
            "historical_stepwise_strategy_count" => length(parent.result.safe_library),
        )
        model = ResourceOptimization.build_exact_resource_model(
            parent.source_specs,
            parent.profiles,
        )
        weight_data = ResourceOptimization.registered_strategy_weights(
            parent.source_specs,
            resource_config,
        )
        for declaration in schedule_declarations
            weights = weight_data.schedules[declaration.source_schedule_id]
            realized = collect(values(weights))
            minimum(realized) >= declaration.expected_min || error(
                "realized weight is below the locked range: $(declaration.schedule_id)",
            )
            maximum(realized) <= declaration.expected_max || error(
                "realized weight is above the locked range: $(declaration.schedule_id)",
            )
            instance = journal_compression_instance_from_financial(
                model,
                weights;
                inactive_id = ResourceOptimization.INACTIVE_ID,
                tie_handling = FinancialComparison._tie_handling(),
                provenance = FinancialComparison._provenance(
                    parent,
                    declaration.schedule_id,
                    parent_hashes,
                ),
            )
            result = compare_financial_algorithm_suite(
                instance;
                audit_id = parent.audit_id,
                audit_label = parent.label,
                schedule_id = declaration.schedule_id,
                heldout_unit = FinancialComparison._heldout_unit(parent),
                current_stepwise_ids = sort!(String.(parent.result.safe_library)),
                controls,
                heldout_evaluator = FinancialComparison._heldout_evaluator(parent, instance),
            )
            audit_result = audit_financial_algorithm_comparison(instance, result)
            audit_result.passed || error(
                "in-memory robustness comparison audit failed: $(parent.audit_id)/$(declaration.schedule_id)",
            )
            push!(instances, instance)
            push!(results, result)
        end
    end
    output_root = _repo_path(config["local_results_root"])
    FinancialComparison._write_results(
        output_root,
        instances,
        results;
        source_import_certificates = source_certificates,
    )
    FinancialComparison.audit_saved_results(output_root)
    _write_analysis(output_root, config)
    audit_saved_robustness(config_path)
    parent_hashes_after = Dict{String,String}()
    for audit in resource_config["audits"]
        merge!(parent_hashes_after, ResourceOptimization._verify_parent_artifacts(audit))
    end
    parent_hashes_after == parent_hashes || error(
        "a committed parent artifact changed during weight robustness",
    )
    println("wrote locked local financial weight robustness; comparisons=6")
    return (; instances, results, output_root)
end


function promote_public_robustness(config_path::AbstractString = CONFIG_PATH)
    lock_hash = verify_design_lock(config_path)
    config = TOML.parsefile(config_path)
    audit = audit_saved_robustness(config_path)
    audit["passed"] === true || error("the local robustness audit did not pass")
    root = _repo_path(config["local_results_root"])
    analysis_root = joinpath(root, "robustness_analysis")
    mapping = Dict(
        "summary.csv" => _repo_path(config["public_summary_path"]),
        "selections.csv" => _repo_path(config["public_selections_path"]),
        "identity_overlap.csv" => _repo_path(config["public_overlap_path"]),
        "rank_stability.csv" => _repo_path(config["public_rank_path"]),
        "empty_residual_certificates.csv" =>
            _repo_path(config["public_certificate_path"]),
        "results.md" => _repo_path(config["public_report_path"]),
    )
    public_hashes = Dict{String,String}()
    for filename in ANALYSIS_FILES
        destination = mapping[filename]
        if filename == "results.md"
            destination == _repo_path(
                "experiments/financial_resource_optimization/WEIGHT_ROBUSTNESS_RESULTS.md",
            ) || error("the public robustness report path changed")
        else
            dirname(destination) == _repo_path("experiments/results/summaries") ||
                error("a public robustness aggregate is outside the permitted directory")
        end
        _write_replace(destination, read(joinpath(analysis_root, filename), String))
        public_hashes[relpath(destination, REPOSITORY_ROOT)] = _sha256_file(destination)
    end
    environment = TOML.parsefile(joinpath(root, "environment.toml"))
    status = Dict{String,Any}(
        "schema_version" => "financial-weight-robustness-public-status-v1",
        "experiment_id" => String(config["experiment_id"]),
        "design_lock_aggregate_sha256" => lock_hash,
        "prior_schedule_outcomes_exist" => true,
        "robustness_specific_analysis_locked_before_outputs" => true,
        "local_exact_audit_passed" => true,
        "local_audit_sha256" => _sha256_file(joinpath(analysis_root, "AUDIT.toml")),
        "local_manifest_sha256" => _sha256_file(joinpath(analysis_root, "MANIFEST.toml")),
        "public_files" => public_hashes,
        "audit_count" => 2,
        "schedule_count" => 3,
        "algorithm_row_count" => 48,
        "terminal_annual_units_pooled" => false,
        "selected_strategy_identifiers_are_aggregate" => true,
        "licensed_rows_included" => false,
        "raw_or_row_level_data_included" => false,
        "solver_status_used_as_exact_proof" => false,
        "execution_git_commit" => environment["git_commit"],
        "execution_dirty_worktree" => environment["dirty_worktree"],
        "julia_version" => environment["julia_version"],
        "manifest_sha256" => environment["manifest_sha256"],
    )
    _write_replace(_repo_path(config["public_status_path"]), _toml_text(status))
    println("promoted audited financial weight-robustness aggregates")
    return mapping
end


function main(args = ARGS)
    length(args) == 1 || error(
        "usage: run_financial_weight_robustness_v1.jl --licensed|--audit-only|--promote-public",
    )
    only(args) == "--licensed" && return run_licensed_robustness()
    only(args) == "--audit-only" && return audit_saved_robustness()
    only(args) == "--promote-public" && return promote_public_robustness()
    error("unknown financial weight-robustness mode: $(only(args))")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    FinancialWeightRobustnessV1.main()
end
