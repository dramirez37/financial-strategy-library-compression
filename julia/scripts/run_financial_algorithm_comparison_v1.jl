module FinancialAlgorithmComparisonV1

using Dates
using SHA: sha256
using StrategyInnovation
using TOML

if !isdefined(Main, :FinancialResourceOptimization)
    Base.include(Main, joinpath(@__DIR__, "run_financial_resource_optimization.jl"))
end
const ResourceOptimization = Main.FinancialResourceOptimization

include(joinpath(@__DIR__, "lock_financial_algorithm_comparison_v1.jl"))
using .LockFinancialAlgorithmComparisonV1: verify_design_lock

export audit_saved_results, main, promote_public_aggregates, run_licensed_comparison

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const CONFIG_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_algorithm_comparison_v1.toml",
)


_repo_path(path::AbstractString) = isabspath(path) ? normpath(path) :
    normpath(joinpath(REPOSITORY_ROOT, path))
_sha256_file(path::AbstractString) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text::AbstractString) = bytes2hex(sha256(codeunits(text)))
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


function _controls(config)
    values = config["controls"]
    return FinancialAlgorithmComparisonControls(
        dp_requirement_limit = Int(values["dp_residual_requirement_limit"]),
        multistart_count = Int(values["multistart_count"]),
        multistart_seed = parse(UInt64, string(values["multistart_seed"])),
        mip_seed = Int(values["mip_seed"]),
        mip_time_limit_seconds = Float64(values["mip_time_limit_seconds"]),
        mip_relative_gap_tolerance =
            Float64(values["mip_relative_gap_tolerance"]),
        mip_absolute_gap_tolerance =
            Float64(values["mip_absolute_gap_tolerance"]),
    )
end


function _parse_csv_line(line::AbstractString)
    fields = String[]
    field = IOBuffer()
    quoted = false
    index = firstindex(line)
    while index <= lastindex(line)
        character = line[index]
        if character == '"'
            next_index = nextind(line, index)
            if quoted && next_index <= lastindex(line) && line[next_index] == '"'
                write(field, '"')
                index = next_index
            else
                quoted = !quoted
            end
        elseif character == ',' && !quoted
            push!(fields, String(take!(field)))
        else
            write(field, character)
        end
        index = nextind(line, index)
    end
    quoted && error("unterminated quoted CSV field")
    push!(fields, String(take!(field)))
    return fields
end


function _read_csv_rows(path::AbstractString)
    lines = readlines(path)
    isempty(lines) && error("empty committed aggregate table: $path")
    header = _parse_csv_line(first(lines))
    length(header) == length(unique(header)) || error("duplicate CSV header: $path")
    rows = Dict{String,String}[]
    for (line_number, line) in enumerate(Iterators.drop(lines, 1))
        isempty(line) && continue
        fields = _parse_csv_line(line)
        length(fields) == length(header) || error(
            "malformed committed aggregate CSV row $(line_number + 1): $path",
        )
        push!(rows, Dict(header[index] => fields[index] for index in eachindex(header)))
    end
    return rows
end


_csv_true(value::AbstractString) = value == "true" ? true :
    value == "false" ? false : error("invalid aggregate Boolean: $value")


function _committed_resource_tables(resource_config)
    outputs = resource_config["outputs"]
    return (
        libraries = _read_csv_rows(_repo_path(outputs["libraries_csv"])),
        solutions = _read_csv_rows(_repo_path(outputs["solutions_csv"])),
        frontiers = _read_csv_rows(
            _repo_path(outputs["frontier_certificates_csv"]),
        ),
        weights = _read_csv_rows(_repo_path(outputs["weights_csv"])),
    )
end


function _only_row(rows, description)
    length(rows) == 1 || error("expected one $description row; found $(length(rows))")
    return only(rows)
end


function _reconstruct_locked_parent(audit, resource_config, tables)
    resource = ResourceOptimization
    audit_id = String(audit["audit_id"])
    membership = [
        row for row in tables.libraries if
        row["audit_id"] == audit_id &&
        row["schedule_id"] == "uniform_cardinality" &&
        row["method"] == "global_safe"
    ]
    isempty(membership) && error("committed source membership is absent: $audit_id")
    source_ids = sort!(String[row["strategy_id"] for row in membership])
    length(source_ids) == length(unique(source_ids)) || error(
        "committed source membership repeats a strategy: $audit_id",
    )
    stepwise_rows = [
        row for row in tables.libraries if
        row["audit_id"] == audit_id &&
        row["schedule_id"] == "uniform_cardinality" &&
        row["method"] == "stepwise_safe" &&
        _csv_true(row["selected"])
    ]
    stepwise_ids = sort!(String[row["strategy_id"] for row in stepwise_rows])
    for schedule_id in REGISTERED_SCHEDULES
        schedule_source_ids = sort!(String[
            row["strategy_id"] for row in tables.libraries if
            row["audit_id"] == audit_id &&
            row["schedule_id"] == schedule_id &&
            row["method"] == "global_safe"
        ])
        schedule_source_ids == source_ids || error(
            "committed source membership changes across weight schedules: $audit_id/$schedule_id",
        )
        schedule_stepwise_ids = sort!(String[
            row["strategy_id"] for row in tables.libraries if
            row["audit_id"] == audit_id &&
            row["schedule_id"] == schedule_id &&
            row["method"] == "stepwise_safe" &&
            _csv_true(row["selected"])
        ])
        schedule_stepwise_ids == stepwise_ids || error(
            "historical stepwise endpoint changes across weight schedules: $audit_id/$schedule_id",
        )
    end
    solution = _only_row(
        [
            row for row in tables.solutions if
            row["audit_id"] == audit_id &&
            row["schedule_id"] == "uniform_cardinality" &&
            row["method"] == "global_safe"
        ],
        "$audit_id committed global-safe solution",
    )
    parse(Int, solution["source_size"]) == length(source_ids) || error(
        "committed source size disagrees with membership: $audit_id",
    )
    sort!(split(solution["selected_strategy_ids"], ';')) ==
        sort!(String[row["strategy_id"] for row in membership if _csv_true(row["selected"])]) ||
        error("committed global-safe selection list disagrees with membership: $audit_id")

    if audit_id == "locked_terminal_v1"
        parent_config = resource.TerminalAudit.load_financial_config(
            _repo_path(audit["config"]),
        )
        data_path = _repo_path(parent_config["data"]["path"])
        resource.TerminalAudit.load_provenance(
            _repo_path(parent_config["data"]["provenance_path"]),
            data_path,
            parent_config,
        )
        catalog = resource.TerminalAudit.finite_strategy_catalog(parent_config)
        compact = (; catalog, initial_library = source_ids)
        profiles = resource._source_profiles_terminal(compact, parent_config)
    elseif audit_id == "annual_walk_forward_v2"
        parent_config = resource.AnnualAudit.load_financial_annual_config(
            _repo_path(audit["config"]),
        )
        resource.AnnualAudit.DesignLock.verify_design_lock(parent_config)
        data_path = _repo_path(parent_config["data"]["path"])
        resource.AnnualAudit._load_provenance(parent_config, data_path)
        catalog = resource.AnnualAudit.finite_strategy_catalog_annual(parent_config)
        compact = (; catalog, initial_library = source_ids)
        profiles = resource._source_profiles_annual(compact, parent_config)
    else
        error("unsupported registered financial audit: $audit_id")
    end
    lookup = Dict(strategy.id => strategy for strategy in catalog)
    all(haskey(lookup, id) for id in source_ids) || error(
        "committed source identifier is absent from the locked grammar: $audit_id",
    )
    source_specs = [lookup[id] for id in source_ids]
    model = resource.build_exact_resource_model(source_specs, profiles)

    frontier_rows = sort!(
        [
            row for row in tables.frontiers if
            row["audit_id"] == audit_id &&
            row["schedule_id"] == "uniform_cardinality" &&
            row["method"] == "global_safe"
        ];
        by = row -> parse(Int, row["belief_state"]),
    )
    committed_frontier = ExactRational[
        exact_rational(row["source_frontier"]) for row in frontier_rows
    ]
    model.source_frontier == committed_frontier || error(
        "licensed validation profiles do not reproduce the committed frontier: $audit_id",
    )
    committed_modules = Set(split(solution["retained_module_ids"], ';'))
    model.source_modules == committed_modules || error(
        "locked grammar does not reproduce the committed source closure: $audit_id",
    )
    _csv_true(solution["exact_frontier_preserved"]) || error(
        "committed global-safe frontier certificate is false: $audit_id",
    )
    _csv_true(solution["exact_closure_preserved"]) || error(
        "committed global-safe closure certificate is false: $audit_id",
    )

    weight_data = resource.registered_strategy_weights(source_specs, resource_config)
    weight_rows = Dict(
        row["strategy_id"] => row for row in tables.weights if row["audit_id"] == audit_id
    )
    weight_columns = Dict(
        "uniform_cardinality" => "uniform_cardinality_weight",
        "nonshared_modules" => "nonshared_modules_weight",
        "validation_computation" => "validation_computation_weight",
        "documented_complexity" => "documented_complexity_weight",
    )
    for schedule_id in keys(weight_columns), id in source_ids
        haskey(weight_rows, id) || error("committed weight row is absent: $audit_id/$id")
        exact_rational(weight_rows[id][weight_columns[schedule_id]]) ==
            weight_data.schedules[schedule_id][id] || error(
                "recomputed weight disagrees with committed weight: $audit_id/$schedule_id/$id",
            )
    end
    opportunity_quality = exact_rational(
        solution["ex_post_enabled_descendant_opportunity_quality"],
    )
    result = (;
        safe_library = stepwise_ids,
        initial_candidate_quality = opportunity_quality,
    )
    return (;
        audit_id,
        label = String(audit["reader_label"]),
        quality_timing = String(audit["quality_timing"]),
        parent_config,
        result,
        source_specs,
        profiles,
        tolerance = Float64(parent_config["backtest"]["frontier_tolerance"]),
        source_import_certificate = (
            committed_membership_reused = true,
            licensed_validation_profiles_recomputed = true,
            exact_frontier_matches_committed = true,
            exact_closure_matches_committed = true,
            registered_weights_match_committed = true,
            annual_parent_replay_claimed = false,
        ),
    )
end


function _tie_handling()
    return JournalTieHandling(
        :declared_representative;
        declaration =
            "financial algorithms return one stable representative unless their own result says otherwise",
        stable_selector = "canonical original financial strategy identifier order",
    )
end


function _provenance(parent, schedule_id, parent_hashes)
    return JournalCompressionProvenance(
        :financial,
        "$(parent.audit_id):$schedule_id",
        "locked financial audit aggregate optimization inputs";
        parent_hashes = sort!(collect(parent_hashes); by = first),
        attributes = [
            "audit_id" => parent.audit_id,
            "evidence_class" => "retrospective financial audit",
            "licensed_rows_included" => "false",
            "schedule_id" => schedule_id,
        ],
        redistributable = true,
    )
end


function _heldout_evaluator(parent, instance)
    return function(selected, frozen_rows)
        # This body is unreachable until compare_financial_algorithm_suite has
        # completed every optimization and frozen every burden-gap row.
        all(ismissing(row.heldout_opportunity_diagnostic) for row in frozen_rows) ||
            error("held-out diagnostics were accessed before the ex-post phase")
        check = check_journal_compression_solution(instance, selected)
        check.exact_feasible || error(
            "held-out evaluation was requested for an unsafe endpoint",
        )
        return parent.result.initial_candidate_quality
    end
end


function _heldout_unit(parent)
    if parent.audit_id == "locked_terminal_v1"
        return "terminal locked-2020-2024 enabled-descendant net-utility opportunity units"
    elseif parent.audit_id == "annual_walk_forward_v2"
        return "annual mean next-year enabled-descendant opportunity units"
    end
    error("unknown financial audit unit: $(parent.audit_id)")
end


function _comparison_rows(result)
    return [merge(
        (
            audit_id = result.audit_id,
            audit_label = result.audit_label,
            schedule_id = result.schedule_id,
            heldout_unit = result.heldout_unit,
            instance_sha256 = result.instance_sha256,
        ),
        row,
    ) for row in result.rows]
end


const SUMMARY_COLUMNS = (
    :audit_id,
    :audit_label,
    :schedule_id,
    :heldout_unit,
    :instance_sha256,
    :algorithm_id,
    :applicability,
    :status,
    :active_strategy_count,
    :frontier_requirement_count,
    :module_requirement_count,
    :coverage_density,
    :duplicate_coverage_count,
    :dominance_reductions,
    :unique_carrier_count,
    :forced_strategy_count,
    :variables_before_preprocessing,
    :variables_after_preprocessing,
    :constraints_before_preprocessing,
    :constraints_after_preprocessing,
    :selected_strategy_count,
    :selected_active_strategy_count,
    :solve_time_seconds,
    :mip_node_count,
    :primal_objective,
    :best_bound,
    :reported_gap,
    :mip_termination_status,
    :solver_claimed_optimal,
    :exact_reconstructed_burden,
    :exact_mandatory_retention,
    :exact_frontier_preservation,
    :exact_closure_preservation,
    :exact_feasible,
    :dp_state_count,
    :exact_frontier_evaluations,
    :exact_closure_evaluations,
    :complete_deletion_scans,
    :multistart_count,
    :random_seed,
    :best_certified_benchmark_burden,
    :absolute_burden_gap,
    :relative_burden_gap,
    :benchmark_evidence_class,
    :heldout_opportunity_diagnostic,
    :heldout_timing,
)

const REGISTERED_AUDITS = (
    "locked_terminal_v1",
    "annual_walk_forward_v2",
)
const REGISTERED_SCHEDULES = (
    "uniform_cardinality",
    "nonshared_modules",
    "validation_computation",
    "documented_complexity",
)
const REGISTERED_ALGORITHMS = (
    "current_stepwise_safe_deletion",
    "heaviest_safe_first",
    "weighted_greedy",
    "weighted_greedy_reverse_delete",
    "multistart_random_deletion",
    "preprocessed_highs_mip",
    "requirement_mask_dp",
    "optional_second_solver_crosscheck",
)


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


function _summary_csv(rows)
    io = IOBuffer()
    println(io, join(string.(SUMMARY_COLUMNS), ','))
    for row in rows
        println(io, join((_csv_cell(getproperty(row, column)) for column in SUMMARY_COLUMNS), ','))
    end
    return String(take!(io))
end


function _environment_payload()
    commit = try
        strip(read(`git -C $REPOSITORY_ROOT rev-parse HEAD`, String))
    catch
        "UNAVAILABLE"
    end
    dirty = try
        !isempty(strip(read(`git -C $REPOSITORY_ROOT status --short`, String)))
    catch
        true
    end
    manifest_path = joinpath(REPOSITORY_ROOT, "julia", "Manifest.toml")
    return Dict{String,Any}(
        "recorded_at_utc" => Dates.format(
            Dates.now(Dates.UTC),
            dateformat"yyyy-mm-ddTHH:MM:SS.sssZ",
        ),
        "git_commit" => commit,
        "dirty_worktree" => dirty,
        "julia_version" => string(VERSION),
        "manifest_sha256" => _sha256_file(manifest_path),
        "operating_system" => string(Sys.KERNEL),
        "architecture" => string(Sys.ARCH),
        "cpu_threads_visible" => Sys.CPU_THREADS,
        "julia_threads" => Threads.nthreads(),
        "licensed_rows_included" => false,
    )
end


function _record_paths(output_root, audit_id, schedule_id)
    stem = "$(audit_id)__$(schedule_id)"
    return (
        instance = joinpath(output_root, "instances", stem * ".toml"),
        comparison = joinpath(output_root, "comparisons", stem * ".toml"),
        solver_log = joinpath(output_root, "solver_logs", stem * "__highs.log"),
    )
end


function _write_results(
    output_root,
    instances,
    results;
    source_import_certificates = nothing,
)
    rows = NamedTuple[]
    manifest_entries = Dict{String,String}()
    for (instance, result) in zip(instances, results)
        paths = _record_paths(output_root, result.audit_id, result.schedule_id)
        _write_replace(paths.instance, serialize_journal_compression_instance(instance))
        _write_replace(paths.comparison, serialize_financial_algorithm_comparison(result))
        _write_replace(
            paths.solver_log,
            get(result.solver_logs, "preprocessed_highs_mip", ""),
        )
        for path in paths
            manifest_entries[relpath(path, output_root)] = _sha256_file(path)
        end
        append!(rows, _comparison_rows(result))
    end
    summary_path = joinpath(output_root, "algorithm_summary.csv")
    environment_path = joinpath(output_root, "environment.toml")
    _write_replace(summary_path, _summary_csv(rows))
    _write_replace(environment_path, _toml_text(_environment_payload()))
    manifest_entries[relpath(summary_path, output_root)] = _sha256_file(summary_path)
    manifest_entries[relpath(environment_path, output_root)] = _sha256_file(environment_path)
    if !isnothing(source_import_certificates)
        certificate_path = joinpath(output_root, "source_import_certificates.toml")
        certificate_payload = Dict{String,Any}(
            "schema_version" => "financial-source-import-certificates-v1",
            "audits" => source_import_certificates,
            "licensed_rows_included" => false,
            "annual_parent_replay_claimed" => false,
        )
        _write_replace(certificate_path, _toml_text(certificate_payload))
        manifest_entries[relpath(certificate_path, output_root)] =
            _sha256_file(certificate_path)
    end
    manifest = Dict{String,Any}(
        "schema_version" => "financial-algorithm-comparison-local-manifest-v1",
        "comparison_count" => length(results),
        "audit_ids" => sort!(unique(result.audit_id for result in results)),
        "heldout_units_pooled" => false,
        "licensed_rows_included" => false,
        "files" => manifest_entries,
    )
    _write_replace(joinpath(output_root, "MANIFEST.toml"), _toml_text(manifest))
    return rows
end


function _parse_exact(value)
    value isa AbstractString || error("saved exact rational is not a string")
    return exact_rational(value)
end


function audit_saved_results(
    output_root::AbstractString = _repo_path(
        TOML.parsefile(CONFIG_PATH)["local_results_root"],
    ),
)
    root = normpath(output_root)
    manifest_path = joinpath(root, "MANIFEST.toml")
    isfile(manifest_path) || error("local comparison manifest is absent: $manifest_path")
    manifest = TOML.parsefile(manifest_path)
    errors = String[]
    for (relative, expected) in manifest["files"]
        path = joinpath(root, relative)
        isfile(path) || begin
            push!(errors, "missing saved artifact: $relative")
            continue
        end
        _sha256_file(path) == expected || push!(errors, "hash mismatch: $relative")
    end
    comparisons = sort!(filter(endswith(".toml"), readdir(joinpath(root, "comparisons"); join = true)))
    checked = 0
    for comparison_path in comparisons
        comparison = TOML.parsefile(comparison_path)
        stem = splitext(basename(comparison_path))[1]
        instance_path = joinpath(root, "instances", stem * ".toml")
        instance = open(instance_path, "r") do io
            read_journal_compression_instance(io)
        end
        journal_compression_instance_sha256(instance) == comparison["instance_sha256"] ||
            push!(errors, "$stem instance hash mismatch")
        rows = Dict(String(row["algorithm_id"]) => row for row in comparison["rows"])
        benchmark_burden = _parse_exact(comparison["benchmark"]["burden"])
        for (algorithm, selection) in comparison["selections"]
            indices = Int.(selection["selected_strategy_indices"])
            recorded_ids = String.(selection["selected_strategy_ids"])
            selected = falses(length(instance.strategy_ids))
            if length(unique(indices)) != length(indices) ||
               any(index -> !(index in eachindex(selected)), indices)
                push!(errors, "$stem/$algorithm has invalid selection indices")
                continue
            end
            selected[indices] .= true
            expected_ids = [string(instance.strategy_ids[index].id) for index in indices]
            recorded_ids == expected_ids ||
                push!(errors, "$stem/$algorithm selected identifiers mismatch")
            check = check_journal_compression_solution(instance, selected)
            row = rows[algorithm]
            get(row, "exact_feasible", false) == check.exact_feasible ||
                push!(errors, "$stem/$algorithm feasibility mismatch")
            get(row, "exact_reconstructed_burden", "") ==
                _exact_text(check.exact_burden) ||
                push!(errors, "$stem/$algorithm burden mismatch")
            get(row, "exact_frontier_preservation", false) ==
                check.frontier_preserved ||
                push!(errors, "$stem/$algorithm frontier mismatch")
            get(row, "exact_closure_preservation", false) ==
                check.closure_preserved ||
                push!(errors, "$stem/$algorithm closure mismatch")
            get(row, "exact_mandatory_retention", false) ==
                check.mandatory_retained ||
                push!(errors, "$stem/$algorithm mandatory-retention mismatch")
            get(row, "exact_tagged_coverage", false) ==
                check.tagged_coverage ||
                push!(errors, "$stem/$algorithm tagged-coverage mismatch")
            if check.exact_feasible
                absolute_gap = check.exact_burden - benchmark_burden
                _parse_exact(row["best_certified_benchmark_burden"]) ==
                    benchmark_burden ||
                    push!(errors, "$stem/$algorithm benchmark burden mismatch")
                _parse_exact(row["absolute_burden_gap"]) == absolute_gap ||
                    push!(errors, "$stem/$algorithm absolute gap mismatch")
                if !iszero(benchmark_burden)
                    _parse_exact(row["relative_burden_gap"]) ==
                        absolute_gap / benchmark_burden ||
                        push!(errors, "$stem/$algorithm relative gap mismatch")
                end
            end
            checked += 1
        end
        any(get(row, "solver_status_used_as_exact_proof", false) === true for row in values(rows)) &&
            push!(errors, "$stem treats solver status as exact proof")
    end
    source_certificate_path = joinpath(root, "source_import_certificates.toml")
    if isfile(source_certificate_path)
        source_certificates = TOML.parsefile(source_certificate_path)
        source_certificates["licensed_rows_included"] === false || push!(
            errors,
            "source-import certificate claims licensed rows are included",
        )
        source_certificates["annual_parent_replay_claimed"] === false || push!(
            errors,
            "source-import certificate incorrectly claims annual parent replay",
        )
        Set(keys(source_certificates["audits"])) == Set(REGISTERED_AUDITS) || push!(
            errors,
            "source-import certificates do not cover both registered audits",
        )
        for (audit_id, certificate) in source_certificates["audits"]
            for field in (
                "committed_membership_reused",
                "licensed_validation_profiles_recomputed",
                "exact_frontier_matches_committed",
                "exact_closure_matches_committed",
                "registered_weights_match_committed",
                "stepwise_endpoint_schedule_invariant",
            )
                get(certificate, field, false) === true || push!(
                    errors,
                    "$audit_id source-import certificate failed: $field",
                )
            end
        end
    end
    audit = Dict{String,Any}(
        "schema_version" => "financial-algorithm-comparison-local-audit-v1",
        "passed" => isempty(errors),
        "errors" => errors,
        "checked_selection_count" => checked,
        "comparison_count" => length(comparisons),
        "heldout_units_pooled" => false,
        "solver_status_used_as_exact_proof" => false,
        "licensed_rows_included" => false,
        "manifest_sha256" => _sha256_file(manifest_path),
    )
    _write_replace(joinpath(root, "AUDIT.toml"), _toml_text(audit))
    isempty(errors) || error("saved financial algorithm audit failed: $(join(errors, "; "))")
    println("financial algorithm comparison audit passed; comparisons=$(length(comparisons)); selections=$checked")
    return audit
end


function _validate_public_summary(output_root::AbstractString, config)
    summary_path = joinpath(output_root, "algorithm_summary.csv")
    audit_path = joinpath(output_root, "AUDIT.toml")
    manifest_path = joinpath(output_root, "MANIFEST.toml")
    environment_path = joinpath(output_root, "environment.toml")
    for path in (summary_path, audit_path, manifest_path, environment_path)
        isfile(path) || error("required local audit artifact is absent: $path")
    end
    audit = TOML.parsefile(audit_path)
    audit["passed"] === true || error("the local exact audit did not pass")
    audit["heldout_units_pooled"] === false || error(
        "the local audit reports pooled held-out units",
    )
    audit["solver_status_used_as_exact_proof"] === false || error(
        "the local audit treats solver status as exact proof",
    )
    expected_header = string.(collect(SUMMARY_COLUMNS))
    actual_header = _parse_csv_line(first(readlines(summary_path)))
    actual_header == expected_header || error(
        "the local summary columns differ from the locked public schema",
    )
    rows = _read_csv_rows(summary_path)
    expected_keys = Set(
        (audit_id, schedule_id, algorithm_id) for audit_id in REGISTERED_AUDITS,
        schedule_id in REGISTERED_SCHEDULES, algorithm_id in REGISTERED_ALGORITHMS
    )
    actual_keys = [
        (row["audit_id"], row["schedule_id"], row["algorithm_id"]) for row in rows
    ]
    length(actual_keys) == length(unique(actual_keys)) || error(
        "the local summary repeats an audit/schedule/algorithm row",
    )
    Set(actual_keys) == expected_keys || error(
        "the local summary does not contain the complete registered comparison grid",
    )
    expected_units = Dict(
        "locked_terminal_v1" =>
            "terminal locked-2020-2024 enabled-descendant net-utility opportunity units",
        "annual_walk_forward_v2" =>
            "annual mean next-year enabled-descendant opportunity units",
    )
    structural_columns = (
        "active_strategy_count",
        "frontier_requirement_count",
        "module_requirement_count",
        "coverage_density",
        "duplicate_coverage_count",
        "dominance_reductions",
        "unique_carrier_count",
        "forced_strategy_count",
        "variables_before_preprocessing",
        "variables_after_preprocessing",
        "constraints_before_preprocessing",
        "constraints_after_preprocessing",
    )
    for audit_id in REGISTERED_AUDITS
        audit_rows = [row for row in rows if row["audit_id"] == audit_id]
        all(row["heldout_unit"] == expected_units[audit_id] for row in audit_rows) ||
            error("the held-out unit changed within $audit_id")
        for column in structural_columns
            length(unique(row[column] for row in audit_rows)) == 1 || error(
                "structural field $column changed across algorithms for $audit_id",
            )
        end
        diagnostics = unique(
            row["heldout_opportunity_diagnostic"] for row in audit_rows if
            row["exact_feasible"] == "true"
        )
        length(diagnostics) == 1 && !isempty(only(diagnostics)) || error(
            "exactly feasible endpoints do not share one post-optimization diagnostic for $audit_id",
        )
    end
    expected_units[REGISTERED_AUDITS[1]] != expected_units[REGISTERED_AUDITS[2]] ||
        error("terminal and annual held-out units were pooled")
    for row in rows
        row["exact_feasible"] == "true" || continue
        for column in (
            "exact_mandatory_retention",
            "exact_frontier_preservation",
            "exact_closure_preservation",
        )
            row[column] == "true" || error(
                "an exactly feasible public row lacks $column: " *
                "$(row["audit_id"])/$(row["schedule_id"])/$(row["algorithm_id"])",
            )
        end
        for column in (
            "exact_reconstructed_burden",
            "best_certified_benchmark_burden",
            "absolute_burden_gap",
            "relative_burden_gap",
            "heldout_opportunity_diagnostic",
        )
            isempty(row[column]) && error(
                "an exactly feasible public row lacks $column: " *
                "$(row["audit_id"])/$(row["schedule_id"])/$(row["algorithm_id"])",
            )
        end
    end
    manifest = TOML.parsefile(manifest_path)
    manifest["files"]["algorithm_summary.csv"] == _sha256_file(summary_path) ||
        error("the local manifest does not authenticate the aggregate summary")
    source_certificate_path = joinpath(output_root, "source_import_certificates.toml")
    if get(config, "experiment_id", "") ==
       "retrospective-financial-algorithm-comparison-v1"
        isfile(source_certificate_path) || error(
            "the licensed source-import certificate is absent",
        )
        get(manifest["files"], "source_import_certificates.toml", "") ==
            _sha256_file(source_certificate_path) || error(
                "the local manifest does not authenticate the source-import certificate",
            )
        source_certificates = TOML.parsefile(source_certificate_path)
        Set(keys(source_certificates["audits"])) == Set(REGISTERED_AUDITS) || error(
            "the source-import certificate does not cover both financial audits",
        )
    end
    String.(config["registered_weight_schedules"]) == collect(REGISTERED_SCHEDULES) ||
        error("the configured schedule order differs from the public schema")
    return (;
        rows,
        audit,
        summary_path,
        audit_path,
        manifest_path,
        environment_path,
        source_certificate_path,
    )
end


_display_cell(value::AbstractString) = isempty(value) ? "—" : replace(value, "|" => "\\|")


function _markdown_table(io, header, rows)
    println(io, "| ", join(header, " | "), " |")
    println(io, "| ", join(fill("---", length(header)), " | "), " |")
    for row in rows
        println(io, "| ", join(_display_cell.(row), " | "), " |")
    end
end


function _public_results_report(rows, summary_relative, summary_sha256)
    labels = Dict(
        "locked_terminal_v1" => "Locked terminal audit",
        "annual_walk_forward_v2" => "Annual walk-forward audit",
    )
    algorithm_labels = Dict(
        "current_stepwise_safe_deletion" => "Locked stepwise deletion",
        "heaviest_safe_first" => "Heaviest-safe-first",
        "weighted_greedy" => "Weighted greedy",
        "weighted_greedy_reverse_delete" => "Weighted greedy + reverse deletion",
        "multistart_random_deletion" => "32-start random deletion",
        "preprocessed_highs_mip" => "Preprocessed HiGHS MIP",
        "requirement_mask_dp" => "Exact requirement-mask DP",
        "optional_second_solver_crosscheck" => "Optional second solver",
    )
    io = IOBuffer()
    println(io, "# Financial algorithm comparison results\n")
    println(io, "Status: **AUDITED RETROSPECTIVE FINANCIAL RESULTS**.\n")
    println(
        io,
        "This report is generated from the public aggregate `",
        summary_relative,
        "` (SHA-256 `",
        summary_sha256,
        "`). Every number below is derived from a committed row; none is manually transcribed.\n",
    )
    println(io, "## Evidence boundary\n")
    println(
        io,
        "The licensed panels were used to recompute validation profiles for the committed source libraries. Before algorithm dispatch, those profiles reproduced the committed exact source frontiers and module unions. Every returned library was then independently rechecked for mandatory inactive retention, exact frontier equality, exact closure equality, and exact burden. HiGHS `OPTIMAL` remains solver evidence, not formal or exhaustive proof. Held-out opportunity diagnostics were evaluated only after all selections and burden gaps were frozen. Terminal and annual diagnostic units are reported separately and are not pooled.\n",
    )
    println(io, "These are retrospective resource-allocation diagnostics. They support no causal, forecasting, alpha, or deployable-performance claim.\n")
    println(io, "## Source structure and preprocessing\n")
    structure_rows = Vector{Vector{String}}()
    for audit_id in REGISTERED_AUDITS
        row = first(row for row in rows if
            row["audit_id"] == audit_id &&
            row["schedule_id"] == "uniform_cardinality" &&
            row["algorithm_id"] == "current_stepwise_safe_deletion")
        push!(structure_rows, [
            labels[audit_id],
            row["active_strategy_count"],
            row["frontier_requirement_count"],
            row["module_requirement_count"],
            row["coverage_density"],
            row["duplicate_coverage_count"],
            row["dominance_reductions"],
            row["unique_carrier_count"],
            row["forced_strategy_count"],
            "$(row["variables_before_preprocessing"]) → $(row["variables_after_preprocessing"])",
            "$(row["constraints_before_preprocessing"]) → $(row["constraints_after_preprocessing"])",
        ])
    end
    _markdown_table(
        io,
        ["Audit", "Active", "Frontier rows", "Module rows", "Density", "Duplicates", "Dominance", "Unique carriers", "Forced", "Variables", "Constraints"],
        structure_rows,
    )
    println(io, "\nCoverage density is exact active strategy-to-tagged-requirement incidence. Reductions are computed by the registered fixed-point exact preprocessor.\n")
    for audit_id in REGISTERED_AUDITS
        println(io, "## ", labels[audit_id], "\n")
        comparison_rows = Vector{Vector{String}}()
        for schedule_id in REGISTERED_SCHEDULES, algorithm_id in REGISTERED_ALGORITHMS
            row = first(row for row in rows if
                row["audit_id"] == audit_id &&
                row["schedule_id"] == schedule_id &&
                row["algorithm_id"] == algorithm_id)
            push!(comparison_rows, [
                schedule_id,
                algorithm_labels[algorithm_id],
                row["status"],
                row["selected_active_strategy_count"],
                row["exact_reconstructed_burden"],
                row["absolute_burden_gap"],
                row["relative_burden_gap"],
                row["solve_time_seconds"],
                row["mip_node_count"],
                row["dp_state_count"],
            ])
        end
        _markdown_table(
            io,
            ["Schedule", "Algorithm", "Status", "Selected active", "Exact burden", "Absolute gap", "Relative gap", "Seconds", "MIP nodes", "DP states"],
            comparison_rows,
        )
        diagnostic = only(unique(
            row["heldout_opportunity_diagnostic"] for row in rows if
            row["audit_id"] == audit_id && row["exact_feasible"] == "true"
        ))
        unit = first(row["heldout_unit"] for row in rows if row["audit_id"] == audit_id)
        println(
            io,
            "\nThe common ex-post opportunity diagnostic for exactly safe endpoints is `",
            diagnostic,
            "` in ",
            unit,
            ". Equality here follows from exact closure preservation; it was not used to choose an algorithm or library.\n",
        )
    end
    println(io, "## Interpretation limits\n")
    println(
        io,
        "Runtime is machine-specific floating-point timing evidence. DP burdens are exact finite-computation results when the registered residual-requirement limit applies. MIP objectives, bounds, gaps, nodes, and statuses are solver diagnostics followed by independent exact feasibility and burden checks. Heuristic gaps inherit the benchmark evidence class stored in each machine-readable row. The unavailable second-solver rows remain visible rather than being dropped.\n",
    )
    return String(take!(io))
end


function promote_public_aggregates(config_path::AbstractString = CONFIG_PATH)
    lock_sha256 = verify_design_lock(config_path)
    config = TOML.parsefile(config_path)
    output_root = _repo_path(config["local_results_root"])
    audit_saved_results(output_root)
    validated = _validate_public_summary(output_root, config)
    public_summary = _repo_path(config["public_summary_path"])
    public_status = _repo_path(config["public_status_path"])
    public_report = _repo_path(config["public_report_path"])
    dirname(public_summary) == _repo_path("experiments/results/summaries") || error(
        "the configured public summary is outside the permitted aggregate directory",
    )
    public_report == _repo_path("journal/aor/reports/FINANCIAL_ALGORITHM_RESULTS.md") ||
        error("the configured public report path changed")
    _write_replace(public_summary, read(validated.summary_path, String))
    summary_sha256 = _sha256_file(public_summary)
    summary_relative = relpath(public_summary, REPOSITORY_ROOT)
    report_text = _public_results_report(
        validated.rows,
        summary_relative,
        summary_sha256,
    )
    _write_replace(public_report, report_text)
    environment = TOML.parsefile(validated.environment_path)
    source_certificates = TOML.parsefile(validated.source_certificate_path)
    status = Dict{String,Any}(
        "schema_version" => "financial-algorithm-comparison-public-status-v1",
        "experiment_id" => String(config["experiment_id"]),
        "design_lock_aggregate_sha256" => lock_sha256,
        "local_exact_audit_passed" => true,
        "local_audit_sha256" => _sha256_file(validated.audit_path),
        "local_manifest_sha256" => _sha256_file(validated.manifest_path),
        "local_source_import_certificate_sha256" =>
            _sha256_file(validated.source_certificate_path),
        "source_import_certificates" => source_certificates["audits"],
        "public_summary_path" => summary_relative,
        "public_summary_sha256" => summary_sha256,
        "public_report_path" => relpath(public_report, REPOSITORY_ROOT),
        "public_report_sha256" => _sha256_file(public_report),
        "row_count" => length(validated.rows),
        "audit_ids" => collect(REGISTERED_AUDITS),
        "schedule_ids" => collect(REGISTERED_SCHEDULES),
        "algorithm_ids" => collect(REGISTERED_ALGORITHMS),
        "heldout_units_pooled" => false,
        "licensed_rows_included" => false,
        "selected_strategy_identifiers_included" => false,
        "raw_or_row_level_data_included" => false,
        "solver_status_used_as_exact_proof" => false,
        "annual_parent_replay_passed" => false,
        "annual_parent_replay_limitation" =>
            "known analytical-lock versus taxonomy-lock certificate identity drift; see AMENDMENT_002.md",
        "execution_git_commit" => environment["git_commit"],
        "execution_dirty_worktree" => environment["dirty_worktree"],
        "julia_version" => environment["julia_version"],
        "manifest_sha256" => environment["manifest_sha256"],
    )
    _write_replace(public_status, _toml_text(status))
    println("promoted audited aggregate-only financial comparison; rows=$(length(validated.rows))")
    return (; public_summary, public_status, public_report)
end


function run_licensed_comparison(config_path::AbstractString = CONFIG_PATH)
    verify_design_lock(config_path)
    resource = ResourceOptimization
    config = TOML.parsefile(config_path)
    resource_config_path = _repo_path(config["parent_resource_config"])
    resource_config = TOML.parsefile(resource_config_path)
    resource.DesignLock.verify_design_lock(resource_config_path)
    parent_hashes = Dict{String,String}()
    for audit in resource_config["audits"]
        merge!(parent_hashes, resource._verify_parent_artifacts(audit))
    end
    tables = _committed_resource_tables(resource_config)
    controls = _controls(config)
    schedules = String.(config["registered_weight_schedules"])
    instances = JournalCompressionInstance[]
    results = FinancialAlgorithmComparisonResult[]
    source_import_certificates = Dict{String,Any}()
    for audit in resource_config["audits"]
        parent = _reconstruct_locked_parent(audit, resource_config, tables)
        source_import_certificates[parent.audit_id] = Dict{String,Any}(
            string(key) => value for (key, value) in pairs(merge(
                parent.source_import_certificate,
                (
                    source_strategy_count = length(parent.source_specs),
                    historical_stepwise_strategy_count = length(parent.result.safe_library),
                    stepwise_endpoint_schedule_invariant = true,
                ),
            ))
        )
        model = resource.build_exact_resource_model(parent.source_specs, parent.profiles)
        weight_data = resource.registered_strategy_weights(
            parent.source_specs,
            resource_config,
        )
        for schedule_id in schedules
            weights = weight_data.schedules[schedule_id]
            instance = journal_compression_instance_from_financial(
                model,
                weights;
                inactive_id = resource.INACTIVE_ID,
                tie_handling = _tie_handling(),
                provenance = _provenance(parent, schedule_id, parent_hashes),
            )
            result = compare_financial_algorithm_suite(
                instance;
                audit_id = parent.audit_id,
                audit_label = parent.label,
                schedule_id,
                heldout_unit = _heldout_unit(parent),
                current_stepwise_ids = sort!(String.(parent.result.safe_library)),
                controls,
                heldout_evaluator = _heldout_evaluator(parent, instance),
            )
            audit = audit_financial_algorithm_comparison(instance, result)
            audit.passed || error(
                "in-memory comparison audit failed for $(parent.audit_id)/$schedule_id",
            )
            push!(instances, instance)
            push!(results, result)
        end
    end
    output_root = _repo_path(config["local_results_root"])
    _write_results(
        output_root,
        instances,
        results;
        source_import_certificates,
    )
    audit_saved_results(output_root)
    parent_hashes_after = Dict{String,String}()
    for audit in resource_config["audits"]
        merge!(parent_hashes_after, resource._verify_parent_artifacts(audit))
    end
    parent_hashes_after == parent_hashes || error(
        "a committed parent artifact changed during financial comparison",
    )
    println("wrote local licensed comparisons; audits=$(length(resource_config["audits"])); schedules=$(length(schedules))")
    return (; instances, results, output_root)
end


function _synthetic_smoke()
    model = (
        source_ids = ["left", "right", "bundle"],
        rational_profiles = Dict(
            "left" => ExactRational[2, 0],
            "right" => ExactRational[0, 2],
            "bundle" => ExactRational[2, 2],
        ),
        source_frontier = ExactRational[2, 2],
        source_modules = Set(["m1", "m2"]),
        lookup = Dict(
            "left" => (modules = ("m1",),),
            "right" => (modules = ("m2",),),
            "bundle" => (modules = ("m1", "m2"),),
        ),
    )
    weights = Dict("left" => 1 // 1, "right" => 1 // 1, "bundle" => 3 // 2)
    instance = journal_compression_instance_from_financial(
        model,
        weights;
        tie_handling = _tie_handling(),
        provenance = JournalCompressionProvenance(
            :financial,
            "synthetic-financial-cli-smoke",
            "public synthetic workflow smoke fixture; no financial rows";
            attributes = ["evidence_class" => "synthetic workflow validation only"],
        ),
    )
    result = compare_financial_algorithm_suite(
        instance;
        audit_id = "synthetic_smoke",
        audit_label = "Synthetic smoke fixture",
        schedule_id = "smoke",
        heldout_unit = "synthetic units (not financial evidence)",
        current_stepwise_ids = ["bundle"],
        controls = FinancialAlgorithmComparisonControls(
            dp_requirement_limit = 10,
            multistart_count = 2,
            mip_time_limit_seconds = 30,
        ),
    )
    audit_financial_algorithm_comparison(instance, result).passed || error(
        "synthetic financial comparison smoke audit failed",
    )
    println("synthetic financial algorithm smoke passed; no financial result generated")
    return result
end


function main(args = ARGS)
    length(args) == 1 || error(
        "usage: run_financial_algorithm_comparison_v1.jl --synthetic-smoke|--licensed|--audit-only|--promote-public",
    )
    only(args) == "--synthetic-smoke" && return _synthetic_smoke()
    only(args) == "--licensed" && return run_licensed_comparison()
    only(args) == "--audit-only" && return audit_saved_results()
    only(args) == "--promote-public" && return promote_public_aggregates()
    error("unknown financial algorithm comparison mode: $(only(args))")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    FinancialAlgorithmComparisonV1.main()
end
